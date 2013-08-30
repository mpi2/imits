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
            consortia.name as consortium, centres.name as production_centre, genes.marker_symbol, mi_attempts.colony_name,
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
            #{insert_bit}
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
            phenotype_attempts.colony_name,
            phenotype_attempt_statuses.name as current_status,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 2) as registered_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 5) as cre_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 6) as cre_complete_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 7) as phenotyping_started_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 8) as phenotyping_complete_date,
            (select to_char(created_at,'YYYY-MM-DD') from phenotype_attempt_status_stamps where phenotype_attempt_id = phenotype_attempts.id and status_id = 1) as phenotyping_aborted_date
          from mi_plans join consortia on mi_plans.consortium_id = consortia.id
            join centres on centres.id = mi_plans.production_centre_id
            join genes on genes.id = mi_plans.gene_id
            join phenotype_attempts on phenotype_attempts.mi_plan_id = mi_plans.id
            join phenotype_attempt_statuses on phenotype_attempts.status_id = phenotype_attempt_statuses.id
          where
            #{insert_bit}
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
