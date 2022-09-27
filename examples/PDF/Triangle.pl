#!/usr/bin/Perl
# derived from Synopsis example in KnuthPlass.pm
# REQUIRES PDF::Builder and Text::Hyphen
# TBD: command-line selection of line width, which text to format, perhaps
#        choice of font and font size
#      see Flatland.pl for more items to consider
#      several different "flavors" of triangles: isoceles, right with left
#        vertical, right with right vertical, rights with flipped base,
#        skewed triangle, even rotated triangle!
#      copy and adjust line lengths and positions for circular, etc. examples
#      see Flatland.pl for $ldquo etc. usage for ' and "
use strict;
use warnings;
use utf8;
use PDF::Builder;
use Text::KnuthPlass;
use POSIX qw/ceil/;

# flag to replace fancy punctuation by ASCII characters
my $use_ASCII = 0;
# force use of pure Perl code
my $purePerl = 1; # 0: use XS, 1: use Perl  DOESN'T WORK

my $textChoice = 1;  # see getPara() at bottom, for choices of sample text
my $outfile = 'Triangle';
my $line_dump = 0;  # debug related
my $do_margin_lines = 0; # debug... do not change, N/A

my $font_scale = 1.7; # adjust to fill circle example
my $radius = 200; # radius of filled circle

my $xleft = 50;  # left (and right) margin
my $raggedRight = 0; # 0 = flush right, 1 = ragged right
my $indentAmount = 0; # ems to indent first line of paragraph. - outdents
#                       upper left corner of paragraph MUST BE 0
#my $split_hyphen = '-';  # TBD check if U+2010 narrow hyphen is available
                         # once font is selected
my $split_hyphen = "\x{2010}";

my $pdf = PDF::Builder->new('compress' => 'none');
my @pageDim = $pdf->mediabox();
#my $lineWidth = 400; # Points. get different wrapping effects by varying
my $lineWidth = $pageDim[2]-2*$xleft; # Points, left margin = right margin
my ($page, $grfx, $text, $ytop);

#my $font = $pdf->ttfont("/Windows/Fonts/arial.ttf");
my $font = $pdf->ttfont("/Windows/Fonts/times.ttf");
#my $font = $pdf->corefont("Helvetica-Bold");

my $vmargin = 100; # top and bottom margins, if fill at least one page
my $font_size = 12;
my $leading = 1.125; # leading will be 9/8 of the font size

my $pageTop = $pageDim[3]-$vmargin; # each page starts here...
my $ybot = $vmargin;                # and ends here

# HTML entities (elaborate vs ASCII) handled in getPara()

my ($w, $t, $paragraph, @lines, $indent, $end_y);
my ($x, $y, $vertical_size);

fresh_page();

# create Knuth-Plass object, build line set with it
$t = Text::KnuthPlass->new(
    'measure' => sub { $text->advancewidth(shift) }, 
    'linelengths' => [ $lineWidth ],  # dummy placeholder
    'indent' => 0,
);

# ---------- actual page content
my $widthHyphen = $text->advancewidth($split_hyphen);

# right triangle, straight vertical side at left
my @list_LL = (
	    # too narrow a line seems to cause problems
#	            $lineWidth*0.05, $lineWidth*0.10,
                    $lineWidth*0.15, $lineWidth*0.20,
                    $lineWidth*0.25, $lineWidth*0.30,
                    $lineWidth*0.35, $lineWidth*0.40,
                    $lineWidth*0.45, $lineWidth*0.50,
                    $lineWidth*0.55, $lineWidth*0.60,
                    $lineWidth*0.65, $lineWidth*0.70,
                    $lineWidth*0.75, $lineWidth*0.80,
                    $lineWidth*0.85, $lineWidth*0.90,
                    $lineWidth*0.95, $lineWidth*1.00,
	      );

$paragraph = getPara(1);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('L', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# isoceles triangle, use text_center()
$paragraph = getPara(2);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph, 'linelengths' => \@list_LL);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# right triangle with vertical at right margin, use text_right()
$paragraph = getPara(3);

