module Sunspot
  module Solr
    module Java
      def self.installed?
        `java -version > /dev/null 2>&1`
        $?.success?
      end
    end
  end
end
