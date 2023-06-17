-- Original by Merung (October, 2018)
-- V1 Forked/Edit by Just_Benji (Februari, 2023) - Added and changed GTNH LSC Compatibility
-- V2 with sensorInformation by Just_Benji (March,2023)
-- V3 disable the average table and enable the new average in/out from v2.3 LSC
-- V3.1 added Toggle functions for Red100Off and ArrowOff
-- V4 Fixed bug with ioratein/iorateout displaying double value
-- V4.1 Added tiers to UXV

-- pastebin get dU5feqYz pwr.lua



local component = require("component")
local computer = require("computer")
local term = require("term")
local gpu = component.gpu
local sides = require("sides")
local MT = {}
local TimeTable = {}

-- Settings to be changed

        -- General
        MSCProxy = "b99a99ad-c564-4549-b7d4-03b2d619cfe0" -- MSC Address
        loopdelay = 2           -- Refresh time, 2 is standard
        RedstoneEnabled = false -- Redstone I/O connected to system for Generator enabling / Value true or false, default: false

        -- Generator Toggle values

        genON = 60              -- Generator turns on
        genOFF = 95             -- Generator turns off

        ArrowOff = false        -- Turns off the arrow underneath the meters
        Red100Off = false       -- When power gets at 100%, screen turns DARKRED to inform void. Can be turned off by setting value to true




-- START OF CODE
-- Setup components
msc = component.proxy(MSCProxy)
storage = msc
if RedstoneEnabled == true then toggleRS = component.redstone end


-- Set Resolution
res_x = 120
res_y = 25
gpu.setResolution(res_x, res_y)

-- Set Max Value and increment for bottom bars
io_max_rate = 600000
io_increment = io_max_rate / 100

-- Functions

function exit_msg(msg)
  term.clear()
  print(msg)
  os.exit()
end


-- Redstone setup
if RedstoneEnabled == true then toggleRS.setWakeThreshold(1) end


function redON()
if RedstoneEnabled == true then
  toggleRS.setOutput({15,15,15,15,15,15})
 -- toggleRS.setOutput(sides.north, 15)
 -- toggleRS.setOutput(sides.east, 15)
 -- toggleRS.setOutput(sides.west, 15)
 -- toggleRS.setOutput(sides.south, 15)
 -- toggleRS.setOutput(sides.top, 15)
 -- toggleRS.setOutput(sides.bottom, 15)
end
end

function redOFF()
if RedstoneEnabled == true then
	toggleRS.setOutput({0,0,0,0,0,0})
 -- toggleRS.setOutput(sides.north, 0)
 -- toggleRS.setOutput(sides.east, 0)
 -- toggleRS.setOutput(sides.west, 0)
 -- toggleRS.setOutput(sides.south, 0)
 -- toggleRS.setOutput(sides.top, 0)
 -- toggleRS.setOutput(sides.bottom, 0)
end
end


-- Maintanance

local sensorInformation = msc.getSensorInformation()
strInfo = sensorInformation[9]

if strInfo == nil then else
y = string.find(strInfo, "§")
z = string.len(strInfo)
MStatus = string.sub(strInfo, (y+3), (z-3))
end


if MStatus == "Working perfectly" then 
MColor = GREEN
else
MColor = RED
end



-- Conversions

function convert_valueEU(eu, colormode)
  if eu == 0 then return "0 EU" end
  local i, units = 1, { "LV", "MV", "HV", "EV", "IV", "LuV", "ZPM", "UV", "UHV", "UEV", "UIV", "UMV", "UXV", }
  
LV = 32
MV = 128
HV = 512
EV = 2048
IV = 8192
LuV = 32768
ZPM = 131072
UV = 524288
UHV = 2097152
UEV = 8388608
UIV = 33554432
UMV = 134217728
UXV = 536870912

if colormode == 5 then eucolorx = GREEN else eucolor = GREEN end

	 if eu <= 0 then
		eu = math.abs(eu)
		if colormode == 5 then eucolorx = RED else eucolor = RED end
end

  	 if eu <= MV then
	  tier = LV
  	  i = 1
 	 elseif eu <= HV then
	  tier = MV	
 	  i = 2
  	 elseif eu <= EV then
	  tier = HV
      i = 3
 	 elseif eu <= IV then
	  tier = EV
 	  i = 4
 	 elseif eu <= LuV then
	  tier = IV
 	  i = 5
	 elseif eu <= ZPM then
	  tier = LuV
 	  i = 6
	 elseif eu <= UV then
	  tier = ZPM
 	  i = 7
	 elseif eu <= UHV then
	  tier = UV
 	  i = 8
   elseif eu <= UEV then
	  tier = UHV
 	  i = 9
   elseif eu <= UIV then
	  tier = UEV
 	  i = 10
   elseif eu <= UMV then
	  tier = UIV
 	  i = 11
   elseif eu <= UXV then
	  tier = UMV
 	  i = 12

 	 else
	  tier = UXV
 	   i = 13
	 end
 	 
     eu = eu / tier

  local unit = units[ i ] or "?"
  local fstr
  if unit == "RF" then
    fstr = "%.0f %s"
  else
    fstr = "%.2f %s"
  end
  return string.format( fstr, eu, unit)
	
