object svcEmployeeMovements: TsvcEmployeeMovements
  OldCreateOrder = False
  OnCreate = ServiceCreate
  AllowPause = False
  DisplayName = 'Employee Movements'
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 78
  Width = 179
end
