local cvPrefix = "savee_advragknockdown_"
local vector_origin = Vector()
local pelvisang, pelvisangdamp, pelvisspd, pelvisspddamp, pelvisdampfactor, pelvisdelta = 50, 10, 0, 0, 0.8, 0.15
local legang, legangdamp, legspd, legspddamp, legsdampfactor, legsdelta = 25, 50, 0, 0, 0.5, 0.2

local pelvisUseMass = false
local legUseMass = true
local legDelta = 15

local getLocalizedVelocity = Savee_AdvRagKnockdown_GetLocalizedVelocity

local function getPhysBonePosAng(tbl, name)
    local pObj = (tbl[name] or {}).pObj
    if not pObj then return vector_origin, angle_zero end
    
    return pObj:GetPos(), pObj:GetAngles()
end

function STATUS:CanBeUsed() 
    return self.Controller_Owner:IsSprinting()
end

function STATUS:OnApply()
    self.DontRemoveTill = CurTime() + 0.2
end

function STATUS:CanGetUp() return false end

function STATUS:OnAnimationCaculated(pObjs, shadowCtrls)

    if not self.Sliding then return end

    local ctrl = self.Controller
    local own = self.Controller_Owner
    local rag = self.Controller_Ragdoll

    local aea = ctrl:GetAimEyeAngles()
    local groundTr = util.QuickTrace(getPhysBonePosAng(pObjs, "ValveBiped.Bip01_Pelvis"), Vector(0, 0, -48), {own, rag})

    if not groundTr.Hit and not groundTr.HitSky then return end

    local velAng = getLocalizedVelocity(rag):Angle()
    local ang = groundTr.HitNormal:Angle()
    
    local _, angDiff = WorldToLocal(vector_origin, aea, vector_origin, velAng)
    local left = math.abs(aea.r) <= 5 and angDiff.y >= 0 or aea.r < 0
    local id = left and 1 or 2

    --print(left, math.floor(aea.r) < 0, math.floor(angDiff.y) > 0)
    local _, angFace = LocalToWorld(vector_origin, Angle(0, 90, 0), vector_origin, aea)

    angFace.y = velAng.y + 90
    angFace.r = ang.p + 90
    angFace.p = Lerp(0.2, ang.r + (left and 30 or -30), angFace.p)


    --print(angDiff, velAng, aea)

    -- 超级史堆代码来咯~
    local para = {90, 120}
    local lThigh, lCalf = left and -160 or -90, table.remove(para, id)
    local rThigh, rCalf = left and -60 or -20, para[1]

    para = {-10, -20}
    local lThighP, rThighP = table.remove(para, id), para[1]

    shadowCtrls["ValveBiped.Bip01_Pelvis"] = {
        angle = angFace,
        maxspeed = pelvisspd,
        maxspeeddamp = pelvisspddamp,
        maxangular = pelvisang,
        maxangulardamp = pelvisangdamp,
        dampfactor = pelvisdampfactor,
        delta = pelvisdelta,
        addMass = pelvisUseMass,
        noCorrection = true
    }
    local _, lLeg = LocalToWorld(vector_origin, Angle(lThighP, -90 + legDelta, lThigh), vector_origin, angFace)
    local _, rLeg = LocalToWorld(vector_origin, Angle(rThighP, -90 - legDelta, rThigh), vector_origin, angFace)
    shadowCtrls["ValveBiped.Bip01_L_Thigh"] = {
        angle = lLeg,
        maxspeed = legspd,
        maxspeeddamp = legspddamp,
        maxangular = legang,
        maxangulardamp = legangdamp,
        dampfactor = legsdampfactor,
        delta = legsdelta,
        addMass = legUseMass,
        noCorrection = true
    }
    shadowCtrls["ValveBiped.Bip01_R_Thigh"] = {
        angle = rLeg,
        maxspeed = legspd,
        maxspeeddamp = legspddamp,
        maxangular = legang,
        maxangulardamp = legangdamp,
        dampfactor = legsdampfactor,
        delta = legsdelta,
        addMass = legUseMass,
        noCorrection = true
    }
    _, lLeg = LocalToWorld(vector_origin, Angle(0, lCalf, 0), vector_origin, lLeg)
    _, rLeg = LocalToWorld(vector_origin, Angle(0, rCalf, 0), vector_origin, rLeg)
    shadowCtrls["ValveBiped.Bip01_L_Calf"] = {
        angle = lLeg,
        maxspeed = legspd,
        maxspeeddamp = legspddamp,
        maxangular = legang,
        maxangulardamp = legangdamp,
        dampfactor = legsdampfactor,
        delta = legsdelta,
        addMass = legUseMass,
        noCorrection = true
    }
    shadowCtrls["ValveBiped.Bip01_R_Calf"] = {
        angle = rLeg,
        maxspeed = legspd,
        maxspeeddamp = legspddamp,
        maxangular = legang,
        maxangulardamp = legangdamp,
        dampfactor = legsdampfactor,
        delta = legsdelta,
        addMass = legUseMass,
        noCorrection = true
    }

