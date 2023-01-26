
xxclasses={}
xxclasstoks={}

function XeTeXcharclass()
local a = token.scan_int()
local b = token.scan_int()
xxclasses[a]=b
end
local func = luatexbase.new_luafunction 'XeTeXcharclass'
token.set_lua('XeTeXcharclass', func , "protected")
lua.get_functions_table()[func] = XeTeXcharclass

function XeTeXinterchartoks()
local a = token.scan_int()
local b = token.scan_int()
token.scan_keyword(' ')
token.scan_keyword('=')
token.scan_keyword(' ')
local c = token.scan_argument(false)
xxclasstoks[a .. "/" .. b]=c
end
local func = luatexbase.new_luafunction 'XeTeXinterchartoks'
token.set_lua('XeTeXinterchartoks', func , "protected")
lua.get_functions_table()[func] = XeTeXinterchartoks


glyphid=node.id"glyph"

local function xxinterchartoks(head)
    if not (tex.count.XeTeXinterchartokenstate > 0) then
        return head
    end
    xxflag=-1
    for n in node.traverse(head) do
    local a = 4095
    local b = 4095
    if xxflag==n then xxflag=-1 end
    if xxflag ==-1 then
    if n.id==glyphid then
     a = xxclasses[n.char] or 0
    end
    if n.next and n.next.id==glyphid then
     b = xxclasses[n.next.char] or 0
    end
        if xxclasstoks[a .. "/" .. b] then
	print("AAb" .. xxruninterchartoksnum)
	print(a,b)
	print("AAc" .. xxclasstoks[a .. "/" .. b])
	    xxflag=1
	    if n.next then xxflag=n.next end
	    tex.scantoks(xxinterchartoksnum,0,xxclasstoks[a .. "/" .. b])
            tex.runtoks("xxruninterchartoks")
            local box = tex.getbox("xxintercharbox")
            node.insert_after(head, n, node.copy_list(box))	
        end
    end
    end
    return head
end

luatexbase.add_to_callback("pre_linebreak_filter", xxinterchartoks,"xx hmm")