#Include "TOTVS.ch"
#Include "vkey.ch"

/*
===============================================================================================================================
Programa----------: MOMS047
Autor-------------: Alex Wallauer
Data da Criacao---: 29/01/2020
Descrição---------: Central de pedidos de venda para varejo - Chamado 31830 - FILIAL 90
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS047(_cChamada)

Local nI            := 0
Local _aParAux      := {}
Local _aParRet      := {}
DEFAULT _cChamada   := "VAREJO"
Private _otemp      := nil
Private lInverte	:= .F.
Private cMarca      := GetMark()
Private aCampos		:= {}
Private nQtdTit		:= 0
Private nPesTit	    := 0
Private nValTit     := 0
Private _cAmb       := Upper(AllTrim(GETENVSERVER()))
Private _nMinimo    := SuperGetMV("IT_CRTMIN",.T.,150)
Private _aCabXML    := {}
Private _aColXML    := {}
Private _lAmbTeste  := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
Private _cDirTRB    := AllTrim(GetTempPath())
If Right(_cDirTRB,1) = "\"
   _cDirTRB := LEFT(_cDirTRB,Len(_cDirTRB)-1)
EndIf

Private MV_PAR71:=Space(200)
Private MV_PAR72:=Space(200)
Private MV_PAR73:=Space(200)
Private MV_PAR74:=Space(200)

// Define se a filial de processamento está habilitada para a integração
If _cChamada == "VAREJO" // MOMS047
   _cFilHabilit := '90'
ElseIf _cChamada == "OPL" //MOMS061
   _cFilHabilit := '[90] [40]'
EndIf
If !cFilant $ _cFilHabilit // Filiais habilitadas na integracao
	U_ITMsg("Filial atual não está habilitada para integração (TXT) com o Roteirizador, somente essa(s): [ "+_cFilHabilit+" ]","Atenção",,1)
	Return .F.
EndIf
DBSelectArea("ZGL")

aOpcoes:={}
If _cChamada == "VAREJO" // MOMS047
   cCadastro:="CENTRAL DE PVS DE VAREJO"
   aAdd(aOpcoes,"1-EXPORTA P/ ROTEIRIZADOR")//1
   aAdd(aOpcoes,"2-IMPORTA DO ROTEIRIZADOR")//2
   aAdd(aOpcoes,"3-CORTES DE PV DE VAREJO ")//3
   MV_PAR91:="1-EXPORTA P/ ROTEIRIZADOR"
ElseIf _cChamada == "OPL" //MOMS061
   cCadastro:="CENTRAL DE PVS DO OPERADOR LOGISTICO"
   aAdd(aOpcoes,"1-EXPORTA P/ OP LOGISTICO")//4
   aAdd(aOpcoes,"2-IMPORTA DO OP LOGISTICO")//5
   MV_PAR91:="1-EXPORTA P/ OP LOGISTICO"
EndIf

aAdd( _aParAux , {2,"Escolha uma Opção",MV_PAR91, aOpcoes,100,".T.",.T.,".T."})

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI
While .T.
   
   MV_PAR01:=MV_PAR91
   If _cChamada == "OPL"
      MV_PAR91:="1-EXPORTA P/ OP LOGISTICO"
   EndIf
   //        aParametros ,cTitle                 ,aRet      ,bOk                     ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
   If ParamBox( _aParAux , "Selecione uma Opcao" , @_aParRet, {|| !Empty(MV_PAR01) } ,        , .T.     ,     ,     ,          ,     , .T.    , .T. )
   	
   	   MV_PAR91:=MV_PAR01
       If _cChamada  == "OPL"
	      If MV_PAR01 = "1" 
             MV_PAR91:="4"//1-EXPORTA P/ OP LOGISTICO
		  Else
             MV_PAR91:="5"//2-IMPORTA DO OP LOGISTICO
		  EndIf
          _cTitulo:="CENTRAL DE PVS DO OPERADOR LOGISTICO"
       Else
          _cTitulo:="CENTRAL DE PEDIDOS DE VENDAS DE VAREJO" 
	   EndIf
   	   
   	   If LEFT(MV_PAR91,1) $ "1,3" //1-EXPORTA P/ ROTEIRIZADOR OU 3-CORTES DE PV DE VAREJO 
   	   	
   	   	  FWMsgRun( , {|oproc| MOMS047ARQ(oproc, .F.) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )
   	   	
   	   	  MOMS047TRS()//Função que monta a tela para processar
   	   	
   	   ElseIf MV_PAR91 = "2"//"2-IMPORTA DO ROTEIRIZADOR" - TXT
   	   	
   	   	  MOMS47GETTXT("ROT")//Função que monta a tela para processar
      
   	   ElseIf MV_PAR91 = "4" //4-EXPORTA P/ OP LOGISTICO"
   	   
   	   	  FWMsgRun( , {|oproc| MOM47GFT(.T.,oproc) }, "Aguarde!" , 'Lendo Dados dos pedidos...' )
      
   	   ElseIf MV_PAR91 = "5"//"5-IMPORTA DO OP LOGISTICO" - CSV / XLSX / XML
      
   	   	  FWMsgRun( , {|oproc| MOMS47GETTXT("OPLOG",oproc) }, "Aguarde!" , 'Lendo Dados do Arquivo...' )//Função que monta a tela para processar
      
   	   EndIf 
      
   Else
   	   Exit
   EndIf

EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS047TRS
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Função que monta a tela para processar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047TRS()

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local _bOK

Private nOpca		:= 0
Private cFiltro		:= "%"
Private _aAreaCabec	:= {}
Private _cNumPed	:= ""
Private oMark		:= Nil
Private oQtda		:= Nil
Private oPesa		:= Nil
Private oValor      := Nil

// Botoes da tela.
If MV_PAR91 = "1"     //"1-EXPORTA P/ ROTEIRIZADOR"
	aAdd( aBotoes , { "" , {|| MOMS047C(05) 	}	, "" , "EXPORTA P/ ROTEIRIZADOR"} )
ElseIf MV_PAR91 = "2" //"2-IMPORTA DO ROTEIRIZADOR"
	aAdd( aBotoes , { "" , {|| MOMS047C(07) 	}	, "" , "IMPORTA DO ROTEIRIZADOR"} )
ElseIf MV_PAR91 = "3" //"3-CORTES DE PV DE VAREJO "
	aAdd( aBotoes , { "" , {|| MOMS047C(06) 	}	, "" , "CORTA OS PVs DE VAREJO"   } )
EndIf
aAdd( aBotoes , { "" , {|| MOMS047C(01)	}, "" , "Pesquisar"		   } )
aAdd( aBotoes , { "" , {|| MOMS047C(02)	}, "" , "Visualizar Pedido"} )
aAdd( aBotoes , { "" , {|| MOMS047C(03)	}, "" , "Analisa Itens"	   } )
aAdd( aBotoes , { "" , {|| MOMS047C(04)	}, "" , "Legenda"          } )
aAdd( aBotoes , { "" , {|| MOMS047C(07)	}, "" , "Atualizar"		   } )
aAdd( aBotoes , { "" , {|| MsAguarde({|| U_ITGEREXCEL(,,_cTitulo,,_aCabXML,_aColXML) },"Gerando Excel...") }, "" , "Gera Excel"	   } )
If MV_PAR91 = "3"     //"1-EXPORTA P/ ROTEIRIZADOR"
   aAdd( aBotoes , { "" , {|| MOMS047C(08)	}, "" , "Marca só PV Azul" } )
EndIf   

// Faz o calculo automatico de dimensoes de objetos
aSize := MSADVSIZE()

_bOK :=aBotoes[1,2]

// Cria a tela para selecao dos pedidos
DEFINE MSDIALOG oDlg1 TITLE _cTitulo From 0,0 To aSize[6],aSize[5] PIXEL

oPanel       := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
@0.8,00.8 Say OemToAnsi("Quantidade:")						OF oPanel
@0.8,0005 Say oQtda		VAR nQtdTit		Picture "@E 99999"	OF oPanel SIZE 60,8

@0.8,0012 Say OemToAnsi("Peso:")						OF oPanel
@0.8,0015 Say oPesa		VAR nPesTit		Picture "@E 999,999,999.99"	OF oPanel SIZE 60,8

@0.8,0024 Say OemToAnsi("Valor:")						OF oPanel
@0.8,0027 Say oValor	VAR nValTit		Picture "@E 999,999,999.99"	OF oPanel SIZE 60,8


If FlatMode()
	aCoors	:= GetScreenRes()
	nHeight	:= aCoors[2]
	nWidth	:= aCoors[1]
Else
	nHeight	:= 143
	nWidth	:= 315
EndIf


DBSelectArea("TRBF")
TRBF->(DBGoTop())
If TRBF->(Bof()) .And. TRBF->(Eof())
   U_ITMsg("NÃO HÁ PEDIDOS PARA PROCESSAR",'Atenção!',"TENTE NOVAMENTE MAIS TARDE",1)
   Return .F.
EndIf

oMark					:= MsSelect():New( "TRBF" , "TRBF_OK" ,, aCampos , lInverte , cMarca , { 35 , 1 , nHeight , nWidth } )
oMark:bMark				:= {|| MOMS047INV( cMarca , lInverte  ) }
oMark:oBrowse:bAllMark	:= {|| FWMsgRun(,{ || MOMS047ALL( cMarca,.F.  ) }, "Aguarde!" , 'Des / Marcando...' ) }
oCol := oMark:oBrowse:aColumns[2]//por isso "TRBF_OK" repeti 2 vezes no aCampos
oCol:bData     := {|| MOMS047CL() }
oMark:oBrowse:aColumns[2]:=oCol

oDlg1:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,_bOK ,{|| nOpca := 2,oDlg1:End()},,aBotoes),;
oPanel:Align:=CONTROL_ALIGN_TOP , oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , oMark:oBrowse:Refresh())

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS047C()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Chamada de itens do menu
Parametros--------: _nopc - Opção do menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047C(_nopc)

Local oproc

Do Case
	
	Case _nopc == 1
		//Pesquisa
		FWMsgRun(,{ || MOMS047PSQ(oMark,"TRBF") }, "Aguarde...","Carregando dados...")
		
	Case _nopc == 2
		//Visualiza pedido de vendas
		FWMsgRun(,{ || MOMS047PPV() }, "Aguarde...","Carregando dados...")
		
	Case _nopc == 3
		//Analisa itens do pedido de vendas
		FWMsgRun(,{ || MOMS047AI(TRBF->TRBF_NUM) }, "Aguarde...","Carregando dados...")
		
	Case _nopc == 4
		//Legenda do browse
		FWMsgRun(,{ || MOMS047Legenda() }, "Aguarde...","Carregando dados...")
		
	Case _nopc == 5
		// "Gera Arquivos Varejo"
		FWMsgRun( , {|oproc| MOMS047Ger(oproc) }, "Aguarde!" , "Gera Arquivos Varejo..." )
		
	Case _nopc == 6
		// "Analise Varejo"
		FWMsgRun( , {|oproc| MOMS047V(oproc) }, "Aguarde!" , 'Processando analise do Varejo...' )
		
	Case _nopc == 7
		//Atualiza browse
		If U_ITMsg("Atualiza tela?","Atenção","Todos os pedidos serão desmarcados!",3,2,2)
			FWMsgRun( , {|oproc| MOMS047ARQ(oproc, .T.) }, "Aguarde!" , 'Carregando dados...' )
		EndIf

	Case _nopc == 8
		//Marca PVS em azul
        FWMsgRun(,{ || MOMS047ALL( cMarca,.T.  ) }, "Aguarde!" , 'Des / Marcando...' )
		
EndCase

Return

/*
===============================================================================================================================
Programa----------: MOMS047PSQ
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047PSQ( oMark , cAlias )

Local oGet1		:= Nil
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local cComboBx1	:= ""
Local aComboBx1	:= { "Dt Emissao (DD/MM/AA)", "Pedido" ,"Cod. Vendedor" }
Local nOpca		:= 0
Local nI		:= 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL

	@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
	@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"
	
	DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
	DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1
	
	For nI := 1 To Len(aComboBx1)
		
		If cComboBx1 == aComboBx1[nI]
			
			DBSelectArea("TRBF")
			TRBF->( DBSetOrder(nI) )
			If nI = 1
				cGet1:=DToS(CTOD(AllTrim(cGet1)))
			EndIf
			MsSeek( cGet1 , .T. )
			
			oMark:oBrowse:Refresh( .T. )
			
		EndIf
		
	Next nI
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS047INV
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
Parametros--------: cmarca - string de marcação do registro da tabela
					linverte - flag de inversão de registros
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047INV( cMarca , lInverte  )

Local lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )

If lMarcado
	nQtdTit++
	nPesTit	+= TRBF->C5_I_PESBR
	nValTit += TRBF->TRBF_VALOR
Else
	nQtdTit--
	nPesTit	-= TRBF->C5_I_PESBR
	nValTit -= TRBF->TRBF_VALOR
EndIf

oQtda:Refresh()
oPesa:Refresh()
oValor:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MOMS047ALL
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: cMarca , lSoPVAzul
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS047ALL( cMarca  , lSoPVAzul )

Local nReg     := TRBF->( Recno() )
Local lMarcado := .F.
DEFAULT lSoPVAzul := .F.

TRBF->( DBGoTop() )

While TRBF->( !Eof() )
	
	lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte ) 
	
	If lMarcado 
		
		TRBF->TRBF_OK := Space(2)
		
		nQtdTit--
		nPesTit	-= TRBF->C5_I_PESBR
		nValTit -= TRBF->TRBF_VALOR
		
	ElseIf !lSoPVAzul//SE For lSoPVAzul = .T. DESMARCA TUDO PRIMEIRO 
		
		TRBF->TRBF_OK := cMarca
		
		nQtdTit++
		nPesTit	+= TRBF->C5_I_PESBR
		nValTit += TRBF->TRBF_VALOR
		
	EndIf
	
	TRBF->( DBSkip() )
EndDo

If lSoPVAzul
	
	TRBF->( DBGoTop() )
	While TRBF->( !Eof() )
		
		If AllTrim(TRBF->SC9_STATUS) == "LIBERADO COM BLOQUEIO DE ESTOQUE"
			
			TRBF->TRBF_OK := cMarca
			
			nQtdTit++
			nPesTit	+= TRBF->C5_I_PESBR
			nValTit += TRBF->TRBF_VALOR
			
		EndIf
		
		TRBF->( DBSkip() )
	EndDo
	
EndIf

TRBF->( DBGoTo(nReg) )

nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
nPesTit := IIf( nPesTit < 0 , 0 , nPesTit )
nValTit := IIf( nValTit < 0 , 0 , nValTit )

oQtda:Refresh()
oPesa:Refresh()
oValor:Refresh()
oMark:oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MOMS047ARQ
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: oproc - objeto da barra de processamento
					_lini - inicializa campos de data de necessidade
					_lcabec - inicializa campos de cabecalho
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047ARQ(oproc,_lcabec)

Local aEstru:= {} , _nni , nI

If !_lcabec

    MV_PAR71:=Space(200)
    MV_PAR72:=Space(200)
    MV_PAR73:=Space(200)
    MV_PAR74:=Space(200)
    _aParAux:={}
	aAdd( _aParAux , { 1 , "Gerente"    , MV_PAR71, "@!"  , ""    , "LSTGER"  , "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Coordenador", MV_PAR72, "@!"  , ""    , "LSTSUP"  , "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Supervisor" , MV_PAR73, "@!"  , ""    , "LSTSUI"  , "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Vendedor"   , MV_PAR74, "@!"  , ""    , "LSTVEN"  , "" , 100 , .F. } )
    _aParRet:={}
    For nI := 1 To Len( _aParAux )
    	aAdd( _aParRet , _aParAux[nI][03] )
    Next nI
    //        aParametros ,cTitle                 ,aRet      ,bOk   ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
    If ParamBox( _aParAux , "Selecione os Filtros" , @_aParRet,     ,        , .T.     ,     ,     ,          ,     , .T.    , .T. )
       MV_PAR71:=AllTrim(MV_PAR01)
       MV_PAR72:=AllTrim(MV_PAR02)
       MV_PAR73:=AllTrim(MV_PAR03)
	   MV_PAR74:=AllTrim(MV_PAR04)
    EndIf

EndIf

// Armazena no array aEstru a estrutura dos campos da tabela.
aAdd( aEstru , { "TRBF_OK"		, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_FILIA"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_NUM"		, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_OPER"    , 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_DTEMI"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTLIB"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTNES"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTENT"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_CODCL"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_LOJCL"	, 'C' , 04 , 0 } )
aAdd( aEstru , { "TRBF_DESCL"	, 'C' , 30 , 0 } )
aAdd( aEstru , { "TRBF_CODRE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESCR"	, 'C' , Len(SA3->A3_NOME), 0 } )
aAdd( aEstru , { "TRBF_CODVE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESVE"	, 'C' , Len(SA3->A3_NOME), 0 } )
aAdd( aEstru , { "C5_I_BLCRE"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLPRC"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLOQ"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_BLOG"  	, 'C' , 01 , 0 } )
aAdd( aEstru , { "TRBF_UF"   	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_CEP"   	, 'C' , 15 , 0 } )
aAdd( aEstru , { "TRBF_MUN"   	, 'C' , 12 , 0 } )
aAdd( aEstru , { "TRBF_VALOR"	, 'N' , 14 , 2 } )
aAdd( aEstru , { "TRBF_FILCR"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_FILFT"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_AGEND"	, 'C' , 20 , 0 } )
aAdd( aEstru , { "C5_I_PEVIN"	, 'C' , 06,0})
aAdd( aEstru , { "C5_I_ENVRD"	, 'C' , 06,0})
aAdd( aEstru , { "C5_I_TRCNF"	, 'C' , 06,0})
aAdd( aEstru , { "SC9_STATUS"	, 'C' , 99 , 0 } )
aAdd( aEstru , { "C5_LIBEROK"	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_PESBR"	, 'N' , 15 , 5 } )
aAdd( aEstru , { "C5_I_TAB" 	, 'C' , Len(SC5->C5_I_TAB ) , 0 } )
aAdd( aEstru , { "A3_I_VBROK"   , 'C' , Len(SA3->A3_I_VBROK) , 0 } )
aAdd( aEstru , { "C5_VEND1" 	, 'C' , Len(SC5->C5_VEND1)+Len(SA3->A3_NOME)    , 0 } )
aAdd( aEstru , { "C5_VEND3" 	, 'C' , Len(SC5->C5_VEND3)+Len(SA3->A3_NOME)    , 0 } )
aAdd( aEstru , { "C5_VEND4" 	, 'C' , Len(SC5->C5_VEND4)+Len(SA3->A3_NOME)    , 0 } )

// Armazena no array aCampos o nome, picture e descricao dos campos
aCampos:={}
aAdd( aCampos , { "TRBF_OK"		, "" , " "					, " "										} )
aAdd( aCampos , { "TRBF_OK"		, "" , " "					, " "										} ) //POR ISSO "TRBF_OK" REPETI 2 VEZES NO ACAMPOS:  oCol:=oMark:oBrowse:aColumns[2] ; oCol:bData:={|| MOMS047CL() }
aAdd( aCampos , { "TRBF_DTEMI"	, "" , "Data Emissao"		, PesqPict( "SC5" , "C5_EMISSAO" )	  		} )
aAdd( aCampos , { "TRBF_NUM"	, "" , "Pedido"				, PesqPict( "SC5" , "C5_NUM"	 )	 		} )
aAdd( aCampos , { "TRBF_OPER"	, "" , "Tipo Ped"           , "@!"	                                    } )
aAdd( aCampos , { "TRBF_AGEND"	, "" , "Tipo de Entrega"    , ""                                        } )
aAdd( aCampos , { "C5_I_PESBR"	, "" , "Peso"				, PesqPict( "SC5" , "C5_I_PESBR" )	 		} )
aAdd( aCampos , { "TRBF_VALOR"	, "" , "Valor"   			, PesqPict( "SC6" , "C6_VALOR"	 )	 		} )
aAdd( aCampos , { "TRBF_DTNES"	, "" , "Data Necess"		, PesqPict( "SC5" , "C5_I_DTENT" )	  		} )
aAdd( aCampos , { "TRBF_DTENT"	, "" , "Data Entrega"		, PesqPict( "SC5" , "C5_I_DTENT" )	  		} )
aAdd( aCampos , { "TRBF_UF"	    , "" , "UF"					, PesqPict( "SA1" , "A1_EST"     )	  		} )
aAdd( aCampos , { "TRBF_MUN"    , "" , "Cidade"				, PesqPict( "SA1" , "A1_MUN"     )	  		} )
aAdd( aCampos , { "TRBF_CEP"	, "" , "CEP"				, PesqPict( "SA1" , "A1_CEP"     )	  		} )
aAdd( aCampos , { "TRBF_CODCL"	, "" , "Cliente"			, PesqPict( "SC5" , "C5_CLIENTE" )	  		} )
aAdd( aCampos , { "TRBF_LOJCL"	, "" , "Loja"				, PesqPict( "SC5" , "C5_LOJACLI" )	  		} )
aAdd( aCampos , { "TRBF_DESCL"	, "" , "Descricao Cliente"	, PesqPict( "SC5" , "C5_I_NOME"  )	  		} )
aAdd( aCampos , { "TRBF_CODRE"	, "" , "Rede"				, PesqPict( "SC5" , "C5_I_GRPVE" )	  		} )
aAdd( aCampos , { "TRBF_DESCR"	, "" , "Descricao Rede"		, PesqPict( "SC5" , "C5_I_NOMRD" )	  		} )
aAdd( aCampos , { "A3_I_VBROK"	, "" , "Tpo Vend."			, PesqPict( "SA3" , "A3_I_VBROK" )	  		} )
aAdd( aCampos , { "TRBF_CODVE"	, "" , "Coordenador"		, PesqPict( "SC5" , "C5_VEND2"   )	  		} )
aAdd( aCampos , { "TRBF_DESVE"	, "" , "Descricao Coordenador",PesqPict("SC5" , "C5_I_V1NOM" )	  		} )
aAdd( aCampos , { "C5_VEND1"	, "" , "Vendendor"		    , PesqPict( "SC5" , "C5_VEND1"   )	  		} )
aAdd( aCampos , { "C5_VEND3"	, "" , "Gerente"     	    , PesqPict( "SC5" , "C5_VEND3"   )	  		} )
aAdd( aCampos , { "C5_VEND4"	, "" , "Supervisor"		    , PesqPict( "SC5" , "C5_VEND4"   )	  		} )
aAdd( aCampos , { "TRBF_OPER"	, "" , "Operação"			, PesqPict( "SC5" , "C5_I_OPER"	 )	 		} )
aAdd( aCampos , { "C5_I_TAB"	, "" , "Tab Preco"			, PesqPict( "SC5" , "C5_I_TAB"	 )	 		} )
aAdd( aCampos , { "SC9_STATUS"	, "" , "Status"   			, "@!"                              		} )  

_aCabXML:={}
aAdd(_aCabXML,{"Status" ,1           ,1         ,.F.})
For _nni := 3 to Len(aCampos)
	// Alinhamento: 1-Left   ,2-Center,3-Right
	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
	//             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
	aAdd(_aCabXML,{aCampos[_nni,3]    ,1           ,1         ,.F.})
Next _nni

// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
If Select("TRBF") > 0
	TRBF->(DBCloseArea())
	If ValType(_otemp) == "O"
		_otemp:Delete()
	EndIf
EndIf

oproc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_otemp := FWTemporaryTable():New( "TRBF", aEstru )

oproc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()
_otemp:AddIndex( "DP", {"TRBF_DTEMI","TRBF_NUM"} )
_otemp:AddIndex( "NM", {"TRBF_NUM"} )
_otemp:AddIndex( "V1", {"C5_VEND1"} )

_otemp:Create()

If Select("QRYPED") > 0
	QRYPED->( DBCloseArea() )
EndIf

// Query para selecao dos dados DOS PEDIDOS
_cQuery := "	SELECT		C5.R_E_C_N_O_ C5REC "
_cQuery += "	FROM		" + RETSQLNAME("SC5") + " C5 "

_cQuery += "	WHERE			C5.D_E_L_E_T_ = ' ' "
_cQuery += "				AND C5.C5_NOTA    = ' '  "
_cQuery += "                AND C5.C5_I_TRCNF <> 'S'  "

_cQuery += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SA3")+ "  "
_cQuery += "                    WHERE D_E_L_E_T_ = ' ' AND A3_FILIAL = '"+xFilial("SA3")+"' AND A3_COD = C5.C5_VEND1 "
_cQuery += "                   AND A3_I_ROTE <> '2' "
_cQuery += " ) "

// Filtra Gerente
If !Empty( MV_PAR71 )             
	If Len(AllTrim(MV_PAR71)) <= 6
		_cQuery += " AND C5.C5_VEND3 = '"+ AllTrim(MV_PAR71) + "' "
	Else
		_cQuery += " AND C5.C5_VEND3 IN "+ FormatIn( MV_PAR71 , ";" )
	EndIf
EndIf

// Filtra Coordenador
If !Empty( MV_PAR72 )             
	If Len(AllTrim(MV_PAR72)) <= 6
		_cQuery += " AND C5.C5_VEND2 = '"+ AllTrim(MV_PAR72) + "' "
	Else
		_cQuery += " AND C5.C5_VEND2 IN "+ FormatIn( MV_PAR72 , ";" )
	EndIf
EndIf

// Filtra Supervisor
If !Empty( MV_PAR73 )      
	If Len(AllTrim(MV_PAR73)) <= 6
		_cQuery += " AND C5.C5_VEND4 = '"+ AllTrim(MV_PAR73) + "' "
	Else
		_cQuery += " AND C5.C5_VEND4 IN "+ FormatIn( MV_PAR73 , ";" )
	EndIf
EndIf

// Filtra Vendedor
If !Empty( MV_PAR74 )      
	If Len(AllTrim(MV_PAR74)) <= 6
		_cQuery += " AND C5.C5_VEND1 = '"+ AllTrim(MV_PAR74) + "' "
	Else
		_cQuery += " AND C5.C5_VEND1 IN "+ FormatIn(MV_PAR74, ";" )
	EndIf
EndIf

// Filtra Filial logada
_cQuery += " AND C5.C5_FILIAL	= '"+ xFilial("SC5") +"' "

// Pedido Funcionario ignora
_cQuery += " AND  C5.C5_I_OPER = '01' "

//Pedidos com bloqueio de bonificação
_cQuery += " AND C5_I_BLOQ <> 'B'  "
_cQuery += " AND C5_I_BLOQ <> 'R' "

// Pedidos que só tenham os armazens Armazens 70;72;20;22
_cQuery += " AND NOT EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C6 "
_cQuery += "                        WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM "
_cQuery += "                                                   AND C6.C6_LOCAL NOT IN "+ FormatIn( "70;72;20;22" , ";" ) + " )"

// Apenas os Pedidos de Tipo Normal podem ser  alterados.
_cQuery += " AND C5.C5_TIPO = 'N' "

_cQuery += " ORDER BY C5_EMISSAO,C5_NUM

oproc:cCaption := ("Carregando query de pedidos...")
ProcessMessages()

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,"QRYPED")

oproc:cCaption :="Contando os pedidos..."
ProcessMessages()

nPesTit	:= 0
nValTit := 0
nQtdTit := 0
nTotPV  := 0
DBSelectArea("QRYPED")
COUNT TO nTotPV
_cTot:=AllTrim(Str(nTotPV))
_nTam:=Len(_cTot)
_npv:=1
_aColXML:={}
_aItem:={}

SC6->(DBSetOrder(1))

QRYPED->(DBGoTop())
While QRYPED->(!Eof())
	
	//Atualiza régua
	oproc:cCaption := ("Lendo Pedidos: ["+ StrZero(_npv,_nTam) +"] de ["+ _cTot+"]")
	ProcessMessages()
	_npv++
	
	SC5->(DBGoTo(QRYPED->C5REC))
	_lTemSC9:=.F.
	_lTodoLiberado:=.F.
	_lPVtemCarga  :=.F.
	If SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	   _lTemSC9:=.T.
  	   _lTodoLiberado:=.T. //SE TIVER TODO LIBERADO NÃO PODE ALTERAR PQ NÃO PRECISA
	   While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL+SC5->C5_NUM
			If !Empty(SC9->C9_CARGA)
				_lPVtemCarga:=.T.
				Exit
			EndIf
			If !Empty(SC9->C9_BLEST) //TÁ COM BLOQUEI DE ESTOQUE PODE ALTERAR 
				_lTodoLiberado:=.F.
				Exit
			EndIf
			SC9->(DBSkip())
	   EndDo
	EndIf
		
	If _lPVtemCarga
		QRYPED->( DBSkip() )
		Loop
	EndIf
	
	//Pedidos com liberação ok de estoque
	If MV_PAR91 = "1" //"1-EXPORTA P/ ROTEIRIZADOR" LE LIBERADOS DE TUDO
		If !_lTodoLiberado//IGNORA NÃO LIBERADOS OU LIBERADO COM BLOQUEIO DE ESTOQUE
			QRYPED->( DBSkip() )
			Loop
		EndIf
		
	Else //"2-CORTES DE PV DE VAREJO " LE NÃO LIBERADOS

		If _lTodoLiberado//IGNORA TODOS LIBERADOS SEM BLOQUEIO DE ESTOQUE
  			QRYPED->( DBSkip() )
  			Loop
		EndIf
		
	EndIf
 
	_nvalsc5:=0   
	_cTipoCarga:=""
	_lLoop:=.F.
	SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	While SC6->(!Eof()) .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM

		_cTipoCarga := Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPCAR")
		If _cTipoCarga = '000002'
		   _lLoop:=.T.
           Exit
		EndIf

		_nvalsc5 += SC6->C6_QTDVEN * SC6->C6_PRCVEN
		SC6->(DBSkip())
	EndDo

    If _lLoop//_cTipoCarga = '000002'
	   QRYPED->( DBSkip() )
  		Loop
	EndIf
	
	_cTipoag := ""
	If AllTrim(SC5->C5_I_AGEND) $ "I/O"
	   _cTipoag := U_TipoEntrega(SC5->C5_I_AGEND)//_cTipoag := "IMEDIATA"
	Else   
       If SC5->C5_I_DTENT > (DATE()+1)
		  QRYPED->( DBSkip() )
		  Loop
       EndIf
	   _cTipoag := U_TipoEntrega(SC5->C5_I_AGEND)
	EndIf

	TRBF->(DBAPPEND())
	TRBF->TRBF_FILIA	:= SC5->C5_FILIAL
	TRBF->TRBF_NUM		:= SC5->C5_NUM
	TRBF->TRBF_OPER     := SC5->C5_I_OPER
	TRBF->TRBF_DTEMI	:= SC5->C5_EMISSAO
	TRBF->TRBF_DTENT	:= SC5->C5_I_DTENT
	TRBF->TRBF_CODCL	:= SC5->C5_CLIENTE
	TRBF->TRBF_LOJCL	:= SC5->C5_LOJACLI
	TRBF->TRBF_DESCL	:= SC5->C5_I_NOME
	TRBF->TRBF_UF   	:= SC5->C5_I_EST
	TRBF->TRBF_CEP   	:= SC5->C5_I_CEP
	TRBF->TRBF_CODRE	:= SC5->C5_I_GRPVE
	TRBF->TRBF_DESCR	:= SC5->C5_I_NOMRD
	TRBF->TRBF_CODVE	:= SC5->C5_VEND2//Coordenador
	TRBF->TRBF_DESVE	:= Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NOME")//SC5->C5_I_V1NOM
	TRBF->C5_VEND1  	:= SC5->C5_VEND1+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME")//Vendedor
	TRBF->C5_VEND3  	:= SC5->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND3,"A3_NOME")//Gerente
	TRBF->C5_VEND4  	:= SC5->C5_VEND4+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND4,"A3_NOME")//Supervisor
	TRBF->TRBF_AGEND 	:= _ctipoag
	TRBF->C5_I_PEVIN 	:= SC5->C5_I_PEVIN
	TRBF->C5_I_ENVRD 	:= SC5->C5_I_ENVRD
	TRBF->C5_I_TRCNF 	:= SC5->C5_I_TRCNF
  	TRBF->SC9_STATUS 	:= If(_lTemSC9,If(_lTodoLiberado,"LIBERADO","LIBERADO COM BLOQUEIO DE ESTOQUE"),"NAO LIBERADO")
	TRBF->C5_LIBEROK 	:= SC5->C5_LIBEROK
	TRBF->C5_I_PESBR 	:= SC5->C5_I_PESBR
	TRBF->C5_I_BLCRE 	:= SC5->C5_I_BLCRE
	TRBF->C5_I_BLPRC 	:= SC5->C5_I_BLPRC
	TRBF->C5_I_BLOQ 	:= SC5->C5_I_BLOQ
	TRBF->C5_I_BLOG 	:= SC5->C5_I_BLOG
	TRBF->TRBF_MUN	 	:= SC5->C5_I_MUN
	TRBF->TRBF_DTNES    := SC5->C5_I_DTNEC
	TRBF->TRBF_VALOR    := _nvalsc5
	TRBF->A3_I_VBROK    := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_I_VBROK")
	TRBF->C5_I_TAB     := SC5->C5_I_TAB

    _aItem:={}
    aAdd(_aItem,SubStr(MOMS047CL(),4))    
    For _nni := 3 TO Len(aCampos)
        _nPos:=TRBF->(FIELDPOS(aCampos[_nni,1]))
        If _nPos <> 0
	       aAdd(_aItem,TRBF->(FIELDGET(_nPos)))
	    EndIf   
    Next _nni
    aAdd(_aColXML,_aItem)
	
	QRYPED->( DBSkip() )
	
EndDo

QRYPED->( DBCloseArea())

TRBF->(DBGoTop())

If Len(_aItem) > 0 .And. Len(_aItem) <> Len(_aCabXML)
   U_ITMsg("Não será possivel gerar XML [Len(_aItem): "+Str(Len(_aItem),2)+" <> Len(_aCabXML): "+Str(Len(_aCabXML),2)+"]",'Atenção!',"AVISE A AREA DE TI SOBBRE ESSE PROBLEMA POR FAVOR",3)//ALERT
EndIf

If _lcabec  //Inicializa cabecalho

	oQtda:Refresh()
	oPesa:Refresh()
	oValor:Refresh()

   DBSelectArea("TRBF")
   TRBF->(DBGoTop())
   If TRBF->(Bof()) .And. TRBF->(Eof())
      U_ITMsg("NÃO HÁ MAIS PEDIDOS PARA PROCESSAR",'Atenção!',"TENTE NOVAMENTE MAIS TARDE",1)
      Return .F.
   EndIf

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS047PPV
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Função para visualizar Pedidos de Vendas
Parametros--------: Nenhum

Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS047PPV()

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	MatA410(Nil, Nil, Nil, Nil, "A410Visual")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS047AI
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Analisa itens
Parametros--------: _cped - Numero do pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047AI(cPED)

Local _cnomefil	:= ""
Local _ccodcomp	:= ""

Private oAzul 	  := LoadBitmap( GetResources(), "BR_AZUL" )
Private oAmarelo  := LoadBitmap( GetResources(), "BR_AMARELO" )
Private oVerde    := LoadBitmap( GetResources(), "BR_VERDE" )
Private aSize     := {}
Private aLigacoes := {}
Private aCC       := {}

//Se não tem registros já retorna
If 	Empty(cPED)
	
	U_ITMsg("Nenhum registro selecionado","Atenção",,1)
	TRBF->(DBGoTop())
	Return
	
EndIf


MOMS047S() //Função utilizada para mostrar as configurações de tela do usuário

SC6->( DBSetOrder(1) )
SC6->( DBSeek(xFilial("SC6")+AllTrim(CPED),.T.) )

SC5->( DBSetOrder(1) )
SC5->( DBSeek(xFilial("SC5")+AllTrim(CPED)) )

nQtd2UM := 0
SC9->(DBSetOrder(1))
SB1->(DBSetOrder(1))

While SC6->(!Eof()) .And. SC6->C6_NUM == AllTrim(CPED)
	
	
	SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
	nFator  := SB1->B1_CONV
	cTipConv:= SB1->B1_TIPCONV
	nNewFat := SB1->B1_I_FATCO
	
	nFator := (If(nFator == 0, nNewFat, nFator))
	If cTipConv == 'D'
		nQtd2UM := SC6->C6_QTDVEN/nFator
	ElseIf cTipConv == 'M'
		nQtd2UM := SC6->C6_QTDVEN*nFator
	EndIf
	
	_cBloq:=" "
	If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		If !Empty(SC9->C9_BLEST)  // verifica estoque se não tem liberação válida ainda
			_cBloq:="B"
		EndIf
	Else
		_cBloq := "N"  //não tem liberação
	EndIf
	
	If SB2->(DBSeek(xFilial("SB2") + SC6->C6_PRODUTO + SC6->C6_LOCAL))
		_nSaldo:=(SB2->B2_QATU - SB2->B2_QEMP - SB2->B2_QEMPN - SB2->B2_RESERVA - SB2->B2_QACLASS)
	Else
		_nSaldo := 0
	EndIf
	
	aAdd(aCC, {	" ",;//01
	            SC6->C6_ITEM,;//02
	            AllTrim(SC6->C6_PRODUTO),;//03
	            AllTrim(SB1->B1_DESC),;//04
            	AllTrim(SC6->C6_UM),;//05
	            Transform(SC6->C6_QTDVEN,"@E 999,999,999.99999"),;//06
	            SC6->C6_LOCAL,;//17
	            Transform(_nSaldo,"@E 999,999,999,999,999.99999"),;//08
	            GetAdvFVal("SB1","B1_SEGUM",xFilial("SB1")+SC6->C6_PRODUTO,1,""),;//09
            	Transform(nQtd2UM,"@E 999,999,999.99999"),;//10
            	Transform(SC6->C6_PRCVEN, "@E 9,999.99"),;//11
            	Transform(SC6->C6_QTDVEN*SC6->C6_PRCVEN, "@E 999,999.99"),;//12
	            _cBloq}) //13
  	SC6->( DBSkip() )
	
End

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
SC5->( DBSeek(xFilial("SC5")+CPED) )

aLigacoes := aSort(aCC,,,{|x,y|x[2]<y[2]})

If Len(aLigacoes) <= 0
	
	Help(" ",1,"SEMDADOS" )
	Return(.F.)
	
EndIf
lClos := .F.
DEFINE MSDIALOG _oDlgHist FROM 1,000 TO aSize[6],aSize[5] TITLE "Itens do Pedido " + CPED  PIXEL

_cnomefil := AllTrim(SC5->C5_FILIAL) + " / " + FWFilialName(cEmpAnt,SC5->C5_FILIAL)
If Empty(SC5->C5_I_FILFT)
	_cnomefat := AllTrim(SC5->C5_FILIAL) + " / " + FWFilialName(cEmpAnt,SC5->C5_FILIAL)
Else
	_cnomefat := AllTrim(SC5->C5_I_FILFT) + " / " + FWFilialName(cEmpAnt,SC5->C5_I_FILFT)
EndIf
If SC5->C5_I_TRCNF = "S"
	_cnomefat := "Troca Nota - " + _cnomefat
Else
	_cnomefat := "Faturamento Direto - " + _cnomefat
EndIf

@ 005,005 Say "Pedido:"
@ 005,040 Get CPED        Picture "@!"  SIZE 050,10 when .F.
@ 005,090 Get _cnomefil   Picture "@!"  SIZE 200,10 when .F.

@ 005,330 Say "Filial Faturamento:"
@ 005,375 Get _cnomefat   Picture "@!"  SIZE 200,10 when .F.

@ 020,005 Say "Cliente:"

_ccodcomp := AllTrim(SC5->C5_CLIENTE) + " / " + AllTrim(SC5->C5_LOJACLI)

@ 020,040 Get _ccodcomp  Picture "@!"  SIZE 050,10 when .F.
@ 020,090 Get AllTrim(GetAdvFval("SA1","A1_NOME",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 020,330 Say "Loja cliente: "
@ 020,375 Get AllTrim(GetAdvFval("SA1","A1_NREDUZ",xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 035,005 Say "Vendedor:"
@ 035,040 Get SC5->C5_VEND1 Picture "@!"  SIZE 050,10 when .F.
@ 035,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND1,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 050,005 Say "Coordenador:"
@ 050,040 Get SC5->C5_VEND2 Picture "@!"  SIZE 050,10 when .F.
@ 050,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND2,1,"")) Picture "@!"  SIZE 200,10 when .F.

@ 065,005 Say "Gerente:"
@ 065,040 Get SC5->C5_VEND3 Picture "@!"  SIZE 050,10 when .F.
@ 065,090 Get AllTrim(GetAdvFval("SA3","A3_NOME",xFilial("SA3")+SC5->C5_VEND3,1,"")) Picture "@!"  SIZE 200,10 when .F.

@080,05 LISTBOX oLbx FIELDS HEADER 	" ","Item","Produto","Descriçâo","1ªUM","Qtd 1ªUM","Armazem","Saldo Armazem","2ªUM","Qtd 2ªUM","Prc Vend","Total" ;
SIZE aSize[3],aSize[4]-110 OF _oDlgHist PIXEL

oLbx:SetArray(aLigacoes)
oLbx:bLine:={||{If(aLigacoes[oLbx:nAt,13]='N',oVerde,If(aLigacoes[oLbx:nAt,13]='B',oAzul,oAmarelo)),;
						aLigacoes[oLbx:nAt,2],;
						aLigacoes[oLbx:nAt,3],;
						aLigacoes[oLbx:nAt,4],;
						aLigacoes[oLbx:nAt,5],;
						aLigacoes[oLbx:nAt,6],;
						aLigacoes[oLbx:nAt,7],;
						aLigacoes[oLbx:nAt,8],;
						aLigacoes[oLbx:nAt,9],;
						aLigacoes[oLbx:nAt,10],;
						aLigacoes[oLbx:nAt,11],;
						aLigacoes[oLbx:nAt,12]}}

oLbx:Refresh()
oLbx:SetFocus(.T.)

@ aSize[4]-20,aSize[3]-130 	Button "&Opcoes"	Size 037,012 action (FWMsgRun(,{ || MOMS047O()},"Aguarde...","Carregando tela de opções de armazéns..."))
@ aSize[4]-20,aSize[3]-65 	Button "&Sair" 		Size 037,012 action (lClos := .F.,_oDlgHist:end())

ACTIVATE MSDIALOG _oDlgHist CENTER

Return

/*
===============================================================================================================================
Programa----------: MOMS047S
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Função utilizada para mostrar as configurações de tela do usuário
Parametros--------: _nPosEnch,_nPosGetDados,_lDimensao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047S(_nPosEnch,_nPosGetDados,_lDimensao)

Local aObjects:= {}
Local aInfo   := {}
Local aPosObj := {}
aSize   := {}

DEFAULT _nPosEnch    := 0
DEFAULT _nPosGetDados:= 0
DEFAULT _lDimensao   :=.F.

// Obtém a a área de trabalho e tamanho da dialog
aSize := MsAdvSize()

aAdd( aObjects, { _nPosEnch    , _nPosEnch    , .T., .T.             } ) // Dados da Enchoice
aAdd( aObjects, { _nPosGetDados, _nPosGetDados, .T., .T. ,_lDimensao } ) // Dados da getdados

// Dados da área de trabalho e separação
aInfo 	:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3, 3, 3 } // Chama MsObjSize e recebe array e tamanhos

aPosObj := MsObjSize( aInfo, aObjects,.T.)

Return aPosObj

/*
===============================================================================================================================
Programa----------: MOMS047Legenda()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: LEGENDA
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047Legenda()

Local aLegenda := {}

aAdd(aLegenda, {"BR_VERDE"	,"PV sem liberação"})
aAdd(aLegenda, {"BR_AZUL"   ,"PV com bloqueio de estoque"})
aAdd(aLegenda, {"BR_AMARELO","PV liberado para faturamento "})
aAdd(aLegenda, {"BR_VIOLETA","PV com bloqueio de crédito"})
aAdd(aLegenda, {"BR_BRANCO" ,"PV com bloqueio de preço"})

BrwLegenda("Legenda","Legenda",aLegenda)

Return .T.

/*
===============================================================================================================================
Programa--------: MOMS047CL
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Retorna cor e legenda
Parametros------: Nenhum
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
Static Function MOMS047CL()

Local _ccor := "BR_VERDE"

	If AllTrim(TRBF->SC9_STATUS) == "LIBERADO"
		
		_ccor := "BR_AMARELO" //Liberacao de estoque ok 
		
	ElseIf AllTrim(TRBF->SC9_STATUS) == "LIBERADO COM BLOQUEIO DE ESTOQUE"
		
		_ccor := "BR_AZUL"   //Liberacao de estoque com bloqueio de produto
		
	EndIf
	
If TRBF->C5_I_BLCRE=="B" .Or. TRBF->C5_I_BLCRE=="R"
	
	_ccor := "BR_VIOLETA" //Bloqueio de crédito
	
EndIf

If TRBF->C5_I_BLPRC == 'B' .Or. TRBF->C5_I_BLPRC == 'R'
	
	_ccor := "BR_BRANCO" //Bloqueio de preço
	
EndIf

If TRBF->C5_I_BLOQ == 'B' .Or. TRBF->C5_I_BLOQ == 'R'
	
	_ccor := "BR_PRETO" //Bloqueio de bonificação
	
EndIf

If TRBF->C5_LIBEROK != 'S' .And. TRBF->C5_I_BLOG == 'S'
	
	_ccor := "BR_MARRON" //Bloqueio de logistica
	
EndIf

Return _ccor

/*
===============================================================================================================================
Função------------: MOMS047O
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Tela de opções de armazéns para produtos com bloqueio de estoque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047O()

Local oBtSair
Local oGrEst
Local oSay1
Local oSayCli
Local oSayCln
Local oSayDt
Local oSayPd
Local oSayPn
Local _cQry			:= ""
Local _nSaldo		:= 0
Local _nY			:= 0
Local _aHeaderIt	:= {}
Local _aColsIt		:= {}
Local _aHeaderEs	:= {}
Local _aColsEs		:= {}
Local _aIn			:= {}
Local _cFilial      := cFilant
Local _cPedido      := TRBF->TRBF_NUM
Local _dDataLib     := TRBF->TRBF_DTLIB
Local _cCliente     := TRBF->TRBF_CODCL
Local _cLoja        := TRBF->TRBF_LOJCL

Private _nSldTot	:= 0
Private oMSNewGIt
Private oMSNewGEs
Private oDlgEst

aAdd( _aHeaderIt, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderIt, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Produto","C9_PRODUTO","@!                                           ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderIt,{"Qt Liberada","C9_QTDLIB ","@E 9,999,999.999                             ",11,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Prc Venda","C9_PRCVEN ","@E 999,999,999.99999999                      ",18,8," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})
aAdd( _aHeaderIt,{"Armazem","C9_LOCAL  ","@!                                           ",2,0,'ExistCpo("NNR") ',"€€€€€€€€€€€€€€ ","C","NNR   "," "," "," "})


DBSelectArea("SC9")
SC9->(DBSetOrder(1))
SC9->(DBSeek(_cFilial + _cPedido))

While !SC9->(Eof()) .And. SC9->C9_FILIAL == _cFilial .And. SC9->C9_PEDIDO == _cPedido
	If !Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_PRETO")   , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_AZUL")    , SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	ElseIf !Empty(SC9->C9_BLEST) .And. !Empty(SC9->C9_BLCRED)
		aAdd(_aColsIt,{LoadBitmap(GetResources(),"BR_VERMELHO"), SC9->C9_ITEM, Posicione("SB1",1,xFilial("SB1")+SC9->C9_PRODUTO,"B1_DESC"), SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_LOCAL, .F.})
	EndIf
	SC9->(DBSkip())
End

aAdd( _aHeaderEs, { 'Status'			, 'CHECKBOL', '@BMP', 10, 0,,, 'C',, 'V' ,  ,  , 'legenda', 'V', 'S' } )
aAdd( _aHeaderEs, {"Item","C9_ITEM   "," ",2,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Produto","C9_PRODUTO","@!                        ",15,0," ","€€€€€€€€€€€€€€ ","C"," "," "," "," "})
aAdd( _aHeaderEs,{"Codigo","NNR_CODIGO","@!                                           ",2,0,'ExistChav("NNR")      ',"€€€€€€€€€€€€€€°","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Descricao","NNR_DESCRI","@!                                           ",20,0,"NaoVazio()                ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "})
aAdd( _aHeaderEs,{"Saldo Atual","B2_QATU   ","@E 9,999,999,999.999                         ",14,3," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "})

_cQry := "SELECT C9_ITEM, C9_PRODUTO, C9_LOCAL, NNR_CODIGO, NNR_DESCRI, NNR_I_OPC "
_cQry += "FROM " + RetSqlName("SC9") + " SC9 "
_cQry += "JOIN " + RetSqlName("NNR") + " NNR ON NNR_FILIAL = '" + xFilial("NNR") + "' AND NNR_CODIGO = C9_LOCAL AND NNR.D_E_L_E_T_ = ' ' "
_cQry += "WHERE C9_FILIAL = '" + _cFilial + "' "
_cQry += "  AND C9_PEDIDO = '" + _cPedido + "' "
_cQry += "  AND (C9_BLEST <> ' ' OR C9_BLCRED <> ' ') "
_cQry += "  AND SC9.D_E_L_E_T_ = ' ' "
_cQry := ChangeQuery(_cQry)

MPSysOpenQuery(_cQry,"TRBARM")

DBSelectArea("TRBARM")
TRBARM->(DBGoTop())

If !TRBARM->(Eof())
	While !TRBARM->(Eof())
		_aIn := StrTokArr(TRBARM->C9_LOCAL+";"+AllTrim(TRBARM->NNR_I_OPC),";")
		For _nY := 1 To Len(_aIn)
			DBSelectArea("SB2")
			SB2->(DBSetOrder(1))
			If SB2->(DBSeek(xFilial("SB2") + TRBARM->C9_PRODUTO + _aIn[_nY]))
				_nSaldo := SaldoSb2()
				If _nSaldo > 0
					_nSldTot += _nSaldo
					aAdd(_aColsEs, {LoadBitmap(GetResources(),"BR_VERDE"),TRBARM->C9_ITEM,Posicione("SB1",1,xFilial("SB1")+TRBARM->C9_PRODUTO,"B1_DESC"),_aIn[_nY],AllTrim(Posicione("NNR",1,xFilial("NNR") + _aIn[_nY],"NNR_DESCRI")),_nSaldo,.F.})
				EndIf
			EndIf
		Next _nY
		TRBARM->(DBSkip())
	End
EndIf

_aColsEs := aSort(_aColsEs,,,{|x,y| x[2] < y[2]})

DBSelectArea("TRBARM")
TRBARM->(DBCloseArea())

DEFINE MSDIALOG oDlgEst TITLE "Ocorreram restrições na liberação do pedido:" FROM 000, 000  TO 520, 700 COLORS 0, 16777215 PIXEL

	@ 009, 006 Say oSayPd PROMPT "Pedido:" SIZE 022, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 030 Say oSayPn PROMPT _cPedido SIZE 025, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 062 Say oSayDt PROMPT "Emissão:" SIZE 025, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 090 Say oSay1 PROMPT _dDataLib SIZE 032, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 009, 130 Say oSayCli PROMPT "Cliente:" SIZE 019, 007 OF oDlgEst COLORS 0, 16777215 PIXEL
	@ 009, 150 Say oSayCln PROMPT _cCliente + "/" + _cLoja + "-" + Posicione("SA1", 1, xFilial("SA1") + _cCliente + _cLoja, "A1_NOME") SIZE 149, 007 OF oDlgEst COLORS 16711680, 16777215 PIXEL
	@ 005, 305 BUTTON oBtSair PROMPT "Sair" SIZE 037, 012 OF oDlgEst ACTION oDlgEst:End() PIXEL

	oMSNewGIt := MsNewGetDados():New( 025, 006, 127, 343, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderIt, _aColsIt)

	@ 130, 006 BITMAP oBmp RESNAME "BR_PRETO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 130, 015 Say "Bloqueio Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 130, 106 BITMAP oBmp RESNAME "BR_AZUL" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 130, 115 Say "Bloqueio Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 130, 206 BITMAP oBmp RESNAME "BR_VERMELHO" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 130, 215 Say "Bloqueio Estoque/Crédito" OF oDlgEst SIZE 100,10 PIXEL

	@ 141, 006 GROUP oGrEst TO 250, 344 PROMPT "Estoques Opcionais" OF oDlgEst COLOR 0, 16777215 PIXEL

	oMSNewGEs := MsNewGetDados():New( 150, 012, 236, 339, 0, "AllwaysTrue", "AllwaysTrue", "", {},, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgEst, _aHeaderEs, _aColsEs)

	@ 240, 009 BITMAP oBmp RESNAME "BR_VERDE" OF oDlgEst SIZE 20,20 NOBORDER PIXEL
	@ 240, 018 Say "Com Estoque" OF oDlgEst SIZE 100,10 PIXEL

	@ 240, 150 Say "Saldo Total:" OF oDlgEst SIZE 100,10 PIXEL
	@ 240, 220 Say AllTrim(Transform(_nSldTot,PesqPict("SC9","C9_QTDLIB"))) OF oDlgEst COLORS 0, 16777215 SIZE 100,10 PIXEL

ACTIVATE MSDIALOG oDlgEst CENTERED

Return

/*
===============================================================================================================================
Programa----------: MOMS047V
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Analise de pedido de Varejo
Parametros--------: oproc = Objeto de processamento para imcrementação da régua de processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047V(oproc)

Local _aPedSC9 := {}
Local _nRegAtu := TRBF->(Recno())
Local _nRegSC5 := SC5->(Recno())
Local _nI,R,nPos,_nConta:=0
Private _aPedRejeicao:= {}
Private _aResultado  := {}
Private _aPedidos    := {}
Private _aItensTot   := {}

If !U_ITMsg("Confirma Analise dos PVs marcados?",'Atenção!',"PVs em em AZUL (Bloq. Estoque) serão alterados para liberar o Estoque",3,2,3,,"CONFIRMA","Voltar")
   Return .F.
EndIf

Begin Sequence

SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM
SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
SA1->(DBSetOrder(1))
SA3->(DBSetOrder(1))

TRBF->(DBSetOrder(1))//ORDEM DE DATA DE EMISSÃO
TRBF->(DBGoTop())
_cTot:= AllTrim(Str( TRBF->(LASTREC()) ))
_cLOG:="PV;ITEM;SALDO 70;SALDO 72;SALDO 20;SALDO 22;QTDE"+CRLF

While TRBF->(!Eof())
	// Somente pedidos selecionados pelo usuario
	If oproc <> NIL
		_nConta++
		oproc:cCaption := ("Analisando Estoque, PV: " + TRBF->TRBF_NUM + " [ "+ StrZero(_nConta,Len(_cTot)) +" de "+ _cTot+" ] ["+AllTrim(Str(Len(_aPedSC9)))+" PV OK]" )
		ProcessMessages()
	EndIf
	If !Empty(TRBF->TRBF_OK)

		//Posiciona tabelas
		If !(SC5->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM)))    //Se não achar na sc5 pula para próximo marcado
			TRBF->(DBSkip())
			Loop
		EndIf
        
        _cMen:=""
        If !SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE)) .Or. SA1->A1_MSBLQL = '1'
           _cMen:="Cliente Bloqueado no Protheus."+CRLF
        EndIf   

		If SA3->(DBSeek(xFilial("SA3")+SC5->C5_VEND1))
           If SA3->A3_MSBLQL = '1'
              _cMen+="Vendedor do Pedido Bloqueado no Protheus. "+CRLF
           EndIf   
        Else
           _cMen:="Vendendor não encontrado: "+SC5->C5_VEND1+CRLF
		EndIf

        If !Empty(SC5->C5_NOTA)
            _cMen+="Pedido esta na Nota: "+SC5->C5_NOTA
	    EndIf

		If  !Empty(_cMen)
			aAdd(_aResultado,{ .F.,;            //01
			                  TRBF->TRBF_FILIA,;//02
			                  TRBF->TRBF_NUM  ,;//03
			                  ""              ,;//04
			                  ""              ,;//05
			                  ""              ,;//06
			                  ""              ,;//07
			                  ""              ,;//08 "Arm 70"
			                  ""              ,;//09 "Arm 72"
			                  ""              ,;//10 "Arm 20"
			                  ""              ,;//11 "Arm 22"
			                  _cMen           ;//12
			                  })
			TRBF->(DBSkip())
			Loop
		EndIf
		
		_lTodoLiberado:=.F.
		_lPVtemCarga  :=.F.
	    _lTemSC9      :=.F.
	    If SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	       _lTemSC9      :=.T.
  	       _lTodoLiberado:=.T. //SE TIVER TODO LIBERADO NÃO PODE ALTERAR PQ NÃO PRECISA
		   While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == TRBF->TRBF_FILIA+TRBF->TRBF_NUM
				If !Empty(SC9->C9_CARGA)
					_lPVtemCarga:=.T.
					Exit
				EndIf
				If !Empty(SC9->C9_BLEST) //TÁ COM BLOQUEIO DE ESTOQUE PODE ALTERAR
					_lTodoLiberado:=.F.
					Exit
				EndIf
				SC9->(DBSkip())
		   EndDo
		EndIf
		
	    _aPedRejeicao:={{.T.,""}}//ZERA POR PV
		If  _lTodoLiberado .Or. _lPVtemCarga
			If _lPVtemCarga
               _cMen:="Pedido esta na Carga: "+SC9->C9_CARGA+"."
            Else//_lTodoLiberado
               _cMen:="Pedido de Vendas já liberado."
			EndIf
			
			aAdd(_aResultado,{ .F.,;             //01
			                  TRBF->TRBF_FILIA,;//02
			                  TRBF->TRBF_NUM+" - "+DToC(TRBF->TRBF_DTEMI),;//03
			                  ""              ,;//04
			                  ""              ,;//05
			                  ""              ,;//06
			                  ""              ,;//07
			                  ""              ,;//08 "Arm 70"
			                  ""              ,;//09 "Arm 72"
			                  ""              ,;//10 "Arm 20"
			                  ""              ,;//11 "Arm 22"
			                  _cMen;//12
			                  })
			
			TRBF->(DBSkip())
			Loop
        
        ElseIf _lTemSC9 .And. !_lTodoLiberado //PV LIBERADOS E COM BLOQUEIO DE ESTOQUE LIBERAMOS O ESTOQUE 

	        _aPedRejeicao:={}//ZERA POR PV
		    MOMS047QGR(TRBF->TRBF_FILIA,TRBF->TRBF_NUM,.T.,oProc)//SO ALTERA O PV PARA LIBERAR O ESTOQUE
        
		EndIf
		
		aAdd(_aPedSC9,{.T.,TRBF->TRBF_FILIA,TRBF->TRBF_NUM})
		
		_cProdutos:=""
		_aResulAux:={}
		
		SC6->( DBSeek( TRBF->TRBF_FILIA+TRBF->TRBF_NUM ) )
		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == TRBF->TRBF_FILIA+TRBF->TRBF_NUM
			
			_cProdutos+=SC6->C6_PRODUTO+";"
			
			// Grava o Array _aResulAux com todos os itens de um pedidos de vendas para grava na arrary _aResultado dentro da função Ver_Est_PV()
			aAdd(_aResulAux,{ .F.,;             //01
			                  SC6->C6_FILIAL  ,;//02
			                  SC6->C6_NUM +" - "+DToC(TRBF->TRBF_DTEMI),;//03
			                  SC6->C6_ITEM    ,;//04
			                  SC6->C6_PRODUTO ,;//05
			                  SC6->C6_LOCAL   ,;//06
			                  SC6->C6_QTDVEN  ,;//07
			                  "0,00"          ,;//08 "Arm 70"
			                  "0,00"          ,;//09 "Arm 72"
			                  "0,00"          ,;//10 "Arm 20"
			                  "0,00"          ,;//11 "Arm 22"
		                 	 _aPedRejeicao[1,2];//12 Erros
			                  })
			
			SC6->( DBSkip() )
			
		EndDo
		
		Ver_Est_PV(TRBF->TRBF_FILIA,_cProdutos,_aResulAux,.F.,TRBF->TRBF_FILIA+"-"+TRBF->TRBF_NUM )//ANALISA OS SALDOS DO PV
		
	EndIf
	
	TRBF->(DBSkip())
	
EndDo

While .T.
	
	lRet:=.T.
	
	If !Empty(_aResultado)
       _aItensTot:={}
	    For R := 1 TO Len(_aResultado)
		    If Empty(_aResultado[R,5] )
			   Loop
			EndIf
		    If (_nPos:=aScan(_aItensTot,{|A| A[1]+A[2] == _aResultado[R,2]+_aResultado[R,5]  } )) = 0
                             //     1                2                  3                 4                5               6                7                 8         9
                             //{"Filial"        ,"Produto"       ,"Qtde no PVs"   ,"Qtde Arm 70"    ,"Qtde Arm 72"  ,"Qtde Arm 20"   ,"Qtde Arm 22"     ,Qtde de PVs,Difereça}
			   aAdd(_aItensTot,{_aResultado[R,2],_aResultado[R,5],_aResultado[R,7],_aResultado[R,8],_aResultado[R,9],_aResultado[R,10],_aResultado[R,11],1          ,0})
		    Else
			   _aItensTot[_nPos,3]+=_aResultado[R,7]
			   _aItensTot[_nPos,8]++
			EndIf
		Next R
	    For R := 1 TO Len(_aItensTot)
		    _nSoma:=(_aItensTot[R,4]+_aItensTot[R,5]+_aItensTot[R,6]+_aItensTot[R,7])
			If _aItensTot[R,3] >  _nSoma
		       _aItensTot[R,9]:= (_nSoma -_aItensTot[R,3] )
			EndIf
		    _aItensTot[R,3]:=TRANS(_aItensTot[R,3],"@E 999,999,999,999.99")
		    _aItensTot[R,4]:=TRANS(_aItensTot[R,4],"@E 999,999,999,999.99")
		    _aItensTot[R,5]:=TRANS(_aItensTot[R,5],"@E 999,999,999,999.99")
		    _aItensTot[R,6]:=TRANS(_aItensTot[R,6],"@E 999,999,999,999.99")
		    _aItensTot[R,7]:=TRANS(_aItensTot[R,7],"@E 999,999,999,999.99")
		    _aItensTot[R,8]:=cValToChar(_aItensTot[R,8])
			If _aItensTot[R,9] <> 0
		       _aItensTot[R,9]:=TRANS(_aItensTot[R,9],"@E 999,999,999,999.99")
			Else
			   _aItensTot[R,9]:=""
			EndIf   
		Next R
		aSort(_aItensTot,,, {|X,Y| X[1]+X[2] < Y[1]+Y[2] } )
	    nPosResu:=Len(_aResultado[1])
	    aBotoes:={} //  1         2         3           4              5             6             7              8             9
        _aCabItens:={"Filial","Produto","Qtde no PVs","Qtde Arm 70","Qtde Arm 72","Qtde Arm 20","Qtde Arm 22","Qtde de PVs","Diferenca"}
		_aSize1   :={      10, 200     ,  55         ,       55    ,     55      , 55          ,55           ,55 }
        aAdd( aBotoes , {"",{||  U_ITListBox( 'Quantidade TOTAL por PRODUTOS' , _aCabItens , _aItensTot , .T. , 1 ,,,_aSize1)},"Produtos Totalizados","Produtos Totalizados"}) 
	    aAdd( aBotoes , {"",{|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
		_cTitAux:="Resultado para cortes dos Pedidos de Vendas de Varejo"
	        //   1     2        3        4       5          6             7          8        9       10       11        12
		_aCab:={" ","Filial","Pedido","Item","Produto","Arm. Atual","Qtde Atual","Arm 70","Arm 72","Arm 20","Arm 22","Observação"}
		_aSize:={05,10      ,15      ,10    ,150      ,35          ,35          ,30      ,30      ,30      ,30      ,200         }
		//      ITListBox(_cTitAux, _aHeader , _aCols     , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons)
		lRet:=U_ITLISTBOX(_cTitAux, _aCab    , _aResultado, .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes  )
		
	EndIf
	
	If lRet .And. Empty(_aPedSC9)
		U_ITMsg("Nenhum pedido de vendas apto para essa ação.","Atenção",,1)
		Break
	ElseIf !lRet
		Break
	EndIf
	
	If !U_ITMsg("CONFIRMA ALTERAÇÃO DOS PEDIDOS?",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")//ALERT
		Loop
	EndIf
	
	Exit
	
EndDo

_cTot := AllTrim(Str(Len(_aPedSC9),))
_aResultado:={}
_cLOG:="PV;ITEM;SALDO 70;SALDO 72;SALDO 20;SALDO 22;QTDE;QUERY"+CRLF
SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM
SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

For _nI := 1 To Len(_aPedSC9)
	
	If oProc <> NIL
		oProc:cCaption := ("Alterando Pedido: " + _aPedSC9[_nI,3] + " "+ StrZero(_nI,Len(_cTot)) +" de "+ _cTot )
		ProcessMessages()
	EndIf
	
	If !(SC5->(DBSeek(_aPedSC9[_nI,2]+_aPedSC9[_nI,3])))    //Se não achar na sc5 pula para próximo marcado
		Loop
	EndIf
	
	_cProdutos   :=""//ZERA POR PV
	_aResulAux   :={}//ZERA POR PV
	_aPedidos    :={}//ZERA POR PV
	_aPedRejeicao:={}//ZERA POR PV

	SC6->( DBSeek( _aPedSC9[_nI,2]+_aPedSC9[_nI,3] ) )
	While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == _aPedSC9[_nI,2]+_aPedSC9[_nI,3]
		
		// Grava o Array _aPedidos com todos os itens de um pedidos de vendas para atualização da base de dados
		aAdd(_aPedidos, {  SC6->C6_FILIAL  ,;//01
		                   SC6->C6_NUM     ,;//02
		                   SC6->C6_ITEM    ,;//03
		                   SC6->C6_PRODUTO ,;//04
		                   SC6->C6_LOCAL   ,;//05
	                       SC6->C6_QTDVEN  ,;//06
	                       "N"             ,;//07
		                   SC6->C6_UNSVEN   ;//08
		                   })
		
		_cProdutos+=SC6->C6_PRODUTO+";"
		
		// Grava o Array _aResulAux com todos os itens de um pedidos de vendas para grava na arrary _aResultado
		aAdd(_aResulAux,{ .F.             ,;//01
		                  SC6->C6_FILIAL  ,;//02
		                  SC6->C6_NUM     ,;//03
		                  SC6->C6_ITEM    ,;//04
		                  SC6->C6_PRODUTO ,;//05
		                  SC6->C6_LOCAL   ,;//06 DE
		                  SC6->C6_LOCAL   ,;//07 PARA
		                  SC6->C6_QTDVEN  ,;//08 DE
	                  	  SC6->C6_QTDVEN  ,;//09 PARA
		                  ""               ;//10 ERROS
		                  })
		
		SC6->( DBSkip() )
		
	EndDo

	lTemItemSemSaldo:=.F.//TESTA SE TA TUDO COM SALDO OK, DENTRO DA Ver_Est_PV()

	lTemItemPraAlterar:=Ver_Est_PV(_aPedSC9[_nI,2],_cProdutos,_aResulAux,.T.,_aPedSC9[_nI,2]+"-"+_aPedSC9[_nI,3])

	_cRet:="NAO_ALTEROU"
	If lTemItemPraAlterar	
	   _cRet:=MOMS047QGR(_aPedSC9[_nI,2],_aPedSC9[_nI,3],.F.,oProc)//ALTERA/CORTA E LIBERA O PEDIDO
    Else
	    aAdd(_aPedRejeicao, {.F.,"[ Não houve alterações no Pedido ]"})    
    EndIf
	
	If !lTemItemSemSaldo .And. _cRet = "NAO_ALTEROU"// SE TA TUDO COM SALDO OK , SÓ LIBERA O PEDIDO 

        _aPedRejeicao:={}
        _cMenTrava:=""
        If !MOMS47Travou(,@_cMenTrava,.F.,oProc)
            aAdd(_aPedRejeicao, {.F.,_cMenTrava})
            
        ElseIf !Ver_Lib_PV(_aPedSC9[_nI,2]+_aPedSC9[_nI,3])//LIBERA O PEDIDO SEM ALTERACOES E COM SALDO EM TUDO TB 
  		    aAdd(_aPedRejeicao, {.F.,"[ Liberacao do PV com problemas, Verifique o PV ]"})
  		    
  	    Else
  		    aAdd(_aPedRejeicao, {.T.,"[ Liberacao do PV realizada com SUCESSO ]"})
  	    EndIf

		For nPos := 1 TO Len(_aResulAux)
			_aResulAux[nPos,01]:=_aPedRejeicao[1,1]
			_aResulAux[nPos,10]:=_aPedRejeicao[1,2]
			aAdd(_aResultado,ACLONE(_aResulAux[nPos]))
		Next nPos

	Else

		For nPos := 1 TO Len(_aResulAux)
			_aResulAux[nPos,01]:=_aPedRejeicao[1,1]
			If _aPedRejeicao[1,1]//OK
				_aResulAux[nPos,10]:=(_aPedRejeicao[1,2]+": "+_aResulAux[nPos,10])
			Else//Rejeitado
				_aResulAux[nPos,10]:=_aPedRejeicao[1,2]
			EndIf
			aAdd(_aResultado,ACLONE(_aResulAux[nPos]))
		Next nPos

	EndIf

	If _cRet = "FINALIZAR"
	   Exit
    EndIf
	
Next _nI

// Pedidos de Vendas que tiveram a alteração de armazem rejeitada.
If !Empty(_aResultado)
	_cTitAux:="Resultado das alteracoes dos Pedidos de Vendas de Varejo"
	_aCab:={" ","Filial","Pedido","Item","Produto","Do Arm.","Para Arm","Da Qtde","Para Qtde","Resultado"}
	_aSize:={05,10      ,15      ,10    ,150      ,35       ,35        ,35       ,35         ,200        }
	nPosResu:=Len(_aResultado[1])
	aBotoes:={}
	aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
	//ITListBox(_cTitAux, _aHeader , _aCols     , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX(_cTitAux, _aCab    , _aResultado, .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes)
	
EndIf

End Sequence

TRBF->(DBGoTo(_nRegAtu))
SC5->(DBGoTo(_nRegSC5))

Return
/*
===============================================================================================================================
Programa----------: MOMS047QGR()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: ALTERA E LIBERA O PEDIDO
Parametros--------: _cNrFilial : Filial do pedido de vendas
                    _cNrPedido : Numero do pedido dew vendas.
                    lSoLiberaPV: .T.: So libera o PV, .F. : Só altera PV
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047QGR(_cNrFilial,_cNrPedido,lSoLiberaPV,oProc,_lOpLog)

Local _aCabPV
Local _aItemPV
Local _aItensPV
Local _nI  , _nni
DEFAULT lSoLiberaPV := .F.
DEFAULT _lOpLog := .F.
Begin Sequence

_aCabPV  :={}
_aItemPV :={}
_aItensPV:={}

// O Array _Pedidos possui apenas um pedido de vendas por filial.
// Posiciona Pedidos de Vendas para as alterações do armazem.
SC5->(DBSetOrder(1))
SC5->(DBSeek( _cNrFilial + _cNrPedido ))

// Monta o cabeçalho do pedido
aAdd( _aCabPV, { "C5_FILIAL"  	,SC5->C5_FILIAL  , Nil}) // filial
aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil}) // Numero do Pedido de Vendas
aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil}) // Tipo de pedido
aAdd( _aCabPV, { "C5_I_OPER" 	,SC5->C5_I_OPER  , Nil}) // Tipo da operacao
aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL}) // Codigo do cliente
aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil}) // Cliente de Entregra
aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL}) // Loja Cliente de Entrega
aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL}) // Loja do cliente
aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL}) // Data de emissao
aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil}) // Transpordadora
aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL}) // Codigo da condicao de pagamanto*
aAdd( _aCabPV, { "C5_I_TAB"  	,SC5->C5_I_TAB  , Nil}) // Tabela de preços
aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil}) // Vendedor
aAdd( _aCabPV, { "C5_VEND2"  	,SC5->C5_VEND2	 , Nil}) // Vendedor
aAdd( _aCabPV, { "C5_VEND3"  	,SC5->C5_VEND3	 , Nil}) // Vendedor
aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil}) // Moeda
aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil}) // Mensagem padrão para a nota
aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL}) // Liberacao Total
aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil}) // Tipo de Liberacao
aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL}) // Tipo do Cliente
aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL}) // Numero que originou a pedido de palete
aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL}) // Pedido Refere a um pedido de Pallet
aAdd( _aCabPV, { "C5_I_DTENT"	,SC5->C5_I_DTENT , Nil}) // Dt de Entrega foi alterado para data do dia
aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil}) // Troca Nota
aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil}) // Bloqueio de Preços
aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil}) // Filial de Faturamento
aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})
aAdd( _aCabPV, { "C5_FILGCT"    ,SC5->C5_FILGCT , Nil})

// Monta o item do pedido
SC6->( DBSetOrder(12) )//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
_nTotal:=0
_cTemLeiteIntegral:=""

While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
	
	_nI := aScan(_aPedidos, {|x| x[1] == SC6->C6_FILIAL .AND.;
	                             x[2] == SC5->C5_NUM    .AND.;
	                             x[3] == SC6->C6_ITEM   .AND.;
	                             x[4] == SC6->C6_PRODUTO})
	If lSoLiberaPV .Or.  _nI > 0	
		
		_aItemPV:={}
		
		aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM"                           , SC6->C6_ITEM }) //  Informa a posição do item
  	    If !lSoLiberaPV
		   aAdd( _aItemPV,{ "AUTDELETA"  ,_aPedidos[_nI,7]                   , Nil }) // Informa se o item será ou não excluído.
		EndIf   
		aAdd( _aItemPV , { "C6_FILIAL"  , SC6->C6_FILIAL                     , Nil }) // Filial
		aAdd( _aItemPV , { "C6_NUM"     , SC6->C6_NUM	                     , Nil }) // Numero do Pedido de Vendas
		aAdd( _aItemPV , { "C6_PRODUTO" , SC6->C6_PRODUTO                    , Nil }) // Codigo do Produto
  	    If lSoLiberaPV
		   aAdd(_aItemPV,{ "C6_QTDVEN"  , SC6->C6_QTDVEN                     , Nil }) // 1oUM Quantidade 
		   aAdd(_aItemPV,{ "C6_UNSVEN"  , SC6->C6_UNSVEN                     , Nil }) // 2oUM Quantidade 
        Else
		   aAdd(_aItemPV,{ "C6_QTDVEN"  , _aPedidos[_nI,6]                   , Nil,,SC6->C6_QTDVEN }) // 1oUM Quantidade 
		   aAdd(_aItemPV,{ "C6_UNSVEN"  , _aPedidos[_nI,8]                   , Nil,,SC6->C6_UNSVEN }) // 2oUM Quantidade 
		EndIf   
		aAdd( _aItemPV , { "C6_PRCVEN"  , SC6->C6_PRCVEN                     , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_PRUNIT"  , SC6->C6_PRUNIT                     , Nil }) // Preco Unitario Liquido
		aAdd( _aItemPV , { "C6_ENTREG"  , SC6->C6_ENTREG                     , Nil }) // Data da Entrega
		aAdd( _aItemPV , { "C6_LOJA"    , SC6->C6_LOJA	                     , Nil }) // Loja do Cliente
		aAdd( _aItemPV , { "C6_SUGENTR" , SC6->C6_SUGENTR                    , Nil }) // Data da Entrega
  	    If lSoLiberaPV
		   aAdd( _aItemPV , { "C6_VALOR"   , SC6->C6_VALOR                   , Nil }) // valor total do item
        Else
		   aAdd( _aItemPV , { "C6_VALOR"   , Round((SC6->C6_PRCVEN*_aPedidos[_nI,6]),2), Nil,,SC6->C6_VALOR  }) // valor total do item
		   If _aPedidos[_nI,7] = "N"
		      _nTotal+=SC6->C6_PRCVEN*_aPedidos[_nI,6]
		   EndIf   
		EndIf   
		aAdd( _aItemPV , { "C6_UM"      , SC6->C6_UM                         , Nil }) // Unidade de Medida Primar.
  	    If lSoLiberaPV
		   aAdd(_aItemPV,{ "C6_LOCAL"   , SC6->C6_LOCAL                      , Nil }) // Armazem / lmoxarifado  // SC6->C6_LOCAL
        Else
		   aAdd(_aItemPV,{ "C6_LOCAL"   , _aPedidos[_nI,5]                   , Nil,,SC6->C6_LOCAL }) // Armazem / lmoxarifado  // SC6->C6_LOCAL
		EndIf   
		aAdd( _aItemPV , { "C6_DESCRI"  , SC6->C6_DESCRI                     , Nil }) // Descricao
		aAdd( _aItemPV , { "C6_QTDLIB"  , SC6->C6_QTDLIB                     , Nil }) // Quantidade Liberada
		aAdd( _aItemPV , { "C6_PEDCLI"  , SC6->C6_PEDCLI                     , Nil }) // Pedido do Cliente
		aAdd( _aItemPV , { "C6_I_BLPRC" , SC6->C6_I_BLPRC                    , Nil }) // Bloqueio de Preço
		
		aAdd( _aItensPV ,_aItemPV )
  	    If !lSoLiberaPV
		   If Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_I_TIPLT") = "I" .And. (_aPedidos[_nI,6] <> SC6->C6_QTDVEN .Or. _aPedidos[_nI,7] ="S")
		      _cTemLeiteIntegral+="("+SC6->C6_PRODUTO+") "
		   EndIf
		EndIf

	EndIf
	
	SC6->( DBSkip() )
EndDo

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM

If !lSoLiberaPV .And. MV_PAR91 <> "5"// não é "5-IMPORTA DO OP LOGISTICO" - CSV
   
   If SC5->C5_CONDPAG = "001"
	  aAdd(_aPedRejeicao, {.F.,"[ Pedido com pagamento anteciado não pode sofrer corte. ]"})
	  Return "ERRO_COND_001"
   EndIf

   If !Empty(_cTemLeiteIntegral)
	  aAdd(_aPedRejeicao, {.F.,"[ Pedido com alteracao no Leite Integral não pode ser alterado: "+_cTemLeiteIntegral+"]"})
	  Return "ERRO_LEITE_INTEGRAL"
   EndIf
   
	_aPars:=Condicao(_nTotal,SC5->C5_CONDPAG,0,SC5->C5_EMISSAO)
	For _nni := 1 to Len(_aPars)
		If _aPars[_nni][2] < _nMinimo
			
			aAdd(_aPedRejeicao, {.F.,"[ Valor de Parcela ( "+cValToChar(_aPars[_nni][2])+" ), do PV, menor que ( "+cValToChar(_nMinimo)+") ]"})
			Return "ERRO_VALOR"
			
		EndIf
	Next _nni
EndIf

lMsErroAuto   := .F.
lAutoErrNoFile:= .F.
_cAOMS074Vld  := ""
_cAOMS074     := "MOMS047" //Não mostra mensagens do mata410

If !MOMS47Travou(_aPedidos,@_cAOMS074Vld,lSoLiberaPV,oProc)

   aAdd(_aPedRejeicao, {.F.,_cAOMS074Vld})
   Return "FINALIZAR"

EndIf

If oproc <> NIL
	oproc:cCaption := ("Alterando Pedido: "+_cNrPedido )
	ProcessMessages()
EndIf

Begin Transaction

MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )

If lMsErroAuto
	
	cErro:=MostraErro()
	aAdd(_aPedRejeicao, {.F.,"[ Alteração Rejeitada: ( "+_cAOMS074Vld + " ) (" + cErro + ") ]"})

ElseIf lSoLiberaPV

    aAdd(_aPedRejeicao, {.T.,"[ Alteração Realizada com SUCESSO p/ liberar estoque ]"})
	
Else

    _cMotivs:="01"//FALTA DE ESTOQUE

  	If !Ver_Lib_PV(SC5->C5_FILIAL+SC5->C5_NUM)//LIBERA O PEDIDO SE ALTERADO COM SUCESSO
		aAdd(_aPedRejeicao, {!_lOpLog,"[ Alteração realizada com SUCESSO, mas Liberação do PV com problemas, Verifique ]"})
  	Else
  		aAdd(_aPedRejeicao, {.T.,"[ Alteração e Liberação realizada com SUCESSO ]"})
  	EndIf
	
EndIf

End Transaction

End Sequence

Return "SAIR"

/*
===============================================================================================================================
Programa--------: Ver_Est_PV()
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Verefica os estoques dos produtos do pedido para ver se tem que costar 
Parametros------: cFil,_cProdutos,_aResulAux,_lCalcSaldo,_cPV
Retorno---------: (.T.) ou (.F.)
===============================================================================================================================
*/
Static Function Ver_Est_PV(cFil,_cProdutos,_aResulAux,_lCalcSaldo,_cPV)

