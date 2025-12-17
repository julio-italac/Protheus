#Include "TOTVS.ch"
#Include 'FINA811.CH'
#Include 'AP5MAIL.CH'
#Include "FWMVCDef.ch"

Static __cMvJurTp	:= NIL
Static __lMulLoj	:= NIL
Static __cRe770F3	:= ''
Static __cArqTrab	:= ''
Static __oFIN8111	:= NIL
Static __oFIN8112	:= NIL
Static __oFIN8113	:= NIL
Static __oFIN8114	:= NIL
Static __oFIN8115	:= NIL

/*
===============================================================================================================================
Programa--------: AFIN030
Autor-----------: Igor Melgaço
Data da Criacao-: 10/03/2022
Descrição-------: Envio de Carta de Cobranca baseado na Rotina FINA811, chamado 38857
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static a811Param := {}

User Function AFIN030( )//nOpcAuto As Numeric , a811Param As Array )
	Local nX			As Numeric
	Local aArea		As Array
	
	//Default nOpcAuto  := 0
	
	Private _aItalac_F3 := {}

	aAdd(_aItalac_F3,{"MV_PAR14"     ,"ZAR"     ,ZAR->(FIELDPOS("ZAR_COD")), ZAR->(FIELDPOS("ZAR_DESC"))  ,          ,          ,          ,           , 0      ,           ,       ,        } )
	
	nX			:= 0
	aArea		:= FWGetArea()
	
	If !TableInDic("FWP") .Or. !TableInDic("FWQ") .Or. !TableInDic("FWS") .Or. !TableInDic("FWT") 
        MsgNextRel()
        Return	
	EndIf	

	If !IsBlind() .And. GetHlpLGPD({"A1_NOME", "E1_NOMCLI"})
		Return .F.
	EndIf
	
	//Encapsulamento da funções que cria o wizard
	U_AF030WIZ(a811Param)

	FWRestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FA811WIZ
Rotina para contrução do wizard de cartas de cobrança

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030WIZ( a811Param as Array )
	Private oStepWiz	As object
	Private o1stPage	As Object
	Private o2ndPage	As Object
	Private o3rdPage	As Object
	Private o4thPage	As Object
	Private o5thPage	As Object
	Private o6thPage	As Object
	Private o7thPage	As Object
	Private aProcesso	As Array
	Private aReport		As Array
	Private cIdCV8		As Character
	Private lSA1Mrk		As Logical
	Private lSE1Mrk		As Logical
	Private nEnvProc	As Numeric
	Private l811Auto	As Logical 

	// Bloco de variáveis utilizado na página 2 / step 2
	Private cCliDe		As Character
	Private cLojaDe		As Character
	Private cCliAte		As Character
	Private cLojaAte	As Character
	Private dDataDe		As Date
	Private dDataAte	As Date
	Private dDtRef		As Date
	Private nValDe		As Numeric
	Private nValAte		As Numeric
	Private cComboFil	As Character
	Private cComboVenc	As Character
	Private cComboConVl	As Character
	Private cSitCob		As Character
	Private aFilial		As Array
	Private cCondCob	As Character
	Private cCodFWP		As Character
	Private cCart       As Character
    Private cRedes      As Character
    Private cExRedes    As Character
	Private cCliBroq    As Character	

	// Bloco de variáveis utilizado na página 3 / step 3
	Private oMrkLayout	As Object
	Private cTrabFWP	As Character

	// Bloco de variáveis utilizado na página 4 / step 4
	Private oMrkClient	As Object
	Private cTrabSA1	As Character

	// Bloco de variáveis utilizado na página 5 / step 5
	Private oMrkTitle
	Private cTrabSE1

	//Inicialização das variáveis
	l811Auto	:= !Empty(a811Param)
	aProcesso	:= {}
	aReport		:= {}
	cIdCV8		:= ''
	lSA1Mrk		:= .F.
	lSE1Mrk		:= .F.
	nEnvProc	:= 0

	If !l811Auto
		cCliDe		:= Space(TamSX3('A1_COD')[1])
		cLojaDe		:= Space(TamSX3('A1_LOJA')[1])
		cCliAte		:= Replicate('Z',TamSX3('A1_COD')[1])
		cLojaAte	:= Replicate('Z',TamSX3('A1_LOJA')[1])
		dDataDe		:= dDataBase - 180
		dDataAte	:= dDataBase + 180
		dDtRef		:= dDataBase
		nValDe		:= 0
		nValAte		:= 0//999999999.99
		cComboFil	:= ''
		cComboVenc	:= ''
		cComboConVl	:= ''
		cSitCob		:= ''
		aFilial		:= {}
		cCondCob	:= ''
		cCart       := Space(50)
        cRedes      := Space(500)
        cExRedes    := Space(500)
		cCliBroq    := ''
	    
	Else
		cCliDe		:= a811Param[01] // Space(TamSX3('A1_COD')[1])
		cLojaDe		:= a811Param[02] // Space(TamSX3('A1_LOJA')[1])
		cCliAte		:= a811Param[03] // Replicate('Z',TamSX3('A1_COD')[1])
		cLojaAte	:= a811Param[04] // Replicate('Z',TamSX3('A1_LOJA')[1])
		dDataDe		:= a811Param[05] // dDataBase - 180
		dDataAte	:= a811Param[06] // dDataBase + 180
		dDtRef		:= a811Param[07] // dDataBase
		nValDe		:= a811Param[08] // 0
		nValAte		:= a811Param[09] // 0
		cComboFil	:= a811Param[10] // ''
		cComboVenc	:= a811Param[11] // ''
		cComboConVl	:= a811Param[12] // ''
		cSitCob		:= a811Param[13] // ''
		aFilial		:= a811Param[14] // {}
		cCondCob	:= a811Param[15] // ''
		cCodFWP		:= a811Param[16] // 'CTE001'
		cCart       := a811Param[17]
        cRedes      := a811Param[18]
        cExRedes    := a811Param[19]
	EndIf

	l811Auto:=.F.

	oStepWiz := FWWizardControl():New(,{600,850})//Instancia a classe FWWizardControl
	oStepWiz:ActiveUISteps()

	If !l811Auto 

		//----------------------
		// Pagina 1
		//----------------------
		o1stPage := oStepWiz:AddStep("1STSTEP",{|Panel| cria_pn1(Panel)}) // Adiciona um Step
		o1stPage:SetStepDescription(STR0001) // Define o título do "step"
		o1stPage:SetNextTitle(STR0002) // Define o título do botão de avançar
		o1stPage:SetNextAction({|| Valid_PG1() }) // Define o bloco ao clicar no botão próximo
		o1stPage:SetCancelAction({|| .T.}) // Define o bloco ao clicar no botão Cancelar

		//----------------------
		// Pagina 2
		//----------------------
		o2ndPage := oStepWiz:AddStep("2NDSTEP", {|Panel| cria_pn2(Panel)})
		o2ndPage:SetStepDescription(STR0003)
		o2ndPage:SetNextTitle(STR0002)
		o2ndPage:SetPrevTitle(STR0004) // Define o título do botão para retorno
		o2ndPage:SetNextAction({|| Valid_PG2()})// Define o bloco ao clicar no botão próximo
		o2ndPage:SetCancelAction({|| .T.})
		o2ndPage:SetPrevAction({|| .T.}) //Define o bloco ao clicar no botão Voltar

		//----------------------
		// Pagina 3
		//----------------------
		o3rdPage := oStepWiz:AddStep("3RDSTEP", {|Panel|cria_pn3(Panel)})
		o3rdPage:SetStepDescription(STR0005)
		o3rdPage:SetNextTitle(STR0002)
		o3rdPage:SetPrevTitle(STR0004)
		o3rdPage:SetNextAction({|| Valid_PG3()})
		o3rdPage:SetPrevAction({|| BackToPg2()})
		o3rdPage:SetCancelAction({|| BtnCancel()})

		//----------------------
		// Pagina 4
		//----------------------
		o4thPage := oStepWiz:AddStep("4THSTEP", {|Panel|cria_pn4(Panel)})
		o4thPage:SetStepDescription(STR0006)
		o4thPage:SetNextTitle(STR0002)
		o4thPage:SetPrevTitle(STR0004)
		o4thPage:SetNextAction({|| Valid_PG4()})
		o4thPage:SetPrevAction({|| BackToPg3()})
		o4thPage:SetCancelAction({|| BtnCancel()})

		//----------------------
		// Pagina 5
		//----------------------
		o5thPage := oStepWiz:AddStep("5THSTEP", {|Panel|cria_pn5(Panel)})
		o5thPage:SetStepDescription(STR0007)
		o5thPage:SetNextTitle(STR0002)
		o5thPage:SetPrevTitle(STR0004)
		o5thPage:SetNextAction({||Valid_PG5()})
		o5thPage:SetPrevAction({|| BackToPg4()})
		o5thPage:SetCancelAction({|| BtnCancel()})

		//----------------------
		// Pagina 6
		//----------------------
		o6thPage := oStepWiz:AddStep("6THSTEP", {|Panel|cria_pn6(Panel)})
		o6thPage:SetStepDescription(STR0008)
		o6thPage:SetNextTitle(STR0002)
		o6thPage:SetPrevTitle(STR0004)
		o6thPage:SetNextAction({|| Valid_PG6()})
		o6thPage:SetPrevAction({||.T.})
		o6thPage:SetCancelAction({|| BtnCancel()})
		o6thPage:SetCancelWhen({||.F.})

		//----------------------
		// Pagina 7
		//----------------------
		o7thPage := oStepWiz:AddStep("7THSTEP", {|Panel|cria_pn7(Panel)})
		o7thPage:SetStepDescription(STR0021)
		o7thPage:SetNextTitle(STR0010)
		o7thPage:SetPrevTitle(STR0004)
		o7thPage:SetNextAction({|| Valid_PG7()})
		o7thPage:SetCancelAction({|| BtnCancel()})
		o7thPage:SetPrevWhen({||.F.})
		o7thPage:SetCancelWhen({||.F.})

		oStepWiz:Activate()

		oStepWiz:Destroy()
	Else
		cria_pn3()
		cria_pn4()
		cria_pn5()
		FIN811AUTO()	
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn1
funções para contrução da primeira página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn1( oPanel As Object )
	Local oFont As Object

	oFont := TFont():New(,,-25,.T.,.T.,,,,,)

	TSay():New(10,15,{|| STR0011},oPanel,,oFont,,,,.T.,CLR_BLUE,)// 'Envio de Cartas de cobrança'
	TSay():New(35,10,{|| STR0012},oPanel,,,,,,.T.,CLR_BLUE,) 	// 'Clique em "próximo" para:'
	TSay():New(45,15,{|| STR0013},oPanel,,,,,,.T.,CLR_BLUE,) 	// '- Definir os parâmetros da rotina;'
	TSay():New(55,15,{|| STR0014},oPanel,,,,,,.T.,CLR_BLUE,) 	// '- Selecionar layouts de Cartas de cobrança;'
	TSay():New(65,15,{|| STR0015},oPanel,,,,,,.T.,CLR_BLUE,) 	// '- Selecionar clientes para evnio;'
	TSay():New(75,15,{|| STR0016},oPanel,,,,,,.T.,CLR_BLUE,) 	// '- Selecionar títulos para envio;'
	TSay():New(85,15,{|| STR0022},oPanel,,,,,,.T.,CLR_BLUE,) 	// '- Efetivar o envio das cartas conforme os dados selecionados.'
	TSay():New(95,10,{|| STR0017},oPanel,,,,,,.T.,CLR_BLUE,) 	// 'Ao final do processo, as cartas serÃ£o enviadas conforme os dados selecionados.'

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn2
funções para contrução da segunda página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn2( oPanel As Object )
	Local aOptions	As Array
	Local aOpConVl	As Array 
	Local aOpBloqu	As Array 
	aOptions := {STR0023,STR0024}
	aOpConVl := {STR0062,STR0063}
    aOpBloqu := {"1-Sim","2-Nao","3-Ambos"}

    _lWhen:={||.F.}
	TSay():New(10,10,{|| STR0025},oPanel,,,,,,.T.,CLR_BLACK,) //
	//[ oWnd],                [ bSetGet], [ nRow], [ nCol], [ nWidth], [ nHeight], [ cPict]          ,bValid,nClrFore,nClrBack,oFont,uParam12,uParam13,lPixel,uParam15],uParam16,bWhen
	TGet():New(10,90,{|u| If( PCount() > 0, cCliDe := u, cCliDe ) } ,oPanel,60,12,X3Picture('A1_COD'),      ,        ,        ,     ,        ,        ,.T.   ,         ,        ,_lWhen,,,,,,'SA1','cCliDe',,,,)

	TSay():New(30,10,{|| STR0026},oPanel,,,,,,.T.,CLR_BLACK,) //  
	TGet():New(30,90,{|u| If( PCount() > 0, cLojaDe := u, cLojaDe ) } ,oPanel,60,12,X3Picture('A1_LOJA'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'cLojaDe',,,,)

	TSay():New(50,10,{|| STR0027},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(50,90,{|u| If( PCount() > 0, cCliAte := u, cCliAte ) } ,oPanel,60,12,X3Picture('A1_COD'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,'SA1','cCliAte',,,,)

	TSay():New(70,10,{|| STR0028},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(70,90,{|u| If( PCount() > 0, cLojaAte := u, cLojaAte ) } ,oPanel,60,12,X3Picture('A1_LOJA'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'cLojaAte',,,,)

	TSay():New(90,10,{|| STR0029},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(90,90,{|u| If( PCount() > 0, dDataDe := u, dDataDe ) } ,oPanel,60,12,,,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'dDataDe',,,,)

	TSay():New(110,10,{|| STR0030},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(110,90,{|u| If( PCount() > 0, dDataAte := u, dDataAte ) } ,oPanel,60,12,,,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'dDataAte',,,,)

	TSay():New(130,10,{|| STR0031},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(130,90,{|u| If( PCount() > 0, nValDe := u, nValDe ) } ,oPanel,60,12,'@E 999,999,999.99',,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'nValDe',,,,)

	TSay():New(150,10,{|| STR0032},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(150,90,{|u| If( PCount() > 0, nValAte := u, nValAte ) } ,oPanel,60,12,'@E 999,999,999.99',,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'nValAte',,,,)

	TSay():New(170,10,{|| STR0037},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(170,90,{|u| If( PCount() > 0, dDtRef := u, dDtRef ) } ,oPanel,60,12,,,,,,,,.T.   ,         ,        ,_lWhen,,,,,,,'dDtRef',,,,)

// *************** LADO DIREITO
	TSay():New(10,200,{|| STR0033},oPanel,,,,,,.T.,CLR_BLACK,) //
	 //[ nRow ], [ nCol ], [ bSetGet ], [ nItens ], [ nWidth ], [ nHeight ],                 [ oWnd ],uParam8 ,bChange,bValid,nClrText,nClrBack,lPixel,oFont,uParam15,uParam16,bWhen
	TComboBox():New(10,280,{|u| If( PCount() > 0, cComboFil := u, cComboFil ) },aOptions,60,12,oPanel,        ,       ,      ,        ,        ,.T.   ,     ,        ,        ,_lWhen,,,,,'cComboFil')

	TSay():New(30,200,{|| STR0034},oPanel,,,,,,.T.,CLR_BLACK,) //
	TComboBox():New(30,280,{|u| If( PCount() > 0, cSitCob := u, cSitCob ) }    ,aOptions,60,12,oPanel,,,,,,.T.   ,         ,        ,,_lWhen,,,,,'cSitCob')

	TSay():New(50,200,{|| STR0035},oPanel,,,,,,.T.,CLR_BLACK,) //
	TComboBox():New(50,280,{|u| If( PCount() > 0, cComboVenc := u, cComboVenc ) },aOptions,60,12,oPanel,,,,,,.T.   ,         ,        ,,_lWhen,,,,,'cComboVenc')

	TSay():New(70,200,{|| "Considera cliente broqueado?" },oPanel,,,,,,.T.,CLR_BLACK,) //
	TComboBox():New(70,280,{|u| If( PCount() > 0, cCliBroq := u, cCliBroq ) },aOpBloqu,60,12,oPanel,,,,,,.T.   ,         ,        ,,_lWhen,,,,,'cCliBroq')

	TSay():New(90,200,{|| STR0061},oPanel,,,,,,.T.,CLR_BLACK,) //
	TComboBox():New(90,280,{|u| If( PCount() > 0, cComboConVl := u, cComboConVl ) },aOpConVl,60,12,oPanel,,,,,,.T.   ,         ,        ,,_lWhen,,,,,'cComboConVl')

	TSay():New(110,200,{|| "Carteira ? (*) Todos"},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(110,280,{|u| If( PCount() > 0, cCart := u, cCart ) } ,oPanel,70,12,X3Picture('E1_I_CART'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,'F3ITLC','cCart',,,,)

	TSay():New(130,200,{|| "Redes ?"},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(130,280,{|u| If( PCount() > 0, cRedes := u, cRedes ) } ,oPanel,70,12,X3Picture('E1_I_CART'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,'REDE50','cRedes',,,,)

	TSay():New(150,200,{|| "Exceto Redes ?"},oPanel,,,,,,.T.,CLR_BLACK,) //
	TGet():New(150,280,{|u| If( PCount() > 0, cExRedes := u, cExRedes ) } ,oPanel,70,12,X3Picture('E1_I_CART'),,,,,,,.T.   ,         ,        ,_lWhen,,,,,,'REDE50','cExRedes',,,,)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn3
funções para contrução da terceira página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn3( oPanel As Object )
	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local aColumns		As Array
	Local nX			As Numeric
	Local cTmpFWPFil	As Character
	Local aSeek			As Array
	Local cArqInd		As Character
	Local cChave		As Character

	aStruct		:= FWP->(DbStruct()) // Carrego a estrutura da tabela de carta de cobrança
	cQuery		:= ''
	cIndex		:= ''
	aColumns	:= {}
	nX			:= 0
	cTmpFWPFil	:= ''
	aSeek		:= {}
	cArqInd		:= ''
	cChave		:= ''

	cIndex := FWP->(IndexKey())

	cQuery += "SELECT * FROM " + RetSqlName('FWP') + " FWP  "
	cQuery += "WHERE FWP.FWP_STATUS = '1' "
	If l811Auto
		cQuery += "AND FWP.FWP_CODCRT = '" + cCodFWP + "' "
	EndIf	
	cQuery += "AND FWP.D_E_L_E_T_ = ' ' "
	cQuery += "ORDER BY "+ SqlOrder(cIndex)

	aAdd(aStruct, {'FWP_OK','C',1,0}) // Adiciono o campo de marca
	If __oFIN8111 <> Nil
		__oFIN8111:Delete()
		__oFIN8111 := Nil
	EndIf

	cTrabFWP := GetNextAlias()

	__oFIN8111 := FWTemporaryTable():New( cTrabFWP )
	__oFIN8111:SetFields(aStruct)
	__oFIN8111:AddIndex("1", {"FWP_DESCRI"})

	//Criação da tabela temporaria
	__oFIN8111:Create()

	If !l811Auto
		MsgRun(STR0066,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabFWP)}) // Cria arquivo temporario
		For nX := 1 To Len(aStruct)
			If	aStruct[nX][1] $ 'FWP_FILIAL|FWP_CODCRT|FWP_DESCRI|FWP_ENVIO'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('FWP',aStruct[nX][1]))
				If aStruct[nX][1] $ 'FWP_ENVIO'
					aColumns[Len(aColumns)]:SetOptions({STR0018,STR0019,STR0020})
				EndIf
			EndIf
		Next nX

		aAdd(aSeek,{STR0060,{{"FWP_DESCRI","C",TamSX3("FWP_DESCRI")[1],0,"",""}},1})

		oMrkLayout:= FWMarkBrowse():New()
		oMrkLayout:oBrowse:SetEditCell(.T.)
		oMrkLayout:oBrowse:SetMainProc("FINA811")
		oMrkLayout:SetFieldMark("FWP_OK")
		oMrkLayout:SetOwner(oPanel)
		oMrkLayout:SetAlias(cTrabFWP)
		oMrkLayout:SetProfileId("0001")
		oMrkLayout:SetAllMark({|| SetMrkAll(1) })
		//oMrkLayout:bAfterMark := {|| oMrkLayout:Refresh()}
		oMrkLayout:SetValid({|| MrkValid()})
		oMrkLayout:SetDescription('')
		oMrkLayout:SetColumns(aColumns)
		oMrkLayout:SetSeek(.T.,aSeek)
		oMrkLayout:Activate()
	Else
		SqlToTrb(cQuery, aStruct, cTrabFWP)
	EndIf

	DBSetOrder(0) // Fica na ordem da query

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn4
funções para contrução da quarta página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn4( oPanel As Object )
	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local aColumns		As Array
	Local aSeek			As Array
	Local nX			As Numeric
	Local cTmpSA1Fil	As Character
	Local aAreaFWP		As Array
	Local cCodCarta		As Character
	Local cFilterSA1	As Character
	Local lF811QRY		As Logical
	Local cQueryAux		As Character

	aStruct		:= SA1->(DbStruct()) // Carrego a estrutura da tabela de cliente
	cQuery		:= ''
	cIndex		:= ''
	aColumns	:= {}
	aSeek		:= {}
	nX			:= 0
	cTmpSA1Fil	:= ''
	aAreaFWP	:= (cTrabFWP)->(GetArea())
	cCodCarta	:= ''
	cFilterSA1	:= ''
	lF811QRY	:= ExistBlock('F811QRY')
	cQueryAux	:= ''

	cIndex := SA1->(IndexKey())

	(cTrabFWP)->(DBGoTop())

	If l811Auto 
		cCodCarta := (cTrabFWP)->FWP_CODCRT
	Else
		While !(cTrabFWP)->(Eof())
			If (cTrabFWP)->FWP_OK == oMrkLayout:cMark
				cCodCarta := (cTrabFWP)->FWP_CODCRT
				Exit
			EndIf
			(cTrabFWP)->(DBSkip())
		EndDo
	EndIf

	FWRestArea(aAreaFWP)

	cQuery += 'SELECT SA1.A1_FILIAL, SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_END, SA1.A1_EMAIL, SA1.A1_VEND, SA1.A1_I_VEND2, SA1.A1_I_VEND3, SA1.A1_I_VEND4 FROM ' + RetSqlName('SA1') + ' SA1 '
    cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
	If !Empty(cCliAte)
	   cQuery += " AND SA1.A1_COD BETWEEN '" + cCliDe + "' AND '" + cCliAte + "' "
	ElseIf !Empty(cCliDe)
	   cQuery += " AND SA1.A1_COD >= '" + cCliDe + "' "
	EndIf
	
	If cCliBroq = "2"
	   cQuery += " AND SA1.A1_MSBLQL <> '1' "
    EndIf

	If !Empty(cLojaAte)
	   cQuery += "AND SA1.A1_LOJA BETWEEN '" + cLojaDe + "' AND '" + cLojaAte + "' "
	ElseIf !Empty(cLojaDe)
	   cQuery += "AND SA1.A1_LOJA >= '" + cLojaDe + "' "
	EndIf
    
	If !Empty(AllTrim(cRedes))
        cQuery += "AND SA1.A1_GRPVEN IN " + FormatIn(AllTrim(cRedes),";")
    EndIf
    If !Empty(AllTrim(cExRedes))
        cQuery += "AND SA1.A1_GRPVEN NOT IN " + FormatIn(AllTrim(cExRedes),";")
    EndIf

	DBSelectArea('FWQ')
	FWQ->(DBSetOrder(1))
	If FWQ->(DBSeek(xFilial('FWQ')+cCodCarta))
		If !Empty(FWQ->FWQ_FILTRA)
			cQuery += "AND " + FWQ->FWQ_FILTRA
		EndIf
	EndIf

	cQuery += "ORDER BY " + SqlOrder(cIndex)

	aAdd(aStruct, {'A1_OK','C',1,0}) // Adiciono o campo de marca

	If __oFIN8112 <> Nil
		__oFIN8112:Delete()
		__oFIN8112 := Nil
	EndIf

	cTrabSA1 := GetNextAlias()

	__oFIN8112 := FWTemporaryTable():New( cTrabSA1 )
	__oFIN8112:SetFields(aStruct)
	__oFIN8112:AddIndex("1",{"A1_COD"})
	__oFIN8112:AddIndex("2",{"A1_NOME"})

	//Criação da tabela temporaria
	__oFIN8112:Create()

	If !l811Auto
		MsgRun(STR0067,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabSA1)}) // Cria arquivo temporario
		For nX := 1 To Len(aStruct)
			If	AllTrim(aStruct[nX][1]) $ 'A1_FILIAL|A1_COD|A1_LOJA|A1_NOME|A1_END|A1_EMAIL|A1_VEND|A1_I_VEND2|A1_I_VEND3|A1_I_VEND4|'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{||'+aStruct[nX][1]+'}') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('SA1',aStruct[nX][1]))
			EndIf
		Next nX

		aAdd(aSeek,{STR0071,{{"A1_COD" ,"C",TamSX3("A1_COD")[1] ,0,"",""}},1})
		aAdd(aSeek,{STR0072,{{"A1_NOME","C",TamSX3("A1_NOME")[1],0,"",""}},2})

		oMrkClient:= FWMarkBrowse():New()
		oMrkClient:oBrowse:SetEditCell(.T.)
		oMrkClient:oBrowse:SetMainProc("FINA811")
		oMrkClient:SetFieldMark("A1_OK")
		oMrkClient:SetOwner(oPanel)
		oMrkClient:SetAlias(cTrabSA1)
		oMrkClient:SetProfileId("0002")
		oMrkClient:SetAllMark({|| MsgRun(STR0073,STR0065,{||SetMrkAll(2)})})
		oMrkClient:SetDescription('')
		oMrkClient:SetColumns(aColumns)
		oMrkClient:SetSeek(.T.,aSeek)
		oMrkClient:Activate()
	Else
		SqlToTrb(cQuery, aStruct, cTrabSA1)
	EndIf

	(cTrabSA1)->(DBSetOrder(1))

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn5
funções para contrução da quinta página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn5( oPanel As Object )
	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local aColumns		As Array
	Local nX			As Numeric
	Local cTmpSE1Fil	As Character
	Local cClients		As Character
	Local cLojas		As Character
	Local aAreaTRB		As Array
	Local cSepNeg  		As Character
	Local cSepProv  	As Character
	Local cSepRec   	As Character
	Local cTmpSA1		As Character
	Local dDtFim		As Date
	Local nTotSE1		As Numeric
	Local lMaxLn		As Logical
	Private dBaixa		As Date

	//Inicialização das variáveis
	aStruct		:= SE1->(DbStruct()) // Carrego a estrutura da tabela de títulos a receber
	cQuery		:= ''
	cIndex		:= ''
	aColumns	:= {}
	nX			:= 0
	cTmpSE1Fil	:= ''
	cClients	:= ''
	cLojas		:= ''
	aAreaTRB	:= (cTrabSA1)->(GetArea())
	cSepNeg  	:= If("|" $ MV_CRNEG,"|",",")
	cSepProv  	:= If("|" $ MVPROVIS,"|",",")
	cSepRec   	:= If("|" $ MVRECANT,"|",",")
	cTmpSA1		:= ""
	dDtFim		:= dDataAte
	nTotSE1		:= 0
	lMaxLn		:= .F.
	dBaixa		:= dDtRef

	If cSitCob == '1' .And. Empty(cCondCob)
		cCondCob := F811GetSit('E1_SITUACA')
	EndIf

	(cTrabSA1)->(DBGoTop())
	If !l811Auto
		MsgRun(STR0068,STR0065,{|| cTmpSA1 := U_AF030TmpCli(cTrabSA1)}) 
	Else 
		U_AF030TmpCli(cTrabSA1)
	EndIf

	FWRestArea(aAreaTRB)

	cIndex := 'E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'

	cQuery += "SELECT * FROM " + RetSqlName('SE1') + " SE1 "

	If cComboFil == "1"
		cQuery += ' WHERE SE1.E1_FILIAL ' + GetRngFil( aFilial, "SE1", .T., @cTmpSE1Fil )
	Else
		cQuery += " WHERE SE1.E1_FILIAL = '" + xFilial('SE1') + "' "
	EndIf

	cQuery += " AND SE1.E1_SALDO > 0 "

	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVABATIM + "|" + MV_CPNEG + "|" + MVTAXA + "|" + MVTXA,"|")
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv)
	cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)
    If Empty(AllTrim(cCart))
        cQuery += " AND E1_I_CART = ' ' "
    ElseIf !Empty(AllTrim(cCart)) .And. AllTrim(cCart) <> "*"
        cQuery += " AND E1_I_CART IN " + FormatIn(AllTrim(cCart),";")
    EndIf

	If cComboVenc == "2"

		Do Case
			Case dDtRef == dDataAte .And. dDataAte > dDataDe
				dDtFim := dDataAte - 1 	//Se a data de referencia For igual a data ate - retroagir 1 dia
			Case dDtRef < dDataAte
				dDtFim := dDtRef		//Data de referencia menor que a data ate - assume a data até
			Case dDtRef > dDataAte
				dDtFim := dDataAte		//Data de referencia maior que a data ate - assume a data de referência
		EndCase

		cQuery += " AND SE1.E1_VENCREA BETWEEN '" + DToS(dDataDe) + "' AND '" + DToS(dDtFim) + "' "
	Else
		cQuery += " AND SE1.E1_VENCREA BETWEEN '" + DToS(dDataDe) + "' AND '" + DToS(IIf(dDtRef > dDataAte,dDtRef,dDataAte)) + "' "
	EndIf

	If !Empty(cCondCob)
		cQuery += " AND SE1." + cCondCob
	EndIf

	cQuery += " AND SE1.E1_SITUACA NOT IN (
	cQuery += "						SELECT FW2_SITUAC FROM " + RetSqlName("FW2") + " WHERE FW2_CODIGO = '0013'
	cQuery += ")"

	If cComboConVl == "1"
	   If nValAte > 0
		  cQuery += " AND SE1.E1_VALOR BETWEEN " + AllTrim(Str(nValDe)) + " AND " + AllTrim(Str(nValAte)) + " "
	   Else
		  cQuery += " AND SE1.E1_VALOR >= " + AllTrim(Str(nValDe)) 
	   EndIf
	Else
	   If nValAte > 0
		  cQuery += " AND SE1.E1_SALDO BETWEEN " + AllTrim(Str(nValDe)) + " AND " + AllTrim(Str(nValAte)) + " "	
	   Else
		  cQuery += " AND SE1.E1_SALDO >= " + AllTrim(Str(nValDe)) 
	   EndIf
	EndIf

	cQuery += " AND (SE1.E1_CLIENTE || SE1.E1_LOJA IN (SELECT SA1T.CLIENTE FROM " + __oFIN8115:GetRealname() + " SA1T ) ) "

	cQuery += " AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY "+ SqlOrder(cIndex)

	cQuery := ChangeQuery(cQuery)

	aAdd(aStruct, {'E1_MRK','C',1,0}) // Adiciono o campo de marca
	aAdd(aStruct, {'DIASATRASO','C',4,0}) // Coluna 'Dias em Atraso'

	cTrabSE1 := GetNextAlias()
	If __oFIN8113 <> Nil
		__oFIN8113:Delete()
		__oFIN8113	:= Nil
	EndIf

	__oFIN8113 := FwTemporaryTable():New(cTrabSE1)

	__oFIN8113:SetFields(aStruct)

	__oFIN8113:AddIndex("1", {"E1_FILIAL","E1_CLIENTE","E1_LOJA","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO"})
	__oFIN8113:AddIndex("2", {"E1_CLIENTE","E1_LOJA"})

	//Criando a Tabela Temporaria
	__oFIN8113:Create()

	If !l811Auto
		MsgRun(STR0068,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabSE1)}) // Cria arquivo temporario
	Else
		SqlToTrb(cQuery, aStruct, cTrabSE1)
	EndIf
	
	DBSetOrder(0) // Fica na ordem da query

	//Faz uma contagem de titulos por conta do maximo de linhas do MVC
	COUNT TO nTotSE1

	If nTotSE1 > 9990
		lMaxLn := .T.
	EndIf

	//Reprocesso a tabela, atualizando o saldo de cada título, considerando abatimentos
	If !lMaxLn
		If !l811Auto
			MsgRun(STR0069,STR0065,{|| U_AF030AtuTrb()})
		Else
			U_AF030AtuTrb()
		EndIf
	EndIf
	
	//Filtro especifico para selecao por saldo que necessita primeiro a   
	//atualizacao da tabela temporaria realizada pela funcao F811AtuTrb
	If cComboConVl == "2"
		cFiltro	:= 'E1_SALDO >= ' + AllTrim(Str(nValDe)) + ' .And. E1_SALDO <= ' + AllTrim(Str(nValAte))
	Else
		cFiltro	:= 'E1_VALOR >= ' + AllTrim(Str(nValDe)) + ' .And. E1_VALOR <= ' + AllTrim(Str(nValAte))
	EndIf

	If !l811Auto
		For nX := 1 To Len(aStruct)
			If	aStruct[nX][1] $ 'E1_FILIAL|E1_FILORIG|E1_NUM|E1_PREFIXO|E1_PARCELA|E1_TIPO|E1_NOMCLI|E1_CLIENTE|E1_LOJA|E1_VALOR|E1_VENCREA'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{||' + aStruct[nX][1] + '}') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('SE1',aStruct[nX][1]))
				If AllTrim(aStruct[nX][1]) == "E1_VALOR"
					aColumns[Len(aColumns)]:SetType("N")
				ElseIf AllTrim(aStruct[nX][1]) == "E1_VENCREA"
					aColumns[Len(aColumns)]:SetType("D")
				Else
					aColumns[Len(aColumns)]:SetType("C")
				EndIf
			ElseIf AllTrim(aStruct[nX][1]) == 'E1_JUROS'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{|| U_AF030TitJur(cTrabSE1) }') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('SE1',aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetType("N")
			ElseIf AllTrim(aStruct[nX][1]) == 'E1_MULTA'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{|| U_AF030RMul(E1_VALOR,E1_SALDO,E1_VENCREA,dDtRef ) }') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('SE1',aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetType("N")
			ElseIf AllTrim(aStruct[nX][1]) == 'E1_SALDO'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{|| E1_SALDO }') )
				aColumns[Len(aColumns)]:SetTitle(RetTitle(aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture(PesqPict('SE1',aStruct[nX][1]))
				aColumns[Len(aColumns)]:SetType("N")
			ElseIf aStruct[nX][1] == 'DIASATRASO'
				aAdd(aColumns,FWBrwColumn():New())
				aColumns[Len(aColumns)]:SetData( &('{|| dDtRef - E1_VENCREA}') )
				aColumns[Len(aColumns)]:SetTitle(STR0046)
				aColumns[Len(aColumns)]:SetSize(aStruct[nX][3])
				aColumns[Len(aColumns)]:SetDecimal(aStruct[nX][4])
				aColumns[Len(aColumns)]:SetPicture('@!')
				aColumns[Len(aColumns)]:SetType("N")
			EndIf
		Next nX

		oMrkTitle:= FWMarkBrowse():New()
		oMrkTitle:AddLegend({|| (dDtRef - E1_VENCREA) > 0},"BLACK",STR0056)
		oMrkTitle:AddLegend({|| (dDtRef - E1_VENCREA) <= 0},"WHITE",STR0057)

		oMrkTitle:SetColumns(aColumns)
		oMrkTitle:oBrowse:SetEditCell(.T.)
		oMrkTitle:oBrowse:SetMainProc("FINA811")
		oMrkTitle:SetFieldMark("E1_MRK")
		oMrkTitle:SetOwner(oPanel)
		oMrkTitle:SetAlias(cTrabSE1)
		oMrkTitle:SetProfileId("0003")
		oMrkTitle:SetAllMark({|| MsgRun(STR0074,STR0065,{||SetMrkAll(3)})})
		oMrkTitle:SetDescription('')
		oMrkTitle:Activate()

		If (cTrabSE1)->(Eof()) //Caso não hajam títulos para o(s) cliente(s) selecionado(s)
			Help(,,"F811NOCLI",,STR0064,1,0)
			oStepWiz:PreviousPage()
		ElseIf lMaxLn
			Help(,,"F811MAXT",,STR0076,1,0)
			oStepWiz:PreviousPage()
		EndIf
	EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn6
funções para contrução da sexta página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn6( oPanel As Object )
	Local oFont As Object

	oFont := TFont():New(,,-25,.T.,.T.,,,,,)

	TSay():New(10,15,{|| STR0011},oPanel,,oFont,,,,.T.,CLR_BLUE,) // 'Envio de Cartas de cobrança'
	TSay():New(35,10,{|| STR0049},oPanel,,,,,,.T.,CLR_BLUE,) // 'Clique em "próximo" para efetivar o envio das cartas de cobrança conforme os parâmetros selecionados anteriormente.'

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cria_pn7
funções para contrução da sétima página do wizard

@param oPanel 

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function cria_pn7( oPanel As Object )
	Local oBtnLog	As Object
	Local oFont		As Object

	oFont := TFont():New(,,-25,.T.,.T.,,,,,)

	// Apresenta o tSay com a fonte Courier New
	TSay():New(10,15,{|| STR0038},oPanel,,oFont,,,,.T.,CLR_BLUE,)
	TSay():New(35,10,{|| STR0039},oPanel,,,,,,.T.,CLR_BLUE,)

	oBtnLog := TButton():New(180,330, STR0040,oPanel,{||ProcLogView(cFilAnt,'FINA811Proc',,cIdCV8 )}, 60,20,,,.F.,.T.,.F.,,.F.,,,.F. )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG2
funções para seção da segunda página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG2() As Logical

	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local cTmpFWPFil	As Character
	Local aSeek			As Array
	Local cArqInd		As Character
	Local cChave		As Character
	Local lCont			As Logical

	aStruct		:= FWP->(DbStruct()) // Carrego a estrutura da tabela de carta de cobrança
	cQuery		:= ''
	cIndex		:= ''
	cTmpFWPFil	:= ''
	aSeek		:= {}
	cArqInd		:= ''
	cChave		:= ''

	//Seleciona filiais
	If cComboFil == "1"
		aFilial := AdmGetFil()
		If Len(aFilial) = 0
		   cComboFil:= "2"
		EndIf
	EndIf

	If l811Auto
		lCont := .T.
	Else
		lCont := o3rdPage:lConstructed
	EndIf

	If lCont
		cIndex := FWP->(IndexKey())
	
		cQuery += "SELECT * FROM " + RetSqlName('FWP') + " FWP "
		cQuery += "WHERE FWP.FWP_STATUS = '1' "

		If l811Auto
			cQuery += "AND FWP.FWP_CODCRT = '" + cCodFWP + "' "
		EndIf

		cQuery += "AND FWP.D_E_L_E_T_ = ' ' "
		cQuery += "ORDER BY "+ SqlOrder(cIndex)

		aAdd(aStruct, {'FWP_OK','C',1,0}) // Adiciono o campo de marca

		If __oFIN8111 <> Nil
			__oFIN8111:Delete()
			__oFIN8111 := Nil
		EndIf

		cTrabFWP := GetNextAlias()
				
		__oFIN8111 := FWTemporaryTable():New( cTrabFWP )
		__oFIN8111:SetFields(aStruct)
		__oFIN8111:AddIndex("1", {"FWP_DESCRI"})

		//Criação da tabela temporaria
		__oFIN8111:Create()

		If !l811Auto // se a rotina foi chamada pelo menu

			MsgRun(STR0066,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabFWP)}) // Cria arquivo temporario

			DBSetOrder(0) // Fica na ordem da query

			aAdd(aSeek,{STR0060,{{"FWP_DESCRI","C",TamSX3("FWP_DESCRI")[1],0,"",""}},1})

			oMrkLayout:SetAlias(cTrabFWP)
			oMrkLayout:SetProfileId("0004")
			oMrkLayout:oBrowse:cProfileId := cTrabFWP
			oMrkLayout:oBrowse:SetMainProc("FINA811")
			oMrkLayout:GoTop(.T.)
			oMrkLayout:SetSeek(.T.,aSeek)
			oMrkLayout:Refresh()
			oMrkLayout:oBrowse:SetFocus()

		Else	// se a rotina foi chamada pela automação de testes

			SqlToTrb(cQuery, aStruct, cTrabFWP)
			DBSetOrder(0) // Fica na ordem da query

		EndIf 

	EndIf

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG3
funções para seção da terceira página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG3() As Logical
	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local cTmpSA1Fil	As Character
	Local aAreaFWP		As Array
	Local cCodCarta		As Character
	Local cFilterSA1	As Character
	Local lLoop			As Logical
	Local lF811QRY		As Logical
	Local cQueryAux		As Character
	Local aSeek			As Array
	Local lCont			As Logical

	aStruct		:= SA1->(DbStruct()) // Carrego a estrutura da tabela de carta de cobrança
	cQuery		:= ''
	cIndex		:= ''
	cTmpSA1Fil	:= ''
	aAreaFWP	:= (cTrabFWP)->(GetArea())
	cCodCarta	:= ''
	cFilterSA1	:= ''
	lLoop		:= .F.
	lF811QRY	:= ExistBlock('F811QRY')
	cQueryAux	:= ''
	aSeek		:= {}

	(cTrabFWP)->(DBGoTop())

	If !l811Auto
		While !(cTrabFWP)->(Eof())
			If !Empty((cTrabFWP)->FWP_OK)
				lLoop := .T.
				Exit
			EndIf
			
			(cTrabFWP)->(DBSkip())
		EndDo

		If !lLoop
			MsgAlert(STR0041,STR0011)
			FWRestArea(aAreaFWP)
			Return .F.
		EndIf

		lCont := o4thPage:lConstructed

	Else
		lCont := .T.
	EndIf

	If lCont

		cIndex := SA1->(IndexKey())

		(cTrabFWP)->(DBGoTop())

		If l811Auto
			cCodCarta := (cTrabFWP)->FWP_CODCRT
		Else
			While !(cTrabFWP)->(Eof())
				If (cTrabFWP)->FWP_OK == oMrkLayout:cMark
					cCodCarta := (cTrabFWP)->FWP_CODCRT
					Exit
				EndIf
				(cTrabFWP)->(DBSkip())
			EndDo
		EndIf

		FWRestArea(aAreaFWP)

		cQuery += 'SELECT SA1.A1_FILIAL, SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_END, SA1.A1_EMAIL FROM ' + RetSqlName('SA1') + ' SA1 '
		cQuery += "	WHERE SA1.D_E_L_E_T_ = ' ' "

	    If !Empty(cCliAte)
	       cQuery += " AND SA1.A1_COD BETWEEN '" + cCliDe + "' AND '" + cCliAte + "' "
	    ElseIf !Empty(cCliDe)
	       cQuery += " AND SA1.A1_COD >= '" + cCliDe + "' "
	    EndIf
	    If !Empty(cLojaAte)
	       cQuery += "AND SA1.A1_LOJA BETWEEN '" + cLojaDe + "' AND '" + cLojaAte + "' "
	    ElseIf !Empty(cLojaDe)
	       cQuery += "AND SA1.A1_LOJA >= '" + cLojaDe + "' "
	    EndIf

	    If cCliBroq = "2"
	       cQuery += "AND SA1.A1_MSBLQL <> '1' "
        EndIf

		DBSelectArea('FWQ')
		FWQ->(DBSetOrder(1))
		If FWQ->(DBSeek(xFilial('FWQ')+cCodCarta))
			If !Empty(FWQ->FWQ_FILTRA)
				cQuery += "AND " + FWQ->FWQ_FILTRA
			EndIf
		EndIf

		If lF811QRY
			cQryAux := ExecBlock('F811QRY',.F.,.F.)
			If !Empty(cQryAux)
				cQuery += " AND " + cQryAux
			EndIf
		EndIf

		cQuery += "ORDER BY "+ SqlOrder(cIndex)
	
		aAdd(aStruct, {'A1_OK','C',1,0}) // Adiciono o campo de marca

		If __oFIN8112 <> Nil
			__oFIN8112:Delete()
			__oFIN8112 := Nil
		EndIf

		cTrabSA1 := GetNextAlias()
				
		__oFIN8112 := FWTemporaryTable():New( cTrabSA1 )
		__oFIN8112:SetFields(aStruct)
		__oFIN8112:AddIndex("1",{"A1_COD"})
		__oFIN8112:AddIndex("2",{"A1_NOME"})

		//Criação da tabela temporaria-
		__oFIN8112:Create()

		If !l811Auto
			MsgRun(STR0067,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabSA1)}) // Cria arquivo temporario
		Else
			SqlToTrb(cQuery, aStruct, cTrabSA1) 
		EndIf

		(cTrabSA1)->(DBSetOrder(1))

		aAdd(aSeek,{STR0071,{{"A1_COD" ,"C",TamSX3("A1_COD")[1] ,0,"",""}},1})
		aAdd(aSeek,{STR0072,{{"A1_NOME","C",TamSX3("A1_NOME")[1],0,"",""}},2})

		lSA1Mrk := .F.

		If !l811Auto
			oMrkClient:SetAlias(cTrabSA1)
			oMrkClient:SetProfileId("0005")
			oMrkClient:oBrowse:cProfileId := cTrabSA1
			oMrkClient:oBrowse:SetMainProc("FINA811")
			oMrkClient:GoTop(.T.)
			oMrkClient:SetSeek(.T.,aSeek)
			oMrkClient:Refresh()
			oMrkClient:oBrowse:SetFocus()
		EndIf

	EndIf

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG4
funções para seção da quarta página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG4() As Logical
	Local aStruct		As Array
	Local cQuery		As Character
	Local cIndex		As Character
	Local nX			As Numeric
	Local cTmpSE1Fil	As Character
	Local cClients		As Character
	Local cLojas		As Character
	Local aAreaTRB		As Array
	Local lLoop			As Logical
	Local cSepNeg   	As Character
	Local cSepProv  	As Character
	Local cSepRec   	As Character
	Local cTmpSA1		As Character
	Local dDtFim		As Date
	Local nTotSE1		As Numeric

	aStruct		:= SE1->(DbStruct()) // Carrego a estrutura da tabela de carta de cobrança
	cQuery		:= ''
	cIndex		:= ''
	nX			:= 0
	cTmpSE1Fil	:= ''
	cClients	:= ''
	cLojas		:= ''
	aAreaTRB	:= (cTrabSA1)->(GetArea())
	lLoop		:= .F.
	cSepNeg   	:= If("|"$MV_CRNEG,"|",",")
	cSepProv  	:= If("|"$MVPROVIS,"|",",")
	cSepRec   	:= If("|"$MVRECANT,"|",",")
	cTmpSA1		:= ""
	dDtFim		:= dDataAte
	nTotSE1		:= 0

	If cSitCob == '1' .And. Empty(cCondCob)
		cCondCob	:= F811GetSit('E1_SITUACA')
	EndIf

	(cTrabSA1)->(DBGoTop())

	While !(cTrabSA1)->(Eof())
		If !Empty((cTrabSA1)->A1_OK)
			lLoop := .T.
			Exit
		EndIf
	
		(cTrabSA1)->(DBSkip())
	EndDo

	FWRestArea(aAreaTRB)

	If !lLoop
		If !l811Auto
			MsgAlert(STR0042,STR0011)
		EndIf
		Return .F.
	EndIf

	If ( o5thPage:lConstructed .And. !l811Auto ) .Or. l811Auto 
		(cTrabSA1)->(DBGoTop())
	
		If !l811Auto
			MsgRun(STR0068,STR0065,{|| cTmpSA1 := U_AF030TmpCli(cTrabSA1)})
		Else
			cTmpSA1 := U_AF030TmpCli(cTrabSA1)
		EndIf

		FWRestArea(aAreaTRB)

		cIndex := 'E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO'

		cQuery += "SELECT * FROM " + RetSqlName('SE1') + " SE1 "

		If cComboFil == "1"
			cQuery += ' WHERE SE1.E1_FILIAL ' + GetRngFil( aFilial, "SE1", .T., @cTmpSE1Fil )
		Else
			cQuery += " WHERE SE1.E1_FILIAL = '" + xFilial('SE1') + "' "
		EndIf

		cQuery += " AND SE1.E1_SALDO > 0 "

		cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVABATIM + "|" + MV_CPNEG + "|" + MVTAXA + "|" + MVTXA,"|")
		cQuery += " AND E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)
		cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv)
		cQuery += " AND E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)

		If cComboVenc == "2"

			Do Case
			Case dDtRef == dDataAte .And. dDataAte > dDataDe
				dDtFim := dDataAte - 1 	//Se a data de referencia For igual a data ate - retroagir 1 dia
			Case dDtRef < dDataAte
				dDtFim := dDtRef		//Data de referencia menor que a data ate - assume a data até
			Case dDtRef > dDataAte
				dDtFim := dDataAte		//Data de referencia maior que a data ate - assume a data de referência
			EndCase

			cQuery += " AND SE1.E1_VENCREA BETWEEN '" + DToS(dDataDe) + "' AND '" + DToS(dDtFim) + "' "
		Else
			cQuery += " AND SE1.E1_VENCREA BETWEEN '" + DToS(dDataDe) + "' AND '" + DToS(IIf(dDtRef > dDataAte,dDtRef,dDataAte)) + "' "
		EndIf
		
		If !Empty(cCondCob)
			cQuery += " AND SE1." + cCondCob
		EndIf

		cQuery += " AND SE1.E1_SITUACA NOT IN ( "
		cQuery += "						SELECT FW2_SITUAC FROM " + RetSqlName("FW2") + " WHERE FW2_CODIGO = '0013' "
		cQuery += ")"

		If cComboConVl == "1"
			cQuery += " AND SE1.E1_VALOR BETWEEN " + AllTrim(Str(nValDe)) + " AND " + AllTrim(Str(nValAte)) + " "
		Else
			cQuery += " AND SE1.E1_SALDO BETWEEN " + AllTrim(Str(nValDe)) + " AND " + AllTrim(Str(nValAte)) + " "	
		EndIf

		cQuery += " AND (SE1.E1_CLIENTE || SE1.E1_LOJA IN (SELECT SA1T.CLIENTE FROM " + __oFIN8115:GetRealname() + " SA1T ) ) "

		cQuery += " AND SE1.D_E_L_E_T_ = ' ' "
		cQuery += " ORDER BY "+ SqlOrder(cIndex)

		cQuery := ChangeQuery(cQuery)

		aAdd(aStruct, {'E1_MRK','C',1,0}) // Adiciono o campo de marca
		aAdd(aStruct, {'DIASATRASO','C',4,0}) // Coluna 'Dias em Atraso'

		cTrabSE1 := GetNextAlias()
		If __oFIN8113 <> Nil
			__oFIN8113:Delete()
			__oFIN8113	:= Nil
		EndIf

		__oFIN8113 := FwTemporaryTable():New(cTrabSE1)

		__oFIN8113:SetFields(aStruct)

		__oFIN8113:AddIndex("1", {"E1_FILIAL","E1_CLIENTE","E1_LOJA","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO"})
		__oFIN8113:AddIndex("2", {"E1_CLIENTE","E1_LOJA"})

		//Criando a Tabela Temporaria
		__oFIN8113:Create()

		If !l811Auto
			MsgRun(STR0068,STR0065,{||SqlToTrb(cQuery, aStruct, cTrabSE1)}) // Cria arquivo temporario
		Else
			SqlToTrb(cQuery, aStruct, cTrabSE1)
		EndIf

		DBSetOrder(0) // Fica na ordem da query

		//Faz uma contagem de titulos por conta do maximo de linhas do MVC
		COUNT TO nTotSE1

		If nTotSE1 > 9990 
			If !l811Auto
				Help(,,"F811MAXT",,STR0076,1,0)
			EndIf
			Return 
		EndIf

		//Reprocesso a tabela, atualizando o saldo de cada título, considerando abatimentos
		If !l811Auto
			MsgRun(STR0069,STR0065,{|| U_AF030AtuTrb()})
		Else
			U_AF030AtuTrb()
		EndIf

		//Filtro especifico para selecao por saldo que necessita primeiro a   
		//atualizacao da tabela temporaria realizada pela funcao F811AtuTrb
		If cComboConVl == "2"
			cFiltro	:= 'E1_SALDO >= ' + AllTrim(Str(nValDe)) + ' .And. E1_SALDO <= ' + AllTrim(Str(nValAte))
		Else
			cFiltro	:= 'E1_VALOR >= ' + AllTrim(Str(nValDe)) + ' .And. E1_VALOR <= ' + AllTrim(Str(nValAte))
		EndIf

		lSE1Mrk := .F.

		If !l811Auto
			oMrkTitle:SetAlias(cTrabSE1)
			oMrkTitle:SetProfileId("0006")

			oMrkTitle:oBrowse:cProfileId := cTrabSE1
			oMrkTitle:oBrowse:SetMainProc("FINA811")

			oMrkTitle:GoTop(.T.)

			oMrkTitle:Refresh()
			oMrkTitle:oBrowse:Refresh()
			oMrkTitle:oBrowse:SetFocus()

			If (cTrabSE1)->(Eof()) //Caso não hajam títulos para o(s) cliente(s) selecionado(s)
				Help(,,"F811NOCLI",,STR0064,1,0)
				oStepWiz:PreviousPage()
			EndIf
			
		EndIf
	EndIf

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG5
funções para seção da quinta página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG5() As Logical
	Local aAreaTRB	As Array
	Local lLoop		As Logical
	Local lRet		As Logical

	aAreaTRB	:= (cTrabSE1)->(GetArea())
	lLoop		:= .F.
	lRet		:= .T.

	If Select(cTrabSE1) <= 0
		MsgAlert(STR0043,STR0011)
		lRet := .F.
	EndIf

	If lRet
		(cTrabSE1)->(DBGoTop())

		While !(cTrabSE1)->(Eof()) .And. lRet
			If !Empty((cTrabSE1)->E1_MRK)
				lLoop := .T.
				Exit
			EndIf
			
			(cTrabSE1)->(DBSkip())
		EndDo

		FWRestArea(aAreaTRB)

		If !lLoop
			MsgAlert(STR0044,STR0011)
			lRet := .F.
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG6
funções para seção da sexta página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG6() As Logical

	MsgRun(STR0070,STR0065,{|| F811GrvFWT()})

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Valid_PG7
funções para seção da sétima página do wizard

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function Valid_PG7() As Logical

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} BackToPg2
funções para seção do retorno da página 3 para página 2

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function BackToPg2() As Logical

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} BackToPg3
funções para seção do retorno da página 4 para página 3

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function BackToPg3() As Logical

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} BackToPg4
funções para seção do retorno da página 5 para página 4

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function BackToPg4() As Logical

	cCondCob := ''

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} BtnCancel
funções para seção do botão cancelar

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function BtnCancel() As Logical
	Local lRet As Logical

	lRet := MsgYesNo(STR0045,STR0011)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} MrkValid
funções para execução do valid da MarkBrowse

@author Pedro Lima
@since  29/07/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function MrkValid() As Logical
	Local cCodCrt	As Character
	Local aAreaFWP	As Array

	cCodCrt		:= (cTrabFWP)->FWP_CODCRT
	aAreaFWP	:= (cTrabFWP)->(GetArea())

	(cTrabFWP)->(DBGoTop())

	While !(cTrabFWP)->(Eof())
		If (cTrabFWP)->FWP_CODCRT != cCodCrt
			(cTrabFWP)->FWP_OK := ''
		EndIf
		(cTrabFWP)->(DBSkip())
	EndDo

	FWRestArea(aAreaFWP)
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Cria a estrutura a ser usada no Modelo de Dados

@author Pedro Pereira Lima
@since 04/09/2015
@version 12.1.7
/*/

