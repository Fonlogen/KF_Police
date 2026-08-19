-- ============================================================================
--  KF_Police - Dati iniziali
--  ---------------------------------------------------------------------------
--  Nessuna emoji: le icone sono chiavi del registro FontAwesome (3.8), non
--  caratteri Unicode. Eseguito da server/sv_database.lua DOPO install.sql e
--  DOPO le migrazioni, perche i seed usano colonne (icon, category_id,
--  jail_months) che su un database preesistente vengono aggiunte dalla
--  migrazione.
-- ============================================================================

-- ============================================================================

INSERT INTO `kf_police_penalcode_categories` (`id`, `label`, `icon`, `sort_order`) VALUES
    (1, 'Codice della strada', 'vehicles', 10),
    (2, 'Ordine pubblico', 'warning', 20),
    (3, 'Patrimonio e armi', 'evidence', 30),
    (4, 'Contro la persona', 'charge', 40)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `icon` = VALUES(`icon`), `sort_order` = VALUES(`sort_order`);

INSERT INTO `kf_police_tags` (`id`, `label`, `icon`, `color`) VALUES
    (1, 'Importante', 'warning', '#A8322A'),
    (2, 'Armi', 'weapon', '#8A5A2B'),
    (3, 'Rapina', 'money', '#7BB661'),
    (4, 'Estorsione', 'money', '#4F8A8B'),
    (5, 'Rissa', 'fist', '#8A4F7D'),
    (6, 'Vandalismo', 'spray', '#C9A227'),
    (7, 'Alcol', 'drink', '#8A8175'),
    (8, 'Stupefacenti', 'drug', '#6B7F1F'),
    (9, 'Veicolo', 'vehicles', '#D98C6A'),
    (10, 'Testimone', 'citizens', '#5A7FA8')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `icon` = VALUES(`icon`), `color` = VALUES(`color`);

