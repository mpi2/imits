# encoding: utf-8

class QualityOverview

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :indicator, :colony_prefix, :pipeline, :emma
  attr_accessor :production_centre, :microinjection_date, :marker_symbol
  attr_accessor :es_cell_clone, :confirm_locus_targeted, :confirm_structure_targeted_allele
  attr_accessor :confirm_downstream_lox_p_site, :confirm_no_additional_vector_insertions, :es_dist_qc
  attr_accessor :es_user_qc, :mouse_qc

  attr_accessor :mi_attempt_id

  attr_accessor :mi_plan_consortium, :mi_plan_production_centre

  def self.build_from_csv(row)
    quality_overview = QualityOverview.new
    quality_overview.indicator = row[0]
    quality_overview.colony_prefix = row[1]
    quality_overview.pipeline = row[2]
    quality_overview.emma = row[3]
    quality_overview.production_centre = row[4]
    quality_overview.microinjection_date = row[5]
    quality_overview.marker_symbol = row[6]
    quality_overview.es_cell_clone = row[7]
    quality_overview.confirm_locus_targeted = row[8]
    quality_overview.confirm_structure_targeted_allele = row[9]
    quality_overview.confirm_downstream_lox_p_site = row[10]
    quality_overview.confirm_no_additional_vector_insertions = row[11]
    quality_overview.es_dist_qc = row[12]
    quality_overview.es_user_qc = row[13]
    quality_overview.mouse_qc = row[14]

    return quality_overview
  end

  def populate_mi_attempt_id
    if self.marker_symbol
      mi_attempt = MiAttempt.find_by_colony_name(self.colony_prefix)
      self.mi_attempt_id = mi_attempt_id
    end
  end

  def populate_mi_plan_attributes
    if self.mi_attempt_id
      mi_attempt = MiAttempt.find!(self.mi_attempt_id)
      if mi_attempt
        self.mi_plan_consortium = mi_attempt.mi_plan.consortium.name
        self.mi_plan_production_centre = mi_attempt.mi_plan.production_centre.name
      end
    end
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

end
