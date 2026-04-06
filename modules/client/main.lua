local props = {}
local spawned = {}
local spawnedRev = {}
local undoStack = {}
local gridMap = {}
local isAdmin = false
local isEditorMode = false
local isGizmoActive = false
local targetInitialized = false
local Strings = Config.Lang
local CELL_SIZE = Config.Streaming.GridSize
local function debugLog(...)
    if Config.DebugMode then
        print("^3[DEBUG]^7", ...)
    end
end
local function notify(msg, type)
    lib.notify({ description = msg, type = type or 'inform' })
end
local function getGridKey(x, y)
    return ("%d_%d"):format(math.floor(x / CELL_SIZE), math.floor(y / CELL_SIZE))
end
local function normalizeRow(row)
    if not row then return nil end
    return {
        propid = tostring(row.propid),
        propname = tostring(row.propname),
        x = tonumber(row.x), y = tonumber(row.y), z = tonumber(row.z),
        rotX = tonumber(row.rotX) or 0.0, rotY = tonumber(row.rotY) or 0.0, rotZ = tonumber(row.rotZ) or 0.0,
        scale = tonumber(row.scale) or 1.0,
        freeze = (row.freeze == true or row.freeze == 1 or row.freeze == "1"),
        colision = (row.colision == true or row.colision == 1 or row.colision == "1")
    }
end
local function pushUndo(actionType, dataBefore, dataAfter)
    table.insert(undoStack, { type = actionType, before = dataBefore, after = dataAfter })
    if #undoStack > 20 then table.remove(undoStack, 1) end
end
local function loadModelSafe(model)
    local hash = (type(model) == 'number') and model or GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do 
        Wait(0) 
        if GetGameTimer() > timeout then return false end 
    end
    return true
end
local function applyEntityProperties(ent, meta)
    if not DoesEntityExist(ent) then return end
    SetEntityRotation(ent, meta.rotX, meta.rotY, meta.rotZ, 2, true)
    if meta.scale and meta.scale ~= 1.0 then
        local f, r, u, pos = GetEntityMatrix(ent)
        if f and r and u and pos then
            SetEntityMatrix(ent, 
                f.x * meta.scale, f.y * meta.scale, f.z * meta.scale, 
                r.x * meta.scale, r.y * meta.scale, r.z * meta.scale, 
                u.x * meta.scale, u.y * meta.scale, u.z * meta.scale, 
                pos.x, pos.y, pos.z
            )
        else
            debugLog("Error obteniendo matriz para escalar entidad:", ent)
        end
    end
    FreezeEntityPosition(ent, meta.freeze)
    if not meta.freeze then 
        ActivatePhysics(ent) 
        SetEntityDynamic(ent, true) 
    end
    SetEntityCollision(ent, meta.colision, meta.colision)
    SetEntityLodDist(ent, 1000)
    if not DecorIsRegisteredAsType("M_PROP_CREATOR_ID", 3) then DecorRegister("M_PROP_CREATOR_ID", 3) end
    DecorSetInt(ent, "M_PROP_CREATOR_ID", tonumber(meta.propid) or 0)
end
local function despawnLocal(pid)
    local ent = spawned[pid]
    if ent then
        if DoesEntityExist(ent) then DeleteEntity(ent) end
        spawned[pid] = nil
        spawnedRev[ent] = nil
    end
end
local function spawnLocal(meta)
    if spawned[meta.propid] and DoesEntityExist(spawned[meta.propid]) then return end
    if loadModelSafe(meta.propname) then
        local obj = CreateObjectNoOffset(meta.propname, meta.x, meta.y, meta.z, false, false, false)
        applyEntityProperties(obj, meta)
        spawned[meta.propid] = obj
        spawnedRev[obj] = meta.propid
        if Config.Streaming.FadeIn then
            SetEntityAlpha(obj, 0, false)
            for i=0, 255, 25 do
                if not DoesEntityExist(obj) then break end
                SetEntityAlpha(obj, i, false)
                Wait(10)
            end
            if DoesEntityExist(obj) then ResetEntityAlpha(obj) end
        end
    end
