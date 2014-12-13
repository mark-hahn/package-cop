"""
  lib/problem.coffee
"""        

crypto = require 'crypto'

module.exports =
class Problem
  
  constructor: (@name) ->
    if typeof @name is 'object'
      {@problemId, @name, @reports} = @name
    else
      hashStr = @name + (new Date().toString()) + Math.random()
      @problemId = 'prb-' + crypto.createHash('md5').update(hashStr).digest('hex')
      @reports = {}

  addReport: (reportId, failed) -> @reports[reportId] = failed
  
  getReports: -> @reports
  
  getLatestReportTime: -> 
    maxTime = 0
    for reportId of @reports
      maxTime = Math.max maxTime, reportId
    maxTime
    