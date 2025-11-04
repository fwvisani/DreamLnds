# Activity Intelligence & Duration Prediction System

## Overview

DreamLnds needs to understand activities at a deep level - not just "this is a museum" but "this is a 4-hour immersive experience that requires advance booking and includes lunch." This document explains how we build that intelligence.

---

## Core Intelligence Layers

### Layer 1: Activity Classification & Duration Prediction
### Layer 2: Friction Detection & Mitigation
### Layer 3: Intent-Aware Recommendations
### Layer 4: Budget-Conscious Filtering

---

## Layer 1: Activity Classification & Duration Prediction

### Problem
Google Places API tells us "Yosemite National Park" but doesn't tell us:
- This is a full-day (8+ hour) experience
- You need a car to get there
- You should pack lunch
- Requires advance reservation
- Best visited in summer

### Solution: Multi-Source Duration Intelligence

#### Source 1: Google Places API Data

```javascript
async function getGooglePlaceInsights(placeId) {
  const place = await googlePlaces.getDetails(placeId, {
    fields: [
      'displayName',
      'types',                    // ['national_park', 'tourist_attraction']
      'userRatingCount',          // Popularity indicator
      'editorialSummary',         // Description
      'regularOpeningHours',      // Hours of operation
      'websiteUri',               // Official website
      'currentOpeningHours'       // Real-time status
    ]
  });
  
  return place;
}
```

#### Source 2: Review Mining (AI Analysis)

```javascript
async function analyzeReviewsForDuration(placeId) {
  // Get recent reviews
  const reviews = await googlePlaces.getReviews(placeId, { limit: 50 });
  
  // Use LLM to extract duration insights
  const analysis = await invokeLLM({
    messages: [{
      role: 'system',
      content: `Analyze these reviews and extract:
1. Average time visitors spent
2. Common complaints about time (too rushed, too long)
3. Recommended duration
4. Time-related tips (arrive early, book ahead, etc.)

Return JSON format.`
    }, {
      role: 'user',
      content: JSON.stringify(reviews)
    }],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'duration_analysis',
        strict: true,
        schema: {
          type: 'object',
          properties: {
            averageDuration: { type: 'integer', description: 'Minutes' },
            recommendedDuration: { type: 'integer' },
            timeInsights: {
              type: 'array',
              items: { type: 'string' }
            },
            crowdedTimes: {
              type: 'array',
              items: { type: 'string' }
            }
          },
          required: ['averageDuration', 'recommendedDuration'],
          additionalProperties: false
        }
      }
    }
  });
  
  return JSON.parse(analysis.choices[0].message.content);
}
```

**Example Output:**
```json
{
  "averageDuration": 480,
  "recommendedDuration": 540,
  "timeInsights": [
    "Most visitors spend 8-9 hours",
    "Arrive before 8am to avoid crowds",
    "Pack lunch - limited food options inside",
    "Reserve parking 2 weeks ahead in summer"
  ],
  "crowdedTimes": ["10am-2pm on weekends"]
}
```

#### Source 3: Activity Type Classification

