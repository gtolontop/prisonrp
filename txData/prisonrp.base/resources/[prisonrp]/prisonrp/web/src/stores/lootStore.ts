/**
 * Loot Container Store
 * Manages active loot container state
 */

import { create } from 'zustand';
import type { LootContainer, ItemDefinition } from '@/types';

interface LootStore {
  // Active loot container
  container: LootContainer | null;

  // Item definitions (shared with inventory)
  itemDefinitions: Record<string, ItemDefinition>;

  // Search progress
  isSearching: boolean;
  searchProgress: number;

  // Actions
  setContainer: (container: LootContainer) => void;
  closeContainer: () => void;
  setItemDefinitions: (definitions: Record<string, ItemDefinition>) => void;
  setSearchProgress: (progress: number, isSearching: boolean) => void;
}

export const useLootStore = create<LootStore>((set) => ({
  container: null,
  itemDefinitions: {},
  isSearching: false,
  searchProgress: 0,

  setContainer: (container) => set({ container }),

  closeContainer: () => set({ container: null, isSearching: false, searchProgress: 0 }),

  setItemDefinitions: (definitions) => set({ itemDefinitions: definitions }),

  setSearchProgress: (progress, isSearching) =>
    set({ searchProgress: progress, isSearching }),
}));
