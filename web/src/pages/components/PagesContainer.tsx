import React, { useContext, useEffect } from 'react'
import { useState } from 'react'
import { useNuiEvent } from '../../hooks/useNuiEvent';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { 
  faSearch,
  faCar,
  faPeopleGroup,
  faFileAlt,
  faSkullCrossbones,
} from '@fortawesome/free-solid-svg-icons'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { fetchNui } from '../../utils/fetchNui';

// import { translate } from '../utils/translator';

interface PagesListProps {
  component: () => Promise<any>;
  label: string;
  icon: JSX.Element;
  hasSeach: boolean;
  hasPlus?: boolean;
}

export const GetIcon = (icon: any) => {
  let faIcon = icon;
  if (typeof faIcon === 'string') {
    faIcon = { prefix: 'fas', iconName: faIcon };
  } 
  return <FontAwesomeIcon icon={faIcon} className='w-[30px]'/>;
}

export const pagesList: { [key: string]: PagesListProps } = {
  citizen_search: {
    component: () => import('../sections/CitizenSearch'),
    label: 'Cerca un cittadino',
    icon: GetIcon(faPeopleGroup),
    hasSeach: true,
  },
  vehicle_search: {
    component: () => import('../sections/VehicleSearch'),
    label: 'Cerca un veicolo',
    icon: GetIcon(faCar),
    hasSeach: true,
  },
  reports: {
    component: () => import('../sections/Reports'),
    label: 'Rapporti',
    icon: GetIcon(faFileAlt),
    hasSeach: true,
    hasPlus: false,
  },
  wanted_list: {
    component: () => import('../sections/WantedList'),
    label: 'Ricercati',
    icon: GetIcon(faSkullCrossbones),
    hasSeach: true,
    hasPlus: false,
  },
  penal_code: {
    component: () => import('../sections/PenalCode'),
    label: 'Codice Penale',
    icon: GetIcon(faFileAlt),
    hasSeach: true,
  },
  
}

interface PagesContainerProps {
  theme: string;
  setActiveComponent: (component: React.ComponentType | any | null) => void;
}

function PagesContainer({ theme, setActiveComponent }: PagesContainerProps) {
  let context = useContext(MDTContext);
  while (!context) {
    context = useContext(MDTContext);
    return <PuffLoader color={'#ffffff'} loading={true} size={50} />;
  }

  const { setHeader } = context;

  const [enabledPages, setEnabledPages] = useState<string[]>([]);

  useEffect(() => {
    fetchNui('getEnabledPages');
  }, []);

  useNuiEvent<any>('setEnabledPages', (data) => {
    if (Array.isArray(data)) {
      setEnabledPages(data);
    } else {
      console.error("Received data is not an array:", data);
    }
  });

  const loadComponent = async (page: string) => {
    if (pagesList[page]) {
      const { default: Component } = await pagesList[page].component();
      setActiveComponent({
        component: Component,
        label: pagesList[page].label,
        name: page,
        icon: pagesList[page].icon,
        hasSearch: pagesList[page].hasSeach,
        hasPlus: pagesList[page].hasPlus,
      });

      setHeader(pagesList[page].label);

    } else {
      console.error(`Component for page "${page}" not found`);
    }
  };

  return (
    <div className={`pages-container bg-[#171717] theme-${theme} gap-2 text-xl flex-1 overflow-y-auto`}>
      {enabledPages.map((page: string) => (
        <div key={page} className='page_list_item bg-[#252525] p-2 cursor-pointer hover:bg-[#333333]' 
          onClick={() => {
            loadComponent(page);
          }}
        >
          <div className="page_icon w-[30px]">
            {pagesList[page]?.icon}
          </div>
          <div className="page_label flex-1">
            {pagesList[page]?.label || page}
          </div>
        </div>
      ))}
    </div>
  )
}

export default PagesContainer

function setHeader(arg0: { icon: JSX.Element; text: string; }) {
  throw new Error('Function not implemented.');
}
