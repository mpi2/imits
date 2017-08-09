class MutagenesisFactor::Donor < ActiveRecord::Base
  acts_as_audited
  extend AccessAssociationByAttribute

  attr_accessible :mutagenesis_factor_id, :vector_name, :oligo_sequence_fa, :concentration, :preparation

  belongs_to :mutagensis_factor
  belongs_to :vector, :class_name => 'TargRep::TargetingVector'

  PREPARATION = ['', 'Circular', 'Linearized', 'Supercoiled', 'Oligo'].freeze

  access_association_by_attribute :vector, :name

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
