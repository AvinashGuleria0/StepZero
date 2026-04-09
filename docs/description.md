# Project Description - StepZero
**Team:** Falcon Claw | **Hackathon:** CHITKARAVERSE 2026 – AI Impact

> **Tagline:** Shifting healthcare from a reactive necessity to a proactive, continuous, and intelligent guardian. 

---

## 1. Project Overview
**StepZero** is an advanced, proactive, Voice-First AI Healthcare Agent designed to predict diseases and assist in the early diagnosis of critical medical events. By actively listening to continuous wearable biometric data, analyzing the user's deep medical history, and correlating symptoms with real-time environmental APIs, StepZero detects health anomalies *before* the user manually asks for help. 

The application is built heavily around the concept of the **"Golden Hour"** in medicine—the critical time window following a health emergency where prompt treatment significantly increases the chances of survival.

## 2. The Core Problem: The Flaw of "Reactive" Healthcare
Current digital healthcare solutions suffer from three fatal flaws:
1. **Delayed Triage (Reactive Tools):** Users must first realize they are sick, open an app, and manually type out symptoms. During severe crises (e.g., cardiac arrest, heatstroke, or severe panic attacks), users are incapacitated and physically unable to request help.
2. **Data Silos (Lack of Context):** A smartwatch can tell a user their heart rate is 135 BPM, but it doesn't know *why*. It cannot cross-reference that biometric spike with the fact that it is currently 42°C outside (indicating heatstroke) or that the user has a family history of heart disease (indicating a cardiac event).
3. **Inaccessibility:** Complex typing interfaces block the most vulnerable demographic—the elderly—from quickly utilizing digital health aides. 

## 3. The StepZero Solution
Project StepZero introduces an **"Intercept and Evaluate"** methodology. We don't wait for the user to tell us they are sick. We silently monitor baseline health numbers in the background. If a threshold is broken, the phone acts as an intelligent agent, "waking up" to ask the user how they feel using localized voice (Text-to-Speech) and listening for their symptoms (Speech-to-Text).

---

## 4. Deep Dive: The Tri-Layer Contextual Triage System
Our AI does not rely on a single source of truth. The underlying Llama-3 (Groq API) model is fed a highly specific, dynamically generated prompt built from three distinct layers:
*   **Layer 1 - Medical History (Firebase):** Gathered during user onboarding. Includes exact Age, Weight, Chronic Conditions (e.g., Hypertension), Current Medications, and Allergies.
*   **Layer 2 - Real-Time Biometrics (Health Connect):** Pulled locally via Android Health Connect. Includes resting Heart Rate (HR), Step Count (to determine if the HR spike is due to exercise or an anomaly), and Sleep data.
*   **Layer 3 - Environmental Context (Weather API):** Uses precise device GPS coordinates to pull live OpenWeatherMap data. This prevents AI hallucination. *Example: Recognizing heat exhaustion in the summer, or respiratory aggravation during high-humidity or cold weather drops.*

---

## 5. Granular Feature Breakdown 

### A. Background Edge-Monitoring
Instead of draining battery by continuously streaming heart-rate data to a cloud server, the Flutter edge client runs localized cron-jobs. It calculates baseline shifts natively on the mobile device. The cloud API is only triggered when the local threshold (e.g., High HR + Zero Movement) is broken.

### B. Elderly-Accessible "Voice-First" UI
We eliminated complex medical jargon drop-downs. The interface is high-contrast and features massive interaction buttons. The AI utilizes a Text-to-Speech (TTS) engine to speak to the patient like a real human doctor and listens via a highly accurate Speech-to-Text (STT) engine. Users can literally just say, *"My chest feels heavy and my left arm hurts,"* and the system handles the rest.

### C. The 60-Second Auto-SOS Bypass (Fail-safe Engineering)
In the event that the AI analyzes the multi-layer data and returns a `"risk_level": "CRITICAL"`, the app initiates the "StepZero SOS Protocol":
1. The screen turns red and displays a **60-second countdown**.
2. An audio prompt announces the escalation and gives the user the chance to say "Cancel" or hit a large cancel button to prevent false alarms.
3. **Native SMS Fallback:** If the timer hits zero, the app does *not* rely on internet-based cloud services to send the SOS (which can fail in poor data zones). Instead, it taps into the device's physical cellular hardware to send a standard local SMS to the designated emergency contact. 
4. **Geolocation Injection:** The emergency SMS automatically appends a Google Maps URL featuring the user's exact current GPS location.

---

## 6. Detailed Incident Workflow
*(What happens when a health emergency strikes?)*

1. **LISTEN:** A 55-year-old user is sitting on the couch. Their wearable records a heart rate spike of 135 BPM while the accelerometer registers 0 steps.
2. **DETECT:** The Android Health Connect integration spots this anomaly. The Flutter app grabs current GPS data, hits the OpenWeather API (noting it is 42°C outside), and packages this local data.
3. **INTERCEPT:** The app brings the screen to life. Using TTS, it says: *"Hi, your vitals show a high resting heart rate. Are you feeling okay?"*
4. **EVALUATE:** The user groggily responds, *"I feel dizzy and I've been sweating."* This voice text, along with the 135 BPM, the 42°C weather data, and the user's Firebase health profile (Hypertension), is sent to the Python FastAPI backend.
5. **AI INFERENCE:** The Python server structures a rigid prompt and passes it to Groq Llama-3. The LLM accurately deduces extreme dehydration/heat-exhaustion. It returns a strict JSON payload flagging the event as "CRITICAL".
6. **ESCALATE:** The phone receives the payload, triggers the 60-second countdown, and ultimately fires the Native SOS SMS with the user's location to their loved ones.

---

## 7. Privacy & Edge AI Vision
We deeply understand that healthcare data is incredibly sensitive.
*   **Minimal Data Transit:** StepZero does not stream biometrics over the internet. Calculations happen on-device, and cloud calls are strictly limited to anomaly events.
*   **Prompt-Driven API Masking:** For the 24-hour hackathon MVP constraint, we utilize the Groq API (Llama-3) to simulate Small Language Model (SLM) processing speeds. 
*   **The Ultimate Future Scope:** The architecture is purposefully designed so that the Groq API can be hot-swapped for a fully native, on-device `llama.cpp` model in the future. This would allow the entire triage and AI inference loop to occur locally on the user's phone completely offline, ensuring 100% data privacy.

---

### StepZero: Build What Matters.
Team Falcon Claw has built StepZero not just as a proof-of-concept AI integration, but as a genuinely feasible, production-ready blueprint aimed at democratizing proactive clinical-level triage for everyone, anywhere.