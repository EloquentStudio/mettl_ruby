require 'uri'
require 'cgi'
require 'openssl'
require 'base64'
require 'json'
require 'httparty'
require 'httmultiparty'
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
    include HTTMultiParty

    class << self
      attr_accessor :config

      def configure
        self.config ||= MettlRuby::Config.new
        yield(config)
      end

      #Mettl API Documentation v1.18.pdf Section#2.1
      def account_info language_code: "en"
        params = init_params
        params[:languageCode] = language_code
        request_url = UrlGenerator.url_for("account")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#2.2
      def add_logo file_path
        params = init_params
        request_url = UrlGenerator.url_for("account", "upload-logo")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url,
          query: params.merge!(
            {
              asgn: asgn,
              logo: File.new(file_path)
            }
          )
        )
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#2.3
      def whitelist_info whitelist, favicon: nil, cover: nil, support_numbers: nil
        params = init_params
        params[:wl] = whitelist.to_json
        params[:support_numbers] = support_numbers.to_json if support_numbers
        request_url = UrlGenerator.url_for("account", "update-white-labeling")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        params[:fav] = File.new(favicon) if favicon
        params[:cov] = File.new(cover) if cover
        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#3.1
      def list_pbts
        params = init_params
        request_url = UrlGenerator.url_for("pbts")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#3.2
      def add_pbts pbts
        params = init_params
        params[:pbts] = pbts.to_json
        request_url = UrlGenerator.url_for("pbts", "add")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#4.1
      def assessments(sort_param: "createdAt", sort_order: "desc")
        params = init_params
        params[:sort] = sort_param
        params[:sort_order] = sort_order

        request_url = UrlGenerator.url_for('assessments')
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        assessments = []
        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          assessments << res["assessments"]
          while !res["paging"]["next"].nil? do
            res = self.get res["paging"]["next"]
            if res["status"] == "SUCCESS"
              assessments << res["assessments"]
            else
              return error_response_for(res)
            end
          end
        else
          return error_response_for(res)
        end

        return {"status"=> "SUCCESS", "assessments"=> assessments.flatten}
      end

      #Mettl API Documentation v1.18.pdf Section#4.2
      def assessment assessment_id
        params = init_params
        request_url = UrlGenerator.url_for("assessments", assessment_id)
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#4.6
      def edit_assessment_settings assessment_id, edit_details
        params = init_params
        params[:as] = edit_details.to_json
        request_url = UrlGenerator.url_for("assessments", "#{assessment_id}/settings/edit")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#4.4
      def schedules
        params = init_params
        request_url = UrlGenerator.url_for("schedules")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#4.5
      def schedule_detail access_key
        params = init_params
        request_url = UrlGenerator.url_for("schedules", access_key)
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#5.1
      def schedules_for_assessment assessment_id
        params = init_params
        request_url = UrlGenerator.url_for("assessments", "#{assessment_id}/schedules")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#4.1
      def create_schedule_for_assessment assessment_id, schedule_detail
        params = init_params
        params[:sc] = schedule_detail.to_json
        request_url = UrlGenerator.url_for("assessments", "#{assessment_id}/schedules")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#5.2
      def edit_schedule access_key, edit_details
        params = init_params
        params[:sc] = edit_details.to_json
        request_url = UrlGenerator.url_for("schedules", "#{access_key}/edit")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#6.1.2
      def register_candidates_for_schedule access_key, candidate_details
        return "Can register a maximum of 20 candidates at a time." if candidate_details.count > 20

        params = init_params
        params[:rd] = { registrationDetails: candidate_details}.to_json
        request_url = UrlGenerator.url_for("schedules", "#{access_key}/candidates")
        asgn = SignatureGenerator.signature_for(http_verb: 'POST', url: request_url, params: params)

        res = self.post(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#6.2
      def status_for_schedule access_key, qr: false, sort_param: "testStartTime", sort_order: "desc"
        params = init_params
        params[:qr] = qr
        params[:sort] = sort_param
        params[:sort_order] = sort_order

        request_url = UrlGenerator.url_for("schedules", "#{access_key}/candidates")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        candidate_statuses = []
        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          candidate_statuses << res["candidates"]
          while !res["paging"]["next"].nil? do
            p "Connecting to #{res["paging"]["next"]}"
            res = self.get res["paging"]["next"]
            if res["status"] == "SUCCESS"
              candidate_statuses << res["candidates"]
            else
              return error_response_for(res)
            end
          end
        else
          return error_response_for(res)
        end

        return {"status"=> "SUCCESS", "schedule_status"=> candidate_statuses.flatten}
      end

      #Mettl API Documentation v1.18.pdf Section#6.3
      def candidate_status_for_schedule candidate_email, access_key, qr: false
        params = init_params
        params[:qr] = qr
        request_url = UrlGenerator.url_for("schedules", "#{access_key}/candidates/#{candidate_email}")
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#6.4
      def delete_report
        params = init_params
        request_url = UrlGenerator.url_for("schedules", "#{access_key}/candidates/#{candidate_email}")
        asgn = SignatureGenerator.signature_for(http_verb: 'DELETE', url: request_url, params: params)

        res = self.delete(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end

      #Mettl API Documentation v1.18.pdf Section#7
      def candidate_details candidate_email, qr: false
        params = init_params
        params[:qr] = qr
        request_url = UrlGenerator.url_for("candidates", candidate_email)
        asgn = SignatureGenerator.signature_for(http_verb: 'GET', url: request_url, params: params)

        res = self.get(request_url, query: params.merge!({asgn: asgn}))
        if res["status"] == "SUCCESS"
          return res
        else
          return error_response_for(res)
        end
      end


      def dummry_schedule assessment_id
        {
          assessmentId: assessment_id,
          name: "Schedule via API",
          imageProctoring: false,
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

      def debug
        MettlRuby::Mettl.configure do |config|
          config.public_key = ""
          config.private_key = ""
        end
      end

      private
      def init_params
        return {ts: Time.now.to_i, ak: config.public_key}
      end

      def error_response_for(response)
        {
          "status"=> "error",
          "error" => {
            "code" => response["error"]["code"],
            "message" => response["error"]["message"]
          }
        }
      end
    end
  end
end
