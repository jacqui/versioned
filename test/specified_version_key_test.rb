require 'test_helper'

class SpecifiedVersionKey < Test::Unit::TestCase
  context 'A specified version key' do
    setup do
      @name = "Blah"
      @loser = Loser.create(:name => @name)
      @version = @loser.version
    end
    should 'be used for the initial version' do
      assert_equal @loser.revision, @loser.version
      assert_equal @loser.revision, @loser.versions.first.number
    end

    context 'after an update' do
      setup do
        @initial_version = @loser.version
        @initial_count = @loser.versions.count
        @initial_name = @loser.name
        @name = 'Blip'
        @loser.name = @name
        @loser.save
        @version = @loser.version
        @count = @loser.versions.count
      end

      should 'have a different version number' do
        assert_not_equal @initial_version, @loser.version
      end

      should 'still be using the specified key' do
        assert_equal @loser.revision, @loser.version
        assert_equal @loser.revision, @loser.versions.last.number
      end

      should 'version count should have increased by one' do
        assert_equal @initial_count + 1, @count
      end
      
      should 'revert properly' do
        @loser.revert_to!(@initial_version)
        assert_equal @initial_name, @loser.name
        assert_equal @count + 1, @loser.versions.count
        assert_not_equal @version, @loser.version
        assert_not_equal @initial_version, @loser.version
      end
    end
  end
end
