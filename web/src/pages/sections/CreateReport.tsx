import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import MDEditor from '@uiw/react-md-editor';
import React, { useContext, useState } from 'react';
import { PuffLoader } from 'react-spinners';
import { MDTContext } from '../App';
import { Tooltip } from 'react-tooltip';

import { debugData } from "../../utils/debugData";

import {
  faLocationDot,
  faTimes,
  faPlus,
  faSearch,
  faAdd,
  faCheck,
} from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../../utils/fetchNui';

interface CreateReportProps {
  report: number | any;
}

function CreateReport() {
  let context = useContext(MDTContext);
  while (!context) {
    context = useContext(MDTContext);
    return <PuffLoader color={'#ffffff'} loading={true} size={50} />;
  }

  const { data, search, setSelectedData, setActiveComponent, theme, config, playerData } = context;

  const [reportData, setReportData] = React.useState<any>(null);
  const [showAddInvolvedDialog, setShowAddInvolvedDialog] = useState(false);
  const [showAddTagDialog, setShowAddTagDialog] = useState(false);

  const handleAddInvolved = (citizen: any) => {
    setReportData((prevData: any) => ({
      ...prevData,
      involved: [...(prevData?.involved || []), citizen.citizenId],
    }));
    setShowAddInvolvedDialog(false);
  };

  const handleAddTag = (tag: any) => {
    setReportData((prevData: any) => ({
      ...prevData,
      tags: [...(prevData?.tags || []), tag.id],
    }));
    setShowAddTagDialog(false);
  };

  const handleCreateReport = () => {

    reportData.officer = playerData?.firstName + ' ' + playerData?.lastName;
    reportData.id = Date.now();
    reportData.location = 'Unknown';
    // Date must be in format AAAA-MM-DD
    reportData.date = new Date().toISOString().split('T')[0];

    if (config.Debug) {
      console.log('Creating report:', reportData);
      debugData([
        {
          action: 'setData',
          data: {
            ...data,
            reports: {
              ...data.reports,
              [Date.now()]: {
                ...reportData,
              },
            }
          },
        }
      ])
      alert('Debug Report creato con successo!');
      setActiveComponent(null);
    } else {
      fetchNui('createReport', reportData);
    }
  };

  return (
    <>
      {data === null && (
        <div className='flex h-full w-full items-center justify-center'>
          <PuffLoader color={'#ffffff'} loading={!data} size={50} />
        </div>
      )}
      
      {data !== null && (
        <div className="flex flex-col w-full h-full px-2 py-1 gap-3 relative">
          <div className="flex flex-row justify-between items-center gap-3 text-white border-b border-gray-700 pb-4">
            <input type='text' className='text-xl px-2 py-1 font-bold w-full h-10 bg-[#222222] text-white rounded-lg' placeholder='Oggetto' 
              onChange={(e) => {
                setReportData({ ...reportData, title: e.target.value });
              }}
            />
          </div>

          <div className="flex flex-col gap-3 rounded-lg text-start flex-1 overflow-y-auto bg-[#222222] text-lg text-gray-300" data-color-mode="dark">
            <MDEditor value={reportData?.description} onChange={
              (value) => {
                setReportData({ ...reportData, description: value });
              }
            } preview="edit" hideToolbar={true} height={'100%'} visibleDragbar={false} />
          </div>
          <div className='flex flex-row gap-2 items-start items-center pt-2 border-t border-gray-600 h-20'>
            <Tooltip
              id={`ttp-create-report-near`}
              place={'bottom'}
              variant={'dark'}
              content={'Aggiungi persone coinvolte'}
              style={{ backgroundColor: "#121212", zIndex: 9999 }}
            />

            <span className='text-lg font-bold text-white'>Persone coinvolte</span>
            <div className='text-lg px-2 py-1 flex-1 flex bg-[#222222] gap-2 text-white rounded-lg h-full overflow-y-auto flex-row flex-wrap'>
              {reportData?.involved &&
                reportData?.involved.map((involved: any, index: number) => {
                  const citizen = data?.citizens[involved];
                  return (
                    <div key={index} className='text-[12px] text-white flex w-fit h-fit flex-row gap-2 items-center gap-1 bg-blue-600 px-1 rounded-md cursor-pointer hover:bg-blue-700'>
                      <span><b>{citizen.firstname} {citizen.lastname}</b> | {involved}</span>
                      <span className='hover:text-red-500 cursor-pointer hover:bg-blue-800 px-2 rounded-md text-md'
                        onClick={() => {
                          // Remove citizen from involved
                          setReportData((prevData: any) => ({
                            ...prevData,
                            involved: prevData.involved.filter((inv: any) => inv !== citizen.citizenId),
                          }));
                        }}
                      >
                        <FontAwesomeIcon icon={faTimes} />
                      </span>
                    </div>
                  );
                })
              }
            </div>
            <button 
              className='btn btn-primary text-white px-2 py-1 flex gap-2 items-center hover:border-b border-blue-500 hover:text-blue-500'
              data-tooltip-id={`ttp-create-report-near`}
              onClick={() => setShowAddInvolvedDialog(true)}
            >
              <FontAwesomeIcon icon={faPlus} />
            </button>
          </div>
          <div className='flex flex-row gap-2 items-center justify-start pt-2 border-t border-gray-600 h-10'>
            
            <Tooltip
              id={`ttp-create-report-tags`}
              place={'bottom'}
              variant={'dark'}
              content={'Aggiungi tag'}
              style={{ backgroundColor: "#121212", zIndex: 9999 }}
            />
            
            <div className='createreport_tags w-full h-full gap-2 flex flex-row items-center gap-1'>
              <h2 className='text-lg text-white'>Tags</h2>
              <div className='text-sm px-1 py-1 h-full bg-[#222222] text-white rounded-lg h-full flex flex-row flex-1 overflow-x-auto gap-1'>
                { reportData?.tags &&
                  reportData?.tags.map((tag: any, index: number) => {
                    const tagData = data?.tags[tag];
                    return (
                      <div key={index} className='flex flex-row gap-2 items-center bg-blue-600 px-1 rounded-md cursor-pointer hover:bg-blue-700'
                      style={{ backgroundColor: tagData?.color || '#000000' }}
                      >
                        <span>{tagData?.label}</span>
                        <span className='hover:text-red-500 cursor-pointer x-2 rounded-md text-md'
                          onClick={() => {
                            // Remove tag from tags
                            setReportData((prevData: any) => ({
                              ...prevData,
                              tags: prevData.tags.filter((t: any) => t !== tagData?.id),
                            }));
                          }}
                        >
                          <FontAwesomeIcon icon={faTimes} />
                        </span>
                      </div>
                    );
                  })
                }
              </div>
              <button
                data-tooltip-id={`ttp-create-report-tags`}
                className='btn btn-primary text-white px-2 py-1 flex gap-2 items-center hover:border-b border-blue-500 hover:text-blue-500'
                onClick={() => setShowAddTagDialog(true)}
              > 
                <FontAwesomeIcon icon={faPlus} />
              </button>
            </div>
          </div>
          <div className='flex flex-row gap-2 items-center justify-end pt-2 border-t border-gray-600'>
            
            <Tooltip
              id={`ttp-create-report-submit`}
              place={'bottom'}
              variant={'dark'}
              content={'Conferma la creazione del report'}
              style={{ backgroundColor: "#121212", zIndex: 9999 }}
            />
            
            <button 
              data-tooltip-id={`ttp-create-report-submit`}
              className='btn btn-primary text-white px-3 py-1 hover:bg-green-400 rounded-lg gap-3 flex flex-row items-center transition-all duration-300'
              onClick={handleCreateReport}
            >
              <FontAwesomeIcon icon={faCheck} />
              Crea Report
            </button>
          </div>
        </div>
      )}

      {showAddTagDialog && <AddReportTag onAdd={handleAddTag} onClose={() => setShowAddTagDialog(false)} alreadyAddedTags={reportData?.tags || []} />}
      {showAddInvolvedDialog && <AddInvolvedPeople onAdd={handleAddInvolved} onClose={() => setShowAddInvolvedDialog(false)} alreadyInvolved={reportData?.involved || []} />}
    </>
  );
}

