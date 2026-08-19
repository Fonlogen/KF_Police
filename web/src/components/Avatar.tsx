import { useState } from 'react';
import { initials } from '../lib/format';

/**
 * Foto segnaletica.
 * Il ripiego e' locale (iniziali su fondo del design system): nessun host
 * esterno, perche' la NUI non ha accesso di rete garantito. Il vecchio
 * Config.DefaultImage puntava a via.placeholder.com, irraggiungibile in gioco.
 */

export type AvatarSize = 'row' | 'card' | 'sheet';

const SIZE: Record<AvatarSize, string> = {
  row: 'h-9 w-9 text-label',      /* 2.25rem: come la riga di tabella */
  card: 'h-[2.1rem] w-[2.1rem] text-label',
  sheet: 'h-24 w-24 text-section',
};

interface AvatarProps {
  src?: string | null;
  firstName?: string;
  lastName?: string;
  size?: AvatarSize;
}

export function Avatar({ src, firstName, lastName, size = 'row' }: AvatarProps): JSX.Element {
  const [failed, setFailed] = useState(false);
  const showImage = Boolean(src) && !failed;

  return (
    <span
      className={[
        'flex shrink-0 items-center justify-center overflow-hidden rounded-sm bg-avatar',
        'font-semibold text-fg-strong/70',
        SIZE[size],
      ].join(' ')}
    >
      {showImage ? (
        <img
          src={src as string}
          alt=""
          onError={() => setFailed(true)}
          className="h-full w-full object-cover"
        />
      ) : (
        initials({ firstName, lastName })
      )}
    </span>
  );
}

export default Avatar;
