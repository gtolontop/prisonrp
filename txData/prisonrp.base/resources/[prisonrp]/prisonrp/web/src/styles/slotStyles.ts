/**
 * Shared Slot Styles
 * Single source of truth for slot styling across all inventory components
 */

export interface SlotStyleOptions {
  isHovered: boolean;
  isValidDrop: boolean;
  isDragging?: boolean;
  cellSize?: number;
}

/**
 * Get complete inline style object for a slot
 * ALL slots use backpack grid style
 */
export function getSlotStyle(options: SlotStyleOptions): React.CSSProperties {
  const { isHovered, isValidDrop, cellSize = 50 } = options;

  let background = "#060809"; // Black background (default)
  let border = "0.5px solid rgba(255, 255, 255, 0.08)"; // Fine white border (darker)

  if (isHovered && isValidDrop) {
    background = "#101F11CC"; // Green dark with transparency
    border = "0.5px solid #101F11";
  } else if (isHovered && !isValidDrop) {
    background = "#210609CC"; // Red dark with transparency
    border = "0.5px solid #210609";
  }

  return {
    width: `${cellSize}px`,
    height: `${cellSize}px`,
    background,
    border,
    boxSizing: "border-box",
  };
}

/**
 * Get Tailwind classes for slot
 * ALL slots use backpack grid style
 */
export function getSlotClasses(options: SlotStyleOptions): string {
  const { isHovered, isValidDrop } = options;

  const classes = [
    "transition-all duration-150 ease-out",
    isHovered && isValidDrop ? "opacity-100" : "",
    isHovered && !isValidDrop ? "opacity-100" : "",
  ];

  return classes.filter(Boolean).join(" ");
}
