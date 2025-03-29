-- 设置全局表
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 获取配置
local RANDOM_TYPE = GetModConfigData("random_type")
local SHOW_ORIGINAL = GetModConfigData("show_original")
local RANDOM_CHANCE = GetModConfigData("random_chance")

-- 添加调试日志函数
local function DebugLog(...)
    print("[随机食物]", ...)
end

-- 获取所有食谱食物
local all_recipes = {}
local food_categories = {}
local food_values = {}

-- 初始化食物列表
local function InitFoodLists()
    -- 获取所有烹饪食谱
    for k, v in pairs(require("preparedfoods")) do
        if v.name and v.weight then
            table.insert(all_recipes, v.name)
            
            -- 按类别分类
            local category = v.tags and v.tags[1] or "uncategorized"
            if not food_categories[category] then
                food_categories[category] = {}
            end
            table.insert(food_categories[category], v.name)
            
            -- 按价值分类
            local value = v.hunger or 0
            local value_key = math.floor(value / 10) * 10
            if not food_values[value_key] then
                food_values[value_key] = {}
            end
            table.insert(food_values[value_key], v.name)
        end
    end
    
    DebugLog("已加载 " .. #all_recipes .. " 种食谱食物")
    for category, foods in pairs(food_categories) do
        DebugLog("类别 " .. category .. ": " .. #foods .. " 种食物")
    end
    for value, foods in pairs(food_values) do
        DebugLog("价值 " .. value .. ": " .. #foods .. " 种食物")
    end
end

-- 获取随机食物
local function GetRandomFood(original_food)
    -- 完全随机
    if RANDOM_TYPE == "full_random" then
        return all_recipes[math.random(#all_recipes)]
    end
    
    -- 同类型随机
    if RANDOM_TYPE == "same_category" then
        local original_recipe = nil
        for k, v in pairs(require("preparedfoods")) do
            if v.name == original_food then
                original_recipe = v
                break
            end
        end
        
        if original_recipe and original_recipe.tags and original_recipe.tags[1] then
            local category = original_recipe.tags[1]
            if food_categories[category] and #food_categories[category] > 0 then
                return food_categories[category][math.random(#food_categories[category])]
            end
        end
    end
    
    -- 同价值随机
    if RANDOM_TYPE == "same_value" then
        local original_recipe = nil
        for k, v in pairs(require("preparedfoods")) do
            if v.name == original_food then
                original_recipe = v
                break
            end
        end
        
        if original_recipe and original_recipe.hunger then
            local value_key = math.floor(original_recipe.hunger / 10) * 10
            if food_values[value_key] and #food_values[value_key] > 0 then
                return food_values[value_key][math.random(#food_values[value_key])]
            end
        end
    end
    
    -- 默认返回完全随机
    return all_recipes[math.random(#all_recipes)]
end

-- 修改烹饪锅的烹饪结果
AddPrefabPostInit("cookpot", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 确保组件存在
    if not inst.components or not inst.components.stewer then
        print("[随机食物] 错误：烹饪锅缺少必要组件")
        return
    end
    
    -- 初始化食物列表
    if #all_recipes == 0 then
        InitFoodLists()
    end
    
    -- 保存原始的烹饪完成函数
    local old_harvest = inst.components.stewer.Harvest
    
    -- 修改烹饪完成函数
    inst.components.stewer.Harvest = function(self, harvester)
        -- 获取原始的烹饪结果
        local original_product = self.product
        
        -- 确保产品有效
        if not original_product then
            return old_harvest(self, harvester)
        end
        
        -- 随机决定是否替换
        if math.random() <= RANDOM_CHANCE then
            -- 获取随机食物
            local random_food = GetRandomFood(original_product)
            
            -- 替换烹饪结果
            self.product = random_food
            
            -- 显示原始食物信息
            if SHOW_ORIGINAL and harvester and harvester.components.talker then
                local original_name = STRINGS.NAMES[string.upper(original_product)] or original_product
                local random_name = STRINGS.NAMES[string.upper(random_food)] or random_food
                harvester.components.talker:Say("原本是" .. original_name .. "，变成了" .. random_name .. "！")
            end
        end
        
        -- 调用原始的烹饪完成函数
        return old_harvest(self, harvester)
    end
end)

-- 对便携烹饪锅也做同样的修改
AddPrefabPostInit("portablecookpot", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 初始化食物列表
    InitFoodLists()
    
    -- 保存原始的烹饪完成函数
    local old_harvest = inst.components.stewer.Harvest
    
    -- 修改烹饪完成函数
    inst.components.stewer.Harvest = function(self, harvester)
        -- 获取原始的烹饪结果
        local original_product = self.product
        
        -- 随机决定是否替换
        if math.random() <= RANDOM_CHANCE then
            -- 获取随机食物
            local random_food = GetRandomFood(original_product)
            
            -- 替换烹饪结果
            self.product = random_food
            
            -- 显示原始食物信息
            if SHOW_ORIGINAL and harvester and harvester.components.talker then
                harvester.components.talker:Say("原本是" .. STRINGS.NAMES[string.upper(original_product)] .. "，变成了" .. STRINGS.NAMES[string.upper(random_food)] .. "！")
            end
        end
        
        -- 调用原始的烹饪完成函数
        return old_harvest(self, harvester)
    end
end) 