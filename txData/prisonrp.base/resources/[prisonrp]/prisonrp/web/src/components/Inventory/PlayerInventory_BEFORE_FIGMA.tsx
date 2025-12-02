/**
 * PlayerInventory Component (NEW VERSION)
 * Reusable component showing player's full inventory
 * Uses new EquipmentSlot components instead of grids
 */

import React from 'react';
import { InventoryGrid } from './InventoryGrid';
import { EquipmentSlot } from './EquipmentSlot';
import { EQUIPMENT_PLACEHOLDERS } from '@/utils/equipmentPlaceholders';
import type { PlayerInventory as PlayerInventoryType, InventoryGrid as InventoryGridType, ItemDefinition, InventoryItem, DraggedItem, MousePosition } from '@/types';

interface PlayerInventoryProps {
  inventory: PlayerInventoryType;
  itemDefinitions: Record<string, ItemDefinition>;
  draggedItem: DraggedItem | null;
  mousePosition: MousePosition;

  // Callbacks
  onDragStart: (item: InventoryItem, source: any, gridPosition: { x: number; y: number }, mousePos: { x: number; y: number }) => void;
  onDrop: (payload: any) => void;
  onContextMenu: (item: InventoryItem, e: React.MouseEvent) => void;
  onItemHover: (item: InventoryItem, e?: React.MouseEvent) => void;
  onItemLeave: () => void;

  // Optional customization
  showWeight?: boolean; // Show weight info (default true)
  compact?: boolean; // Compact layout for loot view (default false)
}

