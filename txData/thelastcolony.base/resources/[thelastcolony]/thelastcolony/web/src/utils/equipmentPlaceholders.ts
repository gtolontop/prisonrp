/**
 * Equipment Slot Placeholder Images
 * Generates simple SVG placeholders until real images are added
 */

// Try to load real images, fallback to SVG placeholders
const getPlaceholderImage = (slotName: string): string => {
  // TODO: First try to load real image when available
  // const imagePath = `/images/placeholders/${slotName}.png`;

  // For now, return SVG data URL as fallback
  // These will be replaced by real images later
  return generateSVGPlaceholder(slotName);
};

const generateSVGPlaceholder = (slotName: string): string => {
  const label = slotName.replace('_', ' ').toUpperCase();

  // Simple SVG with text label
  const svg = `
    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
      <rect width="100" height="100" fill="none" stroke="#555" stroke-width="2" stroke-dasharray="5,5"/>
      <text x="50" y="50" font-family="Arial" font-size="10" fill="#888" text-anchor="middle" dominant-baseline="middle">
        ${label}
      </text>
    </svg>
  `;

  return `data:image/svg+xml;base64,${btoa(svg)}`;
};

// Export placeholder images for each slot
export const EQUIPMENT_PLACEHOLDERS = {
  headgear: getPlaceholderImage('headgear'),
  headset: getPlaceholderImage('headset'),
  face_cover: getPlaceholderImage('face_cover'),
  armor: getPlaceholderImage('armor'),
  rig: getPlaceholderImage('rig'),
  backpack: getPlaceholderImage('backpack'),
  primary: getPlaceholderImage('primary_weapon'),
  secondary: getPlaceholderImage('secondary_weapon'),
  holster: getPlaceholderImage('holster'),
  sheath: getPlaceholderImage('sheath'),
  case: getPlaceholderImage('secure_case'),
};
