# config/cfg_duty.lua

**Ruolo:** servizio (in/out) e divise per grado e sesso.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Il servizio è **interno**: nessuna dipendenza da `esx_service`. Lo stato vive in memoria
per la sessione in `server/sv_duty.lua` e ogni transizione lascia una riga su
`kf_police_duty_log`, da cui si ricava il monte ore.

### `Config.Duty`

| Chiave | Valore | Effetto |
|---|---|---|
| `Enabled` | `true` | fuori servizio non compari nei blip né nel roster |
| `AutoOnLoad` | `false` | non entra in servizio al caricamento del personaggio |
| `ReadOnlyOffDuty` | `true` | fuori servizio il MDT resta consultabile in sola lettura |
| `MaxInService` | `-1` | illimitato; con `>= 0` `SetDuty` rifiuta oltre la soglia |

**`ReadOnlyOffDuty` è dichiarato ma non ancora applicato** da nessun endpoint: oggi
`RequirePermission` non guarda lo stato di servizio. Armeria e garage invece lo
verificano (`canInteract` nelle zone e controllo in `sv_garage.lua`).

### `Config.Cloakroom`

- `RestoreCivilian = true`: l'abito civile viene salvato prima di indossare la divisa e
  ripristinato all'uscita, così lo spogliatoio non distrugge il vestiario personale.
  Il salvataggio è su KVP, quindi sopravvive a un rientro in gioco.
- `Extras`: voci aggiuntive dello spogliatoio oltre alla divisa del grado —
  `bulletproof` (giubbotto antiproiettile) e `gilet` (alta visibilità).

### `Config.Uniforms`

Chiavi di primo livello = **`name` dei gradi in `job_grades`**: `recruit`, `officer`,
`sergeant`, `lieutenant`, `boss`. Più le due voci speciali `bulletproof` e `gilet` usate
dagli `Extras`.

Ogni grado ha `male` e `female` con le chiavi **skinchanger** (`tshirt_1`, `torso_1`,
`decals_1`, `arms`, `pants_1`, `shoes_1`, `helmet_1`, `chain_1`, `ears_1`, e i `_2` per
la texture).

I gradi si distinguono per `decals_1` / `decals_2`: `officer` senza mostrine,
`sergeant` `8/1`, `lieutenant` `8/2`, `boss` `8/3` (valori `male`). `recruit` è l'unico
con `helmet_1 = 46`.

Migrate da `Config.Uniforms` di `esx_policejob`.

## Note e trappole

- Le chiavi sono **skinchanger anche quando il bridge è `fivem-appearance`**:
  `modules/clothing/cl_appearance.lua` le traduce negli indici nativi GTA. Non
  convertirle a mano qui.
- Se un grado non ha una divisa configurata, `client/cl_cloakroom.lua` notifica
  `uniform_missing` e non fa nulla: nessun crash.
- Il ripiego è `uniform[Framework.GetSex()] or uniform.male`.
- Se rinomini un grado in `job_grades` devi rinominare la chiave anche qui, in
  `Config.AuthorizedWeapons` (`cfg_armory.lua`) e in `Config.AuthorizedVehicles`
  (`cfg_vehicles.lua`): sono tutte indicizzate per nome del grado.

## Correlati

[client/cl_cloakroom.md](../client/cl_cloakroom.md) ·
[modules/clothing-cl_appearance.md](../modules/clothing-cl_appearance.md) ·
[server/sv_duty.md](../server/sv_duty.md)
