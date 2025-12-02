/**
 * PlayerInventory Component
 * Reusable component showing player's full inventory
 * Used in both InventoryView and LootView (left side)
 */

import React from 'react';
import { InventoryGrid } from './InventoryGrid';
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

  return (
    <div className="flex flex-col gap-3">
      {/* Weight info */}
      {showWeight && (
        <div className="text-center">
          <p className="text-sm text-gray-400">
            Weight: <span className="font-bold text-white">{inventory.current_weight.toFixed(1)}</span> / {inventory.max_weight} kg
          </p>
        </div>
      )}

      {/* Pockets - Using InventoryGrid (5x 1x1 grids) */}
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

      {/* ChestRig - Using InventoryGrid (2x2) */}
      <div className="flex gap-3 items-start">
        <div className="w-[110px]">
          <div className="text-xs text-gray-400 uppercase font-semibold mb-2">Chest Rig</div>
            {(() => {
              // Convert equipment slot to grid format
              const rigGrid: InventoryGridType = {
                width: 2,
                height: 2,
                items: equipment.rig ? [{ ...equipment.rig, position: { x: 0, y: 0 } }] : []
              };

              return (
                <InventoryGrid
                  grid={rigGrid}
                  itemDefinitions={itemDefinitions}
                  draggedItem={draggedItem}
                  mousePosition={mousePosition}
                  cellSize={cellSize}
                  customValidation={(draggedItem) => {
                    // Rig slot accepts ONLY rig items
                    const itemDef = itemDefinitions[draggedItem.item.item_id];
                    if (!itemDef) return false;
                    // Check if slot is already occupied
                    if (equipment.rig) return false;
                    return ['rig', 'chest_rig'].includes(itemDef.type);
                  }}
                  onDragStart={(item, _source, offset, initialMousePos) => {
                    onDragStart(item, { type: 'equipment', slot_name: 'rig' }, offset, initialMousePos);
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
                      from.position = draggedItem.item.position;
                    }

                    // Validate: only rig items
                    const itemDef = itemDefinitions[draggedItem.item.item_id];
                    if (!itemDef || !['rig', 'chest_rig'].includes(itemDef.type)) {
                      return; // Invalid drop
                    }

                    // Check slot not occupied
                    if (equipment.rig) return;

                    onDrop({
                      item_id: draggedItem.item.id,
                      from,
                      to: { type: 'equipment', slot_name: 'rig' },
                      rotation: draggedItem.item.rotation || 0
                    });
                  }}
                  onContextMenu={onContextMenu}
                  onItemHover={onItemHover}
                  onItemLeave={onItemLeave}
                />
              );
            })()}
        </div>

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

      {/* Backpack - Using InventoryGrid (2x2) */}
      <div className="flex gap-3 items-start">
        <div className="w-[110px]">
          <div className="text-xs text-gray-400 uppercase font-semibold mb-2">Backpack</div>
            {(() => {
              // Convert equipment slot to grid format
              const backpackGrid: InventoryGridType = {
                width: 2,
                height: 2,
                items: equipment.backpack ? [{ ...equipment.backpack, position: { x: 0, y: 0 } }] : []
              };

              return (
                <InventoryGrid
                  grid={backpackGrid}
                  itemDefinitions={itemDefinitions}
                  draggedItem={draggedItem}
                  mousePosition={mousePosition}
                  cellSize={cellSize}
                  customValidation={(draggedItem) => {
                    // Backpack slot accepts ONLY backpack items
                    const itemDef = itemDefinitions[draggedItem.item.item_id];
                    if (!itemDef) return false;
                    // Check if slot is already occupied
                    if (equipment.backpack) return false;
                    return itemDef.type === 'backpack';
                  }}
                  onDragStart={(item, _source, offset, initialMousePos) => {
                    onDragStart(item, { type: 'equipment', slot_name: 'backpack' }, offset, initialMousePos);
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
                      from.position = draggedItem.item.position;
                    }

                    // Validate: only backpack items
                    const itemDef = itemDefinitions[draggedItem.item.item_id];
                    if (!itemDef || itemDef.type !== 'backpack') {
                      return; // Invalid drop
                    }

                    // Check slot not occupied
                    if (equipment.backpack) return;

                    onDrop({
                      item_id: draggedItem.item.id,
                      from,
                      to: { type: 'equipment', slot_name: 'backpack' },
                      rotation: draggedItem.item.rotation || 0
                    });
                  }}
                  onContextMenu={onContextMenu}
                  onItemHover={onItemHover}
                  onItemLeave={onItemLeave}
                />
              );
            })()}
        </div>

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
      </div>
    </div>
  );
};
