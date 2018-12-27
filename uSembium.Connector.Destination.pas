unit uSembium.Connector.Destination;

interface

implementation

uses
  SysUtils, uUtils, uEmployeeMovementDestination, uEmployeeMovementUtils, uEmployeeMovementEndpoint,
  uSembium.Connector.Employees, uSembium.Connector.Utils, System.TimeSpan, uApp;

type
  TSembiumConnectorDestination = class(TEmployeeMovementDestination)
  strict private
    FSembiumConnectorLocatorURL: string;
    FSembiumUserName: string;
    FSembiumPassword: string;
    FSembiumDatabase: string;
  private
    function GetSembiumConnectorToken: TSembiumConnectorToken;
    function GetSembiumConnectorClientApplication: TSembiumConnectorClientApplication;
  protected
    procedure DoAddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement); override;
  public
    constructor Create(const AConfigPath: string); override;
  end;

const
  SSembiumConnectorDestinationTypeName = 'Connector2';
  ConfigValueSembiumConnectorLocatorURL = 'ConnectorLocatorURL';
  ConfigValueSembiumUserName = 'UserName';
  ConfigValueSembiumPassword = 'Password';
  ConfigValueSembiumDatabase = 'Database';

{ TSembiumConnectorDestination }

constructor TSembiumConnectorDestination.Create(const AConfigPath: string);
var
  ConfigPath: string;
begin
  inherited Create(AConfigPath);

  ConfigPath:= AConfigPath + ConfigPathConfiguration;

  FSembiumConnectorLocatorURL:= ReadConfigStringValue(ConfigPath, SSembiumProductName + ConfigValueSembiumConnectorLocatorURL);
  FSembiumUserName:= ReadConfigStringValue(ConfigPath, SSembiumProductName + ConfigValueSembiumUserName);
  FSembiumPassword:= ReadConfigStringValue(ConfigPath, SSembiumProductName + ConfigValueSembiumPassword);
  FSembiumDatabase:= ReadConfigStringValue(ConfigPath, SSembiumProductName + ConfigValueSembiumDatabase);
end;

procedure TSembiumConnectorDestination.DoAddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement);
var
  EmployeesService: IEmployeesService;
begin

  EmployeesService:= CreateEmployeesService(GetSembiumConnectorToken);

  EmployeesService.AddEmployeeMovement(
    AEmployeeMovement.EmployeeNo,
    MovementInOutToInt(AEmployeeMovement.InOut),
    AEmployeeMovement.MovementDateTime
  );
end;

function TSembiumConnectorDestination.GetSembiumConnectorToken: TSembiumConnectorToken;
begin
  Result:=
    uSembium.Connector.Utils.GetConnectorToken(
      GetSembiumConnectorClientApplication,
      FSembiumUserName,
      FSembiumPassword,
      FSembiumDatabase,
      FSembiumConnectorLocatorURL);
end;

function TSembiumConnectorDestination.GetSembiumConnectorClientApplication: TSembiumConnectorClientApplication;
begin
  Result:=
    TSembiumConnectorClientApplication.Create(
      SembiumConnectorApplicationId,
      SembiumConnectorApplicationSecret
    );
end;

initialization
  TEmployeeMovementEndpointTypeRepository.RegisterType(SSembiumProductName + SSembiumConnectorDestinationTypeName, TSembiumConnectorDestination);

end.
