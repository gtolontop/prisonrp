/**
 * Vehicle Inventory Store
 * Manages vehicle trunk inventory state
 */

import { create } from 'zustand';
import type { LootContainer } from '@/types/inventory';

interface VehicleStoreState {
  vehicle: LootContainer | null;
  setVehicle: (vehicle: LootContainer | null) => void;
  updateVehicle: (vehicle: LootContainer) => void;
  closeVehicle: () => void;
}

export const useVehicleStore = create<VehicleStoreState>((set) => ({
  vehicle: null,

  setVehicle: (vehicle) => set({ vehicle }),

  updateVehicle: (vehicle) => set({ vehicle }),

  closeVehicle: () => set({ vehicle: null }),
}));
