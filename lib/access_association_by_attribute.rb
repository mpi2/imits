# encoding: utf-8

module AccessAssociationByAttribute
  # Some behaviour may be undefined if the attribute of the association can be blank
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

      if value.blank?
        self.send("#{association_name}=", nil)
        return
      end

      if !value.respond_to?(:to_str)
        instance_variable_set("@#{virtual_attribute}_errors_", "'#{value}' is invalid")
        return
      end

      new_object = association_class.send("find_by_#{attribute}", value)
      if !new_object
        instance_variable_set("@#{virtual_attribute}_errors_", "'#{value}' does not exist")
        return
      end

      self.send("#{association_name}=", new_object)
    end

    if ! options[:attribute_alias].blank?
      alias_method "#{association_name}_#{options[:attribute_alias]}=", "#{virtual_attribute}="
      alias_method "#{association_name}_#{options[:attribute_alias]}", "#{virtual_attribute}"
    end

    define_method "#{virtual_attribute}_validation" do
      errors = instance_variable_get("@#{virtual_attribute}_errors_")
      if errors
        self.errors.add(virtual_attribute, errors)
      end
    end

    validate "#{virtual_attribute}_validation"

  end
end
