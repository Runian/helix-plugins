PLUGIN.name = "Character Creation: Redone"; 
PLUGIN.author = "Rune Knight";
PLUGIN.description = "Reforms the character creation derma by breaking it down into a readable table and adding hooks.";
PLUGIN.license = [[Copyright 2021 Rune Knight

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.]];

--[[
	STEAM: https://steamcommunity.com/profiles/76561198028996329/
	DISCORD: Rune Knight#5972
]]

--[[
	This plugin was ultimately created to simplify how the character creation is handled and to move it away from the schema.
]]

ix = ix or {};
ix.CCRedone = ix.CCRedone or {};
ix.CCRedone[1] = { -- Resetting any existing populated panels.
	["CharMenuPopulate"] = function( self )
		for i = 1, #self.RepopulatePanels do
			self.RepopulatePanels[i]:Remove();
		end

		self.RepopulatePanels = {};
	end
};
ix.CCRedone[2] = { -- Creation of the progress bar.
	["CharMenuInitalize"] = function( self )
		self.Progress = self:Add( "ixSegmentedProgress" );
		self.Progress:SetBarColor( ix.config.Get( "color" ) );
		self.Progress:SetSize( self:GetParent():GetWide(), 0 );
		self.Progress:SizeToContents();
		self.Progress:SetPos( 0, self:GetParent():GetTall() - self.Progress:GetTall() );
	end
};
ix.CCRedone[3] = { -- Factions & Whitelisting (PANEL #1: 'faction')
	["CharMenuInitalize"] = function( self )
		-- Definitions:
		local Padding = ScreenScale( 32 );
		local Parent = self:GetParent();
		local HalfWidth = Parent:GetWide() * 0.5 - ( Padding * 2 );
		local HalfHeight = Parent:GetTall() * 0.5 - ( Padding * 2 );
		local ModelFOV = ( ScrW() > ScrH() * 1.8 ) and 100 or 78;
		self.Factions = {};
		-- This is the buttons to pick what faction you want to be in. This is for populate later on!
		self.Factions.Buttons = {};
		self.Factions.Panel = self:AddSubpanel( "faction", true );
		self.Factions.Panel:SetTitle( "chooseFaction" );
		self.Factions.Panel.OnSetActive = function()
			-- Two options is two options, but one option is no option. Move on if there is no other option.
			if( #self.Factions.Buttons == 1 ) then
				self:SetActiveSubpanel( "description", 0 );
			end
		end
		
		self.Factions.PanelRight = self.Factions.Panel:Add( "Panel" );
		self.Factions.PanelRight:Dock( RIGHT );
		self.Factions.PanelRight:SetSize( HalfWidth + Padding * 2, HalfHeight );
		
		self.Factions.Proceed = self.Factions.PanelRight:Add( "ixMenuButton" );
		self.Factions.Proceed:SetText( "proceed" );
		self.Factions.Proceed:SetContentAlignment( 6 );
		self.Factions.Proceed:Dock( BOTTOM );
		self.Factions.Proceed:SizeToContents();
		self.Factions.Proceed.DoClick = function()
			self.Progress:IncrementProgress();
			self:Populate();
			self:SetActiveSubpanel( "description" );
		end
	
		self.Factions.Model = self.Factions.PanelRight:Add( "ixModelPanel" );
		self.Factions.Model:Dock( FILL );
		self.Factions.Model:SetModel( "models/error.mdl" );
		self.Factions.Model:SetFOV( ModelFOV );
		self.Factions.Model.PaintModel = self.Factions.Model.Paint;
	
		self.Factions.PanelLeft = self.Factions.Panel:Add( "ixCharMenuButtonList" );
		self.Factions.PanelLeft:SetWide( HalfWidth );
		self.Factions.PanelLeft:Dock( FILL );
	
		self.Factions.Back = self.Factions.Panel:Add( "ixMenuButton" );
		self.Factions.Back:SetText( "return" );
		self.Factions.Back:SizeToContents();
		self.Factions.Back:Dock( BOTTOM );
		self.Factions.Back.DoClick = function()
			self.Progress:DecrementProgress();
			self:SetActiveSubpanel( "faction", 0 );
			self:SlideDown();
			self:GetParent().mainPanel:Undim();
		end
	end,
	["CharMenuPopulate"] = function( self )
		if( !self.Payload.Faction ) then
			for _, v in pairs( self.Factions.Buttons ) do
				if( v:GetSelected() ) then
					v:SetSelected( true );
					break;
				end
			end
		end

		print( "hello?")
		self.Factions.PanelLeft:SizeToContents();

		if( self.bInitialPopulate ) then return end;
		local lastSelected;

		for _, v in pairs( self.Factions.Buttons ) do
			if( v:GetSelected() ) then
				lastSelected = v.Faction;
			end
			if( IsValid( v ) ) then
				v:Remove();
			end
		end

		self.Factions.Buttons = {};

		for _, v in SortedPairs( ix.faction.teams ) do
			if( ix.faction.HasWhitelist( v.index ) ) then
				local button = self.Factions.PanelLeft:Add( "ixMenuSelectionButton" );
				button:SetBackgroundColor( v.color or color_white );
				button:SetText( L( v.name ):utf8upper() );
				button:SizeToContents();
				button:SetButtonList( self.Factions.Buttons );
				button.Faction = v.index;
				button.OnSelected = function( panel )
					local faction = ix.faction.indices[panel.Faction];
					local models = faction:GetModels( LocalPlayer() );

					self.Payload:Set( "faction", panel.Faction );
					self.Payload:Set( "model", math.random( 1, #models ) );
				end
				if( ( lastSelected and lastSelected == v.index ) or ( !lastSelected and v.isDefault ) ) then
					button:SetSelected( true );
					lastSelected = v.index;
				end
			end
		end

		if( #self.Factions.Buttons > 1 ) then
			self.Progress:AddSegment( "@faction" );
		end

	end
};
ix.CCRedone[4] = { -- Description (PANEL #2: 'description')
	["CharMenuInitalize"] = function( self )
		-- Definitions:
		local Padding = ScreenScale( 32 );
		local Parent = self:GetParent();
		local HalfWidth = Parent:GetWide() * 0.5 - ( Padding * 2 );
		local HalfHeight = Parent:GetTall() * 0.5 - ( Padding * 2 );
		local ModelFOV = ( ScrW() > ScrH() * 1.8 ) and 100 or 78;

		self.Description = self:AddSubpanel( "description" );
		self.Description:SetTitle( "chooseDescription" );
		
		self.Description.PanelLeft = self.Description:Add( "Panel" );
		self.Description.PanelLeft:Dock( LEFT );
		self.Description.PanelLeft:SetSize( HalfWidth, HalfHeight );
	
		self.Description.Back = self.Description.PanelLeft:Add( "ixMenuButton" );
		self.Description.Back:SetText( "return" );
		self.Description.Back:SetContentAlignment( 4 );
		self.Description.Back:SizeToContents();
		self.Description.Back:Dock( BOTTOM );
		self.Description.Back.DoClick = function()
			self.Progress:DecrementProgress();
			if( #self.Factions.Buttons == 1 ) then
				self.Factions.Back:DoClick();
			else
				self:SetActiveSubpanel( "faction" );
			end
		end
	
		self.Description.Model = self.Description.PanelLeft:Add( "ixModelPanel" );
		self.Description.Model:Dock( FILL );
		self.Description.Model:SetModel( self.Factions.Model:GetModel() );
		self.Description.Model:SetFOV( ModelFOV - 13 );
		self.Description.Model.PaintModel = self.Description.Model.Paint;
		
		self.Description.PanelRight = self.Description:Add( "Panel" );
		self.Description.PanelRight:SetWide( HalfWidth + Padding * 2 );
		self.Description.PanelRight:Dock( RIGHT );
		
		self.Description.Proceed = self.Description.PanelRight:Add( "ixMenuButton" );
		self.Description.Proceed:SetText( "proceed" );
		self.Description.Proceed:SetContentAlignment( 6 );
		self.Description.Proceed:SizeToContents();
		self.Description.Proceed:Dock( BOTTOM );
		self.Description.Proceed.DoClick = function()
			if( self:VerifyProgression( "description" ) ) then
				-- TODO: Add comment!
				if ( #self.Attributes.PanelRight:GetChildren() < 2) then
					self:SendPayload();
					return
				end
				self.Progress:IncrementProgress();
				self:SetActiveSubpanel( "attributes" );
			end
		end			
	end,
	["CharMenuPopulate"] = function( self )
		if( self.bInitialPopulate ) then return end;

		self.Progress:AddSegment( "@description" );
	end
};
ix.CCRedone[5] = { -- Attributes (PANEL #3: 'attributes')
	["CharMenuInitalize"] = function( self )
		-- Definitions:
		local Padding = ScreenScale( 32 );
		local Parent = self:GetParent();
		local HalfWidth = Parent:GetWide() * 0.5 - ( Padding * 2 );
		local HalfHeight = Parent:GetTall() * 0.5 - ( Padding * 2 );
		local ModelFOV = ( ScrW() > ScrH() * 1.8 ) and 100 or 78;

		self.Attributes = self:AddSubpanel( "attributes" );
		self.Attributes:SetTitle( "chooseSkills" );
		
		self.Attributes.PanelLeft = self.Attributes:Add( "Panel" );
		self.Attributes.PanelLeft:Dock( LEFT );
		self.Attributes.PanelLeft:SetSize( HalfWidth, HalfHeight );

		self.Attributes.Back = self.Attributes.PanelLeft:Add( "ixMenuButton" );
		self.Attributes.Back:SetText( "return" );
		self.Attributes.Back:SetContentAlignment( 4 );
		self.Attributes.Back:SizeToContents();
		self.Attributes.Back:Dock( BOTTOM );
		self.Attributes.Back.DoClick = function()
			self.Progress:DecrementProgress();
			self:SetActiveSubpanel( "description" );
		end

		self.Attributes.Model = self.Attributes.PanelLeft:Add( "ixModelPanel" );
		self.Attributes.Model:Dock( FILL );
		self.Attributes.Model:SetModel( self.Factions.Model:GetModel() );
		self.Attributes.Model:SetFOV( ModelFOV - 13 );
		self.Attributes.Model.PaintModel = self.Attributes.Model.Paint;

		self.Attributes.PanelRight = self.Attributes:Add( "Panel" );
		self.Attributes.PanelRight:SetWide( HalfWidth + Padding * 2);
		self.Attributes.PanelRight:Dock( RIGHT );

		self.Attributes.Proceed = self.Attributes.PanelRight:Add( "ixMenuButton" );
		self.Attributes.Proceed:SetText( "finish" );
		self.Attributes.Proceed:SetContentAlignment( 6 );
		self.Attributes.Proceed:SizeToContents();
		self.Attributes.Proceed:Dock( BOTTOM );
		self.Attributes.Proceed.DoClick = function()
			self:SendPayload();
		end
	end,
	["CharMenuPopulate"] = function( self )
		if( self.bInitialPopulate ) then return end;

		if( #self.Attributes.PanelRight:GetChildren() > 1 ) then
			self.Progress:AddSegment( "@skills" );
		end
	end
};
ix.CCRedone[6] = { -- Hide progress bar if it's the only segment.
	["CharMenuPopulate"] = function( self )
		if( self.bInitialPopulate ) then return end;

		-- No need for the progress bar to be shown if it's only one segment.
		if( #self.Progress:GetSegments() == 1 ) then
			self.Progress:SetVisible( false );
		end
	end
};
ix.CCRedone[7] = { -- Populates all panels according to character variables.
	["CharMenuPopulate"] = function( self )
		local zPos = 1;
		print( "wtf")
		-- set up character vars
		for k, v in SortedPairsByMemberValue( ix.char.vars, "index" ) do
			if( !v.bNoDisplay and k != "__SortedIndex" ) then
				print( k )
				print( v.category )
				local container = self:GetContainerPanel( v.category or "description" );
				local panel;
				if( v.ShouldDisplay and v:ShouldDisplay( container, self.Payload ) == false ) then continue end;
				-- if the var has a custom way of displaying, we'll use that instead
				if( v.OnDisplay ) then
					panel = v:OnDisplay( container, self.Payload );
				elseif( isstring( v.default ) ) then
					panel = container:Add( "ixTextEntry" );
					panel:Dock( TOP );
					panel:SetFont( "ixMenuButtonHugeFont" );
					panel:SetUpdateOnType( true );
					panel.OnValueChange = function( this, text )
						self.Payload:Set( k, text );
					end
				end

				if( IsValid( panel ) ) then
					-- add label for entry
					local label = container:Add( "DLabel" );
					label:SetFont( "ixMenuButtonLabelFont" );
					label:SetText( L( k ):utf8upper() );
					label:SizeToContents();
					label:DockMargin( 0, 16, 0, 2 );
					label:Dock( TOP );

					-- we need to set the docking order so the label is above the panel
					label:SetZPos( zPos - 1 );
					panel:SetZPos( zPos );

					self:AttachCleanup( label );
					self:AttachCleanup( panel );

					if( v.OnPostSetup ) then
						v:OnPostSetup( panel, self.Payload );
					end

					zPos = zPos + 2;
				end
			end
		end
	end
};

hook.Add( "CharMenuInitalize", "CharMenuRedoneInitalize", function( self )
	self.RepopulatePanels = {};
	for _, context in ipairs( ix.CCRedone ) do
		for hookname, func in pairs( context ) do
			if( hookname != "CharMenuInitalize" ) then continue end;
			func( self );
		end
	end
end );

hook.Add( "CharMenuPostInitalize", "CharMenuRedonePostInitalize", function( self )
	for _, context in pairs( ix.CCRedone ) do
		for hookname, func in pairs( context ) do
			if( hookname != "CharMenuPostInitalize" ) then continue end;
			func( self );
		end
	end

	self:AddPayloadHook( "model", function( value )
		local faction = ix.faction.indices[self.Payload.faction];
		if( faction ) then
			local model = faction:GetModels( LocalPlayer() )[value];
			if( istable( model ) ) then
				self.Factions.Model:SetModel( model[1], model[2] or 0, model[3] );
				self.Description.Model:SetModel( model[1], model[2] or 0, model[3] );
				self.Attributes.Model:SetModel( model[1], model[2] or 0, model[3] );
			else
				self.Factions.Model:SetModel( model );
				self.Description.Model:SetModel( model );
				self.Attributes.Model:SetModel( model );
			end
		end
	end );

	net.Receive("ixCharacterAuthed", function()
		timer.Remove( "ixCharacterCreateTimeout" );
		self.AwaitingResponse = false;

		local id = net.ReadUInt( 32 );
		local indices = net.ReadUInt( 6 );
		local charList = {};

		for _ = 1, indices do
			charList[#charList + 1] = net.ReadUInt( 32 );
		end

		ix.characters = charList;

		self:SlideDown();

		if( !IsValid( self ) or !IsValid( self:GetParent() ) ) then return end;

		if( LocalPlayer():GetCharacter() ) then
			self:GetParent().mainPanel:Undim();
			self:GetParent():ShowNotice( 2, L( "charCreated" ) );
		elseif( id ) then
			self.bMenuShouldClose = true;

			net.Start( "ixCharacterChoose" );
				net.WriteUInt( id, 32 );
			net.SendToServer();
		else
			self:SlideDown();
		end
	end)

	net.Receive("ixCharacterAuthFailed", function()
		timer.Remove( "ixCharacterCreateTimeout" );
		self.AwaitingResponse = false;

		local fault = net.ReadString();
		local args = net.ReadTable();

		self:SlideDown();

		self:GetParent().mainPanel:Undim();
		self:GetParent():ShowNotice( 3, L( fault, unpack( args ) ) );
	end)

end );

hook.Add( "CharMenuPopulate", "CharMenuRedonePopulate", function( self )
	for num, context in ipairs( ix.CCRedone ) do
		print( num )
		for hookname, func in pairs( context ) do
			if( hookname != "CharMenuPopulate" ) then continue end;
			func( self );
		end
	end
end );

hook.Add( "CharMenuPostPopulate", "CharMenuRedonePopulate", function( self )
	for _, context in ipairs( ix.CCRedone ) do
		for hookname, func in pairs( context ) do
			if( hookname != "CharMenuPostPopulate" ) then continue end;
			func( self );
		end
	end
end );

hook.Add( "CharMenuGetContainerPanel", "CharMenuRedoneGetContainerPanel", function( self, name )
	if( name == "faction" ) then
		return self.Factions.PanelLeft;
	elseif( name == "description" ) then
		return self.Description.PanelRight;
	elseif( name == "attributes" ) then
		return self.Attributes.PanelRight;
	end
end );