sHUDConfig = {
  height   = 150,                      -- height and width of bars including border
  width    = 14, 
  distance = 120,                      -- distance of bars from middle of the screen
  spacing  = 3,                        -- spacing between bars
  padding  = 1,                        -- width of black border
  perfect  = true,                     -- pixelperfect or not (false/nil to disable)
  
  -- which bars to show and in what order
  bars     = { 
    {'health', 'player'},              -- inner left
    {'power',  'player'},              -- inner right
    {'health', 'target'},              -- outer left
    {'power',  'target'}               -- outer right
    -- {...}, you can add more bars for instance for focus
  }
}
