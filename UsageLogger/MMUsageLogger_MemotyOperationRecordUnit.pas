unit MMUsageLogger_MemotyOperationRecordUnit;

interface

const
  {The number of operations to buffer}
  BufferCount = 32 * 1024 * 1024;

type
  {A single operation}
  PMMOperation = ^TMMOperation;

  // memory Operation record
  TMMOperation = packed record
    {The old pointer number. Will be < 0 for GetMem requests, non-zero otherwise.}
    FOldPointerNumber: Integer;
    {The requested size. Will be zero for FreeMem requests, non-zero otherwise.}
    FRequestedSize: NativeInt;
    {The new pointer number. Will be < 0 for FreeMem requests, non-zero otherwise.}
    FNewPointerNumber: Integer;
  end;

  {The array of operations}
  TMMOperationArray = array [0 .. BufferCount - 1] of TMMOperation;
  PMMOperationArray = ^TMMOperationArray;

implementation

end.
