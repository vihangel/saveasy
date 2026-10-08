-- Fundação: schema privado, enums e utilitários.
-- Valores dos enums batem com os @JsonValue do app (lib/shared/data/models).

create extension if not exists pg_trgm with schema extensions;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.account_type        as enum ('personal', 'business', 'influencer', 'community');
create type public.app_role            as enum ('user', 'moderator', 'admin');
create type public.verification_status as enum ('unverified', 'pending', 'verified', 'rejected');
create type public.pronouns            as enum ('ele_dele', 'ela_dela', 'elu_delu');

create type public.post_type     as enum ('donation', 'event', 'social_action', 'activity', 'tutorial', 'discussion', 'ad');
create type public.post_category as enum ('education', 'health', 'animal', 'environment', 'children', 'culture');
create type public.post_status   as enum ('draft', 'published', 'finished', 'cancelled', 'archived', 'hidden');
create type public.activity_kind as enum ('good_deed', 'item_giveaway');
create type public.interest_kind as enum ('saved', 'interested');
create type public.participation_status as enum ('going', 'cancelled', 'attended', 'no_show');
create type public.ad_plan       as enum ('daily', 'weekly', 'monthly');

create type public.ledger_reason as enum (
  'signup_bonus', 'coin_purchase', 'donation_reward', 'participation_reward',
  'post_created', 'story_created', 'ad_viewed', 'coins_sent', 'coins_received',
  'coins_donated', 'reward_redeemed', 'achievement_claimed', 'store_purchase_reward',
  'subscription_reward', 'invite_reward', 'admin_adjustment'
);

-- Atualiza updated_at automaticamente.
create function private.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end $$;
