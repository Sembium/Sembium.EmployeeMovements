unit uSembium.Connector.Utils;

{$DEFINE USE_REST}

interface

uses
  System.TimeSpan;

type
  TSembiumConnectorClientApplication = record
  private
    FApplicationId: string;
    FApplicationSecret: string;
  public
    constructor Create(const AApplicationId, AApplicationSecret: string);
    property ApplicationId: string read FApplicationId;
    property ApplicationSecret: string read FApplicationSecret;
  end;

type
  TSembiumConnectorToken = record
  strict private
    FAccessToken: string;
    FDBName: string;
    FURL: string;
  private
    property DBName: string read FDBName;
    property AccessToken: string read FAccessToken;
    property URL: string read FURL;
    constructor Create(
      const AConnectorClientApplication: TSembiumConnectorClientApplication;
      const ALoginName, APassword: string;
      const ADBName: string;
      const AConnectorLocatorURLs: string);
  end;

type
  TSembiumConnectorParam = record
  strict private
    FName: string;
    FValue: Variant;
  public
    constructor Create(const AName: string; const AValue: Variant);
    property Name: string read FName;
    property Value: Variant read FValue;
  end;

function GetConnectorToken(
  const AConnectorClientApplication: TSembiumConnectorClientApplication;
  const ALoginName, APassword: string;
  const ADBName: string;
  const AConnectorLocatorURLs: string): TSembiumConnectorToken;

function GetConnectorResult(
  const AConnectorToken: TSembiumConnectorToken;
  const AConnectorServiceName: string;
  const FunctionName: string;
  const Params: array of TSembiumConnectorParam): string;

procedure PostToConnector(
  const AConnectorToken: TSembiumConnectorToken;
  const AConnectorServiceName: string;
  const FunctionName: string;
  const Params: array of TSembiumConnectorParam;
  const ABodyContent: string = '';
  const ABodyContentType: string = '');

var
  ConnectorTokenCacheTimeout: TTimeSpan;

implementation

uses
  SysUtils, Classes, JclStrings, System.StrUtils, System.Variants,
  uIdentityModel.TokenClient,
{$IFDEF USE_REST}
  REST.Client, REST.Types,
{$ELSE}
  IdHTTP, IdSSLOpenSSL,
{$ENDIF}
  IPPeerClient, IPPeerCommon,  // these 2 units must be used in both cases
  System.Generics.Collections, System.SyncObjs, uComputerInfo, uApp;

function GetdentityServerHost: string;
begin
  Result:= SIdentityServerHost;
end;

function GetSembiumAccessToken(
  const AConnectorClientApplication: TSembiumConnectorClientApplication;
  const ALoginName, APassword: string): string;
var
  token: TTokenResponse;
begin
  token:=
    TTokenClient.RequestToken(
      GetdentityServerHost + '/connect/token',
      AConnectorClientApplication.ApplicationId,
      AConnectorClientApplication.ApplicationSecret,
      ALoginName,
      APassword);

  Result:= token.AccessToken;
end;

function GetConnectorURL(const AConnectorLocatorURLs: string): string;

  function SimpleHttpGet(const AUrl: string): string;
  {$IFDEF USE_REST}
  var
    LClient: TRESTClient;
    LRequest: TRESTRequest;
  begin
    LClient:= TRESTClient.Create(AUrl);
    try
      LRequest:= TRESTRequest.Create(LClient);
      LRequest.Method:= rmGET;
      LRequest.SynchronizedEvents:= False;

      LRequest.Execute;

      if (LRequest.Response.StatusCode >= 300) then
        raise Exception.Create('Error: ' + LRequest.Response.StatusCode.ToString + ' ' + LRequest.Response.StatusText + 'Content: ' + LRequest.Response.Content);

      Result:= LRequest.Response.Content;
    finally
      FreeAndNil(LClient);
    end;
  end;

  {$ELSE}

  var
    http: TIdHTTP;
    SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
  begin
    SSLIOHandler:= TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    try
      SSLIOHandler.SSLOptions.Method:= sslvTLSv1_2;
      SSLIOHandler.SSLOptions.Mode:= sslmUnassigned;

      http:= TIdHTTP.Create;
      try
        http.IOHandler:= SSLIOHandler;
        http.ReadTimeout:= 1000;  // milliseconds

        Result:= http.Get(AUrl);
      finally
        http.Free;
      end;
    finally
      SSLIOHandler.Free;
    end;
  end;
  {$ENDIF}

  function IsConnectorAvailable(const AConnectorURL: string): Boolean;
  begin
    Result:= True;
  end;

