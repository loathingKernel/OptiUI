---------------------------------------------------------- 
--	Name: 		Game Interface Script            		--				
--  Copyright 2012 S2 Games								--
----------------------------------------------------------

local _G = getfenv(0)
local ipairs, pairs, select, string, table, next, type, unpack, tinsert, tconcat, tremove, format, tostring, tonumber, tsort, ceil, floor, sub, find, gfind = _G.ipairs, _G.pairs, _G.select, _G.string, _G.table, _G.next, _G.type, _G.unpack, _G.table.insert, _G.table.concat, _G.table.remove, _G.string.format, _G.tostring, _G.tonumber, _G.table.sort, _G.math.ceil, _G.math.floor, _G.string.sub, _G.string.find, _G.string.gfind
local interface = object
local interfaceName = interface:GetName()
RegisterScript2('Game', '34')
Game = {}
Game.MAX_ALLIES 			= 3
Game.MAX_ENEMIES 			= 4
Game.MAX_ALLY_ABILITIES		= 3
Game.ABILITIES_START		= 0
Game.ABILITIES_END			= 4
Game.FULL_ABILITIES_START  	= 0
Game.FULL_ABILITIES_END    	= 8
Game.STATE_START  			= 9
Game.STATE_END    			= 32
Game.INVENTORY_START     	= 36
Game.INVENTORY_END       	= 41
Game.INVENTORY_SPEC_1		= 8 	-- Taunt
Game.INVENTORY_SPEC_2		= 33	-- Fortification

Game.lastHealthEntity = nil
Game.lastManaEntity = nil

local function GetWidgetGame(widget, fromInterface, hideErrors)
	--println('GetWidget ' .. tostring(widget) .. ' in interface ' .. tostring(fromInterface)) 
	if (widget) then
		local returnWidget		
		if (fromInterface) then
			returnWidget = UIManager.GetInterface(fromInterface):GetWidget(widget)		
		else
			returnWidget = interface:GetWidget(widget)
		end	
		if (returnWidget) then
			return returnWidget
		else
			if (not hideErrors) then println('GetWidget Game failed to find ' .. tostring(widget) .. ' in interface ' .. tostring(fromInterface)) end
			return nil		
		end	
	else
		println('GetWidget called without a target')
		return nil
	end
end
local GetWidget = memoizeObject(GetWidgetGame)

----------------------------------------------------------
-- 						General				            --
----------------------------------------------------------

local function NotABot(name)
	if (GameChat) and (GameChat.bots) then
		for _, playerTable in pairs(GameChat.bots) do
			if (string.lower(StripClanTag(playerTable.Name)) == string.lower(StripClanTag(name))) then
				return (not playerTable.isBot)
			end
		end
	end
	return true
end

local function convertTimeRange (inputTimeSeconds)
	local rangeHours = 0
	local rangeMinutes = 0
	local rangeSeconds = 0
	local timeString = ''
	rangeHours = floor(inputTimeSeconds / 3600)
	inputTimeSeconds = inputTimeSeconds - (rangeHours * 3600)
	rangeMinutes = floor(inputTimeSeconds / 60)
	inputTimeSeconds = inputTimeSeconds - (rangeMinutes * 60)
	rangeSeconds = format("%.0d", inputTimeSeconds)
	if inputTimeSeconds < 1 then
		rangeSeconds = '00'
	elseif inputTimeSeconds < 10 then
		rangeSeconds = '0'..rangeSeconds
	end
	if rangeHours > 0 then
		timeString = rangeHours..':'
		if rangeMinutes < 10 then
			timeString = timeString..'0'
		end
	end
	timeString = timeString..rangeMinutes..':'..rangeSeconds
	return timeString
end

local function GetHealthBarColor(healthPercent)
	return Saturate(1 - (healthPercent - 0.50) / 0.50), (healthPercent + (((healthPercent - 0.05) / 1.0)*0.2)) / 0.45, 0, 1
end

----------------------------------------------------------
-- 					Event Sounds				        --
----------------------------------------------------------
-- purchase sounds
local function PlaySellSound()
	interface:UICmd("PlaySound('/shared/sounds/ui/sell.wav')")
end
local function InitSounds()
	interface:RegisterWatch('ItemPurchased', PlaySellSound)
	interface:RegisterWatch('ItemSold', PlaySellSound)
end

----------------------------------------------------------
-- 					Arcade Text				        	--
----------------------------------------------------------
local function InitArcadeText()
	Game.arcadeSetTable = {
		['arcade_text'] = {1800, 1},
		['unicorn'] = {3200, 1},
		['balls'] = {3200, 2},
		['english'] = {3200, 2},
		['pimp'] = {3200, 2},
		['meme'] = {3200, 2},
		['seduction'] = {3200, 2},
		['seductive'] = {3200, 2},
		['thai'] = {3200, 2},
		['thaienglish'] = {3200, 2},
		['pirate'] = {3200, 2},
		['bamf'] = {3200, 3},
	}

	local function ArcadeMessage(message, condition, self, value, set)
		-- OptiUI: Option to disable arcade messages
		if (not GetCvarBool('optiui_ArcadeMessagesDisabled')) then
			if (condition == true) or (condition == tonumber(value)) then		
				local modelPanel = GetWidget('game_arcade_model_'..Game.arcadeSetTable[set][2], 'game')
				if (not modelPanel) then
					modelPanel = GetWidget('game_arcade_model_2', 'game')
				end
		
				modelPanel:SetVisible(true)
				modelPanel:UICmd("SetAnim('idle')")
				modelPanel:UICmd("SetModel('" .. '/ui/common/models/'.. set .. '/' .. message .. '.mdf' .. "')")
				modelPanel:UICmd("SetEffect('" .. '/ui/common/models/'.. set .. '/' .. 'bloodlust.effect' ..  "')")
				modelPanel:Sleep(Game.arcadeSetTable[set][1], function() modelPanel:SetVisible(false) end)
			end
		end
	end
	interface:RegisterWatch('EventTowerDeny', 		function(...) ArcadeMessage('denied', 		true, ...) end)
	interface:RegisterWatch('EventFirstKill', 		function(...) ArcadeMessage('bloodlust', 	true, ...) end)
	interface:RegisterWatch('EventMultiKill', 		function(...) ArcadeMessage('hattrick', 	1, ...) 	ArcadeMessage('quadkill', 	2, ...) 	ArcadeMessage('annihilation', 3, ...) end)
	interface:RegisterWatch('EventKillStreak', 		function(...) ArcadeMessage('bloodbath', 	10, ...) 	ArcadeMessage('immortal', 	15, ...) end)
	interface:RegisterWatch('EventTeamWipe', 		function(...) ArcadeMessage('genocide', 	true, ...) end)
	interface:RegisterWatch('EventSmackdown', 		function(...) ArcadeMessage('smackdown', 	true, ...) end)
	interface:RegisterWatch('EventHumiliation', 	function(...) ArcadeMessage('humiliation', 	true, ...) end)
	interface:RegisterWatch('EventRival', 			function(...) ArcadeMessage('nemesis', 		true, ...) end)
	interface:RegisterWatch('EventPayback', 		function(...) ArcadeMessage('payback', 		true, ...) end)
	interface:RegisterWatch('EventRageQuit', 		function(...) ArcadeMessage('ragequit', 	true, ...) end)
	interface:RegisterWatch('EventVictory', 		function(...) ArcadeMessage('victory', 		true, ...) end)
	interface:RegisterWatch('EventDefeat', 			function(...) ArcadeMessage('defeat', 		true, ...) end)

	local function AccountMessage(self, accountLevel, newVerified)	
		local newVerified = AtoB(newVerified)
		local modelPanel = GetWidget('game_arcade_model_2', 'game')
		
		modelPanel:Sleep(1500, function() 
			modelPanel:SetVisible(true)
			modelPanel:UICmd("SetAnim('idle')")
			if (newVerified) then
				modelPanel:UICmd("SetModel('" .. '/ui/common/models/levelup/verified.mdf' .. "')")
				modelPanel:UICmd("SetEffect('" .. '/ui/common/models/levelup/verified.effect' ..  "')")
			else
				modelPanel:UICmd("SetModel('" .. '/ui/common/models/levelup/levelup.mdf' .. "')")
				modelPanel:UICmd("SetEffect('" .. '/ui/common/models/levelup/levelup.effect' ..  "')")		
			end
			modelPanel:Sleep(5000, function() modelPanel:SetVisible(false) end)
		end)
	end	
	interface:RegisterWatch('EventAccountLevelup', 	function(...) AccountMessage(...) end)
end

