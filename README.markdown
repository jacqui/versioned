Versioned
=========

Simple versioning for MongoMapper

Usage
-----

    class Doc
      include MongoMapper::Document
      include Versioned
      key :title, String
    end

    @doc = Doc.create(:title=>"v1")
    @doc.title = "v2"
    @doc.save

    @doc.revert_to(@doc.version - 1)

    @doc.title = "v3"
    @doc.save

    @doc.revert_to(1)

    puts @doc.title
    => v1