import React, { useEffect, useState } from "react";
import "./App.css";
import { debugData } from "../utils/debugData";
import { fetchNui } from "../utils/fetchNui";

import DepartmentHeader from "./components/DepartmentHeader";
import PagesContainer from "./components/PagesContainer";
import BottomButtons from "./components/BottomButtons";
import Account from "./components/Account";
import PageHeader from "./components/PageHeader";

import tabletImg from '../../assets/tablet.png';
import backgroundImg from '../../assets/debug_wp.jpg';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faTimes,
  faHome,
} from '@fortawesome/free-solid-svg-icons'
import { useNuiEvent } from "../hooks/useNuiEvent";
import DebugMenu from "./components/DebugMenu";
import CitizenView from "./sections/CitizenView";
import { executeDebugData } from "../utils/debugDataList";
import {Dialog, InputDialog} from "./components/Dialog";


// Debug Data
executeDebugData();

// O Contest
export const MDTContext = React.createContext<any>(null);

type Theme = "police" | "sheriff" | "cib";

interface ReturnClientDataCompProps {
  data: unknown;
}

const ReturnClientDataComp: React.FC<ReturnClientDataCompProps> = ({
  data,
}) => (
  <>
    <h5>Returned Data:</h5>
    <pre>
      <code>{JSON.stringify(data, null)}</code>
    </pre>
  </>
);

interface ReturnData {
  x: number;
  y: number;
  z: number;
}