var
  Config: TStringList;
  ConnectorLocatorURL: string;
  ErrorMessages: string;
  ConnectorServiceURLs: string;
  ConnectorServiceURL: string;
begin
  ErrorMessages:= '';

  Config:= TStringList.Create;
  try
    for ConnectorLocatorURL in SplitString(AConnectorLocatorURLs, ';') do
      begin
        if not EndsText('.txt', ConnectorLocatorURL) then
          Exit(ConnectorLocatorURL);

        try
          Config.Text:= SimpleHttpGet(ConnectorLocatorURL);
          ConnectorServiceURLs:= Config.Values['URL'];
          for ConnectorServiceURL in SplitString(ConnectorServiceURLs, ';') do
            begin
              Result:= StrTrimCharRight(ConnectorServiceURL, '/');
              if IsConnectorAvailable(Result) then
                Exit;
            end;
        except
          on E: Exception do
            ErrorMessages:= ErrorMessages +
              Format('Error reading %s:', [ConnectorLocatorURL]) + SLineBreak +
              E.Message + SLineBreak;
        end;
      end;
  finally
    FreeAndNil(Config);
  end;

  raise Exception.Create(ErrorMessages);
end;

function ParamValueToStr(const AValue: Variant): string;
begin
  if VarIsType(AValue, varDate) then
    Result:= FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AValue)
  else
    Result:= AValue;
end;

function ParamsToQueryString(const Params: array of TSembiumConnectorParam): string;
var
  param: TSembiumConnectorParam;
begin
  Result:= '';
  for param in Params do
    Result:= Result + Format('&%s=%s', [param.Name, ParamValueToStr(param.Value)]);
  if (Result <> '') then
    Result:= Copy(Result, 2);
end;

function InternalGetConnectorResult(
  const AConnectorToken: TSembiumConnectorToken;
  const AConnectorServiceName: string;
  const ARequestMethod: string;
  const FunctionName: string;
  const Params: array of TSembiumConnectorParam;
  const ABodyContent, ABodyContentType: string): string;

{$IFDEF USE_REST}
  function GetRequestMethod(const AMethod: string): TRESTRequestMethod;
  var
    r: TRESTRequestMethod;
  begin
    for r:= Low(TRESTRequestMethod) to High(TRESTRequestMethod) do
      if SameText(RESTRequestMethodToString(r), AMethod) then
        Exit(r);

    raise Exception.CreateFmt('Unknown REST method: %s', [AMethod]);
  end;
{$ENDIF}

var
  url: string;
  query: string;
{$IFDEF USE_REST}
  LClient: TRESTClient;
  LRequest: TRESTRequest;
{$ELSE}
  http: TIdHTTP;
  ContentStream: TStringStream;
  ResponseStream: TStringStream;
  SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
{$ENDIF}
begin
  url:= AConnectorToken.URL.TrimRight(['/']) + '/api/' + AConnectorServiceName + '/' + FunctionName;

  query:= ParamsToQueryString(params);

  if (query <> '') then
    url:= url + '?' + query;

{$IFDEF USE_REST}

  LClient:= TRESTClient.Create(url);
  try
    LRequest:= TRESTRequest.Create(LClient);
    LRequest.Method:= GetRequestMethod(ARequestMethod);
    LRequest.SynchronizedEvents:= False;

    LRequest.AddAuthParameter('Authorization', 'Bearer ' + AConnectorToken.AccessToken, TRESTRequestParameterKind.pkHTTPHEADER,[TRESTRequestParameterOption.poDoNotEncode]);
    LRequest.AddParameter('DBName', AConnectorToken.DBName, TRESTRequestParameterKind.pkHTTPHEADER);

    if (ABodyContent <> '') then
      LRequest.Body.Add(ABodyContent, ContentTypeFromString(ABodyContentType));

    LRequest.Execute;

    if (LRequest.Response.StatusCode >= 300) then
      raise Exception.Create('Error: ' + LRequest.Response.StatusCode.ToString + ' ' + LRequest.Response.StatusText + 'Content: ' + LRequest.Response.Content);

    Result:= LRequest.Response.Content;
  finally
    FreeAndNil(LClient);
  end;

