AddCSLuaFile()
SWEP.PrintName = "Rolling Wood"
SWEP.Slot = -1
SWEP.SlotPos = -1

--SWEP.ViewModel = ""
SWEP.WorldModel = ""

SWEP.DrawAmmo = false
-- 完美主义(大虚)
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:Reload() end
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end

function SWEP:PreDrawViewModel()
    return true
end
function SWEP:DrawWorldModel()
    return true
end

function SWEP:Think()
    local own = self:GetOwner()
    local ctrl = Savee_AdvRagKnockdown_GetController(own)
    if IsValid(ctrl) and (ctrl.DroppedWeapon and not IsValid(ctrl.DroppedWeapon[2])) then
        ctrl:ClearDroppedWeapon()
    end
end
function SWEP:Holster()
    if CLIENT then return end

    local own = self:GetOwner()
    local ctrl = Savee_AdvRagKnockdown_GetController(own)
    if IsValid(ctrl) then
        ctrl:ClearDroppedWeapon()
    end
    self:Remove()

    return true
end

function SWEP:OnDrop()
    self:Remove()
end
