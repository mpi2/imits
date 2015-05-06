# encoding: utf-8

class Public::PhenotypeAttempt
  class << self
  include ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
    def model_name
      ActiveModel::Name.new(PhenotypeAttempt)
    end

  end


  PHENOTYPE_ATTEMPT_MAM_FIELDS = {:exclude => ["id", "mi_plan_id", "cre_excision", "deleter_strain_id", "status_id", "parent_colony_id", "colony_background_strain_id", "rederivation_started", "rederivation_complete", "report_to_public", "is_active", "phenotype_attempt_id", "cre_excision", "created_at", "updated_at"],
                                  :include => ["deleter_strain_name", "mouse_allele_type", "distribution_centres_attributes"] + (ColonyQc::QC_FIELDS.map{|a| "#{a}_result"})}
  PHENOTYPE_ATTEMPT_PP_FIELDS = {:exclude => ["id", "mi_plan_id", "mouse_allelle_mod_id", "colony_background_strain_id", "rederivation_started", "rederivation_complete", "status_id", "parent_colony_id", "colony_name", "report_to_public", "is_active", "phenotype_attempt_id", "created_at", "updated_at"],
                                 :include => []}

  READABLE_ATTRIBUTES = {
      :methods => [:id, :mi_plan_id, :status_name, :mi_attempt_colony_name, :parent_colony_name, :colony_name, :production_centre_name, :consortium_name, :marker_symbol, :colony_background_strain_name, :colony_background_strain_mgi_name, :colony_background_strain_mgi_accession, :rederivation_started, :rederivation_complete, :distribution_centres_formatted_display, :is_active, :report_to_public, :cre_excision_required, :excision_required, :phenotyping_productions_attributes, :mouse_allele_symbol_superscript, :mouse_allele_symbol, :status_dates]
  }

  @@phenotype_attempt_fields = []

  (MouseAlleleMod.column_names - PHENOTYPE_ATTEMPT_MAM_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_MAM_FIELDS[:include]).each do |field|
    define_method("#{field}=") do |arg|
      MouseAlleleMod.columns_hash['id'].type
      instance_variable_set("@#{field}",arg)
    end

    define_method("#{field}") do
      if ! instance_variable_get("@#{field}").nil?
        return instance_variable_get("@#{field}")
      elsif !mouse_allele_mod.nil?
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
      if !instance_variable_get("@#{field}").nil?
        return instance_variable_get("@#{field}")
      elsif !linked_phenotyping_production.nil?
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
      @new_record = true
      @mam = MouseAlleleMod.new
      @linked_phenotyping_production = PhenotypingProduction.new
      @@phenotype_attempt_fields.each{|attr| if self.class.public_method_defined?("#{attr}="); self.send("#{attr}=",  params.has_key?(attr) ? params[attr.to_sym] : self.send(attr)) ; end   }
      READABLE_ATTRIBUTES[:methods].each{|attr| if self.class.public_method_defined?("#{attr}="); self.send("#{attr}=",  params.has_key?(attr) ? params[attr.to_sym] : self.send(attr)) ; end }
      @mam = nil
      @linked_phenotyping_production = nil
    end
  end

  def id
    return mouse_allele_mod.phenotype_attempt_id unless mouse_allele_mod.blank?
    return linked_phenotyping_production.phenotype_attempt_id unless linked_phenotyping_production.blank?
    return nil
  end

  def mouse_allele_mod
    return @mam if @mam
    return nil
  end

  def phenotyping_productions
    return @pp if @pp
    return []
  end

  def linked_phenotyping_production
    return @linked_phenotyping_production if new_record? || !@linked_phenotyping_production.blank?
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
     return phenotyping_productions.as_json(:except => ["created_at", "updated_at", "status_id", "phenotype_attempt_id", "parent_colony_id", "colony_background_strain_id"], :methods => ["consortium_name", "production_centre_name", "parent_colony_name", "status_name", "colony_background_strain_name"]) unless phenotyping_productions.blank?
     return []
   end

   def phenotyping_productions_attributes=(arg)
     @phenotyping_productions_attributes = []
     if arg.is_a?(Array) && !arg.blank? && arg.all?{|a| a.is_a?(Hash)}
       @phenotyping_productions_attributes = arg
     elsif  arg.is_a?(Hash) && !arg.blank? && arg.all?{|key, value| value.is_a?(Hash)}
       @phenotyping_productions_attributes = arg.map{|key, value| value}
     end

     return @phenotyping_productions_attributes
   end


  def colony_name
    return @colony_name unless @colony_name.nil?
    return mouse_allele_mod.colony_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_name unless linked_phenotyping_production.blank?
    return nil
  end

  def colony_name=(arg)
    @colony_name = arg
  end

  def colony_background_strain_mgi_name
    return mouse_allele_mod.colony_background_strain_mgi_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_background_strain_mgi_name unless linked_phenotyping_production.blank?
    nil
  end

  def colony_background_strain_mgi_accession
    return mouse_allele_mod.colony_background_strain_mgi_accession unless mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_background_strain_mgi_accession unless linked_phenotyping_production.blank?
    nil
  end

  def mi_plan_id=(arg)
    return nil if arg.blank?
    plan = MiPlan.find(arg)
    @mi_plan_id = plan.id
    @consortium_name = plan.consortium_name
    @production_centre_name = plan.production_centre_name
  end

  def mi_plan_id
    return @mi_plan_id unless @mi_plan_id.nil?
    return mouse_allele_mod.mi_plan_id unless mouse_allele_mod.blank?
    return linked_phenotyping_production.mi_plan_id unless linked_phenotyping_production.blank?
    return nil
  end

  def consortium_name
    return @consortium_name unless @consortium_name.nil?
    return mouse_allele_mod.consortium_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.consortium_name unless linked_phenotyping_production.blank?
    return nil
  end

  def consortium_name=(arg)
    @consortium_name = arg
  end

  def production_centre_name
    return @production_centre_name unless @production_centre_name.nil?
    return mouse_allele_mod.production_centre_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.production_centre_name unless linked_phenotyping_production.blank?
    return nil
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end


  def mi_attempt_colony_name
    return @parent_colony_name unless @parent_colony_name.nil?
    return mouse_allele_mod.parent_colony_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony_name unless linked_phenotyping_production.blank?
    return nil
  end

  def parent_colony_name
    mi_attempt_colony_name
  end


  def mi_attempt_colony_name=(arg)
    puts "HELLO: #{arg}"
    colonies = Colony.where("name = '#{arg}' and mi_attempt_id IS NOT NULL")
    if colonies.length == 1
      puts "NOT HERE"
      @parent_colony_name = colonies.first.name
    end
  end

  def mi_attempt
    return nil if new_record?
    return mouse_allele_mod.parent_colony.mi_attempt unless mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.mi_attempt unless linked_phenotyping_production.blank?
  end

  def deleter_strain_excision_type
    return nil if mouse_allele_mod.blank?
    return mouse_allele_mod.deleter_strain_excision_type
  end

  def colony_background_strain_name
    return @colony_background_strain_name unless @colony_background_strain_name.nil?
    return mouse_allele_mod.colony_background_strain_name unless mouse_allele_mod.blank?
    return linked_phenotyping_production.colony_background_strain_name unless linked_phenotyping_production.blank?
    return nil
  end

  def colony_background_strain_name=(arg)
    @colony_background_strain_name = arg
  end


  def rederivation_started
    return @rederivation_started unless @rederivation_started.nil?
    return mouse_allele_mod.rederivation_started unless mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_started unless linked_phenotyping_production.blank?
    return nil
  end

  def rederivation_started=(arg)
    @rederivation_started = arg
  end

  def rederivation_complete
    return @rederivation_complete unless @rederivation_complete.nil?
    return mouse_allele_mod.rederivation_complete unless mouse_allele_mod.blank?
    return linked_phenotyping_production.rederivation_complete unless linked_phenotyping_production.blank?
    return nil
  end

  def rederivation_complete=(arg)
    @rederivation_complete = arg
  end

  def is_active
    return @active unless @active.blank?
    return mouse_allele_mod.is_active unless mouse_allele_mod.blank?
    return linked_phenotyping_production.is_active unless linked_phenotyping_production.blank?
    return true
  end

  def is_active?
    return is_active
  end

  def is_active=(arg)
    return if ['true', 'false'].include?(arg.to_s)
    @is_active = arg
  end

  def report_to_public
    return @report_to_public unless @report_to_public.nil?
    return mouse_allele_mod.report_to_public unless mouse_allele_mod.blank?
    return linked_phenotyping_production.report_to_public unless linked_phenotyping_production.blank?
    return nil
  end

  def report_to_public=(arg)
    return if ['true', 'false'].include?(arg.to_s)
    @report_to_public = arg
  end

  def distribution_centres
    return mouse_allele_mod.distribution_centres unless mouse_allele_mod.blank?
    return []
  end

  def cre_excision_required
    return excision_required unless excision_required.blank?
    return false
  end

  def cre_excision_required=(arg)
    self.excision_required = arg
  end

  def excision_required
    if new_record?
      return true if @excision_required.nil?
      return @excision_required
    end

    if !mouse_allele_mod.blank?
      return true if @excision_required.nil?
      return @excision_required
    end

    return false if @excision_required.nil?
    return @excision_required
  end

  def excision_required=(arg)
    @excision_required = self.class.to_true_or_false(arg)
  end


  def registered_at
    return nil if mouse_allele_mod.blank?
    return @registered_at unless @registered_at.blank?
    mouse_allele_mod.status_stamps.where("status_id = 1").try(:first).try(:created_at)
  end

  def registered_at=(arg)
  end

  def rederivation_started_at
    return @rederivation_started_at unless @rederivation_started_at.blank?
    return mouse_allele_mod.status_stamps.where("status_id = 3").try(:first).try(:created_at) unless mouse_allele_mod.blank?
    return linked_phenotyping_production.status_stamps.where("status_id = 6").try(:first).try(:created_at) unless linked_phenotyping_production.blank?
    return nil
  end

  def rederivation_started_at=(arg)
  end

  def rederivation_complete_at
    return @rederivation_complete_at unless @rederivation_complete_at.blank?
    return mouse_allele_mod.status_stamps.where("status_id = 4").try(:first).try(:created_at) unless mouse_allele_mod.blank?
    return linked_phenotyping_production.status_stamps.where("status_id = 7").try(:first).try(:created_at) unless linked_phenotyping_production.blank?
    return nil
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

  def in_progress_date
    return registered_at   #Phenotype Attempt Registered
  end

  def public_status
    if status_name == 'Cre Excision Complete' and mouse_allele_mod.try(:report_to_public) == false
      return 'Cre Excision Started'
    end
    return status_name
  end

  def status_dates
    status_stamps_dates = {}

    status_stamps_dates['Phenotype Attempt Registered'] = registered_at.to_date unless registered_at.blank?
    status_stamps_dates['Rederivation Started'] = rederivation_started_at.to_date unless rederivation_started_at.blank?
    status_stamps_dates['Rederivation Complete'] = rederivation_complete_at.to_date unless rederivation_complete_at.blank?
    status_stamps_dates['Cre Excision Started'] = cre_excision_started_at.to_date unless cre_excision_started_at.blank?
    status_stamps_dates['Cre Excision Complete'] = cre_excision_complete_at.to_date unless cre_excision_complete_at.blank?
    status_stamps_dates['Phenotyping Started'] = phenotyping_started_at.to_date unless phenotyping_started_at.blank?
    status_stamps_dates['Phenotyping Complete'] = phenotyping_complete_at.to_date unless phenotyping_complete_at.blank?

    return status_stamps_dates.as_json
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
    return mouse_allele_mod.colony.allele_symbol_superscript unless mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.allele_symbol_superscript unless linked_phenotyping_production.blank?
    return nil
  end

  def mouse_allele_symbol
    return nil if new_record?
    return mouse_allele_mod.colony.allele_symbol unless mouse_allele_mod.blank?
    return linked_phenotyping_production.parent_colony.allele_symbol unless linked_phenotyping_production.blank?
    return nil
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
        @mam = MouseAlleleMod.new({})
      end
      if !mouse_allele_mod.blank?
        (MouseAlleleMod.column_names - PHENOTYPE_ATTEMPT_MAM_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_MAM_FIELDS[:include]).each do |field|
          mouse_allele_mod.send("#{field}=", self.send("#{field}")) unless self.send("#{field}").nil?
        end
      end
    end

    if (new_record? || phenotyping_productions.length == 0) && linked_phenotyping_production.blank?
      @linked_phenotyping_production = PhenotypingProduction.new
    end

    if !mouse_allele_mod.blank? && destroy_mam == false
      mouse_allele_mod.parent_colony_name = mi_attempt_colony_name
      mouse_allele_mod.colony_name = colony_name
      mouse_allele_mod.production_centre_name = production_centre_name || linked_phenotyping_production.try(:production_centre_name)
      mouse_allele_mod.consortium_name = consortium_name || linked_phenotyping_production.try(:consortium_name)
      mouse_allele_mod.mi_plan_id = mi_plan_id

      mouse_allele_mod.rederivation_started = rederivation_started
      mouse_allele_mod.rederivation_complete = rederivation_complete
      mouse_allele_mod.is_active = is_active
      mouse_allele_mod.colony_background_strain_name = colony_background_strain_name

    elsif !linked_phenotyping_production.blank?
      linked_phenotyping_production.parent_colony_name = mi_attempt_colony_name
      linked_phenotyping_production.colony_name = colony_name
      linked_phenotyping_production.production_centre_name = production_centre_name
      linked_phenotyping_production.consortium_name = consortium_name
      linked_phenotyping_production.mi_plan_id = mi_plan_id

      linked_phenotyping_production.rederivation_started = rederivation_started
      linked_phenotyping_production.rederivation_complete = rederivation_complete
      linked_phenotyping_production.is_active = is_active
      linked_phenotyping_production.colony_background_strain_name = colony_background_strain_name
    end

    phenotyping_productions_attributes.each do |pp_attributes|
      pp = nil
      phenotyping_productions.each{|p| pp = p if p.id.to_s == pp_attributes['id'].to_s}

      if pp.blank?
        pp = phenotyping_productions.build
      end
      pp_attributes.each do |patr, pval|
        pp.mark_for_destruction if patr == '_destroy' && self.class.to_true_or_false(pval) == true
        pp.send("#{patr}=".to_sym, pval) unless !pp.methods.include?("#{patr}=".to_sym)
      end
    end

    if !linked_phenotyping_production.blank?
      (PhenotypingProduction.column_names - PHENOTYPE_ATTEMPT_PP_FIELDS[:exclude] + PHENOTYPE_ATTEMPT_PP_FIELDS[:include]).each do |field|
        !linked_phenotyping_production.send("#{field}=", self.send("#{field}")) unless self.send("#{field}").nil?
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
    @errors.clear
    set_models_attributes

    if !destroy_mam && !mouse_allele_mod.blank? && mouse_allele_mod.valid? == false
      mouse_allele_mod.errors.messages.each{|error, message| errors.add("phenotype attempt #{error}", message)}
      return false
    end

    if !mouse_allele_mod.blank? && mouse_allele_mod.new_record? && !new_record? && phenotyping_productions.any?{ |pp| ['Phenotyping Started', 'Phenotyping Complete'].include?(pp.try(:status_name).to_s)}
        errors.add("Phenotype Attempt:", "cannot change 'Excision Required?' if phenotyping has started or is complete.")
        return false
    end

    if destroy_mam
      # change pp parent colony to mi_attempt colony
      if phenotyping_productions.count > 1
        errors.add("Phenotype Attempt:", "cannot change 'Excision Required?' when Phenotype Attempt has many Phenotyping Centres.")
        return false
      end

      if phenotyping_productions.any?{ |pp| ['Phenotyping Started', 'Phenotyping Complete'].include?(pp.try(:status_name).to_s)}
        errors.add("Phenotype Attempt:", "cannot change 'Excision Required?' if phenotyping has started or is complete.")
        return false
      end

      if mouse_allele_mod.status_name == 'Cre Excision Complete'
        errors.add("Phenotype Attempt:", "cannot change 'Excision Required?' if status is more advanced than Cre Excision Complete.")
        return false
      end

      linked_phenotyping_production.parent_colony = mouse_allele_mod.parent_colony unless !linked_phenotyping_production.blank?

    elsif !mouse_allele_mod.blank? && !linked_phenotyping_production.blank?
      linked_phenotyping_production.colony_name = mouse_allele_mod.colony_name
      linked_phenotyping_production.production_centre_name = mouse_allele_mod.production_centre_name
      linked_phenotyping_production.consortium_name = mouse_allele_mod.consortium_name
      linked_phenotyping_production.mi_plan_id = mouse_allele_mod.mi_plan_id
      linked_phenotyping_production.parent_colony = mouse_allele_mod.colony
