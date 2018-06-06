unit uEmployeeMovementUtils;

interface

type
  TMovementInOut = (mioIn, mioOut);

type
  ISourceMovementKey = interface
    function GetAsString: string;
    property AsString: string read GetAsString;
  end;

type
  TEmployeeMovement = record
    SourceMovementKey: ISourceMovementKey;
    SourceName: string;
    DestinationName: string;
    EmployeeNo: Integer;
    MovementDateTime: TDateTime;
    InOut: TMovementInOut;
    function ToString: string;
  end;

type
  TEmployeeMovements = TArray<TEmployeeMovement>;

function MovementInOutToInt(AValue: TMovementInOut): Integer;
function IntToMovementInOut(AValue: Integer): TMovementInOut;

const
  ConfigPathConfiguration = '\Configuration';

function ReadConfigStringValue(const AConfigPath, AValueName: string): string;
function GetConfigPathSubPaths(const AConfigPath: string): TArray<string>;

implementation

uses
  System.SysUtils, uUtils, Winapi.Windows, uFuncUtils, Classes, uEnumeratorUtils, System.Win.Registry,
  uApp;

resourcestring
  SMovementAsText =
    'Source: %s' + SLineBreak +
    'Destination: %s' + SLineBreak +
    'Employee No: %d' + SLineBreak +
    'DateTime: %s' + SLineBreak +
    'InOut: %d';

const
  RegKeyEmployeeMovements = '\Software\%s\%sEmployeeMovements';

function GetRegKeyEmployeeMovements(): string;
begin
  Result:= Format(RegKeyEmployeeMovements, [SRootRegKeyName, SVendorName]);
end;

function MovementInOutToInt(AValue: TMovementInOut): Integer;
begin
  case AValue of
    mioIn: Result:= 1;
    mioOut: Result:= -1;
  else
    raise Exception.Create('Unknown MovementInOut');
  end;
end;

function IntToMovementInOut(AValue: Integer): TMovementInOut;
begin
  case AValue of
    1: Result:= mioIn;
    -1: Result:= mioOut;
  else
    raise Exception.Create('Unknown MovementInOut code');
  end;
end;

function ReadConfigStringValue(const AConfigPath, AValueName: string): string;
var
  RegistryKey: string;
begin
  RegistryKey:= GetRegKeyEmployeeMovements() + AConfigPath;
  Result:=
    Utils.Using(TRegistry.Create(KEY_READ))/
      function (Reg: TRegistry): string begin
        Reg.RootKey:= HKEY_LOCAL_MACHINE;
        if Reg.OpenKey(RegistryKey, False) then
          try
            if not Reg.ValueExists(AValueName) then
              raise Exception.CreateFmt('Registry value "%s" does not exist in key "%s"', [AValueName, RegistryKey]);

            if (Reg.GetDataType(AValueName) <> rdString) then
              raise Exception.CreateFmt('Registry value "%s" in key "%s" is not a string', [AValueName, RegistryKey]);

            Result:= Reg.ReadString(AValueName);
          finally
            Reg.CloseKey;
          end
        else
          raise Exception.CreateFmt('Cannot open registry key "%s"', [RegistryKey]);
      end;
end;

function GetConfigPathSubPaths(const AConfigPath: string): TArray<string>;
var
  Reg: TRegistry;
  RegistryKey: string;
  KeyNames: TStringList;
  KeyName: string;
begin
  RegistryKey:= GetRegKeyEmployeeMovements() + AConfigPath;
  Reg:= TRegistry.Create(KEY_READ);
  try
    Reg.RootKey:= HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(RegistryKey, False) then
      try
        KeyNames:= TStringList.Create;
        try
          Reg.GetKeyNames(KeyNames);

          SetLength(Result, 0);
          for KeyName in KeyNames do
            begin
              SetLength(Result, Length(Result) + 1);
              Result[Length(Result) - 1]:= AConfigPath + '\' + KeyName;
            end;
        finally
          FreeAndNil(KeyNames);
        end;
      finally
        Reg.CloseKey;
      end
    else
      raise Exception.CreateFmt('Cannot open registry key "%s"', [RegistryKey]);
  finally
    FreeAndNil(Reg);
  end;
end;

{ TEmployeeMovement }

function TEmployeeMovement.ToString: string;
begin
  Result:=
    Format(SMovementAsText, [
      SourceName,
      DestinationName,
      EmployeeNo,
      DateTimeToStr(MovementDateTime),
      MovementInOutToInt(InOut)]);
end;

end.
