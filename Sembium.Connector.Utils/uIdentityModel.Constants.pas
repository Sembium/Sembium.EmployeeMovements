unit uIdentityModel.Constants;

interface

type
  HttpStatusCode = class sealed
    public const OK = 200;
  end;

type
  OidcConstants = class sealed
    public type AuthorizeRequest = class sealed
      public const Scope               = 'scope';
      public const ResponseType        = 'response_type';
      public const ClientId            = 'client_id';
      public const RedirectUri         = 'redirect_uri';
      public const State               = 'state';
      public const ResponseMode        = 'response_mode';
      public const Nonce               = 'nonce';
      public const Display             = 'display';
      public const Prompt              = 'prompt';
      public const MaxAge              = 'max_age';
      public const UiLocales           = 'ui_locales';
      public const IdTokenHint         = 'id_token_hint';
      public const LoginHint           = 'login_hint';
      public const AcrValues           = 'acr_values';
      public const CodeChallenge       = 'code_challenge';
      public const CodeChallengeMethod = 'code_challenge_method';
    end;

    public type AuthorizeResponse = class sealed
      public const Scope         = 'scope';
      public const Code          = 'code';
      public const AccessToken   = 'access_token';
      public const ExpiresIn     = 'expires_in';
      public const TokenType     = 'token_type';
      public const RefreshToken  = 'refresh_token';
      public const IdentityToken = 'id_token';
      public const State         = 'state';
      public const Error         = 'error';
    end;

    public type TokenRequest = class sealed
      public const GrantType           = 'grant_type';
      public const RedirectUri         = 'redirect_uri';
      public const ClientId            = 'client_id';
      public const ClientSecret        = 'client_secret';
      public const ClientAssertion     = 'client_assertion';
      public const ClientAssertionType = 'client_assertion_type';
      public const Assertion           = 'assertion';
      public const Code                = 'code';
      public const RefreshToken        = 'refresh_token';
      public const Scope               = 'scope';
      public const UserName            = 'username';
      public const Password            = 'password';
      public const CodeVerifier        = 'code_verifier';
      public const TokenType           = 'token_type';
      public const Algorithm           = 'token_type';
      public const Key                 = 'key';
    end;

    public type TokenResponse = class sealed
      public const AccessToken         = 'access_token';
      public const ExpiresIn           = 'expires_in';
      public const TokenType           = 'token_type';
      public const RefreshToken        = 'refresh_token';
      public const IdentityToken       = 'id_token';
      public const Error               = 'error';
      public const ErrorDescription    = 'error_description';
    end;

    public type GrantTypes = class sealed
      public const Password          = 'password';
      public const AuthorizationCode = 'authorization_code';
      public const ClientCredentials = 'client_credentials';
      public const RefreshToken      = 'refresh_token';
      public const Implicit          = 'implicit';
      public const Saml2Bearer       = 'urn:ietf:params:oauth:grant-type:saml2-bearer';
      public const JwtBearer         = 'urn:ietf:params:oauth:grant-type:jwt-bearer';
    end;
  end;

implementation

end.
