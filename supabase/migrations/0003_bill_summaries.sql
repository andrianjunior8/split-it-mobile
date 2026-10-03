-- One row per bill with its computed totals, for the Home and History lists.
-- security_invoker makes the view obey the caller's RLS on bills/bill_items.
--
-- Rounding must match SplitCalculator in Dart: service on subtotal, tax on
-- subtotal + service, both rounded half up to the nearest rupiah.
create view public.bill_summaries with (security_invoker = true) as
select
  b.id,
  b.host_id,
  b.title,
  b.bill_date,
  b.status,
  b.service_bps,
  b.tax_bps,
  b.created_at,
  s.subtotal,
  sv.service,
  tx.tax,
  s.subtotal + sv.service + tx.tax as total
from public.bills b
cross join lateral (
  select coalesce(sum(i.qty * i.unit_price - i.discount), 0)::bigint as subtotal
    from public.bill_items i
   where i.bill_id = b.id
) s
cross join lateral (select (s.subtotal * b.service_bps + 5000) / 10000 as service) sv
cross join lateral (select ((s.subtotal + sv.service) * b.tax_bps + 5000) / 10000 as tax) tx;

revoke all on public.bill_summaries from anon;
grant select on public.bill_summaries to authenticated;

-- Replaces who shares an item in one transaction.
-- p_shares is {"<participant id>": <weight>, ...}; {} means "everyone equally".
-- security invoker: the caller's RLS applies, so only the host can do this.
create function public.set_item_shares(p_item_id uuid, p_shares jsonb)
returns void
language plpgsql security invoker set search_path = '' as $$
declare
  v_bill uuid;
begin
  select bill_id into v_bill from public.bill_items where id = p_item_id;
  if v_bill is null then
    raise exception 'Item not found' using errcode = 'P0002';
  end if;

  delete from public.item_shares where item_id = p_item_id;

  insert into public.item_shares (bill_id, item_id, participant_id, weight)
  select v_bill, p_item_id, e.key::uuid, e.value::integer
    from jsonb_each_text(p_shares) e;
end;
$$;

revoke execute on function public.set_item_shares(uuid, jsonb) from public, anon;
grant execute on function public.set_item_shares(uuid, jsonb) to authenticated;
