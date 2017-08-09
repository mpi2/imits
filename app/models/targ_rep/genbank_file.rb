class TargRep::GenbankFile < ActiveRecord::Base

  attr_accessor :nested

  TargRep::GenbankFile.include_root_in_json = false

  ##
  ## Associations
  ##

  has_many :allele, :class_name => ::Allele, :dependent => :nullify
  
  has_one :es_cell_allele_design, :class_name => TargRep::Allele, :foreign_key => 'allele_genbank_file_id', :dependent => :nullify
  has_one :vector_allele_design, :class_name => TargRep::Allele, :foreign_key => 'vector_genbank_file_id', :dependent => :nullify

  def targ_rep_allele_design
    es_cell_allele_design unless es_cell_allele_design.blank?
    vector_allele_design unless vector_allele_design.blank?
    return nil
  end

  def apply_cre
    return TargRep::GenbankFile.site_specific_recombination(self.file_gb, 'apply_cre')
  end

  def apply_flp
    return TargRep::GenbankFile.site_specific_recombination(self.file_gb, 'apply_flp')
  end

  def apply_flp_cre
    return TargRep::GenbankFile.site_specific_recombination(self.file_gb, 'apply_flp_cre')
  end


  def self.site_specific_recombination(genbank_file, flag)
    require "open3"
    if !genbank_file.blank?
      Open3.popen3("#{GENBANK_RECOMBINATION_SCRIPT_PATH} --#{flag}") do |std_in, std_out, std_err|
        std_in.write(genbank_file)
        std_in.close_write
        std_err_out = std_err.read
        if std_err_out.present?
          raise "Error during recombination: #{std_err_out}"
        else
          return TargRep::GenbankFile.new({:file_gb => std_out.read})
        end
      end
    else
      raise "Error: No Genbank File Found"
    end
  end

end

# == Schema Information
#
# Table name: targ_rep_genbank_files
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  file_gb    :text
#
