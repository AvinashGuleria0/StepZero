import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const StepZeroApp());
}

class StepZeroApp extends StatelessWidget {
  const StepZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepZero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const TriageScreen(),
    );
  }
}

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  // --- Services ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  static const platform = MethodChannel('com.stepzero.sms');

  // --- Change this if using a physical device (e.g. your PC's local IP 'http://192.168.1.5:8000') ---
  final String backendUrl = "http://127.0.0.1:8000/api/v1/triage/evaluate";
  final String emergencyContact = "+918360336699"; // TODO: Update with real number

  // --- State Variables ---
  bool _isListening = false;
  String _transcript = "";
  
  // SOS Variables
  bool _isSOSMode = false;
  int _sosCountdown = 10;
  Timer? _countdownTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
    _initTTS();
  }

  Future<void> _requestAllPermissions() async {
    print("[FRONTEND LOG] 1. Requesting Android Permissions...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.location,
      Permission.sms,
      Permission.phone,
    ].request();
    print("[FRONTEND LOG] Permissions Result: $statuses");
  }

  Future<void> _initTTS() async {
    print("[FRONTEND LOG] 2. Initializing Text-to-Speech Engine...");
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for clarity
    print("[FRONTEND LOG] TTS Engine Ready.");
  }

  // --- 1. Speech to Text Engine ---
  void _toggleListening() async {
    print("[FRONTEND LOG] Mic Button Tapped. Current isListening state: $_isListening");
    if (!_isListening) {
      print("[FRONTEND LOG] Initializing Speech-to-Text...");
      bool available = await _speech.initialize(
        onStatus: (val) => print('[FRONTEND STT STATUS]: $val'),
        onError: (val) => print('[FRONTEND STT ERROR]: $val'),
      );
      print("[FRONTEND LOG] STT Available: $available");
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _transcript = val.recognizedWords;
            });
            print("[FRONTEND LOG] Partial Transcript: $_transcript");
          },
        );
      }
    } else {
      // User tapped mic again to STOP listening
      print("[FRONTEND LOG] Stopping Speech-to-Text manually...");
      setState(() => _isListening = false);
      _speech.stop();
      print("[FRONTEND LOG] Final Transcript grabbed: '$_transcript'");
      if (_transcript.isNotEmpty) {
        _evaluateAnomaly(_transcript);
      } else {
        print("[FRONTEND LOG] Transcript was empty. Aborting API call.");
      }
    }
  }

  // --- 2. Backend Orchestration (The Simulation Trigger) ---
  Future<void> _evaluateAnomaly(String symptomText) async {
    setState(() => _isLoading = true);
    print("\n[FRONTEND LOG] === STARTING ANOMALY EVALUATION PIPELINE ===");
    try {
      // Get Live GPS Location
      print("[FRONTEND LOG] Fetching GPS Device Coordinates...");
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("[FRONTEND LOG] Coordinates Found: Latitude ${position.latitude}, Longitude ${position.longitude}");

      // Build JSON package to send to the FastAPI Backend
      Map<String, dynamic> payload = {
        "uid": "patient_01",
        "heart_rate": 135, // Hardcoded simulation value for the anomaly trigger
        "is_moving": false,
        "lat": position.latitude,
        "lng": position.longitude,
        "voice_transcript": symptomText
      };
      
      print("[FRONTEND LOG] Sending Payload to Python Backend at: $backendUrl");
      print("[FRONTEND LOG] Payload JSON: $payload");

      // Call backend AI
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print("[FRONTEND LOG] Received Response from Backend. Status Code: ${response.statusCode}");
      print("[FRONTEND LOG] Raw Body: ${response.body}");

      final responseData = jsonDecode(response.body);

      // Successfully processed by Groq Llama-3
      if (responseData['status'] == 'success') {
        final aiEval = responseData['ai_evaluation'];
        print("[FRONTEND LOG] AI Threat Level Graded As: ${aiEval['threat_level']}");
        
        // Text-to-Speech: Agent speaks to patient
        if (aiEval['agent_tts_response'] != null) {
          print("[FRONTEND LOG] Activating TTS to speak: '${aiEval['agent_tts_response']}'");
          await _flutterTts.speak(aiEval['agent_tts_response']);
        }

        // Determine Action
        if (aiEval['action_trigger'] == "START_SOS_TIMER" || aiEval['threat_level'] == "CRITICAL") {
           print("[FRONTEND LOG] CRITICAL THREAT DETECTED. PUSHING TO COMPONENT: _triggerSOSMode()");
          _triggerSOSMode(position.latitude, position.longitude);
        } else {
           print("[FRONTEND LOG] SAFE THREAT DETECTED. DISPLAYING SNACKBAR.");
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Agent: ${aiEval['agent_tts_response']}\nStatus: SAFE')),
          );
        }
      }
    } catch (e) {
      print("[FRONTEND ERROR] Edge AI Call Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server Error context loop. Backend running?')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. The 60-Second SOS Bypass System ---
  void _triggerSOSMode(double lat, double lng) {
    print("\n[FRONTEND LOG] !!! EMERGENCY PROTOCOL INITIATED !!!");
    print("[FRONTEND LOG] Counting down from 10 seconds...");
    setState(() {
      _isSOSMode = true;
      _sosCountdown = 10;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown > 0) {
        setState(() {
          _sosCountdown--;
        });
      } else {
        // COUNTDOWN HIT 0! TRIGGER NATIVE SMS
        print("[FRONTEND LOG] TIMER ZERO. DISPATCHING SMS NOW!");
        timer.cancel();
        _fireEmergencySMS(lat, lng);
      }
    });
  }

  void _cancelSOS() {
    print("[FRONTEND LOG] USER PRESSED CANCEL. ABORTING SOS...");
    _countdownTimer?.cancel();
    setState(() {
      _isSOSMode = false;
      _sosCountdown = 10;
      _transcript = ""; 
    });
    _flutterTts.stop();
  }

  void _fireEmergencySMS(double lat, double lng) async {
    String mapLink = "https://maps.google.com/?q=$lat,$lng";
    // String smsMessage = "URGENT SOS: StepZero AI has intercepted a CRITICAL incident (Heart Spike/Heatstroke). Patient location: $mapLink";
    String smsMessage = "URGENT SOS TEST";

    // Send SMS blindly in the background using our custom Native Kotlin channel!
    try {
      print("[FRONTEND LOG] Calling Kotlin Native Channel to Background send SMS...");
      await platform.invokeMethod('sendSMS', {
        'phone': emergencyContact,
        'msg': smsMessage,
      });
      print("[FRONTEND LOG] Native Code Returned: SUCCESS.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("CRITICAL: EMERGENCY SMS DISPATCHED!", style: TextStyle(fontSize: 20)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("[FRONTEND LOG] NATIVE KOTLIN ERROR: $e");
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("FAILED TO SEND SMS: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSOSMode = false;
      _transcript = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    // Top-level switch between Idle Monitoring & Red Alert UI
    if (_isSOSMode) {
      return _buildSOSScreen();
    }
    return _buildIdleScreen();
  }

  // ---- The Voice-First Accessible UI (Elderly Target) ----
  Widget _buildIdleScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StepZero Active Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isListening ? "Listening to your symptoms..." : "StepZero is actively guarding you.",
                    style: TextStyle(fontSize: 22, color: _isListening ? Colors.redAccent : Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  
                  // Enormous accessible tap area
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Colors.grey.shade900,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isListening ? Colors.redAccent : Colors.black,
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  if (_isLoading) const CircularProgressIndicator(color: Colors.redAccent),
                  
                  if (_transcript.isNotEmpty && !_isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '"$_transcript"',
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- The 60-Second Escape Hatch (Red Screen) ----
  Widget _buildSOSScreen() {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              
              const Text(
                "CRITICAL\nANOMALY",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 40),
              
              Text(
                "$_sosCountdown",
                style: const TextStyle(
                  fontSize: 160, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()]
                ),
              ),
              const Text(
                "SECONDS UNTIL EMERGENCY SMS",
                style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              
              const Spacer(),
              
              // Massive visual contrast cancel button
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: SizedBox(
                   width: double.infinity,
                   height: 100,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                     ),
                     onPressed: _cancelSOS,
                     child: const Text(
                       "I AM OKAY (CANCEL)",
                       style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                   ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
