###
  lib/package-cop-item.coffee
###

{Emitter}   = require 'emissary'
PackageCopItemView = require './package-cop-item-view'

module.exports =
class PackageCopItem
  Emitter.includeInto @
  
  constructor: ->
  
  getTitle:     -> 'Packages'
  getViewClass: -> PackageCopItemView
  
