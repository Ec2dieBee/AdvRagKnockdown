-- Ciallo
-- 这是一个仿照(和修改)Z-City击倒/布娃娃系统的玩意(但是是TM自己想的, 太痛苦了, 太痛苦了)
-- 但是我不想让这玩意挂上各种License(保留所有权利.jpg)所以代码是自己写的, 痛苦程度参见实体的抓握部分
-- 你知道有好的方法能用但是因为你看了答案所以你不再能使用它aughhhhhhhh
-- 
-- Savee14702 保留一切权利
-- 如果使用/修改该插件的核心部分, 请在发布页面的Credits里加上我的名字
-- 
-- 2026/5/17 这一切全他妈关于速度 你想要留下你的名字就必须快点, 是的这都关于名头, 你第一个弄出来这个名头就是你的
-- @RagKnockdown @MPNKnockdown(RagKnockdown的更全的老版本, 支持ClassicKnockdown(ZSKnockdown), 这是我的命名)
-- TODO: SANITY CHECK, 如果有更多需要读CTRL的玩意


AddCSLuaFile()

-- CVs
local cvPrefix = "savee_advragknockdown_"
local cvTags = {FCVAR_ARCHIVE,FCVAR_REPLICATED}

-- 证明我抄袭了RagKnockdown的有力证据
local cv_kd_enabled = CreateConVar(cvPrefix .. "enabled", 1, cvTags, "字面意思, 除了typo", 0, 1)
local cv_kd_enabled_ply = CreateConVar(cvPrefix .. "enableply", 1, cvTags, "字面意思, 除了typo", 0, 1)
local cv_kd_enabled_npc = CreateConVar(cvPrefix .. "enablenpc", 1, cvTags, "字面意思, 除了typo", 0, 1)
local cv_kd_damagecalc_usetakedamage = CreateConVar(cvPrefix .. "damagecalc_usetakedamage", 0, cvTags, "使用TakeDamageInfo并更进一步修改BulletTable, 可能会出现没受到伤害且力度不够时仍被击倒的情况", 0, 1)
local cv_kd_damagecalc_usetakedamage_bulletnodelay = CreateConVar(cvPrefix .. "damagecalc_usetakedamage_dontdelaybulletcalc", 0, cvTags, "取消延迟子弹的击倒判定, **十分不建议在ZCity里启用这个**", 0, 1)
local cv_kd_damagecalc_usetakedamage_strictbullet = CreateConVar(cvPrefix .. "damagecalc_usetakedamage_strictbullet", 0, cvTags, "启用更加\"严苛\"的判定方式以防止无限穿透四肢 0-正常 1-严苛 2-很几把严苛 **建议在ZCity里设成2**", 0, 2)

CreateConVar(cvPrefix .. "npc_usehook_createentityragdoll", 0, cvTags, "在NPC被击倒时调用CreateEntityRagdoll", 0, 1)
CreateConVar(cvPrefix .. "playdead_npc_usehook_createentityragdoll", 1, cvTags, "在NPC假死时调用CreateEntityRagdoll", 0, 1)

CreateConVar(cvPrefix .. "statcalc_npc_staminadmgmul", 1, cvTags, "[对NPC] 体力伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_npc_conscdmgmul", 1, cvTags, "[对NPC] 意识伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_ply_staminadmgmul", 1, cvTags, "[对玩家] 体力伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_ply_conscdmgmul", 1, cvTags, "[对玩家] 意识伤害乘数", 0)

local entMeta = FindMetaTable("Entity")
local plyMeta = FindMetaTable("Player")
local npcMeta = FindMetaTable("NPC")

local isSP = game.SinglePlayer()

-- 防止你射的正爽的时候子弹从你的眼睛打到你的胳膊
local whitelistedBones = {
    ["ValveBiped.Bip01_Head1"] = true,
    ["ValveBiped.Bip01_R_Clavicle"] = true,
    ["ValveBiped.Bip01_R_UpperArm"] = true,
    ["ValveBiped.Bip01_R_Forearm"] = true,
    ["ValveBiped.Bip01_R_Hand"] = true,
    ["ValveBiped.Bip01_L_Clavicle"] = true,
    ["ValveBiped.Bip01_L_UpperArm"] = true,
    ["ValveBiped.Bip01_L_Forearm"] = true,
    ["ValveBiped.Bip01_L_Hand"] = true,
}

-- ToDo: 是否需要将NW换成NW2?

--[[SAVEE_ADVRAGKNOCKDOWN_LIMBS = {
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_R_Hand",
}]]
local BITCOUNT_LIMBINFO = 3
local BITCOUNT_OPERATIONINFO = 2
local tickInterval = engine.TickInterval()
local handPosDelta = Vector(16, 0, -4)

--[[funchooks.Add("Entity.EyePos", "test1", function(self, ...)

    --print("Ciall1o~")

    return __undetoured(self, ...)

end)
funchooks.Add("Entity.EyePos", "test", function(self, ...)

    --print("Ciall3o~")

    return __undetoured(self, ...)

end)]]

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

local function entTypeCheck(ent)
    if not cv_kd_enabled:GetBool() then return false end
    if not IsValid(ent) or ent:IsMarkedForDeletion() or ent:Health() <= 0 then return false end
    return (ent:IsPlayer() and cv_kd_enabled_ply:GetBool()) or (ent:IsNPC() and cv_kd_enabled_npc:GetBool())
end
local function getController(ent)
    if not cv_kd_enabled:GetBool() then return end
    local ctrl = CLIENT and ent:GetNW2Entity("Savee_AdvRagKnockdown_Controller") or ent.Savee_AdvRagKnockdown_Controller
    if not IsValid(ctrl) or not ctrl.GetRagdoll or not IsValid(ctrl:GetRagdoll()) then return end
    return ctrl
end

-- debug.lua
local function debugTrace()

	local level = 1

	local str = ""

	while true do

		local info = debug.getinfo( level, "Sln" )
		if ( !info ) then break end

		if ( info.what ) == "C" then

			str = str .. string.format( "\t%i: C function\t\"%s\"\n", level, info.name )

		else

			str = str .. string.format( "\t%i: Line %d\t\"%s\"\t\t%s\n", level, info.currentline, info.name, info.short_src )

		end

		level = level + 1

	end

    return str

end

local trs = {
    "TraceLine",
    "TraceHull",
    "TraceEntity",
    "TraceEntityHull",
}
local wlDebugTraces = {
    "DoToolTrace",
    "wep_jack_gmod_hands",
    "mvp_perfecthands",
}

local function isWhiteListedTrace(traceStr)
    if not traceStr then return end
    for _, str in ipairs(wlDebugTraces) do
        if string.find(traceStr, str) then return true end
    end
    return false
end


for _, str in ipairs(trs) do
    
    local function trOverride(data, ...)

        --do return __undetoured(data, ...) end

        --print(1)
        --print(data.filter)
        --error("1 \n", 2)
        local trace = debugTrace()
        --if string.find(trace or "", "DoToolTrace") then print(111) end
        if data.getRaw or isWhiteListedTrace(trace) then
            --print(data.filter)
            data.getRaw = true
            return __undetoured(data, ...)
        end
        --if SERVER then ErrorNoHalt(trace) end

        local filter = data.filter
        --print(filter)
        if istable(filter) then
            local found = {}

            for _, e in ipairs(filter) do

                if not IsValid(e) then continue end
                local ctrl = getController(e)
                if not IsValid(ctrl) or found[ctrl] then continue end
                found[ctrl] = true
                --print(e)
                filter[#filter + 1] = e:IsRagdoll() and ctrl:GetOwner() or ctrl:GetRagdoll()

            end

        elseif isentity(filter) then

            local ctrl = getController(filter)
            if not IsValid(ctrl) then return __undetoured(data, ...) end

            --print(111)
            data.filter = {ctrl:GetOwner(), ctrl:GetRagdoll()}
            --if SERVER then debug.Trace() end

        elseif isfunction(filter) then

            local newfunc = function(ent)
                local ctrl = getController(ent)
                if not IsValid(ctrl) then return filter(ent) end
                local own, rag = ctrl:GetOwner(), ctrl:GetRagdoll()
                local eyePos = own:EyePos()
                local rHD = ctrl:GetRArmDelta()

                local aimTr = util.TraceLine({
                    start = eyePos,
                    endpos = eyePos + ctrl:GetAimEyeAngles():Forward() * 65536,
                    filter = own,
                    mask = MASK_SHOT,
                    getRaw = true,
                })
                --print(ent, aimTr.Entity, aimTr.Entity ~= rag)
                if rHD <= 0.15 and (aimTr.Entity ~= rag or whitelistedBones[rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone) or -1)]) then
                    return filter(own) and filter(rag)
                end

                return filter(ent)
            end

            data.filter = newfunc

        end

        --PrintTable(data)

        --if SERVER then debug.Trace() PrintTable(__raw(data, ...)) end

        return __undetoured(data, ...)

    end
    local function trOverride2(inp, _2, data, ...)

        --do return __undetoured(inp, _2, data, ...) end
        --print(1, data, ...)
        --PrintTable(inp)
        --PrintTable(_2)
        --PrintTable(data)

        local ent = data.Entity
        --if SERVER then print(data.getRaw) end
        if not IsValid(ent) or not ent:IsRagdoll() or inp.getRaw then return __undetoured(inp, _2, data, ...) end
        local ctrl = getController(ent)

        --print(1)
        if IsValid(ctrl) then
            --print(ctrl:GetOwner())
            data.Entity = ctrl:GetOwner()
            --print(data.HitBoxBone)
            --print(data.HitGroup)
            if SERVER then
                local rag = ctrl:GetRagdoll()
                local tr = util.TraceHull({
                    start = data.HitPos,
                    endpos = data.HitPos,
                    whitelist = true,
                    filter = {rag},
                    getRaw = true,
                    mask = MASK_ALL,
                    mins = Vector(-2, -2, -2),
                    maxs = Vector(2, 2, 2),
                })
                local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
                local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]
                data.HitGroup = hitGroup or 0
            elseif data.HitBox == 0 then
                data.HitGroup = ent:GetHitBoxHitGroup(data.HitBox, 0)
            end
            --print(12)
        end

        return __undetoured(inp, _2, data, ...)

    end

    funchooks.Add("util." .. str, "Savee_AdvRagKnockdown_HitScanMod", trOverride)
    funchooks.AddPost("util." .. str, "Savee_AdvRagKnockdown_HitScanMod", trOverride2)

