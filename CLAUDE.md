# KF_Police — istruzioni per Claude

Risorsa FiveM: **MDT + job polizia standalone** che assorbe `esx_policejob`.
Framework ESX, `ox_lib`, `oxmysql`, NUI in React + TypeScript + Tailwind.

- **Lingua di lavoro:** italiano. Commenti nel codice, documentazione e testi UI in italiano.
- **Branch corrente:** `feature/mdt-rework` (rework in corso, vedi §3).
- **Versione risorsa:** 2.0.0

---

## 1. Come orientarsi: leggi i file di contesto, non tutti gli script

In `.claude/context/` c'è **un file `.md` per ogni file sorgente** del progetto: cosa fa,
cosa espone, chi lo usa, quali trappole ha. Serve a capire il progetto senza rileggere
migliaia di righe di Lua e TSX.

**Ordine di lettura consigliato:**

1. `.claude/context/README.md` — indice completo e mappa del progetto.
2. `.claude/context/ARCHITECTURE.md` — flussi trasversali: contratto NUI, permessi,
   sequenza di avvio del database, invalidazioni. **Leggilo sempre prima di toccare
   qualcosa che attraversa client e server.**
3. Il `.md` del file specifico su cui devi lavorare.
4. Solo allora il sorgente vero.

Documenti di lavoro (stato del rework, non descrizione del codice):

- `.claude/handoff.md` — stato delle fasi, cosa resta da fare.
- `.claude/progress/2026-08-19-stato-implementazione.md` — inventario e decisioni prese.
- `.claude/plans/2026-08-19-kf-police-mdt-rework.md` — il piano approvato. **Le §1 e §3
  sono chiuse: non rimetterle in discussione.**
- `.claude/plans/assets/mockup-casefile-v4.html` — specifica visiva vincolante,
  1280 × 910 con base 16 px.

---

## 2. REGOLA: i file di contesto vanno mantenuti aggiornati

I `.md` in `.claude/context/` sono documentazione **viva**. Se divergono dal codice
diventano peggio che inutili: fanno prendere decisioni sbagliate.

### Quando aggiornare

| Modifica al codice | Azione richiesta su `.claude/context/` |
|---|---|
| Cambi il comportamento di un file | Aggiorna il suo `.md` **nello stesso turno di lavoro** |
| Crei un file sorgente nuovo | Crea il `.md` corrispondente **e** aggiungilo all'indice in `README.md` |
| Elimini un file sorgente | Elimina il suo `.md` **e** togli la voce da `README.md` |
| Rinomini o sposti un file | Rinomina/sposta il `.md` e correggi i riferimenti che lo citano |
| Aggiungi o rinomini un endpoint MDT | Aggiorna il `.md` del modulo server **e** la tabella endpoint in `ARCHITECTURE.md` |
| Cambi lo schema del database | Aggiorna `sql/install.md` e, se serve, `sql/migrations-001_normalize.md` |
| Cambi un permesso o un grado | Aggiorna `shared/sh_permissions.md` e la sezione permessi di `ARCHITECTURE.md` |
| Cambi un token del design system | Aggiorna `web/styles/tokens.md` |
| Cambi il contratto di un bridge | Aggiorna il `.md` del contratto **e** quelli delle implementazioni |

Non aggiornare un `.md` è considerato lavoro **incompleto**, esattamente come lasciare
un test rotto.

### Come si scrive un file di contesto

Struttura fissa, così è scansionabile:

```markdown
# <percorso/del/file.lua>

**Ruolo:** una riga, cosa fa questo file e perché esiste.
**Contesto:** shared | client | server | UI
**Caricato da:** fxmanifest (posizione) oppure chi lo importa

## Cosa fa
Prosa breve. Il flusso, non un elenco di righe di codice.

## API pubblica
Funzioni/valori globali, endpoint registrati, eventi emessi e ascoltati.

## Dipendenze
Da cosa dipende e chi dipende da lui.

## Note e trappole
Decisioni non ovvie, bug corretti qui, cose che si rompono facilmente.
```

Regole di stile per i `.md` di contesto:

- **Descrivi il perché, non ripetere il codice.** Se il `.md` è una parafrasi riga per
  riga, non serve a nulla.
- **Zero emoji**, come nel resto del progetto.
- Cita i file con il percorso relativo alla radice della risorsa.
- Collega gli altri contesti con link relativi (`[sv_main](../server/sv_main.md)`).
- Se una cosa è vera *oggi* ma sta per cambiare, dillo esplicitamente e indica la fase.

