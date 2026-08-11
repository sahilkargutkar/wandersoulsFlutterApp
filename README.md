<p align="center">
  <img src="assets/images/readme_banner.png" alt="WanderSouls Banner" width="100%" />
</p>

<p align="center">
  <a href="#"><img src="assets/logo-main.svg" alt="WanderSouls Logo" width="120" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <strong>📣 NEW: AI-generated day-by-day itineraries, now with collaborative editing — <a href="#-features">see it below</a></strong>
</p>

<h1 align="center">Your ultimate AI travel planning app</h1>

<p align="center">
  <a href="#">WanderSouls</a>: an alternative to TripIt, Wanderlog, Google Trips...<br/>
  WanderSouls offers everything you need to plan a trip, organize the details,<br/>
  and travel with a group — without twelve tabs open.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter&logoColor=white&style=for-the-badge" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white&style=for-the-badge" alt="Dart" />
  <img src="https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white&style=for-the-badge" alt="FastAPI" />
  <img src="https://img.shields.io/badge/.NET_Core-512BD4?logo=.net&logoColor=white&style=for-the-badge" alt=".NET Core" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?logo=mongodb&logoColor=white&style=for-the-badge" alt="MongoDB" />
</p>

<p align="center">
  <a href="#-getting-started"><strong>Explore the docs »</strong></a>
  &nbsp;·&nbsp;
  <a href="#-demo"><strong>Watch the demo »</strong></a>
</p>

<p align="center">
  <a href="https://github.com/<your-org>/wander-souls/issues/new?labels=bug">Report Bug</a>
  ·
  <a href="https://github.com/<your-org>/wander-souls/issues/new?labels=enhancement">Request Feature</a>
  ·
  <a href="LICENSE">License</a>
</p>

---

## 🔌 See it in action

<p align="center">
  <img src="assets/gifs/app_demo.gif" alt="WanderSouls demo — AI itinerary generation and the timeline editor" width="720" />
</p>

> Drop a 15–25s screen recording at `assets/gifs/app_demo.gif` — onboarding → AI itinerary generated → drag-and-drop timeline edit reads best end to end.

## ✨ Features

|                                                                                            |                                                                                             |
| ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| <img src="assets/gifs/features/ai_itinerary.gif" alt="AI itinerary generator" width="360" /><br/><sub>🤖 AI itinerary generator</sub> | <img src="assets/gifs/features/places_explorer.gif" alt="Google Places destination explorer" width="360" /><br/><sub>🗺️ Destination explorer (Google Places API)</sub> |
| <img src="assets/gifs/features/timeline_editor.gif" alt="Drag and drop timeline editor" width="360" /><br/><sub>📅 Drag-and-drop timeline editor</sub> | <img src="assets/gifs/features/collab_planning.gif" alt="Collaborative trip planning" width="360" /><br/><sub>👥 Collaborative planning</sub> |

> Same idea as above — a short capture per feature at each `assets/gifs/features/*.gif` path. Keep each under ~5MB so the grid loads fast on GitHub.

---

## 📋 Intro

- AI-generated, cost-optimized day-by-day itineraries — transport, lodging, food, and sightseeing in one plan
- Rich destination data pulled live from the Google Places API (New): ratings, reviews, hours, photos
- Drag-and-drop timeline editing on any active trip
- Invite friends or family to co-edit an itinerary in real time
- Keep tickets, bookings, and confirmation PDFs attached to the trip they belong to

## 🛠️ Tech Stack

- Flutter (v3.22+) · Dart · BLoC pattern · Dio HTTP client · ScreenUtil
- .NET Core Web API on Azure App Services — auth, trip metadata, collaborators, files
- FastAPI (Python 3.10+) AI proxy — prompt schemas + JSON validation against Mistral AI / OpenAI
- MongoDB Atlas
- Google Places API (New) & Google Maps SDK

## 🗺️ System Architecture

```mermaid
graph TD
    A[Flutter App] -->|HTTPS Requests| B[.NET Core Backend on Azure]
    A -->|Direct APIs| C[Google Places API New]
    A -->|AI Itinerary Calls| B
    B -->|DB Queries| D[(MongoDB Atlas)]
    B -->|Prompt Forwarding| E[FastAPI AI Service]
    E -->|Generative Calls| F[Mistral AI / OpenAI]
```

---

## 🚀 Getting Started

**Prerequisites:** Flutter SDK (v3.22+) · Python (3.10+) · Google Places API credentials

**1. Mobile client**
```bash
git clone https://github.com/<your-org>/wander-souls.git && cd wander-souls
echo "GOOGLE_API_KEY=your_google_key_here" > .env
flutter pub get && flutter run
```

**2. AI service**
```bash
cd ai_service
echo "MISTRAL_API_KEY=your_mistral_key_here" > .env
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 💛 Support the Project

If WanderSouls saved you some trip-planning headaches:

- ⭐ Star the repo — it's the easiest way to help others find it
- ☕ [Buy me a coffee](https://www.buymeacoffee.com/<your-handle>)
- 🐛 [Open an issue](https://github.com/<your-org>/wander-souls/issues) for bugs or ideas

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=<your-org>/wander-souls&type=Date)](https://star-history.com/#<your-org>/wander-souls&Date)

## 📄 License

This repository's source code is available under the [MIT License](LICENSE).