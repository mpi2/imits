g = Gene.where(marker_symbol: 'Mtbp').first

c = Colony.where(name: 'KBL_Mtbp_01').destroy_all
c = Colony.where(name: 'EPD0331_6_D10').destroy_all
c = Colony.where(name: 'EPD0331_6_D12').destroy_all

p = g.mi_plans

mi = MiAttempt.where(mi_plan_id: p[0].id)
mi.destroy_all

p.destroy_all


gene = Gene.where(marker_symbol:'Tspan10').first
mi_plans = gene.mi_plans
mi_plan = MiPlan.find(23577)
mi_plan.is_resolving_others = true
mi_plan.destroy

mi_plan = MiPlan.find(26530)
mi_plan.valid? #validate is the entry is correct
mi_plan.save(:validate => false)


mi_plan.force_assignment = true
mi_plan.force_assignment
mi_plan.save!
mi_plan.status.name


# mi_plan.errors.messages
# mi_plan.reload


colonies = ["MMBT", "SPNF", "ABHF", "PIKF", "NCFF", "CYBF", "MMCJ", "MLFX", "PMGL", "MMBX"]

colonies.each do |c|
  colony = Colony.find_by_name(c)
  allele = colony.alleles.first
  allele.save!
end


g = Gene.find_by_marker_symbol('Mad1l1')
pp = g.phenotyping_productions
pp_tcp = PhenotypingProduction.find(3405)
pp_tcp.is_active = false
pp_tcp.is_active
pp_tcp.save!



















