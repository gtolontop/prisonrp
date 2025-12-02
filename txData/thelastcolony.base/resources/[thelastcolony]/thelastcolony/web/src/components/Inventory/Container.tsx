/**
 * Container Component
 * Reusable component for displaying loot containers
 * Used in LootView (right side), VehicleView, StorageView
 */

import React from 'react';
import { InventoryGrid } from './InventoryGrid';
import type { LootContainer, ItemDefinition, DraggedItem, MousePosition, InventoryItem } from '@/types';

interface ContainerProps {
  container: LootContainer;
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
  title?: string; // Override container label
  cellSize?: number; // Cell size in px (default 55)
}

export const Container: React.FC<ContainerProps> = ({
  container,
  itemDefinitions,
  draggedItem,
  mousePosition,
  onDragStart,
  onDrop,
  onContextMenu,
  onItemHover,
  onItemLeave,
  title,
  cellSize = 55,
}) => {
  return (
    <div className="flex flex-col gap-3">
      {/* Header */}
      <div className="text-center">
        <h2 className="text-xl font-bold text-white">{title || container.label}</h2>
        <p className="text-xs text-gray-400">
          {container.grid.width}×{container.grid.height} Storage
        </p>
      </div>

      {/* Container Grid */}
      <InventoryGrid
        grid={container.grid}
        itemDefinitions={itemDefinitions}
        draggedItem={draggedItem}
        mousePosition={mousePosition}
        cellSize={cellSize}
        onDragStart={(item, _source, gridPos, mousePos) => {
          // Override source type to 'container' for loot items
          onDragStart(item, { type: 'container', container_id: container.id, position: gridPos }, gridPos, mousePos);
        }}
        onDrop={(position) => {
          if (!draggedItem) return;

          // Build 'from' payload based on source
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
            to: { type: 'container', position },
            rotation: draggedItem.item.rotation || 0,
            container_id: container.id, // Include container ID for server
          });
        }}
        onContextMenu={onContextMenu}
        onItemHover={onItemHover}
        onItemLeave={onItemLeave}
      />
    </div>
  );
};
