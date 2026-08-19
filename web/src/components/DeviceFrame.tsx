import type { ReactNode } from 'react';
import Icon from './Icon';
import { closeMdt } from '../lib/nui';
import { useMdt } from '../state/MdtProvider';
import { useTabletScale } from '../hooks/useTabletScale';
import ToastStack from './Toast';
import type { FrameInset } from '../lib/types';
import tabletFrame from '../../assets/tablet.png';

/**
 * Telaio del dispositivo (sezione 3.6).
 * ---------------------------------------------------------------------------
 * Due riquadri concentrici:
 *
 *  - quello esterno e' l'ingombro fisico del tablet (`frameWidth/frameHeight`),
 *    ed e' il solo punto del progetto dove si scrivono dei pixel: la misura
 *    arriva dal client, che l'ha calcolata sulla risoluzione reale;
 *  - quello interno e' la schermata utile, posizionata sulla finestra
 *    trasparente del PNG con le percentuali di `frameInset`. Tutto quello che
 *    sta dentro misura in rem, e useTabletScale imposta il font-size della
 *    radice.
 *
 * L'immagine e' stirata sul riquadro esterno (`h-full w-full`, nessun
 * object-fit): il ritaglio combacia con la schermata per costruzione, perche' le
 * percentuali vengono dalle stesse misure con cui il client ha dimensionato il
 * riquadro. Il rapporto del ritaglio non e' identico a quello di progetto,
 * quindi la scocca prende il 2.3% di stiramento verticale: e' voluto, vedi
 * Config.UI.frame.
 *
 * `pointer-events-none` sull'immagine: la scocca copre gli angoli della UI
 * (l'arrotondamento della finestra e' suo, non del CSS) ma non deve intercettare
 * nessun clic.
 *
 * Con `Config.UI.frame.enabled = false` il client non manda `frameInset` e il
 * componente torna al telaio puramente CSS di prima.
 */

/**
 * Ripiego per `npm run dev`, dove `mdt:geometry` non arriva mai. Duplica le
 * misure di `Config.UI.frame`: se si sostituisce il PNG vanno cambiate in
 * entrambi i posti. In gioco questi valori non vengono mai usati.
 *
 * Le misure orizzontali comprendono 1 px di sovrapposizione per lato sotto la
 * scocca: il bordo della finestra e' antialiasato e senza sovrapposizione si
 * vede una cucitura di gioco. La spiegazione completa e' in Config.UI.frame.
 */
const DEV_INSET: FrameInset = {
  left: 59 / 1400,
  top: 93 / 1073,
  width: 1280 / 1400,
  height: 888 / 1073,
};

/** Cornice che contiene una schermata di 1280x910, la dimensione di progetto. */
const DEV_FRAME = {
  width: Math.round(1280 / DEV_INSET.width),
  height: Math.round(910 / DEV_INSET.height),
};

export function DeviceFrame({ children }: { children: ReactNode }): JSX.Element {
  const { geometry, officer, toasts, dismissToast } = useMdt();

  useTabletScale(geometry);

  const inset = geometry ? geometry.frameInset : DEV_INSET;
  const outer = geometry
    ? { width: geometry.frameWidth, height: geometry.frameHeight }
    : DEV_FRAME;

  return (
    <div className="flex h-full w-full items-center justify-center">
      <div
        className="relative"
        style={{ width: `${outer.width}px`, height: `${outer.height}px` }}
      >
        <div
          data-dept={officer?.job ?? 'police'}
          style={
            inset
              ? {
                  left: `${inset.left * 100}%`,
                  top: `${inset.top * 100}%`,
                  width: `${inset.width * 100}%`,
                  height: `${inset.height * 100}%`,
                }
              : { left: 0, top: 0, width: '100%', height: '100%' }
          }
          className={
            inset
              ? 'absolute flex flex-col overflow-hidden rounded-lg bg-shell font-ui text-fg'
              : 'absolute flex flex-col overflow-hidden rounded-lg bg-shell font-ui text-fg shadow-2xl'
          }
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

        {inset ? (
          <img
            src={tabletFrame}
            alt=""
            aria-hidden="true"
            draggable={false}
            className="pointer-events-none absolute inset-0 z-40 h-full w-full select-none drop-shadow-2xl"
          />
        ) : null}
      </div>
    </div>
  );
}

export default DeviceFrame;
