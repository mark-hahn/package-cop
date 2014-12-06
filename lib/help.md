<helpProblems>
## Package Cop

*This page is the actual application, not just a help page.* You can turn off the help text on this page in the pkg configuration settings.

---

#### Problems ...

Add a prb by typing its name in an empty row.  Whenever you experience that prb check the `Occurred` check-box. Check this box only when the prb happened with the currently loaded and enabled packages.  Multiple problems can be checked.  Every time you change an `Occurred` text box an entry in a database is updated with test results including what packages were enabled.

*Note:* You only indicate when a prb happens, not when you think a prb isn't happening. When the `Occurred` check box is not checked it doesn't mean the prb isn't present. This ensures the accuracy of the data.

*Hint:* If you are concentrating on doing real work and not testing packages, and a prb occurs, just bring this page up, check the prb check-box, and return immediately to your work.

Clicking and selecting one of the prb names also controls what test results are displayed in the Packages list below.  Deleting a prb will permanently delete all test results for that prb.

***Table of problems goes here**

<helpPackages>

#### Packages ...

This is a list of all installed packages.  The `Currently Enabled` column shows the enabled state since the last load.  The `Enable` check-box controls whether the pkg will be enabled or disabled on the next reload of Atom.  The selection choices can be saved (see below) so you can experiment freely and then restore the settings.

The columns to the right of the pkg names are test results for the prb that is selected above in the `Problems` section.  The first column is an indicator for total history of that pkg with regard to the prb.  It shows `?` when 

The columns to the right are a history of prb events.  Only events for one prb are shown at once.  Select the prb to be displayed in the `Problems` section above. Each column represents one or more reloads of Atom. Multiple columns with the same results are combined. Each colored box is a prb occurance.  

<helpAction>

#### Action Buttons

<helpMethodology>

#### Test Methodology


<end>
