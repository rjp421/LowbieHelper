local lh_gui = gui.get_tab("LowbieHelper")

-- thanks to the team at YumMenu Extras Addon LUA Script for some of this as a base
local addonVersion = "0.0.1"

local helpPlayers = {}


-- Function to create a text element
function createText(tab, text)
    lh_gui:add_text(text)
end

function sleep(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        -- Yield the CPU to avoid high CPU usage during the delay
        coroutine.yield()
    end
end

function toolTip(tab, text, seperate)
    seperate = seperate or false
    if tab == "" then
        if seperate then --waiting approval
            ImGui.SameLine()
            ImGui.TextDisabled("(?)")
        end
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
      ImGui.Text(text)
            ImGui.EndTooltip()
        end
    else
        lh_gui:add_imgui(function()
            if seperate then
                ImGui.SameLine()
                ImGui.TextDisabled("(?)")
            end
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(text)
                ImGui.EndTooltip()
            end
        end)
    end
end

function newText(tab, text, size)
    size = size or 1
    lh_gui:add_imgui(function()
        ImGui.SetWindowFontScale(size)
        ImGui.Text(text)
        ImGui.SetWindowFontScale(1)
    end)
end

newText(lh_gui, "Welcome to LowbieHelper v"..addonVersion, 1)
createText(lh_gui, "Happy to help :)")
lh_gui:add_separator()


lhEnabled = lh_gui:add_checkbox("LH Enabled")
toolTip(lh_gui, "Detect lowbies/poor in the session")
lhEnabled:set_enabled(true)

lh_gui:add_sameline()
lhAnnounce = lh_gui:add_checkbox("Announce")
toolTip(lh_gui, "Announce help to the player")
lh_gui:add_sameline()
lhLoop = lh_gui:add_checkbox("Loop")
toolTip(lh_gui, "Loop detection")

lh_gui:add_separator()
local allowedMaxMoneyInput = lh_gui:add_input_int("Max money")
toolTip(lh_gui, "Maximum money allowed before helping")
allowedMaxMoneyInput:set_value(500000)
local allowedMaxRankInput = lh_gui:add_input_int("Max rank")
toolTip(lh_gui, "Maximum rank allowed before helping")
allowedMaxRankInput:set_value(50)




function lhCheck()
    --local allowedMaxMoney = allowedMaxMoneyInput:get_value()
    --local targetPlayerRank = allowedMaxRankInput:get_value()
    local localPlayerID = PLAYER.PLAYER_ID()
    --log.info("[LowbieHelper]  allowedMaxMoney: "..allowedMaxMoneyInput:get_value().."  allowedMaxRank: "..allowedMaxRankInput:get_value())
    
    -- reset the array
    --helpPlayers = 'nil'
    --helpPlayers = {}

    -- Identify lowbies and store their IDs
    for i = 0, 31 do
        local pid = i
        local targetPlayerName = PLAYER.GET_PLAYER_NAME(pid)
        if targetPlayerName ~= '**Invalid**' and pid ~= localPlayerID then
            local hpIndex = getHelpPlayerIndex(pid)
            local isHelpable = isPlayerHelpable(pid)
            local targetPlayerWallet = network.get_player_wallet(pid)
            local targetPlayerBank = network.get_player_bank(pid)
            local targetPlayerRank = network.get_player_rank(pid)
            local targetPlayerRP = network.get_player_rp(pid)
            local langid = network.get_player_language_id(pid)
            local lang = network.get_player_language_name(pid)
            local detect = network.is_player_flagged_as_modder(pid)
            local reason = network.get_flagged_modder_reason(pid)
            local targetPlayerMoney = targetPlayerWallet+targetPlayerBank
            -- if player is clean
            --if lang == "Chinese" or lang == "Chinese (Traditional)" or lang == "Chinese (Simplified)" or lang == "Chinese (Simpified)" then
            if not detect and not string.find(lang,"Chinese",1) and (targetPlayerMoney > 0) then
                -- need a better way to tell when a player has fully joined
                --if ((targetPlayerWallet > 0) and (targetPlayerBank > 0) and (targetPlayerMoney > 0)) or ((targetPlayerRank ~= 0) and (targetPlayerRP ~= 0)) then
                --if targetPlayerMoney > 0 then
                    --log.info("[LowbieHelper]  "..targetPlayerName.."  PID:"..pid.."  Wallet: "..targetPlayerWallet.."  Bank: "..targetPlayerBank.."  Money: "..targetPlayerMoney.."  Rank: "..targetPlayerRank.."  RP: "..targetPlayerRP)
                    -- if player is poor or low rank
                    if hpIndex and not isHelpable then
                        gui.show_message("LowbieHelper:lhCheck", "REMOVING  pid="..pid.."  name="..targetPlayerName.."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
                        log.info("[LowbieHelper:lhCheck]  REMOVING  pid="..pid.."  name="..targetPlayerName.."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
                        table.remove(helpPlayers,hpIndex)
                    elseif isHelpable and not hpIndex then
                        --gui.show_message("LowbieHelper", "LOWBIE DETECTED:  ["..targetPlayerName.."]  PID:"..pid.. "  Money: "..targetPlayerMoney.."  Rank: "..targetPlayerRank)
                        gui.show_message("LowbieHelper", "ADDING  "..pid..","..targetPlayerName.."  Wallet: "..targetPlayerWallet.."  Bank: "..targetPlayerBank.."  Money: "..targetPlayerMoney.."  Rank: "..targetPlayerRank.."  #helpPlayers: "..#helpPlayers)
                        log.info("[LowbieHelper:lhCheck]  ADDING  "..pid..","..targetPlayerName.."  Wallet: "..targetPlayerWallet.."  Bank: "..targetPlayerBank.."  Money: "..targetPlayerMoney.."  Rank: "..targetPlayerRank.."  #helpPlayers: "..#helpPlayers)
                        table.insert(helpPlayers, {pid,targetPlayerName,0})
                    end
                --end
            end
        end
    end
    --log.info("[LowbieHelper]  lhCheck finished,  #helpPlayers: "..#helpPlayers)
end

function getHelpPlayerIndex(pid)
    for k,v in pairs(helpPlayers) do
        if pid == v[1] then
            return k
        end
    end
    -- else
    return nil
end

function isPlayerHelpable(pid)
    local targetPlayerWallet = network.get_player_wallet(pid)
    local targetPlayerBank = network.get_player_bank(pid)
    local targetPlayerRank = network.get_player_rank(pid)
    local targetPlayerRP = network.get_player_rp(pid)
    local targetPlayerMoney = targetPlayerWallet+targetPlayerBank
    --log.info("[LowbieHelper:isPlayerHelpable]  pid: "..pid.."  targetPlayerMoney: "..targetPlayerMoney.."  allowedMaxMoney: "..allowedMaxMoneyInput:get_value().."  targetPlayerRank: "..targetPlayerRank.."  allowedMaxRank: "..allowedMaxRankInput:get_value())
    if targetPlayerMoney == 0 or (targetPlayerMoney >= allowedMaxMoneyInput:get_value() and targetPlayerRank >= allowedMaxRankInput:get_value()) then
        return false
    elseif ((targetPlayerWallet > 0) and (targetPlayerBank > 0) and (targetPlayerMoney > 0)) or ((targetPlayerRank ~= 0) and (targetPlayerRP ~= 0)) then
        return true
    end
end

function lhHelpPlayers()
    for k, v in pairs(helpPlayers) do
        local pid = v[1]
        if PLAYER.GET_PLAYER_PED(pid) == PLAYER.PLAYER_PED_ID() then
            gui.show_message("LowbieHelper:lhHelpPlayers", "The target has been detected to have left or the target is you")
            return
        end
        local targetPlayerName = v[2]
        local targetPlayerWallet = network.get_player_wallet(pid)
        local targetPlayerBank = network.get_player_bank(pid)
        local targetPlayerRank = network.get_player_rank(pid)
        local targetPlayerRP = network.get_player_rp(pid)
        local targetPlayerMoney = targetPlayerWallet+targetPlayerBank
        -- remove if no longer eligable
        if not isPlayerHelpable(pid) then
            gui.show_message("LowbieHelper:lhHelpPlayers", "REMOVING  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
            log.info("[LowbieHelper:lhHelpPlayers]  REMOVING  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
            table.remove(helpPlayers,k)
        else
            log.info("[LowbieHelper:lhHelpPlayers]  HELPING  pid = "..pid.."  name: "..v[2].."  timesHelped="..v[3].."  #helpPlayers: "..#helpPlayers)
            -- TODO does player need mostly money or RP?
            if targetPlayerMoney < allowedMaxMoneyInput:get_value() or targetPlayerRank <=20 then
                -- player needs money
                -- TODO separate into a function?
                script.run_in_fiber(function(tse)
                    --tse:yield()
                    for i = 0, 9 do
                        for j = 0, 20 do
                            network.trigger_script_event(1 << pid, {968269233, pid, 0, i, j, j, j})
                            for n = 0, 16 do
                                network.trigger_script_event(1 << pid, {968269233, pid, n, i, j, j, j})
                            end
                        end
                        network.trigger_script_event(1 << pid, {968269233, pid, 1, i, 1, 1, 1})
                        network.trigger_script_event(1 << pid, {968269233, pid, 3, i, 1, 1, 1})
                        network.trigger_script_event(1 << pid, {968269233, pid, 10, i, 1, 1, 1})
                        network.trigger_script_event(1 << pid, {968269233, pid, 0, i, 1, 1, 1})
                        tse:yield()
                    end
                    log.info("[LowbieHelper:lhHelpPlayers]  Blessed "..pid..","..v[2].." with 25k RP (1 time)".."  timesHelped="..v[3])
                    gui.show_message("LowbieHelper:lhHelpPlayers", "Helped "..targetPlayerName.." with 25k / RP (1 time)".."  timesHelped="..v[3])
                    if lhAnnounce:is_enabled() and v[3] == 0 then
                        network.send_chat_message_to_player(pid, "[LowbieHelper]  "..targetPlayerName..", You have been blessed with RP + 25k (1 time)!")
                    end
                    --sleep(1)
                end)
            elseif targetPlayerRank < allowedMaxRankInput:get_value() then
                -- player needs rp
                -- TODO
                    log.info("[LowbieHelper:lhHelpPlayers]  NEEDS RP "..pid..","..v[2].."  targetPlayerRank: "..targetPlayerRank.."  timesHelped="..v[3])
                    gui.show_message("LowbieHelper:lhHelpPlayers", "NEEDS RP "..targetPlayerName.."  targetPlayerRank: "..targetPlayerRank.."  timesHelped="..v[3])
            end
            -- TODO set timesHelped
            local timesHelped = v[3]+1
            -- remove the player helped from the array
            -- TEST move current item to the end of the array
            table.remove(helpPlayers,k)
            table.insert(helpPlayers, {pid,targetPlayerName,timesHelped})
        end
        -- only run once, TODO fix
        return
    end
end


script.register_looped("lhEnabled", function(script)
    -- sleep until next game frame
    script:yield()
    if lhEnabled:is_enabled() and lhLoop:is_enabled() then 
        lhCheck()
        lhHelpPlayers()
        -- sleep until next game frame
        script:yield()
    end
end)



lh_gui:add_separator()
lh_gui:add_button("Check now!", function ()
    if lhEnabled:is_enabled() then 
        log.info("[LH]  Checking!")
        gui.show_message("LH", "Checking!")
        lhCheck()
    end
end)

lh_gui:add_sameline()
lh_gui:add_button("Print Array", function()
    log.info("[LowbieHelper:PrintArray]  #helpPlayers: "..#helpPlayers)
    for k,v in pairs(helpPlayers) do
        local pid = v[1]
        local targetPlayerWallet = network.get_player_wallet(pid)
        local targetPlayerBank = network.get_player_bank(pid)
        local targetPlayerRank = network.get_player_rank(pid)
        local targetPlayerMoney = targetPlayerWallet+targetPlayerBank
        gui.show_message("LowbieHelper:PrintArray", "k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank.."  rp="..network.get_player_rp(v[1]))
        log.info("[LowbieHelper:PrintArray]  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank.."  rp="..network.get_player_rp(v[1]))
        if not isPlayerHelpable(pid) then
            gui.show_message("LowbieHelper:PrintArray", "REMOVING  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
            log.info("[LowbieHelper:PrintArray]  REMOVING  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3].."  wallet="..targetPlayerWallet.."  bank="..targetPlayerBank.."  targetPlayerMoney: "..targetPlayerMoney.."  rank="..targetPlayerRank)
            table.remove(helpPlayers,k)
        end
    end
end)

lh_gui:add_sameline()
lh_gui:add_button("Help", function()
    lhHelpPlayers()
end)
toolTip(lh_gui, "Gives players some Money / RP")


lh_gui:add_separator()
createText(lh_gui, "Selected player:")

lh_gui:add_button("Give Ammo", function()
    local pid = network.get_selected_player()
    log.info("[LowbieHelper:GiveAmmo]  GIVING AMMO to "..PLAYER.GET_PLAYER_NAME(pid))
    for k,v in pairs(helpPlayers) do
        gui.show_message("LowbieHelper:GiveAmmo", "k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3])
        log.info("[LowbieHelper:GiveAmmo]  k="..tostring(k).."  pid="..pid.."  name="..v[2].."  timesHelped="..v[3])
    end
    for k,v in pairs(command.get_all_player_command_names()) do
        log.info("[LowbieHelper:GiveAmmo]  [commands]  "..tostring(k).."\t"..v)
    end
    --command.call_player(pid, "giveammo") -- CRASHES
    --[[script.run_in_fiber(function(giveAmmo)
        --command.call("giveammoall")
        giveAmmo:yield()
    end)]] -- ALSO CRASHES
end)
toolTip(lh_gui, "Gives players ammo [NYI]")


lh_gui:add_separator()
createText(lh_gui, "Loops:")

lh_fastRP = lh_gui:add_checkbox("Super Fast RP")
script.register_looped("lh_fastRP", function(script)
    -- sleep until next game frame
    script:yield()
    if lh_fastRP:is_enabled() == true then
        local pid = network.get_selected_player()
        if not isPlayerHelpable(pid) then
            return
        end
        if PLAYER.GET_PLAYER_PED(network.get_selected_player()) == PLAYER.PLAYER_PED_ID() then
            gui.show_message("Super Fast RP", "RP Stopped, player has left the session.")
            lh_fastRP:set_enabled(false)
            return
        end
        for i = 0, 24 do
            network.trigger_script_event(1 << pid, {968269233 , pid, 1, 4, i, 1, 1, 1, 1})
        end
    end
end)
toolTip(lh_gui, "Remotely floods the selected player with RP (about 1 level/sec)")

lh_gui:add_sameline()
lh_ezMoney = lh_gui:add_checkbox("Money ($225k)")
script.register_looped("lh_ezMoney", function(script)
    -- sleep until next game frame
    script:yield()
    if lh_ezMoney:is_enabled() == true then
        local pid = network.get_selected_player()
        if not isPlayerHelpable(pid) then
            return
        end
        if PLAYER.GET_PLAYER_PED(network.get_selected_player()) == PLAYER.PLAYER_PED_ID() then
            gui.show_message("Money ($225k)","Money Stopped, player has left the session.")
            lh_ezMoney:set_enabled(false)
            return
        end
        for n = 0, 10 do
            for l = -10, 10 do
                network.trigger_script_event(1 << pid, {968269233 , pid, 1, l, l, n, 1, 1, 1})
            end
        end
    end
end)
toolTip(lh_gui, "Sometimes works, sometimes doesn't.  Up to 225k")



event.register_handler(menu_event.PlayerLeave, function (playerName)
    --log.info("Player "..playerName.." left")
    -- exit if array is empty
    if not helpPlayers[1] then
        return
    end
    for k,v in pairs(helpPlayers) do
        if v[2] == playerName then
            table.remove(helpPlayers,k)
        end
    end
end)

event.register_handler(menu_event.PlayerMgrInit, function ()
    --log.info("Player manager inited, we just joined a session.")
    -- TODO recreate the array(s)
    helpPlayers = 'nil'
    helpPlayers = {}
end)

event.register_handler(menu_event.PlayerMgrShutdown, function ()
    helpPlayers = 'nil'
    helpPlayers = {}
end)
