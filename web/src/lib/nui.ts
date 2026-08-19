/**
 * Ponte con la NUI.
 * Un solo canale verso il client Lua: la UI dichiara l'endpoint, il client lo
 * inoltra al server che rivalida giocatore, lavoro, permesso di grado e rate
 * limit (sezione 6.1 del piano).
 */

import type { MdtResponse } from './types';

export const isBrowser = (): boolean => !(window as any).invokeNative;

const resourceName = (): string =>
  (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'KF_Police';

/** POST grezzo verso una callback NUI. */
export async function postNui<T = unknown>(name: string, data?: unknown): Promise<T | null> {
  if (isBrowser()) {
    return null;
  }

  try {
    const response = await fetch(`https://${resourceName()}/${name}`, {
      method: 'post',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });

    return (await response.json()) as T;
  } catch {
    return null;
  }
}

/**
 * Chiama un endpoint MDT.
 * In browser (npm run dev) risponde il mock, così l'interfaccia si sviluppa
 * senza il gioco avviato.
 */
export async function callMdt<T extends MdtResponse = MdtResponse>(
  endpoint: string,
  payload?: Record<string, unknown>,
): Promise<T> {
  if (isBrowser()) {
    const { mockEndpoint } = await import('./mock');
    return mockEndpoint(endpoint, payload ?? {}) as T;
  }

  const response = await postNui<T>('mdt', { endpoint, payload: payload ?? {} });

  if (!response) {
    return { ok: false, error: 'nui_unreachable' } as T;
  }

  return response;
}

/** Chiude il tablet. */
export function closeMdt(): void {
  void postNui('mdt:close');
}
