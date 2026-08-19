import Icon from './Icon';
import { useMdt } from '../state/MdtProvider';

/**
 * Linguette (sezione 3.7).
 * Inattiva: h 2.4rem, bg-tab, bordo line, senza bordo inferiore.
 * Attiva:   h 2.6rem, bg-sheet (si fonde col foglio), bordo line-perf e
 *           box-shadow interno con l'accento.
 * `white-space: nowrap` sempre: le linguette non vanno mai a capo.
 */
export function TabStrip(): JSX.Element {
  const { tabs, activeTabId, setActiveTab, closeTab, openReport, can } = useMdt();

  return (
    <div className="flex shrink-0 items-end gap-[0.2rem] px-4 pt-[0.6rem]">
      {tabs.map((tab) => {
        const active = tab.id === activeTabId;

        return (
          <div
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={[
              // `min-w-0` e' necessario: un elemento flex non scende sotto la
              // larghezza del proprio contenuto se non glielo si concede, e con
              // molte schede aperte la striscia sbordava spingendo il pulsante
              // "nuovo rapporto" fuori dal telaio. Cosi' i titoli si troncano e
              // la striscia resta su una riga sola a qualunque numero di schede.
              'flex min-w-0 max-w-[14rem] cursor-pointer items-center gap-[0.45rem] whitespace-nowrap',
              'rounded-t-md border border-b-0 px-[0.9rem] text-tab',
              active
                ? 'h-tabactive border-line-perf bg-sheet font-semibold text-fg-strong shadow-[inset_0_0.18rem_0_var(--accent)]'
                : 'h-tab border-line bg-tab font-medium text-fg-muted hover:text-fg',
            ].join(' ')}
          >
            <Icon name={tab.icon} size="lg" className="shrink-0" />
            <span className="min-w-0 truncate">{tab.title}</span>

            {tab.closable ? (
              <button
                type="button"
                title="Chiudi scheda"
                onClick={(event) => {
                  event.stopPropagation();
                  closeTab(tab.id);
                }}
                className="ml-[0.2rem] shrink-0 text-fg-dim hover:text-critical"
              >
                <Icon name="close" size="xs" />
              </button>
            ) : null}
          </div>
        );
      })}

      <span className="min-w-[0.5rem] flex-1" />

      {can('mdt.report.create') ? (
        <button
          type="button"
          title="Nuovo rapporto"
          onClick={() => openReport('new')}
          className="flex h-tab shrink-0 items-center gap-[0.45rem] rounded-t-md border border-b-0 border-line bg-tab px-[0.9rem] text-tab text-warning hover:brightness-125"
        >
          <Icon name="add" size="lg" />
        </button>
      ) : null}
    </div>
  );
}

export default TabStrip;
