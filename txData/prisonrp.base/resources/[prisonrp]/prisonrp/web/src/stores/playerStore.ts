import { create } from 'zustand';

interface BodyZone {
  zone: string;
  hp: number;
  maxHp: number;
  bleeding: boolean;
  fractured: boolean;
}

interface PlayerStore {
  // Character info
  characterId: number | null;
  name: string;

  // Body health
  bodyHealth: BodyZone[];

  // Stats
  stamina: number;
  maxStamina: number;
  concentration: number;
  maxConcentration: number;

  // Effects
  effects: Array<{ type: string; zone?: string; duration?: number }>;

  // Actions
  setPlayer: (data: Partial<PlayerStore>) => void;
  updateBodyHealth: (zone: string, hp: number) => void;
  addEffect: (effect: { type: string; zone?: string; duration?: number }) => void;
  removeEffect: (effectId: number) => void;

  // Mock data
  loadMockData: () => void;
}

export const usePlayerStore = create<PlayerStore>((set) => ({
  characterId: null,
  name: '',

  bodyHealth: [
    { zone: 'head', hp: 100, maxHp: 100, bleeding: false, fractured: false },
    { zone: 'torso', hp: 100, maxHp: 100, bleeding: false, fractured: false },
    { zone: 'left_arm', hp: 100, maxHp: 100, bleeding: false, fractured: false },
    { zone: 'right_arm', hp: 100, maxHp: 100, bleeding: false, fractured: false },
    { zone: 'left_leg', hp: 100, maxHp: 100, bleeding: false, fractured: false },
    { zone: 'right_leg', hp: 100, maxHp: 100, bleeding: false, fractured: false },
  ],

  stamina: 100,
  maxStamina: 100,
  concentration: 100,
  maxConcentration: 100,

  effects: [],

  setPlayer: (data) => set((state) => ({ ...state, ...data })),

  updateBodyHealth: (zone, hp) =>
    set((state) => ({
      bodyHealth: state.bodyHealth.map((z) =>
        z.zone === zone ? { ...z, hp } : z
      ),
    })),

  addEffect: (effect) =>
    set((state) => ({
      effects: [...state.effects, effect],
    })),

  removeEffect: (effectId) =>
    set((state) => ({
      effects: state.effects.filter((_, idx) => idx !== effectId),
    })),

  loadMockData: () => {
    console.log('[PlayerStore] Loading mock data');
    set({
      characterId: 1,
      name: 'John Survivor',
      bodyHealth: [
        { zone: 'head', hp: 100, maxHp: 100, bleeding: false, fractured: false },
        { zone: 'torso', hp: 75, maxHp: 100, bleeding: true, fractured: false },
        { zone: 'left_arm', hp: 100, maxHp: 100, bleeding: false, fractured: false },
        { zone: 'right_arm', hp: 50, maxHp: 100, bleeding: false, fractured: true },
        { zone: 'left_leg', hp: 100, maxHp: 100, bleeding: false, fractured: false },
        { zone: 'right_leg', hp: 80, maxHp: 100, bleeding: false, fractured: false },
      ],
      stamina: 65,
      concentration: 80,
      effects: [
        { type: 'bleeding', zone: 'torso' },
        { type: 'fracture', zone: 'right_arm' },
      ],
    });
  },
}));
