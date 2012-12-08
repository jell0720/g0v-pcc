#!/usr/bin/env ruby
require 'json'
require 'open-uri'
require 'fileutils'
base_dir = 'tender-pages'
require 'time'
FileUtils.mkdir_p('base_dir')
Dir.glob('tender-urls/*.json').sort.each do |path|
  date = path.match(/\d{4}-\d{2}-\d{2}/)[0]
  html_dir = File.join(base_dir, date)
  FileUtils.mkdir_p(html_dir)

  urls = JSON.load(open(path))
  urls.each_with_index do |url, index|
    if url =~ /pkAtmMain=(\d+)/
      html_path = File.join(html_dir, $1) 
      puts "get: #{date} - #{index+1}/#{urls.length} - #{$1} - #{url}"
      if !File.exists? html_path
        open(html_path,'w'){|f| f.write(open(url).read)} 
      sleep rand(10)/10.0 + rand(1)
      end
    end
  end

end
