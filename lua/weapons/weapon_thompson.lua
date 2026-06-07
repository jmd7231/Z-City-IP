if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_akm"
SWEP.PrintName = "M1A1 Thompson"
SWEP.Author = "Auto-Ordnance"
SWEP.Instructions = "American submachine gun chambered in .45 ACP."
SWEP.Category = "Weapons - Submachineguns"
SWEP.Spawnable = false
-- Keep the AKM base models and fake-model offsets so Homigrad always has the
-- attachments and bones required by its first-person renderer.
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = ".45 ACP"
SWEP.Primary.Damage = 42
SWEP.Primary.Force = 42
SWEP.Primary.Wait = 0.1
SWEP.weight = 4.8
