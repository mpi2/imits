class Mp2Load::LegacyEmailsSentReport

  attr_accessor :legacy_emails_sent

  def legacy_emails_sent
    @legacy_emails_sent ||= process_data(ActiveRecord::Base.connection.execute(self.class.legacy_emails_sent_sql))
  end


  def process_data(data)
    process_data = []

    data.each do |row|
      processed_row = row.dup
      if !processed_row['assigned_inactive_status'].blank? && ['Withdrawn', 'Inactive'].include?(processed_row['assigned_inactive_status'])
        processed_row['gene_assignment_status'] = 'Withdrawn'
        processed_row['conditional_allele_production_status'] = nil
        processed_row['null_allele_production_status'] = nil
        processed_row['phenotyping_status'] = nil
      end

      process_data << processed_row
    end

    return process_data
  end
  private :process_data

  class << self

    def show_columns
      [{'title' => 'mgi_accession_id', 'field' => 'mgi_accession_id'},
       {'title' => 'marker_symbol', 'field' => 'marker_symbol'},
       {'title' => 'email', 'field' => 'email'},
       {'title' => 'last_email_sent_date', 'field' => 'latest_email_sent_date'},
       {'title' => 'gene_assignment_status', 'field' => 'assigned_inactive_status'},
       {'title' => 'conditional_allele_production_status', 'field' => 'conditional_mouse_status_name'},
       {'title' => 'null_allele_production_status', 'field' => 'null_mouse_status_name'},
       {'title' => 'phenotyping_status', 'field' => 'phenotyping_status_name'},
       {'title' => 'gene_contact_created_at', 'field' => 'gene_contact_created_at'},
       {'title' => 'contact_created_at', 'field' => 'contact_created_at'}
       ]
    end

    def legacy_emails_sent_sql
      <<-EOF
        WITH notification_summary AS (
            SELECT notifications.gene_id, notifications.contact_id, GREATEST(welcome_email_sent, last_email_sent) AS latest_email_sent_date,
                   notifications.created_at
            FROM notifications WHERE welcome_email_sent IS NOT NULL OR last_email_sent IS NOT NULL
        ),

        assigned_data AS (
          SELECT n.gene_id, n.contact_id, mpss.created_at AS stamp_date, mps.name AS status_name, mps.order_by, withdrawn_s.name AS inactive_status
            FROM mi_plans
              JOIN mi_plan_status_stamps mpss ON mpss.mi_plan_id = mi_plans.id
              JOIN mi_plan_statuses mps ON mps.id = mpss.status_id
              JOIN notification_summary n ON n.gene_id = mi_plans.gene_id AND n.latest_email_sent_date >= mpss.created_at
              LEFT JOIN mi_plan_statuses withdrawn_s ON mi_plans.status_id = withdrawn_s.id AND (withdrawn_s.name = 'Inactive' OR withdrawn_s.name = 'Withdrawn')
          WHERE mi_plans.report_to_public = true AND mi_plans.consortium_id != 17 AND mi_plans.mutagenesis_via_crispr_cas9 = false
          ORDER BY n.gene_id, n.contact_id, withdrawn_s.name DESC, order_by DESC
          ),

          
          conditional_mi_attempts AS (
            SELECT n.gene_id, n.contact_id, miss.created_at AS stamp_date, mis.name AS status_name, mis.order_by, mi.id AS mi_attempt_id, mi.report_to_public AS report_to_public
            FROM mi_attempts mi
              JOIN mi_plans ON mi_plans.id = mi.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
              JOIN mi_attempt_status_stamps miss ON miss.mi_attempt_id = mi.id AND miss.status_id != 6 AND miss.status_id != 3  -- exclude Chimeras/founder obtained & Aborted status
              JOIN mi_attempt_statuses mis ON mis.id = miss.status_id
              JOIN targ_rep_es_cells es ON  es.id = mi.es_cell_id
              JOIN targ_rep_alleles a ON a.id = es.allele_id
              JOIN targ_rep_mutation_types mt ON mt.id = a.mutation_type_id AND mt.name = 'Conditional Ready'
              JOIN notification_summary n ON n.gene_id = mi_plans.gene_id AND n.latest_email_sent_date >= miss.created_at
            WHERE  mi_plans.consortium_id != 17
            ORDER BY n.gene_id, n.contact_id, order_by DESC
          ),

          conditional_mouse_data AS (
            SELECT gene_id, contact_id, stamp_date, status_name, mi_attempt_id
            FROM conditional_mi_attempts
            WHERE report_to_public = true
            ORDER BY gene_id, contact_id, order_by DESC
          ),


          null_mi_attempts AS (
            SELECT n.gene_id, n.contact_id, miss.created_at AS stamp_date, mis.name AS status_name, mis.order_by
            FROM mi_attempts mi
              JOIN mi_plans ON mi_plans.id = mi.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
              JOIN mi_attempt_status_stamps miss ON miss.mi_attempt_id = mi.id AND miss.status_id != 6 AND miss.status_id != 3  -- exclude Chimeras/founder obtained & Aborted status
              JOIN mi_attempt_statuses mis ON mis.id = miss.status_id
              JOIN targ_rep_es_cells es ON es.id = mi.es_cell_id
              JOIN targ_rep_alleles a ON a.id = es.allele_id
              JOIN targ_rep_mutation_types mt ON mt.id = a.mutation_type_id AND mt.name != 'Conditional Ready'
              JOIN notification_summary n ON n.gene_id = mi_plans.gene_id AND n.latest_email_sent_date >= miss.created_at
            WHERE mi.report_to_public = true AND mi_plans.consortium_id != 17
            ORDER BY n.gene_id, n.contact_id, order_by DESC
          ),

          all_null_data AS (
            SELECT n.gene_id, n.contact_id, mamss.created_at AS stamp_date, mam_status.name AS status_name, 
              mam_status.order_by AS order_by
            FROM conditional_mi_attempts
              JOIN colonies ON colonies.mi_attempt_id = conditional_mi_attempts.mi_attempt_id
              JOIN mouse_allele_mods ON mouse_allele_mods.parent_colony_id = colonies.id
              JOIN mouse_allele_mod_status_stamps mamss ON mouse_allele_mods.id = mamss.mouse_allele_mod_id AND mamss.status_id != 1 AND mamss.status_id != 2 -- exclude registered statuses
              JOIN mouse_allele_mod_statuses mam_status ON mamss.status_id = mam_status.id
              JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
              JOIN notification_summary n ON n.gene_id = mi_plans.gene_id AND n.latest_email_sent_date >= mamss.created_at
            WHERE mouse_allele_mods.is_active = true AND mouse_allele_mods.report_to_public = true AND mi_plans.consortium_id != 17

            UNION

            SELECT *
              FROM null_mi_attempts
            ORDER BY gene_id, contact_id, order_by DESC

          ),

          phenotyping_data AS (
            SELECT n.gene_id, n.contact_id, ppss.created_at AS stamp_date, pps.name AS status_name, pps.order_by
            FROM phenotyping_productions pp
              JOIN mi_plans ON mi_plans.id = pp.mi_plan_id AND mi_plans.mutagenesis_via_crispr_cas9 = false
              JOIN phenotyping_production_status_stamps ppss ON ppss.phenotyping_production_id = pp.id
              JOIN phenotyping_production_statuses pps ON pps.id = ppss.status_id
              JOIN notification_summary n ON n.gene_id = mi_plans.gene_id AND n.latest_email_sent_date >= ppss.created_at
            WHERE pp.report_to_public = true
            ORDER BY n.gene_id, n.contact_id, order_by DESC
          ),

          partitioned_assigned_data AS (
            SELECT gene_id,
                   first_value(status_name) OVER (PARTITION BY gene_id) AS status_name,
                   first_value(inactive_status) OVER (PARTITION BY gene_id) AS inactive_status
            FROM assigned_data
          ),

          top_assigned_data AS (
            SELECT DISTINCT gene_id, status_name, inactive_status
              FROM partitioned_assigned_data
          ),

          partitioned_conditional_mouse_data AS (
            SELECT gene_id,
                   first_value(status_name) OVER (PARTITION BY gene_id) AS status_name
            FROM conditional_mouse_data
          ),

          top_conditional_mouse_data AS (
            SELECT DISTINCT gene_id, status_name
              FROM partitioned_conditional_mouse_data
          ),

          partitioned_null_mouse_data AS (
            SELECT gene_id,
                   first_value(status_name) OVER (PARTITION BY gene_id) AS status_name
            FROM all_null_data
          ),

          top_null_mouse_data AS (
            SELECT DISTINCT gene_id, status_name
              FROM partitioned_null_mouse_data
          ),
          
          partitioned_phenotyping_data AS (
            SELECT gene_id,
                   first_value(status_name) OVER (PARTITION BY gene_id) AS status_name
            FROM phenotyping_data
          ),

          top_phenotyping_data AS (
            SELECT DISTINCT gene_id, status_name
              FROM partitioned_phenotyping_data
          )

          SELECT contacts.email, contacts.created_at AS contact_created_at, n.created_at AS gene_contact_created_at,
                 genes.marker_symbol, genes.mgi_accession_id, n.latest_email_sent_date,
                 top_assigned_data.status_name AS assigned_status_name, top_assigned_data.inactive_status AS assigned_inactive_status,
                 top_conditional_mouse_data.status_name AS conditional_mouse_status_name,
                 top_null_mouse_data.status_name AS null_mouse_status_name,
                 top_phenotyping_data.status_name AS phenotyping_status_name
          FROM notification_summary n
            JOIN genes ON genes.id = n.gene_id
            JOIN contacts ON contacts.id = n.contact_id
            LEFT JOIN top_assigned_data ON top_assigned_data.gene_id = n.gene_id
            LEFT JOIN top_conditional_mouse_data ON top_conditional_mouse_data.gene_id = n.gene_id
            LEFT JOIN top_null_mouse_data ON top_null_mouse_data.gene_id = n.gene_id
            LEFT JOIN top_phenotyping_data ON top_phenotyping_data.gene_id = n.gene_id
          ORDER BY n.contact_id, n.gene_id
      EOF
    end
  end

end