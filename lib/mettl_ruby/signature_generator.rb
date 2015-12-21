module MettlRuby
  module SignatureGenerator
    module_function
    def signature_for(http_verb:, url:, params:, private_key:)
      sorted_params = params.sort.to_h
      request_string = http_verb.upcase.to_s +  url.to_s
      sorted_params.values.each do |param_val|
        request_string += "\n#{param_val.to_s}"
      end
      signature = (Base64.encode64("#{OpenSSL::HMAC.digest('sha1', private_key, request_string)}"))[0..-2]
    end
  end
end
