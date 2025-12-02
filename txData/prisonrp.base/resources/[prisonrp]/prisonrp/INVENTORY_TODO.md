# 📋 THE LAST COLONY - INVENTORY SYSTEM TODO

**Complete Roadmap for Custom Grid Inventory System**

---

## 🎯 PROJECT OVERVIEW

### Vision
Build a **Tarkov/Arena Breakout Infinite-style grid inventory** system for a 700-player extraction shooter FiveM server.

### Core Pillars
1. **Grid Inventory** - Tarkov-like drag & drop with rotation
2. **Immersive Audio 3D** - Positional sounds
3. **Realistic Combat** - Hit detection by body zone, armor, ammo types
4. **Varied Zombies** - 5+ types with unique AI

### Stack
- **Backend**: Lua (ox_core, oxmysql)
- **Frontend**: React + TypeScript + Vite + Tailwind + Zustand
- **Audio**: pma-voice (player voice) + custom system (world sounds)
- **Database**: MariaDB

---

## 📂 PROJECT STRUCTURE

```
prisonrp-resource/
├─ fxmanifest.lua         ✅ DONE
├─ client/                ⏳ TO DO
├─ server/                ⏳ TO DO
├─ shared/
│  ├─ config.lua          ✅ DONE
│  ├─ items.lua           ✅ DONE
│  ├─ constants.lua       ✅ DONE
│  └─ utils.lua           ✅ DONE
├─ web/
│  ├─ src/
│  │  ├─ App.tsx          ✅ DONE
│  │  ├─ components/      ⏳ TO DO
│  │  ├─ views/           ⏳ TO DO (placeholders done)
│  │  ├─ stores/          ✅ DONE (basic stores)
│  │  ├─ hooks/           ⏳ TO DO
│  │  ├─ utils/           ⏳ TO DO
│  │  └─ types/           ⏳ TO DO
│  └─ package.json        ✅ DONE
└─ sql/
   └─ schema.sql          ✅ DONE
```

---

## 📅 DEVELOPMENT PHASES

### ✅ PHASE 0: ARCHITECTURE & SETUP (COMPLETED)

- [x] Create folder structure
- [x] fxmanifest.lua (remove ox_inventory dependency)
- [x] package.json + Vite + TypeScript + Tailwind
- [x] Complete SQL schema
- [x] shared/items.lua (test items with compatibility)
- [x] shared/config.lua
- [x] shared/constants.lua
- [x] shared/utils.lua
- [x] DevTools sidebar (test UIs in dev mode)
- [x] Zustand stores (ui, inventory, player)
- [x] Placeholder views

---

## 🚀 PHASE 1: CORE INVENTORY SYSTEM (PRIORITY)

### 1.1 TypeScript Types & Interfaces

**Files to create:**
- [ ] `web/src/types/inventory.ts`
- [ ] `web/src/types/items.ts`
- [ ] `web/src/types/equipment.ts`
- [ ] `web/src/types/player.ts`
- [ ] `web/src/types/nui.ts`

**What to include:**
```typescript
// Example: inventory.ts
export interface InventoryItem {
  id: string;
  item_id: string;
  quantity: number;
  x?: number;
  y?: number;
  rotation: 0 | 1 | 2 | 3;  // 0°, 90°, 180°, 270°
  slot_type: 'grid' | 'pocket' | 'rig';
  slot_index?: number;
  metadata?: ItemMetadata;
}

export interface ItemMetadata {
  durability?: number;
  max_durability?: number;
  loaded_ammo?: Array<{type: string; count: number}>;
  attachments?: Record<string, string | null>;
  [key: string]: any;
}

export interface InventoryGrid {
  width: number;
  height: number;
  items: InventoryItem[];
}

// etc.
```

---

### 1.2 NUI Communication Layer (Lua ↔ React)

**Files to create:**

**Client-side (Lua):**
- [ ] `client/modules/nui/callbacks.lua`
  - Register all callbacks from React
  - Forward to server for validation

