module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class UnassignedMiPlanError < RuntimeError; end

  included do
    belongs_to :mi_plan
    validates :mi_plan, :presence => true

    before_save :deal_with_unassigned_or_inactive_plans

    def deal_with_unassigned_or_inactive_plans
      raise UnassignedMiPlanError unless mi_plan.assigned?
    end
    protected :deal_with_unassigned_or_inactive_plans
  end

  module Public
    extend ActiveSupport::Concern

    included do
      validate :validate_production_centre_name_and_consortium_name_both_or_neither
      validate :mi_plan_id_or_names_not_both

      def deal_with_unassigned_or_inactive_plans
        if ! mi_plan.assigned?
          mi_plan.update_attributes!(:is_active => true, :force_assignment => true)
        end
      end
      protected :deal_with_unassigned_or_inactive_plans

    end # included

    def validate_production_centre_name_and_consortium_name_both_or_neither
      if( (@production_centre_name.blank? and @consortium_name.present?) or
                  (@consortium_name.blank? and @production_centre_name.present?))
        errors.add(:base, 'Either both or neither of consortium_name and production_centre_name must be assigned')
      end
    end

    def mi_plan_id_or_names_not_both
      if(changes.has_key?(:mi_plan_id) and (
            @production_centre_name.present? or @consortium_name.present?))
        errors.add(:base, 'If mi_plan_id is assigned, consortium_name or production_centre_name cannot be assigned as well')
      end
    end
  end # Public

=begin
  def try_to_find_production_centre_name
    return @production_centre_name if @production_centre_name
    return mi_plan.production_centre.name if(mi_plan.present? and mi_plan.production_centre.present?)
    return mi_attempt.production_centre.name if(respond_to?(:mi_attempt) and mi_attempt.present?)
    return nil
  end

  def try_to_find_consortium_name
    return @consortium_name if @consortium_name
    return mi_plan.consortium.name if(mi_plan.present?)
    return mi_attempt.consortium.name if(respond_to?(:mi_attempt) and mi_attempt.present?)
    return nil
  end

  def try_to_find_plan
    c = try_to_find_consortium_name
    p = try_to_find_production_centre_name

    if c.blank? or p.blank? or gene.blank?
      return nil
    elsif mi_plan
      if c == mi_plan.consortium.name and p == mi_plan.production_centre.name
        return mi_plan
      end
    else
      found_plan = MiPlan.search(
        :consortium_name_eq => c,
        :production_centre_name_eq => p,
        :gene_id_eq => gene.id
      ).result.first
      return found_plan
    end

    return nil
  end

  def set_mi_plan
    plan = try_to_find_plan
    if plan
      self.mi_plan = plan
    end
  end
=end
end
