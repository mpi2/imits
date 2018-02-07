class Strain < ActiveRecord::Base
  acts_as_reportable
  attr_accessible :name, :mgi_strain_name, :mgi_strain_accession_id, :background_strain, :test_cross_strain, :blast_strain

  scope :background_strain, where(:background_strain => true)
  scope :test_cross_strain, where(:test_cross_strain => true)
  scope :blast_strain, where(:blast_strain => true)

  validates :name, :uniqueness => true, :presence => true

  validates_format_of :mgi_strain_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true,
    :allow_blank => true

  def pretty_drop_down
    if !self.mgi_strain_accession_id.blank?
      return "#{self.name}:#{self.mgi_strain_accession_id}"
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
#  background_strain       :boolean          default(FALSE)
#  test_cross_strain       :boolean          default(FALSE)
#  blast_strain            :boolean          default(FALSE)
#
# Indexes
#
#  index_strains_on_name  (name) UNIQUE
#
