local version = "";
local pvpkills = 0;
local pvekills = 0;
local debug = true;
local screenshot = true;

local root_sound_path = "Interface\\AddOns\\killpro\\audio\\";
local syst_sound_path = "sys\\";
local pack_sound_path = "packs\\";

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
		message = {
			type = 'text',
			name = 'Display message.',
			desc = 'The message displayed after a kill has been made.',
			usage = '<message>',
			get = "getMessage",
			set = "setMessage"
		},
		getpos = {
			type = 'execute',
			name = 'Print player information.',
			desc = 'Prints all information pertaining to positioning.',
			func = function()
					kp:printPos()
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
		resetpve = {
			type = 'execute',
			name = 'Reset PvE kills.',
			desc = 'Reset your PvE kills.',
			desc = 'Resets your PvE kills to zero.',
			func = function()
					kp:resetPvEKills()
			       end
		},
		resetall = {
			type = 'execute',
			name = 'Reset all kills.',
			desc = 'Resets all kill counters to zero.',
			func = function()
					kp:resetAllKills()
			       end
		}
	}
};

kp = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0");
kp:RegisterChatCommand({"/killpro"}, options)
kp:RegisterDB("kpDBv2", "kpDBPCv2");

kp:RegisterDefaults("profile", {
	kpmsg = "owned"
});

function kp:OnEnable()
	kp:Print("|cff7777aaKillPro module loaded.|r");
	-- kp:audioPlayer(root_sound_path .. syst_sound_path .. "fear.ogg");
end

function kp:OnDisable()

end

function kp:ZoneHandler()
	
end

function kp:testKill()
	
end

function kp:resetPvPKills()
	
end

function kp:resetPvEKills()
	
end

function kp:resetAllKills()
	
end

function kp:getMessage()
	
end

function kp:setMessage()
	
end

function kp:printPos()
	
end

function kp:audioPlayer(sound)
	
	PlaySoundFile(sound);

	if not (PlaySoundFile(sound)) then
		
	end
end