# Intelligent Scheduling & Personalization

## Overview

This document explains how DreamLnds creates optimized, personalized itineraries that minimize travel time, respect user preferences, and feel natural rather than robotic.

---

## Core Principles

### 1. **User Intent is King**
- If user says "I love skateboarding" → Skateparks are MANDATORY, not optional
- Tourist attractions are secondary to user's passions
- Balance: 60% user interests + 40% must-see landmarks

### 2. **Minimize Wasted Time**
- Group activities by geographic clusters
- Suggest restaurants "on the way" between activities
- Avoid backtracking across the city

### 3. **Realistic Pacing**
- Not too rushed (tourist trap syndrome)
- Not too empty (wasted vacation days)
- Adapt to user's energy level

---

## Algorithm 1: Activity Density Calculator

### Purpose
Determine optimal number of activities per day based on:
- Activity types (museums = slower, parks = faster)
- Travel distances
- User pace preference

### Formula

```javascript
function calculateActivitiesPerDay(params) {
  const {
    userPace,        // "relaxed" | "moderate" | "packed"
    dayDuration,     // hours available (e.g., 10 hours)
    activities,      // array of potential activities
    avgTravelTime    // average time between locations
  } = params;

  // Base time budgets per pace
  const paceConfig = {
    relaxed: {
      activityTime: 2.5,      // hours per activity
      mealTime: 1.5,          // hours per meal
      bufferTime: 1.0,        // spontaneity buffer
      maxActivities: 3
    },
    moderate: {
      activityTime: 2.0,
      mealTime: 1.0,
      bufferTime: 0.5,
      maxActivities: 4
    },
    packed: {
      activityTime: 1.5,
      mealTime: 0.75,
      bufferTime: 0.25,
      maxActivities: 6
    }
  };

  const config = paceConfig[userPace];
  
  // Calculate available time
  const availableTime = dayDuration 
    - (3 * config.mealTime)           // 3 meals
    - config.bufferTime;              // buffer
  
  // Calculate how many activities fit
  const timePerActivity = config.activityTime + avgTravelTime;
  const maxFit = Math.floor(availableTime / timePerActivity);
  
  // Cap at pace maximum
  const optimalCount = Math.min(maxFit, config.maxActivities);
  
  return {
    activitiesPerDay: optimalCount,
    totalTime: optimalCount * timePerActivity,
    bufferTime: availableTime - (optimalCount * timePerActivity)
  };
}
```

### Example Output

**User: "Relaxed pace, 5 days in Paris"**
```json
{
  "activitiesPerDay": 3,
  "schedule": {
    "09:00-11:30": "Activity 1",
    "11:30-13:00": "Lunch",
    "13:30-16:00": "Activity 2",
    "16:00-17:00": "Coffee break (buffer)",
    "17:30-20:00": "Activity 3",
    "20:00-21:30": "Dinner"
  }
}
```

**User: "Packed pace, 3 days in Tokyo"**
```json
{
  "activitiesPerDay": 6,
  "schedule": {
    "08:00-09:30": "Activity 1",
    "09:45-11:15": "Activity 2",
    "11:30-12:15": "Quick lunch",
    "12:30-14:00": "Activity 3",
    "14:15-15:45": "Activity 4",
    "16:00-17:30": "Activity 5",
    "17:45-19:15": "Activity 6",
    "19:30-21:00": "Dinner"
  }
}
```

---

## Algorithm 2: Geographic Clustering & Route Optimization

### Purpose
Group activities by location to minimize travel time and create logical "zones" for each day.

### Step 1: Cluster Activities by Geography

```javascript
function clusterActivitiesByLocation(activities, destination) {
  // Use k-means clustering to group activities
  // k = number of days in trip
  
  const clusters = kMeansClustering(
    activities.map(a => ({ lat: a.location.lat, lng: a.location.lng })),
    numberOfDays
  );
  
  // Assign each cluster to a day
  return clusters.map((cluster, dayIndex) => ({
    day: dayIndex + 1,
    activities: cluster,
    centroid: calculateCentroid(cluster),
    radius: calculateRadius(cluster)  // km from center
  }));
}
```

### Step 2: Optimize Order Within Each Day

```javascript
function optimizeActivityOrder(dayActivities, startLocation) {
  // Traveling Salesman Problem (TSP) solution
  // Use nearest neighbor heuristic for speed
  
  let currentLocation = startLocation;
  let remaining = [...dayActivities];
  let optimized = [];
  
  while (remaining.length > 0) {
    // Find nearest activity
    const nearest = findNearest(currentLocation, remaining);
    optimized.push(nearest);
    remaining = remaining.filter(a => a.id !== nearest.id);
    currentLocation = nearest.location;
  }
  
  return optimized;
}

function findNearest(from, activities) {
  return activities.reduce((nearest, activity) => {
    const distance = calculateDistance(from, activity.location);
    return distance < nearest.distance 
      ? { activity, distance }
      : nearest;
  }, { activity: activities[0], distance: Infinity }).activity;
}
```

