local EVENT_NAMES = {
    CREATE_REMOVE_MENU = 'm:propcreator:createremovemenu',
    REMOVE_PROP = 'm:propcreator:RemoveProp',
    REQUEST_PROPS = 'm:propcreator:RequestProps',
    OPEN_MENU = 'm:propcreator:openmenu',
    DELETE_ALL_PROPS = 'm:propcreator:DeleteAllProps'
}

local function CreateRemovePropsMenu(props)
    if not props or #props == 0 then
        lib.notify({ description = Configuration.Translations.NoPropsOnDB, type = 'error' })
        return
    end

    local options = {}

    for _, prop in ipairs(props) do
        table.insert(options, {
            title = prop.propname,
            metadata = {
                { label = Configuration.Translations.Collisions, value = string.format("[%.2f, %.2f, %.2f]", prop.x, prop.y, prop.z) },
                { label = Configuration.Translations.PropIDName, value = prop.propid },
                { label = Configuration.Translations.Heading, value = prop.heading },
                { label = Configuration.Translations.Frozen, value = prop.freeze and "Yes" or "No" },
                { label = Configuration.Translations.Collisions, value = prop.colision and "Enabled" or "Disabled" }
            },
            icon = 'box',
            onSelect = function()
                TriggerServerEvent(EVENT_NAMES.REMOVE_PROP, prop.propid)
                TriggerServerEvent(EVENT_NAMES.REQUEST_PROPS, "creator")
            end
        })
    end

    lib.registerContext({
        id = 'prop_remove_menu',
        title = Configuration.Translations.RemovePropsMenuTitle,
        options = options
    })

    lib.showContext('prop_remove_menu')
end

RegisterNetEvent(EVENT_NAMES.CREATE_REMOVE_MENU, CreateRemovePropsMenu)

RegisterNetEvent(EVENT_NAMES.OPEN_MENU, function()
    ShowPropCreatorMenu()
end)

if Configuration.Framework == "QBCore" then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerServerEvent(EVENT_NAMES.REQUEST_PROPS, "creator")
    end)
elseif Config.Framework == "ESX" then
    Configuration('esx:playerLoaded', function()
        TriggerServerEvent(EVENT_NAMES.REQUEST_PROPS, "creator")
    end)
end


AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        TriggerEvent(EVENT_NAMES.DELETE_ALL_PROPS)
    end
end)
