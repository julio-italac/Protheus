#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UP29634
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UP29634( cEmpAmb, cFilAmb )

Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   cMsg      := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk

	If FindFunction( "MPDicInDB" ) .AND. MPDicInDB()
		cMsg := "Este update NÃO PODE ser executado neste Ambiente." + CRLF + CRLF + ;
				"Os arquivos de dicionários se encontram no Banco de Dados e este update está preparado " + ;
				"para atualizar apenas ambientes com dicionários no formato ISAM (.dbf ou .dtc)."

		If lAuto
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( cMsg )
			ConOut( DToC(Date()) + "|" + Time() + cMsg )
		Else
			MsgInfo( cMsg )
		EndIf

		Return NIL
	EndIf

	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else

		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgStop( "Atualização Realizada.", "UP29634" )
				Else
					MsgStop( "Atualização não Realizada.", "UP29634" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualização Realizada." )
				Else
					Final( "Atualização não Realizada." )
				EndIf
			EndIf

		Else
			Final( "Atualização não Realizada." )

		EndIf

	Else
		Final( "Atualização não Realizada." )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// Só adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetType( 3 )
			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Versão.............: " + GetVersao(.T.) )
			AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Estação............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )

			//------------------------------------
			// Atualiza o dicionário SX2
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX2()

			//------------------------------------
			// Atualiza o dicionário SX3
			//------------------------------------
			FSAtuSX3()

			//------------------------------------
			// Atualiza o dicionário SIX
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/índices" )

			// Alteração física dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			//------------------------------------
			// Atualiza os helps
			//------------------------------------
			oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuHlp()

			//==================================================================
			// Atualiza a tabela ZG5 com as condições utilizadas nas legendas.
			//==================================================================
			Atuliz_ZG5()

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
Local aEstrut   := {}
Local aSX2      := {}
Local cAlias    := ""
Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
Local cEmpr     := ""
Local cPath     := ""
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
             "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
             "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


dbSelectArea( "SX2" )
SX2->( dbSetOrder( 1 ) )
SX2->( dbGoTop() )
cPath := SX2->X2_PATH
cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

//
// Tabela ZY8
//
aAdd( aSX2, { ;
	'ZY8'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'ZY8'+cEmpr																, ; //X2_ARQUIVO
	'Monitor Pedidos Vendas Itens P'										, ; //X2_NOME
	''																		, ; //X2_NOMESPA
	''																		, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSX2 ) )

dbSelectArea( "SX2" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX2 )

	oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

	If !SX2->( dbSeek( aSX2[nI][1] ) )

		If !( aSX2[nI][1] $ cAlias )
			cAlias += aSX2[nI][1] + "/"
			AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .T. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
					FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
				Else
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf
			EndIf
		Next nJ
		MsUnLock()

	Else

		If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
			RecLock( "SX2", .F. )
			SX2->X2_UNICO := aSX2[nI][12]
			MsUnlock()

			If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
				TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
			EndIf

			AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .F. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf

			EndIf
		Next nJ
		MsUnLock()

	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


