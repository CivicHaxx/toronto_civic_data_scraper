# encoding: utf-8
require "net/http"
require "awesome_print"
require "csv"
require "pry"
require "nokogiri"
require "open-uri"
require "active_support/all"
require "active_record"

require_relative "./db_setup.rb"
require_relative "./db/migrations/001_create_vote_records_table.rb"

configuration = YAML::load(IO.read("config/database.yml"))
ActiveRecord::Base.establish_connection(configuration["development"])

#CreateVoteRecordsTable.migrate(:change)

class VoteRecord < ActiveRecord::Base
end

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
    members[1..-1].each do |member|
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
      csv = Net::HTTP.post_form(base, params).body
      CSV.parse(csv.scrub,
                headers: true,
                header_converters: lambda { |h| h.try(:parameterize).try(:underscore) })
         .map{|x| x.to_hash.symbolize_keys }
         .map{|x| x.merge(councillor_id: member[:id], councillor_name: member[:name]) }
         .each{|x|
          begin
             VoteRecord.create!(x)
          rescue Encoding::UndefinedConversionError
             puts "Try re encoding it"
             record = Hash[x.map {|k, v| [k.to_sym, v.force_encoding('utf-8').scrub('')] }]
             VoteRecord.create!(record)
          end
         }
    end
  end

end

# results.first.map{|x| [x[:date_time].to_time, x[:date_time]] }
binding.pry

puts ""
