module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class Error <  ApplicationModel::ValidationError; end
  class MissingMiPlanError < Error; end
  class UnsuitableMiPlanError < Error; end

#  included do
#    before_save :ensure_plan_exists
#    before_save :deal_with_unassigned_or_inactive_plans
#  end

  def ensure_plan_exists
    self.errors.add(:base, 'Please select a plan') if mi_plan.blank?
  end
  protected :ensure_plan_exists

  # Overridden in Public
  def deal_with_unassigned_or_inactive_plans
    raise UnsuitableMiPlanError, "mi_plan is in status #{mi_plan.status.name} - it must be in an assigned state." unless mi_plan.assigned?
  end
  protected :deal_with_unassigned_or_inactive_plans

  module Public
    extend ActiveSupport::Concern

    def deal_with_unassigned_or_inactive_plans
      mi_plan.reload
      if ! mi_plan.assigned?
        new_attrs = {:is_active => true, :force_assignment => true}
        if kind_of? MiAttempt and ! is_active?
          new_attrs.delete(:is_active)
        end
        mi_plan.update_attributes!(new_attrs)
      end
    end
    protected :deal_with_unassigned_or_inactive_plans

    def consortium_name
      mi_plan.try(:consortium).try(:name)
    end

    def production_centre_name
      mi_plan.try(:production_centre).try(:name)
    end

  end # Public

end
