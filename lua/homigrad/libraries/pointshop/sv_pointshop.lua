--
hg.Pointshop = hg.Pointshop or {}

local PLUGIN = hg.Pointshop
PLUGIN.PlayerInstances = PLUGIN.PlayerInstances or {}

hook.Add("DatabaseConnected", "PointshopCreateData", function()
	local query

	query = mysql:Create("hg_pointshop")
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("donpoints", "FLOAT NOT NULL")
		query:Create("points", "FLOAT NOT NULL")
        query:Create("items", "TEXT NOT NULL")
		query:PrimaryKey("steamid")
	query:Execute()

    --hook.Run("ZPointshopLoaded")

    PLUGIN.Active = true
end)

--local query = mysql:Drop("zb_experience")
--query:Execute()

hook.Add( "PlayerInitialSpawn","Pointshop_OnInitSpawn", function( ply )
    local name = ply:Name()
	local steamID64 = ply:SteamID64()

    if not PLUGIN.Active then
        PLUGIN.PlayerInstances[steamID64] = {}

		PLUGIN.PlayerInstances[steamID64].donpoints = 0
        PLUGIN.PlayerInstances[steamID64].points = 0
        PLUGIN.PlayerInstances[steamID64].items = {}
        return
    end 

	local query = mysql:Select("hg_pointshop")
		query:Select("donpoints")
		query:Select("points")
        query:Select("items")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].donpoints) then
				local updateQuery = mysql:Update("hg_pointshop")
					updateQuery:Update("steam_name", name)
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

				PLUGIN.PlayerInstances[steamID64] = {}

                PLUGIN.PlayerInstances[steamID64].donpoints = tonumber(result[1].donpoints)
                PLUGIN.PlayerInstances[steamID64].points = tonumber(result[1].points)
                PLUGIN.PlayerInstances[steamID64].items = util.JSONToTable(result[1].items)

                hook.Run( "PS_PlayerLoaded", ply, steamID64 )
			else
				local insertQuery = mysql:Insert("hg_pointshop")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("donpoints", 0)
		            insertQuery:Insert("points", 0)
                    insertQuery:Insert("items", util.TableToJSON({}))
				insertQuery:Execute()

				PLUGIN.PlayerInstances[steamID64] = {}

				PLUGIN.PlayerInstances[steamID64].donpoints = 0
                PLUGIN.PlayerInstances[steamID64].points = 0
                PLUGIN.PlayerInstances[steamID64].items = {}

			end
		end)
	query:Execute()
end)


local plyMeta = FindMetaTable("Player")

function plyMeta:GetPointshopVars()
    local steamID64 = self:SteamID64()
    if not util.IsBinaryModuleInstalled("mysqloo")  then
        PLUGIN.PlayerInstances[steamID64] = {}

		PLUGIN.PlayerInstances[steamID64].donpoints = 0
        PLUGIN.PlayerInstances[steamID64].points = 0
        PLUGIN.PlayerInstances[steamID64].items = {}
        return PLUGIN.PlayerInstances[steamID64]
    end

    return PLUGIN.PlayerInstances[steamID64]
end

function plyMeta:PS_AddPoints( ammout )
    local pointshopVars = self:GetPointshopVars()

    if ammout < 1 then
        return false, "How."
    end

    self:PS_SetPoints(pointshopVars.points + ammout)

    if callback then
        callback( self )
    end

    return true, ammout .. " IGcity points added. Use !pointshop to open the pointshop."
end

function plyMeta:PS_SetPoints( value )
    if not util.IsBinaryModuleInstalled("mysqloo") then return end
	local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
		updateQuery:Update("points", value)
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()

    pointshopVars.points = value
end

function plyMeta:PS_TakePoints( ammout, callback )
    local pointshopVars = self:GetPointshopVars()

    if ammout > pointshopVars.points then
        return false, "Not enough IGcity points."
    end

    self:PS_SetPoints(pointshopVars.points - ammout)

    if callback then
        callback( self )
    end

    return true, ammout .. " IGcity points spent."
end

-- ATTACK THE D POINT

function plyMeta:PS_AddDPoints( ammout )
    local pointshopVars = self:GetPointshopVars()

    if ammout < 1 then
        return false, "How."
    end

    self:PS_SetDPoints(pointshopVars.donpoints + ammout)

    if callback then
        callback( self )
    end

    return true, ammout .. " DZPoints added !pointshop to open a pointshop"
end

function plyMeta:PS_SetDPoints( value )
    if not util.IsBinaryModuleInstalled("mysqloo") then return end
	local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
		updateQuery:Update("donpoints", value)
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()

    pointshopVars.donpoints = value
end

function plyMeta:PS_TakeDPoints( ammout, callback )
    local pointshopVars = self:GetPointshopVars()

    if ammout > pointshopVars.donpoints then
        return false, "Not enough DZPoints."
    end

    self:PS_SetDPoints(pointshopVars.donpoints - ammout)

    if callback then
        callback( self )
    end

    return true, ammout .. " DZPoints spent."
end

-- Items functions

function plyMeta:PS_SetItems( tItems )
    local steamID64 = self:SteamID64()
    local pointshopVars = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
		updateQuery:Update("items", util.TableToJSON(tItems))
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()

    pointshopVars.items = tItems
end

function plyMeta:PS_AddItem( uid )
    if not hg.PointShop.Items[uid] then return end
    local pointshopVars = self:GetPointshopVars()

    pointshopVars.items[ uid ] = true

    self:PS_SetItems(pointshopVars.items)
end

function plyMeta:PS_HasItem( uid )
    local pointshopVars = self:GetPointshopVars()
    --PrintTable(pointshopVars)
    if !pointshopVars then return false end
    return pointshopVars.items[ uid ] or false
end