//
// Campos Tabela ZY8
//

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'01'																	, ; //X3_ORDEM
	'ZY8_FILIAL'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	2																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Filial'																, ; //X3_TITULO
	'Sucursal'																, ; //X3_TITSPA
	'Branch'																, ; //X3_TITENG
	'Filial do Sistema'														, ; //X3_DESCRIC
	'Sucursal'																, ; //X3_DESCSPA
	'Branch of the System'													, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	1																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	''																		, ; //X3_VISUAL
	''																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	'033'																	, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'02'																	, ; //X3_ORDEM
	'ZY8_FILFT'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	2																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Filial pedid'															, ; //X3_TITULO
	''																		, ; //X3_TITSPA
	''																		, ; //X3_TITENG
	''																		, ; //X3_DESCRIC
	''																		, ; //X3_DESCSPA
	''																		, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(65)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	'033'																	, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'03'																	, ; //X3_ORDEM
	'ZY8_NUMPV'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	6																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Nr Ped Venda'															, ; //X3_TITULO
	'Nr Ped Compr'															, ; //X3_TITSPA
	'Nr Ped Compr'															, ; //X3_TITENG
	'Numero Pedido de Compras'												, ; //X3_DESCRIC
	'Numero Pedido de Compras'												, ; //X3_DESCSPA
	'Numero Pedido de Compras'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	'SC5'																	, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'04'																	, ; //X3_ORDEM
	'ZY8_SEQUEN'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	4																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Sequencia'																, ; //X3_TITULO
	'Sequencia'																, ; //X3_TITSPA
	'Sequencia'																, ; //X3_TITENG
	'Sequencia'																, ; //X3_DESCRIC
	'Sequencia'																, ; //X3_DESCSPA
	'Sequencia'																, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'05'																	, ; //X3_ORDEM
	'ZY8_DTMONI'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt Monitoram'															, ; //X3_TITULO
	'Dt Monitoram'															, ; //X3_TITSPA
	'Dt Monitoram'															, ; //X3_TITENG
	'Data Monitoramento'													, ; //X3_DESCRIC
	'Data Monitoramento'													, ; //X3_DESCSPA
	'Data Monitoramento'													, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'DDATABASE'																, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'06'																	, ; //X3_ORDEM
	'ZY8_HRMONI'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	5																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Hr Monitoram'															, ; //X3_TITULO
	'Hr Monitoram'															, ; //X3_TITSPA
	'Hr Monitoram'															, ; //X3_TITENG
	'Hora Monitoramento'													, ; //X3_DESCRIC
	'Hora Monitoramento'													, ; //X3_DESCSPA
	'Hora Monitoramento'													, ; //X3_DESCENG
	'99:99'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'TIME()'																, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'07'																	, ; //X3_ORDEM
	'ZY8_COMENT'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	200																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Comentario'															, ; //X3_TITULO
	'Comentario'															, ; //X3_TITSPA
	'Comentario'															, ; //X3_TITENG
	'Comentario'															, ; //X3_DESCRIC
	'Comentario'															, ; //X3_DESCSPA
	'Comentario'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'08'																	, ; //X3_ORDEM
	'ZY8_CODUSR'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	6																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Cod Usuario'															, ; //X3_TITULO
	'Cod Usuario'															, ; //X3_TITSPA
	'Cod Usuario'															, ; //X3_TITENG
	'Codigo do Usuario'														, ; //X3_DESCRIC
	'Codigo do Usuario'														, ; //X3_DESCSPA
	'Codigo do Usuario'														, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'__CUSERID'																, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'09'																	, ; //X3_ORDEM
	'ZY8_NOMUSR'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	40																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Nome Usuario'															, ; //X3_TITULO
	'Nome Usuario'															, ; //X3_TITSPA
	'Nome Usuario'															, ; //X3_TITENG
	'Nome Usuario'															, ; //X3_DESCRIC
	'Nome Usuario'															, ; //X3_DESCSPA
	'Nome Usuario'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'USRFULLNAME(__CUSERID)'												, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'10'																	, ; //X3_ORDEM
	'ZY8_ENVIAD'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Flag Envio'															, ; //X3_TITULO
	'Flag Envio'															, ; //X3_TITSPA
	'Flag Envio'															, ; //X3_TITENG
	'Flag Item Enviado'														, ; //X3_DESCRIC
	'Flag Item Enviado'														, ; //X3_DESCSPA
	'Flag Item Enviado'														, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'11'																	, ; //X3_ORDEM
	'ZY8_ENCMON'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Encerra Moni'															, ; //X3_TITULO
	'Encerra Moni'															, ; //X3_TITSPA
	'Encerra Moni'															, ; //X3_TITENG
	'Encerra Monitoramento'													, ; //X3_DESCRIC
	'Encerra Monitoramento'													, ; //X3_DESCSPA
	'Encerra Monitoramento'													, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'12'																	, ; //X3_ORDEM
	'ZY8_DTNECE'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Data Necessid'															, ; //X3_TITULO
	'Data Necessid'															, ; //X3_TITSPA
	'Data Necessid'															, ; //X3_TITENG
	'Data Necessidade'														, ; //X3_DESCRIC
	'Data Necessidade'														, ; //X3_DESCSPA
	'Data Necessidade'														, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'13'																	, ; //X3_ORDEM
	'ZY8_DTFAT'																, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Data Faturam'															, ; //X3_TITULO
	'Data Faturam'															, ; //X3_TITSPA
	'Data Faturam'															, ; //X3_TITENG
	'Dt Faturamento'			    										, ; //X3_DESCRIC
	'Dt Faturamento'														, ; //X3_DESCSPA
	'Dt Faturamento'														, ; //X3_DESCENG
	'@D'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
	'U_A0MS97Val(,.F.)'														, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(65)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'14'																	, ; //X3_ORDEM
	'ZY8_DTFOLD'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt Anterior'															, ; //X3_TITULO
	'Dt Anterior'															, ; //X3_TITSPA
	'Dt Anterior'															, ; //X3_TITENG
	'Dt Anterior'															, ; //X3_DESCRIC
	'Dt Anterior'															, ; //X3_DESCSPA
	'Dt Anterior'															, ; //X3_DESCENG
	'@D'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'U_A0MS97Val(,.F.)'														, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	'S'																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'15'																	, ; //X3_ORDEM
	'ZY8_JUSCOD'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	3																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Cod. Justi'															, ; //X3_TITULO
	'Cod. Justi'															, ; //X3_TITSPA
	'Cod. Justi'															, ; //X3_TITENG
	'Codigo Justificativa'													, ; //X3_DESCRIC
	'Codigo Justificativa'													, ; //X3_DESCSPA
	'Codigo Justificativa'													, ; //X3_DESCENG
	'999'																	, ; //X3_PICTURE
	'ExistCpo("ZY5") .AND. U_A0MS97Val(M->ZY8_JUSCOD)'						, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	'ZY5'																	, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	'S'																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	'S'																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'16'																	, ; //X3_ORDEM
	'ZY8_JUSDES'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	50																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Justificativ'															, ; //X3_TITULO
	'Justificativ'															, ; //X3_TITSPA
	'Justificativ'															, ; //X3_TITENG
	'Justificativa'															, ; //X3_DESCRIC
	'Justificativa'															, ; //X3_DESCSPA
	'Justificativa'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	'POSICIONE("ZY5",1,xFilial("ZY5")+ZY8->ZY8_JUSCOD,"ZY5_DESCR")'			, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'V'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	'POSICIONE("ZY5",1,xFilial("ZY5")+ZY8->ZY8_JUSCOD,"ZY8_DESCR")'			, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	'S'																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'17'																	, ; //X3_ORDEM
	'ZY8_ORIGEM'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	20																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Origem'																, ; //X3_TITULO
	'Origem'																, ; //X3_TITSPA
	'Origem'																, ; //X3_TITENG
	'Origem'																, ; //X3_DESCRIC
	'Origem'																, ; //X3_DESCSPA
	'Origem'																, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	''																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	''																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	'S'																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'18'																	, ; //X3_ORDEM
	'ZY8_DTPREV'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt.Prev.Est'															, ; //X3_TITULO
	'Dt.Prev.Est'															, ; //X3_TITSPA
	'Dt.Prev.Est'															, ; //X3_TITENG
	'Data Prevista Estoque Ped'												, ; //X3_DESCRIC
	'Data Prevista Estoque Ped'												, ; //X3_DESCSPA
	'Data Prevista Estoque Ped'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'19'																	, ; //X3_ORDEM
	'ZY8_OBSERV'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	200																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Observ.Just.'															, ; //X3_TITULO
	'Observ.Just.'															, ; //X3_TITSPA
	'Observ.Just.'															, ; //X3_TITENG
	'Observacao da Justificati'												, ; //X3_DESCRIC
	'Observacao da Justificati'												, ; //X3_DESCSPA
	'Observacao da Justificati'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'20'																	, ; //X3_ORDEM
	'ZY8_CODPRD'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	15																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Codigo Produ'															, ; //X3_TITULO
	'Codigo Produ'															, ; //X3_TITSPA
	'Codigo Produ'															, ; //X3_TITENG
	'Codigo Produto'														, ; //X3_DESCRIC
	'Codigo Produto'														, ; //X3_DESCSPA
	'Codigo Produto'														, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'21'																	, ; //X3_ORDEM
	'ZY8_DSCPRD'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	40																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Descr.Produt'															, ; //X3_TITULO
	'Descr.Produt'															, ; //X3_TITSPA
	'Descr.Produt'															, ; //X3_TITENG
	'Descricao Produto'														, ; //X3_DESCRIC
	'Descricao Produto'														, ; //X3_DESCSPA
	'Descricao Produto'														, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'22'																	, ; //X3_ORDEM
	'ZY8_UNSVEN'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	9																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Qtd Ven 2 UM'															, ; //X3_TITULO
	'Qtd Ven 2 UM'															, ; //X3_TITSPA
	'Qtd Ven 2 UM'															, ; //X3_TITENG
	'Quant. Vend. na 2 Unid M.'												, ; //X3_DESCRIC
	'Quant. Vend. na 2 Unid M.'												, ; //X3_DESCSPA
	'Quant. Vend. na 2 Unid M.'												, ; //X3_DESCENG
	'@E 99,999.999'															, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'23'																	, ; //X3_ORDEM
	'ZY8_SEGUM'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	2																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Segunda UM'															, ; //X3_TITULO
	'Segunda UM'															, ; //X3_TITSPA
	'Segunda UM'															, ; //X3_TITENG
	'Segunda Unidade de Medida'												, ; //X3_DESCRIC
	'Segunda Unidade de Medida'												, ; //X3_DESCSPA
	'Segunda Unidade de Medida'												, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	'SAH'																	, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	'ExistCpo("SAH")'														, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'24'																	, ; //X3_ORDEM
	'ZY8_QTDVEN'															, ; //X3_CAMPO
	'N'																		, ; //X3_TIPO
	13																		, ; //X3_TAMANHO
	3																		, ; //X3_DECIMAL
	'Quantidade'															, ; //X3_TITULO
	'Quantidade'															, ; //X3_TITSPA
	'Quantidade'															, ; //X3_TITENG
	'Quantidade Vendida'													, ; //X3_DESCRIC
	'Quantidade Vendida'													, ; //X3_DESCSPA
	'Quantidade Vendida'													, ; //X3_DESCENG
	'@E 999,999,999.999'													, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'25'																	, ; //X3_ORDEM
	'ZY8_UM'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	2																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Unidade'																, ; //X3_TITULO
	'Unidade'																, ; //X3_TITSPA
	'Unidade'																, ; //X3_TITENG
	'Unidade de Medida Primar.'												, ; //X3_DESCRIC
	'Unidade de Medida Primar.'												, ; //X3_DESCSPA
	'Unidade de Medida Primar.'												, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'26'																	, ; //X3_ORDEM
	'ZY8_VNCZY3'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	20																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Vinc.Tab.ZY3'															, ; //X3_TITULO
	'Vinc.Tab.ZY3'															, ; //X3_TITSPA
	'Vinc.Tab.ZY3'															, ; //X3_TITENG
	'Vinculo com a Tabela ZY3.'												, ; //X3_DESCRIC
	'Vinculo com a Tabela ZY3.'												, ; //X3_DESCSPA
	'Vinculo com a Tabela ZY3.'												, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY8'																	, ; //X3_ARQUIVO
	'27'																	, ; //X3_ORDEM
	'ZY8_DTECLI'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt.Entr.Clie'															, ; //X3_TITULO
	'Dt.Entr.Clie'															, ; //X3_TITSPA
	'Dt.Entr.Clie'															, ; //X3_TITENG
	'Data de Entrega no Client'												, ; //X3_DESCRIC
	'Data de Entrega no Client'												, ; //X3_DESCSPA
	'Data de Entrega no Client'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

