
-- 初始化安全随机索引生成
function GetSafeRandomIndex()
  local max_attempts = 30
  local attempts = 0
  local target = -1

  repeat
      target = RANDOMGENERATE(15, 0)
      attempts = attempts + 1
      -- 检查索引有效性及对象存活状态
      if target >= 0 and target <= 15 and SA[target] ~= nil then
          if ObjectIsAlive(SA[target]) then
              return target
          end
      end
      Sleep(5)  -- 优化等待时间
  until attempts >= max_attempts

  return -1  -- 返回无效索引表示失败
end
