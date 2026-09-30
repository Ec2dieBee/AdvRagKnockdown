local tickInterval = engine.TickInterval()
local VBoxInstalled = ConVarExists("vbox_contact_damping")

local vector_origin, angle_zero = Vector(), Angle()



-- 在经历了如此之长的痛苦之后, 我决定: 强制设置每个模型的MASS, 我可去你妈的吧
-- 不在这个表里的pObj质量统统减少, I DONT CARE
-- Breen.mdl
local boneMassList = {
    ["ValveBiped.Bip01_Pelvis"] = 13,
    ["ValveBiped.Bip01_L_Thigh"] = 10,
    ["ValveBiped.Bip01_L_Calf"] = 5,
    ["ValveBiped.Bip01_L_Foot"] = 2.4,
    ["ValveBiped.Bip01_Spine1"] = 24,
    ["ValveBiped.Bip01_Spine2"] = 32,
    --["ValveBiped.Bip01_R_UpperArm"] = 3.5,
    --["ValveBiped.Bip01_R_Forearm"] = 1.75,
    --["ValveBiped.Bip01_R_UpperArm"] = 17.5,
    --["ValveBiped.Bip01_R_Forearm"] = 13.5,
    ["ValveBiped.Bip01_R_UpperArm"] = 9,
    ["ValveBiped.Bip01_R_Forearm"] = 5,
    ["ValveBiped.Bip01_R_Thigh"] = 10,
    ["ValveBiped.Bip01_R_Calf"] = 5,
    ["ValveBiped.Bip01_R_Foot"] = 2.4,
    ["ValveBiped.Bip01_Head1"] = 5,
    ["ValveBiped.Bip01_L_UpperArm"] = 9,
    ["ValveBiped.Bip01_L_Forearm"] = 5,
    --["ValveBiped.Bip01_L_Hand"] = 1.5,
    --["ValveBiped.Bip01_R_Hand"] = 1.5,
    ["ValveBiped.Bip01_L_Hand"] = 2,
    ["ValveBiped.Bip01_R_Hand"] = 2,

}

local cvPrefix = "savee_advragknockdown_"
local function getCV(cv, st)
    cv = GetConVar(cvPrefix .. cv)
    if not cv then return end
    if st then
        cv = cv["Get" .. st](cv)
    end

    return cv
end

ENT.LHand_Grabbing = false
ENT.LHand_Grabbing_Broken = false
ENT.LHand_NextGrab = -1
ENT.LHand_GrabbingData = {}
ENT.RHand_Grabbing_Broken = false
ENT.RHand_Grabbing = false
ENT.RHand_NextGrab = -1
ENT.RHand_GrabbingData = {}


---@param rag Entity
function ENT.modifyRagdoll(rag, pObjs, ownVel)
    
    --print("ICALL")
    
    if CLIENT or not IsValid(rag) then return end
    local ctrl = rag.Savee_AdvRagKnockdown_Controller
    local oldVels = {}

    -- dumbass_define_animandphys.qci
    for i, data in pairs(pObjs) do
        local pObj = data.pObj
        if not pObj then continue end
        oldVels[i] = pObj:GetVelocity()
        pObj:EnableMotion(false)
    end

    Savee_AdvRagKnockdown_ReplaceRagConstraints(rag, pObjs)
    
    for i, data in pairs(pObjs) do
        local pObj = data.pObj
        if not pObj then continue end
        pObj:EnableMotion(true)
        pObj:Wake()
        pObj:SetVelocityInstantaneous(oldVels[i] + ownVel)
    end

    -- 在这加个CV
    if not getCV("rag_minmasslimit", "Bool") then return end
    
    local objCount = rag:GetPhysicsObjectCount()

    --for bone, data in pairs(pObjs) do
    for i = 0, objCount - 1 do
        --local pObj = data.pObj
        local pObj = rag:GetPhysicsObjectNum(i)
        local bone = rag:GetBoneName((rag:TranslatePhysBoneToBone(i)))

        if armBones[bone] and VBoxInstalled then
            pObj:SetDamping(0, 250)
        end
        
        --print(bone)
        
        if boneMassList[bone] then
            --print(bone)
            pObj:SetMass(math.max(pObj:GetMass(), boneMassList[bone]))
            --print(bone)
        end
        
    end

    if ctrl then ctrl.PreventPhysAttackTill = CurTime() + (objCount - 14) / 2 end
    
end
local hitgroupDmg_limbs = 0.5

local hitGroupPhysicsDmgMuls = {
    [HITGROUP_GENERIC] = 1,
    [HITGROUP_HEAD] = 1.25,
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 0.8,
    [HITGROUP_GEAR] = 0,
    [HITGROUP_LEFTARM] = hitgroupDmg_limbs,
    [HITGROUP_RIGHTARM] = hitgroupDmg_limbs,
    [HITGROUP_LEFTLEG] = hitgroupDmg_limbs,
    [HITGROUP_RIGHTLEG] = hitgroupDmg_limbs,
}