{$ELSE}

  SSLIOHandler:= TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  try
    SSLIOHandler.SSLOptions.Method:= sslvTLSv1_2;
    SSLIOHandler.SSLOptions.Mode:= sslmUnassigned;

    http:= TIdHTTP.Create;
    try
      http.IOHandler:= SSLIOHandler;

      http.Request.CustomHeaders.AddValue('Authorization', 'Bearer ' + AConnectorToken.AccessToken);
      http.Request.CustomHeaders.AddValue('DBName', AConnectorToken.DBName);

      http.Request.CustomHeaders.AddValue('ClientDeviceId', GetLocalComputerName);
      http.Request.CustomHeaders.AddValue('ClientOSSessionId', IntToStr(GetWindowsSessionId));
      http.Request.CustomHeaders.AddValue('ClientOSVersion', GetWindowsVersionString + '     ' + GetInternetExplorerVersionString);
      http.Request.CustomHeaders.AddValue('ClientHardwareInfo', GetHardwareInfo);

      ContentStream:= TStringStream.Create(ABodyContent);
      try
        ResponseStream:= TStringStream.Create('', TEncoding.UTF8);
        try
          if (ABodyContent <> '') then
            http.Request.ContentType:= ABodyContentType;

          try
            if SameText(ARequestMethod, Id_HTTPMethodGet) then
              begin
                http.Get(url, ResponseStream);
              end;

            if SameText(ARequestMethod, Id_HTTPMethodPost) then
              begin
                http.Post(url, ContentStream, ResponseStream);
              end;

            if SameText(ARequestMethod, Id_HTTPMethodPut) then
              begin
                http.Put(url, ContentStream, ResponseStream);
              end;

            if SameText(ARequestMethod, Id_HTTPMethodDelete) then
              begin
                http.Delete(url, ResponseStream);
              end;
          except
            on E: EIdHTTPProtocolException do
              raise Exception.Create(E.Message + SLineBreak + E.ErrorMessage);
          else
            raise
          end;

          Result:= ResponseStream.DataString;
        finally
          ResponseStream.Free;
        end;
      finally
        ContentStream.Free;
      end;
    finally
      http.Free;
    end;
  finally
    SSLIOHandler.Free;
  end;

{$ENDIF}
end;

type
  TConnectorTokenCacheKey = record
    ConnectorClientApplication: TSembiumConnectorClientApplication;
    LoginName: string;
    Password: string;
    DBName: string;
    ConnectorLocatorURLs: string;
    constructor Create(
      const AConnectorClientApplication: TSembiumConnectorClientApplication;
      const ALoginName, APassword: string;
      const ADBName: string;
      const AConnectorLocatorURLs: string);
    function ToString: string;
  end;

  TConnectorTokenCacheResult = record
    ConnectorToken: TSembiumConnectorToken;
    IssueMoment: TDateTime;
    constructor Create(const AConnectorToken: TSembiumConnectorToken; const AIssueMoment: TDateTime);
  end;

var
  ConnectorTokenCache: TDictionary<string, TConnectorTokenCacheResult>;
  ConnectorTokenCacheCriticalSection: TCriticalSection;

constructor TConnectorTokenCacheKey.Create(
  const AConnectorClientApplication: TSembiumConnectorClientApplication;
  const ALoginName, APassword: string;
  const ADBName: string;
  const AConnectorLocatorURLs: string);
begin
  ConnectorClientApplication:= AConnectorClientApplication;
  LoginName:= ALoginName;
  Password:= APassword;
  DBName:= ADBName;
  ConnectorLocatorURLs:= AConnectorLocatorURLs;
end;

function TConnectorTokenCacheKey.ToString: string;
begin
  Result:=
    ConnectorClientApplication.ApplicationId + '#' +
    ConnectorClientApplication.ApplicationSecret + '#' +
    LoginName + '#' +
    Password + '#' +
    DBName + '#' +
    ConnectorLocatorURLs;
end;

constructor TConnectorTokenCacheResult.Create(const AConnectorToken: TSembiumConnectorToken; const AIssueMoment: TDateTime);
begin
  ConnectorToken:= AConnectorToken;
  IssueMoment:= AIssueMoment;
end;

