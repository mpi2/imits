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
            consortia.name as consortium, centres.name as production_centre, genes.marker_symbol, mi_attempts.external_ref AS colony_name,
            targ_rep_es_cells.name as clone, mi_attempt_statuses.name as current_status, mi_date as mi_date_asserted,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 1) as mi_date_of_entry,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 4) as chimerism_date,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 2) as gc_date,
            (select to_char(created_at,'YYYY-MM-DD') from mi_attempt_status_stamps where mi_attempt_id = mi_attempts.id and status_id = 3) as abort_date
          from
            mi_plans join consortia on mi_plans.consortium_id = consortia.id
            join centres on centres.id = mi_plans.production_centre_id
            join genes on genes.id = mi_plans.gene_id
            join mi_attempts on mi_attempts.mi_plan_id = mi_plans.id
            join mi_attempt_statuses on mi_attempts.status_id = mi_attempt_statuses.id
            join targ_rep_es_cells on mi_attempts.es_cell_id = targ_rep_es_cells.id
          where
            #{insert_bit} and mi_plans.mutagenesis_via_crispr_cas9 = false
	  and
	    (centres.name = 'HMGU' AND consortia.name = 'Helmholtz GMC'
	  OR
	    centres.name = 'ICS' AND consortia.name IN ('Phenomin', 'Helmholtz GMC')
	  OR
	    centres.name in ('BCM', 'TCP', 'JAX', 'RIKEN BRC')
	  OR
	    centres.name = 'Harwell' AND consortia.name IN ('BaSH', 'MRC')
	  OR
	    centres.name = 'UCD' AND consortia.name = 'DTCC'
	  OR
	    centres.name = 'WTSI' AND consortia.name IN ('MGP', 'BaSH')
	  OR
	    centres.name = 'Monterotondo' AND consortia.name = 'Monterotondo')
          order by mi_date_asserted;
      EOF
    end

    def pa_rows_sql(insert_bit)
      <<-EOF
          select
            consortia.name as consortium, centres.name as production_centre, genes.marker_symbol,
            case when externally_modified.colony_name is not null then externally_modified.colony_name else mouse_allele_mods.colony_name end,
            case when phenotyping_production_statuses.order_by >= mouse_allele_mod_statuses.order_by
              then (CASE WHEN phenotyping_production_statuses.name like '%Aborted%' then 'Phenotype Attempt Aborted' else phenotyping_production_statuses.name end)
              else (CASE WHEN mouse_allele_mod_statuses.name like '%Aborted%' then 'Phenotype Attempt Aborted' else mouse_allele_mod_statuses.name end)
            end as current_status,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and status_id = 1) as registered_date,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and status_id = 5) as cre_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and status_id = 6) as cre_complete_date,
            case when externally_modified.no_modification_required = true and externally_modified.mi_plan_id != phenotyping_productions.mi_plan_id then 1 else 0 end as mouse_modified_externally,
            (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 3) as phenotyping_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotyping_production_status_stamps where phenotyping_production_id = phenotyping_productions.id and status_id = 4) as phenotyping_complete_date,
            (select to_char(created_at,'YYYY-MM-DD') from mouse_allele_mod_status_stamps where mouse_allele_mod_id = mouse_allele_mods.id and status_id = 7) as phenotyping_aborted_date

            from mi_plans join consortia on mi_plans.consortium_id = consortia.id
            join centres on centres.id = mi_plans.production_centre_id
            join genes on genes.id = mi_plans.gene_id
            left join
              (mouse_allele_mods join mouse_allele_mod_statuses on mouse_allele_mods.status_id = mouse_allele_mod_statuses.id
              ) ON mouse_allele_mods.mi_plan_id = mi_plans.id
            left join
              (phenotyping_productions
                join phenotyping_production_statuses on phenotyping_productions.status_id = phenotyping_production_statuses.id
                join mouse_allele_mods as externally_modified on externally_modified.id = phenotyping_productions.mouse_allele_mod_id
              ) ON (mouse_allele_mods.id is NULL AND phenotyping_productions.mi_plan_id = mi_plans.id) OR (mouse_allele_mods.id IS NOT NULL AND mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id)
          where
            #{insert_bit}
      and (mouse_allele_mods.id IS NOT NULL OR phenotyping_productions.id IS NOT NULL) and mi_plans.mutagenesis_via_crispr_cas9 = false
	  and
	    (centres.name = 'HMGU' AND consortia.name = 'Helmholtz GMC'
	  OR
	    centres.name = 'ICS' AND consortia.name IN ('Phenomin', 'Helmholtz GMC')
	  OR
	    centres.name in ('BCM', 'TCP', 'JAX', 'RIKEN BRC')
	  OR
	    centres.name = 'Harwell' AND consortia.name IN ('BaSH', 'MRC')
	  OR
	    centres.name = 'UCD' AND consortia.name = 'DTCC'
	  OR
	    centres.name = 'WTSI' AND consortia.name IN ('MGP', 'BaSH')
	  OR
	    centres.name = 'Monterotondo' AND consortia.name = 'Monterotondo')
          order by registered_date;
      EOF
    end

  end

end
