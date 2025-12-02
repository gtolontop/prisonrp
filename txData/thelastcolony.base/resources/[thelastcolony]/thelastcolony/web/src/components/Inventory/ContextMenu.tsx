/**
 * Context Menu Component
 * Right-click menu for inventory items
 */

import React, { useEffect, useRef } from 'react';
import type { InventoryItem, ItemDefinition } from '@/types';

interface ContextMenuAction {
  label: string;
  icon?: string;
  color?: string;
  onClick: () => void;
  disabled?: boolean;
}

interface ContextMenuProps {
  item: InventoryItem;
  itemDef: ItemDefinition;
  position: { x: number; y: number };
  onClose: () => void;
  onUse?: () => void;
  onEquip?: () => void;
  onUnequip?: () => void;
  onDrop?: () => void;
  // onDiscard removed - same as drop
  onInspect?: () => void;
  onSplit?: () => void;
  onUnload?: () => void; // For weapons with magazines
}

export const ContextMenu: React.FC<ContextMenuProps> = ({
  item,
  itemDef,
  position,
  onClose,
  onUse,
  onEquip,
  onUnequip,
  onDrop,
  onInspect,
  onSplit,
  onUnload,
}) => {
  const menuRef = useRef<HTMLDivElement>(null);

  // Close on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        onClose();
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [onClose]);

  // Close on ESC
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  // Build actions based on item type
  const actions: ContextMenuAction[] = [];

  // Use (consumables, medical, food)
  if (itemDef.usable && onUse) {
    actions.push({
      label: itemDef.consumable ? 'Consume' : 'Use',
      icon: '✓',
      color: 'text-green-400',
      onClick: () => {
        onUse();
        onClose();
      },
    });
  }

  // Equip (weapons, armor, etc.) - use 'type' not 'category'
  if (item.slot_type !== 'equipment' && ['weapon', 'armor', 'helmet', 'rig', 'backpack'].includes(itemDef.type) && onEquip) {
    actions.push({
      label: 'Equip',
      icon: '🎽',
      onClick: () => {
        onEquip();
        onClose();
      },
    });
  }

  // Unequip
  if (item.slot_type === 'equipment' && onUnequip) {
    actions.push({
      label: 'Unequip',
      icon: '📤',
      onClick: () => {
        onUnequip();
        onClose();
      },
    });
  }

  // Unload magazine (weapons with loaded mag)
  if (itemDef.category === 'weapon' && item.metadata?.loaded_magazine && onUnload) {
    actions.push({
      label: 'Unload Magazine',
      icon: '🔓',
      onClick: () => {
        onUnload();
        onClose();
      },
    });
  }

  // Split stack
  if (itemDef.stackable && item.quantity > 1 && onSplit) {
    actions.push({
      label: 'Split Stack',
      icon: '✂',
      onClick: () => {
        onSplit();
        onClose();
      },
    });
  }

  // Inspect
  if (onInspect) {
    actions.push({
      label: 'Inspect',
      icon: '🔍',
      onClick: () => {
        onInspect();
        onClose();
      },
    });
  }

  // Separator
  if (actions.length > 0) {
    actions.push({
      label: '',
      onClick: () => {},
      disabled: true,
    });
  }

  // Drop (discard and drop are the same - removes item)
  if (onDrop) {
    actions.push({
      label: 'Drop',
      icon: '🗑',
      color: 'text-red-400',
      onClick: () => {
        onDrop();
        onClose();
      },
    });
  }

  // Discard removed - same as drop

  // Calculate menu position (prevent overflow)
  const menuStyle: React.CSSProperties = {
    position: 'fixed',
    left: `${position.x}px`,
    top: `${position.y}px`,
    zIndex: 10000,
  };

  return (
    <div
      ref={menuRef}
      className="bg-gray-900 border-2 border-gray-700 rounded shadow-2xl min-w-[180px] py-1"
      style={menuStyle}
    >
      {/* Header */}
      <div className="px-3 py-2 border-b border-gray-700">
        <div className="text-sm font-semibold text-white truncate">
          {itemDef.label}
        </div>
        {item.quantity > 1 && (
          <div className="text-xs text-gray-400">
            x{item.quantity}
          </div>
        )}
        {item.metadata?.durability !== undefined && (
          <div className="flex items-center gap-1 mt-1">
            <div className="flex-1 h-1 bg-gray-800 rounded">
              <div
                className={`h-full rounded ${
                  item.metadata.durability > 75
                    ? 'bg-green-500'
                    : item.metadata.durability > 50
                    ? 'bg-yellow-500'
                    : item.metadata.durability > 25
                    ? 'bg-orange-500'
                    : 'bg-red-500'
                }`}
                style={{ width: `${item.metadata.durability}%` }}
              />
            </div>
            <span className="text-xs text-gray-500">
              {item.metadata.durability}%
            </span>
          </div>
        )}
      </div>

      {/* Actions */}
      <div className="py-1">
        {actions.map((action, index) => {
          if (action.label === '') {
            return <div key={index} className="h-px bg-gray-700 my-1" />;
          }

          return (
            <button
              key={index}
              onClick={action.onClick}
              disabled={action.disabled}
              className={`w-full px-3 py-1.5 text-left text-sm flex items-center gap-2 transition-colors ${
                action.disabled
                  ? 'opacity-50 cursor-not-allowed'
                  : 'hover:bg-gray-800'
              } ${action.color || 'text-gray-300'}`}
            >
              {action.icon && <span className="text-base">{action.icon}</span>}
              <span>{action.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
