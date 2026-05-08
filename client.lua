local spawnedMushrooms = {}
local mushroomBlip = nil

local function spawnMushroom(index, data)
    if spawnedMushrooms[index] then 
		return 
	end
    
    lib.requestModel(data.model)
    local obj = CreateObject(data.model, data.coords.x, data.coords.y, data.coords.z, false, false, false)
    SetEntityHeading(obj, data.coords.w)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    exports.ox_target:addLocalEntity(obj, {
        {
            id = 'mush_'..index,
            icon = 'fa-solid fa-hands-holding',
            label = 'Podnieś grzybka',
            distance = 2.0,
            onSelect = function()
                CollectMushroom(index, data, obj)
            end,
            canInteract = function()
                return not LocalPlayer.state.IsHandcuffed and not LocalPlayer.state.isDead and not LocalPlayer.state.Dragging and not LocalPlayer.state.IsDragged and not LocalPlayer.state.IsTied
            end,
        }
    })
    
    spawnedMushrooms[index] = obj
    SetModelAsNoLongerNeeded(data.model)
end

local function initMushrooms()
    local states = lib.callback.await('a-mushrooms:server:getStates', 500)
    if not states then 
		return 
	end
    
    for i, data in ipairs(Config.Mushrooms) do
        if states[i] then 
            spawnMushroom(i, data) 
        end
    end

    if not mushroomBlip then
        mushroomBlip = AddBlipForCoord(-526.4200, 6005.3540, 33.2850)
        SetBlipSprite(mushroomBlip, 541)
        SetBlipColour(mushroomBlip, 10)
        SetBlipScale(mushroomBlip, 0.7)
        SetBlipAsShortRange(mushroomBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Zbieranie grzybów')
        EndTextCommandSetBlipName(mushroomBlip)
    end
end

CreateThread(function()
    initMushrooms()
end)

function CollectMushroom(index, cfg, entity)
    LocalPlayer.state:set('IsAnimated', true, true)
    exports.ox_target:disableTargeting(true)
	LocalPlayer.state.invBusy = true 
    
    local hasKnife = cache.weapon == `WEAPON_KNIFE`
    local destroyChance = hasKnife and 0 or math.random(1, 100)
    
    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        label = 'Podnosisz grzyba',
        disable = { 
			car = true, 
			move = true, 
			combat = true 
		},
        anim = {
			dict = 'anim@treasurehunt@doubleaction@action', 
			clip = 'double_action_pickup'
		},
    }) then 
        ClearPedSecondaryTask(cache.ped)
        
        local result = lib.callback.await('a-mushrooms:server:collectMushroom', false, index, destroyChance, {label = cfg.label, item = cfg.item})
        
        if result == 'already_picked' then
            ESX.ShowNotification('Ktoś już zebrał tego grzyba!')
        elseif result == 'destroyed' then
            ESX.ShowNotification(ESX.PlayerData.sex == 'm' and 'Zniszczyłeś grzyba' or 'Zniszczyłaś grzyba')
        end
    else 
        ClearPedSecondaryTask(cache.ped)
        ESX.ShowNotification('Przerwano zbieranie')	
    end	
    
    LocalPlayer.state:set('IsAnimated', false, true)
    exports.ox_target:disableTargeting(false)	
	LocalPlayer.state.invBusy = false 	
end

RegisterNetEvent('a-mushrooms:client:removeMushroom', function(index)
    if spawnedMushrooms[index] then
        exports.ox_target:removeLocalEntity(spawnedMushrooms[index], 'mush_'..index)
        DeleteObject(spawnedMushrooms[index])
        spawnedMushrooms[index] = nil
    end
end)

RegisterNetEvent('a-mushrooms:client:reloadMushrooms', function()
    initMushrooms()
end)

RegisterNetEvent('esx:onPlayerDeath', function()
    lib.cancelProgress()
end)

AddEventHandler('playerSpawned', function()
    lib.cancelProgress()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i, obj in pairs(spawnedMushrooms) do
            exports.ox_target:removeLocalEntity(obj, 'mush_'..i)
            DeleteObject(obj)
        end
    end
end)