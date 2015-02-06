#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

STDOUT.sync = true

class ScraperEmmaRepository

    attr_accessor :gene_details
    attr_accessor :count_is_mice
    attr_accessor :count_is_recovery
    attr_accessor :count_is_germ_plasm
    attr_accessor :count_is_embryos
    attr_accessor :count_unique_alleles_found
    attr_accessor :count_unique_alleles_with_products

    # URLs for scraping EMMA websites
    EMMA_REPO              = 'EMMA'
    EMMA_GENE_SEARCH_STUB  = 'https://www.infrafrontier.eu/sites/infrafrontier.eu/themes/custom/infrafrontier/emmaSearch/search_browse_emmastr_db.php?query='

    def initialize
        # instance variables
         @gene_details                       = {}
         @count_is_mice                      = 0
         @count_is_recovery                  = 0
         @count_is_germ_plasm                = 0
         @count_is_embryos                   = 0
         @count_unique_alleles_found         = 0
         @count_unique_alleles_with_products = 0
    end

    def fetch_emma_allele_details( marker_symbol )

        if ( marker_symbol.nil? )
            puts "ERROR : no marker symbol input to fetch_emma_allele_details, cannot continue"
            return
        end

        begin
            gene_specific_url = "#{EMMA_GENE_SEARCH_STUB}#{marker_symbol}"

            doc = nil
            doc = get_doc(gene_specific_url)
            if doc.nil?
              puts "WARN: no page returned for URL: #{gene_specific_url}"
              return
            end

            rows = doc.xpath("//body/table[@class='resultSet tablesorter']/tbody/tr")

            if ( rows.nil? || rows.count == 0 )
                puts "WARN: No rows found on alleles table for URL: #{gene_specific_url}"
            end

            # to hold hash of allele details in main hash
            @gene_details[marker_symbol] = { 'alleles' => {} }

            # pull details from each row
            rows.each do |row|
                emmaid            = row.at_xpath('td[1]/span/span[1]').text.to_s.strip
                mgiLink           = row.at_xpath('td[2]').text.to_s.strip
                strain_well_id    = row.at_xpath('td[3]').text.to_s.strip
                strain_prefix     = row.at_xpath('td[4]/text()[1]').to_s.strip
                allele_name       = row.at_xpath('td[4]/sup').text.to_s.strip
                img_link          = row.at_xpath('td[5]/span/img').to_s.strip
                availability_text = row.at_xpath('td[5]/span/span').text.to_s.strip

                next unless allele_name

                puts "allele name in repo: #{allele_name}"

                row_available = false
                if ( img_link =~ /.*(green_dot).*/ ) || ( img_link =~ /.*(yellow_dot).*/ )
                    row_available = true
                end

                if row_available
                    if ( @gene_details[marker_symbol]['alleles'].has_key?(allele_name) )
                        @gene_details[marker_symbol]['alleles'][allele_name]['is_mice'] = 1
                    else
                        @count_unique_alleles_found += 1

                        @gene_details[marker_symbol]['alleles'][allele_name] = {
                            'is_mice'       => 1,
                            'is_recovery'   => 0,
                            'is_germ_plasm' => 0,
                            'is_embryos'    => 0
                        }
                        @count_is_mice += 1
                        @count_unique_alleles_with_products += 1
                    end # allele duplicated
                end # end row available
            end # end rows
        rescue => e
            puts "ERROR : failed to fetch product details for gene #{marker_symbol}"
            puts "Exception message : #{e.message}"
            return
        end

        return @gene_details[marker_symbol]
    end

    private
        def get_doc url
            begin
                command = "curl -o /tmp/trash.html #{url}"
                system command

                # add html headers and footer to the file as this is a page fragment
                command = "echo \"<!DOCTYPE html><html><body>$(cat /tmp/trash.html)\" > /tmp/trash.html"
                system command

                command = "echo \"</body></html>\" >> /tmp/trash.html"
                system command

                # read the file into Nokogiri
                file    = File.open("/tmp/trash.html", "rb")
                doc     = Nokogiri::HTML(file.read)

                return doc
            rescue => e
                puts "ERROR : failed to get_page"
                puts "Exception message : #{e.message}"
            end
        end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ScraperEmmaRepository.new
end