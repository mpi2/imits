require 'pp'

class MmrrcOriginal
  def run
    r1 = File.open('mmrrc_1_strain_data.tsv','w')
    r2 = File.open('mmrrc_2_strain_alteration.tsv','w')
    r3 = File.open('mmrrc_3_locus_data.tsv','w')
    r4 = File.open('mmrrc_4_sds_data.tsv','w')

    mmrrc_centres = Colony::DistributionCentre.joins(:colony).where("colony_distribution_centres.distribution_network = 'MMRRC' AND colonies.mi_attempt_id IS NOT NULL");

    r1.write "mmrrc_id\tallele_symbol\tgenetic_founder_background_strain\tcurrent_background_strain\tclone\tresearch_area\thuman_disease_models\n"
    r2.write "mmrrc_id\tmmrrc_strain_nomenclature\talteration\tes_cell_line\n"
    r3.write "mmrrc_id\tmgi_gene_symbol\tmgi_allele_id\talteration_at_locus\talteration_description\tlocus_allele\tspecies\tgene\tmgi_gene_id\tchromosome\n"
    r4.write "colony_name\tmmrrc_strain_nomenclature\tcommon_strain_name\tgenetic_alterations\tbackcross_generation\tinterbreeding_generation\tmouse_strain_development\tmouse_strain_control\tphenotype_reference\tphenotype_of_het_hemi_mutants\tcoat_colour\tphysical_characteristics\tdonor_primary_reference\tdonor_primary_reference_url\tresearch_applications\tbreeding_system\tbreeding_schemes\n"

    mmrrc_centres.each do |mi_dcentre|

      col = mi_dcentre.colony
      mi = col.mi_attempt

      next if mi.blank? || mi.es_cell.blank?

      es_cell = mi.es_cell
      gene = mi.mi_plan.gene

      #report 1
      colony_name = col.name
      marker_symbol = gene.marker_symbol
      allele_symbol = col.allele_symbol
      allele_name = allele_symbol.match("<sup>(.*)</sup>")[1]
      genetic_founder_background_strain = es_cell.strain
      current_background_strain = col.background_strain_name
      clone = es_cell.name
      research_area = ''
      human_disease_models = ''

      #r2
      alteration = es_cell.allele.mutation_type.name
      if alteration == 'Conditional Ready'
        alteration = 'Knockout First'
      end
      puts "#{es_cell.name} --- #{alteration}"
      if(col.allele_type == 'e')
        alteration = 'Targeted NonConditional'
      end
      if(col.allele_type == 'a')
        alteration = 'Knockout First'
      end
      parental_cell_line = es_cell.parental_cell_line

      #r3
      chromosome = gene.chr
      mgi_accession_id= gene.mgi_accession_id
      mgi_allele_id = gene.mgi_accession_id
      # this is going to fail for crisprs - have to rework to go via mutagenesis factor,
      # OR it could be stamped directly on the MI (best idea ...)
      allele_mgi_allele_id = col.mgi_allele_id.blank? ? mi.es_cell.mgi_allele_id : col.mgi_allele_id

      #r4
      mmrrc_strain_nomenclature = "#{current_background_strain} - #{allele_symbol}"
      common_strain_name = ''

      cassette_start = es_cell.cassette_start
      loxp_start = es_cell.allele.loxp_start
      cassette_name = es_cell.allele.cassette

      ikmc_project_id = es_cell.ikmc_project_id
      genetic_alterations =
      "cassette #{cassette_name} inserted at chromosome #{chromosome} position #{cassette_start}. LoxP site at position #{loxp_start}. mutation is #{alteration}. Details page at https://www.mousephenotype.org/data/alleles/#{mgi_accession_id}/#{allele_name}"

      blast_strain = mi.blast_strain_name
      test_strain = mi.test_cross_strain_name
      interbreeding_generation = ""
      backcross_generation = ""
      bg_strain = current_background_strain
      mouse_strain_development="ES cell clone #{clone} was injected into #{blast_strain} blastocysts. Resulting chimeras were mated to #{test_strain}, progeny were subsequently mated to #{bg_strain}"
      mouse_strain_control = ''
      phenotype_reference = "http://www.mousephenotype.org/data/genes/#{mgi_accession_id}"
      phenotype_of_het_hemi_mutants = ''
      coat_colour = 'black'
      if(es_cell.strain.include? 'A')
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
  end
