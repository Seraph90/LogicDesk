unit Unit2;


interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls;

const
  LampSize=15;
  ElWidth=10;
  ElHeight=Round(1.5*ElWidth);

type
  TCont = class;

  TPin = class (TImage)
  public
    Link: array[1..20] of TPin;
    PType: Boolean;
    State: Boolean;
    Rec: Boolean;
    PEl: Integer;
    PCont: TCont;
    procedure PinOnClick(Sender: TObject);     //тыкаем на контакт
    constructor Create(AOwner: TComponent; x, y: Integer; FType: Boolean; FEl: Integer; FCont: TCont);
    destructor Destroy;
  end;

  TEl = record
    ElIn: array [1..4] of TPin;
    ElOut: TPin;
  end;

  TCont = class (TImage)
  public
    CType: Byte;
    CEl: array[1..4] of TEl;  //Массив элементов
    CX, CY: Integer;
    Bus: Byte;                //Направления контактов шины
    OnLine: Boolean;
    procedure ContOnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    constructor Create(AOwner: TComponent; x, y: Integer; FType: Byte; Pins: Boolean);
    destructor Destroy;
    procedure Redraw(FClr: Cardinal; Pins:Boolean);
  end;


implementation

uses Unit1;

constructor TPin.Create(AOwner: TComponent; x, y: Integer; FType: Boolean; FEl: Integer; FCont: TCont);
var
  i: Integer;
begin
  inherited Create(AOwner);
  for i:=1 to 20
  do
    Self.Link[i]:=nil;  //очищаем контакты
  State:=False;
  PType:=FType;
  Rec:=False;      //рекурсия
  Parent:=(AOwner as TImage).Parent;
  BringToFront;
  Top:=y-3;
  Left:=x-3;
  Width:=7;
  Height:=7;
  OnClick:=PinOnClick;
  PEl:=FEl;
  PCont:=FCont;
  Canvas.Rectangle(Canvas.ClipRect);
end;

destructor TPin.Destroy;
begin
  inherited Destroy;
end;

procedure TPin.PinOnClick(Sender: TObject);
var
  i, j: Integer;
  b: Boolean;
//  x1, x2, y1, y2: Integer;
begin
  if Self=FstPin
  then
    begin
      Self.Canvas.Brush.Color:=clWhite;
      Self.Canvas.Rectangle(Canvas.ClipRect);
      FstPin:=nil;
      Abort;
    end;
  b:=False;
  for i:=1 to 1+19*Byte(not Self.PType)
  do
    if Self.Link[i]<>nil
    then
      begin
        b:=True;
        Break;
      end;
  if (b) and (Self.PType or (not Self.PType and (FstPin=nil)))
  then
    begin
      if Self.PType
      then
        begin
          if MessageDlg('Удалить связь?', mtConfirmation, [mbYes, mbNo], 0)=mrYes
          then
            begin
              Self.Canvas.Brush.Color:=clWhite;
              Self.Canvas.Rectangle(Canvas.ClipRect);
              Self.Link[1].Canvas.Brush.Color:=clWhite;
              Self.Link[1].Canvas.Rectangle(Canvas.ClipRect);
              for i:=1 to 20
              do
                begin
                  if (Self.Link[1].Link[i]=Self)
                  then
                    begin
                      Self.Link[1].Link[i]:=nil;
                      for j:=1 to 20
                      do
                        if Self.Link[1].Link[j]<>nil
                        then
                          begin
                            Self.Link[1].Canvas.Brush.Color:=clRed;
                            Self.Link[1].Canvas.Rectangle(Canvas.ClipRect);
                          end;
                      Self.Link[1]:=nil;
                      Break;
                    end;
                end;
            end;
        end
      else
        begin
          if MessageDlg('Удалить все связи?', mtConfirmation, [mbYes, mbNo], 0)=mrYes
          then
            begin
              Self.Canvas.Brush.Color:=clWhite;
              Self.Canvas.Rectangle(Canvas.ClipRect);
              for i:=1 to 20
              do
                if Self.Link[i]<>nil
                then
                  begin
                    Self.Link[i].Canvas.Brush.Color:=clWhite;
                    Self.Link[i].Canvas.Rectangle(Canvas.ClipRect);
                    Self.Link[i].Link[1]:=nil;
                    Self.Link[i]:=nil;
                  end;
            end;
        end;
      Form1.RedrawWire;
      Exit;
      Abort;
    end;
  if FstPin=nil
  then
    begin
      Canvas.Brush.Color:=clLime;
      Canvas.Rectangle(Canvas.ClipRect);
      FstPin:=Self;
    end
  else
    if (Self.PType<>FstPin.PType) and not((Self.PEl=FstPin.PEl) and (Self.PCont=FstPin.PCont))
    then
      begin
        FstPin.Canvas.Brush.Color:=clRed;
        FstPin.Canvas.Rectangle(Canvas.ClipRect);
        Self.Canvas.Brush.Color:=clRed;
        Self.Canvas.Rectangle(Canvas.ClipRect);
        for i:=1 to 20
        do
          if Self.Link[i]=nil
          then
            begin
              FstPin.Link[1]:=Self;
              Self.Link[i]:=FstPin;
              FstPin:=nil;
              Break;
            end
      end;
  Form1.RedrawWire;