end



function convert_value(rf)
  if rf == 0 then return "0 EU" end
  local i, units = 1, { "EU", "10^3 EU", "10^6 EU", "10^9 EU", "10^12 EU", "10^15 EU", "10^18 EU", "10^21 EU" }
  while rf >= 1000 do
    rf = rf / 1000
    i = i + 1
  end
  local unit = units[ i ] or "?"
  local fstr
  if unit == "RF" then
    fstr = "%.0f %s"
  else
    fstr = "%.2f %s"
  end
  return string.format( fstr, rf, unit )
end

function get_percent_color(energy)
  local energycolor
  if energy <= 5 then
    energycolor = RED
  elseif energy <= 25 then
    energycolor = ORANGE
  elseif energy <= 50 then
    energycolor = YELLOW
  elseif energy <= 75 then
    energycolor = GREEN
  elseif energy <= 99 then
    energycolor = BLUE
  else
    energycolor = BLACK
  end
  return energycolor
end







function convert_valueEU2(rf)
  if rf == 0 then return "0 EU" end
  local i, units = 1, { "EU", "K EU", "M EU", "G EU", "T EU", "P EU", "E EU", "Y EU" }
  while rf >= 1000 do
    rf = rf / 1000
    i = i + 1
  end
  local unitx = units[ i ] or "?"
  local fstr
  if unitx == "RF" then
    fstr = "%.0f %s"
  else
    fstr = "%.2f %s"
  end
  return string.format( fstr, rf, unitx )
end




-- Draw sections

function draw_legend(io)
  gpu.setForeground(fg_default)

  for loc = 0, 100, 10
  do
    term.setCursor(offset + loc, visual_y_start + 11)
    term.write(loc)
    term.setCursor(offset + loc, visual_y_start + 12)
    term.write("|")
  end

  if ArrowOff == false then draw_direction(io) end

end

function draw_direction(io)

local is_neg
local pos_num

  if io == 0
  then
    return
  elseif io > 0
  then
    is_neg = 0
    pos_num = io
  elseif io < 0
  then
    is_neg = 1
    pos_num = io * -1
  end

  -- Determine how many "="
  local num_col = pos_num / io_increment
  if num_col > 100 then num_col = 100 end
  if num_col < 1 then num_col = 1 end

  -- Create the bars

  local base_bar = ""
  local base_bar1 = ""
  local base_bar2 = ""
  local base_bar3 = ""
  local num_spaces = 100 - num_col
  local space_offset = num_spaces / 2


  for int_space = 0, space_offset, 1
  do
    base_bar = base_bar .. " "
  end

  if is_neg == 1
  then
    base_bar1 = base_bar .. "/"
    base_bar2 = base_bar .. "<="
    base_bar3 = base_bar .. "\\"
  else
    base_bar1 = base_bar
    base_bar2 = base_bar
    base_bar3 = base_bar
  end

  for int_eq = 0, num_col, 1
  do
    base_bar1 = base_bar1 .. "="
    base_bar2 = base_bar2 .. "="
    base_bar3 = base_bar3 .. "="
  end

  if is_neg == 0
  then
    base_bar1 = base_bar1 .. "\\"
    base_bar2 = base_bar2 .. "=>"
    base_bar3 = base_bar3 .. "/"
  end

  -- Draw the actual bars
  if is_neg == 1
  then
    gpu.setForeground(RED)
    term.setCursor(offset, visual_y_start + 15)
    term.write(base_bar1)
    term.setCursor(offset - 1, visual_y_start + 16)
    term.write(base_bar2)
    term.setCursor(offset, visual_y_start + 17)
    term.write(base_bar3)
    gpu.setForeground(fg_default)
  else
    gpu.setForeground(GREEN)
    term.setCursor(offset, visual_y_start + 15)
    term.write(base_bar1)
    term.setCursor(offset, visual_y_start + 16)
    term.write(base_bar2)
    term.setCursor(offset, visual_y_start + 17)
    term.write(base_bar3)
    gpu.setForeground(fg_default)
  end

end

function draw_visuals(percent)

  term.setCursor(offset, visual_y_start + 13)
  for check = 0, 100, 1
  do
    if check <= percent
    then
      gpu.setForeground(get_percent_color(check))
      term.write("|")
      gpu.setForeground(fg_default)
    else
      gpu.setForeground(fg_default)
      term.write(".")
    end
  end