```javascript
const ACTIVITY_TYPES = {
  // Full-day experiences (6+ hours)
  FULL_DAY: {
    types: ['national_park', 'theme_park', 'zoo', 'aquarium', 'ski_resort'],
    defaultDuration: 480,  // 8 hours
    characteristics: {
      needsTransportation: true,
      includesMeals: 'recommended',
      advanceBooking: 'often_required',
      weatherDependent: true
    }
  },
  
  // Half-day experiences (3-4 hours)
  HALF_DAY: {
    types: ['museum', 'art_gallery', 'botanical_garden', 'shopping_mall'],
    defaultDuration: 180,  // 3 hours
    characteristics: {
      needsTransportation: false,
      includesMeals: 'optional',
      advanceBooking: 'sometimes',
      weatherDependent: false
    }
  },
  
  // Short visits (1-2 hours)
  SHORT_VISIT: {
    types: ['landmark', 'viewpoint', 'church', 'monument', 'park'],
    defaultDuration: 90,   // 1.5 hours
    characteristics: {
      needsTransportation: false,
      includesMeals: 'no',
      advanceBooking: 'rarely',
      weatherDependent: true
    }
  },
  
  // Quick stops (30-60 min)
  QUICK_STOP: {
    types: ['cafe', 'store', 'market', 'street'],
    defaultDuration: 45,
    characteristics: {
      needsTransportation: false,
      includesMeals: 'no',
      advanceBooking: 'no',
      weatherDependent: false
    }
  },
  
  // Meal experiences (1-2 hours)
  DINING: {
    types: ['restaurant', 'cafe', 'bar'],
    defaultDuration: 90,
    characteristics: {
      needsTransportation: false,
      includesMeals: 'yes',
      advanceBooking: 'recommended_for_dinner',
      weatherDependent: false
    }
  },
  
  // Multi-day experiences
  MULTI_DAY: {
    types: ['hiking_trail', 'camping_area', 'resort'],
    defaultDuration: 1440,  // Full day minimum
    characteristics: {
      needsTransportation: true,
      includesMeals: 'required',
      advanceBooking: 'required',
      weatherDependent: true,
      requiresEquipment: true
    }
  }
};

function classifyActivity(place) {
  // Check each category
  for (const [category, config] of Object.entries(ACTIVITY_TYPES)) {
    if (place.types.some(type => config.types.includes(type))) {
      return {
        category,
        ...config
      };
    }
  }
  
  // Default to short visit
  return ACTIVITY_TYPES.SHORT_VISIT;
}
```

#### Source 4: Web Scraping Official Websites

```javascript
async function scrapeOfficialWebsite(websiteUrl) {
  // Scrape official website for duration info
  const html = await fetch(websiteUrl).then(r => r.text());
  
  // Use LLM to extract structured info
  const extracted = await invokeLLM({
    messages: [{
      role: 'system',
      content: `Extract visit information from this website:
- Recommended visit duration
- Ticket prices
- Booking requirements
- Special requirements (guides, equipment)
- Best time to visit
- What's included (meals, guides, etc.)

Return JSON.`
    }, {
      role: 'user',
      content: html.substring(0, 10000)  // First 10k chars
    }],
    response_format: { type: 'json_object' }
  });
  
  return JSON.parse(extracted.choices[0].message.content);
}
```

#### Combined Intelligence

```javascript
async function getActivityIntelligence(place) {
  // Parallel data gathering
  const [googleInsights, reviewAnalysis, websiteData] = await Promise.all([
    getGooglePlaceInsights(place.id),
    analyzeReviewsForDuration(place.id),
    place.websiteUri ? scrapeOfficialWebsite(place.websiteUri) : null
  ]);
  
  // Classify activity type
  const classification = classifyActivity(place);
  
  // Combine all sources with weighted priority
  const intelligence = {
    duration: {
      minimum: Math.min(
        reviewAnalysis.averageDuration * 0.7,
        classification.defaultDuration * 0.8
      ),
      recommended: reviewAnalysis.recommendedDuration || classification.defaultDuration,
      maximum: classification.defaultDuration * 1.5
    },
    
    requirements: {
      advanceBooking: websiteData?.bookingRequired || classification.characteristics.advanceBooking,
      transportation: classification.characteristics.needsTransportation,
      equipment: websiteData?.equipmentNeeded || classification.characteristics.requiresEquipment,
      guide: websiteData?.guideRequired || false
    },
    
    inclusions: {
      meals: websiteData?.mealsIncluded || classification.characteristics.includesMeals,
      tickets: websiteData?.ticketInfo || null
    },
    
    timing: {
      bestTimeOfDay: reviewAnalysis.bestTime || null,
      crowdedTimes: reviewAnalysis.crowdedTimes || [],
      weatherDependent: classification.characteristics.weatherDependent
    },
    
    tips: reviewAnalysis.timeInsights || []
  };
  
  // Cache this intelligence
  await cacheActivityIntelligence(place.id, intelligence);
  
  return intelligence;
}
```

---

## Layer 2: Friction Detection & Mitigation

### What is Friction?

