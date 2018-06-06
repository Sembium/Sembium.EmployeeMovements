unit dMastersSource;

interface

uses
  System.SysUtils, System.Classes, DBXMSSQL, Data.FMTBcd, Data.SqlExpr, Data.DB, Datasnap.DBClient, AbmesClientDataSet,
  Datasnap.Provider, uEmployeeMovementSource, SqlTimSt, Vcl.SvcMgr;

type
  TdmMastersSource = class(TDataModule)
    prvUnregisteredEmployeeMovements: TDataSetProvider;
    cdsUnregisteredEmployeeMovements: TAbmesClientDataSet;
    cdsUnregisteredEmployeeMovementsCARD_ID: TIntegerField;
    cdsUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME: TSQLTimeStampField;
    cdsUnregisteredEmployeeMovementsTZONE: TIntegerField;
    cdsUnregisteredEmployeeMovementsEMPLOYEE_NO_TEXT: TWideStringField;
    cdsUnregisteredEmployeeMovementsIN_OUT: TIntegerField;
    db: TSQLConnection;
    qryUnregisteredEmployeeMovements: TSQLQuery;
    qryUnregisteredEmployeeMovementsCARD_ID: TIntegerField;
    qryUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME: TSQLTimeStampField;
    qryUnregisteredEmployeeMovementsTZONE: TIntegerField;
    qryUnregisteredEmployeeMovementsEMPLOYEE_NO_TEXT: TWideStringField;
    qryUnregisteredEmployeeMovementsIN_OUT: TIntegerField;
    cdsUnregisteredEmployeeMovementsDESTINATION_NAME: TWideStringField;
    qryMarkEmployeeMovementAsRegistered: TSQLQuery;
    qryPingSQLServer: TSQLQuery;
    procedure dbBeforeConnect(Sender: TObject);
  private
    FSQLServerUserName: string;
    FSQLServerPassword: string;
    FSQLServerName: string;
    FSQLServerDatabase: string;
    procedure AcquireDBConnection;
    procedure ReleaseDBConnection;
    procedure MarkEmployeeMovementAsRegistered(ACardId: Integer; AMovementDateTime: TSQLTimeStamp;
      ATargetZone: Integer);
  public
    destructor Destroy; override;
  end;

implementation

uses
  uEmployeeMovementEndpoint, uEmployeeMovementUtils, System.Variants, Winapi.ActiveX;

type
  TMastersSource = class(TEmployeeMovementSource)
  private
    FdmMastersSource: TdmMastersSource;
    FEventLogger: TEventLogger;
  protected
    procedure DoMarkEmployeeMovementAsRegistered(const AEmployeeMovement: TEmployeeMovement); override;
  public
    constructor Create(const AConfigPath: string); override;
    destructor Destroy; override;
    function GetEmployeeMovements: TEmployeeMovements; override;
  end;

type
  TMastersMovementKey = class(TInterfacedObject, ISourceMovementKey)
  strict private
    FCardId: Integer;
    FMovementDateTime: TSQLTimeStamp;
    FTZone: Integer;
    function GetAsString: string;
  public
    constructor Create(ACardId: Integer; AMovementDateTime: TSQLTimeStamp; ATZone: Integer);
    property CardId: Integer read FCardId;
    property MovementDateTime: TSQLTimeStamp read FMovementDateTime;
    property TZone: Integer read FTZone;
    property AsString: string read GetAsString;
  end;

const
  SMastersSourceTypeName = 'Masters';

  ConfigValueSQLServerUserName = 'SQLServerUserName';
  ConfigValueSQLServerPassword = 'SQLServerPassword';
  ConfigValueSQLServerName = 'SQLServerName';
  ConfigValueSQLServerDatabase = 'SQLServerDatabase';

{$R *.dfm}

{ TMastersMovementKey }

constructor TMastersMovementKey.Create(ACardId: Integer; AMovementDateTime: TSQLTimeStamp; ATZone: Integer);
begin
  inherited Create;
  FCardId:= ACardId;
  FMovementDateTime:= AMovementDateTime;
  FTZone:= ATZone;
end;

function TMastersMovementKey.GetAsString: string;
begin
  Result:=
    Format(
      'CardId: %d' + SLineBreak + 'MovementDateTime: %s' + SLineBreak + 'TZone: %d',
      [FCardId, SQLTimeStampToStr('dd.mm.yyyy hh:nn:ss', FMovementDateTime), FTZone]);
end;

{ TdmMastersSource }

procedure TdmMastersSource.AcquireDBConnection;
begin
  if db.Connected then
    try
      qryPingSQLServer.Open;  // ping
      qryPingSQLServer.Close;  // pong
    except
      db.Close;
    end;  { try }

  db.Open;
end;

procedure TdmMastersSource.dbBeforeConnect(Sender: TObject);
begin
  db.Params.Values['User_Name']:= FSQLServerUserName;
  db.Params.Values['Password']:= FSQLServerPassword;
  db.Params.Values['HostName']:= FSQLServerName;
  db.Params.Values['DataBase']:= FSQLServerDatabase;
end;

procedure TdmMastersSource.ReleaseDBConnection;
begin
  db.Close;
end;

destructor TdmMastersSource.Destroy;
begin
  ReleaseDBConnection;
  inherited;