**React-side (TypeScript):**
- [ ] `web/src/utils/nui.ts`
  ```typescript
  export async function fetchNUI<T = any>(event: string, data?: any): Promise<T> {
    const response = await fetch(`https://prisonrp/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await response.json();
  }
  ```

**Events to implement:**

| Event Name | Direction | Purpose |
|------------|-----------|---------|
| `openInventory` | Lua → React | Open inventory UI |
| `closeInventory` | Lua → React | Close inventory UI |
| `updateInventory` | Lua → React | Sync inventory data |
| `moveItem` | React → Lua | Player drags item |
| `rotateItem` | React → Lua | Player presses R |
| `dropItem` | React → Lua | Player drops item |
| `useItem` | React → Lua | Player uses consumable |
| `equipItem` | React → Lua | Equip to slot |
| `unequipItem` | React → Lua | Unequip from slot |

---

### 1.3 Grid System (Core Logic)

**Files to create:**
- [ ] `web/src/utils/grid.ts`

**Functions needed:**
```typescript
// Check if item can fit at position
export function canItemFitAt(
  item: Item,
  x: number,
  y: number,
  gridWidth: number,
  gridHeight: number,
  existingItems: InventoryItem[],
  rotation: number
): boolean;

// Find first free slot for item
export function findFreeSlot(
  item: Item,
  gridWidth: number,
  gridHeight: number,
  existingItems: InventoryItem[],
  rotation?: number
): { x: number; y: number; rotation: number } | null;

// Check collision between two items
export function itemsCollide(
  x1: number, y1: number, w1: number, h1: number,
  x2: number, y2: number, w2: number, h2: number
): boolean;

// Get item dimensions after rotation
export function getRotatedDimensions(
  width: number,
  height: number,
  rotation: number
): { width: number; height: number };

// Auto-organize storage by category
export function organizeItems(
  items: InventoryItem[],
  gridWidth: number,
  gridHeight: number
): InventoryItem[];
```

**Server-side validation:**
- [ ] `server/modules/inventory/grid.lua`
  - Mirror all grid logic in Lua
  - Validate every move server-side

---

### 1.4 Drag & Drop System

**Files to create:**
- [ ] `web/src/hooks/useDragDrop.ts`
- [ ] `web/src/components/Inventory/DragDropProvider.tsx`

**Features:**
- Smooth drag with ghost preview
- Snap to grid
- Rotation with R key during drag
- Auto-swap if target occupied
- Highlight valid/invalid drop zones
- Cancel with ESC

**Libraries:**
- Use `react-draggable` OR implement custom with mouse events
- Consider `framer-motion` for smooth animations

---

### 1.5 Inventory Components

**Components to create:**

#### A. GridInventory
- [ ] `web/src/components/Inventory/GridInventory.tsx`
  - Renders grid background
  - Renders all items
  - Handles drag & drop
  - Shows weight bar
  - Organize button (for storage only)

#### B. GridSlot
- [ ] `web/src/components/Inventory/GridSlot.tsx`
  - Individual cell (1x1)
  - Highlight on hover if compatible item being dragged
  - Click handlers

#### C. ItemCard
- [ ] `web/src/components/Inventory/ItemCard.tsx`
  - Visual representation of item in grid
  - Shows icon, quantity, durability bar
  - Rarity border color
  - Rotation applied via CSS transform

#### D. ItemTooltip
- [ ] `web/src/components/Inventory/ItemTooltip.tsx`
  - Shows on hover
  - Item name, description, stats
  - Weight, value
  - Compatible weapons/magazines/ammo (highlight system)

#### E. ItemDetail3D
- [ ] `web/src/components/Inventory/ItemDetail3D.tsx`
  - Modal that opens on right-click → "Inspect"
  - 3D model viewer (Three.js via @react-three/fiber)
  - Rotatable with mouse drag
  - Show metadata (attachments, ammo, etc.)

#### F. SearchOverlay
- [ ] `web/src/components/Inventory/SearchOverlay.tsx`
  - When opening corpse/container
  - Progressively reveals items (1 per 0.5s)
  - Animated

#### G. Container Modal
- [ ] `web/src/components/Inventory/Container.tsx`
  - Opens when right-click backpack → "Open"
  - Shows backpack inventory in modal
  - Can drag items in/out
  - "Roll Up" button if empty

---

### 1.6 Pockets & Rig Slots

**Special slot types:**

#### A. Pockets
- Always visible (no equipment needed)
- 5 individual 1x1 slots
- Only accepts 1x1 items
- Component: `web/src/components/Inventory/PocketsDisplay.tsx`

#### B. Rig Slots
- Displayed when rig equipped
- **Custom slot sizes** (not a standard grid)
- Example: Tactical Rig has:
  - 4 slots (1x2 each) for magazines
  - 2 slots (1x1 each) for grenades
- Component: `web/src/components/Inventory/RigSlots.tsx`

**Data structure:**
```typescript
interface RigSlotDefinition {
  type: 'fixed';
  w: number;
  h: number;
  index: number;
}

