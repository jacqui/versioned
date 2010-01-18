require 'test_helper'

class CreationTest < Test::Unit::TestCase
  context 'The number of versions' do
    setup do
      @name = 'Steve Richert'
      @user = User.create(:name => @name)
      @count = @user.versions.count
    end

    should 'initially equal one' do
      assert_equal 1, @count
    end

    should 'not increase when no changes are made in an update' do
      @user.name =  @name
      assert_equal @count, @user.versions.count
    end

    should 'not increase when no changes are made before a save' do
      @user.save
      assert_equal @count, @user.versions.count
    end

    should 'not increase when reverting to the current version' do
      @user.revert_to!(@user.version)
      assert_equal @count, @user.versions.count
    end

    context 'after an update' do
      setup do
        @initial_count = @count
        @name = 'Steve Jobs'
        @user.name = @name
        @user.save
        @count = @user.versions.count
      end

      should 'increase by one' do
        assert_equal @initial_count + 1, @count
      end

      should 'increase by one when reverted' do
        @user.revert_to!(:first)
        assert_equal @count + 1, @user.versions.count
      end

      should 'not increase until a revert is saved' do
        @user.revert_to(:first)
        assert_equal @count, @user.versions.count
        @user.save
        assert_not_equal @count, @user.versions.count
      end
    end
    
    should "retrieve a specific version without reverting it" do
      @user.name = "Hoge"
      @user.save
      version_count = @user.versions.size
      @user.retrieve_version 2
      assert_equal version_count, @user.versions.size
    end

    context 'after multiple updates' do
      setup do
        @initial_count = @count
        @new_name = 'Steve Jobs'
        @user.name = @new_name
        @user.name = @name
        @count = @user.versions.count
      end

      should 'not increase when reverting to an identical version' do
        @user.revert_to!(:first)
        assert_equal @count, @user.versions.count
      end
    end
  end
end
