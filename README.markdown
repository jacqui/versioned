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

    @doc.revert

    puts @doc.title
    => v1

    @doc.title = "v3"
    @doc.save
    @doc.version
    => 3

    @doc.retrieve_version 2
    puts @doc.title 
    => "v2"

    @doc = Doc.find(@doc.id)
    @doc.title
    => "v3"
    @doc.version
    => 3
