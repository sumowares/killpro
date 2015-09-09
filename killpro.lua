local version = "ALPHA 0.5";

-- Access help with '/killlshot'

-- This addon was originally created for as a request on the
-- nostalrius private vanilla server where a user requested active
-- working copy of killshot. Rather, than tinker with a system and
-- attempt to downgrade an entire framework I decided to write my
-- own addon.  Enjoy, and if you have any questions feel free to 
-- let me know.

-- url: http://forum.nostalrius.org/viewtopic.php?f=63&t=20917

local incombat = false;

local root_sound_path = "Interface\\AddOns\\killpro\\audio\\";
local syst_sound_path = "sys\\";
local pack_sound_path = "packs\\";
local ozone = "Startup";
local loaded = 0;
local stest = "Osanna dies, you gain honor!";

--local logpve = true;
local logpvp = true;

local isplayerdead = false;

local options = {
	type = 'group',
	args = {
		test = {
			type = 'execute',
			name = 'Test kill functions.',
			desc = 'Test kill functions using current parameters.',
			func = function()
					kp:testKill()
			       end
		},
		voice = {
			type = 'text',
			name = 'Voice pack name',
			desc = 'The voice pack for killpro to use, must be in /AddOns/killpro/audio/packs.',
			usage = '<pack>',
			get = "getAudio",
			set = "setAudio",
		},
		getpos = {
			type = 'execute',
			name = 'Print player information.',
			desc = 'Prints all information pertaining to positioning.',
			func = function()
					kp:printPos()
				   end
		},
		pvpkills = {
			type = 'execute',
			name = 'View current PvP kills.',
			desc = 'View how many enemies killed for current session/zone.',
			func = function()
					kp:getPvPKills()
				   end
		},
		pvpstreak = {
			type = 'execute',
			name = 'View PvP streak.',
			desc = 'View statistical information pertaining to PvP kill streak.',
			func = function()
					kp:getPvPStreak()
				   end
		},
		resetpvp = {
			type = 'execute',
			name = 'Reset PvP kills.',
			desc = 'Resets your PvP kills down to zero.',
			func = function()
					kp:resetPvPKills()
				   end
		},
		resetall = {
			type = 'execute',
			name = 'Reset all kills.',
			desc = 'Resets all kill counters to zero.',
			func = function()
					kp:resetAllKills()
			       end
		},
		pvpsnaps = {
			type = 'text',
			name = 'PvP snaps.',
			desc = 'Use <on/off> to take screenshots of PvP kills.',
			usage = '<on/off>',
			get =  "getPvPSnap",
			set =  "setPvPSnap",
		},
		mute = {
			type = 'text',
			name = 'Mute sounds.',
			desc = 'Use <on/off> to mute addon sounds.',
			usage = '<on/off>',
			get =  "getSMute",
			set =  "setSMute",
		},
		message = {
			type = 'text',
			name = 'Display message.',
			desc = 'The message displayed after a kill has been made.',
			usage = '<message>',
			get = "getMessage",
			set = "setMessage",
		},
		emote = {
			type = 'text',
			name = 'Emote on kill',
			desc = 'An emote to perform whenever you kill or assist.',
			usage = '<emote>',
			get = 'getEmote',
			set = 'setEmote',
		},
		debug = {
			type = 'text',
			name = 'Verbose debugging.',
			desc = 'Turns verbose debugging on/off.',
			usage = '<on/off>',
			get = "getDebug",
			set = "setDebug",
		},
	}
};

kp = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0");
kp:RegisterChatCommand({"/killpro", "/kp"}, options)
kp:RegisterDB("kpDBv2", "kpDBPCv2");

local parser = ParserLib:GetInstance("1.1");

function kp:OnEnable()
-- the events that handle player events, such as combat
-- death, logout, and combat
	self:RegisterEvent("PLAYER_DEAD", "DeathHandler");
	self:RegisterEvent("PLAYER_LOGOUT", "OnLogout");
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatBegin");
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatEnd");
	self:RegisterEvent("PLAYER_UNGHOST", "resetAlive");
	
-- the event that handles the killing of an honorable
-- target
	self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "LogKill");

-- the event that handles when a player changes current zone
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneHandler");
		
-- the audio processor which is used whenever WoW is
-- unable to play a sound fire during a particular instance
	self:RegisterEvent("kp_SoundEvent", "audioPlayer");
	
	kp:Print("Killpro is now active.");
