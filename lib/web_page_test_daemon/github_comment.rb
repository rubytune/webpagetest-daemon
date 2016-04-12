
module WebPageTestDaemon
  class GithubComment
    def self.extract_jobs(pull, object)
      jobs = []

      job_template = {
        pull_request:          pull.fetch('url'),
        pull_request_comments: pull.fetch('comments_url'),
        branch:                pull.fetch('head').fetch('ref'),
        reference:             pull.fetch('base').fetch('ref'),
        sha:                   pull.fetch('head').fetch('sha'),
        reference_sha:         pull.fetch('base').fetch('sha'),
        github_holder:         object
      }

      object.fetch('body').scan(%r{^/webpagetest (.+)}).each do |args|
        job_template[:arguments] = args.first
        jobs.push(job_template.dup)
      end

      jobs
    end
  end
end
