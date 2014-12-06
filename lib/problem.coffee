"""
  lib/problem.coffee
"""        

crypto = require 'crypto'

module.exports =
class Problem
  
  constructor: (@name) ->
    if typeof @name is 'object'
      {@problemId, @name, @latestReportTime} = @name
    else
      hashStr = @name + (new Date().toString()) + Math.random()
      @problemId = 'prb-' + crypto.createHash('md5').update(hashStr).digest('hex')
      @setLatestReportTime()

  getLatestReportTime: -> @latestReportTime
  setLatestReportTime: -> @latestReportTime = Date.now()
