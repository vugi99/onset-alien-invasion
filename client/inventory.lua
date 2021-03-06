local InventoryUI

AddEvent("OnPackageStart", function()
    InventoryUI = CreateWebUI(0.0, 0.0, 0.0, 0.0)
    LoadWebFile(InventoryUI, "http://asset/"..GetPackageName().."/client/ui/inventory/inventory.html")
    SetWebAlignment(InventoryUI, 0.0, 0.0)
    SetWebAnchors(InventoryUI, 0.0, 0.0, 1.0, 1.0)
    SetWebVisibility(InventoryUI, WEB_HITINVISIBLE)
end)

AddEvent('OnKeyPress', function(key)
  if key == 'Tab' then
    ShowMouseCursor(true)
    SetInputMode(INPUT_GAMEANDUI)
    ExecuteWebJS(InventoryUI, "EmitEvent('ShowInventory')")
  end
end)

AddEvent('OnKeyRelease', function(key)
  if key == 'Tab' then
    ExecuteWebJS(InventoryUI, "EmitEvent('HideInventory')")
    ShowMouseCursor(false)
    SetInputMode(INPUT_GAME)
  end
end)

-- inventory
AddRemoteEvent("SetInventory", function(data)
	ExecuteWebJS(InventoryUI, "EmitEvent('SetInventory',".. data ..")")
end)