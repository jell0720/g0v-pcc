#!/usr/bin/env ruby
# encoding: utf-8
require 'nokogiri'
require 'yaml'
require 'yajl/json_gem'
require 'fileutils'

def t(node)
  if node
    text=node.text
    text.gsub!(/[\n\r\t]/,'')
    text.gsub!(/[　 ]+/,' ')
    text.strip! 
    return text 
  end
end

def parse_inner_table(table)
  json={}
  keys=[]
  current_json=json
  tenderer_type=nil
  table.css('tr').each do |tr|
    th =t(tr.css("th"))
    td =t(tr.css("td").first)
 
    current_json=json
    keys.each do |k|
      current_json[k] ||= {}
      current_json=current_json[k]
    end

    new_tenderer_start =( th.match /(?<type>.*標廠商)(?<index>\d+)/) 
    if new_tenderer_start && td == ''
      if keys[0] == '品項'
        keys=keys[0,2] +[ new_tenderer_start[:type], new_tenderer_start[:index] ]
      else
        keys=[ new_tenderer_start[:type], new_tenderer_start[:index] ]
      end
      next
    end
    
    new_item_start =( th.match /第(?<index>\d+)品項/) 
    if new_item_start && td == ''
      keys = ['品項', new_item_start[:index]]
      next
    end
    
    current_json[th] = td
  end
  json
end

Dir.glob(ARGV[0]) do |source_path|
  result_file = File.join('tenders-json', "#{source_path}.json")
  next if File.exists?(result_file)
  puts source_path
  doc = Nokogiri::HTML(open(source_path))

  json={}
  keys=[]
  current_json=json
  rowspan=0
  trs = doc.css('#printArea > table.tender_table > tbody > tr[class]')
  next if trs.length ==0 

  doc.css('#printArea > table.tender_table > tbody > tr[class]').each do |tr|
    next if t(tr) =~ /紅色字體表示此次更正公告與前次之差異/
    if rowspan > 0
      rowspan-=1 
    else
      keys.pop 
    end

    current_json=json
    keys.each do |k|
      current_json[k] ||= {}
      current_json=current_json[k]
    end

    if tr.css('td[rowspan]').length > 0
      rowspan = tr.css('td[rowspan]').attr('rowspan').value.to_i - 1
      key=t(tr)
      keys.push key
    elsif tr.css('table').length > 0
      current_json.merge! parse_inner_table( tr.css('table'))
    else
      th = t(tr.xpath("th"))
      if th != ''
        current_json[th] = t(tr.css("td").first)
      end
    end

  end
  procurement_data = json["採購資料"] || json["已公告資料"]
  json["url"]="http://web.pcc.gov.tw/tps/main/pms/tps/atm/atmAwardAction.do?newEdit=false&searchMode=common&method=inquiryForPublic&pkAtmMain=#{File.basename(source_path)}&tenderCaseNo=#{procurement_data['標案案號']}"
  puts JSON.pretty_generate(json)
  #FileUtils.mkdir_p(File.dirname(result_file))
  #open(result_file,'w'){|f| f.write(JSON.pretty_generate(json)) }
end
