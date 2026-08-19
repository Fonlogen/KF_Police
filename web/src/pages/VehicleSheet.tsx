import { useCallback, useEffect, useState } from 'react';
import Sheet, { DataRow, Panel, SheetBody, SheetHeader } from '../components/Sheet';
import Button from '../components/Button';
import Chip from '../components/Chip';
import Stamp from '../components/Stamp';
import Modal from '../components/Modal';
import EmptyState from '../components/EmptyState';
import { SkeletonRows } from '../components/Skeleton';
import { TextArea } from '../components/Field';
import { callMdt } from '../lib/nui';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { dateTime, num, reportStatus } from '../lib/format';
import type { VehicleRecord } from '../lib/types';

/**
 * Scheda del veicolo.
 * Funziona anche su una targa non registrata: in quel caso il server restituisce
 * solo i flag, che e' l'informazione utile durante un controllo su strada.
 */

/** Quale flag si sta cambiando: serve per chiedere il motivo prima di attivarlo. */
type FlagKey = 'stolen' | 'impounded' | 'bolo';

const FLAG_LABEL: Record<FlagKey, string> = {
  stolen: 'Segnala come rubato',
  impounded: 'Registra il sequestro',
  bolo: 'Dirama un BOLO',
};

export function VehicleSheet({ plate }: { plate: string }): JSX.Element {
  const { can, notify, revision, openCitizen, openReport } = useMdt();

  const [vehicle, setVehicle] = useState<VehicleRecord | null>(null);
  const [loading, setLoading] = useState(true);

  const [flagModal, setFlagModal] = useState<FlagKey | null>(null);
  const [reason, setReason] = useState('');
  const [notes, setNotes] = useState('');
  const [notesOpen, setNotesOpen] = useState(false);

  const load = useCallback(async () => {
    const response = await callMdt('vehicles:get', { plate });
    const payload = response as { vehicle?: VehicleRecord };

    setVehicle(response.ok && payload.vehicle ? payload.vehicle : null);
    setLoading(false);
  }, [plate]);

  useEffect(() => {
    setLoading(true);
    void load();
  }, [load]);

  useRevisionEffect([revision.vehicles], () => void load());

  const setFlag = async (changes: Record<string, unknown>) => {
    const response = await callMdt('vehicles:setFlag', { plate, ...changes });

    setFlagModal(null);
    setNotesOpen(false);
    setReason('');

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) void load();
  };

  if (loading) {
    return (
      <Sheet>
        <SheetHeader title={plate} />
        <SkeletonRows rows={6} />
      </Sheet>
    );
  }

  if (!vehicle) {
    return (
      <Sheet>
        <SheetHeader title={plate} />
        <EmptyState
          icon="vehicles"
          title="Veicolo sconosciuto"
          hint="La targa non risulta registrata e non ha segnalazioni a suo carico."
        />
      </Sheet>
    );
  }

  const flags = vehicle.flags;
  const canFlag = can('mdt.vehicle.flag');

  return (
    <Sheet>
      <SheetHeader
        title={vehicle.plate}
        count={vehicle.model}
        action={{ icon: 'refresh', title: 'Ricarica la scheda', onClick: () => void load() }}
      />

      <SheetBody>
        <div className="flex flex-wrap items-center gap-2">
          {flags.isStolen ? <Stamp label="RUBATO" icon="warning" tone="critical" /> : null}
          {flags.hasBolo ? <Stamp label="BOLO" icon="wanted" tone="critical" /> : null}
          {flags.isImpounded ? <Stamp label="SEQUESTRATO" icon="impound" tone="warning" /> : null}
          {!vehicle.registered ? <Stamp label="NON REGISTRATO" icon="warning" tone="info" /> : null}
        </div>

        <Panel title="Veicolo" icon="vehicles">
          <DataRow label="Targa" value={vehicle.plate} numeric />
          <DataRow label="Modello" value={vehicle.model} />
          <DataRow label="Tipo" value={vehicle.type} />
          <DataRow label="Registrato" value={vehicle.registered ? 'Si' : 'No'} />
          <DataRow label="In garage" value={vehicle.stored ? 'Si' : 'No'} />
          <DataRow
            label="Chilometraggio"
            value={vehicle.mileage != null ? `${num(vehicle.mileage)} km` : '-'}
            numeric
          />
          {vehicle.job ? <DataRow label="Veicolo di servizio" value={vehicle.job} /> : null}
        </Panel>

        <Panel title="Proprietario" icon="identity">
          {vehicle.owner ? (
            <>
              <DataRow
                label="Nome"
                value={
                  <button
                    type="button"
                    title="Apri il fascicolo"
                    onClick={() => openCitizen(vehicle.owner as string, vehicle.ownerName)}
                    className="truncate text-left text-info hover:brightness-125"
                  >
                    {vehicle.ownerName ?? 'Sconosciuto'}
                  </button>
                }
              />
              <DataRow label="SSN" value={vehicle.ownerSsn ?? '-'} numeric />
              <DataRow label="Telefono" value={vehicle.ownerPhone ?? '-'} numeric />
            </>
          ) : (
            <EmptyState icon="identity" title="Nessun proprietario registrato" />
          )}
        </Panel>

        <Panel
          title="Segnalazioni"
          icon="warning"
          action={
            canFlag ? (
              <Button
                icon="edit"
                onClick={() => {
                  setNotes(flags.notes ?? '');
                  setNotesOpen(true);
                }}
              >
                Annotazioni
              </Button>
            ) : null
          }
        >
          <div className="flex flex-wrap items-center gap-2">
            <Chip
              label={flags.isStolen ? 'Rubato' : 'Non rubato'}
              icon="warning"
              tone={flags.isStolen ? 'critical' : 'neutral'}
              onClick={
                canFlag
                  ? () => (flags.isStolen ? void setFlag({ stolen: false }) : setFlagModal('stolen'))
                  : undefined
              }
              title={canFlag ? 'Cambia lo stato' : undefined}
            />

            <Chip
              label={flags.hasBolo ? 'BOLO attivo' : 'Nessun BOLO'}
              icon="wanted"
              tone={flags.hasBolo ? 'critical' : 'neutral'}
              onClick={
                canFlag
                  ? () => (flags.hasBolo ? void setFlag({ bolo: false }) : setFlagModal('bolo'))
                  : undefined
              }
              title={canFlag ? 'Cambia lo stato' : undefined}
            />

            <Chip
              label={flags.isImpounded ? 'Sequestrato' : 'Non sequestrato'}
              icon="impound"
              tone={flags.isImpounded ? 'warning' : 'neutral'}
              onClick={
                canFlag
                  ? () =>
                      flags.isImpounded ? void setFlag({ impounded: false }) : setFlagModal('impounded')
                  : undefined
              }
              title={canFlag ? 'Cambia lo stato' : undefined}
            />
          </div>

          {flags.isStolen || flags.hasBolo || flags.isImpounded ? (
            <div className="flex flex-col gap-2 border-t border-line-soft pt-2">
              {flags.boloReason ? <DataRow label="Motivo BOLO" value={flags.boloReason} /> : null}
              {flags.impoundReason ? <DataRow label="Motivo sequestro" value={flags.impoundReason} /> : null}
              {flags.impoundBy ? <DataRow label="Sequestrato da" value={flags.impoundBy} /> : null}
              {flags.impoundAt ? (
                <DataRow label="Data sequestro" value={dateTime(flags.impoundAt)} numeric />
              ) : null}
            </div>
          ) : null}

          {flags.notes ? (
            <p className="whitespace-pre-wrap break-words border-t border-line-soft pt-2 text-data leading-relaxed text-fg">
              {flags.notes}
            </p>
          ) : null}
        </Panel>

        <Panel title="Rapporti collegati" icon="reports">
          {vehicle.reports.length === 0 ? (
            <EmptyState icon="reports" title="Nessun rapporto collegato" />
          ) : (
            vehicle.reports.map((entry) => (
              <button
                key={entry.id}
                type="button"
                onClick={() => openReport(entry.id, entry.title)}
                className="flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2 text-left hover:bg-hover"
              >
                <span className="num shrink-0 text-label text-fg-dim">#{entry.id}</span>
                <span className="min-w-0 flex-1 truncate text-data text-fg-strong">{entry.title}</span>
                <Chip
                  label={reportStatus(entry.status)}
                  tone={entry.status === 'closed' ? 'success' : entry.status === 'draft' ? 'neutral' : 'warning'}
                />
                <span className="num shrink-0 text-label text-fg-muted">{dateTime(entry.date)}</span>
              </button>
            ))
          )}
        </Panel>
      </SheetBody>

      <Modal
        open={flagModal !== null}
        title={flagModal ? FLAG_LABEL[flagModal] : ''}
        width="sm"
        onClose={() => setFlagModal(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setFlagModal(null)}>
              Annulla
            </Button>
            <Button
              variant="danger"
              icon="confirm"
              disabled={reason.trim() === ''}
              onClick={() => {
                if (flagModal) void setFlag({ [flagModal]: true, reason });
              }}
            >
              Conferma
            </Button>
          </>
        }
      >
        <TextArea value={reason} onChange={setReason} label="Motivo" rows={4} maxLength={255} />
      </Modal>

      <Modal
        open={notesOpen}
        title="Annotazioni sul veicolo"
        onClose={() => setNotesOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setNotesOpen(false)}>
              Annulla
            </Button>
            <Button variant="primary" icon="save" onClick={() => void setFlag({ notes })}>
              Salva
            </Button>
          </>
        }
      >
        <TextArea value={notes} onChange={setNotes} rows={6} maxLength={1000} />
      </Modal>
    </Sheet>
  );
}

export default VehicleSheet;
