# config/cfg_armory.lua

**Ruolo:** armeria — armi autorizzate per grado, oggetti, scorte iniziali.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Lo stock è su **`kf_police_armory_stock`**, non su `esx_datastore`: sopravvive ai restart
ed è leggibile in SQL.

### `Config.Armory`

| Chiave | Valore | Effetto |
|---|---|---|
| `BuyFrom` | `'society'` | il rifornimento scala il conto società; `'player'` addebita il contante dell'agente |
| `BuyPermission` | `'armory.buy'` | grado minimo per rifornire (solo `boss`) |
| `Audit` | `true` | ogni prelievo/deposito su `kf_police_audit` |
| `InitialStock` | mappa item → quantità | creata alla prima installazione da `sv_migrations.lua`, **non** dal seed SQL |

`InitialStock` contiene armi (`WEAPON_NIGHTSTICK 20`, `WEAPON_STUNGUN 10`,
`WEAPON_APPISTOL 8`, `WEAPON_ADVANCEDRIFLE 4`, `WEAPON_PUMPSHOTGUN 4`,
`WEAPON_FLASHLIGHT 20`) e oggetti (`handcuffs 25`, `radio 25`, `police_mdt 10`,
`armor 15`).

### `Config.AuthorizedWeapons`

Indicizzato per **nome del grado**. Ogni voce:
`{ weapon, price, components? }`. I `components` sono hash applicati al prelievo
(`ox_inventory` li accetta come metadata).

Progressione: `recruit` ha manganello, torcia, taser e pistola; `officer` aggiunge il
fucile d'assalto; `sergeant` e superiori aggiungono il pump. `lieutenant` e `boss` hanno
lo stesso arsenale del `sergeant`.

I `price` sono i costi di **rifornimento**, non di prelievo: prendere è sempre gratis se
c'è scorta.

### `Config.ArmoryItems`

Oggetti non-arma disponibili a **tutti i gradi**: `handcuffs` (max 2), `radio` (max 1),
`police_mdt` (max 1), `armor` (max 1). Il campo `max` è un tetto per inventario,
verificato in `sv_armory.lua` prima della consegna.

## Note e trappole

- Lo stock in database usa le chiavi **minuscole** (`string.lower`): `WEAPON_APPISTOL`
  diventa `weapon_appistol`. `sv_armory.lua` normalizza sempre.
- Il prelievo è **atomico**: `UPDATE ... SET count = count - ? WHERE item = ? AND
  count >= ?`. Due agenti che prendono l'ultima arma nello stesso istante non la
  duplicano.
- Se la consegna in inventario fallisce, lo stock **torna indietro** (`returnStock`):
  niente sparizioni.
- Il server rivalida che l'arma sia fra quelle autorizzate per il **grado dell'agente**:
  il client non può chiedere un'arma di un grado superiore.
- `police_mdt` è nella lista ma **non esiste ancora come item** in `ox_inventory`: F8.

## Correlati

[server/sv_armory.md](../server/sv_armory.md) ·
[client/cl_armory.md](../client/cl_armory.md) ·
[modules/inventory-sv_ox.md](../modules/inventory-sv_ox.md)
