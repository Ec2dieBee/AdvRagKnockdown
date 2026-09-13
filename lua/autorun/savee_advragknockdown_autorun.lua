-- Ciallo
-- 这是一个仿照(和修改)Z-City击倒/布娃娃系统的玩意(但是是TM自己想的, 太痛苦了, 太痛苦了)
-- 但是我不想让这玩意挂上各种License(保留所有权利.jpg)所以代码是自己写的, 痛苦程度参见实体的抓握部分
-- 你知道有好的方法能用但是因为你看了答案所以你不再能使用它aughhhhhhhh
-- 
-- Savee14702 保留一切权利
-- 如果使用/修改该插件的核心部分, 请获得许可并在发布页面的Credits里加上我的名字(也别拿去商用)
-- Savee14702 All Rights Reserved.
-- If used/modified the "core" part of this addon, please ask for my permission and add my name in the "Credits" section(if it has) of your release page(Workshop page I guess)(AND NO COMMERICAL USE!)
-- 
-- 2026/5/17 这一切全他妈关于速度 你想要留下你的名字就必须快点, 是的这都关于名头, 你第一个弄出来这个名头就是你的
-- @RagKnockdown @MPNKnockdown(RagKnockdown的更全的老版本, 支持ClassicKnockdown(ZSKnockdown), 这是我的命名)
-- TODO: SANITY CHECK, 如果有更多需要读CTRL的玩意
-- 
-- 2026/8/7: 观前提醒: 本插件完全抄袭了RagKnockdown, 就连名字也一样


AddCSLuaFile()

-- CVs
local cvPrefix = "savee_advragknockdown_"
local cvTags = {FCVAR_ARCHIVE,FCVAR_REPLICATED}

-- 证明我抄袭了RagKnockdown的有力证据 7.25: 现在没有了 8.7: 你要不看看上面呢
local cv_kd_enabled = CreateConVar(cvPrefix .. "enabled", 1, cvTags, "激活整个插件 *警告! 哪怕这个插件被禁用 某些hook的运算也是会照常运行的!*", 0, 1)
local cv_kd_enabled_ply = CreateConVar(cvPrefix .. "enableply", 1, cvTags, "对玩家启用击倒", 0, 1)
local cv_kd_enabled_npc = CreateConVar(cvPrefix .. "enablenpc", 1, cvTags, "对NPC启用击倒", 0, 1)
--local cv_kd_enabled_nextbot = CreateConVar(cvPrefix .. "enablenextbot", 1, cvTags, "对NextBot启用击倒", 0, 1)

local cv_kd_playdead_enabled = CreateConVar(cvPrefix .. "playdead_enabled", 1, cvTags, "激活假死", 0, 1)
local cv_kd_playdead_enabled_ply = CreateConVar(cvPrefix .. "playdead_enableply", 1, cvTags, "对玩家启用假死", 0, 1)
local cv_kd_playdead_enabled_npc = CreateConVar(cvPrefix .. "playdead_enablenpc", 1, cvTags, "对NPC启用假死", 0, 1)

local cv_kd_knockdown_plyinveh = CreateConVar(cvPrefix .. "knockdown_playerinvehicle", 1, cvTags, "是否击倒在载具内的玩家(如果玩家在车里则试图让他们离开载具, 如果他们能)", 0, 1)

local cv_kd_knockdown_defaultbehaviour = CreateConVar(cvPrefix .. "knockdown_defaultbehaviour", 1, cvTags, "启用默认的击倒检测, 如果你有什么东西对击倒检测做了彻底改变可以关掉", 0, 1)
local cv_kd_knockdown_percentdamage_enabled = CreateConVar(cvPrefix .. "knockdown_percentdamage_enabled", 1, cvTags, "允许在伤害大于玩家最大生命百分比时击倒玩家", 0, 1)
local cv_kd_knockdown_percentdamage = CreateConVar(cvPrefix .. "knockdown_percentdamage", 0.5, cvTags, "击倒玩家所需的伤害百分比, 请注意 如果其它条件满足也是可以击倒的", 0, 1)
local cv_kd_knockdown_mindamage = CreateConVar(cvPrefix .. "knockdown_mindamage", 10, cvTags, "击倒玩家最小所需的伤害, 请注意 如果力度足够也是可以击倒的", 0)
local cv_kd_knockdown_mindamageforce = CreateConVar(cvPrefix .. "knockdown_mindamageforce", 2500, cvTags, "击倒玩家最小所需的伤害力度, 请注意 如果伤害足够也是可以击倒的", 0)
local cv_kd_knockdown_physgun = CreateConVar(cvPrefix .. "knockdown_physicsgun", 0, cvTags, "允许使用物理枪捡起可击倒实体", 0, 1)
local cv_kd_knockdown_gravgun = CreateConVar(cvPrefix .. "knockdown_gravitygun", 0, cvTags, "允许使用重力枪推倒实体", 0, 1)

local cv_kd_damagecalc_usetakedamage = CreateConVar(cvPrefix .. "knockdown_usetakedamage", 0, cvTags, "使用TakeDamageInfo并更进一步修改BulletTable, 可能会出现没受到伤害且力度不够时仍被击倒的情况", 0, 1)

local cv_kd_ctrl_useheadang = CreateConVar(cvPrefix .. "control_useheadangles", 0, cvTags, "在玩家转动视角时使用玩家目前的头部朝向计算, 可能会导致无法舒适翻滚", 0, 1)
local cv_kd_ctrl_luacode_uselocaleyeangles = CreateConVar(cvPrefix .. "control_luacode_uselocaleyeangles", 1, cvTags, "[手感][代码相关] 将要设置的EyeAngles\"局部化\"(经过Roll旋转), 可以解决部分武器包的武器后坐力垂直于地面的问题, 但可能有其它奇怪的现象", 0, 1)
local cv_kd_ctrl_luacode_dontclampeyeang = CreateConVar(cvPrefix .. "control_luacode_dontclampeyeang", 1, cvTags, "[手感] 瞄准时不钳制玩家的视角(roll仍然会被锁住), 对部分eye设置的很史的模型有奇效, 同时在手感上也和ZCity相似", 0, 1)

local cv_kd_perf_luacode_nexttick = CreateConVar(cvPrefix .. "performance_luacode_nexttick", 0.01, cvTags, "[性能][代码相关] 下次统一运行控制器Tick()的时间, 这个值越大布娃娃效果越拉跨(但性能会好点我猜), 不建议大于0.03", 0)
local cv_kd_perf_luacode_ctrlamnt = CreateConVar(cvPrefix .. "performance_luacode_maxprocessedcontroller", 10, cvTags, "[性能][代码相关] 一tick间隔(或者是你设置的tick间隔)处理的控制器数量, 设置为0则无上限", 0)
local cv_kd_perf_luacode_tracelevel = CreateConVar(cvPrefix .. "performance_luacode_tracelevel", 4, cvTags, "[性能][代码相关] 查找Trace的层数, 越高越\"广泛\", 操作涉及到布娃娃的面越广, 但有潜在的性能消耗(低于4的话工具枪无法选择布娃娃)", 0)
local cv_kd_perf_luacode_deltamul = CreateConVar(cvPrefix .. "performance_luacode_deltamul", 1, cvTags, "[性能][代码相关][需重启] ShadowControl运算中delta的乘数, 把它调低对安装了VPhysics-Box3D的人有帮助 不要让它为0, 推荐值为0.5", 0)
--local cv_kd_perf_luacode_usecustomdraw = CreateConVar(cvPrefix .. "performance_luacode_usecustomdraw", 1, cvTags, "[性能][代码相关] TBA", 0, 1)
--local cv_kd_agressivecompability = CreateConVar(cvPrefix .. "agressivecompability", 0, cvTags, "通过覆盖其它钩子", 0)