end

function kp:OnInitialize()
	kp:Print("Initialized the interfaces.");
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "fear.ogg");
	ozone = GetZoneText();
end

function kp:OnLogout()
-- reset all kills in memory to zero to avoid false kills
-- on the next active session
	self.db.profile.pvpstreak = 0;
	self.db.profile.pvpkills = 0;
end

-- register the default variables for a clean installation of killpro
kp:RegisterDefaults("profile", {
	apack = "female_sexy",
	pvesnap = "off",
	pvpsnap = "off",
	mute = "off",
	message = "Victory!!",
	emote = "laugh",
	pvpkills = 0,
	pvekills = 0,
	pvpstreak = 0,
	pvestreak = 0,
	isdebug = "off",
	hspvp = 0,
	hspve = 0,
});

function kp:resetAlive()
	if (self.db.profile.isdebug == "on") then
		kp:Print("Received message that you are back from the dead.");
	end

-- reset isplayerdead to false that way the addon knows that the
-- player is alive and well
	isplayerdead = false;
end

-- get the debug value
function kp:getDebug()
	return self.db.profile.isdebug;
end

-- set the debug value <value>
function kp:setDebug(value)
	self.db.profile.isdebug = value;
end

-- get the kill message
function kp:getMessage()
	return self.db.profile.message;
end

-- set the kill message <message>
function kp:setMessage(message)
	self.db.profile.message = message;
end

-- get the mute value
function kp:getSMute()
	return self.db.profile.mute;
end

-- set the mute value <value>
function kp:setSMute(value)
	self.db.profile.mute = value;
end

-- get the pvp snapshot value
function kp:getPvPSnap()
	return self.db.profile.pvpsnap;
end

-- set the pvp snapshot value <value>
function kp:setPvPSnap(value)
	self.db.profile.pvpsnap = value;
end

-- get the emote value 
function kp:getEmote()
	return self.db.profile.emote;
end

-- set the emote value <value>
function kp:setEmote(value)
	self.db.profile.emote = value;
end

-- print the total number of players killed this zone/session
function kp:getPvPKills()
	kp:Print("You have killed " .. self.db.profile.pvpkills .. " this session/zone.");
end

-- print the current kill streak and show the highest streak
function kp:getPvPStreak()
	kp:Print("Your current streak is " .. self.db.profile.pvpstreak .. " this session, your highest streak is " .. self.db.profile.hspvp .. "!");
end

-- called whenever a player dies
function kp:DeathHandler()
-- set the isplayerdead to true
	isplayerdead = true;
-- reset the current kill streak
	self.db.profile.pvpstreak = 0;
	
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_death.ogg");
	
	if (self.db.profile.isdebug == "on") then
		kp:Print("You are now dead, congratulations.");
	end
end

-- called whenever combat begins
function kp:CombatBegin()
-- set incombat to true so we know a player is fighting
	incombat = true;
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_combat_begin.ogg");
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("Now entering combat mode.");
	end
end

-- called whenever combat ends
function kp:CombatEnd()
-- set incombat to false so we know that combat is over
	incombat = false;
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("Now leaving combat mode.");
	end
	
-- check if the player is dead, if not play victory sound
	if (isplayerdead == false) then
		kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_combat_end.ogg");
	end
	
	logpvp = true;
end

-- called whenever a player changes active zones
function kp:ZoneHandler()
-- this will prevent the addon from displaying meaningless
-- data whenever the addon is loaded into memory
	if (loaded == 0) then loaded = loaded + 1; return; end;
	
	kp:Print("Summary for " .. ozone .. ".");
	kp:Print("==================================");
	kp:Print("Total PvP Kills:" .. self.db.profile.pvpkills);
	kp:Print("PvP Kill Streak:" .. self.db.profile.pvpstreak);
	
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
	
	kp:Print("Zone has changed from " .. ozone .. " to " .. GetZoneText() .. " killing streak and count has been reset.");

-- set the old zone to the current zone
	ozone = GetZoneText();
end

-- called whenever the player tests the system
function kp:testKill()
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "fear.ogg");
	
	local startPos, endPos, playerName, restOfString = string.find("Sumo dies, honorable kill Rank: (Estimated Honor Points:6) has been received.", "(%w+)[%s%p]*(.*)" );
	kp:messageHud(self.db.profile.message .. " " .. playerName .. " " .. self.db.profile.pvpkills .. " kills!!");
	
