class Version
  include MongoMapper::Document
  include Comparable
  
  key :number, Integer
  key :versioned_type, String
  key :versioned_id, ObjectId
  key :changes, Hash
  timestamps!

  belongs_to :versioned, :polymorphic => true
  def changes
    read_attribute(:changes)
  end
  alias_attribute :version, :number

  def <=>(other)
    number <=> other.number
  end
end
