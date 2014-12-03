###
  lib/package-cop-item-view.coffee
###

fs = require 'fs'
pathUtil = require 'path'
{$,ScrollView} = require 'atom'
marked = require 'marked'

capitalize = (str) ->
  caStr = str.toLowerCase()
  regex = new RegExp '(^|\\W)\\w', 'g'
  while (match = regex.exec str)
    caStr = caStr[0...match.index] + 
            match[0].toUpperCase() + 
            caStr[regex.lastIndex...] 
  caStr
  
module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-help', outlet:'helpProblems'
      @div class:'package-cop-help', outlet:'helpPackages'
      @table outlet:'packagesTable', =>
        @tr =>
          @th =>
            @div class:'th-pkgs', 'INSTALLED PACKAGES'
            @div class:'th-loaded',     'Loaded'
            @div class:'th-active',     'Active'
            @div class:'th-enabled',    'Enabled'
            @div class:'th-ctrl-click', 'Ctrl-click for web page'
      @div class:'package-cop-help', outlet:'helpAction'
      @div class:'package-cop-help', outlet:'helpMethodology'
 
  initialize: ->
    @subs = []
    if atom.config.get 'package-cop.showHelpText'
      helpMD = fs.readFileSync pathUtil.join(__dirname, 'help.md'), 'utf8'
      regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
      while (match = regex.exec helpMD)
        @[match[1]].html marked match[2]
        --regex.lastIndex
      
    packages = {}
    for metadata in atom.packages.getAvailablePackageMetadata()
      name = metadata.name
      if atom.packages.isBundledPackage name then continue
      
      repository = metadata.repository ? ''
      if typeof repository is 'object'
        repository = repository.url ? ''
        
      packages[name] = pkg =
        version:     metadata.version
        description: metadata.description
        repository:  repository
        path:        path     = atom.packages.resolvePackagePath name
        bundled:     bundled  = atom.packages.isBundledPackage   name
        willBeDisabled: \
               willBeDisabled = atom.packages.isPackageDisabled name
      if not repository
        console.log 'package-cop: no repository found', name, metadata
      
      if bundled then continue
      
      wbd = (if willBeDisabled then ' willBeDisabled' else '')
      @packagesTable.append """
        <tr class="pkg-#{name}"> <td>
          <span class="octicon octicon-dot dot"></span>
          <span class="name#{wbd}">#{capitalize name.replace /-/g, ' '}</span>
        </td> </tr>
      """
      
    @subs.push @packagesTable.on 'click', 'tr', (e) ->
      $tr   = $ @
      $name = $tr.find '.name'
      name  = $tr.attr('class')[4...]
      if e.ctrlKey
        url = 'https://atom.io/packages/' + name
        if atom.webBrowser
          atom.webBrowser.createPage url
        else
          require('shell').openExternal url
        return
        
      if $name.hasClass('willBeDisabled') 
        packages[name].willBeDisabled = no
        atom.packages.enablePackage name
        atom.packages.activatePackage name
        $name.removeClass('willBeDisabled')
      else 
        packages[name].willBeDisabled = yes
        atom.packages.deactivatePackage name
        atom.packages.disablePackage name
        $name.addClass('willBeDisabled')
        
    setState = (name, state, set) ->
      if set
        if not pkg[state]
          pkg[state] = yes
          $("tr.pkg-#{name} .dot").addClass state
      else
        if pkg[state]
          pkg[state] = no
          $("tr.pkg-#{name} .dot").removeClass state
      
    @chkActiveInterval = setInterval ->
      for name, pkg of packages 
        setState name, 'loaded', atom.packages.isPackageLoaded name
        setState name, 'active', atom.packages.isPackageActive name
    , 1000
    
  destroy: ->
    if @chkActiveInterval then clearInterval @chkActiveInterval
    for sub in @subs then sub.off()
      
###

packages       = atom.packages.getAvailablePackageNames()
metadata       = atom.packages.getAvailablePackageMetadata()

path           = atom.packages.resolvePackagePath pkgName
bundled        = atom.packages.isBundledPackage   pkgName
disabled       = atom.packages.isPackageDisabled  pkgName
loaded         = atom.packages.isPackageLoaded    pkgName
active         = atom.packages.isPackageActive    pkgName

package        = atom.packages.enablePackage      pkgName
package        = atom.packages.disablePackage     pkgName

activePackages = atom.packages.getActivePackages()
loadedPackages = atom.packages.getLoadedPackages()

package        = atom.packages.getLoadedPackage pkgName
package        = atom.packages.getActivePackage pkgName

###




