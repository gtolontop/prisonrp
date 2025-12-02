/**
 * Inventory View
 * Uses PlayerInventory component for all inventory display (equipment + storage)
 * Fixed drag flash (endDrag AFTER sendNUIEvent)
 */

import React from 'react';
import { PlayerInventory } from '@/components/Inventory/PlayerInventory';
import { Container } from '@/components/Inventory/Container';
import { ContextMenu } from '@/components/Inventory/ContextMenu';
import { ItemTooltip } from '@/components/Inventory/ItemTooltip';
import { useInventoryStore } from '@/stores/inventoryStore';
import { useLootStore } from '@/stores/lootStore';
import { useKeyboard, useContextMenu, useTooltip, useDragAndDrop } from '@/hooks';
import { closeUI, sendNUIEvent } from '@/utils/nui';
import { findCompatibleItems, findCompatibleEquipmentSlots } from '@/utils/inventory';
import type { InventoryItem } from '@/types';

const InventoryView: React.FC = () => {
  const { inventory, itemDefinitions, devMoveItem } = useInventoryStore();
  const { container } = useLootStore();
  const { draggedItem, mousePosition, startDrag, endDrag, rotateDraggedItem, lockOperation, unlockOperation } = useDragAndDrop();
  const { contextMenu, openContextMenu, closeContextMenu } = useContextMenu();
  const { tooltip, showTooltip, hideTooltip } = useTooltip();

  // Check if we're in dev mode
  const isDev = import.meta.env?.DEV === true;

  // Track compatible items for highlighting (Tarkov-style)
  const [compatibleItemIds, setCompatibleItemIds] = React.useState<string[]>([]);
  const [compatibleSlots, setCompatibleSlots] = React.useState<string[]>([]);

  // Calculate compatible items and slots when hovering an item
  const handleItemHover = React.useCallback((item: any) => {
    showTooltip(item);

    // If dragging, don't recalculate compatibilities (keep the dragged item's compatibilities)
    if (draggedItem) return;

    if (!inventory) return;

    const itemDef = itemDefinitions[item.item_id];
    if (!itemDef) return;

    // Collect all items from all containers
    const allItems = [
      ...inventory.backpack.items,
      ...(inventory.backpack_storage?.items || []),
      ...(inventory.rig?.items || []),
      ...inventory.pockets.map(p => p.item).filter((item): item is InventoryItem => item !== null),
      ...inventory.equipment.map(e => e.item).filter((item): item is InventoryItem => item !== null),
    ];

    // Find compatible items (ammo → weapon, etc.)
    const compatible = findCompatibleItems(itemDef, allItems, itemDefinitions);
    setCompatibleItemIds(compatible);

    // Find compatible equipment slots (pistol → holster, etc.)
    const slots = findCompatibleEquipmentSlots(itemDef);
    setCompatibleSlots(slots);
  }, [inventory, itemDefinitions, showTooltip, draggedItem]);

  const handleItemLeave = React.useCallback(() => {
    hideTooltip();

    // If dragging, keep the compatibilities visible
    if (draggedItem) return;

    setCompatibleItemIds([]);
    setCompatibleSlots([]);
  }, [hideTooltip, draggedItem]);

  // Calculate compatibilities when starting to drag an item
  React.useEffect(() => {
    if (!draggedItem || !inventory) return;

    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return;

    // Collect all items from all containers
    const allItems = [
      ...inventory.backpack.items,
      ...(inventory.backpack_storage?.items || []),
      ...(inventory.rig?.items || []),
      ...inventory.pockets.map(p => p.item).filter((item): item is InventoryItem => item !== null),
      ...inventory.equipment.map(e => e.item).filter((item): item is InventoryItem => item !== null),
    ];

    // Find compatible items (ammo → weapon, etc.)
    const compatible = findCompatibleItems(itemDef, allItems, itemDefinitions);
    setCompatibleItemIds(compatible);

    // Find compatible equipment slots (pistol → holster, etc.)
    const slots = findCompatibleEquipmentSlots(itemDef);
    setCompatibleSlots(slots);

    // Clear when drag ends
    return () => {
      if (!draggedItem) {
        setCompatibleItemIds([]);
        setCompatibleSlots([]);
      }
    };
  }, [draggedItem, inventory, itemDefinitions]);

  // Helper to safely send move item events with operation locking
  const safeMoveItem = React.useCallback((payload: any) => {
    // Try to lock - if already locked, reject silently
    if (!lockOperation()) {
      console.log('[Inventory] Move rejected - operation in progress');
      return;
    }

    // OPTIMISTIC UPDATE: Move item visually immediately (no flash)
    // This happens in BOTH dev and prod mode
    console.log('[Inventory] Optimistic move:', payload);
    devMoveItem(payload);
    endDrag();

    // DEV MODE: Don't send to server, just simulate locally
    if (isDev) {
      console.log('[DEV] Local move only (no server)');
      setTimeout(() => unlockOperation(), 100);
      return;
    }

    // PROD MODE: Send to server for validation
    // If server rejects, it will send 'updateInventory' to rollback
    sendNUIEvent('moveItem', payload);

    // Unlock after a short delay to prevent double-clicks
    setTimeout(() => {
      unlockOperation();
    }, 100);
  }, [lockOperation, unlockOperation, endDrag, isDev, devMoveItem]);

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

  // Global mouseup handler to cancel drag if dropped outside valid slots
  React.useEffect(() => {
    if (!draggedItem) return;

    const handleGlobalMouseUp = (e: MouseEvent) => {
      // Check if the mouseup was on a valid drop target
      // If not captured by any slot's onMouseUp, cancel the drag
      const target = e.target as HTMLElement;

      // If clicked on background or non-droppable area, cancel drag
      if (!target.closest('[data-droppable="true"]')) {
        console.log('[Inventory] Dropped outside valid area - canceling drag');
        endDrag();
      }
    };

    // Use capture phase to catch event before slots
    window.addEventListener('mouseup', handleGlobalMouseUp, { capture: false });

    return () => {
      window.removeEventListener('mouseup', handleGlobalMouseUp, { capture: false });
    };
  }, [draggedItem, endDrag]);

  if (!inventory) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-black/80">
        <p className="text-white">Loading...</p>
      </div>
    );
  }

  return (
    <div
      className="w-full h-screen flex justify-center"
      style={{
        paddingTop: '140px',
        background: `
          radial-gradient(
            ellipse at center,
            rgba(30, 30, 35, 0.92) 0%,
            rgba(20, 20, 25, 0.94) 40%,
            rgba(10, 10, 15, 0.96) 70%,
            rgba(0, 0, 0, 0.98) 100%
          ),
          radial-gradient(
            ellipse 150% 100% at 50% 50%,
            rgba(40, 40, 50, 0.15) 0%,
            transparent 50%
          )
        `,
      }}
    >
      <div className="w-full max-w-[90vw] flex gap-6 overflow-auto" style={{ height: 'fit-content' }}>

        {/* PLAYER INVENTORY (FIGMA DESIGN) */}
        <PlayerInventory
          inventory={inventory}
          itemDefinitions={itemDefinitions}
          draggedItem={draggedItem}
          mousePosition={mousePosition}
          onDragStart={startDrag}
          onDrop={safeMoveItem}
          onContextMenu={openContextMenu}
          onItemHover={handleItemHover}
          onItemLeave={handleItemLeave}
          compatibleItemIds={compatibleItemIds}
          compatibleSlots={compatibleSlots}
          showWeight={true}
          compact={false}
        />

        {/* SECONDARY CONTAINER (Loot, Glovebox, Trunk, Stash, etc.) */}
        {container && (
          <div className="w-[500px] flex-shrink-0">
            <Container
              container={container}
              itemDefinitions={itemDefinitions}
              draggedItem={draggedItem}
              mousePosition={mousePosition}
              onDragStart={startDrag}
              onDrop={safeMoveItem}
              onContextMenu={openContextMenu}
              onItemHover={showTooltip}
              onItemLeave={hideTooltip}
            />
          </div>
        )}


        {/* Dragged item preview */}
        {draggedItem && (() => {
          const itemDef = itemDefinitions[draggedItem.item.item_id];
          if (!itemDef) return null;

          const rotation = draggedItem.item.rotation ?? 0;
          const isRotated = rotation === 1 || rotation === 3;
          const width = isRotated ? itemDef.size.height : itemDef.size.width;
          const height = isRotated ? itemDef.size.width : itemDef.size.height;

          // Use icon if available, fallback to image
          const imageUrl = itemDef.icon || itemDef.image;

          // Don't rotate square items visually (1x1, 2x2, 3x3, etc.)
          const isSquare = itemDef.size.width === itemDef.size.height;
          const visualRotation = isSquare ? 0 : rotation * 90;

          return (
            <div
              className="fixed pointer-events-none z-50"
              style={{
                left: `${mousePosition.x}px`,
                top: `${mousePosition.y}px`,
                width: `${width * 65}px`,
                height: `${height * 65}px`,
                transform: 'translate(-50%, -50%)',
              }}
            >
              <img
                src={imageUrl}
                alt={itemDef.label}
                className="w-full h-full object-contain opacity-70"
                draggable={false}
                style={{
                  transform: `rotate(${visualRotation}deg)`,
                }}
              />
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
              onUse={() => {
                sendNUIEvent('useItem', { item_id: menuItem.id });
                closeContextMenu();
              }}
              onEquip={() => {
                // Server will determine the correct slot
                sendNUIEvent('equipItem', { item_id: menuItem.id, slot: 'primary' as any });
                closeContextMenu();
              }}
              onUnequip={() => {
                sendNUIEvent('unequipItem', { item_id: menuItem.id });
                closeContextMenu();
              }}
              onDrop={() => {
                sendNUIEvent('dropItem', { item_id: menuItem.id });
                closeContextMenu();
              }}
              onSplit={() => {
                sendNUIEvent('splitStackPrompt', { item_id: menuItem.id, quantity: menuItem.quantity });
                closeContextMenu();
              }}
              onUnload={() => {
                sendNUIEvent('unloadMagazine', { item_id: menuItem.id });
                closeContextMenu();
              }}
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

export default InventoryView;
