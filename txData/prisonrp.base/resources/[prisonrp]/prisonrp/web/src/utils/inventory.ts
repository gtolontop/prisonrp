/**
 * Inventory Utility Functions
 * Grid calculations, collision detection, rotation logic
 */

import type {
  InventoryItem,
  InventoryGrid,
  GridPosition,
  RotationIndex,
  DropValidation,
} from '@/types';
import type { ItemDefinition, ItemSize } from '@/types';

/**
 * Get item size based on rotation
 * 0° and 180° = normal size
 * 90° and 270° = width and height swapped
 */
export function getRotatedSize(size: ItemSize, rotation: RotationIndex): ItemSize {
  // Rotation 1 (90°) and 3 (270°) swap width and height
  if (rotation === 1 || rotation === 3) {
    return {
      width: size.height,
      height: size.width,
    };
  }
  return size;
}

/**
 * Get all grid positions occupied by an item
 */
export function getOccupiedCells(
  position: GridPosition,
  size: ItemSize,
  rotation: RotationIndex
): GridPosition[] {
  const rotatedSize = getRotatedSize(size, rotation);
  const cells: GridPosition[] = [];

  for (let x = 0; x < rotatedSize.width; x++) {
    for (let y = 0; y < rotatedSize.height; y++) {
      cells.push({
        x: position.x + x,
        y: position.y + y,
      });
    }
  }

  return cells;
}

/**
 * Check if item fits in grid at given position
 */
export function canItemFitAt(
  position: GridPosition,
  itemSize: ItemSize,
  rotation: RotationIndex,
  gridSize: { width: number; height: number }
): boolean {
  const rotatedSize = getRotatedSize(itemSize, rotation);

  // Check if item goes out of grid bounds
  if (
    position.x < 0 ||
    position.y < 0 ||
    position.x + rotatedSize.width > gridSize.width ||
    position.y + rotatedSize.height > gridSize.height
  ) {
    return false;
  }

  return true;
}

/**
 * Check if two items collide on grid
 */
export function doItemsCollide(
  item1Pos: GridPosition,
  item1Size: ItemSize,
  item1Rotation: RotationIndex,
  item2Pos: GridPosition,
  item2Size: ItemSize,
  item2Rotation: RotationIndex
): boolean {
  const cells1 = getOccupiedCells(item1Pos, item1Size, item1Rotation);
  const cells2 = getOccupiedCells(item2Pos, item2Size, item2Rotation);

  // Check if any cells overlap
  return cells1.some((cell1) =>
    cells2.some((cell2) => cell1.x === cell2.x && cell1.y === cell2.y)
  );
}

/**
 * Find conflicting items at a position
 */
export function findConflictingItems(
  position: GridPosition,
  itemSize: ItemSize,
  rotation: RotationIndex,
  grid: InventoryGrid,
  itemDefinitions: Record<string, ItemDefinition>,
  excludeItemId?: string
): InventoryItem[] {
  const conflicts: InventoryItem[] = [];

  for (const existingItem of grid.items) {
    // Skip the item being moved
    if (existingItem.id === excludeItemId) continue;

    // Skip items without position (shouldn't happen in grid)
    if (!existingItem.position) continue;

    const existingDef = itemDefinitions[existingItem.item_id];
    if (!existingDef) continue;

    const collision = doItemsCollide(
      position,
      itemSize,
      rotation,
      existingItem.position,
      existingDef.size,
      existingItem.rotation
    );

    if (collision) {
      conflicts.push(existingItem);
    }
  }

  return conflicts;
}

/**
 * Validate item drop at position
 */
