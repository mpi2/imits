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
  validates :sequence_description, :presence => true, :inclusion => { :in => ['clone', 'cre_excised_clone', 'flp_excised_clone', 'flp_cre_excised_clone', 'targeting_vector'] }
  
  validate do |gbk|
    if !gbk.allele_genbank_file_collection.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM targ_rep_genbank_files  WHERE targ_rep_genbank_files.sequence_description = '#{self.sequence_description}' AND targ_rep_genbank_files.allele_genbank_file_collection IS NOT NULL #{self.id.blank? ? '' : "AND targ_rep_genbank_files.id != #{self.id}"} LIMIT 1")
      gbk.errors.add :genbank_file, "for #{self.sequence_description} has already been provided." if not_uniq_col.count > 0
    end

    if !gbk.colony.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM targ_rep_genbank_files  WHERE targ_rep_genbank_files.sequence_description = '#{self.sequence_description}' AND targ_rep_genbank_files.colony_id IS NOT NULL #{self.id.blank? ? '' : "AND targ_rep_genbank_files.id != #{self.id}"} LIMIT 1")
      gbk.errors.add :genbank_file, "for #{self.sequence_description} has already been provided." if not_uniq_col.count > 0
    end
  end

end

