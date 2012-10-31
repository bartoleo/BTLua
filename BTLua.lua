--- BTLua
if not BTLua then
  BTLua={}
end
BTLua.BTree = {}
function BTLua.BTree:new(...)
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
BTLua.node = {}
function BTLua.node:new(...)
 local _o = {}
 setmetatable(_o, self)
 self.__index = self
 _o:init(...)
 return _o
end
--------------- SEQUENCE ----------------
BTLua.Sequence = inheritsFrom(BTLua.node)
function BTLua.Sequence:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  local arg = { ... }
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function BTLua.Sequence:run(pbehavtree)
  --debugprint("BTLua.Sequence:run")
  local _s, _child
  for i=1,#self.c do
    _child = self.c[i]
    --debugprint("BTLua.Sequence:run "..i)
    if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n == pbehavtree.ticknum-1 then
      _s = _child.s
    else
      _s = _child:run(pbehavtree)
    end
    if _s==false or _s=="Running" then
      --debugprint("BTLua.Sequence ends2")
      --debugprint(_s)
      self.n,self.s = pbehavtree.ticknum, _s
      return _s
    end
  end
  --debugprint("BTLua.Sequence ends")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- SELECTOR ----------------
BTLua.Selector = inheritsFrom(BTLua.node)
function BTLua.Selector:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  local arg = { ... }
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function BTLua.Selector:run(pbehavtree)
  --debugprint("BTLua.Selector:run")
  local _s, _child
  for i=1,#self.c do
     --debugprint("BTLua.Selector "..i)
     _child = self.c[i]
     if self.s == "Running" and self.n == pbehavtree.ticknum-1 and _child.s~="Running" and _child.n== pbehavtree.ticknum-1 then
       _s = _child.s
     else
       _s = _child:run(pbehavtree)
     end
     if _s==true or _s=="Running" then
        --debugprint("BTLua.Selector ends2")
        --debugprint(_s)
        self.n,self.s = pbehavtree.ticknum, _s
        return _s
      end
    end
  --debugprint("BTLua.Selector ends")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- RANDOMSELECTOR ----------------
BTLua.RandomSelector = inheritsFrom(BTLua.node)
function BTLua.RandomSelector:init(...)
  self.s = ""
  self.n = -1
  self.c = {}
  local arg = { ... }
  for i,v in ipairs(arg) do
    table.insert(self.c,v)
  end
