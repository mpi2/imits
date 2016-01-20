class MiAttemptKompUnreconciledListReport

    ##
    ## Report to display the repository mi attempt distribution centre unreconciled list
    ##

    attr_accessor :komp_unreconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def komp_unreconciled_list
        # centre_id 35 is Komp Repo
        @komp_unreconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_by_centre_sql(self.consortium, self.prod_centre, 35))
    end

    class << self

        def title
          "Mi Attempt Distribution Centres Komp Repository Unreconciled List"
        end

        def select_list_by_centre_sql(consortium, prod_centre, repo_centre_id)
            sql = <<-EOF
              SELECT genes.marker_symbol,
              mi_attempts.id AS mi_attempt_id,
              mi_attempts.external_ref AS mi_attempt_colony_name,
              mi_attempts.mouse_allele_type,
              targ_rep_es_cells.allele_type,
              targ_rep_mutation_types.name AS es_cell_allele_mutation_type,
              colony_distribution_centres.reconciled,
              date(colony_distribution_centres.reconciled_at) AS reconciled_date
              FROM colony_distribution_centres
              JOIN colonies ON colonies.id = colony_distribution_centres.colony_id
              JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
              JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
              JOIN plans ON plans.id = mi_attempts.plan_id
              JOIN centres ON centres.id = plans.production_centre_id
              JOIN genes ON genes.id = plans.gene_id
              JOIN consortia ON plans.consortium_id = consortia.id
              JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
              JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
              LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
              WHERE mi_attempt_statuses.name = 'Genotype confirmed'
              AND colony_distribution_centres.centre_id = #{repo_centre_id}
              AND reconciled = 'false'
              AND consortia.name = '#{consortium}'
              AND centres.name = '#{prod_centre}'
              AND (colony_distribution_centres.start_date IS NULL OR colony_distribution_centres.start_date <= current_date)
              AND (colony_distribution_centres.end_date IS NULL OR current_date <= colony_distribution_centres.end_date )
              ORDER BY genes.marker_symbol
            EOF
        end
    end # end class

end
