misspelt_strain_id = Strain.find_by_name('C57BL6/NCrl').id

mi_attempts = MiAttempt.where(:blast_strain_id => misspelt_strain_id).map{ |mi| mi.id }

correct_strain_id = Strain.find_by_name("C57BL/6NCrl").id
mi_attempts_inactive = Array.new

mi_attempts.each do |mi_id|
  mi = MiAttempt.find(mi_id)
  begin
	  mi.blast_strain_id = correct_strain_id
	  mi.save!
  rescue
    mi_attempts_inactive.push(mi_id)
  end
end

mi_attempts_inactive_2 = Array.new

mi_attempts_inactive.each do |mi_id|
  mi = MiAttempt.find(mi_id)
  p = mi.mi_plan
  if !p.is_active?
    p.is_active = true
    p.save!
    mi.blast_strain_id = correct_strain_id
    mi.save!
    p.is_active = false
    p.save!
  else
    mi_attempts_inactive_2.push(mi_id)
  end
end

mi_attempts.count

mi_attempts_inactive.count

mi_attempts_inactive_2.count

# {:id=>20, :name=>"C57BL6/NCrl", :mgi_strain_accession_id=>nil, :mgi_strain_name=>nil, :background_strain=>true, :test_cross_strain=>true, :blast_strain=>true},