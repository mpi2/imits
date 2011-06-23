# encoding: utf-8

module AccessAssociationByAttribute
  def access_association_by_attribute(association_name, attribute)
    virtual_attribute = "#{association_name}_#{attribute}"

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

    define_method "#{virtual_attribute}_before_validation" do
      return unless instance_variable_defined?("@#{virtual_attribute}")

      association_class = self.send(association_name).class
      value = instance_variable_get("@#{virtual_attribute}")
      new_object = association_class.send("find_by_#{attribute}", value)
      if ! new_object
        self.errors.add(virtual_attribute, "'#{value}' does not exist")
      end
    end

    before_validation "#{virtual_attribute}_before_validation"

    define_method "#{virtual_attribute}_before_save" do
      return unless instance_variable_defined?("@#{virtual_attribute}")

      association_class = self.send(association_name).class
      value = instance_variable_get("@#{virtual_attribute}")
      new_object = association_class.send("find_by_#{attribute}", value)
      self.send("#{association_name}=", new_object)
    end

    before_validation "#{virtual_attribute}_before_save"

  end
end
