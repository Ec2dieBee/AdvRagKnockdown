-- ToDo: 很显然这将成为一个"枢纽", 所以你要把功能模块一类的玩意加上
-- 很显然这会和Ragknockdown冲突, 但是目前先做进阶起身(是的 你不能在Ragknockdown里创飞一个正在起来的人, 这不好)
-- ToDo: 代码莫写死(模 块 化)
-- Done: NPC兼容

-- 显然的 Z-City的系统很Newbility
-- 但是我们仍然需要自己做一个, 除了复用键位以外应该不会有问题
-- 大概吧
-- 所以我看了他们的代码 然后没看懂(根本就没好好看所以约等于没看(看了第二次然后发现看的东西早就做完了, 没做的东西也不需要加进来))
-- 好了看了第三次终于看懂了(抓握物品), 这意味着我走反作用力的路线被彻底锁死了(这也意味着骷髅头不会把你砸死)
-- 大多数功能都是我进游戏实验出来的
-- 
-- lua_run print(Entity(1):GetViewModel():GetModel())
-- lua_run local ent = Entity(1):GetEyeTrace().Entity ent:RemoveInternalConstraint(1)
-- 
-- ToDo: 清清不用的值
-- ToDo: 把这个激八Mass检测杀了, 你不需要这个东西了, 他4Saken了(这里没有word.exe)
-- 
-- ToDo: 加个装死检测, 用你从其它代码学到的"Cache"
---警告! 这并不意味着你可以躲在电视后面听The Great Punishment然后拿霰弹枪射击**某个很大的猫科生物**
-- Done: 引入类似Z-City的健康系统, (意识(能否控制武器/控制力), 体力(最大控制力), 我猜这两个够用了(坐等其他人搬运Z-City健康系统.jpg))
-- ToDo: 让Miku可以舒适的射击

local isSP = game.SinglePlayer()

local vector_origin = Vector()

AddCSLuaFile()
local _
local tickInterval = engine.TickInterval()

local noArmVal = 55

--[[local blacklistedVM = {
    ["models/weapons/c_irifle.mdl"] = true,
    ["models/weapons/c_smg1.mdl"] = true,
    ["models/weapons/c_crowbar.mdl"] = true,
    ["models/weapons/c_357.mdl"] = true,
    ["models/weapons/c_pistol.mdl"] = true,
    ["models/weapons/c_scifiv.mdl"] = true,
    ["models/weapons/cstrike/c_mach_m249para.mdl"] = true,
}]]

-- 奈莉特供
local boneWhiteList = {
    ["ValveBiped.Bip01_Pelvis"] = true,
    ["ValveBiped.Bip01_L_Thigh"] = true,
    ["ValveBiped.Bip01_L_Calf"] = true,
    ["ValveBiped.Bip01_L_Foot"] = true,
    ["ValveBiped.Bip01_Spine1"] = true,
    ["ValveBiped.Bip01_Spine2"] = true,
    ["ValveBiped.Bip01_R_Clavicle"] = true,
    ["ValveBiped.Bip01_R_UpperArm"] = true,
    ["ValveBiped.Bip01_R_Forearm"] = true,
    ["ValveBiped.Bip01_R_Thigh"] = true,
    ["ValveBiped.Bip01_R_Calf"] = true,
    ["ValveBiped.Bip01_R_Foot"] = true,
    ["ValveBiped.Bip01_Head1"] = true,
    ["ValveBiped.Bip01_L_Clavicle"] = true,
    ["ValveBiped.Bip01_L_UpperArm"] = true,
    ["ValveBiped.Bip01_L_Forearm"] = true,
    ["ValveBiped.Bip01_L_Hand"] = true,
    ["ValveBiped.Bip01_R_Hand"] = true,

}
-- 在经历了如此之长的痛苦之后, 我决定: 强制设置每个模型的MASS, 我可去你妈的吧
-- 不在这个表里的pObj质量统统减少, I DONT CARE
-- Breen.mdl
local boneMassList = {
    ["ValveBiped.Bip01_Pelvis"] = 13,
    ["ValveBiped.Bip01_L_Thigh"] = 10,
    ["ValveBiped.Bip01_L_Calf"] = 5,
    ["ValveBiped.Bip01_L_Foot"] = 2.4,
    ["ValveBiped.Bip01_Spine1"] = 5,
    ["ValveBiped.Bip01_Spine2"] = 24,
    ["ValveBiped.Bip01_R_UpperArm"] = 3.5,
    ["ValveBiped.Bip01_R_Forearm"] = 1.75,
    ["ValveBiped.Bip01_R_Thigh"] = 10,
    ["ValveBiped.Bip01_R_Calf"] = 5,
    ["ValveBiped.Bip01_R_Foot"] = 2.4,
    ["ValveBiped.Bip01_Head1"] = 5,
    ["ValveBiped.Bip01_L_UpperArm"] = 3.5,
    ["ValveBiped.Bip01_L_Forearm"] = 1.75,
    --["ValveBiped.Bip01_L_Hand"] = 1.5,
    --["ValveBiped.Bip01_R_Hand"] = 1.5,
    ["ValveBiped.Bip01_L_Hand"] = 1.2,
    ["ValveBiped.Bip01_R_Hand"] = 1.2,

}

local armBones = {
    --[[["ValveBiped.Bip01_Spine2"] = {
        forceMul = 1,
        deltaAng = Angle(0, 0, 0)
    },]]
    --["ValveBiped.Bip01_Head1"] = 1,
    --["ValveBiped.Bip01_L_Clavicle"] = 1,
    --["ValveBiped.Bip01_R_Clavicle"] = 1,
    ["ValveBiped.Bip01_L_UpperArm"] = {
        forceMul = 1,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_L_Forearm"] = {
        forceMul = 1.5,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_R_UpperArm"] = {
        forceMul = 1,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_R_Forearm"] = {
        forceMul = 1,
        deltaAng = Angle(0, 0, 0)
    },
    --[[["ValveBiped.Bip01_L_Hand"] = {
        forceMul = 5,
        dampForceMul = 5,
        deltaAng = Angle()
    },]]
    --[[["ValveBiped.Bip01_R_Hand"] = {
        forceMul = 5,
        dampForceMul = 5,
        deltaAng = Angle(0, 0, 0)
    },]]
}
-- 我承认我的英语是一坨屎
local originalAnimBones = {
    ["ValveBiped.Bip01_Spine2"] = {
        forceMul = 1,
        deltaAng = Angle(0, 0, 0)
    },
    --["ValveBiped.Bip01_Head1"] = 1,
    --["ValveBiped.Bip01_L_Clavicle"] = 1,
    --["ValveBiped.Bip01_R_Clavicle"] = 1,
    ["ValveBiped.Bip01_L_UpperArm"] = {
        forceMul = 7,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_L_Forearm"] = {
        forceMul = 7,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_R_UpperArm"] = {
        forceMul = 7,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_R_Forearm"] = {
        forceMul = 7,
        deltaAng = Angle(0, 0, 0)
    },
    ["ValveBiped.Bip01_L_Hand"] = {
        forceMul = 7,
        dampForceMul = 5,
        deltaAng = Angle()
    },
    ["ValveBiped.Bip01_R_Hand"] = {
        forceMul = 7,
        dampForceMul = 5,
        deltaAng = Angle(0, 0, 0)
    },
}

local lArmDeltaBones = {
    ["ValveBiped.Bip01_L_Upperarm"] = true,
    ["ValveBiped.Bip01_L_Forearm"] = true,
    ["ValveBiped.Bip01_L_Hand"] = true,
}
local rArmDeltaBones = {
    ["ValveBiped.Bip01_R_Upperarm"] = true,
    ["ValveBiped.Bip01_R_Forearm"] = true,
    ["ValveBiped.Bip01_R_Hand"] = true,
}

--[[local twoHandsDelta = {
    --["ValveBiped.Bip01_R_Hand"] = Angle(0, -15),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(0, 35, 0),
    --["ValveBiped.Bip01_L_UpperArm"] = Angle(10, 0, 10),
    --["ValveBiped.Bip01_L_Forearm"] = Angle(0, 0, 0),
}


local upperBodyBones = {
    ["ValveBiped.Bip01_Spine2"] = 0.8,
}]]

local holdTypeActs = {
    ["pistol"] = ACT_HL2MP_IDLE_CROUCH_PISTOL,
    ["revolver"] = ACT_HL2MP_IDLE_REVOLVER,
    ["duel"] = ACT_HL2MP_IDLE_DUEL,
    ["smg"] = ACT_HL2MP_IDLE_CROUCH_SMG1,
    ["ar2"] = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
    ["shotgun"] = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
    ["rpg"] = ACT_HL2MP_IDLE_RPG,
    ["physgun"] = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
    ["crossbow"] = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
    ["camera"] = ACT_HL2MP_IDLE_CAMERA,
    ["slam"] = ACT_HL2MP_IDLE_CROUCH_SLAM,
    ["normal"] = ACT_HL2MP_IDLE,
    ["grenade"] = ACT_HL2MP_IDLE_GRENADE,
    ["melee"] = ACT_HL2MP_IDLE_MELEE,
    ["melee2"] = ACT_HL2MP_IDLE_MELEE2,
    ["knife"] = ACT_HL2MP_IDLE_KNIFE,
    ["fist"] = ACT_HL2MP_IDLE_FIST,
    ["passive"] = ACT_HL2MP_IDLE_PASSIVE,
    ["magic"] = ACT_HL2MP_IDLE_MAGIC,
}

local twoArmAimDelta = Vector(5, 5, -7)
local oneArmAimDelta = Vector(10, 5, -7)

local aimPosDelta = {
    ["pistol"] = oneArmAimDelta,
    ["revolver"] = oneArmAimDelta,
    ["duel"] = Vector(15, 10, -10),
    ["smg"] = twoArmAimDelta,
    ["ar2"] = twoArmAimDelta,
    ["shotgun"] = twoArmAimDelta,
    ["rpg"] = twoArmAimDelta,
    ["physgun"] = twoArmAimDelta,
    ["crossbow"] = twoArmAimDelta,
    ["camera"] = twoArmAimDelta,
    ["slam"] = oneArmAimDelta,
    ["normal"] = Vector(),
    ["grenade"] = oneArmAimDelta,
    ["melee"] = oneArmAimDelta,
    ["melee2"] = oneArmAimDelta,
    ["knife"] = oneArmAimDelta,
    ["fist"] = oneArmAimDelta,
    ["passive"] = twoArmAimDelta,
    ["magic"] = oneArmAimDelta,
}

-- 手调吧, QTMD
--[[local twoArmAimDelta = {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(50, -40, 180), 
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-50, 60, 180),
}
local oneArmAimDelta = {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(30, -20, 180), 
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-30, 30, 180),
}

local aimPosDelta = {
    ["pistol"] = oneArmAimDelta,
    ["revolver"] = oneArmAimDelta,
    ["duel"] = Vector(15, 10, -10),
    ["smg"] = twoArmAimDelta,
    ["ar2"] = twoArmAimDelta,
    ["shotgun"] = twoArmAimDelta,
    ["rpg"] = twoArmAimDelta,
    ["physgun"] = twoArmAimDelta,
    ["crossbow"] = twoArmAimDelta,
    ["camera"] = twoArmAimDelta,
    ["slam"] = oneArmAimDelta,
    ["normal"] = Vector(),
    ["grenade"] = oneArmAimDelta,
    ["melee"] = oneArmAimDelta,
    ["melee2"] = oneArmAimDelta,
    ["knife"] = oneArmAimDelta,
    ["fist"] = oneArmAimDelta,
    ["passive"] = twoArmAimDelta,
    ["magic"] = oneArmAimDelta,
}]]

-- 如果 这个武器的 ~= 热兵器(手雷一边凉快去) 那么
--     武器.不用自定义位置 = 真
-- 结束
local doOriginalHTs = {
    ["knife"] = true,
    ["melee"] = true,
    ["melee2"] = true,
    ["fist"] = true,
    ["magic"] = true,
    ["grenade"] = true,
    ["camera"] = true,
    ["slam"] = true,
    ["normal"] = true,
}
local noAimHTs = {
    [""] = true,
    ["normal"] = true,
    ["fist"] = true,
}
local meleeHTs = {
    ["melee"] = true,
    ["melee2"] = true,
    ["fist"] = true,
    ["knife"] = true,
}

local deltaedHT = {
    ["ar2"] = true,
    ["smg1"] = true,
    ["rpg"] = true,
    ["crossbow"] = true,
    ["shotgun"] = true,
}

local noCollides = {
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Forearm",
    "ValveBiped.Bip01_L_Thigh",
    "ValveBiped.Bip01_L_Calf",
    "ValveBiped.Bip01_R_Hand",
    "ValveBiped.Bip01_R_Forearm",
    "ValveBiped.Bip01_R_Thigh",
    "ValveBiped.Bip01_R_Calf",
}

local hitgroup_limbs = {0.2, 0.1}

local hitGroupMuls = {
    [HITGROUP_GENERIC] = {0.5, 1},
    [HITGROUP_HEAD] = {0.5, 2},
    [HITGROUP_CHEST] = {0.6, 0.5},
    [HITGROUP_STOMACH] = {0.8, 0.3},
    [HITGROUP_GEAR] = {0, 0},
    [HITGROUP_LEFTARM] = hitgroup_limbs,
    [HITGROUP_RIGHTARM] = hitgroup_limbs,
    [HITGROUP_LEFTLEG] = hitgroup_limbs,
    [HITGROUP_RIGHTLEG] = hitgroup_limbs,
}