-- 注释参见C手转换器
local function calcBaseScale(ent)

    local bone1, bone2, bone3 = ent:LookupBone("ValveBiped.Bip01_R_UpperArm"), ent:LookupBone("ValveBiped.Bip01_R_Forearm"), ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone1 or not bone2 or not bone3 then return 1 end
    local bp2 = ent:GetBonePosition(bone2)
    
    local dist1 = ent:GetBonePosition(bone1):Distance(bp2)
    local dist2 = bp2:Distance(ent:GetBonePosition(bone3))

    local baseScale = Lerp(0.5, 11.69 / dist1, 11.48 / dist2)

    return baseScale

end

function ENT:SetupRagdoll(rag, pObjs)
    local own = self:GetOwner()

    -- noob gore mod 2支持
    rag.destructible_Corpse = false

    -- Miku很可爱, 但她只有158cm
    -- 这就是为什么这个值在这
    local mdlScale = calcBaseScale(rag)
    rag.Savee_AdvRagKnockdown_ModelScale = mdlScale

    -- Still Miku兼容
    -- 部分模型的TranslateBoneToPhysBone结果不正确

    for pID = 0, rag:GetPhysicsObjectCount() - 1 do
        local pObj = rag:GetPhysicsObjectNum(pID)
        local i = rag:TranslatePhysBoneToBone(pID)

        --own:CopyBoneMatrix(i, mtx)
        --local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

        --pObj:SetPos(pos)
        --pObj:SetAngles(ang)
        
        local name = rag:GetBoneName(i)
        --pIDToName[pID] = name
        --print(i, name, pID, pObj)

        pObjs[name] = {
            id = pID,
            pObj = pObj,
            physBone = true,
        }
        --print(rag:GetBoneName(rag:TranslatePhysBoneToBone(i)), pObj:GetMass())
    end


    -- Miku兼容
    for i = 0, rag:GetBoneCount() - 1 do

        local name = rag:GetBoneName(i)
        
        if pObjs[name] then continue end

        local pID = rag:TranslateBoneToPhysBone(i)
        local pObj = rag:GetPhysicsObjectNum(pID)
        --pIDToName[pID] = name
        --pObj:SetMaterial("Player")

        --print(i, name, pID, pObj)

        ---@type PhysObj
        pObjs[name] = {
            id = pID,
            pObj = pObj,
            physBone = false,
        }

    end

    --local hitGroups = {}
    rag.Savee_AdvRagKnockdown_HitGroups = {}
    rag.Savee_AdvRagKnockdown_HitBoxes = {}

    for i = 0, own:GetHitBoxCount(0) - 1 do
        
        local bone = own:GetHitBoxBone(i, 0)
        local hitGroup = own:GetHitBoxHitGroup(i, 0)
        rag.Savee_AdvRagKnockdown_HitGroups[bone] = hitGroup
        rag.Savee_AdvRagKnockdown_HitBoxes[bone] = i

    end

    rag:AddCallback("PhysicsCollide", function(rag, data)
    
        if not IsValid(self) or not IsValid(own) then return end

        local ct = CurTime()
        if self.GettingUp and ct + data.DeltaTime <= self.PreventPhysAttackTill then return end

        -- 我不认为你高速创到一个灰尘会导致你昏厥, 我觉得该昏的是灰尘
        local pObj = data.PhysObject
        
        local spd = data.HitSpeed --(data.OurOldVelocity - data.OurNewVelocity)
        local dot = spd:GetNormalized():Dot(data.HitNormal)
        local mul = math.ease.InQuart((1 - dot) / 2 + 0.1)
        spd = spd:Length()

        local official = boneMassList[rag:GetBoneName(pObj:GetIndex())]

        --print(spd * mul, mul)

        spd = math.max(spd * mul - (official and (self.GettingUp and 800 or 600) or 1200) / math.max(1, mdlScale), 0)
        --print(spd)
        if spd == 0 or data.HitEntity == rag then return end

        local tr = util.TraceHull({
            start = data.HitPos,
            endpos = data.HitPos,
            whitelist = true,
            filter = rag,
            getRaw = true,
            mask = MASK_ALL,
            mins = Vector(-2, -2, -2),
            maxs = Vector(2, 2, 2),
        })
        local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
        local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]
        local hgMul = hitGroupPhysicsDmgMuls[hitGroup or 0]

        local ent = data.HitEntity

        local dmg = (spd / 10 - pObj:GetMass()) * math.min(data.DeltaTime, 1) / 1.5
        if ent:IsNPC() or ent:IsRagdoll() or ent:GetClass() == "func_breakable_surf" then 
            dmg = dmg / 10
        end

        --print(hitGroup)

        local di = DamageInfo()
        self.DI_MarkedAsTaken[di] = true
        di:SetDamage(dmg * (official and 1 or 0.2) * hgMul)
        di:SetDamageType(DMG_CRUSH)

        local pAtk = ent:GetPhysicsAttacker()
        di:SetAttacker(IsValid(pAtk) and pAtk or ent)
        di:SetInflictor(ent)

        --print(data.HitEntity)
        own:TakeDamageInfo(di, true)
        self.PreventPhysAttackTill = ct + tickInterval * 2
    
    end)

