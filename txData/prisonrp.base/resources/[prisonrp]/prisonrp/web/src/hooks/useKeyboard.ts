/**
 * Keyboard Hook
 * Handles keyboard events for inventory (R for rotation, ESC to close, etc.)
 */

import { useEffect } from 'react';

interface UseKeyboardOptions {
  onRotate?: () => void;
  onEscape?: () => void;
  onDrop?: () => void; // X to drop item
  onTransfer?: () => void; // T to transfer item to container/loot
  onQuickSlot?: (slotIndex: number) => void; // 0-3 for keys 1-4
  enabled?: boolean;
}

export function useKeyboard(options: UseKeyboardOptions): void {
  const {
    onRotate,
    onEscape,
    onDrop,
    onTransfer,
    onQuickSlot,
    enabled = true,
  } = options;

  useEffect(() => {
    if (!enabled) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // Don't trigger if typing in input
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return;
      }

      switch (e.key.toLowerCase()) {
        case 'r':
          e.preventDefault();
          onRotate?.();
          break;

        case 'x':
          e.preventDefault();
          onDrop?.();
          break;

        case 't':
          e.preventDefault();
          onTransfer?.();
          break;

        case 'escape':
        case 'tab':
        case 'f':
          e.preventDefault();
          onEscape?.();
          break;

        case '1':
        case '2':
        case '3':
        case '4':
          e.preventDefault();
          const slotIndex = parseInt(e.key) - 1;
          onQuickSlot?.(slotIndex);
          break;

        default:
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onRotate, onEscape, onDrop, onTransfer, onQuickSlot, enabled]);
}
