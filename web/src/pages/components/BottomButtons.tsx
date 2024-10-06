import React from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faRadio,
  faExclamationTriangle,
} from '@fortawesome/free-solid-svg-icons'

function BottomButtons() {
  const [reportsNumber, setReportsNumber] = React.useState(1)
  
  return (
    <div className={`bottom-buttons flex-1 gap-2 flex h-[100px] max-h-[100px]`}>
      <div className="radio-button w-[100px] h-full bg-[#252525] hover:bg-[#333333] flex items-center justify-center text-green-500 cursor-pointer">
        <FontAwesomeIcon icon={faRadio} className='text-3xl' />
      </div>
      <div className="emergency-button flex-1 h-full bg-[#252525] hover:bg-[#333333] flex items-center justify-center gap-4 text-red-500 cursor-pointer relative">
        <FontAwesomeIcon icon={faExclamationTriangle} className='text-3xl'/>
        <span className="text-xl text-white font-bold">
          SEGNALAZIONI
        </span>
        <span className="text-sm text-white font-bold bg-orange-500 px-2 py-1 absolute right-0 top-0 rounded-bl-lg">
          {reportsNumber > 9 ? '9+' : reportsNumber}
        </span>
      </div>
    </div>
  )
}

export default BottomButtons