unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,
  Unit2, StdCtrls, Menus;

type
  TForm1 = class(TForm)
    I_Table: TImage;          //правые
    I_El: TImage;             //левые
    procedure FormCreate(Sender: TObject);
    procedure I_TableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RedrawWire;       //прорисовка провода
    procedure Test;             //проверяем шину и вызываем test link
    function TestLink(FPin: TPin): Boolean;    //расчитывает всю логику
    procedure Redraw;           //перерисовка поля
    procedure RedrawEl;         // не испол
    procedure Turn(Sender: TObject);    //выбор элемента слева
  private
  public
  end;

const
  panelCol = 6;

var
  Form1: TForm1;
  //L: Integer;
  Cur: Integer;
  Field: array[0..6, 0..7] of TCont;  //контейнеры на поле
  FstPin: TPin; //1й контакт нажатый

implementation

{$R *.dfm}
{$R WindowsXP.res}

function TForm1.TestLink(FPin: TPin):Boolean;
var
  t: Boolean;
begin
  TestLink:=False;
  if FPin.Link[1]=nil
  then
    case FPin.PCont.CType
    of
      1..3:Exit;
      4..4:begin
             TestLink:=True;
             FPin.State:=True;
           end;
      5..7:begin
             TestLink:=False;
             FPin.State:=False;
           end;
    end
  else
    begin

      if FPin.Link[1].Rec
      then
        begin
          TestLink:=FPin.Link[1].State;
          Exit;
        end
      else
        FPin.Link[1].Rec:=True;

      case FPin.Link[1].PCont.CType
      of
        2:t:=FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ElOut.State;
        4:t:=not(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1]) and TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2]));
        {>
        5:t:=not(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1])
                    and TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2])
                    and TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[3])
                    and TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[4]));
        {<}
        5:t:=not(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1]) or TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2]));
        6:t:=not(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1])
                    xor TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2]));
        7:t:=(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1])
                    xor TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2]));
        {>
        7:t:=not(TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1])
                    or TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2])
                    or TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[3])
                    or TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[4]));
        {<}
      end;
      TestLink:=t;
      FPin.State:=t;
      FPin.Link[1].State:=t;
  {
  if FPin.State
  then
    begin
      FPin.Canvas.Brush.Color:=clLime;
      FPin.Link[1].Canvas.Brush.Color:=clLime;
    end
  else
    begin
      FPin.Canvas.Brush.Color:=clRed;
      FPin.Link[1].Canvas.Brush.Color:=clRed;
    end;
  FPin.Canvas.FillRect(FPin.Canvas.ClipRect);
  FPin.Link[1].Canvas.FillRect(FPin.Canvas.ClipRect);
  }
    end;
end;

procedure TForm1.Test;
var
  i, j, k, ii, jj: Integer;
  ta: array[1..4] of TCont;
begin
  i:=1;
  //FillChar(ta, SizeOf(ta), 0);
  k:=0;
  while i<=6
  do
    begin
      j:=2;
      while j<=7
      do
        begin
          if Field[i, j]<>nil
          then
            begin
              Field[i, j].OnLine:=
                 ((Field[i, j-1]<>nil) and ((Field[i, j].Bus and 8)>0) and ((Field[i, j-1].Bus and 1)>0) and (Field[i, j-1].OnLine))
              or ((Field[i-1, j]<>nil) and ((Field[i, j].Bus and 4)>0) and ((Field[i-1, j].Bus and 2)>0) and (Field[i-1, j].OnLine));
              if (Field[i, j].OnLine) and (Field[i, j].CType=3)
              then
                begin
                  Inc(k);
                  ta[k]:=Field[i, j];
                end;
            end;
          Inc(j);
        end;
      Inc(i);
    end;

  for i:=1 to 6
  do
    for j:=2 to 7
    do
      if Field[i, j]<>nil
      then
        for ii:=1 to 4
        do
        {
          if Field[i, j].CEl[ii]<>nil
          then
        }
            begin
              for jj:=1 to 4
              do
                if Field[i, j].CEl[ii].ElIn[jj]<>nil
                then
                  Field[i, j].CEl[ii].ElIn[jj].Rec:=False;
                if Field[i, j].CEl[ii].ElOut<>nil
                then
                  Field[i, j].CEl[ii].ElOut.Rec:=False;
            end;
  for i:=1 to k
  do
    for j:=1 to 2
    do
      ta[i].CEl[j].ElIn[1].State:=TestLink(ta[i].CEl[j].ElIn[1]);

end;

procedure TForm1.RedrawWire;
var
  i, j, k, z: Integer;
  x1, y1, x2, y2: Integer;
