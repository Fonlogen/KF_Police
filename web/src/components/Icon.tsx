/**
 * Registro centralizzato delle icone (sezione 3.8 del piano).
 *
 * Solo FontAwesome, zero emoji in tutto il progetto. Le icone non vengono
 * importate a caso nei componenti: si passa da questo registro, così un cambio
 * di icona e' una riga sola e i tag del database possono riferirsi a una chiave
 * (colonna `icon`) invece di contenere un carattere Unicode.
 */

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import {
  faUsers,
  faCar,
  faFileLines,
  faScaleBalanced,
  faSkullCrossbones,
  faHandcuffs,
  faWalkieTalkie,
  faUserShield,
  faMagnifyingGlass,
  faXmark,
  faPlus,
  faChevronRight,
  faChevronLeft,
  faChevronDown,
  faChevronUp,
  faIdCard,
  faLocationDot,
  faSignal,
  faClock,
  faTriangleExclamation,
  faFingerprint,
  faGavel,
  faGun,
  faSackDollar,
  faHandFist,
  faSprayCanSparkles,
  faWineBottle,
  faPills,
  faShieldHalved,
  faPenToSquare,
  faTrash,
  faFloppyDisk,
  faCheck,
  faBan,
  faCircleInfo,
  faRotate,
  faFilter,
  faVolumeHigh,
  faVolumeXmark,
  faMicrophone,
  faListUl,
  faBriefcase,
  faPhone,
  faCakeCandles,
  faVenusMars,
  faFlag,
  faHouse,
  faArrowLeft,
  faSort,
  faSortUp,
  faSortDown,
  faCircleCheck,
  faCircleExclamation,
  faLock,
  faKey,
  faInbox,
  faStamp,
  faCarBurst,
  faUserGroup,
} from '@fortawesome/free-solid-svg-icons';

export const ICONS = {
  /* Navigazione */
  citizens: faUsers,
  vehicles: faCar,
  reports: faFileLines,
  penalcode: faScaleBalanced,
  wanted: faSkullCrossbones,
  jail: faHandcuffs,
  radio: faWalkieTalkie,
  duty: faUserShield,

  /* Azioni */
  search: faMagnifyingGlass,
  close: faXmark,
  add: faPlus,
  open: faChevronRight,
  collapse: faChevronLeft,
  expand: faChevronRight,
  down: faChevronDown,
  up: faChevronUp,
  back: faArrowLeft,
  edit: faPenToSquare,
  delete: faTrash,
  save: faFloppyDisk,
  confirm: faCheck,
  void: faBan,
  refresh: faRotate,
  filter: faFilter,
  list: faListUl,

  /* Dati */
  identity: faIdCard,
  location: faLocationDot,
  signal: faSignal,
  clock: faClock,
  warning: faTriangleExclamation,
  evidence: faFingerprint,
  charge: faGavel,
  info: faCircleInfo,
  success: faCircleCheck,
  error: faCircleExclamation,
  phone: faPhone,
  birth: faCakeCandles,
  sex: faVenusMars,
  nationality: faFlag,
  property: faHouse,
  license: faKey,
  locked: faLock,
  stamp: faStamp,
  impound: faCarBurst,
  roster: faUserGroup,
  boss: faBriefcase,
  empty: faInbox,

  /* Ordinamento */
  sort: faSort,
  sortAsc: faSortUp,
  sortDesc: faSortDown,

  /* Radio */
  volumeOn: faVolumeHigh,
  volumeOff: faVolumeXmark,
  talking: faMicrophone,

  /* Icone usate dai tag del database (colonna `icon`) */
  weapon: faGun,
  money: faSackDollar,
  fist: faHandFist,
  spray: faSprayCanSparkles,
  drink: faWineBottle,
  drug: faPills,
  shield: faShieldHalved,
} as const;

export type IconKey = keyof typeof ICONS;

/** Chiavi di icona proveniente dal database: se non e' nel registro, si ricade
 *  su `warning` invece di rompere il rendering. */
export function resolveIcon(key: string | undefined | null): IconDefinition {
  if (key && key in ICONS) {
    return ICONS[key as IconKey];
  }

  return ICONS.warning;
}

export type IconSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';

const SIZE_VAR: Record<IconSize, string> = {
  xs: 'var(--ico-xs)',
  sm: 'var(--ico-sm)',
  md: 'var(--ico-md)',
  lg: 'var(--ico-lg)',
  xl: 'var(--ico-xl)',
  '2xl': 'var(--ico-2xl)',
};

interface IconProps {
  name: IconKey | string;
  size?: IconSize;
  className?: string;
  spin?: boolean;
}

/** Icona del registro, dimensionata dai token della scala icone. */
export function Icon({ name, size = 'lg', className, spin }: IconProps): JSX.Element {
  return (
    <FontAwesomeIcon
      icon={resolveIcon(name as string)}
      spin={spin}
      className={className}
      style={{ width: SIZE_VAR[size], height: SIZE_VAR[size] }}
    />
  );
}

export default Icon;
