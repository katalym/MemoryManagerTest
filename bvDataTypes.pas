(**
  Release: 8.22 14 - Aug -2023
  Purpose: Basic tames for use in Delphi code when accessing databasxe fields
  Copyright(c) 2001-2023, BroadView Software Inc. All rights reserved.
*)

unit bvDataTypes;

interface

uses
  Data.DB, System.Classes, Vcl.ComCtrls, System.Generics.Collections, Vcl.Controls,
  Vcl.Graphics, Vcl.Forms, Vcl.OleCtrls;

function bvCardinalToShortInt(const aCardinal: Cardinal): ShortInt; inline;

function bvCardinalToInt(const aCardinal: Cardinal): Integer; inline;

function bvCardinalToNativeInt(const aCardinal: Cardinal): NativeInt; inline;

function bvCardinalToWord(const aCardinal: Cardinal): Word; inline;

function bvInt64ToCardinal(const aInt64: Int64): Cardinal; inline;

function bvInt64ToInt(const aInt64: Int64): Integer; inline;

function bvInt64ToNativeInt(const aInt64: Int64): NativeInt; inline;

function bvInt64ToWord(const aInt64: Int64): Word; inline;

function bvIntToByte(const aInteger: Integer): Byte; inline;

function bvIntToCardinal(const aInteger: Integer): Cardinal; inline;

function bvIntToNativeUInt(const aInteger: Integer): NativeUInt; inline;

function bvIntToShortInt(const aInteger: Integer): ShortInt; inline;

function bvIntToSmallInt(const aInteger: Integer): SmallInt; inline;

function bvIntToTConstraintSize(const aInteger: Integer): TConstraintSize; inline;

function bvIntToTFontCharset(const aInteger: Integer): TFontCharset; inline;

function bvIntToTScrollBarInc(const aInteger: Integer): TScrollBarInc; inline;

function bvIntToTWidth(const aInteger: Integer): TWidth; inline;

function bvIntToWord(const aInteger: Integer): Word; inline;

function bvNativeIntToInt(const aNInt: NativeInt): Integer; inline;

function bvNativeUIntToCardinal(const aNUInt: NativeUInt): Cardinal; inline;

function bvNativeUIntToByte(const aNUInt: NativeUInt): Byte; inline;

function bvNativeUIntToInt(const aNUInt: NativeUInt): Integer; inline;

function bvNativeUIntToNativeInt(const aNUInt: NativeUInt): NativeInt; inline;

function bvShortIntToByte(const aShortInt: ShortInt): Byte; inline;

function bvWordToByte(const aWord: Word): Byte; inline;

implementation

uses
  System.SysUtils;

function bvCardinalToShortInt(const aCardinal: Cardinal): ShortInt; inline;
begin
{$WARN COMPARING_SIGNED_UNSIGNED OFF}
  if aCardinal > High(ShortInt) then begin
{$WARN COMPARING_SIGNED_UNSIGNED ON}
    raise Exception.CreateFmt('Error in implicit convertion Cardinal %d to ShortInt', [aCardinal]);
    Result := 0;
  end else
    Result := ShortInt(aCardinal);
end;

function bvCardinalToInt(const aCardinal: Cardinal): Integer; inline;
begin
{$WARN COMPARING_SIGNED_UNSIGNED OFF}
  if aCardinal > High(Integer) then begin
{$WARN COMPARING_SIGNED_UNSIGNED ON}
    raise Exception.CreateFmt('Error in implicit convertion Cardinal %d to Integer', [aCardinal]);
    Result := 0;
  end else
    Result := Integer(aCardinal);
end;

function bvCardinalToNativeInt(const aCardinal: Cardinal): NativeInt; inline;
begin
{$WARN COMPARING_SIGNED_UNSIGNED OFF}
  if aCardinal > High(NativeInt) then begin
{$WARN COMPARING_SIGNED_UNSIGNED ON}
    raise Exception.CreateFmt('Error in implicit convertion Cardinal %d to NativeInt', [aCardinal]);
    Result := 0;
  end else
    Result := NativeInt(aCardinal);
end;

function bvCardinalToWord(const aCardinal: Cardinal): Word; inline;
begin
  if aCardinal > High(Word) then begin
    raise Exception.CreateFmt('Error in implicit convertion Cardinal %d to Word', [aCardinal]);
    Result := 0;
  end else
    Result := Word(aCardinal);
end;

