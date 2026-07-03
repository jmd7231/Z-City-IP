local MODE = MODE

MODE.name = "revolutionarywar"
MODE.base = "tdm"
MODE.PrintName = "Revolutionary War"

-- TDM normally forces players to use their hands during its 20-second buy phase.
-- This mode has a fixed loadout and no buy phase, so weapons are usable immediately.
function MODE:HG_MovementCalc_2()
end
