import React, { useState, useContext, useEffect } from 'react';
import { PuffLoader } from 'react-spinners';
import { useNuiEvent } from '../../hooks/useNuiEvent';

import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { 
  faCircleInfo,
  faIdBadge, 
} from '@fortawesome/free-solid-svg-icons';
import Badge from '../components/Badge';
import DataTable from '../components/DataTable';

import guestImage from '../../../assets/guest.png';

interface CitizenSearchProps {
  theme: string;
  setActiveComponent: (component: React.ComponentType | any | null) => void;
  searchQuery: string;
}

const GetIcon = (icon: string | any) => {
  return <FontAwesomeIcon icon={icon} />;
};

function CitizenSearch({ theme, setActiveComponent, searchQuery }: CitizenSearchProps) {

  let context = useContext(MDTContext);
  while (!context) {
    context = useContext(MDTContext);
    return <PuffLoader color={'#ffffff'} loading={true} size={50} />;
  }

  const { data, search, setSelectedData } = context;

  // Should be async
  const loadCitizenComponent = async (citizen: any, theme: string) => {
    const { default: CitizenView } = await import('./CitizenView');
    setActiveComponent({
      component: CitizenView,
      props: {
        citizen: citizen,
        theme: theme,
      },
    });
  };

  // useEffect(() => {
  //   console.log('Search Query NEW:', search, search?.toLowerCase());
  // }, [search]);

  return (
    <>
      { data === null && (
        <div className='flex h-full w-full items-center justify-center'>
          <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        </div>
      )}

      { data !== null && (
        <DataTable
          columns={{
            image: 'Foto Segnaletica',
            name: 'Nome',
            surname: 'Cognome',
            town: 'Cittadinanza',
            job: 'Lavoro',
            actions: 'Azioni',
          }}

          rows={
            Object.keys(data?.citizens)
            .filter((citizen: any) => {
              let ctz = data?.citizens[citizen];
              // if (!search) console.log('No search query', search);

              if (search.split(' ').length > 1) {
                let searchQueries = search.split(' ');
                let found = false;

                searchQueries.forEach((query: string) => {
                  if (ctz?.firstname?.toLowerCase().includes(query) || ctz?.lastname?.toLowerCase().includes(query)) found = true;
                });

                if (found) return citizen;
              }

              if (search === '' || !search) return citizen;
              else if (ctz?.firstname?.toLowerCase().includes(search)) return citizen;
              else if (ctz?.lastname?.toLowerCase().includes(search)) return citizen;
              else if (ctz?.citizenId?.toString().includes(search)) return citizen;
              else if (ctz?.phoneNumber?.toString().includes(search)) return citizen;
              
              return null;
            })
            .sort((a: any, b: any) => {
              let ctzA = data?.citizens[a];
              let ctzB = data?.citizens[b];
              let nameA = `${ctzA?.firstname} ${ctzA?.lastname}`.toLowerCase();
              let nameB = `${ctzB?.firstname} ${ctzB?.lastname}`.toLowerCase();
              return nameA.localeCompare(nameB);
            })
            .map((citizen: any) => (
              // Get the citizen data of the citizen key
              citizen = data?.citizens[citizen],
              {
                image: citizen?.image || guestImage,
                name: citizen?.firstname,
                surname: citizen?.lastname,
                town: citizen?.town || 'Los Santos',
                job: citizen?.job?.job_label || 'Disoccupato',
                actions: {
                  type: 'button',
                  // label: 'Informazioni dettagliate',
                  icon: faCircleInfo,
                  tooltip: {
                    place: 'bottom',
                    text: 'Informazioni cittadino',
                    variant: 'info',
                  },
                  function: () => {
                    setSelectedData(citizen);
                    loadCitizenComponent(citizen, theme);
                  },
                  style: 'bg-green-500 h-10 w-10',
                },
              }
            ))
          }
          emptyMessage={`Nessun cittadino trovato` + (search ? ` per la ricerca "${search}"` : '')}
          style={{
            body: 'h-full w-full',
            table: 'h-full w-full',
            row: 'h-20 text-lg',
            cell: '[&>img]:h-16 [&>img]:w-16 h-full',
          }}
        />

        // <div className='w-full h-full flex flex-col overflow-y-auto'>
        //   {/* On searchQuery change, filter data */}
        //   { !data?.citizens &&
        //     <div className='flex h-full w-full items-center justify-center'>
        //       <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        //     </div>
        //   }
        //   {/* Filter data.citizens based on searchQuery (data is a object {}) */}
        //   {data?.citizens && 
        //   Object.keys(data?.citizens)
        //     .filter((citizen: any) => {
        //       let ctz = data?.citizens[citizen];
        //       if (!search) console.log('No search query', search);
  
        //       if (search === '' || !search) return citizen;
        //       else if (ctz?.firstname?.toLowerCase().includes(search)) return citizen;
        //       else if (ctz?.lastname?.toLowerCase().includes(search)) return citizen;
        //       else if (ctz?.citizenId?.toString().includes(search)) return citizen;
        //       else if (ctz?.phoneNumber?.toString().includes(search)) return citizen;
  
        //       console.log('No match found for:', search, citizen);
  
        //       return null;
        //     })
        //     .sort((a: any, b: any) => {
        //       let ctzA = data?.citizens[a];
        //       let ctzB = data?.citizens[b];
        //       let nameA = `${ctzA?.firstname} ${ctzA?.lastname}`.toLowerCase();
        //       let nameB = `${ctzB?.firstname} ${ctzB?.lastname}`.toLowerCase();
        //       return nameA.localeCompare(nameB);
        //     })
        //     .map((citizen: any) => (
        //       // Get the citizen data of the citizen key
        //       citizen = data?.citizens[citizen],
  
        //       <div key={citizen?.citizenId} className='citizen_card bg-[#252525] p-2 cursor-pointer hover:bg-[#333333] flex justify-between items-center'>
        //         <div className='flex items-center gap-3'>
        //           <img className='citizen_avatar w-[50px] h-[50px] bg-[#333333] rounded-full object-fill items-center' src={citizen.image} style={{
        //             objectFit: 'cover',
        //           }}></img>
        //           <div className='flex flex-col'>
        //             <div className='citizen_name text-xl flex flex-row'>{citizen?.firstname} {citizen?.lastname}
        //               {/* { citizen?.job?.job_name === 'police' && 
        //                 (<Badge job={citizen?.job} text='LSPD' size='sm' />)
        //               }
        //               { citizen?.job?.job_name === 'ambulance' && 
        //                 (<Badge job={citizen?.job} text='EMS' size='sm' />)
        //               } */}
        //               {/* { citizen?.wanted && 
        //                 (<Badge role='wanted' text='Ricercato' size='sm' />)
        //               } */}
        //             </div>
        //           </div>
        //         </div>
        //         <div className='flex flex-row bg-gray-600 gap-3 text-white items-center px-3 rounded-lg h-10 hover:bg-gray-700'
        //           onClick={() => {
    
        //             setSelectedData(citizen);
  
        //             setActiveComponent('citizen_data');
        //           }}
        //         >                
        //           <FontAwesomeIcon icon={faCircleInfo} className='text-white bg-[#00000000]' />
        //           Maggiori informazioni
        //         </div>
        //       </div>
        //     ))
          // }
        // </div>
      )}
    </>
  )
}

export default CitizenSearch;