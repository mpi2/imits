# encoding: utf-8
require 'open-uri'

class QualityOverview

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :indicator, :colony_prefix, :pipeline, :consortium
  attr_accessor :production_centre, :microinjection_date, :mutation_subtype, :marker_symbol
  attr_accessor :es_cell_clone, :confirm_locus_targeted, :confirm_structure_targeted_allele
  attr_accessor :confirm_downstream_lox_p_site, :confirm_no_additional_vector_insertions
  attr_accessor :es_dist_qc, :es_user_qc, :mouse_qc

  attr_accessor :mi_attempt_id

  attr_accessor :mi_plan_consortia_grouping_order, :mi_plan_consortia_grouping, :mi_plan_consortium, :mi_plan_production_centre, :mi_attempt_distribution_centres, :mi_attempt_status

  def self.build_from_csv(row)
    quality_overview = QualityOverview.new
    quality_overview.indicator = row[0]
    quality_overview.colony_prefix = row[1]
    quality_overview.pipeline = row[2]
    quality_overview.consortium = row[3]
    quality_overview.production_centre = row[4]
    quality_overview.microinjection_date = row[5]
    quality_overview.marker_symbol = row[6]
    quality_overview.mutation_subtype = row[7]
    quality_overview.es_cell_clone = row[8]
    quality_overview.confirm_locus_targeted = row[9]
    quality_overview.confirm_structure_targeted_allele = row[10]
    quality_overview.confirm_downstream_lox_p_site = row[11]
    quality_overview.confirm_no_additional_vector_insertions = row[12]
    quality_overview.es_dist_qc = row[13]
    quality_overview.es_user_qc = row[14]
    quality_overview.mouse_qc = row[15]

    return quality_overview
  end

  def self.import(file_path)

    infile = open(file_path)
    count = 0
    quality_overviews = Array.new
    CSV.parse(infile) do |row|
      count += 1
      next if count == 1 or row.join.blank?
        quality_overview = QualityOverview.build_from_csv(row)
        next if ! quality_overview.populate_related_data

        quality_overviews.push(quality_overview)
    end

    return quality_overviews
  end

  def self.sort(quality_overviews)
    quality_overviews.sort!{|qa,qb| [qa.mi_plan_consortia_grouping_order ,qa.mi_plan_consortium, qa.production_centre, qa.marker_symbol] <=> [qb.mi_plan_consortia_grouping_order, qb.mi_plan_consortium, qb.production_centre, qb.marker_symbol]}
    return quality_overviews
  end

  def self.group(quality_overview_groupings)
    quality_overview_grouped = {}
    current_group = ''
    quality_overview_groupings.each do |rec|
      if rec.mi_plan_consortia_grouping != current_group
        current_group = rec.mi_plan_consortia_grouping
        quality_overview_grouped[current_group] = []
      end
      quality_overview_grouped[current_group] << rec
    end
    return quality_overview_grouped
  end

  def populate_related_data
    if self.colony_prefix
      mi_attempt = MiAttempt.find_by_colony_name(self.colony_prefix)
      return false if ! mi_attempt

      self.mi_attempt_id = mi_attempt.id
      self.mi_plan_consortium = mi_attempt.mi_plan.consortium.name
      self.mi_plan_consortia_grouping, self.mi_plan_consortia_grouping_order = Consortium[self.mi_plan_consortium].consortia_group_and_order
      self.mi_plan_production_centre = mi_attempt.mi_plan.production_centre.name
      self.mi_attempt_distribution_centres = mi_attempt.distribution_centres_formatted_display
      self.mi_attempt_status = mi_attempt.status.name
    end
    return true
  end

  def overall_pass
    if self.indicator == "allpass"
      return true
    else
      return false
    end
  end

  def available_attributes
    instance_values_hash = self.instance_values
    instance_values_hash.delete('mi_attempt_id')
    return instance_values_hash
  end

  def column_names
    instance_values_hash = self.available_attributes
    instance_values_hash.keys.map!{|key| key.humanize}
  end

  def column_values
    instance_values_hash = self.available_attributes
    instance_values_hash.values
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
