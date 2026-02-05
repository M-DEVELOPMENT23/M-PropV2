-- CREDITS
-- Andyyy7666: https://github.com/overextended/ox_lib/pull/453
-- AvarianKnight: https://forum.cfx.re/t/allow-drawgizmo-to-be-used-outside-of-fxdk/5091845/8?u=demi-automatic

local dataview = require 'modules.client.dataview'

--========================================================--
-- STATE
--========================================================--

local enableScale = true         
local isCursorActive = false
local gizmoEnabled = false
local currentMode = 'Translate'
local isRelative = false
local currentEntity
local cancelled = false

local WHEEL_STEP = 0.05
local MIN_SCALE = 0.05
local MAX_SCALE = 50.0

lib.locale()

--========================================================--
-- HELPERS
--========================================================--

local function vecLen(x, y, z)
    return math.sqrt(x*x + y*y + z*z)
end

local function normalize(x, y, z)
    local length = vecLen(x, y, z)
    if length == 0 then
        return 0, 0, 0
    end
    return x / length, y / length, z / length
end

local function getEntityUniformScale(entity)
    local f, r, u = GetEntityMatrix(entity)
    local sr = vecLen(r[1], r[2], r[3])
    local sf = vecLen(f[1], f[2], f[3])
    local su = vecLen(u[1], u[2], u[3])
    local s = (sr + sf + su) / 3.0
    if s <= 0.0 then s = 1.0 end
    return s
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = dataview.ArrayBuffer(60)

    view:SetFloat32(0, r[1])
        :SetFloat32(4, r[2])
        :SetFloat32(8, r[3])
        :SetFloat32(12, 0)
        :SetFloat32(16, f[1])
        :SetFloat32(20, f[2])
        :SetFloat32(24, f[3])
        :SetFloat32(28, 0)
        :SetFloat32(32, u[1])
        :SetFloat32(36, u[2])
        :SetFloat32(40, u[3])
        :SetFloat32(44, 0)
        :SetFloat32(48, a[1])
        :SetFloat32(52, a[2])
        :SetFloat32(56, a[3])
        :SetFloat32(60, 1)

    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0),  view:GetFloat32(4),  view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)

    if not enableScale then
        x1, y1, z1 = normalize(x1, y1, z1)
        x2, y2, z2 = normalize(x2, y2, z2)
        x3, y3, z3 = normalize(x3, y3, z3)
    end

    SetEntityMatrix(entity,
        x1, y1, z1,
        x2, y2, z2,
        x3, y3, z3,
        tx, ty, tz
    )
end

local function applyUniformScaleToMatrix(view, targetScale)
    local fx, fy, fz = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local rx, ry, rz = view:GetFloat32(0),  view:GetFloat32(4),  view:GetFloat32(8)
    local ux, uy, uz = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)

    local fnx, fny, fnz = normalize(fx, fy, fz)
    local rnx, rny, rnz = normalize(rx, ry, rz)
    local unx, uny, unz = normalize(ux, uy, uz)

    view:SetFloat32(16, fnx * targetScale)
        :SetFloat32(20, fny * targetScale)
        :SetFloat32(24, fnz * targetScale)
        :SetFloat32(0,  rnx * targetScale)
        :SetFloat32(4,  rny * targetScale)
        :SetFloat32(8,  rnz * targetScale)
        :SetFloat32(32, unx * targetScale)
        :SetFloat32(36, uny * targetScale)
        :SetFloat32(40, unz * targetScale)
end

--========================================================--
-- LOOPS
--========================================================--

local function gizmoLoop(entity)
    if not gizmoEnabled then
        return LeaveCursorMode()
    end

    EnterCursorMode()
    isCursorActive = true

    if IsEntityAPed(entity) then
        SetEntityAlpha(entity, 200)
    else
        SetEntityDrawOutline(entity, true)
    end

    while gizmoEnabled and DoesEntityExist(entity) do
        Wait(0)

        if IsControlJustPressed(0, 47) then
            if isCursorActive then
                LeaveCursorMode()
                isCursorActive = false
            else
                EnterCursorMode()
                isCursorActive = true
            end
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 200, true)
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 202, true)

        if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 202) then
            cancelled = true
            gizmoEnabled = false
            PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            break
        end

        local matrixBuffer = makeEntityMatrix(entity)

        if currentMode == 'Scale' then
            DisableControlAction(0, 14, true) 
            DisableControlAction(0, 15, true) 

            local up = IsDisabledControlJustPressed(0, 15)
            local down = IsDisabledControlJustPressed(0, 14)

            if up or down then
                local currentScale = getEntityUniformScale(entity)
                local delta = (up and WHEEL_STEP or -WHEEL_STEP)
                local targetScale = clamp(currentScale * (1.0 + delta), MIN_SCALE, MAX_SCALE)

                applyUniformScaleToMatrix(matrixBuffer, targetScale)
                applyEntityMatrix(entity, matrixBuffer)
            end
        end

        if currentMode == 'Rotate' and IsControlPressed(0, 21) then
            local rot = GetEntityRotation(entity, 2)
            rot.z = math.floor((rot.z + 22.5) / 45) * 45
            SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, true)
        end

        local changed = Citizen.InvokeNative(
            0xEB2EDCA2,
            matrixBuffer:Buffer(),
            'Editor1',
            Citizen.ReturnResultAnyway()
        )

        if changed then
            if currentMode == 'Scale' then
                local rx, ry, rz = matrixBuffer:GetFloat32(0),  matrixBuffer:GetFloat32(4),  matrixBuffer:GetFloat32(8)
                local fx, fy, fz = matrixBuffer:GetFloat32(16), matrixBuffer:GetFloat32(20), matrixBuffer:GetFloat32(24)
                local ux, uy, uz = matrixBuffer:GetFloat32(32), matrixBuffer:GetFloat32(36), matrixBuffer:GetFloat32(40)

                local sx = vecLen(rx, ry, rz)
                local sy = vecLen(fx, fy, fz)
                local sz = vecLen(ux, uy, uz)

                local newUniformScale = math.max(sx, math.max(sy, sz))
                newUniformScale = clamp(newUniformScale, MIN_SCALE, MAX_SCALE)

                applyUniformScaleToMatrix(matrixBuffer, newUniformScale)
            end

            applyEntityMatrix(entity, matrixBuffer)
        end
    end

    if isCursorActive then LeaveCursorMode() end
    isCursorActive = false

    if DoesEntityExist(entity) then
        if IsEntityAPed(entity) then SetEntityAlpha(entity, 255) end
        SetEntityDrawOutline(entity, false)
    end

    gizmoEnabled = false
    currentEntity = nil
