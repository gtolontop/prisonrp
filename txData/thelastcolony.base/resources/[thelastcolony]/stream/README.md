# 📦 Custom Assets - Stream Folder

This folder contains all custom 3D models, textures, and assets for The Last Colony.

## 📁 Folder Structure

```
stream/
├── props/          # Custom props (loot items, containers, world objects)
├── weapons/        # Custom weapon models
├── vehicles/       # Custom vehicle models
├── peds/           # Custom zombie/NPC models
└── README.md
```

## 🎨 How to Add Custom Props

### 1. Prepare Your Files
You need these files for each custom prop:
- `.ydr` - 3D model file
- `.ytd` - Texture dictionary (optional, if model has custom textures)
- `.ytyp` - Type definition (optional, for advanced props)

### 2. Place Files in the Correct Folder
- **Loot items** → `stream/props/`
- **Weapons** → `stream/weapons/`
- **Vehicles** → `stream/vehicles/`
- **Zombies/NPCs** → `stream/peds/`

### 3. Get the Model Hash
After placing your `.ydr` file, you need the hash name.

**Example**: If your file is `backpack_tactical.ydr`, the hash is `backpack_tactical`

### 4. Add to `shared/items.lua`

```lua
Items["tactical_backpack"] = {
    name = "Tactical Backpack",
    type = "container",
    weight = 2.5,
    max_stack = 1,
    world_prop = `backpack_tactical`, -- Your custom model hash
    grid_size = {width = 2, height = 3},
    -- ... other properties
}
```

### 5. Test In-Game
1. Restart the resource: `/restart thelastcolony`
2. Drop the item from your inventory
3. The custom model should appear on the ground with an outline

## 📝 Naming Conventions

**Use lowercase with underscores**:
- ✅ `medkit_advanced.ydr`
- ✅ `weapon_ak47_custom.ydr`
- ❌ `MedKit-Advanced.ydr`
- ❌ `WeaponAK47Custom.ydr`

## 🔍 Troubleshooting

### Model Not Appearing (Pink/Purple Box)
- **Cause**: Model hash incorrect or file not loaded
- **Fix**: Check that the `.ydr` filename matches the hash in `world_prop`

### Model Is Black/No Textures
- **Cause**: Missing `.ytd` texture file
- **Fix**: Place the `.ytd` file in the same folder as the `.ydr`

### Model Spawns Underground/In Air
- **Cause**: Model origin point is wrong
- **Fix**: Re-export the model with correct pivot point at bottom-center

### Model Spawns Huge/Tiny
- **Cause**: Model scale in 3D software was wrong
- **Fix**: Re-export with correct scale (1 unit = 1 meter in GTA V)

## 🎯 Recommended Props to Add

### High Priority
- [ ] Tactical backpacks (small, medium, large)
- [ ] Medical kits (bandage, medkit, trauma kit)
- [ ] Weapons (AK-47, M4A1, pistols)
- [ ] Ammo boxes
- [ ] Food/Water items
- [ ] Armor vests (levels 1-5)

### Medium Priority
- [ ] Loot containers (military crates, toolboxes)
- [ ] Crafting materials
- [ ] Tools (hammer, wrench, etc.)

### Low Priority
- [ ] Decorative items
- [ ] Quest items

## 📚 Resources

- **Model Conversion Tools**: OpenIV, CodeWalker
- **Texture Editing**: Photoshop, GIMP
- **3D Modeling**: Blender, 3DS Max, Maya

---

**Last Updated**: 2025-10-23
**Maintained By**: The Last Colony Dev Team
