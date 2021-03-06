
r1 = File.open('mmrrc_1_strain_data.tsv','w')
r2 = File.open('mmrrc_2_strain_alteration.tsv','w')
r3 = File.open('mmrrc_3_locus_data.tsv','w')
r4 = File.open('mmrrc_4_sds_data.tsv','w')

mmrrc_centres = MiAttempt::DistributionCentre.where(:distribution_network=>"MMRRC");

r1.write "mmrrc_id\tallele_symbol\tgenetic_founder_background_strain\tcurrent_background_strain\tclone\tresearch_area\thuman_disease_models\n"
r2.write "mmrrc_id\tmmrrc_strain_nomenclature\talteration\tes_cell_line\n"
r3.write "mmrrc_id\tmgi_gene_symbol\tmgi_allele_id\talteration_at_locus\talteration_description\tlocus_allele\tspecies\tgene\tmgi_gene_id\tchromosome\n"
r4.write "colony_name}\tmmrrc_strain_nomenclature\tcommon_strain_name\tgenetic_alterations\tbackcross_generation\tinterbreeding_generation\tmouse_strain_development\tmouse_strain_control\tphenotype_reference\tphenotype_of_het_hemi_mutants\tcoat_colour\tphysical_characteristics\tdonor_primary_reference\tdonor_primary_reference_url\tresearch_applications\tbreeding_system\tbreeding_schemes\n"

mmrrc_centres.each do |mi_dcentre|

	mi = mi_dcentre.mi_attempt

	#report 1
	colony_name = mi.colony_name
	marker_symbol = mi.mi_plan.gene.marker_symbol
	allele_symbol = mi.allele_symbol
	genetic_founder_background_strain = mi.es_cell.strain
	current_background_strain = mi.colony_background_strain.name
	clone = mi.es_cell.name
	research_area = ''
	human_disease_models = ''

	#r2
	alteration = mi.es_cell.allele.mutation_type.name
	if alteration == 'Conditional Ready'
		alteration = 'Knockout First'
	end
	puts "#{mi.es_cell.name} --- #{alteration}"
	if(mi.mouse_allele_type == 'e')
		alteration = 'Targeted NonConditional'	
	end
	parental_cell_line = mi.es_cell.parental_cell_line

	#r3
	chromosome = mi.es_cell.allele.chromosome
	mgi_accession_id= mi.mi_plan.gene.mgi_accession_id
	mgi_allele_id = mi.mi_plan.gene.mgi_accession_id
	# this is going to fail for crisprs - have to rework to go via mutagenesis factor, 
	# OR it could be stamped directly on the MI (best idea ...)
	allele_mgi_allele_id = mi.es_cell.mgi_allele_id

	#r4
	mmrrc_strain_nomenclature = "#{mi.colony_background_strain.name} - #{allele_symbol}"
	common_strain_name = ''

	cassette_start = mi.es_cell.allele.cassette_start 
	loxp_start = mi.es_cell.allele.loxp_start 
	cassette_name = mi.es_cell.allele.cassette

	ikmc_project_id = mi.es_cell.ikmc_project_id
	genetic_alterations = 
		"cassette #{cassette_name} inserted at chromosome #{chromosome} position #{cassette_start}. LoxP site at position #{loxp_start}. mutation is #{alteration}. Details page at www.mousephenotype.org/martsearch_ikmc_project/martsearch/ikmc_project/#{ikmc_project_id}"

	blast_strain = mi.blast_strain.name
	test_strain = mi.test_cross_strain.name
	interbreeding_generation = ""
	backcross_generation = ""
	bg_strain = mi.colony_background_strain.name
	mouse_strain_development="ES cell clone #{clone} was injected into #{blast_strain} blastocysts. Resulting chimeras were mated to #{test_strain}, progeny were subsequently mated to #{bg_strain}"
	mouse_strain_control = ''
	phenotype_reference = "http://www.mousephenotype.org/data/genes/#{mgi_accession_id}"
	phenotype_of_het_hemi_mutants = ''
	coat_colour = 'black'
	if(mi.es_cell.strain.include? 'A')
		coat_colour = 'agouti and black'
	end
	physical_characteristics = ''
	donor_primary_reference = 'Skarnes WC, Rosen B, West AP, Koutsourakis M, Bushell W, Iyer V, Mujica AO, Thomas M, Harrow J, Cox T, Jackson D, Severin J, Biggs P, Fu J, Nefedov M, de Jong PJ, Stewart AF, Bradley A.&nbsp;A conditional knockout resource for the genome-wide study of mouse gene function. Nature, 2011, 474 (7351) 337-42.'
	donor_primary_reference_url = 'http://www.ncbi.nlm.nih.gov/pubmed/21677750?dopt=Abstract'
	research_applications = ""
	breeding_system = "Intra-strain Random Mating"
	breeding_schemes = "Wild-type female x Heterozygous male from the colony or reciprocal mating"

	r1.write "#{colony_name}\t#{allele_symbol}\t#{genetic_founder_background_strain}\t#{current_background_strain}\t#{clone}\t#{research_area}\t#{human_disease_models}\n"

	r2.write "#{colony_name}\t#{allele_symbol}\t#{alteration}\t#{parental_cell_line}\n"

	r3.write "#{colony_name}\t#{marker_symbol}\t#{mgi_allele_id}\t\t\t\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tGene\n"
	r3.write "#{colony_name}\t#{allele_symbol}\t#{allele_mgi_allele_id}\t#{alteration}\t#{clone}\t#{allele_symbol}\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tAllele\n"

	r4.write "#{colony_name}\t#{mmrrc_strain_nomenclature}\t#{common_strain_name}\t#{genetic_alterations}\t#{backcross_generation}\t#{interbreeding_generation}\t#{mouse_strain_development}\t#{mouse_strain_control}\t#{phenotype_reference}\t#{phenotype_of_het_hemi_mutants}\t#{coat_colour}\t#{physical_characteristics}\t#{donor_primary_reference}\t#{donor_primary_reference_url}\t#{research_applications}\t#{breeding_system}\t#{breeding_schemes}\n"

end

r1.close
r2.close
r3.close
r4.close
