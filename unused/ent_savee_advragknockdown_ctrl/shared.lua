local oldinc = include
local function include(...)
    if CLIENT then
        AddCSLuaFile(...)
    end
    oldinc(...)
end
AddCSLuaFile()
include("util.lua")
local tickInterval = engine.TickInterval()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "很像ZCity的击倒"

ENT.AutomaticFrameAdvance = true

ENT.Category = "Savee Stuffs - CONCEPTS"
ENT.Spawnable = false

-- VARS
ENT.Removing = false

ENT.OnGroundState = 0.1

local anims = {
    Getup = {
        -- 面朝天
        {
            Model = "models/Zombie/Classic.mdl",
            Sequence = "slumprise_b",
            AngDelta = Angle(0, 0, 0),

            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.7, 0.8},
            Recover_Duck = {0.4, 0.5},
            --pitchmin, pitchmax, 翻转
            Pitch = {-90, 90, true},
            GetUp_Stand = 0.7,
            GetUp_Duck = 0.6,
        },
        -- 面朝地
        {
            Model = "models/Zombie/Classic.mdl",
            Sequence = "slumprise_a",
            AngDelta = Angle(0, -90, 0),

            StartCycle = 0.2,
            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.7, 0.8},
            Recover_Duck = {0.4, 0.5},
            Pitch = {-90, 90},
            GetUp_Stand = 0.7,
            GetUp_Duck = 0.6,
        },
    },
}


if SERVER then
    local function hasAnim(anim, seq)
        return anim:LookupSequence(seq) ~= -1
    end

    -- 这几把啥???
    -- ToDo: 把这玩意改成遍历ANIMTABLE
    timer.Simple(tickInterval, function()

        local anim = ents.Create("base_anim")
        anim:Spawn()

        anim:SetModel("models/player/breen.mdl")
        if hasAnim(anim, "proneup_stand") then
            anims.Getup[#anims.Getup + 1] = {
                Model = "models/player/breen.mdl",
                Sequence = "proneup_stand",
                AngDelta = Angle(0, 0, 0),

                StartCycle = 0.1,
                Recover = {0.9, 1},
                Recover_Duck = {0.8, 0.9},
                Pitch = {-90, 90},
                GetUp_Stand = 0.8,
                GetUp_Duck = 0.5,
            }
        end
        if hasAnim(anim, "wos_l4d_getup_from_pounced") then
            anims.Getup[#anims.Getup + 1] = {
                Model = "models/player/breen.mdl",
                Sequence = "wos_l4d_getup_from_pounced",
                AngDelta = Angle(0, 0, 0),

                StartCycle = 0.1,
                Recover = {0.9, 1},
                Recover_Duck = {0.8, 0.9},
                Pitch = {-90, 90, true},
                GetUp_Stand = 0.8,
                GetUp_Duck = 0.5,
            }
        end

        anim:Remove()

        hook.Run("Savee_AdvRagKnockdown_GetUpAnimationInit", anims.Getup)
    end)
end

ENT.AnimationTable = anims

function ENT:SpawnFunction(ply, tr, ClassName)

    --if ( !tr.Hit ) then return end
    --print("?")
    if IsValid(ply.Savee_AdvRagKnockdown_Controller) then return end

    local SpawnPos = tr.HitPos
    
    local ent = ents.Create(ClassName)
    ent:SetOwner(ply)
    ent:SetPos(ply:GetPos())
    ent:Spawn()
    ent:Activate()

    return ent

end

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "AimingWeapon")
    --self:NetworkVar("Bool", 1, "OnGround")
    self:NetworkVar("Entity", 0, "Ragdoll")
    self:NetworkVar("Float", 0, "LArmDelta")
    self:NetworkVar("Float", 1, "RArmDelta")
    self:NetworkVar("Float", 2, "Stamina")
    self:NetworkVar("Float", 3, "Consciousness")
    -- 这里有mRNA, 所以每个从这里拿的角度都得Normalize一遍
    --self:NetworkVar("Angle", 0, "AimEyeAngles")
end

local wlCERHooks = {
    "DMS_Init",
}

