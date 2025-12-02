# OX_CORE - Documentation Complète

## Vue d'ensemble

**ox_core** est un framework FiveM moderne développé par Overextended. Il fournit une base robuste pour les serveurs FiveM avec :

- **Version**: 1.5.8
- **License**: LGPL-3.0-or-later
- **Repository**: https://github.com/communityox/ox_core.git
- **Dépendances**:
  - FiveM Server Build 12913+
  - OneSync activé
  - ox_lib
  - MariaDB 11.4+ (recommandé)

---

## Schéma de Base de Données

### Tables Principales

#### 1. **users** - Utilisateurs
Stocke les identifiants des joueurs.

```sql
CREATE TABLE IF NOT EXISTS `users` (
  `userId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) DEFAULT NULL,
  `license2` VARCHAR(50) DEFAULT NULL,
  `steam` VARCHAR(20) DEFAULT NULL,
  `fivem` VARCHAR(10) DEFAULT NULL,
  `discord` VARCHAR(20) DEFAULT NULL,
  PRIMARY KEY (`userId`)
);
```

---

#### 2. **characters** - Personnages
Stocke les informations des personnages.

```sql
CREATE TABLE IF NOT EXISTS `characters` (
  `charId` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `userId` INT UNSIGNED NOT NULL,
  `stateId` VARCHAR(7) NOT NULL UNIQUE,
  `firstName` VARCHAR(50) NOT NULL,
  `lastName` VARCHAR(50) NOT NULL,
  `fullName` VARCHAR(101) AS (CONCAT(`firstName`, ' ', `lastName`)) STORED,
  `gender` VARCHAR(10) NOT NULL,
  `dateOfBirth` DATE NOT NULL,
  `phoneNumber` VARCHAR(20) NULL,
  `lastPlayed` DATETIME DEFAULT CURRENT_TIMESTAMP() NOT NULL,
  `isDead` TINYINT(1) DEFAULT 0 NOT NULL,
  `x` FLOAT NULL,
  `y` FLOAT NULL,
  `z` FLOAT NULL,
  `heading` FLOAT NULL,
  `health` TINYINT UNSIGNED NULL,
  `armour` TINYINT UNSIGNED NULL,
  `statuses` LONGTEXT COLLATE utf8mb4_bin DEFAULT JSON_OBJECT() NOT NULL,
  `deleted` DATE NULL
);
```

**Champs importants:**
- `stateId`: Identifiant unique (ex: "AB1234")
- `statuses`: JSON stockant faim, soif, stress, etc.
- `deleted`: Suppression douce (soft delete)

---

#### 3. **ox_groups** - Groupes/Jobs
Définit les groupes (police, ambulance, etc.).

```sql
CREATE TABLE IF NOT EXISTS `ox_groups` (
  `name` VARCHAR(20) NOT NULL PRIMARY KEY,
  `label` VARCHAR(50) NOT NULL,
  `type` VARCHAR(50) NULL,
  `colour` TINYINT UNSIGNED DEFAULT NULL,
  `hasAccount` TINYINT(1) NOT NULL DEFAULT '0'
);
```

**Exemple:**
```sql
INSERT INTO ox_groups (name, label, type, hasAccount)
VALUES ('police', 'LSPD', 'leo', 1);
```

---

#### 4. **character_groups** - Appartenance aux groupes
Lie les personnages aux groupes avec grades.

```sql
CREATE TABLE IF NOT EXISTS `character_groups` (
  `charId` INT UNSIGNED NOT NULL,
  `name` VARCHAR(20) NOT NULL,
  `grade` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `isActive` TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY `name` (`name`, `charId`)
);
```

**Utilisation:**
- `isActive`: Groupe actuellement actif (système de service)
- `grade`: Rang dans le groupe

---

#### 5. **ox_group_grades** - Grades des groupes

```sql
CREATE TABLE IF NOT EXISTS `ox_group_grades` (
  `group` VARCHAR(20) NOT NULL,
  `grade` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `label` VARCHAR(50) NOT NULL,
  `accountRole` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`group`, `grade`)
);
```

**Exemple:**
```sql
INSERT INTO ox_group_grades (group, grade, label, accountRole) VALUES
('police', 1, 'Cadet', 'viewer'),
('police', 2, 'Officer', 'contributor'),
('police', 3, 'Sergent', 'manager'),
('police', 4, 'Lieutenant', 'manager'),
('police', 5, 'Capitaine', 'owner');
```

---

#### 6. **vehicles** - Véhicules

```sql
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plate` CHAR(8) NOT NULL UNIQUE,
  `vin` CHAR(17) NOT NULL UNIQUE,
  `owner` INT UNSIGNED NULL,
  `group` VARCHAR(20) NULL,
  `model` VARCHAR(20) NOT NULL,
  `class` TINYINT UNSIGNED NULL,
  `data` JSON NOT NULL,
  `trunk` JSON NULL,
  `glovebox` JSON NULL,
  `stored` VARCHAR(50) NULL,
  PRIMARY KEY (`id`)
);
```

