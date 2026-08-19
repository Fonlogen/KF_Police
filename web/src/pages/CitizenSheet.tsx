import { useCallback, useEffect, useMemo, useState } from 'react';
import Sheet, { DataRow, Panel, SheetBody, SheetHeader } from '../components/Sheet';
import Icon from '../components/Icon';
import Avatar from '../components/Avatar';
import Button, { IconButton } from '../components/Button';
import Chip from '../components/Chip';
import Stamp from '../components/Stamp';
import Modal, { ConfirmDialog } from '../components/Modal';
import EmptyState from '../components/EmptyState';
import { SkeletonRows } from '../components/Skeleton';
import { Checkbox, NumberField, TextArea, TextField } from '../components/Field';
import { callMdt } from '../lib/nui';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import {
  dateOnly,
  dateTime,
  duration,
  fullName,
  involvedRole,
  money,
  months as monthsLabel,
  num,
  reportStatus,
} from '../lib/format';
import type { Charge, CitizenDossier, Note, PenalCategory } from '../lib/types';

/**
 * Fascicolo del cittadino.
 * ---------------------------------------------------------------------------
 * Tutte le azioni passano da un endpoint che rivalida permesso e dati: qui non
 * c'e' nessuna logica di autorizzazione, solo la scelta di cosa mostrare. Se
 * `can(...)` e' falso il pulsante non compare, ma e' il server che rifiuta.
 *
 * L'aggiunta di reati e' MULTIPLA: si selezionano piu' articoli e si manda una
 * sola chiamata con `penalcodeIds[]`, inserita in transazione lato server
 * (correzione del bug L2, che riscriveva il blob JSON dell'intero fascicolo).
 */

type ActiveModal = 'charges' | 'fine' | 'jail' | 'wanted' | 'note' | null;

// ---------------------------------------------------------------------------
//  Riga di un reato
// ---------------------------------------------------------------------------

