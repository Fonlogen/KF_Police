# sql/backup/

**Ruolo:** dump di backup del database. Non fanno parte del runtime.

## Contenuto

`kfdev_esx_20260819.sql` — dump completo di `kfdev_esx`, circa 22 MB / 145 000 righe.
Preso prima della migrazione al nuovo schema.

## Gitignorato

`.gitignore` della risorsa contiene:

```
sql/backup/*.sql
```

I dump sono pesanti e non vanno versionati. Non sono nemmeno nei `files` di
`fxmanifest.lua`: il server non li legge.

## Come si usa

MariaDB gira in **Docker** su questa macchina, nessun client MySQL locale:

```bash
# Ripristino
docker exec -i MariaDB mariadb -uroot -pNegroPene123 kfdev_esx < sql/backup/kfdev_esx_20260819.sql

# Nuovo dump
docker exec MariaDB mariadbdump -uroot -pNegroPene123 kfdev_esx > sql/backup/kfdev_esx_$(date +%Y%m%d).sql
```

## Note

- Il backup **della sola tabella migrata** è un'altra cosa: lo crea `sv_migrations.lua`
  dentro il database come `kf_police_citizens_backup_20260819`. Non c'entra con questa
  cartella.
- Non aprire il dump con Read: sono 145 000 righe. Per ispezionarlo, usare query mirate
  contro il database.

## Correlati

[server/sv_migrations.md](../server/sv_migrations.md) ·
[../../CLAUDE.md](../../../CLAUDE.md) §5
