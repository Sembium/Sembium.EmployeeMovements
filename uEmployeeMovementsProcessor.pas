unit uEmployeeMovementsProcessor;

interface

uses
  uEmployeeMovementEndpoint, uEmployeeMovementDestination, uEmployeeMovementSource, uEmployeeMovementUtils, SvcMgr, System.SysUtils;

type
  TEmployeeMovementsProcessor = class
  private
    FSources: TEmployeeMovementEndpoints<TEmployeeMovementSource>;
    FDestinations: TEmployeeMovementEndpoints<TEmployeeMovementDestination>;
    FEventLogger: TEventLogger;
    procedure DoProcessingError(AException: Exception; const ACustomMessage: string);
    procedure TryTransferEmployeeMovements(ASource: TEmployeeMovementSource);
    procedure TransferEmployeeMovements(ASource: TEmployeeMovementSource); overload;
    procedure TryTransferEmployeeMovement(const AMovement: TEmployeeMovement);
    procedure TransferEmployeeMovement(const AMovement: TEmployeeMovement);
    procedure AddEmployeeMovementInDestination(const AMovement: TEmployeeMovement);
    procedure MarkEmployeeMovementAsRegisteredInSource(const AMovement: TEmployeeMovement);
  public
    constructor Create;
    destructor Destroy; override;
    procedure TransferEmployeeMovements; overload;
  end;

implementation

resourcestring
  SProcessingError =
    '%s' + SLineBreak +
    'Exception message:' + SLineBreak +
    '%s';

  SFailedToProcessMovement =
    'Failed to process EmployeeMovement:' + SLineBreak +
    '%s';

  SFailedToProcessSource = 'Failed to process Source: %s';

const
  ConfigPathDestinations = '\Destinations';
  ConfigPathSources = '\Sources';

{ TEmployeeMovementsProcessor }

constructor TEmployeeMovementsProcessor.Create;
begin
  inherited;

  FEventLogger:= TEventLogger.Create(ExtractFileName(ParamStr(0)));

  FSources:= TEmployeeMovementEndpointsCreator<TEmployeeMovementSource>.GetEndpoints(ConfigPathSources);
  FDestinations:= TEmployeeMovementEndpointsCreator<TEmployeeMovementDestination>.GetEndpoints(ConfigPathDestinations);
end;

destructor TEmployeeMovementsProcessor.Destroy;
begin
  FreeAndNil(FDestinations);
  FreeAndNil(FSources);

  FreeAndNil(FEventLogger);

  inherited;
end;

procedure TEmployeeMovementsProcessor.DoProcessingError(AException: Exception; const ACustomMessage: string);
begin
  FEventLogger.LogMessage(Format(SProcessingError, [ACustomMessage, AException.Message]));
end;

procedure TEmployeeMovementsProcessor.TransferEmployeeMovements;
var
  Source: TEmployeeMovementSource;
begin
  for Source in FSources do
    TryTransferEmployeeMovements(Source);
end;

procedure TEmployeeMovementsProcessor.TryTransferEmployeeMovements(ASource: TEmployeeMovementSource);
begin
  try
    TransferEmployeeMovements(ASource);
  except
    on E: Exception do
      DoProcessingError(E, Format(SFailedToProcessSource, [ASource.Name]));
  end;
end;

procedure TEmployeeMovementsProcessor.TransferEmployeeMovements(ASource: TEmployeeMovementSource);
var
  Movement: TEmployeeMovement;
begin
  for Movement in ASource.GetEmployeeMovements do
    TryTransferEmployeeMovement(Movement);
end;

procedure TEmployeeMovementsProcessor.TryTransferEmployeeMovement(const AMovement: TEmployeeMovement);
begin
  try
    TransferEmployeeMovement(AMovement);
  except
    on E: Exception do
      DoProcessingError(E, Format(SFailedToProcessMovement, [AMovement.ToString]));
  end;
end;

procedure TEmployeeMovementsProcessor.TransferEmployeeMovement(const AMovement: TEmployeeMovement);
begin
  AddEmployeeMovementInDestination(AMovement);
  MarkEmployeeMovementAsRegisteredInSource(AMovement);
end;

procedure TEmployeeMovementsProcessor.AddEmployeeMovementInDestination(const AMovement: TEmployeeMovement);
var
  Destination: TEmployeeMovementDestination;
begin
  Destination:= FDestinations.ByName(AMovement.DestinationName);
  Destination.AddEmployeeMovement(AMovement);
end;

procedure TEmployeeMovementsProcessor.MarkEmployeeMovementAsRegisteredInSource(const AMovement: TEmployeeMovement);
var
  Source: TEmployeeMovementSource;
begin
  Source:= FSources.ByName(AMovement.SourceName);
  Source.MarkEmployeeMovementAsRegistered(AMovement);
end;

end.
