import Icon, { type IconKey } from './Icon';

/**
 * Controllo segmentato dell'intestazione del foglio (sezione 3.7).
 * Sotto i 1100 px logici collassa a sole icone: è parte della correzione n. 2
 * che impedisce all'intestazione di andare a capo.
 */

export interface Segment<T extends string> {
  value: T;
  label: string;
  icon: IconKey;
}

export function SegmentedControl<T extends string>({
  value,
  segments,
  onChange,
  iconOnly,
}: {
  value: T;
  segments: Segment<T>[];
  onChange: (value: T) => void;
  iconOnly?: boolean;
}): JSX.Element {
  return (
    <div className="flex h-field shrink-0 overflow-hidden rounded-sm border border-line-perf">
      {segments.map((segment) => {
        const active = segment.value === value;

        return (
          <button
            key={segment.value}
            type="button"
            title={segment.label}
            onClick={() => onChange(segment.value)}
            className={[
              'flex items-center gap-2 whitespace-nowrap text-status transition-colors duration-100',
              iconOnly ? 'w-field justify-center' : 'px-[0.8rem]',
              active ? 'bg-accent font-semibold text-white' : 'font-medium text-fg-muted hover:bg-hover',
            ].join(' ')}
          >
            <Icon name={segment.icon} size="lg" />
            {iconOnly ? null : segment.label}
          </button>
        );
      })}
    </div>
  );
}

export default SegmentedControl;
