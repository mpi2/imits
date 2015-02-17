#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

STDOUT.sync = true

class ScraperMmrrcRepository

    attr_accessor :gene_details
    attr_accessor :count_is_mice
    attr_accessor :count_is_recovery
    attr_accessor :count_is_germ_plasm
    attr_accessor :count_is_embryos
    attr_accessor :count_unique_alleles_found
    attr_accessor :count_unique_alleles_with_products

    # URLs for scraping MMRRC websites
    MMRRC_REPO                      = 'MMRRC'
    MMRRC_GENE_SEARCH_PARAMS_PREFIX = 'fulltext='
    MMRRC_GENE_SEARCH_PARAMS_SUFFIX = '&InitialMaintenanceLevel=Both&organization=Both&Status_AVD=AVD&Status_Importation=Importation&Status_Accepted=Accepted&page_number=0'
    MMRRC_GENE_SEARCH_URL           = 'https://www.mmrrc.org/ajax/searchCatalog.php'

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

    def fetch_mmrrc_allele_details( marker_symbol )

        if ( marker_symbol.nil? )
            puts "ERROR : no marker symbol input to fetch_mmrrc_allele_details, cannot continue"
            return
        end

        begin
            gene_specific_params = "#{MMRRC_GENE_SEARCH_PARAMS_PREFIX}#{marker_symbol}#{MMRRC_GENE_SEARCH_PARAMS_SUFFIX}"

            doc = nil
            doc = get_doc( gene_specific_params)
            if doc.nil?
              puts "WARN: no page returned for URL: '#{MMRRC_GENE_SEARCH_URL}' with params: '#{gene_specific_params}'"
              return
            end

            rows        = doc.xpath("//table/tr[@class='search_result_row']")

            if ( rows.nil? || rows.count == 0 )
                puts "WARN: No rows found on alleles table for marker symbol #{marker_symbol} and URL: #{MMRRC_GENE_SEARCH_URL}"
            end

            # to hold hash of allele details in main hash
            @gene_details[marker_symbol] = { 'alleles' => {} }

            # pull details from each row
            rows.each do |row|
                allele_row               = row.at_xpath('td[2]/a').try(:to_s).try(:strip)

                allele_name = nil
                if allele_row && ( allele_row.include? "<sup>")
                    extracted_allele     = allele_row.match(/.*<sup>(.*)<\/sup>/)[1]
                    allele_name          = extracted_allele
                else
                    next
                end

                mmrrc_id          = row.at_xpath('td[3]/text()[1]').try(:to_s).try(:strip)
                product_available = row.at_xpath('td[4]/text()[1]').try(:to_s).try(:strip)

                is_mice    = 0
                is_embryos = 0

                unless product_available.nil?
                    case product_available
                    when 'Live Colony'
                        is_mice = 1
                    when 'Cryo-archive'
                        is_embryos = 1
                    end
                end

                next unless allele_name

                puts "allele name in repo: #{allele_name}"

                if ( @gene_details[marker_symbol]['alleles'].has_key?(allele_name) )
                    if is_mice == 1
                        @gene_details[marker_symbol]['alleles'][allele_name]['is_mice']    = 1
                    end
                    if is_embryos == 1
                        @gene_details[marker_symbol]['alleles'][allele_name]['is_embryos'] = 1
                    end
                else
                    @count_unique_alleles_found += 1

                    @gene_details[marker_symbol]['alleles'][allele_name] = {
                        'is_mice'       => is_mice,
                        'is_recovery'   => 0,
                        'is_germ_plasm' => 0,
                        'is_embryos'    => is_embryos
                    }
                    if is_mice == 1
                        @count_is_mice += 1
                    end
                    if is_embryos == 1
                        @count_is_embryos += 1
                    end
                    @count_unique_alleles_with_products += 1
                end # allele duplicated
            end # end rows
        rescue => e
            puts "ERROR : failed to fetch product details for gene #{marker_symbol}"
            puts "Exception message : #{e.message}"
            return
        end

        return @gene_details[marker_symbol]
    end

    private
        def get_doc( params )
            begin
                command = "curl --globoff --basic --request POST --header 'application/x-www-form-urlencoded' --output /tmp/trash.html --data-binary '#{params}' '#{MMRRC_GENE_SEARCH_URL}'"
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
  ScraperMmrrcRepository.new
end