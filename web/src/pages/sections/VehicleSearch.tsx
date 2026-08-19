import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React, { useContext, useEffect } from 'react'
import { MDTContext } from '../App';
import PuffLoader from 'react-spinners/PuffLoader';
import { 
  faUser,
  faEye,
} from '@fortawesome/free-solid-svg-icons';
import DataTable from '../components/DataTable';
import { getById, toRecordMap } from '../../utils/utils';

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
                rows={Object.keys(toRecordMap(data?.vehicles))
                  .filter((vehicle: any) => {
                    let veh = getById(data?.vehicles, vehicle);
                    const query = (search || '').toLowerCase();
                    if (!query) return true;
                    return (
                      String(veh?.model || '').toLowerCase().includes(query) ||
                      String(veh?.plate || '').toLowerCase().includes(query) ||
                      String(veh?.owner || '').toLowerCase().includes(query)
                    );
                  })
                  .map((vehicle: any) => {
                    let veh = getById(data?.vehicles, vehicle);
                    let citizen = getById(data?.citizens, veh?.owner);

                    if (!citizen) {
                      citizen = {
                        disabled: true,
                        firstname: 'Sconosciuto',
                        lastname: '',
                      }
                    }

                    return {
                      model: veh?.label || veh?.model,
                      plate: veh?.plate,
                      owner: `${citizen.firstname || ''} ${citizen.lastname || ''}`.trim(),
                      actions: [
                        {
                          type: 'button',
                          icon: faEye,
                          tooltip: {
                            place: 'bottom',
                            text: veh?.stolen ? 'Rimuovi rubato' : 'Segna come rubato',
                            variant: 'info',
                          },
                          function: () => {
                            setSelectedData(veh);
                            setActiveComponent('vehicle_data');
                          },
                          style: veh?.stolen ? 'bg-orange-600' : 'bg-green-600',
                        },
                        {
                          type: 'button',
                          icon: faUser,
                          tooltip: {
                            place: 'bottom',
                            text: 'Informazioni proprietario',
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