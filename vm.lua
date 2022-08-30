function PrintTable(tableToPrint, depth)
	if depth == nil then
		print('{')
		PrintTable(tableToPrint, 1)
		print('}')
	else
		local last = 0
		for i,v in pairs(tableToPrint) do
			last = i
		end
		for i, v in pairs(tableToPrint) do
			if type(v) == 'table' and #v > 0 then
        if v == getfenv() then
          print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] = getfenv()' .. (i == last and '' or ','))
        else
				  print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] = {')
        end
				PrintTable(v, depth + 1)
				print(string.rep('    ', depth) .. '}' .. (i == last and '' or ','))
			elseif type(v) == 'table' then
				print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] = {}' .. (i == last and '' or ','))
			elseif type(v) == 'function' then
				print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] =  nil' .. (i == last and '' or ',') .. ' -- ' .. tostring(v))
			elseif type(v) == 'string' then
				print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] =  "' .. tostring(v) .. '"' .. (i == last and '' or ','))
			else
				print(string.rep('    ', depth) .. '[' .. tostring(i) .. '] =  ' .. tostring(v) .. (i == last and '' or ','))
			end
		end
	end
end

-- NUMBERS ONLY!!!1
-- Anything else will be ignored
-- Syntax (numbers 0 through 9)
local syntax = {
	[0] = {
		title = "construct number",
		syntax = "<0 * digits> <number>",
		returns = "number",
		examples = {
			"01 = 1",
			"0011 = 11",
			"0000069420 = 69420"
		}
	},

	[1] = {
		title = "set variable",
		syntax = "1 <number variable> <any value>",
		returns = "number",
		examples = {
			"10101 -> Sets variable 1 to 1",
		}
	},

	[2] = {
		title = "construct character",
		syntax = "2 <number charactercode>",
		returns = "a string containing the character",
		examples = {
			"2000106 = \"j\"",
			"101000106 101201 -> Sets variable 1 to 106 then uses its value to convert variable 1 to \"j\"",
		}
	},

	[3] = {
		title = "concatenate",
		syntax = "3 <var value1> <var value2>",
		returns = "the values concatenated together",
		examples = {
			"101000120 102000100 101201 102202 10330102 -> Sets variables 1 and 2 to 120 and 100, constructs chars \"x\" and \"d\" from them, and sets variable 3 to a concatenation of variables 1 and 2 which is the string \"xd\"",
		}
	},

	[4] = {
		title = "getfenv / table index",
		syntax = "4 <var table> <var field>",
		returns = "4 returns the result of getfenv() the first time it is used, then is subsequently used to index values within tables",
		examples = {
			"1014 1020095 1030071 102202 103203 10430203 10540104 = sets variable 1 to getfenv(), sets variables 2 and 3 to 95 and 71, constructs variables 2 and 3 as chars \"_\" and \"G\", sets variable 4 to the concatenation of variables 2 and 3 (\"_G\"), and sets variable 5 to getfenv()[\"_G\"]"
		}
	},

	[5] = {
		title = "call function",
		syntax = "5 <function> <number args> <tuple args>",
		returns = "the return of the function inside a table in case it returns multiple args",
		examples = {
			"not yet"
		}
	},
  [6] = {
    title = "set value",
    syntax = "6 <table> <key> <value>",
    returns = "nothing",
    examples = {
      "br"
    }
  }
}

local program = [[
1 02 4

1 09 03
1 0010 04
1 0011 05
1 0012 06
1 0013 07
1 0014 08

1 09 000112
1 0010 000114
1 0011 000105
1 0012 000110
1 0013 000116
1 0014 000121

1 09 2 03
1 0010 2 04
1 0011 2 05
1 0012 2 06
1 0013 2 07
1 0014 2 08

1 09 3 03 04
1 09 3 03 05
1 09 3 03 06
1 09 3 03 07

1 0012 2 0097
1 0013 2 000101

1 0014 3 08 07
1 0014 3 08 06

1 0010 4 02 03

5 04 01 08
]]


local function getnumber(input)
	local len = string.len(input)
	local output = ""
	for i = 1, len, 1 do
		local char = string.sub(input, i, i)
		if char == "1"
			or char == "2"
			or char == "3"
			or char == "4"
			or char == "5"
			or char == "6"
			or char == "7"
			or char == "8"
			or char == "9"
			or char == "0" then
			output = output .. char
		end
	end
	return output
end

