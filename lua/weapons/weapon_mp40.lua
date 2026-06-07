if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_mp5"
SWEP.PrintName = "MP 40"
SWEP.Author = "Erma Werke"
SWEP.Instructions = "German submachine gun chambered in 9x19 mm."
SWEP.Category = "Weapons - Submachineguns"
SWEP.Spawnable = false
-- Keep the MP5 base models and fake-model offsets. The generic DOD world model does not
-- contain the bones/attachments expected by homigrad_base and renders as an ERROR.
SWEP.Primary.ClipSize = 32
SWEP.Primary.DefaultClip = 32
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Damage = 38
SWEP.Primary.Force = 38
SWEP.Primary.Wait = 0.1
SWEP.weight = 4
