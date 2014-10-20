class TargRep::AlleleSequenceAnnotation < ActiveRecord::Base
  acts_as_audited

  attr_accessible :mutation_type, :genomic_start_coordinate, :genomic_end_coordinate, :expected, :actual, :comment, :oligos_start_coordinate, :oligos_end_coordinate, :mutation_length

  belongs_to :allele

  TYPE = ['Deletion', 'Insertion', 'Substitution'].freeze

  validates_inclusion_of :mutation_type,
    :in => TYPE,
    :message => "Type can only be #{TYPE.to_sentence}"
  validates :genomic_start_coordinate, :numericality => {:only_integer => true, :greater_than_or_equal_to  => 0}, allow_blank: true
  validates :genomic_end_coordinate, :numericality => {:only_integer => true, :greater_than_or_equal_to  => 0}, allow_blank: true
  validates :oligos_start_coordinate, :numericality => {:only_integer => true, :greater_than_or_equal_to  => 0}, allow_blank: true
  validates :oligos_end_coordinate, :numericality => {:only_integer => true, :greater_than_or_equal_to  => 0}, allow_blank: true

end

# == Schema Information
#
# Table name: targ_rep_allele_sequence_annotations
#
#  id                       :integer          not null, primary key
#  mutation_type            :string(255)
#  expected                 :string(255)
#  actual                   :string(255)
#  comment                  :text
#  oligos_start_coordinate  :integer
#  oligos_end_coordinate    :integer
#  mutation_length          :integer
#  genomic_start_coordinate :integer
#  genomic_end_coordinate   :integer
#  allele_id                :integer
#