//-------------------------------------------------------------------
Static Function ModelDef() As Object
	Local oModel	As Object
	Local oMaster	As Object
	Local oStruFWT	As Object

	oModel		:= MPFormModel():New('FINA811',/*PreValidacao*/,/*{|oModel| FINM030Pos(oModel)}*/,/*{|oModel| FINM030Grv(oModel)}*/,/*bCancel*/ )
	oMaster		:= FWFormModelStruct():New()
	oStruFWT	:= FWFormStruct(1,'FWT', /*bAvalCampo*/, /*lViewUsado*/ ) //Cartas Enviadas

	oMaster:AddTable('FWP',,'MASTER')

	// Crio o campo virtual para armazenar o código da carta e posteriormente gravar na tabela FWP
	oMaster:AddField('CODCARTA','','CODCARTA','C',TamSX3('FWP_CODCRT')[1],0,/*bValid*/,/*When*/,/*aValues*/,.F.,{||""},/*Key*/,.F.,.T.,)

	// Cria os modelos relacionados
	oModel:AddFields('MASTER',/*cOwner*/,oMaster,,,{|o|{}})
	oModel:AddGrid('FWTDETAIL','MASTER',oStruFWT)

	oModel:SetRelation('FWTDETAIL', {{'FWT_FILIAL', 'xFilial("FWT")'}, {'FWT_LAYOUT', 'CODCARTA'}} , FWT->(IndexKey(1)) ) 

	oStruFWT:SetProperty('FWT_LAYOUT',MODEL_FIELD_OBRIGAT,.F.)
	oStruFWT:SetProperty('FWT_DTENVI',MODEL_FIELD_OBRIGAT,.F.)
	oStruFWT:SetProperty('FWT_CHAVE' ,MODEL_FIELD_OBRIGAT,.F.)
	oStruFWT:SetProperty('FWT_PROCES',MODEL_FIELD_OBRIGAT,.F.)
	oStruFWT:SetProperty('FWT_DTREFE',MODEL_FIELD_OBRIGAT,.F.)

	oModel:SetPrimaryKey( {} )
	oModel:GetModel('FWTDETAIL'):SetMaxLine(9990)
	oModel:GetModel('MASTER'):SetOnlyQuery(.T.)

