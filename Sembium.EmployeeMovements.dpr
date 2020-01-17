program Sembium.EmployeeMovements;

uses
  ComObj,
  SvcMgr,
  MidasLib,
  sEmployeeMovements in 'sEmployeeMovements.pas' {svcEmployeeMovements: TService},
  uUtils in '..\src\Common\uUtils.pas',
  uNestProc in '..\src\Common\uNestProc.pas',
  uFuncUtils in '..\src\Common\uFuncUtils.pas',
  uEnumeratorUtils in '..\src\Common\uEnumeratorUtils.pas',
  uServerMessageIds in '..\src\Common\uServerMessageIds.pas',
  uRttiUtils in '..\src\Common\uRttiUtils.pas',
  uSystemLocaleUtils in '..\src\Common\uSystemLocaleUtils.pas',
  uEmployeeMovementDestination in 'uEmployeeMovementDestination.pas',
  uEmployeeMovementUtils in 'uEmployeeMovementUtils.pas',
  uEmployeeMovementSource in 'uEmployeeMovementSource.pas',
  dMastersSource in 'dMastersSource.pas' {dmMastersSource: TDataModule},
  uEmployeeMovementsProcessor in 'uEmployeeMovementsProcessor.pas',
  uRepeatingAction in 'uRepeatingAction.pas',
  uEmployeeMovementEndpoint in 'uEmployeeMovementEndpoint.pas',
  uTextFileDestination in 'uTextFileDestination.pas',
  uSembium.Connector.Destination in 'uSembium.Connector.Destination.pas',
  uSembium.Connector.Employees in 'Sembium.Connector.Utils\uSembium.Connector.Employees.pas',
  uSembium.Connector.Utils in 'Sembium.Connector.Utils\uSembium.Connector.Utils.pas',
  uSembium.Connector.Json in 'Sembium.Connector.Utils\uSembium.Connector.Json.pas',
  uLkJSON in 'Sembium.Connector.Utils\uLkJSON.pas',
  uIdentityModel.Constants in 'Sembium.Connector.Utils\uIdentityModel.Constants.pas',
  uIdentityModel.TokenClient in 'Sembium.Connector.Utils\uIdentityModel.TokenClient.pas',
  uComputerInfo in '..\src\Common\uComputerInfo.pas',
  uApp in '..\App\EmployeeMovements\uApp.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TsvcEmployeeMovements, svcEmployeeMovements);
  Application.Run;
end.
