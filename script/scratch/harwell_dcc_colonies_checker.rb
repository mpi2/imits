

colonies_not_found_at_all = []
colonies_found = []

colonies.each do |name|
  c = PhenotypingProduction.where('lower(colony_name) = ?', name.downcase)
  if c.blank?
    colonies_not_found_at_all.push(name)
  else
    colonies_found.push(name)
  end
end

colonies_not_found2 = []
colonies_found2 = []

colonies.each do |name|
  c = PhenotypingProduction.find_by_colony_name(name)
  if c.blank?
    colonies_not_found2.push(name)
  else
    colonies_found2.push(name)
  end
end

colonies_not_found_case_sensitive = []
colonies_not_found_case_sensitive = colonies_not_found2 - colonies_not_found_at_all
colonies_found3 = []

colonies_not_found_case_sensitive.each do |name|
  c = PhenotypingProduction.where('lower(colony_name) = ?', name.downcase)
  colonies_found3.push([name, c[0].colony_name])
end





