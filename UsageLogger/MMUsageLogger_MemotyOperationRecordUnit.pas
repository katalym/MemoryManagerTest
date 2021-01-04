unit MMUsageLogger_MemotyOperationRecordUnit;

interface

const
  // The number of operations to buffer
  BufferCount = 4 * 1024 * 1024;

type
  // A single operation
  PMMOperation = ^TMMOperation;

  // memory Operation record
  TMMOperation = packed record
    // The new pointer number. Will be < 0 for FreeMem requests, non-zero otherwise.
    FNewPointerNumber: Cardinal;
    // The old pointer number. Will be < 0 for GetMem requests, non-zero otherwise.
    FOldPointerNumber: Cardinal;
    // The requested size. Will be zero for FreeMem requests, non-zero otherwise.
    FRequestedSize: Cardinal; // should be NativeInt but assume 32 bit will be enough
    // Thread ID - zero for Main thread
    FThreadID: Cardinal;
    // Tick Count
    FTicks: Cardinal;
  end;

  // The array of operations
  TMMOperationArray = array [0 .. BufferCount - 1] of TMMOperation;
  PMMOperationArray = ^TMMOperationArray;

implementation

end.
