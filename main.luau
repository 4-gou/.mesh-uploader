local net = require("@lune/net")
local stdio = require("@lune/stdio")
local process = require("@lune/process")
local fs = require("@lune/fs")

stdio.write("roblox .mesh uploader\nhttps://github.com/4-gou/.mesh-uploader\n")

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
	stdio.ewrite("\nthe \"cookie.txt\" file doesn't exist or is invalid\nDid you delete it accidentally?")
	return
end

local succeed,file
if process.args[1]~=nil then
	succeed,file=pcall(function()
		return fs.readFile(process.args[1])
	end)
else
	stdio.ewrite("\nNo file name was provided.")
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
	stdio.ewrite("\nFailed to fetch latest Roblox version required to proceed!")
	return
end

if succeed==true then
	if isTokenValid(biscuit)==true then
		local csrf=fetchCSRFToken(biscuit)
		local response = net.request({
			url = "https://data.roblox.com/ide/publish/UploadNewMesh?name=Mesh",
			method = "POST",
			headers = {["x-csrf-token"]=csrf,["Cookie"]=`.ROBLOSECURITY={biscuit}`,["Content-Type"]="application/octet-stream",["User-Agent"]=userAgent},
			body = file
		})
		if response.ok then
			stdio.write("\nSuccess! ID: ")
			stdio.write(response.body)
		else
			stdio.ewrite("\nFailed to upload: ")
			stdio.ewrite(response.body)
		end
	else
		stdio.ewrite("\nThe cookie you have provided is invalid")
	end
else
	stdio.ewrite("\nFailed\nIs the mesh file valid?")
end