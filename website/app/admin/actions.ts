'use server';

import { revalidatePath } from 'next/cache';
import { notFound } from 'next/navigation';
import { adminAllowed } from '@/lib/admin';
import { freeSlot, setDisabled } from '@/lib/dodo';

// Each action checks again: server actions are reachable by POST, not only from the page.
function guard() { if (!adminAllowed()) notFound(); }

export async function revoke(form: FormData) {
  guard();
  await setDisabled(String(form.get('id')), true);
  revalidatePath('/admin');
}

export async function restore(form: FormData) {
  guard();
  await setDisabled(String(form.get('id')), false);
  revalidatePath('/admin');
}

export async function free(form: FormData) {
  guard();
  await freeSlot(String(form.get('key')), String(form.get('instance')));
  revalidatePath('/admin');
}
