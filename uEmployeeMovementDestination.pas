unit uEmployeeMovementDestination;

interface

uses
  uEmployeeMovementEndpoint, uEmployeeMovementUtils;

type
  TEmployeeMovementDestination = class abstract(TEmployeeMovementEndpoint)
  protected
    procedure DoAddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement); virtual; abstract;
  public
    procedure AddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement);
  end;

implementation

uses
  SysUtils;

{ TEmployeeMovementDestination }

procedure TEmployeeMovementDestination.AddEmployeeMovement(const AEmployeeMovement: TEmployeeMovement);
begin
  Assert(UpperCase(AEmployeeMovement.DestinationName) = UpperCase(Name));
  DoAddEmployeeMovement(AEmployeeMovement);
end;

end.
