// Server-only helper for the owner's admin page. The secret key never reaches the browser:
// it is read here, in server components and server actions only (devpost/spec-m2.md > Admin Page).

// ponytail: Dodo test mode until launch (slice 10 sets the live base URL).
const BASE = process.env.DODO_API_BASE ?? 'https://test.dodopayments.com';
import { PRODUCT } from './prices';

export const hasKey = () => Boolean(process.env.DODO_API_KEY);

async function dodo<T>(path: string, init: RequestInit = {}, auth = true): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (auth) headers.Authorization = `Bearer ${process.env.DODO_API_KEY}`;
  const res = await fetch(BASE + path, { ...init, headers, cache: 'no-store' });
  if (!res.ok) throw new Error(`Dodo answered ${res.status} for ${init.method ?? 'GET'} ${path.split('?')[0]}`);
  const text = await res.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

export type Sale = { id: string; date: string; country: string; amount: number; currency: string; status: string; refund: string | null };
export type Key = { id: string; key: string; status: string; limit: number | null; created: string; macs: { id: string; name: string; created: string }[] };

type Page<T> = { items: T[] };
type DodoPayment = { payment_id: string; created_at: string; total_amount: number; currency: string; status: string; refund_status: string | null; billing?: { country: string } };
type DodoKey = { id: string; key: string; status: string; activations_limit: number | null; instances_count: number; created_at: string };
type DodoInstance = { id: string; name: string; created_at: string };

// The latest 50 sales. The list has no country, so each sale is read once more.
// ponytail: one request per sale; page through or cache once sales outgrow 50.
export async function sales(): Promise<Sale[]> {
  const { items } = await dodo<Page<DodoPayment>>('/payments?page_size=50');
  const full = await Promise.all(items.map(p => dodo<DodoPayment>(`/payments/${p.payment_id}`)));
  return full.map(p => ({
    id: p.payment_id, date: p.created_at, country: p.billing?.country ?? '?',
    amount: p.total_amount, currency: p.currency, status: p.status, refund: p.refund_status,
  }));
}

// OurNotch's licence keys, with the Mac using each one (at most one: the buyer's).
export async function keys(): Promise<Key[]> {
  const { items } = await dodo<Page<DodoKey>>(`/license_keys?product_id=${PRODUCT}&page_size=100`);
  return Promise.all(items.map(async k => ({
    id: k.id, key: k.key, status: k.status, limit: k.activations_limit, created: k.created_at,
    macs: k.instances_count === 0 ? [] : (await dodo<Page<DodoInstance>>(`/license_key_instances?license_key_id=${k.id}`)).items
      .map(i => ({ id: i.id, name: i.name, created: i.created_at })),
  })));
}

// A checkout for the free trial. Indian cards approve a bank mandate for ₹499, not Dodo's ₹15,000 default.
export const checkoutSession = (returnUrl: string) =>
  dodo<{ checkout_url: string }>('/checkouts', {
    method: 'POST',
    body: JSON.stringify({ product_cart: [{ product_id: PRODUCT, quantity: 1 }], mandate_min_amount_inr_paise: 49900, return_url: returnUrl }),
  });

// The kill switch: a disabled key answers "not valid", so both Macs of the pair lock at their next check.
export const setDisabled = (id: string, disabled: boolean) =>
  dodo(`/license_keys/${id}`, { method: 'PATCH', body: JSON.stringify({ disabled }) });

// Frees a lost Mac's slot through Dodo's public deactivate call, so the buyer can activate a new Mac.
export const freeSlot = (key: string, instanceId: string) =>
  dodo('/licenses/deactivate', { method: 'POST', body: JSON.stringify({ license_key: key, license_key_instance_id: instanceId }) }, false);
