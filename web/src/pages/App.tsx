import { useEffect, useState } from 'react';
import DeviceFrame from '../components/DeviceFrame';
import StatusBar from '../components/StatusBar';
import Sidebar from '../components/Sidebar';
import TabStrip from '../components/TabStrip';
import RadioDock from '../components/RadioDock';
import Sheet from '../components/Sheet';
import EmptyState from '../components/EmptyState';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { closeMdt, isBrowser } from '../lib/nui';
import { useMdt, type Tab } from '../state/MdtProvider';
import type { PageKey } from '../lib/types';

import CitizensPage from './CitizensPage';
import CitizenSheet from './CitizenSheet';
import VehiclesPage from './VehiclesPage';
import VehicleSheet from './VehicleSheet';
import ReportsPage from './ReportsPage';
import ReportSheet from './ReportSheet';
import PenalCodePage from './PenalCodePage';
import WantedPage from './WantedPage';
import JailPage from './JailPage';
import RadioPage from './RadioPage';
import DutyPage from './DutyPage';

/**
 * Telaio dell'applicazione.
 * ---------------------------------------------------------------------------
 * La mappa `pageKey -> componente` vive QUI e non in pages/registry.ts: quel
 * file resta di soli metadati perche' e' importato da MdtProvider, e
 * associarvi i componenti creerebbe un ciclo di import
 * (pagina -> useMdt -> provider -> registry -> pagina).
 *
 * Differenze rispetto alla versione precedente di questo file:
 *  - nessun `window.addEventListener` nel corpo del render (bug U1: ne
 *    registrava uno nuovo a ogni render, senza mai rimuoverlo);
 *  - nessuna misura in pixel calcolata a mano dal config: la geometria arriva
 *    dal client e la applica DeviceFrame, il resto e' in rem;
 *  - un solo contesto (MdtProvider) invece di MDTContext con 16 setter.
 */

const PAGE_COMPONENTS: Record<PageKey, () => JSX.Element> = {
  citizens: CitizensPage,
  vehicles: VehiclesPage,
  reports: ReportsPage,
  penalcode: PenalCodePage,
  wanted: WantedPage,
  jail: JailPage,
  radio: RadioPage,
  duty: DutyPage,
};

/** Smistamento della linguetta attiva sul componente che la disegna. */
function ActiveView({ tab }: { tab: Tab }): JSX.Element {
  if (tab.kind === 'citizen' && tab.refId) {
    return <CitizenSheet identifier={tab.refId} />;
  }

  if (tab.kind === 'vehicle' && tab.refId) {
    return <VehicleSheet plate={tab.refId} />;
  }

  if (tab.kind === 'report' && tab.refId) {
    return <ReportSheet tabId={tab.id} reportId={tab.refId === 'new' ? 'new' : Number(tab.refId)} />;
  }

  const Page = tab.pageKey ? PAGE_COMPONENTS[tab.pageKey] : undefined;

  if (!Page) {
    return (
      <Sheet>
        <EmptyState
          icon="warning"
          title="Pagina non disponibile"
          hint="La scheda non ha un contenuto associato."
        />
      </Sheet>
    );
  }

  return <Page />;
}

export function App(): JSX.Element | null {
  const { ready, tabs, activeTabId } = useMdt();

  // In browser (`npm run dev`) il tablet e' sempre aperto: il gioco non manda
  // mai `mdt:visible` e senza questo l'interfaccia non si vedrebbe mai.
  const [visible, setVisible] = useState(isBrowser);

  useNuiEvent<{ visible: boolean }>('mdt:visible', (data) => setVisible(Boolean(data?.visible)));

  // ESC chiude il tablet. Listener in useEffect con cleanup.
  useEffect(() => {
    if (!visible) return undefined;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;

      // Una modale aperta assorbe ESC: chiude se stessa, non il tablet.
      if (document.querySelector('[data-modal="open"]')) return;

      event.preventDefault();
      closeMdt();

      // In browser non c'e' un client che risponda con `mdt:visible`.
      if (isBrowser()) setVisible(false);
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible]);

  if (!visible) return null;

  const activeTab = tabs.find((tab) => tab.id === activeTabId);

  return (
    <DeviceFrame>
      <StatusBar />

      <div className="flex min-h-0 flex-1">
        <Sidebar />

        <div className="flex min-w-0 flex-1 flex-col">
          <TabStrip />

          {activeTab ? (
            <ActiveView tab={activeTab} />
          ) : (
            <Sheet>
              <EmptyState
                icon={ready ? 'empty' : 'refresh'}
                title={ready ? 'Nessuna scheda aperta' : 'Connessione al terminale'}
                hint={ready ? 'Scegli una voce dal menu a sinistra.' : undefined}
              />
            </Sheet>
          )}

          <RadioDock />
        </div>
      </div>
    </DeviceFrame>
  );
}

export default App;
