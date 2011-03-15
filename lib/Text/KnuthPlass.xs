#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define isPenalty(sv) (SvROK(sv) && sv_derived_from(sv, "Text::KnuthPlass::Penalty"))
#define ivHash(hv, key) (IV)SvIV(*hv_fetch((HV*)hv, key, strlen(key), TRUE))
#define nvHash(hv, key) (NV)SvNVx(*hv_fetch((HV*)hv, key, strlen(key), TRUE))
#define debug(x)

typedef SV * Text_KnuthPlass;

void _insert_before(HV* a, SV* activelist, SV* newnode) {
    dSP;
    AV* ary = (AV*)SvRV(activelist);
    I32 found = 0;
    I32 i = 0;
    while (i <= av_len(ary)) {
        SV** x = av_fetch(ary, i, 0);
        if (SvRV(*x) == (SV*)a) { found = 1; break; }
        i++;
    }
    if (found) { 
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs((SV*)ary);
    XPUSHs(sv_2mortal(newSViv(i)));
    XPUSHs(sv_2mortal(newSViv(0)));
    XPUSHs(newnode);
    PUTBACK;
    pp_splice();
    FREETMPS;
    LEAVE;
    }
}

void _drop_node(HV* a, SV* activelist) {
    dSP;
    SV** src;
    AV* ary = (AV*)SvRV(activelist);
    I32 i = 0;
    I32 found = 0;
    while (i <= AvFILLp(ary)) {
        SV** x = AvARRAY(ary) + i;
        if (*x && SvROK(*x) && SvRV(*x) == (SV*)a) {
            found = 1;
            break;
        }
        i++;
    }
    if (found) {
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs((SV*)ary);
            XPUSHs(sv_2mortal(newSViv(i)));
            XPUSHs(sv_2mortal(newSViv(1)));
            PUTBACK;
            pp_splice();
            FREETMPS;
            LEAVE;
            return;
    }


    /*
    src = AvARRAY(ary) + i + 1;
    Move(src,src - 1, AvFILLp(ary) - i + 1, SV*);
    AvFILLp(ary)--;
    */
}

NV _compute_cost(Text_KnuthPlass self, IV start, IV end, SV* a, 
    IV current_line, AV* nodes) {
    IV  infinity   = ivHash(self, "infinity");
    HV* sum = (HV*)SvRV(*hv_fetch((HV*)self, "sum", 3, FALSE));
    HV* totals = (HV*)(SvRV(*hv_fetch((HV*)a, "totals", 6, TRUE)));
    NV width = nvHash(sum, "width") - nvHash(totals,"width");
    AV* linelengths = (AV*)SvRV(*hv_fetch((HV*)self, "linelengths", 11, FALSE));
    I32 ll = av_len(linelengths);
    NV stretch = 0;
    NV shrink = 0;
    NV linelength = SvNV(*av_fetch(linelengths, current_line <= ll ? current_line-1 : ll, 0));

    debug(warn("Computing cost from %i to %i\n", start, end));
    debug(warn("Sum width: %f\n", nvHash(sum, "width")));
    debug(warn("Total width: %f\n", nvHash(totals, "width")));
    if (isPenalty(*av_fetch(nodes, end, 0))) {
        debug(warn("Adding penalty width\n"));
        width += nvHash(SvRV(*av_fetch(nodes,end, 0)),"width");
    }
    debug(warn("Width %f, linelength %f\n", width, linelength));
    if (width < linelength) {
        stretch = nvHash(sum, "stretch") - nvHash(totals, "stretch");
        debug(warn("Stretch %f\n", stretch));
        if (stretch > 0) {
            return (linelength - width) / stretch;
        } else {
            return infinity;
        }
    } else if (width > linelength) {
        debug(warn("Shrink %f\n", shrink));
        shrink = nvHash(sum, "shrink") - nvHash(totals, "shrink");
        if (shrink > 0) { 
            return (linelength - width) / shrink;
        } else {
            return infinity;
        }
    } else { return 0; }
}

HV* _compute_sum(Text_KnuthPlass self, IV index, AV* nodes) {
    HV* result = newHV();
    HV* sum = (HV*)SvRV(*hv_fetch((HV*)self, "sum", 3, FALSE));
    IV  infinity   = ivHash(self, "infinity");
    NV width = nvHash(sum, "width");
    NV stretch = nvHash(sum, "stretch");
    NV shrink = nvHash(sum, "shrink");
    I32 len = av_len(nodes);
    I32 i = index;

    while (i < len) {
        SV* e = *av_fetch(nodes, i, 0);
        if (sv_derived_from(e, "Text::KnuthPlass::Glue")) {
            width   += nvHash(SvRV(e), "width");
            stretch += nvHash(SvRV(e), "stretch");
            shrink  += nvHash(SvRV(e), "shrink");
        } else if (sv_derived_from(e, "Text::KnuthPlass::Box") ||
            (isPenalty(e) && ivHash(SvRV(e), "penalty") == -infinity
               && i > index)) {
               break;
        }
        i++;
    }

    hv_stores(result, "width", newSVnv(width));
    hv_stores(result, "stretch", newSVnv(stretch));
    hv_stores(result, "shrink", newSVnv(shrink));
    return result;
}

MODULE = Text::KnuthPlass		PACKAGE = Text::KnuthPlass		

