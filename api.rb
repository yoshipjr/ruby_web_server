require 'webrick'
require 'json'
def check_req(req)
 query_para = req.query_string
 # クエリパラメータが不正の場合に500 badrequestを返す
 res = WEBrick::HTTPStatus::BadGateway.new
 res.message
end
srv = WEBrick::HTTPServer.new(
  BindAddress: '127.0.0.1',
  Port: 18_080
)
url = '/'
srv.mount_proc(url) do |req, res|
  status = req.query_string.match(/\d+/).to_s
  res.status = status.to_i
  res.body = {value: "success",query_param: status}.to_json
end
trap('INT') { srv.shutdown }
srv.start