$t->line_lengths(@list_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('R', @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# filled circle, adjust font_size to fill as much as possible
$paragraph = getPara(1);

# xc,yc at xleft+.5*lineWidth (need minimum 2*radius height available)
if (2*$radius > $lineWidth) { $radius = $lineWidth/2; }
if ($ytop - 2*$radius < $ybot) { fresh_page(); }

$text->font($font, $font_size*$font_scale);
my $baseline_delta = $font_size * $font_scale * $leading;
$text->leading($baseline_delta);

# figure set of line lengths, plus extra full width for overflow
# text is centered at xc.
my ($delta_x, @circle_LL);
for (my $circle_y = $ytop-$baseline_delta; 
	$circle_y > $ytop-2*$radius; 
	$circle_y -= $baseline_delta) {
    $delta_x = sqrt($radius**2 - ($circle_y-$ytop+$radius)**2);
    push @circle_LL, 2*$delta_x;
}
push @circle_LL, $lineWidth*0.8;  # for overflow from circle

$t->line_lengths(@circle_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('C', @lines);

    $ytop = $end_y;

# -------------
fresh_page();
# rectangle with two circular cutouts
$paragraph = getPara(1);

$font_scale = 1.0;
$text->font($font, $font_size*$font_scale);
$baseline_delta = $font_size*$font_scale * $leading;
$text->leading($baseline_delta);
$radius = 5.0 * $baseline_delta;
$xleft = 100;
$lineWidth = $pageDim[2]-2*$xleft;

# figure set of line lengths, plus extra full width for overflow
my (@odd_LL, @odd_start_x, @odd_end_x);
for (my $odd_y = 0; 
	$odd_y <= $baseline_delta*2+$radius; 
	$odd_y += $baseline_delta) {

    if ($odd_y < $radius) {
	# line starts at delta_x
        $delta_x = sqrt($radius**2 - $odd_y**2);
        push @odd_start_x,  $delta_x;
	unshift @odd_end_x, $lineWidth-$delta_x;
    } else {
	# line starts at beginning
        push @odd_start_x, 0;
	unshift @odd_end_x, $lineWidth;
    }
}
	
# line lengths
for (my $row = 0; $row < @odd_start_x; $row++) {
    push @odd_LL, $odd_end_x[$row]-$odd_start_x[$row];
}
push @odd_LL, $lineWidth*0.8;  # for overflow from area

$t->line_lengths(@odd_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('X', \@odd_start_x, @lines);

    $ytop = $end_y;

# skip 2 lines
$ytop -= 2 * $font_size*$leading;

# -------------
# "A Mouse's Tale" layout
# This is only using KP to adjust the second paragraph until it ends in the
#   middle of the page. From there on out (the tail/tale itself) is a centered
#   decreasing amplitude sine wave whih also decreases the font size.
#
# Lewis Carroll's "Alice's Adventures in Wonderland" (1865). most readable
# version from bootless.net/mouse.html, used here. note that font size and
# leading decrease as you go down the page. probably define a sinusoidal wave
# of decreasing amplitude to be the centerline of the text, with linear 
# decreasing width (in points). try a multiplier starting at 1.0 and decreasing
# by 5% at each line, to use on 1) line length, 2) font size, 3) leading. 
# KP may have to be given a fixed font size to work against, so
# possibly it will be a narrow but fixed width column? this brings up the issue
# of KP handling a paragraph of a mix of font sizes and font faces, and how to
# figure the word lengths! possibly a wrapper around KP to know about font face
# and size used (embedded in the text?) and give hints to help with text length.
#
# If this is done with simply a decreasing font size on a constant-width column,
# I'm not sure it's worth doing with KP except as a novelty. KP would only apply
# to the first two regular paragraphs. Maybe part of KP.pl, and put the Pearl
# River text (demo rivers) into triangle.pl? Adjust paragraph width so that
# last "full" line of 2nd paragraph is fully justified, and tale is centered.
# Might not be worth doing in a Text version.
#    like this:--
#       "Fury said to
 
# various HTML entities (so to speak)
# flag to replace by ASCII characters
my $use_ASCII = 0;

my $mdash = "\x{2014}"; # --
my $lsquo = "\x{2018}"; # '
my $rsquo = "\x{2019}"; # '
my $ldquo = "\x{201C}"; # "
my $rdquo = "\x{201D}"; # "
my $sect  = "\x{A7}";   # sect
if ($use_ASCII) {
	$mdash = '--';
	$lsquo = $rsquo = '\'';
	$ldquo = $rdquo = '"';
	$sect  = 'sect';
}

.center 2
                                The Mouse${rsquo}s Tale
                                by Lewis Carroll

.pa with indent 0
    ${ldquo}Mine is a long and a sad tale!${rdquo} said the Mouse, turning to Alice, and sighing.

.pa with indent 0
    ${ldquo}It is a long tail, certainly,${rdquo} said Alice, looking down with wonder at the Mouse${rsquo}s tail; ${ldquo}but why do you call it sad?${rdquo} And she kept on puzzling about it while the Mouse was speaking, so that her idea of the tale was something like this:${mdash}

.sine wave in center, decreasing amplitude and font size
.cover about 540 degrees. some words italic
${ldquo}Fury said to
a mouse, that
he met
in the
house,
${lsquo}Let us
both go
to law:
I will
prosecute
you.${mdash}
Come, I${rsquo}ll
take no
denial;
We must
have a
trial:
For
really
this
morning
I${rsquo}ve
nothing
to do.${rsquo}
Said the
mouse to
the cur,
${lsquo}Such a
trial,
dear sir,
With no
jury or
judge,
would be
wasting
our breath.${rsquo}
${lsquo}I${rsquo}ll be
judge,
I${rsquo}ll be
jury,${rsquo}
Said
cunning
old Fury;
${lsquo}I${rsquo}ll try
the whole
cause,
and
condemn
you
to
death.${rsquo} ${rdquo}
.five short pa follow, if there is room on the page

$paragraph = getPara(1);

$font_scale = 1.0;
$text->font($font, $font_size*$font_scale);
$baseline_delta = $font_size*$font_scale * $leading;
$text->leading($baseline_delta);
$radius = 5.0 * $baseline_delta;
$xleft = 100;
$lineWidth = $pageDim[2]-2*$xleft;

$t->line_lengths(@odd_LL);
@lines = $t->typeset($paragraph);
    dump_lines(@lines) if $line_dump;
    # output @lines to PDF, starting at $xleft, $ytop
    $end_y = write_paragraph('X', \@odd_start_x, @lines);

    $ytop = $end_y;

# ---- do once at very end
$pdf->saveas("$outfile.pdf");

# END

sub getPara {
    my ($choice) = @_;  

    # various HTML entities (so to speak)
    # flag to replace by ASCII characters

    my $mdash = "\x{2014}"; # --
    my $lsquo = "\x{2018}"; # '
    my $rsquo = "\x{2019}"; # '
    my $ldquo = "\x{201C}"; # "
    my $rdquo = "\x{201D}"; # "
    my $sect  = "\x{A7}";   # sect
    if ($use_ASCII) {
	$mdash = '--';
	$lsquo = $rsquo = '\'';
	$ldquo = $rdquo = '"';
	$sect  = 'sect';
    }

    # original text for both used MS Smart Quotes for open and close single
    # quotes. replaced by ASCII single quotes ' so will work anywhere.
    if ($choice == 1) {
      # 1. a paragraph from "The Frog King" (Grimms)
    return 
    "In olden times when wishing still helped one, there lived a king ".
    "whose daughters were all beautiful; and the youngest was so beautiful ".
    "that the sun itself, which has seen so much, was astonished whenever it ".
    "shone in her face. Close by the king${rsquo}s castle lay a great dark ".
    "forest, and under an old lime-tree in the forest was a well, and when ".
    "the day was very warm, the king${rsquo}s child went out into the forest ".
    "and sat down by the side of the cool fountain; and when she was bored ".
    "she took a golden ball, and threw it up on high and caught it; and this ".
    "ball was her favorite plaything.".
    ""; }

    if ($choice == 2) {
      # 2. a paragraph from page 16 of the Knuth-Plass article
    return
    "Some people prefer to have the right edge of their text look ".
    "${lsquo}solid${rsquo}, by setting periods, commas, and other punctuation ".
    "marks (including inserted hyphens) in the right-hand margin. For ".
    "example, this practice is occasionally used in contemporary advertising. ".
    "It is easy to get inserted hyphens into the margin: We simply let the ".
    "width of the corresponding penalty item be zero. And it is almost as ".
    "easy to do the same for periods and other symbols, by putting every such ".
    "character in a box of width zero and adding the actual symbol width to ".
    "the glue that follows. If no break occurs at this glue, the accumulated ".
    "width is the same as before; and if a break does occur, the line will be ".
    "justified as if the period or other symbol were not present.".
    ""; }

    if ($choice == 3) {
      # 3. from a forum post of mine
    return
    "That double-dot you see above some letters${mdash}they${rsquo}re the ".
    "same thing, right? No! Although they look the same, the two are actually ".
    "very different, and not at all interchangeable. An umlaut is used in ".
    "Germanic languages, and merely means that the primary vowel (a, o, or u) ".
    "is followed by an e. It is a shorthand for (initially) handwriting: \xE4 ".
    "is more or less interchangeable with ae (not to be confused with the ".
    "\xE6 ligature), \xF6 is oe (again, not \x{0153}), and \xFC is ue. This, ".
    "of course, changes the pronunciation of the vowel, just as adding an e ".
    "to an English word (at the end) shifts the vowel sound (e.g., mat to ".
    "mate). Some word spellings, especially for proper names, may prefer one ".
    "or the other form (usually _e). Whether to use the umlaut form or the ".
    "two-letter form is usually an arbitrary choice in electronic ".
    "typesetting, unless the chosen font lacks the umlaut form (as well as a ".
    "combining ${ldquo}dieresis${rdquo} character). It is more common in ".
    "English-language cold metal typesetting to lack the umlaut form, and ".
    "require the two-letter form. See also thorn and ${ldquo}ye${rdquo}, ".
    "where the ${ldquo}e${rdquo} was originally written as a superscript to ".
    "the thorn (\xFE).".
    ""; }

}
# --------------------------
sub fresh_page {
    # set up a new page, with no content
    $page = $pdf->page();
    $grfx = $page->gfx();
    $text = $page->text();
    $ytop = $pageTop;
    # default font
    $text->font($font, $font_size);
    $text->leading($font_size * $leading);
   #margin_lines();
    return;
}

# --------------------------
# write_paragraph(@lines)
# if y goes below ybot, start new page and finish paragraph
# does NOTHING to check for widows and orphans!
sub write_paragraph {
    my $align = shift;
    my @offsets;  # extra offsets for custom effects
    if ($align eq 'X') {
        @offsets = @{ shift(@_) };
    }
    my @lines = @_;

    my $x;
    my $y = $ytop;  # current starting y
    # $ybot is checked, too

    print STDERR ">>>>>>>>>>>>>>> start paragraph\n"; # reassure user
    # first line, see if first box is value '' with non-zero width. would be
    # + or - indent amount. if negative indent, xleft+indent better be >= 0
    my $indent = 0;

    my $node1 = $lines[0]->{'nodes'}->[0]; 
    if ($node1->isa("Text::KnuthPlass::Box") && $node1->value() eq '') {
        # we have an indent value (for first line) + or -
        $indent = $node1->width();
        shift @{ $lines[0]->{'nodes'} }; # get rid of indent box
    }

    for my $line (@lines) {
        my $ratio = $line->{'ratio'};
        $x = $xleft; 
	if ($align eq 'X' && @offsets) {
	    $x += shift(@offsets);
	}
        print "========== new line @ $x,$y ==============\n" if $line_dump;
	$x += $indent; # done separately so debug shows valid $x
        $indent = 0; # resets globally, so need to keep setting
	my $x_offset = 0;

        # how much to reduce each glue due to adding hyphen at end
        # According to Knuth-Plass article, some designers prefer to have
        #   punctuation (including the word-splitting hyphen) hang over past the
        #   right margin (as the original code did here). However, other
        #   punctuation did NOT hang over, so that would need some work to 
	#   separate out line-end punctuation and giving the box a zero width.
	
        my $reduceGlue = 0;
        my $useSplitHyphen = 0;
        if ($line->{'nodes'}[-1]->is_penalty()) { 
	    # last word in line is split (hyphenated). node[-2] must be a Box?
	    my $lastChar = '';
            if ($line->{'nodes'}[-2]->isa("Text::KnuthPlass::Box")) {
	        $lastChar = substr($line->{'nodes'}[-2]->value(), -1, 1);
                if ($lastChar eq '-'      || # ASCII hyphen
		    $lastChar eq '\x2010' || # hyphen
		    $lastChar eq '\x2011' || # non-breaking hyphen
	            $lastChar eq '\x2012' || # figure dash
	            $lastChar eq '\x2013' || # en dash
	            $lastChar eq '\x2014' || # em dash
	            $lastChar eq '\x2015' || # quotation dash
	            0) {
		    # fragment already ends with hyphen, so don't add one
		    $useSplitHyphen = 0;
	        } else {
                    # hyphen added to end of fragment, so reduce glue width
		    $useSplitHyphen = 1;
	            my $number_glues = 0;
	            for my $node (@{$line->{'nodes'}}) {
	                if ($node->isa("Text::KnuthPlass::Glue")) { $number_glues++; }
	            }
	            # TBD if no glues in this line, or if reduction amount makes
		    #   glue too close to 0 in width, have to do something else!
	            if ($number_glues) {
	                $reduceGlue = $widthHyphen / $number_glues;
	            }

	        } # whether or not to add a hyphen at end (word IS split)
	    } # examined node needs to be a Box
        } # there IS a penalty on this line

        # one line of output
        # each node is a box (text) or glue (variable-width space)...
	#   ignore penalty
        # output each text and space node in the line
	# TBD: alternative is to assemble blank-separated text, and use
	#   PDF's wordspace() to adjust glue lengths. if doing hanging 
	#   punctuation, would have to adjust value so line overhangs right
	#   by size of punctuation.
	
	# what is the total line length?
	
        my $length = 0;
        for my $node (@{$line->{'nodes'}}) {
            if ($node->isa("Text::KnuthPlass::Box")) {
                $length += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $length +=
                  ($node->width() - $reduceGlue) + $line->{'ratio'} *
	            (($raggedRight)? 1:
                    ($line->{'ratio'} < 0? $node->shrink(): $node->stretch()));
            } elsif ($node->isa("Text::KnuthPlass::Penalty")) {
	        # no action at this time (common at hyphenation points, is
		# of interest if hyphenated word at end of line)
             }
        }
        # add hyphen to text ONLY if fragment didn't already end with some
        # sort of hyphen or dash 
        if ($useSplitHyphen) {
	    $length += $widthHyphen;
        }
        # now have $length, how long line is

	# set starting offset of full string per alignment
	if      ($align eq 'L' || $align eq 'X') {
            $x_offset = 0;
	} elsif ($align eq 'C') {
            $x_offset = ($lineWidth-$length)/2;
	} else { # 'R'
            $x_offset = $lineWidth-$length;
	}

        for my $node (@{$line->{'nodes'}}) {
	    $text->translate($x+$x_offset,$y);
            if ($node->isa("Text::KnuthPlass::Box")) {
                $text->text($node->value());
                $x += $node->width();
            } elsif ($node->isa("Text::KnuthPlass::Glue")) {
                $x += ($node->width() - $reduceGlue) + $line->{'ratio'} *
	        (($raggedRight)? 1:
                    ($line->{'ratio'} < 0? $node->shrink(): $node->stretch()));
            } elsif ($node->isa("Text::KnuthPlass::Penalty")) {
	        # no action at this time (common at hyphenation points, is
	        # of interest if hyphenated word at end of line)
            }
	}
	
        # add hyphen to text ONLY if fragment didn't already end with some
        # sort of hyphen or dash 
        if ($useSplitHyphen) {
	    $text->text($split_hyphen); 
        }
        $y -= $text->leading();  # next line down
	if ($y < $ybot) { 
	    fresh_page();
	    $y = $pageTop;
	}
    } # end of handling a line
    return $y;
} # end of write_paragraph()

# --------------------------
sub margin_lines {

    if (!$do_margin_lines) { return; }

    # draw left and right margin lines
    $grfx->strokecolor("red");
    $grfx->linewidth(0.5);
    $grfx->poly($xleft,$ytop+$font_size, 
	        $xleft,$end_y+$font_size);
    $grfx->poly($xleft+$lineWidth,$ytop+$font_size, 
	        $xleft+$lineWidth,$end_y+$font_size);
    $grfx->stroke();
    # done with this sample
    return;
}

# --------------------------
# dump @lines (diagnostics)
sub dump_lines {
    my @lines = @_;

    foreach (@lines) { 
        # $_ is a hashref
        print "========== new line ==============\n";
        foreach my $key (sort keys %$_) { 
            my $value = $_->{$key};
            if ($key eq 'nodes') {
                print "$key:\n";
                my @content = @{ $value };
                foreach my $item ( @content ) {
	            print "\n" if (ref($item) =~ m/::Box/);
	            print ref($item)."\n";
	            foreach my $subitem ( sort keys %$item ) {
                        print "$subitem = $item->{$subitem}\n";
	                # box value = 'text fragment'
	                #     width = width in Points
	                # glue shrink = factor ~1
	                #      stretch = facctor ~1
	                #      width = width in Points (whitespace)
	                # penalty flagged = 0 or 1
	                #         penalty = value of penalty
	                #         shrink = factor
	                #         width = width in Points
	            }
                }
            } else {
                # not sure what position is (x position at raw end of line?)
                print "$key = $value, ";
            }
        } 
        print "\n";
    }

    return;
} # end of dump_lines()

