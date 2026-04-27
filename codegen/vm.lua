 
--[[
 
 
will replaced better asap
 
 
]]
 
 
return function()
 
    return "local _v=setmetatable({},{__index=_ENV or _G});local _x=function(_s)local _f,_e=(loadstring or load)(_s,nil,'t',_v);if not _f then error(_e)end;_v.pairs=pairs;_v.ipairs=ipairs;_v.print=print;_v.tostring=tostring;_v.tonumber=tonumber;_v.type=type;_v.math=math;_v.string=string;_v.table=table;_v.unpack=unpack or table.unpack;_v.select=select;_v.error=error;_v.pcall=pcall;_v.xpcall=xpcall;_v.next=next;_v.rawget=rawget;_v.rawset=rawset;_v.rawequal=rawequal;_v.setmetatable=setmetatable;_v.getmetatable=getmetatable;_v.require=require;_v.load=load;_v.loadstring=loadstring;_v.game=rawget(_ENV or _G,'game');_v.workspace=rawget(_ENV or _G,'workspace');_v.script=rawget(_ENV or _G,'script');local _ok,_er=pcall(_f);if not _ok then error(_er)end;end;"
 
end
 
