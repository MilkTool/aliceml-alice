%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 2000
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

{ /y /x x x mulf y y mulf addf sqrt } /dist

0.2 0.2 0.3 point /black1
0.4 0.4 0.5 point /black2
0.7 0.7 0.5 point /white1
1.0 1.0 0.8 point /white2

%%
%% Surface functions
%%

{ /col2 /col1
  { /v /u /face
    face 0 eqi
    { % rotational: stripes according to angle u
      u 12.0 mulf floor 2 modi 1 eqi { col1 } { col2 } if
    }
    { % flat: rays according to angle from origin to (u, v)
      u 0.5 subf /u v 0.5 subf /v
      u u v dist apply divf /b
      0.0 v lessf { b asin } { 360.0 b asin subf } if 180.0 addf 30.0 divf
      floor 2 modi 1 eqi { col1 } { col2 } if
    }
    if
    0.7 0.3 1.0
  }
} /figureSurface

%%
%% Board
%%

{ /v /u /face
  3 face lessi
  { % top, bottom: checkered
    0 u 8.0 mulf floor v 8.0 mulf floor addi
  }
  { face 2 modi 0 eqi
    { 0 } % front, left: striped black/white
    { 1 } % back, right: striped white/black
    if u 8.0 mulf floor
  } if 2 modi eqi { black1 } { white2 } if
  0.4 0.6 0.5
} cube -0.5 -1.0 -0.5 translate 8.0 0.3 8.0 scale /board

%%
%% Pawns
%%

{ /col2 /col1
  col1 col2 figureSurface apply /surface
  surface sphere 0.0 1.0 0.0 translate
  surface cylinder union
  surface sphere 0.0 2.3 0.0 translate difference
  surface sphere 0.8 uscale 0.0 2.5 0.0 translate union
  0.3 uscale
} /pawn

white1 white2 pawn apply /whitePawn
black1 black2 pawn apply /blackPawn

%%
%% Towers
%%

{ /col2 /col1
  col1 col2 figureSurface apply /surface
  col1 col1 figureSurface apply /surface1
  col2 col2 figureSurface apply /surface2
  % Base
  surface cylinder 1.0 0.75 1.0 scale
  % Wall
  surface cone 0.0 -1.0 0.0 translate 180.0 rotatez 90.0 rotatey
  1.0 7.5 1.0 scale union
  surface cylinder 1.0 2.8 1.0 scale intersect
  % Platform
  surface cylinder 0.0 3.0 0.0 translate union
  % Viewholes
  surface cylinder 0.7 4.0 0.7 scale
  { /rot
    surface1 plane 90.0 rotatex
    surface2 plane -90.0 rotatex 30.0 rotatey intersect rot rotatey
  } /apex
  15.0 apex apply 75.0 apex apply union 135.0 apex apply union
  195.0 apex apply union 255.0 apex apply union 315.0 apex apply union
  surface cylinder intersect union
  0.0 3.5 0.0 translate difference
  0.4 uscale
} /tower

white1 white2 tower apply /whiteTower
black1 black2 tower apply /blackTower

%%
%% Bishops
%%

{ /col2 /col1
  col1 col2 figureSurface apply /surface
  % Base
  surface cylinder 1.0 0.75 1.0 scale
  % Body
  surface cone 180.0 rotatez 30.0 rotatey 0.0 1.0 0.0 translate
  1.0 7.5 1.0 scale
  surface plane 0.0 3.0 0.0 translate intersect union
  % Head
  surface sphere 0.0 3.05 0.0 translate difference
  surface sphere 0.8 uscale 0.0 3.25 0.0 translate union
  0.4 uscale
} /bishop

white1 white2 bishop apply /whiteBishop
black1 black2 bishop apply /blackBishop

%%
%% Queens
%%

{ /v2 /v1
  v1 getx v2 getx mulf
  v1 gety v2 gety mulf addf
  v1 getz v2 getz mulf addf
} /dotprod

