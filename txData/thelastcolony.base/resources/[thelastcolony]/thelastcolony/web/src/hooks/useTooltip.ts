/**
 * Tooltip Hook
 * Manages item tooltip state with real-time mouse tracking
 */

import { useState, useCallback, useEffect } from 'react';
import type { InventoryItem } from '@/types';

interface TooltipState {
  item: InventoryItem;
  position: { x: number; y: number };
}

interface UseTooltipReturn {
  tooltip: TooltipState | null;
  showTooltip: (item: InventoryItem) => void;
  hideTooltip: () => void;
}

export function useTooltip(): UseTooltipReturn {
  const [tooltip, setTooltip] = useState<TooltipState | null>(null);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  const showTooltip = useCallback((item: InventoryItem) => {
    setTooltip({
      item,
      position: mousePosition,
    });
  }, [mousePosition]);

  const hideTooltip = useCallback(() => {
    setTooltip(null);
  }, []);

  // Track global mouse position
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const newPos = { x: e.clientX, y: e.clientY };
      setMousePosition(newPos);

      // Update tooltip position if active
      setTooltip((prev) => {
        if (!prev) return null;
        return {
          ...prev,
          position: newPos,
        };
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return {
    tooltip,
    showTooltip,
    hideTooltip,
  };
}
