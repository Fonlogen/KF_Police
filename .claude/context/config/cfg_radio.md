# config/cfg_radio.lua

**Ruolo:** canali radio pma-voice, export usati, suoni.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

### `Config.Radio`

| Chiave | Valore | Effetto |
|---|---|---|
| `Enabled` | `true` | |
| `Resource` | `'pma-voice'` | verificata con `GetResourceState` |
| `RequireItem` | `false` | con `true` serve l'item `radio` in inventario |
| `DefaultVolume` | `60` | |
| `DisconnectOnClose` | `false` | chiudere il tablet **non** stacca la radio |
| `DisconnectOnDutyEnd` | `true` | uscire dal servizio stacca la radio |
| `UseAnims` | `true` | dichiarata, non ancora consumata |

### `Config.Radio.Exports`

Gli export di pma-voice descritti come `{ resource, name }`:

| Chiave | Export |
|---|---|
| `setChannel` | `pma-voice:setRadioChannel` |
| `leave` | `pma-voice:removePlayerFromRadio` |
| `setVolume` | `pma-voice:setRadioVolume` |
| `setProperty` | `pma-voice:setVoiceProperty` |

**Vengono chiamati con il colon-call corretto** da `modules/voice/cl_pma.lua`: è la
correzione del bug L1. Vedi quel documento per il dettaglio.

### `Config.Radio.Sounds`

`Connect`, `Disconnect`, `Click` con `{ dict, name, volume }`. Suonati da
`client/cl_radio.lua` con `PlaySoundFrontend`.

### `Config.Radio.Channels`

Cinque canali, ognuno `{ id, label, short, channel, jobs, minGrade }`:

| `id` | `short` | Freq. | Lavori | Grado min. |
|---|---|---|---|---|
| `lspd_main` | `CH1` | 1 | police | 0 |
| `lspd_tac` | `CH2` | 2 | police | 2 |
| `lspd_cmd` | `CH3` | 3 | police | 4 |
| `ems_main` | `EMS` | 4 | ambulance | 0 |
| `shared` | `TAC` | 5 | police, ambulance | 0 |

- `channel` è la frequenza numerica passata a pma-voice.
- `short` è l'etichetta corta dei pulsanti del `RadioDock` in fondo al tablet.
- `jobs` + `minGrade` sono filtrati da `canUseChannel()` in `client/cl_radio.lua`.

## Note e trappole

- La radio è **interamente lato client**: gli endpoint `radio:*` sono registrati con
  `RegisterLocalMdtEndpoint` e non fanno un giro sul server. Conseguenza: il controllo di
  `jobs`/`minGrade` è client-side. Non è un buco di sicurezza grave (il canale lo impone
  pma-voice), ma non è una validazione autorevole.
- `short` deve stare in pochi caratteri: il pulsante del dock non va a capo.
- Se pma-voice non è avviato, `Voice.Available()` è falso e `JoinPoliceRadio` ritorna
  `radio_unavailable`: la UI mostra il dock spento, non si rompe.

## Correlati

[modules/voice-cl_pma.md](../modules/voice-cl_pma.md) ·
[client/cl_radio.md](../client/cl_radio.md) ·
[web/components/RadioDock.md](../web/components/RadioDock.md)