interface AddInvolvedPeopleProps {
  onAdd: (citizen: any) => void;
  onClose: () => void;
  alreadyInvolved: string[];
}

function AddInvolvedPeople({ onAdd, onClose, alreadyInvolved }: AddInvolvedPeopleProps) {
  const context = useContext(MDTContext);

  if (!context) {
    return <div>Loading...</div>;
  }

  const { data } = context;
  const [involvedCitizenSearch, setInvolvedCitizenSearch] = React.useState<string>('');

  return (
    <div
      className='absolute top-0 left-0 w-full h-full bg-opacity-50 flex items-center justify-center bg-black z-30'
    >
      <div className='flex flex-col gap-3 bg-[#222222] rounded-lg p-3 px-4 h-[25rem] w-[25rem]'>
        <div className='flex flex-row justify-between items-center gap-3'>
          <h2 className='text-xl font-bold text-white'>Aggiungi persone coinvolte</h2>
          <button className='btn btn-primary px-2 py-1 text-red-500 flex items-center hover:text-red-400' onClick={onClose}>
            <FontAwesomeIcon icon={faTimes} />
          </button>
        </div>
        <div className='flex flex-row gap-3 items-center justify-between flex-1 overflow-hidden'>
          <div className='add_involved-citizen-list w-full h-full gap-2 flex flex-col bg-[#171717] rounded-lg overflow-y-auto'>
            { data?.citizens &&
              Object.keys(data?.citizens)
              .filter((citizen: any) => {
                const citizenData = data?.citizens[citizen];
                const searchLower = involvedCitizenSearch.toLowerCase();
                return (
                  !alreadyInvolved.includes(citizenData.citizenId) && // Exclude already involved citizens
                  (!involvedCitizenSearch ||
                  citizenData?.citizenId.toLowerCase().includes(searchLower) ||
                  citizenData?.firstname.toLowerCase().includes(searchLower) ||
                  citizenData?.lastname.toLowerCase().includes(searchLower))
                );
              })
              .map((citizen: any, index: number) => {
                const citizenData = data?.citizens[citizen];
                return (
                <div key={index} className='flex flex-row gap-2 items-center px-2 py-1 cursor-pointer hover:bg-[#191919] rounded-lg' onClick={() => onAdd(citizenData)}>
                  <img src={citizenData?.image} className='w-[30px] h-[30px] rounded-full object-fill' />
                  <div
                  className='flex flex-row gap-3 justify-between flex-1 w-full'
                  >
                  <div className='flex flex-col gap-3'>
                    <span className='text-white text-lg'>{citizenData?.firstname} {citizenData?.lastname}</span>
                  </div>
                  <span
                    className='flex text-white text-[10px] bg-[#333333] px-2 py-0 rounded-lg items-center'
                  >{citizenData?.citizenId}</span>
                  </div>
                </div>
                )
              })
            }
          </div>
        </div>
        <div className='flex flex-row gap-3 items-center justify-between'>
          <input type='text' className='text-lg py-1 bg-[#222222] hover:bg-[#191919] px-2 text-white rounded-lg flex-1' placeholder='Cerca cittadino'
            onChange={(e) => {
              setInvolvedCitizenSearch(e.target.value);
            }}
          />
          <button className='btn btn-primary text-white px-3 py-1 hover:bg-[#171717] rounded-lg gap-3 flex flex-row items-center'>
            <FontAwesomeIcon icon={faSearch} />
            Cerca
          </button>
        </div>
      </div>
    </div>
  );
}