### Step 3: Insert Meals "On The Way"

```javascript
async function insertMealsAlongRoute(activities, mealType) {
  const meals = [];
  
  for (let i = 0; i < activities.length - 1; i++) {
    const from = activities[i];
    const to = activities[i + 1];
    
    // Get route between activities
    const route = await getRoute(from.location, to.location);
    const midpoint = route.midpoint;
    
    // Search for restaurants near the route
    const restaurants = await searchPlacesNearRoute({
      route: route.polyline,
      type: 'restaurant',
      radius: 500,  // 500m from route
      priceLevel: userBudget,
      rating: 4.0   // minimum rating
    });
    
    // Pick best restaurant based on:
    // - Proximity to route (minimize detour)
    // - Rating
    // - Cuisine match to user preferences
    const bestRestaurant = rankRestaurants(restaurants, {
      userCuisinePreferences,
      routeProximity: true
    })[0];
    
    meals.push({
      restaurant: bestRestaurant,
      insertAfter: from,
      detourTime: calculateDetour(route, bestRestaurant.location)
    });
  }
  
  return meals;
}
```

### Visual Example

**Before Optimization:**
```
Hotel → Eiffel Tower (5km, 15min)
        ↓
        Louvre (8km, 25min)
        ↓
        Notre Dame (3km, 10min)
        ↓
        Sacré-Cœur (6km, 20min)

Total travel: 22km, 70 minutes
```

**After Optimization:**
```
Hotel → Louvre (2km, 8min)
        ↓
        [Lunch at Le Marais - on the way, +2min detour]
        ↓
        Notre Dame (1.5km, 6min)
        ↓
        Sacré-Cœur (4km, 15min)
        ↓
        [Dinner near Sacré-Cœur]
        ↓
        Eiffel Tower (5km, 18min)

Total travel: 12.5km, 47 minutes (-33% travel time!)
```

---

## Algorithm 3: User Interest Prioritization

### Purpose
Ensure user's passions are represented throughout the itinerary, not just as afterthoughts.

### Interest Weighting System

```javascript
function calculateActivityScore(activity, userProfile) {
  const {
    interests,        // ["skateboarding", "street art", "coffee"]
    travelStyle,      // "adventure" | "cultural" | "relaxation"
    mustSeeLevel      // "flexible" | "balanced" | "completist"
  } = userProfile;
  
  let score = 0;
  
  // 1. Direct interest match (HIGHEST PRIORITY)
  interests.forEach(interest => {
    if (activity.categories.includes(interest)) {
      score += 100;  // Major boost
    }
    if (activity.tags.includes(interest)) {
      score += 50;
    }
  });
  
  // 2. Travel style alignment
  const styleMatch = {
    adventure: ['outdoor', 'sports', 'hiking', 'extreme'],
    cultural: ['museum', 'art', 'history', 'architecture'],
    relaxation: ['spa', 'beach', 'park', 'cafe']
  };
  
  if (styleMatch[travelStyle].some(tag => activity.tags.includes(tag))) {
    score += 30;
  }
  
  // 3. Must-see landmarks (LOWER PRIORITY than user interests)
  if (activity.isMustSee) {
    score += mustSeeLevel === 'completist' ? 40 : 20;
  }
  
  // 4. Rating & popularity
  score += activity.rating * 5;
  score += Math.log(activity.reviewCount) * 2;
  
  // 5. Uniqueness (hidden gems bonus)
  if (activity.reviewCount < 1000 && activity.rating > 4.5) {
    score += 25;  // Hidden gem!
  }
  
  return score;
}
```

### Mandatory vs Optional Activities

