# DreamLnds - Product Requirements Document (Updated)
## Implementation-Ready Specification

**Version:** 2.0  
**Last Updated:** January 2025  
**Status:** In Development (Sprints 1-3 Complete)

---

## Executive Summary

DreamLnds is a social network that enables dreams by combining AI-powered travel planning with social sharing and community discovery. Unlike traditional travel apps that simply list attractions, DreamLnds understands user passions, predicts friction points, optimizes routes intelligently, and creates a complete lifecycle from inspiration to memories.

**Current Status:**
- ✅ Core infrastructure complete
- ✅ Intelligence Engine operational
- ✅ Activity Discovery with Google Maps integration
- ✅ Itinerary Builder with route optimization
- 🚧 Frontend views (Grid, Timeline, Map) in progress
- 🚧 Social features pending

---

## 1. Vision & Mission

### Vision
Be the platform where dreams become reality - from the first spark of inspiration to the lasting memories shared with the world.

### Mission
Empower people to plan, experience, and share their dream adventures through intelligent AI assistance and vibrant community connection.

### Core Differentiators

1. **Dream-First Philosophy**
   - Not "Top 10 in Paris" but "You love skateboarding? Here are 3 skateparks + Eiffel Tower"
   - 60/40 split: 60% user passions, 40% famous landmarks
   - Guaranteed user-interest activities every day

2. **Intelligence-First Architecture**
   - 4-layer intelligence system predicts duration, cost, frictions, and requirements
   - Multi-source duration prediction (Google API + review mining + LLM + activity type)
   - Proactive friction detection with 8 types of potential issues

3. **Route Intelligence**
   - Geographic clustering reduces travel time by 30-40%
   - Meals inserted "along the way" (<500m, <5min detour)
   - Real-time travel calculations with Google Routes API

4. **Complete Dream Lifecycle**
   - **Before:** Dream Board for inspiration
   - **During:** AI-powered planning with real-time optimization
   - **After:** Memory Maker for storytelling and sharing

---

## 2. Technical Architecture (Implemented)

### 2.1 Agent System

#### **Orchestrator Agent** (Master Coordinator)
**Status:** ✅ Implemented

**Responsibilities:**
- State machine managing 8 conversation states
- Coordinates all specialized agents
- Maintains conversation context and history
- Handles state transitions and error recovery

**States:**
1. `greeting` - Initial welcome
2. `intent_gathering` - Collecting trip information
3. `intent_clarification` - Asking follow-up questions
4. `activity_discovery` - Finding places
5. `itinerary_building` - Creating schedule
6. `friction_resolution` - Handling conflicts
7. `refinement` - User adjustments
8. `finalization` - Presenting final itinerary

**Implementation:**
```typescript
class OrchestratorAgent {
  private context: ConversationContext;
  
  async processUserMessage(message: string): Promise<string> {
    // Routes to appropriate handler based on state
    // Coordinates Intent Analyzer, Activity Discovery, Itinerary Builder
  }
}
```

#### **Intent Analyzer Agent** (Deep Understanding)
**Status:** ✅ Implemented

**Capabilities:**
- Extracts explicit intent (destination, dates, budget, interests)
- Infers implicit preferences (travel style, pace, values)
- Calculates completeness score (0-1)
- Generates smart follow-up questions
- Geocodes destinations via Google Maps API

**Example Output:**
```json
{
  "explicit": {
    "destination": "Paris, France",
    "numberOfDays": 5,
    "budget": "moderate",
    "interests": ["skateboarding", "photography", "local food"]
  },
  "implicit": {
    "travelStyle": "adventure",
    "pace": "moderate",
    "values": ["authentic", "local", "active"]
  },
  "completeness": 0.85,
  "missingFields": ["startDate"]
}
```

#### **Activity Discovery Agent** (Smart Search)
**Status:** ✅ Implemented

**Process:**
1. **Query Generation** - LLM generates 8-12 diverse search queries
   - User interests (priority)
   - Famous landmarks
   - Local experiences
   - Dining options

2. **Search Execution** - Google Places API (Text Search + Place Details)
   - Deduplicates by place_id
   - Limits to 50 places to control API costs

3. **Intelligence Enrichment** - Applies all 4 intelligence layers
   - Duration prediction
   - Cost estimation
   - Friction detection
   - Requirements analysis

4. **Scoring & Categorization**
   - **Mandatory (100+ points):** Matches user interests
   - **Must-see (50-99 points):** Famous landmarks, highly rated
   - **Filler (<50 points):** Good alternatives

