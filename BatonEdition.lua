require "lib.moonloader"
local   ev          = require 'samp.events'
local   imgui       = require 'imgui'
local   inicfg      = require 'inicfg'
local   updater     = require 'update_helper'

script_name('BatonEdition')
script_version('1.0.1')
script_author('Your Name')

-- Auto-update settings
local update_url = 'https://raw.githubusercontent.com/pv9kznsnwy-boop/BatonEtition/main/BatonEdition.lua'
local version_url = 'https://raw.githubusercontent.com/pv9kznsnwy-boop/BatonEtition/main/version.txt'
local update_available = false
local new_version = ''

--VARIABLES
local sw, sh = getScreenResolution() 
local  active_obrez = false
local work = false

local fix = false

-- Timer variables
local timer_end_time = 0
local remaining_minutes = 0
local timer_paused = false
local pause_time = 0

local cfg = inicfg.load({
    obrez = {
        obrez = false, 
        birth = false
    },
    timer = {
        end_time = 0
    },
    settings = {
        auto_work = false
    },
    stats = {
        opened_count = 0
    }
}, 'opening_obrez')

if not doesFileExist('opening_obrez.ini') then
    inicfg.save(cfg, 'opening_obrez.ini')
end

-- Load saved timer
local timer_loaded = false
if cfg.timer and cfg.timer.end_time > 0 then
    timer_end_time = cfg.timer.end_time
    timer_loaded = true
end

local checkbox_obrez    = imgui.ImBool(cfg.obrez.obrez)
local checkbox_auto     = imgui.ImBool(cfg.settings.auto_work)
local main_window       = imgui.ImBool(false)

local textdraw = {
    [1] = {2124, 2301, 2000},
}


function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(80) end
    
    wait(10000) -- Delay 10 seconds after connecting to server
    
    -- Wait for player to spawn
    repeat wait(100) until sampIsLocalPlayerSpawned()
    wait(1000)
    
    sampAddChatMessage('[BatonEdition] Script loaded!', 0x0DFF00)
    
    -- Check for updates (always enabled)
    lua_thread.create(function()
        wait(3000)
        updater.checkUpdate(version_url, script_version(), function(has_update, version)
            if has_update then
                update_available = true
                new_version = version
                sampAddChatMessage('[BatonEdition] Update available: v' .. version, 0xFFFF00)
                sampAddChatMessage('[BatonEdition] Open /obrez menu to update', 0xFFFF00)
            end
        end)
    end)
    
    -- Check saved timer after spawn
    if timer_loaded and cfg.settings.auto_work then
        local current_time = os.time()
        if timer_end_time > current_time then
            remaining_minutes = math.ceil((timer_end_time - current_time) / 60)
            sampAddChatMessage('[BatonEdition] Timer: ' .. remaining_minutes .. ' min left. Opening...', 0x0DFF00)
            work = true
        else
            timer_end_time = 0
            cfg.timer.end_time = 0
            inicfg.save(cfg, 'opening_obrez.ini')
        end
    end
    
    sampRegisterChatCommand('obrez', 
    function()
        main_window.v = not main_window.v 
        imgui.Process = main_window.v
    end)

    while true do
        wait(0)

        -- Auto timer check
        if work and timer_end_time > 0 then
            local current_time = os.time()
            if current_time >= timer_end_time then
                timer_end_time = 0
                remaining_minutes = 0
                cfg.timer.end_time = 0
                inicfg.save(cfg, 'opening_obrez.ini')
            else
                remaining_minutes = math.ceil((timer_end_time - current_time) / 60)
            end
        end

        if work then 
            sampSendClickTextdraw(65535)
            wait(355)
            fix = true
            fix = false
            sampSendChat('/invent')
            wait(400)
            for i = 1, 1 do
                if not work then break end
                sampSendClickTextdraw(textdraw[1][1])
                wait(1000)
                sampSendClickTextdraw(textdraw[1][2])
                wait(1000)
            end
            wait(100)
            sampSendClickTextdraw(65535)
            
            -- Use remaining minutes if available, otherwise default 60 minutes
            local wait_time = remaining_minutes > 0 and remaining_minutes or 60
            if wait_time > 0 then
                wait(wait_time * 60000)
            end
        end

    end
end
    
function imgui.TextQuestion(text)
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip() 
    end 
end

