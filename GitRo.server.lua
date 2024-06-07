local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local toolbar : PluginToolbar = plugin:CreateToolbar("GitRo")

local linkButton : PluginToolbarButton = toolbar:CreateButton("\tLink To Repo\t", "Links to your GitHub Repository", "rbxassetid://17755791268")
linkButton.ClickableWhenViewportHidden = false

local pushButton : PluginToolbarButton = toolbar:CreateButton("\tPush Script\t", "Push script to linked repository", "rbxassetid://17755799729")
pushButton.ClickableWhenViewportHidden = true

local pullButton : PluginToolbarButton = toolbar:CreateButton("\tPull Script\t", "Pull script from linked repository", "rbxassetid://17755801977")
pullButton.ClickableWhenViewportHidden = true

local exportButton : PluginToolbarButton = toolbar:CreateButton("Push Group", "Export group to GitHub", "rbxassetid://17756272147")
exportButton.ClickableWhenViewportHidden = true

local importButton : PluginToolbarButton = toolbar:CreateButton("Pull Group", "Export group to GitHub", "rbxassetid://17758663673")
importButton.ClickableWhenViewportHidden = true



local CoreGui : Instance = game:GetService("CoreGui")

local plug : Plugin = plugin
local gameid = game.GameId
local GUI = script:WaitForChild("GitHubPluginScreen"):Clone()
local player = game

GUI.Enabled = false
GUI.Parent = CoreGui

local ACCOUNT_KEY = "ACCOUNT_KEY"
local REPOS_KEY = "REPOS_KEY"
local AUTH_KEY = "AUTH_KEY"

local function onLinkButtonClicked()
	GUI.Enabled = not GUI.Enabled
	if plugin:GetSetting(ACCOUNT_KEY) and plugin:GetSetting(REPOS_KEY) and plugin:GetSetting(AUTH_KEY) then
		GUI.Frame.Main.Visible = false
		GUI.Frame.Linked.Visible = true
	else
		GUI.Frame.Main.Visible = true
		GUI.Frame.Linked.Visible = false
	end
end

local GitHub = require(script:WaitForChild("GitHub"))
local linkGuiButton = GUI.Frame.Main.LinkButton
local unlinkGuiButton = GUI.Frame.Linked.UnlinkButton
local Account = GUI.Frame.Main.Account.Text
local Auth = GUI.Frame.Main.Auth.Text
local Repos = GUI.Frame.Main.Repos.Text

if plugin:GetSetting(ACCOUNT_KEY) and plugin:GetSetting(REPOS_KEY) and plugin:GetSetting(AUTH_KEY) then
	GUI.Frame.Main.Visible = false
	GUI.Frame.Linked.Visible = true
	pushButton.Enabled = true
	pullButton.Enabled = true
	exportButton.Enabled = true
	importButton.Enabled = true
	linkButton.Icon = "rbxassetid://17757397788"
else
	GUI.Frame.Main.Visible = true
	GUI.Frame.Linked.Visible = false
	pushButton.Enabled = false
	pullButton.Enabled = false
	exportButton.Enabled = false
	importButton.Enabled = false
	linkButton.Icon = "rbxassetid://17757403302"
end

linkGuiButton.Activated:Connect(function()
	local success, code, body = GitHub.link(Account.Text, Repos.Text, Auth.Text)
	if not success then
		warn("Could not link")
		pushButton.Enabled = false
		pullButton.Enabled = false
		exportButton.Enabled = false
		importButton.Enabled = false
		print(code)
		print(body)
	else
		print("Linked!")
		plugin:SetSetting(ACCOUNT_KEY, Account.Text)
		plugin:SetSetting(REPOS_KEY, Repos.Text)
		plugin:SetSetting(AUTH_KEY, Auth.Text)
		pushButton.Enabled = true
		pullButton.Enabled = true
		exportButton.Enabled = true
		importButton.Enabled = true
		GUI.Frame.Main.Visible = false
		GUI.Frame.Linked.Visible = true
		linkButton.Icon = "rbxassetid://17757397788"
	end
end)

unlinkGuiButton.Activated:Connect(function()
	plugin:SetSetting(ACCOUNT_KEY, nil)
	plugin:SetSetting(REPOS_KEY, nil)
	plugin:SetSetting(AUTH_KEY, nil)
	GUI.Frame.Main.Visible = true
	GUI.Frame.Linked.Visible = false
	pushButton.Enabled = false
	pullButton.Enabled = false
	exportButton.Enabled = false
	importButton.Enabled = false
	linkButton.Icon = "rbxassetid://17757403302"
end)

function onPush()
	local file : Script = Selection:Get()[1]
	local root : Script = Selection:Get()[2]
	local Account = plugin:GetSetting(ACCOUNT_KEY)
	local Repos = plugin:GetSetting(REPOS_KEY)
	local Auth = plugin:GetSetting(AUTH_KEY)
	
	if file:IsA("ModuleScript") or file:IsA("Script") or file:IsA("LocalScript") and Account and Repos and Auth then
		local target : Script = file
		local content = target.Source
		local path = GitHub.fullNameToGitHubFile(target, root)
		--local path = target.Name .. ".lua"
		local success, code, body = GitHub.createOrReplace(Account, Repos, Auth, path, "GitRo: " .. target.Name .. " pushed.", content)
		if success then
			print("Pushed file.")
		else
			warn("Could not push file.")
			if code and body then
				print(code .. ": " .. body)
			end
		end
	end
