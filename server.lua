local AlienNPCs = {}
local AlienLocations = {} -- aliens.json

local LootPickups = {}
local LootLocations = {} -- lootpickups.json


-- welcome message
function OnPlayerJoin(player)
    SetPlayerSpawnLocation(player, 125773.000000, 80246.000000, 1645.000000, 90.0)
    SetPlayerRespawnTime(player, 15 * 1000)
	AddPlayerChatAll('<span color="#eeeeeeaa">'..GetPlayerName(player)..' ('..player..') joined the server</>')
	AddPlayerChatAll('<span color="#eeeeeeaa">There are '..GetPlayerCount()..' players on the server</>')
    AddPlayerChat(player, "Welcome to the invasion!")
end
AddEvent("OnPlayerJoin", OnPlayerJoin)

-- death message
function OnPlayerDeath(player, killer)
    AddPlayerChatAll(GetPlayerName(player)..' has been taken')
    AddPlayerChat(player, "DEAD!  You must wait 15 seconds to respawn...")
end
AddEvent("OnPlayerDeath", OnPlayerDeath)

-- add alien pos
AddCommand("apos", function(playerid)
    local x, y, z = GetPlayerLocation(playerid)
    string = "Location: "..x..", "..y..", "..z
    AddPlayerChat(playerid, string)
    print(string)
    table.insert(AlienLocations, { x, y, z })

    local file = io.open("packages/"..GetPackageName().."/data/aliens.json", 'w')
    local contents = json_encode(AlienLocations)
    file:write(contents)
    io.close(file)
end)

-- add loot pos
AddCommand("lpos", function(playerid)
    local x, y, z = GetPlayerLocation(playerid)
    string = "Location: "..x..", "..y..", "..z
    AddPlayerChat(playerid, string)
    print(string)
    table.insert(LootLocations, { x, y, z })

    local file = io.open("packages/"..GetPackageName().."/data/lootboxes.json", 'w')
    local contents = json_encode(LootLocations)
    file:write(contents)
    io.close(file)
end)

-- Setup world
function OnPackageStart()
    SetupAliens()
    SetupLootPickups()

    -- one timer to rule them all
    CreateTimer(function()
        for _,npc in pairs(AlienNPCs) do
            ResetAlien(npc)
        end
    end, 10000, npc)
end
AddEvent("OnPackageStart", OnPackageStart)


function SetupAliens()
    print "Reading alien NPC positions..."
    local file = io.open("packages/"..GetPackageName().."/data/aliens.json", 'r')
    local contents = file:read("*a")
    AlienLocations = json_decode(contents);
    io.close(file)

    -- create alien npcs
    for _,pos in pairs(AlienLocations) do
        npc = CreateNPC(pos[1], pos[2], pos[3], 90)
        SetNPCHealth(npc, 999)
        SetNPCPropertyValue(npc, 'clothing', math.random(23, 24))
        SetNPCPropertyValue(npc, 'location', pos)
        table.insert(AlienNPCs, npc)
    end
end

function SetupLootPickups()
    print "Reading loot pickups..."
    local file = io.open("packages/"..GetPackageName().."/data/lootpickups.json", 'r')
    local contents = file:read("*a")
    LootLocations = json_decode(contents);
    io.close(file)

    -- create loot pickups
    for _,pos in pairs(LootLocations) do
        local pickup = CreatePickup(815, pos[1], pos[2], pos[3])
        SetPickupPropertyValue(pickup, 'type', 'heal')
        table.insert(LootPickups, pickup)

        local objectId = math.random(4,22)
        local weaponId = objectId - 2
        local pickup = CreatePickup(objectId, pos[1] + 200, pos[2], pos[3])
        SetPickupPropertyValue(pickup, 'type', 'weapon')
        SetPickupPropertyValue(pickup, 'weaponId', weaponId)
        table.insert(LootPickups, pickup)

        local objectId = math.random(4,22)
        local weaponId = objectId - 2
        local pickup = CreatePickup(objectId, pos[1] - 200, pos[2], pos[3])
        SetPickupPropertyValue(pickup, 'type', 'weapon')
        SetPickupPropertyValue(pickup, 'weaponId', weaponId)
        table.insert(LootPickups, pickup)

        local objectId = math.random(4,22)
        local weaponId = objectId - 2
        local pickup = CreatePickup(objectId, pos[1], pos[2] + 200, pos[3])
        SetPickupPropertyValue(pickup, 'type', 'weapon')
        SetPickupPropertyValue(pickup, 'weaponId', weaponId)
        table.insert(LootPickups, pickup)

        local objectId = math.random(4,22)
        local weaponId = objectId - 2
        local pickup = CreatePickup(objectId, pos[1], pos[2] - 200, pos[3])
        SetPickupPropertyValue(pickup, 'type', 'weapon')
        SetPickupPropertyValue(pickup, 'weaponId', weaponId)
        table.insert(LootPickups, pickup)
    end
