program brapack;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes, Zlib;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

function CalculateCRC32(AStream : TStream): Cardinal;
const
  CRC32Table:  ARRAY[0..255] of Cardinal =
   ($00000000, $77073096, $EE0E612C, $990951BA,
    $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
    $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
    $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
    $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
    $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
    $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116,
    $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
    $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
    $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
    $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
    $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
    $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
    $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
    $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
    $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086,
    $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
    $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,
    $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
    $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
    $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
    $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
    $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
    $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
    $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
    $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
    $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
    $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
    $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
    $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
    $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
    $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
    $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);
var
  aMemStream: TMemoryStream;
  aValue: Byte;
begin
  aMemStream := TMemoryStream.Create;
  try
    Result := $FFFFFFFF;
    while AStream.Position < AStream.Size do begin
      aMemStream.Seek(0, soFromBeginning);
      if AStream.Size - AStream.Position >= 1024*1024
        then aMemStream.CopyFrom(AStream, 1024*1024)
        else begin
          aMemStream.Clear;
          aMemStream.CopyFrom(AStream, AStream.Size-AStream.Position);
        end;
      aMemStream.Seek(0, soFromBeginning);
      while aMemStream.Position < aMemStream.Size do begin
        aMemStream.ReadBuffer(aValue, 1);
        Result := (Result shr 8) xor CRC32Table[aValue xor (Result and $000000FF)];
      end;
    end;
    Result := not Result;
  finally aMemStream.Free end;
end;

procedure UnpackBra;
var
  FileStream1: TFileStream;
  MemoryStream1, MemoryStream2: TMemoryStream;
  StringList1: TStringList;
  ZDecompressionStream1: TZDecompressionStream;
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
      DataName:=TEncoding.GetEncoding(932).GetString(StringBytes);
      MemoryStream1.Position:=LongWord1+DataNameLength;

      FileStream1.Position:=DataOffset+$C;
      FileStream1.ReadBuffer(UnkValue,4);
      StringList1.Add(DataName+'='+IntToStr(UnkValue)+','+IntToStr(DataTime)+','+IntToStr(DataFlags));

      ForceDirectories(ExtractFileDir(OutDir+'\'+DataName));
      ZDecompressionStream1:=TZDecompressionStream.Create(FileStream1, -15);
      try
        MemoryStream2.CopyFrom(ZDecompressionStream1, DataUnkSize);
      finally ZDecompressionStream1.Free end;
      MemoryStream2.Position:=0;
      if not (DataCrc=CalculateCRC32(MemoryStream2)) then begin Writeln('Error: CRC32 mismatch in archive footer'); Readln; exit end;
      MemoryStream2.SaveToFile(OutDir+'\'+DataName);
      MemoryStream2.Clear;
      Writeln('[',StringOfChar('0',Length(IntToStr(NumOfFiles))-Length(IntToStr(i+1)))+IntToStr(i+1)+'/'+IntToStr(NumOfFiles)+'] '+DataName);
    end;
    StringList1.SaveToFile(OutDir+'\bra_filelist.txt', TEncoding.UTF8);
  finally FileStream1.Free; MemoryStream1.Free; MemoryStream2.Free; StringList1.Free end;
end;

procedure PackBra;
type
  ShiftjisString = type AnsiString(932);
const
  brahdr: Int64=$200414450;
  ZeroByte: Byte=0;
var
  FileStream1, FileStream2: TFileStream;
  MemoryStream1, MemoryStream2: TMemoryStream;
  StringList1: TStringList;
  ZCompressionStream1: TZCompressionStream;
  InputDir, s: String;
  SjisString: ShiftjisString;
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
          DataCrc:=CalculateCRC32(FileStream2);
          FileStream2.Position:=0;

          if ParamCount>1 then
            if LowerCase(Copy(ParamStr(2),2))='zcfastest' then ZCompressionStream1:=TZCompressionStream.Create(MemoryStream2, zcFastest, -15) else ZCompressionStream1:=TZCompressionStream.Create(MemoryStream2, zcMax, -15)
          else ZCompressionStream1:=TZCompressionStream.Create(MemoryStream2, zcMax, -15); //15 is default Zlib value

          try
            DataUnkSize:=FileStream2.Size;
            ZCompressionStream1.CopyFrom(FileStream2, FileStream2.Size);
          finally ZCompressionStream1.Free end;
        finally FileStream2.Free end;
        DataCompSize:=MemoryStream2.Size;
        FileStream1.WriteBuffer(DataUnkSize,4);
        FileStream1.WriteBuffer(DataCompSize,4);
        FileStream1.WriteBuffer(DataCrc,4);
        FileStream1.WriteBuffer(UnkValue,4);
        MemoryStream2.Position:=0;
        FileStream1.CopyFrom(MemoryStream2,DataCompSize);
        MemoryStream2.Clear;

        MemoryStream1.WriteBuffer(DataTime,4);
        MemoryStream1.WriteBuffer(DataCrc,4);
        DataCompSize:=DataCompSize+$10;
        MemoryStream1.WriteBuffer(DataCompSize,4);
        MemoryStream1.WriteBuffer(DataUnkSize,4);
        SjisString:=ShiftjisString(StringList1.Names[z]);
        DataNameLength:=Length(SjisString);
        if (DataNameLength mod 4)>0 then Word1:=DataNameLength+4-(DataNameLength mod 4) else Word1:=DataNameLength; //padding
        if DataNameLength<Word1 then begin SjisString:=SjisString+#0; DataNameLength:=DataNameLength+1 end;
        MemoryStream1.WriteBuffer(Word1,2);
        MemoryStream1.WriteBuffer(DataFlags,2);
        DataOffset:=FileStream1.Size-DataCompSize;
        MemoryStream1.WriteBuffer(DataOffset,4);
        MemoryStream1.WriteBuffer(SjisString[1], DataNameLength);
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
    Writeln('Compile Heart BRA Unpacker/Packer v1.2 by RikuKH3');
    Writeln('-------------------------------------------------');
    if ParamCount=0 then begin Writeln('Usage: brapack.exe <input file or folder> [-zcFastest]'); Readln; exit end;
    if Pos('.', ExtractFileName(ParamStr(1)))=0 then PackBra else UnpackBra;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
