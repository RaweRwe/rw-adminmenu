ESX = nil
local itemList, jobList = {}, {}
RaweAdmin = {}
TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

AddEventHandler('onResourceStart', function()
    MySQL.ready(function ()
        MySQL.Async.fetchAll('SELECT name, label FROM items',{}, function(result)
            itemList = result
        end)

        MySQL.Async.fetchAll('SELECT * FROM jobs ORDER BY name <>  "unemployed", name',{}, function(result)
            for i=1, #result, 1 do
                MySQL.Async.fetchAll('SELECT grade, label FROM job_grades WHERE job_name = @job',{["@job"] = result[i].name}, function(result2)
                    table.insert(jobList, {name = result[i].name, label = result[i].label, ranks = result2})
                end)
            end
        end)
    end)
end)

AddEventHandler("playerConnecting", function(name, setReason, deferrals)
    local player = source
    local identifier
    for k,v in ipairs(GetPlayerIdentifiers(player)) do
        if string.match(v, 'license') then
            identifier = v
            break
        end
    end

    deferrals.defer()
    deferrals.update("Checking Ban Status.")
    
    MySQL.Async.fetchAll('SELECT * FROM bans WHERE license = @license', {
        ['@license'] = identifier
    }, function(result)
        if result[1] then
            if result[1].time ~= 0 then
            	if result[1].time < os.time() then
            		RaweAdmin.Unban(result[1].license)
            		deferrals.done()
            		return
            	end

            	local time = math.floor((result[1].time - os.time()) / 60)
                deferrals.done("[RaweAdmin] Geçici olarak yasaklandınız Süre: "..time.." "..result[1].reason)
            else
                deferrals.done("[RaweAdmin] Şu nedenle kalıcı olarak yasaklandınız: "..result[1].reason)
            end
        else
            deferrals.done()
        end
    end)
end)


--[Fetch User Rank CallBack]
ESX.RegisterServerCallback("esx_marker:fetchUserRank", function(source, cb)
    local player = ESX.GetPlayerFromId(source)

    if player then
        local playerGroup = player.getGroup()

        if playerGroup then 
            cb(playerGroup)
        else
            cb("user")
        end
    else
        cb("user")
    end
end)

ESX.RegisterServerCallback("RaweAdmin:getPlayers", function(source,cb)
    local data = {}
    local xPlayers = ESX.GetPlayers()

    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        data[i] = {
            identifier = xPlayer.getIdentifier(),
            playerid = xPlayers[i],
            group = xPlayer.getGroup(),
    	    rpname = xPlayer.getName(),
    	    cash = xPlayer.getMoney(), 
            bank = xPlayer.getAccount("bank").money,
    	    name = GetPlayerName(xPlayers[i])
        }
    end

    cb(data)
end)

ESX.RegisterServerCallback("RaweAdmin:getItemList", function(source,cb)
    cb(itemList)
 end)

ESX.RegisterServerCallback("RaweAdmin:getBanList", function(source,cb)
    MySQL.Async.fetchAll('SELECT * FROM bans',{}, function(result)
    	for i=1, #result, 1 do
    		result[i].time = math.floor((result[i].time - os.time()) / 60)
    	end
        	cb(result)
      end)
 end)

ESX.RegisterServerCallback("RaweAdmin:getJobs", function(source,cb)
    cb(jobList)
 end)

RaweAdmin.Kick = function(playerID, reason)
    DropPlayer(playerID, reason)
end

RaweAdmin.Ban = function(playerID, time, reason)
    local xPlayer = ESX.GetPlayerFromId(playerID)
    if time ~= 0 then
    	local timeToSeconds = time * 60
    	time = (os.time() + timeToSeconds)
    end

    MySQL.Async.execute('INSERT INTO bans (license, name, time, reason) VALUES (@license, @name, @time, @reason)',
        {   
            ['license'] = xPlayer.getIdentifier(), 
            ['name'] = GetPlayerName(playerID), 
            ['time'] = time, 
            ['reason'] = reason 
        },
        function(insertId)
            DropPlayer(playerID, "Sunucudan uzaklaştırıldınız")
    end)
