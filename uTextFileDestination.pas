unit uTextFileDestination;

interface

implementation

uses
  uEmployeeMovementDestination, uEmployeeMovementUtils, uEmployeeMovementEndpoint, SysUtils, IOUtils, Classes, uUtils;

resourcestring
  SEmployeeMovementLogEntry =
    '%s' + SLineBreak +
    SLineBreak +
    '-------------------------------' + SLineBreak +
    SLineBreak;

const
  STextFileDestinationTypeName = 'TextFile';
  ConfigValueFileName = 'FileName';

type
  TTextFileDestination = class(TEmployeeMovementDestination)
  strict private
    FFileName: string;
  protected
    procedure DoAddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement); override;
  public
    constructor Create(const AConfigPath: string); override;
  end;

{ TTextFileDestination }

constructor TTextFileDestination.Create(const AConfigPath: string);
var
  ConfigPath: string;
begin
  inherited Create(AConfigPath);

  ConfigPath:= AConfigPath + ConfigPathConfiguration;

  FFileName:= ReadConfigStringValue(ConfigPath, ConfigValueFileName);
end;

procedure TTextFileDestination.DoAddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement);
begin
  TFile.AppendAllText(FFileName, Format(SEmployeeMovementLogEntry, [AEmployeeMovement.ToString]), TEncoding.UTF8);
end;

initialization
  TEmployeeMovementEndpointTypeRepository.RegisterType(STextFileDestinationTypeName, TTextFileDestination);

end.
