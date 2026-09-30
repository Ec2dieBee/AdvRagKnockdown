include("shared.lua")
include("sv_ragdollstuffs.lua")
include("sv_damage.lua")

-- VARS/STATUS
ENT.NextBroadcastNWEntity = -1

ENT.PreventPhysAttackTill = -1
ENT.NextCalcAnim = -1
ENT.NextRegenStamina = -1
ENT.NextRegenConsciousness = -1
ENT.NextSetLArmDelta = -1
ENT.NextSetRArmDelta = -1
ENT.CanSetLArmDelta = true
ENT.CanSetRArmDelta = true

ENT.NextGetUp = -1

ENT.ShadowCtrlData = {}
ENT.DI_MarkedAsTaken = {}


ENT.UsePlayerAimAnimation = false

-- 享受你的Prone Mod但是是布娃娃版
-- 更加战术的操作, 我猜(这样你的狙击点就没那么容易被发现了)
ENT.LowPose = false

ENT.GettingUp = false
ENT.GettingUp_Crouch = false
ENT.GettingUp_SyncingToOwner = false
ENT.GettingUp_FaceAng = Angle()