---

## 3. Stato del rework (aggiornato al 2026-08-19)

| Fase | Titolo | Stato |
|---|---|---|
| F0 | Preparazione | Completata |
| F1 | Fondazioni Lua | Completata, **mai collaudata in gioco** |
| F2 | Design system UI | **In corso**: token, primitive e telaio fatti; pagine parziali |
| F3 | MDT dati reali | Backend completo, frontend parziale |
| F4 | Radio nel tablet | Backend + RadioDock fatti, pagina Radio da fare |
| F5 | Azioni di campo | Completata lato Lua, mai collaudata |
| F6 | Strutture stazione | Completata lato Lua, mai collaudata |
| F7 | Carcere | Completata lato Lua, mai collaudata |
| F8 | Dismissione `esx_policejob` | Non iniziata |
| F9 | Hardening e collaudo | Parziale |

### La build della UI è rotta, ed è previsto

`web/src/pages/App.tsx` importa sei pagine che **non esistono ancora**: `ReportSheet`,
`PenalCodePage`, `WantedPage`, `JailPage`, `RadioPage`, `DutyPage`. Finché non vengono
scritte, `npx tsc --noEmit` e `npm run build` falliscono. Non è una regressione da
indagare: è F2 a metà. Dettagli in `.claude/context/web/pages/App.md`.

I file legacy in `web/src/pages/sections/` e `web/src/pages/components/` importano
`MDTContext` da `../App`, che non lo esporta più: sono **codice morto che non compila**.
Vanno cancellati, non riparati (vedi `.claude/context/web/legacy-ui.md`).

---

## 4. Trappole da non ripetere

1. **Export FiveM:** `exports[res][name](arg)` mangia il primo argomento come `self`.
   Va sempre `exports[res]:name(arg)` oppure `handle[name](handle, arg)`. È il bug L1 e
   ricompare facilmente.
2. **Tailwind:** `"bg-" + colore` e `` `w-[${x}px]` `` non generano nessuna classe (bug
   U3/U4). Mappe statiche complete, oppure `style={{ }}` per i valori davvero dinamici
   (es. il colore di un tag, che arriva dal database).
3. **`width` + `flex` sulla stessa cella** si contraddicono (bug U11). In `DataTable`
   sono mutuamente esclusivi per costruzione.
4. **Listener nel corpo del render** = memory leak (bug U1). Sempre in `useEffect` con
   cleanup.
5. **Hook condizionali:** mai `while (!context) { context = useContext(...) }` (bug U2).
   `useMdt()` lancia se il provider manca.
6. **Zero emoji** in qualunque file, seed SQL compresi. Solo chiavi del registro `ICONS`.
7. **Solo `rem`**, mai `px`, nei componenti UI. La radice la imposta `useTabletScale`.
8. **Ordine di avvio database:** install → migrate → seed. Invertirlo dà
   `ERROR 1054 Unknown column 'icon'`.
9. **Non fidarsi mai del payload NUI:** ogni endpoint rivalida. Le azioni di campo
   verificano la distanza dal bersaglio con `GetEntityCoords` **sul server**.
10. **Nessun host esterno** dalla NUI (font, immagini): la rete non è garantita. Il
    ripiego per le foto è locale, `web/assets/guest.png`.

---

## 5. Verifiche

```bash
# TypeScript (oggi fallisce di proposito, vedi §3)
cd "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police/web" && npx tsc --noEmit

# Build della UI
npm run build

# Sintassi Lua: non c'e' un interprete installato, si usa luaparse via Node.
# Script in .claude/progress/2026-08-19-stato-implementazione.md §7
node "$TEMP/luacheck/check.mjs" "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police"

# Nessun valore hardcoded nei componenti nuovi
grep -rE "text-\[|w-\[|h-\[|#[0-9a-fA-F]{6}" web/src/components web/src/pages

# Nessuna emoji
grep -rP "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]" web/src shared sql
```

### Database

MariaDB gira in Docker, **nessun client MySQL locale**. Il database è `kfdev_esx`.

```bash
docker exec MariaDB mariadb -uroot -pNegroPene123 kfdev_esx -e "SELECT 1"
docker exec -i MariaDB mariadb -uroot -pNegroPene123 kfdev_esx < file.sql
```

Nulla è ancora stato provato con il server FiveM avviato: sintassi Lua, compilazione
TypeScript ed esecuzione dei file SQL sono le sole verifiche fatte.
