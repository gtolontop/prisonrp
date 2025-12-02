/**
 * Inventory Grid Component
 * Main grid container for inventory items
 * Professional drag & drop with smooth animations
 */

import React, { useState, useCallback, useRef } from 'react';
import { ItemRenderer } from './ItemRenderer';
import type { InventoryGrid as InventoryGridType, InventoryItem, GridPosition, DraggedItem } from '@/types';
import type { ItemDefinition } from '@/types';
import { validateDrop, snapToGrid, getRotatedSize } from '@/utils/inventory';
import { getSlotStyle, getSlotClasses } from '@/styles/slotStyles';

interface InventoryGridProps {
  grid: InventoryGridType;
  itemDefinitions: Record<string, ItemDefinition>;
  cellSize?: number;
  draggedItem: DraggedItem | null;
  mousePosition: { x: number; y: number };
  onDragStart: (item: InventoryItem, source: DraggedItem['source'], offset: { x: number; y: number }, initialMousePos: { x: number; y: number }) => void;
  onDrop: (position: GridPosition) => void;
  onContextMenu?: (item: InventoryItem, event: React.MouseEvent) => void;
  onItemHover?: (item: InventoryItem) => void;
  onItemLeave?: () => void;
  customValidation?: (draggedItem: DraggedItem, position: GridPosition) => boolean; // Custom validation for special slots
  compatibleItemIds?: string[]; // Items to highlight (Tarkov-style compatibility)
}

// Create empty transparent image to prevent browser's default drag preview
const emptyImage = new Image();
emptyImage.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