Return oModel


//-------------------------------------------------------------------
/*/{Protheus.doc} F811GrvFWT()
Faz a gravseção da tabela FWT com base nos registros selecionados
nas Markbrowses

@author Pedro Pereira Lima
@since 04/09/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function F811GrvFWT() As Logical
	Local oModelFWT		As Object
	Local oSubFWT		As Object
	Local cCodCarta		As Character
	Local cChaveFK7		As Character
	Local cProcess		As Character
	Local nProcesso		As Numeric
	Local aAreaTRBFWP	As Array
	Local aAreaTRBSA1	As Array
	Local aAreaTRBSE1	As Array
	Local cChaveCli		As Character
	Local cChaveTit		As Character
	Local nOrder		As Numeric
	Local lCliOk		As Logical
	Local lTitOk		As Logical
	Local lEmitSA1		As Logical

	oModelFWT	:= FwLoadModel('FINA811') // Model de gravseção da FWT
	oSubFWT		:= Nil
	cCodCarta	:= ''
	cChaveFK7	:= ''
	cProcess	:= ''
	nProcesso	:= 0
	aAreaTRBFWP	:= (cTrabFWP)->(GetArea())
	aAreaTRBSA1	:= (cTrabSA1)->(GetArea())
	aAreaTRBSE1	:= (cTrabSE1)->(GetArea())
	cChaveCli	:= ""
	cChaveTit	:= ""
	nOrder		:= 0
	lEmitSA1	:= .T.

	//Carrego model de gravseção da FWT
	oModelFWT:SetOperation(MODEL_OPERATION_INSERT) //Inclusao
	oModelFWT:Activate()

	(cTrabFWP)->(DBGoTop())

	If l811Auto
		cCodCarta := (cTrabFWP)->FWP_CODCRT
		cFilLayout:= (cTrabFWP)->FWP_FILIAL
	Else
		While !(cTrabFWP)->(Eof())
			If (cTrabFWP)->FWP_OK == oMrkLayout:cMark
				cCodCarta := (cTrabFWP)->FWP_CODCRT
				cFilLayout:= (cTrabFWP)->FWP_FILIAL
				Exit
			EndIf
			(cTrabFWP)->(DBSkip())
		EndDo
	EndIf

	oModelFWT:SetValue('MASTER','CODCARTA',cCodCarta)

	// Gravseção do 'SubModel'
	oSubFWT	:= oModelFWT:GetModel('FWTDETAIL')

	//Verifica a ordem de busca na SE1 pelo compartilhamento
	If (FWModeAccess('SA1',1) == 'E' .And. FWModeAccess('SA1',2) == 'E' .And. FWModeAccess('SA1',3) == 'E') .And.;
			(FWModeAccess('SE1',1) == 'E' .And. FWModeAccess('SE1',2) == 'E' .And. FWModeAccess('SE1',3) == 'E')
		//Totalmente exclusivo
		nOrder 		:= 1
		cChaveCli	:= "(cTrabSA1)->(A1_FILIAL + A1_COD + A1_LOJA)"
		cChaveTit	:= "(cTrabSE1)->(E1_FILIAL + E1_CLIENTE + E1_LOJA)"
	ElseIf (FWModeAccess('SA1',1) == 'C' .Or. FWModeAccess('SA1',2) == 'C' .Or. FWModeAccess('SA1',3) == 'C')
		//Cliente Compartilhado
		nOrder 		:= 2
		cChaveCli 	:= "(cTrabSA1)->(A1_COD + A1_LOJA)"
		cChaveTit	:= "(cTrabSE1)->(E1_CLIENTE + E1_LOJA)"
	EndIf

	(cTrabSA1)->(DBGoTop())

	nEnvProc := 0

	If nOrder > 0 .And. !Empty(cChaveTit)
		(cTrabSE1)->(DBSetOrder(nOrder))
		While !(cTrabSA1)->(Eof())

			//Verifica a ordem de busca na SE1 pelo compartilhamento
			If nOrder = 1
				cChaveCli	:= "(cTrabSA1)->(A1_FILIAL + A1_COD + A1_LOJA)"
				cChaveTit	:= "(cTrabSE1)->(E1_FILIAL + E1_CLIENTE + E1_LOJA)"
			Else
				cChaveCli 	:= "(cTrabSA1)->(A1_COD + A1_LOJA)"
				cChaveTit	:= "(cTrabSE1)->(E1_CLIENTE + E1_LOJA)"
			EndIf

			If l811Auto
				lCliOk := .T.
			Else
				lCliOk := (cTrabSA1)->A1_OK == oMrkClient:cMark 
			EndIf
		
			lEmitSA1 := .T.

			If lCliOk 
				(cTrabSE1)->(DBGoTop())
				If (cTrabSE1)->(DBSeek(&(cChaveCli)))
					cProcess := ""
					While !(cTrabSE1)->(Eof()) .And. &(cChaveCli) == &(cChaveTit)
						If l811Auto
							lTitOk := .T.
						Else
							lTitOk := (cTrabSE1)->E1_MRK == oMrkTitle:cMark 
						EndIf

						If lTitOk 
							If Empty(cProcess)
								cProcess := FWUUIDV4()
								nProcesso++
							EndIf

							If lEmitSA1
								aAdd(aProcesso,{(cTrabSA1)->(A1_FILIAL + A1_COD + A1_LOJA),{}})
								lEmitSA1 := .F.
							EndIf
							aAdd(aReport,{(cTrabSA1)->A1_COD,(cTrabSA1)->A1_LOJA,cProcess,cCodCarta})

							If !oSubFWT:IsEmpty()
								oSubFWT:AddLine()
							EndIf

							cChaveFK7 := FINGRVFK7("SE1",;
								(cTrabSE1)->(E1_FILIAL + '|' + E1_PREFIXO + '|' + E1_NUM + '|' + E1_PARCELA + '|' + E1_TIPO + '|' + E1_CLIENTE + '|' + E1_LOJA),;
								(cTrabSE1)->E1_FILORIG)

							oSubFWT:SetValue('FWT_LAYOUT',cCodCarta)
							oSubFWT:SetValue('FWT_DTENVI',dDataBase)
							oSubFWT:SetValue('FWT_CHAVE',cChaveFK7)
							oSubFWT:SetValue('FWT_PROCES',cProcess)
							oSubFWT:SetValue('FWT_DTREFE',dDtRef)
							oSubFWT:SetValue('FWT_FILLYT',cFilLayout)
							aAdd(aProcesso[nProcesso][2],{cProcess,cChaveFK7,(cTrabSE1)->E1_FILORIG})
							If l811Auto
								aAdd(aRetorno,{cProcess,cChaveFK7}) // variável aRetorno declarada no fonte FINA811TESTCASE
							EndIf 
							nEnvProc++
						EndIf
						(cTrabSE1)->(DBSkip())
					EndDo
				EndIf
			Else
				(cTrabSA1)->(DBSkip())
				Loop
			EndIf
			(cTrabSA1)->(DBSkip())
		EndDo
	EndIf

	If oModelFWT:VldData()
		oModelFWT:CommitData()
		lRet:= .T.
	Else
		If !l811Auto
			cLog := cValToChar(oModelFWT:GetErrorMessage()[4]) + ' - '
			cLog += cValToChar(oModelFWT:GetErrorMessage()[5]) + ' - '
			cLog += cValToChar(oModelFWT:GetErrorMessage()[6])
		
			Help(,,"F811CART",,cLog,1,0)
		EndIf
	EndIf

	//Processa o envio de e-mails e/ou a exibição do relatório
	//conforme a configurseção do layout da carta selecionado
	F811SendMail()

	FWRestArea(aAreaTRBSE1)
	FWRestArea(aAreaTRBSA1)
	FWRestArea(aAreaTRBFWP)

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} F811SendMail()
Envia os e-mails de cobrança

@author Pedro Pereira Lima
@since 04/09/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function F811SendMail() As Logical
	Local cServer		As Character
	Local cUser			As Character
	Local cPass			As Character
	Local cFrom			As Character
	Local cSubject		As Character
	Local cUsrAut		As Character
	Local cPswAut		As Character
	Local lAutentica	As Logical
	Local cTo			As Character
	Local lConexao		As Logical
	Local lEnvio		As Logical
	Local lAuth			As Logical
	Local cHtml			As Character
	Local cCodCarta		As Character
	Local aMailFld		As Array
	Local cSaudacao		As Character
	Local cCorpoCrt		As Character
	Local cConcluCrt	As Character
	Local cError		As Character
	Local nX			As Numeric
	Local nY			As Numeric
	Local nZ			As Numeric
	Local nW			As Numeric
	Local aAux			As Array
	Local aAreaFWP		As Array
	Local lCabecVenc	As Logical
	Local cFilFWP		As Character
	Local cFilFWS		As Character
	Local cLogMsg		As Character
	Local nLenTitle		As Numeric
	Local lF811MAILTO	As Logical
	Local cMailTo		As Character
	Local aStatus		As Array
	Local cProcStatus	As Character
	Local lLayoutOk		As Logical
	Local cEndere1		As Character
	Local cEndere2		As Character
	Local cCC           As Character
	Local aEmails       As Array

	cServer		:= AllTrim( GetMV('MV_RELSERV',.F.,'')	)
	cUser		:= AllTrim( GetMV('MV_RELAUSR',.F.,'')	)//AllTrim( GetMV('MV_RELACNT',.F.,'')	)
	cPass		:= AllTrim( GetMV('MV_RELAPSW',.F.,'')	)//AllTrim( GetMV('MV_RELPSW' ,.F.,'')	)
	cFrom		:= AllTrim( GetMV('MV_RELFROM',.F.,'')	)
	cSubject	:= AllTrim( GetMV('MV_RELBODY',.F.,'')	)
	cUsrAut		:= AllTrim( GetMV('MV_RELACNT',.F.,'')	)//AllTrim( GetMV('MV_RELAUSR',.F.,'')	)
	cPswAut		:= AllTrim( GetMV('MV_RELPSW' ,.F.,'')	)//AllTrim( GetMV('MV_RELAPSW',.F.,'')	)
	lAutentica	:= GetMV('MV_RELAUTH',.F.,.F.)
	cTo			:= ''
	lConexao	:= .F.
	lEnvio		:= .F.
	lAuth		:= .F.
	cHtml		:= ''
	cCodCarta	:= ''
	aMailFld	:= {}
	cSaudacao	:= ''
	cCorpoCrt	:= ''
	cConcluCrt	:= ''
	cError		:= ''
	nX			:= 0
	nY			:= 0
	nZ			:= 0
	nW			:= 0
	aAux		:= {}
	aAreaFWP	:= (cTrabFWP)->(GetArea())
	lCabecVenc	:= .T.
	cFilFWP		:= ''
	cFilFWS		:= ''
	cLogMsg		:= ''
	nLenTitle	:= TamSX3('FWS_DESCRI')[1]
	lF811MAILTO	:= ExistBlock('F811MAILTO')
	cMailTo		:= ''
	aStatus		:= {}
	cProcStatus	:= ''
	cEndere1	:= ""
	cEndere2	:= ""
	cCC         := ""
	aEmails     := {}

	Private dBaixa		:= dDtRef

	(cTrabFWP)->(DBGoTop())

	While !(cTrabFWP)->(Eof())
		If l811Auto 
			lLayoutOk := .T.
		Else
			lLayoutOk := (cTrabFWP)->FWP_OK == oMrkLayout:cMark
		EndIf 
		
		If lLayoutOk
			cFilFWP   := (cTrabFWP)->FWP_FILIAL
			cCodCarta := (cTrabFWP)->FWP_CODCRT
			FWP->(DBSetOrder(1))
			FWP->(DBSeek(xFilial('FWP',cFilFWP)+cCodCarta))
			cSaudacao := FWP->FWP_TXTSAU
			cCorpoCrt := FWP->FWP_TXTCRT
			cConcluCrt:= FWP->FWP_TXTCON
			cTpEnvio  := FWP->FWP_ENVIO
			Exit
		EndIf
		(cTrabFWP)->(DBSkip())
	EndDo

	FWRestArea(aAreaFWP)

	cAliasFWS := GetNextAlias()

	cFilFWS := xFilial('FWS',cFilFWP)

	//Query para seleção dos campos que compõem o layout da carta de cobrança
	BeginSql Alias cAliasFWS

		SELECT FWS.FWS_CAMPO,FWS.FWS_DESCRI
		FROM %Table:FWS% FWS
		WHERE FWS.FWS_FILIAL = %Exp:cFilFWS%
		AND FWS.FWS_LAYOUT = %Exp:cCodCarta%
		AND FWS.%NOTDEL%
		ORDER BY FWS.FWS_SEQ

	EndSql

	//Montagem do array contendo
	// - Nome do campo no SX3
	// - Descrição do campo
	// - Tipo do campo (SX3)
	// - Picture do campo (SX3)
	While !(cAliasFWS)->(Eof())
		SX3->(DBSetOrder(2)) // X3_CAMPO
		SX3->(DBSeek((cAliasFWS)->FWS_CAMPO))
		aAdd(aMailFld, {(cAliasFWS)->FWS_CAMPO,(cAliasFWS)->FWS_DESCRI,SX3->X3_TIPO,SX3->X3_PICTURE})
		(cAliasFWS)->(DBSkip())
	EndDo

	DBSelectArea(cAliasFWS)
	DBCloseArea()

	ProcLogIni( {} , 'FINA811Proc' , , @cIdCV8 )

	ProcLogAtu( 'INICIO', , , , .T. )

	ProcRegua(nEnvProc)

	If cTpEnvio $ '1|3' // Tipo de envio: E-mail ou Ambos
		For nX := 1 To Len(aProcesso)

			// Caso não haja nenhum título selecionado para o cliente
			If Empty(aProcesso[nX][2])
				Loop
			EndIf

			lCabecVenc := .T.

			SA1->(DBSetOrder(1))
			SA1->(DBSeek(aProcesso[nX][1]))
			cTo := AllTrim(SA1->A1_EMAIL)

			cLogMsg := ''

			cHtml := ''
			cHtml += '<html>'
			cHtml += '<head>'
			cHtml += '<style>'
			cHtml += 'table#tabela_titulos {'
			cHtml += 'border: 1px solid black;'
			cHtml += 'border-collapse: collapse;}'
			cHtml += 'caption, td, th {'
			cHtml += 'border: 1px solid black;'
			cHtml += 'font-family:verdana;}'
			cHtml += 'td#bloco {'
			cHtml += 'border: 0px;}'
			cHtml += 'td#valor {'
			cHtml += 'text-align: right;}'
			cHtml += 'td#data {'
			cHtml += 'text-align: center;}'
			cHtml += '</style>'
			cHtml += '</head>'
			cHtml += '<body>'

			//Saudseção
			cHtml += '<table style="width:80%">'
			cHtml += '<tr>'
			cHtml += '<td id="bloco">'
			cHtml += cSaudacao
			cHtml += '</td>'
			cHtml += '</tr>'
			cHtml += '</table><br>'
			cHtml += '<table style="width:80%">'
			cHtml += '<tr>'
			cHtml += '<td id="bloco">'
			cHtml += SA1->A1_NOME+"  ( "+SA1->A1_COD + " - " + SA1->A1_LOJA+" )"
			cHtml += '</td>'
			cHtml += '</tr>'

			If !Empty(SA1->A1_ENDCOB) .And. !Empty(SA1->A1_MUNC) .And. !Empty(SA1->A1_CEPC) .And. !Empty(SA1->A1_ESTC) .And. !Empty(SA1->A1_BAIRROC)
				cEndere1 := Capital(AllTrim(SA1->A1_ENDCOB))
				cEndere2 := Capital(AllTrim(SA1->A1_BAIRROC)) + " - " + Capital(AllTrim(SA1->A1_MUNC)) + " - " + SA1->A1_ESTC + " - " + Transform(SA1->A1_CEPC,"@R 99999-999")
			Else
				cEndere1 := Capital(AllTrim(SA1->A1_END))
				cEndere2 := Capital(AllTrim(SA1->A1_BAIRRO)) + " - " + Capital(AllTrim(SA1->A1_MUN)) + " - " + SA1->A1_EST + " - " + Transform(SA1->A1_CEP,"@R 99999-999")
			EndIf

			cHtml += '<tr>'
			cHtml += '<td id="bloco">'
			cHtml += cEndere1
			cHtml += '</td>'
			cHtml += '</tr>'
			cHtml += '<tr>'
			cHtml += '<td id="bloco">'
			cHtml += cEndere2
			cHtml += '</td>'
			cHtml += '</tr>'
			cHtml += '</table><br><br>'

			cLogMsg += SA1->A1_NOME + CRLF + CRLF

			//Corpo da carta
			cHtml += '<table style="width:80%">'
			cHtml += '<tr>'
			cHtml += '<td id="bloco">'
			cHtml += cCorpoCrt
			cHtml += '</td>'
			cHtml += '</tr>'
			cHtml += '</table><br>'

			_cVendedor:=""
			_cMensagem:="Vendendor nao encontrado"
			_lVendDif:=.F.

			For nY := 1 To Len(aProcesso[nX][2])

				FK7->(DBSetOrder(1))
				FK7->(DBSeek(xFilial('FK7',aProcesso[nX][2][nY][3]) + aProcesso[nX][2][nY][2]))
				SE1->(DBSetOrder(1))
				SE1->(DBSeek(FK7->FK7_FILTIT+FK7->FK7_PREFIX+FK7->FK7_NUM+FK7->FK7_PARCEL+FK7->FK7_TIPO+FK7->FK7_CLIFOR+FK7->FK7_LOJA))

				If !Empty(SE1->E1_VEND1) .And. !_lVendDif
				   If !Empty(_cVendedor) .And. SE1->E1_VEND1 <> _cVendedor
				      _lVendDif:=.T.
					  _cMensagem:="Titulos com vendedores diferentes"
				   EndIf
				   If SE1->E1_VEND1 $ (SA1->(A1_VEND+A1_I_VEND2+A1_I_VEND3+A1_I_VEND4))
				      _cVendedor:=SE1->E1_VEND1
					  _cMensagem:=""
				   ElseIf Empty(_cVendedor)
					  _cMensagem:="Titulos com vendedores incopativeis com o cadastro de Cliente"
				   EndIf
				EndIf

				nValAbat  := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,;
					SE1->E1_CLIENTE,SE1->E1_LOJA,xFilial('SE1',SE1->E1_FILORIG),,SE1->E1_TIPO)

				If nY == 1
					cProcStatus := aProcesso[nX][02][nY][01]
				EndIf

				If cComboVenc == "1" .And. SE1->E1_VENCREA >= dDtRef
					aAdd(aAux,SE1->(Recno()))
				Else
					If lCabecVenc //Gero o cabeçalho HTML apenas uma vez caso existam títulos vencidos
						//títulos em atraso
						cHtml += '<table style="width:80%">'
						cHtml += '<caption>'
						cHtml += '<b>' + STR0047 + '</b>'
						cHtml += '</caption>'
						cHtml += '<tr>'
						cLogMsg += STR0047 + CRLF + CRLF
						//cabeçalho
						For nZ := 1 To Len(aMailFld)
							cHtml += '<th>'
							cHtml += aMailFld[nZ][2]
							cHtml += '</th>
							cLogMsg += aMailFld[nZ][2] + ' | '
						Next nZ
						cHtml += '</tr>'
						cLogMsg += CRLF
						lCabecVenc := .F.
					EndIf

					cHtml += '<tr>'
					For nZ := 1 To Len(aMailFld)
						If aMailFld[nZ][3] == 'N' .And. !(AllTrim(aMailFld[nZ][1]) $ 'E1_JUROS|E1_MULTA|E1_SALDO')
							cHtml += '<td id="valor">
							cHtml += Transform(SE1->&(AllTrim(aMailFld[nZ][1])),AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(SE1->&(AllTrim(aMailFld[nZ][1])),AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf aMailFld[nZ][3] == 'D'
							cHtml += '<td id="data">
							cHtml += DToC(SE1->&(AllTrim(aMailFld[nZ][1])))
							cLogMsg += PadR(DToC(SE1->&(AllTrim(aMailFld[nZ][1]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_SALDO'
							cHtml += '<td id="valor">
							cHtml += Transform(SE1->E1_SALDO - nValAbat,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(SE1->E1_SALDO - nValAbat,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_MULTA'
							//--------------------------------------------------------------------------------------
							//parâmetros LojxRMul
							//lRegrafin			- Realiza cÃ¡lculo de juros pela regra do SIGAFIN (.T.)
							//lAcresVlTit		- Adiciona Acrescimo no Total?            
	                        //nPerMulta			- Percentual de Multa                     
	                        //nSaldo			- Saldo do  título                        
							//nAcrescimo		- Valor de Acrescimo                      
							//dDtVencRea		- Data de Vencimento Real                 
							//dDtPag			- Data de Pagamento                       
							//lBxparcial		- Baixa Parcial?                          
							//nE1_Multa			- Valor da Multa E1_MULTA                 
							//lAbat				- Abate valor?                            
							//cPrefixo			- Prefixo do título                       
							//cNumero			- Numero do título                        
							//cParcela			- Parcela do título                       
							//cTipo				- Tipo do título 
							//cCliente			- Cliente do título                       
							//cLoja				- Loja do Cliente do título               
							//cAliasSE1			- Alias da WorkArea do título (posicionada)
							//lLoja				- Chamado pelo Loja? 						
							//--------------------------------------------------------------------------------------
							nMulta := LojxRMul(,.F.,,SE1->E1_SALDO - nValAbat,,SE1->E1_VENCREA,dDtRef,,)
							cHtml += '<td id="valor">
							cHtml += Transform(nMulta,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(nMulta,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_JUROS'
							nJuros := Fa070Juros(SE1->E1_MOEDA,SE1->E1_SALDO - nValAbat,,)
							cHtml += '<td id="valor">
							cHtml += Transform(nJuros,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(nJuros,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'DATRASO'
							cHtml += '<td id="valor">
							cHtml += AllTrim(Str( IIf(dDataBase > SE1->E1_VENCREA,dDataBase - SE1->E1_VENCREA,0) ))
							cLogMsg += PadL(AllTrim(Str( IIf(dDataBase > SE1->E1_VENCREA,dDataBase - SE1->E1_VENCREA,0) )),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'TOTAL'
							nMulta := LojxRMul(,.F.,,SE1->E1_SALDO - nValAbat,,SE1->E1_VENCREA,dDtRef,,)

							nJuros := Fa070Juros(SE1->E1_MOEDA,SE1->E1_SALDO - nValAbat,,)

							cHtml += '<td id="valor">
							cHtml += Transform(SE1->E1_SALDO + nMulta + nJuros - nValAbat,"@E 999,999,999.99")
							cLogMsg += PadL(AllTrim(Transform(SE1->E1_SALDO + nMulta + nJuros- nValAbat,"@E 999,999,999.99")),nLenTitle) + ' | '
						Else
							cHtml += '<td>'
							cHtml += SE1->&(AllTrim(aMailFld[nZ][1]))
							cLogMsg += PadR(SE1->&(AllTrim(aMailFld[nZ][1])),nLenTitle) + ' | '
						EndIf
						cHtml += '</td>'
					Next nZ
					cHtml += '</tr>'
					cLogMsg += CRLF
				EndIf
				IncProc()
			Next nY

			aEmails := F811MAILTO(_cVendedor,_cMensagem)
			cTo := aEmails[1]
			cCC := aEmails[2]
			
			If Empty(cTo)
				ProcLogAtu( 'ERRO' , STR0054, SA1->A1_COD + " - " + SA1->A1_LOJA + " | " + SA1->A1_NOME , , .T. )
				aAdd(aStatus,{aProcesso[nX][02][01][01],"2",cCodCarta})
				Loop
			EndIf

			If !lCabecVenc
				cHtml += '</table><br><br>'
			EndIf

			If cComboVenc == "1" .And. Len(aAux) > 0
				//Caso não haja nenhum título vencido, não mostro a mensagem de relação de títulos a vencer
				If !lCabecVenc
					cHtml += '<table style="width:80%">'
					cHtml += '<tr>'
					cHtml += '<td id="bloco">'
					cHtml += STR0055
					cHtml += '</td>'
					cHtml += '</tr>'
					cHtml += '</table><br>'
				EndIf
				//títulos a vencer
				cHtml += '<table style="width:80%">'
				cHtml += '<caption>'
				cHtml += '<b>' + STR0048 + '</b>'
				cHtml += '</caption>'
				cHtml += '<tr>'

				cLogMsg += STR0048 + CRLF + CRLF

				For nZ := 1 To Len(aMailFld)
					cHtml += '<th>'
					cHtml += aMailFld[nZ][2]
					cHtml += '</th>
					cLogMsg += aMailFld[nZ][2] + ' | '
				Next nZ
				cHtml += '</tr>'
				cLogMsg += CRLF

				For nW := 1 To Len(aAux)
					cHtml += '<tr>'
					SE1->(DBGoTo(aAux[nW]))
					nValAbat  := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",SE1->E1_MOEDA,dDataBase,;
						SE1->E1_CLIENTE,SE1->E1_LOJA,xFilial('SE1',SE1->E1_FILORIG),,SE1->E1_TIPO)
					For nZ := 1 To Len(aMailFld)
						If aMailFld[nZ][3] == 'N' .And. !(AllTrim(aMailFld[nZ][1]) $ 'E1_JUROS|E1_MULTA|E1_SALDO')
							cHtml += '<td id="valor">
							cHtml += Transform(SE1->&(AllTrim(aMailFld[nZ][1])),AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(SE1->&(AllTrim(aMailFld[nZ][1])),AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf aMailFld[nZ][3] == 'D'
							cHtml += '<td id="data">
							cHtml += DToC(SE1->&(AllTrim(aMailFld[nZ][1])))
							cLogMsg += PadR(DToC(SE1->&(AllTrim(aMailFld[nZ][1]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_SALDO'
							cHtml += '<td id="valor">
							cHtml += Transform(SE1->E1_SALDO - nValAbat,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(SE1->E1_SALDO - nValAbat,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_MULTA'
							//--------------------------------------------------------------------------------------
							//parâmetros LojxRMul
							//lRegrafin			- Realiza cÃ¡lculo de juros pela regra do SIGAFIN (.T.)
							//lAcresVlTit		- Adiciona Acrescimo no Total?            
	                        //nPerMulta			- Percentual de Multa                     
	                        //nSaldo			- Saldo do  título                        
							//nAcrescimo		- Valor de Acrescimo                      
							//dDtVencRea		- Data de Vencimento Real                 
							//dDtPag			- Data de Pagamento                       
							//lBxparcial		- Baixa Parcial?                          
							//nE1_Multa			- Valor da Multa E1_MULTA                 
							//lAbat				- Abate valor?                            
							//cPrefixo			- Prefixo do título                       
							//cNumero			- Numero do título                        
							//cParcela			- Parcela do título                       
							//cTipo				- Tipo do título 
							//cCliente			- Cliente do título                       
							//cLoja				- Loja do Cliente do título               
							//cAliasSE1			- Alias da WorkArea do título (posicionada)
							//lLoja				- Chamado pelo Loja? 						
							//--------------------------------------------------------------------------------------
							nMulta := LojxRMul(,.F.,,SE1->E1_SALDO - nValAbat,,SE1->E1_VENCREA,dDtRef,,)
							cHtml += '<td id="valor">
							cHtml += Transform(nMulta,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(nMulta,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'E1_JUROS'
							nJuros := Fa070Juros(SE1->E1_MOEDA,SE1->E1_SALDO - nValAbat,,)
							cHtml += '<td id="valor">
							cHtml += Transform(nJuros,AllTrim(aMailFld[nZ][4]))
							cLogMsg += PadL(AllTrim(Transform(nJuros,AllTrim(aMailFld[nZ][4]))),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'DATRASO'
							cHtml += '<td id="valor">
							cHtml += AllTrim(Str( IIf(dDataBase > SE1->E1_VENCREA,dDataBase - SE1->E1_VENCREA,0) ))
							cLogMsg += PadL(AllTrim(Str( IIf(dDataBase > SE1->E1_VENCREA,dDataBase - SE1->E1_VENCREA,0) )),nLenTitle) + ' | '
						ElseIf AllTrim(aMailFld[nZ][1]) == 'TOTAL'
							nMulta := LojxRMul(,.F.,,SE1->E1_SALDO - nValAbat,,SE1->E1_VENCREA,dDtRef,,)

							nJuros := Fa070Juros(SE1->E1_MOEDA,SE1->E1_SALDO - nValAbat,,)

							cHtml += '<td id="valor">
							cHtml += Transform(SE1->E1_SALDO + nMulta + nJuros - nValAbat,"@E 999,999,999.99")
							cLogMsg += PadL(AllTrim(Transform(SE1->E1_SALDO + nMulta + nJuros - nValAbat,"@E 999,999,999.99")),nLenTitle) + ' | '
						Else
							cHtml += '<td>'
							cHtml += SE1->&(AllTrim(aMailFld[nZ][1]))
							cLogMsg += PadR(SE1->&(AllTrim(aMailFld[nZ][1])),nLenTitle) + ' | '
						EndIf
						cHtml += '</td>'
					Next nZ

					cLogMsg += CRLF

					IncProc()
					cHtml += '</tr>'
				Next nW
				aAux := {}
				cHtml += '</table><br><br>'
			EndIf

			//conclusão
			If !Empty(cConcluCrt)
				cHtml += '<table style="width:80%">'
				cHtml += '<tr>'
				cHtml += '<td id="bloco">'
				cHtml += cConcluCrt
				cHtml += '</td>'
				cHtml += '</tr>'
				cHtml += '</table>'
			EndIf

			cHtml += '</body>'
			cHtml += '</html>'

			//Efetua a conexão com o servidor de saída (SMTP)
			Connect Smtp Server cServer ACCOUNT cUser PASSWORD cPass RESULT lConexao

			//Efetua autenticação do servidor de e-mail
			If lAutentica
				lAuth := MailAuth(cUsrAut,cPswAut)
			EndIf

			//Processa o envio do e-mail conforme parâmetros definidos
			Send Mail From cFrom to cTo CC cCC SubJect cSubject BODY cHtml RESULT lEnvio

			If lAuth
				If lConexao
					If lEnvio
						ProcLogAtu( 'MENSAGEM' , STR0050 + SA1->A1_NOME , cLogMsg , , .T. )
						aAdd(aStatus,{cProcStatus,"1",cCodCarta})
					Else
						GET MAIL ERROR cError
						ProcLogAtu( 'ERRO' , STR0051 + SA1->A1_EMAIL , cError , , .T. )
						aAdd(aStatus,{cProcStatus,"4",cCodCarta})
					EndIf
				Else
					GET MAIL ERROR cError
					ProcLogAtu( 'ERRO' , STR0052 + cServer , cError , , .T. )
					aAdd(aStatus,{cProcStatus,"3",cCodCarta})
				EndIf
			Else
				GET MAIL ERROR cError
				ProcLogAtu( 'ERRO' , STR0075 + cServer , cError , , .T. )
				aAdd(aStatus,{cProcStatus,"5",cCodCarta})
			EndIf

			DisConnect Smtp Server
			
		Next nX
	EndIf

	If !Empty(aStatus)
		For nX := 1 To Len(aStatus)
			FWT->(DBSetOrder(1))
			If FWT->(DBSeek(xFilial("FWT") + aStatus[nX][03] + aStatus[nX][01]))
				While !FWT->(Eof()) .And. FWT->(FWT_FILIAL + FWT_LAYOUT + FWT_PROCES) == xFilial("FWT") + aStatus[nX][03] + aStatus[nX][01]
					RecLock("FWT")
					FWT->FWT_STATUS := aStatus[nX][02]
					MSUnLock()
				
					FWT->(DBSkip())
				EndDo
			EndIf
		Next nX
	EndIf

	If !l811Auto .And. cTpEnvio $ "2|3" // Tipo de Envio: Carta física ou Ambos
		FINR811A(.T.,cComboVenc) //// Titulos a Vencer?  1-Sim , 2-Nao
		ProcLogAtu( 'MENSAGEM' , STR0053 , , , .T.)
	EndIf

	ProcLogAtu( 'FIM' , , , , .T. )

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} SetMrkAll
Marca/Desmarca todos os registro da MarkBrowse que está ativa

@param nTrab - Corresponde á MarkBrowse ativa no momento

@author Pedro Pereira Lima
@since 04/09/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function SetMrkAll( nTrab As Numeric )
	Local aArea		As Array
	Local cMarca	As Character
	
	Default nTrab := 2 // Cliente

	aArea	:= {}
	cMarca	:= ''

	If nTrab == 1
		Return
	ElseIf nTrab == 2
		aArea := (cTrabSA1)->(GetArea())
		(cTrabSA1)->(DBGoTop())
		If lSA1Mrk
			cMarca := ''
			lSA1Mrk := .F.
		Else
			cMarca := oMrkClient:cMark
			lSA1Mrk := .T.
		EndIf

		While !(cTrabSA1)->(Eof())
			(cTrabSA1)->A1_OK := cMarca
			(cTrabSA1)->(DBSkip())
		EndDo

		FWRestArea(aArea)
		oMrkClient:Refresh()
	ElseIf nTrab == 3
		aArea := (cTrabSE1)->(GetArea())
		(cTrabSE1)->(DBGoTop())
		If lSE1Mrk
			cMarca := ''
			lSE1Mrk := .F.
		Else
			cMarca := oMrkTitle:cMark
			lSE1Mrk := .T.
		EndIf

		While !(cTrabSE1)->(Eof())
			(cTrabSE1)->E1_MRK := cMarca
			(cTrabSE1)->(DBSkip())
		EndDo

		FWRestArea(aArea)
		oMrkTitle:Refresh()
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} F811AbatRec
Retorna o valor de abatimento (caso haja) do título   

@author Pedro Lima
@since 16/12/2015	
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030AbatRec() As Numeric
	Local nValAbat	As Numeric
	Local cFilAbat	As Character
	Local cPrefixo	As Character
	Local cNum 		As Character
	Local cParcela 	As Character
	Local cTipo	 	As Character
	Local cCliente	As Character
	Local cLoja		As Character
	Local cMoeda	As Character
	Local aArea		As Array
	Local cAliasAux	As Character
	Local lFinr811	As Logical
	Local lRPC		As Logical

	nValAbat	:= 0
	cFilAbat	:= ''
	cPrefixo	:= ''
	cNum		:= ''
	cParcela	:= ''
	cTipo		:= ''
	cCliente	:= ''
	cLoja		:= ''
	cMoeda		:= ''
	aArea		:= FWGetArea()
	cAliasAux	:= ''
	lFinr811	:= FWIsInCallStack('FINR811') .Or. FWIsInCallStack('FINR811A')
	lRPC		:= AllTrim(Funname()) == 'RPC'

	If lFinr811 .Or. (lRPC .And. Type('cTrabSE1') == 'U')
		cAliasAux	:= 'SE1'
	Else
		cAliasAux	:= cTrabSE1
	EndIf

	cFilAbat	:= xFilial('SE1',(cAliasAux)->E1_FILORIG)
	cPrefixo	:= (cAliasAux)->E1_PREFIXO
	cNum 		:= (cAliasAux)->E1_NUM
	cParcela 	:= (cAliasAux)->E1_PARCELA
	cTipo	 	:= (cAliasAux)->E1_TIPO
	cCliente	:= (cAliasAux)->E1_CLIENTE
	cLoja		:= (cAliasAux)->E1_LOJA
	cMoeda		:= (cAliasAux)->E1_MOEDA

	If !lFinr811
		//Posiciono a SE1 no registro correspondente para uso na SumAbatRec
		SE1->(DBSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		SE1->(DBSeek(xFilial('SE1',(cAliasAux)->E1_FILORIG) + (cAliasAux)->(E1_CLIENTE + E1_LOJA) + cPrefixo + cNum + cParcela + (cAliasAux)->E1_TIPO ))
	EndIf

	nValAbat  := SomaAbat(cPrefixo,cNum,cParcela,"R",cMoeda,dDataBase,cCliente,cLoja,cFilAbat,,cTipo)

	FWRestArea(aArea)

Return nValAbat

//-------------------------------------------------------------------
/*/{Protheus.doc} F811RMul
Retorna o valor de multa (caso haja) do título   

