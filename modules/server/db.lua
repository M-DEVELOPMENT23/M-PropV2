local props = {}
local ready = false
local RESOURCE_NAME = GetCurrentResourceName()

local function boolInt(b) return (b == true or b == 1) and 1 or 0 end
local function intBool(i) return (i == 1 or i == true) end

local function hasPermission(source)
    local aces = Config.AllowedAces or { "propcreator.admin" }
    for _, ace in ipairs(aces) do
        if IsPlayerAceAllowed(source, ace) then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- STARTUP: DEBUG DIAGNOSTICS + DATABASE INIT + PROP LOADING
-- ═══════════════════════════════════════════════════════════
CreateThread(function()
    Wait(500)

    local version = GetResourceMetadata(RESOURCE_NAME, "version", 0) or "unknown"
    local divider = "^7══════════════════════════════════════════════════"

    print(divider)
    print(("^5[M-PropV2]^0 Starting v%s — Debug Diagnostics"):format(version))
    print(divider)

    -- 1) Check dependencies
    local deps = { "oxmysql", "ox_lib" }
    local depsOk = true
    for _, dep in ipairs(deps) do
        local state = GetResourceState(dep)
        local ok = (state == "started")
        if not ok then depsOk = false end
        local color = ok and "^2" or "^1"
        print(("%s[M-PropV2]^0  ├─ %s: %s%s^0"):format(color, dep, color, state))
    end

    if not depsOk then
        print("^1[M-PropV2]^0  └─ ^1Missing dependencies! Aborting startup.^0")
        print(divider)
        ready = true
        return
    end

    -- 2) Auto-create database table
    print("^5[M-PropV2]^0  ├─ Checking database table...")
    local createOk, createErr = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `m_props_created` (
                `propid`   INT(11)       NOT NULL AUTO_INCREMENT,
                `propname` VARCHAR(255)  NOT NULL,
                `x`        FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `y`        FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `z`        FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `rotX`     FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `rotY`     FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `rotZ`     FLOAT(12,6)   NOT NULL DEFAULT 0.000000,
                `scale`    FLOAT(12,6)   NOT NULL DEFAULT 1.000000,
                `freeze`   TINYINT(1)    NOT NULL DEFAULT 1,
                `colision` TINYINT(1)    NOT NULL DEFAULT 1,
                PRIMARY KEY (`propid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    if createOk then
        print("^2[M-PropV2]^0  ├─ Database table: ^2OK^0")
    else
        print("^1[M-PropV2]^0  ├─ Database table: ^1FAILED^0")
        print(("^1[M-PropV2]^0  │   Error: %s"):format(tostring(createErr)))
    end

    -- 3) Load existing props
    local loadOk, result = pcall(function()
        return MySQL.query.await("SELECT * FROM m_props_created")
    end)

    if loadOk and result then
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
        print(("^2[M-PropV2]^0  ├─ Props loaded: ^2%d^0"):format(#result))
    else
        print("^1[M-PropV2]^0  ├─ Props loaded: ^1FAILED^0")
        if not loadOk then
            print(("^1[M-PropV2]^0  │   Error: %s"):format(tostring(result)))
        end
    end

    -- 4) Allowed ACEs info
    local acesStr = table.concat(Config.AllowedAces or { "propcreator.admin" }, ", ")
    print(("^5[M-PropV2]^0  └─ Allowed ACEs: ^3%s^0"):format(acesStr))

    print(divider)
    print("^2[M-PropV2]^0 Startup complete.")
    print(divider)

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