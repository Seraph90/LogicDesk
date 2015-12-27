unit Unit1;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, ExtCtrls,
	Unit2, StdCtrls, Menus;

type
	TForm1 = class(TForm)

		// Рабочее поле
		I_Table: TImage;

		// Поле выбора
		I_El: TImage;
		procedure FormCreate(Sender: TObject);
		procedure I_TableMouseUp(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);

		// Прорисовка провода
		procedure RedrawWire;

		// Проверка питания и вызов проверки логики
		procedure Test;

		// Расчёт логики
		function TestLink(FPin: TPin): Boolean;

		// Перерисовка поля
		procedure Redraw;

		// Выбор элемента в поле выбора
		procedure Turn(Sender: TObject);
	private
	public
	end;

const
	panelCol = 6;
  elCount = 6;
  batType = 1;
  sendLampType = 3;

var
	Form1: TForm1;
	
	Cur: Integer;

	// Рабочее поле
	Field: array[0..6, 0..7] of TCont;

	// Первый выыбранный контакт
	FstPin: TPin;

implementation

{$R *.dfm}
{$R WindowsXP.res}

// Расчёт логики
function TForm1.TestLink(FPin: TPin):Boolean;
var
	res: Boolean;
begin
	TestLink := False;
  //res := False;
	if (FPin.Link[1] = nil) then
		case FPin.PCont.CType
		of
			// Элементы у которых нет логики
			1..4: Exit;
			// Элементы у которых на свободных контактах логическая 1
			5..5: begin
							TestLink := True;
							FPin.State := True;
						end;

			// Элементы у которых на свободных контактах логический 0
			6..7: begin
							TestLink := False;
							FPin.State := False;
						end;
      {<}
		end
	else
		begin
			// Проверка на рекурсию
			if FPin.Link[1].Rec
			then
				begin
					TestLink := FPin.Link[1].State;
					Exit;
				end
			else
				begin
					FPin.Link[1].Rec := True;
				end;

			// Описание логики
			case (FPin.Link[1].PCont.CType) of

        // Лампочка
				3: res := FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ElOut.State;

        // not And
				5: res := not(
                    TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1]) and
                    TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2])
                  );

        // not Or
				6: res := not(
                    TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1]) or
                    TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2])
                  );

        // Xor
				7: res := TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[1]) xor
                  TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[2]) xor
                  TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[3]) xor
                  TestLink(FPin.Link[1].PCont.CEl[FPin.Link[1].PEl].ELIn[4]);
 			end;

			TestLink := res;
			FPin.State := res;
			FPin.Link[1].State := res;
		end;
end;

// Проверка питания и вызов проверки логики
procedure TForm1.Test;
var
	i, j, k, ii, jj: Integer;
	ta: array[1..4] of TCont;
begin
	i := 1;
	k := 0;
	while (i <= 6) do
		begin
			j := 2;
			while (j <= 7) do
				begin
					if (Field[i, j] <> nil) then
						begin
							Field[i, j].OnLine :=
								 ((Field[i, j - 1] <> nil) and ((Field[i, j].Bus and 8) > 0) and ((Field[i, j - 1].Bus and 1) > 0) and (Field[i, j - 1].OnLine))
							or ((Field[i - 1, j] <> nil) and ((Field[i, j].Bus and 4) > 0) and ((Field[i - 1, j].Bus and 2) > 0) and (Field[i - 1, j].OnLine));
							if ((Field[i, j].OnLine) and (Field[i, j].CType = sendLampType + 1)) then
								begin
									Inc(k);
									ta[k] := Field[i, j];
								end;
						end;
					Inc(j);
				end;
			Inc(i);
		end;
	for i := 1 to 6 do
		for j := 2 to 7 do
			if Field[i, j] <> nil then
				for ii := 1 to 4 do
					begin
						for jj := 1 to 4 do
							if (Field[i, j].CEl[ii].ElIn[jj] <> nil) then
								Field[i, j].CEl[ii].ElIn[jj].Rec := False;
							if (Field[i, j].CEl[ii].ElOut <> nil) then
								Field[i, j].CEl[ii].ElOut.Rec := False;
					end;
	for i:=1 to k do
		for j:=1 to 2 do
			ta[i].CEl[j].ElIn[1].State := TestLink(ta[i].CEl[j].ElIn[1]);
end;

// Прорисовка провода
procedure TForm1.RedrawWire;
var
	i, j, k, z: Integer;
	x1, y1, x2, y2: Integer;
