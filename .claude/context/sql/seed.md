# sql/seed.sql

**Ruolo:** dati iniziali: 4 categorie, 10 tag, **59 articoli** di codice penale.
**Eseguito da:** `server/sv_database.lua` → `Database.Seed()`, **terzo e ultimo** passo

## Perché è separato da install.sql

I seed usano colonne (`icon`, `category_id`, `jail_months`) che su un database preesistente
vengono aggiunte dalla **migrazione**, cioè dal passo 2. Eseguendoli prima si prende
`ERROR 1054 Unknown column 'icon'`: è già successo, è la ragione della separazione.

Ordine obbligatorio: `install.sql` → `Migrations.Run()` → `seed.sql`.

## Contenuto

### Categorie (id fissi 1-4)

| id | Etichetta | Icona | Ordine |
|---|---|---|---|
| 1 | Codice della strada | `vehicles` | 10 |
| 2 | Ordine pubblico | `warning` | 20 |
| 3 | Patrimonio e armi | `evidence` | 30 |
| 4 | Contro la persona | `charge` | 40 |

### Tag (id fissi 1-10)

Importante, Armi, Rapina, Estorsione, Rissa, Vandalismo, Alcol, Stupefacenti, Veicolo,
Testimone. Ognuno con una chiave `icon` del registro `ICONS` e un `color` esadecimale.

**Zero emoji**: le icone sono chiavi FontAwesome, non caratteri Unicode (bug L11).

### Articoli

- **id 1-7**: gli articoli maggiori del codice penale iniziale (Omicidio, Rapina, Furto,
  Estorsione, Rissa, Vandalismo, Guida in stato di ebbrezza).
- **id 101-152**: le 52 `fine_types` di `esx_policejob`, **tradotte in italiano** e
  riversate come articoli con la loro categoria. Distribuzione: 20 nella categoria 1,
  10 nella 2, 15 nella 3, 7 nella 4.

Totale **59 articoli** su 4 categorie. `fine_types` resta in database ma non è più letta da
KF_Police: una sola fonte per multe e reati.

Ogni articolo ha `code` (`PC-NNN`), `fine`, `jail_months`, `is_felony`.

## Idempotenza

Tutti gli `INSERT` hanno `ON DUPLICATE KEY UPDATE` su etichetta, descrizione, valori
numerici e gravità. Rieseguire il seed non duplica nulla.

**Conseguenza importante:** un articolo modificato dalla UI viene **riportato ai valori
iniziali** al prossimo avvio del server. Chi vuole personalizzare gli articoli 1-7 e
101-152 deve modificare questo file, non solo la UI.

## Note e trappole

- Gli id sono **espliciti e fissi**: aggiungere articoli propri conviene farlo da 200 in su
  per non collidere con futuri ampliamenti del seed.
- `jail_months` di `Omicidio` è 500 → 15 000 secondi con `SecondsPerMonth = 30`, tagliati a
  7 200 dal `Config.Jail.MaxSeconds`. **Il tetto è ciò che rende il codice penale
  giocabile**: non alzarlo senza rivedere gli articoli.
- Gli apostrofi nelle descrizioni sono `\'` (`'Porto d\'armi assente'`): lo splitter di
  `RunSqlFile` gestisce l'escape, ma resta il motivo per cui non si può usare un
  `split(';')` ingenuo.
- Nessuna lettera accentata nelle stringhe, come nei locali (`citta`, `liberta`): mantieni
  la convenzione.
- Lo **stock iniziale dell'armeria non è qui**: lo crea `sv_migrations.lua` da
  `Config.Armory.InitialStock`, perché la fonte è la configurazione Lua.

## Correlati

[sql/install.md](install.md) · [server/sv_penalcode.md](../server/sv_penalcode.md) ·
[config/cfg_jail.md](../config/cfg_jail.md) ·
[web/components/Icon.md](../web/components/Icon.md)