end

function ENT:TryGetUp(animTbl, forced)
    --do return false end
    if not forced and not self:ShouldGetUp() then return end

    if not animTbl then

        local rag = self:GetRagdoll()
        local besties = {}
        local _, pitch = rag:GetBonePosition(0)
        pitch = pitch.p
        for _, data in ipairs(self.AnimationTable.Getup) do
            local angData = data.Pitch or {0, 0}
            local min, max, rev = angData[1], angData[2], angData[3]

            if rev and (pitch > min and pitch < max) or not rev and (pitch < min or pitch > max) then 
                continue
            end

            besties[#besties + 1] = data
        end
        animTbl = next(besties) and besties[math.random(#besties)] or table.Random(self.AnimationTable.Getup)

    end

    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    local mdlScale = rag.Savee_AdvRagKnockdown_ModelScale

    local pos = rag:GetBonePosition(0)
    local pos2 = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Spine2") or 1)

    local ang = (pos2 - pos):Angle()
    ang:Normalize()

    -- TODO: 射线检测
    ang.p = 0
    ang.r = 0

    _, ang = LocalToWorld(vector_origin, (animTbl.AngDelta or Angle()), vector_origin, ang)

    local anim = self.GetupAnimModel

    self.GettingUp = true
    self.GettingUp_SyncingToOwner = false
    self.GettingUp_FaceAng = ang
    self.PreventPhysAttackTill = CurTime() + 0.2
    anim:SetParent(nil)

    local hull = (own:OBBMaxs() - own:OBBMins()) / 2
    hull.z = 1

    local heightTr = util.TraceLine({start = pos + Vector(0, 0, 5), endpos = pos - Vector(0, 0, 64 * mdlScale), filter = {self, own, rag}, mask = MASK_ALL})
    local heightLerp = ((pos2.z + pos.z) / 2 - heightTr.HitPos.z) / (24 * mdlScale) - 0.1
    --print(heightLerp)
    
    local tr = rag:WaterLevel() >= 1 and {HitPos = rag:GetPos()} or util.TraceHull({
        start = rag:GetPos() + Vector(0, 0, 5), 
        endpos = rag:GetPos() - Vector(0, 0, 64),
        filter = {rag, own},
        mins = -hull,
        maxs = hull,
    })

    anim:SetPos(tr.HitPos)
    anim:SetAngles(ang)
    anim:SetModel(animTbl.Model) 
    anim:SetSequence(animTbl.Sequence)
    anim:SetPlaybackRate(1)

    local cycle = animTbl.StartCycle or 0

    local crouch, stand = animTbl.GetUp_Duck or 0.3, animTbl.GetUp_Stand or 0.7
    if heightLerp > 0.5 then
        cycle = Lerp((heightLerp - 0.5) / 0.5, crouch, stand)
    else
        cycle = Lerp(heightLerp / 0.5, cycle, crouch)
    end

    anim:SetCycle(cycle)
    --if IsValid(tr.Entity) then anim:SetParent(tr.Entity) end
    self.CurGetUpAnimData = animTbl

end

function ENT:ShouldGetUp()

    if self.NextGetUp > CurTime() then return false end

    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    local stamina = self:GetStamina()
    local consc = self:GetConsciousness()

    if consc < 45 or stamina < 45 then return false end

    if self.GettingUp then
        local bp1 = (self.GettingUp_SyncingToOwner and self or self.GetupAnimModel):GetBonePosition(0)
        local bp2 = rag:GetBonePosition(0)
        local dist = bp1:Distance(bp2)

        if dist > 25 and rag:WaterLevel() < 1 then return false end
    else
        local pos = rag:GetBonePosition(0)
        local tr = util.TraceLine({start = pos + Vector(0, 0, 5), endpos = pos - Vector(0, 0, 64 * rag.Savee_AdvRagKnockdown_ModelScale), filter = {self, own}, mask = MASK_ALL})
        
        local hasResult, cResult = runThatHook("Savee_AdvRagKnockdown_ShouldGetUp", own, self, tr)
        
        return not hasResult and (tr.Hit or rag:WaterLevel() >= 1) or cResult
    end

    return true
end

function ENT:CancelGetUp()
    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    self.GettingUp = false
    self.GetupAnimModel:SetParent(rag)
    
    if own:IsNPC() then self:SetCachedVar("NPC_CanGetUpVar", false, math.Rand(1, 3), true) end
end


