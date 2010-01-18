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

class Loser
  include MongoMapper::Document
  extend Versioned::ClassMethods
  versioned :use_key => :revision
  key :revision, Integer
  key :name, String
  timestamps!

  before_save :set_revision

  def set_revision
    write_attribute :revision, (Time.now.to_f * 1000).ceil
  end
end

class LockableUser
  include MongoMapper::Document
  include Versioned
  locking!

  key :name, String
  key :required_field, String
  validates_presence_of :required_field
end

class UnversionedLockableUser
  include MongoMapper::Document
  extend Versioned::ClassMethods
  locking!
  
  key :name, String
end

User.destroy_all
Loser.destroy_all
Version.destroy_all
