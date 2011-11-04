# encoding: utf-8

EXCLUDE_LIST = %w{
    8615
    11072
    11061
    11060
    11036
    11066
    8682
    11086
    8610
    11116
    11089
    11077
    11418
    11051
    7899
    11035
    11044
    5403
    11063
    11115
    11032
    5437
    11085
    11065
    11030
    11058
    11047
    11087
    7531
    11039
    11038
    6459
    8619
    7916
    7544
    7562
    8667
    8666
    6334
    7855
    5890
    7884
    7875
    7854
    7951
    5544
    8681
    5912
    5578
    5447
    5615
    5609
    7644
    5584
    7898
    11289
    11782
    11820
    11812
    11821
    11822
    11830
    11823
    11832
    11836
    11834
    11844
    11850
    11981
    11986
    11982
    12318
    12344
    12400
    7955
    8618
    11076
    11080
    8625
    7731
    5271
    7688
    6451
    6437
    8640
    8659
    8643
    8635
    11088
    11042
    11098
    10352
    11037
    11101
    11040
    11033
    11102
    11064
    5580
    7378
    5614
    11814
    11815
    11826
    11835
    11839
    11838
    11837
    11846
    11848
    11859
    12670
    12316
    5227
    11057
    11056
    7917
    5934
    12807
    12832
}.map!(&:to_i)

stats = Hash.new { 0 }

mi_map = {}

Old::MiAttempt.order('id asc').all.each do |old_mi|
  old_mi_id = old_mi.id.to_i
  next if EXCLUDE_LIST.include?(old_mi_id)

  search_params = {:es_cell_name_eq => old_mi.clone.clone_name}

  new_mis =  MiAttempt.search(search_params).result
  if new_mis.size == 0
    puts "#{old_mi_id} NO NEW MIS FOR ES CELL #{old_mi.clone.clone_name}"
    next
  elsif new_mis.size == 1
    mi_map[old_mi] = new_mis.first
    next
  end

  if ! old_mi.production_centre.blank?

    old_production_centre_name = old_mi.production_centre.name
    if old_production_centre_name == 'GSF'
      old_production_centre_name = 'HMGU'
    end

    search_params[:mi_plan_production_centre_name_eq] = old_production_centre_name
  end

  if !old_mi.colony_name.blank?
    search_params[:colony_name_eq] = old_mi.colony_name
  end

  #if ! old_mi.actual_mi_date.blank?
  #  search_params[:mi_date_eq] = old_mi.actual_mi_date.to_date
  #end

  new_mis = MiAttempt.search(search_params).result
  #new_mis = MiAttempt.search(:es_cell_name_eq => old_mi.clone.clone_name, :mi_date_eq => old_mi.actual_mi_date.to_date).result

  if new_mis.size == 0
    puts "#{old_mi_id} NO NEW MIS FOUND"
    stats[:no_new_mis_found] += 1
  elsif new_mis.size != 1
    puts "#{old_mi_id} MULTIPLE NEW MIS FOUND MATCHING"
    stats[:multiple_new_mis_found] += 1
  else
    mi_map[old_mi] = new_mis.first
    next
  end
end

y stats
