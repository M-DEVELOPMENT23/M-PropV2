local props = {}
local ready = false

local function boolInt(b) return (b == true or b == 1) and 1 or 0 end
local function intBool(i) return (i == 1 or i == true) end

local function hasPermission(source)
    return IsPlayerAceAllowed(source, "propcreator.admin") 
end

CreateThread(function()
    Wait(1000)
    local result = MySQL.query.await("SELECT * FROM m_props_created")

    if not result then
        print("^3[PropCreator]^7 No props found or DB error.")
    else
        for _, v in ipairs(result) do
            local idStr = tostring(v.propid)
            props[idStr] = {
                propid = idStr,
                propname = v.propname,
                x = v.x, y = v.y, z = v.z,
                rotX = v.rotX, rotY = v.rotY, rotZ = v.rotZ,
                scale = v.scale or 1.0,
                freeze = intBool(v.freeze),
                colision = intBool(v.colision)
            }
        end
        print(("^2[PropCreator]^7 Loaded %s props."):format(#result))
    end
    ready = true
end)

lib.callback.register("m:propcreator:getAllProps", function(source)
    if not hasPermission(source) then return nil end
    while not ready do Wait(100) end
    local list = {}
    for _, meta in pairs(props) do table.insert(list, meta) end
    return list
end)

lib.callback.register("m:propcreator:canUse", function(source)
    return hasPermission(source)
end)

lib.callback.register("m:propcreator:createProp", function(source, model, x, y, z, rx, ry, rz, col, frz, scale)
    if not hasPermission(source) then return false end

    scale = scale or 1.0
    local newId = MySQL.insert.await([[
        INSERT INTO m_props_created (propname, x, y, z, rotX, rotY, rotZ, freeze, colision, scale)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { model, x, y, z, rx, ry, rz, boolInt(frz), boolInt(col), scale })

    if not newId then return nil end
    local sId = tostring(newId)

    local data = {
        propid = sId, propname = model,
        x = x, y = y, z = z, rotX = rx, rotY = ry, rotZ = rz,
        scale = scale, freeze = frz, colision = col
    }

    props[sId] = data
    TriggerClientEvent("m:propcreator:client:propAdded", -1, data)
    return data
end)

lib.callback.register("m:propcreator:updateProp", function(source, propid, x, y, z, rx, ry, rz, col, frz, scale)
    if not hasPermission(source) then return false end
    local sId = tostring(propid)
    
    if not props[sId] then return false end

    local affected = MySQL.update.await([[
        UPDATE m_props_created SET x=?, y=?, z=?, rotX=?, rotY=?, rotZ=?, freeze=?, colision=?, scale=? WHERE propid=?
    ]], { x, y, z, rx, ry, rz, boolInt(frz), boolInt(col), scale, sId })

    if affected then
        props[sId].x, props[sId].y, props[sId].z = x, y, z
        props[sId].rotX, props[sId].rotY, props[sId].rotZ = rx, ry, rz
        props[sId].freeze, props[sId].colision, props[sId].scale = frz, col, scale
        TriggerClientEvent("m:propcreator:client:propUpdated", -1, props[sId])
        return props[sId]
    end
    return false
end)

lib.callback.register("m:propcreator:removeProp", function(source, propid)
    if not hasPermission(source) then return false end
    local sId = tostring(propid)

    if props[sId] then
        local oldData = props[sId]
        MySQL.query("DELETE FROM m_props_created WHERE propid = ?", { sId })
        props[sId] = nil
        TriggerClientEvent("m:propcreator:client:propRemoved", -1, sId)
        return oldData
    end
    return false
end)