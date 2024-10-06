import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faEye } from '@fortawesome/free-solid-svg-icons';

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
            <h2 className="text-2xl font-bold max-w-[60%]">Report #{report?.id} | {report?.title}</h2>
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
          <div className="flex flex-col gap-3 rounded-lg text-start flex-1 overflow-y-auto bg-[#222222] py-2 px-3 text-lg text-gray-300">
            {report?.description}
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