local AOData = {
  outsourcing = false,
  estimate = 0,
  orders = 0,
  full = false,
  pointsPerOrder = 200,
}

local function Notify(title, text)
  local image = "UI/Icons/Notifications/New/research.tga"
  AddCustomOnScreenNotification("AutoOutsource", title, text, image)
end

local function NotifyAutoOutsource(amount)
  local title = T("Outsourcing finished")
  local text = T("Re-outsourcing again up to <ResearchPoints(" .. amount .. ")>")

  return Notify(title, text)
end

local function NotifyFinishOutsource()
  local title = T("Auto-outsourcing disabled")
  local text = T("Your funding is below the hardcoded limit")

  return Notify(title, text)
end

-- resets AutoOutsourceData values
local function reset()
  AOData.outsourcing = false
  AOData.estimate = 0
  AOData.orders = 0
end

function OnMsg.NewMinute()
  local outsource = UICity:GetEstimatedRP_Outsource()

  if not AOData.outsourcing and outsource ~= 0 then
    AOData.outsourcing = true
    AOData.estimate = outsource
    AOData.orders = outsource / AOData.pointsPerOrder

    print(string.format("Outsourcing is enabled with %d orders and an estimate of %d", AOData.orders, AOData.estimate))
  end

  if AOData.outsourcing and outsource ~= AOData.estimate and math.fmod(outsource, AOData.pointsPerOrder) == 0 then
    print("Outsourcing changed")
    local orders = outsource / AOData.pointsPerOrder
    if orders < AOData.orders then
      print("Outsourcing finished")
      local diff = AOData.orders - orders
      local cost = diff * AOData.pointsPerOrder * 1000000
      -- hardcoded for now to minimum (cost + 4,000,000,000)
      local requiredFunds = cost + 4000 * 1000000
      local canOutsource = UICity.funding >= requiredFunds
      local points = diff * AOData.pointsPerOrder

      if canOutsource then
        print("Re-outsourcing diff " .. diff .. " and points " .. points)
        UICity:OutsourceResearch(points * 5)

        -- Substract amount from funding
        UICity:ChangeFunding(-cost)


        NotifyAutoOutsource(AOData.estimate)
        print(string.format("Re-outsourcing per %dM", AOData.estimate))
      else
        NotifyFinishOutsource()
        print("Can't auto-outsource, disabling...")
        -- Reset values
        reset()
      end
    else
      print("Orders increased, updating to ".. outsource .." points and " .. orders .." orders")
      AOData.estimate = outsource
      AOData.orders = orders
    end
  end
end
