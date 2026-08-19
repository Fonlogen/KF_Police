# client/cl_boss.lua

**Ruolo:** menu società. Delega a `esx_society` se presente, altrimenti roster interno in
sola lettura.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_garage.lua`

## Cosa fa

Registra una zona per ogni `bossActions` di ogni stazione, permesso `society.boss` (solo
`boss`).

Due comportamenti:

1. **`esx_society` avviato** → `TriggerServerEvent('esx_society:openBossMenu', Config.Society,
   nil, { wash = false })`. Conti, assunzioni e salari sono servizi **condivisi con gli altri
   lavori**: duplicarli farebbe danno.
2. **Altrimenti** → chiama `duty:roster` e mostra un menu contestuale con una voce per
   agente (`disabled = true`, non cliccabile): nome, grado, stato di servizio, monte ore
   formattato con `FormatDuration`.

Se il roster non risponde: `boss_unavailable`.

## Perché esiste come file separato

Non era nell'elenco del piano: è stato aggiunto perché il boss menu è una funzione da
assorbire da `esx_policejob` (fase F8) e meritava un file suo invece di stare dentro
`cl_cloakroom.lua`.

## Note e trappole

- Il roster interno è **in sola lettura**: non assume, non licenzia, non promuove. Serve a
  non lasciare la zona muta se `esx_society` manca.
- `wash = false` disabilita il riciclaggio di denaro nel menu di `esx_society`.
- La società è registrata all'avvio da `sv_main.lua` con
  `esx_society:registerSociety`: se quella registrazione non avviene, `openBossMenu` non
  trova la società.
- La pagina Servizio del MDT (`DutyPage`, non ancora scritta) userà lo **stesso** endpoint
  `duty:roster` con più funzioni. Questo menu resterà come accesso rapido dalla stazione.

## Correlati

[server/sv_duty.md](../server/sv_duty.md) · [server/sv_main.md](../server/sv_main.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)
