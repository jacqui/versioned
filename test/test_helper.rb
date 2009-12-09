%w{rubygems mongo_mapper shoulda mongo/gridfs mime/types}.each {|f| require f}

MongoMapper.database = "test-versions"

class ActiveSupport::TestCase
  def teardown
    MongoMapper.connection.drop_database "test-attachments"
    MongoMapper.database = "test-attachments"
  end
  def inherited(base)
    base.define_method teardown do 
      super
    end
  end
end