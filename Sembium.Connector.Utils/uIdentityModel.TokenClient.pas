unit uIdentityModel.TokenClient;

{$DEFINE USE_REST}

interface

uses
  uSembium.Connector.Json;

{$SCOPEDENUMS ON}

type
  TAuthenticationStyle =
  (
    BasicAuthentication,
    PostValues,
    None
  );

type
  TTokenResponse = record
  private
    FRaw: string;
    FJson: TObject;  // memory leak !!! nikoj ne go oswobojdava
    function GetString(const AName: string): string;
    function GetInt(const AName: string): Integer;
    function GetAccessToken: string;
    function GetIdentityToken: string;
    function GetError: string;
    function GetIsError: Boolean;
    function GetExpiresIn: Integer;
    function GetTokenType: string;
    function GetRefreshToken: string;
  public
    constructor Create(const ARaw: string);
    property Raw: string read FRaw;
    property AccessToken: string read GetAccessToken;
    property IdentityToken: string read GetIdentityToken;
    property Error: string read GetError;
    property IsError: Boolean read GetIsError;
    property ExpiresIn: Integer read GetExpiresIn;
    property TokenType: string read GetTokenType;
    property RefreshToken: string read GetRefreshToken;
  end;

type
  TTokenClient = class
  public
    class function RequestToken(
      AAddress: string;
      AClientId: string;
      AClientSecret: string;
      AUserName: string;
      APassword: string;
      AScope: string = '';
      AAuthenticationStyle: TAuthenticationStyle = TAuthenticationStyle.BasicAuthentication;
      AExtra: TObject = nil): TTokenResponse;
  end;

implementation

uses
  System.SysUtils,
{$IFDEF USE_REST}
  REST.Client, REST.Types, REST.Authenticator.Basic,
{$ELSE}
  IdHTTP, System.Classes, IdSSLOpenSSL,
{$ENDIF}
  uIdentityModel.Constants;

{ TTokenClient }

class function TTokenClient.RequestToken(
  AAddress: string;
  AClientId: string;
  AClientSecret: string;
  AUserName: string;
  APassword: string;
  AScope: string;
  AAuthenticationStyle: TAuthenticationStyle;
  AExtra: TObject): TTokenResponse;
var
{$IFDEF USE_REST}
  LClient: TRESTClient;
  LAuthenticator: THTTPBasicAuthenticator;
  LRequest: TRESTRequest;
{$ELSE}
  http: TIdHTTP;
  ResponseStream: TStringStream;
  ContentStream: TStringStream;
  boundary: string;
  SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;

  procedure AddParam(const AParamName, AParamValue: string; const AParams: TStringList);
  begin
    AParams.Add('--' + boundary);
    AParams.Add(Format('Content-Disposition: form-data; name="%s"', [AParamName]));
    AParams.Add('');
    AParams.Add(AParamValue);
  end;

  function GetParamsContent(const ABoundary: string): string;
  var
    Params: TStringList;
  begin
    Params:= TStringList.Create;
    try
      AddPAram(OidcConstants.TokenRequest.GrantType, OidcConstants.GrantTypes.Password, Params);
      AddPAram(OidcConstants.TokenRequest.UserName, AUserName, Params);
      AddPAram(OidcConstants.TokenRequest.Password, APassword, Params);
      Params.Add('--' + boundary + '--');

      Result:= Params.Text;
    finally
      Params.Free;
    end;
  end;
{$ENDIF}

begin
  Assert(AAddress <> '');
  Assert(AClientId <> '');

