os.execute("calendar -f calendar.own -l 7")




-- Code by Oystein 
-- http://www.promixis.com/forums/showthread.php?15300-Google-Calendar-iCal-as-event-trigger

-- Lua script to get events from a Google Calender
-- Url to the ICal formated calender is given in gCalUrl


local gCalUrl = "http://www.google.com/calendar/ical/ke ..... db/basic.ics"
local gCalTimeSone = 2

local http = require("socket.http")



function gCal_GetICalData()
	local sink
    local file
    
    os.execute("calcurse -x > mycal.dat")
    
    file = "/home/eri/mycal.dat"
	sink = file:read()--http.request(gCalUrl)
	--gir.LogMessage('Http returned data', sink,1)
	return sink
end


function gCal_PhraseICalData(data)
	local CurrentBlock = "None"
	local MyEvent = {}
	local AllMyEvents = {}
	--print(data)
	local lines
	local values
	data = string.gsub(data, "\r", "")	--Remove CarageReturn
	lines = string.Split(data, "\n")
	
	for i,line in ipairs(lines) do 
		--print(line)
		values = string.Split(line, ':')
		if values[1] == "BEGIN" then
			if values[2] == "VEVENT" then
				CurrentBlock = "VEVENT"
				--print("Current Block equals VEVENT")
			end
		end
		if CurrentBlock == "VEVENT" then
			if values[1] == "DTSTART" then
				MyEvent['start'] = values[2]
			end
			if values[1] == "DTEND" then
				MyEvent['end'] = values[2]
			end
			if values[1] == "SUMMARY" then
				MyEvent['name'] = values[2]
			end
			if values[1] == "END" then
				CurrentBlock = "None"
				--table.foreach(MyEvent, print)
				table.insert(AllMyEvents, table.copy(MyEvent))
			end
		end
	end
	return AllMyEvents
end

function gCal_UTCTimePhrase(data)
	
	local MyDate = {}
	MyDate['Year'] = tonumber(string.sub(data, 1, 4))
	MyDate['Month'] = tonumber(string.sub(data, 5, 6))
	MyDate['Day'] = tonumber(string.sub(data, 7, 8))
	MyDate['Hour'] = tonumber(string.sub(data, 10, 11))
	MyDate['Minute'] = tonumber(string.sub(data, 12, 13))
	MyDate['Second'] = tonumber(string.sub(data, 14, 15))

	return date:new(MyDate)
end

function gCal_SendTrigers(MyEvents)
	local TimeDiff
	local i, MyEvent

	CurrentTimeAndDate = date:now()
	CurrentTimeAndDate.Hour = CurrentTimeAndDate.Hour - gCalTimeSone   -- Adding timesone

	

	for i, MyEvent in ipairs(MyEvents) do
		--table.foreach(MyEvent, print)
		TimeDiff = CurrentTimeAndDate - gCal_UTCTimePhrase(MyEvent['start'])
		--print(TimeDiff)
		if ((0 <= TimeDiff) and (TimeDiff < 60)) then
			gir.TriggerEventEx(MyEvent['name'], 2001, 2)
		end
		
		TimeDiff = CurrentTimeAndDate - gCal_UTCTimePhrase(MyEvent['end'])
		if ((0 <= TimeDiff) and (TimeDiff < 60)) then
			gir.TriggerEventEx(MyEvent['name'], 2001, 1)
		end
		
	end

end

function gCal_Main()
	local ICalData
	
	if gCalTimeTrigger == nil then
		gCalTimeTrigger = 0
	end

	if gCalTimeTrigger > 0 then
		gCalTimeTrigger = gCalTimeTrigger -1
	else
		gCalTimeTrigger = 20
		--Do ones in a hvile
		--print('gCal Refresh Data')
		ICalData = gCal_GetICalData()
		if ICalData then
			gCalEvents = gCal_PhraseICalData(ICalData)
		else
			print('gCal Error reading ICal data')
		end
	end
	
	--Do every time
	--print('gCal ReadTriggers')
	gCal_SendTrigers(gCalEvents)
end

thread.newthread(gCal_Main,{})

--print('gCal Finito',gCalTimeTrigger)


