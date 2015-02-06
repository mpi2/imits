class MiAttemptEmmaReconciledListReport

    ##
    ## Report to display the repository mi attempt distribution centre reconciled list
    ##

    attr_accessor :emma_reconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def emma_reconciled_list
        @emma_reconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_by_dist_network_sql(self.consortium, self.prod_centre, 'EMMA'))
    end

    class << self

        def title
          "Mi Attempt Distribution Centres EMMA Repository Reconciled List"
        end

        def select_list_by_dist_network_sql(consortium, prod_centre, dist_network_name)
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
              AND mi_attempt_distribution_centres.distribution_network = '#{dist_network_name}'
              AND reconciled = 'true'
              AND consortia.name = '#{consortium}'
              AND centres.name = '#{prod_centre}'
              AND (mi_attempt_distribution_centres.start_date IS NULL OR mi_attempt_distribution_centres.start_date <= current_date)
              AND (mi_attempt_distribution_centres.end_date IS NULL OR current_date <= mi_attempt_distribution_centres.end_date )
              ORDER BY genes.marker_symbol
            EOF
        end

    end # end class

end
