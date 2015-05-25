###
  lib/package-cop-item-view.coffee
###

fs = require 'fs'
util = require 'util'
SubAtom  = require 'sub-atom'
pathUtil = require 'path'
$ = require 'jquery'
{ScrollView} = require 'atom-space-pen-views'
marked = require 'marked'
moment = require 'moment'
_      = require 'underscore'

Problem = require './problem'
Package = require './package'

module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class: 'package-cop-hdr', =>
        @div class:'package-cop-title', 
                   '__________ Package Cop __________'
        @div class:'btn native-key-bindings help-btn', outlet:'helpBtn'
        
      @div class:'package-cop-help', outlet:'helpHeader'
      
      @div class:'problem-horiz', =>
        @div class:'package-cop-help', outlet:'helpProblems'
        
        @div class:'problems-table', =>
          @table outlet:'problemsTable', =>
            @tr => @th 'SELECT PROBLEM'
            @tr => @td => @input class: 'native-key-bindings new-problem-input', \
                           placeholder: 'Enter new problem'
                 
        @div class: 'problem-detail', outlet: 'problemDetail', =>
          @div class: 'problem-hdr', =>
            @div class: 'problem-hdr-hdr', =>
              @div class: 'problem-name', outlet: 'problemName'
            @div class: 'problem-hdr-summary', =>
              @div class: 'last-report', outlet: 'lastReport'
              @div class: 'resolution', =>
                @span class: 'cleared', outlet: 'cleared'
              
          @div class: 'report-result', =>
            @div class: 'report-result-hdr', 'Report Result:'
            @div class: 'btn native-key-bindings problem-report fail', 'Problem Occurred'
            @div class: 'btn native-key-bindings problem-report pass', 'Test Passed'
            
          @div class:'edit-problem', outlet:'editProblem', =>
            @div class: 'problem-edit-hdr', 'Edit Problem:'
            @div class: 'btn native-key-bindings problem-rename', 'Rename'
            @div class: 'btn native-key-bindings problem-delete', 'Delete'
            @input class: 'native-key-bindings rename-input', outlet: 'renameInput'
          
      @div class:'action-horiz', =>
        @div class:'package-cop-help', outlet:'helpActions'
        @div class: 'enable-packages', outlet:'enablePackages', =>
          @div class: 'enable-packages-hdr', 'Enable Packages:'
          @div class: 'enable-packages-btns', outlet:'enablePackagesBtns',  =>
            @div class: 'btn native-key-bindings btn-sel-all',      'All'
            @div class: 'btn native-key-bindings btn-sel-none',     'None'
            @div class: 'btn native-key-bindings btn-sel-save',     'Save'
            @div class: 'btn native-key-bindings btn-sel-restore',  'Restore'
            @div class: 'btn native-key-bindings btn-sel-auto-all', 'Test All Problems'
            @div class: 'btn native-key-bindings btn-sel-auto',     'Test Problem (Bisect)'
        
        @div class: 'reload-atom', =>
          @div class: 'reload-atom-hdr', 'Restart:'
          @div class: 'btn native-key-bindings btn-reload', \
               outlet:'reloadAtom', 'Reload Atom'
          @label class: 'reload-activate', \
                        'Activate all enabled on reload', =>
            @input class:'reload-activate-chkbox', type:'checkbox', \
                   outlet:'reloadActivateChkbox'

      @div class:'package-horiz', =>
        @div class:'package-cop-help', outlet:'helpPackages'
        @table class:'packages-table', outlet:'packagesTable', =>
          @tr class:'pkg-hdr-tr', =>
            @th  class:'th-installed', =>
              @div class:'th-pkgs', 'Installed Packages:'
              @div class:'th-legend', =>
                @div class:'th-loaded loaded legend',       'Loaded'
                @div class:'th-activated activated legend', 'Activated'
                @div class:'th-enabled legend',             'Enabled'
                @div class:'th-cleared legend',             'Cleared'
        
            @th class:'th-chkmrk'
            @th class:'th-fails', =>
              @span class:'th-fails-label', 'Failed Reports'
            @th class:'th-passes', =>
              @span class:'th-passes-label', 'Passed Reports'
              
        @div class:'time-popup hidden', outlet:'timePopup'
              
  initialize: (@packageCopItem) ->
    @subs = new SubAtom
    @problems = @packageCopItem.getProblems()
    @packages = @packageCopItem.getPackages()
    @reports  = null
    @setHelpBtn no
    
    problemList = []
    for problemId, prb of @problems then problemList.push prb
    problemList.sort (prba, prbb) -> prba.getLatestReportTime() - prbb.getLatestReportTime()
    for problem in problemList then @addProblemToTable problem, true
    
    @addUntitledProblemIfNeeded()
    
    helpMD = fs.readFileSync pathUtil.join(__dirname, 'help.md'), 'utf8'
    regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
    while (match = regex.exec helpMD)
      @[match[1]].html marked match[2]
      --regex.lastIndex
    
    for metadata in atom.packages.getAvailablePackageMetadata().concat {
                    name: 'Atom', version: atom.getVersion()
                    homepage: 'http://atom.io'}
      {name, version, homepage, repository, theme} = metadata
      if name is 'package-cop' or theme or not name or not version or 
         atom.packages.isBundledPackage name then continue
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
        if not hasState
          @packages[packageId] = null
          continue
      
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
      
      state   = pkg.getState()
      enabled = (if pkg.getEnabled()    then ' enabled' else '')
      old     = (if pkg.getOldVersion() then ' old'     else '')
      pkg.$tr = $ """
        <tr class="" data-packageId="#{packageId}"> 
          <td class="dotname">
            <span class="octicon octicon-dot dot current #{state}"></span>
            <span class="name#{old}#{enabled}">#{pkg.getTitle()}</span>
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
      for packageId, pkg of @packages when pkg.$tr
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
    
  addUntitledProblemIfNeeded: ->
    if (_.size @problems) is 0
      $tr = @problemsTable.find('input.new-problem-input').closest 'tr'
      @addProblem 'Untitled', $tr
  
  addProblem: (name, $tr) ->
    @currentProblem = new Problem name
    @problems[@currentProblem.problemId] = @currentProblem
    @packageCopItem.saveDataStore()
    @addProblemToTable @currentProblem
    @selectProblem $tr
  
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

  renameSelectedProblem: ->
    if @currentProblem and not @renameInput.hasClass 'active'
      @editProblem.addClass 'rename'
      @renameInput.addClass 'active'
                  .val @currentProblem.name
                  .focus()
    
  cancelProblemRename: ->
    @editProblem.removeClass 'rename'
    @renameInput.removeClass 'active'

  deleteSelectedProblem: ->
    if ($tr = @problemsTable.find 'tr.selected').length is 0 then return
    problemId = $tr.attr 'data-problemid'
    problem = @problems[problemId]
    name = problem.name
    btn = atom.confirm
      message: 'Package-Cop: Confirm Problem Deletion\n'
      detailedMessage: 'Are you sure you want to delete the problem "' + name +
                        '" and all its test report data?'
      buttons: ['Cancel', 'Delete']
    if btn is 1
      reportIds = []
      reports = problem.getReports()
      for reportId of reports then reportIds.push reportId
      for reportId in reportIds
        @deleteReport reportId, yes
      delete @problems[problemId]
      @packageCopItem.saveDataStore()
      $tr.remove()
      @selectProblem()
      @addUntitledProblemIfNeeded()
      
  setLastReport: -> 
    if (time = @currentProblem.getLatestReportTime())
      timeMoment = moment time
      @lastReport.html 'Last Report: ' +
        timeMoment.format('ddd') + '&nbsp;&nbsp;' +
        timeMoment.format('YYYY-MM-DD HH:mm:ss') + '&nbsp; &nbsp;' + 
        timeMoment.fromNow()
      @lastReport.show()
    else 
      @lastReport.hide()
  
  selectProblem: ($tr) ->
    @addUntitledProblemIfNeeded()
    $trs = @problemsTable.find('tr')
    $trs.removeClass 'selected'
    @enablePackagesBtns.removeClass 'no-problem'
    @enablePackagesBtns.removeClass 'one-problem'
    @enablePackagesBtns.removeClass 'gt-one-problem'
    if $trs.length < 3 
      @find('.problem-detail').hide()
      @enablePackagesBtns.addClass 'no-problem'
      @currentProblem = null
      @updateChecked yes
      return
    else if $trs.length is 3 
      @enablePackagesBtns.addClass 'one-problem'
    else
      @enablePackagesBtns.addClass 'gt-one-problem'
    @find('.problem-detail').css display: 'inline-block'
    $tr ?= $trs.eq(1)
    $tr.addClass 'selected'
    problemid = $tr.attr 'data-problemid'
    @currentProblem = @problems[problemid]
    @problemName.text @currentProblem.name
    @setLastReport()
    @updateChecked()

    states = []
    @reports = @currentProblem.getReports()
    for reportId, failed of @reports
      states.push [reportId, failed]
    states.sort()
    for packageId, pkg of @packages when pkg.$tr
      $tr.find('.fails-dot,.passes-dot').remove()
      for state in states
        [reportId, failed] = state
        state = pkg.getStates()[reportId] ? 'no-state'
        @addReportDot $tr, failed, state, reportId

  updateChecked: (clearChecks) ->
    @packagesTable.find('.check')
      .removeClass 'cleared'
    if clearChecks then return
    
    numCleared = 0
    for packageId, pkg of @packages when pkg.$tr
      if @isCleared pkg, @currentProblem
        numCleared++
        pkg.$tr.find('.check').addClass 'cleared'
      else nameNotCleared = pkg.name
    numPkgs = _.size @packages
    percent = Math.round numCleared * 100 / numPkgs
    @cleared.removeClass 'all-cleared found-it'
    if numCleared is numPkgs then @cleared.addClass 'all-cleared' 
    if numCleared is numPkgs-1
      @cleared.text 'Package causing problem: ' + nameNotCleared
              .addClass 'found-it'
    else @cleared.text \ 
      "Packages Cleared: #{numCleared}/#{numPkgs}, #{percent}%"
    
  addReportDot: ($tr, failed, state, reportId) ->
    tdClass = (if failed then 'fails' else 'passes')
    $td = $tr.find 'td.' + tdClass
    $td.append '<span data-reportid="' + reportId + '" ' +
      'class="' + tdClass + '-dot ' + state + ' report' +
      (switch state
         when 'no-state' then '">&nbsp;</span>'
         when 'unloaded' then '">-</span>'
         else ' octicon octicon-dot"></span>')
      
  deleteReport: (reportId, dontSave) ->
    @packagesTable
      .find('span.report[data-reportid="' + reportId + '"]')
      .remove()
    delete @reports[reportId]
    for packageId, pkg of @packages
      delete pkg.getStates()[reportId]
    if not dontSave
      @packageCopItem.saveDataStore()
      @updateChecked()
    
  getProblemName: ($inp, sameAsSelOK) ->
    if not /\w/.test (name = $inp.val()) then return
    name = name.replace /^\s+|\s+$/g, ''
    lcName = name.toLowerCase()
    for problemId, problem of @problems
      if lcName is problem.name.toLowerCase() and
          not (sameAsSelOK and lcName is @currentProblem.name.toLowerCase())
        atom.confirm
          message: 'Package-Cop: Duplicate Problem Name\n'
          detailedMessage: 'Another problem has the same name "' + problem.name + '".'
          buttons: ['OK']
        return 
    return name

  enableDisablePackage: (pkg, enable) ->
    pkg.enableDisable enable
    if pkg.$tr
      $name = pkg.$tr.find '.name'
      if enable then $name.addClass('enabled') else $name.removeClass('enabled')
    else console.log 'Package-cop enableDisablePackage, no pkg.$tr:', util.inspect pkg, depth: null
      
  enableAllSetup: -> 
    for packageId, pkg of @packages
      @enableDisablePackage pkg, yes
    @packageCopItem.saveDataStore()
    false
  enableNoneSetup: ->
    for packageId, pkg of @packages
      @enableDisablePackage pkg, no
    @packageCopItem.saveDataStore()
    false
  enableSaveSetup:  ->
    for packageId, pkg of @packages
      pkg.saveState()
    @packageCopItem.saveDataStore()
    false
  enableRestoreSetup: ->
    for packageId, pkg of @packages when pkg.$tr
      {state, enabled} = pkg.getSavedState()
      if pkg.getState()   isnt state or
         pkg.getEnabled() isnt enabled
        pkg.restoreState()
        $dot = pkg.$tr.find '.dot'
        $dot.removeClass 'unloaded'
        $dot.removeClass 'loaded'
        $dot.removeClass 'activated'
        $dot.addClass state
        $name = pkg.$tr.find '.name'
        if enabled then $name.addClass('enabled')
        else $name.removeClass('enabled')
    @packageCopItem.saveDataStore()
    false
    
  isCleared: (pkg, problem) ->
    cleared = no
    for reportId, failed of problem.reports
      state = pkg.states[reportId]
      if state is   'activated' and not failed or
         state isnt 'activated' and     failed
        return yes
    no
    
  anyProblemNotCleared: (pkg) ->
    for problemId, problem of @problems
      if not @isCleared pkg, problem then return true
    false
        
  enableAutoSetup: (allProblems) ->
    flip = no
    for packageId, pkg of @packages
      notCleared = (if allProblems then @anyProblemNotCleared pkg \
                    else not @isCleared pkg, @currentProblem)
      if notCleared and (flip = not flip)
        pkg.enableDisable not pkg.getEnabled()
    @packageCopItem.saveDataStore()
    false

  setHelpBtn: (flip) ->
    hide = @packageCopItem.getHideHelpFlag() 
    if flip then hide = not hide
    $help = @.find('.package-cop-help')
    if hide
      @helpBtn.text 'Show Help'
      $help.addClass 'hidden'
    else 
      @helpBtn.text 'Hide Help'
      $help.removeClass 'hidden'
    hide
    
  setupEvents: ->
    @subs.add  @helpBtn, 'click', =>
      hideHelp = @setHelpBtn yes
      @packageCopItem.setHideHelpFlag hideHelp
      
    @subs.add @problemsTable, 'keypress', 'input.new-problem-input', (e) => 
      if e.which is 13
        $inp = $ e.target
        if (name = @getProblemName $inp)
          @addProblem name, $inp.closest 'tr'
        false

    @subs.add @problemsTable, 'click', 'tr', (e) =>
      $tr = $(e.target).closest 'tr'
      if $tr.hasClass 'problem-name'
        @selectProblem $tr
        
    @subs.add @problemDetail, 'click', '.problem-report', (e) =>
      failed = $(e.target).hasClass 'fail'
      reportId = Date.now()
      @currentProblem.addReport reportId, failed
      @setLastReport()
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
      @updateChecked()

    @subs.add @problemDetail, 'click', '.problem-rename', =>
      @renameSelectedProblem()

    @subs.add @renameInput, 'keypress', (e) => 
      if e.which is 13
        if (name = @getProblemName $(e.target), yes)
          @problemsTable.find('tr.selected td').text name
          @problemName.text name
          @currentProblem.name = name
          @packageCopItem.saveDataStore()
        @cancelProblemRename()
        false

    @subs.add @renameInput, 'blur', => @cancelProblemRename()
    
    @subs.add @problemDetail, 'click', '.problem-delete', =>
      @deleteSelectedProblem()
      
    @subs.add @enablePackages, 'click', '.btn-sel-all',       => @enableAllSetup()
    @subs.add @enablePackages, 'click', '.btn-sel-none',      => @enableNoneSetup()
    @subs.add @enablePackages, 'click', '.btn-sel-save',      => @enableSaveSetup()
    @subs.add @enablePackages, 'click', '.btn-sel-restore',   => @enableRestoreSetup()
    @subs.add @enablePackages, 'click', '.btn-sel-auto-all',  => @enableAutoSetup yes
    @subs.add @enablePackages, 'click', '.btn-sel-auto',      => @enableAutoSetup no
    
    @reloadActivateChkbox.on 'change', (e) =>
      @packageCopItem.setReloadActivateFlag $(e.target).is ':checked'
      
    @subs.add @reloadAtom, 'click', => 
      @packageCopItem.setReloadedFromThisPackageFlag yes
      $('body').trigger 'window:reload'
  
    @subs.add @packagesTable, 'click', 'td.dotname', (e) =>
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
        
      if not pkg.getOldVersion() and pkg.name isnt 'Atom'
        @enableDisablePackage pkg, not pkg.getEnabled()
        
    @subs.add @packagesTable, 'mouseover', 'span.report', (e) =>
      $tgt = $ e.target
      timeMoment = moment +$tgt.attr 'data-reportid'
      pos = $tgt.position()
      @timePopup.css left: pos.left-100, top: pos.top-15
                .removeClass 'hidden'
                .html \
                  timeMoment.format('ddd')                 + '&nbsp; &nbsp;' +
                  timeMoment.format('YYYY-MM-DD HH:mm:ss') + '&nbsp; &nbsp;' + 
                  timeMoment.fromNow()
      setTimeout (=> @timePopup.addClassHidden), 2500
    @subs.add @packagesTable, 'mouseout', 'span.report', =>
      @timePopup.addClass 'hidden'
      
    @subs.add @packagesTable, 'click', 'span.report', (e) =>
      $tgt = $ e.target
      reportId = $tgt.attr 'data-reportid'
      timeMoment = moment +reportId
      button = atom.confirm
        message: 'Packe-Cop: conform report deletion\n'
        detailedMessage: 'Are you sure you want to delete the ' +
          (if $tgt.hasClass('fails-dot') then 'failure' else 'success') +
          ' report from ' + 
           timeMoment.format('ddd') + '  ' +
           timeMoment.format('YYYY-MM-DD HH:mm:ss') + '  ' + 
           timeMoment.fromNow() + '?'
        buttons: ['Cancel', 'Delete']
      if button is 1
        @deleteReport reportId

  destroy: ->
    if @chkActivatedInterval 
      clearInterval @chkActivatedInterval
    @subs.dispose()
      
