local AlienHealth = 999
local AlienRespawnTime = 20 * 1000
local AlienLocations = {} -- aliens.json
local AlienAttackRange = 5000
local AlienSpawnInterval = 30 * 60 * 1000 -- spawn aliens every 30 mins

-- TODO remove
AddCommand("apos", function(playerid)
    local x, y, z = GetPlayerLocation(playerid)
    string = "Location: "..x.." "..y.." "..z
    AddPlayerChat(playerid, string)
    print(string)
    table.insert(AlienLocations, { x, y, z })

    File_SaveJSONTable("packages/"..GetPackageName().."/server/data/aliens.json", AlienLocations)
end)

-- TODO remove
AddCommand("alien", function(player)
    local x, y, z = GetPlayerLocation(player)
    SpawnAlien(x+2000, y, z)
end)

function SetupAliens()
    AlienLocations = File_LoadJSONTable("packages/"..GetPackageName().."/server/data/aliens.json")

    -- spawn all aliens
    SpawnAlienAreas()

    -- re-spawn on a timer
    CreateTimer(function()
        SpawnAlienAreas()
    end, AlienSpawnInterval)

    -- process timer for all aliens
    CreateTimer(function()
        for _,npc in pairs(GetAllNPC()) do
            if (GetNPCPropertyValue(npc, 'type') == 'alien') then
                ResetAlien(npc)
            end
        end
    end, 10000)
end


function SpawnAlienAreas()
    -- destroy any existing aliens
    for _,npc in pairs(GetAllNPC()) do
        if (GetNPCPropertyValue(npc, 'type') == 'alien') then
            -- only destroy aliens not currently attacking
            if (GetNPCPropertyValue(npc, 'target') == nil) then
                DestroyNPC(npc)
            end
        end
    end

    print "Spawning aliens..."

    -- create alien npcs
    for _,pos in pairs(AlienLocations) do
        local x,y = randomPointInCircle(pos[1], pos[2], 10000)
        SpawnAlien(x, y, pos[3]+100)
    end
end

function SpawnAlien(x, y, z)
    --CreateObject(303, x, y, z+100, 0, 0, 0, 10, 10, 200) -- TODO remove me
    local npc = CreateNPC(x, y, z+100, 90)
    SetNPCHealth(npc, AlienHealth)
    SetNPCRespawnTime(npc, AlienRespawnTime)
    SetNPCPropertyValue(npc, 'clothing', math.random(23, 24))
    SetNPCPropertyValue(npc, 'type', 'alien')
    SetNPCPropertyValue(npc, 'location', { x, y, z })
end

function OnNPCSpawn(npc)
    if GetNPCPropertyValue(npc, 'type') == 'alien' then
        SetNPCHealth(npc, AlienHealth)

        local x,y,z = GetNPCLocation(npc)
        SetNPCPropertyValue(npc, 'location', { x, y, z })
    end
end
AddEvent("OnNPCSpawn", OnNPCSpawn)

-- damage aliens
AddEvent("OnNPCDamage", function(npc, damagetype, amount)
    -- stop alien temporarily when damaged
    local x, y, z = GetNPCLocation(npc)
    SetNPCTargetLocation(npc, x, y, z)

    local health = GetNPCHealth(npc)
    if (health > 0) then
        -- keep attacking if still alive
        Delay(500, function(npc)
            ResetAlien(npc)
        end, npc)
    end
end)

AddEvent("OnNPCDeath", function(npc, killer)
    if killer ~= 0 then
        CallRemoteEvent(killer, 'AlienNoLongerAttacking')
        AddPlayerChatAll(GetPlayerName(killer) .. ' has killed an alien!')
        print(GetPlayerName(killer) .. ' has killed an alien')
    end
    SetNPCPropertyValue(npc, 'target', nil, true)
end)

function ResetAlien(npc)
    health = GetNPCHealth(npc)
    if (health == false or health <= 0) then
        return
    end

    local target, nearest_dist = GetNearestPlayer(npc)
    if (target~=0 and not IsPlayerDead(target)) then
        if (nearest_dist < AlienAttackRange) then
            SetNPCPropertyValue(npc, 'target', target, true)

            local veh = GetPlayerVehicle(target)
            if veh == 0 then
                SetNPCFollowPlayer(npc, target, 350)
            else
                SetNPCFollowVehicle(npc, veh, 400)
                if (nearest_dist < 2000) then
                    -- force player out of vehicle and disable it
                    RemovePlayerFromVehicle(target)
                    SetVehicleDamage(veh, math.random(1,8), 1.0)
                    -- remove it from game
                    Delay(60000, function()
                        DestroyVehicle(veh)
                    end)
                end
            end
            CallRemoteEvent(target, 'AlienAttacking', npc)
        elseif (GetNPCPropertyValue(npc, 'target') == target) then
            -- target is out of range, alien is sad
            local x, y, z = GetNPCLocation(npc)
            SetNPCTargetLocation(npc, x, y, z)
            SetNPCPropertyValue(npc, 'target', nil, true)
            CallRemoteEvent(target, 'AlienNoLongerAttacking', npc)
            -- wait a bit then walk back home, little alien
            Delay(15000, function()
                local location = GetNPCPropertyValue(npc, 'location')
                SetNPCTargetLocation(npc, location[1], location[2], location[3], 100)
            end)
        end
    end
end

-- kills players when reached
function OnNPCReachTarget(npc)
    local target = GetNPCPropertyValue(npc, 'target')
    if target ~= nil then
        if (not IsPlayerDead(target)) then
            -- insta-kill
            SetNPCAnimation(npc, "KUNGFU", true)
            SetPlayerHealth(target, 0)
            Delay(2000, function()
                SetNPCAnimation(npc, "DANCE12", true)
            end)
            Delay(8000, function()
                AlienReturn(npc)
            end)
        else
            -- player already dead, go home
            AlienReturn(npc)
        end
    end
end
AddEvent("OnNPCReachTarget", OnNPCReachTarget)

-- return alien back to starting position
function AlienReturn(npc)
    SetNPCAnimation(npc, "STOP", true)
    SetNPCPropertyValue(npc, 'target', nil, true)

    local location = GetNPCPropertyValue(npc, 'location')
    SetNPCTargetLocation(npc, location[1], location[2], location[3], 800)
end

-- get nearest player to npc
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