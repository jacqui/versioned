require 'test_helper'

class LockTest < Test::Unit::TestCase
  context 'An unversioned model with locks' do
    setup do
      @user = UnversionedLockableUser.create(:name => 'Kurt')
    end

    should 'have a lock_version field' do
      assert_not_nil @user.lock_version
    end

    should 'save just fine when no conflicts' do
      @user.name = 'Bob'
      assert @user.save
    end

    should 'save just fine when given the proper lock version' do
      u = UnversionedLockableUser.find(@user.id)
      @user.update_attributes(:name => 'Bill')

      assert u.update_attributes(:name => 'Jose', :lock_version => @user.lock_version)
    end

    should 'not save when given the wrong version' do
      assert_raise Versioned::StaleDocumentError do
        @user.update_attributes(:name => 'Bob', :lock_version => 1111)
      end

      # lock_version should match what we passed in
      assert_equal 1111, @user.lock_version
    end
  end
  context 'A versioned model with locks' do
    setup do
      @user = LockableUser.create(:name => 'Kurt', :required_field => 'woo!')
    end

    should 'have a lock_version field' do
      assert_not_nil @user.lock_version
      assert_equal @user.version, @user.lock_version
    end

    should 'save just fine when no conflicts' do
      @user.name = 'Bob'
      assert @user.save
    end

    should 'save just fine when given the proper lock version' do
      u = LockableUser.find(@user.id)
      @user.update_attributes(:name => 'Bill')

      assert u.update_attributes(:name => 'Jose', :lock_version => @user.lock_version)
    end

    should 'not save when given the wrong version' do
      assert_raise Versioned::StaleDocumentError do
        @user.update_attributes(:name => 'Bob', :lock_version => 1111)
      end

      # lock_version should match what we passed in
      assert_equal 1111, @user.lock_version
    end

    should 'be revertable with the lock version' do
      v = @user.lock_version
      name = @user.name
      @user.update_attributes(:name => "Schlub")

      assert_not_equal v, @user.lock_version

      @user.revert_to(v)

      assert_equal name, @user.name
      assert_not_equal v, @user.lock_version #shouldn't have reverted version
    end

    should 'accept a specified version on create' do
      u = LockableUser.create(:name => 'Burt', :required_field => 'woo!', :lock_version => 1111)
      assert_equal 1111, u.lock_version
    end

    should "have same lock_version when validation fails" do
      @user.required_field = nil
      v = @user.lock_version
      result = @user.save
      assert !result
      assert_equal v, @user.lock_version
    end
  end
end
