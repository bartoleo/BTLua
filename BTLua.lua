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
 setmetatable(_o, self)
 self.__index = self
 _o:init(...)
 return _o
end
--------------- SEQUENCE ----------------
btsequence = inheritsFrom(btnode)
function btsequence:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function btsequence:run(pbehavtree)
  --debugprint("btsequence:run")
  local _s, _child
  for i=1,#self.c do
    _child = self.c[i]
    --debugprint("btsequence:run "..i)
    if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n == pbehavtree.ticknum-1 then
      _s = _child.s
    else
      _s = _child:run(pbehavtree)
    end
    if _s==false or _s=="Running" then
      --debugprint("btsequence ends2")
      --debugprint(_s)
      self.n,self.s = pbehavtree.ticknum, _s
      return _s
    end
  end
  --debugprint("btsequence ends")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- SELECTOR ----------------
btselector = inheritsFrom(btnode)
function btselector:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function btselector:run(pbehavtree)
  --debugprint("btselector:run")
  local _s, _child
  for i=1,#self.c do
     --debugprint("btselector "..i)
     _child = self.c[i]
     if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
       _s = _child.s
     else
       _s = _child:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        --debugprint("btselector ends2")
        --debugprint(_s)
        self.n,self.s = pbehavtree.ticknum, _s
        return _s
      end
    end
  --debugprint("btselector ends")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- RANDOMSELECTOR ----------------
btrandomselector = inheritsFrom(btnode)
function btrandomselector:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function btrandomselector:run(pbehavtree)
  --debugprint("btrandomselector:run")
  local _s, _child
  if self.s ~= "Running" or self.n ~= pbehavtree.ticknum-1 then
    shuffle(self.c)
  end
  for i=1,#self.c do
    _child = self.c[i]
    if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
      _s = _child.s
    else
      _s = _child:run(pbehavtree)
    end
    if _s==true or _s=="Running" then
     self.n,self.s = pbehavtree.ticknum, _s
     return _s
   end
 end
 self.n,self.s = pbehavtree.ticknum, _s
 return _s
