# client/cl_radio.lua

**Ruolo:** radio: stato, connessione ai canali, endpoint locali `radio:*` per la NUI.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_actions_vehicle.lua`

## Cosa fa

Il pannello radio vive **dentro il tablet** (`RadioDock` nel telaio + pagina Radio): non
c'è più un overlay separato. Le chiamate a pma-voice passano da
[modules/voice/cl_pma.lua](../modules/voice-cl_pma.md), che usa il colon-call corretto
(bug L1).

Stato locale: `currentChannelId`, `radioReady`, `volume`.

## API pubblica

| Funzione | Ritorna |
|---|---|
| `GetAvailableRadioChannels()` | canali che il lavoro e il grado consentono, con `connected` |
| `GetRadioState()` | stato completo per la NUI |
| `PushRadioStateToNui()` | `SendNUIMessage({ action = 'mdt:radio', ... })`, solo se il tablet è aperto |
| `JoinPoliceRadio(channelId)` | `ok, chiaveMessaggio` |
| `LeavePoliceRadio()` | |

`GetRadioState()` compone: `enabled` (config **e** `Voice.Available()`), `current`,
`currentLabel`, `currentNumber`, `channels`, `volume`, `listeners`
(`Voice.GetListenerCount()`), `talking` (`Voice.IsAnyoneTalking()`).

### `JoinPoliceRadio`, in ordine

1. `Config.Radio.Enabled` → `radio_disabled`
2. `Voice.Available()` → `radio_unavailable`
3. `hasRadioItem()` → `radio_no_item` (solo se `RequireItem`)
4. canale esistente e `canUseChannel` → `radio_not_allowed`
5. **stesso canale già connesso** → esce (toggle) e ritorna `radio_disconnected`
6. alla prima connessione: `Voice.SetRadioEnabled(true)` + `Voice.SetVolume(...)`
7. `Voice.SetChannel(...)` → `radio_unavailable` se l'export fallisce

`canUseChannel(channel)` verifica che il lavoro sia in `channel.jobs` e che
`grade >= channel.minGrade`.

## Endpoint locali

Registrati con `RegisterLocalMdtEndpoint`: **non fanno un giro sul server**, perché
pma-voice vive sul client.

| Endpoint | Payload | Ritorna |
|---|---|---|
| `radio:state` | — | `{ ok, radio }` |
| `radio:join` | `channelId` | `{ ok, message, radio }`, e notifica |
| `radio:leave` | — | `{ ok, radio }` |
| `radio:volume` | `volume` | `{ ok, radio }`; `ClampInt(0, 100, 60)` |

## Sincronizzazione

`KF_Police:Client:RadioStateChanged` (emesso da `cl_pma.lua` a ogni evento pma-voice)
→ `PushRadioStateToNui()`. Il dock si aggiorna **senza che la NUI interroghi nulla**: chi
entra, chi esce, chi parla.

| Altro evento | Azione |
|---|---|
| `KF_Police:Client:LeaveRadio` | uscita forzata (fine servizio) |
| `esx:setJob` | se il lavoro nuovo non è autorizzato, esce dal canale |
| `onResourceStop` | esce dal canale |

## Note e trappole

- **Il controllo di `jobs`/`minGrade` è client-side.** Gli endpoint sono locali, quindi il
  server non li valida. Non è un buco grave (il canale lo impone pma-voice) ma non è una
  validazione autorevole.
- `radioReady` fa impostare volume e `radioEnabled` **una sola volta per sessione**: un
  cambio volume prima della prima connessione viene applicato solo da `radio:volume`.
- `volume` locale parte da `nil` e ripiega su `Config.Radio.DefaultVolume`: non è
  persistito, ogni ricarica del client lo azzera.
- `Config.Radio.UseAnims` è dichiarata e **non usata**: non c'è animazione della radio.
- La pagina Radio del MDT (`RadioPage`) **non è ancora scritta**: oggi la radio si usa solo
  dal `RadioDock`, che è sempre visibile in fondo al tablet.

## Correlati

[config/cfg_radio.md](../config/cfg_radio.md) ·
[modules/voice-cl_pma.md](../modules/voice-cl_pma.md) ·
[web/components/RadioDock.md](../web/components/RadioDock.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)
