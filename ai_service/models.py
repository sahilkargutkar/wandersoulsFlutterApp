from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date


# ──────────────────────── Request Models ────────────────────────

class BudgetCategoryRequest(BaseModel):
    transportation: float = 0.0
    accommodation: float = 0.0
    food: float = 0.0
    activities: float = 0.0


class BudgetRequest(BaseModel):
    budgetType: str = "flexible"
    totalEstimated: float = 0.0
    currency: str = "USD"
    byCategory: BudgetCategoryRequest = BudgetCategoryRequest()


class ItineraryRequest(BaseModel):
    destination: str
    startDate: str
    endDate: str
    whoIsGoing: str = "solo"
    travelTastes: List[str] = []
    budget: BudgetRequest = BudgetRequest()
    tripName: Optional[str] = None
    description: Optional[str] = None


# ──────────────────────── Response Models ────────────────────────

class ActivityResponse(BaseModel):
    time: str
    name: str
    description: str
    category: str
    estimatedCost: float = 0.0
    duration: str = ""
    tips: str = ""
    imageUrl: Optional[str] = None


class DayItinerary(BaseModel):
    day: int
    date: str
    title: str
    activities: List[ActivityResponse] = []


class ItineraryResponse(BaseModel):
    tripName: str
    destination: str
    startDate: str
    endDate: str
    totalDays: int
    itinerary: List[DayItinerary] = []
    estimatedTotalCost: float = 0.0
    travelTips: List[str] = []
