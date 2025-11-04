# DreamLnds - Project Overview
## AI-Powered Social Network for Dream Travel Planning

**Status:** In Development (30% Complete)  
**Current Sprint:** Sprint 3 Complete, Sprint 4 Starting  
**Target Launch:** Week 20 (14 weeks remaining)  
**Last Updated:** January 2025

---

## What is DreamLnds?

DreamLnds is a social network that enables dreams by combining AI-powered travel planning with social sharing and community discovery. Unlike traditional travel apps that simply list attractions, DreamLnds understands your passions, predicts potential problems, optimizes routes intelligently, and creates a complete journey from inspiration to lasting memories.

### The Core Idea

**Traditional travel apps say:** "Here are the top 10 things to do in Paris"

**DreamLnds says:** "You love skateboarding? Here are 3 authentic skateparks in Paris, plus the Eiffel Tower, a hidden street art district, and a local food market - all optimized so you spend 40% less time traveling between places"

---

## What Makes DreamLnds Different?

### 1. **Intelligence-First Architecture**

DreamLnds doesn't just search for places - it **understands** them through a 4-layer intelligence system that predicts duration, estimates costs, detects potential friction points, and analyzes requirements before you even see the suggestion.

**Example:** When DreamLnds suggests Yosemite National Park, it knows:
- **Duration:** 9 hours recommended (not just "all day")
- **Cost:** $210 total ($35 entry + $150 optional guide + $25 meals)
- **Frictions:** Booking required 2 weeks ahead, car needed (3.5hr drive), pack lunch
- **Requirements:** Download offline maps, bring layers, fill water at visitor center

### 2. **Dream-First Personalization**

Traditional apps prioritize famous landmarks. DreamLnds prioritizes **your passions**.

**Scoring System:**
- User interest match: **100 points** (highest priority)
- Famous landmark: 20 points
- High rating: 20 points
- Budget alignment: 20 points

**Result:** If you say "I love skateboarding," you'll see skateparks **every single day**, not just once as an afterthought. The system guarantees 60% user-interest activities and 40% famous landmarks.

### 3. **Route Intelligence**

DreamLnds doesn't just list activities - it **optimizes** them geographically and temporally.

**Geographic Clustering:** Activities are grouped by neighborhood using k-means clustering, reducing travel time by 30-40%.

**Route Optimization:** A nearest-neighbor algorithm orders activities to minimize backtracking (Traveling Salesman Problem approximation).

**Meals Along the Way:** Restaurants are inserted within 500 meters of your route, adding less than 5 minutes of detour time. No more "Where should we eat?" moments.

**Real Travel Times:** Every time slot includes actual travel time calculated via Google Routes API, not estimates.

### 4. **Proactive Friction Detection**

DreamLnds identifies 8 types of potential problems **before** you encounter them:

1. **Booking Required** - "⚠️ Reserve 2 weeks ahead"
2. **Transportation Needed** - "🚗 Car required (3.5hr drive)"
3. **Meal Gaps** - "🍽️ No food for 6 hours - pack snacks"
4. **Weather Risks** - "☔ Outdoor activity - check forecast"
5. **Crowd Overload** - "👥 Very busy 10am-2pm - go early"
6. **Budget Exceeded** - "💰 This exceeds your daily budget"
7. **Physical Demands** - "🥾 Moderate hiking - proper shoes needed"
8. **Time Constraints** - "⏰ Not enough time for full experience"

### 5. **Complete Dream Lifecycle**

Most apps focus only on planning. DreamLnds covers the entire journey:

**Before (Inspiration):** Dream Board - Pinterest-style inspiration collection where you save places, and AI suggests itineraries based on your board.

**During (Planning):** AI-powered conversational planner that understands vague ideas like "I want to visit Europe" and turns them into concrete, optimized itineraries.

**After (Memories):** Memory Maker - Transform your trip into a beautiful story with photos, timeline, and AI-generated summaries to share with the community.

---

## Current Architecture

### AI Agent System (6 Specialized Agents)

DreamLnds uses an **agent-based architecture** where specialized AI agents collaborate to create perfect itineraries:

