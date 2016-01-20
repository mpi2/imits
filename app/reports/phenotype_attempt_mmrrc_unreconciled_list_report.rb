class PhenotypeAttemptMmrrcUnreconciledListReport

    ##
    ## Report to display the repository phenotype attempt distribution centre unreconciled list
    ##

    attr_accessor :mmrrc_unreconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def mmrrc_unreconciled_list
        @mmrrc_unreconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_by_dist_network_sql(self.consortium, self.prod_centre, 'MMRRC'))
    end

    class << self

      def title
        "Phenotype Attempt Distribution Centres MMRRC Repository Unreconciled List"
      end

      def select_list_by_dist_network_sql(consortium, prod_centre, dist_network_name)
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
            JOIN plans ON plans.id = mouse_allele_mods.plan_id
            JOIN centres ON centres.id = plans.production_centre_id
            JOIN genes ON genes.id = plans.gene_id
            JOIN consortia ON plans.consortium_id = consortia.id
            JOIN colonies mi_colony ON mi_colony.id = mouse_allele_mods.parent_colony_id
            JOIN mi_attempts ON mi_attempts.id = mi_colony.mi_attempt_id
            JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
            JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
            LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
            WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
            AND colony_distribution_centres.distribution_network = '#{dist_network_name}'
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
