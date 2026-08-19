import { useEffect } from 'react';
import Icon, { type IconKey } from './Icon';

/**
 * Notifiche dentro il tablet.
 * Il server e le azioni di campo mandano `mdt:notify`: la notifica compare nel
 * telaio, non come notifica di gioco sopra il tablet.
 */

export type ToastTone = 'inform' | 'success' | 'error' | 'warning';

export interface ToastItem {
  id: number;
  message: string;
  type: ToastTone;
}

const TONE: Record<ToastTone, { className: string; icon: IconKey }> = {
  inform: { className: 'border-info text-info', icon: 'info' },
  success: { className: 'border-success text-success', icon: 'success' },
  error: { className: 'border-critical text-critical', icon: 'error' },
  warning: { className: 'border-warning text-warning', icon: 'warning' },
};

function Toast({ item, onDone }: { item: ToastItem; onDone: (id: number) => void }): JSX.Element {
  useEffect(() => {
    const timer = window.setTimeout(() => onDone(item.id), 4000);
    return () => window.clearTimeout(timer);
  }, [item.id, onDone]);

  const tone = TONE[item.type] ?? TONE.inform;

  return (
    <div
      className={[
        'kf-toast flex max-w-[24rem] items-center gap-2.5 rounded-sm border-l-2 border-y border-r',
        'border-y-line border-r-line bg-raised px-3 py-2.5 text-card shadow-lg',
        tone.className,
      ].join(' ')}
    >
      <Icon name={tone.icon} size="lg" />
      <span className="min-w-0 flex-1 text-fg">{item.message}</span>
      <button
        type="button"
        title="Chiudi"
        onClick={() => onDone(item.id)}
        className="text-fg-dim hover:text-fg"
      >
        <Icon name="close" size="xs" />
      </button>
    </div>
  );
}

export function ToastStack({
  items,
  onDismiss,
}: {
  items: ToastItem[];
  onDismiss: (id: number) => void;
}): JSX.Element {
  return (
    <div className="pointer-events-none absolute right-4 top-[3rem] z-50 flex flex-col items-end gap-2">
      {items.map((item) => (
        <div key={item.id} className="pointer-events-auto">
          <Toast item={item} onDone={onDismiss} />
        </div>
      ))}
    </div>
  );
}

export default ToastStack;
