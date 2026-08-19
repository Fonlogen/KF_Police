# modules/voice/cl_pma.lua

**Ruolo:** bridge voce su `pma-voice`. **Contiene la correzione del bug L1** e traccia
chi è in ascolto e chi parla.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, ultimo dei bridge client

## Il bug L1, in dettaglio

In FiveM il metatable degli export espone `function(self, ...)`. Quindi:

```lua
exports['pma-voice']['setRadioChannel'](canale)   -- SBAGLIATO: canale finisce in self
exports['pma-voice']:setRadioChannel(canale)      -- corretto
```

Il vecchio `client/cl_radio.lua` faceva la prima forma: `setRadioChannel` riceveva `nil` e
**la radio non cambiava mai canale**. Qui il self viene passato esplicitamente:

```lua
local handle = exports[exportCfg.resource]
handle[exportCfg.name](handle, table.unpack(args, 1, args.n))
```

che è identico al colon-call. Lo stesso schema è ripetuto in
[sv_fines.lua](../server/sv_fines.md) e nei bridge inventario e target.

## API pubblica

| Funzione | Note |
|---|---|
| `Voice.CallExport(exportCfg, ...)` | motore comune; `false` se la risorsa non è `started`, se la maniglia manca o se il `pcall` fallisce |
| `Voice.Available()` | `Config.Radio.Enabled` **e** risorsa `started` |
| `Voice.SetChannel(channel)` | |
| `Voice.Leave()` | azzera anche `listeners` e `talking` |
| `Voice.SetVolume(volume)` | `ClampInt(volume, 0, 100, 60)` |
| `Voice.SetRadioEnabled(enabled)` | via `setVoiceProperty('radioEnabled', bool)` |
| `Voice.GetListenerCount()` | numero di `listeners` **+ 1** (l'agente stesso) |
| `Voice.GetTalking()` | array di server id |
| `Voice.IsAnyoneTalking()` | `next(talking) ~= nil` |

`CallExport` stampa l'errore solo se `Config.Debug`: un export mancante non riempie la
console.

## Stato ricavato dagli eventi pma-voice

| Evento ascoltato | Effetto |
|---|---|
| `pma-voice:syncRadioData` | ricostruisce da zero `listeners` e `talking` |
| `pma-voice:addPlayerToRadio` | aggiunge a `listeners` |
| `pma-voice:removePlayerFromRadio` | rimuove da `listeners` e `talking` |
| `pma-voice:setTalkingOnRadio` | aggiorna `talking` |

Ogni cambiamento emette `KF_Police:Client:RadioStateChanged`, che
`client/cl_radio.lua` ascolta per fare `PushRadioStateToNui()`. Risultato: il `RadioDock`
del tablet si aggiorna **senza che la NUI interroghi nulla**, e l'istogramma si animano
solo mentre qualcuno parla.

## Note e trappole

- Il conteggio `+1` di `GetListenerCount()` assume che l'agente sia connesso al canale.
  `cl_radio.lua` la chiama solo se `currentChannelId` è valorizzato, quindi il conto è
  corretto; chiamarla fuori da quel contesto darebbe `1` invece di `0`.
- `listeners` e `talking` sono indicizzati per **server id**, non per identifier.
- Se pma-voice non emette gli eventi (versione vecchia o forkata), lo stato resta vuoto:
  il dock mostra "0 in ascolto" e non si anima, ma la radio funziona comunque.
- Questo file **non** fa `return` condizionale: `Voice` esiste sempre, ed è
  `Voice.Available()` a dire se serve a qualcosa.

## Correlati

[config/cfg_radio.md](../config/cfg_radio.md) ·
[client/cl_radio.md](../client/cl_radio.md) ·
[web/components/RadioDock.md](../web/components/RadioDock.md)
