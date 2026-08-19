import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import Icon from './Icon';
import { SkeletonRows } from './Skeleton';
import EmptyState from './EmptyState';
import Pagination from './Pagination';

/**
 * Tabella del design system - riscrittura completa (sezione 3.7).
 * ---------------------------------------------------------------------------
 * Differenze rispetto alla versione precedente:
 *  - l'altezza NON e' piu' fissa (App.css aveva `height: 200px` per tutte le
 *    tabelle, bug U6): il corpo occupa lo spazio residuo con flex-1 e scorre;
 *  - a una cella non si applica mai `width` insieme a `flex` (bug U11): le due
 *    cose sono mutuamente esclusive per costruzione;
 *  - ordinamento per colonna, paginazione, stato vuoto, scheletro di
 *    caricamento e virtualizzazione oltre 100 righe.
 */

export interface Column<T> {
  key: string;
  header: string;
  /** Colonna proporzionale. Mutuamente esclusiva con `width`. */
  flex?: number;
  /** Colonna a larghezza fissa (es. '2.75rem'). Mutuamente esclusiva con `flex`. */
  width?: string;
  align?: 'left' | 'right';
  sortable?: boolean;
  render: (row: T) => ReactNode;
}

export type SortDirection = 'asc' | 'desc';

interface DataTableProps<T> {
  columns: Column<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  loading?: boolean;
  onRowClick?: (row: T) => void;
  emptyTitle?: string;
  emptyHint?: string;
  sortBy?: string;
  sortDir?: SortDirection;
  onSort?: (key: string, direction: SortDirection) => void;
  page?: number;
  pageSize?: number;
  total?: number;
  onPage?: (page: number) => void;
}

/** Soglia oltre la quale si passa al rendering a finestra. */
const VIRTUALIZE_ABOVE = 100;
const OVERSCAN = 6;

/** Altezza di riga in pixel, ricavata dal font-size della radice (3.4rem). */
function useRowHeightPx(): number {
  const [height, setHeight] = useState(() => rowHeightFromRoot());

  useEffect(() => {
    const update = () => setHeight(rowHeightFromRoot());

    // La radice cambia quando cambia la risoluzione (useTabletScale).
    const observer = new MutationObserver(update);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['style'] });

    window.addEventListener('resize', update);

    return () => {
      observer.disconnect();
      window.removeEventListener('resize', update);
    };
  }, []);

  return height;
}

function rowHeightFromRoot(): number {
  const root = Number.parseFloat(getComputedStyle(document.documentElement).fontSize || '16');
  return (Number.isFinite(root) ? root : 16) * 3.4;
}

