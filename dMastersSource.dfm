object dmMastersSource: TdmMastersSource
  OldCreateOrder = False
  Height = 225
  Width = 446
  object prvUnregisteredEmployeeMovements: TDataSetProvider
    DataSet = qryUnregisteredEmployeeMovements
    Exported = False
    Options = [poReadOnly, poUseQuoteChar]
    Left = 88
    Top = 112
  end
  object cdsUnregisteredEmployeeMovements: TAbmesClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'prvUnregisteredEmployeeMovements'
    Left = 88
    Top = 160
    object cdsUnregisteredEmployeeMovementsCARD_ID: TIntegerField
      FieldName = 'CARD_ID'
      Required = True
    end
    object cdsUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME: TSQLTimeStampField
      FieldName = 'MOVEMENT_DATE_TIME'
      Required = True
    end
    object cdsUnregisteredEmployeeMovementsTZONE: TIntegerField
      FieldName = 'TZONE'
      Required = True
    end
    object cdsUnregisteredEmployeeMovementsEMPLOYEE_NO_TEXT: TWideStringField
      FieldName = 'EMPLOYEE_NO_TEXT'
      Size = 100
    end
    object cdsUnregisteredEmployeeMovementsIN_OUT: TIntegerField
      FieldName = 'IN_OUT'
    end
    object cdsUnregisteredEmployeeMovementsDESTINATION_NAME: TWideStringField
      FieldName = 'DESTINATION_NAME'
      Size = 200
    end
  end
  object db: TSQLConnection
    ConnectionName = 'MSSQLConnection'
    DriverName = 'MSSQL'
    LoginPrompt = False
    Params.Strings = (
      'SchemaOverride=%.dbo'
      'DriverUnit=DBXMSSQL'
      
        'DriverPackageLoader=TDBXDynalinkDriverLoader,DBXCommonDriver150.' +
        'bpl'
      
        'DriverAssemblyLoader=Borland.Data.TDBXDynalinkDriverLoader,Borla' +
        'nd.Data.DbxCommonDriver,Version=15.0.0.0,Culture=neutral,PublicK' +
        'eyToken=91d62ebb5b0d1b1b'
      
        'MetaDataPackageLoader=TDBXMsSqlMetaDataCommandFactory,DbxMSSQLDr' +
        'iver150.bpl'
      
        'MetaDataAssemblyLoader=Borland.Data.TDBXMsSqlMetaDataCommandFact' +
        'ory,Borland.Data.DbxMSSQLDriver,Version=15.0.0.0,Culture=neutral' +
        ',PublicKeyToken=91d62ebb5b0d1b1b'
      'GetDriverFunc=getSQLDriverMSSQL'
      'LibraryName=dbxmss.dll'
      'VendorLib=sqlncli10.dll'
      'HostName=ServerName'
      'Database=Database Name'
      'MaxBlobSize=-1'
      'LocaleCode=0000'
      'IsolationLevel=ReadCommitted'
      'OSAuthentication=False'
      'PrepareSQL=True'
      'User_Name=user'
      'Password=password'
      'BlobSize=-1'
      'ErrorResourceFile='
      'OS Authentication=False'
      'Prepare SQL=False')
    BeforeConnect = dbBeforeConnect
    Left = 8
    Top = 8
  end
  object qryUnregisteredEmployeeMovements: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQL.Strings = (
      'select'
      '  io.CARD_ID,'
      '  io.DTIME as MOVEMENT_DATE_TIME,'
      '  io.TZONE,'
      '  p.TEL2 as EMPLOYEE_NO_TEXT,'
      '  case sz.IS_EXTERNAL'
      '    when '#39'Y'#39' then 1'
      '    when '#39'N'#39' then -1'
      '  end as IN_OUT,'
      '  p.ADDRESS as DESTINATION_NAME'
      ''
      'from'
      '  IN_OUT io,'
      '  CARDS c,'
      '  PERSONS p,'
      '  ZONE sz,'
      '  ZONE tz'
      ''
      'where'
      '  (io.HISTORY_ID = 0) and'
      ''
      '  (c.ID = io.CARD_ID) and'
      '  (p.ID = c.PERSON_ID) and'
      '  (sz.ID = io.SZONE) and'
      '  (tz.ID = io.TZONE) and'
      ''
      '  (tz.IS_EXTERNAL <> sz.IS_EXTERNAL)'
      ''
      'order by'
      '  MOVEMENT_DATE_TIME,'
      '  EMPLOYEE_NO_TEXT,'
      '  IN_OUT')
    SQLConnection = db
    Left = 88
    Top = 64
    object qryUnregisteredEmployeeMovementsCARD_ID: TIntegerField
      FieldName = 'CARD_ID'
      Required = True
    end
    object qryUnregisteredEmployeeMovementsMOVEMENT_DATE_TIME: TSQLTimeStampField
      FieldName = 'MOVEMENT_DATE_TIME'
      Required = True
    end
    object qryUnregisteredEmployeeMovementsTZONE: TIntegerField
      FieldName = 'TZONE'
      Required = True
    end
    object qryUnregisteredEmployeeMovementsEMPLOYEE_NO_TEXT: TWideStringField
      FieldName = 'EMPLOYEE_NO_TEXT'
      Size = 100
    end
    object qryUnregisteredEmployeeMovementsIN_OUT: TIntegerField
      FieldName = 'IN_OUT'
    end
    object qryUnregisteredEmployeeMovementsDESTINATION_NAME: TWideStringField
      FieldName = 'DESTINATION_NAME'
      Size = 200
    end
  end
  object qryMarkEmployeeMovementAsRegistered: TSQLQuery
    MaxBlobSize = -1
    Params = <
      item
        DataType = ftInteger
        Name = 'CARD_ID'
        ParamType = ptInput
      end
      item
        DataType = ftTimeStamp
        Name = 'DTIME'
        ParamType = ptInput
      end
      item
        DataType = ftInteger
        Name = 'TZONE'
        ParamType = ptInput
      end>
    SQL.Strings = (
      'update'
      '  IN_OUT'
      'set'
      '  HISTORY_ID = 1'
      'where'
      '  (CARD_ID = :CARD_ID) and'
      '  (DTIME = :DTIME) and'
      '  (TZONE = :TZONE)')
    SQLConnection = db
    Left = 304
    Top = 160
  end
  object qryPingSQLServer: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQL.Strings = (
      'select'
      '  Min(ID) as DUMMY'
      'from'
      '  PERSONS')
    SQLConnection = db
    Left = 304
    Top = 80
  end
end
