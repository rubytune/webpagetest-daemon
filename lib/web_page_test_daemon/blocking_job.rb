
require 'sinatra/base'

require 'web_page_test'
require 'web_page_test_daemon/test_results_job'

module WebPageTestDaemon
  class BlockingJob
    PINGBACK_HOST = ENV["PINGBACK_HOST"]
    PINGBACK_PORT = ENV["PINGBACK_PORT"] || 8080
    PINGBACK_READ, PINGBACK_WRITE = IO.pipe

    @queue = :web_page_test_blocking_jobs

    def self.perform(job)
      webpagetest = WebPageTest::Batch.new
      args = Shellwords.shellsplit(job["arguments"])
      args << "--pingback" << pingback_url

      warn("Running webpagetest with: #{args.inspect}")

      args << "--api-key" << ENV["WEBPAGETEST_API_KEY"]
      test_ids = webpagetest.option_parser.parse(args).map do |url|
        webpagetest.run(url).tap{ |id| warn("test_id: #{id.inspect}") }
      end

      warn "Waiting for signals"
      test_ids.size.times do |i|
        PINGBACK_READ.read(1)
        warn "App signaled #{i+1} tests completed"
      end

      job["webpagetest_server"] = webpagetest.server
      job["test_ids"] = test_ids

      warn "Enqueuing github comment job"
      Resque.enqueue(TestResultsJob, job)
    end

    def self.pingback_url
      "http://#{PINGBACK_HOST}:#{PINGBACK_PORT}/test_complete"
    end

    def self.pingback_app
      @pingback_app ||= Sinatra.new do
        set :port, PINGBACK_PORT

        post "/test_complete" do
          PINGBACK_WRITE.write("1")
          warn "Pingback app received test complete message: #{params['id']}"
        end
      end.tap(&:run!)
    end
  end
end
