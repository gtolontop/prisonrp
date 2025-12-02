/**
 * Hovered Item Hook
 * Tracks which item is currently hovered for keyboard shortcuts
 */

import { useState } from 'react';
import type { InventoryItem } from '@/types/inventory';

interface HoveredItemData {
  item: InventoryItem;
  source: {
    type: 'grid' | 'pocket' | 'equipment' | 'rig' | 'loot' | 'storage';
    container_id?: string;
    position?: { x: number; y: number };
    slot_index?: number;
    slot_name?: string;
  };
}

export function useHoveredItem() {
  const [hoveredItem, setHoveredItem] = useState<HoveredItemData | null>(null);

  const setHovered = (item: InventoryItem | null, source?: HoveredItemData['source']) => {
    if (item && source) {
      setHoveredItem({ item, source });
    } else {
      setHoveredItem(null);
    }
  };

  const clearHovered = () => {
    setHoveredItem(null);
  };

  return {
    hoveredItem,
    setHovered,
    clearHovered,
  };
}
