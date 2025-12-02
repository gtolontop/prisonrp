/**
 * Case Slot Component
 * Permanent case with 3 slots in a row: Card (2x1) + Compass (1x1)
 * Items are NOT draggable, NOT removable, permanent
 */

import React from 'react';
import { ItemRenderer } from './ItemRenderer';
import type { InventoryItem } from '@/types';
import type { ItemDefinition } from '@/types';

export interface CaseSlotProps {
  cardItem: InventoryItem | null; // Card (takes 2 slots)
  compassItem: InventoryItem | null; // Compass (takes 1 slot)
  itemDefinitions: Record<string, ItemDefinition>;
  cellSize?: number; // Default 55
}

export const CaseSlot: React.FC<CaseSlotProps> = ({
  cardItem,
  compassItem,
  itemDefinitions,
  cellSize = 55,
}) => {
  const borderWidth = 2;
  const borderColor = '#C1C9C1';

  return (
    <div className="flex flex-col gap-2">
      {/* Label */}
      <div className="text-xs text-gray-400 uppercase font-semibold">Case</div>

      {/* 3 slots in a row: [Card][Card][Compass] */}
      <div
        className="flex"
        style={{
          background: '#060809',
          border: `${borderWidth}px solid ${borderColor}`,
        }}
      >
        {/* Card slot (2x1) */}
        <div
          className="relative flex items-center justify-center"
          style={{
            width: `${cellSize * 2}px`,
            height: `${cellSize}px`,
            borderRight: `1px solid rgba(255, 255, 255, 0.1)`,
            background: 'rgba(60, 60, 60, 0.3)',
          }}
        >
          {cardItem ? (
            <ItemRenderer
              item={cardItem}
              itemDef={itemDefinitions[cardItem.item_id]}
              cellSize={cellSize}
              isDragging={false}
              inGrid={false}
            />
          ) : (
            <div className="text-xs text-gray-600 pointer-events-none">Card</div>
          )}

          {/* Lock icon overlay */}
          <div className="absolute top-1 right-1 text-gray-600 text-xs pointer-events-none">
            🔒
          </div>
        </div>

        {/* Compass slot (1x1) */}
        <div
          className="relative flex items-center justify-center"
          style={{
            width: `${cellSize}px`,
            height: `${cellSize}px`,
            background: 'rgba(60, 60, 60, 0.3)',
          }}
        >
          {compassItem ? (
            <ItemRenderer
              item={compassItem}
              itemDef={itemDefinitions[compassItem.item_id]}
              cellSize={cellSize}
              isDragging={false}
              inGrid={false}
            />
          ) : (
            <div className="text-xs text-gray-600 pointer-events-none">Compass</div>
          )}

          {/* Lock icon overlay */}
          <div className="absolute top-1 right-1 text-gray-600 text-xs pointer-events-none">
            🔒
          </div>
        </div>
      </div>

      {/* Info text */}
      <div className="text-xs text-gray-500 italic">Permanent items (cannot be removed)</div>
    </div>
  );
};
