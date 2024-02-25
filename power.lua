-- Original by Merung (October, 2018)
-- V1 Forked/Edit by Just_Benji (Februari, 2023) - Added and changed GTNH LSC Compatibility
-- V2 with sensorInformation by Just_Benji (March,2023)
-- V3 disable the average table and enable the new average in/out from v2.3 LSC
-- V3.1 added Toggle functions for Red100Off and ArrowOff
-- V4 Fixed bug with ioratein/iorateout displaying double value
-- V4.1 Added tiers to UXV

-- Quetz4l time!
-- Added redstone levels for generators (from 0 to 10). 10 = ~0% eu, 2 = ~15% eu ...
-- Added battery charging and discharging time
-- Changed Arrow on Display
-- Added more settings
-- Added Wifi capacity
-- Auto detect LCR
-- Added passive lost to the average EU chagnes


-- You can download by this command "wget https://raw.githubusercontent.com/Quetz4l/LCR_Power_Control/main/power.lua power.lua"

local component = require("component")
local computer = require("computer")
local term = require("term")
local gpu = component.gpu
local MT = {}
local TimeTable = {}


MSCProxy = nil

--[ Settings to be changed ]

--MSCProxy = component.get("118b") -- MSC Address by manual
Loopdelay = 2           -- Refresh time, 2 is standard
RedstoneEnabled = true -- Redstone I/O connected to system for Generator enabling / Value true or false, default: false

ArrowOff = false       -- Turns off the arrow underneath the meters
Red100Off = false      -- When power gets at 100%, screen turns DARKRED to inform void. Can be turned off by setting value to true

ShowWifiMod = true
ShowMainenenceStatus = true
ShowPassiveLost = true
ShowTime = true

-- Generator Toggle values
GenON = 60  -- Generator turns on
GenOFF = 95 -- Generator turns off





-- [ START OF CODE ]
function GetLSC()
   for id, name in pairs(component.list()) do
      if name == "gt_machine" then
         local lcr = component.proxy(id)
         if lcr.getSensorInformation()[15] ~= nil and string.sub(lcr.getSensorInformation()[15], 1, 14) == "Total wireless" then
            return id
         end
      end
   end

   term.clear()
   exit("LSR not found, try set ID by manual")
end

if MSCProxy == nil then
   MSCProxy = GetLSC()
end

MSC = component.proxy(MSCProxy)
if RedstoneEnabled == true then ToggleRS = component.redstone end


-- Set Resolution
Res_x = 120
Res_y = 25
gpu.setResolution(Res_x, Res_y)

-- Define Colors
local COLORS = {
   RED = 0xFF0000,
   BLUE = 0x0000FF,
   GREEN = 0x00FF00,
   BLACK = 0x000000,
   WHITE = 0xFFFFFF,
   PURPLE = 0x800080,
   YELLOW = 0xFFFF00,
   ORANGE = 0xFFA500,
   DARKRED = 0x880000,
}


-- Redstone setup
function Redstone()
   if RedstoneEnabled == true then ToggleRS.setWakeThreshold(1) end

   function RedON(signal)
      if RedstoneEnabled == true then
         ToggleRS.setOutput({ signal, signal, signal, signal, signal, signal })
      end
   end

   function RedOFF()
      if RedstoneEnabled == true then
         ToggleRS.setOutput({ 0, 0, 0, 0, 0, 0 })
      end
   end
end


-- Maintanance
function Maintenance()
   local sensorInformation = MSC.getSensorInformation()
   local strInfo = sensorInformation[9]

   if strInfo == nil then else
      y = string.find(strInfo, "§")
      z = string.len(strInfo)
      MStatus = string.sub(strInfo, (y + 3), (z - 3))
   end

   if MStatus == "Working perfectly" then
      MColor = COLORS.GREEN
   else
      MColor = COLORS.RED
   end
end



