# encoding: utf-8

class String
  def to_json_variable
    ActiveSupport::JSON::Variable.new(self)
  end
end