# the live.ogg dj-sink
live = strip_blank(
    id="live-strip",
    track_sensitive=true,
    #max_blank=5., threshold=-50.,
    audio_to_stereo(
      input.harbor(
        id="live", port=8010,
        password=icecast_pass,
        buffer=2.,max=5.,"live.ogg")))

radio = fallback(
  id="add-live",
  track_sensitive=false,
  [live,radio])