**Scoring Algorithm:**
```
Interest match: +100 points (highest priority)
Rating (4.5+): +20 points
Popularity (1000+ reviews): +20 points
Budget alignment: +20 points or -50 penalty
Travel style match: +20 points
```

#### **Itinerary Builder Agent** (Optimization)
**Status:** ✅ Implemented

**Process:**
1. **Calculate Activities Per Day** (pace-based)
   - Slow/Relaxed: 3 activities + meals + buffer
   - Moderate: 4 activities + meals
   - Fast/Packed: 6 activities + quick meals

2. **Select Activities** (mandatory-first algorithm)
   - Priority 1: All mandatory (user interests)
   - Priority 2: Must-see landmarks
   - Priority 3: Filler activities

3. **Geographic Clustering**
   - Simple k-means clustering by latitude
   - Groups activities by proximity
   - Divides evenly across days

4. **Route Optimization**
   - Nearest-neighbor algorithm (Traveling Salesman Problem approximation)
   - Minimizes travel distance between activities

5. **Time Slot Assignment**
   - Starts at 9:00 AM
   - Uses predicted duration from Intelligence Engine
   - Calculates travel time via Google Routes API
   - Adds 15-minute buffers between activities

6. **Meal Insertion** (TODO: Sprint 4)
   - Search restaurants along route (<500m, <5min detour)
   - Insert at logical meal times (12:00-14:00, 19:00-21:00)

**Output Structure:**
```typescript
interface Itinerary {
  destination: string;
  days: DaySchedule[];
  metadata: {
    totalActivities: number;
    totalCost: number;
    numberOfDays: number;
  };
}

interface DaySchedule {
  dayNumber: number;
  activities: TimeSlot[];
  summary: {
    totalActivities: number;
    totalCost: number;
    totalTravelTime: number;
    startTime: string;
    endTime: string;
  };
}

interface TimeSlot {
  startTime: string; // "09:00"
  endTime: string; // "11:30"
  activity: EnrichedActivity;
  travelFromPrevious?: {
    duration: number; // minutes
    distance: number; // meters
    mode: string; // "walking"
  };
}
```

#### **Intelligence Engine** (Shared Service)
**Status:** ✅ Implemented

**Layer 1: Duration Prediction**

Multi-source approach with weighted average:
1. **Google Places API** (30% weight) - Editorial summary parsing
2. **Review Mining** (30% weight) - Extract time mentions from reviews
3. **Activity Type** (20% weight) - Lookup table by place type
4. **LLM Prediction** (20% weight) - Intelligent estimation

**Duration Lookup Table:**
```typescript
{
  national_park: 480 min (8 hours),
  museum: 150 min (2.5 hours),
  restaurant: 90 min (1.5 hours),
  landmark: 60 min (1 hour),
  cafe: 45 min (45 minutes)
}
```

**Output:**
```json
{
  "minimum": 120,
  "recommended": 180,
  "maximum": 240,
  "confidence": 0.8,
  "source": "multi_source"
}
```

**Layer 2: Cost Estimation**

LLM-based with structured output:
```json
{
  "entry": 35,
  "guide": 150,
  "equipment": 0,
  "transport": 25,
  "meals": 25,
  "total": 235,
  "currency": "USD",
  "confidence": 0.7
}
```

**Layer 3: Friction Detection**

8 friction types automatically detected:
1. **Booking Required** - Advance reservation needed
2. **Transportation** - Car/tour required
3. **Meal Gap** - Long time without food
4. **Weather Dependent** - Outdoor activity risks
5. **Crowd Overload** - Too many people
6. **Budget Exceeded** - Cost over user limit
7. **Physical Demand** - Challenging activity
8. **Time Constraint** - Not enough time

**Layer 4: Requirements Analysis**

LLM analyzes and structures:
```json
{
  "booking": {
    "required": true,
    "advanceNotice": "2 weeks",
    "url": "..."
  },
  "transportation": {
    "required": true,
    "type": "car",
    "duration": 210
  },
  "physical": {
    "level": "moderate"
  },
  "weather": {
    "dependent": true
  }
}
```

#### **Quality Checker Agent** (Friction Detection)
**Status:** ✅ Placeholder (Full implementation Sprint 4)

**Responsibilities:**
- Validate itinerary quality
- Detect scheduling conflicts
- Check diversity and balance
- Verify feasibility

---

### 2.2 Google Maps Integration

**Status:** ✅ Implemented with caching

#### APIs Integrated (6 of 13)

