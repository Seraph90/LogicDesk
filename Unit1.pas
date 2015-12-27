unit Unit1;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, ExtCtrls,
	Unit2, StdCtrls, Menus;

type
	TForm1 = class(TForm)

		// Work field
		I_Table: TImage;

		// Change field
		I_El: TImage;
		procedure FormCreate(Sender: TObject);
		procedure I_TableMouseUp(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);

		procedure RedrawWire;

		// Connect test and logic test
		procedure Test;

		// Calculate logic
		function TestLink(FPin: TPin): Boolean;

		// Work field redraw
		procedure Redraw;

		// Change element on work field
		procedure Turn(Sender: TObject);
	private
	public
	end;

const
  // The number of selectable items
  elCount = 6;

  // Battaries conteiner type
  batType = 1;

  // Signal generators lamp conteiner type
  sendLampType = 3;

var
	Form1: TForm1;
	
	Cur: Integer;

	// Work field
	Field: array[0..6, 0..7] of TCont;

	// First selected pin
	FstPin: TPin;

implementation

{$R *.dfm}
{$R WindowsXP.res}

// Calculate logic
function TForm1.TestLink(FPin: TPin):Boolean;
var
	res: Boolean;
begin
	TestLink := False;
  res := False;
	if (FPin.Link[1] = nil) then
		case FPin.PCont.CType
		of

			// Elements without logic
			1..4: Exit;

			// Elements with logic 1 on free pin
			5..5: begin
							TestLink := True;
							FPin.State := True;
						end;

			// Elements with logic 0 on free pin
			6..7: begin
							TestLink := False;
							FPin.State := False;
						end;

		end
	else
		begin
			// Check for recursion
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

			// Describing logic
			case (FPin.Link[1].PCont.CType) of

        // Lamp
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

// Connect test and logic test
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

// Work field redraw
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

// Change element on work field
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
					{> If elements not organized
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
	// Clearing field
	for i := 1 to 6 do
		for j := 1 to 7 do
      begin
  			Field[i, j] := nil;
      end;

	// Creates elements on work field
	Field[1, 1] := TCont.Create(I_Table, 0, 0, 1, True);
	Field[1, 1].OnLine := True;
	Field[1, 2] := TCont.Create(I_Table, 0, 1, 3, True);
	Field[1, 2].OnLine := True;
	Field[2, 2] := TCont.Create(I_Table, 1, 1, 5, True);
	Field[2, 2].OnLine := True;
	Field[3, 2] := TCont.Create(I_Table, 2, 1, 4, True);

	// Creates elements on change field
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

// Create new element on mouse up
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
	// Destroying all elements 
	for i := 1 to 6 do
		for j := 1 to 7 do
			if (Field[i, j] <> nil) then
        begin
  				Field[i, j].Destroy;
        end;
end;

end.
