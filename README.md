# git-gps

A tool to track commits in a git repository by GPS coordinates.

Currently only works on OS X.

## Motivation

For awhile now, I've wanted GPS logging of my checkins to source control
systems. Between the `CoreLocation` framework on OS X and git's post-commit
hooks, this is now possible.

## Installation

Build the git-gps project, and put the resulting git-gps binary in
`/usr/local/bin`.

Now, to start logging GPS on checkins in a checkout of a git repo, go to
your repo and run:

```sh
git-gps init
```

Then, each time you commit to the repo, a post-commit hook will be run
which updates the `.git-gps` file at the root of the repository and adds
it to the commit.

This is very alpha-level software, so please file issues, etc. 

Patches welcome!
