import { useCallback, useEffect, useMemo, useState } from 'react';
import Sheet, { Panel, SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column } from '../components/DataTable';
import Avatar from '../components/Avatar';
import { IconButton } from '../components/Button';
import Chip from '../components/Chip';
import { ConfirmDialog } from '../components/Modal';
import { callMdt } from '../lib/nui';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { dateTime, duration, fullName, num } from '../lib/format';
import type { JailRow } from '../lib/types';

/**
 * Detenuti.
 * ---------------------------------------------------------------------------
 * Il tempo residuo lo scala il server (che decide se contare anche chi e'
 * offline): qui non viene mai estrapolato. Per non mostrare un valore vecchio la
 * pagina si rilegge da sola ogni 15 secondi mentre e' aperta, oltre che quando
 * il server invalida lo scope `jail`.
 */

const RELOAD_EVERY_MS = 15000;

/** Solo i campi delle celle che servono all'interfaccia. */
interface CellInfo {
  id: string;
  label?: string;
  capacity?: number;
}

export function JailPage(): JSX.Element {
  const { openCitizen, notify, revision, can } = useMdt();

  const [rows, setRows] = useState<JailRow[]>([]);
  const [cells, setCells] = useState<CellInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [releasing, setReleasing] = useState<JailRow | null>(null);

  const load = useCallback(async () => {
    const response = await callMdt('jail:list');
    const payload = response as { rows?: JailRow[]; cells?: CellInfo[] };

    setRows(response.ok ? (payload.rows ?? []) : []);
    setCells(response.ok ? (payload.cells ?? []) : []);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  useRevisionEffect([revision.jail], () => void load());

  // Rilettura periodica: il conto alla rovescia vive sul server.
  useEffect(() => {
    const timer = window.setInterval(() => void load(), RELOAD_EVERY_MS);
    return () => window.clearInterval(timer);
  }, [load]);

  const occupancy = useMemo(() => {
    const used = new Map<string, number>();

    for (const row of rows) {
      if (row.cell) used.set(row.cell, (used.get(row.cell) ?? 0) + 1);
    }

    return used;
  }, [rows]);

  const release = async () => {
    if (!releasing) return;

    const response = await callMdt('jail:release', { identifier: releasing.identifier });
    setReleasing(null);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) void load();
  };

  const columns: Column<JailRow>[] = [
    {
      key: 'avatar',
      header: '',
      width: '2.75rem',
      render: (row) => (
        <Avatar src={row.mugshot} firstName={row.firstName} lastName={row.lastName} size="row" />
      ),
    },
    {
      key: 'name',
      header: 'Detenuto',
      flex: 1.4,
      render: (row) => (
        <>
          <span className="min-w-0 truncate font-semibold text-fg-strong">{fullName(row)}</span>
          {row.online ? null : <Chip label="Offline" icon="signal" tone="neutral" />}
        </>
      ),
    },
    {
      key: 'remaining',
      header: 'Residuo',
      flex: 0.9,
      render: (row) => (
        <span className="num font-semibold text-warning">{duration(row.secondsRemaining)}</span>
      ),
    },
    {
      key: 'reason',
      header: 'Motivo',
      flex: 1.8,
      render: (row) => <span className="truncate">{row.reason ?? '-'}</span>,
    },
    {
      key: 'cell',
      header: 'Cella',
      width: '4.5rem',
      render: (row) => <span className="num text-fg-muted">{row.cell ?? '-'}</span>,
    },
    {
      key: 'officer',
      header: 'Disposto da',
      flex: 1.2,
      render: (row) => <span className="truncate text-fg-muted">{row.officer ?? '-'}</span>,
    },
    {
      key: 'at',
      header: 'Ingresso',
      flex: 1.1,
      render: (row) => <span className="num truncate text-fg-muted">{dateTime(row.jailedAt)}</span>,
    },
    {
      key: 'actions',
      header: 'Azioni',
      width: can('jail.release') ? '6rem' : '3.5rem',
      align: 'right',
      render: (row) => (
        <>
          {can('jail.release') ? (
            <IconButton
              icon="confirm"
              variant="warning"
              title="Rilascia il detenuto"
              onClick={() => setReleasing(row)}
            />
          ) : null}

          <OpenCell
            title={`Apri il fascicolo di ${fullName(row)}`}
            onClick={() => openCitizen(row.identifier, fullName(row))}
          />
        </>
      ),
    },
  ];

  return (
    <Sheet>
      <SheetHeader
        title="Detenuti"
        count={num(rows.length)}
        action={{ icon: 'refresh', title: 'Ricarica', onClick: () => void load() }}
        extra={
          cells.length > 0 ? (
            <span className="num shrink-0 text-status text-fg-muted">
              {num(cells.length - occupancy.size)} celle libere su {num(cells.length)}
            </span>
          ) : null
        }
      />

      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(row) => row.identifier}
        loading={loading}
        onRowClick={(row) => openCitizen(row.identifier, fullName(row))}
        emptyTitle="Nessun detenuto"
        emptyHint="Il carcere e vuoto."
      />

      {cells.length > 0 ? (
        <div className="shrink-0 border-t border-line-soft px-4 py-3">
          <Panel title="Occupazione celle" icon="jail">
            <div className="flex flex-wrap gap-2">
              {cells.map((cell) => {
                const used = occupancy.get(cell.id) ?? 0;
                const capacity = cell.capacity ?? 1;

                return (
                  <Chip
                    key={cell.id}
                    label={`${cell.label ?? cell.id}: ${num(used)} / ${num(capacity)}`}
                    icon={used > 0 ? 'jail' : 'locked'}
                    tone={used >= capacity ? 'critical' : used > 0 ? 'warning' : 'neutral'}
                  />
                );
              })}
            </div>
          </Panel>
        </div>
      ) : null}

      <ConfirmDialog
        open={releasing !== null}
        title="Rilascia il detenuto"
        message={
          releasing
            ? `${fullName(releasing)} viene rilasciato subito, con ${duration(releasing.secondsRemaining)} ancora da scontare.`
            : ''
        }
        confirmLabel="Rilascia"
        onConfirm={() => void release()}
        onCancel={() => setReleasing(null)}
      />
    </Sheet>
  );
}

export default JailPage;
