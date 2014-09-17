#!/usr/bin/env ruby

require 'pp'

mgis = %W{
  MGI:1917237
  MGI:1915134
  MGI:1919862
  MGI:2441745
  MGI:88042
  MGI:3044626
  MGI:88158
  MGI:99495
  MGI:1859549
  MGI:1921703
  MGI:2446120
  MGI:2147298
  MGI:1858223
  MGI:1354756
  MGI:1339752
  MGI:2137383
  MGI:1919304
  MGI:94872
  MGI:1196287
  MGI:94900
  MGI:1913719
  MGI:95514
  MGI:109374
  MGI:1858901
  MGI:2429943
  MGI:1338001
  MGI:3647683
  MGI:1353651
  MGI:109255
  MGI:96012
  MGI:2384589
  MGI:99894
  MGI:1924082
  MGI:96397
  MGI:1933382
  MGI:1929612
  MGI:1333831
  MGI:1921408
  MGI:1343094
  MGI:1202398
  MGI:2444786
  MGI:1343166
  MGI:2684762
  MGI:2147583
  MGI:1333811
  MGI:96924
  MGI:1917458
  MGI:1859396
  MGI:1858271
  MGI:2676278
  MGI:2444343
  MGI:2384588
  MGI:2158505
  MGI:107374
  MGI:109211
  MGI:1923759
  MGI:2652890
  MGI:98858
  MGI:1913129
  MGI:2443235
  MGI:1933159
  MGI:1919443
  MGI:98280
  MGI:1922075
  MGI:1860267
  MGI:2145895
  MGI:1919247
  MGI:2144471
  MGI:1913311
  MGI:107914
  MGI:3045226
  MGI:98780
  MGI:106657
  MGI:2137352
  MGI:1927616
  MGI:1921855
  MGI:1355274
  MGI:98912
  MGI:2140882
  MGI:1341292
  MGI:2385198
  MGI:1918722
  MGI:2442483
  MGI:1917925
  MGI:2655768
  MGI:1917140
  MGI:1920701
  MGI:1923257
}

#Currently LIMS2 records 88 mouse genes in the “MGP Recovery” basket.
#I need you two to cooperate to
#
#1) get the marker symbols for these genes
#
#2) make crispr-based MI Plans in iMITS for each of these genes, for consortium = BaSH, production centre = WTSI. The “mutagenesis via crispr cas9” flag has to be set => true for these plans, that’s the whole point. There will already be a couple of plans in there for WTSI with this flag checked.
#
#I think Saj can get Richard the list of plans (part 1). I think Richard can script the creation of the plans (part 2). Can you ticket this, and let’s see if it can be done this week? It’s an iMITS task, I guess.

counter = 0
verbose = true
missing = []
debug = false
plan_ids_old = []
plan_ids_new = []

plans_old = []
plans_new = []

ApplicationModel.audited_transaction do

  mgis.each do |mgi|
    gene = Gene.find_by_mgi_accession_id mgi

    if ! gene
      puts "#### cannot find '#{mgi}'" if verbose
      missing.push mgi
      next
    end

    plan_params = {
      :consortium_id => Consortium.find_by_name!('BaSH').id,
      :production_centre_id => Centre.find_by_name!('WTSI').id,
      :gene_id => gene.id,
      #  :status => MiPlan::Status[:Assigned],
      # :priority => MiPlan::Priority.find_by_name!(:High),
      :mutagenesis_via_crispr_cas9 => true
    }

    plan = MiPlan.where(plan_params).first

    if plan
      puts "#### exists '#{mgi}'"
      plan_ids_old.push plan.id
      plans_old.push plan
      #puts plan.to_json(:include => {:gene => {}})
    else
      plan = MiPlan.create!(plan_params)
      # puts plan.to_json
      plan_ids_new.push plan.id
      plans_new.push plan
    end

    # puts "#### found '#{mgi}'" if verbose
    counter += 1
  end

  if counter != mgis.length
    raise "#### unequal counts!"

    pp missing
  end

  puts "#### old:"
  pp plan_ids_old

  #plans_old.each do |p|
  #  puts p.to_json(:include => {:gene => {}})
  #end

  puts "#### new:"
  pp plan_ids_new

  #plans_new.each do |p|
  #  puts p.to_json(:include => {:gene => {}})
  #end

  (plan_ids_old + plan_ids_new).each do |id|
    MiPlan.find id
  end

  raise "rollback!" if debug

  puts "done!"

end
