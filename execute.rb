$stdout.sync = true
require "json"
require "faraday"

data = JSON.parse(ARGF.read)

changed_files = ENV.fetch("CHANGED_FILES").split(' ')
updated_files = data["files"].map{ |f| f["path"] }
added_files = 0
message = "Updated styles accross entire repo"

if changed_files.length == 0
  reportable_files = "--all"
  added_files = data["files"].count
else
  reportable_files = (changed_files & updated_files)
  reportable_files = reportable_files.reject do |i| 
    i.include?("schema.rb") 
  end
  puts reportable_files.inspect
  added_files = reportable_files.count
  if added_files == 0
    puts "there were no reportable files"
    exit(0)
  end
  reportable_files = reportable_files.join(" ")
  message = "Updated styles for pull request \##{ENV.fetch('GITHUB_NUMBER')}"
  puts message.inspect
end


branch = "pushbit/rubocop"
if changed_files.length > 0
  branch += "-#{ENV.fetch('GITHUB_NUMBER')}"
end

puts "Checking out branch"
system "git checkout -B #{branch}"

puts "Adding updated files"
system "git add #{reportable_files}"

puts "Commiting changed files"
system "git commit -m \"#{message}\""

if added_files > 0 
  puts "Pushing branch"
  system "git push -f origin #{branch}"

  conn = Faraday.new(:url => ENV.fetch("APP_URL")) do |config|
    config.adapter Faraday.default_adapter
  end
  discovery_message = "Code style and linting fixed in #{added_files} file#{'s' if added_files > 1}"

  if ENV["GITHUB_NUMBER"]
  " for pull request #{ENV.fetch('GITHUB_NUMBER')}"
  end

  discovery = {
    title: "Fix style issues in pull request \##{ENV.fetch('GITHUB_NUMBER')}",
    task_id: ENV.fetch("TASK_ID"),
    kind: :style,
    identifier: ["rubocop", ENV.fetch("BASE_BRANCH")].join("-"),
    branch: branch,
    code_changed: true,
    priority: :low,
    message: discovery_message
  }

  puts "Posting the following discovery"
  puts discovery.inspect

  res = conn.post do |req|
    req.url '/discoveries'
    req.headers['Content-Type'] = 'application/json'
    req.headers['Authorization'] = "Basic #{ENV.fetch("ACCESS_TOKEN")}"
    req.body = discovery.to_json
  end

  puts "Result"
  puts res.inspect
else
  puts "No files relevant to this pr were updated by rubocop"
end
