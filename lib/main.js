/*
  main.js - part of the RTV project
  - CoffeScript Glue Code
  - Trigger `make deps`
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3
*/

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
    "bootstrap" : require('./rtv/rtv').bootstrap
  })
  module.exports = RTV}

if(!fs.existsSync(dir+"/node_modules")){
  console.log("installing node.js dependencies");
  p = child_process.spawn("make",["deps"],{"cwd":dir,"stdio":[0,1,2]})
  p.on('close',function(data){init()})
  return; }
else init();