end



-- Convert string to number  , credits to nidas
function parser(string)
    if type(string) == "string" then
        local numberString = string.gsub(string, "([^0-9]+)", "")
        if tonumber(numberString) then
            return math.floor(tonumber(numberString) + 0)
        end
        return 0
    else
        return 0
    end
end


-- Average table calculator
function AverageEU(TableAverageEU, EUStored)
    local euold = 0
    local eunew = 0
    local eusom = 0
    local AveEU = 0
    local i = 1
    local told = 0
    local tnew = 0
    local tsom = 0

    table.insert(TableAverageEU, 1, EUStored)
    table.insert(TimeTable,1, computer.uptime())
    
    if #TableAverageEU > 11 then
        while i <= 10 do
          if i == 1 then
            euold = TableAverageEU[1]
            told = TimeTable[1]
          else
            eunew = TableAverageEU[i]
            eusom = (eunew - euold) + eusom
            euold = eunew
            
            tnew = TimeTable[i]
            tsom = (tnew - told) + tsom
            told = tnew

          end
          i = i + 1
        end
        AveEU = eusom / 10 / tsom
    else
        AveEU = 0
    end
    return AveEU
end

-- Define Colors

RED = 0xFF0000
BLUE = 0x0000FF
GREEN = 0x00FF00
BLACK = 0x000000
WHITE = 0xFFFFFF
PURPLE = 0x800080
YELLOW = 0xFFFF00
ORANGE = 0xFFA500
DARKRED = 0x880000




-- Main Code
term.clear()

ylogo = 36
gpu.setForeground(YELLOW)
term.setCursor(ylogo, 1 + 4) term.write("        ░░░             ░░             ░░░        ")
term.setCursor(ylogo, 1 + 5) term.write("          ░░░           ░░           ░░░          ")
term.setCursor(ylogo, 1 + 6) term.write("         ░░             ░░             ░░░        ")
term.setCursor(ylogo, 1 + 7) term.write("        ░░░░            ░░               ░░       ")
term.setCursor(ylogo, 1 + 8) term.write("       ░░  ░░           ░░               ░░░      ")
term.setCursor(ylogo, 1 + 9) term.write("      ░░    ░░░         ░░                ░░░     ")
term.setCursor(ylogo, 1 + 10) term.write("      ░░      ░░        ░░                ░░░     ")
term.setCursor(ylogo, 1 + 11) term.write("  ░░░░░░        ░░      ░░░░░░░░░░░░░░░░░░░░░░░░  ")
term.setCursor(ylogo, 1 + 12) term.write("      ░░         ░░░    ░░                ░░░     ")
term.setCursor(ylogo, 1 + 13) term.write("      ░░           ░░   ░░                ░░░     ")
term.setCursor(ylogo, 1 + 14) term.write("       ░░            ░░░░░               ░░       ")
term.setCursor(ylogo, 1 + 15) term.write("        ░░            ░░░░              ░░░       ")
term.setCursor(ylogo, 1 + 16) term.write("         ░░             ░░             ░░         ")
term.setCursor(ylogo, 1 + 17) term.write("          ░░░           ░░           ░░░          ")
term.setCursor(ylogo, 1 + 18) term.write("         ░░             ░░             ░░░        ")

gpu.setForeground(WHITE)
term.setCursor(35, 22)     term.write("█▀█ █▀█ █░█░█ █▀▀ █▀█   █▀▀ █▀█ █▄░█ ▀█▀ █▀█ █▀█ █░░")
term.setCursor(35, 23)     term.write("█▀▀ █▄█ ▀▄▀▄▀ ██▄ █▀▄   █▄▄ █▄█ █░▀█ ░█░ █▀▄ █▄█ █▄▄")
os.sleep(3)




