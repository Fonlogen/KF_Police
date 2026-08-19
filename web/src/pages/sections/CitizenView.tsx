import React, { useContext, useState } from 'react'
import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faPhone,
  faBriefcase,
  faUser,
  faPlus,
  faSkullCrossbones,
} from '@fortawesome/free-solid-svg-icons';
import DataTable from '../components/DataTable';
import { fetchNui } from '../../utils/fetchNui';
import { getById, getRecordList, toRecordMap } from '../../utils/utils';

interface CitizenViewProps {
  citizen: any;
  theme: string;
}

function CitizenView({ citizen, theme }: CitizenViewProps) {
  const context = useContext(MDTContext);
  const [chargeId, setChargeId] = useState('');
  const [note, setNote] = useState('');
  const [wantedReason, setWantedReason] = useState('');

  if (!context) {
    return <div>Loading...</div>;
  }

  const { data } = context;
  const currentCitizen = typeof citizen === 'string' || typeof citizen === 'number'
    ? getById(data?.citizens, citizen)
    : (citizen?.citizenId ? getById(data?.citizens, citizen.citizenId) || citizen : citizen);

  if (!currentCitizen) {
    return <h1>Cittadino non trovato</h1>;
  }

  const penalcode = toRecordMap(data?.penalcode || data?.penalCode);
  const vehicles = getRecordList(data?.vehicles).filter((vehicle: any) => String(vehicle?.owner) === String(currentCitizen.citizenId));
  const records = getRecordList(currentCitizen.criminalRecord || currentCitizen.criminalRecords);
  const licenses = getRecordList(currentCitizen.licenses);
  const properties = getRecordList(currentCitizen.properties);
  const reports = getRecordList(currentCitizen.reports);
  const notes = getRecordList(currentCitizen.notes);

  const toggleWanted = async () => {
    await fetchNui('setWanted', {
      citizenId: currentCitizen.citizenId,
      wanted: !currentCitizen.wanted,
      reason: wantedReason || currentCitizen.wantedReason || 'Ricercato',
    });
  };

  const addCharge = async () => {
    if (!chargeId) return;
    await fetchNui('addCharge', {
      citizenId: currentCitizen.citizenId,
      penalId: chargeId,
    });
    setChargeId('');
  };

  const saveNote = async () => {
    if (!note.trim()) return;
    await fetchNui('saveCitizenNote', {
      citizenId: currentCitizen.citizenId,
      note,
    });
    setNote('');
  };

  return (
    <div className='flex flex-col h-full w-full p-2 gap-5'>
      <div className='flex flex-row justify-between items-center gap-3'>
        <img
          src={currentCitizen.image || 'https://via.placeholder.com/150'}
          className='w-[150px] h-[150px] rounded-full object-cover'
        />
        <div className='flex flex-col gap-2 flex-1 items-start px-3'>
          <h2 className='text-xl font-bold text-white flex flex-row items-center gap-3'>
            {currentCitizen.firstname} {currentCitizen.lastname}
            {currentCitizen.wanted && (
              <span className='text-sm bg-red-700 text-white px-2 py-1 rounded-lg'>Ricercato</span>
            )}
          </h2>
          <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
            <FontAwesomeIcon icon={faPhone} className='text-white w-5' />
            {currentCitizen.phoneNumber || currentCitizen.phone_number || 'N/A'}
          </span>
          <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
            <FontAwesomeIcon icon={faBriefcase} className='text-white w-5' />
            {currentCitizen.job?.job_label || 'Disoccupato'} {currentCitizen.job?.job_grade_label && ('• ' + currentCitizen.job.job_grade_label)}
          </span>
          <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
            <FontAwesomeIcon icon={faUser} className='text-white w-5' />
            {currentCitizen.citizenId}
          </span>
        </div>
      </div>

      <div className='flex flex-col gap-2 bg-[#222222] p-3 rounded-lg'>
        <div className='flex flex-row gap-2 items-center'>
          <select
            className='flex-1 bg-[#171717] text-white px-2 py-2 rounded-lg'
            value={chargeId}
            onChange={(e) => setChargeId(e.target.value)}
          >
            <option value=''>Aggiungi reato dal codice penale</option>
            {Object.values(penalcode).map((article: any) => (
              <option key={article.id} value={article.id}>
                {article.title || article.crime} {article.sanction ? `- ${article.sanction}` : ''}
              </option>
            ))}
          </select>
          <button className='bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-lg flex items-center gap-2' onClick={addCharge}>
            <FontAwesomeIcon icon={faPlus} />
            Aggiungi
          </button>
        </div>
        <div className='flex flex-row gap-2 items-center'>
          <input
            className='flex-1 bg-[#171717] text-white px-2 py-2 rounded-lg'
            placeholder='Motivo ricercato'
            value={wantedReason}
            onChange={(e) => setWantedReason(e.target.value)}
          />
          <button className={`${currentCitizen.wanted ? 'bg-green-700' : 'bg-red-700'} hover:opacity-90 text-white px-3 py-2 rounded-lg flex items-center gap-2`} onClick={toggleWanted}>
            <FontAwesomeIcon icon={faSkullCrossbones} />
            {currentCitizen.wanted ? 'Rimuovi ricercato' : 'Segna come ricercato'}
          </button>
        </div>
        <div className='flex flex-row gap-2 items-center'>
          <input
            className='flex-1 bg-[#171717] text-white px-2 py-2 rounded-lg'
            placeholder='Aggiungi nota operativa'
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
          <button className='bg-gray-700 hover:bg-gray-600 text-white px-3 py-2 rounded-lg' onClick={saveNote}>
            Salva nota
          </button>
        </div>
      </div>

      <DataTable
        header='Registro penale'
        emptyMessage='Nessun reato registrato'
        rows={records.map((record: any) => ({
          crime: record.crime || record.title || '-',
          date: record.date || '-',
          location: record.location || '-',
          officer: record.officer || '-',
          fine: record.fine != null ? `$${record.fine}` : (record.sanction || '-'),
        }))}
        columns={{ crime: 'Reato', date: 'Data', location: 'Luogo', officer: 'Agente', fine: 'Sanzione' }}
      />

      <DataTable
        header='Veicoli in possesso'
        emptyMessage='Nessun veicolo registrato'
        rows={vehicles.map((vehicle: any) => ({
          vehicle: vehicle.label || String(vehicle.model || '').toUpperCase(),
          plate: vehicle.plate,
          buyDate: vehicle.buyDate,
          pounded: vehicle.pounded ? 'Si' : 'No',
          stolen: vehicle.stolen ? 'Si' : 'No',
        }))}
        columns={{
          vehicle: 'Veicolo',
          plate: 'Targa',
          buyDate: 'Stato',
          pounded: 'Sequestrato',
          stolen: 'Rubato',
        }}
      />

      <DataTable
        header='Licenze in possesso'
        emptyMessage='Nessuna licenza registrata'
        rows={licenses.map((license: any) => ({
          license: license.label || license.type,
          date: license.date || 'N/A',
          status: license.status || 'active',
        }))}
        columns={{ license: 'Licenza', date: 'Data', status: 'Stato' }}
      />

      <DataTable
        header='Proprietà in possesso'
        emptyMessage='Nessuna proprietà registrata'
        rows={properties.map((property: any) => ({
          property: property.label,
          address: property.address,
          city: property.city,
        }))}
        columns={{ property: 'Proprietà', address: 'Indirizzo', city: 'Zona' }}
      />

      <DataTable
        header='Rapporti collegati'
        emptyMessage='Nessun rapporto registrato'
        rows={reports.map((report: any) => ({
          title: report.title,
          date: report.date,
          officer: report.officer,
          report: report.report || report.description,
        }))}
        columns={{ title: 'Oggetto', date: 'Data', officer: 'Agente', report: 'Rapporto' }}
      />

      <DataTable
        header='Note operative'
        emptyMessage='Nessuna nota registrata'
        rows={notes.map((item: any) => ({
          date: item.date,
          officer: item.officer,
          note: item.note,
        }))}
        columns={{ date: 'Data', officer: 'Agente', note: 'Nota' }}
      />
    </div>
  );
}

export default CitizenView
