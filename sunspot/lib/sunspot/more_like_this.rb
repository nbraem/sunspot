%w(abstract_search query_facet field_facet date_facet facet_row hit
   highlight).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  # 
  # This class encapsulates the results of a Solr MoreLikeThis search. It provides access
  # to search results, total result count, and pagination information.
  # Instances of MoreLikeThis are returned by the Sunspot.more_like_this and
  # Sunspot.new_more_like_this methods.
  #
  class MoreLikeThis < AbstractSearch

    def this_object=(object)
      @query.scope.add_restriction(
	IdField.instance,
	Sunspot::Query::Restriction::EqualTo,
	Sunspot::Adapters::InstanceAdapter.adapt(object).index_id
      )
      @setup.all_more_like_this_fields.each { |field| @query.add_field(field) }
    end

    def interesting_terms
      if @solr_result['interestingTerms']
	if @solr_result['interestingTerms'].last.is_a? Float
	  # interestingTerms: ["body_mlt_textv:two", 1.0, "body_mlt_textv:three", 1.0]
	  @interesting_terms ||= @solr_result['interestingTerms'].each_slice(2).map do |interesting_term, score|
	    field, term = interesting_term.match(/(.*)_.+:(.*)/)[1..2]
	    InterestingTerm.new(field, term, score)
	  end
	else
	  @interesting_terms ||= @solr_result['interestingTerms'].map do |term|
	    InterestingTerm.new(term)
	  end
	end
      end
    end

    def reset
      super
      @interesting_terms = nil
    end

    private

    # override
    def dsl
      DSL::MoreLikeThis.new(@query, @setup)
    end

    def execute_request(params)
      @connection.mlt(params)
    end
    
    class InterestingTerm
      attr_reader :term, :field, :score

      def initialize(term, field = nil, score = 1.0)
	@term = term
	@field = field
	@score = score
      end
    end

  end
end
