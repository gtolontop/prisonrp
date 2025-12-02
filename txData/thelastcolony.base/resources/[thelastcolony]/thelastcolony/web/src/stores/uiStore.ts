import { create } from 'zustand';

type ViewName = 'inventory' | 'loot' | 'vehicle' | 'storage' | 'market' | 'hud' | 'death' | null;

interface UIStore {
  // Active view
  activeView: ViewName;
  setActiveView: (view: ViewName) => void;

  // Dev mode
  isDevMode: boolean;
  setDevMode: (enabled: boolean) => void;

  // Modals
  activeModal: string | null;
  openModal: (modalId: string) => void;
  closeModal: () => void;
}

export const useUIStore = create<UIStore>((set) => ({
  // Defaults
  activeView: null,
  isDevMode: typeof window !== 'undefined' && import.meta.env?.DEV === true,

  setActiveView: (view) => set({ activeView: view }),

  setDevMode: (enabled) => set({ isDevMode: enabled }),

  activeModal: null,
  openModal: (modalId) => set({ activeModal: modalId }),
  closeModal: () => set({ activeModal: null }),
}));
