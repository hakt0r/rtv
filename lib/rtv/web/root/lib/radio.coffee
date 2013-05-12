###
  Da Mighty Radio (DRM-E4)
    html5-only-go-fuck-yourselves-edition
###

class GuerillaRadio

  newsid : 0

  urls :
    radio :
      "audio/ogg" : "http://ulzq.de:8000/web.ogg"
      "audio/aac" : "http://ulzq.de:8000/web.aac"
      "audio/mp3" : "http://ulzq.de:8000/web.mp3"
    tv :
      "video/ogg" : "http://ulzq.de:8000/tv.ogg"

  constructor : ->
    window.Radio = this
    globalize_ids ['tv','ticker','title']
    window.btn =
      play    : document.querySelector "#play-btn"
      stop    : document.querySelector "#stop-btn"
      volume  : document.querySelector "#volume"
    btn.play.addEventListener   "click", -> Radio.mode "play"
    btn.stop.addEventListener   "click", -> Radio.mode "stop"
    btn.volume.addEventListener "change", -> Radio.tv.setVolume this.value if Radio.tv?

    new UIButton
      hide : true
      parent : "#menu"
      id : "radio"
      class : "framed blank radio"
      click : -> Radio.mode "play", "radio"

    new UIButton
      hide : true
      parent : "#menu"
      id : "tv"
      class : "framed blank tv"
      click : -> Radio.mode "play", "tv"

    api.register
      meta : (m) => $("#title").html meta_to_title(m)
      news : (m) =>
        $("#news").append """
          <div class="news" id="news-#{++Radio.newsid}">
            <h2>
              <a href='#{m.link}'>#{m.title}</a>
              (<a href='#{m.source}'>quelle</a>)
            </h2>
          </div>"""
        @remove_newsitem Radio.newsid

  remove_newsitem : (id) ->
    setTimeout ->
      i = $("#news-#{id}")
      i.fadeOut 5000, ->
        i.remove()
    , 10000

  mode : (action,what) =>
    what = "radio" unless what?    
    console.log "mode: #{action} #{what}"
    switch action
      when "stop" then (action = "stopped"; @tv.pause(); )
      when "play"
        for mime, url of @urls[what]
          if soundManager.canPlayURL url
            @tv.destruct() if @tv?
            flash =  -> $(btn.play).fadeTo(100,0.5).delay(100).fadeTo(100,1.0)
            @tv = soundManager.createSound
              id : what
              url : url
              volume : btn.volume.value
              onid3 : (e) -> console.log e
              whenload : => flash Radio.mode "loaded"
              whenloading : => flash Radio.mode "loading"
              onconnect : => flash Radio.mode "connected"
              ondataerror : (e) -> @mode "stopped", what, console.error e
              onerror : (e) => @mode "stopped", what, console.error e
              onfinish : (e) -> flash Radio.mode "stopped", what, @play()
              play : (e) => flash @mode "playing", what
              onplay : (e) => flash @mode "playing", what
              onbufferchange : (v)=> flash Radio.mode if v then "buffering" else "playing"
              # whileplaying : => Radio.mode "playing"
              # whileloading : => flash Radio.mode "buffering"
            @tv.play()
            break
      when "buffering"
        btn["play"].className = "framed play #{action}"
      when "playing"
        btn["play"].className = "framed play #{action}"
        switch what
          when "radio"
            $(btn.radio).addClass("on")
            $(btn.tv).removeClass("on")
          when "tv"
            $(btn.radio).removeClass("on")
            $(btn.tv).addClass("on")

$(document).ready () ->
  new GuerillaRadio()
  api.connect()
  soundManager.setup
    debugMode : off
    url : "/lib"
    onready : ->