end

--========================================================--
-- UI & EXPORTS
--========================================================--

local function GetVectorText(vectorType)
    if not currentEntity then return 'ERR_NO_ENTITY_' .. (vectorType or "UNK") end
    local label = (vectorType == "coords" and "Position" or "Rotation")
    local vec = (vectorType == "coords" and GetEntityCoords(currentEntity) or GetEntityRotation(currentEntity))
    return ('%s: %.2f, %.2f, %.2f'):format(label, vec.x, vec.y, vec.z)
end

local function textUILoop()
    CreateThread(function()
        while gizmoEnabled do
            Wait(100)
            local modeLine = 'Current Mode: ' .. currentMode .. ' | ' .. (isRelative and 'Relative' or 'World') .. '  \n'
            local scaleLine = ('Scale: %.2f  \n'):format(currentEntity and getEntityUniformScale(currentEntity) or 1.0)

            lib.showTextUI(
                modeLine ..
                GetVectorText("coords") .. '  \n' ..
                GetVectorText("rotation") .. '  \n' ..
                scaleLine ..
                '[G]     - ' .. (isCursorActive and locale("disable_cursor") or locale("enable_cursor")) .. '  \n' ..
                '[W]     - ' .. locale("translate_mode") .. '  \n' ..
                '[R]     - ' .. locale("rotate_mode") .. '  \n' ..
                '[S]     - ' .. locale("scale_mode") .. '  \n' ..
                '[Q]     - ' .. locale("toggle_space") .. '  \n' ..
                '[LALT]  - ' .. locale("snap_to_ground") .. '  \n' ..
                '[ENTER] - ' .. locale("done_editing") .. '  \n'
            )
        end
        lib.hideTextUI()
    end)
end

local function useGizmo(entity)
    cancelled = false
    gizmoEnabled = true
    currentEntity = entity
    textUILoop()
    gizmoLoop(entity)
    return {
        handle = entity,
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity, 2),
        scale = getEntityUniformScale(entity),
        cancelled = cancelled
    }
end

exports("useGizmo", useGizmo)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    gizmoEnabled = false
    cancelled = true
    if isCursorActive then LeaveCursorMode() isCursorActive = false end
    lib.hideTextUI()
end)

lib.addKeybind({ name = '_gizmoSelect', description = locale("select_gizmo_description"), defaultMapper = 'MOUSE_BUTTON', defaultKey = 'MOUSE_LEFT', onPressed = function() if gizmoEnabled then ExecuteCommand('+gizmoSelect') end end, onReleased = function() ExecuteCommand('-gizmoSelect') end })
lib.addKeybind({ name = '_gizmoTranslation', description = locale("translation_mode_description"), defaultKey = 'W', onPressed = function() if gizmoEnabled then currentMode = 'Translate' ExecuteCommand('+gizmoTranslation') end end, onReleased = function() ExecuteCommand('-gizmoTranslation') end })
lib.addKeybind({ name = '_gizmoRotation', description = locale("rotation_mode_description"), defaultKey = 'R', onPressed = function() if gizmoEnabled then currentMode = 'Rotate' ExecuteCommand('+gizmoRotation') end end, onReleased = function() ExecuteCommand('-gizmoRotation') end })
lib.addKeybind({ name = '_gizmoLocal', description = locale("toggle_space_description"), defaultKey = 'Q', onPressed = function() if gizmoEnabled then isRelative = not isRelative ExecuteCommand('+gizmoLocal') end end, onReleased = function() ExecuteCommand('-gizmoLocal') end })
lib.addKeybind({ name = 'gizmoclose', description = locale("close_gizmo_description"), defaultKey = 'RETURN', onReleased = function() if gizmoEnabled then gizmoEnabled = false end end })
lib.addKeybind({ name = 'gizmoSnapToGround', description = locale("snap_to_ground_description"), defaultKey = 'LMENU', onPressed = function() if gizmoEnabled then PlaceObjectOnGroundProperly_2(currentEntity) end end })
lib.addKeybind({ name = '_gizmoScale', description = locale("scale_mode_description"), defaultKey = 'S', onPressed = function() if gizmoEnabled then currentMode = 'Scale' ExecuteCommand('+gizmoScale') end end, onReleased = function() ExecuteCommand('-gizmoScale') end })