**Champs importants:**
- `vin`: Numéro de châssis (17 caractères, unique)
- `owner`: charId du propriétaire (NULL si non possédé)
- `group`: Propriété de groupe (véhicules partagés)
- `stored`: Emplacement ('garage_nom', 'impound', NULL si spawné)

---

#### 7. **accounts** - Comptes bancaires

```sql
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `label` VARCHAR(50) NOT NULL,
  `owner` INT UNSIGNED NULL,
  `group` VARCHAR(20) NULL,
  `balance` INT DEFAULT 0 NOT NULL,
  `isDefault` TINYINT(1) DEFAULT 0 NOT NULL,
  `type` ENUM ('personal', 'shared', 'group', 'inactive') DEFAULT 'personal' NOT NULL
);
```

**Types de comptes:**
- `personal`: Compte individuel
- `shared`: Compte partagé multi-utilisateurs
- `group`: Compte d'organisation
- `inactive`: Compte supprimé (soft delete)

---

#### 8. **account_roles** - Rôles de compte

```sql
CREATE TABLE `account_roles` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `deposit` TINYINT(1) NOT NULL DEFAULT '0',
  `withdraw` TINYINT(1) NOT NULL DEFAULT '0',
  `addUser` TINYINT(1) NOT NULL DEFAULT '0',
  `removeUser` TINYINT(1) NOT NULL DEFAULT '0',
  `manageUser` TINYINT(1) NOT NULL DEFAULT '0',
  `transferOwnership` TINYINT(1) NOT NULL DEFAULT '0',
  `viewHistory` TINYINT(1) NOT NULL DEFAULT '0',
  `manageAccount` TINYINT(1) NOT NULL DEFAULT '0',
  `closeAccount` TINYINT(1) NOT NULL DEFAULT '0',
  `sendInvoice` TINYINT(1) NOT NULL DEFAULT '0',
  `payInvoice` TINYINT(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);
```

**Rôles par défaut:**
- `viewer`: Visualisation uniquement
- `contributor`: Peut déposer
- `manager`: Peut déposer, retirer, gérer utilisateurs
- `owner`: Contrôle total

---

#### 9. **ox_licenses** - Licences

```sql
CREATE TABLE IF NOT EXISTS `ox_licenses` (
  `name` VARCHAR(20) NOT NULL UNIQUE,
  `label` VARCHAR(50) NOT NULL
);
```

**Licences par défaut:**
```sql
INSERT INTO ox_licenses (name, label) VALUES
('weapon', 'Permis de Port d\'Arme'),
('driver', 'Permis de Conduire');
```

---

#### 10. **ox_statuses** - Statuts

```sql
CREATE TABLE IF NOT EXISTS `ox_statuses` (
  `name` VARCHAR(20) NOT NULL,
  `default` TINYINT (3) UNSIGNED NOT NULL DEFAULT 0,
  `onTick` DECIMAL(8, 7) DEFAULT 0
);
```

