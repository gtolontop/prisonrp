/**
 * Player State Types
 * Core player data, stats, and status
 */

import type { PlayerInventory } from './inventory';
import type { PlayerEquipment, BodyHealth } from './equipment';

export interface PlayerData {
  // Identity
  character_id: string; // ox_core character ID
  name: string;
  level: number;

  // Inventory & Equipment
  inventory: PlayerInventory;
  equipment: PlayerEquipment;

  // Health
  body_health: BodyHealth[];
  overall_health: number; // 0-100
  is_alive: boolean;

  // Status effects
  bleeding: boolean;
  fractures: string[]; // ["left_arm", "right_leg"]
  pain: number; // 0-100
  stamina: number; // 0-100
  hydration: number; // 0-100
  energy: number; // 0-100

  // Location
  is_in_safe_zone: boolean;
  current_zone?: string; // Zone ID if any

  // Economy
  money: number;
  bank: number;

  // Stats (for leaderboards - future Phase 4)
  kills: number;
  deaths: number;
  extractions: number;
  total_loot_value: number;

  // Session
  session_start: number; // Timestamp
  time_in_raid: number; // Seconds
}

/**
 * Nearby players (for proximity UI)
 */
export interface NearbyPlayer {
  server_id: number;
  name: string;
  distance: number; // meters
  is_hostile: boolean;
  is_in_guild: boolean;
}

/**
 * Player action state
 */
export type PlayerAction =
  | 'idle'
  | 'looting'
  | 'healing'
  | 'eating'
  | 'drinking'
  | 'reloading'
  | 'using_item'
  | 'searching'
  | 'extracting';

export interface PlayerActionState {
  action: PlayerAction;
  progress: number; // 0-100
  time_remaining: number; // seconds
  cancelable: boolean;
}

/**
 * Guild/Group info
 */
export interface GuildInfo {
  id: string;
  name: string;
  tag: string; // [TAG]
  role: 'leader' | 'officer' | 'member';
  member_count: number;
  online_members: number;
}

/**
 * Player permissions/flags
 */
export interface PlayerFlags {
  is_admin: boolean;
  is_moderator: boolean;
  can_spawn_items: boolean;
  god_mode: boolean;
  no_clip: boolean;
}

/**
 * Player preferences (saved in DB)
 */
export interface PlayerPreferences {
  // UI
  ui_scale: number; // 0.8 - 1.2
  show_tooltips: boolean;
  show_weight: boolean;
  show_durability: boolean;

  // Audio
  master_volume: number; // 0-100
  voice_volume: number;
  sfx_volume: number;
  music_volume: number;

  // Gameplay
  auto_reload: boolean;
  toggle_aim: boolean;
  invert_mouse: boolean;

  // Keybinds
  keybinds: Record<string, string>; // action -> key
}

/**
 * Death info (for death screen)
 */
export interface DeathInfo {
  killer_name?: string;
  killer_weapon?: string;
  death_zone: string; // Body zone hit
  distance?: number; // Distance from killer
  time_of_death: number; // Timestamp
  lost_items: string[]; // Item IDs lost
  insurance_available: boolean; // Future feature
}

/**
 * Extraction info
 */
export interface ExtractionPoint {
  id: string;
  name: string;
  type: 'military_base' | 'helicopter';
  distance: number; // meters
  active: boolean;
  requires_beacon: boolean;
  time_remaining?: number; // For helicopter extractions
}

/**
 * Mission/Quest progress (future Phase 4)
 */
export interface MissionProgress {
  mission_id: string;
  name: string;
  description: string;
  progress: number; // 0-100
  objectives: {
    description: string;
    completed: boolean;
  }[];
  rewards: {
    money: number;
    xp: number;
    items: string[];
  };
}
