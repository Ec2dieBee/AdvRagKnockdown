-- 在这插入你自己的自定义状态
-- 和钩子类似, 返还非空值可停掉之后的STATUS的运算
-- 这些属性的运算总是在钩子之后进行(这意味着如果有钩子阻止你起身Status不会被调用)
-- 这里的代码不会被热加载, 如果你是一名开发者我对此深表歉意
-- 可以使用lua_refresh_file entities/ent_savee_advragknockdown_ctrl/shared.lua以热加载ctrl.lua(而免去解包的痛苦)
-- 不幸的是, 你每次修改后都需要再上一次Status(悲)
-- 特殊的键
-- __id 这玩意的ID, 也就是文件名
-- Controller - 控制器实体
-- Controller_Owner - 被击倒的人
-- Controller_Ragdoll - 布娃娃

STATUS.Base = "status_base"

-- 在玩家选择进行这个行为时调用
---@return bool 是否允许玩家进行这个行为
function STATUS:CanBeUsed() return true end

-- 在被施加时调用
function STATUS:OnApply() end

-- 每Tick调用一次, 在大部分逻辑之前
-- 不会让你停掉任何东西
function STATUS:Tick() end

-- 每Think调用一次, 在大部分逻辑之前
-- 不会让你停掉任何东西
function STATUS:Think() end

function STATUS:GetID()
    return rawget(self, "__id")
end

-- 傻逼代码, 但本质上应该是个hack
function STATUS:Remove()
    local ctrl = self.Controller
    if not IsValid(ctrl) then return end
    ctrl.ActiveStatus[self:GetID()] = nil -- 你他妈怎么写的代码
end

-- 在布娃娃初始化后调用
---@param rag Entity 布娃娃
---@param pObjs table ARKD给的布娃娃物理部件表
---@param ownVel Vector 被击倒者的速度
function STATUS:RagdollInitialized(rag, pObjs, ownVel) end

-- 把这俩玩意加上
-- 只在起身途中调用
-- 和CanGetUp的差别是这玩意只会在起身途中不停调用以强奸你的游戏
---@return boolean? 是否阻止起身
function STATUS:ShouldGetUp() end

-- 在尝试起身时调用
---@return boolean? 是否阻止起身
function STATUS:CanGetUp() end


-- 在ENT:DealWithAnim的起身动画后调用
---@param pObjs table ARKD生成的PhysObj表
---@param shadowCtrls table 动画表, 你在function里做的修改会被**直接**应用
---@return boolean? 是否挡掉默认动画检测(不包括起身)
function STATUS:DoAnimationSystem(pObjs, shadowCtrls) end

-- 在ENT:DealWithAnim的动画计算完毕后调用
-- ---@param pObjs table ARKD生成的PhysObj表
---@param shadowCtrls table 动画表, 你在function里做的修改会被**直接**应用
function STATUS:OnAnimationCaculated(pObjs, shadowCtrls) end

-- 控制是否进行PhysicsSimulate, 或者是你要做些什么
---@param physObj PhysObj 物理部件
---@param deltaTime number 距离上次模拟的时间
---@return boolean? 停掉原版PhysicsSimulate
function STATUS:PhysicsSimulate(physObj, deltaTime) end

-- 滑行前调用这个function
---@param vel Vector 速度
---@param velLen number 速度大小
---@return boolean? true: 无视条件直接过 false: 无视条件直接拒绝
function STATUS:PhysicsSimulate_CanSurf(vel, velLen) end

-- 滑行时调用这个function, 事实上整个系统都是为了这碟醋包的饺子
-- 不建议返还false, 毕竟运算已经好了
---@param spdMul number 最终计算好的速度乘数
---@return number|boolean? false: 不进行滑行, 数字: 最终采用的滑行速度加成
function STATUS:PhysicsSimulate_Surfing(spdMul) end

-- 覆写HasKeyInput
---@param key IN 键位
---@return boolean? 这个键被覆盖的状态
function STATUS:KeyOverride(key) end

