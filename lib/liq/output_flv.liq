# ok :> no further debug info... no progress
output.gstreamer.audio_video(
  clock_safe=false,
  pipeline="
  appsrc name=\"asrc\" block=true caps=\"audio/x-raw,format=S16LE,layout=interleaved,channels=2,rate=44100\" format=time ! queue ! audioconvert ! audioresample ! speexenc ! muxer. 
  appsrc name=\"vsrc\" block=true caps=\"video/x-raw,format=RGBA,width=320,height=240,framerate=25/1,pixel-aspect-ratio=1/1\" format=time blocksize=307200 ! queue ! videoconvert ! videoscale add-borders=true ! videorate ! x264enc pass=pass1 threads=0 bitrate=1536 tune=zerolatency ! muxer.
  flvmux name=muxer ! rtmpsink location='rtmp://localhost:1935/tracker.live.bittorrent.com:3000'",
  video)