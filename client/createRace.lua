cur_waypoint = 0
next_cur_waypoint = 0
timerHud = 0
showTimer = false
freezeCar = false

first = true
function sendWaypoint(x, y, z, target, race_len)
    if next_cur_waypoint > 0 then
        next_cur_waypoint = cur_waypoint
        cur_waypoint = CreateWaypoint(x, y, z, "CheckPoint "..target.."/"..race_len)
    else
        next_cur_waypoint = cur_waypoint
        cur_waypoint = CreateWaypoint(x, y, z, "CheckPoint "..target.."/"..race_len)
    end
end
AddRemoteEvent("sendwaypoint", sendWaypoint)

function removeAllWaypoint()
    for k,v in pairs(GetAllWaypoints()) do
        DestroyWaypoint(v)
    end
end
AddRemoteEvent("removeallwaypoint", removeAllWaypoint)

function createHud()
    timerHud = CreateTextBox(-15, 180, "Starting in..", "right")
    SetTextBoxAnchors(timerHud, 1.0, 0.0, 1.0, 0.0)
    SetTextBoxAlignment(timerHud, 1.0, 0.0)
end
AddRemoteEvent("createcountdown", createHud)

function startcountdown(timecountdwn)
    SetTextBoxText(timerHud, "Starting in "..timecountdwn)
end
AddRemoteEvent("startcountdown", startcountdown)

function toggleTimerhud()
    showTimer = not showTimer
    
    if showTimer then
        time_ms, time_s, time_m = 0, 0, 0
        timer = CreateTimer(function()
            if time_ms < 100 then 
                time_ms = time_ms + 1
            else
                time_ms = 0
                time_s = time_s + 1
            end
            if time_s > 60 then 
                time_s = 0
                time_m = time_m + 1
            end

            SetTextBoxText(timerHud, "Time: "..time_m..":"..time_s..":"..time_ms)
        end, 10)
    else
        AddPlayerChat("You've done the course in "..time_m..":"..time_s..":"..time_ms)
        DestroyTimer(timer)
    end
end
AddRemoteEvent("starttimer", toggleTimerhud)

function rmhudtimer()
    DestroyTextBox(timerHud)
end
AddRemoteEvent("rmhudtimer", rmhudtimer)
