class ApplicationModel::StatusChangerMachine

  class Item
    def initialize(required, &conditions)
      @conditions = conditions
      @required = required
    end

    def conditions_met_for?(object)
      conditions_met = @conditions.call(object)
      if @required
        required_conditions_met = @required.conditions_met_for?(object)
      else
        required_conditions_met = true
      end
      return (conditions_met and required_conditions_met)
    end
  end

  def initialize
    @items = {}
  end

  def add(status, required = nil, &conditions)
    raise "Already have #{status}" if @items.has_key?(status)
    required = @items[required]
    object = Item.new(required, &conditions)
    @items[status] = object
  end

  def get_status_for(object)
    new_status = nil
    @items.each do |status, item|
      if item.conditions_met_for?(object)
        new_status = status
      end
    end
    return new_status
  end

end