end

--funchooks.Add("util.TraceLine", "Savee_AdvRagKnockdown_HitScanMod", trOverride)
----funchooks.Add("util.TraceLine", "Savee_AdvRagKnockdown_HitScanMod2", trOverride)
--funchooks.Add("util.TraceHull", "Savee_AdvRagKnockdown_HitScanMod", trOverride)
--funchooks.Add("util.TraceEntity", "Savee_AdvRagKnockdown_HitScanMod", trOverride)
--funchooks.Add("util.TraceEntityHull", "Savee_AdvRagKnockdown_HitScanMod", trOverride)


--print(funchooks.GetRawFunction("util.TraceLine"))

funchooks.Add("Entity.GetPos", "Savee_AdvRagKnockdown_Sync", function(ent, raw, ...)

    if raw or not entTypeCheck(ent) then return __undetoured(ent, raw, ...) end
    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:GetBonePosition(0)

    return bone
   
end)

local doOriginalHTs = {
    ["knife"] = true,
    ["melee"] = true,
    ["melee2"] = true,
    ["fists"] = true,
    ["magic"] = true,
    ["grenade"] = true,
    ["camera"] = true,
    ["slam"] = true,
    ["normal"] = true,
}

funchooks.Add("Player.GetShootPos", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --if SERVER then print(__undetoured(ply)) end
    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if raw or not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local rag = ctrl:GetRagdoll()

    local wep = ply:GetActiveWeapon()
    local nonFirearm = doOriginalHTs[IsValid(wep) and wep:GetHoldType() or ""]

    if nonFirearm then return ply:EyePos(raw, ...) end
    --print(nonFirearm)
    local mtx = rag:GetBoneMatrix(rag:LookupBone("ValveBiped.Bip01_R_Hand"))

    -- 多门游戏支持
    if not mtx then return __undetoured(ply, raw, ...) end
    local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

    local newpos, newang = LocalToWorld(handPosDelta, Angle(), pos, ang)
    local tr = util.TraceLine({
        start = pos,
        endpos = newpos,
        filter = {ply, rag},
        mask = MASK_SHOT,
    })
    --print(tr.Entity)


    return tr.HitPos
   

end)
funchooks.Add("NPC.GetShootPos", "Savee_AdvRagKnockdown_Sync", function(ply, ...)

    --if SERVER then print(__undetoured(ply)) end
    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()
    local mtx = rag:GetBoneMatrix(rag:LookupBone("ValveBiped.Bip01_R_Hand"))
    local pos, ang = mtx:GetTranslation(), mtx:GetAngles()

    local newpos, newang = LocalToWorld(handPosDelta, Angle(), pos, ang)
    local tr = util.TraceLine({
        start = pos,
        endpos = newpos,
        filter = {ply, rag},
        mask = MASK_SHOT,
    })
    --print(tr.Entity)


    return tr.HitPos
   

end)

local lastSysTime = -1
funchooks.Add("Entity.EyePos", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local sysTime = SysTime()
    
    if lastSysTime >= sysTime and ctrl.VarCaches["EyePos"] then 
        --print("有点拦截了") 
        return ctrl.VarCaches["EyePos"] 
    end
    lastSysTime = sysTime + FrameTime() * 0.1

    local rag = ctrl:GetRagdoll()

    local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then return __undetoured(ply, raw, ...) end

    local tr

    local delta = math.Clamp(CLIENT and ctrl.SmoothedRArmDelta or (ctrl:GetRArmDelta() - 0.03) * 10, 0, 1)

    if ctrl:GetAimingWeapon() and delta <= 0.15 then
        local eyeatt = rag:LookupAttachment("eyes")
        if eyeatt == 0 then return __undetoured(ply, raw, ...) end

        local eyepos = rag:GetAttachment(eyeatt).Pos
        local eyeang = rag:GetAttachment(eyeatt).Ang

        tr = util.TraceLine({
            start = eyepos,
            endpos = eyepos + eyeang:Forward() * 5 * (rag.Savee_AdvRagKnockdown_ModelScale or 1),
            filter = {ply, rag},
            mask = MASK_SHOT,
        })
    else
        local pos, ang = rag:GetBonePosition(bone)
        local newhandpos = LocalToWorld(handPosDelta, Angle(), pos, ang)
        tr = util.TraceLine({
            start = pos,
            endpos = newhandpos,
            filter = {ply, rag},
            mask = MASK_SHOT,
        })
    end

    --local wep = ply:GetActiveWeapon()

    -- 简单的解法, 极致的脑瘫
    local final = tr.HitPos - ctrl:GetAimEyeAngles():Forward()

    ctrl.VarCaches["EyePos"] = final
    --print(final)

    return final
   

end)
funchooks.Add("Entity.EyeAngles", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)

    -- 神秘多人游戏bug
    if not IsValid(ctrl) or not ctrl.GetAimEyeAngles then return __undetoured(ply, raw, ...) end

    local ea = ctrl:GetAimEyeAngles()
    ea.z = 0
    ea:Normalize()

    return SERVER and ea or LerpAngle(FrameTime(), ctrl.LastEyeAng or ea, ea)
   

end)

funchooks.Add("Entity.GetVelocity", "Savee_AdvRagKnockdown_Sync", function(ply, ...)

    if not entTypeCheck(ply) then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    
    local rag = ctrl:GetRagdoll()

    local vel = SERVER and rag:GetPhysicsObjectNum(0):GetVelocity() or rag:GetVelocity()

    if vel:LengthSqr() <= 64 then 
        vel = Vector()
    end
    return vel
   
end)

funchooks.AddPost("Entity.SetPos", "Savee_AdvRagKnockdown_Sync", function(ply, inputs, ...)

    local raw = inputs[2]
    if raw or not entTypeCheck(ply) then return __undetoured(ply, inputs, ...) end

    local ctrl = getController(ply)

    -- 神秘多人游戏bug
    if not IsValid(ctrl) then return __undetoured(ply, inputs, ...) end

    local rag = ctrl:GetRagdoll()
    local pos = inputs[1]

    local oldPos = ply:GetPos()
    for _, data in pairs(ctrl.RagPObjs) do
        local pObj = data.pObj
        if not data.physBone or not pObj then continue end
        local wtl = pObj:GetPos() - oldPos
        pObj:SetPos(pos + wtl)
    end

    return __undetoured(ply, inputs, ...)

end)

funchooks.Add("Entity.ManipulateBoneAngles", "Savee_AdvRagKnockdown_Sync", function(ply, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if not ply:IsPlayer() then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()

    rag:ManipulateBoneAngles(...)

    return __undetoured(ply, ...)
   

end)
funchooks.Add("Entity.ManipulateBonePosition", "Savee_AdvRagKnockdown_Sync", function(ply, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if not ply:IsPlayer() then return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ...) end
    local rag = ctrl:GetRagdoll()

    rag:ManipulateBonePosition(...)

    return __undetoured(ply, ...)
   

end)

funchooks.Add("Entity.IsOnGround", "Savee_AdvRagKnockdown_Sync", function(ent, ...)
    if ent:IsRagdoll() then return __undetoured(ent, ...) end

    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, ...) end

    return ctrl:GetRagdoll():IsOnGround(...)
end)
funchooks.Add("Entity.OnGround", "Savee_AdvRagKnockdown_Sync", function(ent, ...)
    if ent:IsRagdoll() then return __undetoured(ent, ...) end

    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, ...) end

    return ctrl:GetRagdoll():OnGround(...)
