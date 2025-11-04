# DreamLnds AI Planner Architecture

## Overview

The DreamLnds planner uses a **multi-agent AI system** combined with **Google Maps APIs** to transform user dreams into concrete, actionable itineraries. This document explains the complete architecture, data flow, and API usage.

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
│  (React Frontend - Chat Interface + Itinerary Views)           │
└────────────────────────┬────────────────────────────────────────┘
                         │ tRPC
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND API LAYER                            │
│  (Express + tRPC - server/routers/planner.ts)                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌──────────────────┐           ┌──────────────────┐
│   AI ORCHESTRATOR│           │  CACHE LAYER     │
│   (LLM Agents)   │◄─────────►│  (Supabase DB)   │
└────────┬─────────┘           └──────────────────┘
         │
         │ Coordinates 4 specialized agents
         │
    ┌────┴────┬─────────┬──────────┐
    ▼         ▼         ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Intent  │ │Activity│ │Logistics│ │Day     │
│Resolver│ │Finder  │ │Agent   │ │Planner │
└────┬───┘ └───┬────┘ └───┬────┘ └───┬────┘
     │         │          │          │
     │         │          │          │
     └─────────┴──────────┴──────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │  GOOGLE MAPS APIs    │
         │  (13 APIs)           │
         └──────────────────────┘
```

---

## Agent System Breakdown

### 1. **Intent Resolver Agent**

**Purpose:** Understands user's dream and extracts structured information through conversation.

**AI Model:** OpenAI GPT-4 (via Manus Built-in API)

**Input:**
- User messages (natural language)
- Conversation history
- Current context (destination, dates, budget, etc.)

**Output:**
- Clarifying questions
- Extracted structured data:
  ```json
  {
    "destination": "Paris, France",
    "startDate": "2025-06-15",
    "endDate": "2025-06-20",
    "numberOfDays": 5,
    "budget": "moderate",
    "interests": ["art", "food", "history"],
    "travelStyle": "cultural exploration"
  }
  ```

**APIs Used:**
- **Manus LLM API** (invokeLLM function)
- **Google Geocoding API** - Convert city names to coordinates
- **Google Time Zone API** - Get timezone for destination

**Function:** `trpc.planner.chat`

**Progressive Logic:**
1. User says "Europe" → Suggest 3 countries
2. User says "France" → Suggest 3 cities
3. User says "Paris" → Ask about duration
4. No dates? → Ask summer/winter preference
5. No budget? → Assume "moderate", offer to adjust

---

### 2. **Activity Finder Agent**

**Purpose:** Discovers activities, restaurants, hotels, and attractions for the destination.

**AI Model:** OpenAI GPT-4 + Google Places API

**Input:**
- Destination (city + coordinates)
- User interests
- Budget level
- Travel style

**Output:**
- List of categorized activities:
  ```json
  {
    "activities": [
      {
        "placeId": "ChIJD7fiBh9u5kcRYJSMaMOCCwQ",
        "name": "Eiffel Tower",
        "category": "landmark",
        "rating": 4.6,
        "userRatingsTotal": 123456,
        "priceLevel": 2,
        "photos": ["photo_reference_1", "photo_reference_2"],
        "address": "Champ de Mars, 5 Avenue Anatole France",
        "location": { "lat": 48.8584, "lng": 2.2945 },
        "openingHours": {...},
        "estimatedDuration": 120
      }
    ],
    "restaurants": [...],
    "hotels": [...]
  }
  ```

**APIs Used:**
1. **Google Places API (New)** - Text search for activities
   - Endpoint: `places:searchText`
   - Use: Find places by query ("best restaurants in Paris")
   
2. **Google Places API** - Place details
   - Endpoint: `Place Details`
   - Use: Get photos, reviews, hours, contact info

3. **Manus LLM API** - Categorize and rank results
   - Use: AI decides which places match user's dream best

**Caching Strategy:**
- Cache place details for 7 days (table: `cache_places_details`)
- Key: `place_id`
- Reduces API costs by 80%+

**Function:** `server/services/activityFinder.ts`

---

### 3. **Logistics Agent**

**Purpose:** Calculates travel times, routes, and optimal sequencing of activities.

**AI Model:** Rule-based + Google Routes API

**Input:**
- List of activities with locations
- Start/end times for each activity
- Transportation mode (walking, transit, driving)

**Output:**
- Travel time matrix
- Optimized route order
- Transportation instructions
  ```json
  {
    "routes": [
      {
        "from": "Eiffel Tower",
        "to": "Louvre Museum",
        "distance": "3.2 km",
        "duration": "12 minutes",
        "mode": "walking",
        "polyline": "encoded_polyline_string",
        "steps": [...]
      }
    ]
  }
  ```

**APIs Used:**
1. **Google Routes API** - Optimal routes between points
   - Endpoint: `routes:computeRoutes`
   - Use: Get best route with real-time traffic

2. **Google Distance Matrix API** - Travel times between multiple points
   - Use: Calculate time matrix for all activities

3. **Google Directions API** - Step-by-step navigation
   - Use: Detailed turn-by-turn directions

4. **Google Roads API** - Snap coordinates to roads
   - Use: Ensure accurate route tracking

**Caching Strategy:**
- Cache routes for 24 hours (table: `cache_routes`)
- Key: `origin_lat_lng + destination_lat_lng + mode`
- Invalidate when traffic patterns change significantly

**Function:** `server/services/logisticsAgent.ts`

---

### 4. **Day Planner Agent**

**Purpose:** Assembles activities into a realistic, enjoyable daily schedule.

**AI Model:** OpenAI GPT-4 (with function calling)

**Input:**
- Categorized activities from Activity Finder
- Travel times from Logistics Agent
- User preferences (early bird vs night owl, pace)
- Number of days

**Output:**
- Complete day-by-day itinerary:
  ```json
  {
    "days": [
      {
        "dayNumber": 1,
        "date": "2025-06-15",
        "theme": "Iconic Paris",
        "activities": [
          {
            "time": "09:00",
            "duration": 120,
            "type": "activity",
            "placeId": "ChIJ...",
            "name": "Eiffel Tower",
            "description": "Start your Paris adventure...",
            "travelFromPrevious": {
              "duration": 0,
              "mode": "start"
            }
          },
          {
            "time": "11:30",
            "duration": 90,
            "type": "meal",
            "placeId": "ChIJ...",
            "name": "Café de Flore",
            "travelFromPrevious": {
              "duration": 15,
              "mode": "walking"
            }
          }
        ]
      }
    ]
  }
  ```

**AI Decision Making:**
1. **Pacing:** Ensures 2-3 hour breaks, avoids burnout
2. **Logistics:** Activities in same area grouped together
3. **Timing:** Museums in morning, restaurants at meal times
4. **Balance:** Mix of must-see + hidden gems
5. **Flexibility:** Buffer time for spontaneity

**APIs Used:**
- **Manus LLM API** with structured output (JSON schema)
- **Google Places API** - Opening hours validation
- **Google Street View Static API** - Preview images for each location

**Function:** `trpc.planner.generateItinerary`

---

## Complete Data Flow Example

### User Journey: "I want to visit Paris"

```
1. USER: "I want to visit Paris"
   ↓
