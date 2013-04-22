###
  "RTV main-"module - part of the RTV project
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3
###

module.exports =
  defaults : ->
    defaults =
      web :
        static  : 8020
        websock : 8021
      icecast : {}
      database : { path : "#{@PREFIX}/etc/bot.db" }
      liquify :
        server  : "127.0.0.1"
        port    : 1234
        rcvport : 8100
    return defaults
  bootstrap : (onfinish) ->
    prompt = require 'prompt'
    schema = properties :
      admin_name:
        default : 'admin'
        pattern: /^[a-zA-Z\s\-]+$/
        message: "Name must be only letters, spaces, or dashes"
        required: true
      admin_password:
        required: true
        hidden: true
      xmpp:
        properties:
          jid:
            pattern: /[^@]+@[a-zA-Z0-9_.\-]+$/
            message: "e.g. joe@example.com"
            required: true
          server:
            default : ' as in jid '
          password:
            required: true
            hidden: true
          room_jid:
            required: true
          room_nick:
            default : 'rtv'
            required : true
      icecast:
        properties:
          source_password:
            required: true
          admin_password:
            default : ' source_passwd '
          relay_password:
            default : ' source_passwd '
          port:
            default : 8000
      web:
        properties:
          static : {default:8020}
          websock : {default:8021}
      liquify:
        properties:
          server :
            default : "127.0.0.1"
          port :
            default : 1234
          rcvaddr :
            default : "127.0.0.1"
          rcvport :
            default : 8100
    prompt.start()
    prompt.get schema, (err, r) ->
      r.icecast.admin_password = r.icecast.source_password unless r.icecast.admin_password isnt ' source_passwd '
      r.icecast.relay_password = r.icecast.source_password unless r.icecast.relay_password isnt ' source_passwd '
      r.xmpp.server = r.xmpp.jid.split('@').pop() unless r.xmpp.server isnt ' as in jid '
      r.admin = { name : r.admin_name, pass : r.admin_password }
      delete r.admin_name
      delete r.admin_password
      r.modules = [ 'xmpp', 'feed', 'rtv', 'rtv/web', 'rtv/liquify', 'rtv/youtube' ]
      onfinish(r)
  init : ->