import type { IconKey } from '../components/Icon';
import type { PageKey } from '../lib/types';

/**
 * Registro delle pagine: solo metadati (etichetta, icona, gruppo, permesso).
 * I componenti sono associati in App.tsx, così questo file non crea cicli di
 * import con il provider di stato.
 *
 * `group` corrisponde alle etichette di gruppo della sidebar del mockup:
 * "Archivio" e "Operativo".
 */

export type PageGroup = 'archivio' | 'operativo';

export interface PageDefinition {
  label: string;
  icon: IconKey;
  group: PageGroup;
  /** Permesso minimo per vedere la voce. Il server rifiuta comunque. */
  permission: string;
  /** Chiave del contatore mostrato come badge, se previsto. */
  badge?: 'wanted' | 'jail' | 'reports' | 'duty';
  /** Il badge dei detenuti e' giallo, non rosso (mockup). */
  badgeTone?: 'accent' | 'warning';
}

export const PAGES: Record<PageKey, PageDefinition> = {
  citizens: {
    label: 'Anagrafica',
    icon: 'citizens',
    group: 'archivio',
    permission: 'mdt.citizen.view',
  },
  vehicles: {
    label: 'Veicoli',
    icon: 'vehicles',
    group: 'archivio',
    permission: 'mdt.vehicle.view',
  },
  reports: {
    label: 'Rapporti',
    icon: 'reports',
    group: 'archivio',
    permission: 'mdt.view',
    badge: 'reports',
  },
  penalcode: {
    label: 'Codice Penale',
    icon: 'penalcode',
    group: 'archivio',
    permission: 'mdt.view',
  },
  wanted: {
    label: 'Ricercati',
    icon: 'wanted',
    group: 'operativo',
    permission: 'mdt.citizen.view',
    badge: 'wanted',
  },
  jail: {
    label: 'Detenuti',
    icon: 'jail',
    group: 'operativo',
    permission: 'mdt.jail.view',
    badge: 'jail',
    badgeTone: 'warning',
  },
  radio: {
    label: 'Radio',
    icon: 'radio',
    group: 'operativo',
    permission: 'radio.use',
  },
  duty: {
    label: 'Servizio',
    icon: 'duty',
    group: 'operativo',
    permission: 'mdt.view',
  },
};

export const GROUP_LABELS: Record<PageGroup, string> = {
  archivio: 'Archivio',
  operativo: 'Operativo',
};

export const GROUP_ORDER: PageGroup[] = ['archivio', 'operativo'];
