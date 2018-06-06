unit uEmployeeMovementEndpoint;

interface

uses
  Generics.Collections;

type
  TEmployeeMovementEndpoint = class abstract
  strict private
    FName: string;
  public
    constructor Create(const AConfigPath: string); virtual;
    property Name: string read FName;
  end;

  TEmployeeMovementEndpointClass = class of TEmployeeMovementEndpoint;

type
  TEmployeeMovementEndpoints<T: TEmployeeMovementEndpoint> = class(TObjectList<T>)
  public
    function ByName(const AName: string; ACaseSensitive: Boolean = False): T;
  end;

type
  TEmployeeMovementEndpointTypeRepository = class
  strict private
    class var FTypes: TDictionary<string, TEmployeeMovementEndpointClass>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterType(const ATypeName: string; AType: TEmployeeMovementEndpointClass);
    class function GetType(const ATypeName: string): TEmployeeMovementEndpointClass;
  end;

type
  TEmployeeMovementEndpointsCreator<T: TEmployeeMovementEndpoint> = class
  strict private
    class function IsEndpointEnabled(const AConfigPath: string): Boolean;
    class function CreateEndpoint(const AConfigPath: string): T;
  public
    class function GetEndpoints(const AConfigPath: string): TEmployeeMovementEndpoints<T>;
  end;

implementation

uses
  SysUtils, uEmployeeMovementUtils, uFuncUtils;

{ TEmployeeMovementEndpoint }

constructor TEmployeeMovementEndpoint.Create(const AConfigPath: string);
const
  ConfigValueName = 'Name';
begin
  inherited Create;
  FName:= ReadConfigStringValue(AConfigPath, ConfigValueName);
end;

{ TEmployeeMovementEndpoints<T> }

function TEmployeeMovementEndpoints<T>.ByName(const AName: string; ACaseSensitive: Boolean): T;
var
  Endpoint: T;
begin
  for Endpoint in Self do
    if (ACaseSensitive and (Endpoint.Name = AName)) or
       (not ACaseSensitive and (UpperCase(Endpoint.Name) = UpperCase(AName))) then
      begin
        Exit(Endpoint);
      end;

  raise Exception.CreateFmt('Unknown Endpoint "%s"', [AName]);
end;

{ TEmployeeMovementEndpointTypeRepository }

class constructor TEmployeeMovementEndpointTypeRepository.Create;
begin
  FTypes:= TDictionary<string, TEmployeeMovementEndpointClass>.Create;
end;

class destructor TEmployeeMovementEndpointTypeRepository.Destroy;
begin
  FreeAndNil(FTypes);
end;

class procedure TEmployeeMovementEndpointTypeRepository.RegisterType(const ATypeName: string; AType: TEmployeeMovementEndpointClass);
begin
  FTypes.Add(UpperCase(ATypeName), AType);
end;

class function TEmployeeMovementEndpointTypeRepository.GetType(const ATypeName: string): TEmployeeMovementEndpointClass;
begin
  Result:= FTypes[UpperCase(ATypeName)];
end;

{ TEmployeeMovementEndpointsCreator<T> }

class function TEmployeeMovementEndpointsCreator<T>.IsEndpointEnabled(const AConfigPath: string): Boolean;
const
  ConfigValueEnabled = 'Enabled';
begin
  Result:= StrToBoolDef(ReadConfigStringValue(AConfigPath, ConfigValueEnabled), False);
end;

class function TEmployeeMovementEndpointsCreator<T>.GetEndpoints(const AConfigPath: string): TEmployeeMovementEndpoints<T>;
var
  ChildConfigPath: string;
begin
  Result:= TEmployeeMovementEndpoints<T>.Create;
  try
    for ChildConfigPath in GetConfigPathSubPaths(AConfigPath) do
      if IsEndpointEnabled(ChildConfigPath) then
        Result.Add(CreateEndpoint(ChildConfigPath));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

class function TEmployeeMovementEndpointsCreator<T>.CreateEndpoint(const AConfigPath: string): T;
const
  ConfigValueType = 'Type';
var
  Endpoint: TEmployeeMovementEndpoint;
  TypeName: string;
begin
  TypeName:= ReadConfigStringValue(AConfigPath, ConfigValueType);
  Endpoint:= TEmployeeMovementEndpointTypeRepository.GetType(TypeName).Create(AConfigPath);
  try
    if not (Endpoint is T) then
      raise Exception.CreateFmt('Incorrect Type of Endpoint "%s" of type "%s"', [Endpoint.Name, TypeName]);

    Result:= (Endpoint as T);
  except
    FreeAndNil(Endpoint);
    raise;
  end;
end;

end.
