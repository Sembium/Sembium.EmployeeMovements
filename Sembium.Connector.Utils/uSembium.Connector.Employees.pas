unit uSembium.Connector.Employees;

{$DEFINE USE_REST}

interface

uses
  uSembium.Connector.Utils;

type
  IEmployeeMovement = interface
    function GetEmployeeNo: Integer;
    function GetInOut: Integer;
    function GetMovementDateTime: TDateTime;
    property EmployeeNo: Integer read GetEmployeeNo;
    property InOut: Integer read GetInOut;
    property MovementDateTime: TDateTime read GetMovementDateTime;
  end;

type
  IEmployeesService = interface
    procedure AddEmployeeMovement(const AEmployeeNo, AInOut: Integer; const AMovementDateTime: TDateTime);
    procedure AddEmployeeMovements(const AMovements: TArray<IEmployeeMovement>);
  end;

function CreateEmployeeMovement(const AEmployeeNo, AInOut: Integer; const AMovementDateTime: TDateTime): IEmployeeMovement;
function CreateEmployeesService(const AConnectorToken: TSembiumConnectorToken): IEmployeesService;

implementation

uses
  System.SysUtils,
{$IFDEF USE_REST}
  REST.Json, REST.Types,
{$ENDIF}
  uSembium.Connector.Json;

type
  TEmployeeMovement = class(TInterfacedObject, IEmployeeMovement)
  strict private
    FInOut: Integer;
    FEmployeeNo: Integer;
    FMovementDateTime: TDateTime;
  public
    constructor Create(const AEmployeeNo, AInOut: Integer; const AMovementDateTime: TDateTime);
    function GetEmployeeNo: Integer;
    function GetInOut: Integer;
    function GetMovementDateTime: TDateTime;
  end;

type
  TEmployeesService = class(TInterfacedObject, IEmployeesService)
  strict private
    const SembiumConnectorServiceName = 'employees';
  strict private
    FSembiumConnectorToken: TSembiumConnectorToken;
  public
    constructor Create(const AConnectorToken: TSembiumConnectorToken);
    procedure AddEmployeeMovement(const AEmployeeNo, AInOut: Integer; const AMovementDateTime: TDateTime);
    procedure AddEmployeeMovements(const AMovements: TArray<IEmployeeMovement>);
  end;

function CreateEmployeeMovement(const AEmployeeNo, AInOut: Integer; const AMovementDateTime: TDateTime): IEmployeeMovement;
begin
  Result:= TEmployeeMovement.Create(AEmployeeNo, AInOut, AMovementDateTime);
end;

function CreateEmployeesService(const AConnectorToken: TSembiumConnectorToken): IEmployeesService;
begin
  Result:= TEmployeesService.Create(AConnectorToken);
end;

{ TEmployees }

procedure TEmployeesService.AddEmployeeMovement(const AEmployeeNo,
  AInOut: Integer; const AMovementDateTime: TDateTime);
begin
  PostToConnector(FSembiumConnectorToken, SembiumConnectorServiceName, 'AddEmployeeMovement', [
    TSembiumConnectorParam.Create('employeeNo', AEmployeeNo),
    TSembiumConnectorParam.Create('inOut', AInOut),
    TSembiumConnectorParam.Create('movementDateTime', AMovementDateTime)]);
end;

procedure TEmployeesService.AddEmployeeMovements(
  const AMovements: TArray<IEmployeeMovement>);
var
  Json: TObject;
  Movement: IEmployeeMovement;
  jo: TObject;
begin
  Json:= CreateJsonArray;
  try
    for Movement in AMovements do
      begin
{$IFDEF USE_REST}
        jo:= TJson.ObjectToJsonObject(Movement as TObject, [joDateFormatISO8601]);
{$ELSE}
        jo:= CreateJsonObject;
        try
          AddStringToJsonObject(jo, 'employeeNo', IntToStr(Movement.EmployeeNo));
          AddStringToJsonObject(jo, 'inOut', IntToStr(Movement.InOut));
          AddStringToJsonObject(jo, 'movementDateTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Movement.MovementDateTime));
        except
          jo.Free;
          raise;
        end;
{$ENDIF}

        AddItemToJsonArray(Json, jo);
      end;

    PostToConnector(FSembiumConnectorToken, SembiumConnectorServiceName, 'AddEmployeeMovements', [], JsonToString(Json), 'application/json');
  finally
    Json.Free;
  end;
end;

constructor TEmployeesService.Create(const AConnectorToken: TSembiumConnectorToken);
begin
  FSembiumConnectorToken:= AConnectorToken;
end;

{ TEmployeeMovement }

constructor TEmployeeMovement.Create(const AEmployeeNo, AInOut: Integer;
  const AMovementDateTime: TDateTime);
begin
  FEmployeeNo:= AEmployeeNo;
  FInOut:= AInOut;
  FMovementDateTime:= AMovementDateTime;
end;

function TEmployeeMovement.GetEmployeeNo: Integer;
begin
  Result:= FEmployeeNo;
end;

function TEmployeeMovement.GetInOut: Integer;
begin
  Result:= FInOut;
end;

function TEmployeeMovement.GetMovementDateTime: TDateTime;
begin
  Result:= FMovementDateTime;
end;

initialization

end.
