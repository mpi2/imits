class TargRep::TargetingVector < ActiveRecord::Base

  acts_as_audited

  attr_accessor :nested

  ##
  ## Associations
  ##

  belongs_to :pipeline
  belongs_to :allele
  belongs_to :ikmc_project, :class_name => "TargRep::IkmcProject", :foreign_key => :ikmc_project_foreign_id
  has_many :mutagenesis_factors

  has_many :es_cells

  accepts_nested_attributes_for :es_cells, :allow_destroy => true

  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => true,
    :presence => true

 # validates :pipeline, :presence => true
  validates :allele, :presence => {:unless => :nested}

  ##
  ## Filters
  ##
  before_destroy :check_for_vector_usages

  before_save :set_mirko_ikmc_project_id

  before_save do
    self.report_to_public = true if self.report_to_public.nil?
  end

  ##
  ## Methods
  ##

  public

    def to_json( options = {} )
      TargRep::TargetingVector.include_root_in_json = false
      super options
    end

    def to_xml( options = {} )
      options.update(
        :skip_types => true
      )
      super options
    end

    def report_to_public?
      self.report_to_public
    end

  protected
    # Set mirKO ikmc_project_ids to "mirKO#{self.allele_id}"
    def set_mirko_ikmc_project_id
      if (self.ikmc_project_id.blank? or self.ikmc_project_id =~ /^mirko$/i) and self.pipeline.try(:name) == "mirKO"
        self.ikmc_project_id = "mirKO#{ self.allele_id }"
      end
    end

    def check_for_vector_usages
      unless es_cells.blank? && mutagenesis_factors.blank?
         self.errors.add :base, 'Cannot Delete .ES Cell(s) have been created from this Targeting Vector.' unless es_cells.blank?
         self.errors.add :base, 'Cannot Delete .This Targeting Vector has been used in a Mi Attempt.' unless mutagenesis_factors.blank?
        return false
      end
      return true
    end

end

# == Schema Information
#
# Table name: targ_rep_targeting_vectors
#
#  id                            :integer          not null, primary key
#  allele_id                     :integer          not null
#  name                          :string(255)      not null
#  ikmc_project_id               :string(255)
#  intermediate_vector           :string(255)
#  report_to_public              :boolean          not null
#  pipeline_id                   :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  ikmc_project_foreign_id       :integer
#  mgi_allele_name_prediction    :string(40)
#  allele_type_prediction        :string(10)
#  production_centre_auto_update :boolean          default(TRUE), not null
#
# Indexes
#
#  index_targvec                     (name) UNIQUE
#  targeting_vectors_allele_id_fk    (allele_id)
#  targeting_vectors_pipeline_id_fk  (pipeline_id)
#
