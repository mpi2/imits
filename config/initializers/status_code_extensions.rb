class String
  def status
    retval = MiPlan::Status.find_by_code(self)
    return retval if retval

    retval = MiAttempt::Status.find_by_code(self)
    return retval if retval

    retval = PhenotypeAttempt::Status.find_by_code(self)
    return retval if retval

    raise "Status code #{self} not found!"
  end
end

class Symbol
  def status
    retval = MiPlan::Status.find_by_code(self)
    return retval if retval

    retval = MiAttempt::Status.find_by_code(self)
    return retval if retval

    retval = PhenotypeAttempt::Status.find_by_code(self)
    return retval if retval

    raise "Status code #{self} not found!"
  end
end
