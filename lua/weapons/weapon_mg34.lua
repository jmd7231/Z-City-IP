if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_m249"
SWEP.PrintName = "MG 34"
SWEP.Author = "Mauser"
SWEP.Instructions = "German general-purpose machine gun chambered in 7.92x57 mm."
SWEP.Category = "Weapons - Machineguns"
SWEP.Spawnable = false
-- Keep the M249 base models and fake-model offsets. A plain MG34 world model is
-- not compatible with the custom Homigrad renderer and produces an ERROR model.
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "5.56x45 mm"
SWEP.Primary.Damage = 55
SWEP.Primary.Force = 55
SWEP.Primary.Wait = 0.05
SWEP.ReloadTime = 8
SWEP.weight = 11.6
