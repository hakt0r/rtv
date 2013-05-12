b = LiquidBridge.create
  sockets: 10
testcount = 1000
success = 0
cmd = [
  "request.trace 0"
  "request.trace 1"
  "request.trace 2" ]
test = ->
  console.log "start base test"
  b cmd, (expect) ->
    expect = expect.join('\n')
    console.log "base", expect
    console.log "start real tests"
    start_time = Date.now() / 1000
    for i in [1..testcount]
      b cmd, (result) ->
        result = result.join('\n')
        if result == expect
          success++
          if testcount is success
            secs = Date.now() / 1000 - start_time
            console.log (testcount*3 / secs).toFixed(1), "rq/s total:", secs.toFixed(1), " seconds"
        else console.log "ERROR\n", result
setTimeout test, 1000