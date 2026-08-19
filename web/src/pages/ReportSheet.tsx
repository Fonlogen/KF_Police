import { useCallback, useEffect, useState } from 'react';
import Sheet, { Panel, SheetBody, SheetHeader } from '../components/Sheet';
import Button, { IconButton } from '../components/Button';
import Chip from '../components/Chip';
import Modal, { ConfirmDialog } from '../components/Modal';
import EmptyState from '../components/EmptyState';
import Avatar from '../components/Avatar';
import { SkeletonRows } from '../components/Skeleton';
import { Checkbox, SelectField, TextArea, TextField } from '../components/Field';
import { callMdt } from '../lib/nui';
import { usePagedQuery } from '../hooks/usePagedQuery';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { dateTime, fullName, involvedRole } from '../lib/format';
import type {
  CitizenRow,
  InvolvedRole,
  ReportDetail,
  ReportInvolved,
  ReportStatus,
  Tag,
} from '../lib/types';

/**
 * Redazione di un rapporto.
 * ---------------------------------------------------------------------------
 * Coinvolti, veicoli e tag sono tabelle di giunzione lato server e il
 * salvataggio e' una transazione: un rapporto non resta mai a meta'.
 *
 * Il vecchio editor usava @uiw/react-md-editor (700 kB di bundle) per un campo
 * di testo semplice: qui e' una textarea, e il markdown non serviva a nessuno
 * perche' il rapporto viene riletto come testo.
 */

const STATUS_OPTIONS: { value: ReportStatus; label: string }[] = [
  { value: 'draft', label: 'Bozza' },
  { value: 'open', label: 'Aperto' },
  { value: 'closed', label: 'Chiuso' },
];

const ROLE_OPTIONS: { value: InvolvedRole; label: string }[] = [
  { value: 'suspect', label: 'Sospettato' },
  { value: 'victim', label: 'Vittima' },
  { value: 'witness', label: 'Testimone' },
];

const ROLE_TONE: Record<InvolvedRole, 'critical' | 'info' | 'neutral'> = {
  suspect: 'critical',
  victim: 'info',
  witness: 'neutral',
};

// ---------------------------------------------------------------------------
//  Modale: scelta di un cittadino da coinvolgere
// ---------------------------------------------------------------------------

function InvolvedPicker({
  open,
  onClose,
  onPick,
}: {
  open: boolean;
  onClose: () => void;
  onPick: (citizen: CitizenRow, role: InvolvedRole) => void;
}): JSX.Element {
  const [search, setSearch] = useState('');
  const [role, setRole] = useState<InvolvedRole>('suspect');

  const query = usePagedQuery<CitizenRow>(
    'citizens:search',
    { query: search },
    { pageSize: 8, debounceMs: 220 },
  );

  return (
    <Modal open={open} title="Aggiungi un coinvolto" onClose={onClose}>
      <SelectField
        value={role}
        onChange={(value) => setRole(value as InvolvedRole)}
        options={ROLE_OPTIONS}
        label="Ruolo"
      />

      <TextField
        value={search}
        onChange={setSearch}
        icon="search"
        label="Cittadino"
        placeholder="Nome, cognome o SSN..."
      />

      {query.loading ? (
        <SkeletonRows rows={4} />
      ) : query.rows.length === 0 ? (
        <EmptyState icon="citizens" title="Nessun cittadino" hint="Affina la ricerca." />
      ) : (
        <div className="flex flex-col gap-1">
          {query.rows.map((citizen) => (
            <button
              key={citizen.identifier}
              type="button"
              onClick={() => onPick(citizen, role)}
              className="flex h-row items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 text-left hover:bg-hover"
            >
              <Avatar
                src={citizen.mugshot}
                firstName={citizen.firstName}
                lastName={citizen.lastName}
                size="row"
              />
              <span className="min-w-0 flex-1 truncate text-data font-semibold text-fg-strong">
                {fullName(citizen)}
              </span>
              <span className="num shrink-0 text-label text-fg-muted">{citizen.ssn ?? '-'}</span>
            </button>
          ))}
        </div>
      )}
    </Modal>
  );
}