export function validateDrop(
  position: GridPosition,
  item: InventoryItem,
  itemDef: ItemDefinition,
  grid: InventoryGrid,
  itemDefinitions: Record<string, ItemDefinition>
): DropValidation {
  // Check if item fits in grid bounds
  if (!canItemFitAt(position, itemDef.size, item.rotation, grid)) {
    return {
      valid: false,
      reason: 'Item does not fit in grid',
    };
  }

  // Check for collisions with other items
  const conflicts = findConflictingItems(
    position,
    itemDef.size,
    item.rotation,
    grid,
    itemDefinitions,
    item.id
  );

  if (conflicts.length > 0) {
    return {
      valid: false,
      reason: 'Item overlaps with other items',
      conflicts,
    };
  }

  return {
    valid: true,
  };
}

/**
 * Find first available position for item in grid
 */
export function findAvailablePosition(
  itemSize: ItemSize,
  rotation: RotationIndex,
  grid: InventoryGrid,
  itemDefinitions: Record<string, ItemDefinition>
): GridPosition | null {
  const rotatedSize = getRotatedSize(itemSize, rotation);

  // Scan grid from top-left to bottom-right
  for (let y = 0; y <= grid.height - rotatedSize.height; y++) {
    for (let x = 0; x <= grid.width - rotatedSize.width; x++) {
      const position = { x, y };

      // Check if this position is free
      const conflicts = findConflictingItems(
        position,
        itemSize,
        rotation,
        grid,
        itemDefinitions
      );

      if (conflicts.length === 0) {
        return position;
      }
    }
  }

  return null; // No space available
}

/**
 * Calculate total weight of inventory
 */
export function calculateTotalWeight(
  items: InventoryItem[],
  itemDefinitions: Record<string, ItemDefinition>
): number {
  let total = 0;

  for (const item of items) {
    const def = itemDefinitions[item.item_id];
    if (!def) continue;

    total += def.weight * item.quantity;
  }

  return Math.round(total * 100) / 100; // Round to 2 decimals
}

/**
 * Get next rotation (clockwise)
 */
export function getNextRotation(current: RotationIndex): RotationIndex {
  return ((current + 1) % 4) as RotationIndex;
}

/**
 * Check if item can be stacked with another
 */
export function canStackItems(
  item1: InventoryItem,
  item2: InventoryItem,
  itemDefinitions: Record<string, ItemDefinition>
): boolean {
  // Must be same item type
  if (item1.item_id !== item2.item_id) return false;

  const def = itemDefinitions[item1.item_id];
  if (!def || !def.stackable) return false;

  // Check if adding would exceed max stack
  const totalQuantity = item1.quantity + item2.quantity;
  if (def.max_stack && totalQuantity > def.max_stack) return false;

  // Items with metadata generally can't stack (unique durability, attachments, etc.)
  if (item1.metadata || item2.metadata) return false;

  return true;
}

/**
 * Snap position to grid (for drag & drop)
 */
export function snapToGrid(
  x: number,
  y: number,
  cellSize: number
): GridPosition {
  return {
    x: Math.floor(x / cellSize),
    y: Math.floor(y / cellSize),
  };
}

/**
 * Check if item can be equipped to slot
 */
export function canEquipToSlot(
  _item: InventoryItem,
  itemDef: ItemDefinition,
  slotName: string
): boolean {
  // Use 'type' field from item definition (not 'category')
  const slotTypes: Record<string, string[]> = {
    headgear: ['helmet'],
    headset: ['headset'],
    face_cover: ['face_cover'],
    armor: ['armor'],
    rig: ['rig'],
    backpack: ['backpack'],
    holster: ['pistol', 'weapon'],
    sheath: ['melee', 'weapon'],
    primary: ['primary', 'weapon'],
    secondary: ['secondary', 'weapon'],
  };

  const allowedTypes = slotTypes[slotName];
  if (!allowedTypes) return false;

  // Check if item type matches
  if (!allowedTypes.includes(itemDef.type)) return false;

  // Additional weapon checks (weapon_type must match)
  if (itemDef.type === 'weapon' && itemDef.weapon_type) {
    if (slotName === 'holster' && itemDef.weapon_type !== 'pistol') return false;
    if (slotName === 'sheath' && itemDef.weapon_type !== 'melee') return false;
    if (slotName === 'primary' && (itemDef.weapon_type === 'pistol' || itemDef.weapon_type === 'melee')) return false;
    if (slotName === 'secondary' && (itemDef.weapon_type === 'pistol' || itemDef.weapon_type === 'melee')) return false;
  }

  return true;
}

