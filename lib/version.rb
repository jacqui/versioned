class Version
  include MongoMapper::Document
  key :version_number, Integer
  key :versioned_type, String
  key :versioned_id, ObjectId
  key :changed_attrs, Hash
  timestamps!

  belongs_to :versioned, :polymorphic => true
end