// From items.lua:
rig_tactical = {
  rig_slots: [
    {type: "fixed", w: 1, h: 2, index: 0},
    {type: "fixed", w: 1, h: 2, index: 1},
    {type: "fixed", w: 1, h: 2, index: 2},
    {type: "fixed", w: 1, h: 2, index: 3},
    {type: "fixed", w: 1, h: 1, index: 4},
    {type: "fixed", w: 1, h: 1, index: 5}
  ]
}
```

---

### 1.7 Equipment Slots

**Components:**
- [ ] `web/src/components/Equipment/EquipmentSlots.tsx`
- [ ] `web/src/components/Equipment/WeaponSlots.tsx`
- [ ] `web/src/components/Equipment/Player3D.tsx` (3D character model)

**Slots:**
- Helmet
- Armor (can be blocked by armored rig)
- Rig
- Backpack
- Primary Weapon
- Secondary Weapon
- Melee Weapon
- Pistol
- Gas Mask

**Logic:**
- Drag item from inventory → equipment slot = equip
- Drag from slot → inventory = unequip
- Validate compatibility:
  - Armored rig blocks armor slot
  - Full-face helmet blocks gas mask
  - etc.

**Server validation:**
- [ ] `server/modules/inventory/equipment.lua`

---

### 1.8 Compatibility Highlight System

**Feature:** When hovering over an item, highlight compatible items in green.

**Example:**
- Hover AK-47 magazine → Highlight AK-47 (weapon) + 7.62x39 ammo (green)
- Hover 7.62x39 ammo → Highlight AK magazines + AK weapons (green)

**Implementation:**
```typescript
// In ItemCard.tsx
const handleMouseEnter = () => {
  const compatible = getCompatibleItems(item.item_id);
  inventoryStore.setHighlightedItems(compatible);
};

const handleMouseLeave = () => {
  inventoryStore.clearHighlights();
};
```

**Add to inventoryStore:**
```typescript
highlightedItems: string[];  // Array of item_ids to highlight
setHighlightedItems: (ids: string[]) => void;
clearHighlights: () => void;
```

---

### 1.9 Weight System

**Display:**
- Bar at bottom of inventory: `15.5 / 100 kg`
- Color:
  - Green: < 80%
  - Yellow: 80-100%
  - Red: > 100% (over-encumbered)

**Effects (client-side):**
- 80-100%: Slight slowdown
- 100-120%: Heavy slowdown, stamina drains faster
- >120%: Can barely move

**Calculation:**
```typescript
export function calculateTotalWeight(items: InventoryItem[]): number {
  return items.reduce((total, item) => {
    const itemData = getItem(item.item_id);
    return total + (itemData.weight * item.quantity);
  }, 0);
}
```

---

### 1.10 Server-Side Inventory Logic

**Files to create:**

#### A. Inventory Core
- [ ] `server/modules/inventory/main.lua`
  - Load/save inventory from DB
  - Add/remove items
  - Move items (with validation)

#### B. Validation
- [ ] `server/modules/inventory/validation.lua`
  ```lua
  function ValidateMove(playerId, itemId, fromSlot, toSlot)
    -- Check player owns item
    -- Check distance (anti-cheat)
    -- Check grid space available
    -- Check weight limit
    -- Return success/failure
  end
  ```

#### C. Equipment
- [ ] `server/modules/inventory/equipment.lua`
  - Equip/unequip validation
  - Apply stat bonuses (armor value, etc.)
  - Block slots if needed (armored rig)

#### D. Loot
- [ ] `server/modules/inventory/loot.lua`
  - Open container (corpse, crate, etc.)
  - Transfer items
  - Multi-player loot support

---

### 1.11 Database Integration

**Queries needed:**

#### Load Inventory
```lua
local inventory = MySQL.query.await('SELECT * FROM inventory WHERE character_id = ?', {charId})
local items = MySQL.query.await('SELECT * FROM inventory_items WHERE inventory_id = ?', {inventory.inventory_id})
```

#### Save Item Move
```lua
MySQL.update.await('UPDATE inventory_items SET position_x = ?, position_y = ?, rotation = ? WHERE id = ?', {
  newX, newY, newRotation, itemId
})
```

#### Save Equipment
```lua
MySQL.update.await('UPDATE equipment SET helmet = ?, armor = ?, rig = ?, backpack = ? WHERE character_id = ?', {
  json.encode(helmetData), json.encode(armorData), json.encode(rigData), json.encode(backpackData), charId
})
```

---

## 🎨 PHASE 2: UI/UX POLISH

### 2.1 Visual Design

**Tasks:**
- [ ] Design grid cells (border, hover states)
- [ ] Item card design (icon, rarity border, durability bar)
- [ ] Tooltip design (rich info display)
- [ ] Weight bar design
- [ ] Equipment slots design
- [ ] Modal designs (3D viewer, container)

**Colors (from Tailwind config):**
- Background: `#0a0f1a` (dark-900)
- Borders: `#374151` (dark-border)
- Rarity colors: Use `Constants.RarityColors`

