class MiAttempt::AggregatedView < ::MiAttempt
  set_table_name 'aggregated_mi_attempts'

  belongs_to :latest_mi_attempt_status, :class_name => 'MiAttemptStatus'

  def to_xml(options = {}, &block)
    options = options.symbolize_keys
    options.merge!(:root => 'mi-attempt')
    super(options, &block)
  end
end