export const InventoryGrid: React.FC<InventoryGridProps> = ({
  grid,
  itemDefinitions,
  cellSize = 50,
  draggedItem,
  mousePosition,
  onDragStart,
  onDrop,
  onContextMenu,
  onItemHover,
  onItemLeave,
  customValidation,
  compatibleItemIds = [],
}) => {
  const [hoverPosition, setHoverPosition] = useState<GridPosition | null>(null);
  const gridRef = useRef<HTMLDivElement>(null);

  // Check if cell is occupied by an item
  const isCellOccupied = useCallback(
    (position: GridPosition): boolean => {
      return grid.items.some((item) => {
        if (!item.position) return false;
        const def = itemDefinitions[item.item_id];
        if (!def) return false;

        // Check if this cell is within item bounds
        const rotatedWidth = item.rotation === 1 || item.rotation === 3 ? def.size.height : def.size.width;
        const rotatedHeight = item.rotation === 1 || item.rotation === 3 ? def.size.width : def.size.height;

        return (
          position.x >= item.position.x &&
          position.x < item.position.x + rotatedWidth &&
          position.y >= item.position.y &&
          position.y < item.position.y + rotatedHeight
        );
      });
    },
    [grid.items, itemDefinitions]
  );

  // Validate if dragged item can be dropped at hover position
  const isValidDrop = useCallback(
    (position: GridPosition): boolean => {
      if (!draggedItem) return false;

      const itemDef = itemDefinitions[draggedItem.item.item_id];
      if (!itemDef) return false;

      // First check standard grid validation (fits in grid, no overlap, etc.)
      const validation = validateDrop(
        position,
        draggedItem.item,
        itemDef,
        grid,
        itemDefinitions
      );

      if (!validation.valid) return false;

      // Then check custom validation if provided (for pockets, equipment slots, etc.)
      if (customValidation) {
        return customValidation(draggedItem, position);
      }

      return true;
    },
    [draggedItem, grid, itemDefinitions, customValidation]
  );

  // Update hover position based on global mouse position
  React.useEffect(() => {
    if (!draggedItem || !gridRef.current) {
      setHoverPosition(null);
      return;
    }

    const rect = gridRef.current.getBoundingClientRect();
    const itemDef = itemDefinitions[draggedItem.item.item_id];
    if (!itemDef) return;

    // Calculate item size based on rotation
    const rotation = draggedItem.item.rotation || 0;
    const isRotated = rotation === 1 || rotation === 3;
    const itemWidth = isRotated ? itemDef.size.height : itemDef.size.width;
    const itemHeight = isRotated ? itemDef.size.width : itemDef.size.height;

    // CORRECT METHOD: Snap cursor first, then center item around it
    // 1. Find which cell the cursor is over
    const mouseGridX = mousePosition.x - rect.left;
    const mouseGridY = mousePosition.y - rect.top;
    const cursorCell = snapToGrid(mouseGridX, mouseGridY, cellSize);

    // 2. Center the item around the cursor cell (in grid units, not pixels)
    const centerOffsetCells = {
      x: Math.floor(itemWidth / 2),
      y: Math.floor(itemHeight / 2),
    };

    const snapped = {
      x: cursorCell.x - centerOffsetCells.x,
      y: cursorCell.y - centerOffsetCells.y,
    };

    // Check if mouse is over the grid (STRICT check with margin)
    const MARGIN = 5;
    const isMouseOverGrid =
      mousePosition.x >= rect.left + MARGIN &&
      mousePosition.x <= rect.right - MARGIN &&
      mousePosition.y >= rect.top + MARGIN &&
      mousePosition.y <= rect.bottom - MARGIN;

    if (isMouseOverGrid) {
      // Validate that item fits in grid bounds
      if (
        snapped.x >= 0 &&
        snapped.y >= 0 &&
        snapped.x + itemWidth <= grid.width &&
        snapped.y + itemHeight <= grid.height
      ) {
        setHoverPosition(snapped);
      } else {
        setHoverPosition(null);
      }
    } else {
      setHoverPosition(null);
    }
  }, [draggedItem, mousePosition, cellSize, itemDefinitions]);

  const handleMouseUp = () => {
    if (!draggedItem) return;

    // If we have a valid hover position and it's valid, drop there immediately
    if (hoverPosition && isValidDrop(hoverPosition)) {
      onDrop(hoverPosition);
    }
    // If invalid or no hover position, the item will stay at original position
    // by not calling onDrop - the parent will handle cleanup

    setHoverPosition(null);
  };

  // Check if a cell is part of the hover area
  const isCellInHoverArea = useCallback(
    (position: GridPosition): boolean => {
      if (!hoverPosition || !draggedItem) return false;

      const itemDef = itemDefinitions[draggedItem.item.item_id];
      if (!itemDef) return false;

      const rotatedSize = getRotatedSize(itemDef.size, draggedItem.item.rotation);

      return (
        position.x >= hoverPosition.x &&
        position.x < hoverPosition.x + rotatedSize.width &&
        position.y >= hoverPosition.y &&
        position.y < hoverPosition.y + rotatedSize.height
      );
    },
    [hoverPosition, draggedItem, itemDefinitions]
  );

  // Check if a cell belongs to the dragged item
  const isCellPartOfDraggedItem = useCallback(
    (position: GridPosition): boolean => {
      if (!draggedItem) return false;

      // Find which item occupies this cell
      const occupyingItem = grid.items.find((item) => {
        if (!item.position) return false;
        const def = itemDefinitions[item.item_id];
        if (!def) return false;

        const rotatedWidth = (item.rotation === 1 || item.rotation === 3) ? def.size.height : def.size.width;
        const rotatedHeight = (item.rotation === 1 || item.rotation === 3) ? def.size.width : def.size.height;

        return (
          position.x >= item.position.x &&
          position.x < item.position.x + rotatedWidth &&
          position.y >= item.position.y &&
          position.y < item.position.y + rotatedHeight
        );
      });

      // Return true if this cell is occupied by the dragged item
      return occupyingItem?.id === draggedItem.item.id;
    },
    [draggedItem, grid.items, itemDefinitions]
  );

  // Render all grid cells with smooth hover effects
  const renderCells = () => {
    const cells = [];
    const isDropValid = hoverPosition ? isValidDrop(hoverPosition) : false;

    for (let y = 0; y < grid.height; y++) {
      for (let x = 0; x < grid.width; x++) {
        const position = { x, y };
        const isInHoverArea = isCellInHoverArea(position);
        const cellOccupied = isCellOccupied(position);
        const isPartOfDraggedItem = isCellPartOfDraggedItem(position);

        // Use shared slot styles (same as Slot component)
        const cellClasses = getSlotClasses({
          isHovered: isInHoverArea,
          isValidDrop: isDropValid,
          isDragging: draggedItem !== null,
        });

        const cellStyle = getSlotStyle({
          isHovered: isInHoverArea,
          isValidDrop: isDropValid,
          cellSize,
        });

        // Add gray background for occupied cells (not part of dragged item)
        const additionalClasses = [
          !isInHoverArea && cellOccupied && !isPartOfDraggedItem ? 'bg-gray-800/60' : '',
        ].filter(Boolean).join(' ');

        cells.push(
          <div
            key={`${x}-${y}`}
            className={[cellClasses, additionalClasses].filter(Boolean).join(' ')}
            style={cellStyle}
          />
        );
      }
    }
    return cells;
  };

  // Render all items
  const renderItems = () => {
    return grid.items.map((item) => {
      const def = itemDefinitions[item.item_id];
      if (!def || !item.position) return null;

      const isDragging = draggedItem?.item.id === item.id;
      const isCompatible = compatibleItemIds.includes(item.id);

      // Show a ghost image at the original position when dragging
      if (isDragging) {
        const rotation = item.rotation || 0;
        const isRotated = rotation === 1 || rotation === 3;
        const width = isRotated ? def.size.height : def.size.width;
        const height = isRotated ? def.size.width : def.size.height;

        return (
          <div
            key={`${item.id}-ghost`}
            className="absolute pointer-events-none"
            style={{
              left: `${item.position.x * cellSize}px`,
              top: `${item.position.y * cellSize}px`,
              width: `${width * cellSize}px`,
              height: `${height * cellSize}px`,
            }}
          >
            <img
              src={def.image}
              alt={def.label}
              className="w-full h-full object-contain"
              style={{
                opacity: 0.3,
                filter: 'grayscale(100%) brightness(0.8)',
              }}
            />
          </div>
        );
      }

      return (
        <div
          key={item.id}
          className="absolute pointer-events-auto"
          style={{
            left: `${item.position.x * cellSize}px`,
            top: `${item.position.y * cellSize}px`,
            cursor: 'grab',
            // Fade in/out transition for compatibility highlight
            transition: 'outline 0.2s ease-in-out, outline-color 0.2s ease-in-out',
            // Compatibility highlight (simple green border like valid drop zones)
            outline: isCompatible ? '2px solid rgba(34, 197, 94, 0.8)' : '2px solid transparent',
            outlineOffset: '-2px', // Inside the element
          }}
          onMouseDown={(e) => {
            if (e.button !== 0) return; // Only left click
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
              // Calculate distance moved
              const dx = moveEvent.clientX - startX;
              const dy = moveEvent.clientY - startY;
              const distance = Math.sqrt(dx * dx + dy * dy);

              // Only start drag if moved more than 5px (prevents accidental drags)
              if (!dragStarted && distance > 5) {
                dragStarted = true;

                console.log('[Grid] Start drag after movement:', {
                  item: item.item_id,
                  distance,
                });

                onDragStart(
                  item,
                  { type: 'grid', original_position: item.position },
                  offset,
                  { x: moveEvent.clientX, y: moveEvent.clientY }
                );

                // Clean up listeners
                window.removeEventListener('mousemove', handleMouseMove);
                window.removeEventListener('mouseup', handleMouseUp);
              }
            };

            const handleMouseUp = () => {
              // Clean up if drag never started (just a click)
              if (!dragStarted) {
                window.removeEventListener('mousemove', handleMouseMove);
                window.removeEventListener('mouseup', handleMouseUp);
              }
            };

            window.addEventListener('mousemove', handleMouseMove);
            window.addEventListener('mouseup', handleMouseUp);
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
            itemDef={def}
            cellSize={cellSize}
            isDragging={false}
            inGrid={true}
          />
        </div>
      );
    });
  };

  const gridStyle: React.CSSProperties = {
    display: 'grid',
    gridTemplateColumns: `repeat(${grid.width}, ${cellSize}px)`,
    gridTemplateRows: `repeat(${grid.height}, ${cellSize}px)`,
    width: `${grid.width * cellSize}px`,
    height: `${grid.height * cellSize}px`,
    position: 'relative',
    boxSizing: 'content-box',
  };

  return (
    <div
      ref={gridRef}
      className="relative"
      style={{
        ...gridStyle,
        background: '#060809',
        border: '1.5px solid rgba(255, 255, 255, 0.15)',
      }}
      onMouseUp={handleMouseUp}
    >
      {/* Grid cells (background) */}
      {renderCells()}

      {/* Items (foreground) */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="relative w-full h-full">
          {renderItems()}
        </div>
      </div>
    </div>
  );
};