end

function STATUS:PhysicsSimulate_CanSurf(vel, velLen)
    return true
end

local surfSpdMin = GetConVar(cvPrefix .. "surfing_minspeed")
local surfSpdMulMaxSpd = GetConVar(cvPrefix .. "surfing_speedmult_maxspeed")
function STATUS:PhysicsSimulate_Surfing(spdMul)
    return math.Clamp(spdMul * 2, 0, math.min(0.9, surfSpdMulMaxSpd:GetFloat() * 1.1))
end

function STATUS:Think()
    local ct = CurTime()
    local rag = self.Controller_Ragdoll

    local satisfied = getLocalizedVelocity(rag):Length() < surfSpdMin:GetFloat()
    if ct >= self.DontRemoveTill and satisfied then 
        self:Remove() 
    elseif not satisfied then
        self.DontRemoveTill = ct + 0.2
    end
end

function STATUS:RagdollInitialized(rag, pObjs, ownVel)
    local ctrl = self.Controller
    local dir = ctrl:GetAimEyeAngles():Forward()
    local dot = dir:Dot(ownVel:GetNormalized())

    if (dot <= 0.6 and dot >= -0.5) then self:Remove() return end

    local torso = pObjs["ValveBiped.Bip01_Spine2"].pObj
    local lCalf, rCalf = pObjs["ValveBiped.Bip01_L_Calf"].pObj, pObjs["ValveBiped.Bip01_R_Calf"].pObj
    
    local torsoMass, legMass = torso:GetMass(), rCalf:GetMass()
    
    local exForce = dir
    
    self.Sliding = dot > 0.6
    --[[if self.Sliding then
        local aea = ctrl:GetAimEyeAngles()
        ctrl:SetAimEyeAngles(aea + Angle(0, 0, math.random(0, 1) == 1 and -5 or 5))
    end]]

    exForce.z = dot > 0.5 and 50 or 0 -- 滑铲抬腿
    local upForce = Vector(0, 0, (dot > 0.5 and -30) or (dot < -0.5 and 600) or 0) -- 滑铲/飞扑

    local onGround = ctrl.OnGroundState > 0.8
    local mult = (onGround and 1.2 or 0.2)
    --print(onGround, ctrl.OnGroundState)

    ownVel = ownVel * mult
    rag:SetVelocity(ownVel)

    torso:ApplyForceCenter((upForce - exForce) * torsoMass / 2)
    
    exForce.z = 0
    lCalf:ApplyForceCenter(ownVel + (upForce + exForce) * legMass)
    rCalf:ApplyForceCenter(ownVel + (upForce + exForce) * legMass)
end

function STATUS:KeyOverride(key)
    if key == IN_DUCK then return true end
end