CreateConVar(cvPrefix .. "rag_minmasslimit", 1, cvTags, "设置布娃娃特定部位的最小重量, 并降低布娃娃其它部位的重量. 对于物理部件特多的布娃娃可能会有Bug, 关掉这个会导致特定模型伸手可以飞天", 0, 1)


CreateConVar(cvPrefix .. "npc_usehook_createentityragdoll", 0, cvTags, "在NPC被击倒时调用CreateEntityRagdoll", 0, 1)
CreateConVar(cvPrefix .. "playdead_npc_usehook_createentityragdoll", 1, cvTags, "在NPC假死时调用CreateEntityRagdoll", 0, 1)
CreateConVar(cvPrefix .. "playdead_npc_usehook_onnpckilled", 1, cvTags, "在NPC假死时调用OnNPCKilled", 0, 1)
CreateConVar(cvPrefix .. "playdead_npc_allydist", 500, cvTags, "假死NPC寻找\"友军\"的距离", 0)
CreateConVar(cvPrefix .. "playdead_npc_allyamnt", 3, cvTags, "假死NPC脱离假死需要\"友军\"的数量", 0)
CreateConVar(cvPrefix .. "playdead_npc_deployattack_timer", 15, cvTags, "假死NPC多长时间不被注视后才脱离假死", 0)
CreateConVar(cvPrefix .. "playdead_npc_soundemitchance", 0.1, cvTags, "假死NPC在通常情况下挨打发出受伤声音的几率", 0, 1)

CreateConVar(cvPrefix .. "statcalc_npc_staminadmgmul", 1, cvTags, "[对NPC] 体力伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_npc_conscdmgmul", 1, cvTags, "[对NPC] 意识伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_ply_staminadmgmul", 1, cvTags, "[对玩家] 体力伤害乘数", 0)
CreateConVar(cvPrefix .. "statcalc_ply_conscdmgmul", 1, cvTags, "[对玩家] 意识伤害乘数", 0)

local clcv_ctrl_nodefkeybind = CreateClientConVar(cvPrefix .. "cl_control_disabledefaultkeybind", "0", true, true, "禁用默认的瞄准方法(按住E瞄准), 可能对某些服务器的自定义按键设置有帮助", 0, 1)
local clcv_ctrl_reversedaiming = CreateClientConVar(cvPrefix .. "cl_control_reversedaiming", "0", true, true, "[仅按住E可用时] 按住E取消瞄准 而不是进行瞄准", 0, 1)
local clcv_ctrl_aim = CreateClientConVar(cvPrefix .. "cl_control_autoaim", "0", true, true, "[仅自定义按键可用时] 击倒时默认开启瞄准(0: 关闭, 1: 仅主动击倒, 2: 任何情况下被击倒(需要服务器打开相关设置!))", 0, 2) -- ToDo: 把2加上
CreateClientConVar(cvPrefix .. "cl_control_altaimkey", "0", true, true, "[仅按住E可用时] 按住[慢走键](默认是LAlt)进行瞄准", 0, 1)
CreateClientConVar(cvPrefix .. "cl_getup_smoothtransitioninterval", "0.15", true, true, "在起身后视角在和老视角和实际视角的过渡时间, 总而言之就是能让起身的视角转换看上去丝滑一点(我相信你不会把它改成1以上的值)", 0)
--CreateClientConVar(cvPrefix .. "cl_contrl_rollspdmul_sprint", "1.5", true, true, "在起身后视角在和老视角和实际视角的过渡时间, 总而言之就是能让起身的视角转换看上去丝滑一点(我相信你不会把它改成1以上的值)", 0)
--CreateClientConVar(cvPrefix .. "cl_contrl_rollspdmul_walk", "0.5", true, true, "在起身后视角在和老视角和实际视角的过渡时间, 总而言之就是能让起身的视角转换看上去丝滑一点(我相信你不会把它改成1以上的值)", 0)

--local clcv_perf_usecalcviewmodelview = CreateClientConVar(cvPrefix .. "cl_performance_luacode_usecalcviewmodelview", "1", true, true, "[绘制][代码相关] 是否使用武器的CalcViewModelView, 可能有神秘小Bug", 0, 1)

local cvVars = {}
local function addCallback(name, type, prefix)
    local cv = GetConVar(cvPrefix .. name)
    local key = (prefix or "") .. name

    cvVars[key] = cv["Get" .. type](cv)
    cvars.AddChangeCallback(cvPrefix .. name, function()
        cvVars[key] = cv["Get" .. type](cv)
    end)
end
addCallback("cl_control_altaimkey", "Bool")
addCallback("control_luacode_uselocaleyeangles", "Bool")
addCallback("cl_getup_smoothtransitioninterval", "Float")
--addCallback("cl_contrl_rollspdmul_sprint", "Float")
--addCallback("cl_contrl_rollspdmul_walk", "Float")


--[[local var_cv_kd_ctrl_luacode_uselocaleyeangles = cv_kd_ctrl_luacode_uselocaleyeangles:GetBool()
cvars.AddChangeCallback(cvPrefix .. "control_luacode_uselocaleyeangles", function()
    var_cv_kd_ctrl_luacode_uselocaleyeangles = cv_kd_ctrl_luacode_uselocaleyeangles:GetBool()
end)]]

--local entMeta = FindMetaTable("Entity")
--local plyMeta = FindMetaTable("Player")
--local npcMeta = FindMetaTable("NPC")

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

-- ToDo: 是否需要将NW换成NW2?

--[[SAVEE_ADVRAGKNOCKDOWN_LIMBS = {
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_R_Hand",
}]]
local BITCOUNT_LIMBINFO = 3
local BITCOUNT_OPERATIONINFO = 2

local vector_origin, angle_zero = Vector(), Angle()

local tickInterval = engine.TickInterval()
local handPosDelta = Vector(16, 0, -4)

local handlingKnockdownedCmd = false

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
    if not IsValid(ent) or ent:IsNextBot() or ent:IsMarkedForDeletion() or ent:Health() <= 0 then return false end
    return (ent:IsPlayer() and cv_kd_enabled_ply:GetBool()) or (ent:IsNPC() and cv_kd_enabled_npc:GetBool())
end
local function getController(ent)
    if not cv_kd_enabled:GetBool() or not IsValid(ent) then return end

    local ctrl = CLIENT and ent:GetNW2Entity("Savee_AdvRagKnockdown_Controller") or ent.Savee_AdvRagKnockdown_Controller
    if not IsValid(ctrl) or ctrl.Removing or not ctrl.GetRagdoll then return end

    local rag = ctrl:GetRagdoll()
    if not IsValid(rag) or rag:IsMarkedForDeletion() then return end

    return ctrl
end

local mtx = Matrix()
local function getBoneMatrixPosAng(rag, name)
    name = rag:LookupBone(name)
    if not name then return vector_origin, angle_zero end

    rag:CopyBoneMatrix(name, mtx)
    if not mtx then return vector_origin, angle_zero end

    return mtx:GetTranslation(), mtx:GetAngles()
end

local function runThatHook(name, ...)
    local stuffs = {hook.Run(name, ...)}

    return #stuffs > 0, unpack(stuffs)
end

-- debug.lua
local traceLvl = cv_kd_perf_luacode_tracelevel:GetInt()
cvars.AddChangeCallback(cvPrefix .. "performance_luacode_tracelevel", function()
    traceLvl = cv_kd_perf_luacode_tracelevel:GetInt()
end)
local function debugTrace()

	local level = 1

	local str = ""

	while level <= traceLvl do

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
    "wire_",
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

                if not isentity(e) or not IsValid(e) then continue end
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

            local checked = {}

            local newfunc = function(ent)
                local ctrl = getController(ent)
                if not IsValid(ctrl) then return filter(ent) end
                if checked[ctrl] ~= nil then return checked[ctrl] end
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
                local result
                if rHD <= 0.15 and (aimTr.Entity ~= rag or whitelistedBones[rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone) or -1)]) then
                    result = filter(own) and filter(rag)
                else
                    result = filter(own)
                end

                checked[ctrl] = result
                return result
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

