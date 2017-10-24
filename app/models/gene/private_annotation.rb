class Gene::PrivateAnnotation < ActiveRecord::Base

  belongs_to :gene

  def self.load_annoations
    idg_config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
    cmg_tier1_config = YAML.load_file("#{Rails.root}/config/cmg_tier1_symbols.yml")
    cmg_tier2_config = YAML.load_file("#{Rails.root}/config/cmg_tier2_symbols.yml")

    genes = {}

    idg_config.each do |gene|
      genes[gene] = {} unless genes.has_key?(gene)
      genes[gene][:idg] = true
    end

    cmg_tier1_config.each do |gene|
      genes[gene] = {} unless genes.has_key?(gene)
      genes[gene][:cmg_tier1] = true
    end

    cmg_tier2_config.each do |gene|
      genes[gene] = {} unless genes.has_key?(gene)
      genes[gene][:cmg_tier2] = true
    end

    genes.each do |gene, params|
      search_for_gpa_model = Gene::PrivateAnnotation.joins(:gene).where("marker_symbol = '#{gene}'")
      next if search_for_gpa_model.blank? || search_for_gpa_model.length > 1
      gpa = Gene::PrivateAnnotation.find(search_for_gpa_model.first.id)
      gpa.update_attributes(params)
    end
  end

end

# == Schema Information
#
# Table name: gene_private_annotations
#
#  id        :integer          not null, primary key
#  gene_id   :integer          not null
#  idg       :boolean          default(FALSE)
#  cmg_tier1 :boolean          default(FALSE)
#  cmg_tier2 :boolean          default(FALSE)
#
