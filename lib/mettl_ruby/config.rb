module MettlRuby
  class Config
    attr_accessor :public_key, :private_key
    
    def initialize(opts = {})
      @public_key = opts[:public_key]
      @private_key = opts[:private_key]
    end

    def validate
      errors = []
      errors << "Invalid Public Key" if @public_key.nil? || @public_key.empty?
      errors << "Invalid Private Key" if @private_key.nil? || @private_key.empty?
      unless errors.empty?
        raise ArgumentError, "#{errors.join(', ')}"
      end
    end
  end
end