@author Mauricio Pequim Jr
@since 16/12/2015	
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030RMul( nValor As Numeric, nSaldo As Numeric, dDtVencRea As Date, dDtRef As Date )

	Local nMulta As Numeric

	DEFAULT nValor		:= 0
	DEFAULT nSaldo		:= 0
	DEFAULT dDtVencRea	:= dDataBase
	DEFAULt dDtRef		:= dDataBase

	nMulta := 0

	If __cMvJurTp == NIL
		__cMvJurTp	:= SuperGetMv("MV_JURTIPO",,"")  // calculo de Multa do Loja , se JURTIPO == L
	EndIf

	If __lMulLoj == NIL
		__lMulLoj := SuperGetMv("MV_LJINTFS", ,.F.) //Calcula multa conforme regra do loja, se integrseção com financial estiver habilitada
	EndIf

	// Verifica se o tipo de calculo de juros é igual (L)loja ou Indicacao do calculo de Multa do Loja, calcula a multa 
	If (__cMvJurTp == "L" .Or. __lMulLoj) .And. nSaldo + U_AF030AbatRec() > 0

		nMulta := 	LojxRMul(,.F.,,nSaldo,,dDtVencRea,dDtRef)

	EndIf

Return nMulta

//-------------------------------------------------------------------
/*/{Protheus.doc} F811AtuTrb
Ajusta o valor do saldo do título, considerando seus abatimentos   

@author Pedro Lima
@since 07/01/2016	
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030AtuTrb()

	(cTrabSE1)->(DBGoTop())

	While !(cTrabSE1)->(Eof())
		RecLock(cTrabSE1,.F.)
		(cTrabSE1)->E1_SALDO := (cTrabSE1)->E1_SALDO - U_AF030AbatRec()
		MSUnLock()
		(cTrabSE1)->(DBSkip())
	EndDo

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} F811TmpCli
Monta uma tabela temporária com a relação de clientes selecionados
permitindo que o filtro de títulos seja feito levando em considerseção
a relação dos clientes selecionados   

@author Pedro Lima
@since 28/07/2016	
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030TmpCli( cTrabSA1 As Character ) As Character
	Local aStruTMP	As Array
	Local cTmpSA1	As Character

	aStruTMP	:= {}
	cTmpSA1		:= ""

	//cria arquivo temporario no banco de Dados que contera as filiais
	aAdd(aStruTMP, { "CLIENTE", "C", TamSX3('A1_COD')[1] + TamSX3('A1_LOJA')[1], 0 } )

	cTmpSA1 := GetNextAlias()
	If __oFIN8115 <> Nil
		__oFIN8115:Delete()
		__oFIN8115	:= Nil
	EndIf

	__oFIN8115 := FwTemporaryTable():New(cTmpSA1)

	__oFIN8115:SetFields(aStruTMP)

	//Criando a Tabela Temporaria
	__oFIN8115:Create()
	Sleep(1000)

	While !(cTrabSA1)->(Eof())
		If !Empty((cTrabSA1)->A1_OK) .Or. l811Auto
			RecLock(cTmpSA1,.T.)
			(cTmpSA1)->CLIENTE := (cTrabSA1)->A1_COD + (cTrabSA1)->A1_LOJA
			MSUnLock()
		EndIf

		(cTrabSA1)->(DBSkip())
	EndDo

Return cTmpSA1

//-------------------------------------------------------------------
/*/{Protheus.doc} F811TitJur
Retorna o valor de juros dos títulos   