Local _cQuery:=""
Local _cAlias:= GetNextAlias()
Local nPos:=0 , _nQtde:=0
Local _lTemAlteracao:=.F.
Local _lVaiExcluirTodos:=.T.
Local _cCrtl3Um := "N" // Produtos a validar quantidade fracionada na terceira unidade de medida.

_cProdutos:=LEFT(_cProdutos,Len(_cProdutos)-1)

_cQuery += " SELECT DISTINCT B2_COD,"
_cQuery += "        NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB270"
_cQuery += "            WHERE     SB270.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB270.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB270.B2_LOCAL = '70' "
_cQuery += "                  AND SB270.D_E_L_E_T_ = ' '),0)  SALDO70,"
_cQuery += "       NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB272"
_cQuery += "            WHERE     SB272.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB272.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB272.B2_LOCAL = '72' "
_cQuery += "                  AND SB272.D_E_L_E_T_ = ' '),0)  SALDO72, "
_cQuery += "        NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB220"
_cQuery += "            WHERE     SB220.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB220.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB220.B2_LOCAL = '20' "
_cQuery += "                  AND SB220.D_E_L_E_T_ = ' '),0)  SALDO20,"
_cQuery += "       NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB222"
_cQuery += "            WHERE     SB222.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB222.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB222.B2_LOCAL = '22' "
_cQuery += "                  AND SB222.D_E_L_E_T_ = ' '),0)  SALDO22 "
_cQuery += "  FROM " + RetSqlName("SB2")+ " SB2 "
_cQuery += " WHERE     B2_FILIAL = '"+cFil+"' "
_cQuery += "       AND B2_COD IN "+FormatIn(_cProdutos,";")
_cQuery += "       AND B2_LOCAL IN ('70', '72','20', '22') "
_cQuery += "       AND SB2.D_E_L_E_T_ = ' ' "
_cQuery += "       ORDER BY B2_COD "
_cQuery := ChangeQuery(_cQuery)

