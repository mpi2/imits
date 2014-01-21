module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class Error <  ApplicationModel::ValidationError; end
  class MissingMiPlanError < Error; end
  class UnsuitableMiPlanError < Error; end

  #VALIDATION METHODS

  def validate_plan # returns true if validations pass
    if mi_plan.blank?
      self.errors.add(:base, 'Please select a plan')
      return false
    end

    if ['Withdrawn', 'Inactive'].include?(mi_plan.status.name)
      self.errors.add(:mi_plan, "is in status #{mi_plan.status.name} - it must be in an assigned state.")
    end

    es_cell = self.try(:es_cell)
    if (es_cell and es_cell.try(:gene) != mi_plan.try(:gene))
      self.errors.add :base, "mi_plan and es_cell gene mismatch!  Should be the same! (#{es_cell.try(:gene).try(:marker_symbol)} != #{self.mi_plan.try(:gene).try(:marker_symbol)})"
    end

    return true
  end
  protected :validate_plan


  # BEFORE SAVE METHODS

  # Overridden in Public
  def deal_with_unassigned_or_inactive_plans
    raise UnsuitableMiPlanError, "mi_plan is in status #{mi_plan.status.name} - it must be in an assigned state." unless mi_plan.assigned?
  end
  protected :deal_with_unassigned_or_inactive_plans


  #COMMON METHODS
  def consortium_name
    if @consortium_name.blank?
      mi_plan.try(:consortium).try(:name)
    else
      return @consortium_name
    end
  end

  def consortium_name=(arg)
    @consortium_name = arg
    if @consortium_name != self.mi_plan.try(:consortium).try(:name)
      # this forces the changed methods to record a change.
      self.changed_attributes['consortium_name'] = arg
    end
  end

  def production_centre_name
    if @production_centre_name.blank?
      mi_plan.try(:production_centre).try(:name)
    else
      return @production_centre_name
    end
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
    if @production_centre_name != self.mi_plan.try(:production_centre).try(:name)
      # this forces the changed methods to record a change.
      self.changed_attributes['production_centre_name'] = arg
    end
  end

# PUBLIC MODEL
  module Public
    extend ActiveSupport::Concern

    #VALIDATION METHODS


    # BEFORE SAVE METHODS

    # changes mi_plan status to assigned.
    def deal_with_unassigned_or_inactive_plans
      mi_plan.reload
      if ! mi_plan.assigned?
        new_attrs = {:force_assignment => true}
        mi_plan.update_attributes!(new_attrs)
      end
    end
    protected :deal_with_unassigned_or_inactive_plans


    #COMMON METHODS
  end # Public

end
