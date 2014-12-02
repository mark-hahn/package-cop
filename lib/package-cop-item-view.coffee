###
  lib/package-cop-item-view.coffee
###

fs = require 'fs'
path = require 'path'
{ScrollView} = require 'atom'
marked = require 'marked'

module.exports =
class PackageCopItemView extends ScrollView
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-help', outlet:'helpProblems'
      @div class:'package-cop-help', outlet:'helpPackages'
      @table outlet:'packagesTable', =>
        @tr =>
          @th 'Enbled'
          @th 'Loaded'
          @th 'Active'
          @th 'Enable'
          @th 'Name'
      @div class:'package-cop-help', outlet:'helpAction'
      @div class:'package-cop-help', outlet:'helpMethodology'

  initialize: ->
    if atom.config.get 'package-cop.showHelpText'
      helpMD = fs.readFileSync path.join(__dirname, 'help.md'), 'utf8'
      regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
      while (match = regex.exec helpMD) and match[1] isnt 'end'
        @[match[1]].html marked match[2]
        --regex.lastIndex
      
    packages = {}
    for metadata in atom.packages.getAvailablePackageMetadata()
      name       = metadata.name
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
        disabled:    disabled = atom.packages.isPackageDisabled  name
        loaded:      loaded   = atom.packages.isPackageLoaded    name
        active:      active   = atom.packages.isPackageActive    name
        enable:      enable = no
        
      if not repository
        console.log 'package-cop: no repository found', name, metadata
      
      if bundled then continue
      
      check = '<span class="octicon octicon-check"></span>'
      
      @packagesTable.append """
        <tr>
          <td align="center"> 
            #{if disabled then '' else check}
          </td>
          <td align="center"> 
            #{if not loaded then '' else check}
          </td>
          <td align="center"> 
            #{if not active then '' else check}
          </td>
          <td align="center"> 
            #{if disabled then '' else check}
          </td>
          <td #{if disabled then 'class="name-disabled"' else ''}> 
            #{name}                         
          </td>
        </tr>
      """
      
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