/** Stile della cella: `width` e `flex` non convivono mai (bug U11). */
function cellStyle<T>(column: Column<T>): React.CSSProperties {
  if (column.width) {
    return { width: column.width, flexShrink: 0 };
  }

  return { flex: column.flex ?? 1, minWidth: 0 };
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  loading,
  onRowClick,
  emptyTitle = 'Nessun risultato',
  emptyHint,
  sortBy,
  sortDir = 'asc',
  onSort,
  page,
  pageSize,
  total,
  onPage,
}: DataTableProps<T>): JSX.Element {
  const bodyRef = useRef<HTMLDivElement>(null);
  const rowHeight = useRowHeightPx();
  const [scrollTop, setScrollTop] = useState(0);
  const [viewportHeight, setViewportHeight] = useState(0);

  const virtualize = rows.length > VIRTUALIZE_ABOVE;

  const onScroll = useCallback(() => {
    if (bodyRef.current) {
      setScrollTop(bodyRef.current.scrollTop);
    }
  }, []);

  useEffect(() => {
    const element = bodyRef.current;
    if (!element) return undefined;

    const observer = new ResizeObserver(() => setViewportHeight(element.clientHeight));
    observer.observe(element);
    setViewportHeight(element.clientHeight);

    return () => observer.disconnect();
  }, []);

  // Torna in cima quando cambiano i dati: la pagina 2 non deve aprirsi a metà.
  useEffect(() => {
    if (bodyRef.current) {
      bodyRef.current.scrollTop = 0;
      setScrollTop(0);
    }
  }, [page, rows.length]);

  const window_ = useMemo(() => {
    if (!virtualize || rowHeight <= 0) {
      return { start: 0, end: rows.length, padTop: 0, padBottom: 0 };
    }

    const visible = Math.ceil((viewportHeight || rowHeight * 10) / rowHeight);
    const start = Math.max(0, Math.floor(scrollTop / rowHeight) - OVERSCAN);
    const end = Math.min(rows.length, start + visible + OVERSCAN * 2);

    return {
      start,
      end,
      padTop: start * rowHeight,
      padBottom: Math.max(0, (rows.length - end) * rowHeight),
    };
  }, [virtualize, rowHeight, viewportHeight, scrollTop, rows.length]);

  const handleSort = (column: Column<T>) => {
    if (!column.sortable || !onSort) return;

    const nextDirection: SortDirection = sortBy === column.key && sortDir === 'asc' ? 'desc' : 'asc';
    onSort(column.key, nextDirection);
  };

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {/* Intestazione */}
      <div className="flex h-thead shrink-0 items-center gap-3 border-b border-line-perf bg-raised px-4">
        {columns.map((column) => {
          const sorted = sortBy === column.key;

          return (
            <button
              key={column.key}
              type="button"
              disabled={!column.sortable || !onSort}
              onClick={() => handleSort(column)}
              style={cellStyle(column)}
              className={[
                'flex items-center gap-1.5 truncate text-label font-bold uppercase tracking-[0.1em]',
                column.align === 'right' ? 'justify-end' : 'justify-start',
                sorted ? 'text-fg-strong' : 'text-fg-head',
                column.sortable && onSort ? 'hover:text-fg-strong' : 'cursor-default',
              ].join(' ')}
            >
              <span className="truncate">{column.header}</span>
              {column.sortable && onSort ? (
                <Icon name={sorted ? (sortDir === 'asc' ? 'sortAsc' : 'sortDesc') : 'sort'} size="xs" />
              ) : null}
            </button>
          );
        })}
      </div>

      {/* Corpo: flex-1 + overflow, nessuna altezza fissa */}
      <div ref={bodyRef} onScroll={onScroll} className="min-h-0 flex-1 overflow-y-auto">
        {loading ? (
          <SkeletonRows rows={8} />
        ) : rows.length === 0 ? (
          <EmptyState title={emptyTitle} hint={emptyHint} />
        ) : (
          <>
            {window_.padTop > 0 ? <div style={{ height: window_.padTop }} /> : null}

            {rows.slice(window_.start, window_.end).map((row) => (
              <div
                key={rowKey(row)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={[
                  'flex h-row items-center gap-3 border-b border-line-soft px-4 text-data',
                  onRowClick ? 'cursor-pointer hover:bg-hover' : '',
                ].join(' ')}
              >
                {columns.map((column) => (
                  <div
                    key={column.key}
                    style={cellStyle(column)}
                    className={[
                      'flex min-w-0 items-center gap-2',
                      column.align === 'right' ? 'justify-end' : 'justify-start',
                    ].join(' ')}
                  >
                    {column.render(row)}
                  </div>
                ))}
              </div>
            ))}

            {window_.padBottom > 0 ? <div style={{ height: window_.padBottom }} /> : null}
          </>
        )}
      </div>

      {page && pageSize && total && onPage ? (
        <Pagination page={page} pageSize={pageSize} total={total} onChange={onPage} />
      ) : null}
    </div>
  );
}

/** Pulsante "apri" in coda alla riga (chevron), 2.25rem quadrato. */
export function OpenCell({ onClick, title }: { onClick?: () => void; title?: string }): JSX.Element {
  return (
    <button
      type="button"
      title={title ?? 'Apri'}
      onClick={
        onClick
          ? (event) => {
              event.stopPropagation();
              onClick();
            }
          : undefined
      }
      className="flex h-target w-target items-center justify-center rounded-sm border border-line-ctrl bg-control text-info hover:brightness-125"
    >
      <Icon name="open" size="md" />
    </button>
  );
}

export default DataTable;