-- Conversions
function convert_valueEU(eu, colormode)
   if eu == 0 then return "0 EU" end
   local i, units = 1, { "LV", "MV", "HV", "EV", "IV", "LuV", "ZPM", "UV", "UHV", "UEV", "UIV", "UMV", "UXV", "MAX" }

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
   MAX = 2147483640

   if colormode == 5 then eucolorx = COLORS.GREEN else eucolor = COLORS.GREEN end

   if eu <= 0 then
      eu = math.abs(eu)
      if colormode == 5 then eucolorx = COLORS.RED else eucolor = COLORS.RED end
   end

   local tier

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
      tier = MAX
      i = 13
   end

   eu = eu / tier

   local unit = units[i] or "?"
   local fstr
   if unit == "RF" then
      fstr = "%.0f %s"
   else
      fstr = "%.2f %s"
   end
   return string.format(fstr, eu, unit)
end

function convert_value(rf)
   if rf == 0 then return "0 EU" end
   local i, units = 1, { "EU", "10^3 EU", "10^6 EU", "10^9 EU", "10^12 EU", "10^15 EU", "10^18 EU", "10^21 EU" }
   while rf >= 1000 do
      rf = rf / 1000
      i = i + 1
   end
   local unit = units[i] or "?"
   local fstr
   if unit == "RF" then
      fstr = "%.0f %s"
   else
      fstr = "%.2f %s"
   end
   return string.format(fstr, rf, unit)
end

function get_percent_color(energy)
   local energycolor
   if energy <= 5 then
      energycolor = COLORS.RED
   elseif energy <= 25 then
      energycolor = COLORS.ORANGE
   elseif energy <= 50 then
      energycolor = COLORS.YELLOW
   elseif energy <= 75 then
      energycolor = COLORS.GREEN
   elseif energy <= 99 then
      energycolor = COLORS.BLUE
   else
      energycolor = COLORS.BLACK
   end
   return energycolor
end

local function convert_valueEU2(rf)
   if rf == 0 then return "0 EU" end
   local i, units = 1, { "EU", "K EU", "M EU", "G EU", "T EU", "P EU", "E EU", "Z EU", "Y EU", "Zz EU", "Yy EU", "B EU", "Bb EU" }
   while rf >= 1000 do
      rf = rf / 1000
      i = i + 1
   end
   local unitx = units[i] or "?"
   local fstr
   if unitx == "RF" then
      fstr = "%.0f %s"
   else
      fstr = "%.2f %s"
   end
   return string.format(fstr, rf, unitx)
end

-- Draw Arrow
local arrowProgress = 5
local arrowMargin = 10
local maxArrowProgress = Res_x - arrowMargin * 2

local function draw_arrow(io, y_shift)
   if ArrowOff == true or io == 0 then return end
   local posX

   local pos_num = io > 0 and true or false
   local arrowIteration = pos_num and 1 or -1
   local color = pos_num and 0x386a18 or 0xe51111
   gpu.setForeground(color)

   local function drawArrow(text, y_inc)
      term.setCursor(posX, y_shift + y_inc)
      term.write(text)
   end

   -- Create the bars
   local function drawPosArrowHead()
      drawArrow("\\ ", 0)
      drawArrow(" >", 1)
      drawArrow("/ ", 2)
   end

   local function drawNegArrowHead()
      drawArrow(" /", 0)
      drawArrow("< ", 1)
      drawArrow(" \\", 2)
   end

   local function drawArrowBody()
      for _ = 0, arrowProgress do
         drawArrow("▓", 0)
         drawArrow("█", 1)
         drawArrow("▓", 2)
         posX = posX + arrowIteration
      end
   end

   if pos_num then
      posX = arrowMargin
      drawArrowBody()
      drawPosArrowHead()
   else
      posX = Res_x - arrowMargin
      drawArrowBody()
      posX = posX + arrowIteration
      drawNegArrowHead()
   end

   arrowProgress = arrowProgress + 5
   if arrowProgress > maxArrowProgress then
      arrowProgress = 5
   end

   gpu.setForeground(fg_default)
end

