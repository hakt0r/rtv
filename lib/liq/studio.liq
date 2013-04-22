# the studio environment

jack.start()

# tv = ref false # is the tv supposed to broadcast
studio  = ref false # is the studio supposed to broadcast
conference = ref false # alt.: only overlay mumble

left    = queue.deck("left")
right   = queue.deck("right")
music   = mix(id="xfade",[left,right])

dj      = strip_blank(id="dj",max_blank=0.1,input.jack(id="dj-in"))
conf    = strip_blank(id="conf",max_blank=0.1,input.jack(id="conf-in"))
voip    = strip_blank(id="voip",max_blank=0.1,input.jack(id="voip-in"))

monitor = mix(id="monitor",[music,dj]) #conf,voip,music,radio
monitor = amplify.command(id="monitor",cmd="volume.out",monitor)

master  = mix(id="master",[music,dj,conf,voip,radio])
master  = amplify.command(id="master",cmd="volume.out",master)

def studio.init()
  print("studio.init")
  print(server.execute("xfade.select 0 true"))
  print(server.execute("xfade.select 0 true"))
  print(server.execute("xfade.select 1 true"))
  print(server.execute("xfade.volume 1 0"))
  ( -1. )
end

add_timeout(fast=false,1.,studio.init)

# output.jack(start=true,fallible=true,id="monitor-jack",monitor)
monitor.ogg(start=true,"monitor-web",drop_metadata(monitor))

radio = switch(
  track_sensitive=false,[
  ({ !studio }, master ),
  ({ !conference }, smooth_add(normal=radio,special=dj) ),
  ({ true }, radio )
])

# api functions ################################################################

def mumble.start(display,~vnc=false)
  system("pkill Xvfb; rm -f /tmp/.X#{display}-lock; Xvfb :#{display} -screen 1 400x400x24 &")
  system("while LANG=C DISPLAY=:#{display} xkbbell 2>&1 | " ^
    "grep -q open; do sleep 0.5; done")
  if vnc then
    system("DISPLAY=:#{display} x11vnc -ncache 2 &")
  end
  system("DISPLAY=:#{display} HOME=/var/radio/etc " ^ 
      "mumble \"mumble://radio@localhost/tech?version=1.2.0\" &" ^
    "\nwhile ! jack_lsp | grep -q mumble; do sleep 0.5; done" ^
    "\njack_connect monitor-jack:out_0 mumble:input" ^
    "\njack_connect monitor-jack:out_1 mumble:input" ^
    "\njack_connect mumble:output dj-in:in_0" ^
    "\njack_connect mumble:output dj-in:in_1")
end
def mumble.stop(display)
  system("sh -c 'kill -QUIT $(cat /tmp/.X#{display}-lock)'")
end
def conference.stop()
  conference := false  
  mumble.stop(0)
end
def conference.start()
  conference := true  
  mumble.start(0)
end
def studio.start()
  studio := true
end
def studio.stop()
  studio := false
end
def studio.go.live()
  if !conference then conference.stop() end
  studio.start()
end
def studio.go.conf()
  if !studio then studio.stop() end
  conference.start()
end
def studio.go.off()
  if !conference then conference.stop()
  elsif !studio then studio.stop() end
end
def studio.go(a)
  mode = (
    if a == "live-toggle" then
      if !studio then
        studio.go.off()
        "off"
      else
        studio.go.live()
        "live"
      end
    elsif a == "live" then
      studio.go.live()
      "live"
    elsif a == "conference" then
      studio.go.conf()
      "conference"
    else
      studio.go.off()
      "off"
    end )
  message([("studio",[("mode",mode)])])
end

## public api function

def studio.status(_)
  if !studio then "studio mode"
  elsif !conference then "conference mode"
  else "offline" end
end
server.register("go", fun (a)-> begin studio.go(a) "DONE" end )
server.register("status", studio.status )
server.register("mumble.start", fun (_)-> begin mumble.start(0);"DONE" end )
server.register("mumble.stop",  fun (_)-> begin mumble.stop(0);"DONE" end )
server.register("mumble.restart", fun (_)-> begin mumble.stop(0);mumble.start(0);"DONE" end )
