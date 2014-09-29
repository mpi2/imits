#!/usr/bin/env ruby

# Select the gene list from the Komp website
# ruby -r "./app/helpers/repository_gene_details_scraper.rb" -e "RepositoryGeneDetailsScraper.new.fetch_komp_catalog_gene_list"

require 'pp'
require 'rubygems'
require 'nokogiri'
require 'open-uri'

class RepositoryGeneDetailsScraper

    # URLs for scraping KOMP websites
    KOMP_GENES_CATALOG_PAGE_URL = 'https://www.komp.org/catalog.php?available=&mutation=&gname=J&project=&origin=&'
    KOMP_GENE_PAGE_URL_STUB = 'https://www.komp.org/geneinfo.php?geneid='

    def initialize
        # instance variables
         @komp_gene_details = {}
    end

    ##
    # Pull out the geneids for all genes in the Komp catalog
    ##
    def fetch_komp_catalog_gene_list()

        puts "Fetching Komp gene list"

        # process catalog table from Komp website
        begin
            page = Nokogiri::HTML(open(KOMP_GENES_CATALOG_PAGE_URL))
            catalog_rows = page.css("#catalog tbody tr")
            catalog_rows.each do |row|

                # gene id
                gene_id_href_nodeset = row.xpath('./td[1]/a/@href')
                gene_id_url = gene_id_href_nodeset.first.value
                # now we have the URL extract the geneid and turn it into an int
                split_url = gene_id_url.match(/([^\?]*)\?geneid=(\d*)/)
                geneid = split_url[2].to_s

                # gene marker symbol
                marker_symbol = row.xpath('./td[1]/a/b/i/text()[1]').to_s

                # project
                # project = row.xpath('./td[2]/text()[1]').to_s

                # origin
                origin = row.xpath('./td[3]/text()[1]').to_s

                # products
                # products_1 = row.xpath('./td[4]/a/text()[1]').to_s
                # products_2 = row.xpath('./td[4]/a/text()[2]').to_s

                #  filter out 'UCD internal' es cell rows
                if ( origin == 'UCD internal' )
                    # puts "Skipping UCD internal row for #{marker_symbol}"
                    next
                end

                # add into hash
                @komp_gene_details[marker_symbol] = {
                    'geneid'               => geneid
                }
            end
        rescue => e
          puts "ERROR : failed to extract catalog gene data"
          puts "Exception message : #{e.message}"
        end

        puts "Gene details:"
        pp @komp_gene_details
    end

    # fetch the allele details for ALL the genes in the Komp catalog list (used for testing)
    # def fetch_komp_allele_details_for_all_genes()
    #     # if @komp_gene_details is empty call fetch_komp_catalog_gene_list()
    #     if ( @komp_gene_details.count() == 0 )
    #         fetch_komp_catalog_gene_list()
    #         if ( @komp_gene_details.count() == 0 )
    #             puts "ERROR : no gene details in list, cannot continue"
    #             return
    #         end
    #     end

    #     # for each marker symbol key in @komp_gene_details, call method to fetch
    #     # details from the genes sub-page in Komp
    #     is_first_time = true
    #     @komp_gene_details.each do |curr_marker_symbol, gene_details|
    #         # delay for random time in seconds before processing
    #         if ( is_first_time == true )
    #             is_first_time = false
    #         else
    #             sleep(3 + rand(7))
    #         end

    #         puts "Processing : marker symbol - #{curr_marker_symbol}, Komp gene_id - #{gene_details['geneid']}"
    #         fetch_komp_allele_details_by_marker_symbol( curr_marker_symbol )
    #     end

    #     pp @komp_gene_details
    # end

    ##
    # Fetch the allele details from the komp subpage for a specific gene marker symbol
    # and return a hash of gene details
    ##
    def fetch_komp_allele_details_by_marker_symbol( marker_symbol )

        gene_table = nil

        # TODO : change this section to fetch geneid from gene table once stored there
        if @komp_gene_details.nil?
            self.fetch_komp_catalog_gene_list()
        end

        # fetch geneid from main hash for this marker symbol
        unless @komp_gene_details.has_key?(marker_symbol)
            puts "ERROR : no gene details in list for marker symbol #{marker_symbol}, cannot continue"
            return
        end

        geneid = @komp_gene_details[marker_symbol]['geneid']

        # puts "geneid for #{marker_symbol} is #{geneid}"
        if geneid.nil? || geneid.empty?
            puts "ERROR : no geneid found for marker symbol #{marker_symbol}, cannot continue"
            return
        end

        # use geneid to pull the subpage from Komp
        begin
            gene_specific_url = "#{KOMP_GENE_PAGE_URL_STUB}#{geneid}"
            page = Nokogiri::HTML(open( gene_specific_url ))

            # identify the correct table
            page_tables = page.css('#main_body_td table')
            page_tables.each do |table|
                if is_komp_targeting_projects_table?( table )
                    gene_table = table
                end
            end # page_tables

            if ( gene_table.nil? || gene_table.blank? )
                puts "ERROR : could not locate targeting projects table in sub-page for marker symbol #{marker_symbol}, cannot continue"
                return
            else
                # cycle through rows in table
                process_komp_targeting_table( gene_table, marker_symbol )
            end
        rescue => e
            puts "ERROR : failed to fetch product details for gene #{marker_symbol}"
            puts "Exception message : #{e.message}"
        end

        return @komp_gene_details[marker_symbol]
    end

    # Scrape data from the gene sub-page targeting table
    def process_komp_targeting_table( gene_table, marker_symbol )

        # save hash of allele details in main hash
        @komp_gene_details[marker_symbol] = { 'alleles' => {} }

        # cycle through rows in table
        gene_table_rows = gene_table.css('tr')
        gene_table_rows.each do |row|
            # identify allele rows
            allele = row.css('td small sup').text.to_s
            if ( allele.nil? || allele.empty? )
                next
            end

            # puts "Allele : #{allele}"

            # cycle through cells in this row to look for order buttons
            is_live_mice      = 0
            is_cryo_recovery  = 0
            is_germ_plasm     = 0
            is_embryos        = 0

            row_cells = row.css('td')
            row_cells.each do |cell|
                anchor_node = cell.css('a')
                anchor_text = anchor_node.text.to_s
                if ( anchor_text.nil? || anchor_text.empty? )
                    next
                end
                if ( anchor_text == 'Order' )
                    # this cell represents an order button, now check if of type we want to flag
                    href_text = cell.css('a/@href').text.to_s
                    # example=    orders.php?project=VG15514&mutation=tm1.1(KOMP)Vlcg&product=mice
                    href_nodeset = anchor_node.xpath('@href')
                    href_node = href_nodeset.first.value
                    split_href = href_node.match(/([^\?]*)\&product=(\w*)/)
                    # pp split_href

                    # filter out cells that do not have product buttons
                    if ( split_href.nil? || split_href.length < 2 )
                        # puts "WARN : no product regex match for cell"
                        next
                    end
                    # extract the product value e.g. mice
                    product = split_href[2].to_s

                    case product
                        when 'mice'
                            is_live_mice     = 1
                        when 'recovery'
                            is_cryo_recovery = 1
                        when 'sperm'
                            is_germ_plasm    = 1
                        when 'embryos'
                            is_embryos       = 1
                        else
                            # other buttons/order types are ignored
                    end # case
                end # order
            end

            @komp_gene_details[marker_symbol]['alleles'][allele] = {
                'is_live_mice'         => is_live_mice,
                'is_cryo_recovery'     => is_cryo_recovery,
                'is_germ_plasm'        => is_germ_plasm,
                'is_embryos'           => is_embryos
            }

            # pp @komp_gene_details[marker_symbol]

        end # gene_table_row
    end

    def is_komp_targeting_projects_table?( table )
        table_rows = table.css('tr')
        table_rows.each do |row|
            row_tds = row.css('td')
            row_tds.each do |cell|
                if ( cell.text.match(/Product Availability/) )
                    return true
                end
            end # row_tds
        end # table_rows

        return false
    end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  RepositoryGeneDetailsScraper.new.fetch_komp_catalog_gene_list
end