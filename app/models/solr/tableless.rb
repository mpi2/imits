class Solr::Tableless < Tableless

  def doc_to_tsv
    attr_values = self.class.attributes.map do |attr|
    
     attr_value = self.send(attr)
     if attr_value.class == Array
       attr_value.join('|')
     elsif attr_value.blank? && self.class.valid_blank_fields.include?(attr)
       '""'
     else
       attr_value.to_s
     end
    
    end

    return "#{attr_values.join("\t")}\n"
  end

  def self.tsv_header
    return "#{self.attributes.join("\t")}\n"
  end

  def self.valid_blank_fields
    return []
  end
end
