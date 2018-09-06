class MgiAlleleLoad::CrisprAlleleReport

  attr_accessor :crispr_mgi_allele


  def crispr_mgi_allele
    @crispr_mgi_allele ||= process_data(ActiveRecord::Base.connection.execute(self.class.mgi_allele_sql))
  end

  def process_data(data)
    data2 = data.to_a
    data2.each do |row|
      row['allele_class'] = 'endonuclease-mediated'

      if !row['allele_type'].blank? && !row['allele_subtype'].blank?
        project_name = 'IMPC'
        centres_name = row['centres_full_name']
        injection_components = ["#{row['nuclease']} #{row['nuclease_form']}", "#{ row['num_guides'].to_i > 1 ? row['num_guides'].to_s : 'the'} guide sequence#{ row['num_guides'].to_i > 1 ? 's' : ''} #{ row['guide_sequences'] }"]
        
        if !row['donor_types'].blank?
          if row['donor_types'].split(',').any?{|donor_type| ['Oligo', 'ssDNA Oligo'].include?(donor_type)}
         
            if row['allele_type'] == 'HDR'
              injection_components << "a donor oligo"
            else
              injection_components << "a non-contributing oligo"
            end

          elsif row['allele_type'] == 'HR'
            injection_components << "a donor plasmid"
          else
            injection_components << "a non-contributing plasmid" 
          end
        end

        injection_description_string = injection_components.to_sentence
  
        if ['Indel', 'Exon Deletion', 'Intra-exdel deletion', 'Inter-exdel deletion', 'Whole-gene deletion'].include?(row['allele_subtype'])
          mutation_result = "a#{ ['a','i','o','e','u'].include?(row['allele_subtype'][0]) ? 'n' : '' } #{row['allele_subtype']}"
        elsif ['Null reporter', 'Conditional Ready', 'Point Mutation'].include?(row['allele_subtype'])
          mutation_result = "a #{row['allele_subtype']} allele"
        else
          mutation_result = ''
        end
        
        description = "This allele from #{project_name} was generated at #{centres_name} by injecting #{injection_description_string}, which resulted in #{ mutation_result }."
  
        row['mgi_allele_description'] = description
      end
    end
    return data2
  end

  class << self

    def show_columns
      [{'title' => 'Marker Symbol', 'field' => 'marker_symbol'},
       {'title' => 'MGI Accession ID', 'field' => 'mgi_accession_id'},
       {'title' => 'ES Cell Line', 'field' => 'es_cell_line'},
       {'title' => 'Colony Name', 'field' => 'colony_name'},
       {'title' => 'Colony Background Strain', 'field' => 'colony_background_strain'},
       {'title' => 'Project Name', 'field' => 'project_name'},
       {'title' => 'Production Centre', 'field' => 'production_centre'},

       {'title' => 'Allele Class', 'field' => 'allele_class'},
       {'title' => 'Allele Type', 'field' => 'allele_type'},
       {'title' => 'Allele Subtype', 'field' => 'allele_subtype'},
       {'title' => 'MGI Allele Description', 'field' => 'mgi_allele_description'},
       {'title' => 'MGI Allele Name', 'field' => 'mgi_allele_name'},
       {'title' => 'MGI Allele Accession', 'field' => 'mgi_allele_accession'}
       ]
    end

    def mgi_allele_sql
      <<-EOF
      WITH crisprs AS (
          SELECT mi_attempts.id AS mi_attempt_id, string_agg(targ_rep_crisprs.sequence, ', ') AS guides, count(targ_rep_crisprs.id) num_guides
          FROM targ_rep_crisprs
            JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = targ_rep_crisprs.mutagenesis_factor_id
          GROUP BY mi_attempts.id
        ),

        donors AS (
          SELECT mi_attempts.id AS mi_attempt_id, count(mutagenesis_factor_donors.oligo_sequence_fa) num_oligos, string_agg(mutagenesis_factor_donors.oligo_sequence_fa, ', ') AS donor_sequences,
          string_agg(targ_rep_targeting_vectors.name, ', ') AS plasmid_ids, string_agg(mutagenesis_factor_donors.preparation, ',') AS donor_types
          FROM mutagenesis_factor_donors
            LEFT JOIN targ_rep_targeting_vectors ON mutagenesis_factor_donors.vector_id = targ_rep_targeting_vectors.id
            JOIN mi_attempts ON mi_attempts.mutagenesis_factor_id = mutagenesis_factor_donors.mutagenesis_factor_id
          GROUP BY mi_attempts.id
        ),
        characterized_alleles AS (
          SELECT trace_files.colony_id AS colony_id, a.mutant_fa AS protein_sequence,
          string_agg( 'Chromosome:' || aa.chr || ' Start:' || aa.start || ' ' || (CASE WHEN aa.mod_type = 'del' THEN 'deletion' WHEN aa.mod_type = 'ins' THEN 'insertion' WHEN aa.mod_type = 'snp' THEN 'nucleotide_substitutions' ELSE aa.mod_type END) || ':' || (aa.end - aa.start + 1) || 'bp ' || (CASE WHEN aa.mod_type = 'del' THEN  'mutation:' || substring( aa.ref_seq from 2 for (aa.end - aa.start + 1) ) WHEN aa.mod_type = 'ins' THEN 'mutation:' ||  substring( aa.alt_seq from 2 for (aa.end - aa.start + 1) ) WHEN aa.mod_type = 'snp' THEN 'mutation:' || aa.ref_seq || '/' || aa.alt_seq ELSE '' END), '|') AS molecular_characterization
          FROM trace_files
          JOIN alleles a ON trace_files.colony_id = a.colony_id
          JOIN allele_annotations aa ON a.id = aa.allele_id
          GROUP BY trace_files.colony_id, a.mutant_fa
        )



      SELECT
        genes.marker_symbol AS marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        genes.chr AS chromosome,
        colonies.name AS colony_name,
        blast_strains.name AS es_cell_line,
        background_strains.name AS colony_background_strain,
        centres.name AS production_centre,
        centres.full_name AS centres_full_name,
        CASE WHEN mi_attempts.mrna_nuclease IS NOT NULL THEN mi_attempts.mrna_nuclease 
            WHEN mi_attempts.protein_nuclease IS NOT NULL THEN mi_attempts.protein_nuclease
            ELSE '' 
            END AS nuclease,
        CASE WHEN mi_attempts.mrna_nuclease IS NOT NULL THEN 'RNA' 
            WHEN mi_attempts.protein_nuclease IS NOT NULL THEN 'Protein'
            ELSE '' 
            END AS nuclease_form,
        crisprs.guides AS guide_sequences,
        crisprs.num_guides AS num_guides,
        CASE WHEN donors.num_oligos > 0 THEN donors.donor_sequences ELSE '' END AS donor_sequences,
        CASE WHEN donors.num_oligos = 0 THEN donors.plasmid_ids ELSE '' END AS plasmid_ids,
        alleles.mgi_allele_accession_id AS mgi_allele_accession,
        alleles.mgi_allele_symbol_superscript AS mgi_allele_name,
        CASE WHEN characterized_alleles.colony_id IS NULL THEN 'No' ELSE 'Yes' END AS allele_characterized,
        characterized_alleles.molecular_characterization AS molecular_characterization,
        characterized_alleles.protein_sequence AS consequence_to_protein,
        donors.donor_types,
        'IMPC' AS project_name,
        alleles.allele_type,
        alleles.allele_subtype
      FROM mi_attempts
        JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
        JOIN alleles ON alleles.colony_id = colonies.id
        LEFT JOIN strains blast_strains ON blast_strains.id = mi_attempts.blast_strain_id
        LEFT JOIN strains background_strains ON background_strains.id = colonies.background_strain_id
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
        JOIN crisprs ON crisprs.mi_attempt_id = mi_attempts.id
        LEFT JOIN donors ON donors.mi_attempt_id = mi_attempts.id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN centres ON centres.id = mi_plans.production_centre_id
        LEFT JOIN characterized_alleles ON characterized_alleles.colony_id = colonies.id

      WHERE colonies.genotype_confirmed = true
      ORDER BY mgi_accession_id
      EOF
    end
  end

end