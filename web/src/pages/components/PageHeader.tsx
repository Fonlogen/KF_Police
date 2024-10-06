import React from 'react'
import SearchBar from './SearchBar'

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faPlus } from '@fortawesome/free-solid-svg-icons'

interface PageHeaderProps {
  activeComponent: any;
  setSearchQuery?: (query: string) => void;
  header?: any;
}

function PageHeader({ activeComponent, setSearchQuery, header }: PageHeaderProps) {
  // console.log(JSON.stringify(activeComponent))
  return (
    <div className={`bottom-part bg-[#171717] w-full h-[40px] flex-1 flex items-center justify-between px-2`}>
      <div className="page-name flex flex-row gap-3 items-center text-lg">
        {header?.icon || activeComponent?.icon} 
        <span className="text-white text-xl">{header || activeComponent?.label || activeComponent?.name}</span>
      </div>
      {activeComponent?.hasSearch && (
        <div className='flex flex-row gap-2'>
          <SearchBar setSearchQuery={setSearchQuery} />
          {activeComponent?.hasPlus && (
            <div className="add-button bg-[#272727] text-white hover:bg-green-600 font-bold py-1 px-2 rounded-lg w-fit cursor-pointer ">
              <FontAwesomeIcon icon={faPlus} className="text-lg font-bold" />
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default PageHeader