@author Pedro Lima
@since 28/07/2016	
@version 12.1.7
/*/
//-------------------------------------------------------------------
User Function AF030TitJur( cTrabSE1 As Character ) As Numeric
	Local nValJur As Numeric

	nValJur := 0

	SE1->(DBSetOrder(1))
	SE1->(MsSeek( (cTrabSE1)->(E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA) ))

	nValJur := fa070Juros(SE1->E1_MOEDA,SE1->E1_SALDO)

Return nValJur


// Funções da situações de cobrança dque devem ser alteradas quando o SERASA 
// descer para o padrão
//-------------------------------------------------------------------
/*/{Protheus.doc} FGetSitCob
Retorna as situações de cobranças selecionadas.
@author william.gundim
@since  14/01/2016
@version P12
/*/	
//-------------------------------------------------------------------
Static Function F811GetSit( cCampo As Character, cFiltro As Character, lFilFW2 As Logical ) As Character
	Local cRet	As Character
	Local nX	As Numeric

	Default cFiltro := ''
	Default lFilFW2 := .T.

	cRet	:= ''
	nX		:= 0

	//Markbrowse com as situações de cobranças.
	F811FltSC(cFiltro,lFilFW2)

	If !Empty(__cRe770F3)
		cRet := cCampo + " IN (" + __cRe770F3 + ")"
	EndIf

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} F811FltSC
contrução de Browse de Consulta padrão do tipo específica 
situações cobrança seleção
NOME ORIGINAL DA FUNCAO F770FltSC
@Return cRet é relação das situações de cobrança selecionadas pelo usuário
@author lucas.oliveira
@since  16/05/2015
@version 12.1.6
/*/
//-------------------------------------------------------------------
Static Function F811FltSC( cFiltro As Character, lFilFW2 As Logical ) As Logical
	Local lRet		As Logical
	Local aStru		As Array
	Local cQuery	As Character
	Local aColumns	As Array
	Local cChave	As Character
	Local nX		As Numeric
	Local aSize     As Array
	Local bOk		As Codeblock
	Local bCancel	As Codeblock
	Local aPesq		As Array

	Default cFiltro	:= ''
	Default lFilFW2	:= .T.

	lRet		:= .F.
	aStru		:= FRV->(DBSTRUCT()) //Estrutura da tabela de situações de cobrança.
	cQuery		:= ''
	aColumns	:= {}
	cChave		:= ''
	nX			:= 0
	aSize		:= {}
	bOk			:= {||lRet := F811GrvSC(__cArqTrab),oDlg:End()}
	bCancel		:= {|| oMrkBrowse:Deactivate(),oDlg:End()}
	aPesq		:= {}

	//Criar uma FWMarkBrowse() baseado na tabela FRV, apresentando todas as situações de cobrança e sua Descrição para seleção do usuário.
	//Caso o usuário confirme, retornar string com o código das situações selecionadas, alimentando a variáveis static __cRe770F3

	__cRe770F3 := ''

	If Empty(__cArqTrab)
		//Seleciona as situações de cobrança, exceto aquelas que impedem interseção com a Serasa 
		cQuery += "SELECT * FROM "+ RetSqlName("FRV") +" FRV "
		cQuery += "WHERE FRV.FRV_FILIAL = '" + xFilial("FRV") + "' "
		cQuery += "AND FRV.D_E_L_E_T_ = ' ' "

		If lFilFW2 //Incluso If para nao executar esse trecho quando executado pelo relatorio FINR645
			cQuery += "AND FRV_CODIGO NOT IN(
			cQuery += "Select FW2_SITUAC FROM "+ RetSqlName("FW2")
			cQuery += " WHERE D_E_L_E_T_ = ''"
			cQuery += " AND FW2_CODIGO = '0012' )"
		EndIf

		If !Empty(cFiltro)
			cQuery += " AND " + cFiltro
		EndIf
		cQuery += " ORDER BY "+ SqlOrder(FRV->(IndexKey()))

		cChave := FRV->(IndexKey())
		aAdd(aStru, {'FRV_OK','C',1,0}) // Adiciono o campo de marca

		__cArqTrab := GetNextAlias()
		If __oFIN8114 <> Nil
			__oFIN8114:Delete()
			__oFIN8114	:= Nil
		EndIf

		__oFIN8114 := FwTemporaryTable():New(__cArqTrab)

		__oFIN8114:SetFields(aStru)

		__oFIN8114:AddIndex("01", {"FRV_CODIGO"})
		__oFIN8114:AddIndex("02", {"FRV_DESCRI"})

		//Criando a Tabela Temporaria
		__oFIN8114:Create()
	
		Processa({||SqlToTrb(cQuery, aStru, __cArqTrab)})	// Cria arquivo temporario

	EndIf

	//MarkBrowse
	For nX := 1 To Len(aStru)
		If	aStru[nX][1] $ "FRV_FILIAL|FRV_CODIGO|FRV_DESCRI|FRV_BANCO|FRV_DESCON|FRV_PROTES|FRV_PERCEN|FRV_NATIOF"
			aAdd(aColumns,FWBrwColumn():New())
			aColumns[Len(aColumns)]:SetData( &("{||"+aStru[nX][1]+"}") )
			aColumns[Len(aColumns)]:SetTitle(RetTitle(aStru[nX][1]))
			aColumns[Len(aColumns)]:SetSize(aStru[nX][3])
			aColumns[Len(aColumns)]:SetDecimal(aStru[nX][4])
			aColumns[Len(aColumns)]:SetPicture(PesqPict("FRV",aStru[nX][1]))
		EndIf
	Next nX

	//Regras para pesquisa na tela
	aAdd(aPesq,{AllTrim(RetTitle("FRV_CODIGO")),{{'FRV',"C",TamSX3("FRV_CODIGO")[1],0,AllTrim(RetTitle("FRV_CODIGO")),"@!"}},1})
	aAdd(aPesq,{AllTrim(RetTitle("FRV_DESCRI")),{{'FRV',"C",TamSX3("FRV_DESCRI")[1],0,AllTrim(RetTitle("FRV_DESCRI")),"@!"}},1})

	If !(__cArqTrab)->(Eof())
		aSize := MsAdvSize(,.F.,400)
		DEFINE MSDIALOG oDlg TITLE STR0017 From 300,0 to 800,800 OF oMainWnd PIXEL //situações de cobrança
		oMrkBrowse:= FWMarkBrowse():New()
		oMrkBrowse:oBrowse:SetEditCell(.T.)
		oMrkBrowse:oBrowse:SetMainProc("FINA811")
		oMrkBrowse:SetFieldMark("FRV_OK")
		oMrkBrowse:SetOwner(oDlg)
		oMrkBrowse:SetAlias(__cArqTrab)
		oMrkBrowse:SetProfileId("0007")
		oMrkBrowse:SetSeek(.T.,aPesq)
		oMrkBrowse:SetMenuDef("")
		oMrkBrowse:AddButton(STR0077, bOk,,2) //Confirmar
		oMrkBrowse:AddButton(STR0078,bCancel,,2 ) //Cancelar
		oMrkBrowse:bMark	:= {||}
		oMrkBrowse:bAllMark	:= {||F811SCMark(oMrkBrowse,__cArqTrab)}
		oMrkBrowse:SetMark( "X", __cArqTrab, "FRV_OK" )
		oMrkBrowse:SetDescription("")
		oMrkBrowse:SetColumns(aColumns)
		oMrkBrowse:SetTemporary(.T.)
		oMrkBrowse:Activate()
		ACTIVATE MSDIALOg oDlg CENTERED
	EndIf

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc}F811SCMark
Marca ou desmarca todas as situações de cobrança.
NOME ORIGINAL DA FUNCAO F770SCMark
@author lucas.oliveira
@since  06/10/2015
@version 12.1.7
/*/
//-------------------------------------------------------------------
Static Function F811SCMark( oMrkBrowse As Object, __cArqTrab As Character ) As Logical
	Local cMarca As Character

	cMarca := oMrkBrowse:Mark()

	DBSelectArea(__cArqTrab)
	(__cArqTrab)->(DBGoTop())

	While !(__cArqTrab)->(Eof())
	
		RecLock(__cArqTrab, .F.)

		If (__cArqTrab)->FRV_OK == cMarca
			(__cArqTrab)->FRV_OK := ' '
		Else
			(__cArqTrab)->FRV_OK := cMarca
		EndIf

		MSUnLock()
		(__cArqTrab)->(DBSkip())
	EndDo
	(__cArqTrab)->(DBGoTop())
	oMrkBrowse:oBrowse:Refresh(.T.)

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc}F811GrvSC
NOME ORIGINAL DA FUNCAO F770GrvSC
Grava em uma string todas as situações de cobrança selecionadas.
@author lucas.oliveira
@since  16/05/2015
@version 12.1.6
/*/
//-------------------------------------------------------------------
Static Function F811GrvSC( __cArqTrab As Character ) As Logical
	Local lRet		As Logical
	Local nRecno	As Numeric
	Local nX		As Numeric

	lRet	:= .F.
	nRecno	:= 0
	nX		:= 0

	DBSelectArea(__cArqTrab)
	nRecno := (__cArqTrab)->(RecNo())
	(__cArqTrab)->(DBGoTop())
	While !(__cArqTrab)->(Eof())
		If !Empty((__cArqTrab)->FRV_OK)
			__cRe770F3 += IIf(nX > 0, ",'" + (__cArqTrab)->FRV_CODIGO + "'", "'" + (__cArqTrab)->FRV_CODIGO + "'")
			nX++
		EndIf
		(__cArqTrab)->(DBSkip())
	End

	(__cArqTrab)->(DBGoTo(nRecno))
	lRet := IIf(Len(__cRe770F3) > 0,.T., .F.)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} FIN811AUTO
