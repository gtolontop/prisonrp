/**
 * PlayerInventory Component (NEW DESIGN - Figma Layout)
 * Left Section: Navbar + Equipment (2x2) + Weapons (2x2)
 * Right Section: Pockets + Rig/Backpack/Case (slot + grid) with custom scrollbar
 *
 * IMPORTANT: Labels are INSIDE slots, collés (no gap)
 */

import React from 'react';
import { InventoryGrid } from './InventoryGrid';
import type {
  PlayerInventory as PlayerInventoryType,
  InventoryGrid as InventoryGridType,
  ItemDefinition,
  InventoryItem,
  DraggedItem,
  MousePosition
} from '@/types';

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

  // Compatibility highlighting (Tarkov-style)
  compatibleItemIds?: string[];
  compatibleSlots?: string[]; // Equipment slots to highlight

  showWeight?: boolean;
  compact?: boolean;
}

// Figma colors (all in RGBA format for consistency)
const COLORS = {
  labelBorder: 'rgba(255, 255, 255, 0.15)', // Bordure blanche transparente
  equipmentSlot: 'rgba(0, 0, 0, 0.48)', // Noir
  grid: 'rgba(255, 255, 255, 0.15)', // Blanc transparent
  scrollbarThumb: 'rgba(0, 238, 255, 1)', // Cyan clair
  scrollbarTrack: 'rgba(0, 130, 140, 1)', // Cyan foncé
  navbar: 'rgba(217, 217, 217, 1)', // Gris
};

// Inventory Label Component - Reusable label for all slots
// Takes width in pixels - use 102 for square slots, 265 for weapon slots, etc.
const InventoryLabel: React.FC<{
  children: React.ReactNode;
  width: number; // Width in pixels
}> = ({ children, width }) => {
  return (
    <div
      className="text-xs font-semibold flex items-center px-0.5"
      style={{
        border: `1px solid ${COLORS.labelBorder}`,
        color: 'white',
        width: `${width}px`,
        height: '17px',
        boxSizing: 'border-box',
        fontSize: '13px',
      }}
    >
      {children}
    </div>
  );
};

