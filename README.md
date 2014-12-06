# Package-Cop

Atom editor: Find pkg causing an error by logging errors

This is not ready for use.  Development has barely started.  This is being published for discussion and to claim the name `package-cop`.  

### Status

You can run this pkg now but only help will appear, although the help implementation is interesting in how it uses markdown to generate the HTML of the actual application.

### Planned Features (2014-11-26)

I'm including notes from `discuss.atom.io` which cover most of the planned functionailty.  

---

I'm working on a pkg that accomplishes two things, both related to enabling and disabling installed packages. 

First it provides a list of your installed packages and each one can be toggled between enabled and disabled with a click on the name. Secondly it provides a built-in algorithm, similar to a git bisect, that enables a set of packages for each reload to find what pkg is causing an error.

---

This pkg spec is evolving rapidly as I work on it ...

It now serves a third purpose as a general purpose logger. It logs the test results over time and you don't really have to be doing an "active" test to make use of it.

- You can blindly enable whatever packages you want, do your normal workflow, and only have to deal with this utility when an error happens and you log the error. Then you can go back to work with little interruption..The log can later be processed by an inference logic engine.

- Logging is also good for reporting. You can say bug foo happened the first time when pkg bar changed to version X. This "coincidence" checking is a different kind of analysis from bisection.

- I'm going to monitor whether a pkg was activated when the error happened, not just if it was enabled. I may only consider activated pkg status for inclusion in the test data.

- I'm going to consider every version of a pkg as a separate entity in the inference logic. I'm also including each version of Atom in the test data like pkg data. The Atom version is a very significant variable.

- I'm allowing one to register and track multiple problems as they happen. This means the multiple problems can share test state and get more utility out of each reload.

- I've also got some ideas that enhance the testing not just passively monitor it.

  - One trick is to force all packages to be activated at load. This   will slow down load time and other operations but should increase the chances of breaking it which helps.

  - Some serious breakage can be done by using fuzz-busting. In other words randomly and rapidly fire off commands (being careful to protect stuff).

  - Fuzz busting would also be a good for acceptance testing of a single pkg.

All this mish-mash of features will be blended together into a new type of utility that is everything having to do with monitoring packages and their problems. In other words it does one thing but has a tool-belt of different tools.
