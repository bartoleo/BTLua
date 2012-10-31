times=1
cycles=50000

function resetEnv()
  local function addEnv(pstring)
    _G.env[pstring]=0
    _G.env[pstring.."_true"]=0
    _G.env[pstring.."_false"]=0
    _G.env[pstring.."_running"]=0
  end
  _G.env={}
  addEnv("a")
  addEnv("b")
  addEnv("c")
  addEnv("d")
  addEnv("e")
  addEnv("f")
  addEnv("g")
  addEnv("h")
end

function printEnv()
  local function _print(pstring)
    print (pstring..":".._G.env[pstring].."  t:".._G.env[pstring.."_true"].."  f:".._G.env[pstring.."_false"].."  r:".._G.env[pstring.."_running"])
  end
  _print("a")
  _print("b")
  _print("c")
  _print("d")
  _print("e")
  _print("f")
  _print("g")
  _print("h")

end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function love.load()
 require "BTLua"
 require "BTLua2"
 inspect = require 'inspect'
 resetEnv()
 print(_VERSION)
end

function love.keypressed(key)
 if key=="escape" then
   love.event.push('quit')
 end

 collectgarbage ("collect")
 collectgarbage ("stop")
 --
 local func
 local test
 local took
 local now
 local min
 local max
 local tot
 if _G["test_"..key] then
   print (" =========================================== kb:"..round(collectgarbage ("count"),3))
   min = -1
   max = -1
   tot = 0
   for time=1,times do
     resetEnv()
     collectgarbage ("collect")

     collectgarbage ("stop")
     func = _G["test_"..key]
     if (_G["test_"..key.."_init"]) then
       _G["test_"..key.."_init"]()
     end
     test = _G["test_"..key.."_desc"]
     local kbini = collectgarbage ("count")
     local now = os.clock()
     ---
     func()
     ---
     local took = os.clock() - now
     local kbfin = collectgarbage ("count")-kbini
     print(test .. " n." .. time.."/"..times.. " took: "..round(took,5).." sec and "..round(kbfin,1).." Kb")
     printEnv()
     if min == -1 or took<min then
      min = took
     end
     if max == -1 or took>max then
      max = took
     end
     tot = tot + took
   end
   print ("Min:"..round(min,5).." Max:"..round(max,5).." Tot:"..round(tot,5).." Avg:"..round(tot/times,5).." over "..times.." times")
 else
  print ("No such test:".."test_"..key.." !")
 end
 --
 collectgarbage ("collect")
 collectgarbage ("restart")
 collectgarbage ("step")
 collectgarbage ("step")
 collectgarbage ("collect")
 print ("kb:"..round(collectgarbage ("count"),3))

end


function love.update()
end

function love.draw()
end

function test_1_init()
  test_1_desc="prova bht"
  bht=BTLua2.TreeWalker:new("prova",nil,
                             BTLua2.PrioritySelector:new(
                               BTLua2.Sequence:new(
                                 BTLua2.Condition:new(func_a),
                                 BTLua2.Action:new(func_b)),
                               BTLua2.PrioritySelector:new(
                                 BTLua2.PrioritySelector:new(
                                   BTLua2.Sequence:new(
                                     BTLua2.Condition:new(func_c),
                                     BTLua2.Action:new(func_d)
                                   ),
                                   BTLua2.Sequence:new(
                                     BTLua2.Condition:new(func_e),
                                     BTLua2.Action:new(func_f)
                                   )
                                 )
                                 ,BTLua2.Sequence:new(
                                   BTLua2.Condition:new(func_g),
                                   BTLua2.Action:new(func_h)
                                 )
                              )
                           ))
end

function test_1()
  local i
  for i=1,cycles do
      bht:Tick()
  end
end

function test_2_init()
  test_2_desc="prova behavtree"
  bht2=BTLua.BTree:new("prova",nil,
                             BTLua.Selector:new(
                               BTLua.Sequence:new(
                                 BTLua.Condition:new(func_a),
                                 BTLua.Action:new(func_b)),
                               BTLua.Selector:new(
                                 BTLua.Selector:new(
                                   BTLua.Sequence:new(
                                     BTLua.Condition:new(func_c),
                                     BTLua.Action:new(func_d)
                                   ),
                                   BTLua.Sequence:new(
                                     BTLua.Condition:new(func_e),
                                     BTLua.Action:new(func_f)
                                   )
                                 )
                                 ,BTLua.Sequence:new(
                                   BTLua.Condition:new(func_g),
                                   BTLua.Action:new(func_h)
                                 )
                              )
                           ),nil,nil)
end

function test_2()
  local i
  for i=1,cycles do
      bht2:run()
  end
end

function func_a()
  _G.env.a = _G.env.a + 1
  if _G.env.a > 3000 then
    _G.env.a_false = _G.env.a_false + 1
    return false
  else
    _G.env.a_true = _G.env.a_true + 1
    return true
  end
end

function func_b()
  _G.env.b = _G.env.b + 1
  if _G.env.b > 3000 then
    _G.env.b_false = _G.env.b_false + 1
    return false
  else
    if _G.env.b % 2 == -1 then
      _G.env.b_running = _G.env.b_running + 1
      --return "Running"
      coroutine.yield("Running")
    end
    _G.env.b_true = _G.env.b_true + 1
    return true
  end
end

function func_c()
  _G.env.c = _G.env.c + 1
  if _G.env.c > 3000 then
    _G.env.c_false = _G.env.c_false + 1
    return false
  else
    _G.env.c_true = _G.env.c_true + 1
    return true
  end
end

function func_d()
  _G.env.d = _G.env.d + 1
  if _G.env.d > 3000 then
    _G.env.d_false = _G.env.d_false + 1
    return false
  else
    _G.env.d_true = _G.env.d_true + 1
    return true
  end
end


function func_e()
  _G.env.e = _G.env.e + 1
  if _G.env.e > 3000 then
    _G.env.e_false = _G.env.e_false + 1
    return false
  else
    _G.env.e_true = _G.env.e_true + 1
    return true
  end
end

function func_f()
  _G.env.f = _G.env.f + 1
  if _G.env.f >3000 then
    _G.env.f_false = _G.env.f_false + 1
    return false
  else
    _G.env.f_true = _G.env.f_true + 1
    return true
  end
end

function func_g()
  _G.env.g = _G.env.g + 1
  if _G.env.g > 3000 then
    _G.env.g_false = _G.env.g_false + 1
    return false
  else
    _G.env.g_true = _G.env.g_true + 1
    return true
  end
end

function func_h()
  _G.env.h = _G.env.h + 1
  if _G.env.h > 3000 then
    _G.env.h_false = _G.env.h_false + 1
    return false
  else
    _G.env.h_true = _G.env.h_true + 1
    return true
  end
end