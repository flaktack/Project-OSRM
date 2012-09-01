-- Begin of globals

bollards_whitelist = { [""] = true, ["cattle_grid"] = true, ["border_control"] = true, ["toll_booth"] = true, ["no"] = true}
access_tag_whitelist = { ["yes"] = true, ["train"] = true, ["vehicle"] = true, ["permissive"] = true, ["designated"] = true  }
access_tag_blacklist = { ["no"] = true, ["private"] = true, ["agricultural"] = true, ["forestery"] = true }
access_tag_restricted = { ["destination"] = true, ["delivery"] = true }
access_tags = { "train", "psv", "vehicle" }
service_tag_restricted = { ["parking_aisle"] = true }
ignore_in_grid = { ["ferry"] = true, ["pier"] = true, ["abandoned"] = true, ["disused"] = true, ["platform"] = true }

speed_profile = { 
  ["rail"] = 90, 
  ["subway"] = 60, 
  ["light_rail"] = 50, 
  ["tram"] = 40,
  ["narrow_gauge"] = 20,
  ["default"] = 50
}

discard_sharp_turns = false
take_minimum_of_speeds = true
obey_oneway = true

-- End of globals

function node_function (node)
  return 1
end

function turn_function (angle)
    return 10000*math.abs(angle)/180 -- penalty 
end

function way_function (way)
  
  -- First, get the properties of each way that we come across
    local highway = way.tags:Find("railway")
    local service = way.tags:Find("service")
    local name = way.tags:Find("name")
    local ref = way.tags:Find("ref")
    local maxspeed = parseMaxspeed(way.tags:Find ( "maxspeed") )
    local oneway = way.tags:Find("oneway")
    local area = way.tags:Find("area")
    local access = way.tags:Find("access")

  -- Second parse the way according to these properties

	if("yes" == area) then
		return 0
	end
		
  -- Check if we are allowed to access the way
    if access_tag_blacklist[access] ~=nil and access_tag_blacklist[access] then
		return 0;
    end
    
  -- Check if our vehicle types are forbidden
    for i,v in ipairs(access_tags) do 
      local mode_value = way.tags:Find(v)
      if nil ~= mode_value and "no" == mode_value then
	    return 0;
      end
    end
  
    
  -- Set the name that will be used for instructions  
	if "" ~= ref then
	  way.name = ref
	elseif "" ~= name then
	  way.name = name
	end
	
	if "roundabout" == junction then
	  way.roundabout = true;
	end
    
  -- Set the avg speed on the way if it is accessible by road class
    if (speed_profile[highway] ~= nil and way.speed == -1 ) then 
      if (0 < maxspeed and not take_minimum_of_speeds) or (maxspeed == 0) then
        maxspeed = math.huge
      end
      way.speed = math.min(speed_profile[highway], maxspeed)

      -- Service ways are 10 km/h slower
      if (20 > way.speed and service ~= nil) then
        way.speed = way.speed - 20;
      end
    end

  -- Set the avg speed on ways that are marked accessible
    if access_tag_whitelist[access]  and way.speed == -1 then
      if (0 < maxspeed and not take_minimum_of_speeds) or maxspeed == 0 then
        maxspeed = math.huge
      end
      way.speed = math.min(speed_profile["default"], maxspeed)
    end

  -- Set access restriction flag if access is allowed under certain restrictions only
    if access ~= "" and access_tag_restricted[access] then
	  way.is_access_restricted = true
    end

  -- Set access restriction flag if service is allowed under certain restrictions only
    if service ~= "" and service_tag_restricted[service] then
	  way.is_access_restricted = true
    end
    
  -- Set direction according to tags on way
    if obey_oneway then
      if oneway == "no" or oneway == "0" or oneway == "false" then
	    way.direction = Way.bidirectional
	  elseif oneway == "-1" then
	    way.direction = Way.opposite
      elseif oneway == "yes" or oneway == "1" or oneway == "true" then
		way.direction = Way.oneway
      else
        way.direction = Way.bidirectional
      end
    else
      way.direction = Way.bidirectional
    end
    
  -- Override general direction settings of there is a specific one for our mode of travel
  
    if ignore_in_grid[highway] ~= nil and ignore_in_grid[highway] then
		way.ignore_in_grid = true
  	end
  	way.type = 1
  return 1
end
