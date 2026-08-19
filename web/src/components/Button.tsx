import type { ReactNode } from 'react';
import Icon, { type IconKey, type IconSize } from './Icon';

/**
 * Pulsante del design system.
 * Le classi sono mappe statiche e complete: Tailwind non genera mai una classe
 * costruita per concatenazione (causa dei bug U3/U4).
 */

export type ButtonVariant = 'primary' | 'ghost' | 'danger' | 'warning';
export type ButtonSize = 'sm' | 'md' | 'lg';

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-accent text-white border-accent hover:brightness-110',
  ghost: 'bg-control text-fg border-line-ctrl hover:bg-hover',
  danger: 'bg-critical/10 text-critical border-critical hover:bg-critical/20',
  warning: 'bg-control text-warning border-line-ctrl hover:bg-hover',
};

const SIZE: Record<ButtonSize, string> = {
  sm: 'h-btnsm px-3 text-status',
  md: 'h-btnmd px-4 text-card',
  lg: 'h-btnlg px-5 text-data',
};

const ICON_SIZE: Record<ButtonSize, IconSize> = {
  sm: 'lg',
  md: 'lg',
  lg: 'xl',
};

interface ButtonProps {
  children?: ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  icon?: IconKey;
  onClick?: () => void;
  disabled?: boolean;
  title?: string;
  className?: string;
  fullWidth?: boolean;
}

export function Button({
  children,
  variant = 'ghost',
  size = 'sm',
  icon,
  onClick,
  disabled,
  title,
  className,
  fullWidth,
}: ButtonProps): JSX.Element {
  return (
    <button
      type="button"
      title={title}
      disabled={disabled}
      onClick={onClick}
      className={[
        'inline-flex items-center justify-center gap-2 rounded-sm border font-medium',
        'transition-[filter,background-color] duration-100',
        'disabled:opacity-40 disabled:cursor-not-allowed',
        VARIANT[variant],
        SIZE[size],
        fullWidth ? 'w-full' : '',
        className ?? '',
      ].join(' ')}
    >
      {icon ? <Icon name={icon} size={ICON_SIZE[size]} /> : null}
      {children ? <span className="whitespace-nowrap">{children}</span> : null}
    </button>
  );
}

/**
 * Pulsante di sola icona. Quadrato di 2.3rem: sopra il minimo di 2.25rem
 * imposto dalla sezione 3.3 per ogni bersaglio cliccabile.
 */
export function IconButton({
  icon,
  onClick,
  title,
  disabled,
  variant = 'warning',
  className,
}: {
  icon: IconKey;
  onClick?: () => void;
  title?: string;
  disabled?: boolean;
  variant?: ButtonVariant;
  className?: string;
}): JSX.Element {
  return (
    <button
      type="button"
      title={title}
      disabled={disabled}
      onClick={onClick}
      className={[
        'inline-flex h-field w-field shrink-0 items-center justify-center rounded-sm border',
        'transition-colors duration-100 disabled:opacity-40 disabled:cursor-not-allowed',
        VARIANT[variant],
        className ?? '',
      ].join(' ')}
    >
      <Icon name={icon} size="lg" />
    </button>
  );
}

export default Button;
