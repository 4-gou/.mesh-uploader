local net = require("@lune/net")
local stdio = require("@lune/stdio")
local process = require("@lune/process")
local fs = require("@lune/fs")
local task = require("@lune/task")

stdio.write("roblox .mesh uploader\nhttps://github.com/4-gou/roblox-.mesh-uploader")

local logs: string = ""
local function log(text)
	logs..=`{text}\n`
end
local function fetchCSRFToken(token: string): string
	local response = net.request({
		url = "https://auth.roblox.com/v2/logout",
		method = "POST",
		headers = {["Cookie"]=`.ROBLOSECURITY={token}`,["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
	})
	return response.headers["x-csrf-token"]
end
local function isTokenValid(token: string): boolean
	local response = net.request({
		url = "https://economy.roblox.com/v1/user/currency",
		method = "GET",
		headers = {["Cookie"]=`.ROBLOSECURITY={token}`,["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
	})
	return response.ok
end

local good,biscuit=pcall(function()
	return fs.readFile("cookie.txt")
end)
if good==false then
	stdio.ewrite("\n\nthe \"cookie.txt\" file doesn't exist or is invalid\nDid you delete it accidentally?\n\nClosing in 5 seconds")
	task.wait(5)
	return
end

local succeed,files
if process.args[1]~=nil then
	succeed,files=pcall(function()
		local filetable={}
		for _,file in process.args do
			table.insert(filetable,fs.readFile(process.args[1]))
		end
		return filetable
	end)
else
	stdio.ewrite("\n\nNo files were provided.\n\nClosing in 5 seconds")
	task.wait(5)
	return
end

local userAgent: string = ""
local latestRBXVersion = net.request({
	url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/version.txt",
	method = "GET",
	headers = {["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
})
if latestRBXVersion.ok==true then
	userAgent = `RobloxStudio/WinInet RobloxApp/{latestRBXVersion.body} (GlobalDist; RobloxDirectDownload)`
	-- apparently this specific user agent is required otherwise
	-- uploads will fail with a BadUserAgent error
else
	stdio.ewrite("\n\nFailed to fetch latest Roblox version required to proceed!\n\nClosing in 5 seconds")
	task.wait(5)
	return
end

if succeed==true then
	if isTokenValid(biscuit)==true then
		for _,mesh in files do
			local csrf=fetchCSRFToken(biscuit)
			local response = net.request({
				url = "https://data.roblox.com/ide/publish/UploadNewMesh?name=Mesh",
				method = "POST",
				headers = {["x-csrf-token"]=csrf,["Cookie"]=`.ROBLOSECURITY={biscuit}`,["Content-Type"]="application/octet-stream",["User-Agent"]=userAgent},
				body = mesh
			})
			if response.ok then
				log(`Success! ID: {response.body}`)
			else
				log(`Failed to upload: {response.body}`)
			end
			task.wait(1.325) -- to prevent ratelimits
		end
		fs.writeFile(`{os.time()}_uploads.log`,logs)
	else
		stdio.ewrite("\n\nThe cookie you have provided is invalid\n\nClosing in 5 seconds")
		task.wait(5)
		return
	end
else
	stdio.ewrite("\n\nFailed\nAre the mesh files valid?\n\nClosing in 5 seconds")
	task.wait(5)
	return
end