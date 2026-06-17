unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, StdCtrls,
  ExtCtrls, EpikTimer, BGRABitmap,BGRABitmapTypes, Math, LCLIntf;

type
  Inform = record
    Previous: Float;
    TimePerFrame: Float;
    LinePerFrame: Integer;
    FramePerSec: Float;
    ActualElapsed: Float;
    LineLeftOver: Integer;
    Speed_frame:Extended;
  end;

type
  Average_ = record
    Actual: Float;
    ActualAverage: Float;
    Min, Max: Integer;
    TotalPixelForFindFactor: Integer;
    Factor, PersenOffset: Float;
    Point1, Point2: Integer;
    ActualCounter, CounterLimit: Integer;
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label2: TLabel;
    Label3: TLabel;
    PaintBox2: TPaintBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
    timer_: TEpikTimer;
    Run_:Boolean;
    Background_, bmp, bmp2, BufferBMP: TBGRABitmap;
    Grid_:Tpoint;
    c: TBGRAPixel;
    Trect_:Trect;
    Positioning:integer;
    Actual_, Arithmetic_:Average_;
    GeometricMean_:Average_;
    HarmonicMean:Average_;
    Information:Inform;
    procedure Main_Loop(RunX:Boolean);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Main_Loop(RunX:Boolean);
//Use Case 1 disable case 2; design for running one program only
//Use Case 2 disable case 2; design for Share CUP to other program

//Case 1 at 50F/S Maximum: 21000000 line/Sec;  Minimum: 17000000 Line/Sec;  400000 Line/Frame
//Case 2 at 50F/S Maximum: 700000 line/Sec;  Minimum: 500000 Line/Sec;  13000 Line/Frame

var
  Frame_, Line_:integer;
  i:integer;
