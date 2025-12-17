local LuckBoost = {}

function LuckBoost.apply(baseLuck, boostPercent)
  if type(baseLuck) ~= "number" or type(boostPercent) ~= "number" then
    error("baseLuck and boostPercent must be numbers")
  end
  if boostPercent < -100 then boostPercent = -100 end
  local factor = 1 + (boostPercent / 100)
  return baseLuck * factor
end

function LuckBoost.applyCap(baseLuck, boostPercent, minLuck, maxLuck)
  local v = LuckBoost.apply(baseLuck, boostPercent)
  if type(minLuck) == "number" and v < minLuck then v = minLuck end
  if type(maxLuck) == "number" and v > maxLuck then v = maxLuck end
  return v
end

return LuckBoost
