--[[
    Equipment Visuals Module
    Handles visual sync for equipped items (weapons, armor, backpacks)
]]

local ox = lib
local Items = require 'shared.items'

-- ============================================
-- STATE
-- ============================================

local currentEquipment = {
    head = nil,
    armor = nil,
    rig = nil,
    backpack = nil,
    holster = nil,
    melee = nil,
    primary = nil,
    secondary = nil
}

local weaponProps = {} -- {primary = propEntity, secondary = propEntity, ...}
local armorComponents = {} -- {armor = componentId, ...}

-- ============================================
-- WEAPON VISUALS
-- ============================================

--- Attach weapon prop to ped
--- @param ped number Ped ID
--- @param weaponModel hash Weapon model hash
--- @param slot string Equipment slot (primary, secondary, holster, melee)
local function AttachWeaponProp(ped, weaponModel, slot)
    -- Load weapon model
    RequestModel(weaponModel)
    local timeout = 0
    while not HasModelLoaded(weaponModel) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(weaponModel) then
        print(string.format('^3[Equipment]^0 Failed to load weapon model %s', weaponModel))
        return nil
    end

    -- Create weapon prop
    local prop = CreateObject(weaponModel, 0.0, 0.0, 0.0, true, true, false)
    SetEntityCollision(prop, false, false)

    -- Attach to appropriate bone based on slot
    local boneIndex
    local offsetX, offsetY, offsetZ = 0.0, 0.0, 0.0
    local rotX, rotY, rotZ = 0.0, 0.0, 0.0

    if slot == 'primary' then
        -- Attach to back (SKEL_Spine3)
        boneIndex = GetPedBoneIndex(ped, 24818)
        offsetX, offsetY, offsetZ = -0.15, -0.15, 0.0
        rotX, rotY, rotZ = 0.0, 180.0, 0.0
    elseif slot == 'secondary' then
        -- Attach to back right (SKEL_Spine2)
        boneIndex = GetPedBoneIndex(ped, 24817)
        offsetX, offsetY, offsetZ = 0.15, -0.10, 0.0
        rotX, rotY, rotZ = 0.0, 180.0, 20.0
    elseif slot == 'holster' then
        -- Attach to right hip (SKEL_R_Thigh)
        boneIndex = GetPedBoneIndex(ped, 58271)
        offsetX, offsetY, offsetZ = 0.12, 0.0, -0.05
        rotX, rotY, rotZ = 0.0, 270.0, 0.0
    elseif slot == 'melee' then
        -- Attach to left hip (SKEL_L_Thigh)
        boneIndex = GetPedBoneIndex(ped, 65245)
        offsetX, offsetY, offsetZ = -0.05, 0.05, 0.0
        rotX, rotY, rotZ = 180.0, 90.0, 0.0
    end

    AttachEntityToEntity(
        prop, ped, boneIndex,
        offsetX, offsetY, offsetZ,
        rotX, rotY, rotZ,
        true, true, false, true, 1, true
    )

    print(string.format('^2[Equipment]^0 Attached weapon to slot %s', slot))

    return prop
end

--- Remove weapon prop
local function RemoveWeaponProp(slot)
    if weaponProps[slot] then
        if DoesEntityExist(weaponProps[slot]) then
            DeleteEntity(weaponProps[slot])
        end
        weaponProps[slot] = nil
        print(string.format('^2[Equipment]^0 Removed weapon from slot %s', slot))
    end
end

-- ============================================
-- ARMOR VISUALS
-- ============================================

