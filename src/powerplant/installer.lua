-- To install: `wget run https://raw.githubusercontent.com/techno-sam/snr_s2_powerplant/main/src/powerplant/installer.lua`
-- check if commands are present

local fs_idx = {
    startup = {
        "30_powerplant.lua"
    },
    "powerplant.lua",
    "installer.lua"
}

---Uninstall a fs table recursively
---@param path string path so far
---@param tbl table
local function uninstall(path, tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            uninstall(path..k.."/", v)
        elseif type(v) == "string" then
            -- fetch from GH
            local fs_path = path..v

            shell.run("rm "..fs_path)
        end
    end
end

if ... == "clean_install" then
    shell.run("rm *")
    shell.run("wget run https://raw.githubusercontent.com/techno-sam/snr_s2_powerplant/main/src/powerplant/installer.lua")
end

if ... == "update" then
    uninstall("/", fs_idx)
    shell.run("wget run https://raw.githubusercontent.com/techno-sam/snr_s2_powerplant/main/src/powerplant/installer.lua")
end

---Install a fs table recursively
---@param path string path so far
---@param tbl table
local function install(path, tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            install(path..k.."/", v)
        elseif type(v) == "string" then
            -- fetch from GH
            local fs_path = path..v
            local gh_path = "https://raw.githubusercontent.com/techno-sam/snr_s2_powerplant/main/src/powerplant"..fs_path

            shell.run("wget "..gh_path.." "..fs_path)
        end
    end
end

install("/", fs_idx)

shell.run("reboot")