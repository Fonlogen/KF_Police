/**
 * Dati finti per lo sviluppo in browser (`npm run dev`).
 * ---------------------------------------------------------------------------
 * Sostituisce il vecchio debugDataList.ts. Nessun accesso al gioco: `callMdt`
 * instrada qui quando la pagina non gira dentro la NUI, così l'interfaccia si
 * costruisce e si misura contro il mockup senza avviare il server.
 *
 * Le forme delle risposte rispecchiano esattamente quelle di server/sv_*.lua.
 */

import type {
  Bootstrap,
  CitizenDossier,
  CitizenRow,
  JailRow,
  PenalCategory,
  RadioState,
  ReportDetail,
  ReportRow,
  RosterRow,
  Tag,
  VehicleRecord,
  VehicleRow,
  WantedRow,
} from './types';

const OFFICER = {
  identifier: 'char1:devidentifier',
  name: 'Fonlogen Dev',
  firstName: 'Fonlogen',
  lastName: 'Dev',
  ssn: '811-91-8780',
  job: 'police',
  jobLabel: 'Police Dept.',
  grade: 4,
  gradeName: 'boss',
  gradeLabel: 'Captain',
  onDuty: true,
};

/** Tutti i permessi: in sviluppo si vede l'interfaccia completa. */
const PERMISSIONS = [
  'mdt.view',
  'mdt.citizen.view',
  'mdt.vehicle.view',
  'mdt.report.create',
  'mdt.report.edit',
  'mdt.report.delete',
  'mdt.note.create',
  'mdt.note.delete',
  'mdt.charge.add',
  'mdt.charge.void',
  'mdt.wanted.set',
  'mdt.vehicle.flag',
  'mdt.penalcode.edit',
  'mdt.tag.edit',
  'mdt.fine.issue',
  'mdt.jail.view',
  'mdt.roster.view',
  'jail.send',
  'jail.release',
  'radio.use',
  'duty.toggle',
  'society.boss',
];