--@@ START OF LOOP CODE @@
function DrawTheScreen()
    local sensorInformation = msc.getSensorInformation()

    -- Get information
    local storedenergyinit = parser(sensorInformation[2])
    local maxenergyinit = parser(sensorInformation[3])

    local ioratein = parser(string.sub(sensorInformation[7],1,-15))
    local iorateout = parser(string.sub(sensorInformation[8],1,-15))
    local iorate = ioratein - iorateout

    local percentenergy = storedenergyinit / maxenergyinit * 100

    local convstored = convert_value( storedenergyinit )
    local convmax = convert_value( maxenergyinit )

    -- General settings
    offset = 10
    visual_y_start = 5
    fg_default = WHITE
    fg_color_max = PURPLE
    eucolor = fg_default
    eucolorx = fg_default

    local fg_color_stored = get_percent_color(percentenergy)
    local fg_color_percent = fg_color_stored

    local fg_color_io

    if iorate <= 0 then
    fg_color_io = RED
    else
    fg_color_io = GREEN
    end

    -- Power Toggle
    if RedstoneEnabled == true then
      currentOutputRSTable = toggleRS.getOutput()
      currentOutputRS = currentOutputRSTable[3]
      if currentOutputRS == 0 then statusRS = "OFF" else statusRS = "ON" end

      if percentenergy <= genON then
      redON() 
      statusRS = "ON"
      end
      if percentenergy >= genOFF then 
      redOFF()
      statusRS = "OFF"
      end	
    else
      statusRS = "RS Disabled"
    end

   if Red100Off == false then
     if percentenergy <= 99 then
     gpu.setBackground(BLACK)
     else
     gpu.setBackground(DARKRED)
      end
   else 
      gpu.setBackground(BLACK)
    end


    -- Draw screen

    --Draw logo
    term.clear()
    gpu.setForeground(fg_default)


    term.setCursor(35, visual_y_start -2)    term.write("█▀█ █▀█ █░█░█ █▀▀ █▀█   █▀▀ █▀█ █▄░█ ▀█▀ █▀█ █▀█ █░░")
    term.setCursor(35, visual_y_start -1)    term.write("█▀▀ █▄█ ▀▄▀▄▀ ██▄ █▀▄   █▄▄ █▄█ █░▀█ ░█░ █▀▄ █▄█ █▄▄")


    -- Draw current energy stored
    term.setCursor(30, visual_y_start + 2)
    term.write("Current Stored Energy / Max Energy: ")
    gpu.setForeground(fg_color_stored)
    term.write(convstored)
    gpu.setForeground(fg_default)
    term.write (" / ")
    gpu.setForeground(fg_color_max)
    term.write(convmax)
    gpu.setForeground(fg_default)


    -- Draw percentage 
    term.setCursor(30,visual_y_start + 3)
    term.write("Percent Full:        ")
    gpu.setForeground(fg_color_percent)
    term.write(string.format("%.12f %s", percentenergy, " %"))
    gpu.setForeground(fg_default)

    -- Draw Actual In
    term.setCursor(30,visual_y_start + 4)
    term.write("Average EU In/s:     ")
    gpu.setForeground(GREEN)
    term.write(convert_valueEU(ioratein, 1) .. " equal to " .. convert_valueEU2(ioratein))
    gpu.setForeground(fg_default)

    -- Draw Actual Out
    term.setCursor(30,visual_y_start + 5)
    term.write("Average EU Out/s:    ")
    gpu.setForeground(RED)
    term.write(convert_valueEU(iorateout, 1) .. " equal to " .. convert_valueEU2(iorateout))
    gpu.setForeground(fg_default)

    -- Draw Actual Change in/out
    term.setCursor(30,visual_y_start + 6)
    term.write("Average EU Change/s: ")
    if iorate ~= nil then ioratechange =  convert_valueEU(iorate) end
    gpu.setForeground(eucolor)
    if ioratechange ~= nil then term.write(ioratechange) end
    gpu.setForeground(fg_default)


    -- Draw EU/Average Change: 
    -- function disabled as in 2.3 has LSC fix for average per second, can be turned on for longer average eu consumption.
      AVEUToggle = false
    if AVEUToggle == true then
      term.setCursor(30,visual_y_start + 7)
      term.write("Average EU Change/s: ")
      AVEU = AverageEU(MT, storedenergyinit)
      AVEU = convert_valueEU(AVEU, 5)
      gpu.setForeground(eucolorx)
      if AVEU ~=nil then term.write(AVEU) end
      gpu.setForeground(fg_default)
    end

    -- Draw Maintenance status
    term.setCursor(30,visual_y_start + 8)
    term.write("Maintenance status:  ")
    if MStatus == "Working perfectly" then MColor = GREEN else MColor = RED end
    gpu.setForeground(MColor)
    if MColor == RED then gpu.setBackground(YELLOW) end
    term.write(MStatus)
    gpu.setForeground(fg_default)
    gpu.setBackground(BLACK)

    -- Draw Generator Status
    term.setCursor(30,visual_y_start + 9)
    term.write("Generators status:   ")
    gpu.setForeground(fg_default)
    term.write(statusRS)
    gpu.setForeground(fg_default)
    gpu.setBackground(BLACK)

    -- Draw ColorScreen
    draw_visuals(percentenergy)
    -- Draw Pointline
    draw_legend(iorate)





-- Sleep
os.sleep(loopdelay)

end
--@@ END OF LOOP CODE@@--



-- Loop Run
local event_loop = true
while event_loop do
    -- pcall(DrawTheScreen)    -- optional function to keep running even with errors
    DrawTheScreen()
end