{ /v
  v getx /x x x mulf
  v gety /x x x mulf addf
  v getz /x x x mulf addf
} /len

{ /v2 /v1
  v1 v2 dotprod apply v1 len apply v2 len apply mulf divf acos
} /angle

{ /col2 /col1
  col1 col2 figureSurface apply /surface
  col1 col1 figureSurface apply /surface1
  col2 col2 figureSurface apply /surface2
  % Base
  surface cylinder 1.0 0.75 1.0 scale
  % Body
  surface cone 180.0 rotatez 30.0 rotatey 0.0 1.0 0.0 translate
  1.0 7.5 1.0 scale
  surface plane 0.0 3.0 0.0 translate intersect union
  % Crown
  %1.0 0.5 sqrt subf /x
  %x x 0.0 point /v1
  %30.0 cos x 30.0 sin point /v2
  %v1 v2 angle apply /phi
  38.146 /phi
  surface cylinder 1.0 2.0 1.0 scale
  surface1 plane -90.0 phi subf rotatex
  surface2 plane 90.0 phi addf rotatex intersect
  -45.0 rotatez 1.0 0.0 0.0 translate /wedge
  wedge wedge 60.0 rotatey union wedge 120.0 rotatey union
  wedge 180.0 rotatey union wedge 240.0 rotatey union wedge 300.0 rotatey union
  0.0 1.0 0.0 translate difference
  0.6 0.25 0.6 scale 0.0 4.2 0.0 translate union
  % Head
  surface sphere 0.0 3.3 0.0 translate difference
  surface sphere 0.8 uscale 0.0 3.5 0.0 translate union
  0.4 uscale
} /queen

white1 white2 queen apply /whiteQueen
black1 black2 queen apply /blackQueen

%%
%% The scene
%%

%board
%whiteTower -0.5 0.0 -3.5 translate union
%blackTower 0.5 0.0 0.5 translate union
%whitePawn 2.5 0.0 -1.5 translate union
%blackPawn 1.5 0.0 -2.5 translate union
%30.0 rotatey -20.0 rotatex 0.4 uscale 0.3 0.0 3.0 translate

%whiteTower -70.0 rotatex 0.0 0.0 4.0 translate

board
whitePawn -3.5 0.0 -2.5 translate union
whitePawn -2.5 0.0 -2.5 translate union
whitePawn -1.5 0.0 -2.5 translate union
whitePawn -0.5 0.0 -2.5 translate union
whitePawn 0.5 0.0 -2.5 translate union
whitePawn 1.5 0.0 -2.5 translate union
whitePawn 2.5 0.0 -2.5 translate union
whitePawn 3.5 0.0 -2.5 translate union
whiteTower -3.5 0.0 -3.5 translate union
whiteTower 3.5 0.0 -3.5 translate union
whiteBishop -1.5 0.0 -3.5 translate union
whiteBishop 1.5 0.0 -3.5 translate union
whiteQueen -0.5 0.0 -3.5 translate union
blackPawn -3.5 0.0 2.5 translate union
blackPawn -2.5 0.0 2.5 translate union
blackPawn -1.5 0.0 2.5 translate union
blackPawn -0.5 0.0 2.5 translate union
blackPawn 0.5 0.0 2.5 translate union
blackPawn 1.5 0.0 2.5 translate union
blackPawn 2.5 0.0 2.5 translate union
blackPawn 3.5 0.0 2.5 translate union
blackTower -3.5 0.0 3.5 translate union
blackTower 3.5 0.0 3.5 translate union
blackBishop -1.5 0.0 3.5 translate union
blackBishop 1.5 0.0 3.5 translate union
blackQueen -0.5 0.0 3.5 translate union
30.0 rotatey -20.0 rotatex 0.4 uscale 0.3 0.0 3.0 translate

/scene

0.0 0.0 -1.0 point
1.0 1.0 1.0 point pointlight /l

0.33 0.33 0.33 point [ l ] scene 3 60.0 1024 768 "chess.ppm" render