local dmgTypeMuls = {
    [DMG_CRUSH] = {2, 5},
    [DMG_CLUB] = {1.5, 2.5},
    [DMG_SLASH] = {1.5, 0.8},
    [DMG_BLAST] = {0.3, 2},
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

-- 我去 失落科技!!!
---@param a Entity
---@param b Entity
local function cloneAtoB(b, a, fucked)
    if not fucked then
	    a:SetPos(b:GetPos())
	    a:SetAngles(b:GetAngles())
	    a:SetModel(b:GetModel())
    end
    a:SetModelScale(b:GetModelScale())
	a:SetMaterial(b:GetMaterial())
	a:SetSkin(b:GetSkin())
    a:SetColor(b:GetColor())

    a:SetRenderMode(b:GetRenderMode())
    a:SetRenderFX(b:GetRenderFX())
	--a:SetSubMaterial(number index=nil, string material=nil)
	for i = 0, #b:GetBodyGroups() - 1 do --测试得出的是能设置的比总数少1
		a:SetBodygroup(i, b:GetBodygroup(i))
	end
	for i = 0, #b:GetMaterials() - 1 do
		a:SetSubMaterial(i, b:GetSubMaterial(i))
	end
    if b:HasBoneManipulations() then
	    for i = 0, b:GetBoneCount() - 1 do
	    	a:ManipulateBonePosition(i, b:GetManipulateBonePosition(i))
	    	a:ManipulateBoneAngles(i, b:GetManipulateBoneAngles(i))
	    	a:ManipulateBoneScale(i, b:GetManipulateBoneScale(i))
	    	a:ManipulateBoneJiggle(i, b:GetManipulateBoneJiggle(i))
	    end
    end
	
end

---@param ent Entity
---@param pos Vector
---@return number
local function nearestBone(ent, pos, physRequired)

    local wls = {}

    if physRequired then
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local bone = ent:TranslatePhysBoneToBone(i)
            wls[bone] = true
        end
    end

    local nearest, dist = -1
    for i = 0, ent:GetBoneCount() - 1 do
        if physRequired and not wls[i] then continue end
        local bPos = ent:GetBonePosition(i)
        
        if nearest == -1 or bPos:Distance(pos) < dist then 
            nearest = i 
            dist = bPos:Distance(pos) 
        end

    end

    return nearest
end
local function boneHasParent(rag, i, pI)
    if i == pI then return true end
    local tries = 0
    while i ~= -1 and tries <= 256 do
        tries = tries + 1
        i = rag:GetBoneParent(i or 0)
        if i == pI then return true end
    end
    return false
end

-- 在学校想出来的神秘IK系统
-- 基于三角函数/余弦定理(极向还没想好但是2骨足够了)
-- 这个故事告诉我们高中知识还是有用的

local function calcBasicArmIK(armPos, armAng, handPos, mdlScale, pole, rotateAng, wtl)
    mdlScale = mdlScale or 1
    -- 理论上是个位置
    pole = pole or 0
    rotateAng = rotateAng or Angle(0, 0, 0)

    -- 事实上我的数学是一坨史, 但是这些玩意书上都有.jpg
    local c = handPos:DistToSqr(armPos)
    local a, b = 11.69 * mdlScale, 11.48 * mdlScale
    --print(a, b, c)
    --print((c ^ 2 + a ^ 2 - b ^ 2) / (2 * c * a))
    local cos1, cos2 = (c + a ^ 2 - b ^ 2) / (2 * (c ^ 0.5) * a), (a ^ 2 + b ^ 2 - c) / (2 * a * b)
    --print(cos1, cos2)
    -- 手动钳制(有笨比把范围搞成0-1了)
    cos1 = math.Clamp(cos1, -1, 1)
    cos2 = math.Clamp(cos2, -1, 1)
    local degUpperArm = math.deg(math.acos(cos1))
    local degForeArm = math.deg(math.acos(cos2))
    --print(degUpperArm, degForeArm)
    local baseAng = (handPos - armPos):Angle()
    baseAng:RotateAroundAxis(baseAng:Forward(), pole)
    baseAng:Normalize()

    --print(baseAng)
    
    --baseAng:RotateAroundAxis(baseAng:Right(), 0)
    local _, angUpperArm = LocalToWorld(vector_origin, rotateAng, vector_origin, baseAng)
    angUpperArm:RotateAroundAxis(baseAng:Right(), -degUpperArm)
    --angUpperArm:RotateAroundAxis(angUpperArm:Up(), rotateAng.y)
    --angUpperArm:RotateAroundAxis(angUpperArm:Forward(), rotateAng.r)
    
    -- 这里不能画图, 总而言之Forearm的角度可以是相对于(出于你作为人的"优越性", 应该是"只能是相对于")前臂(上一骨骼)的, 毕竟这是二维的
    local _, angForeArm = LocalToWorld(vector_origin, Angle(0, -180 + degForeArm), vector_origin, angUpperArm)
    --angForeArm:RotateAroundAxis(baseAng:Right(), degForeArm)
    --angForeArm:RotateAroundAxis(angForeArm:Right(), rotateAng.p)
    --angForeArm:RotateAroundAxis(angForeArm:Up(), rotateAng.y)
    --angForeArm:RotateAroundAxis(angForeArm:Forward(), rotateAng.r)

    --ctrl.DebugMdl:SetPos(handPos)
    --ctrl.DebugMdl:SetAngles(angUpperArm)
    if wtl then
        --_, wtl = LocalToWorld(vector_origin, Angle(90, 90, 0), vector_origin, wtl)
        _, angUpperArm = WorldToLocal(vector_origin, angUpperArm, vector_origin, wtl)
        _, angForeArm = WorldToLocal(vector_origin, angForeArm, vector_origin, wtl)
        --print(angUpperArm)
    end

    return angUpperArm, angForeArm
end

local function getCV(cv, st)
    cv = GetConVar("savee_advragknockdown_" .. cv)
    if not cv then return end
    if st then
        cv = cv["Get" .. st](cv)
    end

    return cv
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "很像ZCity的击倒"

ENT.AutomaticFrameAdvance = true

ENT.Category = "Savee Stuffs - CONCEPTS"
ENT.Spawnable = true

-- VARS

ENT.OnGroundState = 0.1
ENT.NextBroadcastNWEntity = -1

ENT.PreventPhysAttackTill = -1
ENT.NextCalcAnim = -1
ENT.NextCache = -1
ENT.NextRegenStamina = -1
ENT.NextRegenConsciousness = -1
ENT.NextSetLArmDelta = -1
ENT.NextSetRArmDelta = -1
ENT.CanSetLArmDelta = true
ENT.CanSetRArmDelta = true

ENT.CustomOwnerRenderOverride = nil

ENT.RagPhysDmgTakenCount = 0

ENT.Removing = false

ENT.ShadowCtrlData = {}
ENT.CacheTimers = {}
ENT.DI_MarkedAsTaken = {}
ENT.DI_GoingToTake = {}

ENT.Caches = {
    NPC_MoveGoal = Vector(),
    NPC_HasMoveGoal = Vector(),
    NPC_LastGoalUpdate = -1,
    NPC_LastCrawl = -1,
    NPC_ShouldRHand = false,
    NearWalling = 0,
}

ENT.RagPObjs = {}
ENT.RagLastModel = ""

ENT.GettingUp = false
ENT.GettingUp_SyncingToOwner = false
ENT.GettingUp_FaceAng = Angle()

ENT.UsePlayerAimAnimation = false

-- 享受你的Prone Mod但是是布娃娃版
-- 更加战术的操作, 我猜(这样你的狙击点就没那么容易被发现了)
ENT.LowPose = false

--ENT.LArm_Dist = 11
--ENT.RArm_Dist = 11

--ENT.LArm_LTW = vector_origin
--ENT.RArm_LTW = vector_origin

ENT.LHand_Grabbing = false
ENT.LHand_Grabbing_Broken = false
ENT.LHand_NextGrab = -1
ENT.LHand_GrabbingData = {}
ENT.RHand_Grabbing_Broken = false
ENT.RHand_Grabbing = false
ENT.RHand_NextGrab = -1
ENT.RHand_GrabbingData = {}

ENT.KeyInputs = {}
-- 用以解决30个插件不间断强奸EyePos造成的卡顿
ENT.VarCaches = {}

ENT.AnimationTable = {
    Getup = {
        --[[{
            Model = "models/Combine_Super_Soldier.mdl",
            Sequence = "cover_crouch", -- 可以是数字

            AngDelta = Angle(0, 0, 0), -- 相对角度偏移

            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.1, 0.9},
            Recover_Duck = {0.4, 0.5},
             --pitchmin, pitchmax, 翻转
            Pitch = {-90, 90, true}
        },]]
        {
            Model = "models/Zombie/Classic.mdl",
            Sequence = "slumprise_b", -- 可以是数字
            AngDelta = Angle(0, 0, 0), -- 相对角度偏移

            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.8, 0.9},
            Recover_Duck = {0.4, 0.5},
            --pitchmin, pitchmax, 翻转
            Pitch = {-90, 90, true}
        },
        {
            Model = "models/Zombie/Classic.mdl",
            Sequence = "slumprise_a", -- 可以是数字
            AngDelta = Angle(0, 0, 0), -- 相对角度偏移

            StartCycle = 0.3,
            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.8, 0.9},
            Recover_Duck = {0.4, 0.5},
            Pitch = {-90, 90}
        },
        --[[{
            Model = "models/Zombie/Classic.mdl",
            Sequence = "slumprise_b", -- 可以是数字
            AngDelta = Angle(0, -90, 0), -- 相对角度偏移

            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0, 0},
            Recover_Duck = {0, 0},
        },]]
    },
}

function ENT:SpawnFunction(ply, tr, ClassName)

    --if ( !tr.Hit ) then return end
    --print("?")
    if IsValid(ply.Savee_AdvRagKnockdown_Controller) then return end

    local SpawnPos = tr.HitPos
    
    local ent = ents.Create(ClassName)
    ent:SetAimEyeAngles(ply:EyeAngles())
    ent:SetOwner(ply)
    ent:SetPos(ply:GetPos())
    ent:Spawn()
    ent:Activate()

    return ent

end


-- 甲级战犯, 崩溃主要导致者(对NPC 我猜)
-- 导致我浪费好几个小时的罪魁祸首
-- 经验证, 可能是布娃娃移除的时机不对/未能消除所有约束导致
local function replaceRagconstraint(rag, pObjs, bchild, bparent, minAng, maxAng, fric)
    
    if not IsValid(rag) or not bchild or not bparent then return end
    if not rag:LookupBone(bparent) or not rag:LookupBone(bchild) then return end
    
    --local _
    minAng = minAng or Angle()
    maxAng = maxAng or Angle()
    fric = fric or 0
    
    -- 我甚至记得下来完整的前缀
    -- 每个正常模型都有的玩意, 没有就让它滚
    local lArm = pObjs and pObjs[bparent].id or rag:TranslateBoneToPhysBone(rag:LookupBone(bparent))
    local lHand = pObjs and pObjs[bchild].id or rag:TranslateBoneToPhysBone(rag:LookupBone(bchild))
    local lArmP = pObjs and pObjs[bparent].pObj or rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone(bparent)))
    local lHandP = pObjs and pObjs[bchild].pObj or rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone(bchild)))
    --print(rag:GetBoneName(rag:LookupBone(bparent)), rag:GetBoneName(rag:LookupBone(bchild)), rag:GetBoneName(rag:TranslatePhysBoneToBone(lArm)))
    local oldHandPos, oldHandAng, oldArmPos, oldArmAng = lHandP:GetPos(), lHandP:GetAngles(), lArmP:GetPos(), lArmP:GetAngles()
    --local oldHandAng = lHandP:GetAngles()

    --lHandP:ClearGameFlag(FVPHYSICS_PART_OF_RAGDOLL)
    --lHandP:ClearGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY)
    
    local ent = ents.Create("base_anim")
    ent:SetModel(rag:GetModel())
    ent:SetPos(rag:GetPos())
    ent:SetNoDraw(true)
    ent:DrawShadow(false)
    ent:Spawn()
    
    -- 我希望布娃娃的相对骨骼修改始终如一
    -- constraint.AdvBallsocket局部过头(即相对当前角度), 需要复原才行
    local parentMtx, childMtx = ent:GetBoneMatrix(ent:LookupBone(bparent)), ent:GetBoneMatrix(ent:LookupBone(bchild))
    if not parentMtx or not childMtx then SafeRemoveEntityDelayed(ent, tickInterval) return end
    local armPos, armAng = parentMtx:GetTranslation(), parentMtx:GetAngles()
    local handPos, handAng = childMtx:GetTranslation(), childMtx:GetAngles()
    
    --SafeRemoveEntityDelayed(ent, tickInterval)
    ent:Remove()

    lArmP:EnableMotion(false)
    lHandP:EnableMotion(false)

    lArmP:SetPos(armPos)
    lArmP:SetAngles(armAng)

    lHandP:SetPos(handPos)
    lHandP:SetAngles(handAng)
    
    local wtlLH = WorldToLocal(lHandP:GetPos(), lHandP:GetAngles(), lArmP:GetPos(), lArmP:GetAngles())

    --lHandP:SetAngles(oldArmAng)
    -- 瞧瞧我发现了什么, phys_ragdollconstraint!
    -- Verified By Savee14702 100%(Except one axis)
    --lHandP:SetAngles(oldHandAng)
    --lHandP:Wake()
    --local const = constraint.AdvBallsocket(rag, rag, lArm, lHand, wtlLH, nil, 0, 0, minAng.p, minAng.y, minAng.r, maxAng.p, maxAng.y, maxAng.r, fric, fric, fric, 0, 1)
    --local _, correctedAng = LocalToWorld(vector_origin, Angle(0, 0, -90), vector_origin, lArmP:GetAngles())
    --lHandP:SetAngles(correctedAng)
    constraint.AdvBallsocket(rag, rag, lArm, lHand, wtlLH, nil, 0, 0, minAng.p, minAng.y, minAng.r, maxAng.p, maxAng.y, maxAng.r, fric, fric, fric, 0, 1)
    rag:RemoveInternalConstraint(lHand)
    --print(const)
    --local constEst = constraint.Elastic(rag, rag, lArm, lHand, wtlLH, vector_origin, 20000, 500, 0.1, "", 0, false, Color(0, 0, 0, 0))
    --local constRop = constraint.Rope(rag, rag, lArm, lHand, wtlLH, vector_origin, 1, 01, 0, 0, "", false, Color(0, 0, 0, 0))
    --const:SetSaveValue("m_bSimulatedEveryTick", true)
    --PrintTable(const:GetSaveTable(true))

    --table.insert(rag.Savee_AdvRagKnockdown_ShitConsts, const)
    
    --constraint.Rope(rag, rag, lArm, lHand, wtlLH, Vector(), 0.01, 0, 0, 0, "", false, Color(0, 0, 0, 0))
    lArmP:SetPos(oldArmPos)
    lArmP:SetAngles(oldArmAng)
    lHandP:SetPos(oldHandPos)
    lHandP:SetAngles(oldHandAng)

    lArmP:EnableMotion(true)
    lHandP:EnableMotion(true)

    
    --lHandP:SetAngles(oldArmAng)
    --lHandP:Wake()

    --constraint.AddConstraintTable(rag, const)
    --[[if IsValid(constEst) then 
        table.insert(rag.Savee_AdvRagKnockdown_ShitConsts, constEst)
    end
    if IsValid(constRop) then 
        table.insert(rag.Savee_AdvRagKnockdown_ShitConsts, constRop)
    end]]

    
    --print("Approved By Queen JIAFEI 100%")
    
end


-- SVOnly
---@param rag Entity
local function modifyRagdoll(rag, pObjs)
    
    --print("ICALL")
    
    if CLIENT or not IsValid(rag) then return end
    local ctrl = rag.Savee_AdvRagKnockdown_Controller
    
    local angMax = Angle(65, 80, 80)
    
    --print(constraint.Find(rag, rag, "AdvBallsocket", rag:LookupBone("ValveBiped.Bip01_L_Forearm"), rag:LookupBone("ValveBiped.Bip01_L_Hand")))
    
    --PrintTable(constraint.FindConstraints(rag, "AdvBallsocket"))
    
    -- dumbass_define_animandphys.qci
    --if replace then
    replaceRagconstraint(rag, pObjs, "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm", -angMax, angMax, 0)
    replaceRagconstraint(rag, pObjs, "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm", -angMax, angMax, 0)
    --end

    do return end
    --local self = rag.Savee_AdvRagKnockdown_Controller
    --[[local pObjs = self.RagPObjs
    
    if not next(pObjs) or self.RagLastModel ~= rag:GetModel() then
        pObjs = {}
        -- Miku兼容
        for i = 0, rag:GetBoneCount() - 1 do
            
            local pID = rag:TranslateBoneToPhysBone(i)
            local pObj = rag:GetPhysicsObjectNum(pID)
            --pObj:SetMaterial("Player")
            
            ---@type PhysObj
            pObjs[rag:GetBoneName(i)] = {
                id = pID,
                pObj = pObj,
                physBone = rag:TranslatePhysBoneToBone(pID) == i,
            }
            
        end
        
        self.RagLastModel = rag:GetModel()
        self.RagPObjs = pObjs
        
    end]]
    
    local objCount = rag:GetPhysicsObjectCount()

    --for bone, data in pairs(pObjs) do
    for i = 0, objCount - 1 do
        --local pObj = data.pObj
        local pObj = rag:GetPhysicsObjectNum(i)
        local bone = rag:GetBoneName((rag:TranslatePhysBoneToBone(i)))
        
        --print(bone)
        
        if boneMassList[bone] then
            --print(bone)
            pObj:SetMass(math.max(pObj:GetMass(), boneMassList[bone]))
            --print(bone)
        --[[else--if data.physBone then
            local mass = pObj:GetMass()
            pObj:SetMass(math.max(1, mass * 0.2))]]
        end
        
    end

    if ctrl then ctrl.PreventPhysAttackTill = CurTime() + (objCount - 14) / 2 end
    
    -- 令人震惊的是AIMANGLE偏移居然是这个泌阳的Mass导致的
    -- 没有物理思维的恶果来了, btw这段注释是从Tick里迁来的
    --[[local rArm = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_R_Forearm")))
    local rHand = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_R_Hand")))
    local lArm = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_L_Forearm")))
    local lHand = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_L_Hand")))
    rHand:SetMass(rHand:GetMass() * 1.5)
    lHand:SetMass(lHand:GetMass() * 1.5)]]
    
    --[[local head = rag:LookupBone("ValveBiped.Bip01_Head1")
    if head then
        head = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(head))
        head:SetMass(head:GetMass() * 55.5)
    end]]
    --replaceRagconstraint(rag, "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_UpperArm", -angMax, angMax, 0)
    --replaceRagconstraint(rag, "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", -angMax, angMax, 0)
    --replaceRagconstraint(rag, "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_Pelvis", Angle(-45, -30, -75), Angle(45, 30, 35), 25)
    --replaceRagconstraint(rag, "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_Pelvis", Angle(-45, -30, -75), Angle(45, 30, 35), 25)
    
end

--if SERVER then modifyRagdoll(Entity(1):GetEyeTrace().Entity) end

local aimBlackListedNPCClass = {
    ["npc_citizen"] = true,
}

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
function ENT:SetCachedVar(key, var, time)
    local ct, last = CurTime(), self.CacheTimers[key] or -1
    if last > ct then return end
    self.Caches[key] = var
    self.CacheTimers[key] = ct + time
end


function ENT:RemoveSelf(killOwner)
    if CLIENT then return end
    local own = self:GetOwner()
    local rag = self:GetRagdoll()
    if IsValid(own) then
        --own:RemoveEffects(EF_BONEMERGE)
        --own:SetParent(nil)
        --[[for _, c in ipairs(self:GetChildren()) do
            if not IsValid(c) then continue end
            c:SetMoveParent(own)
        end]]
        if killOwner then
            if own:IsPlayer() then    
                own:Kill()
            else
                own:TakeDamage(own:GetMaxHealth() * 2)
            end
        end
    end
    self:Remove()
    --SafeRemoveEntity(self)