----------------------------------------------------------
-- 						Mid Bar					        --
----------------------------------------------------------
local function InitMidBar()
	---[[ Team scores
	interface:RegisterWatch('ScoreboardTeam1', function(_, _, _, totalDeaths) GetWidget('game_team_score_1'):SetText('H: ^r' .. round(totalDeaths)) end)
	interface:RegisterWatch('ScoreboardTeam2', function(_, _, _, totalDeaths) GetWidget('game_team_score_2'):SetText('L: ^g' .. round(totalDeaths)) end)

	---[[ Clock
	Game.game_match_time_label = GetWidget('game_match_time_label')
	-- OptiUI: Timer object init
	Game.game_match_time_rotation_label = GetWidget('game_match_time_rotation_label')
	Game.game_match_time_rune_label = GetWidget('game_match_time_rune_label')
	Game.game_match_time_rotation_label:SetText('^oD^w/^pN')
	Game.game_match_time_rune_label:SetText('Rune')
	-- OptiUI: end
	local function MatchTime(sourceWidget, matchTime, isPreMatchPhase)
		Game.game_match_time_label:SetText( convertTimeRange(matchTime) )
		Game.isPreMatchPhase = AtoB(isPreMatchPhase)

		-- OptiUI: Day/Night, Rune Timers
		local dayDuration = GetCvarInt('g_dayLength') / 1000
		--local powerupInterval = GetCvarInt('g_powerupSpawnInterval') / 1000
		-- OptiUI: Hardcoding rune interval for forests of caldavar.
		local powerupInterval = 120

		if (AtoB(isPreMatchPhase)) then
			Game.game_match_time_rotation_label:SetText('^pN^w/^oD')
			Game.game_match_time_rune_label:SetText('Rune')
		
		else
			local untilChange = (dayDuration / 2) - (Game.lastMatchTime % (dayDuration / 2)) - 1
			local timestate = floor(Game.lastMatchTime / (dayDuration / 2)) % 2
			if (timestate == 1) then
				Game.game_match_time_rotation_label:SetText('^pN^w: '..convertTimeRange(untilChange))
			else
				Game.game_match_time_rotation_label:SetText('^oD^w: '..convertTimeRange(untilChange))
			end

			local untilRuneSpawn = (powerupInterval) - (Game.lastMatchTime % (powerupInterval)) - 1
			if (untilRuneSpawn < 30) then
				Game.game_match_time_rune_label:SetText('R: ^:^r'..convertTimeRange(untilRuneSpawn))
			else
				Game.game_match_time_rune_label:SetText('R: '..convertTimeRange(untilRuneSpawn))
			end
		end
		-- OptiUI: end
	end
	Game.lastMatchTime = -1
	local function PreMatchTime(sourceWidget, matchTime, isPreMatchPhase)
		local tempMatchTime = floor(tonumber(matchTime) / 1000)
		if (Game.lastMatchTime ~= tempMatchTime) then
			MatchTime(sourceWidget, tempMatchTime, isPreMatchPhase)
		end
		Game.lastMatchTime = tempMatchTime
	end
	interface:RegisterWatch('MatchTime', PreMatchTime)

	Game.game_clock_face = GetWidget('game_clock_face')
	local function TimeOfDay(sourceWidget, rotation, soundName)
		if (soundName) and NotEmpty(soundName) then
			-- OptiUI: Changed it to _face in order to play the sound
			GetWidget('game_clock_face'):UICmd("PlaySound('/shared/sounds/"..soundName..".wav')")
			--[[
			if (soundName == 'good_morning') then
				GetWidget('game_clock_effect'):UICmd([==[SetEffect('/ui/effects/clock_day.effect')]==])
			elseif (soundName == 'good_night') then
				GetWidget('game_clock_effect'):UICmd([==[SetEffect('/ui/effects/clock_night.effect')]==])
			end
			--]]
		end
		Game.game_clock_face:SetRotation(rotation * 360)
	end
	interface:RegisterWatch('TimeOfDay', TimeOfDay)
	
	local function UpdateGameClockHover()
		local dayDuration = GetCvarInt('g_dayLength') / 1000

		if (Game.isPreMatchPhase) then
			local dayStartTime = GetCvarInt('g_dayStartTime') / 1000
			local untilChange = (Game.lastMatchTime) + (dayDuration / 2)
			
			Trigger('genericGameFloatingTip', 'true', '16h', '', 'game_label_clock_day', Translate('game_label_clock_day_2', 'time', convertTimeRange(untilChange)), '', '', '3h', '-2h')
			
		elseif (GetTimeOfDawn) then
			
			local correctedTimeOfDay = Game.lastMatchTime - (GetTimeOfDawn() / 1000)
			if(correctedTimeOfDay < 0) then
				correctedTimeOfDay = dayDuration + (correctedTimeOfDay + 1)
			end
			
			local untilChange = (dayDuration / 2) - (correctedTimeOfDay % (dayDuration / 2))
			local timestate = floor(correctedTimeOfDay / (dayDuration / 2)) % 2	
			
			if (timestate == 1) then
				Trigger('genericGameFloatingTip', 'true', '16h', '', 'game_label_clock_night', Translate('game_label_clock_night_2', 'time', convertTimeRange(untilChange)), '', '', '3h', '-2h')
			else
				Trigger('genericGameFloatingTip', 'true', '16h', '', 'game_label_clock_day', Translate('game_label_clock_day_2', 'time', convertTimeRange(untilChange)), '', '', '3h', '-2h')
			end				
		else
			local untilChange = (dayDuration / 2) - (Game.lastMatchTime % (dayDuration / 2))
			local timestate = floor(Game.lastMatchTime / (dayDuration / 2)) % 2		

			if (timestate == 1) then
				Trigger('genericGameFloatingTip', 'true', '16h', '', 'game_label_clock_night', Translate('game_label_clock_night_2', 'time', convertTimeRange(untilChange)), '', '', '3h', '-2h')
			else
				Trigger('genericGameFloatingTip', 'true', '16h', '', 'game_label_clock_day', Translate('game_label_clock_day_2', 'time', convertTimeRange(untilChange)), '', '', '3h', '-2h')
			end	
		end
	end
	
	Game.game_clock_face:SetCallback('onmouseover', function()
		UpdateGameClockHover()
		Game.game_clock_face:RegisterWatch('MatchTime', UpdateGameClockHover)
	end)
	
	Game.game_clock_face:SetCallback('onmouseout', function()
		Game.game_clock_face:UnregisterWatch('MatchTime')
		Trigger('genericGameFloatingTip', '', '', '', '', '', '', '', '', '')
	end)	
	
	-- Base Health
	local function BaseHealth(baseID, game_base_health_header, game_base_health_backer, game_base_health_bar, sourceWidget, healthPercent)
		game_base_health_header:SetVisible(AtoN(healthPercent) < 1)
		if AtoN(healthPercent) < 1 then
			game_base_health_backer:SetVisible(AtoB(healthPercent))
			game_base_health_backer:SetWidth(ToPercent(AtoN(healthPercent)))
			game_base_health_bar:SetColor(GetHealthBarColor(healthPercent))
		end
	end
	for i=0,1,1 do
		interface:RegisterWatch('BaseHealth'..i, function(...) BaseHealth(i, GetWidget('game_base_health_header_'..i), GetWidget('game_base_health_backer_'..i), GetWidget('game_base_health_bar_'..i), ...) end)
	end

	---[[ Player scores
	local function PlayerScore(sourceWidget, heroKills, heroDeaths, heroAsists, creepKills, neutralKills, denies)
		GetWidget('game_player_score_1'):SetText('^g' .. heroKills .. '^* / ^r' .. heroDeaths  .. '^* / ^960' .. heroAsists)
		GetWidget('game_player_score_2'):SetText('^g' .. round(creepKills + neutralKills) .. '^* / ^y' .. denies)
	end
	interface:RegisterWatch('PlayerScore', PlayerScore)
end

----------------------------------------------------------
-- 						Kill Board						--
----------------------------------------------------------
local function GetKillboardOffset(value)
	value = value + Game.killBoardOffset
	if (value > 4) then
		value = value - 4
	end

	return value
end

local function RemoveKillboardEntry(widget, fadeTime)
	widget:FadeOut(fadeTime)
	widget:Sleep(fadeTime, function()
		table.remove(Game.killBoardEntries, 1)

		Game.killBoardOffset = Game.killBoardOffset + 1
		if (Game.killBoardOffset > 3) then
			Game.killBoardOffset = 0
		end

		Game.UpdateKillboard()
	end)
end

function Game.UpdateKillboard()
	for i=1, math.min(#Game.killBoardEntries, 4) do
		local offset = GetKillboardOffset(i)
		local killWidget = GetWidget("killBoardEntry"..offset)
		local killTable = Game.killBoardEntries[i]
		-- set all the icons, frames, etc.
		if (not killTable.exists) then
			killTable.exists = true
			GetWidget("killBoardNameA"..offset):SetColor(killTable.killerPlayerColor)
			GetWidget("killBoardNameA"..offset):SetText(killTable.killerName)
			GetWidget("killBoardHeroIconA"..offset):SetTexture(killTable.killerHeroIcon)
			GetWidget("killBoardTeamA"..offset):SetBorderColor(killTable.killerTeamColor)

			GetWidget("killBoardSkull"..offset):SetColor(killTable.killerTeamColor)

			GetWidget("killBoardNameB"..offset):SetColor(killTable.victimPlayerColor)
			GetWidget("killBoardNameB"..offset):SetText(killTable.victimName)
			GetWidget("killBoardHeroIconB"..offset):SetTexture(killTable.victimHeroIcon)
			GetWidget("killBoardTeamB"..offset):SetBorderColor(killTable.victimTeamColor)

			killWidget:SetY(0)
			killWidget:DoEventN(0)

			killWidget:Sleep(6000, function() RemoveKillboardEntry(killWidget, 1000) end)
		else
			if (i == 1 and #Game.killBoardEntries > 3) then
				killWidget:Sleep(1, function() RemoveKillboardEntry(killWidget, 250) end)
			end
			killWidget:SlideY((math.min(#Game.killBoardEntries, 4) - i)*(-killWidget:GetHeight()), 250)
		end
	end
end

local function InitKillBoard()
	Game.killBoardEntries = {}
	Game.killBoardOffset = 0
	local function EventKill(sourceWidget, killerName, victimName, killerTeam, victimTeam, killerPlayerColor, victimPlayerColor, killerHeroIcon, victimHeroIcon, assists, killerEntityName, victimEntityName)	
		local killerTeamColor, victimTeamColor
		if AtoB(killerTeam) then killerTeamColor = '0 1 0 1' else killerTeamColor = '1 0 0 1' end
		if AtoB(victimTeam) then victimTeamColor = '0 1 0 1' else victimTeamColor = '1 0 0 1' end

		local killBoardEntry = {}
		killBoardEntry.killerName = killerName
		killBoardEntry.victimName = victimName
		killBoardEntry.killerTeamColor = killerTeamColor
		killBoardEntry.victimTeamColor = victimTeamColor
		killBoardEntry.killerPlayerColor = killerPlayerColor
		killBoardEntry.victimPlayerColor = victimPlayerColor
		killBoardEntry.killerHeroIcon = killerHeroIcon
		killBoardEntry.victimHeroIcon = victimHeroIcon
		--killBoardEntry.assists = assists
		killBoardEntry.killerEntityName = killerEntityName
		killBoardEntry.victimEntityName = victimEntityName
		killBoardEntry.exists = false

		table.insert(Game.killBoardEntries, killBoardEntry)
		Game.UpdateKillboard()
	end
	GetWidget('KillBoard'):RegisterWatch('EventKill', EventKill)
end

----------------------------------------------------------
-- 						Scoreboard						--
----------------------------------------------------------
local function ResizeScoreboard()
	local numTop, numBottom = 0, 0
	for i=0,4 do
		if (Game.scoreboardVisible[i]) then
			numTop = numTop + 1
		end
	end
	for i=5,9 do
		if (Game.scoreboardVisible[i]) then
			numBottom = numBottom + 1
		end
	end

	if ((Game.scoreboardLastTop ~= numTop) or (Game.scoreboardLastBottom ~= numBottom)) then
		Game.scoreboardLastTop = numTop
		Game.scoreboardLastBottom = numBottom

		GetWidget("Nscores"):SetHeight(((numBottom + numTop) * Game.scoreGrowHeight) + (Game.scoreGrowHeight * 1.6))
		if (numTop > 0) then
			GetWidget("Nscores_Legion"):SetHeight((numTop * Game.scoreGrowHeight) + (Game.scoreGrowHeight / 2.0))
			GetWidget("Nscores_Legion"):SetVisible(1)
		else
			GetWidget("Nscores_Legion"):SetVisible(0)
		end

		if (numBottom > 0) then
			GetWidget("Nscores_Hellbourne"):SetHeight((numBottom * Game.scoreGrowHeight) + (Game.scoreGrowHeight / 2.0))
			GetWidget("Nscores_Hellbourne"):SetVisible(1)
		else
			GetWidget("Nscores_Hellbourne"):SetVisible(0)
		end

		-- set the x since the set height will mess up the slide
		if (Game.scoreboardOpen) then
			GetWidget("Nscores"):SetX("1h")
		else
			GetWidget("Nscores"):SetX("23h")
		end
	end
end

function Game.ToggleScoreboard()
	Game.scoreboardOpen = not Game.scoreboardOpen

	GetWidget("Nscores_min"):SetVisible(Game.scoreboardOpen)
	GetWidget("Nscores_max"):SetVisible(not Game.scoreboardOpen)

	if (Game.scoreboardOpen) then
		GetWidget("Nscores"):SlideX("1h", 250)
	else
		GetWidget("Nscores"):SlideX("23h", 250)
	end
end

local function InitScoreboard()
	Game.scoreboardVisible = {}
	Game.scoreGrowHeight = GetWidget("Nscores"):GetHeight()
	Game.scoreboardOpen = false
	Game.scoreboardLastTop, Game.scoreboardLastBottom = 0, 0
	local function ScoreboardPlayer(index, widget, name)
		if (name and string.len(name) > 0) then
			Game.scoreboardVisible[index] = true
		else
			Game.scoreboardVisible[index] = false
		end

		ResizeScoreboard()
	end
	for i=0,9 do
		interface:RegisterWatch('ScoreboardPlayer'..i, function(...) ScoreboardPlayer(i, ...) end)
	end

	local function ScoreboardChange(widget, param)
		if ((tonumber(param) == 0 and Game.scoreboardOpen) or (tonumber(param) == 1 and not Game.scoreboardOpen)) then
			Game.ToggleScoreboard()
		end
		Trigger('GameImagePreviewVis', 'false', '100%')
	end
	interface:RegisterWatch('ScoreboardChange', ScoreboardChange)
end

----------------------------------------------------------
-- 				Player Top Left Info					--
----------------------------------------------------------
local function InitPlayerTopLeftInfo()
	local function HeroIcon(sourceWidget, heroIcon)
		GetWidget('game_top_left_hero_icon'):SetTexture(heroIcon)
	end
	interface:RegisterWatch('HeroIcon', HeroIcon)

	local function HeroStatus(sourceWidget, heroStatus)
		if (AtoB(heroStatus)) then
			GetWidget('game_top_left_hero_icon'):UICmd("SetRenderMode('normal')")
			GetWidget('game_top_left_hero_icon'):SetColor('white')
			HideWidget('game_top_left_hero_icon_dead', 'game')
			HideWidget('game_top_left_respawn_timer', 'game')
		else
			GetWidget('game_top_left_hero_icon'):UICmd("SetRenderMode('grayscale')")
			GetWidget('game_top_left_hero_icon'):SetColor('gray')
			ShowWidget('game_top_left_hero_icon_dead', 'game')
			ShowWidget('game_top_left_respawn_timer', 'game')
		end
	end
	interface:RegisterWatch('HeroStatus', HeroStatus)

	local function PlayerInfo(sourceWidget, _, playerColor)
		-- OptiUI: Made icon_bg a frame and added level_bg color
		GetWidget('game_top_left_hero_icon_bg'):SetBorderColor(playerColor)
		GetWidget('game_top_left_hero_level_bg'):SetColor(playerColor)
	end
	interface:RegisterWatch('PlayerInfo', PlayerInfo)

	local function HeroRespawn(sourceWidget, respawnTime)
		GetWidget('game_top_left_respawn_timer'):SetText(respawnTime)
	end
	Game.lastRespawnTime = -1
	local function PreHeroRespawn(sourceWidget, respawnTime)
		local respawnTime = tonumber(respawnTime)
		if (respawnTime) then
			local tempRespawnTime = ceil(respawnTime / 1000)
			if (Game.lastRespawnTime ~= tempRespawnTime) then
				HeroRespawn(sourceWidget, tempRespawnTime)
			end
			Game.lastRespawnTime = tempRespawnTime
		end
	end
	interface:RegisterWatch('HeroRespawn', PreHeroRespawn)

	local function HeroHealth(sourceWidget, health, maxHealth, healthPercent, healthShadow)
		local health, maxHealth, tempHealthPercent, tempHealthShadow = AtoN(health), AtoN(maxHealth), ToPercent(AtoN(healthPercent)), ToPercent(AtoN(healthPercent))
		if GetCvarBoolMem('cg_showHeroHealthLerp') then
			GetWidget('game_top_left_health_lerp'):ScaleWidth(tempHealthShadow, 500, -1)
		else
			GetWidget('game_top_left_health_lerp'):SetWidth(0)
		end
		-- OptiUI: Fixed the small glitch with 0 width on bar elements
		GetWidget('game_top_left_health_bar'):SetVisible(AtoB(health))
		GetWidget('game_top_left_health_bar'):SetWidth(tempHealthPercent)
		GetWidget('game_top_left_health_bar'):SetColor(GetHealthBarColor(healthPercent))
		GetWidget('game_top_left_health_bar'):UICmd("SetUScale(GetHeight() * 32 # 'p')")
		if (maxHealth > 0) then
			GetWidget('game_top_left_health_label'):SetText(ceil(health) .. '/' .. ceil(maxHealth))
		else
			GetWidget('game_top_left_health_label'):SetText('')
		end
	end
	interface:RegisterWatch('HeroHealth', HeroHealth)

	local function HeroMana(sourceWidget, mana, maxMana, manaPercent, manaShadow)
		local mana, maxMana, tempManaPercent, tempManaShadow = AtoN(mana), AtoN(maxMana), ToPercent(AtoN(manaPercent)), ToPercent(AtoN(manaPercent))
		if (maxMana > 0) then
			GetWidget('game_top_left_mana_lerp'):SetVisible(true)
			-- OptiUI: Fixed the small glitch with 0 width on bar elements
			GetWidget('game_top_left_mana_bar'):SetVisible(AtoB(mana))
			GetWidget('game_top_left_mana_label'):SetVisible(true)
			if GetCvarBoolMem('cg_showHeroHealthLerp') then
				GetWidget('game_top_left_mana_lerp'):ScaleWidth(tempManaShadow, 500, -1)
			else
				GetWidget('game_top_left_mana_lerp'):SetWidth(0)
			end
			GetWidget('game_top_left_mana_bar'):SetWidth(tempManaPercent)
			GetWidget('game_top_left_mana_bar'):UICmd("SetUScale(GetHeight() * 32 # 'p')")	
			GetWidget('game_top_left_mana_label'):SetText(ceil(mana) .. '/' .. ceil(maxMana))
		else
			GetWidget('game_top_left_mana_lerp'):SetVisible(false)
			GetWidget('game_top_left_mana_bar'):SetVisible(false)
			GetWidget('game_top_left_mana_label'):SetVisible(false)	
		end
	end
	interface:RegisterWatch('HeroMana', HeroMana)

	local function HeroLevel(sourceWidget, currentLevel, skillPoints)
		local currentLevel, skillPoints = ceil(AtoN(currentLevel)), AtoN(skillPoints)
		if (skillPoints >= 1) then
			GetWidget('game_top_left_hero_lvlup'):SetVisible(true)
		else
			GetWidget('game_top_left_hero_lvlup'):SetVisible(false)
		end
		GetWidget('game_top_left_hero_level_label'):SetText(currentLevel)
	end
	interface:RegisterWatch('HeroLevel', HeroLevel)

	local function HeroBuyBack(sourceWidget, canBuyback)
		local canBuyback = AtoB(canBuyback)
		GetWidget('game_top_left_buyback_parent'):SetVisible(canBuyback)
	end
	interface:RegisterWatch('HeroBuyBack', HeroBuyBack)

	local function HeroBuyBacksExhausted(sourceWidget, buybackExhausted)
		local buybackExhausted = AtoB(buybackExhausted)
		GetWidget('dev_buyback'):SetVisible(not buybackExhausted)
		if (buybackExhausted) then
			GetWidget('game_top_left_buyback_exhausted_label'):SetColor('gray')
			GetWidget('game_top_left_buyback_label'):SetColor('#999900')
			GetWidget('game_top_left_buyback_indicator'):SetColor('#FF0000')
		else
			GetWidget('game_top_left_buyback_exhausted_label'):SetColor('white')
			GetWidget('game_top_left_buyback_label'):SetColor('yellow')
			GetWidget('game_top_left_buyback_indicator'):SetColor('#00FF00')
		end
	end
	interface:RegisterWatch('HeroBuyBacksExhausted', HeroBuyBacksExhausted)

	local function HeroBuyBackCost(sourceWidget, cost)
		GetWidget('game_top_left_buyback_label'):SetText(ceil(cost))
	end
	interface:RegisterWatch('HeroBuyBackCost', HeroBuyBackCost)
end


----------------------------------------------------------
-- 					RAP Visibility						--
----------------------------------------------------------
local function SetRapButtonVisible(visState, visible)

	if(visState.scoreboardIndex ~= nil) then
		GetWidget("rap_scoreboard_"..visState.scoreboardIndex):SetVisible(visible)

	end
	
	if(visState.allyIndex ~= nil) then
		GetWidget('ally_rap_indicator_' .. visState.allyIndex):SetVisible(visible)		
		Set('ally_rap_available_'..visState.allyIndex, visible, 'bool')

		-- OptiUI: We don't use the texture so comment this section out
		--if(visible) then
		--	GetWidget('ally_rap_indicator_template_' .. visState.allyIndex):SetTexture('/ui/common/ally_frame_rap.tga')
		--else
		--	GetWidget('ally_rap_indicator_template_' .. visState.allyIndex):SetTexture('/ui/common/ally_frame.tga')
		--end
		-- OptiUI: end
	end
end

local function RapButtonRefreshVis()
	
	if(Game == nil or Game.RapVisibleStates == nil or not GetCvarBool('ui_rap_enabled')) then
		return
	end
	
	local localSpectator = false
	for clNum, visState in pairs(Game.RapVisibleStates) do
		if(visState.isSpectatingClient) then
			localSpectator = true
			break 
		end
	end

	for clNum, visState in pairs(Game.RapVisibleStates) do
		SetRapButtonVisible(visState, not (visState.isSelf or visState.isBot or visState.isDC or visState.isSpectator or visState.isMentor or localSpectator))

		-- and GetCvarBool('ui_rap_enabled') and GetCvarBool('ui_maintenance_RAP')
		-- we have an ignore selection in the menu now, this is always visible minus for bots
		if (visState.allyIndex) then
			-- OptiUI: Added option to disable right click menu
			if ((not localSpectator) and (not visState.isBot) and (not GetCvarBool('optiui_AllyFramesDisableRightClick'))) then
			-- OptiUI: end
				GetWidget('ally_right_click_menu_button_' .. visState.allyIndex):SetCallback('onrightclick', function() interface:UICmd("CallEvent('ally_right_click_menu_".. visState.allyIndex .."');") end )
			else
				GetWidget('ally_right_click_menu_button_' .. visState.allyIndex):SetCallback('onrightclick', function() end )
			end
		end
	end
end

function Game:ToggleIgnore(playerName)
	local shouldMute = false
	if AtoB(UIManager.GetActiveInterface():UICmd([[ChatIsIgnored(']] .. playerName .. [[')]])) then
		shouldMute = false
		UIManager.GetActiveInterface():UICmd([[ChatUnignore(']] .. playerName .. [[')]])
	else
		shouldMute = true
		UIManager.GetActiveInterface():UICmd([[ChatIgnore(']] .. playerName .. [[')]])
	end
	if (Game.playerNameToClient) and (Game.playerNameToClient[playerName]) then
		if (not AtoB(UIManager.GetActiveInterface():UICmd([[IsVoiceMuted(']] .. Game.playerNameToClient[playerName] .. [[')]]))) or (shouldMute) then
			UIManager.GetActiveInterface():UICmd([[VoiceMute(']] .. Game.playerNameToClient[playerName] .. [[')]])
		else
			UIManager.GetActiveInterface():UICmd([[VoiceUnmute(']] .. Game.playerNameToClient[playerName] .. [[')]])
		end
	end
end

function Game:ScoreboardRapButtonSetVisFlag(clientNumber, scoreboardIndex, isBot, playerName)

	Game.RapVisibleStates = Game.RapVisibleStates or {}
	Game.RapVisibleStates[clientNumber] = Game.RapVisibleStates[clientNumber] or {}
	Game.RapVisibleStates[clientNumber].scoreboardIndex = scoreboardIndex
	Game.RapVisibleStates[clientNumber].isBot = AtoB(isBot)
	Game.RapVisibleStates[clientNumber].isSelf = (StripClanTag(playerName) == StripClanTag(GetAccountName()))

	RapButtonRefreshVis()
end

function Game:AllySpectatorRapButtonSetVisFlag(clientNumber, isSpectator, isMentor, playerName)
	
	Game.RapVisibleStates = Game.RapVisibleStates or {}
	Game.RapVisibleStates[clientNumber] = Game.RapVisibleStates[clientNumber] or {}	
	Game.RapVisibleStates[clientNumber].isSpectator = AtoB(isSpectator)
	Game.RapVisibleStates[clientNumber].isMentor = AtoB(isMentor)
	Game.RapVisibleStates[clientNumber].isSpectatingClient = ((AtoB(isSpectator) or AtoB(isMentor)) and (StripClanTag(playerName) == StripClanTag(GetAccountName())))

	RapButtonRefreshVis()
end

function Game:AllyRapRightClickSetVisFlag(clientNumber, allyIndex)
	
	Game.RapVisibleStates = Game.RapVisibleStates or {}
	Game.RapVisibleStates[clientNumber] = Game.RapVisibleStates[clientNumber] or {}
	Game.RapVisibleStates[clientNumber].allyIndex = AtoN(allyIndex)

	RapButtonRefreshVis()
end

function Game:AllyRapDisconnectSetVisFlag(allyIndex, isDC)
	
	Game.RapVisibleStates = Game.RapVisibleStates or {}
		
	-- Find the data that matches the ally index
	for clNum, visState in pairs(Game.RapVisibleStates) do
		if(visState.allyIndex == allyIndex) then
			Game.RapVisibleStates[clNum].isDC = AtoB(isDC)
			break
		end
	end

	RapButtonRefreshVis()
end

----------------------------------------------------------
-- 						Ally Info						--
----------------------------------------------------------
local function InitAllyInfo()

	-- OptiUI: Position ally icons based on option
	if GetCvarBoolMem('optiui_AllyFramesWide') then
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon_wide', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','0')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon_wide', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','1')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon_wide', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','2')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon_wide', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','3')
	else
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','0')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','1')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','2')
		GetWidget('game_ally_display_holder'):Instantiate('team_member_icon', 'group','team_member_icon_group', 'y','0%', 'align','left', 'index','3')
	end

	local function PositionAllyInfo()

		--groupfcall('team_member_icon_group', function(index, widget, groupName) widget:Destroy() end)

		if GetCvarBool('optiui_AllyFramesWidescreen') then
			GetWidget('game_ally_display_holder'):SetAlign("center")
			GetWidget('game_ally_display_holder'):SetVAlign("bottom")
			GetWidget('game_ally_display_holder'):SetX("0.0h")
			GetWidget('game_ally_display_holder'):SetY("-0.5h")

			if GetCvarBoolMem('optiui_AllyFramesWide') then
				GetWidget('game_ally_display_holder'):SetWidth("105.0h")
				GetWidget('game_ally_display_holder'):SetHeight("10.1h")
			else
				GetWidget('game_ally_display_holder'):SetWidth("90.0h")
				GetWidget('game_ally_display_holder'):SetHeight("13.5h")
			end

			GetWidget('game_top_left_ally_parent_0'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_0'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_0'):SetY(0)
			
			GetWidget('game_top_left_ally_parent_1'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_1'):SetVAlign("bottom")
			GetWidget('game_top_left_ally_parent_1'):SetY(0)

			GetWidget('game_top_left_ally_parent_2'):SetAlign("right")
			GetWidget('game_top_left_ally_parent_2'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_2'):SetY(0)

			GetWidget('game_top_left_ally_parent_3'):SetAlign("right")
			GetWidget('game_top_left_ally_parent_3'):SetVAlign("bottom")
			GetWidget('game_top_left_ally_parent_3'):SetY(0)
		else
			GetWidget('game_ally_display_holder'):SetAlign("top")
			GetWidget('game_ally_display_holder'):SetVAlign("left")
			GetWidget('game_ally_display_holder'):SetX("0.0h")
			GetWidget('game_ally_display_holder'):SetY("6.1h")

			if GetCvarBoolMem('optiui_AllyFramesWide') then
				GetWidget('game_ally_display_holder'):SetWidth("13.5h")
				GetWidget('game_ally_display_holder'):SetHeight("19.0h")
			else
				GetWidget('game_ally_display_holder'):SetWidth("6.0h")
				GetWidget('game_ally_display_holder'):SetHeight("28.0h")
			end

			GetWidget('game_top_left_ally_parent_0'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_0'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_0'):SetY('0%')

			GetWidget('game_top_left_ally_parent_1'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_1'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_1'):SetY('25%')

			GetWidget('game_top_left_ally_parent_2'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_2'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_2'):SetY('50%')

			GetWidget('game_top_left_ally_parent_3'):SetAlign("left")
			GetWidget('game_top_left_ally_parent_3'):SetVAlign("top")
			GetWidget('game_top_left_ally_parent_3'):SetY('75%')
		end
	end
	interface:RegisterWatch('optiui_AllyInfoPosition', PositionAllyInfo)
	PositionAllyInfo()
	-- OptiUI: end

	local function AllyExists(allyIndex, sourceWidget, exists)
		GetWidget('game_top_left_ally_parent_'..allyIndex):SetVisible(AtoB(exists))
	end

	local function AllyHeroInfo(allyIndex, sourceWidget, displayName, iconPath, level)
		GetWidget('game_top_left_ally_image_'..allyIndex):SetTexture(iconPath)
		GetWidget('game_top_left_ally_level_label_'..allyIndex):SetText(level)
		Game.PlayerIconPathsByIndex = Game.PlayerIconPathsByIndex or {}
		Game.PlayerIconPathsByIndex[allyIndex] = iconPath
	end

	local function AllyStatus(allyIndex, sourceWidget, status)
		if (AtoB(status)) then
			GetWidget('game_top_left_ally_status_light_'..allyIndex):SetVisible(true)
			GetWidget('game_top_left_ally_dead_'..allyIndex):SetVisible(false)
			GetWidget('game_top_left_ally_image_'..allyIndex):UICmd("SetRenderMode('normal')")
			GetWidget('game_top_left_ally_image_'..allyIndex):SetColor('white')		
		else
			GetWidget('game_top_left_ally_status_light_'..allyIndex):SetVisible(false)
			GetWidget('game_top_left_ally_dead_'..allyIndex):SetVisible(true)
			GetWidget('game_top_left_ally_image_'..allyIndex):UICmd("SetRenderMode('grayscale')")
			GetWidget('game_top_left_ally_image_'..allyIndex):SetColor('gray')			
		end
	end

	local function AllyRespawn(allyIndex, sourceWidget, respawnTime)
		GetWidget('game_top_left_ally_respawn_'..allyIndex):SetText(respawnTime)
	end
	Game.lastAllyRespawnTime = {-1,-1,-1,-1}
	local function PreAllyRespawn(allyIndex, sourceWidget, respawnTime)
		local respawnTime = tonumber(respawnTime)
		if (respawnTime) then
			local tempRespawnTime = ceil(respawnTime / 1000)
			if (Game.lastAllyRespawnTime[allyIndex]) and (Game.lastAllyRespawnTime[allyIndex] ~= tempRespawnTime) then
				AllyRespawn(allyIndex, sourceWidget, tempRespawnTime)
			end
			Game.lastAllyRespawnTime[allyIndex] = tempRespawnTime
		end
	end

	local function AllyAFK(allyIndex, sourceWidget, isAFK)
		GetWidget('game_top_left_ally_afk_'..allyIndex):SetVisible(AtoB(isAFK))
	end

	local function AllyDisconnected(allyIndex, sourceWidget, isDC)
		GetWidget('game_top_left_ally_dc_'..allyIndex):SetVisible(AtoB(isDC))

		Game:AllyRapDisconnectSetVisFlag(allyIndex, isDC)
		
	end

	local function AllyDisconnectTime(allyIndex, sourceWidget, dcTime)
		GetWidget('game_top_left_ally_dc_label_'..allyIndex):SetText(convertTimeRange(dcTime/1000))
	end

	local function AllyPlayerInfo(allyIndex, sourceWidget, playerName, playerColor, playerClient)
		-- OptiUI: Set border color and bg color
		--GetWidget('game_top_left_ally_parent_'..allyIndex):SetColor(playerColor)
		GetWidget('game_top_left_ally_image_bg_'..allyIndex):SetBorderColor(playerColor)
		GetWidget('game_top_left_ally_level_bg_'..allyIndex):SetColor(playerColor)
		Game.PlayerColorsByIndex = Game.PlayerColorsByIndex or {}
		Game.PlayerColorsByIndex[allyIndex] = playerColor
		
		Game.PlayerIndexByName = Game.PlayerIndexByName or {}
		Game.PlayerIndexByName[playerName] = allyIndex
		
		--printdb('Ally index:            ' .. Game.PlayerIndexByName[playerName])
		
		Game.playerNameToClient = Game.playerNameToClient or {}
		Game.playerNameToClient[playerName] = playerClient
		if (playerName) and NotEmpty(playerName) and AtoB(interface:UICmd([[ChatIsIgnored(']] .. playerName .. [[')]])) then
			interface:UICmd([[VoiceMute(']] .. playerClient .. [[')]])
		end
		
		Game:AllyRapRightClickSetVisFlag(playerClient, allyIndex)		
	end

	local function AllyLoadingPercent(allyIndex, sourceWidget, loadPercent)
		local loadPercent = tonumber(loadPercent)
		if (loadPercent < 1) then
			GetWidget('game_top_left_ally_load_'..allyIndex):SetVisible(true)
			GetWidget('game_top_left_ally_load_label_'..allyIndex):SetText(format("%.0d", (AtoN(loadPercent))*100)..'%')
		else
			GetWidget('game_top_left_ally_load_'..allyIndex):SetVisible(false)
		end
	end

	local function AllyHealth(allyIndex, sourceWidget, health, maxHealth, healthPercent, healthShadow)
		local health, maxHealth, tempHealthPercent, tempHealthShadow = AtoN(health), AtoN(maxHealth), ToPercent(AtoN(healthPercent)), ToPercent(AtoN(healthPercent))
		GetWidget('game_top_left_ally_health_'..allyIndex):SetVisible(health > 0)		
		GetWidget('game_top_left_ally_health_'..allyIndex):SetWidth(tempHealthPercent)
		GetWidget('game_top_left_ally_health_'..allyIndex):SetColor(GetHealthBarColor(healthPercent))
		-- OptiUI: Print maxHealth in wide frames
		if GetCvarBoolMem('optiui_AllyFramesWide') then
			GetWidget('game_top_left_ally_health_label_'..allyIndex):SetText(round(health)..'/'..round(maxHealth))
		else
			GetWidget('game_top_left_ally_health_label_'..allyIndex):SetText(round(health))
		end
		-- OptiUI: end
	end

	local function AllyMana(allyIndex, sourceWidget, mana, maxMana, manaPercent, manaShadow)
		local mana, maxMana, tempManaPercent, tempManaShadow = AtoN(mana), AtoN(maxMana), ToPercent(AtoN(manaPercent)), ToPercent(AtoN(manaPercent))
		if (maxMana > 0) then
			GetWidget('game_top_left_ally_mana_'..allyIndex):SetVisible(mana > 0)
			GetWidget('game_top_left_ally_mana_'..allyIndex):SetWidth(tempManaPercent)
			-- OptiUI: Print maxHealth in wide frames
			if GetCvarBoolMem('optiui_AllyFramesWide') then
				GetWidget('game_top_left_ally_mana_label_'..allyIndex):SetText(round(mana)..'/'..round(maxMana))
			else
				GetWidget('game_top_left_ally_mana_label_'..allyIndex):SetText(round(mana))
			end
			-- OptiUI: end
		else
			GetWidget('game_top_left_ally_mana_'..allyIndex):SetVisible(false)
		end
	end

	local function AllyVoice(allyIndex, sourceWidget, usingVOIP, statusVOIP)
		local usingVOIP, statusVOIP = AtoB(usingVOIP), AtoB(statusVOIP)
		GetWidget('game_top_left_ally_voip_'..allyIndex):SetVisible(usingVOIP)
		if (statusVOIP) then
			GetWidget('game_top_left_ally_voip_indicator_'..allyIndex):SetColor('red')
		else
			if (usingVOIP) then
				GetWidget('game_top_left_ally_voip_indicator_'..allyIndex):SetColor('lime')
			else
				GetWidget('game_top_left_ally_voip_indicator_'..allyIndex):SetColor('white')
			end
		end	
	end
																--			0			1			2			3			4		  5			  6				  7		           8			9			10			11		12          13         14        15
	local function AllyAbilityInfo(allyIndex, slotIndex, sourceWidget, abilityValid, unLeveled, canActivate, isActive, isDisabled, needMana, abilityLevel, remainingCooldown, maxCooldown, null,       displayName, iconPath, isPassive, entityName, charges, maxCharges)
		local unLeveled, isDisabled, isPassive, needMana, canActivate, isActive = AtoB(unLeveled), AtoB(isDisabled), AtoB(isPassive), AtoB(needMana), AtoB(canActivate), AtoB(isActive)
		local remainingCooldown, maxCooldown = AtoB(remainingCooldown), AtoB(maxCooldown)
		if (unLeveled) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('silver')
		elseif (isDisabled) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('red')	
		elseif (isPassive) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('green')	
		elseif (remainingCooldown and maxCooldown) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('yellow')	
		elseif (needMana) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('blue')	
		elseif (canActivate or isActive) then
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('lime')	
		else
			GetWidget('ally_ability_status_dot_'..allyIndex..'_'..slotIndex):SetColor('orange')
		end	
		-- OptiUI: Ally abilities level labels
		GetWidget('ally_ability_status_level_'..allyIndex..'_'..slotIndex):SetText(abilityLevel)
		-- OptiUI: end
	end

	for i=0,Game.MAX_ALLIES,1 do	
		interface:RegisterWatch('AllyExists'..i, function(...) AllyExists(i, ...) end)
		interface:RegisterWatch('AllyHeroInfo'..i, function(...) AllyHeroInfo(i, ...) end)
		interface:RegisterWatch('AllyStatus'..i, function(...) AllyStatus(i, ...) end)
		interface:RegisterWatch('AllyRespawn'..i, function(...) PreAllyRespawn(i, ...) end)
		interface:RegisterWatch('AllyAFK'..i, function(...) AllyAFK(i, ...) end)
		interface:RegisterWatch('AllyDisconnected'..i, function(...) AllyDisconnected(i, ...) end)
		interface:RegisterWatch('AllyDisconnectTime'..i, function(...) AllyDisconnectTime(i, ...) end)
		interface:RegisterWatch('AllyPlayerInfo'..i, function(...) AllyPlayerInfo(i, ...) end)
		interface:RegisterWatch('AllyLoadingPercent'..i, function(...) AllyLoadingPercent(i, ...) end)
		interface:RegisterWatch('AllyHealth'..i, function(...) AllyHealth(i, ...) end)
		interface:RegisterWatch('AllyMana'..i, function(...) AllyMana(i, ...) end)
		interface:RegisterWatch('AllyVoice'..i, function(...) AllyVoice(i, ...) end)
		for s=0,Game.MAX_ALLY_ABILITIES,1 do
			interface:RegisterWatch('AllyAbility'..s..'Info'..i, function(...) AllyAbilityInfo(i, s, ...) end)
		end
	end

	local function AllyDisplay(sourceWidget, displayAllies)
		local displayAllies = AtoB(displayAllies)
		GetWidget('game_ally_display_holder'):SetVisible(displayAllies)
		GetWidget('game_top_left_ally_expand_btn'):SetVisible(not displayAllies)
	end
	interface:RegisterWatch('AllyDisplay', function(...) AllyDisplay(...) end)
end


----------------------------------------------------------
-- 						Vote Menu						--
----------------------------------------------------------
local function InitVoteMenu()
	Game.playerAFK = {}

	GetWidget('voting_combobox_cover').onselect = function(sourceWidget)
		local itemValue = GetWidget('voting_combobox_cover'):UICmd("this")
		GetWidget('voting_combobox_cover_hover'):SetVisible(false)
		if (itemValue == '1') then
			GetWidget('remake_confirm'):DoEventN(0)
		elseif (itemValue == '2') then
			interface:UICmd("CallVote('pause')")	
		elseif (itemValue == '3') then
			GetWidget('concede_confirm'):DoEventN(0)
		elseif (itemValue == '4') then
			interface:UICmd("Unpause()")	
		elseif (itemValue == '5') then
			GetWidget('game_kick_list'):DoEventN(0)
		elseif (itemValue == '6') then
		
		end	
		HideWidget('game_menu_tip_vote', 'game')
		HideWidget('game_menu_tip_remake', 'game')
		HideWidget('game_menu_tip_pause', 'game')
		HideWidget('game_menu_tip_nopauseleft', 'game')
		HideWidget('game_menu_tip_concede', 'game')
		HideWidget('game_menu_tip_unpause', 'game')
		HideWidget('game_menu_tip_kick', 'game')
		GetWidget('voting_combobox_cover'):UICmd("SetSelectedItemByValue(-1)")	
	end
	GetWidget('voting_combobox_cover_listbox').onmouseover = function(sourceWidget)
		local itemValue = GetWidget('voting_combobox_cover_listbox'):UICmd("this")
		if 		(itemValue == '1') then
			ShowWidget('game_menu_tip_remake', 'game')
		elseif  (itemValue == '2') then
			ShowWidget('game_menu_tip_pause', 'game')
		elseif  (itemValue == '3') then
			ShowWidget('game_menu_tip_concede', 'game')
		elseif  (itemValue == '4') then
			ShowWidget('game_menu_tip_unpause', 'game')
		elseif  (itemValue == '5') then
			ShowWidget('game_menu_tip_kick', 'game')
		elseif  (itemValue == '6') then
			ShowWidget('game_menu_tip_remake', 'game')
		elseif  (itemValue == '7') then
			ShowWidget('game_menu_tip_pause', 'game')
		elseif  (itemValue == '8') then
			ShowWidget('game_menu_tip_concede', 'game')
		elseif  (itemValue == '9') then
			ShowWidget('game_menu_tip_kick', 'game')
		elseif  (itemValue == '10') then
			ShowWidget('game_menu_tip_unpause', 'game')
		elseif  (itemValue == '11') then
			ShowWidget('game_menu_tip_nopauseleft', 'game')
		end
	end
	GetWidget('voting_combobox_cover_listbox').onmouseout = function(sourceWidget)
		HideWidget('game_menu_tip_vote', 'game')
		HideWidget('game_menu_tip_remake', 'game')
		HideWidget('game_menu_tip_pause', 'game')
		HideWidget('game_menu_tip_nopauseleft', 'game')
		HideWidget('game_menu_tip_concede', 'game')
		HideWidget('game_menu_tip_unpause', 'game')
		HideWidget('game_menu_tip_kick', 'game')
	end
	GetWidget('voting_combobox_cover'):RefreshCallbacks()
	GetWidget('voting_combobox_cover_listbox'):RefreshCallbacks()

	local function VotePermissions(sourceWidget, inProgress, cooldown, remake, concede, canVote, canPause, isPaused, canUnPause, canVote)
		local voting_combobox_cover = GetWidget('voting_combobox_cover')
		local inProgress, cooldown, remake, concede, canVote, canPause, isPaused, canUnPause, canVote = AtoB(inProgress), AtoB(cooldown), AtoB(remake), AtoB(concede), AtoB(canVote), AtoB(canPause), AtoB(isPaused), AtoB(canUnPause), AtoB(canVote)
		voting_combobox_cover:ClearItems()
		if (isPaused) then
			if (canUnPause) then
				voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 4, 'label', 'game_menu_unpause_button')
			else
				voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_unpause', 10, 'label', 'game_menu_unpause_button')
			end
		else
			if (inProgress or cooldown) then
				voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_disabled', 7, 'label', 'game_menu_pause_button')
			else
				if (canPause) then
					voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 2, 'label', 'game_menu_pause_button')
				else
					voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_disabled', 11, 'label', 'game_menu_nopauseleftshort')
				end
			end	
		end
		
		if ((not inProgress) and (not cooldown) and  canVote) then
			voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 5, 'label', 'game_menu_kick_afk')
		else
			voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_disabled', 9, 'label', 'game_menu_kick_afk')
		end
		
		if ((not inProgress) and (not cooldown) and  remake and canVote) then
			voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 1, 'label', 'game_menu_remake_button')
		else
			voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_disabled', 6, 'label', 'game_menu_remake_button')
		end	
		
		if (not GetCvarBool('is_dev_game')) then
			if ((not inProgress) and (not cooldown) and  (not concede)) then
				voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 3, 'label', 'game_menu_concede_button')
			else
				voting_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item_disabled', 8, 'label', 'game_menu_concede_button')
			end
		end
	end
	interface:RegisterWatch('VotePermissions', VotePermissions)

	local function MenuPlayerInfo(index, widget, ...)
		local kickWidget = GetWidget("kick_player_item_"..index)
		local kickButton = GetWidget("kick_player_item_"..index.."_button")
		local kickIndex = arg[1]

		local kickFunction = function()
				CallVote('kick_afk', kickIndex)
				GetWidget("game_kick_list"):DoEventN(1)
			end

		kickButton:SetCallback("onclick", kickFunction)
		kickButton:RefreshCallbacks()
		kickButton:SetVisible(tonumber(arg[18]) == 0)

		if (AtoB(arg[4]) and (not AtoB(arg[10])) and (GetAccountName() ~= arg[3]) and (tonumber(arg[1]) ~= -1) and (not AtoB(arg[11])) and AtoB(arg[17])) then
			kickWidget:SetVisible(1)
			Game.playerAFK[index] = true
		else
			kickWidget:SetVisible(0)
			Game.playerAFK[index] = false
		end

		-- update no player visibility
		local shouldShow = true
		for i=0,9 do
			if (Game.playerAFK[i]) then
				shouldShow = false
				break
			end
		end

		GetWidget("game_afk_kick_menu"):SetVisible(shouldShow)
	end
	for i=0,9 do
		interface:RegisterWatch('MenuPlayerInfo'..i, function(...) MenuPlayerInfo(i, ...) end)
	end
end

----------------------------------------------------------
-- 					Game Menu							--
----------------------------------------------------------
local function InitGameMenu()
	GetWidget('menu_combobox_cover').onselect = function(sourceWidget)
		local itemValue = GetWidget('menu_combobox_cover'):UICmd("this")
		GetWidget('menu_combobox_cover_hover'):SetVisible(false)
		if (itemValue == '1') then
			interface:UICmd("ToggleMenu()")
			HideWidget('game_menu_tip_chat', 'game')
		elseif (itemValue == '2') then
			interface:UICmd("ToggleMenu()")			
			UIManager.GetInterface('main'):GetWidget('game_options'):Sleep(1, function()
				UIManager.GetInterface('main'):HoNMainF('MainMenuPanelToggle', 'game_options', nil, true, nil, nil, 311)
			end)
			HideWidget('game_menu_tip_options', 'game')
		elseif (itemValue == '3') then
			if AtoB(interface:UICmd("IsValidLeaverGame()")) then
				ShowWidget('disconnect_confirm_leaver', 'game')
			else
				ShowWidget('disconnect_confirm', 'game')
			end
			HideWidget('game_menu_tip_disconnect', 'game')
		elseif (itemValue == '4') then
			if AtoB(interface:UICmd("IsValidLeaverGame()")) then
				ShowWidget('quit_confirm_leaver', 'game')
			else
				ShowWidget('quit_confirm', 'game')
			end
			HideWidget('game_menu_tip_quit', 'game')
		elseif (itemValue == '5') then
			GetWidget('spec_kick_list'):DoEventN(0)
		elseif (itemValue == '6') then
			GetWidget('game_mentor_first_time'):FadeIn(50)
		end	
		if Empty(itemValue) then
			HideWidget('game_menu_tip_menu', 'game')
		end	
		GetWidget('menu_combobox_cover'):UICmd("SetSelectedItemByValue(-1)")	
		HideWidget('game_menu_tip_spec', 'game')
		HideWidget('game_menu_tip_mentor', 'game')	
	end
	GetWidget('menu_combobox_cover_listbox').onmouseover = function(sourceWidget)
		local itemValue = GetWidget('menu_combobox_cover_listbox'):UICmd("this")
		if 		(itemValue == '1') then
			ShowWidget('game_menu_tip_chat', 'game')
		elseif  (itemValue == '2') then	
			ShowWidget('game_menu_tip_options', 'game')
		elseif  (itemValue == '3') then
			ShowWidget('game_menu_tip_disconnect', 'game')
		elseif  (itemValue == '4') then
			ShowWidget('game_menu_tip_quit', 'game')
		elseif  (itemValue == '5') then
			ShowWidget('game_menu_tip_spec', 'game')
		elseif  (itemValue == '6') then
			ShowWidget('game_menu_tip_mentor', 'game')
		end
	end
	GetWidget('menu_combobox_cover_listbox').onmouseout = function(sourceWidget)
		HideWidget('game_menu_tip_menu', 'game')
		HideWidget('game_menu_tip_chat', 'game')
		HideWidget('game_menu_tip_options', 'game')
		HideWidget('game_menu_tip_disconnect', 'game')
		HideWidget('game_menu_tip_quit', 'game')
		HideWidget('game_menu_tip_spec', 'game')
		HideWidget('game_menu_tip_mentor', 'game')
	end
	GetWidget('menu_combobox_cover').onload = function(sourceWidget)
		local menu_combobox_cover = GetWidget('menu_combobox_cover')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 1, 'label', 'game_menu_chat')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 2, 'label', 'game_menu_options_button')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 3, 'label', 'game_menu_disconnect_button')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 4, 'label', 'game_menu_quit_button')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 5, 'label', 'game_menu_vote_spec')
		menu_combobox_cover:AddTemplateListItem('gamecontrol_combobox_item', 6, 'label', 'game_menu_vote_ment')
	end
	GetWidget('menu_combobox_cover'):RefreshCallbacks()
	GetWidget('menu_combobox_cover_listbox'):RefreshCallbacks()
