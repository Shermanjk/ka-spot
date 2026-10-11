-- KaSpot v1. Latest location only; no historical location trail.
-- Apply using the Supabase SQL editor or Supabase CLI migrations.
begin;

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.connection_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> recipient_id)
);
create unique index if not exists one_pending_request_per_pair
  on public.connection_requests (least(requester_id, recipient_id), greatest(requester_id, recipient_id))
  where status = 'pending';

create table if not exists public.connections (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references auth.users(id) on delete cascade,
  user_b_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_a_id < user_b_id),
  unique (user_a_id, user_b_id)
);

create table if not exists public.location_sharing (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  is_enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (owner_id, recipient_id),
  check (owner_id <> recipient_id)
);

create table if not exists public.locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  recorded_at timestamptz not null default now()
);

create table if not exists public.saved_places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  created_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  connection_notifications_enabled boolean not null default true,
  arrival_alerts_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

create or replace function public.is_accepted_connection(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.connections c
    where (c.user_a_id = least(a, b) and c.user_b_id = greatest(a, b))
  );
$$;
revoke all on function public.is_accepted_connection(uuid, uuid) from public;
grant execute on function public.is_accepted_connection(uuid, uuid) to authenticated;

create or replace function public.guard_request_update()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.id <> old.id or new.requester_id <> old.requester_id
     or new.recipient_id <> old.recipient_id or new.created_at <> old.created_at then
    raise exception 'Request identity is immutable';
  end if;
  if old.status <> 'pending' or new.status not in ('accepted', 'rejected', 'cancelled') then
    raise exception 'Invalid request status transition';
  end if;
  if new.status in ('accepted', 'rejected') and auth.uid() <> old.recipient_id then
    raise exception 'Only the recipient can accept or reject';
  end if;
  if new.status = 'cancelled' and auth.uid() <> old.requester_id then
    raise exception 'Only the requester can cancel';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists connection_request_update_guard on public.connection_requests;
create trigger connection_request_update_guard before update on public.connection_requests
for each row execute function public.guard_request_update();

create or replace function public.create_connection_after_accept()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'accepted' and old.status = 'pending' then
    insert into public.connections (user_a_id, user_b_id)
    values (least(new.requester_id, new.recipient_id), greatest(new.requester_id, new.recipient_id))
    on conflict (user_a_id, user_b_id) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists accepted_request_creates_connection on public.connection_requests;
create trigger accepted_request_creates_connection after update of status on public.connection_requests
for each row execute function public.create_connection_after_accept();

create or replace function public.cleanup_sharing_after_connection_removal()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  delete from public.location_sharing
  where (owner_id = old.user_a_id and recipient_id = old.user_b_id)
     or (owner_id = old.user_b_id and recipient_id = old.user_a_id);
  return old;
end;
$$;
drop trigger if exists connection_removal_revokes_sharing on public.connections;
create trigger connection_removal_revokes_sharing after delete on public.connections
for each row execute function public.cleanup_sharing_after_connection_removal();

create or replace function public.guard_sharing_upsert()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.owner_id <> auth.uid() then raise exception 'Only the location owner may control sharing'; end if;
  if not public.is_accepted_connection(new.owner_id, new.recipient_id) then
    raise exception 'Sharing is available only to accepted connections';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists location_sharing_guard on public.location_sharing;
create trigger location_sharing_guard before insert or update on public.location_sharing
for each row execute function public.guard_sharing_upsert();

alter table public.profiles enable row level security;
alter table public.connection_requests enable row level security;
alter table public.connections enable row level security;
alter table public.location_sharing enable row level security;
alter table public.locations enable row level security;
alter table public.saved_places enable row level security;
alter table public.notification_preferences enable row level security;

-- A connected person can see only the owner's deliberately published profile fields.
create policy profile_self_or_connection_read on public.profiles for select to authenticated
using (id = (select auth.uid()) or public.is_accepted_connection(id, (select auth.uid())));
create policy profile_self_insert on public.profiles for insert to authenticated
with check (id = (select auth.uid()));
create policy profile_self_update on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy requests_participant_read on public.connection_requests for select to authenticated
using (requester_id = (select auth.uid()) or recipient_id = (select auth.uid()));
create policy requests_requester_create on public.connection_requests for insert to authenticated
with check (requester_id = (select auth.uid()) and requester_id <> recipient_id
  and not public.is_accepted_connection(requester_id, recipient_id));
