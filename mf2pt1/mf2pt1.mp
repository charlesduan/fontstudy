%%%%
%%%% MF2PT1.MP, by Scott Pakin, pakin@uiuc.edu
%%%%
%%%% This file is used to dump a special version of MetaPost with:
%%%%     inimpost '\input mf2pt1; dump'
%%%%
%%%% To pretty-print this file, you'll need LaTeX and the mftinc package
%%%% (available from CTAN).
%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% mf2pt1                                                               %%%%
%%%% Copyright (C) 2001 Scott Pakin                                       %%%%
%%%%                                                                      %%%%
%%%% This program may be distributed and/or modified under the conditions %%%%
%%%% of the LaTeX Project Public License, either version 1.2 of this      %%%%
%%%% license or (at your option) any later version.                       %%%%
%%%%                                                                      %%%%
%%%% The latest version of this license is in:                            %%%%
%%%%                                                                      %%%%
%%%%    http://www.latex-project.org/lppl.txt                             %%%%
%%%%                                                                      %%%%
%%%% and version 1.2 or later is part of all distributions of LaTeX       %%%%
%%%% version 1999/12/01 or later.                                         %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

input mfplain;
input roex;

join_kind := 0;
end_kind := 0;
miter_size := 0pt;

%%% addto makepath makepen
%%% length clockwise counterclockwise
%%% scaled dashed withcolor

%% \begin{explaincode}
%%   Enable a \MF\ file to determine if it's being built with
%%   \texttt{mf2pt1}.
%% \end{explaincode}

newinternal ps_output;
ps_output := 1;


%% \begin{explaincode}
%%   The following was taken right out of \texttt{mfplain.mp}.  The \mfcomment
%    |def| and the |special|s at the end
%%   are the sole additions.  Normally, MetaPost outputs a tight bounding
%%   box around the character in its PostScript output.  The purpose of the
%%   first \mfcomment
%    |special|
%%   is to pass \texttt{mf2pt1} a bounding box that includes the proper
%%   surrounding whitespace.  The purpose of the second special is to
%%   provide \texttt{mf2pt1} with a default PostScript font name.
%% \end{explaincode}

def beginchar(expr c,w_sharp,h_sharp,d_sharp) =
  begingroup
    charcode:=if known c: byte c else: 0 fi;
    charwd:=w_sharp;      charht:=h_sharp;       chardp:=d_sharp;
    w:=charwd*pt; h:=charht*pt; d:=chardp*pt;
    charic:=0; clearxy; clearit; clearpen; scantokens extra_beginchar;

    def to_bp (expr num) = decimal (ceiling (num*bp_per_pixel)) enddef;
    special "% MF2PT1: bbox 0 " & to_bp (-d) & " " & to_bp(w) & " " & to_bp(h);
    special "% MF2PT1: font_size " & decimal designsize;
    special "% MF2PT1: font_slant " & decimal font_slant_;
    for fvar = "font_identifier", "font_coding_scheme", "font_version",
      "font_comment", "font_family", "font_weight", "font_unique_id",
      "font_name":
      if known scantokens (fvar & "_"):
        special "% MF2PT1: " & fvar & " " & scantokens (fvar & "_");
      fi;
    endfor;
    for fvar = "font_underline_position", "font_underline_thickness":
      if known scantokens (fvar & "_"):
        special "% MF2PT1: " & fvar & " " &
          scantokens ("decimal " & fvar & "_");
      fi;
    endfor;
    special "% MF2PT1: font_fixed_pitch " &
            (if font_fixed_pitch_: "1" else: "0" fi);
enddef;


%% \begin{explaincode}
%%   Store the value of \mfcomment
%    |font_slant_|, so we can recall it at each |beginchar|.
%% \end{explaincode}

font_slant_ := 0;

def font_slant expr x =
  font_slant_ := x;
  fontdimen 1: x
enddef;


%% \begin{explaincode}
%%   Define a bunch of PostScript font parameters to be used by
%%   \texttt{mf2pt1.pl}.  Default values are specified in
%%   \texttt{mf2pt1.pl}, not here.
%% \end{explaincode}

forsuffixes fvar = font_version, font_comment, font_family, font_weight,
                   font_name, font_unique_id:
  scantokens ("string " & str fvar & "_;");
  scantokens ("def " & str fvar & " expr x = " & str fvar & "_ := x enddef;");
endfor;

forsuffixes fvar = font_underline_position, font_underline_thickness:
  scantokens ("numeric " & str fvar & "_;");
  scantokens ("def " & str fvar & " expr x = " & str fvar & "_ := x enddef;");
endfor;

boolean font_fixed_pitch_;
font_fixed_pitch_ := false;
def font_fixed_pitch expr x = font_fixed_pitch_ := x enddef;


%% \begin{explaincode}
%%   We'd like to be able to use calligraphic pens.  Normally, MetaPost's
%%   output routine does all the work for us of converting these to filled
%%   PostScript paths.  The only exception occurs for paths drawn using a
%%   pen that was transformed from  \mfcomment
%    |pencircle|.  MetaPost outputs these paths as stroked PostScript
%%   paths.  The following code tricks MetaPost into using a filled path
%%   for  \mfcomment
%    |pencircle| by replacing the primitive |pencircle| pen with a
%%   non-primitive approximation.  Note that we use a 20-gon for our circle
%%   instead of a diamond, so we get better results from  \mfcomment
%    |draw|.
%% \end{explaincode}

pen fakepencircle;
fakepencircle := makepen (for deg=0 step 360/20 until 359:
    (0.5 cosd deg, 0.5 sind deg)--
  endfor cycle);
