# encoding: utf-8

module AccessAssociationByAttribute
  def access_association_by_attribute(association_name, attribute)

    define_method "#{association_name}_#{attribute}" do
      association = self.send(association_name)
      if association
        return association.send(attribute)
      else
        return nil
      end
    end

    define_method "#{association_name}_#{attribute}=" do |value|
      association_class = self.send(association_name).class
      new_object = association_class.send("find_by_#{attribute}", value)
      self.send("#{association_name}=", new_object)
    end

  end
end