---

### 2.2 Animations

**Using Framer Motion:**

- [ ] Smooth drag & drop
- [ ] Item rotation animation (R key)
- [ ] Fade in/out for modals
- [ ] Slide in for tooltips
- [ ] Pulse effect for highlighted compatible items
- [ ] Search reveal animation (items appear one by one)

---

### 2.3 Accessibility

- [ ] Keyboard shortcuts:
  - `I` = Toggle inventory
  - `R` = Rotate item while dragging
  - `ESC` = Close inventory/modals
  - `Ctrl+Click` = Quick move to storage
  - `Shift+Click` = Split stack
- [ ] Screen reader support (aria labels)
- [ ] Focus management (tab navigation)

---

## 💪 PHASE 3: BODY HEALTH SYSTEM

### 3.1 Components

- [ ] `web/src/components/BodyHealth/BodyHealthDisplay.tsx`
  - Human body silhouette
  - Color-coded zones (green/yellow/red)
  - Click zone to see details
  - Shows bleeding/fracture icons
  - **Reusable** in both Inventory view AND HUD

- [ ] `web/src/components/BodyHealth/HitZones.tsx`
  - SVG overlay for zones

- [ ] `web/src/components/BodyHealth/EffectsList.tsx`
  - List of active effects (bleeding, fracture, pain)

### 3.2 Server Logic

- [ ] `server/modules/combat/damage.lua`
  ```lua
  function ApplyDamage(victimId, attackerId, weapon, bone, distance)
    local zone = GetZoneFromBone(bone)
    local damage = CalculateDamage(weapon, zone, GetArmorValue(victimId, zone))

    -- Apply damage to zone
    local newHP = math.max(0, GetZoneHP(victimId, zone) - damage)
    SetZoneHP(victimId, zone, newHP)

    -- Check for effects
    if newHP < 50 then
      ApplyBleeding(victimId, zone)
    end

    if damage > 70 then
      ApplyFracture(victimId, zone)
    end

    -- Update client
    TriggerClientEvent('bodyhealth:update', victimId, GetBodyHealth(victimId))
  end
  ```

- [ ] `server/modules/combat/effects.lua`
  - Bleeding tick damage
  - Fracture penalties
  - Pain effects

### 3.3 Medical Items Usage

- [ ] `client/modules/combat/medic.lua`
  ```lua
  function UseMedicalItem(itemId, targetZone)
    local item = Items[itemId]

    -- Animation
    PlayAnim('anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01', item.use_time * 1000)

    -- Progress bar
    lib.progressBar({
      duration = item.use_time * 1000,
      label = 'Using ' .. item.name,
      useWhileDead = false,
      canCancel = true
    })

    -- Apply effects server-side
    TriggerServerEvent('medic:useItem', itemId, targetZone)
  end
  ```

---

## 🎯 PHASE 4: LOOT SYSTEM

### 4.1 Loot Containers (World Spawns)

**Server:**
- [ ] `server/modules/inventory/containers.lua`
  - Spawn containers at defined positions
  - Generate loot from loot tables
  - Track last looted time
  - Respawn after cooldown (only if no players nearby)

**Client:**
- [ ] `client/modules/inventory/loot.lua`
  - Detect nearby containers (3m range)
  - Show "Press F to Search" prompt
  - Open LootView (dual grid: your inv + container inv)

### 4.2 Corpse Looting

