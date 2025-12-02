/**
 * Item Tooltip Component
 * Shows detailed item information on hover
 */

import React from 'react';
import type { InventoryItem, ItemDefinition } from '@/types';
import { UIConfig } from '@/config/ui';

interface ItemTooltipProps {
  item: InventoryItem;
  itemDef: ItemDefinition;
  position: { x: number; y: number };
}

export const ItemTooltip: React.FC<ItemTooltipProps> = ({ item, itemDef, position }) => {
  // Tooltip follows mouse with slight offset (bottom-right)
  const tooltipStyle: React.CSSProperties = {
    position: 'fixed',
    left: `${position.x + 15}px`,
    top: `${position.y + 15}px`,
    zIndex: 9999,
    pointerEvents: 'none',
  };

  // Build className based on config
  const tooltipClassName = [
    'border border-gray-700 shadow-2xl min-w-[280px] max-w-[400px] p-3 transition-opacity duration-75',
    UIConfig.useBackdropBlur ? 'bg-gray-900/95 backdrop-blur-sm' : 'bg-gray-900',
  ].join(' ');

  // Get category color (unused - kept for future UI enhancements)
  // const getCategoryColor = () => {
  //   switch (itemDef.category) {
  //     case 'weapon':
  //       return 'border-yellow-600';
  //     case 'armor':
  //     case 'helmet':
  //       return 'border-blue-600';
  //     case 'medical':
  //       return 'border-green-600';
  //     case 'food':
  //       return 'border-purple-600';
  //     case 'ammo':
  //     case 'magazine':
  //       return 'border-orange-600';
  //     default:
  //       return 'border-gray-600';
  //   }
  // };

  // Get rarity/quality color (unused - kept for future UI enhancements)
  // const getQualityColor = (durability?: number) => {
  //   if (!durability) return 'text-gray-400';
  //   if (durability > 90) return 'text-green-400';
  //   if (durability > 75) return 'text-yellow-400';
  //   if (durability > 50) return 'text-orange-400';
  //   return 'text-red-400';
  // };

  return (
    <div
      className={tooltipClassName}
      style={tooltipStyle}
    >
      {/* Header */}
      <div className="border-b border-gray-700 pb-2 mb-2">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1">
            <div className="text-base font-bold text-white">{itemDef.label}</div>
            <div className="text-xs text-gray-400 capitalize">{itemDef.category}</div>
          </div>
          {item.quantity > 1 && (
            <div className="text-sm font-bold text-white bg-gray-800 px-2 py-1 rounded">
              x{item.quantity}
            </div>
          )}
        </div>
      </div>

      {/* Description */}
      <div className="text-xs text-gray-300 mb-3">{itemDef.description}</div>

      {/* Stats */}
      <div className="space-y-1.5">
        {/* Durability */}
        {item.metadata?.durability !== undefined && item.metadata?.max_durability !== undefined && (
          <div className="flex items-center justify-between">
            <span className="text-xs text-gray-400">Durability</span>
            <span className="text-xs text-white font-medium">
              {item.metadata.durability}/{item.metadata.max_durability}
            </span>
          </div>
        )}

        {/* Weight */}
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-400">Weight</span>
          <span className="text-xs text-white font-medium">
            {(itemDef.weight * item.quantity).toFixed(2)} kg
          </span>
        </div>

        {/* Value */}
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-400">Value</span>
          <span className="text-xs text-white font-medium">
            ${(itemDef.base_value * item.quantity).toLocaleString()}
          </span>
        </div>

        {/* Size */}
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-400">Size</span>
          <span className="text-xs text-white">
            {itemDef.size.width}x{itemDef.size.height}
          </span>
        </div>

        {/* Weapon Stats */}
        {itemDef.category === 'weapon' && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="text-xs font-semibold text-gray-300 mb-1">Weapon Stats</div>

            {itemDef.damage && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Damage</span>
                <span className="text-xs text-white font-medium">{itemDef.damage}</span>
              </div>
            )}

            {itemDef.fire_rate && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Fire Rate</span>
                <span className="text-xs text-white">{itemDef.fire_rate} RPM</span>
              </div>
            )}

            {itemDef.caliber && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Caliber</span>
                <span className="text-xs text-white font-mono">{itemDef.caliber}</span>
              </div>
            )}

            {item.metadata?.loaded_magazine && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Magazine</span>
                <span className="text-xs text-white">Loaded</span>
              </div>
            )}
          </>
        )}

        {/* Armor Stats */}
        {(itemDef.category === 'armor' || itemDef.category === 'helmet') && itemDef.armor_class && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="text-xs font-semibold text-gray-300 mb-1">Armor Stats</div>

            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-400">Class</span>
              <span className="text-xs text-white font-bold">Level {itemDef.armor_class}</span>
            </div>

            {itemDef.armor_zones && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Protection</span>
                <span className="text-xs text-white capitalize">
                  {itemDef.armor_zones.join(', ')}
                </span>
              </div>
            )}

            {itemDef.armor_material && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Material</span>
                <span className="text-xs text-white capitalize">{itemDef.armor_material}</span>
              </div>
            )}
          </>
        )}

        {/* Medical Stats */}
        {itemDef.category === 'medical' && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="text-xs font-semibold text-gray-300 mb-1">Medical Effects</div>

            {itemDef.heal_amount && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Heals</span>
                <span className="text-xs text-white">+{itemDef.heal_amount} HP</span>
              </div>
            )}

            {itemDef.stops_bleeding && (
              <div className="text-xs text-white">✓ Stops Bleeding</div>
            )}

            {itemDef.cures_fracture && (
              <div className="text-xs text-white">✓ Cures Fracture</div>
            )}
          </>
        )}

        {/* Food/Drink Stats */}
        {itemDef.category === 'food' && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="text-xs font-semibold text-gray-300 mb-1">Effects</div>

            {itemDef.energy !== undefined && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Energy</span>
                <span className="text-xs text-white">
                  {itemDef.energy >= 0 ? '+' : ''}{itemDef.energy}
                </span>
              </div>
            )}

            {itemDef.hydration !== undefined && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">Hydration</span>
                <span className="text-xs text-white">
                  {itemDef.hydration >= 0 ? '+' : ''}{itemDef.hydration}
                </span>
              </div>
            )}
          </>
        )}

        {/* Ammo/Magazine Stats */}
        {itemDef.category === 'ammo' && itemDef.penetration && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-400">Penetration</span>
              <span className="text-xs text-white">{itemDef.penetration}</span>
            </div>
          </>
        )}

        {itemDef.category === 'magazine' && itemDef.magazine_capacity && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-400">Capacity</span>
              <span className="text-xs text-white">{itemDef.magazine_capacity} rounds</span>
            </div>
          </>
        )}

        {/* Container Grid */}
        {itemDef.container_grid && (
          <>
            <div className="h-px bg-gray-700 my-2" />
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-400">Storage</span>
              <span className="text-xs text-white">
                {itemDef.container_grid.width}x{itemDef.container_grid.height} grid
              </span>
            </div>
          </>
        )}
      </div>

      {/* Footer hints */}
      {itemDef.usable && (
        <div className="mt-3 pt-2 border-t border-gray-700">
          <div className="text-xs text-gray-500">
            {itemDef.consumable ? 'Right-click to consume' : 'Right-click to use'}
          </div>
        </div>
      )}
    </div>
  );
};