// Equipment Slot Component (simplified inline - NO LABEL)
const EquipmentSlotSimple: React.FC<{
  slotName: string;
  width: number;
  height: number;
  item: InventoryItem | null;
  itemDefinitions: Record<string, ItemDefinition>;
  draggedItem: DraggedItem | null;
  mousePosition: MousePosition;
  isBlocked?: boolean;
  isCompatible?: boolean; // Highlight slot if compatible with hovered item
  compatibleItemIds?: string[]; // IDs of items that are compatible with hovered item (for highlighting equipped items)
  onDragStart: any;
  onDrop: any;
  onContextMenu?: any;
  onItemHover?: any;
  onItemLeave?: any;
}> = ({
  slotName,
  width,
  height,
  item,
  itemDefinitions,
  draggedItem,
  mousePosition,
  isBlocked = false,
  isCompatible = false,
  compatibleItemIds = [],
  onDragStart,
  onDrop,
  onContextMenu,
  onItemHover,
  onItemLeave,
}) => {
  const slotRef = React.useRef<HTMLDivElement>(null);
  const [isHovered, setIsHovered] = React.useState(false);

  // Check drop validity
  React.useEffect(() => {
    if (!draggedItem || !slotRef.current) {
      setIsHovered(false);
      return;
    }

    const rect = slotRef.current.getBoundingClientRect();
    const isOver =
      mousePosition.x >= rect.left &&
      mousePosition.x <= rect.right &&
      mousePosition.y >= rect.top &&
      mousePosition.y <= rect.bottom;

    setIsHovered(isOver);
  }, [draggedItem, mousePosition]);

  const handleMouseUp = () => {
    if (!isHovered || !draggedItem || isBlocked) return;

    // Validate that item can be equipped in this slot
    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return;

    // Special case: secondary slot accepts both primary and secondary weapons
    if (slotName === 'secondary') {
      const isValidWeapon = itemDef.equipSlot === 'secondary' || itemDef.equipSlot === 'primary';
      if (!isValidWeapon) return; // Invalid drop - don't call onDrop
    } else {
      // For all other slots, must match exactly
      if (itemDef.equipSlot !== slotName) return; // Invalid drop - don't call onDrop
    }

    // Valid drop - call onDrop
    onDrop(slotName);
  };

  const isDragging = draggedItem?.item.id === item?.id;

  // Check if current hover is valid for visual feedback
  const isValidHover = React.useMemo(() => {
    if (!isHovered || !draggedItem || isBlocked) return false;

    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return false;

    if (slotName === 'secondary') {
      return itemDef.equipSlot === 'secondary' || itemDef.equipSlot === 'primary';
    }
    return itemDef.equipSlot === slotName;
  }, [isHovered, draggedItem, isBlocked, slotName, itemDefinitions]);

  // Check if equipped item is compatible with hovered item (e.g., weapon compatible with ammo)
  const isEquippedItemCompatible = React.useMemo(() => {
    if (!item) return false;
    return compatibleItemIds.includes(item.id);
  }, [item, compatibleItemIds]);

  return (
    <div
      ref={slotRef}
      style={{
        width: `${width}px`,
        height: `${height}px`,
        backgroundColor: COLORS.equipmentSlot,
        cursor: isBlocked ? 'not-allowed' : (item ? 'grab' : 'default'),
        position: 'relative',
        // Visual feedback: green if valid hover, red if invalid hover
        border: isHovered && draggedItem
          ? isValidHover
            ? '2px solid rgba(0, 255, 0, 0.6)' // Green border = valid drop
            : '2px solid rgba(255, 0, 0, 0.6)' // Red border = invalid drop
          : 'none',
        boxSizing: 'border-box',
        // Compatibility highlight (green outline when hovering compatible item)
        transition: 'outline 0.2s ease-in-out',
        outline: (isCompatible || isEquippedItemCompatible) ? '2px solid rgba(34, 197, 94, 0.8)' : '2px solid transparent',
        outlineOffset: '-2px',
      }}
      onMouseUp={handleMouseUp}
    >
        {/* Item rendering */}
        {item && !isDragging && (
          <div
            className="absolute inset-0"
            onMouseDown={(e) => {
              if (e.button !== 0 || isBlocked) return;
              e.stopPropagation();

              const startX = e.clientX;
              const startY = e.clientY;
              const itemRect = e.currentTarget.getBoundingClientRect();
              const offset = {
                x: e.clientX - itemRect.left,
                y: e.clientY - itemRect.top,
              };

              let dragStarted = false;

              const handleMouseMove = (moveEvent: MouseEvent) => {
                const dx = moveEvent.clientX - startX;
                const dy = moveEvent.clientY - startY;
                const distance = Math.sqrt(dx * dx + dy * dy);

                if (!dragStarted && distance > 5) {
                  dragStarted = true;
                  onDragStart(
                    item,
                    { type: 'equipment', slot_name: slotName },
                    offset,
                    { x: moveEvent.clientX, y: moveEvent.clientY }
                  );
                  window.removeEventListener('mousemove', handleMouseMove);
                  window.removeEventListener('mouseup', handleMouseUpDrag);
                }
              };

              const handleMouseUpDrag = () => {
                if (!dragStarted) {
                  window.removeEventListener('mousemove', handleMouseMove);
                  window.removeEventListener('mouseup', handleMouseUpDrag);
                }
              };

              window.addEventListener('mousemove', handleMouseMove);
              window.addEventListener('mouseup', handleMouseUpDrag);
            }}
            onContextMenu={(e) => {
              e.stopPropagation();
              if (onContextMenu && !isDragging) {
                e.preventDefault();
                onContextMenu(item, e);
              }
            }}
            onMouseEnter={() => {
              if (onItemHover && !isDragging) {
                onItemHover(item);
              }
            }}
            onMouseLeave={() => {
              if (onItemLeave && !isDragging) {
                onItemLeave();
              }
            }}
          >
            <img
              src={itemDefinitions[item.item_id]?.image}
              alt={itemDefinitions[item.item_id]?.label}
              className="w-full h-full object-contain"
              draggable={false}
            />
            {/* Item Name (top left) */}
            <div className="absolute top-0.5 left-0.5 px-0 pointer-events-none">
              <div className="text-xs text-white font-semibold">
                {itemDefinitions[item.item_id]?.label}
              </div>
              {/* Weapon Caliber (below name for weapons) */}
              {itemDefinitions[item.item_id]?.type === 'weapon' && itemDefinitions[item.item_id]?.caliber && (
                <div className="text-[10px] text-gray-300 font-normal leading-tight">
                  {itemDefinitions[item.item_id]?.caliber}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Blocked state - visual only, no text */}
      </div>
  );
};

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
  compatibleItemIds = [],
  compatibleSlots = [],
}) => {
  // Convert equipment array to object
  const equipment = React.useMemo(() => {
    const result: any = {};
    inventory.equipment?.forEach((slot: any) => {
      result[slot.slot_name] = slot.item;
    });
    return result;
  }, [inventory.equipment]);

  const cellSize = 65;

  // Compute which items to display in rig and armor slots (handling rig+armor combo)
  const { displayedRigItem, displayedArmorItem } = React.useMemo(() => {
    const rigItem = equipment.rig;
    const armorItem = equipment.armor;

    // Check if rig fills body armor
    const rigDef = rigItem ? itemDefinitions[rigItem.item_id] : null;
    const rigFillsArmor = rigDef?.fillsBodyArmor === true;

    // Check if armor is actually a rig (when equipped in armor slot)
    const armorDef = armorItem ? itemDefinitions[armorItem.item_id] : null;
    const armorIsRig = armorDef?.equipSlot === 'rig' && armorDef?.fillsBodyArmor === true;

    return {
      // Rig slot: show rig, or if armor is actually a rig+armor combo, show that
      displayedRigItem: rigItem || (armorIsRig ? armorItem : null),
      // Armor slot: show armor, or if rig fills armor, show the rig
      displayedArmorItem: armorItem || (rigFillsArmor ? rigItem : null),
    };
  }, [equipment.rig, equipment.armor, itemDefinitions]);

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

    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return;

    if (slotName === 'secondary') {
      const validForSecondary = itemDef.equipSlot === 'secondary' || itemDef.equipSlot === 'primary';
      if (!validForSecondary) return;
    } else if (slotName === 'armor') {
      // Armor slot accepts armor items OR rigs that fill body armor
      const validForArmor = itemDef.equipSlot === 'armor' || (itemDef.equipSlot === 'rig' && itemDef.fillsBodyArmor === true);
      if (!validForArmor) return;
    } else if (slotName === 'rig') {
      // Rig slot only accepts rig items
      if (itemDef.equipSlot !== 'rig') return;
    } else {
      // Other slots must match exactly
      if (itemDef.equipSlot !== slotName) return;
    }

    onDrop({
      item_id: draggedItem.item.id,
      from,
      to: { type: 'equipment', slot_name: slotName },
      rotation: draggedItem.item.rotation || 0
    });
  };

  return (
    <div className="flex" style={{ gap: '54px' }}>
      {/* ===== SECTION GAUCHE ===== */}
      <div className="flex flex-col">
        {/* Navbar */}
        <div className="flex items-center" style={{ height: '30px', marginBottom: '19px' }}>
          <div className="flex items-center justify-center text-xs font-bold" style={{ backgroundColor: COLORS.navbar, width: '23px', height: '23px', marginTop: '3px' }}>
            E
          </div>
          <div className="flex items-center justify-center text-xs font-semibold" style={{ backgroundColor: COLORS.navbar, width: '194px', height: '30px', marginLeft: '10px' }}>
            Equipment
          </div>
          <div className="flex items-center justify-center text-xs font-semibold" style={{ backgroundColor: COLORS.navbar, width: '194px', height: '30px', marginLeft: '7px' }}>
            Health
          </div>
          <div className="flex items-center justify-center text-xs font-bold" style={{ backgroundColor: COLORS.navbar, width: '23px', height: '23px', marginLeft: '10px', marginTop: '3px' }}>
            A
          </div>
        </div>

        {/* Equipment Row 1: Headgear + Headset */}
        <div className="flex justify-between" style={{ width: '461px', marginBottom: '8px' }}>
          <div>
            <InventoryLabel width={102}>Headgear</InventoryLabel>
            <EquipmentSlotSimple
              slotName="headgear"
              width={102}
              height={102}
              item={equipment.headgear || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('headgear') && !equipment.headgear}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
          <div>
            <InventoryLabel width={102}>Headset</InventoryLabel>
            <EquipmentSlotSimple
              slotName="headset"
              width={102}
              height={102}
              item={equipment.headset || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('headset') && !equipment.headset}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
        </div>

        {/* Equipment Row 2: FaceCover + BodyArmor */}
        <div className="flex justify-between" style={{ width: '461px', marginBottom: '132px' }}>
          <div>
            <InventoryLabel width={102}>Face Cover</InventoryLabel>
            <EquipmentSlotSimple
              slotName="face_cover"
              width={102}
              height={102}
              item={equipment.face_cover || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('face_cover') && !equipment.face_cover}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
          <div>
            <InventoryLabel width={102}>Body Armor</InventoryLabel>
            <EquipmentSlotSimple
              slotName="armor"
              width={102}
              height={102}
              item={displayedArmorItem}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('armor') && !displayedArmorItem}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
        </div>

        {/* Weapons Row 1: Primary + Holster */}
        <div className="flex justify-between" style={{ width: '461px', marginBottom: '8px' }}>
          <div>
            <InventoryLabel width={265}>Primary Weapon</InventoryLabel>
            <EquipmentSlotSimple
              slotName="primary"
              width={265}
              height={102}
              item={equipment.primary || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('primary') && !equipment.primary}
              compatibleItemIds={compatibleItemIds}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
          <div>
            <InventoryLabel width={102}>Holster</InventoryLabel>
            <EquipmentSlotSimple
              slotName="holster"
              width={102}
              height={102}
              item={equipment.holster || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('holster') && !equipment.holster}
              compatibleItemIds={compatibleItemIds}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
        </div>

        {/* Weapons Row 2: Secondary + Sheath */}
        <div className="flex justify-between" style={{ width: '461px' }}>
          <div>
            <InventoryLabel width={265}>Secondary Weapon</InventoryLabel>
            <EquipmentSlotSimple
              slotName="secondary"
              width={265}
              height={102}
              item={equipment.secondary || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isCompatible={compatibleSlots.includes('secondary') && !equipment.secondary}
              compatibleItemIds={compatibleItemIds}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
          <div>
            <InventoryLabel width={102}>Sheath</InventoryLabel>
            <EquipmentSlotSimple
              slotName="sheath"
              width={102}
              height={102}
              item={equipment.sheath || null}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              isBlocked={true}
              isCompatible={compatibleSlots.includes('sheath') && !equipment.sheath}
              onDragStart={onDragStart}
              onDrop={handleEquipmentDrop}
              onContextMenu={onContextMenu}
              onItemHover={onItemHover}
              onItemLeave={onItemLeave}
            />
          </div>
        </div>
      </div>

      {/* ===== SECTION DROITE (with scrollbar) ===== */}
      <div className="flex relative">
        <div
          className="overflow-y-auto custom-scrollbar"
          style={{
            maxHeight: '752px',
            paddingRight: '10px',
          }}
        >
          <style>{`
            .custom-scrollbar::-webkit-scrollbar {
              width: 8px;
            }
            .custom-scrollbar::-webkit-scrollbar-track {
              background: rgba(255, 255, 255, 0.08);
              border-radius: 4px;
            }
            .custom-scrollbar::-webkit-scrollbar-thumb {
              background: rgba(255, 255, 255, 0.25);
              border-radius: 4px;
            }
            .custom-scrollbar::-webkit-scrollbar-thumb:hover {
              background: rgba(255, 255, 255, 0.4);
            }
            /* Remove scrollbar arrows */
            .custom-scrollbar::-webkit-scrollbar-button {
              display: none;
            }
            /* Firefox */
            .custom-scrollbar {
              scrollbar-width: thin;
              scrollbar-color: rgba(255, 255, 255, 0.25) rgba(255, 255, 255, 0.08);
            }
          `}</style>

          {/* Pockets */}
          <div style={{ marginBottom: '9px' }}>
            <InventoryLabel width={102}>Pockets</InventoryLabel>
            <div className="flex" style={{ gap: '6px' }}>
              {inventory.pockets.slice(0, 4).map((pocket: any, index: number) => {
                const pocketGrid: InventoryGridType = {
                  width: 1,
                  height: 1,
                  items: pocket.item ? [{ ...pocket.item, position: { x: 0, y: 0 } }] : []
                };

                return (
                  <div
                    key={index}
                    style={{ width: '65px', height: '65px'}}
                  >
                    <InventoryGrid
                      grid={pocketGrid}
                      itemDefinitions={itemDefinitions}
                      draggedItem={draggedItem}
                      mousePosition={mousePosition}
                      cellSize={65}
                      compatibleItemIds={compatibleItemIds}
                      customValidation={(draggedItem) => {
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

                        const itemDef = itemDefinitions[draggedItem.item.item_id];
                        if (!itemDef || itemDef.size.width !== 1 || itemDef.size.height !== 1) {
                          return;
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
                  </div>
                );
              })}
            </div>
          </div>

          {/* Rig */}
          <div style={{ marginBottom: '8px' }}>
            <InventoryLabel width={102}>Rig</InventoryLabel>
            <div className="flex">
              <EquipmentSlotSimple
                slotName="rig"
                width={102}
                height={102}
                item={displayedRigItem}
                itemDefinitions={itemDefinitions}
                draggedItem={draggedItem}
                mousePosition={mousePosition}
                isCompatible={compatibleSlots.includes('rig') && !displayedRigItem}
                onDragStart={onDragStart}
                onDrop={handleEquipmentDrop}
                onContextMenu={onContextMenu}
                onItemHover={onItemHover}
                onItemLeave={onItemLeave}
              />
              {inventory.rig && (
                <div>
                  <InventoryGrid
                    grid={inventory.rig}
                    itemDefinitions={itemDefinitions}
                    draggedItem={draggedItem}
                    mousePosition={mousePosition}
                    cellSize={cellSize}
                    compatibleItemIds={compatibleItemIds}
                    onDragStart={(item, _source, offset, initialMousePos) => {
                      onDragStart(item, { type: 'rig' }, offset, initialMousePos);
                    }}
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
            </div>
          </div>

          {/* Backpack */}
          <div style={{ marginBottom: '17px' }}>
            <InventoryLabel width={102}>Backpack</InventoryLabel>
            <div className="flex">
              <EquipmentSlotSimple
                slotName="backpack"
                width={102}
                height={102}
                item={equipment.backpack || null}
                itemDefinitions={itemDefinitions}
                draggedItem={draggedItem}
                mousePosition={mousePosition}
                isCompatible={compatibleSlots.includes('backpack') && !equipment.backpack}
                onDragStart={onDragStart}
                onDrop={handleEquipmentDrop}
                onContextMenu={onContextMenu}
                onItemHover={onItemHover}
                onItemLeave={onItemLeave}
              />
              {inventory.backpack_storage && (
                <div>
                  <InventoryGrid
                    grid={inventory.backpack_storage}
                    itemDefinitions={itemDefinitions}
                    draggedItem={draggedItem}
                    mousePosition={mousePosition}
                    cellSize={cellSize}
                    compatibleItemIds={compatibleItemIds}
                    onDragStart={(item, _source, offset, initialMousePos) => {
                      onDragStart(item, { type: 'grid' }, offset, initialMousePos);
                    }}
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
          </div>

          {/* Case */}
          <div>
            <InventoryLabel width={102}>Secure Case</InventoryLabel>
            <div className="flex">
              <EquipmentSlotSimple
                slotName="case"
                width={102}
                height={102}
                item={equipment.case || null}
                itemDefinitions={itemDefinitions}
                draggedItem={draggedItem}
                mousePosition={mousePosition}
                isBlocked={true}
                isCompatible={compatibleSlots.includes('case') && !equipment.case}
                onDragStart={onDragStart}
                onDrop={handleEquipmentDrop}
                onContextMenu={onContextMenu}
                onItemHover={onItemHover}
                onItemLeave={onItemLeave}
              />
              {inventory.case_storage && (
                <div>
                  <InventoryGrid
                    grid={inventory.case_storage}
                    itemDefinitions={itemDefinitions}
                    draggedItem={draggedItem}
                    mousePosition={mousePosition}
                    cellSize={cellSize}
                    compatibleItemIds={compatibleItemIds}
                    customValidation={() => false}
                    onDragStart={() => {}}
                    onDrop={() => {}}
                    onContextMenu={onContextMenu}
                    onItemHover={onItemHover}
                    onItemLeave={onItemLeave}
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