**Server:**
- [ ] `server/modules/death/corpse.lua`
  - On player death, create corpse entity
  - Store all inventory/equipment in `corpses` table
  - Spawn corpse at death position
  - Despawn after 10 minutes OR when EMS arrives

**Client:**
- [ ] Show "Press F to Search Body" on corpse
- Open LootView with search animation (progressive reveal)

### 4.3 Search System

**Feature:** Items in pockets/rig are hidden until searched.

**Logic:**
```typescript
const [searchedItems, setSearchedItems] = useState<string[]>([]);

useEffect(() => {
  if (!isSearching) return;

  const interval = setInterval(() => {
    const nextItem = hiddenItems[searchedItems.length];
    if (nextItem) {
      setSearchedItems([...searchedItems, nextItem]);
    } else {
      setIsSearching(false);
    }
  }, 500);  // Reveal 1 item every 0.5s

  return () => clearInterval(interval);
}, [isSearching, searchedItems]);
```

### 4.4 Multi-Player Looting

**Server logic:**
- Multiple players can open same container simultaneously
- First to take an item gets it (optimistic locking)
- Update all connected clients when item taken

```lua
local activeLoots = {}  -- [containerId] = {player1, player2, ...}

function OnLootItem(playerId, containerId, itemId)
  -- Check item still exists
  local container = GetContainer(containerId)
  if not container or not container:HasItem(itemId) then
    return false, "Item no longer available"
  end

  -- Remove item
  container:RemoveItem(itemId)

  -- Notify all looters
  for _, looterId in ipairs(activeLoots[containerId]) do
    TriggerClientEvent('loot:updateContainer', looterId, container:GetItems())
  end

  return true
end
```

---

## 💼 PHASE 5: STORAGE SYSTEM

### 5.1 Personal Storage

**Components:**
- [ ] `web/src/views/StorageView.tsx`
  - Dual grid: left = your inventory, right = storage
  - Drag items between grids
  - **Organize button** (auto-sort by category)
  - Upgrade button (if max capacity reached)

**Server:**
- [ ] `server/modules/storage/personal.lua`
  - Load storage from DB
  - Save storage on close
  - Handle upgrades (cost money, add slots)

### 5.2 Guild Storage

**Same as personal but:**
- Shared between guild members
- Size depends on guild level
- Rank-based permissions (who can deposit/withdraw)

**Components:**
- [ ] `web/src/views/GuildStorageView.tsx`
- [ ] `web/src/components/Storage/PermissionModal.tsx`

**Server:**
- [ ] `server/modules/storage/guild.lua`
  - Check permissions before allowing access
  - Log all transactions (who took what)

### 5.3 Organize Function

**Algorithm:**
```typescript
export function organizeItems(
  items: InventoryItem[],
  gridWidth: number,
  gridHeight: number
): InventoryItem[] {
  // Group by category
  const grouped = groupByCategory(items);

  // Sort each group (rarity desc, name asc)
  const sorted = Object.entries(grouped).flatMap(([category, items]) =>
    items.sort((a, b) => compareRarity(a, b) || compareName(a, b))
  );

  // Place items top-left to bottom-right
  let currentX = 0;
  let currentY = 0;
  let rowHeight = 0;

  return sorted.map(item => {
    const { w, h } = getItemSize(item);

    // Move to next row if doesn't fit
    if (currentX + w > gridWidth) {
      currentX = 0;
      currentY += rowHeight;
      rowHeight = 0;
    }

    const positioned = {
      ...item,
      x: currentX,
      y: currentY,
      rotation: 0
    };

    currentX += w;
    rowHeight = Math.max(rowHeight, h);

    return positioned;
  });
}
```

---

## 🛒 PHASE 6: MARKET SYSTEM

### 6.1 NPC Vendor

**Components:**
- [ ] `web/src/components/Market/VendorNPC.tsx`
  - Left: Vendor inventory (items for sale)
  - Right: Your inventory
  - Drag item to vendor = sell
  - Drag item from vendor = buy
  - Show prices

**Server:**
- [ ] `server/modules/market/vendor.lua`
  - Fixed inventory (refreshes daily)
  - Buy/sell price calculations
  - Transaction validation (player has money, item exists, etc.)

### 6.2 Player Marketplace

**Components:**
- [ ] `web/src/components/Market/Marketplace.tsx`
  - Browse listings (filter by category, rarity, price)
  - List item for sale (set price, duration)
  - Buy listing
  - View your active listings

