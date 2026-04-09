## 💡 Project Overview: Proactive AI Health Triage
**The Problem Statement:** Build an AI-powered system that predicts diseases or assists in early diagnosis using symptoms, wearable data, or medical history.

**Our Solution:** Most health apps are *reactive* (you get sick -> you open app -> you type symptoms). We are building a *proactive* system. Our AI silently monitors Google Fit wearable data in the background. If it spots a severe anomaly (like a 130 BPM heart rate spike while stationary), it connects the dots using local weather APIs (e.g., it’s 42°C outside) and the user's Firebase medical profile, and **talks to the user first** via an elderly-friendly Voice UI to triage the emergency. 

---

## ⚙️ How it Works (The Workflow)
1. **The Deep Onboarding:** User enters Name, Age, Weight, Allergies, Family Medical History, Lifestyle habits, and Emergency Contacts.
2. **Background Monitoring:** App links with Google Fit to pull real-time Heart Rate (BPM).
3. **The Trigger & Environment Check:** If a BPM anomaly occurs, the Python backend checks the user's location via OpenWeather API to get environmental context.
4. **Voice Intercept:** The phone vibrates, and the TTS (Text-to-Speech) asks: *"Your heart rate spiked to 130 and it is 42 degrees outside. Are you feeling okay?"*
5. **AI Evaluation (The SLM):** The user replies via Voice. The AI evaluates all 3 layers (Profile + Wearable + Voice Symptom). 
6. **The 60-Second SOS:** If it's a critical threat (e.g., cardiac event), a red countdown starts. If not canceled in 60s, it auto-texts the emergency contact with a message and a Google Maps link to the nearest hospital.

*(Hackathon Secret Weapon: Since it’s hard to force a real heart attack for the judges, we will build a hidden "Dev Toggles" screen in our Flutter app with buttons like `[Simulate HR Spike]` to flawlessly trigger the demo live.)*

---

## 🛠️ The Tech Stack
*   **Frontend (UI):** Flutter (Fast UI, cross-platform)
*   **Voice/Accessibility Packages:** `speech_to_text` & `flutter_tts`
*   **Backend System:** Python (FastAPI or Flask)
*   **Database & Auth:** Firebase (Firestore)
*   **AI Engine (SLM Simulation):** Groq API running Llama-3 (Blazing fast inference, mimics local edge processing without crashing the mobile device).
*   **APIs Used:**
    *   **Google Fit API** (Wearable data simulation/connection)
    *   **OpenWeatherMap API** (Environmental context)
    *   **Google Maps API** (Nearest hospital location for SOS)
    *   **Twilio / Local App Intent** (Triggering the SOS SMS)

---

## ✅ THE 24-HOUR HACKATHON CHECKLIST
*Split these tasks among the team right now!*

### Phase 1: Foundation & APIs (Hours 1-4)
- [ ] Initialize Flutter project & setup Firebase App.
- [ ] Initialize Python FastAPI backend environment.
- [ ] Obtain API Keys: Groq (Llama 3), Google Maps, OpenWeather.
- [ ] Obtain Google Fit OAuth/API credentials via Google Cloud Console.

### Phase 2: App & UI Development (Hours 4-12)
-[ ] Build User Onboarding Flow UI (Profile form storing to Firestore).
- [ ] Build Main Screen (High contrast, elderly-friendly, massive Voice Mic button).
- [ ] Implement `speech_to_text` so user voice converts to text.
- [ ] Implement `flutter_tts` so app can speak back.
- [ ] Build the "Hidden Dev Toggle Screen" (Buttons to force a HR=130 spike).

### Phase 3: Backend Logic & AI Engine (Hours 12-18)
- [ ] Write Python endpoint to receive `(WearableData, UserProfile, UserVoiceText, Weather)`.
- [ ] Write the Groq System Prompt instructing the AI to output evaluation JSON.
- [ ] Build the Weather integration (Take Lat/Long, get Temp/Condition).
-[ ] Build the 60-Second Auto-SOS Trigger logic & Countdown UI.

### Phase 4: Integration, Pitch & Polish (Hours 18-24)
- [ ] Connect Flutter frontend to Python backend.
- [ ] Test the demo flow end-to-end flawlessly using the hidden toggles.
- [ ] Build the final PPT (See strict format below).
- [ ] Practice the live presentation. 

---
---

# 📊 STRICT 7-SLIDE PPT TEMPLATE CONTENT
*(Rule Check from the organizers' PDF: Max 7 slides, NO paragraphs, MUST use specific headers, vague ideas penalized).* 

**Title Slide:** Team Falcon Claw (Add Member Names & Roll Nos). Project: Proactive AI Health Triage.

**SLIDE 1: Problem Statement**
*   AI-powered system predicting diseases using symptoms, wearables, and medical history.
*   **Core Issue:** Most health tech is *reactive* (waits for user to get sick).
*   **Target Problem:** During critical emergencies (e.g., heatstroke, cardiac arrest), users cannot type or explain symptoms.
*   **The Need:** A system that predicts crises *before* they escalate using background data.

**SLIDE 2: Current Challenges**
*   **Delayed Triage:** Apps wait for user input, losing the "golden hour" in emergencies.
*   **Context Blindness:** Wearables see a heart-rate spike but lack medical and environmental context (is it a run, or is it a stroke?).
*   **Inaccessibility:** Complex typing interfaces block elderly/chronically ill users from digital healthcare.

**SLIDE 3: Proposed Solution**
*   **Proactive AI Agent:** Continuously monitors wearable anomalies and initiates conversation if danger is sensed.
*   **Voice-First Interface:** Replaces typing with accessible STT (Speech-To-Text) and TTS (Text-to-Speech).
*   **Tri-Layer Context Engine:** Merges Medical Profile (Firebase) + Real-Time Wearable Data (Google Fit) + Live Symptom Voice Input.

**SLIDE 4: Solution Workflow**
*   **Monitor:** Background app scans Google Fit data continuously.
*   **Detect & Correlate:** Anomaly detected (e.g., HR > 130). AI fetches location weather (e.g., 42°C) via OpenWeather API.
*   **Engage:** App automatically asks user via Voice, *"Your heart rate is high in extreme heat. How do you feel?"*
*   **Evaluate:** Python SLM backend processes the voice response against user's clinical profile to predict the condition.

**SLIDE 5: Key Features**
*   **Environmental Triage:** Cross-references vitals with local weather context (e.g., heat exhaustion detection).
*   **On-Device Privacy First:** High-speed LLM processing built for Edge SLM architecture logic.
*   **Elderly-Accessible UI:** Zero-type, high-contrast, conversational app interface.
*   **Automated 60-Second SOS:** Countdown timer that auto-sends SMS + nearest hospital GPS to contacts if not manually canceled. 

**SLIDE 6: Technical Approach**
*   **Frontend:** Flutter (Mobile) with `speech_to_text` integration.
*   **Backend:** Python Fast API for fast data parsing and triage routing.
*   **AI Brain:** Groq API (Llama-3 model) for low-latency contextual medical inference.
*   **Data Pipeline:** Firebase (Profile/Auth) + Google Fit (Biometrics) + Weather & Maps APIs.

**SLIDE 7: Impact & Future Scope**
*   **Immediate Impact:** Secures early-warning care for the elderly, disabled, and isolated individuals.
*   **Reduced Fatalities:** Intercepts conditions like dehydration and arrhythmias before they require an ambulance.
*   **Future Scope:** 
    *   Full multi-agent deployment on edge smartwatch operating systems.
    *   Integration with IoT medical devices (Glucometers, BP Monitors).