end
local function updateGrid(meta, remove)
    local key = getGridKey(meta.x, meta.y)
    if not gridMap[key] then gridMap[key] = {} end
    if remove then
        gridMap[key][meta.propid] = nil
    else
        gridMap[key][meta.propid] = meta
    end
end
CreateThread(function()
    while true do
        Wait(1000)
        if not isAdmin then 
            Wait(2000) 
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local gx, gy = math.floor(coords.x / CELL_SIZE), math.floor(coords.y / CELL_SIZE)
            local activeProps = {}
            for x = gx - 1, gx + 1 do
                for y = gy - 1, gy + 1 do
                    local key = ("%d_%d"):format(x, y)
                    if gridMap[key] then
                        for id, meta in pairs(gridMap[key]) do
                            local dist = #(coords - vector3(meta.x, meta.y, meta.z))
                            if dist <= Config.Streaming.SpawnRadius then
                                activeProps[id] = true
                                if not spawned[id] then spawnLocal(meta) end
                            elseif dist > Config.Streaming.DespawnRadius then
                                if spawned[id] then despawnLocal(id) end
                            end
                        end
                    end
                end
            end
            for id, ent in pairs(spawned) do
                if not activeProps[id] and DoesEntityExist(ent) then
                    local pCoords = GetEntityCoords(ent)
                    if #(coords - pCoords) > Config.Streaming.DespawnRadius then
                        despawnLocal(id)
                    end
                end
            end
        end
    end
end)
local function getPropsInRadius(coords, radius, modelFilter)
    local found = {}
    local hashFilter = modelFilter and GetHashKey(modelFilter) or nil
    for id, meta in pairs(props) do
        local pCoords = vector3(meta.x, meta.y, meta.z)
        if #(coords - pCoords) <= radius then
            if not hashFilter or GetHashKey(meta.propname) == hashFilter then
                table.insert(found, { id = id, meta = meta, dist = #(coords - pCoords) })
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    return found
end
local function executeMassDelete(listIds)
    if not listIds or #listIds == 0 then return notify(Strings.NothingFound, "error") end
    local confirm = lib.alertDialog({
        header = Strings.DeleteWarning,
        content = (Strings.DeleteWarning .. '\nTotal: ' .. #listIds),
        centered = true,
        cancel = true
    })
    if confirm == 'confirm' then
        local count = 0
        lib.showTextUI(Strings.MassDeleteStart, { position = "top-center", style = { backgroundColor = "#ff4d4d", color = "white" } })
        for i, pid in ipairs(listIds) do
            if i % 5 == 0 then 
                lib.showTextUI((Strings.DeletingUI):format(i, #listIds)) 
            end
            local success = false
            local removed = nil
            local ok, result = pcall(function()
                return lib.callback.await("m:propcreator:removeProp", false, pid)
            end)
            if ok and result then
                removed = result
                success = true
                pushUndo("delete", normalizeRow(removed), nil)
                local idStr = tostring(pid)
                if props[idStr] then
                    updateGrid(props[idStr], true)
                    props[idStr] = nil
                end
                despawnLocal(idStr)
                count = count + 1
            else
                debugLog("Failed to delete ID:", pid)
            end
            Wait(Config.MassDeleteDelay)
        end
        lib.hideTextUI()
        notify((Strings.MassDeleteDone):format(count, #listIds), "success")
    end
end
local function editPropFlow(propid)
    local meta = props[tostring(propid)]
    if not meta then return end
    isGizmoActive = true
    lib.hideTextUI()
    despawnLocal(propid)
    local obj = CreateObjectNoOffset(meta.propname, meta.x, meta.y, meta.z, false, false, false)
    applyEntityProperties(obj, meta)
    SetEntityAlpha(obj, 200, false)
    SetEntityCollision(obj, false, false) 
    FreezeEntityPosition(obj, true)
    local result = exports["M-PropV2"]:useGizmo(obj)
    if result and not result.cancelled then
        local coords = GetEntityCoords(obj)
        local rot = GetEntityRotation(obj, 2)
        local scale = tonumber(result.scale) or meta.scale
        local updated = lib.callback.await("m:propcreator:updateProp", false, meta.propid, 
            coords.x, coords.y, coords.z, 
            rot.x, rot.y, rot.z, 
            meta.colision, meta.freeze, scale
        )
        if updated then
            pushUndo("update", meta, updated)
            notify(Strings.Updated, "success")
        end
    end
    if DoesEntityExist(obj) then DeleteEntity(obj) end
    isGizmoActive = false
    if props[propid] then spawnLocal(props[propid]) end
end
local function createPropFlow(model, freeze, collision, groundSnap)
    if not loadModelSafe(model) then return notify(Strings.ModelInvalid, 'error') end
    isGizmoActive = true
    lib.hideTextUI()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 3.0)
    local tempObj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    if groundSnap then 
        SetEntityCoords(tempObj, coords.x, coords.y, coords.z)
        PlaceObjectOnGroundProperly(tempObj) 
    end
    SetEntityAlpha(tempObj, Config.Placement.PreviewAlpha, false)
    SetEntityCollision(tempObj, false, false)
    local result = exports["M-PropV2"]:useGizmo(tempObj)
    if result and not result.cancelled then
        local fPos = GetEntityCoords(tempObj)
        local fRot = GetEntityRotation(tempObj, 2)
        local fScl = tonumber(result.scale) or 1.0
        local newRow = lib.callback.await("m:propcreator:createProp", false, model, fPos.x, fPos.y, fPos.z, fRot.x, fRot.y, fRot.z, collision, freeze, fScl)
        if newRow then
            pushUndo("create", nil, normalizeRow(newRow))
            notify(Strings.Created, "success")
        end
    end
    DeleteEntity(tempObj)
    isGizmoActive = false
end
local function openPropListMenu(filter)
    local ped = PlayerPedId()
    local nearby = getPropsInRadius(GetEntityCoords(ped), 20.0, filter)
    local options = {}
    if #nearby == 0 then
        table.insert(options, { title = Strings.NothingFound, disabled = true })
    else
        table.insert(options, {
            title = ("%s (%d)"):format(Strings.DeleteAllRadius, #nearby),
            icon = "triangle-exclamation",
            iconColor = "red",
            onSelect = function()
                local ids = {}
                for _, v in ipairs(nearby) do table.insert(ids, v.id) end
                executeMassDelete(ids)
            end
        })
        for _, data in ipairs(nearby) do
            table.insert(options, {
                title = ("%s | ID: %s"):format(data.meta.propname, data.id),
                description = ("Dist: %.2fm"):format(data.dist),
                icon = 'cube',
                onSelect = function()
                    lib.registerContext({
                        id = 'm_prop_action_'..data.id,
                        title = data.meta.propname,
                        menu = 'm_prop_list',
                        options = {
                            {
                                title = Strings.Teleport,
                                icon = 'location-dot',
                                onSelect = function()
                                    SetEntityCoords(ped, data.meta.x, data.meta.y, data.meta.z)
                                end
                            },
                            {
                                title = Strings.EditGizmo,
                                icon = 'pen-ruler',
                                onSelect = function() editPropFlow(data.id) end
                            },
                            {
                                title = Strings.DeleteProp,
                                icon = 'trash',
                                iconColor = 'red',
                                onSelect = function()
                                    local removed = lib.callback.await("m:propcreator:removeProp", false, data.id)
                                    if removed then 
                                        pushUndo("delete", normalizeRow(removed), nil)
                                        notify(Strings.Deleted, "success")
                                        openPropListMenu(filter)
                                    end
                                end
                            }
                        }
                    })
                    lib.showContext('m_prop_action_'..data.id)
                end
            })
        end
    end
    lib.registerContext({
        id = 'm_prop_list',
        title = '📋 Props List',
        menu = 'm_prop_advanced',
        options = options
    })
    lib.showContext('m_prop_list')
end
local function openMainMenu()
    if not isAdmin then 
        isAdmin = lib.callback.await("m:propcreator:canUse", false) 
        if isAdmin then setupTarget() end
    end
    
    if not isAdmin then return notify(Strings.NoPerms, "error") end

    lib.registerContext({
        id = 'm_prop_main',
        title = Strings.MenuTitle,
        options = {
            {
                title = Strings.EditorMode .. ': ' .. (isEditorMode and 'ON' or 'OFF'),
                icon = isEditorMode and 'toggle-on' or 'toggle-off',
                iconColor = isEditorMode and '#00ff00' or '#ff0000',
                description = Strings.EditorDesc,
                onSelect = function()
                    isEditorMode = not isEditorMode
                    openMainMenu()
                end
            },
            {
                title = Strings.NewProp,
                icon = 'plus',
                onSelect = function()
                    local input = lib.inputDialog(Strings.NewProp, {
                        {type='input', label=Strings.InputModel, required=true},
                        {type='checkbox', label=Strings.InputFreeze, checked=true},
                        {type='checkbox', label=Strings.InputCol, checked=true},
                        {type='checkbox', label=Strings.InputSnap, checked=true}
                    })
                    if input then createPropFlow(input[1], input[2], input[3], input[4]) end
                end
            },
            {
                title = Strings.AdvTools,
                icon = 'toolbox',
                description = Strings.AdvDesc,
                onSelect = function()
                    lib.registerContext({
                        id = 'm_prop_advanced',
                        title = Strings.AdvTools,
                        menu = 'm_prop_main',
                        options = {
                            {
                                title = Strings.SearchProps,
                                icon = 'magnifying-glass',
                                onSelect = function() openPropListMenu(nil) end
                            },
                            {
                                title = Strings.DeleteAllRadius,
                                icon = 'bomb',
                                iconColor = '#ff4d4d',
                                onSelect = function()
                                    local input = lib.inputDialog(Strings.DeleteAllRadius, {
                                        {type = 'number', label = Strings.InputRadius, default = 5, min = 1, max = 50}
                                    })
                                    if input then
                                        local targets = getPropsInRadius(GetEntityCoords(PlayerPedId()), input[1], nil)
                                        local ids = {}
                                        for _, t in ipairs(targets) do table.insert(ids, t.id) end
                                        executeMassDelete(ids)
                                    end
                                end
                            },
                            {
                                title = Strings.DeleteModelRadius,
                                icon = 'filter',
                                onSelect = function()
                                    local input = lib.inputDialog(Strings.DeleteModelRadius, {
                                        {type = 'input', label = Strings.InputModel, required = true},
                                        {type = 'number', label = Strings.InputRadius, default = 10, min = 1, max = 100}
                                    })
                                    if input then
                                        local targets = getPropsInRadius(GetEntityCoords(PlayerPedId()), input[2], input[1])
                                        local ids = {}
                                        for _, t in ipairs(targets) do table.insert(ids, t.id) end
                                        executeMassDelete(ids)
                                    end
                                end
                            }
                        }
                    })
                    lib.showContext('m_prop_advanced')
                end
            },
            {
                title = Strings.UndoLast,
                icon = 'rotate-left',
                disabled = #undoStack == 0,
                description = (Strings.History):format(#undoStack),
                onSelect = function()
                    local act = table.remove(undoStack)
                    if not act then return end
                    if act.type == 'create' then
                        lib.callback.await("m:propcreator:removeProp", false, act.after.propid)
                    elseif act.type == 'delete' then
                        local r = act.before
                        lib.callback.await("m:propcreator:createProp", false, r.propname, r.x, r.y, r.z, r.rotX, r.rotY, r.rotZ, r.colision, r.freeze, r.scale)
                    elseif act.type == 'update' then
                        local r = act.before
                        lib.callback.await("m:propcreator:updateProp", false, r.propid, r.x, r.y, r.z, r.rotX, r.rotY, r.rotZ, r.colision, r.freeze, r.scale)
                    end
                    notify(Strings.Undo)
                    openMainMenu() 
                end
            }
        }
    })
    lib.showContext('m_prop_main')
end
CreateThread(function()
    local sleep
    local colR, colG, colB = 0, 255, 255
    while true do
        sleep = 500
        if isEditorMode and isAdmin and not isGizmoActive then
            sleep = 0
            local ped = PlayerPedId()
            local pPos = GetEntityCoords(ped)
            local closest, closestDist = nil, 10.0
            for id, ent in pairs(spawned) do
                if DoesEntityExist(ent) then
                    local dist = #(pPos - GetEntityCoords(ent))
                    if dist < closestDist then
                        closest = ent
                        closestDist = dist
                    end
                end
            end
            if closest then
                local cPos = GetEntityCoords(closest)
                local pid = spawnedRev[closest] or "?"
                local meta = props[pid]
                DrawLine(pPos.x, pPos.y, pPos.z, cPos.x, cPos.y, cPos.z, colR, colG, colB, 150)
                local min, max = GetModelDimensions(GetEntityModel(closest))
                local topZ = cPos.z + max.z + 0.3
                DrawMarker(2, cPos.x, cPos.y, topZ, 0,0,0, 0,180.0,0, 0.2,0.2,0.2, 0,255,0,200, true, true, 2)
                lib.showTextUI((Strings.PropInfo):format(pid, meta and meta.propname or "Unknown"))
            else
                if lib.isTextUIOpen() then lib.hideTextUI() end
            end
        else
            if lib.isTextUIOpen() and not isGizmoActive then lib.hideTextUI() end
        end
        Wait(sleep)
    end
end)
local function setupTarget()
    if targetInitialized or not Config.UseTarget then return end
    targetInitialized = true
    exports.ox_target:addGlobalObject({
        {
            name = 'm_prop:edit',
            icon = Config.TargetIcons.Edit,
            label = Strings.EditGizmo,
            canInteract = function(entity) 
                return isAdmin and isEditorMode and spawnedRev[entity] and not isGizmoActive
            end,
            onSelect = function(data)
                local pid = spawnedRev[data.entity]
                if pid then editPropFlow(pid) end
            end
        },
        {
            name = 'm_prop:duplicate',
            icon = Config.TargetIcons.Duplicate,
            label = Strings.NewProp .. ' (Clone)',
            canInteract = function(entity) return isAdmin and isEditorMode and spawnedRev[entity] and not isGizmoActive end,
            onSelect = function(data)
                local pid = spawnedRev[data.entity]
                local p = props[pid]
                createPropFlow(p.propname, p.freeze, p.colision, false)
            end
        },
        {
            name = 'm_prop:delete',
            icon = Config.TargetIcons.Delete,
            label = Strings.DeleteProp,
            canInteract = function(entity) return isAdmin and isEditorMode and spawnedRev[entity] and not isGizmoActive end,
            onSelect = function(data)
                local pid = spawnedRev[data.entity]
                if pid then
                    local removed = lib.callback.await("m:propcreator:removeProp", false, pid)
                    if removed then 
                        pushUndo("delete", normalizeRow(removed), nil)
                        notify(Strings.Deleted, "success")
                    end
                end
            end
        }
    })
end
RegisterNetEvent("m:propcreator:client:propAdded", function(row)
    local meta = normalizeRow(row)
    props[meta.propid] = meta
    updateGrid(meta, false)
    if isAdmin and #(GetEntityCoords(PlayerPedId()) - vector3(meta.x, meta.y, meta.z)) < Config.Streaming.SpawnRadius then
        spawnLocal(meta)
    end
end)
RegisterNetEvent("m:propcreator:client:propUpdated", function(row)
    local meta = normalizeRow(row)
    local oldKey = getGridKey(props[meta.propid].x, props[meta.propid].y)
    local newKey = getGridKey(meta.x, meta.y)
    if oldKey ~= newKey then
        updateGrid(props[meta.propid], true)
    end
    props[meta.propid] = meta
    updateGrid(meta, false)
    despawnLocal(meta.propid)
    Wait(50)
    spawnLocal(meta)
end)
RegisterNetEvent("m:propcreator:client:propRemoved", function(pid)
    local id = tostring(pid)
    if props[id] then
        updateGrid(props[id], true)
        props[id] = nil
        despawnLocal(id)
    end
end)
CreateThread(function()
    Wait(1000)
    isAdmin = lib.callback.await("m:propcreator:canUse", false)
    if isAdmin then
        setupTarget()
        local list = lib.callback.await("m:propcreator:getAllProps", false) or {}
        for _, v in ipairs(list) do 
            local meta = normalizeRow(v)
            props[meta.propid] = meta
            updateGrid(meta, false)
        end
    end
end)
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and Config.DeleteOnStop then
        for _, e in pairs(spawned) do DeleteEntity(e) end
    end
end)
RegisterCommand(Config.OpenMenuCommand, openMainMenu)