**Statuts par défaut:**
```sql
INSERT INTO ox_statuses (name, `default`, onTick) VALUES
('hunger', 0, 0.02),   -- Faim augmente
('thirst', 0, 0.05),   -- Soif augmente
('stress', 0, -0.10);  -- Stress diminue
```

---

## Exports Serveur (Server-Side)

### Gestion des Joueurs

#### **Ox.GetPlayer(source)**
Récupère l'instance d'un joueur.

```lua
-- Par source
local player = Ox.GetPlayer(source)

-- Par identifiant
local player = Ox.GetPlayer('license2:xxxxx')
```

**Retourne:** Instance `OxPlayer` ou `nil`

---

#### **Ox.GetPlayers(filter)**
Récupère tous les joueurs, avec filtre optionnel.

```lua
-- Tous les joueurs
local players = Ox.GetPlayers()

-- Joueurs avec filtre
local cops = Ox.GetPlayers({ groups = { police = 1 } })
```

---

### Méthodes OxPlayer (Joueur)

#### **Propriétés**
```lua
player.source        -- ID serveur du joueur
player.userId        -- ID utilisateur (base de données)
player.charId        -- ID personnage actif
player.stateId       -- State ID (ex: "AB1234")
player.username      -- Nom d'utilisateur
player.identifier    -- Identifiant principal
player.ped           -- Entité ped du joueur
```

---

#### **player.emit(eventName, ...)**
Déclenche un événement côté client.

```lua
player.emit('notification', 'Bonjour!')
```

---

#### **player.set(key, value, replicated)**
Stocke des métadonnées sur le personnage.

```lua
player.set('job', 'police', true)  -- répliqué au client
player.set('customData', { foo = 'bar' })
```

---

#### **player.get(key)**
Récupère des métadonnées.

```lua
local job = player.get('job')
local firstName = player.get('firstName')
```

---

#### **player.getCoords()**
Récupère les coordonnées du joueur.

```lua
local coords = player.getCoords()  -- vector3
```

---

#### **player.getAccount()**
Récupère le compte bancaire par défaut.

```lua
local account = player.getAccount()
```

---

#### **player.setGroup(groupName, grade)**
Ajoute/retire un joueur d'un groupe.

```lua
-- Ajouter au groupe avec grade
player.setGroup('police', 3)

-- Retirer du groupe
player.setGroup('police', 0)
```

**Retourne:** `boolean` (succès)

---

#### **player.getGroup(filter)**
Récupère le grade d'un joueur dans un groupe.

```lua
-- Vérifier un seul groupe
local grade = player.getGroup('police')

-- Vérifier plusieurs groupes
local name, grade = player.getGroup({ 'police', 'sheriff' })

-- Avec grade minimum requis
local name, grade = player.getGroup({ police = 2, sheriff = 3 })
```

---

#### **player.getGroups()**
Récupère tous les groupes du joueur.

```lua
local groups = player.getGroups()
-- Retourne: { police = 3, ambulance = 1 }
```

---

#### **player.setActiveGroup(groupName)**
Définit le groupe actif (en service).

```lua
player.setActiveGroup('police')    -- en service
player.setActiveGroup(nil)         -- hors service
```

---

#### **player.hasPermission(permission)**
Vérifie une permission.

```lua
local canAccess = player.hasPermission('group.police.armory')
```

---

#### **player.setStatus(statusName, value)**
Définit une valeur de statut.

```lua
player.setStatus('hunger', 50)
```

---

#### **player.getStatus(statusName)**
Récupère une valeur de statut.

```lua
local hunger = player.getStatus('hunger')
```

---

#### **player.addStatus(statusName, value)**
Augmente un statut.

```lua
player.addStatus('hunger', 10)  -- +10
```

---

#### **player.removeStatus(statusName, value)**
Diminue un statut.

```lua
player.removeStatus('thirst', 5)  -- -5
```

---

#### **player.addLicense(licenseName)**
Accorde une licence.

