# encoding: utf-8

module MiAttempt::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(MiAttempt)

  ss.add('Micro-injection in progress') { |mi| true }

  ss.add('Chimeras/Founder obtained') do |mi|
    (mi.es_cell? and mi.total_male_chimeras.to_i > 0) or (mi.crispr? and (mi.mutagenesis_factor.no_nhej_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_deletion_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_hr_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_hdr_g0_mutants.to_i > 0))
  end

  ss.add('Chimeras obtained') do |mi|
    mi.es_cell? and mi.total_male_chimeras.to_i > 0
  end


  ss.add('Founder obtained') do |mi|
    mi.crispr? and (mi.mutagenesis_factor.no_nhej_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_deletion_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_hr_g0_mutants.to_i > 0 || mi.mutagenesis_factor.no_hdr_g0_mutants.to_i > 0)
  end


  ss.add('Genotype confirmed', 'Chimeras/Founder obtained') do |mi|

    if !mi.crispr? && !mi.es_cell?
      false
    elsif mi.es_cell?
      if mi.production_centre.try(:name) == 'WTSI'
        mi.colonies.any?{ |c| c.is_released_from_genotyping?}
      else
        mi.number_of_het_offspring.to_i != 0 or mi.number_of_chimeras_with_glt_from_genotyping.to_i != 0
      end
    else mi.crispr?
      if mi.production_centre.try(:name) == 'WTSI'
        mi.colonies.any?{ |c| c.is_released_from_genotyping? && c.genotype_confirmed}
      else
        mi.colonies.any?{|c| c.genotype_confirmed}
      end
    end
  end


  ss.add('Micro-injection aborted') do |mi|
    ! mi.is_active?
  end

  included do
    @@status_manager = ss
    cattr_reader :status_manager
  end

  def change_status
    self.status = MiAttempt::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

  def crispr?
    self.es_cell_id.blank? and !self.mutagenesis_factor_id.blank?
  end

  def es_cell?
    !self.es_cell_id.blank? and self.mutagenesis_factor_id.blank?
  end
end
