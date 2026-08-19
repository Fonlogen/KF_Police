import { useState } from 'react';
import Sheet, { SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column } from '../components/DataTable';
import Chip from '../components/Chip';
import Icon from '../components/Icon';
import type { Segment } from '../components/SegmentedControl';
import { usePagedQuery } from '../hooks/usePagedQuery';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { dateTime, num, reportStatus } from '../lib/format';
import type { ReportRow, ReportStatus } from '../lib/types';

/**
 * Elenco dei rapporti.
 * I rapporti riservati li filtra il server in base al grado: qui non c'e' nessun
 * controllo di visibilita' da aggirare.
 */

type StatusFilter = 'all' | ReportStatus;

const SEGMENTS: Segment<StatusFilter>[] = [
  { value: 'all', label: 'Tutti', icon: 'list' },
  { value: 'open', label: 'Aperti', icon: 'reports' },
  { value: 'closed', label: 'Chiusi', icon: 'confirm' },
  { value: 'draft', label: 'Bozze', icon: 'edit' },
];

const TONE: Record<ReportStatus, 'warning' | 'success' | 'neutral'> = {
  open: 'warning',
  closed: 'success',
  draft: 'neutral',
};

export function ReportsPage(): JSX.Element {
  const { openReport, revision, pageSize, can } = useMdt();

  const [filter, setFilter] = useState<StatusFilter>('all');
  const [search, setSearch] = useState('');

  const query = usePagedQuery<ReportRow>(
    'reports:list',
    // Il server ignora uno status che non riconosce: "all" equivale a nessun
    // filtro, e resta una stringa vuota per non mandare rumore.
    { query: search, status: filter === 'all' ? '' : filter },
    { pageSize, debounceMs: 220 },
  );

  useRevisionEffect([revision.reports], query.reload);

  const columns: Column<ReportRow>[] = [
    {
      key: 'id',
      header: 'N.',
      width: '3.5rem',
      render: (row) => <span className="num truncate text-fg-dim">#{row.id}</span>,
    },
    {
      key: 'title',
      header: 'Titolo',
      flex: 2.4,
      render: (row) => (
        <>
          {row.isConfidential ? (
            <span className="shrink-0 text-warning" title="Rapporto riservato">
              <Icon name="locked" size="md" />
            </span>
          ) : null}

          <span className="truncate font-semibold text-fg-strong">{row.title}</span>

          {(row.tags ?? []).map((tag) => (
            <Chip key={tag.id} label={tag.label} icon={tag.icon} color={tag.color} />
          ))}
        </>
      ),
    },
    {
      key: 'officer',
      header: 'Agente',
      flex: 1.2,
      render: (row) => <span className="truncate">{row.officer ?? '-'}</span>,
    },
    {
      key: 'location',
      header: 'Luogo',
      flex: 1.1,
      render: (row) => <span className="truncate text-fg-muted">{row.location ?? '-'}</span>,
    },
    {
      key: 'involved',
      header: 'Coinvolti',
      width: '5rem',
      align: 'right',
      render: (row) => <span className="num text-fg-muted">{num(row.involvedCount ?? 0)}</span>,
    },
    {
      key: 'status',
      header: 'Stato',
      flex: 0.9,
      render: (row) => <Chip label={reportStatus(row.status)} tone={TONE[row.status] ?? 'neutral'} />,
    },
    {
      key: 'date',
      header: 'Data',
      flex: 1.1,
      render: (row) => <span className="num truncate text-fg-muted">{dateTime(row.date)}</span>,
    },
    {
      key: 'open',
      header: 'Apri',
      width: '3.5rem',
      align: 'right',
      render: (row) => (
        <OpenCell title={`Apri il rapporto numero ${row.id}`} onClick={() => openReport(row.id, row.title)} />
      ),
    },
  ];

  return (
    <Sheet>
      <SheetHeader
        title="Rapporti di servizio"
        count={num(query.total)}
        segments={SEGMENTS}
        segmentValue={filter}
        onSegmentChange={(value: StatusFilter) => setFilter(value)}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Titolo, agente o luogo..."
        action={
          can('mdt.report.create')
            ? { icon: 'add', title: 'Nuovo rapporto', onClick: () => openReport('new') }
            : { icon: 'refresh', title: 'Ricarica', onClick: query.reload }
        }
      />

      <DataTable
        columns={columns}
        rows={query.rows}
        rowKey={(row) => String(row.id)}
        loading={query.loading}
        onRowClick={(row) => openReport(row.id, row.title)}
        emptyTitle="Nessun rapporto"
        emptyHint={search ? 'Nessun risultato per questa ricerca.' : 'Non ci sono rapporti con questo stato.'}
        /* Nessun ordinamento per colonna: il server ordina sempre dal rapporto
           piu' recente e non accetta altre chiavi. Meglio nessun controllo che
           un controllo che non fa niente. */
        page={query.page}
        pageSize={query.pageSize}
        total={query.total}
        onPage={query.setPage}
      />
    </Sheet>
  );
}

export default ReportsPage;
