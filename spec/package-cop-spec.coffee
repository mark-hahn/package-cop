{WorkspaceView} = require 'atom'
PackageCop = require '../lib/package-cop'

# Use the command `window:run-pkg-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "PackageCop", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('package-cop')

  describe "when the package-cop:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.package-cop')).not.toExist()

      # This is an activation event, triggering it will cause the pkg to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'package-cop:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.package-cop')).toExist()
        atom.commands.dispatch atom.workspaceView.element, 'package-cop:toggle'
        expect(atom.workspaceView.find('.package-cop')).not.toExist()
