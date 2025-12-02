/**
 * Vehicle Inventory View
 * Player inventory (left) + Vehicle trunk (right)
 * Same architecture as LootView
 */

import React from 'react';
import { Slot } from '@/components/Inventory/Slot';
import { InventoryGrid } from '@/components/Inventory/InventoryGrid';
import { ContextMenu } from '@/components/Inventory/ContextMenu';
import { ItemTooltip } from '@/components/Inventory/ItemTooltip';
import { useInventoryStore } from '@/stores/inventoryStore';
import { useVehicleStore } from '@/stores/vehicleStore';
import { useKeyboard, useContextMenu, useTooltip, useDragAndDrop } from '@/hooks';
import { closeUI, sendNUIEvent } from '@/utils/nui';

const VehicleView: React.FC = () => {
  const { inventory, itemDefinitions } = useInventoryStore();
  const { vehicle } = useVehicleStore();
  const { draggedItem, mousePosition, startDrag, endDrag, rotateDraggedItem, lockOperation, unlockOperation } = useDragAndDrop();
  const { contextMenu, openContextMenu, closeContextMenu } = useContextMenu();
  const { tooltip, showTooltip, hideTooltip } = useTooltip();

  // Helper to safely send move item events with operation locking
  const safeMoveItem = React.useCallback((payload: any) => {
    if (!lockOperation()) {
      console.log('[Vehicle] Move rejected - operation in progress');
      return;
    }
    sendNUIEvent('moveItem', payload);
    setTimeout(() => {
      endDrag();
      unlockOperation();
    }, 100);
  }, [lockOperation, unlockOperation, endDrag]);

  // Keyboard shortcuts
  useKeyboard({
    onRotate: () => {
      if (draggedItem) {
        const itemDef = itemDefinitions[draggedItem.item.item_id];
        if (itemDef) rotateDraggedItem(itemDef);
      }
    },
    onEscape: () => {
      if (contextMenu) {
        closeContextMenu();
      } else if (draggedItem) {
        endDrag();
      } else {
        closeUI();
      }
    },
  });

  if (!inventory || !vehicle) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-black/80">
        <p className="text-white">Loading...</p>
      </div>
    );
  }


  return (
    <div className="w-full h-full bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 p-4 overflow-auto">
      <div className="max-w-[1800px] mx-auto flex gap-4">

        {/* LEFT: Player Inventory */}
        <div className="flex flex-col gap-4 w-[500px]">

          <div className="text-center">
            <h2 className="text-xl font-bold text-white">Your Inventory</h2>
            <p className="text-xs text-gray-400">
              Weight: {inventory.current_weight.toFixed(1)} / {inventory.max_weight} kg
            </p>
          </div>

          {/* Pockets */}
          <div>
            <div className="text-xs text-gray-400 uppercase font-semibold mb-2">Pockets</div>
            <div className="flex">
              {inventory.pockets.map((pocket, index) => {
                const item = pocket.item;
                const itemDef = item ? itemDefinitions[item.item_id] : undefined;
                const canDrop = !!(draggedItem && !item);

                return (
                  <Slot
                    key={index}
                    item={item}
                    itemDef={itemDef}
                    width={1}
                    height={1}
                    cellSize={50}
                    canDrop={canDrop}
                    onDragStart={(e: React.MouseEvent) => {
                      if (!item) return;
                      startDrag(
                        item,
                        { type: 'pocket', slot_index: index },
                        { x: 0, y: 0 },
                        { x: e.clientX, y: e.clientY }
                      );
                    }}
                    onDrop={() => {
                      if (!draggedItem) return;

                      // Build 'from' data
                      const from: any = {};
                      if (draggedItem.source.type === 'grid') {
                        from.type = 'grid';
                        from.position = draggedItem.item.position;
                      } else if (draggedItem.source.type === 'rig') {
                        from.type = 'rig';
                        from.position = draggedItem.item.position;
                      } else if (draggedItem.source.type === 'loot') {
                        from.type = 'loot';
                        from.container_id = (draggedItem.source as any).container_id;
                        from.position = draggedItem.item.position;
                      } else if (draggedItem.source.type === 'pocket') {
                        from.type = 'pocket';
                        from.slot_index = (draggedItem.source as any).slot_index;
                      } else if (draggedItem.source.type === 'equipment') {
                        from.type = 'equipment';
                        from.slot_name = (draggedItem.source as any).slot_name;
                      }

                      // Send to server
                      safeMoveItem( {
                        item_id: draggedItem.item.id,
                        from,
                        to: { type: 'pocket', slot_index: index },
                        rotation: 0
                      });

                      // CRITICAL: endDrag AFTER sendNUIEvent (prevents flash)
                    }}
                    onContextMenu={(e: React.MouseEvent) => item && openContextMenu(item, e)}
                    onMouseEnter={() => item && showTooltip(item)}
                    onMouseLeave={hideTooltip}
                  />
                );
              })}
            </div>
          </div>

          {/* Backpack Grid */}
          <div>
            <div className="text-xs text-gray-400 uppercase font-semibold mb-2">
              Backpack ({inventory.backpack.width}×{inventory.backpack.height})
            </div>
            <InventoryGrid
              grid={inventory.backpack}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              cellSize={50}
              onDragStart={startDrag}
              onDrop={(position) => {
                if (!draggedItem) return;

                // Build 'from' data
                const from: any = {};
                if (draggedItem.source.type === 'grid') {
                  from.type = 'grid';
                  from.position = draggedItem.item.position;
                } else if (draggedItem.source.type === 'rig') {
                  from.type = 'rig';
                  from.position = draggedItem.item.position;
                } else if (draggedItem.source.type === 'loot') {
                  from.type = 'loot';
                  from.container_id = (draggedItem.source as any).container_id;
                  from.position = draggedItem.item.position;
                } else if (draggedItem.source.type === 'pocket') {
                  from.type = 'pocket';
                  from.slot_index = (draggedItem.source as any).slot_index;
                } else if (draggedItem.source.type === 'equipment') {
                  from.type = 'equipment';
                  from.slot_name = (draggedItem.source as any).slot_name;
                }

                // Send to server
                safeMoveItem( {
                  item_id: draggedItem.item.id,
                  from,
                  to: { type: 'grid', position },
                  rotation: draggedItem.item.rotation || 0
                });

                // CRITICAL: endDrag AFTER sendNUIEvent (prevents flash)
              }}
              onContextMenu={openContextMenu}
              onItemHover={showTooltip}
              onItemLeave={hideTooltip}
            />
          </div>

          {/* Rig Grid (if equipped) */}
          {inventory.rig && (
            <div>
              <div className="text-xs text-gray-400 uppercase font-semibold mb-2">
                🎽 Tactical Rig ({inventory.rig.width}×{inventory.rig.height})
              </div>
              <InventoryGrid
                grid={inventory.rig}
                itemDefinitions={itemDefinitions}
                draggedItem={draggedItem}
                mousePosition={mousePosition}
                cellSize={50}
                onDragStart={startDrag}
                onDrop={(position) => {
                  if (!draggedItem) return;

                  // Build 'from' data
                  const from: any = {};
                  if (draggedItem.source.type === 'grid') {
                    from.type = 'grid';
                    from.position = draggedItem.item.position;
                  } else if (draggedItem.source.type === 'rig') {
                    from.type = 'rig';
                    from.position = draggedItem.item.position;
                  } else if (draggedItem.source.type === 'loot') {
                    from.type = 'loot';
                    from.container_id = (draggedItem.source as any).container_id;
                    from.position = draggedItem.item.position;
                  } else if (draggedItem.source.type === 'pocket') {
                    from.type = 'pocket';
                    from.slot_index = (draggedItem.source as any).slot_index;
                  } else if (draggedItem.source.type === 'equipment') {
                    from.type = 'equipment';
                    from.slot_name = (draggedItem.source as any).slot_name;
                  }

                  // Send to server
                  safeMoveItem( {
                    item_id: draggedItem.item.id,
                    from,
                    to: { type: 'rig', position },
                    rotation: draggedItem.item.rotation || 0
                  });

                  // CRITICAL: endDrag AFTER sendNUIEvent (prevents flash)
                }}
                onContextMenu={openContextMenu}
                onItemHover={showTooltip}
                onItemLeave={hideTooltip}
              />
            </div>
          )}
        </div>

        {/* RIGHT: Vehicle Trunk */}
        <div className="flex-1">
          <div className="text-center mb-4">
            <h2 className="text-2xl font-bold text-white">
              🚗 Vehicle Trunk
            </h2>
            <p className="text-sm text-gray-400">
              {vehicle.grid.items.length} items · {vehicle.grid.width}×{vehicle.grid.height}
            </p>
          </div>

          <InventoryGrid
            grid={vehicle.grid}
            itemDefinitions={itemDefinitions}
            draggedItem={draggedItem}
            mousePosition={mousePosition}
            cellSize={50}
            onDragStart={startDrag}
            onDrop={(position) => {
              if (!draggedItem) return;

              // Build 'from' data
              const from: any = {};
              if (draggedItem.source.type === 'grid') {
                from.type = 'grid';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'rig') {
                from.type = 'rig';
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'loot') {
                from.type = 'loot';
                from.container_id = (draggedItem.source as any).container_id;
                from.position = draggedItem.item.position;
              } else if (draggedItem.source.type === 'pocket') {
                from.type = 'pocket';
                from.slot_index = (draggedItem.source as any).slot_index;
              } else if (draggedItem.source.type === 'equipment') {
                from.type = 'equipment';
                from.slot_name = (draggedItem.source as any).slot_name;
              }

              // Send to server
              safeMoveItem( {
                item_id: draggedItem.item.id,
                from,
                to: {
                  type: 'loot',
                  position,
                  container_id: vehicle.id,
                },
                rotation: draggedItem.item.rotation || 0
              });

              // CRITICAL: endDrag AFTER sendNUIEvent (prevents flash)
            }}
            onContextMenu={openContextMenu}
            onItemHover={showTooltip}
            onItemLeave={hideTooltip}
          />
        </div>

        {/* Dragged item preview */}
        {draggedItem && (() => {
          const itemDef = itemDefinitions[draggedItem.item.item_id];
          if (!itemDef) return null;

          const rotation = draggedItem.item.rotation || 0;
          const isRotated = rotation === 1 || rotation === 3;
          const width = isRotated ? itemDef.size.height : itemDef.size.width;
          const height = isRotated ? itemDef.size.width : itemDef.size.height;

          return (
            <div
              className="fixed pointer-events-none z-50"
              style={{
                left: `${mousePosition.x}px`,
                top: `${mousePosition.y}px`,
                width: `${width * 50}px`,
                height: `${height * 50}px`,
                transform: 'translate(-50%, -50%)',
              }}
            >
              {itemDef.icon && (
                <img
                  src={`/items/${itemDef.icon}`}
                  alt={itemDef.name}
                  className="w-full h-full object-contain opacity-70"
                  draggable={false}
                />
              )}
              {/* Item Name (top left) */}
              <div className="absolute top-1 left-1 bg-black/70 px-1">
                <div className="text-xs text-white font-semibold">
                  {itemDef.label}
                </div>
                {/* Weapon Caliber (below name for weapons) */}
                {itemDef.type === 'weapon' && itemDef.caliber && (
                  <div className="text-[10px] text-gray-300 font-normal leading-tight">
                    {itemDef.caliber}
                  </div>
                )}
              </div>
            </div>
          );
        })()}

        {/* Context menu */}
        {contextMenu && contextMenu.item && (() => {
          const menuItem = contextMenu.item;
          const menuItemDef = itemDefinitions[menuItem.item_id];
          if (!menuItemDef) return null;

          return (
            <ContextMenu
              item={menuItem}
              itemDef={menuItemDef}
              position={contextMenu.position}
              onClose={closeContextMenu}
            />
          );
        })()}

        {/* Tooltip */}
        {tooltip && (
          <ItemTooltip
            item={tooltip.item}
            itemDef={itemDefinitions[tooltip.item.item_id]}
            position={tooltip.position}
          />
        )}
      </div>
    </div>
  );
};

export default VehicleView;
