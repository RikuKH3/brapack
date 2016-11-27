program brapack;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes, ZLibExGZ;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

function Pad(length: Cardinal; DataAlignment: Cardinal): Cardinal;
var
  m: Cardinal;
begin
  Result:=length;
  m:=length mod DataAlignment;
  if (m>0) then Result:=result+DataAlignment-m;
end;

procedure UnpackBra;
const
  gziphdr1: LongWord=$8B1F;
  gziphdr2: LongWord=$8;
var
  FileStream1, FileStream2: TFileStream;
  MemoryStream1, MemoryStream2: TMemoryStream;
  StringList1: TStringList;
  StringBytes: TBytes;
  DataName, OutDir: String;
  FileTablePos, NumOfFiles, DataTime, DataCrc, DataCompSize, DataUnkSize, DataOffset, UnkValue, LongWord1: LongWord;
  DataNameLength, DataFlags: Word;
  i: Integer;
  Byte1: Byte;
begin
  OutDir:=ExpandFileName(Copy(ParamStr(1),1,Length(ParamStr(1))-Length(ExtractFileExt(ParamStr(1)))));
  FileStream1:=TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite); MemoryStream1:=TMemoryStream.Create; MemoryStream2:=TMemoryStream.Create; StringList1:=TStringList.Create;
  try
    FileStream1.ReadBuffer(LongWord1,4);
    if not (LongWord1=$414450) then begin Writeln('Error: Input file is not a valid BRA archive file'); Readln; exit end;
    FileStream1.Position:=FileStream1.Position+4;
    FileStream1.ReadBuffer(FileTablePos,4);
    FileStream1.ReadBuffer(NumOfFiles,4);
    FileStream1.Position:=FileTablePos;
    MemoryStream1.CopyFrom(FileStream1,FileStream1.Size-FileTablePos);
    MemoryStream1.Position:=0;

    for i:=0 to NumOfFiles-1 do
    begin
      MemoryStream1.ReadBuffer(DataTime,4);
      MemoryStream1.ReadBuffer(DataCrc,4);
      MemoryStream1.ReadBuffer(DataCompSize,4);
      MemoryStream1.ReadBuffer(DataUnkSize,4);
      MemoryStream1.ReadBuffer(DataNameLength,2);
      MemoryStream1.ReadBuffer(DataFlags,2);
      MemoryStream1.ReadBuffer(DataOffset,4);

      LongWord1:=MemoryStream1.Position;
      SetLength(StringBytes,0);
      repeat
        MemoryStream1.ReadBuffer(Byte1,1);
        if not (Byte1=0) then
        begin
          SetLength(StringBytes, Length(StringBytes)+1);
          StringBytes[Length(StringBytes)-1]:=Byte1;
        end;
      until (Byte1=0) or (MemoryStream1.Position=LongWord1+DataNameLength);
      DataName:=TEncoding.UTF8.GetString(StringBytes);
      MemoryStream1.Position:=LongWord1+DataNameLength;

      FileStream1.Position:=DataOffset+$C;
      FileStream1.ReadBuffer(UnkValue,4);
      StringList1.Add(DataName+'='+IntToStr(UnkValue)+','+IntToStr(DataTime)+','+IntToStr(DataFlags));

      MemoryStream2.WriteBuffer(gziphdr1,2);
      MemoryStream2.WriteBuffer(gziphdr2,8);
      MemoryStream2.CopyFrom(FileStream1, DataCompSize-$10);
      MemoryStream2.WriteBuffer(DataCrc,4);
      MemoryStream2.WriteBuffer(DataUnkSize,4);
      MemoryStream2.Position:=0;
      ForceDirectories(ExtractFileDir(OutDir+'\'+DataName));
      FileStream2:=TFileStream.Create(OutDir+'\'+DataName, fmCreate or fmOpenWrite or fmShareDenyWrite);
      try
        GZDecompressStream(MemoryStream2,FileStream2);
      finally FileStream2.Free end;
      MemoryStream2.Clear;
      Writeln('[',StringOfChar('0',Length(IntToStr(NumOfFiles))-Length(IntToStr(i+1)))+IntToStr(i+1)+'/'+IntToStr(NumOfFiles)+'] '+DataName);
    end;
    StringList1.SaveToFile(OutDir+'\bra_filelist.txt', TEncoding.UTF8);
  finally FileStream1.Free; MemoryStream1.Free; MemoryStream2.Free; StringList1.Free end;
end;

procedure PackBra;
const
  brahdr: Int64=$200414450;
  ZeroByte: Byte=0;
var
  FileStream1, FileStream2: TFileStream;
  MemoryStream1, MemoryStream2: TMemoryStream;
  StringList1: TStringList;
  InputDir, s: String;
  utfstring: UTF8String;
  FileTablePos, NumOfFiles, DataOffset, DataTime, DataUnkSize, DataCompSize, DataCrc, UnkValue: LongWord;
  Word1, DataFlags, DataNameLength: Word;
  z, i: Integer;
begin
  InputDir:=ExpandFileName(ParamStr(1));
  repeat if InputDir[Length(InputDir)]='\' then SetLength(InputDir, Length(InputDir)-1) until not (InputDir[Length(InputDir)]='\');
  StringList1:=TStringList.Create;
  try
    if not (FileExists(InputDir+'\bra_filelist.txt')) then begin Writeln('Error: '+#39+'bra_filelist.txt'+#39+' not found in selected directory'); Readln; exit end;
    StringList1.LoadFromFile(InputDir+'\bra_filelist.txt');
    if StringList1.Count=0 then begin Writeln('Error: '+#39+'bra_filelist.txt'+#39+' is empty'); Readln; exit end;

    FileStream1:=TFileStream.Create(InputDir+'.bra', fmCreate or fmOpenWrite or fmShareDenyWrite); MemoryStream1:=TMemoryStream.Create; MemoryStream2:=TMemoryStream.Create;
    try
      FileStream1.WriteBuffer(brahdr,8);
      FileStream1.Size:=FileStream1.Size+4; //reserved for FileTablePos
      NumOfFiles:=StringList1.Count;
      FileStream1.WriteBuffer(NumOfFiles,4);

      for z:=0 to NumOfFiles-1 do
      begin
        i:=Pos(',', StringList1.ValueFromIndex[z]);
        UnkValue:=LongWord(StrToInt64(Copy(StringList1.ValueFromIndex[z],1,i-1)));
        s:=Copy(StringList1.ValueFromIndex[z],i+1);
        i:=Pos(',', s);
        DataTime:=LongWord(StrToInt64(Copy(s,1,i-1)));
        DataFlags:=Word(StrToInt64(Copy(s,i+1)));

        FileStream2:=TFileStream.Create(InputDir+'\'+StringList1.Names[z], fmOpenRead or fmShareDenyWrite);
        try
          GZCompressStream(FileStream2, MemoryStream2);
          //GZCompressStream2(
          DataUnkSize:=FileStream2.Size;
          DataCompSize:=MemoryStream2.Size-18;
          MemoryStream2.Position:=MemoryStream2.Size-8;
          MemoryStream2.ReadBuffer(DataCrc,4);
          MemoryStream2.Position:=$A;

          FileStream1.WriteBuffer(DataUnkSize,4);
          FileStream1.WriteBuffer(DataCompSize,4);
          FileStream1.WriteBuffer(DataCrc,4);
          FileStream1.WriteBuffer(UnkValue,4);
          FileStream1.CopyFrom(MemoryStream2,DataCompSize);
        finally FileStream2.Free end;
        MemoryStream2.Clear;

        MemoryStream1.WriteBuffer(DataTime,4);
        MemoryStream1.WriteBuffer(DataCrc,4);
        DataCompSize:=DataCompSize+$10;
        MemoryStream1.WriteBuffer(DataCompSize,4);
        MemoryStream1.WriteBuffer(DataUnkSize,4);
        utfstring:=UTF8String(StringList1.Names[z]);
        DataNameLength:=Length(utfstring);
        Word1:=Pad(DataNameLength,4);
        if DataNameLength<Word1 then begin utfstring:=utfstring+#0; DataNameLength:=DataNameLength+1 end;
        MemoryStream1.WriteBuffer(Word1,2);
        MemoryStream1.WriteBuffer(DataFlags,2);
        DataOffset:=FileStream1.Size-DataCompSize;
        MemoryStream1.WriteBuffer(DataOffset,4);
        MemoryStream1.WriteBuffer(utfstring[1], DataNameLength);
        for i:=1 to Word1-DataNameLength do MemoryStream1.WriteBuffer(ZeroByte,1);
        Writeln('[',StringOfChar('0',Length(IntToStr(NumOfFiles))-Length(IntToStr(z+1)))+IntToStr(z+1)+'/'+IntToStr(NumOfFiles)+'] '+StringList1.Names[z]);
      end;
      FileTablePos:=FileStream1.Size;
      MemoryStream1.Position:=0;
      FileStream1.CopyFrom(MemoryStream1, MemoryStream1.Size);
      FileStream1.Position:=8;
      FileStream1.WriteBuffer(FileTablePos,4);
    finally FileStream1.Free; MemoryStream1.Free; MemoryStream2.Free end;
  finally StringList1.Free end;
end;

begin
  try
    Writeln('Compile Heart BRA Unpacker/Packer v1.0 by RikuKH3');
    Writeln('-------------------------------------------------');
    if ParamCount=0 then begin Writeln('Usage: brapack.exe <input file or folder>'); Readln; exit end;
    if Pos('.', ExtractFileName(ParamStr(1)))=0 then PackBra else UnpackBra;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
