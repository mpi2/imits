class TargRep::Crispr < ActiveRecord::Base
  acts_as_audited

  attr_accessible :mutagensis_factor_id, :sequence, :chr, :start, :end, :grna_conentration

  belongs_to :mutagenesis_factor, :inverse_of => :crisprs

  before_validation :upper_case_sequence

  validates_uniqueness_of :sequence, :scope => [:mutagenesis_factor_id]
  validates_presence_of :mutagenesis_factor
  validates_format_of :sequence,
      :with       => /^[ACGT]+$/i,
      :message    => "must consist of a sequence of 'A', 'C', 'G' or 'T'"
  validates :start, :numericality => {:only_integer => true, :greater_than => 0}
  validates :end, :numericality => {:only_integer => true, :greater_than => 0}
  validates_length_of :sequence,
     :is => 23


  def upper_case_sequence
    self.sequence = self.sequence.upcase if !self.sequence.blank?
  end
  protected :upper_case_sequence
end

# == Schema Information
#
# Table name: targ_rep_crisprs
#
#  id                    :integer          not null, primary key
#  mutagenesis_factor_id :integer          not null
#  sequence              :string(255)      not null
#  chr                   :string(255)
#  start                 :integer
#  end                   :integer
#  created_at            :datetime
#  grna_conentration     :float
#
