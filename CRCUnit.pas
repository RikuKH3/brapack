unit CRCUnit;

interface
function GetNewCRC(OldCRC: cardinal; StPtr: pointer; StLen: integer): cardinal;
procedure UpdateCRC(StPtr: pointer; StLen: integer; var CRC: cardinal);
function GetZipCRC(StPtr: pointer; StLen: integer): cardinal;
function GetFileCRC(const FileName: string): cardinal;

implementation
var
  CRCtable: array[0..255] of cardinal;

function GetNewCRC(OldCRC: cardinal; StPtr: pointer; StLen: integer): cardinal;
asm
  test edx,edx;
  jz @ret;
  neg ecx;
  jz @ret;
  sub edx,ecx; // Address after last element

  push ebx;
  mov ebx,0; // Set ebx=0 & align @next
@next:
  mov bl,al;
  xor bl,byte [edx+ecx];
  shr eax,8;
  xor eax,cardinal [CRCtable+ebx*4];
  inc ecx;
  jnz @next;
  pop ebx;

@ret:
end;

procedure UpdateCRC(StPtr: pointer; StLen: integer; var CRC: cardinal);
begin
  CRC:=GetNewCRC(CRC,StPtr,StLen);
end;

function GetZipCRC(StPtr: pointer; StLen: integer): cardinal;
begin
  Result:=not GetNewCRC($FFFFFFFF, StPtr, StLen);
end;

function GetFileCRC(const FileName: string): cardinal;
const
  BufSize = 64*1024;
var
  Fi: file;
  pBuf: PChar;
  Count: integer;
begin
  Assign(Fi,FileName);
  Reset(Fi,1);
  GetMem(pBuf,BufSize);
  Result:=$FFFFFFFF;
  repeat
    BlockRead(Fi,pBuf^,BufSize,Count);
    if Count=0 then break;
    Result:=GetNewCRC(Result,pBuf,Count);
  until false;
  Result:=not Result;
  FreeMem(pBuf);
  CloseFile(Fi);
end;

procedure CRCInit;
var
  c: cardinal;
  i, j: integer;
begin
  for i:=0 to 255 do begin
    c:=i;
    for j:=1 to 8 do if odd(c) then c:=(c shr 1) xor $EDB88320 else c:=(c shr 1);
    CRCtable[i]:=c;
  end;
end;

initialization
  CRCinit;
end.
