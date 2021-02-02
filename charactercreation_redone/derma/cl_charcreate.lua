local Padding = ScreenScale( 32 );

DEFINE_BASECLASS( "ixCharMenuPanel" );
local PANEL = {};

function PANEL:Init()
	-- Definitions (even if they don't do anything here):
	local Parent = self:GetParent();
	local HalfWidth = Parent:GetWide() * 0.5 - ( Padding * 2 );
	local HalfHeight = Parent:GetTall() * 0.5 - ( Padding * 2 );
	local ModelFOV = ( ScrW() > ScrH() * 1.8 ) and 100 or 78;
	-- Reset:
	self:ResetPayload( true );
	-- CharMenuInitalize Hook:
	hook.Run( "CharMenuInitalize", self );
	-- CharMenuPostInitalize Hook:
	hook.Run( "CharMenuPostInitalize", self );
end

function PANEL:SendPayload()
	if( self.AwaitingResponse or !self:VerifyProgression() ) then return end;
	self.AwaitingResponse = true;

	timer.Create( "ixCharacterCreateTimeout", 10, 1, function()
		if( IsValid( self ) and self.AwaitingResponse ) then
			self.AwaitingResponse = false;
			self:SlideDown();
			self:GetParent().MainPanel:Undim()
			self:GetParent():ShowNotice( 3, L( "unknownError" ) );
		end
	end)

	self.Payload:Prepare();

	net.Start( "ixCharacterCreate" );
		net.WriteTable( self.Payload );
	net.SendToServer();
end

function PANEL:OnSlideUp()
	self:ResetPayload();
	self:Populate();
	self.Progress:SetProgress( 1 );
	self:SetActiveSubpanel( "faction", 0 );
end

function PANEL:OnSlideDown()
end

function PANEL:ResetPayload( bWithHooks )
	if( bWithHooks ) then
		self.Hooks = {};
	end

	self.Payload = {};

	function self.Payload.Set( payload, key, value )
		self:SetPayload( key, value );
	end

	function self.Payload.AddHook( payload, key, callback )
		self:AddPayloadHook( key, callback );
	end

	function self.Payload.Prepare( payload )
		self.Payload.Set = nil;
		self.Payload.AddHook = nil;
		self.Payload.Prepare = nil;
	end
end

function PANEL:SetPayload( key, value )
	self.Payload[key] = value;
	self:RunPayloadHook( key, value );
end

function PANEL:AddPayloadHook( key, callback )
	if( !self.Hooks[key] ) then
		self.Hooks[key] = {};
	end

	self.Hooks[key][#self.Hooks[key] + 1] = callback;
end

function PANEL:RunPayloadHook( key, value )
	local hooks = self.Hooks[key] or {};
	for _, v in ipairs( hooks ) do
		v( value );
	end
end

function PANEL:GetContainerPanel( name )
	return hook.Run( "CharMenuGetContainerPanel", self, name );
end

function PANEL:AttachCleanup( panel )
	self.RepopulatePanels[#self.RepopulatePanels + 1] = panel;
end

function PANEL:Populate()
	-- CharMenuPopulate Hook:
	hook.Run( "CharMenuPopulate", self );
	self.bInitialPopulate = true;
	-- CharMenuPostPopulate Hook:
	hook.Run( "CharMenuPostPopulate", self );
end

function PANEL:VerifyProgression( name )
	for k, v in SortedPairsByMemberValue( ix.char.vars, "index" ) do
		if( name != nil and ( v.category or  "description" ) != name ) then continue end;
		local value = self.Payload[k];

		if( !v.bNoDisplay or v.OnValidate ) then
			if( v.OnValidate ) then
				local result = { v:OnValidate( value, self.Payload, LocalPlayer() ) };
				if( result[1] == false ) then
					self:GetParent():ShowNotice( 3, L( unpack( result, 2 ) ) );
					return false;
				end
			end
			self.Payload[k] = value;
		end
	end
	return true;
end

function PANEL:Paint( width, height )
	derma.SkinFunc( "PaintCharacterCreateBackground", self, width, height );
	BaseClass.Paint( self, width, height );
end

vgui.Register("ixCharMenuNew", PANEL, "ixCharMenuPanel")
