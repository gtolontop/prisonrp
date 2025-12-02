fx_version 'cerulean'
game 'gta5'

description 'The Last Colony - Stream Assets'
version '1.0.0'

-- Enable map resource
this_is_a_map 'yes'

-- Files that require explicit declaration
files {
    -- MAPS: Type definitions and config files
    'maps/**/*.ytyp',

    -- PEDS: All ped-related files
    'peds/**/*.ytd',

    -- VEHICLES: All vehicle files
    'vehicles/**/*.yft',

    -- WEAPONS: All weapon files
    'weapons//*.ydr',

    -- PROPS: All prop files
    'props/military_crates/*.ydr',
}