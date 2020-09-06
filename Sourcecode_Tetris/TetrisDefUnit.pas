unit TetrisDefUnit;

interface

// ---------------------------------------------------------------------

const cMaxSteine         = 6;
      cMaxSteinElement   = 3;
      cMaxSteinRotation  = 3;

      cFeldSpalten       = 10;
      cFeldZeilen        = 19;

      cMaxFeldSpalte     = cFeldSpalten-1;
      cMaxFeldZeile      = cFeldZeilen-1;

      cFrei              = -1;

// Steinelement (Klotz)
type RSteinElement=record
  x,y:Integer;
end;
// Stein in def. Rotation bestehend aus 4 Steinel Ementen
type RSteinRotation=record
  SteinElemente:array[0..cMaxSteinElement] of RSteinElement;
end;
// Stein in allen möglichen Rotationen
type RStein=record
  Rotation:array[0..cMaxSteinRotation] of RSteinRotation;
  Symbol:Integer;
end;

// Spielfeld Definition
Type RZeile=Record
      spalten:Array[0..cMaxFeldSpalte] of Integer;
     end;
Type RSpielfeld=record
      zeilen: Array[0..cMaxFeldZeile] of RZeile;
     end;

// Sonstiges
Type RVisuAktion=(vaPaint,vaErase);

// ---------------------------------------------------------------------

// Init ( für Aufruf bei Programmstart )
procedure TetrisInit;

procedure LoescheFeld;
procedure NeuerStein;
function CheckSteinPos(Stein:RStein; x,y,r:Integer):Boolean;
procedure SetzeStein(Stein:RStein; x,y,r:Integer);
function ZeileVoll(y:Integer):Boolean;
procedure LoescheZeile(y:Integer);

// ---------------------------------------------------------------------

// Liste aller verfügbaren Steine (wird zur Laufzeit generiert wegen hsPacal)
var Steine:Array[0..cMaxSteine] of RStein;

// Spielfeld
var Spielfeld:RSpielfeld;

// aktueller Stein mit Position und Rotation
var aktStein:RStein;
    aktSteinX:Integer;
    aktSteinY:Integer;
    aktSteinR:Integer;

    nextStein:RStein;

    Punkte:Integer;

implementation

// -----------------------------------------------------------------------

procedure SetupSteinRotation(iStein, iRotation:Integer; x1,y1,x2,y2,x3,y3,x4,y4:Integer);  // intern
begin
  Steine[iStein].Rotation[iRotation].SteinElemente[0].x:= x1;
  Steine[iStein].Rotation[iRotation].SteinElemente[0].y:= y1;

  Steine[iStein].Rotation[iRotation].SteinElemente[1].x:= x2;
  Steine[iStein].Rotation[iRotation].SteinElemente[1].y:= y2;

  Steine[iStein].Rotation[iRotation].SteinElemente[2].x:= x3;
  Steine[iStein].Rotation[iRotation].SteinElemente[2].y:= y3;

  Steine[iStein].Rotation[iRotation].SteinElemente[3].x:= x4;
  Steine[iStein].Rotation[iRotation].SteinElemente[3].y:= y4;
end;

// -----------------------------------------------------------------------

