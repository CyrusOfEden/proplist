Proplist
========

[![Build Status](https://travis-ci.org/knrz/proplist.svg?branch=master)](https://travis-ci.org/knrz/proplist)
[![Inline docs](http://inch-ci.org/github/knrz/proplist.svg)](http://inch-ci.org/github/knrz/proplist)

Proplist provides the complete Keyword API, but for Proplists.

Documentation
-------------

You can find the docs over at [hexdocs](https://hexdocs.pm/proplist/), or take a look through `lib/proplist.ex` for inline docs.

N.B. In general, the functions are a 1-for-1 mapping of the `Keyword` functions. If there are differences, they've been aliased as their Keyword counterparts, e.g. `has_prop?` is aliased as `has_key?`.

Getting Started
---------------

Add `proplist` to your deps, then run `$ mix deps.get`.

```elixir
def deps do
  [{:proplist, "~> 0.1"}]
end
```

That's it!

Is it any good?
---------------

Yes.
