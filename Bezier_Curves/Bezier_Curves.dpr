program Bezier_Curves;

uses
  Forms,
  UB1 in 'UB1.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Courbes  de  Bézier';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
