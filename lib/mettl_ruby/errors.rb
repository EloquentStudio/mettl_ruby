module MettlRuby
  module Errors
    Errors = {
      E400: "Request was not well-formed/Invalid parameters supplied.",
      E401: "Authentication failed/Signature mismatch",
      E403: "Access denied. The API key is not authorized for requested resource/action.",
      E404: "Requested resource not found.",
      E405: "HTTP Method not allowed for this API Request",
      E408: "Request Timed out",
      E422: "Signature expired.",
      E503: "API Service is currently unavailable",
      E504: "Invalid Timestamp",
      E509: "Rate limit exceeded",
    }

    module_function
    def message_for_code(code)
      Errors.fetch(code.to_sym, "Unknown error code")
    end

    def errors
      return Errors
    end
  end
end
