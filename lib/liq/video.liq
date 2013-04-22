#!/usr/bin/liquidsoap

set("frame.video.channels",1)
set("frame.video.samplerate",5)
set("frame.video.width",320)
set("frame.video.height",240)

radio = mksafe(mux_video(video=single("#{RADIO}/web/img/rtv.png"),radio))
movie = request.equeue(id="movie")
video = fallback(track_sensitive=false,[movie,radio])
#video = clock(sync=false,video)
#video = mksafe(buffer(video))
radio = drop_video(video)

ignore(radio)
ignore(video)