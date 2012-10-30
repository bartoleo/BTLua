--- BTLua
if not BTLua then
  BTLua={}
end
BTLua.behavtree = {}
function BTLua.behavtree:new(...)
   local _o = {}
   _o.name=""
   _o.tree=nil
   _o.object=nil
   _o.laststatus=nil
   _o.Runningnode=nil
   _o.initialized=false
   _o.ticknum=0
   setmetatable(_o, self)
   self.__index = self
   _o:init(...)
   return _o
end
--------------- UTILS -------------------
local function inheritsFrom( baseClass )
    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end
    return new_class
end
--
local function shuffle(t)
  -- see: http://en.wikipedia.org/wiki/Fisher-Yates_shuffle
  local n = #t

  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end

  return t
end
local cocreate = coroutine.create
local coyield = coroutine.yield
local coresume = coroutine.resume
local codead = function(co) return co == nil or coroutine.status(co) == "dead" end
--------------- NODE --------------------
btnode = {}
function btnode:new(...)
   local _o = {}
   _o.status=""
   _o.ticknum = -1
   setmetatable(_o, self)
   self.__index = self
   _o:init(...)
   return _o
end
--------------- SEQUENCE ----------------
btsequence = inheritsFrom(btnode)
function btsequence:init(...)
  self.childs = {}
  for i,v in ipairs(arg) do
    table.insert(self.childs,v)
  end
end
function btsequence:run(pbehavtree)
  --debugprint("btsequence:run")
  local _s
  for i=1,#self.childs do
    --debugprint("btsequence:run "..i)
    if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
      _s = self.childs[i].status
    else
      _s = self.childs[i]:run(pbehavtree)
    end
    if _s==false or _s=="Running" then
      --debugprint("btsequence ends2")
      --debugprint(_s)
      self.ticknum,self.status = pbehavtree.ticknum, _s
      return _s
    end
  end
  --debugprint("btsequence ends")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- SELECTOR ----------------
btselector = inheritsFrom(btnode)
function btselector:init(...)
  self.childs = {}
  for i,v in ipairs(arg) do
    table.insert(self.childs,v)
  end
end
function btselector:run(pbehavtree)
  --debugprint("btselector:run")
  local _s
  for i=1,#self.childs do
     --debugprint("btselector "..i)
     if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
       _s = self.childs[i].status
     else
       _s = self.childs[i]:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        --debugprint("btselector ends2")
        --debugprint(_s)
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
     end
  end
  --debugprint("btselector ends")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- RANDOMSELECTOR ----------------
btrandomselector = inheritsFrom(btnode)
function btrandomselector:init(...)
  self.childs = {}
  for i,v in ipairs(arg) do
    table.insert(self.childs,v)
  end
end
function btrandomselector:run(pbehavtree)
  --debugprint("btrandomselector:run")
  local _s
  if self.status ~= "Running" or self.ticknum ~= pbehavtree.ticknum-1 then
    shuffle(self.childs)
  end
  for i=1,#self.childs do
     if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
       _s = self.childs[i].status
     else
       _s = self.childs[i]:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
     end
  end
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- FILTER ----------------
btfilter = inheritsFrom(btnode)
function btfilter:init(pcondition,pchild)
  self.childs = {pchild}
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btfilter:run(pbehavtree)
  --debugprint("btfilter:run "..type(self.condition))
  local _s
  if self.status ~= "Running" or self.ticknum ~= pbehavtree.ticknum-1 then
    if type(self.condition) == "function" then
      _s = self.condition(pbehavtree.object,pbehavtree)
      if _s == false then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  for i=1,#self.childs do
     if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
       _s = self.childs[i].status
     else
       _s = self.childs[i]:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
     end
  end
  --debugprint("btfilter:run result ")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATOR ----------------
btdecorator = inheritsFrom(btnode)
function btdecorator:init(pcondition,pchild)
  self.childs = {pchild}
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btdecorator:run(pbehavtree)
  --debugprint("btdecorator:run "..type(self.condition))
  local _s
  if self.status ~= "Running" or self.ticknum ~= pbehavtree.ticknum-1 then
    if type(self.condition) == "function" then
      _s = self.condition(pbehavtree.object,pbehavtree)
      if _s == false then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  for i=1,#self.childs do
     if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
       _s = self.childs[i].status
     else
       _s = self.childs[i]:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
     end
  end
  --debugprint("btdecorator:run result ")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATORCONTINUE ----------------
btdecoratorcontinue = inheritsFrom(btnode)
function btdecoratorcontinue:init(pcondition,pchild)
  self.childs = {pchild}
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btdecoratorcontinue:run(pbehavtree)
  --debugprint("btdecoratorcontinue:run "..type(self.condition))
  local _s
  if self.status ~= "Running" or self.ticknum ~= pbehavtree.ticknum-1 then
    if type(self.condition) == "function" then
      _s = self.condition(pbehavtree.object,pbehavtree)
      if _s == false then
        _s = true
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  for i=1,#self.childs do
     if self.status == "Running" and self.ticknum == pbehavtree.ticknum-1 and self.childs[i].status~="Running" and self.childs[1].ticknum== pbehavtree.ticknum-1 then
       _s = self.childs[i].status
     else
       _s = self.childs[i]:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        self.ticknum,self.status = pbehavtree.ticknum, _s
        return _s
     end
  end
  --debugprint("btdecoratorcontinue:run result ")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- WAIT ----------------