create policy requests_participant_transition on public.connection_requests for update to authenticated
using ((requester_id = (select auth.uid()) or recipient_id = (select auth.uid())) and status = 'pending')
with check ((requester_id = (select auth.uid()) or recipient_id = (select auth.uid())));

create policy connections_participant_read on public.connections for select to authenticated
using (user_a_id = (select auth.uid()) or user_b_id = (select auth.uid()));
create policy connections_participant_remove on public.connections for delete to authenticated
using (user_a_id = (select auth.uid()) or user_b_id = (select auth.uid()));
-- Connection rows are created only by the trusted acceptance trigger. Removing
-- a connection deletes both directional grants before the transaction commits.

create policy sharing_owner_or_recipient_read on public.location_sharing for select to authenticated
using (owner_id = (select auth.uid()) or recipient_id = (select auth.uid()));
create policy sharing_owner_create on public.location_sharing for insert to authenticated
with check (owner_id = (select auth.uid()) and public.is_accepted_connection(owner_id, recipient_id));
create policy sharing_owner_update on public.location_sharing for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()) and public.is_accepted_connection(owner_id, recipient_id));
create policy sharing_owner_delete on public.location_sharing for delete to authenticated
using (owner_id = (select auth.uid()));

-- A user writes only their own latest location. A recipient reads only while
-- the owner has an enabled per-recipient sharing grant and the connection exists.
create policy locations_owner_upsert on public.locations for insert to authenticated
with check (user_id = (select auth.uid()) and exists (
  select 1 from public.location_sharing s where s.owner_id = (select auth.uid()) and s.is_enabled
));
create policy locations_owner_refresh on public.locations for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()) and exists (
  select 1 from public.location_sharing s where s.owner_id = (select auth.uid()) and s.is_enabled
));
create policy locations_authorized_read on public.locations for select to authenticated
using (user_id = (select auth.uid()) or exists (
  select 1 from public.location_sharing s
  where s.owner_id = locations.user_id and s.recipient_id = (select auth.uid())
    and s.is_enabled and public.is_accepted_connection(s.owner_id, s.recipient_id)
));
create policy locations_owner_delete on public.locations for delete to authenticated
using (user_id = (select auth.uid()));

create policy saved_places_owner_all on public.saved_places for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notification_preferences_owner_all on public.notification_preferences for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Make the Data API role grants explicit; RLS remains the row/relationship boundary.
revoke all on public.profiles, public.connection_requests, public.connections,
  public.location_sharing, public.locations, public.saved_places,
  public.notification_preferences from anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.connection_requests to authenticated;
grant select, delete on public.connections to authenticated;
grant select, insert, update, delete on public.location_sharing to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
grant select, insert, update, delete on public.saved_places to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;

-- Add public.locations and public.location_sharing to the supabase_realtime
-- publication in the dashboard only after reviewing RLS and Realtime settings.
-- A database trigger below removes public.locations when the owner's final
-- enabled sharing grant is disabled or deleted.

commit;


-- Keep this cleanup trigger at the database boundary: direct client-side revocation
-- must stop exposing stale coordinates even if the owner app closes immediately.
begin;
create or replace function public.remove_unshared_latest_location()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  affected_owner uuid;
begin
  if tg_op = 'DELETE' then
    affected_owner := old.owner_id;
  else
    affected_owner := new.owner_id;
  end if;
  if not exists (
    select 1 from public.location_sharing s
    where s.owner_id = affected_owner and s.is_enabled
  ) then
    delete from public.locations where user_id = affected_owner;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
drop trigger if exists sharing_revocation_clears_location on public.location_sharing;
create trigger sharing_revocation_clears_location after update of is_enabled or delete on public.location_sharing
for each row execute function public.remove_unshared_latest_location();
commit;
