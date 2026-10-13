import { redirect } from 'next/navigation';
import { CHECKOUT_HOST, PRODUCT, originFrom } from '@/lib/prices';
import { checkoutSession, hasKey } from '@/lib/dodo';

const THANKS = new Set(['/thanks', '/fr/thanks', '/de/thanks']);

// "Try it free": creates a Dodo checkout for the 3-day trial and sends the buyer there. Without the API key
// (or if Dodo fails), the product's plain checkout link still works; Indian cards then see Dodo's ₹15,000 limit.
export async function GET(request: Request) {
  const asked = new URL(request.url).searchParams.get('thanks') ?? '/thanks';
  const returnUrl = originFrom(request.headers) + (THANKS.has(asked) ? asked : '/thanks');
  let url = `${CHECKOUT_HOST}/buy/${PRODUCT}?quantity=1&redirect_url=${encodeURIComponent(returnUrl)}`;
  if (hasKey()) {
    try {
      url = (await checkoutSession(returnUrl)).checkout_url;
    } catch (error) {
      console.error('checkout session failed, using the plain link:', error);
    }
  }
  redirect(url);
}
