local match = ngx.re.match
local gsub = ngx.re.gsub
local math_floor = math.floor
local tonumber = tonumber
local tostring = tostring
local type = type
local string_format = string.format
local cjson_encode = require "cjson.safe".encode
local cjson_decode = require "cjson.safe".decode

local version = '1.0'

local function utf8len(s)
    local _, cnt = s:gsub('[^\128-\193]',"")
    return cnt
end

local function null_converter(v)
    -- ** used in lua-resty-mysql, what's in pg?
    if tostring(v) == "userdata: NULL" then
        return nil
    else
        return v
    end
end

local function required(kwargs)
    local message = kwargs.message 
      or (kwargs.name and 'you must provide '..kwargs.name) 
      or 'this field is required'
    return function(v)
        if v == nil or v == '' then
            return nil, message
        else
            return v
        end
    end
end

local function not_required(v)
    if v == nil or v == '' then
        return 
    else
        return v
    end
end

local function decode(v, model) 
    return cjson_decode(v) 
end

local function encode(v, model) 
    return cjson_encode(v) 
end

local function number(v, model)
    return tonumber(v)
end

local function as_is(v)
    return v
end

local function maxlength(kwargs)
    if type(kwargs) ~= 'table' then
        kwargs = {number=kwargs}
    end
    local number = kwargs.number
    local message = kwargs.message 
      or "no more than "..number.." characters"
    return function ( value )
        if utf8len(value) > number then
            return nil, message
        else
            return value
        end
    end
end
local function minlength(kwargs)
    if type(kwargs) ~= 'table' then
        kwargs = {number=kwargs}
    end
    local number = kwargs.number
    local message = kwargs.message 
      or "no less than "..number.." characters"
    return function ( value )
        if utf8len(value) < number then
            return nil, message
        else
            return value
        end
    end
end
local function max(kwargs)
    if type(kwargs) ~= 'table' then
        kwargs = {number=kwargs}
    end
    local number = kwargs.number
    local message = kwargs.message 
      or "this value cannot be bigger than "..number
    return function ( value )
        if value > number then
            return nil, message
        else
            return value
        end
    end
end
local function min(kwargs)
    if type(kwargs) ~= 'table' then
        kwargs = {number=kwargs}
    end
    local number = kwargs.number
    local message = kwargs.message 
      or "this value cannot be smaller than "..number
    return function ( value )
        if value < number then
            return nil, message
        else
            return value
        end
    end
end
local function regex(kwargs)
    if type(kwargs) ~= 'table' then
        kwargs = {exp=kwargs}
    end
    local exp = kwargs.exp
    local message = kwargs.message or 'invalid format'
    return function ( value )
        if not match(value, exp, 'jo') then
            return nil, message
        else
            return value
        end
    end
end

local function forbid_empty_array(kwargs)
    local message = kwargs.message 
      or (kwargs.name and 'you must provide '..kwargs.name) 
      or 'this field is required'
    return function(v)
        if #v == 0 then
            return nil, message
        else
            return v
        end
    end
end

local function integer(v)
    local number = tonumber(v)
    if not number then
        return nil, 'integer is required'
    end
    return math_floor(number)
end

local URL_REGEX = '^(https?:)?//.*$' -- yeah baby, just so simple
local function url(value)
    if not match(value, URL_REGEX, 'jo') then
        return nil, 'invalid link format'
    else
        return value
    end
end
local url = regex('^(https?:)?//.*$')

local function encode_as_array(value)
    if value ~= nil and type(value) ~= 'table' then
        return nil, 'this value must be a table'
    end
    return array(value)
end

return {
    required = required, 
    not_required = not_required, 
    maxlength = maxlength, 
    minlength = minlength,
    max = max, 
    min = min, 
    regex = regex,
    forbid_empty_array = forbid_empty_array,
    integer=integer,
    url = url,
    encode = encode,
    decode = decode,
    number = number,
    as_is = as_is,
    null_converter = null_converter,
    encode_as_array = encode_as_array,
}