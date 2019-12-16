# JuDoc

[MacOS/Linux] | Coverage
:-----------: | :------:
[![Build Status](https://travis-ci.org/tlienart/SimpleParser.jl.svg?branch=master)](https://travis-ci.org/tlienart/SimpleParser.jl) | [![codecov.io](http://codecov.io/github/tlienart/SimpleParser.jl/coverage.svg?branch=master)](http://codecov.io/github/tlienart/SimpleParser?branch=master)

This parser is a clean rewrite of [JuDoc](https://github.com/tlienart/JuDoc.jl)'s parser and will eventually be used by JuDoc but could also be used to build other parsers for simple markup languages like Common Markdown.

This package is currently **not** registered and rather allows to work and test the parser independently of the rest of the machinery.
Feel free to fork it though.

## Gist

Simple Parser is for people who don't want to bother themselves with theory and just want to assume that their parser is doing something similar to what a human would do when reading something like Markdown.

The steps are:

1. Find tokens (read the text once and build a list of anything that could mark something to do),
1. Find blocks (convert single Tokens or groups of Tokens into something that must be processed later on as a block).

### Tokens

A pass goes over all characters in the text, specific characters trigger a "Pattern" check which is effectively a look-ahead:
- either looking up a single character or a fixed number of characters (e.g.: does this look  like "abc"),
- or a greedy look-up taking characters as long as they meet a rule (e.g.: is this a bunch of letters).

What to do is contained in a tokens dictionary.

```
Placeholder for example
```

### Blocks
