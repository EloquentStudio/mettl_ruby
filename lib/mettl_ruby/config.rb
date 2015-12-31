module MettlRuby
  class Config
    attr_accessor :public_key, :private_key
    
    def initialize(opts = {})
      @public_key = opts[:public_key]
      @private_key = opts[:private_key]
    end
  end
end
