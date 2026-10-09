import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { adminAllowed } from '@/lib/admin';
import { hasKey, keys, sales } from '@/lib/dodo';
import { free, restore, revoke } from './actions';

export const metadata: Metadata = { title: 'Admin · OurNotch', robots: { index: false } };
export const dynamic = 'force-dynamic';

const money = (minor: number, currency: string) =>
  new Intl.NumberFormat('en', { style: 'currency', currency }).format(minor / 100);
const day = (iso: string) => new Date(iso).toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' });
// Enough to recognise a key in an email; never the whole key on screen.
const short = (key: string) => `${key.slice(0, 8)}…`;

// The owner's page (devpost/prd-m2.md > Admin Page): sales, keys, and the kill switch, live from Dodo.
export default async function Admin() {
  if (!adminAllowed()) notFound();
  if (!hasKey()) {
    return (
      <main className="y-wrap a-page">
        <h1>Admin</h1>
        <p className="a-note">Add your Dodo test-mode API key to <code>website/.env.local</code> as <code>DODO_API_KEY=…</code>, then restart the dev server. The file is ignored by git.</p>
      </main>
    );
  }
  const [s, k] = await Promise.all([sales(), keys()]);
  return (
    <main className="y-wrap a-page">
      <h1>Admin</h1>
      <p className="a-note">Live from Dodo (test mode). Revoking a key locks both Macs of the pair at their next daily check.</p>

      <h2>Sales <small>{s.length}</small></h2>
      <div className="a-scroll">
        <table className="a-table">
          <thead><tr><th>Date</th><th>Country</th><th>Price</th><th>Status</th></tr></thead>
          <tbody>
            {s.map(p => (
              <tr key={p.id}>
                <td>{day(p.date)}</td><td>{p.country}</td><td>{money(p.amount, p.currency)}</td>
                <td>{p.refund ? `refund ${p.refund.toLowerCase()}` : p.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>Licence keys <small>{k.length}</small></h2>
      <div className="a-scroll">
        <table className="a-table">
          <thead><tr><th>Key</th><th>Status</th><th>Macs in use</th><th></th></tr></thead>
          <tbody>
            {k.map(key => (
              <tr key={key.id}>
                <td><code>{short(key.key)}</code><div className="a-dim">{day(key.created)}</div></td>
                <td className={key.status === 'active' ? '' : 'a-off'}>{key.status}</td>
                <td>
                  {key.macs.length}{key.limit != null && ` of ${key.limit}`}
                  {key.macs.map(m => (
                    <form key={m.id} action={free} className="a-mac">
                      <input type="hidden" name="key" value={key.key} /><input type="hidden" name="instance" value={m.id} />
                      <span>{m.name}</span><button className="a-btn">Free slot</button>
                    </form>
                  ))}
                </td>
                <td>
                  <form action={key.status === 'disabled' ? restore : revoke}>
                    <input type="hidden" name="id" value={key.id} />
                    <button className={key.status === 'disabled' ? 'a-btn' : 'a-btn a-danger'}>{key.status === 'disabled' ? 'Restore' : 'Revoke'}</button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
