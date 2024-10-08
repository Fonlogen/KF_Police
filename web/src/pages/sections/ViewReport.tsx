import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { 
  faEye,
  faLocationDot,
  faTimes,
} from '@fortawesome/free-solid-svg-icons';

import MDEditor, { selectWord } from "@uiw/react-md-editor";
// No import is required in the WebPack.
import "@uiw/react-md-editor/markdown-editor.css";
// No import is required in the WebPack.
import "@uiw/react-markdown-preview/markdown.css";


interface ViewReportProps {
  report: number | any;
  theme: string;
}

function ViewReport({ report }: ViewReportProps) {

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
      {data === null && (
        <div className='flex h-full w-full items-center justify-center'>
          <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        </div>
      )}
      
      {data !== null && report !== null && (
        report = typeof report === 'number' ? data.reports[report] : report,
        <div className="flex flex-col w-full h-full px-2 py-1 gap-3">
          <div className="flex flex-row justify-between items-center gap-3 text-white border-b border-gray-700 pb-4">
            <h2 className="text-2xl font-bold flex-1 text-start">Report #{report?.id} | {report?.title}</h2>
            <div className='report-tags flex flex-row items-center gap-1'>
              {report?.tags &&
                report?.tags?.map((tag: any, index: number) => {
                  const tagData = data.tags[tag];
                  return (
                    <span key={index} className={`tag bg-gray-500 text-white px-2 py-1 rounded-lg text-[10px] flex flex-row items-center gap-2`} style={
                      {
                        backgroundColor: tagData?.color
                      }
                    }>
                      {tagData?.icon && <FontAwesomeIcon icon={tagData.icon} />}
                      {tagData?.label}
                    </span>
                  );
                })
              }
            </div>
          </div>
          <div className="flex flex-col gap-3 rounded-lg text-start flex-1 overflow-y-auto bg-[#222222] text-lg text-gray-300" data-color-mode="dark">
            <MDEditor value={report?.description} preview="preview" hideToolbar={true} height={'100%'} visibleDragbar={false} />
          </div>
          <div className='flex flex-row gap-2 items-center justify-start pt-2 border-t border-gray-600 h-10'>
            <h2 className='text-lg text-white'>Cittadini coinvolti</h2>
            <div className='text-sm px-1 py-1 bg-[#222222] text-white rounded-lg h-full flex flex-row flex-1 overflow-x-auto gap-1'>
              { !report?.involved || Object.keys(report?.involved).length === 0 && (
                <span className='text-white'>Nessun cittadino coinvolto</span>
              )}

              {report?.involved &&
                report?.involved.map((involved: any, index: number, cid: number) => (
                  cid = involved,
                  involved = data?.citizens[involved],
                  <div key={index} className='text-[12px] text-white flex flex-row gap-2 items-center gap-1 bg-blue-600 px-1 rounded-md cursor-pointer hover:bg-blue-700'
                    onClick={() => loadCitizenComponent(involved, theme)}
                  >
                    <span><b>{involved.firstname} {involved.lastname}</b> | {cid}</span>
                    {/* <span className='hover:text-red-500 cursor-pointer hover:bg-blue-800 px-2 rounded-md text-md'
                      onClick={() => {
                        // Remove the citizen from the involved list
                        report.involved[index] = null;
                        // Update the report
                        data.reports[report.id] = report;
                        
                      }}
                    >
                      <FontAwesomeIcon icon={faTimes} />
                    </span> */}
                  </div>
                ))
              }
            </div>
          </div>
          <div className="flex flex-row justify-between items-center gap-3">
            <span className="text-gray-400">Creato da <b>{report?.officer}</b></span>
            <span className="text-gray-400">Creato in data <b>{report?.date}</b></span>
          </div>
        </div>
      )}
    </>
  )
}

export default ViewReport