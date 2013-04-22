###
  Da Mighty Radio (DRM-E4)
    html5-only-go-fuck-yourselves-edition
###

class GuerillaStudio

  constructor : ->
    window.Studio = this

    @initGUI()

    api.register
      msg :
        login : (b) =>
          console.log "SUCCESS #{b}"
          @exec "left refresh"
          @exec "right refresh"
          @exec "master refresh"
          @exec "monitor refresh"
          # @exec "xfade refresh"
          Dialog.hide("#login-dialog")
          UIButton.byId.login.hide()
          UIButton.byId.studio.show()
          UIButton.byId.chat.show()
          UIButton.byId.search.show()
        raw : (m)-> console.log "RAW: #{m.raw}"
      studio :
        left    : ui.Left.message 
        right   : ui.Right.message
        monitor : ui.Monitor.message
        master  : ui.Master.message
      mode :
        live : (m)->
          ui.Master.out.state on
        off : (m)->
          ui.Master.out.state off
      search : (m)->
        return ui.Search.add_results m
      news : (m)->
        e = document.createElement "p"
        e.innerHTML =
          "NEWS(<a href='#{m.news.source}'>quelle</a>) " + 
          "#{m.news.title} " + 
          "(<a href='#{m.news.link}'>link</a>)<br/>"
        ticker.insertBefore e, ticker.firstChild

  cli :
    usage : => "login [user] [pass]"
    echo  : (args,reply) => args.join(' ')
    login : (args,reply) => @login(args.shift(),args.join(' '))

  search : (term) => api.socket.message {search:term}
  exec   : (m)    => api.socket.message(m) if api.socket?

  login  : (user,pass) =>
    salt = String.random(10)
    pass = SHA512(SHA512(pass)+salt)
    api.socket.message {login:{user:user,pass:pass,salt:salt}}
    return "logging in as #{user}"

  toggle_broadcast : () => api.socket.message "go live"

  toggleGUI : =>
    $("#windows").css("display", if $("#windows").css("display") is "none" then "block" else "none")
    @resize_faders()

  initGUI : =>
    window.ui = {}

    # CONSOLE :: refac
    window.my_console = $("#out").console
      promptLabel: "anx@radio> "
      commandValidate: (line) => true
      commandHandle: (data,reply) => 
        line = data.split(' ')
        cmd  = line.shift()
        return Studio.cli[cmd].call(api,line,reply) if Studio.cli[cmd]?
        api.socket.message data; true
      autofocus: true
      animateScroll: true
      promptHistory: true
    $("#out").on "focus", () ->          $("#console").css("bottom","0px")
    $("#console").on "mouseleave", () -> $("#console").css("bottom","-190px")
    $("#console").on "mouseenter", () ->
      $("#console").css("bottom","0px")
      $("#out")[0].focus()

    # MENU BUTTONS
    new UIButton
      hide : true
      parent : "#menu"
      id : "studio"
      class : "framed blank studio"
      click : -> Studio.toggleGUI()
      init  : -> $(btn.studio).hide()

    new UIButton
      hide : true
      parent : "#menu"
      id : "chat"
      class : "framed blank dj"
      click : =>
        if @rtc? then @rtc.quit()
        else @rtc = new WebRTC $("#chat")

    # new UIButton
    #   hide : true
    #   parent : "#menu"
    #   id : "search"
    #   class : "framed blank search"

    # LOGIN DIALOG :: refac
    new UIButton
      parent : "#menu"
      id : "login"
      class : "framed blank login"
      click : ->
        Dialog.show("#login-dialog")
        $("#user").focus()
    defbtn = (btns) ->
      for k, v of btns
        btn[k] = document.querySelector v.query
        btn[k].addEventListener  "click", v.click if v.click?
        v.init() if v.init?
    buttons =
      dologin :
        query : "#do-login"
        click : -> Studio.login TEXT("#user"), TEXT("#pass")
      nologin :
        query : "#cancel-login"
        click : -> Dialog.hide("#login-dialog")
    defbtn buttons
    $("#pass").on "keypress", (k,e)-> Studio.login TEXT("#user"), TEXT("#pass") if k.keyCode is 13

    # SETUP SLIDERS
    $(".fader.horizontal").slider(
      animate : true
      min : 0
      max : 100)

    # UI::GLUE::SEARCH
    ui.Search =
      field : $("#search")
      add_result : (el,uri) =>
        reset = () =>
          $("#results").css("display","none")
          ui.Left.playlist.removeClass("clickme")
          ui.Right.playlist.removeClass("clickme")
          ui.Left.playlist.off "click"
          ui.Right.playlist.off "click"
        ui.Left.playlist.addClass("clickme")
        ui.Right.playlist.addClass("clickme")
        ui.Left.playlist.on("click", () =>
          reset()
          ui.Left.push(uri))
        ui.Right.playlist.on("click", () =>
          reset()
          ui.Right.push(uri))
      add_results : (search) =>
        console.log "search.results"
        results = $("#results")
        results.css("display","block")
        results.css("position","fixed")
        lines = search.result.split("\n")
        for l in lines
          t = cleanup_filename(l)
          results.append "<a href='#' onclick='ui.Search.add_result(this,\"#{l}\")' class='result'>#{t}</a>"
        results.find("a").css("display","block")
    ui.Search.field.keypress (evt) =>
      if evt.which == 13
        console.log "search #{ui.Search.field.val()}"
        @search(ui.Search.field.val())
        return false
      true
    ui.Search.field.sortable
      connectWith: ".draggy"

    # UI::GLUE::DECKS
    ui.Left = new Deck("left")
    ui.Right = new Deck("right")

    # UI::GLUE::MIXERS
    ui.Master = new Mixer
      resource : "master"
      output :
        class : "signal"
        action : => @exec "go live-toggle"
      inputs :
        0 : "music"
        1 : "dj"
        2 : "conf"
        3 : "voip"
    ui.Monitor = new Mixer
      resource : "monitor"
      output:
        class : "monitor"
        action : => @exec "monitor.toggle"
      inputs :
        0 : "music"
        1 : "dj"

    # UI::GLUE::MODULES
    ui.Xfade = new Module("#xfade-grp")
    ui.Xfade.fader.on "slide", (evt,ui) =>
      api.socket.message("fade set #{ui.value}")
    ON "#broadcast", "click", => @toggle_broadcast()

    # resize .fader.horizontal
    @resize_faders = -> $("#decks .fader.vertical").css "height", ($(".playlist").height()-43) + "px"
    $(window).on "resize", @resize_faders


$(document).ready () -> new GuerillaStudio()