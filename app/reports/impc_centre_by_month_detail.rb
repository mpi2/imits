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
          select
            consortia.name as consortium, centres.name as production_centre, genes.marker_symbol, colonies.name AS colony_name,
            targ_rep_es_cells.name as clone, mi_attempt_statuses.name as current_status, mi_date as mi_date_asserted,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 1) as mi_date_of_entry,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 4) as chimerism_date,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 2) as gc_date,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 3) as abort_date
          from
            mi_plans join consortia on mi_plans.consortium_id = consortia.id
            join centres on centres.id = mi_plans.production_centre_id
            join genes on genes.id = mi_plans.gene_id
            join mi_attempts on mi_attempts.accredited_to_id = mi_plans.id
            join colonies on colonies.mi_attempt_id = mi_attempts.id
            join mi_attempt_statuses on mi_attempts.status_id = mi_attempt_statuses.id
            join targ_rep_es_cells on mi_attempts.es_cell_id = targ_rep_es_cells.id
          where
            #{insert_bit} and mi_plans.mutagenesis_via_crispr_cas9 = false
          and (#{MiPlan.impc_activity_sql_where})
          order by mi_date_asserted;
      EOF
    end

    def pa_rows_sql(insert_bit)
      <<-EOF
          select
            consortia.name as consortium, centres.name as production_centre, genes.marker_symbol,
            pp_parent_colony.name AS colony_name,
            case when mouse_allele_mod_statuses.name like '%Aborted%' then 'Phenotype Attempt Aborted'
            when phenotyping_production_statuses.order_by IS NULL THEN mouse_allele_mod_statuses.name
            when mouse_allele_mod_statuses.order_by IS NULL THEN phenotyping_production_statuses.name
            when phenotyping_production_statuses.order_by >= mouse_allele_mod_statuses.order_by
              then (CASE WHEN phenotyping_production_statuses.name like '%Aborted%' then 'Phenotype Attempt Aborted' else phenotyping_production_statuses.name end)
              else (CASE WHEN mouse_allele_mod_statuses.name like '%Aborted%' then 'Phenotype Attempt Aborted' else mouse_allele_mod_statuses.name end)
            end as current_status,
            CASE WHEN mouse_allele_mods.id IS NOT NULL THEN (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and mouse_allele_mod_status_stamps.status_id = 1)
              ELSE (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 1)
              END
            as registered_date,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and mouse_allele_mod_status_stamps.status_id = 5) as cre_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and mouse_allele_mod_status_stamps.status_id = 6) as cre_complete_date,
            case when mouse_allele_mods.id IS NULL AND pp_parent_colony.mouse_allele_mod_id IS NOT NULL then 1 else 0 end as mouse_modified_externally,
            (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 3) as phenotyping_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 4) as phenotyping_complete_date,

            CASE WHEN mouse_allele_mods.status_id = 7 THEN (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and status_id = 7)
              WHEN phenotyping_productions.status_id = 5 THEN (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 7)
              END
            as phenotyping_aborted_date

            from mi_plans join consortia on mi_plans.consortium_id = consortia.id
            join centres on centres.id = mi_plans.production_centre_id
            join genes on genes.id = mi_plans.gene_id
            left join
              (phenotyping_productions
                join phenotyping_production_statuses on phenotyping_productions.status_id = phenotyping_production_statuses.id
                join colonies pp_parent_colony ON pp_parent_colony.id = phenotyping_productions.parent_colony_id
              ) ON mi_plans.id = phenotyping_productions.accredited_to_id

            left join (mouse_allele_mods
                join mouse_allele_mod_statuses on mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
              ) ON mouse_allele_mods.id = pp_parent_colony.mouse_allele_mod_id OR (mouse_allele_mods.accredited_to_id = mi_plans.id AND phenotyping_productions.id IS NULL)

          where
            #{insert_bit}
            and (mouse_allele_mods.id IS NOT NULL OR phenotyping_productions.id IS NOT NULL) and mi_plans.mutagenesis_via_crispr_cas9 = false
            and (#{MiPlan.impc_activity_sql_where})
          order by registered_date;
      EOF
    end

  end

end
