# encoding: utf-8

module Reports::MiProduction::Helper

  # TODO: do this as a class and not directly
  
  def strong(param)
    return '<strong>' + param.to_s + '</strong>' if param
    return ''
  end
  
  def fix_mutation_type(mt)
    return "Knockout First" if mt == 'conditional_ready'
    mt = mt ? mt.gsub(/_/, ' ') : ''
    mt = mt.gsub(/\b\w/){$&.upcase}
    return mt
  end
  
end