export const PlayerInventory: React.FC<PlayerInventoryProps> = ({
  inventory,
  itemDefinitions,
  draggedItem,
  mousePosition,
  onDragStart,
  onDrop,
  onContextMenu,
  onItemHover,
  onItemLeave,
  showWeight = true,
  compact = false,
}) => {
  // Convert equipment array to object for easy access
  const equipment = React.useMemo(() => {
    const result: any = {};
    inventory.equipment?.forEach((slot) => {
      result[slot.slot_name] = slot.item;
    });
    return result;
  }, [inventory.equipment]);

  const cellSize = compact ? 45 : 55;

  // Check if chest rig fills body armor slot
  const rigFillsBodyArmor = React.useMemo(() => {
    if (!equipment.rig) return false;
    const rigDef = itemDefinitions[equipment.rig.item_id];
    return rigDef?.fillsBodyArmor === true;
  }, [equipment.rig, itemDefinitions]);

  // Handle equipment slot drop
  const handleEquipmentDrop = (slotName: string) => {
    if (!draggedItem) return;

    const from: any = {};
    if (draggedItem.source.type === 'grid') {
      from.type = 'grid';
      from.position = draggedItem.item.position;
    } else if (draggedItem.source.type === 'rig') {
      from.type = 'rig';
      from.position = draggedItem.item.position;
    } else if (draggedItem.source.type === 'pocket') {
      from.type = 'pocket';
      from.slot_index = (draggedItem.source as any).slot_index;
    } else if (draggedItem.source.type === 'equipment') {
      from.type = 'equipment';
      from.slot_name = (draggedItem.source as any).slot_name;
    } else if (draggedItem.source.type === 'container') {
      from.type = 'container';
      from.container_id = (draggedItem.source as any).container_id;
      from.position = draggedItem.item.position;
    }

    // Validate item can go in this slot
    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return; // No definition

    // Special case: secondary slot accepts both secondary AND primary weapons
    if (slotName === 'secondary') {
      const validForSecondary = itemDef.equipSlot === 'secondary' || itemDef.equipSlot === 'primary';
      if (!validForSecondary) return; // Invalid drop
    } else {
      // Normal validation: equipSlot must match
      if (itemDef.equipSlot !== slotName) return; // Invalid drop
    }

    console.log(`[PlayerInventory] Dropping to equipment slot ${slotName} with rotation ${draggedItem.item.rotation || 0}`);
    onDrop({
      item_id: draggedItem.item.id,
      from,
      to: { type: 'equipment', slot_name: slotName },
      rotation: draggedItem.item.rotation || 0
    });
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Weight info */}
      {showWeight && (
        <div className="text-center">
          <p className="text-sm text-gray-400">
            Weight: <span className="font-bold text-white">{inventory.current_weight.toFixed(1)}</span> / {inventory.max_weight} kg
          </p>
        </div>
      )}

      {/* === EQUIPMENT SLOTS === */}
      <div className="grid grid-cols-2 gap-3">
        {/* Left column: Square slots */}
        <div className="flex flex-col gap-3">
          <EquipmentSlot
            slotName="headgear"
            label="Headgear"
            item={equipment.headgear || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.headgear}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="headset"
            label="Headset"
            item={equipment.headset || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.headset}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="face_cover"
            label="Face Cover"
            item={equipment.face_cover || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.face_cover}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="armor"
            label="Body Armor"
            item={equipment.armor || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.armor}
            isBlocked={rigFillsBodyArmor}
            blockedReason="Filled by chest rig"
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />
        </div>

        {/* Right column: Square slots */}
        <div className="flex flex-col gap-3">
          <EquipmentSlot
            slotName="holster"
            label="Holster"
            item={equipment.holster || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.holster}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="sheath"
            label="Sheath"
            item={equipment.sheath || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.sheath}
            isBlocked={true}
            blockedReason="Permanent knife"
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="backpack"
            label="Backpack"
            item={equipment.backpack || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.backpack}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />

          <EquipmentSlot
            slotName="rig"
            label="Chest Rig"
            item={equipment.rig || null}
            itemDefinitions={itemDefinitions}
            width={102}
            height={102}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            placeholderImage={EQUIPMENT_PLACEHOLDERS.rig}
            onDragStart={onDragStart}
            onDrop={handleEquipmentDrop}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />
        </div>
      </div>

      {/* Weapon slots (Rectangles) */}
      <div className="flex flex-col gap-3">
        <EquipmentSlot
          slotName="primary"
          label="Primary Weapon"
          item={equipment.primary || null}
          itemDefinitions={itemDefinitions}
          width={265}
          height={102}
          draggedItem={draggedItem}
          mousePosition={mousePosition}
          placeholderImage={EQUIPMENT_PLACEHOLDERS.primary}
          onDragStart={onDragStart}
          onDrop={handleEquipmentDrop}
          onContextMenu={onContextMenu}
          onItemHover={onItemHover}
          onItemLeave={onItemLeave}
        />

        <EquipmentSlot
          slotName="secondary"
          label="Secondary Weapon"
          item={equipment.secondary || null}
          itemDefinitions={itemDefinitions}
          width={265}
          height={102}
          draggedItem={draggedItem}
          mousePosition={mousePosition}
          placeholderImage={EQUIPMENT_PLACEHOLDERS.secondary}
          onDragStart={onDragStart}
          onDrop={handleEquipmentDrop}
          onContextMenu={onContextMenu}
          onItemHover={onItemHover}
          onItemLeave={onItemLeave}
        />
      </div>

      {/* === SECURE CASE SLOT === */}
      <EquipmentSlot
        slotName="case"
        label="Secure Case"
        item={equipment.case || null}
        itemDefinitions={itemDefinitions}
        width={102}
        height={102}
        draggedItem={draggedItem}
        mousePosition={mousePosition}
        placeholderImage={EQUIPMENT_PLACEHOLDERS.case}
        isBlocked={true}
        blockedReason="Permanent secure case"
        onDragStart={onDragStart}
        onDrop={handleEquipmentDrop}
        onContextMenu={onContextMenu}
        onItemHover={onItemHover}
        onItemLeave={onItemLeave}
      />

      {/* === POCKETS === */}
      <div>
        <div className="text-xs text-gray-400 uppercase font-semibold mb-2">Pockets</div>
        <div className="flex gap-1">
          {inventory.pockets.map((pocket, index) => {
            // Convert pocket to grid format
            const pocketGrid: InventoryGridType = {
              width: 1,
              height: 1,
              items: pocket.item ? [{ ...pocket.item, position: { x: 0, y: 0 } }] : []
            };

            return (
              <InventoryGrid
                key={index}
                grid={pocketGrid}
                itemDefinitions={itemDefinitions}
                draggedItem={draggedItem}
                mousePosition={mousePosition}
                cellSize={cellSize}
                customValidation={(draggedItem) => {
                  // Pockets accept ONLY 1x1 items
                  const itemDef = itemDefinitions[draggedItem.item.item_id];
                  if (!itemDef) return false;
                  return itemDef.size.width === 1 && itemDef.size.height === 1;
                }}
                onDragStart={(item, _source, offset, initialMousePos) => {
                  onDragStart(item, { type: 'pocket', slot_index: index }, offset, initialMousePos);
                }}
                onDrop={(_position) => {
                  if (!draggedItem) return;

                  const from: any = {};
                  if (draggedItem.source.type === 'grid') {
                    from.type = 'grid';
                    from.position = draggedItem.item.position;
                  } else if (draggedItem.source.type === 'rig') {
                    from.type = 'rig';
                    from.position = draggedItem.item.position;
                  } else if (draggedItem.source.type === 'pocket') {
                    from.type = 'pocket';
                    from.slot_index = (draggedItem.source as any).slot_index;
                  } else if (draggedItem.source.type === 'equipment') {
                    from.type = 'equipment';
                    from.slot_name = (draggedItem.source as any).slot_name;
                  } else if (draggedItem.source.type === 'container') {
                    from.type = 'container';
                    from.container_id = (draggedItem.source as any).container_id;
                    from.position = draggedItem.item.position;
                  }

                  // Validate: only 1x1 items in pockets
                  const itemDef = itemDefinitions[draggedItem.item.item_id];
                  if (!itemDef || itemDef.size.width !== 1 || itemDef.size.height !== 1) {
                    return; // Invalid drop
                  }

                  onDrop({
                    item_id: draggedItem.item.id,
                    from,
                    to: { type: 'pocket', slot_index: index },
                    rotation: 0
                  });
                }}
                onContextMenu={onContextMenu}
                onItemHover={onItemHover}
                onItemLeave={onItemLeave}
              />
            );
          })}
        </div>
      </div>

      {/* === CHEST RIG STORAGE (if equipped) === */}
      {inventory.rig && (
        <div className="flex-1">
          <div className="text-xs text-gray-400 uppercase font-semibold mb-2">
            Rig Storage ({inventory.rig.width}×{inventory.rig.height})
          </div>
          <InventoryGrid
            grid={inventory.rig}
            itemDefinitions={itemDefinitions}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            cellSize={cellSize}
            onDragStart={onDragStart}
            onDrop={(position) => {
              if (!draggedItem) return;

              const from: any = {};
              if (draggedItem.source.type === 'grid') {
                from.type = 'grid';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'rig') {
                from.type = 'rig';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'pocket') {
                from.type = 'pocket';
                from.slot_index = (draggedItem.source as any).slot_index;
              } else if (draggedItem.source.type === 'equipment') {
                from.type = 'equipment';
                from.slot_name = (draggedItem.source as any).slot_name;
              } else if (draggedItem.source.type === 'container') {
                from.type = 'container';
                from.container_id = (draggedItem.source as any).container_id;
                from.position = draggedItem.item.position;
              }

              onDrop({
                item_id: draggedItem.item.id,
                from,
                to: { type: 'rig', position },
                rotation: draggedItem.item.rotation || 0
              });
            }}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />
        </div>
      )}

      {/* === SECURE CASE STORAGE (always visible, permanent items with lock) === */}
      {inventory.case_storage && (
        <div className="flex-1">
          <div className="text-xs text-gray-400 uppercase font-semibold mb-2 flex items-center gap-2">
            Secure Case Storage (3×1)
          </div>
          <InventoryGrid
            grid={inventory.case_storage}
            itemDefinitions={itemDefinitions}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            cellSize={cellSize}
            // Prevent ANY drag/drop on case storage (all items locked)
            customValidation={() => false}
            onDragStart={() => {
              // Allow viewing tooltip but prevent dragging
              return; // Do nothing
            }}
            onDrop={() => {
              // Prevent any drop
              return;
            }}
            onContextMenu={(item, e) => {
              // Show limited context menu (no drop/unequip options)
              onContextMenu(item, e);
            }}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />
        </div>
      )}

      {/* === BACKPACK STORAGE (if equipped) === */}
      {inventory.backpack_storage && (
        <div className="flex-1">
          <div className="text-xs text-gray-400 uppercase font-semibold mb-2">
            Backpack Storage ({inventory.backpack.width}×{inventory.backpack.height})
          </div>
          <InventoryGrid
            grid={inventory.backpack}
            itemDefinitions={itemDefinitions}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            cellSize={cellSize}
            onDragStart={onDragStart}
            onDrop={(position) => {
              if (!draggedItem) return;

              const from: any = {};
              if (draggedItem.source.type === 'grid') {
                from.type = 'grid';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'rig') {
                from.type = 'rig';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'pocket') {
                from.type = 'pocket';
                from.slot_index = (draggedItem.source as any).slot_index;
              } else if (draggedItem.source.type === 'equipment') {
                from.type = 'equipment';
                from.slot_name = (draggedItem.source as any).slot_name;
              } else if (draggedItem.source.type === 'container') {
                from.type = 'container';
                from.container_id = (draggedItem.source as any).container_id;
                from.position = draggedItem.item.position;
              }

              onDrop({
                item_id: draggedItem.item.id,
                from,
                to: { type: 'grid', position },
                rotation: draggedItem.item.rotation || 0
              });
            }}
            onContextMenu={onContextMenu}
            onItemHover={onItemHover}
            onItemLeave={onItemLeave}
          />
        </div>
      )}
    </div>
  );
};
