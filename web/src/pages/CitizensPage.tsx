import { useState } from 'react';
import Sheet, { SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column, type SortDirection } from '../components/DataTable';
import Avatar from '../components/Avatar';
import Stamp from '../components/Stamp';
import type { Segment } from '../components/SegmentedControl';
import { usePagedQuery } from '../hooks/usePagedQuery';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { countLabel, duration, fullName } from '../lib/format';
import type { CitizenRow } from '../lib/types';

/**
 * Anagrafica cittadini.
 * ---------------------------------------------------------------------------
 * E' la schermata riprodotta nel mockup approvato
 * (.claude/plans/assets/mockup-casefile-v4.html): le proporzioni delle colonne
 * sono prese da li' e non vanno cambiate senza aggiornare il mockup.
 *
 *   avatar 2.75rem fisso | nome 1.15 | cognome 1.4 | cittadinanza 1 |
 *   impiego 1.3 | apri 3.5rem fisso
 *
 * La ricerca e' SQL e paginata lato server: qui non arriva mai l'elenco
 * completo dei cittadini (bug L4).
 */

type CitizenFilter = 'all' | 'wanted' | 'jailed';

const SEGMENTS: Segment<CitizenFilter>[] = [
  { value: 'all', label: 'Tutti', icon: 'citizens' },
  { value: 'wanted', label: 'Ricercati', icon: 'wanted' },
  { value: 'jailed', label: 'Detenuti', icon: 'jail' },
];

export function CitizensPage(): JSX.Element {
  const { openCitizen, revision, pageSize } = useMdt();

  const [filter, setFilter] = useState<CitizenFilter>('all');
  const [search, setSearch] = useState('');
  // Le chiavi di ordinamento sono i nomi ammessi dalla lista bianca del server
  // (server/sv_citizens.lua, tabella SORTABLE): la NUI non puo' inventarne.
  const [sortBy, setSortBy] = useState('lastname');
  const [sortDir, setSortDir] = useState<SortDirection>('asc');

  const query = usePagedQuery<CitizenRow>(
    'citizens:search',
    { query: search, filter, sortBy, sortDir },
    { pageSize, debounceMs: 220 },
  );

  // Ricarica solo questa vista quando il server invalida uno scope che la
  // riguarda: lo stato di ricercato e la detenzione cambiano le righe.
  useRevisionEffect([revision.citizen, revision.wanted, revision.jail], query.reload);

  const wantedCount = Number(query.extra.wantedCount ?? 0);

  const columns: Column<CitizenRow>[] = [
    {
      key: 'avatar',
      header: '',
      width: '2.75rem',
      render: (row) => (
        <Avatar src={row.mugshot} firstName={row.firstName} lastName={row.lastName} size="row" />
      ),
    },
    {
      key: 'firstname',
      header: 'Nome',
      flex: 1.15,
      sortable: true,
      render: (row) => <span className="truncate font-semibold text-fg-strong">{row.firstName}</span>,
    },
    {
      key: 'lastname',
      header: 'Cognome',
      flex: 1.4,
      sortable: true,
      render: (row) => (
        <>
          <span className="truncate font-semibold text-fg-strong">{row.lastName}</span>

          {row.isWanted ? (
            <Stamp label="RICERCATO" icon="wanted" tone="critical" title={row.wantedReason} />
          ) : null}

          {row.isJailed ? (
            <Stamp
              label="DETENUTO"
              icon="jail"
              tone="warning"
              title={`Residuo ${duration(row.jailSecondsRemaining)}`}
            />
          ) : null}
        </>
      ),
    },
    {
      key: 'nationality',
      header: 'Cittadinanza',
      flex: 1,
      sortable: true,
      render: (row) => <span className="truncate">{row.nationality}</span>,
    },
    {
      key: 'job',
      header: 'Impiego',
      flex: 1.3,
      sortable: true,
      render: (row) => <span className="truncate">{row.job}</span>,
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
        title="Anagrafica cittadini"
        count={countLabel(query.total, {
          count: wantedCount,
          singular: 'ricercato',
          plural: 'ricercati',
        })}
        segments={SEGMENTS}
        segmentValue={filter}
        onSegmentChange={(value: CitizenFilter) => setFilter(value)}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Nome, cognome o SSN..."
        action={{ icon: 'refresh', title: 'Ricarica', onClick: query.reload }}
      />

      <DataTable
        columns={columns}
        rows={query.rows}
        rowKey={(row) => row.identifier}
        loading={query.loading}
        onRowClick={(row) => openCitizen(row.identifier, fullName(row))}
        emptyTitle="Nessun cittadino"
        emptyHint={
          search
            ? 'Nessun risultato per questa ricerca.'
            : filter === 'wanted'
              ? 'Nessun ricercato in questo momento.'
              : filter === 'jailed'
                ? 'Nessun detenuto in questo momento.'
                : undefined
        }
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

export default CitizensPage;
