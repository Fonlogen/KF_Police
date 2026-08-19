import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { callMdt, isBrowser } from '../lib/nui';
import { useNuiEvent } from '../hooks/useNuiEvent';
import type {
  Bootstrap,
  Counters,
  GameStatus,
  Geometry,
  InvalidatePayload,
  InvalidateScope,
  Officer,
  PageKey,
  RadioState,
} from '../lib/types';
import type { IconKey } from '../components/Icon';
import type { ToastItem, ToastTone } from '../components/Toast';
import { PAGES } from '../pages/registry';

/**
 * Stato del MDT.
 * Un solo contesto per bootstrap, permessi, linguette, invalidazioni e
 * notifiche. Gli hook sono sempre chiamati in cima e senza condizioni: la
 * vecchia UI aveva `while (!context) { context = useContext(...) }` (bug U2).
 */

export type TabKind = 'page' | 'citizen' | 'vehicle' | 'report';

export interface Tab {
  id: string;
  kind: TabKind;
  pageKey?: PageKey;
  refId?: string;
  title: string;
  icon: IconKey;
  closable: boolean;
}

interface MdtState {
  ready: boolean;
  officer: Officer | null;
  permissions: Set<string>;
  can: (permission: string) => boolean;
  pages: PageKey[];
  counters: Counters;
  geometry: Geometry | null;
  status: GameStatus;
  radio: RadioState | null;
  defaultImage: string;

  tabs: Tab[];
  activeTabId: string;
  setActiveTab: (id: string) => void;
  openPage: (page: PageKey) => void;
  openCitizen: (identifier: string, name?: string) => void;
  openVehicle: (plate: string) => void;
  openReport: (id: number | 'new', title?: string) => void;
  closeTab: (id: string) => void;

  sidebarCollapsed: boolean;
  toggleSidebar: () => void;

  notify: (message: string, tone?: ToastTone) => void;
  toasts: ToastItem[];
  dismissToast: (id: number) => void;

  /** Contatore che cambia quando il server invalida uno scope. */
  revision: Record<InvalidateScope, number>;
  bumpRevision: (scope: InvalidateScope) => void;

  refreshRadio: () => void;
  refreshCounters: () => void;
}

const MdtContext = createContext<MdtState | null>(null);

const EMPTY_COUNTERS: Counters = { wanted: 0, jail: 0, reports: 0, duty: 0 };

const EMPTY_REVISION: Record<InvalidateScope, number> = {
  citizen: 0,
  citizens: 0,
  reports: 0,
  wanted: 0,
  vehicles: 0,
  jail: 0,
  penalcode: 0,
  roster: 0,
};

let toastSeq = 0;

