/**
 * CfxGameView Component
 * Wrapper to enable/disable cfx-game-view for FiveM NUI backdrop-filter support
 *
 * IMPORTANT: To use backdrop-filter in FiveM, you need an <object type="application/x-cfx-game-view">
 * element BEHIND your UI. This component creates that structure automatically.
 *
 * When enabled: Creates game view object + container for proper backdrop-filter
 * When disabled: Fallback to standard div (no blur support)
 */

import React from 'react';

interface CfxGameViewProps {
  enabled?: boolean; // Enable cfx-game-view object (default: true)
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * Container with optional cfx-game-view support for backdrop-filter
 *
 * Usage:
 * <CfxGameView enabled={true}>
 *   <YourUIContent />
 * </CfxGameView>
 *
 * When enabled=true:
 *   - Creates <object type="application/x-cfx-game-view"> (game render)
 *   - Places your UI on top with proper layering
 *   - backdrop-filter will now work correctly
 *
 * When enabled=false:
 *   - Standard div (backdrop-filter will show black background)
 */
export const CfxGameView: React.FC<CfxGameViewProps> = ({
  enabled = true,
  children,
  className = '',
  style
}) => {
  if (enabled) {
    return (
      <div
        className={className}
        style={{
          ...style,
          position: 'relative',
        }}
      >
        {/* Game view object - renders the game underneath UI */}
        <object
          type="application/x-cfx-game-view"
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            zIndex: -1,
            pointerEvents: 'none',
          }}
        />

        {/* UI content on top */}
        <div style={{ position: 'relative', zIndex: 1 }}>
          {children}
        </div>
      </div>
    );
  }

  // Fallback without cfx-game-view (backdrop-filter won't work)
  return (
    <div
      className={className}
      style={style}
    >
      {children}
    </div>
  );
};
