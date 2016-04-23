
require 'sinatra/base'

require 'web_page_test'
require 'web_page_test_daemon/test_results_job'

module WebPageTestDaemon
  class BlockingJob
    PINGBACK_HOST = ENV["PINGBACK_HOST"]
    PINGBACK_PORT = ENV["PINGBACK_PORT"] || 8080

    @queue = :web_page_test_blocking_jobs

    def self.perform(job)
      args = Shellwords.shellsplit(job["arguments"])
      args << "--pingback" << pingback_url

      warn("webpagetest args: #{args.inspect}")
      args << "--api-key" << ENV["WEBPAGETEST_API_KEY"]

      webpagetest = WebPageTest::Batch.new
      urls = webpagetest.option_parser.parse(args)

      test_ids = run_webpagetest(webpagetest, urls)

      job["webpagetest_server"] = webpagetest.server
      job["test_ids"] = test_ids

      warn "Enqueuing github comment job"
      Resque.enqueue(TestResultsJob, job)
    end

    def self.run_webpagetest(webpagetest, urls)
      test_ids = urls.map do |url|
        webpagetest.run(url).tap{ |id| warn("test_id: #{id.inspect}") }
      end

      warn "Waiting for signals"
      run_pingback_app(test_ids)

      test_ids
    end

    def self.pingback_url
      "http://#{PINGBACK_HOST}:#{PINGBACK_PORT}/test_complete"
    end

    def self.run_pingback_app(test_ids)
      incomplete_tests = test_ids.dup

      app = Sinatra.new do
        set :lock, true
        set :bind, "0.0.0.0"
        set :port, PINGBACK_PORT

        get "/test_complete" do
          warn "Pingback app received test complete message: #{params['id']}"
          incomplete_tests.delete(params["id"])
          app.stop! if incomplete_tests.empty?
        end
      end

      app.run!
    end
  end
end