end)

funchooks.Add("Player.GetAimVector", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")

    local eyeatt = rag:LookupAttachment("eyes")
    if not bone or eyeatt == 0 then return __undetoured(ply, raw, ...) end

    local eyepos = rag:GetAttachment(eyeatt).Pos

    local handpos, handang = rag:GetBonePosition(bone)
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ply, rag},
        mask = MASK_SHOT,
    })]]

    local av = raw and __raw(ply, ...) or (CLIENT and (ctrl.LastEyeAng and ctrl.LastEyeAng:Forward()) or ctrl:GetAimEyeAngles():Forward()) --(tr.HitPos - eyepos):GetNormalized()
    --print(rDelta)


    return LerpVector(CLIENT and ctrl.SmoothedRArmDelta or math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av, handang:Forward())
   

end)
funchooks.Add("NPC.GetAimVector", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")

    local eyeatt = rag:LookupAttachment("eyes")
    if not bone or eyeatt == 0 then return __undetoured(ply, raw, ...) end

    local eyepos = rag:GetAttachment(eyeatt).Pos

    local handpos, handang = rag:GetBonePosition(bone)
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ply, rag},
        mask = MASK_SHOT,
    })]]

    local av = raw and __raw(ply, ...) or ctrl:GetAimEyeAngles():Forward() --(tr.HitPos - eyepos):GetNormalized()
    --print(rDelta)


    return LerpVector(CLIENT and ctrl.SmoothedRArmDelta or math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av, handang:Forward())
   

end)


funchooks.Add("Player.IsPlayingTaunt", "Savee_AdvRagKnockdown_ARC9TPIK", function(ply, ...)

    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) or true then return __undetoured(ply, ...) end
    
    -- TODO: 把IN_USE检测换了
    return false
   

end)

-- https://wiki.facepunch.com/gmod/GM:ScaleNPCDamage
local function GetNPCDamageMultiplier(npc, iHitGroup, dmginfo)

    if (iHitGroup == HITGROUP_GEAR) then
        -- HL2 also sets the hitgroup to GENERIC here, but we cannot
        return 0.01
    elseif (iHitGroup == HITGROUP_HEAD) then
        -- Some NPCs have unique behaviors
        if (npc:GetClass() == "npc_combine_s") then
            return 2
        elseif (npc:GetClass() == "npc_zombie" or npc:GetClass() == "npc_zombine" or npc:GetClass() == "npc_fastzombie" or
                npc:GetClass() == "npc_poisonzombie" or npc:GetClass() == "npc_zombie_torso" or npc:GetClass() == "npc_fastzombie_torso") then
            if (bit.band(dmginfo:GetDamageType(), DMG_BUCKSHOT) != 0) then
                if (IsValid(dmginfo:GetAttacker())) then
                    local flDist = (npc:GetPos() - dmginfo:GetAttacker():GetPos()):Length()

                    if flDist <= 96 then
                        return 3
                    end
                end
            else
                return 2
            end
        end

        return GetConVarNumber("sk_npc_head")
    elseif (iHitGroup == HITGROUP_CHEST) then
        return GetConVarNumber("sk_npc_chest")
    elseif (iHitGroup == HITGROUP_STOMACH) then
        return GetConVarNumber("sk_npc_stomach")
    elseif (iHitGroup == HITGROUP_LEFTARM or iHitGroup == HITGROUP_RIGHTARM) then
        return GetConVarNumber("sk_npc_arm")
    elseif (iHitGroup == HITGROUP_LEFTLEG or iHitGroup == HITGROUP_RIGHTLEG) then
        return GetConVarNumber("sk_npc_leg")
    end

    -- No change in damage
    return 1

end

-- 武器支持
hook.Add("EntityFireBullets", "Savee_AdvRagKnockdown_HitScanMod", function(ent, bullet)
    --local wep = ent
    if ent:IsWeapon() then ent = ent:GetOwner() end
    if cv_kd_damagecalc_usetakedamage_strictbullet:GetBool() and bullet.Savee_AdvRagKnockdown_Suspended then
        return false
    end
    
    if SERVER then
        local cb = bullet.Callback
        bullet.Callback = function(attacker, btr, di)
            --BTR!???????

            --btr = table.Copy(btr)

            --print(tr.HitGroup)
            --print(di)
            --tr.HitGroup = 1
            local rag = btr.Entity

            --bullet.Fucked = true
            --print(btr.HitPos)
            if cv_kd_damagecalc_usetakedamage_strictbullet:GetBool() and bullet.Savee_AdvRagKnockdown_SuspendIfHitAgain == rag then
                --print(2)
                bullet.Savee_AdvRagKnockdown_Suspended = true
                return {damage = false, effects = false}
            end

            local ctrl = getController(rag)
            --print(rag)
            if IsValid(ctrl) then
                local own = ctrl:GetOwner()

                if IsValid(rag) and rag:IsRagdoll() then

                    local tr = util.TraceHull({
                        start = btr.HitPos,
                        endpos = btr.HitPos,
                        whitelist = true,
                        filter = {rag},
                        getRaw = true,
                        mask = MASK_ALL,
                        mins = Vector(-2, -2, -2),
                        maxs = Vector(2, 2, 2),
                    })
                    local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
                    local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]
                    --print(hitGroup, HITGROUP_HEAD)
                    --hook.Run(own:IsPlayer() and "ScalePlayerDamage" or "ScaleNPCDamage", own, hitGroup, di)
                    --[[if not scale and own:IsNPC() then
                        scale = GetNPCDamageMultiplier(own, hitGroup, di)
                        --print(scale)
                    end]]
                    --di:ScaleDamage(di:GetDamage() * (scale or 1))
                    --print(hitGroup)
                    -- 神秘Bug, 我忘记重名的事了
                    btr.HitBoxBone = bone
                    btr.HitBox = rag.Savee_AdvRagKnockdown_HitBoxes[bone]
                    btr.HitGroup = hitGroup --own:GetHitBoxHitGroup(rag.Savee_AdvRagKnockdown_HitBoxes[bone], 0)
                    btr.Entity = own
                    --print("?")
                    --di:SetDamage(di:GetDamage() / 2)
                    --if not bullet.IgnoreEntity then bullet.IgnoreEntity = rag end

                    --ctrl.DI_MarkedAsTaken[di] = true

                    --print(hitGroup)
                end
                --if not bullet.IgnoreEntity or bullet.IgnoreEntity == own then bullet.IgnoreEntity = ctrl:GetRagdoll() end
            end
            --di:SetDamage(114514)
            --cb(attacker, tr, di)

            local result

            --print(btr.Entity)
            --print(di)
            if cb then
                --print(btr.HitGroup)
                result = cb(attacker, btr, di)
                --print(1, di, btr.Entity)
            end

            --local ent = btr.Entity
            if SERVER and cv_kd_damagecalc_usetakedamage:GetBool() and IsValid(rag) then
                if cv_kd_damagecalc_usetakedamage_bulletnodelay:GetBool() then
                    if rag:IsRagdoll() then
                        Savee_AdvRagKnockdown_DoRagDamage(rag, di, di:GetDamage() > 0)
                    else
                        Savee_AdvRagKnockdown_DMGKnockdown(rag, di, di:GetDamage() > 0)
                    end
                else
                    timer.Simple(tickInterval, function()
                        if not di then return end
                        if rag:IsRagdoll() then
                            Savee_AdvRagKnockdown_DoRagDamage(rag, di, di:GetDamage() > 0)
                        else
                            Savee_AdvRagKnockdown_DMGKnockdown(rag, di, di:GetDamage() > 0)
                        end
                    end)
                end
                if cv_kd_damagecalc_usetakedamage_strictbullet:GetBool() and IsValid(ctrl) then
                    --print(1)
                    bullet.IgnoreEntity = ctrl:GetOwner()
                    bullet.Savee_AdvRagKnockdown_SuspendIfHitAgain = rag
                    bullet.Savee_AdvRagKnockdown_Suspended = cv_kd_damagecalc_usetakedamage_strictbullet:GetInt() == 2
                end
            end

            return result

        end
    end

    ---@type Entity
    local ctrl = getController(ent)
    --print(ent)
    if not IsValid(ctrl) then return true end
    --print("ccc")

    local rag = ctrl:GetRagdoll()
    --[[local eyeatt = rag:LookupAttachment("eyes")

    local eyepos = rag:GetAttachment(eyeatt).Pos]]

    --print(bullet.Src, ent:EyePos(), ent:GetShootPos())

    local shootPos = ent:GetShootPos()
    local eyePos = ent:EyePos()

    local rHD = ctrl:GetRArmDelta()
    --print(rHD)

    local wep = bullet.Inflictor

    --print(bullet.Src, eyePos, shootPos)
    if (IsValid(wep) and not wep:IsScripted() or bullet.Src == shootPos) and rHD <= 0.15 then
        bullet.Src = eyePos
    elseif rHD > 0.15 and bullet.Src == eyePos then
        bullet.Src = shootPos
    end

    --bullet.Src = eyePos

    local handpos, handang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_R_Hand"))
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ent, rag},
        mask = MASK_SHOT,
    })]]
    --local actualav = (tr.HitPos - shootPos):GetNormalized()

    local av = ent:GetAimVector()
    -- 神秘Bug修复
    local bDir = (isSP or SERVER) and bullet.Dir or av

    --[[if CLIENT then
        --local ang = bDir:Angle()
        --ang:Normalize()
        --print(ent:EyeAngles(true), ang)

        --bDir:Rotate(Angle(31, 0, 0))
        --bDir = av
    end]]
    --print(bDir:Angle(), av:Angle(), ent:GetAimVector(true):Angle(), ent:EyeAngles(true))
    local _, dDir = WorldToLocal(vector_origin, bDir:Angle(), vector_origin, av:Angle())

    --print(dDir)
    bDir = ctrl:GetAimEyeAngles():Forward()
    bDir:Rotate(dDir)

    local hAngFwd = handang:Forward()
    hAngFwd:Rotate(dDir)
    --bDir = LocalToWorld(dDir, angle_zero, ctrl:GetAimEyeAngles():Forward(), angle_zero)
    --dDir = LocalToWorld(dDir, angle_zero, handang:Forward(), handang)
    --dDir:Normalize()


    --print(rDelta)

    --print(bullet.IgnoreEntity)
    --print(bullet.Src, ent:EyePos(), ent:GetShootPos())
    --print(math.Clamp((rHD - 0.03), 0, 1))
    bullet.Dir = LerpVector(math.Clamp((rHD - 0.03) * 10, 0, 1), bDir, hAngFwd)

    --[[local tr = util.TraceLine({
        start = bullet.Src,
        endpos = bullet.Src + bullet.Dir * 65536,
        filter = {ent, rag},
        mask = MASK_SHOT,
    })]]

    local aimTr = util.TraceLine({
        start = eyePos,
        endpos = eyePos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = ent,
        mask = MASK_SHOT,
        getRaw = true,
    })
    --util.QuickTrace(eyePos, ctrl:GetAimEyeAngles():Forward() * 1000)
    --print(aimTr.Entity)
    -- 确认你不是机器人
    -- 有效防止MTM Neutrino Cannon 把你囊死的问题
    if not IsValid(bullet.IgnoreEntity) and rHD <= 0.15 and (aimTr.Entity ~= rag or whitelistedBones[rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone) or -1)]) then
        bullet.IgnoreEntity = ctrl:GetRagdoll()
    --[[else
        print(1)]]
    end

    return true --__undetoured(ent, bullet)

