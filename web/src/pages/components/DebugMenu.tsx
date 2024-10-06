import React from 'react'
import { useContext } from 'react'
import { MDTContext } from '../App'
import { debugData } from '../../utils/debugData';

function DebugMenu() {
  const { config, playerData, setPlayerData } = useContext(MDTContext);
  const [showMenu, setShowMenu] = React.useState(false);

  const keyHandler = (e: KeyboardEvent) => {
    if (["F4"].includes(e.code) && config.Debug) {
      setShowMenu(!showMenu);
    }
  };

  window.addEventListener("keydown", keyHandler);

  return showMenu && (
    <div className='opacity-[90%] bg-gray-800 absolute left-3 top-3 flex flex-col gap-1 w-[350px] p-3 text-center z-[10000]'>
      <h1 className='text-lg font-bold'>KF Police Debug Menu</h1>
      <span className='text-sm text-gray-400'>Press F4 to toggle this menu</span>
      <h3>Theme</h3>
      <div className='flex flex-row gap-2'>
        <button className="bg-gray-600 p-2 rounded-md hover:bg-gray-700"
          onClick={() => {
            debugData([
              {
                action: "setTheme",
                data: "police",
              },
            ]);            
          }}
        >Police</button>
        <button className="bg-gray-600 p-2 rounded-md hover:bg-gray-700"
          onClick={() => {
            debugData([
              {
                action: "setTheme",
                data: "sheriff",
              },
            ]);            
          }}
        >Sheriff</button>
        <button className="bg-gray-600 p-2 rounded-md hover:bg-gray-700"
          onClick={() => {
            debugData([
              {
                action: "setTheme",
                data: "cib",
              },
            ]);            
          }}
        >
          CIB
        </button>
      </div>
      <h3>Data</h3>
      {/* 2 text box for player firstname and player lastname in playerData */}
      <input type="text" placeholder="Player Firstname" className='bg-gray-600 p-2 rounded-md' onChange={(e) => {
        setPlayerData({
          ...playerData,
          firstName: e.target.value,
        });
      }} />
      <input type="text" placeholder="Player Lastname" className='bg-gray-600 p-2 rounded-md' onChange={(e) => {
        setPlayerData({
          ...playerData,
          lastName: e.target.value,
        });
      }} />

    </div>
  )
}

export default DebugMenu