end

-- lua_run PrintTable(hook.GetTable()["CreateEntityRagdoll"])
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
        --[[hook.Add("CalcView", self, function(_, ply, pos, ang, fov)
            --local self = getController(ply)
            if not IsValid(self) or not IsValid(self:GetRagdoll()) then return end
            return self:CalcView(ply, pos, ang, fov)
    
        end)
        hook.Add("CalcViewModelView", self, function(_, ...)
            --local self = getController(LocalPlayer():GetViewEntity())
            if not IsValid(self) or not IsValid(self:GetRagdoll()) then return end
            return self:CalcViewModelView(...)

        end)
        hook.Add("PreDrawPlayerHands", self, function(_, ...)
            --local self = getController(LocalPlayer():GetViewEntity())
            if not IsValid(self) or not IsValid(self:GetRagdoll()) then return end
            return self:PreDrawPlayerHands(...)

        end)]]

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
    --rag:SetSolid(SOLID_VPHYSICS)
    --rag:DrawShadow(false)
    --rag:SetNoDraw(true)
    --rag:SetParent(own)

    cloneAtoB(own, rag)
    --rag:RemoveFlags(FL_OBJECT)

    rag:Spawn()
    rag.Savee_AdvRagKnockdown_Controller = self
    
    --[[local lHand = rag:LookupBone("ValveBiped.Bip01_L_Hand")
    local rHand = rag:LookupBone("ValveBiped.Bip01_R_Hand")

    if lHand then
        local handPos, handAng = rag:GetBonePosition(lHand)
        local armPos, armAng = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_L_Forearm"))
        self.LArm_LTW = WorldToLocal(handPos, angle_zero, armPos, armAng)
    end
    if rHand then
        local handPos, handAng = rag:GetBonePosition(rHand)
        local armPos, armAng = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_R_Forearm"))
        self.RArm_LTW = WorldToLocal(handPos, angle_zero, armPos, armAng)
    end]]
    --own:CaoWo("yesyes")

    if own:IsNPC() and getCV("npc_usehook_createentityragdoll", "Bool") then
        local hooks = hook.GetTable().CreateEntityRagdoll
        for _, id in ipairs(wlCERHooks) do
            hooks[id](own, rag, true)
        end
    end
    --rag:SetParent(nil)
    --rag:RemoveEffects(EF_BONEMERGE)
    rag:AddEffects(EFL_DONTBLOCKLOS)
    rag:AddFlags(FL_NOTARGET)
    rag:AddFlags(FL_NPC)
    --rag:RemoveFlags(FL_OBJECT)
    rag:SetCollisionGroup(own:IsPlayer() and COLLISION_GROUP_PLAYER or COLLISION_GROUP_DEBRIS_TRIGGER)

    --modifyRagdoll(rag)

    rag:SetNW2Entity("Savee_AdvRagKnockdown_Controller", self)

    --self:DeleteOnRemove(rag)

    --rag:DeleteOnRemove(self)
    --rag:CollisionRulesChanged()
    -- Miku很可爱, 但她只有158cm
    -- 这就是为什么这个值在这
    --print(calcBaseScale(rag))

    local mdlScale = calcBaseScale(rag)
    rag.Savee_AdvRagKnockdown_ModelScale = mdlScale
    --rag:SetParent(nil)
    --[[for i, b1 in pairs(noCollides) do
        for i2, b2 in pairs(noCollides) do
            if i2 == i then continue end
            local p1, p2 = rag:TranslateBoneToPhysBone(rag:LookupBone(b1) or 0), rag:TranslateBoneToPhysBone(rag:LookupBone(b2) or 0)
            --print(b1, b2)
            constraint.NoCollide(rag, rag, p1, p2)
        end
    end]]

    -- Still Miku兼容
    -- 部分模型的TranslateBoneToPhysBone结果不正确

    local pObjs = {}

    for pID = 0, rag:GetPhysicsObjectCount() - 1 do
        local pObj = rag:GetPhysicsObjectNum(pID)
        local i = rag:TranslatePhysBoneToBone(pID)

        local pos, ang = own:GetBonePosition(i)

        pObj:SetPos(pos)
        pObj:SetAngles(ang)

        pObj:SetVelocity(ownVel)
        pObj:Wake()

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
        if ct <= self.PreventPhysAttackTill then return end

        -- 我不认为你高速创到一个灰尘会导致你昏厥, 我觉得该昏的是灰尘
        local pObj = data.PhysObject
        
        local spd = data.HitSpeed --(data.OurOldVelocity - data.OurNewVelocity)
        local dot = spd:GetNormalized():Dot(data.HitNormal)
        local mul = (1 - dot) / 2
        spd = spd:Length()

        local official = boneMassList[rag:GetBoneName(pObj:GetIndex())]

        --print(spd * mul, mul)

        spd = math.max(spd * mul - (official and 600 or 1600) / math.max(1, mdlScale), 0)

        --print(spd)
        if spd == 0 or data.HitEntity == rag then return end

        local ent = data.HitEntity

        local dmg = spd / 10 - pObj:GetMass()
        --print(dmg, ent)

        --print(data.PhysObject)
        --PrintTable(data.PhysObject:GetTable())

        --[[local bone = nearestBone(rag, data.HitPos, true) --pObjtoBones[data.PhysObject] or 0
        local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]
        local hgMul = hitGroupMuls[hitGroup or 0]

        --print(rag:GetBoneName(bone), hitGroup)

        local stDmg = spd / 100 * (hgMul and hgMul[1] or 1)
        local csDmg = spd / 20 * (hgMul and hgMul[2] or 1)

        local stamina = self:GetStamina()
        stamina = stamina - stDmg

        local consc = self:GetConsciousness()
        consc = consc - csDmg

        self:SetStamina(math.max(0, stamina))
        self:SetConsciousness(math.max(0, consc))

        self.NextRegenStamina = math.max(ct, self.NextRegenStamina) + math.Clamp(stDmg / 20, 0.1, 1)
        self.NextRegenConsciousness = math.max(ct, self.NextRegenConsciousness) + math.Clamp(csDmg / 20, 0.1, 1.5)]]

        local di = DamageInfo()
        self.DI_MarkedAsTaken[di] = true
        di:SetDamage(dmg * (official and 1 or 0.2))
        di:SetDamageType(DMG_CRUSH)

        local pAtk = ent:GetPhysicsAttacker()
        di:SetAttacker(IsValid(pAtk) and pAtk or ent)
        di:SetInflictor(ent)

        --print(data.HitEntity)
        own:TakeDamageInfo(di, true)
        self.PreventPhysAttackTill = ct + tickInterval * 2
    
    end)

    self.RagLastModel = rag:GetModel()
    self.RagPObjs = pObjs

    self:SetRagdoll(rag)
    self:SetParent(rag)

    self:SetLocalPos(vector_origin)
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
    --print(self, "设置父级", own, rag)
    --if own:IsNPC() then
    --own:FollowBone(rag, 1)
    --else
    --PrintTable(own:GetChildren())
    --childs[#childs + 1] = own:GetInternalVariable("m_hMoveChild")
    
    -- 看起来是SetMoveParent太早导致的VPhysics.dll抽风(access violation exception)
    -- 在sa_03测试了, 击杀3-4个盾兵并未发生崩溃情况(老方法会崩溃, 参见autorun.lua)
    -- 我就一会点GmosLua的苦逼高中生, C艹这些玩意交给高人解决吧(奈莉看完也4了.jpg)
    timer.Simple(tickInterval, function() 
        if not IsValid(self) then return end
        -- [ARC9] Modern Warfare 2019 飞刀支持
        modifyRagdoll(rag, pObjs)
        own:SetMoveParent(rag)
        own:SetLocalPos(vector_origin)
        self.Initialized = true
    end)

    if own:IsNPC() then
        constraint.NoCollide(own, rag, -1, -1, true)
    end

    self.m_iOwnMoveType = own:GetMoveType()
    self.m_iOwnCollisionGroup = own:GetCollisionGroup()
    self.m_iOwnSolid = own:GetSolid()
    self.m_entOwnLightOrigin = own:GetLightingOriginEntity()
    own:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    own:SetMoveType(MOVETYPE_NONE)
    own:SetSolid(SOLID_NONE)
    own:AddEffects(EF_BONEMERGE)
    --own:AddEffects(EF_BONEMERGE_FASTCULL)
    own:SetLightingOriginEntity(rag)
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

   --[[hook.Add("Tick", self, function()
        if not IsValid(self) or self:IsMarkedForDeletion() then return end
        if not IsValid(self:GetRagdoll()) or not IsValid(own) or own:IsMarkedForDeletion() or own:Health() <= 0 then self:RemoveSelf(true) return end
        --if self:IsFlagSet(FL_KILLME) then return end
        --local ct = CurTime()
        --if self.NextCalcAnim > ct then return end
        self:Tick()
        --self.NextCalcAnim = ct + tickInterval * 2
    end)]]
    --hook.Add("Tick", self, self.Tick)

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

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "AimingWeapon")
    --self:NetworkVar("Bool", 1, "OnGround")
    self:NetworkVar("Entity", 0, "Ragdoll")
    self:NetworkVar("Float", 0, "LArmDelta")
    self:NetworkVar("Float", 1, "RArmDelta")
    self:NetworkVar("Float", 2, "Stamina")
    self:NetworkVar("Float", 3, "Consciousness")
    -- 这里有mRNA, 所以每个从这里拿的角度都得Normalize一遍
    self:NetworkVar("Angle", 0, "AimEyeAngles")
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

