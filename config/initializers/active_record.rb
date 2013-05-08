module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter

        def translate_exception(exception, message)
          case exception.result.try(:error_field, PGresult::PG_DIAG_SQLSTATE)
          when UNIQUE_VIOLATION
            RecordNotUnique.new(message, exception)
          when FOREIGN_KEY_VIOLATION
            InvalidForeignKey.new(message, exception)
          else
            super
          end
        end

    end
  end
end