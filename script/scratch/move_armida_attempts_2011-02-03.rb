DATA = {
  'MRC - Harwell-HEPD0636_8_G11-1' => 'MRC',
  'MRC - Harwell-EPD0371_2_D09-1' => 'MRC',
  'Sirt1 (B04)' => 'MRC',
  'MRC - Harwell-HEPD0636_1_D12-1' => 'MRC',
  'Mxra7-G06' => 'MRC',
  'Frs2' => 'MRC',
  'Frs2 - B06' => 'BaSH',
  'MRC - Harwell-HEPD0584_1_F05-1' => 'MRC',
  'Anp32b' => 'MRC',
  'Adcy1' => 'MRC',
  '6030458c11rik (D05)' => 'MRC',
  'Zdhhc24' => 'MRC',
  'Mapkapk2 (A02)' => 'MRC',
  'Tpcn2-E09' => 'BaSH',
  'bc029214' => 'BaSH',
  'MRC - Harwell-EPD0340_5_E07-2' => 'MRC',
  'MRC - Harwell-EPD0340_5_E07-1' => 'MRC',
  'wdr34' => 'BaSH',
  'Map3k7 - B12' => 'BaSH',
  'Cbx2' => 'BaSH',
  'EPb4.1L5 - B10 - B6J' => 'BaSH',
  'Epb4.1L5-B10-B6Alb' => 'BaSH',
  'Zcrb1-H01' => 'BaSH',
  'Grm6-G06' => 'BaSH',
  'Kcnj9' => 'BaSH',
  'P2rx4 (E09)' => 'BaSH',
  'MRC - Harwell-EPD0370_7_E10-1' => 'MRC',
  'MRC - Harwell-HEPD0634_6_C08-1' => 'MRC',
  'MRC - Harwell-HEPD0557_4_E10-1' => 'MRC',
  'MRC - Harwell-HEPD0636_6_A05-1' => 'MRC',
  'MRC - Harwell-HEPD0507_9_H02-1' => 'MRC'
}

MiAttempt.transaction do

  DATA.each do |colony_name, new_consortium_name|
    mi = MiAttempt.find_by_colony_name!(colony_name)
    old_mi_plan = mi.mi_plan
    production_centre_name = mi.mi_plan.production_centre.name
    mi.mi_plan = nil
    mi.consortium_name = new_consortium_name
    mi.production_centre_name = production_centre_name
    mi.__send__(:set_mi_plan)
    raise "Same MiPlan being assigned for #{colony_name}" if mi.mi_plan == old_mi_plan
    puts("Moving #{colony_name}(#{mi.gene.marker_symbol}) from #{old_mi_plan.consortium.name} to #{mi.mi_plan.consortium.name}")
    mi.save!
  end

  raise "ROLLBACK"
end
