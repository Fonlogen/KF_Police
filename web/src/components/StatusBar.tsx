import Icon from './Icon';
import { useMdt } from '../state/MdtProvider';

/**
 * Barra di stato del tablet (sezione 3.7).
 * h 2.25rem, bg-chrome, bordo inferiore line-soft, testo 0.8rem fg-muted,
 * gap 1.15rem tra i gruppi, icone 0.95rem, valori in grassetto fg-chrome 600.
 */

function Group({ children }: { children: React.ReactNode }): JSX.Element {
  return <span className="flex items-center gap-1.5">{children}</span>;
}

export function StatusBar(): JSX.Element {
  const { officer, status } = useMdt();

  return (
    <header className="flex h-statusbar shrink-0 items-center gap-[1.15rem] border-b border-line-soft bg-chrome px-4 text-status text-fg-muted">
      <Group>
        <Icon name="duty" size="lg" />
        <b className="font-semibold tracking-[0.06em] text-fg-chrome">
          {officer ? officer.gradeLabel || officer.jobLabel : 'LSPD'}
        </b>
      </Group>

      <Group>
        <Icon name="location" size="lg" />
        {status.location}
      </Group>

      {officer?.ssn ? <span className="num">SSN {officer.ssn}</span> : null}

      <span className="flex-1" />

      <span
        className={[
          'flex items-center gap-1.5 text-chrome font-semibold',
          officer?.onDuty ? 'text-success' : 'text-fg-dim',
        ].join(' ')}
      >
        <span
          className={[
            'h-[0.45rem] w-[0.45rem] rounded-dot',
            officer?.onDuty ? 'bg-success' : 'bg-fg-dim',
          ].join(' ')}
        />
        {officer?.onDuty ? 'IN SERVIZIO' : 'FUORI SERVIZIO'}
      </span>

      <Group>
        <Icon name="signal" size="lg" />
      </Group>

      <Group>
        <Icon name="clock" size="lg" />
        <span className="num">{status.time}</span>
      </Group>

      {/* Batteria: 1.75rem x 0.85rem, bordo #5C5449, riempimento warning */}
      <span className="flex h-[0.85rem] w-[1.75rem] shrink-0 items-center rounded-[0.15rem] border border-fg-dim p-[2px]">
        <span className="block h-full w-[78%] rounded-[1px] bg-warning" />
      </span>
    </header>
  );
}

export default StatusBar;
