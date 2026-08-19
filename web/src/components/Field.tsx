import type { ReactNode } from 'react';
import Icon, { type IconKey } from './Icon';

/**
 * Campi uniformi: input, select, textarea condividono altezza, fondo, bordo e
 * raggio. Altezza 2.3rem come da sezione 3.7, sopra il minimo cliccabile.
 */

const BASE =
  'w-full rounded-sm border border-line-inset bg-inset text-card text-fg placeholder:text-fg-dim ' +
  'transition-colors duration-100 focus:border-accent';

export function FieldLabel({ children }: { children: ReactNode }): JSX.Element {
  return (
    <span className="text-label font-semibold uppercase tracking-[0.1em] text-fg-dim">{children}</span>
  );
}

export function FieldWrap({
  label,
  hint,
  children,
}: {
  label?: string;
  hint?: string;
  children: ReactNode;
}): JSX.Element {
  return (
    <label className="flex min-w-0 flex-col gap-1.5">
      {label ? <FieldLabel>{label}</FieldLabel> : null}
      {children}
      {hint ? <span className="text-label text-fg-muted">{hint}</span> : null}
    </label>
  );
}

interface TextFieldProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  label?: string;
  hint?: string;
  icon?: IconKey;
  maxLength?: number;
  disabled?: boolean;
  numeric?: boolean;
  onEnter?: () => void;
  autoFocus?: boolean;
  className?: string;
}

export function TextField({
  value,
  onChange,
  placeholder,
  label,
  hint,
  icon,
  maxLength,
  disabled,
  numeric,
  onEnter,
  autoFocus,
  className,
}: TextFieldProps): JSX.Element {
  const input = (
    <div className={['relative flex h-field items-center', className ?? ''].join(' ')}>
      {icon ? (
        <span className="pointer-events-none absolute left-3 text-fg-muted">
          <Icon name={icon} size="lg" />
        </span>
      ) : null}
      <input
        type="text"
        value={value}
        disabled={disabled}
        maxLength={maxLength}
        autoFocus={autoFocus}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && onEnter) onEnter();
        }}
        className={[
          BASE,
          'h-field',
          icon ? 'pl-9 pr-3' : 'px-3',
          numeric ? 'num' : '',
        ].join(' ')}
      />
    </div>
  );

  if (!label && !hint) return input;

  return (
    <FieldWrap label={label} hint={hint}>
      {input}
    </FieldWrap>
  );
}

export function NumberField({
  value,
  onChange,
  label,
  hint,
  min,
  max,
  disabled,
}: {
  value: number;
  onChange: (value: number) => void;
  label?: string;
  hint?: string;
  min?: number;
  max?: number;
  disabled?: boolean;
}): JSX.Element {
  return (
    <FieldWrap label={label} hint={hint}>
      <input
        type="number"
        value={Number.isFinite(value) ? value : 0}
        min={min}
        max={max}
        disabled={disabled}
        onChange={(event) => onChange(Number(event.target.value))}
        className={[BASE, 'num h-field px-3'].join(' ')}
      />
    </FieldWrap>
  );
}

export function TextArea({
  value,
  onChange,
  label,
  hint,
  placeholder,
  rows = 6,
  maxLength,
  disabled,
}: {
  value: string;
  onChange: (value: string) => void;
  label?: string;
  hint?: string;
  placeholder?: string;
  rows?: number;
  maxLength?: number;
  disabled?: boolean;
}): JSX.Element {
  return (
    <FieldWrap label={label} hint={hint}>
      <textarea
        value={value}
        rows={rows}
        maxLength={maxLength}
        disabled={disabled}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        className={[BASE, 'resize-none px-3 py-2 leading-relaxed'].join(' ')}
      />
    </FieldWrap>
  );
}

export function SelectField<T extends string | number>({
  value,
  onChange,
  options,
  label,
  hint,
  disabled,
}: {
  value: T;
  onChange: (value: string) => void;
  options: { value: T; label: string }[];
  label?: string;
  hint?: string;
  disabled?: boolean;
}): JSX.Element {
  return (
    <FieldWrap label={label} hint={hint}>
      <select
        value={value}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
        className={[BASE, 'h-field px-3'].join(' ')}
      >
        {options.map((option) => (
          <option key={String(option.value)} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </FieldWrap>
  );
}

export function Checkbox({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: string;
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className="flex h-target items-center gap-2.5 rounded-sm px-1 text-card text-fg hover:bg-hover"
    >
      <span
        className={[
          'flex h-5 w-5 items-center justify-center rounded-sm border',
          checked ? 'border-accent bg-accent text-white' : 'border-line-inset bg-inset text-transparent',
        ].join(' ')}
      >
        <Icon name="confirm" size="sm" />
      </span>
      <span className="whitespace-nowrap">{label}</span>
    </button>
  );
}
