
require "sinatra/base"
require "json"
require "openssl"

require "web_page_test_daemon/github_comment"
require "web_page_test_daemon/create_job"

module WebPageTestDaemon
  class App < Sinatra::Base
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

    attr_accessor :payload

    configure :production, :development do
      enable :logging
    end

    get "/" do
      "Hello World!"
    end

    # pull_request
    post "/pull_request" do
      pull = payload.fetch('pull_request')

      if payload.fetch('action') == 'opened'
        jobs = GithubComment.extract_jobs(pull, pull)
        jobs.each{ |job| Resque.enqueue(CreateJob, job) }
      end

      "Ok"
    end

    # pull_request_review_comment
    # issue_comment
    post "/comment" do
      if payload['issue'] && payload['issue'].key?('pull_request')
        pull = stringify_keys pull_request(payload['issue']['pull_request']['url']).to_h
      elsif payload['pull_request']
        pull = payload['pull_request']
      end

      comment = payload.fetch('comment')

      if pull
        jobs = GithubComment.extract_jobs(pull, comment)
        jobs.each{ |job| Resque.enqueue(CreateJob, job) }
      end

      "Ok"
    end


    before /pull_request|comment/ do
      body = request.body.read
      @payload = JSON.parse(body)
    end

    private

    attr_reader :github

    def pull_request(url)
      @github ||= Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
      github.get(url)
    end

    def stringify_keys(object)
      case object
      when Hash
        object.each_with_object({}) do |(k, v), h|
          h[k.to_s] = stringify_keys(v)
        end
      when Array
        object.map{ |x| stringify_keys(x) }
      else
        object
      end
    end
  end
end