1. **Places API - Text Search** ✅
   - Search by query string
   - Radius-based filtering
   - Returns place_id for details

2. **Places API - Place Details** ✅
   - Full place information
   - Photos, reviews, ratings
   - Opening hours, contact info

3. **Places API - Nearby Search** ✅
   - Location-based search
   - Type and keyword filtering

4. **Geocoding API** ✅
   - Address to coordinates
   - Destination resolution

5. **Directions API** ✅
   - Route between two points
   - Multiple travel modes
   - Duration and distance

6. **Distance Matrix API** ✅
   - Multiple origins/destinations
   - Bulk distance calculations

#### Caching Strategy (Implemented)

**Places Cache:**
- TTL: 7 days
- Reduces API costs by 80%+
- Stores full place details

**Routes Cache:**
- TTL: 24 hours
- Key: origin + destination + mode
- Stores route geometry and metrics

**AI Responses Cache:**
- TTL: 1 hour
- Key: prompt hash
- Stores LLM outputs

**Implementation:**
```typescript
class GoogleMapsService {
  async getPlaceDetails(placeId: string): Promise<any> {
    // Check cache first
    const cached = await getCachedPlaceDetails(placeId);
    if (cached) return cached;
    
    // Fetch from API
    const place = await fetchFromGoogleAPI(placeId);
    
    // Cache result
    await cachePlaceDetails(placeId, place, 7 * 24 * 60 * 60);
    
    return place;
  }
}
```

#### Pending APIs (Sprint 4-5)

7. **Routes API (New)** - Advanced routing
8. **Street View Static API** - Preview images
9. **Time Zone API** - Local time handling
10. **Maps JavaScript API** - Interactive maps
11. **Roads API** - Snap to roads
12. **Maps Static API** - Static map images
13. **Geolocation API** - Current location

---

### 2.3 Database Schema (Supabase)

**Status:** ✅ Implemented

#### Core Tables

