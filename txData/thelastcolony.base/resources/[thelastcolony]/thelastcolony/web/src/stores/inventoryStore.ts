import { create } from 'zustand';
import type { PlayerInventory, InventoryItem, ItemDefinition, GridPosition, RotationIndex } from '@/types';

interface InventoryStore {
  // Player inventory data
  inventory: PlayerInventory | null;

  // Item definitions (from shared/items.lua)
  itemDefinitions: Record<string, ItemDefinition>;

  // Actions
  setInventory: (inventory: PlayerInventory) => void;
  setItemDefinitions: (definitions: Record<string, ItemDefinition>) => void;

  // Item operations (these will trigger NUI callbacks to server)
  rotateItem: (itemId: string) => void;
  moveItem: (itemId: string, newPosition: GridPosition, newRotation?: RotationIndex) => void;
  dropItem: (itemId: string) => void;

  // DEV MODE ONLY: Local item movement simulation
  devMoveItem: (payload: any) => void;
}

export const useInventoryStore = create<InventoryStore>((set, get) => ({
  inventory: null,
  itemDefinitions: {},

  setInventory: (inventory) => set({ inventory }),

  setItemDefinitions: (definitions) => set({ itemDefinitions: definitions }),

  rotateItem: (itemId) => {
    const state = get();
    if (!state.inventory) return;

    // Find item in inventory
    let item: InventoryItem | null = null;

    // Check backpack
    item = state.inventory.backpack.items.find((i) => i.id === itemId) || null;

    // Check rig items (rig is now a grid, not individual slots)
    if (!item && state.inventory.rig) {
      item = state.inventory.rig.items.find((i) => i.id === itemId) || null;
    }

    if (!item) return;

    // Toggle between horizontal (0) and vertical (1)
    const isVertical = item.rotation === 1 || item.rotation === 3;
    const newRotation = (isVertical ? 0 : 1) as RotationIndex;

    // Update locally (optimistic)
    set((state) => {
      if (!state.inventory) return state;

      const updateItems = (items: InventoryItem[]) =>
        items.map((i) =>
          i.id === itemId ? { ...i, rotation: newRotation } : i
        );

      return {
        inventory: {
          ...state.inventory,
          backpack: {
            ...state.inventory.backpack,
            items: updateItems(state.inventory.backpack.items),
          },
          rig: state.inventory.rig
            ? {
                ...state.inventory.rig,
                items: updateItems(state.inventory.rig.items), // Rig is now a grid
              }
            : null,
        },
      };
    });

    // Send to server (will be implemented with NUI callbacks)
    console.log('[InventoryStore] Rotate item:', itemId, 'to', newRotation);
  },

  moveItem: (itemId, newPosition, newRotation?) => {
    const state = get();
    if (!state.inventory) return;


    // Update locally (optimistic)
    set((state) => {
      if (!state.inventory) return state;

      const updateItemPosition = (items: InventoryItem[]) =>
        items.map((i) => {
          if (i.id !== itemId) return i;

          const updates: Partial<InventoryItem> = { position: newPosition };
          if (newRotation !== undefined) {
            updates.rotation = newRotation;
          }

          return { ...i, ...updates };
        });

      return {
        inventory: {
          ...state.inventory,
          backpack: {
            ...state.inventory.backpack,
            items: updateItemPosition(state.inventory.backpack.items),
          },
          rig: state.inventory.rig
            ? {
                ...state.inventory.rig,
                items: updateItemPosition(state.inventory.rig.items), // Rig is now a grid
              }
            : null,
        },
      };
    });

    // TODO: Send to server via NUI callback
    // sendNUIEvent('moveItem', { itemId, position: newPosition, rotation: newRotation });
  },

  dropItem: (itemId) => {
    console.log('[InventoryStore] Drop item:', itemId);
    // This will be implemented with NUI callbacks
  },

  // DEV MODE ONLY: Simulate server-side item movement for local testing
  devMoveItem: (payload: any) => {
    const state = get();
    if (!state.inventory) return;

    console.log('[DEV] Moving item:', payload);

    const { item_id, from, to, rotation } = payload;

    // Find the item in the source location
    let itemToMove: InventoryItem | null = null;

    if (from.type === 'grid') {
      itemToMove = state.inventory.backpack_storage?.items.find(i => i.id === item_id) || null;
    } else if (from.type === 'rig') {
      itemToMove = state.inventory.rig?.items.find(i => i.id === item_id) || null;
    } else if (from.type === 'pocket') {
      const pocket = state.inventory.pockets[from.slot_index];
      itemToMove = pocket?.item || null;
    } else if (from.type === 'equipment') {
      const equipSlot = state.inventory.equipment.find(e => e.slot_name === from.slot_name);
      itemToMove = equipSlot?.item || null;
    }

    if (!itemToMove) {
      console.error('[DEV] Item not found:', item_id, from);
      return;
    }

    // Remove from source
    set((state) => {
      if (!state.inventory) return state;

      const newInventory = { ...state.inventory };

      // Remove from source
      if (from.type === 'grid' && newInventory.backpack_storage) {
        newInventory.backpack_storage = {
          ...newInventory.backpack_storage,
          items: newInventory.backpack_storage.items.filter(i => i.id !== item_id)
        };
      } else if (from.type === 'rig' && newInventory.rig) {
        newInventory.rig = {
          ...newInventory.rig,
          items: newInventory.rig.items.filter(i => i.id !== item_id)
        };
      } else if (from.type === 'pocket') {
        newInventory.pockets = newInventory.pockets.map((pocket, idx) =>
          idx === from.slot_index ? { ...pocket, item: null } : pocket
        );
      } else if (from.type === 'equipment') {
        newInventory.equipment = newInventory.equipment.map(slot =>
          slot.slot_name === from.slot_name ? { ...slot, item: null } : slot
        );
      }

      // Add to destination
      const movedItem = { ...itemToMove!, rotation: rotation ?? itemToMove!.rotation };

      if (to.type === 'grid' && newInventory.backpack_storage) {
        movedItem.position = to.position;
        movedItem.slot_type = 'grid';
        newInventory.backpack_storage = {
          ...newInventory.backpack_storage,
          items: [...newInventory.backpack_storage.items, movedItem]
        };
      } else if (to.type === 'rig' && newInventory.rig) {
        movedItem.position = to.position;
        movedItem.slot_type = 'rig';
        newInventory.rig = {
          ...newInventory.rig,
          items: [...newInventory.rig.items, movedItem]
        };
      } else if (to.type === 'pocket') {
        delete movedItem.position;
        movedItem.slot_type = 'pocket';
        movedItem.slot_index = to.slot_index;
        newInventory.pockets = newInventory.pockets.map((pocket, idx) =>
          idx === to.slot_index ? { ...pocket, item: movedItem } : pocket
        );
      } else if (to.type === 'equipment') {
        delete movedItem.position;
        movedItem.slot_type = 'equipment';
        newInventory.equipment = newInventory.equipment.map(slot =>
          slot.slot_name === to.slot_name ? { ...slot, item: movedItem } : slot
        );
      }

      return { inventory: newInventory };
    });
  },
}));

// DEV ONLY: Load mock data on mount
if (typeof window !== 'undefined' && import.meta.env?.DEV === true) {
  import('@/utils/mockData').then(({ mockInventory, mockItemDefinitions }) => {
    useInventoryStore.setState({
      inventory: mockInventory,
      itemDefinitions: mockItemDefinitions,
    });
  });
}