//
// Campos Tabela SC5
//
aAdd( aSX3, { ;
	'SC5'																	, ; //X3_ARQUIVO
	'E8'																	, ; //X3_ORDEM
	'C5_I_DTPRV'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt.Prev.PedE'															, ; //X3_TITULO
	'Dt.Prev.PedE'															, ; //X3_TITSPA
	'Dt.Prev.PedE'															, ; //X3_TITENG
	'Data Prevista Estoque PV'												, ; //X3_DESCRIC
	'Data Prevista Estoque PV'												, ; //X3_DESCSPA
	'Data Prevista Estoque PV'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'SC5'																	, ; //X3_ARQUIVO
	'E9'																	, ; //X3_ORDEM
	'C5_I_DTCLI'															, ; //X3_CAMPO
	'D'																		, ; //X3_TIPO
	8																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Dt.Entr.Clie'															, ; //X3_TITULO
	'Dt.Entr.Clie'															, ; //X3_TITSPA
	'Dt.Entr.Clie'															, ; //X3_TITENG
	'Data de Entrega no Client'												, ; //X3_DESCRIC
	'Data de Entrega no Client'												, ; //X3_DESCSPA
	'Data de Entrega no Client'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

//
// Campos Tabela ZG5
//
aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'08'																	, ; //X3_ORDEM
	'ZG5_COND1'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	150																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Condicao 1'															, ; //X3_TITULO
	'Condicao 1'															, ; //X3_TITSPA
	'Condicao 1'															, ; //X3_TITENG
	'Condicao 01'															, ; //X3_DESCRIC
	'Condicao 01'															, ; //X3_DESCSPA
	'Condicao 01'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'09'																	, ; //X3_ORDEM
	'ZG5_LEGCD1'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Legenda 1'																, ; //X3_TITULO
	'Legenda 1'																, ; //X3_TITSPA
	'Legenda 1'																, ; //X3_TITENG
	'Legenda da Condicao 01'												, ; //X3_DESCRIC
	'Legenda da Condicao 01'												, ; //X3_DESCSPA
	'Legenda da Condicao 01'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Agenda Maior que Permitido;2=Aguarda Dt.Faturamento;3=Cobrar faturamento;4=Faturar Urgente;5=Perdeu agenda', ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'10'																	, ; //X3_ORDEM
	'ZG5_COND2'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	150																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Condicao 2'															, ; //X3_TITULO
	'Condicao 2'															, ; //X3_TITSPA
	'Condicao 2'															, ; //X3_TITENG
	'Condicao 02'															, ; //X3_DESCRIC
	'Condicao 02'															, ; //X3_DESCSPA
	'Condicao 02'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'11'																	, ; //X3_ORDEM
	'ZG5_LEGCD2'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Legenda 2'																, ; //X3_TITULO
	'Legenda 2'																, ; //X3_TITSPA
	'Legenda 2'																, ; //X3_TITENG
	'Legenda 02'															, ; //X3_DESCRIC
	'Legenda 02'															, ; //X3_DESCSPA
	'Legenda 02'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Agenda Maior que Permitido;2=Aguarda Dt.Faturamento;3=Cobrar faturamento;4=Faturar Urgente;5=Perdeu agenda', ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'12'																	, ; //X3_ORDEM
	'ZG5_COND3'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	150																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Condicao 3'															, ; //X3_TITULO
	'Condicao 3'															, ; //X3_TITSPA
	'Condicao 3'															, ; //X3_TITENG
	'Condicao 03'															, ; //X3_DESCRIC
	'Condicao 03'															, ; //X3_DESCSPA
	'Condicao 03'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'13'																	, ; //X3_ORDEM
	'ZG5_LEGCD3'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Legenda 3'																, ; //X3_TITULO
	'Legenda 3'																, ; //X3_TITSPA
	'Legenda 3'																, ; //X3_TITENG
	'Legenda 03'															, ; //X3_DESCRIC
	'Legenda 03'															, ; //X3_DESCSPA
	'Legenda 03'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Agenda Maior que Permitido;2=Aguarda Dt.Faturamento;3=Cobrar faturamento;4=Faturar Urgente;5=Perdeu agenda', ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'14'																	, ; //X3_ORDEM
	'ZG5_COND4'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	150																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Condicao 4'															, ; //X3_TITULO
	'Condicao 4'															, ; //X3_TITSPA
	'Condicao 4'															, ; //X3_TITENG
	'Condicao 04'															, ; //X3_DESCRIC
	'Condicao 04'															, ; //X3_DESCSPA
	'Condicao 04'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'15'																	, ; //X3_ORDEM
	'ZG5_LEGCD4'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Legenda 4'																, ; //X3_TITULO
	'Legenda 4'																, ; //X3_TITSPA
	'Legenda 4'																, ; //X3_TITENG
	'Legenda 04'															, ; //X3_DESCRIC
	'Legenda 04'															, ; //X3_DESCSPA
	'Legenda 04'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Agenda Maior que Permitido;2=Aguarda Dt.Faturamento;3=Cobrar faturamento;4=Faturar Urgente;5=Perdeu agenda', ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'16'																	, ; //X3_ORDEM
	'ZG5_COND5'																, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	150																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Condicao 5'															, ; //X3_TITULO
	'Condicao 5'															, ; //X3_TITSPA
	'Condicao 5'															, ; //X3_TITENG
	'Condicao 05'															, ; //X3_DESCRIC
	'Condicao 05'															, ; //X3_DESCSPA
	'Condicao 05'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'17'																	, ; //X3_ORDEM
	'ZG5_LEGCD5'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	1																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Legenda 5'																, ; //X3_TITULO
	'Legenda 5'																, ; //X3_TITSPA
	'Legenda 5'																, ; //X3_TITENG
	'Legenda 05'															, ; //X3_DESCRIC
	'Legenda 05'															, ; //X3_DESCSPA
	'Legenda 05'															, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	'1=Agenda Maior que Permitido;2=Aguarda Dt.Faturamento;3=Cobrar faturamento;4=Faturar Urgente;5=Perdeu agenda', ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME
aAdd( aSX3, { ;
	'ZG5'																	, ; //X3_ARQUIVO
	'18'																	, ; //X3_ORDEM
	'ZG5_OBSERV'															, ; //X3_CAMPO
	'M'																		, ; //X3_TIPO
	10																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Observacoes'															, ; //X3_TITULO
	'Observacoes'															, ; //X3_TITSPA
	'Observacoes'															, ; //X3_TITENG
	'Observacoes'															, ; //X3_DESCRIC
	'Observacoes'															, ; //X3_DESCSPA
	'Observacoes'															, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

//
// Campos Tabela ZY3
//
aAdd( aSX3, { ;
	'ZY3'																	, ; //X3_ARQUIVO
	'18'																	, ; //X3_ORDEM
	'ZY3_OBSERV'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	200																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Observ.Just.'															, ; //X3_TITULO
	'Observ.Just.'															, ; //X3_TITSPA
	'Observ.Just.'															, ; //X3_TITENG
	'Observacao Justificativa'												, ; //X3_DESCRIC
	'Observacao Justificativa'												, ; //X3_DESCSPA
	'Observacao Justificativa'												, ; //X3_DESCENG
	''																		, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'S'																		, ; //X3_BROWSE
	'A'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME

aAdd( aSX3, { ;
	'ZY3'																	, ; //X3_ARQUIVO
	'19'																	, ; //X3_ORDEM
	'ZY3_VNCZY8'															, ; //X3_CAMPO
	'C'																		, ; //X3_TIPO
	20																		, ; //X3_TAMANHO
	0																		, ; //X3_DECIMAL
	'Vinc.Tab.ZY8'															, ; //X3_TITULO
	'Vinc.Tab.ZY8'															, ; //X3_TITSPA
	'Vinc.Tab.ZY8'															, ; //X3_TITENG
	'Vinculo com a Tabela ZY8'												, ; //X3_DESCRIC
	'Vinculo com a Tabela ZY8'												, ; //X3_DESCSPA
	'Vinculo com a Tabela ZY8'												, ; //X3_DESCENG
	'@!'																	, ; //X3_PICTURE
	''																		, ; //X3_VALID
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
	''																		, ; //X3_RELACAO
	''																		, ; //X3_F3
	0																		, ; //X3_NIVEL
	Chr(254) + Chr(192)														, ; //X3_RESERV
	''																		, ; //X3_CHECK
	''																		, ; //X3_TRIGGER
	'U'																		, ; //X3_PROPRI
	'N'																		, ; //X3_BROWSE
	'V'																		, ; //X3_VISUAL
	'R'																		, ; //X3_CONTEXT
	''																		, ; //X3_OBRIGAT
	''																		, ; //X3_VLDUSER
	''																		, ; //X3_CBOX
	''																		, ; //X3_CBOXSPA
	''																		, ; //X3_CBOXENG
	''																		, ; //X3_PICTVAR
	''																		, ; //X3_WHEN
	''																		, ; //X3_INIBRW
	''																		, ; //X3_GRPSXG
	''																		, ; //X3_FOLDER
	''																		, ; //X3_CONDSQL
	''																		, ; //X3_CHKSQL
	''																		, ; //X3_IDXSRV
	'N'																		, ; //X3_ORTOGRA
	''																		, ; //X3_TELA
	''																		, ; //X3_POSLGT
	'N'																		, ; //X3_IDXFLD
	''																		, ; //X3_AGRUP
	''																		, ; //X3_MODAL
	''																		} ) //X3_PYME


//
// Atualizando dicionário
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
			If aSX3[nI][nPosTam] <> SXG->XG_SIZE
				aSX3[nI][nPosTam] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo] + " NÃO atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq] $ cAlias )
		cAlias += aSX3[nI][nPosArq] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela ZY8
//
aAdd( aSIX, { ;
	'ZY8'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'ZY8_FILIAL+ZY8_NUMPV+ZY8_SEQUEN'										, ; //CHAVE
	'Nr Ped Vend+Sequencia'													, ; //DESCRICAO
	''																		, ; //DESCSPA
	''																		, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'ZY8'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'ZY8_NUMPV'																, ; //CHAVE
	'Nr Ped Vend'															, ; //DESCRICAO
	''																		, ; //DESCSPA
	''																		, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for alteração precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando índices..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp
Função de processamento da gravação dos Helps de Campos

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
Local aHlpPor   := {}
Local aHlpEng   := {}
Local aHlpSpa   := {}

AutoGrLog( "Ínicio da Atualização" + " " + "Helps de Campos" + CRLF )


oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

//
// Helps Tabela ZY8
//
aHlpPor := {}
aAdd( aHlpPor, 'Data Prevista do Estoque do Pedido de' )
aAdd( aHlpPor, 'Vendas.' )

PutHelp( "PZY8_DTPREV", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_DTPREV" )

aHlpPor := {}
aAdd( aHlpPor, 'Observação da Justificativa.' )

PutHelp( "PZY8_OBSERV", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_OBSERV" )

aHlpPor := {}
aAdd( aHlpPor, 'Código do produto' )

PutHelp( "PZY8_CODPRD", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_CODPRD" )

aHlpPor := {}
aAdd( aHlpPor, 'Descrição do Produto.' )

PutHelp( "PZY8_DSCPRD", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_DSCPRD" )

aHlpPor := {}
aAdd( aHlpPor, 'Quantidade de venda na segunda unidade' )
aAdd( aHlpPor, 'de medida.' )

PutHelp( "PZY8_UNSVEN", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_UNSVEN" )

aHlpPor := {}
aAdd( aHlpPor, 'Segunda unidade de medida.' )

PutHelp( "PZY8_SEGUM ", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_SEGUM" )

aHlpPor := {}
aAdd( aHlpPor, 'Quantidade vendida.' )

PutHelp( "PZY8_QTDVEN", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_QTDVEN" )

aHlpPor := {}
aAdd( aHlpPor, 'Primeira unidade de medida.' )

PutHelp( "PZY8_UM    ", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_UM" )

aHlpPor := {}
aAdd( aHlpPor, 'Campo de vínculo com a tabela ZY3.' )

PutHelp( "PZY8_VNCZY3", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_VNCZY3" )

aHlpPor := {}
aAdd( aHlpPor, 'Data de entrega no cliente.' )

PutHelp( "PZY8_DTECLI", aHlpPor, {}, {}, .T. )
AutoGrLog( "Atualizado o Help do campo " + "ZY8_DTECLI" )

AutoGrLog( CRLF + "Final da Atualização" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "Máscara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Seleção" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UP29634" ) ) ) ;
Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
Local lOpen := .F.
Local nLoop := 0

If FindFunction( "OpenSM0Excl" )
	For nLoop := 1 To 20
		If OpenSM0Excl(,.F.)
			lOpen := .T.
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
Else
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		Sleep( 500 )
	Next nLoop
EndIf

If !lOpen
	MsgStop( "Não foi possível a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  17/08/20
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet

//===============================================================================================
// Programa.......: Atuliz_ZG5
// Autor..........: Julio de Paula Paz
// Data...........: 28/08/2019
//===============================================================================================
// Descrição......: Atualizar a tabela Transit Time com as condições definidas para a legenda 
//                  da rotina Gestão de Carteira.
//===============================================================================================
// Parâmetros.....: Nenhum
//===============================================================================================
// Retorno........: Nenhum
//===============================================================================================
Static Function Atuliz_ZG5()
Local _aDados := {}
Local _nI

Begin Sequence
Aadd(_aDados,{'             ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01AC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01AL       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01AM       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 35' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 21.AND. (TRBSC5->C5_I_DTENT - DATE()) < 34 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 20' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 19' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 18' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01AP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 35' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 21.AND. (TRBSC5->C5_I_DTENT - DATE()) < 34 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 20' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 19' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 18' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01BA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01CE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01DF       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==2' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 1' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01ES       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 6' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==5' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 4' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==2' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 1' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01MA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==2' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 1' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01MS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01MT       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01PA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01PB       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01PE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01PI       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 6' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==5' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 4' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01RN       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01RO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 6' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==5' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 4' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01RR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 35' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 21.AND. (TRBSC5->C5_I_DTENT - DATE()) < 34 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 20' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 19' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 18' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01RS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01SC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 5' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 3' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01SE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 10' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 9' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 8' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  01TO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  02GO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  04GO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  04MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  06GO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  06MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  09GO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  0AGO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  0BGO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10AC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10AL       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10AM       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 27' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 13 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 26)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10AP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10BA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10CE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10DF       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10ES       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10MA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10MS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10MT       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10PA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10PB       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10PE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10PI       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10RN       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10RO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10RR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 30' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 16 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 29)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10RS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10SC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10SE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  10TO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  11RO       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20AL       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20AM       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20BA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20CE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20ES       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20MA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20MT       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20PA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20PB       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20PE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20PI       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20RN       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20RO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 23' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 9 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 22 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20RS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20SC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20SE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  20TO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23AL       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23AM       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23BA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23CE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23ES       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 21' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 7 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 20)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23MA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23MT       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23PA       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23PB       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23PE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23PI       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23RN       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23RO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 23' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 9 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 22 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23RS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23SC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23SE       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 25' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 11 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 24 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  23TO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  24RS       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  25RS       ',"ZG5->ZG5_COND1 := '' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40ES       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  40SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90GO       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90MG       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90MG     36',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90MS     36',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90RJ       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90RJ     36',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90RS       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SC       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP0210136',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP0280436',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP0650836',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP1110236',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP4980536',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  90SP5710536',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 20' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 6 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 19)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM00300  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM01100  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM01902  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM02504  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM02553  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 18' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 4 .AND. (TRBSC5->C5_I_DTENT - DATE()) < 17 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==4' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM02603  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM03536  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91AM03569  ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 16' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 2.AND. (TRBSC5->C5_I_DTENT - DATE()) < 15 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  91RR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 22' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 8.AND. (TRBSC5->C5_I_DTENT - DATE()) < 21 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  93PR       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 17' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 3.AND. (TRBSC5->C5_I_DTENT - DATE()) < 16 )' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 4' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) == 3' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 2' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 
Aadd(_aDados,{'  93SP       ',"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ", "ZG5->ZG5_LEGCD1 := '1' ", "ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", "ZG5->ZG5_LEGCD2 := '2' ", "ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", "ZG5->ZG5_LEGCD3 := '3' ", "ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ", "ZG5->ZG5_LEGCD4 := '4' ", "ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ", "ZG5->ZG5_LEGCD5 := '5' ", "ZG5->ZG5_OBSERV := '' "}) 

/*
Aadd(_aDados,{'  93SP       ', 1
"ZG5->ZG5_COND1 := '(TRBSC5->C5_I_DTENT - DATE()) > 19' ",  //2
"ZG5->ZG5_LEGCD1 := '1' ",  //  3
"ZG5->ZG5_COND2 := '((TRBSC5->C5_I_DTENT - DATE()) > 5 .AND. (TRBSC5->C5_I_DTENT - DATE()) <18)' ", // 4
"ZG5->ZG5_LEGCD2 := '2' ", // 5
"ZG5->ZG5_COND3 := '(TRBSC5->C5_I_DTENT - DATE()) == 7' ", 6
"ZG5->ZG5_LEGCD3 := '3' ",  // 7
"ZG5->ZG5_COND4 := '(TRBSC5->C5_I_DTENT - DATE()) ==6' ",  // 8
"ZG5->ZG5_LEGCD4 := '4' ", // 9
"ZG5->ZG5_COND5 := '(TRBSC5->C5_I_DTENT - DATE()) < 5' ",  // 10
"ZG5->ZG5_LEGCD5 := '5' ", // 11
"ZG5->ZG5_OBSERV := '' "}) // 12 
*/
   DbSelectArea("ZG5")
   ZG5->(DbSetOrder(1)) // ZG5_FILIAL+ZG5_FILORI+ZG5_UF+ZG5_CODMUN+ZG5_LOCAL  
   For _nI := 1 To Len(_aDados)   
       If ZG5->(DbSeek(_aDados[_nI,1]))  
          ZG5->(RecLock("ZG5",.F.) )
          &(_aDados[_nI,2])
		  &(_aDados[_nI,3])
		  &(_aDados[_nI,4])
		  &(_aDados[_nI,5])
		  &(_aDados[_nI,6])
		  &(_aDados[_nI,7])
		  &(_aDados[_nI,8])
		  &(_aDados[_nI,9])
		  &(_aDados[_nI,10])
		  &(_aDados[_nI,11])
		  &(_aDados[_nI,12])
		  
          ZG5->(MsUnLock())
	   EndIf
   Next


End Sequence

Return Nil

/////////////////////////////////////////////////////////////////////////////
