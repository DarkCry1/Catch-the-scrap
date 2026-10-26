--!strict
local Movement = {}

function Movement.effectiveSpeed(baseSpeed: number, strength: number, weight: number, minimumSpeed: number): number
    assert(baseSpeed > 0 and baseSpeed < math.huge, "baseSpeed must be finite and positive")
    assert(strength > 0 and strength < math.huge, "strength must be finite and positive")
    assert(weight >= 0 and weight < math.huge, "weight must be finite and nonnegative")
    assert(minimumSpeed > 0 and minimumSpeed <= baseSpeed, "minimumSpeed must be positive and <= baseSpeed")
    return math.max(minimumSpeed, baseSpeed / (1 + (weight / strength) ^ 1.25 * 0.45))
end

return Movement
