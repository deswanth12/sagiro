-- ====================================================================
-- PAISAPILOT FAMILY MODE v4.0 - ENTERPRISE POSTGRESQL SCHEMA
-- ====================================================================

CREATE TABLE families (
    family_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    photo_url TEXT,
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    invite_expires_at TIMESTAMP WITH TIME ZONE,
    invite_created_by VARCHAR(50),
    is_invite_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by VARCHAR(50)
);

CREATE TYPE family_role_enum AS ENUM ('owner', 'adult', 'child', 'guest');
CREATE TYPE member_status_enum AS ENUM ('pending', 'approved', 'declined');

CREATE TABLE family_members (
    family_id UUID REFERENCES families(family_id) ON DELETE CASCADE,
    user_id VARCHAR(50) NOT NULL,
    role family_role_enum NOT NULL DEFAULT 'adult',
    status member_status_enum NOT NULL DEFAULT 'pending',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (family_id, user_id)
);

CREATE TABLE family_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(family_id) ON DELETE CASCADE,
    user_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'family_created', 'member_joined', 'budget_created', 'goal_completed'
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(30) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE family_budgets (
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(family_id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    limit_amount NUMERIC(12, 2) NOT NULL,
    month VARCHAR(7) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by VARCHAR(50)
);

CREATE TABLE family_goals (
    goal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(family_id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    target_amount NUMERIC(12, 2) NOT NULL,
    saved_amount NUMERIC(12, 2) DEFAULT 0.00,
    deadline DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by VARCHAR(50)
);

-- Row-Level Security Policies
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_goals ENABLE ROW LEVEL SECURITY;
