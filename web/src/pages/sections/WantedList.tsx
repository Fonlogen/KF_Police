import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import DataTable from '../components/DataTable';
import { faEye, faUserCheck } from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../../utils/fetchNui';
import { getById, getRecordList } from '../../utils/utils';

function WantedList() {
  const context = useContext(MDTContext);

  if (!context) {
    return (
      <div className='flex h-full w-full items-center justify-center'>
        <PuffLoader color={'#ffffff'} loading={true} size={50} />
      </div>
    );
  }

  const { data, search, setActiveComponent, theme, setHeader } = context;
  const searchString = (search || '').toLowerCase();

  const rows = getRecordList(data?.wantedList)
    .map((entry: any) => {
      const citizen = getById(data?.citizens, entry.citizen);
      return {
        ...entry,
        citizenData: citizen,
        name: citizen ? `${citizen.firstname || ''} ${citizen.lastname || ''}`.trim() : entry.citizen,
      };
    })
    .filter((entry: any) => {
      if (!searchString) return true;
      return (
        String(entry.name || '').toLowerCase().includes(searchString) ||
        String(entry.reason || '').toLowerCase().includes(searchString) ||
        String(entry.wantedBy || '').toLowerCase().includes(searchString) ||
        String(entry.citizen || '').toLowerCase().includes(searchString)
      );
    });

  const openCitizen = async (citizen: any) => {
    if (!citizen) return;
    const { default: CitizenView } = await import('./CitizenView');
    setActiveComponent({
      component: CitizenView,
      props: { citizen, theme },
    });
    setHeader(`${citizen.firstname || ''} ${citizen.lastname || ''}`.trim());
  };

  return (
    <div className='w-full h-full'>
      <DataTable
        emptyMessage='Nessun ricercato in archivio'
        columns={{
          name: 'Cittadino',
          reason: 'Motivo',
          wantedBy: 'Emesso da',
          actions: 'Azioni',
        }}
        rows={rows.map((entry: any) => ({
          name: entry.name,
          reason: entry.reason || 'Ricercato',
          wantedBy: entry.wantedBy || 'LSPD',
          actions: [
            {
              type: 'button',
              icon: faEye,
              tooltip: { place: 'bottom', text: 'Apri scheda cittadino' },
              function: () => openCitizen(entry.citizenData),
              style: 'bg-green-600',
            },
            {
              type: 'button',
              icon: faUserCheck,
              tooltip: { place: 'bottom', text: 'Rimuovi da ricercati' },
              function: () => fetchNui('setWanted', { citizenId: entry.citizen, wanted: false }),
              style: 'bg-red-600',
            },
          ],
        }))}
        style={{ body: 'h-full', table: 'h-full' }}
      />
    </div>
  );
}

export default WantedList