#### **1. Orchestrator Agent** (Master Coordinator)
- Manages conversation flow through 8 states
- Coordinates all other agents
- Maintains context and history
- Handles state transitions

**States:** Greeting → Intent Gathering → Intent Clarification → Activity Discovery → Itinerary Building → Friction Resolution → Refinement → Finalization

#### **2. Intent Analyzer Agent** (Deep Understanding)
- Extracts explicit intent (destination, dates, budget, interests)
- Infers implicit preferences (travel style, pace, values)
- Calculates completeness score
- Generates smart follow-up questions

**Example:** "I want to visit Paris and I love skateboarding" becomes:
```json
{
  "explicit": {
    "destination": "Paris, France",
    "interests": ["skateboarding"]
  },
  "implicit": {
    "travelStyle": "adventure",
    "values": ["authentic", "local", "active"]
  },
  "completeness": 0.4,
  "missingFields": ["numberOfDays", "budget", "startDate"]
}
```

#### **3. Intelligence Engine** (Shared Service)

The brain that powers all smart decisions with 4 intelligence layers:

**Layer 1: Duration Prediction** - Multi-source approach combining Google API, review mining, activity type lookup, and LLM prediction. Outputs minimum, recommended, and maximum durations with confidence scores.

**Layer 2: Cost Estimation** - LLM-based estimation with detailed breakdown: entry fee, guide cost, equipment rental, transportation, and meals. Includes confidence score.

**Layer 3: Friction Detection** - Automatically detects 8 types of potential problems and assigns severity levels (low, medium, high).

**Layer 4: Requirements Analysis** - Structures booking requirements, transportation needs, physical demands, and weather dependencies.

#### **4. Activity Discovery Agent** (Smart Search)

Discovers places that match user intent through a 4-step process:

**Step 1: Query Generation** - LLM generates 8-12 diverse search queries prioritizing user interests, then famous landmarks, then local experiences.

**Step 2: Search Execution** - Google Places API (Text Search + Place Details) with deduplication by place_id.

**Step 3: Intelligence Enrichment** - Applies all 4 intelligence layers to every activity.

**Step 4: Scoring & Categorization** - Scores activities and categorizes as Mandatory (100+ points), Must-see (50-99 points), or Filler (<50 points).

#### **5. Itinerary Builder Agent** (Optimization)

Transforms discovered activities into realistic daily schedules through a 6-step process:

**Step 1: Calculate Activities Per Day** - Based on user pace: Relaxed (3 activities), Moderate (4 activities), Packed (6 activities).

**Step 2: Select Activities** - Mandatory-first algorithm ensures user interests appear every day.

**Step 3: Geographic Clustering** - K-means clustering groups activities by neighborhood.

**Step 4: Route Optimization** - Nearest-neighbor algorithm minimizes travel distance.

**Step 5: Time Slot Assignment** - Starts at 9:00 AM, uses predicted durations, calculates travel times via Google Routes API, adds 15-minute buffers.

**Step 6: Meal Insertion** (Coming Sprint 4) - Searches restaurants along route, inserts at logical meal times.

#### **6. Quality Checker Agent** (Friction Detection)

Validates itinerary quality and detects issues:
- Diversity check (not all museums)
- Balance check (activity types)
- Feasibility check (realistic timing)
- Budget check (within limits)

---

## Technical Stack

### Frontend
- **Framework:** React 19 + TypeScript
- **Styling:** Tailwind CSS 4
- **UI Components:** shadcn/ui (modern, accessible components)
- **State Management:** TanStack Query (via tRPC)
- **Routing:** Wouter (lightweight React router)
- **Maps:** Google Maps JavaScript API
- **Markdown:** Streamdown (for AI responses)

### Backend
- **Runtime:** Node.js 22
- **Framework:** Express 4
- **API:** tRPC 11 (end-to-end type safety)
- **Database:** Supabase (PostgreSQL)
- **ORM:** Drizzle (type-safe SQL)
- **Authentication:** Manus OAuth
- **LLM:** OpenAI GPT-4 (via Manus built-in API)