local setItOnMe = {
    "Material",
    "Skin",
    "Color",
    "Model",
    "RenderMode",
    "RenderFX",
    "Bodygroup",
    "BodyGroups",
    "Velocity",
    "AbsVelocity",
    "LocalVelocity",
    "FlexScale",
    "FlexWeight",
}

for _, str in ipairs(setItOnMe) do

    -- 反Stack Overflow
    -- Clone Drone In the
    local dangerzone
    local function override(ent, ...)
        local ctrl = getController(ent)
        if dangerzone or not IsValid(ctrl) then return __undetoured(ent, ...) end
        
        dangerzone = true

        if ent:IsRagdoll() and ent.Initialized then
            local own = ctrl:GetOwner()
            own["Set" .. str](own, ...)
            dangerzone = false
            return
        end
        local rag = ctrl:GetRagdoll()
        
        rag["Set" .. str](rag, ...)

        dangerzone = false

        return __undetoured(ent, ...)
    end

    funchooks.Add("Entity.Set" .. str, "Savee_AdvRagKnockdown_Syncing", override)

end

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
    local mtx = rag:GetBoneMatrix(rag:LookupBone("ValveBiped.Bip01_R_Hand") or rag:LookupBone("ValveBiped.Bip01_R_Forearm"))
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

funchooks.Add("Entity.SetOwner", "Savee_AdvRagKnockdown_AntiBadCollision", function(ent, own, raw, ...)

    if raw or not entTypeCheck(own) then return __undetoured(ent, own, raw, ...) end
    local ctrl = getController(own)

    if not IsValid(ctrl) then return __undetoured(ent, own, raw, ...) end
    local rag = ctrl:GetRagdoll()

    ctrl.OwnerModifiedEnts[ent] = true

    return __undetoured(ent, rag, raw, ...)
   
end)

funchooks.AddPost("Entity.GetOwner", "Savee_AdvRagKnockdown_AntiBadCollision", function(ent, inputs, own, ...)

    local raw = inputs[1]
    if raw or not entTypeCheck(own) then return __undetoured(ent, inputs, own, ...) end

    local ctrl = getController(own)
    if not IsValid(ctrl) or not ctrl.OwnerModifiedEnts[ent] then return __undetoured(ent, inputs, own, ...) end

    return __undetoured(ent, inputs, __raw(ctrl), ...)
   
end)

local INE = math.IsNearlyEqual

local lastSysTime_EyePos = -1
funchooks.Add("Entity.EyePos", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
    local sysTime = SysTime()
    
    local cache = ctrl.VarCaches["EyePos"] 
    if lastSysTime_EyePos >= sysTime and cache then 
        return cache
    end
    lastSysTime_EyePos = sysTime + tickInterval

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

local lastSysTime_EyeAngles = -1

funchooks.Add("Entity.EyeAngles", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, raw, ...) end

    local ctrl = getController(ply)
    local sysTime = SysTime()

    -- 神秘多人游戏bug
    if not IsValid(ctrl) or not ctrl.GetAimEyeAngles then return __undetoured(ply, raw, ...) end

    --print(sysTime - lastSysTime_EyeAngles)
    local cache = ctrl.VarCaches["EyeAng"]
    if lastSysTime_EyeAngles >= sysTime and cache then 
        return Angle(cache.p, cache.y, cache.r)
    end


    lastSysTime_EyeAngles = sysTime + tickInterval * 0.01

    local ea = ctrl:GetAimEyeAngles()
    ea.z = 0
    ea:Normalize()

    local final = SERVER and ea or LerpAngle(FrameTime(), ctrl.LastEyeAng or ea, ea)
    --print(final)
    ctrl.VarCaches["EyeAng"] = final

    return final
   

end)

