import { useEffect } from 'react';
import type { Geometry } from '../lib/types';

/**
 * Scala dinamica del tablet (sezione 3.2 del piano).
 * ---------------------------------------------------------------------------
 * Il client calcola `rootFontSize` in funzione della larghezza reale del tablet
 * e la NUI la applica al font-size della radice. Siccome tutte le misure dei
 * componenti sono in rem, a 1920x1080, 2560x1440 e 3840x2160 il testo ha la
 * stessa dimensione apparente.
 */
export function useTabletScale(geometry: Geometry | null): void {
  useEffect(() => {
    if (!geometry?.rootFontSize) return;

    document.documentElement.style.fontSize = `${geometry.rootFontSize}px`;
  }, [geometry?.rootFontSize]);
}

export default useTabletScale;
