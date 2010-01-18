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

  def previous
    find_related(:first, :number => {:$lt => number}, :order => 'number.desc')
  end

  def next
    find_related(:first, :number => {:$gt => number}, :order => 'number.asc')
  end

  protected

  def find_related(*args)
    options = args.extract_options!
    params = options.merge(:versioned_id => versioned_id, :versioned_type => versioned_type)
    self.class.find(args.first, params)
  end
end
