//
// Implementierung by YvoPet
// HSPascal 2.1.0 Compiler, PalmOS 3.5 oder höher (Achtung: Compilerswitch in Systemunits)
//
// Es ist für den Cache weder hilfreich noch nötig diesen Code zu lesen,
// ihr werdet die Koordinaten hier nicht finden! (die sind "ausgelagert")
// Die Veröffentlichung des Codes ist nur als Info für alle Technik-Interessierten gedacht.
//
// History
// -------
// 12.07.2014 v1.00 Spiel implementiert, Parameter noch einzustellen
// 12.07.2014 v1.01 Menü geändert
// 07.06.2015 v1.02 Start-/SpielCounter implementiert
//

Program Tetris;


{$SearchPath Units; Units\UI; Units\System}
{$ApplName Tetris,YVOPET}
// YVOPET is a referenced PalmOS CreatorID (http://dev.palmos.com/creatorid/)

Uses
  Window, Form, Menu, Rect, Event, SysEvent, SystemMgr, FloatMgr, HSUtils,
  TimeMgr, Preferences, SystemResources, Crt, Chars, SoundMgr, KeyMgr, SysUtils,
  TextConsts, Util, Eventhandler, Bitmap, BitmapUtil, Logo, UIresources,
  TetrisDefUnit;

// ----------------------------------------------------

// Achtung: Dialog regulär nicht verwenden, ermöglichen das herausspringen aus der Anwendung
//          da dort der normale eventhandler ohne filter greift

{$R Resources.ro}

// ----------------------------------------------------

type RGameMode=(gmEasy,gmNormal,gmHard);
     RGameState=(gsStart,gsRun,gsLoose,gsWon);

// Programm -------

const sVersion = 'v1.02';
      itimer   = 10;   // ms

var WorkRect:    RectangleType;
    wt,wb,wr,wl: Integer;

    GameMode:    RGameMode;
    GameState:   RGameState;

    LastBatteryupdate: UInt32;
    StartCount:        UInt32;
    PlayCount:         UInt32;

// Spiel -----------

const cxOfsSpielfeld = 4;  // pixel
      cyOfsSpielfeld = 4;  // pixel
      ciSteinGr      = 8;  // pixel

      cixPunkte      = 105;
      ciyPunkte      = 10;

      cixNaechster   = 112;
      ciyNaechster   = 70;

      ciBMPMenue     = 1;
      ciBMPSpielfeld = 2;

      ciBMPSteinOfs  = 10;
      ciBMPSteinLeer = 19;

      ciBMPRollo     = 20;

var   timer: UInt32;

// - Hilfsfunktionen ------------------------------------

Function InWorkRect(var Event: EventType): Boolean;
begin
  with Event do
    InWorkRect:= RctPtInRectangle(ScreenX, ScreenY, WorkRect);
end;

Function RandomBool:Boolean;
var t:integer;
begin
  t:= random(100);
  if t > 50 then
   RandomBool:= true
  else
   RandomBool:= false;
end;

// - Visualisierung -------------------------------------

procedure VisuDebugMsg(sDebug:string);
begin
  sDebug:= '"'+sDebug+'"';
  WinDrawChars(sDebug, length(sDebug), 1, 20);
end;

procedure VisuStein(xPixel,yPixel:Integer; r:Integer; Stein:RStein; VisuAktion:RVisuAktion);
var x,y:integer;
    i:integer;
    iresbmp:integer;
begin
  if ( R <  0 ) or
     ( R >  cMaxSteinRotation ) then
     exit;

  if VisuAktion = vaPaint then
   iresbmp:= ciBMPSteinOfs+Stein.Symbol
  else
   iresbmp:= ciBMPSteinLeer;
  for i:= 0 to cMaxSteinElement do
  begin
    x:= xPixel+Stein.Rotation[r].SteinElemente[i].x*ciSteinGr;
    y:= yPixel+Stein.Rotation[r].SteinElemente[i].y*ciSteinGr;
    if y >= cyOfsSpielfeld then
    PaintBmp(iresbmp,x,y);
  end;
end;

