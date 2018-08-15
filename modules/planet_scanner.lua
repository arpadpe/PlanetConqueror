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
    local ore_found = {}
    local x_init = math.floor(PositionX - range/2) 
    local x_end = math.floor(PositionX + range/2) 
    local y_init =  math.floor(PositionY - range/2)
    local y_end = math.floor(PositionY + range/2)

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
   -- l_print("size x_scan "..#x_scan.." Size y_scan "..#y_scan)

    total_ores = 0 
        for i=1, #x_scan do
            for j=1, #y_scan do

                if Draw.compareColor(Map.checkColor(x_scan[i],y_scan[j]),ore_color) then
                    table.insert(ore_found,{x = x_scan[i],y = y_scan[j]})
                    
                  --  l_print("ore found: "..x_scan[i].." "..y_scan[j])
                    total_ores = total_ores + 1 
                end
            end
        end
        -- GET NUMBER OF PACKAGES 

        if get_number_packages then
            if total_ores%MemorySize == 0 then --exact number of packages
                total_number_packages = total_ores/MemorySize
            --[[else 
                total_number_packages = math.floor(#ore_table/MemorySize)]]
               -- l_print("total number packages "..total_ores/MemorySize)
            end 
           -- say("get numbr packages")
            get_number_packages = false
        end
       -- RETURN ORE FOUND IN MEMORY SIZE SLOTS
        
        if #ore_found <= MemorySize and #ore_found ~= 0 then 
          --  l_print(" we have plenty of memory")
            last_package_sent = true
            return ore_found
        elseif #ore_send == 0 and #ore_found ~= 0 then 
          --  l_print("first time we sent things ") 
            for i = 1 , MemorySize do 
                table.insert(ore_send, ore_found[i])
            end 
            count_packages = count_packages + 1 
            return ore_send
        elseif #ore_send ~= 0 and #ore_found ~= 0 then
            index_list = {}
         --   l_print("sedond time we sent things")
        
            for i = 1 , MemorySize do 
                for j = #ore_found, 1, -1 do
                    if ore_found[j]~= nil and ore_send[i] ~= nil then 
                        if ore_send[i].x == ore_found[j].x and ore_send[i].y ==ore_found[j].y then 
                        table.insert(index_list, j)
                        -- l_print("j value scanning  "..j)
                        end
                    end
                end

            end

            max_index = math.max(unpack(index_list))
           -- l_print("max index "..max_index)
            index_list = nil
            
            
           --l_print("remainings "..(#ore_found - max_index))
            if (#ore_found - max_index) < MemorySize then 
                for i = MemorySize, (#ore_found - max_index)+1, -1 do
                    ore_send[i]=nil --table.remove(ore_send,i)
                end
                for i = 1, (#ore_found - max_index) do     
                    ore_send[i].x = ore_found[max_index + i].x
                    ore_send[i].y = ore_found[max_index + i].y
                end 
                last_package_sent = true
            else

                for i = 1, MemorySize do
                    if ore_send[i] ~= nil then 
                    ore_send[i].x = ore_found[max_index + i].x
                    ore_send[i].y = ore_found[max_index + i].y
                    end

                end

                count_packages = count_packages + 1 
                if count_packages ==total_number_packages then 
                    last_package_sent = true 
                end



            end
            return ore_send
        end
        


end

return planetScanner