MPSysOpenQuery(_cQuery,_cAlias)

_cLOG+="QUERY: "+_cQuery+CRLF

While (_cAlias)->(!Eof())
	
	_cLOG+=_cPV+";'"+(_cAlias)->B2_COD+";"+Str((_cAlias)->SALDO70,20,5)+";"+Str((_cAlias)->SALDO72,20,5)+";"+Str((_cAlias)->SALDO20,20,5)+";"+Str((_cAlias)->SALDO72,22,5)+";"
	
	If (nPos:=aScan(_aResulAux, {|P| P[5] == (_cAlias)->B2_COD } )) <> 0
		nSaldo70:=(_cAlias)->SALDO70
		nSaldo72:=(_cAlias)->SALDO72
		nSaldo20:=(_cAlias)->SALDO20
		nSaldo22:=(_cAlias)->SALDO22
		
		_aSaldos:={}
		aAdd(_aSaldos,{nSaldo70,"70"})
		aAdd(_aSaldos,{nSaldo72,"72"})
		aAdd(_aSaldos,{nSaldo20,"20"})
		aAdd(_aSaldos,{nSaldo22,"22"})
		aSort(_aSaldos,,,{ |x,y| x[1] < y[1] })//O maior fica por ultimo
		
		If _lCalcSaldo
		   cArm   := _aPedidos[nPos,05]
		   _nQtde := _aPedidos[nPos,06]
           _n2Qtde:= _aPedidos[nPos,08]
		Else
			cArm  := _aResulAux[nPos,06]
			_nQtde:= _aResulAux[nPos,07]
		EndIf
		_cLOG+= Str(_nQtde,20,5)
		
		_lAjusta:= .F.
		If nSaldo70 >= _nQtde
			cArm:="70"
		ElseIf nSaldo72 >= _nQtde
			cArm:="72"
		ElseIf nSaldo20 >= _nQtde
			cArm:="20"
		ElseIf nSaldo22 >= _nQtde
			cArm:="22"
		Else
			_lAjusta:=.T.
			cArm  :=_aSaldos[4,2]
			_nQtde:=_aSaldos[4,1]//Se os 4 armazens tiverem zerado joga zero aqui
		EndIf
		
		If _lCalcSaldo//EFETIVANDO
			
			If _lAjusta .And. _nQtde <> 0   //ACERTA A 1UM conforme a 2UM interia
				
				SB1->(DBSeek(xFilial("SB1")+AllTrim((_cAlias)->B2_COD)))
				
				_cCrtl3Um := Posicione("SBZ",1,xFilial("SBZ")+(_cAlias)->B2_COD,"BZ_I_PR3UM")

				If _cCrtl3Um == "S" // (AllTrim((_cAlias)->B2_COD) $ _cPrd3Um) //Calcula a 1um 
					
					_n3Qtde:=(_nQtde / SB1->B1_I_QT3UM)//CALCULA A 3UM
					
					If _n3Qtde <> Int(_n3Qtde) .And. Int(_n3Qtde) <> 0
						
						_n3Qtde:=Int(_n3Qtde)//PEGA SÓ O INTEIRO DA 3UM
						
						_nQtde:=(_n3Qtde*SB1->B1_I_QT3UM)// **RECACULA** A 1UM COM A 3UM INTEIRA
						
					EndIf
					
				EndIf   
					
 	            nFator := SB1->B1_CONV
            	nFator := (If(nFator == 0, SB1->B1_I_FATCO , nFator))

				If  nFator > 0
						
					If SB1->B1_TIPCONV = 'D'
						_n2Qtde:=(_nQtde/nFator)//CALCULA A 2UM
					Else
						_n2Qtde:=(_nQtde*nFator)//CALCULA A 2UM
					EndIf
                    
                    _cCrtl3Um := Posicione("SBZ",1,xFilial("SBZ")+(_cAlias)->B2_COD,"BZ_I_PR3UM")

				    If _cCrtl3Um <> "S" .And. _n2Qtde <> Int(_n2Qtde) // !(AllTrim((_cAlias)->B2_COD) $ _cPrd3Um)
						
						_n2Qtde:=Int(_n2Qtde)//PEGA SÓ O INTEIRO DA 2UM
						
						If SB1->B1_TIPCONV = 'D'
							_nQtde:=(_n2Qtde*nFator)//**RECACULA** A 1UM COM A 2UM INTEIRA
						Else
							_nQtde:=(_n2Qtde/nFator)//**RECACULA** A 1UM COM A 2UM INTEIRA
						EndIf
						
					EndIf

				EndIf
				
			EndIf
			
			If _nQtde > 0
				
				_aResulAux[nPos,7]:=cArm
				_aResulAux[nPos,9]:=_nQtde
				If _aPedidos[nPos,05] <> cArm
					_aResulAux[nPos,01]:=.T.//SÓ SINALIZO DE TIVER ALTERACAO
					_aResulAux[nPos,10]:=" [Armazem alterado]"
				EndIf
				If _nQtde < _aPedidos[nPos,06]
  					_aResulAux[nPos,01]:=.T.//SÓ SINALIZO DE TIVER CORTE
  					_aResulAux[nPos,10]+=" [Quantidade foi cortada]"
				EndIf
				_aPedidos[nPos,05]:=cArm
  				_aPedidos[nPos,06]:=_nQtde
				_aPedidos[nPos,07]:="N"
  				_aPedidos[nPos,08]:=_n2Qtde
                _lVaiExcluirTodos:=.F.
				
			Else//SE NÃO CONSEGUU SALDO EM NENHUM ARMAZEM DELETA
				
 				_aResulAux[nPos,01]:=.T. //SÓ SINALIZO DE TIVER que excluir
  				_aPedidos [nPos,07]:="S" //MARCA PARA DELETA
  				_aResulAux[nPos,10]:=" [Sem Saldo sufiente nos armazens 70, 72, 20 e 22 Item foi excluido]"
  				lTemItemSemSaldo:=.T.
				
			EndIf
			
		Else////ANALISANDO
			
			_nQtde:=_aResulAux[nPos,7]
			If _aSaldos[4,1] > 0
				If _aResulAux[nPos,06] <> cArm
					_aResulAux[nPos,01]:=.T. //SÓ SINALIZO DE TIVER ALTERACAO
					_aResulAux[nPos,Len(_aResulAux[nPos])]+="[ Armazem poderá ser alterado para "+cArm+" ]"
				EndIf
				If _aSaldos[4,1] < _nQtde
					_aResulAux[nPos,01]:=.T. //SÓ SINALIZO DE TIVER CORTE
					_aResulAux[nPos,Len(_aResulAux[nPos])]+="[ Quantidade sofrerá cortes ou item pode ser excluido ]"
				EndIf
		        If !_aResulAux[nPos,1]//Se tem saldo no armazem atual do item
				   _aResulAux[nPos,Len(_aResulAux[nPos])]+="[ Item OK ]"
				EndIf   

			Else //Se NÃO tem saldo de produto do PV
				_aResulAux[nPos,Len(_aResulAux[nPos])]+="[ Sem Saldo nos armazemns 70, 72, 20 e 22 ]"
			EndIf
			_cLOG+=Str(_nQtde,20,5)
			
			_aResulAux[nPos,06]:=" "+_aResulAux[nPos,06]
			_aResulAux[nPos,07]:=_nQtde
			_aResulAux[nPos,08]:=nSaldo70
			_aResulAux[nPos,09]:=nSaldo72
			_aResulAux[nPos,10]:=nSaldo20
			_aResulAux[nPos,11]:=nSaldo22
			
		EndIf//_lCalcSaldo
		
	EndIf
	
	_cLOG+=CRLF
	
	(_cAlias)->(DBSkip())
	