end

RaweAdmin.Unban = function(license)
    MySQL.Async.execute('DELETE FROM bans WHERE license = @license',
        {   
            ['license'] = license, 
        },
        function(insertId)
            print("player unbanned")
    end)
end

RaweAdmin.AddWeapon = function(playerID, selectedWeapon, ammo)
    xPlayer = ESX.GetPlayerFromId(playerID)
    if xPlayer.hasWeapon(selectedWeapon) then
        xPlayer.addWeaponAmmo(selectedWeapon, 50)
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Silahınıza cephane eklendi') 
    else
        xPlayer.addWeapon(selectedWeapon, ammo)
        TriggerClientEvent('esx:showNotification', xPlayer.source, ESX.GetWeaponLabel(selectedWeapon)..' sana verildi.') 
    end
end

RaweAdmin.AddCash = function(playerID, amount)
    xPlayer = ESX.GetPlayerFromId(playerID)
    xPlayer.addMoney(amount)
end

RaweAdmin.AddBank = function(playerID, amount)
    xPlayer = ESX.GetPlayerFromId(playerID)
    xPlayer.addAccountMoney("bank", amount)
end


AddItem = function(playerID, selectedItem, amount)
    local xPlayer = ESX.GetPlayerFromId(playerID)
    xPlayer.addInventoryItem(selectedItem, amount)
end

RaweAdmin.Teleport = function(targetId, action)
    local xPlayer, xTarget, sourceMessage, targetMessage
    if source ~= 0 then
        if action == "bring" then
            sourceMessage = "Bir oyuncu getirdin"
            targetMessage = "Getirildiniz"
            xPlayer = ESX.GetPlayerFromId(source)
            xTarget = ESX.GetPlayerFromId(targetId)
        elseif action == "goto" then
            targetMessage = "You teleported to a player"
            xPlayer = ESX.GetPlayerFromId(targetId)
            xTarget = ESX.GetPlayerFromId(source)
        end


        if xTarget then
            local targetCoords = xTarget.getCoords()
            local playerCoords = xPlayer.getCoords()
            xTarget.setCoords(playerCoords)
            if sourceMessage then
                TriggerClientEvent('esx:showNotification', xPlayer.source, sourceMessage)
            end
            TriggerClientEvent('esx:showNotification', xTarget.source, targetMessage)
        else
            TriggerClientEvent('esx:showNotification', xPlayer.source, 'Kullanıcı Aktif Değil')        
        end
    end
end