begin
  if Not Run_ then
  begin
    Run_:=True;
    Information.Previous:=0;
    Frame_:=0;
    Line_:=0;
    timer_.Clear;
    timer_.Start;

    while Run_ do
    begin
      application.ProcessMessages; //Work one program only   Case 1.

      //Run your program here
      bmp.PutImage(0,0,BufferBMP,dmDrawWithTransparency);

      Trect_.TopLeft.x:=1;
      Trect_.TopLeft.y:=0;
      Trect_.BottomRight.x:=PaintBox2.Width;
      Trect_.BottomRight.y:=PaintBox2.Height;
      bmp.PutImagePart(0,0,bmp,Trect_,dmDrawWithTransparency);

      Positioning:=Positioning+1;
      if Positioning = (bmp2.Width) then Positioning :=0;

      Trect_.TopLeft.x:=Positioning;
      Trect_.TopLeft.y:=0;
      Trect_.BottomRight.x:=Positioning+1;
      Trect_.BottomRight.y:=bmp2.Height;
      bmp.PutImagePart(PaintBox2.Width-1,0,bmp2,Trect_,dmDrawWithTransparency);

      if (Actual_.Point2>0) then Actual_.Point2:=PaintBox2.Height-Actual_.Point2;
      if (Actual_.Point1>0) and (Actual_.Point2>0) then
      begin
        i:=PaintBox2.Width;
        c := ColorToBGRA(rgb(0,5,108));  //ColorToBGRA(rgb(0,105,208));
        bmp.DrawPolyLineAntialias([PointF(i-1,Actual_.Point1), PointF(i,Actual_.Point2)],c,2);
      end;
      Actual_.Point1:=Actual_.Point2;

      if Arithmetic_.ActualCounter>=Arithmetic_.CounterLimit then
      begin
        Arithmetic_.ActualCounter:=0;
        c := ColorToBGRA(rgb(105,0,208));
        bmp.DrawPolyLineAntialias([PointF(PaintBox2.Width-Arithmetic_.CounterLimit,Arithmetic_.Point1), PointF(PaintBox2.Width,Arithmetic_.Point2)],c,2);
        Arithmetic_.Point1:=Arithmetic_.Point2;
      end;

      if GeometricMean_.ActualCounter>=GeometricMean_.CounterLimit then
      begin
        GeometricMean_.ActualCounter:=0;
        c := ColorToBGRA(rgb(5,105,208));
        bmp.DrawPolyLineAntialias([PointF(PaintBox2.Width-GeometricMean_.CounterLimit,GeometricMean_.Point1), PointF(PaintBox2.Width,GeometricMean_.Point2)],c,2);
        GeometricMean_.Point1:=GeometricMean_.Point2;
      end;

      if HarmonicMean.ActualCounter>=HarmonicMean.CounterLimit then
      begin
        HarmonicMean.ActualCounter:=0;
        c := ColorToBGRA(rgb(5,105,8));
        bmp.DrawPolyLineAntialias([PointF(PaintBox2.Width-HarmonicMean.CounterLimit,HarmonicMean.Point1), PointF(PaintBox2.Width,HarmonicMean.Point2)],c,2);
        HarmonicMean.Point1:=HarmonicMean.Point2;
      end;

      Arithmetic_.Actual:= Information.LinePerFrame;
      if (Arithmetic_.Min=0) or (Arithmetic_.Min>Information.LinePerFrame) then Arithmetic_.Min:=Information.LinePerFrame;
      if (Arithmetic_.Max=0) or (Arithmetic_.Max<Information.LinePerFrame) then Arithmetic_.Max:=Information.LinePerFrame;
      if (Arithmetic_.Min>0) and (Arithmetic_.Max>0) and (Arithmetic_.Max-Arithmetic_.Min>0) then Arithmetic_.Factor:=round(((Arithmetic_.Max+(Arithmetic_.Max/100*Arithmetic_.PersenOffset))-Arithmetic_.Min)/Arithmetic_.TotalPixelForFindFactor);
      if (Arithmetic_.Min>0) and (Arithmetic_.Max>0) and (Information.LinePerFrame>0) and (Arithmetic_.Max-Arithmetic_.Min>0) then
      begin
        if Arithmetic_.ActualAverage <=0 then Arithmetic_.ActualAverage:=Arithmetic_.Actual;
        Arithmetic_.ActualAverage:=(Arithmetic_.Actual+Arithmetic_.ActualAverage)/2;
        Arithmetic_.ActualCounter:=Arithmetic_.ActualCounter+1;
        Arithmetic_.Point2:=round((Arithmetic_.ActualAverage-Arithmetic_.Min)/Arithmetic_.Factor);
        Arithmetic_.Point2:=Arithmetic_.TotalPixelForFindFactor-Arithmetic_.Point2;
        if Arithmetic_.Point1=0 then Arithmetic_.Point1:=Arithmetic_.Point2;
      end;

      if (Actual_.Min=0) or (Actual_.Min>Information.LinePerFrame) then Actual_.Min:=Information.LinePerFrame;
      if (Actual_.Max=0) or (Actual_.Max<Information.LinePerFrame) then Actual_.Max:=Information.LinePerFrame;
      if (Actual_.Min>0) and (Actual_.Max>0) and (Actual_.Max-Actual_.Min>0) then i:=round(((Actual_.Max+(Actual_.Max/100*10))-Actual_.Min)/PaintBox2.Height);
      if (Actual_.Min>0) and (Actual_.Max>0) and (Information.LinePerFrame>0) and (Actual_.Max-Actual_.Min>0) then
      begin
        Actual_.Point2:=round((Information.LinePerFrame-Actual_.Min)/i);
      end;

      GeometricMean_.Actual:= Information.LinePerFrame;
      if (GeometricMean_.Min=0) or (GeometricMean_.Min>Information.LinePerFrame) then GeometricMean_.Min:=Information.LinePerFrame;
      if (GeometricMean_.Max=0) or (GeometricMean_.Max<Information.LinePerFrame) then GeometricMean_.Max:=Information.LinePerFrame;
      if (GeometricMean_.Min>0) and (GeometricMean_.Max>0) and (GeometricMean_.Max-GeometricMean_.Min>0) then GeometricMean_.Factor:=round(((GeometricMean_.Max+(GeometricMean_.Max/100*GeometricMean_.PersenOffset))-GeometricMean_.Min)/GeometricMean_.TotalPixelForFindFactor);
      if (GeometricMean_.Min>0) and (GeometricMean_.Max>0) and (Information.LinePerFrame>0) and (GeometricMean_.Max-GeometricMean_.Min>0) then
      begin
        if GeometricMean_.ActualAverage <=0 then GeometricMean_.ActualAverage:=GeometricMean_.Actual;
        GeometricMean_.ActualAverage:=sqrt(GeometricMean_.Actual*GeometricMean_.ActualAverage);
        GeometricMean_.ActualCounter:=GeometricMean_.ActualCounter+1;
        GeometricMean_.Point2:=round((GeometricMean_.ActualAverage-GeometricMean_.Min)/GeometricMean_.Factor);
        GeometricMean_.Point2:=GeometricMean_.TotalPixelForFindFactor-GeometricMean_.Point2;
        if GeometricMean_.Point1=0 then GeometricMean_.Point1:=GeometricMean_.Point2;
      end;

      HarmonicMean.Actual:= Information.LinePerFrame;
      if (HarmonicMean.Min=0) or (HarmonicMean.Min>Information.LinePerFrame) then HarmonicMean.Min:=Information.LinePerFrame;
      if (HarmonicMean.Max=0) or (HarmonicMean.Max<Information.LinePerFrame) then HarmonicMean.Max:=Information.LinePerFrame;
      if (HarmonicMean.Min>0) and (HarmonicMean.Max>0) and (HarmonicMean.Max-HarmonicMean.Min>0) then HarmonicMean.Factor:=round(((HarmonicMean.Max+(HarmonicMean.Max/100*HarmonicMean.PersenOffset))-HarmonicMean.Min)/HarmonicMean.TotalPixelForFindFactor);
      if (HarmonicMean.Min>0) and (HarmonicMean.Max>0) and (Information.LinePerFrame>0) and (HarmonicMean.Max-HarmonicMean.Min>0) then
      begin
        if HarmonicMean.ActualAverage <=0 then HarmonicMean.ActualAverage:=HarmonicMean.Actual;
        HarmonicMean.ActualAverage:=2/((1/HarmonicMean.Actual)+(1/HarmonicMean.ActualAverage));
        HarmonicMean.ActualCounter:=HarmonicMean.ActualCounter+1;
        HarmonicMean.Point2:=round((HarmonicMean.ActualAverage-HarmonicMean.Min)/HarmonicMean.Factor);
        HarmonicMean.Point2:=HarmonicMean.TotalPixelForFindFactor-HarmonicMean.Point2;
        if HarmonicMean.Point1=0 then HarmonicMean.Point1:=HarmonicMean.Point2;
      end;

      BufferBMP.PutImage(0,0,bmp,dmDrawWithTransparency);
      //Any text information here
      c := ColorToBGRA(rgb(0,50,255));
      bmp.FontHeight:=15;
      bmp.TextOut(10,(bmp.FontFullHeight*0)+5,'F/S='+FloatToStr(Information.FramePerSec),c);
      bmp.TextOut(10,(bmp.FontFullHeight*1)+5,'ms/F='+FloatToStr(Information.TimePerFrame),c);
      bmp.TextOut(10,(bmp.FontFullHeight*2)+5,'Time='+FloatToStr(Information.ActualElapsed),c);
      bmp.TextOut(10,(bmp.FontFullHeight*3)+5,'Line/F='+IntToStr(Information.LinePerFrame),c);
      bmp.TextOut(10,(bmp.FontFullHeight*4)+5,'Line left over='+IntToStr(Information.LineLeftOver),c);

      //c := ColorToBGRA(rgb(255,50,0));
      //bmp.TextOut(210,(bmp.FontFullHeight*0)+5,'GeometricMean_.Actual='+FloatToStr(GeometricMean_.Actual),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*1)+5,'GeometricMean_.ActualAverage='+FloatToStr(GeometricMean_.ActualAverage),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*2)+5,'GeometricMean_.Min='+IntToStr(GeometricMean_.Min),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*3)+5,'GeometricMean_.Max='+IntToStr(GeometricMean_.Max),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*4)+5,'GeometricMean_.Factor='+FloatToStr(GeometricMean_.Factor),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*5)+5,'GeometricMean_.PersenOffset='+FloatToStr(GeometricMean_.PersenOffset),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*6)+5,'Point1/Point2='+FloatToStr(GeometricMean_.Point1)+'/'+FloatToStr(GeometricMean_.Point2),c);
      //bmp.TextOut(210,(bmp.FontFullHeight*7)+5,'ActualCounter/CounterLimit='+IntToStr(GeometricMean_.ActualCounter)+'/'+IntToStr(GeometricMean_.CounterLimit),c);

      //Render here
      bmp.Draw(PaintBox2.Canvas,0,0,True);


      //Clear your hardware here

      Information.LinePerFrame:=0;
      while ((timer_.Elapsed -Information.Previous <= Information.Speed_frame) and
             (timer_.Elapsed < 1) and (Run_)) do //and (timer_.Elapsed < 1) do
      begin
        //application.ProcessMessages; //Share CUP  Case 2

        //Detect your hardware here

        Line_:=Line_+1;
        Information.LinePerFrame:=Information.LinePerFrame+1;

        //Run_:=not Run_; //For run only 1 cycle
      end;

      //Other status here

      if timer_.Elapsed >= 1 then Information.TimePerFrame:=(timer_.Elapsed-Information.Previous)*1000;
      Information.Previous:=timer_.Elapsed;
      Frame_:=Frame_+1;
      if timer_.Elapsed >= 1 then
      begin
        Information.ActualElapsed:=timer_.Elapsed*1000;
        timer_.Stop;
        Information.FramePerSec:=Frame_;
        Information.Previous:=0;
        Frame_:=0;
        Information.LineLeftOver:=Line_;
        Line_:=0;
        timer_.Clear;
        timer_.Start;
      end;
    end;

    If not Run_ then  timer_.Stop;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, i2, i3:integer;