Friction = Anything that could frustrate the user or ruin their experience

### Friction Types & Detection

```javascript
const FRICTION_TYPES = {
  BOOKING_REQUIRED: {
    severity: 'high',
    detection: (activity) => {
      return activity.intelligence.requirements.advanceBooking === 'required' ||
             activity.reviews.some(r => r.text.includes('sold out') || r.text.includes('book ahead'));
    },
    mitigation: {
      alert: "⚠️ Advance booking required - book 2-4 weeks ahead",
      action: "provide_booking_link",
      alternative: "suggest_similar_no_booking_needed"
    }
  },
  
  TRANSPORTATION_NEEDED: {
    severity: 'medium',
    detection: (activity) => {
      const distanceFromCity = calculateDistance(activity.location, cityCenter);
      return distanceFromCity > 15 || activity.intelligence.requirements.transportation;
    },
    mitigation: {
      alert: "🚗 Car/tour required - 45min drive from city center",
      action: "suggest_rental_car_or_tour",
      alternative: "suggest_closer_alternative"
    }
  },
  
  MEAL_GAP: {
    severity: 'medium',
    detection: (schedule) => {
      // Check if there's 4+ hours without a meal
      for (let i = 0; i < schedule.length - 1; i++) {
        const gap = calculateTimeGap(schedule[i].endTime, schedule[i + 1].startTime);
        if (gap > 240 && !schedule[i].includesMeal) {
          return true;
        }
      }
      return false;
    },
    mitigation: {
      alert: "🍽️ Long gap without food - pack snacks or add lunch stop",
      action: "insert_meal_break",
      alternative: "suggest_activity_with_food"
    }
  },
  
  WEATHER_RISK: {
    severity: 'low',
    detection: (activity, date) => {
      if (!activity.intelligence.timing.weatherDependent) return false;
      
      const forecast = getWeatherForecast(activity.location, date);
      return forecast.rainProbability > 60 || forecast.temp < 5 || forecast.temp > 35;
    },
    mitigation: {
      alert: "🌧️ Outdoor activity - check weather forecast",
      action: "suggest_backup_indoor_option",
      alternative: "move_to_better_weather_day"
    }
  },
  
  CROWD_OVERLOAD: {
    severity: 'low',
    detection: (activity, time) => {
      return activity.intelligence.timing.crowdedTimes.some(crowdTime => 
        isTimeInRange(time, crowdTime)
      );
    },
    mitigation: {
      alert: "👥 Peak crowd time - consider visiting earlier/later",
      action: "suggest_alternative_time",
      alternative: "suggest_less_crowded_alternative"
    }
  },
  
  BUDGET_EXCEED: {
    severity: 'high',
    detection: (activity, userBudget) => {
      const activityCost = estimateActivityCost(activity);
      const dailyBudget = userBudget.total / userBudget.days;
      return activityCost > dailyBudget * 0.4;  // Single activity > 40% of daily budget
    },
    mitigation: {
      alert: "💰 Expensive - $150 entrance + $80 guide",
      action: "show_cost_breakdown",
      alternative: "suggest_budget_friendly_alternative"
    }
  },
  
  PHYSICAL_DEMAND: {
    severity: 'medium',
    detection: (activity) => {
      const keywords = ['hiking', 'climbing', 'strenuous', 'difficult', 'steep'];
      return keywords.some(kw => 
        activity.description?.toLowerCase().includes(kw) ||
        activity.reviews.some(r => r.text.toLowerCase().includes(kw))
      );
    },
    mitigation: {
      alert: "🥾 Physically demanding - 8km hike with elevation gain",
      action: "show_difficulty_level",
      alternative: "suggest_easier_alternative"
    }
  },
  
  TIME_CONSTRAINT: {
    severity: 'high',
    detection: (activity, schedule) => {
      const allocated = activity.allocatedTime;
      const recommended = activity.intelligence.duration.recommended;
      return allocated < recommended * 0.7;  // Less than 70% of recommended time
    },
    mitigation: {
      alert: "⏰ Rushed - only 2hrs allocated but 4hrs recommended",
      action: "suggest_more_time",
      alternative: "remove_activity_or_adjust_schedule"
    }
  }
};

async function detectFrictions(itinerary, userProfile) {
  const frictions = [];
  
  for (const day of itinerary.days) {
    for (const activity of day.activities) {
      // Check each friction type
      for (const [type, config] of Object.entries(FRICTION_TYPES)) {
        if (config.detection(activity, day.date, userProfile)) {
          frictions.push({
            type,
            severity: config.severity,
            activity: activity.name,
            day: day.dayNumber,
            mitigation: config.mitigation
          });
        }
      }
    }
  }
  
  return frictions;
}
```

