module.exports = ->
  { PREFIX } = this
  config = @config.rtv

  { radio, webradio } = config.stream
  radio = ( """out.#{k}(start=true,"radio",radio)""" for k,v of radio when v is true ).join '\n'
  webradio = ( """out.#{k}(start=true,"web",nometa)""" for k,v of webradio when v is true ).join '\n'

  template = """
    # enable_replaygain_metadata()
    set("server.telnet", true)
    set("server.telnet.port", 1234)
    set("frame.video.channels",0)
    set("log.level",1)
    set("log.file.path","#{@project}/log/liquidsoap.log")

    system("lsof -i -P -n | grep LISTEN | awk '/1234/{system(\\"kill -9 \\"$2)}'")

    RADIO       = "#{@project}"
    base_path   = RADIO
    source_path = RADIO
    bin_path    = base_path ^ "/bin"
    inc_path    = base_path ^ "/liq"
    icecast_pass="#{@config.rtv.icecast['source-password']}"
    icecast_host="localhost"

    # mark config labels optional
    ignore(bin_path)
    ignore(inc_path)
    ignore(source_path)
    ignore(icecast_pass)
    ignore(icecast_host)
    # mark config labels optional

    %include "#{@project_lib}/liq/library.liq"

    # activate one of the following as a base source
    # %include "#{@project_lib}/liq/fallback.liq"
    %include "#{@project_lib}/liq/schedule.liq"

    # play request-queue
    %include "#{@project_lib}/liq/player.liq"

    # live sink
    %include "#{@project_lib}/liq/live.liq"

    # announcer
    # %include "#{@project_lib}/liq/announce.liq"

    # disable this if you dont need it
    # the jack wallclock is expensive 
    %include "#{@project_lib}/liq/studio.liq"

    # metadata hackery
    %include "#{@project_lib}/liq/metadata.liq"

    # video is quite expensive (think a dedicated core)
    # %include "#{@project_lib}/liq/video.liq"

    # Output Formats
    #{radio}

    # Strip metadata for webradio
    nometa = drop_metadata(radio)
    #{webradio}"""
  return template