end

-- pickup loot
function OnPlayerPickupHit(player, pickup)
	for _,p in pairs(LootPickups) do
		if p == pickup then
            if (GetPickupPropertyValue(pickup, 'type') == 'weapon') then
                SetPlayerWeapon(player, GetPickupPropertyValue(pickup, 'weaponId'), 450, true, 1, true)
            elseif (GetPickupPropertyValue(pickup, 'type') == 'heal') then
                CallRemoteEvent(player, 'HealthPickup')                
                SetPlayerHealth(player, GetPlayerHealth(player) + 25)
            end
            SetPickupVisibility(pickup, player, false)
            Delay(30 * 1000, function()
                SetPickupVisibility(pickup, player, true)
            end)
            return
		end
	end
end
AddEvent("OnPlayerPickupHit", OnPlayerPickupHit)


-- damage aliens
function OnNPCDamage(npc, damagetype, amount)
    -- stop alien temporarily when damaged
    local x, y, z = GetNPCLocation(npc)
    SetNPCTargetLocation(npc, x, y, z)

    health = GetNPCHealth(npc)

    local text = CreateText3D(health, 12, x, y, z + 140, 0, 0, 0)
    Delay(1000, function()
        DestroyText3D(text)
    end)

    if (health <= 0) then
        -- alien is dead
        local location = GetNPCPropertyValue(npc, 'location')
        local target = GetNPCPropertyValue(npc, 'target')
        SetNPCTargetLocation(npc, location[1], location[2], location[3])
        SetNPCPropertyValue(npc, 'target', nil, true)
        CallRemoteEvent(target, 'AlienNoLongerAttacking', npc)
    else
        -- keep attacking if still alive
        Delay(500, function(npc)
            ResetAlien(npc)
        end, npc)
    end
end
AddEvent("OnNPCDamage", OnNPCDamage)

function ResetAlien(npc)
    health = GetNPCHealth(npc)
    if (health <= 0) then
        return
    end

    local target, nearest_dist = GetNearestPlayer(npc)
    if (target~=0 and not IsPlayerDead(target)) then
        if (nearest_dist < 3000) then
            SetNPCPropertyValue(npc, 'target', target, true)
            SetNPCFollowPlayer(npc, target, 350)
            CallRemoteEvent(target, 'AlienAttacking', npc)
        elseif (GetNPCPropertyValue(npc, 'target') == target) then
            local x, y, z = GetNPCLocation(npc)
            SetNPCTargetLocation(npc, x, y, z)
            SetNPCPropertyValue(npc, 'target', nil, true)
            CallRemoteEvent(target, 'AlienNoLongerAttacking', npc)
        end
    end
end

function AttackNearestPlayer(npc)
    local target, nearest_dist = GetNearestPlayer(npc)
    if (target~=0 and nearest_dist==0.0) then
        if (not IsPlayerDead(target)) then
            SetNPCAnimation(npc, "SLAP01", false)
            SetPlayerHealth(target, 0)
            SetNPCPropertyValue(npc, 'target', nil, true)
            SetNPCAnimation(npc, "DANCE12", true)
            Delay(7000, function()
                local location = GetNPCPropertyValue(npc, 'location')
                SetNPCTargetLocation(npc, location[1], location[2], location[3])
            end)
        end
    end
end
AddEvent("OnNPCReachTarget", AttackNearestPlayer)


function GetNearestPlayer(npc)
	local plys = GetAllPlayers()
	local found = 0
	local nearest_dist = 999999.9
	local x, y, z = GetNPCLocation(npc)

	for _,v in pairs(plys) do
		local x2, y2, z2 = GetPlayerLocation(v)
		local dist = GetDistance3D(x, y, z, x2, y2, z2)
		if dist < nearest_dist then
			nearest_dist = dist
			found = v
		end
	end
	return found, nearest_dist
end