end;

procedure TdmMastersSource.MarkEmployeeMovementAsRegistered(ACardId: Integer; AMovementDateTime: TSQLTimeStamp;
  ATargetZone: Integer);
begin
  qryMarkEmployeeMovementAsRegistered.ParamByName('CARD_ID').AsInteger:= ACardId;
  qryMarkEmployeeMovementAsRegistered.ParamByName('DTIME').AsSQLTimeStamp:= AMovementDateTime;
  qryMarkEmployeeMovementAsRegistered.ParamByName('TZONE').AsInteger:= ATargetZone;

  qryMarkEmployeeMovementAsRegistered.ExecSQL;

  if (qryMarkEmployeeMovementAsRegistered.RowsAffected <> 1) then
    raise Exception.CreateFmt(
      'Marking employee movement affected %d rows',
      [qryMarkEmployeeMovementAsRegistered.RowsAffected]);
end;

{ TMastersSource }

constructor TMastersSource.Create(const AConfigPath: string);
var
  ConfigPath: string;
begin
  inherited Create(AConfigPath);

  CoInitialize(nil);

  FEventLogger:= TEventLogger.Create(ExtractFileName(ParamStr(0)));

  FdmMastersSource:= TdmMastersSource.Create(nil);

  ConfigPath:= AConfigPath + ConfigPathConfiguration;
  FdmMastersSource.FSQLServerUserName:= ReadConfigStringValue(ConfigPath, ConfigValueSQLServerUserName);
  FdmMastersSource.FSQLServerPassword:= ReadConfigStringValue(ConfigPath, ConfigValueSQLServerPassword);
  FdmMastersSource.FSQLServerName:= ReadConfigStringValue(ConfigPath, ConfigValueSQLServerName);
  FdmMastersSource.FSQLServerDatabase:= ReadConfigStringValue(ConfigPath, ConfigValueSQLServerDatabase);
end;

destructor TMastersSource.Destroy;
begin
  FreeAndNil(FdmMastersSource);
  FreeAndNil(FEventLogger);
  inherited;
end;

function TMastersSource.GetEmployeeMovements: TEmployeeMovements;

  function GetSourceMovementErrorText(const AMovement: TEmployeeMovement; E: Exception): string;
  const
    SLinesDelimiter = SLineBreak + '----------------------' + SLineBreak;
  begin
    Result:= 'Source Name: ' + Name + SLinesDelimiter;

    if Assigned(AMovement.SourceMovementKey) then
      Result:= Result + 'Movement Key: ' + SLineBreak + AMovement.SourceMovementKey.AsString + SLinesDelimiter;

    Result:= Result + 'Exception Message: ' + SLineBreak + E.Message + SLinesDelimiter;
  end;

  function GetEmployeeNo(AEmployeeNoField: TField): Integer;
  begin
    if (AEmployeeNoField.AsString = '') then
      raise Exception.Create('Employee No is Required');

    if not TryStrToInt(AEmployeeNoField.AsString, Result) then
      raise Exception.CreateFmt('"%s" is not a valid Employee No', [AEmployeeNoField.AsString]);
  end;

var
  Movement: TEmployeeMovement;
begin
  SetLength(Result, 0);
  with FdmMastersSource do
    begin
      AcquireDBConnection;

      cdsUnregisteredEmployeeMovements.Open;
      try
        while not cdsUnregisteredEmployeeMovements.Eof do
          begin
            Movement.SourceMovementKey:= nil;
            try
              Movement.SourceMovementKey:=
                TMastersMovementKey.Create(
                  cdsUnregisteredEmployeeMovementsCARD_ID.AsInteger,
                  cdsUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME.AsSQLTimeStamp,
                  cdsUnregisteredEmployeeMovementsTZONE.AsInteger);

              Movement.SourceName:= Self.Name;  // da stoi Self.Name zashtoto e vav "with"
              Movement.DestinationName:= cdsUnregisteredEmployeeMovementsDESTINATION_NAME.AsString;
              Movement.EmployeeNo:= GetEmployeeNo(cdsUnregisteredEmployeeMovementsEMPLOYEE_NO_TEXT);
              Movement.MovementDateTime:= cdsUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME.AsDateTime;
              Movement.InOut:= IntToMovementInOut(cdsUnregisteredEmployeeMovementsIN_OUT.AsInteger);

              SetLength(Result, Length(Result) + 1);
              Result[Length(Result) - 1]:= Movement;
            except
              on E: Exception do
                FEventLogger.LogMessage(GetSourceMovementErrorText(Movement, E));
            end;

            cdsUnregisteredEmployeeMovements.Next;
          end;
      finally
        cdsUnregisteredEmployeeMovements.Close;
      end;
    end;
end;

procedure TMastersSource.DoMarkEmployeeMovementAsRegistered(const AEmployeeMovement: TEmployeeMovement);
begin
  FdmMastersSource.AcquireDBConnection;
  with (AEmployeeMovement.SourceMovementKey as TMastersMovementKey) do
    FdmMastersSource.MarkEmployeeMovementAsRegistered(CardId, MovementDateTime, TZone);
end;

initialization
  TEmployeeMovementEndpointTypeRepository.RegisterType(SMastersSourceTypeName, TMastersSource);

end.
