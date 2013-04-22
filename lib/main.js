dirname = require('path').dirname
fs = require('fs')
child_process = require('child_process')

dir = dirname(dirname(process.mainModule.filename))

init = function(){
  Bot = require('./rex/lib/main.js')

  RTV = new Bot({
    "project" : dir,
    "project_lib" : dir + "/lib",
    "config_path" : dir + "/etc",
    "config_file" : dir + "/etc/rtv.json",
    "modules" : [ "rtv" ],
    "bootstrap" : function(onfinish){
      require('./rtv/rtv').bootstrap(onfinish)
    }
  })
  module.exports = RTV
}

if(!fs.existsSync(dir+"/node_modules")){
  console.log("installing node.js dependencies");
  p = child_process.spawn("npm",["install"],{"cwd":dir,"stdio":[0,1,2]})
  p.on('close',function(data){
    p = child_process.spawn("npm",["install"],{"cwd":dir+"/lib/rex","stdio":[0,1,2]})
    p.on('close',function(data){
      init();
    })
  })
  return; }
else init();