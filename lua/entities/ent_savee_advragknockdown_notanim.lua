AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "滚木实体"

ENT.AutomaticFrameAdvance = true

ENT.Category = "Savee Stuffs - OTHERS"

-- ARC9 热成像支持
-- btw 为啥这些nodraw的玩意还会被network到客户端?
-- Not networked是你的谎言~
function ENT:Draw() end
