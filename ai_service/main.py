import json
import os
from datetime import datetime

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from mistralai.client import Mistral

from models import (
    ActivityResponse,
    DayItinerary,
    ItineraryRequest,
    ItineraryResponse,
)

load_dotenv()

app = FastAPI(
    title="WanderSouls AI Itinerary Generator",
    description="Generates personalized day-by-day travel itineraries using Mistral AI",
    version="1.0.0",
)

# CORS – allow Flutter app from any origin during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Mistral(api_key=os.getenv("MISTRAL_API_KEY"))


def _build_prompt(req: ItineraryRequest) -> str:
    """Build the system + user prompt for OpenAI."""

    # Calculate number of days
    try:
        start = datetime.fromisoformat(req.startDate.replace("Z", "+00:00"))
        end = datetime.fromisoformat(req.endDate.replace("Z", "+00:00"))
        total_days = max((end - start).days, 1)
    except Exception:
        total_days = 3

    budget_info = (
        f"Budget type: {req.budget.budgetType}, "
        f"Total estimated: {req.budget.totalEstimated} {req.budget.currency}, "
        f"Transportation: {req.budget.byCategory.transportation}, "
        f"Accommodation: {req.budget.byCategory.accommodation}, "
        f"Food: {req.budget.byCategory.food}, "
        f"Activities: {req.budget.byCategory.activities}"
    )

    tastes = ", ".join(req.travelTastes) if req.travelTastes else "general sightseeing"

    system_prompt = """You are an expert travel planner AI. Generate a detailed day-by-day travel itinerary.
You MUST respond with ONLY valid JSON matching the exact schema below – no markdown, no extra text.

JSON Schema:
{
  "tripName": "string",
  "destination": "string",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "totalDays": number,
  "itinerary": [
    {
      "day": number,
      "date": "YYYY-MM-DD",
      "title": "string (catchy day title)",
      "activities": [
        {
          "time": "HH:MM AM/PM",
          "name": "string",
          "description": "string (2-3 sentences)",
          "category": "string (one of: Landmark, Food, Adventure, Culture, Shopping, Nature, Entertainment, Transport, Accommodation)",
          "estimatedCost": number,
          "duration": "string (e.g. '2 hours')",
          "tips": "string (one helpful tip)"
        }
      ]
    }
  ],
  "estimatedTotalCost": number,
  "travelTips": ["string (3-5 general travel tips)"]
}

Rules:
- Plan 4-6 activities per day covering morning, afternoon, and evening.
- Include a mix of the traveler's interests.
- Keep estimated costs realistic for the destination.
- Include local cuisine and hidden gems.
- Factor in travel time between locations.
- The total estimated cost should be within the stated budget."""

    user_prompt = f"""Plan a {total_days}-day trip to {req.destination}.

Travel group: {req.whoIsGoing}
Interests: {tastes}
{budget_info}
Start date: {req.startDate}
End date: {req.endDate}

Generate a complete day-by-day itinerary."""

    return system_prompt, user_prompt


@app.post("/generate-itinerary", response_model=ItineraryResponse)
async def generate_itinerary(request: ItineraryRequest):
    """Generate an AI-powered travel itinerary."""

    if not os.getenv("MISTRAL_API_KEY"):
        raise HTTPException(status_code=500, detail="Mistral API key not configured")

    system_prompt, user_prompt = _build_prompt(request)

    try:
        response = client.chat.complete(
            model="mistral-small-latest",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.3,
            response_format={"type": "json_object"},
        )

        raw = response.choices[0].message.content
        data = json.loads(raw)

        # Build validated response
        itinerary = ItineraryResponse(
            tripName=data.get("tripName", request.tripName or f"Trip to {request.destination}"),
            destination=data.get("destination", request.destination),
            startDate=data.get("startDate", request.startDate),
            endDate=data.get("endDate", request.endDate),
            totalDays=data.get("totalDays", 1),
            itinerary=[
                DayItinerary(
                    day=d.get("day", i + 1),
                    date=d.get("date", ""),
                    title=d.get("title", f"Day {i + 1}"),
                    activities=[
                        ActivityResponse(
                            time=a.get("time", ""),
                            name=a.get("name", ""),
                            description=a.get("description", ""),
                            category=a.get("category", ""),
                            estimatedCost=float(a.get("estimatedCost", 0)),
                            duration=a.get("duration", ""),
                            tips=a.get("tips", ""),
                        )
                        for a in d.get("activities", [])
                    ],
                )
                for i, d in enumerate(data.get("itinerary", []))
            ],
            estimatedTotalCost=float(data.get("estimatedTotalCost", 0)),
            travelTips=data.get("travelTips", []),
        )

        return itinerary

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="AI returned invalid JSON. Please try again.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation failed: {str(e)}")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "WanderSouls AI Itinerary Generator"}