EndDo

(_cAlias)->(DBCloseArea())
_lTemAlteracao:=.F.
//AJUSTA O RESULTADO _aResulAux
For nPos := 1 TO Len(_aResulAux)
	SB1->(DBSeek(xFilial("SB1")+_aResulAux[nPos,5]))
	_aResulAux[nPos,5]:=AllTrim(_aResulAux[nPos,5])+"-"+SB1->B1_DESC
	If _lCalcSaldo//VAI EFETIVA
		If _aResulAux[nPos,1]//Se tem saldo de algum produto do PV ou armazem para alterar
			_lTemAlteracao:=.T.//para alterar
		EndIf
	Else//ANALISOU
		aAdd(_aResultado,_aResulAux[nPos])
	EndIf
Next nPos

If _lCalcSaldo .And. _lVaiExcluirTodos
   _lTemAlteracao:=.F.
EndIf

Return _lTemAlteracao

/*
===============================================================================================================================
Programa--------: Ver_Lib_PV(cChave)
Autor-----------: Alex Wallauer
Data da Criacao-: 30/01/2020
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: cChave: Filia + Pedido,
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function Ver_Lib_PV(cChave)

Local _lOK:=.T.//Não Tem erro
Local _nQtdLib:=0

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
If !SC6->( DBSeek( cChave ) )
	_lOK:=.F.//Tem erro
EndIf

SC9->(DBSetOrder(1) )//
SC6->(DBSetOrder(1))
While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == cChave
	
	If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		_nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA ITEM DO PEDIDO
	EndIf
	
	If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		If SC9->C9_QTDLIB <> SC6->C6_QTDVEN
			_lOK:=.F.//Tem erro
			Exit
		ElseIf !Empty(SC9->C9_BLEST)
			_lOK:=.F.//Tem erro
			Exit
		EndIf	    
		If !(Empty(SC9->C9_BLCRED))
           SC9->(RecLock("SC9",.F.))
  		   SC9->C9_BLCRED := " "	   
	   	   SC9->(MSUnLock("SC9"))
	   		
	       //Faz análise e liberação de estoque pois o padrão não analisa estoque se o crédito está bloqueado
	       //Posiciona SC6 pois a função A440VerSb2 depende do SC6 posicionado para analisar o estoque
	       If SC6->(DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO+SC9->C9_ITEM)) .And. A440VerSB2(SC9->C9_QTDLIB)
	       	  If !(Empty(SC9->C9_BLEST))
	       	     SC9->(RecLock("SC9",.F.))
		         SC9->C9_BLEST := ""
	   	         If !(MaAvalSC9("SC9",5,{{ "","","","",SC9->C9_QTDLIB,SC9->C9_QTDLIB2,Ctod(""),"","","",SC9->C9_LOCAL}}))
	   	            SC9->C9_BLEST := "02"
			        _lOK:=.F.//Tem erro
			        Exit
	   	         EndIf	
	             SC9->(MSUnLock("SC9"))
	          EndIf
	   	   EndIf	
   	    EndIf	
	Else
	   _lOK:=.F.//Tem erro
	   Exit
	EndIf
	SC6->( DBSkip() )
	
EndDo

Return _lOK

/*
===============================================================================================================================
Programa----------: MOMS047Ger
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: Gera Arquivos Varejo
Parametros--------: oproc = Objeto de processamento para imcrementação da régua de processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS047Ger(oproc)

Local _cFileCLI:="CLI"+DToS(DATE())+"01"
Local _cFilePED:="PED"+DToS(DATE())+"01"
Local  cDIRini :=AllTrim(GetTempPath())
Local _nConta  := nContPV := 0
Local nPos     := 0
Local _cTexto1 :=""
Local _cTexto2 :=""
Local lRet      := .T.

Static _cDir := 'C:\'

_cDir := tFileDialog( "\", "Selecione o Diretorio de Destino:" ,, _cDir, .T., GETF_MULTISELECT)

If !Empty(_cDir)	

	While FILE(_cDir + _cFileCLI + ".TXT")
		_cFileCLI:=Soma1(_cFileCLI)//renumera se já existir no destino
	EndDo

	While FILE(_cDir + _cFilePED + ".TXT")
		_cFilePED:=Soma1(_cFilePED)//renumera se já existir no destino
	EndDo

	If !(cDIRini == Upper(AllTrim(_cDir)))//deleta a origem se não For o mesmo diretorio
	FErase(cDIRini + _cFileCLI + ".TXT")
	FErase(cDIRini + _cFilePED + ".TXT")
	EndIf

	_nHd1 := FCreate(cDIRini + _cFileCLI + ".TXT")
	If _nHd1 = -1
		U_ITMsg("O arquivo de nome "+cDIRini + _cFileCLI + ".TXT"+" nao pode ser criado!",'Atenção!',"Entre em contato com a TI",3)//ALERT
		Return .F.
	EndIf

	_nHd2 := FCreate(cDIRini + _cFilePED + ".TXT")
	If _nHd2 = -1
		FClose(_nHd1)
		U_ITMsg("O arquivo de nome "+cDIRini + _cFilePED + ".TXT"+" nao pode ser criado!",'Atenção!',"Entre em contato com a TI",3)//ALERT
		Return .F.
	EndIf

	Begin Sequence

	SA1->(DBSetOrder(1)) //
	SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
	SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM
	SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

	TRBF->(DBSetOrder(2))//ORDEM DE PV
	TRBF->(DBGoTop())
	_cTot:= AllTrim(Str( TRBF->(LASTREC()) ))
	_aClientes:={}
	_aResultado:={}

	While TRBF->(!Eof())
		// Somente pedidos selecionados pelo usuario
		If oproc <> NIL
			_nConta++
			oproc:cCaption := ("Gerando Arquivos, PV: " + TRBF->TRBF_NUM + " [ "+ StrZero(_nConta,Len(_cTot)) +" de "+ _cTot+" ]" )
			ProcessMessages()
		EndIf
		
		If !Empty(TRBF->TRBF_OK)
			//Posiciona tabelas
			If !(SC5->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM)))    //Se não achar na sc5 pula para próximo marcado
				TRBF->(DBSkip())
				Loop
			EndIf

			_lAchouSA1:=SA1->(DBSeek( xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			
			_lTodoLiberado:=.F.
			_lPVtemCarga:=.F.
			If SC9->(DBSeek(TRBF->TRBF_FILIA+TRBF->TRBF_NUM))
				_lTodoLiberado:=.T.
				While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == TRBF->TRBF_FILIA+TRBF->TRBF_NUM
					If !Empty(SC9->C9_CARGA)
						_lPVtemCarga:=.T.
						Exit
					EndIf
					If !Empty(SC9->C9_BLEST)
						_lTodoLiberado:=.F.
						Exit
					EndIf
					SC9->(DBSkip())
				EndDo
			EndIf
			
			If !_lTodoLiberado .Or. _lPVtemCarga
				If _lPVtemCarga
				_cMen:="Pedido esta na Carga: "+SC9->C9_CARGA+"."
				Else
				_cMen:="Pedido NÃO liberado ou com Bloqueio de Estoque. Não é permitido gerar."
				EndIf
				aAdd(_aResultado,{ .F.,;            //01
								TRBF->TRBF_FILIA,;//02
								TRBF->TRBF_NUM  ,;//03
								DToC(TRBF->TRBF_DTEMI),;//04
								SC5->C5_CLIENTE+SC5->C5_LOJACLI+" - "+AllTrim(SA1->A1_NREDUZ),;//05
								""              ,;//06
								""              ,;//07
								""              ,;//08
								""              ,;//09
								""              ,;//10
								_cMen;//11
								})
				
				TRBF->(DBSkip())
				Loop
			EndIf
			
			If _lAchouSA1 .And. aScan(_aClientes,SC5->C5_CLIENTE+SC5->C5_LOJACLI) = 0
				aAdd(_aClientes,SC5->C5_CLIENTE+SC5->C5_LOJACLI)
				
				_cQueryRDC:="SELECT CODCLI,LATITU,LONGIT FROM RDCITL.TGA221 WHERE CODCLI = '"+AllTrim(SA1->A1_CGC)+"' "
				_cQueryRDC := ChangeQuery(_cQueryRDC)
				MPSysOpenQuery(_cQueryRDC,"QRYRDC")

				_cTexto1:=""
				_cTexto1+=AllTrim(SA1->A1_COD)+AllTrim(SA1->A1_LOJA)+";"
				_cTexto1+=AllTrim(SA1->A1_CGC   )+";"
				_cTexto1+=AllTrim(SA1->A1_CEP   )+";"
				_cTexto1+=AllTrim(SA1->A1_NOME  )+";"
				_cTexto1+=AllTrim(SA1->A1_NREDUZ)+";"
				_cTexto1+=AllTrim(SA1->A1_END   )+";"
				_cTexto1+=AllTrim(SA1->A1_BAIRRO)+";"
				_cTexto1+=AllTrim(SA1->A1_MUN   )+";"
				_cTexto1+=AllTrim(SA1->A1_EST   )+";"
				_cTexto1+=AllTrim(StrTran(QRYRDC->LATITU,",","."))+";"
				_cTexto1+=AllTrim(StrTran(QRYRDC->LONGIT,",","."))+";"
				
				FWrite( _nHd1 , _cTexto1 + CHR(13) + CHR(10) )
				
				QRYRDC->(DBCloseArea())
				DBSelectArea("TRBF")
				
			EndIf
			
			_aResulAux:={}
			If SC6->( DBSeek( TRBF->TRBF_FILIA+TRBF->TRBF_NUM ) )
			nContPV++
			EndIf   
			While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == TRBF->TRBF_FILIA+TRBF->TRBF_NUM
				
				_cTipoCarga := Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPCAR")
				
				_cTexto2:=""
				_cTexto2+=AllTrim(SC5->C5_CLIENTE)+AllTrim(SC5->C5_LOJACLI)+";"
				_cTexto2+=AllTrim(SC5->C5_NUM)+";"
				_cTexto2+=AllTrim(SubStr(DToS(SC5->C5_I_DTENT),7,2)+SubStr(DToS(SC5->C5_I_DTENT),5,2)+SubStr(DToS(SC5->C5_I_DTENT),1,4))+";"
				_cTexto2+=AllTrim(Str(SC6->C6_UNSVEN ,15,2))+";"
				_cTexto2+=AllTrim(Str(SC6->C6_I_PTBRU,16,4))+";"
				_cTexto2+=AllTrim(Str(SC6->C6_VALOR  ,15,2))+";"
				_cTexto2+=If(_cTipoCarga='000002','R','S')+";"
				_cTexto2+=AllTrim(SC6->C6_PRODUTO)+";"
				_cTexto2+=AllTrim(SC6->C6_DESCRI)+";"
				_cTexto2+=If(_cTipoCarga='000002','1','2')+";"
				_cTexto2+=If(_cTipoCarga='000002','R','S')+";"
				_cTexto2+=AllTrim(StrTran(StrTran(StrTran(SC5->C5_MENNOTA,CRLF,' '),CHR(13),' '),CHR(10),' '))
				
				FWrite( _nHd2 , _cTexto2 + CRLF )
				
				// Grava o Array _aResulAux com todos os itens de um pedidos de vendas para grava na arrary _aResultado dentro da função Ver_Est_PV()
				aAdd(_aResulAux,{ .T.,;             //01
								SC6->C6_FILIAL  ,;//02
								SC6->C6_NUM     ,;//03
								DToC(TRBF->TRBF_DTEMI),;//04
								SC5->C5_CLIENTE+SC5->C5_LOJACLI+" - "+AllTrim(SA1->A1_NREDUZ),;//05
								SC6->C6_ITEM    ,;//06
								AllTrim(SC6->C6_PRODUTO)+" - "+AllTrim(SC6->C6_DESCRI) ,;//07
								SC6->C6_LOCAL   ,;//08
								SC6->C6_QTDVEN,;//09
								SC6->C6_VALOR ,;//10
								"Gerado com Sucesso";//11
								})
				
				SC6->( DBSkip() )
				
			EndDo
			
			For nPos := 1 TO Len(_aResulAux)
				aAdd(_aResultado,ACLONE(_aResulAux[nPos]))
			Next nPos
			
		EndIf
		
		TRBF->(DBSkip())
		
	EndDo

	End Sequence

	FClose(_nHd1)
	FClose(_nHd2)

	If !(cDIRini == Upper(AllTrim(_cDir)))
		
		_lOKCli:=__CopyFile( cDIRini + _cFileCLI + ".TXT", _cDir +  _cFileCLI + ".TXT" )
		
		_lOKPED:=__CopyFile( cDIRini + _cFilePED + ".TXT", _cDir +  _cFilePED + ".TXT" )
		
		
		If _lOKCli .And. _lOKPED
			
			FErase(cDIRini + _cFileCLI + ".TXT")
			FErase(cDIRini + _cFilePED + ".TXT")
			U_ITMsg("TXTs salvo com SUCESSO em: "+CHR(13)+CHR(10)+ Upper(_cDir+_cFileCLI) + ".TXT e "+CHR(13)+CHR(10)+Upper(_cDir+_cFilePED) + ".TXT","Atenção",,2)
			
		Else
			
			If !_lOKCli
				U_ITMsg("Operação de salvar o TXT: "+ _cDir + _cFileCLI + ".TXT FALHOU!","Atenção","Verifique o nome do arquivo e do diretorio e tente novamente.",1)
			EndIf
			
			If !_lOKPED
				U_ITMsg("Operação de salvar o TXT: "+ _cDir + _cFilePED + ".TXT FALHOU!","Atenção","Verifique o nome do arquivo e do diretorio e tente novamente.",1)
			EndIf

		EndIf
		
	Else
		
		U_ITMsg("TXTs salvo com SUCESSO em " +CRLF+ Upper(cDIRini+_cFileCLI) + ".TXT e  "+CRLF+Upper(cDIRini+_cFilePED)+".TXT","Atenção","Diretorio de destino ["+Upper(_cDir)+"] igual ao de Origem",2)
		
	EndIf


	If !Empty(_aResultado)
		
		_cMsgTop:=AllTrim(Str(Len(_aClientes)))+" Clientes Gerados / "+AllTrim(Str(nContPV))+" Pedidos Gerados "
		_cTitAux:="Resultado dos Pedidos de Vendas de Varejo Gerados: "+_cMsgTop
		_aCab:={" ","Filial","Pedido","Emissao","Cliente","Item","Produto","Arm.","Qtde","Valor","Resultado"}
		_aSize:={05,10      ,15      ,15        ,125     ,10    ,150      ,20     ,35   ,35     ,200        }
		//ITListBox(_cTitAux, _aHeader , _aCols     , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
		U_ITLISTBOX(_cTitAux, _aCab    , _aResultado, .T.      , 4      , _cMsgTop ,          , _aSize  ,         ,     ,        , )
		
	EndIf

	TRBF->(DBSetOrder(1))
	TRBF->(DBGoTop())
Else
	lRet := .F.
Endif

Return lRet

/*
===============================================================================================================================
Programa----------: MOMS47GETTXT
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
Descrição---------: Processamento de Importação de DADOS DO ROTELIZADOR
Parametros--------: cOrigem,oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS47GETTXT(cOrigem,oproc)

Local _aParAux := {},nI 
Local _aParRet := {}
Local _bOK     := {|| .T. }
Local cExt:=If(cOrigem="ROT","TXT","CSV/XLS/XML")


MV_PAR92:="C:\"+Space(300)
aAdd( _aParAux , { 1 , "Selecione arq. ."+cExt,MV_PAR92, "@!"	, "", "DIR","", 120, .T. } )
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI
//        aParametros ,cTitle               ,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
If !ParamBox( _aParAux,"Selecione o Arquivo",@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T. )
    Return .F.
EndIf

_cArq:=MV_PAR92:=AllTrim(MV_PAR01)

If Empty(MV_PAR92)
   Return .F.
EndIf

If oproc <> NIL
	oproc:cCaption := ("Verificando Ambiente do Usuario...")
	ProcessMessages()
EndIf

_lConverteu:=.F.
If cOrigem = "OPLOG" .And. (".XLS" $ Upper(MV_PAR92) .Or. ".XML" $ Upper(MV_PAR92))

	_cNFileExcel:="\xlstemp"+SUBS(MV_PAR92,RAT(".",MV_PAR92))
    _cNFileTemp :="\csvtemp"+SUBS(MV_PAR92,RAT(".",MV_PAR92))

	_copyfile(MV_PAR92,_cDirTRB+_cNFileExcel)

	//detecta se é excel ou libreoffice e cria script de conversão
	ferase(_cDirTRB+"\converzz.vbs")
	ferase(_cDirTRB+"\csvtemp.csv")
	ferase(_cDirTRB+"\testa.bat")
	ferase(_cDirTRB+"\resp.txt")
	
	_nHandle := FCreate(_cDirTRB+"\testa.bat")
	FWrite(_nHandle, 'reg query "HKEY_CLASSES_ROOT\Excel.Application\CurVer" > '+_cDirTRB+'\resp.txt' + CHR(13))
	FClose(_nHandle)	
	shellexecute("Open",_cDirTRB+"\testa.bat","","",0)
	//tempo de espera para garantir que arquivo foi finalizado
	Sleep(1500)
	FT_FUSE(_cDirTRB+"\resp.txt")	
	FT_FSKIP()		
	_cHKEY := FT_FREADLN()

	If oproc <> NIL
		oproc:cCaption := ("Convertendo Arq. para csvtemp.csv ...")
		ProcessMessages()
	EndIf

	If "HKEY_CLASSES_ROOT\Excel.Application\CurVer"  $ _cHKEY //Tem Excel
        _cSaveAs:= "6" // CSV: 6-CSV - SEPAROU POR VIRGULA COM ALGUNS ESPACOS
        _cFormat:= '"@"' // Formatacao dos numeros
		
		_nHandle:= FCreate(_cDirTRB+"\converzz.vbs")
		FWrite(_nHandle, "Dim oExcel" + CHR(13))
		FWrite(_nHandle, 'Set oExcel = CreateObject("Excel.Application")'+ CHR(13))
		FWrite(_nHandle, "Dim oBook"+ CHR(13))
		FWrite(_nHandle, "Set oBook = oExcel.Workbooks.Open(Wscript.Arguments.Item(0))"+ CHR(13))
        If ".CSV" $ Upper(MV_PAR92) 
		   FWrite(_nHandle, 'oBook.Sheets(1).Range("A1:A1000").NumberFormat = "################"'+ CHR(13)+CHR(10))
		Else
		   FWrite(_nHandle, 'oBook.Sheets(1).Range("D2:D1000").NumberFormat = '+_cFormat+ CHR(13)+CHR(10))
		   FWrite(_nHandle, 'oBook.Sheets(1).Range("E2:E1000").NumberFormat = '+_cFormat+ CHR(13)+CHR(10))
        EndIf
		FWrite(_nHandle, "oBook.SaveAs WScript.Arguments.Item(1), "+_cSaveAs+ CHR(13))//CSV: 6-CSV - SEPAROU POR VIRGULA COM ALGUNS ESPACOS
		FWrite(_nHandle, "oBook.Close False"+ CHR(13))
		FWrite(_nHandle, "oExcel.Quit"+ CHR(13))
		FClose(_nHandle)

		ShellExecute("open", _cDirTRB+"\converzz.vbs", _cDirTRB+_cNFileExcel+" "+_cDirTRB+"\csvtemp.csv", "", 0)

	Else
		U_ITMsg("Falha ao converter o arquivo excel para .csv","Erro","Instale o Excel. pois não foi encontrado.",1)
		ferase(_cDirTRB+"\testa.bat")
        ferase(_cDirTRB+"\resp.txt")
		Return .F.
	EndIf

    MV_PAR92:=_cDirTRB+"\csvtemp.csv"
	_nConta:=0
	While .T.
	   If FILE(MV_PAR92) .Or. _nConta > 100
	      Exit
	   EndIf
	   _nConta++
	   Sleep(1000)
	EndDo
	_lConverteu:=.T.

EndIf

If cOrigem="ROT"//"2-IMPORTA DO ROTEIRIZADOR" - TXT
   FWMsgRun( , {|oproc| MOMS47LETXT(oproc) }, "Aguarde..." , 'Lendo Arq: '+MV_PAR92 )
Else//"5-IMPORTA DO OP LOGISTICO" - CSV - XLS - XML
   FWMsgRun( , {|oproc| MOMS47LECSV(oproc) }, "Aguarde..." , 'Lendo Arq: '+MV_PAR92 )
EndIf

If cOrigem = "OPLOG" .And. "CSVTEMP.CSV" $ Upper(MV_PAR92)
   Ferase(_cDirTRB+"\converzz.vbs")
   Ferase(_cDirTRB+"\testa.bat")
   Ferase(_cDirTRB+"\resp.txt")
   Ferase(_cDirTRB+_cNFileExcel)
   Ferase(_cDirTRB+_cNFileTemp)
   Ferase(_cDirTRB+"\csvtemp.csv")
EndIf
		
Return .T.

/*
===============================================================================================================================
Programa----------: MOMS47LETXT
Autor-------------: Alex Wallauer
Data da Criacao---: 18/02/2020
Descrição---------: Processamento de Importação de DADOS DO TYT
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS47LETXT(oProc)

Local _nCpo
oProc:cCaption := ("Lendo dados do Arquivo...")
ProcessMessages()

_cArq := AllTrim(MV_PAR92)
If Upper(RIGHT(_cArq,3)) <> "TXT" .Or. FT_FUSE(_cArq) == -1
	U_ITMsg("Não foi possível abrir o arquivo informado.",;
	"Arquivo inválido","O arquivo informado deve ser .TXT ou verificar se o arquivo informado esta correto.",1)
	Return .F.
EndIf

_cTot:=FT_FLASTREC()
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
_nCont:=_nConta:=0
	

_aDados:={}
_nErro:=0
_aRotErro:={}
_aLinRepetido={}
_aPVRepetido={}
SB1->(DBSetOrder(1))
DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
 	
	_nCont++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
	ProcessMessages()
	
	_cDados := FT_FREADLN()
	_cDados := StrTran(_cDados,'"','')
	_cDados := StrTran(_cDados,',','.')//Troca a sepracao das decimais pra ponto por causa do Val

	//Verifica se é final de arquivo
	If Empty(_cDados) .Or. AllTrim(_cDados) = ';;;;'
	   _nConta++
	   If _nConta > 10
	      Exit
	   Else
	      Exit
	   EndIf   
	EndIf

    If aScan(_aLinRepetido,_cDados) = 0
        aAdd(_aLinRepetido,_cDados)    
    Else
       FT_FSKIP()
       Loop
    EndIf
  	
	_aLinhas:= StrTokArr2(_cDados,";",.T.)
	_aItens:={}
	
  	If Len(_aLinhas) < 18
  		_aLinhas:=U_ITTXTARRAY(_cDados,"",18,18)
  	EndIf
  
	aAdd(_aItens,.T.                                   )//01
	aAdd(_aItens,If(Len(_aLinhas) > 00,_aLinhas[01],""))//02
	aAdd(_aItens,If(Len(_aLinhas) > 01,_aLinhas[02],""))//03
	aAdd(_aItens,If(Len(_aLinhas) > 02,_aLinhas[03],""))//04
	aAdd(_aItens,If(Len(_aLinhas) > 03,_aLinhas[04],""))//05
	aAdd(_aItens,If(Len(_aLinhas) > 04,_aLinhas[05],""))//06
	aAdd(_aItens,If(Len(_aLinhas) > 05,_aLinhas[06],""))//07
	aAdd(_aItens,If(Len(_aLinhas) > 06,_aLinhas[07],""))//08
	aAdd(_aItens,If(Len(_aLinhas) > 07,_aLinhas[08],""))//09
	aAdd(_aItens,If(Len(_aLinhas) > 08,_aLinhas[09],""))//10
	aAdd(_aItens,If(Len(_aLinhas) > 09,_aLinhas[10],""))//11
	aAdd(_aItens,If(Len(_aLinhas) > 10,_aLinhas[11],""))//12
	aAdd(_aItens,If(Len(_aLinhas) > 11,_aLinhas[12],""))//13
	aAdd(_aItens,If(Len(_aLinhas) > 12,_aLinhas[13],""))//14
	aAdd(_aItens,If(Len(_aLinhas) > 13,_aLinhas[14],""))//15
	aAdd(_aItens,If(Len(_aLinhas) > 14,_aLinhas[15],""))//16
	aAdd(_aItens,If(Len(_aLinhas) > 15,_aLinhas[16],""))//17
	aAdd(_aItens,If(Len(_aLinhas) > 16,_aLinhas[17],""))//18
	aAdd(_aItens,If(Len(_aLinhas) > 17,_aLinhas[18],""))//19
	aAdd(_aItens,"" )//20 - Erro

   cFilPed:=cFilant//"90"  
   If Empty(_aItens[5]) 
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ PEDIDO não informada ]"
   Else
      _aItens[5]:=AllTrim( _aItens[5] )

      If aScan(_aPVRepetido,_aItens[5]) = 0
         aAdd(_aPVRepetido,_aItens[5])
      Else   
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]+="[ PEDIDO Repetido ("+AllTrim(_aItens[5])+") em outra Carga ]"
      EndIf

      If !SC5->(DBSeek(cFilPed+_aItens[5]))
        
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]+="[ PEDIDO não encontrado nessa Filial ] "
      
      Else

        DAK->(DBSetOrder(1))
		_lTemSC9:=.F.
		_lTodoLiberado:=.F.
		_lPVtemCarga  :=.F.
		If SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			_lTemSC9:=.T.
			_lTodoLiberado:=.T. //SE TIVER TODO LIBERADO NÃO PODE ALTERAR PQ NÃO PRECISA
			While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL+SC5->C5_NUM
				If !Empty(SC9->C9_CARGA)
                    DAK->(DBSeek(SC9->C9_FILIAL+SC9->C9_CARGA))
					_lPVtemCarga:=.T.
					Exit
				EndIf
				If !Empty(SC9->C9_BLEST) //TÁ COM BLOQUEI DE ESTOQUE PODE ALTERAR
					_lTodoLiberado:=.F.
					Exit
				EndIf
				SC9->(DBSkip())
			EndDo
		EndIf
		
		If !_lPVtemCarga
           DAI->(DBSetOrder(4))
           If DAI->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM)) 
              DAK->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_COD))
              _lPVtemCarga:=.T.
	       EndIf
	    EndIf

		If !_lTemSC9
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ PEDIDO não esta Liberado ]"
		ElseIf _lPVtemCarga
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ PEDIDO já esta na CARGA: "+SC9->C9_CARGA+" / "+AllTrim(If(!Empty(DAK->("DAK_I_ROTE")),DAK->DAK_I_ROTE,DAK->DAK_I_OBS))+" ]"
		ElseIf !_lTodoLiberado
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ PEDIDO com bloqueio de estoque no item: "+SC9->C9_PRODUTO+" ]"
		EndIf
	  EndIf
   EndIf
   
   If Empty(_aItens[4])  .And. _aItens[1]
      _aItens[4]:=SC5->C5_CLIENTE+SC5->C5_LOJACLI
   EndIf

   If Empty(_aItens[4]) 
      _aItens[1]:=.F.
     _aItens[Len(_aItens)]:="[ CODIGO Cliente não informada ]"
   Else
	  cCod:=AllTrim( _aItens[4] )
	  SA1->(DBSetOrder(1))
      If SA1->(DBSeek(xFilial("SA1")+AllTrim(cCod)))
         If SA1->A1_MSBLQL = '1'
            _aItens[1]:=.F.
            _aItens[Len(_aItens)]:="[ Cliente Bloqueado no Protheus ]"
         EndIf   
         _aItens[4]:=SA1->A1_COD+"-"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NREDUZ)//NÃO MEXER NA ORDEM USO PARA DAR SEEK PARA FRENTE
	  Else   
         _aItens[4]:="["+cCod+"]"
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]:="[ CODIGO Cliente não Encontrado no Protheus ]"
      EndIf   
   EndIf
     
   If !Empty(_aItens[6]) 
      _aItens[6]:=StrZero(Val(_aItens[6]),3)
   EndIf

// VALIDACAO DO VEICULO
   _cRet:=""
   If !Empty(_aItens[13])
       _cRet:=BuscaVei(_aItens[13])
   EndIf    
   If Empty( _aItens[13] ) .Or. Empty(_cRet) 
	  _aItens[1]:=.F.
	  _aItens[Len(_aItens)]+="[ Codigo do Veiculo não encontrado ]"
   Else
	  _aItens[13]:=_cRet
   EndIf
// VALIDACAO DO VEICULO

   If _aItens[1] = .F.
      aAdd(_aRotErro,_aItens[9])
      _nErro++
   EndIf
   aAdd(_aDados,_aItens)

   FT_FSKIP()

EndDo

FT_FUSE()

If Len(_aDados) > 0
  
   For _nCpo := 1 TO Len(_aDados)
       If _aDados[_nCpo,1] .And. aScan(_aRotErro,_aDados[_nCpo,9]) <> 0//Se achou
          _aDados[_nCpo,1]:=.F.//Se um der errado não vai integra o pedido todo
          _aDados[_nCpo,Len(_aDados[1])]:="[Carga com 1 ou mais Pedidos com erro] "
       EndIf
       _aDados[_nCpo,2]:=If(_aDados[_nCpo,1],"OK-","XX-")+_aDados[_nCpo,9]+"-"+_aDados[_nCpo,2]
   Next _nCpo
	//Monta _aCab
	_aCab:={}
	_aSize:={}
	aAdd(_aCab,"")//01
	aAdd(_aSize,05)
	aAdd(_aCab,"Nome Rota")//02
	aAdd(_aSize,100)
	aAdd(_aCab,"No Rota")//03
	aAdd(_aSize,30)
	aAdd(_aCab,"Cliente")//04
	aAdd(_aSize,150)
	aAdd(_aCab,"Pedido")//05
	aAdd(_aSize,35)
	aAdd(_aCab,"Seq Ent")//06 
	aAdd(_aSize,05)
	aAdd(_aCab,"Placa")//07
	aAdd(_aSize,40)
	aAdd(_aCab,"Motorista")//08
	aAdd(_aSize,040)
	aAdd(_aCab,"Codigo Rota")//09
	aAdd(_aSize,40)
	aAdd(_aCab,"Peso Pedido")//10
	aAdd(_aSize,40)
	aAdd(_aCab,"Cod Depósito")//11 
	aAdd(_aSize,40)
	aAdd(_aCab,"Custo Frete Total")//12 
	aAdd(_aSize,40)
	aAdd(_aCab,"Codigo do Veículo")//13  ******
	aAdd(_aSize,100)
	aAdd(_aCab,"Cod Transportadora")//14
	aAdd(_aSize,40)
	aAdd(_aCab,"Valor Frete")//15 
	aAdd(_aSize,40)
	aAdd(_aCab,"Valor PV")//16 
	aAdd(_aSize,40)
	aAdd(_aCab,"Nome Cli")//17 
	aAdd(_aSize,40)
	aAdd(_aCab,"Nome Transp")//18 
	aAdd(_aSize,40)
	aAdd(_aCab,"Nome do Motorista")//19 ***
	aAdd(_aSize,100)
	aAdd(_aCab,"Resultado")//20
	aAdd(_aSize,300)
	
	_cTitAux:="Dados do Arquivo "+_cArq
	_cMsgTop:="Importação Roterizador, Registros Lidos: "+AllTrim(TRANSFORM(Val(_cTot),"@E 999,999,999"))+", Com Erros: "+AllTrim(TRANSFORM(_nErro,"@E 999,999,999"))
    aSort( _aDados ,,, {|X, Y| X[2]+X[6] < Y[2]+Y[6] } )
	While .T.


        nPosResu:=Len(_aDados[1])//Posiçao dos "Erros"
        _aButtons:={}
        aAdd(_aButtons,{"BUDGET",{|| AVISO("PROBLEMA",oLbxAux:aArray[oLbxAux:nAt][nPosResu],{"Fechar"},3)  },"", "Visualizar Erro" }) 
   		//     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
		lOK:=U_ITLISTBOX(_cTitAux, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop  ,          , _aSize  ,         ,     ,        , _aButtons)
		
		If lOK .And. U_ITMsg("Confirma geracao das CARGAS ?",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")
           _aCarga:={}
           _aDadosAux:={}
           For _nCpo := 1 TO Len(_aDados)//GRAVA A CARGA ROTERIZADOR
               If _aDados[_nCpo,1] //pedidos OK               
                  If (nPos:=aScan(_aCarga,{|C| C[1] == _aDados[_nCpo,9] } ) ) = 0
                     aAdd(_aCarga, { _aDados[_nCpo,9] , { _aDados[_nCpo] } } )
                  Else
                     aAdd(_aCarga[nPos,2],_aDados[_nCpo])
                  EndIf
   			      aAdd(_aDadosAux,_aDados[_nCpo])
               EndIf
           Next _nCpo
           
		   If Len(_aDadosAux) = 0
	          U_ITMsg("Nenhum Pedido válido",'Atenção!',"Deve ter pelo menos um Pedido OK para gerar uma carga",1)
		      Loop
		   EndIf

           _cTot:=Len(_aCarga)
           _cTot:=AllTrim(Str(_cTot))
           For _nCpo := 1 TO Len(_aCarga)
   			   MOMS47Carga(oProc,_aCarga[_nCpo,1],_aCarga[_nCpo,2],_cTot,.F.)//GRAVA A CARGA ROTERIZADOR
   		   Next _nCpo
           
           _aDados:=ACLONE(_aDadosAux)
           nPosResu:=Len(_aDados[1])//Posiçao dos "Erros"
           _aButtons:={}
           aAdd(_aButtons,{"BUDGET",{|| AVISO("PROBLEMA",oLbxAux:aArray[oLbxAux:nAt][nPosResu],{"Fechar"},3)  },"", "Visualizar Erro" }) 
   		   //     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
		   lOK:=U_ITLISTBOX(_cTitAux, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop  ,          , _aSize  ,         ,     ,        , _aButtons)

		   Exit

		ElseIf !lOK .And. U_ITMsg("Confirma SAIR ?",'Atenção!',"Todos os registros de válidações serão perdidos",3,2,3,,"CONFIRMA","Voltar")
			Exit
		EndIf
		
	EndDo
Else
	U_ITMsg("Nenhum registro válido",'Atenção!',"Dados do Arquivo "+_cArq,1)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: BuscaVei
Autor-------------: Alex Wallauer
Data da Criacao---: 18/02/2020
Descrição---------: Realiza a busca dos dados para a tela de Transporte via F3
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function BuscaVei(_cVeiculo)

Local _cRet:=""
DA3->( DBSetOrder(1) )
If DA3->( DBSeek( xFilial("DA3") + _cVeiculo ) )
	_cRet:=_cVeiculo+" - "+AllTrim( DA3->DA3_DESC ) + " ("+AllTrim( DA3->DA3_PLACA)+")"
	If !Empty( DA3->DA3_MOTORI )
		DA4->( DBSetOrder(1) )
		If DA4->( DBSeek( xFilial("DA4") + DA3->DA3_MOTORI ) )
		   _cRet+=" / "+AllTrim( DA4->DA4_NOME ) + " ("+AllTrim( DA4->DA4_COD  )+") "  
		   SA2->( DBSetOrder(1) )
		   If SA2->( DBSeek( xFilial() + DA4->DA4_FORNEC + DA4->DA4_LOJA) )
		   	  cCNPJTra:=AllTrim(SA2->A2_CGC)
		   EndIf   
		EndIf
	EndIf
	
EndIf                             

Return _cRet

/*
===============================================================================================================================
Programa----------: MOMS47Carga
Autor-------------: Alex Wallauer
Data da Criacao---: 19/02/2020
Descrição---------: CRIA PRE CARGA
Parametros--------: oProc,_cCarga,_aPVs,_cTot,_lOpLog
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS47Carga(oProc,_cCarga,_aPVs,_cTot,_lOpLog)

Local _lRet := .T.    
Local _nTamPedido 
Local _cMsg, _nI, P
Local _aQtdClientes 
Local _cMsgOk
Local _cCodUsuario:=__cUserId
Local _cChavePesq, _aJaProces, _cPedidos
Local _nCont:=0
Local _nTam:=Len(_cTot)
_nCont++
If oProc <> NIL
   oProc:cCaption := ("GERANDO CARGA: "+AllTrim(_cCarga)+" - "+StrZero(_nCont,_nTam) +" de "+ _cTot)
    ProcessMessages()
EndIf
Private _cMailUsrCarga
Private _lEnviaEmail := .F. 
_lPedOk     := .F.
_aCargasAtu := {}
_lDeuErro   := .F.


Begin Sequence
   // Registra o tempo inicial de criação da carga.
   _cMsg    := ""
   _cMsgOk  := ""   
   _cCodigo := ""   
   _cFilial := xFilial("SC5")
   _nTamPedido := TamSX3("C5_NUM")[1]  

   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                                                                
   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO                                                                                                                             
   DAK->(DBSetOrder(1))
   DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
   SC9->(DBSetOrder(1)) // C9_FILIAL + C9_PEDIDO
   
   // Valida se pedidos podem ser lockados, util para definir se já não está rodando o processo 
   	SC5->(DBSetOrder(1))

   // Verifica pedido bonificação bloqueado e PV vinculados
   aP1Vinculados:={}
   aP2Vinculados:={}
   _cPedAux:=""
    
   For _nI := 1 to Len(_aPVs)   
       
	   If _lOpLog
		  _aPVs[_nI,Len(_aPVs[_nI])]:=" " //_cMsg limpa as mensagens de aviso
          _cPC:=PadR(_aPVs[_nI,3],_nTamPedido," ")

          If _cPC $ _cPedAux
			 Loop
		  Else
             _cPedAux+=_cPC+";"//Controle para LER o Pedido uma vez só 
		  EndIf

	   Else       
          _cPC:=PadR(_aPVs[_nI,5],_nTamPedido," ")
	   EndIf
	   
	   cMsg:=""
    
    	If !SC5->(DBSeek(_cFilial+_cPC))
    	
    		_cMsg += " O pedido  " + _cPC + " não encontrado nessa filail: "+_cFilial
    	
    	ElseIf !SC5->(MsRLock(SC5->(RECNO())))
    	
    		_cMsg += " No momento este Pedido de Vendas está sendo utilizado por outro usuário e não pode ser manipulado. Vefifique se já não há cargas para ele e tente integrar novamente mais tarde: " + _cPC 
    	
    	ElseIf !Empty(SC5->C5_NOTA) 
 
            _cMsg += " Pedido não disponível para geração da carga! Pedido de vendas: "+ AllTrim(_cPC) +" já faturado: "+SC5->C5_NOTA
 
    	ElseIf Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_MSBLQL") == '1'
 
    		_cMsg += "Cliente do pedido bloqueado no cadastro "+AllTrim(SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI)+"." + " Pedido de vendas: "+ AllTrim(_cPC) 
 
    	EndIf 
    	
        // Verifica se este pedido já existe lançado para alguma Carga.
       DAI->(DBSetOrder(4))
       If DAI->(DBSeek(_cFilial+_cPC)) 
           DAK->(DBSetOrder(1))
           If DAK->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_COD))
              _cMsg += " Já existe o PV: " + AllTrim(_cPC) + " para CARGA: " + AllTrim(DAI->DAI_COD) + " / "+AllTrim(If(!Empty(DAK->("DAK_I_ROTE")),DAK->DAK_I_ROTE,DAK->DAK_I_OBS))
           EndIf
       EndIf
        
       If SC5->(DBSeek(_cFilial+_cPC))

      	  If SC5->C5_I_OPER = '10' .And. (SC5->C5_I_BLOQ == "B" .Or. SC5->C5_I_BLOQ == "R")
             _cMsg+= "Pedido de bonificação sem liberação - " + SC5->C5_NUM + " "
          EndIf

          aAdd(aP1Vinculados,SC5->C5_NUM)
          If !Empty(SC5->C5_I_PEVIN)
             aAdd(aP2Vinculados,{ SC5->C5_NUM , SC5->C5_I_PEVIN , _nI })
          EndIf

       EndIf

       _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg

   Next _nI

   cFaltaPVinculado:=""
   For P := 1 TO Len(aP2Vinculados)
       If aScan(aP1Vinculados, aP2Vinculados[P,2]) = 0 
          cFaltaPVinculado+=" PV "+aP2Vinculados[P,1]+" na carga sem o PV Vinculado "+aP2Vinculados[P,2]
          _aPVs[ aP2Vinculados[P,3] , Len(_aPVs[ aP2Vinculados[P,3] ]) ] += _cMsg
       EndIf
   Next P

   If !Empty(_cMsg)
      _cMsg:=""//limpa pq a mensagem é de um PV somente
      Break
   EndIf
   
   // Realiza a liberação dos pedidos de vendas se passar no teste de crédito e estoque
   If .T.
      _cChavePesq := ""
      _aJaProces  := {}
      _cPedidos   := ""      
      SC5->(DBSetOrder(1))
      SC9->(DBSetOrder(1))
      SA1->(DBSetOrder(1))
      SC5->(DBSetOrder(1))
      SB2->(DBSetOrder(1))
   	  SC6->(DBSetOrder(12))//C - C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
      _nPesoTot :=0
      _nPesoCSeca :=0
      _nPesoCRefrigerada :=0
      _nTotCarga:= 0
	  If _lOpLog  // OPERADOR  LOGISTICO
		 _aPedidos := {}		 
		 lTemItemPraAlterar:=.F.
	  EndIf
      _lDeuErro:=.F.
      For _nI := 1 To Len(_aPVs)
	         
          Begin Transaction
          Begin Sequence//para dar o Loop no For fechando o Begin Transaction

			 If _lOpLog  // OPERADOR  LOGISTICO
                
  			    _cPC     := _aPVs[_nI,3]
                _cVeiculo:= ""
				_cFilial := cFilant//"90"  ou "40"
				lTemItemPraAlterar:=.F.

                SC5->(DBSeek(_cFilial+_cPC)) 
                SC6->(DBSetOrder(12))//C - C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
				While _cPC = _aPVs[_nI,3]
                
				   _cCodSB1 := LEFT(_aPVs[_nI,4],Len(SC6->C6_PRODUTO))
				   If oProc <> NIL
                      oProc:cCaption := ("LENDO PEDIDO / PRODUTO: "+AllTrim(_cPC)+" / "+_cCodSB1)
                      ProcessMessages()
                   EndIf

                   If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM+_cCodSB1))
	               
		               // Grava o Array _aPedidos com todos os itens de um pedidos de vendas para atualização da base de dados
		               aAdd(_aPedidos, {  SC6->C6_FILIAL   ,;//01
		                                  SC6->C6_NUM      ,;//02
		                                  SC6->C6_ITEM     ,;//03
		                                  SC6->C6_PRODUTO  ,;//04
		                                  SC6->C6_LOCAL    ,;//05
	                                      Val(_aPVs[_nI,5]),;//06 - SC6->C6_QTDVEN 
	                                      "N"              ,;//07
		                                  Val(_aPVs[_nI,6]); //08 - SC6->C6_UNSVEN
		                                  })
						If SC6->C6_QTDVEN  <> Val(_aPVs[_nI,5])
						   lTemItemPraAlterar:=.T.
						EndIf		               
				   EndIf				   
			       
				   _nI++
				   If _nI > Len(_aPVs)
				      Exit
				   EndIf
				
				EndDo

                If SC6->(DBSeek(cFilPed+_cPC))
                   While SC6->C6_FILIAL + SC6->C6_NUM == cFilPed+_cPC
		              If aScan(_aPVs , {|P| P[3] == SC6->C6_NUM .And. SC6->C6_PRODUTO == LEFT(P[4],Len(SC6->C6_PRODUTO)) } ) = 0
		                 // Grava o Array _aPedidos com todos os itens de um pedidos de vendas para atualização da base de dados
		                 aAdd(_aPedidos, {  SC6->C6_FILIAL   ,;//01
		                                    SC6->C6_NUM      ,;//02
		                                    SC6->C6_ITEM     ,;//03
		                                    SC6->C6_PRODUTO  ,;//04
		                                    SC6->C6_LOCAL    ,;//05
	                                        SC6->C6_QTDVEN   ,;//06
	                                        "S"              ,;//07
		                                    SC6->C6_UNSVEN    ;//08
		                                    })
				    	  lTemItemPraAlterar:=.T.
		             EndIf
                     SC6->( DBSkip())
                   EndDo
                EndIf

				_nI--
            	_aPedRejeicao:={}
	            
				If lTemItemPraAlterar	
	            
				    _cRet:=MOMS047QGR(SC5->C5_FILIAL,SC5->C5_NUM,.F.,oProc,.F.)//ALTERA E LIBERA O PEDIDO
				    If !_aPedRejeicao[1,1]//se rejeito
				       _cmsg+=_aPedRejeicao[1,2]
				    EndIf
				    _aPedidos:= {}
                   
				Else//  SÓ LIBERA O PEDIDO 
                   
				    _cMenTrava:=""
                    If !MOMS47Travou(,@_cMenTrava,.F.,oProc)
                        _cmsg+=_cMenTrava                            
                    ElseIf !Ver_Lib_PV(SC5->C5_FILIAL+SC5->C5_NUM)//LIBERA O PEDIDO SEM ALTERACOES 
  	               	    _cmsg+="[ Liberacao do PV com problemas, Verifique o PV: "+SC5->C5_NUM+" ]"  	                	    
  	                EndIf
               
	            EndIf
				    
				If !Empty(_cMsg)   
                    _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
		            MSUnLockAll() 
					_lDeuErro:=.T.
		            BREAK
                EndIf
			 
			 Else// ROTERIZADOR 
                _cPC      := PadR(_aPVs[_nI,5],_nTamPedido," ")
                _cVeiculo := LEFT(_aPVs[_nI,13],Len(DA3->DA3_COD))//CODIGO DO VEICULO DA CARGA
             EndIf

   	         // Monta valor total do pedido
             SC6->(DBSetOrder(1))
             If SC6->(DBSeek(_cFilial+_cPC))
                While SC6->C6_FILIAL + SC6->C6_NUM == _cFilial+_cPC
                   _nTotCarga += SC6->C6_VALOR
                   SC6->( DBSkip())
                EndDo
             EndIf
              
             SC5->(DBSetOrder(1))       
             If SC5->(DBSeek(_cFilial+_cPC)) .And. SC6->(DBSeek(_cFilial+_cPC))
                _nPesoTot   += SC5->C5_I_PESBR
                _cChavePesq := ""
                _aJaProces  := {}  
                _cmsg       := ""
                If MOMS47Travou({},@_cmsg,.T.,oProc,{"SC5"})//SC5->(MsRLock(SC5->(RECNO())))
                   RecLock("SC5",.F.) 

                   SC6->(DBSetOrder(1))
                   SC6->(DBSeek(_cFilial+_cPC))
                   While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == _cFilial+_cPC

                      _cChavePesq := SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM  // Para evitar que o mesmo item de pedido seja processado mais de uma vez 

                      If aScan(_aJaProces,_cChavePesq) == 0
                         aAdd(_aJaProces,_cChavePesq)
                      Else
                         SC6->(DBSkip())
                         Loop
                      EndIf
                      
                      SC9->(DBSetOrder(1))
    	                  
  	                  If !(SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))) .Or. !Empty(SC9->C9_BLEST)  // verifica estoque se não tem liberação válida ainda	
  	                  	 //Verifica se pode gravar registros do C6, A1 e B2
  	                  	 _lflock := .F.
  	                  	
   	                  	 If !SC6->(MsRLock(SC6->(RECNO())))
  	                  		_cmsg += "No momento este Pedido de Vendas está sendo utilizado por outro usuário e não pode ser manipulado. Tente integrar novamente mais tarde: " + SC6->C6_NUM + "/" + SC6->C6_ITEM
  	                  		_lflock := .T.
  	                  	 EndIf
  	                  	
  	                  	 SA1->(DBSetOrder(1))
  	                  	 SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
  	                  	 
  	                  	 SB2->(DBSetOrder(1)) 	                  	
  	                  	 SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
  	                  	
  	                  	 If ! _lflock .And. !SB2->(MsRLock(SB2->(RECNO())))
  	                  		_cmsg += "No momento este estoque está sendo utilizado por outro usuário e não pode ser manipulado. Tente integrar novamente mais tarde: " + SB2->B2_COD + "/" + SB2->B2_LOCAL
  	                  		_lflock := .T.
  	                  	 EndIf
  	           	         
   	           	         If _lflock .And. !Empty(_cMsg)  //Break exclusivo para falha de lock dos itens
                            _aPVs[_nI,Len(_aPVs[_nI])]+=_cMsg
  	           	         	//DISARMTRANSACTION()
							_lDeuErro:=.T.
  	           	        	Break
  	           	         EndIf
  	                     
  	                     //Analise da liberação de estoque
  	                     _lestoque := .F.
  	                     
  	                     SC9->(DBSetOrder(1))
  	                     If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)) 
  	                     	If SC9->C9_QTDLIB <> SC6->C6_QTDVEN  		        	 
  	                     	   _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". A quantidade liberada diverge da quantidade do item: " + SC6->C6_ITEM + " - Produto: " +;
  	                           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
  	                        ElseIf !Empty(SC9->C9_BLEST)   
  	                           _nQtdEst := 0
  	                           If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
  	                              _nQtdEst := (SB2->B2_QATU - SB2->B2_QEMP - SB2->B2_QEMPN - SB2->B2_RESERVA - SB2->B2_QACLASS)
  	                           EndIf
  	                                         	                           
                               _lBloqEst   := .T.
  	                           _cTextoMsg := " Erro na liberação do Estoque do PV: "+AllTrim(SC6->C6_NUM)+". Item: " + SC6->C6_ITEM + " - " +;
  	                                         AllTrim(SC6->C6_PRODUTO) + ". Qtd PV: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+" "+SC6->C6_UM+". Armazém: " + SC6->C6_LOCAL +;
  	                                         ". Qtd Estoque: " + AllTrim(Str(_nQtdEst,18,5)) + " " + SC6->C6_UM

  	                           If !(_cTextoMsg $ _cMsg)
  	                              _cMsg += _cTextoMsg
  	                           EndIf
                            ElseIf !Empty(SC9->C9_BLCRED) 
                               _cPedidos += "C9_BLCRED: "+SC9->C9_BLCRED+", Nr.Pedido V.: " + AllTrim(SC6->C6_NUM) + " - Item: " + SC6->C6_ITEM + " - Produto: "+AllTrim(SC6->C6_PRODUTO) + " - Qtd: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". ### " 
                            ElseIf !Empty(SC9->C9_CARGA) 
  	                           _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de carga para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	                           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
                            ElseIf !Empty(SC9->C9_NFISCAL) 
  	                           _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de nota fiscal para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	                           SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"."                               		        	     
                            Else
  	                           _lestoque := .T.
	                        EndIf
  	                     Else
                   	     	_cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Não foi gerado registro de liberação " + SC6->C6_ITEM + " - Produto: " +;
  	                        SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". " 
  	                     EndIf
 
   	                     If _lestoque
 		                    MSUnLockAll()
 		                 EndIf
 		              
 		              ElseIf SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)) 
 

 		        	     If SC9->C9_QTDLIB <> SC6->C6_QTDVEN
 		        	        _cMsg += "Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". A quantidade liberada diverge da quantidade do item: " + SC6->C6_ITEM + " - Produto: " +;
  	                                 SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". " 
 		        	     ElseIf !Empty(SC9->C9_BLEST) 

  	                        _cTextoMsg := "Erro na liberação do Estoque do PV: "+AllTrim(SC6->C6_NUM)+". Item: " + SC6->C6_ITEM + " - " +;
  	                                      AllTrim(SC6->C6_PRODUTO) + ". Qtd PV: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+" "+SC6->C6_UM+". Armazém: " + SC6->C6_LOCAL +;
  	                                      ". Qtd Estoque: " + AllTrim(Str(_nQtdEst,18,5)) + " " + SC6->C6_UM                                                                                    
                            _lBloqEst   := .T.
  	                        If !(_cTextoMsg $ _cMsg)
  	                           _cMsg += _cTextoMsg
  	                        EndIf   
  	                        
 		        	     ElseIf !Empty(SC9->C9_BLCRED)                                                                                                              
 		        	        _cPedidos += "C9_BLCRED: "+SC9->C9_BLCRED+",  Nr.Pedido V.: " + AllTrim(SC6->C6_NUM) + " - Item: " + SC6->C6_ITEM + " - Produto: "+AllTrim(SC6->C6_PRODUTO) + " - Qtd: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+". ### " 
 		        	     ElseIf !Empty(SC9->C9_CARGA) 
 		        	        _cMsg += "Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de carga para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	                                 SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
 		        	     ElseIf !Empty(SC9->C9_NFISCAL) 
 		        	        _cMsg += "Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Bloqueio de nota fiscal para o item: " + SC6->C6_ITEM + " - Produto: " +;
  	                                 SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"."                               		        	     
 		        	     Else
 		                    MSUnLockAll()
 		                 EndIf 
  	                  Else
  	                     _cMsg += " Erro na liberação do Pedido de Vendas: "+AllTrim(SC6->C6_NUM)+". Não foi gerado registro de liberação " + SC6->C6_ITEM + " - Produto: " +;
  	                              SC6->C6_PRODUTO + " Quantidade: "+ AllTrim(Str(SC6->C6_QTDVEN,18,5))+"." 
  	                  EndIf  

                      _nPesoSB1:= Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_PESBRU")
	                  If SB1->B1_TIPCAR == "000002" // Carga Refrigerada  
	                     _nPesoCRefrigerada  +=(_nPesoSB1 * SC6->C6_QTDVEN)
	                  Else// Carga Seca
	                     _nPesoCSeca +=(_nPesoSB1 * SC6->C6_QTDVEN)
	                  EndIf														

                      SC6->(DBSkip())
                   EndDo
                                                       
                   If ! Empty(_cPedidos) .And. ! _cPedidos $ _cMsg
                      _cMsg += "Erro na liberação do Pedido de Vendas. Bloqueio por Crédito: " + _cPedidos
                   EndIf
                   
                   If !Empty(_cMsg)  
				       
                      _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
                      //Disarmtransaction()	
		              MSUnLockAll()
					  _lDeuErro:=.T. 
		              Break
                   EndIf

                Else   
                   _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
 	               MSUnLockAll()
				   _lDeuErro:=.T.	         
	               Break 
		        EndIf
   
                If ! Empty(_cMsg)
                   _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
          	       MSUnLockAll()
    			   _lDeuErro:=.T.
                   Break 
                EndIf

             Else

      	        _cMsg += " Não achou mais o Pedido de Vendas: "+AllTrim(_cPC)
                _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
        	    MSUnLockAll()
    			_lDeuErro:=.T.
      	        Break 
	         EndIf
      
             MSUnLockAll()
          
		  End Sequence
		  End Transaction

       Next _nI
      
	  MSUnLockAll()
   
   EndIf 
   
   If !Empty(_cMsg) .Or. _lDeuErro
      _cMsg:=""//limpa pq a mensagem é de um PV somente
      BREAK
   EndIf    

   // Cria as cargas e grava os dados das tabelas DAK e DAI normalmente.
   Begin Transaction      

     _cCodigo := U_AOMS089(.F.,"DAK","DAK_COD",.F.)
     If oProc <> NIL
        oProc:cCaption := ("GERANDO CARGA: "+_cCodigo)
        ProcessMessages()
     EndIf

     DAK->(RecLock("DAK",.T.))
     DAK->DAK_FILIAL := _cFilial // Filial do Embarcador
     DAK->DAK_COD    := _cCodigo // GetSx8Num("DAK","DAK_COD")   
     DAK->DAK_SEQCAR := "01"     // sempre 01
     DAK->DAK_ROTEIR := ""       // sempre vazio
     DAK->DAK_FEZNF  := "2"              // sempre 2
     DAK->DAK_DATA   := Date()           // Date()
     DAK->DAK_HORA   := Time()           // Time()
     DAK->DAK_JUNTOU := "MANUAL"         // sempre MANUAL
     DAK->DAK_ACECAR := "2"              // sempre 2
     DAK->DAK_ACEVAS := "2"              // sempre 2
     DAK->DAK_ACEFIN := "2"              // sempre 2
     DAK->DAK_AJUDA1 := ""               // sempre vazio
     DAK->DAK_AJUDA2 := ""               // sempre vazio
     DAK->DAK_AJUDA3 := ""               // sempre vazio
     DAK->DAK_DTACCA := CTOD("  /  /  ") // sempre vazio
     DAK->DAK_OK     := ""               // sempre vazio
     DAK->DAK_FLGUNI := "2"              // sempre 2
     DAK->DAK_DATENT := CTOD("  /  /  ") // sempre vazio
     DAK->DAK_BLWMS  := ""               // sempre vazio
     DAK->DAK_BLQCAR := ""               // sempre vazio
     DAK->DAK_HRSTAR := "08:00"          // sempre 08:00
     DAK->DAK_I_FRET := 0                // sempre 0  
     DAK->DAK_ROTEIR := '999999'     
     DAK->DAK_I_REDP := ""               // sempre vazio 
     DAK->DAK_I_RELO := ""               // sempre vazio
     DAK->DAK_I_VRPE := 0                // Sempre 0
     DAK->DAK_I_PREC := "1"
     DAK->DAK_PESO   := Round(_nPesoTot,2)
	 If _lOpLog  // **************** OPERADOR  LOGISTICO ****************
	    DAK->DAK_I_OBS  := "Carga do Operador Logistico via CSV"
	    DAK->DAK_I_OPER := _cCodOP
        DAK->DAK_I_OPLO := _cLojOP
        If DAK->DAK_FILIAL = "90"
           DAK->DAK_CAMINH := "UTI00362"
           DAK->DAK_MOTORI := "054863"
		ElseIf DAK->DAK_FILIAL = "40"
           DAK->DAK_CAMINH := "CAM22679"
           DAK->DAK_MOTORI := "065379"
		EndIf
        DAK->DAK_I_TPFR := "2" // 1="Autonomo";2="PJ-Transportadora" 
	    SA2->( DBSetOrder(1) )
		SA2->( DBSeek( xFilial() + DAK->DAK_I_OPER + DAK->DAK_I_OPLO) )
		_nVlrFrete:=0
		If DAK->(FIELDPOS("DAK_I_PSEC")) <> 0
	       _nVlrFrete+= Round((_nPesoCSeca * SA2->A2_I_VFRPS),2)
           DAK->DAK_I_PSEC:= _nPesoCSeca
		EndIf
		If DAK->(FIELDPOS("DAK_I_PREF")) <> 0
           _nVlrFrete+= Round((_nPesoCRefrigerada * SA2->A2_I_VFRPR),2)
           DAK->DAK_I_PREF:= _nPesoCRefrigerada
		EndIf
	    DAK->DAK_I_FRET := Round(_nVlrFrete,2)
	    If !Empty(SA2->A2_I_CAMIN) .And. !Empty(SA2->A2_I_MOTOR) 
           DAK->DAK_CAMINH := SA2->A2_I_CAMIN
           DAK->DAK_MOTORI := SA2->A2_I_MOTOR
		EndIf
	 Else
	    DAK->DAK_I_OBS  := "Carga do Roteirizador via TXT"
        If( DAK->(FIELDPOS("DAK_I_ROTE")) <> 0 ,DAK->DAK_I_ROTE:=DAK->DAK_I_OBS , )
        cCNPJTra:=""//gravada na função cCNPJTra
        cREt:=BuscaVei(_cveiculo)//Posiciona DA3 DA4 SA2 E GRAVA A VARIAVEL cCNPJTra
        If !Empty(cREt)//SE ACHOU
           DAK->DAK_CAMINH := DA3->DA3_COD // DA3_COD para DA3_PLACA igual placa 
           DAK->DAK_MOTORI := DA4->DA4_COD // DA4_COD para DA4_CGC   igual ao cpf do motorista
           DAK->DAK_I_TPFR := If(Len(cCNPJTra)< 14,"1","2")  // 1="Autonomo";2="PJ-Transportadora" (escolhe se cpf no transportador é 1, se é cgc no transportador é 2)            
           DAK->DAK_TRANSP := SA2->A2_COD      // SA2->A2_COD que tenha a2_cgc  igual a cnpj de transportadora 
        Else
           DAK->DAK_CAMINH := _cVeiculo // DA3_COD para DA3_PLACA igual placa 
           DAK->DAK_I_TPFR := "2"  // 1="Autonomo";2="PJ-Transportadora" 
        EndIf
	 EndIf     
     DAK->DAK_VALOR  := _nTotCarga
     DAK->DAK_USERGA := U_RetLgiLga(_cCodUsuario) // _cid - id de usuário do Protheus 
     DAK->DAK_USERGI := U_RetLgiLga(_cCodUsuario) // _cid - id de usuário do Protheus 

     // Gravação dos Itens da Carga.
     _aQtdClientes := {}
         
     DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
   	 SC5->(DBSetOrder(1))
     _cPedAux:=""
	 For _nI := 1 To Len(_aPVs)

	   If _lOpLog
		  _cPC := PadR(_aPVs[_nI,3],_nTamPedido," ")
          If _cPC $ _cPedAux
			 Loop
		  Else
             _cPedAux+=_cPC+";"//Controle para LER o Pedido uma vez só 
		  EndIf
	   Else
		  _cPC := PadR(_aPVs[_nI,5],_nTamPedido," ")
	   EndIf
		
		If !(SC5->(DBSeek(_cFilial + _cPC))) // Posiciona no numero de pedido da SC5
			
			_cMsg := "Falha ao gravar itens da carga, PV NÃO ENCONTRADO" + _cFilial + _cPC
            _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
			MSUnLockAll()
			DisarmTransaction()
			Break
			
		EndIf
		
		DAI->(RecLock("DAI",.T.))
		DAI->DAI_FILIAL := _cFilial             // Filial do Embarcador
		DAI->DAI_COD    := _cCodigo             // DAK->DAK_COD
		DAI->DAI_SEQCAR := "01"                 // sempre 01
		DAI->DAI_PEDIDO := _cPC                 // pedido indicado no xml
		DAI->DAI_CLIENT := SC5->C5_CLIENTE      // c5_cliente
		DAI->DAI_LOJA   := SC5->C5_LOJACLI      // c5_loja
		DAI->DAI_VENDED := ""                   // sempre vazio
		DAI->DAI_CAPVOL := 0          // sempre 0
		DAI->DAI_PERCUR := "999999"   // sempre 999999
		DAI->DAI_ROTA   := "999999"   // sempre 999999
		DAI->DAI_ROTEIR := "999999"   // sempre 999999
		DAI->DAI_SEQROT := ""         // sempre vazio
		DAI->DAI_NFISCA := ""         // sempre vazio
		DAI->DAI_SERIE  := ""         // sempre vazio
		DAI->DAI_DATA   := Date()     // Date()
		DAI->DAI_HORA   := Time()     // Time()
		DAI->DAI_CARORI := "CARGA"    // sempre CARGA
		DAI->DAI_REMITO := ""         // sempre vazio
		DAI->DAI_SERREM := ""         // sempre vazio
		DAI->DAI_DTCHEG := Date()     // Date()
		DAI->DAI_CHEGAD := "08:00"    // sempre 08:00
		DAI->DAI_TMSERV := "0000:00"  // sempre 0000:00
		DAI->DAI_DTSAID := Date()     // Date()
		DAI->DAI_I_FRET := 0          // sempre 0
		DAI->DAI_VALFRE := 0          // sempre 0
		DAI->DAI_FREAUT := 0          // sempre 0
		DAI->DAI_I_REDP := "2"     // A2_COD cujo a2_cgc igual a campo de redespacho
		DAI->DAI_PESO   := SC5->C5_I_PESBR // c5_pesol ou c5_pesob de acordo com parâmetro
		DAI->DAI_I_TIPC := "2"// 1 = "Paletizada" / 2 = "Batida"
		DAI->DAI_SEQUEN := StrZero(Val(_aPVs[_nI,6]),6)
		If _lOpLog
	       DAI->DAI_I_OPER:="1"
	       DAI->DAI_I_OPLO:=_cCodOP
	       DAI->DAI_I_LOPL:=_cLojOP
		Else
		   DAI->DAI_I_OPER := "2"     // A2_COD cujo a2_cgc igual a campo de operador logistico
        EndIf
		
		_cChave  := DAI->( DAI_CLIENT + DAI_LOJA )
		If !Empty(_cChave) .And. aScan(_aQtdClientes,_cChave) = 0
			aAdd(_aQtdClientes,_cChave)// Contagem de clientes diferentes nos itens da carga.
		EndIf
        DAI->(MSUnLock())
             
          SC9->(DBSetOrder(1))
          If SC9->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))       	  
       	  
          	  While DAI->DAI_FILIAL == SC9->C9_FILIAL .And. DAI->DAI_PEDIDO == SC9->C9_PEDIDO
       	  
          	  	If SC9->(RecLock("SC9",.F.))
  
          	  		SC9->C9_CARGA := DAK->DAK_COD
          	  		SC9->C9_SEQCAR := '01'
          	  		SC9->C9_SEQENT := DAI->DAI_SEQUEN
  
          	  	Else
  
          	  		_cMsg += "Falha ao reservar pedido (SC9): " + DAI->DAI_PEDIDO
    	  		    _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
        	  		MSUnLockAll()
          	  		DisarmTransaction()
          	  		Break
  
          	  	EndIf
       		  
          	  	SC9->(DBSkip())
       		  
       		  EndDo
           
           Else
       		
       		    _cMsg += "Falha ao reservar pedido (SC9 não encotrado)" + DAI->DAI_PEDIDO
   	  		    _aPVs[_nI,Len(_aPVs[_nI])] += _cMsg
       		    MSUnLockAll()
          	    DisarmTransaction()
          	    Break
           
           EndIf
 
     Next _nI
   
     DAK->DAK_PTOENT := Len(_aQtdClientes) // contagem de clientes diferentes, dai_client+cai_loja 
     DAK->(MSUnLock())
      
     ConfirmSX8()
     
   End Transaction
      // Realiza a efetivação da carga no Protheus.
      _cMailUsrCarga := Lower(AllTrim(UsrRetMail(RetCodUsr())))  //AllTrim(aUsuario[1,14])  //envia email do criador da carga para o om200fim
      _lEnviaEmail := .T. 
                 //_lEstorno,_aCargas,_lEnviaDireto,_lScheduller,_lMarcaEnvio
      U_OM200Email(.F.      ,Nil     ,.T.          ,.T.         ,.F.)
      _cMsgOk := "[ Carga Protheus: "+_cCodigo+", GERADA COM SUCESSO! ]" 
	  _cMsgTop:=_cMsgOk
   
End Sequence

If !Empty(_cMsg) .Or. _lDeuErro
   _cMsg:=""//limpa pq a mensagem é de um PV somente
EndIf    

_lRet:=.T.
lTemErro:=.F.
For _nI := 1 to Len( _aPVs)   
    If !Empty(_aPVs[_nI,Len(_aPVs[_nI])]) //_cMsg
	   _nErro++
       _aPVs[_nI,1]:=.F.
       lTemErro:=.T.
       _lRet:=.F.
    EndIf   
Next _nI

//Garante que vai liberar lock de todos os cabeçalhos e todos os itens
SC5->(DBSetOrder(1))
For _nI := 1 to Len( _aPVs)
	
     _cPC     := _aPVs[_nI,3]
	 _cFilial := cFilant//"90"  ou "40"
	If lTemErro
		If Empty(_cMsg) .And. Empty( _aPVs[_nI,Len(_aPVs[_nI])] )
		   _aPVs[_nI,Len(_aPVs[_nI])]:="[ Um ou mais pedidos com problema nessa carga ]"
		ElseIf Empty( _aPVs[_nI,Len(_aPVs[_nI])] )
		   _aPVs[_nI,Len(_aPVs[_nI])]:=_cMsg
		EndIf
	Else
	  _cMsgWK:=""
	  If _lOpLog  // OPERADOR  LOGISTICO
         If SC5->(DBSeek(_cFilial+_cPC)) 
		    _cMsgWK:=WFCredito(oProc,_cCodigo)//ENVIA WF DE CREDITO 
		 EndIf
	  EndIf
	  _aPVs[_nI,Len(_aPVs[_nI])]:=_cMsgOk+_cMsgWK
	EndIf
	
	If SC5->(DBSeek(_cFilial+_cPC))
		
		SC5->(MSUnLock())
		SC5->(MSUnLockall())
		
		SA1->(DBSetOrder(1))
		If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			
			SA1->(MSUnLock())
			SA1->(MSUnLockall())
			
		EndIf
		
		SC6->(DBSetOrder(1))
		If SC6->(DBSeek(_cFilial+_cPC))
			
			While SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
				
				SC6->(MSUnLock())
				SC6->(MSUnLockall())
				
				SB2->(DBSetOrder(1))
				If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
					
					SB2->(MSUnLock())
					SB2->(MSUnLockall())
					
				EndIf
				
				SC6->(DBSkip())
				
			EndDo
			
		EndIf
		
	EndIf
	
Next _nI

Return _lRet 

/*
===============================================================================================================================
Programa----------: MOMS47Travou()
Autor-------------: Alex Wallauer
Data da Criacao---: 09/10/2018
Descrição---------: Loca os registro de tabelas previamente, Tenta realizar lock de todos os registros por _nI segundos
Parametros--------: _aPedidos: itens, _cErro: Mensagens erro,lSoLiberaPV,aTabelas
Retorno-----------: _ltravou: .T. / .F. 
===============================================================================================================================
*/
Static Function MOMS47Travou(_aPedidos,_cErro,lSoLiberaPV,oProc,aTabelas)

