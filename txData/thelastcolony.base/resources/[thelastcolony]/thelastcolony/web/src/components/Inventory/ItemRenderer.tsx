/**
 * Item Renderer Component
 * Renders item visuals on grid with image, quantity, durability, etc.
 */

import React from 'react';
import type { InventoryItem } from '@/types';
import type { ItemDefinition } from '@/types';

interface ItemRendererProps {
  item: InventoryItem;
  itemDef: ItemDefinition;
  cellSize: number;
  isDragging?: boolean;
  isPreview?: boolean;
  inGrid?: boolean; // TRUE if in InventoryGrid (needs calculated size), FALSE if in Slot (takes parent size)
}

export const ItemRenderer: React.FC<ItemRendererProps> = ({
  item,
  itemDef,
  cellSize,
  inGrid = false,
}) => {

  // Calculate item dimensions based on rotation (ONLY for grids)
  const getItemDimensions = () => {
    const { size, rotatable } = itemDef;
    const rotation = item.rotation;

    // Rotation 1 (90°) and 3 (270°) swap width and height
    if (rotatable && (rotation === 1 || rotation === 3)) {
      return {
        width: size.height * cellSize,
        height: size.width * cellSize,
      };
    }

    return {
      width: size.width * cellSize,
      height: size.height * cellSize,
    };
  };

  const dimensions = inGrid ? getItemDimensions() : null;

  // Calculate rotation angle for image (only for non-square items)
  const getRotationAngle = () => {
    const { size } = itemDef;
    // Don't rotate square items (1x1, 2x2, 3x3, etc.)
    if (size.width === size.height) {
      return 0;
    }
    const rotation = item.rotation ?? 0;
    return rotation * 90; // 0°, 90°, 180°, 270°
  };

  const itemCardClass = [
    'overflow-hidden',
  ].filter(Boolean).join(' ');

  // If in grid: fixed size. If in slot: take 100% of parent
  const wrapperStyle = inGrid && dimensions
    ? {
        width: `${dimensions.width}px`,
        height: `${dimensions.height}px`,
      }
    : {};

  const wrapperClass = inGrid ? 'relative' : 'relative w-full h-full';

  return (
    <div
      className={wrapperClass}
      style={wrapperStyle}
    >
      <div
        className={itemCardClass}
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'radial-gradient(81.97% 50% at 50% 50%, rgba(90, 90, 90, 0.30) 0%, rgba(87, 87, 87, 0.45) 100%),rgba(0, 0, 0, 0.35)',
          padding: '2px',
        }}
      >
        {/* Item Image - Centered */}
        <img
          src={itemDef.image}
          alt={itemDef.label}
          className="object-contain"
          style={{
            maxWidth: '100%',
            maxHeight: '100%',
            transform: `rotate(${getRotationAngle()}deg)`,
            transition: 'transform 0.2s ease-out',
          }}
          draggable={false}
        />

        {/* Item Name (top left) */}
        <div className="absolute top-0 left-0.5 pointer-events-none">
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

        {/* Quantity (if stackable) */}
        {itemDef.stackable && item.quantity > 1 && (
          <div className="absolute bottom-0 right-0 px-1 text-xs text-white font-bold pointer-events-none">
            {item.quantity}
          </div>
        )}

        {/* Durability Text (bottom right) */}
        {item.metadata?.durability !== undefined && item.metadata?.max_durability !== undefined && (
          <div className="absolute bottom-0 right-0 px-1 text-xs text-white font-bold pointer-events-none">
            {item.metadata.durability}/{item.metadata.max_durability}
          </div>
        )}

        {/* Item Name Tooltip (on hover - will be handled by parent) */}
      </div>
    </div>
  );
};
