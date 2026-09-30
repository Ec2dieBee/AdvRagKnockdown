local cvPrefix = "savee_advragknockdown_"
local function getCV(cv, st)
    cv = GetConVar(cvPrefix .. cv)
    if not cv then return end
    if st then
        cv = cv["Get" .. st](cv)
    end

    return cv
end

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
    local newStaminaDmg, newConscDmg = hook.Run("Savee_AdvRagKnockdown_OnBrainDamage", own, self, stDmg, csDmg, di, force)
    stDmg = newStaminaDmg or stDmg
    csDmg = newConscDmg or csDmg


    local stamina = self:GetStamina()
    stamina = stamina - stDmg

    local consc = self:GetConsciousness()
    consc = consc - csDmg


    self:SetStamina(math.max(0, stamina))
    self:SetConsciousness(math.max(0, consc))

    self.NextRegenStamina = math.max(ct, self.NextRegenStamina) + math.Clamp(dmg / 20, 0.1, 3) * forceMul
    self.NextRegenConsciousness = math.max(ct, self.NextRegenConsciousness) + math.Clamp(dmg / 10, 0.1, 5) * forceMul / 2

end


