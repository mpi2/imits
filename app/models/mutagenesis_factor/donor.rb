class MutagenesisFactor::Donor < ActiveRecord::Base
  acts_as_audited
  extend AccessAssociationByAttribute

  attr_accessible :mutagenesis_factor_id, :vector_name, :oligo_sequence_fa, :concentration, :preparation

  belongs_to :mutagensis_factor
  belongs_to :vector, :class_name => 'TargRep::TargetingVector'

  before_validation :set_preparation_when_oligo_sequence_is_set

  validate do |donor|
    if donor.preparation == 'Oligo' && oligo_sequence_fa.blank?
      donor.errors.add :oligo_sequence_fa, "cannot be blank when donor preparation has been ser to 'Oligo'"
    end
  end

  validate do |donor|
    if !oligo_sequence_fa.blank? && donor.preparation != 'Oligo'
      donor.errors.add :preparation, "must be set to 'Oligo' when a 'Oligo Sequence' has been provided"
    end
  end

  PREPARATION = ['', 'Circular', 'Linearized', 'Supercoiled', 'Oligo'].freeze

  access_association_by_attribute :vector, :name


  def set_preparation_when_oligo_sequence_is_set
  	return if oligo_sequence_fa.blank? || !preparation.blank?
    preparation = 'Oligo'
  end
  private :set_preparation_when_oligo_sequence_is_set
end

# == Schema Information
#
# Table name: mutagenesis_factor_donors
#
#  id                    :integer          not null, primary key
#  mutagenesis_factor_id :integer          not null
#  vector_id             :integer
#  concentration         :float
#  preparation           :string(255)
#  oligo_sequence_fa     :text
#
