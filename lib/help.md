<helpHeader>

Package-Cop helps find which package is causing an error, is a manager for enabling/disabling/uninstalling packages, and a testing tool for Atom package development. See the Package-Cop readme for detailed instructions for each usage.

*Note: All help text like this can be hidden with the button above. The UI below is fully functional with or without this text.* 

<helpProblems>

---

### Problems And Resolution

If you are running repeated tests for one or more problems, then those problems should be added to the list below. If not skip to the next section.

A detail box appears on the right for the selected problem. At the top of the detail box, under the problem name, the date/time of the last activity is shown.  Also shown is the current state of the problem resolution.  Specifically it shows how many packages installed have been cleared, i.e. shown to not be the cause of the problem.  The goal is to increase that number until only the package causing the problem remains.

The `Report Result` buttons are used to record results of tests.  The `Problem Occurred` button should be clicked immediately after the problem has been observed.  On the other hand the `Test Passed` button should only be used when a conclusive test has shown the error isn't happening.  

And finally the `Edit Problem` buttons allow renaming and deleting the problem.

<helpActions>

---

### Actions

The `Enable Packages` buttons control what packages are enabled.  `All` and `None` enable/disable all packages immediately.  You can see the changes in the package list below.  `Save` stores the state of every package so it can be recalled with the `Restore` button.  It is recommended to save your preferred setup before testing.

The `Test Problem (Bisect)` button immediately changes half the packages that aren't cleared yet.  By alternating between the `Report Result` buttons and this button you can rapidly increase the number of cleared packages.  This is similar to the `git --bisect` operation.  If more than two problems are in the list, another button `Test All Problems` appears which does the same bisect operation but on all problems at once.  This is usually faster that doing one problem at a time.

The `Reload Atom` button restarts Atom like `ctrl-alt-R` except this Package-Cop page is auto-loaded afterwards.  The `Activate all enabled on reload` causes all enabled packages to be activated during load.  This is cleared after each use to make sure the behavior is not accidentally left on.

<helpPackages>

---

### Packages

The table below shows a list of all installed packages.  The leftmost column shows the name of the package along with its current live state.  The state is shown to the left of the name as either a blank space, a gray dot, or a red dot. As the legend at the top indicates, gray is loaded and red is activated

If the package will be loaded on the next Atom reload, i.e. enabled, then its name is in bold. `Click` on the name to enable or disable the package.  The package is immediately loaded/activated or deactivated/unloaded to match the enabled state.

`Ctrl-click` on the package name to bring up its web page in an external browser or inside Atom (if the `web-browser` package is installed). `Ctrl-alt-click` will allow you to uninstall the package.

### Test Results (optional)

The columns to the right of the package name show detailed test results that have been recorded.  They can usually be ignored but can sometimes give useful clues. 

The first column shows a green checkmark if the package has been "cleared" of the problem selected above in the `Problems And Resolution` section. The `Failed Reports` and `Passed Reports` columns also apply only to this problem.  On each click of the `Problem Occurred` button a new column of dashes and dots will appear in the failed column and likewise the `Test Passed` button will cause them to appear in the passed column.

Each dash/dot matches what was to the left of the package name when the report was made, i.e. the state of the package.  A dash is the same as a blank space.

When you `hover` over a dot/dash the time the report was made is shown.  If you `click` on one the entire report (column of dashes/dots) may be deleted from the record.

<end>
