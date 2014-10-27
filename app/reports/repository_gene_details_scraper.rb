#!/usr/bin/env ruby

# Select the gene list from the Komp website
# ruby -r "./app/helpers/repository_gene_details_scraper.rb" -e "RepositoryGeneDetailsScraper.new.fetch_komp_catalog_gene_list"

require 'rubygems'
require 'nokogiri'
require 'open-uri'

class RepositoryGeneDetailsScraper

    attr_accessor :komp_gene_details
    attr_accessor :count_is_mice
    attr_accessor :count_is_recovery
    attr_accessor :count_is_germ_plasm
    attr_accessor :count_is_embryos
    attr_accessor :count_unique_alleles_found
    attr_accessor :count_unique_alleles_with_products

    # URLs for scraping KOMP websites
    KOMP_REPO = 'KOMP Repo'
    KOMP_GENES_CATALOG_PAGE_URL = 'https://www.komp.org/catalog.php?available=&mutation=&gname=&project=&origin=&'
    KOMP_GENE_PAGE_URL_STUB = 'https://www.komp.org/geneinfo.php?geneid='
    KOMP_GENE_SEARCH_STUB = 'https://www.komp.org/searchresult.php?query='

    def initialize
        # instance variables
         @komp_gene_details                  = {}
         @count_is_mice                      = 0
         @count_is_recovery                  = 0
         @count_is_germ_plasm                = 0
         @count_is_embryos                   = 0
         @count_unique_alleles_found         = 0
         @count_unique_alleles_with_products = 0
    end

    ##
    # Pull out the geneids for all genes in the Komp catalog
    ##
    def fetch_komp_catalog_gene_list( repo_url )

        puts "Fetching Komp gene list"
        @komp_gene_details = {}

        # process catalog table from Komp website
        count_updates   = 0
        count_unchanged = 0
        begin
            if ( repo_url.nil? )
                repo_url = KOMP_GENES_CATALOG_PAGE_URL
            end

            page = Nokogiri::HTML(open(repo_url))
            catalog_rows = page.css("#catalog tbody tr")
            catalog_rows.each do |row|
                # gene id
                gene_id_href_nodeset = row.xpath('./td[1]/a/@href')
                if ( gene_id_href_nodeset.first.nil? )
                    next
                end
                gene_id_url = gene_id_href_nodeset.first.value
                # now we have the URL extract the geneid
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
                   next
                end

                # add into hash
                @komp_gene_details[marker_symbol] = {
                    'geneid'               => geneid
                }

                # store it on the genes table matching on marker symbol
                if ( save_komp_geneid_for_marker_symbol( marker_symbol, geneid ) )
                    puts "Found gene #{marker_symbol} with geneid #{geneid}"
                    count_updates += 1
                else
                    count_unchanged += 1
                end
            end
        rescue => e
          puts "ERROR : failed to extract catalog gene data"
          puts "Exception message : #{e.message}"
        end

        # puts "Gene details:"
        # pp @komp_gene_details
        puts "Count of updates to Komp geneid on genes table = #{count_updates}"
        puts "Count of unchanged Komp geneids on genes table = #{count_updates}"
    end

    def save_komp_geneid_for_marker_symbol( marker_symbol, geneid )

        gene = Gene.find_by_marker_symbol( marker_symbol )
        if gene.nil?
            puts "ERROR : failed to identify gene for marker symbol #{marker_symbol}, cannot save Komp geneid"
        else
            if ( gene.komp_repo_geneid.nil? || ( gene.komp_repo_geneid != geneid ) )
                gene.komp_repo_geneid = geneid
                gene.save
                return true
            end
        end

        return false
    end

    # # fetch the allele details for all the genes in the Komp catalog list (limited by gname in URL, used for testing)
    # def fetch_komp_allele_details_for_all_genes()

    #     timeStart = Time.new
    #     puts "start at #{timeStart.inspect}"

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
    #     puts "Count of genes to process = #{@komp_gene_details.count()}"
    #     count_genes_processed = 0
    #     sleeptime_total = 0
    #     @komp_gene_details.each do |curr_marker_symbol, gene_details|

    #         pp gene_details

    #         # delay for random time in seconds before processing
    #         if ( is_first_time == true )
    #             is_first_time = false
    #         else
    #             sleeptime = rand(7)
    #             sleep(3 + sleeptime)
    #             sleeptime_total = sleeptime_total + sleeptime + 3
    #         end

    #         puts "Processing : marker symbol - #{curr_marker_symbol}, Komp gene_id - #{gene_details['geneid']}"
    #         fetch_komp_allele_details( curr_marker_symbol, @komp_gene_details[curr_marker_symbol]['geneid'] )
    #         count_genes_processed += 1
    #     end

    #     # pp @komp_gene_details

    #     puts "Count of genes processed = #{count_genes_processed}"
    #     puts "Total sleeptime = #{sleeptime_total}"

    #     timeEnd = Time.new
    #     duration_string = duration( timeEnd - timeStart )
    #     puts "stop at #{timeEnd.inspect}"
    #     puts "duration = #{duration_string}"
    #     puts "total sleeptime = #{sleeptime_total} secs"

    #     return
    # end

    # # duration display (for testing)
    # def duration( time_in_secs )
    #     ms    = (time_in_secs.modulo(1) * 1000).to_i
    #     secs  = time_in_secs.to_int
    #     mins  = secs / 60
    #     hours = mins / 60
    #     days  = hours / 24

    #     if days > 0
    #       "#{days} days and #{hours % 24} hours and #{mins % 60} minutes and #{secs % 60} seconds and #{ms} msecs"
    #     elsif hours > 0
    #       "#{hours} hours and #{mins % 60} minutes and #{secs % 60} seconds and #{ms} msecs"
    #     elsif mins > 0
    #       "#{mins} minutes and #{secs % 60} seconds and #{ms} msecs"
    #     elsif secs > 0
    #       "#{secs} seconds and #{ms} msecs"
    #     elsif ms >= 0
    #       "#{ms} msecs"
    #     end
    # end

    ##
    # Fetch the allele details from the komp subpage for a specific gene
    # and return a hash of gene details
    ##
    def fetch_komp_allele_details( marker_symbol, geneid )

        if ( marker_symbol.nil? )
            puts "ERROR : no marker symbol input to fetch_komp_allele_details_by_marker_symbol, cannot continue"
            return
        end

        if ( geneid.nil? )
            puts "WARN : no geneid input to fetch_komp_allele_details_by_marker_symbol"
            # attempt to scrape gene id from komp site
            geneid = fetch_komp_geneid_for_marker_symbol( marker_symbol )
            if ( geneid.nil? )
                puts "ERROR : cannot select allele details, no geneid found for marker symbol #{marker_symbol}, cannot continue"
                return
            end
        end

        puts "Repo Scraper geneid = #{geneid}"

        gene_table = nil

        # now use geneid to pull the subpage from Komp
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

            # to hold hash of allele details in main hash
            @komp_gene_details[marker_symbol] = { 'alleles' => {} }

            if ( gene_table.nil? || gene_table.blank? )
                puts "WARN : could not locate targeting projects table in sub-page for marker symbol #{marker_symbol}, perhaps no products"
            else
                # cycle through rows in table
                process_komp_targeting_table( gene_table, marker_symbol )
            end
        rescue => e
            puts "ERROR : failed to fetch product details for gene #{marker_symbol}"
            puts "Exception message : #{e.message}"
            return
        end

        return @komp_gene_details[marker_symbol]
    end

    def fetch_komp_geneid_for_marker_symbol( marker_symbol )

        if ( @komp_gene_details.nil? || @komp_gene_details.count() == 0 )
            # try selecting a limited catalog listing and extracting the gene id
            repo_url = KOMP_GENES_CATALOG_PAGE_URL
            repo_url["gname="] = "gname=#{marker_symbol}"
            puts "Repo URL : #{repo_url}"
            self.fetch_komp_catalog_gene_list( repo_url )
        end

        # fetch geneid from main hash for this marker symbol
        geneid = 0
        if @komp_gene_details.has_key?(marker_symbol)
            geneid = @komp_gene_details[marker_symbol]['geneid']
        else
            puts "WARN : no entry found in komp gene list for marker symbol #{marker_symbol}, searching"
            geneid = search_komp_for_marker_symbol( marker_symbol )
        end

        if ( geneid.nil? || geneid == 0 )
            puts "ERROR : unable to identify a geneid for marker symbol #{marker_symbol}"
            return
        end

        return geneid
    end

    # some genes are not displayed in the catalog listing but do exist in komp, so use search
    def search_komp_for_marker_symbol( marker_symbol )

        search_url = KOMP_GENE_SEARCH_STUB + "#{marker_symbol}"
        puts "Search URL : #{search_url}"
        page = Nokogiri::HTML(open(search_url))
        page_title = page.css("head title").text
        puts "Page title = #{page_title}"

        # search outcome one of three types:
        if ( page_title == 'Search Result' )
            if ( ( page.xpath( '//*[@id="main_body_td"]/b[2]').text ) == 'no' )
                # 1. No result -> gene not in repository, return nil
                puts "WARN : No result found in search of repository for marker symbol #{marker_symbol}"
                return
            elsif ( page.xpath( '//*[@id="main_body_td"]/table/thead/tr[1]/th' ).text == 'KOMP Search Results' )
                # 2. There is a Search sub-page -> select geneid from links on this page and store, then fetch_komp_allele_details, return geneid
                page.xpath('//*[@id="main_body_td"]/table/tr').each do |row|
                    # check for match to our marker_symbol
                    row_ms = row.xpath( './td[1]/a[1]/b/i' ).text.strip
                    if ( row_ms.nil? )
                        next
                    end
                    if ( row_ms == marker_symbol )
                        # correct row, pull put gene id
                        gene_id_href_nodeset = row.xpath('./td[1]/a/@href')
                        if ( gene_id_href_nodeset.first.nil? )
                            puts "ERROR : failed to locate gene info nodeset in search row"
                            return
                        end
                        gene_id_url = gene_id_href_nodeset.first.value
                        split_url = gene_id_url.match(/([^\?]*)\?geneid=(\d*)/)
                        geneid = split_url[2].to_s
                        puts "geneid extracted from search sub-page : #{geneid}"

                        # save geneid into genes
                        save_komp_geneid_for_marker_symbol( marker_symbol, geneid )

                        # fetch gene details for gene id into main hash
                        fetch_komp_allele_details( marker_symbol, geneid )

                        return geneid
                    end
                end # search result row

                puts "ERROR : failed to locate gene marker symbol in search sub-page, cannot extract geneid"
                return
            else
                # unrecognised search result
                puts "ERROR : Unrecognised page format when searching Komp repository for marker symbol #{marker_symbol}"
                return
            end
        else
            # 3. Direct to normal gene products page
            geneid = String(nil)
            page.xpath('//a/@href').each do |link|
                if ( link.value.nil? )
                    next
                end
                gene_id_url = link.value
                split_url = gene_id_url.match(/([^\?]*)\?geneid=(\d*)/)
                if ( split_url.nil? )
                    next
                end
                geneid = split_url[2].to_s
            end

            if ( geneid.nil? || geneid == "" )
                puts "ERROR : unable to locate geneid on searching Komp repository for marker symbol #{marker_symbol}"
                return
            end

            # save geneid into genes
            save_komp_geneid_for_marker_symbol( marker_symbol, geneid )

            # fetch gene details for gene id into main hash
            fetch_komp_allele_details( marker_symbol, geneid )

            return geneid
        end
    end

    # Scrape data from the gene sub-page targeting table
    def process_komp_targeting_table( gene_table, marker_symbol )

        # check gene table present, repository may have no information
        if ( gene_table.nil? )
            return
        end

        # cycle through rows in table
        gene_table_rows = gene_table.css('tr')
        gene_table_rows.each do |row|

            # identify allele rows
            allele = row.css('td small sup').text.to_s
            if ( allele.nil? || allele.empty? )
                next
            end

            puts "Komp allele found : #{allele}"

            # cycle through cells in this row to look for order buttons
            is_mice           = 0
            is_recovery       = 0
            is_germ_plasm     = 0
            is_embryos        = 0

            row_cells = row.css('td')

            row_cells.each do |cell|

                anchor_node = cell.css('a').first

                if anchor_node.nil?
                    next
                end

                anchor_text = anchor_node.text.to_s

                if ( anchor_text.nil? || anchor_text.empty? )
                    next
                end

                # puts "anchor node anchor text = #{anchor_text}"

                if ( anchor_text == 'Order' )
                    # this cell represents an order button, now check if of type we want to flag
                    # example=    orders.php?project=VG15514&mutation=tm1.1(KOMP)Vlcg&product=mice
                    href_nodeset    = anchor_node.xpath('@href')
                    href_node       = href_nodeset.first
                    href_node_text  = href_node.value
                    split_href      = href_node_text.match(/([^\?]*)\&product=(\w*)/)

                    # filter out cells that do not have product buttons
                    if ( split_href.nil? )
                        next
                    end

                    if ( split_href.length < 2 )
                        puts "WARN : product regex match for targeting table cell unexpected count"
                        next
                    end

                    # extract the product value e.g. mice and set flags
                    product = split_href[2].to_s
                    case product
                        when 'mice'
                            is_mice          = 1
                        when 'mice'
                            is_recovery      = 1
                        when 'sperm'
                            is_germ_plasm    = 1
                        when 'embryos'
                            is_embryos       = 1
                        else
                            # other buttons/order types are ignored
                    end # case
                end # order
            end

            # sometimes the allele is listed twice, do not overwrite positives
            if ( @komp_gene_details[marker_symbol]['alleles'].has_key?(allele) )
                if ( is_mice == 1 )
                    @komp_gene_details[marker_symbol]['alleles'][allele]['is_mice'] = 1
                end
                if ( is_recovery == 1 )
                    @komp_gene_details[marker_symbol]['alleles'][allele]['is_recovery'] = 1
                end
                if ( is_germ_plasm == 1 )
                    @komp_gene_details[marker_symbol]['alleles'][allele]['is_germ_plasm'] = 1
                end
                if ( is_embryos == 1 )
                    @komp_gene_details[marker_symbol]['alleles'][allele]['is_embryos'] = 1
                end
            else
                @count_unique_alleles_found += 1

                @count_is_mice += 1       if ( is_mice == 1 )
                @count_is_recovery += 1   if ( is_recovery == 1 )
                @count_is_germ_plasm += 1 if ( is_germ_plasm == 1 )
                @count_is_embryos += 1    if ( is_embryos == 1 )

                if ( ( is_mice == 1 ) || ( is_recovery == 1 ) || ( is_germ_plasm == 1 ) || ( is_embryos == 1 ) )
                    @count_unique_alleles_with_products += 1
                end

                @komp_gene_details[marker_symbol]['alleles'][allele] = {
                    'is_mice'              => is_mice,
                    'is_recovery'          => is_recovery,
                    'is_germ_plasm'        => is_germ_plasm,
                    'is_embryos'           => is_embryos
                }
            end
        end # gene_table_row

        return
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