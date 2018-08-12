local planetScanner = {}

local ore_color = {255,255,0}

function planetScanner.get_ids_in_range(range)
    local id_table = {}
    local x_init = math.floor(PositionX - range/2) 
    local x_end = math.floor(PositionX + range/2) 
    local x_scan = {}
    if x_init < 0 then 
        for i = x_init,0,1 do
            table.insert(x_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, x_end do
            table.insert(x_scan,i)
        end     
    elseif x_end > (ENV_WIDTH-1) then
        for i = x_end,ENV_WIDTH,-1 do
            table.insert(x_scan,(i-ENV_WIDTH))
        end
        for i = x_init, (ENV_WIDTH-1) do
            table.insert(x_scan,i)
        end 
    else
        for  i = x_init, x_end do 
            table.insert(x_scan,i)
        end
    end 

    local y_init = math.floor(PositionY - range/2)
    local y_end = math.floor(PositionY + range/2)
    local y_scan = {}
    if y_init < 0 then 
        for i = y_init,0,1 do
            table.insert(y_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, y_end do
            table.insert(y_scan,i)
        end     
    elseif y_end > (ENV_WIDTH-1) then
        for i = y_end,ENV_WIDTH,-1 do
            table.insert(y_scan,(i-ENV_WIDTH))
        end
        for i = y_init, (ENV_WIDTH-1) do
            table.insert(y_scan,i)
        end 
    else
        for  i = y_init, y_end do 
            table.insert(y_scan,i)
        end
    end
    
    for i=1, #x_scan do
       
        for j=1, #y_scan do
			local ids = Collision.checkPosition(x_scan[i],y_scan[j])

			for k=1, #ids do 
		    	table.insert(id_table, ids[k])
		    end
        end
	end
 
	return id_table
end

function planetScanner.get_ores_in_range(range)
    local ore_table = {}
    local x_init = math.floor(PositionX - range/2) 
    local x_end = math.floor(PositionX + range/2) 
    local x_scan = {}
    if x_init < 0 then 
        for i = x_init,0,1 do
            table.insert(x_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, x_end do
            table.insert(x_scan,i)
        end     
    elseif x_end > (ENV_WIDTH-1) then
        for i = x_end,ENV_WIDTH,-1 do
            table.insert(x_scan,(i-ENV_WIDTH))
        end
        for i = x_init, (ENV_WIDTH-1) do
            table.insert(x_scan,i)
        end 
    else
        for  i = x_init, x_end do 
            table.insert(x_scan,i)
        end
    end 

    local y_init = math.floor(PositionY - range/2)
    local y_end = math.floor(PositionY + range/2)
    local y_scan = {}
    if y_init < 0 then 
        for i = y_init,0,1 do
            table.insert(y_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, y_end do
            table.insert(y_scan,i)
        end     
    elseif y_end > (ENV_WIDTH-1) then
        for i = y_end,ENV_WIDTH,-1 do
            table.insert(y_scan,(i-ENV_WIDTH))
        end
        for i = y_init, (ENV_WIDTH-1) do
            table.insert(y_scan,i)
        end 
    else
        for  i = y_init, y_end do 
            table.insert(y_scan,i)
        end
    end
    
    for i=1, #x_scan do
       
        for j=1, #y_scan do
            if Draw.compareColor(Map.checkColor(x_scan[i], y_scan[j]), ore_color) then
                table.insert(ore_table,{x = x_scan[i],y = y_scan[j]})
            end
        end
    end
 
    return ore_table
end

return planetScanner