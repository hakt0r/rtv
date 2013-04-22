b = new LiquidBridge
  smin: 2
  smax: 10
testcount = 1000
success = 0
cmd = [
  "master.status 0"
  "master.status 1"
  "master.status 2"
  "master.status 3"
  "master.status 4"
  "master.status 5" ]
cmd = "master.status 5"
console.log "start test"

test = ->
  test_ready = (expect) ->
    start_time = Date.now() / 1000
    test_leaf = (result) ->
      #result = result.join()
      if result == expect
        console.log "!",success++
        if success is testcount
          secs = Date.now() / 1000 - start_time
          console.log (testcount / secs), "rq/s total:", secs, " seconds"
      else
        console.log "ERROR!"
    #expect = expect.join()
    for i in [0..testcount]
      # console.log "start test #{i}"
      b.exec cmd, test_leaf
  b.exec cmd, test_ready
# setTimeout test, 1000
test()