{$IFDEF USE_REST}

  LClient:= TRESTClient.Create(AAddress);
  try
    LRequest := TRESTRequest.Create(LClient);
    LRequest.Accept:= 'application/json';
    LRequest.Timeout:= 25000;

    LRequest.AddParameter(OidcConstants.TokenRequest.GrantType, OidcConstants.GrantTypes.Password);
    LRequest.AddParameter(OidcConstants.TokenRequest.UserName, AUserName);
    LRequest.AddParameter(OidcConstants.TokenRequest.Password, APassword);

    if not string.IsNullOrWhiteSpace(AScope) then
      LRequest.AddParameter(OidcConstants.TokenRequest.Scope, AScope);

    if (AAuthenticationStyle = TAuthenticationStyle.BasicAuthentication) then
      begin
        LAuthenticator:= THTTPBasicAuthenticator.Create(LClient);
        LAuthenticator.Username:= AClientId;
        LAuthenticator.Password:= AClientSecret;
        LClient.Authenticator:= LAuthenticator;
      end;

    if (AAuthenticationStyle = TAuthenticationStyle.PostValues) then
      begin
        LRequest.AddParameter(OidcConstants.TokenRequest.ClientId, AClientId);

        if not string.IsNullOrWhiteSpace(AClientSecret) then
            LRequest.AddParameter(OidcConstants.TokenRequest.ClientSecret, AClientSecret);
      end;

    if Assigned(AExtra) then
      LRequest.Params.AddObject(AExtra);

    LRequest.Method:= TRESTRequestMethod.rmPOST;

    LRequest.Execute;

    if (LRequest.Response.StatusCode >= 300) then
      raise Exception.Create(
        'Error: ' + LRequest.Response.StatusCode.ToString + ' ' + LRequest.Response.StatusText + SLineBreak +
        'Content: ' + LRequest.Response.Content);

    Result:= TTokenResponse.Create(LRequest.Response.Content);
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

      http.Request.Accept:= 'application/json';
      http.Request.AcceptEncoding:= 'gzip, deflate';
      http.ReadTimeout:= 25000;

      boundary:= '--------------------------457955866935001821245284';
      http.Request.ContentType:= 'multipart/form-data; boundary=' + boundary;

      if not string.IsNullOrWhiteSpace(AScope) then
        http.Request.CustomHeaders.AddValue(OidcConstants.TokenRequest.Scope, AScope);


      if (AAuthenticationStyle = TAuthenticationStyle.BasicAuthentication) then
        begin
          http.Request.BasicAuthentication:= True;
          http.Request.Username:= AClientId;
          http.Request.Password:= AClientSecret;
        end;

      if (AAuthenticationStyle = TAuthenticationStyle.PostValues) then
        begin
          http.Request.CustomHeaders.AddValue(OidcConstants.TokenRequest.ClientId, AClientId);

          if not string.IsNullOrWhiteSpace(AClientSecret) then
            http.Request.CustomHeaders.AddValue(OidcConstants.TokenRequest.ClientSecret, AClientSecret);
        end;

      if Assigned(AExtra) then
        http.Request.CustomHeaders.AddObject('', AExtra);

      ContentStream:= TStringStream.Create(GetParamsContent(boundary));
      try
        ResponseStream := TStringStream.Create('', TEncoding.UTF8);
        try
          try
            http.Post(AAddress, ContentStream, ResponseStream);
          except 
            on E: EIdHTTPProtocolException do
              raise Exception.Create(E.Message + SLineBreak + E.ErrorMessage);
          else
            raise
          end;
  
          Result:= TTokenResponse.Create(ResponseStream.DataString);
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

{ TTokenResponse }

constructor TTokenResponse.Create(const ARaw: string);
begin
  FRaw:= ARaw;
  FJson:= ParseJsonString(ARaw);
  Assert(Assigned(FJson));
end;

function TTokenResponse.GetString(const AName: string): string;
begin
  Assert(Assigned(FJson));
  Result:= JsonValueToString(GetJsonValue(FJson, AName));
end;

function TTokenResponse.GetInt(const AName: string): Integer;
begin
  Assert(Assigned(FJson));
  Result:= JsonValueToInt(GetJsonValue(FJson, AName));
end;

function TTokenResponse.GetAccessToken: string;
begin
  Result:= GetString(OidcConstants.TokenResponse.AccessToken);
end;

function TTokenResponse.GetIdentityToken: string;
begin
  Result:= GetString(OidcConstants.TokenResponse.IdentityToken);
end;

function TTokenResponse.GetError: string;
begin
  Result:= GetString(OidcConstants.TokenResponse.Error);
end;

function TTokenResponse.GetIsError: Boolean;
begin
  Result:= not string.IsNullOrEmpty(GetString(OidcConstants.TokenResponse.Error));
end;

function TTokenResponse.GetExpiresIn: Integer;
begin
  Result:= GetInt(OidcConstants.TokenResponse.ExpiresIn);
end;

function TTokenResponse.GetTokenType: string;
begin
  Result:= GetString(OidcConstants.TokenResponse.TokenType);
end;

function TTokenResponse.GetRefreshToken: string;
begin
  Result:= GetString(OidcConstants.TokenResponse.RefreshToken);
end;

end.