end

-- called whenever a player wishes to reset current
-- kill information
function kp:resetPvPKills()
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
	
	kp:Print("Reset all PvP type counters.");
end

-- called whenever a player wishes to reset all
-- kill information
function kp:resetAllKills()
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
	self.db.profile.hspvp = 0;
	
	kp:Print("Reset all PvP type counters.");
end

-- called whenever a player wishes to geographical information
function kp:printPos()
	
end

-- prints a message to the screen as floating text
function kp:messageHud(message)
    if (IsAddOnLoaded("Blizzard_CombatText")) then CombatText_AddMessage(message, CombatText_StandardSCroll, 1, 0.1, 0.1, "crit", 0);        
    elseif (IsAddOnLoaded("SCT")) then SCT:DisplayText(message, {r=1.0, g=0.1, b=0.1}, 1, "event", 1, 1);             
    end
end

-- called whenever a snapshot needs to be taken
function kp:TakeSnap()
	Screenshot();
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("A screenshot has been recorded.");
	end
end

-- called whenever player receives honorpoints for
-- either killing or assisting a kill
function kp:LogKill(message)

-- check if we are in combat, if not then just get out of 
-- here as we have no business being here
	if (incombat == true) then
-- check to make sure that we can log this as a kill, more or less
-- this is put in place to prevent multiple false calls
		if (logpvp == false) then return; end;
		self.db.profile.pvpkills = self.db.profile.pvpkills + 1;
		self.db.profile.pvpstreak = self.db.profile.pvpstreak + 1;
		
-- get the name of the player that has just been killed
		local startPos, endPos, playerName, restOfString = string.find(message, "(%w+)[%s%p]*(.*)" );
		kp:messageHud(self.db.profile.message .. " " .. playerName .. " " .. self.db.profile.pvpkills .. " kills!!");

-- set our logpvp flag to false to prevent false calls
		logpvp = false;
		
		if (self.db.profile.isdebug =="on") then
			kp:Print("A PvP message of [" .. message .. "] has been received, extracted [" .. playerName .. "] as characters name.");
		end
		
		kp:killAudio(self.db.profile.pvpkills);
		
-- a new high streak has been set, we need to notify the user of this!
		if (self.db.profile.pvpstreak > self.db.profile.hspvp) then
			self.db.profile.hspvp = self.db.profile.pvpstreak;
			kp:messageHud(self.db.profile.hspvp .. " kills!! A new PvP record streak!!");
			
			if (self.db.profile.isdebug =="on") then
				kp:Print("A new PvP streak of " .. self.db.profile.pvpstreak .. " has been recorded.");
			end
		end
		
		if (self.db.profile.pvpsnap == "on") then
			kp:TakeSnap();
		end
		
		if (self.db.profile.emote ~= "none") then
			SendChatMessage(self.db.profile.message .. " " .. playerName .. " " .. self.db.profile.pvpkills .. " kills this session!", "EMOTE", nil, nil);
			DoEmote(self.db.profile.emote,"none"); 
		end
	end
end

function kp:getAudio()
	return self.db.profile.apack;
end

function kp:setAudio(pack)
	self.db.profile.apack = pack;
end

-- pipes audio out to kp:audioPlayer depending upon the number
-- of kills
function kp:killAudio(value)
		if (self.db.profile.isdebug =="on") then
			kp:Print("Audio processor received an Int value of " .. value .. ".");
			kp:Print("Audio file chosen is: " .. root_sound_path .. pack_sound_path .. self.db.profile.apack .. "\\" .. value .. ".ogg");
		end
		
		if (value > 14) then
			kp:audioPlayer(root_sound_path .. pack_sound_path .. self.db.profile.apack .. "\\14.ogg");
		else
			kp:audioPlayer(root_sound_path .. pack_sound_path .. self.db.profile.apack .. "\\" .. value .. ".ogg");
		end
end

-- plays audio to the audio device
function kp:audioPlayer(sound)
	if (self.db.profile.mute == "on") then return; end;

	if (self.db.profile.isdebug =="on") then
		kp:Print("Attempting to play: " .. sound);
	end

	if not (PlaySoundFile(sound)) then
-- unable to play audio, reschedule the event to fire again
		self:ScheduleEvent("kp_SoundEvent", 0.2, sound);
	end
end