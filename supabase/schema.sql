-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Enums
CREATE TYPE subscription_tier AS ENUM ('free', 'premium');
CREATE TYPE contest_status AS ENUM ('draft', 'active', 'ended');
CREATE TYPE voting_type AS ENUM ('like', 'stars', 'categories');

-- 2. Users Table
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    provider_id TEXT, -- Google Auth ID
    subscription_tier subscription_tier DEFAULT 'free',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Subscription History Table (New)
CREATE TABLE public.subscription_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tier subscription_tier NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE, -- Null means active indefinitely or auto-renew
    amount_paid DECIMAL(10, 2),
    currency TEXT DEFAULT 'USD',
    payment_provider TEXT, -- e.g., 'stripe', 'apple', 'google'
    transaction_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Contests Table
CREATE TABLE public.contests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    google_album_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status contest_status DEFAULT 'draft',
    start_at TIMESTAMP WITH TIME ZONE,
    end_at TIMESTAMP WITH TIME ZONE,
    voting_type voting_type DEFAULT 'like',
    custom_theme_config JSONB, -- For premium users to store colors/theme
    show_vote_counts BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Photos Table
CREATE TABLE public.photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL REFERENCES public.contests(id) ON DELETE CASCADE,
    google_media_item_id TEXT NOT NULL,
    meta_data JSONB, -- Store width, height, creationTime, etc.
    vote_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Votes Table
CREATE TABLE public.votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    photo_id UUID NOT NULL REFERENCES public.photos(id) ON DELETE CASCADE,
    score INTEGER DEFAULT 1, -- 1 for like, 1-5 for stars
    category TEXT, -- Optional for category voting (e.g., 'Best Smile', 'Funniest')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate voting per photo by the same user
    UNIQUE(user_id, photo_id)
);

-- 7. Functions & Triggers

-- Function to handle new user creation from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, avatar_url, provider_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'provider_id'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Automatically create public.users record when auth.users is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to automatically update vote_count on insert
CREATE OR REPLACE FUNCTION update_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.photos
        SET vote_count = vote_count + 1
        WHERE id = NEW.photo_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.photos
        SET vote_count = vote_count - 1
        WHERE id = OLD.photo_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_vote_change
AFTER INSERT OR DELETE ON public.votes
FOR EACH ROW EXECUTE FUNCTION update_vote_count();


-- 8. Row Level Security (RLS) Policies (Basic Examples)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- Users can view their own data
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Users can view their own subscription history
CREATE POLICY "Users can view own subscription history" ON public.subscription_history
    FOR SELECT USING (auth.uid() = user_id);

-- Everyone can view active contests (or restricted by link logic in app)
CREATE POLICY "Public can view active contests" ON public.contests
    FOR SELECT USING (status = 'active' OR status = 'ended');

-- Hosts can update their own contests
CREATE POLICY "Hosts can update own contests" ON public.contests
    FOR UPDATE USING (auth.uid() = host_user_id);

-- Everyone can view photos of active contests
CREATE POLICY "Public can view photos" ON public.photos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.contests 
            WHERE contests.id = photos.contest_id 
            AND (contests.status = 'active' OR contests.status = 'ended')
        )
    );

-- Authenticated users can vote
CREATE POLICY "Authenticated users can vote" ON public.votes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
