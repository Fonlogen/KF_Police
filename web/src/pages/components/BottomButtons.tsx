import React, { useContext } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faRadio,
  faExclamationTriangle,
} from '@fortawesome/free-solid-svg-icons'
import { MDTContext } from '../App'
import { getRecordList } from '../../utils/utils'
import RadioPanel from './RadioPanel'

function BottomButtons() {
  const context = useContext(MDTContext)
  const wantedCount = getRecordList(context?.data?.wantedList).length
  const [radioOpen, setRadioOpen] = React.useState(false)

  const openWanted = async () => {
    if (!context?.setActiveComponent) return
    const { default: WantedList } = await import('../sections/WantedList')
    context.setActiveComponent({
      component: WantedList,
      label: 'Ricercati',
      name: 'wanted_list',
      hasSearch: true,
    })
    context.setHeader?.('Ricercati')
  }
  
  return (
    <div className={`bottom-buttons flex-1 gap-2 flex h-[100px] max-h-[100px]`}>
      <div className="radio-button w-[100px] h-full bg-[#252525] hover:bg-[#333333] flex items-center justify-center text-green-500 cursor-pointer" onClick={() => setRadioOpen(true)}>
        <FontAwesomeIcon icon={faRadio} className='text-3xl' />
      </div>
      <RadioPanel open={radioOpen} onClose={() => setRadioOpen(false)} />
      <div className="emergency-button flex-1 h-full bg-[#252525] hover:bg-[#333333] flex items-center justify-center gap-4 text-red-500 cursor-pointer relative" onClick={openWanted}>
        <FontAwesomeIcon icon={faExclamationTriangle} className='text-3xl'/>
        <span className="text-xl text-white font-bold">
          RICERCATI
        </span>
        <span className="text-sm text-white font-bold bg-orange-500 px-2 py-1 absolute right-0 top-0 rounded-bl-lg">
          {wantedCount > 9 ? '9+' : wantedCount}
        </span>
      </div>
    </div>
  )
}

export default BottomButtons