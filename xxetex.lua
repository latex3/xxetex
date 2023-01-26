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
}
