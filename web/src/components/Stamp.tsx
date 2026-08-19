import Icon, { type IconKey } from './Icon';

/**
 * Timbro del fascicolo (sezione 3.7).
 * La leggera rotazione di -2.5 gradi e' cio' che da' il carattere "fascicolo":
 * va mantenuta.
 */

export type StampTone = 'critical' | 'warning' | 'success' | 'info';

const TONE: Record<StampTone, string> = {
  critical: 'text-critical border-critical bg-critical/10',
  warning: 'text-warning border-warning bg-warning/10',
  success: 'text-success border-success bg-success/10',
  info: 'text-info border-info bg-info/10',
};

interface StampProps {
  label: string;
  icon?: IconKey;
  tone?: StampTone;
  title?: string;
}

export function Stamp({ label, icon = 'wanted', tone = 'critical', title }: StampProps): JSX.Element {
  return (
    <span
      title={title ?? label}
      className={[
        'ml-[0.45rem] inline-flex shrink-0 items-center gap-[0.3rem] rounded-sm border-[1.5px]',
        'px-[0.42rem] py-[0.18rem] text-micro font-bold tracking-[0.09em]',
        '-rotate-[2.5deg]',
        TONE[tone],
      ].join(' ')}
    >
      <Icon name={icon} size="sm" />
      {label}
    </span>
  );
}

export default Stamp;
