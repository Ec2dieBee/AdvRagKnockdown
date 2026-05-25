-- ToDo: 很显然这将成为一个"枢纽", 所以你要把功能模块一类的玩意加上
-- 很显然这会和Ragknockdown冲突, 但是目前先做进阶起身(是的 你不能在Ragknockdown里创飞一个正在起来的人, 这不好)

-- 显然的 Z-City的系统很Newbility
-- 但是我们仍然需要自己做一个, 除了复用键位以外应该不会有问题
-- 大概吧
AddCSLuaFile()
local tickInterval = engine.TickInterval()


local upperBodyBones = {
    ["ValveBiped.Bip01_Spine2"] = 0.2,
    --["ValveBiped.Bip01_Head1"] = 1,
    --["ValveBiped.Bip01_L_Clavicle"] = 1,
    ["ValveBiped.Bip01_L_UpperArm"] = 1,
    ["ValveBiped.Bip01_L_Forearm"] = 1.1,
    ["ValveBiped.Bip01_L_Hand"] = 3,
    --["ValveBiped.Bip01_R_Clavicle"] = 1,
    ["ValveBiped.Bip01_R_UpperArm"] = 1,
    ["ValveBiped.Bip01_R_Forearm"] = 1.1,
    ["ValveBiped.Bip01_R_Hand"] = 3,
}

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "test"

ENT.AutomaticFrameAdvance = true

ENT.Category = "Savee Stuffs - CONCEPTS"
ENT.Spawnable = true


function ENT:Initialize()

    self:SetModel("models/props_junk/PropaneCanister001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    self:StartMotionController()

end

function ENT:PhysicsSimulate( phys, deltatime )
 
    phys:Wake()
    
    phys:ComputeShadowControl({
        --secondstoarrive = ,
        pos = Vector(),
        angle = Angle(),
        maxangular = 500,
        maxangulardamp = 100,
        maxspeed = 100,
        maxspeeddamp = 100,
        dampfactor = 0.8,
        --teleportdistance = 200,
        delta = deltatime
    })
 
end
