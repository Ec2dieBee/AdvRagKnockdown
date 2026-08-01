function AdvRagKnockdown_ShouldKnockdown(ent, di, dt) end

---@overload fun(eventName: "AdvRagKnockdown_ShouldKnockdown", identifier: any, func: fun(ent:Entity, damageInfo:CTakeDamageInfo, damageTaken:boolean))
---@overload fun(eventName: "AdvRagKnockdown_ShouldGetup", identifier: any, func: fun(ent:Entity, ctrl:Entity))
function hook.Add(eventName, identifier, func) end


