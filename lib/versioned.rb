require 'version'

module Versioned
  class StaleDocumentError < MongoMapper::MongoMapperError; end
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      versioned
    end
  end

  module LockingInstanceMethods
    private
      #new? isn't working
      def is_new_document?
        (read_attribute(self.version_lock_key).blank? && changes[self.version_lock_key.to_s].blank?) ||
        (changes[self.version_lock_key.to_s] && changes[self.version_lock_key.to_s].first.blank?)
      end
      def prep_lock_version
        old = read_attribute(self.version_lock_key)
        if !is_new_document? || old.blank?
          v = (Time.now.to_f * 1000).ceil.to_s
          write_attribute self.version_lock_key, v
        end

        old
      end

      def save_to_collection(options = {})
        current_version = prep_lock_version
        if is_new_document?
          collection.insert(to_mongo, :safe => true)
        else
          selector = { :_id => read_attribute(:_id), self.version_lock_key => current_version }
          #can't upsert, safe must be true for this to work
          result = collection.update(selector, to_mongo, :upsert => false, :safe => true)

          if result.is_a?(Array) && result[0][0]['updatedExisting'] == false
            write_attribute self.version_lock_key, current_version
            raise StaleDocumentError.new
          elsif !result.is_a?(Array)
            #wtf?
            write_attribute self.version_lock_key, current_version
            raise "Unexpected result from mongo"
          end

          selector[:_id]
        end
      end
  end
  module ClassMethods
    def locking!(options = {})
      include(LockingInstanceMethods)
      class_inheritable_accessor :version_lock_key
      self.version_lock_key = options[:key] || :lock_version
      self.version_use_key = self.version_lock_key

      key self.version_lock_key, Integer
      (self.version_except_columns ||= []) << self.version_lock_key.to_s #don't version the lock key 
    end

    def versioned(options = {})
      class_inheritable_accessor :version_only_columns
      self.version_only_columns = Array(options[:only]).map(&:to_s).uniq if options[:only]
      class_inheritable_accessor :version_except_columns
      self.version_except_columns = Array(options[:except]).map(&:to_s).uniq if options[:except]

      class_inheritable_accessor :version_use_key
      self.version_use_key = options[:use_key]

      many :versions, :as => :versioned, :order => 'number ASC', :dependent => :delete_all do
        def between(from, to)
          from_number, to_number = number_at(from), number_at(to)
          return [] if from_number.nil? || to_number.nil?
          condition = (from_number == to_number) ? to_number : Range.new(*[from_number, to_number].sort)
          if condition.is_a?(Range)
            conditions = {'$gte' => condition.first, '$lte' => condition.last}
          else
            conditions = condition
          end
          find(:all, 
            :number => conditions,
            :order => "number #{(from_number > to_number) ? 'DESC' : 'ASC'}"
          )
        end

        def at(value)
          case value
            when Version then value
            when Numeric then find_by_number(value.floor)
            when Symbol then respond_to?(value) ? send(value) : nil
            when Date, Time then last(:created_at => {'$lte' => value.to_time})
          end
        end

        def number_at(value)
          case value
            when Version then value.number
            when Numeric then value.floor
            when Symbol, Date, Time then at(value).try(:number)
          end
        end
      end

      after_create :create_initial_version
      after_update :create_initial_version, :if => :needs_initial_version?
      after_update :create_version, :if => :needs_version?

      include InstanceMethods
      alias_method_chain :reload, :versions
    end

  end

  module InstanceMethods
    private
      def versioned_columns
        case
          when version_only_columns then self.class.keys.keys & version_only_columns
          when version_except_columns then self.class.keys.keys - version_except_columns
          else self.class.keys.keys
        end - %w(created_at created_on updated_at updated_on)
      end

      def needs_initial_version?
        versions.empty?
      end

      def needs_version?
        !(versioned_columns & changed).empty?
      end

      def reset_version(new_version = nil)
        @last_version = nil if new_version.nil?
        @version = new_version
      end

      def next_version_number(initial = false)
        v = read_attribute self.version_use_key unless self.version_use_key.nil?
        v = 1 if v.nil? && initial
        v = last_version + 1 if v.nil? && !initial
        v
      end
      def create_initial_version
        versions.create(:changes => nil, :number => next_version_number(true))
      end

      def create_version
        versions << Version.create(:changes => changes.slice(*versioned_columns), :number => next_version_number)
        reset_version
      end

    public
      def version
        @version ||= last_version
      end

      def last_version
        @last_version ||= versions.inject(1){|max, version| version.number > max ? version.number : max} 
      end

      def reverted?
        version != last_version
      end

      def reload_with_versions(*args)
        reset_version
        reload_without_versions(*args)
      end

      def changes_between(from, to)
        from_number, to_number = versions.number_at(from), versions.number_at(to)
        return {} if from_number == to_number
        chain = versions.between(from_number, to_number)
        return {} if chain.empty?

        backward = chain.first > chain.last
        backward ? chain.pop : chain.shift

        chain.inject({}) do |changes, version|
          version.changes.each do |attribute, change|
            change.reverse! if backward
            new_change = [changes.fetch(attribute, change).first, change.last]
            changes.update(attribute => new_change)
          end
          changes
        end
      end
      
      def revert
        revert_to self.versions.at(self.version).previous
      end
      
      def retrieve_version n
        versions.find_by_number(n).changes.each do |n,v|
          self.send("#{n.to_sym}=",v.first)
        end 
      end
      
      def revert_to(value)
        to_number = versions.number_at(value)
        changes = changes_between(version, to_number)
        return version if changes.empty?

        changes.each do |attribute, change|
          write_attribute(attribute, change.last)
        end

        reset_version(to_number)
      end

      def revert_to!(value)
        revert_to(value)
        reset_version if saved = save
        saved
      end

      def latest_changes
        return {} if version.nil?
        versions.at(version).changes
      end
  end
end
