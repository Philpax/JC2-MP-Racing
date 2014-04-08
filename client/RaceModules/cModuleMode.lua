class("Mode" , RaceModules)

function RaceModules.Mode:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.timer = nil
	
	self.timerControl = nil
	
	self:EventSubscribe("RaceEnd")
	self:NetworkSubscribe("RaceWillEndIn")
end

-- Events

function RaceModules.Mode:Render()
	
end

function RaceModules.Mode:RaceEnd()
	if self.timerControl then
		self.timerControl:Remove()
	end
	
	self:Destroy()
end

-- Network events

function RaceModules.Mode:RaceWillEndIn(endTime)
	self:EventSubscribe("Render")
	
	self.timerControl = RaceMenuUtility.CreateTimer("next race" , endTime)
end