-- Articoli maggiori (ereditati dal codice penale iniziale)
INSERT INTO `kf_police_penalcode` (`id`, `code`, `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony`) VALUES
    (1, 'PC-401', 4, 'Omicidio', 'Omicidio volontario di una persona.', 10000, 500, 1),
    (2, 'PC-301', 3, 'Rapina', 'Rapina a mano armata o con minaccia.', 5000, 300, 1),
    (3, 'PC-302', 3, 'Furto', 'Sottrazione di beni altrui.', 3000, 200, 1),
    (4, 'PC-303', 3, 'Estorsione', 'Richiesta di denaro o beni con minaccia.', 2000, 100, 1),
    (5, 'PC-201', 2, 'Rissa', 'Rissa o aggressione in luogo pubblico.', 1000, 50, 0),
    (6, 'PC-304', 3, 'Vandalismo', 'Danneggiamento di beni pubblici o privati.', 500, 25, 0),
    (7, 'PC-101', 1, 'Guida in stato di ebbrezza', 'Guida sotto effetto di alcol o stupefacenti.', 2000, 100, 1)
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`), `title` = VALUES(`title`),
    `description` = VALUES(`description`), `fine` = VALUES(`fine`),
    `jail_months` = VALUES(`jail_months`), `is_felony` = VALUES(`is_felony`);

-- Multe unificate al codice penale (ex tabella fine_types di esx_policejob).
-- Categoria 1 - Codice della strada
INSERT INTO `kf_police_penalcode` (`id`, `code`, `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony`) VALUES
    (101, 'PC-102', 1, 'Uso improprio del clacson', 'Segnalazione acustica non giustificata.', 30, 0, 0),
    (102, 'PC-103', 1, 'Sorpasso su linea continua', 'Attraversamento di linea continua.', 40, 0, 0),
    (103, 'PC-104', 1, 'Guida in contromano', 'Circolazione sul lato sbagliato della carreggiata.', 250, 0, 0),
    (104, 'PC-105', 1, 'Inversione di marcia vietata', 'Inversione a U dove non consentita.', 250, 0, 0),
    (105, 'PC-106', 1, 'Guida fuoristrada non consentita', 'Circolazione fuori dalla sede stradale.', 170, 0, 0),
    (106, 'PC-107', 1, 'Rifiuto di ordine legittimo', 'Mancata ottemperanza a un ordine di un agente.', 30, 0, 0),
    (107, 'PC-108', 1, 'Fermata in luogo vietato', 'Arresto del veicolo dove non consentito.', 150, 0, 0),
    (108, 'PC-109', 1, 'Sosta vietata', 'Veicolo in sosta irregolare.', 70, 0, 0),
    (109, 'PC-110', 1, 'Mancata concessione di precedenza', 'Omessa precedenza a destra.', 70, 0, 0),
    (110, 'PC-111', 1, 'Documenti del veicolo non conformi', 'Dati del veicolo non corrispondenti.', 90, 0, 0),
    (111, 'PC-112', 1, 'Mancato arresto allo stop', 'Omesso arresto al segnale di stop.', 105, 0, 0),
    (112, 'PC-113', 1, 'Passaggio con semaforo rosso', 'Attraversamento con luce rossa.', 130, 0, 0),
    (113, 'PC-114', 1, 'Sorpasso vietato', 'Manovra di sorpasso non consentita.', 100, 0, 0),
    (114, 'PC-115', 1, 'Circolazione con veicolo non omologato', 'Veicolo non conforme alle norme.', 100, 0, 0),
    (115, 'PC-116', 1, 'Guida senza patente', 'Conduzione di veicolo senza titolo abilitativo.', 1500, 0, 0),
    (116, 'PC-117', 1, 'Omissione di soccorso dopo incidente', 'Fuga dopo un sinistro.', 800, 5, 1),
    (117, 'PC-118', 1, 'Eccesso di velocita fino a 5 mph', 'Superamento del limite entro 5 mph.', 90, 0, 0),
    (118, 'PC-119', 1, 'Eccesso di velocita da 5 a 15 mph', 'Superamento del limite tra 5 e 15 mph.', 120, 0, 0),
    (119, 'PC-120', 1, 'Eccesso di velocita da 15 a 30 mph', 'Superamento del limite tra 15 e 30 mph.', 180, 0, 0),
    (120, 'PC-121', 1, 'Eccesso di velocita oltre 30 mph', 'Superamento del limite oltre 30 mph.', 300, 0, 0)
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`), `title` = VALUES(`title`),
    `description` = VALUES(`description`), `fine` = VALUES(`fine`),
    `jail_months` = VALUES(`jail_months`), `is_felony` = VALUES(`is_felony`);