### Proactive Friction Mitigation

```javascript
async function mitigateFrictions(itinerary, frictions) {
  const mitigated = { ...itinerary };
  
  // Sort by severity
  frictions.sort((a, b) => {
    const severityOrder = { high: 3, medium: 2, low: 1 };
    return severityOrder[b.severity] - severityOrder[a.severity];
  });
  
  for (const friction of frictions) {
    switch (friction.type) {
      case 'BOOKING_REQUIRED':
        // Add booking link and warning
        const activity = findActivity(mitigated, friction.activity);
        activity.warnings = activity.warnings || [];
        activity.warnings.push({
          type: 'booking',
          message: friction.mitigation.alert,
          bookingLink: await getBookingLink(activity)
        });
        break;
        
      case 'MEAL_GAP':
        // Auto-insert meal break
        const day = mitigated.days[friction.day - 1];
        const mealBreak = await findNearbyRestaurant(
          day.activities,
          userProfile.budget,
          userProfile.cuisinePreferences
        );
        day.activities.splice(friction.activityIndex + 1, 0, mealBreak);
        break;
        
      case 'BUDGET_EXCEED':
        // Offer alternative
        const expensive = findActivity(mitigated, friction.activity);
        expensive.budgetWarning = {
          estimatedCost: estimateActivityCost(expensive),
          alternative: await findBudgetAlternative(expensive, userProfile)
        };
        break;
        
      case 'TIME_CONSTRAINT':
        // Extend time or suggest removal
        const rushed = findActivity(mitigated, friction.activity);
        rushed.timeWarning = {
          allocated: rushed.allocatedTime,
          recommended: rushed.intelligence.duration.recommended,
          suggestion: "Consider allocating more time or removing this activity"
        };
        break;
    }
  }
  
  return mitigated;
}
```

---

## Layer 3: Intent-Aware Recommendations

### Understanding Deep Intent

```javascript
async function extractDeepIntent(userMessage, conversationHistory) {
  const analysis = await invokeLLM({
    messages: [{
      role: 'system',
      content: `Analyze the user's message to extract deep intent:

1. Surface intent: What they explicitly said
2. Deep intent: What they really want
3. Constraints: Budget, physical ability, time, etc.
4. Emotional drivers: Adventure, relaxation, learning, etc.
5. Hidden preferences: Extracted from context

Example:
User: "I love skateboarding"
Surface: Wants skateboarding activities
Deep: Wants authentic local scene, not tourist traps
Constraints: Likely budget-conscious (skate culture)
Emotional: Community, freedom, creativity
Hidden: Probably likes street art, indie music, casual dining

Return detailed JSON analysis.`
    }, {
      role: 'user',
      content: JSON.stringify({
        message: userMessage,
        history: conversationHistory
      })
    }],
    response_format: { type: 'json_object' }
  });
  
  return JSON.parse(analysis.choices[0].message.content);
}
```

**Example Intent Analysis:**

**User says:** "I want to visit national parks"

**Surface intent:**
```json
{
  "activity": "national parks",
  "type": "outdoor"
}
```