procedure VisuPunkte;
var stmp:String;
begin
  if WinSetBackColor(255)>0 then begin end;
  if WinSetTextColor(0)>0 then begin end;

  stmp:= 'Punkte';
  WinDrawChars(stmp, length(stmp), cixPunkte, ciyPunkte);

  stmp:= inttostr(Punkte);
  WinDrawChars(stmp, length(stmp), cixPunkte, ciyPunkte+10);
end;

procedure VisuNaechsterStein;
var Rect: RectangleType;
begin
  RctSetRectangle(Rect,100,55,30,45);
  WinDrawRectangle(Rect, 0);

  VisuStein(cixNaechster, ciyNaechster, 0, nextStein, vaPaint);
end;

procedure VisuSpielFeld;
var x,y:Integer;
    iresbmp:Integer;
begin
  // Spielfeld ist als Grafik hinterlegt
  FullScreenBmp(ciBMPSpielfeld);

  // Feld Inhalt
  for y:= 0 to cMaxFeldZeile do
  begin
   for x:= 0 to cMaxFeldSpalte do
   begin
     iresbmp:= ciBMPSteinLeer;
     if (Spielfeld.zeilen[y].spalten[x] > -1) then
     begin
       iresbmp:= ciBMPSteinOfs+Spielfeld.zeilen[y].spalten[x];
       PaintBMP(iresbmp, cxOfsSpielfeld+X*ciSteinGr, cyOfsSpielfeld+Y*ciSteinGr);
     end;
   end;
  end;

end;

procedure VisuBattery;
var sBatteryInfo:string;
begin
  if WinSetBackColor(255)>0 then begin end;
  if WinSetTextColor(0)>0 then begin end;

  // Update und Visualisierung
  sBatteryInfo:= 'Akku: ' + GetBatteryInfo; // + '/' + inttostr(StartCount) + '/' + inttostr(PlayCount) + ' ';
  WinDrawChars(sBatteryInfo, length(sBatteryinfo), 20, 20);

  if WinSetBackColor(255)>0 then begin end;
  if WinSetTextColor(0)>0 then begin end;
end;

procedure VisuStartScreen;
begin
  if WinSetBackColor(255)>0 then begin end;
  if WinSetTextColor(0)>0 then begin end;

  WinDrawChars(sVersion, length(sVersion), 120, 20);
  VisuBattery;
  //Akkustatus (erste Zeile) automatisch, trotzdem hier gleich anzeigen (programmstart)

  WinDrawChars(sstart, length(sstart), 20, 48);
  WinDrawChars(sanweisung1, length(sanweisung1), 20, 60);
  WinDrawChars(sanweisung2, length(sanweisung2), 20, 72);
  WinDrawChars(sanweisung3, length(sanweisung3), 20, 84);

  WinDrawChars(sSchwierigkeit, length(sSchwierigkeit), 20, 110);

end;

// - Spiel (Start) --------------------------------------

Procedure startgame;
begin
  inc(PlayCount);

  GameState:= gsStart;

  // TetrisDefUnit Initialisieren
  // initialisiert Spielfeld und Spielvariablen
  TetrisInit;

  // Spielfeld anzeigen
  VisuSpielfeld;

  // nächster Stein
  VisuNaechsterStein;

  // Punkte
  VisuPunkte;

  // Spieltimer zurücksetzen
  timer:= 0;

  FlushEvents;
  GameState:= gsRun;
end;

// - Spiel (Laufzeit) -----------------------------------

procedure DoGameEndeLoose;
var i:integer;
begin

     for i:= 1 to cFeldZeilen do
     begin
      PaintBmp(ciBMPRollo, cxOfsSpielfeld, cyOfsSpielfeld+(i-1)*ciSteingr);
      Delay(25);
     end;

     DoSound(600,50);
     DoSound(500,50);
     DoSound(400,50);
     DoSound(300,500);

     WinEraseRectangle(WorkRect, 1);
     PaintBMP(ciBMPMenue, wl, wt);

     if WinSetBackColor(255)>0 then begin end;
     if WinSetTextColor(0)>0 then begin end;

     WinDrawChars(sVersion, length(sVersion), 120, 20);
     //Akkustatus (erste Zeile) automatisch

     WinDrawChars(sloose, length(sloose), 20, 50);
     WinDrawChars(sanweisung1, length(sanweisung1), 20, 70);
     WinDrawChars(sanweisung2, length(sanweisung2), 20, 80);
     WinDrawChars(sanweisung3, length(sanweisung3), 20, 90);

     GameState:= gsLoose;
     exit;
