###
  WebRTC module
###

class WebRTC 

  constructor : (@parent) ->
    @videos = []
    me = this

    parent.append("""<div id="videos"><video id="rtc-you" autoplay/></div>""")
    if PeerConnection
      rtc.createStream { video: true , audio: true },
        (stream) ->
          you = document.getElementById("rtc-you")
          you.src = URL.createObjectURL(stream)
          me.videos.push you
          $(".layer").css("right","66px") # nudge layer to the right to make place for videos
    else
      alert "Your browser is not supported or rtc-you have to turn on flags. In chrome you go to chrome://flags and turn on Enable PeerConnection remember to restart chrome"
      return

    rtc.connect "ws://ulzq.de:8888", "studio"
    #rtc.connect "ws://ulzq.de:8022", "studio"
    rtc.on "add remote stream", (stream, socketId) ->
      console.log "ADDING REMOTE STREAM..."
      clone = me.cloneVideo("rtc-you", socketId)
      document.getElementById(clone.id).setAttribute "class", ""
      rtc.attachStream stream, clone.id
      me.subdivideVideos()
    rtc.on "disconnect stream", (data) ->
      console.log "remove " + data
      me.removeVideo data

    @websocketChat =
      send: (message) -> rtc._socket.send message
      recv: (message) -> message
      event: "receive_chat_msg"

    @dataChannelChat =
      send: (message) ->
        for connection of rtc.dataChannels
          channel = rtc.dataChannels[connection]
          channel.send message
      recv: (channel, message) -> JSON.parse(message).data
      event: "data stream data"

    @initFullScreen()
    @initNewRoom()
    @initChat()

  getNumPerRow : =>
    len = @videos.length
    biggest = undefined
    # Ensure length is even for better division.
    len++  if len % 2 is 1
    biggest = Math.ceil(Math.sqrt(len))
    biggest++  while len % biggest isnt 0
    biggest

  subdivideVideos : =>
    return
    perRow = @getNumPerRow()
    numInRow = 0
    i = 0
    len = @videos.length
    while i < len
      video = @videos[i]
      @setWH video, i
      numInRow = (numInRow + 1) % perRow
      i++

  setWH : (video, i) =>
    perRow = @getNumPerRow()
    perColumn = Math.ceil(@videos.length / perRow)
    width = Math.floor((window.innerWidth) / perRow)
    height = Math.floor((window.innerHeight - 190) / perColumn)
    video.width = width
    video.height = height
    video.style.position = "absolute"
    video.style.left = (i % perRow) * width + "px"
    video.style.top = Math.floor(i / perRow) * height + "px"

  cloneVideo : (domId, socketId) =>
    video = document.getElementById(domId)
    clone = video.cloneNode(false)
    clone.id = "remote" + socketId
    document.getElementById("videos").appendChild clone
    @videos.push clone
    clone

  removeVideo : (socketId) =>
    video = document.getElementById("remote" + socketId)
    if video
      @videos.splice @videos.indexOf(video), 1
      video.parentNode.removeChild video

  addToChat : (msg, color) =>
    messages = document.getElementById("messages")
    msg = @sanitize(msg)
    if color
      msg = "<span style=\"color: " + color + "; padding-left: 15px\">" + msg + "</span>"
    else
      msg = "<strong style=\"padding-left: 15px\">" + msg + "</strong>"
    messages.innerHTML = messages.innerHTML + msg + "<br>"
    messages.scrollTop = 10000

  sanitize : (msg) =>
    msg.replace /</g, "&lt;"

  initFullScreen : =>
    @fsBtn = new UIButton
      parent : "#chat"
      id : 'fullscreen'
      class : 'framed video'
      click : (event) =>
        elem = document.getElementById("videos")
        elem.webkitRequestFullScreen()

  initNewRoom : =>
    @newRoomBtn =  new UIButton
      parent : "#chat"
      id : "addroom"
      class : 'framed add'
      click : (event) =>
        chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
        string_length = 8
        randomstring = ""
        i = 0
        while i < string_length
          rnum = Math.floor(Math.random() * chars.length)
          randomstring += chars.substring(rnum, rnum + 1)
          i++
        window.location.hash = randomstring
        location.reload()

  initChat : =>
    return
    chat = undefined
    if rtc.dataChannelSupport
      console.log "initializing data channel chat"
      chat = @dataChannelChat
    else
      console.log "initializing websocket chat"
      chat = @websocketChat
    input = document.getElementById("out")
    room = window.location.hash.slice(1)
    color = "#" + ((1 << 24) * Math.random() | 0).toString(16)
    input.addEventListener "keydown", ((event) =>
      key = event.which or event.keyCode
      if key is 13
        chat.send JSON.stringify(
          eventName: "chat_msg"
          data:
            messages: input.value
            room: room
            color: color
        )
        @addToChat input.value
        input.value = ""
    ), false
    rtc.on chat.event, =>
      data = chat.recv.apply(this, arguments_)
      console.log data.color
      @addToChat data.messages, data.color.toString(16)

PeerConnection = window.PeerConnection or window.webkitPeerConnection00 or window.webkitRTCPeerConnection
window.WebRTC = WebRTC