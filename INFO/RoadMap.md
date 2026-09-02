# Text::KnuthPlass Road Map

This module splits a paragraph-long string into a series of lines, creating a
pleasing "well-shaped" paragraph. It uses the Knuth-Plass algorithm made famous
in (La)TeX, and is usable by a wide range of calling systems.

_We can offer no guarantees that any of these items listed will be addressed,
nor in what order. We will be happy to discuss offers of Pull Requests to
implement specific items._

Keep in mind that the output from this package will be used by a variety of
libraries, such as (but not limited to) PDF::Builder and PDF::API2. Also, it is
possible to use it for both proportional width and fixed width fonts, permitting
its use for "flat" text files.

1. We need to coordinate with changes to bramstein/typeset package on GitHub,
particularly to `src/linebreak.js`. Right now, I'm not sure how much the Perl
code (in Text::KnuthPlass) has been updated since 2011! I have a full
line-by-line compare to do, as there were substantial updates in June, 2026.
I believe that only `src/linebreak.js` needs to be watched for updates.
2. Bug: With text output, if line is already as tight as possible (one space
between each word), a hyphen added at end will spill over past the margin.
3. Deal with various forms of hyphens and dashes in the original text, to not
get a - after them if break is made right after that character. Not sure if
this is something in Text::KnuthPlass or better handled in the caller.

    * ASCII hyphen U+002D  should always be an acceptable break point
    * soft hyphen U+00AD  should always be an acceptable break point
    * narrow hyphen U+2010 (preferred over ASCII hyphen, but need to check if
      it's in the particular font in use). should always be an acceptable
      break point
    * non-breaking hyphen U+2011 (like U+2010, but forbid break here)
    * figdash U+2012
    * en-dash U+2013
    * em-dash U+2014   currently appears to NOT break here
    * quotation-dash (horizontal bar) U+2015

4. The CD-ROM in Unicode reference book has line-breaking info, when you should
and should NOT break within a line (especially before/after certain characters),
also at http://unicode.org/reports/tr14/tr14-12.html. This is important
information for those working with other than European languages.
PDF::Builder::UniWrap may be useful in determining can/can't/may split points,
although it appears to be possibly quite out of date.
East and Southeast Asian language line splitting is complicated, while Western
languages usually can split on spaces and hyphens/dashes. Note that simple
_word_ splitting libraries may not currently properly handle Dutch and German,
where letters may be repeated or changed at a split.
5. Are Non-breaking spaces handled correctly? NBSP, ZWNBSP, WJ,CGJ prohibit a
break immediately before or after, while ZWSP permits a break, as does x20.
Needs testing, if nothing else. Knuth-Plass 1982 paper discusses such things
extensively. See also Unicode TR 14.
6. It is frowned upon to split a paragraph (due to end of page or column) with
a line with a hyphen. Need to know where a paragraph is split between columns
and place a very high penalty for hyphenating the line. While we're at it, we
need also to avoid creating widows and orphans. Either some sort of column
_outline_ can be given, or a count of lines available in this column. Note that
baseline spacing (leading) can vary as fonts and font sizes change.
7. Make the added (new) "hyphen" configurable. For PDF, it is often preferable
to output a "soft hyphen" (U+00AD) rather than a "hard hyphen" (U+002D). Any
further processing of the PDF (such as a reflow, or a screen reader), can
thus know that the word was split and can be recombined (use caution with
Dutch and German!). Perhaps even make U+00AD the default, and require an
explicit parameter setting to use U+002D '-'.
8. Figure out what to do when mixing bidirectional text (e.g., Arabic) with
LTR text (e.g., English) and a word needs to be split for a line to fit.
Presumably you don't want a hyphenated word right in the middle of a line.
9. Input text not to be only flat text, but also marked up in some manner, as
bold or italic text may have different width from regular, as well as font
family changes and font size changes. The language used for a segment should
be changeable so that the correct word-splitting library can be used for it.
The markup needs to be preserved in some manner so that (once the paragraph's
individual lines have been decided upon) the calling program can proceed to
pick the appropriate font file. This may require a new API.
10. Find and document any other hidden or hard-coded settings (make
configurable). The 1982 KP article has some suggestions.
11. A general means is needed to set parameters, such as

    * slight differences between ragged-right and flush justified
    * ragged-left (flush right), centered
    * RTL equivalents for ragged-right, ragged-left
    * need an indent amount (global) and then per-paragraph override of indent
      amount and number of lines, such as to accommodate dropped caps. Also to
      suppress indent after a heading
    * where to allow splits around hard-coded hyphens and dashes (some styles
      permit break _before_ the dash)
    * manual setting of discretionary/auxiliary spaces (try hard to suppress
      line break, but not absolutely forbid) such as (TeX-style) with Dr.&Smith
    * adjust handling of glue (space) after punctuation
    * allow punctuation "hanging over" past the right margin (or left margin for
      RTL languages?)

12. Test "center" style and implement left (ragged right) and right aligned.
13. A more general means of describing a column than an array of line lengths
(define the outline of the paragraph built with a simple path of lines, arcs,
and splines, or just accept a polyline). Report back the position within unused
column space (to avoid an
orphan), or the leftover text that didn't fit within the column. If it appears
that just one line is left to go (a widow), rerun, adjusting the leading, to
squeeze in that line. If only room for one line (orphan), rerun, adjusting the
leading. Watch out when changing leading (over entire page?) that it doesn't
create new widows and orphans, or heal one (leaving an empty line). Also watch
out for interaction with images, floats, inserts, etc. when changing leading,
but if the column outline is in fixed coordinates (already allowing for floats)
hopefully there will be no collisions. A list of lines (with font information)
would be returned, along with information of x and y coordinates where they
would be printed. KP itself never puts ink on paper.
14. A more general means of embedding KP "commands" in the text, to override
current settings. Besides discretionary/auxiliary spaces, these could include
suggested break points in words (like &SHY;, to be removed before any SHY's are
added for displayable output), mandatory break points, forbidden
break points, etc.
15. Decide how to handle the use of a library such as HarfBuzz to handle complex
scripts, as well as kerning, ligatures, and Small/Petite Caps in Western
languages. As part of the markup, forbid/suggest ligatures. Ligatures usually
change the width little enough that they won't affect a breakpoint, but the
change in word length still needs to be accounted for in glue length. Post
processing needed by output routines to know which letters were replaced (by
HarfBuzz) ligatures, and what the new word lengths are. HSadvancewidth() presumably
knows what to do with kerning, and may know what ligatures it will be using.
Needs plenty of testing!
16. As part of a new hyphenation library (a separate library) that allows
switching among several languages and proper handling of Dutch and German rules,
deal with emergency situations where the library has no idea how to split a
"word". This could include on camelCase, letters/numbers, internal punctuation,
etc., as well as a "Hail Mary" option if a word won't even fit on the available
line. If a line becomes far too loose due to an unsplittable "word" (such as a
URL or a hash value), it would be time to do a Hail Mary, but you don't want to
do this in the initial split-up of words (camelCase, etc. OK). Should explicitly
call hyphenator just for oversized words, and when line too loose. Re punctuation,
split after various hyphens (including - and SHYs), before # or % (so hex values 
aren't separated), etc.
17. Other improvements suggested for Knuth-Plass. detect and penalize:

    * "cubs" (probably better to flag a last line less than 25% of available
      line, than just a single word)
    * "stacks" of the same word or fragment at the beginning or end of two
      consecutive lines
    * "rivers" (a major headache to implement)
    * multiple hyphenated lines in a row (increase the hyphenation
      penalty/demerit with each one; reverse at each unhyphenated line until
      back to default amount)
    * hyphenated penultimate line (not sure this is really needed)
    * if ragged right or left, don't let a complete word overhang space on the
      line below
    * handle bidirectional and mixed text

18. Rather than outputting separate boxes and glue, allow output of an entire
line (unless interrupted by some sort of markup) at a time, with information
on what to do for more/less word spacing and any change to character spacing
(for tracking).
19. Set "solid" with 'solid'=>1 (default 0). One punctuation mark (not a letter,
accented letter, digit, or any kind of space) at split point gets length of 0,
with actual length transferred to the glue following it. Result is "hanging"
punctuation over the right margin, which some styles like. Possibly offer on
left margin too. Want only one punctuation mark over the margin.
20. Consider "optical alignment" to allow slight overhang left and right of some
letters and other characters. This will vary by font, so it requires some low-level
interfacing with font support.
21. How to handle swashes and alternate glyphs for letter(s)? Need for KP to know
width of replacement letter before it does any line splitting. Some sort of markup
(in addition to style, weight, etc.) to let KP know what the glyph is to be.