RegisterNetEvent("RaweAdmin:GiveWeapon")
AddEventHandler("RaweAdmin:GiveWeapon", function(playerID, weapon)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanGiveWeapon then
        RaweAdmin.AddWeapon(playerID, weapon, 10)
        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Verdiğiniz: '..GetPlayerName(playerID)..' a '..ESX.GetWeaponLabel(weapon)) 
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:AddItem")
AddEventHandler("RaweAdmin:AddItem", function(playerID, selectedItem, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanGiveItem then
        AddItem(playerID, selectedItem, amount)
        TriggerClientEvent('esx:showNotification', source, "Verdiniz: "..selectedItem.." Verilen Kişi: "..GetPlayerName(playerID))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)


RegisterNetEvent("RaweAdmin:AddCash")
AddEventHandler("RaweAdmin:AddCash", function (playerID, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanAddCash then
        RaweAdmin.AddCash(playerID, amount)
        TriggerClientEvent('esx:showNotification', source, "Para Verdiniz: "..amount.." Verilen Kişi: "..GetPlayerName(playerID))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:AddBank")
AddEventHandler("RaweAdmin:AddBank", function (playerID, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanAddBank then
        RaweAdmin.AddBank(playerID, amount)
        TriggerClientEvent('esx:showNotification', source, "Transfer Ettiniz: "..amount.." Verilen Kişi: "..GetPlayerName(playerID).."'s Bank Account")
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent('RaweAdmin:Kick')
AddEventHandler('RaweAdmin:Kick', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanKick then
        RaweAdmin.Kick(playerId, reason)
        TriggerClientEvent('esx:showNotification', source, "Banlandı: "..GetPlayerName(playerId))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent('RaweAdmin:Ban')
AddEventHandler('RaweAdmin:Ban', function(playerId, time, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and (Config.Perms[playerGroup].CanBanTemp and time ~= 0) or (Config.Perms[playerGroup].CanBanPerm and time == 0) then
        RaweAdmin.Ban(playerId, time, reason)
        TriggerClientEvent('esx:showNotification', source, "Banlandı: "..GetPlayerName(playerId))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Promote")
AddEventHandler("RaweAdmin:Promote", function (playerID, group)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    local targetPlayer = ESX.GetPlayerFromId(playerID)
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanPromote then
        if group ~= "superadmin" or playerGroup == "superadmin" then
            targetPlayer.setGroup(group)
            TriggerClientEvent('esx:showNotification', source, "Terfi Ettirildi: "..GetPlayerName(playerID).." Rütbe: "..group)
        end
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Announcement")
AddEventHandler("RaweAdmin:Announcement", function (message)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanAnnounce then
        TriggerClientEvent('chat:addMessage', -1, {color = { 255, 0, 0}, args = {"ANNOUNCEMENT ", message}})
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Notification")
AddEventHandler("RaweAdmin:Notification", function (playerID, message)
    local _source = playerID
    TriggerClientEvent('chat:addMessage', _source, {args = {"RaweAdmin ", message}})
end)

RegisterNetEvent("RaweAdmin:Teleport")
AddEventHandler("RaweAdmin:Teleport", function (targetId, action)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanTeleport then
        RaweAdmin.Teleport(targetId, action)
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Slay")
AddEventHandler("RaweAdmin:Slay", function (target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanSlay then
        TriggerClientEvent('RaweAdmin:Slay', target)
        TriggerClientEvent('esx:showNotification', source, "Öldürdün: "..GetPlayerName(target))
        TriggerClientEvent('esx:showNotification', target, "Bir admin tarafından öldürüldün.  ")
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:God")
AddEventHandler("RaweAdmin:God", function (target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanGodmode then
        TriggerClientEvent('RaweAdmin:God', target)
        TriggerClientEvent('esx:showNotification', source, "GodMode etkin "..GetPlayerName(target))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Freeze")
AddEventHandler("RaweAdmin:Freeze", function (target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanFreeze then
        TriggerClientEvent('RaweAdmin:Freeze', target)
        TriggerClientEvent('esx:showNotification', source, "Dondunuz/Çözdünüz "..GetPlayerName(target))
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:Unban")
AddEventHandler("RaweAdmin:Unban", function(license)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanUnban then
        RaweAdmin.Unban(license)
        TriggerClientEvent('esx:showNotification', source, "Bamı Kaldırıldı ("..license..")")
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:setJob")
AddEventHandler("RaweAdmin:setJob", function(target, job, rank)
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(target)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanSetJob then
        targetPlayer.setJob(job, rank)
        TriggerClientEvent('esx:showNotification', source, "Meslek Değiştirildi: "..GetPlayerName(target).." Meslek: "..job)
        TriggerClientEvent('esx:showNotification', target, "İşiniz şu şekilde değiştirildi: "..job)
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RegisterNetEvent("RaweAdmin:revive")
AddEventHandler("RaweAdmin:revive", function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(target)
    local playerGroup = xPlayer.getGroup()
    if Config.Perms[playerGroup] and Config.Perms[playerGroup].CanRevive then
        targetPlayer.triggerEvent('esx_ambulancejob:revive')
        TriggerClientEvent('esx:showNotification', source, "Canlandırıldınız: "..GetPlayerName(target))
        TriggerClientEvent('esx:showNotification', target, "Bir yönetici tarafından canlandırıldınız")
    else
       RaweAdmin.Error(source, "noPerms")
    end
end)

RaweAdmin.Error = function(source, message)
    if message == "noPerms" then
        TriggerClientEvent('chat:addMessage', source, {args = {"RaweAdmin ", "Bunun için izniniz yok. "}})
    else
        TriggerClientEvent('chat:addMessage', source, {args = {"RaweAdmin ", message}})
    end
end

function split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end