/**
 * Tipi condivisi con il server.
 * Rispecchiano le risposte degli endpoint di server/sv_*.lua (sezione 6 del
 * piano): se un campo cambia lì, va cambiato qui.
 */

export type PageKey =
  | 'citizens'
  | 'vehicles'
  | 'reports'
  | 'penalcode'
  | 'wanted'
  | 'jail'
  | 'radio'
  | 'duty';

export interface MdtResponse {
  ok: boolean;
  error?: string;
  message?: string;
}

export interface Paged<T> extends MdtResponse {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Officer {
  identifier: string;
  name: string;
  firstName: string;
  lastName: string;
  ssn?: string;
  job: string;
  jobLabel: string;
  grade: number;
  gradeName: string;
  gradeLabel: string;
  mugshot?: string;
  onDuty: boolean;
}

export interface Counters {
  wanted: number;
  jail: number;
  reports: number;
  duty: number;
}

export interface Bootstrap extends MdtResponse {
  officer: Officer;
  permissions: string[];
  pages: PageKey[];
  counters: Counters;
  ui: {
    pageSize: number;
    defaultImage: string;
    locale: string;
  };
  radio: { enabled: boolean };
}

export interface CitizenRow {
  identifier: string;
  firstName: string;
  lastName: string;
  ssn?: string;
  dateOfBirth?: string;
  sex?: string;
  nationality: string;
  phone?: string;
  job: string;
  mugshot?: string;
  isWanted: boolean;
  wantedReason?: string;
  isJailed: boolean;
  jailSecondsRemaining: number;
}

export interface Charge {
  id: number;
  penalcodeId?: number;
  code?: string;
  crime: string;
  fine: number;
  jailMonths: number;
  isPaid: boolean;
  officer?: string;
  location?: string;
  victim?: string;
  victimIdentifier?: string;
  reportId?: number;
  date: string;
  voided: boolean;
  voidedAt?: string;
  voidedBy?: string;
  voidReason?: string;
}

export interface ChargeTotals {
  totalFine: number;
  totalMonths: number;
  unpaidFine: number;
  count: number;
}

export interface Note {
  id: number;
  note: string;
  officer?: string;
  date: string;
  updatedAt?: string;
}

export interface JailStatus {
  jailed: boolean;
  secondsRemaining: number;
  totalSeconds?: number;
  reason?: string;
  cell?: string;
  officer?: string;
  jailedAt?: string;
  label?: string;
}

export interface CitizenDossier extends MdtResponse {
  citizen: CitizenRow & {
    height?: number;
    jobName?: string;
    jobGrade?: number;
    wantedBy?: string;
    wantedAt?: string;
  };
  charges: Charge[];
  totals: ChargeTotals;
  notes: Note[];
  vehicles: VehicleRow[];
  licenses: { type: string; label: string }[];
  properties: { id: string; label: string; address: string; city: string }[];
  reports: ReportRow[];
  jail?: JailStatus;
}

export interface VehicleRow {
  plate: string;
  model: string;
  type: string;
  stored?: boolean;
  owner?: string;
  ownerName?: string;
  job?: string;
  isStolen: boolean;
  isImpounded: boolean;
  hasBolo: boolean;
}

export interface VehicleRecord {
  plate: string;
  registered: boolean;
  model: string;
  type: string;
  stored: boolean;
  mileage?: number;
  job?: string;
  owner?: string;
  ownerName?: string;
  ownerSsn?: string;
  ownerPhone?: string;
  flags: {
    isStolen: boolean;
    isImpounded: boolean;
    impoundReason?: string;
    impoundBy?: string;
    impoundAt?: string;
    hasBolo: boolean;
    boloReason?: string;
    notes?: string;
  };
  reports: ReportRow[];
}

export interface Tag {
  id: number;
  label: string;
  icon: string;
  color: string;
}

export type ReportStatus = 'draft' | 'open' | 'closed';

export interface ReportRow {
  id: number;
  title: string;
  officer?: string;
  officerId?: string;
  location?: string;
  status: ReportStatus;
  isConfidential?: boolean;
  date: string;
  updatedAt?: string;
  involvedCount?: number;
  role?: string;
  tags?: Tag[];
}

export type InvolvedRole = 'suspect' | 'victim' | 'witness';

export interface ReportInvolved {
  identifier: string;
  role: InvolvedRole;
  firstName: string;
  lastName: string;
  ssn?: string;
}

export interface ReportDetail extends ReportRow {
  description: string;
  involved: ReportInvolved[];
  vehicles: { plate: string; model?: string; owner?: string; ownerName?: string }[];
  tags: Tag[];
}

export interface PenalArticle {
  id: number;
  code?: string;
  categoryId?: number;
  title: string;
  description: string;
  fine: number;
  jailMonths: number;
  isFelony: boolean;
}

export interface PenalCategory {
  id: number;
  label: string;
  icon: string;
  sortOrder: number;
  articles: PenalArticle[];
}

export interface WantedRow {
  identifier: string;
  firstName: string;
  lastName: string;
  ssn?: string;
  nationality: string;
  job: string;
  mugshot?: string;
  reason: string;
  wantedBy?: string;
  wantedAt?: string;
  chargeCount: number;
}

export interface JailRow {
  identifier: string;
  firstName: string;
  lastName: string;
  ssn?: string;
  mugshot?: string;
  secondsRemaining: number;
  totalSeconds: number;
  timeLabel: string;
  reason?: string;
  cell?: string;
  officer?: string;
  jailedAt?: string;
  online: boolean;
}

export interface RosterRow {
  identifier: string;
  firstName: string;
  lastName: string;
  ssn?: string;
  mugshot?: string;
  grade: number;
  gradeLabel: string;
  onDuty: boolean;
  online: boolean;
  secondsThisMonth: number;
}

export interface RadioChannel {
  id: string;
  label: string;
  short: string;
  channel: number;
  connected: boolean;
}

export interface RadioState {
  enabled: boolean;
  current?: string;
  currentLabel?: string;
  currentNumber?: number;
  channels: RadioChannel[];
  volume: number;
  listeners: number;
  talking: boolean;
}

/**
 * Finestra trasparente della cornice (web/assets/tablet.png), in frazioni
 * dell'immagine. Il client le calcola da Config.UI.frame: la UI le usa come
 * percentuali e non conosce le misure in pixel del PNG.
 */
export interface FrameInset {
  left: number;
  top: number;
  width: number;
  height: number;
}

export interface Geometry {
  /** Schermata utile, dentro la cornice. Da qui deriva rootFontSize. */
  width: number;
  height: number;
  /** Ingombro fisico del dispositivo, cornice compresa. */
  frameWidth: number;
  frameHeight: number;
  /** Assente quando Config.UI.frame.enabled e' falso. */
  frameInset?: FrameInset;
  screenWidth: number;
  screenHeight: number;
  rootFontSize: number;
}

export interface GameStatus {
  location: string;
  time: string;
  inVehicle?: boolean;
}

export type InvalidateScope =
  | 'citizen'
  | 'citizens'
  | 'reports'
  | 'wanted'
  | 'vehicles'
  | 'jail'
  | 'penalcode'
  | 'roster';

export interface InvalidatePayload {
  scope: InvalidateScope;
  id?: string;
}
