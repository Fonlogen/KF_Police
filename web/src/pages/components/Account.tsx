import React from 'react'

interface AccountProps {
  playerData: any;
  theme: string;
}

function Account({ playerData, theme }: AccountProps) {
  return (
    <div className="account flex flex-row gap-2 p-[5px] px-[10px] bg-[#171717] items-center">
      <img src={playerData?.image || 'https://via.placeholder.com/150'} alt="Player Avatar" className="avatar w-[40px] h-[40px] rounded-[50%] border-[3px] border-white" />
      <div className="player-info flex flex-col items-start">
        <span className="player-name text-white text-lg font-bold">{playerData?.firstName || 'Guest'} {playerData?.lastName || ''}</span>
        <span className="player-grade text-sm">{playerData?.grade || 'No degree'}</span>
      </div>
    </div>
  )
}

export default Account