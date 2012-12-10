# 取得特定日期決標案網址 

`get_tender_urls_by_date.rb STARTDATE [ENDDATE]`

取得 2012-01-01 的決標案
`get_tender_urls_by_date 2012-01-01`

取得 2012-01-01 ~ 2012-01-31的決標案
`get_tender_urls_by_date 2012-01-01 2012-01-31`

執行後會下載到 `tender-urls` 目錄中

# 下載標案網頁

tender_page_downloader.rb

執行後會下載由 `get_tender_urls_by_date.rb` 產生 `tender-urls` 裏面的 url 儲存到 `tender-pages` 目錄中

# 將決標網頁轉成 json 

`parser.rb TARGET_FOLDER/*`

ex `./parser.rb "tender-pages/*/*"`
