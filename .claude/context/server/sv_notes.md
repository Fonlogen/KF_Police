# server/sv_notes.lua

**Ruolo:** note di servizio sul fascicolo. **Correzione del bug L6.**
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_charges.lua`

## Il bug L6

Gli id delle note erano calcolati come `#citizen.notes + 1`: dopo una cancellazione due
note finivano con **lo stesso id**, e modificarne una modificava l'altra. Ora l'id arriva
da `AUTO_INCREMENT` e non si ripete mai.

## Endpoint

### `notes:add` — `mdt.note.create`

Verifica che il cittadino esista, sanifica la nota a `Config.Limits.note` (1000), inserisce
con `officer_id` e `officer_name`. Ritorna il nuovo `id` e la lista aggiornata.

### `notes:update` — `mdt.note.create`

Regola di autorizzazione **oltre al permesso**:

```lua
local isOwner = existing.officer_id == info.identifier
if not isOwner and not HasPermission(info.job, info.grade, 'mdt.note.delete') then
    return MdtError('no_permission')
end
```

Cioè: la propria nota si modifica sempre; quella di un altro richiede il permesso di
**eliminare** le note (grado `sergeant`+). Non esiste un permesso separato per "modifica
note di altri": si riusa `mdt.note.delete` come proxy di autorità.

### `notes:delete` — `mdt.note.delete`

Cancella davvero la riga. Il testo cancellato viene messo nel payload dell'audit, così
resta recuperabile da `kf_police_audit`.

## Note e trappole

- Tutti e tre gli endpoint ritornano `GetCitizenNotes(identifier)` aggiornata: la UI non
  deve ricaricare il dossier.
- `notes:update` **non** aggiorna `updated_at` a mano: ci pensa la colonna con
  `ON UPDATE CURRENT_TIMESTAMP`.
- La nota è `TEXT` in database ma tagliata a 1000 caratteri in ingresso: il limite è
  applicativo, non di schema.
- `notes:add` è l'unico endpoint che richiede l'esistenza del cittadino in `users`;
  `update` e `delete` lavorano sull'id della nota e non ricontrollano.
- `citizens:setMugshot` usa lo stesso permesso `mdt.note.create`: è la scelta più
  permissiva coerente (chi può annotare può caricare una foto).

## Correlati

[server/sv_citizens.md](sv_citizens.md) ·
[shared/sh_permissions.md](../shared/sh_permissions.md) ·
[web/pages/CitizenSheet.md](../web/pages/CitizenSheet.md)
