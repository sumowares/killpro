local version = "ALPHA 0.5";

-- Access help with '/killlshot'

-- This addon was originally created for as a request on the
-- nostalrius private vanilla server where a user requested active
-- working copy of killshot. Rather, than tinker with a system and
-- attempt to downgrade an entire framework I decided to write my
-- own addon.  Enjoy, and if you have any questions feel free to 
-- let me know.

local incombat = false;

local root_sound_path = "Interface\\AddOns\\killpro\\audio\\";
local syst_sound_path = "sys\\";
local pack_sound_path = "packs\\";
local ozone = "";

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
		--pvekills = {
		--	type = 'execute',
		--	name = 'View current PvE kills.',
		--	desc = 'View how many enemies killed for current session/zone.',
		--	func = function()
		--			kp:getPvEKills()
		--		   end
		--},
		--pvestreak= {
		--	type = 'execute',
		--	name = 'View PvE streak.',
		--	desc = 'View statistical information pertaining to PvE kill streak.',
		--	func = function()
		--		    kp:getPvEStreak()
		--		   end
		--},
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
		--resetpve = {
		--	type = 'execute',
		--	name = 'Reset PvE kills.',
		--	desc = 'Reset your PvE kills.',
		--	desc = 'Resets your PvE kills to zero.',
		--	func = function()
		--			kp:resetPvEKills()
		--	       end
		--},
		resetall = {
			type = 'execute',
			name = 'Reset all kills.',
			desc = 'Resets all kill counters to zero.',
			func = function()
					kp:resetAllKills()
			       end
		},
		--pvesnaps = {
		--	type = 'text',
		--	name = 'PvE snaps.',
		--	desc = 'Use <on/off> to take screenshots of PvE kills.',
		--	usage = '<on/off>',
		--	get =   "getPvESnap",
		--	set =  "setPvESnap",
		--},
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
kp:RegisterChatCommand({"/killpro"}, options)
kp:RegisterDB("kpDBv2", "kpDBPCv2");

deformat = AceLibrary("Deformat-2.0");

function kp:OnEnable()
	self:RegisterEvent("PLAYER_DEAD", "DeathHandler");
	self:RegisterEvent("PLAYER_LOGOUT", "OnLogout");
	self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "LogKill");
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatBegin");
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatEnd");
	self:RegisterEvent("kp_SoundEvent", "audioPlayer");
	self:RegisterEvent("PLAYER_UNGHOST", "resetAlive");
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneHandler");
	
	kp:Print("Registered events with Warcraft API, addon is now active.");
end

function kp:OnInitialize()
	kp:Print("Initialized the interfaces.");
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "fear.ogg");
	ozone = GetZoneText();
end

function kp:OnLogout()
	--self.db.profile.pvestreak = 0;
	self.db.profile.pvpstreak = 0;
	--self.db.profile.pvekills = 0;
	self.db.profile.pvpkills = 0;
end

kp:RegisterDefaults("profile", {
	apack = "female_sexy",
	pvesnap = "off",
	pvpsnap = "off",
	mute = "off",
	message = "Victory!!",
	pvpkills = 0,
	pvekills = 0,
	pvpstreak = 0,
	pvestreak = 0,
	isdebug = "off",
	hspvp = 0,
	hspve = 0,
});

function kp:resetAlive()
	isplayerdead = false;
end

function kp:getDebug()
	return self.db.profile.isdebug;
end

function kp:setDebug(value)
	self.db.profile.isdebug = value;
end

function kp:getMessage()
	return self.db.profile.message;
end

function kp:setMessage(message)
	self.db.profile.message = message;
end

function kp:getSMute()
	return self.db.profile.mute;
end

function kp:setSMute(value)
	self.db.profile.mute = value;
end

--function kp:getPvESnap()
--	return self.db.profile.pvesnap;
--end

--function kp:setPvESnap(value)
--	self.db.profile.pvesnap = value;
--end

function kp:getPvPSnap()
	return self.db.profile.pvpsnap;
end

function kp:setPvPSnap(value)
	self.db.profile.pvpsnap = value;
end

--function kp:getPvEKills()
--	kp:Print("You have killed " .. self.db.profile.pvekills .. " this session/zone.");
--end

--function kp:getPvEStreak()
--	kp:Print("Your current streak is " .. self.db.profile.pvestreak .. " this session, your highest streak is " .. self.db.profile.hspve .. "!");
--end

function kp:getPvPKills()
	kp:Print("You have killed " .. self.db.profile.pvpkills .. " this session/zone.");
end

