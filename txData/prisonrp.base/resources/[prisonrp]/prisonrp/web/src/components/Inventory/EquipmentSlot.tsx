/**
 * Equipment Slot Component
 * Single slot for equipment items (headgear, weapons, armor, etc.)
 * Supports drag-and-drop with visual feedback (green=valid, red=invalid)
 * Auto-swaps items when dropping on occupied slot
 */

import React from 'react';
import { ItemRenderer } from './ItemRenderer';
import type { InventoryItem, DraggedItem, MousePosition } from '@/types';
import type { ItemDefinition } from '@/types';

export interface EquipmentSlotProps {
  slotName: 'headgear' | 'headset' | 'face_cover' | 'armor' | 'rig' | 'backpack' | 'primary' | 'secondary' | 'holster' | 'sheath' | 'case';
  label: string;
  item: InventoryItem | null;
  itemDefinitions: Record<string, ItemDefinition>;

  // Size (102x102 for square, 265x102 for rectangle)
  width: number;
  height: number;

  // Drag state
  draggedItem: DraggedItem | null;
  mousePosition: MousePosition;

  // Placeholder image
  placeholderImage?: string;

  // Blocked state (for body armor when rig fills it)
  isBlocked?: boolean;
  blockedReason?: string;

  // Callbacks
  onDragStart: (item: InventoryItem, source: DraggedItem['source'], offset: { x: number; y: number }, initialMousePos: { x: number; y: number }) => void;
  onDrop: (slotName: string) => void;
  onContextMenu?: (item: InventoryItem, event: React.MouseEvent) => void;
  onItemHover?: (item: InventoryItem) => void;
  onItemLeave?: () => void;
}

export const EquipmentSlot: React.FC<EquipmentSlotProps> = ({
  slotName,
  label,
  item,
  itemDefinitions,
  width,
  height,
  draggedItem,
  mousePosition,
  placeholderImage,
  isBlocked = false,
  blockedReason,
  onDragStart,
  onDrop,
  onContextMenu,
  onItemHover,
  onItemLeave,
}) => {
  const slotRef = React.useRef<HTMLDivElement>(null);
  const [isHovered, setIsHovered] = React.useState(false);
  const [isValidDrop, setIsValidDrop] = React.useState(false);

  // Check if dragged item can be dropped in this slot
  const canAcceptDrop = React.useCallback((): boolean => {
    if (!draggedItem) return false;
    if (isBlocked) return false; // Blocked slots (armor when rig fills it)

    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return false;

    // Special case: secondary slot accepts both secondary AND primary weapons
    if (slotName === 'secondary') {
      return itemDef.equipSlot === 'secondary' || itemDef.equipSlot === 'primary';
    }

    // Check if item's equipSlot matches this slot
    return itemDef.equipSlot === slotName;
  }, [draggedItem, itemDefinitions, slotName, isBlocked]);

  // Update hover state when mouse moves
  React.useEffect(() => {
    if (!draggedItem || !slotRef.current) {
      setIsHovered(false);
      setIsValidDrop(false);
      return;
    }

    const rect = slotRef.current.getBoundingClientRect();
    const isOver =
      mousePosition.x >= rect.left &&
      mousePosition.x <= rect.right &&
      mousePosition.y >= rect.top &&
      mousePosition.y <= rect.bottom;

    setIsHovered(isOver);
    setIsValidDrop(isOver && canAcceptDrop());
  }, [draggedItem, mousePosition, canAcceptDrop]);

  // Handle drop
  const handleMouseUp = () => {
    if (isValidDrop) {
      onDrop(slotName);
    }
  };

  // Determine border color based on state
  const getBorderColor = (): string => {
    if (isBlocked) return '#555555'; // Gray for blocked
    if (isHovered && draggedItem) {
      return isValidDrop ? '#22c55e' : '#ef4444'; // Green or Red
    }
    return 'rgba(255, 255, 255, 0.15)'; // Default
  };

  // Determine background
  const getBackground = (): string => {
    if (isBlocked) {
      return 'rgba(50, 50, 50, 0.5)'; // Dark gray for blocked
    }
    if (isHovered && draggedItem) {
      return isValidDrop
        ? 'rgba(34, 197, 94, 0.2)' // Green overlay
        : 'rgba(239, 68, 68, 0.2)'; // Red overlay
    }
    return 'radial-gradient(81.97% 50% at 50% 50%, rgba(90, 90, 90, 0.30) 0%, rgba(87, 87, 87, 0.45) 100%), rgba(0, 0, 0, 0.35)';
  };

  const isDragging = draggedItem?.item.id === item?.id;

  return (
    <div className="flex flex-col gap-1">
      {/* Label */}
      <div className="text-xs text-gray-400 uppercase font-semibold">{label}</div>

      {/* Slot */}
      <div
        ref={slotRef}
        className="relative overflow-hidden transition-all duration-150"
        style={{
          width: `${width}px`,
          height: `${height}px`,
          background: getBackground(),
          border: `2px solid ${getBorderColor()}`,
          cursor: isBlocked ? 'not-allowed' : (item ? 'grab' : 'default'),
        }}
        onMouseUp={handleMouseUp}
      >
        {/* Blocked state - show reason if provided */}
        {isBlocked && blockedReason && (
          <div
            className="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 pointer-events-none"
            title={blockedReason}
          >
            <div className="text-xs text-gray-300 text-center px-2">
              {blockedReason}
            </div>
          </div>
        )}

        {/* Placeholder image (when empty and not blocked) */}
        {!item && !isBlocked && placeholderImage && (
          <>
            <div className="absolute inset-0 flex items-center justify-center opacity-30 pointer-events-none">
              <img
                src={placeholderImage}
                alt={label}
                className="object-contain"
                style={{ maxWidth: '80%', maxHeight: '80%' }}
              />
            </div>
            {/* Diagonal stripes overlay for empty slots */}
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 8px, rgba(0, 0, 0, 0.3) 8px, rgba(0, 0, 0, 0.3) 10px)',
              }}
            />
          </>
        )}

        {/* Item */}
        {item && !isDragging && (
          <div
            className="absolute inset-0 pointer-events-auto"
            onMouseDown={(e) => {
              if (e.button !== 0 || isBlocked) return; // Only left click and not blocked
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

                // Start drag after 5px movement
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
            <ItemRenderer
              item={item}
              itemDef={itemDefinitions[item.item_id]}
              cellSize={50} // Dummy value, ItemRenderer will use parent size
              isDragging={false}
              inGrid={false} // FALSE = take 100% of parent size
            />
          </div>
        )}

        {/* Ghost image when dragging */}
        {isDragging && item && (
          <div className="absolute inset-0 pointer-events-none">
            <img
              src={itemDefinitions[item.item_id]?.image}
              alt={itemDefinitions[item.item_id]?.label}
              className="w-full h-full object-contain"
              style={{
                opacity: 0.3,
                filter: 'grayscale(100%) brightness(0.8)',
              }}
            />
          </div>
        )}
      </div>
    </div>
  );
};
