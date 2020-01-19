local ScoreboardUI

AddEvent("OnPackageStart", function()
  ScoreboardUI = CreateWebUI(0.0, 0.0, 0.0, 0.0, 1, 60)
  SetWebAnchors(ScoreboardUI, 0.0, 0.0, 1.0, 1.0)
  LoadWebFile(ScoreboardUI, 'http://asset/' .. GetPackageName() .. '/client/ui/scoreboard/scoreboard.html')
  SetWebVisibility(ScoreboardUI, WEB_HIDDEN)
end)

AddEvent('OnKeyPress', function(key)
  if key == 'Tab' then
    CallRemoteEvent('RequestScoreboardUpdate')
    SetWebVisibility(ScoreboardUI, WEB_VISIBLE)
  end
end)

AddEvent('OnKeyRelease', function(key)
  if key == 'Tab' then
    SetWebVisibility(ScoreboardUI, WEB_HIDDEN)
  end
end)

AddRemoteEvent('OnServerScoreboardUpdate', function(players)
  if players == nil then 
    return 
  end

  ExecuteWebJS(ScoreboardUI, "LoadOnlinePlayers("..players..")")
  --ExecuteWebJS(ScoreboardUI, 'LoadHighscores('..highscores..')')
end)