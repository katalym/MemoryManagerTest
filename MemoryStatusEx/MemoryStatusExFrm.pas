unit MemoryStatusExFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TMemoryStatusExForm = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    btnRefreshStatus: TBitBtn;
    procedure btnRefreshStatusClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure UpdateMemoryStatus;
  public
    { Public declarations }
  end;

var
  MemoryStatusExForm: TMemoryStatusExForm;

implementation

{$R *.dfm}

procedure TMemoryStatusExForm.btnRefreshStatusClick(Sender: TObject);
begin
  UpdateMemoryStatus;
end;

procedure TMemoryStatusExForm.FormCreate(Sender: TObject);
begin
  UpdateMemoryStatus;
end;

procedure TMemoryStatusExForm.UpdateMemoryStatus;
var
  vMemoryStatusEx : MemoryStatusEx;
begin
  Memo1.Lines.Clear;

  FillChar (vMemoryStatusEx, SizeOf(MemoryStatusEx), #0);
  vMemoryStatusEx.dwLength := SizeOf(MemoryStatusEx);
  GlobalMemoryStatusEx (vMemoryStatusEx);

  Memo1.Lines.Add(Format('dwLength: %d', [vMemoryStatusEx.dwLength]));
  Memo1.Lines.Add('dwLength: The size of the structure, in bytes. You must set this member before calling GlobalMemoryStatusEx.');

  Memo1.Lines.Add(Format('dwMemoryLoad: %d', [vMemoryStatusEx.dwMemoryLoad]));
  Memo1.Lines.Add('dwMemoryLoad: A number between 0 and 100 that specifies the approximate percentage of physical memory that is in use (0 indicates no ' +
    'memory use and 100 indicates full memory use).');

  Memo1.Lines.Add(Format('ullTotalPhys: %d', [vMemoryStatusEx.ullTotalPhys]));
  Memo1.Lines.Add('ullTotalPhys: The amount of actual physical memory, in bytes.');

  Memo1.Lines.Add(Format('ullAvailPhys: %d', [vMemoryStatusEx.ullAvailPhys]));
  Memo1.Lines.Add('ullAvailPhys: The amount of physical memory currently available, in bytes. This is the amount of physical memory that can be immediately ' +
    'reused without having to write its contents to disk first. It is the sum of the size of the standby, free, and zero lists.');

  Memo1.Lines.Add(Format('ullTotalPageFile: %d', [vMemoryStatusEx.ullTotalPageFile]));
  Memo1.Lines.Add('ullTotalPageFile: The current committed memory limit for the system or the current process, whichever is smaller, in bytes. To get the system-wide ' +
    'committed memory limit, call GetPerformanceInfo.');

  Memo1.Lines.Add(Format('ullAvailPageFile: %d', [vMemoryStatusEx.ullAvailPageFile]));
  Memo1.Lines.Add('ullAvailPageFile: The maximum amount of memory the current process can commit, in bytes. This value is equal to or smaller than the system-wide ' +
    'available commit value. To calculate the system-wide available commit value, call GetPerformanceInfo and subtract the value of CommitTotal from the value of CommitLimit.');

  Memo1.Lines.Add(Format('ullTotalVirtual: %d', [vMemoryStatusEx.ullTotalVirtual]));
  Memo1.Lines.Add('ullTotalVirtual: The size of the user-mode portion of the virtual address space of the calling process, in bytes. This value depends on the type of process, ' +
  'the type of processor, and the configuration of the operating system. For example, this value is approximately 2 GB for most 32-bit processes on an x86 processor ' +
  'and approximately 3 GB for 32-bit processes that are large address aware running on a system with 4-gigabyte tuning enabled.');

  Memo1.Lines.Add(Format('ullAvailVirtual: %d', [vMemoryStatusEx.ullAvailVirtual]));
  Memo1.Lines.Add('ullAvailVirtual: The amount of unreserved and uncommitted memory currently in the user-mode portion of the virtual address space of the calling process, in bytes.');

  Memo1.Lines.Add(Format('ullAvailExtendedVirtual: %d', [vMemoryStatusEx.ullAvailExtendedVirtual]));
  Memo1.Lines.Add('ullAvailExtendedVirtual: Reserved. This value is always 0.');

end;

end.