**Deep intent (AI extracted):**
```json
{
  "surface": {
    "activity": "national parks",
    "type": "outdoor"
  },
  "deep": {
    "seeking": "nature immersion, escape from city, photography opportunities",
    "avoiding": "crowds, commercialization, rushed experiences",
    "values": "authenticity, sustainability, solitude"
  },
  "constraints": {
    "physical": "comfortable with moderate hiking",
    "time": "willing to dedicate full days",
    "budget": "moderate - willing to pay for quality experiences"
  },
  "emotional_drivers": [
    "connection with nature",
    "personal growth",
    "photography/memories"
  ],
  "hidden_preferences": {
    "accommodation": "prefers camping or eco-lodges over hotels",
    "dining": "pack own meals, local diners",
    "transportation": "needs rental car",
    "companions": "likely solo or small group",
    "pace": "slow, contemplative"
  },
  "recommendations": {
    "include": [
      "sunrise/sunset viewpoints",
      "wildlife watching spots",
      "photography workshops",
      "ranger-led programs",
      "camping gear rental info"
    ],
    "avoid": [
      "touristy viewpoints with buses",
      "expensive lodges",
      "rushed day trips",
      "crowded trails"
    ]
  }
}
```

### Intent-Driven Activity Selection

```javascript
async function selectActivitiesBasedOnIntent(intent, destination) {
  // Use intent analysis to guide search
  const searchQueries = generateSmartQueries(intent);
  
  // Example for national parks intent:
  // Instead of just "national parks near [city]"
  // Search for:
  const queries = [
    `${destination} national parks less crowded`,
    `${destination} sunrise viewpoints photography`,
    `${destination} wildlife watching spots`,
    `${destination} camping sites with facilities`,
    `${destination} ranger programs nature walks`,
    `${destination} scenic drives national parks`
  ];
  
  const results = await Promise.all(
    queries.map(q => googlePlaces.searchText(q))
  );
  
  // Rank by intent alignment
  const ranked = results.flat().map(place => ({
    ...place,
    intentScore: calculateIntentAlignment(place, intent)
  })).sort((a, b) => b.intentScore - a.intentScore);
  
  return ranked;
}

function calculateIntentAlignment(place, intent) {
  let score = 0;
  
  // Check if place matches "include" recommendations
  intent.recommendations.include.forEach(keyword => {
    if (place.description?.includes(keyword) ||
        place.reviews.some(r => r.text.includes(keyword))) {
      score += 20;
    }
  });
  
  // Penalize if place matches "avoid" list
  intent.recommendations.avoid.forEach(keyword => {
    if (place.description?.includes(keyword)) {
      score -= 30;
    }
  });
  
  // Bonus for crowd level alignment
  if (intent.deep.avoiding.includes('crowds') && place.userRatingsTotal < 1000) {
    score += 25;  // Hidden gem bonus
  }
  
  // Budget alignment
  if (place.priceLevel <= intent.constraints.budget.level) {
    score += 15;
  }
  
  return score;
}
```

---

## Layer 4: Budget-Conscious Filtering

### Comprehensive Cost Estimation

```javascript
async function estimateActivityCost(activity, userProfile) {
  const costs = {
    entry: 0,
    guide: 0,
    equipment: 0,
    transportation: 0,
    meals: 0,
    extras: 0
  };
  
  // 1. Entry/ticket cost
  if (activity.priceLevel) {
    // Google price level: 0 (free) to 4 ($$$$)
    const priceMap = { 0: 0, 1: 15, 2: 30, 3: 60, 4: 120 };
    costs.entry = priceMap[activity.priceLevel];
  }
  
  // 2. Check if guide required/recommended
  if (activity.intelligence.requirements.guide) {
    costs.guide = await getAverageGuideCost(activity);
  }
  
  // 3. Equipment rental
  if (activity.intelligence.requirements.equipment) {
    costs.equipment = await getEquipmentRentalCost(activity);
  }
  
  // 4. Transportation cost
  const distanceFromCity = calculateDistance(activity.location, userProfile.accommodation);
  if (distanceFromCity > 10) {
    costs.transportation = estimateTransportCost(distanceFromCity, userProfile.transportMode);
  }
  
  // 5. Meal costs (if activity is full-day)
  if (activity.intelligence.duration.recommended > 300) {  // 5+ hours
    if (activity.intelligence.inclusions.meals === 'included') {
      costs.meals = 0;  // Already included
    } else if (activity.intelligence.inclusions.meals === 'recommended') {
      costs.meals = userProfile.budget.mealBudget;
    }
  }
  
  // 6. Extract costs from reviews
  const reviewCosts = await extractCostsFromReviews(activity.reviews);
  if (reviewCosts.average) {
    // Use review data to refine estimates
    costs.entry = (costs.entry + reviewCosts.average) / 2;
  }
  
  const total = Object.values(costs).reduce((sum, cost) => sum + cost, 0);
  
  return {
    breakdown: costs,
    total,
    perPerson: total,
    currency: userProfile.currency || 'USD',
    confidence: reviewCosts.confidence || 'estimated'
  };
}
```

