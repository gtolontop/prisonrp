/**
 * Context Menu Hook
 * Manages context menu state and position
 */

import { useState, useCallback } from 'react';
import type { InventoryItem } from '@/types';

interface ContextMenuState {
  item: InventoryItem | null;
  position: { x: number; y: number };
}

export function useContextMenu() {
  const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null);

  const openContextMenu = useCallback((item: InventoryItem, event: React.MouseEvent) => {
    event.preventDefault();

    setContextMenu({
      item,
      position: {
        x: event.clientX,
        y: event.clientY,
      },
    });
  }, []);

  const closeContextMenu = useCallback(() => {
    setContextMenu(null);
  }, []);

  return {
    contextMenu,
    openContextMenu,
    closeContextMenu,
  };
}
