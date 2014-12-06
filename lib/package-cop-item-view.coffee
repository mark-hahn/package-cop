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
            @div class: 'btn native-key-bindings problem-fail', 'Problem Occured'
            @div class: 'btn native-key-bindings problem-pass', 'Passed Test'
            
          @div class:'edit-problem', =>
            @div class: 'problem-edit-hdr', 'Edit Problem:'
            @div class: 'btn native-key-bindings problem-rename', 'Rename'
            @div class: 'btn native-key-bindings problem-delete', 'Delete'
          
      @div class:'enable-horiz', =>
        @div class:'package-cop-help', outlet:'helpEnableBtns'
        
        @div class: 'enable-packages', =>
          @div class: 'enable-packages-hdr', 'Enable Packages:'
          @div class: 'btn native-key-bindings btn-sel-auto',     'Test This Problem (Bisect)'
          @div class: 'btn native-key-bindings btn-sel-auto-all', 'Test All Problems'
          @div class: 'btn native-key-bindings btn-sel-all',      'All'
          @div class: 'btn native-key-bindings btn-sel-none',     'None'
          @div class: 'btn native-key-bindings btn-sel-starred',  'Starred'
        
      @div class:'package-horiz', =>
        @div class:'package-cop-help', outlet:'helpPackages'
        
        @table class:'packages-table', outlet:'packagesTable', =>
          @tr =>
            @th =>
              @div class:'th-pkgs',       'INSTALLED PACKAGES'
              @div class:'th-click',      'Click to enable/disable'
              @div class:'th-ctrl-click', 'Ctrl-click for web page'
              @div class:'th-loaded',     'Loaded'
              @div class:'th-activated',  'Activated'
              @div class:'th-enabled',    'Enabled'
            
      @div class:'package-cop-help', outlet:'helpAction'
      @div class:'package-cop-help', outlet:'helpMethodology'
  
  initialize: (@packageCopItem) ->
    @subs = []
    @problems = @packageCopItem.getProblems()
    @packages = @packageCopItem.getPackages()
    
    problemList = []
    for problemId, prb of @problems then problemList.push prb
    problemList.sort (prba, prbb) -> prba.getLatestReportTime() - prbb.getLatestReportTime()
    for problem in problemList then @addProblemToTable problem, true
    @selectProblem()
    
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
        if pkg.name is name and pkg.version isnt version or
           pkg.name is 'Atom'
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
        <tr class="#{packageId}"> 
          <td>
            <span class="octicon octicon-dot dot"></span>
            <span class="name#{oldClass}">#{pkg.getTitle()}</span>
          </td> 
        </tr>
      """
      @packagesTable.append pkg.$tr
      
    @packageCopItem.saveDataStore()
    
    @chkActivatedInterval = setInterval =>
      for packageId, pkg of @packages
        if (state = pkg.getStateIfChanged())
          $dot = pkg.$tr.find '.dot'
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
    if $trs.length < 3 
      @find('.problem-detail').hide()
      $enablePackagesDiv.addClass 'no-problem'
      return
    @find('.problem-detail').show()
    $enablePackagesDiv.removeClass 'no-problem'
    $tr ?= $trs.eq(1)
    $tr.addClass 'selected'
    problemid = $tr.attr 'data-problemid'
    prb =  @problems[problemid]
    @problemName.text prb.name
    console.log prb.getLatestReportTime()
    time = moment prb.getLatestReportTime()
    @lastReport.html 'Last Report: ' +
      time.format('ddd') + '&nbsp;&nbsp;' +
      time.format('YYYY-MM-DD HH:mm:ss') + '&nbsp; &nbsp;' + time.fromNow()
    @resolution.text 'Packages Cleared: 0/0, 0%'
    
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
        
    @subs.push @problemDetail.on 'click', '.problem-delete', =>
      @deleteSelectedProblem()

    @subs.push @packagesTable.on 'click', 'tr', (e) =>
      $tr = $ e.currentTarget
      packageId = $tr.attr 'class'
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
      