### Budget-Aware "Along the Way" Recommendations

```javascript
async function findRestaurantsAlongRoute(route, userProfile) {
  const { budget, cuisinePreferences } = userProfile;
  
  // Calculate remaining daily budget
  const spentSoFar = calculateDailySpending(userProfile.currentDay);
  const remainingBudget = budget.dailyFood - spentSoFar;
  
  // Determine acceptable price level
  let maxPriceLevel;
  if (remainingBudget > 50) maxPriceLevel = 3;      // $$$
  else if (remainingBudget > 25) maxPriceLevel = 2; // $$
  else maxPriceLevel = 1;                           // $
  
  // Search along route with budget constraint
  const restaurants = await googlePlaces.searchAlongRoute({
    route: route.polyline,
    type: 'restaurant',
    maxPriceLevel,
    minRating: 4.0,
    rankPreference: 'DISTANCE'
  });
  
  // Further filter by cuisine preference and budget
  const filtered = restaurants.filter(r => {
    // Check cuisine match
    const cuisineMatch = !cuisinePreferences.length || 
      cuisinePreferences.some(pref => r.types.includes(pref));
    
    // Estimate cost
    const estimatedCost = estimateRestaurantCost(r, userProfile);
    const withinBudget = estimatedCost <= remainingBudget;
    
    return cuisineMatch && withinBudget;
  });
  
  // Rank by: budget fit + rating + route proximity
  return filtered.map(r => ({
    ...r,
    estimatedCost: estimateRestaurantCost(r, userProfile),
    detourTime: calculateDetour(route, r.location),
    budgetFit: (remainingBudget - estimateRestaurantCost(r, userProfile)) / remainingBudget,
    score: calculateRestaurantScore(r, remainingBudget, route)
  })).sort((a, b) => b.score - a.score);
}

function calculateRestaurantScore(restaurant, remainingBudget, route) {
  const budgetScore = (remainingBudget - restaurant.estimatedCost) / remainingBudget * 40;
  const ratingScore = restaurant.rating * 8;
  const proximityScore = (1 - restaurant.detourTime / 15) * 30;  // Max 15min detour
  const popularityScore = Math.log(restaurant.userRatingsTotal) * 2;
  
  return budgetScore + ratingScore + proximityScore + popularityScore;
}
```

---

## Putting It All Together: Intelligent Activity Selection

```javascript
async function selectIntelligentActivities(userProfile, destination) {
  // 1. Extract deep intent
  const intent = await extractDeepIntent(
    userProfile.messages,
    userProfile.conversationHistory
  );
  
  // 2. Search for activities based on intent
  const candidates = await selectActivitiesBasedOnIntent(intent, destination);
  
  // 3. Get intelligence for each activity
  const enriched = await Promise.all(
    candidates.map(async activity => ({
      ...activity,
      intelligence: await getActivityIntelligence(activity),
      cost: await estimateActivityCost(activity, userProfile)
    }))
  );
  
  // 4. Filter by budget
  const withinBudget = enriched.filter(a => 
    a.cost.total <= userProfile.budget.dailyActivities
  );
  
  // 5. Detect potential frictions
  const withFrictions = withinBudget.map(activity => ({
    ...activity,
    frictions: detectActivityFrictions(activity, userProfile)
  }));
  
  // 6. Score and rank
  const scored = withFrictions.map(activity => ({
    ...activity,
    finalScore: calculateFinalScore(activity, intent, userProfile)
  })).sort((a, b) => b.finalScore - a.finalScore);
  
  // 7. Select top activities with diversity
  const selected = selectDiverseActivities(scored, userProfile.numberOfDays);
  
  return selected;
}

function calculateFinalScore(activity, intent, userProfile) {
  let score = 0;
  
  // Intent alignment (40%)
  score += activity.intentScore * 0.4;
  
  // Rating (20%)
  score += activity.rating * 4;
  
  // Budget fit (20%)
  const budgetFit = 1 - (activity.cost.total / userProfile.budget.dailyActivities);
  score += budgetFit * 20;
  
  // Friction penalty (10%)
  const frictionPenalty = activity.frictions.length * 5;
  score -= frictionPenalty;
  
  // Uniqueness bonus (10%)
  if (activity.userRatingsTotal < 1000 && activity.rating > 4.5) {
    score += 10;  // Hidden gem
  }
  
  return score;
}
```

