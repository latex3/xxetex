local fontid = token.create("fontid")

local function XeTeXfonttype()
    token.put_next(fontid)
    local fid = token.scan_int()
    local tfmdata = font.getfont(fid)
    local fonttype = tfmdata.format == "opentype" and 2 or 0
    tex.print([[\numexpr]] .. fonttype .. [[\relax]])
end

local function XeTeXfirstfontchar()
    token.put_next(fontid)
    local fid = token.scan_int()
    local tfmdata = font.getfont(fid)
    local min
    for slot in pairs(tfmdata.characters) do
        min = min and (slot < min and slot or min) or slot
    end
    tex.print([[\numexpr]] .. min .. [[\relax]])
end

local function XeTeXlastfontchar()
    token.put_next(fontid)
    local fid = token.scan_int()
    local tfmdata = font.getfont(fid)
    local max
    for slot in pairs(tfmdata.characters) do
        max = max and (slot > max and slot < 2^16 and slot or max) or slot
    end
    tex.print([[\numexpr]] .. max .. [[\relax]])
end

local function XeTeXglyph()
    local index = token.scan_int()
    local tfmdata = font.getfont(font.current())
    if tfmdata.format ~= "opentype"
        and tfmdata.format ~= "truetype" then
        tex.error([[Cannot use \XeTeXglyph with ]] ..
            tfmdata.name .. tfmdata.format  ..
            [[; not opentype or truetype]])
    end
    for slot, char in pairs(tfmdata.characters) do
        if char.index == index then
            tex.print(utf.char(char.unicode))
            return
        end
    end
end

local function XeTeXcountglyphs()
    token.put_next(fontid)
    local fid = token.scan_int()
    local tfmdata = font.getfont(fid)
    local count = 0
    if tfmdata.format == "opentype" then
        for _ in pairs(tfmdata.characters) do
            count = count + 1
        end
    end
    tex.print([[\numexpr]] .. count .. [[\relax]])
end

local function XeTeXglyphname()
    token.put_next(fontid)
    local fid = token.scan_int()
    local index = token.scan_int()
    local tfmdata = font.getfont(fid)
    if tfmdata.format ~= "opentype" then
        tex.error([[Cannot use \XeTeXglyphname with ]] ..
            tfmdata.name .. [[; not a native platform font]])
    end
    local count = 0
    for slot, char in pairs(tfmdata.shared.rawdata.descriptions) do
        if char.index == index then
            tex.print(char.name)
            return
        end
    end
end

local function XeTeXglyphindex()
    local k = string.gsub(token.scan_string(),'"','')
    token.scan_keyword(' ') -- remove optional space
    local tfmdata = font.getfont(font.current())
    if tfmdata.format ~= "opentype" then
        tex.error([[Cannot use \XeTeXglyphindex with ]] ..
            tfmdata.name .. [[; not a native platform font]])
    end
    local index = 0
    for slot, char in pairs(tfmdata.shared.rawdata.descriptions) do
        if char.name == k then
            index = char.index
            break
        end
    end
    tex.print([[\numexpr]] .. index .. [[\relax]])
end

local function XeTeXcharglyph()
    local id = token.scan_int()
    local tfmdata = font.getfont(font.current())
    if tfmdata.format ~= "opentype" then
        tex.error([[Cannot use \XeTeXcharglyph with ]] ..
            tfmdata.name .. [[; not a native platform font]])
    end
    local index = tfmdata.characters[id].index
    tex.print([[\numexpr]] .. index .. [[\relax]])
end

local function XeTeXglyphbounds()
    local edge = token.scan_int()
    local slot = token.scan_int()
    local tfmdata = font.getfont(font.current())
    if tfmdata.format ~= "opentype" then
        tex.error([[Cannot use \XeTeXglyphname with ]] ..
            tfmdata.name .. [[; not a native platform font]])
    end
    for _,char in pairs(tfmdata.shared.rawdata.descriptions) do
        if char and char.index == slot then
            local bbox = char.boundingbox
            local dimen = 0
            if edge == 1 then
                dimen = bbox and bbox[1] / 100 * 2^16 or 0
            elseif edge == 2 then
                dimen = tfmdata.characters[char.unicode].height
            elseif edge == 3 then
                dimen = bbox and (char.width - bbox[3]) / 100 * 2^16 or 0
            elseif edge == 4 then
                dimen = tfmdata.characters[char.unicode].depth
            end
            tex.print([[\dimexpr]] .. tex.round(dimen) .. [[sp\relax]])
            break
        end
    end
