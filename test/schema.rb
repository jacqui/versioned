MongoMapper.connection = Mongo::Connection.new('127.0.0.1')
MongoMapper.database = "testing_versioned"

class User
  include MongoMapper::Document
  include Versioned
  key :first_name, String
  key :last_name, String
  timestamps!
  
  def name
    [first_name, last_name].compact.join(' ')
  end

  def name=(names)
    self[:first_name], self[:last_name] = names.split(' ', 2)
  end
end

User.destroy_all
Version.destroy_all