```javascript
function categorizeActivities(activities, userProfile) {
  const scored = activities.map(activity => ({
    ...activity,
    score: calculateActivityScore(activity, userProfile)
  }));
  
  // Mandatory: Direct interest matches
  const mandatory = scored.filter(a => 
    userProfile.interests.some(interest => 
      a.categories.includes(interest) || a.tags.includes(interest)
    )
  );
  
  // Must-see: Famous landmarks
  const mustSee = scored.filter(a => a.isMustSee);
  
  // Filler: High-rated general activities
  const filler = scored.filter(a => 
    !mandatory.includes(a) && !mustSee.includes(a)
  );
  
  return { mandatory, mustSee, filler };
}

function buildItinerary(categorized, daysCount, activitiesPerDay) {
  const itinerary = [];
  
  for (let day = 1; day <= daysCount; day++) {
    const dayActivities = [];
    
    // Ensure at least 1 mandatory activity per day
    const mandatoryForDay = categorized.mandatory.shift();
    if (mandatoryForDay) dayActivities.push(mandatoryForDay);
    
    // Fill remaining slots with mix of must-see and filler
    const remaining = activitiesPerDay - dayActivities.length;
    const mustSeeCount = Math.floor(remaining * 0.4);  // 40% must-see
    const fillerCount = remaining - mustSeeCount;      // 60% filler
    
    dayActivities.push(
      ...categorized.mustSee.splice(0, mustSeeCount),
      ...categorized.filler.splice(0, fillerCount)
    );
    
    itinerary.push({
      day,
      activities: dayActivities
    });
  }
  
  return itinerary;
}
```

### Example: Skateboarding User in Barcelona

**User Profile:**
```json
{
  "interests": ["skateboarding", "street art", "tapas"],
  "travelStyle": "adventure",
  "mustSeeLevel": "balanced"
}
```

**Activity Scores:**
```
MACBA Skatepark          → 150 (skateboarding match + rating)
Sagrada Familia          → 45  (must-see + rating)
Park Güell               → 50  (must-see + outdoor)
Sants Skatepark          → 140 (skateboarding match)
Gothic Quarter Street Art → 120 (street art match + cultural)
La Rambla                → 35  (tourist spot)
Tapas Tour               → 130 (tapas match + experience)
```

**Generated 3-Day Itinerary:**
```
Day 1: Skateboarding Focus
  - MACBA Skatepark (MANDATORY - user interest)
  - Gothic Quarter Street Art (user interest)
  - Tapas Tour (user interest)
  - Sagrada Familia (must-see, balanced in)

Day 2: Culture + Skating
  - Sants Skatepark (MANDATORY - user interest)
  - Park Güell (must-see + outdoor)
  - El Born neighborhood (street art)
  - Beachfront skate spots

Day 3: Mix
  - Montjuïc (outdoor + views)
  - Boqueria Market (food)
  - Barceloneta Beach (relaxation)
  - Evening skate session at Forum
```

**Notice:** Every day has at least one skateboarding activity, even though Sagrada Familia is more "famous". User's passion comes first!

---

## Algorithm 4: Dynamic Adjustment Based on User Feedback

### Real-time Learning

```javascript
function adjustItinerary(currentItinerary, userFeedback) {
  const { action, activity, reason } = userFeedback;
  
  switch (action) {
    case 'removed':
      // User removed an activity - learn why
      if (reason === 'not_interested') {
        // Downweight similar activities
        adjustCategoryWeight(activity.categories, -20);
      } else if (reason === 'too_far') {
        // Reduce travel radius
        adjustMaxTravelDistance(-0.5);  // km
      }
      break;
      
    case 'added':
      // User manually added activity - boost similar ones
      adjustCategoryWeight(activity.categories, +30);
      break;
      
    case 'moved':
      // User changed order - respect their preference
      learnPreferredSequence(activity, newPosition);
      break;
  }
  
  // Regenerate itinerary with learned preferences
  return regenerateWithPreferences(currentItinerary);
}
```

---

## Algorithm 5: Time-of-Day Optimization

### Purpose
Schedule activities at optimal times based on:
- Opening hours
- Crowd levels
- Weather (if applicable)
- Energy levels

```javascript
function assignTimeSlots(activities, date) {
  const timeSlots = [];
  
  activities.forEach(activity => {
    // Get optimal time for this activity type
    const optimalTime = getOptimalTime(activity);
    
    timeSlots.push({
      activity,
      preferredTime: optimalTime,
      flexibility: calculateFlexibility(activity)
    });
  });
  
  // Sort by flexibility (least flexible first)
  timeSlots.sort((a, b) => a.flexibility - b.flexibility);
  
  // Assign times starting with least flexible
  const schedule = [];
  let currentTime = '09:00';
  
  timeSlots.forEach(slot => {
    const startTime = findBestTime(
      currentTime,
      slot.preferredTime,
      slot.activity.openingHours
    );
    
    schedule.push({
      activity: slot.activity,
      startTime,
      endTime: addMinutes(startTime, slot.activity.duration)
    });
    
    currentTime = addMinutes(
      schedule[schedule.length - 1].endTime,
      getTravelTime(schedule[schedule.length - 1], schedule[schedule.length])
    );
  });
  
  return schedule;
}

function getOptimalTime(activity) {
  const rules = {
    museum: '09:00',        // Early to avoid crowds
    restaurant_lunch: '12:30',
    restaurant_dinner: '19:30',
    park: '15:00',          // Afternoon when weather is best
    nightlife: '22:00',
    market: '08:00',        // Early for freshness
    viewpoint: '18:00'      // Sunset
  };
  
  return rules[activity.type] || '10:00';
}
```

