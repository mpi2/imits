class Strain < ActiveRecord::Base
  acts_as_reportable
  validates :name, :uniqueness => true, :presence => true

  validates_format_of :mgi_strain_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true,
    :allow_blank => true

  def pretty_drop_down
    if !self.mgi_strain_accession_id.blank?
      return "#{self.mgi_strain_accession_id}:#{self.name}"
    else
      return self.name
    end
  end
end

# == Schema Information
#
# Table name: strains
#
#  id                      :integer          not null, primary key
#  name                    :string(100)      not null
#  created_at              :datetime
#  updated_at              :datetime
#  mgi_strain_accession_id :string(100)
#  mgi_strain_name         :string(100)
#
# Indexes
#
#  index_strains_on_name  (name) UNIQUE
#
