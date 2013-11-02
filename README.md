# Rub, a build system.

Rub is designed to be a flexible build system for all projects and languages.

For the official documentation see the
[Wiki](https://github.com/kevincox/rub/wiki), or clone it for offline viewing.

	git clone https://github.com/kevincox/rub.wiki.git

We track our issues in [Launchpad](https://launchpad.net/rub).

Rub is designed to provide a simple framework for writing build scripts and
libraries to be used by those build scripts.  Rub does not offer any language
specific tools but instead libraries for every language.  These libraries
abstract away the system dependant details and allow your project to build on
a wide variety of systems.  You tell these libraries what you want done and they
tell Rub how to do it.

Rub treats every build as fresh, there are no clean or configure steps.  You
simply run rub with what you want built and it generates your project.  However,
in the interest of speed Rub "caches" results.  If all the inputs, outputs and
commands are the same as the last run Rub knows that the same file will be
generated so it uses the old version.

Rub also has interesting properties such as depending on system files.  This
means that you C programs will be re-compiled after a compiler upgrade, even if
you didn't change your program at all.  This ties into building fresh every
time, you should always get the same result as building from scratch.

Rub is a work in progress and there are a lot of "suppot" code that needs to be
written before libraries will work reasonably.  By writing these functions into
Rub we don't need to have them in every library.