---

## Integration with Google Maps APIs

### Route Optimization API Call

```javascript
async function optimizeRouteWithGoogle(activities) {
  // Use Google Routes API with waypoint optimization
  const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
    method: 'POST',
    headers: {
      'X-Goog-Api-Key': process.env.GOOGLE_MAPS_API_KEY,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline,routes.optimizedIntermediateWaypointIndex'
    },
    body: JSON.stringify({
      origin: { location: { latLng: activities[0].location } },
      destination: { location: { latLng: activities[activities.length - 1].location } },
      intermediates: activities.slice(1, -1).map(a => ({
        location: { latLng: a.location }
      })),
      travelMode: 'WALK',
      optimizeWaypointOrder: true,  // KEY: Let Google optimize!
      routingPreference: 'TRAFFIC_AWARE'
    })
  });
  
  const data = await response.json();
  const optimizedOrder = data.routes[0].optimizedIntermediateWaypointIndex;
  
  // Reorder activities based on Google's optimization
  return reorderActivities(activities, optimizedOrder);
}
```

### Finding Restaurants Along Route

```javascript
async function findRestaurantsAlongRoute(route) {
  // Use Places API (New) with searchAlongRoute
  const response = await fetch('https://places.googleapis.com/v1/places:searchAlongRoute', {
    method: 'POST',
    headers: {
      'X-Goog-Api-Key': process.env.GOOGLE_MAPS_API_KEY,
      'X-Goog-FieldMask': 'places.displayName,places.rating,places.priceLevel'
    },
    body: JSON.stringify({
      textQuery: 'restaurant',
      polyline: route.polyline,
      maxResultCount: 10,
      rankPreference: 'DISTANCE'  // Closest to route
    })
  });
  
  return await response.json();
}
```

---

## Putting It All Together: Complete Flow

```javascript
async function generateIntelligentItinerary(userInput) {
  // 1. Extract user preferences
  const profile = await extractUserProfile(userInput);
  
  // 2. Find ALL potential activities
  const allActivities = await findActivities(profile.destination);
  
  // 3. Score and categorize by user interests
  const categorized = categorizeActivities(allActivities, profile);
  
  // 4. Calculate optimal activities per day
  const { activitiesPerDay } = calculateActivitiesPerDay({
    userPace: profile.pace,
    dayDuration: 12,
    activities: allActivities,
    avgTravelTime: 0.5
  });
  
  // 5. Build initial itinerary (interest-first)
  let itinerary = buildItinerary(
    categorized,
    profile.numberOfDays,
    activitiesPerDay
  );
  
  // 6. Cluster activities by geography
  itinerary = await clusterActivitiesByLocation(
    itinerary,
    profile.destination
  );
  
  // 7. Optimize route order within each day
  for (let day of itinerary) {
    day.activities = await optimizeRouteWithGoogle(day.activities);
  }
  
  // 8. Insert meals along optimized routes
  for (let day of itinerary) {
    day.meals = await insertMealsAlongRoute(day.activities, profile.budget);
  }
  
  // 9. Assign optimal time slots
  for (let day of itinerary) {
    day.schedule = assignTimeSlots(day.activities, day.date);
  }
  
  // 10. Return complete, optimized itinerary
  return itinerary;
}
```

---

## Key Differentiators

### What Makes DreamLnds Special:

1. **Interest-First, Not Landmark-First**
   - Other apps: "Here are the top 10 tourist spots"
   - DreamLnds: "You love skateboarding? Here are the best skateparks + some famous spots"

2. **Route-Aware Meal Suggestions**
   - Other apps: "Here are restaurants in Paris"
   - DreamLnds: "This restaurant is 2 minutes off your route between activities"

3. **Realistic Pacing**
   - Other apps: 8 activities per day (exhausting!)
   - DreamLnds: 3-6 activities based on YOUR pace preference

4. **Geographic Intelligence**
   - Other apps: Random order of activities
   - DreamLnds: Cluster by neighborhood, minimize backtracking

5. **Learning System**
   - Other apps: Static itineraries
   - DreamLnds: Learns from your edits and improves suggestions

---

This intelligent scheduling system ensures every DreamLnds itinerary feels personalized, realistic, and optimized for the user's unique dream.
