import React, { useContext } from 'react'
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';

import DataTable from '../components/DataTable';
import {
  faEye,
  faFileAlt,
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CreateReport from './CreateReport';

function Reports() {

  let context = useContext(MDTContext);
  while (!context) {
    context = useContext(MDTContext);
    return <PuffLoader color={'#ffffff'} loading={true} size={50} />;
  }

  const { data, search, setSelectedData, setActiveComponent, theme, setHeader } = context;

  const createReport = async (theme: string) => {
    const { default: CreateReport } = await import('./CreateReport');
    setActiveComponent({
      component: CreateReport,
      props: {
        theme: theme,
      },
    });

    setHeader('Creazione Report');
  };

  const viewReport = async (report: any, theme: string) => {
    const { default: ViewReport } = await import('./ViewReport');
    console.log('Viewing Report:', report);
    setActiveComponent({
      component: ViewReport,
      props: {
        report: report,
        theme: theme,
      },
    });

    setHeader('Visualizzazione Report #' + report);
  }

  return (
    <>
      {data === null && (
        <div className='flex h-full w-full items-center justify-center'>
          <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        </div>
      )}
      {data !== null && (
        <div className='w-full h-full flex flex-col relative'>

          <button className='absolute btn btn-primary bg-black/80 backdrop-blur-lg text-blue-600 px-1 py-1 flex gap-2 items-center rounded-2xl bottom-5 left-0 right-0 mx-auto z-50 w-fit pr-3 hover:bg-black/100 hover:text-white' onClick={() => createReport(theme)}>
            <span className='text-white bg-gray-900/50 rounded-xl px-4 py-[10px] pointer-events-none'>
              <FontAwesomeIcon icon={faFileAlt} />
            </span>
            Crea un report
          </button>


          <div className='w-full h-full flex flex-col overflow-y-auto'>
            {/* On searchQuery change, filter data */}
            {!data &&
              <div className='flex h-full w-full items-center justify-center'>
                <PuffLoader color={'#ffffff'} loading={!data} size={50} />
              </div>
            }

            {data?.reports &&
              <div className='flex flex-col gap-3 rounded-lg px-1'>
                {
                  Object.keys(data.reports)
                    .filter((key: any) => {
                      const report = data.reports[key];
                      const searchString = search.toLowerCase();
                      return (
                        report.title?.toLowerCase().includes(searchString) ||
                        report.description?.toLowerCase().includes(searchString) ||
                        report.date?.toLowerCase().includes(searchString) ||
                        report.officer?.toLowerCase().includes(searchString) ||
                        (report.tags && report.tags.some((tag: any) => data.tags[tag]?.label.toLowerCase().includes(searchString)))
                      );
                    })
                    .sort((a: any, b: any) => new Date(data.reports[b].date).getTime() - new Date(data.reports[a].date).getTime())
                    .map((reportKey: any, index: number) => {
                      const report = data.reports[reportKey];
                      return (
                        <div key={index} className='flex flex-col gap-2 px-4 py-3 bg-[#252525] items-center rounded-2xl w-full h-26 max-h-26 overflow-hidden'>
                          <div className='flex flex-row gap-2 w-full items-center justify-between'>
                            <div className='reportlist-item-left-part flex flex-col items-start flex text-left overflow-hidden'>
                              <span className='text-white text-lg font-bold'>{report.title.substring(0, 50)}{report.title.length > 50 ? '...' : ''} </span>
                              <span className='text-sm '>{report.description.substring(0, 50)}...</span>
                            </div>
                            <div className='reportlist-item-right-part flex flex-row gap-2'>
                              <button className='btn btn-primary text-white px-2 py-1 flex gap-2 items-center hover:border-b border-blue-500 hover:text-blue-500' onClick={() => viewReport(report.id, theme)}>
                                <FontAwesomeIcon icon={faEye} />
                                Visualizza
                              </button>
                            </div>
                          </div>
                          <div className='flex flex-row gap-2 w-full items-center justify-between pt-2 border-t border-gray-600'>
                            <div className='flex flex-row gap-2 items-center'>
                              <span className='text-sm text-gray-400'>Creato da <b>{report.officer}</b> in data <b>{report.date}</b></span>
                            </div>
                            <div className='reportlist-tags flex flex-row gap-2'>
                              {report.tags &&
                                report.tags.map((tag: any, index: number) => {
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
                        </div>
                      );
                    })
                }
              </div>
            }
            {!data?.reports &&
              <div className='flex h-full w-full items-center justify-center'>
                <span>Nessun report trovato</span>
              </div>
            }
          </div>
        </div>
      )}
    </>
  )
}

export default Reports