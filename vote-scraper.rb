# mechanize is used to get the member ids from the json form
require 'mechanize'
# net/http is used to post form data
require 'net/http'

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
members.each do |member|
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
	votes = Net::HTTP.post_form(url, params).body
	result[id.to_sym] = [name, votes]
end

# do something cool with the data now