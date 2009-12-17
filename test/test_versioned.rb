require "test_helper"

require File.expand_path(File.dirname(__FILE__) + '/../lib/versioned')
require File.expand_path(File.dirname(__FILE__) + '/../lib/version')

class Doc
  include MongoMapper::Document
  include Versioned
  key :title, String
end

MongoMapper.connection.drop_database DB_NAME
MongoMapper.database = DB_NAME

class VersionTest < Test::Unit::TestCase
  
  context "A Content Instance" do
    
    setup do
      @doc = Doc.create(:title=>"Foo")   
    end
    
    should "respond to versions" do
      assert @doc.respond_to?(:versions)
    end
    
    should "have before_save callback" do
      assert Doc.before_update.collect(&:method).include?(:save_version)
    end
    
    context "after update" do
      setup do
        @doc.title = "Version 2"
        @doc.save
      end

      should "create a version after update" do
        assert_equal(1, @doc.versions.count)
      end
      
      should "have the correct version number" do
        assert_equal(1, @doc.versions.first.version_number)
      end

      should "update the model's version key" do
        assert_equal(1, @doc.version)
      end
      
      should "have :title in changes" do
        assert_contains(@doc.versions.first.changed_attrs.keys, "title")
      end
      
      should "revert to last version" do
        @doc.revert
        assert_equal(@doc.title, "Foo")
      end
      
      should "revert by version #" do
        @doc.title = "Version 3"
        @doc.save
        @doc.revert_to_version 2
        assert_equal("Version 2", @doc.title)
      end
      
      should "retrieve a specific version without reverting it" do
        @doc.title = "Version 3"
        @doc.save
        version_count = @doc.versions.size
        @doc.retrieve_version 2
        assert_equal version_count, @doc.versions.size
      end
      should "cleanup versions on destroy" do
        @doc.destroy
        assert_equal(0, Version.count)
      end
      
    end
    
  end
end