-- Categoria 2 - Ordine pubblico
INSERT INTO `kf_police_penalcode` (`id`, `code`, `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony`) VALUES
    (121, 'PC-202', 2, 'Ostruzione della circolazione', 'Impedimento al normale flusso del traffico.', 110, 0, 0),
    (122, 'PC-203', 2, 'Ubriachezza in luogo pubblico', 'Stato di ebbrezza manifesta in pubblico.', 90, 0, 0),
    (123, 'PC-204', 2, 'Condotta molesta', 'Comportamento contrario alla quiete pubblica.', 90, 0, 0),
    (124, 'PC-205', 2, 'Ostruzione alla giustizia', 'Intralcio a un procedimento o a un intervento.', 130, 3, 0),
    (125, 'PC-206', 2, 'Insulti verso un civile', 'Ingiurie rivolte a un cittadino.', 75, 0, 0),
    (126, 'PC-207', 2, 'Oltraggio a pubblico ufficiale', 'Ingiurie rivolte a un agente in servizio.', 110, 0, 0),
    (127, 'PC-208', 2, 'Minaccia verbale a un civile', 'Minaccia rivolta a un cittadino.', 90, 0, 0),
    (128, 'PC-209', 2, 'Minaccia verbale a un agente', 'Minaccia rivolta a un agente in servizio.', 150, 2, 0),
    (129, 'PC-210', 2, 'Dichiarazioni mendaci', 'Fornitura di informazioni false agli agenti.', 250, 3, 0),
    (130, 'PC-211', 2, 'Tentata corruzione', 'Offerta di denaro o favori a un pubblico ufficiale.', 1500, 10, 1)
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`), `title` = VALUES(`title`),
    `description` = VALUES(`description`), `fine` = VALUES(`fine`),
    `jail_months` = VALUES(`jail_months`), `is_felony` = VALUES(`is_felony`);

-- Categoria 3 - Patrimonio e armi
INSERT INTO `kf_police_penalcode` (`id`, `code`, `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony`) VALUES
    (131, 'PC-305', 3, 'Esibizione di arma in area urbana', 'Ostentazione di un\'arma in citta.', 120, 3, 0),
    (132, 'PC-306', 3, 'Esibizione di arma letale in area urbana', 'Ostentazione di un\'arma da fuoco in citta.', 300, 6, 1),
    (133, 'PC-307', 3, 'Porto d\'armi assente', 'Detenzione di arma senza licenza.', 600, 5, 1),
    (134, 'PC-308', 3, 'Detenzione di arma illegale', 'Possesso di arma non consentita.', 700, 8, 1),
    (135, 'PC-309', 3, 'Possesso di strumenti da scasso', 'Detenzione di attrezzi per effrazione.', 300, 3, 0),
    (136, 'PC-310', 3, 'Furto d\'auto', 'Sottrazione di un veicolo altrui.', 1800, 10, 1),
    (137, 'PC-311', 3, 'Detenzione ai fini di spaccio', 'Possesso di sostanze illecite per la cessione.', 1500, 15, 1),
    (138, 'PC-312', 3, 'Produzione di sostanze illecite', 'Fabbricazione di sostanze proibite.', 1500, 15, 1),
    (139, 'PC-313', 3, 'Detenzione di sostanze illecite', 'Possesso di sostanze proibite.', 650, 6, 1),
    (140, 'PC-314', 3, 'Sequestro di persona', 'Privazione della liberta di un cittadino.', 1500, 20, 1),
    (141, 'PC-315', 3, 'Sequestro di un agente', 'Privazione della liberta di un pubblico ufficiale.', 2000, 30, 1),
    (142, 'PC-316', 3, 'Rapina', 'Sottrazione di beni con violenza o minaccia.', 650, 12, 1),
    (143, 'PC-317', 3, 'Rapina a mano armata in negozio', 'Rapina con arma a danno di un esercizio.', 650, 15, 1),
    (144, 'PC-318', 3, 'Rapina a mano armata in banca', 'Rapina con arma a danno di un istituto di credito.', 1500, 25, 1),
    (145, 'PC-319', 3, 'Truffa', 'Artifizi e raggiri per procurarsi un profitto.', 2000, 10, 1)
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`), `title` = VALUES(`title`),
    `description` = VALUES(`description`), `fine` = VALUES(`fine`),
    `jail_months` = VALUES(`jail_months`), `is_felony` = VALUES(`is_felony`);

-- Categoria 4 - Contro la persona
INSERT INTO `kf_police_penalcode` (`id`, `code`, `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony`) VALUES
    (146, 'PC-402', 4, 'Aggressione a un civile', 'Lesioni a danno di un cittadino.', 2000, 15, 1),
    (147, 'PC-403', 4, 'Aggressione a un agente', 'Lesioni a danno di un pubblico ufficiale.', 2500, 20, 1),
    (148, 'PC-404', 4, 'Tentato omicidio di un civile', 'Atti diretti a uccidere un cittadino.', 3000, 30, 1),
    (149, 'PC-405', 4, 'Tentato omicidio di un agente', 'Atti diretti a uccidere un pubblico ufficiale.', 5000, 45, 1),
    (150, 'PC-406', 4, 'Omicidio di un civile', 'Uccisione di un cittadino.', 10000, 60, 1),
    (151, 'PC-407', 4, 'Omicidio di un agente', 'Uccisione di un pubblico ufficiale.', 30000, 90, 1),
    (152, 'PC-408', 4, 'Omicidio colposo', 'Morte causata per colpa.', 1800, 20, 1)
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`), `title` = VALUES(`title`),
    `description` = VALUES(`description`), `fine` = VALUES(`fine`),
    `jail_months` = VALUES(`jail_months`), `is_felony` = VALUES(`is_felony`);
