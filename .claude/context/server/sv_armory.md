# server/sv_armory.lua

**Ruolo:** armeria. Catalogo per grado, prelievo/deposito **atomici**, rifornimento.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_fines.lua`

## Cosa fa

Lo stock è su `kf_police_armory_stock`, non su `esx_datastore`: sopravvive ai restart ed è
leggibile in SQL.

Espone quattro **callback diretti** (`lib.callback`), non endpoint MDT: l'armeria è un menu
di gioco, non una pagina del tablet.

## Atomicità

Il prelievo non fa "leggi, controlla, scrivi". Fa una **`UPDATE` condizionata**:

```sql
UPDATE kf_police_armory_stock SET count = count - ? WHERE item = ? AND count >= ?
```

Se `affectedRows` è 0, la scorta non c'era. Due agenti che prendono l'ultima arma nello
stesso istante: uno vince, l'altro riceve `armory_out_of_stock`. Nessuna duplicazione.

`returnStock` è un upsert `ON DUPLICATE KEY UPDATE count = count + VALUES(count)`.

## Callback

### `KF_Police:armory:catalog` — `armory.use`

Armi autorizzate per il **grado** dell'agente (`Config.AuthorizedWeapons[gradeName]`) più
`Config.ArmoryItems`, ognuna con la scorta reale. Include `canBuy`.

L'etichetta di un'arma senza `label` è derivata dal nome:
`WEAPON_APPISTOL` → `Appistol`.

### `KF_Police:armory:take` — `armory.use`

1. l'item deve essere fra quelli **autorizzati per il grado** → altrimenti `no_permission`;
2. `consumeStock(itemName, 1)` → altrimenti `armory_out_of_stock`;
3. per gli oggetti, controlla il tetto `max` per inventario; se supera, **rimette lo stock**
   e risponde `armory_full`;
4. `Inventory.AddWeapon(src, item, 250, components)` oppure `Inventory.AddItem`;
5. se la consegna **fallisce**, `returnStock`: niente sparizioni.

Le armi escono con 250 munizioni.

### `KF_Police:armory:store` — `armory.use`

Rimuove dall'inventario, poi `returnStock`. Se la rimozione fallisce risponde
`armory_no_item` e non altera lo stock.

### `KF_Police:armory:buy` — `armory.buy`

`count` 1-50. Cerca il prezzo prima fra le armi del grado, poi fra gli oggetti. Addebita
`Config.Society` (o il contante dell'agente se `Config.Armory.BuyFrom == 'player'`), poi
crea lo stock.

## Note e trappole

- **Il deposito non verifica che l'item sia dell'armeria.** Chi ha `armory.use` può
  depositare qualunque cosa e farla diventare stock. Un `armor` comprato altrove aumenta
  la scorta LSPD. Vale la pena chiuderlo se diventa un problema.
- `buy` cerca il prezzo per **nome esatto**: un item con `price = 0` in configurazione
  risulta gratuito e crea stock senza addebito.
- Se `esx_addonaccount` non è avviato, `RemoveSocietyMoney` ritorna `false` e la risposta è
  `armory_no_money`, che è fuorviante: il problema è la risorsa mancante.
- I nomi in database sono minuscoli (`string.lower`), quelli in configurazione maiuscoli:
  `consumeStock` e `returnStock` normalizzano, il resto del codice usa la forma di
  configurazione.
- `Config.Armory.Audit` controlla solo l'audit di `take`/`store`. Il `buy` è **sempre**
  tracciato.

## Correlati

[config/cfg_armory.md](../config/cfg_armory.md) ·
[client/cl_armory.md](../client/cl_armory.md) ·
[modules/inventory-sv_ox.md](../modules/inventory-sv_ox.md)
