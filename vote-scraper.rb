require_relative './db_setup.rb'

require 'net/http'
require "awesome_print"
require "csv"
require "pry"
require "nokogiri"
require "open-uri"
require "active_support/all"

def run
  base = URI("http://app.toronto.ca/tmmis/getAdminReport.do")

  term_url = "http://app.toronto.ca/tmmis/getAdminReport.do" +
             "?function=prepareMemberVoteReport&termId="

  term_ids = [3,4,6]

  term_ids.each do |term_id|
    puts "Getting term #{term_id}"
    term_page = Nokogiri::HTML(open(term_url + term_id.to_s))
    members = term_page.css("select[name='memberId'] option")
                  .map do |x|
                    {
                      id:    x.attr("value"),
                      name:  x.text
                    }
                  end
    results = members[1..-1].each do |member|
      puts "Getting member vote report for #{member[:name]}"
      params = {
        toDate: "",
        termId: term_id,
        sortOrder: "",
        sortBy: "",
        page: 0,
        memberId: member[:id],
        itemsPerPage: 50,
        function: "getMemberVoteReport",
        fromDate: "",
        exportPublishReportId: 2,
        download: "csv",
        decisionBodyId: 0
      }
      #CSV.foreach(file, :headers => true, :header_converters => lambda { |h| h.try(:downcase) })
      csv = Net::HTTP.post_form(base, params).body
      eh = CSV.parse(csv.scrub,
                headers: true,
                header_converters: lambda { |h| h.try(:parameterize).try(:underscore) })
         .map{|x| x.to_hash.symbolize_keys }
         .map{|x| x.merge(councillor_id: member[:id], councillor_name: member[:name]) }
         .each{|x| binding.pry }
         #.each{|x| VoteEvent.create!(x) }
      #binding.pry
    end
  end

end

# results.first.map{|x| [x[:date_time].to_time, x[:date_time]] }
binding.pry

puts ""
