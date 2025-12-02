# 🔧 INVENTORY REFACTOR PLAN

## Problème actuel
- **50+ composants** qui font la même chose
- **Multiple handlers** pour chaque type de slot
- **CSS dupliqué** partout
- **Impossible à maintenir**

## Solution : Architecture Unifiée

### 1. UN SEUL Composant : `<Slot>`

```tsx
<Slot
  item={item}           // L'item (null si vide)
  location={location}   // Où il est: {type, position/index}
  size={{w, h}}        // Taille du slot
  onDrop={handleDrop}   // UN SEUL handler universel
/>
```

### 2. UN SEUL Handler

```tsx
const handleDrop = (item: Item, from: Location, to: Location) => {
  sendNUIEvent('moveItem', { item_id: item.id, from, to, rotation });
};
```

### 3. Composition Universelle

```tsx
// Backpack = Grille de slots
<Grid width={5} height={6}>
  {items.map(item => <Slot item={item} location={{type:'grid', pos}} />)}
</Grid>

// Rig = Grille de slots (MÊME composant!)
<Grid width={3} height={4}>
  {items.map(item => <Slot item={item} location={{type:'rig', pos}} />)}
</Grid>

// Loot = Grille de slots (encore pareil!)
<Grid width={10} height={10}>
  {items.map(item => <Slot item={item} location={{type:'loot', pos}} />)}
</Grid>

// Pockets = Liste de slots 1x1
{pockets.map((item, i) =>
  <Slot item={item} size={{1,1}} location={{type:'pocket', index:i}} />
)}

// Equipment = Liste de slots variables
{equipment.map((slot) =>
  <Slot
    item={slot.item}
    size={getEquipmentSize(slot)}
    location={{type:'equipment', slot:slot.name}}
  />
)}
```

### 4. Suppression de Fichiers

**À SUPPRIMER** :
- ❌ `Pockets.tsx` → Remplacer par `<Slot>` répété
- ❌ `EquipmentSlots.tsx` → Remplacer par `<Slot>` répété
- ❌ `RigSlots.tsx` → Remplacer par `<Grid>` + `<Slot>`
- ❌ `handlePocketDrop()` → Utiliser `handleDrop()`
- ❌ `handleEquipmentDrop()` → Utiliser `handleDrop()`
- ❌ `handleRigDrop()` → Utiliser `handleDrop()`
- ❌ `handleGridDrop()` → Utiliser `handleDrop()`

**À GARDER** :
- ✅ `Slot.tsx` (simplifié)
- ✅ `InventoryGrid.tsx` (wrapper pour grille)
- ✅ `ItemRenderer.tsx` (affichage item)

### 5. Migration Progressive

1. ✅ Créer `<Slot>` universel
2. ✅ Créer `handleDrop()` universel
3. Refactor `Pockets` → `<Slot>` × 5
4. Refactor `Equipment` → `<Slot>` × N
5. Refactor `Rig` → `<Grid>` + `<Slot>`
6. Refactor `Loot` → `<Grid>` + `<Slot>`
7. Supprimer anciens composants
8. Cleanup CSS

## Résultat Final

**Avant** : 2000+ lignes, 10+ composants, 5+ handlers
**Après** : 500 lignes, 3 composants, 1 handler

**Maintenance** : ×10 plus facile
**CSS** : Unifié dans `Slot.tsx`
**Bugs** : Divisés par 5
