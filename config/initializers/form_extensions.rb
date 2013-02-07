module ActionView
  module Helpers
    class FormBuilder

      def index
        @options[:index] || @options[:child_index]
      end

      def fields_for(record_name, record_object = nil, fields_options = {}, &block)
        fields_options, record_object = record_object, nil if record_object.is_a?(Hash) && record_object.extractable_options?
        fields_options[:builder] ||= options[:builder]
        fields_options[:parent_builder] = self
        fields_options[:namespace] = options[:namespace]

        case record_name
          when String, Symbol
            if nested_attributes_association?(record_name)
              return fields_for_with_nested_attributes(record_name, record_object, fields_options, block)
            end
          else
            record_object = record_name.is_a?(Array) ? record_name.last : record_name
            record_name   = ActiveModel::Naming.param_key(record_object)
        end

        index = if options.has_key?(:index)
                  options[:index]
                elsif defined?(@auto_index)
                  self.object_name = @object_name.to_s.sub(/\[\]$/,"")
                  @auto_index
                end

        record_name = index ? "#{object_name}[#{index}][#{record_name}]" : "#{object_name}[#{record_name}]"
        fields_options[:child_index] = index

        @template.fields_for(record_name, record_object, fields_options, &block)
      end

      def fields_for_with_nested_attributes(association_name, association, options, block)
        name = "#{object_name}[#{association_name}_attributes]"
        association = convert_to_model(association)

        if association.respond_to?(:persisted?)
          association = [association] if @object.send(association_name).is_a?(Array)
        elsif !association.respond_to?(:to_ary)
          association = @object.send(association_name)
        end

        if association.respond_to?(:to_ary)
          explicit_child_index = options[:child_index]
          output = ActiveSupport::SafeBuffer.new
          association.each do |child|
            options[:child_index] = nested_child_index(name) unless explicit_child_index
            output << fields_for_nested_model("#{name}[#{options[:child_index]}]", child, options, block)
          end
          output
        elsif association
          fields_for_nested_model(name, association, options, block)
        end
      end

    end
  end
end