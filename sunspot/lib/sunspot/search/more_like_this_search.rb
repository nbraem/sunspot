module Sunspot
  # 
  # This class encapsulates the results of a Solr MoreLikeThis search. It provides access
  # to search results, total result count, and pagination information.
  # Instances of MoreLikeThis are returned by the Sunspot.more_like_this and
  # Sunspot.new_more_like_this methods.
  #
  module Search
    class MoreLikeThisSearch < AbstractSearch
      def execute(options={})
        if @query.more_like_this.fields.empty?
          @setup.all_more_like_this_fields.each do |field|
            @query.more_like_this.add_field(field, field.more_like_this_boost)
          end
        end
        super
      end

      def request_handler
        super || :mlt
      end

      def interesting_terms
	if @solr_result['interestingTerms']
	  if @solr_result['interestingTerms'].last.is_a? Float
	    # interestingTerms: ["body_mlt_textv:two", 1.0, "body_mlt_textv:three", 1.0]
	    @interesting_terms ||= @solr_result['interestingTerms'].each_slice(2).map do |interesting_term, score|
	      field, term = interesting_term.match(/(.*)_.+:(.*)/)[1..2]
	      InterestingTerm.new(term, field, score)
	    end
	  else
	    @interesting_terms ||= @solr_result['interestingTerms'].map do |term|
	      InterestingTerm.new(term)
	    end
	  end
	end
      end

      private

      # override
      def dsl
        DSL::MoreLikeThisQuery.new(self, @query, @setup)
      end
    end
  end
end
