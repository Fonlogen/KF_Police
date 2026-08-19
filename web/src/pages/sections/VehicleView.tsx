import React, { useContext } from 'react'
import { MDTContext } from '../App';
import { fetchNui } from '../../utils/fetchNui';
import { getById } from '../../utils/utils';

interface VehicleViewProps {
  vehicle: any;
  theme: string;
}

function VehicleView({ vehicle }: VehicleViewProps) {
  const context = useContext(MDTContext);
  if (!context) return <div>Loading...</div>;

  const { data, setActiveComponent, theme, setHeader } = context;
  const current = typeof vehicle === 'string' ? getById(data?.vehicles, vehicle) : (getById(data?.vehicles, vehicle?.plate) || vehicle);
  if (!current) return <h1>Veicolo non trovato</h1>;

  const owner = getById(data?.citizens, current.owner);

  const openOwner = async () => {
    if (!owner) return;
    const { default: CitizenView } = await import('./CitizenView');
    setActiveComponent({
      component: CitizenView,
      props: { citizen: owner, theme },
    });
    setHeader(`${owner.firstname || ''} ${owner.lastname || ''}`.trim());
  };

  return (
    <div className='flex flex-col gap-4 p-3 text-left w-full'>
      <h2 className='text-2xl font-bold text-white'>{current.label || current.model} • {current.plate}</h2>
      <div className='grid grid-cols-2 gap-3 text-gray-300'>
        <div className='bg-[#222222] p-3 rounded-lg'>Proprietario: <b>{owner ? `${owner.firstname} ${owner.lastname}` : 'Sconosciuto'}</b></div>
        <div className='bg-[#222222] p-3 rounded-lg'>Stato: <b>{current.buyDate || 'N/A'}</b></div>
        <div className='bg-[#222222] p-3 rounded-lg'>Rubato: <b>{current.stolen ? 'Si' : 'No'}</b></div>
        <div className='bg-[#222222] p-3 rounded-lg'>Sequestrato: <b>{current.pounded ? 'Si' : 'No'}</b></div>
      </div>
      <div className='flex gap-2'>
        <button className='bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-lg' onClick={openOwner}>Apri proprietario</button>
        <button className='bg-orange-600 hover:bg-orange-700 text-white px-3 py-2 rounded-lg' onClick={() => fetchNui('setVehicleFlag', { plate: current.plate, stolen: !current.stolen })}>
          {current.stolen ? 'Rimuovi rubato' : 'Segna rubato'}
        </button>
        <button className='bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded-lg' onClick={() => fetchNui('setVehicleFlag', { plate: current.plate, pounded: !current.pounded })}>
          {current.pounded ? 'Rimuovi sequestro' : 'Sequestra'}
        </button>
      </div>
    </div>
  );
}

export default VehicleView
