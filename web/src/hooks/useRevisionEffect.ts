import { useEffect, useRef } from 'react';

/**
 * Ricarica mirata su invalidazione (correzione del bug L4, lato UI).
 * ---------------------------------------------------------------------------
 * Il server non trasmette piu' l'intero database a ogni modifica: manda
 * `mdt:invalidate` con lo scope toccato, il provider incrementa
 * `revision[scope]` e ogni pagina ricarica SOLO la propria vista.
 *
 * Il primo render e' escluso di proposito: la query iniziale la fa gia'
 * `usePagedQuery` (o l'effetto di caricamento della scheda), quindi eseguire
 * `run` anche al montaggio significherebbe chiedere due volte la stessa pagina.
 *
 * @param revisions contatori da osservare, es. `[revision.citizen, revision.wanted]`
 * @param run       che cosa rieseguire quando uno di quei contatori cambia
 */
export function useRevisionEffect(revisions: number[], run: () => void): void {
  const saved = useRef(run);
  const mounted = useRef(false);

  // I contatori sono numeri: la stringa unita e' un confronto per valore, quindi
  // un array nuovo a ogni render non fa scattare l'effetto.
  const key = revisions.join(':');

  useEffect(() => {
    saved.current = run;
  }, [run]);

  useEffect(() => {
    if (!mounted.current) {
      mounted.current = true;
      return;
    }

    saved.current();
  }, [key]);
}

export default useRevisionEffect;
