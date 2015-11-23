class TargRep::GenbankFile < ActiveRecord::Base

  TargRep::GenbankFile.include_root_in_json = false

  ##
  ## Associations
  ##

  belongs_to :colony

  belongs_to :allele_genbank_file_collection, :class_name => 'TargRep::AllelesGenbankFileCollection'

  ##
  ## Validations
  ##

  validates :file, :presence => true

end