end


-- Character Classes


local xxetexclasses={}
local xxetexclasstoks={}

local function XeTeXcharclass()
local a = token.scan_int()
local b = token.scan_int()
xxetexclasses[a]=b
end
local func = luatexbase.new_luafunction 'XeTeXcharclass'
token.set_lua('XeTeXcharclass', func , "protected")
lua.get_functions_table()[func] = XeTeXcharclass

local function XeTeXinterchartoks()
local a = token.scan_int()
local b = token.scan_int()
token.scan_keyword(' ')
token.scan_keyword('=')
token.scan_keyword(' ')
local c = token.scan_argument(false)
xxetexclasstoks[a .. "/" .. b]=c
end
local func = luatexbase.new_luafunction 'XeTeXinterchartoks'
token.set_lua('XeTeXinterchartoks', func , "protected")
lua.get_functions_table()[func] = XeTeXinterchartoks




local function xxetexinterchartoks(head)
    if not (tex.count.XXeTeXinterchartokenstate > 0) then
        return head
    end
    local glyphid=node.id"glyph"
    local xxetexflag=-1
    for n in node.traverse(head) do
    local a = 4095
    local b = 4095
    if xxetexflag==n then xxetexflag=-1 end
    if xxetexflag ==-1 then
    if n.id==glyphid then
     a = xxetexclasses[n.char] or 0
    end
    if n.next and n.next.id==glyphid then
     b = xxetexclasses[n.next.char] or 0
    end
        if xxetexclasstoks[a .. "/" .. b] then
	    xxetexflag=-1
	    if n.next then xxetexflag=n.next end
	    tex.scantoks(xxetexinterchartoksnum,0,xxetexclasstoks[a .. "/" .. b])
            tex.runtoks("xxetexruninterchartoks")
            local box = tex.getbox("xxetex@intercharbox")
            node.insert_after(head, n, node.copy_list(box))	
        end
    end
    end
    return head
end

-- graphics




local function XeTeXpicfile()
local filename = token.scan_string()
local t=img.scan{filename=filename}
--local t ={}
--t.filename =  token.scan_string()
local scan=false
-- ignore key order for now
repeat
  scan=false
  token.scan_keyword(' ')
  local scale=1
  if token.scan_keyword('scaled') then
    scan=true
    scale=  0.0001*token.scan_int()
    -- t.width=scale*t.xsize
    -- t.height=scale*t.ysize
  end
  token.scan_keyword(' ')
  if token.scan_keyword('width') then
    scan=true
    t.width=  token.scan_dimen()
  end
  token.scan_keyword(' ')
  if token.scan_keyword('height') then
    scan=true
    t.height=  token.scan_dimen()
  end
  token.scan_keyword(' ')
  if token.scan_keyword('rotated') then
    -- full coverage would need to wrap image 
    scan=true
    local angle=token.scan_real()
    if angle==90 then
      t.transform= 1
    end
  end
until not(scan)
img.write(t)
end
local func = luatexbase.new_luafunction 'XeTeXpicfile'
lua.get_functions_table()[func] = XeTeXpicfile
token.set_lua('XeTeXpicfile', func , "protected")
token.set_lua('XeTeXpdffile', func , "protected")

return {
    XeTeXfonttype      = XeTeXfonttype,
    XeTeXfirstfontchar = XeTeXfirstfontchar,
    XeTeXlastfontchar  = XeTeXlastfontchar,
    XeTeXglyph         = XeTeXglyph,
    XeTeXcountglyphs   = XeTeXcountglyphs,
    XeTeXglyphname     = XeTeXglyphname,
    XeTeXglyphindex    = XeTeXglyphindex,
    XeTeXcharglyph     = XeTeXcharglyph,
    XeTeXglyphbounds   = XeTeXglyphbounds,
    --
    xxetexinterchartoks = xxetexinterchartoks,
}