end;

procedure DoGameEndeWon;
begin

     DoSound(600,50);
     DoSound(800,50);
     DoSound(1000,50);
     DoSound(1200,500);

     WinEraseRectangle(WorkRect, 1);
     PaintBMP(ciBMPMenue, wl, wt);

     if WinSetBackColor(255)>0 then begin end;
     if WinSetTextColor(0)>0 then begin end;

     WinDrawChars(sVersion, length(sVersion), 120, 20);
     //Akkustatus (erste Zeile) automatisch

     WinDrawChars(swon1, length(swon1), 20, 40);
     WinDrawChars(swon2, length(swon2), 20, 50);
     WinDrawChars(swon3, length(swon3), 20, 60);

     WinDrawChars(swon4, length(swon4), 20, 80);
     WinDrawChars(swon5, length(swon5), 20, 90);
     WinDrawChars(swon6, length(swon6), 20, 100);

     gamestate:= gsWon;
     exit;

end;

procedure DoGameLogic(key:uInt32);
var bDo:Boolean;
    tmpR:Integer;
    y,c,i:Integer;
    speed:Integer;
begin
  bDo:= false;
  if (key <> 0) then
  begin
    bDo:= true;
  end;
  speed:= 50;
  if gamemode = gmEasy then speed:= 50;
  if gamemode = gmNormal then speed:= 35;
  if gamemode = gmHard then speed:= 20;

  if (timer >= speed) then
  begin
    timer:= 0;
    bDo:= true;
    if CheckSteinPos(aktStein, aktSteinX, aktSteinY+1, aktSteinR) then
    begin
      // Stein fällt automatisch hinab
      key:= ChrPageDown;
    end
    else
    begin
      //übernehmen an aktueller Pos
      SetzeStein(aktStein, aktSteinX, aktSteinY, aktSteinR);

      DoSound(100, 100);

      // Punkte
      inc(Punkte, 10);

      // Prüfe volle Zeilen
      c:= 0;
      for y:= 0 to cMaxFeldZeile do
      begin
        if ZeileVoll(y) then
        begin
          LoescheZeile(y);
          VisuSpielfeld;

          // Punkte
          inc(Punkte, 100);
          inc(c);
        end;
      end;
      if c = 4 then
      begin
        // Punkte
        inc(Punkte, 400);
      end;
      if c > 0 then
      begin
        for i:= 1 to 10 do
        begin
          DoSound(2000, 25);
          DoSound(200, 25);
        end;
      end;

      // Punkte visualisieren
      VisuPunkte;

      // neuen Stein bilden
      //VisuSpielfeld;
      NeuerStein;
      VisuStein(cxOfsSpielfeld+aktSteinX*ciSteinGr, cyOfsSpielfeld+aktSteinY*ciSteinGr, aktSteinR, aktStein, vaPaint);

      // nächsten Stein visualisieren
      VisuNaechsterStein;

      //Prüfe auf Ende (Ausgangsposition+1 nicht möglich)
      if not CheckSteinPos(aktStein, aktSteinX, aktSteinY+1, aktSteinR) then
      begin
        VisuStein(cxOfsSpielfeld+aktSteinX*ciSteinGr, cyOfsSpielfeld+aktSteinY*ciSteinGr, aktSteinR, aktStein, vaPaint);

        Delay(1000);
        DoGameEndeLoose;
        bDo:= false;
      end;

      if Punkte > 1500 then
      begin
        Delay(1000);
        DoGameEndeWon;
        bDo:= false;
      end;

    end;
  end;

  if bDo=true then
  begin
    VisuStein(cxOfsSpielfeld+aktSteinX*ciSteinGr, cyOfsSpielfeld+aktSteinY*ciSteinGr, aktSteinR, aktStein, vaErase);

    // bewegung
    if key = vchrHard1 then
    begin
      // links
      if CheckSteinPos(aktStein, aktSteinX-1, aktSteinY, aktSteinR) then
       dec(aktSteinX);
    end;
    if key = vchrHard2 then
    begin
      // rechts
      if CheckSteinPos(aktStein, aktSteinX+1, aktSteinY, aktSteinR) then
       inc(aktSteinX);
    end;
    if key = chrPageDown then
    begin
      if CheckSteinPos(aktStein, aktSteinX, aktSteinY+1, aktSteinR) then
       inc(aktSteinY);
    end;
    if key = vchrHard3 then
    begin
      tmpR:= aktSteinR;
      dec(tmpR);
      if tmpR<0 then tmpR:= cMaxSteinRotation;
      if CheckSteinPos(aktStein, aktSteinX, aktSteinY, tmpR) then
       aktSteinR:= tmpR;
    end;
    if key = vchrHard4 then
    begin
      tmpR:= aktSteinR;
      inc(tmpR);
      if tmpR>cMaxSteinElement then tmpR:= 0;
      if CheckSteinPos(aktStein, aktSteinX, aktSteinY, tmpR) then
       aktSteinR:= tmpR;
    end;

    VisuStein(cxOfsSpielfeld+aktSteinX*ciSteinGr, cyOfsSpielfeld+aktSteinY*ciSteinGr, aktSteinR, aktStein, vaPaint);

    if (Key = vchrHard1) or
       (Key = vchrHard2) then
    begin
      DoSound(880, 10);
    end;

    if (Key = vchrHard3) or
       (Key = vchrHard4) then
    begin
      DoSound(440, 10);
    end;

  end; // of Key