Procedure TetrisInit;
begin
  // Steine aufbauen, immer Angefangen bei Ausgangsposition (Name), dann im Uhrzeigersinn rotiert

  // Stein0:I
  Steine[0].Symbol:= 0;
  SetupSteinRotation(0,0,    0,-1,   0, 0,   0,+1,   0,+2 );
  SetupSteinRotation(0,1,   -1, 0,   0, 0,  +1, 0,  +2, 0 );
  SetupSteinRotation(0,2,    0,-1,   0, 0,   0,+1,   0,+2 );
  SetupSteinRotation(0,3,   -1, 0,   0, 0,  +1, 0,  +2, 0 );

  // Stein1:L
  Steine[1].Symbol:= 1;
  SetupSteinRotation(1,0,    0,-1,   0, 0,   0, 1,   1, 1 );
  SetupSteinRotation(1,1,    0, 1,   0, 0,   1, 0,   2, 0 );
  SetupSteinRotation(1,2,   -1,-1,   0,-1,   0, 0,   0, 1 );
  SetupSteinRotation(1,3,   -1, 0,   0, 0,   1, 0,   1,-1 );

  // Stein2:J (invertiertes L)
  Steine[2].Symbol:= 2;
  SetupSteinRotation(2,0,   -1, 1,   0, 1,   0, 0,   0,-1 );
  SetupSteinRotation(2,1,   -1,-1,  -1, 0,   0, 0,   1, 0 );
  SetupSteinRotation(2,2,    1,-1,   0,-1,   0, 0,   0, 1 );
  SetupSteinRotation(2,3,   -1, 0,   0, 0,   1, 0,   1, 1 );

  // Stein3:O (Würfel)
  Steine[3].Symbol:= 3;
  SetupSteinRotation(3,0,    0, 0,   -1, 0,   0,-1,   -1,-1 );
  SetupSteinRotation(3,1,    0, 0,   -1, 0,   0,-1,   -1,-1 );
  SetupSteinRotation(3,2,    0, 0,   -1, 0,   0,-1,   -1,-1 );
  SetupSteinRotation(3,3,    0, 0,   -1, 0,   0,-1,   -1,-1 );

  // Stein4:T
  Steine[4].Symbol:= 4;
  SetupSteinRotation(4,0,   -1, 0,   0, 0,   1, 0,   0, 1 );
  SetupSteinRotation(4,1,    0,-1,   0, 0,   0, 1,   1, 0 );
  SetupSteinRotation(4,2,   -1, 0,   0, 0,   1, 0,   0,-1 );
  SetupSteinRotation(4,3,    0,-1,   0, 0,   0, 1,  -1, 0 );

  // Stein5:Z
  Steine[5].Symbol:= 5;
  SetupSteinRotation(5,0,   -1,-1,   0,-1,   0, 0,   1, 0 );
  SetupSteinRotation(5,1,   -1, 1,  -1, 0,   0, 0,   0,-1 );
  SetupSteinRotation(5,2,   -1,-1,   0,-1,   0, 0,   1, 0 );
  SetupSteinRotation(5,3,   -1, 1,  -1, 0,   0, 0,   0,-1 );

  // Stein6:S
  Steine[6].Symbol:= 6;
  SetupSteinRotation(6,0,   -1, 0,   0, 0,   0,-1,   1,-1 );
  SetupSteinRotation(6,1,   -1,-1,  -1, 0,   0, 0,   0, 1 );
  SetupSteinRotation(6,2,   -1, 0,   0, 0,   0,-1,   1,-1 );
  SetupSteinRotation(6,3,   -1,-1,  -1, 0,   0, 0,   0, 1 );

  // Feld löschen
  LoescheFeld;

  // VariablenPreset
  aktStein  := Steine[Random(cMaxSteine)];
  nextStein := Steine[Random(cMaxSteine)];
  aktSteinX := cFeldSpalten div 2;
  aktSteinY := 0;
  aktSteinR := 0;
  Punkte    := 0;
end;

// -----------------------------------------------------------------------

procedure LoescheFeld;
var x,y:Integer;
begin
 for y:= 0 to cMaxFeldZeile do
 begin
  for x:= 0 to cMaxFeldSpalte do
  begin
   Spielfeld.zeilen[y].spalten[x]:= cFrei;
  end;
 end;
end;

// -----------------------------------------------------------------------

procedure NeuerStein;
begin
  aktStein  := nextStein;
  aktSteinX := cFeldSpalten div 2;
  aktSteinY := 0;
  aktSteinR := Random(cMaxSteinRotation);

  nextStein  := Steine[Random(cMaxSteine)];
end;

// -----------------------------------------------------------------------

function CheckSteinPos(Stein:RStein; x,y,r:Integer):Boolean;
var ie:integer;
begin
  CheckSteinPos:= false;

  for ie:= 0 to cMaxSteinElement do
  begin
   // Prüfe ob alle Elemente in Spielfeld (Ausnahme oben)
   if (x+Stein.Rotation[r].SteinElemente[ie].x < 0) or
      (x+Stein.Rotation[r].SteinElemente[ie].x > cMaxFeldSpalte) or
      (y+Stein.Rotation[r].SteinElemente[ie].y > cMaxFeldZeile) then
   begin
     // Element außerhalb Spielfeld
     exit;
   end
   else
   begin
    // Prüfe ob Elment ein bereits vorhandenes überschneiden würde
    if Spielfeld.zeilen[y+Stein.Rotation[r].SteinElemente[ie].y].spalten[x+Stein.Rotation[r].SteinElemente[ie].x] <> cFrei then
    begin
      // Feld bereits belegt
      exit;
    end;
   end;
  end;

  CheckSteinPos:= true;
end;

// -----------------------------------------------------------------------

procedure SetzeStein(Stein:RStein; x,y,r:Integer);
var ie:Integer;
begin
  for ie:= 0 to cMaxSteinElement do
  begin
    Spielfeld.zeilen[y+Stein.Rotation[r].SteinElemente[ie].y].spalten[x+Stein.Rotation[r].SteinElemente[ie].x]:= Stein.Symbol;
  end;
end;

// -----------------------------------------------------------------------

function ZeileVoll(y:Integer):Boolean;
var x:Integer;
begin
  ZeileVoll:= true;
  for x:= 0 to cMaxFeldSpalte do
   if Spielfeld.zeilen[y].spalten[x] = cFrei then
    ZeileVoll:= false;
end;

// -----------------------------------------------------------------------

procedure LoescheZeile(y:Integer);
var yt,xt:integer;
begin
 for yt:= y downto 0 do
 begin
   if yt > 0 then
   begin
     Spielfeld.zeilen[yt]:= Spielfeld.zeilen[yt-1];
   end
   else
   begin
     for xt:= 0 to cMaxFeldSpalte do
      Spielfeld.zeilen[0].spalten[xt]:= cFrei;
   end;
 end;
end;

// -----------------------------------------------------------------------

end.

