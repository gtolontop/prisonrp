/**
 * Drag and Drop Hook
 * Handles all drag & drop logic for inventory items with custom mouse tracking
 * Includes operation locking to prevent concurrent operations
 */

import { useState, useCallback, useEffect, useRef } from 'react';
import type { DraggedItem, InventoryItem, RotationIndex } from '@/types';

interface UseDragAndDropReturn {
  draggedItem: DraggedItem | null;
  isDragging: boolean;
  mousePosition: { x: number; y: number };
  isOperationInProgress: boolean;
  startDrag: (item: InventoryItem, source: DraggedItem['source'], offset: { x: number; y: number }, initialMousePos: { x: number; y: number }) => void;
  endDrag: () => void;
  cancelDrag: () => void;
  rotateDraggedItem: (itemDef: { size: { width: number; height: number } }) => void;
  updateDraggedItemPosition: (position: { x: number; y: number }) => void;
  lockOperation: () => boolean;
  unlockOperation: () => void;
}

export function useDragAndDrop(): UseDragAndDropReturn {
  const [draggedItem, setDraggedItem] = useState<DraggedItem | null>(null);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const operationLock = useRef<boolean>(false);
  const lockTimeout = useRef<NodeJS.Timeout | null>(null);

  const startDrag = useCallback(
    (
      item: InventoryItem,
      source: DraggedItem['source'],
      offset: { x: number; y: number },
      initialMousePos: { x: number; y: number }
    ) => {
      // Set mouse position immediately to avoid jump
      setMousePosition(initialMousePos);

      // Create a copy of the item for dragging (so we can modify rotation without affecting the original)
      const itemCopy = { ...item };

      setDraggedItem({
        item: itemCopy,
        source,
        offset,
      });
    },
    []
  );

  const lockOperation = useCallback(() => {
    // If already locked, reject the operation
    if (operationLock.current) {
      console.log('[DragDrop] Operation rejected - another operation in progress');
      return false;
    }

    operationLock.current = true;

    // Auto-unlock after 2 seconds as a safety measure
    if (lockTimeout.current) {
      clearTimeout(lockTimeout.current);
    }
    lockTimeout.current = setTimeout(() => {
      operationLock.current = false;
      console.log('[DragDrop] Operation lock auto-released');
    }, 2000);

    return true;
  }, []);

  const unlockOperation = useCallback(() => {
    if (lockTimeout.current) {
      clearTimeout(lockTimeout.current);
      lockTimeout.current = null;
    }
    operationLock.current = false;
  }, []);

  const endDrag = useCallback(() => {
    setDraggedItem(null);
    unlockOperation();
  }, [unlockOperation]);

  const cancelDrag = useCallback(() => {
    setDraggedItem(null);
    unlockOperation();
  }, [unlockOperation]);

  const updateDraggedItemPosition = useCallback((position: { x: number; y: number }) => {
    setDraggedItem((prev) => {
      if (!prev) return null;
      return {
        ...prev,
        item: {
          ...prev.item,
          position,
        },
      };
    });
  }, []);

  const rotateDraggedItem = useCallback((itemDef: { size: { width: number; height: number } }) => {
    setDraggedItem((prev) => {
      if (!prev) return null;

      // Don't rotate square items (1x1, 2x2, 3x3, etc.)
      if (itemDef.size.width === itemDef.size.height) {
        console.log(`[DragDrop] Cannot rotate square item (${itemDef.size.width}x${itemDef.size.height})`);
        return prev;
      }

      // Simple toggle between 0 and 1 ONLY
      const newRotation = (prev.item.rotation === 0 ? 1 : 0) as RotationIndex;

      console.log(`[DragDrop] Rotating item from ${prev.item.rotation} to ${newRotation}`);

      // Keep the same offset - simplest approach
      // The item will shift a bit visually but it's consistent
      return {
        ...prev,
        item: {
          ...prev.item,
          rotation: newRotation,
        },
      };
    });
  }, []);

  // Track mouse position globally when dragging
  useEffect(() => {
    if (!draggedItem) return;

    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };

    const handleMouseUp = (e: MouseEvent) => {
      // Store mouse up event for grid to handle
      setMousePosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);

    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [draggedItem]);

  return {
    draggedItem,
    isDragging: draggedItem !== null,
    mousePosition,
    isOperationInProgress: operationLock.current,
    startDrag,
    endDrag,
    cancelDrag,
    rotateDraggedItem,
    updateDraggedItemPosition,
    lockOperation,
    unlockOperation,
  };
}
