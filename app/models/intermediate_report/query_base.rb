module IntermediateReport::QueryBase

    def select_sql(category = 'es cell', approach = 'all', allele_type = 'all')

      on_clause_criteria = {'category' => category,
                            'allele_type' => allele_type
                            }

      selection_type = {'all'                       => {'mi_production'=> true, 'allele_mod_production' => true, 'phenotyping' => true},
                        'micro-injection'           => {'mi_production' => true, 'allele_mod_production' => false, 'phenotyping' => true},
                        'mouse allele modification' => {'mi_production' => false, 'allele_mod_production' => true, 'phenotyping' => true}
                        }

      return generate_sql(on_clause_criteria, selection_type[approach])

    end


    def where_sql(category = 'es cell', approach = 'all', allele_type = 'all', conditions = {})

      sql = <<-EOF
        SELECT tmp.*
          FROM (#{select_sql(category, approach, allele_type )}) tmp
      EOF

      criteria = []

      field_operation_hash = {
        'ci' => ['UPPER', 'upcase'],
        }

      comparisons_hash = {
        'eq'    => [' = ', "'@'"],
        'neq'   => [' != ', "'@'"],
        'gteq'  => [' >= ', "'@'"],
        'gt'    => [' > ', "'@'"],
        'lteq'  => [' <= ', "'@'"],
        'lt'    => [' < ', "'@'"],
        'in'    => [' IN ', "('@')"],
        'nin'   => [' NOT IN ', "('@')"],
        'cont'  => [' LIKE ', "'%@%'"],
        'null'  => [' IS NULL ', nil],
        'nnull' => [' IS NOT NULL ', nil],
        }

      unless conditions.blank?
        conditions.each do |field, value|
          value = value.join("','") if value.class == Array
          md = /(\w*(?<!_ci))(?:_(ci))?(?:_(\w*))\Z/.match(field)

          attr = md[1]
          field_operation = md[2]
          operator = md[3]

          next if attr.blank? || operator.blank? || !comparisons_hash.has_key?(operator) || !IntermediateReportSummaryByCentreAndConsortia.new.attributes.has_key?(attr)

          if field_operation
            criteria << "#{field_operation_hash[field_operation][0]}(tmp.#{attr}) #{comparisons_hash[operator][0]} #{comparisons_hash[operator][1].blank? ? '' : comparisons_hash[operator][1].sub('@',value.send(field_operation_hash[field_operation][1]))}"
          else
            criteria << "tmp.#{attr} #{comparisons_hash[operator][0]} #{comparisons_hash[operator][1].blank? ? '' : comparisons_hash[operator][1].sub('@',value)}"
          end
        end
      end

      sql = sql + ' WHERE ' + criteria.join(' AND ') if !criteria.blank?

      return sql
    end


    def generate_sql( where_clauses = {}, display = {})

      display['plan'] = true
      display['mi_production'] = true if !display.has_key?('mi_production')
      display['allele_mod_production'] = true if !display.has_key?('allele_mod_production')
      display['phenotyping'] = true if !display.has_key?('phenotyping')

      where_clauses['category'] = 'es cell' if !where_clauses.has_key?('category')
      where_clauses['allele_type'] = 'all' if !where_clauses.has_key?('allele_type')

      if !where_clauses.has_key?('phenotyping_approach')
        where_clauses['phenotyping_approach'] = 'all'
        if !display['allele_mod_production'] || !display['mi_production']
          if display['allele_mod_production']
            where_clauses['phenotyping_approach'] = 'mouse allele modification'
          elsif display['mi_production']
            where_clauses['phenotyping_approach'] = 'micro-injection'
          end
        end
      end

      where = []
      sql = <<-EOF
        SELECT #{select_fields(display)}
        FROM (SELECT DISTINCT plans.gene_id #{self.distinct_fields.has_key?('consortia') ? ', plans.consortium_id' : ''} #{self.distinct_fields.has_key?('centre') ? ', plans.production_centre_id' : ''} FROM plans) AS distinct_gene_consortia_centre
        JOIN genes ON genes.id = distinct_gene_consortia_centre.gene_id
        #{self.distinct_fields.has_key?('consortia') ? 'JOIN consortia ON consortia.id = distinct_gene_consortia_centre.consortium_id' : ''}
        #{self.distinct_fields.has_key?('centre') ? 'JOIN centres ON centres.id = distinct_gene_consortia_centre.production_centre_id' : ''}
        LEFT JOIN (SELECT *
               FROM #{self.table_name}
               WHERE #{self.table_name}.catagory = '#{where_clauses['category']}' AND #{self.table_name}.allele_type = '#{where_clauses['allele_type']}' AND #{self.table_name}.approach = 'plan'
             ) AS plan_summary ON #{on_clause.gsub('@', 'plan_summary')}
      EOF
      where << "plan_summary.mi_plan_status IS NOT NULL"

      if display.has_key?('mi_production') && display['mi_production'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM #{self.table_name}
                     WHERE #{self.table_name}.catagory = '#{where_clauses['category']}' AND #{self.table_name}.allele_type = '#{where_clauses['allele_type']}' AND #{self.table_name}.approach = 'micro-injection'
                    ) AS mi_production_summary ON #{on_clause.gsub('@', 'mi_production_summary')}
        EOF
        where << "mi_production_summary.mi_attempt_status IS NOT NULL"
      end

      if display.has_key?('allele_mod_production') && display['allele_mod_production'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM #{self.table_name}
                     WHERE #{self.table_name}.catagory = '#{where_clauses['category']}' AND #{self.table_name}.allele_type = '#{where_clauses['allele_type']}' AND #{self.table_name}.approach = 'mouse allele modification'
                    ) AS allele_mod_production_summary ON #{on_clause.gsub('@', 'allele_mod_production_summary')}
        EOF
        where << "allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL"
      end

      if display.has_key?('phenotyping') && display['phenotyping'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM #{self.table_name}
                     WHERE #{self.table_name}.catagory = '#{where_clauses['category']}' AND #{self.table_name}.allele_type = '#{where_clauses['allele_type']}'  #{!where_clauses['phenotyping_approach'].nil? ? "AND #{self.table_name}.approach = '#{where_clauses['phenotyping_approach']}'" : ''}
                    ) AS phenotyping_production_summary ON #{on_clause.gsub('@', 'phenotyping_production_summary')}
        EOF
        where << "phenotyping_production_summary.phenotyping_status IS NOT NULL"
      end

      sql += "WHERE #{where.join(' OR ')} " unless where.blank?
      return sql
    end

    def select_fields(display = {'mi_production' => true, 'allele_mod_production' => true, 'phenotyping' => true})
      display['plan'] = true
      #confiuration of fields that should be returned
      sql = ''

      if display.has_key?('plan') && display['plan'] == true
        sql += <<-EOF
               genes.marker_symbol AS gene,
               #{self.distinct_fields.has_key?('consortia') ? 'consortia.name AS consortium,' : ''}
               #{self.distinct_fields.has_key?('centre') ? 'centres.name AS production_centre,' : ''}
               plan_summary.plan_id,
               plan_summary.mgi_accession_id,
               plan_summary.mi_plan_status,
               #{self.table_name != 'intermediate_report_summary_by_gene' ? 'plan_summary.gene_interest_date,' : ''}
               plan_summary.assigned_date,
               plan_summary.assigned_es_cell_qc_in_progress_date,
               plan_summary.assigned_es_cell_qc_complete_date,
               plan_summary.aborted_es_cell_qc_failed_date
        EOF
      end

      if display.has_key?('mi_production') && display['mi_production'] == true
        sql += <<-EOF
               ,mi_production_summary.mi_attempt_id,
               mi_production_summary.mi_attempt_external_ref,
               mi_production_summary.mi_attempt_colony_name,
               mi_production_summary.mi_attempt_status,
               mi_production_summary.micro_injection_aborted_date,
               mi_production_summary.micro_injection_in_progress_date,
               mi_production_summary.chimeras_obtained_date,
               mi_production_summary.founder_obtained_date,
               mi_production_summary.genotype_confirmed_date
        EOF
      end

      if display.has_key?('allele_mod_production') && display['allele_mod_production'] == true
        sql += <<-EOF
               ,allele_mod_production_summary.modified_mouse_allele_mod_id,
               allele_mod_production_summary.mouse_allele_mod_id,
               allele_mod_production_summary.mouse_allele_mod_colony_name,
               allele_mod_production_summary.mouse_allele_mod_status,
               allele_mod_production_summary.mouse_allele_mod_registered_date,
               allele_mod_production_summary.rederivation_started_date,
               allele_mod_production_summary.rederivation_complete_date,
               allele_mod_production_summary.cre_excision_started_date,
               allele_mod_production_summary.cre_excision_complete_date
        EOF
      end

      if display.has_key?('phenotyping') && display['phenotyping'] == true
        sql += <<-EOF
               ,phenotyping_production_summary.phenotyping_production_id,
               phenotyping_production_summary.phenotyping_production_colony_name,
               phenotyping_production_summary.phenotyping_status,
               phenotyping_production_summary.phenotyping_registered_date,
               phenotyping_production_summary.phenotyping_rederivation_started_date,
               phenotyping_production_summary.phenotyping_rederivation_complete_date,
               phenotyping_production_summary.phenotyping_experiments_started_date,
               phenotyping_production_summary.phenotyping_started_date,
               phenotyping_production_summary.phenotyping_complete_date,
               phenotyping_production_summary.phenotype_attempt_aborted_date,
               phenotyping_production_summary.approach AS phenotyping_approach
        EOF
      end

      if display.has_key?('plan') && display['plan'] == true &&
         display.has_key?('mi_production') && display['mi_production'] == true &&
         display.has_key?('allele_mod_production') && display['allele_mod_production'] == true &&
         display.has_key?('phenotyping') && display['phenotyping'] == true
        sql += <<-EOF
           , CASE WHEN phenotyping_production_summary.phenotyping_status = 'Phenotype Production Aborted' AND (allele_mod_production_summary.mouse_allele_mod_status IS NULL OR allele_mod_production_summary.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
                WHEN phenotyping_production_summary.phenotyping_status IS NOT NULL THEN phenotyping_production_summary.phenotyping_status
                WHEN allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL THEN allele_mod_production_summary.mouse_allele_mod_status
                WHEN mi_production_summary.mi_attempt_status IS NOT NULL THEN mi_production_summary.mi_attempt_status
                WHEN plan_summary.mi_plan_status IS NOT NULL THEN plan_summary.mi_plan_status
           END AS overall_status
        EOF
      end

      return sql
    end

    def distinct_fields
      return {}
    end

    def on_clause
      return "@.gene = genes.marker_symbol #{self.distinct_fields.has_key?('consortia') ?  'AND @.consortium = consortia.name ' : '' } #{self.distinct_fields.has_key?('centre') ?  ' AND @.production_centre = centres.name' : ''}"
    end

end

# == Schema Information
#
# Table name: intermediate_report_summary_by_centre_and_consortia
#
#  id                                     :integer          not null, primary key
#  catagory                               :string(255)      not null
#  approach                               :string(255)      not null
#  allele_type                            :string(255)      not null
#  mi_plan_id                             :integer
#  mi_attempt_id                          :integer
#  modified_mouse_allele_mod_id           :integer
#  mouse_allele_mod_id                    :integer
#  phenotyping_production_id              :integer
#  consortium                             :string(255)
#  production_centre                      :string(255)
#  gene                                   :string(255)
#  mgi_accession_id                       :string(255)
#  mi_attempt_external_ref                :string(255)
#  mi_attempt_colony_name                 :string(255)
#  mouse_allele_mod_colony_name           :string(255)
#  phenotyping_production_colony_name     :string(255)
#  mi_plan_status                         :string(255)
#  gene_interest_date                     :date
#  assigned_date                          :date
#  assigned_es_cell_qc_in_progress_date   :date
#  assigned_es_cell_qc_complete_date      :date
#  aborted_es_cell_qc_failed_date         :date
#  mi_attempt_status                      :string(255)
#  micro_injection_aborted_date           :date
#  micro_injection_in_progress_date       :date
#  chimeras_obtained_date                 :date
#  founder_obtained_date                  :date
#  genotype_confirmed_date                :date
#  mouse_allele_mod_status                :string(255)
#  mouse_allele_mod_registered_date       :date
#  rederivation_started_date              :date
#  rederivation_complete_date             :date
#  cre_excision_started_date              :date
#  cre_excision_complete_date             :date
#  phenotyping_status                     :string(255)
#  phenotyping_registered_date            :date
#  phenotyping_rederivation_started_date  :date
#  phenotyping_rederivation_complete_date :date
#  phenotyping_experiments_started_date   :date
#  phenotyping_started_date               :date
#  phenotyping_complete_date              :date
#  phenotype_attempt_aborted_date         :date
#  created_at                             :date
#
# Indexes
#
#  irscc_allele_type              (allele_type)
#  irscc_approach                 (approach)
#  irscc_catagory                 (catagory)
#  irscc_mi_attempts              (mi_attempt_id)
#  irscc_mi_plans                 (mi_plan_id)
#  irscc_mouse_allele_mods        (mouse_allele_mod_id)
#  irscc_phenotyping_productions  (phenotyping_production_id)
#
