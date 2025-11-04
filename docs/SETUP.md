# DreamLnds Setup Guide

This document provides instructions for setting up the DreamLnds development environment.

## Prerequisites

- Node.js 22.x or higher
- pnpm (recommended) or npm
- Git
- A Supabase account
- A Google Cloud account (for Maps APIs)
- An OpenAI account (for GPT-5 API)

## Supabase Configuration

The DreamLnds backend is powered by Supabase. The project has been initialized with the complete database schema.

### Project Details

- **Project ID:** `godbkuerepkqdpkxqyzc`
- **Project URL:** `https://godbkuerepkqdpkxqyzc.supabase.co`
- **Region:** `us-east-2`
- **Database Version:** PostgreSQL 17

### Environment Variables

Create a `.env.local` file in the frontend directory with the following variables:

```bash
# Supabase
VITE_SUPABASE_URL=https://godbkuerepkqdpkxqyzc.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZGJrdWVyZXBrcWRwa3hxeXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0MzI1MTUsImV4cCI6MjA3NDAwODUxNX0.uUeSRdodyUUHrK-eP2JQ19r19wq2whbas7mhtYDlCxE

# OpenAI
VITE_OPENAI_API_KEY=your_openai_api_key_here

# Google Maps
VITE_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Important:** Never commit the `.env.local` file to version control. It is already included in `.gitignore`.

## Database Schema

The database schema has been fully initialized with the following components:

### Social Schema
- **profiles**: User profiles with username, bio, avatar, etc.
- **follows**: Follower/following relationships
- **posts**: User-generated posts with visibility controls
- **post_media**: Media attachments for posts
- **likes**: Post likes
- **comments**: Post comments

### Planner Schema
- **itineraries**: Top-level container for trip plans
- **itinerary_versions**: Version history for undo/redo functionality
- **timeline_items**: Individual activities, meals, hotels, and transfers

### Caching Schema
- **cache_places_details**: Cached Google Places API responses
- **cache_routes**: Cached Google Routes API responses
- **cache_ai_responses**: Cached AI-generated responses

### Admin Schema
- **feature_flags**: Feature toggles for gradual rollouts
- **audit_logs**: Audit trail for sensitive operations

All tables have Row Level Security (RLS) enabled with appropriate policies.

## Database Migrations

All schema changes are tracked in the `supabase/migrations/` directory (to be created). The initial schema has been applied as migration `init_dreamlnds_schema`.

To apply future migrations:

```bash
# Using Supabase CLI (when set up)
supabase db push

# Or using the Supabase MCP server
manus-mcp-cli tool call apply_migration --server supabase --input '{"project_id":"godbkuerepkqdpkxqyzc","name":"migration_name","query":"SQL_QUERY_HERE"}'
```

## Google Maps API Setup

DreamLnds uses the following Google Maps APIs:

- Places API
- Places API (New)
- Distance Matrix API
- Routes API
- Time Zone API
- Street View Static API
- Directions API
- Geocoding API
- Geolocation API
- Maps Embed API
- Maps JavaScript API
- Roads API
- Maps Static API

### Steps to Enable APIs

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable all the APIs listed above
4. Create an API key with appropriate restrictions
5. Add the API key to your `.env.local` file

## OpenAI API Setup

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Create an API key
3. Add the API key to your `.env.local` file

**Note:** DreamLnds is designed to use GPT-5, but will fall back to GPT-4 Turbo if GPT-5 is unavailable.

## Development Workflow

### Frontend Development

```bash
# Navigate to the frontend directory (to be created)
cd frontend

# Install dependencies
pnpm install

# Start the development server
pnpm dev
```

### Backend Development

Supabase Edge Functions will be developed in the `supabase/functions/` directory (to be created).

```bash
# Serve Edge Functions locally (when set up)
supabase functions serve

# Deploy Edge Functions
supabase functions deploy function_name
```

## Testing

### Running Tests

```bash
# Frontend tests
cd frontend
pnpm test

# E2E tests
pnpm test:e2e
```

## Deployment

### Frontend Deployment (Vercel)

The frontend will be automatically deployed to Vercel on every push to the `main` branch.

### Backend Deployment (Supabase)

Database migrations and Edge Functions are deployed through the Supabase dashboard or CLI.

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues, verify:
1. Your Supabase project is active
2. Your API keys are correct
3. Row Level Security policies are properly configured

### API Rate Limits

To avoid hitting API rate limits:
1. Use the caching tables extensively
2. Monitor API usage in the admin dashboard
3. Implement per-user rate limiting

## Support

For questions or issues, please refer to the documentation in the `docs/` directory or contact the development team.

---

**Last Updated:** November 3, 2025
