function CourseCheckpoint:__init(course)
	self.course = course
	self.index = -1
	self.position = nil
	self.radius = 12.05
	self.type = 7
	-- nil = Allow all vehicles and on-foot.
	-- {} -- Allow all vehicles but not on-foot.
	-- {0} = Only allow on-foot. TODO: Wait, shouldn't it be -1?
	self.validVehicles = nil
	self.useIcon = false
	self.isRespawnable = true
	self.checkpoint = nil
	-- When racer enters checkpoint, these functions of ours are called. One argument: racer.
	-- Array of function names.
	self.actions = {}
end

function CourseCheckpoint:Spawn()
	local spawnArgs = {}
	spawnArgs.position = self.position
	spawnArgs.create_checkpoint = true
	spawnArgs.create_trigger = true
	spawnArgs.create_indicator = self.useIcon
	spawnArgs.type = self.type
	spawnArgs.world = self.course.race.world
	spawnArgs.despawn_on_enter = false
	spawnArgs.activation_box = Vector3(
		self.radius ,
		self.radius ,
		self.radius
	)
	spawnArgs.enabled = true
	
	self.checkpoint = Checkpoint.Create(spawnArgs)
	
	self.course.checkpointMap[self.checkpoint:GetId()] = self
end

function CourseCheckpoint:GetIsValidVehicle(vehicle)
	-- We don't have a required vehicle.
	if self.validVehicles == nil then
		return true
	-- We require any vehicle.
	elseif table.count(self.validVehicles) == 0 then
		return vehicle ~= nil
	-- We require a vehicle from a list.
	else
		local vehicleModelId
		if vehicle then
			vehicleModelId = vehicle:GetModelId()
		else
			-- On-foot.
			vehicleModelId = 0
		end
		
		for n , modelId in ipairs(self.validVehicles) do
			if modelId == vehicleModelId then
				return true
			end
		end
	end
	
	return false
end

-- Called by PlayerEnterVehicle event of race.
function CourseCheckpoint:Enter(racer)
	if
		racer.hasFinished == false and
		self:GetIsValidVehicle(racer.player:GetVehicle()) and
		racer.targetCheckpoint == self.index
	then
		-- Advance racer's checkpoint.
		racer:AdvanceCheckpoint(self.index)
		-- Call this checkpoint's actions.
		for index , functionName in ipairs(self.actions) do
			self[functionName](self , racer)
		end
	end
end

function CourseCheckpoint:MarshalForClient()
	return {
		self.position
	}
end

function CourseCheckpoint:MarshalJSON()
	local checkpoint = {}
	
	checkpoint.position = {}
	checkpoint.position.x = self.position.x
	checkpoint.position.y = self.position.y
	checkpoint.position.z = self.position.z
	checkpoint.radius = self.radius
	checkpoint.type = self.type
	checkpoint.validVehicles = self.validVehicles
	checkpoint.useIcon = self.useIcon
	checkpoint.isRespawnable = self.isRespawnable
	checkpoint.actions = self.actions
	
	return checkpoint
end