**Server:**
- [ ] `server/modules/market/marketplace.lua`
  - Create listing (lock item until sold/expired)
  - Buy listing (transfer item, pay seller, collect tax)
  - Cancel listing (return item)
  - Expire old listings (cronjob)

**Tax system:**
- 5% tax on all sales
- Goes to `server_economy` table
- Used for events, new player rewards, etc.

### 6.3 NPC AI Marketplace

**Feature:** NPCs also buy/sell on marketplace (make it feel alive)

**Server:**
- [ ] `server/modules/npc/marketplace_bot.lua`
  - Every 10 minutes, NPCs check marketplace
  - 30% chance to buy a listing (if price < base_price * 1.2)
  - NPCs also list items for sale occasionally

---

## 💀 PHASE 7: DEATH & COMBAT HISTORY

### 7.1 Death Screen

**Components:**
- [ ] `web/src/views/DeathView.tsx`
  - "Operation Failed" screen
  - Show how you died (killer, weapon, distance, hitzone)
  - "Continue" button → Combat History

### 7.2 Combat History

**Components:**
- [ ] `web/src/components/Death/CombatHistory.tsx`
  - Timeline of session:
    - Where you went (map with path traced)
    - Kills (who, weapon, distance)
    - Damage dealt/received
    - Loot collected
    - Containers opened

**Server:**
- [ ] `server/modules/death/history.lua`
  - Query `combat_logs` table for session
  - Aggregate data into summary
  - Send to client

**Movement tracking:**
- [ ] `client/modules/combat/tracking.lua`
  ```lua
  local movementBuffer = {}

  CreateThread(function()
    while true do
      local ped = PlayerPedId()
      local coords = GetEntityCoords(ped)

      table.insert(movementBuffer, {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        timestamp = GetGameTimer()
      })

      -- Send batch to server every 30 seconds
      if #movementBuffer >= 60 then  -- 5 sec * 60 = 5 minutes of data
        TriggerServerEvent('combat:logMovement', movementBuffer)
        movementBuffer = {}
      end

      Wait(5000)  -- Log every 5 seconds
    end
  end)
  ```

### 7.3 EMS System

**Server:**
- [ ] `server/modules/death/ems.lua`
  - On death, wait 30 seconds
  - Spawn helicopter entity
  - Fly to corpse location
  - Play animation: EMS drops items on ground
  - Despawn corpse
  - Fly away

**Client:**
- [ ] Spectate EMS arrival (cinematic camera)
- [ ] Show items being dropped

---

## 📊 PHASE 8: LEADERBOARDS & SESSIONS

### 8.1 Session Tracking

**Server:**
- [ ] `server/modules/logging/session.lua`
  - Create session on spawn
  - Update stats during session (kills, loot value, etc.)
  - End session on extraction/death
  - Update `leaderboard` table with new records

### 8.2 Leaderboard UI

**Components:**
- [ ] `web/src/views/LeaderboardView.tsx`
  - Tabs for each category:
    - Total Kills
    - K/D Ratio
    - Extractions
    - Best Single Extraction Value
    - Longest Survival
    - Zombie Kills
    - etc.
  - Show top 100 per category

**Server:**
- [ ] `server/modules/leaderboard/main.lua`
  - Update leaderboard every 5 minutes
  - Provide API for client to fetch rankings

---

## 🎮 PHASE 9: HUD SYSTEM

### 9.1 HUD Components

**Components to create:**
- [ ] `web/src/components/HUD/WeightBar.tsx`
- [ ] `web/src/components/HUD/StaminaBar.tsx`
- [ ] `web/src/components/HUD/ConcentrationBar.tsx`
- [ ] `web/src/components/HUD/Compass.tsx` (3D top-center)
- [ ] `web/src/components/HUD/QuickHints.tsx` (bottom-right, shows "Press V to use", etc.)
- [ ] `web/src/components/HUD/EffectsIcons.tsx` (bleeding, fracture icons)
- [ ] `web/src/components/HUD/BodyHealthMini.tsx` (small body silhouette, always visible)

### 9.2 Quick Use System

**Feature:** If you have a medical item in pockets/rig, press V to use it

