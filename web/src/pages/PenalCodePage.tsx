import { useCallback, useEffect, useMemo, useState } from 'react';
import Sheet, { Panel, SheetBody, SheetHeader } from '../components/Sheet';
import Button, { IconButton } from '../components/Button';
import Chip from '../components/Chip';
import Modal, { ConfirmDialog } from '../components/Modal';
import EmptyState from '../components/EmptyState';
import { SkeletonRows } from '../components/Skeleton';
import { Checkbox, NumberField, SelectField, TextArea, TextField } from '../components/Field';
import { callMdt } from '../lib/nui';
import { useRevisionEffect } from '../hooks/useRevisionEffect';
import { useMdt } from '../state/MdtProvider';
import { money, months as monthsLabel, num } from '../lib/format';
import type { PenalArticle, PenalCategory } from '../lib/types';

/**
 * Codice penale.
 * ---------------------------------------------------------------------------
 * Una sola fonte per reati e multe: le 52 `fine_types` di esx_policejob sono
 * state riversate qui come articoli con la loro categoria. `fine` e
 * `jail_months` sono colonne numeriche, non stringhe da cui riestrarre
 * l'importo con una regex (bug L10).
 */

interface Draft {
  id?: number;
  code: string;
  categoryId: number;
  title: string;
  description: string;
  fine: number;
  jailMonths: number;
  isFelony: boolean;
}

const EMPTY_DRAFT: Draft = {
  code: '',
  categoryId: 0,
  title: '',
  description: '',
  fine: 0,
  jailMonths: 0,
  isFelony: false,
};

function ArticleRow({
  article,
  canEdit,
  onEdit,
  onDelete,
}: {
  article: PenalArticle;
  canEdit: boolean;
  onEdit: () => void;
  onDelete: () => void;
}): JSX.Element {
  return (
    <div className="flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2">
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <div className="flex min-w-0 items-baseline gap-2">
          {article.code ? <span className="num shrink-0 text-label text-fg-dim">{article.code}</span> : null}
          <span className="min-w-0 truncate text-data font-semibold text-fg-strong">{article.title}</span>
          {article.isFelony ? <Chip label="Grave" icon="warning" tone="critical" /> : null}
        </div>

        {article.description ? (
          <span className="truncate text-label text-fg-muted">{article.description}</span>
        ) : null}
      </div>

      <span className="num shrink-0 text-data font-semibold text-fg">{money(article.fine)}</span>

      <span className="num w-[6rem] shrink-0 text-right text-status text-warning">
        {monthsLabel(article.jailMonths)}
      </span>

      {canEdit ? (
        <>
          <IconButton icon="edit" variant="ghost" title="Modifica l'articolo" onClick={onEdit} />
          <IconButton icon="delete" variant="danger" title="Elimina l'articolo" onClick={onDelete} />
        </>
      ) : null}
    </div>
  );
}

