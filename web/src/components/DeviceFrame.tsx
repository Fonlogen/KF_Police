import type { ReactNode } from 'react';
import Icon from './Icon';
import { closeMdt } from '../lib/nui';
import { useMdt } from '../state/MdtProvider';
import { useTabletScale } from '../hooks/useTabletScale';
import ToastStack from './Toast';

/**
 * Telaio del dispositivo (sezione 3.6).
 * r-lg, bg-shell, overflow-hidden. La dimensione arriva dal client
 * (ComputeTabletGeometry) e non e' mai scritta in pixel nel componente: qui si
 * applica solo il valore ricevuto, e useTabletScale imposta il font-size della
 * radice da cui dipendono tutte le misure in rem.
 */
export function DeviceFrame({ children }: { children: ReactNode }): JSX.Element {
  const { geometry, officer, toasts, dismissToast } = useMdt();

  useTabletScale(geometry);

  return (
    <div className="flex h-full w-full items-center justify-center">
      <div
        data-dept={officer?.job ?? 'police'}
        style={
          geometry
            ? { width: `${geometry.width}px`, height: `${geometry.height}px` }
            : // In browser (npm run dev) si usa la dimensione logica di progetto.
              { width: '1280px', height: '910px' }
        }
        className="relative flex flex-col overflow-hidden rounded-lg bg-shell font-ui text-fg shadow-2xl"
      >
        <button
          type="button"
          title="Chiudi (ESC)"
          onClick={closeMdt}
          className="absolute right-3 top-[0.45rem] z-30 flex h-[1.4rem] w-[1.4rem] items-center justify-center rounded-sm text-fg-dim hover:text-critical"
        >
          <Icon name="close" size="sm" />
        </button>

        <ToastStack items={toasts} onDismiss={dismissToast} />

        {children}
      </div>
    </div>
  );
}

export default DeviceFrame;