funções para automação de teste do envio da carta de cobrança

@param
@author rogerio.melonio	
@since  16/03/2018
@version 12.1.17
/*/
//-------------------------------------------------------------------
Static Function FIN811AUTO() As Logical
	Local lRet As Logical 

	lRet := .T.

	// Pagina 2 
	// seleção da carta de cobrança ativa passado pela automação de testes
	Valid_PG2() 

	// Pagina 3
	// Validseção da carta e seleção dos clientes 
	lRet := Valid_PG3() 

	If lRet
		// Pagina 4
		// Validseção dos clientes, seleção e validseção dos títulos
		Valid_PG4() 
		(cTrabSE1)->(DBGoTop())
		lRet := !(cTrabSE1)->(Eof())
	EndIf

	If lRet
		// Pagina 6
		// Processa o envio através de chamada da funções F811GrvFWT()
		F811GrvFWT()
	EndIf 

Return lRet


/*
===============================================================================================================================
Programa----------: F811MAILTO
Autor-------------: Alex Wallauer
Data da Criacao---: 05/04/2022
Descrição---------: Antigo PE no programa FINA811.PRW - Rotina para envio das cartas de cobranca - CHAMADO 35423
Parametros--------: _cVendedor,_cMensagem)
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function F811MAILTO(_cVendedor,_cMensagem)

Local cGetPara:= AllTrim(SA1->A1_EMAIL)
Local cGetCc  := AllTrim(UsrRetMail(__cUserId))
Local cGetNovo:= Space(1000)
Local aEmails := {}
Local nOpcA   := 0
Local nCol    := 50
Local nlin    := 06
Local cCliente:=AllTrim(SA1->A1_NOME)+" ( "+SA1->A1_COD + " - " + SA1->A1_LOJA +" ) "
Local cGetVend:=Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_EMAIL")//+Space(1000) //
Local _lCheck := .F.

If Empty(cGetVend)
   _cMensagem:="Vendedor sem e-mail"
EndIf

If !Empty(_cMensagem)
   cGetVend:=_cMensagem
EndIf

cGetNovo := Space(1000)

DEFINE MSDIALOG oDlgMail TITLE "Configuracao do E-Mail" FROM 000, 000  TO 300, 650   PIXEL

	@ nlin  , 006 Say oPara PROMPT "Cliente:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ nlin-1, nCol MSGET cCliente SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.
    nlin+=16

	// Para:
	@ nlin  , 006 Say oPara PROMPT "E-mail Cliente:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ nlin-1, nCol MSGET cGetPara SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.
    nlin+=16

	// Com cópia:
	@ nlin  , 006 Say oCc PROMPT "Com Copia:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ nlin-1, nCol MSGET cGetCc SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.
    nlin+=16

	// E-mail Novo:
	@ nlin  , 006 Say oAssunto PROMPT "E-Mail Novo:" SIZE 045, 007 OF oDlgMail   PIXEL
	@ nlin-1, nCol MSGET cGetNovo SIZE 256, 010 OF oDlgMail  PIXEL VALID U_EEmail( cGetNovo ) 
    nlin+=16

	// E-mail Vendedor:
	@ nlin,006 Checkbox _lCheck PROMPT "Enviar E-Mail p/ Vendedor?"	PIXEL OF oDlgMail SIZE 200,008 WHEN Empty(_cMensagem) PIXEL //ON CLICK( AFIN004TPT( _lCheck , @aItens ) , oVend:Refresh() )
    nlin+=16
	@ nlin, 006 Say "Vendedor: "+_cVendedor+" - "+SA3->A3_NOME OF oDlgMail   PIXEL//SIZE 045, 007 
    nlin+=16
	@ nlin, 06 MSGET oVend VAR cGetVend SIZE 256, 010 OF oDlgMail  PIXEL WHEN .F.//_lCheck//VALID U_EEmail( cGetVend ) 
    nlin+=17

	@ nlin, nCol    BUTTON oButEnv PROMPT "&OK"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , IIf(!Empty(AllTrim(cGetPara+cGetNovo)),oDlgMail:End(),U_ITMsg("Preencha o campo E-mail Novo pois no cadastro desse cliente o campo e-mail não está preenchido!","Atenção",,3)) ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If !Empty(cGetNovo)  .And. nOpcA = 1
   cGetPara := AllTrim(cGetNovo)
   If _lCheck	  
	  aEmails := { cGetPara,cGetCc+";"+cGetVend}
   Else
	  aEmails := { cGetNovo,cGetCc}
   EndIf
Else
   	If _lCheck
		aEmails := { cGetPara,cGetCc+";"+cGetVend}
	Else
		aEmails := { cGetPara,cGetCc}
	EndIf
EndIf

Return aEmails

/*
===============================================================================================================================
Programa----------: Valid_PG1()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/04/2022
Descrição---------: PE no programa FINA811.PRW - Rotina para envio das cartas de cobranca - CHAMADO 35423
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Valid_PG1()

Local nI
Local aOptions := {"1 - Sim","2 - Nao"}
Local aOpConVl := {"1 - Valor Total","2 - Saldo      "}
Local aOpBloqu := {"1 - Sim  ","2 - Nao  "}
Local _aParAux := {} 
Local _aParRet := {} 
Local _bOK     := {|| .T. }

cComboFil  :=aOptions[1]
cSitCob    :=aOptions[2]
cComboVenc :=aOptions[2]
cComboConVl:=aOpConVl[1]
cCliBroq   :=aOpBloqu[1]

aAdd( _aParAux , { 1 , LEFT(STR0025,Len(STR0025)-1),cCliDe     ,X3Picture('A1_COD')    ,"",'SA1'   	, "" , 060 , .F. } )//01
aAdd( _aParAux , { 1 , LEFT(STR0026,Len(STR0026)-1),cLojaDe    ,X3Picture('A1_LOJA')   ,"",        	, "" , 060 , .F. } )//02
aAdd( _aParAux , { 1 , LEFT(STR0027,Len(STR0027)-1),cCliAte    ,X3Picture('A1_COD')    ,"",'SA1'   	, "" , 060 , .F. } )//03
aAdd( _aParAux , { 1 , LEFT(STR0028,Len(STR0028)-1),cLojaAte   ,X3Picture('A1_LOJA')   ,"",        	, "" , 060 , .F. } )//04
aAdd( _aParAux , { 1 , LEFT(STR0029,Len(STR0029)-1),dDataDe    ,"@D"                   ,"",        	, "" , 060 , .F. } )//05
aAdd( _aParAux , { 1 , LEFT(STR0030,Len(STR0030)-1),dDataAte   ,"@D"                   ,"",        	, "" , 060 , .F. } )//06
aAdd( _aParAux , { 1 , LEFT(STR0031,Len(STR0031)-1),nValDe     ,'@E 999,999,999.99'    ,"",        	, "" , 060 , .F. } )//07
aAdd( _aParAux , { 1 , LEFT(STR0032,Len(STR0032)-1),nValAte    ,'@E 999,999,999.99'    ,"",        	, "" , 060 , .F. } )//08
aAdd( _aParAux , { 2 , LEFT(STR0033,Len(STR0033)-1),1          ,aOptions,                             060 ,".T.",.F. } )//09 
aAdd( _aParAux , { 2 , LEFT(STR0034,Len(STR0034)-1),2          ,aOptions,                             060 ,".T.",.F. } )//10 
aAdd( _aParAux , { 2 , LEFT(STR0035,Len(STR0035)-1),2          ,aOptions,                             060 ,".T.",.F. } )//11 
aAdd( _aParAux , { 1 , LEFT(STR0037,Len(STR0037)-1),dDtRef     ,"@D"                   ,"",         , "" , 060 , .T. } )//12
aAdd( _aParAux , { 2 , LEFT(STR0061,Len(STR0061)-1),1          ,aOpConVl,                             060 ,".T.",.F. } )//13 
aAdd( _aParAux , { 1 ,"Carteira ? (*) Todos"       , cCart     ,X3Picture('E1_I_CART') ,,'F3ITLC'   , "" , 060 , .F. } )//14
aAdd( _aParAux , { 1 ,"Redes"	                   , cRedes    ,"@S99"				   ,,"REDE50"   , "" , 099 , .F. } )//15
aAdd( _aParAux , { 1 ,"Exceto Redes"               , cExRedes  ,"@S99"				   ,,"REDE50"   , "" , 099 , .F. } )//16
aAdd( _aParAux , { 2 ,"Considera cliente bloqueado",1          ,aOpBloqu,                             060 ,".T.",.F. } )//17 

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI
//aParametros, cTitle                           , @aRet   ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Selecione os filtros" , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oPanel*/,/*cLoad*/,.T.         ,.T.          )
   Return .F.
EndIf

cCliDe     :=MV_PAR01
cLojaDe    :=MV_PAR02
cCliAte    :=MV_PAR03
cLojaAte   :=MV_PAR04
dDataDe    :=MV_PAR05
dDataAte   :=MV_PAR06
nValDe     :=MV_PAR07
nValAte    :=MV_PAR08
cComboFil  :=If(ValType(MV_PAR09)="N",Str(MV_PAR09,1),LEFT(MV_PAR09,1))
cSitCob    :=If(ValType(MV_PAR10)="N",Str(MV_PAR10,1),LEFT(MV_PAR10,1))
cComboVenc :=If(ValType(MV_PAR11)="N",Str(MV_PAR11,1),LEFT(MV_PAR11,1))
dDtRef     :=MV_PAR12
cComboConVl:=If(ValType(MV_PAR13)="N",Str(MV_PAR13,1),LEFT(MV_PAR13,1))
cCart      :=MV_PAR14
cRedes     :=MV_PAR15
cExRedes   :=MV_PAR16
cCliBroq   :=If(ValType(MV_PAR17)="N",Str(MV_PAR17,1),LEFT(MV_PAR17,1))

Return .T.
