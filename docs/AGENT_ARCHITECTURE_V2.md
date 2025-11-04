# DreamLnds Agent Architecture V2

## Overview

This is the revised agent architecture incorporating activity intelligence, friction detection, deep intent understanding, and budget awareness. The system is designed to create truly personalized, realistic, and friction-free itineraries.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER CONVERSATION                            │
│              (Chat Interface - Natural Language)                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ORCHESTRATOR AGENT                              │
│  (Coordinates all agents, maintains context, manages flow)      │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────────┐
│ INTENT ANALYZER │ │  KNOWLEDGE  │ │ QUALITY CHECKER │
│     AGENT       │ │    BASE     │ │     AGENT       │
└────────┬────────┘ └──────┬──────┘ └────────┬────────┘
         │                 │                  │
         └─────────────────┼──────────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
         ▼                                   ▼
┌──────────────────────┐          ┌──────────────────────┐
│  ACTIVITY DISCOVERY  │          │   ITINERARY BUILDER  │
│       AGENT          │          │       AGENT          │
└──────────┬───────────┘          └──────────┬───────────┘
           │                                  │
           │    ┌─────────────────────────┐   │
           └───►│  INTELLIGENCE ENGINE    │◄──┘
                │  (4 Intelligence Layers)│
                └────────────┬────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
       ┌────────────────┐       ┌────────────────┐
       │  GOOGLE MAPS   │       │   SUPABASE     │
       │  APIs (13)     │       │   CACHE        │
       └────────────────┘       └────────────────┘
```

---

## Agent Definitions

### 1. Orchestrator Agent

**Role:** Master coordinator that manages the entire planning workflow

**Responsibilities:**
- Maintains conversation context
- Decides which agent to invoke next
- Manages state transitions (gathering → planning → refining)
- Handles user interruptions and clarifications
- Ensures smooth handoffs between agents

**State Machine:**
```javascript
const ORCHESTRATOR_STATES = {
  GREETING: 'greeting',
  INTENT_GATHERING: 'intent_gathering',
  INTENT_CLARIFICATION: 'intent_clarification',
  ACTIVITY_DISCOVERY: 'activity_discovery',
  ITINERARY_BUILDING: 'itinerary_building',
  FRICTION_RESOLUTION: 'friction_resolution',
  REFINEMENT: 'refinement',
  FINALIZATION: 'finalization'
};

class OrchestratorAgent {
  constructor() {
    this.state = ORCHESTRATOR_STATES.GREETING;
    this.context = {
      userProfile: {},
      intent: {},
      activities: [],
      itinerary: null,
      frictions: [],
      conversationHistory: []
    };
  }
  
  async processUserMessage(message) {
    // Add to history
    this.context.conversationHistory.push({
      role: 'user',
      content: message,
      timestamp: new Date()
    });
    
    // Determine next action based on current state
    switch (this.state) {
      case ORCHESTRATOR_STATES.GREETING:
        return await this.handleGreeting(message);
        
      case ORCHESTRATOR_STATES.INTENT_GATHERING:
        return await this.handleIntentGathering(message);
        
      case ORCHESTRATOR_STATES.ACTIVITY_DISCOVERY:
        return await this.handleActivityDiscovery();
        
      case ORCHESTRATOR_STATES.ITINERARY_BUILDING:
        return await this.handleItineraryBuilding();
        
      case ORCHESTRATOR_STATES.FRICTION_RESOLUTION:
        return await this.handleFrictionResolution();
        
      case ORCHESTRATOR_STATES.REFINEMENT:
        return await this.handleRefinement(message);
        
      default:
        return await this.handleUnexpected(message);
    }
  }
  
  async handleGreeting(message) {
    // Warm, engaging greeting
    const response = await invokeLLM({
      messages: [{
        role: 'system',
        content: `You are a dream travel partner. Greet the user warmly and ask them to share their dream trip. Be enthusiastic and encouraging.`
      }, {
        role: 'user',
        content: message
      }]
    });
    
    this.state = ORCHESTRATOR_STATES.INTENT_GATHERING;
    return response.choices[0].message.content;
  }
  
