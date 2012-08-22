class ApplicationModel::StatusManager

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

  def initialize(klass)
    @items = {}
    @klass = klass
    @status_class = @klass.const_get(:Status)
  end

  def add(status, required = nil, &conditions)
    raise "Already have #{status}" if @items.has_key?(status)
    required = @items[required]
    @items[status] = Item.new(required, &conditions)
  end

  def get_status_for(object)
    new_status_name = nil
    @items.each do |status_name, item|
      if item.conditions_met_for?(object)
        new_status_name = status_name
      end
    end
    return new_status_name
  end

  def manage_status_stamps_for(object)
    status_stamp_names = object.status_stamps.all.map(&:name)

    @items.each do |status_name, item|
      if item.conditions_met_for?(object)
        if ! status_stamp_names.include?(status_name)
          object.status_stamps.create!(:status => @status_class.find_by_name!(status_name))
        end
      else
        if status_stamp_names.include?(status_name)
          object.status_stamps.all.find {|ss| ss.name == status_name}.destroy
        end
      end
    end
  end

  def status_stamps_order_sql
    status_stamp_class = @klass.const_get(:StatusStamp)

    ordered_statuses = @items.keys.map {|i| @status_class.find_by_name!(i)}

    order_by_str = ordered_statuses.map do |status|
      "#{status_stamp_class.table_name}.status_id=#{status.id}"
    end

    return order_by_str.reverse.join ', '
  end

end