function ENT:Initialize()
    local own = self:GetOwner()
    if not IsValid(own) or IsValid(own.Savee_AdvRagKnockdown_Controller) then
        if SERVER then
            self:RemoveSelf()
        end
        return
    end

    --self:SetTransmitWithParent(true)

    if CLIENT then 
        local rag = self:GetRagdoll()
        -- 绘制问题, 现在NPC应该不会在击倒的时候闪烁一下了
        if IsValid(rag) then
            own:SetParent(rag)
            self:SetRenderBounds(rag:GetRenderBounds())
        end

        timer.Simple(tickInterval, function()
            self.Initialized = true
        end)
        
        return 
    end

    
    
    --print("我在过安检")
    --if own:Health() <= 0 then self:RemoveSelf(true) error("你看还真有安检没过的") return end
    --
    --print("我创造了")
    own.Savee_AdvRagKnockdown_Controller = self

    local ownVel = own:GetVelocity()
    if own:IsNPC() then
        ownVel = ownVel + own:GetMoveVelocity()
    end

    self:SetStamina(100)
    self:SetConsciousness(100)

    --local animTbl = self.AnimationTable.Getup[1]

    self:SetModel(own:GetModel())
    self:SetSequence(own:GetSequence())
    self:DrawShadow(false)
    self:AddEffects(EF_NOSHADOW)
    self:AddEffects(EF_NORECEIVESHADOW)

    self:SetPlaybackRate(1)
    self:SetCycle(own:GetCycle())
    
    --self:SetNoDraw(true)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    -- 部分布娃娃那写死的约束将我强奸300万次(遍历我的每个左脑细胞)
    local rag = ents.Create("prop_ragdoll")
    rag:SetModel(own:GetModel())
    rag:SetPos(self:GetPos())
    rag:SetAngles(own:GetAngles())

    cloneAtoB(own, rag)
    --rag:RemoveFlags(FL_OBJECT)

    rag:SetParent(own)
    rag:AddEffects(EF_BONEMERGE)

    rag:Spawn()
    rag.Savee_AdvRagKnockdown_Controller = self

    if own:IsNPC() and getCV("npc_usehook_createentityragdoll", "Bool") then
        local hooks = hook.GetTable().CreateEntityRagdoll
        for _, id in ipairs(wlCERHooks) do
            hooks[id](own, rag, true)
        end
    end

    rag:SetParent(nil)
    rag:RemoveEffects(EF_BONEMERGE)

    rag:AddEFlags(EFL_DONTBLOCKLOS)
    rag:SetCollisionGroup(own:IsPlayer() and COLLISION_GROUP_PLAYER or COLLISION_GROUP_NPC_ACTOR)

    if own:IsNPC() then constraint.NoCollide(own, rag, 0, 0, false) end

    --modifyRagdoll(rag)

    rag:SetNW2Entity("Savee_AdvRagKnockdown_Controller", self)

    local pObjs = {}
    self:SetupRagdoll(rag, pObjs)

    self.RagLastModel = rag:GetModel()
    self.RagPObjs = pObjs

    self:SetRagdoll(rag)
    self:SetParent(rag)

    self:SetLocalPos(Vector(0, 0, 2))
    self:SetTransmitWithParent(true)

    local ownPos = own:GetPos()
    local bound = Vector(2, 2, 2)
    local groundTr = util.TraceHull({
        start = ownPos,
        endpos = ownPos - Vector(0, 0, 38 * mdlScale),
        filter = {rag, own},
        maxs = bound * mdlScale,
        mins = -bound * mdlScale,
    })
    self.OnGroundState = 1.2 - (ownPos.z - groundTr.HitPos.z) / 64

    --own:FollowBone(rag, rag:LookupBone("ValveBiped.Bip01_R_Hand"))
    own:SetNW2Entity("Savee_AdvRagKnockdown_Controller", self)
    
    -- 看起来是SetMoveParent太早导致的VPhysics.dll抽风(access violation exception)
    -- 在sa_03测试了, 击杀3-4个盾兵并未发生崩溃情况(老方法会崩溃, 参见autorun.lua)
    -- 我就一会点GmosLua的苦逼高中生, C艹这些玩意交给高人解决吧(奈莉看完也4了.jpg)
    timer.Simple(tickInterval, function() 
        if not IsValid(self) or not IsValid(rag) then return end
        -- [ARC9] Modern Warfare 2019 飞刀支持
        self.modifyRagdoll(rag, pObjs, ownVel)
        
        own:SetMoveParent(rag)
        self.Initialized = true
    end)

    self.m_iOwnMoveType = own:GetMoveType()
    self.m_iOwnCollisionGroup = own:GetCollisionGroup()
    --self.m_iOwnSolid = own:GetSolid()
    self.m_entOwnLightOrigin = own:GetLightingOriginEntity()

    -- BUG: 市民有这个MOVETYPE的时候会卡列车动画
    -- https://github.com/ValveSoftware/source-sdk-2013/blob/b8cfb12c0e083a2ef5b2f9f9b50f3902fa034474/src/game/server/hl2/npc_citizen17.cpp#L1168
    own:SetMoveType(MOVETYPE_NONE)
    own:SetCollisionGroup(CUSTOM_OWNER_COLLISIONGROUP)
    --own:SetSolid(SOLID_NONE)
    own:SetLightingOriginEntity(rag)

    own:AddEffects(EF_BONEMERGE)
    own:AddEffects(EF_BONEMERGE_FASTCULL)
    --own:SetNoDraw()

    local aimBlock = own:IsNPC() and aimBlackListedNPCClass[own:GetClass()]

    local fakePly = ents.Create("base_anim")
    fakePly:SetModel(aimBlock and "models/player/breen.mdl" or own:GetModel())
    fakePly:Spawn()
    self.FakePlyModel = fakePly
    self:DeleteOnRemove(fakePly)

    fakePly:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    fakePly:SetNoDraw(true)
    fakePly:SetAutomaticFrameAdvance(true)

    --print(self, "钩子", own, rag)

    self.m_vOwnViewOffset = own:GetViewOffset()

    local anim = ents.Create("base_anim")
    anim:SetModel(own:GetModel())
    anim:Spawn()
    self.GetupAnimModel = anim
    self:DeleteOnRemove(anim)
    anim:DeleteOnRemove(self)
    anim:SetPos(rag:GetPos())
    anim:SetParent(rag)
    anim:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    anim:SetNoDraw(true)
    anim:SetAutomaticFrameAdvance(true)

    if not own:IsPlayer() then 
        ---@cast own NPC
        self.UsePlayerAimAnimation = aimBlock
        self:SetCachedVar("NPC_CanGetUpVar", false, math.Rand(2, 5))
        --return
    else
        self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        rag:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        anim:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        fakePly:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
    end

    --own:TakeDamage(10000)
    --[[local debugMdl = ents.Create("base_anim")
    self.DebugMdl = debugMdl
    self:DeleteOnRemove(debugMdl)
    debugMdl:SetModel("models/Gibs/wood_gib01d.mdl")
    debugMdl:Spawn()]]

    
    --local own = self:GetOwner()
    --own:SetViewEntity(rag)
    --self:SetPos(self:GetPos() + Vector(0, 0, 15))

