# git-gps

A set of functionality to track commits in a git repository by GPS 
coordinates.

Currently only works on OS X.

## Installation

Build the git-gps project, and put the resulting git-gps binary in
`/usr/local/bin`.

Now, to start logging GPS on checkins in a checkout of a git repo, run:

```sh
git-gps init
```

Then, each time you commit to the repo, a post-commit hook will be run
which updates the `.git-gps` file at the root of the repository.

This is very alpha-level software, so please file issues, etc. 

Patches welcome!
