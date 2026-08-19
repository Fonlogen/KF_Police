import React, { useContext, useEffect, useState } from 'react'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faRadio, faTimes, faSignal } from '@fortawesome/free-solid-svg-icons'
import { fetchNui } from '../../utils/fetchNui'
import { MDTContext } from '../App'

function RadioPanel({ open, onClose }: { open: boolean; onClose: () => void }) {
  const context = useContext(MDTContext)
  const [state, setState] = useState<any>({ channels: [], current: null, enabled: true })

  const load = async () => {
    const result = await fetchNui<any>('getRadioState', {}, {
      enabled: true,
      current: null,
      channels: context?.config?.Radio?.Channels || [],
    })
    if (result) setState(result)
  }

  useEffect(() => {
    if (open) load()
  }, [open])

  if (!open) return null

  const toggle = async (id: string) => {
    const result = await fetchNui<any>('toggleRadioChannel', { id })
    if (result?.state) setState(result.state)
  }

  return (
    <div className='absolute inset-0 z-[80] flex items-end justify-start p-4 pointer-events-none'>
      <div className='pointer-events-auto w-[320px] bg-[#171717] border border-[#333] rounded-xl p-3 shadow-xl'>
        <div className='flex items-center justify-between mb-3'>
          <h3 className='text-white font-bold flex items-center gap-2'>
            <FontAwesomeIcon icon={faRadio} className='text-green-500' />
            Radio
          </h3>
          <button className='text-gray-400 hover:text-white' onClick={onClose}>
            <FontAwesomeIcon icon={faTimes} />
          </button>
        </div>
        <div className='flex flex-col gap-2 max-h-[320px] overflow-y-auto'>
          {(state.channels || []).map((channel: any) => (
            <button
              key={channel.id}
              className={`flex items-center justify-between px-3 py-2 rounded-lg text-left ${channel.connected ? 'bg-green-800' : 'bg-[#252525] hover:bg-[#333]'}`}
              onClick={() => toggle(channel.id)}
            >
              <span className='flex items-center gap-2 text-white'>
                <span className='w-2 h-2 rounded-full' style={{ background: channel.color || '#27ae60' }} />
                {channel.label}
              </span>
              <span className='text-xs text-gray-300 flex items-center gap-1'>
                <FontAwesomeIcon icon={faSignal} />
                {channel.channel}
              </span>
            </button>
          ))}
          {(!state.channels || state.channels.length === 0) && (
            <div className='text-gray-400 text-sm'>Nessun canale disponibile</div>
          )}
        </div>
      </div>
    </div>
  )
}

export default RadioPanel
