class ApplicationModel::StatusManager

  class Item
    def initialize(required, options = {}, &conditions)
      @conditions = conditions
      @options = options.symbolize_keys!
      @required = required
    end

    def conditions_met_for?(object)
      conditions_met = @conditions.call(object)
      if @options[:skip_requirements_if]
        enforce_req = (not @options[:skip_requirements_if].call(object))
      else
        enforce_req = true
      end

      if @required and enforce_req == true
        required_conditions_met = @required.conditions_met_for?(object)
      else
        required_conditions_met = true
      end

      return (conditions_met and required_conditions_met)
    end
  end

  def initialize(klass, status_class = :Status, status_stamp_association = :status_stamps)
    @items = {}
    @klass = klass
    @status_class = @klass.const_get(status_class)
    @status_stamp_association = status_stamp_association
  end

  def add(status, required = nil, options = {}, &conditions)
    raise "Already have #{status}" if @items.has_key?(status)
    required = @items[required]
    @items[status] = Item.new(required, options, &conditions)
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
    status_stamp_names = object.send(@status_stamp_association).all.map(&:name)
    @items.each do |status_name, item|
      if item.conditions_met_for?(object)
        if ! status_stamp_names.include?(status_name)
          object.send(@status_stamp_association).create!(:status => @status_class.find_by_name!(status_name))
        end
      else
        if status_stamp_names.include?(status_name)
          object.send(@status_stamp_association).all.find {|ss| ss.name == status_name}.try(:destroy)
        end
      end
    end
    object.send(@status_stamp_association).reload
  end

end
