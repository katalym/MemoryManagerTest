unit RenameMMForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, VCL.Graphics, VCL.Controls, VCL.Forms,
  VCL.Dialogs, VCL.StdCtrls, VCL.Buttons;

type
  TRenameFrm = class(TForm)
    bCancel: TBitBtn;
    bOK: TBitBtn;
    eMMName: TEdit;
    Label1: TLabel;
  end;

var
  RenameFrm: TRenameFrm;

implementation

{$R *.dfm}

end.