function ChargeRow({
  charge,
  canVoid,
  onVoid,
  onOpenReport,
}: {
  charge: Charge;
  canVoid: boolean;
  onVoid: () => void;
  onOpenReport?: () => void;
}): JSX.Element {
  return (
    <div
      className={[
        'flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2',
        charge.voided ? 'opacity-55' : '',
      ].join(' ')}
    >
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <div className="flex min-w-0 items-baseline gap-2">
          {charge.code ? <span className="num shrink-0 text-label text-fg-dim">{charge.code}</span> : null}

          <span
            className={[
              'min-w-0 truncate text-data font-semibold',
              charge.voided ? 'text-fg-muted line-through' : 'text-fg-strong',
            ].join(' ')}
          >
            {charge.crime}
          </span>
        </div>

        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-label text-fg-muted">
          <span className="num">{dateTime(charge.date)}</span>
          {charge.officer ? <span className="truncate">{charge.officer}</span> : null}
          {charge.location ? (
            <span className="flex items-center gap-1 truncate">
              <Icon name="location" size="sm" />
              {charge.location}
            </span>
          ) : null}
          {charge.victim ? (
            <span className="truncate">Vittima: {charge.victim}</span>
          ) : null}
          {charge.voided && charge.voidReason ? (
            <span className="truncate text-critical">Annullato: {charge.voidReason}</span>
          ) : null}
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-2">
        {charge.fine > 0 ? (
          <span className="num text-data font-semibold text-fg">{money(charge.fine)}</span>
        ) : null}

        {charge.jailMonths > 0 ? (
          <span className="num whitespace-nowrap text-status text-warning">{monthsLabel(charge.jailMonths)}</span>
        ) : null}

        {charge.voided ? (
          <Chip label="Annullato" icon="void" tone="neutral" title={charge.voidedBy ?? undefined} />
        ) : charge.isPaid ? (
          <Chip label="Pagato" icon="success" tone="success" />
        ) : charge.fine > 0 ? (
          <Chip label="Da pagare" icon="warning" tone="warning" />
        ) : null}

        {charge.reportId && onOpenReport ? (
          <IconButton
            icon="reports"
            variant="ghost"
            title={`Apri il rapporto numero ${charge.reportId}`}
            onClick={onOpenReport}
          />
        ) : null}

        {canVoid && !charge.voided ? (
          <IconButton icon="void" variant="danger" title="Annulla il reato" onClick={onVoid} />
        ) : null}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
//  Modale: aggiunta reati (selezione multipla)
// ---------------------------------------------------------------------------

function ChargesModal({
  open,
  identifier,
  defaultLocation,
  onClose,
  onDone,
}: {
  open: boolean;
  identifier: string;
  defaultLocation: string;
  onClose: () => void;
  onDone: (message?: string, ok?: boolean) => void;
}): JSX.Element {
  const [categories, setCategories] = useState<PenalCategory[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<number[]>([]);
  const [location, setLocation] = useState(defaultLocation);
  const [freeCrime, setFreeCrime] = useState('');
  const [freeFine, setFreeFine] = useState(0);
  const [freeMonths, setFreeMonths] = useState(0);
  const [saving, setSaving] = useState(false);

  // Il codice penale si carica alla prima apertura, non al montaggio della
  // scheda: chi non contesta reati non paga quella query.
  useEffect(() => {
    if (!open) return;

    setLoading(true);
    setLocation(defaultLocation);

    void callMdt('penalcode:list').then((response) => {
      const payload = response as { categories?: PenalCategory[] };
      setCategories(response.ok ? (payload.categories ?? []) : []);
      setLoading(false);
    });
  }, [open, defaultLocation]);

  const filtered = useMemo(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return categories;

    return categories
      .map((category) => ({
        ...category,
        articles: category.articles.filter(
          (article) =>
            article.title.toLowerCase().includes(needle) ||
            (article.code ?? '').toLowerCase().includes(needle),
        ),
      }))
      .filter((category) => category.articles.length > 0);
  }, [categories, search]);

  const totals = useMemo(() => {
    const flat = categories.flatMap((category) => category.articles);
    let fine = freeFine;
    let jail = freeMonths;

    for (const id of selected) {
      const article = flat.find((entry) => entry.id === id);
      if (article) {
        fine += article.fine;
        jail += article.jailMonths;
      }
    }

    return { fine, jail };
  }, [categories, selected, freeFine, freeMonths]);

  const toggle = (id: number) => {
    setSelected((prev) => (prev.includes(id) ? prev.filter((entry) => entry !== id) : [...prev, id]));
  };

  const reset = () => {
    setSelected([]);
    setSearch('');
    setFreeCrime('');
    setFreeFine(0);
    setFreeMonths(0);
  };

  const submit = async () => {
    if (selected.length === 0 && freeCrime.trim() === '') return;

    setSaving(true);

    const response = await callMdt('charges:add', {
      identifier,
      penalcodeIds: selected,
      crime: freeCrime.trim(),
      fine: freeFine,
      jailMonths: freeMonths,
      location,
    });

    setSaving(false);

    if (response.ok) reset();

    onDone(response.message ?? response.error, response.ok);
  };

  const nothingSelected = selected.length === 0 && freeCrime.trim() === '';

  return (
    <Modal
      open={open}
      title="Contesta reati"
      width="lg"
      onClose={() => {
        reset();
        onClose();
      }}
      footer={
        <>
          <span className="num mr-auto text-status text-fg-muted">
            {num(selected.length)} selezionati - {money(totals.fine)} - {monthsLabel(totals.jail)}
          </span>

          <Button
            variant="ghost"
            onClick={() => {
              reset();
              onClose();
            }}
          >
            Annulla
          </Button>

          <Button
            variant="primary"
            icon="charge"
            disabled={nothingSelected || saving}
            onClick={() => void submit()}
          >
            Contesta
          </Button>
        </>
      }
    >
      <TextField
        value={search}
        onChange={setSearch}
        icon="search"
        placeholder="Cerca un articolo..."
        label="Codice penale"
      />

      {loading ? (
        <SkeletonRows rows={5} />
      ) : filtered.length === 0 ? (
        <EmptyState icon="penalcode" title="Nessun articolo" hint="Nessun risultato per questa ricerca." />
      ) : (
        <div className="flex flex-col gap-3">
          {filtered.map((category) => (
            <div key={category.id} className="flex flex-col gap-1">
              <span className="flex items-center gap-2 text-label font-bold uppercase tracking-[0.1em] text-fg-dim">
                <Icon name={category.icon} size="sm" />
                {category.label}
              </span>

              {category.articles.map((article) => (
                <div key={article.id} className="flex items-center gap-3">
                  <span className="min-w-0 flex-1">
                    <Checkbox
                      checked={selected.includes(article.id)}
                      onChange={() => toggle(article.id)}
                      label={article.code ? `${article.code} - ${article.title}` : article.title}
                    />
                  </span>

                  <span className="num shrink-0 text-status text-fg-muted">{money(article.fine)}</span>

                  {article.jailMonths > 0 ? (
                    <span className="num shrink-0 whitespace-nowrap text-status text-warning">
                      {monthsLabel(article.jailMonths)}
                    </span>
                  ) : null}

                  {article.isFelony ? <Chip label="Grave" icon="warning" tone="critical" /> : null}
                </div>
              ))}
            </div>
          ))}
        </div>
      )}

      <TextField value={location} onChange={setLocation} label="Luogo" icon="location" maxLength={100} />

      <div className="flex flex-col gap-2 rounded-sm border border-dashed border-line-perf px-3 py-3">
        <span className="text-label font-bold uppercase tracking-[0.1em] text-fg-dim">
          Reato non in codice
        </span>

        <TextField
          value={freeCrime}
          onChange={setFreeCrime}
          placeholder="Descrizione del reato"
          maxLength={255}
        />

        <div className="flex gap-3">
          <span className="min-w-0 flex-1">
            <NumberField value={freeFine} onChange={setFreeFine} label="Multa" min={0} />
          </span>
          <span className="min-w-0 flex-1">
            <NumberField value={freeMonths} onChange={setFreeMonths} label="Mesi" min={0} />
          </span>
        </div>
      </div>
    </Modal>
  );
}

// ---------------------------------------------------------------------------
//  Scheda
// ---------------------------------------------------------------------------

export function CitizenSheet({ identifier }: { identifier: string }): JSX.Element {
  const { can, notify, revision, openVehicle, openReport, status, defaultImage } = useMdt();

  const [dossier, setDossier] = useState<CitizenDossier | null>(null);
  const [loading, setLoading] = useState(true);
  const [failure, setFailure] = useState<string | undefined>(undefined);

  const [modal, setModal] = useState<ActiveModal>(null);

  const [voidTarget, setVoidTarget] = useState<Charge | null>(null);
  const [voidReason, setVoidReason] = useState('');

  const [noteDraft, setNoteDraft] = useState('');
  const [noteEditing, setNoteEditing] = useState<Note | null>(null);
  const [noteToDelete, setNoteToDelete] = useState<Note | null>(null);

  const [wantedReason, setWantedReason] = useState('');
  const [fineAmount, setFineAmount] = useState(0);
  const [fineLabel, setFineLabel] = useState('');
  const [jailMonths, setJailMonths] = useState(0);
  const [jailReason, setJailReason] = useState('');
  const [releasing, setReleasing] = useState(false);

  const load = useCallback(async () => {
    const response = await callMdt<CitizenDossier>('citizens:get', { identifier });

    if (!response.ok) {
      setDossier(null);
      setFailure(response.error ?? 'citizen_not_found');
    } else {
      setDossier(response);
      setFailure(undefined);
    }

    setLoading(false);
  }, [identifier]);

  useEffect(() => {
    setLoading(true);
    void load();
  }, [load]);

  useRevisionEffect([revision.citizen, revision.jail, revision.wanted], () => void load());

  const citizen = dossier?.citizen;
  const jail = dossier?.jail;

  const report = (message?: string, ok?: boolean) => {
    if (message) notify(message, ok ? 'success' : 'error');
    if (ok) void load();
  };

  const setWanted = async (wanted: boolean, reason: string) => {
    const response = await callMdt('wanted:set', { identifier, wanted, reason });
    setModal(null);
    setWantedReason('');
    report(response.message ?? response.error, response.ok);
  };

  const submitVoid = async () => {
    if (!voidTarget) return;

    const response = await callMdt('charges:void', { chargeId: voidTarget.id, reason: voidReason });
    setVoidTarget(null);
    setVoidReason('');
    report(response.message ?? response.error, response.ok);
  };

  const submitNote = async () => {
    if (noteDraft.trim() === '') return;

    const response = noteEditing
      ? await callMdt('notes:update', { id: noteEditing.id, note: noteDraft })
      : await callMdt('notes:add', { identifier, note: noteDraft });

    setModal(null);
    setNoteDraft('');
    setNoteEditing(null);
    report(response.message ?? response.error, response.ok);
  };

  const submitDeleteNote = async () => {
    if (!noteToDelete) return;

    const response = await callMdt('notes:delete', { id: noteToDelete.id });
    setNoteToDelete(null);
    report(response.message ?? response.error, response.ok);
  };

  const submitFine = async () => {
    const response = await callMdt('fines:issue', {
      identifier,
      amount: fineAmount,
      label: fineLabel,
      location: status.location,
    });

    setModal(null);
    report(response.message ?? response.error, response.ok);
  };

  const submitJail = async () => {
    const response = await callMdt('jail:send', {
      identifier,
      months: jailMonths,
      reason: jailReason,
    });

    setModal(null);
    report(response.message ?? response.error, response.ok);
  };

  const submitRelease = async () => {
    setReleasing(true);
    const response = await callMdt('jail:release', { identifier });
    setReleasing(false);
    report(response.message ?? response.error, response.ok);
  };

  if (loading) {
    return (
      <Sheet>
        <SheetHeader title="Fascicolo" />
        <SkeletonRows rows={8} />
      </Sheet>
    );
  }

  if (!citizen) {
    return (
      <Sheet>
        <SheetHeader title="Fascicolo" />
        <EmptyState
          icon="warning"
          title="Fascicolo non disponibile"
          hint={failure === 'no_permission' ? 'Permesso negato.' : 'Cittadino non trovato in anagrafica.'}
        />
      </Sheet>
    );
  }

  const name = fullName(citizen);
  const charges = dossier?.charges ?? [];
  const activeCharges = charges.filter((charge) => !charge.voided);
  const totals = dossier?.totals;

  return (
    <Sheet>
      <SheetHeader
        title={name}
        count={citizen.ssn ? `SSN ${citizen.ssn}` : undefined}
        action={{ icon: 'refresh', title: 'Ricarica il fascicolo', onClick: () => void load() }}
        extra={
          <span className="flex shrink-0 items-center gap-2">
            {can('mdt.wanted.set') ? (
              <IconButton
                icon="wanted"
                variant={citizen.isWanted ? 'danger' : 'ghost'}
                title={citizen.isWanted ? 'Revoca lo stato di ricercato' : 'Segnala come ricercato'}
                onClick={() => {
                  if (citizen.isWanted) {
                    void setWanted(false, '');
                  } else {
                    setWantedReason('');
                    setModal('wanted');
                  }
                }}
              />
            ) : null}

            {can('mdt.fine.issue') ? (
              <IconButton
                icon="money"
                title="Emetti una sanzione"
                onClick={() => {
                  setFineAmount(totals?.unpaidFine ?? 0);
                  setFineLabel('');
                  setModal('fine');
                }}
              />
            ) : null}

            {can('jail.send') && !jail?.jailed ? (
              <IconButton
                icon="jail"
                title="Trasferisci in carcere"
                onClick={() => {
                  setJailMonths(totals?.totalMonths ?? 0);
                  setJailReason('');
                  setModal('jail');
                }}
              />
            ) : null}
          </span>
        }
      />

      <SheetBody>
        {/* ---------------- Identita' ---------------- */}
        <div className="flex gap-4">
          <Avatar
            src={citizen.mugshot ?? defaultImage}
            firstName={citizen.firstName}
            lastName={citizen.lastName}
            size="sheet"
          />

          <div className="flex min-w-0 flex-1 flex-col gap-2">
            <div className="flex min-w-0 flex-wrap items-center gap-2">
              <h4 className="min-w-0 truncate text-section font-bold text-fg-strong">{name}</h4>

              {citizen.isWanted ? (
                <Stamp label="RICERCATO" icon="wanted" tone="critical" title={citizen.wantedReason} />
              ) : null}

              {jail?.jailed ? (
                <Stamp
                  label="DETENUTO"
                  icon="jail"
                  tone="warning"
                  title={`Residuo ${duration(jail.secondsRemaining)}`}
                />
              ) : null}
            </div>

            <DataRow label="SSN" value={citizen.ssn ?? '-'} numeric />
            <DataRow label="Nascita" value={dateOnly(citizen.dateOfBirth)} numeric />
            <DataRow label="Sesso" value={citizen.sex ?? '-'} />
            <DataRow
              label="Altezza"
              value={citizen.height ? `${num(citizen.height)} cm` : '-'}
              numeric
            />
            <DataRow label="Cittadinanza" value={citizen.nationality} />
            <DataRow label="Telefono" value={citizen.phone ?? '-'} numeric />
            <DataRow label="Impiego" value={citizen.job} />
          </div>
        </div>

        {citizen.isWanted ? (
          <Panel title="Ricerca attiva" icon="wanted">
            <DataRow label="Motivo" value={citizen.wantedReason ?? '-'} />
            <DataRow label="Segnalato da" value={citizen.wantedBy ?? '-'} />
            <DataRow label="Data" value={dateTime(citizen.wantedAt)} numeric />
          </Panel>
        ) : null}

        {/* ---------------- Carcere ---------------- */}
        {jail?.jailed ? (
          <Panel
            title="Detenzione in corso"
            icon="jail"
            action={
              can('jail.release') ? (
                <Button
                  variant="warning"
                  icon="confirm"
                  disabled={releasing}
                  onClick={() => void submitRelease()}
                >
                  Rilascia
                </Button>
              ) : null
            }
          >
            <DataRow label="Tempo residuo" value={duration(jail.secondsRemaining)} numeric />
            <DataRow label="Motivo" value={jail.reason ?? '-'} />
            <DataRow label="Cella" value={jail.cell ?? '-'} />
            <DataRow label="Disposto da" value={jail.officer ?? '-'} />
            <DataRow label="Ingresso" value={dateTime(jail.jailedAt)} numeric />
          </Panel>
        ) : null}

        {/* ---------------- Reati ---------------- */}
        <Panel
          title="Reati e sanzioni"
          icon="charge"
          action={
            can('mdt.charge.add') ? (
              <Button variant="primary" icon="add" onClick={() => setModal('charges')}>
                Contesta
              </Button>
            ) : null
          }
        >
          {totals ? (
            <div className="flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-line-soft pb-2">
              <span className="num text-status text-fg-muted">
                {num(activeCharges.length)} attivi su {num(charges.length)}
              </span>
              <span className="num text-data font-semibold text-fg-strong">{money(totals.totalFine)}</span>
              <span className="num text-status text-warning">{monthsLabel(totals.totalMonths)}</span>
              {totals.unpaidFine > 0 ? (
                <span className="num text-status text-critical">
                  Non pagato: {money(totals.unpaidFine)}
                </span>
              ) : null}
            </div>
          ) : null}

          {charges.length === 0 ? (
            <EmptyState icon="charge" title="Nessun reato" hint="Fascicolo penale pulito." />
          ) : (
            charges.map((charge) => (
              <ChargeRow
                key={charge.id}
                charge={charge}
                canVoid={can('mdt.charge.void')}
                onVoid={() => {
                  setVoidTarget(charge);
                  setVoidReason('');
                }}
                onOpenReport={
                  charge.reportId ? () => openReport(charge.reportId as number) : undefined
                }
              />
            ))
          )}
        </Panel>

        {/* ---------------- Note ---------------- */}
        <Panel
          title="Note di servizio"
          icon="edit"
          action={
            can('mdt.note.create') ? (
              <Button
                icon="add"
                onClick={() => {
                  setNoteEditing(null);
                  setNoteDraft('');
                  setModal('note');
                }}
              >
                Aggiungi
              </Button>
            ) : null
          }
        >
          {(dossier?.notes ?? []).length === 0 ? (
            <EmptyState icon="edit" title="Nessuna nota" />
          ) : (
            (dossier?.notes ?? []).map((note) => (
              <div
                key={note.id}
                className="flex items-start gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2"
              >
                <div className="flex min-w-0 flex-1 flex-col gap-1">
                  <p className="whitespace-pre-wrap break-words text-data leading-relaxed text-fg">
                    {note.note}
                  </p>
                  <span className="flex flex-wrap gap-x-3 text-label text-fg-muted">
                    <span className="truncate">{note.officer ?? '-'}</span>
                    <span className="num">{dateTime(note.date)}</span>
                  </span>
                </div>

                {can('mdt.note.create') ? (
                  <IconButton
                    icon="edit"
                    variant="ghost"
                    title="Modifica la nota"
                    onClick={() => {
                      setNoteEditing(note);
                      setNoteDraft(note.note);
                      setModal('note');
                    }}
                  />
                ) : null}

                {can('mdt.note.delete') ? (
                  <IconButton
                    icon="delete"
                    variant="danger"
                    title="Elimina la nota"
                    onClick={() => setNoteToDelete(note)}
                  />
                ) : null}
              </div>
            ))
          )}
        </Panel>

        {/* ---------------- Veicoli ---------------- */}
        <Panel title="Veicoli intestati" icon="vehicles">
          {(dossier?.vehicles ?? []).length === 0 ? (
            <EmptyState icon="vehicles" title="Nessun veicolo intestato" />
          ) : (
            <div className="flex flex-wrap gap-2">
              {(dossier?.vehicles ?? []).map((vehicle) => (
                <Chip
                  key={vehicle.plate}
                  label={`${vehicle.plate} - ${vehicle.model}`}
                  icon={vehicle.isStolen ? 'warning' : vehicle.isImpounded ? 'impound' : 'vehicles'}
                  tone={vehicle.isStolen ? 'critical' : vehicle.isImpounded ? 'warning' : 'neutral'}
                  onClick={() => openVehicle(vehicle.plate)}
                />
              ))}
            </div>
          )}
        </Panel>

        {/* ---------------- Licenze ---------------- */}
        <Panel title="Licenze" icon="license">
          {(dossier?.licenses ?? []).length === 0 ? (
            <EmptyState icon="license" title="Nessuna licenza" />
          ) : (
            <div className="flex flex-wrap gap-2">
              {(dossier?.licenses ?? []).map((license) => (
                <Chip key={license.type} label={license.label} icon="license" tone="info" />
              ))}
            </div>
          )}
        </Panel>

        {/* ---------------- Proprieta' ---------------- */}
        {(dossier?.properties ?? []).length > 0 ? (
          <Panel title="Proprieta'" icon="property">
            {(dossier?.properties ?? []).map((property) => (
              <DataRow
                key={property.id}
                label={property.label}
                value={`${property.address} - ${property.city}`}
              />
            ))}
          </Panel>
        ) : null}

        {/* ---------------- Rapporti ---------------- */}
        <Panel title="Rapporti collegati" icon="reports">
          {(dossier?.reports ?? []).length === 0 ? (
            <EmptyState icon="reports" title="Nessun rapporto collegato" />
          ) : (
            (dossier?.reports ?? []).map((entry) => (
              <button
                key={`${entry.id}:${entry.role ?? ''}`}
                type="button"
                onClick={() => openReport(entry.id, entry.title)}
                className="flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2 text-left hover:bg-hover"
              >
                <span className="num shrink-0 text-label text-fg-dim">#{entry.id}</span>
                <span className="min-w-0 flex-1 truncate text-data text-fg-strong">{entry.title}</span>
                {entry.role ? <Chip label={involvedRole(entry.role)} tone="info" /> : null}
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

      {/* ---------------- Modali ---------------- */}

      <ChargesModal
        open={modal === 'charges'}
        identifier={identifier}
        defaultLocation={status.location}
        onClose={() => setModal(null)}
        onDone={(message, ok) => {
          if (ok) setModal(null);
          report(message, ok);
        }}
      />

      <Modal
        open={modal === 'wanted'}
        title="Segnala come ricercato"
        width="sm"
        onClose={() => setModal(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModal(null)}>
              Annulla
            </Button>
            <Button
              variant="danger"
              icon="wanted"
              disabled={wantedReason.trim() === ''}
              onClick={() => void setWanted(true, wantedReason)}
            >
              Segnala
            </Button>
          </>
        }
      >
        <TextArea
          value={wantedReason}
          onChange={setWantedReason}
          label="Motivo della ricerca"
          rows={4}
          maxLength={255}
        />
      </Modal>

      <Modal
        open={modal === 'fine'}
        title="Emetti una sanzione"
        width="sm"
        onClose={() => setModal(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModal(null)}>
              Annulla
            </Button>
            <Button variant="primary" icon="money" disabled={fineAmount <= 0} onClick={() => void submitFine()}>
              Emetti
            </Button>
          </>
        }
      >
        <NumberField value={fineAmount} onChange={setFineAmount} label="Importo" min={1} />
        <TextField
          value={fineLabel}
          onChange={setFineLabel}
          label="Causale"
          hint="Se vuota si usa la causale predefinita del reparto."
          maxLength={120}
        />
      </Modal>

      <Modal
        open={modal === 'jail'}
        title="Trasferimento in carcere"
        width="sm"
        onClose={() => setModal(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModal(null)}>
              Annulla
            </Button>
            <Button variant="primary" icon="jail" disabled={jailMonths <= 0} onClick={() => void submitJail()}>
              Trasferisci
            </Button>
          </>
        }
      >
        <NumberField
          value={jailMonths}
          onChange={setJailMonths}
          label="Mesi di condanna"
          hint="La cella la assegna il server tra quelle libere."
          min={1}
        />
        <TextArea value={jailReason} onChange={setJailReason} label="Motivo" rows={3} maxLength={255} />
      </Modal>

      <Modal
        open={modal === 'note'}
        title={noteEditing ? 'Modifica la nota' : 'Nuova nota di servizio'}
        onClose={() => {
          setModal(null);
          setNoteEditing(null);
        }}
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => {
                setModal(null);
                setNoteEditing(null);
              }}
            >
              Annulla
            </Button>
            <Button
              variant="primary"
              icon="save"
              disabled={noteDraft.trim() === ''}
              onClick={() => void submitNote()}
            >
              Salva
            </Button>
          </>
        }
      >
        <TextArea value={noteDraft} onChange={setNoteDraft} rows={6} maxLength={1000} />
      </Modal>

      <Modal
        open={voidTarget !== null}
        title="Annulla il reato"
        width="sm"
        onClose={() => setVoidTarget(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setVoidTarget(null)}>
              Annulla
            </Button>
            <Button variant="danger" icon="void" onClick={() => void submitVoid()}>
              Conferma
            </Button>
          </>
        }
      >
        <p className="text-card leading-relaxed text-fg">
          Il reato resta nel fascicolo con la nota di annullamento: lo storico non viene cancellato.
        </p>
        <TextArea
          value={voidReason}
          onChange={setVoidReason}
          label={`Motivo per "${voidTarget?.crime ?? ''}"`}
          rows={3}
          maxLength={255}
        />
      </Modal>

      <ConfirmDialog
        open={noteToDelete !== null}
        title="Elimina la nota"
        message="La nota viene rimossa definitivamente dal fascicolo."
        confirmLabel="Elimina"
        onConfirm={() => void submitDeleteNote()}
        onCancel={() => setNoteToDelete(null)}
      />
    </Sheet>
  );
}

export default CitizenSheet;
