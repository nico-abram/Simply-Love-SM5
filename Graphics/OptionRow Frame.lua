local t = Def.ActorFrame {}

-- a row
t[#t + 1] =
	Def.Quad {
	Name = "RowBackgroundQuad",
	OnCommand = function(self)
		self:zoomto(_screen.w * 0.85, _screen.h * 0.0625)
	end
}

-- black quad behind the title
t[#t + 1] =
	Def.Quad {
	Name = "TitleBackgroundQuad",
	OnCommand = function(self)
		self:halign(0):x(-_screen.cx / 1.1775):zoomto(_screen.w * WideScale(0.18, 0.15), _screen.h * 0.0625):diffuse(
			Color.Black
		):diffusealpha(BrighterOptionRows() and 0.8 or 0.25)
	end
}

-- This feels pretty hackish.
-- ScreenPlayerOptions overlay.lua has all the necessary NoteSkin actors loaded but not showing.
--
-- Here, we're adding one ActorProxy per-player per-OptionRow.  That's a lot of ActorProxies that mostly aren't being used! :(
--
-- Once the OptionRows are ready (after the ScreenPlayerOptions is processed), we can check each OptionRow's name.
-- If GetName() returns "NoteSkin" then SetTarget() using the appropriate hidden NoteSkin actor.

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)

	t[#t + 1] =
		SL.IsEtterna and
		Def.ActorFrame {
			Name = "OptionRowProxy" .. pn,
			OnCommand = function(self)
				local optrow = self:GetParent():GetParent():GetParent()
				self.isNS = optrow:GetName() == "NoteSkin"
				if self.isNS then
					self:SetUpdateFunction(
						function()
							if self.lastns then
								local noteskin_actor = self.lastns
								noteskin_actor:y(self:GetTrueY())
							end
						end
					)
					self:xy(0, 0)
				else
					-- if this OptionRow isn't NoteSkin, this ActorProxy isn't needed
					-- and can be cut out of the render pipeline
					self:visible(false)
					if self.lastns then
						self.lastns:visible(false)
						self.lastns = nil
					end
				end
			end,
			-- NoteSkinChanged is broadcast by the SaveSelections() function for the NoteSkin OptionRow definition
			-- in ./Scripts/SL-PlayerOptions.lua
			NoteSkinChangedMessageCommand = function(self, params)
				if not self.isNS then
					return
				end
				if player == params.Player then
					-- attempt to find the hidden NoteSkin actor added by ./BGAnimations/ScreenPlayerOptions overlay.lua
					local noteskin_actor = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("NoteSkin_" .. params.NoteSkin)

					if self.lastns then
						self.lastns:visible(false)
						self.lastns = nil
					end
					-- ensure that that NoteSkin actor exists before attempting to set it as the target of this ActorProxy
					if noteskin_actor then
						self.lastns = noteskin_actor
						noteskin_actor:y(self:GetTrueY()):zoom(0.4):diffusealpha(0):sleep(0.01):diffusealpha(1):visible(true)
					end
				end
			end
		} or
		Def.ActorProxy {
			Name = "OptionRowProxy" .. pn,
			OnCommand = function(self)
				local optrow = self:GetParent():GetParent():GetParent()
				if optrow:GetName() == "NoteSkin" then
					-- if this OptionRow is NoteSkin, set the necessary parameters and queuecommand("Update")
					-- to actually SetTarget() to the appropriate NoteSkin actor
					self:x(-_screen.cx / 1.1775 + _screen.w * WideScale(0.18, 0.15) - (player == PLAYER_1 and 45 or 15)):zoom(0.4):diffusealpha(
						0
					):sleep(0.01):diffusealpha(1)
				else
					-- if this OptionRow isn't NoteSkin, this ActorProxy isn't needed
					-- and can be cut out of the render pipeline
					self:hibernate(math.huge)
				end
			end,
			-- NoteSkinChanged is broadcast by the SaveSelections() function for the NoteSkin OptionRow definition
			-- in ./Scripts/SL-PlayerOptions.lua
			NoteSkinChangedMessageCommand = function(self, params)
				if player == params.Player then
					-- attempt to find the hidden NoteSkin actor added by ./BGAnimations/ScreenPlayerOptions overlay.lua
					local noteskin_actor = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("NoteSkin_" .. params.NoteSkin)

					-- ensure that that NoteSkin actor exists before attempting to set it as the target of this ActorProxy
					if noteskin_actor then
						self:SetTarget(noteskin_actor)
					end
				end
			end
		}
end

return t
