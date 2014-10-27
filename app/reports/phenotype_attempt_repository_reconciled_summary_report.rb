class PhenotypeAttemptRepositoryReconciledSummaryReport

    ##
    ## Report to display the repository mi attempt distribution centre summary
    ##

    attr_accessor :phenotype_reconciled_summary_list

    def phenotype_reconciled_summary_list
        @phenotype_reconciled_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_sql)
    end

    class << self

        def title
          "Phenotype Attempt Distribution Centres Summary for Komp Repository"
        end

        def consortia_ids_to_include
           # 4 is BaSH consortium, 7 is JAX, 5 is DTCC
           [4,5,7]
        end

        # centre_id 35 is Komp Repo

        def select_summary_sql
          sql = <<-EOF
            SELECT consortia.name AS consortium_name, centres.name AS production_centre_name,
            COUNT(phenotype_attempt_distribution_centres.mouse_allele_mod_id) AS count_mouse_allele_mods,
            COALESCE(sum(CASE WHEN phenotype_attempt_distribution_centres.reconciled = 'false' THEN 1 ELSE 0 END),0) AS count_reconciled_false,
            COALESCE(sum(CASE WHEN phenotype_attempt_distribution_centres.reconciled = 'not checked' THEN 1 ELSE 0 END),0) AS count_not_checked,
            COALESCE(sum(CASE WHEN phenotype_attempt_distribution_centres.reconciled = 'not found' THEN 1 ELSE 0 END),0) AS count_not_found,
            COALESCE(sum(CASE WHEN phenotype_attempt_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0) AS count_reconciled_true,
            ROUND(((( COALESCE(sum(CASE WHEN phenotype_attempt_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0)::float )
            /( COUNT(phenotype_attempt_distribution_centres.phenotype_attempt_id)::float )) * 100.00::float)::numeric, 1 ) AS percent_reconciled_true
            FROM phenotype_attempt_distribution_centres
            JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotype_attempt_distribution_centres.mouse_allele_mod_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
            JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON mi_plans.consortium_id = consortia.id
            WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
            AND phenotype_attempt_distribution_centres.centre_id = 35
            AND consortia.id in ( #{consortia_ids_to_include.join(',')} )
            GROUP BY consortia.name, centres.name
            ORDER BY consortia.name, centres.name
          EOF
        end
    end # end class

end
