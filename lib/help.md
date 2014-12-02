<helpProblems>
## Package Cop

*This page is the actual application, not just a help page.* You can turn off the help text on this page in the package configuration settings.

---

#### Problems ...

Add a problem by typing its name in an empty row.  Whenever you experience that problem check the `Occurred` check-box. Check this box only when the problem happened with the currently loaded and enabled packages.  Multiple problems can be checked.  Every time you change an `Occurred` text box an entry in a database is updated with test results including what packages were enabled.

*Note:* You only indicate when a problem happens, not when you think a problem isn't happening. When the `Occurred` check box is not checked it doesn't mean the problem isn't present. This ensures the accuracy of the data.

*Hint:* If you are concentrating on doing real work and not testing packages, and a problem occurs, just bring this page up, check the problem check-box, and return immediately to your work.

Clicking and selecting one of the problem names also controls what test results are displayed in the Packages list below.  Deleting a problem will permanently delete all test results for that problem.

***Table of problems goes here**

<helpPackages>

#### Packages ...

This is a list of all installed packages.  The `Currently Enabled` column shows the enabled state since the last load.  The `Enable` check-box controls whether the package will be enabled or disabled on the next reload of Atom.  The selection choices can be saved (see below) so you can experiment freely and then restore the settings.

The columns to the right of the package names are test results for the problem that is selected above in the `Problems` section.  The first column is an indicator for total history of that package with regard to the problem.  It shows `?` when 

The columns to the right are a history of problem events.  Only events for one problem are shown at once.  Select the problem to be displayed in the `Problems` section above. Each column represents one or more reloads of Atom. Multiple columns with the same results are combined. Each colored box is a problem occurance.  

<helpAction>

#### Action Buttons

<helpMethodology>

#### Test Methodology


<end>
