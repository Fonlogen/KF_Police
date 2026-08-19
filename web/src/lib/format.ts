/** Formattazione condivisa. Nessuna emoji, nessun carattere decorativo. */

/** Importi in valuta locale senza decimali. */
export function money(amount: number | undefined | null): string {
  const value = Number(amount ?? 0);
  return `$${value.toLocaleString('it-IT')}`;
}

/** Numeri con separatore di migliaia. */
export function num(value: number | undefined | null): string {
  return Number(value ?? 0).toLocaleString('it-IT');
}

/** Data SQL -> "gg/mm/aaaa hh:mm". Se non e' interpretabile, si mostra grezza. */
export function dateTime(value?: string | null): string {
  if (!value) return '-';

  const parsed = parseSql(value);
  if (!parsed) return value;

  return parsed.toLocaleString('it-IT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/** Solo la data. */
export function dateOnly(value?: string | null): string {
  if (!value) return '-';

  const parsed = parseSql(value);
  if (!parsed) return value;

  return parsed.toLocaleDateString('it-IT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

function parseSql(value: string): Date | null {
  // "2026-08-19 21:47:00" e la variante ISO con T.
  const normalized = value.includes('T') ? value : value.replace(' ', 'T');
  const parsed = new Date(normalized);

  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

/** Secondi -> "1h 05m" / "12m 30s" / "45s". */
export function duration(seconds: number | undefined | null): string {
  const total = Math.max(0, Math.floor(Number(seconds ?? 0)));

  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const rest = total % 60;

  if (hours > 0) return `${hours}h ${String(minutes).padStart(2, '0')}m`;
  if (minutes > 0) return `${minutes}m ${String(rest).padStart(2, '0')}s`;

  return `${rest}s`;
}

/** Mesi di condanna -> etichetta leggibile. */
export function months(value: number | undefined | null): string {
  const total = Number(value ?? 0);
  if (total <= 0) return '-';

  return total === 1 ? '1 mese' : `${num(total)} mesi`;
}

/** Nome completo. */
export function fullName(person: { firstName?: string; lastName?: string }): string {
  return `${person.firstName ?? ''} ${person.lastName ?? ''}`.trim() || 'Sconosciuto';
}

/** Iniziali per l'avatar di riserva. */
export function initials(person: { firstName?: string; lastName?: string }): string {
  const first = (person.firstName ?? '').charAt(0);
  const last = (person.lastName ?? '').charAt(0);

  return `${first}${last}`.toUpperCase() || '?';
}

/** Etichetta del contatore nell'intestazione del foglio (es. "8 - 1 ricercato"). */
export function countLabel(total: number, extra?: { count: number; singular: string; plural: string }): string {
  const base = num(total);

  if (!extra || extra.count <= 0) return base;

  return `${base} - ${num(extra.count)} ${extra.count === 1 ? extra.singular : extra.plural}`;
}

const STATUS_LABELS: Record<string, string> = {
  draft: 'Bozza',
  open: 'Aperto',
  closed: 'Chiuso',
};

export function reportStatus(status: string): string {
  return STATUS_LABELS[status] ?? status;
}

const ROLE_LABELS: Record<string, string> = {
  suspect: 'Sospettato',
  victim: 'Vittima',
  witness: 'Testimone',
};

export function involvedRole(role: string): string {
  return ROLE_LABELS[role] ?? role;
}
