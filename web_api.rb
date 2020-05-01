require 'webrick'
require 'json'

class UebAPI
  def initialize(bind_address: '192.168.1.11', port: 18_080)
    @srv = WEBrick::HTTPServer.new(
      BindAddress: bind_address,
      Port: port
    )
    @mount_procs = {}
  end

  def start
    do_mount_procs
    default_mount_proc
    trap('INT') { @srv.shutdown }
    @srv.start
  end

  def mount_proc(dir, method: :GET, body: {}.to_json, status: WEBrick::HTTPStatus::RC_OK, &block)
    @mount_procs[dir] ||= {}
    @mount_procs[dir][method] = { body: body, status: status, block: block }
  end

  private

  def default_mount_proc
    @srv.mount_proc('/') do |req, res|
      log_request(req)
      res.body = {}.to_json
      p res.status = 409 
    end
  end

  def do_mount_procs
    @mount_procs.each do |dir, methods|
      do_mount_proc(dir, methods)
    end
  end

  def do_mount_proc(dir, methods)
    @srv.mount_proc(dir) do |req, res|
      log_request(req)
      method = methods.fetch(req.request_method.to_sym)
      if method
        res.content_type = 'application/json'
        res.status = method[:status]
        res.body = method[:body]
        method[:block].call(req, res) if method[:block]
      end
    end
  end

  def log_request(req)
    info = "method=#{req.request_method}, uri=#{req.request_uri}, query=#{req.query_string}, body=#{req.body}"
    @srv.logger.info(info)
  end
end

srv = UebAPI.new
url = '/'
# この部分は、必要に応じて追加、修正します。
srv.mount_proc('/foo/bar', method: :GET, status: 200) do |req, res|
  res.body = { value: 'baz' }.to_json
end
srv.mount_proc('/foo/bar', method: :POST, body: { result: 'ok' }.to_json, status: 201)

srv.mount_proc(url,method: :GET,status: 200) do |req, res|
  #WEBrick::HTTPStatus.success?(200)
  res['Content-Type'] = 'text/html'
  res.body = {value: "success",query_param: req.query_string}.to_json
  #self.mount_procs[url][:GET][:status]= 409 
  p res
end

srv.mount_proc(url, method: :POST, body: { result: 'ok' }.to_json, status: 201)
srv.start
