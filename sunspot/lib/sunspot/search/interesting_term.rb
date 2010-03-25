module Sunspot
  module Search
    #
    # InterestingTerm encapsulates the information returned by solr
    # when specifying mlt.interestingTerms = list or details
    #
    class InterestingTerm
      #
      # Actual term that is extracted by the MoreLikeThisHandler in solr.
      # Results returned by more_like_this are found by searching for this term.
      #
      attr_reader :term
      
      #
      # Field of this interesing term, or nil if interesting_terms is
      # not :details
      #
      attr_reader :field
      
      #
      # Score of this interesting term, or nil if interesting_terms is
      # not :details
      #
      attr_reader :score

      def initialize(term, field = nil, score = nil) #:nodoc:
	@term = term
	@field = field
	@score = score
      end
    end
  end
end
