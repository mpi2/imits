module ApplicationModel::BelongsToMiPlan
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

    if c.blank? or p.blank?
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
end