---

## Example: National Park Full-Day Experience

### Input
```json
{
  "user": "I want to visit Yosemite National Park",
  "budget": "moderate",
  "interests": ["photography", "hiking", "nature"]
}
```

### AI Intelligence Output
```json
{
  "activity": {
    "name": "Yosemite National Park",
    "duration": {
      "minimum": 360,
      "recommended": 540,
      "maximum": 720
    },
    "requirements": {
      "advanceBooking": "required_2_weeks",
      "transportation": "car_required",
      "equipment": "hiking_boots_recommended",
      "guide": "optional_but_valuable"
    },
    "inclusions": {
      "meals": "not_included_pack_lunch",
      "parking": "included_with_reservation"
    },
    "costs": {
      "entry": 35,
      "parking": 0,
      "guide": 150,
      "equipment": 0,
      "meals": 25,
      "total": 210
    },
    "frictions": [
      {
        "type": "BOOKING_REQUIRED",
        "severity": "high",
        "mitigation": "Book parking reservation 2 weeks ahead at recreation.gov"
      },
      {
        "type": "TRANSPORTATION_NEEDED",
        "severity": "high",
        "mitigation": "3.5 hour drive from San Francisco - rent car or join tour"
      },
      {
        "type": "MEAL_GAP",
        "severity": "medium",
        "mitigation": "Pack lunch and snacks - limited food options inside park"
      }
    ],
    "aiRecommendations": {
      "bestTime": "Arrive before 7am to avoid crowds and catch sunrise",
      "mustSee": ["Tunnel View", "Glacier Point", "Yosemite Falls"],
      "photography": "Golden hour at Tunnel View (6:30am), Half Dome from Glacier Point (sunset)",
      "hiking": "Mist Trail to Vernal Fall (3hrs round trip, moderate difficulty)",
      "tips": [
        "Download offline maps - spotty cell service",
        "Bring layers - temperature varies 20°F throughout day",
        "Fill water bottles at visitor center",
        "Check trail conditions before hiking"
      ]
    },
    "schedule": {
      "06:30": "Arrive, park at Tunnel View",
      "06:45": "Sunrise photography at Tunnel View",
      "08:00": "Drive to Yosemite Valley",
      "08:30": "Breakfast at Yosemite Valley Lodge",
      "09:30": "Hike Mist Trail to Vernal Fall",
      "12:30": "Packed lunch at Vernal Fall",
      "14:00": "Return from hike",
      "15:00": "Drive to Glacier Point",
      "16:00": "Explore Glacier Point",
      "18:30": "Sunset photography",
      "19:30": "Drive back to accommodation"
    }
  }
}
```

---

## Key Takeaways

1. **Multi-Source Intelligence**: Combine Google APIs + reviews + websites + AI analysis
2. **Proactive Friction Detection**: Predict problems before they happen
3. **Deep Intent Understanding**: Go beyond surface requests to understand true desires
4. **Budget Awareness**: Every recommendation respects user's financial constraints
5. **Realistic Planning**: Account for travel, meals, breaks, and unexpected delays

This intelligence layer is what transforms DreamLnds from a simple itinerary generator into a true dream partner.