end)

-- 所以你不必要在空中蹲下然后发现自己起不来
-- 就当是在穿墙吧
hook.Add("Move", "Savee_AdvRagKnockdown_RagMoveOverride", function(ply)
    
    local ctrl = ply.Savee_AdvRagKnockdown_Controller
    if not IsValid(ctrl) then return end

    -- SourceSDK https://github.com/ValveSoftware/source-sdk-2013/blob/3300848d8a25ef6403c91f82a4cd97d6daefbc06/src/game/shared/gamemovement.cpp#L1203
    -- 直接复制了他们的ViewPunch代码, 因为我们不希望玩家做任何事, 但不幸的是他们也会被禁用
    local viewPunch = ply:GetViewPunchAngles()
    local viewPunchVel = ply:GetViewPunchVelocity()
    local len, lenVel = viewPunch:Forward():LengthSqr()
    if len > 0.001 or lenVel > 0.001 then
        local ft = FrameTime()

        viewPunch = viewPunch + viewPunchVel * ft
        local damping = math.max(0, 1 - (9 * ft))

        viewPunchVel = viewPunchVel * damping

        local springForceMagnitude = math.Clamp(69 * ft, 0, 2)
        viewPunchVel = viewPunchVel - viewPunch * springForceMagnitude

        ply:SetViewPunchAngles(viewPunch)
        ply:SetViewPunchVelocity(viewPunchVel)

    else
        ply:SetViewPunchAngles(angle_zero)
        ply:SetViewPunchVelocity(angle_zero)
    end
    --print(viewPunch)

    return true

end)

hook.Add("Tick", "Savee_AdvRagKnockdown_CtrlTick", function()
    --do return end
    for _, ent in pairs(ents.FindByClass("ent_savee_advragknockdown_ctrl")) do
        if not IsValid(ent) or ent:IsMarkedForDeletion() then continue end
        
        local own = ent:GetOwner()
        if not IsValid(ent:GetRagdoll()) or not IsValid(own) or own:IsMarkedForDeletion() or own:Health() <= 0 then ent:RemoveSelf() continue end
        ent:Tick()
    end
end)
    
