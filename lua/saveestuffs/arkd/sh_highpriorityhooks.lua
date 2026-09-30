-- Hook的运行是按照什么"内存加载顺序"来的, 因为这就是pair的工作方式
-- Table keys in Lua have no specific order, and will be returned in whatever order they exist in memory. This may not always be in ascending order or alphabetical order. If you need to iterate over an array in order, use ipairs.
-- (Lua中的Table键无特定顺序, 并且会按照它们存在于内存中的顺序返还, 这可能不总是以递进或顺字母表排序. 如果你要以特定顺序遍历一个Array, 去用ipairs)
-- 显然我们要草翻这个世界的所有子弹, 所以修改子弹的钩子必须被挂到首位, that's it

AddCSLuaFile()