function imgui.OnDrawFrame()
    if not main_window.v then imgui.Process = false end
    if main_window.v then
    -- Update remaining time in real-time
    if timer_end_time > 0 then
        local current_time = os.time()
        if current_time >= timer_end_time then
            timer_end_time = 0
            remaining_minutes = 0
            cfg.timer.end_time = 0
            inicfg.save(cfg, 'opening_obrez.ini')
        else
            remaining_minutes = math.ceil((timer_end_time - current_time) / 60)
        end
    end
    
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 , sh / 2), imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(430, 230), imgui.Cond.FirstUseEver)
    imgui.Begin('BatonEdition', main_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
    imgui.Checkbox(' Open obrez', checkbox_obrez)
    if checkbox_obrez.v then 
        cfg.opening_obrez = true
        inicfg.save(cfg, 'opening_obrez.ini')
    else
        cfg.opening_obrez = false
        inicfg.save(cfg, 'opening_obrez.ini')
    end
    
    imgui.Checkbox(' Auto work on timer', checkbox_auto)
    if checkbox_auto.v then 
        cfg.settings.auto_work = true
        inicfg.save(cfg, 'opening_obrez.ini')
    else
        cfg.settings.auto_work = false
        inicfg.save(cfg, 'opening_obrez.ini')
    end
    
    -- Show remaining time
    if remaining_minutes > 0 then
        imgui.TextColored(imgui.ImVec4(1.0, 0.6, 0.0, 1.0), 'Left: ' .. remaining_minutes .. ' min')
    end
    
    -- Show opened count
    imgui.TextColored(imgui.ImVec4(0.5, 1.0, 0.5, 1.0), 'Opened: ' .. cfg.stats.opened_count)
    
    -- Show update button if available
    if update_available then
        imgui.TextColored(imgui.ImVec4(1.0, 1.0, 0.0, 1.0), 'Update available: v' .. new_version)
        if imgui.Button('Update Now', imgui.ImVec2(100, 25)) then
            sampAddChatMessage('[BatonEdition] Downloading update...', 0xFFFF00)
            updater.downloadUpdate(update_url, thisScript().path, function(success)
                if success then
                    sampAddChatMessage('[BatonEdition] Updated! Reloading...', 0x0DFF00)
                    thisScript():reload()
                else
                    sampAddChatMessage('[BatonEdition] Update failed!', 0xFF0000)
                end
            end)
        end
    end
    
    imgui.NewLine()
    if work then 
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.96, 0.16, 0.16, 0.85))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.85, 0.12, 0.12, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.73, 0.11, 0.11, 1.00))
    else
        local colors = imgui.GetStyle().Colors
        local clr = imgui.Col
        imgui.PushStyleColor(imgui.Col.Button, colors[clr.Button] )
        imgui.PushStyleColor(imgui.Col.ButtonHovered, colors[clr.ButtonHovered])
        imgui.PushStyleColor(imgui.Col.ButtonActive, colors[clr.ButtonActive])
    end
    if imgui.Button((work and 'Stop' or 'Start'), imgui.ImVec2(100, 30)) then 
        if work then 
            work = false
        else
            work = true
        end
    end 

	imgui.Text("BATON PIDARAS")
		
    imgui.PopStyleColor(3)
    imgui.End()
    end
end

function ev.onShowTextDraw(id, data)
    if work then
        if checkbox_obrez.v and data.modelId == 2124 then 
            textdraw[1][1] = id 
        end
        if data.text == 'USE' or data.text == 2301 then 
            textdraw[1][2] = id + 1
        end
    end
end

