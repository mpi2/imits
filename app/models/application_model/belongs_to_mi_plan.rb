module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class Error <  ApplicationModel::ValidationError; end
  class MissingMiPlanError < Error; end
  class UnsuitableMiPlanError < Error; end

  #VALIDATION METHODS

  def validate_plan # returns true if validations pass
#    if plan.blank?
#      self.errors.add(:base, 'Please select a plan')
#      return false
#    end

    if plan.consortium.blank? or plan.production_centre.blank?
      self.errors.add(:mi_plan, "must have been assigned to a production centre before production can commence")
      return false
    end

    es_cell = self.try(:es_cell)
    if (es_cell and es_cell.try(:gene) != plan.try(:gene))
      self.errors.add :base, "plan and es_cell gene mismatch!  Should be the same! (#{es_cell.try(:gene).try(:marker_symbol)} != #{self.plan.try(:gene).try(:marker_symbol)})"
      return false
    end

    return true
  end
  protected :validate_plan

  def validate_marker_symbol
    gene = Gene.find_by_marker_symbol(marker_symbol)
    self.errors.add :base, "Invalid marker_symbol" if gene.blank?

    if !plan_id.blank?
      self.errors.add :base, "Cannot change marker_symbol once production has started" if plan.marker_symbol != marker_symbol
    end
  end

  # BEFORE SAVE METHODS

  # changes plan intention status to assigned.
  def manage_plan_and_intentions &update_intention
    if (@consortium_name.blank? || @production_centre_name.blank?) && plan.consortium_name != consortium_name && plan.production_centre_name != production_centre_name
      plans = Plan.joins(:gene, :consortium, :production_centre).where("genes.marker_symbol = '#{self.marker_symbol}' AND consortia.name = '#{consortium_name}' AND centres.name = '#{production_centre_name}'")
      raise 'Cannot have multiple plans for gene_id, consortia.id and centre_id' if plans.length > 1
      if plans.length == 1
        self.plan = plans.first
      else
        new_plan = Plan.new(:marker_symbol => marker_symbol, :consortium_name => consortium_name, :production_centre_name => production_centre_name)
        raise 'Could not save new plan' unless new_plan.save
        plan = new_plan
      end
    end

    update_intention.call
  end
  protected :manage_plan_and_intentions



  #COMMON METHODS
  def mi_plan_id=(arg)
    plan = Plan.find(arg)
    return if plan.blank?

    self.marker_symbol = plan.marker_symbol
    self.consortium_name = plan.consortium_name
    self.production_centre_name = plan.production_centre_name
  end

  def marker_symbol
    if @marker_symbol.blank?
      return plan.marker_symbol
    else
      return @marker_symbol
    end
  end

  def marker_symbol=(arg)
    @marker_symbol = arg
  end

  def consortium_name
    if @consortium_name.blank?
      return plan.try(:consortium).try(:name)
    else
      return @consortium_name
    end
  end

  def consortium_name=(arg)
    @consortium_name = arg
  end

  def production_centre_name
    if @production_centre_name.blank?
      return plan.try(:production_centre).try(:name)
    else
      return @production_centre_name
    end
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end
end
