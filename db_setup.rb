require "sqlite3"
require 'data_mapper'
require "dm-sqlite-adapter"

DataMapper.setup( :default, "sqlite3:database.sqlite3" )

class VoteEvent
	include DataMapper::Resource

	property :id, 								Serial
  property :committee,          String
  property :date_time,          String
  property :agenda_item,        String
  property :agenda_item_title,  String
  property :motion_type,        String
  property :vote,               String
  property :result,             String
  property :vote_description,   Text
  property :councillor_id,      Integer
  property :councillor_name,    Integer

end

DataMapper.finalize
DataMapper.auto_upgrade!