void
_mainloop(self, node, index, nodes)
    Text_KnuthPlass self
    SV* node
    IV index
    AV* nodes

    CODE:
    SV* activelist = *hv_fetch((HV*)self, "activeNodes", 11, FALSE);
    IV  tolerance  = ivHash(self, "tolerance");
    IV  infinity   = ivHash(self, "infinity");
    SV* demerits_r = *hv_fetch((HV*)self, "demerits", 8, FALSE);
    NV  ratio = 0;
    IV  nodepenalty = 0;
    NV  demerits = 0;
    IV  linedemerits = 0, flaggeddemerits = 0, fitnessdemerits = 0;
    HV* candidates[4];
    NV  badness;
    IV  current_line = 0;
    HV* tmpsum;
    IV  current_class = 0;
    IV  ptr = 0;
    SV* active;

    active = *(av_fetch((AV*)SvRV(activelist), 0, 0));
    if (demerits_r && SvRV(demerits_r)) {
        linedemerits = ivHash(SvRV(demerits_r), "line");
        flaggeddemerits = ivHash(SvRV(demerits_r), "flagged");
        fitnessdemerits = ivHash(SvRV(demerits_r), "fitness");
    } else {
        croak("Demerits hash not properly set!");
    }

    if (isPenalty(node)) {
        nodepenalty = SvIV(*hv_fetch((HV*)SvRV(node), "penalty", 7, TRUE));
    }

    while (active && SvROK(active)) {
        int t;
        candidates[0] = NULL; candidates[1] = NULL; 
        candidates[2] = NULL; candidates[3] = NULL;
        debug(warn("Outer\n"));
        while (active && SvROK(active)) {
            SV** next = av_fetch((AV*)SvRV(activelist), ++ptr, 0);
            IV position = ivHash(SvRV(active), "position");

            debug(warn("Inner %i\n", ptr));

            current_line = 1+ ivHash(SvRV(active), "line");
            ratio = _compute_cost(self, position, index, SvRV(active), current_line, nodes);
            debug(warn("Got a ratio of %f\n", ratio));
            if (ratio < 1 || (isPenalty(node) && nodepenalty == -infinity)) {
                debug(warn("Dropping a node\n"));
                SvREFCNT_inc(active);
                _drop_node((HV*)SvRV(active), activelist);
                sv_2mortal(active);
                ptr--;
            }
            if (-1 <= ratio && ratio <= tolerance) {
                SV* nodeAtPos = *av_fetch(nodes, position, FALSE); 
                badness = 100 * ratio * ratio * ratio;
                debug(warn("Badness is %f\n", badness));
                if (isPenalty(node) && nodepenalty > 0) {
                    demerits = linedemerits + badness + nodepenalty;
                } else if (isPenalty(node) && nodepenalty != -infinity) {
                    demerits = linedemerits + badness - nodepenalty;
                } else {
                    demerits = linedemerits + badness;
                }
                demerits = demerits * demerits;
                if (isPenalty(node) && isPenalty(SvRV(nodeAtPos))) {
                    demerits = demerits + (flaggeddemerits * 
                        ivHash(node, "flagged") * 
                        ivHash(SvRV(nodeAtPos), "flagged"));
                }

                if (ratio < -0.5)       current_class = 0;
                else if (ratio <= 0.5)  current_class = 1;
                else if (ratio <= 1)    current_class = 2;
                else                    current_class = 3;

                if (abs(current_class - ivHash(SvRV(active), "fitnessClass")) > 1) 
                    demerits += fitnessdemerits;

                demerits += nvHash(SvRV(active), "demerits");

                if (!candidates[current_class] ||
                    demerits < ivHash(candidates[current_class], "demerits")) {
                    debug(warn("Setting c %i\n", current_class));
                    if (!candidates[current_class])
                        candidates[current_class] = newHV();
                    hv_stores(candidates[current_class], "active",
                            newRV(SvRV(active))
                    );
                    hv_stores(candidates[current_class], "demerits", newSVnv(demerits));
                    hv_stores(candidates[current_class], "ratio", newSVnv(ratio));
                }
            }
            active = next ? *next : &PL_sv_undef;
            if (!active || !SvROK(active) ||
                ivHash(SvRV(active),"line") >= current_line) 
                break;
        }
        debug(warn("Post inner loop\n"));


        for (t = 0; t <= 3; t++) {
            if (candidates[t]) {
                HV* newnode = newHV();
                SV* newobj;
                SV* cactive = *hv_fetch(candidates[t], "active", 6, FALSE);
                tmpsum = _compute_sum(self, index, nodes);

                hv_stores(newnode, "position", newSViv(index));
                hv_stores(newnode, "fitnessClass", newSViv(t));
                hv_stores(newnode, "totals", newRV_noinc((SV*)tmpsum));
                hv_stores(newnode, "previous", newRV(SvRV(cactive))); 
                hv_stores(newnode, "demerits", newSVnv(nvHash(candidates[t], "demerits")));
                hv_stores(newnode, "ratio", newSVnv(nvHash(candidates[t], "ratio")));
                hv_stores(newnode, "line", newSViv( 1 + ivHash(SvRV(cactive), "line")));
                // Make a new breakpoint
                newobj = newRV_noinc((SV*)newnode);
                newobj = sv_bless(newobj, gv_stashpv("Text::KnuthPlass::Breakpoint",GV_ADD));
                if (active && SvROK(active)) {
                    debug(warn("Before\n"));
                    _insert_before((HV*)SvRV(active), activelist, newobj);
                    ptr++;
                } else {
                    debug(warn("After\n"));
                    av_push((AV*)SvRV(activelist), newobj);
                }
                sv_free((SV*)candidates[t]);
           }
        }
    }
