/**
 * NUI Communication Types
 * Event types for Lua <-> React communication
 */

import type { PlayerData } from './player';
import type { LootContainer } from './inventory';
import type { ItemDefinition } from './items';
import type { ExtractionPoint, DeathInfo } from './player';

/**
 * Events FROM Lua TO React
 */
export type LuaToReactEvent =
  | { type: 'openInventory'; data: OpenInventoryPayload }
  | { type: 'closeInventory' }
  | { type: 'updateInventory'; data: PlayerData }
  | { type: 'openLootContainer'; data: LootContainer }
  | { type: 'closeLootContainer' }
  | { type: 'updateLootContainer'; data: LootContainer }
  | { type: 'openVehicle'; data: LootContainer }
  | { type: 'closeVehicle' }
  | { type: 'updateVehicle'; data: LootContainer }
  | { type: 'openStorage'; data: StoragePayload }
  | { type: 'closeStorage' }
  | { type: 'showNotification'; data: NotificationPayload }
  | { type: 'updateHealth'; data: HealthUpdatePayload }
  | { type: 'updateWeight'; data: WeightUpdatePayload }
  | { type: 'showDeathScreen'; data: DeathInfo }
  | { type: 'hideDeathScreen' }
  | { type: 'updateExtractionPoints'; data: ExtractionPoint[] }
  | { type: 'startAction'; data: ActionPayload }
  | { type: 'cancelAction' }
  | { type: 'updateActionProgress'; data: { progress: number; time_remaining: number } };

/**
 * Events FROM React TO Lua
 */
export interface ReactToLuaEvents {
  // Inventory
  moveItem: MoveItemPayload;
  rotateItem: RotateItemPayload;
  splitStack: SplitStackPayload;
  splitStackPrompt: SplitStackPromptPayload;
  dropItem: DropItemPayload;
  useItem: UseItemPayload;
  equipItem: EquipItemPayload;
  unequipItem: UnequipItemPayload;
  unloadMagazine: UnloadMagazinePayload;
  discardItem: DiscardItemPayload;

  // Loot
  takeItemFromContainer: TakeItemPayload;
  transferItemToContainer: TransferItemPayload;
  moveItemInContainer: MoveItemInContainerPayload;
  takeAndEquipFromContainer: TakeAndEquipItemPayload;
  searchContainer: { container_id: string };
  closeContainer: { container_id: string };

  // Storage
  depositItem: TransferItemPayload;
  withdrawItem: TakeItemPayload;

  // Actions
  cancelAction: {};
  requestExtraction: { extraction_id: string };
  callHelicopter: { beacon_item_id: string };

  // Market (future)
  listItem: ListItemPayload;
  buyItem: BuyItemPayload;

  // UI
  closeUI: {};
  requestSync: {}; // Request full data sync
}

/**
 * Payload Types
 */

export interface OpenInventoryPayload {
  player_data: PlayerData;
  item_definitions: Record<string, ItemDefinition>; // item_id -> definition
}

export interface StoragePayload {
  type: 'personal' | 'guild';
  container: LootContainer;
}

export interface NotificationPayload {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number; // milliseconds
}

export interface HealthUpdatePayload {
  body_health: import('./equipment').BodyHealth[];
  overall_health: number;
  bleeding: boolean;
  fractures: string[];
}

export interface WeightUpdatePayload {
  current_weight: number;
  max_weight: number;
  overweight: boolean;
}

export interface ActionPayload {
  action: import('./player').PlayerAction;
  duration: number; // seconds
  cancelable: boolean;
}

export interface MoveItemPayload {
  item_id: string; // Instance ID
  from: {
    type: 'grid' | 'pocket' | 'equipment' | 'rig' | 'loot' | 'storage' | 'container' | 'backpack_storage';
    container_id?: string;
    position?: { x: number; y: number };
    slot_index?: number;
    slot_name?: string; // For equipment slots
  };
  to: {
    type: 'grid' | 'pocket' | 'equipment' | 'rig' | 'loot' | 'storage' | 'container' | 'backpack_storage';
    container_id?: string;
    position?: { x: number; y: number };
    slot_index?: number;
    slot_name?: string; // For equipment slots
  };
  rotation: 0 | 1 | 2 | 3;
}

export interface RotateItemPayload {
  item_id: string;
  new_rotation: 0 | 1 | 2 | 3;
}

export interface SplitStackPayload {
  item_id: string;
  split_amount: number;
  target_position: { x: number; y: number };
}

export interface DropItemPayload {
  item_id: string;
  quantity?: number; // For stackable items
}

export interface UseItemPayload {
  item_id: string;
  target_zone?: string; // For medical items (e.g., "left_arm")
}

export interface EquipItemPayload {
  item_id: string;
  slot: import('./equipment').EquipmentSlotName;
}

export interface UnequipItemPayload {
  item_id: string; // Instance ID of the equipped item
}

export interface UnloadMagazinePayload {
  item_id: string; // Instance ID of the weapon
}

export interface SplitStackPromptPayload {
  item_id: string; // Instance ID
  quantity: number; // Current stack size
}

export interface DiscardItemPayload {
  item_id: string;
  confirm: boolean; // Require confirmation for valuable items
}

export interface TakeItemPayload {
  container_id: string;
  item_id: string;
  to_position?: { x: number; y: number };
  to_pocket?: number; // 0-4
}

export interface TransferItemPayload {
  item_id: string;
  container_id: string;
  to_position?: { x: number; y: number };
}

export interface MoveItemInContainerPayload {
  container_id: string;
  item_id: string;
  from_position: { x: number; y: number };
  to_position: { x: number; y: number };
}

export interface TakeAndEquipItemPayload {
  container_id: string;
  item_id: string;
  slot: import('./equipment').EquipmentSlotName;
}

export interface ListItemPayload {
  item_id: string;
  price: number;
  duration_hours: number;
}

export interface BuyItemPayload {
  listing_id: string;
}

/**
 * NUI Callback Response
 */
export interface NUIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * Type helper for NUI callbacks
 */
export type NUICallback<T extends keyof ReactToLuaEvents> = (
  data: ReactToLuaEvents[T]
) => Promise<NUIResponse>;
