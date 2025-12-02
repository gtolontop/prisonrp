/**
 * Inventory System Types
 * Grid-based inventory with support for rotation, stacking, and metadata
 */

export type RotationDegrees = 0 | 90 | 180 | 270;
export type RotationIndex = 0 | 1 | 2 | 3; // Maps to degrees: 0=0°, 1=90°, 2=180°, 3=270°

export type SlotType = 'grid' | 'pocket' | 'rig' | 'equipment' | 'container' | 'loot' | 'backpack_storage' | 'case_storage';

export interface GridPosition {
  x: number;
  y: number;
}

export interface ItemMetadata {
  // Durability (weapons, armor, tools)
  durability?: number;
  max_durability?: number;

  // Weapon-specific
  loaded_magazine?: string | null; // Magazine item_id currently loaded
  chambered_round?: string | null; // Ammo type in chamber
  attachments?: {
    optic?: string | null;
    barrel?: string | null;
    grip?: string | null;
    stock?: string | null;
    laser?: string | null;
  };

  // Magazine-specific
  loaded_ammo?: Array<{
    type: string; // Ammo item_id
    count: number;
  }>;

  // Armor-specific
  armor_class?: number; // 1-6
  armor_zones?: string[]; // ["thorax", "stomach"]

  // Medical/Food
  uses_remaining?: number;

  // Custom metadata
  [key: string]: any;
}

export interface InventoryItem {
  // Unique instance ID
  id: string;

  // Item definition ID (from shared/items.lua)
  item_id: string;

  // Quantity (for stackable items)
  quantity: number;

  // Grid position (only for grid slots)
  position?: GridPosition;

  // Rotation (0=0°, 1=90°, 2=180°, 3=270°)
  rotation: RotationIndex;

  // Slot information
  slot_type: SlotType;
  slot_index?: number; // For pockets (0-4), equipment slots, rig slots

  // Metadata
  metadata?: ItemMetadata;
}

export interface InventoryGrid {
  width: number;
  height: number;
  items: InventoryItem[];
}

export interface PocketSlot {
  index: number; // 0-4
  item: InventoryItem | null;
}

// OLD: Individual rig slots (deprecated - rigs are now grids)
// export interface RigSlot {
//   index: number;
//   width: number;
//   height: number;
//   type: 'fixed';
//   item: InventoryItem | null;
// }

export interface RigStorage {
  item_id: string; // ID of the rig item itself
  width: number; // Grid width (like backpack)
  height: number; // Grid height (like backpack)
  items: InventoryItem[]; // Items in rig grid
}

export interface BackpackStorage {
  item_id: string; // ID of the backpack item itself
  width: number;
  height: number;
  items: InventoryItem[];
}

export interface CaseStorage {
  width: number; // 3
  height: number; // 1
  items: InventoryItem[]; // Card + Compass (permanent, locked)
}

export interface EquipmentSlot {
  slot_name: 'headgear' | 'headset' | 'face_cover' | 'armor' | 'rig' | 'backpack' | 'primary' | 'secondary' | 'holster' | 'sheath' | 'case';
  item: InventoryItem | null;
}

export interface PlayerInventory {
  // Main grid (base inventory)
  backpack: InventoryGrid;

  // Dynamic backpack storage (appears when backpack equipped)
  backpack_storage: BackpackStorage | null;

  // Dynamic rig slots (appears when rig equipped)
  rig: RigStorage | null;

  // Secure case storage (permanent, 1x3 grid with card + compass)
  case_storage: CaseStorage | null;

  // Pockets (5 individual 1x1 slots - always present)
  pockets: PocketSlot[];

  // Equipment slots
  equipment: EquipmentSlot[];

  // Total weight
  current_weight: number;
  max_weight: number;
}

/**
 * Mouse position for drag & drop
 */
export interface MousePosition {
  x: number;
  y: number;
}

/**
 * Item being dragged
 */
export interface DraggedItem {
  item: InventoryItem;
  source: {
    type: 'grid' | 'pocket' | 'equipment' | 'rig' | 'loot' | 'container';
    container_id?: string; // For loot containers
    original_position?: GridPosition;
    slot_index?: number; // For pocket slots
    slot_name?: string; // For equipment slots
  };
  offset: {
    x: number;
    y: number;
  };
}

/**
 * Drop validation result
 */
export interface DropValidation {
  valid: boolean;
  reason?: string;
  conflicts?: InventoryItem[]; // Items that would be overlapped
}

/**
 * Container (loot box, corpse, storage)
 */
export interface LootContainer {
  id: string;
  type: 'loot_box' | 'corpse' | 'storage' | 'vehicle' | 'container';
  label: string; // Display name
  name?: string; // Deprecated - use label
  grid: InventoryGrid;
  distance?: number; // Distance from player
}

/**
 * Search progress for containers
 */
export interface SearchProgress {
  container_id: string;
  progress: number; // 0-100
  time_remaining: number; // seconds
}
