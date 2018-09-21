bash_consortium = Consortium.where(:name => "BaSH").first
mrc_consortium = Consortium.where(:name => "MRC").first

gene_symbol_mrc_to_bash = [
	'Adprhl1', # OK
	'Ap3b2', # OK
	'Bdkrb1', # Has a plan from BaSH, NO ES CELL QC
	'Bud23', # Has a plan from MRC, NO ES CELL QC
	'Cacng5', # Has a plan from MRC, NO ES CELL QC
	'Cckbr', # Has a plan from MRC, NO ES CELL QC
	'Chrna5', # OK
	'Col1a2', # OK
	'Crb1', # Has a plan from MRC, NO ES CELL QC
	'Crtac1', # OK
	'Dtx1', # OK
	'Dtx2', # OK
	'Fgf4', # Has a plan from MRC, NO ES CELL QC
	'Gabra2', # Has a plan from MRC, NO ES CELL QC
	'Gch1', # OK
	'Gckr', # OK
	'Hpca', # Has a plan from MRC, NO ES CELL QC
	'Ikzf2', # Has a plan from MRC, NO ES CELL QC
	'Irs1', # OK
	'Irs2', # OK
	'Irx3', # OK
	'Kcnf1', # Has a plan from MRC, NO ES CELL QC
	'Kcnj11', # Has a plan from MRC, NO ES CELL QC ** # Has a plan from MRC, has a Phenotype Attempt but not MI Attempt **
	'Nedd1', # OK
	'Nell2', # OK
	'Nr2f6', # OK
	'P3h2', # OK
	'Pde1a', # OK
	'Senp5', # OK
	'Sez6', # OK
	'Shank3', ########
	'Slc17a7', # OK
	'Tspoap1', # Has a plan from MRC, NO ES CELL QC
	'Unc13c', # OK
	'Usp31' # OK
]

gene_symbol_mrc_to_bash.each do |this_gene_symbol|
  this_gene = Gene.where(:marker_symbol => this_gene_symbol).first
  mi_plans = MiPlan.where(:consortium_id => mrc_consortium.id, :gene_id => this_gene.id)
  if mi_plans.length == 1 
  	mi_plans[0].consortium_id = bash_consortium.id
    mi_plans[0].save!
  else
    mi_plans.each do |this_mi_plan|
      mi_attempt = MiAttempt.where(:mi_plan_id => this_mi_plan.id)
      if !mi_attempt.empty?
      	this_mi_plan.consortium_id = bash_consortium.id
      	this_mi_plan.save!
      end
    end
  end
end

# Bdkrb1
this_gene = Gene.where(:marker_symbol => 'Bdkrb1').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", bash_consortium.id, this_gene.id).destroy_all

# Bud23
this_gene = Gene.where(:marker_symbol => 'Bud23').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Cacng5
this_gene = Gene.where(:marker_symbol => 'Cacng5').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Cckbr
this_gene = Gene.where(:marker_symbol => 'Cckbr').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Crb1
this_gene = Gene.where(:marker_symbol => 'Crb1').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Fgf4
this_gene = Gene.where(:marker_symbol => 'Fgf4').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Gabra2
this_gene = Gene.where(:marker_symbol => 'Gabra2').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Hpca
this_gene = Gene.where(:marker_symbol => 'Hpca').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Ikzf2
this_gene = Gene.where(:marker_symbol => 'Ikzf2').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Kcnf1
this_gene = Gene.where(:marker_symbol => 'Kcnf1').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all

# Kcnj11 => CHECK THIS BIT, NOT SURE IF IT WORKS!!!
this_gene = Gene.where(:marker_symbol => 'Kcnj11').first

new_plan_id = nil
mi_plans_bash = MiPlan.where(:consortium_id => bash_consortium.id, :gene_id => this_gene.id)
mi_plans_bash.each do |plan_bash|
  if plan_bash.mutagenesis_via_crispr_cas9 == false
  	new_plan_id = plan_bash.id
  end
end

mi_plans_mrc = MiPlan.where(:consortium_id => mrc_consortium.id, :gene_id => this_gene.id)
mi_plans_mrc.each do |plan_mrc|
  phenotype = plan_mrc.phenotyping_productions
  phenotype.each do |phe|
	phe.mi_plan_id = new_plan_id
    phe.save!
  end
  mouse_allele = plan_mrc.mouse_allele_mods
  mouse_allele.each do |a|
    a.mi_plan_id = new_plan_id
    a.save!
  end
end

mi_plan = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all



# Tspoap1
this_gene = Gene.where(:marker_symbol => 'Tspoap1').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", mrc_consortium.id, this_gene.id).destroy_all






###########################################################

gene_symbol_bash_to_mrc = [
	'Nnt', # Has a plan from BaSH, NO ES CELL QC 
	'Spatc1l', # OK
	'Tm6sf2', # Has a plan from BaSH, NO ES CELL QC 
]

gene_symbol_bash_to_mrc.each do |this_gene_symbol|
  this_gene = Gene.where(:marker_symbol => this_gene_symbol).first
  mi_plans = MiPlan.where(:consortium_id => bash_consortium.id, :gene_id => this_gene.id)
  if mi_plans.length == 1 
  	mi_plans[0].consortium_id = mrc_consortium.id
    mi_plans[0].save!
  else
    mi_plans.each do |this_mi_plan|
      mi_attempt = MiAttempt.where(:mi_plan_id => this_mi_plan.id)
      if !mi_attempt.empty?
      	this_mi_plan.consortium_id = mrc_consortium.id
      	this_mi_plan.save!
      end
    end
  end
end

# Nnt
this_gene = Gene.where(:marker_symbol => 'Nnt').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", bash_consortium.id, this_gene.id).destroy_all

# Tm6sf2
this_gene = Gene.where(:marker_symbol => 'Tm6sf2').first
mi_plans = MiPlan.where("consortium_id = ? AND gene_id = ? AND (number_of_es_cells_starting_qc = 0 OR number_of_es_cells_starting_qc IS NULL)", bash_consortium.id, this_gene.id).destroy_all


#######################################################

# Cdh23 mark as Experimental
this_gene = Gene.where(:marker_symbol => 'Cdh23').first
mi_plans = MiPlan.where(:consortium_id => mrc_consortium.id, :gene_id => this_gene.id)
mi_plans.each do |this_mi_plan|
  mi_attempts = MiAttempt.where(:mi_plan_id => this_mi_plan.id)
  mi_attempts.each do |mi|
  	mi.experimental = true
  	mi.save!
  end
end

# Col4a5
this_gene = Gene.where(:marker_symbol => 'Col4a5').first
mi_plan = MiPlan.where(:consortium_id => bash_consortium.id, :gene_id => this_gene.id)
mi_plan.each do |p|
  p.phenotyping_productions.destroy_all
  p.mouse_allele_mods.destroy_all
  p.save!
end
















