class TargRep::GenbankFile < ActiveRecord::Base

  TargRep::GenbankFile.include_root_in_json = false

  ##
  ## Associations
  ##

  belongs_to :colony
  belongs_to :allele_genbank_file_collection, :class_name => 'TargRep::AllelesGenbankFileCollection', :foreign_key => 'genbank_file_collection_id'

  ##
  ## Validations
  ##

  validates :file, :presence => true
  validates :sequence_type, :presence => true, :inclusion => { :in => ['clone', 'cre_excised_clone', 'flp_excised_clone', 'flp_cre_excised_clone', 'targeting_vector', 'cassette'] }
  
  validate do |gbk|
    if !gbk.allele_genbank_file_collection.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM targ_rep_genbank_files  WHERE targ_rep_genbank_files.sequence_type = '#{self.sequence_type}' AND targ_rep_genbank_files.genbank_file_collection_id IS NOT NULL AND targ_rep_genbank_files.genbank_file_collection_id = #{self.genbank_file_collection_id} #{self.id.blank? ? '' : "AND targ_rep_genbank_files.id != #{self.id}"} LIMIT 1")
      gbk.errors.add :genbank_file, "for #{self.sequence_type} has already been provided." if not_uniq_col.count > 0
    end

    if !gbk.colony.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM targ_rep_genbank_files  WHERE targ_rep_genbank_files.sequence_type = '#{self.sequence_type}' AND targ_rep_genbank_files.colony_id IS NOT NULL AND targ_rep_genbank_files.colony_id = #{self.colony_id} #{self.id.blank? ? '' : "AND targ_rep_genbank_files.id != #{self.id}"} LIMIT 1")
      gbk.errors.add :genbank_file, "for #{self.sequence_type} has already been provided." if not_uniq_col.count > 0
    end
  end

end

# == Schema Information
#
# Table name: targ_rep_genbank_files
#
#  id                         :integer          not null, primary key
#  genbank_file_collection_id :integer
#  colony_id                  :integer
#  sequence_type              :string(255)
#  file                       :text
#  image                      :binary
#  simple_image               :binary
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
