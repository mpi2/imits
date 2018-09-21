this_gene = Gene.where(:marker_symbol => 'Togaram1').first
jax_consortium = Consortium.where(:name => "JAX").first
bash_consortium = Consortium.where(:name => "BaSH").first

mi = this_gene.mi_attempts
p = this_gene.mi_plans
p_bash = p.find_by_consortium_id(4)
mi_jax = p_bash.mi_attempts.find_by_external_ref('Togaram1_115229')
mi_jax.mi_plan_id
mi_jax.mi_plan_id = 26898
mi_jax.mi_plan_id


#####################################################################################

g = Gene.where(:marker_symbol => 'Pcif1').first
bash_consortium = Consortium.where(:name => "BaSH").first

p = g.mi_plans.where(consortium_id: bash_consortium.id)
p_del = p.where(consortium_id: bash_consortium.id, mutagenesis_via_crispr_cas9: false).first

p_del.phenotyping_productions
p_del.phenotyping_productions.destroy_all

p_del.mouse_allele_mods
p_del.mouse_allele_mods.destroy_all

mi = p_del.mi_attempts.first
c = Colony.find_by_mi_attempt_id(mi.id)
c.destroy
p_del.mi_attempts.destroy_all

p_del.destroy

#####################################################################################

hmgu_centre = Centre.where(:name => 'HMGU').first
col = Colony.find_by_name('INFRA-16429A-D1-1-1')
p = col.mi_plan
p.production_centre_id = hmgu_centre.id
p.save!

#####################################################################################

g = Gene.find_by_marker_symbol('Ndufb4')
alleles = g.allele
alleles.each do |a|
  a.save!
end

c = Colony.find_by_name('PMGE')
alleles = c.alleles
alleles.each do |a|
  a.save!
end

#####################################################################################

g = Gene.find_by_marker_symbol('Tas2r139')
bash_consortium = Consortium.where(:name => "BaSH").first
p = g.mi_plans.where(:consortium_id => bash_consortium.id)
p.each do |plan|
  plan.is_active = true
  plan.save!
end

g = Gene.find_by_marker_symbol('Akt1s1')
bash_consortium = Consortium.where(:name => "BaSH").first
p = g.mi_plans.where(:consortium_id => bash_consortium.id, :mutagenesis_via_crispr_cas9 => true)
p.each do |plan|
  plan.is_active = true
  plan.save!
end



















