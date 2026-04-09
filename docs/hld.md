# High-Level Design (HLD) - Project StepZero
**Team Falcon Claw | CHITKARAVERSE 2026**

## 1. Architectural Overview
Project StepZero employs a **Client-Cloud Hybrid Architecture** designed for ultra-low latency and high reliability during medical emergencies. 

Instead of a traditional request-response web application, StepZero acts as a **Proactive Edge-Triggered Agent**. The mobile device (Edge) continuously monitors hardware sensors. The cloud backend acts strictly as an orchestration and inference layer, executing context-gathering and AI analysis only when an anomaly is pushed from the Edge.

---

## 2. System Architecture Diagram

```mermaid
graph TD
    %% Client/Edge Layer
    subgraph Edge Client (Flutter Application)
        UI[Voice-First UI & SOS Dashboard]
        HC[Android Health Connect]
        STT_TTS[On-Device STT / TTS]
        SMS[Hardware SMS Trigger]
    end

    %% Cloud/Backend Layer
    subgraph Cloud Orchestration (Python FastAPI)
        API_GW[API Router & Auth]
        Context_Mgr[Context & Profile Aggregator]
        Prompt_Eng[LLM Prompt Builder]
    end

    %% External & Third-Party APIs
    subgraph Data & Inference Layer
        FB[(Firebase Firestore & Auth)]
        LLM[Groq API: Llama-3 8B]
        Weather[OpenWeatherMap API]
        Maps[Google Maps Location Services]
    end

    %% Workflows
    HC -- Background Sync --> UI
    UI -- "1. Voice Text + Biometrics" --> API_GW
    
    API_GW --> Context_Mgr
    Context_Mgr -- "2. Fetch Medical History" --> FB
    Context_Mgr -- "3. Fetch Weather/Location Context" --> Weather
    
    Context_Mgr --> Prompt_Eng
    Prompt_Eng -- "4. Triage Request" --> LLM
    LLM -- "5. Structured JSON Diagnosis" --> Prompt_Eng
    
    Prompt_Eng -- "6. Agent Response + Action" --> API_GW
    API_GW --> UI
    
    UI -- "7. Trigger Warning/Audio" --> STT_TTS
    UI -- "8. Countdown Complete" --> SMS
    SMS -- "9. Emergency Dispatch" --> Maps
```

*(Note: You can copy and paste the above code block into any Mermaid JS viewer like mermaid.live to generate a beautiful system graphic for your GitHub or PPT).*

---

## 3. High-Level Components

### 3.1 Client Edge Application (Flutter)
The frontend is responsible for the user interface and physical hardware interactions.
*   **Sensor Polling:** Passively queries Google Fit / Android Health Connect for vital anomalies.
*   **Audio Processing:** Utilizes local device hardware to convert Speech-to-Text (STT) and Text-to-Speech (TTS) to reduce audio stream payload sizes. Only text strings are sent to the cloud.
*   **Action Execution:** Owns the ultimate authority to bypass APIs and use the mobile carrier’s native SMS network for SOS alerts, ensuring messages send even on low 2G/3G data networks.

### 3.2 Logic & Orchestration Backend (FastAPI / Python)
The central nervous system of StepZero. It is entirely stateless, built for speed and asynchronous processing.
*   **Context Aggregation (The Tri-Layer Merge):** It acts as the middleman that grabs the user's incoming payload, reaches into the Database (Medical Profile), reaches into the Weather API (Environment), and stitches them together.
*   **AI Gateway:** Manages the communication with the Large/Small Language Model. It applies strict "System Prompting" to prevent AI hallucinations, forcing the model to reply in rigid JSON formats.

### 3.3 Data Storage (Firebase)
Handles all persistent data requirements.
*   **Firebase Authentication:** Secures user identities.
*   **Cloud Firestore:** A NoSQL structure optimized for rapid reading of the user's base medical profiles, allergies, and emergency contact details. 

### 3.4 Inference Engine (Llama-3 via Groq)
*   **Why Groq?** In medical emergencies, waiting 5-10 seconds for standard ChatGPT generation can cause user panic. Groq provides LPU (Language Processing Unit) speeds, outputting hundreds of tokens per second.
*   **Role:** Strictly evaluates the aggregated data matrix to predict the disease, assess severity (CRITICAL vs WARNING vs NORMAL), and define the next executable step.

---

## 4. Communication Protocols & Security
*   **Client to Backend:** HTTPS REST APIs utilizing JSON payloads.
*   **Authentication:** Firebase Bearer Tokens attached to Flutter HTTP headers. Validated by FastAPI before any medical profiles are pulled.
*   **Data Minimization:** Continuous wearable data is *not* continuously streamed to the server. The server is only pinged when the local Flutter app calculates an anomaly, protecting user privacy and reducing server load.
