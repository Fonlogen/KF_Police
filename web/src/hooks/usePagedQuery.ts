import { useCallback, useEffect, useRef, useState } from 'react';
import { callMdt } from '../lib/nui';
import type { Paged } from '../lib/types';

/**
 * Query paginata verso un endpoint MDT.
 * Sostituisce il modello "invia tutto il DB e filtra in React" (causa del bug
 * L4): ogni schermata chiede solo la propria pagina.
 */

export interface PagedQueryState<T> {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
  loading: boolean;
  error?: string;
  /** Campi aggiuntivi restituiti dall'endpoint (es. wantedCount). */
  extra: Record<string, unknown>;
}

export interface PagedQuery<T> extends PagedQueryState<T> {
  setPage: (page: number) => void;
  reload: () => void;
}

export function usePagedQuery<T>(
  endpoint: string,
  params: Record<string, unknown>,
  options?: { pageSize?: number; debounceMs?: number },
): PagedQuery<T> {
  const [state, setState] = useState<PagedQueryState<T>>({
    rows: [],
    total: 0,
    page: 1,
    pageSize: options?.pageSize ?? 25,
    loading: true,
    extra: {},
  });

  const [page, setPage] = useState(1);
  const [nonce, setNonce] = useState(0);

  // I parametri sono confrontati per valore: un oggetto nuovo a ogni render non
  // deve far ripartire la query.
  const serialized = JSON.stringify(params);
  const lastSerialized = useRef(serialized);

  // Cambiando filtro o ricerca si torna a pagina 1.
  useEffect(() => {
    if (lastSerialized.current !== serialized) {
      lastSerialized.current = serialized;
      setPage(1);
    }
  }, [serialized]);

  useEffect(() => {
    let cancelled = false;
    const debounce = options?.debounceMs ?? 0;

    setState((prev) => ({ ...prev, loading: true }));

    const run = async () => {
      const response = (await callMdt(endpoint, {
        ...JSON.parse(serialized),
        page,
        pageSize: options?.pageSize ?? 25,
      })) as Paged<T> & Record<string, unknown>;

      if (cancelled) return;

      if (!response.ok) {
        setState((prev) => ({ ...prev, loading: false, error: response.error, rows: [], total: 0 }));
        return;
      }

      const { rows, total, page: current, pageSize, ok, ...extra } = response;

      setState({
        rows: rows ?? [],
        total: total ?? 0,
        page: current ?? page,
        pageSize: pageSize ?? options?.pageSize ?? 25,
        loading: false,
        extra: extra as Record<string, unknown>,
      });
    };

    const timer = window.setTimeout(run, debounce);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [endpoint, serialized, page, nonce, options?.pageSize, options?.debounceMs]);

  const reload = useCallback(() => setNonce((value) => value + 1), []);

  return { ...state, page, setPage, reload };
}

export default usePagedQuery;
