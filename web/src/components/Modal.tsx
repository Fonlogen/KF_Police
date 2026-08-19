import type { ReactNode } from 'react';
import { useEffect } from 'react';
import Icon from './Icon';
import Button from './Button';

/**
 * Modale che SOSTITUISCE Dialog.tsx (bug U7).
 * ---------------------------------------------------------------------------
 * Il vecchio componente copiava la prop `show` in uno `useState` che non
 * risincronizzava mai, e la X di chiusura non aveva handler: di fatto era
 * inutilizzabile ed era commentato in App.tsx. Qui lo stato e' interamente
 * controllato dalle props e la chiusura funziona (X, Esc, click sullo sfondo).
 *
 * La modale vive DENTRO il telaio del tablet, non a schermo pieno.
 */

interface ModalProps {
  open: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  width?: 'sm' | 'md' | 'lg';
}

const WIDTH: Record<'sm' | 'md' | 'lg', string> = {
  sm: 'w-[22rem]',
  md: 'w-[32rem]',
  lg: 'w-[44rem]',
};

export function Modal({ open, title, onClose, children, footer, width = 'md' }: ModalProps): JSX.Element | null {
  // Listener registrato in useEffect con cleanup: mai nel corpo del render
  // (era la causa del memory leak U1).
  useEffect(() => {
    if (!open) return undefined;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        onClose();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="absolute inset-0 z-40 flex items-center justify-center bg-black/55"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div
        className={[
          'flex max-h-[85%] flex-col overflow-hidden rounded-lg border border-line bg-sheet shadow-2xl',
          WIDTH[width],
        ].join(' ')}
      >
        <header className="flex h-sheethead shrink-0 items-center gap-3 border-b border-dashed border-line-perf px-4">
          <h3 className="min-w-0 flex-1 truncate text-section font-bold tracking-[-0.01em] text-fg-strong">
            {title}
          </h3>
          <button
            type="button"
            title="Chiudi"
            onClick={onClose}
            className="flex h-target w-target items-center justify-center rounded-sm border border-line-ctrl bg-control text-fg-muted hover:text-critical"
          >
            <Icon name="close" size="lg" />
          </button>
        </header>

        <div className="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-4 py-4">{children}</div>

        {footer ? (
          <footer className="flex shrink-0 items-center justify-end gap-2 border-t border-line-soft px-4 py-3">
            {footer}
          </footer>
        ) : null}
      </div>
    </div>
  );
}

/** Conferma per le azioni distruttive. Il pulsante rosso e' l'unico primario. */
export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Conferma',
  onConfirm,
  onCancel,
}: {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
}): JSX.Element | null {
  return (
    <Modal
      open={open}
      title={title}
      onClose={onCancel}
      width="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onCancel}>
            Annulla
          </Button>
          <Button variant="danger" icon="confirm" onClick={onConfirm}>
            {confirmLabel}
          </Button>
        </>
      }
    >
      <p className="text-card leading-relaxed text-fg">{message}</p>
    </Modal>
  );
}

export default Modal;