end;

// ----------------------------------------------------

Function HandleEvent(var Event: EventType; var Key:uInt32): Boolean;
var
  N: Integer;
  OldMenu: Pointer;

  CurX: Integer;
  CurY: Integer;

begin
  HandleEvent:=False;
  Key:= 0;

  with Event do
  Case eType of
  // ----------
  frmLoadEvent:
    begin

      HandleEvent:= true;
    end;
  frmOpenEvent: //Main Form
    begin
      // kein Formular

      HandleEvent:= true;
    end;
  // ----------
  (*
  menuEvent:
    begin;
      Case Data.Menu.ItemID of
      //
      end;
      HandleEvent:= true;
    end;
  *)
  // ----------
  penDownEvent:
    begin
      PenDown:=True;
      if InWorkRect(Event) then begin

        // Buttons
        If (gamestate <> gsRun) and (Event.ScreenY > 100) then
        begin
          case Event.ScreenX of
            0..53:   begin
                      GameMode:= gmEasy;
                      StartGame;
                     end;
           53..106:  begin
                      GameMode:= gmNormal;
                      StartGame;
                     end;
           106..159: begin
                      GameMode:= gmHard;
                      StartGame;
                   end;
          end;
        end;

        HandleEvent:= true;
      end;
    end;
  penUpEvent:
    begin
      if PenDown and InWorkRect(Event) then begin
        //
        HandleEvent:= true;
      end;
    end;
  penMoveEvent:
    if PenDown and InWorkRect(Event) then begin
      //
      HandleEvent:= true;
    end;
  keyDownEvent:
    begin
      //VisuDebugMsg(inttostr(ord(data.keydown.chr)));
      //delay(1000);

      // up/down/hardkeys
      if (data.keydown.chr = chrPageUp) or
         (data.keydown.chr = chrPageDown) or
         (data.keydown.chr = vchrhard1) or
         (data.keydown.chr = vchrhard2) or
         (data.keydown.chr = vchrhard3) or
         (data.keydown.chr = vchrhard4) then
      begin
       HandleEvent:= true;
       key:= data.keydown.chr;
      end;

      lastbatteryupdate:= 0; // löst sofortigen refresh bei taste ein/aus
      // vchrPowerOff kommt bei Tastenbetätigung
      // vchrLateWakeup kommt beim reaktivieren
      // vchrAutoOff kommt beim Timer aus

      if data.keydown.chr = vchrLateWakeup then
      begin
        inc(StartCount);

        DisplayFullScreenIntro(500);

        WinEraseRectangle(WorkRect, 1);
        PaintBMP(ciBMPMenue, wl, wt);

        Visustartscreen;

        gamestate:= gsStart;
        gamemode:=  gmNormal;

        FlushEvents;

        n:= SndPlaySmfResource(s2u32(midiRsc), 1000, prefSysSoundVolume);
        //Visudebugmsg(inttostr(n));
      end;

      if (data.keydown.chr = vchrPowerOff) or
         (data.keydown.chr = vchrAutoOff) then
      begin
        // Achtung: hier nur mit Bedacht Code einfügen, sonst blockiert man ggf. den Standby, fatal!
        DisplayBlack;
      end;

    end;
  // ----------
  ctlSelectEvent: //Control button
    begin
      (*
      case Data.CtlEnter.ControlID of
        MainSButton: begin;
                        GameMode:= gmEasy;
                        StartGame;
                     end;
        MainNButton: begin;
                        GameMode:= gmNormal;
                        StartGame;
                     end;
        MainPButton: begin;
                        GameMode:= gmHard;
                        StartGame;
                     end;
      end;
      HandleEvent:= true;
      *)
    end;
  // ----------
  else
    HandleEvent:=False;
  end;
