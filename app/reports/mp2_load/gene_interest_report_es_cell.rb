class Mp2Load::GeneInterestReportEsCell

  attr_accessor :gene_statues


  def gene_statues
    @gene_statues ||= process_data(ActiveRecord::Base.connection.execute(self.class.gene_interest_sql))
  end

  def process_data(data)
    process_data = []

    data.each do |row|
      processed_row = row.dup
      if !processed_row['gene_assignment_status'].blank? && ['Withdrawn', 'Inactive'].include?(processed_row['gene_assignment_status'])
        processed_row['gene_assignment_status'] = 'Withdrawn'
        processed_row['conditional_allele_production_status'] = nil
        processed_row['conditional_allele_production_centre'] = nil
        processed_row['conditional_allele_status_date'] = nil
        processed_row['conditional_allele_production_start_date'] = nil
        processed_row['null_allele_production_status'] = nil
        processed_row['null_allele_production_centre'] = nil
        processed_row['null_allele_status_date'] = nil
        processed_row['null_allele_production_start_date'] = nil
        processed_row['phenotyping_status'] = nil
        processed_row['phenotyping_centre'] = nil
        processed_row['phenotyping_status_date'] = nil
        processed_row['number_of_significant_phenotypes'] = nil
      end
 
      process_data << processed_row
    end

    return process_data
  end
  private :process_data

  class << self

    def show_columns
      [{'title' => 'gene_mgi_accession_id', 'field' => 'gene_mgi_accession_id'},
       {'title' => 'gene_marker_symbol', 'field' => 'gene_marker_symbol'},
       {'title' => 'gene_assignment_status', 'field' => 'gene_assignment_status'},
       {'title' => 'gene_assigned_to', 'field' => 'gene_assigned_to'},
       {'title' => 'gene_assignment_status_date', 'field' => 'gene_assignment_status_date'},
       {'title' => 'conditional_allele_production_status', 'field' => 'conditional_allele_production_status'},
       {'title' => 'conditional_allele_production_centre', 'field' => 'conditional_allele_production_centre'},
       {'title' => 'conditional_allele_status_date', 'field' => 'conditional_allele_status_date'},
       {'title' => 'conditional_allele_production_start_date', 'field' => 'conditional_allele_production_start_date'},

       {'title' => 'null_allele_production_status', 'field' => 'null_allele_production_status'},
       {'title' => 'null_allele_production_centre', 'field' => 'null_allele_production_centre'},
       {'title' => 'null_allele_status_date', 'field' => 'null_allele_status_date'},

       {'title' => 'null_allele_production_start_date', 'field' => 'null_allele_production_start_date'},

       {'title' => 'phenotyping_status', 'field' => 'phenotyping_status'},
       {'title' => 'phenotyping_centre', 'field' => 'phenotyping_centre'},
       {'title' => 'phenotyping_status_date', 'field' => 'phenotyping_status_date'},
       {'title' => 'number_of_significant_phenotypes', 'field' => 'number_of_significant_phenotypes'}
       ]
    end

    def gene_interest_sql
      <<-EOF
                WITH ordered_plans AS (
          SELECT mi_plans.gene_id, mi_plans.id AS mi_plan_id, mi_plan_statuses.name AS status_name, mi_plans.production_centre_id AS centre_id, mpss.created_at AS state_change_date
          FROM mi_plans
            JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id
            JOIN mi_plan_status_stamps mpss ON mi_plans.id = mpss.mi_plan_id AND mi_plans.status_id = mpss.status_id
          WHERE phenotype_only = false AND es_cell_qc_only = false AND mi_plans.report_to_public = true AND mi_plans.mutagenesis_via_crispr_cas9 = false AND mi_plans.consortium_id != 17 -- exclude EUCOMMToolsCre  
          ORDER BY
            mi_plans.gene_id,
            mi_plan_statuses.order_by DESC
          ),

          top_assigned_status AS (
            SELECT DISTINCT ordered_plans.gene_id, first_value(ordered_plans.mi_plan_id) OVER (PARTITION BY ordered_plans.gene_id) AS mi_plan_id, 
                first_value(ordered_plans.status_name) OVER (PARTITION BY ordered_plans.gene_id) AS status_name,
                first_value(ordered_plans.centre_id) OVER (PARTITION BY ordered_plans.gene_id) AS centre_id,
                first_value(ordered_plans.state_change_date) OVER (PARTITION BY ordered_plans.gene_id) AS state_change_date
            FROM ordered_plans
          ),

          genes_assigned_status AS (
            SELECT top_assigned_status.gene_id AS gene_id, centres.name AS centre_name, top_assigned_status.status_name, top_assigned_status.state_change_date
            FROM top_assigned_status
              JOIN centres ON centres.id = top_assigned_status.centre_id
          ),

          ordered_conditional_mi_attempts AS (
          SELECT  ordered_plans.gene_id AS gene_id, ordered_plans.mi_plan_id AS mi_plan_id, mi_status.name AS status_name, mi_attempts.id AS mi_attempt_id, 
          ordered_plans.centre_id AS centre_id, miss.created_at AS state_change_date, production_started_stamp.created_at AS production_started_date
          FROM mi_attempts
            LEFT JOIN (targ_rep_es_cells es JOIN targ_rep_alleles a ON a.id = es.allele_id AND a.mutation_type_id = 1) ON es.id = mi_attempts.es_cell_id
            JOIN mi_attempt_statuses mi_status ON mi_status.id = mi_attempts.status_id
            JOIN mi_attempt_status_stamps miss ON mi_attempts.id = miss.mi_attempt_id AND mi_attempts.status_id = miss.status_id
            JOIN ordered_plans ON ordered_plans.mi_plan_id = mi_attempts.mi_plan_id
            LEFT JOIN mi_attempt_status_stamps production_started_stamp ON production_started_stamp.mi_attempt_id = mi_attempts.id AND production_started_stamp.status_id = 1
          WHERE es.id IS NOT NULL AND mi_attempts.report_to_public = true AND mi_attempts.experimental = false
          ORDER BY
            ordered_plans.gene_id,
            mi_status.order_by DESC
          ),

          top_conditional_production_status AS (
            SELECT DISTINCT ordered_conditional_mi_attempts.gene_id, first_value(ordered_conditional_mi_attempts.mi_attempt_id) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS mi_attempt_id,
            first_value(ordered_conditional_mi_attempts.status_name) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS status_name,
            first_value(ordered_conditional_mi_attempts.mi_plan_id) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS mi_plan_id,
            first_value(ordered_conditional_mi_attempts.centre_id) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS centre_id,
            first_value(ordered_conditional_mi_attempts.state_change_date) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS state_change_date,
            min(ordered_conditional_mi_attempts.production_started_date) OVER (PARTITION BY ordered_conditional_mi_attempts.gene_id) AS production_started_date
            FROM ordered_conditional_mi_attempts
          ),

          conditional_production_status AS (
            SELECT top_conditional_production_status.gene_id AS gene_id, centres.name AS centre_name, top_conditional_production_status.status_name AS status_name, 
            top_conditional_production_status.state_change_date AS state_change_date, top_conditional_production_status.production_started_date AS production_started_date
            FROM top_conditional_production_status
              JOIN centres ON centres.id = top_conditional_production_status.centre_id
          ),


          null_mi_attempts AS (
            SELECT  ordered_plans.gene_id AS gene_id, ordered_plans.mi_plan_id AS mi_plan_id, mi_status.name AS status_name, 
                CASE WHEN mi_status.name = 'Genotype confirmed' THEN mi_status.order_by + 220 ELSE mi_status.order_by END AS order_by, -- Ensure Genotype Confirmed status trumps mouse_allele_mod statuses.
                ordered_plans.centre_id AS centre_id, miss.created_at AS state_change_date, production_started_stamp.created_at AS production_started_date
            FROM mi_attempts
              LEFT JOIN ordered_conditional_mi_attempts ON ordered_conditional_mi_attempts.mi_attempt_id = mi_attempts.id
              JOIN mi_attempt_statuses mi_status ON mi_status.id = mi_attempts.status_id
              JOIN mi_attempt_status_stamps miss ON mi_attempts.id = miss.mi_attempt_id AND mi_attempts.status_id = miss.status_id
              JOIN ordered_plans ON ordered_plans.mi_plan_id = mi_attempts.mi_plan_id
              LEFT JOIN mi_attempt_status_stamps production_started_stamp ON production_started_stamp.mi_attempt_id = mi_attempts.id AND production_started_stamp.status_id = 1
            WHERE ordered_conditional_mi_attempts.mi_attempt_id IS NULL AND mi_attempts.report_to_public = true AND mi_attempts.experimental = false
            ORDER BY
              ordered_plans.gene_id,
              mi_status.order_by DESC
          ),


          all_null_production AS (
            (SELECT ordered_conditional_mi_attempts.gene_id AS gene_id, mouse_allele_mods.mi_plan_id AS mi_plan_id, mam_status.name AS status_name, 
              mam_status.order_by AS order_by, 
                    ordered_plans.centre_id AS centre_id, mamss.created_at AS state_change_date, production_started_stamp.created_at AS production_started_date
            FROM ordered_conditional_mi_attempts
              JOIN colonies ON colonies.mi_attempt_id = ordered_conditional_mi_attempts.mi_attempt_id
              JOIN mouse_allele_mods ON mouse_allele_mods.parent_colony_id = colonies.id
              JOIN mouse_allele_mod_statuses mam_status ON mouse_allele_mods.status_id = mam_status.id
              JOIN mouse_allele_mod_status_stamps mamss ON mouse_allele_mods.status_id = mamss.status_id AND mouse_allele_mods.id = mamss.mouse_allele_mod_id
              JOIN ordered_plans ON ordered_plans.mi_plan_id = mouse_allele_mods.mi_plan_id
              LEFT JOIN mouse_allele_mod_status_stamps production_started_stamp ON production_started_stamp.mouse_allele_mod_id = mouse_allele_mods.id AND production_started_stamp.status_id = 1
            WHERE mouse_allele_mods.is_active = true AND mouse_allele_mods.report_to_public = true AND mam_status.id != 1 AND mam_status.id != 2 -- registered statuses and aborted status.
            )
            UNION
            (
            SELECT * FROM null_mi_attempts
            )

            ),

          ordered_null_mi_attempts AS (
            SELECT all_null_production.*
            FROM all_null_production
            ORDER BY 
              all_null_production.gene_id,
              all_null_production.order_by DESC

          ),

          top_null_production_status AS (
            SELECT DISTINCT ordered_null_mi_attempts.gene_id,
                first_value(ordered_null_mi_attempts.status_name) OVER (PARTITION BY ordered_null_mi_attempts.gene_id) AS status_name,
                first_value(ordered_null_mi_attempts.mi_plan_id) OVER (PARTITION BY ordered_null_mi_attempts.gene_id) AS mi_plan_id,
                first_value(ordered_null_mi_attempts.centre_id) OVER (PARTITION BY ordered_null_mi_attempts.gene_id) AS centre_id,
                first_value(ordered_null_mi_attempts.state_change_date) OVER (PARTITION BY ordered_null_mi_attempts.gene_id) AS state_change_date,
                min(ordered_null_mi_attempts.production_started_date) OVER (PARTITION BY ordered_null_mi_attempts.gene_id) AS production_started_date
            FROM ordered_null_mi_attempts
          ),

          null_production_status AS (
            SELECT top_null_production_status.gene_id AS gene_id, centres.name AS centre_name, top_null_production_status.status_name AS status_name,
                   top_null_production_status.state_change_date AS state_change_date, top_null_production_status.production_started_date AS production_started_date
            FROM top_null_production_status
              JOIN mi_plans ON mi_plans.id = top_null_production_status.mi_plan_id
              JOIN centres ON centres.id = mi_plans.production_centre_id
            WHERE mi_plans.mutagenesis_via_crispr_cas9 = false
          ),


          order_phenotyping_productions AS (
            SELECT mi_plans.gene_id, phenotyping_productions.id AS phenotyping_production_id, mi_plans.id AS mi_plan_id, pps.name AS status_name, mi_plans.production_centre_id AS centre_id,
                   ppss.created_at AS state_change_date
            FROM phenotyping_productions
              JOIN phenotyping_production_statuses pps ON pps.id = phenotyping_productions.status_id
              JOIN phenotyping_production_status_stamps ppss ON phenotyping_productions.id = ppss.phenotyping_production_id AND phenotyping_productions.status_id = ppss.status_id 
              JOIN mi_plans ON mi_plans.id = phenotyping_productions.mi_plan_id AND mi_plans.report_to_public = true
            WHERE phenotyping_productions.report_to_public = true AND mi_plans.mutagenesis_via_crispr_cas9 = false AND mi_plans.consortium_id != 17 -- exclude EUCOMMToolsCre
            ORDER BY 
              mi_plans.gene_id,
              pps.order_by DESC
          ),

          top_phenotyping_status AS (
            SELECT DISTINCT order_phenotyping_productions.gene_id, first_value(order_phenotyping_productions.phenotyping_production_id) OVER (PARTITION BY order_phenotyping_productions.gene_id) AS phenotyping_production_id,
                first_value(order_phenotyping_productions.status_name) OVER (PARTITION BY order_phenotyping_productions.gene_id) AS status_name,
                first_value(order_phenotyping_productions.mi_plan_id) OVER (PARTITION BY order_phenotyping_productions.gene_id) AS mi_plan_id,
                first_value(order_phenotyping_productions.centre_id) OVER (PARTITION BY order_phenotyping_productions.gene_id) AS centre_id,
                first_value(order_phenotyping_productions.state_change_date) OVER (PARTITION BY order_phenotyping_productions.gene_id) AS state_change_date
            FROM order_phenotyping_productions
          ),

          genes_phenotyping_status AS (
            SELECT top_phenotyping_status.gene_id AS gene_id, centres.name AS centre_name, top_phenotyping_status.status_name AS status_name, top_phenotyping_status.state_change_date AS state_change_date
            FROM top_phenotyping_status
              JOIN centres ON centres.id = top_phenotyping_status.centre_id
          )

        SELECT
        genes.mgi_accession_id AS gene_mgi_accession_id,
        genes.marker_symbol AS gene_marker_symbol,
        genes_assigned_status.status_name AS gene_assignment_status,
        genes_assigned_status.centre_name AS gene_assigned_to,
        genes_assigned_status.state_change_date AS gene_assignment_status_date,
        conditional_production_status.status_name AS conditional_allele_production_status,
        conditional_production_status.centre_name AS conditional_allele_production_centre,
        conditional_production_status.state_change_date AS conditional_allele_status_date,
        conditional_production_status.production_started_date AS conditional_allele_production_start_date,
        null_production_status.status_name AS null_allele_production_status,
        null_production_status.centre_name AS null_allele_production_centre,
        null_production_status.state_change_date AS null_allele_status_date,
        null_production_status.production_started_date AS null_allele_production_start_date,
        genes_phenotyping_status.status_name AS phenotyping_status,
        genes_phenotyping_status.centre_name AS phenotyping_centre,
        genes_phenotyping_status.state_change_date AS phenotyping_status_date,
        0 AS number_of_significant_phenotpyes
        FROM genes 
          LEFT JOIN genes_assigned_status ON genes.id = genes_assigned_status.gene_id
          LEFT JOIN null_production_status ON genes.id = null_production_status.gene_id
          LEFT JOIN conditional_production_status ON genes.id = conditional_production_status.gene_id
          LEFT JOIN genes_phenotyping_status ON genes.id = genes_phenotyping_status.gene_id
        
      EOF
    end
  end

end