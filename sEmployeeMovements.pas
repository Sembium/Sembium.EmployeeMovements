unit sEmployeeMovements;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, uEmployeeMovementsProcessor, uRepeatingAction;

type
  TsvcEmployeeMovements = class(TService)
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceCreate(Sender: TObject);
  private
    FEmployeeMovementsProcessor: TEmployeeMovementsProcessor;
    FRepeatTransferEmployeeMovements: TRepeatingAction;
  public
    function GetServiceController: TServiceController; override;
  end;

var
  svcEmployeeMovements: TsvcEmployeeMovements;

implementation

uses
  uEmployeeMovementUtils, uApp;

const
  ConfigValueTimeIntervalInSeconds = 'TimeIntervalInSeconds';

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  svcEmployeeMovements.Controller(CtrlCode);
end;

{ TsvcEmployeeMovements }

function TsvcEmployeeMovements.GetServiceController: TServiceController;
begin
  Result:= ServiceController;
end;

procedure TsvcEmployeeMovements.ServiceCreate(Sender: TObject);
begin
  Name:= StringReplace(Name, 'svc', 'svc' + SVendorName, []);
  DisplayName:= SVendorName + ' ' + DisplayName;
end;

procedure TsvcEmployeeMovements.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FEmployeeMovementsProcessor:= TEmployeeMovementsProcessor.Create;

  FRepeatTransferEmployeeMovements:=
    TRepeatingAction.Create(
      StrToInt(ReadConfigStringValue('', ConfigValueTimeIntervalInSeconds)),
      procedure begin
        FEmployeeMovementsProcessor.TransferEmployeeMovements;
      end);
end;

procedure TsvcEmployeeMovements.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  FreeAndNil(FRepeatTransferEmployeeMovements);
  FreeAndNil(FEmployeeMovementsProcessor);
end;

end.
