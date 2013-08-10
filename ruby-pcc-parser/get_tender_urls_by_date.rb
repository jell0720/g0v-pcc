#!/usr/bin/env ruby
#encoding: utf-8
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
  tender_url_count = 0
  tender_url_patten      = Regexp.new('main/pms/tps/atm/atmAwardAction.do\?newEdit=false&searchMode=common&method=inquiryForPublic&pkAtmMain=')
  tender_url_patten2      = Regexp.new('main/pms/tps/atm/atmNonAwardAction.do\?searchMode=common&method=nonAwardContentForPublic&pkAtmMain=')
  tender_list_url_patten = Regexp.new('tender\.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&isSpdt=&pageIndex=(\d+)')
  mechanize.get('http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=advance&searchTarget=ATM') do |page|
    puts "start search"
    result_page = page.form_with(:name => "TenderActionForm") do |f|
      f['tenderStatus']           = "4,5,21,29" # 標案狀態-決標公告
      f['awardAnnounceStartDate'] = search_date #決標公告時間
      f['awardAnnounceEndDate']   = search_date #決標公告時間
    end.submit
    puts "got page: 1"
    tender_url_count = result_page.search(".T11b").text.to_i
    urls =  result_page.links.map(&:href)
    max_page = urls.inject([]){ |result, x| 
      if x =~ tender_url_patten || x =~ tender_url_patten2
        tender_urls << x
      elsif x =~ tender_list_url_patten
        result << $1.to_i
      end
      result
    }.max 

  end

  puts "max_page: #{max_page.to_i}"
  tender_urls.uniq!
  puts "取得數量: #{tender_urls.length}"

  if max_page && max_page > 1
    (2..max_page).each do |page_number|
      sleep 10+rand(5)
      mechanize.get("http://web.pcc.gov.tw/tps/pss/tender\.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&isSpdt=&pageIndex=#{page_number}")
      puts "got page: #{page_number}/#{max_page}"

      mechanize.current_page.links.each do |link|
        if link.href =~ tender_url_patten || link.href =~ tender_url_patten2
          tender_urls << link.href
        end
      end
      tender_urls.uniq!
      puts "取得數量: #{tender_urls.length}"
    end
  end

  FileUtils.mkdir_p('tender-urls')
  tender_urls.uniq!
  tender_urls.map!{ |url|
   "http://web.pcc.gov.tw/tps/"+ url[3..-1]
  }
  
  if tender_urls.length != tender_url_count
    raise "取得決標資料數量與網站描述不符, 取得數量#{tender_urls.length}, 網站描述數量 #{tender_url_count}"
  end

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


