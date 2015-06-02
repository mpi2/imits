class PhenotypeAttemptRepositoryReconciledSummaryReport

    ##
    ## Report to display the repository mi attempt distribution centre summary
    ##

    attr_accessor :phenotype_reconciled_komp_summary_list
    attr_accessor :phenotype_reconciled_emma_summary_list
    attr_accessor :phenotype_reconciled_mmrrc_summary_list

    def phenotype_reconciled_komp_summary_list
        # centre_id 35 is Komp Repo
        @phenotype_reconciled_komp_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_by_centre_sql(35))
    end

    def phenotype_reconciled_emma_summary_list
        @phenotype_reconciled_emma_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_by_dist_network_sql("EMMA"))
    end

    def phenotype_reconciled_mmrrc_summary_list
        @phenotype_reconciled_mmrrc_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_by_dist_network_sql("MMRRC"))
    end

    class << self

        def title
          "Phenotype Attempt Distribution Centres Summary of Reconciled Alleles"
        end

        def consortia_ids_to_include
           # 4 is BaSH consortium, 7 is JAX, 5 is DTCC
           [4,5,7]
        end

        def select_summary_by_centre_sql(repo_centre_id)
          sql = <<-EOF
            SELECT consortia.name AS consortium_name, centres.name AS production_centre_name,
            COUNT(mouse_allele_mods.id) AS count_mouse_allele_mods,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'false' THEN 1 ELSE 0 END),0) AS count_reconciled_false,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'not checked' THEN 1 ELSE 0 END),0) AS count_not_checked,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'not found' THEN 1 ELSE 0 END),0) AS count_not_found,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0) AS count_reconciled_true,
            ROUND(((( COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0)::float )
            /( COUNT(mouse_allele_mods.id)::float )) * 100.00::float)::numeric, 1 ) AS percent_reconciled_true
            FROM colony_distribution_centres
            JOIN colonies ON colonies.id = colony_distribution_centres.colony_id
            JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
            JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON mi_plans.consortium_id = consortia.id
            WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
            AND colony_distribution_centres.centre_id = 35
            AND consortia.id in ( #{consortia_ids_to_include.join(',')} )
            AND (colony_distribution_centres.start_date IS NULL OR colony_distribution_centres.start_date <= current_date)
            AND (colony_distribution_centres.end_date IS NULL OR current_date <= colony_distribution_centres.end_date )
            GROUP BY consortia.name, centres.name
            ORDER BY consortia.name, centres.name
          EOF
        end

        def select_summary_by_dist_network_sql(dist_network_name)
          sql = <<-EOF
            SELECT consortia.name AS consortium_name, centres.name AS production_centre_name,
            COUNT(mouse_allele_mods.id) AS count_mouse_allele_mods,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'false' THEN 1 ELSE 0 END),0) AS count_reconciled_false,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'not checked' THEN 1 ELSE 0 END),0) AS count_not_checked,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'not found' THEN 1 ELSE 0 END),0) AS count_not_found,
            COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0) AS count_reconciled_true,
            ROUND(((( COALESCE(sum(CASE WHEN colony_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0)::float )
            /( COUNT(mouse_allele_mods.id)::float )) * 100.00::float)::numeric, 1 ) AS percent_reconciled_true
            FROM colony_distribution_centres
            JOIN colonies ON colonies.id = colony_distribution_centres.colony_id
            JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
            JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON mi_plans.consortium_id = consortia.id
            WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
            AND colony_distribution_centres.distribution_network = '#{dist_network_name}'
            AND consortia.id in ( #{consortia_ids_to_include.join(',')} )
            AND (colony_distribution_centres.start_date IS NULL OR colony_distribution_centres.start_date <= current_date)
            AND (colony_distribution_centres.end_date IS NULL OR current_date <= colony_distribution_centres.end_date )
            GROUP BY consortia.name, centres.name
            ORDER BY consortia.name, centres.name
          EOF
        end
    end # end class

end
