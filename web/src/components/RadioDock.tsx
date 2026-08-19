import { useEffect } from 'react';
import Icon from './Icon';
import { callMdt } from '../lib/nui';
import { useMdt } from '../state/MdtProvider';
import { num } from '../lib/format';

/**
 * RadioDock (sezione 3.7) - fisso nel telaio, in fondo al fascicolo.
 * Sostituisce l'overlay separato di BottomButtons.tsx: la radio non e' piu' una
 * schermata a parte.
 *
 * h 3rem, bg-chrome, bordo #262019 (line-perf), r-md, padding 0 0.9rem,
 * gap 0.75rem, margine 0.65rem 1rem 0.8rem.
 * L'istogramma di 5 barre e' animato solo quando qualcuno sta parlando.
 */

const BAR_HEIGHTS = ['30%', '65%', '100%', '48%', '80%'];
const BAR_DELAYS = ['0s', '0.12s', '0.24s', '0.08s', '0.18s'];

export function RadioDock(): JSX.Element | null {
  const { radio, refreshRadio, notify, can } = useMdt();

  // Stato iniziale: il client risponde in locale, senza passare dal server.
  useEffect(() => {
    refreshRadio();
  }, [refreshRadio]);

  if (!can('radio.use')) {
    return null;
  }

  const connected = Boolean(radio?.current);

  const toggle = async (channelId: string) => {
    const response = await callMdt('radio:join', { channelId });

    if (response.message) {
      notify(response.message, response.ok ? 'success' : 'error');
    }

    refreshRadio();
  };

  return (
    <div className="shrink-0 px-4 pb-[0.8rem] pt-[0.65rem]">
      <div className="flex h-radiodock items-center gap-3 rounded-md border border-line-perf bg-chrome px-[0.9rem]">
        <span className={connected ? 'text-warning' : 'text-fg-dim'}>
          <Icon name="radio" size="2xl" />
        </span>

        <span className="min-w-0">
          <b className="block truncate text-card font-semibold leading-tight text-fg-strong">
            {radio?.currentLabel ?? 'Radio non connessa'}
          </b>
          <i className={['block truncate text-label not-italic', connected ? 'text-warning' : 'text-fg-dim'].join(' ')}>
            {connected
              ? `CH ${num(radio?.currentNumber ?? 0)} - ${num(radio?.listeners ?? 0)} in ascolto`
              : 'Seleziona un canale'}
          </i>
        </span>

        {/* Istogramma: animato solo mentre qualcuno parla */}
        <span className="flex h-[1.15rem] shrink-0 items-end gap-[0.14rem]">
          {BAR_HEIGHTS.map((height, index) => (
            <i
              key={index}
              className={[
                'block w-[0.2rem] rounded-[1px]',
                connected ? 'bg-warning' : 'bg-fg-dim',
                radio?.talking ? 'kf-wave-bar' : '',
              ].join(' ')}
              style={{ height, animationDelay: BAR_DELAYS[index] }}
            />
          ))}
        </span>

        <span className="flex-1" />

        <span className="flex shrink-0 gap-[0.3rem]">
          {(radio?.channels ?? []).map((channel) => (
            <button
              key={channel.id}
              type="button"
              title={channel.label}
              onClick={() => void toggle(channel.id)}
              className={[
                'flex h-8 items-center rounded-sm border px-[0.7rem] text-status font-semibold',
                'transition-colors duration-100',
                channel.connected
                  ? 'border-warning bg-warning/15 text-fg-strong'
                  : 'border-line-perf bg-tab text-fg-muted hover:text-fg',
              ].join(' ')}
            >
              {channel.short}
            </button>
          ))}
        </span>
      </div>
    </div>
  );
}

export default RadioDock;
