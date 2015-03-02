# encoding: utf-8

class Public::PhenotypeAttempt


  PHENOTYPE_ATTEMPT_MAM_FIELDS = {:exclude => ["cre_excision", "deleter_strain_id", "status_id", "colony_background_strain_id", "rederivation_started", "rederivation_complete", "report_to_public", "is_active", "phenotype_attempt_id", "created_at", "updated_at"],
                                  :include => ["deleter_strain_name", "colony_name"] + (ColonyQc::QC_FIELDS.map{|a| "#{a}_result"})}
  PHENOTYPE_ATTEMPT_PP_FIELDS = {:exclude => ["id", "mi_plan_id", "mouse_allelle_mod_id", "colony_background_strain_id" "status_id", "parent_colony_id", "colony_name", "report_to_public", "is_active", "phenotype_attempt_id", "created_at", "updated_at"],
                                 :include => []}

  @@phenotype_attempt_fields = []

  (MouseAlleleMod.column_names - PHENOTYPE_ATTEMPT_MAM_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_MAM_FIELDS[:include]).each do |field|
    define_method("#{field}=") do |arg|
      MouseAlleleMod.columns_hash['id'].type
      instance_variable_set("@#{field}",arg)
    end

    define_method("#{field}") do
      if !instance_variable_get("@#{field}").blank?
        return instance_variable_get("@#{field}")
      elsif !mouse_allele_mod.blank?
        mouse_allele_mod.send("#{field}")
      else
        nil
      end
    end

    @@phenotype_attempt_fields << field
  end


  (PhenotypingProduction.column_names - PHENOTYPE_ATTEMPT_PP_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_PP_FIELDS[:include]).each do |field|
    define_method("#{field}=") do |arg|
      instance_variable_set("@#{field}",arg)
    end

    define_method("#{field}") do
      if !instance_variable_get("@#{field}").blank?
        return instance_variable_get("@#{field}")
      elsif !linked_phenotyping_production.blank?
        linked_phenotyping_production.send("#{field}")
      else
        nil
      end
    end

    @@phenotype_attempt_fields << field
  end


  def initialize(params)
    @new_record = false
    @errors = ActiveModel::Errors.new(PhenotypeAttempt)

    if  params.has_key?(:mouse_allele_mod_id) ||  params.has_key?(:phenotyping_production_id)
      @mam = nil
      @pp = nil
      if params.has_key?(:mouse_allele_mod_id)
        mam = MouseAlleleMod.find(params[:mouse_allele_mod_id])
        raise "invalid mouse_allele_mod" if mam.blank?
        @mam = mam
        @pp = @mam.colony.phenotyping_productions
      else
        pp = PhenotypingProduction.where("id = #{params[:phenotyping_production_id]}")
        raise "invalid phenotyping_production" if pp.blank?
        @mam = pp.first.parent_colony.try(:mouse_allele_mod)
        @pp = @mam.try(:colony).try(:phenotyping_productions) || pp
      end
    else
      @mam = MouseAlleleMod.new
      @pp =  PhenotypingProduction.new
      @new_record = true
    end

  end

  def mouse_allele_mod
    return @mam if @mam
    return nil
  end

  def phenotyping_productions
    return @pp if @pp
    return nil
  end

  def linked_phenotyping_production
    return @linked_phenotyping_production unless @linked_phenotyping_production.blank?
    if mouse_allele_mod.blank?
      pp = phenotyping_productions
    else
      pp = PhenotypingProduction.joins(mi_plan: [:consortium, :production_centre]).where("parent_colony_id = #{self.mouse_allele_mod.colony.id} AND consortia.name = '#{self.mouse_allele_mod.consortium_name}' AND centres.name = '#{self.mouse_allele_mod.production_centre_name}'")
    end
    if pp.count > 1 or pp.count == 0
      return nil
    else
      @linked_phenotyping_production = PhenotypingProduction.find(pp.first.id)
      return @linked_phenotyping_production
    end
  end

   def phenotyping_productions_attributes
     return @phenotyping_productions_attributes.as_json unless @phenotyping_productions_attributes.nil?
     return phenotyping_productions.as_json(:except => [:created_at, :updated_at, :status_id, :phenotype_attempt_id, :parent_colony_id, :colony_background_strain_id], :methods => [:consortium_name, :production_centre_name, :parent_colony_name, :status_name, :colony_background_strain_name])
   end

   def phenotyping_productions_attributes=(arg)
     @phenotyping_productions_attributes = []

     if arg.is_a?(Array) && !arg.blank? && arg.all?{|a| a.is_a?(Hash)}
       @phenotyping_productions_attributes=arg
     end

     return @phenotyping_productions_attributes
   end


  def mi_attempt_colony_name
    return @parent_colony_name unless @parent_colony_name.blank?
    return mouse_allele_mod.parent_colony.name if !mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.name if !linked_phenotyping_production.blank?
  end

  def mi_attempt_colony_name=(arg)
    colonies = Colony.where("name = '#{arg}' and mi_attempt_id IS NOT NULL")
    if colonies.length == 1
      @parent_colony_name = colonies.first
    end
  end

  def deleter_strain_excision_type
    return nil if mouse_allele_mod.blank?
    return mouse_allele_mod.deleter_strain_excision_type
  end

  def colony_background_strain_name
    return @colony_background_strain_name unless @colony_background_strain_name.blank?
    return mouse_allele_mod.colony_background_strain_name if !mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_background_strain_name if !linked_phenotyping_production.blank?
  end

  def colony_background_strain_name=(arg)
    @colony_background_strain_name = arg
  end


  def rederivation_started
    return @rederivation_started unless @rederivation_started.blank?
    return mouse_allele_mod.rederivation_started if !mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_started if !linked_phenotyping_production.blank?
  end

  def rederivation_started=(arg)
    @rederivation_started = arg
  end

  def rederivation_complete
    return @rederivation_complete unless @rederivation_complete.blank?
    return mouse_allele_mod.rederivation_complete if !mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_complete if !linked_phenotyping_production.blank?
  end

  def rederivation_complete=(arg)
    @rederivation_complete = arg
  end

  def cre_excision_required
    return excision_required if deleter_strain_excision_type.blank?
    return deleter_strain_excision_type == 'Cre'
  end

  def flp_excision_required
    return false if deleter_strain_excision_type.blank?
    return deleter_strain_excision_type == 'Flp'
  end

  def flp_cre_excision_required
    return false if deleter_strain_excision_type.blank?
    return deleter_strain_excision_type == 'Flp-Cre'
  end

  def cre_excisio_required=(arg)
    excision_required = arg
  end

  def excision_required
    if new_record?
      return true if @excision_required.blank?
      return @excision_required
    end

    if !mouse_allele_mod.blank?
      return true if @excision_required.blank?
      return @excision_required
    end

    return false if @excision_required.blank?
    return @excision_required
  end

  def excision_required=(arg)
    @excision_required = (arg == true)
  end

  def status_name
    return nil if mouse_allele_mod.blank? && phenotyping_productions.blank?
    return phenotyping_productions.first.status_name if mouse_allele_mod.blank?
    return mouse_allele_mod.status_name if phenotyping_productions.blank?

    statuses = [{:status_name => mouse_allele_mod.status.name, :status_order_by => mouse_allele_mod.status.order_by}]
    phenotyping_productions.each{ |pp| statuses << {:status_name => pp.status.name, :status_order_by => pp.status.order_by}}

    statuses = statuses.sort{ |s1, s2| s2[:status_order_by] <=> s1[:status_order_by]}
    return statuses[0][:status_name]
  end

  def set_models_attributes

    if excision_required == false
      @mam = nil if new_record?
      @destroy_mam = true unless mouse_allele_mod.blank?
    else
      @destroy_mam = false if destroy_mam == true
      if mouse_allele_mod.blank?
        @mam = MouseAlleleMod.new
      end
      if !mouse_allele_mod.blank?
        (MouseAlleleMod.column_names - PHENOTYPE_ATTEMPT_MAM_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_MAM_FIELDS[:include]).each do |field|
          mouse_allele_mod.send("#{field}=", self.send("#{field}"))
        end
      end
    end

    phenotyping_productions_attributes.each do |pp_attributes|
      pp = nil
      phenotyping_productions.each{|p| pp = p if p.id == pp_attributes['id']}
      if pp.blank?
        pp = PhenotypingProduction.new
        phenotyping_productions << pp
      end
      pp_attributes.each do |patr, pval|
        pp[patr] = pval
      end
    end

    if !linked_phenotyping_production.blank?
      (PhenotypingProduction.column_names - PHENOTYPE_ATTEMPT_PP_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_PP_FIELDS[:include]).each do |field|
        !linked_phenotyping_production.send("#{field}=", self.send("#{field}"))
      end
    end
  end


  def destroy_mam
    @destroy_mam || false
  end

  def new_record?
    @new_record
  end

  def errors
    @errors
  end

  def valid?
    set_models_attributes

    if !mouse_allele_mod.blank? && mouse_allele_mod.valid? == false
      mouse_allele_mod.errors.messages.each{|error, message| errors.add("phenotype attempt #{error}", message)}
      return false
    end

    phenotyping_productions.each do |pp|
      if pp.valid? == false
        pp.errors.messages.each{|error, message| errors.add("phenotype attempt #{error}", message)}
        return false
      end
    end

    return true
  end

  def save
    mouse_allele_mod.reload
    phenotyping_productions.each{|pp| pp.reload}
    linked_phenotyping_production.try(:reload)

    return false unless valid?

    mouse_allele_mod.save if mouse_allele_mod.changed?
    linked_phenotyping_production.save if linked_phenotyping_production.changed?
    phenotyping_productions.each{|pp| pp.save if pp.changed?}

    reload
  end

  def reload
    mouse_allele_mod.reload
    phenotyping_productions.each{|pp| pp.reload}
    linked_phenotyping_production.try(:reload)


    instance_variable_names.each do |iv|
      instance_variable_set(iv, nil) if self.class.column_names.member?(iv.gsub('@', ''))
    end
  end