-- Parse timer from server messages
local function onServerMessageHandler(color, text)
    -- Pause timer on disconnect
    if text:find("Ïîäêëþ÷àåìñÿ ê èãðå") or text:find("???????????? ? ????") then
        if timer_end_time > 0 and not timer_paused then
            timer_paused = true
            pause_time = os.time()
            sampAddChatMessage('[BatonEdition] Timer paused (disconnect)', 0xFFFF00)
        end
        return
    end
    
    -- Resume timer on connect
    if text:find("Äîáðî ïîæàëîâàòü") or text:find("????? ??????????") then
        if timer_paused and timer_end_time > 0 then
            local paused_duration = os.time() - pause_time
            timer_end_time = timer_end_time + paused_duration
            cfg.timer.end_time = timer_end_time
            inicfg.save(cfg, 'opening_obrez.ini')
            timer_paused = false
            sampAddChatMessage('[BatonEdition] Timer resumed', 0x0DFF00)
        end
        return
    end
    
    -- Match cooldown message first (priority)
    local minutes = text:match("(%d+) ìèí")
    if minutes and (text:find("Îøèáêà") or text:find("??????") or text:find("äîëæíî") or text:find("??????")) then
        local mins = tonumber(minutes)
        if mins and mins > 0 and mins < 120 then
            timer_end_time = os.time() + mins * 60
            remaining_minutes = mins
            cfg.timer.end_time = timer_end_time
            inicfg.save(cfg, 'opening_obrez.ini')
            sampAddChatMessage('[BatonEdition] Timer: ' .. remaining_minutes .. ' min', 0x0DFF00)
        end
        return
    end
    
    -- Match success: "áûë äîáàâëåí" (only if no error)
    if (text:find("äîáàâëåí") or text:find("????????")) and not text:find("Îøèáêà") and not text:find("??????") then
        timer_end_time = os.time() + 60 * 60
        remaining_minutes = 60
        cfg.timer.end_time = timer_end_time
        cfg.stats.opened_count = cfg.stats.opened_count + 1
        inicfg.save(cfg, 'opening_obrez.ini')
        sampAddChatMessage('[BatonEdition] Timer: 60 min | Opened: ' .. cfg.stats.opened_count, 0x0DFF00)
    end
end

-- Register event using ev
ev.onServerMessage = function(color, text)
    onServerMessageHandler(color, text)
end

function ev.onShowDialog(dialogId, style, title, b1, b2, text)
    if fix and text:find("  ") then
		sampSendDialogResponse(dialogId, 0, 0, "")
		sampAddChatMessage("{ffffff} inventory {ff0000}fixed{ffffff}!",-1)   
		return false
	end
    if dialogId == 0 and text:find('{ff0000}      ') and work then
        work = false
        main_window.v = false
        sampAddChatMessage('<<WARNING>> {ffffff}   /,   !', 0xff0000)
    end
    if dialogId == 0 and text:find('!') then 
        sampAddChatMessage('[INFORMATION] {FFFFFF}   ,   {FF9A00}4  .', 0x0DFF00)
        sampSendDialogResponse(id, 0, _, _)
        return false
    end
    if dialogId == 0 and text:find('') then 
        sampSendDialogResponse(id, 0, _, _)
        return false
    end
    if dialogId == 0 and text:find(' ') then 
        sampSendDialogResponse(id, 0, _, _)
        return false
    end
end

function BH_theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
 
    style.WindowPadding = ImVec2(6, 4)
    style.WindowRounding = 5.0
    style.ChildWindowRounding = 5.0
    style.FramePadding = ImVec2(5, 2)
    style.FrameRounding = 5.0
    style.ItemSpacing = ImVec2(7, 5)
    style.ItemInnerSpacing = ImVec2(1, 1)
    style.TouchExtraPadding = ImVec2(0, 0)
    style.IndentSpacing = 6.0
    style.ScrollbarSize = 12.0
    style.ScrollbarRounding = 5.0
    style.GrabMinSize = 20.0
    style.GrabRounding = 2.0
    style.WindowTitleAlign = ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.28, 0.30, 0.35, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.16, 0.18, 0.22, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.19, 0.22, 0.26, 1)
    colors[clr.PopupBg]                = ImVec4(0.05, 0.05, 0.10, 0.90)
    colors[clr.Border]                 = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.22, 0.25, 0.30, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.22, 0.25, 0.29, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.19, 0.22, 0.26, 0.59)
    colors[clr.MenuBarBg]              = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.20, 0.25, 0.30, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.49, 0.63, 0.86, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.49, 0.63, 0.86, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.90, 0.90, 0.90, 0.50)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.30)
    colors[clr.SliderGrabActive]       = ImVec4(0.80, 0.50, 0.50, 1.00)
    colors[clr.Button]                 = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.49, 0.62, 0.85, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.49, 0.62, 0.85, 1.00)
    colors[clr.Header]                 = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.22, 0.24, 0.28, 1.00)
    colors[clr.HeaderActive]           = ImVec4(0.22, 0.24, 0.28, 1.00)
    colors[clr.Separator]              = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.49, 0.61, 0.83, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.49, 0.62, 0.83, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.50, 0.63, 0.84, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.16, 0.18, 0.22, 0.76)
end
BH_theme()
