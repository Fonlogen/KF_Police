import React from 'react'

interface BackgroundProps {
  config: any;
  image: string;
}

function Background({ config, image }: BackgroundProps) {
  return (
    <div 
      className={`background-img absolute z-0 w-[${config?.window?.width || 1280}px] h-[${config?.window?.height || 720}px] max-w-[${config?.window?.width || 1280}px] max-h-[${config?.window?.height || 720}px] overflow-hidden`}
    >
      <img src={image} alt="Background" className='w-full h-full object-cover' />
    </div>
  )
}

export default Background