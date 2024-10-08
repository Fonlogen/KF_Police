import React from 'react'
import { useEffect, useContext } from 'react';
import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { 
  faTimes,
  faPhone,
  faIdBadge,
  faBriefcase,
  faUser,
} from '@fortawesome/free-solid-svg-icons';
import Badge from '../components/Badge';

import DataTable from '../components/DataTable';

interface CitizenViewProps {
  citizen: any;
  theme: string;    
}

function CitizenView({ citizen, theme }: CitizenViewProps) {

  const context = useContext(MDTContext);

  if (!context) {
    return <div>Loading...</div>;
  }

  const { data, setSelectedData, selectedData } = context;
  const paginationModel = { page: 0, pageSize: 5 };

  if (typeof citizen === 'string') {
    citizen = data?.citizens[citizen];
  }

  if (citizen !== null && !selectedData) {
    setSelectedData(citizen);
  }


  return (
    !citizen ? (
      <h1>No citizen found</h1>
    ) : (
      <div className='flex flex-col h-full w-full p-2'>
        <div className='flex flex-col gap-5'>
          <h2 className='text-2xl font-bold'>Informazioni cittadino</h2>
          <div className='flex flex-row justify-between items-center gap-3'>
            <img src={selectedData?.image} className='w-[150px] h-[150px] rounded-full object-fill' 
              style={{
                objectFit: 'cover',
              }}
            />
            <div className='flex flex-col gap-2 flex-1 items-start px-3'>
              <h2 className='text-xl font-bold text-white flex flex-row'>{selectedData?.firstname} {selectedData?.lastname}
              {/* { selectedData?.job?.job_name === 'police' && (
                <Badge job={selectedData?.job} text='LSPD' size='lg' />
              )} */}
              </h2>
              <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
                <FontAwesomeIcon icon={faPhone} className='text-white w-5' />
                {selectedData?.phoneNumber || 'No phone number'}
              </span>
              <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
                <FontAwesomeIcon icon={faBriefcase} className='text-white w-5' />
                {selectedData?.job?.job_label || 'Unemployed'} {selectedData?.job?.job_grade_label && ('• ' + selectedData?.job?.job_grade_label)}
              </span>
              <span className='text-lg text-gray-400 flex flex-row gap-3 items-center'>
                <FontAwesomeIcon icon={faUser} className='text-white w-5' />
                {selectedData?.citizenId}
              </span>
            </div>
          </div>
        
          <DataTable 
            header = 'Registro penale'
            emptyMessage = 'Nessun reato registrato'
            rows = {
              typeof selectedData?.criminalRecord === 'object' ?
              Object.keys(selectedData?.criminalRecord).map((record: any) => ({
                crime: selectedData?.criminalRecord[record]?.crime,
                date: selectedData?.criminalRecord[record]?.date,
                location: selectedData?.criminalRecord[record]?.location,
                officer: selectedData?.criminalRecord[record]?.officer
              })) : selectedData?.criminalRecord || []
            }
            columns = {
              {crime: 'Reato', date: 'Data', location: 'Stato', officer: 'Agente'}
            }
          />

          <DataTable
            header = 'Veicoli in possesso'
            emptyMessage = 'Nessun veicolo registrato'
            rows = {
              data?.vehicles && Object.keys(data?.vehicles).filter((vehicle: any) => data?.vehicles[vehicle]?.owner === selectedData?.citizenId).map((vehicle: any) => ({
                'vehicle': data?.vehicles[vehicle]?.label || data?.vehicles[vehicle]?.model?.toUpperCase(),
                'plate': data?.vehicles[vehicle]?.plate,
                'buyDate': data?.vehicles[vehicle]?.buyDate,
                'pounded': data?.vehicles[vehicle]?.pounded ? '✅' : '❌',
                'stolen': data?.vehicles[vehicle]?.stolen ? '✅' : '❌',
              }))
            }
            columns = {{
              vehicle: 'Veicolo', 
              plate: 'Targa', 
              buyDate:'Acquistato il',
              pounded: 'Sequestrato',
              stolen: 'Rubato',
            }}
          />
          
          <DataTable
            header = 'Licenze in possesso'
            emptyMessage = 'Nessuna licenza registrata'
            rows = {
              typeof selectedData?.licenses === 'object' ?
              Object.keys(selectedData?.licenses).map((license: any) => ({
                license: selectedData?.licenses[license]?.label,
                date: selectedData?.licenses[license]?.date,
                status: selectedData?.licenses[license]?.status,
              })) : selectedData?.licenses || []
            }
            columns = {
              {license: 'Licenza', date: 'Data', status: 'Stato'}
            }
          />

          <DataTable
            header = 'Proprietà in possesso'
            emptyMessage = 'Nessuna proprietà registrata'
            rows = {
              typeof selectedData?.properties === 'object' ?
              Object.keys(selectedData?.properties).map((property: any) => ({
                property: selectedData?.properties[property]?.label,
                address: selectedData?.properties[property]?.address,
                city: selectedData?.properties[property]?.city,
              })) : selectedData?.properties || []
            }
            columns = {
              {property: 'Proprietà', address: 'Indirizzo', city: 'Stato'}
            }
          />

          <DataTable 
            header = 'Rapporti e Note'
            emptyMessage = 'Nessun rapporto registrato'
            rows = {
              typeof selectedData?.reports === 'object' ?
              Object.keys(selectedData?.reports).map((report: any) => ({
                date: selectedData?.reports[report]?.date,
                officer: selectedData?.reports[report]?.officer,
                reportTitle: selectedData?.reports[report]?.title,
                report: selectedData?.reports[report]?.report,
              })) : selectedData?.reports || []
            }
            columns = {
              {title: 'Oggetto', date: 'Data', officer: 'Agente', report: 'Rapporto'}
            }
          />
        </div>
      </div>
    )
  )
}

export default CitizenView