  async handleIntentGathering(message) {
    // Invoke Intent Analyzer Agent
    const intent = await intentAnalyzerAgent.analyze(message, this.context);
    this.context.intent = intent;
    
    // Check if we have enough information
    if (intent.completeness < 0.7) {
      // Need more clarification
      this.state = ORCHESTRATOR_STATES.INTENT_CLARIFICATION;
      return await this.askClarifyingQuestion(intent);
    } else {
      // Ready to discover activities
      this.state = ORCHESTRATOR_STATES.ACTIVITY_DISCOVERY;
      return await this.handleActivityDiscovery();
    }
  }
  
  async askClarifyingQuestion(intent) {
    // Identify what's missing
    const missing = intent.missingFields;
    
    // Generate smart clarifying question
    const question = await invokeLLM({
      messages: [{
        role: 'system',
        content: `Based on the user's intent, ask ONE clarifying question to gather missing information: ${JSON.stringify(missing)}. Be conversational and helpful.`
      }, {
        role: 'user',
        content: JSON.stringify(intent)
      }]
    });
    
    return question.choices[0].message.content;
  }
  
  async handleActivityDiscovery() {
    // Show loading message
    await this.sendMessage("🔍 Discovering amazing activities that match your interests...");
    
    // Invoke Activity Discovery Agent
    const activities = await activityDiscoveryAgent.discover(this.context.intent);
    this.context.activities = activities;
    
    // Move to itinerary building
    this.state = ORCHESTRATOR_STATES.ITINERARY_BUILDING;
    return await this.handleItineraryBuilding();
  }
  
  async handleItineraryBuilding() {
    await this.sendMessage("✨ Creating your personalized itinerary...");
    
    // Invoke Itinerary Builder Agent
    const itinerary = await itineraryBuilderAgent.build(
      this.context.activities,
      this.context.intent
    );
    this.context.itinerary = itinerary;
    
    // Check for frictions
    const frictions = await qualityCheckerAgent.detectFrictions(itinerary);
    this.context.frictions = frictions;
    
    if (frictions.some(f => f.severity === 'high')) {
      this.state = ORCHESTRATOR_STATES.FRICTION_RESOLUTION;
      return await this.handleFrictionResolution();
    } else {
      this.state = ORCHESTRATOR_STATES.FINALIZATION;
      return await this.presentItinerary();
    }
  }
  
  async handleFrictionResolution() {
    // Present frictions to user and get input
    const highFrictions = this.context.frictions.filter(f => f.severity === 'high');
    
    const message = await invokeLLM({
      messages: [{
        role: 'system',
        content: `Present these potential issues to the user and suggest solutions. Be helpful and offer alternatives.`
      }, {
        role: 'user',
        content: JSON.stringify(highFrictions)
      }]
    });
    
    this.state = ORCHESTRATOR_STATES.REFINEMENT;
    return message.choices[0].message.content;
  }
  
