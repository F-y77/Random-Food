local PetAdaptation = Class(function(self, inst)
    self.inst = inst
    self.pet_type = "NEUTRAL"
    self.scrappy_level = 0  -- 斗志昂扬等级
    self.crafty_level = 0   -- 灵巧等级
    self.peppy_level = 0    -- 俏皮等级
    self.plump_level = 0    -- 吃饱喝足等级
    
    self.combat_bonus = 0   -- 战斗加成
    self.work_bonus = 0     -- 工作加成
    self.sanity_bonus = 0   -- 精神加成
    self.hunger_bonus = 0   -- 饥饿加成
end)

function PetAdaptation:GetPetType()
    return self.pet_type
end

function PetAdaptation:UpdateAdaptation(owner, action_type, value)
    if not owner then return end
    
    local adaptation_speed = GetModConfigData("pet_adaptation_speed") or 2
    value = value or adaptation_speed
    
    -- 根据行为类型更新宠物特质
    if action_type == "combat" then
        -- 斗志昂扬
        self.scrappy_level = math.min(100, self.scrappy_level + value)
        -- 其他特质略微降低
        self.crafty_level = math.max(0, self.crafty_level - value * 0.2)
        self.peppy_level = math.max(0, self.peppy_level - value * 0.1)
        self.plump_level = math.max(0, self.plump_level - value * 0.1)
        
    elseif action_type == "craft" then
        -- 灵巧
        self.crafty_level = math.min(100, self.crafty_level + value)
        -- 其他特质略微降低
        self.scrappy_level = math.max(0, self.scrappy_level - value * 0.2)
        self.peppy_level = math.max(0, self.peppy_level - value * 0.1)
        self.plump_level = math.max(0, self.plump_level - value * 0.1)
        
    elseif action_type == "pet" then
        -- 俏皮
        self.peppy_level = math.min(100, self.peppy_level + value)
        -- 其他特质略微降低
        self.scrappy_level = math.max(0, self.scrappy_level - value * 0.1)
        self.crafty_level = math.max(0, self.crafty_level - value * 0.1)
        self.plump_level = math.max(0, self.plump_level - value * 0.1)
        
    elseif action_type == "feed" then
        -- 吃饱喝足
        self.plump_level = math.min(100, self.plump_level + value)
        -- 其他特质略微降低
        self.scrappy_level = math.max(0, self.scrappy_level - value * 0.1)
        self.crafty_level = math.max(0, self.crafty_level - value * 0.1)
        self.peppy_level = math.max(0, self.peppy_level - value * 0.1)
    end
    
    -- 确定主要特质
    local max_level = math.max(self.scrappy_level, self.crafty_level, self.peppy_level, self.plump_level)
    
    if max_level > 50 then
        if max_level == self.scrappy_level then
            self.pet_type = "SCRAPPY"
        elseif max_level == self.crafty_level then
            self.pet_type = "CRAFTY"
        elseif max_level == self.peppy_level then
            self.pet_type = "PEPPY"
        elseif max_level == self.plump_level then
            self.pet_type = "PLUMP"
        end
    else
        self.pet_type = "NEUTRAL"
    end
    
    -- 计算加成
    self:CalculateBonus()
    
    -- 更新外观和名称
    self:UpdateAppearance()
end

function PetAdaptation:CalculateBonus()
    -- 计算战斗加成 (斗志昂扬)
    local combat_bonus_max = GetModConfigData("combat_bonus_max") or 0.2
    self.combat_bonus = (self.scrappy_level / 100) * combat_bonus_max
    
    -- 计算工作加成 (灵巧)
    local work_bonus_max = GetModConfigData("work_bonus_max") or 0.2
    self.work_bonus = (self.crafty_level / 100) * work_bonus_max
    
    -- 计算精神加成 (俏皮)
    local sanity_bonus_max = GetModConfigData("sanity_bonus_max") or 1.0
    self.sanity_bonus = (self.peppy_level / 100) * sanity_bonus_max
    
    -- 计算饥饿加成 (吃饱喝足)
    local hunger_bonus_max = GetModConfigData("hunger_bonus_max") or 0.1
    self.hunger_bonus = (self.plump_level / 100) * hunger_bonus_max
end