begin
  Redraw;
  {for i:=1 to 6
  do
    for j:=1 to 5
    do
      if Field[i, j]<>nil
      then }
  for i:=1 to 6
  do
    for j:=1 to 7
    do
      if Field[i, j]<>nil
      then
        for k:=1 to 4
        do
          for z:=1 to 4
          do
          if (Field[i, j].CEl[k].ElIn[z]<>nil) and (Field[i, j].CEl[k].ElIn[z].Link[1]<>nil)
          then
            begin
              x1:=Field[i, j].CEl[k].ElIn[z].Left+3-Form1.I_Table.Left;
              y1:=Field[i, j].CEl[k].ElIn[z].Top+3-Form1.I_Table.Top;
              x2:=Field[i, j].CEl[k].ElIn[z].Link[1].Left+3-Form1.I_Table.Left;
              y2:=Field[i, j].CEl[k].ElIn[z].Link[1].Top+3-Form1.I_Table.Top;
              Form1.I_Table.Canvas.MoveTo(x1, y1);
              Form1.I_Table.Canvas.LineTo(x2, y2);
            end;
end;

procedure TForm1.RedrawEl;
var
  i: Integer;
  Clr: Cardinal;
begin
{
  I_El.Canvas.Brush.Color:=clWhite;
  I_El.Canvas.FillRect(I_El.Canvas.ClipRect);
  for i:=1 to 4
  do
    begin
      if Cur=i
      then
        begin
          Clr:=I_El.Canvas.Brush.Color;
          I_El.Canvas.Brush.Color:=clSilver;
        end
      else
        I_El.Canvas.Brush.Color:=clWhite;
    end;
}
end;

procedure TForm1.Redraw;
var
  i, j: Integer;
begin
  I_Table.Canvas.FillRect(I_Table.Canvas.ClipRect);
  Test;
  for i:=1 to 6
  do
    for j:=1 to 7
    do
      begin
        I_Table.Canvas.Rectangle(i*100-95, j*100-95, i*100-5, j*100-5);
        if Field[i, j]<>nil
        then
          Field[i, j].Redraw(clWhite, False);
      end;
end;

procedure TForm1.Turn(Sender: TObject);
var
  i: Integer;
begin
  for i:=1 to 7
  do
    begin
      if Field[0, i]=Sender
      then
        begin
          Field[0, i].Redraw(clSilver, False);
          Cur:=i+1;
          {
          case i
          of
            1, 2:Cur:=i;
            3:  Cur:=5;
            4: Cur:=3;
            5: Cur:=6;
            6: Cur:=7;
          end;
          }
        end
      else
        Field[0, i].Redraw(clWhite, False);
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, j: Integer;
begin
  for i:=1 to 6
  do
    for j:=1 to 7
    do
      Field[i, j]:=nil;

  Field[1, 1]:=TCont.Create(I_Table, 0, 0, 1, True);
  Field[1, 1].OnLine:=True;
  Field[1, 2]:=TCont.Create(I_Table, 0, 1, 2, True);
  Field[1, 2].OnLine:=True;
  Field[2, 2]:=TCont.Create(I_Table, 1, 1, 6, True);
  Field[3, 2]:=TCont.Create(I_Table, 2, 1, 3, True);
  Field[0, 1]:=TCont.Create(I_El, 0, 0, 2, False);
  Field[0, 2]:=TCont.Create(I_El, 0, 1, 3, False);
  Field[0, 3]:=TCont.Create(I_El, 0, 2, 4, False);
  Field[0, 4]:=TCont.Create(I_El, 0, 3, 5, False);
  Field[0, 5]:=TCont.Create(I_El, 0, 4, 6, False);
  Field[0, 6]:=TCont.Create(I_El, 0, 5, 7, False);
  Field[0, 7]:=TCont.Create(I_El, 0, 6, 8, False);
  Field[0, 1].OnClick:=Turn;
  Field[0, 2].OnClick:=Turn;
  Field[0, 3].OnClick:=Turn;
  Field[0, 4].OnClick:=Turn;
  Field[0, 5].OnClick:=Turn;
  Field[0, 6].OnClick:=Turn;
  Field[0, 7].OnClick:=Turn;
  Cur:=0;
  Redraw;
end;

procedure TForm1.I_TableMouseUp(Sender: TObject; Button: TMouseButton;   //прорисовываем справа
  Shift: TShiftState; X, Y: Integer);
var
  tx, ty: Byte;
begin
  tx:=(x div 100)+1;
  ty:=(y div 100)+1;
  if (Field[tx, ty]=nil) and (Cur<>0)
  {
  and (((Field[tx, ty-1]<>nil) and ((Field[tx, ty-1].Bus and 1)>0) and (((Field[0, Cur].Bus and 8)>0))
  or  (((Field[tx-1, ty]<>nil) and ((Field[tx-1, ty].Bus and 2)>0) and (((Field[0, Cur].Bus and 4)>0))))))
  }
  then
    begin
      Field[tx, ty]:=TCont.Create(I_Table, tx-1, ty-1, Cur, True);
      Redraw;
      RedrawWire;
    end;
end;


procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i, j: Integer;
begin
  for i:=1 to 6
  do
    for j:=1 to 7
    do
      if (Field[i, j]<>nil)
      then
        Field[i, j].Destroy;
end;

end.
