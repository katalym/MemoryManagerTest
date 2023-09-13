unit CPU_Usage_Unit;

interface

function GetCpuUsage_Kernel: Int64;

function GetCpuUsage_Total: Int64;

function GetCpuUsage_User: Int64;

implementation

uses
  System.SysUtils, Winapi.Windows;

type
  TCPUUsageData = record
    FProcessID: cardinal;
    FHandle: NativeUint;
  end;

  PCPUUsageData = ^TCPUUsageData;

var
  InternalCPUUsageData: PCPUUsageData;

function _CreateUsageCounter: Boolean;
var
  vHandle: NativeUint;
  vPID: Cardinal;
begin
  vPID := GetCurrentProcessID;

  Result := False;
  // We need a handle with PROCESS_QUERY_INFORMATION privileges
  vHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, vPID);
  if vHandle = 0 then
    exit;
  New(InternalCPUUsageData);
  InternalCPUUsageData.FProcessID := vPID;
  InternalCPUUsageData.FHandle := vHandle;
end;

procedure _DestroyUsageCounter;
begin
  CloseHandle(InternalCPUUsageData.FHandle);
  Dispose(InternalCPUUsageData);
end;

function GetCurrentCpuUsage(out aKernel, aUser: Int64): Int64;
var
  vCreationTime, vExitTime, vKernelTime, vUserTime: TFileTime;
  vTime: TSystemTime;
begin

  GetProcessTimes(InternalCPUUsageData.FHandle, vCreationTime, vExitTime, vKernelTime, vUserTime);
  // convert _FILETIME to Int64 - milliseconds
  FileTimeToSystemTime(vKernelTime, vTime);
  aKernel := ((vTime.wHour * 60 + vTime.wMinute) * 60 + vTime.wSecond) * 1000 + vTime.wMilliseconds;
  FileTimeToSystemTime(vUserTime, vTime);
  aUser := ((vTime.wHour * 60 + vTime.wMinute) * 60 + vTime.wSecond) * 1000 + vTime.wMilliseconds;

  // total
  Result := aKernel + aUser;

end;

function GetCpuUsage_Total: Int64;
var
  vKernel, vUser: Int64;
begin
  Result := GetCurrentCpuUsage(vKernel, vUser);
end;

function GetCpuUsage_User: Int64;
var
  vKernel: Int64;
begin
  GetCurrentCpuUsage(vKernel, Result);
end;

function GetCpuUsage_Kernel: Int64;
var
  vUser: Int64;
begin
  GetCurrentCpuUsage(Result, vUser);
end;

initialization

_CreateUsageCounter;

finalization

_DestroyUsageCounter;

end.