#      linked_phenotyping_production.colony_background_strain_name = mouse_allele_mod.colony_background_strain_name if mouse_allele_mod.changes.has_key("colony_background_strain_name") && mouse_allele_mod.changes["colony_background_strain_name"][0] != linked_phenotyping_production.colony_background_strain_name
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
    @mam = nil if new_record?
    @linked_phenotyping_production = nil if new_record?

    mouse_allele_mod.reload unless mouse_allele_mod.blank?
    phenotyping_productions.delete_if{|pp| pp.new_record? || pp.marked_for_destruction?}
    phenotyping_productions.each{|pp| pp.reload}
    linked_phenotyping_production.try(:reload) unless linked_phenotyping_production.blank?


    return false unless valid?

    puts "PHENOTYPE ATTEMPT: #{attributes}"

    begin
      ActiveRecord::Base.transaction do
        if destroy_mam
          #reparent phenotyping production to mi_attempt colony before mam deletion
          mouse_allele_mod.colony.phenotyping_productions.each{|pp| pp.parent_colony_id = mouse_allele_mod.parent_colony_id; pp.save}
          mouse_allele_mod.destroy
        else
          #ensure pp and mam phenotype_attempt_id match. Can get out of sync if mam is deleted and then recreated for example.
          if !new_record? && !mouse_allele_mod.blank? && !linked_phenotyping_production.blank? && !linked_phenotyping_production.phenotype_attempt_id.blank? && (mouse_allele_mod.phenotype_attempt_id.blank? || linked_phenotyping_production.phenotype_attempt_id != mouse_allele_mod.phenotype_attempt_id)
            mouse_allele_mod.phenotype_attempt_id = linked_phenotyping_production.phenotype_attempt_id
          end

          if !mouse_allele_mod.blank?
            mouse_allele_mod.save(validate: false)

            mouse_allele_mod.colony.phenotyping_productions.each do |pp|
              if pp.parent_colony_id != mouse_allele_mod.colony.id
                pp.parent_colony_id = mouse_allele_mod.colony.id
                pp.save
              end
            end
          end
        end

        linked_phenotyping_production.save! unless linked_phenotyping_production.blank? || !linked_phenotyping_production.changed?
        phenotyping_productions.each do |pp|
          if pp.marked_for_destruction?
            @linked_phenotyping_production = nil if !linked_phenotyping_production.blank? && linked_phenotyping_production.id == pp.id
            pp.destroy
          else
            pp.save! if pp.changed?
          end
        end
      end

    rescue ActiveRecord::RecordInvalid => exception
      errors.add("Phenotype Attempt:", exception.message)
      return false
    end

    reload
    return true
  end

  def reload

    mouse_allele_mod.reload unless mouse_allele_mod.blank? || destroy_mam
    phenotyping_productions.delete_if{|pp| pp.new_record? || pp.marked_for_destruction?}
    phenotyping_productions.each{|pp| pp.reload}
    linked_phenotyping_production.try(:reload) unless linked_phenotyping_production.blank?
    @distribution_centres_attributes = []

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

  def self.status_order
    status_order = {}
    MouseAlleleMod::Status.all.each{|status| status_order[status] = status[:order_by]}
    PhenotypingProduction::Status.all.each{|status| status_order[status] = status[:order_by]}
    return status_order
  end

  def self.column_names
    return @@phenotype_attempt_fields
  end

  def self.to_true_or_false(var)
    case var
      when true,'true',1,'1'
        return true
      when false, 'false',0,'0'
        return false
    end
  end

  protected
end