-- AI给我提了个醒(是的有人很自恋)
-- 这玩意得留着, 因为大多数SetEyeAngles都是在强健你EyeAngles的Roll(到0)
funchooks.Add("Player.SetEyeAngles", "Savee_AdvRagKnockdown_Sync", function(ply, ang, raw, ...)

    --do return __undetoured(ply, ...) end
    --error(1)
    --if SERVER then print(1) end
    if raw or not entTypeCheck(ply) then return __undetoured(ply, ang, raw, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) then return __undetoured(ply, ang, raw, ...) end
    local oldAng = ctrl:GetAimEyeAngles()
    local roll = oldAng.r

    --[[local delta = ang - oldAng
    delta:RotateAroundAxis(oldAng:Forward(), roll)

    ang = oldAng + delta]]

    ang.r = roll

    return __undetoured(ply, ang, raw, ...)
   
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

funchooks.Add("Entity.GetPos", "Savee_AdvRagKnockdown_Sync", function(ent, raw, ...)

    if raw or not entTypeCheck(ent) then return __undetoured(ent, raw, ...) end
    local ctrl = getController(ent)
    if not IsValid(ctrl) then return __undetoured(ent, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local bone = rag:GetPos()

    return bone
   
end)
funchooks.Add("Entity.GetAngles", "Savee_AdvRagKnockdown_Sync", function(ent, raw, ...)

    if raw or not entTypeCheck(ent) then return __undetoured(ent, raw, ...) end
    local ctrl = getController(ent)

    if not IsValid(ctrl) then return __undetoured(ent, raw, ...) end
    local rag = ctrl:GetRagdoll()
    local _, ang = rag:GetBonePosition(0)

    return (ang:Up()):Angle()
   
end)

funchooks.AddPost("Entity.SetPos", "Savee_AdvRagKnockdown_Sync", function(ply, inputs, ...)

    local raw = inputs[2]
    if raw or not entTypeCheck(ply) then return __undetoured(ply, inputs, ...) end

    local ctrl = getController(ply)

    -- 神秘多人游戏bug
    if not IsValid(ctrl) then return __undetoured(ply, inputs, ...) end
    ctrl:CancelGetUp()
    local pos = inputs[1]

    local oldPos = ply:GetPos()
    for _, data in pairs(ctrl.RagPObjs) do
        local pObj = data.pObj
        if not data.physBone or not IsValid(pObj) then continue end
        local wtl = pObj:GetPos() - oldPos

        local oldState = pObj:IsMotionEnabled()

        pObj:EnableMotion(false)
        pObj:SetPos(pos + wtl)
        pObj:EnableMotion(oldState)
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

    local finalAV = CLIENT and ctrl.LastEyeAng or ctrl:GetAimEyeAngles()
    --finalAV.r = 0
    --finalAV:Normalize()
    finalAV = finalAV:Forward()


    local av = raw and __raw(ply, ...) or finalAV --(tr.HitPos - eyepos):GetNormalized()
    --print(rDelta)


    return LerpVector(CLIENT and ctrl.SmoothedRArmDelta or math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av, handang:Forward())
   

end)


--[[funchooks.Add("Player.IsPlayingTaunt", "Savee_AdvRagKnockdown_TauntOverride", function(ply, ...)

    --do return __undetoured(ply, ...) end

    local ctrl = getController(ply)
    if not IsValid(ctrl) or true then return __undetoured(ply, ...) end
    
    -- TODO: 把IN_USE检测换了
    return false
   

end)]]

funchooks.Add("CUserCmd.SetViewAngles", "Savee_AdvRagKnockdown_RecoilCorrection", function(cmd, ang, raw, ...)
    if not raw and handlingKnockdownedCmd then
        local oldAng = cmd:GetViewAngles()
        local roll = oldAng.r

        local delta = ang - oldAng
        oldAng:RotateAroundAxis(oldAng:Right(), -delta.p)
        oldAng:RotateAroundAxis(oldAng:Forward(), delta.y)
        oldAng:RotateAroundAxis(oldAng:Up(), delta.r)

        ang = oldAng
    end
    return __undetoured(cmd, ang, raw, ...)
end)

-- 武器支持
hook.Add("EntityFireBullets", "Savee_AdvRagKnockdown_HitScanMod", function(ent, bullet, fucked)
    --local wep = ent
    if fucked then return end
    if ent:IsWeapon() then ent = ent:GetOwner() end
    
    if SERVER then
        local newbullet = table.Copy(bullet)
        hook.Run("EntityFireBullets", ent, newbullet, true)
        local cb = newbullet.Callback or bullet.Callback
        bullet.Callback = function(attacker, btr, di)
            --BTR!???????

            --btr = table.Copy(btr)

            --print(tr.HitGroup)
            --print(di)
            --tr.HitGroup = 1
            local rag = btr.Entity

            --bullet.Fucked = true
            --print(btr.HitPos)

            local ctrl = getController(rag)
            --print(rag)
            if IsValid(ctrl) and IsValid(rag) and rag:IsRagdoll() then
                local own = ctrl:GetOwner()

                local tr = util.TraceHull({
                    start = btr.HitPos,
                    endpos = btr.HitPos,
                    whitelist = true,
                    filter = rag,
                    getRaw = true,
                    mask = MASK_ALL,
                    mins = Vector(-2, -2, -2),
                    maxs = Vector(2, 2, 2),
                })
                local bone = rag:TranslatePhysBoneToBone(tr.PhysicsBone)
                local hitGroup = rag.Savee_AdvRagKnockdown_HitGroups[bone]
  
                -- 神秘Bug, 我忘记重名的事了
                btr.HitBoxBone = bone
                btr.HitBox = rag.Savee_AdvRagKnockdown_HitBoxes[bone] or btr.HitBox
                btr.HitGroup = hitGroup or btr.HitGroup --own:GetHitBoxHitGroup(rag.Savee_AdvRagKnockdown_HitBoxes[bone], 0)
                btr.Entity = own
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
                if rag:IsRagdoll() then
                    Savee_AdvRagKnockdown_DoRagDamage(rag, di, di:GetDamage() > 0)
                else
                    Savee_AdvRagKnockdown_DMGKnockdown(rag, di, di:GetDamage() > 0)
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

    local wep = bullet.Inflictor or bullet.Attacker

    --print(rHD, bullet.Src, eyePos, shootPos)
    if (IsValid(wep) and not wep:IsScripted() or bullet.Src == shootPos) and rHD <= 0.15 then
        bullet.Src = eyePos
        --print(1)
    elseif rHD > 0.15 and bullet.Src == eyePos then
        bullet.Src = shootPos
    end

    --bullet.Src = eyePos

    local handpos, handang = getBoneMatrixPosAng(rag, "ValveBiped.Bip01_R_Hand")
    handpos, handang = LocalToWorld(handPosDelta, Angle(), handpos, handang)

    --[[local tr = util.TraceLine({
        start = eyepos,
        endpos = eyepos + ctrl:GetAimEyeAngles():Forward() * 65536,
        filter = {ent, rag},
        mask = MASK_SHOT,
    })]]
    --local actualav = (tr.HitPos - shootPos):GetNormalized()
    local av = CLIENT and bullet.Dir or ent:GetAimVector(true)
    -- 神秘Bug修复
    local bDir = (isSP or SERVER) and bullet.Dir or av

    --print(bDir:Angle(), av:Angle(), ent:GetAimVector(true):Angle(), ent:EyeAngles(true))
    local _, dDir = WorldToLocal(vector_origin, bDir:Angle(), vector_origin, av:Angle())

    --print(dDir)
    --bDir = ctrl:GetAimEyeAngles():Forward()
    --bDir:Rotate(dDir)

    local hAngFwd = handang:Forward()
    --hAngFwd:Rotate(Angle(0, 0, 0))
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
    local aimDir = ctrl:GetAimEyeAngles():Forward()
    local aimTr = util.TraceLine({
        start = eyePos + aimDir * 15,
        endpos = eyePos + aimDir * 65536,
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
    --else
        --print(IsValid(bullet.IgnoreEntity), rHD, rag:GetBoneName(rag:TranslatePhysBoneToBone(aimTr.PhysicsBone)), aimTr.Entity ~= rag)
    end

    return true --__undetoured(ent, bullet)

end)

-- 所以你不必要在空中蹲下然后发现自己起不来
-- 就当是在穿墙吧
hook.Add("Move", "Savee_AdvRagKnockdown_RagMoveOverride", function(ply, mv)
    
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

        ply:SetViewPunchAngles(viewPunch, true)
        ply:SetViewPunchVelocity(viewPunchVel, true)

    else
        ply:SetViewPunchAngles(angle_zero)
        ply:SetViewPunchVelocity(angle_zero)
    end
    --print(viewPunch)

    return true

end)

local tickCo = coroutine.create(function()
    while true do
        local time = math.max(tickInterval, cv_kd_perf_luacode_nexttick:GetFloat())
        local isFucked = cv_kd_perf_luacode_ctrlamnt:GetInt() ~= 0
        local amnt = 0

        local ctrls = ents.FindByClass("ent_savee_advragknockdown_ctrl")
        table.sort(ctrls, function(a)
            local own = a:GetOwner()
            if not IsValid(own) then return end

            return a:IsPlayer()
        end)
        
        for _, ent in ipairs(ctrls) do
            if not IsValid(ent) or ent:IsMarkedForDeletion() then continue end
            
            local own = ent:GetOwner()
            if not IsValid(ent:GetRagdoll()) or not IsValid(own) or own:IsMarkedForDeletion() or own:Health() <= 0 then ent:RemoveSelf() continue end

            ent:Tick()
            if own:IsPlayer() then continue end

            amnt = amnt + 1
            if isFucked and amnt >= cv_kd_perf_luacode_ctrlamnt:GetInt() then
                amnt = 0
                coroutine.wait(time)
            end
        end
        coroutine.wait(time)
    end
end)

hook.Add("Tick", "Savee_AdvRagKnockdown_CtrlTick", function()
    if coroutine.status(tickCo) == "suspended" then
        coroutine.resume(tickCo)
    end    
end)

hook.Add("CalcMainActivity", "Savee_AdvRagKnockdown_Correction", function(ply)
    local ctrl = getController(ply)
    if not IsValid(ctrl) then return end

    return ctrl:HasKeyInput(IN_DUCK) and ACT_MP_CROUCH_IDLE or ACT_MP_STAND_IDLE, -1
end)
    
if SERVER then

    --util.AddNetworkString("Savee_AdvRagKnockdown_UpdateRagLimbs")
    util.AddNetworkString("Savee_AdvRagKnockdown_OperationMsg")

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

    local function canPlayDead(ply)

    end

    local function doKnockdown(ply, vec, bone)
        if not cv_kd_enabled:GetBool() then return end
        
        if not entTypeCheck(ply) then return end
        --print("正在击倒: ", ply, vec, bone)

        local oldCtrl = getController(ply)
        if IsValid(oldCtrl) then
            oldCtrl:CancelGetUp()
            --[[for _, data in pairs(oldCtrl.RagPObjs) do
                if not data.physBone then continue end
                local pObj = data.pObj
                if data.MotionDisabledByGetUp then
                    data.MotionDisabledByGetUp = nil
                    pObj:EnableMotion(true)
                end
            end]]

            if ply:IsNPC() then
                oldCtrl:SetCachedVar("NPC_CanGetUpVar", false, math.Rand(3, 7))
            end
        end

        if ply:IsPlayer() and ply:InVehicle() then
            if not cv_kd_knockdown_plyinveh:GetBool() then return end
            local can = hook.Run("CanExitVehicle", ply:GetVehicle(), ply)
            if not can then return end
            ply:ExitVehicle()
        end
        local ctrl = IsValid(oldCtrl) and oldCtrl or ents.Create("ent_savee_advragknockdown_ctrl")
        if not IsValid(oldCtrl) then
            ctrl:SetOwner(ply)
            ctrl:SetPos(ply:GetPos())
            ctrl:Spawn()
            ctrl.PreventPhysAttackTill = CurTime() + 0.05
            -- 防误触
            ctrl.NextGetUp = CurTime() + 0.5
        end
        --do return end
        --ply:SetNW2Entity("Savee_AdvRagKnockdown_Controller", ent)
        local rag = ctrl:GetRagdoll()
        if vec and IsValid(rag) then
            if not isvector(vec) then
                if vec then ctrl.DI_MarkedAsTaken[vec] = true end
                
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

    local mvBlacklist = {
        [MOVETYPE_VPHYSICS] = true,
        [MOVETYPE_FLY] = true,
        [MOVETYPE_FLYGRAVITY] = true,
    }

    local function calcRagDamage(rag, di, take)

        --if not cv_kd_enabled:GetBool() then return end

        --do return end

        ---@type Entity
        local ctrl = getController(rag)
        if not IsValid(ctrl) then return end
        --print(di, rag, ctrl.DI_MarkedAsTaken[di])

        
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
        if not IsValid(own) or rag == own then return end
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
        if atk:IsWorld() or (IsValid(atk) and (atk:GetSolid() == SOLID_VPHYSICS and (atk:IsRagdoll() or atk:CreatedByMap()))) then
            return
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
        local inf = di:GetInflictor()

        if IsValid(inf) and (atk:IsRagdoll() or (inf ~= atk and ((inf:IsNPC() and not mvBlacklist[inf:GetMoveType()]) or inf:IsPlayer() or inf:IsNextBot() or inf:GetClass() == "func_breakable_surf"))) then
            di:SetDamage(math.floor(dmg / 50))
        end

        ctrl:DoBrainDamages(di)
        ctrl.DI_MarkedAsTaken[di] = true
        own:TakeDamageInfo(di, true)

        --print(rag, own, di)

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

        
        local hp = ent:Health()
        if hp <= 0 then return end

        if di then
            local dmg = di:GetDamage()
            local result, should = runThatHook("Savee_AdvRagKnockdown_ShouldKnockdown", ent, di, take)
            if result and not should then return end

            if dmg <= cv_kd_knockdown_mindamage:GetFloat() and di:GetDamageForce():Length() < cv_kd_knockdown_mindamageforce:GetFloat() then return end
        end
            --print(ent:Health())
        --if dmg >= ent:Health() or ent:Health() <= 0 then return end
        --print("我要被踹翻了Help: ", ent, di)

        local ctrl = getController(ent)
        if IsValid(ctrl) then
            ctrl:CancelGetUp()
            return
        end
    
        --if not ent:LookupBone("ValveBiped.Bip01_L_Hand") or not ent:LookupBone("ValveBiped.Bip01_R_Hand") then return end 
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
        return true
    end
    
    Savee_AdvRagKnockdown_DMGKnockdown = doKnockdownDetection
    Savee_AdvRagKnockdown_DoRagDamage = calcRagDamage
    Savee_AdvRagKnockdown_DoKnockdown = doKnockdown

    -- 甲级战犯, 崩溃主要导致者(对NPC 我猜)
    -- 导致我浪费好几个小时的罪魁祸首
    -- 经验证, 可能是布娃娃移除的时机不对/未能消除所有约束导致
    function Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, bchild, bparent, minAng, maxAng, fric)
        if not IsValid(rag) or not bchild or not bparent then return end
        if not rag:LookupBone(bparent) or not rag:LookupBone(bchild) then return end

        if pObjs and (not pObjs[bparent].physBone or not pObjs[bchild].physBone) then return end
        --print(bparent)

        --local _
        minAng = minAng or Angle()
        maxAng = maxAng or Angle()
        fric = fric or 0

        -- 我甚至记得下来完整的前缀
        -- 每个正常模型都有的玩意, 没有就让它滚
        local lArm = pObjs and pObjs[bparent].id or rag:TranslateBoneToPhysBone(rag:LookupBone(bparent))
        local lHand = pObjs and pObjs[bchild].id or rag:TranslateBoneToPhysBone(rag:LookupBone(bchild))
        local lArmP = pObjs and pObjs[bparent].pObj or rag:GetPhysicsObjectNum(lArm)
        local lHandP = pObjs and pObjs[bchild].pObj or rag:GetPhysicsObjectNum(lHand)
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

        SafeRemoveEntityDelayed(ent, tickInterval)
        --ent:Remove()
    
        lArmP:SetPos(armPos)
        lArmP:SetAngles(armAng)

        lHandP:SetPos(handPos)
        lHandP:SetAngles(handAng)

        local wtlLH = WorldToLocal(handPos, handAng, armPos, armAng)

        --lHandP:SetAngles(oldArmAng)
        -- 瞧瞧我发现了什么, phys_ragdollconstraint!
        -- Verified By Savee14702 100%(Except one axis)
        --lHandP:SetAngles(oldHandAng)
        --lHandP:Wake()
        --local const = constraint.AdvBallsocket(rag, rag, lArm, lHand, wtlLH, nil, 0, 0, minAng.p, minAng.y, minAng.r, maxAng.p, maxAng.y, maxAng.r, fric, fric, fric, 0, 1)
        --local _, correctedAng = LocalToWorld(vector_origin, Angle(0, 0, -90), vector_origin, lArmP:GetAngles())
        --lHandP:SetAngles(correctedAng)
        local const = constraint.AdvBallsocket(rag, rag, lArm, lHand, wtlLH, nil, 0, 0, minAng.p, minAng.y, minAng.r, maxAng.p, maxAng.y, maxAng.r, fric, fric, fric, 0, 1)
        rag:RemoveInternalConstraint(lHand)

        lArmP:SetPos(oldArmPos)
        lArmP:SetAngles(oldArmAng)
        
        lHandP:SetPos(oldHandPos)
        lHandP:SetAngles(oldHandAng)


        --[[if IsValid(const) then 
            table.insert(ctrl.ReplacedConsts, {lHandP, lArmP, wtlLH, lHandP:GetMass(), lArmP:GetMass()})
        end]]


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

    function Savee_AdvRagKnockdown_ReplaceRagConstraints(rag, pObjs)
        local ctrl = getController(rag)

        local angMax = Angle(75, 80, 80)
        Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm", -angMax, angMax, 0)
        Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm", -angMax, angMax, 0)
    
        Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, "ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine2", -Angle(15, 60, 50), Angle(15, 40, 50), 0)

        angMax = Angle(80, 80, 80)
        Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2", -angMax, angMax, 0)
        Savee_AdvRagKnockdown_ReplaceRagConstraint(ctrl, rag, pObjs, "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", -angMax, angMax, 0)

    end

    ---@diagnostic disable-next-line: gmod-net-read-write-order-mismatch
    net.Receive("Savee_AdvRagKnockdown_OperationMsg", function(len, p)

        local type = net.ReadUInt(BITCOUNT_OPERATIONINFO)

        ---@type Entity
        local ctrl = p.Savee_AdvRagKnockdown_Controller
        if type == 0 then
            if IsValid(ctrl) then ctrl:CancelGetUp() return end
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

    local replaceACTs = {
        --[ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
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
        end
        doKnockdownDetection(ent, di, dmg > 0)
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
        end
        doKnockdownDetection(ent, di, dmg > 0)

        return __undetoured(atk, di, res, raw, ...)
    
    end)
    funchooks.Add("Entity.TakeDamage", "Savee_AdvRagKnockdown_DmgModSupport", function(ent, dmg, atk, inf, raw, ...)
        --local ctrl = getController(ent)
        if raw or not cv_kd_damagecalc_usetakedamage:GetBool() then return __undetoured(ent, dmg, atk, inf, raw, ...) end

        local di = DamageInfo()
        di:SetDamage(dmg)
        di:SetDamageType(DMG_GENERIC)
        if IsValid(atk) then di:SetAttacker(atk) end
        if isentity(inf) and IsValid(inf) then di:SetInflictor(inf) end
        if ent:IsRagdoll() then
            calcRagDamage(ent, di, dmg > 0)
        end
        doKnockdownDetection(ent, di, dmg > 0)

        return __undetoured(ent, dmg, atk, inf, raw, ...)
    
    end)
    
    funchooks.Add("NPC.GetAimVector", "Savee_AdvRagKnockdown_Sync", function(ply, raw, ...)

        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, raw, ...) end
        local rag = ctrl:GetRagdoll()
        local bone = rag:LookupBone("ValveBiped.Bip01_R_Hand")

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


        return LerpVector(math.Clamp((ctrl:GetRArmDelta() - 0.03) * 10, 0, 1), av, handang:Forward())
    
    end)

    funchooks.Add("Entity.BodyTarget", "Savee_AdvRagKnockdown_Sync", function(ply, vec, raw, ...)

        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, vec, raw, ...) end
        local rag = ctrl:GetRagdoll()
        local bone = rag:LookupBone("ValveBiped.Bip01_Spine2")

        local pos = rag:GetBonePosition(bone)

        return pos
    
    end)
    funchooks.Add("Entity.HeadTarget", "Savee_AdvRagKnockdown_Sync", function(ply, vec, raw, ...)

        local ctrl = getController(ply)
        if not IsValid(ctrl) then return __undetoured(ply, vec, raw, ...) end
        local rag = ctrl:GetRagdoll()
        local bone = rag:LookupBone("ValveBiped.Bip01_Head1")

        local pos = rag:GetBonePosition(bone)

        return pos
    
    end)

    funchooks.Add("NPC.Disposition", "Savee_AdvRagKnockdown_Sync", function(ply, ent, raw, ...)

        local ctrl = getController(ent)
        if raw or not IsValid(ctrl) or not ent:IsRagdoll() or ply == ent then return __undetoured(ply, ent, raw, ...) end
        local own = ctrl:GetOwner(true)

        return ply:Disposition(own)
    
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

    hook.Add("PlayerUse", "Savee_AdvRagKnockdown_HelpFriendly", function(ply, ent)
        -- 无法在被击倒时扶起队友.jpg
        if IsValid(getController(ply)) or not ply:KeyDown(IN_WALK) then return end

        local ctrl = getController(ent)
        if not IsValid(ctrl) then return end 
        ent = ctrl:GetOwner()

        if not ent:IsNPC() or (ent:Disposition(ply) < D_LI and not GetConVar("ai_ignoreplayers"):GetBool()) then return end
        
        ctrl:TryGetUp()
        
        return false
    end)

    hook.Add("EntityEmitSound", "Savee_AdvRagKnockdown_Unconsciousness", function(data)
        local ent = data.Entity
        local ctrl = getController(ent)
        if not IsValid(ctrl) then return end

        if ctrl.NPCState_Unconsciousness then return false end
    end)
    
    hook.Add("PostCleanupMap", "Savee_AdvRagKnockdown_ResetRagdoll", function()
    
        for _, ent in ipairs(ents.FindByClass("ent_savee_advragknockdown_ctrl")) do
            if not IsValid(ent) or ent:IsMarkedForDeletion() then continue end
            
            local own = ent:GetOwner()
            local rag = ent:GetRagdoll()
            if not IsValid(rag) or not IsValid(own) or not own:IsPlayer() or not own:Alive() 
            or own.inKillMove
            then ent:RemoveSelf() continue end

            Savee_AdvRagKnockdown_ReplaceRagConstraints(rag, ent.RagPObjs)
        end
    
    end)

    hook.Add("OnNPCKilled", "!!Savee_AdvRagKnockdown_SetNPCPos", function(npc)
        local ctrl = getController(npc)
        if not IsValid(ctrl) or not ctrl.Initialized then return end

        npc:SetPos(ctrl:GetRagdoll():GetPos(), true)

    end)

    hook.Add("PhysgunPickup", "Savee_AdvRagKnockdown_TransStuffIntoRag", function(ply, ent, fucked)
        if fucked or not cv_kd_knockdown_physgun:GetBool() or ply == ent or not entTypeCheck(ent) then return end
        if not hook.Run("PhysgunPickup", ply, ent, true) then return false end

        return not doKnockdownDetection(ent, nil, true)
    end)
    hook.Add("OnPhysgunPickup", "Savee_AdvRagKnockdown_TransGetUpIntoSleep", function(ply, ent)
        local ctrl = getController(ent)
        if not ent:IsRagdoll() or not IsValid(ctrl) then return end
        
        ctrl:CancelGetUp()
    end)

    hook.Add("GravGunPunt", "Savee_AdvRagKnockdown_TransStuffIntoRag", function(ply, ent, fucked)
        if fucked or not cv_kd_knockdown_gravgun:GetBool() or ply == ent or not entTypeCheck(ent) then return end
        if hook.Run("GravGunPunt", ply, ent, true) == false or not doKnockdownDetection(ent, nil, true) then return false end
        
        return true
    end)

    hook.Add("CreateEntityRagdoll", "Savee_AdvRagKnockdown_InheritRagVel", function(ent, dRag, fucked)
        --print(dRag)
        ---@type Entity
        local ctrl = getController(ent)
        if fucked or not IsValid(ctrl) or dRag:IsMarkedForDeletion() then return end

        --do dRag:Remove() return end

        --ent:SetParent(nil)

        --print("ent有点死了: ", ent, dRag)

        --print(ent)
    
        ---@type Entity
        local rag = ctrl:GetRagdoll()

        local dataList = {}

        --print(1)
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local pObj = dRag:GetPhysicsObjectNum(i)
            local pObjRag = rag:GetPhysicsObjectNum(i)
            if not IsValid(pObj) or not IsValid(pObjRag) then continue end
            dataList[i] = {pObjRag:GetPos(), pObjRag:GetAngles()}
            pObj:Wake()
            pObj:SetVelocity(pObjRag:GetVelocity())
        end

        timer.Simple(tickInterval, function()
            if not IsValid(dRag) then return end

            for i, data in pairs(dataList) do
                local pObj = dRag:GetPhysicsObjectNum(i)
                if not IsValid(pObj) then continue end
                pObj:SetPos(data[1])
                pObj:SetAngles(data[2])
            end
        end)

        ctrl:RemoveSelf()

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

    -- 你知道吗我又加了两个感叹号
    hook.Add("EntityTakeDamage", "!!!!!Savee_AdvRagKnockdown_OwnerCorrection", function(rag, di)

        local atk = di:GetAttacker()

        local ctrl = getController(atk)
        if IsValid(ctrl) and atk:IsRagdoll() then di:SetAttacker(ctrl:GetOwner()) end
    
    end)
    hook.Add("PostEntityTakeDamage", "Savee_AdvRagKnockdown_RagDamage", function(rag, di, take)

        if not cv_kd_enabled:GetBool() or cv_kd_damagecalc_usetakedamage:GetBool() or rag:IsMarkedForDeletion() then return end
        --print("IC2")
        calcRagDamage(rag, di, take)
    
    end)

    hook.Add("PostEntityTakeDamage", "Savee_AdvRagKnockdown_Knockdown", function(ent, di, take)

        if not cv_kd_enabled:GetBool() or ent:IsMarkedForDeletion() then return end
        if cv_kd_damagecalc_usetakedamage:GetBool() then return end

        doKnockdownDetection(ent, di, take)

    end)

    local blackListedInputs_NonAiming = {
        IN_ATTACK2,
        IN_RELOAD,
    }
    local blackListedInputs = {
        IN_SPEED,
        IN_DUCK,
    }

    
    -- 加个优先级
    hook.Add("StartCommand", "!Savee_AdvRagKnockdown_RagView", function(ply, cmd)
        ---@type Entity
        local ctrl = ply.Savee_AdvRagKnockdown_Controller
        handlingKnockdownedCmd = IsValid(ctrl)
        if not IsValid(ctrl) then return end


        local stamina = ctrl:GetStamina()
        local consc = ctrl:GetConsciousness()

        if consc < 15 then cmd:ClearButtons() end

        --cmd:RemoveKey()
        --print(cmd:GetViewAngles())

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
            if cmd:KeyDown(IN_ATTACK) and (meleeHTs[ht] or (wep:Clip1() == 0 and blackListedHTs[ht])) then
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

    -- 兼容
    hook.Add("BSMod_KillMoveStarted", "Savee_AdvRagKnockdown_PosCorrection", function(ply, tar)
        local plyCtrl = getController(ply)
        local tarCtrl = getController(tar)
        if IsValid(plyCtrl) then plyCtrl:RemoveSelf() end
        if IsValid(tarCtrl) then tarCtrl:RemoveSelf() end
    end)

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

    local oldAimingState

    concommand.Add(cvPrefix .. "doknockdown", function()
        if not cv_kd_enabled:GetBool() then return end
        local lp = LocalPlayer()
        local ctrl = getController(lp)

        net.Start("Savee_AdvRagKnockdown_OperationMsg", true)
        net.WriteUInt(0, BITCOUNT_OPERATIONINFO)
        net.SendToServer()

        --print(ctrl, clcv_ctrl_aim:GetInt() < 1)
        if ctrl or clcv_ctrl_aim:GetInt() < 1 then return end

        timer.Simple(isSP and 0 or lp:Ping() / 800, function() sendAimingMsg(1) oldAimingState = true end)
    
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
            pObj:SetVelocityInstantaneous(rag:GetVelocity())
        end
        --print(deadRag:GetPhysicsObjectNum(1))
    end)

    hook.Add("InputMouseApply", "Savee_AdvRagKnockdown_ViewControl", function(cmd, x, y)
        --print(cmd:GetMouseY(), y)
        local ctrl = getController(LocalPlayer())
        if not IsValid(ctrl) or (x == 0 and y == 0) then return end
        local rag = ctrl:GetRagdoll()
        local consc = ctrl:GetConsciousness()

        local deltaAng = Angle(y, x) * (isSP and 1 / 66 or tickInterval)

        local conscLerp = math.ease.OutQuint(consc / 100)

        local oldAng = cmd:GetViewAngles()

        local refAng = oldAng

        local eyeatt = rag:LookupAttachment("eyes")
        if cv_kd_ctrl_useheadang:GetBool() and eyeatt ~= 0 then
            refAng = rag:GetAttachment(eyeatt).Ang
        end

        -- 在Z-City里吸氰化物吸的
        oldAng:RotateAroundAxis(refAng:Right(), -deltaAng.p * conscLerp)
        oldAng:RotateAroundAxis(refAng:Up(), -deltaAng.y * conscLerp)

        --newAng:Normalize()
        cmd:SetViewAngles(oldAng, true)
        return true
    end)

    local last_stored_roll = 0
    hook.Add("StartCommand", "!Savee_AdvRagKnockdown_RagOperation", function(ply, cmd)
        ---@type Entity
        local ctrl = getController(ply)
        handlingKnockdownedCmd = IsValid(ctrl)
        if not IsValid(ctrl) then oldAimingState = false return end

        local consc = ctrl:GetConsciousness()

        local oldAng = ctrl:GetAimEyeAngles()
        local wep = ply:GetActiveWeapon()

        -- 原版武器兼容, 虽然你无论怎么压枪弹道都是往上飘的就是了
        if IsValid(wep) and not wep:IsScripted() and last_stored_roll ~= 0 and oldAng.r == 0 then
            oldAng.r = last_stored_roll
        end

        local conscLerp = math.ease.OutQuint(consc / 100)
        --local manualMul = not cmd:KeyDown(IN_FORWARD) and (cmd:KeyDown(IN_SPEED) and cvVars.cl_contrl_rollspdmul_sprint or cmd:KeyDown(IN_WALK) and cvVars.cl_contrl_rollspdmul_walk) or 1

        if ctrl:GetParent() ~= ctrl:GetRagdoll() then
            oldAng.r = math.Approach(oldAng.r, 0, 15)
        elseif cmd:KeyDown(IN_MOVELEFT) then
            oldAng = (oldAng - Angle(0, 0, 90) * conscLerp * FrameTime())
        elseif cmd:KeyDown(IN_MOVERIGHT) then
            oldAng = (oldAng + Angle(0, 0, 90) * conscLerp * FrameTime())
        end
        cmd:SetViewAngles(oldAng, true)
        last_stored_roll = oldAng.r

        local aimingBind = clcv_ctrl_nodefkeybind:GetBool() and input.LookupBinding("+advragknockdown_aimweapon") or input.LookupBinding(cvPrefix .. "toggleaimweapon")

        local newAimingState = cmd:KeyDown(cvVars.cl_control_altaimkey and IN_WALK or IN_USE)
        
        -- 世界上最聪明的解决方案
        if clcv_ctrl_reversedaiming:GetBool() then newAimingState = not newAimingState end

        if not aimingBind and newAimingState ~= oldAimingState then
            --print(1)
            --print(cmd:KeyDown(IN_USE))
            sendAimingMsg(newAimingState and 1 or 0)
            oldAimingState = newAimingState
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
            if cmd:KeyDown(IN_ATTACK) then
                ctrl:AddKeyInput(IN_ATTACK)
                if (wep:Clip1() == 0 and blackListedHTs[ht]) then
                    cmd:RemoveKey(IN_ATTACK)
                end
            end
        elseif ctrl:GetLArmDelta() > 0.3 and cmd:KeyDown(IN_RELOAD) then
            cmd:RemoveKey(IN_RELOAD)
        end

    
    end)

    local function returnCheck(self)
        return not IsValid(self) or (not self.GetRagdoll or not IsValid(self:GetRagdoll()))
    end

    -- 类似Z-City那样的"平滑转换"

    local calcview_last_stored = -1
    local calcview_last_pos = vector_origin
    local calcview_last_ang = angle_zero
    hook.Add("CalcView", "zzzSavee_AdvRagKnockdown_CTRLHook", function(ply, pos, ang, fov)
        local self = getController(ply)
        local ct = CurTime()

        if returnCheck(self) then 
            local calcview_transtime = cvVars.cl_getup_smoothtransitioninterval
            local lerp = (ct - calcview_last_stored) / calcview_transtime

            return calcview_last_stored + calcview_transtime >= ct and {
                origin = LerpVector(lerp, calcview_last_pos, pos),
                angles = LerpAngle(lerp, calcview_last_ang, ang),
            } or nil
        end
        local result = self:CalcView(ply, pos, ang, fov)

        if not result then return end

        calcview_last_stored = ct
        calcview_last_pos = result.origin
        calcview_last_ang = result.angles
        return result

    end)

    local function doWeaponCalcView(wep, vm, pos, ang)
        if wep.CalcViewModelView then 
            pos, ang = wep:CalcViewModelView(vm, pos, ang, pos, ang)
        elseif wep.GetViewModelPosition then 
            pos, ang = wep:GetViewModelPosition(pos, ang) 
        end
        return pos, ang
    end


    hook.Add("CalcViewModelView", "Savee_AdvRagKnockdown_CTRLHook", function(wep, vm, oldPos, oldAng, pos, ang, ...)
        local self = getController(LocalPlayer():GetViewEntity())
        if returnCheck(self) then
            local ct = CurTime()
            
            local calcview_transtime = cvVars.cl_getup_smoothtransitioninterval
            local lerp = (ct - calcview_last_stored) / calcview_transtime

            if calcview_last_stored + calcview_transtime < ct then return end
            pos = LerpVector(lerp, calcview_last_pos, pos)

            if IsValid(wep) then
                pos, ang = doWeaponCalcView(wep, vm, pos, ang)
            end
            
            return pos, ang
        end
        return self:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang, ...)
    
    end)
    hook.Add("PreDrawPlayerHands", "Savee_AdvRagKnockdown_CTRLHook", function(...)
        local self = getController(LocalPlayer():GetViewEntity())
        if returnCheck(self) then return end
        return self:PreDrawPlayerHands(...)
    end)

    -- EF_BONEMERGE特有的双绘制
    SAVEE_ADVRAGKNOCKDOWN_DRAWINGOPAQUE = false
    hook.Add("PreDrawOpaqueRenderables", "Savee_AdvRagKnockdown_FuckEF_BONEMERGE", function()
        SAVEE_ADVRAGKNOCKDOWN_DRAWINGOPAQUE = true
    end)
    hook.Add("PreDrawTranslucentRenderables", "Savee_AdvRagKnockdown_FuckEF_BONEMERGE", function()
        SAVEE_ADVRAGKNOCKDOWN_DRAWINGOPAQUE = false
    end)

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

    --[[funchooks.Add("Entity.SetBoneMatrix", "Savee_AdvRagKnockdown_TPIKSupport", function(ply, i, mtx, ...)
        if ply:IsRagdoll() then return __undetoured(ply, i, mtx, ...) end
        local ctrl = getController(ply)
        --print(ply)
        if IsValid(ctrl) then
            local rag = ctrl:GetRagdoll()
            rag:SetBoneMatrix(i, mtx)
        end

        return __undetoured(ply, i, mtx, ...)
    end)
    funchooks.Add("Entity.SetBonePosition", "Savee_AdvRagKnockdown_TPIKSupport", function(ply, i, pos, ang, ...)
        if ply:IsRagdoll() then return __undetoured(ply, i, pos, ang, ...) end
        local ctrl = getController(ply)
        if IsValid(ctrl) then
            ctrl:GetRagdoll():SetBonePosition(i, pos, ang)
        end

        return __undetoured(ply, i, pos, ang, ...)
    end)]]

    local opaques = {
        [RENDERGROUP_OPAQUE] = true,
        [RENDERGROUP_OPAQUE_BRUSH] = true,
        [RENDERGROUP_OPAQUE_HUGE] = true,
        [RENDERGROUP_BOTH] = true,
    }

    funchooks.Add("Entity.DrawModel", "Savee_AdvRagKnockdown_SuspendInsufficientDraw", function(ent, fl, ...)
        
        --do return __undetoured(ent, fl, ...) end

        local own = ent
        
        if ent:IsWeapon() then
            own = ent:GetOwner()
        end

        local ctrl = getController(own)
        if not IsValid(own) or not IsValid(ctrl) then return __undetoured(ent, fl, ...) end
        if ent:GetNoDraw() then return end
        
        local rag = ctrl:GetRagdoll()

        local renderGroup = ent:GetRenderGroup()
        if opaques[renderGroup] and not SAVEE_ADVRAGKNOCKDOWN_DRAWINGOPAQUE then return end
        if not opaques[renderGroup] and renderGroup ~= RENDERGROUP_BOTH and SAVEE_ADVRAGKNOCKDOWN_DRAWINGOPAQUE then return end

        -- 我猜需要有人验证一下
        if own:IsPlayer() then return __undetoured(ent, fl, ...) end

        --render.SetLightingOrigin(Entity(1):GetEyeTrace().HitPos)
        --rag:SetPos(rag:GetBonePosition(0))

        -- 一种模拟布娃娃光照的方法, 应该可以修复一些Bug, 代价嘛...
        -- 我猜这个也花不了多少性能:/
        local oldPos = rag:GetPos()
        local pos = oldPos + rag:OBBCenter() - Vector(0, 0, 16) -- 目前来看这么做可以模拟布娃娃的光照
    
        rag:SetPos(pos)
        --own:SetPos(pos, true)

        render.SetLightingOrigin(pos)

        local result = {__undetoured(ent, fl, ...)}
        rag:SetPos(oldPos)

        return unpack(result)
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

--[[ 

hook列表
    Annotation似乎没用(其实是不会用)
    所以我把东西在这里列出来 希望能起到一定帮助

    **Savee_AdvRagKnockdown_ShouldKnockdown**
    介绍:
        判断是否要击倒一个实体
        建议在这里获取控制台指令再做计算(或者你在这里修改damageInfo欺骗默认算法)
    传入: 
        ent, 实体, 要被击倒的实体
        damageInfo, CTakeDamageInfo, 伤害信息
        damageTaken, bool, 是否承受伤害
    传出:
        bool, 是否击倒实体, 返还nil**会交给下个钩子处理, 或是让默认算法处理**

    **Savee_AdvRagKnockdown_ShouldGetUp**
    介绍:
        判断一个实体是否应该进入起身状态, 如果意识和体力低于45**仍然不可起身**
    传入: 
        ent, 实体, 要被击倒的实体
        ctrl, 实体, 控制器实体
        groundTr, TraceResult, 地面射线检测(是否着地)
    传出:
        bool, 是否应该起身, 返还nil**会交给下个钩子处理, 或是让默认算法处理**

    **Savee_AdvRagKnockdown_OnBrainDamage**
    介绍:
        修改实体受到的体力/意识伤害
        需要注意的是此时的伤害已经**经由控制台乘数修改**
    传入: 
        ent, 实体, 受伤实体
        ctrl, 实体, 控制器实体
        stDmg, float, 当前体力伤害
        csDmg, float, 当前意识伤害
        damageInfo, CTakeDamageInfo, 伤害信息
        force, float?, 伤害力度(可能为空!)
    传出:
        float?, 新的体力伤害, 如果为空则使用默认值
        float?, 新的意识伤害, 如果为空则使用默认值
    **Savee_AdvRagKnockdown_GetUpAnimationInit**
    介绍:
        在这里添加你的自定义动画
        你可以在这里添加非数字key
    传入: 
        animtbl, table, 动画表
    示例:
    
        animtbl.test = {
            Model = "models/Combine_Super_Soldier.mdl",
            Sequence = "cover_crouch", -- 可以是数字

            AngDelta = Angle(0, 0, 0), -- 相对角度偏移

            -- PhysControl Parameter
            -- {startCycle, EndCycle}
            Recover = {0.1, 0.9},
            Recover_Duck = {0.4, 0.5},
            -- pitchmin, pitchmax, 翻转
            Pitch = {-90, 90, true},
            -- 在站着的位置(盆骨距离地面45hu)的Cycle
            GetUp_Stand = 0.7,
            -- 在蹲着的位置(盆骨距离地面25hu)的Cycle
            GetUp_Duck = 0.3,
        },

]]
