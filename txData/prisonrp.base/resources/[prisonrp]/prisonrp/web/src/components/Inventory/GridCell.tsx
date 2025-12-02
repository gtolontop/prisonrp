/**
 * Grid Cell Component
 * Individual cell in the inventory grid
 * Handles rendering, drag detection, and drop validation
 */

import React from 'react';
import type { GridPosition, InventoryItem } from '@/types';

interface GridCellProps {
  position: GridPosition;
  size: number; // Cell size in pixels
  item: InventoryItem | null;
  isOccupied: boolean;
  isValidDrop: boolean;
  isDragOver: boolean;
  onDragStart?: (item: InventoryItem, offset: { x: number; y: number }) => void;
  onDragOver?: (position: GridPosition) => void;
  onDrop?: (position: GridPosition) => void;
  onContextMenu?: (item: InventoryItem, event: React.MouseEvent) => void;
}

export const GridCell: React.FC<GridCellProps> = ({
  position,
  size,
  item,
  isOccupied,
  isValidDrop,
  isDragOver,
  onDragStart,
  onDragOver,
  onDrop,
  onContextMenu,
}) => {
  const handleMouseDown = (e: React.MouseEvent) => {
    if (!item || !onDragStart) return;

    // Only left click
    if (e.button !== 0) return;

    // Calculate offset from top-left corner of item
    const rect = e.currentTarget.getBoundingClientRect();
    const offset = {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
    };

    onDragStart(item, offset);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    if (onDragOver) {
      onDragOver(position);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (onDrop) {
      onDrop(position);
    }
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    if (item && onContextMenu) {
      onContextMenu(item, e);
    }
  };

  // Cell styling
  const cellClass = [
    'relative border border-gray-700',
    isDragOver && isValidDrop ? 'bg-green-500/20 border-green-500' : '',
    isDragOver && !isValidDrop ? 'bg-red-500/20 border-red-500' : '',
    !isDragOver && isOccupied ? 'bg-gray-800' : 'bg-gray-900',
    item ? 'cursor-grab active:cursor-grabbing' : '',
  ].filter(Boolean).join(' ');

  return (
    <div
      className={cellClass}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        gridColumn: position.x + 1,
        gridRow: position.y + 1,
      }}
      onMouseDown={handleMouseDown}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
      onContextMenu={handleContextMenu}
    >
      {/* Item will be rendered by ItemRenderer component */}
      {/* This is just the cell background */}
    </div>
  );
};
