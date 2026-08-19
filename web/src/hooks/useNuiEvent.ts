import { useEffect, useRef } from 'react';

/**
 * Ascolto degli eventi inviati da SendNUIMessage.
 * Il listener e' registrato in useEffect con cleanup e l'handler passa da una
 * ref, così un handler nuovo a ogni render non ri-registra il listener.
 */
export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void): void {
  const saved = useRef(handler);

  useEffect(() => {
    saved.current = handler;
  }, [handler]);

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const payload = event.data as { action?: string; data?: T } | undefined;

      if (payload && payload.action === action) {
        saved.current(payload.data as T);
      }
    };

    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action]);
}

export default useNuiEvent;
