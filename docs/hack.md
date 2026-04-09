## 💡 Project Overview: Project StepZero
**The Problem Statement:** Build an AI-powered system that predicts diseases or assists in early diagnosis using symptoms, wearable data, or medical history.

**Our Solution:** We are shifting healthcare from reactive to proactive. Project StepZero integrates directly with the OS layer (**Android Health Connect**) to monitor vitals. If it detects a sudden anomaly (like a 130 BPM heart rate while sitting), it checks live local weather data (e.g., 42°C heatwave), correlates it with the user's Firebase medical history, and intercepts the user using an elderly-friendly Voice AI to triage a potential crisis (like heatstroke or cardiac event).

---

## 🛠️ The Tech Stack (Hackathon Optimized)
*   **Frontend:** Flutter (High contrast UI, elderly-friendly)
*   **Vital Connectivity:** **Android Health Connect API** via the Flutter `health` package (Replaces deprecated Google Fit API).
*   **Voice Interactivity:** `speech_to_text` & `flutter_tts`
*   **Backend & DB:** Python FastAPI + Firebase (Firestore) for Medical Profiles.
*   **AI Engine (SLM Simulation):** Groq API (Llama-3). *Prompt Engineering rule: strictly enforced JSON-only outputs.*
*   **SMS Integration:** Flutter `url_launcher` or `telephony` (to send native SOS SMS straight from the device, avoiding 14-day Twilio A2P telecom verifications).
*   **External APIs:** OpenWeatherMap API & Google Maps API.

---

## ✅ THE 24-HOUR EXECUTION CHECKLIST

### Phase 1: Foundation & APIs (Hours 1-4)
- [ ] Initialize Flutter project & setup Firebase App.
-[ ] Initialize Python FastAPI backend environment.
- [ ] Obtain API Keys: Groq, Google Maps, OpenWeather.
- [ ] **Mobile OS Fix:** Setup Android Manifest permissions for Android Health Connect (Testing requires an Android 14+ emulator/device). 

### Phase 2: App, UI & "The Simulation" (Hours 4-12)
- [ ] Build User Onboarding Flow (Save Age, Allergies, Heart History to Firestore).
- [ ] Build Main Screen (Massive Voice Mic button for accessibility).
- [ ] Implement `speech_to_text` & `flutter_tts`.
- [ ] **Crucial Fix:** Build the "Dev Toggle Dashboard." Do not write background isolates—OS Doze limits will kill it. Create manual buttons to inject dummy JSON payloads (e.g., `[Simulate HR Spike = 135]`) to seamlessly trigger the workflow live.

### Phase 3: Backend Logic & Strict AI Parsing (Hours 12-18)
- [ ] Write Python endpoint to receive `(HealthConnectData, UserProfile, VoiceText, Weather)`.
- [ ] **Crucial Fix:** Implement the aggressive Groq prompt: *"You are an evaluation engine. You receive (HR, Temp, Profile, Symptoms). Output ONLY a valid JSON object with exactly two keys: `{"threat_level": "CRITICAL/MODERATE/SAFE", "condition_guess": "string"}`. No markdown, no conversational text."*
- [ ] Build the Weather integration (Lat/Long -> Temp).
- [ ] Build the 60-Second Auto-SOS Countdown UI.

### Phase 4: Integrations (Hours 18-24)
- [ ] **Crucial Fix:** Integrate local SMS dispatch (using `url_launcher` to prefill the messaging app with: *"SOS: [User] is having a medical emergency. Coordinates: [Google Maps Link]"*). 
- [ ] Rehearse demo end-to-end using Dev Toggles.
- [ ] Build final PPT. 

---
---

# 📊 STRICT 7-SLIDE PPT TEMPLATE (Updated)
*(Adhering strictly to PDF Rules: Max 7 slides, NO paragraphs, MUST use exact headers).* 

**Title Slide:** 
Project StepZero (By Team Falcon Claw)
Member 1, 2, 3, 4 | Roll Nos.

**SLIDE 1: Problem Statement**
*   Building an AI system to predict diseases using symptoms, wearables, and medical history.
*   **The Flaw:** Most digital health tools are *reactive*—users must identify they are sick first.
*   **The Target:** Critical medical events (strokes, heat exhaustion) where users are incapacitated.
*   **The Need:** A system that initiates diagnosis *before* the user actively asks for help.

**SLIDE 2: Current Challenges**
*   **Delayed Triage:** Apps wait for user input, causing fatal delays during the "golden hour" of medical emergencies.
*   **Data Silos:** Wearables detect an anomaly, but lack medical history and environmental context (Is HR high due to exercise, or 42°C heat, or a cardiac defect?).
*   **Inaccessibility:** Complex typing apps block elderly users from urgent healthcare access.

**SLIDE 3: Proposed Solution**
*   **Project StepZero:** A proactive, voice-activated Edge AI Agent. 
*   **Background Monitoring:** Actively queries local biometric data rather than waiting for text inputs.
*   **Tri-Layer Contextual Triage:** Unifies Medical History + Real-time Biometrics + Environmental Weather APIs into a single analytical pipeline.

**SLIDE 4: Solution Workflow**
*   **Listen:** System accesses background vitals via Android Health Connect.
*   **Detect:** Anomalous baseline shift occurs (e.g., resting HR hits 130). AI pulls OpenWeather data.
*   **Intercept:** Phone initiates conversational Voice check-in: *"Your vitals are high, are you experiencing chest pain?"*
*   **Evaluate:** Python AI backend strictly outputs triage JSON.
*   **Escalate:** High-risk threat starts 60-second native SOS dispatch.

**SLIDE 5: Key Features**
*   **Android Health Connect Native Integration:** Future-proofed biometrics access (replaces legacy Google Fit).
*   **Environmental Correlator:** Reduces false positives by matching symptoms to local weather APIs.
*   **Elderly-Accessible UI:** Voice-First interface powered by rapid STT/TTS engine.
*   **Device-Native SOS Bypass:** Avoids API bottlenecks by triggering the local sim hardware to send emergency text + map coordinates.

**SLIDE 6: Technical Approach**
*   **Frontend App:** Flutter & Dart. 
*   **OS Health API:** Android Health Connect (Android 14+ compliant). 
*   **Backend Inference:** Python FastAPI utilizing an aggressive JSON-prompted LLM (Llama-3 via Groq) to simulate rapid Edge-AI.
*   **Cloud Architecture:** Firebase (Firestore logic, authentication) coupled with precise external geofencing APIs.

**SLIDE 7: Impact & Future Scope**
*   **Immediate Impact:** Bridges the gap between passive hardware tracking and active clinical intervention for at-risk demographics. 
*   **Clinical Reliability:** Shifts reliance away from user "guessing" their symptoms.
*   **Future Scope:** 
    *   Transition logic fully on-device natively using optimized open-weights SLMs (Llama.cpp on mobile). 
    *   Integration with external clinical dashboard APIs. 
