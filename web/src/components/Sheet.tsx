import { useEffect, useRef, useState, type ReactNode } from 'react';
import Icon from './Icon';
import { IconButton } from './Button';
import { TextField } from './Field';
import SegmentedControl, { type Segment } from './SegmentedControl';

/**
 * Il "foglio" del fascicolo e la sua intestazione (sezione 3.7).
 *
 * L'angolo in alto a sinistra e' quadrato perche' li' si innesta la linguetta:
 * border-radius 0 md md md.
 */

export function Sheet({ children }: { children: ReactNode }): JSX.Element {
  return (
    <section className="mx-4 flex min-h-0 flex-1 flex-col overflow-hidden rounded-b-md rounded-tr-md border border-line bg-sheet">
      {children}
    </section>
  );
}

/**
 * Larghezza dell'elemento in rem.
 * Serve a decidere il collasso del controllo segmentato: la soglia del piano
 * ("sotto 1100 px logici") viene misurata sullo spazio davvero disponibile per
 * l'intestazione, non sulla finestra, perche' la sidebar espansa o compressa
 * cambia quello spazio a parita' di larghezza del tablet.
 */
function useWidthRem(ref: React.RefObject<HTMLElement>): number {
  const [widthRem, setWidthRem] = useState(999);

  useEffect(() => {
    const element = ref.current;
    if (!element) return undefined;

    const measure = () => {
      const root = Number.parseFloat(getComputedStyle(document.documentElement).fontSize || '16');
      setWidthRem(element.clientWidth / (Number.isFinite(root) && root > 0 ? root : 16));
    };

    const observer = new ResizeObserver(measure);
    observer.observe(element);
    measure();

    return () => observer.disconnect();
  }, [ref]);

  return widthRem;
}

/** 1100 px logici totali, meno sidebar e margini, sull'area dell'intestazione. */
const COLLAPSE_SEGMENTS_BELOW_REM = 54;

interface SheetHeaderProps<T extends string> {
  title: string;
  /** Contatore in font numerico, es. "8 - 1 ricercato". */
  count?: string;
  segments?: Segment<T>[];
  segmentValue?: T;
  onSegmentChange?: (value: T) => void;
  search?: string;
  onSearch?: (value: string) => void;
  searchPlaceholder?: string;
  /** Azione principale a destra (pulsante icona 2.3rem). */
  action?: { icon: 'add' | 'save' | 'refresh' | 'edit'; title: string; onClick: () => void };
  extra?: ReactNode;
}

/**
 * Intestazione del foglio - correzione richiesta n. 2 del piano.
 * ---------------------------------------------------------------------------
 * Riga singola che non va mai a capo, ad alcuna larghezza:
 *   - `flex-nowrap` sul contenitore e altezza fissa 3.5rem;
 *   - il titolo e' l'unico elemento che si comprime (`min-w-0` + `truncate`);
 *   - il campo di ricerca e' largo 14rem, non elastico;
 *   - il badge CTRL K non sta dentro al campo: e' un tooltip;
 *   - sotto la soglia il controllo segmentato diventa solo icone.
 */
export function SheetHeader<T extends string>({
  title,
  count,
  segments,
  segmentValue,
  onSegmentChange,
  search,
  onSearch,
  searchPlaceholder,
  action,
  extra,
}: SheetHeaderProps<T>): JSX.Element {
  const headerRef = useRef<HTMLDivElement>(null);
  const widthRem = useWidthRem(headerRef);
  const searchRef = useRef<HTMLDivElement>(null);

  // CTRL K mette il fuoco sulla ricerca. Listener in useEffect con cleanup:
  // mai nel corpo del render (bug U1).
  useEffect(() => {
    if (!onSearch) return undefined;

    const onKeyDown = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        searchRef.current?.querySelector('input')?.focus();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onSearch]);

  return (
    <header
      ref={headerRef}
      className="flex h-sheethead shrink-0 flex-nowrap items-center gap-[0.8rem] border-b border-dashed border-line-perf px-4"
    >
      {/* Unico elemento comprimibile */}
      <div className="flex min-w-0 items-baseline gap-[0.55rem] overflow-hidden">
        <h3 className="truncate text-section font-bold tracking-[-0.01em] text-fg-strong">{title}</h3>
        {count ? <span className="num whitespace-nowrap text-status font-medium text-fg-muted">{count}</span> : null}
      </div>

      <span className="flex-1" />

      {extra}

      {segments && segmentValue !== undefined && onSegmentChange ? (
        <SegmentedControl
          value={segmentValue}
          segments={segments}
          onChange={onSegmentChange}
          iconOnly={widthRem < COLLAPSE_SEGMENTS_BELOW_REM}
        />
      ) : null}

      {onSearch ? (
        <div ref={searchRef} className="w-search shrink-0" title="CTRL K per cercare">
          <TextField
            value={search ?? ''}
            onChange={onSearch}
            icon="search"
            placeholder={searchPlaceholder ?? 'Cerca...'}
          />
        </div>
      ) : null}

      {action ? <IconButton icon={action.icon} title={action.title} onClick={action.onClick} /> : null}
    </header>
  );
}

/** Corpo scorrevole per le schede di dettaglio (non tabellari). */
export function SheetBody({ children }: { children: ReactNode }): JSX.Element {
  return <div className="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-4 py-4">{children}</div>;
}

/** Pannello: intestazione bg-raised + contenuto. Usato nelle schede. */
export function Panel({
  title,
  icon,
  action,
  children,
}: {
  title: string;
  icon?: Parameters<typeof Icon>[0]['name'];
  action?: ReactNode;
  children: ReactNode;
}): JSX.Element {
  return (
    <div className="flex flex-col overflow-hidden rounded-md border border-line">
      <div className="flex h-thead shrink-0 items-center gap-2 border-b border-line-perf bg-raised px-3">
        {icon ? (
          <span className="text-fg-head">
            <Icon name={icon} size="lg" />
          </span>
        ) : null}
        <span className="min-w-0 flex-1 truncate text-label font-bold uppercase tracking-[0.1em] text-fg-head">
          {title}
        </span>
        {action}
      </div>
      <div className="flex flex-col gap-2 px-3 py-3">{children}</div>
    </div>
  );
}

/** Coppia etichetta / valore, allineata come nel fascicolo. */
export function DataRow({
  label,
  value,
  numeric,
}: {
  label: string;
  value: ReactNode;
  numeric?: boolean;
}): JSX.Element {
  return (
    <div className="flex items-baseline gap-3">
      <span className="w-[9rem] shrink-0 text-label font-semibold uppercase tracking-[0.08em] text-fg-dim">
        {label}
      </span>
      <span className={['min-w-0 flex-1 break-words text-data text-fg', numeric ? 'num' : ''].join(' ')}>
        {value ?? '-'}
      </span>
    </div>
  );
}

export default Sheet;