save pencircle;
pen pencircle;
pencircle := fakepencircle;


%% \begin{explaincode}
%%   Return  \mfcomment
%    |true| if a path is cyclic, |false| otherwise.
%% \end{explaincode}

def is_cyclic expr cpath =
  (point 0 of cpath = point (length cpath) of cpath)
enddef;


%% \begin{explaincode}
%%   Determine the direction of a closed curve.  \mfcomment
%    Returns |true| if the curve is clockwise, |false| if counterclockwise.
%% \end{explaincode}

vardef is_clockwise primary cpath =
  turningnumber cpath <= 0
enddef;


%% \begin{explaincode}
%%   Make a given path run clockwise.  \mfcomment
%    (|counterclockwise| is defined by \texttt{mfplain}.)
%% \end{explaincode}

vardef clockwise primary c =
  (if is_clockwise c: c else: (reverse c) fi)
enddef;


%% \begin{explaincode}
%%   Redefine  \mfcomment
%    |fill| and |unfill| to ensure that filled paths run
%%   counterclockwise and unfilled paths run clockwise, as is required
%%   by PostScript Type~1 fonts.
%% \end{explaincode}

def fill expr c =
  addto currentpicture contour counterclockwise c t_ pc_
enddef;

def unfill expr c =
  addto currentpicture contour clockwise c t_ pc_ withcolor background
enddef;


%% \begin{explaincode}
%%   Convert  \mfcomment
%    |filldraw| and |unfilldraw| to |fill| and |unfill|.
%% \end{explaincode}

tracingtitles := 1;
def clean_path expr p =
  begingroup
  save p_,E_,t_; path p_,E_; boolean t_;
  t_ := false;
  for i_:=0 upto length(p)-1:
    E_:=subpath (i_,i_+1) of p;
    if (point 0 of E_)=(point 1 of E_) : else:
      if t_: p_ := p_ .. controls (postcontrol 0 of E_) and (precontrol 1 of E_)
	    .. if i_ = length(p)-1: cycle else: (point 1 of E_) fi;
      else:
	p_ := E_;
	t_ := true;
      fi
    fi
  endfor
  p_
  endgroup
enddef;

def filldraw expr c =
  begingroup
  save R, P; path P;
    show c;
    show length c;
    show clean_path c;
    message "! Warning: Replacing filldraw with fill and draw.";
    change_weight (clean_path c) (tiny.breadth) R;
    fill R1;
  endgroup
enddef;

def unfilldraw expr c =
  begingroup
    message "! Warning: Replacing unfilldraw with unfill.";
    unfill c
  endgroup
enddef;


%% \begin{explaincode}
%%   Return  \mfcomment
%    |true| if |currentpen| looks like a |pencircle|.
%% \end{explaincode}

def using_pencircle =
  begingroup
    path qpath, circlepath;
    qpath = makepath currentpen;
    numeric circlediv;
    circlepath = makepath pencircle;
    circlediv = xpart (lrcorner circlepath);

    (length qpath = length circlepath) and (pen_rt <> 0) and (pen_top <> 0)
    for pp = 0 upto (length qpath)-1:
      and ((xpart (point pp of qpath) / pen_rt,
            ypart (point pp of qpath) / pen_top) =
           point pp of circlepath / circlediv)
    endfor
  endgroup
enddef;


%% \begin{explaincode}
%%   If the pen looks like a circular pen, draw a nice circle.  Otherwise,
%%   draw the pen as is.
%% \end{explaincode}

def drawdot expr z =
  if using_pencircle:
    begingroup
      path cpath;
      numeric clength;
      cpath = makepath currentpen;
      clength = length cpath;
      fill ((point 0 of cpath)
        ..(point clength/4 of cpath)
        ..(point clength/2 of cpath)
        ..(point 3*clength/4 of cpath)
        ..cycle) shifted z t_
    endgroup
  else:
    addto currentpicture contour makepath currentpen shifted z
    t_ pc_
  fi
enddef;


%% \begin{explaincode}
%%   Do the same as the above, but unfill the current pen.
%% \end{explaincode}

def undrawdot expr z =
  if using_pencircle:
    begingroup
      path cpath;
      numeric clength;
      cpath = makepath currentpen;
      clength = length cpath;
      unfill ((point 0 of cpath)
        ..(point clength/4 of cpath)
        ..(point clength/2 of cpath)
        ..(point 3*clength/4 of cpath)
        ..cycle) shifted z t_
    endgroup
  else:
    unfill makepath currentpen shifted z t_
  fi
enddef;


%% \begin{explaincode}
%%   MetaPost renders \mfcomment
%    |draw| with a filled curve.
%%   Hence, we need to ensure the orientation is correct (i.e.,
%%   counterclockwise).  Unfortunately, we have no way to check for
%%   overlap, and it's fairly common for MetaPost to output
%%   self-overlapping curve outlines, even if the curve itself has no
%%   overlap.
%% \end{explaincode}

def draw expr p =
  addto currentpicture
  if picture p:
    also p
  elseif is_cyclic p:
    doublepath counterclockwise p t_ withpen currentpen
  else:
    if is_clockwise (p--cycle):
      doublepath (reverse p) t_ withpen currentpen
    else:
      doublepath p t_ withpen currentpen
    fi
  fi
  pc_
enddef;

def undraw expr p =
  addto currentpicture
  if picture p:
    also p
  elseif is_cyclic p:
    doublepath clockwise p t_ withpen currentpen
  else:
    if is_clockwise (p--cycle):
      doublepath p t_ withpen currentpen
    else:
      doublepath (reverse p) t_ withpen currentpen
    fi
  fi
  pc_ withcolor background
enddef;
