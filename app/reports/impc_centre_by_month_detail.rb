class ImpcCentreByMonthDetail

  def initialize

  end

  def es_rows(centre)
    ActiveRecord::Base.connection.execute(self.class.es_rows_sql).to_a
  end

  def mi_rows(centre)
    insert_bit = ActiveRecord::Base.send(:sanitize_sql_array, ["centres.name = ?", centre])
    ActiveRecord::Base.connection.execute(self.class.mi_rows_sql(insert_bit)).to_a
  end

  def pa_rows(centre)
    insert_bit = ActiveRecord::Base.send(:sanitize_sql_array, ["centres.name = ?", centre])
    ActiveRecord::Base.connection.execute(self.class.pa_rows_sql(insert_bit)).to_a
  end

  class << self

    def es_rows_sql
      <<-EOF
      EOF
    end

    def mi_rows_sql(insert_bit)
      <<-EOF
          SELECT
            consortia.name AS consortium, centres.name AS production_centre, genes.marker_symbol, colonies.name AS colony_name,
            targ_rep_es_cells.name AS clone, mi_attempt_statuses.name AS current_status, mi_date AS mi_date_asserted,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mi_attempt_status_stamps WHERE mi_attempt_id = mi_attempts.id and status_id = 1) AS mi_date_of_entry,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mi_attempt_status_stamps WHERE mi_attempt_id = mi_attempts.id and status_id = 4) AS chimerism_date,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mi_attempt_status_stamps WHERE mi_attempt_id = mi_attempts.id and status_id = 2) AS gc_date,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mi_attempt_status_stamps WHERE mi_attempt_id = mi_attempts.id and status_id = 3) AS abort_date
          FROM plans 
            JOIN consortia ON plans.consortium_id = consortia.id
            JOIN centres ON centres.id = plans.production_centre_id
            JOIN genes ON genes.id = plans.gene_id
            JOIN mi_attempts ON mi_attempts.plan_id = plans.id
            JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
            JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id
            JOIN targ_rep_es_cells ON mi_attempts.es_cell_id = targ_rep_es_cells.id
          WHERE
            #{insert_bit}
          AND (#{Plan.impc_activity_sql_where})
          ORDER BY mi_date_asserted;
      EOF
    end

    def pa_rows_sql(insert_bit)
      <<-EOF
          SELECT
            consortia.name AS consortium, centres.name AS production_centre, genes.marker_symbol,
            pp_parent_colony.name AS colony_name,
            CASE when mouse_allele_mod_statuses.name LIKE '%Aborted%' THEN 'Phenotype Attempt Aborted'
            WHEN phenotyping_production_statuses.order_by IS NULL THEN mouse_allele_mod_statuses.name
            WHEN mouse_allele_mod_statuses.order_by IS NULL THEN phenotyping_production_statuses.name
            WHEN phenotyping_production_statuses.order_by >= mouse_allele_mod_statuses.order_by
              THEN (CASE WHEN phenotyping_production_statuses.name LIKE '%Aborted%' THEN 'Phenotype Attempt Aborted' ELSE phenotyping_production_statuses.name END)
              ELSE (CASE WHEN mouse_allele_mod_statuses.name LIKE '%Aborted%' THEN 'Phenotype Attempt Aborted' ELSE mouse_allele_mod_statuses.name END)
            END AS current_status,
            CASE WHEN mouse_allele_mods.id IS NOT NULL THEN (select to_char(created_at,'YYYY-MM-DD') FROM mouse_allele_mod_status_stamps WHERE mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = 1)
              ELSE (select to_char(created_at,'YYYY-MM-DD') FROM phenotyping_production_status_stamps WHERE phenotyping_production_id = phenotyping_productions.id AND status_id = 1)
              END
            AS registered_date,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mouse_allele_mod_status_stamps WHERE mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = 5) AS cre_started_date,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM mouse_allele_mod_status_stamps WHERE mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = 6) AS cre_complete_date,
            CASE WHEN mouse_allele_mods.id IS NULL AND pp_parent_colony.mouse_allele_mod_id IS NOT NULL THEN 1 ELSE 0 END as mouse_modified_externally,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM phenotyping_production_status_stamps WHERE phenotyping_production_id = phenotyping_productions.id AND status_id = 3) AS phenotyping_started_date,
            (SELECT to_char(created_at,'YYYY-MM-DD') FROM phenotyping_production_status_stamps WHERE phenotyping_production_id = phenotyping_productions.id AND status_id = 4) AS phenotyping_complete_date,

            CASE WHEN mouse_allele_mods.status_id = 7 THEN (SELECT to_char(created_at,'YYYY-MM-DD') FROM mouse_allele_mod_status_stamps WHERE mouse_allele_mod_id = mouse_allele_mods.id AND status_id = 7)
              WHEN phenotyping_productions.status_id = 5 THEN (SELECT to_char(created_at,'YYYY-MM-DD') FROM phenotyping_production_status_stamps WHERE phenotyping_production_id = phenotyping_productions.id AND status_id = 7)
              END
            AS phenotyping_aborted_date

            FROM plans
            JOIN plan_intentions ON plan_intentions.plan_id = plans.id AND plan_intentions.intention_id = 3
            JOIN consortia on plans.consortium_id = consortia.id
            JOIN centres on centres.id = plans.production_centre_id
            JOIN genes on genes.id = plans.gene_id
            LEFT JOIN
              (phenotyping_productions
                JOIN phenotyping_production_statuses ON phenotyping_productions.status_id = phenotyping_production_statuses.id
                JOIN colonies pp_parent_colony ON pp_parent_colony.id = phenotyping_productions.parent_colony_id
              ) ON plans.id = phenotyping_productions.plan_id

            LEFT JOIN (mouse_allele_mods
                JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
              ) ON mouse_allele_mods.id = pp_parent_colony.mouse_allele_mod_id OR (mouse_allele_mods.mi_plan_id = mi_plans.id AND phenotyping_productions.id IS NULL)

          where
            #{insert_bit}
            and (mouse_allele_mods.id IS NOT NULL OR phenotyping_productions.id IS NOT NULL)
            and (#{Plan.impc_activity_sql_where})
          order by registered_date;
      EOF
    end

  end

end