end

----------------------------------------------------------
-- 			   Bottom Center Panel						--
----------------------------------------------------------
local function InitBottomCenterPanel()

	-- OptiUI: Position elements in Bottom Center panel
	local function PositionBottomCenter()
		if GetCvarBool('optiui_BottomCenterAbilitiesBelowBars') then
			GetWidget('game_center_health'):SetY('-8.2h')
			GetWidget('game_center_mana'):SetY('-6.1h')
			GetWidget('game_center_abilities'):SetY('0.0h')
		else
			GetWidget('game_center_health'):SetY('-2.1h')
			GetWidget('game_center_mana'):SetY('0.0h')
			GetWidget('game_center_abilities'):SetY('-4.6h')
		end
	end
	interface:RegisterWatch('optiui_BottomCenterPosition', PositionBottomCenter)
	PositionBottomCenter()
	-- OptiUI: end

	-- Health
	local function ActiveHealth(sourceWidget, health, maxHealth, healthPercent, healthShadow)
		local health, maxHealth, tempHealthPercent, tempHealthShadow = AtoN(health), AtoN(maxHealth), ToPercent(AtoN(healthPercent)), ToPercent(AtoN(healthPercent))
		if GetCvarBoolMem('cg_showHeroHealthLerp') and (health > 0) and (Game.lastHealthEntity == GetSelectedEntity()) then
			GetWidget('game_center_health_lerp'):ScaleWidth(tempHealthShadow, 500, -1)
		else
			Game.lastHealthEntity = GetSelectedEntity()
			GetWidget('game_center_health_lerp'):ScaleWidth(0, 0, -1)
		end
		-- OptiUI: Fix for frame width = 0 graphic glitch
		GetWidget('game_center_health_bar_backer'):SetVisible(health > 0)
		GetWidget('game_center_health_bar_backer'):SetWidth(tempHealthPercent)
		GetWidget('game_center_health_bar'):SetColor(GetHealthBarColor(healthPercent))
		GetWidget('game_center_health_bar'):UICmd("SetUScale(GetHeight() * 32 # 'p')")	
		if (maxHealth > 0) then
			GetWidget('game_center_health_label'):SetText(ceil(health) .. '/' .. ceil(maxHealth))
		else
			GetWidget('game_center_health_label'):SetText('')
		end
		-- OptiUI: Health regen label always visible
		GetWidget('game_center_health_regen_label'):SetVisible((health/maxHealth) <= 0.99)
	end
	interface:RegisterWatch('ActiveHealth', ActiveHealth)

	local function ActiveHealthRegen(sourceWidget, baseHealthRegen, healthRegen)
		local baseHealthRegen, healthRegen = AtoN(baseHealthRegen), AtoN(healthRegen)
		GetWidget('game_center_health_regen_label'):SetText('+'..format("%.1f", healthRegen))
	end
	interface:RegisterWatch('ActiveHealthRegen', ActiveHealthRegen)

	-- Mana
	local function ActiveMana(sourceWidget, mana, maxMana, manaPercent, manaShadow)
		local mana, maxMana, tempManaPercent, tempManaShadow = AtoN(mana), AtoN(maxMana), ToPercent(AtoN(manaPercent)), ToPercent(AtoN(manaPercent))
		if (maxMana > 0) then		
			-- OptiUI: Small rename to keep things clean and fix for frame width = 0 graphic glitch
			GetWidget('game_center_mana_bar_backer'):SetVisible(mana > 0)
			GetWidget('game_center_mana_label'):SetVisible(true)
			GetWidget('game_center_mana_regen_label'):SetVisible(true)	
			if GetCvarBoolMem('cg_showHeroHealthLerp') and (mana > 0) and (Game.lastManaEntity == GetSelectedEntity()) then
				GetWidget('game_center_mana_lerp'):ScaleWidth(tempManaShadow, 500, -1)
			else
				Game.lastManaEntity = GetSelectedEntity()
				GetWidget('game_center_mana_lerp'):ScaleWidth(0, 0, -1)
			end
			-- OptiUI: Small rename to keep things clean
			GetWidget('game_center_mana_bar_backer'):SetWidth(tempManaPercent)		
			GetWidget('game_center_mana_bar'):UICmd("SetUScale(GetHeight() * 32 # 'p')")
			GetWidget('game_center_mana_label'):SetText(ceil(mana) .. '/' .. ceil(maxMana))
			-- OptiUI: Mana regen label always visible
			GetWidget('game_center_mana_regen_label'):SetVisible((mana/maxMana) <= 0.99)
		else
			GetWidget('game_center_mana_lerp'):SetVisible(false)
			-- OptiUI: Small rename to keep things clean
			GetWidget('game_center_mana_bar_backer'):SetVisible(false)
			GetWidget('game_center_mana_label'):SetVisible(false)	
			GetWidget('game_center_mana_regen_label'):SetVisible(false)
		end
	end
	interface:RegisterWatch('ActiveMana', ActiveMana)

	local function ActiveManaRegen(sourceWidget, baseManaRegen, manaRegen)
		local baseManaRegen, manaRegen = AtoN(baseManaRegen), AtoN(manaRegen)
		GetWidget('game_center_mana_regen_label'):SetText('+'..format("%.1f", manaRegen))
	end
	interface:RegisterWatch('ActiveManaRegen', ActiveManaRegen)

	local function ActiveLevel(sourceWidget, currentLevel, skillPoints, showLevelup, _)
		local currentLevel, skillPoints, showLevelup = ceil(AtoN(currentLevel)), AtoN(skillPoints), AtoB(showLevelup)
		if (showLevelup or (skillPoints >= 1)) then
			-- OptiUI: Disable gears and change location of lvlup buttons
			GetWidget('game_center_levelup_btn_holder'):FadeIn(100)
			--GetWidget('game_center_levelup_btn_holder'):SlideY('14h', 150)
			--GetWidget('game_center_large_gear'):Rotate(0, 250)
		else
			GetWidget('game_center_levelup_btn_holder'):FadeOut(100)
			--GetWidget('game_center_levelup_btn_holder'):SlideY('22.6h', 150)
			--GetWidget('game_center_large_gear'):Rotate(30, 250)
		end
		if (skillPoints >= 1) then
			GetWidget('game_center_levelup_btn_holder'):SetBorderColor("purple")
		else
			GetWidget('game_center_levelup_btn_holder'):SetBorderColor("gray")
		end
		GetWidget('game_center_portrait_glow'):SetVisible(skillPoints >= 1)
		GetWidget('game_center_level_label'):SetText(currentLevel)
	end
	interface:RegisterWatch('ActiveLevel', ActiveLevel)

	--Portrait
	local function ActivePortrait(sourceWidget, icon)
		if (icon) then
			GetWidget('game_center_portrait_icon'):SetTexture(icon)
		end
	end
	interface:RegisterWatch('ActivePortrait', ActivePortrait)

	local function UpdateGameCenterPortrait()
		if (Game.ActiveIllusion) then
			GetWidget('game_center_portrait_icon'):SetColor('0.35 1.3 0.35')
			GetWidget('game_center_portrait_icon'):UICmd("SetRenderMode('grayscale')")
		elseif (Game.ActiveStatus) then
			GetWidget('game_center_portrait_icon'):SetColor('white')
			GetWidget('game_center_portrait_icon'):UICmd("SetRenderMode('normal')")
		else
			GetWidget('game_center_portrait_icon'):SetColor('gray')
			GetWidget('game_center_portrait_icon'):UICmd("SetRenderMode('grayscale')")
		end
	end

	-- OptiUI: changed to 'icon' to fix console spam --
	local function ActiveStatus(sourceWidget, status)
		local status = AtoB(status)
		Game.ActiveStatus = status
		UpdateGameCenterPortrait()
		-- OptiUI: Portrait icon always visible
		--GetWidget('game_center_portrait_icon'):SetVisible(status)
	end
	interface:RegisterWatch('ActiveStatus', ActiveStatus)

	local function ActiveIllusion(sourceWidget, isIllusion)
		local isIllusion = AtoB(isIllusion)
		Game.ActiveIllusion = isIllusion
		UpdateGameCenterPortrait()
	end
	interface:RegisterWatch('ActiveIllusion', ActiveIllusion)

	-- OptiUI: Removed to fix console spam --
	local function ActiveModel(sourceWidget, model)
		--if (model) then
			--GetWidget('game_center_portrait_icon'):UICmd("SetModel('"..model.."')")
		--end
	end
	interface:RegisterWatch('ActiveModel', ActiveModel)

	local function ActivePlayerInfo(sourceWidget, playerName, playerColor)
		-- OptiUI: Removed model and added frame color
		--GetWidget('game_center_portrait_icon'):UICmd("SetTeamColor('"..playerColor.."')")
		GetWidget('game_center_portrait_frame'):SetBorderColor(playerColor)
		GetWidget('game_center_level_backer'):SetColor(playerColor)
	end
	interface:RegisterWatch('ActivePlayerInfo', ActivePlayerInfo)

	local function ActiveEffect(sourceWidget, ...)
		-- OptiUI: Removed to fix console spam --
		-- for index, effectPath in ipairs(arg) do
		-- 	GetWidget('game_center_portrait_icon'):UICmd("SetEffectIndexed('"..effectPath.."',"..index..");")
		-- end
	end
	interface:RegisterWatch('ActiveEffect', ActiveEffect)

	local function ToolTargetingEntity(sourceWidget, tool)
		local tool = AtoB(tool)
		GetWidget('game_center_portrait_button'):SetVisible(tool)
		GetWidget('game_center_portrait_button'):UICmd("RefreshCursor()")
	end
	interface:RegisterWatch('ToolTargetingEntity', ToolTargetingEntity)

	local function ActiveLifetime(sourceWidget, remainingLifetime, actualLifetime, remainingPercent)
		local remainingLifetime, actualLifetime, remainingPercent = AtoN(remainingLifetime), AtoN(actualLifetime), AtoN(remainingPercent)
		if (actualLifetime <= 0) then
			GetWidget('game_center_exp_bar_backer'):SetVisible(true)
			GetWidget('game_center_life_bar_backer'):SetVisible(false)
		else
			GetWidget('game_center_exp_bar_backer'):SetVisible(false)
			GetWidget('game_center_life_bar_backer'):SetVisible(true)
			-- OptiUI: Removed the widget from the interface
			--GetWidget('game_center_life_bar_ring'):SetValue(remainingPercent)
			-- OptiUI: Control lifetime bar width
			GetWidget('game_center_life_bar'):SetWidth(remainingPercent * 100 .. '%')
			GetWidget('game_center_life_bar_label'):SetText(ceil(remainingLifetime / 1000) .. ' s')
		end
	end
	interface:RegisterWatch('ActiveLifetime', ActiveLifetime)

	local function ActiveExperience(sourceWidget, exists, xp, xpOfNextLevel, percentNextLevel, xpThisLevel)
		-- OptiUI: Removed the widget from the interface and added new functions
		--GetWidget('game_center_exp_bar_ring'):SetValue(percentNextLevel)
		GetWidget('game_center_exp_bar_parent'):SetVisible(AtoB(exists))
		GetWidget('game_center_exp_bar'):SetVisible(AtoB(xpThisLevel))
		GetWidget('game_center_exp_bar'):SetWidth(percentNextLevel * 100 .. '%')
		GetWidget('game_center_exp_bar_label'):SetText(math.floor(tonumber(xpThisLevel)) .. '/' .. math.floor(tonumber(xpOfNextLevel)))
	end
	interface:RegisterWatch('ActiveExperience', ActiveExperience)

	local function ActiveDamage(sourceWidget, minAtkDmg, maxAtkDmg, avgAtkDmg)
		local minAtkDmg, maxAtkDmg, avgAtkDmg = AtoN(minAtkDmg), AtoN(maxAtkDmg), AtoN(avgAtkDmg)
		GetWidget('game_center_damage'):SetVisible(maxAtkDmg ~= 0)
		GetWidget('game_center_damage_label'):SetText(' ' .. ceil(minAtkDmg + avgAtkDmg) .. ' - ' .. ceil(maxAtkDmg + avgAtkDmg))
	end
	interface:RegisterWatch('ActiveDamage', ActiveDamage)

	-- OptiUI: Added damage reduction label code
	Game.playerArmor = 0
	Game.playerDamageMitigation = 0
	local function ActiveArmor(sourceWidget, baseArmor, armor, mitigation)
		local baseArmor, armor, mitigation = AtoN(baseArmor), AtoN(armor), AtoN(mitigation)
		GetWidget('game_center_armor_label'):SetText(' ' .. format("%.1f", armor) .. ' / ' .. format("%.1f", Game.playerMagicArmor) )
		GetWidget('game_center_damage_mitigation_label'):SetText(' '.. FtoA(tonumber(mitigation) * 100, 1)..'% / '..FtoA(tonumber(Game.playerMagicDamageMitigation) * 100, 1)..'%')
		Game.playerArmor = armor
		Game.playerDamageMitigation = mitigation
	end
	interface:RegisterWatch('ActiveArmor', ActiveArmor)
	
	-- OptiUI: Added magic damage reduction label code
	Game.playerMagicArmor = 0
	Game.playerMagicDamageMitigation = 0
	local function ActiveMagicArmor(sourceWidget, baseMagicArmor, magicArmor, mitigation)
		local baseMagicArmor, magicArmor, mitigation = AtoN(baseMagicArmor), AtoN(magicArmor), AtoN(mitigation)
		GetWidget('game_center_armor_label'):SetText(' ' .. format("%.1f", Game.playerArmor) .. ' ^777/^999 ' .. format("%.1f", magicArmor) )
		GetWidget('game_center_damage_mitigation_label'):SetText(' '..FtoA(tonumber(Game.playerDamageMitigation) * 100, 1)..'% / '.. FtoA(tonumber(mitigation) * 100, 1)..'%')
		Game.playerMagicArmor = magicArmor
		Game.playerMagicDamageMitigation = mitigation
	end
	interface:RegisterWatch('ActiveMagicArmor', ActiveMagicArmor)	
	
	local function ActiveMoveSpeed(sourceWidget, baseSpeed, speed)
		local baseSpeed, speed = AtoN(baseSpeed), AtoN(speed)
		GetWidget('game_center_speed_label'):SetText(' ' .. ceil(speed))
	end
	interface:RegisterWatch('ActiveMoveSpeed', ActiveMoveSpeed)

	local function ActiveHasAttributes(sourceWidget, hasAttributes)
		local hasAttributes = AtoB(hasAttributes)
		GetWidget('game_center_att_parent'):SetVisible(hasAttributes)
	end
	interface:RegisterWatch('ActiveHasAttributes', ActiveHasAttributes)

	local function ActiveAttributes(sourceWidget, strength, agility, intelligence, primaryAttribute)
		local strength, agility, intelligence, primaryAttribute = AtoN(strength), AtoN(agility), AtoN(intelligence), AtoN(primaryAttribute)	
		if (primaryAttribute == 0) then
			GetWidget('game_center_att_label'):SetText(' ^773' .. ceil(strength) .. '^* ' .. ceil(agility) .. ' ' .. ceil(intelligence))
		elseif (primaryAttribute == 1) then
			GetWidget('game_center_att_label'):SetText(' ' .. ceil(strength) .. ' ^773' .. ceil(agility) .. '^* ' .. ceil(intelligence))
		elseif (primaryAttribute == 2) then
			GetWidget('game_center_att_label'):SetText(' ' .. ceil(strength) .. ' ' .. ceil(agility) .. ' ^773' .. ceil(intelligence))
		else
			GetWidget('game_center_att_label'):SetText(' ' .. ceil(strength) .. ' ' .. ceil(agility) .. ' ' .. ceil(intelligence))
		end
	end
	interface:RegisterWatch('ActiveAttributes', ActiveAttributes)

	local function ActiveName(sourceWidget, name)
		if (name) then
			GetWidget('game_center_name_label'):SetText(name)
		end
		-- Reset lerp when changing active unit
		GetWidget('game_center_health_lerp'):ScaleWidth(0, 0, -1)
		GetWidget('game_center_mana_lerp'):ScaleWidth(0, 0, -1)
	end
	interface:RegisterWatch('ActiveName', ActiveName)

	-- Error messages
	local function ErrorMessage(sourceWidget, errorMessage)
		if (errorMessage) then
			GetWidget('game_center_error_messages'):UICmd([[TextBufferCmd(']] .. EscapeString(errorMessage) .. [[')]])
		end
	end
	interface:RegisterWatch('ErrorMessage', ErrorMessage)

	-- Shop indicator (hanging sign thingy)
	local function PlayerCanShop(sourceWidget, canShop)
		local canShop = AtoB(canShop)
		if (canShop) then
			GetWidget('item_shop_sign'):SetVisible(true)
			GetWidget('item_shop_sign'):Sleep(1, function() GetWidget('item_shop_sign'):FadeIn(100) end)
			-- do the above sleep to interrupt any existing sleeps to set the sign invisible
		else
			GetWidget('item_shop_sign'):Sleep(250, function() GetWidget('item_shop_sign'):SetVisible(false) end)
			GetWidget('item_shop_sign'):FadeOut(100)
		end
	end
	interface:RegisterWatch('PlayerCanShop', PlayerCanShop)

	-- gold label
	local function PlayerGold(sourceWidget, playerGold)
		if (playerGold) then
			GetWidget('game_center_gold_label'):SetText(playerGold)
		end
	end
	interface:RegisterWatch('PlayerGold', PlayerGold)
