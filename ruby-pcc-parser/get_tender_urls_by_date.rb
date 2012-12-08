#!/usr/bin/env ruby
require 'mechanize'
require 'fileutils'
require 'json'
require 'date'

def get_daily_tender_urls(date)
  search_year =  date.year > 1911 ? date.year - 1911 : date.year
  search_date = "#{search_year}/#{date.strftime('%m')}/#{date.strftime('%d')}"
  puts search_date

  mechanize = Mechanize.new
  max_page = 1
  tender_urls = []
  tender_url_patten      = Regexp.new('main/pms/tps/atm/atmAwardAction.do\?newEdit=false&searchMode=common&method=inquiryForPublic&pkAtmMain=')
  tender_list_url_patten = Regexp.new('tender\.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&pageIndex=(\d+)')

  mechanize.get('http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=advance&searchTarget=ATM') do |page|
    puts "start search"
    result_page = page.form_with(:name => "TenderActionForm") do |f|
      f['tenderStatus']           = "4,5,21,29" # 標案狀態-決標公告
      f['awardAnnounceStartDate'] = search_date #決標公告時間
      f['awardAnnounceEndDate']   = search_date #決標公告時間
    end.submit
    puts "got page: 1"
    urls =  result_page.links.map(&:href)
    max_page = urls.inject([]){ |result, x| 
      if x =~ tender_url_patten
        tender_urls << x
      elsif x =~ tender_list_url_patten
        result << $1.to_i
      end
      result
    }.max 

  end

  puts "max_page: #{max_page.to_i}"
  if max_page && max_page > 1
    (2..max_page).each do |page_number|
      sleep rand(3)+rand(10)/10.0
      mechanize.get("http://web.pcc.gov.tw/tps/pss/tender\.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&pageIndex=#{page_number}")
      puts "got page: #{page_number}/#{max_page}"

      mechanize.current_page.links.each do |link|
        if link.href =~ tender_url_patten
          tender_urls << link.href
        end
      end
    end
  end

  FileUtils.mkdir_p('tender-urls')
  tender_urls.uniq!
  tender_urls.map!{ |url|
   "http://web.pcc.gov.tw/tps/"+ url[3..-1]
  }
  open(File.join('tender-urls', "#{date.strftime('%Y-%m-%d')}.json"),'w') do 
    |f| f.write JSON.dump(tender_urls)
  end
end

start_date= Date.parse(ARGV[0])

if ARGV[1]
  end_date = Date.parse(ARGV[1])
  (end_date - start_date + 1).to_i.times do |x|
    get_daily_tender_urls( start_date+x )
  end
else
  get_daily_tender_urls( Date.parse(ARGV[0]) )
end


