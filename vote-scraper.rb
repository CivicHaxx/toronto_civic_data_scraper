# mechanize is used to get the member ids from the json form
require 'mechanize'
# net/http is used to post form data
require 'net/http'
require "awesome_print"
require "csv"

require "pry"
require 'data_mapper'

DataMapper.setup( :default, "sqlite3:database.sqlite3" )

class VoteRecord
  include DataMapper::Resource

  property :id, 						Serial
  property :name, 					String
  property :councillor_id, 	String
  property :csv_raw, 				Text
end

class ParsedCSV
	include DataMapper::Resource

	property :id, 								Serial
  property :committee, 					String
  property :date_time, 					String
  property :agenda_item_number, String
  property :agenda_item_title, 	String
  property :motion_type, 				String
  property :vote, 							String
  property :result, 						String
  property :vote_description, 	String
  property :vote_record_id,			Integer

  belongs_to :vote_record
end

DataMapper.finalize
DataMapper.auto_upgrade!

def get_data
	# create a agent to go get ids
	agent = Mechanize.new
	url = URI('http://app.toronto.ca/tmmis/getAdminReport.do')
	report_function = '?function=prepareMemberVoteReport'

	# send the agent to the page
	page = agent.get(url + report_function)
	#and grab the correct form
	form = page.form('adminReportForm')

	#add member names and ids to an array
	members = []
	member_field = form.field_with(:name => "memberId")
	member_field.options.each { |member| members << [member.text, member.value] }

	#delete the first one
	members.delete(["---Select Member---", "0"])

	# create an empty hash for our results
	result = {}

	# go through each member in the array and add the vote data to the hash
	results = members[0..4].map do |member|
		name = member[0]
		id = member[1]
		params = { 
			toDate: "",
			termId: 6,
			sortOrder: "",
			sortBy: "",
			page: 0,
			memberId: id,
			itemsPerPage: 50,
			function: "getMemberVoteReport",
			fromDate: "",
			exportPublishReportId: 2,
			download: "csv",
			decisionBodyId: 0
		}
		# votes = Net::HTTP.post_form(url, params).body
		# result[id.to_sym] = [name, votes]
		# {
		# 	councillor_id: id,
		# 	name: name,
		# 	csv: Net::HTTP.post_form(url, params).body
		# }
		v = VoteRecord.create!({
			name: name,
			councillor_id: id,
			csv_raw: Net::HTTP.post_form(url, params).body
		})

		persist_csv(v.csv_raw, v.id)
	end
end

# raw_data = VoteRecord.all.first.csv_raw

def persist_csv(csv_raw, vote_record_id)
	parsed = CSV.parse(csv_raw.scrub, headers: true)
	parsed.each do |row|
		entries = row.to_h.values
		ParsedCSV.create!({
  		committee: 					entries[0],
  		date_time:  				entries[1],
  		agenda_item_number: entries[2],
  		agenda_item_title:  entries[3],
  		motion_type:        entries[4], 
  		vote:  							entries[5],
  		result:   					entries[6],
  		vote_description:   entries[7],
  		vote_record_id:  		vote_record_id
		})
	end
end

binding.pry

puts ""
# ap result
# do something cool with the data now