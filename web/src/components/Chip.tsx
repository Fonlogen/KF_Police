import Icon, { type IconKey } from './Icon';

/** Chip: etichetta compatta, cliccabile o statica. Bersaglio >= 2.25rem. */

export type ChipTone = 'neutral' | 'accent' | 'critical' | 'warning' | 'success' | 'info';

const TONE: Record<ChipTone, string> = {
  neutral: 'bg-control text-fg border-line-ctrl',
  accent: 'bg-accent text-white border-accent',
  critical: 'bg-critical/10 text-critical border-critical',
  warning: 'bg-warning/10 text-warning border-warning',
  success: 'bg-success/10 text-success border-success',
  info: 'bg-info/10 text-info border-info',
};

interface ChipProps {
  label: string;
  icon?: IconKey | string;
  tone?: ChipTone;
  color?: string;
  onClick?: () => void;
  onRemove?: () => void;
  selected?: boolean;
  title?: string;
}

export function Chip({
  label,
  icon,
  tone = 'neutral',
  color,
  onClick,
  onRemove,
  selected,
  title,
}: ChipProps): JSX.Element {
  const interactive = Boolean(onClick);

  // Il colore dei tag arriva dal database: e' un dato, non un valore di stile
  // scritto nel componente, quindi passa da style e non da una classe.
  const custom = color
    ? { borderColor: color, color, backgroundColor: `${color}1A` }
    : undefined;

  const Element = interactive ? 'button' : 'span';

  return (
    <Element
      {...(interactive ? { type: 'button' as const, onClick } : {})}
      title={title ?? label}
      style={custom}
      className={[
        'inline-flex h-target min-w-0 shrink-0 items-center gap-2 rounded-sm border px-2.5',
        'text-status font-medium',
        custom ? '' : TONE[selected ? 'accent' : tone],
        interactive ? 'transition-colors duration-100 hover:brightness-125' : '',
      ].join(' ')}
    >
      {icon ? <Icon name={icon} size="lg" /> : null}
      <span className="truncate">{label}</span>
      {onRemove ? (
        <button
          type="button"
          title="Rimuovi"
          onClick={(event) => {
            event.stopPropagation();
            onRemove();
          }}
          className="text-fg-dim hover:text-critical"
        >
          <Icon name="close" size="xs" />
        </button>
      ) : null}
    </Element>
  );
}

export default Chip;
