#!/usr/bin/env ruby

require 'pp'
require 'open-uri'

# 1. MGI Marker Accession ID
# 2. Marker Type
# 3. Feature Type
# 4. Marker Symbol
# 5. Marker Name
# 6. Chromosome
# 7. Start Coordinate
# 8. End Coordinate
# 9. Strand
# 10. Genome Build
# 11. Provider Collection
# 12. Provider Display

class MarkerTypeCk

  def initialize
    @genes_data = []
  end

  def load
    url = 'ftp://ftp.informatics.jax.org/pub/reports/MGI_MRK_Coord.rpt'
    open(url, :proxy => nil) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_index = headers.index('1. MGI Marker Accession ID')
      marker_symbol_index = headers.index('4. Marker Symbol')
      marker_name_index = headers.index('5. Marker Name')
      chr_index = headers.index('6. Chromosome')
      start_index = headers.index('7. Start Coordinate')
      end_index = headers.index('8. End Coordinate')
      strand_index = headers.index('9. Strand')
      genome_build_index = headers.index('10. Genome Build')
      marker_type_index = headers.index('2. Marker Type')
      feature_type_index = headers.index('3. Feature Type')

      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        @genes_data.push({
          'mgi_accession_id' => row[mgi_accession_index],
          'marker_symbol' => row[marker_symbol_index],
          'marker_name'   => row[marker_name_index],
          'chr'           => row[chr_index],
          'start'         => row[start_index],
          'end'           => row[end_index],
          'strand'        => row[strand_index],
          'genome_build'  => row[genome_build_index],
          'marker_type'  => row[marker_type_index],
          'feature_type'  => row[feature_type_index]
        })
      end
    end
  end

  def save_csv filename, data
    CSV.open(filename, "wb") do |csv|
      csv << data.first.keys
      data.each do |hash|
        csv << hash.values
      end
    end
  end

  def run
    load
    save_csv 'MGI_MRK_Coord.csv', @genes_data
  end

end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  MarkerTypeCk.new.run
end
