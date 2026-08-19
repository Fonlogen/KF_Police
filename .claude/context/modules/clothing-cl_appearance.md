# modules/clothing/cl_appearance.lua

**Ruolo:** bridge vestiario su `fivem-appearance`. Traduce le divise skinchanger negli
indici nativi GTA.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, fra i bridge client
**Attivo se:** `Config.Clothing == 'fivem-appearance'`

## Contratto

Implementato anche da [cl_skinchanger.lua](clothing-cl_skinchanger.md):

```lua
Clothing.Available()        -> boolean
Clothing.Snapshot()         -> table|nil   (abbigliamento attuale)
Clothing.Apply(components)              (chiavi skinchanger)
Clothing.Restore(snapshot)  -> boolean
Clothing.SaveCivilian()     -> boolean    (memorizza su KVP)
Clothing.RestoreCivilian()  -> boolean
Clothing.HasCivilian()      -> boolean
Clothing.ClearCivilian()
```

## Cosa fa

`Config.Uniforms` (in `config/cfg_duty.lua`) usa le **chiavi skinchanger**
(`tshirt_1`, `torso_1`, `pants_2`, `helmet_1`, ...). `fivem-appearance` vuole invece liste
di componenti e prop con gli indici nativi. La traduzione è `COMPONENT_MAP` + `translate()`.

### `COMPONENT_MAP`

Ogni chiave skinchanger → `{ indiceNativo, 'component'|'prop' }`:

| Componenti | Prop |
|---|---|
| `mask_1` → 1, `arms` → 3, `pants_1` → 4, `bags_1` → 5, `shoes_1` → 6, `chain_1` → 7, `tshirt_1` → 8, `bproof_1` → 9, `decals_1` → 10, `torso_1` → 11 | `helmet_1` → 0, `glasses_1` → 1, `ears_1` → 2, `watches_1` → 6, `bracelets_1` → 7 |

### `translate()`

Il suffisso decide il campo: `_2` è la **texture**, tutto il resto è il **drawable**.
Le due chiavi (`torso_1` e `torso_2`) confluiscono nella stessa voce, indicizzata per
indice nativo, poi convertite in due liste piatte:

```lua
{ component_id = 11, drawable = 55, texture = 0 }   -- componenti
{ prop_id = 0, drawable = 46, texture = 0 }         -- prop
```

Applicate con `setPedComponents` / `setPedProps`, solo se la lista non è vuota.

### Abito civile

`Snapshot()` legge `getPedComponents` e `getPedProps` (due `pcall` indipendenti: se uno
fallisce l'altro vale ancora). `SaveCivilian()` lo serializza su **KVP**
(`kf_police:civilian_outfit`), quindi sopravvive a un rientro in gioco.
`RestoreCivilian()` lo rilegge e chiama `Restore`, che passa gli snapshot **così come
sono** (già in formato nativo, nessuna traduzione).

## Note e trappole

- **`Apply` e `Restore` prendono formati diversi.** `Apply` vuole le chiavi skinchanger e
  traduce; `Restore` vuole già gli indici nativi. Passare uno snapshot ad `Apply` non fa
  nulla (nessuna chiave corrisponde a `COMPONENT_MAP`), silenziosamente.
- Tutte le chiamate a `fivem-appearance` sono in `pcall` con **closure**, non con self
  esplicito: `pcall(function() exports['fivem-appearance']:setPedComponents(...) end)`.
  Il colon-call dentro la closure è corretto.
- Se `fivem-appearance` non è avviato, `Available()` è falso e lo spogliatoio notifica
  `uniform_missing`: nessun crash.
- Il KVP è **per personaggio? No: per cliente.** `SetResourceKvp` è globale sulla
  macchina, non per personaggio. Con più personaggi sullo stesso account l'abito civile
  salvato è quello dell'ultimo che è entrato in servizio. Limitazione nota.

## Correlati

[modules/clothing-cl_skinchanger.md](clothing-cl_skinchanger.md) ·
[config/cfg_duty.md](../config/cfg_duty.md) ·
[client/cl_cloakroom.md](../client/cl_cloakroom.md)
