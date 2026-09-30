ENT.CacheTimers = {}
ENT.Caches = {
    NPC_MoveGoal = Vector(),
    NPC_HasMoveGoal = Vector(),
    NPC_LastGoalUpdate = -1,
    NPC_LastCrawl = -1,
    NPC_ShouldRHand = false,
    NearWalling = 0,
    HeadWalling = 0,
}
ENT.VarCaches = {}

if SERVER then
    ENT.OwnerModifiedEnts = {}

    ENT.RagPObjs = {}
    ENT.RagLastModel = ""
end

-- 你的语法是一坨
function ENT:ShouldUseCachedVar(key)
    local ct, last = CurTime(), self.CacheTimers[key] or -1
    return last > ct
end
function ENT:GetCachedVar(key, var)
    local ct, last = CurTime(), self.CacheTimers[key] or -1
    if last > ct then return self.Caches[key] end
    return var == nil and self.Caches[key] or var
end
function ENT:SetCachedVar(key, var, time, forced)
    local ct, last = CurTime(), self.CacheTimers[key] or -1

    if not forced and last > ct then return end

    self.Caches[key] = var
    self.CacheTimers[key] = ct + time
end


-- 我猜这是ZCity用的操作方式
-- 这个方法可以不强奸服务器的Net, 在大型RP服务器里可能会有更好的效果(是的是的是的)
function ENT:GetAimEyeAngles()
    local own = self:GetOwner()
    if not IsValid(own) then return angle_zero end
    local ea = own:EyeAngles(true)

    if SERVER and own:IsNPC() then ea.y = own:GetIdealYaw() end
    return ea
end
function ENT:SetAimEyeAngles(ang)
    local own = self:GetOwner()
    if not IsValid(own) then return end

    if isfunction(own.SetEyeAngles) then
        own:SetEyeAngles(ang, true)
    elseif isfunction(own.SetIdealYaw) then
        own:SetIdealYaw(ang.y)
    else
        own:SetAngles(ang)
    end
end

function ENT:AddKeyInput(key)
    self.KeyInputs[key] = true
end
function ENT:HasKeyInput(key)
    local own = self:GetOwner()
    --own:ChatPrint(tostring(self.KeyInputs[key]))
    --own:ChatPrint(tostring(own:KeyDown(key)))
    return self.KeyInputs[key] or (own:IsPlayer() and own:KeyDown(key))
end


