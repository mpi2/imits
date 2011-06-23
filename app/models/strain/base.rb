class Strain::Base < ActiveRecord::Base
  @abstract_class = true

  def self.define_interface
    acts_as_reportable

    attr_accessible :id
    belongs_to :strain, :foreign_key => :id

    delegate :name, :to => :strain

    def self.find_by_name(name)
      strain = Strain.find_by_name(name)
      if strain
        return self.find_by_id(strain.id)
      else
        return nil
      end
    end

    def self.find_by_name!(name)
      strain = Strain.find_by_name!(name)
      return self.find_by_id!(strain.id)
    end

  end
end
