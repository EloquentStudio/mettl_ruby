module MettlRuby
  module UrlGenerator
  	BaseUrl = "http://api.mettl.com/v1/"
    KnownObjects = ["assessment", "assessments", "schedule", "schedules"]

    class UnknownObject < StandardError
      attr_reader :object, :message
      
      def initialize(message = nil, object = nil)
        @message = message || "Encountered unknown object in request."
        @object = object || "UnknownObject"
      end
    end

  	module_function
		def url_for(object, params)
      raise UnknownObject unless KnownObjects.include? object
      BaseUrl + object
		end

    def known_objects
      return KnownObjects
    end
  end
end