import { useState } from 'react';
import Sheet, { SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column, type SortDirection } from '../components/DataTable';
import Chip from '../components/Chip';
import type { Segment } from '../components/SegmentedControl';
import { usePagedQuery } from '../hooks/usePagedQuery';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { num } from '../lib/format';
import type { VehicleRow } from '../lib/types';

/**
 * Archivio veicoli.
 * I flag (rubato, sequestrato, BOLO) arrivano da `kf_police_vehicle_flags`:
 * sopravvivono al restart, non sono piu' una tabella in RAM (bug L3).
 */

type VehicleFilter = 'all' | 'stolen' | 'impounded' | 'bolo';

const SEGMENTS: Segment<VehicleFilter>[] = [
  { value: 'all', label: 'Tutti', icon: 'vehicles' },
  { value: 'stolen', label: 'Rubati', icon: 'warning' },
  { value: 'impounded', label: 'Sequestrati', icon: 'impound' },
  { value: 'bolo', label: 'BOLO', icon: 'wanted' },
];

export function VehiclesPage(): JSX.Element {
  const { openVehicle, openCitizen, revision, pageSize } = useMdt();

  const [filter, setFilter] = useState<VehicleFilter>('all');
  const [search, setSearch] = useState('');
  // Chiavi ammesse dalla lista bianca di server/sv_vehicles.lua.
  const [sortBy, setSortBy] = useState('plate');
  const [sortDir, setSortDir] = useState<SortDirection>('asc');

  const query = usePagedQuery<VehicleRow>(
    'vehicles:search',
    { query: search, filter, sortBy, sortDir },
    { pageSize, debounceMs: 220 },
  );

  useRevisionEffect([revision.vehicles], query.reload);

  const columns: Column<VehicleRow>[] = [
    {
      key: 'plate',
      header: 'Targa',
      flex: 1,
      sortable: true,
      render: (row) => <span className="num truncate font-semibold text-fg-strong">{row.plate}</span>,
    },
    {
      key: 'model',
      header: 'Modello',
      flex: 1.2,
      render: (row) => <span className="truncate">{row.model}</span>,
    },
    {
      key: 'owner',
      header: 'Proprietario',
      flex: 1.5,
      sortable: true,
      render: (row) =>
        row.owner ? (
          <button
            type="button"
            title="Apri il fascicolo del proprietario"
            onClick={(event) => {
              event.stopPropagation();
              openCitizen(row.owner as string, row.ownerName);
            }}
            className="min-w-0 truncate text-left text-info hover:brightness-125"
          >
            {row.ownerName ?? 'Sconosciuto'}
          </button>
        ) : (
          <span className="truncate text-fg-muted">Sconosciuto</span>
        ),
    },
    {
      key: 'type',
      header: 'Tipo',
      flex: 0.7,
      sortable: true,
      render: (row) => <span className="truncate text-fg-muted">{row.type}</span>,
    },
    {
      key: 'flags',
      header: 'Stato',
      flex: 1.6,
      render: (row) => (
        <span className="flex min-w-0 items-center gap-2 overflow-hidden">
          {row.isStolen ? <Chip label="Rubato" icon="warning" tone="critical" /> : null}
          {row.isImpounded ? <Chip label="Sequestrato" icon="impound" tone="warning" /> : null}
          {row.hasBolo ? <Chip label="BOLO" icon="wanted" tone="critical" /> : null}
          {row.stored ? <Chip label="In garage" icon="locked" tone="neutral" /> : null}
          {!row.isStolen && !row.isImpounded && !row.hasBolo && !row.stored ? (
            <span className="text-label text-fg-dim">Regolare</span>
          ) : null}
        </span>
      ),
    },
    {
      key: 'open',
      header: 'Apri',
      width: '3.5rem',
      align: 'right',
      render: (row) => (
        <OpenCell title={`Apri la scheda di ${row.plate}`} onClick={() => openVehicle(row.plate)} />
      ),
    },
  ];

  return (
    <Sheet>
      <SheetHeader
        title="Archivio veicoli"
        count={num(query.total)}
        segments={SEGMENTS}
        segmentValue={filter}
        onSegmentChange={(value: VehicleFilter) => setFilter(value)}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Targa o proprietario..."
        action={{ icon: 'refresh', title: 'Ricarica', onClick: query.reload }}
      />

      <DataTable
        columns={columns}
        rows={query.rows}
        rowKey={(row) => row.plate}
        loading={query.loading}
        onRowClick={(row) => openVehicle(row.plate)}
        emptyTitle="Nessun veicolo"
        emptyHint={search ? 'Nessun risultato per questa ricerca.' : undefined}
        sortBy={sortBy}
        sortDir={sortDir}
        onSort={(key, direction) => {
          setSortBy(key);
          setSortDir(direction);
        }}
        page={query.page}
        pageSize={query.pageSize}
        total={query.total}
        onPage={query.setPage}
      />
    </Sheet>
  );
}

export default VehiclesPage;