# CLASS METHODS

  def self.find(id)
    mam = MouseAlleleMod.find_by_phenotype_attempt_id(id)
    return self.new({:mouse_allele_mod_id => mam.id}) if mam
    pp = PhenotypingProduction.joins(:parent_colony).where("phenotyping_productions.phenotype_attempt_id = #{id} AND colonies.mi_attempt_id IS NOT NULL")
    # should return either 1 record or none
    return self.new({:phenotyping_production_id => pp.first.id}) if pp
    return nil
  end

  def self.find_by_mouse_allele_mod_id(id)
    mam = MouseAlleleMod.find(id)
    return self.new({:mouse_allele_mod_id => mam.id}) if mam
    return nil
  end

  def self.find_by_phenotyping_production_id(id)
    pp = PhenotypingProduction.find(id)
    return self.new({:phenotyping_production_id => pp.id}) if pp
    return nil
  end

  def self.find_by_colony_name(colony_name)
    colony = Colony.where("name = '#{colony_name}' AND mouse_allele_mod_id IS NOT NULL").first
    return self.new({:mouse_allele_mod_id => colony.mouse_allele_mod_id}) unless colony.blank?
    pp = PhenotypingProduction.find_by_colony_name(colony_name)
    return self.new({:phenotyping_production_id => pp.id}) unless pp.blank?
    return nil
  end

  def self.readable_name
    'phenotype attempt'
  end

  def self.column_names
    return @@phenotype_attempt_fields
  end
end
