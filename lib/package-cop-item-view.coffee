###
  lib/package-cop-item-view.coffee
###

fs     = require 'fs'
crypto = require 'crypto'

pathUtil = require 'path'
{$,ScrollView} = require 'atom'
marked = require 'marked'

PackageVersion = require './package-version'

module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-help', outlet:'helpHeader'
      
      @div class:'package-cop-help', outlet:'helpProblems'
      @table class:'problems-table', outlet:'problemsTable', =>
        @tr => @th 'PROBLEMS'
        @tr => @td => @input class: 'native-key-bindings', \
                       placeholder: 'Enter new problem here'

      @div class:'package-cop-help', outlet:'helpPackages'
      @table class:'packages-table', outlet:'packagesTable', =>
        @tr =>
          @th =>
            @div class:'th-pkgs',       'INSTALLED PACKAGES'
            @div class:'th-loaded',     'Loaded'
            @div class:'th-activated',  'Activated'
            @div class:'th-enabled',    'Enabled'
            @div class:'th-ctrl-click', 'Ctrl-click for web page'
            
      @div class:'package-cop-help', outlet:'helpAction'
      
      @div class:'package-cop-help', outlet:'helpMethodology'
      
  initialize: (@packageCopItem) ->
    @subs = []
    @testData = @packageCopItem.getTestData()
    
    if atom.config.get 'package-cop.showHelpText'
      helpMD = fs.readFileSync pathUtil.join(__dirname, 'help.md'), 'utf8'
      regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
      while (match = regex.exec helpMD)
        @[match[1]].html marked match[2]
        --regex.lastIndex
        
    for metadata in atom.packages.getAvailablePackageMetadata()
      {name, version, homepage, repository} = metadata
      if name is 'package-cop' or atom.packages.isBundledPackage name then continue
      packageId = PackageVersion.packageIdFromNameVersion name, version
      @testData[packageId] ?= new PackageVersion name, version
      @testData[packageId].repoURL = homepage ? repository?.url ? repository
      @testData[packageId].inPackageMgrList = yes
      for packageId, pkgVers of @testData
        if pkgVers.name is name and pkgVers.version isnt version
          pkgVers.setOldVersion()

    for packageId, pkgVers of @testData
      if not pkgVers.inPackageMgrList
        if pkgVers.getTestRecords().length is 0
          @testData[packageId] = null
          continue
      delete pkgVers.inPackageMgrList
      
    nameCounts = {}
    for packageId, pkgVers of @testData when pkgVers
      nameCounts[pkgVers.name] ?= 0
      nameCounts[pkgVers.name]++
      
    pkgVersArray = []
    for packageId, pkgVers of @testData
      if pkgVers and nameCounts[pkgVers.name] > 1
        pkgVers.addVersionToTitle()
      pkgVersArray.push [packageId, pkgVers]
    pkgVersArray.sort()
        
    for packageIdPkgVers in pkgVersArray
      [packageId, pkgVers] = packageIdPkgVers
      if not pkgVers then delete @testData[packageId]; continue
      oldClass = (if pkgVers.getOldVersion() then ' old' else '')
      pkgVers.$tr = $ """
        <tr class="#{packageId}"> 
          <td>
            <span class="octicon octicon-dot dot"></span>
            <span class="name#{oldClass}">#{pkgVers.getTitle()}</span>
          </td> 
        </tr>
      """
      @packagesTable.append pkgVers.$tr
      
    @packageCopItem.putTestData()
    
    @chkActivatedInterval = setInterval =>
      for packageId, pkgVers of @testData
        if (state = pkgVers.getStateIfChanged())
          $dot = pkgVers.$tr.find '.dot'
          $dot.removeClass 'unloaded'
          $dot.removeClass 'loaded'
          $dot.removeClass 'activated'
          $dot.addClass state
        if (enabled = pkgVers.getEnabledIfChanged())?
          $name = pkgVers.$tr.find '.name'
          if enabled then $name.addClass    'enabled'
          else            $name.removeClass 'enabled'
    , 1000
    
    @setupEvents()

  selectProblem: ($tr) ->
    @problemsTable.find('tr').removeClass 'selected'
    $tr.addClass 'selected'
    # id = $tr.attr 'data-id'
    # $td  = $tr.find 'td'
    # title = $td.text()
    
  setupEvents: ->
    @subs.push @problemsTable.on 'keypress', 'input', (e) => 
      if e.which is 13
        $tr  = $(e.target).closest 'tr'
        $td  = $tr.find 'td'
        $inp = $tr.find 'input'
        if $inp.length
          if not (title = $inp.val()) then return
          for packageId, pkgVers of @testData
            if title.toLowerCase() is pkgVers.name.toLowerCase()
              atom.confirm
                message: 'Package-Cop: Duplicate Problem Name\n'
                detailedMessage: 'Another problem has the same name "' + pkgVers.name + '".'
                buttons: ['OK']
              return
          $newTr = $tr.clone()
          hashStr = title + (new Date().toString()) + Math.random()
          id = crypto.createHash("md5").update(hashStr).digest("hex")
          $inp.remove()
          $tr.addClass 'problem-title'
          $tr.attr 'data-id', id
          $td.text title
          $newTr.removeAttr 'data-id'
          $newTr.find('input').val ''
          @problemsTable.append $newTr
        @selectProblem $tr
        false
    
    @subs.push @problemsTable.on 'click', 'tr', (e) =>
      $tr = $ e.currentTarget
      if $tr.hasClass 'problem-title'
        @selectProblem $tr

    @subs.push @packagesTable.on 'click', 'tr', (e) =>
      $tr = $ e.currentTarget
      packageId = $tr.attr 'class'
      if not packageId then return
      pkgVers = @testData[packageId]
      
      if e.ctrlKey
        if e.altKey
          if pkgVers.uninstall()
            delete @testData[packageId]
            @packageCopItem.putTestData()
            $tr.remove()
        else
          @testData[packageId].openURL()
        return
        
      if pkgVers.getOldVersion() then return
      
      $name = $tr.find '.name'
      if pkgVers.getEnabled()
        pkgVers.deactivate()
        pkgVers.disable()
        pkgVers.unload()
        $name.removeClass('enabled')
      else 
        pkgVers.load()
        pkgVers.enable()
        pkgVers.activate()
        $name.addClass('enabled')

  destroy: ->
    if @chkActivatedInterval 
      clearInterval @chkActivatedInterval
    for sub in @subs 
      sub.off?()
      sub.unsubscribe?()
      
