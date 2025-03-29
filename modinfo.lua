name = "随机食物"
description = "烹饪锅煮出来的食谱食物会变成随机的食谱食物，每次都是惊喜！哈哈哈，给大厨更多惊喜。"
author = "Va6gn（凌）"
version = "1.0.0"

-- 兼容性
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- 客户端/服务器兼容性
client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

-- 图标
icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- 配置选项
configuration_options = {
    {
        name = "random_type",
        label = "随机类型",
        options = {
            {description = "完全随机", data = "full_random"},
            {description = "同类型随机", data = "same_category"},
            {description = "同价值随机", data = "same_value"}
        },
        default = "full_random",
    },
    {
        name = "show_original",
        label = "显示原始食物",
        options = {
            {description = "是", data = true},
            {description = "否", data = false}
        },
        default = true,
    },
    {
        name = "random_chance",
        label = "随机概率",
        options = {
            {description = "25%", data = 0.25},
            {description = "50%", data = 0.5},
            {description = "75%", data = 0.75},
            {description = "100%", data = 1.0}
        },
        default = 1.0,
    }
} 