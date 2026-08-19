import { useCallback, useEffect, useMemo, useState } from 'react';
import Sheet, { SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column } from '../components/DataTable';
import Avatar from '../components/Avatar';
import Button from '../components/Button';
import Chip from '../components/Chip';
import type { Segment } from '../components/SegmentedControl';
import { callMdt } from '../lib/nui';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { duration, fullName, num } from '../lib/format';
import type { RosterRow } from '../lib/types';

/**
 * Servizio: organico, gradi, stato di servizio e monte ore.
 * ---------------------------------------------------------------------------
 * CORREZIONE BUG U9
 * ---------------------------------------------------------------------------
 * La vecchia AgentManagement era uno stub: rendeva un titolo e niente altro.
 * Qui il roster arriva da `duty:roster`, che calcola le ore degli ultimi 30
 * giorni da `kf_police_duty_log` includendo la sessione ancora aperta.
 */

type DutyFilter = 'all' | 'onduty' | 'online';

const SEGMENTS: Segment<DutyFilter>[] = [
  { value: 'all', label: 'Tutti', icon: 'roster' },
  { value: 'onduty', label: 'In servizio', icon: 'duty' },
  { value: 'online', label: 'Connessi', icon: 'signal' },
];

export function DutyPage(): JSX.Element {
  const { openCitizen, notify, revision, officer, can } = useMdt();

  const [rows, setRows] = useState<RosterRow[]>([]);
  const [onDutyCount, setOnDutyCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<DutyFilter>('all');
  const [search, setSearch] = useState('');
  const [toggling, setToggling] = useState(false);

  const load = useCallback(async () => {
    const response = await callMdt('duty:roster');
    const payload = response as { rows?: RosterRow[]; onDuty?: number };

    setRows(response.ok ? (payload.rows ?? []) : []);
    setOnDutyCount(response.ok ? (payload.onDuty ?? 0) : 0);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  useRevisionEffect([revision.roster], () => void load());

  const toggleDuty = async () => {
    setToggling(true);

    const response = await callMdt('duty:toggle');
    setToggling(false);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    // Lo stato dell'agente arriva anche da `mdt:duty`, che aggiorna la barra di
    // stato: qui serve solo rileggere l'organico.
    if (response.ok) void load();
  };

  // Filtro e ricerca in locale: l'organico di un reparto sono decine di righe,
  // non migliaia, e arriva in una sola risposta.
  const visible = useMemo(() => {
    const needle = search.trim().toLowerCase();

    return rows.filter((row) => {
      if (filter === 'onduty' && !row.onDuty) return false;
      if (filter === 'online' && !row.online) return false;

      if (!needle) return true;

      return (
        fullName(row).toLowerCase().includes(needle) ||
        (row.ssn ?? '').toLowerCase().includes(needle) ||
        row.gradeLabel.toLowerCase().includes(needle)
      );
    });
  }, [rows, filter, search]);

  const columns: Column<RosterRow>[] = [
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
      header: 'Agente',
      flex: 1.5,
      render: (row) => (
        <>
          <span className="min-w-0 truncate font-semibold text-fg-strong">{fullName(row)}</span>
          {row.identifier === officer?.identifier ? <Chip label="Tu" tone="info" /> : null}
        </>
      ),
    },
    {
      key: 'grade',
      header: 'Grado',
      flex: 1.3,
      render: (row) => (
        <>
          <span className="truncate">{row.gradeLabel}</span>
          <span className="num shrink-0 text-label text-fg-dim">#{row.grade}</span>
        </>
      ),
    },
    {
      key: 'duty',
      header: 'Servizio',
      flex: 1,
      render: (row) => (
        <span
          className={[
            'flex items-center gap-2 text-status font-semibold',
            row.onDuty ? 'text-success' : 'text-fg-dim',
          ].join(' ')}
        >
          <span
            className={['h-[0.45rem] w-[0.45rem] rounded-dot', row.onDuty ? 'bg-success' : 'bg-fg-dim'].join(
              ' ',
            )}
          />
          {row.onDuty ? 'In servizio' : 'Fuori servizio'}
        </span>
      ),
    },
    {
      key: 'online',
      header: 'Stato',
      flex: 0.8,
      render: (row) =>
        row.online ? (
          <Chip label="Connesso" icon="signal" tone="success" />
        ) : (
          <span className="text-label text-fg-dim">Offline</span>
        ),
    },
    {
      key: 'hours',
      header: 'Ore (30 gg)',
      flex: 0.9,
      align: 'right',
      render: (row) => <span className="num text-fg">{duration(row.secondsThisMonth)}</span>,
    },
    {
      key: 'open',
      header: 'Apri',
      width: '3.5rem',
      align: 'right',
      render: (row) => (
        <OpenCell
          title={`Apri il fascicolo di ${fullName(row)}`}
          onClick={() => openCitizen(row.identifier, fullName(row))}
        />
      ),
    },
  ];

  return (
    <Sheet>
      <SheetHeader
        title="Servizio"
        count={`${num(rows.length)} - ${num(onDutyCount)} in servizio`}
        segments={SEGMENTS}
        segmentValue={filter}
        onSegmentChange={(value: DutyFilter) => setFilter(value)}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Agente o grado..."
        action={{ icon: 'refresh', title: 'Ricarica', onClick: () => void load() }}
        extra={
          can('duty.toggle') ? (
            <Button
              variant={officer?.onDuty ? 'warning' : 'primary'}
              icon="duty"
              disabled={toggling}
              onClick={() => void toggleDuty()}
            >
              {officer?.onDuty ? 'Smonta' : 'Monta'}
            </Button>
          ) : null
        }
      />

      <DataTable
        columns={columns}
        rows={visible}
        rowKey={(row) => row.identifier}
        loading={loading}
        onRowClick={(row) => openCitizen(row.identifier, fullName(row))}
        emptyTitle="Nessun agente"
        emptyHint={
          search
            ? 'Nessun risultato per questa ricerca.'
            : filter === 'onduty'
              ? 'Nessuno e in servizio in questo momento.'
              : filter === 'online'
                ? 'Nessun collega connesso.'
                : undefined
        }
      />
    </Sheet>
  );
}

export default DutyPage;
