import Icon, { type IconKey } from './Icon';

/** Stato vuoto: compare al posto della tabella quando non ci sono risultati. */
export function EmptyState({
  icon = 'empty',
  title,
  hint,
}: {
  icon?: IconKey;
  title: string;
  hint?: string;
}): JSX.Element {
  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 px-6 py-10 text-center">
      <span className="flex h-12 w-12 items-center justify-center rounded-md bg-raised text-fg-dim">
        <Icon name={icon} size="2xl" />
      </span>
      <p className="text-data font-semibold text-fg-strong">{title}</p>
      {hint ? <p className="max-w-[28rem] text-card text-fg-muted">{hint}</p> : null}
    </div>
  );
}

export default EmptyState;