// ---------------------------------------------------------------------------
//  Scheda
// ---------------------------------------------------------------------------

export function ReportSheet({
  reportId,
  tabId,
}: {
  reportId: number | 'new';
  tabId: string;
}): JSX.Element {
  const { can, notify, revision, officer, status: gameStatus, openCitizen, openVehicle, openReport, closeTab } =
    useMdt();

  const isNew = reportId === 'new';

  const [loading, setLoading] = useState(!isNew);
  const [missing, setMissing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [reportState, setReportState] = useState<ReportStatus>('open');
  const [confidential, setConfidential] = useState(false);
  const [involved, setInvolved] = useState<ReportInvolved[]>([]);
  const [vehicles, setVehicles] = useState<{ plate: string; model?: string; ownerName?: string }[]>([]);
  const [tags, setTags] = useState<Tag[]>([]);
  const [meta, setMeta] = useState<{ officer?: string; officerId?: string; date?: string } | null>(null);

  const [allTags, setAllTags] = useState<Tag[]>([]);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [plateDraft, setPlateDraft] = useState('');
  const [confirmDelete, setConfirmDelete] = useState(false);

  /** Un campo modificato: serve solo a non ricaricare sopra il lavoro in corso. */
  const touch = <T,>(setter: (value: T) => void) => (value: T) => {
    setDirty(true);
    setter(value);
  };

  const load = useCallback(async () => {
    if (reportId === 'new') return;

    const response = await callMdt('reports:get', { id: reportId });
    const payload = response as { report?: ReportDetail };

    if (!response.ok || !payload.report) {
      setMissing(true);
      setLoading(false);
      return;
    }

    const report = payload.report;

    setTitle(report.title);
    setDescription(report.description);
    setLocation(report.location ?? '');
    setReportState(report.status);
    setConfidential(Boolean(report.isConfidential));
    setInvolved(report.involved);
    setVehicles(report.vehicles);
    setTags(report.tags);
    setMeta({ officer: report.officer, officerId: report.officerId, date: report.date });
    setMissing(false);
    setDirty(false);
    setLoading(false);
  }, [reportId]);

  useEffect(() => {
    if (isNew) {
      // Il luogo predefinito e' dove si trova l'agente adesso.
      setLocation(gameStatus.location);
      setMeta({ officer: officer?.name, officerId: officer?.identifier });
      return;
    }

    setLoading(true);
    void load();
  }, [isNew, load, gameStatus.location, officer?.name, officer?.identifier]);

  // Un rapporto modificato da un altro agente non deve sovrascrivere quello che
  // si sta scrivendo: si ricarica solo se non ci sono modifiche locali.
  useRevisionEffect([revision.reports], () => {
    if (!dirty) void load();
  });

  useEffect(() => {
    void callMdt('tags:list').then((response) => {
      const payload = response as { rows?: Tag[] };
      if (response.ok) setAllTags(payload.rows ?? []);
    });
  }, []);

  const canEdit =
    isNew ||
    can('mdt.report.edit') ||
    (meta?.officerId != null && meta.officerId === officer?.identifier);

  const save = async () => {
    if (title.trim() === '') return;

    setSaving(true);

    const response = await callMdt('reports:save', {
      id: isNew ? undefined : reportId,
      title,
      description,
      location,
      status: reportState,
      isConfidential: confidential,
      involved: involved.map((entry) => ({ identifier: entry.identifier, role: entry.role })),
      vehicles: vehicles.map((entry) => entry.plate),
      tags: tags.map((entry) => entry.id),
    });

    setSaving(false);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (!response.ok) return;

    setDirty(false);

    // Un rapporto nuovo ha un id solo dopo il salvataggio: la linguetta
    // "Nuovo rapporto" viene sostituita da quella del rapporto vero.
    const savedId = Number((response as { id?: number }).id);

    if (isNew && Number.isFinite(savedId)) {
      closeTab(tabId);
      openReport(savedId, title);
    } else {
      void load();
    }
  };

  const remove = async () => {
    const response = await callMdt('reports:delete', { id: reportId });
    setConfirmDelete(false);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) closeTab(tabId);
  };

  const toggleTag = (tag: Tag) => {
    setDirty(true);
    setTags((prev) =>
      prev.some((entry) => entry.id === tag.id)
        ? prev.filter((entry) => entry.id !== tag.id)
        : [...prev, tag],
    );
  };

  const addPlate = () => {
    const plate = plateDraft.trim().toUpperCase();
    if (plate === '') return;

    setDirty(true);
    setVehicles((prev) => (prev.some((entry) => entry.plate === plate) ? prev : [...prev, { plate }]));
    setPlateDraft('');
  };

  if (loading) {
    return (
      <Sheet>
        <SheetHeader title="Rapporto" />
        <SkeletonRows rows={8} />
      </Sheet>
    );
  }

  if (missing) {
    return (
      <Sheet>
        <SheetHeader title="Rapporto" />
        <EmptyState
          icon="reports"
          title="Rapporto non disponibile"
          hint="Il rapporto non esiste piu' oppure e' riservato."
        />
      </Sheet>
    );
  }

  return (
    <Sheet>
      <SheetHeader
        title={isNew ? 'Nuovo rapporto' : title || `Rapporto #${reportId}`}
        count={meta?.date ? dateTime(meta.date) : undefined}
        action={
          canEdit
            ? { icon: 'save', title: 'Salva il rapporto', onClick: () => void save() }
            : { icon: 'refresh', title: 'Ricarica', onClick: () => void load() }
        }
        extra={
          !isNew && can('mdt.report.delete') ? (
            <IconButton icon="delete" variant="danger" title="Elimina il rapporto" onClick={() => setConfirmDelete(true)} />
          ) : null
        }
      />

      <SheetBody>
        <Panel title="Testata" icon="reports">
          <TextField
            value={title}
            onChange={touch(setTitle)}
            label="Titolo"
            maxLength={150}
            disabled={!canEdit}
          />

          <div className="flex flex-wrap gap-3">
            <span className="min-w-0 flex-1">
              <TextField
                value={location}
                onChange={touch(setLocation)}
                label="Luogo"
                icon="location"
                maxLength={100}
                disabled={!canEdit}
              />
            </span>

            <span className="w-[12rem] shrink-0">
              <SelectField
                value={reportState}
                onChange={(value) => {
                  setDirty(true);
                  setReportState(value as ReportStatus);
                }}
                options={STATUS_OPTIONS}
                label="Stato"
                disabled={!canEdit}
              />
            </span>
          </div>

          <Checkbox
            checked={confidential}
            onChange={(value) => {
              setDirty(true);
              setConfidential(value);
            }}
            label="Riservato: visibile solo a chi lo ha scritto e ai gradi alti"
          />

          {meta?.officer ? (
            <span className="text-label text-fg-muted">Redatto da {meta.officer}</span>
          ) : null}
        </Panel>

        <Panel title="Relazione" icon="edit">
          <TextArea
            value={description}
            onChange={touch(setDescription)}
            rows={12}
            maxLength={5000}
            placeholder="Descrizione dei fatti, in ordine cronologico."
            disabled={!canEdit}
          />
        </Panel>

        <Panel
          title="Coinvolti"
          icon="citizens"
          action={
            canEdit ? (
              <Button icon="add" onClick={() => setPickerOpen(true)}>
                Aggiungi
              </Button>
            ) : null
          }
        >
          {involved.length === 0 ? (
            <EmptyState icon="citizens" title="Nessun coinvolto" />
          ) : (
            involved.map((entry) => (
              <div
                key={`${entry.identifier}:${entry.role}`}
                className="flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2"
              >
                <Chip label={involvedRole(entry.role)} tone={ROLE_TONE[entry.role] ?? 'neutral'} />

                <button
                  type="button"
                  title="Apri il fascicolo"
                  onClick={() => openCitizen(entry.identifier, fullName(entry))}
                  className="min-w-0 flex-1 truncate text-left text-data text-info hover:brightness-125"
                >
                  {fullName(entry)}
                </button>

                <span className="num shrink-0 text-label text-fg-muted">{entry.ssn ?? '-'}</span>

                {canEdit ? (
                  <IconButton
                    icon="close"
                    variant="danger"
                    title="Rimuovi dal rapporto"
                    onClick={() => {
                      setDirty(true);
                      setInvolved((prev) =>
                        prev.filter(
                          (item) => !(item.identifier === entry.identifier && item.role === entry.role),
                        ),
                      );
                    }}
                  />
                ) : null}
              </div>
            ))
          )}
        </Panel>

        <Panel title="Veicoli" icon="vehicles">
          {canEdit ? (
            <div className="flex items-end gap-2">
              <span className="min-w-0 flex-1">
                <TextField
                  value={plateDraft}
                  onChange={setPlateDraft}
                  label="Targa"
                  numeric
                  maxLength={12}
                  onEnter={addPlate}
                />
              </span>
              <Button icon="add" onClick={addPlate}>
                Collega
              </Button>
            </div>
          ) : null}

          {vehicles.length === 0 ? (
            <EmptyState icon="vehicles" title="Nessun veicolo collegato" />
          ) : (
            <div className="flex flex-wrap gap-2">
              {vehicles.map((entry) => (
                <Chip
                  key={entry.plate}
                  label={entry.model ? `${entry.plate} - ${entry.model}` : entry.plate}
                  icon="vehicles"
                  onClick={() => openVehicle(entry.plate)}
                  onRemove={
                    canEdit
                      ? () => {
                          setDirty(true);
                          setVehicles((prev) => prev.filter((item) => item.plate !== entry.plate));
                        }
                      : undefined
                  }
                />
              ))}
            </div>
          )}
        </Panel>

        <Panel title="Etichette" icon="filter">
          {allTags.length === 0 ? (
            <EmptyState icon="filter" title="Nessuna etichetta configurata" />
          ) : (
            <div className="flex flex-wrap gap-2">
              {allTags.map((tag) => {
                const selected = tags.some((entry) => entry.id === tag.id);

                return (
                  <Chip
                    key={tag.id}
                    label={tag.label}
                    icon={tag.icon}
                    color={selected ? tag.color : undefined}
                    selected={selected}
                    onClick={canEdit ? () => toggleTag(tag) : undefined}
                    title={selected ? 'Togli questa etichetta' : 'Applica questa etichetta'}
                  />
                );
              })}
            </div>
          )}
        </Panel>

        {canEdit ? (
          <div className="flex items-center gap-2">
            <Button
              variant="primary"
              size="md"
              icon="save"
              disabled={title.trim() === '' || saving}
              onClick={() => void save()}
            >
              {isNew ? 'Crea il rapporto' : 'Salva le modifiche'}
            </Button>

            {dirty ? <span className="text-label text-warning">Modifiche non salvate</span> : null}
          </div>
        ) : null}
      </SheetBody>

      <InvolvedPicker
        open={pickerOpen}
        onClose={() => setPickerOpen(false)}
        onPick={(citizen, role) => {
          setDirty(true);
          setInvolved((prev) =>
            prev.some((entry) => entry.identifier === citizen.identifier && entry.role === role)
              ? prev
              : [
                  ...prev,
                  {
                    identifier: citizen.identifier,
                    role,
                    firstName: citizen.firstName,
                    lastName: citizen.lastName,
                    ssn: citizen.ssn,
                  },
                ],
          );
          setPickerOpen(false);
        }}
      />

      <ConfirmDialog
        open={confirmDelete}
        title="Elimina il rapporto"
        message="Il rapporto e tutti i suoi collegamenti vengono eliminati. I reati collegati restano nei fascicoli."
        confirmLabel="Elimina"
        onConfirm={() => void remove()}
        onCancel={() => setConfirmDelete(false)}
      />
    </Sheet>
  );
}

export default ReportSheet;
