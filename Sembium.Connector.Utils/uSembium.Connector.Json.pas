unit uSembium.Connector.Json;

interface

uses
  Variants, uLkJSON, SysUtils;

function ParseJsonString(const AJsonString: string): TObject;
function JsonToString(const AJson: TObject): string;

function GetJsonArrayLength(const AJsonArray: TObject): Integer;
function GetJsonArrayItem(const AJsonArray: TObject; const AIndex: Integer): TObject;

function GetJsonValue(const AJson: TObject; const AValueName: string): TObject;

function JsonValueToInt(const AJsonValue: TObject): Integer;
function JsonValueToInt64(const AJsonValue: TObject): Int64;
function JsonValueToDouble(const AJsonValue: TObject): Double;
function JsonValueToVarInt(const AJsonValue: TObject): Variant;
function JsonValueToVarInt64(const AJsonValue: TObject): Variant;
function JsonValueToVarDouble(const AJsonValue: TObject): Variant;
function JsonValueToString(const AJsonValue: TObject): string;
function JsonValueToBoolean(const AJsonValue: TObject): Boolean;

function CreateJsonObject: TObject;
procedure AddStringToJsonObject(const AJson: TObject; const AName, AValue: string);

function CreateJsonArray: TObject;
procedure AddItemToJsonArray(const AJson, AItem: TObject);

implementation

function ParseJsonString(const AJsonString: string): TObject;
begin
  Result:= TlkJSON.ParseText(AJsonString);
end;

function JsonToString(const AJson: TObject): string;
begin
  Result:= TlkJSON.GenerateText(AJson as TlkJSONobject);
end;

function GetJsonArrayLength(const AJsonArray: TObject): Integer;
begin
  if (AJsonArray = nil) then
    Result:= 0
  else
    Result:= (AJsonArray as TlkJSONlist).Count;
end;

function GetJsonArrayItem(const AJsonArray: TObject; const AIndex: Integer): TObject;
begin
  Result:= (AJsonArray as TlkJSONlist).Child[AIndex]
end;

function GetJsonValue(const AJson: TObject; const AValueName: string): TObject;
begin
  Result:= (AJson as TlkJSONobject).Field[AValueName];
end;

function JsonValueToInt(const AJsonValue: TObject): Integer;
begin
  Result:= (AJSonValue as TlkJSONnumber).Value;
end;

function JsonValueToInt64(const AJsonValue: TObject): Int64;
begin
  Result:= (AJSonValue as TlkJSONnumber).Value;
end;

function JsonValueToDouble(const AJsonValue: TObject): Double;
begin
  Result:= (AJSonValue as TlkJSONnumber).Value;
end;

function JsonValueToVarInt(const AJSonValue: TObject): Variant;
begin
  Result:= (AJSonValue as TlkJSONbase).Value;
end;

function JsonValueToVarInt64(const AJSonValue: TObject): Variant;
begin
  Result:= (AJSonValue as TlkJSONbase).Value;
end;

function JsonValueToVarDouble(const AJSonValue: TObject): Variant;
begin
  Result:= (AJSonValue as TlkJSONbase).Value;
end;

function JsonValueToString(const AJSonValue: TObject): string;
begin
  if VarIsNull((AJSonValue as TlkJSONbase).Value) then
    Result:= ''
  else
    Result:= (AJSonValue as TlkJSONstring).Value;
end;

function JsonValueToBoolean(const AJsonValue: TObject): Boolean;
begin
  Result:= (AJSonValue as TlkJSONboolean).Value;
end;

function CreateJsonObject: TObject;
begin
  Result:= TlkJSONobject.Create;
end;

procedure AddStringToJsonObject(const AJson: TObject; const AName, AValue: string);
begin
  (AJson as TlkJSONobject).Add(AName, AValue)
end;

function CreateJsonArray: TObject;
begin
  Result:= TlkJSONlist.Create;
end;

procedure AddItemToJsonArray(const AJson, AItem: TObject);
begin
  (AJson as TlkJSONlist).Add(AItem as TlkJSONbase);
end;

end.