end

function ENT:RestorePlayerData()

    local own = self:GetOwner()
    if not IsValid(own) then return end

    --own:RemoveFlags(FL_DUCKING)
    local offset = self.m_vOwnViewOffset
    own:SetViewOffset(offset)
    if own:IsPlayer() then 
        ---@cast own Player
        own:SetCurrentViewOffset(self:HasKeyInput(IN_DUCK) and own:GetViewOffsetDucked() or offset)
    end
    
    own:SetMoveType(self.m_iOwnMoveType or MOVETYPE_STEP)
    own:SetCollisionGroup(self.m_iOwnCollisionGroup or COLLISION_GROUP_PLAYER)
    --own:SetSolid(self.m_iOwnSolid or SOLID_OBB)
    own:SetLightingOriginEntity(self.m_entOwnLightOrigin or NULL)

end

function ENT:RemoveSelf(killOwner)
    if CLIENT then return end

    local own = self:GetOwner()
    local rag = self:GetRagdoll()
    if IsValid(own) then
        if killOwner then
            if own:IsPlayer() then    
                own:Kill()
            else
                own:TakeDamage(own:GetMaxHealth() * 2)
            end
        end
    end

    -- 甲级战犯#2 has BEEn found
    -- cause: 这B玩意会在下一tick移除, 很显然某些状态会继续(包括BONEMERGE/父子级的状态, 这意味着设置位置的玩意完全无效)
    self:Remove()
    --self:OnRemove()
    --SafeRemoveEntityDelayed(self, tickInterval)
end

function ENT:OnRemove()

    if self.Removing then return end

    self.Removing = true
    if CLIENT then return end

    local rag = self:GetRagdoll()
    local own = self:GetOwner()


    --print(rag)
    if IsValid(own) then

        for ent, _ in pairs(self.OwnerModifiedEnts) do
            if not IsValid(ent) then continue end
            ent:SetOwner(own, true)
        end

        if own:IsPlayer() then
            local ea = own:EyeAngles(true)
            ea.r = 0
            own:SetEyeAngles(ea, true)
        end

        if own:GetMoveParent() == rag then
            own:SetParent(nil)
            own:RemoveEffects(EF_BONEMERGE)
            own:RemoveEffects(EF_BONEMERGE_FASTCULL)
        end

        self:RestorePlayerData()

        local newPos = self.GettingUp_OwnerPos
        
        if newPos then
            own:SetPos(newPos, true)
            own:SetLocalVelocity(vector_origin)
            timer.Simple(tickInterval, function()
                if not IsValid(own) then return end
                own:SetPos(newPos, true)
                own:SetLocalVelocity(vector_origin)
            end)
        end

    end

    if IsValid(rag) then
        -- 看起来两个都有用
        constraint.RemoveAll(rag)
        SafeRemoveEntityDelayed(rag, tickInterval)
    end

end