function bvInt64ToCardinal(const aInt64: Int64): Cardinal; inline;
begin
  if (aInt64 > High(Cardinal)) or (aInt64 < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion Int64 %d to Cardinal', [aInt64]);
    Result := 0;
  end else
    Result := Cardinal(aInt64);
end;

function bvInt64ToInt(const aInt64: Int64): Integer; inline;
begin
  if (aInt64 > High(Integer)) or (aInt64 < Low(Integer)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Int64 %d to Integer', [aInt64]);
    Result := 0;
  end else
    Result := Integer(aInt64);
end;

function bvInt64ToNativeInt(const aInt64: Int64): NativeInt; inline;
begin
  if (aInt64 > High(NativeInt)) or (aInt64 < Low(NativeInt)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Int64 %d to NativeInt', [aInt64]);
    Result := 0;
  end else
    Result := NativeInt(aInt64);
end;

function bvInt64ToWord(const aInt64: Int64): Word; inline;
begin
  if (aInt64 > High(Word)) or (aInt64 < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion Int64 %d to Word', [aInt64]);
    Result := 0;
  end else
    Result := Word(aInt64);
end;

function bvIntToByte(const aInteger: Integer): Byte; inline;
begin
  if (aInteger > High(Byte)) or (aInteger < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to Byte', [aInteger]);
    Result := 0;
  end else
    Result := Byte(aInteger);
end;

function bvIntToCardinal(const aInteger: Integer): Cardinal;  inline;
begin
  if (aInteger < 0)  then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to Cardinal', [aInteger]);
    Result := 0;
  end else
    Result := Cardinal(aInteger);
end;

function bvIntToNativeUInt(const aInteger: Integer): NativeUInt; inline;
begin
  if (aInteger < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to NativeUInt', [aInteger]);
    Result := 0;
  end else
    Result := NativeUInt(aInteger);
end;

function bvIntToShortInt(const aInteger: Integer): ShortInt; inline;
begin
  if (aInteger > High(ShortInt)) or (aInteger < Low(ShortInt)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to ShortInt', [aInteger]);
    Result := 0;
  end else
    Result := ShortInt(aInteger);
end;

function bvIntToSmallInt(const aInteger: Integer): SmallInt; inline;
begin
  if (aInteger > High(SmallInt)) or (aInteger < Low(SmallInt)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to SmallInt', [aInteger]);
    Result := 0;
  end else
    Result := SmallInt(aInteger);
end;

function bvIntToTConstraintSize(const aInteger: Integer): TConstraintSize; inline;
begin
  if (aInteger < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to TConstraintSize', [aInteger]);
    Result := 0;
  end else
    Result := TConstraintSize(aInteger);
end;

function bvIntToTFontCharset(const aInteger: Integer): TFontCharset; inline;
begin
  if (aInteger > High(TFontCharset)) or (aInteger < Low(TFontCharset)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to TFontCharset', [aInteger]);
    Result := Low(TFontCharset);
  end else
    Result := TFontCharset(aInteger);
end;

function bvIntToTScrollBarInc(const aInteger: Integer): TScrollBarInc; inline;
begin
  if (aInteger > High(TScrollBarInc)) or (aInteger < Low(TScrollBarInc)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to TScrollBarInc', [aInteger]);
    Result := Low(TScrollBarInc);
  end else
    Result := TScrollBarInc(aInteger);
end;

function bvIntToTWidth(const aInteger: Integer): TWidth; inline;
begin
  if (aInteger < ColumnHeaderWidth) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to TWidth', [aInteger]);
    Result := 0;
  end else
    Result := TWidth(aInteger);
end;

function bvIntToWord(const aInteger: Integer): Word; inline;
begin
  if (aInteger < 0) or (aInteger > High(Word)) then begin
    raise Exception.CreateFmt('Error in implicit convertion Integer %d to Word', [aInteger]);
    Result := 0;
  end else
    Result := Word(aInteger);
end;

function bvNativeIntToInt(const aNInt: NativeInt): Integer; inline;
begin
  // W1072 Implicit conversion may lose significant digits from 'signed native integer' to 'Integer'
{$WARN COMPARISON_FALSE OFF}
  if (aNInt > High(Integer)) or (aNInt < Low(Integer)) then begin
{$WARN COMPARISON_FALSE ON}
    raise Exception.CreateFmt('Error in implicit convertion NativeUInt %d to NativeInt', [aNInt]);
    Result := 0;
  end else
    Result := Integer(aNInt);
end;

function bvNativeUIntToCardinal(const aNUInt: NativeUInt): Cardinal; inline;
begin
{$WARN COMPARISON_FALSE OFF}
  if (aNUInt > High(Cardinal)) or (aNUInt < Low(Cardinal)) then begin
{$WARN COMPARISON_FALSE ON}
    raise Exception.CreateFmt('Error in implicit convertion NativeUInt %d to Cardinal', [aNUInt]);
    Result := 0;
  end else
    Result := Cardinal(aNUInt);
end;

function bvNativeUIntToByte(const aNUInt: NativeUInt): Byte; inline;
begin
{$WARN COMPARISON_FALSE OFF}
  if (aNUInt > High(Byte)) or (aNUInt < Low(Byte)) then begin
{$WARN COMPARISON_FALSE ON}
    raise Exception.CreateFmt('Error in implicit convertion NativeUInt %d to Byte', [aNUInt]);
    Result := 0;
  end else
    Result := Byte(aNUInt);
end;

function bvNativeUIntToInt(const aNUInt: NativeUInt): Integer; inline;
begin
{$WARN COMPARING_SIGNED_UNSIGNED OFF}
{$WARN COMPARISON_FALSE OFF}
  if (aNUInt > High(NativeInt)) or (aNUInt < Low(NativeInt)) then begin
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
    raise Exception.CreateFmt('Error in implicit convertion NativeUInt %d to NativeInt', [aNUInt]);
    Result := 0;
  end else
    Result := Integer(aNUInt);
end;

function bvNativeUIntToNativeInt(const aNUInt: NativeUInt): NativeInt; inline;
begin
{$WARN COMPARING_SIGNED_UNSIGNED OFF}
{$WARN COMPARISON_FALSE OFF}
  if (aNUInt > High(NativeInt)) or (aNUInt < Low(NativeInt)) then begin
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
    raise Exception.CreateFmt('Error in implicit convertion NativeUInt %d to NativeInt', [aNUInt]);
    Result := 0;
  end else
    Result := NativeInt(aNUInt);
end;

function bvShortIntToByte(const aShortInt: ShortInt): Byte; inline;
begin
  if (aShortInt < 0) then begin
    raise Exception.CreateFmt('Error in implicit convertion ShortInt %d to Byte', [aShortInt]);
    Result := 0;
  end else
    Result := Byte(aShortInt);
end;

function bvWordToByte(const aWord: Word): Byte; inline;
begin
  if aWord > High(Byte) then begin
    raise Exception.CreateFmt('Error in implicit convertion Word %d to Byte', [aWord]);
    Result := 0;
  end else
    Result := Byte(aWord);
end;

end.
