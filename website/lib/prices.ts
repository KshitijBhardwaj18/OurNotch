// Launch prices, fixed per region (devpost/prd-m2.md > Buying and Prices). No struck-through prices.
// Dodo charges the same amounts at checkout from the buyer's currency (Localized Pricing on the product).

// Countries that pay in euros (eurozone, Bulgaria since 2026, and euro-using microstates).
const EURO = new Set('AT BE BG HR CY EE FI FR DE GR IE IT LV LT LU MT NL PT SK SI ES AD MC SM VA ME XK'.split(' '));

export function priceFor(country?: string | null): string {
  const c = country?.toUpperCase();
  if (c === 'IN') return '₹499';
  if (c && EURO.has(c)) return '€3';
  return '$4.50';
}

// ponytail: Dodo test mode until launch, then the live product and checkout host.
// The 3-day free trial: a subscription that charges the one-time price once, on day 3, and lasts 20 years
// (Dodo's longest), so keeping it means paying once.
export const PRODUCT = 'pdt_0NpQhZeQ6pJ3R92rDOQAr';
export const CHECKOUT_HOST = 'https://test.checkout.dodopayments.com';

// Every "Try it free" button: our /buy route starts the checkout, then Dodo returns the buyer to the
// thank-you page in their language (`/thanks`, `/fr/thanks`, `/de/thanks`) with `license_key` added.
export function checkoutUrl(thanksPath = '/thanks'): string {
  return `/buy?thanks=${encodeURIComponent(thanksPath)}`;
}

// The site's own address, from the request (localhost in development, ournotch.app live).
export function originFrom(h: Headers): string {
  const host = h.get('host') ?? 'ournotch.app';
  return `${host.startsWith('localhost') || host.startsWith('127.') ? 'http' : 'https'}://${host}`;
}

// Dodo's customer portal: the buyer enters their purchase email and sees their key ("Find my licence").
export const portalUrl = 'https://test.customer.dodopayments.com/login/bus_0Np1laPQgg48PHzDsmzgI';