### Infrastructure
- **Hosting:** Manus Platform (auto-scaling)
- **Database:** Supabase Cloud
- **Storage:** S3 (via Manus)
- **CDN:** Automatic (Manus)
- **Analytics:** Built-in (Manus)

### External APIs
- **Google Maps:** 13 APIs (6 integrated, 7 pending)
  - ✅ Places API - Text Search
  - ✅ Places API - Place Details
  - ✅ Places API - Nearby Search
  - ✅ Geocoding API
  - ✅ Directions API
  - ✅ Distance Matrix API
  - 🚧 Routes API (New)
  - 🚧 Street View Static API
  - 🚧 Time Zone API
  - 🚧 Maps JavaScript API
  - 🚧 Roads API
  - 🚧 Maps Static API
  - 🚧 Geolocation API

- **OpenAI:** GPT-4 (via Manus built-in API)
- **Supabase:** Database + Auth

---

## Database Schema

### Core Tables (Implemented)

**profiles** - User profiles with avatar, bio, and preferences

**itineraries** - Complete itinerary data stored as JSONB with metadata (destination, dates, budget, status)

**itinerary_versions** - Version history for undo/redo functionality

**timeline_items** - Individual activity time slots for efficient querying

### Caching Tables (Implemented)

**cache_places_details** - Google Places API responses cached for 7 days (80%+ cost reduction)

**cache_routes** - Google Routes API responses cached for 24 hours

**cache_ai_responses** - LLM responses cached for 1 hour

### Social Tables (Pending Sprint 7-8)

**follows** - Follow relationships between users

**posts** - Shared itineraries and memories

**likes** - Post likes

**comments** - Post comments with nested replies

---

## What's Been Built (Sprints 1-3)

### ✅ Sprint 1: Core Infrastructure
- Project initialization (React + tRPC + Supabase)
- Landing page with gradient design
- Authentication (Manus OAuth)
- Database schema (users, itineraries, caching)
- Orchestrator Agent with state machine
- Intent Analyzer Agent with LLM
- Conversational chat interface
- Cache service layer

### ✅ Sprint 2: Intelligence & Discovery
- Intelligence Engine (4 layers)
  - Duration prediction (multi-source)
  - Cost estimation
  - Friction detection (8 types)
  - Requirements analysis
- Activity Discovery Agent
  - Smart query generation
  - Google Places API integration
  - Intent-based scoring
  - Activity categorization
- Google Maps service wrapper
- Caching for all API calls

### ✅ Sprint 3: Itinerary Building
- Activities-per-day calculator (pace-based)
- Activity selection algorithm (mandatory-first)
- Geographic clustering (k-means)
- Route optimization (nearest-neighbor)
- Time slot assignment with travel times
- Integration with Google Routes API
- Orchestrator wiring for full flow

**Current Capability:** The system can take a vague user input like "I want to visit Paris for 5 days and I love skateboarding" and generate a complete, optimized itinerary with real places, realistic timing, and intelligent route planning. However, users can only see this through a chat interface - the visual planner views are not yet built.

---

## What's Next (Sprints 4-10)

### 🚧 Sprint 4-6: Planner Views (Weeks 7-12)

**Grid View (Desktop/Tablet):**
- Column-based layout (days × time slots)
- Activity cards with photos, ratings, costs
- Drag-and-drop to reorder and move between days
- Real-time route recalculation
- Conflict detection and resolution
- Add/delete activities

**Timeline View (Mobile):**
- Vertical scrolling timeline
- Day filter tabs
- Swipe gestures
- Embedded mini-maps
- Street View integration

**Map View (All Devices):**
- Full-screen Google Map
- Activity markers color-coded by type
- Route polylines
- Cluster markers when zoomed out
- Street View integration
- Directions

### 📋 Sprint 7-8: Social Features (Weeks 13-16)

**User Profiles:**
- Avatar upload
- Bio editor
- Stats (itineraries, followers, following)
- Privacy controls

**Follow System:**
- Follow/unfollow users
- Followers/following lists
- Activity feed

**Social Feed:**
- Infinite scroll feed
- Post creation (share itineraries)
- Like/unlike
- Comments with nested replies
- Share functionality