end;

procedure TCont.ContOnMouseUp(Sender: TObject; Button: TMouseButton;    //на контейнер либо удаляем, либо лампочки зажигаем
  Shift: TShiftState; X, Y: Integer);
begin
  if ((Owner as TImage)<>Form1.I_Table) or (CType=1)
  then
    Abort;
  if (ssShift in Shift) and (FstPin=nil)
  then
    begin
      if MessageDlg('Delete?', mtConfirmation, [mbYes, mbNo], 0)=mrYes
      then
        Self.Destroy;
      Abort;
    end
  else
    if CType=2
    then
      begin
        if y<50
        then
          CEl[1].ElOut.State:=not CEl[1].ElOut.State
        else
          CEl[2].ElOut.State:=not CEl[2].ElOut.State;
      end;
  Redraw(clWhite, False);
  Form1.Redraw;
  Form1.RedrawWire;
end;

constructor TCont.Create(AOwner: TComponent; x, y: Integer; FType: Byte; Pins: Boolean);    //создание контейнера
begin
  inherited Create(AOwner);
  if Pins
  then
    begin
      Canvas.FillRect(Canvas.ClipRect);
      Transparent:=True;
    end;
  CType:=FType;
  CX:=x;
  CY:=y;
  OnLine:=False;
  Parent:=(AOwner as TImage).Parent;
  BringToFront;
  Top:=y*100+(AOwner as TImage).Top;
  Left:=x*100+(AOwner as TImage).Left;
  Width:=100;
  Height:=100;
  Redraw(clWhite, Pins);
  OnMouseUp:=ContOnMouseUp;
end;

destructor TCont.Destroy;    //убивание контейнера
var
  i, j, k: Integer;
begin
  for i:=1 to 4
  do
    begin
      for j:=1 to 4
      do
        if CEl[i].ElIn[j]<>nil
        then
          begin
            if CEl[i].ElIn[j].Link[1]<>nil
            then
              begin
                CEl[i].ElIn[j].Link[1].Canvas.Brush.Color:=clWhite;
                CEl[i].ElIn[j].Link[1].Canvas.Rectangle(CEl[i].ElIn[j].Link[1].Canvas.ClipRect);
                for k:=1 to 20
                do
                  if CEl[i].ElIn[j].Link[1].Link[k]=CEl[i].ElIn[j]
                  then
                    begin
                      CEl[i].ElIn[j].Link[1].Link[k]:=nil;
                      CEl[i].ElIn[j].Link[1]:=nil;
                      Break;
                    end;
              end;
            CEl[i].ElIn[j].Destroy;
          end;
      if CEl[i].ElOut<>nil
      then
        begin
          for k:=1 to 20
          do
            begin
              if CEl[i].ElOut.Link[k]<>nil
              then
                begin
                  CEl[i].ElOut.Link[k].Canvas.Brush.Color:=clWhite;
                  CEl[i].ElOut.Link[k].Canvas.Rectangle(CEl[i].ElOut.Link[k].Canvas.ClipRect);
                  CEl[i].ElOut.Link[k].Link[1]:=nil;
                  CEl[i].ElOut.Link[k]:=nil;
                end;
            end;
          CEl[i].ElOut.Destroy;
        end;
    end;
  Field[CX+1, CY+1]:=nil;
  Form1.RedrawWire;
  inherited Destroy;
