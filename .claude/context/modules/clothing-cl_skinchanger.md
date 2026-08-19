# modules/clothing/cl_skinchanger.lua

**Ruolo:** bridge vestiario su `skinchanger` / `esx_skin`. Ripiego.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_appearance.lua`
**Attivo se:** `Config.Clothing == 'skinchanger'`

## Cosa fa

Stesso contratto di [cl_appearance.lua](clothing-cl_appearance.md), ma **senza
traduzione**: le chiavi di `Config.Uniforms` sono già quelle native di skinchanger.

| Funzione | Implementazione |
|---|---|
| `Available()` | `GetResourceState('skinchanger') == 'started'` |
| `Snapshot()` | `TriggerEvent('skinchanger:getSkin', cb)` **reso sincrono** con attesa fino a 1 s |
| `Apply(components)` | `TriggerEvent('skinchanger:loadClothes', nil, components)` |
| `Restore(snapshot)` | `TriggerEvent('skinchanger:loadSkin', snapshot)` |
| `SaveCivilian()` | snapshot → KVP `kf_police:civilian_outfit` |
| `RestoreCivilian()` | dal KVP; **se manca**, ricade su `esx_skin:loadDefaultSkin` |
| `HasCivilian()` / `ClearCivilian()` | lettura e cancellazione del KVP |

### Lo snapshot sincrono

`skinchanger:getSkin` è basato su callback. Qui viene atteso con un ciclo:

```lua
local timeout = GetGameTimer() + 1000
while not done and GetGameTimer() < timeout do Wait(0) end
```

Se scade, `Snapshot()` ritorna `nil` e `SaveCivilian()` ritorna `false`: l'abito civile
non viene salvato e l'uscita dalla divisa userà il ripiego `esx_skin`.

## Note e trappole

- `Wait(0)` in un ciclo di attesa è accettabile solo perché il timeout è 1 s. Non
  estenderlo: bloccherebbe il thread client.
- Il ripiego su `esx_skin:loadDefaultSkin` è una **rete di sicurezza specifica di questo
  bridge**: `cl_appearance.lua` non ce l'ha, perché fivem-appearance non ha un equivalente
  diretto.
- **Non è il bridge attivo** nella configurazione corrente
  (`Config.Clothing = 'fivem-appearance'`): fa `return` in cima.
- La chiave KVP è la **stessa** dei due bridge. Cambiando `Config.Clothing` a server
  avviato, il KVP scritto da un bridge viene letto dall'altro in un formato che non
  capisce: `Restore` non fa nulla di visibile. Cambiare bridge richiede un
  `Clothing.ClearCivilian()`.

## Correlati

[modules/clothing-cl_appearance.md](clothing-cl_appearance.md) ·
[config/cfg_duty.md](../config/cfg_duty.md)
