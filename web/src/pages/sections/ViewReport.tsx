import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faTrash } from '@fortawesome/free-solid-svg-icons';
import MDEditor from "@uiw/react-md-editor";
import "@uiw/react-md-editor/markdown-editor.css";
import "@uiw/react-markdown-preview/markdown.css";
import { getById, getRecordList } from '../../utils/utils';
import { fetchNui } from '../../utils/fetchNui';

interface ViewReportProps {
  report?: number | any;
  reportId?: number | string;
  theme?: string;
}

function ViewReport({ report, reportId }: ViewReportProps) {
  const context = useContext(MDTContext);

  if (!context) {
    return (
      <div className='flex h-full w-full items-center justify-center'>
        <PuffLoader color={'#ffffff'} loading={true} size={50} />
      </div>
    );
  }

  const { data, setActiveComponent, theme, setHeader } = context;
  const reportKey = reportId ?? (typeof report === 'object' ? report?.id : report);
  const currentReport = typeof report === 'object' && report?.title
    ? report
    : getById(data?.reports, reportKey);

  const loadCitizenComponent = async (citizen: any) => {
    if (!citizen) return;
    const { default: CitizenView } = await import('./CitizenView');
    setActiveComponent({
      component: CitizenView,
      props: {
        citizen,
        theme,
      },
    });
    setHeader(`${citizen.firstname || ''} ${citizen.lastname || ''}`.trim());
  };

  const handleDelete = async () => {
    if (!currentReport?.id) return;
    await fetchNui('deleteReport', { id: currentReport.id });
    const { default: Reports } = await import('./Reports');
    setActiveComponent({
      component: Reports,
      props: { theme },
    });
    setHeader('Rapporti');
  };

  if (!currentReport) {
    return (
      <div className='flex h-full w-full items-center justify-center'>
        <span>Report non trovato</span>
      </div>
    );
  }

  const involvedPeople = getRecordList(currentReport.involved)
    .map((involved: any) => {
      const citizenId = typeof involved === 'object' ? involved?.citizenId || involved?.id : involved;
      return {
        citizenId,
        citizen: getById(data?.citizens, citizenId),
      };
    });

  return (
    <div className="flex flex-col w-full h-full px-2 py-1 gap-3">
      <div className="flex flex-row justify-between items-center gap-3 text-white border-b border-gray-700 pb-4">
        <h2 className="text-2xl font-bold flex-1 text-start">
          Report #{currentReport.id} | {currentReport.title || 'Senza titolo'}
        </h2>
        <div className='flex flex-row items-center gap-1'>
          {(currentReport.tags || []).map((tag: any, index: number) => {
            const tagData = getById(data?.tags, tag);
            if (!tagData) return null;
            return (
              <span
                key={`${currentReport.id}-tag-${index}`}
                className='tag text-white px-2 py-1 rounded-lg text-[10px] flex flex-row items-center gap-2'
                style={{ backgroundColor: tagData.color || '#333333' }}
              >
                {tagData.label}
              </span>
            );
          })}
        </div>
      </div>

      <div className="flex flex-col gap-3 rounded-lg text-start flex-1 overflow-y-auto bg-[#222222] text-lg text-gray-300" data-color-mode="dark">
        <MDEditor
          value={currentReport.description || 'Nessuna descrizione'}
          preview="preview"
          hideToolbar={true}
          height={'100%'}
          visibleDragbar={false}
        />
      </div>

      <div className='flex flex-row gap-2 items-center justify-start pt-2 border-t border-gray-600 min-h-10'>
        <h2 className='text-lg text-white'>Cittadini coinvolti</h2>
        <div className='text-sm px-1 py-1 bg-[#222222] text-white rounded-lg h-full flex flex-row flex-1 overflow-x-auto gap-1'>
          {involvedPeople.length === 0 && (
            <span className='text-white'>Nessun cittadino coinvolto</span>
          )}
          {involvedPeople.map(({ citizenId, citizen }: any, index: number) => (
            <div
              key={`${citizenId}-${index}`}
              className='text-[12px] text-white flex flex-row items-center gap-1 bg-blue-600 px-1 rounded-md cursor-pointer hover:bg-blue-700'
              onClick={() => loadCitizenComponent(citizen)}
            >
              <span>
                <b>{citizen ? `${citizen.firstname || ''} ${citizen.lastname || ''}`.trim() : 'Sconosciuto'}</b> | {citizenId}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="flex flex-row justify-between items-center gap-3">
        <span className="text-gray-400">Creato da <b>{currentReport.officer || 'Sconosciuto'}</b></span>
        <span className="text-gray-400">Creato in data <b>{currentReport.date || 'N/A'}</b></span>
        <button
          className='btn text-white px-3 py-1 hover:bg-red-500 rounded-lg gap-2 flex flex-row items-center'
          onClick={handleDelete}
        >
          <FontAwesomeIcon icon={faTrash} />
          Elimina
        </button>
      </div>
    </div>
  );
}

export default ViewReport
