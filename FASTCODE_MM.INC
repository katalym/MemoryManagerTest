// For development and debugging purposes only.
// All defines should be disabled for production builds.

{.$DEFINE MM_DEFAULT}
{.$DEFINE MM_SCALEMM2}
{.$DEFINE MM_FASTMM4}
{.$DEFINE MM_FASTMM5}
{.$DEFINE MM_BIGBRAIN}

//  no memory manager defined in FASTCODE_MM.INC - use default for debugging
//{$IFNDEF MM_DEFAULT}{$IFNDEF MM_SCALEMM2}{$IFNDEF MM_FASTMM4}{$IFNDEF MM_FASTMM5}{$IFNDEF MM_BIGBRAIN}
// comment/Undefine the line below if running _BuildAll.bat
{.$DEFINE MM_DEFAULT}
//{$ENDIF}{$ENDIF}{$ENDIF}{$ENDIF}{$ENDIF}

