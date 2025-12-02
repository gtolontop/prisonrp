import { useEffect } from 'react';
import { useUIStore } from '@stores/uiStore';
import { useInventoryStore } from '@stores/inventoryStore';
import { useLootStore } from '@stores/lootStore';
import { useVehicleStore } from '@stores/vehicleStore';
import DevSidebar from '@components/DevTools/DevSidebar';
import { CfxGameView } from '@components/CfxGameView';
import { UIConfig } from '@/config/ui';

// Views
import InventoryView from '@views/InventoryView';
import LootView from '@views/LootView';
import VehicleView from '@views/VehicleView';
import StorageView from '@views/StorageView';
import MarketView from '@views/MarketView';
import HUDView from '@views/HUDView';
import DeathView from '@views/DeathView';

function App() {
  const { activeView, setActiveView, isDevMode } = useUIStore();
  const { setInventory, setItemDefinitions } = useInventoryStore();
  const { setContainer, setItemDefinitions: setLootItemDefs, closeContainer } = useLootStore();
  const { setVehicle, closeVehicle } = useVehicleStore();


  useEffect(() => {
    // Listen for NUI messages from FiveM
    const handleMessage = (event: MessageEvent) => {
      const { type, data } = event.data;

      console.log('[NUI] Received:', type, data);

      // Route messages to appropriate stores
      switch (type) {
        case 'openInventory':
          console.log('[NUI] Opening inventory with items:', data.inventory?.backpack?.items?.length || 0);
          console.log('[NUI] Item definitions count:', Object.keys(data.itemDefinitions || {}).length);
          setInventory(data.inventory);
          setItemDefinitions(data.itemDefinitions);
          setActiveView('inventory');
          break;

        case 'closeInventory':
          setActiveView(null);
          break;

        case 'updateInventory':
          console.log('[NUI] Updating inventory with items:', data.inventory?.backpack?.items?.length || 0);
          console.log('[NUI] Item definitions count:', Object.keys(data.itemDefinitions || {}).length);
          setInventory(data.inventory);
          if (data.itemDefinitions) {
            setItemDefinitions(data.itemDefinitions);
          }
          break;

        case 'openLoot':
          console.log('[NUI] Opening loot container:', data.container?.id);
          console.log('[NUI] Container items:', data.container?.grid?.items?.length || 0);
          console.log('[NUI] Player inventory items:', data.inventory?.backpack?.items?.length || 0);

          // Set player inventory FIRST (so LootView has data when it mounts)
          setInventory(data.inventory);
          setItemDefinitions(data.itemDefinitions || {});

          // Set loot container data
          setContainer(data.container);
          setLootItemDefs(data.itemDefinitions || {});

          // Open loot view
          setActiveView('loot');
          break;

        case 'closeLoot':
        case 'closeLootContainer':
          console.log('[NUI] Closing loot container');
          closeContainer(); // Reset lootStore
          setActiveView(null); // Close UI
          break;

        case 'updateLootContainer':
          console.log('[NUI] Updating loot container:', data.container);
          if (data.container) {
            setContainer(data.container);
          }
          break;

        case 'openVehicle':
          console.log('[NUI] Opening vehicle trunk:', data);
          setInventory(data.inventory);
          setItemDefinitions(data.itemDefinitions || {});
          setVehicle(data.container);
          setActiveView('vehicle');
          break;

        case 'closeVehicle':
          console.log('[NUI] Closing vehicle trunk');
          closeVehicle();
          setActiveView(null);
          break;

        case 'updateVehicle':
          console.log('[NUI] Updating vehicle trunk:', data);
          if (data) {
            setVehicle(data);
          }
          break;

        case 'openStorage':
          // TODO: Handle storage
          setActiveView('storage');
          break;

        case 'showNotification':
          // TODO: Implement toast notifications
          console.log('[NUI] Notification:', data);
          break;

        default:
          console.warn('[NUI] Unknown message type:', type);
      }
    };

    window.addEventListener('message', handleMessage);

    return () => {
      window.removeEventListener('message', handleMessage);
    };
  }, [setInventory, setItemDefinitions, setActiveView, setContainer, setLootItemDefs, closeContainer]);

  // Render active view
  const renderView = () => {
    switch (activeView) {
      case 'inventory':
        return <InventoryView />;
      case 'loot':
        return <LootView />;
      case 'vehicle':
        return <VehicleView />;
      case 'storage':
        return <StorageView />;
      case 'market':
        return <MarketView />;
      case 'hud':
        return <HUDView />;
      case 'death':
        return <DeathView />;
      default:
        return null;
    }
  };

  // Enable cfx-game-view only when a UI is active (not null)
  const shouldUseCfxGameView = UIConfig.useCfxGameView && activeView !== null;

  return (
    <CfxGameView enabled={shouldUseCfxGameView} className="w-full h-full overflow-hidden relative">
      {/* Dev Tools Sidebar (only in dev mode) */}
      {isDevMode && <DevSidebar />}

      {/* Main Content */}
      <div className="w-full h-full">
        {renderView()}
      </div>
    </CfxGameView>
  );
}

export default App;
