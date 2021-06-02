local spawnedBees = 0
local beess = {}
local isPickingUp, isProcessing = false, false


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(8000)
		local coords = GetEntityCoords(PlayerPedId())

		if GetDistanceBetweenCoords(coords, Config.CircleZones.BeeField.coords, true) < 20 then
			SpawnBeees()
			Citizen.Wait(8000)
		else
			Citizen.Wait(8000)
		end
	end
end)



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #beess, 1 do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(beess[i]), false) < 1 then
				nearbyObject, nearbyID = beess[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then

			if not isPickingUp then
				Citizen.Wait(1)
				ESX.ShowHelpNotification(_U('weed_pickupprompt'))
				--exports['mythic_notify']:SendAlert('inform', '[E] Tuşuna basarak bal topla', 2500)
				--break;
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true

				ESX.TriggerServerCallback('kp_bee:canPickUp', function(canPickUp)

					if canPickUp then
						TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)
						TriggerEvent("mythic_progbar:client:progress", {
							name = "unique_action_name",
							duration = 7500,
							label = "Bal Topluyorsun.. 🍯",
							useWhileDead = false,
							canCancel = true,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							},
							prop = {
								model = "prop_paper_bag_small",
							}
						}, function(status)
							if not status then
								-- Do Something If Event Wasn't Cancelled
							end
						end)

						Citizen.Wait(4000)
						ClearPedTasks(playerPed)
						Citizen.Wait(4000)
		
						ESX.Game.DeleteObject(nearbyObject)
		
						table.remove(beess, nearbyID)
						spawnedBees = spawnedBees - 1
		
						TriggerServerEvent('kp_bee:pickedUpCannabis')
					else
						ESX.ShowNotification(_U('weed_inventoryfull'))
					end

					isPickingUp = false

				end, 'honey_a')
			end

		else
			Citizen.Wait(500)
		end

	end

end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(beess) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnBeees()
	while spawnedBees < 20 do
		Citizen.Wait(10)
		local sandCoords = GenerateBeeCoords()

		ESX.Game.SpawnLocalObject('prop_crate_07a', sandCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(beess, obj)
			spawnedBees = spawnedBees + 1
		end)
	end
end

function ValidateSandCoord(plantCoord)
	if spawnedBees > 0 then
		local validate = true

		for k, v in pairs(beess) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 10 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.BeeField.coords, false) > 20 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateBeeCoords()
	while true do
		Citizen.Wait(220)

		local beeCoordX, beeCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-30, 30)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-25, 25)

		beeCoordX = Config.CircleZones.BeeField.coords.x + modX
		beeCoordY = Config.CircleZones.BeeField.coords.y + modY

		local coordZ = GetCoordZ(beeCoordX, beeCoordY)
		local coord = vector3(beeCoordX, beeCoordY, coordZ)

		if ValidateSandCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 40.0, 41.0, 42.0, 43.0, 44.0, 45.0, 46.0, 47.0, 48.0, 49.0, 50.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 43.0
end