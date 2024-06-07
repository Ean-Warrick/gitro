local GitHub = {}
local HTTPService = game:GetService("HttpService")
local Base64 = require(script:WaitForChild("Base64"))

GitHub.BaseURL = "https://api.github.com/repos"

function GitHub.getFileType(instance : Instance)
	if instance:IsA("LocalScript") then
		return ".client.lua"
	elseif instance:IsA("Script") then
		return ".server.lua"
	elseif instance:IsA("ModuleScript") then
		return ".module.lua"
	end
end

function GitHub.fullNameToGitHubFile(instance : Instance, root : Instance)
	root = root or instance
	local fullName = instance:GetFullName()
	local rootFull = root:GetFullName()
	local newPath = root.Name .. string.split(fullName, rootFull)[2] 
	local split = string.split(newPath, ".")

	local checking = instance.Parent
	for i = #split - 1, 1 , -1 do
		if checking:IsA("LocalScript") then
			split[i] = split[i] .. ".client"
		elseif checking:IsA("Script") then
			split[i] = split[i] .. ".server"
		elseif checking:IsA("ModuleScript") then
			split[i] = split[i] .. ".module"
		end
		checking = checking.Parent
	end
	local result = ""
	for i, v in ipairs(split) do
		result = result .. v .. ((i < #split and "/") or "")
	end
	result = result .. GitHub.getFileType(instance)
	return result
end

function GitHub.getTree(account : string, respos : string, token : string, treeName : string)
	local url = GitHub.BaseURL .. "/" .. account .. "/" .. respos .. "/" .. "git/trees/main?recursive=1"
	local result = HTTPService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = {
			Accept = "application/vnd.github.v3.json",
			Authorization = "bearer " .. token
		},
	})
	return result.Success, result.Success and HTTPService:JSONDecode(result.Body) or result.Body
end

function GitHub.getDirectoryContent(account : string, respos : string, token : string, path : string)
	local url = GitHub.BaseURL .. "/" .. account .. "/" .. respos .. "/" .. "contents/" .. path
	local result = HTTPService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = {
			Accept = "application/vnd.github.v3.json",
			Authorization = "bearer " .. token
		},
	})
	return result.Success, result.Success and HTTPService:JSONDecode(result.Body) or result.Body
end

function GitHub.link(account : string, respos : string, token : string) : boolean
	local url = GitHub.BaseURL .. "/" .. account .. "/" .. respos .. "/contents/link.lua"
	
	local sha = nil
	local result = HTTPService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = {
			Accept = "application/vnd.github.v3.json",
			Authorization = "bearer " .. token
		},
	})

	if result.Success then
		local json = HTTPService:JSONDecode(result.Body)
		sha = json.sha
	end
	
	local contentTable = {
		gameId = game.GameId,
		timeStamp = os.time(),
		message = "Do not delete this file from GitHub"
	}
	
	if result.StatusCode == 404 or result.Success then
		print("Already Existed:", result.Success)
		result = HTTPService:RequestAsync({
			Url = url,
			Method = "PUT",
			Headers = {
				Accept = "application/vnd.github.v3.json",
				Authorization = "bearer " .. token
			},
			Body = HTTPService:JSONEncode({
				message = "Linked repository to Roblox game.",
				content = Base64.encode(HTTPService:JSONEncode(contentTable)),
				sha = sha
			})
		})
	end
	
	return result.Success, result.StatusCode, result.Body
end

function GitHub.createOrReplace(account : string, respos : string, token : string, path : string, commitMessage : string, content : string)
	if not account or not respos or not token or not path or not commitMessage or not content then
		warn("Action stopped. Repository is not linked.")
		return
	end
	local url = GitHub.BaseURL .. "/" .. account .. "/" .. respos .. "/contents/" .. path
	local sha = nil
	local result = HTTPService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = {
			Accept = "application/vnd.github.v3.json",
			Authorization = "bearer " .. token
		},
	})
	
	if result.Success then
		local json = HTTPService:JSONDecode(result.Body)
		sha = json.sha
	end
	
	if result.StatusCode == 404 or result.Success then
		local resultPut = HTTPService:RequestAsync({
			Url = url,
			Method = "PUT",
			Headers = {
				Accept = "application/vnd.github.v3.json",
				Authorization = "bearer " .. token
			},
			Body = HTTPService:JSONEncode({
				message = commitMessage or "No commit message added.",
				content = Base64.encode(content),
				sha = sha
			})
		})
		
		return resultPut.Success, result.StatusCode, result.Body
	end
	
	return false, -1
end

function GitHub.pull(account : string, respos : string, token : string, path : string)
	if not account or not respos or not token or not path then
		warn("Action stopped. Repository is not linked.")
		return
	end
	local url = GitHub.BaseURL .. "/" .. account .. "/" .. respos .. "/contents/" .. path
	local sha = nil
	local result = HTTPService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = {
			Accept = "application/vnd.github.v3.raw",
			Authorization = "bearer " .. token
		},
	})
	return result.Success, result.Body
end

return GitHub
