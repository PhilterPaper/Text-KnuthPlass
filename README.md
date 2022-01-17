# Text-KnuthPlass

`Text::KnuthPlass` is a Perl and XS (C) implementation of the well-known TeX
paragraph-shaping (a.k.a. line-breaking) algorithm, as created by Donald E.
Knuth and Michael F. Plass in 1981.

Given a long string containing the text of a paragraph, this module decides
where to split a line (possibly hyphenating a word in the process), while
attempting to:

* maintain fairly consistent text "tightness"
* minimize hyphenation overall
* not have two or more hyphenated lines in a row
* not have entire words "floating" over the next line
* not hyphenate the penultimate line

What it **doesn't** do:

* attempt to avoid widows and orphans. This is the job of the calling routine, as `Text::KnuthPlass` doesn't know how much of the paragraph fits on this page (or column) and how much has to be spilled to the next page or column.
* attempt to avoid hyphenating the last word of the last line of a _split_ paragraph on a page or column (as before, it doesn't know where you're going to be splitting the paragraph between columns or pages).

The Knuth-Plass algorithm does this by defining "boxes", "glue", and
"penalties" for the paragraph text, and fiddling with line break points to
minimize the overall sum of penalties. This can result in the "breaking" of one
or more of the listed rules, if it results in an overall better score ("better
looking" layout).

`Text::KnuthPlass` handles word widths by either character count, or a user-
supplied width function (such as based on the current font and font size). It
can also handle varying-length lines, if your column is not a perfect rectangle.

## Installation

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

## Documentation

After installation, documentation can be found via

    perldoc Text::KnuthPlass

or

    pod2html lib/Text/KnuthPlass.pm > KnuthPlass.html

## Support

Bug tracking is via

    "https://github.com/PhilterPaper/Text-KnuthPlass/issues?q=is%3Aissue+sort%3Aupdated-desc+is%3Aopen"

(you will need a GitHub account to create or contribute to a discussion, but
anyone can read tickets.) The old RT ticket system is closed.

Do NOT under ANY circumstances open a PR (Pull Request) to report a bug. It is
a waste of both your and our time and effort. Open a regular ticket (issue),
and attach a Perl (.pl) program illustrating the problem, if possible. If you
believe that you have a program patch, and offer to share it as a PR, we may
give the go-ahead. Unsolicited PRs may be closed without further action.

## License

This product is licensed under the Perl license. You may redistribute under
the GPL license, if desired, but you will have to add a copy of that license
to your distribution, per its terms.

(c)copyright 2020-2022 by Phil M Perry
earlier copyrights held by Simon Cozens

## History

Around 2009, Bram Stein wrote a Javascript implementation of the Knuth-Plass 
paragraph fitting algorithm named `typeset` (not to be confused with the 
language `typescript`, nor the publishing system `Typeset`). It may be found
on GitHub in `bramstein/typeset`, and does not appear to be maintained (last 
update 2017). In 2011, Simon Cozens ported `typeset` to Perl, and called it 
`Text::KnuthPlass`, maintaining it for only a short time. In 2020, Phil Perry 
took over maintenance of this package.

There are a number of known bugs in Text::KnuthPlass, and the first priority
is to study post-2011 changes to `typeset` and see if they resolve the
problems. There is also a refactored (still Javascript) version of 
`typeset`, intended for use as a library, in `frobnitzem/typeset`, which 
should be looked at, as it was maintained through 2017. Finally, there are a 
number of Knuth-Plass implementations in other languages, such as Python 
(`akuchling/texlib`) and typescript (`avery-laird/breaker`) that should be
studied. And of course, there is the original Knuth-Plass paper and the
annotated listing in _TeX: The Program_. It's just a matter of finding the 
time to go through all these sources and fix up `Text::KnuthPlass`, and then 
extend it in various ways.

## An Example

Find an example of using Text::KnuthPlass in `examples/KP.pl`. It assumes that
Text::Hyphen and PDF::Builder are installed. You can easily substitute
PDF::API2 and change the PDF::Builder references in the code. You have a choice
of three text selections to format, and can change many settings, such as the
font, font size, indentation amount, leading, line length (in Points), and
whether output is flush right or ragged right. The output file is `KP.pdf`.

