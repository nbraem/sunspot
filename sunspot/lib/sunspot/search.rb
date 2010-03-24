%w(abstract_search query_facet field_facet date_facet facet_row hit
   highlight).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  # 
  # This class encapsulates the results of a Solr search. It provides access
  # to search results, total result count, facets, and pagination information.
  # Instances of Search are returned by the Sunspot.search and
  # Sunspot.new_search methods.
  #
  class Search < AbstractSearch
    # 
    # Retrieve all facet objects defined for this search, in order they were
    # defined. To retrieve an individual facet by name, use #facet()
    #
    attr_reader :facets

    def initialize(connection, setup, query, configuration) #:nodoc:
      super(connection, setup, query, configuration)
      @facets = []
      @facets_by_name = {}
    end

    # 
    # Get the facet object for the given name. `name` can either be the name
    # given to a query facet, or the field name of a field facet. Returns a
    # Sunspot::Facet object.
    #
    # ==== Parameters
    #
    # name<Symbol>::
    #   Name of the field to return the facet for, or the name given to the
    #   query facet when the search was constructed.
    # dynamic_name<Symbol>::
    #   If faceting on a dynamic field, this is the dynamic portion of the field
    #   name.
    #
    # ==== Example:
    #
    #   search = Sunspot.search(Post) do
    #     facet :category_ids
    #     dynamic :custom do
    #       facet :cuisine
    #     end
    #     facet :age do
    #       row 'Less than a month' do
    #         with(:published_at).greater_than(1.month.ago)
    #       end
    #       row 'Less than a year' do
    #         with(:published_at, 1.year.ago..1.month.ago)
    #       end
    #       row 'More than a year' do
    #         with(:published_at).less_than(1.year.ago)
    #       end
    #     end
    #   end
    #   search.facet(:category_ids)
    #     #=> Facet for :category_ids field
    #   search.facet(:custom, :cuisine)
    #     #=> Facet for the dynamic field :cuisine in the :custom field definition
    #   search.facet(:age)
    #     #=> Facet for the query facet named :age
    #
    def facet(name, dynamic_name = nil)
      if name
        if dynamic_name
          @facets_by_name[:"#{name}:#{dynamic_name}"]
        else
          @facets_by_name[name.to_sym]
        end
      end
    end

    # 
    # Deprecated in favor of optional second argument to #facet
    #
    def dynamic_facet(base_name, dynamic_name) #:nodoc:
      facet(base_name, dynamic_name)
    end

    # 
    # Get the data accessor that will be used to load a particular class out of
    # persistent storage. Data accessors can implement any methods that may be
    # useful for refining how data is loaded out of storage. When building a
    # search manually (e.g., using the Sunspot#new_search method), this should
    # be used before calling #execute(). Use the
    # Sunspot::DSL::Search#data_accessor_for method when building searches using
    # the block DSL.
    #
    def data_accessor_for(clazz) #:nodoc:
      (@data_accessors ||= {})[clazz.name.to_sym] ||=
        Adapters::DataAccessor.create(clazz)
    end

    # 
    # Build this search using a DSL block. This method can be called more than
    # once on an unexecuted search (e.g., Sunspot.new_search) in order to build
    # a search incrementally.
    #
    # === Example
    #
    #   search = Sunspot.new_search(Post)
    #   search.build do
    #     with(:published_at).less_than Time.now
    #   end
    #   search.execute!
    #
    def build(&block)
      Util.instance_eval_or_call(dsl, &block)
      self
    end

    # 
    # Populate the Hit objects with their instances. This is invoked the first
    # time any hit has its instance requested, and all hits are loaded as a
    # batch.
    #
    def populate_hits #:nodoc:
      id_hit_hash = Hash.new { |h, k| h[k] = {} }
      hits.each do |hit|
        id_hit_hash[hit.class_name][hit.primary_key] = hit
      end
      id_hit_hash.each_pair do |class_name, hits|
        ids = hits.map { |id, hit| hit.primary_key }
        data_accessor = data_accessor_for(Util.full_const_get(class_name))
        hits_for_class = id_hit_hash[class_name]
        data_accessor.load_all(ids).each do |result|
          hit = hits_for_class.delete(Adapters::InstanceAdapter.adapt(result).id.to_s)
          hit.result = result
        end
        hits_for_class.values.each { |hit| hit.result = nil }
      end
    end

    def inspect #:nodoc:
      "<Sunspot::Search:#{query.to_params.inspect}>"
    end

    def add_field_facet(field, options = {}) #:nodoc:
      name = (options[:name] || field.name)
      add_facet(name, FieldFacet.new(field, self, options))
    end

    def add_date_facet(field, options) #:nodoc:
      name = (options[:name] || field.name)
      add_facet(name, DateFacet.new(field, self, options))
    end

    def add_query_facet(name, options) #:nodoc:
      add_facet(name, QueryFacet.new(name, self, options))
    end

    def facet_response #:nodoc:
      @solr_result['facet_counts']
    end

    private

    def dsl
      DSL::Search.new(self, @setup)
    end

    def execute_request(params)
      @connection.select(params)
    end

    def add_facet(name, facet)
      @facets << facet
      @facets_by_name[name.to_sym] = facet
    end
  end
end
