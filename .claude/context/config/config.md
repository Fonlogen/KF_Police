# config/config.lua

**Ruolo:** impostazioni trasversali. Tutto il resto è nei `cfg_*.lua` della stessa
cartella, caricati subito dopo.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, **primo** dei `shared_scripts` dopo `ox_lib`

## Cosa fa

Crea la tabella globale `Config` e la popola con le voci che non appartengono a un
sottosistema specifico. Ogni `cfg_*.lua` poi aggiunge le proprie chiavi alla stessa
tabella.

## Contenuto

### Base

| Chiave | Valore | Note |
|---|---|---|
| `Config.Debug` | `false` | attiva `Logger.Debug` e il debug delle zone target |
| `Config.Locale` | `'it'` | ripiego su `en` per chiave mancante |
| `Config.Framework` | `'esx'` | unico implementato |
| `Config.Target` | `'ox_target'` | oppure `'marker'` |
| `Config.Inventory` | `'ox_inventory'` | oppure `'esx'` |
| `Config.Clothing` | `'fivem-appearance'` | oppure `'skinchanger'` |
| `Config.AllowedJobs` | `police`, `ambulance` | chi può aprire il MDT |
| `Config.PoliceJobs` | `police` | chi ha le funzioni di campo |
| `Config.Society` | `'society_police'` | conto per armeria e sanzioni |

I quattro bridge sono selezionati qui e ogni implementazione fa `return` in cima se non
è quella scelta: solo una resta caricata.

### Apertura del MDT

- `Config.OpenCommand = 'openmdt'`
- **`Config.OpenKey = 'F5'`** — correzione bug L8: F6 collideva con
  `police:quickactions` di `esx_policejob`.
- `Config.OpenItem = 'police_mdt'`, con `Config.OpenItemAliases = { 'mdt', 'tablet' }`
  per retrocompatibilità con gli inventari esistenti.

`police_mdt` **non esiste ancora** in `ox_inventory`: va creato in F8. Oggi funzionano
gli alias.

### Interfaccia

`Config.UI` definisce la scala dinamica: `baseWidth 1280`, `baseHeight 910` (rapporto
1.4066), `heightRatio 0.96`, `minWidth 1080`, `maxWidth 1920`, `scale 1.0`. Li consuma
`ComputeTabletGeometry()` in `client/cl_nui.lua`.

`Config.UI.frame` descrive la cornice fisica (`web/assets/tablet.png`, 1400 × 1073) e la
sua finestra trasparente. **`heightRatio` misura la cornice intera, non la schermata**:
siccome la scocca è alta 1.208 volte il ritaglio, la schermata utile è sempre più piccola
della frazione dichiarata. È la ragione per cui `heightRatio` è passato da 0.86 a 0.96
insieme alla cornice — a 0.86 la UI si sarebbe rimpicciolita del 17%, testo compreso.

`minWidth`/`maxWidth` valgono sulla **schermata**, non sulla cornice: è la larghezza
della schermata che determina `rootFontSize`, quindi la leggibilità.

Le misure orizzontali di `frame` **non sono il ritaglio nudo**: comprendono 1 px di
sovrapposizione per lato (`cutoutX 59` invece di 60, `cutoutWidth 1280` invece di 1278).
Il bordo della finestra è antialiasato su 1 px e senza sovrapposizione in gioco si vedeva
una cucitura di gioco ai lati. Dettagli nel commento del file e in
[client/cl_nui.md](../client/cl_nui.md).

`Config.EnabledPages` è l'elenco ordinato delle pagine della sidebar; le chiavi devono
corrispondere a `PAGES` in `web/src/pages/registry.ts`.

`Config.PageSize = 25` e `Config.MaxPageSize = 100` limitano le liste.
`Config.DefaultImage = 'assets/guest.png'` è la foto di riserva: **file locale, nessun
host esterno** (il vecchio valore puntava a `via.placeholder.com`, irraggiungibile in
gioco).

### Anti-abuso

- `Config.RateLimit`: finestra 10 s, 120 chiamate, 30 scritture. Applicato in
  `server/sv_permissions.lua`.
- `Config.Limits`: lunghezze massime accettate dai callback (`query 64`, `note 1000`,
  `reportBody 8000`, ...). Usate da `SanitizeText` in ogni endpoint.
- `Config.Audit`: `Enabled`, `KeepDays 60`.

## Note e trappole

- Aggiungere una pagina richiede **tre** modifiche coordinate: `Config.EnabledPages`,
  `PAGES` in `registry.ts`, e la mappa `PAGE_COMPONENTS` in `web/src/pages/App.tsx`.
- `Config.DefaultTown` è stato **rimosso**: la nazionalità viene da `users.nationality`.
- Cambiare `Config.Locale` non richiede build della UI: le stringhe della NUI sono
  scritte in italiano nei componenti, i locali servono ai messaggi Lua.

## Correlati

[shared/sh_permissions.md](../shared/sh_permissions.md) ·
[client/cl_nui.md](../client/cl_nui.md) ·
[web/pages/registry.md](../web/pages/registry.md)