begin
  Information.Speed_frame:=0.02;
  timer_ := TEpikTimer.Create(nil);
  Run_:=False;
  Positioning:=0;

  Actual_.ActualAverage:=0;
  Actual_.Point1:=0;
  Actual_.Point2:=0;
  Actual_.Max:=0;
  Actual_.Min:=0;
  Actual_.Actual:=0;
  Actual_.CounterLimit:=5;
  Actual_.TotalPixelForFindFactor:=PaintBox2.Height;
  Actual_.PersenOffset:=10;
  Actual_.Factor:=0;

  Arithmetic_.ActualAverage:=0;
  Arithmetic_.Point1:=0;
  Arithmetic_.Point2:=0;
  Arithmetic_.Max:=0;
  Arithmetic_.Min:=0;
  Arithmetic_.Actual:=0;
  Arithmetic_.CounterLimit:=5;
  Arithmetic_.TotalPixelForFindFactor:=PaintBox2.Height;
  Arithmetic_.PersenOffset:=10;
  Arithmetic_.Factor:=0;

  GeometricMean_.ActualAverage:=0;
  GeometricMean_.Point1:=0;
  GeometricMean_.Point2:=0;
  GeometricMean_.Max:=0;
  GeometricMean_.Min:=0;
  GeometricMean_.Actual:=0;
  GeometricMean_.CounterLimit:=5;
  GeometricMean_.TotalPixelForFindFactor:=PaintBox2.Height;
  GeometricMean_.PersenOffset:=20;
  GeometricMean_.Factor:=0;

  HarmonicMean.ActualAverage:=0;
  HarmonicMean.Point1:=0;
  HarmonicMean.Point2:=0;
  HarmonicMean.Max:=0;
  HarmonicMean.Min:=0;
  HarmonicMean.Actual:=0;
  HarmonicMean.CounterLimit:=5;
  HarmonicMean.TotalPixelForFindFactor:=PaintBox2.Height;
  HarmonicMean.PersenOffset:=30;
  HarmonicMean.Factor:=0;

  Grid_.X:=26;
  Grid_.y:=15;

  if Grid_.X<0 then Grid_.X:=0;
  if Grid_.Y<0 then Grid_.Y:=0;

  Background_ := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00000000));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  BufferBMP := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00000000));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00CCCCCC));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp2 := TBGRABitmap.Create(Round(PaintBox2.Width/(Grid_.X+1))+1,PaintBox2.Height, ColorToBGRA($00CCCCCC));//ColorToBGRA($00CCCCCC)//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))

  Background_.Canvas2D.lineWidth:=1;
  Background_.Canvas2D.strokeStyle ('rgb(55,255,55)');
  Background_.Canvas2D.stroke();

  Background_.JoinStyle := pjsBevel;
  Background_.PenStyle := psSolid;

  c := ColorToBGRA(rgb(30,30,30));
  i2:=Round(PaintBox2.Width/(Grid_.X+1));
  i3:=0;
  for i := 0 to Grid_.X do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(i3,0), PointF(i3,PaintBox2.Height)],c,1);
  end;

  i2:=Round(PaintBox2.Height/(Grid_.Y+1));
  i3:=0;
  for i := 0 to Grid_.Y do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(0,i3), PointF(PaintBox2.Width,i3)],c,1);
  end;

  //bmp.PutImage(0,0,Background_,dmDrawWithTransparency);
  BufferBMP.PutImage(0,0,Background_,dmDrawWithTransparency);

  Trect_.TopLeft.x:=0;
  Trect_.TopLeft.y:=0;
  Trect_.BottomRight.x:=bmp2.Width;
  Trect_.BottomRight.y:=bmp2.Height;
  bmp2.PutImagePart(0,0,Background_,Trect_,dmDrawWithTransparency);
  Positioning:=(PaintBox2.Width mod (Trect_.BottomRight.x-1));
  //c := ColorToBGRA(rgb(250,50,50));
  //bmp2.DrawPolyLineAntialias([PointF(0,0), PointF(0,bmp2.Height)],c,1);

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Label2.Visible:=False;
  Main_Loop(Run_);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Information.Speed_frame:=0.02;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Information.Speed_frame:=0.029;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Label2.Visible:=True;
  Run_:=False;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Run_:=False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  timer_.Free;
  BufferBMP.Free;
  Background_.Free;
  bmp.Free;
  bmp2.Free;
end;


end.