```lua
player.addLicense('weapon')
```

---

#### **player.removeLicense(licenseName)**
Retire une licence.

```lua
player.removeLicense('driver')
```

---

#### **player.getLicense(licenseName)**
Récupère les données d'une licence.

```lua
local license = player.getLicense('weapon')
-- Retourne: { issued = timestamp, ... }
```

---

#### **player.save()**
Sauvegarde le personnage dans la base de données.

```lua
player.save()
```

---

#### **player.logout(save, dropped)**
Déconnecte le personnage actif.

```lua
player.logout()           -- sauvegarde et retour à la sélection
player.logout(false)      -- ne sauvegarde pas
```

---

#### **player.createCharacter(data)**
Crée un nouveau personnage.

```lua
local charIndex = player.createCharacter({
  firstName = 'John',
  lastName = 'Doe',
  gender = 'male',
  date = '1990-01-01'
})
```

---

### Gestion des Véhicules

#### **Ox.GetVehicle(handle)**
Récupère un véhicule par entity ou VIN.

```lua
-- Par entity
local vehicle = Ox.GetVehicle(entity)

-- Par VIN
local vehicle = Ox.GetVehicle('1AB2CD3EF1234567')
```

---

#### **Ox.CreateVehicle(data, coords, heading)**
Crée et spawn un nouveau véhicule.

```lua
-- Véhicule possédé
local vehicle = Ox.CreateVehicle({
  model = 'adder',
  owner = charId
}, coords, heading)

-- Véhicule temporaire
local vehicle = Ox.CreateVehicle('adder', coords, heading)
```

---

#### **Ox.SpawnVehicle(dbId, coords, heading)**
Spawn un véhicule sauvegardé.

```lua
local vehicle = Ox.SpawnVehicle(dbId, coords, heading)
```

---

### Méthodes OxVehicle

#### **Propriétés**
```lua
vehicle.entity       -- Handle de l'entité
vehicle.netId        -- Network ID
vehicle.plate        -- Plaque d'immatriculation
vehicle.model        -- Modèle du véhicule
vehicle.id           -- ID base de données
vehicle.vin          -- VIN du véhicule
vehicle.owner        -- charId du propriétaire
vehicle.group        -- Nom du groupe propriétaire
```

---

#### **vehicle.setStored(location, despawn)**
Définit l'emplacement de stockage.

```lua
vehicle.setStored('garage_lspd')
vehicle.setStored('impound', true)  -- despawn
vehicle.setStored(nil)              -- marquer comme sorti
```

---

#### **vehicle.setOwner(charId)**
Change le propriétaire.

```lua
vehicle.setOwner(charId)
vehicle.setOwner(nil)  -- retire le propriétaire
```

---

#### **vehicle.setGroup(group)**
Définit la propriété de groupe.

```lua
vehicle.setGroup('police')
vehicle.setGroup(nil)  -- retire le groupe
```

---

#### **vehicle.getProperties()**
Récupère les propriétés du véhicule (personnalisation).

```lua
local properties = vehicle.getProperties()
```

---

#### **vehicle.setProperties(properties, apply)**
Définit les propriétés.

```lua
vehicle.setProperties(properties)
vehicle.setProperties(properties, true)  -- applique à l'entité
```

---

#### **vehicle.save()**
Sauvegarde le véhicule.

```lua
vehicle.save()
```

---

#### **vehicle.despawn(save)**
Despawn le véhicule.

```lua
vehicle.despawn()        -- despawn et sauvegarde
vehicle.despawn(false)   -- despawn sans sauvegarder
```

---

#### **vehicle.delete()**
Supprime définitivement le véhicule.

```lua
vehicle.delete()  -- retire de la BDD et despawn
```

---

### Gestion des Comptes Bancaires

#### **Ox.GetAccount(accountId)**
Récupère un compte par ID.

```lua
local account = Ox.GetAccount(accountId)
```

---

