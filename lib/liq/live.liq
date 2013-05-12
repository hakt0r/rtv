# the live.ogg dj-sink

livesink = ref false

live = input.harbor(
  id="live", port=8010,
  password=icecast_pass,
  buffer=2.,max=5.,"live.ogg")

live = fallback(
  id="add-live",
  track_sensitive=false,
  [ strip_blank(
      id="live-strip",
      track_sensitive=false,
      #max_blank=5., threshold=-50.,
      audio_to_stereo(live)),
    radio])

radio = switch(
  track_sensitive=false,[
  ({ !livesink }, live ),
  ({ true }, radio )
])

def icecast_sink(a)
  mode = (
    if a == "on" then
      livesink := true
      "on"
    elsif a == "off" then
      livesink := false
      "off"
    elsif !livesink then "on"
    else "off" end )
  message([("studio",[("ice",mode)])])
end
server.register("ice", fun (a)-> begin icecast_sink(a) "DONE" end )