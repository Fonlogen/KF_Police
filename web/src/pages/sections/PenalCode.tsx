import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import DataTable from '../components/DataTable';
import { getRecordList } from '../../utils/utils';

function PenalCode() {
  const context = useContext(MDTContext);

  if (!context) {
    return (
      <div className='flex h-full w-full items-center justify-center'>
        <PuffLoader color={'#ffffff'} loading={true} size={50} />
      </div>
    );
  }

  const { data, search } = context;
  const searchString = (search || '').toLowerCase();
  const articles = getRecordList(data?.penalcode || data?.penalCode).filter((article: any) => {
    if (!searchString) return true;
    return (
      String(article.title || article.crime || '').toLowerCase().includes(searchString) ||
      String(article.description || '').toLowerCase().includes(searchString) ||
      String(article.sanction || '').toLowerCase().includes(searchString)
    );
  });

  return (
    <div className='w-full h-full'>
      <DataTable
        emptyMessage='Nessun articolo trovato'
        columns={{
          id: 'Art.',
          title: 'Reato',
          description: 'Descrizione',
          sanction: 'Sanzione',
        }}
        rows={articles.map((article: any) => ({
          id: article.id,
          title: article.title || article.crime,
          description: article.description || '',
          sanction: article.sanction || `${article.fine ? `$${article.fine}` : ''} ${article.jailTime ? `| ${article.jailTime} mesi` : ''}`.trim(),
        }))}
        style={{ body: 'h-full', table: 'h-full' }}
      />
    </div>
  );
}

export default PenalCode
