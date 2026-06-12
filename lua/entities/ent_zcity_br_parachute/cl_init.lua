include("shared.lua")

local canopyMaterial = Material("models/debug/debugwhite")
local lineMaterial = Material("cable/cable2")
local canopyRed = Color(205, 20, 24, 235)
local canopyWhite = Color(238, 238, 232, 235)
local lineColor = Color(225, 225, 215, 220)

local function drawDoubleSidedQuad(a, b, c, d, color)
    render.DrawQuad(a, b, c, d, color)
    render.DrawQuad(d, c, b, a, color)
end

function ENT:DrawTranslucent()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local base = owner:GetPos() + Vector(0, 0, 150)
    local forward = Angle(0, owner:EyeAngles().y, 0):Forward()
    local right = forward:Cross(vector_up)
    local center = base + forward * 20
    local halfWidth = 74
    local halfLength = 54
    local crown = center + vector_up * 28

    local frontLeft = center + forward * halfLength - right * halfWidth
    local frontRight = center + forward * halfLength + right * halfWidth
    local backLeft = center - forward * halfLength - right * halfWidth
    local backRight = center - forward * halfLength + right * halfWidth

    render.SetMaterial(canopyMaterial)
    drawDoubleSidedQuad(crown, frontLeft, center + forward * halfLength, frontRight, canopyRed)
    drawDoubleSidedQuad(crown, frontRight, backRight, center - forward * halfLength, canopyWhite)
    drawDoubleSidedQuad(crown, center - forward * halfLength, backLeft, frontLeft, canopyRed)
    drawDoubleSidedQuad(frontLeft, backLeft, backRight, frontRight, canopyWhite)

    local harness = owner:GetPos() + Vector(0, 0, 48)
    render.SetMaterial(lineMaterial)
    render.DrawBeam(frontLeft, harness, 1.5, 0, 1, lineColor)
    render.DrawBeam(frontRight, harness, 1.5, 0, 1, lineColor)
    render.DrawBeam(backLeft, harness, 1.5, 0, 1, lineColor)
    render.DrawBeam(backRight, harness, 1.5, 0, 1, lineColor)
end
