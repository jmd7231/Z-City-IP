local MODE = MODE

net.Receive("ZS_RoundStart", function()
	surface.PlaySound("ambient/alarms/warningbell1.wav")
	chat.AddText(Color(130, 220, 90), "[Zombie Survival] ", color_white, "A Zombie Alpha is hunting the survivors.")
end)

net.Receive("ZS_RoundEnd", function()
	local winner = net.ReadString()
	if winner == "zombies" then
		chat.AddText(Color(130, 220, 90), "[Zombie Survival] ", color_white, "The infection consumed everyone.")
	elseif winner == "survivors" then
		chat.AddText(Color(70, 130, 200), "[Zombie Survival] ", color_white, "The Zombie Alpha was killed.")
	else
		chat.AddText(Color(180, 180, 180), "[Zombie Survival] ", color_white, "Round ended.")
	end
end)
