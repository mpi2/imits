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

            header_row = doc.xpath("//body/table[@class='resultSet tablesorter']/thead/tr[1]")

            col_adjust = 0
            if header_row
                col2_name = header_row.at_xpath('th[2]').try(:text).try(:to_s).try(:strip)
                puts "col2_name : #{col2_name}"
                if ( col2_name.include? "OMIM name" )
                    col_adjust = 1
                end
            end

            rows = doc.xpath("//body/table[@class='resultSet tablesorter']/tbody/tr")

            if ( rows.nil? || rows.count == 0 )
                puts "WARN: No rows found on alleles table for URL: #{gene_specific_url}"
            end

            # to hold hash of allele details in main hash
            @gene_details[marker_symbol] = { 'alleles' => {} }

            # pull details from each row
            rows.each do |row|
                emmaid            = row.at_xpath("td[1]/span/span[1]").try(:text).try(:to_s).try(:strip)
                gene_symbol         = row.at_xpath("td[#{col_adjust + 2}]").try(:text).try(:to_s).try(:strip)
                common_strain_name  = row.at_xpath("td[#{col_adjust + 3}]").try(:text).try(:to_s).try(:strip)
                # strain_prefix       = row.at_xpath("td[4]/text()[1]").try(:to_s).try(:strip)
                int_strain_desig    = row.at_xpath("td[#{col_adjust + 4}]").try(:to_s).try(:strip)
                status_img          = row.at_xpath("td[#{col_adjust + 5}]/span/img").try(:to_s).try(:strip)
                # status_text         = row.at_xpath("td[5]/span/span").try(:text).try(:to_s).try(:strip)

                # repository search is sloppy, check marker symbol match for row
                next unless gene_symbol == marker_symbol

                puts "EMMA id            : #{emmaid}"
                puts "gene_symbol        : #{gene_symbol}"
                puts "common_strain_name : #{common_strain_name}"
                puts "int_strain_desig   : #{int_strain_desig}"
                puts "status_img         : #{status_img}"

                allele_name = nil
                if int_strain_desig && ( int_strain_desig.include? "<sup>")
                    extracted_allele     = int_strain_desig.match(/.*<sup>(.*)<\/sup>/)[1]
                    allele_name          = extracted_allele
                else
                    next
                end

                puts "allele name in repo: #{allele_name}"

                row_available = false
                if ( status_img =~ /.*(green_dot).*/ ) || ( status_img =~ /.*(yellow_dot).*/ )
                    row_available = true
                end

                if row_available
                    puts "product available"
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