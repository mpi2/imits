class Mp2Load::PhenotypingProductionsReport

  attr_accessor :phenotyping_productions


  def phenotyping_productions
    @phenotyping_productions ||= process_data(ActiveRecord::Base.connection.execute(self.class.phenotyping_productions_sql.dup))


  end

  def process_data(data)
    phenotyping_productions_complete = []

    data.each do |row|
      if row["cohort_production_centre_name"].nil?
        row["cohort_production_centre_name"] = row["phenotyping_centre_name"]
      end
      
      allele = row["mouse_allele_symbol"].to_s
      gene = row["marker_symbol"].to_s

      row["mouse_allele_symbol"] = gene + "<sup>" + allele + "</sup>"

      phenotyping_productions_complete.push(row)
    end

    return phenotyping_productions_complete.to_json
  end
  private :process_data



  class << self

    def phenotyping_productions_sql
      <<-EOF
        SELECT pp.id, pp.colony_name, strain.name AS colony_background_strain_name, parent_strain.name AS parent_colony_background_strain_name, phenotyping_centre.name AS phenotyping_centre_name, cohort_centre.name AS cohort_production_centre_name, a.mgi_allele_symbol_superscript AS mouse_allele_symbol, g.mgi_accession_id, g.marker_symbol, pp.phenotype_attempt_id, p.id AS mi_plan_id, pp.phenotyping_started, pp.is_active

        FROM phenotyping_productions pp INNER JOIN colonies c ON c.id = pp.parent_colony_id 
          LEFT JOIN phenotyping_production_statuses ps ON ps.id = pp.status_id
          LEFT JOIN strains parent_strain ON c.background_strain_id = parent_strain.id
          LEFT JOIN strains strain ON pp.colony_background_strain_id = strain.id
          LEFT JOIN mi_plans p ON p.id = pp.mi_plan_id
          LEFT JOIN centres phenotyping_centre ON phenotyping_centre.id = p.production_centre_id
          LEFT JOIN centres cohort_centre ON cohort_centre.id = pp.cohort_production_centre_id
          LEFT JOIN genes g ON g.id = p.gene_id
          LEFT JOIN alleles a ON c.id = a.colony_id

        WHERE (ps.name != 'Rederivation Started' AND c.genotype_confirmed = true);
      EOF
    end
  end

end