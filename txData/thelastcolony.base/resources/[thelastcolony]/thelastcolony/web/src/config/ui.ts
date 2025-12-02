/**
 * UI Configuration
 * Global settings for UI behavior
 */

export const UIConfig = {
  /**
   * Enable cfx-game-view for FiveM NUI
   *
   * When TRUE:
   * - Enables proper backdrop-blur rendering
   * - Allows game rendering underneath UI
   * - Required for blur effects to work in FiveM
   *
   * When FALSE:
   * - Fallback to standard div
   * - Blur effects won't work properly in FiveM (will show black)
   * - Use if you have compatibility issues
   */
  useCfxGameView: false,

  /**
   * Enable backdrop-blur CSS effects
   * Only works properly if useCfxGameView = true
   *
   * When FALSE:
   * - Uses solid backgrounds instead of blur
   * - Better performance
   * - More compatible but less modern look
   */
  useBackdropBlur: false,
};
