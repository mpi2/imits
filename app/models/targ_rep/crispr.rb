class TargRep::Crispr < ActiveRecord::Base
  acts_as_audited

  attr_accessible :name, :gene_id

  belongs_to :genes

  validates :name, :presence => true, :uniqueness => true
  validates :gene_id, :presence => true

end


# == Schema Information
#
# Table name: targ_rep_crisprs
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  gene_id    :integer         not null
#  created_at :datetime
#