end
--------------- FILTER ----------------
btfilter = inheritsFrom(btnode)
function btfilter:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btfilter:run(pbehavtree)
  --debugprint("btfilter:run "..type(self.w))
  local _s, _child
  if self.s ~= "Running" or self.n ~= pbehavtree.ticknum-1 then
    if type(self.w) == "function" then
      _s = self.w(pbehavtree.object,pbehavtree)
      if _s == false then
        self.n,self.s = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  for i=1,#self.c do
    _child = self.c[i]
    if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
      _s = _child.s
    else
      _s = _child:run(pbehavtree)
    end
    if _s==true or _s=="Running" then
     self.n,self.s = pbehavtree.ticknum, _s
     return _s
   end
 end
  --debugprint("btfilter:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATOR ----------------
btdecorator = inheritsFrom(btnode)
function btdecorator:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btdecorator:run(pbehavtree)
  --debugprint("btdecorator:run "..type(self.w))
  local _s
  if self.s ~= "Running" or self.n ~= pbehavtree.ticknum-1 then
    if type(self.w) == "function" then
      _s = self.w(pbehavtree.object,pbehavtree)
      if _s == false then
        self.n,self.s = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  local _child
  for i=1,#self.c do
   if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
     _s = _child.s
   else
     _s = _child:run(pbehavtree)
   end
   if _s==true or _s=="Running" then
    self.n,self.s = pbehavtree.ticknum, _s
    return _s
  end
end
  --debugprint("btdecorator:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATORCONTINUE ----------------
btdecoratorcontinue = inheritsFrom(btnode)
function btdecoratorcontinue:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btdecoratorcontinue:run(pbehavtree)
  --debugprint("btdecoratorcontinue:run "..type(self.w))
  local _s
  if self.s ~= "Running" or self.n ~= pbehavtree.ticknum-1 then
    if type(self.w) == "function" then
      _s = self.w(pbehavtree.object,pbehavtree)
      if _s == false then
        _s = true
        self.n,self.s = pbehavtree.ticknum, _s
        return _s
      end
    end
  end
  local _child
  for i=1,#self.c do
   if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
     _s = _child.s
   else
     _s = _child:run(pbehavtree)
   end
   if _s==true or _s=="Running" then
    self.n,self.s = pbehavtree.ticknum, _s
    return _s
  end
end
  --debugprint("btdecoratorcontinue:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- WAIT ----------------
btwait = inheritsFrom(btnode)
function btwait:init(pcondition,ptimeout,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  self.t = ptimeout
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btwait:run(pbehavtree)
--TODO da fare
end
--------------- WAITCONTINUE ----------------
btwaitcontinue = inheritsFrom(btnode)
function btwaitcontinue:init(pcondition,ptimeout,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  selft = ptimeout
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btwaitcontinue:run(pbehavtree)
--TODO da fare
end
--------------- REPEATUNTIL ----------------
btrepeatuntil = inheritsFrom(btnode)
function btrepeatuntil:init(pcondition,ptimeout,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  self.t = ptimeout
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
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
  self.s = ""
  self.n = -1
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function btcondition:run(pbehavtree)
  --debugprint("btcondition:run "..type(self.w))
  local _s
  if type(self.w) == "function" then
    _s = self.w(pbehavtree.object,pbehavtree)
  end
  --debugprint("btcondition:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- ACTION ----------------
btaction = inheritsFrom(btnode)
function btaction:init(paction)
  self.s = ""
  self.n = -1
  if type(self.a) == "string" then
    self.a = loadstring(paction)
  else
    self.a = paction
  end
  self.r = nil
end
function btaction:run(pbehavtree)
  --debugprint("btaction:run")
  local _s
  if type(self.a) == "function" then
    _s = self.a(pbehavtree.object,pbehavtree)
  end
  self.n,self.s = pbehavtree.ticknum, _s
  if _s == "Running" then
  end
  return _s
end
--------------- ACTIONRESUME ----------------
btactionresume = inheritsFrom(btnode)
function btactionresume:init(paction)
  self.s = ""
  self.n = -1
  if type(self.a) == "string" then
    self.a = loadstring(paction)
  else
    self.a = paction
  end
  self.r = nil
end
function btactionresume:run(pbehavtree)
  --debugprint("btactionresume:run")
  local _status, _s
  if type(self.a) == "function" then
    if self.s ~= "Running" or self.n ~= pbehavtree.ticknum-1 then
      self.r = cocreate(self.a)
    end
    if codead(self.r) then
      self.r = cocreate(self.a)
    end
    _status,_s = coresume(self.r, pbehavtree.object,pbehavtree)
  end
  self.n,self.s = pbehavtree.ticknum, _s
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
  self.initialized = false
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
    pnode.p =pparent
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

function BTLua.behavtree:addNode(pparent,pnode)
  if pparent then
    table.insert(pparent.c,pnode)
  else
    table.insert(self.tree,pnode)
  end
  self.initialized = false
end

function BTLua.behavtree:parseTable(pparent,ptable)
  if pparent == nil then
    self.name = ptable.name or ptable.title or self.name
    self.tree=nil
    self.laststatus=nil
    self.Runningnode=nil
    self.ticknum=0
  end
  if ptable.nodes and ptable.children then
    for i = 1,#ptable.nodes.children do
      self:parseNodeAndAdd(nil,ptable.nodes.children[i])
    end
  end
  self.initialized=false
end

function BTLua.behavtree:parseNodeAndAdd(pparent,pnode)
  local _node = self:parseNode(pnode)
  self:addNode(pparent,_node)
  if pnode.childen then
    for i = 1,#pnode.children do
      self:parseNodeAndAdd(_node,pnode.children[i])
    end
  end
end

function BTLua.behavtree:parseNode(pnode)
  local _node = nil
  local _type = string.upper(pnode.type)
  local _func = pnode.func
  if _type =="ACTION" then
    _node =  BTLua.action:new(_func)
  end
  return _node
end

--debugprint=print
