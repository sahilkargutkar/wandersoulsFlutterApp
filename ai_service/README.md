# WanderSouls AI Itinerary Generator

A FastAPI service that uses OpenAI (GPT-4o-mini) to generate personalized day-by-day travel itineraries.

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure API key:**
   Copy `.env.example` to `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-key-here
   ```

3. **Run the server:**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Test:**
   - Swagger docs: http://localhost:8000/docs
   - Health check: http://localhost:8000/health

## API Endpoint

### `POST /generate-itinerary`

Generates a day-by-day itinerary based on trip details.

**Request:**
```json
{
  "destination": "Paris, France",
  "startDate": "2026-07-01T00:00:00Z",
  "endDate": "2026-07-05T00:00:00Z",
  "whoIsGoing": "couple",
  "travelTastes": ["culture", "food"],
  "budget": {
    "budgetType": "moderate",
    "totalEstimated": 5000,
    "currency": "USD",
    "byCategory": {
      "transportation": 1000,
      "accommodation": 2000,
      "food": 1000,
      "activities": 1000
    }
  }
}
```

**Response:** Structured day-by-day itinerary with activities, costs, and tips.