interface AddReportTagProps {
  onAdd: (tag: any) => void;
  onClose: () => void;
  alreadyAddedTags: string[];
}

function AddReportTag({ onAdd, onClose, alreadyAddedTags = [] }: AddReportTagProps) {
  const context = useContext(MDTContext);

  if (!context) {
    return <div>Loading...</div>;
  }

  const { data } = context;
  const [tagSearch, setTagSearch] = React.useState<string>('');

  return (
    <div
      className='absolute top-0 left-0 w-full h-full bg-opacity-50 flex items-center justify-center bg-black z-30'
    >
      <div className='flex flex-col gap-3 bg-[#222222] rounded-lg p-3 px-4 h-[25rem] w-[25rem]'>
        <div className='flex flex-row justify-between items-center gap-3'>
          <h2 className='text-xl font-bold text-white'>Aggiungi Tag</h2>
          <button className='btn btn-primary px-2 py-1 text-red-500 flex items-center hover:text-red-400' onClick={onClose}>
            <FontAwesomeIcon icon={faTimes} />
          </button>
        </div>
        <div className='flex flex-row gap-3 items-center justify-between flex-1 overflow-hidden'>
          <div className='add_tag-list w-full h-full gap-2 flex flex-col bg-[#171717] rounded-lg overflow-y-auto'>
            { data?.tags &&
              Object.keys(data?.tags)
              .filter((tag: any) => {
                const tagData = data?.tags[tag];
                const searchLower = tagSearch.toLowerCase();
                return (
                  !alreadyAddedTags.includes(tagData.id) && // Exclude already added tags
                  (!tagSearch ||
                  tagData?.id.toLowerCase().includes(searchLower) ||
                  tagData?.label.toLowerCase().includes(searchLower))
                );
              })
              .map((tag: any, index: number) => {
                const tagData = data?.tags[tag];
                return (
                <div key={index} className='flex flex-row gap-2 items-center px-2 py-1 cursor-pointer hover:bg-[#191919] rounded-lg' onClick={() => onAdd(tagData)}>
                  <div
                  className='flex flex-row gap-3 justify-between flex-1 w-full'
                  >
                  <div className='flex flex-col gap-3'>
                    <span className='text-white text-lg'>{tagData?.label}</span>
                  </div>
                  {/* <span
                    className='flex text-white text-[10px] bg-[#333333] px-2 py-0 rounded-lg items-center'
                  >{tagData?.id}</span> */}
                  </div>
                </div>
                )
              })
            }
          </div>
        </div>
        <div className='flex flex-row gap-3 items-center justify-between'>
          <input type='text' className='text-lg py-1 bg-[#222222] hover:bg-[#191919] px-2 text-white rounded-lg flex-1' placeholder='Cerca tag'
            onChange={(e) => {
              setTagSearch(e.target.value);
            }}
          />
          <button className='btn btn-primary text-white px-3 py-1 hover:bg-[#171717] rounded-lg gap-3 flex flex-row items-center'>
            <FontAwesomeIcon icon={faSearch} />
            Cerca
          </button>
        </div>
      </div>
    </div>
  );
}

export default CreateReport;
export { AddInvolvedPeople, AddReportTag };