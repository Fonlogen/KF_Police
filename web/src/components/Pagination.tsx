import Icon from './Icon';
import { num } from '../lib/format';

/** Paginazione: nessuna lista viene mai caricata per intero (sezione 6). */
export function Pagination({
  page,
  pageSize,
  total,
  onChange,
}: {
  page: number;
  pageSize: number;
  total: number;
  onChange: (page: number) => void;
}): JSX.Element | null {
  const pages = Math.max(1, Math.ceil(total / Math.max(1, pageSize)));

  if (total <= pageSize) {
    return null;
  }

  const from = (page - 1) * pageSize + 1;
  const to = Math.min(total, page * pageSize);

  return (
    <div className="flex h-thead shrink-0 items-center gap-3 border-t border-line-soft px-4">
      <span className="num text-label text-fg-muted">
        {num(from)}-{num(to)} di {num(total)}
      </span>

      <span className="flex-1" />

      <button
        type="button"
        title="Pagina precedente"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
        className="flex h-target w-target items-center justify-center rounded-sm border border-line-ctrl bg-control text-info disabled:opacity-30"
      >
        <Icon name="collapse" size="md" />
      </button>

      <span className="num text-status text-fg">
        {num(page)} / {num(pages)}
      </span>

      <button
        type="button"
        title="Pagina successiva"
        disabled={page >= pages}
        onClick={() => onChange(page + 1)}
        className="flex h-target w-target items-center justify-center rounded-sm border border-line-ctrl bg-control text-info disabled:opacity-30"
      >
        <Icon name="open" size="md" />
      </button>
    </div>
  );
}

export default Pagination;
