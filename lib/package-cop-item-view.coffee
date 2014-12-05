###
  lib/package-cop-item-view.coffee
###

fs = require 'fs'
{execSync} = require 'child_process'

pathUtil = require 'path'
{$,ScrollView} = require 'atom'
marked = require 'marked'

PackageVersion = require './package-version'

module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-help', outlet:'helpProblems'

      @table outlet:'problemsTable', =>
        @tr =>
          @th =>

      @div class:'package-cop-help', outlet:'helpPackages'
      @table outlet:'packagesTable', =>
        @tr =>
          @th =>
            @div class:'th-pkgs',       'INSTALLED PACKAGES'
            @div class:'th-loaded',     'Loaded'
            @div class:'th-activated',     'Activated'
            @div class:'th-enabled',    'Enabled'
            @div class:'th-ctrl-click', 'Ctrl-click for web page'
            
      @div class:'package-cop-help', outlet:'helpAction'
      
      @div class:'package-cop-help', outlet:'helpMethodology'
      
  initialize: (packageCopItem) ->
    @subs = []
    @testData = packageCopItem.getTestData()
    
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
      
    packageCopItem.putTestData()

    @subs.push @packagesTable.on 'click', 'tr', (e) =>
      $tr = $ e.currentTarget
      packageId = $tr.attr 'class'
      if not packageId then return
      name = PackageVersion.nameFromPackageId packageId
      $name = $tr.find '.name'
      if e.ctrlKey
        if e.altKey
          Uninstall = atom.confirm
            message: 'Package Cop: Confirm Uninstall\n'
            detailedMessage: 'Are you sure you want to uninstall the package ' + name +
                            '? The package will be removed and all test results lost. ' +
                            'Please wait a few seconds ...'
            buttons: ['Cancel', 'Uninstall']
          if Uninstall
            try
              console.log execSync 'apm uninstall ' + name, encoding: 'utf8'
            catch e
              atom.confirm
                message: 'Package Cop: Error During Uninstall\n'
                detailedMessage: e.message
                buttons: ['OK']
              return
            delete @testData[packageId]
            packageCopItem.putTestData()
            $tr.remove()
        else
          url = @testData[packageId].repoURL ? 'https://atom.io/packages/' + name
          if atom.webBrowser
            atom.webBrowser.createPage url
          else
            require('shell').openExternal url
        return
        
      pkgVers = @testData[packageId]
      if pkgVers.getOldVersion() then return
      
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
    
  destroy: ->
    if @chkActivatedInterval 
      clearInterval @chkActivatedInterval
    for sub in @subs 
      sub.off?()
      sub.unsubscribe?()
      