  async presentItinerary() {
    // Format and present the final itinerary
    const presentation = await invokeLLM({
      messages: [{
        role: 'system',
        content: `Present this itinerary to the user in an exciting, engaging way. Highlight the best parts and explain why each activity was chosen based on their interests.`
      }, {
        role: 'user',
        content: JSON.stringify(this.context.itinerary)
      }]
    });
    
    // Save to database
    await this.saveItinerary();
    
    return presentation.choices[0].message.content;
  }
}
```

---

### 2. Intent Analyzer Agent

**Role:** Deep understanding of user's dreams, preferences, and constraints

**Responsibilities:**
- Extract explicit information (destination, dates, budget)
- Infer implicit preferences (travel style, pace, interests)
- Detect constraints (physical ability, dietary restrictions, accessibility needs)
- Calculate intent completeness score
- Generate smart follow-up questions

**Implementation:**
```javascript
class IntentAnalyzerAgent {
  async analyze(message, context) {
    // Use LLM with structured output
    const analysis = await invokeLLM({
      messages: [{
        role: 'system',
        content: `You are an expert at understanding travel dreams. Analyze the user's message and extract:
1. Explicit information (destination, dates, budget, interests)
2. Implicit preferences (travel style, pace, values)
3. Constraints (physical, dietary, accessibility)
4. Emotional drivers (what makes this a "dream")
5. Missing information needed for planning

Return detailed JSON with completeness score (0-1).`
      }, {
        role: 'user',
        content: JSON.stringify({
          message,
          conversationHistory: context.conversationHistory,
          currentIntent: context.intent
        })
      }],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'intent_analysis',
          strict: true,
          schema: {
            type: 'object',
            properties: {
              explicit: {
                type: 'object',
                properties: {
                  destination: { type: 'string' },
                  startDate: { type: 'string' },
                  endDate: { type: 'string' },
                  numberOfDays: { type: 'integer' },
                  budget: { type: 'string' },
                  interests: { type: 'array', items: { type: 'string' } }
                }
              },
              implicit: {
                type: 'object',
                properties: {
                  travelStyle: { type: 'string' },
                  pace: { type: 'string' },
                  values: { type: 'array', items: { type: 'string' } },
                  avoidances: { type: 'array', items: { type: 'string' } }
                }
              },
              constraints: {
                type: 'object',
                properties: {
                  physical: { type: 'string' },
                  dietary: { type: 'array', items: { type: 'string' } },
                  accessibility: { type: 'array', items: { type: 'string' } }
                }
              },
              emotional: {
                type: 'object',
                properties: {
                  drivers: { type: 'array', items: { type: 'string' } },
                  dreamAspect: { type: 'string' }
                }
              },
              completeness: { type: 'number' },
              missingFields: { type: 'array', items: { type: 'string' } }
            },
            required: ['explicit', 'implicit', 'completeness', 'missingFields'],
            additionalProperties: false
          }
        }
      }
    });
    
    const intent = JSON.parse(analysis.choices[0].message.content);
    
    // Enrich with geocoding if destination provided
    if (intent.explicit.destination) {
      intent.geocoded = await this.geocodeDestination(intent.explicit.destination);
    }
    
    return intent;
  }
  
  async geocodeDestination(destination) {
    // Use Google Geocoding API
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(destination)}&key=${process.env.GOOGLE_MAPS_API_KEY}`
    );
    const data = await response.json();
    
    if (data.results[0]) {
      return {
        formattedAddress: data.results[0].formatted_address,
        location: data.results[0].geometry.location,
        placeId: data.results[0].place_id,
        types: data.results[0].types
      };
    }
    
    return null;
  }
}
```

---

### 3. Activity Discovery Agent

**Role:** Find and enrich activities using intelligence layers

**Responsibilities:**
- Search Google Places API based on intent
- Apply intelligence layers (duration, cost, frictions)
- Score activities by intent alignment
- Categorize as mandatory/must-see/filler
- Return ranked, enriched activities