--print(Player(2):PS_HasItem( "test_item_1" ))

-- networking and other

util.AddNetworkString("hg_pointshop_net")

function PLUGIN:NET_SendPointShopVars( ply )

    net.Start( "hg_pointshop_net" )
        net.WriteTable( ply:GetPointshopVars() )
    net.Send( ply )
end

--PLUGIN:NET_SendPointShopVars( Player(2) )

util.AddNetworkString("hg_pointshop_send_notificate")

function PLUGIN:NET_BuyItem( ply, uid )
    if not util.IsBinaryModuleInstalled("mysqloo") then return end
    if hg.PointShop.Items[uid].ISDONATE then return end
    if not hg.PointShop.Items[uid] then print(ply, "[PS-ZCity] The player is trying to buy invalid item.", "UID: "..uid ) return end
    if ply:PS_HasItem( uid ) then PLUGIN:NET_SendPointShopVars( ply ) return end

    local yes = false
    local reason = ""

    if hg.PointShop.Items[uid].ISDONATE then
        yes, reason = ply:PS_TakeDPoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem( uid ) end)
    else
        yes, reason = ply:PS_TakePoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem( uid ) end)
    end
    
    net.Start( "hg_pointshop_send_notificate" )
        net.WriteString(reason)
    net.Send( ply )

    PLUGIN:NET_SendPointShopVars( ply )
end

function PLUGIN:NET_GetBuyedItems( ply )
    PLUGIN:NET_SendPointShopVars( ply )
end

net.Receive("hg_pointshop_net",function( _, ply )
    if ply.PSNetCD and ply.PSNetCD > CurTime() then return end

    ply.PSNetCD = CurTime() + 0.01

    local str = net.ReadString()
    local funcstring = PLUGIN[ "NET_" .. str ]

    if not funcstring then print(ply, "[PS-ZCity] Player trying to call an invalid function!", "NAME: "..str ) return end
    local vars = net.ReadTable()
    if table.Count(vars) > 5 then print(ply, "[PS-ZCity] The player is trying to send a bunch of vars to the net.", "NAME: "..str ) return end

    funcstring( PLUGIN, ply, unpack(vars) )
end)


local function IsVIPPlayer(ply)
    if not IsValid(ply) then return false end

    local group = string.lower(ply:GetUserGroup() or "")
    return group == "vip" or string.find(group, "vip", 1, true) ~= nil
end

concommand.Add("hg_ps_give_vip_points", function(executor, _, args)
    if IsValid(executor) and not executor:IsSuperAdmin() then
        executor:PrintMessage(HUD_PRINTCONSOLE, "[PointShop] Superadmin access required.\n")
        return
    end

    local targetArg = args[1]
    local amount = tonumber(args[2] or "")

    if not targetArg or not amount then
        local usage = "Usage: hg_ps_give_vip_points <steamid64|name> <amount>\n"
        if IsValid(executor) then
            executor:PrintMessage(HUD_PRINTCONSOLE, usage)
        else
            print("[PointShop] " .. usage)
        end
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == targetArg or string.find(string.lower(ply:Name()), string.lower(targetArg), 1, true) then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        local msg = "[PointShop] VIP target not found online.\n"
        if IsValid(executor) then executor:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
        return
    end

    if not IsVIPPlayer(target) then
        local msg = "[PointShop] Target is not in a VIP usergroup.\n"
        if IsValid(executor) then executor:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
        return
    end

    local ok, reason = target:PS_AddPoints(amount)
    local result = "[PointShop] " .. (reason or "Unknown result") .. "\n"

    if IsValid(executor) then
        executor:PrintMessage(HUD_PRINTCONSOLE, result)
    else
        print(result)
    end

    if ok then
        target:PrintMessage(HUD_PRINTCONSOLE, "[PointShop] You received " .. tostring(amount) .. " IGcity points.")
    end
end)

local PASSIVE_IGPOINTS_PER_HOUR = 20
local PASSIVE_IGPOINTS_INTERVAL = 300
local PASSIVE_IGPOINTS_PER_TICK = PASSIVE_IGPOINTS_PER_HOUR * (PASSIVE_IGPOINTS_INTERVAL / 3600)

hook.Add("Think", "PointShop_PassiveIGPoints", function()
    if not PLUGIN.Active then return end

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        ply.PS_NextPassiveIGPoints = ply.PS_NextPassiveIGPoints or (CurTime() + PASSIVE_IGPOINTS_INTERVAL)
        ply.PS_PassiveIGPointsRemainder = ply.PS_PassiveIGPointsRemainder or 0

        if CurTime() < ply.PS_NextPassiveIGPoints then continue end

        ply.PS_NextPassiveIGPoints = CurTime() + PASSIVE_IGPOINTS_INTERVAL

        local pointMultiplier = 1
        if IsVIPPlayer(ply) then
            pointMultiplier = 5
        elseif (tonumber(ply.Karma) or 0) >= 100 then
            pointMultiplier = 2
        end

        ply.PS_PassiveIGPointsRemainder = ply.PS_PassiveIGPointsRemainder + (PASSIVE_IGPOINTS_PER_TICK * pointMultiplier)

        local wholePoints = math.floor(ply.PS_PassiveIGPointsRemainder)
        if wholePoints < 1 then continue end

        local ok = ply:PS_AddPoints(wholePoints)
        if ok then
            ply.PS_PassiveIGPointsRemainder = ply.PS_PassiveIGPointsRemainder - wholePoints
            ply:ChatPrint("You earned " .. tostring(wholePoints) .. " IGcity points")
        end
    end
end)

hook.Add("HG_PlayerSay","OpenPointShop",function(ply, txtTbl, txt)
    if txt == "!pointshop" then
        ply:ConCommand("hg_pointshop")
    end
end)