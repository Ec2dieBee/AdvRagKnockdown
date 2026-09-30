-- 这里装着低优先级钩子方便其它插件烹饪
AddCSLuaFile()

for _, data in ipairs(SAVEE_ADVRAGKNOCKDOWN_LOWPRIOHOOKS) do
    hook.Add(data[1], data[2], data[3])
end

