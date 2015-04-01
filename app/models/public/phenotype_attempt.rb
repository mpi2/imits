# encoding: utf-8

class Public::PhenotypeAttempt
  class << self
#    include ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
#    def parent
#      Public
#    end

  end


  PHENOTYPE_ATTEMPT_MAM_FIELDS = {:exclude => ["id", "cre_excision", "deleter_strain_id", "status_id", "colony_background_strain_id", "rederivation_started", "rederivation_complete", "report_to_public", "is_active", "phenotype_attempt_id", "created_at", "updated_at"],
                                  :include => ["deleter_strain_name"] + (ColonyQc::QC_FIELDS.map{|a| "#{a}_result"})}
  PHENOTYPE_ATTEMPT_PP_FIELDS = {:exclude => ["id", "mi_plan_id", "mouse_allelle_mod_id", "colony_background_strain_id" "status_id", "parent_colony_id", "colony_name", "report_to_public", "is_active", "phenotype_attempt_id", "created_at", "updated_at"],
                                 :include => []}

  READABLE_ATTRIBUTES = {
      :methods => [:id, :status_name, :mi_attempt_colony_name, :colony_name, :production_centre_name, :consortium_name, :marker_symbol, :rederivation_started, :rederivation_complete, :distribution_centres_formatted_display, :is_active, :report_to_public ]
  }

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
      if defined? !instance_variable_get("@#{field}")
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
    @errors = ActiveModel::Errors.new(Public::PhenotypeAttempt)

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
      if params.has_key?(:mi_plan)
        @mam = MouseAlleleMod.new(:mi_plan => params[:mi_plan])
      else
        @mam = MouseAlleleMod.new
      end
      @linked_phenotyping_production = PhenotypingProduction.new
      @new_record = true
      attributes.each{|attr| attr = nil}
    end
  end

  def id
    return mouse_allele_mod.phenotype_attempt_id unless mouse_allele_mod.blank?
    return linked_phenotyping_production.phenotype_attempt_id unless linked_phenotyping_production.blank?
    nil
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


  def colony_name
    return @colony_name if defined? @colony_name
    return mouse_allele_mod.colony.name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_name
  end

  def colony_name=(arg)
    @colony_name = arg
  end

  def consortium_name
    return @consortium_name if defined? @consortium_name
    return mouse_allele_mod.consortium_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.consortium_name
  end

  def consortium_name=(arg)
    @consortium_name = arg
  end

  def production_centre_name
    return @production_centre_name if defined? @production_centre_name
    return mouse_allele_mod.production_centre_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.production_centre_name
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end


  def mi_attempt_colony_name
    return @parent_colony_name if defined? @parent_colony_name
    return mouse_allele_mod.parent_colony.name if !mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.name if !linked_phenotyping_production.blank?
  end

  def mi_attempt_colony_name=(arg)
    colonies = Colony.where("name = '#{arg}' and mi_attempt_id IS NOT NULL")
    if colonies.length == 1
      @parent_colony_name = colonies.first
    end
  end

  def mi_attempt
    return nil if new_record?
    return mouse_allele_mod.parent_colony.mi_attempt if !mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.mi_attempt if !linked_phenotyping_production.blank?
  end

  def deleter_strain_excision_type
    return nil if mouse_allele_mod.blank?
    return mouse_allele_mod.deleter_strain_excision_type
  end

  def colony_background_strain_name
    return @colony_background_strain_name if defined? @colony_background_strain_name
    return mouse_allele_mod.colony_background_strain_name if !mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_background_strain_name if !linked_phenotyping_production.blank?
  end

  def colony_background_strain_name=(arg)
    @colony_background_strain_name = arg
  end


  def rederivation_started
    return @rederivation_started if defined? @rederivation_started
    return mouse_allele_mod.rederivation_started if !mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_started if !linked_phenotyping_production.blank?
  end

  def rederivation_started=(arg)
    @rederivation_started = arg
  end

  def rederivation_complete
    return @rederivation_complete if defined? @rederivation_complete
    return mouse_allele_mod.rederivation_complete if !mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_complete if !linked_phenotyping_production.blank?
  end

  def rederivation_complete=(arg)
    @rederivation_complete = arg
  end

  def is_active
    return @active unless @active.blank?
    return mouse_allele_mod.is_active unless mouse_allele_mod.blank?
    return linked_phenotyping_production.is_active
  end

  def is_active=(arg)
    return if ['true', 'false'].include?(arg.to_s)
    @is_active = arg
  end

  def report_to_public
    return @report_to_public if defined? @report_to_public
    return mouse_allele_mod.report_to_public unless mouse_allele_mod.blank?
    return linked_phenotyping_production.report_to_public
  end

  def report_to_public=(arg)
    return if ['true', 'false'].include?(arg.to_s)
    @report_to_public = arg
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


  def registered_at
    return nil if mouse_allele_mod.blank?
    return @rederivation_complet_at unless @rederivation_complet_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 1").try(:first).try(:created_at)
  end

  def registered_at=(arg)
  end

  def rederivation_started_at
    return nil if mouse_allele_mod.blank?
    return @rederivation_complet_at unless @rederivation_complet_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 3").try(:first).try(:created_at)
  end

  def rederivation_started_at=(arg)
  end

  def rederivation_complet_at
    return nil if mouse_allele_mod.blank?
    return @rederivation_complet_at unless @rederivation_complet_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 4").try(:first).try(:created_at)
  end

  def rederivation_complet_at=(arg)
  end

  def cre_excision_started_at
    return nil if mouse_allele_mod.blank?
    return @cre_excision_started_at unless @cre_excision_started_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 5").try(:first).try(:created_at)
  end

  def cre_excision_started_at=(arg)
  end

  def cre_excision_complete_at
    return nil if mouse_allele_mod.blank?
    return @cre_excision_started_at unless @cre_excision_started_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 6").try(:first).try(:created_at)
  end

  def cre_excision_complete_at=(arg)
  end

  def phenotyping_started_at
    phenotyping_productions.map{|pp| pp.status_stamps.where("status_id = 3").try(:first).try(:created_at)}.select(&:present?).min
  end

  def phenotyping_complete_at
    phenotyping_productions.map{|pp| pp.status_stamps.where("status_id = 4").try(:first).try(:created_at)}.select(&:present?).min
  end

  def status_name
    return nil if (mouse_allele_mod.blank? && phenotyping_productions.blank?) || new_record?
    return translate_status_name(phenotyping_productions.first.status_name) if mouse_allele_mod.blank?
    return translate_status_name(mouse_allele_mod.status_name) if phenotyping_productions.blank?

    statuses = [{:status_name => translate_status_name(mouse_allele_mod.status.name), :status_order_by => mouse_allele_mod.status.order_by}]
    phenotyping_productions.each{ |pp| statuses << {:status_name => translate_status_name(pp.status.name), :status_order_by => pp.status.order_by}}

    statuses = statuses.sort{ |s1, s2| s2[:status_order_by] <=> s1[:status_order_by]}
    return statuses[0][:status_name]
  end

  def mouse_allele_symbol_superscript
    return nil if new_record?
    return mouse_allele_mod.colony.allele_symbol_superscript if mouse_allele_mod
    return mi_attempt.colony.allele_symbol_superscript if linked_phenotyping_production
  end


  def translate_status_name(status_name)
    return nil if status_name.blank?
    return 'Phenotype Attempt Aborted' if status_name =~ /Aborted/
    return 'Phenotype Attempt Registered' if status_name =~ /Registered/
    return status_name
  end

  def marker_symbol
    return mouse_allele_mod.mi_plan.gene.marker_symbol if !mouse_allele_mod.blank? && !mouse_allele_mod.mi_plan.blank?
    return linked_phenotyping_production.mi_plan.gene.marker_symbol if !linked_phenotyping_production.blank? && !linked_phenotyping_production.mi_plan.blank?
  end

  def distribution_centres_formatted_display
    return mouse_allele_mod.distribution_centres_formatted_display unless mouse_allele_mod.blank?
    return []
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
    @errors = ActiveModel::Errors.new(PhenotypeAttempt)
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

  def update_attributes(attr)
    return false if attr.blank?

    attr.each do |key, value|
      begin
        self.method("#{key}=")
        self.send("#{key}=".to_sym, value)
      rescue
        next
      end
    end
    self.save
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
    return true
  end

  def reload
    mouse_allele_mod.reload
    phenotyping_productions.each{|pp| pp.reload}
    linked_phenotyping_production.try(:reload)


    instance_variable_names.each do |iv|
      instance_variable_set(iv, nil) if self.class.column_names.member?(iv.gsub('@', ''))
    end
  end

  def attributes
    exclude = READABLE_ATTRIBUTES[:exclude] || []
    attrs = {}
    @@phenotype_attempt_fields.each do |attr|
      attrs[attr] = self.send(attr) unless exclude.include?(attr)
    end

    READABLE_ATTRIBUTES[:methods].each do |attr|
      attrs[attr] = self.send(attr) unless exclude.include?(attr)
    end

    return attrs
  end

# CLASS METHODS

  def self.find(id)
    puts "ID: #{id}"
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
