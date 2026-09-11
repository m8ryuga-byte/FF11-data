_addon.name = 'GariCounter'
_addon.author = 'AI'
_addon.version = '1.0'
_addon.commands = {'garicounter', 'gari'}

local texts = require('texts')
local config = require('config')

local default_settings = {
    pos = {x = 500, y = 200},
}
local settings = config.load(default_settings)

local display = texts.new('${content}')
display.content = 'GariCounter Loading...'
display:font('Meiryo')
display:size(10)
display:bold(true)
display:color(255, 255, 255)
display:bg_alpha(150)
display:bg_color(0, 0, 0)

local px = tonumber(settings.pos.x) or 500
local py = tonumber(settings.pos.y) or 200
display:pos(px, py)

local session_total = 0
local session_start = nil
local current_total = nil
local last_gain = 0

local function format_number(n)
    local formatted = string.format('%d', math.floor(n))
    local sign = ''
    if formatted:sub(1, 1) == '-' then
        sign = '-'
        formatted = formatted:sub(2)
    end
    while true do
        local new_formatted, count = formatted:gsub('^(%d+)(%d%d%d)', '%1,%2')
        formatted = new_formatted
        if count == 0 then break end
    end
    return sign .. formatted
end

local function update_display()
    local lines = {}
    table.insert(lines, '◆ガリモーフリー獲得カウンター')
    table.insert(lines, string.format('今回のソーティ　+%s', format_number(session_total)))
    if last_gain > 0 then
        table.insert(lines, string.format('直近　　　　　+%s', format_number(last_gain)))
    end
    if current_total then
        table.insert(lines, string.format('所持合計　　　%s', format_number(current_total)))
    end
    if session_start then
        local elapsed_sec = os.time() - session_start
        if elapsed_sec > 0 then
            local mm = math.floor(elapsed_sec / 60)
            local ss = elapsed_sec % 60
            local per_hour = session_total / elapsed_sec * 3600
            table.insert(lines, '----------------------')
            table.insert(lines, string.format('経過　%d分%02d秒', mm, ss))
            table.insert(lines, string.format('時速換算　%s/h', format_number(per_hour)))
        end
    end
    display.content = table.concat(lines, '\n')
end

local function reset_session()
    session_total = 0
    session_start = os.time()
    last_gain = 0
    update_display()
end

windower.register_event('incoming text', function(original, modified, original_mode, modified_mode, blocked)
    local text = windower.from_shift_jis(original)

    if text:find('『ソーティ』に進入します') then
        reset_session()
        windower.add_to_chat(207, windower.to_shift_jis('GariCounter: ソーティ入場を検知、カウンターをリセットしました。'))
        return
    end

    local gain, total = text:match('ガリモーフリーを(%d+)得た、(%d+)になった')
    if gain then
        gain = tonumber(gain)
        total = tonumber(total)
        if not session_start then
            session_start = os.time()
        end
        session_total = session_total + gain
        last_gain = gain
        current_total = total
        update_display()
    end
end)

windower.register_event('login', function()
    display:show()
    update_display()
end)

windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        display:show()
        update_display()
    end
end)

windower.register_event('unload', function()
    if display then
        display:destroy()
    end
end)

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower()

    if command == 'reset' then
        reset_session()
        windower.add_to_chat(207, windower.to_shift_jis('GariCounter: カウンターをリセットしました。'))
    elseif command == 'pos' and args[1] and args[2] then
        local nx = tonumber(args[1])
        local ny = tonumber(args[2])
        if nx and ny then
            settings.pos.x = nx
            settings.pos.y = ny
            config.save(settings)
            display:pos(nx, ny)
        end
    elseif command == 'show' then
        display:show()
    elseif command == 'hide' then
        display:hide()
    else
        windower.add_to_chat(207, windower.to_shift_jis('GariCounter コマンド一覧:'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gari reset      : 今回のカウントをリセット'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gari pos [x] [y]: 表示位置を変更'))
        windower.add_to_chat(207, windower.to_shift_jis('  //gari show/hide  : 表示のオン/オフ'))
    end
end)
