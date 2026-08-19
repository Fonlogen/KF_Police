import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { faEye, faFileAlt } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { getRecordList, getById, shorten, safeText } from '../../utils/utils';

function Reports() {
  const context = useContext(MDTContext);

  if (!context) {
    return (
      <div className='flex h-full w-full items-center justify-center'>
        <PuffLoader color={'#ffffff'} loading={true} size={50} />
      </div>
    );
  }

  const { data, search, setActiveComponent, theme, setHeader } = context;
  const reports = getRecordList(data?.reports);
  const searchString = (search || '').toLowerCase();

  const createReport = async () => {
    const { default: CreateReport } = await import('./CreateReport');
    setActiveComponent({
      component: CreateReport,
      props: {
        theme,
      },
    });
    setHeader('Creazione Report');
  };

  const viewReport = async (report: any) => {
    const { default: ViewReport } = await import('./ViewReport');
    setActiveComponent({
      component: ViewReport,
      props: {
        report,
        reportId: report?.id,
        theme,
      },
    });
    setHeader(`Visualizzazione Report #${report?.id ?? ''}`);
  };

  const filteredReports = reports
    .filter((report: any) => {
      if (!report) return false;
      if (!searchString) return true;

      const tagLabels = (report.tags || [])
        .map((tag: any) => getById(data?.tags, tag)?.label || '')
        .join(' ')
        .toLowerCase();

      return (
        safeText(report.title).toLowerCase().includes(searchString) ||
        safeText(report.description).toLowerCase().includes(searchString) ||
        safeText(report.date).toLowerCase().includes(searchString) ||
        safeText(report.officer).toLowerCase().includes(searchString) ||
        tagLabels.includes(searchString)
      );
    })
    .sort((a: any, b: any) => new Date(b?.date || 0).getTime() - new Date(a?.date || 0).getTime());

  return (
    <div className='w-full h-full flex flex-col relative'>
      <button
        className='absolute btn btn-primary bg-black/80 backdrop-blur-lg text-blue-600 px-1 py-1 flex gap-2 items-center rounded-2xl bottom-5 left-0 right-0 mx-auto z-50 w-fit pr-3 hover:bg-black/100 hover:text-white'
        onClick={createReport}
      >
        <span className='text-white bg-gray-900/50 rounded-xl px-4 py-[10px] pointer-events-none'>
          <FontAwesomeIcon icon={faFileAlt} />
        </span>
        Crea un report
      </button>

      <div className='w-full h-full flex flex-col overflow-y-auto'>
        {filteredReports.length === 0 && (
          <div className='flex h-full w-full items-center justify-center'>
            <span>Nessun report trovato</span>
          </div>
        )}

        {filteredReports.length > 0 && (
          <div className='flex flex-col gap-3 rounded-lg px-1'>
            {filteredReports.map((report: any) => (
              <div key={report.id} className='flex flex-col gap-2 px-4 py-3 bg-[#252525] items-center rounded-2xl w-full overflow-hidden'>
                <div className='flex flex-row gap-2 w-full items-center justify-between'>
                  <div className='flex flex-col items-start text-left overflow-hidden'>
                    <span className='text-white text-lg font-bold'>{shorten(report.title, 50) || 'Senza titolo'}</span>
                    <span className='text-sm'>{shorten(report.description, 80) || 'Nessuna descrizione'}</span>
                  </div>
                  <button
                    className='btn btn-primary text-white px-2 py-1 flex gap-2 items-center hover:border-b border-blue-500 hover:text-blue-500'
                    onClick={() => viewReport(report)}
                  >
                    <FontAwesomeIcon icon={faEye} />
                    Visualizza
                  </button>
                </div>
                <div className='flex flex-row gap-2 w-full items-center justify-between pt-2 border-t border-gray-600'>
                  <span className='text-sm text-gray-400'>
                    Creato da <b>{report.officer || 'Sconosciuto'}</b> in data <b>{report.date || 'N/A'}</b>
                  </span>
                  <div className='flex flex-row gap-2'>
                    {(report.tags || []).map((tag: any, index: number) => {
                      const tagData = getById(data?.tags, tag);
                      if (!tagData) return null;
                      return (
                        <span
                          key={`${report.id}-tag-${index}`}
                          className='tag text-white px-2 py-1 rounded-lg text-[10px] flex flex-row items-center gap-2'
                          style={{ backgroundColor: tagData.color || '#333333' }}
                        >
                          {tagData.label}
                        </span>
                      );
                    })}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default Reports
