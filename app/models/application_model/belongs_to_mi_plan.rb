module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class Error < RuntimeError; end
  class MissingMiPlanError < Error; end
  class UnsuitableMiPlanError < Error; end

  included do
    belongs_to :mi_plan

    before_save :set_mi_plan
    before_save :ensure_plan_exists
    before_save :deal_with_unassigned_or_inactive_plans
  end

  def set_mi_plan
    # to be overridden
  end
  protected :set_mi_plan

  def ensure_plan_exists
    raise MissingMiPlanError, 'An mi_plan MUST be assigned either via mi_plan_id or via production_centre_name and consortium_name' if mi_plan.blank?
  end
  protected :ensure_plan_exists

  def deal_with_unassigned_or_inactive_plans
    raise UnsuitableMiPlanError, 'mi_plan is not in an assigned state.  This is probably a bug, please inform the developers of this application.' unless mi_plan.assigned?
  end
  protected :deal_with_unassigned_or_inactive_plans

  module Public
    extend ActiveSupport::Concern

    included do
      validate :validate_production_centre_name_and_consortium_name_both_or_neither
      validate :validate_mi_plan_id_or_names_not_both
      validate :validate_consortium_and_production_centre_names_exist
    end # included

    def deal_with_unassigned_or_inactive_plans
      if ! mi_plan.assigned?
        mi_plan.update_attributes!(:is_active => true, :force_assignment => true)
      end
    end
    protected :deal_with_unassigned_or_inactive_plans

    def validate_production_centre_name_and_consortium_name_both_or_neither
      if( (@production_centre_name.blank? and @consortium_name.present?) or
                  (@consortium_name.blank? and @production_centre_name.present?))
        errors.add(:base, 'Either both or neither of consortium_name and production_centre_name must be assigned')
      end
    end
    protected :validate_production_centre_name_and_consortium_name_both_or_neither

    def validate_mi_plan_id_or_names_not_both
      if(changes.has_key?(:mi_plan_id) and (
            @production_centre_name.present? or @consortium_name.present?))
        errors.add(:base, 'If mi_plan_id is assigned, consortium_name or production_centre_name cannot be assigned as well')
      end
    end
    protected :validate_mi_plan_id_or_names_not_both

    def validate_consortium_and_production_centre_names_exist
      if @consortium_name.present? and @production_centre_name.present?
        if ! Consortium.find_by_name(@consortium_name)
          errors.add :consortium_name, 'does not exist'
        end
        if ! Centre.find_by_name(@production_centre_name)
          errors.add :production_centre_name, 'does not exist'
        end
      end
    end
    protected :validate_consortium_and_production_centre_names_exist

    def lookup_mi_plan
      return MiPlan.search(
        :production_centre_name_eq => @production_centre_name,
        :consortium_name_eq => @consortium_name,
        :gene_id_eq => gene.id).result.first
    end
    protected :lookup_mi_plan

    def set_mi_plan
      return unless @production_centre_name.present? and @consortium_name.present? and gene.present?

      if mi_plan.present? and
                mi_plan.consortium.name == @consortium_name and
                mi_plan.production_centre.name == @production_centre_name
        return mi_plan
      end

      found_plan = lookup_mi_plan
      if found_plan
        self.mi_plan = found_plan
      end

    end
    protected :set_mi_plan

    def consortium_name
      if @consortium_name.blank?
        mi_plan.try(:consortium).try(:name)
      else
        return @consortium_name
      end
    end

    def consortium_name=(arg)
      @consortium_name = arg
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
    end

  end # Public

end