btwait = inheritsFrom(btnode)
function btwait:init(pcondition,ptimeout,pchild)
  self.childs = {pchild}
  self.timeout = ptimeout
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btwait:run(pbehavtree)
--TODO da fare
end
--------------- WAITCONTINUE ----------------
btwaitcontinue = inheritsFrom(btnode)
function btwaitcontinue:init(pcondition,ptimeout,pchild)
  self.childs = {pchild}
  self.timeout = ptimeout
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btwaitcontinue:run(pbehavtree)
--TODO da fare
end
--------------- REPEATUNTIL ----------------
btrepeatuntil = inheritsFrom(btnode)
function btrepeatuntil:init(pcondition,ptimeout,pchild)
  self.childs = {pchild}
  self.timeout = ptimeout
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btrepeatuntil:run(pbehavtree)
--TODO da fare
end
--------------- SLEEP --------------------
function btSleep(timeout)
    return btwaitcontinue:new(function() return false end, nil, timeout)
end
--------------- CONDITION ----------------
btcondition = inheritsFrom(btnode)
function btcondition:init(pcondition)
  if type(self.condition) == "string" then
    self.condition = loadstring(pcondition)
  else
    self.condition = pcondition
  end
end
function btcondition:run(pbehavtree)
  --debugprint("btcondition:run "..type(self.condition))
  local _s
  if type(self.condition) == "function" then
    _s = self.condition(pbehavtree.object,pbehavtree)
  end
  --debugprint("btcondition:run result ")
  --debugprint(_s)
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- ACTION ----------------
btaction = inheritsFrom(btnode)
function btaction:init(paction)
  if type(self.action) == "string" then
    self.action = loadstring(paction)
  else
    self.action = paction
  end
  self.runner = nil
end
function btaction:run(pbehavtree)
  --debugprint("btaction:run")
  local _s
  if type(self.action) == "function" then
    _s = self.action(pbehavtree.object,pbehavtree)
  end
  self.ticknum,self.status = pbehavtree.ticknum, _s
  if _s == "Running" then
  end
  return _s
end
--------------- ACTIONRESUME ----------------
btactionresume = inheritsFrom(btnode)
function btactionresume:init(paction)
  if type(self.action) == "string" then
    self.action = loadstring(paction)
  else
    self.action = paction
  end
  self.runner = nil
end
function btactionresume:run(pbehavtree)
  --debugprint("btactionresume:run")
  local _status, _s
  if type(self.action) == "function" then
    if self.status ~= "Running" or self.ticknum ~= pbehavtree.ticknum-1 then
      self.runner = cocreate(self.action)
    end
    if codead(self.runner) then
      self.runner = cocreate(self.action)
    end
    _status,_s = coresume(self.runner, pbehavtree.object,pbehavtree)
  end
  self.ticknum,self.status = pbehavtree.ticknum, _s
  return _s
end
--------------- RETURNTRUE ---------------
function btReturnTrue()
  return true
end
--------------- RETURNFALSE ---------------
function btReturnFalse()
  return false
end
--------------- BEHAVTREE ----------------
function BTLua.behavtree:init(pname,pobject,ptree,pfunctionstart,pfunctionend)
  --debugprint("BTLua.behavtree:init")
  self.name=pname
  self.object=pobject
  self.tree={ptree}
  self.functionstart = pfunctionstart
  self.functionend = pfunctionend
  self.initialized=false
  self:initialize()
end

function BTLua.behavtree:run()

  --debugprint("BTLua.behavtree:run "..self.name)

  if (self.initialized==false) then
    self:initialize()
  end

  if self.functionstart then
    self.functionstart(self.object,self)
  end

  self.ticknum = self.ticknum + 1
  if self.ticknum > 10000 then
    for i=1,#self.tree do
      self:resetTicknumChilds(self.tree[i])
    end
  end
  self.laststatus = nil
  local _s
  for i=1,#self.tree do
    --debugprint(i.."/"..#self.tree)
     _s = self.tree[i]:run(self)
  end
  self.laststatus = _s

  if self.functionend then
    self.functionend(self.object,self)
  end

  --debugprint(_s)

  return self.laststatus
end

function BTLua.behavtree:initialize()
  for i=1,#self.tree do
    self:setParentChilds(self.tree[i],nil)
  end
end

function BTLua.behavtree:setParentChilds(pnode,pparent)
  if pnode then
    pnode.parent =pparent
    if pnode.childs then
      for i=1,#pnode.childs do
        self:setParentChilds(pnode.childs[i],pnode)
      end
    end
  end
end

function BTLua.behavtree:resetTicknumChilds(pbehavtree,pnode)
  if pnode then
    pnode.ticknum =pnode.ticknum-pbehavtree.ticknum
    if pnode.childs then
      for i=1,#pnode.childs do
        self:resetTicknumChilds(pbehavtree,pnode.childs[i])
      end
    end
  end
end

--debugprint=print