--- Apply armor component to ped
--- @param ped number Ped ID
--- @param itemDef table Item definition
--- @param slot string Equipment slot (head, armor, rig, backpack)
local function ApplyArmorComponent(ped, itemDef, slot)
    -- For now, we use native GTA V armor/helmet components
    -- Later you can add custom MLO models or prop attachments

    if slot == 'head' then
        -- Set helmet drawable (varies by ped model)
        local helmDrawable = itemDef.ped_drawable or 8
        local helmTexture = itemDef.ped_texture or 0
        SetPedPropIndex(ped, 0, helmDrawable, helmTexture, true) -- Prop 0 = Hat/Helmet
        print(string.format('^2[Equipment]^0 Applied helmet (drawable %d)', helmDrawable))
    elseif slot == 'armor' then
        -- Set body armor drawable
        local armorDrawable = itemDef.ped_drawable or 2
        local armorTexture = itemDef.ped_texture or 0
        SetPedComponentVariation(ped, 9, armorDrawable, armorTexture, 0) -- Component 9 = Body Armor
        print(string.format('^2[Equipment]^0 Applied armor (drawable %d)', armorDrawable))
    elseif slot == 'rig' then
        -- Tactical rig (can be body armor component or custom prop)
        local rigDrawable = itemDef.ped_drawable or 1
        local rigTexture = itemDef.ped_texture or 0
        SetPedComponentVariation(ped, 9, rigDrawable, rigTexture, 0)
        print(string.format('^2[Equipment]^0 Applied rig (drawable %d)', rigDrawable))
    elseif slot == 'backpack' then
        -- Backpack (can be torso component or prop attachment)
        local backpackDrawable = itemDef.ped_drawable or 45
        local backpackTexture = itemDef.ped_texture or 0
        SetPedComponentVariation(ped, 5, backpackDrawable, backpackTexture, 0) -- Component 5 = Bag
        print(string.format('^2[Equipment]^0 Applied backpack (drawable %d)', backpackDrawable))
    end
end

--- Remove armor component
local function RemoveArmorComponent(ped, slot)
    if slot == 'head' then
        ClearPedProp(ped, 0) -- Remove helmet
        print('^2[Equipment]^0 Removed helmet')
    elseif slot == 'armor' or slot == 'rig' then
        SetPedComponentVariation(ped, 9, 0, 0, 0) -- Remove body armor
        print('^2[Equipment]^0 Removed armor/rig')
    elseif slot == 'backpack' then
        SetPedComponentVariation(ped, 5, 0, 0, 0) -- Remove backpack
        print('^2[Equipment]^0 Removed backpack')
    end
end

-- ============================================
-- MAIN SYNC FUNCTION
-- ============================================

--- Sync equipment visuals based on server data
--- @param data table {slot, item_id, itemDef}
RegisterNetEvent('equipment:syncVisuals', function(data)
    local ped = PlayerPedId()

    if not data.slot or not data.item_id then
        print('^3[Equipment]^0 Invalid sync data')
        return
    end

    local slot = data.slot
    local itemId = data.item_id
    local itemDef = data.itemDef or Items[itemId]

    if not itemDef then
        print(string.format('^3[Equipment]^0 Item definition not found for %s', itemId))
        return
    end

    -- Update current equipment state
    currentEquipment[slot] = itemId

    -- Apply visuals based on item category
    if itemDef.category == 'primary' or itemDef.category == 'secondary' or
       itemDef.category == 'pistol' or itemDef.category == 'melee' then
        -- Remove old weapon prop if exists
        RemoveWeaponProp(slot)

        -- Attach new weapon prop
        local weaponModel = itemDef.world_prop or GetHashKey('WEAPON_PISTOL')
        weaponProps[slot] = AttachWeaponProp(ped, weaponModel, slot)

    elseif itemDef.category == 'helmet' or itemDef.category == 'armor' or
           itemDef.category == 'rig' or itemDef.category == 'backpack' then
        -- Apply armor/clothing component
        ApplyArmorComponent(ped, itemDef, slot)
    end

    print(string.format('^2[Equipment]^0 Synced visuals for slot %s (item: %s)', slot, itemId))
end)

--- Clear equipment visuals when item unequipped
RegisterNetEvent('equipment:clearVisuals', function(slot)
    local ped = PlayerPedId()

    if not slot then
        return
    end

    currentEquipment[slot] = nil

    -- Remove weapon prop or armor component
    RemoveWeaponProp(slot)
    RemoveArmorComponent(ped, slot)

    print(string.format('^2[Equipment]^0 Cleared visuals for slot %s', slot))
end)

-- ============================================
-- CLEANUP ON DEATH/RESPAWN
-- ============================================

AddEventHandler('playerSpawned', function()
    -- Clear all equipment visuals on respawn
    local ped = PlayerPedId()

    for slot, _ in pairs(weaponProps) do
        RemoveWeaponProp(slot)
    end

    for slot, _ in pairs(currentEquipment) do
        RemoveArmorComponent(ped, slot)
    end

    currentEquipment = {}
    weaponProps = {}

    print('^2[Equipment]^0 Cleared all visuals on respawn')
end)

print('^2[Equipment]^0 Visuals module loaded')
