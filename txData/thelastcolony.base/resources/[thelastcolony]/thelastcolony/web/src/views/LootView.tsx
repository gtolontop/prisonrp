/**
 * Loot View
 * LEFT: Equipment slots (Headgear, Armor, Weapons, etc.)
 * CENTER: Pockets, ChestRig grid, Backpack grid
 * RIGHT: Container for loot
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

const LootView: React.FC = () => {
  const { inventory, itemDefinitions } = useInventoryStore();
  const { container } = useLootStore();
  const { draggedItem, mousePosition, startDrag, endDrag, rotateDraggedItem, lockOperation, unlockOperation } = useDragAndDrop();
  const { contextMenu, openContextMenu, closeContextMenu } = useContextMenu();
  const { tooltip, showTooltip, hideTooltip } = useTooltip();

  // Helper to safely send move item events with operation locking
  const safeMoveItem = React.useCallback((payload: any) => {
    // Try to lock - if already locked, reject silently
    if (!lockOperation()) {
      console.log('[Loot] Move rejected - operation in progress');
      return;
    }

    // DEBUG: Log payload being sent
    console.log('[LootView] Sending moveItem:', JSON.stringify(payload, null, 2));

    // Send event
    sendNUIEvent('moveItem', payload);

    // End drag immediately (no flash - item will appear at new position when server updates)
    endDrag();

    // Unlock after a short delay to prevent double-clicks
    setTimeout(() => {
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

  // Global mouseup handler to cancel drag if dropped outside valid slots
  React.useEffect(() => {
    if (!draggedItem) return;

    const handleGlobalMouseUp = (e: MouseEvent) => {
      // Check if the mouseup was on a valid drop target
      // If not captured by any slot's onMouseUp, cancel the drag
      const target = e.target as HTMLElement;

      // If clicked on background or non-droppable area, cancel drag
      if (!target.closest('[data-droppable="true"]')) {
        console.log('[Loot] Dropped outside valid area - canceling drag');
        endDrag();
      }
    };

    // Use capture phase to catch event before slots
    window.addEventListener('mouseup', handleGlobalMouseUp, { capture: false });

    return () => {
      window.removeEventListener('mouseup', handleGlobalMouseUp, { capture: false });
    };
  }, [draggedItem, endDrag]);

  if (!inventory || !container) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-black/80">
        <p className="text-white">Loading...</p>
      </div>
    );
  }

  return (
    <div className="w-full h-screen p-4 flex items-center justify-center">
      <div className="w-full h-full max-w-[95vw] max-h-[90vh] flex gap-6 overflow-auto">

        {/* CENTER: PLAYER INVENTORY */}
        <PlayerInventory
          inventory={inventory}
          itemDefinitions={itemDefinitions}
          draggedItem={draggedItem}
          mousePosition={mousePosition}
          onDragStart={startDrag}
          onDrop={safeMoveItem}
          onContextMenu={openContextMenu}
          onItemHover={showTooltip}
          onItemLeave={hideTooltip}
          showWeight={true}
          compact={false}
        />

        {/* RIGHT: CONTAINER */}
        <div className="w-[500px]">
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
                width: `${width * 55}px`,
                height: `${height * 55}px`,
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

export default LootView;