if SERVER then

    --util.AddNetworkString("Savee_AdvRagKnockdown_UpdateRagLimbs")
    util.AddNetworkString("Savee_AdvRagKnockdown_OperationMsg")
    util.AddNetworkString("Savee_AdvRagKnockdown_MouseMoveMsg")

    local hitgroup_limbs = {0.2, 0.1}
    local hitgroupDmg_limbs = 0.6

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
    local hitGroupPhysicsDmgMuls = {
        [HITGROUP_GENERIC] = 1,
        [HITGROUP_HEAD] = 2.5,
        [HITGROUP_CHEST] = 1.2,
        [HITGROUP_STOMACH] = 1,
        [HITGROUP_GEAR] = 0,
        [HITGROUP_LEFTARM] = hitgroupDmg_limbs,
        [HITGROUP_RIGHTARM] = hitgroupDmg_limbs,
        [HITGROUP_LEFTLEG] = hitgroupDmg_limbs,
        [HITGROUP_RIGHTLEG] = hitgroupDmg_limbs,
    }

    local dmgTypeMuls = {
        [DMG_CRUSH] = {2, 5},
        [DMG_CLUB] = {1.5, 2.5},
        [DMG_SLASH] = {1.5, 0.8},
        [DMG_BLAST] = {0.3, 2},
    }

    --[[---@param ctrl Entity
    ---@param rag Entity
    ---@param di CTakeDamageInfo
    local function doBrainDamages(ctrl, rag, di)

        local ct = CurTime()
        local dmg = di:GetDamage()

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

        local forceMul = math.max(0.5, di:GetDamageForce():Length() / 3500)
        local hgMul = hitGroupMuls[hitGroup or 0]
        local dtMul = dmgTypeMuls[di:GetDamageType()]
        local stDmg = (dmg * 0.8) * (hgMul and hgMul[1] or 1) * (dtMul and dtMul[1] or 1) * forceMul
        local csDmg = (dmg * 0.5) * (hgMul and hgMul[2] or 1) * (dtMul and dtMul[2] or 1) * forceMul

        --print(rag:GetBoneName(bone), rag.Savee_AdvRagKnockdown_HitGroups[bone])

        local stamina = ctrl:GetStamina()
        stamina = stamina - stDmg

        local consc = ctrl:GetConsciousness()
        consc = consc - csDmg

        ctrl:SetStamina(math.max(0, stamina))
        ctrl:SetConsciousness(math.max(0, consc))

        ctrl.NextRegenStamina = math.max(ct, ctrl.NextRegenStamina) + math.Clamp(dmg / 20, 0.1, 1.5) * forceMul / 2
        ctrl.NextRegenConsciousness = math.max(ct, ctrl.NextRegenConsciousness) + math.Clamp(dmg / 10, 0.1, 2) * forceMul / 2

    end]]
    local function doKnockdown(ply, vec, bone)

        if not cv_kd_enabled:GetBool() then return end

        --print("正在击倒: ", ply, vec, bone)

        if not entTypeCheck(ply) then return end

        local oldCtrl = getController(ply)
        if IsValid(oldCtrl) then
            oldCtrl.GettingUp = false
            if own:IsNPC() then
                oldCtrl:SetCachedVar("NPC_CanGetUpVar", false, math.Rand(3, 7))
            end
        end
        
        if ply:IsNPC() then 
            -- sa_03
            for _, e in pairs(ents.FindInSphere(ply:GetPos(), 512)) do
                if IsValid(e) and e:CreatedByMap() and e:GetParent() == ply then return end
            end
            --return
        end

        if ply:IsPlayer() and ply:InVehicle() then
            local can = hook.Run("CanExitVehicle", ply:GetVehicle(), ply)
            if not can then return end
            ply:ExitVehicle()
        end
        local ctrl = IsValid(oldCtrl) and oldCtrl or ents.Create("ent_savee_advragknockdown_ctrl")
        if not IsValid(oldCtrl) then
            ctrl:SetOwner(ply)
            ctrl:SetPos(ply:GetPos())
            ctrl:SetAimEyeAngles(ply:EyeAngles())
            ctrl:Spawn()
            ctrl.PreventPhysAttackTill = CurTime() + 0.05
        end
        --do return end
        --ply:SetNW2Entity("Savee_AdvRagKnockdown_Controller", ent)
        local rag = ctrl:GetRagdoll()
        if vec and IsValid(rag) then
            if not isvector(vec) then
                if di then ctrl.DI_MarkedAsTaken[di] = true end
                
                rag:TakePhysicsDamage(vec) 
                ctrl:DoBrainDamages(vec, true)
                return
            end
            
            if not bone then
                for i = 0, rag:GetPhysicsObjectCount() - 1 do
                    local pObj = rag:GetPhysicsObjectNum(i)
                    pObj:ApplyForceCenter(vec)
                end
            else
                local bone = rag:TranslateBoneToPhysBone(bone)
                local pObj = rag:GetPhysicsObjectNum(bone)
                if not pObj then return end
                pObj:ApplyForceCenter(vec)
            end
        end

    end
    local function doKnockdown_Damage(ply, vec, bone)
        if not entTypeCheck(ply) then return end
        --print(tickInterval)
        timer.Simple(tickInterval, function()
            if not IsValid(ply) or IsValid(getController(ply)) then return end
            return doKnockdown(ply, vec, bone)
        end)

    end

    local function replaceRagconstraint(rag, bchild, bparent, minAng, maxAng, fric)
    
        if not IsValid(rag) or not bchild or not bparent then return end
        if not rag:LookupBone(bparent) or not rag:LookupBone(bchild) then return end
        
        --local _
        minAng = minAng or Angle()
        maxAng = maxAng or Angle()
        fric = fric or 0
        
        -- 我甚至记得下来完整的前缀
        -- 每个正常模型都有的玩意, 没有就让它滚
        local lArm = rag:TranslateBoneToPhysBone(rag:LookupBone(bparent))
        local lHand = rag:TranslateBoneToPhysBone(rag:LookupBone(bchild))
        local lArmP = rag:GetPhysicsObjectNum(lArm)
        local lHandP = rag:GetPhysicsObjectNum(lHand)
        local oldHandPos, oldHandAng, oldArmPos, oldArmAng = lHandP:GetPos(), lHandP:GetAngles(), lArmP:GetPos(), lArmP:GetAngles()

        --lHandP:ClearGameFlag(FVPHYSICS_PART_OF_RAGDOLL)
        --lHandP:ClearGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY)
        
        local ent = ents.Create("base_anim")
        ent:SetModel(rag:GetModel())
        ent:Spawn()
        
        -- 我希望布娃娃的相对骨骼修改始终如一
        -- constraint.AdvBallsocket局部过头(即相对当前角度), 需要复原才行
        local armPos, armAng = ent:GetBonePosition(ent:LookupBone(bparent))
        local handPos, handAng = ent:GetBonePosition(ent:LookupBone(bchild))
        
        SafeRemoveEntity(ent)
        
        lArmP:SetPos(armPos)
        lArmP:SetAngles(armAng)
        lHandP:SetPos(handPos)
        lHandP:SetAngles(handAng)
        
        local wtlLH = WorldToLocal(lHandP:GetPos(), lHandP:GetAngles(), lArmP:GetPos(), lArmP:GetAngles())
        --local
        rag:RemoveInternalConstraint(lHand)
        local const = constraint.AdvBallsocket(rag, rag, lArm, lHand, wtlLH, nil, 0, 0, minAng.p, minAng.y, minAng.r, maxAng.p, maxAng.y, maxAng.r, fric, fric, fric, 0, 1)
        if IsValid(const) then 
            table.insert(rag.Savee_AdvRagKnockdown_ShitConsts, const)
        end

        lArmP:SetPos(oldArmPos)
        lArmP:SetAngles(oldArmAng)
        lHandP:SetPos(oldHandPos)
        lHandP:SetAngles(oldHandAng)

        --print("Approved By Queen JIAFEI 100%")

    end

    local function calcRagDamage(rag, di, take)

        --if not cv_kd_enabled:GetBool() then return end

        --do return end

        ---@type Entity
        local ctrl = rag.Savee_AdvRagKnockdown_Controller
        if not IsValid(ctrl) then return end
        --print(di, rag, ctrl.DI_MarkedAsTaken[di])

        --print(di)

        if not take or not IsValid(ctrl) or ctrl:IsMarkedForDeletion() or ctrl.DI_MarkedAsTaken[di] then
            return
        end
        --if ctrl.DI_MarkedAsTaken[di] then return end
        
        if not rag:IsRagdoll() then
            rag = IsValid(ctrl) and ctrl:GetRagdoll()
            --if IsValid(rag) then rag:TakePhysicsDamage(di) end
            ctrl:DoBrainDamages(di)
            return
        end

        --error("RAT!")
        --print(di)
        --local count = table.Count(ctrl.DI_MarkedAsTaken)
        --if count >= 100 then error("FUCK") end

        local own = ctrl:GetOwner()
        if not IsValid(own) or rag == own or own:Health() <= 0 then return end
        --if own:IsFlagSet(FL_KILLME) or own:IsFlagSet(FL_TRANSRAGDOLL) then return end

        local ct = CurTime()

        local dmg = di:GetDamage()
        local atk = di:GetAttacker()

        local wep = di:GetInflictor() or atk:GetActiveWeapon()

        if (atk == own or atk == rag) and own:IsNPC() and IsValid(wep) and wep:GetClass() == "weapon_stunstick" then
            --di:SetDamage(0)
            --print("HYW")
            return
        end
        --print("HYW2")

        local dmgPos = di:GetDamagePosition()

        local tr = util.TraceHull({
            start = dmgPos,
            endpos = dmgPos,
            whitelist = true,
            filter = {rag},
            getRaw = true,
            mask = MASK_ALL,
            mins = Vector(-2, -2, -2),
            maxs = Vector(2, 2, 2),
        })
        local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
        local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]

        -- ToDo: 伤害计算优化
        --print(atk:IsWorld())
        --print(atk, (atk:IsWorld() or (atk:CreatedByMap() and atk:GetMoveType() ~= MOVETYPE_VPHYSICS) or atk:IsRagdoll()) and (di:IsDamageType(DMG_CRUSH) or di:IsDamageType(DMG_FALL)))
        if atk:IsWorld() or (IsValid(atk) and (atk:GetSolid() == SOLID_VPHYSICS or atk:IsRagdoll() or atk:CreatedByMap())) then
            return
            --[[local pObj = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(nearestBone(rag, di:GetDamagePosition()))) or rag:GetPhysicsObject()

            local vel = rag:GetVelocity()
            local tr = util.TraceEntityHull({
                start = rag:GetPos(), 
                endpos = rag:GetPos() - Vector(0, 0, 15),
                filter = {rag, own}
            }, rag)

            if IsValid(tr.Entity) then vel = vel - tr.Entity:GetVelocity() end

            local spdMul = (vel:Length() - 450) / 500 * Lerp((vel.z - 200) / 400, 0.9, 1.5)
            --print(spdMul)
            local finalDmg = (atk == rag or CurTime() <= ctrl.PreventPhysAttackTill) and 0 or math.max(dmg / (rag:GetPhysicsObjectCount() * Lerp(spdMul, 1, 0)) - pObj:GetMass() * Lerp(spdMul, 1, 0), 0)

            if ctrl.RagPhysDmgTakenCount >= 5 then
                finalDmg = finalDmg / 5
            end

            local hgMul = hitGroupPhysicsDmgMuls[hitGroup or 0]
            --local dtMul = dmgTypeMuls[di:GetDamageType()]

            finalDmg = finalDmg * (hgMul or 1) --* (dtMul and dtMul[2] or 1)

            local numpObjs = rag:GetPhysicsObjectCount()
            -- Breen.mdl
            local pObjReduce = math.max(1, numpObjs - 14)
            
            finalDmg = finalDmg / pObjReduce

            di:SetDamage(finalDmg)
            if finalDmg > 0 then
                ctrl.RagPhysDmgTakenCount = math.min(8, ctrl.RagPhysDmgTakenCount + 1)
            end]]
        else
            hook.Run(own:IsPlayer() and "ScalePlayerDamage" or "ScaleNPCDamage", own, hitGroup, di)
        end
        --print(di:GetDamage())
        --if not IsValid(own) then return end
        --[[local tbl = {}
        for _, func in ipairs(infos) do
            --print(func, di["Get" .. func](di))
            tbl[func] = di["Get" .. func](di)
        end

        -- 参见funchooks(修改Trace的那些)
        -- 这个是子弹适配, Trace的是给像Apex Hands SWEP这样的玩意准备的
        -- 撬棍会同时触发两个条件, 所以要修复
        print("对Rag的Own造成伤害: ", rag, own, di)
        ctrl.DI_GoingToTake[#ctrl.DI_GoingToTake + 1] = tbl
        ctrl.DI_MarkedAsTaken[di] = true]]
    

        ctrl:DoBrainDamages(di)
        ctrl.DI_MarkedAsTaken[di] = true
        own:TakeDamageInfo(di, true)

        --[[if di:GetDamage() >= own:Health() then
            --ctrl:Remove()
            own:SetParent(NULL)
        end]]

    end

    local blMdlCache = {}

    local wlMoveTypes = {
        [MOVETYPE_CUSTOM] = true,
        [MOVETYPE_STEP] = true,
        [MOVETYPE_LADDER] = true,
        [MOVETYPE_ISOMETRIC] = true,
        [MOVETYPE_WALK] = true,
    }

    local function doKnockdownDetection(ent, di, take)

        if not cv_kd_enabled:GetBool() then return end

        --print(take)
        --print(take)
        if not take or not ent:LookupBone("ValveBiped.Bip01_Pelvis") then return end

        --if ent:IsPlayer() and ent:Health() > 35 then return end
        --if ent:IsPlayer() then return end

        if not entTypeCheck(ent) then return end

        
        local dmg = di:GetDamage()
        --print(ent:Health())
        if dmg <= 10 and di:GetDamageForce():Length() < 2500 then return end
        if ent:Health() <= 0 then return end
        --if dmg >= ent:Health() or ent:Health() <= 0 then return end
        --print("我要被踹翻了Help: ", ent, di)

        local ctrl = getController(ent)
        if IsValid(ctrl) then
            ctrl.GettingUp = false
            return
        end
    
        if not ent:LookupBone("ValveBiped.Bip01_L_Hand") or not ent:LookupBone("ValveBiped.Bip01_R_Hand") then return end 
        --if not then return end
        local mdl = ent:GetModel()
        if blMdlCache[mdl] then 
            return
        elseif not file.Exists(string.sub(mdl, 1, -4) .. "phy", "GAME") then -- 没有物理文件击倒个瘠薄
            blMdlCache[mdl] = true
            return
        end

        --print("我真的要被踹翻了Help: ", ent, di)

        

        --ent:SetVelocity(di:GetDamageForce())
        --doKnockdown(ent, di)

        --do return end

        doKnockdown(ent, di)

    end
    
    Savee_AdvRagKnockdown_DMGKnockdown = doKnockdownDetection
    Savee_AdvRagKnockdown_DoRagDamage = calcRagDamage
    Savee_AdvRagKnockdown_DoKnockdown = doKnockdown

    --[[concommand.Add(cvPrefix .. "knockdowntest", function()
        doKnockdown(Entity(1):GetEyeTrace().Entity)
    end)

    concommand.Add(cvPrefix .. "test", function(p)
    
        local rag = p:GetEyeTrace().Entity

        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local pobj = rag:GetPhysicsObjectNum(i)
            pobj:SetDragCoefficient(10000)
            pobj:SetAngleDragCoefficient(10000)
            pobj:SetInertia(Vector())
        end
    
    end) ]]
    --[[net.Receive("Savee_AdvRagKnockdown_UpdateRagLimbs", function(len, p)

        local ctrl = p.Savee_AdvRagKnockdown_Controller
        if not IsValid(ctrl) then return end

        local limb = net.ReadUInt(BITCOUNT_LIMBINFO)
        local pos = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        local ang = Angle(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())

        local tbl = ctrl.LimbPos[SAVEE_ADVRAGKNOCKDOWN_LIMBS[limb]
        if not tbl then
            ctrl.LimbPos[SAVEE_ADVRAGKNOCKDOWN_LIMBS[limb] ] = {pos, ang}
        else
            tbl[1] = pos
            tbl[2] = ang
        end

    
    end)]]
    ---@diagnostic disable-next-line: gmod-net-read-write-order-mismatch
    net.Receive("Savee_AdvRagKnockdown_OperationMsg", function(len, p)

        local type = net.ReadUInt(BITCOUNT_OPERATIONINFO)

        ---@type Entity
        local ctrl = p.Savee_AdvRagKnockdown_Controller
        if type == 0 then
            if IsValid(ctrl) then ctrl.GettingUp = false return end
            doKnockdown(p)
            -- 击倒我
        elseif IsValid(ctrl) then
            if type == 1 then
                local n = net.ReadUInt(2)
                --print(n == 2 and not ctrl:GetAimingWeapon())
                ctrl:SetAimingWeapon(n == 2 and not ctrl:GetAimingWeapon() or n ~= 2 and tobool(n))
            else
                local n = net.ReadUInt(2)
                ctrl.LowPose = (n ~= 2 and tobool(n) or not ctrl.LowPose)
            end
        end
        --if not IsValid(ctrl) then return end
    
    end)
    net.Receive("Savee_AdvRagKnockdown_MouseMoveMsg", function(len, p)

        local ctrl = getController(p)
        if not IsValid(ctrl) then return end

        local consc = ctrl:GetConsciousness()

        local oldAng = ctrl:GetAimEyeAngles()
        local x, y = net.ReadFloat(), net.ReadFloat()
        local deltaAng = Angle(y, x) * tickInterval

        local conscLerp = math.ease.OutQuint(consc / 100)

        -- 在Z-City里吸氰化物吸的
        oldAng:RotateAroundAxis(oldAng:Right(), -deltaAng.p * conscLerp)
        oldAng:RotateAroundAxis(oldAng:Up(), -deltaAng.y * conscLerp)

        --newAng:Normalize()
        ctrl:SetAimEyeAngles(oldAng)
    
    end)

    local replaceACTs = {
        [ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
    }

    funchooks.Add("Player.AnimRestartGesture", "Savee_AdvRagKnockdown_Sync", function(ply, _, act, autokill, ...)
    
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, _, act, autokill, ...) end
        act = ply:TranslateWeaponActivity(act)
        act = replaceACTs[act] or act
        ctrl.FakePlyModel:RestartGesture(act, true, autokill)

        return __undetoured(ply, _, act, autokill, ...)
    
    end)
    --[[funchooks.Add("Entity.DispatchTraceAttack", "Savee_AdvRagKnockdown_BulletStuffs", function(ply, _, traceResult, ...)
    
        local ctrl = getController(ply)
        if true or not IsValid(ctrl) then return __undetoured(ply, _, traceResult, ...) end
        print("IShoot")

        return __undetoured(ply, _, traceResult, ...)
    
    end)]]
    --[[funchooks.Add("Entity.SetModel", "Savee_AdvRagKnockdown_Sync", function(ent, ...)
    
        local ctrl = getController(ent)
        if IsValid(ctrl) and not ent:IsRagdoll() then ctrl:Remove() end

        return __undetoured(ent, ...)
    
    end)]]

    --[[local dis = 0

    funchooks.Add("Entity.TakeDamageInfo", "Savee_AdvRagKnockdown_Debugstuffs", function(ply, di, ...)

        dis = dis + 1
        if dis > 128 then error("操你妈 外乡人", 2) return end

        return __undetoured(ply, di, ...)
    
    end)]]

    -- 优化(真的吗?)

    --[[funchooks.AddPost("Player.CreateRagdoll", "Savee_AdvRagKnockdown_InheritRagVel", function(ply, ...)
    
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, ...) end
        local rag = ctrl:GetRagdoll()
        if not IsValid(rag) then return __undetoured(ply, ...) end

        local deadRag = ply:GetRagdollEntity()
        for i = 0, deadRag:GetPhysicsObjectCount() - 1 do
            local pObj1, pObj2 = deadRag:GetPhysicsObjectNum(i), rag:GetPhysicsObjectNum(i)
            if not IsValid(pObj1) or not IsValid(pObj2) then continue end
            pObj1:SetPos(pObj2:GetPos())
            pObj1:SetAngles(pObj2:GetAngles())
            pObj1:SetVelocity(pObj2:GetVelocity())
            --print(1)
        end
        return __undetoured(ply, ...)
    
    end)]]

    -- @EzBodyDamage
    funchooks.Add("Entity.TakeDamageInfo", "Savee_AdvRagKnockdown_DmgModSupport", function(ent, di, raw, ...)
    
        --local ctrl = getController(ent)
        local dmg = di:GetDamage()
        if raw or not cv_kd_damagecalc_usetakedamage:GetBool() then return __undetoured(ent, di, raw, ...) end
        --print(di)
        if ent:IsRagdoll() then
            calcRagDamage(ent, di, dmg > 0)
        else
            doKnockdownDetection(ent, di, dmg > 0)
        end
        --print(ent, dmg)

        return __undetoured(ent, di, raw, ...)
    
    end)
    funchooks.Add("Entity.DispatchTraceAttack", "Savee_AdvRagKnockdown_DmgModSupport", function(atk, di, res, raw, ...)
    
        --local ctrl = getController(ent)
        local ent = res.Entity
        local dmg = di:GetDamage()
        if raw or not IsValid(ent) or not cv_kd_damagecalc_usetakedamage:GetBool() then return __undetoured(atk, di, res, raw, ...) end
        --print(di)
        if ent:IsRagdoll() then
            calcRagDamage(ent, di, dmg > 0)
        else
            doKnockdownDetection(ent, di, dmg > 0)
        end

        return __undetoured(atk, di, res, raw, ...)
    
    end)
    funchooks.Add("Entity.TakeDamage", "Savee_AdvRagKnockdown_DmgModSupport", function(ent, dmg, atk, inf, raw, ...)
        --local ctrl = getController(ent)
        if raw or not cv_kd_damagecalc_usetakedamage:GetBool() then return __undetoured(ent, dmg, atk, inf, raw, ...) end

        local di = DamageInfo()
        di:SetDamage(dmg)
        di:SetDamageType(DMG_GENERIC)
        if IsValid(atk) then di:SetAttacker(atk) end
        if IsValid(inf) then di:SetInflictor(inf) end
        if ent:IsRagdoll() then
            calcRagDamage(ent, di, dmg > 0)
        else
            doKnockdownDetection(ent, di, dmg > 0)
        end

        return __undetoured(ent, dmg, atk, inf, raw, ...)
    
    end)

    --local ent = ents.Create("npc_combine_s")
    --ent:Spawn()
    --doKnockdown(ent)

    --[[hook.Add("OnEntityCreated", "Savee_AdvRagKnockdown_DONTFUCKMYGAME", function(ent)
        timer.Simple(tickInterval * 5, function()
            if not IsValid(ent) then return end
            ent.Savee_AdvRagKnockdown_CanBeKnockdowned = true
        end)
    end)]]
    
    hook.Add("PostCleanupMap", "Savee_AdvRagKnockdown_ResetRagdoll", function()
    
        for _, ent in pairs(ents.FindByClass("ent_savee_advragknockdown_ctrl")) do
            if not IsValid(ent) or ent:IsMarkedForDeletion() then return end
            
            local own = ent:GetOwner()
            local rag = ent:GetRagdoll()
            if not IsValid(rag) or not IsValid(own) or not own:IsPlayer() or not own:Alive() then ent:RemoveSelf() continue end

            local angMax = Angle(65, 80, 80)
            replaceRagconstraint(rag, "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm", -angMax, angMax, 0)
            replaceRagconstraint(rag, "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm", -angMax, angMax, 0)
            
        end
    
    end)

    hook.Add("CreateEntityRagdoll", "Savee_AdvRagKnockdown_InheritRagVel", function(ent, dRag, fucked)
        --print(dRag)
        ---@type Entity
        local ctrl = ent.Savee_AdvRagKnockdown_Controller
        if fucked or not IsValid(ctrl) or dRag:IsMarkedForDeletion() then return end
        --do dRag:Remove() return end

        --ent:SetParent(nil)

        --print("ent有点死了: ", ent, dRag)

        --print(ent)
    
        ---@type Entity
        local rag = ctrl:GetRagdoll()

        --print(1)
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local pObj = dRag:GetPhysicsObjectNum(i)
            if not IsValid(pObj) then continue end
            pObj:Wake()
            pObj:SetVelocity(rag:GetPhysicsObjectNum(i):GetVelocity())
        end

    end)
    hook.Add("CanPlayerEnterVehicle", "Savee_AdvRagKnockdown_NoVehicle", function(ply)
        --print(dRag)
        ---@type Entity
        local ctrl = getController(ply)
        if IsValid(ctrl) then return false end
        

    end)

    hook.Add("SetupPlayerVisibility", "Savee_AdvRagKnockdown_PVS", function(ply, ve)
        if IsValid(ve) and ve ~= ply then return end
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return end
        local rag = ctrl:GetRagdoll()

        AddOriginToPVS(ply:EyePos())
    end)

    hook.Add("PostEntityTakeDamage", "Savee_AdvRagKnockdown_RagDamage", function(rag, di, take)

        if not cv_kd_enabled:GetBool() or cv_kd_damagecalc_usetakedamage:GetBool() then return end
        --print("IC2")
    
        calcRagDamage(rag, di, take)
    
    end)

    hook.Add("PostEntityTakeDamage", "Savee_AdvRagKnockdown_Knockdown", function(ent, di, take)

        if not cv_kd_enabled:GetBool() then return end
        if cv_kd_damagecalc_usetakedamage:GetBool() then return end

        doKnockdownDetection(ent, di, take)

    end)

    local blackListedInputs_NonAiming = {
        IN_ATTACK2,
        IN_RELOAD,
    }
    local blackListedInputs = {
        IN_SPEED,
    }
    local blackListedHTs = {
        ["pistol"] = true,
        ["revolver"] = true,
        ["ar2"] = true,
        ["smg1"] = true,
        ["rpg"] = true,
        ["crossbow"] = true,
        ["shotgun"] = true,
        ["duel"] = true,
    }
    local meleeHTs = {
        ["melee"] = true,
        ["melee2"] = true,
        ["fists"] = true,
        ["knife"] = true,
    }

    hook.Add("StartCommand", "Savee_AdvRagKnockdown_RagView", function(ply, cmd)
        ---@type Entity
        local ctrl = ply.Savee_AdvRagKnockdown_Controller
        if not IsValid(ctrl) then return end

        local stamina = ctrl:GetStamina()
        local consc = ctrl:GetConsciousness()

        if consc < 15 then cmd:ClearButtons() end

        --cmd:RemoveKey()
        --print(cmd:GetViewAngles())
        --local _, angDelta = WorldToLocal(vector_origin, cmd:GetViewAngles(), vector_origin, ply:EyeAngles())

        for key, stat in pairs(ctrl.KeyInputs) do
            if not stat or cmd:KeyDown(key) then continue end
            ctrl.KeyInputs[key] = nil
        end

        --print(ctrl.AimEyeAngles)
        --print(angDelta)

        local wep = ply:GetActiveWeapon()
        local aiming = ctrl:GetAimingWeapon()

        for _, key in ipairs(blackListedInputs) do
            if not cmd:KeyDown(key) then continue end
            ctrl:AddKeyInput(key)
            cmd:RemoveKey(key)
        end

        if (not aiming or consc < 55) and IsValid(wep) then
            for _, key in ipairs(blackListedInputs_NonAiming) do
                if not cmd:KeyDown(key) then continue end
                ctrl:AddKeyInput(key)
                cmd:RemoveKey(key)
            end
            
            local ht = wep:GetHoldType()
            if cmd:KeyDown(IN_ATTACK) and meleeHTs[ht] or wep:Clip1() == 0 and blackListedHTs[ht] then
                ctrl:AddKeyInput(IN_ATTACK)
                cmd:RemoveKey(IN_ATTACK)
            end
        elseif ctrl:GetLArmDelta() > 0.3 and cmd:KeyDown(IN_RELOAD) then
            cmd:RemoveKey(IN_RELOAD)
        end
    
    end)
    --[[hook.Add("OnNPCKilled", "Savee_AdvRagKnockdown_SBBugs", function(npc)
        do return end
        ---@type Entity
        local ctrl = npc.Savee_AdvRagKnockdown_Controller
        if not IsValid(ctrl) then return end
        local rag = ctrl:GetRagdoll()
        if not IsValid(rag) then return end

        npc:SetParent(nil)
        npc:SetPos(rag:GetPos())
        npc:RemoveEffects(EF_BONEMERGE)
    
    end)]]

    --[[funchooks.Add("_G.SetPhysConstraintSystem", "Savee_AdvRagKnockdown_Test", function(sys, ...)
        --print(sys)
        return __undetoured(sys, ...)
    end)]]

else

    --local cv_userenderview = CreateClientConVar(cvPrefix .. "cl_userenderview", 1, true, true, "使用RenderView, 可能会导致性能问题, 但应该可以解决不正确的Clipping", 0, 1)

    local function sendAimingMsg(state)
        if not cv_kd_enabled:GetBool() then return end
        net.Start("Savee_AdvRagKnockdown_OperationMsg", true)
        net.WriteUInt(1, BITCOUNT_OPERATIONINFO)
        net.WriteUInt(state ~= nil and tonumber(state) or 2, 2)
        net.SendToServer()
    end
    local function sendLowPoseMsg(state)
        if not cv_kd_enabled:GetBool() then return end
        net.Start("Savee_AdvRagKnockdown_OperationMsg", true)
        net.WriteUInt(2, BITCOUNT_OPERATIONINFO)
        net.WriteUInt(state ~= nil and tonumber(state) or 2, 2)
        net.SendToServer()
    end

    concommand.Add(cvPrefix .. "doknockdown", function()
        if not cv_kd_enabled:GetBool() then return end
        net.Start("Savee_AdvRagKnockdown_OperationMsg", true)
        net.WriteUInt(0, BITCOUNT_OPERATIONINFO)
        net.SendToServer()
    end)

    concommand.Add(cvPrefix .. "toggleaimweapon", function()
        sendAimingMsg()
    end)
    concommand.Add("+advragknockdown_aimweapon", function()
        sendAimingMsg(true)
    end)
    concommand.Add("-advragknockdown_aimweapon", function()
        sendAimingMsg(false)
    end)
    concommand.Add(cvPrefix .. "toggleaimlowpose", function()
        sendLowPoseMsg()
    end)
    concommand.Add("+advragknockdown_aimlowpose", function()
        sendLowPoseMsg(true)
    end)
    concommand.Add("-advragknockdown_aimlowpose", function()
        sendLowPoseMsg(false)
    end)

    hook.Add("CreateClientsideRagdoll", "Savee_AdvRagKnockdown_RagSync", function(ply, deadRag)
        --print(deadRag)
        --ply:SetParent(nil)
        --ply:SetPos(ply:GetPos())
        --print(ply:GetParent())
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return end
        --print(ply)
        --deadRag:SetPos(ply:GetPos())
        
        local rag = ctrl:GetRagdoll()
        deadRag:SetPos(rag:GetPos())

        for i = 0, deadRag:GetPhysicsObjectCount() - 1 do
            local pObj= deadRag:GetPhysicsObjectNum(i)
            local pos, ang = rag:GetBonePosition(deadRag:TranslatePhysBoneToBone(i))
            --print(deadRag:TranslatePhysBoneToBone(i), pos, rag)
            if not IsValid(pObj) or not pos then continue end
            pObj:SetPos(pos)
            pObj:SetAngles(ang)
            --pObj:SetVelocity(pObj2:GetVelocity())
        end
        --print(deadRag:GetPhysicsObjectNum(1))
    end)

    local blackListedHTs = {
        ["pistol"] = true,
        ["revolver"] = true,
        ["ar2"] = true,
        ["smg1"] = true,
        ["rpg"] = true,
        ["crossbow"] = true,
        ["shotgun"] = true,
        ["duel"] = true,
    }
    local meleeHTs = {
        ["melee"] = true,
        ["melee2"] = true,
        ["fists"] = true,
        ["knife"] = true,
    }

    hook.Add("InputMouseApply", "Savee_AdvRagKnockdown_SendMoveMsg", function(cmd, x, y)
        --print(cmd:GetMouseY(), y)
        local ctrl = getController(LocalPlayer())
        if not IsValid(ctrl) or (x == 0 and y == 0) then return end
        net.Start("Savee_AdvRagKnockdown_MouseMoveMsg", true)
        net.WriteFloat(x)
        net.WriteFloat(y)
        net.SendToServer()
    end)

    hook.Add("StartCommand", "Savee_AdvRagKnockdown_RagOperation", function(ply, cmd)
        ---@type Entity
        local ctrl = getController(ply)
        if not IsValid(ctrl) then return end
        local aimingBind = input.LookupBinding("+advragknockdown_aimweapon") or input.LookupBinding(cvPrefix .. "toggleaimweapon")
        if not aimingBind then
            --print(1)
            --print(cmd:KeyDown(IN_USE))
            sendAimingMsg(cmd:KeyDown(IN_USE) and 1 or 0)
        end

        --print(cmd:GetMouseX())

        local wep = ply:GetActiveWeapon()
        if not ctrl.GetAimingWeapon then return end
        local aiming = ctrl:GetAimingWeapon()

        if not aiming and IsValid(wep) then
            if cmd:KeyDown(IN_RELOAD) then
                ctrl:AddKeyInput(IN_RELOAD)
                cmd:RemoveKey(IN_RELOAD)
            end
            
            local ht = wep:GetHoldType()
            if cmd:KeyDown(IN_ATTACK) and meleeHTs[ht] or wep:Clip1() == 0 and blackListedHTs[ht] then
                ctrl:AddKeyInput(IN_ATTACK)
                cmd:RemoveKey(IN_ATTACK)
            end
        elseif ctrl:GetLArmDelta() > 0.3 and cmd:KeyDown(IN_RELOAD) then
            cmd:RemoveKey(IN_RELOAD)
        end

    
    end)

    local function returnCheck(self)
        return not IsValid(self) or (not self.GetRagdoll or not IsValid(self:GetRagdoll()))
    end

    hook.Add("CalcView", "Savee_AdvRagKnockdown_CTRLHook", function(ply, pos, ang, fov)
        local self = getController(LocalPlayer():GetViewEntity())
        if returnCheck(self) then return end
        return self:CalcView(ply, pos, ang, fov)
    
    end)
    hook.Add("CalcViewModelView", "Savee_AdvRagKnockdown_CTRLHook", function(...)
        local self = getController(LocalPlayer():GetViewEntity())
        if returnCheck(self) then return end
        return self:CalcViewModelView(...)
    
    end)
    hook.Add("PreDrawPlayerHands", "Savee_AdvRagKnockdown_CTRLHook", function(...)
        local self = getController(LocalPlayer():GetViewEntity())
        if returnCheck(self) then return end
        return self:PreDrawPlayerHands(...)
    
    end)

    --[[hook.Add("RenderScene", "Savee_AdvRagKnockdown_AltView", function(pos, ang, fov)
        local lp = LocalPlayer()
        if not IsValid(lp) or not cv_userenderview:GetBool() then return end
        lp = lp:GetViewEntity()

        local scrW, scrH = ScrW(), ScrH()

        --lp:EyePos()

        local ctrl = getController(lp)
        if not IsValid(ctrl) then return end
        local rag = ctrl:GetRagdoll()
        local eyeatt = rag:LookupAttachment("eyes")
        local eyepos = lp:EyePos()
        local eyeang = lp:EyeAngles()
        if eyeatt ~= 0 then
            eyepos = rag:GetAttachment(eyeatt).Pos
            eyeang = rag:GetAttachment(eyeatt).Ang        
        end

        render.RenderView({
            origin = eyepos,
            angles = ang,
            x = 0, y = 0,
            w = scrW, h = scrH,
            drawhud = true,
            drawmonitors = true,
            dopostprocess = true,
        })
        --render.RenderHUD(0, 0, scrW, scrH)

        return true

    end)]]

    -- 给"健康系统"的显示, 毕竟这玩意不是ZCity所以东西都往简单了来(其实和原版没太大关系, 除了体力这个东西)
    local stamina, consc = 100, 100

    hook.Add("RenderScreenspaceEffects", "Savee_AdvRagKnockdown_CTRLHook", function(...)
        local self = getController(LocalPlayer():GetViewEntity())
        local isvalid = not returnCheck(self)
        --print(isvalid, getController(LocalPlayer():GetViewEntity()))
        stamina = Lerp(0.1, stamina, isvalid and self:GetStamina() or 100)
        consc = Lerp(0.1, consc, isvalid and self:GetConsciousness() or 100)

        local staminaLerp = math.ease.InOutQuad(stamina / 100)
        local conscLerp = math.ease.OutQuint(consc / 100)

        local sharpen = 0
        local toyTown = 0

        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }

        --print(staminaLerp)


        tab["$pp_colour_brightness"] = tab["$pp_colour_brightness"] + Lerp(staminaLerp, -0.2, 0)
        tab["$pp_colour_contrast"] = tab["$pp_colour_contrast"] + Lerp(staminaLerp, -0.3, 0)
        tab["$pp_colour_colour"] = tab["$pp_colour_colour"] + Lerp(staminaLerp, -0.2, 0)

        tab["$pp_colour_brightness"] = tab["$pp_colour_brightness"] + Lerp(conscLerp, -0.8, 0)
        tab["$pp_colour_contrast"] = tab["$pp_colour_contrast"] + Lerp(conscLerp, -0.5, 0)
        tab["$pp_colour_colour"] = tab["$pp_colour_colour"] + Lerp(conscLerp, -0.5, 0)

        sharpen = sharpen + Lerp((staminaLerp - 0.2) / 0.8, 1, 0)
        toyTown = toyTown + Lerp((staminaLerp - 0.2) / 0.8, 2, 0)

        DrawColorModify(tab)

        if sharpen > 0.05 then
            DrawSharpen(sharpen, sharpen * 2.5)
        end
        if toyTown > 0.05 then
            DrawToyTown(toyTown, ScrH() / 8 * toyTown)
        end
    
    end)

    -- 兼容

    hook.Add("ARC9_Hook_BlockTPIK", "Savee_AdvRagKnockdown_BlockTPIK", function(wep)
        local own = wep:GetOwner()
        local ent = own:GetNW2Entity("Savee_AdvRagKnockdown_Controller")
        --print(ent)
        if not IsValid(ent) then return end
        if not ent:GetAimingWeapon() or ent:GetLArmDelta() > 0.15 then return true end
    end)

    hook.Add("PreDrawBody", "Savee_AdvRagKnockdown_BlockBody", function()
        if IsValid(getController(LocalPlayer())) then return false end
    end)

end

Savee_AdvRagKnockdown_GetController = getController

--[[local f = file.Open("models/savee/ocs/savee39672/nellie.phy", "r", "GAME")
f:Write("FUCKYOU")
f:Close()]]
