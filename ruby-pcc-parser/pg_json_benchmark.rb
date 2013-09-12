require 'bundler'
Bundler.setup

require 'pg'
require 'benchmark'

conn = PG.connect( user: 'postgres', dbname: 'g0v_pcc' )

conn.exec('CREATE TABLE IF NOT EXISTS tenders (id varchar(128) PRIMARY KEY, data json)')
conn.exec('truncate tenders')

conn.prepare( 'delete_tender', "delete from tenders where id = $1" )
conn.prepare( 'insert_tender', "INSERT INTO tenders VALUES ($1, $2);" )

Benchmark.bm do |benchmark|
  benchmark.report("insert json") do
    Dir.glob('tenders-json/**/*.json').each do |x|
      id = File.basename(x,".json")
      json = open(x, 'r'){|f| f.read}
      conn.exec_prepared( 'delete_tender', [id] )
      conn.exec_prepared( 'insert_tender', [id, json] )
    end
  end
end
