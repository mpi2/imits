require 'pp'

class MiAttemptKompReconciledListReport

    ##
    ## Report to display the Komp repository mi attempt distribution centre reconciled list
    ##

    attr_accessor :komp_reconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def komp_reconciled_list
        @komp_reconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_sql(self.consortium, self.prod_centre))

        # @komp_reconciled_list_base ||= ActiveRecord::Base.connection.execute(self.class.select_list_sql(self.consortium, self.prod_centre))

        # @komp_reconciled_list = []

        # @komp_reconciled_list_base.each do |row|
        #   mi_id = row['mi_attempt_id']
        #   mi = MiAttempt.find_by_id(mi_id)
        #   mi_symbol = mi.allele_symbol.to_s if mi
        #   if mi_symbol
        #     regex = /(?<=<sup>)(.*)(?=<\/sup>)/
        #     row['allele_symbol'] = mi_symbol.match(regex)[1]
        #   else
        #     row['allele_symbol'] = ""
        #   end
        #   @komp_reconciled_list.push row
        #   pp row
        # end

        # @komp_reconciled_list
    end

    class << self

        def title
          "Mi Attempt Distribution Centres Komp Repository Reconciled List"
        end

        # centre_id 35 is Komp Repo

        def select_list_sql(consortium, prod_centre)
            sql = <<-EOF
              SELECT genes.marker_symbol,
              mi_attempt_distribution_centres.mi_attempt_id,
              mi_attempts.external_ref AS mi_attempt_colony_name,
              mi_attempts.mouse_allele_type,
              targ_rep_es_cells.allele_type,
              targ_rep_mutation_types.name AS es_cell_allele_mutation_type,
              mi_attempt_distribution_centres.reconciled,
              date(mi_attempt_distribution_centres.reconciled_at) AS reconciled_date
              FROM mi_attempt_distribution_centres
              JOIN mi_attempts ON mi_attempts.id = mi_attempt_distribution_centres.mi_attempt_id
              JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
              JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
              JOIN centres ON centres.id = mi_plans.production_centre_id
              JOIN genes ON genes.id = mi_plans.gene_id
              JOIN consortia ON mi_plans.consortium_id = consortia.id
              JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
              JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
              LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
              WHERE mi_attempt_statuses.name = 'Genotype confirmed'
              AND mi_attempt_distribution_centres.centre_id = 35
              AND reconciled = 'true'
              AND consortia.name = '#{consortium}'
              AND centres.name = '#{prod_centre}'
              ORDER BY genes.marker_symbol
            EOF
        end
    end # end class

end