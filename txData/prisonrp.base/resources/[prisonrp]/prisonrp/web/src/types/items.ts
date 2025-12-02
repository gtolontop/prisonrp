/**
 * Item Definition Types
 * Mirrors the shared/items.lua structure
 */

export type ItemCategory =
  | 'weapon'
  | 'ammo'
  | 'magazine'
  | 'attachment'
  | 'armor'
  | 'helmet'
  | 'rig'
  | 'backpack'
  | 'medical'
  | 'food'
  | 'container'
  | 'key'
  | 'tool'
  | 'misc'
  | 'quest';

export type WeaponType = 'pistol' | 'smg' | 'rifle' | 'shotgun' | 'sniper' | 'melee';

export type AmmoType =
  | '9x19'
  | '5.56x45'
  | '7.62x39'
  | '7.62x51'
  | '12gauge'
  | '.45ACP'
  | '5.45x39';

export interface ItemSize {
  width: number;
  height: number;
}

export interface ItemDefinition {
  // Basic info
  name: string;
  label: string;
  description: string;
  type: string; // Item type from items.lua (weapon, armor, rig, helmet, etc.)
  category?: ItemCategory; // Optional, legacy field

  // Visual
  image: string; // Path to image asset
  model?: string; // 3D model hash (for world drops)
  icon?: string; // UI icon override

  // Grid properties
  size: ItemSize;
  rotatable: boolean;

  // Stacking
  stackable: boolean;
  max_stack?: number;

  // Weight
  weight: number; // in kg

  // Economy
  base_value: number; // Base sell price

  // Usage
  usable: boolean;
  consumable: boolean;

  // Weapon-specific
  weapon_type?: WeaponType;
  caliber?: AmmoType;
  compatible_magazines?: string[]; // Magazine item_ids
  compatible_ammo?: string[]; // Ammo item_ids
  damage?: number;
  fire_rate?: number; // rounds per minute
  recoil?: number;
  ergonomics?: number;

  // Magazine-specific
  magazine_capacity?: number;
  magazine_caliber?: AmmoType;

  // Ammo-specific
  ammo_caliber?: AmmoType;
  penetration?: number; // 1-100
  damage_modifier?: number; // 0.8 = 80% damage, 1.2 = 120% damage
  tracer?: boolean;

  // Armor-specific
  armor_class?: number; // 1-6
  armor_zones?: string[]; // ["head", "thorax", "stomach"]
  armor_durability?: number;
  armor_material?: string; // "ceramic", "steel", "aramid"

  // Container-specific (backpacks, rigs)
  container_grid?: ItemSize;

  // Equipment-specific
  equipSlot?: 'headgear' | 'headset' | 'face_cover' | 'armor' | 'rig' | 'backpack' | 'primary' | 'secondary' | 'holster' | 'sheath' | 'case'; // Which equipment slot this item can go in
  fillsBodyArmor?: boolean; // If true, this rig also fills the body armor slot (blocking it)

  // Medical-specific
  heal_amount?: number;
  heal_over_time?: boolean;
  heal_duration?: number; // seconds
  stops_bleeding?: boolean;
  cures_fracture?: boolean;

  // Food/Drink
  hydration?: number; // -100 to 100
  energy?: number; // -100 to 100

  // Metadata template
  metadata_template?: Partial<import('./inventory').ItemMetadata>;
}

/**
 * Compatibility check result
 */
export interface CompatibilityCheck {
  compatible: boolean;
  reason?: string;
}

/**
 * Item comparison (for UI sorting/filtering)
 */
export type ItemSortField = 'name' | 'weight' | 'value' | 'category';
export type ItemSortOrder = 'asc' | 'desc';

export interface ItemFilter {
  category?: ItemCategory[];
  search?: string;
  min_value?: number;
  max_value?: number;
  min_weight?: number;
  max_weight?: number;
}
