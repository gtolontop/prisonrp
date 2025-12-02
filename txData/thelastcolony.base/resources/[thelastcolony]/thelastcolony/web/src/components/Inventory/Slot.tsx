/**
 * Slot Component
 * Used for ALL inventory slots (backpack, rig, loot, pockets, equipment)
 */

import React from "react";
import type { InventoryItem, ItemDefinition } from "@/types";
import { getSlotStyle, getSlotClasses } from "@/styles/slotStyles";
import { ItemRenderer } from "./ItemRenderer";

interface SlotProps {
  // Item in slot (null = empty)
  item: InventoryItem | null;
  itemDef?: ItemDefinition;

  // Slot dimensions in grid cells
  width: number;
  height: number;

  // Grid position (for grid-based slots like backpack/rig)
  gridPosition?: { x: number; y: number };

  // Drop zone state - SAME system as InventoryGrid
  canDrop?: boolean; // Is this slot valid for current drag?
  isDragging?: boolean; // Is there an active drag?
  mousePosition?: { x: number; y: number }; // Global mouse position during drag
  draggedItem?: { item: { id: string } } | null; // Currently dragged item

  // Event handlers
  onDragStart?: (e: React.MouseEvent) => void;
  onDrop?: () => void; // Changed to simple callback (no event needed)
  onContextMenu?: (e: React.MouseEvent) => void;
  onMouseEnter?: (e: React.MouseEvent) => void;
  onMouseLeave?: () => void;

  // Optional visual customization
  label?: string; // e.g., "Pocket 1", "Primary Weapon"
  cellSize?: number; // px size of each grid cell (default 50)
  className?: string;
}

export const Slot: React.FC<SlotProps> = ({
  item,
  itemDef,
  width,
  height,
  gridPosition,
  canDrop = false,
  isDragging = false,
  mousePosition,
  draggedItem,
  onDragStart,
  onDrop,
  onContextMenu,
  onMouseEnter,
  onMouseLeave,
  label,
  cellSize = 50,
  className = "",
}) => {
  const isEmpty = !item;
  const slotRef = React.useRef<HTMLDivElement>(null);

  // Check if THIS item is being dragged (SAME as InventoryGrid)
  const isThisItemBeingDragged = draggedItem?.item.id === item?.id;

  // SAME system as InventoryGrid: check if mouse is over this slot using global mousePosition
  const isHovered = React.useMemo(() => {
    if (!isDragging || !mousePosition || !slotRef.current) return false;

    const rect = slotRef.current.getBoundingClientRect();
    return (
      mousePosition.x >= rect.left &&
      mousePosition.x <= rect.right &&
      mousePosition.y >= rect.top &&
      mousePosition.y <= rect.bottom
    );
  }, [isDragging, mousePosition]);

  // Show validation feedback when hovering during drag
  const showValidationFeedback = isHovered && isDragging && canDrop !== undefined;

  // Container style (positioning and dimensions)
  const containerStyle: React.CSSProperties = gridPosition
    ? {
        gridColumn: `${gridPosition.x + 1} / span ${width}`,
        gridRow: `${gridPosition.y + 1} / span ${height}`,
        width: `${width * cellSize}px`,
        height: `${height * cellSize}px`,
      }
    : {
        width: `${width * cellSize}px`,
        height: `${height * cellSize}px`,
      };

  // Render grid cells (SAME as InventoryGrid)
  const renderGridCells = () => {
    const cells = [];
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const cellClasses = getSlotClasses({
          isHovered: showValidationFeedback,
          isValidDrop: canDrop || false,
          isDragging: isDragging,
        });

        const cellStyle = getSlotStyle({
          isHovered: showValidationFeedback,
          isValidDrop: canDrop || false,
          cellSize,
        });

        cells.push(
          <div
            key={`${x}-${y}`}
            className={cellClasses}
            style={cellStyle}
          />
        );
      }
    }
    return cells;
  };

  // IDENTICAL drag detection as InventoryGrid
  const handleMouseDown = (e: React.MouseEvent) => {
    if (isEmpty || !onDragStart) return;
    if (e.button !== 0) return; // Only left click

    const startX = e.clientX;
    const startY = e.clientY;
    let dragStarted = false;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      // Calculate distance moved
      const dx = moveEvent.clientX - startX;
      const dy = moveEvent.clientY - startY;
      const distance = Math.sqrt(dx * dx + dy * dy);

      // Only start drag if moved more than 5px (prevents accidental drags)
      if (!dragStarted && distance > 5) {
        dragStarted = true;
        onDragStart(e);

        // Clean up listeners
        window.removeEventListener("mousemove", handleMouseMove);
        window.removeEventListener("mouseup", handleMouseUp);
      }
    };

    const handleMouseUp = () => {
      // Clean up if drag never started (just a click)
      if (!dragStarted) {
        window.removeEventListener("mousemove", handleMouseMove);
        window.removeEventListener("mouseup", handleMouseUp);
      }
    };

    window.addEventListener("mousemove", handleMouseMove);
    window.addEventListener("mouseup", handleMouseUp);
  };

  return (
    <div
      ref={slotRef}
      className={`relative ${className}`}
      style={{
        ...containerStyle,
        display: 'grid',
        gridTemplateColumns: `repeat(${width}, ${cellSize}px)`,
        gridTemplateRows: `repeat(${height}, ${cellSize}px)`,
      }}
      data-droppable={canDrop ? "true" : "false"}
      onMouseUp={(e) => {
        // Handle drop on mouse up (custom drag system)
        if (canDrop && onDrop && e.button === 0) {
          e.stopPropagation();
          onDrop();
        }
      }}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      {/* Grid cells (background) - SAME as InventoryGrid */}
      {renderGridCells()}

      {/* Label (pocket number, slot name, etc.) */}
      {label && (
        <div className="absolute top-0.5 left-1 text-[9px] text-gray-500 uppercase tracking-wide pointer-events-none z-10">
          {label}
        </div>
      )}

      {/* Item rendering over the grid - SAME as InventoryGrid */}
      {!isEmpty && itemDef && (
        <>
          {isThisItemBeingDragged ? (
            // Ghost image when dragging (SAME as InventoryGrid)
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                width: '100%',
                height: '100%',
              }}
            >
              <img
                src={itemDef.image}
                alt={itemDef.label}
                className="w-full h-full object-contain"
                style={{
                  opacity: 0.3,
                  filter: 'grayscale(100%) brightness(0.8)',
                }}
              />
            </div>
          ) : (
            // Normal item rendering
            <div
              className="absolute inset-0 pointer-events-auto cursor-grab active:cursor-grabbing"
              style={{
                width: '100%',
                height: '100%',
              }}
              onMouseDown={handleMouseDown}
              onContextMenu={onContextMenu}
            >
              <ItemRenderer
                item={item}
                itemDef={itemDef}
                cellSize={cellSize}
                inGrid={false}
              />
            </div>
          )}
        </>
      )}
    </div>
  );
};