**Client logic:**
```lua
RegisterKeyMapping('quickuse', 'Quick Use Medical Item', 'keyboard', 'V')

RegisterCommand('quickuse', function()
  local item = GetFirstMedicalItemInQuickSlots()
  if item then
    UseMedicalItem(item.item_id)
  else
    lib.notify({type = 'error', description = 'No medical items in quick access'})
  end
end)
```

---

## 🛡️ PHASE 10: ANTI-CHEAT & SECURITY

### 10.1 Server Validation

**Every action must be validated:**

- [ ] `server/modules/inventory/validation.lua`
  ```lua
  function ValidateInventoryAction(playerId, action, data)
    -- Check player distance to container
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local containerCoords = GetContainerCoords(data.containerId)

    if #(playerCoords - containerCoords) > 5.0 then
      LogSuspiciousAction(playerId, 'distance_cheat', {
        action = action,
        distance = #(playerCoords - containerCoords)
      })
      return false, "Too far away"
    end

    -- Check player owns item
    if not PlayerOwnsItem(playerId, data.itemId) then
      BanPlayer(playerId, "Item duplication attempt")
      return false, "Invalid item"
    end

    -- Check slot validity
    if not IsValidSlot(data.toSlot) then
      return false, "Invalid slot"
    end

    return true
  end
  ```

### 10.2 Rate Limiting

- [ ] `server/modules/logging/ratelimit.lua`
  ```lua
  local actionCounts = {}  -- [playerId] = {[action] = count}

  function CheckRateLimit(playerId, action, maxPerSecond)
    actionCounts[playerId] = actionCounts[playerId] or {}
    actionCounts[playerId][action] = (actionCounts[playerId][action] or 0) + 1

    if actionCounts[playerId][action] > maxPerSecond then
      LogSuspiciousAction(playerId, 'rate_limit_exceeded', {action = action})
      return false
    end

    return true
  end

  -- Reset every second
  CreateThread(function()
    while true do
      Wait(1000)
      actionCounts = {}
    end
  end)
  ```

### 10.3 Logging

- [ ] Log **everything** to `anticheat_logs` table
- [ ] Create admin panel to review flagged accounts
- [ ] Auto-ban on 10+ flags (configurable)

---

## 🧪 PHASE 11: TESTING & DEBUGGING

### 11.1 Unit Tests (Optional but Recommended)

**Frontend:**
- [ ] Test grid logic (canItemFitAt, findFreeSlot, etc.)
- [ ] Test drag & drop
- [ ] Test compatibility highlighting

**Backend:**
- [ ] Test inventory validation
- [ ] Test equipment compatibility
- [ ] Test loot generation

### 11.2 Integration Tests

- [ ] Test full flow: spawn → loot → equip → extract
- [ ] Test multi-player loot
- [ ] Test combat damage → body health → death → EMS
- [ ] Test marketplace transactions

### 11.3 Performance Tests

- [ ] Simulate 700 players
- [ ] Monitor server TPS
- [ ] Check database query performance
- [ ] Profile client FPS with inventory open

### 11.4 Security Tests

- [ ] Attempt item duplication
- [ ] Attempt distance cheats
- [ ] Attempt inventory manipulation via NUI devtools
- [ ] Stress test rate limiter

---

## 🎨 PHASE 12: POLISH & OPTIMIZATION

### 12.1 UI Polish

- [ ] Add micro-interactions (hover effects, click feedback)
- [ ] Smooth animations everywhere
- [ ] Loading states (when opening container, etc.)
- [ ] Error messages (user-friendly)

### 12.2 Performance Optimization

**Client:**
- [ ] Memoize expensive calculations
- [ ] Use `React.memo` on components
- [ ] Virtualize long lists (marketplace, storage)
- [ ] Lazy load 3D models

**Server:**
- [ ] Cache frequently accessed data (items, player inventory)
- [ ] Batch database updates
- [ ] Use Redis for session data (if needed)

### 12.3 Code Cleanup

- [ ] Remove debug logs
- [ ] Add JSDoc comments
- [ ] Refactor duplicated code
- [ ] Type safety audit (fix all `any` types)

---

## 📋 ADDITIONAL FEATURES (Post-MVP)

### Crafting System
- [ ] UI to select recipe
- [ ] Check materials in inventory
- [ ] Craft item (animation, cooldown)
- [ ] Server validation

### Weapon Attachments System
- [ ] UI to modify weapon (drag scope onto weapon)
- [ ] Apply stat bonuses
- [ ] Save attachments in metadata