end

class MmrrcNew
  FOLDER = "#{Rails.root}/tmp/mmrrc"

  def run
    hash = {}

    #r1 = File.open('mmrrc_1_strain_data.tsv','w')
    #r2 = File.open('mmrrc_2_strain_alteration.tsv','w')
    #r3 = File.open('mmrrc_3_locus_data.tsv','w')
    #r4 = File.open('mmrrc_4_sds_data.tsv','w')

    mmrrc_centres = Colony::DistributionCentre.joins(:colony).where("colony_distribution_centres.distribution_network = 'MMRRC' AND colonies.mi_attempt_id IS NOT NULL");

    #r1.write "production_centre\tmmrrc_id\tallele_symbol\tgenetic_founder_background_strain\tcurrent_background_strain\tclone\tresearch_area\thuman_disease_models\n"
    #r2.write "production_centre\tmmrrc_id\tmmrrc_strain_nomenclature\talteration\tes_cell_line\n"
    #r3.write "production_centre\tmmrrc_id\tmgi_gene_symbol\tmgi_allele_id\talteration_at_locus\talteration_description\tlocus_allele\tspecies\tgene\tmgi_gene_id\tchromosome\n"
    #r4.write "production_centre\tcolony_name\tmmrrc_strain_nomenclature\tcommon_strain_name\tgenetic_alterations\tbackcross_generation\tinterbreeding_generation\tmouse_strain_development\tmouse_strain_control\tphenotype_reference\tphenotype_of_het_hemi_mutants\tcoat_colour\tphysical_characteristics\tdonor_primary_reference\tdonor_primary_reference_url\tresearch_applications\tbreeding_system\tbreeding_schemes\n"

    mmrrc_centres.each do |mi_dcentre|
      col = mi_dcentre.colony
      mi = col.mi_attempt

      next if mi.blank? || mi.es_cell.blank?

      es_cell = mi.es_cell
      gene = mi.mi_plan.gene

      production_centre = mi.production_centre.name

      #report 1
      colony_name = col.name
      marker_symbol = gene.marker_symbol
      allele_symbol = col.allele_symbol
      allele_name = allele_symbol.blank? ? '' : allele_symbol.match("<sup>(.*)</sup>")[1]
      genetic_founder_background_strain = es_cell.strain
      current_background_strain = col.background_strain_name
      clone = es_cell.name
      research_area = ''
      human_disease_models = ''

      #r2
      alteration = es_cell.allele.mutation_type.name
      if alteration == 'Conditional Ready'
        alteration = 'Knockout First'
      end
      puts "#{es_cell.name} --- #{alteration}"
      if(col.allele_type == 'e')
        alteration = 'Targeted NonConditional'
      end
      if(col.allele_type == 'a')
        alteration = 'Knockout First'
      end
      parental_cell_line = es_cell.parental_cell_line

      #r3
      chromosome = gene.chr
      mgi_accession_id= gene.mgi_accession_id
      mgi_allele_id = gene.mgi_accession_id
      # this is going to fail for crisprs - have to rework to go via mutagenesis factor,
      # OR it could be stamped directly on the MI (best idea ...)
      allele_mgi_allele_id = col.mgi_allele_id.blank? ? mi.es_cell.mgi_allele_id : col.mgi_allele_id

      #r4
      mmrrc_strain_nomenclature = "#{current_background_strain} - #{allele_symbol}"
      common_strain_name = ''

      cassette_start = es_cell.allele.cassette_start
      loxp_start = es_cell.allele.loxp_start
      cassette_name = es_cell.allele.cassette

      ikmc_project_id = es_cell.ikmc_project_id
      genetic_alterations =
      "cassette #{cassette_name} inserted at chromosome #{chromosome} position #{cassette_start}. LoxP site at position #{loxp_start}. mutation is #{alteration}. Details page at https://www.mousephenotype.org/data/alleles/#{mgi_accession_id}/#{allele_name}"

      blast_strain = mi.blast_strain_name
      test_strain = mi.test_cross_strain_name
      interbreeding_generation = ""
      backcross_generation = ""
      bg_strain = current_background_strain
      mouse_strain_development="ES cell clone #{clone} was injected into #{blast_strain} blastocysts. Resulting chimeras were mated to #{test_strain}, progeny were subsequently mated to #{bg_strain}"
      mouse_strain_control = ''
      phenotype_reference = "http://www.mousephenotype.org/data/genes/#{mgi_accession_id}"
      phenotype_of_het_hemi_mutants = ''
      coat_colour = 'black'
      if(es_cell.strain.include? 'A')
        coat_colour = 'agouti and black'
      end
      physical_characteristics = ''
      donor_primary_reference = 'Skarnes WC, Rosen B, West AP, Koutsourakis M, Bushell W, Iyer V, Mujica AO, Thomas M, Harrow J, Cox T, Jackson D, Severin J, Biggs P, Fu J, Nefedov M, de Jong PJ, Stewart AF, Bradley A.&nbsp;A conditional knockout resource for the genome-wide study of mouse gene function. Nature, 2011, 474 (7351) 337-42.'
      donor_primary_reference_url = 'http://www.ncbi.nlm.nih.gov/pubmed/21677750?dopt=Abstract'
      research_applications = ""
      breeding_system = "Intra-strain Random Mating"
      breeding_schemes = "Wild-type female x Heterozygous male from the colony or reciprocal mating"

      hash[1] ||= {}; hash[1]['All'] ||= []
      hash[2] ||= {}; hash[2]['All'] ||= []
      hash[3] ||= {}; hash[3]['All'] ||= []
      hash[4] ||= {}; hash[4]['All'] ||= []

      hash[1] ||= {}; hash[1][production_centre] ||= []
      hash[2] ||= {}; hash[2][production_centre] ||= []
      hash[3] ||= {}; hash[3][production_centre] ||= []
      hash[4] ||= {}; hash[4][production_centre] ||= []



      hash[1]['All'].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{genetic_founder_background_strain}\t#{current_background_strain}\t#{clone}\t#{research_area}\t#{human_disease_models}\n"

      hash[2]['All'].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{alteration}\t#{parental_cell_line}\n"

      hash[3]['All'].push "#{production_centre}\t#{colony_name}\t#{marker_symbol}\t#{mgi_allele_id}\t\t\t\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tGene\n"
      hash[3]['All'].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{allele_mgi_allele_id}\t#{alteration}\t#{clone}\t#{allele_symbol}\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tAllele\n"

      hash[4]['All' ].push "#{production_centre}\t#{colony_name}\t#{mmrrc_strain_nomenclature}\t#{common_strain_name}\t#{genetic_alterations}\t#{backcross_generation}\t#{interbreeding_generation}\t#{mouse_strain_development}\t#{mouse_strain_control}\t#{phenotype_reference}\t#{phenotype_of_het_hemi_mutants}\t#{coat_colour}\t#{physical_characteristics}\t#{donor_primary_reference}\t#{donor_primary_reference_url}\t#{research_applications}\t#{breeding_system}\t#{breeding_schemes}\n"



      hash[1][production_centre].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{genetic_founder_background_strain}\t#{current_background_strain}\t#{clone}\t#{research_area}\t#{human_disease_models}\n"

      hash[2][production_centre].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{alteration}\t#{parental_cell_line}\n"

      hash[3][production_centre].push "#{production_centre}\t#{colony_name}\t#{marker_symbol}\t#{mgi_allele_id}\t\t\t\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tGene\n"
      hash[3][production_centre].push "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{allele_mgi_allele_id}\t#{alteration}\t#{clone}\t#{allele_symbol}\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tAllele\n"

      hash[4][production_centre].push "#{production_centre}\t#{colony_name}\t#{mmrrc_strain_nomenclature}\t#{common_strain_name}\t#{genetic_alterations}\t#{backcross_generation}\t#{interbreeding_generation}\t#{mouse_strain_development}\t#{mouse_strain_control}\t#{phenotype_reference}\t#{phenotype_of_het_hemi_mutants}\t#{coat_colour}\t#{physical_characteristics}\t#{donor_primary_reference}\t#{donor_primary_reference_url}\t#{research_applications}\t#{breeding_system}\t#{breeding_schemes}\n"

      #r1.write "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{genetic_founder_background_strain}\t#{current_background_strain}\t#{clone}\t#{research_area}\t#{human_disease_models}\n"
      #
      #r2.write "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{alteration}\t#{parental_cell_line}\n"
      #
      #r3.write "#{production_centre}\t#{colony_name}\t#{marker_symbol}\t#{mgi_allele_id}\t\t\t\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tGene\n"
      #r3.write "#{production_centre}\t#{colony_name}\t#{allele_symbol}\t#{allele_mgi_allele_id}\t#{alteration}\t#{clone}\t#{allele_symbol}\tmouse\t#{marker_symbol}\t#{mgi_accession_id}\t#{chromosome}\tAllele\n"
      #
      #r4.write "#{production_centre}\t#{colony_name}\t#{mmrrc_strain_nomenclature}\t#{common_strain_name}\t#{genetic_alterations}\t#{backcross_generation}\t#{interbreeding_generation}\t#{mouse_strain_development}\t#{mouse_strain_control}\t#{phenotype_reference}\t#{phenotype_of_het_hemi_mutants}\t#{coat_colour}\t#{physical_characteristics}\t#{donor_primary_reference}\t#{donor_primary_reference_url}\t#{research_applications}\t#{breeding_system}\t#{breeding_schemes}\n"
    end

    write hash

    #r1.close
    #r2.close
    #r3.close
    #r4.close
  end

  def write hash
    FileUtils.mkdir_p FOLDER

    header = {
      1 => "production_centre\tmmrrc_id\tallele_symbol\tgenetic_founder_background_strain\tcurrent_background_strain\tclone\tresearch_area\thuman_disease_models\n",
      2 => "production_centre\tmmrrc_id\tmmrrc_strain_nomenclature\talteration\tes_cell_line\n",
      3 => "production_centre\tmmrrc_id\tmgi_gene_symbol\tmgi_allele_id\talteration_at_locus\talteration_description\tlocus_allele\tspecies\tgene\tmgi_gene_id\tchromosome\n",
      4 => "production_centre\tcolony_name\tmmrrc_strain_nomenclature\tcommon_strain_name\tgenetic_alterations\tbackcross_generation\tinterbreeding_generation\tmouse_strain_development\tmouse_strain_control\tphenotype_reference\tphenotype_of_het_hemi_mutants\tcoat_colour\tphysical_characteristics\tdonor_primary_reference\tdonor_primary_reference_url\tresearch_applications\tbreeding_system\tbreeding_schemes\n"
    }

    filenames = {
      1 => 'strain_data.tsv',
      2 => 'strain_alteration.tsv',
      3 => 'locus_data.tsv',
      4 => 'sds_data.tsv'
    }

    #  puts "#### FOLDER: '#{FOLDER}'"

    hash.keys.each do |key|
      hash[key].keys.each do |key2|
        FileUtils.mkdir_p "#{FOLDER}/#{key2}"
        r = File.open("#{FOLDER}/#{key2}/#{filenames[key]}",'w')
        r.write header[key]
        r.write hash[key][key2].join
        r.close
      end
    end
  end

  def get_files
    return if ! File.exists?(FOLDER)

    folders = {}
    Dir.foreach(FOLDER) do |dir|
      next if dir == '.' || dir == '..'
      Dir.foreach(FOLDER + "/" + dir) do |file|
        next if file == '.' || file == '..'
        folders[dir] ||= {}
        s = file.gsub(/_/, ' ').gsub(/.tsv/, '')
        s = s.split.map(&:capitalize).join(' ')
        folders[dir][s] = FOLDER + "/" + dir + "/" + file
      end
    end

    #pp folders
    folders
  end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  #MmrrcOriginal.new.run
  MmrrcNew.new.run
end
