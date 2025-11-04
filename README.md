# DreamLnds

**Build Your Dreams, Share Your Memories**

DreamLnds is a social network that enables dreams by combining AI-powered travel planning with a vibrant social community. The platform helps users turn their travel aspirations into reality through intelligent, personalized itinerary generation and seamless social sharing.

## 🌟 Vision

To be the world's leading social network for dream enablement, where inspiration meets execution.

## 🚀 Features

### Social Network
- User profiles with followers/following
- Social feed with posts, likes, and comments
- Share itineraries directly to the feed
- Clone and customize itineraries from the community

### AI-Powered Travel Planner
- **Conversational Onboarding**: Chat-based interface that guides users from vague ideas to concrete plans
- **Progressive Intent Gathering**: Start with minimal input and let the AI ask the right questions
- **Intelligent Itinerary Generation**: Day-by-day schedules with activities, meals, and transportation
- **Multiple Views**:
  - **Grid View** (Desktop): Time-slot grid with drag-and-drop editing
  - **Timeline View** (Mobile): Vertical timeline with expandable cards
  - **Map View**: Interactive map with routes and locations
- **Conflict Resolution**: Smart detection and resolution of scheduling conflicts

### Rich Data Integration
- Full integration with Google Maps Platform (13 APIs)
- Street View previews
- Real-time travel times and routes
- Detailed place information and reviews

## 🛠️ Tech Stack

### Frontend
- **Framework**: Vite + React 18 + TypeScript 5.0
- **Styling**: Tailwind CSS 3.3 + shadcn/ui
- **State Management**: Zustand + React Query
- **Drag-and-Drop**: @dnd-kit
- **Maps**: Google Maps JavaScript API
- **i18n**: i18next (Portuguese, English, Spanish)

### Backend
- **Platform**: Supabase
- **Database**: PostgreSQL 15 with Row Level Security (RLS)
- **Auth**: Supabase Auth (JWT + OAuth)
- **Storage**: Supabase Storage
- **API**: Supabase Edge Functions (Deno)

### AI & External Services
- **LLM**: OpenAI GPT-5
- **Maps**: Google Maps Platform
- **CDN**: Cloudflare

### DevOps
- **Hosting**: Vercel (frontend), Supabase (backend)
- **CI/CD**: GitHub Actions
- **Monitoring**: Sentry, Vercel Analytics

## 📁 Project Structure

```
DreamLnds/
├── docs/                           # Documentation
│   ├── PRD.md                      # Product Requirements Document
│   ├── Database_Schema.md          # Database schema and data model
│   ├── Communication_Protocol.md   # UI-to-Agent communication protocol
│   ├── Intent_Gathering_Strategy.md # Progressive intent gathering strategy
│   └── Enhancement_Proposals.md    # Future feature proposals
├── frontend/                       # Frontend application (to be created)
├── supabase/                       # Supabase configuration (to be created)
│   ├── migrations/                 # Database migrations
│   └── functions/                  # Edge Functions
└── README.md                       # This file
```

## 📚 Documentation

All project documentation is available in the [`docs/`](./docs/) directory:

- **[PRD.md](./docs/PRD.md)**: Comprehensive Product Requirements Document covering market analysis, user personas, features, and technical architecture.
- **[Database_Schema.md](./docs/Database_Schema.md)**: Detailed database schema with tables, relationships, and RLS policies.
- **[Communication_Protocol.md](./docs/Communication_Protocol.md)**: Event-driven architecture for UI-to-Agent communication.
- **[Intent_Gathering_Strategy.md](./docs/Intent_Gathering_Strategy.md)**: Conversational AI strategy for progressive intent gathering.
- **[Enhancement_Proposals.md](./docs/Enhancement_Proposals.md)**: Future feature ideas including Dream Board, Memory Maker, and more.

## 🎯 Roadmap

### MVP (v1.0) - 90-120 days
- ✅ User authentication and profiles
- ✅ Social feed with posts and itinerary sharing
- ✅ Conversational AI planner with progressive intent gathering
- ✅ Time-slot grid with drag-and-drop (desktop)
- ✅ Timeline view (mobile)
- ✅ Map view with routes
- ✅ Conflict detection and resolution

### v1.1
- Dream Board (inspiration collection)
- Direct Messaging
- Enhanced privacy controls

### v1.2
- Curated Dream Itineraries Marketplace
- Memory Maker (post-trip storytelling)
- Ads system

### Long-term
- Expansion to other verticals (music, food, events)
- Co-branded credit cards and loyalty programs
- Advanced AI features

## 🌍 Supported Languages

- Portuguese (pt-BR)
- English (en-US)
- Spanish (es-ES)

## 🔐 Security & Compliance

- GDPR, LGPD, and CCPA compliant
- End-to-end encryption for sensitive data
- Row Level Security (RLS) for database access
- Regular security audits

## 📊 Success Metrics (Year 1)

| Metric | Goal |
|--------|------|
| Total Registered Users | 150,000 |
| Monthly Active Users (MAU) | 120,000 (80%) |
| Premium Conversion Rate | 4% |
| Monthly Recurring Revenue (MRR) | $64,500 |
| Net Promoter Score (NPS) | 55+ |

## 🤝 Contributing

This is a private project. Contributions are currently limited to the core team.

## 📄 License

Proprietary - All rights reserved.

## 📞 Contact

- **Website**: [dreamlnds.com](https://dreamlnds.com) (under construction)
- **Website (BR)**: [dreamlnds.com.br](https://dreamlnds.com.br) (under construction)

---

**Built with ❤️ by the DreamLnds team**