2. Intent Resolver Agent (LLM)
   - Asks: "How many days?"
   - Asks: "What's your budget?"
   - Asks: "What are you interested in?"
   ↓
3. USER: "5 days, moderate budget, love art and food"
   ↓
4. Intent Resolver Agent
   - Extracts: { destination: "Paris", days: 5, budget: "moderate", interests: ["art", "food"] }
   - Calls Google Geocoding API → Gets coordinates
   ↓
5. Activity Finder Agent
   - Calls Google Places API (New) → "best art museums in Paris"
   - Calls Google Places API (New) → "best restaurants in Paris"
   - LLM ranks results by user interests
   - Returns 50+ activities/restaurants
   ↓
6. Logistics Agent
   - Calls Google Distance Matrix API → Travel times between all places
   - Calls Google Routes API → Optimal routes
   - Creates travel time matrix
   ↓
7. Day Planner Agent (LLM with function calling)
   - Receives: activities + travel times + user preferences
   - LLM decides: "Day 1: Louvre → Lunch at Le Marais → Notre Dame"
   - Validates opening hours with Google Places API
   - Generates complete 5-day itinerary
   ↓
8. SAVE TO DATABASE
   - Itinerary saved to Supabase (itineraries table)
   - Timeline items saved (timeline_items table)
   - Cache all API responses
   ↓
9. RETURN TO USER
   - Display in Grid View / Timeline View / Map View
