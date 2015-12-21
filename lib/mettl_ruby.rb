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

    def assessments(sort_param: "createdAt", sort_order: "desc")
      params = init_params
      params[:sort] = sort_param
      params[:sort_order] = sort_order

      request_url = UrlGenerator.url_for('assessments')
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params, private_key: @config.private_key)
      
      assessments = []
      res = self.class.get(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        assessments << res["assessments"]
        while !res["paging"]["next"].nil? do
          p "Connecting to #{res["paging"]["next"]}"
          res = self.class.get res["paging"]["next"]
          if res["status"] == "SUCCESS"
            assessments << res["assessments"]
          else
            return res["error"].values.join ": "
          end
        end
      else
        return res["error"].values.join ": "
      end

      return assessments.flatten!
    end

    def assessment assessment_id
      params = init_params
      request_url = UrlGenerator.url_for("assessments", assessment_id)
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params, private_key: @config.private_key)
      
      res = self.class.get(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        return res["assessment"]
      else
        return res["error"].values.join ": "
      end
    end

    def edit_assessment assessment_id, edit_details
      raise NotImplementedError
    end

    def schedules
      params = init_params
      request_url = UrlGenerator.url_for("schedules")
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params, private_key: @config.private_key)

      res = self.class.get(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        return res["schedules"]
      else
        return res["error"].values.join ": "
      end
    end

    def schedule_detail access_key
      params = init_params
      request_url = UrlGenerator.url_for("schedules", access_key)
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params, private_key: @config.private_key)

      res = self.class.get(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        return res["schedule"]
      else
        return res["error"].values.join ": "
      end
    end

    def schedules_for_assessment assessment_id
      params = init_params
      request_url = UrlGenerator.url_for("assessments", "#{assessment_id}/schedules")
      asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params, private_key: @config.private_key)

      res = self.class.get(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        return res["schedules"]
      else
        return res["error"].values.join ": "
      end
    end

    def create_schedule_for_assessment assessment_id, schedule_detail
      params = init_params
      params[:sc] = schedule_detail.to_json
      request_url = UrlGenerator.url_for("assessments", "#{assessment_id}/schedules")
      asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params, private_key: @config.private_key)

      res = self.class.post(request_url, query: params.merge!({asgn: asgn}))
      if res["status"] == "SUCCESS"
        return res["createdSchedule"]
      else
        return res["error"].values.join ": "
      end
    end

    def dummry_schedule assessment_id
      {
        assessmentId: assessment_id,
        name: "Schedule via API", "imageProctoring": false,
        isCandidateAuthProctored: false,
        webProctoring: {
          enabled: false 
          },
        scheduleType: "AlwaysOn",
        scheduleWindow: nil,
        access: {
          type: "OpenForAll",
          candidates: nil,
          sendEmail: false
          },
        ipAccessRestriction: {
          enabled: false 
          },
        allowCopyPaste: true,
        exitRedirectionUrl: "http://exit/redirection/url/here",
        sourceApp: "Name Of Application Hitting the API",
        testStartNotificationUrl: "http://application/path/listening/to/the/start/request",
        testFinishNotificationUrl: "http://application/path/listening/to/the/finish/request",
        testGradedNotificationUrl: "http://application/path/listening/to/the/grade/response/request",
        testResumeEnabledForExpiredTestURL: "http://application/path/listening/to/the/resumedenabled/request"
      }
    end

    def self.debug
      MettlRuby::Mettl.new(private_key: , public_key: )
    end

    private
    def init_params
      return {ts: Time.now.to_i, ak: @config.public_key}
    end
  end
end
