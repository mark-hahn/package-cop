###
  lib/package-cop-item-view.coffee
###

fs     = require 'fs'

pathUtil = require 'path'
{$,ScrollView} = require 'atom'
marked = require 'marked'
moment = require 'moment'

Problem = require './problem'
Package = require './package'

module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-title', 
                 '__________ Package Cop __________'
      @div class:'package-cop-help', outlet:'helpHeader'
      
      @div class:'problem-horiz', =>
        @div class:'package-cop-help', outlet:'helpProblems'
        
        @div class:'problems-table', =>
          @table outlet:'problemsTable', =>
            @tr => @th 'SELECT PROBLEM'
            @tr => @td => @input class: 'native-key-bindings', \
                           placeholder: 'Enter new problem'
                 
        @div class: 'problem-detail', outlet: 'problemDetail', =>
          @div class: 'problem-hdr', =>
            @div class: 'problem-hdr-hdr', =>
              @div class: 'problem-name', outlet: 'problemName'
            @div class: 'problem-hdr-summary', =>
              @div class: 'last-report',        outlet: 'lastReport'
              @div class: 'resolution',         outlet: 'resolution'
              
          @div class: 'report-result', =>
            @div class: 'report-result-hdr', 'Report Result:'
            @div class: 'btn native-key-bindings problem-report fail', 'Problem Occurred'
            @div class: 'btn native-key-bindings problem-report pass', 'Passed Test'
            
          @div class:'edit-problem', =>
            @div class: 'problem-edit-hdr', 'Edit Problem:'
            @div class: 'btn native-key-bindings problem-rename', 'Rename'
            @div class: 'btn native-key-bindings problem-delete', 'Delete'
          
      @div class:'package-horiz', =>
        @div class:'package-cop-help', outlet:'helpPackages'
        
        @div class: 'enable-packages', =>
          @div class: 'enable-packages-hdr', 'Enable:'
          @div class: 'btn native-key-bindings btn-sel-auto',     'Test Problem (Bisect)'
          @div class: 'btn native-key-bindings btn-sel-auto-all', 'Test All Problems'
          @div class: 'btn native-key-bindings btn-sel-all',      'All'
          @div class: 'btn native-key-bindings btn-sel-none',     'None'
          @div class: 'btn native-key-bindings btn-sel-starred',  'Starred'
        
        @table class:'packages-table', outlet:'packagesTable', =>
          @tr class:'pkg-hdr-tr', =>
            @th  class:'th-installed', =>
              @div class:'th-pkgs',       'INSTALLED PACKAGES'
              # @div class:'th-click',      'Click to enable/disable'
              @div class:'th-ctrl-click', 'Ctrl-click for web page'
              @div class:'th-legend loaded',    'Loaded'
              @div class:'th-legend activated', 'Activated'
              @div class:'th-enabled',          'Enabled'
              @div class:'th-cleared',          'Cleared'
        
            @th class:'th-chkmrk'
            @th class:'th-Fails',  'Failed Setups'
            @th class:'th-Passes', 'Passed Setups'
              
      @div class:'package-cop-help', outlet:'helpAction'
      @div class:'package-cop-help', outlet:'helpMethodology'
  
  initialize: (@packageCopItem) ->
    @subs = []
    @problems = @packageCopItem.getProblems()
    @packages = @packageCopItem.getPackages()
    @reports  = null
    
    problemList = []
    for problemId, prb of @problems then problemList.push prb
    problemList.sort (prba, prbb) -> prba.getLatestReportTime() - prbb.getLatestReportTime()
    for problem in problemList then @addProblemToTable problem, true
    
    if atom.config.get 'package-cop.showHelpText'
      helpMD = fs.readFileSync pathUtil.join(__dirname, 'help.md'), 'utf8'
      regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
      while (match = regex.exec helpMD)
        @[match[1]].html marked match[2]
        --regex.lastIndex
    
    for metadata in atom.packages.getAvailablePackageMetadata().concat {
                    name: 'Atom', version: atom.getVersion()
                    homepage: 'http://atom.io'}
      {name, version, homepage, repository} = metadata
      if name is 'package-cop' or atom.packages.isBundledPackage name then continue
      packageId = Package.packageIdFromNameVersion name, version
      @packages[packageId] ?= new Package name, version
      @packages[packageId].repoURL = homepage ? repository?.url ? repository
      @packages[packageId].inPackageMgrList = yes
      for packageId, pkg of @packages
        if pkg.name is name and pkg.version isnt version
          pkg.setOldVersion()

    for packageId, pkg of @packages
      if not pkg.inPackageMgrList
        hasState = no
        for hasState of pkg.getStates() then break
        if hasState
          @packages[packageId] = null
          continue
      delete pkg.inPackageMgrList
      
    nameCounts = {Atom: 1}
    for packageId, pkg of @packages when pkg
      nameCounts[pkg.name] ?= 0
      nameCounts[pkg.name]++
    
    packageArray = []
    for packageId, pkg of @packages
      if pkg and nameCounts[pkg.name] > 1
        pkg.addVersionToTitle()
      packageArray.push [packageId, pkg]
    packageArray.sort()
        
    for packageIdPkgVers in packageArray
      [packageId, pkg] = packageIdPkgVers
      if not pkg then delete @packages[packageId]; continue
      oldClass = (if pkg.getOldVersion() then ' old' else '')
      pkg.$tr = $ """
        <tr class="" data-packageId="#{packageId}"> 
          <td class="dotname">
            <span class="octicon octicon-dot dot current"></span>
            <span class="name#{oldClass}">#{pkg.getTitle()}</span>
          </td> 
          <td>
            <span class="octicon octicon-check check"></span>
          </td> 
          <td class="fails"></td> 
          <td class="passes"></td> 
        </tr>
      """
      @packagesTable.append pkg.$tr
      
    @packageCopItem.saveDataStore()
    @selectProblem()
    
    @chkActivatedInterval = setInterval =>
      for packageId, pkg of @packages
        if (state = pkg.getStateIfChanged())
          $dot = pkg.$tr.find '.dot.current'
          $dot.removeClass 'unloaded'
          $dot.removeClass 'loaded'
          $dot.removeClass 'activated'
          $dot.addClass state
        if (enabled = pkg.getEnabledIfChanged())?
          $name = pkg.$tr.find '.name'
          if enabled then $name.addClass    'enabled'
          else            $name.removeClass 'enabled'
    , 1000
    
    @setupEvents()
    
  addProblemToTable: (prb, reverse) -> 
    $tr = @problemsTable.find 'tr:last'
    $newTr = $tr.clone()
    $tr.find('input').remove()
    $tr.addClass 'problem-name'
    $tr.attr 'data-problemid', prb.problemId
    $tr.find('td').text prb.name
    $newTr.removeAttr 'data-problemid'
    $newTr.find('input').val ''
    @problemsTable.append $newTr
    if reverse then @problemsTable.find('tr:first').after $tr

  deleteSelectedProblem: ->
    if ($tr = @problemsTable.find 'tr.selected').length is 0 then return
    problemId = $tr.attr 'data-problemid'
    name = @problems[problemId].name
    btn = atom.confirm
      message: 'Package-Cop: Confirm Problem Deletion\n'
      detailedMessage: 'Are you sure you want to delete the problem "' + name +
                        '" and all its test report data?'
      buttons: ['Cancel', 'Delete']
    if btn is 1
      delete @problems[problemId]
      @packageCopItem.saveDataStore()
      $tr.remove()
      @selectProblem()
  
  selectProblem: ($tr) ->
    $trs = @problemsTable.find('tr')
    $trs.removeClass 'selected'
    $enablePackagesDiv = @find '.enable-packages'
    $enablePackagesDiv.removeClass 'no-problem'
    $enablePackagesDiv.removeClass 'one-problem'
    if $trs.length < 3 
      @find('.problem-detail').hide()
      $enablePackagesDiv.addClass 'no-problem'
      return
    else if $trs.length is 3 
      $enablePackagesDiv.addClass 'one-problem'
    @find('.problem-detail').css display: 'inline-block'
    $tr ?= $trs.eq(1)
    $tr.addClass 'selected'
    problemid = $tr.attr 'data-problemid'
    @currentProblem =  @problems[problemid]
    @problemName.text @currentProblem.name
    if (time = @currentProblem.getLatestReportTime())
      timeMoment = moment time
      @lastReport.html 'Last Report: ' +
        timeMoment.format('ddd') + '&nbsp;&nbsp;' +
        timeMoment.format('YYYY-MM-DD HH:mm:ss') + '&nbsp; &nbsp;' + 
        timeMoment.fromNow()
      @lastReport.show()
    else 
      @lastReport.hide()
    @resolution.text 'Packages Cleared: 0/0, 0%'
    
    states = []
    reports = @currentProblem.getReports()
    for reportId, failed of reports
      states.push [reportId, failed]
    states.sort()
    for packageId, pkg of @packages
      $tr = pkg.$tr
      $tr.find('.fails-dot,.passes-dot').remove()
      for state in states
        [reportId, failed] = state
        state = pkg.getStates()[reportId]
        @addReportDot $tr, failed, state, reportId
    
  addReportDot: ($tr, failed, state, reportId) ->
      tdClass = (if failed then 'fails' else 'passes')
      $td = $tr.find 'td.' + tdClass
      $td.append '<span data-reportId="' + reportId + '" ' +
        'class="octicon octicon-dot ' + tdClass + '-dot ' + state + '"></span>'
    
  setupEvents: ->
    @subs.push @problemsTable.on 'keypress', 'input', (e) => 
      if e.which is 13
        $tr = $(e.target).closest 'tr'
        if ($inp = $tr.find 'input').length
          if not /\w/.test (name = $inp.val()) then return
          name = name.replace /^\s+|\s+$/g, ''
          for problemId, prb of @problems
            if name.toLowerCase() is prb.name.toLowerCase()
              atom.confirm
                message: 'Package-Cop: Duplicate Problem Name\n'
                detailedMessage: 'Another problem has the same name "' + prb.name + '".'
                buttons: ['OK']
              return
          prb = new Problem name
          @problems[prb.problemId] = prb
          @packageCopItem.saveDataStore()
          @addProblemToTable prb
          @selectProblem $tr
        false
    
    @subs.push @problemsTable.on 'click', 'tr', (e) =>
      $tr = $(e.target).closest 'tr'
      if $tr.hasClass 'problem-name'
        @selectProblem $tr
        
    @subs.push @problemDetail.on 'click', '.problem-report', (e) =>
      failed = $(e.target).hasClass 'fail'
      reportId = Date.now()
      @currentProblem.addReport reportId, failed
      @packagesTable.find('tr:not(.pkg-hdr-tr)').each (idx, tr) =>
        $tr = $ tr
        $dot = $tr.find '.dot.current'
        state = switch
          when $dot.hasClass 'unloaded'  then 'unloaded'
          when $dot.hasClass 'loaded'    then 'loaded'
          when $dot.hasClass 'activated' then 'activated'
        @addReportDot $tr, failed, state, reportId
        packageId = $tr.attr 'data-packageId'
        @packages[packageId].getStates()[reportId] = state
      @packageCopItem.saveDataStore()

    @subs.push @problemDetail.on 'click', '.problem-delete', =>
      @deleteSelectedProblem()

    @subs.push @packagesTable.on 'click', 'td.dotname', (e) =>
      $tr = $(e.target).closest('tr')
      packageId = $tr.attr 'data-packageId'
      if not packageId then return
      pkg = @packages[packageId]
      
      if e.ctrlKey
        if e.altKey
          if pkg.uninstall()
            delete @packages[packageId]
            @packageCopItem.saveDataStore()
            $tr.remove()
        else
          @packages[packageId].openURL()
        return
        
      if pkg.getOldVersion() then return
      
      $name = $tr.find '.name'
      if pkg.getEnabled()
        pkg.deactivate()
        pkg.disable()
        pkg.unload()
        $name.removeClass('enabled')
      else 
        pkg.load()
        pkg.enable()
        pkg.activate()
        $name.addClass('enabled')

  destroy: ->
    if @chkActivatedInterval 
      clearInterval @chkActivatedInterval
    for sub in @subs 
      sub.off?()
      sub.unsubscribe?()
      
