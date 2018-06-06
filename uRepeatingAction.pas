unit uRepeatingAction;

interface

uses
  SysUtils, ExtCtrls;

type
  TRepeatingAction = class
  private
    FTimer: TTimer;
    FProc: TProc;
    procedure TimerTick(Sender: TObject);
  public
    constructor Create(ATimeIntervalInSeconds: Integer; const AProc: TProc);
    destructor Destroy; override;
  end;

implementation

{ TRepeatingAction }

constructor TRepeatingAction.Create(ATimeIntervalInSeconds: Integer; const AProc: TProc);
begin
  inherited Create;

  FProc:= AProc;

  FTimer:= TTimer.Create(nil);
  FTimer.Interval:= ATimeIntervalInSeconds * 1000;
  FTimer.OnTimer:= TimerTick;
  FTimer.Enabled:= True;
end;

destructor TRepeatingAction.Destroy;
begin
  if Assigned(FTimer) then
    FTimer.Enabled:= False;

  FreeAndNil(FTimer);

  inherited Destroy;
end;

procedure TRepeatingAction.TimerTick(Sender: TObject);
begin
  FProc;
end;

end.
