vehicle = {}
timer_id = 0
timerHud = 0
data_race = {}

-- get races
local raceData, raceDataErr = io.open("packages/race/server/raceData.lua", "r")

function createRaceTable(s, delimiter1, delimiter2)
    local first = true
    for match in (s..delimiter1):gmatch("(.-)"..delimiter1) do
        if first then
            name = match
            data_race[name] = {}
            first = false
        else
            local cords = {}
            for matchcord in (match..delimiter2):gmatch("(.-)"..delimiter2) do
                table.insert(cords, matchcord);
            end
            table.insert(data_race[name], cords);
        end
    end
    return
end


for line in raceData:lines() do
    createRaceTable(line, ';', ',')
end
io.close(raceData)

function onJoin(playerid)
    vehicle[playerid] = 0
end
AddEvent("OnPlayerJoin", onJoin )

function addcheckpoint(playerid, name, id)
    if GetPlayerVehicle(playerid) == 0 then
        AddPlayerChat(playerid, "You must me in a car to add Checkpoints")
        return
    end

    if not name or name == "help" then
        AddPlayerChat(playerid, "Usage: /addcheckpoint <name> [id]")
        return
    end

    local x, y, z = GetPlayerLocation(playerid)
    local pitch, yaw, roll = GetVehicleRotation(GetPlayerVehicle( playerid ))

    if data_race[name] == nil then
        data_race[name] = {}
        AddPlayerChat(playerid, "Created race: "..name)
    end
    if not id then
        id = tostring(#data_race[name] + 1)
    end
    if data_race[name][tonumber(id)] == nil then
        data_race[name][tonumber(id)] = {x, y, z, pitch, yaw, roll}
        AddPlayerChat(playerid, "New point race: "..name.." "..id..", X:"..x..", Y:"..y..", Z:"..z)
    else
        table.remove( data_race[name], tonumber(id) )
        table.insert( data_race[name], tonumber(id), {x, y, z} )
        AddPlayerChat(playerid, name.." "..id..", X:"..x..", Y:"..y..", Z:"..z)
    end
end
AddCommand("addcheckpoint", addcheckpoint)
AddCommand("acp", addcheckpoint)

function getcheckpoints(playerid, name)
    if not name then
        AddPlayerChat(playerid, "Usage: /getcheckpoints <name>")
        return
    end
    for k, v in pairs(data_race[name]) do
        local x, y, z, rp, ry, rr = table.unpack(v)
        AddPlayerChat(playerid, tostring(k.." X:"..x..", Y:"..y..", Z:"..z))
    end
end
AddCommand("getcheckpoints", getcheckpoints)
AddCommand("gcp", getcheckpoints)

function saverace(playerid, name)
    if not name or #data_race[name] == nil then
        AddPlayerChat(playerid, "Usage: /saverace <name>")
        return
    end
    local raceDataSav, raceDataSavErr = io.open("packages/race/server/raceData.lua", "a")
    raceDataSav:write(name.."; ")
    local first = true
    for k, v in pairs(data_race[name]) do
        local x, y, z
        if first then
            x, y, z, rp, ry, rr = table.unpack(v)
            raceDataSav:write(x..","..y..","..z..","..rp..","..ry..","..rr.."; ")
            first = true
        else
            x, y, z = table.unpack(v)
            raceDataSav:write(x..","..y..","..z.."; ")
        end
    end
    raceDataSav:write("\n")
    io.close(raceDataSav)
    AddPlayerChat(playerid, "Race saved")
end
AddCommand("saverace", saverace)
AddCommand("sr", saverace)

function startSoloRace(playerid, name)
    if not name then
        AddPlayerChat(playerid, "Usage: /startrace <name>")
        return
    end

    if GetPlayerVehicle(playerid) == 0 then
        AddPlayerChat(playerid, "You must me in a car to start a race")
        return
    end

    if #data_race[name] < 2 then
        AddPlayerChat(playerid, "Please choose a race that have a least 2 checkpoints")
        return
    end

    if timer_id > 0 then 
        DestroyTimer( timer_id ) 
        timer_id = 0
    end

    -- TP PLAYER
    local target = 2
    local start_x, start_y , start_z = data_race[name][1][1], data_race[name][1][2], data_race[name][1][3]
    local start_pitch, start_yaw, start_roll = data_race[name][1][4], data_race[name][1][5], data_race[name][1][6]
    local target_x, target_y, target_z = table.unpack(data_race[name][target])
    local last_cp = {start_x, start_y, start_z}
    local cur_x, cur_y, cur_z = GetPlayerLocation( playerid )
    SetVehicleLocation(vehicle[playerid], start_x, start_y , start_z + 30)
    SetVehicleRotation(vehicle[playerid], start_pitch, start_yaw, start_roll)
    
    CallRemoteEvent(playerid, "sendwaypoint", target_x, target_y, target_z, target, #data_race[name] )

    --COUNTDOWN
    local countdownTime = 3
    CallRemoteEvent(playerid, "createcountdown")
    
    
    countdown = CreateTimer(function()
        if countdownTime > 0 then
            CallRemoteEvent(playerid, "startcountdown", countdownTime )
            countdownTime = countdownTime - 1
        else
            DestroyTimer(countdown)
        end
    end, 1000)

    --NXT CP
        CallRemoteEvent(playerid, "starttimer")
        timer_id = CreateTimer(function()
            if target <= #data_race[name] then
                cur_x, cur_y, cur_z = GetPlayerLocation(playerid)
                local dist = GetDistance3D(cur_x, cur_y, cur_z, target_x, target_y, target_z)
                -- AddPlayerChat(playerid, "Dist:"..dist..", Trg:"..target.."last cp:"..tostring(last_cp[1]) )
                if dist < 600.0 and last_cp ~= {target_x, target_y, target_z} then
                    last_cp = {target_x, target_y, target_z}
                    target = target + 1
                    if target > #data_race[name] then
                        CallRemoteEvent(playerid, "removeallwaypoint")
                        CallRemoteEvent(playerid, "starttimer")
                        CallRemoteEvent(playerid, "rmhudtimer")
                        DestroyTimer( timer_id )
                        return
                    else
                        CallRemoteEvent(playerid, "removeallwaypoint")
                        if target ~= #data_race[name] then
                            target_x, target_y, target_z = table.unpack(data_race[name][target+1])
                            CallRemoteEvent(playerid, "sendwaypoint", target_x, target_y, target_z, target+1, #data_race[name] )
                        end
                        target_x, target_y, target_z = table.unpack(data_race[name][target])
                        CallRemoteEvent(playerid, "sendwaypoint", target_x, target_y, target_z, target, #data_race[name] )
                    end
                end
            else
                CallRemoteEvent(playerid, "removeallwaypoint")
                CallRemoteEvent(playerid, "starttimer")
                CallRemoteEvent(playerid, "rmhudtimer")
                DestroyTimer( timer_id )
                return
            end
        end, 200)
end
AddCommand("startsolorace", startSoloRace )
AddCommand("ssr", startSoloRace )

function stopRace()
    DestroyTimer( timer_id )
end
AddCommand("stoprace", stopRace )
AddCommand("str", stopRace )

function spawnVehicle(playerid, vehicleId)
    if not vehicleId then
        AddPlayerChat(playerid, "Usage: /vehicle <id>")
        return
    end

    local x, y, z = GetPlayerLocation(playerid)
    local h = GetPlayerHeading(playerid)
    if vehicle[playerid] ~= nil then
        DestroyVehicle(vehicle[playerid])
        vehicle[playerid] = CreateVehicle(tonumber(vehicleId), x, y, z, h)
    else
        vehicle[playerid] = CreateVehicle(tonumber(vehicleId), x, y, z, h)
    end
    AttachVehicleNitro(vehicle[playerid])
    SetVehicleRespawnParams(vehicle[playerid], false)
    SetPlayerInVehicle(playerid, vehicle[playerid])
end
AddCommand("v", spawnVehicle )
AddCommand("vehicle", spawnVehicle )
