-- DreamLnds Database Schema
-- Version: 1.0
-- Date: 2025-11-03

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- SOCIAL SCHEMA
-- ============================================================================

-- Profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT CHECK (char_length(bio) <= 500),
    website_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Follows table
CREATE TABLE public.follows (
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Posts table
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT CHECK (char_length(content) <= 5000),
    itinerary_id UUID,
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'followers_only', 'private')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Post media table
CREATE TABLE public.post_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Likes table
CREATE TABLE public.likes (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (user_id, post_id)
);

-- Comments table
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 1000),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================================================
-- PLANNER SCHEMA
-- ============================================================================

-- Itineraries table
CREATE TABLE public.itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    destination_city TEXT NOT NULL,
    current_version_id UUID,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CHECK (end_date >= start_date)
);

-- Itinerary versions table
CREATE TABLE public.itinerary_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    itinerary_id UUID NOT NULL REFERENCES public.itineraries(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    itinerary_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (itinerary_id, version_number)
);

-- Add foreign key for current_version_id
ALTER TABLE public.itineraries 
ADD CONSTRAINT itineraries_current_version_id_fkey 
FOREIGN KEY (current_version_id) REFERENCES public.itinerary_versions(id);

-- Timeline items table
CREATE TABLE public.timeline_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    itinerary_id UUID NOT NULL REFERENCES public.itineraries(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('activity', 'meal', 'hotel', 'transfer')),
    place_id TEXT,
    place_name TEXT,
    place_data JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CHECK (end_time > start_time)
);

-- Add foreign key for posts.itinerary_id
ALTER TABLE public.posts 
ADD CONSTRAINT posts_itinerary_id_fkey 
FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE SET NULL;

-- ============================================================================
-- CACHING SCHEMA
-- ============================================================================

-- Cache for Google Places API details
CREATE TABLE public.cache_places_details (
    place_id TEXT PRIMARY KEY,
    place_data JSONB NOT NULL,
    cached_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

-- Cache for Google Routes API
CREATE TABLE public.cache_routes (
    route_key TEXT PRIMARY KEY,
    origin_place_id TEXT NOT NULL,
    destination_place_id TEXT NOT NULL,
    travel_mode TEXT NOT NULL,
    route_data JSONB NOT NULL,
    cached_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

-- Cache for AI responses
CREATE TABLE public.cache_ai_responses (
    cache_key TEXT PRIMARY KEY,
    prompt_hash TEXT NOT NULL,
    response_data JSONB NOT NULL,
    cached_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

-- ============================================================================
-- ADMIN SCHEMA
-- ============================================================================

-- Feature flags table
CREATE TABLE public.feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flag_name TEXT UNIQUE NOT NULL,
    is_enabled BOOLEAN DEFAULT false,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Audit logs table
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at DESC);

-- Follows indexes
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- Posts indexes
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX idx_posts_itinerary_id ON public.posts(itinerary_id) WHERE itinerary_id IS NOT NULL;

-- Post media indexes
CREATE INDEX idx_post_media_post_id ON public.post_media(post_id);

-- Likes indexes
CREATE INDEX idx_likes_post_id ON public.likes(post_id);

-- Comments indexes
CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_user_id ON public.comments(user_id);

-- Itineraries indexes
CREATE INDEX idx_itineraries_user_id ON public.itineraries(user_id);
CREATE INDEX idx_itineraries_is_public ON public.itineraries(is_public) WHERE is_public = true;
CREATE INDEX idx_itineraries_created_at ON public.itineraries(created_at DESC);

-- Itinerary versions indexes
CREATE INDEX idx_itinerary_versions_itinerary_id ON public.itinerary_versions(itinerary_id);
CREATE INDEX idx_itinerary_versions_data ON public.itinerary_versions USING GIN (itinerary_data);

-- Timeline items indexes
CREATE INDEX idx_timeline_items_itinerary_id ON public.timeline_items(itinerary_id);
CREATE INDEX idx_timeline_items_day_number ON public.timeline_items(day_number);

-- Cache indexes
CREATE INDEX idx_cache_places_expires_at ON public.cache_places_details(expires_at);
CREATE INDEX idx_cache_routes_expires_at ON public.cache_routes(expires_at);
CREATE INDEX idx_cache_ai_expires_at ON public.cache_ai_responses(expires_at);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timeline_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cache_places_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cache_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cache_ai_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can delete their own profile" ON public.profiles FOR DELETE USING (auth.uid() = id);

-- Follows policies
CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow others" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Posts policies
CREATE POLICY "Public posts are viewable by everyone" ON public.posts FOR SELECT USING (
    visibility = 'public' OR 
    user_id = auth.uid() OR
    (visibility = 'followers_only' AND EXISTS (
        SELECT 1 FROM public.follows WHERE follower_id = auth.uid() AND following_id = user_id
    ))
);
CREATE POLICY "Users can insert their own posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON public.posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- Post media policies (inherit from posts)
CREATE POLICY "Post media is viewable if parent post is viewable" ON public.post_media FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.posts WHERE id = post_id AND (
            visibility = 'public' OR 
            user_id = auth.uid() OR
            (visibility = 'followers_only' AND EXISTS (
                SELECT 1 FROM public.follows WHERE follower_id = auth.uid() AND following_id = posts.user_id
            ))
        )
    )
);
CREATE POLICY "Users can insert media for their own posts" ON public.post_media FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.posts WHERE id = post_id AND user_id = auth.uid())
);
CREATE POLICY "Users can delete media from their own posts" ON public.post_media FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.posts WHERE id = post_id AND user_id = auth.uid())
);