local function draw_visuals(percent, y_shift)
   term.setCursor(offset, y_shift)
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

   for loc = 0, 100, 10
   do
      term.setCursor(offset + loc, y_shift - 1)
      term.write(loc)
      term.setCursor(offset + loc, y_shift)
      term.write("|")
   end
end

-- Convert string to number
local function parser(string)
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

function GetTime(secs)
   local parts = 4
   local units = { "centuries", "years", "d", "hr", "min", "sec" }
   local result = {}
   for i, v in ipairs({ 3153600000, 31536000, 86400, 3600, 60 }) do
      if secs >= v then
         result[i] = math.floor(secs / v)
         secs = math.floor(secs % v)
      end
   end
   result[5] = secs

   local resultString = ""
   local i = 1
   while parts ~= 0 and i ~= 6 do
      if result[i] and result[i] > 0 then
         resultString = resultString .. result[i] .. " " .. units[i] .. " "
         parts = parts - 1
      end
      i = i + 1
   end
   if resultString == "inf centuries " then resultString = "Infinity" end
   return resultString
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
   table.insert(TimeTable, 1, computer.uptime())

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




-- Main Code

local function showStartLogo()
   term.clear()

   ylogo = 36
   gpu.setForeground(COLORS.YELLOW)
   term.setCursor(ylogo, 1 + 4)
   term.write("        ░░░             ░░             ░░░        ")
   term.setCursor(ylogo, 1 + 5)
   term.write("          ░░░           ░░           ░░░          ")
   term.setCursor(ylogo, 1 + 6)
   term.write("         ░░             ░░             ░░░        ")
   term.setCursor(ylogo, 1 + 7)
   term.write("        ░░░░            ░░               ░░       ")
   term.setCursor(ylogo, 1 + 8)
   term.write("       ░░  ░░           ░░               ░░░      ")
   term.setCursor(ylogo, 1 + 9)
   term.write("      ░░    ░░░         ░░                ░░░     ")
   term.setCursor(ylogo, 1 + 10)
   term.write("      ░░      ░░        ░░                ░░░     ")
   term.setCursor(ylogo, 1 + 11)
   term.write("  ░░░░░░        ░░      ░░░░░░░░░░░░░░░░░░░░░░░░  ")
   term.setCursor(ylogo, 1 + 12)
   term.write("      ░░         ░░░    ░░                ░░░     ")
   term.setCursor(ylogo, 1 + 13)
   term.write("      ░░           ░░   ░░                ░░░     ")
   term.setCursor(ylogo, 1 + 14)
   term.write("       ░░            ░░░░░               ░░       ")
   term.setCursor(ylogo, 1 + 15)
   term.write("        ░░            ░░░░              ░░░       ")
   term.setCursor(ylogo, 1 + 16)
   term.write("         ░░             ░░             ░░         ")
   term.setCursor(ylogo, 1 + 17)
   term.write("          ░░░           ░░           ░░░          ")
   term.setCursor(ylogo, 1 + 18)
   term.write("         ░░             ░░             ░░░        ")

   gpu.setForeground(COLORS.WHITE)
   term.setCursor(35, 22)
   term.write("█▀█ █▀█ █░█░█ █▀▀ █▀█   █▀▀ █▀█ █▄░█ ▀█▀ █▀█ █▀█ █░░")
   term.setCursor(35, 23)
   term.write("█▀▀ █▄█ ▀▄▀▄▀ ██▄ █▀▄   █▄▄ █▄█ █░▀█ ░█░ █▀▄ █▄█ █▄▄")
   os.sleep(3)
end



