class MiAttemptRepositoryReconciledSummaryReport

    ##
    ## Report to display the repository mi attempt distribution centre summary
    ##

    attr_accessor :mi_reconciled_summary_list

    def mi_reconciled_summary_list
        @mi_reconciled_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_sql)
    end

    class << self

        def title
          "Mi Attempt Distribution Centres Summary for Komp Repository"
        end

        def consortia_ids_to_include
           # 4 is BaSH consortium, 7 is JAX, 5 is DTCC
           [4,5,7]
        end

        # centre_id 35 is Komp Repo

        def select_summary_sql
          sql = <<-EOF
            SELECT consortia.name AS consortium_name, centres.name AS production_centre_name,
            COUNT(mi_attempt_distribution_centres.mi_attempt_id) AS count_mi_attempts_gtc,
            COALESCE(sum(CASE WHEN mi_attempt_distribution_centres.reconciled = 'false' THEN 1 ELSE 0 END),0) AS count_reconciled_false,
            COALESCE(sum(CASE WHEN mi_attempt_distribution_centres.reconciled = 'not checked' THEN 1 ELSE 0 END),0) AS count_not_checked,
            COALESCE(sum(CASE WHEN mi_attempt_distribution_centres.reconciled = 'not found' THEN 1 ELSE 0 END),0) AS count_not_found,
            COALESCE(sum(CASE WHEN mi_attempt_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0) AS count_reconciled_true,
            ROUND(((( COALESCE(sum(CASE WHEN mi_attempt_distribution_centres.reconciled = 'true' THEN 1 ELSE 0 END),0)::float )
            /( COUNT(mi_attempt_distribution_centres.mi_attempt_id)::float )) * 100.00::float)::numeric, 1 ) AS percent_reconciled_true
            FROM mi_attempt_distribution_centres
            JOIN mi_attempts ON mi_attempts.id = mi_attempt_distribution_centres.mi_attempt_id
            JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
            JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN consortia ON mi_plans.consortium_id = consortia.id
            WHERE mi_attempt_statuses.name = 'Genotype confirmed'
            AND mi_attempt_distribution_centres.centre_id = 35
            AND consortia.id in ( #{consortia_ids_to_include.join(',')} )
            GROUP BY consortia.name, centres.name
            ORDER BY consortia.name, centres.name
          EOF
        end
    end # end class

end
