class MiAttemptKompReconciledSummaryReport

    ##
    ## Report to display the Komp repository mi attempt distribution centre summary
    ##

    attr_accessor :komp_summary_list

    def komp_summary_list
        @komp_summary_list ||= ActiveRecord::Base.connection.execute(self.class.select_summary_sql)
    end

    # def generate_komp_summary_list
    #     puts "IN GENERATE"
    #     list = []

    #     komp_summary_list.each do |report_row|
    #         report_row_hash = {
    #             'consortium_name'         => report_row['consortium_name'],
    #             'production_centre_name'  => report_row['production_centre_name'],
    #             'count_mi_attempts_gtc'   => report_row['count_mi_attempts_gtc'],
    #             'count_reconciled_true'   => report_row['count_reconciled_true'],
    #             'percent_reconciled_true' => report_row['percent_reconciled_true']
    #         }
    #         list.push(report_row_hash)
    #     end

    #     pp list

    #     list

    #     # hash = {}

    #     # komp_summary_list.each do |report_row|

    #     #     hash[report_row['consortium_name']][report_row['production_centre_name']] = {
    #     #         report_row['count_mi_attempts_gtc'],
    #     #         report_row['count_reconciled_true'],
    #     #         report_row['percent_reconciled_true']
    #     #     }

    #     # end

    #     # pp hash

    #     # hash
    # end

    class << self

        def title
          "Mi Attempt Distribution Centres Summary for Komp Repository"
        end

        def consortia_ids_to_include
           # 4 is BaSH consortium, 7 is JAX, 5 is DTCC
           [4,5,7]
        end

        # centre_id 35 is Komp Repo
        # SELECT * FROM some_table WHERE some_table.colX in ('#{some_values.join('\', \'')}');

        def select_summary_sql
          sql = <<-EOF
            SELECT consortia.name AS consortium_name, centres.name AS production_centre_name,
            count(mi_attempt_distribution_centres.mi_attempt_id) AS count_mi_attempts_gtc,
            count(nullif((mi_attempt_distribution_centres.reconciled = 'true'), false)) AS count_reconciled_true,
            round(((( count(nullif((mi_attempt_distribution_centres.reconciled = 'true'), false))::float )
            /( count(mi_attempt_distribution_centres.mi_attempt_id)::float )) * 100.00::float)::numeric, 1 ) AS percent_reconciled_true
            FROM mi_attempt_distribution_centres
            JOIN mi_attempts on mi_attempts.id = mi_attempt_distribution_centres.mi_attempt_id
            JOIN mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id
            JOIN mi_plans on mi_plans.id = mi_attempts.mi_plan_id
            JOIN centres on centres.id = mi_plans.production_centre_id
            JOIN consortia on mi_plans.consortium_id = consortia.id
            WHERE mi_attempt_statuses.name = 'Genotype confirmed'
            AND mi_attempt_distribution_centres.centre_id = 35
            AND consortia.id in ( 4, 5, 7 )
            GROUP BY consortia.name, centres.name
            order by consortia.name, centres.name
          EOF
        end
    end # end class

end
