local MODE = MODE

MODE.name = "ww2tdm"
MODE.base = "tdm"
MODE.PrintName = "WW2 Team Deathmatch"

-- This mode has fixed loadouts and no TDM buy phase.
function MODE:HG_MovementCalc_2()
end
