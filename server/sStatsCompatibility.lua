----------------------------------------------------------------------------------------------------
-- Manages backward compatibility. If a database from an old Racing version is loaded, it is
-- converted to use the new version. In theory, /all/ database versions are backwards compatible.
----------------------------------------------------------------------------------------------------

Stats.UpdateFromOldVersion = function(version)
	print("Updating database...")
	local timer = Timer()
	
	-- This is /the entire database/ marshalled into a table.
	local database = {}
	database.RacePlayers = SQL:Query("select * from RacePlayers"):Execute()
	database.RaceResults = SQL:Query("select * from RaceResults"):Execute()
	database.RaceCourses = SQL:Query("select * from RaceCourses"):Execute()
	
	if version == 0 then
		Stats.UpdateFromV0(database)
		version = 1
	end
	if version == 1 then
		Stats.UpdateFromV1(database)
		version = 2
	end
	
	print(".")
	
	-- Drop all tables.
	local transaction = SQL:Transaction()
	SQL:Execute("drop table if exists RacePlayers")
	SQL:Execute("drop table if exists RaceResults")
	SQL:Execute("drop table if exists RaceCourses")
	SQL:Execute("drop table if exists RaceVersion")
	transaction:Commit()
	
	print(".")
	
	-- Recreate the database.
	
	Stats.CreateTables()
	
	local transaction = SQL:Transaction()
	
	-- RacePlayers
	for index , racePlayer in ipairs(database.RacePlayers) do
		local command = SQL:Command("insert into RacePlayers values(?,?,?,?,?,?)")
		command:Bind(1 , racePlayer.SteamId)
		command:Bind(2 , racePlayer.Name)
		command:Bind(3 , racePlayer.PlayTime)
		command:Bind(4 , racePlayer.Starts)
		command:Bind(5 , racePlayer.Finishes)
		command:Bind(6 , racePlayer.Wins)
		command:Execute()
	end
	print(".")
	-- RaceResults
	for index , raceResult in ipairs(database.RaceResults) do
		local command = SQL:Command(
			"insert into RaceResults(SteamId , Place , CourseFileNameHash , Vehicle , BestTime) "..
			"values(?,?,?,?,?)"
		)
		command:Bind(1 , raceResult.SteamId)
		command:Bind(2 , raceResult.Place)
		command:Bind(3 , raceResult.CourseFileNameHash)
		command:Bind(4 , raceResult.Vehicle)
		command:Bind(5 , raceResult.BestTime)
		command:Execute()
	end
	print(".")
	-- RaceCourses
	for index , raceCourse in ipairs(database.RaceCourses) do
		local command = SQL:Command(
			"insert into RaceCourses values(?,?,?,?,?)"
		)
		command:Bind(1 , raceCourse.FileNameHash)
		command:Bind(2 , raceCourse.Name)
		command:Bind(3 , raceCourse.TimesPlayed)
		command:Bind(4 , raceCourse.VotesUp)
		command:Bind(5 , raceCourse.VotesDown)
		command:Execute()
	end
	
	print(".")
	
	transaction:Commit()
	
	print("Done. Time elapsed: "..string.format("%.3f" , timer:GetSeconds()).." seconds")
end

Stats.UpdateFromV0 = function(database)
	for index , racePlayer in ipairs(database.RacePlayers) do
		racePlayer.PlayTime = racePlayer.Playtime
		racePlayer.Playtime = nil
	end
end

Stats.UpdateFromV1 = function(database)
	for index , racePlayer in ipairs(database.RacePlayers) do
		local starts = 0
		local finishes = 0
		local wins = 0
		
		local query = SQL:Query("select Place from RaceResults where SteamId = (?)")
		query:Bind(1 , racePlayer.SteamId)
		local results = query:Execute()
		
		starts = #results
		
		for index , result in ipairs(results) do
			if tonumber(result.Place) >= 1 then
				finishes = finishes + 1
			end
			if tonumber(result.Place) == 1 then
				wins = wins + 1
			end
		end
		
		racePlayer.Starts = starts
		racePlayer.Finishes = finishes
		racePlayer.Wins = wins
	end
end