**Implementation:**
```javascript
class ActivityDiscoveryAgent {
  async discover(intent) {
    // 1. Generate smart search queries
    const queries = this.generateSearchQueries(intent);
    
    // 2. Search Google Places API
    const rawActivities = await this.searchActivities(queries, intent.geocoded.location);
    
    // 3. Apply intelligence layers to each activity
    const enriched = await Promise.all(
      rawActivities.map(activity => this.enrichActivity(activity, intent))
    );
    
    // 4. Score by intent alignment
    const scored = enriched.map(activity => ({
      ...activity,
      intentScore: this.calculateIntentScore(activity, intent)
    }));
    
    // 5. Categorize
    const categorized = this.categorizeActivities(scored, intent);
    
    return categorized;
  }
  
  generateSearchQueries(intent) {
    // Use LLM to generate diverse search queries
    const queries = [];
    
    // Direct interest queries
    intent.explicit.interests.forEach(interest => {
      queries.push(`best ${interest} in ${intent.explicit.destination}`);
      queries.push(`${interest} ${intent.implicit.values.join(' ')} ${intent.explicit.destination}`);
    });
    
    // Travel style queries
    if (intent.implicit.travelStyle === 'adventure') {
      queries.push(`outdoor activities ${intent.explicit.destination}`);
      queries.push(`adventure sports ${intent.explicit.destination}`);
    }
    
    // Hidden gems
    queries.push(`hidden gems ${intent.explicit.destination}`);
    queries.push(`local favorites ${intent.explicit.destination}`);
    
    // Must-see landmarks
    queries.push(`must see attractions ${intent.explicit.destination}`);
    
    return queries;
  }
  
  async searchActivities(queries, location) {
    const allResults = [];
    
    for (const query of queries) {
      // Check cache first
      const cached = await this.checkCache(query);
      if (cached) {
        allResults.push(...cached);
        continue;
      }
      
      // Search Google Places API (New)
      const response = await fetch('https://places.googleapis.com/v1/places:searchText', {
        method: 'POST',
        headers: {
          'X-Goog-Api-Key': process.env.GOOGLE_MAPS_API_KEY,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.types,places.rating,places.userRatingCount,places.priceLevel,places.location,places.photos,places.editorialSummary,places.websiteUri'
        },
        body: JSON.stringify({
          textQuery: query,
          locationBias: {
            circle: {
              center: location,
              radius: 50000  // 50km
            }
          },
          maxResultCount: 20
        })
      });
      
      const data = await response.json();
      allResults.push(...(data.places || []));
      
      // Cache results
      await this.cacheResults(query, data.places);
    }
    
    // Deduplicate by place ID
    const unique = Array.from(
      new Map(allResults.map(p => [p.id, p])).values()
    );
    
    return unique;
  }
  
  async enrichActivity(activity, intent) {
    // Apply all 4 intelligence layers
    const intelligence = await intelligenceEngine.analyze(activity, intent);
    
    return {
      ...activity,
      intelligence,
      cost: intelligence.cost,
      duration: intelligence.duration,
      frictions: intelligence.frictions,
      recommendations: intelligence.recommendations
    };
  }
  
  calculateIntentScore(activity, intent) {
    let score = 0;
    
    // Direct interest match (highest weight)
    intent.explicit.interests.forEach(interest => {
      if (activity.types.includes(interest) || 
          activity.displayName.text.toLowerCase().includes(interest)) {
        score += 100;
      }
    });
    
    // Implicit preference alignment
    if (intent.implicit.values.includes('authentic') && activity.userRatingCount < 1000) {
      score += 50;  // Hidden gem bonus
    }
    
    // Avoidance penalty
    intent.implicit.avoidances?.forEach(avoid => {
      if (activity.types.includes(avoid)) {
        score -= 50;
      }
    });
    
    // Rating
    score += (activity.rating || 0) * 10;
    
    // Budget fit
    const budgetLevel = { low: 1, moderate: 2, high: 3, luxury: 4 }[intent.explicit.budget] || 2;
    if (activity.priceLevel <= budgetLevel) {
      score += 30;
    } else {
      score -= 20;
    }
    
    return score;
  }
  
  categorizeActivities(activities, intent) {
    const sorted = activities.sort((a, b) => b.intentScore - a.intentScore);
    
    return {
      mandatory: sorted.filter(a => a.intentScore >= 100),  // Direct interest matches
      mustSee: sorted.filter(a => a.types.includes('tourist_attraction') && a.rating >= 4.5),
      filler: sorted.filter(a => a.intentScore < 100 && a.rating >= 4.0),
      all: sorted
    };
  }
}
```

---

### 4. Itinerary Builder Agent

**Role:** Assemble activities into optimized daily schedules

**Responsibilities:**
- Calculate optimal activities per day
- Cluster activities geographically
- Optimize route order
- Insert meals along routes
- Assign time slots
- Balance mandatory/must-see/filler