#### **Ox.GetCharacterAccount(charId)**
Récupère le compte par défaut d'un personnage.

```lua
local account = Ox.GetCharacterAccount(charId)
local account = Ox.GetCharacterAccount('AB1234')  -- par stateId
```

---

#### **Ox.CreateAccount(owner, label)**
Crée un nouveau compte.

```lua
-- Compte de personnage
local account = Ox.CreateAccount(charId, 'Mon Épargne')

-- Compte de groupe
local account = Ox.CreateAccount('police', 'Police Department')
```

---

### Méthodes OxAccount

#### **account.get(keys)**
Récupère les informations du compte.

```lua
-- Un seul champ
local balance = account.get('balance')

-- Plusieurs champs
local data = account.get({ 'balance', 'label', 'type' })
```

---

#### **account.addBalance(data)**
Ajoute des fonds.

```lua
local result = account.addBalance({
  amount = 1000,
  message = 'Salaire'
})
```

---

#### **account.removeBalance(data)**
Retire des fonds.

```lua
local result = account.removeBalance({
  amount = 500,
  message = 'Achat',
  overdraw = false
})
```

---

#### **account.transferBalance(data)**
Transfère des fonds.

```lua
local result = account.transferBalance({
  toId = targetAccountId,
  amount = 1000,
  message = 'Paiement',
  note = 'Facture #123',
  actorId = charId
})
```

---

#### **account.depositMoney(playerId, amount, message)**
Dépose de l'argent liquide (nécessite ox_inventory).

```lua
local result = account.depositMoney(playerId, amount, 'Dépôt ATM')
```

---

#### **account.withdrawMoney(playerId, amount, message)**
Retire de l'argent liquide.

```lua
local result = account.withdrawMoney(playerId, amount, 'Retrait ATM')
```

---

#### **account.createInvoice(data)**
Crée une facture.

```lua
local invoiceId = account.createInvoice({
  toAccount = targetAccountId,
  payerId = charId,
  amount = 5000,
  message = 'Services rendus',
  dueDate = os.time() + (86400 * 7)  -- 7 jours
})
```

---

### Gestion des Groupes

#### **Ox.GetGroup(name)**
Récupère les données d'un groupe.

```lua
local group = Ox.GetGroup('police')
```

**Retourne:**
```lua
{
  name = 'police',
  label = 'LSPD',
  type = 'leo',
  colour = 0,
  hasAccount = true,
  grades = { ... },
  principal = 'group.police',
  activePlayers = Set { [1] = true, [2] = true }
}
```

---

#### **Ox.GetGroupActivePlayers(groupName)**
Récupère les joueurs en service.

```lua
local activeCops = Ox.GetGroupActivePlayers('police')
```

---

## Exports Client (Client-Side)

### Gestion du Joueur

#### **Ox.GetPlayer()**
Récupère l'instance du joueur local.

```lua
local player = Ox.GetPlayer()
```

---

### Méthodes OxPlayer Client

#### **player.get(key)**
Récupère des métadonnées (demande au serveur si non caché).

```lua
local firstName = player.get('firstName')
```

---

#### **player.getCoords()**
Récupère les coordonnées.

```lua
local coords = player.getCoords()
```

---

#### **player.getGroup(filter)**
Récupère le grade dans un groupe.

```lua
local grade = player.getGroup('police')
```

---

#### **player.getStatuses()**
Récupère tous les statuts.

```lua
local statuses = player.getStatuses()
```

---

#### **player.hasPermission(permission)**
Vérifie une permission.

```lua
local canAccess = player.hasPermission('group.police.armory')
```

---

## Événements

### Événements Serveur

#### **ox:playerLoaded**
Déclenché quand un joueur charge un personnage.

```lua
AddEventHandler('ox:playerLoaded', function(source, userId, charId)
  print(('Joueur %s a chargé le personnage %s'):format(source, charId))
end)
```

---

#### **ox:playerLogout**
Déclenché quand un joueur se déconnecte.

