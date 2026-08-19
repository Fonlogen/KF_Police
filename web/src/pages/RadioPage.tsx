import { useState } from 'react';
import Sheet, { DataRow, Panel, SheetBody, SheetHeader } from '../components/Sheet';
import Icon from '../components/Icon';
import Button from '../components/Button';
import Chip from '../components/Chip';
import EmptyState from '../components/EmptyState';
import { callMdt } from '../lib/nui';
import { useMdt } from '../state/MdtProvider';
import { num } from '../lib/format';
import type { RadioState } from '../lib/types';

/**
 * Radio.
 * ---------------------------------------------------------------------------
 * Gli endpoint `radio:*` sono gestiti in locale sul client: pma-voice vive li',
 * un giro sul server non servirebbe a niente.
 *
 * Il dock in fondo al telaio resta il comando rapido (i pulsanti CH1..TAC);
 * questa pagina e' il pannello completo: elenco canali, volume e stato.
 */

export function RadioPage(): JSX.Element {
  const { radio, refreshRadio, notify, can } = useMdt();
  const [busy, setBusy] = useState(false);

  const send = async (endpoint: string, payload?: Record<string, unknown>) => {
    setBusy(true);

    const response = await callMdt(endpoint, payload);
    const state = (response as { radio?: RadioState }).radio;

    setBusy(false);

    if (response.message) {
      notify(response.message, response.ok ? 'success' : 'error');
    }

    // La risposta contiene gia' lo stato aggiornato, ma il provider e' la fonte
    // unica: si rilegge da la' cosi' anche il dock si aggiorna.
    if (state || response.ok) refreshRadio();
  };

  if (!can('radio.use')) {
    return (
      <Sheet>
        <SheetHeader title="Radio" />
        <EmptyState
          icon="radio"
          title="Radio non autorizzata"
          hint="Il tuo grado non ha accesso alle frequenze di servizio."
        />
      </Sheet>
    );
  }

  const channels = radio?.channels ?? [];
  const volume = radio?.volume ?? 60;
  const connected = Boolean(radio?.current);

  return (
    <Sheet>
      <SheetHeader
        title="Radio di servizio"
        count={connected ? `CH ${num(radio?.currentNumber ?? 0)}` : 'non connessa'}
        action={{ icon: 'refresh', title: 'Rileggi lo stato', onClick: refreshRadio }}
      />

      <SheetBody>
        <Panel
          title="Stato"
          icon="radio"
          action={
            connected ? (
              <Button variant="danger" icon="close" disabled={busy} onClick={() => void send('radio:leave')}>
                Disconnetti
              </Button>
            ) : null
          }
        >
          <DataRow label="Canale" value={radio?.currentLabel ?? 'Nessuno'} />
          <DataRow
            label="Frequenza"
            value={connected ? num(radio?.currentNumber ?? 0) : '-'}
            numeric
          />
          <DataRow label="In ascolto" value={num(radio?.listeners ?? 0)} numeric />
          <DataRow
            label="Trasmissione"
            value={
              radio?.talking ? (
                <span className="flex items-center gap-2 text-warning">
                  <Icon name="talking" size="lg" />
                  Qualcuno sta parlando
                </span>
              ) : (
                'Silenzio'
              )
            }
          />
        </Panel>

        <Panel title="Canali" icon="list">
          {channels.length === 0 ? (
            <EmptyState icon="radio" title="Nessun canale configurato" />
          ) : (
            channels.map((channel) => (
              <div
                key={channel.id}
                className="flex items-center gap-3 rounded-sm border border-line-soft bg-inset px-3 py-2"
              >
                <span className={channel.connected ? 'text-warning' : 'text-fg-dim'}>
                  <Icon name="radio" size="xl" />
                </span>

                <span className="flex min-w-0 flex-1 flex-col">
                  <b className="truncate text-data font-semibold text-fg-strong">{channel.label}</b>
                  <i className="num truncate text-label not-italic text-fg-muted">
                    {channel.short} - frequenza {num(channel.channel)}
                  </i>
                </span>

                {channel.connected ? <Chip label="Connesso" icon="success" tone="success" /> : null}

                <Button
                  variant={channel.connected ? 'ghost' : 'primary'}
                  icon={channel.connected ? 'close' : 'confirm'}
                  disabled={busy}
                  onClick={() =>
                    void send(channel.connected ? 'radio:leave' : 'radio:join', { channelId: channel.id })
                  }
                >
                  {channel.connected ? 'Esci' : 'Entra'}
                </Button>
              </div>
            ))
          )}
        </Panel>

        <Panel title="Volume" icon="volumeOn">
          <div className="flex items-center gap-3">
            <span className="text-fg-muted">
              <Icon name="volumeOff" size="lg" />
            </span>

            <input
              type="range"
              min={0}
              max={100}
              step={5}
              value={volume}
              disabled={busy}
              onChange={(event) => void send('radio:volume', { volume: Number(event.target.value) })}
              className="min-w-0 flex-1"
            />

            <span className="text-fg-muted">
              <Icon name="volumeOn" size="lg" />
            </span>

            <span className="num w-[3.5rem] shrink-0 text-right text-data font-semibold text-fg-strong">
              {num(volume)}
            </span>
          </div>
        </Panel>
      </SheetBody>
    </Sheet>
  );
}

export default RadioPage;