**Implementation:**
```javascript
class ItineraryBuilderAgent {
  async build(activities, intent) {
    // 1. Calculate activities per day
    const { activitiesPerDay } = this.calculateDensity(intent);
    
    // 2. Select activities (mandatory-first approach)
    const selected = this.selectActivities(
      activities,
      intent.explicit.numberOfDays,
      activitiesPerDay
    );
    
    // 3. Cluster by geography
    const clustered = await this.clusterByDay(selected, intent.explicit.numberOfDays);
    
    // 4. Optimize route order within each day
    for (let day of clustered) {
      day.activities = await this.optimizeRoute(day.activities);
    }
    
    // 5. Insert meals along routes
    for (let day of clustered) {
      day.meals = await this.insertMeals(day.activities, intent);
    }
    
    // 6. Assign time slots
    for (let day of clustered) {
      day.schedule = this.assignTimeSlots(day.activities, day.meals);
    }
    
    // 7. Add metadata
    const itinerary = {
      id: generateId(),
      userId: intent.userId,
      destination: intent.explicit.destination,
      startDate: intent.explicit.startDate,
      endDate: intent.explicit.endDate,
      days: clustered,
      metadata: {
        totalActivities: selected.length,
        totalCost: this.calculateTotalCost(clustered),
        travelStyle: intent.implicit.travelStyle,
        pace: intent.implicit.pace
      },
      createdAt: new Date()
    };
    
    return itinerary;
  }
  
  selectActivities(activities, numberOfDays, activitiesPerDay) {
    const totalSlots = numberOfDays * activitiesPerDay;
    const selected = [];
    
    // Ensure at least 1 mandatory per day
    const mandatoryPerDay = Math.min(
      Math.ceil(activities.mandatory.length / numberOfDays),
      Math.floor(activitiesPerDay * 0.6)
    );
    
    for (let day = 0; day < numberOfDays; day++) {
      // Add mandatory activities
      const dayMandatory = activities.mandatory.splice(0, mandatoryPerDay);
      selected.push(...dayMandatory);
      
      // Fill remaining slots
      const remaining = activitiesPerDay - dayMandatory.length;
      const mustSeeCount = Math.floor(remaining * 0.4);
      const fillerCount = remaining - mustSeeCount;
      
      selected.push(
        ...activities.mustSee.splice(0, mustSeeCount),
        ...activities.filler.splice(0, fillerCount)
      );
    }
    
    return selected;
  }
  
  async optimizeRoute(activities) {
    // Use Google Routes API with waypoint optimization
    const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
      method: 'POST',
      headers: {
        'X-Goog-Api-Key': process.env.GOOGLE_MAPS_API_KEY,
        'X-Goog-FieldMask': 'routes.optimizedIntermediateWaypointIndex,routes.distanceMeters,routes.duration'
      },
      body: JSON.stringify({
        origin: { location: { latLng: activities[0].location } },
        destination: { location: { latLng: activities[activities.length - 1].location } },
        intermediates: activities.slice(1, -1).map(a => ({
          location: { latLng: a.location }
        })),
        travelMode: 'WALK',
        optimizeWaypointOrder: true
      })
    });
    
    const data = await response.json();
    const optimizedOrder = data.routes[0].optimizedIntermediateWaypointIndex;
    
    // Reorder activities
    const optimized = [activities[0]];
    optimizedOrder.forEach(index => optimized.push(activities[index + 1]));
    optimized.push(activities[activities.length - 1]);
    
    return optimized;
  }
  
  async insertMeals(activities, intent) {
    const meals = [];
    const mealTimes = { breakfast: '08:00', lunch: '12:30', dinner: '19:30' };
    
    // Find restaurants along the route
    for (let i = 0; i < activities.length - 1; i++) {
      const from = activities[i];
      const to = activities[i + 1];
      
      // Search along route
      const restaurants = await this.findRestaurantsAlongRoute(from, to, intent);
      
      if (restaurants.length > 0) {
        meals.push({
          type: this.determineMealType(from.endTime),
          restaurant: restaurants[0],
          insertAfter: from.id
        });
      }
    }
    
    return meals;
  }
}
```

---

### 5. Quality Checker Agent

**Role:** Detect frictions and ensure itinerary quality

**Responsibilities:**
- Run all friction detection algorithms
- Validate schedule feasibility
- Check budget compliance
- Ensure diversity and balance
- Suggest improvements

**Implementation:**
```javascript
class QualityCheckerAgent {
  async detectFrictions(itinerary) {
    const frictions = [];
    
    // Run all friction detectors
    frictions.push(...await this.detectBookingFrictions(itinerary));
    frictions.push(...await this.detectTransportFrictions(itinerary));
    frictions.push(...await this.detectMealGaps(itinerary));
    frictions.push(...await this.detectBudgetIssues(itinerary));
    frictions.push(...await this.detectTimeConstraints(itinerary));
    frictions.push(...await this.detectPhysicalDemands(itinerary));
    
    // Sort by severity
    return frictions.sort((a, b) => {
      const severityOrder = { high: 3, medium: 2, low: 1 };
      return severityOrder[b.severity] - severityOrder[a.severity];
    });
  }
  
  async validateQuality(itinerary) {
    const checks = {
      diversity: this.checkDiversity(itinerary),
      balance: this.checkBalance(itinerary),
      feasibility: this.checkFeasibility(itinerary),
      budgetCompliance: this.checkBudgetCompliance(itinerary),
      interestAlignment: this.checkInterestAlignment(itinerary)
    };
    
    const score = Object.values(checks).reduce((sum, check) => sum + check.score, 0) / 5;
    
    return {
      overallScore: score,
      checks,
      passed: score >= 0.7
    };
  }
}
```

---

### 6. Intelligence Engine (Shared Service)

**Role:** Centralized intelligence for all agents

