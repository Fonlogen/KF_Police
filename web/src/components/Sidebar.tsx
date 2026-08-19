import Icon from './Icon';
import Avatar from './Avatar';
import { useMdt } from '../state/MdtProvider';
import { GROUP_LABELS, GROUP_ORDER, PAGES } from '../pages/registry';
import { num } from '../lib/format';
import type { PageKey } from '../lib/types';

/**
 * Sidebar - correzione richiesta n. 1 del piano.
 * ---------------------------------------------------------------------------
 * Il rail icon-only da 4.4em e' stato sostituito da una sidebar da 13rem con
 * righe icona + etichetta: altezza riga 3rem (48 px, requisito esplicito del
 * committente), icona 1.25rem, testo 0.92rem. Il pulsante di compressione resta,
 * ma il default e' espansa.
 */

const BADGE_TONE = {
  accent: 'bg-accent text-white',
  warning: 'bg-warning text-shell',
} as const;

function SidebarItem({
  page,
  active,
  collapsed,
  badge,
  onSelect,
}: {
  page: PageKey;
  active: boolean;
  collapsed: boolean;
  badge?: number;
  onSelect: () => void;
}): JSX.Element {
  const definition = PAGES[page];

  return (
    <button
      type="button"
      title={definition.label}
      onClick={onSelect}
      className={[
        'flex h-nav shrink-0 items-center gap-[0.7rem] rounded-md text-nav transition-colors duration-100',
        collapsed ? 'justify-center px-0' : 'px-[0.7rem]',
        active
          ? 'bg-active font-semibold text-fg-strong shadow-[inset_0.2rem_0_0_var(--accent)]'
          : 'font-medium text-fg-nav hover:bg-navhover hover:text-fg-navhover',
      ].join(' ')}
    >
      <Icon name={definition.icon} size="xl" />

      {collapsed ? null : <span className="min-w-0 flex-1 truncate text-left">{definition.label}</span>}

      {!collapsed && badge && badge > 0 ? (
        <span
          className={[
            'flex h-[1.3rem] min-w-[1.3rem] items-center justify-center rounded-dot px-[0.35rem]',
            'text-micro font-bold',
            BADGE_TONE[definition.badgeTone ?? 'accent'],
          ].join(' ')}
        >
          {num(badge)}
        </span>
      ) : null}
    </button>
  );
}

export function Sidebar(): JSX.Element {
  const {
    officer,
    pages,
    counters,
    tabs,
    activeTabId,
    openPage,
    sidebarCollapsed,
    toggleSidebar,
    can,
  } = useMdt();

  const activeTab = tabs.find((tab) => tab.id === activeTabId);
  const activePage = activeTab?.kind === 'page' ? activeTab.pageKey : undefined;

  const visible = pages.filter((page) => PAGES[page] && can(PAGES[page].permission));

  return (
    <nav
      className={[
        'flex shrink-0 flex-col gap-[0.2rem] border-r border-line-soft bg-chrome px-2 py-3',
        sidebarCollapsed ? 'w-sidebarmin' : 'w-sidebar',
      ].join(' ')}
    >
      {/* Brand: crest 2.5rem con l'accento del dipartimento */}
      <div
        className={[
          'flex items-center gap-[0.6rem] pb-[0.85rem] pt-[0.15rem]',
          sidebarCollapsed ? 'justify-center px-0' : 'px-[0.4rem]',
        ].join(' ')}
      >
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md bg-accent text-white">
          <Icon name="duty" size="2xl" />
        </span>

        {sidebarCollapsed ? null : (
          <span className="min-w-0">
            <b className="block truncate text-card font-bold leading-tight text-fg-strong">Los Santos</b>
            <i className="block truncate text-micro font-medium uppercase not-italic tracking-[0.08em] text-fg-muted">
              {officer?.jobLabel ?? 'Police Dept.'}
            </i>
          </span>
        )}
      </div>

      {GROUP_ORDER.map((group) => {
        const groupPages = visible.filter((page) => PAGES[page].group === group);
        if (groupPages.length === 0) return null;

        return (
          <div key={group} className="flex flex-col gap-[0.2rem]">
            {sidebarCollapsed ? (
              <span className="mx-2 my-1.5 h-px bg-line-soft" />
            ) : (
              <span className="px-[0.6rem] pb-[0.35rem] pt-[0.7rem] text-micro font-bold uppercase tracking-[0.14em] text-fg-dim">
                {GROUP_LABELS[group]}
              </span>
            )}

            {groupPages.map((page) => (
              <SidebarItem
                key={page}
                page={page}
                active={activePage === page}
                collapsed={sidebarCollapsed}
                badge={PAGES[page].badge ? counters[PAGES[page].badge as keyof typeof counters] : undefined}
                onSelect={() => openPage(page)}
              />
            ))}
          </div>
        );
      })}

      <span className="flex-1" />

      <button
        type="button"
        title={sidebarCollapsed ? 'Espandi' : 'Comprimi'}
        onClick={toggleSidebar}
        className="flex h-statusbar shrink-0 items-center justify-center gap-[0.45rem] rounded-md bg-collapse text-label font-semibold text-fg-collapse hover:text-fg-nav"
      >
        <Icon name={sidebarCollapsed ? 'expand' : 'collapse'} size="sm" />
        {sidebarCollapsed ? null : 'Comprimi'}
      </button>

      {/* Scheda agente */}
      <div
        className={[
          'mt-[0.4rem] flex items-center gap-[0.6rem] border-t border-line-soft px-2 py-[0.6rem]',
          sidebarCollapsed ? 'justify-center' : '',
        ].join(' ')}
      >
        <Avatar
          src={officer?.mugshot}
          firstName={officer?.firstName}
          lastName={officer?.lastName}
          size="card"
        />

        {sidebarCollapsed ? null : (
          <span className="min-w-0">
            <b className="block truncate text-card font-semibold leading-tight text-fg-strong">
              {officer?.name ?? 'Agente'}
            </b>
            <i className="block truncate text-micro not-italic text-fg-muted">
              {officer ? `${officer.gradeLabel} - #${officer.grade}` : ''}
            </i>
          </span>
        )}
      </div>
    </nav>
  );
}

export default Sidebar;
