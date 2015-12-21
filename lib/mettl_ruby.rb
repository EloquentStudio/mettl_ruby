require 'uri'
require 'cgi'
require 'openssl'
require 'base64'
require 'json'
require 'httparty'
require 'pry'
require 'pry-nav'

require "mettl_ruby/version"
require "mettl_ruby/config"
require "mettl_ruby/url_generator"
require "mettl_ruby/signature_generator"
require "mettl_ruby/errors"

module MettlRuby
  class Mettl
    include HTTParty

    def initialize(opts = {}, &block)
      @config = Config.new(opts)
      yield(@config) if block_given?
      @config.validate
    end

    def fetch_assessments
      params = {ts: Time.now.to_i, ak: @config.public_key}
      url = UrlGenerator.url_for('assessments', params)
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: url, params: params, private_key: @config.private_key)
      
      res = self.class.get url, query: params.merge!({asgn: asgn})
      if res["status"] == "SUCCESS"
        return res["assessments"]
      else
        return res["error"].values.join ": "
      end
    end

    def call_api url, params, asgn
      res = self.class.get url, query: params.merge!({asgn: asgn})
    end

    def self.debug
      m = MettlRuby::Mettl.new(private_key: , public_key: )
      m.fetch_assessments
    end
  end
end
