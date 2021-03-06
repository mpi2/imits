# encoding: utf-8

class TestDummy
  class Error < RuntimeError; end

  ASSOCIATIONS = [
    :gene,
    :consortium,
    :production_centre,
    :centre,
    :deposited_material,
    :sub_project
  ].freeze

  def self.create(type, *values)
    return self.new(type, *values).object
  end

  def self.mi_plan(*values)
    return create(:mi_plan, *values)
  end

  def initialize(type, *values)
    if values.last.kind_of?(Hash)
      hash_values = values.pop.symbolize_keys
    else
      hash_values = {}
    end

    @associations = ASSOCIATIONS.dup
    @object_class = FactoryGirl.factory_by_name(type).build_class
    attrs_to_assign = {}
    values.each do |value|
      attr, value = get_attr_and_associated(value)
      attrs_to_assign[attr] = value
      hash_values.delete(attr)
    end

    @object = Factory.build type, hash_values.merge(attrs_to_assign)

    @object.save!
  end

  attr_reader :object

  private

  def get_attr_and_associated(value)
    @associations.each do |association|
      reflection = @object_class.reflections[association]
      next unless reflection

      associated = find_associated_by_value(reflection.klass, value)
      if associated
        @associations.delete(association)
        return association, associated
      end
    end

    raise Error, "#{value} not found in associated tables"
  end

  def find_associated_by_value(association_class, value)
    attr_to_search = case association_class.name
    when 'Gene' then :marker_symbol
    else             :name
    end
    return association_class.send("find_by_#{attr_to_search}", value)
  end

end