end
function BTLua.RandomSelector:run(pbehavtree)
  --debugprint("BTLua.RandomSelector:run")
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
BTLua.Filter = inheritsFrom(BTLua.node)
function BTLua.Filter:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function BTLua.Filter:run(pbehavtree)
  --debugprint("BTLua.Filter:run "..type(self.w))
  local _s, _child
  local _object, _btree = pbehavtree.object, pbehavtree
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
  --debugprint("BTLua.Filter:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATOR ----------------
BTLua.Decorator = inheritsFrom(BTLua.node)
function BTLua.Decorator:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function BTLua.Decorator:run(pbehavtree)
  --debugprint("BTLua.Decorator:run "..type(self.w))
  local _s
  local _object, _btree = pbehavtree.object, pbehavtree
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
  --debugprint("BTLua.Decorator:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- DECORATORContinue ----------------
BTLua.DecoratorContinue = inheritsFrom(BTLua.node)
function BTLua.DecoratorContinue:init(pcondition,pchild)
  self.s = ""
  self.n = -1
  self.c = {pchild}
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function BTLua.DecoratorContinue:run(pbehavtree)
  --debugprint("BTLua.DecoratorContinue:run "..type(self.w))
  local _s
  local _object, _btree = pbehavtree.object, pbehavtree
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
  --debugprint("BTLua.DecoratorContinue:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- WAIT ----------------
BTLua.Wait = inheritsFrom(BTLua.node)
function BTLua.Wait:init(pcondition,ptimeout,pchild)
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
function BTLua.Wait:run(pbehavtree)
--TODO da fare
end
--------------- WAITContinue ----------------
BTLua.WaitContinue = inheritsFrom(BTLua.node)
function BTLua.WaitContinue:init(pcondition,ptimeout,pchild)
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
function BTLua.WaitContinue:run(pbehavtree)
--TODO da fare
end
--------------- REPEATUNTIL ----------------
BTLua.RepeatUntil = inheritsFrom(BTLua.node)
function BTLua.RepeatUntil:init(pcondition,ptimeout,pchild)
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
function BTLua.RepeatUntil:run(pbehavtree)
--TODO da fare
end
--------------- SLEEP --------------------
function BTLua.Sleep(timeout)
  return BTLua.WaitContinue:new(function() return false end, nil, timeout)
end
--------------- CONDITION ----------------
BTLua.Condition = inheritsFrom(BTLua.node)
function BTLua.Condition:init(pcondition)
  self.s = ""
  self.n = -1
  if type(self.w) == "string" then
    self.w = loadstring(pcondition)
  else
    self.w = pcondition
  end
end
function BTLua.Condition:run(pbehavtree)
  --debugprint("BTLua.Condition:run "..type(self.w))
  local _s
  local _object, _btree = pbehavtree.object, pbehavtree
  if type(self.w) == "function" then
    _s = self.w(pbehavtree.object,pbehavtree)
  end
  --debugprint("BTLua.Condition:run result ")
  --debugprint(_s)
  self.n,self.s = pbehavtree.ticknum, _s
  return _s
end
--------------- ACTION ----------------
BTLua.Action = inheritsFrom(BTLua.node)
function BTLua.Action:init(paction)
  self.s = ""
  self.n = -1
  if type(self.a) == "string" then
    self.a = loadstring(paction)
  else
    self.a = paction
  end
  self.r = nil
end
function BTLua.Action:run(pbehavtree)
  --debugprint("BTLua.Action:run")
  local _s
  local _object, _btree = pbehavtree.object, pbehavtree
  if type(self.a) == "function" then
    _s = self.a(pbehavtree.object,pbehavtree)
  end
  self.n,self.s = pbehavtree.ticknum, _s
  if _s == "Running" then
  end
  return _s
end
--------------- ActionResume ----------------
BTLua.ActionResume = inheritsFrom(BTLua.node)
function BTLua.ActionResume:init(paction)
  self.s = ""
  self.n = -1
  if type(self.a) == "string" then
    self.a = loadstring(paction)
  else
    self.a = paction
  end
  self.r = nil
end
function BTLua.ActionResume:run(pbehavtree)
  --debugprint("BTLua.ActionResume:run")
  local _status, _s
  local _object, _btree = pbehavtree.object, pbehavtree
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
function BTLua.ReturnTrue()
  return true
end
--------------- RETURNFALSE ---------------
function BTLua.ReturnFalse()
  return false
end
--------------- BEHAVTREE ----------------
function BTLua.BTree:init(pname,pobject,ptree,pfunctionstart,pfunctionend)
  --debugprint("BTLua.BTree:init")
  self.name=pname
  self.object=pobject
  self.tree={ptree}
  self.functionstart = pfunctionstart
  self.functionend = pfunctionend
  self.initialized = false
  self:initialize()
end

function BTLua.BTree:run()

  --debugprint("BTLua.BTree:run "..self.name)

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

function BTLua.BTree:initialize()
  for i=1,#self.tree do
    self:setParentChilds(self.tree[i],nil)
  end
end

function BTLua.BTree:setParentChilds(pnode,pparent)
  if pnode then
    pnode.p =pparent
    if pnode.childs then
      for i=1,#pnode.childs do
        self:setParentChilds(pnode.childs[i],pnode)
      end
    end
  end
end

function BTLua.BTree:resetTicknumChilds(pbehavtree,pnode)
  if pnode then
    pnode.ticknum =pnode.ticknum-pbehavtree.ticknum
    if pnode.childs then
      for i=1,#pnode.childs do
        self:resetTicknumChilds(pbehavtree,pnode.childs[i])
      end
    end
  end
end

function BTLua.BTree:addNode(pparent,pnode)
  if pparent then
    table.insert(pparent.c,pnode)
  else
    table.insert(self.tree,pnode)
  end
  self.initialized = false
end

function BTLua.BTree:parseTable(pparent,ptable)
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

function BTLua.BTree:parseNodeAndAdd(pparent,pnode)
  local _node = self:parseNode(pnode)
  self:addNode(pparent,_node)
  if pnode.childen then
    for i = 1,#pnode.children do
      self:parseNodeAndAdd(_node,pnode.children[i])
    end
  end
end

function BTLua.BTree:parseFunc(pfunc)
  -- Compatibility: Lua-5.0
  local function split(str, delim, maxNb)
      -- Eliminate bad cases...
      if string.find(str, delim) == nil then
          return { str }
      end
      if maxNb == nil or maxNb < 1 then
          maxNb = 0    -- No limit
      end
      local result = {}
      local pat = "(.-)" .. delim .. "()"
      local nb = 0
      local lastPos
      for part, pos in string.gfind(str, pat) do
          nb = nb + 1
          result[nb] = part
          lastPos = pos
          if nb == maxNb then break end
      end
      -- Handle the last field
      if nb ~= maxNb then
          result[nb + 1] = string.sub(str, lastPos)
      end
      return result
  end
  if pfunc==nil or pfunc=="" then
    return nil
  end
  local _funcs = split(pfunc,"|")
  local _return ={}
  local _object, _btree = self.object, self
  for i,v in ipairs(_funcs) do
    if v ~= "" then
      local _function
      local _strfunc = string.gsub(v, "#", "_object.")
      local _strfunc = string.gsub(v, "@", "_G.")
      local _strfunc = string.gsub(v, "!", "_btree.")
      if (string.sub(_strfunc,1,1)=="'" or string.sub(_strfunc,-1)=='"') and string.sub(_strfunc,1,1)==string.sub(_strfunc,-1) then
        -- string
        table.insert(_return,string.sub(_strfunc,2,-1))
      elseif tonumber(_strfunc)~=nil then
        -- number
        table.insert(_return,tonumber(_strfunc))
      else
        _function = loadstring("return ".._strfunc)
      end
    end
  end
  return _return
end

function BTLua.BTree:parseNode(pnode)
  local _node = nil
  local _type = string.upper(pnode.type)
  local _func = nil
  if pnode.func then
    _func =  BTLua.BTree:parseFunc(pnode.func)
  end
  if _type =="ACTION" then
    _node =  BTLua.Action:new(unpack(_func))
  end
  if _type =="ACTIONRESUME" then
    _node =  BTLua.Action:new(unpack(_func))
  end
  if _type =="CONDITION" then
    _node =  BTLua.Condition:new(unpack(_func))
  end
  if _type =="SELECTOR" then
    _node =  BTLua.Selector:new()
  end
  if _type =="RANDOMSELECTOR" then
    _node =  BTLua.RandomSelector:new()
  end
  if _type =="SEQUENCE" then
    _node =  BTLua.Sequence:new()
  end
  if _type =="FILTER" then
    _node =  BTLua.Filter:new(unpack(_func))
  end
  if _type =="DECORATOR" then
    _node =  BTLua.Decorator:new(unpack(_func))
  end
  if _type =="DECORATORCONTINUE" then
    _node =  BTLua.DecoratorContinue:new(unpack(_func))
  end
  if _type =="WAIT" then
    _node =  BTLua.Wait:new(unpack(_func))
  end
  if _type =="WAITCONTINUE" then
    _node =  BTLua.WaitContinue:new(unpack(_func))
  end
  if _type =="REPEATUNTIL" then
    _node =  BTLua.RepeatUntil:new(unpack(_func))
  end
  if _type =="SLEEP" then
    _node =  BTLua.Sleep:new(unpack(_func))
  end
  return _node
end

--debugprint=print
