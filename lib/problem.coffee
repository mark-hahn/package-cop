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
    
  calcCleared: (packages) ->
    pkgChecks = {}
    for packageId, pkg of packages
      haveFailClear = no
      havePassClear = no
      for reportId, failed of @reports
        state = pkg.states[reportId]
        if state is   'activated' and not failed then havePassClear = yes
        if state isnt 'activated' and     failed then haveFailClear = yes
        if haveFailClear and havePassClear 
          pkgChecks[packageId] = 'conflicted'
          break
      if not pkgChecks[packageId] and (haveFailClear or havePassClear)
        pkgChecks[packageId] = 'cleared'
    pkgChecks
    