```lua
AddEventHandler('ox:playerLogout', function(source, userId, charId)
  print(('Joueur %s s\'est déconnecté'):format(source))
end)
```

---

#### **ox:setGroup**
Déclenché quand le groupe d'un joueur change.

```lua
AddEventHandler('ox:setGroup', function(source, groupName, grade)
  if grade then
    print(('Joueur %s ajouté à %s grade %s'):format(source, groupName, grade))
  else
    print(('Joueur %s retiré de %s'):format(source, groupName))
  end
end)
```

---

#### **ox:setActiveGroup**
Déclenché quand le groupe actif change.

```lua
AddEventHandler('ox:setActiveGroup', function(source, newGroup, oldGroup)
  print(('Joueur %s changé de service: %s -> %s'):format(source, oldGroup or 'none', newGroup or 'none'))
end)
```

---

### Événements Client

#### **ox:playerLoaded**
Déclenché quand le joueur local charge un personnage.

```lua
AddEventHandler('ox:playerLoaded', function(player, isNew)
  print('Personnage chargé')
  if isNew then
    print('C\'est un nouveau personnage!')
  end
end)
```

---

#### **ox:playerDeath**
Déclenché à la mort du joueur.

```lua
AddEventHandler('ox:playerDeath', function()
  print('Joueur mort')
end)
```

---

#### **ox:statusTick**
Déclenché à chaque mise à jour des statuts.

```lua
AddEventHandler('ox:statusTick', function(statuses)
  -- statuses = { hunger = 50, thirst = 75 }
end)
```

---

## Configuration

### Convars Serveur (server.cfg)

```cfg
# Connexion MySQL
set mysql_connection_string "mysql://root:gtol@localhost/prisonrp?charset=utf8mb4"

# Nombre de slots de personnages (défaut: 1)
set ox:characterSlots 3

# Format de plaque (. = aléatoire, A = lettre, 1 = chiffre)
set ox:plateFormat "........"

# Stockage véhicule par défaut
set ox:defaultVehicleStore "impound"

# Mode debug
set ox:debug 1

# Créer compte par défaut à la création de personnage
set ox:createDefaultAccount 1
```

---

## Système de Permissions

### Format des Permissions

```lua
-- Format: group.{groupName}.{permission}
player.hasPermission('group.police.armory')
player.hasPermission('group.admin.commands')
```

### Définir des Permissions

```lua
-- Via ox_lib
Ox.SetGroupPermission('police', 3, 'armory', true)

-- Via server.cfg
add_ace group.police.grade.3 group.police.armory allow
```

### Permissions dans server.cfg

```cfg
# Admin total
add_ace group.admin command allow

# Groupe police - armurerie pour grade 3+
add_ace group.police.grade.3 group.police.armory allow
add_ace group.police.grade.4 group.police.armory allow

# Groupe admin - commandes économie
add_ace group.admin.grade.1 group.admin.economy allow
```

---

## Exemples Pratiques

### Exemple 1: Système de Service

```lua
-- Commande pour prendre/quitter le service
RegisterCommand('service', function(source)
  local player = Ox.GetPlayer(source)
  local activeGroup = player.get('activeGroup')

  if activeGroup then
    -- Quitter le service
    player.setActiveGroup(nil)
    player.emit('ox_lib:notify', {
      title = 'Service',
      description = 'Vous êtes maintenant hors service',
      type = 'info'
    })
  else
    -- Trouver le premier groupe disponible
    local groups = player.getGroups()
    local firstGroup = next(groups)

    if firstGroup then
      player.setActiveGroup(firstGroup)
      player.emit('ox_lib:notify', {
        title = 'Service',
        description = 'Vous êtes en service: ' .. firstGroup,
        type = 'success'
      })
    else
      player.emit('ox_lib:notify', {
        title = 'Erreur',
        description = 'Vous n\'avez aucun métier',
        type = 'error'
      })
    end
  end
end)

-- Vérifier le nombre de policiers en service
RegisterCommand('countcops', function(source)
  local activeCops = Ox.GetGroupActivePlayers('police')
  print('Policiers en service:', #activeCops)
end, true)
```