begin
	Redraw;
	for i := 1 to 6 do
		for j := 1 to 7 do
			if (Field[i, j] <> nil) then
				for k := 1 to 4  do
					for z := 1 to 4 do
					if ((Field[i, j].CEl[k].ElIn[z] <> nil) and (Field[i, j].CEl[k].ElIn[z].Link[1] <> nil)) then
						begin
							x1 := Field[i, j].CEl[k].ElIn[z].Left + 3 - Form1.I_Table.Left;
							y1 := Field[i, j].CEl[k].ElIn[z].Top + 3 - Form1.I_Table.Top;
							x2 := Field[i, j].CEl[k].ElIn[z].Link[1].Left + 3 - Form1.I_Table.Left;
							y2 := Field[i, j].CEl[k].ElIn[z].Link[1].Top + 3 - Form1.I_Table.Top;
							Form1.I_Table.Canvas.MoveTo(x1, y1);
							Form1.I_Table.Canvas.LineTo(x2, y2);
						end;
end;

// Перерисовка поля
procedure TForm1.Redraw;
var
	i, j: Integer;
begin
	I_Table.Canvas.FillRect(I_Table.Canvas.ClipRect);
	Test;
	for i := 1 to 6 do
		for j := 1 to 7 do
			begin
				I_Table.Canvas.Rectangle(i * 100 - 95, j * 100 - 95, i * 100 - 5 , j * 100 - 5);
				if (Field[i, j] <> nil) then
					Field[i, j].Redraw(clWhite, False);
			end;
end;

// Выбор элемента в поле выбора
procedure TForm1.Turn(Sender: TObject);
var
	i: Integer;
begin
	for i := 1 to elCount do
		begin
			if (Field[0, i] = Sender) then
				begin
					Field[0, i].Redraw(clSilver, False);
					Cur := i + 1;
					{>
					case i
					of
						1, 2: Cur := i;
						3:  	Cur := 5;
						4:    Cur := 3;
						5:    Cur := 6;
						6:    Cur := 7;
					end;
					{<}
				end
			else
				Field[0, i].Redraw(clWhite, False);
		end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
	i, j: Integer;
begin
	// Очистка поля
	for i := 1 to 6 do
		for j := 1 to 7 do
      begin
  			Field[i, j] := nil;
      end;
	// Создание элементов на поле
	Field[1, 1] := TCont.Create(I_Table, 0, 0, 1, True);
	Field[1, 1].OnLine := True;
	Field[1, 2] := TCont.Create(I_Table, 0, 1, 3, True);
	Field[1, 2].OnLine := True;
	Field[2, 2] := TCont.Create(I_Table, 1, 1, 5, True);
	Field[2, 2].OnLine := True;
	Field[3, 2] := TCont.Create(I_Table, 2, 1, 4, True);

	// Отрисовка элементов на поле выбора
	Field[0, 1] := TCont.Create(I_El, 0, 0, 2, False);
	Field[0, 2] := TCont.Create(I_El, 0, 1, 3, False);
	Field[0, 3] := TCont.Create(I_El, 0, 2, 4, False);
	Field[0, 4] := TCont.Create(I_El, 0, 3, 5, False);
	Field[0, 5] := TCont.Create(I_El, 0, 4, 6, False);
	Field[0, 6] := TCont.Create(I_El, 0, 5, 7, False);
	Field[0, 1].OnClick := Turn;
	Field[0, 2].OnClick := Turn;
	Field[0, 3].OnClick := Turn;
	Field[0, 4].OnClick := Turn;
	Field[0, 5].OnClick := Turn;
	Field[0, 6].OnClick := Turn;
	Cur:=0;
	Redraw;
end;

// Создание нового элемента на поле при отпускании кнопки мыши
procedure TForm1.I_TableMouseUp(Sender: TObject; Button: TMouseButton;
	Shift: TShiftState; X, Y: Integer);
var
	tx, ty: Byte;
begin
	tx := (x div 100) + 1;
	ty := (y div 100) + 1;
	if ((Field[tx, ty] = nil) and (Cur <> 0)) then
		begin
			Field[tx, ty] := TCont.Create(I_Table, tx - 1, ty - 1, Cur, True);
			Redraw;
			RedrawWire;
		end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
	i, j: Integer;
begin
	// Уничтожение элементов на поле
	for i := 1 to 6 do
		for j := 1 to 7 do
			if (Field[i, j] <> nil) then
        begin
  				Field[i, j].Destroy;
        end;
end;

end.
