class MutagenesisFactor < ActiveRecord::Base
  acts_as_audited

  attr_accessible :name, :gene_id

  has_one :mi_attempt
  has_many :crisprs
  belongs_to :vector

end






# == Schema Information
#
# Table name: mutagenesis_factors
#
#  id            :integer         not null, primary key
#  vector_id     :integer
#  crispr_method :string(255)     not null
#

