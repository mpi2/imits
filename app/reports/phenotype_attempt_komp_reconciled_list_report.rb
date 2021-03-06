class PhenotypeAttemptKompReconciledListReport

    ##
    ## Report to display the repository phneotype attempt distribution centre reconciled list
    ##

    attr_accessor :komp_reconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def komp_reconciled_list
        # centre_id 35 is Komp Repo
        @komp_reconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_by_centre_sql(self.consortium, self.prod_centre, 35))
    end

    class << self

      def title
        "Phenotype Attempt Distribution Centres Komp Repository Reconciled List"
      end

      def select_list_by_centre_sql(consortium, prod_centre, repo_centre_id)
          sql = <<-EOF
            SELECT genes.marker_symbol,
            mouse_allele_mods.id AS mouse_allele_mod_id,
            mouse_allele_mods.colony_name AS phenotype_attempt_colony_name,
            mouse_allele_mods.mouse_allele_type,
            targ_rep_es_cells.allele_type,
            targ_rep_mutation_types.name AS es_cell_allele_mutation_type,
            colony_distribution_centres.reconciled,
            date(colony_distribution_centres.reconciled_at) AS reconciled_date
            FROM colony_distribution_centres
            JOIN colonies ON colonies.id = colony_distribution_centres.colony_id
            JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
            JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
            JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
            JOIN centres ON centres.id = mi_plans.production_centre_id
            JOIN genes ON genes.id = mi_plans.gene_id
            JOIN consortia ON mi_plans.consortium_id = consortia.id
            JOIN colonies mi_colony ON mi_colony.id = mouse_allele_mods.parent_colony_id
            JOIN mi_attempts ON mi_attempts.id = mi_colony.mi_attempt_id
            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
            AND colony_distribution_centres.centre_id = #{repo_centre_id}
            AND reconciled = 'true'
            AND consortia.name = '#{consortium}'
            AND centres.name = '#{prod_centre}'
            AND (colony_distribution_centres.start_date IS NULL OR colony_distribution_centres.start_date <= current_date)
            AND (colony_distribution_centres.end_date IS NULL OR current_date <= colony_distribution_centres.end_date )
            ORDER BY genes.marker_symbol
          EOF
      end
    end # end class

end
