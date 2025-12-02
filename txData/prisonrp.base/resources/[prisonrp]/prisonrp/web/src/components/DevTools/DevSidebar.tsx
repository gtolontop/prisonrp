import { useState } from 'react';
import { useUIStore } from '@stores/uiStore';
import { useInventoryStore } from '@stores/inventoryStore';
import { useLootStore } from '@stores/lootStore';
import { mockInventory, mockItemDefinitions } from '@/utils/mockData';

type ViewName = 'inventory' | 'loot' | 'storage' | 'market' | 'hud' | 'death' | null;

const DevSidebar = () => {
  const [isOpen, setIsOpen] = useState(true);
  const { activeView, setActiveView } = useUIStore();
  const { setInventory, setItemDefinitions } = useInventoryStore();
  const { setContainer, setItemDefinitions: setLootItemDefs } = useLootStore();

  const views: { name: ViewName; label: string }[] = [
    { name: 'inventory', label: 'Inventory' },
    { name: 'loot', label: 'Loot' },
    { name: 'storage', label: 'Storage' },
    { name: 'market', label: 'Market' },
    { name: 'hud', label: 'HUD' },
    { name: 'death', label: 'Death' },
  ];

  const handleViewChange = (view: ViewName) => {
    // Load mock data when opening inventory or loot views
    if (view === 'inventory') {
      setInventory(mockInventory);
      setItemDefinitions(mockItemDefinitions);
    } else if (view === 'loot') {
      // Load mock inventory for player
      setInventory(mockInventory);
      setItemDefinitions(mockItemDefinitions);

      // Load mock loot container
      setContainer({
        id: 'mock_container_1',
        label: 'Military Crate',
        type: 'container',
        grid: {
          width: 6,
          height: 6,
          items: [
            {
              id: 'loot_1',
              item_id: 'medkit',
              quantity: 1,
              position: { x: 0, y: 0 },
              rotation: 0,
              slot_type: 'grid',
            },
            {
              id: 'loot_2',
              item_id: 'water_bottle',
              quantity: 1,
              position: { x: 2, y: 0 },
              rotation: 0,
              slot_type: 'grid',
            },
            {
              id: 'loot_3',
              item_id: 'ammo_762',
              quantity: 3,
              position: { x: 0, y: 2 },
              rotation: 0,
              slot_type: 'grid',
            },
          ],
        },
      });
      setLootItemDefs(mockItemDefinitions);
    }

    setActiveView(view);
  };

  return (
    <>
      {/* Toggle */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="fixed top-4 right-4 z-[9999] bg-gray-800/90 hover:bg-gray-700 text-gray-300 px-3 py-2 text-sm rounded border border-gray-700"
      >
        {isOpen ? '✕' : 'DevTools'}
      </button>

      {/* Sidebar */}
      {isOpen && (
        <div className="fixed top-0 right-0 w-64 h-full bg-gray-900/95 border-l border-gray-800 z-[9998] p-4">
          <div className="text-xs text-gray-500 mb-4">DEV MODE</div>

          {/* Views */}
          <div className="space-y-1">
            {views.map((view) => (
              <button
                key={view.name}
                onClick={() => handleViewChange(view.name)}
                className={`w-full text-left px-3 py-2 text-sm rounded transition-colors ${
                  activeView === view.name
                    ? 'bg-gray-800 text-white'
                    : 'text-gray-400 hover:bg-gray-800/50 hover:text-gray-300'
                }`}
              >
                {view.label}
              </button>
            ))}

            <button
              onClick={() => setActiveView(null)}
              className="w-full text-left px-3 py-2 text-sm text-gray-500 hover:text-gray-400 rounded transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </>
  );
};

export default DevSidebar;