-- Likes policies
CREATE POLICY "Likes are viewable by everyone" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike posts" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- Comments policies
CREATE POLICY "Comments are viewable if parent post is viewable" ON public.comments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.posts WHERE id = post_id AND (
            visibility = 'public' OR 
            user_id = auth.uid() OR
            (visibility = 'followers_only' AND EXISTS (
                SELECT 1 FROM public.follows WHERE follower_id = auth.uid() AND following_id = posts.user_id
            ))
        )
    )
);
CREATE POLICY "Users can insert their own comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own comments" ON public.comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- Itineraries policies
CREATE POLICY "Public itineraries are viewable by everyone" ON public.itineraries FOR SELECT USING (
    is_public = true OR user_id = auth.uid()
);
CREATE POLICY "Users can insert their own itineraries" ON public.itineraries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own itineraries" ON public.itineraries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own itineraries" ON public.itineraries FOR DELETE USING (auth.uid() = user_id);

-- Itinerary versions policies (inherit from itineraries)
CREATE POLICY "Itinerary versions are viewable if parent itinerary is viewable" ON public.itinerary_versions FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND (is_public = true OR user_id = auth.uid())
    )
);
CREATE POLICY "Users can insert versions for their own itineraries" ON public.itinerary_versions FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND user_id = auth.uid())
);

-- Timeline items policies (inherit from itineraries)
CREATE POLICY "Timeline items are viewable if parent itinerary is viewable" ON public.timeline_items FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND (is_public = true OR user_id = auth.uid())
    )
);
CREATE POLICY "Users can insert timeline items for their own itineraries" ON public.timeline_items FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND user_id = auth.uid())
);
CREATE POLICY "Users can update timeline items for their own itineraries" ON public.timeline_items FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND user_id = auth.uid())
);
CREATE POLICY "Users can delete timeline items for their own itineraries" ON public.timeline_items FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.itineraries WHERE id = itinerary_id AND user_id = auth.uid())
);

-- Cache policies (accessible by authenticated users)
CREATE POLICY "Cache is readable by authenticated users" ON public.cache_places_details FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Cache is writable by authenticated users" ON public.cache_places_details FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Routes cache is readable by authenticated users" ON public.cache_routes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Routes cache is writable by authenticated users" ON public.cache_routes FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "AI cache is readable by authenticated users" ON public.cache_ai_responses FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "AI cache is writable by authenticated users" ON public.cache_ai_responses FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Feature flags policies (read-only for all, admin-only for write)
CREATE POLICY "Feature flags are viewable by everyone" ON public.feature_flags FOR SELECT USING (true);

-- Audit logs policies (admin-only)
CREATE POLICY "Audit logs are viewable by admins only" ON public.audit_logs FOR SELECT USING (false);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_itineraries_updated_at BEFORE UPDATE ON public.itineraries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timeline_items_updated_at BEFORE UPDATE ON public.timeline_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feature_flags_updated_at BEFORE UPDATE ON public.feature_flags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, full_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
