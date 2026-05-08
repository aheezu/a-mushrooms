local AvailableMushrooms = {}
for i = 1, #Config.Mushrooms do 
    AvailableMushrooms[i] = true 
end

lib.callback.register('a-mushrooms:server:collectMushroom', function(source, index, destroyChances, data)
    if not AvailableMushrooms[index] then 
        return 'already_picked' 
    end

    AvailableMushrooms[index] = false
    TriggerClientEvent('a-mushrooms:client:removeMushroom', -1, index)

    local allPicked = true
    for i = 1, #Config.Mushrooms do
        if AvailableMushrooms[i] then
            allPicked = false
            break
        end
    end

    if allPicked then
        SetTimeout(Config.RespawnTime, function()
            for i = 1, #Config.Mushrooms do 
                AvailableMushrooms[i] = true 
            end
            TriggerClientEvent('a-mushrooms:client:reloadMushrooms', -1)
        end)
    end

    if destroyChances > 60 then
        return 'destroyed'
    else
        exports.ox_inventory:AddItem(source, data.item, 1)
        return 'success'
    end
end)

lib.callback.register('a-mushrooms:server:getStates', function(source)
    return AvailableMushrooms
end)