end;

procedure TCont.Redraw(FClr: Cardinal; Pins:Boolean);   //рисовалка контейнера
var
  i, j: Integer;
begin
  with Canvas
  do
    begin
      Brush.Color:=FClr;
      if OnLine
      then
        Pen.Color:=clBlue
      else
        Pen.Color:=RGB(200, 0, 0);
      Rectangle(5,5,95,95);
      case CType
      of
        1:begin
            Rectangle(10, 10, 80, 35);
            Rectangle(79, 15, 85, 30);
            Rectangle(10, 37, 80, 62);
            Rectangle(79, 42, 85, 57);
            Rectangle(10, 64, 80, 89);
            Rectangle(79, 69, 85, 84);
            Bus:=1;
          end;
        2:begin
            for i:=0 to 1
            do
              begin
                if Pins
                then
                  begin
                    CEl[i+1].ElOut:=TPin.Create(Self, Left+30+2*LampSize, Top+30+i*40, False, i+1, Self);
                    //CEl[i+1].ElCont:=@Self;
                  end;
                Ellipse(30-LampSize, 30+i*40-LampSize, 30+LampSize, 30+i*40+LampSize);
                if (CEl[i+1].ElOut<>nil) and (CEl[i+1].ElOut.State) and OnLine
                then
                  Brush.Color:=clLime
                else
                  Brush.Color:=clGreen;
                Ellipse(30-LampSize+5, 30+i*40-LampSize+5, 30+LampSize-5, 30+i*40+LampSize-5);
                MoveTo(30+LampSize, 30+i*40);
                LineTo(30+2*LampSize, 30+i*40);
                Brush.Color:=FClr;
              end;
            Bus:=11;
          end;
        3:begin
            for i:=0 to 1
            do
              begin
                if Pins
                then
                  begin
                    CEl[i+1].ElIn[1]:=TPin.Create(Self, Left+70-2*LampSize, Top+30+i*40, True, i+1, Self);
                    //CEl[i+1].ElCont:=@Self;
                  end;
                Ellipse(70+LampSize, 30+i*40-LampSize, 70-LampSize, 30+i*40+LampSize);
                if (CEl[i+1].ElIn[1]<>nil) and (CEl[i+1].ElIn[1].State) and Self.OnLine
                then
                  Brush.Color:=clLime
                else
                  Brush.Color:=clGreen;
                Ellipse(70+LampSize-5, 30+i*40-LampSize+5, 70-LampSize+5, 30+i*40+LampSize-5);
                MoveTo(70-LampSize, 30+i*40);
                LineTo(70-2*LampSize, 30+i*40);
                Brush.Color:=FClr;
              end;
            Bus:=4;
          end;
        4:begin
            for i:=0 to 1
            do
              for j:=0 to 1
              do
                begin
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+15+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+30+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+20, (j*40)+15, (i*40)+20+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25, (j*40)+20, '&');
                  MoveTo((i*40)+20, (j*40)+15+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+15+(ElHeight div 2));
                  MoveTo((i*40)+20, (j*40)+30+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+30+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth, (j*40)+15+ElHeight);
                  Ellipse((i*40)+20+2*ElWidth-3, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        6:begin
            for i:=0 to 1
            do
              for j:=0 to 1
              do
                begin
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+15+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+30+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+20, (j*40)+15, (i*40)+20+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25, (j*40)+20, '=1');
                  MoveTo((i*40)+20, (j*40)+15+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+15+(ElHeight div 2));
                  MoveTo((i*40)+20, (j*40)+30+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+30+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth, (j*40)+15+ElHeight);
                  Ellipse((i*40)+20+2*ElWidth-3, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        {>
        5:begin
            for j:=0 to 1
            do
              //for j:=0 to 1
              //do
                begin
                i:=0;
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+12+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+19+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[3]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+26+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[4]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+33+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth+20, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+40, (j*40)+15, (i*40)+40+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25+20, (j*40)+20, '&');
                  MoveTo((i*40)+20+20, (j*40)+12+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+12+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+19+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+19+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+26+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+26+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+33+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+33+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth+20, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth+20, (j*40)+15+ElHeight);
                  Ellipse((i*40)+20+2*ElWidth-3+20, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2+20, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        {<}
        5:begin
            for i:=0 to 1
            do
              for j:=0 to 1
              do
                begin
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+15+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+30+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+20, (j*40)+15, (i*40)+20+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25, (j*40)+20, '1');
                  MoveTo((i*40)+20, (j*40)+15+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+15+(ElHeight div 2));
                  MoveTo((i*40)+20, (j*40)+30+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+30+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth, (j*40)+15+ElHeight);
                  Ellipse((i*40)+20+2*ElWidth-3, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        7:begin
            for i:=0 to 1
            do
              for j:=0 to 1
              do
                begin
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+15+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15, Top+(j*40)+30+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+20, (j*40)+15, (i*40)+20+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25, (j*40)+20, '=1');
                  MoveTo((i*40)+20, (j*40)+15+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+15+(ElHeight div 2));
                  MoveTo((i*40)+20, (j*40)+30+(ElHeight div 2));
                  LineTo((i*40)+15, (j*40)+30+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth, (j*40)+15+ElHeight);
                  //Ellipse((i*40)+20+2*ElWidth-3, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        {>
        7:begin
            for j:=0 to 1
            do
              //for j:=0 to 1
              //do
                begin
                i:=0;
                if Pins
                then
                  begin
                    CEl[(i*2)+1+j].ElIn[1]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+12+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[2]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+19+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[3]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+26+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElIn[4]:=TPin.Create(Self, Left+(i*40)+15+20, Top+(j*40)+33+(ElHeight div 2), True, (i*2)+1+j, Self);
                    CEl[(i*2)+1+j].ElOut:=TPin.Create(Self, Left+(i*40)+25+2*ElWidth+20, Top+(j*40)+15+ElHeight, False, (i*2)+1+j, Self);
                    //CEl[(i*2)+1+j].ElCont:=@Self;
                  end;
                  Rectangle((i*40)+40, (j*40)+15, (i*40)+40+2*ElWidth, (j*40)+15+2*ElHeight);
                  TextOut((i*40)+25+20, (j*40)+20, '1');
                  MoveTo((i*40)+20+20, (j*40)+12+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+12+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+19+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+19+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+26+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+26+(ElHeight div 2));
                  MoveTo((i*40)+20+20, (j*40)+33+(ElHeight div 2));
                  LineTo((i*40)+15+20, (j*40)+33+(ElHeight div 2));
                  MoveTo((i*40)+20+2*ElWidth+20, (j*40)+15+ElHeight);
                  LineTo((i*40)+25+2*ElWidth+20, (j*40)+15+ElHeight);
                  Ellipse((i*40)+20+2*ElWidth-3+20, (j*40)+15+ElHeight-2, (i*40)+20+2*ElWidth+2+20, (j*40)+15+ElHeight+3);
                end;
            Bus:=6;
          end;
        {<}
        8:begin
            Rectangle(5, 5, 31, 31);
            Rectangle(69, 5, 95, 31);
            Rectangle(5, 69, 31, 95);
            Rectangle(69, 69, 95, 95);
            Bus:=15;
          end;
      end;
      if (Bus and 8)>0
      then
        Rectangle(30, 0, 70, 6);
      if (Bus and 4)>0
      then
        Rectangle(0, 30, 6, 70);
      if (Bus and 2)>0
      then
        Rectangle(94, 30, 100, 70);
      if (Bus and 1)>0
      then
        Rectangle(30, 94, 70, 100);
    end;
end;

end.
