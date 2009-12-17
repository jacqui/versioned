class Version
  include MongoMapper::Document
  key :version_number, Integer, :required => true
  key :versioned_type, String, :required => true
  key :versioned_id, ObjectId, :required => true
  key :changed_attrs, Hash
  timestamps!

  belongs_to :versioned, :polymorphic => true
end