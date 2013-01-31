module Arel

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CaseInsensitiveIn(o)
        Rails.logger.info 'find query'
        "UPPER(#{visit o.left}) IN (#{visit o.right})"
      end
    end

    class DepthFirst
      alias :visit_Arel_Nodes_CaseInsensitiveIn                 :binary
    end
  end

  module Nodes
    class CaseInsensitiveIn < Arel::Nodes::In
      def initialize(left, right)
        Rails.logger.info 'initialize'
        super(left, right)
      end

      def self.name
        Rails.logger.info caller
        "Arel::Nodes::CaseInsensitiveIn"
      end
    end
  end

  module Predications
    def bob(other)
      if other.kind_of? Array
        puts 'use bob predicate'
        upcased_other = other.map {|i| i.try(:upcase)}
        Nodes::CaseInsensitiveIn.new(self, upcased_other)
      else
        raise "Unsupported operand for bob (#{other.class.name})"
      end
    end
  end

end
