# fxmanifest.lua

**Ruolo:** manifest della risorsa. Dichiara ordine di caricamento, pagina NUI, file
esposti al client e dipendenze.
**Contesto:** manifest
**Versione:** 2.0.0 · `fx_version 'cerulean'` · `lua54 'yes'`

## Cosa fa

Elenca **esplicitamente** ogni file, senza glob. L'ordine non è cosmetico:

- **`shared_scripts`**: `@ox_lib/init.lua` → configurazione (`config/config.lua` prima
  di tutti i `cfg_*`) → utilità (`sh_utils`) → permessi (`sh_permissions`, che popola
  `Config.Permissions`) → locali → contratto del bridge framework.
- **`client_scripts`**: bridge (framework, notify, target, clothing, voice) → nucleo
  (`cl_main`, `cl_nui`) → funzioni.
- **`server_scripts`**: `@oxmysql/lib/MySQL.lua` → bridge → infrastruttura
  (`sv_logger` → `sv_permissions` → `sv_migrations` → `sv_database`) → `sv_main` (che
  registra il dispatcher) → moduli di dominio.

Un glob renderebbe l'ordine dipendente dal filesystem: `sh_permissions.lua` prima di
`config.lua` significa `Config` nil, `sv_database.lua` prima di `sv_migrations.lua`
significa `Migrations` nil.

## Pagina e file NUI

```lua
ui_page 'web/build/index.html'
```

`files` espone: il bundle in `web/build/`, i quattro `.woff2` in `web/assets/fonts/`, i
`.png` di `web/assets/`, e i tre file SQL (`install`, `seed`, `migrations/*`) che
`server/sv_database.lua` legge con `LoadResourceFile`.

I font sono dentro la risorsa perché **la NUI non ha accesso di rete garantito**: Google
Fonts via CDN non è affidabile e il testo ricadrebbe su Arial. La voce
`web/assets/fonts/*.woff2` resta come ripiego: Vite copia comunque i font in
`web/build/assets/` con l'hash.

## Dipendenze

`es_extended`, `oxmysql`, `ox_lib`.

Dipendenze **facoltative**, rilevate a runtime con `GetResourceState`: `ox_target`,
`ox_inventory`, `fivem-appearance`, `skinchanger`/`esx_skin`, `pma-voice`,
`esx_addonaccount`, `esx_society`, `esx_phone`, e i nove adapter di banking di
`config/cfg_banking.lua`.

## Note e trappole

- **Ogni file nuovo va aggiunto a mano** nella sezione giusta, nel punto giusto
  dell'ordine. Non esiste un glob che lo raccolga.
- `web/build/` è gitignorato: va rigenerato con `cd web && npm run build`. Senza build la
  `ui_page` non esiste e il tablet non si apre.
- `sql/backup/*.sql` non è nei `files` e non serve al runtime.

## Correlati

- [ARCHITECTURE.md](ARCHITECTURE.md) §5 per la sequenza di avvio del database.
- [web/toolchain.md](web/toolchain.md) per come si produce `web/build/`.