/**
 * Find all compatible items in inventory for a hovered item
 * (e.g., when hovering ammo, find weapons that accept it)
 */
export function findCompatibleItems(
  hoveredItemDef: ItemDefinition,
  allItems: InventoryItem[],
  itemDefinitions: Record<string, ItemDefinition>
): string[] {
  const compatibleIds: string[] = [];

  // If hovering ammo, find weapons that accept it
  if (hoveredItemDef.type === 'ammo' && hoveredItemDef.ammo_caliber) {
    for (const item of allItems) {
      const itemDef = itemDefinitions[item.item_id];
      if (!itemDef) continue;

      // Check if weapon accepts this caliber
      if (itemDef.type === 'weapon' && itemDef.caliber === hoveredItemDef.ammo_caliber) {
        compatibleIds.push(item.id);
      }

      // Check if magazine accepts this ammo
      if (itemDef.type === 'magazine' && itemDef.magazine_caliber === hoveredItemDef.ammo_caliber) {
        compatibleIds.push(item.id);
      }
    }
  }

  // If hovering weapon, find compatible ammo and magazines
  if (hoveredItemDef.type === 'weapon' && hoveredItemDef.caliber) {
    for (const item of allItems) {
      const itemDef = itemDefinitions[item.item_id];
      if (!itemDef) continue;

      // Check if ammo matches weapon caliber
      if (itemDef.type === 'ammo' && itemDef.ammo_caliber === hoveredItemDef.caliber) {
        compatibleIds.push(item.id);
      }

      // Check if magazine matches weapon
      if (itemDef.type === 'magazine') {
        // Check if magazine is in weapon's compatible list
        if (hoveredItemDef.compatible_magazines?.includes(item.item_id)) {
          compatibleIds.push(item.id);
        }
        // Or check caliber match
        else if (itemDef.magazine_caliber === hoveredItemDef.caliber) {
          compatibleIds.push(item.id);
        }
      }
    }
  }

  // If hovering magazine, find compatible weapons and ammo
  if (hoveredItemDef.type === 'magazine' && hoveredItemDef.magazine_caliber) {
    for (const item of allItems) {
      const itemDef = itemDefinitions[item.item_id];
      if (!itemDef) continue;

      // Check if weapon accepts this magazine
      if (itemDef.type === 'weapon') {
        if (itemDef.compatible_magazines?.includes(hoveredItemDef.name)) {
          compatibleIds.push(item.id);
        }
        // Or check caliber match
        else if (itemDef.caliber === hoveredItemDef.magazine_caliber) {
          compatibleIds.push(item.id);
        }
      }

      // Check if ammo fits in this magazine
      if (itemDef.type === 'ammo' && itemDef.ammo_caliber === hoveredItemDef.magazine_caliber) {
        compatibleIds.push(item.id);
      }
    }
  }

  return compatibleIds;
}

/**
 * Find compatible equipment slots for a hovered item
 * (e.g., when hovering a pistol, return ['holster'])
 */
export function findCompatibleEquipmentSlots(
  hoveredItemDef: ItemDefinition
): string[] {
  const compatibleSlots: string[] = [];

  // If item has an equipSlot, that's the compatible slot
  if (hoveredItemDef.equipSlot) {
    compatibleSlots.push(hoveredItemDef.equipSlot);
  }

  // Special case: primary weapons can also go in secondary
  if (hoveredItemDef.equipSlot === 'primary') {
    compatibleSlots.push('secondary');
  }

  return compatibleSlots;
}
