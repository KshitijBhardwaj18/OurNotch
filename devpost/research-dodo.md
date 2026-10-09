# Dodo Payments — research notes (2026-10-04)

These are facts gathered for Milestone 2 licensing. Every claim links to its source. Check them again before building, because docs change.

## Licence keys
- One-time products can issue a licence key per unit bought. You set an expiry (30 days, 1 year, or never) and an activation limit per product. https://docs.dodopayments.com/features/license-keys
- Three endpoints are public, so the app can call them with no API key. Base URL `https://live.dodopayments.com`, or `https://test.dodopayments.com` for test mode.
  - `POST /licenses/activate` takes `{license_key, name}`. It returns 201 with `id` (the instance ID, `lki_…`), `product` and `customer`. Errors: 403 inactive, 404 not found, 422 activation limit reached.
  - `POST /licenses/validate` takes `{license_key, license_key_instance_id?}` and returns `{valid}`.
  - `POST /licenses/deactivate` takes `{license_key, license_key_instance_id}`.
- Dodo does no hardware fingerprinting. The app chooses the `name` and stores the returned `lki_` ID.
- The official Swift SDK is iOS only and only opens checkout. On macOS, use plain HTTPS with URLSession.

## Prices per region
- **Localized Pricing** sets a fixed price per country (e.g. IN ₹X) or per currency (e.g. all EUR €Z). It works on one-time products. Unmatched countries fall back to the base price converted live (Adaptive Currency, 2–4 % FX fee charged to the customer). https://docs.dodopayments.com/features/localized-pricing
- Checkout links can force the currency with `paymentCurrency` or show a currency selector with `showCurrencySelector`.

## India
- An Indian individual or company can be the merchant (needs PAN; GST registration is optional). Customers in India paying in INR get UPI, RuPay, Indian cards and Apple Pay. One-time purchases need no e-mandate.
- Payouts are **USD, GBP or EUR only** (INR payouts were discontinued). Paid on the 4th and 18th of the month.
- Not documented: FIRA/FIRC, LUT, export-of-services treatment. Ask support@dodopayments.com.

## Merchant of Record
- Dodo is the legal seller. It collects and remits EU VAT, US sales tax, Indian GST and more, and invoices customers. https://docs.dodopayments.com/features/mor-introduction

## Checkout, webhooks, testing
- Static link: `https://checkout.dodopayments.com/buy/{product_id}?redirect_url=…&metadata_<key>=…&country=…`. No backend needed.
- After payment, `return_url` receives a `license_key` parameter.
- Webhooks: `payment.succeeded`, `refund.succeeded`, `license_key.created`, `entitlement_grant.revoked`.
- Test card 4242424242424242, India Visa 4576238912771450, UPI `success@upi`. One FAQ line claims test mode generates no licence keys; check this early.

## Fees and refunds
- **Fees:** 4 % + 40¢, plus 1.5 % for international cards. India domestic is 4 % + 15¢. https://dodopayments.com/pricing
- **Refunds:** $1 each. Chargebacks: $30. Refund window is 30 days by default.
- **On refund the key is disabled automatically**, and `validate` then returns `valid: false`.

## Risk to clear first
- Dodo prohibits "social matching and interaction services", including "platforms for real-time person-to-person interactions". OurNotch isn't dating or matchmaking, but the wording is vague. **Get written pre-clearance from compliance@dodopayments.com before building on Dodo.** https://docs.dodopayments.com/miscellaneous/merchant-acceptance

## Suggested shape (to decide in the PRD/spec)
- **Product:** one one-time product with a licence key, activation limit 2 (one per partner's Mac), no expiry.
- **Prices:** a USD base, plus Localized Pricing for IN (₹) and EUR (€).
- **Buying:** the app opens a static checkout link carrying the pair ID.
- **Activating:** each Mac activates and keeps its `lki_` ID in the Keychain. The partner's Mac could receive the key through the encrypted pairing.
- **Checking:** validate on launch, with an offline grace period. "Move to a new Mac" calls deactivate.
