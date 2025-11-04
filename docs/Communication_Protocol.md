# DreamLnds: UI-to-Agent Communication Protocol

## 1. Overview

To solve the critical challenge of keeping the user interface (UI) and the backend AI agents in sync, we will implement an **event-driven architecture**. Instead of the UI making assumptions, every significant user action on the Planner Grid will be translated into a structured event and sent to the backend. The `Conversational Editor` agent will process this event, orchestrate the necessary updates with other agents, and return a new, validated state of the itinerary to the UI.

This ensures a single source of truth (the backend state) and makes the system's behavior predictable and debuggable. All communication will happen over a secure WebSocket connection or via dedicated API endpoints, using JSON as the data format.

---

## 2. Core Principles

- **The UI is a "Dumb" Renderer:** The frontend's primary job is to render the state provided by the backend and to emit structured events based on user input. It does not contain business logic for itinerary planning.
- **Events are Commands, Not Suggestions:** An event like `MOVE_TIMELINE_ITEM` is a direct command from the user. The backend's job is to execute it and report back on the outcome (success, failure, or conflicts).
- **Idempotency:** Whenever possible, API endpoints for these events should be idempotent. For example, sending the same `UPDATE_ACTIVITY_DURATION` event multiple times should result in the same final state.
- **Single Source of Truth:** The `itineraries` and `itinerary_versions` tables in the Supabase database are the absolute source of truth. The UI always reflects this state.

---

## 3. Communication Flow

1.  **User Action:** A user performs an action in the Planner UI (e.g., drags an activity).
2.  **Frontend Emits Event:** The frontend constructs a JSON payload representing the action and sends it to the backend `Conversational Editor` agent.
3.  **Backend Processes Event:**
    a. The `Conversational Editor` receives the event and validates it.
    b. It calls other agents as needed (e.g., `Logistics & Time Agent` to check travel times, `Finders` to fetch alternatives).
    c. It checks for any resulting conflicts (e.g., scheduling clashes, opening hour violations).
    d. It creates a new version of the itinerary with the changes applied.
4.  **Backend Responds:** The backend sends the complete, updated itinerary JSON back to the frontend.
5.  **Frontend Re-renders:** The UI updates to reflect the new state, displaying the changes and any new conflict warnings.

---

## 4. Event & Payload Definitions

All events will be sent to an endpoint like `POST /api/v1/itineraries/{itineraryId}/events`.

The request body will have a common structure:

```json
{
  "eventId": "uuid", // Unique ID for this specific event, for tracing
  "eventType": "EVENT_NAME",
  "payload": { ... } // Event-specific payload
}
```

### Itinerary & Timeline Events

#### `MOVE_TIMELINE_ITEM`
- **Trigger:** User drags and drops an activity/meal/transfer to a new day or time.
- **Payload:**
  ```json
  {
    "timelineItemId": "uuid",
    "newDay": "YYYY-MM-DD",
    "newStartTime": "HH:MM:SS", // 24-hour format
    "source": "UI:DRAG_AND_DROP"
  }
  ```

#### `UPDATE_TIMELINE_ITEM_DURATION`
- **Trigger:** User resizes a tile on the grid to change its duration.
- **Payload:**
  ```json
  {
    "timelineItemId": "uuid",
    "newDurationMinutes": 120
  }
  ```

#### `ADD_TIMELINE_ITEM`
- **Trigger:** User adds a new activity from a search result or a list of alternatives.
- **Payload:**
  ```json
  {
    "placeId": "google_place_id", // Google Place ID of the new item
    "itemKind": "activity" | "meal",
    "targetDay": "YYYY-MM-DD",
    "targetStartTime": "HH:MM:SS" // Optional, AI can place it if omitted
  }
  ```

#### `REMOVE_TIMELINE_ITEM`
- **Trigger:** User deletes an activity from the itinerary.
- **Payload:**
  ```json
  {
    "timelineItemId": "uuid"
  }
  ```

#### `REPLACE_TIMELINE_ITEM`
- **Trigger:** User selects an alternative for an existing activity.
- **Payload:**
  ```json
  {
    "timelineItemIdToReplace": "uuid",
    "newPlaceId": "google_place_id_of_alternative"
  }
  ```

### Hotel Events

#### `CHANGE_HOTEL`
- **Trigger:** User selects a different hotel from the recommended list.
- **Payload:**
  ```json
  {
    "newHotelPlaceId": "google_place_id_of_hotel"
  }
  ```

### Conversational AI Events

#### `PROCESS_NATURAL_LANGUAGE_COMMAND`
- **Trigger:** User types a command into the chat interface (e.g., "Find a cheaper restaurant for dinner on day 2").
- **Payload:**
  ```json
  {
    "commandText": "Find a cheaper restaurant for dinner on day 2",
    "context": { // Optional context from the UI
      "activeDay": "YYYY-MM-DD",
      "selectedItemId": "uuid"
    }
  }
  ```
- **Response:** This is a special case. The backend might respond with a clarifying question or a list of suggestions (`ghost tiles`) for the user to approve, rather than a direct itinerary update.

#### `APPROVE_AI_SUGGESTION`
- **Trigger:** User clicks "Accept" on a `ghost tile` proposed by the AI.
- **Payload:**
  ```json
  {
    "suggestionId": "uuid" // ID of the suggestion to approve
  }
  ```

---

## 5. Backend Response Structure

After processing an event, the backend will respond with the full, updated itinerary object. This ensures the frontend is always in sync.

**Success Response (`200 OK`):**

```json
// The full itinerary JSON object, as defined in the PRD
{
  "runId": "...",
  "days": [ ... ],
  "notices": ["Travel time between activities on Day 2 has been updated."],
  ...
}
```

**Error/Conflict Response (`409 Conflict` or `400 Bad Request`):**

If an action results in a conflict, the backend will not immediately reject it. Instead, it will identify the conflict and return a specific `409 Conflict` response that details the collision and provides the UI with clear options for the user to resolve it.

```json
{
  "error": "ConflictDetected",
  "message": "Placing this activity here conflicts with an existing one.",
  "conflict": {
    "type": "OVERLAP", // or "CLOSING_HOURS", "EXCESSIVE_TRAVEL_TIME"
    "movingItemId": "uuid_of_item_being_moved",
    "conflictingItemId": "uuid_of_item_being_overlapped",
    "resolutionOptions": [
      {
        "action": "REPLACE",
        "description": "Replace 'Jardin du Luxembourg' with 'Louvre Museum'."
      },
      {
        "action": "SHIFT_AND_INSERT",
        "description": "Move 'Jardin du Luxembourg' and subsequent activities to a later time to make space."
      },
      {
        "action": "CANCEL",
        "description": "Cancel the move and leave everything as is."
      }
    ]
  },
  "originalItinerary": { ... } // The itinerary state before the failed action
}
```

Upon receiving this, the UI will display a modal dialog presenting the user with the `resolutionOptions`. The user's choice will then trigger a new event (e.g., `RESOLVE_CONFLICT` with the chosen action) sent back to the backend.

This protocol creates a robust and transparent system where user actions have clear and predictable outcomes, and the AI's role is to execute and validate those actions, making for a powerful and trustworthy user experience.
