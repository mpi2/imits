class TargRep::TargetedAllele < TargRep::Allele
  include TargRep::Allele::CassetteValidation
  include TargRep::Allele::FeatureValidation

  validates :homology_arm_start, :presence => true
  validates :homology_arm_end,   :presence => true
  validates :cassette,           :presence => true
  validates :cassette_type,      :presence => true
  validates :cassette_start,     :presence => true
  validates :cassette_end,       :presence => true

  validates_uniqueness_of :project_design_id,
    :scope => [
      :gene_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ],
    :message => "must have unique design features"

  after_save :check_and_set_type

  def missing_fields?
    assembly.blank? ||
    chromosome.blank? ||
    strand.blank? ||
    mutation_type.blank? ||
    homology_arm_start.blank? ||
    homology_arm_end.blank? ||
    cassette_start.blank? ||
    cassette_end.blank?
  end

  def self.targeted_allele?; true; end

  protected
    def check_and_set_type
      if mutation_type.gene_trap?
        update_attribute(:type, 'TargRep::GeneTrap')
      end
    end
end

# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                             :integer          not null, primary key
#  gene_id                        :integer
#  assembly                       :string(255)      default("GRCm38"), not null
#  chromosome                     :string(2)        not null
#  strand                         :string(1)        not null
#  homology_arm_start             :integer
#  homology_arm_end               :integer
#  loxp_start                     :integer
#  loxp_end                       :integer
#  cassette_start                 :integer
#  cassette_end                   :integer
#  cassette                       :string(100)
#  backbone                       :string(100)
#  subtype_description            :string(255)
#  floxed_start_exon              :string(255)
#  floxed_end_exon                :string(255)
#  project_design_id              :integer
#  reporter                       :string(255)
#  mutation_method_id             :integer
#  mutation_type_id               :integer
#  mutation_subtype_id            :integer
#  cassette_type                  :string(50)
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  intron                         :integer
#  type                           :string(255)      default("TargRep::TargetedAllele")
#  has_issue                      :boolean          default(FALSE), not null
#  issue_description              :text
#  sequence                       :text
#  taqman_critical_del_assay_id   :string(255)
#  taqman_upstream_del_assay_id   :string(255)
#  taqman_downstream_del_assay_id :string(255)
#  wildtype_oligos_sequence       :string(255)
#  private                        :boolean          default(FALSE), not null
#  production_centre_id           :integer
#
