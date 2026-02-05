
if not IsDuplicityVersion() then return end

local RESOURCE_NAME = "M-PropV2"
local VERSION_URL = "https://raw.githubusercontent.com/M-DEVELOPMENT23/M-PropV2/main/version.txt"

local function CheckVersion()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "unknown"

    PerformHttpRequest(VERSION_URL, function(statusCode, response)
        if statusCode ~= 200 or not response then
            print("^3[M-PropV2]^0 Version check skipped (GitHub unreachable).")
            return
        end

        local latestVersion = response:gsub("%s+", "")

        print("^7------------------------------------------------------------^0")
        print("^5[M-PropV2]^0 Version Check")

        if latestVersion == currentVersion then
            print(("^2[M-PropV2]^0 You are running the latest version (^3%s^0)"):format(currentVersion))
        else
            print(("^1[M-PropV2]^0 Outdated version detected!"))
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
