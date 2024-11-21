print("\n\n")

local MOTOR = "back"               -- side where electric start motor is connected
local BUNDLE = "front"             -- side where bundled wire is connected
local FUEL_SHUTOFF = colors.red    -- steam engine fuel supply
local LOAD_SHUTOFF = colors.orange -- accumulators
local FUEL_REMOVAL = colors.lime   -- steam engine fuel drain (power on to drain)
local MODE_TOGGLE  = colors.blue   -- when powered, manual, otherwise automatic
local MANUAL_STATE = colors.lightBlue -- powered: on, unpowered: off

-- bundled wire target state
local sided_bundle_state = {}

local is_running = true
local load_failed = false

local function find_accumulators()
    return { peripheral.find("createaddition:modular_accumulator") }
end

local accumulators = find_accumulators()



local function get_stored_energy()
    local energy = 0
    for _, accumulator in pairs(accumulators) do
        energy = energy + accumulator.getEnergy()
    end
    return energy
end

local function get_total_capacity()
    local capacity = 0
    for _, accumulator in pairs(accumulators) do
        capacity = capacity + accumulator.getEnergyCapacity()
    end
    return capacity
end

local function are_any_below(percent)
    for _, accumulator in pairs(accumulators) do
        if (accumulator.getEnergy() / accumulator.getEnergyCapacity()) < percent then
            return true
        end
    end
    return false
end

local function are_all_above(percent)
    return not are_any_below(percent)
end

---sets output of a side based on the state
---@param side string
---@param color integer
---@param state boolean
local function setBundledColor(side, color, state)
    local current = sided_bundle_state[side] or 0
    if state then
        current = colors.combine(current, color)
    else
        current = colors.subtract(current, color)
    end
    redstone.setBundledOutput(side, current)
    sided_bundle_state[side] = current
end


---gets input from a side
---@param side string
---@param color integer
---@return boolean
local function getBundledColor(side, color)
    local current = redstone.getBundledInput(side)
    return colors.test(current, color)
end

---emits a 1-redstone-tick pulse to a bundled wire
---@param side string
---@param color integer
local function pulseColor(side, color)
    setBundledColor(side, color, true)
    sleep(0.1)
    setBundledColor(side, color, false)
end

---emits a 1-redstone-tick pulse on the given side
---@param side string
local function pulseSide(side)
    redstone.setOutput(side, true)
    sleep(0.1)
    redstone.setOutput(side, false)
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

    -- disable fuel
    print(" - Disabling fuel")
    setBundledColor(BUNDLE, FUEL_SHUTOFF, true)

    -- drain fuel
    print(" - Enabling fuel drain")
    setBundledColor(BUNDLE, FUEL_REMOVAL, true)

    set_state(false)
end

local function start_powerplant()
    print("Starting up powerplant")

    -- disable accumulators
    print(" - Disabling accumulators")
    setBundledColor(BUNDLE, LOAD_SHUTOFF, true)

    -- prevent fuel drain
    print(" - Disabling fuel drain")
    setBundledColor(BUNDLE, FUEL_REMOVAL, false)

    -- enable fuel
    print(" - Enabling fuel")
    setBundledColor(BUNDLE, FUEL_SHUTOFF, false)

    -- start motors
    print(" - Starting motor")
    pulseSide(MOTOR)

    print(" - Waiting 5 seconds for powerplant start")
    sleep(5)

    -- enable accumulators
    print(" - Enabling accumulators")
    setBundledColor(BUNDLE, LOAD_SHUTOFF, false)

    set_state(true)
end

local function step()
    local manual_mode = getBundledColor(BUNDLE, MODE_TOGGLE)

    if load_failed then
        load_failed = false
        shutdown_powerplant()
    elseif manual_mode then
        local target_state = getBundledColor(BUNDLE, MANUAL_STATE)
        if is_running and (not target_state) then
            shutdown_powerplant()
        elseif (not is_running) and target_state then
            start_powerplant()
        end
    elseif is_running then
        if are_all_above(0.90) then
            shutdown_powerplant()
        end
    else
        if are_any_below(0.50) then
            start_powerplant()
        end
    end
end

while true do
    print("\n\n==========================\nRunning checks")
    accumulators = find_accumulators()
    step()

    print("\nStored energy: "..get_stored_energy().."/"..get_total_capacity())

    sleep(5)
end

print("Powerplant execution complete")