local function tokenize(input)
	local done = false

	local i_p = 1

	local tokens = {}

	local function addtoken(token)
		table.insert(tokens, token)
	end

	local function get_instruction()
		local opcode = tonumber(string.sub(input, i_p, i_p))
		if opcode == 0 then
			i_p = i_p + 1
			local digits = 1
			local fullNumber = ""
			local gotFullDigits = false
			local gotFullNumber = false
			while gotFullNumber == false do
				local instruction_part = tonumber(string.sub(input, i_p, i_p))
				if instruction_part == 0 and gotFullDigits == false then
					digits = digits + 1
				else
					gotFullDigits = true
					fullNumber = fullNumber .. tostring(instruction_part)
					digits = digits - 1
					if digits == 0 then
						gotFullNumber = true
					end
				end
				i_p = i_p + 1
			end
			return {0, tonumber(fullNumber)}
		elseif opcode == nil then
			return nil
		else
			i_p = i_p + 1
			return {opcode}
		end
	end

	while done == false do
		local token = get_instruction()
		if token ~= nil then
			addtoken(token)
		else
			done = true
		end
	end
	return tokens
end

local function setuptokens(tokens)
	local instr_count = #tokens
	local arguments = {
		["_ENV"] = 0,
		["_NUMBER"] = 0,
		["_VAR"] = 2,
		["_CHAR"] = 1,
		["_CONCAT"] = 2,
		["_INDEX"] = 2,
		["_CALL"] = 2,
    ["_SET"] = 3
	}
	local envarg = false
	for _, v in pairs(tokens) do
		if v[1] == 4 and envarg == false then
			envarg = true
			v[1] = "_ENV"
		elseif v[1] == 0 then
			v[1] = "_NUMBER"
		elseif v[1] == 1 then
			v[1] = "_VAR"
		elseif v[1] == 2 then
			v[1] = "_CHAR"
		elseif v[1] == 3 then
			v[1] = "_CONCAT"
		elseif v[1] == 4 then
			v[1] = "_INDEX"
		elseif v[1] == 5 then
			v[1] = "_CALL"
		elseif v[1] == 6 then
			v[1] = "_SET"
		end
	end
	for i_p = instr_count, 1, -1 do
		local currentinst = tokens[i_p]
		local argstotake = arguments[currentinst[1]]
		if argstotake > 0 then
			currentinst[2] = {}
			for i = 1, argstotake, 1 do
				local argtotake = tokens[i_p + i]
				table.insert(currentinst[2], argtotake)
				tokens[i_p + i] = nil
			end
		end
    if currentinst[1] == "_CALL" then
      local funcArgsToTake = currentinst[2][2][2]
      if funcArgsToTake > 0 then
			  for i = 1, funcArgsToTake, 1 do
			  	local argtotake = tokens[i_p + 2 + i]
			  	table.insert(currentinst[2], argtotake)
			  	tokens[i_p + 2 + i] = nil
			  end
      end
    end
	end
	return tokens
end

local function runTokens(tokens)
	local env_vars = {}
	local function run_token(token)
		local opcode, args = token[1], token[2]
		if opcode == "_NUMBER" then
			if type(args) ~= "number" then
				return 0
			end
			if env_vars[args] ~= nil then
				return env_vars[args]
			else
				return args
			end
		elseif opcode == "_VAR" then
			local varindex, value = run_token(args[1]), run_token(args[2])
			env_vars[varindex] = value
		elseif opcode == "_ENV" then
			return getfenv()
		elseif opcode == "_CHAR" then
			local char = string.char(run_token(args[1]))
			return char
		elseif opcode == "_CONCAT" then
			local a, b = run_token(args[1]), run_token(args[2])
			local c, d = pcall(function() return (a .. b) end)
			if c == false then
				warn("Unsuccessful concatenation of (" .. tostring(a) .. ") and (" .. tostring(b) .. ")!")
				return nil
			end
			return d
		elseif opcode == "_INDEX" then
			local parent, child = run_token(args[1]), run_token(args[2])
			return parent[child]
		elseif opcode == "_CALL" then
      local funcArgs = {}
      for i, arg in pairs(args) do
        if i > 2 then
          table.insert(funcArgs, run_token(arg))
        end
      end
      run_token(args[1])(unpack(funcArgs))
    elseif opcode == "_SET" then
      local tab, idx, val = run_token(args[1]), run_token(args[2]), run_token(args[3])
      tab[idx] = val
    end
	end
	for _, v in pairs(tokens) do
		run_token(v)
    --PrintTable(env_vars)
	end
  PrintTable(env_vars)
end

local tokensToRun = setuptokens(tokenize(getnumber(program)))
PrintTable(tokensToRun)
runTokens(tokensToRun)