export function PenalCodePage(): JSX.Element {
  const { can, notify, revision } = useMdt();

  const [categories, setCategories] = useState<PenalCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const [draft, setDraft] = useState<Draft | null>(null);
  const [toDelete, setToDelete] = useState<PenalArticle | null>(null);

  const canEdit = can('mdt.penalcode.edit');

  const load = useCallback(async () => {
    const response = await callMdt('penalcode:list');
    const payload = response as { categories?: PenalCategory[] };

    setCategories(response.ok ? (payload.categories ?? []) : []);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  useRevisionEffect([revision.penalcode], () => void load());

  const filtered = useMemo(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return categories;

    return categories
      .map((category) => ({
        ...category,
        articles: category.articles.filter(
          (article) =>
            article.title.toLowerCase().includes(needle) ||
            article.description.toLowerCase().includes(needle) ||
            (article.code ?? '').toLowerCase().includes(needle),
        ),
      }))
      .filter((category) => category.articles.length > 0);
  }, [categories, search]);

  const total = useMemo(
    () => categories.reduce((sum, category) => sum + category.articles.length, 0),
    [categories],
  );

  const categoryOptions = useMemo(
    () => [
      { value: 0, label: 'Senza categoria' },
      ...categories.filter((category) => category.id > 0).map((category) => ({
        value: category.id,
        label: category.label,
      })),
    ],
    [categories],
  );

  const save = async () => {
    if (!draft || draft.title.trim() === '') return;

    const response = await callMdt('penalcode:save', {
      id: draft.id,
      code: draft.code,
      categoryId: draft.categoryId > 0 ? draft.categoryId : undefined,
      title: draft.title,
      description: draft.description,
      fine: draft.fine,
      jailMonths: draft.jailMonths,
      isFelony: draft.isFelony,
    });

    setDraft(null);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) void load();
  };

  const remove = async () => {
    if (!toDelete) return;

    const response = await callMdt('penalcode:delete', { id: toDelete.id });
    setToDelete(null);

    if (response.message ?? response.error) {
      notify((response.message ?? response.error) as string, response.ok ? 'success' : 'error');
    }

    if (response.ok) void load();
  };

  return (
    <Sheet>
      <SheetHeader
        title="Codice penale"
        count={`${num(total)} articoli`}
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Articolo o codice..."
        action={
          canEdit
            ? { icon: 'add', title: 'Nuovo articolo', onClick: () => setDraft({ ...EMPTY_DRAFT }) }
            : { icon: 'refresh', title: 'Ricarica', onClick: () => void load() }
        }
      />

      <SheetBody>
        {loading ? (
          <SkeletonRows rows={8} />
        ) : filtered.length === 0 ? (
          <EmptyState
            icon="penalcode"
            title="Nessun articolo"
            hint={search ? 'Nessun risultato per questa ricerca.' : 'Il codice penale e vuoto.'}
          />
        ) : (
          filtered.map((category) => (
            <Panel
              key={category.id}
              title={`${category.label} (${num(category.articles.length)})`}
              icon={category.icon}
            >
              {category.articles.map((article) => (
                <ArticleRow
                  key={article.id}
                  article={article}
                  canEdit={canEdit}
                  onEdit={() =>
                    setDraft({
                      id: article.id,
                      code: article.code ?? '',
                      categoryId: article.categoryId ?? 0,
                      title: article.title,
                      description: article.description,
                      fine: article.fine,
                      jailMonths: article.jailMonths,
                      isFelony: article.isFelony,
                    })
                  }
                  onDelete={() => setToDelete(article)}
                />
              ))}
            </Panel>
          ))
        )}
      </SheetBody>

      <Modal
        open={draft !== null}
        title={draft?.id ? 'Modifica articolo' : 'Nuovo articolo'}
        onClose={() => setDraft(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setDraft(null)}>
              Annulla
            </Button>
            <Button
              variant="primary"
              icon="save"
              disabled={!draft || draft.title.trim() === ''}
              onClick={() => void save()}
            >
              Salva
            </Button>
          </>
        }
      >
        {draft ? (
          <>
            <div className="flex flex-wrap gap-3">
              <span className="w-[8rem] shrink-0">
                <TextField
                  value={draft.code}
                  onChange={(value) => setDraft({ ...draft, code: value })}
                  label="Codice"
                  numeric
                  maxLength={16}
                />
              </span>

              <span className="min-w-0 flex-1">
                <SelectField
                  value={draft.categoryId}
                  onChange={(value) => setDraft({ ...draft, categoryId: Number(value) })}
                  options={categoryOptions}
                  label="Categoria"
                />
              </span>
            </div>

            <TextField
              value={draft.title}
              onChange={(value) => setDraft({ ...draft, title: value })}
              label="Titolo"
              maxLength={150}
            />

            <TextArea
              value={draft.description}
              onChange={(value) => setDraft({ ...draft, description: value })}
              label="Descrizione"
              rows={4}
              maxLength={500}
            />

            <div className="flex gap-3">
              <span className="min-w-0 flex-1">
                <NumberField
                  value={draft.fine}
                  onChange={(value) => setDraft({ ...draft, fine: value })}
                  label="Multa"
                  min={0}
                />
              </span>
              <span className="min-w-0 flex-1">
                <NumberField
                  value={draft.jailMonths}
                  onChange={(value) => setDraft({ ...draft, jailMonths: value })}
                  label="Mesi di carcere"
                  min={0}
                />
              </span>
            </div>

            <Checkbox
              checked={draft.isFelony}
              onChange={(value) => setDraft({ ...draft, isFelony: value })}
              label="Reato grave"
            />
          </>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={toDelete !== null}
        title="Elimina l'articolo"
        message={`"${toDelete?.title ?? ''}" viene rimosso dal codice penale. I reati gia' contestati conservano il testo: lo storico non cambia.`}
        confirmLabel="Elimina"
        onConfirm={() => void remove()}
        onCancel={() => setToDelete(null)}
      />
    </Sheet>
  );
}

export default PenalCodePage;