**Responsibilities:**
- Activity classification
- Duration prediction
- Cost estimation
- Friction detection
- Review analysis
- Website scraping

**Implementation:**
```javascript
class IntelligenceEngine {
  async analyze(activity, intent) {
    // Run all intelligence layers in parallel
    const [classification, duration, cost, frictions, insights] = await Promise.all([
      this.classifyActivity(activity),
      this.predictDuration(activity),
      this.estimateCost(activity, intent),
      this.detectActivityFrictions(activity, intent),
      this.extractInsights(activity)
    ]);
    
    return {
      classification,
      duration,
      cost,
      frictions,
      insights,
      recommendations: this.generateRecommendations(activity, insights, intent)
    };
  }
  
  async predictDuration(activity) {
    // Multi-source duration prediction
    const sources = await Promise.all([
      this.getGoogleDuration(activity),
      this.analyzeReviewDuration(activity),
      this.scrapeWebsiteDuration(activity),
      this.getTypicalDuration(activity.types)
    ]);
    
    // Weighted average
    return this.combineDurations(sources);
  }
  
  async estimateCost(activity, intent) {
    // Comprehensive cost estimation
    return {
      entry: await this.estimateEntryCost(activity),
      guide: await this.estimateGuideCost(activity),
      equipment: await this.estimateEquipmentCost(activity),
      transportation: await this.estimateTransportCost(activity, intent),
      meals: await this.estimateMealCost(activity, intent),
      total: 0  // Calculated from above
    };
  }
}
```

---

## Data Flow Example

**User Input:** "I love skateboarding and want to visit Barcelona for 4 days on a moderate budget"

### Step 1: Orchestrator receives message
```javascript
orchestrator.state = 'INTENT_GATHERING';
```

### Step 2: Intent Analyzer extracts information
```json
{
  "explicit": {
    "destination": "Barcelona, Spain",
    "numberOfDays": 4,
    "budget": "moderate",
    "interests": ["skateboarding"]
  },
  "implicit": {
    "travelStyle": "adventure",
    "pace": "moderate",
    "values": ["authentic", "local", "creative"],
    "avoidances": ["touristy", "expensive"]
  },
  "completeness": 0.85
}
```

### Step 3: Activity Discovery searches and enriches
```javascript
// Searches:
// - "best skateboarding in Barcelona"
// - "skateparks Barcelona local"
// - "street art Barcelona"
// - "authentic tapas Barcelona"

// Returns 50+ activities, scored and categorized:
{
  "mandatory": [
    { "name": "MACBA Skatepark", "intentScore": 150 },
    { "name": "Sants Skatepark", "intentScore": 145 }
  ],
  "mustSee": [
    { "name": "Sagrada Familia", "intentScore": 45 }
  ]
}
```

### Step 4: Itinerary Builder creates schedule
```javascript
// Day 1: Skateboarding focus
// - MACBA Skatepark (mandatory)
// - Gothic Quarter street art
// - Tapas lunch (along route)
// - Sagrada Familia (must-see)
```

### Step 5: Quality Checker detects frictions
```javascript
// No high-severity frictions
// Medium: "Sagrada Familia requires advance booking"
```

### Step 6: Orchestrator presents itinerary
```
"I've created an amazing 4-day Barcelona itinerary focused on your love for skateboarding! 
Every day includes authentic skate spots, plus the best of Barcelona's culture and food..."
```

---

## Implementation Priority

### Phase 1: Core Agents (Week 1-2)
1. Orchestrator Agent (basic state machine)
2. Intent Analyzer Agent (LLM-based)
3. Activity Discovery Agent (Google Places integration)

### Phase 2: Intelligence (Week 3-4)
4. Intelligence Engine (duration, cost, classification)
5. Itinerary Builder Agent (route optimization)

### Phase 3: Quality (Week 5-6)
6. Quality Checker Agent (friction detection)
7. Refinement loops
8. Caching layer

---

## Key Improvements from V1

1. **Orchestrator-driven:** Clear workflow management
2. **Deep intent understanding:** Goes beyond surface requests
3. **Intelligence-first:** Every activity enriched before planning
4. **Friction-aware:** Proactive problem detection
5. **Budget-conscious:** Every decision respects constraints
6. **Quality-checked:** Validation before presentation

This architecture ensures DreamLnds creates truly intelligent, personalized, and friction-free itineraries.
