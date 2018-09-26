#!/usr/bin/env ruby 

# Find alleles with fasta file and the colony id 
# allele = Allele.where("mutant_fa IS NOT NULL").map { |a| [a.colony_id, a.mutant_fa] } 
allele = Allele.where("mutant_fa IS NOT NULL")

gene_info_array = [] 

# Find the rest of the information and create a json file 
allele.each do |a| 
  # colony_id = a[0] 
  # mutant_fa = a[1] 

  # Find mi attempt id 
  # mi_attempt_id = Colony.where(id: colony_id).select("mi_attempt_id") 

  # Find mi plan id and the external reference 
  # mi_attempt = MiAttempt.where(id: mi_attempt_id).select("mi_plan_id, external_ref, mutagenesis_factor_id, blast_strain_id").first 
  mi_attempt = a.colony.mi_attempt

  # Find gene id, return a list 
  # gene_id = MiPlan.where(id: mi_attempt.mi_plan_id).select("gene_id") 

  # Find gene information 
  # gene = Gene.where(id: gene_id).select("marker_symbol, mgi_accession_id, ensembl_ids, chr, start_coordinates, end_coordinates").first 
  gene = a.gene

  # Find targeted region start and end points 
  # crispr_start = TargRep::Crispr.where(mutagenesis_factor_id: mi_attempt.mutagenesis_factor_id).minimum("start") 
  # crispr_end = TargRep::Crispr.where(mutagenesis_factor_id: mi_attempt.mutagenesis_factor_id).maximum("end") 
  crispr_start = mi_attempt.crisprs.minimum("start") 
  crispr_end = mi_attempt.crisprs.maximum("end")

  # Find oligo sequence 
  mutagenesis_factor_donors = MutagenesisFactor::Donor.where(mutagenesis_factor_id: mi_attempt.mutagenesis_factor_id).select("oligo_sequence_fa").first 
  if mutagenesis_factor_donors.nil? 
  	oligo = nil 
  else 
  	oligo = mutagenesis_factor_donors.oligo_sequence_fa 
  end

  # Find strain 
  # strain = Strain.where(id: mi_attempt.blast_strain_id).select("name").first 
  strain = mi_attempt.blast_strain.name

  # Create hash object 
  hash_obj = { 
  	"gene_marker_symbol" => gene.marker_symbol, 
	"gene_mgi_accession_id" => gene.mgi_accession_id, 
	"ensembl_ids" => gene.ensembl_ids, 
	"gene_chromosome" => gene.chr, 
	"gene_start_coord" => gene.start_coordinates, 
	"gene_end_coordinate" => gene.end_coordinates, 
	"mutant_ref" => mi_attempt.external_ref, 
	"mutant_fasta_file" => mutant_fa, 
	"targeted_region_start" => crispr_start, 
	"targeted_region_end" => crispr_end, 
	"oligos" => oligo, 
	"strain" => strain.name 
  } 

  # Add hash object to the final array
  gene_info_array.push(hash_obj) 
end 

# Write info to a JSON file
File.open("crisprcon.json","w") do |f| 
  f.write(gene_info_array.to_json) 
end 
























