#!/usr/bin/env ruby
require 'json'
require 'open-uri'
require 'fileutils'
require 'uri'
require 'cgi'
base_dir = 'tender-pages'
FileUtils.mkdir_p(base_dir)
Dir.glob('tender-urls/*.json').sort.reverse.each do |path|
  date = path.match(/\d{4}-\d{2}-\d{2}/)[0]
  html_dir = File.join(base_dir, date)
  FileUtils.mkdir_p(html_dir)

  urls = JSON.load(open(path))
  urls.each_with_index do |url, index|
    #uri=URI.parse(url)
    #params = CGI.parse(uri.query)
    params =  url.match(/pkAtmMain=(?<pkAtmMain>[^&]+)&tenderCaseNo=(?<tenderCaseNo>.*$)/)
    if params["pkAtmMain"]
      html_path = File.join(html_dir, "#{params["pkAtmMain"]}-#{params["tenderCaseNo"]}") 
      if !File.exists? html_path
        puts "get: #{date} - #{index+1}/#{urls.length} - #{html_path} - #{url}"
        begin
          html_source = open(url+'&contentMode=1').read 
          open(html_path,'w'){|f| f.write(html_source)} 
          sleep rand(10)/10.0 + rand(1)
        rescue
        end
      end
    end
  end
end
