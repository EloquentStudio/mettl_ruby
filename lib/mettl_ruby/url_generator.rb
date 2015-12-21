module MettlRuby
  module UrlGenerator
  	BaseUrl = "http://api.mettl.com/v1"
    KnownObjects = ["assessments", "schedule", "schedules"]

    class UnknownObject < StandardError
      attr_reader :object, :message
      
      def initialize(message = nil, object = nil)
        @message = message || "Encountered unknown object in request."
        @object = object || "UnknownObject"
      end
    end

    #http://api.mettl.com/v1/assessments/
    #http://api.mettl.com/v1/assessments/{assessment-id}
    #http://api.mettl.com/v1/assessments/{assessment-id}/schedules
  	module_function
		def url_for(object, params=nil)
      raise UnknownObject unless KnownObjects.include? object
      [BaseUrl, object, params.to_s].join("/")
		end

    def known_objects
      return KnownObjects
    end
  end
end