const CITIZENS: CitizenRow[] = [
  {
    identifier: 'char1:devidentifier',
    firstName: 'Fonlogen',
    lastName: 'Dev',
    ssn: '811-91-8780',
    dateOfBirth: '1990-04-12',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0117',
    job: 'LSPD - Captain',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char2:dado',
    firstName: 'Dado',
    lastName: 'Dado',
    ssn: '292-07-1406',
    dateOfBirth: '1988-11-02',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0142',
    job: 'LSPD - Lieutenant',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char3:franchito',
    firstName: 'Franchito',
    lastName: 'Dossarioes',
    ssn: '076-81-0894',
    dateOfBirth: '1995-01-23',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0188',
    job: 'Disoccupato',
    isWanted: true,
    wantedReason: 'Rapina a mano armata in banca',
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char4:lady',
    firstName: 'Lady',
    lastName: 'Lilla',
    ssn: '515-87-4812',
    dateOfBirth: '1993-07-19',
    sex: 'F',
    nationality: 'Los Santos',
    phone: '555-0203',
    job: 'Disoccupato',
    isWanted: false,
    isJailed: true,
    jailSecondsRemaining: 420,
  },
  {
    identifier: 'char5:san',
    firstName: 'San',
    lastName: 'Andreas',
    ssn: '677-15-0384',
    dateOfBirth: '1985-03-05',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0231',
    job: 'Disoccupato',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char6:marco',
    firstName: 'Marco',
    lastName: 'Bellini',
    ssn: '318-44-9021',
    dateOfBirth: '1991-09-30',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0266',
    job: 'Meccanico',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char7:giulia',
    firstName: 'Giulia',
    lastName: 'Ferraro',
    ssn: '204-63-7715',
    dateOfBirth: '1996-12-08',
    sex: 'F',
    nationality: 'Los Santos',
    phone: '555-0290',
    job: 'EMS - Paramedico',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
  {
    identifier: 'char8:rocco',
    firstName: 'Rocco',
    lastName: 'Santoro',
    ssn: '442-19-5508',
    dateOfBirth: '1987-06-14',
    sex: 'M',
    nationality: 'Los Santos',
    phone: '555-0314',
    job: 'Disoccupato',
    isWanted: false,
    isJailed: false,
    jailSecondsRemaining: 0,
  },
];

const VEHICLES: VehicleRow[] = [
  {
    plate: 'KF 4471',
    model: 'sultan',
    type: 'car',
    stored: false,
    owner: 'char3:franchito',
    ownerName: 'Franchito Dossarioes',
    isStolen: true,
    isImpounded: false,
    hasBolo: true,
  },
  {
    plate: 'LS 9920',
    model: 'blista',
    type: 'car',
    stored: true,
    owner: 'char6:marco',
    ownerName: 'Marco Bellini',
    isStolen: false,
    isImpounded: false,
    hasBolo: false,
  },
  {
    plate: 'ZX 1188',
    model: 'futo',
    type: 'car',
    stored: false,
    owner: 'char8:rocco',
    ownerName: 'Rocco Santoro',
    isStolen: false,
    isImpounded: true,
    hasBolo: false,
  },
];

const TAGS: Tag[] = [
  { id: 1, label: 'Importante', icon: 'warning', color: '#A8322A' },
  { id: 2, label: 'Armi', icon: 'weapon', color: '#8A5A2B' },
  { id: 3, label: 'Rapina', icon: 'money', color: '#7BB661' },
  { id: 5, label: 'Rissa', icon: 'fist', color: '#8A4F7D' },
];

const REPORTS: ReportRow[] = [
  {
    id: 14,
    title: 'Rapina alla Fleeca di Legion Square',
    officer: 'Fonlogen Dev',
    officerId: OFFICER.identifier,
    location: 'Legion Square',
    status: 'open',
    isConfidential: false,
    date: '2026-08-18 21:14:00',
    involvedCount: 2,
    tags: [TAGS[2], TAGS[1]],
  },
  {
    id: 13,
    title: 'Rissa fuori dal Bahama Mamas',
    officer: 'Dado Dado',
    officerId: 'char2:dado',
    location: 'San Andreas Ave',
    status: 'closed',
    isConfidential: false,
    date: '2026-08-17 02:40:00',
    involvedCount: 3,
    tags: [TAGS[3]],
  },
  {
    id: 12,
    title: 'Controllo veicolo sospetto',
    officer: 'Fonlogen Dev',
    officerId: OFFICER.identifier,
    location: 'Vespucci Blvd',
    status: 'draft',
    isConfidential: true,
    date: '2026-08-16 18:05:00',
    involvedCount: 1,
    tags: [],
  },
  {
    id: 11,
    title: 'Sequestro veicolo abbandonato',
    officer: 'Dado Dado',
    officerId: 'char2:dado',
    location: 'Elgin Ave',
    status: 'open',
    isConfidential: false,
    date: '2026-08-15 11:22:00',
    involvedCount: 0,
    tags: [TAGS[0]],
  },
];

const PENAL: PenalCategory[] = [
  {
    id: 1,
    label: 'Codice della strada',
    icon: 'vehicles',
    sortOrder: 10,
    articles: [
      {
        id: 7,
        code: 'PC-101',
        categoryId: 1,
        title: 'Guida in stato di ebbrezza',
        description: 'Guida sotto effetto di alcol o stupefacenti.',
        fine: 2000,
        jailMonths: 100,
        isFelony: true,
      },
      {
        id: 112,
        code: 'PC-113',
        categoryId: 1,
        title: 'Passaggio con semaforo rosso',
        description: 'Attraversamento con luce rossa.',
        fine: 130,
        jailMonths: 0,
        isFelony: false,
      },
      {
        id: 115,
        code: 'PC-116',
        categoryId: 1,
        title: 'Guida senza patente',
        description: 'Conduzione di veicolo senza titolo abilitativo.',
        fine: 1500,
        jailMonths: 0,
        isFelony: false,
      },
    ],
  },
  {
    id: 3,
    label: 'Patrimonio e armi',
    icon: 'evidence',
    sortOrder: 30,
    articles: [
      {
        id: 144,
        code: 'PC-318',
        categoryId: 3,
        title: 'Rapina a mano armata in banca',
        description: 'Rapina con arma a danno di un istituto di credito.',
        fine: 1500,
        jailMonths: 25,
        isFelony: true,
      },
      {
        id: 136,
        code: 'PC-310',
        categoryId: 3,
        title: "Furto d'auto",
        description: 'Sottrazione di un veicolo altrui.',
        fine: 1800,
        jailMonths: 10,
        isFelony: true,
      },
    ],
  },
  {
    id: 4,
    label: 'Contro la persona',
    icon: 'charge',
    sortOrder: 40,
    articles: [
      {
        id: 150,
        code: 'PC-406',
        categoryId: 4,
        title: 'Omicidio di un civile',
        description: 'Uccisione di un cittadino.',
        fine: 10000,
        jailMonths: 60,
        isFelony: true,
      },
    ],
  },
];

const RADIO: RadioState = {
  enabled: true,
  current: 'lspd_main',
  currentLabel: 'LSPD Principale',
  currentNumber: 1,
  channels: [
    { id: 'lspd_main', label: 'LSPD Principale', short: 'CH1', channel: 1, connected: true },
    { id: 'lspd_tac', label: 'LSPD Tattica', short: 'CH2', channel: 2, connected: false },
    { id: 'lspd_cmd', label: 'LSPD Comando', short: 'CH3', channel: 3, connected: false },
    { id: 'shared', label: 'Canale Condiviso', short: 'TAC', channel: 5, connected: false },
  ],
  volume: 60,
  listeners: 4,
  talking: true,
};

function paginate<T>(rows: T[], payload: Record<string, unknown>) {
  const page = Number(payload.page ?? 1);
  const pageSize = Number(payload.pageSize ?? 25);
  const start = (page - 1) * pageSize;

  return { ok: true, rows: rows.slice(start, start + pageSize), total: rows.length, page, pageSize };
}

function matches(haystack: (string | undefined)[], query: string): boolean {
  if (!query) return true;
  const needle = query.toLowerCase();
  return haystack.some((value) => (value ?? '').toLowerCase().includes(needle));
}

function dossier(identifier: string): CitizenDossier {
  const citizen = CITIZENS.find((entry) => entry.identifier === identifier) ?? CITIZENS[0];

  return {
    ok: true,
    citizen: { ...citizen, height: 182, jobName: 'unemployed', jobGrade: 0 },
    charges: [
      {
        id: 91,
        penalcodeId: 144,
        code: 'PC-318',
        crime: 'Rapina a mano armata in banca',
        fine: 1500,
        jailMonths: 25,
        isPaid: false,
        officer: 'Fonlogen Dev',
        location: 'Legion Square',
        reportId: 14,
        date: '2026-08-18 21:20:00',
        voided: false,
      },
      {
        id: 90,
        penalcodeId: 136,
        code: 'PC-310',
        crime: "Furto d'auto",
        fine: 1800,
        jailMonths: 10,
        isPaid: true,
        officer: 'Dado Dado',
        location: 'Vespucci Blvd',
        date: '2026-08-14 16:02:00',
        voided: false,
      },
      {
        id: 84,
        crime: 'Oltraggio a pubblico ufficiale',
        fine: 110,
        jailMonths: 0,
        isPaid: false,
        officer: 'Dado Dado',
        location: 'Elgin Ave',
        date: '2026-08-10 09:44:00',
        voided: true,
        voidedAt: '2026-08-11 10:00:00',
        voidedBy: 'Fonlogen Dev',
        voidReason: 'Contestazione errata',
      },
    ],
    totals: { totalFine: 3300, totalMonths: 35, unpaidFine: 1500, count: 3 },
    notes: [
      {
        id: 12,
        note: 'Soggetto noto per resistenza durante i fermi. Procedere in coppia.',
        officer: 'Dado Dado',
        date: '2026-08-12 22:10:00',
      },
    ],
    vehicles: VEHICLES.filter((vehicle) => vehicle.owner === citizen.identifier),
    licenses: [
      { type: 'drive', label: 'Patente B' },
      { type: 'weapon', label: 'Porto d\'armi' },
    ],
    properties: [{ id: 'p1', label: 'Appartamento Integrity Way', address: 'Integrity Way 2', city: 'Los Santos' }],
    reports: REPORTS.filter((report) => report.id === 14),
    jail: citizen.isJailed
      ? {
          jailed: true,
          secondsRemaining: citizen.jailSecondsRemaining,
          totalSeconds: 900,
          reason: 'Rapina',
          cell: 'A2',
          officer: 'Fonlogen Dev',
          label: '7m 00s',
        }
      : { jailed: false, secondsRemaining: 0 },
  };
}

/** Instradamento degli endpoint verso i dati finti. */
export function mockEndpoint(endpoint: string, payload: Record<string, unknown>): unknown {
  const query = String(payload.query ?? '');

  switch (endpoint) {
    case 'bootstrap':
      return {
        ok: true,
        officer: OFFICER,
        permissions: PERMISSIONS,
        pages: ['citizens', 'vehicles', 'reports', 'penalcode', 'wanted', 'jail', 'radio', 'duty'],
        counters: { wanted: 1, jail: 2, reports: 2, duty: 3 },
        ui: { pageSize: 25, defaultImage: 'assets/guest.png', locale: 'it' },
        radio: { enabled: true },
      } satisfies Bootstrap;

    case 'citizens:search': {
      let rows = CITIZENS.filter((citizen) =>
        matches([citizen.firstName, citizen.lastName, citizen.ssn, citizen.phone], query),
      );

      if (payload.filter === 'wanted') rows = rows.filter((citizen) => citizen.isWanted);
      if (payload.filter === 'jailed') rows = rows.filter((citizen) => citizen.isJailed);

      return { ...paginate(rows, payload), wantedCount: CITIZENS.filter((c) => c.isWanted).length };
    }

    case 'citizens:get':
      return dossier(String(payload.identifier ?? ''));

    case 'vehicles:search': {
      let rows = VEHICLES.filter((vehicle) => matches([vehicle.plate, vehicle.model, vehicle.ownerName], query));

      if (payload.filter === 'stolen') rows = rows.filter((vehicle) => vehicle.isStolen);
      if (payload.filter === 'impounded') rows = rows.filter((vehicle) => vehicle.isImpounded);
      if (payload.filter === 'bolo') rows = rows.filter((vehicle) => vehicle.hasBolo);

      return paginate(rows, payload);
    }

    case 'vehicles:get': {
      const vehicle = VEHICLES.find((entry) => entry.plate === payload.plate) ?? VEHICLES[0];

      return {
        ok: true,
        vehicle: {
          plate: vehicle.plate,
          registered: true,
          model: vehicle.model,
          type: vehicle.type,
          stored: Boolean(vehicle.stored),
          mileage: 12480,
          owner: vehicle.owner,
          ownerName: vehicle.ownerName,
          ownerSsn: '076-81-0894',
          ownerPhone: '555-0188',
          flags: {
            isStolen: vehicle.isStolen,
            isImpounded: vehicle.isImpounded,
            impoundReason: vehicle.isImpounded ? 'Abbandonato su carreggiata' : undefined,
            impoundBy: vehicle.isImpounded ? 'Dado Dado' : undefined,
            impoundAt: vehicle.isImpounded ? '2026-08-15 11:30:00' : undefined,
            hasBolo: vehicle.hasBolo,
            boloReason: vehicle.hasBolo ? 'Veicolo usato in rapina' : undefined,
          },
          reports: REPORTS.slice(0, 1),
        } satisfies VehicleRecord,
      };
    }

    case 'vehicles:impounded':
      return {
        ok: true,
        rows: VEHICLES.filter((vehicle) => vehicle.isImpounded).map((vehicle) => ({
          plate: vehicle.plate,
          model: vehicle.model,
          ownerName: vehicle.ownerName,
          reason: 'Abbandonato su carreggiata',
          officer: 'Dado Dado',
          date: '2026-08-15 11:30:00',
        })),
        total: 1,
      };

    case 'reports:list': {
      let rows = REPORTS.filter((report) => matches([report.title, report.officer, report.location], query));
      if (payload.status) rows = rows.filter((report) => report.status === payload.status);

      return paginate(rows, payload);
    }

    case 'reports:get': {
      const report = REPORTS.find((entry) => entry.id === Number(payload.id)) ?? REPORTS[0];

      return {
        ok: true,
        report: {
          ...report,
          description:
            'Alle 21:14 e stata segnalata una rapina in corso presso la filiale Fleeca di Legion Square.\n\nDue soggetti armati, uno dei quali identificato in Franchito Dossarioes.',
          involved: [
            {
              identifier: 'char3:franchito',
              role: 'suspect',
              firstName: 'Franchito',
              lastName: 'Dossarioes',
              ssn: '076-81-0894',
            },
            { identifier: 'char6:marco', role: 'witness', firstName: 'Marco', lastName: 'Bellini', ssn: '318-44-9021' },
          ],
          vehicles: [{ plate: 'KF 4471', model: 'sultan', ownerName: 'Franchito Dossarioes' }],
          tags: report.tags ?? [],
        } satisfies ReportDetail,
      };
    }

    case 'reports:save':
      return { ok: true, id: Number(payload.id ?? 15), message: 'Rapporto salvato' };

    case 'reports:delete':
      return { ok: true, message: 'Rapporto eliminato' };

    case 'tags:list':
      return { ok: true, rows: TAGS };

    case 'penalcode:list':
      return { ok: true, categories: PENAL, articles: PENAL.flatMap((category) => category.articles) };

    case 'wanted:list': {
      const rows: WantedRow[] = CITIZENS.filter((citizen) => citizen.isWanted).map((citizen) => ({
        identifier: citizen.identifier,
        firstName: citizen.firstName,
        lastName: citizen.lastName,
        ssn: citizen.ssn,
        nationality: citizen.nationality,
        job: citizen.job,
        reason: citizen.wantedReason ?? 'Ricercato',
        wantedBy: 'Fonlogen Dev',
        wantedAt: '2026-08-18 21:30:00',
        chargeCount: 3,
      }));

      return paginate(rows, payload);
    }

    case 'jail:list': {
      const rows: JailRow[] = CITIZENS.filter((citizen) => citizen.isJailed).map((citizen) => ({
        identifier: citizen.identifier,
        firstName: citizen.firstName,
        lastName: citizen.lastName,
        ssn: citizen.ssn,
        secondsRemaining: citizen.jailSecondsRemaining,
        totalSeconds: 900,
        timeLabel: '7m 00s',
        reason: 'Rapina',
        cell: 'A2',
        officer: 'Fonlogen Dev',
        jailedAt: '2026-08-19 20:50:00',
        online: true,
      }));

      return { ok: true, rows, total: rows.length, cells: [] };
    }

    case 'duty:roster': {
      const rows: RosterRow[] = [
        {
          identifier: OFFICER.identifier,
          firstName: 'Fonlogen',
          lastName: 'Dev',
          grade: 4,
          gradeLabel: 'LSPD - Captain',
          onDuty: true,
          online: true,
          secondsThisMonth: 44100,
        },
        {
          identifier: 'char2:dado',
          firstName: 'Dado',
          lastName: 'Dado',
          grade: 3,
          gradeLabel: 'LSPD - Lieutenant',
          onDuty: true,
          online: true,
          secondsThisMonth: 28800,
        },
        {
          identifier: 'char9:nuovo',
          firstName: 'Nuovo',
          lastName: 'Recluta',
          grade: 0,
          gradeLabel: 'LSPD - Recruit',
          onDuty: false,
          online: false,
          secondsThisMonth: 5400,
        },
      ];

      return { ok: true, rows, total: rows.length, onDuty: 2, job: 'police', canManage: true };
    }

    case 'duty:state':
      return { ok: true, onDuty: true, total: 2 };

    case 'duty:toggle':
      return { ok: true, onDuty: !OFFICER.onDuty, message: 'Stato servizio aggiornato' };

    case 'radio:state':
    case 'radio:join':
    case 'radio:leave':
    case 'radio:volume':
      return { ok: true, radio: RADIO };

    case 'client:context':
      return { ok: true, location: 'Vespucci Blvd', time: '21:47' };

    case 'client:nearby':
      return { ok: false, error: 'no_nearby_player' };

    default:
      return { ok: true };
  }
}
