import { faSearch } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import React from 'react'
import { MDTContext } from '../App';

interface SearchBarProps {
  setSearchQuery: (query: string) => void    
}

function SearchBar({ setSearchQuery }: SearchBarProps) {

  const { setSearch } = React.useContext(MDTContext);

  return (
    <div className="search-bar flex flex-row gap-2 items-center">
      <FontAwesomeIcon icon={faSearch} className="text-white" />
      <input type="text" className="w-[250px] bg-[#101010] text-white px-2 py-1 outline-none" placeholder="Cerca..." 
        onChange={(e) => {
          // console.log('Setting new Search Query:', e.target.value);
          setSearch(e.target.value.toLowerCase());
        }}
      />
    </div>
  )
}

export default SearchBar