--@@ START OF LOOP CODE @@
function DrawTheScreen()
   local sensorInformation = MSC.getSensorInformation()

   -- Get information
   local storedenergyinit = parser(sensorInformation[2])
   local maxenergyinit = parser(sensorInformation[3])


   local ioratein = parser(string.sub(sensorInformation[7], 1, -15))
   local iorateout = parser(string.sub(sensorInformation[8], 1, -15))
   local iorate = ioratein - iorateout

   local passiveLost = ShowPassiveLost and string.sub(sensorInformation[4], 15) or ""
   local WifiStorage

   if ShowWifiMod then
      WifiStorage = string.sub(sensorInformation[15], 23)
   end

   local percentenergy = storedenergyinit / maxenergyinit * 100

   local convstored = convert_value(storedenergyinit)
   local convmax = convert_value(maxenergyinit)

   -- General settings
   offset = 10
   visual_y_start = 5
   fg_default = COLORS.WHITE
   fg_color_max = COLORS.PURPLE
   eucolor = fg_default
   eucolorx = fg_default


   local percent_fg_color = get_percent_color(percentenergy)
   if percent_fg_color == 0 then percent_fg_color = 240 end

   local fg_color_stored = percent_fg_color
   local fg_color_percent = percent_fg_color


   -- Power Toggle
   if RedstoneEnabled == true then
      local currentOutputRSTable = ToggleRS.getOutput()
      local currentOutputRS = currentOutputRSTable[3]

      StatusRS = currentOutputRS == 0 and "OFF" or "ON"

      if percentenergy <= GenON then
         RedON(15)
         StatusRS = "ON"
      end
      if percentenergy >= GenOFF then
         RedOFF()
         StatusRS = "OFF"
      end
   else
      StatusRS = "RS Disabled"
   end

   if Red100Off == true and percentenergy > 99 then
         gpu.setBackground(COLORS.DARKRED)
   else
      gpu.setBackground(COLORS.BLACK)
   end


   -- Draw screen

   --Draw logo
   term.clear()
   gpu.setForeground(fg_default)
   local y_shift = 2
   local x_data = 52


   term.setCursor(35, visual_y_start - 2)
   term.write("█▀█ █▀█ █ █ █ █▀▀ █▀█   █▀▀ █▀█ █▄ █ ▀█▀ █▀█ █▀█ █  ")
   term.setCursor(35, visual_y_start - 1)
   term.write("█▀▀ █▄█ ▀▄▀▄▀ ██▄ █▀▄   █▄▄ █▄█ █ ▀█  █  █▀▄ █▄█ █▄▄")


   -- Draw current energy stored
   term.setCursor(30, visual_y_start + y_shift)
   term.write("Stored / Capacity EU: ")
   gpu.setForeground(fg_color_stored)
   term.setCursor(x_data, visual_y_start + y_shift)
   term.write(convstored)

   gpu.setForeground(fg_color_max)
   term.write(" / " .. convmax)
   gpu.setForeground(fg_default)


   -- Draw percentage
   y_shift = y_shift + 1
   term.setCursor(30, visual_y_start + y_shift)
   term.write("Percent Full:")
   term.setCursor(x_data, visual_y_start + y_shift)
   gpu.setForeground(fg_color_percent)
   if percentenergy > 99.999 then
      term.write("100 %")
   else
      term.write(string.format("%.12f %s", percentenergy, "%"))
   end
   gpu.setForeground(fg_default)

   -- Draw Actual In
   y_shift = y_shift + 1
   term.setCursor(30, visual_y_start + y_shift)
   term.write("Average EU In/s:")
   gpu.setForeground(COLORS.GREEN)
   term.setCursor(x_data, visual_y_start + y_shift)
   term.write(convert_valueEU(ioratein, 1) .. " equal to " .. convert_valueEU2(ioratein))
   gpu.setForeground(fg_default)

   -- Draw Actual Out
   y_shift = y_shift + 1
   term.setCursor(30, visual_y_start + y_shift)
   term.write("Average EU Out/s:")
   gpu.setForeground(COLORS.RED)
   term.setCursor(x_data, visual_y_start + y_shift)
   term.write(convert_valueEU(iorateout, 1) .. " equal to " .. convert_valueEU2(iorateout) .. "  (+" .. passiveLost ..
   ")")
   gpu.setForeground(fg_default)

   -- Draw Actual Change in/out
   y_shift = y_shift + 1
   term.setCursor(30, visual_y_start + y_shift)
   term.write("Average EU Change/s:")
   if iorate ~= nil then ioratechange = convert_valueEU(iorate - parser(passiveLost)) end
   gpu.setForeground(eucolor)
   term.setCursor(x_data, visual_y_start + y_shift)
   if ioratechange ~= nil then term.write(ioratechange) end
   gpu.setForeground(fg_default)

   -- Draw EU/Average Change:
   -- function disabled as in 2.3 has LSC fix for average per second, can be turned on for longer average eu consumption.
   AVEUToggle = false
   if AVEUToggle == true then
      y_shift = y_shift + 1
      term.setCursor(30, visual_y_start + y_shift)
      term.write("Average EU Change/s:")
      AVEU = AverageEU(MT, storedenergyinit)
      AVEU = convert_valueEU(AVEU, 5)
      gpu.setForeground(eucolorx)
      term.setCursor(x_data, visual_y_start + y_shift)
      if AVEU ~= nil then term.write(AVEU) end
      gpu.setForeground(fg_default)
   end

   if ShowTime then
      local color
      local text

      if percentenergy < 99.99 then
         local seconds
         if ioratein > 0 then
            seconds = (maxenergyinit - storedenergyinit) / ioratein
            color = COLORS.GREEN
         else
            seconds = (storedenergyinit) / (iorateout * 20)
            color = COLORS.RED
         end
         seconds = seconds / 20
         text = GetTime(seconds)
      else
         color = COLORS.GREEN
         text = "is already full"
      end

      y_shift = y_shift + 1
      term.setCursor(30, visual_y_start + y_shift)
      term.write("Time:")
      gpu.setForeground(color)
      term.setCursor(x_data, visual_y_start + y_shift)
      term.write(text)
      gpu.setForeground(fg_default)
      gpu.setBackground(COLORS.BLACK)
   end

   if ShowMainenenceStatus or RedstoneEnabled or ShowWifiMod then
      y_shift = y_shift + 1
   end

   -- Draw Maintenance status
   if ShowMainenenceStatus then
      y_shift = y_shift + 1
      term.setCursor(30, visual_y_start + y_shift)
      term.write("Maintenance status:")
      if MStatus == "Working perfectly" then MColor = COLORS.GREEN else MColor = COLORS.RED end
      gpu.setForeground(MColor)
      if MColor == COLORS.RED then gpu.setBackground(COLORS.YELLOW) end
      term.setCursor(x_data, visual_y_start + y_shift)
      term.write(MStatus)
      gpu.setForeground(fg_default)
      gpu.setBackground(COLORS.BLACK)
   end

   -- Draw Generator Status
   if RedstoneEnabled then
      y_shift = y_shift + 1
      term.setCursor(30, visual_y_start + y_shift)
      term.write("Generators status:")
      gpu.setForeground(fg_default)
      term.setCursor(x_data, visual_y_start + y_shift)
      term.write(StatusRS)
      gpu.setForeground(fg_default)
      gpu.setBackground(COLORS.BLACK)
   end

   -- Draw WiFi
   if ShowWifiMod then
      -- Draw Wifi Time for new energy loose
      y_shift = y_shift + 1
      term.setCursor(30, visual_y_start + y_shift)
      term.write("WiFi Eu:")

      gpu.setForeground(eucolor)
      term.setCursor(x_data, visual_y_start + y_shift)
      term.write(WifiStorage)
      gpu.setForeground(fg_default)
   end


   -- Draw ColorScreen
   draw_visuals(percentenergy, 20) -- default height= 20

   -- Draw Arrow
   draw_arrow(iorate, 22) --default height= 22




   -- Sleep
   os.sleep(Loopdelay)
end

--@@ END OF LOOP CODE@@--

local function run()
showStartLogo()
   local event_loop = true
   while event_loop do
      -- pcall(DrawTheScreen)    -- optional function to keep running even with errors
      DrawTheScreen()
   end
end

run()