const App = (): JSX.Element => {
  // STATES
  const [playerData, setPlayerData] = useState<any>({});
  const [config, setConfig] = useState<any>({});
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [fullscreen, setFullscreen] = useState<boolean>(false);
  const [theme, setTheme] = useState("cib" as Theme);
  const [activeComponent, setActiveComponent] = useState<React.ComponentType | any | string | null>(null);
  const [data, setData] = useState<any>({
  });
  const [clientData, setClientData] = useState<ReturnData | null>(null);
  const [selectedData, setSelectedData] = useState<any>(null);
  const [dialogData, setDialogData] = useState<any>(null);
  const [header, setHeader] = useState<string>('');

  // NUI Event Handlers
  useNuiEvent<any>('setTheme', (data) => {
    if (data) {
      setTheme(data);
    }
  });
  useNuiEvent<any>('setConfig', (data) => {
    if (data) {
      if (config) {
        setConfig({ ...config, ...data });
      }
    }
  });
  useNuiEvent<any>('setData', (newData) => {
    if (newData) {
      if (data) {
        setData({ ...data, ...newData });
      }
    }
  });
  useNuiEvent<any>('setPlayerData', (data) => {
    if (data) {
      if (playerData) {
        setPlayerData({ ...playerData, ...data });
      }
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'F11') {
      setFullscreen(!fullscreen);
      e.preventDefault();
    }
  });

  const handleGetClientData = () => {
    fetchNui<ReturnData>("getClientData")
      .then((retData) => {
        console.dir(retData);
        setClientData(retData);
      })
      .catch((e) => {
        setClientData({ x: 500, y: 300, z: 200 });
      });
  };

  return (
    <div className={`nui-wrapper theme-${theme} z-30 relative`}>
      {/* Width and height must be window.width + borderImage.offsetX ecc */}
      { !fullscreen &&
        <div className={`tablet-image absolute z-50 pointer-events-none`}
          style={{
            height:     config?.window?.height  ? `${config.window.height + config.borderImage.heightOffset}px` : '720px',
            width:      config?.window?.width   ? `${config.window.width  + config.borderImage.widthOffset}px`  : '1080px',
            maxHeight:  config?.window?.height  ? `${config.window.height + config.borderImage.heightOffset}px` : '720px',
            maxWidth:   config?.window?.width   ? `${config.window.width  + config.borderImage.widthOffset}px`  : '1080px',
          }}
        >
          <img src={tabletImg} alt="Tablet" className="object-fill h-full w-full" />
        </div>
      }

      {
        config?.Debug &&
        <img src={backgroundImg} alt="Background" className="background-image absolute z-[-1] pointer-events-none w-full h-full" />
      }

      <div 
        className={`mdt-container flex flex-col gap-3 ${fullscreen ? 'window_fullscreen' : ''}`}
        style={
          !fullscreen
          ? {
              height: config?.window?.height ? `${config.window.height}px` : '1366px',
              width: config?.window?.width ? `${config.window.width}px` : '768px',
              maxHeight: config?.window?.height ? `${config.window.height}px` : '1366px',
              maxWidth: config?.window?.width ? `${config.window.width}px` : '768px',
            }
          : {}
        }
      >
        <MDTContext.Provider value={
          { 
            data: data, 
            setData: setData,
            config: config, 
            setConfig: setConfig,
            playerData: playerData, 
            setPlayerData: setPlayerData,
            theme: theme, 
            setTheme: setTheme,
            activeComponent: activeComponent,
            setActiveComponent: setActiveComponent,
            search: searchQuery, 
            setSearch: setSearchQuery, 
            selectedData: selectedData,
            setSelectedData: setSelectedData, 
            dialogData: dialogData,
            setDialogData: setDialogData,
            header: {
              icon: faHome,
              text: 'Benvenuto',
            },
            setHeader: setHeader,
          }
        }>
          <DebugMenu />

          {/* <Dialog 
            title={dialogData?.title} 
            body={dialogData?.message} 
            show={dialogData?.show}
            options={dialogData?.options}
            background={dialogData?.background}
            onClose={dialogData?.onClose}
            className={dialogData?.className}
            style={dialogData?.style}
          /> */}
          
          {/* <InputDialog 
            title='Testtttt'
            body='Test'
            show={true}
            options={[
              {
                type: 'input',
                inputType: 'text',
                placeholder: 'Inserisci il nome del cittadino',
              },
              {
                type: 'button',
                label: 'Cerca',
                className: 'btn-primary',
                onClick: () => {
                  console.log('Cerca');
                },
              }
            ]}
          /> */}

          <div 
            className="mdt-header flex flex-row gap-3 justify-between h-[100px]"
          >
            <DepartmentHeader deptCity='Los Santos' deptText="Police Department" deptImage="https://static.wikia.nocookie.net/diamond-city/images/c/c0/LSPD.png" className={`theme-${theme}`} />
            <div className={`header-right theme-${theme} flex flex-col gap-3 items-center h-full flex-1`}>
              <div className="top-part flex w-full justify-end gap-2 h-[50px]">
                <Account playerData={playerData} theme={theme} />
                <button className="close-button text-red-500 hover:text-red-600 px-3" onClick={() => fetchNui("hideFrame")}>
                  <FontAwesomeIcon icon={faTimes} className="text-4xl font-bold" />
                </button>
              </div>
              <PageHeader activeComponent={activeComponent} setSearchQuery={setSearchQuery} header={header} />
            </div>
          </div>
          <div className="mdt-content flex flex-row flex-1 gap-3 overflow-hidden">
            <div className="side-part w-[350px] gap-3 flex flex-col overflow-hidden">
              <PagesContainer theme={`${theme}`} setActiveComponent={setActiveComponent} />
              <BottomButtons />
            </div>

            <div className={`main-part flex-1 theme-${theme} box-border`} id='content'>
              { activeComponent && activeComponent === 'citizen_data' && (
                <CitizenView citizen={undefined} theme={""} />
              )}
              { activeComponent && activeComponent === 'vehicle_data' && (
                <h1>Vehicle data</h1>
              )}
              {activeComponent && activeComponent !== 'citizen_data' && activeComponent !== 'vehicle_data' && React.createElement(activeComponent.component, { theme, setActiveComponent, searchQuery, ...(activeComponent.props || {}) })}
              {!activeComponent && (
                <div className='flex flex-col gap-3 text-xl'>
                  <h1>Benvenuto {playerData?.firstName || 'Duce'},</h1>
                  <p>Clicca su una delle opzioni a sinistra per iniziare.</p>
                </div>
              )}
            </div>
          </div>
        </MDTContext.Provider>
      </div>
    </div>
  );
};

export default App;