export function MdtProvider({ children }: { children: ReactNode }): JSX.Element {
  const [ready, setReady] = useState(false);
  const [officer, setOfficer] = useState<Officer | null>(null);
  const [permissions, setPermissions] = useState<Set<string>>(new Set());
  const [pages, setPages] = useState<PageKey[]>([]);
  const [counters, setCounters] = useState<Counters>(EMPTY_COUNTERS);
  const [geometry, setGeometry] = useState<Geometry | null>(null);
  const [status, setStatus] = useState<GameStatus>({ location: 'Los Santos', time: '--:--' });
  const [radio, setRadio] = useState<RadioState | null>(null);
  const [defaultImage, setDefaultImage] = useState('assets/guest.png');

  const [tabs, setTabs] = useState<Tab[]>([]);
  const [activeTabId, setActiveTabId] = useState('');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const [revision, setRevision] = useState<Record<InvalidateScope, number>>(EMPTY_REVISION);

  const tabSeq = useRef(0);

  const notify = useCallback((message: string, tone: ToastTone = 'inform') => {
    if (!message) return;

    toastSeq += 1;
    const item: ToastItem = { id: toastSeq, message, type: tone };
    setToasts((prev) => [...prev.slice(-3), item]);
  }, []);

  const dismissToast = useCallback((id: number) => {
    setToasts((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const bumpRevision = useCallback((scope: InvalidateScope) => {
    setRevision((prev) => ({ ...prev, [scope]: prev[scope] + 1 }));
  }, []);

  // --------------------------------------------------------------------------
  //  Linguette
  // --------------------------------------------------------------------------

  const pushTab = useCallback((tab: Omit<Tab, 'id'> & { id?: string }) => {
    const id = tab.id ?? `${tab.kind}:${tab.refId ?? tab.pageKey ?? ++tabSeq.current}`;

    setTabs((prev) => {
      const existing = prev.find((entry) => entry.id === id);
      if (existing) return prev;

      return [...prev, { ...tab, id }];
    });

    setActiveTabId(id);
  }, []);

  const openPage = useCallback(
    (page: PageKey) => {
      const definition = PAGES[page];
      if (!definition) return;

      pushTab({
        id: `page:${page}`,
        kind: 'page',
        pageKey: page,
        title: definition.label,
        icon: definition.icon,
        closable: false,
      });
    },
    [pushTab],
  );

  const openCitizen = useCallback(
    (identifier: string, name?: string) => {
      pushTab({
        id: `citizen:${identifier}`,
        kind: 'citizen',
        refId: identifier,
        title: name ?? 'Fascicolo',
        icon: 'identity',
        closable: true,
      });
    },
    [pushTab],
  );

  const openVehicle = useCallback(
    (plate: string) => {
      pushTab({
        id: `vehicle:${plate}`,
        kind: 'vehicle',
        refId: plate,
        title: plate,
        icon: 'vehicles',
        closable: true,
      });
    },
    [pushTab],
  );

  const openReport = useCallback(
    (id: number | 'new', title?: string) => {
      pushTab({
        id: `report:${id}`,
        kind: 'report',
        refId: String(id),
        title: title ?? (id === 'new' ? 'Nuovo rapporto' : `Rapporto #${id}`),
        icon: 'reports',
        closable: true,
      });
    },
    [pushTab],
  );

  const closeTab = useCallback((id: string) => {
    setTabs((prev) => {
      const index = prev.findIndex((tab) => tab.id === id);
      if (index === -1) return prev;

      const next = prev.filter((tab) => tab.id !== id);

      setActiveTabId((current) => {
        if (current !== id) return current;
        const fallback = next[index] ?? next[index - 1] ?? next[0];
        return fallback ? fallback.id : '';
      });

      return next;
    });
  }, []);

  // --------------------------------------------------------------------------
  //  Bootstrap
  // --------------------------------------------------------------------------

  const applyBootstrap = useCallback(
    (data: Bootstrap) => {
      setOfficer(data.officer);
      setPermissions(new Set(data.permissions ?? []));
      setPages(data.pages ?? []);
      setCounters(data.counters ?? EMPTY_COUNTERS);
      setDefaultImage(data.ui?.defaultImage ?? 'assets/guest.png');
      setReady(true);

      // Prima pagina abilitata come linguetta iniziale.
      const first = (data.pages ?? []).find((page) => PAGES[page]);
      if (first) {
        const definition = PAGES[first];
        const id = `page:${first}`;
        setTabs([
          {
            id,
            kind: 'page',
            pageKey: first,
            title: definition.label,
            icon: definition.icon,
            closable: false,
          },
        ]);
        setActiveTabId(id);
      }
    },
    [],
  );

  useNuiEvent<Bootstrap>('mdt:bootstrap', applyBootstrap);
  useNuiEvent<Geometry>('mdt:geometry', (data) => setGeometry(data));
  useNuiEvent<GameStatus>('mdt:status', (data) => setStatus((prev) => ({ ...prev, ...data })));
  useNuiEvent<Counters>('mdt:counters', (data) => setCounters((prev) => ({ ...prev, ...data })));
  useNuiEvent<RadioState>('mdt:radio', (data) => setRadio(data));

  useNuiEvent<{ onDuty: boolean }>('mdt:duty', (data) => {
    setOfficer((prev) => (prev ? { ...prev, onDuty: data.onDuty } : prev));
  });

  useNuiEvent<{ message: string; type: ToastTone }>('mdt:notify', (data) => {
    notify(data.message, data.type);
  });

  useNuiEvent<InvalidatePayload>('mdt:invalidate', (data) => {
    if (data?.scope) bumpRevision(data.scope);
  });

  useNuiEvent<{ view: 'citizen' | 'vehicle'; id: string }>('mdt:open', (data) => {
    if (data.view === 'citizen') openCitizen(data.id);
    if (data.view === 'vehicle') openVehicle(data.id);
  });

  // In browser il bootstrap arriva dal mock, così `npm run dev` mostra la UI.
  useEffect(() => {
    if (!isBrowser()) return;

    void callMdt('bootstrap').then((response) => {
      if (response.ok) applyBootstrap(response as Bootstrap);
    });
  }, [applyBootstrap]);

  const refreshRadio = useCallback(() => {
    void callMdt('radio:state').then((response) => {
      const payload = response as { radio?: RadioState };
      if (response.ok && payload.radio) setRadio(payload.radio);
    });
  }, []);

  const refreshCounters = useCallback(() => {
    void callMdt('bootstrap').then((response) => {
      const payload = response as Bootstrap;
      if (response.ok && payload.counters) setCounters(payload.counters);
    });
  }, []);

  const can = useCallback((permission: string) => permissions.has(permission), [permissions]);

  const value = useMemo<MdtState>(
    () => ({
      ready,
      officer,
      permissions,
      can,
      pages,
      counters,
      geometry,
      status,
      radio,
      defaultImage,
      tabs,
      activeTabId,
      setActiveTab: setActiveTabId,
      openPage,
      openCitizen,
      openVehicle,
      openReport,
      closeTab,
      sidebarCollapsed,
      toggleSidebar: () => setSidebarCollapsed((value_) => !value_),
      notify,
      toasts,
      dismissToast,
      revision,
      bumpRevision,
      refreshRadio,
      refreshCounters,
    }),
    [
      ready,
      officer,
      permissions,
      can,
      pages,
      counters,
      geometry,
      status,
      radio,
      defaultImage,
      tabs,
      activeTabId,
      openPage,
      openCitizen,
      openVehicle,
      openReport,
      closeTab,
      sidebarCollapsed,
      notify,
      toasts,
      dismissToast,
      revision,
      bumpRevision,
      refreshRadio,
      refreshCounters,
    ],
  );

  return <MdtContext.Provider value={value}>{children}</MdtContext.Provider>;
}

/**
 * Accesso al contesto. L'hook e' chiamato una volta sola, in cima al
 * componente, e lancia se il provider manca: nessun ciclo di attesa (bug U2).
 */
export function useMdt(): MdtState {
  const context = useContext(MdtContext);

  if (!context) {
    throw new Error('useMdt richiede MdtProvider');
  }

  return context;
}

export default MdtProvider;
