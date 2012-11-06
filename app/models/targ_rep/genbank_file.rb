class TargRep::GenbankFile < ActiveRecord::Base

  attr_accessor :nested

  TargRep::GenbankFile.include_root_in_json = false

  ##
  ## Associations
  ##

  belongs_to :allele, :class_name => "TargRep::Allele"

  ##
  ## Validations
  ##

  validates :allele_id,
    :presence => true,
    :uniqueness => true,
    :unless => :nested

  def escell_clone_cre
    return site_specific_recombination(self.escell_clone, 'apply_cre')
  end

  def targeting_vector_cre
    return site_specific_recombination(self.targeting_vector, 'apply_cre')
  end

  def escell_clone_flp
    return site_specific_recombination(self.escell_clone, 'apply_flp')
  end

  def targeting_vector_flp
    return site_specific_recombination(self.targeting_vector, 'apply_flp')
  end

  def escell_clone_flp_cre
    return site_specific_recombination(self.escell_clone, 'apply_flp_cre')
  end

  def targeting_vector_flp_cre
    return site_specific_recombination(self.targeting_vector, 'apply_flp_cre')
  end

private
  def site_specific_recombination(genbank_file, flag)
    require "open3"
    if !genbank_file.blank?
      Open3.popen3("#{GENBANK_RECOMBINATION_SCRIPT_PATH} --#{flag}") do |std_in, std_out, std_err|
        std_in.write(genbank_file)
        std_in.close_write
        std_err_out = std_err.read
        if std_err_out.present?
          raise "Error during recombination: #{std_err_out}"
        else
          return std_out.read
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
#  id               :integer         not null, primary key
#  allele_id        :integer         not null
#  escell_clone     :text
#  targeting_vector :text
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  genbank_files_allele_id_fk  (allele_id)
#

