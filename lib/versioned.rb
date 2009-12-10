
module Versioned
  module ClassMethods
    def versioned
      include InstanceMethods
      many :versions, :as => :versioned, :dependent=>:destroy
      key :version, Integer
      before_update :save_version
    end
  end
  module InstanceMethods
    def save_version
      versions << Version.create(:changed_attrs=>changes,:version_number => new_version_number)
    end
    def new_version_number
      version = versions.count + 1
      versions.count + 1
    end
    
    def revert
      versions.last(:order=>"version_number desc").changed_attrs.each do |n,v|
        self.send("#{n.to_sym}=",v.first)
      end
      save
    end
    
    def revert_to_version n
      versions.find_by_version_number(n).changed_attrs.each do |n,v|
        self.send("#{n.to_sym}=",v.first)
      end
      save
    end
    
  end
  def self.included klass
    klass.extend Versioned::ClassMethods
    klass.class_eval do
      versioned
    end
  end
end