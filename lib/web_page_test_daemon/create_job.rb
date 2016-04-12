
require 'shellwords'

require 'web_page_test'

module WebPageTestDaemon
  class CreateJob
    @queue = :web_page_test_jobs

    def self.perform(job)
      webpagetest = WebPageTest::Batch.new
      args = Shellwords.shellsplit(job["arguments"])

      webpagetest.api_key = ENV["WEBPAGETEST_API_KEY"]

      test_ids = webpagetest.option_parser.parse(args).map do |url|
        webpagetest.run(url)
      end

      job["test_ids"] = test_ids

      Resque.enqueue_in(30.seconds, StatusCheckJob, job)
    end
  end
end
