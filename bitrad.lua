local bitrad = { version = "bitrad v1" }

local json = require("json")
local currentAd = {}
currentAd.position = 0
local ads = {}

-- Causes a browser launch to the specified url
local function launchBrowser(url) 
	system.openURL( url )
end


-- When ad is done downloading, add it to the ads table
function adDone(event, adObj, key, filename) 
	local adImg = event.target
	local ad = {}
	ad.filename = filename
	ad.link = adObj.link
	table.insert(ads, ad)
end

-- Download and store the ad image
function getAdImg (adObj, key)
	local filename = 'adimage' .. key
	network.download( adObj.image_src, "GET", function (event) adDone(event, adObj, key, filename) end , filename, system.TemporaryDirectory )
end

-- Download all the ads and put them into the ads table
local function populateAds(adSources)
	for key,value in pairs(adSources) do
		getAdImg(value, key)
	end
end


-- Take the json response from the Bitrad API and pass it to populateAds()
local function processBitradJson( event )
        if ( event.isError ) then
                print( "Network error, could not reach the Bitrad servers")
        else
		   adJson = event.response
		   adsObj = json.decode(adJson)
		   if adsObj.error then
				print('*************Bitrad Query Error! ' .. adsObj.error)
		   else
				populateAds(adsObj.ads)
			end
        end
end
 
function bitrad.getAds(bitradKey) 
	network.request( "http://www.bitrad.com/betabitrad/index.php/ad_service/get_ads/" .. bitradKey, "GET", processBitradJson )
end

--Rotate the ads, if no ads are in the ads table, do nothing
function bitrad.rotateAds()
	currentAd.position = currentAd.position + 1
	if currentAd.position > table.getn(ads) then currentAd.position = 1 end
	local pos = currentAd.position
	
	if ads[pos] then
		print ('rotating to: ' .. pos)
		if currentAd.adImg then
			currentAd.adImg:removeSelf()
		end
		local ad = ads[pos]
		-- Replace with sizes from the json
		local width = 320
		local height = 60
		currentAd.adImg = display.newImageRect( ad.filename, system.TemporaryDirectory, width, height )
		currentAd.adImg.x = display.contentWidth / 2
		currentAd.adImg.y = display.contentHeight - height
		currentAd.adImg:addEventListener("tap", function() launchBrowser(ad.link) end)
	else
		print('no ads yet')
	end
	timer.performWithDelay( 5000, bitrad.rotateAds )
end


return bitrad