```

---

## API Usage Summary

### Google Maps APIs (13 Total)

| API | Purpose | Usage Frequency | Caching |
|-----|---------|-----------------|---------|
| **Places API (New)** | Search activities | High | 7 days |
| **Places API** | Place details | High | 7 days |
| **Geocoding API** | City → Coordinates | Medium | Permanent |
| **Routes API** | Optimal routes | High | 24 hours |
| **Distance Matrix API** | Travel time matrix | High | 24 hours |
| **Directions API** | Turn-by-turn | Medium | 24 hours |
| **Time Zone API** | Destination timezone | Low | Permanent |
| **Street View Static API** | Location previews | Medium | 30 days |
| **Maps JavaScript API** | Interactive map display | High | N/A (frontend) |
| **Maps Static API** | Static map images | Low | 30 days |
| **Maps Embed API** | Embedded maps | Low | N/A (frontend) |
| **Geolocation API** | User location | Low | N/A (frontend) |
| **Roads API** | Snap to roads | Low | 24 hours |

### Manus Built-in APIs

| API | Purpose | Usage |
|-----|---------|-------|
| **LLM API** | All AI agent reasoning | Very High |
| **Storage API** | Store itinerary exports | Medium |
| **Notification API** | Alert user when itinerary ready | Low |

---

## Cost Optimization Strategies

### 1. **Aggressive Caching**
- Places: 7 days (rarely change)
- Routes: 24 hours (traffic patterns)
- Geocoding: Permanent (coordinates don't change)
- AI responses: 1 hour (same query = same result)

### 2. **Batch Requests**
- Use Distance Matrix for multiple origins/destinations in one call
- Batch place details requests

### 3. **Smart Fallbacks**
- If cache hit → Return immediately
- If API fails → Use LLM knowledge as fallback
- If budget exceeded → Queue request for later

### 4. **Request Deduplication**
- If 2 users plan same city simultaneously → Share results

---

## Database Schema for Caching

### `cache_places_details`
```sql
CREATE TABLE cache_places_details (
  place_id VARCHAR(255) PRIMARY KEY,
  data JSONB NOT NULL,
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  INDEX idx_expires (expires_at)
);
```

### `cache_routes`
```sql
CREATE TABLE cache_routes (
  id UUID PRIMARY KEY,
  origin_lat DECIMAL(10, 8),
  origin_lng DECIMAL(11, 8),
  destination_lat DECIMAL(10, 8),
  destination_lng DECIMAL(11, 8),
  mode VARCHAR(50),
  data JSONB NOT NULL,
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  INDEX idx_route (origin_lat, origin_lng, destination_lat, destination_lng, mode)
);
```

### `cache_ai_responses`
```sql
CREATE TABLE cache_ai_responses (
  query_hash VARCHAR(64) PRIMARY KEY,
  prompt TEXT NOT NULL,
  response JSONB NOT NULL,
  model VARCHAR(100),
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP
);
```

---

## Error Handling & Fallbacks

### API Failures

1. **Google Maps API Down:**
   - Fallback to LLM knowledge
   - Show warning: "Using estimated data"
   - Queue for retry when API recovers

2. **LLM API Down:**
   - Use cached similar queries
   - Show error: "AI temporarily unavailable"

3. **Rate Limit Exceeded:**
   - Serve from cache
   - Queue new requests
   - Notify admin

### Conflict Resolution

When user drags activity to occupied time slot:

```javascript
// Detect conflict
if (newActivity.time overlaps existingActivity.time) {
  // Show dialog
  showConflictDialog({
    options: [
      "Replace existing activity",
      "Shift existing activity later",
      "Cancel this change"
    ]
  });
}
```

---

## Implementation Status

### ✅ Completed
- Intent Resolver Agent (basic)
- Day Planner Agent (basic)
- LLM integration
- Chat interface

### 🚧 In Progress
- Google Maps API integration
- Caching layer
- Activity Finder Agent

### 📋 TODO
- Logistics Agent
- Conflict detection
- Route optimization
- Real-time updates

---

## Next Steps for Development

1. **Implement Activity Finder** (`server/services/activityFinder.ts`)
   - Integrate Google Places API (New)
   - Add caching layer
   - Test with real queries

2. **Implement Logistics Agent** (`server/services/logisticsAgent.ts`)
   - Integrate Google Routes API
   - Calculate travel time matrix
   - Optimize route order

3. **Enhance Day Planner**
   - Use function calling for structured output
   - Add opening hours validation
   - Implement pacing logic

4. **Build Itinerary Views**
   - Grid View (desktop)
   - Timeline View (mobile)
   - Map View (with routes)

---

## Testing Strategy

### Unit Tests
- Each agent function independently
- Mock API responses
- Test edge cases (no results, API errors)

### Integration Tests
- Complete flow: chat → itinerary
- Test with different cities
- Verify caching works

### Load Tests
- Simulate 100 concurrent users
- Measure API costs
- Verify cache hit rate > 70%

---

## Monitoring & Analytics

### Key Metrics
1. **API Usage:** Calls per endpoint per day
2. **Cache Hit Rate:** % of requests served from cache
3. **Generation Time:** Seconds to create itinerary
4. **User Satisfaction:** Itinerary acceptance rate
5. **Cost per Itinerary:** Total API cost

### Alerts
- API budget > 80% → Notify admin
- Cache hit rate < 50% → Investigate
- Generation time > 30s → Optimize

---

This architecture ensures DreamLnds creates high-quality, realistic itineraries while keeping API costs manageable through intelligent caching and agent coordination.
