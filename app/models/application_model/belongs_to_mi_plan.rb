module ApplicationModel::BelongsToMiPlan
  extend ActiveSupport::Concern

  class Error <  ApplicationModel::ValidationError; end
  class MissingMiPlanError < Error; end
  class UnsuitableMiPlanError < Error; end

  included do
    belongs_to :mi_plan

    before_save :set_mi_plan
    before_save :ensure_plan_exists
    before_save :deal_with_unassigned_or_inactive_plans
  end

  # Overridden in Public
  def set_mi_plan
    if self.kind_of? PhenotypeAttempt
      self.mi_plan ||= mi_attempt.try(:mi_plan)
    end
  end
  protected :set_mi_plan

  def ensure_plan_exists
    raise MissingMiPlanError, 'An mi_plan MUST be assigned either via mi_plan_id or via production_centre_name and consortium_name' if mi_plan.blank?
  end
  protected :ensure_plan_exists

  # Overridden in Public
  def deal_with_unassigned_or_inactive_plans
    raise UnsuitableMiPlanError, "mi_plan is in status #{mi_plan.status.name} - it must be in an assigned state." unless mi_plan.assigned?
  end
  protected :deal_with_unassigned_or_inactive_plans

  module Public
    extend ActiveSupport::Concern

    included do
      validate :validate_production_centre_name_and_consortium_name_both_or_neither
      validate :validate_mi_plan_id_or_names_not_both
      validate :validate_consortium_and_production_centre_names_exist
      validate :lookup_mi_plan
    end # included

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
      return false if mi_plan.blank? && gene.blank?

      lookup_params = {
        :production_centre_name_eq => @production_centre_name,
        :consortium_name_eq => @consortium_name,
        :gene_id_eq => gene.id
      }
      plan = MiPlan.search(lookup_params).result.first
      
      if kind_of? MiAttempt
        if plan
          if plan.phenotype_only
            self.errors.add(:base, 'MiAttempt cannot be created for this MiPlan. (phenotype only)')
            return nil
          end
        else
          lookup_params.delete(:production_centre_name_eq)
          lookup_params[:production_centre_is_null] = true
          plan = MiPlan.search(lookup_params).result.first
        end
      end

      return plan
    end

    def set_mi_plan
      mi_plan.try(:reload)
      if @production_centre_name.present? and @consortium_name.present? and gene.present?
        if mi_plan.present? and
                  mi_plan.consortium.name == @consortium_name and
                  mi_plan.production_centre.name == @production_centre_name
          return mi_plan
        end

        found_plan = lookup_mi_plan
        if found_plan
          found_plan = MiPlan.find(found_plan)

          if found_plan.production_centre.blank? and kind_of? MiAttempt
            found_plan.update_attributes!(:production_centre => Centre.find_by_name!(@production_centre_name))
          end
          self.mi_plan = found_plan
        else
          self.mi_plan = MiPlan.create!(
            :consortium => Consortium.find_by_name!(@consortium_name),
            :production_centre => Centre.find_by_name!(@production_centre_name),
            :gene => gene,
            :force_assignment => true,
            :priority => MiPlan::Priority.find_by_name!('High')
          )
        end
      end
      super
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
