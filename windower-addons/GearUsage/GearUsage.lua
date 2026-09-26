_addon.name = 'GearUsage'
_addon.author = 'AI'
_addon.version = '1.0'
_addon.commands = {'gearusage', 'gu'}

local res = require('resources')
local config = require('config')

local default_settings = {
    usage = {}, -- [tostring(item_id)] = {count=N, last=timestamp, en=..., ja=...}
}
local settings = config.load(default_settings, true) -- per-character

settings.usage = settings.usage or {}

local EQUIP_SLOTS = {
    'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet',
    'neck', 'waist', 'left_ear', 'right_ear', 'left_ring', 'right_ring', 'back',
}

local WARDROBE_BAGS = {
    'wardrobe', 'wardrobe2', 'wardrobe3', 'wardrobe4',
    'wardrobe5', 'wardrobe6', 'wardrobe7', 'wardrobe8',
}

local previous_equipped = {}

-- FFXIのアイテムフラグ: 0x8000=レア, 0x4000=EX(交換不可)
local FLAG_RARE = 0x8000
local FLAG_EX = 0x4000

local function rare_ex_label(item_res)
    if not item_res or not item_res.flags then return '' end
    local flags = item_res.flags
    local is_rare = bit.band(flags, FLAG_RARE) ~= 0
    local is_ex = bit.band(flags, FLAG_EX) ~= 0
    if is_rare and is_ex then return 'レア/EX' end
    if is_rare then return 'レア' end
    if is_ex then return 'EX' end
    return ''
end

local function get_equipped_item_id(equip, slot_name)
    local bag_id = equip[slot_name .. '_bag']
    local slot_index = equip[slot_name]
    if not bag_id or not slot_index or slot_index == 0 then
        return nil
    end
    local item_data = windower.ffxi.get_items(bag_id, slot_index)
    if item_data and item_data.id and item_data.id ~= 0 then
        return item_data.id
    end
    return nil
end

local function record_usage(item_id)
    local key = tostring(item_id)
    local entry = settings.usage[key]
    if not entry then
        local item_res = res.items[item_id]
        entry = {
            count = 0,
            last = 0,
            en = item_res and item_res.en or ('Unknown#' .. item_id),
            ja = item_res and item_res.ja or '',
        }
        settings.usage[key] = entry
    end
    entry.count = entry.count + 1
    entry.last = os.time()
end

local function check_equipment_changes()
    local items = windower.ffxi.get_items()
    if not items or not items.equipment then return end
    local equip = items.equipment

    for _, slot_name in ipairs(EQUIP_SLOTS) do
        local item_id = get_equipped_item_id(equip, slot_name)
        if item_id and item_id ~= previous_equipped[slot_name] then
            record_usage(item_id)
        end
        previous_equipped[slot_name] = item_id
    end
end

local function poll_loop()
    check_equipment_changes()
    coroutine.schedule(poll_loop, 5)
end

local function autosave_loop()
    config.save(settings)
    coroutine.schedule(autosave_loop, 60)
end

windower.register_event('incoming chunk', function(id, data)
    if id == 0x050 then
        coroutine.schedule(check_equipment_changes, 0.3)
    end
end)

windower.register_event('login', function()
    coroutine.schedule(check_equipment_changes, 2.0)
    coroutine.schedule(poll_loop, 5)
    coroutine.schedule(autosave_loop, 60)
end)

windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        check_equipment_changes()
        coroutine.schedule(poll_loop, 5)
        coroutine.schedule(autosave_loop, 60)
    end
end)

local function get_wardrobe_item_ids()
    local items = windower.ffxi.get_items()
    local ids = {}
    for _, bag_name in ipairs(WARDROBE_BAGS) do
        local bag = items[bag_name]
        if bag then
            for i = 1, #bag do
                local slot_data = bag[i]
                if slot_data and slot_data.id and slot_data.id ~= 0 then
                    table.insert(ids, slot_data.id)
                end
            end
        end
    end
    return ids
end

local function sorted_usage_list()
    local list = {}
    for key, entry in pairs(settings.usage) do
        table.insert(list, {
            id = tonumber(key), count = entry.count, last = entry.last,
            en = entry.en, ja = entry.ja,
        })
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list
end

