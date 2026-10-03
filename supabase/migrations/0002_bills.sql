-- Bills, the people splitting them, the ordered items, and who shares each item.
--
-- Money is stored as bigint rupiah (no fractions, no float rounding).
-- Tax and service are stored in basis points: 1000 = 10%.

create type public.bill_status as enum ('draft', 'done');

create table public.bills (
  id               uuid primary key default gen_random_uuid(),
  host_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title            text not null check (length(trim(title)) between 1 and 100),
  bill_date        date not null default current_date,
  status           public.bill_status not null default 'draft',
  service_bps      integer not null default 0 check (service_bps between 0 and 10000),
  tax_bps          integer not null default 0 check (tax_bps between 0 and 10000),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index bills_host_date_idx on public.bills (host_id, bill_date desc);

-- A splitter. user_id is null for friends who do not have an account.
create table public.participants (
  id            uuid primary key default gen_random_uuid(),
  bill_id       uuid not null references public.bills (id) on delete cascade,
  user_id       uuid references auth.users (id) on delete set null,
  display_name  text not null check (length(trim(display_name)) between 1 and 50),
  is_host       boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (bill_id, user_id),
  unique (id, bill_id)
);

create index participants_user_idx on public.participants (user_id);
create unique index participants_one_host_idx on public.participants (bill_id) where is_host;

create table public.bill_items (
  id          uuid primary key default gen_random_uuid(),
  bill_id     uuid not null references public.bills (id) on delete cascade,
  name        text not null check (length(trim(name)) between 1 and 100),
  qty         integer not null check (qty > 0),
  unit_price  bigint not null check (unit_price >= 0),
  discount    bigint not null default 0 check (discount >= 0),
  position    integer not null default 0,
  created_at  timestamptz not null default now(),
  check (discount <= qty * unit_price),
  unique (id, bill_id)
);

create index bill_items_bill_idx on public.bill_items (bill_id, position);

-- Who shares an item, and in what proportion (weight 2 = twice the share).
-- An item without any rows here is split equally among all participants.
-- The composite foreign keys guarantee item and participant are on the same bill.
create table public.item_shares (
  bill_id         uuid not null,
  item_id         uuid not null,
  participant_id  uuid not null,
  weight          integer not null default 1 check (weight > 0),
  primary key (item_id, participant_id),
  foreign key (item_id, bill_id) references public.bill_items (id, bill_id) on delete cascade,
  foreign key (participant_id, bill_id) references public.participants (id, bill_id) on delete cascade
);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger bills_touch_updated_at
  before update on public.bills
  for each row execute function public.touch_updated_at();

-- Every bill starts with its host as a participant.
create function public.add_host_participant() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  host_name text;
begin
  select coalesce(
           nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
           nullif(trim(u.raw_user_meta_data ->> 'username'), ''),
           split_part(u.email, '@', 1)
         )
    into host_name
    from auth.users u
   where u.id = new.host_id;

  insert into public.participants (bill_id, user_id, display_name, is_host)
  values (new.id, new.host_id, left(coalesce(host_name, 'Host'), 50), true);
  return new;
end;
$$;

create trigger bills_add_host_participant
  after insert on public.bills
  for each row execute function public.add_host_participant();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Members (host or a participant linked to an account) can read a bill.
-- Only the host can change it.
-- ---------------------------------------------------------------------------

-- security definer so the policies below do not recurse into each other.
create function public.is_bill_member(target_bill uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bills b
     where b.id = target_bill and b.host_id = (select auth.uid())
  ) or exists (
    select 1 from public.participants p
     where p.bill_id = target_bill and p.user_id = (select auth.uid())
  );
$$;

create function public.is_bill_host(target_bill uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bills b
     where b.id = target_bill and b.host_id = (select auth.uid())
  );
$$;

revoke execute on function public.is_bill_member(uuid) from public, anon;
revoke execute on function public.is_bill_host(uuid) from public, anon;
grant execute on function public.is_bill_member(uuid) to authenticated;
grant execute on function public.is_bill_host(uuid) to authenticated;

alter table public.bills        enable row level security;
alter table public.participants enable row level security;
alter table public.bill_items   enable row level security;
alter table public.item_shares  enable row level security;

create policy "Members read bills" on public.bills
  for select to authenticated using (public.is_bill_member(id));
create policy "Users create own bills" on public.bills
  for insert to authenticated with check (host_id = (select auth.uid()));
create policy "Host updates bill" on public.bills
  for update to authenticated
  using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));
create policy "Host deletes bill" on public.bills
  for delete to authenticated using (host_id = (select auth.uid()));

-- Column grants: the host flag and bill links cannot be changed after insert.
revoke update on public.participants from authenticated, anon;
grant update (display_name, user_id) on public.participants to authenticated;
revoke update on public.bill_items from authenticated, anon;
grant update (name, qty, unit_price, discount, position) on public.bill_items to authenticated;
revoke update on public.item_shares from authenticated, anon;
grant update (weight) on public.item_shares to authenticated;
revoke update on public.bills from authenticated, anon;
grant update (title, bill_date, status, service_bps, tax_bps) on public.bills to authenticated;

create policy "Members read participants" on public.participants
  for select to authenticated using (public.is_bill_member(bill_id));
create policy "Host adds participants" on public.participants
  for insert to authenticated with check (public.is_bill_host(bill_id) and not is_host);
create policy "Host edits participants" on public.participants
  for update to authenticated
  using (public.is_bill_host(bill_id)) with check (public.is_bill_host(bill_id));
create policy "Host removes non-host participants" on public.participants
  for delete to authenticated using (public.is_bill_host(bill_id) and not is_host);

create policy "Members read items" on public.bill_items
  for select to authenticated using (public.is_bill_member(bill_id));
create policy "Host writes items" on public.bill_items
  for all to authenticated
  using (public.is_bill_host(bill_id)) with check (public.is_bill_host(bill_id));

create policy "Members read shares" on public.item_shares
  for select to authenticated using (public.is_bill_member(bill_id));
create policy "Host writes shares" on public.item_shares
  for all to authenticated
  using (public.is_bill_host(bill_id)) with check (public.is_bill_host(bill_id));
