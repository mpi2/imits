# encoding: utf-8

module AccessAssociationByAttribute
  def access_association_by_attribute(assocication_name, attribute_name)

    define_method "#{assocication_name}_#{attribute_name}" do
      assoc = self.send(assocication_name)
      if assoc
        return assoc.send(attribute_name)
      else
        return nil
      end
    end

  end
end
