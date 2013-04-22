#!/usr/bin/liquidsoap

def message(data)
  print("echo '#{json_of(data)}\n' | nc -w 1 127.0.0.1 8100 &")
  system("echo '#{json_of(data)}\n' | nc -w 1 127.0.0.1 8100 &")
end

def pipe_in(id)
  strip_blank(
    input.external(
      id=id,
      restart=true,
      restart_on_error=true,
      "dd if=" ^ base_path ^ "/" ^ id))
end

def pipe_out(id,source)
  output.file(
    fallible=true,
    id=id,
    %wav(
      stereo=true,
      channels=2,
      samplesize=16,
      header=false),
    base_path ^ "/" ^ id,
    source)
end

def pa_hijack(id,source,command)
  system(base_path ^ "/src/radio.pa.launch mumble -k")
  system(base_path ^ "/src/radio.pa.launch mumble -p -v " ^ command)
  system("sleep 2")
  xpath=base_path ^ "/run/" ^ id ^ "-out"
  to_app = output.file(
      fallible=true,
      id=id ^ "-in",
      %wav(
        stereo=true,
        channels=2,
        samplesize=16,
        header=false),
      base_path ^ "/run/" ^ id ^ "-in",
      source)
  from_app = input.external(
    id=id ^ "-out",
    restart=true,
    restart_on_error=true,
    buffer=0.1,max=1.,
    "dd bs=1 if=" ^ xpath ^ " 2>/dev/null")
  (from_app,to_app)
end
#mumble_io = pa_hijack("mumble",radio,
#  "mumble \"mumble://radio@localhost/tech?version=1.2.0\"")
#mumble_in  = mksafe(fst(mumble_io))
#mumble_out = snd(mumble_io)

def out.wav.start()
  print("wav-start")
end
def out.wav.stop()
  print("wav-stop")
end
def out.wav(~start=true,id,source)
  output.harbor(
    %wav,
    id=id ^ "-wav",
    start=start,
    on_start = out.wav.start,
    on_stop = out.wav.stop,
    port = 8010,
    fallible = true,
    #url = id ^ ".wav",
    source)
end

def out.ogg(~start=true,id,source)
  output.icecast(
    %vorbis,
    id=id ^ "-ogg",
    start=start,
    fallible=true,
    mount=id ^ ".ogg",
    host=icecast_host,
    password=icecast_pass,
    source)
end

def out.opus(~start=false,id,source)
  output.icecast(
    start=start,
    id=id ^ "-opus",
    fallible=true,
    mount=id ^ ".opus",
    host=icecast_host,
    password=icecast_pass,
    format="audio/ogg",
    %opus(vbr="unconstrained", application="restricted_lowdelay", 
      complexity=5, max_bandwidth="wide_band", samplerate=48000, bitrate=64, 
      frame_size=20., channels=2, signal="music"),
    source)
end

def monitor.opus(~start=false,id,source)
  output.harbor(
    port = 8010,
    burst = 512,
    chunk = 128,
    start=start,
    id=id,
    fallible=true,
    mount=id ^ ".opus",
    %opus(vbr="unconstrained", application="voip", 
      complexity=5, max_bandwidth="narrow_band", samplerate=12000, bitrate=64, 
      frame_size=20., channels=2, signal="music"),
    source)
end

def monitor.ogg(~start=false,id,source)
  output.harbor(
    port = 8010,
    burst = 512,
    chunk = 128,
    start=start,
    id=id,
    fallible=true,
    mount=id ^ ".ogg",
    %vorbis,
    source)
end

def out.aac(~start=false,id,source)
  output.icecast(
    start=start,
    id=id ^ "-aac",
    fallible=true,
    mount=id ^ ".aac",
    host=icecast_host,
    password=icecast_pass,
    %aac(channels=2, samplerate=44100, bitrate=64, adts=true),
    source)
end

def out.mp3(~start=false,id,source)
  output.icecast(
    %mp3,
    start=start,
    id=id ^ "-mp3",
    fallible=true,
    mount=id ^ ".mp3",
    host=icecast_host,
    password=icecast_pass,
    source)
end

def queue.smart(id)
  s = audio_to_stereo(id=id,request.equeue(id=id,conservative=true))
  add_skip_command(s)
  s
end

def amplify.command(~id="zzsetmyid",~cmd="volume",source)
  setting = ref "100"
  pair = insert_metadata(id=id,source)
  source = snd(pair)
  metafn = fst(pair)
  metacm = fun (v)-> begin
    if v != "" then
      setting := v
      metafn([("setvolume",string_of(float_of_string(v)*0.01))]);
    end
    !setting
  end
  source = amplify(id=id,override="setvolume",1.0,source)
  source = map_metadata(update=true,fun (_)-> [("setvolume","")],source)
  server.register( "#{id}.#{cmd}", metacm )
  ignore(server.execute("#{id}.#{cmd} #{!setting}"))
  source
end

def queue.deck(id)
  s = audio_to_stereo(id=id,request.equeue(id=id))
  add_skip_command(s)
  s = on_track(fun (m)-> message([("studio",[(id,[("meta",m)])])]),s)
  s = amplify.command(id=id,s)
  play = ref false
  server.register("#{id}.play", fun(_)-> begin play := true; "DONE" end )
  server.register("#{id}.pause", fun(_)-> begin play := false; "DONE" end )
  server.register("#{id}.stop", fun(_)-> begin play := false; print(server.execute("#{id}.skip")); "DONE" end )
  server.register("#{id}.status", fun(_)-> if ( !play ) then "PLAY" else "STOP" end )
  s = switch(track_sensitive=false,[({ !play }, s),({ true }, fail() )])
  s
end

## JACK AUDIO (this one lacks metadata, video)
def jack.start()
  system("#{RADIO}/bin/radio.jack.start 2>&1")
end
def jack.connect(src,dst)
  system("jack_connect #{src}:out_0 #{dst}:in_0 &")
  system("jack_connect #{src}:out_1 #{dst}:in_1 &")
end
def jack.autoconnect(src,dst)
  source = input.jack(id=dst)
  on_blank(
    max_blank=1.,
    #length=1.,
    (fun () -> jack.connect(src,dst)),source)
end
def jack.out(id,source)
  jacksink = output.jack(
  id=id,
  fallible=true,
  source)
end

## WAV via HARBOUR (cpu-cheaper than ogg?)
def ipc.harbor.wav.output(id,source)
  output.harbor(
    id = "#{id}-wav",
    port = 8010,
    fallible = true,
    mount="#{id}.wav",
    %wav(stereo=true, channels=2, samplesize=16, header=true),
    source)
end

def ipc.harbor.wav.input(id)
  input.http(
    buffer = 2.0,
    max = 5.0,
    "http://localhost:8010/#{id}.wav" )
end