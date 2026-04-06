
if not IsDuplicityVersion() then return end

local RESOURCE_NAME = GetCurrentResourceName()
local MANIFEST_URL = "https://raw.githubusercontent.com/M-DEVELOPMENT23/M-PropV2/main/fxmanifest.lua"

local function CheckVersion()
    local currentVersion = GetResourceMetadata(RESOURCE_NAME, "version", 0) or "unknown"

    PerformHttpRequest(MANIFEST_URL, function(statusCode, response)
        -- statusCode can be number or string depending on runtime
        local code = tonumber(statusCode) or 0

        if code ~= 200 or not response then
            print("^3[M-PropV2]^0 Version check skipped (GitHub unreachable).")
            return
        end

        -- Parse version from fxmanifest: version 'x.y.z' or version "x.y.z"
        -- Use \n anchor to avoid matching fx_version 'cerulean'
        local latestVersion = response:match("\nversion%s+['\"]([^'\"]+)['\"]")

        if not latestVersion then
            print("^3[M-PropV2]^0 Version check skipped (could not parse remote version).")
            return
        end

        latestVersion = latestVersion:gsub("%s+", "")

        print("^7------------------------------------------------------------^0")
        print("^5[M-PropV2]^0 Version Check")

        if latestVersion == currentVersion then
            print(("^2[M-PropV2]^0 You are running the latest version (^3%s^0)"):format(currentVersion))
        else
            print("^1[M-PropV2]^0 Outdated version detected!")
            print(("^1[M-PropV2]^0 Current: ^3%s^0 | Latest: ^2%s^0"):format(currentVersion, latestVersion))
            print("^1[M-PropV2]^0 Update here:")
            print("^4https://github.com/M-DEVELOPMENT23/M-PropV2^0")
        end

        print("^7------------------------------------------------------------^0")
    end, "GET")
end

CreateThread(function()
    Wait(3000)
    CheckVersion()
end)