function ENT:TryGetUp(animTbl, forced)
    --do return false end
    -- 在这插入检测
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
        animTbl = next(besties) and besties[math.random(#besties)] or self.AnimationTable.Getup[math.random(#self.AnimationTable.Getup)]

    end

    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    local pos = rag:GetBonePosition(0)
    local pos2 = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Spine2") or 0)

    local ang = (pos - pos2):Angle()
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
    
    local tr = util.TraceHull({
        start = rag:GetPos() + Vector(0, 0, 35), 
        endpos = rag:GetPos() - Vector(0, 0, 15),
        filter = {rag, own},
        mins = -hull,
        maxs = hull,
    })

    anim:SetPos(tr.HitPos)
    anim:SetAngles(ang)
    anim:SetModel(animTbl.Model) 
    anim:SetSequence(animTbl.Sequence)
    anim:SetPlaybackRate(1)
    anim:SetCycle(animTbl.StartCycle or 0)
    --if IsValid(tr.Entity) then anim:SetParent(tr.Entity) end
    self.CurGetUpAnimData = animTbl

end

function ENT:ShouldGetUp()

    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    local stamina = self:GetStamina()
    local consc = self:GetConsciousness()

    if consc < 45 or stamina < 45 then return false end

    if self.GettingUp then
        local bp1 = (self.GettingUp_SyncingToOwner and self or self.GetupAnimModel):GetBonePosition(0)
        local bp2 = rag:GetBonePosition(0)
        local dist = bp1:Distance(bp2)

        if dist > 25 then return false end
    else
        local pos = rag:GetBonePosition(0)
        local tr = util.TraceLine({start = pos + Vector(0, 0, 5), endpos = pos - Vector(0, 0, 10), filter = {self, own}, mask = MASK_ALL})
        return tr.Hit
    end

    return true
end

function ENT:RestorePlayerData()

    local own = self:GetOwner()
    if not IsValid(own) then return end

    --own:RemoveFlags(FL_DUCKING)

    own:SetViewOffset(self.m_vOwnViewOffset)
    if own:IsPlayer() then own:SetCurrentViewOffset(self.m_vOwnViewOffset) end
    
    own:SetMoveType(self.m_iOwnMoveType or MOVETYPE_STEP)
    own:SetCollisionGroup(self.m_iOwnCollisionGroup or COLLISION_GROUP_PLAYER)
    own:SetSolid(self.m_iOwnSolid or SOLID_OBB)
    own:SetLightingOriginEntity(self.m_entOwnLightOrigin or NULL)

end

function ENT:OnRemove()

    --[[if self.Removing then return end
    self.Removing = true
    hook.Remove("Tick", self)
    --self:NextThink(CurTime() + 1)

    if CLIENT then 
        hook.Remove("CalcView", self)
        hook.Remove("CalcViewModelView", self)
        if IsValid(self.CSEnt) then self.CSEnt:Remove() end
        if IsValid(self.FakePlyModel) then self.FakePlyModel:Remove() end
        --if IsValid(self.CSRagdoll) then self.CSRagdoll:Remove() end
        return
    end]]
    --print("Removed")

    if CLIENT then return end

    local own = self:GetOwner()
    local rag = self:GetRagdoll()
    --print(rag)
    if IsValid(own) then
        self:RestorePlayerData()
        if own:IsPlayer() then
            local aea = self:GetAimEyeAngles()
            aea.r = 0
            own:SetEyeAngles(aea, true)
        end

        if own:GetMoveParent() == rag then
            own:RemoveEffects(EF_BONEMERGE)
            --own:RemoveEffects(EF_BONEMERGE_FASTCULL)
            own:SetParent(nil)
            -- DEBUG
            --own:SetPos(self:GetRagdoll():GetPos())

            --print(self, "布娃娃是我的父亲", own, rag)
        end
    end
    
    if IsValid(rag) then
        -- 不确定是哪个修复的bug
        constraint.RemoveAll(rag)
        SafeRemoveEntityDelayed(rag, tickInterval)
    end
    --if IsValid(self.GetupAnimModel) then SafeRemoveEntityDelayed(self.GetupAnimModel, 0) end
    --if IsValid(self.FakePlyModel) then SafeRemoveEntityDelayed(self.FakePlyModel, 0) end
    
    

end

-- Gmos实例
local function ListConditions(npc)
	
	if(!IsValid(npc)) then return end
	
	print(npc:GetClass().." ("..npc:EntIndex()..") has conditions:")
	
	for c = 0, 100 do
	
		if(npc:HasCondition(c)) then
		
			print(npc:ConditionName(c))
			
		end
		
	end
	
end

local function checkCanPull(ent)
    return ent:IsWorld() or IsValid(ent) and (ent:CreatedByMap() and ent:GetMoveType() ~= MOVETYPE_VPHYSICS or (IsValid(ent:GetPhysicsObject()) and not ent:GetPhysicsObject():IsMotionEnabled()) or ent:IsVehicle())
end

function ENT:DoBrainDamages(di, force)

    local ct = CurTime()
    if not force and self.PreventPhysAttackTill > ct then return end

    local dmg = di:GetDamage()
    local rag = self:GetRagdoll()

    local numpObjs = rag:GetPhysicsObjectCount()
    local pObjReduce = math.max(0, numpObjs - 15)
    dmg = dmg / math.max(1, pObjReduce / 2)

    local own = self:GetOwner()

    local tr = util.TraceHull({
        start = di:GetDamagePosition(),
        endpos = di:GetDamagePosition(),
        whitelist = true,
        filter = {rag},
        getRaw = true,
        mask = MASK_ALL,
        mins = Vector(-2, -2, -2),
        maxs = Vector(2, 2, 2),
    })
    local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
    local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]

    --print(hitGroup)

    local forceMul = math.Clamp(di:GetDamageForce():Length() / 3500, 0.5, 3)
    local hgMul = hitGroupMuls[hitGroup or 0]
    local dtMul = dmgTypeMuls[di:GetDamageType()]
    local stDmg = (dmg * 0.8) * (hgMul and hgMul[1] or 1) * (dtMul and dtMul[1] or 1) * forceMul * getCV("statcalc_" .. (own:IsPlayer() and "ply" or "npc") .. "_staminadmgmul", "Float")
    local csDmg = (dmg * 0.5) * (hgMul and hgMul[2] or 1) * (dtMul and dtMul[2] or 1) * forceMul * getCV("statcalc_" .. (own:IsPlayer() and "ply" or "npc") .. "_conscdmgmul", "Float")

    --print(rag:GetBoneName(bone), rag.Savee_AdvRagKnockdown_HitGroups[bone])

    local stamina = self:GetStamina()
    stamina = stamina - stDmg

    local consc = self:GetConsciousness()
    consc = consc - csDmg

    self:SetStamina(math.max(0, stamina))
    self:SetConsciousness(math.max(0, consc))

    self.NextRegenStamina = math.max(ct, self.NextRegenStamina) + math.Clamp(dmg / 20, 0.1, 3) * forceMul
    self.NextRegenConsciousness = math.max(ct, self.NextRegenConsciousness) + math.Clamp(dmg / 10, 0.1, 5) * forceMul / 2

end

local bound = Vector(3, 3, 3)

function ENT:Think()
    local ct = CurTime()

    local own = self:GetOwner()
    local rag = self:GetRagdoll()

    if CLIENT then 
        if not IsValid(rag) or not IsValid(own) then return true end

        local flOnGround = self:IsFlagSet(FL_ONGROUND)
        local nwOnGround = self:GetNW2Bool("Savee_AdvRagKnockdown_OnGround")

        if nwOnGround and not flOnGround then
            rag:AddFlags(FL_ONGROUND)
        elseif flOnGround then
            rag:RemoveFlags(FL_ONGROUND)
        end

        if own:IsPlayer() and not rag.GetPlayerColor then
            function rag:GetPlayerColor()
                return own:GetPlayerColor()
            end
        end

        if rag.RenderOverride ~= self.CustomRagRenderOverride then
            rag.RenderOverride = self.CustomRagRenderOverride
        end

        return true 
    end
    if not IsValid(own) or own:Health() <= 0 or (own:IsPlayer() and not own:Alive()) then self:RemoveSelf() return end
    local isPly = own:IsPlayer()

    local wep = own:GetActiveWeapon()
    
    if IsValid(wep) then
        local wepHT
        wepHT = wep:GetHoldType()

        if noAimHTs[wepHT] then
            wep:SetNextPrimaryFire(ct + 0.2)
            wep:SetNextSecondaryFire(ct + 0.2)
        end
    end
    self.DI_MarkedAsTaken = {}
    
    local rag = self:GetRagdoll()
    if not IsValid(rag) then self:RemoveSelf(true) end

    local eyeatt = rag:LookupAttachment("eyes")
    if eyeatt == 0 then return end

    local eyepos = rag:GetAttachment(eyeatt).Pos
    local eyeang = rag:GetAttachment(eyeatt).Ang

    local aea = self:GetAimEyeAngles()
    local stamina, consc = self:GetStamina(), self:GetConsciousness()
    
    local mdlScale = rag.Savee_AdvRagKnockdown_ModelScale

    -- NPCNPCNPC
    if not isPly then
        --print(self:GetRArmDelta())
        local goal = own:GetCurWaypointPos()
        if goal == vector_origin then goal = own:GetGoalPos() end
        local hasGoal = self:GetCachedVar("NPC_HasMoveGoal", goal ~= vector_origin)
        --self.Caches.NPC_MoveGoal = hasGoal and goal
        --self.Caches.NPC_HasMoveGoal = hasGoal
        if hasGoal then
            self.Caches.NPC_LastGoalUpdate = ct --hasGoal and goal
            self:SetCachedVar("NPC_MoveGoal", goal, 1)
            self:SetCachedVar("NPC_HasMoveGoal", hasGoal, math.random(2, 4))

            local noArm = noAimHTs[IsValid(wep) and wep:GetHoldType() or ""]
            self:SetCachedVar("NPC_ShouldRHand", self:GetCachedVar("NPC_ShouldRHand", not self:GetCachedVar("NPC_ShouldRHand")), noArm and 0.8 or 0.4)
        else
            self:SetCachedVar("NPC_HasMoveGoal", hasGoal, 0.1)
        end
        self:SetCachedVar("NPC_CanGetUpVar", math.random(100) >= 85, math.Rand(3, 7))

        self.LowPose = hasGoal

        local target = own:GetNPCState() == NPC_STATE_SCRIPT and own:GetTarget() or own:GetEnemy()
        if IsValid(target) then
            --print(target)
            local sPos = own:GetShootPos()
            local aim = target:BodyTarget(own:GetShootPos(true)) --(target:GetPos() + target:OBBCenter() - sPos):Angle()
            aim = (aim - sPos):Angle()
            aim:Normalize()
            
            --aim.r = aea.r
            --aim.y = own:GetIdealYaw()
            --print(aim)
            self:SetAimEyeAngles(aim) --LerpAngle(0.5, aea, aim))
        else
            local stuff = own:EyeAngles(true)
            stuff.y = own:GetIdealYaw()
            self:SetAimEyeAngles(LerpAngle(0.5, aea, stuff))
        end

        --ListConditions(own)
        
        local ang = Angle(0, aea.y, 0)
        --own:SetLocalAngles(ang)
        --own:SetPos(rag:GetPos() - own:OBBCenter(), true)

        if consc < 45 then
            own:ClearSchedule()
            --own:ClearGoal()
            --own:SetActivity(ACT_IDLE)
            own:NextThink(ct + 0.15)
            --print(1)
        end

    else
        local av = own:GetAimVector()
        own:SetEyeAngles(av:Angle(), true)
    end


    -- 操作

    if (not isPly and self:GetCachedVar("NPC_CanGetUpVar") or self:HasKeyInput(IN_JUMP)) and not self.GettingUp then
        
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

        self:TryGetUp(next(besties) and besties[math.random(#besties)] or self.AnimationTable.Getup[math.random(#self.AnimationTable.Getup)])

    end

    --self:DoGrabDetection()

    -- 小东西

    local fakePly = self.FakePlyModel

    if not IsValid(fakePly) then return end
    local wep = own:GetActiveWeapon()
    local wepHT = IsValid(wep) and wep:GetHoldType() or "normal"
    --own:SetActivity((IsValid(wep) and wepHT == "shotgun") and ACT_MP_CROUCH_IDLE or ACT_MP_STAND_IDLE)
    --fakePly:SetPos(self:GetPos() + Vector(0, 0, 30))
    --local _, ang = LocalToWorld(vector_origin, own:EyeAngles(), pelvis:GetPos(), pelvis:GetAngles())
    
    --ang:RotateAroundAxis(ang:Forward(), 90)
    fakePly:SetAngles(aea)

    --fakePly:SetNoDraw(false)
    --fakePly:SetModel(own:GetModel())

    if isPly or self.UsePlayerAimAnimation then
        fakePly:SetSequence(fakePly:SelectWeightedSequence(IsValid(wep) and holdTypeActs[wepHT] or ACT_HL2MP_IDLE))
    else
        fakePly:SetSequence(own:GetSequence())
    end
    --print(own:GetActivity())
    fakePly:SetCycle(own:GetCycle())
    --fakePly:FrameAdvance()
    fakePly:SetPos(self:GetPos())

    if not isPly then
        fakePly:SetPoseParameter("aim_pitch", own:GetPoseParameter("aim_pitch") or 0)
        fakePly:SetPoseParameter("aim_yaw", own:GetPoseParameter("aim_yaw") or 0)
    end

    -- 检测
    local pelvisPos = rag:GetBonePosition(0)
    local groundTr = util.TraceHull({
        start = pelvisPos,
        endpos = pelvisPos - Vector(0, 0, 64 * mdlScale),
        filter = {rag, own},
        maxs = bound * mdlScale,
        mins = -bound * mdlScale,
    })
    local hit = groundTr.Hit
    --print(groundTr.Hit)
    local newOGS = 0
    if hit then
        newOGS = 1
    else
        if IsValid(self.LHand_Grabbing) then
            newOGS = newOGS + 0.3
        end
        if IsValid(self.RHand_Grabbing) then
            newOGS = newOGS + 0.3
        end
    end
    self.OnGroundState = math.Approach(self.OnGroundState, newOGS, hit and 0.25 or 0.35)

    local flOnGround = self:IsFlagSet(FL_ONGROUND)

    if self.OnGroundState >= 0.6 and not flOnGround then
        rag:AddFlags(FL_ONGROUND)
        self:SetNW2Bool("Savee_AdvRagKnockdown_OnGround", true)
    elseif flOnGround then
        rag:RemoveFlags(FL_ONGROUND)
        self:SetNW2Bool("Savee_AdvRagKnockdown_OnGround", false)
    end
    --print(self.OnGroundState)

    --print(hit)

    if not hit and (self.LHand_Grabbing or self.RHand_Grabbing) then
        self:SetStamina(stamina - 0.1)
        if self.NextRegenStamina - ct < 3 then
            self.NextRegenStamina = math.max(self.NextRegenStamina, ct) + 0.15
        end
    end

    if self.NextRegenStamina <= ct then
        self:SetStamina(math.min(consc + 5, stamina + 2))
    elseif consc < stamina then
        self:SetStamina(consc)
    end
    if self.NextRegenConsciousness <= ct then
        self:SetConsciousness(math.min(100, consc + 2))
    end

    if not self:ShouldUseCachedVar("NearWalling") then
        local dist = 32 * mdlScale
        local tr = util.QuickTrace(eyepos, aea:Forward() * dist, own)
        --print((64 - tr.HitPos:Distance(eyepos)) / 64)
        self:SetCachedVar("NearWalling", math.min((dist - tr.HitPos:Distance(eyepos)) / dist, 0.9), 0.2)
    end

    if consc < 25 then
        self:SetAimingWeapon(false)
    end

    --print(rag:OnGround())

    -- 起身
    if self.GettingUp and not self:ShouldGetUp() then
        self.GettingUp = false
    elseif self.GettingUp then

        local anim = self.GetupAnimModel
        local aimAng = self:GetAimEyeAngles()
        aimAng.r = math.Approach(aimAng.r, 0, 15)

        self:SetAimEyeAngles(aimAng)
        
        local animData = self.CurGetUpAnimData

        --local myMdl, animMdl = self:GetModel(), animData.Model
        local cyc = anim:GetCycle()
        --print(cyc, animData.Recover[2])

        if cyc >= animData.Recover[2] then
            local tr = util.TraceEntityHull({
                start = pelvisPos + Vector(0, 0, 2),
                endpos = pelvisPos - Vector(0, 0, 100),
                filter = {rag, own},
            }, own)

            --print(tr.Entity)

            --own:SetVelocity(Vector())
            --print(self, "我彻底起来了", own, rag)

            own:SetParent(nil)
            rag:SetVelocity(Vector())
            self:SetVelocity(Vector())
            self:RemoveSelf()
            own:SetPos(tr.HitPos, true)
            local faceAng = self.GettingUp_FaceAng
            timer.Simple(tickInterval, function()
                if not IsValid(own) then return end
                own:SetPos(tr.HitPos + Vector(0, 0 ,0.1), true)
                own:SetAngles(faceAng)
                own:SetLocalVelocity(Vector())
            end)
            return
        elseif cyc >= animData.Recover[1] and self:GetParent() == rag then

            local ang = self:GetAimEyeAngles()
            ang:Normalize()
            ang.z = 0
            ang.p = 0

            local tr = util.TraceLine({
                start = pelvisPos + Vector(0, 0, 2),
                endpos = pelvisPos - Vector(0, 0, 100),
                filter = {rag, own}
            }, own)

            --print(self, "我快起来了", own, rag)

            self:SetParent(nil)
            self:SetPos(tr.HitPos + Vector(0, 0, 0.2))
            self:SetAngles(ang)
            self:SetModel(own:GetModel())
            self:SetSequence(own:GetSequence())
            self:SetPlaybackRate(own:GetPlaybackRate())
            self:SetCycle(own:GetCycle())
            self:SetPoseParameter("aim_pitch", own:GetPoseParameter("aim_pitch"))
            self:SetPoseParameter("aim_yaw", own:GetPoseParameter("aim_yaw"))
            self.GettingUp_SyncingToOwner = true
            --own:SetAngles(self.GettingUp_FaceAng)
            --self:SetNoDraw(false)
        elseif cyc >= animData.Recover[1] then
            self:SetPoseParameter("aim_pitch", own:GetPoseParameter("aim_pitch"))
            self:SetPoseParameter("aim_yaw", own:GetPoseParameter("aim_yaw"))
            self:SetAimEyeAngles(LerpAngle(0.1, self:GetAimEyeAngles(), self.GettingUp_FaceAng))
        end

        return

    elseif self:GetParent() ~= rag then
        --print(self, "NO DADDY STOPPPPPPPPPPP", own, rag)
        self:SetParent(rag)
    end

    -- 数据
    
    if own:GetMoveType() ~= MOVETYPE_NONE then
        self.m_iOwnMoveType = own:GetMoveType()
        own:SetMoveType(MOVETYPE_NONE)
    end
    if own:GetCollisionGroup() ~= COLLISION_GROUP_IN_VEHICLE then
        self.m_iOwnCollisionGroup = own:GetCollisionGroup()
        own:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    end
    if own:GetSolid() ~= SOLID_NONE then
        self.m_iOwnSolid = own:GetSolid()
        own:SetSolid(SOLID_NONE)
    end
    if own:GetLightingOriginEntity() ~= rag then
        self.m_entOwnLightOrigin = own:GetLightingOriginEntity()
        own:SetLightingOriginEntity(rag)
    end

    if self.NextBroadcastNWEntity <= ct then
        self.NextBroadcastNWEntity = ct + 2
        own:SetNW2Entity("Savee_AdvRagKnockdown_Controller", self)
        rag:SetNW2Entity("Savee_AdvRagKnockdown_Controller", self)
    end

    self.RagPhysDmgTakenCount = math.max(0, self.RagPhysDmgTakenCount - 3)

    -- 杂

    if isPly then
        own:SetCurrentViewOffset(vector_origin)
        own:SetViewOffset(vector_origin)
        --own:SetViewOffsetCro(vector_origin)
    --else
    end

    --own:SetLocalPos(vector_origin)
    --own:SetPos(vector_origin)
    --own:SetLocalPos(Vector(18, 0, -3))
    --local hitpos = own:GetEyeTrace().HitPos
    self:NextThink(ct + 0.1)
    return true

end

local shadowDatas = {
    --"maxspeed",
    "maxangular",
}
local shadowDampDatas = {
    "maxspeeddamp",
    "maxangulardamp",
}

local infos = {
    "AmmoType",
    "Attacker",
    "BaseDamage",
    "Damage",
    "DamageBonus",
    "DamageCustom",
    "DamageForce",
    "DamagePosition",
    "DamageType",
    "Inflictor",
    "MaxDamage",
    "ReportedPosition",
    "Weapon",
}

local bodySpeedForceMul = 1
local bodyAngForceMul = 1
local armSpeedForceMul = 1
local armAngForceMul = 1

local legDelta = 35

local torsoUseMass = true
local torsoMoveUseMass = true
local headUseMass = true
local handUseMass = true
local handAimUseMass = true
local pelvisUseMass = false
local legUseMass = true
local getupUseMass = true

local function getPhysBonePosAng(tbl, name)
    local pObj = (tbl[name] or {}).pObj
    if not pObj then return vector_origin, angle_zero end
    
    return pObj:GetPos(), pObj:GetAngles()
end

-- 这样你就不必来来回回

local torsoang, torsoangdamp, torsospd, torsospddamp, torsodampfactor, torsodelta = 450, 250, 0, 0, 0.8, 0.1
--local torsomovespd, torsomovespddamp, torsomovespddelta = 450, 450, 0.2
local headang, headangdamp, headspd, headspddamp, headdampfactor, headdelta = 80, 50, 0, 0, 0.8, 0.05
local handang, handangdamp, handspd, handspddamp, handdampfactor, handdelta = 265, 265, 635, 235, 0.8, 0.2
local handaimang, handaimangdamp, handaimspd, handaimspddamp, handaimdampfactor, handaimdelta = 250, 150, 5, 0, 0.8, 0.05
local armaimang, armaimangdamp, armaimspd, armaimspddamp, armaimdampfactor, armaimdelta = 250, 150, 0, 0, 0.5, 0.1
local pelvisang, pelvisangdamp, pelvisspd, pelvisspddamp, pelvisdampfactor, pelvisdelta = 0, 10, 0, 0, 0.8, 0.15
local legang, legangdamp, legspd, legspddamp, legsdampfactor, legsdelta = 25, 5, 0, 0, 0.2, 0.2

-- 为了避免强奸你的性能 我们制作了一个Tick 用以执行那些*不得不*每Tick执行的操作
-- 快感谢Tick吧
-- ZCity没解决布娃娃抽风乱动的bug, 所以这里就那样
-- 我力竭了
-- 2026/7/5: 甚至分离了更多东西, 希望能优化性能
function ENT:DealWithAnims(isPly, aimingWeapon, noArm, wepHT, isMeleeHT)


    if CLIENT or not self.Initialized then return end

    --print("1")
    --print(self:GetAimingWeapon())

    --local npcForceMul = 1

    local ct = CurTime()

    --self:SetAimEyeAngles(Angle())

    ---@type Entity
    local own = self:GetOwner()
    ---@type Entity
    local rag = self:GetRagdoll()

    --cloneAtoB(own, rag, true)
    --rag:SetFriction(10)

    --print(rag:GetVelocity())
    local mdlScale = rag.Savee_AdvRagKnockdown_ModelScale

    local caches = self.Caches

    --local av = own:GetAimVector()
    local aea = self:GetAimEyeAngles()
    --print(own:GetGoalPos())

    local in_forward = not isPly and caches.NPC_HasMoveGoal or self:HasKeyInput(IN_FORWARD)
    --local in_back = self:HasKeyInput(IN_BACK)
    local in_duck = self:HasKeyInput(IN_DUCK)

    local pObjs = self.RagPObjs
    local shadowCtrls = {}

    --print(numpObjs)

    --[[if not next(pObjs) or self.RagLastModel ~= rag:GetModel() then
        pObjs = {}
        -- Miku兼容
        for i = 0, rag:GetBoneCount() - 1 do
            
            local pID = rag:TranslateBoneToPhysBone(i)
            local pObj = rag:GetPhysicsObjectNum(pID)
            --pObj:SetMaterial("Player")

            ---@type PhysObj
            pObjs[rag:GetBoneName(i)] = {
                id = pID,
                pObj = pObj,
                physBone = rag:TranslatePhysBoneToBone(pID) == i,
            }

        end

        self.RagLastModel = rag:GetModel()
        self.RagPObjs = pObjs

    end]]

    --[[for i = 0, numpObjs - 1 do

        local pObj = rag:GetPhysicsObjectNum(i)
        --pObj:SetDamping(0, 10)
        
        --[[---@type PhysObj
        pObjs[rag:GetBoneName(rag:TranslatePhysBoneToBone(i))] = {
            id = i,
            pObj = rag:GetPhysicsObjectNum(i),
        }]

    end]]

    if not next(pObjs) then return end
    if not pObjs["ValveBiped.Bip01_Spine2"] then pObjs["ValveBiped.Bip01_Spine2"] = pObjs["ValveBiped.Bip01_Spine1"] end

    if not pObjs["ValveBiped.Bip01_Spine2"] then 
        self:RemoveSelf() 
        error("Model not supported: " .. own:GetModel() .. "\nMake sure the model have a physobj on ValveBiped.Bip01_Spine2/ValveBiped.Bip01_Spine1!")
    end

    ---@type PhysObj
    local torso = pObjs["ValveBiped.Bip01_Spine2"].pObj


    local eyeatt = rag:LookupAttachment("eyes")
    local eyepos = own:EyePos()
    local eyeang = own:EyeAngles()
    if eyeatt ~= 0 then
        eyepos = rag:GetAttachment(eyeatt).Pos
        eyeang = rag:GetAttachment(eyeatt).Ang        
    end

    --[[for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local pObj = rag:GetPhysicsObjectNum(i)
        pObj:ApplyTorqueCenter(-pObj:GetAngleVelocity() * tickInterval * pObj:GetMass())
        --pObj:ApplyForceCenter(-pObj:GetVelocity() * tickInterval * pObj:GetMass())
    end]]

    --local posdelta = own:EyePos() - own:GetPos()

    --print(1)

    --AddOriginToPVS(eyepos)

    --local head = pObjs["ValveBiped.Bip01_Head1"] and pObjs["ValveBiped.Bip01_Head1"].pObj
    --local headMass = head and head:GetMass() or 0

    --do return end

    --self:SetAimingWeapon(true)
    -- 矫正姿势
    if in_duck then

        
        --local pelvisAng = aea --Angle(pelvis:GetAngles().p, aea.y, aea.r)

        --local mass = pelvis:GetMass()
        --pelvis:EnableMotion(false)
        local angFace = Angle(0, 90, 0)
        shadowCtrls["ValveBiped.Bip01_Pelvis"] = {
            angle = angFace,
            maxspeed = pelvisspd,
            maxspeeddamp = pelvisspddamp,
            maxangular = pelvisang,
            maxangulardamp = pelvisangdamp,
            dampfactor = pelvisdampfactor,
            delta = pelvisdelta,
            addMass = pelvisUseMass,
        }
        local _, lLeg = LocalToWorld(vector_origin, Angle(-45, -90 + legDelta, -90), vector_origin, angFace)
        local _, rLeg = LocalToWorld(vector_origin, Angle(-45, -90 - legDelta, -90), vector_origin, angFace)
        shadowCtrls["ValveBiped.Bip01_L_Thigh"] = {
            angle = lLeg,
            maxspeed = legspd,
            maxspeeddamp = legspddamp,
            maxangular = legang,
            maxangulardamp = legangdamp,
            dampfactor = legsdampfactor,
            delta = legsdelta,
            addMass = legUseMass,
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
        }
        _, lLeg = LocalToWorld(vector_origin, Angle(0, 120, 0), vector_origin, lLeg)
        _, rLeg = LocalToWorld(vector_origin, Angle(0, 120, 0), vector_origin, rLeg)
        shadowCtrls["ValveBiped.Bip01_L_Calf"] = {
            angle = lLeg,
            maxspeed = legspd,
            maxspeeddamp = legspddamp,
            maxangular = legang,
            maxangulardamp = legangdamp,
            dampfactor = legsdampfactor,
            delta = legsdelta,
            addMass = legUseMass,
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
        }
        
    end

    -- Ragdoll CTRLs
    --print(wep:StillWaiting())

    if aimingWeapon and not noArm then

        local oldLArm = self:GetLArmDelta()
        local oldRArm = self:GetRArmDelta()

        --own:RemoveFlags(FL_DUCKING)
        own:SetAbsVelocity(rag:GetVelocity())
        --own:AddFlags(FL_ONGROUND)

        --local newpos, newang = LocalToWorld(Vector(32, 0, -5), Angle(), handpos, handang)

        --own:SetPos(LerpVector(0.98, handpos, tr.HitPos))
        --own:SetLocalPos(Vector(3, 0,))
        --[[do
            local tr = util.TraceLine({
                start = eyepos,
                endpos = eyepos + self:GetAimEyeAngles():Forward() * 65536,
                filter = {own, rag},
                mask = MASK_SHOT,
            })
            self.DebugMdl:SetPos(tr.HitPos)
        end]]
        --[[if isPly then
            own:SetCurrentViewOffset(vector_origin)
        else
            own:SetViewOffset(vector_origin)
        end
        --own:SetLocalPos(Vector(18, 0, -3))
        --local hitpos = own:GetEyeTrace().HitPos

        local wep = own:GetActiveWeapon()
        --own:SetActivity((IsValid(wep) and wepHT == "shotgun") and ACT_MP_CROUCH_IDLE or ACT_MP_STAND_IDLE)
        --fakePly:SetPos(self:GetPos() + Vector(0, 0, 30))
        --local _, ang = LocalToWorld(vector_origin, own:EyeAngles(), pelvis:GetPos(), pelvis:GetAngles())
        
        --ang:RotateAroundAxis(ang:Forward(), 90)
        fakePly:SetAngles(aea)

        --fakePly:SetNoDraw(false)
        --fakePly:SetModel(own:GetModel())

        if isPly or self.UsePlayerAimAnimation then
            fakePly:SetSequence(fakePly:SelectWeightedSequence(IsValid(wep) and holdTypeActs[wepHT] or ACT_HL2MP_IDLE))
        else
            fakePly:SetSequence(own:GetSequence())
        end
        --print(own:GetActivity())
        fakePly:SetCycle(own:GetCycle())
        --fakePly:FrameAdvance()
        fakePly:SetPos(self:GetPos())

        if not isPly then
            fakePly:SetPoseParameter("aim_pitch", own:GetPoseParameter("aim_pitch") or 0)
            fakePly:SetPoseParameter("aim_yaw", own:GetPoseParameter("aim_yaw") or 0)
        end]]


        --[[local pos, ang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_R_Hand"))

        pos, ang = LocalToWorld(Vector(8, 0, -3), Angle(), pos, ang)
        local tr = util.TraceLine({
            start = pos,
            endpos = pos + ang:Forward() * 65535,
            filter = {own, rag}
        })]]

        local fakePly = self.FakePlyModel

        if not IsValid(fakePly) then return end

        local pos, ang = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_R_Hand")

        pos, ang = LocalToWorld(Vector(8, 0, -3), Angle(), pos, ang)

        --eyeang = aea --(own:GetEyeTrace().HitPos - eyepos):Angle()
        --eyeang:Normalize()
        --local ea = eyeang:GetNormalized()
        --self.DebugMdl:SetPos(own:GetEyeTrace().HitPos)

        --print(own:EyePos(), eyepos, eyeang, own:EyeAngles())

        --[[for bName, _ in pairs(upperBodyBones) do
            
            local pObj = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(rag:LookupBone(bName)))
            pObj:Wake()
        
            local pos, ang = self:GetBonePosition(self:LookupBone(bName))

            pObj:ComputeShadowControl({
                secondstoarrive = 0.01,
                
                angle = ang,
                maxspeed = 0,
                maxspeeddamp = 0,
                maxangular = 50 + pObj:GetMass() * 10,
                maxangulardamp = 10 + pObj:GetMass(),
                dampfactor = 0.8,
                delta = 0.1,
            })

        end]]
        
        local target = fakePly --blacklistedVM[own:GetViewModel():GetModel()] and self or fakePly
        --local angDelta = Angle(-10, 0, 50)

        --print(own:EyeAngles())

        local angFace = Angle(-90, -90, 180)
        local angFaceTorso = Angle(-90, -90, 0)
        
        --print
        --print(torso)
        shadowCtrls["ValveBiped.Bip01_Spine2"] = {
            --secondstoarrive = 0.01,
            
            angle = angFaceTorso,
            maxspeed = torsospd,
            maxspeeddamp = torsospddamp,
            maxangular = torsoang,
            maxangulardamp = torsoangdamp,
            dampfactor = torsodampfactor,
            delta = torsodelta,
            addMass = torsoUseMass,
        }

        
        shadowCtrls["ValveBiped.Bip01_Head1"] = {
            --secondstoarrive = 0.15,
            
            angle = angFace,
            maxspeed = headspd,
            maxspeeddamp = headspddamp,
            maxangular = headang,
            maxangulardamp = headangdamp,
            dampfactor = headdampfactor,
            delta = headdelta,
            addMass = headUseMass,
        }
        
        -- armBones
        -- 手臂

        local nonFirearm = doOriginalHTs[wepHT]

        --print(nonFirearm)

        local lArmDeltaMax = 1
        local rArmDeltaMax = 1
        for bName, data in pairs(nonFirearm and originalAnimBones or armBones) do
        
            --local i = rag:TranslateBoneToPhysBone(rag:LookupBone(bName))
        
            ---@type PhysObj
            local pObj = pObjs[bName].pObj
            if not IsValid(pObj) then continue end
        
            --print(1)
        
            local forceMul = data.forceMul
            --local dampForceMul = data.dampForceMul or 1
            --local deltaAng = data.deltaAng
        
            --local fm = math.min(0.1, tickInterval * pObj:GetMass())
        
            --pObj:ApplyTorqueCenter(-pObj:GetAngleVelocity() * fm)
            --pObj:ApplyForceCenter(-pObj:GetVelocity() * fm)
            --pObj:SetAngleVelocity(vector_origin)
        
            --forceMul = forceMul * 10
        
            local bI = target:LookupBone(bName)
--    
            if not bI then continue end
            --print(i, bI, bName)
        
            --local mtx = target:GetBoneMatrix(bI)
            --if not mtx then continue end
        
            local pos, ang = target:GetBonePosition(bI) --mtx:GetTranslation(), mtx:GetAngles()
        
            --pos, ang = LocalToWorld(vector_origin, deltaAng, pos, ang)
            --pos, ang = LocalToWorld(pos, ang, own:EyePos(), own:EyeAngles())
        
            --local mass = pObj:GetMass()
            --pObj:Wake()
            --pObj:EnableMotion(true)
            --pObj:EnableCollisions(false)
            --local equal = ang:IsEqualTol(pObj:GetAngles(), 125)

            if lArmDeltaBones[bName] then
                forceMul = forceMul * Lerp((oldLArm - 0.2), 1, isPly and 10 or 100)
            elseif rArmDeltaBones[bName] then
                forceMul = forceMul * Lerp((oldRArm - 0.2) / 0.8, 1, isPly and 10 or 100)
            end
            
            --[[local htAng = aimPosDelta[wepHT][bName]
            --print(bName, htAng)
            if htAng then
                _, htAng = LocalToWorld(vector_origin, htAng, vector_origin, aea)
            end]]
            shadowCtrls[bName] = {
                --secondstoarrive = 0.05,
                pos = pos,
                angle = ang,
                maxspeed = 0,
                maxspeeddamp = 0,
                maxangular = (not nonFirearm and 10 or torsoang) * forceMul,
                maxangulardamp = (not nonFirearm and 10 or torsoangdamp) * forceMul,
                dampfactor = 0.8,
                delta = 0.1,
                noCorrection = true,
            }
            --print(pos)
            --pObj:SetDamping(10000000, 1000000)
            --if not nonFirearm or (not lArmDeltaBones[bName] and not rArmDeltaBones[bName]) then continue end
        
            --local pobjDir = pObj:GetAngles():Forward()
            --local dot = pobjDir:Dot(ang:Forward())
            --print(bName, dot)
            --[[if lArmDeltaBones[bName] then
                lArmDeltaMax = math.min(lArmDeltaMax, dot)
            else
                rArmDeltaMax = math.min(rArmDeltaMax, dot)
            end]]
            --print(d)
        
        
        end

        
        --[[local animLHandPos, animLHandAng = fakePly:GetBonePosition(fakePly:LookupBone("ValveBiped.Bip01_L_Hand"))
        local animRHandPos, animRHandAng = fakePly:GetBonePosition(fakePly:LookupBone("ValveBiped.Bip01_R_Hand"))

        local lhToLocalPos, lhToLocalAng = WorldToLocal(animLHandPos, animLHandAng, animRHandPos, animRHandAng)
        lhToLocalPos, lhToLocalAng = LocalToWorld(lhToLocalPos, lhToLocalAng, rhandpos, rhandang)
        --rhToLocalPos = rhToLocalPos + aea:Up() * 5

        shadowCtrls["ValveBiped.Bip01_L_Hand"] = {
            --secondstoarrive = 0.05,
            pos = lhToLocalPos,
            angle = lhToLocalAng,
            maxspeed = 150,
            maxspeeddamp = 80,
            maxangular = 700,
            maxangulardamp = 500,
            dampfactor = 0.8,
            delta = 0.05,
        }]]

        -- Sonic.EXE The Distaster 2D Remake.jpg
        -- I mean, 这不灾难吗?
        -- ToDo: 整理这里
        if not nonFirearm then

            local ragHeadPos, ragHeadAng = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_Head1")
            local ragLUArmPos, ragLUArmAng = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_L_UpperArm")
            local ragRUArmPos, ragRUArmAng = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_R_UpperArm")
            local animHeadPos, animHeadAng = fakePly:GetBonePosition(fakePly:LookupBone("ValveBiped.Bip01_Head1"))
            local animLHandPos, animLHandAng = fakePly:GetBonePosition(fakePly:LookupBone("ValveBiped.Bip01_L_Hand"))
            local animRHandPos, animRHandAng = fakePly:GetBonePosition(fakePly:LookupBone("ValveBiped.Bip01_R_Hand"))

            local _, faceAng = LocalToWorld(vector_origin, Angle(-90, 0, 90), vector_origin, aea)
            local lhToLocalPos, lhToLocalAng = WorldToLocal(animLHandPos, animLHandAng, animRHandPos, animRHandAng)
            local rhToLocalPos, rhToLocalAng = WorldToLocal(animRHandPos, animRHandAng, animHeadPos, faceAng)
            _, faceAng = LocalToWorld(vector_origin, Angle(-90, 0, 90), vector_origin, aea)
            --lhToLocalPos, lhToLocalAng = LocalToWorld(lhToLocalPos, lhToLocalAng, rhandpos, rhandang)
            -- 需要检测区分下文
            rhToLocalPos, rhToLocalAng = LocalToWorld(rhToLocalPos, rhToLocalAng, ragHeadPos, faceAng)

            -- ToDo: 没用了就杀了
            --[[if isMeleeHT then
                rhToLocalPos = rhToLocalPos
            else]]
            local nearwalling = self:GetCachedVar("NearWalling")
            if not isMeleeHT then
                -- 歪打正着
                local wepDelta = (aimPosDelta[wepHT] or twoArmAimDelta) * mdlScale
                rhToLocalPos = eyepos + aea:Forward() * wepDelta.x * (1 - nearwalling) * (isPly and 1 or deltaedHT[wepHT] and 1.2 or 1.5) + aea:Right() * wepDelta.y * (isPly and 1 or wepDelta == twoArmAimDelta and 2 or 1) + aea:Up() * wepDelta.z * (isPly and 1 or 1)
                --rhToLocalPos = eyepos + aea:Forward() * wepDelta.x + aea:Right() * wepDelta.y + aea:Up() * wepDelta.z
            end
            --rhToLocalPos = rhToLocalPos + aea:Up() * 5
            local _, rHandFaceAng = LocalToWorld(vector_origin, Angle(5, 0, 180),vector_origin, aea)
            
            rHandFaceAng = LerpAngle(0.6, rhToLocalAng, rHandFaceAng)
            --local _, torsoFaceAng = LocalToWorld(vector_origin, Angle(90, 0, -90), vector_origin, aea)
            lhToLocalPos, lhToLocalAng = LocalToWorld(lhToLocalPos, lhToLocalAng, rhToLocalPos, rHandFaceAng)
            -- 需要检测区分下文

            local torsoAngle = torso:GetAngles()
            _, torsoAngle = LocalToWorld(vector_origin, Angle(0, 90, 90), vector_origin, torsoAngle)
            local exRotate = torsoAngle.r
            
            local var = 50 - 25 * nearwalling

            -- speeddamp是他妈一坨屎, 这就是为什么我们要做100%橙汁(?????)啊不对角度运算
            local angLUpperArm, angLForeArm = calcBasicArmIK(ragLUArmPos, ragLUArmAng, lhToLocalPos, mdlScale, var + exRotate, Angle(0, 0, -90), aea)
            local angRUpperArm, angRForeArm = calcBasicArmIK(ragRUArmPos, ragRUArmAng, rhToLocalPos, mdlScale, -var + exRotate, Angle(0, 0, -90), aea)

            shadowCtrls["ValveBiped.Bip01_L_UpperArm"] = {
                --secondstoarrive = tickInterval / 10,
                angle = angLUpperArm,
                maxangular = armaimang,
                maxangulardamp = armaimangdamp,
                dampfactor = armaimdampfactor,
                delta = armaimdelta,
                addMass = handAimUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_L_Forearm"] = {
                --secondstoarrive = tickInterval / 10,
                angle = angLForeArm,
                maxangular = armaimang,
                maxangulardamp = armaimangdamp,
                dampfactor = armaimdampfactor,
                delta = armaimdelta,
                addMass = handAimUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_R_UpperArm"] = {
                --secondstoarrive = tickInterval / 10,
                angle = angRUpperArm,
                maxangular = armaimang,
                maxangulardamp = armaimangdamp,
                dampfactor = armaimdampfactor,
                delta = armaimdelta,
                addMass = handAimUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_R_Forearm"] = {
                --secondstoarrive = tickInterval / 10,
                angle = angRForeArm,
                maxangular = armaimang,
                maxangulardamp = armaimangdamp,
                dampfactor = armaimdampfactor,
                delta = armaimdelta,
                addMass = handAimUseMass,
            }

            --pObjs["ValveBiped.Bip01_R_UpperArm"].pObj:EnableMotion(!false)

            --print(dist)


            -- 力竭了, 希望你可以从这里理解为什么现实中右手持步枪向右转向瞄准有速度减益了(我记得这是真的)
            _, lhToLocalAng = WorldToLocal(vector_origin, lhToLocalAng, vector_origin, aea)
            shadowCtrls["ValveBiped.Bip01_L_Hand"] = {
                --secondstoarrive = tickInterval / 10,
                angle = lhToLocalAng,
                maxspeed = handaimspd,
                maxspeeddamp = handaimspddamp,
                maxangular = handaimang,
                maxangulardamp = handaimangdamp,
                dampfactor = handaimdampfactor,
                delta = handaimdelta,
                addMass = handAimUseMass,
                noMotion = true
            }
            shadowCtrls["ValveBiped.Bip01_R_Hand"] = {
                --secondstoarrive = tickInterval / 10,
                angle = Angle(5, 0, 180),
                maxspeed = handaimspd,
                maxspeeddamp = handaimspddamp,
                maxangular = handaimang,
                maxangulardamp = handaimangdamp,
                dampfactor = handaimdampfactor,
                delta = handaimdelta,
                addMass = handAimUseMass,
                noMotion = true
                --teleportdistance = 1,
            }

            local pobjDir = pObjs["ValveBiped.Bip01_R_Hand"].pObj:GetAngles():Forward()
            local pobjPos = pObjs["ValveBiped.Bip01_R_Hand"].pObj:GetPos()
            local dot = math.min(1, pobjDir:Dot(rHandFaceAng:Forward()) * (isPly and 1 or 1.1))
            --print(dot)
            rArmDeltaMax = math.min(rArmDeltaMax, dot, 1 - math.max(0, pobjPos:Distance(rhToLocalPos) - (isPly and 5 or 15)) / 5)
            pobjPos = pObjs["ValveBiped.Bip01_L_Hand"].pObj:GetPos()
            lArmDeltaMax = 1 - math.max(0, pobjPos:Distance(lhToLocalPos) - 15) / 5
            
            --print(rArmDeltaMax)

        end
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:SetMass(50)
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:EnableMotion(!false)

        --local _, rHandFaceAng = LocalToWorld(vector_origin, Angle(20, 0, -180), vector_origin, aea)
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:SetAngles(rHandFaceAng)


        --[[pObjs["ValveBiped.Bip01_R_Hand"].pObj:EnableMotion(false)
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:Wake()
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:Sleep()
        pObjs["ValveBiped.Bip01_R_Hand"].pObj:SetAngles(rHandFaceAng)
        pObjs["ValveBiped.Bip01_R_Hand"].pObj:EnableMotion(true)]]

        --rag:SetRagdollAng(rag:LookupBone("ValveBiped.Bip01_R_Hand"), rHandFaceAng)
        --rag:RagdollUpdatePhysics()
        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:EnableMotion(false)

        lArmDeltaMax = Lerp(lArmDeltaMax + 0.25, 1, 0)
        rArmDeltaMax = Lerp((rArmDeltaMax + 0.15) ^ 2, 1, 0)
        --print(lArmDeltaMax)
        if self.NextSetRArmDelta <= ct then

            local finalVar = math.Approach(oldRArm, rArmDeltaMax, 0.2)

            --print(0)
            self.CanSetRArmDelta = nonFirearm or finalVar ~= 0
            if oldRArm == 0 and self.CanSetRArmDelta then
                self.NextSetRArmDelta = ct + 0
                --print(1)
            else
                self:SetRArmDelta(finalVar)
            end

        end

        if not in_forward and self.NextSetLArmDelta <= ct then

            local finalVar = math.Approach(oldLArm, lArmDeltaMax, 0.2)

            --print(finalVar)
            self.CanSetLArmDelta = nonFirearm or finalVar <= 0
            if oldLArm == 0 and self.CanSetLArmDelta then
                self.NextSetLArmDelta = ct + 0.05
                --print(1)
            else
                self:SetLArmDelta(finalVar)
            end

        end

        local const = self.LHand_Grabbing
        if in_forward then
            self:SetLArmDelta(math.Approach(self:GetLArmDelta(), 1, 0.25))

            --print(grabtr.Entity, grabtr.HitWorld)
            --self.DebugMdl:SetPos(handpos + handang:Forward() * 7 + handang:Right() * 7)

            local dir = not isPly and (caches.NPC_MoveGoal - eyepos):GetNormalized() or aea:Forward()
            local ang = Angle(0, 0, 90)
            shadowCtrls["ValveBiped.Bip01_L_Hand"] = {
                --secondstoarrive = 0.01,
                pos = eyepos + (dir * 30 - eyeang:Up() * (isPly and 3 or 10 + caches.NPC_MoveGoal:Distance(eyepos) / 10)) * mdlScale,
                angle = ang,
                maxspeed = handspd,
                maxspeeddamp = handspddamp,
                maxangular = handang,
                maxangulardamp = handangdamp,
                dampfactor = handdampfactor,
                delta = handdelta,
                addMass = handUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_L_UpperArm"] = nil
            shadowCtrls["ValveBiped.Bip01_L_Forearm"] = nil

            -- 神秘ShadowCTRL实现方式, 总结: 史
            --[[local _, ang = LocalToWorld(vector_origin, Angle(0, -15, 0), vector_origin, aea)
            shadowCtrls["ValveBiped.Bip01_L_UpperArm"] = {
                angle = ang,
                maxangular = handaimang,
                maxangulardamp = handaimangdamp,
                maxspeed = 0,
                maxspeeddamp = 0,
                dampfactor = handaimdampfactor,
                delta = handaimdelta,
                addMass = handAimUseMass,
            }
            _, ang = LocalToWorld(vector_origin, Angle(0, -15, 0), vector_origin, aea)
            shadowCtrls["ValveBiped.Bip01_L_Forearm"] = {
                angle = ang,
                maxangular = handaimang,
                maxangulardamp = handaimangdamp,
                maxspeed = 0,
                maxspeeddamp = 0,
                dampfactor = handaimdampfactor,
                delta = handaimdelta,
                addMass = handAimUseMass,
            }]]
            --pObjs["ValveBiped.Bip01_L_UpperArm"].pObj:EnableMotion(!false)
            --pObjs["ValveBiped.Bip01_L_Forearm"].pObj:EnableMotion(!false)

        elseif not IsValid(const) then
            self:SetLArmDelta(math.Approach(self:GetLArmDelta(), lArmDeltaMax, 0.25))
        end
        --[[local const = self.LHand_Grabbing

        if (in_forward or in_back) and IsValid(const) and self.LHand_GrabbingWorld then

            local tPos = torso:GetPos()
            local dir = not isPly and (caches.NPC_MoveGoal - eyepos):GetNormalized() or aea:Forward()
            --shadowCtrls["ValveBiped.Bip01_L_Hand"] = nil
            --[[shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(0.8, tPos, in_forward and lhandpos or lhandpos - dir * 35 * mdlScale)
            shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeed = torsomovespd
            shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeeddamp = torsomovespddamp
            shadowCtrls["ValveBiped.Bip01_Spine2"].delta = torsomovespddelta
            shadowCtrls["ValveBiped.Bip01_Spine2"].addMass = torsoMoveUseMass]]
            --local _, ang = LocalToWorld(vector_origin, Angle(0, 90, 0), vector_origin, aea)
            --[[shadowCtrls["ValveBiped.Bip01_L_UpperArm"] = nil and {
                angle = ang,
                maxangular = handaimang * 1000,
                maxangulardamp = handaimangdamp,
                maxspeed = 0,
                maxspeeddamp = 0,
                dampfactor = handaimdampfactor,
                delta = handaimdelta * 0.1,
                addMass = handAimUseMass,
            }
            pObjs["ValveBiped.Bip01_L_UpperArm"].pObj:SetAngles(ang)
            _, ang = LocalToWorld(vector_origin, Angle(0, 90, 0), vector_origin, aea)
            shadowCtrls["ValveBiped.Bip01_L_Forearm"] = nil and{
                angle = ang,
                maxangular = handaimang * 1000,
                maxangulardamp = handaimangdamp,
                maxspeed = 0,
                maxspeeddamp = 0,
                dampfactor = handaimdampfactor,
                delta = handaimdelta * 0.1,
                addMass = handAimUseMass,
            }]

            --pObjs["ValveBiped.Bip01_L_Forearm"].pObj:SetAngles(ang)

            --print("11111")

        end]]

    else
        self:SetLArmDelta(1)
        self:SetRArmDelta(1)

        local lhand = noArm and self:HasKeyInput(IN_ATTACK) or in_forward
        local rhand = self:HasKeyInput(IN_ATTACK2) or (not isPly and in_forward)

        local forward, right = aea:Forward() * 30 * mdlScale, aea:Right() * 5 * mdlScale
        local pos = eyepos + forward

        if not isPly then
            pos = pos - Vector(0, 0, 50)
        end
        if lhand then
            self:SetLArmDelta(math.Approach(self:GetLArmDelta(), 1, 0.2))
            local ang = Angle(0, 0, 90)
            shadowCtrls["ValveBiped.Bip01_L_Hand"] = {
                --secondstoarrive = 0.01,
                pos = pos - right,
                angle = ang,
                maxspeed = handspd,
                maxspeeddamp = handspddamp,
                maxangular = handang,
                maxangulardamp = handangdamp,
                dampfactor = handdampfactor,
                delta = handdelta,
                addMass = handUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_L_UpperArm"] = nil
            shadowCtrls["ValveBiped.Bip01_L_Forearm"] = nil
        end
        if rhand then
            local ang = Angle(20, 20, (noArm or isMeleeHT) and 90 or 180)
            shadowCtrls["ValveBiped.Bip01_R_Hand"] = {
                --secondstoarrive = 0.01,
                pos = pos + right,
                angle = ang,
                maxspeed = handspd,
                maxspeeddamp = handspddamp,
                maxangular = handang,
                maxangulardamp = handangdamp,
                dampfactor = handdampfactor,
                delta = handdelta,
                addMass = handUseMass,
            }
            shadowCtrls["ValveBiped.Bip01_R_UpperArm"] = nil
            shadowCtrls["ValveBiped.Bip01_R_Forearm"] = nil
        end

        if aimingWeapon or rhand or lhand then
            
            local angFace = Angle(-90, -90, 180)
            local angFaceTorso = Angle(-90, -90, 0)
            
            --pObjs["ValveBiped.Bip01_R_Hand"].pObj:EnableMotion(false)
            --pObjs["ValveBiped.Bip01_Head1"].pObj:EnableMotion(false)
            shadowCtrls["ValveBiped.Bip01_Head1"] = {
                --secondstoarrive = 0.15,
                
                angle = angFace,
                maxspeed = headspd,
                maxspeeddamp = headspddamp,
                maxangular = headang,
                maxangulardamp = headangdamp,
                dampfactor = headdampfactor,
                delta = headdelta,
                addMass = headUseMass,
            }
            local mul = aimingWeapon and 1 or 0.01
            shadowCtrls["ValveBiped.Bip01_Spine2"] = {
                --secondstoarrive = 0.15,
                
                angle = angFaceTorso,
                maxspeed = torsospd * mul,
                maxspeeddamp = torsospddamp * mul,
                maxangular = torsoang * mul,
                maxangulardamp = torsoangdamp * mul,
                dampfactor = torsodampfactor,
                delta = torsodelta,
                addMass = torsoUseMass,
            }
        end

        --[[local const = self.LHand_Grabbing
        local constR = self.RHand_Grabbing

        if not shadowCtrls["ValveBiped.Bip01_Spine2"] then
            shadowCtrls["ValveBiped.Bip01_Spine2"] = {
                maxspeeddamp = 0,
                dampfactor = 0.8,
                addMass = torsoUseMass,
            }
        end
        if in_forward then
            if IsValid(const) and self.LHand_GrabbingWorld then
                shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(aimingWeapon and 0.7 or 0.5, torso:GetPos(), lhandpos)
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeed = torsomovespd
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeeddamp = torsomovespddamp
                shadowCtrls["ValveBiped.Bip01_Spine2"].delta = torsomovespddelta
                shadowCtrls["ValveBiped.Bip01_Spine2"].addMass = torsoMoveUseMass
            elseif IsValid(constR) and self.RHand_GrabbingWorld then
                shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(aimingWeapon and 0.7 or 0.5, torso:GetPos(), rhandpos)
                --print(1)
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeed = torsomovespd
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeeddamp = torsomovespddamp
                shadowCtrls["ValveBiped.Bip01_Spine2"].delta = torsomovespddelta
                shadowCtrls["ValveBiped.Bip01_Spine2"].addMass = torsoMoveUseMass
            end
        elseif in_back then
            local dir = not isPly and (caches.NPC_MoveGoal - eyepos):GetNormalized() or aea:Forward() --(tPos - lhandpos):GetNormalized()
            if IsValid(const) and self.LHand_GrabbingWorld then
                local tPos = torso:GetPos()
                shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(aimingWeapon and 0.7 or 0.5, tPos, lhandpos - dir * 30 * mdlScale)
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeed = torsomovespd
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeeddamp = torsomovespddamp
                shadowCtrls["ValveBiped.Bip01_Spine2"].delta = torsomovespddelta
                shadowCtrls["ValveBiped.Bip01_Spine2"].addMass = torsoMoveUseMass
            elseif IsValid(constR) and self.RHand_GrabbingWorld then
                local tPos = torso:GetPos()
                shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(aimingWeapon and 0.7 or 0.5, tPos, lhandpos - dir * 30 * mdlScale)
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeed = torsomovespd
                shadowCtrls["ValveBiped.Bip01_Spine2"].maxspeeddamp = torsomovespddamp
                shadowCtrls["ValveBiped.Bip01_Spine2"].delta = torsomovespddelta
                shadowCtrls["ValveBiped.Bip01_Spine2"].addMass = torsoMoveUseMass
            end
        end]]
        
    end


    if not self.GettingUp and shadowCtrls["ValveBiped.Bip01_Spine2"] and shadowCtrls["ValveBiped.Bip01_Spine2"].angle then
        
        local ang = shadowCtrls["ValveBiped.Bip01_Spine2"].angle
        if in_duck then
            ang:RotateAroundAxis(Vector(0, -1, 0), 25)
        elseif self.LowPose then --IsValid(wep) and wep.ARC9 and wep:GetBipod() then
            ang:RotateAroundAxis(Vector(0, -1, 0), -30)
        end
        --ang:RotateAroundAxis(aea:Right(), -25)
    end

    self.ShadowCtrlData = shadowCtrls

end


-- 2026/7/5 这里被改为只处理真正和Tick有关的东西以试图优化
function ENT:Tick()

    if CLIENT then return end

    self.VarCaches = {}

    local ct = CurTime()

    local fakePly = self.FakePlyModel
    if not IsValid(fakePly) then return end

    ---@type Entity
    local own = self:GetOwner()
    ---@type Entity
    local rag = self:GetRagdoll()
    local mdlScale = rag.Savee_AdvRagKnockdown_ModelScale

    if self.Initialized and own:GetMoveParent() ~= rag then
        self:RemoveSelf()
        return
    elseif not own:IsEffectActive(EF_BONEMERGE) then
        own:AddEffects(EF_BONEMERGE)
    end

    local shadowCtrls = table.Copy(self.ShadowCtrlData)
    local pObjs = self.RagPObjs

    local stamina, consc = self:GetStamina(), self:GetConsciousness()
    local staminaLerp, conscLerp = math.ease.InOutQuad(stamina / 100), math.ease.OutQuint(consc / 100)


    local wep = own:GetActiveWeapon()
    local noArm = true --noAimHTs[wepHT]
    local isMeleeHT
    local wepHT
    local isPly = own:IsPlayer()


    local aimingWeapon = consc >= 35 and (not isPly and own:GetActivity() ~= ACT_IDLE or self:GetAimingWeapon())
    local caches = self.Caches

    if IsValid(wep) then
        wepHT = wep:GetHoldType()
        noArm, isMeleeHT = noAimHTs[wepHT] or (meleeHTs[wepHT] and not aimingWeapon), meleeHTs[wepHT]
        --print(noArm, wepHT)
    elseif not isPly and not own:CapabilitiesHas(CAP_USE_WEAPONS) then
        --print(1) 
        wepHT = "fist"
        local en = own:GetEnemy()
        noArm = not IsValid(en)
    end

    if consc < noArmVal then noArm = true end

    local aea = self:GetAimEyeAngles()

    local eyeatt = rag:LookupAttachment("eyes")
    local eyepos = own:EyePos()
    local eyeang = own:EyeAngles()
    if eyeatt ~= 0 then
        eyepos = rag:GetAttachment(eyeatt).Pos
        eyeang = rag:GetAttachment(eyeatt).Ang        
    end

    if not isPly then
        --eyepos = eyepos - own:GetInternalVariable("m_HackedGunPos") or vector_origin
        own:SetPos(rag:GetPos(), true)
    else
        own:SetPos(eyepos + (aea:Forward() * 7) * math.max(1, mdlScale), true)
    end

    local in_forward = not isPly and caches.NPC_HasMoveGoal or self:HasKeyInput(IN_FORWARD)
    local in_back = self:HasKeyInput(IN_BACK)

    local numpObjs = rag:GetPhysicsObjectCount()
    -- Breen.mdl
    local extrapObjs = numpObjs - 15

    -- 起身
    if self.GettingUp then

        local lfoot, rfoot = pObjs["ValveBiped.Bip01_L_Foot"] and pObjs["ValveBiped.Bip01_L_Foot"].pObj, pObjs["ValveBiped.Bip01_R_Foot"] and pObjs["ValveBiped.Bip01_R_Foot"].pObj

        local lFootOnGround = lfoot and util.TraceLine({start = lfoot:GetPos(), endpos = lfoot:GetPos() - Vector(0, 0, 10), filter = {own, rag}})
        lFootOnGround = lFootOnGround.Hit or lFootOnGround.HitWorld
        local rFootOnGround = rfoot and util.TraceLine({start = rfoot:GetPos(), endpos = rfoot:GetPos() - Vector(0, 0, 10), filter = {own, rag}})
        rFootOnGround = rFootOnGround.Hit or rFootOnGround.HitWorld

        --print(lFootOnGround)

        local getupForceMul = 1
        if lFootOnGround then getupForceMul = getupForceMul + 0.65 end
        if rFootOnGround then getupForceMul = getupForceMul + 0.65 end

        local target = self.GettingUp_SyncingToOwner and self or self.GetupAnimModel
        --print(target)
        for i = 0, target:GetBoneCount() - 1 do
            local bName = target:GetBoneName(i)
            if shadowCtrls[bName] or not pObjs[bName] or not pObjs[bName].physBone or not boneWhiteList[bName] then continue end

            local pObj = pObjs[bName].pObj
            local pos, ang = target:GetBonePosition(i)
            --local mass = pObj:GetMass()
            --print(bName, mass)

            --pObj:EnableMotion(false)

            shadowCtrls[bName] = {
                --secondstoarrive = 0.01,
                pos = pos,
                angle = ang,
                maxspeed = 350 * getupForceMul,
                maxspeeddamp = 350 * getupForceMul,
                maxangular = 250,
                maxangulardamp = 350,
                dampfactor = Lerp((self.GetupAnimModel:GetCycle() - 0.3) / 0.7, 0.2, 0.5),
                delta = 0.2,
                DontFuckMe = true,
                --addMass = getupUseMass,
            }

        end

    end

    -- 主体控制
    -- 因为太几把占性能了所以挪走了
    -- 貌似能在踹翻30个联合军的情况下省下~30fps
    if self.NextCalcAnim <= ct then
        
        self:DealWithAnims(isPly, aimingWeapon, noArm, wepHT, isMeleeHT)

        self.NextCalcAnim = ct + (isPly and 0.1 or 0.2)
    end


    -- 操作
    if self:HasKeyInput(IN_MOVELEFT) then
        --pelvis:ApplyTorqueCenter(pelvis:GetAngles():Right() * -200)
        self:SetAimEyeAngles(aea - Angle(0, 0, 1.5) * conscLerp)
    elseif self:HasKeyInput(IN_MOVERIGHT) then
        --pelvis:ApplyTorqueCenter(pelvis:GetAngles():Right() * 200)
        self:SetAimEyeAngles(aea + Angle(0, 0, 1.5) * conscLerp)
    end

    --aea.r = pelvis:GetAngles().z
    --self:SetAimEyeAngles(aea)

    --self:DoGrabDetection(shadowCtrls)

    -- 抓握
    local torso = pObjs["ValveBiped.Bip01_Spine2"].pObj

    local lhandpos, lhandang = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_L_Hand")
    local rhandpos, rhandang = getPhysBonePosAng(pObjs, "ValveBiped.Bip01_R_Hand")

    local grabtr = util.TraceLine({
        start = lhandpos,
        endpos = lhandpos + lhandang:Forward() * 3 + lhandang:Right() * 5,
        filter = {own, rag},
        mins = Vector(-5, -5, -5),
        maxs = Vector(5, 5, 5),
    })


    local ent = grabtr.HitWorld and Entity(0) or grabtr.Entity
    local const = self.LHand_Grabbing
    local constR = self.RHand_Grabbing

    local crawlCond = not isPly and (ct - caches.NPC_LastGoalUpdate) <= 1
    local grabCond = not self.GettingUp and math.random(1, 45) <= stamina
    if not grabCond then
        if IsValid(const) then self.LHand_NextGrab = ct + 1 end
        if IsValid(constR) then self.RHand_NextGrab = ct + 1 end
    end

    if not IsValid(const) and self.LHand_Grabbing_Broken then
        self.LHand_NextGrab = ct + 1
        self.LHand_Grabbing_Broken = false
    end
    if not IsValid(constR) and self.RHand_Grabbing_Broken then
        self.RHand_NextGrab = ct + 1
        self.RHand_Grabbing_Broken = false
    end
    local doLHand = grabCond and ((isPly and self:HasKeyInput(IN_SPEED) or (crawlCond and not self:GetCachedVar("NPC_ShouldRHand")))) and self.LHand_NextGrab <= ct
    --print(math.IsNearlyEqual(caches.NPC_LastGoalUpdate, ct + 0.6, 0.5), caches.NPC_LastGoalUpdate, ct + 0.6)
    --print(doLHand)

    --print(ent, IsValid(ent), grabtr.HitWorld)
    if (IsValid(ent) or ent:IsWorld()) and doLHand and not IsValid(const) then

        --pObjs["ValveBiped.Bip01_L_Hand"].pObj:SetPos(grabtr.HitPos + grabtr.HitNormal * 5)
        --print("Create", ent)
        local pObjID = grabtr.HitBoxBone and ent:TranslateBoneToPhysBone(grabtr.HitBoxBone) or 0
        local pObj = ent:GetPhysicsObjectNum(pObjID)

        if not pObj then 
            pObj = ent:GetPhysicsObject()
            pObjID = 0
        end

        self.LHand_Grabbing = constraint.Weld(rag, ent, pObjs["ValveBiped.Bip01_L_Hand"].id, pObjID, 10000, false, false)
        self.LHand_Grabbing_Broken = true
        --if not self.LHand_Grabbing then print("SMJB") end
        --self.LHand_Grabbing:SetKeyValue("forcelimit", 1)
        -- 我没有物理思维, 所以让引擎做这玩意, which 协助定位这个傻逼Prop
        -- 绳子可以拿去搞捆绑.jpg

        local wtl = WorldToLocal(grabtr.HitPos, angle_zero, pObj:GetPos(), pObj:GetAngles())

        -- 弹性绳索, 很适合模拟一个人是怎么抓东西的, 比绳子好114倍, 比绞盘好514倍
        --self.LHand_Grabbing_Winch = constraint.Elastic(rag, ent, pObjs["ValveBiped.Bip01_Spine2"].id, pObjID, Vector(4, 2, 2) * mdlScale, wtl, 20000, 50, 0.2, "", 3, false, Color(255, 255, 255))
        self.LHand_GrabbingWorld = checkCanPull(ent)

        self.LHand_GrabbingData = {
            ent = ent, 
            wtlPos = wtl,
            pObjID = pObjID,
        }

        --[[if IsValid(self.LHand_Grabbing_Winch) and IsValid(self.LHand_Grabbing) then
            self.LHand_Grabbing_Winch:DeleteOnRemove(self.LHand_Grabbing)
            self.LHand_Grabbing:DeleteOnRemove(self.LHand_Grabbing_Winch)
        end]]
        --self.LHand_Grabbing_Winch:SetSaveValue("m_start", Vector())
        --print(self.LHand_Grabbing_Winch:GetInternalVariable("m_start"))
        --print(self.LHand_Grabbing_Winch:SetSaveValue("m_totalLength", 0.))

    elseif IsValid(const) and not doLHand then

        --print(grabCond, self:HasKeyInput(IN_SPEED), own:KeyDown(IN_SPEED))
        const:Remove()
        self.LHand_Grabbing_Broken = false
        --if IsValid(self.LHand_Grabbing_Winch) then self.LHand_Grabbing_Winch:Remove() end
        self.LHand_GrabbingWorld = false
        self.LHand_GrabbingData = {}
        --caches.LastCrawl = ct

    end

    --print(self.LHand_Grabbing_Winch:GetInternalVariable("m_start"))


    local grabtrR = util.TraceLine({
        start = rhandpos,
        endpos = rhandpos + rhandang:Forward() * 3 + rhandang:Right() * 5,
        filter = {own, rag},
        mins = Vector(-5, -5, -5),
        maxs = Vector(5, 5, 5),
    })
    --self.DebugMdl:SetPos(grabtr.HitPos)
    local entR = grabtrR.HitWorld and Entity(0) or grabtrR.Entity

    local doRHand = grabCond and ((isPly and self:HasKeyInput(IN_WALK)) or (crawlCond and self:GetCachedVar("NPC_ShouldRHand"))) and self.RHand_NextGrab <= ct

    --print(ent, IsValid(ent), grabtr.HitWorld)
    if (IsValid(entR) or entR:IsWorld()) and doRHand and not IsValid(constR) and noArm then

        --pObjs["ValveBiped.Bip01_R_Hand"].pObj:SetPos(grabtrR.HitPos + grabtrR.HitNormal * 5)
        --print("Create", ent)
        local pObjID = grabtrR.HitBoxBone and entR:TranslateBoneToPhysBone(grabtrR.HitBoxBone) or 0
        local pObj = entR:GetPhysicsObjectNum(pObjID)
        if not pObj then 
            pObj = entR:GetPhysicsObject()
            pObjID = 0
        end

        self.RHand_Grabbing = constraint.Weld(rag, entR, pObjs["ValveBiped.Bip01_R_Hand"].id, pObjID, 10000, false, false)
        self.RHand_Grabbing_Broken = true
        --print(self.RHand_Grabbing)
        self.RHand_GrabbingWorld = checkCanPull(entR)

        local wtl = WorldToLocal(grabtrR.HitPos, angle_zero, pObj:GetPos(), pObj:GetAngles())

        self.RHand_GrabbingData = {
            ent = entR, 
            wtlPos = wtl,
            pObjID = pObjID,
        }

    elseif IsValid(constR) and (not doRHand or not noArm) then

        --print("Remove")
        constR:Remove()
        self.RHand_Grabbing_Broken = false
        self.RHand_GrabbingWorld = false
        self.RHand_GrabbingData = {}

    end

    local lWinch = self.LHand_Grabbing_Winch
    local rWinch = self.RHand_Grabbing_Winch

    -- Alr Listen
    -- 当我进游戏再次观察ZCity的布娃娃系统的时候我震惊了
    -- 我相信里面一定有神秘地精魔法让它效果这么好(Edit: 该死的反作用力)
    -- 但是很显然我贫瘠的大脑做不到独立思考出这玩意的运作方式, 只能自己想一个(Edit: 实际上是我考虑过的反作用力(实际上这是本质), 但没想到能逆天到直接ApplyForce)
    -- 向你介绍: 基于原版约束的抓握, 因为原版约束在物理的兼容性比该死的ShadowCTRL做的好114514倍

    if IsValid(const) then
        if in_forward then
           if not self.LHand_Grabbing_Winch_Forward and IsValid(lWinch) then
               lWinch:Remove()
           end

           local spd = self.LHand_GrabbingWorld and 4500 or 2000

           if not IsValid(lWinch) then
                local data = self.LHand_GrabbingData
                -- Z-City的参数(给我的感觉), 和我进去爬的时候的手部位置几乎一致
                lWinch = constraint.Elastic(rag, data.ent, pObjs["ValveBiped.Bip01_Spine2"].id, data.pObjID, (Vector(-6, 6, 1) - aea:Forward()), data.wtlPos, spd, 250, 1, "", 0, true, Color(255, 255, 255, 0))
                if lWinch then 
                    const:DeleteOnRemove(lWinch)
                end

                self.LHand_Grabbing_Winch = lWinch
           end

           if not lWinch then return end
           
           lWinch:Fire("SetSpringLength", 1)
           lWinch:Fire("SetSpringConstant", spd * staminaLerp)
           self.LHand_Grabbing_Winch_Forward = true
        elseif in_back then
            -- 这是他妈的一坨屎, 但是只能这么做(因为反作用力被占了况且这玩意已经半成形了(而且更稳定))
            -- 我觉得每Tick都移除再创造对性能影响太大了, 但是这玩意不能被Licensed.jpg
            if IsValid(lWinch) then
               lWinch:Remove()
            end

            local tPos = torso:GetPos()
            local dir = not isPly and (caches.NPC_MoveGoal - eyepos):GetNormalized() or aea:Forward()
            --shadowCtrls["ValveBiped.Bip01_L_Hand"] = nil
            --[[shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(0.8, tPos, in_forward and lhandpos or lhandpos - dir * 35 * mdlScale)]]

            local pos = LerpVector(0.8, tPos, in_forward and lhandpos or lhandpos + dir * 35 * mdlScale)
            pos = WorldToLocal(pos, angle_zero, torso:GetPos(), torso:GetAngles())
            
            local data = self.LHand_GrabbingData
            lWinch = constraint.Elastic(rag, data.ent, pObjs["ValveBiped.Bip01_Spine2"].id, data.pObjID, pos, data.wtlPos, (self.LHand_GrabbingWorld and 2000 or 1500) * staminaLerp, 250, 0.2, "", 0, true, Color(255, 255, 255, 0))
            if lWinch then const:DeleteOnRemove(lWinch) end

            self.LHand_Grabbing_Winch = lWinch

            if not lWinch then return end

            lWinch:Fire("SetSpringLength", 0.1)
            self.LHand_Grabbing_Winch_Forward = false
        elseif IsValid(lWinch) then 
            lWinch:Remove()
        end
    end
    if IsValid(constR) then
        if in_forward then
           if not self.RHand_Grabbing_Winch_Forward and IsValid(rWinch) then
               rWinch:Remove()
           end

           local spd = self.RHand_GrabbingWorld and 4500 or 2000

           if not IsValid(rWinch) then
               local data = self.RHand_GrabbingData
               -- Z-City的参数(给我的感觉), 和我进去爬的时候的手部位置几乎一致
               rWinch = constraint.Elastic(rag, data.ent, pObjs["ValveBiped.Bip01_Spine2"].id, data.pObjID, (Vector(-6, 6, -1) - aea:Forward()), data.wtlPos, spd, 250, 1, "", 0, true, Color(255, 255, 255, 0))
               if rWinch then constR:DeleteOnRemove(rWinch) end

               self.RHand_Grabbing_Winch = rWinch
           end

           if not rWinch then return end
           
           rWinch:Fire("SetSpringLength", 1)
           rWinch:Fire("SetSpringConstant", spd * staminaLerp)
           self.RHand_Grabbing_Winch_Forward = true
        elseif in_back then
            -- 这是他妈的一坨屎, 但是只能这么做(因为反作用力被占了)
            -- 我觉得每Tick都移除再创造对性能影响太大了, 但是这玩意不能被Licensed.jpg
            if IsValid(rWinch) then
               rWinch:Remove()
            end

            local tPos = torso:GetPos()
            local dir = not isPly and (caches.NPC_MoveGoal - eyepos):GetNormalized() or aea:Forward()
            --shadowCtrls["ValveBiped.Bip01_L_Hand"] = nil
            --[[shadowCtrls["ValveBiped.Bip01_Spine2"].pos = LerpVector(0.8, tPos, in_forward and lhandpos or lhandpos - dir * 35 * mdlScale)]]

            local pos = LerpVector(0.8, tPos, in_forward and rhandpos or rhandpos + dir * 35 * mdlScale)
            pos = WorldToLocal(pos, angle_zero, torso:GetPos(), torso:GetAngles())
            
            local data = self.RHand_GrabbingData
            rWinch = constraint.Elastic(rag, data.ent, pObjs["ValveBiped.Bip01_Spine2"].id, data.pObjID, pos, data.wtlPos, (self.RHand_GrabbingWorld and 2000 or 1500) * staminaLerp, 250, 0.2, "", 0, true, Color(255, 255, 255, 0))
            if rWinch then constR:DeleteOnRemove(rWinch) end

            self.RHand_Grabbing_Winch = rWinch

            if not rWinch then return end

            rWinch:Fire("SetSpringLength", 0.1)
            self.RHand_Grabbing_Winch_Forward = false
        elseif IsValid(rWinch) then 
            rWinch:Remove()
        end
    end


    -- 应用最后的结果, 用Table方便改, 真的是太棒了

    --self:SetStamina(0)

    local forceMul = (1 + math.max(extrapObjs / 5, 0)) * math.min(1.5, self:GetStamina() / 60)

    --print(forceMul)
    local p, y, r = aea:Right(), aea:Forward(), aea:Up()
    for bName, data in pairs(shadowCtrls) do
        if not pObjs[bName] then continue end
        --print(bName, data.angle)
        if not data.noCorrection and data.angle then
           _,  data.angle = LocalToWorld(vector_origin, data.angle, vector_origin, aea)
        end

        local pObj = pObjs[bName].pObj
        data.secondstoarrive = tickInterval
        local mass = pObj:GetMass()
        --print(mass, bName)

        for _, k in ipairs(shadowDatas) do
            data[k] = (data[k] or 0) * forceMul * Lerp(self.OnGroundState, 0.2, 1) * self.OnGroundState * (data.addMass and mass or 1)
        end
        for _, k in ipairs(shadowDampDatas) do
            data[k] = (data[k] or 0) * forceMul * self.OnGroundState * (data.addMass and mass or 1)
        end
        pObj:Wake()
        pObj:ComputeShadowControl(data)
        --pObj:Sleep()
    end

end

if SERVER then return end

local noDrawBones = {
    "ValveBiped.Bip01_Head1",
    "ValveBiped.Bip01_L_UpperArm",
    "ValveBiped.Bip01_R_UpperArm",
}

-- 这玩意就在客户端(也就是你)有
local shouldDrawVM

local huge = math.huge
function ENT:Draw(fl)

end


local mtx = Matrix()
function ENT:CustomRagRenderOverride(fl)
    --do return end
    --if not shouldDrawVM then return end

    local ctrl = Savee_AdvRagKnockdown_GetController(self)
    if not IsValid(ctrl) then return end
    local own = ctrl:GetOwner()
    local ve = LocalPlayer():GetViewEntity()
    if ve ~= own or not IsValid(own) or (self.Initialized and own:GetMoveParent() ~= self) then return end

    own:SetupBones()

    if own:IsPlayer() then
        hook.Run("PrePlayerDraw", own, fl)
    end
    
    local ragNoDrawBones = self.Savee_AdvRagKnockdown_NoDrawBones
    if not ragNoDrawBones then
        self:SetupBones()

        ragNoDrawBones = {}

        local targetBIDs = {}
        for _, bName in ipairs(noDrawBones) do
            targetBIDs[#targetBIDs + 1] = self:LookupBone(bName)
        end

        for i = 0, self:GetBoneCount() - 1 do
            for _, id in ipairs(targetBIDs) do
                if not boneHasParent(self, i, id) then continue end
                ragNoDrawBones[i] = true
            end
        end
        --self.Savee_AdvRagKnockdown_PendingBoneMatrix = {}
        self.Savee_AdvRagKnockdown_NoDrawBones = ragNoDrawBones
        return
    end

    --local stored = {}
    local nb = self:GetBoneCount()

    for i = 0, nb - 1 do
        local bName = self:GetBoneName(i)
        if bName == "__INVALIDBONE__" then continue end
        --stored[i] = self:GetBoneMatrix(i)
        own:CopyBoneMatrix(i, mtx)
        
        if ragNoDrawBones[i] and ve == own and (shouldDrawVM or bName == "ValveBiped.Bip01_Head1") then
            mtx:Scale(Vector(huge, huge, huge))
        end
        self:SetBoneMatrix(i, mtx)
        own:SetBoneMatrix(i, mtx)
    end


    self:DrawModel(fl)
    if own:IsPlayer() then
        hook.Run("PostPlayerDraw", own, fl)
        self:SetupBones()
    end


    --[[for i, mtx in pairs(stored) do
        self:SetBoneMatrix(i, mtx)
    end]]

end


local xyzs = {"x", "y", "z"}

local function clampAng(ang, min, max)

    local newAng = Angle()
    for _, k in pairs(xyzs) do
        newAng[k] = math.Clamp(ang[k], isangle(min) and min[k] or min, isangle(max) and max[k] or max)
    end

    return newAng

end
function ENT:CalcView(ply, pos, ang, fov)

    --do return end
    local own = self:GetOwner()
    if LocalPlayer():GetViewEntity() ~= own then shouldDrawVM = false return end

    --[[if not IsValid(self.CSEnt) then
        self.CSEnt = ClientsideModel("models/hunter/plates/plate.mdl")
    end]]

    --print(ang, ply:EyeAngles())

    local rag = self:GetRagdoll()
    local eyeatt = rag:LookupAttachment("eyes")
    if eyeatt == 0 then return end

    local eyepos = rag:GetAttachment(eyeatt).Pos
    local eyeang = rag:GetAttachment(eyeatt).Ang
    pos = eyepos
    ang.p = eyeang.p
    ang.y = eyeang.y
    ang.r = eyeang.r

    local ea = (ply:GetEyeTrace().HitPos - eyepos):Angle()
    --local av = ply:GetAimVector():Angle()
    ea:Normalize()

    local viewPunch = ply:GetViewPunchAngles()

    --ply:SetViewPunchAngles(LerpAngle(0.5, viewPunch, Angle()))

    if (self:GetAimingWeapon() or ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2)) then
        --print("FUCK")

        local aea = self:GetAimEyeAngles()
        aea:Normalize()

        -- 高效(?), 相比下面那坨玩意
        local _, wtl = WorldToLocal(vector_origin, aea, vector_origin, eyeang)
        _, ang = LocalToWorld(vector_origin, clampAng(wtl, Angle(-35, -35, -5), Angle(35, 35, 5)), vector_origin, ang)
    
    end

    ang = ang + viewPunch
    --av:Normalize()

    --print(ply:EyePos(), eyepos)

    local hpos, hang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_R_Hand"))

    hpos, hang = LocalToWorld(Vector(8, 0, -3), Angle(), hpos, hang)
    --print(ply:GetAimVector(), hang:Forward())

    --[[local tr = util.TraceLine({
        start = hpos,
        endpos = ply:EyePos() + ply:GetAimVector(true) * 10000,

        filter = {ply, rag},
    })

    self.CSEnt:SetPos(tr.HitPos)]]

    --ang = self:GetAimEyeAngles() --(tr.HitPos - eyepos):Angle()
    --ang:Normalize()
    --print(ang, eyeang)

    -- I Mean, 看看这坨史, 什么都解决不了, 真是太不懂事了
    --[[for _, k in pairs(xyzs) do
        local v = eyeang[k]
        local curV = ang[k]
        local min, max = v - 35, v + 35
        if min <= -180 then
            --print(2)
            min = min + 360
            local mid = (min + max) / 2
            --print(curV, min, max, mid)
            if min < curV and max > curV then
                ang[k] = curV > mid and min or max
            end
        elseif max >= 180 then
            max = max - 360
            local mid = (max + min) / 2
            if max < curV and min > curV then
                ang[k] = curV > mid and max or min
            end
            --print(curV, min, max, mid)
        else
            --print(v, curV, min, max)
            ang[k] = math.Clamp(curV, min, max)
        end
    end]]
    local consc = self:GetConsciousness()

    local wep = ply:GetActiveWeapon()
    local noArm = true --noAimHTs[wepHT]
    --local isMeleeHT
    local wepHT

    if IsValid(wep) then
        if wep.CalcView then
            pos, ang, fov = wep:CalcView(ply, eyepos, ang, fov)
        end
        --print(1)

        wepHT = wep:GetHoldType()
        noArm = noAimHTs[wepHT] or (wep:IsScripted() and wep.ViewModel == "") --, isMeleeHT = noAimHTs[wepHT], meleeHTs[wepHT]
    end

    if consc < noArmVal then noArm = true end
    
    --print(ply:GetEyeTrace().HitPos, ply:EyeAngles(), tr.HitPos, ea)

    self.EyeAng = ang
    self.EyeFOV = fov
    self.LastEyeAng = LerpAngle(math.min(1, isSP and 1 or FrameTime() * 25), self.LastEyeAng or ang, ang)

    shouldDrawVM = not noArm and self:GetAimingWeapon()
    --ply:SetViewPunchAngles(Angle())
    --local vpa = ply:GetViewPunchAngles()
    --ply:SetViewPunchAngles(Angle())
    --print(vpa)

    --print("HYW")
    local view = {
        origin = pos,
        angles = ang,
        fov = fov,
        drawviewer = not shouldDrawVM,
    }
    --ply:GetViewModel():DrawModel()

    return view

end
function ENT:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang)

    --do return end

    local ply = LocalPlayer()

    if not IsValid(ply) or self:GetOwner() ~= ply or (IsValid(ply:GetViewEntity()) and ply:GetViewEntity() ~= ply) then return end

    local rag = self:GetRagdoll()
    local eyeatt = rag:LookupAttachment("eyes")
    if eyeatt == 0 then return end

    local eyepos = rag:GetAttachment(eyeatt).Pos
    local eyeang = self.EyeAng or rag:GetAttachment(eyeatt).Ang
    --pos = pos - eyeang:Forward() - eyeang:Up()
    
    --print(eyeang)
    --print(oldAng, ply:EyeAngles())


    local _, hang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_R_Hand"))

    _, hang = LocalToWorld(vector_origin, Angle(0, 0, 180), vector_origin, hang)
    
    --[[local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 65535,
        filter = {ply, rag},
    })]]
    local dir = ply:GetAimVector():Angle() --(tr.HitPos - eyepos):Angle() --eyeang --rag:GetAttachment(eyeatt).Ang
    --print(eyeang, dir)
    dir:Normalize()
    local dang = self.LastVMDeltaAng or Angle()
    self.LastVMDeltaAng = LerpAngle(FrameTime() * 5, dang, dir - eyeang)
    -- SOURCESDK
    -- https://github.com/ValveSoftware/source-sdk-2013/blob/c623a7c30d5cb7275cc64ed0b866f61f4a64c6eb/src/game/client/c_baseviewmodel.cpp#L55
    local fov = wep.ViewModelFOV or GetConVar("viewmodel_fov"):GetInt()
    --local wepFOV = wep.TranslateFOV and wep:TranslateFOV() or GetConVar("viewmodel_fov"):GetInt()
    local pFOV = ply:GetFOV()
    local worldX = math.tan(pFOV * math.pi / 360)
    local viewX = math.tan(fov * math.pi / 360)

    local factorX = (viewX / worldX)
    --local factorX = fov / pFOV

    local lpos, lang = WorldToLocal(pos, ang, oldPos, oldAng)

    local lea = self.LastEyeAng or Angle()
    local aeyeang = Angle(lea.x, lea.y, lea.r)
    --aeyeang:Normalize()

    --local lpos, lang = WorldToLocal(oldPos, oldAng, oldPos, oldAng)
    -- 累了 毁灭吧
    -- 目前这玩意的角度测算还是有问题, 但是好在这个被控制在仅限部分HoldType上了
    -- 已经折腾快一天了(实际上不够24小时)

    -- 很奇怪, dAng必须被加上去
    pos, ang = LocalToWorld(lpos, lang + dang * factorX, eyepos, aeyeang)
    -- 又一个歪打正着
    ang:RotateAroundAxis(ang:Right(), dang.p * factorX)
    ang:RotateAroundAxis(ang:Up(), dang.y * factorX)
    ang:RotateAroundAxis(ang:Forward(), lea.r * factorX)
    --ang.r = 0
    --print(ang)
    local wep = ply:GetActiveWeapon()

    if IsValid(wep) then
        
        if wep.CalcViewModelView then 
            pos, ang = wep:CalcViewModelView(vm, pos, ang, pos, ang)
        elseif wep.GetViewModelPosition then 
            pos, ang = wep:GetViewModelPosition(pos, ang) 
        end

    end
    --local _, delta = WorldToLocal(vector_origin, angle_zero, eyepos, eyeang)
    --print(self:GetRArmDelta())
    local rArmDelta = self:GetRArmDelta()
    self.SmoothedRArmDelta = math.Approach(self.SmoothedRArmDelta or rArmDelta, rArmDelta, 0.01)
    return pos, LerpAngle(self.SmoothedRArmDelta, ang, hang)

end

-- 你会想要把SVMAL的系统搬过来
-- 出于对双枪的兼容性(不, 实际上不兼容)
function ENT:PreDrawPlayerHands(hands, vm, ply, wep)

    --do return end

    local ply = LocalPlayer()

    if not IsValid(ply) or self:GetOwner() ~= ply or (IsValid(ply:GetViewEntity()) and ply:GetViewEntity() ~= ply) then return end


    --print(hands)
    
    local rag = self:GetRagdoll()

    local lArmDelta = self:GetLArmDelta()
    self.LastLArmDelta = Lerp(FrameTime() * 20, self.LastLArmDelta or lArmDelta, lArmDelta)
    lArmDelta = self.LastLArmDelta

    hands:SetupBones()

    local mtx = Matrix()
    for bone = 0, hands:GetBoneCount() - 1 do
        local name = hands:GetBoneName(bone)

        if not string.StartsWith(name, "ValveBiped.Bip01_L_") then continue end

        local bone2 = rag:LookupBone(name)
        -- 抽象, 理论上它们都应存在
        if not bone or not bone2 then continue end

        rag:CopyBoneMatrix(bone2, mtx)
        local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

        hands:CopyBoneMatrix(bone, mtx)
        mtx:SetTranslation(LerpVector(lArmDelta, mtx:GetTranslation(), pos))
        mtx:SetAngles(LerpAngle(lArmDelta, mtx:GetAngles(), ang))

        hands:SetBoneMatrix(bone, mtx)
    end

end

-- 客户端玩意
--[[function ENT:GetPlayerColor()
    local own = self:GetOwner()
    if not IsValid(own) then return end
    return own.GetPlayerColor and own:GetPlayerColor()
end
function ENT:GetActiveWeapon()
    local own = self:GetOwner()
    if not IsValid(own) then return end
    return own:GetActiveWeapon()
end
function ENT:GetWeapons()
    local own = self:GetOwner()
    if not IsValid(own) then return end
    return own:GetWeapons()
end]]


