# Low-Level Design (LLD) - Project StepZero
**Team Falcon Claw | CHITKARAVERSE 2026**

## 1. System Components & Modules Overview
The architecture is divided into three main operational nodes:
1. **Client Edge (Flutter):** Handles hardware interfacing (Sensors, Microphone, GPS, SMS).
2. **Logic Engine (Python FastAPI):** Handles orchestration, API calls, and context building.
3. **Inference Node (Groq Llama-3 API):** Processes the SLM decision-making matrix.
4. **Data Layer (Firebase):** Manages user states and medical histories.

---

## 2. Database Schema (Firebase Firestore)
We utilize a NoSQL structure to ensure fast read times during the "golden hour" of an emergency.

### Collections & Documents
*   **Collection: `users`** (Document ID: `uid` from Firebase Auth)
    *   `name` (String)
    *   `phone` (String)
    *   `emergency_contact_name` (String)
    *   `emergency_contact_phone` (String)
    *   `location_tracking_enabled` (Boolean)
    
*   **Sub-Collection: `users/{uid}/health_profile`**
    *   `age` (Integer)
    *   `weight_kg` (Double)
    *   `pre_existing_conditions` (Array of Strings: e.g., ["Hypertension", "Asthma"])
    *   `medications` (Array of Strings)
    *   `family_history` (String)
    
*   **Collection: `incidents`** (Document ID: Auto-generated UUID)
    *   `uid` (Reference String)
    *   `timestamp` (Timestamp)
    *   `trigger_source` (String: "wearable_anomaly", "manual_voice")
    *   `vital_snapshot` (Map: `{heart_rate: 135, steps: 0}`)
    *   `weather_context` (Map: `{temp_c: 42, condition: "Sunny"}`)
    *   `user_transcript` (String)
    *   `ai_diagnosis` (String)
    *   `sos_triggered` (Boolean)

---

## 3. Backend API Specifications (FastAPI)

### Endpoint 1: Evaluate Vitals & Context
*   **Path:** `POST /api/v1/triage/evaluate`
*   **Description:** Triggered when the Flutter app detects a baseline anomaly (e.g., HR > 120 at rest). Gathers weather data, injects medical profile, and queries Groq LLM.
*   **Request Payload (JSON):**
    ```json
    {
      "uid": "abc123xyz",
      "vitals": {
        "heart_rate": 135,
        "is_moving": false
      },
      "location": {
        "lat": 30.8596,
        "lng": 76.8119
      },
      "voice_transcript": "My chest feels very heavy and I am sweating."
    }
    ```
*   **Internal Backend Process:**
    1. Python extracts `lat`/`lng` -> Calls OpenWeatherMap API -> Gets 42°C.
    2. Python extracts `uid` -> Queries Firestore `users/{uid}/health_profile` -> Gets Age 55, Hypertension.
    3. Prompts Groq/Llama-3: *"User is 55 with Hypertension. Vitals: HR 135 resting. Environment: 42°C. Transcript: 'My chest feels heavy'. Output JSON response dictating next action."*
*   **Response Payload (JSON):**
    ```json
    {
      "status": "success",
      "risk_level": "CRITICAL",
      "agent_tts_response": "This could be a cardiac event. I am initiating the 60-second SOS timer. Please sit down.",
      "action_trigger": "START_SOS_TIMER",
      "suggested_actions": ["Rest", "Drink Water"]
    }
    ```

---

## 4. Flutter Client Component Logic (Edge Layer)

### 4.1 Wearable Interface (`health_service.dart`)
*   **Library:** `health` (Android Health Connect integration)
*   **Workflow:**
    1. Requests `READ` permissions for Heart Rate and Steps.
    2. Background isolate runs a cron job every 5 minutes fetching the last 15 mins of data.
    3. Applies Local Rule: `IF (HR > 120) AND (Steps in last 10 mins < 50) THEN emit AnomalyEvent`.

### 4.2 Voice Manager (`audio_service.dart`)
*   **Libraries:** `speech_to_text`, `flutter_tts`
*   **Workflow:**
    1. Upon `AnomalyEvent`, UI turns screen on and `flutter_tts` asks: *"Your heart rate is 135 but you are resting. Are you okay?"*
    2. Automatically triggers `speech_to_text.listen()`.
    3. Converts spoken words to String. Passes string to `/api/v1/triage/evaluate`.

### 4.3 Native SOS Hardware Bypass (`sos_manager.dart`)
*   **Libraries:** `url_launcher` (for SMS intent) or `telephony` (for direct background SMS).
*   **Workflow:**
    1. If FastAPI returns `"action_trigger": "START_SOS_TIMER"`, start 60-sec visual countdown.
    2. If user presses "Cancel", API logs incident as "Resolved/False Alarm".
    3. If timer hits `0`, build message string: *"URGENT: Falcon AI has detected a critical anomaly for Avinash. Vitals: HR 135. Location: https://maps.google.com/?q=30.8596,76.8119"*.
    4. Execute Native SMS Intent to `emergency_contact_phone`.

---

## 5. Sequence Diagram / Data Flow (Anomaly Scenario)
```text
1. [Watch/Phone Sensors] -> HR drops/spikes abnormally ->[Flutter Background Isolate]
2. [Flutter Isolate] wakes UI -> Initiates[TTS Agent: "Are you feeling okay?"]
3. [User speaks] -> [Flutter STT] -> Text generated -> Sends payload to[FastAPI]
4. [FastAPI] parallel queries:
    a. [Firebase Firestore] for user medical history.
    b. [OpenWeather API] for environmental context.
5. [FastAPI] aggregates payload -> Posts to [Groq Llama-3 Engine].
6. [Llama-3] analyzes inputs -> returns rigid JSON formatting -> [FastAPI].
7. [FastAPI] parses JSON -> Sends escalation response to [Flutter].
8. [Flutter] -> Starts 60s timer -> Plays TTS Warning.
9. [Timer Expired] ->[Flutter] triggers device OS to send Native SMS to Emergency Contact.
```