function GetConnectorToken(
  const AConnectorClientApplication: TSembiumConnectorClientApplication;
  const ALoginName, APassword: string;
  const ADBName: string;
  const AConnectorLocatorURLs: string): TSembiumConnectorToken;
var
  ConnectorTokenCacheKey: TConnectorTokenCacheKey;
  ConnectorTokenCacheResult: TConnectorTokenCacheResult;
  Found: Boolean;
begin
  ConnectorTokenCacheKey:=
    TConnectorTokenCacheKey.Create(
      AConnectorClientApplication,
      ALoginName, APassword,
      ADBName,
      AConnectorLocatorURLs);

  Found:= False;

  ConnectorTokenCacheCriticalSection.Enter;
  try
    if ConnectorTokenCache.TryGetValue(ConnectorTokenCacheKey.ToString, ConnectorTokenCacheResult) then
      begin
        if (TTimeSpan.Subtract(Now, ConnectorTokenCacheResult.IssueMoment) < ConnectorTokenCacheTimeout) then
          begin
            Result:= ConnectorTokenCacheResult.ConnectorToken;
            Found:= True;
          end;
      end;
  finally
    ConnectorTokenCacheCriticalSection.Leave;
  end;

  if not Found then
    begin
      Result:=
        TSembiumConnectorToken.Create(
          AConnectorClientApplication,
          ALoginName, APassword,
          ADBName,
          AConnectorLocatorURLs);

      ConnectorTokenCacheCriticalSection.Enter;
      try
        if ConnectorTokenCache.TryGetValue(ConnectorTokenCacheKey.ToString, ConnectorTokenCacheResult) then
          begin
            if (TTimeSpan.Subtract(Now, ConnectorTokenCacheResult.IssueMoment) < ConnectorTokenCacheTimeout) then
              begin
                Result:= ConnectorTokenCacheResult.ConnectorToken;
                Found:= True;
              end;
          end;

        if not Found then
          ConnectorTokenCache.AddOrSetValue(
            ConnectorTokenCacheKey.ToString,
            TConnectorTokenCacheResult.Create(Result, Now)
          );
      finally
        ConnectorTokenCacheCriticalSection.Leave;
      end;
    end;

  Assert(Result.DBName = ADBName);
end;

function GetConnectorResult(
  const AConnectorToken: TSembiumConnectorToken;
  const AConnectorServiceName: string;
  const FunctionName: string;
  const Params: array of TSembiumConnectorParam): string;
begin
  Result:= InternalGetConnectorResult(AConnectorToken, AConnectorServiceName, 'GET', FunctionName, Params, '', '');
end;

procedure PostToConnector(
  const AConnectorToken: TSembiumConnectorToken;
  const AConnectorServiceName: string;
  const FunctionName: string;
  const Params: array of TSembiumConnectorParam;
  const ABodyContent, ABodyContentType: string);
begin
  InternalGetConnectorResult(AConnectorToken, AConnectorServiceName, 'POST', FunctionName, Params, ABodyContent, ABodyContentType);
end;

{ TSembiumConnectorToken }

constructor TSembiumConnectorToken.Create(
  const AConnectorClientApplication: TSembiumConnectorClientApplication;
  const ALoginName, APassword: string;
  const ADBName: string;
  const AConnectorLocatorURLs: string);
begin
  FAccessToken:= GetSembiumAccessToken(AConnectorClientApplication, ALoginName, APassword);
  FDBName:= ADBName;
  FURL:= GetConnectorURL(AConnectorLocatorURLs);
end;

{ TSembiumConnectorClientApplication }

constructor TSembiumConnectorClientApplication.Create(const AApplicationId,
  AApplicationSecret: string);
begin
  FApplicationId:= AApplicationId;
  FApplicationSecret:= AApplicationSecret;
end;

{ TSembiumConectorParam }

constructor TSembiumConnectorParam.Create(const AName: string; const AValue: Variant);
begin
  FName:= AName;
  FValue:= AValue;
end;

initialization
  ConnectorTokenCacheTimeout:= TTimeSpan.FromHours(1);
  ConnectorTokenCacheCriticalSection:= TCriticalSection.Create;
  ConnectorTokenCache:= TDictionary<string, TConnectorTokenCacheResult>.Create();

finalization
  FreeAndNil(ConnectorTokenCache);
  FreeAndNil(ConnectorTokenCacheCriticalSection);

end.