---

### Exemple 2: Donner un Véhicule

```lua
-- Commande admin pour donner un véhicule
RegisterCommand('giveveh', function(source, args)
  local player = Ox.GetPlayer(source)

  -- Vérifier permission
  if not player.hasPermission('group.admin.vehicles') then
    return player.emit('ox_lib:notify', {
      type = 'error',
      description = 'Pas de permission'
    })
  end

  local model = args[1]
  local targetId = tonumber(args[2]) or source

  local target = Ox.GetPlayer(targetId)
  if not target then return end

  local coords = target.getCoords()

  -- Créer véhicule possédé
  local vehicle = Ox.CreateVehicle({
    model = model,
    owner = target.charId
  }, coords, 0.0)

  if vehicle then
    target.emit('ox_lib:notify', {
      type = 'success',
      description = 'Véhicule reçu: ' .. model
    })
  end
end, true)
```

---

### Exemple 3: Système de Salaire

```lua
-- Distribuer les salaires toutes les 30 minutes
CreateThread(function()
  while true do
    Wait(30 * 60 * 1000)  -- 30 minutes

    local players = Ox.GetPlayers()

    for _, player in pairs(players) do
      local activeGroup = player.get('activeGroup')

      if activeGroup then
        local grade = player.getGroup(activeGroup)
        local salary = 500 + (grade * 100)  -- Salaire basé sur le grade

        local account = player.getAccount()
        if account then
          account.addBalance({
            amount = salary,
            message = 'Salaire - ' .. activeGroup
          })

          player.emit('ox_lib:notify', {
            title = 'Salaire',
            description = string.format('Vous avez reçu $%d', salary),
            type = 'success'
          })
        end
      end
    end
  end
end)
```

---

### Exemple 4: Garer un Véhicule

```lua
-- Fonction pour garer un véhicule
function ParkVehicle(source, garageName)
  local ped = GetPlayerPed(source)
  local veh = GetVehiclePedIsIn(ped, false)

  if veh == 0 then
    return { success = false, message = 'Pas dans un véhicule' }
  end

  local vehicle = Ox.GetVehicleFromEntity(veh)

  if not vehicle then
    return { success = false, message = 'Véhicule non possédé' }
  end

  local player = Ox.GetPlayer(source)

  -- Vérifier propriété
  if vehicle.owner ~= player.charId and not vehicle.group then
    return { success = false, message = 'Pas votre véhicule' }
  end

  -- Stocker et despawn
  vehicle.setStored(garageName, true)

  return { success = true, message = 'Véhicule garé' }
end
```

---

### Exemple 5: Distributeur ATM

```lua
-- Déposer de l'argent
RegisterNetEvent('atm:deposit', function(amount)
  local player = Ox.GetPlayer(source)
  local account = player.getAccount()

  if not account then return end

  local result = account.depositMoney(source, amount, 'Dépôt ATM')

  player.emit('ox_lib:notify', {
    type = result.success and 'success' or 'error',
    description = result.message
  })
end)

-- Retirer de l'argent
RegisterNetEvent('atm:withdraw', function(amount)
  local player = Ox.GetPlayer(source)
  local account = player.getAccount()

  if not account then return end

  local result = account.withdrawMoney(source, amount, 'Retrait ATM')

  player.emit('ox_lib:notify', {
    type = result.success and 'success' or 'error',
    description = result.message
  })
end)
```

---

### Exemple 6: Vérifier les Licences

