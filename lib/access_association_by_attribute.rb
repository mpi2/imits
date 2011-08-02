# encoding: utf-8

module AccessAssociationByAttribute
  # Some behaviour may be undefined if the attribute of the association can be
  # blank
  def access_association_by_attribute(association_name, attribute, options = {})
    options.symbolize_keys!

    virtual_attribute = "#{association_name}_#{attribute}"
    association_class = self.reflections[association_name].class_name.constantize

    define_method virtual_attribute do
      if instance_variable_defined?("@#{virtual_attribute}")
        return instance_variable_get("@#{virtual_attribute}")
      else
        new_value = self.send(association_name).try(:send, attribute)
        instance_variable_set("@#{virtual_attribute}", new_value)
        return new_value
      end
    end

    define_method "#{virtual_attribute}=" do |value|
      instance_variable_set("@#{virtual_attribute}", value)
    end

    if ! options[:attribute_alias].blank?
      alias_method "#{association_name}_#{options[:attribute_alias]}=", "#{virtual_attribute}="
      alias_method "#{association_name}_#{options[:attribute_alias]}", "#{virtual_attribute}"
    end

    define_method "#{virtual_attribute}_before_validation" do
      return true unless instance_variable_defined?("@#{virtual_attribute}")

      value = instance_variable_get("@#{virtual_attribute}")

      new_object = association_class.send("find_by_#{attribute}", value)
      if !value.blank? and !new_object
        self.errors.add(virtual_attribute, "'#{value}' does not exist")
      end

      return true
    end

    before_validation "#{virtual_attribute}_before_validation"

    define_method "#{virtual_attribute}_before_save" do
      return true unless instance_variable_defined?("@#{virtual_attribute}")

      value = instance_variable_get("@#{virtual_attribute}")
      new_object = association_class.send("find_by_#{attribute}", value)
      self.send("#{association_name}=", new_object)
      return true
    end

    before_validation "#{virtual_attribute}_before_save"

  end
end