end

----------------------------------------------------------
-- 					Bottom Section						--
----------------------------------------------------------
local function InitBottomSection()
	local function PositionBottomSection() -- Set the position of the minimap, the selected info, attack modifiers, and selected buffs. Fires on script load and game join
		-- because of the courier stuff, we can't just mirror the buttons, so now it will get set based on this
		-- (we also can't have dupe inventory buttons that work correctly, so this is why we have to move them)
		local widgetPositions = {
			['right'] = {
				['game_info_taunt'] = 				{['align'] = "center",	 ['valign'] = "top"},
				['game_info_fortification'] = 		{['align'] = "center",	 ['valign'] = "bottom"},
				['game_info_courier_status'] = 		{['align'] = "right",	 ['valign'] = "top"},
				['game_info_courier_private'] = 	{['align'] = "right",	 ['valign'] = "bottom"},
				['game_info_courier_controller'] = 	{['align'] = "left",	 ['valign'] = "top"},
				['game_info_courier_button'] = 		{['align'] = "right",	 ['valign'] = "bottom"},

				['stash_courier_status'] = 			{['align'] = "right",	 ['valign'] = "top"},
				['stash_courier_private'] = 		{['align'] = "right",	 ['valign'] = "bottom"},
				['stash_courier_controller'] = 		{['align'] = "left",	 ['valign'] = "bottom"},
				['stash_courier_button'] = 			{['align'] = "right",	 ['valign'] = "bottom"}
			},
			['left'] = {
				['game_info_taunt'] = 				{['align'] = "center",	 ['valign'] = "top"},
				['game_info_fortification'] = 		{['align'] = "center",	 ['valign'] = "bottom"},
				['game_info_courier_status'] = 		{['align'] = "left",	 ['valign'] = "top"},
				['game_info_courier_private'] = 	{['align'] = "left",	 ['valign'] = "bottom"},
				['game_info_courier_controller'] = 	{['align'] = "right",	 ['valign'] = "top"},
				['game_info_courier_button'] = 		{['align'] = "left",	 ['valign'] = "bottom"},

				['stash_courier_status'] = 			{['align'] = "left",	 ['valign'] = "top"},
				['stash_courier_private'] = 		{['align'] = "left",	 ['valign'] = "bottom"},
				['stash_courier_controller'] = 		{['align'] = "right",	 ['valign'] = "bottom"},
				['stash_courier_button'] = 			{['align'] = "left",	 ['valign'] = "bottom"}
			}
		}

		-- OptiUI: Resizable minimap
		local minimapSize = ((GetCvarInt('optiui_MiniMapSize') / 100) + 0.5) * 23.2
		-- OptiUI:end

		if (not GetCvarBool('ui_minimap_rightside')) then		
			GetWidget('attack_modifiers_right'):SetVisible(false)
			GetWidget('mini_map_right'):SetVisible(false)
			-- OptiUI: Resizable minimap
			GetWidget('attack_modifiers_left'):SetY(-(minimapSize + 0.8) .. 'h')
			GetWidget('mini_map_left'):SetWidth(minimapSize .. 'h')
			GetWidget('mini_map_left'):SetHeight(minimapSize .. 'h')
			GetWidget('radial_minimap'):SetY(-minimapSize .. 'h')
			-- OptiUI:end
			GetWidget('attack_modifiers_left'):SetVisible(true)
			GetWidget('mini_map_left'):SetVisible(true)
			GetWidget('tooltip_placement'):SetY('-21h')

			for button,positions in pairs(widgetPositions['right']) do
				GetWidget(button):SetAlign(positions.align)
				GetWidget(button):SetVAlign(positions.valign)
			end
			
			GetWidget('selection_info_right'):SetAlign('right')
			--GetWidget('game_botright_orders_right'):SetVisible(true)
			--GetWidget('game_botright_orders_left'):SetVisible(false)	
			--GetWidget('game_botright_units_right'):SetVisible(true)
			--GetWidget('game_botright_units_left'):SetVisible(false)
			--GetWidget('game_botright_building_right'):SetVisible(true)
			--GetWidget('game_botright_building_left'):SetVisible(false)
			--GetWidget('game_botright_mult_right'):SetVisible(true)
			--GetWidget('game_botright_mult_left'):SetVisible(false)
			
			GetWidget('game_selected_info_orders'):SetAlign('right')
			GetWidget('game_selected_info_orders_pos'):SetX('0')
			GetWidget('game_selected_info_unit'):SetAlign('right')
			GetWidget('game_selected_info_unit_bg'):SetAlign('right')
			GetWidget('game_selected_info_unit_icon'):SetAlign('left')
			GetWidget('game_selected_info_unit_icon'):SetX('0.0h')
			--GetWidget('game_selected_info_unit_item_catcher'):SetAlign('right')
			--GetWidget('game_selected_info_unit_item_catcher'):SetX('-17.1h')
			GetWidget('game_selected_info_unit_inventory'):SetAlign('right')
			GetWidget('game_selected_info_unit_inventory'):SetX('-1.2h')
			GetWidget('game_botright_health_bar_bg_0'):SetAlign('right')
			GetWidget('game_botright_health_bar_bg_0'):SetX('-1.2h')
			GetWidget('game_botright_mana_bar_bg_0'):SetAlign('right')
			GetWidget('game_botright_mana_bar_bg_0'):SetX('-1.2h')
			GetWidget('game_selected_info_unit_inventory_cover'):SetAlign('right')
			GetWidget('game_selected_info_unit_inventory_cover'):SetX('-1.2h')
			--GetWidget('game_botright_level_bg_0'):SetAlign('right') 		
			--GetWidget('game_botright_level_bg_0'):SetX('0.0h')
			GetWidget('game_botright_name_label_0B_parent'):SetVisible(false)
			GetWidget('game_botright_name_label_0_parent'):SetAlign('right')
			GetWidget('game_botright_name_label_0_parent'):SetX('-1.2h')
			GetWidget('game_botright_name_label_0_parent'):SetVisible(true)
			GetWidget('game_botright_name_label_0'):SetAlign('right')
			GetWidget('game_botright_name_label_0'):SetX('0.5h')
			GetWidget('game_botright_name_label_0'):SetVisible(true)
			GetWidget('game_botright_name_label_0B'):SetVisible(false)
			GetWidget('game_selected_info_unit_stats'):SetAlign('left')
			GetWidget('game_selected_info_unit_stats'):SetX('0.0h')
			
			GetWidget('game_selected_info_building'):SetAlign('right')
			GetWidget('game_selected_info_building_bg'):SetAlign('right')
			-- OptiUI: Changed from right to left
			GetWidget('game_selected_info_building_icon'):SetAlign('left')
			--GetWidget('game_selected_info_building_icon'):SetX('-17.1h')
			--GetWidget('game_selected_info_building_item_catcher'):SetAlign('right')
			--GetWidget('game_selected_info_building_item_catcher'):SetX('-17.1h')
			GetWidget('game_botright_health_bar_bg_1'):SetAlign('right')
			GetWidget('game_botright_health_bar_bg_1'):SetX('-1.2h')
			GetWidget('game_selected_info_building_shared_abilities'):SetAlign('right')
			GetWidget('game_selected_info_building_shared_abilities'):SetX('-1.2h')
			GetWidget('game_selected_info_building_shared_abilities_pos'):SetAlign('right')
			-- OptiUI: Shared abilities on buildings alignment
			GetWidget('ability_frame_shared_33'):SetAlign('right')
			GetWidget('ability_frame_shared_35'):SetAlign('left')
			--GetWidget('game_selected_info_building_shared_abilities_pos'):SetX('0.0h')
			-- OptiUI: Changed from right to left
			--GetWidget('game_botright_level_bg_1'):SetAlign('right')
			--GetWidget('game_botright_level_bg_1'):SetX('-0.7h')
			GetWidget('game_botright_name_label_1B_parent'):SetVisible(false)
			GetWidget('game_botright_name_label_1_parent'):SetAlign('right')
			GetWidget('game_botright_name_label_1_parent'):SetX('-1.2h')
			GetWidget('game_botright_name_label_1_parent'):SetVisible(true)
			GetWidget('game_botright_name_label_1'):SetAlign('right')
			GetWidget('game_botright_name_label_1'):SetX('0.5h')
			GetWidget('game_botright_name_label_1'):SetVisible(true)
			GetWidget('game_botright_name_label_1B'):SetVisible(false)
			-- OptiUI: Changed from right to left
			GetWidget('game_selected_info_building_stats'):SetAlign('left')
			--GetWidget('game_selected_info_building_stats'):SetX('-14.9h')
			
			GetWidget('game_selected_info_mult'):SetAlign('right')
			GetWidget('game_selected_info_mult_backer'):SetAlign('right')
			GetWidget('game_selected_info_mult_units'):SetAlign('right')
			GetWidget('game_selected_info_mult_units'):SetX('0.0h')
			
			GetWidget('stash_parent'):SetAlign('right')
			GetWidget('stash'):SetAlign('right')
			GetWidget('game_stash_buttons'):SetAlign('left')
			GetWidget('game_stash_buttons'):SetX('1.2h')
			--GetWidget('game_stash_bg'):SetVisible(true)
			--GetWidget('game_stash_bg_alt'):SetVisible(false)
			
			GetWidget('game_stash_label_parent'):SetAlign('left')
			GetWidget('game_stash_label_parent'):SetX('1.2h')
			GetWidget('game_stash_icon'):SetAlign('left')
			--GetWidget('game_stash_icon'):SetX('-14.2h')
			--GetWidget('game_stash_label'):SetAlign('right')
			--GetWidget('game_stash_label'):SetX('-6.0h')
			
			GetWidget('game_stash_tip_stash'):SetAlign('right')
			GetWidget('game_stash_tip_stash'):SetX('-0.25h')

			GetWidget('stash_courier_button'):SetX('-1.1h')
			
		else
			-- OptiUI: Resizable minimap
			GetWidget('attack_modifiers_right'):SetY(-(minimapSize + 0.8) .. 'h')
			GetWidget('mini_map_right'):SetWidth(minimapSize .. 'h')
			GetWidget('mini_map_right'):SetHeight(minimapSize .. 'h')
			GetWidget('radial_minimap'):SetY(-minimapSize .. 'h')
			-- OptiUI:end
			GetWidget('attack_modifiers_right'):SetVisible(true)
			GetWidget('mini_map_right'):SetVisible(true)		
			GetWidget('attack_modifiers_left'):SetVisible(false)
			GetWidget('mini_map_left'):SetVisible(false)
			-- OptiUI: Resizable minimap
			GetWidget('tooltip_placement'):SetY(-(minimapSize + 2.8) .. 'h')
			-- OptiUI:end
			
			for button,positions in pairs(widgetPositions['left']) do
				GetWidget(button):SetAlign(positions.align)
				GetWidget(button):SetVAlign(positions.valign)
			end

			GetWidget('selection_info_right'):SetAlign('left')
			--GetWidget('game_botright_orders_right'):SetVisible(false)
			--GetWidget('game_botright_orders_left'):SetVisible(true)		
			--GetWidget('game_botright_units_right'):SetVisible(false)
			--GetWidget('game_botright_units_left'):SetVisible(true)
			--GetWidget('game_botright_building_right'):SetVisible(false)
			--GetWidget('game_botright_building_left'):SetVisible(true)	
			--GetWidget('game_botright_mult_right'):SetVisible(false)
			--GetWidget('game_botright_mult_left'):SetVisible(true)
				
			GetWidget('game_selected_info_orders'):SetAlign('left')
			GetWidget('game_selected_info_orders_pos'):SetX('0')
			GetWidget('game_selected_info_unit'):SetAlign('left')
			GetWidget('game_selected_info_unit_bg'):SetAlign('left')
			GetWidget('game_selected_info_unit_icon'):SetAlign('right')
			GetWidget('game_selected_info_unit_icon'):SetX('0.0h')
			--GetWidget('game_selected_info_unit_item_catcher'):SetAlign('left')
			--GetWidget('game_selected_info_unit_item_catcher'):SetX('17.1h')
			GetWidget('game_selected_info_unit_inventory'):SetAlign('left')
			GetWidget('game_selected_info_unit_inventory'):SetX('1.2h')
			GetWidget('game_botright_health_bar_bg_0'):SetAlign('left')
			GetWidget('game_botright_health_bar_bg_0'):SetX('1.2h')
			GetWidget('game_botright_mana_bar_bg_0'):SetX('1.2h')		
			GetWidget('game_botright_mana_bar_bg_0'):SetAlign('left')	
			GetWidget('game_selected_info_unit_inventory_cover'):SetAlign('left')
			GetWidget('game_selected_info_unit_inventory_cover'):SetX('1.2h')
			--GetWidget('game_botright_level_bg_0'):SetAlign('left')
			--GetWidget('game_botright_level_bg_0'):SetX('0.0h')
			GetWidget('game_botright_name_label_0_parent'):SetVisible(false)			
			GetWidget('game_botright_name_label_0B_parent'):SetAlign('left')
			GetWidget('game_botright_name_label_0B_parent'):SetX('1.2h')
			GetWidget('game_botright_name_label_0B_parent'):SetVisible(true)
			GetWidget('game_botright_name_label_0B'):SetAlign('left')
			GetWidget('game_botright_name_label_0B'):SetX('-0.5h')
			GetWidget('game_botright_name_label_0B'):SetVisible(true)
			GetWidget('game_botright_name_label_0'):SetVisible(false)
			GetWidget('game_selected_info_unit_stats'):SetAlign('right')
			GetWidget('game_selected_info_unit_stats'):SetX('0.0h')
			
			GetWidget('game_selected_info_building'):SetAlign('left')
			GetWidget('game_selected_info_building_bg'):SetAlign('left')
			-- OptiUI: Changed from left to right
			GetWidget('game_selected_info_building_icon'):SetAlign('right')
			--GetWidget('game_selected_info_building_icon'):SetX('17.1h')
			--GetWidget('game_selected_info_building_item_catcher'):SetAlign('left')
			--GetWidget('game_selected_info_building_item_catcher'):SetX('17.1h')
			GetWidget('game_botright_health_bar_bg_1'):SetAlign('left')
			GetWidget('game_botright_health_bar_bg_1'):SetX('1.2h')
			GetWidget('game_selected_info_building_shared_abilities'):SetAlign('left')
			GetWidget('game_selected_info_building_shared_abilities'):SetX('1.2h')
			GetWidget('game_selected_info_building_shared_abilities_pos'):SetAlign('left')
			-- OptiUI: Shared abilities on buildings alignment
			GetWidget('ability_frame_shared_33'):SetAlign('left')
			GetWidget('ability_frame_shared_35'):SetAlign('right')
			--GetWidget('game_selected_info_building_shared_abilities_pos'):SetX('-0.4h')
			-- OptiUI: Changed from left to right
			--GetWidget('game_botright_level_bg_1'):SetAlign('left')
			--GetWidget('game_botright_level_bg_1'):SetX('0.0h')
			GetWidget('game_botright_name_label_1_parent'):SetVisible(false)
			GetWidget('game_botright_name_label_1B_parent'):SetAlign('left')
			GetWidget('game_botright_name_label_1B_parent'):SetX('1.2h')
			GetWidget('game_botright_name_label_1B_parent'):SetVisible(true)
			GetWidget('game_botright_name_label_1B'):SetAlign('left')
			GetWidget('game_botright_name_label_1B'):SetX('-0.5h')
			GetWidget('game_botright_name_label_1B'):SetVisible(true)
			GetWidget('game_botright_name_label_1'):SetVisible(false)
			-- OptiUI: Changed from left to right
			GetWidget('game_selected_info_building_stats'):SetAlign('right')
			--GetWidget('game_selected_info_building_stats'):SetX('16.6h')

			GetWidget('game_selected_info_mult'):SetAlign('left')
			GetWidget('game_selected_info_mult_backer'):SetAlign('left')
			GetWidget('game_selected_info_mult_units'):SetAlign('left')
			GetWidget('game_selected_info_mult_units'):SetX('0.0h')
				
			GetWidget('stash_parent'):SetAlign('left')
			GetWidget('stash'):SetAlign('left')
			GetWidget('game_stash_buttons'):SetAlign('right')
			GetWidget('game_stash_buttons'):SetX('-1.2h')
			--GetWidget('game_stash_bg'):SetVisible(false)
			--GetWidget('game_stash_bg_alt'):SetVisible(true)
			
			GetWidget('game_stash_label_parent'):SetAlign('right')
			GetWidget('game_stash_label_parent'):SetX('-1.2h')
			GetWidget('game_stash_icon'):SetAlign('right')
			--GetWidget('game_stash_icon'):SetX('8.0h')
			--GetWidget('game_stash_label'):SetAlign('left')
			--GetWidget('game_stash_label'):SetX('8.5h')
			
			GetWidget('game_stash_tip_stash'):SetAlign('left')
			GetWidget('game_stash_tip_stash'):SetX('0.25h')

			GetWidget('stash_courier_button'):SetX('1.1h')
			
		end
	end
	interface:RegisterWatch('MiniMapPosition', PositionBottomSection)
	PositionBottomSection()
end

Game.mapEffect = {}
local function MapEffect(sourceWidget, param0, param1, param2, param3, param4, param5, param6)
	local effect_panel = GetWidget('effect_panel')
	Game.mapEffect[param3] = Game.mapEffect[param3] or {}
	
	local function DoPing()
		if GetWidget('minimap'):IsVisible() then
			effect_panel:UICmd([[StartEffect(']]..param0..[[', GetMinimapDrawX('minimap', ']]..param1..[[') 			/ GetScreenWidth(), 	GetMinimapDrawY('minimap', 1.0 - ]]..param2..[[) 			/ GetScreenHeight(), ']]..param3..[[', GetMinimapDrawX('minimap', ']]..param5..[[') 			/ GetScreenWidth(), 	GetMinimapDrawY('minimap', 1.0 - ]]..param6..[[) 			/ GetScreenHeight())]])
		else
			effect_panel:UICmd([[StartEffect(']]..param0..[[', GetMinimapDrawX('minimap_altview', ']]..param1..[[') 	/ GetScreenWidth(), 	GetMinimapDrawY('minimap_altview', 1.0 - ]]..param2..[[) 	/ GetScreenHeight(), ']]..param3..[[', GetMinimapDrawX('minimap_altview', ']]..param5..[[') 	/ GetScreenWidth(), 	GetMinimapDrawY('minimap_altview', 1.0 - ]]..param6..[[) 	/ GetScreenHeight())]])
		end
		Game.mapEffect[param3].hostTime = HostTime()
	end
	
	if (not Game.mapEffect[param3].hostTime) or (not Game.mapEffect[param3].numPings) or ( (HostTime() - Game.mapEffect[param3].hostTime) > 5000) then
		Game.mapEffect[param3].numPings = 1
		DoPing()
	elseif	((Game.mapEffect[param3].numPings < 3) or GetCvarBool("ui_unlimitedPings")) then	
		DoPing()
		Game.mapEffect[param3].numPings = Game.mapEffect[param3].numPings + 1	
	end

end
interface:RegisterWatch('MapEffect', MapEffect)

----------------------------------------------------------
-- 					Bottom Right						--
----------------------------------------------------------
local function InitBottomRight()
	-- Health
	local function SelectedHealth(targetWidget, sourceWidget, health, maxHealth, healthPercent, healthShadow)
		local health, maxHealth, tempHealthPercent, tempHealthShadow = AtoN(health), AtoN(maxHealth), AtoN(healthPercent), ToPercent(AtoN(healthPercent))
		if (maxHealth > 0) then
			GetWidget('game_botright_health_bar_bg_'..targetWidget):SetVisible(true)
			GetWidget('game_botright_health_bar_backer_'..targetWidget):SetColor(GetHealthBarColor(healthPercent))
			GetWidget('game_botright_health_bar_'..targetWidget):SetWidth(ToPercent(tempHealthPercent))
			GetWidget('game_botright_health_bar_'..targetWidget):SetColor(GetHealthBarColor(healthPercent))	
			if (tempHealthPercent < 0) then
				GetWidget('game_botright_health_bar_'..targetWidget):SetVisible(false)	
				GetWidget('game_botright_health_label_'..targetWidget):SetText(Translate('game_invulnerable'))
			else
				GetWidget('game_botright_health_label_'..targetWidget):SetText(ceil(health) .. '/' .. ceil(maxHealth))
				GetWidget('game_botright_health_bar_'..targetWidget):SetVisible(true)	
			end		
		else
			GetWidget('game_botright_health_bar_bg_'..targetWidget):SetVisible(false)
		end
	end
	interface:RegisterWatch('SelectedHealth0', function(...) SelectedHealth('0', ...) SelectedHealth('1', ...) end)

	-- Mana
	local function SelectedMana(targetWidget, sourceWidget, mana, maxMana, manaPercent, manaShadow)
		local mana, maxMana, tempManaPercent, tempManaShadow = AtoN(mana), AtoN(maxMana), ToPercent(AtoN(manaPercent)), ToPercent(AtoN(manaPercent))
		if (maxMana > 0) then		
			GetWidget('game_botright_mana_bar_bg_'..targetWidget):SetVisible(true)
			GetWidget('game_botright_mana_bar_'..targetWidget):SetWidth(tempManaPercent)
			GetWidget('game_botright_mana_label_'..targetWidget):SetText(ceil(mana) .. '/' .. ceil(maxMana))		
		else
			GetWidget('game_botright_mana_bar_bg_'..targetWidget):SetVisible(false)
		end
	end
	interface:RegisterWatch('SelectedMana0', function(...) SelectedMana('0', ...) end)

	local function SelectedLevel(targetWidget, sourceWidget, currentLevel, hasLevel)
		if (hasLevel) then
			local hasLevel = AtoB(hasLevel)
			GetWidget('game_botright_level_bg_'..targetWidget):SetVisible(hasLevel)
			GetWidget('game_botright_level_label_'..targetWidget):SetText(currentLevel)
		end
	end
	interface:RegisterWatch('SelectedLevel0', function(...) SelectedLevel('0', ...) SelectedLevel('1', ...) end)

	--Portrait
	local function SelectedIcon(targetWidget, sourceWidget, icon)
		if (icon) and NotEmpty(icon) then
			GetWidget('game_botright_portrait_icon_'..targetWidget):SetTexture(icon)
			GetWidget('game_botright_portrait_icon_'..targetWidget):SetVisible(true)
		else
			GetWidget('game_botright_portrait_icon_'..targetWidget):SetVisible(false)
		end
	end
	interface:RegisterWatch('SelectedIcon0', function(...) SelectedIcon('0', ...) SelectedIcon('1', ...) end)

	local function UpdateGameCenterPortrait(targetWidget)
		if (Game.SelectedIllusion) then
			GetWidget('game_botright_portrait_icon_'..targetWidget):SetColor('0.35 1.3 0.35')
			GetWidget('game_botright_portrait_icon_'..targetWidget):UICmd("SetRenderMode('grayscale')")
		else
			GetWidget('game_botright_portrait_icon_'..targetWidget):SetColor('white')
			GetWidget('game_botright_portrait_icon_'..targetWidget):UICmd("SetRenderMode('normal')")
		end
	end

	local function SelectedIllusion(targetWidget, sourceWidget, isIllusion)
		local isIllusion = AtoB(isIllusion)
		Game.SelectedIllusion = isIllusion
		UpdateGameCenterPortrait(targetWidget)
	end
	interface:RegisterWatch('SelectedIllusion0', function(...) SelectedIllusion('0', ...) SelectedIllusion('1', ...) end)

	local function SelectedModel(sourceWidget, model)
		GetWidget('game_botright_portrait_model'):UICmd("SetModel('"..model.."')")
	end
	interface:RegisterWatch('SelectedModel', SelectedModel)

	local function SelectedPlayerInfo(sourceWidget, playerName, playerColor)
		GetWidget('game_botright_portrait_model'):UICmd("SetTeamColor('"..playerColor.."')")
	end
	interface:RegisterWatch('SelectedPlayerInfo', SelectedPlayerInfo)

	local function SelectedEffect(sourceWidget, SelectedEffect)
		if (SelectedEffect) then
			GetWidget('game_botright_portrait_model'):UICmd("SetEffect('"..SelectedEffect.."')")
		end
	end
	interface:RegisterWatch('SelectedEffect', SelectedEffect)

	local function SelectedLifetime(sourceWidget, remainingLifetime, actualLifetime, remainingPercent)
		local remainingLifetime, actualLifetime, remainingPercent = AtoN(remainingLifetime), AtoN(actualLifetime), AtoN(remainingPercent)
		if (actualLifetime <= 0) then
			GetWidget('game_botright_life_bar_backer'):SetVisible(false)
		else
			GetWidget('game_botright_life_bar_backer'):SetVisible(true)
			GetWidget('game_botright_life_bar_ring'):SetValue(remainingPercent)
			GetWidget('game_botright_life_bar_label'):SetText(ceil(remainingLifetime / 1000) .. ' s')
		end
	end
	interface:RegisterWatch('SelectedLifetime', SelectedLifetime)

	local function SelectedName(targetWidget, sourceWidget, name)
		local label = GetWidget('game_botright_name_label_'..targetWidget)
		local labelB = GetWidget('game_botright_name_label_'..targetWidget..'B')
		if (label) and (name) then
			label:SetText(name)
		end
		if (labelB) and (name) then
			labelB:SetText(name)
		end
	end
	interface:RegisterWatch('SelectedName0', function(...) SelectedName('0', ...) SelectedName('1', ...) end)
end
----------------------------------------------------------
-- 					Backpack / Inventory				--
----------------------------------------------------------
-- inventory_button slot 36-41  (8 and 33)
local function InitBackpack()
	local function ActiveInventoryExists(slotIndex, sourceWidget, exists)
		local exists = AtoB(exists)
		GetWidget('inventory_button_bg_empty_'..slotIndex):SetVisible(not exists)
		GetWidget('inventory_button_parent_'..slotIndex):SetVisible(exists)
	end

	local function ActiveInventoryIcon(slotIndex, sourceWidget, iconPath)
		GetWidget('inventory_button_icon_'..slotIndex):SetTexture(iconPath)
		GetWidget('inventory_button_recipe_icon_'..slotIndex):SetTexture(iconPath)
	end
														--				0		  1           2          3       4          5            6         7            8           9         10       11         12          13    14
	local function ActiveInventoryStatus(slotIndex, sourceWidget, canActivate, isActive, isDisabled, needMana, inUse, currentLevel, canLevelUp, maxLevel, isActiveSlot, canShare, isBorrowed, team, recentPurchase, index, iSlot)
		local currentLevel, maxLevel = AtoN(currentLevel), AtoN(maxLevel)
		if (AtoB(canActivate)) then
			GetWidget('inventory_button_icon_'..slotIndex):UICmd("SetRenderMode('normal')")
		else
			GetWidget('inventory_button_icon_'..slotIndex):UICmd("SetRenderMode('grayscale')")
		end	
		if ((currentLevel > 0) or (maxLevel == 0)) then
			GetWidget('inventory_button_activate_'..slotIndex):SetEnabled(true)
			GetWidget('inventory_button_activate_'..slotIndex):SetColor('white')
		else
			GetWidget('inventory_button_activate_'..slotIndex):SetEnabled(false)
			GetWidget('inventory_button_activate_'..slotIndex):SetColor('invisible')
		end		
		if ((currentLevel == 0) and (maxLevel > 0)) then
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetColor('#404040')
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetVisible(true)
		elseif (AtoB(isDisabled)) then
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetColor('#676045')
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetVisible(true)
		elseif (AtoB(needMana)) then
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetColor('#4444ff')
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetVisible(true)
		else
			GetWidget('inventory_button_color_overlay_'..slotIndex):SetVisible(false)
		end
		-- OptiUI: Item mana label parent
		GetWidget('inventory_button_level_label_'..slotIndex):SetText(AtoN(currentLevel))
		if (maxLevel > 1) then
			GetWidget('inventory_button_level_parent_'..slotIndex):SetVisible(true)
		else
			GetWidget('inventory_button_level_parent_'..slotIndex):SetVisible(false)
		end
		GetWidget('inventory_button_shared_'..slotIndex):SetVisible(AtoB(canShare) and AtoB(isBorrowed))
		GetWidget('inventory_button_recent_'..slotIndex):SetVisible(AtoB(recentPurchase) and (not AtoB(isBorrowed)))
		GetWidget('inventory_button_muted_'..slotIndex):SetVisible(AtoB(isBorrowed) and (not AtoB(canShare)))
		GetWidget('inventory_button_target_parent_'..slotIndex):SetVisible(AtoB(isActiveSlot))
		GetWidget('inventory_button_toggle_'..slotIndex):SetVisible(AtoB(isActive))
		GetWidget('inventory_button_activating_'..slotIndex):SetVisible(AtoB(inUse))
	end

	local function ActiveInventoryRecipe(slotIndex, sourceWidget, isRecipe)
		local isRecipe = AtoB(isRecipe)
		GetWidget('inventory_button_icon_'..slotIndex):SetVisible(not isRecipe)
		GetWidget('inventory_button_recipe_parent_'..slotIndex):SetVisible(isRecipe)
	end

	local function ActiveInventoryCooldown(slotIndex, sourceWidget, remainingCDTime, ttCDTime, remainingCDPercent, CDTime)
		local remainingCDTime, ttCDTime, remainingCDPercent, CDTime = AtoN(remainingCDTime), AtoN(ttCDTime), AtoN(remainingCDPercent), AtoN(CDTime)
		if (ttCDTime > 0) then
			GetWidget('inventory_button_cooldown_overlay_'..slotIndex):SetVisible(true)
			GetWidget('inventory_button_cooldown_overlay_'..slotIndex):SetValue(remainingCDPercent)
		else
			GetWidget('inventory_button_cooldown_overlay_'..slotIndex):SetVisible(false)
		end
		if (remainingCDTime > 0) then
			GetWidget('inventory_button_cooldown_label_'..slotIndex):SetVisible(true)
			GetWidget('inventory_button_cooldown_label_'..slotIndex):SetText( ceil(remainingCDTime/1000) .. 's')	
		else
			GetWidget('inventory_button_cooldown_label_'..slotIndex):SetVisible(false)
		end
	end
	Game.lastInventoryCooldown = {}
	local function PreActiveInventoryCooldown(slotIndex, sourceWidget, remainingCDTime, ttCDTime, remainingCDPercent, CDTime)
		local remainingCDTime = tonumber(remainingCDTime)
		if (remainingCDTime) then
			local tempRemainingCDTime = ceil(remainingCDTime / 10)
			if (Game.lastInventoryCooldown[slotIndex] ~= tempRemainingCDTime) then
				ActiveInventoryCooldown(slotIndex, sourceWidget, remainingCDTime, ttCDTime, remainingCDPercent, CDTime)
			end
			Game.lastInventoryCooldown[slotIndex] = tempRemainingCDTime
		end
	end

	local function ActiveInventoryHasTimer(slotIndex, sourceWidget, hasTimer)
		local hasTimer = AtoB(hasTimer)
		GetWidget('inventory_button_timer_'..slotIndex):SetVisible(hasTimer)
	end

	local function ActiveInventoryTimer(slotIndex, sourceWidget, timer)
		local timer = AtoN(timer)	
		GetWidget('inventory_button_timer_'..slotIndex):SetText(convertTimeRange((timer + 949)/1000))
	end

	local function ActiveInventoryCanActivate(slotIndex, sourceWidget, canActivate)
		local canActivate = AtoB(canActivate)
		GetWidget('inventory_button_activate_'..slotIndex):SetVisible(canActivate)
		GetWidget('inventory_button_bevel_'..slotIndex):SetVisible(not canActivate)
	end

	local function ActiveInventoryCharges(slotIndex, sourceWidget, charges)
		local charges = AtoN(charges)
		if (charges) and (charges > 0) then
			GetWidget('inventory_button_timer_'..slotIndex):SetY('0')
			GetWidget('inventory_button_charges_parent_'..slotIndex):SetVisible(true)
			GetWidget('inventory_button_charges_label_'..slotIndex):SetText(charges)
			if (charges < 10) then
				-- OptiUI: Smaller font size for single digit charges
				GetWidget('inventory_button_charges_label_'..slotIndex):SetFont('dyn_9')
			else
				GetWidget('inventory_button_charges_label_'..slotIndex):SetFont('dyn_8')
			end
		else
			GetWidget('inventory_button_timer_'..slotIndex):SetY('-25%')
			GetWidget('inventory_button_charges_parent_'..slotIndex):SetVisible(false)
		end
	end

	local function EventActiveInventoryReady(slotIndex, sourceWidget, isReady)
		GetWidget('inventory_button_refresh_'..slotIndex):SetVisible(true)
		GetWidget('inventory_button_refresh_'..slotIndex):UICmd("SetAnim('idle')")
		GetWidget('inventory_button_refresh_'..slotIndex):UICmd("SetEffect('/ui/common/models/refresh/refresh.effect')")
		GetWidget('inventory_button_refresh_'..slotIndex):Sleep(1333, function() GetWidget('inventory_button_refresh_'..slotIndex):SetVisible(false) end)
	end

	Game.InventorySlotTable = {}
	for i=Game.INVENTORY_START,Game.INVENTORY_END ,1 do
		tinsert(Game.InventorySlotTable, i)
	end
	tinsert(Game.InventorySlotTable, Game.INVENTORY_SPEC_1)
	tinsert(Game.InventorySlotTable, Game.INVENTORY_SPEC_2)

	for _,i in ipairs(Game.InventorySlotTable) do
		-- Indexed Triggers
		interface:RegisterWatch('ActiveInventoryExists'..i, 		function(...)  ActiveInventoryExists(i, ...) end)
		interface:RegisterWatch('ActiveInventoryIcon'..i,   		function(...)  ActiveInventoryIcon(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryStatus'..i, 		function(...)  ActiveInventoryStatus(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryRecipe'..i, 		function(...)  ActiveInventoryRecipe(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryCooldown'..i,  		function(...)  PreActiveInventoryCooldown(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryHasTimer'..i,  		function(...)  ActiveInventoryHasTimer(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryTimer'..i,  		function(...)  ActiveInventoryTimer(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryCanActivate'..i,  	function(...)  ActiveInventoryCanActivate(i, ...)   end)
		interface:RegisterWatch('ActiveInventoryCharges'..i,  		function(...)  ActiveInventoryCharges(i, ...)   end)
		interface:RegisterWatch('EventActiveInventoryReady'..i,  	function(...)  EventActiveInventoryReady(i, ...)   end)
		-- Callbacks
		GetWidget('inventory_button_refresh_'..i):SetCallback('onshow', function() GetWidget('inventory_button_refresh_'..i):UICmd("PlaySound('/shared/sounds/ui/ability_refresh.wav')") end)
		GetWidget('inventory_button_refresh_'..i):RefreshCallbacks()
	end
end
----------------------------------------------------------
-- 					Channel Bar							--
----------------------------------------------------------
local function InitChannelBar()
	local function ChannelActiveInventoryChannel(slotIndex, sourceWidget, isChanneling, _, _, percent)
		local isChanneling, percent = AtoB(isChanneling), AtoN(percent)
		if (isChanneling ~= GetWidget('channel_bar_'..slotIndex):IsVisible()) then
			if (isChanneling) then
				GetWidget('channel_bar_'..slotIndex):SetVisible(true)
				GetWidget('channel_bar_'..slotIndex):PushToBack()
				GetWidget('channel_bar_bg_'..slotIndex):SetColor('0.75 0.5 0 1')
				GetWidget('channel_bar_right_'..slotIndex):SetColor('0.75 0.5 0 0.2')
				GetWidget('channel_bar_prog_'..slotIndex):SetColor('0.75 0.5 0 1')
			else
				GetWidget('channel_bar_'..slotIndex):FadeOut(1000)
				GetWidget('channel_bar_bg_'..slotIndex):SetColor('0.5 0 0.75 1')
				GetWidget('channel_bar_right_'..slotIndex):SetColor('0.5 0 0.75 0.2')
				GetWidget('channel_bar_prog_'..slotIndex):SetColor('0.5 0 0.75 1')
			end
		end
		if (isChanneling) then
			GetWidget('channel_bar_prog_'..slotIndex):SetWidth(ToPercent(1.0 - percent))
		else
			GetWidget('channel_bar_prog_'..slotIndex):SetWidth(0)
		end	
	end

	local function ChannelActiveInventoryIcon(slotIndex, sourceWidget, iconPath)
		GetWidget('channel_bar_icon_'..slotIndex):SetTexture(iconPath or '$invis')
	end

	local function ChannelActiveInventoryDescription(slotIndex, sourceWidget, descName)
		GetWidget('channel_bar_label_'..slotIndex):SetText(descName)
	end

	local function ChannelControlUnitStateMoved(slotIndex, sourceWidget, movedFrom, movedTo)
		local movedFrom, movedTo = tonumber(movedFrom), tonumber(movedTo)
		if (movedFrom == slotIndex) then
			GetWidget('channel_bar_'..slotIndex):SetVisible(false)
		end
	end

	Game.ChannelSlotTable = {}
	for i=Game.FULL_ABILITIES_START,Game.FULL_ABILITIES_END ,1 do
		tinsert(Game.ChannelSlotTable, i)
	end
	for i=Game.STATE_START,Game.STATE_END ,1 do
		tinsert(Game.ChannelSlotTable, i)
	end
	for i=Game.INVENTORY_START,Game.INVENTORY_END ,1 do
		tinsert(Game.ChannelSlotTable, i)
	end

	for _,i in ipairs(Game.ChannelSlotTable) do
		GetWidget('channel_bar_'..i):RegisterWatch('ActiveInventoryChannel'..i, 		function(...)  ChannelActiveInventoryChannel(i, ...) end)
		GetWidget('channel_bar_'..i):RegisterWatch('ActiveInventoryIcon'..i,   			function(...)  ChannelActiveInventoryIcon(i, ...)   end)
		GetWidget('channel_bar_'..i):RegisterWatch('ActiveInventoryDescription'..i,   	function(...)  ChannelActiveInventoryDescription(i, ...)   end)
		GetWidget('channel_bar_'..i):RegisterWatch('ControlUnitStateMoved',   			function(...)  ChannelControlUnitStateMoved(i, ...)   end)
	end
end

----------------------------------------------------------
-- 					Active Inventory					--
----------------------------------------------------------
local function InitActiveInventory()
	-- Levelup
	local function LvlUpActiveInventoryExists(slotIndex, sourceWidget, exists)
		local exists = AtoB(exists)
		GetWidget('ability_lvlup_button_'..slotIndex):SetVisible(exists)
	end

	local function LvlUpActiveInventoryIcon(slotIndex, sourceWidget, iconPath)
		GetWidget('ability_lvlup_button_icon_'..slotIndex):SetTexture(iconPath)
	end
														   --			   0           1         2           3       4          5            6         7           8           9           10      11        12           13     14
	local function LvlUpActiveInventoryStatus(slotIndex, sourceWidget, canActivate, isActive, isDisabled, needMana, inUse, currentLevel, canLevelUp, maxLevel, isActiveSlot, canShare, isBorrowed, team, recentPurchase, index, iSlot)
		if (AtoN(currentLevel) > 0) then
			GetWidget('ability_lvlup_button_label_parent_'..slotIndex):SetVisible(true)
			GetWidget('ability_lvlup_button_label_'..slotIndex):SetText(currentLevel)
		else
			GetWidget('ability_lvlup_button_label_parent_'..slotIndex):SetVisible(false)
		end
		if (AtoB(canLevelUp)) then
			GetWidget('ability_lvlup_button_icon_'..slotIndex):UICmd("SetRenderMode('normal')")
			GetWidget('ability_lvlup_button_icon_'..slotIndex):SetColor('white')
			GetWidget('ability_lvlup_button_button_'..slotIndex):SetCallback('onclick', function()	GetWidget('ability_lvlup_button_button_'..slotIndex):UICmd("PlaySound('/shared/sounds/ui/levelup_ability.wav'); LevelUpAbility("..slotIndex..");")end )
			GetWidget('ability_lvlup_button_button_'..slotIndex):RefreshCallbacks()
			-- OptiUI: Removed ability level up effect because it is heavy and distracting --
			GetWidget('level_up_effect_'..slotIndex):SetBorderColor("yellow")
		else
			GetWidget('ability_lvlup_button_icon_'..slotIndex):UICmd("SetRenderMode('grayscale')")
			GetWidget('ability_lvlup_button_icon_'..slotIndex):SetColor('#808080')
			GetWidget('ability_lvlup_button_button_'..slotIndex):SetCallback('onclick', function() GetWidget('ability_lvlup_button_button_'..slotIndex):UICmd("PlaySound('/shared/sounds/ui/error.wav');") end )
			GetWidget('ability_lvlup_button_button_'..slotIndex):RefreshCallbacks()
			-- OptiUI: Removed ability level up effect because it is heavy and distracting --
			GetWidget('level_up_effect_'..slotIndex):SetBorderColor("gray")
		end
	end

	-- Levelup (slots 0-4)
	for i=Game.ABILITIES_START,Game.ABILITIES_END ,1 do
		interface:RegisterWatch('ActiveInventoryExists'..i, function(...) LvlUpActiveInventoryExists(i, ...) end)
		interface:RegisterWatch('ActiveInventoryIcon'..i, function(...) LvlUpActiveInventoryIcon(i, ...) end)
		interface:RegisterWatch('ActiveInventoryStatus'..i, function(...) LvlUpActiveInventoryStatus(i, ...) end)
	end
end

----------------------------------------------------------
-- 					Abilities							--
----------------------------------------------------------
function Game:RegisterAbilityIcon(sourceWidget, abilitySlot)
	local function ActiveInventoryIcon(sourceWidget, param0)
		sourceWidget:SetTexture(param0)
	end
	sourceWidget:RegisterWatch('ActiveInventoryIcon'..abilitySlot, ActiveInventoryIcon)
	
	local function ActiveInventoryStatus(sourceWidget, param0)
		if AtoB(param0) then
			sourceWidget:UICmd("SetRenderMode('normal')")
		else
			sourceWidget:UICmd("SetRenderMode('grayscale')")
		end
	end
	sourceWidget:RegisterWatch('ActiveInventoryStatus'..abilitySlot, ActiveInventoryStatus)
end

function Game:RegisterAbilityPie(sourceWidget, abilitySlot)
	local function ActiveInventoryCooldown(sourceWidget, param0, param1, param2)
		sourceWidget:SetVisible(tonumber(param1) > 0)
		sourceWidget:SetValue(AtoN(param2))
	end
	sourceWidget:RegisterWatch('ActiveInventoryCooldown'..abilitySlot, ActiveInventoryCooldown)
end

function Game:RegisterAbilityCooldown(sourceWidget, abilitySlot)
	local function ActiveInventoryCooldown(sourceWidget, param0, param1, param2)
		sourceWidget:SetVisible(AtoB(param0))
		--sourceWidget:SetText(convertTimeRange((AtoN(param0) + 949)/1000))
		sourceWidget:SetText(ceil(AtoN(param0) / 1000)..'s')
	end
	sourceWidget:RegisterWatch('ActiveInventoryCooldown'..abilitySlot, ActiveInventoryCooldown)
end

function Game:RegisterAbilityTimer(sourceWidget, abilitySlot)
	local function ActiveInventoryHasTimer(sourceWidget, param0)
		sourceWidget:SetVisible(AtoB(param0))
	end
	sourceWidget:RegisterWatch('ActiveInventoryHasTimer'..abilitySlot, ActiveInventoryHasTimer)
	
	local function ActiveInventoryTimer(sourceWidget, param0)
		sourceWidget:SetText(convertTimeRange((AtoN(param0) + 949)/1000))
	end
	sourceWidget:RegisterWatch('ActiveInventoryTimer'..abilitySlot, ActiveInventoryTimer)	
end

function Game:RegisterAbilityOverlay(sourceWidget, abilitySlot)
	local function ActiveInventoryStatus(sourceWidget, param0, param1, param2, param3, param4, param5, param6, param7)
		if (param5 == '0') and (tonumber(param7) > 0) then
			sourceWidget:SetVisible(true)
			sourceWidget:SetColor('#404040')
		elseif AtoB(param2) then
			sourceWidget:SetVisible(true)
			sourceWidget:SetColor('#676045')
		elseif AtoB(param3) then
			sourceWidget:SetVisible(true)
			sourceWidget:SetColor('#4444ff')
		else
			sourceWidget:SetVisible(false)
		end
	end
	sourceWidget:RegisterWatch('ActiveInventoryStatus'..abilitySlot, ActiveInventoryStatus)
end

local function InitReactiveTips()
		
	Game.tAvailableHeroTips = {}
	
	local function DisplayHeroTip(heroEntity, isOffensive, tipstring)
		
		GetWidget('game_hero_tip_dontask_parent'):SetVisible(0)				
		GetWidget('game_hero_tip_icon'):SetVisible(0)
		GetWidget('game_hero_tip_icon_label'):SetVisible(0)
		GetWidget('game_hero_tip_icon_desc'):SetVisible(0)
		local delay = 1250
		if (Game.lastRespawnTime > 10000) then
			delay = 2500
		end
		
		GetWidget('game_hero_tip_parent'):SetX('0')
		GetWidget('game_hero_tip_parent'):SetY('22h')	
		
		GetWidget('game_hero_tip_parent'):Sleep(delay, function()
			if (not GetWidget('game_hero_tip_parent'):IsVisible()) then
				
				--GetWidget('game_hero_tip_parent'):SetHeight('1h')
				--GetWidget('game_hero_tip_parent'):SetWidth('1h')
				
				--GetWidget('game_hero_tip_parent'):Scale(width, height, 250)

				GetWidget('game_hero_tip_icon'):SetTexture(GetEntityIconPath(heroEntity))
				GetWidget('game_hero_tip_icon_label'):SetText(GetEntityDisplayName(heroEntity))
				if (isOffensive) then
					GetWidget('game_hero_tip_icon_label'):SetColor('0 0.8 0 1')
					GetWidget('game_hero_tip_icon_desc'):SetText(Translate(tipstring))
				else
					GetWidget('game_hero_tip_icon_label'):SetColor('red')
					GetWidget('game_hero_tip_icon_desc'):SetText(Translate(tipstring))
				end
				GetWidget('game_hero_tip_icon'):FadeIn(250)
				GetWidget('game_hero_tip_icon_label'):FadeIn(250)
				GetWidget('game_hero_tip_icon_desc'):FadeIn(250)
				GetWidget('game_hero_tip_dontask_parent'):FadeIn(250)
				GetWidget('game_hero_tip_parent'):Sleep(21, function()
					if (not GetWidget('game_hero_tip_parent'):IsVisible()) then
						GetWidget('game_hero_tip_parent'):SetVisible(1)
						GetWidget('game_hero_tip_parent'):SlideY('-22.0h', 250)
					end
				end)
			end
		end)
	end	
	
	local function EnemyHeroInfo(enemyIndex, sourceWidget, displayName, iconPath, heroLevel, heroEntity)
		--println('EnemyHeroInfo = ' .. tostring(heroEntity) )
		Game.PlayerIconPathsByIndex = Game.PlayerIconPathsByIndex or {}
		Game.PlayerIconPathsByIndex[enemyIndex + 5] = iconPath
		if (heroEntity) and NotEmpty(heroEntity) and (Game.canLoadEnemyTips) then
			for i = 1,4,1 do
				if Translate('hero_tip_defensive_tip_'..heroEntity..'_'..i) ~= ('hero_tip_defensive_tip_'..heroEntity..'_'..i) then
					Game.tAvailableHeroTips[heroEntity] = Game.tAvailableHeroTips[heroEntity] or {}
					tinsert(Game.tAvailableHeroTips[heroEntity], {'hero_tip_defensive_tip_'..heroEntity..'_'..i, false, heroEntity})
				end
			end	
		end
	end	

	local function EnemyPlayerInfo(enemyIndex, sourceWidget, playerName, playerColor, clientNumber)
		
		Game.PlayerColorsByIndex = Game.PlayerColorsByIndex or {}
		Game.PlayerColorsByIndex[enemyIndex + 5] = playerColor
		
		Game.PlayerIndexByName = Game.PlayerIndexByName or {}
		Game.PlayerIndexByName[playerName] = enemyIndex + 5
		
		--printdb('Enemy index:            ' .. Game.PlayerIndexByName[playerName])
	end
	
	--[[
	local function AllyHeroInfo(enemyIndex, sourceWidget, displayName, iconPath, heroLevel, heroEntity)
		if (heroEntity) and NotEmpty(heroEntity) then
			Game.tAvailableHeroTips[heroEntity] = true
		end
	end	
	--]]
	
	local function HeroName(_, heroNameString)
		--println('HeroName = ' .. tostring(heroNameString) )
		if (heroNameString) and NotEmpty(heroNameString) then
			Game.tAvailableHeroTips = {}
			Game.canLoadEnemyTips = true
			for i = 1,4,1 do
				if Translate('hero_tip_offensive_tip_'..GetViewHeroName()..'_'..i) ~= ('hero_tip_offensive_tip_'..GetViewHeroName()..'_'..i) then
					Game.tAvailableHeroTips[GetViewHeroName()] = Game.tAvailableHeroTips[GetViewHeroName()] or {}
					tinsert(Game.tAvailableHeroTips[GetViewHeroName()], {'hero_tip_offensive_tip_'..GetViewHeroName()..'_'..i, true, GetViewHeroName()})
				end
			end
			GetWidget('game_hero_tip_info_parent'):Sleep(1500, function() Game.canLoadEnemyTips = false end)
		end
	end		
	
	for i=0,Game.MAX_ENEMIES,1 do
		interface:RegisterWatch('EnemyHeroInfo'..i, function(...) EnemyHeroInfo(i, ...) end)
		interface:RegisterWatch('EnemyPlayerInfo'..i, function(...) EnemyPlayerInfo(i, ...) end)
	end
	
	interface:RegisterWatch('HeroName', HeroName)
	--interface:RegisterWatch('AllyHeroInfo'..i, function(...) AllyHeroInfo(i, ...) end)
	
	local randomTip
	local function EventKill(sourceWidget, killerName, victimName, killerTeam, victimTeam, killerPlayerColor, victimPlayerColor, killerHeroIcon, victimHeroIcon, assists, killerEntityName, victimEntityName)
		--println('EventKill')
		--println('killerEntityName = ' .. tostring(killerEntityName) )
		--println('victimEntityName = ' .. tostring(victimEntityName) )
		if (Game.tAvailableHeroTips) and IsMe(victimName) and (killerEntityName) and NotEmpty(killerEntityName) and (victimEntityName) and NotEmpty(victimEntityName) and (not GetCvarBool('ui_hideGameHeroTips')) then		
			local tempTipTable = {}
			for index, tipTable in pairs(Game.tAvailableHeroTips[killerEntityName]) do
				tinsert(tempTipTable, {tipTable, index})
			end
			for index,tipTable in pairs(Game.tAvailableHeroTips[victimEntityName]) do
				tinsert(tempTipTable, {tipTable, index})
			end
			--printTable(tempTipTable)
			
			if (tempTipTable) and (#tempTipTable > 0) then
				randomTip =  math.random(1, #tempTipTable)
				DisplayHeroTip(tempTipTable[randomTip][1][3], tempTipTable[randomTip][1][2], tempTipTable[randomTip][1][1])	
				Game.tAvailableHeroTips[tempTipTable[randomTip][1][3]][tempTipTable[randomTip][2]] = nil
			end
		end
	end
	GetWidget('game_hero_tip_parent'):RegisterWatch('EventKill', EventKill)	
	
	local function ActiveStatus(sourceWidget, status)
		local status = AtoB(status)
		if (status) then
			GetWidget('game_hero_tip_parent'):FadeOut(250)
			--GetWidget('game_hero_tip_parent'):Sleep(1250, function()
				
			--end)
		end
	end	
	GetWidget('game_hero_tip_parent'):RegisterWatch('ActiveStatus', ActiveStatus)

end

----------------------------------------------------------
-- 						Init	   						 --
----------------------------------------------------------
function Game:InitializeGameInterface()
	InitSounds()
	InitArcadeText()
	InitMidBar()
	InitKillBoard()
	InitScoreboard()
	InitPlayerTopLeftInfo()
	InitAllyInfo()
	InitVoteMenu()
	InitGameMenu()
	InitBottomCenterPanel()
	InitBottomSection()
	InitBottomRight()
	InitBackpack()
	InitChannelBar()
	InitActiveInventory()
	--InitAbililties()
	InitReactiveTips()
	
	InitSounds = nil
	InitArcadeText = nil
	InitMidBar = nil
	InitKillBoard = nil
	InitScoreboard = nil
	InitPlayerTopLeftInfo = nil
	InitAllyInfo = nil
	InitVoteMenu = nil
	InitGameMenu = nil
	InitBottomCenterPanel = nil
	InitBottomSection = nil
	InitBottomRight = nil
	InitBackpack = nil
	InitChannelBar = nil
	InitActiveInventory = nil
	--InitAbililties = nil	
	InitReactiveTips = nil
	InitWaveTicker = nil
	
	self.InitializeGameInterface = nil
end

local function ChatShowPostGameStats()	
	--println('^g^: GAME ChatShowPostGameStats 1')
	
	Set('ui_match_stats_waitingToShow', 'true', 'bool')
	Set('_stats_last_match_id', '', 'string')
	Set('_stats_last_replay_id', '', 'string')
	Set('_stats_last_match_id', GetShowStatsMatchID(), 'string')	
	
	printdb('In game ^g^: GetShowStatsMatchID() ' .. tostring(GetShowStatsMatchID()))
	
	if GetWidget('match_stats', nil, true) and GetWidget('match_stats', nil, true):IsVisible() then
		--println('^g^: GAME ChatShowPostGameStats 2')
		Set('ui_match_replays_blockSimpleStats', 'false', 'bool')
	else
		--println('^g^: GAME ChatShowPostGameStats 3')
		UIManager.GetInterface('main'):HoNMainF('MainMenuPanelToggle', 'match_stats', nil, true)
	end
end	
interface:RegisterWatch('ChatShowPostGameStats', ChatShowPostGameStats)

local function GamePhaseChange(sourceWidget, gamePhase)
	if (tonumber(gamePhase) <= 4) then
		GetWidget("game_hero_tip_parent", "game"):SetVisible(0);
	end

	if (GameChat) then
		GameChat.GamePhase(sourceWidget, gamePhase)
	end	
	if (HoN_Notifications) then
		HoN_Notifications.GamePhase(sourceWidget, gamePhase)
	end	
end	
interface:RegisterWatch('GamePhase', GamePhaseChange)

local function ChatWhisperUpdate(...)
	if (GameChat) then
		GameChat.ChatWhisperUpdate(...)
	end	
end
interface:RegisterWatch('ChatWhisperUpdate', ChatWhisperUpdate)

local function AllChatMessages(...)
	if (GameChat) then
		GameChat.AllChatMessages(...)
	end
end
interface:RegisterWatch('AllChatMessages', AllChatMessages)

local function GLIncorrectDisplay(_, param)
	if (not UIManager.GetInterface('main'):IsVisible()) then
		if AtoB(param) then
			if (not GetCvarBool('ui_hideGLIncorrectWarning')) then
				Trigger('TriggerDialogBoxWithComboboxGame', 'gl_incorrect_display', '', 'options_button_ok', '', '', 'gl_incorrect_display_desc', '', 'game_menu_dont_show_again', 'ui_hideGLIncorrectWarning')
			end
		else
			-- problem has been solved, hide it
			GetWidget("generic_dialog_box_combo_game"):FadeOut(100)
		end
	end
end
interface:RegisterWatch('GLIncorrectDisplay', GLIncorrectDisplay)	

----------------------------------------------------------
-- 		Allow UI script to call object functions	    --
----------------------------------------------------------
function interface:GameF(func, ...)
  print(Game[func](self, ...))
end	