local function show_top(n)
    n = n or 10
    local list = sorted_usage_list()
    windower.add_to_chat(207, windower.to_shift_jis(string.format('GearUsage: 使用回数ランキング TOP%d', n)))
    for i = 1, math.min(n, #list) do
        local e = list[i]
        windower.add_to_chat(207, windower.to_shift_jis(string.format('  %d位  %s (%s)  %d回', i, e.en, e.ja, e.count)))
    end
    if #list == 0 then
        windower.add_to_chat(207, windower.to_shift_jis('  記録がまだありません。装備を切り替えると記録が始まります。'))
    end
end

local function show_wardrobe()
    local ward_ids = get_wardrobe_item_ids()
    local seen = {}
    local list = {}
    for _, id in ipairs(ward_ids) do
        if not seen[id] then
            seen[id] = true
            local entry = settings.usage[tostring(id)]
            local item_res = res.items[id]
            table.insert(list, {
                id = id,
                count = entry and entry.count or 0,
                en = item_res and item_res.en or ('Unknown#' .. id),
                ja = item_res and item_res.ja or '',
                rare_ex = rare_ex_label(item_res),
            })
        end
    end
    table.sort(list, function(a, b) return a.count < b.count end)
    windower.add_to_chat(207, windower.to_shift_jis('GearUsage: モグワードローブ内 使用回数(少ない順)'))
    windower.add_to_chat(207, windower.to_shift_jis('  ※レア/EXは売却不可(いらなければ削除のみ可能)'))
    for _, e in ipairs(list) do
        local unused_tag = (e.count == 0) and '【未使用】' or ''
        local flag_tag = (e.rare_ex ~= '') and ('[' .. e.rare_ex .. ']') or ''
        windower.add_to_chat(207, windower.to_shift_jis(string.format('  %s (%s) %s  %d回 %s', e.en, e.ja, flag_tag, e.count, unused_tag)))
    end
    windower.add_to_chat(207, windower.to_shift_jis(string.format('合計 %d 種類', #list)))
end

local function export_csv()
    windower.create_dir(windower.addon_path .. 'data')
    local player = windower.ffxi.get_player()
    local charname = player and player.name or 'unknown'
    local path = windower.addon_path .. 'data/' .. charname .. '_gearusage.csv'
    local file = io.open(path, 'w')
    if not file then
        windower.add_to_chat(207, windower.to_shift_jis('GearUsage: ファイル書き出しに失敗しました: ' .. path))
        return
    end
    local ward_ids = {}
    for _, id in ipairs(get_wardrobe_item_ids()) do ward_ids[id] = true end

    file:write('\239\187\191') -- UTF-8 BOM (Excel文字化け対策)
    file:write('item_id,en,ja,count,last_used,rare_ex,in_wardrobe\n')
    local list = sorted_usage_list()
    for _, e in ipairs(list) do
        local last_str = (e.last and e.last > 0) and os.date('%Y-%m-%d %H:%M:%S', e.last) or ''
        local rare_ex = rare_ex_label(res.items[e.id])
        local in_wardrobe = ward_ids[e.id] and 'yes' or 'no'
        file:write(string.format('%d,"%s","%s",%d,%s,%s,%s\n', e.id, e.en, e.ja, e.count, last_str, rare_ex, in_wardrobe))
    end
    file:close()
    windower.add_to_chat(207, windower.to_shift_jis('GearUsage: CSVを書き出しました: ' .. path))
end

windower.register_event('unload', function()
    config.save(settings)
    export_csv()
end)

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower()

    if command == 'top' then
        show_top(tonumber(args[1]) or 10)
    elseif command == 'wardrobe' then
        show_wardrobe()
    elseif command == 'export' then
        export_csv()
    elseif command == 'reset' then
        settings.usage = {}
        config.save(settings)
        windower.add_to_chat(207, windower.to_shift_jis('GearUsage: 集計をリセットしました。'))
    else
        windower.add_to_chat(207, windower.to_shift_jis('GearUsage コマンド一覧:'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gu top [n]   : 使用回数の多い順に表示 (既定10件)'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gu wardrobe  : モグワードローブ内の装備を使用回数の少ない順に表示'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gu export    : CSVファイルに書き出し'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gu reset     : 集計をリセット'))
    end
end)
