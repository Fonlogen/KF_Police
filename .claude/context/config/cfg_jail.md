# config/cfg_jail.lua

**Ruolo:** carcere — conversione della pena, celle, area di confinamento, rilascio.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Il tempo residuo vive su **`kf_police_jail` in secondi**, quindi è persistente a
disconnessione e restart della risorsa. Qui si definisce come i "mesi" del codice penale
diventano secondi reali.

### `Config.Jail`

| Chiave | Valore | Effetto |
|---|---|---|
| `Enabled` | `true` | |
| `SecondsPerMonth` | `30` | 1 mese di condanna = 30 s di detenzione |
| `MaxSeconds` | `7200` | tetto di 2 ore reali, applicato con `ClampInt` |
| `CountOffline` | `false` | a giocatore offline il timer **non** scende |
| `Tick` | `5` | il timer server gira ogni 5 s |
| `PersistEvery` | `6` | scrive su database ogni 6 tick (30 s) |
| `TeleportOnJoin` | `true` | il detenuto torna in cella a ogni rientro |
| `Release` | `vector3(1845.0, 2585.9, 45.7)` | punto di rilascio |
| `StripWeapons` | `true` | tutte le armi rimosse all'ingresso |

### `Config.Jail.Cells`

Sei celle (`A1`-`A3`, `B1`-`B3`) con `capacity = 2` ciascuna: 12 posti totali.
`pickCell()` in `sv_jail.lua` conta gli occupanti e restituisce la prima cella con posto;
se sono tutte piene `JailPlayer` fallisce con `jail_no_cell`.

### `Config.Jail.Bounds`

`center = vector3(1771.0, 2591.0, 45.6)`, `radius = 65.0`. `client/cl_jail.lua` controlla
ogni 2 s: uscire dall'area riporta in cella con notifica `jail_cannot_leave`.

## Note e trappole

- **Le coordinate sono le celle standard di Bolingbroke.** Restano da confermare con la
  mappa realmente in uso: è un dubbio aperto in `.claude/handoff.md` §10.
- `SecondsPerMonth = 30` con gli articoli del seed produce pene molto lunghe: `Omicidio`
  ha `jail_months = 500`, cioè 15 000 s, tagliati a 7 200 dal `MaxSeconds`. Il tetto è
  ciò che rende il codice penale giocabile: non alzarlo senza rivedere gli articoli.
- `CountOffline = false` significa che disconnettersi **congela** la pena, non la annulla:
  `playerDropped` scrive il residuo su database.
- Il rilascio automatico lo esegue il **server**, non l'agente che ha arrestato: funziona
  anche se quell'agente è offline.

## Correlati

[server/sv_jail.md](../server/sv_jail.md) ·
[client/cl_jail.md](../client/cl_jail.md) ·
[sql/seed.md](../sql/seed.md)
