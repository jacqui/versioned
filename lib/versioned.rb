
module Versioned
  module InstanceMethods
    
    def save_version
      versions << Version.create(:changed_attrs=>changes,:version_number => new_version_number)
      self.version = self.versions.count+1
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
    
    def diff v
      compare_to = self.versions.find_by_version_number(v)
      compare_to.changed_attrs.map {|n,v| { n => v } }
    end
    
  end
  def self.included klass
    klass.class_eval do
      include InstanceMethods
      many :versions, :as => :versioned, :dependent=>:destroy
      key :version, Integer, :default => 1
      before_update :save_version
    end
  end
end