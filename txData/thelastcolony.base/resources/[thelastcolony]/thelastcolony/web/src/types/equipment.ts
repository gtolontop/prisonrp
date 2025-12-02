/**
 * Equipment System Types
 * Handles equipped items (weapons, armor, clothing)
 */

import type { InventoryItem } from './inventory';

export type EquipmentSlotName =
  | 'headgear'    // Helmet/hat
  | 'headset'     // Earphones/comms
  | 'face_cover'  // Gas mask/balaclava
  | 'armor'       // Body armor
  | 'rig'         // Tactical rig/vest
  | 'backpack'    // Backpack
  | 'primary'     // Primary weapon
  | 'secondary'   // Secondary weapon
  | 'holster'     // Sidearm
  | 'sheath'      // Melee weapon (default knife)
  | 'case';       // Secure case (contains card + compass)

export interface EquipmentSlotDefinition {
  name: EquipmentSlotName;
  label: string;
  allowed_categories: string[]; // Item categories that can go here
  required: boolean; // If false, can be empty
}

export interface EquippedItem {
  slot: EquipmentSlotName;
  item: InventoryItem;
}

export interface PlayerEquipment {
  headgear: InventoryItem | null;
  headset: InventoryItem | null;
  face_cover: InventoryItem | null;
  armor: InventoryItem | null;
  rig: InventoryItem | null;
  backpack: InventoryItem | null;
  primary: InventoryItem | null;
  secondary: InventoryItem | null;
  holster: InventoryItem | null;
  sheath: InventoryItem | null;
  case: InventoryItem | null; // Secure case (permanent)
}

/**
 * Armor protection calculation
 */
export interface ArmorProtection {
  class: number; // 1-6
  durability: number; // 0-100
  zones: BodyZone[];
  material: 'ceramic' | 'steel' | 'aramid' | 'composite';

  // Effectiveness against different ammo types
  penetration_resistance: number; // 0-100
}

export type BodyZone =
  | 'head'
  | 'thorax'
  | 'stomach'
  | 'left_arm'
  | 'right_arm'
  | 'left_leg'
  | 'right_leg';

export interface BodyHealth {
  zone: BodyZone;
  health: number; // 0-100
  max_health: number;

  // Status effects
  bleeding: boolean;
  fractured: boolean;
  blacked_out: boolean; // Health at 0
}

/**
 * Weapon stats with modifiers from attachments
 */
export interface WeaponStats {
  // Base stats
  base_damage: number;
  base_fire_rate: number;
  base_recoil: number;
  base_ergonomics: number;
  base_accuracy: number;

  // Modified stats (after attachments)
  effective_damage: number;
  effective_fire_rate: number;
  effective_recoil: number;
  effective_ergonomics: number;
  effective_accuracy: number;

  // Current state
  loaded_ammo: number;
  magazine_capacity: number;
  chambered: boolean;
  durability: number; // 0-100

  // Fire modes
  available_fire_modes: FireMode[];
  current_fire_mode: FireMode;
}

export type FireMode = 'safe' | 'semi' | 'burst' | 'auto';

/**
 * Attachment modifiers
 */
export interface AttachmentModifiers {
  recoil_modifier: number; // -10 = -10% recoil
  ergonomics_modifier: number;
  accuracy_modifier: number;
  weight_modifier: number;
}

/**
 * Quick slot for easy access (1-4 keys)
 */
export interface QuickSlot {
  index: number; // 0-3 (maps to keys 1-4)
  item_id: string | null; // Item in inventory to quick-use
  keybind: string; // '1', '2', '3', '4'
}

/**
 * Clothing/Appearance (future Phase 3)
 */
export interface ClothingSlot {
  slot: 'hat' | 'glasses' | 'mask' | 'top' | 'pants' | 'shoes' | 'gloves';
  item_id: string | null;
  // Drawables and textures for GTA V native clothing system
  drawable: number;
  texture: number;
}