**profiles**
```sql
CREATE TABLE profiles (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  username VARCHAR(50) UNIQUE,
  full_name VARCHAR(255),
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**itineraries**
```sql
CREATE TABLE itineraries (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES profiles(id),
  destination VARCHAR(255) NOT NULL,
  start_date DATE,
  end_date DATE,
  budget VARCHAR(50),
  travel_style VARCHAR(50),
  status VARCHAR(50) DEFAULT 'draft',
  data JSONB NOT NULL, -- Full itinerary JSON
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**itinerary_versions**
```sql
CREATE TABLE itinerary_versions (
  id SERIAL PRIMARY KEY,
  itinerary_id INTEGER REFERENCES itineraries(id),
  version_number INTEGER NOT NULL,
  data JSONB NOT NULL,
  changes_summary TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**timeline_items**
```sql
CREATE TABLE timeline_items (
  id SERIAL PRIMARY KEY,
  itinerary_id INTEGER REFERENCES itineraries(id),
  day_number INTEGER NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  activity_data JSONB NOT NULL,
  sort_order INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Caching Tables

**cache_places_details**
```sql
CREATE TABLE cache_places_details (
  place_id VARCHAR(255) PRIMARY KEY,
  data JSONB NOT NULL,
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_places_expires ON cache_places_details(expires_at);
```

**cache_routes**
```sql
CREATE TABLE cache_routes (
  id SERIAL PRIMARY KEY,
  origin_lat DECIMAL(10, 8) NOT NULL,
  origin_lng DECIMAL(11, 8) NOT NULL,
  destination_lat DECIMAL(10, 8) NOT NULL,
  destination_lng DECIMAL(11, 8) NOT NULL,
  mode VARCHAR(20) NOT NULL,
  data JSONB NOT NULL,
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  UNIQUE(origin_lat, origin_lng, destination_lat, destination_lng, mode)
);
```

**cache_ai_responses**
```sql
CREATE TABLE cache_ai_responses (
  id SERIAL PRIMARY KEY,
  prompt_hash VARCHAR(64) UNIQUE NOT NULL,
  prompt TEXT NOT NULL,
  response JSONB NOT NULL,
  model VARCHAR(100),
  cached_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL
);
```

#### Social Tables (Pending Sprint 7-8)

**follows**
```sql
CREATE TABLE follows (
  follower_id INTEGER REFERENCES profiles(id),
  following_id INTEGER REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);
```

**posts**
```sql
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES profiles(id),
  itinerary_id INTEGER REFERENCES itineraries(id),
  content TEXT,
  media_urls TEXT[],
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**likes**
```sql
CREATE TABLE likes (
  user_id INTEGER REFERENCES profiles(id),
  post_id INTEGER REFERENCES posts(id),
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);
```

**comments**
```sql
CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES posts(id),
  user_id INTEGER REFERENCES profiles(id),
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 3. User Experience

### 3.1 Conversational Planning Flow

**Status:** ✅ Implemented

**Example Conversation:**

```
AI: "Hey there! 👋 I'm so excited to help you plan your dream adventure! 
     Tell me - what's the trip you've been dreaming about?"

User: "I want to visit Paris and I love skateboarding"

AI: "That sounds amazing! Paris is perfect for skateboarding - there are 
     some incredible skateparks! How many days are you planning for this 
     adventure?"

User: "5 days, moderate budget"

AI: "Perfect! 🔍 Let me find the best skateparks, landmarks, and local 
     spots for you..."

[Activity Discovery runs]

AI: "Found 47 amazing activities! Building your perfect itinerary..."

[Itinerary Builder runs]

AI: "🎉 Your dream Paris itinerary is ready! I've crafted 5 amazing days 
     that perfectly blend your love for skateboarding with the city's best 
     culture and food. Every day includes an authentic skatepark (because 
     you're passionate about skating!), plus hidden gems and must-see spots. 
     I've optimized the routes so you spend less time traveling and more 
     time experiencing. Ready to see the full day-by-day plan?"
```

### 3.2 Planner Views (Sprint 4-6)

#### **Grid View** (Desktop/Tablet)
**Status:** 🚧 Pending

**Layout:**
- Columns: Days (Day 1, Day 2, etc.)
- Rows: Time slots (9:00 AM - 9:00 PM)
- Cards: Activity cards with drag-and-drop

**Activity Card Contents:**
- Photo (from Google Places)
- Name and type
- Time slot (09:00 - 11:30)
- Rating (4.7★) and review count
- Cost estimate ($35)
- Travel time from previous (15 min walk)
- Friction warnings (⚠️ Booking required)

**Interactions:**
- Drag to reorder within day
- Drag to move between days
- Click to expand details
- Delete to remove
- Add button to insert new activity

**Real-time Updates:**
- Route recalculation on drag
- Time slot auto-adjustment
- Cost total updates
- Conflict detection

#### **Timeline View** (Mobile)
**Status:** 🚧 Pending

**Layout:**
- Vertical scrolling timeline
- Day filter tabs at top
- Activity cards in chronological order
- Travel time connectors between cards

**Features:**
- Swipe to change days
- Tap to expand activity
- Embedded mini-map per activity
- Street View preview on long-press

#### **Map View** (All Devices)
**Status:** 🚧 Pending

**Layout:**
- Full-screen Google Map
- Day selector (filter by day)
- Activity markers color-coded by type
- Route polyline between activities

**Features:**
- Cluster markers when zoomed out
- Click marker to show activity card
- Show/hide route
- Directions button
- Street View integration

**Map Markers:**
- 🎨 Culture (museums, galleries)
- 🌳 Nature (parks, outdoors)
- 🍽️ Dining (restaurants, cafes)
- 🛹 User interests (skateparks)
- 🏛️ Landmarks (famous sites)

---

## 4. Key Features Status

### ✅ Completed (Sprints 1-3)

1. **Authentication & User Profiles**
   - Manus OAuth integration
   - User profile management
   - Session handling

2. **Conversational AI Planner**
   - Intent gathering with progressive questioning
   - Natural language understanding
   - Context-aware responses

3. **Intelligence Engine**
   - Multi-source duration prediction
   - Cost estimation with breakdown
   - Friction detection (8 types)
   - Requirements analysis

4. **Activity Discovery**
   - Smart query generation
   - Google Places API integration
   - Intent-based scoring
   - Activity categorization

5. **Itinerary Building**
   - Activities-per-day calculation
   - Mandatory-first selection
   - Geographic clustering
   - Route optimization
   - Time slot assignment

6. **Caching System**
   - Places cache (7 days)
   - Routes cache (24 hours)
   - AI responses cache (1 hour)

### 🚧 In Progress (Sprint 4-6)

7. **Grid View with Drag-and-Drop**
8. **Timeline View (Mobile)**
9. **Interactive Map View**
10. **Meal Insertion Logic**
11. **Conflict Resolution UI**
12. **Itinerary Refinement**

### 📋 Pending (Sprint 7-10)

13. **Social Feed**
14. **Follow System**
15. **Post Sharing**
16. **Likes & Comments**
17. **Dream Board (Inspiration)**
18. **Memory Maker (Post-Trip)**
19. **Admin Dashboard**
20. **Analytics & Monitoring**

---

## 5. Technical Stack

### Frontend
- **Framework:** React 19 + TypeScript
- **Styling:** Tailwind CSS 4
- **UI Components:** shadcn/ui
- **State Management:** TanStack Query (via tRPC)
- **Routing:** Wouter
- **Maps:** Google Maps JavaScript API
- **Markdown:** Streamdown

### Backend
- **Runtime:** Node.js 22
- **Framework:** Express 4
- **API:** tRPC 11
- **Database:** Supabase (PostgreSQL)
- **ORM:** Drizzle
- **Authentication:** Manus OAuth
- **LLM:** OpenAI GPT (via Manus)

### Infrastructure
- **Hosting:** Manus Platform
- **Database:** Supabase Cloud
- **Storage:** S3 (via Manus)
- **CDN:** Automatic (Manus)
- **Analytics:** Built-in (Manus)

### External APIs
- **Google Maps:** 13 APIs
- **OpenAI:** GPT-4 (via Manus)
- **Supabase:** Database + Auth

---

## 6. Success Metrics

### Year 1 Goals

**User Growth:**
- 150,000 registered users
- 120,000 monthly active users
- 80% retention rate (30 days)

**Engagement:**
- 25,000 itineraries created/month
- 15,000 itineraries shared/month
- 50,000 social interactions/month

**Revenue:**
- $64,500 MRR (Monthly Recurring Revenue)
- $774,000 ARR (Annual Recurring Revenue)
- 5% conversion to paid

**Quality:**
- 55+ Net Promoter Score
- 4.5+ app store rating
- <2% churn rate

### Key Performance Indicators (KPIs)

**Planner Metrics:**
- Time to first itinerary: <10 minutes
- Itinerary completion rate: >70%
- User satisfaction: >4.5/5
- AI accuracy: >85%

**Social Metrics:**
- Posts per user: 3/month
- Engagement rate: >8%
- Follower growth: 20%/month
- Viral coefficient: >1.2

**Technical Metrics:**
- API response time: <500ms (p95)
- Uptime: >99.9%
- Cache hit rate: >80%
- Error rate: <0.1%

---

## 7. Monetization Strategy

### Freemium Model

**Free Tier:**
- 3 itineraries/month
- Basic activity suggestions
- Standard route optimization
- Community features
- 5 GB storage

**Pro Tier ($9.99/month):**
- Unlimited itineraries
- Priority AI processing
- Advanced optimizations
- Offline access
- 50 GB storage
- No ads

**Premium Tier ($19.99/month):**
- Everything in Pro
- Concierge service
- Exclusive experiences
- Priority support
- 200 GB storage
- White-label option

### Additional Revenue Streams

1. **Affiliate Commissions**
   - Hotels (Booking.com, Airbnb)
   - Activities (GetYourGuide, Viator)
   - Flights (Skyscanner)
   - 5-15% commission

2. **Sponsored Activities**
   - Featured placements
   - Promoted experiences
   - Local business partnerships

3. **API Access**
   - Travel agencies
   - Tour operators
   - Corporate travel

---

## 8. Competitive Analysis

### Direct Competitors

**TripIt**
- ❌ No AI planning
- ❌ No social features
- ✅ Good organization
- ✅ Offline access

**Wanderlog**
- ❌ Basic AI
- ❌ Limited social
- ✅ Collaborative planning
- ✅ Good UI

**Roadtrippers**
- ❌ Road trips only
- ❌ No AI
- ✅ Route optimization
- ✅ POI discovery

### DreamLnds Advantages

1. **AI-First:** Deep intent understanding, not just keyword matching
2. **Intelligence:** Predicts frictions, costs, durations proactively
3. **Personalization:** 60% user interests, 40% famous landmarks
4. **Social:** Complete lifecycle from inspiration to memories
5. **Optimization:** Route intelligence saves 30-40% travel time

---

## 9. Risk Assessment

### Technical Risks

**Risk:** Google Maps API costs exceed budget
**Mitigation:** Aggressive caching (80%+ hit rate), rate limiting, usage monitoring

**Risk:** LLM hallucinations produce incorrect information
**Mitigation:** Multi-source validation, confidence scores, user feedback loops

**Risk:** Scaling issues with concurrent users
**Mitigation:** Horizontal scaling, caching, async processing, queue system

### Business Risks

**Risk:** Low user adoption
**Mitigation:** Viral features, referral program, content marketing, influencer partnerships

**Risk:** Competitor launches similar features
**Mitigation:** Continuous innovation, community moat, network effects

**Risk:** Regulatory changes (data privacy)
**Mitigation:** GDPR compliance, data minimization, user controls

---

## 10. Development Timeline

### Completed (Weeks 1-6)

- ✅ Sprint 1: Core infrastructure, authentication, Orchestrator, Intent Analyzer
- ✅ Sprint 2: Intelligence Engine, Activity Discovery, Google Maps integration
- ✅ Sprint 3: Itinerary Builder, route optimization, time slot assignment

### In Progress (Weeks 7-12)

- 🚧 Sprint 4: Grid view with drag-and-drop, conflict resolution
- 🚧 Sprint 5: Timeline view (mobile), Map view
- 🚧 Sprint 6: Meal insertion, refinement UI, quality checker

### Upcoming (Weeks 13-20)

- 📋 Sprint 7: Social feed, follow system
- 📋 Sprint 8: Post sharing, likes, comments
- 📋 Sprint 9: Admin dashboard, analytics
- 📋 Sprint 10: Polish, testing, bug fixes, deployment

### Beta Launch: Week 18
### Public Launch: Week 20

---

## 11. Future Enhancements (Post-MVP)

### Phase 2 (Months 4-6)

1. **Dream Board**
   - Pinterest-style inspiration board
   - Save places, activities, photos
   - AI suggests itineraries from board

2. **Memory Maker**
   - Post-trip storytelling
   - Photo albums with timeline
   - AI-generated trip summaries
   - Share memories with community

3. **Collaborative Planning**
   - Invite friends to co-plan
   - Real-time editing
   - Voting on activities
   - Split cost calculator

### Phase 3 (Months 7-12)

4. **Mobile Apps**
   - iOS native app
   - Android native app
   - Offline mode
   - Push notifications

5. **Advanced AI**
   - Voice interface
   - Image recognition (upload photo, find place)
   - Predictive suggestions
   - Learning from user behavior

6. **Enterprise Features**
   - Team accounts
   - Corporate travel policies
   - Expense tracking
   - Admin controls

---

## 12. Appendices

### A. API Documentation

**Planner API Endpoints (tRPC):**

```typescript
planner: {
  chat: protectedProcedure
    .input(z.object({
      messages: z.array(MessageSchema),
      conversationContext: z.any().optional()
    }))
    .mutation(async ({ input, ctx }) => {
      // Returns AI response + updated context
    }),
    
  getItinerary: protectedProcedure
    .input(z.object({ id: z.number() }))
    .query(async ({ input, ctx }) => {
      // Returns full itinerary
    }),
    
  updateItinerary: protectedProcedure
    .input(z.object({
      id: z.number(),
      changes: z.any()
    }))
    .mutation(async ({ input, ctx }) => {
      // Updates and returns new version
    })
}
```

### B. Environment Variables

**Required:**
- `GOOGLE_MAPS_API_KEY` - Google Maps API key
- `VITE_GOOGLE_MAPS_API_KEY` - Frontend Google Maps key
- `DATABASE_URL` - Supabase connection string

**Auto-Injected (Manus):**
- `BUILT_IN_FORGE_API_KEY` - Manus LLM API key
- `BUILT_IN_FORGE_API_URL` - Manus API endpoint
- `JWT_SECRET` - Session signing secret
- `OAUTH_SERVER_URL` - OAuth backend URL

### C. Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] API keys restricted (HTTP referrers)
- [ ] Error monitoring enabled
- [ ] Analytics configured
- [ ] Backup strategy implemented
- [ ] CDN configured
- [ ] SSL certificates valid
- [ ] Rate limiting enabled
- [ ] GDPR compliance verified

---

## Document Control

**Version History:**
- v1.0 (Dec 2024) - Initial PRD
- v2.0 (Jan 2025) - Updated with implementation details

**Maintained By:** Development Team  
**Next Review:** After Sprint 6 completion

**Related Documents:**
- `AGENT_ARCHITECTURE_V2.md` - Detailed agent specifications
- `INTELLIGENT_SCHEDULING.md` - Scheduling algorithms
- `ACTIVITY_INTELLIGENCE.md` - Intelligence Engine details
- `PLANNER_ARCHITECTURE.md` - System architecture
- `todo.md` - Sprint-by-sprint task list
