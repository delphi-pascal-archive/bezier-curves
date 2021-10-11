{ Demo unit : Bezier curves and smothing algorithm
  Jean-Yves Queinec :    j.y.q@wanadoo.fr

  Keywords : Bezier curves
             Smoothing algorithm with smooth factor
             square to circle transformation
             coloured flowers }
unit UB1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    UpDown1: TUpDown;
    Edit1: TEdit;
    Label1: TLabel;
    UpDown2: TUpDown;
    Edit2: TEdit;
    Label2: TLabel;
    Button2: TButton;
    Button3: TButton;
    Image1: TImage;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Panel2: TPanel;
    RadioGroup1: TRadioGroup;
    Panel3: TPanel;
    PaintBox1: TPaintBox;
    Panelcolo: TPanel;
    Panel4: TPanel;
    PaintBox2: TPaintBox;
    CheckBox3: TCheckBox;
    SpeedButton1: TSpeedButton;
    Panel5: TPanel;
    Memo1: TMemo;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure FormCreate(Sender: TObject);
    procedure UpDown2Click(Sender: TObject; Button: TUDBtnType);
    procedure FormDestroy(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckBox2Click(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RadioGroup1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure PaintBox2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox2Paint(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    Bmpfond : Tbitmap;              { background bitmap with grid pattern  }

    Figure : integer;               { kingd of shape }
    cx, cy : integer;               { image centre }
    NB1 : longint;                  { Nunber of points }
    AA : array[0..64] of Tpoint;    { points  }
    NB2 : longint;                  { number of points used for Bezier curve  }
    BB : array[0..64*3] of Tpoint;  { points for Bezier curve}
    { polygon drawing }
    Anglepoly : single;             { angle regular polygon }
    Angles : array[0..64*3] of single; { memorize original angles }
    drawing : boolean;
    Startp : integer;      { current BB point (clic select) }
    Startangle : single;   { starting angle for current point }
    Startx : integer;
    Starty : integer;
    infoang  : array[0..2] of single;   { to draw a polygon }
    { colors }
    couleur : array[0..127] of Tcolor;

  public
    Procedure Affichage(lisser : boolean);
    procedure Dessin;
    procedure Quadrillage;
    procedure lissage(acoef: integer);
    procedure polygone;
    procedure sinusoide;
    procedure Lescouleurs;
    procedure setpipette(pstyle : boolean);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}
const
  crpipette = 2;


{---- The Form ---}
procedure TForm1.FormCreate(Sender: TObject);
begin
  Screen.Cursors[crPipette] := LoadCursor(HInstance, 'PCURSEUR');
  drawing := false;
  lescouleurs;
  quadrillage;
  figure := 0;
  affichage(true);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Bmpfond.free;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  close;
end;

{---- Utility Fonctions ----------}
Function Egalpoints(pt1, pt2 : tpoint): boolean;
begin
  IF (pt1.x = pt2.x) AND (pt1.y = Pt2.y) then result := true
  else result := false;
end;

Function arctangente(ax, ay : integer) : single;
var
  symetrie : boolean;
  wx, wy : single;
begin
  if ax < 0 then symetrie := true else symetrie := false;
  wx :=  abs(ax);
  wy := -ay;
  IF wx < 0.001 then  { avoid zero divide }
  begin
    if wy < 0 then result := pi+pi/2 else result := pi/2;
  end
  else
  begin
    result := arctan(wy / wx);
    IF symetrie then result := pi - result;
  end;
end;

procedure Tform1.quadrillage;   // bmpfond grid pattern
var
  i : integer;
begin
  Bmpfond := tbitmap.create;
  Bmpfond.width   := image1.width;
  Bmpfond.height  := image1.height;
  with Bmpfond.canvas do
  begin
    brush.color := clwhite;
    fillrect(rect(0,0,Image1.width, Image1.height));
    cx := Image1.width div 2;
    cy := Image1.height div 2;
    for i := 1 to Image1.width div 10 do
    begin
      if i mod 5 = 0 then pen.color := $00B0E0FF else pen.color := $00F0F4FF;
      moveto(cx+i*5, 0); lineto(cx+i*5, Image1.height);
      moveto(cx-i*5, 0); lineto(cx-i*5, Image1.height);
    end;
    for i := 1 to Image1.height div 10 do
    begin
      if i mod 5 = 0 then pen.color := $00B0E0FF else pen.color := $00F0F4FF;
      moveto(0,cy+i*5); lineto(Image1.width,cy+i*5);
      moveto(0,cy-i*5); lineto(Image1.width,cy-i*5);
    end;
    pen.color:= $0080B0D0;
    moveto(0,cy); lineto(Image1.width,cy);
    moveto(cx,0); lineto(cx, Image1.height);
  end;
end;

{ Smoothing algorithm
  computes Bezier control points
  acoef is the smoothing factor
  Takes care of points 0 and NB2 when they are at the same
  location(closed curve) }
procedure TForm1.lissage(acoef: integer);
var
  i, j : integer;

  Function sym(a, b : integer): integer;  // symmmetry  b / a
  begin
    result := a - ((b-a)*acoef) div 100;
  end;
  Function mil(a, b : integer): integer;  // middle
  begin
    result := (a+b) div 2;
  end;

  // computes a control point position based on
  // symmetries of 2 adjacents points BB n-1 et BBn+1.
  Function ctrlpt(pt, pt1, pt2 : tpoint): tpoint;
  begin
    result.x := mil(mil(pt.x, pt1.x), mil(sym(pt.x, pt2.x), pt.x));
    result.y := mil(mil(pt.y, pt1.y), mil(sym(pt.y, pt2.y), pt.y));
  end;

begin
  // Computes control points
  For j := 1 to NB1-1 do  // points of the cource (edges) excluding end points
  begin
    i := j*3;        // range of point in the  BB array
    BB[i-1] := ctrlpt(BB[i], BB[i-3], BB[i+3]); // prior control point
    BB[i+1] := ctrlpt(BB[i], BB[i+3], BB[i-3]); // next control point
  end;
  IF egalpoints(BB[0], BB[NB2]) then
  begin   // closed curve
    BB[0+1]   := ctrlpt(BB[0], BB[3], BB[NB2-3]);
    BB[NB2-1] := ctrlpt(BB[NB2], BB[NB2-3], BB[3]);
  end
  else
  begin   // open curve
    BB[1]     := BB[0];    // "right" control point from 0
    BB[NB2-1] := BB[NB2];  // "lef" control point from NB2
  end;
end;

procedure TForm1.Affichage(lisser : boolean);
var
 i : integer;
begin
  Image1.canvas.draw(0,0,bmpfond);
  case figure of
    0 : polygone;
    1 : sinusoide;
  end;
  IF lisser then
  begin
    // copy the AA array points to BB array
    NB2 := NB1*3;
    for i := 0 to NB1 do
    begin
       BB[i*3] := AA[i]; // interval is 3 points
    end;
    lissage(Updown1.position);
    // memorize angular positions in order to keep good precision
    // during successive points displacements
    IF figure = 0 then for i := 0 to NB2 do
    begin
      Angles[i] := arctangente(BB[i].x-cx, BB[i].y-cy);
      if i < 3 then infoang[i] := Angles[i]; // memorize angles
    end;
  end;
  IF checkbox1.checked then
  begin
    with image1.canvas do
    begin
      pen.color := clsilver;
      polyline(slice(AA,NB1+1));
      pen.color := clblack;
    end;
  end;
  dessin;
end;

// Regular Polygon from number of points NB1
procedure Tform1.Polygone;
var
  i : integer;
  a1, b : single; // angle and radius
  cx, cy : integer;  // centre
begin
  cx := image1.width div 2;
  cy := image1.height div 2;
  b  := 200.0;          // radius
  NB1 := updown2.position;       // polygone is closed
  IF NB1 < 2 then exit;
  anglepoly := 2*pi / NB1;       // angle increment
  a1 := pi / 2;                  // starting angle
  For i := 0 to NB1-1 do
  begin
    AA[i].x := cx + round(b*cos(a1));
    AA[i].y := cy - round(b*sin(a1)); // y inversed
    a1 := a1+anglepoly;
  end;
  AA[NB1] := AA[0];    // close polygon
end;

procedure Tform1.Sinusoide;  // aligned points and sine curve
var
  i : integer;
  a0, a, b : integer;
  r : integer;
begin
  NB1 := Updown2.position;
  a := (Image1.width - 24) div NB1;
  a0 := cx - a*(NB1 div 2);
  b := Image1.height*3 div 8;
  for i := 0 to NB1 do
  begin
    AA[i].x := a0+a*i;
    r := i mod 4;
    case r of
    0 : AA[i].y := cy;
    1 : AA[i].y := cy-b;
    2 : AA[i].y := cy;
    3 : AA[i].y := cy+b;
    end;
  end;
  IF nb1 mod 2 = 1 then nb1 := nb1 - 1;  // even nunber of points
end;

procedure Tform1.Dessin;   // draws Bezier curve and points
var
  i : integer;
  {-----}
  procedure unecroix(ax, ay : integer; acolor : tcolor);
  begin
    with image1.canvas do
    begin
      pen.color := acolor;
      moveto(ax-1, ay); lineto (ax+2, ay);
      moveto(ax, ay-1); lineto(ax, ay+2);
    end;
  end;
  {-----}
begin
  with image1.canvas do
  begin
    pen.color := cllime;
    if drawing and ((figure = 1) OR (Checkbox1.checked = false)) then
    begin
      case startp mod 3 of
      0 : begin
            if startp < NB2 then
            begin
              moveto(BB[startp].x, BB[startp].y);
              lineto(BB[startp+1].x, BB[startp+1].y);
            end;
            if startp > 0 then
            begin
              moveto(BB[startp-1].x, BB[startp-1].y);
              lineto(BB[startp].x, BB[startp].y);
            end;
          end;
      1 : begin
            moveto(BB[startp-1].x, BB[startp-1].y);
            lineto(BB[startp].x, BB[startp].y);
          end;
      2 : begin
            moveto(BB[startp].x, BB[startp].y);
            lineto(BB[startp+1].x, BB[startp+1].y);
          end;
      end; // case
    end;
    // courbe de Bézier
    pen.color := clblack;
    Windows.polybezier(image1.canvas.handle, BB, NB2+1);
    // points
    If checkbox2.Checked then
    begin
      For i := 0 to NB2 do
      begin
        case i mod 3 of
        0 : begin
             pen.color := clblack;
             ellipse(BB[i].x-2, BB[i].y-2, BB[i].x+2, BB[i].y+2);
            end;
        1 : unecroix(BB[i].x, BB[i].y, clblue);
        2 : unecroix(BB[i].x, BB[i].y, clred);
        end;
      end;
    end
    else pixels[0,0] := pixels[0,0];
    { force paintbox to repaint because an API function using the canvas
      handle of a timage component doesn't do that }
  end;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i : integer;
  a, ro, rox, roy : single;
  colox, coloy : integer;

begin
  // colour drawing
  IF speedbutton1.down then
  begin
    with image1.canvas do
    begin
      IF Button = MbRight then Panelcolo.color := pixels[x, y]
      else
      begin
        brush.color := Panelcolo.color;
        // symmetrical processing
        IF checkbox3.checked then
        begin
          IF figure = 0 then
          begin
            rox := x-cx;
            roy := y-cy;
            ro := sqrt(sqr(rox) + sqr(roy));
            a := arctangente(x-cx, y-cy);
            for i := 0 to Nb1 do
            begin
              colox := Cx + round(ro*cos(a));
              coloy := Cy - round(ro*sin(a));
              if Nb1 mod 2 = 0 then
              begin
                if i mod 2 = 0 then floodfill(colox, coloy, clblack, fsBorder);
              end
              else floodfill(colox, coloy, clblack, fsBorder);
              a := a + anglepoly;
            end;
          end
          else
          begin
            floodfill(x, y, clblack, fsBorder);
            floodfill(cx*2-x, y, clblack, fsborder);
          end;
        end
        else  floodfill(x,y, clblack, fsBorder);
        brush.color := clwhite;
      end;
    end;
    exit;
  end;

  For i := 0 to Nb2 do
  begin
    IF (x > BB[i].x-4) AND (x < BB[i].x+4) AND  // clic on a point ?
       (y > BB[i].y-4) AND (y < BB[i].y+4) then
    begin
      startp := i;
      startx := BB[startp].x;
      starty := BB[startp].y;
      startangle := arctangente(startx-cx, starty -cy);
      drawing := true;
      Image1.Canvas.draw(0,0, bmpfond);
      image1.canvas.pen.mode := pmnotxor;
      dessin;    // uses notxor drawing . Polybezier doesn't do that
      break;
    end;
  end;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  i : integer;
  m : integer;
  rox, roy, ro : single;
  a0, a : single;
begin
  IF NOT drawing then exit;
  dessin;       //  notxor erase
  IF checkbox1.checked then
  begin
    Case figure of
    0: begin
        a0 := arctangente(x-cx, y-cy) - startangle;
        rox := x-cx;
        roy := y-cy;
        ro := sqrt(sqr(rox) + sqr(roy));  // same radius for all points
        m := startp mod 3;    // edge point or conrol point
        For i := 0 to NB2 do
        begin
          if i mod 3 = m  then
          begin
             a := angles[i] + a0 ;  // angle variation
             BB[i].x := Cx + round(ro*cos(a));
             BB[i].y := Cy - round(ro*sin(a));
          end;
        end;
        Case radiogroup1.itemindex of
        1 : if m = 0 then    // link points 0 et 1 ('right' point)
            for i := 0 to NB1 - 1 do BB[i*3+1] := BB[i*3];
        2 : if m = 0 then    // lier points 0 et 2 ('left' point)
            for i := 1 to NB1 do BB[i*3-1] := BB[i*3];
        3 : begin            // link control points
              if m = 1 then for i := 0 to NB1 - 1 do BB[i*3+2] := BB[i*3+1]
              else
              if m = 2 then for i := 0 to NB1 - 1 do BB[i*3+1] := BB[i*3+2];
            end;
        4 : begin   //  opposite control points
              if m = 1 then for i := 0 to NB1 - 1 do
              begin
                BB[i*3+2].x := Cx+Cx - BB[i*3+1].x;
                BB[i*3+2].y := Cy+cy - BB[i*3+1].y;
              end
              else
              if m = 2 then for i := 0 to NB1 - 1 do
              begin
                BB[i*3+1].x := Cx+Cx - BB[i*3+2].x;
                BB[i*3+1].y := Cy+cy - BB[i*3+2].y;
              end;
            end;
        5 : For i := 0 to NB2 do  // rotation
            begin
              if i mod 3 <> m  then
              begin
                a := angles[i] + a0 ;
                rox := BB[i].x - cx;
                roy := BB[i].y - cy;
                ro := sqrt(sqr(rox) + sqr(roy));
                BB[i].x := Cx + round(ro*cos(a));
                BB[i].y := Cy - round(ro*sin(a));
              end;
             end;
        end; // case  radiogroup1
       end;
    1: begin
        BB[startp].x := x;   // move the point and symmetrical / y axis
        BB[startp].y := y;
        // symmetrical point from vertical axix (cy)
        i := nb2 - startp;
        if startp = i then BB[i].x := cx else BB[i].x := cx*2-x;
        BB[i].y := y;
       end;
    end; //  case
  end   // if checkbox
  else
  begin   // no symmetry
    BB[startp].x := x;
    BB[startp].y := y;
  end;
  dessin;   // notxor
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i : integer;
begin
  IF not drawing then exit;
  image1.canvas.pen.mode := pmcopy;
  drawing := false;
  affichage(false);
  IF figure = 0 then
  begin      // update angles
    For i := 0 to Nb2 do Angles[i] := arctangente(BB[i].x-cx, BB[i].y-cy);
    {
    // display angles and radius for information purpose
    With image1.canvas do
    begin
      textout(8,0,'Total number of points = '+inttostr(NB1+1));
      For i := 0 to 2 do
      begin
        a := (angles[i] - infoang[i])* 180 / pi ; // delta angle in degrees
        while a < 0   do  a := a + 360;           // range 0..360
        while a >= 360 do  a := a - 360;
        rox := BB[i].x-cx;
        roy := BB[i].y-cy;
        ro := sqrt(sqr(rox) + sqr(roy));  // rayon
        Case i of
        0 : s := 'Courbe';
        1 : s := 'Bz n°1';
        2 : s := 'Bz n°2';
        end;
        Textout(8, 18*(i+1), s+' a = '+ formatfloat('##0', a)+
            '  ro = '+formatfloat('##0',ro));
      end;
    end;
    }
  end;
end;

//---------  section bouttons and updowns
// polygon
procedure TForm1.Button2Click(Sender: TObject);
begin
  setpipette(false);
  figure := 0;
  updown1.position := 75;
  affichage(true);
end;

// sine
procedure TForm1.Button3Click(Sender: TObject);
begin
  Setpipette(false);
  figure := 1;
  updown1.position := 55;
  affichage(true);
end;

// smooth
procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
  Setpipette(false);
  Image1.Canvas.draw(0,0, bmpfond);
  lissage(updown1.position);
  dessin;
end;

//  points
procedure TForm1.UpDown2Click(Sender: TObject; Button: TUDBtnType);
begin
  Setpipette(false);
  IF figure = 0 then
  begin
    if updown2.position = 4 then updown1.position := 105
    else
    if updown2.position = 5 then updown1.position := 90
    else  updown1.position := 75;
  end;
  IF figure = 1 then updown1.position := 50;
  affichage(true);
end;

// Help
procedure TForm1.Button4Click(Sender: TObject);
begin
  memo1.visible := true;
  button5.visible := true;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  memo1.visible := false;
  button5.visible := false;
end;

procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  Setpipette(false);
  affichage(false);
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  Setpipette(false);
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
   Setpipette(false);
end;


//--------------< section colors >-----------------

procedure Tform1.lescouleurs;
var
  i : integer;
  rr, bb, gg : integer;
  ctr : integer;
Begin
  { creates 128 coulors }
  ctr := 0;
  for i := 0 to 31 do
  begin  {Red To Yellow}
    rr := 255;
    bb := 0;
    gg := (255 * i) div 32;
    couleur[ctr] := rgb(rr, gg, bb);
    inc(ctr);
  end;
  for i := 0 to 23 do
  begin
    { Yellow To Green}
    gg := 255;
    bb := 0;
    rr := 255 - (128*i) div 24;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;
  For i := 0 to 23  do
  begin
    { Green To Cyan}
    rr := 0;
    gg := 255;
    bb := 127+(128 * i) div 24;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;
  For i := 0 to 15 do
  begin
    { Cyan To Blue}
    rr := 0;
    bb := 255;
    gg := 255 - (128 * i) div 16;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;
  For i := 0 TO 31 do
  begin
    { Blue To Magenta}
    gg := 0;
    bb := 255 - (64*i) div 32;
    rr := 127 + (128*i) div 32;
    couleur[ctr] := rgb(rr,gg, bb);
    inc(ctr);
  end;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
var
  j, i : integer;

  function degrad(a, b : integer) : tcolor;
  var
    c1, c2 : Tcolor;
    k : single;
    R1, R2, G1, G2, B1, B2 : single;
    RN,GN,BN : word;
    mano : longint;
  begin
    C1 := couleur[a];
    IF B = 16 then result := c1
    else begin
      IF B < 16 then
      begin
        C2 := $00FFFFFF;
        k  := 15-b;
        k := K /15;
      end
      else
      begin
        C2 := $00969696;
        k := b-15;
        k := k/15;
      end;
      R1 := trunc(GetRvalue(c1));  { colors R V B from c1 }
      G1 := trunc(GetGvalue(c1));
      B1 := trunc(GetBvalue(c1));
      R2 := trunc(GetRvalue(c2));  { coulors R V B from c2 }
      G2 := trunc(GetGvalue(c2));
      B2 := trunc(GetBvalue(c2));
      RN := $00FF AND round(R1+(R2-R1)*k);
      GN := $00FF AND round(G1+(G2-G1)*k);
      BN := $00FF AND round(B1+(B2-B1)*k);
      Mano := RGB(RN,GN,BN);
      Result := $02000000 OR Mano;
    end
  end;

begin
  For i:= 0 to 127 do // display colors
    For j := 0 to 31 do paintbox1.canvas.pixels[j,i] := degrad(i,j);
end;

procedure TForm1.PaintBox2Paint(Sender: TObject);
var
  i: integer;
  b : byte;
begin
  with paintbox2.canvas do
  begin
    for i := 0 to 127 do
    begin
      b := 128+i;
      pen.color := rgb(b,b,b);
      moveto(0, i); lineto(7,i);
    end;
  end;
end;

procedure Tform1.setpipette(Pstyle : boolean);
begin
  If pstyle = true then
  begin
    Paintbox1.cursor := crpipette;
    Paintbox2.cursor := crpipette;
    Image1.cursor := crpipette;
    Speedbutton1.cursor := crpipette;
    IF speedbutton1.down = false then speedbutton1.down := true;
  end
  else
  begin
    Paintbox1.cursor := crdefault;
    Paintbox2.cursor := crdefault;
    Image1.cursor := crdefault;
    Speedbutton1.cursor := crdefault;
    IF speedbutton1.down = true then speedbutton1.down := false;
  end;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
   IF speedbutton1.down then Setpipette(true) else Setpipette(false);
end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Panelcolo.color := PaintBox1.canvas.pixels[x,y];
  Setpipette(true);
end;

procedure TForm1.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Panel5.color := Paintbox1.canvas.Pixels[x, y];
end;

procedure TForm1.PaintBox2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Panelcolo.color := PaintBox2.canvas.pixels[x,y];
  Setpipette(true);
end;

procedure TForm1.PaintBox2MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Panel5.color := Paintbox2.canvas.Pixels[x, y];
end;

end.