### Ammo/Magazine Management
- [ ] Drag ammo onto magazine to load
- [ ] FIFO queue (first in, first out)
- [ ] Drag magazine onto weapon to load
- [ ] Show ammo count in weapon tooltip

### Repair System
- [ ] Right-click item → "Repair"
- [ ] Cost money + materials
- [ ] Durability max decreases each repair

### Item Stacking Improvements
- [ ] Auto-stack when picking up
- [ ] Split stack with Shift+Click
- [ ] Merge stacks with Ctrl+Drag

### Quick Move
- [ ] Ctrl+Click to quick move to storage
- [ ] Alt+Click to quick equip

### Context Menu
- [ ] Right-click item for actions:
  - Use
  - Equip
  - Drop
  - Inspect (3D view)
  - Repair
  - Split Stack
  - Discard

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-Launch
- [ ] Run full test suite
- [ ] Security audit
- [ ] Performance benchmarks (700 players)
- [ ] Database backup & migration scripts
- [ ] Documentation for admins

### Launch Day
- [ ] Deploy to production server
- [ ] Monitor logs for errors
- [ ] Watch for exploits
- [ ] Gather player feedback

### Post-Launch
- [ ] Hotfix critical bugs
- [ ] Balance adjustments (loot tables, prices, etc.)
- [ ] Add telemetry (track most used items, etc.)

---

## 📚 RESOURCES & REFERENCES

### Documentation
- [FiveM Natives](https://docs.fivem.net/natives/)
- [ox_core Documentation](https://overextended.dev/ox_core)
- [ox_lib UI Documentation](https://overextended.dev/ox_lib)
- [React Documentation](https://react.dev)
- [Zustand Documentation](https://zustand-demo.pmnd.rs/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Three.js](https://threejs.org/)

### Inspiration
- **Escape from Tarkov** - Grid inventory system
- **Arena Breakout: Infinite** - Extraction mechanics
- **DayZ** - Survival elements

---

## ✅ COMPLETION CRITERIA

### MVP (Minimum Viable Product)
- [x] Architecture & setup
- [ ] Core inventory (grid, drag & drop, pockets, equipment)
- [ ] Loot system (containers, corpses)
- [ ] Storage (personal, guild)
- [ ] Basic combat (damage, body health)
- [ ] Death & respawn

### Full Release
- [ ] All features above +
- [ ] Market system
- [ ] Combat history
- [ ] Leaderboards
- [ ] HUD
- [ ] Anti-cheat
- [ ] Performance optimized for 700 players

---

## 📝 NOTES FOR DEVELOPER

### Development Order (Recommended)
1. **Start with core inventory grid** (most complex, foundational)
2. **Add drag & drop** (critical for UX)
3. **Implement equipment slots** (builds on grid system)
4. **Add loot system** (requires grid + equipment)
5. **Storage** (reuses loot dual-grid UI)
6. **Body health** (independent system, can be done in parallel)
7. **Market** (complex, do after core is stable)
8. **Death/combat history** (polish feature)
9. **HUD** (integrates everything)
10. **Anti-cheat** (ongoing throughout)

### Tips
- **Test frequently** - Don't build everything before testing
- **Use DevTools** - The sidebar we built is your friend
- **Mock data liberally** - Don't wait for server to test UI
- **Commit often** - Small, focused commits
- **Ask for feedback** - Show progress, iterate

### Common Pitfalls to Avoid
- **Trust client data** - ALWAYS validate server-side
- **Ignore performance** - Profile early, optimize often
- **Over-engineer** - Start simple, add complexity when needed
- **Forget edge cases** - What happens if player disconnects mid-loot?
- **Skip testing** - Bugs in inventory = frustrated players

---

## 🎉 FINAL WORDS

This is a **massive** project, but with this roadmap, you have a clear path forward.

**Estimated Timeline:**
- Phase 1 (Core Inventory): 2-3 weeks
- Phase 2-5 (Loot, Storage, Market): 2-3 weeks
- Phase 6-10 (Polish, Combat, Anti-cheat): 2-3 weeks
- **Total: 6-9 weeks for MVP**

Take it step by step, commit frequently, and you'll have an incredible inventory system that rivals AAA games.

**Let's build the best FiveM inventory ever made.** 🔥

---

*Last Updated: October 2024*
*Project: The Last Colony*
*Developer: teamr*
