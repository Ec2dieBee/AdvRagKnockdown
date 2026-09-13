-- 然后那天她/他告诉我: 你也就这样了, 趁早死了算了
-- 我是指 - 既然我已经知道ragdoll resizer是怎么做的了(指PhysObj:GetMeshConvexes()) 为什么不现在开干呢

AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "[ARKD]布娃娃主体"
ENT.Category = "Savee Stuffs - CONCEPTS"
ENT.Spawnable = true


function ENT:Initialize()
    if CLIENT then return end
    self:Remove()
    local ply = Entity(1)
    local ent = ents.Create("prop_resizedragdoll_physparent")
    ent:SetModel(ply:GetModel())
    ent:SetPos(ply:GetEyeTrace().HitPos + Vector(0, 0, 10))

    local tbl = {}
    local scl = ply:GetModelScale()
    scl = Vector(scl, scl, scl)
    
    for i = 0, 31 do
        tbl[i] = scl
    end
    ent.PhysObjScales = tbl
    ent:Spawn()
end

