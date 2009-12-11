
module Versioned
  module ClassMethods
    def versioned
      include InstanceMethods
      many :versions, :as => :versioned, :dependent=>:destroy
      key :version, Integer, :default=>0
      before_update :save_version
    end
  end
  module InstanceMethods
    def save_version
      versions << Version.create(:changed_attrs=>changes,:version_number => new_version_number)
      self.version = self.versions.count
      save_to_collection
    end
    def new_version_number
      versions.count + 1
    end
    
    def revert
      versions.last(:order=>"version_number desc").changed_attrs.each do |n,v|
        self.send("#{n.to_sym}=",v.first)
      end
      self.version -= 1
      save_to_collection
    end
    
    def revert_to_version n
      v = versions.find_by_version_number(n)
      self.version = v.version_number
      v.changed_attrs.each do |n,v|
        self.send("#{n.to_sym}=",v.first)
      end
      save_to_collection
    end
    
  end
  def self.included klass
    klass.extend Versioned::ClassMethods
    klass.class_eval do
      versioned
    end
  end
end