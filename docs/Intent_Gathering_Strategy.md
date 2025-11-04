# DreamLnds: Progressive Intent Gathering & Conversational AI Strategy

## 1. Core Philosophy: From Chatbot to Dream Partner

The initial user interaction is critical. Instead of presenting a form, we will present a single, inviting chat interface on the homepage. The goal is to make the AI feel less like a tool and more like a knowledgeable and inspiring travel partner. The system will be designed to handle ambiguity and progressively gather the necessary information to build a dream trip, even from a vague starting point.

This approach, which we'll call **Progressive Intent Gathering**, ensures the user is never blocked by a required field and can start dreaming immediately.

---

## 2. The Minimum Viable Intent (MVI)

While the AI can start with very little, there is a **Minimum Viable Intent (MVI)** required before the first itinerary can be generated. This is the absolute minimum information the planner needs to create a coherent first draft.

**The MVI for DreamLnds is: a `destination city` and a `number of days`.**

All conversational flows are designed to guide the user toward providing at least this MVI.

---

## 3. Conversational Flows for Core Intents

The `Intent & Profile Resolver` agent will be responsible for managing these conversations. It will maintain a state for the current user's request and know which pieces of information are still missing.

### A. Destination Intent

- **User Input:** "I want to go to Europe."
- **AI Response & Logic:**
    1.  The AI recognizes "Europe" as a continent, not a city.
    2.  It queries an internal database or makes a quick search to find popular countries in Europe, potentially cross-referencing with the user's profile if they have past trips or stated interests.
    3.  **AI Asks:** "Europe is a fantastic choice! To help me narrow it down, are you dreaming of the historic streets of Italy, the beautiful coasts of Spain, or the vibrant culture of France? Or do you have another country in mind?"
    4.  This continues until the user specifies a city.

### B. Duration (Dates) Intent

- **User Input:** "I want to go to Paris."
- **AI Response & Logic:**
    1.  The AI has the `city` but needs the `number of days`.
    2.  **AI Asks:** "Paris is magical! How much time are you thinking of spending there? A quick weekend getaway, a full week to explore, or something longer?"
    3.  **If the user is still vague (e.g., "I don't know"):** The AI will propose a default and explain its reasoning. "A 5-day trip is perfect for a first visit to Paris, allowing you to see the main highlights without feeling too rushed. Shall I start planning for 5 days?"
    4.  **If the user gives a season (e.g., "Sometime in the summer"):** The AI will use this preference. "Great! I'll plan a trip for you in mid-July to capture that summer atmosphere. We can always adjust the exact dates later."

### C. Budget Intent

- **User Input:** "Plan a 7-day trip to Tokyo."
- **AI Response & Logic:**
    1.  The AI has the MVI (`city` and `duration`). The budget is missing, but it's not a blocker.
    2.  The AI will assume a **`moderate`** budget by default. This provides the best balance and serves as a good starting point for refinement.
    3.  When presenting the itinerary, the AI will make this assumption explicit. "I've created a draft for your 7-day Tokyo adventure, keeping a moderate budget in mind for hotels and restaurants. You can let me know if you'd like to see more luxurious options or find ways to save money!"

### D. Interests & Vibe Intent

- **User Input:** "I want a relaxing beach vacation."
- **AI Response & Logic:**
    1.  This is a high-level "vibe" prompt. The AI needs to translate this into a concrete destination.
    2.  **AI Asks:** "A relaxing beach vacation sounds wonderful. Are you picturing the crystal-clear waters of the Caribbean, the iconic islands of Greece, or the tropical paradise of Thailand?"
    3.  Once a destination is chosen, the AI will use the "relaxing" keyword to influence its choices, prioritizing less-crowded spots, suggesting more downtime, and selecting activities like spa days over intense museum tours.

---

## 4. The "Dream" Elicitation

To truly enable dreams, the AI should go beyond logistics. After gathering the MVI, the AI will ask an open-ended, inspiring question.

> **AI Asks:** "This sounds like an amazing trip. Just so I can make it perfect for you, what is the one thing that would make this a dream come true? Is it seeing a specific landmark, trying a particular food, or capturing that perfect photo?"

This input is not just for flavor. The response will be stored and given the **highest priority** by the planning agents. If the user says their dream is to "see the Eiffel Tower sparkle at night," the `Day Planner` agent will ensure this is scheduled, even if it means rearranging other activities. This single feature transforms the tool from a planner into a dream-maker.
