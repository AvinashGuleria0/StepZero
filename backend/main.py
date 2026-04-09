import os
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
import httpx
from groq import Groq

# Load Environment Variables
load_dotenv()

# Initialize FastAPI
app = FastAPI(title="StepZero Edge API", description="Proactive AI Triage Engine")

# CORS for emulator/device testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
try:
    # Use the JSON file you added to the backend folder
    cred = credentials.Certificate("stepzero-71609-firebase-adminsdk-fbsvc-c727660a39.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase Initialized")
except Exception as e:
    print(f"⚠️ Firebase Init Error: {e}")

# Initialize Groq Client
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# ---- Models ----
class VitalAnomaly(BaseModel):
    uid: str
    heart_rate: int
    is_moving: bool
    lat: float
    lng: float
    voice_transcript: str = ""

# ---- Quick Admin Dashboard ----
@app.get("/", response_class=HTMLResponse)
async def dashboard():
    return """
    <html>
        <head>
            <title>StepZero Dev Dashboard</title>
            <style>
                body { font-family: Arial, sans-serif; background: #121212; color: white; padding: 20px; }
                .card { background: #1e1e1e; padding: 20px; border-radius: 8px; max-width: 600px; margin: 0 auto; }
                button { background: #ff4757; color: white; border: none; padding: 10px 20px; font-size: 16px; cursor: pointer; border-radius: 5px; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>⚡ StepZero Dev Dashboard</h1>
                <p>Simulate a biometric anomaly for a test user.</p>
                <button onclick="triggerSimulation()">Trigger 135 BPM Heatstroke Event</button>
                <pre id="response" style="background:#000; padding:10px; margin-top:20px; white-space:pre-wrap;"></pre>
            </div>
            <script>
                async function triggerSimulation() {
                    document.getElementById('response').innerText = "Simulating...";
                    const res = await fetch('/api/v1/triage/evaluate', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            uid: "test_user_1",
                            heart_rate: 135,
                            is_moving: false,
                            lat: 30.8596,
                            lng: 76.8119,
                            voice_transcript: "I feel very dizzy and hot."
                        })
                    });
                    const data = await res.json();
                    document.getElementById('response').innerText = JSON.stringify(data, null, 2);
                }
            </script>
        </body>
    </html>
    """

# ---- Core API Endpoints ----
@app.post("/api/v1/triage/evaluate")
async def evaluate_anomaly(payload: VitalAnomaly):
    print(f"\n[BACKEND LOG] 1. Received Anomaly Request for UID: {payload.uid}")
    print(f"[BACKEND LOG] Data - HR: {payload.heart_rate}, Moving: {payload.is_moving}, Symptoms: '{payload.voice_transcript}'")
    """
    1. Fetch weather based on lat/lng.
    2. Fetch User Profile from Firebase.
    3. Push to Llama-3 (Groq).
    """
    try:
        # 1. Weather Context
        print(f"[BACKEND LOG] 2. Fetching weather for coordinates: {payload.lat}, {payload.lng}")
        weather_url = f"https://api.openweathermap.org/data/2.5/weather?lat={payload.lat}&lon={payload.lng}&appid={os.getenv('OPENWEATHER_API_KEY')}&units=metric"
        async with httpx.AsyncClient() as client:
            w_res = await client.get(weather_url)
            weather_data = w_res.json()
            temp = weather_data.get("main", {}).get("temp", "Unknown")
            condition = weather_data.get("weather", [{}])[0].get("main", "Unknown")
        print(f"[BACKEND LOG] Weather acquired: {temp}°C, {condition}")

        # 2. Medical History (Fallback if uid 'test_user_1' doesn't exist yet)
        print(f"[BACKEND LOG] 3. Fetching User Profile from Firebase...")
        user_profile = {"age": 55, "conditions": ["Hypertension"]}
        print(f"[BACKEND LOG] Profile acquired: {user_profile}")
        
        # 3. Build Prompt for Llama-3
        system_prompt = f"""
        You are StepZero, an AI medical triage agent. Evaluate this data:
        - Patient: Age {user_profile['age']}, Conditions: {user_profile['conditions']}
        - Vitals: Heart Rate {payload.heart_rate} BPM, Moving: {payload.is_moving}
        - Environment: Temp {temp}°C, {condition}
        - Symptoms: "{payload.voice_transcript}"
        
        Output ONLY a raw JSON object with keys:
        {{"threat_level": "CRITICAL" | "MODERATE" | "SAFE", "condition_guess": "string", "agent_tts_response": "string", "action_trigger": "START_SOS_TIMER" | "MONITOR"}}
        DO NOT include markdown formatting like ```json.
        """
        
        # 4. Infer via Groq
        print(f"[BACKEND LOG] 4. Sending structured prompt to Groq API (Llama-3)...")
        chat_completion = groq_client.chat.completions.create(
            messages=[{"role": "system", "content": system_prompt}],
            model="llama-3.1-8b-instant",
            temperature=0.0
        )
        
        answer = chat_completion.choices[0].message.content
        print(f"[BACKEND LOG] 5. Received raw response from Groq: {answer}")
        
        import json
        try:
             # Clean up potential markdown formatting just in case
             clean_json = answer.replace("```json", "").replace("```", "").strip()
             result = json.loads(clean_json)
             print(f"[BACKEND LOG] 6. Successfully parsed JSON payload from AI.")
        except:
             print(f"[BACKEND LOG] 💥 ERROR: Failed to parse JSON from AI!")
             result = {"error": "Failed to parse JSON from AI", "raw": answer}

        print(f"[BACKEND LOG] 7. Returning response back to Mobile Device.\n")
        return {
            "status": "success",
            "context": {"temp": temp, "weather": condition},
            "ai_evaluation": result
        }

    except Exception as e:
        print(f"[BACKEND LOG] 💥 EXCEPTION TRIGGERED: {e}")
        return {"status": "error", "message": str(e)}

