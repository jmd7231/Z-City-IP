local MODE = MODE

function MODE:HUDPaint()
	if not zb.ROUND_START then return end

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	if fade > 0 then
		draw.SimpleText("Head Crab Survival", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.12, Color(180, 255, 180, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Survive the swarm. Nowhere is safe.", "ZB_HomicideMedium", sw * 0.5, sh * 0.18, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
	if (zb.ROUND_START or 0) + 6 > CurTime() and cmd then
		cmd:RemoveKey(IN_ATTACK)
		cmd:RemoveKey(IN_ATTACK2)
		if mv then
			mv:RemoveKey(IN_ATTACK)
			mv:RemoveKey(IN_ATTACK2)
		end
	end
end
