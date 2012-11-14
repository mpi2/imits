class AuditDiffer

  def diff(h1, h2)
    retval = {}

    h2.each do |key, new_value|
      old_value = h1[key]

      if old_value != new_value
        retval[key] = new_value
      end
    end

    return retval
  end

end