function PetAdaptation:ApplyBonus(owner)
    if not owner then return end
    
    -- 移除旧的加成
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier("pet_bonus")
    end
    
    if owner.components.workmultiplier then
        owner.components.workmultiplier:RemoveMultiplier("pet_bonus")
    end
    
    if owner.components.sanity then
        owner.components.sanity.externalmodifiers:RemoveModifier("pet_bonus")
    end
    
    if owner.components.hunger then
        owner.components.hunger.burnratemodifiers:RemoveModifier("pet_bonus")
    end
    
    -- 应用新的加成
    if self.combat_bonus > 0 then
        owner.components.combat.externaldamagemultipliers:SetModifier("pet_bonus", 1 + self.combat_bonus)
        
        -- 显示加成效果（可选）
        if owner.components.talker and (not owner.last_pet_combat_bonus or owner.last_pet_combat_bonus ~= self.combat_bonus) then
            owner.components.talker:Say(string.format("我的宠物给我提供了%.0f%%的攻击加成！", self.combat_bonus * 100))
            owner.last_pet_combat_bonus = self.combat_bonus
        end
    end
    
    if self.work_bonus > 0 then
        owner.components.workmultiplier:AddMultiplier("pet_bonus", 1 + self.work_bonus)
        
        -- 显示加成效果（可选）
        if owner.components.talker and (not owner.last_pet_work_bonus or owner.last_pet_work_bonus ~= self.work_bonus) then
            owner.components.talker:Say(string.format("我的宠物给我提供了%.0f%%的工作速度加成！", self.work_bonus * 100))
            owner.last_pet_work_bonus = self.work_bonus
        end
    end
    
    if self.sanity_bonus > 0 and owner.components.sanity then
        owner.components.sanity.externalmodifiers:SetModifier("pet_bonus", self.sanity_bonus)
        
        -- 显示加成效果（可选）
        if owner.components.talker and (not owner.last_pet_sanity_bonus or owner.last_pet_sanity_bonus ~= self.sanity_bonus) then
            owner.components.talker:Say(string.format("我的宠物让我感到更加愉快！每分钟恢复%.1f点精神值。", self.sanity_bonus * 60))
            owner.last_pet_sanity_bonus = self.sanity_bonus
        end
    end
    
    if self.hunger_bonus > 0 and owner.components.hunger then
        owner.components.hunger.burnratemodifiers:SetModifier("pet_bonus", 1 - self.hunger_bonus)
        
        -- 显示加成效果（可选）
        if owner.components.talker and (not owner.last_pet_hunger_bonus or owner.last_pet_hunger_bonus ~= self.hunger_bonus) then
            owner.components.talker:Say(string.format("我的宠物让我感到更加饱足！饥饿速度降低%.0f%%。", self.hunger_bonus * 100))
            owner.last_pet_hunger_bonus = self.hunger_bonus
        end
    end
end

function PetAdaptation:UpdateAppearance()
    -- 根据宠物类型更新外观和名称
    if not self.inst.components or not self.inst.components.inspectable then return end
    
    if self.pet_type == "SCRAPPY" then
        -- 斗志昂扬外观
        self.inst.components.inspectable.nameoverride = "CRITTER_" .. string.upper(self.inst.prefab:sub(9)) .. "_SCRAPPY"
    elseif self.pet_type == "CRAFTY" then
        -- 灵巧外观
        self.inst.components.inspectable.nameoverride = "CRITTER_" .. string.upper(self.inst.prefab:sub(9)) .. "_CRAFTY"
    elseif self.pet_type == "PEPPY" then
        -- 俏皮外观
        self.inst.components.inspectable.nameoverride = "CRITTER_" .. string.upper(self.inst.prefab:sub(9)) .. "_PEPPY"
    elseif self.pet_type == "PLUMP" then
        -- 吃饱喝足外观
        self.inst.components.inspectable.nameoverride = "CRITTER_" .. string.upper(self.inst.prefab:sub(9)) .. "_PLUMP"
    else
        -- 中立型外观（恢复默认）
        self.inst.components.inspectable.nameoverride = nil
    end
end

function PetAdaptation:OnSave()
    return {
        pet_type = self.pet_type,
        scrappy_level = self.scrappy_level,
        crafty_level = self.crafty_level,
        peppy_level = self.peppy_level,
        plump_level = self.plump_level
    }
end

function PetAdaptation:OnLoad(data)
    if data then
        self.pet_type = data.pet_type or "NEUTRAL"
        self.scrappy_level = data.scrappy_level or 0
        self.crafty_level = data.crafty_level or 0
        self.peppy_level = data.peppy_level or 0
        self.plump_level = data.plump_level or 0
        
        -- 重新计算加成
        self:CalculateBonus()
    end
end

function PetAdaptation:OnInit()
    -- 初始化时设置默认值
    self.pet_type = "NEUTRAL"
    self.scrappy_level = 0
    self.crafty_level = 0
    self.peppy_level = 0
    self.plump_level = 0
    self.combat_bonus = 0
    self.work_bonus = 0
    self.sanity_bonus = 0
    self.hunger_bonus = 0
    
    -- 计算初始加成
    self:CalculateBonus()
end

return PetAdaptation 