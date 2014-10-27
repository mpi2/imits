class PhenotypeAttemptKompUnreconciledListReport

    ##
    ## Report to display the Komp repository phenotype attempt distribution centre unreconciled list
    ##

    attr_accessor :komp_unreconciled_list
    attr_accessor :consortium
    attr_accessor :prod_centre

    def initialize(consortium=nil, prod_centre=nil)
        @consortium  = consortium
        @prod_centre = prod_centre
    end

    def komp_unreconciled_list
        @komp_unreconciled_list ||= ActiveRecord::Base.connection.execute(self.class.select_list_sql(self.consortium, self.prod_centre))
    end

    class << self

        def title
          "Phenotype Attempt Distribution Centres Komp Repository Unreconciled List"
        end

        # centre_id 35 is Komp Repo

        def select_list_sql(consortium, prod_centre)
            sql = <<-EOF
              SELECT genes.marker_symbol,
              phenotype_attempt_distribution_centres.mouse_allele_mod_id,
              mouse_allele_mods.colony_name AS phenotype_attempt_colony_name,
              mouse_allele_mods.mouse_allele_type,
              targ_rep_es_cells.allele_type,
              targ_rep_mutation_types.name AS es_cell_allele_mutation_type,
              phenotype_attempt_distribution_centres.reconciled,
              date(phenotype_attempt_distribution_centres.reconciled_at) AS reconciled_date
              FROM phenotype_attempt_distribution_centres
              JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotype_attempt_distribution_centres.mouse_allele_mod_id
              JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
              JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
              JOIN centres ON centres.id = mi_plans.production_centre_id
              JOIN genes ON genes.id = mi_plans.gene_id
              JOIN consortia ON mi_plans.consortium_id = consortia.id
              JOIN mi_attempts ON mi_attempts.id = mouse_allele_mods.mi_attempt_id
              JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
              JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
              LEFT OUTER JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
              WHERE mouse_allele_mod_statuses.name = 'Cre Excision Complete'
              AND phenotype_attempt_distribution_centres.centre_id = 35
              AND reconciled = 'false'
              AND consortia.name = '#{consortium}'
              AND centres.name = '#{prod_centre}'
              ORDER BY genes.marker_symbol
            EOF
        end
    end # end class

end
