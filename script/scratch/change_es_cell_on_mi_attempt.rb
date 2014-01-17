'MANC' => ['EPD0042_1_F07', 'EPD0043_5_E04'],

centre = Centre.find_by_name('WTSI')
consortium = Consortium.find_by_name('MGP')
colony_names = {
'EUBZ' => ['EPD0162_1_C04', 'HEPD0631_5_D05'],
'MAGG' => ['EPD0028_1_G04', 'EPD0027_4_C08'],
'MAPC' => ['EPD0164_3_A09', 'EPD0164_3_H04'],
'MCAH' => ['EPD0082_3_H08', 'EPD0082_3_B07'],
'MEYW' => ['EPD0109_7_E02', 'EPD0109_7_B05'],
'MFBZ' => ['EPD0574_3_G06', 'EPD0035_2_F03'],
'MFCA' => ['EPD0035_2_F03', 'EPD0574_3_G06'],
'MFNG' => ['EPD0774_3_C05', 'EPD0660_3_A06'],
'MFPD' => ['EPD0107_1_H04', 'EPD0825_3_D07'],
'MFPE' => ['EPD0825_3_D07', 'EPD0629_3_A05'],
'MFTQ' => ['EPD0043_3_E10', 'EPD0090_4_C10'],
'MFUJ' => ['EPD0797_4_C05', 'EPD0681_3_A05']
}


ApplicationModel.audited_transaction do

colony_names.each do |colony, es_cell_name|
  mi_attempt = Public::MiAttempt.find_by_colony_name(colony)
  if !mi_attempt
    puts 'ERROR: could not find an mi_attempt with colony name #{colony}'
    next
  end
  current_gene = mi_attempt.gene

  es_cell = TargRep::EsCell.find_by_name(es_cell_name[1])
  if !es_cell
    puts "ERROR: could not find es_cell #{es_cell_name[1]}"
    next
  end
  gene = es_cell.gene

  if current_gene == gene
    if mi_attempt.es_cell.name == es_cell_name[0]
      mi_plan = mi_attempt.mi_plan
      if mi_plan.is_active == false
        mi_plan.is_active = true
        mi_plan.save
        mi_attempt.reload
      end
      mi_attempt.es_cell = es_cell
    else
      puts "ERROR mi_attempt #{mi_attempt} with colony name #{colony} has a differnt es_cell than supplied by MGP"
      next
    end
    if mi_attempt.valid?
      mi_attempt.save
    else
      puts "ERROR saving mi_attempt: #{mi_attempt.id} with colony_name: #{colony}"
      puts "#{mi_attempt.errors.messages}"
    end
    next
  end

  # find plan for new gene, consortia and production centre
  mi_plans = Public::MiPlan.find_by_sql("SELECT mi_plans.* FROM mi_plans WHERE mi_plans.consortium_id = #{consortium.id} AND mi_plans.production_centre_id = #{centre.id} AND mi_plans.gene_id = #{gene.id} AND mi_plans.phenotype_only = false")

  if mi_plans.count == 1
    puts 'REASSIGN mi_attempt'
    mi_attempt.mi_plan = mi_plans.first
    mi_attempt.es_cell = es_cell
  elsif mi_plans.count == 0
    puts 'CREATE mi_plan'
    new_plan = Public::MiPlan.new
    new_plan.gene = gene
    new_plan.consortium = consortium
    new_plan.production_centre = centre
    new_plan.priority_id = 3
    new_plan.force_assignment = true
    if new_plan.valid?
      'SAVE plan'
      new_plan.save
    else
      puts "ERROR: could not create a new mi_plan for mi_attempt #{mi_attempt} with colony name #{colony}"
      next
    end
    mi_attempt.mi_plan = new_plan
    mi_attempt.es_cell = es_cell
  else
    puts "ERROR: multiple mi_plans found for mi_attempt #{mi_attempt} with colony name #{colony}"
    next
  end

  if mi_attempt.valid?
    mi_attempt.save
  else
    puts "ERROR saving mi_attempt: #{mi_attempt.id} with colony_name: #{colony}"
    puts "#{mi_attempt.errors.messages}"
  end
end

raise 'ROLLBACK'
end