end

function onPull()
	local file : Script = Selection:Get()[1]
	local root : Script = Selection:Get()[2]
	local Account = plugin:GetSetting(ACCOUNT_KEY)
	local Repos = plugin:GetSetting(REPOS_KEY)
	local Auth = plugin:GetSetting(AUTH_KEY)

	if file:IsA("ModuleScript") or file:IsA("Script") or file:IsA("LocalScript") then
		local target : Script = file
		local content = target.Source
		local path = GitHub.fullNameToGitHubFile(target, root)
		--local path = target.Name .. ".lua"
		local success, content = GitHub.pull(Account, Repos, Auth, path)
		if success then
			print("Pulled file.")
			target.Source = content
		else
			warn("Could not pull.")
			if content then
				print(content)
			end
		end
	else
		warn("Could not pull.")
	end
end

function onExport()
	local file : Instance = Selection:Get()[1]
	local Account = plugin:GetSetting(ACCOUNT_KEY)
	local Repos = plugin:GetSetting(REPOS_KEY)
	local Auth = plugin:GetSetting(AUTH_KEY)
	if file:IsA("Folder") or file:IsA("Script") or file:IsA("ModuleScript") or file:IsA("LocalScript") then
		local scripts = {}
		if file:IsA("Script") or file:IsA("ModuleScript") or file:IsA("LocalScript") then
			table.insert(scripts, file)
		end
		local descendants = file:GetDescendants()
		for d, child : Instance in ipairs(descendants) do
			if child:IsA("Script") or child:IsA("ModuleScript") or child:IsA("LocalScript") then
				table.insert(scripts, child)
			end
		end
		
		local amountToExport = #scripts
		local exported = 0
		print("Exporting " .. amountToExport .. " files.")
		for s, scriptChild in ipairs(scripts) do
			local path = GitHub.fullNameToGitHubFile(scriptChild, file)
			local success = GitHub.createOrReplace(Account, Repos, Auth, path, "GitRo: Pushed " .. scriptChild.Name .. " from full upload: " .. file.Name, scriptChild.Source)
			if success then exported += 1 end
			if not success then
				warn("File was not uploaded: " .. GitHub.fullNameToGitHubFile(scriptChild))
			end
			print(exported .. " / " .. amountToExport)
			task.wait(1)
		end
		print("Finished Exporting")
	end
end

function onImport()
	local file : Instance = Selection:Get()[1]
	local Account = plugin:GetSetting(ACCOUNT_KEY)
	local Repos = plugin:GetSetting(REPOS_KEY)
	local Auth = plugin:GetSetting(AUTH_KEY)
	if file:IsA("Folder") or file:IsA("Script") or file:IsA("ModuleScript") or file:IsA("LocalScript") then
		print("Importing files...")
		local success, body = GitHub.getDirectoryContent(Account, Repos, Auth, "")
		task.wait(.25)
		local paths = {}
		for i, item in ipairs(body) do
			local itemType = item.type
			if itemType == "dir" and string.split(item.name, ".")[1] == file.Name then
				table.insert(paths, item)
			elseif itemType == "file" and string.split(item.name, ".")[1] == file.Name then
				local name = item.name
				local scriptName = string.split(name, ".")[1]
				local nameLength = string.len(name)
				local fileType = string.sub(name, nameLength - 9, nameLength - 4)
				local success, body = GitHub.pull(Account, Repos, Auth, item.path)
				task.wait(.25)
				file.Source = body
			end
			
			
			while #paths > 0 do
				local newPaths = {}
				for p, path in ipairs(paths) do
					local fullPath : string = path.path
					local target = file
					local pathNames = string.split(fullPath, "/")
					for pn, pathName in ipairs(pathNames) do
						if pn == 1 then continue end
						target = target[string.split(pathName, ".")[1]]
					end
					local success, result = GitHub.getDirectoryContent(Account, Repos, Auth, fullPath)
					task.wait(.25)
					if success then
						for i, item in ipairs(result) do
							if item.type == "dir" then
								table.insert(newPaths, item)
								if #string.split(item.name, ".") == 1 then
									local folder = Instance.new("Folder")
									folder.Name = item.name
									folder.Parent = target
								end
							elseif item.type == "file" then
								local name = item.name
								local scriptName = string.split(name, ".")[1]
								local nameLength = string.len(name)
								local fileType = string.sub(name, nameLength - 9, nameLength - 4)
								local success, body = GitHub.pull(Account, Repos, Auth, item.path)
								task.wait(.25)
								local newFile : Script = nil
								if fileType == "module" then
									newFile = Instance.new("ModuleScript")
								elseif fileType == "server" then
									newFile = Instance.new("Script")
								elseif fileType == "client" then
									newFile = Instance.new("LocalScript")
								end
								local name = item.name
								local scriptName = string.split(name, ".")[1]
								newFile.Name = scriptName
								newFile.Parent = target
								local nameLength = string.len(name)
								local fileType = string.sub(name, nameLength - 9, nameLength - 4)
								local success, body = GitHub.pull(Account, Repos, Auth, item.path)
								task.wait(.25)
								newFile.Source = body
							end
						end
					end
				end
				paths = newPaths
			end
		end
		print("Import complete")
	end
end

linkButton.Click:Connect(onLinkButtonClicked)
pullButton.Click:Connect(onPull)
pushButton.Click:Connect(onPush)
exportButton.Click:Connect(onExport)
importButton.Click:Connect(onImport)