Local _lIT_LOCKPD:= SuperGetMV('IT_LOCKPD',.T.,.F.)
Local _tini      := SECONDS()
Local _dini      := Date()
Local _ltravou   := .F.  
Local  _cMenAtual:=""
DEFAULT aTabelas :={"SC5","SB2"}//"SC6","SA1",
DEFAULT _cErro   :=""

If oProc <> NIL
   _cMenAtual:=oProc:cCaption
EndIf

While !(_ltravou)

   _tini:= SECONDS()
   _dini:= Date()
	
	While !(_ltravou) .And. (seconds() - _tini) < 10 .And. Date() == _dini
		
		_ltravou := .T.
		_cErro   := ""

	    If oProc <> NIL
		   oProc:cCaption := _cMenAtual+". Tentativa:  "+AllTrim( Str((SECONDS()-_tini)+1,2,0) ) 
		   ProcessMessages()
	    EndIf

		If aScan(aTabelas,"SC5") <>  0
			
			If !SC5->(MsRLock(SC5->(RECNO())))
				_cUser:= TCInternal(53)
				_cErro:= "PV esta em uso por "+_cUser
				_ltravou := .F.
				
			Else
				
				If  _lIT_LOCKPD
					
					SC5->(MSUnLockALL())
					SC5->(MSUnLock())

					
				EndIf
				
			EndIf
			
		EndIf
		
		If aScan(aTabelas,"SA1") <>  0
			
			SA1->(DBSetOrder(1))
			SA1->(DBSeek(SA1->(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)))
			If  !SA1->(MsRLock(SA1->(RECNO())))
				_cUser:= TCInternal(53)
				_cErro := "Cliente esta uso: "+AllTrim(SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI)+" por "+_cUser
				_ltravou := .F.
				
			Else
				
				If  _lIT_LOCKPD
					
					SA1->(MSUnLockALL())
					SA1->(MSUnLock())

					
				EndIf
				
			EndIf
			
		EndIf
		
		If aScan(aTabelas,"SC6") <>  0 .Or. aScan(aTabelas,"SB2") <>  0
			
			SB2->(DBSetOrder(1))
			SC6->(DBSetOrder(1))
			SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			
			While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC6->(!Eof())
				
				If aScan(aTabelas,"SC6") <>  0
					If !SC6->(MsRLock(SC6->(RECNO())))
						_cUser:= TCInternal(53)
						_cErro := "Item do PV esta em uso: "+AllTrim(SC6->C6_FILIAL+"/"+SC6->C6_PRODUTO+"/ "+SC6->C6_LOCAL)+" por "+_cUser
						_ltravou := .F.
						
					Else
						
						If  _lIT_LOCKPD
							
							SC6->(MSUnLockALL())
							SC6->(MSUnLock())
							
						EndIf
						
					EndIf
				EndIf
				
				If aScan(aTabelas,"SB2") <>  0
					
					SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
					
					If !SB2->(MsRLock(SB2->(RECNO())))
						_cUser:= TCInternal(53)
						_cErro := "Produto / Armazem esta em uso: "+AllTrim(SC6->C6_PRODUTO)+" / "+SC6->C6_LOCAL+" por "+_cUser
						_ltravou := .F.
					Else
						If  _lIT_LOCKPD
							SB2->(MSUnLockALL())
							SB2->(MSUnLock())
						EndIf
					EndIf
					
					If !lSoLiberaPV
						
						_nI := aScan(_aPedidos, {|x| x[1] == SC6->C6_FILIAL .AND.;
						                             x[2] == SC5->C5_NUM    .AND.;
						                             x[3] == SC6->C6_ITEM   .AND.;
					                             	 x[4] == SC6->C6_PRODUTO})
						
						If _nI > 0
							
							SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+_aPedidos[_nI,5] ))
							
							If !SB2->(MsRLock(SB2->(RECNO())))
								_cUser:= TCInternal(53)
								_cErro := "Produto / Armazem esta em uso: "+AllTrim(SC6->C6_PRODUTO)+" / "+_aPedidos[_nI,5]+" por "+_cUser
								_ltravou := .F.
							Else
								If  _lIT_LOCKPD
									SB2->(MSUnLockALL())
									SB2->(MSUnLock())
								EndIf
							EndIf
							
							
						EndIf
					EndIf
				EndIf
				
				SC6->(DBSkip())
				
			EndDo
			
		EndIf
		
	    If !_ltravou 
		   Sleep(100) //Segura o processamento para testar no máximo 10 vezes por segundo os travamentos
		EndIf
	EndDo
	
	If !_ltravou .And. !lSoLiberaPV
	   If U_ITMsg("Não foi possivel alocar os registros do PV: "+SC5->C5_NUM+" pq o "+_cErro ,;
	              'Atenção!',;
	              "Deseja TENTAR novamente alocar o PV ou FINALIZAR o processamento ?",3,2,3,,"TENTAR","FINALIZAR")//ALERT
          Loop
       Else
          Exit   
	   EndIf		
    Else
       Exit
	EndIf
	