function kp:getPvPStreak()
	kp:Print("Your current streak is " .. self.db.profile.pvpstreak .. " this session, your highest streak is " .. self.db.profile.hspvp .. "!");
end

function kp:DeathHandler()
	isplayerdead = true;
	--self.db.profile.pvestreak = 0;
	self.db.profile.pvpstreak = 0;
	
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_death.ogg");
	
	if (self.db.profile.isdebug == "on") then
		kp:Print("You are now dead, congratulations.");
	end
end

function kp:CombatBegin()
	incombat = true;
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_combat_begin.ogg");
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("Now entering combat mode.");
	end
end

function kp:CombatEnd()
	incombat = false;
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("Now leaving combat mode.");
	end
	
	if (isplayerdead == false) then
		kp:audioPlayer(root_sound_path .. syst_sound_path .. "self_combat_end.ogg");
	end
	
--	logpve = true;
	logpvp = true;
end

function kp:ZoneHandler()
	
	kp:Print("Summary for " .. ozone .. ".");
	kp:Print("==================================");
--	kp:Print("Total PvE Kills: " .. self.db.profile.pvekills);
--	kp:Print("PvE Kill Streak:" .. self.db.profile.pvpstreak);
	kp:Print("Total PvP Kills:" .. self.db.profile.pvpkills);
	kp:Print("PvP Kill Streak:" .. self.db.profile.pvpstreak);
	
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
--	self.db.profile.pvekills = 0;
--	self.db.profile.pvestreak = 0;
	
	kp:Print("Zone has changed from " .. ozone .. " to " .. GetZoneText() .. " killing streak and count has been reset.");
	ozone = GetZoneText();
end

function kp:testKill()
	kp:Print(deformat("", UNITDIESOTHER));
	kp:audioPlayer(root_sound_path .. syst_sound_path .. "fear.ogg");
	kp:messageHud("This is a test.");
end

function kp:resetPvPKills()
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
	self.db.profile.hspvp = 0;
	
	kp:Print("Reset all PvP type counters.");
end

--function kp:resetPvEKills()
--	self.db.profile.pvekills = 0;
--	self.db.profile.pvestreak = 0;
--	self.profile.hspve = 0;
--	
--	kp:Print("Reset all PvE type counters.");
--end

function kp:resetAllKills()
	self.db.profile.pvpkills = 0;
	self.db.profile.pvpstreak = 0;
	self.db.profile.hspvp = 0;
--	self.db.profile.pvekills = 0;
--	self.db.profile.pvestreak = 0;
--	self.profile.hspve = 0;
	
	kp:Print("Reset all PvP type counters.");
end

function kp:printPos()
	
end

function kp:printMessage(message, color)
	kp:Print(message);
end

function kp:messageHud(message)
    if (IsAddOnLoaded("Blizzard_CombatText")) then CombatText_AddMessage(message, CombatText_StandardSCroll, 1, 0.1, 0.1, "crit", 0);        
    elseif (IsAddOnLoaded("SCT")) then SCT:DisplayText(message, {r=1.0, g=0.1, b=0.1}, 1, "event", 1, 1);             
    end
end

function kp:TakeSnap()
	Screenshot();
	
	if (self.db.profile.isdebug =="on") then
		kp:Print("A screenshot has been recorded.");
	end
end

function isempty(s)
	return s == nil or s == ''
end

function kp:LogKill(message)

	if (incombat == true) then
		if (logpvp == false) then return; end;
		self.db.profile.pvpkills = self.db.profile.pvpkills + 1;
		self.db.profile.pvpstreak = self.db.profile.pvpstreak + 1;
		
		kp:messageHud(self.db.profile.message .. " " .. self.db.profile.pvpkills .. " kills!!");
		logpvp = false;
		
		if (self.db.profile.isdebug =="on") then
			kp:Print("A PvP message of " .. message .. " has been received.");
		end
		
		kp:killAudio(self.db.profile.pvpkills);
		
		if (self.db.profile.isdebug =="on") then
			kp:Print("A message of " .. message .. " has been received.");
		end
		
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
	end
end

function kp:getAudio()
	return self.db.profile.apack;
end

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

function kp:audioPlayer(sound)
	if (self.db.profile.mute == "on") then return; end;

	if (self.db.profile.isdebug =="on") then
		kp:Print("Attempting to play: " .. sound);
	end

	if not (PlaySoundFile(sound)) then
		self:ScheduleEvent("kp_SoundEvent", 0.2, sound);
	end
end

function kp:setAudio(pack)
	self.db.profile.apack = pack;
end