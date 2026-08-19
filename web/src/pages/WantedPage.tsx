import { useState } from 'react';
import Sheet, { SheetHeader } from '../components/Sheet';
import DataTable, { OpenCell, type Column } from '../components/DataTable';
import Avatar from '../components/Avatar';
import Button, { IconButton } from '../components/Button';
import Modal from '../components/Modal';
import { TextArea } from '../components/Field';
import { callMdt } from '../lib/nui';
import { usePagedQuery } from '../hooks/usePagedQuery';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { dateTime, fullName, num } from '../lib/format';
import type { WantedRow } from '../lib/types';

/**
 * Ricercati.
 * ---------------------------------------------------------------------------
 * Ogni voce e' identificata dall'`identifier` del cittadino, che non cambia mai.
 * La vecchia lista rigenerava gli id per indice di iterazione, quindi tra due
 * refresh l'id di una riga cambiava e si apriva il fascicolo sbagliato (bug L7).
 */

export function WantedPage(): JSX.Element {
  const { openCitizen, notify, revision, pageSize, can } = useMdt();

  const [search, setSearch] = useState('');
  const [clearing, setClearing] = useState<WantedRow | null>(null);
  const [reason, setReason] = useState('');

  const query = usePagedQuery<WantedRow>(
    'wanted:list',
    { query: search },
    { pageSize, debounceMs: 220 },
  );

  useRevisionEffect([revision.wanted, revision.citizen], query.reload);

  const clear = async () => {
    if (!clearing) return;

    const response = await callMdt('wanted:set', {
      identifier: clearing.identifier,
      wanted: false,
      reason,
    });

    setClearing(null);
    setReason('');

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) query.reload();
  };

  const columns: Column<WantedRow>[] = [
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
      header: 'Ricercato',
      flex: 1.4,
      render: (row) => (
        <span className="min-w-0 truncate font-semibold text-fg-strong">{fullName(row)}</span>
      ),
    },
    {
      key: 'reason',
      header: 'Motivo',
      flex: 2,
      render: (row) => <span className="truncate text-critical">{row.reason}</span>,
    },
    {
      key: 'charges',
      header: 'Reati',
      width: '4.5rem',
      align: 'right',
      render: (row) => <span className="num text-fg-muted">{num(row.chargeCount)}</span>,
    },
    {
      key: 'by',
      header: 'Segnalato da',
      flex: 1.2,
      render: (row) => <span className="truncate text-fg-muted">{row.wantedBy ?? '-'}</span>,
    },
    {
      key: 'at',
      header: 'Data',
      flex: 1.1,
      render: (row) => <span className="num truncate text-fg-muted">{dateTime(row.wantedAt)}</span>,
    },
    {
      key: 'actions',
      header: 'Azioni',
      width: can('mdt.wanted.set') ? '6rem' : '3.5rem',
      align: 'right',
      render: (row) => (
        <>
          {can('mdt.wanted.set') ? (
            <IconButton
              icon="void"
              variant="danger"
              title="Revoca la ricerca"
              onClick={() => {
                setClearing(row);
                setReason('');
              }}
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
        title="Ricercati"
        count={num(query.total)}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Nome, SSN o motivo..."
        action={{ icon: 'refresh', title: 'Ricarica', onClick: query.reload }}
      />

      <DataTable
        columns={columns}
        rows={query.rows}
        rowKey={(row) => row.identifier}
        loading={query.loading}
        onRowClick={(row) => openCitizen(row.identifier, fullName(row))}
        emptyTitle="Nessun ricercato"
        emptyHint={search ? 'Nessun risultato per questa ricerca.' : 'Nessuna ricerca attiva in questo momento.'}
        page={query.page}
        pageSize={query.pageSize}
        total={query.total}
        onPage={query.setPage}
      />

      <Modal
        open={clearing !== null}
        title="Revoca la ricerca"
        width="sm"
        onClose={() => setClearing(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setClearing(null)}>
              Annulla
            </Button>
            <Button variant="danger" icon="confirm" onClick={() => void clear()}>
              Revoca
            </Button>
          </>
        }
      >
        <p className="text-card leading-relaxed text-fg">
          {clearing ? `${fullName(clearing)} non risultera' piu' ricercato.` : ''}
        </p>
        <TextArea
          value={reason}
          onChange={setReason}
          label="Motivo della revoca"
          hint="Finisce nel registro delle operazioni."
          rows={3}
          maxLength={255}
        />
      </Modal>
    </Sheet>
  );
}

export default WantedPage;
