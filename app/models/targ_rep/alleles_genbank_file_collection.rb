class TargRep::AllelesGenbankFileCollection < ActiveRecord::Base

  attr_accessor :nested

  TargRep::AllelesGenbankFileCollection.include_root_in_json = false

  ##
  ## Associations
  ##

  belongs_to :allele
  has_one :targeting_vector_genbank_file, :class_name => "TargRep::GenbankFile", :conditions => {:sequence_description => 'targeting_vector'}, :dependent => :destroy
  has_one :clone_genbank_file, :class_name => "TargRep::GenbankFile", :conditions => {:sequence_description => 'clone'}, :dependent => :destroy
  has_one :cre_excised_clone_genbank_file, :class_name => "TargRep::GenbankFile", :conditions => {:sequence_description => 'cre_excised_clone'}, :dependent => :destroy
  has_one :flp_excised_clone_genbank_file, :class_name => "TargRep::GenbankFile", :conditions => {:sequence_description => 'flp_excised_clone'}, :dependent => :destroy
  has_one :flp_cre_excised_clone_genbank_file, :class_name => "TargRep::GenbankFile", :conditions => {:sequence_description => 'flp_cre_excised_clone'}, :dependent => :destroy

  ##
  ## Validations
  ##

  before_save :delete_genbank_files_if_changed
  after_save :create_genbank_file_if_data_present

  validates :allele_id,
    :presence => true,
    :uniqueness => true,
    :unless => :nested


  ##
  ## Before Save Methods
  ##

  def delete_genbank_files_if_changed
    if self.changes.has_key?('escell_clone')
      self.clone_genbank_file.destroy unless self.clone_genbank_file.blank?
      self.cre_excised_clone_genbank_file.destroy unless self.cre_excised_clone_genbank_file.blank?
      self.flp_excised_clone_genbank_file.destroy unless self.flp_excised_clone_genbank_file.blank?
      self.flp_cre_excised_clone_genbank_file.destroy unless self.flp_cre_excised_clone_genbank_file.blank?
      
    end

    if self.changes.has_key?('targeting_vector')
      self.targeting_vector_genbank_file.destroy unless self.targeting_vector_genbank_file.blank?
    end
  end


  ##
  ## After Save Methods
  ##

  def create_genbank_file_if_data_present
    if !escell_clone.blank?
      create_genbank_file(self.clone_genbank_file) = escell_clone if self.clone_genbank_file.blank? && !escell_clone.blank?
      create_genbank_file(self.cre_excised_clone_genbank_file) = escell_clone_cre if self.cre_excised_clone_genbank_file.blank? && !escell_clone_cre.blank?
      create_genbank_file(self.flp_excised_clone_genbank_file) = escell_clone_flp if self.flp_excised_clone_genbank_file.blank? && !escell_clone_flp.blank?
      create_genbank_file(self.flp_cre_excised_clone_genbank_file) = escell_clone_flp_cre if self.flp_cre_excised_clone_genbank_file.blank? && !escell_clone_flp_cre.blank?
    end

    if !targeting_vector.blank?
      self.targeting_vector_genbank_file = targeting_vector if self.targeting_vector_genbank_file
    end

  end


  ##
  ## Instance Methods
  ##

  def escell_clone_cre
    begin
      return site_specific_recombination(self.escell_clone, 'apply_cre')
    rescue
      return nil
    end
  end

  def targeting_vector_cre
    begin
      return site_specific_recombination(self.targeting_vector, 'apply_cre')
    rescue
      return nil
    end
  end

  def escell_clone_flp
    begin
      return site_specific_recombination(self.escell_clone, 'apply_flp')
    rescue
      return nil
    end
  end

  def targeting_vector_flp
    begin
      return site_specific_recombination(self.targeting_vector, 'apply_flp')
    rescue
      return nil
    end
  end

  def escell_clone_flp_cre
    begin
      return site_specific_recombination(self.escell_clone, 'apply_flp_cre')
    rescue
      return nil
    end
  end

  def targeting_vector_flp_cre
    begin
      return site_specific_recombination(self.targeting_vector, 'apply_flp_cre')
    rescue
      return nil
    end
  end

  def cre_excised_genbank_file
    return cre_excised_clone_genbank_file.try(:file)
  end

  def clones_genbank_file
    return cre_excised_clone_genbank_file.try(:file)
  end

  def clones_cre_excised_genbank_file
    return cre_excised_clone_genbank_file.try(:file)
  end

  def clones_flp_excised_genbank_file
    return flp_excised_clone_genbank_file.try(:file)
  end

  def clones_flp_cre_excised_genbank_file
    return flp_cre_excised_clone_genbank_file.try(:file)
  end


private
  def site_specific_recombination(genbank_file, flag)
    require "open3"
    if !genbank_file.blank?
      Open3.popen3("perl -I./script #{GENBANK_RECOMBINATION_SCRIPT_PATH} --#{flag}") do |std_in, std_out, std_err|
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

  def create_genbank_file (genebank_file, sequence_type)
    raise "Genebank File must be provided along with Sequence Type" if genebank_file.blank? || sequence_type.blank?

    begin
      image = AlleleImage2::Image.new(genbank_file, {:mutation_type => allele.mutation_type_name}).render.to_blob { self.format = "PNG" }
    rescue
      image = nil
    end

    begin
      simple_image = AlleleImage2::Image.new(genbank_file, {:mutation_type => allele.mutation_type_name}).render.to_blob { self.format = "PNG" }
    rescue
      simple_image = nil
    end

    begin
      cassette_image = AlleleImage2::Image.new(genbank_file, {:mutation_type => allele.mutation_type_name, :cassetteonly => true}}).render.to_blob { self.format = "PNG" }
    rescue
      cassette_image = nil
    end

    gb = TargRep::GenbankFile.new(:sequence_type => sequence_type, :file => genbank_file, :image => image, :simple_image => simple_image)

    if gb.valid?
      gb.save
    else
      raise 'ERROR: Generating Genbank Files'
    end
  end
    
  end
end

# == Schema Information
#
# Table name: targ_rep_genbank_files
#
#  id                  :integer          not null, primary key
#  allele_id           :integer          not null
#  escell_clone        :text
#  targeting_vector    :text
#  created_at          :datetime
#  updated_at          :datetime
#  allele_genbank_file :text
#
# Indexes
#
#  genbank_files_allele_id_fk  (allele_id)
#
