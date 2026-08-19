/** Scheletro di caricamento: mantiene l'altezza di riga, così la tabella non
 *  salta quando i dati arrivano. */

export function Skeleton({ className }: { className?: string }): JSX.Element {
  return <span className={['kf-skeleton block rounded-sm bg-raised', className ?? ''].join(' ')} />;
}

/** N righe fantasma alte quanto una riga reale (3.4rem). */
export function SkeletonRows({ rows = 6 }: { rows?: number }): JSX.Element {
  return (
    <div className="flex flex-col">
      {Array.from({ length: rows }, (_, index) => (
        <div key={index} className="flex h-row items-center gap-3 border-b border-line-soft px-4">
          <Skeleton className="h-9 w-9" />
          <Skeleton className="h-3.5 flex-[1.15]" />
          <Skeleton className="h-3.5 flex-[1.4]" />
          <Skeleton className="h-3.5 flex-1" />
          <Skeleton className="h-3.5 flex-[1.3]" />
          <Skeleton className="h-9 w-9" />
        </div>
      ))}
    </div>
  );
}

export default Skeleton;
