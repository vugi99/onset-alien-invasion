AddEvent("OnPackageStart", function()
  print("Loading world...")

  local _table = File_LoadJSONTable("packages/"..GetPackageName().."/server/data/world.json")
  for _,v in pairs(_table) do
    if v['modelID'] ~= nil then
      CreateObject(v['modelID'], v['x'], v['y'], v['z'], v['rx'], v['ry'], v['rz'], v['sx'], v['sy'], v['sz'])
    else
      local _AddYaw = DoorConfig[tonumber(doorID)]
      if _AddYaw == nil then
        _AddYaw = 90
      end

      CreateDoor(v['doorID'], v['x'], v['y'], v['z'], v['yaw'] + _AddYaw, true)
    end
  end

  print("Alien Invasion world loaded!")
end)
