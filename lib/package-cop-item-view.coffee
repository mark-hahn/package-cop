###
  lib/package-cop-item-view.coffee
###

fs = require 'fs'
path = require 'path'
{View} = require 'atom'
marked = require 'marked'

module.exports =
class PackageCopItemView extends View
  
  @content: ->
    @div class:'package-cop-item-view', tabIndex:-1, =>
      @div class:'package-cop-help', outlet:'helpTop'
      @div class:'package-cop-help', outlet:'helpMiddle'

  initialize: ->
    helpMD = fs.readFileSync path.join(__dirname, 'help.md'), 'utf8'
    regex = new RegExp '\\<([^>]+)\\>([^<]*)\\<', 'g'
    while (match = regex.exec helpMD) and match[1] isnt 'end'
      @[match[1]].html marked match[2]
      --regex.lastIndex
    
      
      
      