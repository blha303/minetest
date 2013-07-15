--------------------------------------------------------------------------------
-- Generic implementation of a filter/sortable list                           --
--------------------------------------------------------------------------------
filterlist = {}

--------------------------------------------------------------------------------
function filterlist.refresh(this)
	this.m_raw_list = this.m_raw_list_fct(this.m_fetch_param)
	filterlist.process(this)
end

--------------------------------------------------------------------------------
function filterlist.create(raw_fct,compare_fct,uid_match_fct,filter_fct,fetch_param)

	assert((raw_fct ~= nil) and (type(raw_fct) == "function"))
	assert((compare_fct ~= nil) and (type(compare_fct) == "function"))
	
	local this = {}
	
	this.m_raw_list_fct  = raw_fct
	this.m_compare_fct   = compare_fct
	this.m_filter_fct    = filter_fct
	this.m_uid_match_fct = uid_match_fct
	
	this.m_filtercriteria = nil
	this.m_fetch_param = fetch_param
	
	this.m_sortmode = "none"
	this.m_sort_list = {}

	this.m_processed_list = nil
	this.m_raw_list = this.m_raw_list_fct(this.m_fetch_param)

	filterlist.process(this)
	
	return this
end

--------------------------------------------------------------------------------
function filterlist.add_sort_mechanism(this,name,fct)
	this.m_sort_list[name] = fct
end

--------------------------------------------------------------------------------
function filterlist.set_filtercriteria(this,criteria)
	if criteria == this.m_filtercriteria and
		type(criteria) ~= "table" then
		return
	end
	this.m_filtercriteria = criteria
	filterlist.process(this)
end

--------------------------------------------------------------------------------
function filterlist.get_filtercriteria(this)
	return this.m_filtercriteria
end

--------------------------------------------------------------------------------
--supported sort mode "alphabetic|none"
function filterlist.set_sortmode(this,mode)
	if (mode == this.m_sortmode) then
		return
	end
	this.m_sortmode = mode
	filterlist.process(this)
end

--------------------------------------------------------------------------------
function filterlist.get_list(this)
	return this.m_processed_list
end

--------------------------------------------------------------------------------
function filterlist.get_raw_list(this)
	return this.m_raw_list
end

--------------------------------------------------------------------------------
function filterlist.get_raw_element(this,idx)
	if type(idx) ~= "number" then
		idx = tonumber(idx)
	end
	
	if idx ~= nil and idx > 0 and idx < #this.m_raw_list then
		return this.m_raw_list[idx]
	end
	
	return nil
end

--------------------------------------------------------------------------------
function filterlist.get_engine_index(this,listindex)
	assert(this.m_processed_list ~= nil)
	
	if listindex ~= nil and listindex > 0 and
		listindex <= #this.m_processed_list then
		local entry = this.m_processed_list[listindex]
		
		for i,v in ipairs(this.m_raw_list) do
		
			if this.m_compare_fct(v,entry) then
				return i
			end
		end
	end
	
	return 0
end

--------------------------------------------------------------------------------
function filterlist.get_current_index(this,listindex)
	assert(this.m_processed_list ~= nil)
	
	if listindex ~= nil and listindex > 0 and
		listindex <= #this.m_raw_list then
		local entry = this.m_raw_list[listindex]
		
		for i,v in ipairs(this.m_processed_list) do
		
			if this.m_compare_fct(v,entry) then
				return i
			end
		end
	end
	
	return 0
end

--------------------------------------------------------------------------------
function filterlist.process(this)
	assert(this.m_raw_list ~= nil)

	if this.m_sortmode == "none" and
		this.m_filtercriteria == nil then
		this.m_processed_list = this.m_raw_list
		return
	end
	
	this.m_processed_list = {}
	
	for k,v in pairs(this.m_raw_list) do
		if this.m_filtercriteria == nil or 
			this.m_filter_fct(v,this.m_filtercriteria) then
			table.insert(this.m_processed_list,v)
		end
	end
	
	if this.m_sortmode == "none" then
		return
	end
	
	if this.m_sort_list[this.m_sortmode] ~= nil and 
		type(this.m_sort_list[this.m_sortmode]) == "function" then
		
		this.m_sort_list[this.m_sortmode](this)
	end
end

--------------------------------------------------------------------------------
function filterlist.size(this)
	if this.m_processed_list == nil then
		return 0
	end
	
	return #this.m_processed_list
end

--------------------------------------------------------------------------------
function filterlist.uid_exists_raw(this,uid)
	for i,v in ipairs(this.m_raw_list) do
		if this.m_uid_match_fct(v,uid) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
function filterlist.engine_index_by_uid(this, uid)
	local elementcount = 0
	local elementidx = 0
	for i,v in ipairs(this.m_raw_list) do
		if this.m_uid_match_fct(v,uid) then
			elementcount = elementcount +1
			elementidx = i
		end
	end
	
	
	-- If there are more elements than one with same name uid can't decide which
	-- one is meant. This shouldn't be possible but just for sure.
	if elementcount > 1 then
		elementidx=0
	end

	return elementidx
end

--------------------------------------------------------------------------------
-- COMMON helper functions                                                    --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function compare_worlds(world1,world2)

	if world1.path ~= world2.path then
		return false
	end
	
	if world1.name ~= world2.name then
		return false
	end
	
	if world1.gameid ~= world2.gameid then
		return false
	end

	return true
end

--------------------------------------------------------------------------------
function sort_worlds_alphabetic(this) 

	table.sort(this.m_processed_list, function(a, b) 
			local n1 = a.name 
			local n2 = b.name 
			local count = math.min(#n1, #n2) 
			
			for i=1,count do 
				if n1:sub(i, i):lower() < n2:sub(i, i):lower() then 
					return true 
				elseif n1:sub(i, i):lower() > n2:sub(i, i):lower() then 
					return false 
				end 
			end 
			return (#n1 <= #n2) 
		end) 
end