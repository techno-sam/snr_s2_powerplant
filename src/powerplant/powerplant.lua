print("\n\n")

local is_running = true
local load_failed = false

local accumulators = { peripheral.find("createaddition:modular_accumulator") }

local function are_any_below(percent)
    for _, accumulator in pairs(accumulators) do
        if (accumulator.getEnergy() / accumulator.getEnergyCapacity() < percent) then
            return true
        end
    end
    return false
end

local function are_all_above(percent)
    return not are_any_below(percent)
end

local function state_str()
    if is_running then
        return "running"
    else
        return "off"
    end
end

-- load running from file
local state_file = fs.open("/powerplant_state.txt", "r")
if state_file then
    is_running = state_file.readLine() == "true"
    state_file.close()

    print("Loaded initial state: "..state_str())
else
    is_running = false
    load_failed = true
    print("Failed to load initial state, assuming off")
end

local function set_state(running)
    is_running = running
    local state_file = fs.open("/powerplant_state.txt", "w")
    state_file.writeLine(is_running)
    state_file.close()
    print("Set state to: "..state_str())
end

local function shutdown_powerplant()
    print("Shutting down powerplant")

    set_state(false)
end

local function start_powerplant()
    print("Starting up powerplant")
    set_state(true)
end

local function step()
    if (load_failed) then
        load_failed = false
        shutdown_powerplant()
    elseif (is_running) then
        if (are_all_above(0.80)) then
            shutdown_powerplant()
        end
    else
        if (are_any_below(0.25)) then
            start_powerplant()
        end
    end
end

step()

print("Powerplant execution complete")