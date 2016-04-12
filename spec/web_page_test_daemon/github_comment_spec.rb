
require 'spec_helper'

require 'web_page_test_daemon/github_comment'

RSpec.describe WebPageTestDaemon::GithubComment do
  describe '.extract_jobs' do
    let(:pull) {
      {
        "url" => "http://example.com/pull_request_url",
        "comments_url" => "http://example.com/pull_request_comments_url",
        "head" => {
          "ref" => "source_branch",
          "sha" => "source_commit_sha"
        },
        "base" => {
          "ref" => "target_branch",
          "sha" => "target_commit_sha"
        }
      }
    }

    it "should scan the object body for webpagetest jobs" do
      object = { "body" => "comment or pull request body" }
      jobs = WebPageTestDaemon::GithubComment.extract_jobs(pull, object)
      expect(jobs.class).to eq(Array)
      expect(jobs.size).to eq(0)

      object["body"] << "\n/webpagetest one two three"
      object["body"] << "\nblah blah blah /webpagetest blah blah"
      object["body"] << "\n/webpagetest four five six"
      object["body"] << "\nblah blah blah"

      jobs = WebPageTestDaemon::GithubComment.extract_jobs(pull, object)
      expect(jobs.class).to eq(Array)
      expect(jobs.size).to eq(2)

      jobs.each do |job|
        expect(job.class).to eq(Hash)
        expect(job[:pull_request]).to eq(pull["url"])
        expect(job[:pull_request_comments]).to eq(pull["comments_url"])
        expect(job[:branch]).to eq(pull["head"]["ref"])
        expect(job[:reference]).to eq(pull["base"]["ref"])
        expect(job[:sha]).to eq(pull["head"]["sha"])
        expect(job[:reference_sha]).to eq(pull["base"]["sha"])
        expect(job[:github_holder]).to eq(object)
      end

      expect(jobs[0][:arguments]).to eq("one two three")
      expect(jobs[1][:arguments]).to eq("four five six")
    end
  end
end
