#!/usr/bin/env ruby 

# Find alleles with fasta file and the colony id 
allele = Allele.where("mutant_fa IS NOT NULL")

gene_info_array = [] 

# Find the rest of the information and create a json file 
allele.each do |a| 
  colony = a.colony.name

  # Find mi attempt id 
  mi = a.colony.mi_attempt

  # Find fasta sequence
  mutant_fa = a.mutant_fa

  # Find gene information 
  gene = a.gene

  # Find targeted region start and end points 
  crispr_start = mi.crisprs.minimum("start") 
  crispr_end = mi.crisprs.maximum("end")

  # Find oligo sequence 
  mutagenesis_factor_donors = MutagenesisFactor::Donor.where(mutagenesis_factor_id: mi.mutagenesis_factor_id).select("oligo_sequence_fa").first 
  if mutagenesis_factor_donors.nil? 
    oligo = nil 
  else 
    oligo = mutagenesis_factor_donors.oligo_sequence_fa 
  end

  # Find strain 
  strain = mi.blast_strain.name

  # Create hash object 
  hash_obj = { 
    "gene_marker_symbol" => gene.marker_symbol, 
    "gene_mgi_accession_id" => gene.mgi_accession_id, 
    "ensembl_ids" => gene.ensembl_ids, 
    "gene_chromosome" => gene.chr, 
    "gene_start_coord" => gene.start_coordinates, 
    "gene_end_coordinate" => gene.end_coordinates, 
    # "mutant_ref" => mi.external_ref, 
    "mutant_ref" => colony, 
    "mutant_fasta_file" => mutant_fa, 
    "targeted_region_start" => crispr_start, 
    "targeted_region_end" => crispr_end, 
    "oligos" => oligo, 
    "strain" => strain
  } 

  # Add hash object to the final array
  gene_info_array.push(hash_obj) 
end 

# Write info to a JSON file
File.open("/Users⁩/albagomez⁩/Documents⁩/iMits⁩/crisprcon_outputfiles⁩/crisprcon.json","w") do |f| 
  f.write(gene_info_array.to_json) 
end 







