import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React, { useContext, useEffect } from 'react'
import { MDTContext } from '../App';
import PuffLoader from 'react-spinners/PuffLoader';
import { 
  faCircleInfo, 
  faUser,
  faEye
} from '@fortawesome/free-solid-svg-icons';
import DataTable from '../components/DataTable';

function VehicleSearch() {
  
  let context = useContext(MDTContext);
  while (!context) {
    context = useContext(MDTContext);
    return <PuffLoader color={'#ffffff'} loading={true} size={50} />;
  }

  const { data, search, setSelectedData, setActiveComponent, theme } = context;
  
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

  return (
    <>
      { data === null && (
        <div className='flex h-full w-full items-center justify-center'>
          <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        </div>
      )}
      { data !== null && (
        <div className='w-full h-full flex flex-col'>
          <div className='w-full h-full flex flex-col overflow-y-auto'>
            {/* On searchQuery change, filter data */}
            { !data &&
              <div className='flex h-full w-full items-center justify-center'>
                <PuffLoader color={'#ffffff'} loading={!data} size={50} />
              </div>
            }

            { data && !data?.vehicles &&
              <div className='flex h-full w-full items-center justify-center'>
                <PuffLoader color={'#ffffff'} loading={!data} size={50} />
              </div>
            }
            {/* Filter data.vehicles based on searchQuery (data is a object {}) */}
            {data?.vehicles &&
              <DataTable 
                columns={{
                  model: 'Modello',
                  plate: 'Targa',
                  owner: 'Proprietario',
                  actions: 'Azioni',
                }}
                rows={Object.keys(data?.vehicles)
                  .filter((vehicle: any) => {
                    let veh = data?.vehicles[vehicle];
                    // if (!search) console.log('No search query', search);
                    if (search === '' || !search) return vehicle;
                    else if (veh?.model?.toLowerCase().includes(search)) return vehicle;
                    else if (veh?.plate?.toLowerCase().includes(search)) return vehicle;
                    else if (veh?.owner?.toLowerCase().includes(search)) return vehicle;
                  })
                  .map((vehicle: any) => {
                    let citizen = data?.citizens[data?.vehicles[vehicle]?.owner];
                    let veh = data?.vehicles[vehicle];

                    if (!citizen) {
                      citizen = {
                        disabled: true,
                        firstname: 'Sconosciuto',
                        lastname: 'Sconosciuto',
                      }
                    }

                    return {
                      model: veh.model,
                      plate: veh.plate,
                      owner: citizen.firstname + ' ' + citizen.lastname,
                      actions: [
                        {
                          type: 'button',
                          // label: 'Visualizza',
                          icon: faEye,
                          tooltip: {
                            place: 'bottom',
                            text: 'Informazioni veicolo',
                            variant: 'info',
                          },
                          function: () => {
                            if (citizen.disabled) return;
                            setSelectedData(veh);
                            setActiveComponent('vehicle_data');
                          },
                          style: 'bg-green-500',
                        },
                        {
                          type: 'button',
                          // label: 'Azioni',
                          icon: faUser,
                          tooltip: {
                            place: 'bottom',
                            text: 'Informazioni proprietario',
                            // variant: 'info',
                          },
                          function: () => {
                            if (citizen.disabled) return;
                            setSelectedData(citizen);
                            loadCitizenComponent(citizen, theme);
                          },
                        },
                      ]
                    }
                  })
                }
                // header='Veicoli'
                emptyMessage='Nessun veicolo trovato'
                style={{
                  body: 'h-full',
                  table: 'h-full',
                }}
              />
            }

          </div>
        </div>
      )}
    </>
  )
}

export default VehicleSearch