EndDo
If !Empty(_cErro)
   _cErro:="[ "+_cErro+" ]"
EndIf   
If oProc <> NIL
   oProc:cCaption := _cMenAtual
   ProcessMessages()
EndIf

Return _ltravou

/*
===============================================================================================================================
Programa----------: MOMS47LECSV
Autor-------------: Alex Wallauer
Data da Criacao---: 29/05/2020
Descrição---------: Processamento de Importação de DADOS DO CSV do operador logistico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS47LECSV(oProc)

Local _nCpo
Local nQtdeQtde:=5
oProc:cCaption := ("Lendo dados do Arquivo...")
ProcessMessages()

_cArq := AllTrim(MV_PAR92)
If Upper(RIGHT(_cArq,3)) <> "CSV" .Or. FT_FUSE(_cArq) == -1
	U_ITMsg("Não foi possível abrir o arquivo informado: "+_cArq,;
	"Arquivo inválido","O arquivo informado deve ser .CSV ou verificar se o arquivo informado esta correto.",1)
	Return .F.
EndIf

_cTot:=FT_FLASTREC()

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
_cDados := FT_FREADLN()  
If _lConverteu
	If Empty(_cDados) .Or. AllTrim(_cDados) = ';;;;'  .Or. AllTrim(_cDados) = ",,,,"
       FT_FSKIP()  //PULA linha em branco
       _cDados := FT_FREADLN()  
	   _cTot--
	EndIf
	_cDados := StrTran(_cDados,',',';')//Campos com decimais
EndIf
If !"CNPJ;PEDIDO;PRODUTO;QTDE1UM;QTDE2UM" $ Upper(AllTrim(_cDados))
   FT_FUSE()
   U_ITMsg("O arquivo "+_cArq+" informado para relizar a importação não tem o layout padrão.",;
            "Arquivo com formato inválido",;
			"O CSV deve ter as colunas [ CNPJ;PEDIDO;PRODUTO;QTDE1UM;QTDE2UM ] e o mesmo deve ser salvo "+;
		    "no Excel no formato [ CSV (separado por virgulas) ] e "+;
		    "no LibreOffice Calc com Demilitador de campo Ponto e Virgula e sem delimitador de texto.",1)
   Return .F.
EndIf

_cTot:=AllTrim(Str(_cTot-1))
_nTam:=Len(_cTot)
_nCont:=_nConta:=0
_nTamPedido:=Len(SC5->C5_NUM)

_aDados:={}
_nErro:=0
_aRotErro:={}
_aLinRepetido={}
_aPedidos={}
_cCodOP:=""
_cLojOP:=""

SB1->(DBSetOrder(1))
DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))

FT_FSKIP()  //PULA O CABEÇALHO
While !FT_FEOF()  //FAÇA ENQUANTO NAO For FIM DE ARQUIVO
 	
	_nCont++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
	ProcessMessages()
	
	_cDados := FT_FREADLN()
    If _lConverteu
    	_cDados := StrTran(_cDados,',',';')//na conversão vem separado por virgula
    Else
	    _cDados := StrTran(_cDados,'"','')
	    _cDados := StrTran(_cDados,',','.')//Campos com decimais
	EndIf

	
	//Verifica se é final de arquivo
	If Empty(_cDados) .Or. AllTrim(_cDados) = ';;;;'  .Or. (AllTrim(_cDados) = ",,,,")
	   _nConta++
	   If _nConta > 05
	      Exit
	   Else
	      Exit
	   EndIf   
	EndIf

    If aScan(_aLinRepetido,_cDados) = 0
        aAdd(_aLinRepetido,_cDados)    
    Else
       FT_FSKIP()
       Loop
    EndIf
  	
	_aLinhas:= StrTokArr2(_cDados,";",.T.)
	_aItens:={}
	
  	If Len(_aLinhas) < nQtdeQtde
  		_aLinhas:=U_ITTXTARRAY(_cDados,"",nQtdeQtde,nQtdeQtde)
  	EndIf
  
	aAdd(_aItens,.T.                                   )//01
	aAdd(_aItens,If(Len(_aLinhas) > 00,_aLinhas[01],""))//02
	aAdd(_aItens,If(Len(_aLinhas) > 01,_aLinhas[02],""))//03
	aAdd(_aItens,If(Len(_aLinhas) > 02,_aLinhas[03],""))//04
	aAdd(_aItens,If(Len(_aLinhas) > 03,_aLinhas[04],""))//05
	aAdd(_aItens,If(Len(_aLinhas) > 04,_aLinhas[05],""))//06
	
	aAdd(_aItens,"" )
    
   cFilPed:=cFilant//"90"  ou "40"
   If Empty(_aItens[3]) 
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ PEDIDO não informada ]"
   
   Else
      _aItens[3]:=AllTrim( _aItens[3] )

      If !SC5->(DBSeek(cFilPed+_aItens[3]))
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]+="[ PEDIDO não encontrado nessa Filial ] "
      ElseIf If(cFilPed ="90" , (SC5->C5_I_OPER <> "12") , (!SC5->C5_I_OPER $ "10,31") )
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]+="[ PEDIDO não esta na operacao "+If(cFilPed ="90" , "12" , "31" )+", esta na "+SC5->C5_I_OPER+" ] "
      Else

        DAK->(DBSetOrder(1))
		_lTemSC9:=.F.
		_lTodoLiberado:=.F.
		_lPVtemCarga  :=.F.
		If SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			_lTemSC9:=.T.
			_lTodoLiberado:=.T. //SE TIVER TODO LIBERADO NÃO PODE ALTERAR PQ NÃO PRECISA
			While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL+SC5->C5_NUM
				If !Empty(SC9->C9_CARGA)
                    DAK->(DBSeek(SC9->C9_FILIAL+SC9->C9_CARGA))
					_lPVtemCarga:=.T.
					Exit
				EndIf
				If !Empty(SC9->C9_BLEST) //TÁ COM BLOQUEI DE ESTOQUE PODE ALTERAR
					_lTodoLiberado:=.F.
					Exit
				EndIf
				SC9->(DBSkip())
			EndDo
		EndIf
		
		If !_lPVtemCarga
           DAI->(DBSetOrder(4))
           If DAI->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM)) 
              DAK->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_COD))
              _lPVtemCarga:=.T.
	       EndIf
	    EndIf

		If !_lTemSC9
		ElseIf _lPVtemCarga
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ PEDIDO já esta na CARGA: "+SC9->C9_CARGA+" / "+AllTrim(DAK->DAK_I_OBS)+" ]"
		ElseIf !_lTodoLiberado
			_aItens[1]:=.F.
			_aItens[Len(_aItens)]+="[ PEDIDO com bloqueio de estoque no item: "+SC9->C9_PRODUTO+" ]"
		EndIf
	  EndIf
   EndIf

   If _aItens[1]
	  SA1->(DBSetOrder(1))
      If SA1->(DBSeek(xFilial("SA1")+ SC5->C5_CLIENTE+SC5->C5_LOJACLI ))
         If SA1->A1_MSBLQL = '1'
		    _cMsgWK:=" "
			If _aItens[1] 
			   _cMsgWK:=WFCredito(oProc,"")//ENVIA WF DE CREDITO 
			EndIf
            _aItens[1]:=.F.
            _aItens[Len(_aItens)]+="[ Cliente Bloqueado no Protheus ]"+_cMsgWK
         EndIf
	  Else   
         _aItens[1]:=.F.
         _aItens[Len(_aItens)]+="[ CODIGO Cliente não Encontrado no Protheus ]"
      EndIf   
   EndIf
   
   _cCNPJ:=AllTrim(_aItens[2])
   SA2->( DBSetOrder(3) )
   If SA2->(DBSeek(xFilial("SA2")+_cCNPJ))
       _aItens[2]:=_cCNPJ+" [ "+SA2->A2_COD+"-"+SA2->A2_LOJA+" - "+AllTrim(SA2->A2_NREDUZ)+" ]"
   Else   
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ CNPJ  do Operador Logistico não Encontrado no Protheus ]"
   EndIf
   
   If Empty(Val(_aItens[5]) )
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ Qtde 1a UM invalida ]"
   EndIf

   If Empty(Val(_aItens[6]) )
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ Qtde 2a UM invalida ]"
   EndIf

   _cCodSB1:=AllTrim(_aItens[4])
   If SB1->(DBSeek(xFilial("SB1")+_cCodSB1))
       _cCodSB1:=SB1->B1_COD
       _aItens[4]:=_cCodSB1+"- "+AllTrim(SB1->B1_DESC)
	   SC6->( DBSetOrder(12) )//C - C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
	   If !SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM+_cCodSB1))
          _aItens[1]:=.F.
          _aItens[Len(_aItens)]+="[ Produto não Encontrado no Pedido do Protheus (SC6) ]"
	   ElseIf !SC6->C6_LOCAL $ "50/52"
          _aItens[1]:=.F.
          _aItens[Len(_aItens)]+="[ Produto não esta com Local 50/52, esta: "+SC6->C6_LOCAL+" ]"
	   Else//If _aItens[1]
		   If Val(_aItens[5]) > SC6->C6_QTDVEN//NÃO PODE  - 1UM
		      If SB1->B1_CONV = 0 //SE É QUEIJO
                 _aItens[Len(_aItens)]+="[ *Produto (QUEIJO) com quantidade da primeira unidade ("+SC6->C6_UM+") maior que no Protheus ("+cValToChar(SC6->C6_QTDVEN)+")  ]"
              Else//SENÃO É QUEIJO
                 _aItens[1]:=.F.
                 _aItens[Len(_aItens)]+="[ Produto com quantidade da primeira unidade ("+SC6->C6_UM+") maior que no Protheus ("+cValToChar(SC6->C6_QTDVEN)+")  ]"
		      EndIf
           ElseIf Val(_aItens[5]) < SC6->C6_QTDVEN//PODE
              _aItens[Len(_aItens)]+="[ *Produto com quantidade da primeira unidade ("+SC6->C6_UM+") menor que no Protheus ("+cValToChar(SC6->C6_QTDVEN)+") ]"
		   EndIf

	       _aItens[5]:=AllTrim(_aItens[5])+" "+SC6->C6_UM
		   If Val(_aItens[6]) > SC6->C6_UNSVEN//NÃO PODE - 2UM
              _aItens[1]:=.F.
              _aItens[Len(_aItens)]+="[ Produto com quantidade da segunda unidade ("+SC6->C6_SEGUM+") maior que no Protheus ("+cValToChar(SC6->C6_UNSVEN)+") ]"
           ElseIf Val(_aItens[6]) < SC6->C6_UNSVEN//PODE
              _aItens[Len(_aItens)]+="[ *Produto com quantidade da segunda unidade ("+SC6->C6_SEGUM+") menor que no Protheus ("+cValToChar(SC6->C6_UNSVEN)+") ]"
		   EndIf
           
		   If (Val(_aItens[5]) <> SC6->C6_QTDVEN .Or. Val(_aItens[6]) <> SC6->C6_UNSVEN )
	          nFator    := SB1->B1_CONV
              _nQtdProd := Val(_aItens[5])//QTDE 1UM
              _nQtd2UM  := Val(_aItens[6])//QTDE 2UM
		      If nFator = 0 //SE É QUEIJO
                 _nFtMin   := SB1->B1_I_FTMIN
                 _nFtMax   := SB1->B1_I_FTMAX                
                 _nVlrPeca := _nQtdProd / _nQtd2UM
                 If _nVlrPeca < _nFtMin .Or. _nVlrPeca > _nFtMax //Fora dos limites: menor que o Minimo ou maior que o Maximo
                    _aItens[1]:=.F.
                    _aItens[Len(_aItens)]+="[ Produto (QUEIJO) com quantidade em Peça ("+cValToChar(_nVlrPeca)+") fora da faixa minima ("+cValToChar(_nFtMin)+") ou maxima ("+cValToChar(_nFtMax)+") ]"
                 EndIf
              Else//SENÃO É QUEIJO
	             cTipConv:= SB1->B1_TIPCONV
	             If cTipConv == 'D'
	             	nQtd2UM := _nQtdProd/nFator
	             ElseIf cTipConv == 'M'
	             	nQtd2UM := _nQtdProd*nFator
	             EndIf
                 If Val(_aItens[6]) <> nQtd2UM
				     _aItens[1]:=.F.
                    _aItens[Len(_aItens)]+="[ Produto com quantidade na 2UM convertida ("+cValToChar(nQtd2UM)+") diferente da recebida ("+cValToChar(_aItens[6])+") ]"
				 EndIf
		      EndIf
		   EndIf

	       _aItens[6]:=AllTrim(_aItens[6])+" "+SC6->C6_SEGUM
	   EndIf
   Else
      _aItens[1]:=.F.
      _aItens[Len(_aItens)]+="[ Produto não Encontrado no Protheus (SB1) ]"
   EndIf

   If _aItens[1] = .F.
      aAdd(_aRotErro,_aItens[3])
      _nErro++
   EndIf
   aAdd(_aDados,_aItens)

   FT_FSKIP()

EndDo

FT_FUSE()

If Len(_aDados) > 0

   SC6->(DBSetOrder(1))
   _aRotAux:={}
   For _nCpo := 1 TO Len(_aDados)

       If _aDados[_nCpo,1] .And. aScan(_aRotAux,_aDados[_nCpo,3]) = 0//Se não achou erro no pedido inteiro
          _cPC := PadR(_aDados[_nCpo,3],_nTamPedido," ")
          If SC6->(DBSeek(cFilPed+_cPC))
             While SC6->C6_FILIAL + SC6->C6_NUM == cFilPed+_cPC
			    If aScan(_aDados , {|P| P[3] == SC6->C6_NUM .And. SC6->C6_PRODUTO == LEFT(P[4],Len(SC6->C6_PRODUTO)) } ) = 0
                   _aDados[_nCpo,Len(_aDados[1])]+="[ Pedido com item "+AllTrim(SC6->C6_PRODUTO)+" a mais no Protheus ]"
				   aAdd(_aRotAux,_aDados[_nCpo,3])
				   //Exit
				EndIf
                SC6->( DBSkip())
             EndDo
          EndIf
       EndIf
       If Len(_aRotErro) = 0 .And. aScan(_aPedidos,_aDados[_nCpo,3]) = 0//SO VALIDA CREDITO SE NÃO TIVER ERRO
          _cPC := PadR(_aDados[_nCpo,3],_nTamPedido," ")
          If SC5->(DBSeek(cFilPed+_cPC))
		     _cMenBloq:=VerCredito(cFilPed+_cPC, oProc)
			 _aDados[_nCpo,Len(_aDados[1])]+=_cMenBloq
          EndIf
          aAdd(_aPedidos,_aDados[_nCpo,3])
	   EndIf

   Next _nCpo

   For _nCpo := 1 TO Len(_aDados)

       If _aDados[_nCpo,1] .And. aScan(_aRotErro,_aDados[_nCpo,3]) <> 0//Se achou
          _aDados[_nCpo,1]:=.F.//Se um der errado não vai integra o pedido todo
          _aDados[_nCpo,Len(_aDados[1])]+="[ Pedido com 1 ou mais itens com erro ] "
	   EndIf

   Next _nCpo
	//Monta _aCab
	_aCab:={}
	_aSize:={}
	aAdd(_aCab,"")//01
	aAdd(_aSize,05)
	aAdd(_aCab,"CNPJ do Oper. Lojistico")//02
	aAdd(_aSize,100)
	aAdd(_aCab,"Pedido")//03
	aAdd(_aSize,30)
	aAdd(_aCab,"Produto")//04
	aAdd(_aSize,150)
	aAdd(_aCab,"Qtde 1 UM")//05
	aAdd(_aSize,40)
	aAdd(_aCab,"Qtde 2 UM")//06 
	aAdd(_aSize,40)
	aAdd(_aCab,"Resultado")//20
	aAdd(_aSize,300)
	
	_cTitAux:="Dados do Arquivo "+_cArq
	_cMsgTop:="Importação Operador Logistico, Registros Lidos: "+AllTrim(TRANSFORM(Len(_aDados),"@E 999,999,999"))+", Com Erros: "+AllTrim(TRANSFORM(_nErro,"@E 999,999,999"))
	While .T.

        aSort( _aDados ,,, {|X,Y| X[2]+X[3]+X[4] < Y[2]+Y[3]+Y[4] } )

        nPosResu:=Len(_aDados[1])//Posiçao dos "Erros"
        _aButtons:={}
        aAdd(_aButtons,{"BUDGET",{|| AVISO("PROBLEMA",oLbxAux:aArray[oLbxAux:nAt][nPosResu],{"Fechar"},3)  },"", "Visualizar Erro" }) 
   		//     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
		lOK:=U_ITLISTBOX(_cTitAux, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop  ,          , _aSize  ,         ,     ,        , _aButtons)
		If lOK .And. _nErro > 0
		   U_ITMsg("Carga NÃO pode ser Gerada","ATENÇÃO!","Carga NÃO pode ter Pedidos / Itens com problemas",2)
		   Loop
		EndIf
		If lOK .And. U_ITMsg("Confirma geracao da CARGA ?",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")
           _aCargaOP:={}
           _aDadosAux:={}
		   
		   //_cPedAux:=""
           For _nCpo := 1 TO Len(_aDados)//GRAVA A CARGA OPERADOR LOGISTICO
               If _aDados[_nCpo,1]  //.AND. !_aDados[_nCpo,3] $ _cPedAux
                  //_cPedAux+=_aDados[_nCpo,3]+";"//Controle para por o Pedido uma vez só na lista 
                  If (nPos:=aScan(_aCargaOP,{|C| C[1] == _aDados[_nCpo,2] } ) ) = 0
                     aAdd(_aCargaOP, { _aDados[_nCpo,2] , { _aDados[_nCpo] } } )
                  Else
                     aAdd(_aCargaOP[nPos,2] ,_aDados[_nCpo] )
                  EndIf
   			      aAdd(_aDadosAux,_aDados[_nCpo])
               EndIf
           Next _nCpo

           _cTot:=Len(_aCargaOP)
           _cTot:=AllTrim(Str(_cTot))
		   _nErro:=0
           For _nCpo := 1 TO Len(_aCargaOP)
		       _cCNPJ:=LEFT(_aCargaOP[_nCpo,1],Len(SA2->A2_CGC))
               SA2->( DBSetOrder(3) )
               If SA2->(DBSeek(xFilial("SA2")+_cCNPJ))
                  _cCodOP:=SA2->A2_COD
                  _cLojOP:=SA2->A2_LOJA  
			      While SA2->(!Eof()) .And. _cCNPJ == SA2->A2_CGC
				     If SA2->A2_I_CLASS = "T"
                        _cCodOP:=SA2->A2_COD
                        _cLojOP:=SA2->A2_LOJA  
					 EndIf
					 SA2->(DBSkip())
				  EndDo	 
			   EndIf
   			   MOMS47Carga(oProc,"Operador Logistico",_aCargaOP[_nCpo,2],_cTot,.T.)//GRAVA A CARGA OPERADOR LOGISTICO
   		   Next _nCpo
           
           _aDados:=ACLONE(_aDadosAux)
           nPosResu:=Len(_aDados[1])//Posiçao dos "Erros"
           _aButtons:={}
           aAdd(_aButtons,{"BUDGET",{|| AVISO("PROBLEMA",oLbxAux:aArray[oLbxAux:nAt][nPosResu],{"Fechar"},3)  },"", "Visualizar Erro" }) 
		   If _nErro > 0 
	   	      _cMsgTop:="CARGA NÃO FOI GERADA, Registros Lidos: "+AllTrim(TRANSFORM(Val(_cTot),"@E 999,999,999"))+", Com Erros: "+AllTrim(TRANSFORM(_nErro,"@E 999,999,999"))
		   EndIf	
   		   //     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo ,_cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
		   lOK:=U_ITLISTBOX(_cTitAux, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop ,          , _aSize  ,         ,     ,        , _aButtons)
		   Exit
		ElseIf !lOK .And. U_ITMsg("Confirma SAIR ?",'Atenção!',"Todos os registros de válidações serão perdidos",3,2,3,,"CONFIRMA","Voltar")
		   Exit
		EndIf
		
	EndDo
Else
	U_ITMsg("Nenhum registro válido",'Atenção!',"Dados do Arquivo "+_cArq,1)
EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: MOM47GT
Autor-------------: Alex Wallauer 
Data da Criacao---: 23/07/2020
Descrição---------: Schedule de exportação .txt operador logistico para filail 40
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOM47GT()//U_MOM47GT - Schedule da filial 40

Return MOM47GFT(.F.,,"40")//FUNCTION Static

/*
===============================================================================================================================
Programa----------: MOM47GFT
Autor-------------: Jonathan Torioni
Data da Criacao---: 27/06/2020
Descrição---------: Schedule de exportação .txt operador logistico para filail 90
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOM47GFT()//U_MOM47GFT - Schedule da filial 90

Return MOM47GFT(.F.,,"90")//FUNCTION Static

/*
===============================================================================================================================
Programa----------: MOM47GFT
Autor-------------: Jonathan Torioni
Data da Criacao---: 27/06/2020
Descrição---------: Schedule de exportação .txt operador logistico para filail 90
Parametros--------: lLTela, oProc,cFilTab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOM47GFT(lLTela, oProc,cFilTab)

Local cNomArq		:= ""
Local cAlSc5		:= GetNextAlias()
Local cQuery		:= ""
Local aStrAcb		:= {}
Local aAux			:= {}
Local aPedLog		:= {}
Local aEmp			:= {}
Local aCols			:= {}
Local aTabelas		:= {"SC5","SC6","SB1","SA1","CC2","SA2","SX6", "ZP1"}
Local nX			:= 0
Local nPesLiq		:= 0
Local nVlNota		:= 0
Local nVlDesc		:= 0
Local nRet			:= 0
Local dDate			:= Date()
Local cArqTemp		:= "\data\Italac\NT\"
Local cStrOne		:= ""
Local cStrTwo		:= ""
Local cCNPJ			:= ""
Local cCFO			:= ""
Local cSep			:= ""
Local cDtini
Local cExt			:= ""
Local nHandle,nI,R		
Local lFormat		:= .F.
Local lControl		:= .T.
Local _bOK          :={|| If(MV_PAR03 >= MV_PAR02,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
Local aOpcoes:={}
Local _aParAux:={}
Local _aParRet:={}
Local _lAmbTeste := .F.
Private lTela:= If(lLTela=NIL,.F.,lLTela)
DEFAULT cFilTab:= cFilant
Private _cResultado:=""//Variavel alterada dentro da funcao MOM047GerExcel() tb

	If lTela

       MV_PAR81:="1-NÃO ENVIADOS"
       MV_PAR82:=dDataBase
       MV_PAR83:=dDataBase
       
       aOpcoes:={}
       aAdd(aOpcoes,"1-NÃO ENVIADOS")
       aAdd(aOpcoes,"2-ENVIADOS    ")
       _aParAux:={}
       aAdd( _aParAux , { 2 , "Escolha uma Opção", MV_PAR81, aOpcoes,100    ,".T.",.T.,".T."})
       aAdd( _aParAux , { 1 , "Data de:"	     , MV_PAR82, "@D"	, ""	, ""		, "" , 050 , .F. } )
       aAdd( _aParAux , { 1 , "Data ate:"	     , MV_PAR83, "@D"	, ""	, ""		, "" , 050 , .F. } )
       _aParRet:={}
       For nI := 1 To Len( _aParAux )
       	   aAdd( _aParRet , _aParAux[nI][03] )
       Next nI
       //        aParametros ,cTitle                 ,aRet      ,bOk   ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
       If ParamBox( _aParAux , "Selecione uma Opcao" , @_aParRet, _bOK ,        , .T.     ,     ,     ,          ,     , .T.    , .T. )
          MV_PAR81:=MV_PAR01
          MV_PAR82:=MV_PAR02
          MV_PAR83:=MV_PAR03
	   Else	     
	     Return .F.      
	   EndIf
		cDtini	:=  SuperGetMV('IT_DTINEXP',.T.,CTOD("01/06/20"))
		_lAmbTeste := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		If _lAmbTeste
		    cDtini:=CTOD("01/05/20")
		EndIf
	Else
		RPCSetType(3)
        RpcSetEnv("01",cFilTab ,,,, "SCHEDULE_MOMS047_OPLOG", aTabelas)
        sleep( 5000 )
		U_ItConOut("MOMS047 - Iniciando schedule de exportação pedidos/operador logistico, Filial: "+cFilTab)
		cFilant := cFilTab
		cDtini	:= SuperGetMV('IT_DTINEXP',.T.,CTOD("01/06/20"))
		MV_PAR81:= "1"
		_lAmbTeste := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		If _lAmbTeste
		   MV_PAR81:= "2"
           MV_PAR82:=(dDataBase-30)
           MV_PAR83:=dDataBase
		EndIf
		DBSelectArea("SC5")
	EndIf
	//Pego as informações da filial sem desposicionar o SM0
	aEmp := FWSM0Util():GetSM0Data( "01",cFilTab)
	
	//Define a estrutura do cabeçalho da nota para a tabela temporária
	If lTela
		oproc:cCaption := ("Carregando query de pedidos...")
		ProcessMessages()
		aAdd(aStrAcb,"Filial")
		aAdd(aStrAcb,"Pedido")
		aAdd(aStrAcb,"Emissao")
		aAdd(aStrAcb,"Cliente")
		aAdd(aStrAcb,"Codigo")
		aAdd(aStrAcb,"Loja")
		aAdd(aStrAcb,"Operador Logistico")
		If cFilAnt = "90"
		   aAdd(aStrAcb,"Pedido do Operador")
		ElseIf cFilAnt = "40"
		   aAdd(aStrAcb,"E-MAIL do Operador Logistico")
		EndIf
	EndIf
	/*
	Filtro todos os itens com Local 50 ou 52, sem fatura, senhum bloqueio, sem ter enviado
	com emisão >= 01/06/2020 para a filial 90	*/
	cQuery += " SELECT DISTINCT C5.* FROM " + RetSqlName("SC6") + " C6, " + RetSqlName("SC5") + " C5 "
	cQuery += " WHERE C6.D_E_L_E_T_ = ' ' "
	cQuery += "	AND C6_FILIAL = '" + cFilTab + "' "
	cQuery += " AND C6.C6_LOCAL IN ('50','52') "
	cQuery += " AND C5_FILIAL = C6_FILIAL "
	cQuery += " AND C5_NUM   = C6_NUM "
	If LEFT(MV_PAR81,1) = "1"//NÃO ENVIADOS
	   cQuery += " AND C5_EMISSAO  >= '"+DToS(cDtini)+"' "
	   cQuery += " AND C5_I_EXPOP = ' ' "
	Else//ENVIADOS
	   If !Empty(MV_PAR82)
	      cQuery += " AND C5_EMISSAO  >= '"+DToS(MV_PAR82)+"' "
	   EndIf
	   If !Empty(MV_PAR83)
	      cQuery += " AND C5_EMISSAO  <= '"+DToS(MV_PAR83)+"' "
	   EndIf
	   cQuery += " AND C5_I_EXPOP <> ' ' "
	EndIf
	cQuery += " AND C5.D_E_L_E_T_ = ' ' "
	cQuery += " AND C5_TIPO = 'N' "
	cQuery += " AND C5_NOTA = ' ' "
	If  cFilant = "90"
	    cQuery += " AND C5_I_OPER = '12'"
    ElseIf  cFilant = "40"
	    cQuery += " AND (C5_I_OPER = '31' OR C5_I_OPER = '10') "
	EndIf
	cQuery += " AND C5_TIPO = 'N'"
	If !_lAmbTeste
	   cQuery += " AND NOT EXISTS (SELECT 'X' FROM " + RetSqlName("DAI") + " DAI "
	   cQuery += " 				WHERE DAI.D_E_L_E_T_ = ' ' "
	   cQuery += " 				AND DAI.DAI_FILIAL   = C5.C5_FILIAL  "
	   cQuery += " 				AND DAI.DAI_PEDIDO = C5.C5_NUM ) "
	EndIf
	cQuery := ChangeQuery(cQuery)
	MPSysOpenQuery(cQuery,cAlSc5)

	DBSelectArea("SC6")
	SC6->(DBSetOrder(1))
	If lTela
		oproc:cCaption := ("Realizando pré separação dos dados...")
		ProcessMessages()
	EndIf
	While (cAlSc5)->(!Eof())
		If SC6->(DBSeek( (cAlSc5)->C5_FILIAL+(cAlSc5)->C5_NUM ))
			While SC6->(!Eof()) .And. SC6->C6_FILIAL == (cAlSc5)->C5_FILIAL .And. SC6->C6_NUM == (cAlSc5)->C5_NUM
				If !(SC6->C6_LOCAL $ "50,52")
					//Array com pedidos desconsiderados no processamento
					aAdd(aAux, {SC6->C6_FILIAL, SC6->C6_NUM, SC6->C6_ITEM})
					Exit
				EndIf
				SC6->(DBSkip())
			EndDo
		EndIf
		(cAlSc5)->(DBSkip())
	EndDo
	
	(cAlSc5)->(DBGoTop())
	SA1->(DBSetOrder(1))
	CC2->(DBSetOrder(1))
	SB1->(DBSetOrder(1))
	SA2->(DBSetOrder(1))	
	//Monto array com as informações de Pedido X Operador Logistico
	While (cAlSc5)->(!Eof())

		If lTela
			oproc:cCaption := ("Lendo Pedido: "+(cAlSc5)->C5_NUM)
			ProcessMessages()
		EndIf

		If aScan(aAux,{|X| X[1] = (cAlSc5)->C5_FILIAL .And. X[2] = (cAlSc5)->C5_NUM}) == 0
			If SA1->(DBSeek(xFilial("SA1")+(cAlSc5)->C5_CLIENTE+(cAlSc5)->C5_LOJACLI))
				If CC2->(DBSeek(xFilial("CC2")+AllTrim(SA1->A1_EST)+AllTrim(SA1->A1_COD_MUN)))
					If !Empty(CC2->CC2_I_OPCO) .And. CC2->CC2_I_ENVO <> "2"
						If SA2->(DBSeek(xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO))
							aAdd(aPedLog, {	(cAlSc5)->C5_FILIAL,; //01
											(cAlSc5)->C5_NUM,;    //02
											SA1->A1_NREDUZ,;      //03
											CC2->CC2_I_OPCO,;     //04
											CC2->CC2_I_OPLO,;     //05
											AllTrim(SA2->A2_I_SRVFT),;//06
											SA2->A2_I_PRTFT			,;//07
											AllTrim(SA2->A2_I_USRFT),;//08
											AllTrim(SA2->A2_I_PASWD),;//09
											AllTrim(SA2->A2_I_DIRFT),;//10
											CC2->CC2_I_OPCO+CC2->CC2_I_OPLO})//11
							If lTela
								aAdd(aCols, {	(cAlSc5)->C5_FILIAL,;//01
												(cAlSc5)->C5_NUM,;   //02
												DToC(SToD((cAlSc5)->C5_EMISSAO)),; //03
												(cAlSc5)->C5_CLIENTE+(cAlSc5)->C5_LOJACLI+" - "+SA1->A1_NREDUZ,;//04
												CC2->CC2_I_OPCO,;//05
												CC2->CC2_I_OPLO,;//06
												Posicione("SA2",1,xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO,"A2_NOME"),;
												AllTrim(SA2->A2_EMAIL) })
							EndIf
							
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		(cAlSc5)->(DBSkip())
	EndDo

    If cFilant = "40" .And. Len(aPedlog) = 0 .And. 	!lTela
       _aGerExcel:={}
	   MOM047GerExcel()
	EndIf

	//Ordeno por operador logistico
	aPedLog:=aSort(aPedLog, , , { | x,y | x[1]+x[4]+x[5]+x[2] > y[1]+y[4]+y[5]+y[2] } )
	aCols  :=aSort(aCols  , , , { | x,y | x[1]+x[5]+x[6]+x[2] > y[1]+y[5]+y[6]+y[2] } )
	If lTela
	    If Len(aCols) > 0
		   _cMsgTop := "Pedidos Encontrados: "+cValToChar( Len(aCols) )
		   If !U_ITListBox( "PEDIDOS PARA EXPORTAR PARA O OPERADOR LOGISTICO" , aStrAcb , aCols , .T. , 1 , _cMsgTop , /*_lSelUnc*/ , /*_aSizes*/ , /*_nCampo*/ , /*bOk*/ , /*bCancel*/, /*aButtons*/ , /*aCampos*/ , /*bDblClk*/ , aCols , /*bCondMarca*/)
		   	  Return .F.
		   EndIf
		   If !U_ITMsg("Confirma exportação dos dados?",'Atenção!',,2,2,2)
		   	  Return .F.
		   EndIf
		Else
		   If U_ITMsg("Nao há pedidos para enviar","Processo finalizado!","Confirma o envido do e-mail mesmo assim?",2,2,2)
              _aGerExcel:={}
	          MOM047GerExcel()
		   EndIf
		   Return .F.
		EndIf
	EndIf
	_aRecPOS:={}
	_cArquivos:=""
	_nEnviados:=0
	_nPVporArq:=0
	aCols:={}
    _aGerExcel:={}

	For nX := 1 TO Len(aPedLog)
		
		If lTela
			oproc:cCaption := ("Exportando Pedido: "+aPedLog[nX][5]+" [" + cValToChar(nX) +"] de [" + cValToChar(Len(aPedLog)) +"]")
			ProcessMessages()
		EndIf
		nPesLiq := 0
		nVlNota	:= 0
		nVlDesc := 0
		cCFO	:= ""
		//Controle de numeração do arquivo
		If lControl .And. cFilant = "90"
            cExt:= ".txt"
		    nHandle:= -1
		    cSeq   :="01"
			cNomArq:="ITA"+RIGHT(AllTrim(aPedLog[nX][10]),3)+StrZero(MONTH(dDate),2)+ StrZero(DAY(dDate),2) 
			If ExistDir(cArqTemp+aPedLog[nX][4]+aPedLog[nX][5])				
				While File(cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cSeq+cExt)
					cSeq := Soma1(cSeq)
				EndDo
				nHandle := FCreate(cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cSeq+cExt)
			Else
				nRet := MakeDir(cArqTemp+aPedLog[nX][4]+aPedLog[nX][5])
				If nRet <> 0
					U_ItConout("Não foi possível criar o diretório: "+ cArqTemp+aPedLog[nX][4]+aPedLog[nX][5])
					If lTela
				       U_ITMsg("Não foi possível criar o diretório: "+ cArqTemp+aPedLog[nX][4]+aPedLog[nX][5] ,,,1)
					EndIf
					Return .F.
				Else
					nHandle := FCreate(cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cSeq+cExt)
				EndIf
			EndIf
			cNomArq:=cNomArq+cSeq
			_cArquivos:=cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt			

		    If nHandle == -1
		    	U_ItConOut("Não foi possível criar o arquivo: " + cArqTemp + cNomArq )
		    	If lTela
		    	   U_ITMsg("Não foi possível criar o arquivo: " + cArqTemp + cNomArq ,,,1)
		    	EndIf
		    	Return .F.
		    EndIf

		EndIf

		If cFilant = "40"

		   If lControl 
              _aGerExcel:={}
		   EndIf

			SC5->(DBSeek(aPedLog[nX][1]+aPedLog[nX][2]))
			SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			CC2->(DBSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN ))
			SA2->(DBSeek(xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO))//A2_EMAIL

			aAdd(_aRecPOS,{SC5->(RECNO()),""})
			If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			   While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
				  aAdd(_aGerExcel,{AllTrim(SA2->A2_CGC),; //01
				  				  SC5->C5_NUM,;          //02
				  				  SC6->C6_PRODUTO,;      //03
				  				  SC6->C6_QTDVEN ,;      //04
				  				  SC6->C6_UNSVEN,;       //05
				  				  Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_DESC"),;//06
				  				  AllTrim(SA1->A1_CGC),; //07
				  				  AllTrim(SA1->A1_NOME),;//08
				  				  AllTrim(CC2->CC2_MUN),;//09
				  				  Round(SC6->C6_I_PTBRU,2),;//10
				  				  SC5->C5_EMISSAO         ,;//11
				  				  SC5->C5_I_HREMI         })//12
				  SC6->(DBSkip())
			   EndDo
			EndIf
		
		ElseIf  cFilant = "90"

			If SC5->(DBSeek(aPedLog[nX][1]+aPedLog[nX][2]))
				If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
					If CC2->(DBSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN ))
						If SA2->(DBSeek(xFilial("SA2")+aPedLog[nX][4]+aPedLog[nX][5] ))
							//PESO LIQUIDO DA CARGA
							If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
								cCFO := SC6->C6_CF
								While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
									nVlNota += SC6->C6_VALOR
									nVlDesc += SC6->C6_VALDESC
									If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
										nPesLiq += SC6->C6_QTDVEN * SB1->B1_PESO
									EndIf
									SC6->(DBSkip())
								EndDo
							EndIf
							//Montagem feita de forma manual para faciliar a inclusão ou remoção de posições no arquivo
							//Monto a string com as posiçoes do registro tipo 1 Cab.Pedido
							_cPedOP:=SC5->C5_I_PEDOP
							If Empty(_cPedOP)
							   _cPedOP  := GeraNoPed()
							EndIf
						    aAdd(_aRecPOS,{SC5->(RECNO()),_cPedOP})
							cStrOne += "1"+cSep																			//Tipo do Registro (Preencher Fixo 1) 
							cStrOne += PadR(_cPedOP,8) +cSep															//Número da Nota Fiscal
							cStrOne += SubStr(SC5->C5_SERIE,1,2)	+cSep												//Série da Nota Fiscal
							cStrOne += DToS(SC5->C5_EMISSAO)+cSep														//Data de Emissao da Nota Fiscal (AAAAMMDD)
							cStrOne += DToS(SC5->C5_I_DTENT)+cSep														//Data da Coleta (AAAAMMDD)
							cStrOne += PadR(cCNPJ,14)+cSep																//Cnpj de quem vai pagar o frete
							cStrOne += "S"+cSep																			//(S = Frete Pago) (N = Frete a Pagar)	
							cStrOne += "S"+cSep																			//(S = Dedespacho Pago) (N = Redespacho a Pagar)
							cStrOne += StrZero(Val(aEmp[10][2]),14)+cSep												//Cnpj do Remetente
							cStrOne += PadR(aEmp[5][2],40)+cSep															//Razão Social do Remetente
							cStrOne += PadR(aEmp[14][2],40)+cSep														//Endereço do Remetente
							cStrOne += PadR(aEmp[23][2],30)+cSep														//Bairro do Remetente
							cStrOne += PadR(aEmp[17][2],40)+cSep														//Cidade do Remetente
							cStrOne += aEmp[18][2]+cSep																	//Sigla do Estado do Remetente
							cStrOne += PadR(aEmp[12][2],15)	+ cSep														//Inscrição Estadual do Remetente
							cStrOne += PadR(SA1->A1_CGC,14)+cSep														//Cnpj do Destinatario
							cStrOne += SubStr(SA1->A1_NOME,1,40) +cSep													//Razão Social do Destinatario
							cStrOne += SubStr(SA1->A1_END,1,40) +cSep													//Endereço do Destinatario
							cStrOne += SubStr(SA1->A1_BAIRRO,1,30) +cSep												//Bairro do Destinatario
							cStrOne += SubStr(SA1->A1_MUN,1,40) +cSep													//Cidade do Destinatario
							cStrOne += SA1->A1_EST +cSep																//Sigla do Estado do Destinatario
							cStrOne += PadR(SA1->A1_INSCR,15)+cSep														//Inscrição Estadual do Destinatario
							cStrOne += Space(14) + cSep																	//Cnpj do Consignatario
							cStrOne += Space(40) + cSep																	//Razão Social do Consignatario
							cStrOne += Space(40) + cSep																	//Endereço do Consignatario
							cStrOne += Space(30) + cSep																	//Bairro do Consignatario
							cStrOne += Space(40) + cSep																	//Cidade do Consignatario
							cStrOne += Space(2) + cSep																	//Sigla do Estado do Consignatario
							cStrOne += Space(15) + cSep																	//Inscrição Estadual do Consignatario
							cStrOne += StrZero(Val(SA2->A2_CGC),14)+ cSep												//Cnpj do Redespacho
							cStrOne += SubStr(SA2->A2_NOME,1,40) + cSep													//Razão Social do Redespacho
							cStrOne += SubStr(SA2->A2_END,1,40) + cSep													//Endereço do Redespacho
							cStrOne += SubStr(SA2->A2_BAIRRO,1,30) + cSep												//Bairro do Redespacho
							cStrOne += PadR(SubStr(SA2->A2_MUN,1,12),12) + cSep											//Cidade do Redespacho
							cStrOne += StrZero(Val(aEmp[30][2]),7) + cSep												//Codigo da Cidade do Remetente
							cStrOne += StrZero(Val(SA1->A1_COD_MUN),7)+ cSep											//Codigo da Cidade do Destinatario
							cStrOne += StrZero(0,7) + cSep																//Codigo do Numero da Linha
							cStrOne += StrZero(0,7) + cSep																//Codigo da Tabela de Preço
							cStrOne += Space(2) + cSep																	//Sigla do Estado do Redespacho
							cStrOne += Space(15) + cSep																	//Inscrição Estadual do Redespacho
							cStrOne += Space(30) + cSep																	//Natureza da Carga
							cStrOne += PadR(SubStr(SC5->C5_ESPECI1,1,30),30) + cSep										//Espécie da Embalagem
							cStrOne += MOM47NUM(SC5->C5_VOLUME1,5,2,,lFormat) + cSep 									//Qtde de Volumes (99999,99)
							cStrOne += StrZero(0,8) + cSep																//Numero Sequencial dos Volumes
							cStrOne += MOM47NUM(SC5->C5_I_PESBR,6,3,,lFormat) + cSep									//Peso Bruto da Carga (999999,999)
							cStrOne += MOM47NUM(nPesLiq,6,3,,lFormat) + cSep											//Peso Liquido da Carga (999999,999)
							cStrOne += MOM47NUM(0,5,4,,lFormat) + cSep													//Peso Cubico da Carga (99999,9999)
							cStrOne += MOM47NUM(nVlNota,11,2,,lFormat) + cSep											//Valor Total da Nota (99999999999,99)
							cStrOne += MOM47NUM(nVlDesc,11,2,,lFormat) + cSep											//Valor do Desconto da Nota (99999999999,99)
							cStrOne += StrZero(0,8)	+ cSep																//Numero do Manifesto
							cStrOne += StrZero(0,8)	+ cSep																//Data do Manifesto (AAAAMMDD)
							cStrOne += StrZero(0,8)	+ cSep																//Numero da Ordem de Coleta 
							cStrOne += DToS(SC5->C5_I_DTENT )+ cSep														//Dt. Previsão de Entrega no Cliente
							cStrOne += "1 "	+ cSep																		//Modelo do Docto Fiscal (55-Nfe ou 1)
							cStrOne += Space(1)	+ cSep																	//Sub-Série do Docto Fiscal (Em Branco)
							cStrOne += MOM47NUM(0,11,2,,lFormat) + cSep													//Base da Substituição Tributária
							cStrOne += MOM47NUM(0,11,2,,lFormat) + cSep													//Icms da Substiuição Tributária
							cStrOne += PadR(SubStr(Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME"),1,40),40)	+ cSep	//Nome do Representante que Efetuou a Venda
							cStrOne += PadR(SC5->C5_NUM,40)	+ cSep												        //Observação da Nota Fiscal
							cStrOne += MOM47NUM(0,11,2,,lFormat) + cSep													//Valor da Base de Cálculo do ICMS da Nota Fiscal
							cStrOne += MOM47NUM(0,11,2,,lFormat) + cSep													//Valor do Icms da Nota Fiscal
							cStrOne += StrZero(Val(cCFO),4) + cSep														//CFOP de maior predominância na NF
							cStrOne += Space(44) + cSep																	//Chave de Acesso da NFE no Sefaz
							cStrOne += StrZero(0,10) + cSep																//Número do Pim da Suframa
							cStrOne += SA1->A1_CEP+cSep																	//Cep do Destinatário
							cStrOne += StrZero(0,12) + cSep																//Referência de Transporte - Número do Carro
							cStrOne += PadR(SA1->A1_TEL,20)																//Telefone Comercial do Destinatário
							
							FSEEK( nHandle,0,2)
							FWrite( nHandle, cStrOne+CRLF)

							cStrOne := ""

							//Montagem da string dos itens do pedido
							If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
								While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
									cStrTwo += "2"+ cSep																		//Tipo do Registro (Preencher Fixo 2) 
									cStrTwo += PadR(_cPedOP,8)+ cSep														    //Número da Nota Fiscal
									cStrTwo += PadR(SC6->C6_SERIE,2)+ cSep														//Série da Nota Fiscal
									cStrTwo += StrZero(Val(SC6->C6_ITEM),4)+ cSep												//Item da Nota Fiscal
									cStrTwo += PadR(SC6->C6_PRODUTO,15)+ cSep													//Código do Produto do Cliente (Sem edição/mascara)
									cStrTwo += PadR(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_DESC"),40)+ cSep		//Descrição do Produto
									cStrTwo += SC6->C6_UM+ cSep																	//Unidade do Produto
									cStrTwo += MOM47NUM(SC6->C6_QTDVEN,7,3,,lFormat) + cSep 									//Qtde do Item  (9999999,999)
									cStrTwo += MOM47NUM(MOMS47TT(),5,2,,lFormat) + cSep											//Qtde de Volumes do Item
									cStrTwo += MOM47NUM(SC6->C6_VALOR,11,2,,lFormat) + cSep										//Valor Total do Item (99999999999,99)
									cStrTwo += MOM47NUM(SC6->C6_I_PTBRU,5,3,,lFormat) + cSep 									//Peso Bruto do Item
									cStrTwo += MOM47NUM(SC6->C6_QTDVEN * SB1->B1_PESO,5,3,,lFormat) + cSep 						//Peso Liquido do Item
									cStrTwo += MOM47NUM(0,11,2,,lFormat) + cSep													//Base da ST do Item
									cStrTwo += MOM47NUM(0,11,2,,lFormat) + cSep													//Icms da St do Item
									cStrTwo += MOM47NUM(0,11,2,,lFormat) + cSep													//Base de Cálculo do ICMS do Item da Nota Fiscal
									cStrTwo += MOM47NUM(0,11,2,,lFormat) + cSep													//Valor do Icms do Item da Nota Fiscal
									cStrTwo += StrZero(Val(SC6->C6_CF),4)+ cSep													//CFOP do Item na NF
									cStrTwo += StrZero(Val(SC6->C6_ITEM),9)+ cSep												//Numero Sequencial dos Volumes
									cStrTwo += Space(957)																		//Espaço em Branco
									
									FSEEK( nHandle,0,2)
									FWrite( nHandle, cStrTwo+CRLF)

									cStrTwo := ""
									SC6->(DBSkip())
								EndDo
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		
		//Verifico se não existe mais pedidos para este operador logistico.
		_nPVporArq:=0
		If nX+1 <= Len(aPedlog)
			
			If aPedlog[nX+1][4]+aPedLog[nX+1][5] == aPedlog[nX][4]+aPedLog[nX][5]
				lControl := .F.
			Else
				lControl := .T.
                _cResultado:=""//Variavel alterada dentro da funcao MOM047GerExcel() tb
		        If cFilant = "90"
				   FClose(nHandle)
				   _lEnvio:=ITENVFTP( aPedLog[nX][6] , aPedLog[nX][7] , aPedLog[nX][8] , aPedLog[nX][9] , cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\" , cNomArq+cExt , aPedLog[nX][10] , !lTela )
		           If _lEnvio
	                  U_ItConOut((_cResultado:="Arquivo enviado p/ FPT: "+cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt))
			       Else
	                  U_ItConOut((_cResultado:="Arquivo NAO enviado p/ FPT: "+cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt))
			       EndIf
		        ElseIf cFilant = "40"
			       _lEnvio:=MOM047GerExcel(aPedLog[nX][11])				
				EndIf
	
				For R := 1 TO Len(_aRecPOS)//Grava para 90 e 40
				    SC5->(DBGoTo( _aRecPOS[R,1] ))
				    SC5->(RecLock("SC5",.F.))
				    SC5->C5_I_PEDOP:= _aRecPOS[R,2] 
				    If _lEnvio
				       SC5->C5_I_EXPOP:="S"
		               SC5->C5_I_ARQOP:=cNomArq+cExt 
					   _nEnviados++
					   _nPVporArq++
				    EndIf	   
				    SC5->(MSUnLock())
				    SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
				    CC2->(DBSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN ))
				    aAdd(aCols, {SC5->C5_FILIAL,; //01
							     SC5->C5_NUM,;    //02
							     If(cFilant="90",cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt,Posicione("SA2",1,xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO,"A2_EMAIL")) ,;     //03
							     aPedLog[nX][10],;//04
							     CC2->CC2_I_OPCO+" "+CC2->CC2_I_OPLO+"-"+Posicione("SA2",1,xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO,"A2_NOME"),;//05
							     SC5->C5_I_PEDOP,;//06
							     _cResultado })//07
				Next R
			    _aRecPOS:={}
			EndIf
		ElseIf Len(aPedlog) > 0
            _cResultado:=""//Variavel alterada dentro da funcao MOM047GerExcel() tb
		    If cFilant = "90"
			   FClose(nHandle)
			   _lEnvio:=ITENVFTP( aPedLog[nX][6] , aPedLog[nX][7] , aPedLog[nX][8] , aPedLog[nX][9] , cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\" , cNomArq+cExt , aPedLog[nX][10] , !lTela )
		       If _lEnvio
	              U_ItConOut((_cResultado:="Arquivo enviado p/ FTP: "+cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt))
			   Else
	              U_ItConOut((_cResultado:="Arquivo NAO enviado p/ FTP: "+cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt))
			   EndIf
		    ElseIf cFilant = "40"
			   _lEnvio:=MOM047GerExcel(aPedLog[nX][11] )
			EndIf
			For R := 1 TO Len(_aRecPOS)//Grava para 90 e 40
			    SC5->(DBGoTo( _aRecPOS[R,1] ))
			    SC5->(RecLock("SC5",.F.))
			    SC5->C5_I_PEDOP:= _aRecPOS[R,2] 
			    If _lEnvio
			       SC5->C5_I_EXPOP:="S"
	               SC5->C5_I_ARQOP:=cNomArq+cExt 
			      _nEnviados++
			      _nPVporArq++
			    EndIf	   
			    SC5->(MSUnLock())
			    SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
			    CC2->(DBSeek(xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN ))
			    aAdd(aCols, {SC5->C5_FILIAL,; //01
						     SC5->C5_NUM,;    //02
						     If(cFilant="90",cArqTemp+aPedLog[nX][4]+aPedLog[nX][5]+"\"+cNomArq+cExt,Posicione("SA2",1,xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO,"A2_EMAIL")) ,;     //03
						     aPedLog[nX][10],;//04
						     CC2->CC2_I_OPCO+" "+CC2->CC2_I_OPLO+"-"+Posicione("SA2",1,xFilial("SA2")+CC2->CC2_I_OPCO+CC2->CC2_I_OPLO,"A2_NOME"),;//05
						     SC5->C5_I_PEDOP,;//06
						     _cResultado })//07 //Variavel alterada dentro da funcao MOM047GerExcel() tb
			Next R
		    _aRecPOS:={}

		EndIf

	Next nX

	If !lTela
	   U_ItConOut("Pedidos processados: "+cValToChar(_nEnviados))
	   RPCClearEnv()
	Else
	    If Len(aCols) > 0
		   aStrAcb:={}		   
		   aAdd(aStrAcb,"Filial")//01
		   aAdd(aStrAcb,"Pedido")//02
		   aAdd(aStrAcb,If(cFilant="90","Arquivo","E-MAIL do Operador Logistico"))//03
		   aAdd(aStrAcb,If(cFilant="90","Diretorio",""))//04
		   aAdd(aStrAcb,"Operador Logistico")//05
		   aAdd(aStrAcb,If(cFilant="90","Pedido do OPL",""))//06
		   aAdd(aStrAcb,"Resultado")//07
		   _cMsgTop := "Pedidos enviados: "+cValToChar(_nEnviados)
		   U_ITListBox( "PEDIDOS PARA EXPORTAR PARA O OPERADOR LOGISTICO" , aStrAcb , aCols , .T. , 1 , _cMsgTop , /*_lSelUnc*/ , /*_aSizes*/ , /*_nCampo*/ , /*bOk*/ , /*bCancel*/, /*aButtons*/ , /*aCampos*/ , /*bDblClk*/ , aCols , /*bCondMarca*/)
		Else
		    U_ITMsg("Nao há pedidos para enviar","Processo finalizado!",,2)
			Return .F.
		EndIf
	EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS47TT
Autor-------------: Jonathan Torioni 
Data da Criacao---: 28/05/2020
Descrição---------: Calcula volume do item
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function MOMS47TT()

	Local nVolume   	:= 0

	If SB1->B1_I_QT3UM > 0
		If AllTrim(SB1->B1_SEGUM) == 'PC' .And. AllTrim(SB1->B1_TIPO) == 'PA'
			If SC6->C6_UNSVEN/SB1->B1_I_QT3UM >= 1 
				nVolume+= SC6->C6_UNSVEN/SB1->B1_I_QT3UM
			Else
				nVolume++
			EndIf	
		Else
			If SC6->C6_QTDVEN/SB1->B1_I_QT3UM >= 1
				nVolume+=SC6->C6_QTDVEN/SB1->B1_I_QT3UM
			Else
				nVolume++
			EndIf
		EndIf
	ElseIf SC6->C6_UNSVEN > 0
		If SC6->C6_UNSVEN >= 1
			nVolume+=SC6->C6_UNSVEN
		Else
			nVolume++
		EndIf
	Else
		If SC6->C6_QTDVEN >= 1
			nVolume+=SC6->C6_QTDVEN
		Else
			nVolume++
		EndIf
	EndIf
Return nVolume


/*
===============================================================================================================================
Programa----------: ITENVFTP
Autor-------------: Jonathan Torioni
Data da Criacao---: 29/05/2020
Descrição---------: Rotina que Processa o envio de arquivos para servidores FTP
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITENVFTP( cServer , nPorta , cUser , cPass , cPath , cArqEnv , cDirFtp , lViaJob )

	Local lRet		:= .F.
	Local lEnvia	:= .T.
	Default cServer	:= ""
	Default nPorta	:= 21
	Default cUser	:= ""
	Default cPass	:= ""
	Default cPath	:= ""
	Default cArqEnv	:= ""
	Default cDirFtp	:= ""
	Default lViaJob	:= .F.

	If Empty(cServer) .Or. Empty(cUser) .Or. Empty(cPass)
		
		If lViaJob
			U_ITCONOUT( "Falha ao identificar os dados para Login no Servidor de FTP." )
		Else
			U_ITMsg("Falha ao identificar os dados para Login no Servidor de FTP","Alerta",,1)
		EndIf
		
		Return lRet
		
	EndIf

	If Empty(cPath) .Or. Empty(cArqEnv)
		
		If lViaJob
			U_ITCONOUT( "Falha ao identificar o diretório de origem e os arquivos a enviar." )
		Else
			U_ITMsg("Falha ao identificar o diretório de origem e os arquivos a enviar.","Alerta",,1)
		EndIf
		
		Return lRet
		
	EndIf

	If FTPConnect( cServer , nPorta , cUser , cPass )

		If !Empty( cDirFtp )
		
			If !FTPDirChange( cDirFtp )
			
				If lViaJob
					U_ITCONOUT( "Não foi possível acessar o diretório no FTP: "+ cDirFtp +CRLF+ "Informe a área de TI/ERP." )
				Else

					U_ITMsg("Não foi possível acessar o diretório no FTP: "+ cDirFtp +CRLF+ "Informe a área de TI/ERP." +  Chr(13) + Chr(10) + Chr(13) + Chr(10)	+;
							"Informe a área de TI/ERP", "Atenção!" ,,1)
		
				EndIf
				
				lEnvia := .F.
				
			EndIf
			
		EndIf
		
		If lEnvia
		
			FTPSetPasv( .T. )
			lRet := .T.
			If !_lAmbTeste .And. !FTPUpLoad( cPath + cArqEnv , cArqEnv )
				//Realiza mais uma tentativa
				If !FTPUpLoad( cPath + cArqEnv , cArqEnv )
					lRet := .F.
					If lViaJob
						U_ITCONOUT( "Não foi possível realizar o upload do arquivo: "+ cPath + cArqEnv+ "verifique se o servidor está liberado para realizar o upload." )
					Else

					U_ITMsg("Não foi possível realizar o upload do arquivo: "+ cPath + cArqEnv, "Falha!" ,"Verifique se o servidor está liberado para realizar o upload no servidor FTP, Server: "+ cServer +":" + cValToChar(nPorta),1)
		
					EndIf
				EndIf
			EndIf
				
		
		EndIf
		
		FTPDISCONNECT()
	Else

		If lViaJob
		   U_ITCONOUT( "Não foi possivel conectar no FTP: FTPConnect( Sever: "+cServer+" , Porta: "+AllTrim(Str(nPorta))+" , User: "+cUser+" , Senha: "+cPass+" )" )
		Else
		   U_ITMsg("Não foi possivel conectar no FTP: FTPConnect( Sever: "+cServer+" , Porta: "+AllTrim(Str(nPorta))+" , User "+cUser+" , Senha: "+cPass+" )","Atenção!",;
				   "Entre em contato com a Area de TI",1)
		EndIf
		Return lRet

	EndIf

Return lRet 

/*
===============================================================================================================================
Programa----------: MOM47NUM
Autor-------------: Jonathan Torioni
Data da Criacao---: 29/05/2020
Descrição---------: Rotina para formatar numéricos
Parametros--------: Nenhum
Retorno-----------: Retorn caracter formatado
===============================================================================================================================
*/
Static Function MOM47NUM(nNum,nInt,nDec,cSep,lFormat)

	Local cPicture		:= "@E "
	Local nY			:= 0
	Local cRet			:= ""

	Default nDec		:= 0
	Default cSep		:= "."
	Default lFormat		:= .T.

	For nY := 1 TO nInt
		cPicture += "9"
	Next nY
	
	cPicture +=cSep

	If nDec > 0
		For nY := 1 TO nDec
			cPicture += "9"
		Next nY
	EndIf

	If !lFormat
		cRet := StrTran(StrTran(TRANSFORM(nNum,cPicture),",","")," ","0")
	Else
		cRet := StrTran(TRANSFORM(nNum,cPicture)," ","0")
	EndIf

Return cRet


/*
===============================================================================================================================
Programa----------: GeraNoPed()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/06/2020
Descrição---------: Rotina para gerar um numero sequencial do pedido do operador logistico
Parametros--------: Nenhum
Retorno-----------: Retorn caracter formatado
===============================================================================================================================
*/
Static Function GeraNoPed()

Local _cPedOP   := "00000001"
Local _lLockX5 	:= .F.
Local _nCnt01  	:= 0

ZP1->( DBSetOrder(2) )
If ZP1->( MsSeek( xFilial('ZP1') + '  ' + "IT_NUMPEDOP" ) )//ZP1_FILPAR em branco para todas as filiais
   _cPedOP:= AllTrim(ZP1->ZP1_CONTEU)
   While !_lLockX5 .And. (++_nCnt01 < 200)
  	  _lLockX5 := ZP1->(RecLock("ZP1",.F.))
   	  If !_lLockX5
   	  	Inkey(1)
   	  EndIf
   EndDo
Else
    ZP1->(RecLock("ZP1",.T.))
    ZP1->ZP1_FILIAL:=xFilial("ZP1")
    ZP1->ZP1_MODULO:="39"
    ZP1->ZP1_GRUPO :="P"
    ZP1->ZP1_ROTINA:="MOMS047"
    ZP1->ZP1_DESROT:="Central de pedidos de venda para varejo"
	//ZP1->ZP1_FILPAR:="  "//Em branco para todas as filiais
    ZP1->ZP1_PARAM :="IT_NUMPEDOP"
    ZP1->ZP1_DESCRI:="Numeracao do Pedido do Operador Logistico"
    ZP1->ZP1_TIPO  :="C"
    ZP1->ZP1_CONTEU:=_cPedOP
    _lLockX5:=.T.
EndIf
If _lLockX5
	_cPedOP:= AllTrim(ZP1->ZP1_CONTEU)
	ZP1->ZP1_CONTEU  := Soma1( _cPedOP, 8 ) 
	ZP1->(MsRUnLock())
Else
    _cPedOP:= Soma1( _cPedOP, 8 ) 
EndIf

Return _cPedOP

/*/
===============================================================================================================================
Programa--------: VerCredito
Autor-----------: Alex Wallauer
Data da Criacao-: 13/05/2021
Descricao-------: Verifica crédito dos pedidos selecionados
Parametros------: cChave - filail + pedido
				  oproc - objeto de processamento
Retorno---------: {_lRet,Mens} - Se passaram ou não na análise de crédito 
===============================================================================================================================
/*/
Static Function VerCredito(cChave, oproc)

Local _lRet := .T.
Local _cChep:= AllTrim(GetMV("IT_CCHEP"))
Local _cBlqCred:=""

SC5->(DBSetOrder(1))
SC6->(DBSetOrder(1))

If oProc <> NIL
   oProc:cCaption := ("Analisando Credito Pedido: "+cChave)
   ProcessMessages()
EndIf

	//Valida crédito do pedido
If SC5->(DBSeek(cChave))

   If  SC5->C5_TIPO = 'N' 
   		_nTotPV:=0
   		_lValCredito:=.T.   
   		SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   		While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC6->(!Eof())	   
   			_nTotPV += SC6->C6_VALOR
   			If SC6->C6_PRODUTO == _cChep .Or. SC6->C6_CF $ '5910/6910/5911/6911'//NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
   				_lValCredito:=.F.
   				Exit
   			EndIf
   			If Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") != 'S' //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA
   				_lValCredito:=.F.
   				Exit
   			EndIf    
   			If Posicione("ZAY",1,xFilial("ZAY")+ SC6->C6_CF ,"ZAY_TPOPER") != 'V' //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
   				_lValCredito:=.F.
   				Exit
   			EndIf      
   			SC6->(DBSkip())  
   		EndDo
   		If _lValCredito
   			_aRetCre := U_ValidaCredito( _nTotPV , SC5->C5_CLIENTE , SC5->C5_LOJACLI , .T. , , , , SC5->C5_MOEDA,,SC5->C5_NUM)
   			_cBlqCred:=_aRetCre[1]
   			SC5->(RecLock("SC5",.F.))	
   			If _aRetCre[2] = "B"//Se bloqueou		   						   				
   				_lBlq2:= .F.
   				If SC5->C5_I_BLCRE # "R"
   				   SC5->C5_I_BLCRE:= "B"
   				EndIf
   				SC5->C5_I_DTAVA := Date()
   				SC5->C5_I_HRAVA := Time()
   				SC5->C5_I_USRAV := cUserName
   				SC5->C5_I_MOTBL := _cBlqCred
   				_lRet := .F. 	
   			EndIf
   			SC5->C5_I_MOTBL := _cBlqCred//Sempre grava a descrição
   			SC5->(MSUnLock())  
   		Else		   		
   			_cBlqCred:="Não necessita de avaliação de crédito"		   		
   		EndIf		   		
   Else		  
      _cBlqCred:="Não necessita de avaliação de crédito"
   EndIf
 EndIf		 

Return "[ *"+_cBlqCred+" ]"

/*
===============================================================================================================================
Programa----------: WFCredito
Autor-------------: Alex Wallauer
Data da Criacao---: 13/05/2021
Descrição---------: Função que executa wf de liberação de PV
Parametros--------: oProc - objeto da regua de processamento
Retorno-----------: _cmsg - status do envio
===============================================================================================================================
*/
Static Function WFCredito(oProc,_cCodigo)

Local _cMsg   := "[ Não foi necessario enviar WF de credito ]"
Local _cBlqCre:= SC5->C5_I_BLCRE
Local _cBlqPre:= SC5->C5_I_BLPRC
Local _cBlqBon:= SC5->C5_I_BLOQ
Local _cOBS:= "Carga do Operador Logistico via arq. CSV - Carga: "+_cCodigo
If Empty(_cCodigo)
   _cOBS:= "Carga do Operador Logistico via arq. CSV - Com Cliente Bloqueado "
EndIf
If _cBlqCre == "R" .Or. _cBlqCre == "B" .or.;
   _cBlqPre == "R" .Or. _cBlqPre == "B" .or.;
   _cBlqBon == "R" .Or. _cBlqBon == "B" 
   If oProc <> NIL
      oProc:cCaption := ("Enviando WF de credito do Pedido: "+SC5->C5_NUM)
      ProcessMessages()
   EndIf
   U_MOMS030W(,_cOBS) //Envia Wfs de liberação necessários 
   _cMsg := "[ WF de credito de pedido enviado com sucesso ]"

EndIf

Return _cMsg

/*
===============================================================================================================================
Programa----------: MOM047GerExcel()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/07/2021
Descrição---------: Gera Excel e envia por e-mail
Parametros--------: _cForn : codigo + loja da OPL
Retorno-----------: _lEnviouEmail
===============================================================================================================================
*/
Static Function MOM047GerExcel(_cForn)

Local _cPathSrv:="\data\Italac\NT\"
Local _cPathLoc:=""//só tela
Local _cArquivo:="PVS_ITALAC_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xlsx"
Local _cFileName:=_cPathSrv+_cArquivo, E
Local _aConfig  := U_ITCFGEML('')
Local _cAssunto :="Pedidos da ITALAC, Filial " + cFilAnt + " - " + AllTrim(SM0->M0_FILIAL)
Local _cEmlLog  :="",_cEmail:="",_nni,_aCab:={} ,_csetor:=""
Local _cEmailEOL:=SuperGetMV("IT_EMAILEO",.F.,"sistema@italac.com.br")//EXPORTA P/ OP LOGISTICO
Local lEnviaPlan:=.T.
Local cEmailCo:=SuperGetMV("IT_EMAICEO",.T.,"")
If Len(_aGerExcel) = 0
   lEnviaPlan:=.F.
   _cForn:=SuperGetMVV("IT_FOEMAVA",.T.,"F260520003")
EndIf

If lEnviaPlan
    //           1        2        3         4         5          6            7               8           9            10         11        12
    aStrAcb:={ "CNPJ","PEDIDO","PRODUTO","QTDE1UM","QTDE2UM","DESCRICAO","CNPJ CLIENTE","NOME CLIENTE","MUNICIPIO","PESO BRUTO","EMISSAO","HORA EMISS"}
    
    For _nni := 1 to Len(aStrAcb)
    	// Alinhamento: 1-Left   ,2-Center,3-Right
    	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
    	//          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    	If _nni = 4 .Or. _nni = 5 .Or. _nni = 10
      	   aAdd(_aCab,{aStrAcb[_nni]     ,3           ,2         ,.F.})
        Else
    	   aAdd(_aCab,{aStrAcb[_nni]     ,1           ,1         ,.F.})
    	EndIf
    Next _nni
    
    //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX)
    U_ITGEREXCEL(_cArquivo,_cPathSrv  ,""      ,          ,_aCab      ,_aGerExcel,           ,          ,        , .T.        ,            ,          , .T.        ,.T.)

EndIf

SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2")+_cForn))
    
_cEmail := AllTrim(SA2->A2_EMAIL) 

If lTela
	If Type('__cUserId') == 'C'
		_cSetor:= FWSFAllUsers({__cUserID},{"USR_DEPTO"})[1][3]
		_cUserName:= FWSFAllUsers({__cUserID},{"USR_NOME"})[1][3] 
		If U_ITMsg("Deseja uma copia de todos os e-mail enviados?",'Atenção!',"Com Copia para o usuario",3,2,2)
			cEmailCo:= FWSFAllUsers({__cUserID},{'USR_EMAIL'})[1][3] 
		EndIf
	EndIf	
Else
   _cUserName:=AllTrim(SM0->M0_NOME)+" - "+AllTrim(SM0->M0_NOMECOM)
EndIf


If Empty(AllTrim(_csetor))
 	_cSetor := "Logistica"
EndIf

cHtml := 'À '+ SA2->A2_NREDUZ +','
cHtml += '<br><br>'
If lEnviaPlan
    cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo planilha de pedidos da nossa filial  '+ cFilAnt + " - " + AllTrim(SM0->M0_FILIAL)+' conforme negociado.<br>'
Else
    cHtml += '&nbsp;&nbsp;&nbsp;Não há pedidos da nossa filial  '+ cFilAnt + " - " + AllTrim(SM0->M0_FILIAL)+' até o momento.<br>'
EndIf	
cHtml += '<br><br>'
cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
cHtml += '<br><br>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml += '<tr>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim(_cUserName ) ) +'</span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=     '</td>'
cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + '(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4) + '</span>'
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=         '</table>'
cHtml +=     '</td>'
cHtml += '</tr>'
cHtml += '</table>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
cHtml +=             '</span>
cHtml +=             '</p>'
cHtml +=         '</td>'
cHtml +=     '</tr>'
cHtml += '</table>'
cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [MOMS047] </BR>'
cHtml +=             '</span>'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
cHtml +=         '</td>'
cHtml +=     '</tr>
cHtml += '</table>'

_cMsgEml:= cHtml

If lEnviaPlan
   cAttach:=_cFileName
   If lTela 
      _cPathLoc:=GetTempPath()//só tela
      If !__CopyFile( _cFileName , _cPathLoc+_cArquivo)
         U_ITMsg("Nao conseguiu copiar o arquivo DE "+_cFileName+" PARA "+_cPathLoc+_cArquivo,;
                'COPIA DE ARQUIVO',;
                "Mas o e-mail será enviado mesmo assim",3)         
      EndIf
   EndIf
Else
   cAttach:=NIL
EndIf

_aEmails:=StrTokArr(_cEmailEOL,";")
aAdd(_aEmails,_cEmail)

For E := 1 TO Len(_aEmails)

    //U_ITENVMAIL(cFrom        ,cEmailTo  ,cEmailCo  ,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
    U_ITENVMAIL( _aConfig[01] ,_aEmails[E],cEmailCo  ,         ,_cAssunto, _cMsgEml ,cAttach,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
    
    _lEnviouEmail := .F.
    If "SUCESSO" $ Upper(_cEmlLog)
       _cResultado+="Envio de E-mail p/: "+_aEmails[E]+" com SUCESSO"+CHR(13)+CHR(10)
       _lEnviouEmail := .T.
    Else
       _cResultado+="NAO Envio o E-mail p/: "+_aEmails[E]+", ERRO: "+_cEmlLog+CHR(13)+CHR(10)
    EndIf
    
    If lTela
        bBloco:=NIL
    	_cBotao:=""
        If !Empty(_cPathLoc) .And. FILE(_cPathLoc+_cArquivo)
              bBloco:={|| ShellExecute("open", _cArquivo, "", _cPathLoc , 1) }
    		  _cBotao:="Com anexo " + LOWER(AllTrim(_cfileName))+CHR(13)+CHR(10)+"Clique em detalhes para ver o anexo"
    	   //EndIf
        EndIf
        U_ITMsg(_cEmlLog+CHR(13)+CHR(10)+'Envio de E-mail P/ '+_aEmails[E],;
                'Resultdo do Envio de E-mail ',;
                _cBotao,3,,,,,,bBloco)
    EndIf

Next E

If lTela .And. !Empty(_cPathLoc) .And. File(_cPathLoc+_cArquivo)
   Ferase(_cPathLoc+_cArquivo)
EndIf

Return _lEnviouEmail