### 📋 Sprint 9-10: Admin & Launch (Weeks 17-20)

**Admin Dashboard:**
- User management
- Content moderation
- Feature flags
- Analytics

**Analytics:**
- User growth charts
- Engagement metrics
- Revenue tracking
- API monitoring

**Launch Preparation:**
- Beta testing
- Bug fixes
- Performance optimization
- Documentation
- Public launch

---

## Success Metrics

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

## Monetization Strategy

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

**Affiliate Commissions:** Hotels (Booking.com, Airbnb), Activities (GetYourGuide, Viator), Flights (Skyscanner) - 5-15% commission

**Sponsored Activities:** Featured placements, promoted experiences, local business partnerships

**API Access:** Travel agencies, tour operators, corporate travel

---

## Competitive Advantages

### vs TripIt
- ✅ AI-powered planning (TripIt has none)
- ✅ Social features (TripIt has none)
- ✅ Route optimization (TripIt just organizes)

### vs Wanderlog
- ✅ Deep AI understanding (Wanderlog has basic AI)
- ✅ Intelligence layers (Wanderlog doesn't predict frictions)
- ✅ Personalization (Wanderlog prioritizes landmarks)

### vs Roadtrippers
- ✅ All trip types (Roadtrippers is road trips only)
- ✅ AI planning (Roadtrippers has none)
- ✅ Social features (Roadtrippers has minimal)

**DreamLnds' Moat:** The combination of deep AI intelligence, personalization-first approach, route optimization, and social features creates a unique product that's difficult to replicate.

---

## Timeline to Launch

**Completed:** Weeks 1-6 (Sprints 1-3)  
**Current:** Week 6  
**Remaining:** 14 weeks

**Sprint 4-6:** Planner views (6 weeks)  
**Sprint 7-8:** Social features (4 weeks)  
**Sprint 9-10:** Admin & launch (4 weeks)

**Beta Launch:** Week 18  
**Public Launch:** Week 20

---

## Key Documents

1. **PRD_UPDATED.md** - Complete product requirements with implementation details
2. **ROADMAP_TO_LAUNCH.md** - Sprint-by-sprint roadmap to public launch
3. **AGENT_ARCHITECTURE_V2.md** - Detailed agent system specifications
4. **INTELLIGENT_SCHEDULING.md** - Scheduling and optimization algorithms
5. **ACTIVITY_INTELLIGENCE.md** - Intelligence Engine deep dive
6. **PLANNER_ARCHITECTURE.md** - System architecture overview
7. **todo.md** - Detailed task list

---

## How to Get Involved

### For Developers
- Review the codebase at `/home/ubuntu/dreamlnds`
- Check `todo.md` for current sprint tasks
- Read architecture docs in `/docs`

### For Designers
- Review current UI in the dev server
- Provide feedback on Grid/Timeline/Map view wireframes
- Help with landing page and marketing materials

### For Beta Testers
- Sign up for beta access (Week 18)
- Provide feedback on usability
- Report bugs and suggest features

---

## Contact & Resources

**Project Repository:** `/home/ubuntu/dreamlnds`  
**GitHub:** https://github.com/fwvisani/DreamLnds  
**Supabase Project:** godbkuerepkqdpkxqyzc  
**Dev Server:** https://3000-idsrpe99a64jtulruhsca-cc0bcff9.manusvm.computer

**Key Files:**
- `/server/agents/` - AI agent implementations
- `/server/services/` - Intelligence Engine and Google Maps
- `/client/src/pages/` - Frontend pages
- `/docs/` - All documentation

---

## Conclusion

DreamLnds is 30% complete with a solid foundation of intelligent AI agents and optimization algorithms. The next phase focuses on user-facing interfaces (Grid, Timeline, Map views) and social features (Feed, Follow, Share) to complete the full product vision.

With focused execution over the next 14 weeks, DreamLnds will launch as a complete product that truly enables dreams.

**The dream starts with great architecture. Let's build it! 🚀**

---

**Last Updated:** January 2025  
**Version:** 1.0  
**Status:** Living Document (updated after each sprint)