end;

// ----------------------------------------------------

procedure Main;
Var
  initDelayP, periodP, doubleTapDelayP: UInt16;
  queueAheadP:Boolean;
  ret: err;

  Event:         EventType;
  Error:         UInt16;
  DoStop:        Boolean;
  i:             Integer;
  s:             String;

  key:           uInt32;
begin
  // if sndinit > 0 then exit;
  // SndPlaySystemSound(sndStartUp);

  // Tastenwiederholrate und init delay herab setzen
  initdelayP:= 25;       // Einstellparameter für Tastenreaktion
  periodP:= itimer;
  doubleTapDelayP:= 25;  // Einstellparameter für Tastenreaktion
  queueAheadP:= false;
  ret:= KeyRates(true, initDelayP, periodP, doubleTapDelayP, queueAheadP);

  // init zufallsgenerator
  Randomize;

  // init Variablen
  lastbatteryupdate:= 0;
  StartCount:= 0;
  PlayCount:= 0;

  // workrect init
  RctSetRectangle(WorkRect,0,0,160,160);
  wt:= workrect.topleft.y;
  wb:= workrect.topleft.y+workrect.extent.y;
  wl:= workrect.topleft.x;
  wr:= workrect.topleft.x+workrect.extent.x;

  // StartScreen
  WinEraseRectangle(WorkRect, 1);
  PaintBMP(ciBMPMenue, wl, wt);
  VisuStartScreen;

  // preset hauptstruktur
  LastBatteryupdate:=0;
  gamestate:= gsStart;
  gamemode:= gmNormal;

  // init der Spielvariablen siehe startgame

  DoStop:= false;
  Repeat
    key:= 0;

    // Variablen merken (falls für Programm nötig)

    // Event über eigenen Eventhandler holen,
    // der filtert und führt eigenständig SysHandleEvent() aus
    EventHandlerGetEvent(false, 0, Event);

    if not HandleEvent(Event, Key) then begin
    end;

    if gamestate=gsRun then
    begin
      // wenn immer noch run state
      if gamestate=gsRun then
      begin
        // Spiellogic
        DoGameLogic(key);
      end;

      // kein FlushEvents !
    end;

    if (gamestate <> gsrun) then
    begin
      if abs(TimGetSeconds - lastbatteryupdate) >= 3 then
      begin
       lastBatteryUpdate:= TimGetSeconds;
       VisuBattery;
      end;
    end;


    delay(itimer);
    inc(timer);
  Until DoStop or (Event.eType=appStopEvent);

end;

// ----------------------------------------------------

begin
  Main;
end.
