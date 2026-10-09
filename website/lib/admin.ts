// Who may open /admin. Locally, the dev server is yours. Live, the page stays off (404) until slice 10
// puts it behind Cloudflare Access and verifies Access's signed token here.
export const adminAllowed = () => process.env.NODE_ENV === 'development';
