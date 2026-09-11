function floor(num)
  -- 处理正数
  if num >= 0 then
      local integer = 0
      while integer + 1 <= num do
          integer = integer + 1
      end
      return integer
  -- 处理负数
  else
      local integer = 0
      while integer - 1 >= num do
          integer = integer - 1
      end
      return integer
  end
end
function RANDOMGENERATE(MAX, MIN)
  -- 处理MAX <= MIN的情况
  if MAX <= MIN then
      return MAX
  end

  local ZERODELTA = 0
if MIN < 0 then
    ZERODELTA = -MIN
end
local MININ = MIN + ZERODELTA  -- 转换为非负数坐标系
local MAXIN = MAX + ZERODELTA

  local range = MAXIN - MININ + 1
  local randomNum = 0

  -- 生成16位随机数（0-65535）
  for i = 1, 16 do
      randomNum = randomNum * 2 + GetRandomNumber()
      if randomNum < 0 then break end  -- 防止数值溢出
  end

  -- 确保数值落在有效范围
  while randomNum >= range do
      randomNum = randomNum - range
  end

  -- 最终整数化输出
  local final = floor(MININ + randomNum) + ZERODELTA
  return final
end