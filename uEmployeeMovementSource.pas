unit uEmployeeMovementSource;

interface

uses
  uEmployeeMovementEndpoint, uEmployeeMovementUtils;

type
  TEmployeeMovementSource = class abstract(TEmployeeMovementEndpoint)
  protected
    procedure DoMarkEmployeeMovementAsRegistered(const AEmployeeMovement: TEmployeeMovement); virtual; abstract;
  public
    function GetEmployeeMovements: TEmployeeMovements; virtual; abstract;
    procedure MarkEmployeeMovementAsRegistered(const AEmployeeMovement: TEmployeeMovement);
  end;

implementation

uses
  SysUtils;

{ TEmployeeMovementSource }

procedure TEmployeeMovementSource.MarkEmployeeMovementAsRegistered(const AEmployeeMovement: TEmployeeMovement);
begin
  Assert(UpperCase(AEmployeeMovement.SourceName) = UpperCase(Name));
  DoMarkEmployeeMovementAsRegistered(AEmployeeMovement);
end;

end.
