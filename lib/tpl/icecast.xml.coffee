module.exports = ->
  config = @config.rtv.icecast 

  defaults =
      maxclients : 100
      sources : 10
      threadpool : 10
      'queue-size' : 524288
      'client-timeout' : 3
      'header-timeout' : 5
      'source-timeout' : 3
      'burst-on-connect' : 1
      'burst-size' : 65535
      'source-password' : 'hackmenot'
      'relay-password' : 'hackmenot'
      'admin-user' : 'admin'
      'admin-password' : 'hackmenot'
      'hostname' : 'localhost'
      'port' : 8000
 
  for k in Object.keys(defaults)
    config[k] = defaults[k] unless config[k]?

  { radio, webradio } = @config.rtv.stream
  mounts = ""; o = '';
  o += """
    <mount>
      <mount-name>/radio.#{k}</mount-name>
      <fallback-mount>/panic.#{k}</fallback-mount>
      <fallback-override>1</fallback-override>
    </mount>
    <mount><mount-name>/panic.#{k}</mount-name></mount>\n
  """ for k,v of radio when v is true
  mounts += o

  o = '';
  o += """
    <mount>
      <mount-name>/webradio.#{k}</mount-name>
      <fallback-mount>/panic.#{k}</fallback-mount>
      <fallback-override>1</fallback-override>
    </mount>\n""" for k,v of radio when v is true
  mounts += o

  o += """<mount><mount-name>/panic.#{k}</mount-name></mount>\n
  """ for k in Object.keys(radio) when radio[k] is true or webradio[k] is true
  mounts += o

  template = """
    <icecast>
      <limits>
        <clients>#{config.maxclients}</clients>
        <sources>#{config.sources}</sources>
        <threadpool>#{config.threadpool}</threadpool>
        <queue-size>#{config['queue-size']}</queue-size>
        <client-timeout>#{config['client-timeout']}</client-timeout>
        <header-timeout>#{config['header-timeout']}</header-timeout>
        <source-timeout>#{config['source-timeout']}</source-timeout>
        <burst-on-connect>#{config['burst-on-connect']}</burst-on-connect>
        <burst-size>#{config['burst-size']}</burst-size>
      </limits>
      <authentication>
        <source-password>#{config['source-password']}</source-password>
        <relay-password>#{config['relay-password']}</relay-password>
        <admin-user>#{config['admin-user']}</admin-user>
        <admin-password>#{config['admin-password']}</admin-password>
      </authentication>
      <!--directory>
        <yp-url-timeout>15</yp-url-timeout>
        <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
      </directory> -->
      <hostname>#{config.hostname}</hostname>
      <listen-socket>
          <port>#{config.port}</port>
      </listen-socket>
      #{mounts}
      <fileserve>1</fileserve>
      <paths>
        <basedir>#{@project}/share/icecast2</basedir>
        <logdir>#{@project}/log/icecast2</logdir>
        <webroot>#{@project}/share/icecast2/web</webroot>
        <adminroot>#{@project}/share/icecast2/admin</adminroot>
        <alias source="/" dest="/status.xsl"/>
      </paths>
      <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
      	<loglevel>1</loglevel>
      	<logsize>10000</logsize>
      </logging>
      <security>
        <chroot>0</chroot>
      </security>
    </icecast>"""
  return template