```lua
-- Police: vérifier les licences d'un joueur
function CheckLicenses(officerSource, targetSource)
  local target = Ox.GetPlayer(targetSource)

  if not target then return nil end

  local licenses = target.getLicenses()
  local result = {}

  for name, data in pairs(licenses) do
    local licenseInfo = Ox.GetLicense(name)
    table.insert(result, {
      name = name,
      label = licenseInfo.label,
      issued = data.issued
    })
  end

  return result
end

-- Donner permis de conduire après test
RegisterNetEvent('dmv:success', function()
  local player = Ox.GetPlayer(source)

  if player.getLicense('driver') then
    return player.emit('ox_lib:notify', {
      type = 'error',
      description = 'Vous avez déjà un permis'
    })
  end

  player.addLicense('driver')
  player.emit('ox_lib:notify', {
    type = 'success',
    description = 'Permis de conduire obtenu!'
  })
end)
```

---

## Comment se Donner les Permissions Admin

### Méthode 1: Via server.cfg (Recommandé)

1. **Trouver votre FiveM ID:**
   - Connectez-vous au serveur
   - Dans la console serveur, tapez: `status`
   - Notez votre `identifier.fivem:XXXXXXXX`

2. **Modifier server.cfg:**
```cfg
# Ajouter cette ligne avec votre ID
add_principal identifier.fivem:VOTRE_ID group.admin
```

3. **Redémarrer le serveur**

---

### Méthode 2: Via Base de Données

```sql
-- 1. Créer le groupe admin
INSERT INTO ox_groups (name, label, type)
VALUES ('admin', 'Administrateurs', 'admin');

-- 2. Trouver votre charId
SELECT charId, firstName, lastName FROM characters
ORDER BY lastPlayed DESC LIMIT 5;

-- 3. Vous ajouter au groupe admin
INSERT INTO character_groups (charId, name, grade, isActive)
VALUES (VOTRE_CHAR_ID, 'admin', 99, 1);
```

---

### Méthode 3: Script Auto-Admin (Développement)

Créez `resources/[admin]/auto-admin/server.lua`:

```lua
-- ATTENTION: À UTILISER UNIQUEMENT EN DÉVELOPPEMENT
local adminIdentifiers = {
  'license2:xxxxx',
  'fivem:11668350',
  'discord:746700907248484393'
}

AddEventHandler('ox:playerLoaded', function(source, userId, charId)
  local player = Ox.GetPlayer(source)

  for _, id in ipairs(adminIdentifiers) do
    if player.identifier == id or player.get('userId') == userId then
      lib.addPrincipal(source, 'group.admin')
      print(('Auto-admin accordé à %s'):format(player.get('name')))
      break
    end
  end
end)
```

`fxmanifest.lua`:
```lua
fx_version 'cerulean'
game 'gta5'

server_script 'server.lua'

dependency 'ox_lib'
```

---

## Relations avec Autres Ressources

### ox_inventory
- Gère les inventaires de personnages
- Gère les coffres de véhicules
- Intégré avec `depositMoney` et `withdrawMoney`

### ox_lib
- Fournit des fonctions utilitaires
- Système de callbacks
- Gestion des ACE/permissions

### ox_target
- Interactions avec le monde
- Utilise les groupes pour les options

---

## Dépannage

### Problèmes Courants

**Le joueur ne se charge pas:**
- Vérifier la connexion MySQL
- Vérifier que l'utilisateur existe dans `users`
- Vérifier les logs serveur

**Les groupes ne fonctionnent pas:**
- Vérifier que le groupe existe dans `ox_groups`
- Vérifier les grades dans `ox_group_grades`
- Redémarrer le serveur après modification BDD

**Véhicule ne spawn pas:**
- Vérifier que le modèle existe
- Vérifier `stored` = NULL dans la BDD
- Vérifier les logs

**Compte bancaire ne fonctionne pas:**
- Vérifier `type` != 'inactive'
- Vérifier `accounts_access` pour le personnage
- Vérifier que ox_inventory tourne (pour cash)

---

## Ressources Utiles

- **GitHub**: https://github.com/communityox/ox_core
- **Discord**: https://discord.gg/overextended
- **Documentation**: https://overextended.dev
- **ox_lib**: https://github.com/overextended/ox_lib

---

**Version du Document**: 1.0
**Version Framework**: 1.5.8
**Dernière Mise à Jour**: 2025
