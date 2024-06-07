local Base64 : {encode : (input : string) -> string} = {}
local UserInputService = game:GetService("UserInputService")

Base64.encodeTable = {
	['0'] = "A", ['1'] = "B", ['2'] = "C", ['3'] = "D", ['4'] = "E", ['5'] = "F",
	['6'] = "G", ['7'] = "H", ['8'] = "I", ['9'] = "J", ['10'] = "K", ['11'] = "L",
	['12'] = "M", ['13'] = "N", ['14'] = "O", ['15'] = "P", ['16'] = "Q", ['17'] = "R",
	['18'] = "S", ['19'] = "T", ['20'] = "U", ['21'] = "V", ['22'] = "W", ['23'] = "X",
	['24'] = "Y", ['25'] = "Z", ['26'] = "a", ['27'] = "b", ['28'] = "c", ['29'] = "d",
	['30'] = "e", ['31'] = "f", ['32'] = "g", ['33'] = "h", ['34'] = "i", ['35'] = "j",
	['36'] = "k", ['37'] = "l", ['38'] = "m", ['39'] = "n", ['40'] = "o", ['41'] = "p",
	['42'] = "q", ['43'] = "r", ['44'] = "s", ['45'] = "t", ['46'] = "u", ['47'] = "v",
	['48'] = "w", ['49'] = "x", ['50'] = "y", ['51'] = "z", ['52'] = "0", ['53'] = "1",
	['54'] = "2", ['55'] = "3", ['56'] = "4", ['57'] = "5", ['58'] = "6", ['59'] = "7",
	['60'] = "8", ['61'] = "9", ['62'] = "+", ['63'] = "/"
}

function Base64.decimalToBinary(input)
	local start = 128
	local total = 0
	local binary = ""
	for i = 1, 8 do
		if total + start <= input then
			total += start
			binary = binary .. "1"
		else
			binary = binary .. "0"
		end
		start /= 2
	end
	return binary
end

function Base64.binaryToDecimal(binary : string)
	local amount = 32
	local decimal = 0
	for i = 1, #binary do
		local character = string.sub(binary, i, i)
		decimal = character == '1' and decimal + amount or decimal
		amount /= 2
	end
	return tostring(decimal)
end

function Base64.binaryToBase64(binary : string)
	local base64 = ""
	while #binary % 6 ~= 0 do
		binary = binary .. "0"
	end
	local start = 1
	while start + 5 <= #binary do
		local binaryHex = string.sub(binary, start, start + 5)
		local decimal = Base64.binaryToDecimal(binaryHex)
		local base64Character = Base64.encodeTable[decimal]
		base64 = base64 .. base64Character
		start += 6
	end
	
	return base64
end

function Base64.encode(input : string)
	local binaryString = ""
	for c = 1, #input do
		local character = string.sub(input, c, c)
		binaryString = binaryString .. Base64.decimalToBinary(string.byte(character))
	end
	local result = Base64.binaryToBase64(binaryString)

	local padding = ((#input) % 3) > 0 and 3 - (#input) % 3 or 0
	for i = 1, padding do
		result = result .. "="
	end

	return result
end

return Base64
