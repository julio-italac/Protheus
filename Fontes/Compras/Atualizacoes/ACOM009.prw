
#Include "TOTVS.ch"
#Include "FWBROWSE.CH"
#Include "TBICONN.CH"                     
#Include "TBICODE.CH"
#Include 'FWMVCDef.ch'

Static cAliasMrk	:= ""
Static cSelFil		:= ''
Static cArqTrab		:= ''
Static _oACOM009

/*
===============================================================================================================================
Programa----------: ACOM009
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 22/09/2015
Descrição---------: Rotina responsável por Indicar Comprador para SC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM009

Local aAlias		:= {}
Local aColumns		:= {}
Local aParAux 		:= {}
Local aParRet 		:= {}
Local nI			:= 0
Local bChkMarca		:= {|| IIf( aScan( aRegsSC1 , { |x| x[1] + x[2] + x[3] == (cAliasMrk)->C1_FILIAL + (cAliasMrk)->C1_NUM + (cAliasMrk)->C1_ITEM  } ) == 0 , 'LBNO' , 'LBOK' ) }
Local bSelMarca		:= {|| ( IIf( ( nPos := aScan( aRegsSC1 , { |x| x[1] + x[2] + x[3] == (cAliasMrk)->C1_FILIAL + (cAliasMrk)->C1_NUM + (cAliasMrk)->C1_ITEM } ) ) == 0 , ( AAdd( aRegsSC1 , { (cAliasMrk)->C1_FILIAL, (cAliasMrk)->C1_NUM, (cAliasMrk)->C1_ITEM }  ) , lMarcou := .T. ) , ( aDel( aRegsSC1 , nPos ) , aSize( aRegsSC1 , Len( aRegsSC1 ) -1 ) ) ) ) }
Local bAllMarca		:= {|| IIf( Empty( aRegsSC1 ) , aRegsSC1 := aClone( aRegsAll ) , aRegsSC1 := {} ) , oMrkBrowse:Refresh() , oMrkBrowse:GoTop() }
Local bOK     		:= {|| If(MV_PAR03 >= MV_PAR02 .Or. MV_PAR03 > DATE(),.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo ate a data de hoje",3),.F.) ) }
Local bSelectSC1    := {|| U_SelectSC1() }
Local oproc         := Nil

Private aSelFil	:= {}
Private aRegsSC1:= {}
Private aRegsAll:= {}
Private cPerg	:= "ACOM009"
Private aRotina	:= ACOM009M()

_aItalac_F3	:= {} // Variável Private.
AAdd(_aItalac_F3,{"MV_PAR04" ,"SY1"      ,                        ,                   ,     ,"Compradores"     ,} )
aAdd(_aItalac_F3,{"MV_PAR08" ,bSelectSC1,{|Tab| (Tab)->C1_NUM }, {|Tab|DToC(SToD((Tab)->C1_EMISSAO))},  ,"Solicitacoes"    ,          ,          ,60        ,.T.        ,       , } )

MV_PAR01 := Space(200)
MV_PAR02 := dDataBase
MV_PAR03 := dDataBase
MV_PAR04 := Space(200)
MV_PAR05 := "Ambos"
MV_PAR06 := "Todos"
MV_PAR07 := "Ambos"
MV_PAR08 := Space(200)

AAdd( aParAux , { 2 , "SC Por "   			, MV_PAR01 , { "1-Todas Filiais","2-Filial Corrente","3-Selec. Filiais",}, 100 , ".T." , .F. , ".T." } )
AAdd( aParAux , { 1 , "Dt Emissao Inic"  	, MV_PAR02, "@D", ""  , ""	   , "" , 050 , .F. } )
AAdd( aParAux , { 1 , "Dt Emissao Fim"   	, MV_PAR03, "@D", ""  , ""	   , "" , 050 , .F. } )
AAdd( aParAux , { 1 , "Comprador"     		, MV_PAR04, "@!", ""  ,"F3ITLC", "" , 100 , .F. } )
AAdd( aParAux , { 2 , "SC Urgente"       	, MV_PAR05, {"1-Sim","2-Nao","3-NF","Ambos"}, 100 , ".T." , .F. , ".T." } )
AAdd( aParAux , { 2 , "Aplicacao"        	, MV_PAR06, {"1-Consumo  ","2-Investimento  ","3-Manutencao","4-Servico","Todos"}, 100 , ".T." , .F. , ".T." } )
AAdd( aParAux , { 2 , "Situação"        	, MV_PAR07, {"1-Nao Atendidos","2-Parcial","Ambos"}, 100 , ".T." , .F. , ".T." } )
AAdd( aParAux , { 1 , "Solicitacao"      	, MV_PAR08, "@!", ""  ,"F3ITLC", "" , 100 , .F. } )

For nI := 1 To Len( aParAux )
    AAdd( aParRet , aParAux[nI][03] )
Next nI

If !ParamBox( aParAux , "Indicar Comprador P/sc" , @aParRet, bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	U_ItMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	Break
Else
	If SubStr( MV_PAR01 , 1 , 1 ) == "3"	//Seleciona Filiais
		 ACOMSELFIL()
	EndIf
EndIf

//--------------------------------------------------------
//Retorna as colunas para o preenchimento da FWMarkBrowse
//--------------------------------------------------------
FWMsgRun( ,{|oproc| aAlias := aCom009Qry(oproc) } , 'Aguarde!' , 'Verificando os registros...' )
	
cAliasMrk	:= aAlias[1]
aColumns 	:= aAlias[2]

If !(cAliasMrk)->(Eof())
	//Criação da MarkBrowse
	oMrkBrowse:= FWMarkBrowse():New()
	oMrkBrowse:SetDataTable(.T.)
	oMrkBrowse:SetAlias(cAliasMrk)
	oMrkBrowse:AddMarkColumns( bChkMarca , bSelMarca , bAllMarca )
	oMrkBrowse:SetDescription("")
	oMrkBrowse:SetColumns(aColumns)
	oMrkBrowse:Activate()
Else
	U_ITMsg("Não foram localizadas SCs com os filtros selecionados","Atenção",,1)
EndIf

If !Empty (cAliasMrk)
	DBSelectArea(cAliasMrk)
	DBCloseArea()
	Ferase(cAliasMrk+GetDBExtension())
	Ferase(cAliasMrk+OrdBagExt())
	cAliasMrk := ""
	DBSelectArea("SC1")
	DBSetOrder(1)
EndIf

// Grava log da Rotina responsável por Indicar Comprador para SC 
U_ITLOGACS('ACOM009')

Return (.T.)

/*
===============================================================================================================================
Programa----------: ACOM009Qry
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para montar a query e arquivo temporário
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Array [1] - Tabela temporária / [2] - Colunas do browse
===============================================================================================================================
*/
Static Function aCom009Qry(oproc)

Local cAliasTrb		:= GetNextAlias()		
Local aFields		:= {'C1_FILIAL','C1_EMISSAO','C1_NUM','C1_ITEM','C1_CODCOMP','Y1_NOME','C1_I_CODAP','ZZ7_NOME','C1_PRODUTO','C1_DESCRI','C1_UM','C1_QUANT','C1_QUJE','C1_I_ULTPR','C1_I_ULTDT','C1_I_URGEN','C1_I_APLIC','C1_I_CDINV','ZZI_DESINV','C1_CC','C1_I_DTRET','C1_I_INDIC','C1_I_INDDT','C1_I_INDHR','C7_NUM','C7_ITEM','A2_NREDUZ'}
Local cSelect		:= ""
Local aStructSC1	:= SC1->(DBSTRUCT())
Local aColumns		:= {}
Local nX			:= 0					
Local cTempTab		:= ""
Local cFiliais 		:= SubStr( MV_PAR01 , 1 , 1 )
Local dEmissIni		:= MV_PAR02
Local dEmissFim		:= MV_PAR03
Local cComprador	:= MV_PAR04
Local cUrgente		:= SubStr( MV_PAR05 , 1 , 1 )
Local cAplic		:= SubStr( MV_PAR06 , 1 , 1 )
Local cSituac		:= SubStr( MV_PAR07 , 1 , 1 )
Local cSoliciti		:= MV_PAR08

//Variaveis utilizadas para montar o where da query, referente aos filtros preenchidos pelo usuario.
Local cWFilial		:= ""
Local cWUrgen		:= ""
Local cWAplic		:= ""
Local cWhere		:= ""
Local cWSitu		:= ""

If !Empty(MV_PAR08)
	cSoliciti := FormatIn(AllTrim(MV_PAR08),";") //"%"+FormatIn(AllTrim(MV_PAR04),";")+"%"
EndIf

If !Empty(MV_PAR04)
	cComprador := FormatIn(AllTrim(MV_PAR04),";")
EndIf	

oproc:cCaption := ("Iniciando rotina...")
ProcessMessages()

For nX := 1 To Len(aFields)
	cSelect += aFields[nX] + ", "
Next nX

AAdd(aStructSC1,{"SC1RECNO","N",15,0 })

//======================================
//Tratamento da clausula where da filial
//======================================
If cFiliais == '1'			//Todas as Filiais
	cWFilial := "%"
	cWFilial += " SC1.C1_FILIAL >= '" + Space(TamSX3("C1_FILIAL")[1]) + "' AND SC1.C1_FILIAL <= '" + Replicate("Z", TamSX3("C1_FILIAL")[1]) + "' "
	cWFilial += "%"
ElseIf cFiliais == '2'		//Filial Corrente
	cWFilial := "%"
	cWFilial += " SC1.C1_FILIAL  = '" + xFilial("SC1") + "' "
	cWFilial += "%"
ElseIf cFiliais == '3' 		//Seleciona Filiais
	//Leitura das filiais selecionadas
	cWFilial := "%"
	If Empty(cSelFil)
		cWFilial += " SC1.C1_FILIAL IN ('" + xFilial("SC1") + "') "
	Else
		cWFilial += " SC1.C1_FILIAL IN (" + cSelFil + ") "
	EndIf 
	cWFilial += "%"
EndIf

//Tratamento da clausula where do urgente
If cUrgente == '1'				//Sim
	cWUrgen := "%"
	cWUrgen += " SC1.C1_I_URGEN = 'S' "
	cWUrgen += "%"
ElseIf cUrgente == '2'			//Nao
	cWUrgen := "%"
	cWUrgen += " SC1.C1_I_URGEN = 'N' "
	cWUrgen += "%"
ElseIf cUrgente == '3'			//NF
	cWUrgen := "%"
	cWUrgen += " SC1.C1_I_URGEN = 'F' "
	cWUrgen += "%"
ElseIf cUrgente == 'A'			//NF
	cWUrgen := "%"
	cWUrgen += " SC1.C1_I_URGEN IN (' ','S','N','F') "
	cWUrgen += "%"
EndIf

//Tratamento da clausula where da aplicacao
If cAplic == '1'				//Consumo
	cWAplic := "%"
	cWAplic += " SC1.C1_I_APLIC = 'C' "
	cWAplic += "%"
ElseIf cAplic == '2'			//Investimento
	cWAplic := "%"
	cWAplic += " SC1.C1_I_APLIC = 'I' "
	cWAplic += "%"
ElseIf cAplic == '3'			//Manutenção
	cWAplic := "%"
	cWAplic += " SC1.C1_I_APLIC = 'M' "
	cWAplic += "%"
ElseIf cAplic == '4'			//Serviço
	cWAplic := "%"
	cWAplic += " SC1.C1_I_APLIC = 'S' "
	cWAplic += "%"
ElseIf cAplic == 'T'			//Todos
	cWAplic := "%"
	cWAplic += " SC1.C1_I_APLIC <> ' ' "
	cWAplic += "%"
EndIf

//Tratamento da clausula where da Situação
If cSituac == '1'
	cWSitu := "%"
	cWSitu += " SC1.C1_QUJE = 0 "
	cWSitu += "%"
ElseIf cSituac == '2'
	cWSitu := "%"
	cWSitu += " (SC1.C1_QUJE > 0 AND SC1.C1_QUJE < SC1.C1_QUANT) "
	cWSitu += "%"
ElseIf cSituac == 'A'
	cWSitu := "%"
	cWSitu += " SC1.C1_QUJE < SC1.C1_QUANT "
	cWSitu += "%"
EndIf

cWhere := "%"
If !Empty(MV_PAR08)
	cWhere += " SC1.C1_NUM IN "+cSoliciti+" AND "
EndIf
If !Empty(MV_PAR04)
	cWhere += " SC1.C1_CODCOMP IN "+cComprador+" AND "
Else
	cWhere += " SC1.C1_I_INDIC = ' ' AND "
EndIf
cWhere += " SC1.C1_APROV = 'L' AND "
cWhere += " SC1.C1_RESIDUO <> 'S' "
cWhere += "%"

BeginSql alias cAliasTrb

SELECT ' ' SC1_OK, C1_FILIAL, C1_EMISSAO, C1_NUM, C1_ITEM, C1_CODCOMP, Y1_NOME, C1_I_CODAP, ZZ7_NOME,
        C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_QUJE, C1_I_ULTPR, C1_I_ULTDT, C1_I_URGEN, C1_I_APLIC,
		 C1_I_CDINV, ZZI_DESINV, C1_CC, C1_I_DTRET, C1_DATPRF, C1_OBS, B1_I_DESCD,C1_I_INDIC,C1_I_INDDT,
		 C7_NUM,C7_ITEM,C7_FORNECE,C7_LOJA,(SELECT A2_NREDUZ FROM %Table:SA2% SA2 WHERE SA2.A2_COD = SC7.C7_FORNECE AND
		                                              SA2.A2_LOJA = SC7.C7_LOJA AND SC7.%notDel%) A2_NREDUZ,
		 C1_I_INDHR,SC1.R_E_C_N_O_ SC1RECNO  //SC1_OK é o campo criado para o campo de Marcação
FROM %Table:SC1% SC1
LEFT JOIN %Table:SY1% SY1 ON SY1.Y1_FILIAL = %xFilial:SY1% AND SC1.C1_CODCOMP = SY1.Y1_COD AND SY1.%notDel%
JOIN %Table:ZZ7% ZZ7 ON SC1.C1_FILIAL = ZZ7.ZZ7_FILIAL AND SC1.C1_I_CODAP = ZZ7.ZZ7_CODUSR AND ZZ7.%notDel%
LEFT JOIN %Table:ZZI% ZZI ON SC1.C1_FILIAL = ZZI.ZZI_FILIAL AND SC1.C1_I_CDINV = ZZI.ZZI_CODINV AND ZZI.%notDel%
LEFT JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% AND SB1.B1_COD = SC1.C1_PRODUTO AND SB1.%notDel%
LEFT JOIN %Table:SC7% SC7 ON SC7.C7_FILIAL = SC1.C1_FILIAL AND SC7.C7_NUMSC = SC1.C1_NUM AND SC7.C7_ITEMSC = SC1.C1_ITEM AND SC7.%notDel%
WHERE
	%Exp:cWFilial%							AND
	SC1.C1_EMISSAO BETWEEN %exp:dEmissIni%	AND %exp:dEmissFim% AND
	%Exp:cWUrgen%							AND
	%Exp:cWAplic%							AND
	%Exp:cWSitu%							AND
	%Exp:cWhere%							AND
	SC1.%notDel%
ORDER BY
	C1_FILIAL, C1_EMISSAO, C1_NUM, C1_ITEM, C1_CODCOMP, Y1_NOME, C1_I_CODAP, ZZ7_NOME, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_QUJE, C1_I_ULTPR, C1_I_ULTDT, C1_I_URGEN, C1_I_APLIC, C1_I_CDINV, ZZI_DESINV, C1_CC, C1_I_DTRET, C1_DATPRF, C1_OBS, B1_I_DESCD
EndSql

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
aStruTRB:=(cAliasTrb)->(DBSTRUCT())    
 
If (NpOS:=aScan(aStruTRB,{|A|A[1]=="C1_QUANT"})) <> 0
   aStruTRB[NpOS,3]:=22
EndIf

If (NpOS:=aScan(aStruTRB,{|A|A[1]=="C1_QUJE"})) <> 0
   aStruTRB[NpOS,3]:=22
EndIf

If (NpOS:=aScan(aStruTRB,{|A|A[1]=="C1_I_ULTPR"})) <> 0
   aStruTRB[NpOS,3]:=22
EndIf

If (NpOS:=aScan(aStruTRB,{|A|A[1]=="SC1RECNO"})) <> 0
   aStruTRB[NpOS,3]:=22
EndIf

cTempTab := GetNextAlias()
_otemp := FWTemporaryTable():New( cTempTab,aStruTRB )
_otemp:Create()


(cAliasTrb)->(DBGoTop())

While (cAliasTrb)->(!Eof())

	(cTempTab)->(DBAPPEND())
    If Empty((cAliasTrb)->C7_FORNECE)
       aForn:=ACOM009F1(,cAliasTrb)
    EndIf   
	
	(cTempTab)->C1_FILIAL := (cAliasTrb)->C1_FILIAL
	(cTempTab)->C1_NUM    := (cAliasTrb)->C1_NUM
	(cTempTab)->C1_ITEM   := (cAliasTrb)->C1_ITEM
	(cTempTab)->C7_NUM    := (cAliasTrb)->C7_NUM
	(cTempTab)->C7_ITEM   := (cAliasTrb)->C7_ITEM
	(cTempTab)->C7_FORNECE:= If(Empty((cAliasTrb)->C7_FORNECE),aForn[1],(cAliasTrb)->C7_FORNECE)
	(cTempTab)->C7_LOJA   := If(Empty((cAliasTrb)->C7_FORNECE),aForn[2],(cAliasTrb)->C7_LOJA)
	(cTempTab)->A2_NREDUZ := Posicione("SA2",1,xFilial("SA2")+(cTempTab)->C7_FORNECE+(cTempTab)->C7_LOJA,"A2_NREDUZ")
	(cTempTab)->SC1RECNO  := (cAliasTrb)->SC1RECNO
	(cTempTab)->C1_EMISSAO:= (cAliasTrb)->C1_EMISSAO
	(cTempTab)->C1_CODCOMP:= (cAliasTrb)->C1_CODCOMP
	(cTempTab)->Y1_NOME   := (cAliasTrb)->Y1_NOME
	(cTempTab)->C1_I_INDIC  := (cAliasTrb)->C1_I_INDIC
	(cTempTab)->C1_I_INDDT  := (cAliasTrb)->C1_I_INDDT
	(cTempTab)->C1_I_INDHR  := (cAliasTrb)->C1_I_INDHR
	(cTempTab)->C1_I_CODAP  := (cAliasTrb)->C1_I_CODAP
	(cTempTab)->ZZ7_NOME  := (cAliasTrb)->ZZ7_NOME
	(cTempTab)->C1_PRODUTO  := (cAliasTrb)->C1_PRODUTO
	(cTempTab)->C1_DESCRI  := (cAliasTrb)->C1_DESCRI
	(cTempTab)->B1_I_DESCD  := (cAliasTrb)->B1_I_DESCD
	(cTempTab)->C1_UM  := (cAliasTrb)->C1_UM
	(cTempTab)->C1_QUANT  := (cAliasTrb)->C1_QUANT
	(cTempTab)->C1_QUJE  := (cAliasTrb)->C1_QUJE
	(cTempTab)->C1_I_ULTPR  := (cAliasTrb)->C1_I_ULTPR
	(cTempTab)->C1_I_ULTDT :=  (cAliasTrb)->C1_I_ULTDT
	(cTempTab)->C1_I_URGEN  := (cAliasTrb)->C1_I_URGEN
	(cTempTab)->C1_I_APLIC  := (cAliasTrb)->C1_I_APLIC 
	(cTempTab)->C1_I_CDINV  := (cAliasTrb)->C1_I_CDINV 
	(cTempTab)->ZZI_DESINV  := (cAliasTrb)->ZZI_DESINV
	(cTempTab)->C1_CC  := (cAliasTrb)->C1_CC
	(cTempTab)->C1_I_DTRET  := (cAliasTrb)->C1_I_DTRET
	(cTempTab)->C1_DATPRF  := (cAliasTrb)->C1_DATPRF
	(cTempTab)->C1_OBS  := (cAliasTrb)->C1_OBS
	
	(cAliasTrb)->(DBSkip())

EndDo

If ( Select( cAliasTrb ) > 0 )
	DBSelectArea(cAliasTrb)
	DBCloseArea()
EndIf

oproc:cCaption := ("Montando dados...")
ProcessMessages()

(cTempTab)->( DBGoTop() )
While (cTempTab)->(!Eof())
	
	AAdd( aRegsAll , { (cTempTab)->C1_FILIAL, (cTempTab)->C1_NUM, (cTempTab)->C1_ITEM , (cTempTab)->SC1RECNO } )
	
(cTempTab)->( DBSkip() )
EndDo

(cTempTab)->( DBGoTop() )

For nX := 1 To Len(aFields)
	If	!aFields[nX] == "SC1_OK" .And. aFields[nX] $ cSelect
		AAdd(aColumns,FWBrwColumn():New())
		If aFields[nX] == "C1_EMISSAO" .Or. aFields[nX] == "C1_I_ULTDT" .Or. aFields[nX] == "C1_I_DTRET" .Or. aFields[nX] == "C1_I_INDDT"
			aColumns[Len(aColumns)]:SetData( &("{||SToD(" + aFields[nX] + ")}") )
		Else
			aColumns[Len(aColumns)]:SetData( &("{||" + aFields[nX] + "}") )
		EndIf
		aColumns[Len(aColumns)]:SetTitle(RetTitle(aFields[nX])) 
		aColumns[Len(aColumns)]:SetSize(TamSX3(aFields[nX])[1]) 
		aColumns[Len(aColumns)]:SetDecimal(TamSX3(aFields[nX])[2])
		If "Y1" $ aFields[nX]
			aColumns[Len(aColumns)]:SetPicture(PesqPict("SY1",aFields[nX]))
		ElseIf "ZZ7" $ aFields[nX]
			aColumns[Len(aColumns)]:SetPicture(PesqPict("ZZ7",aFields[nX]))
		ElseIf "ZZI" $ aFields[nX]
			aColumns[Len(aColumns)]:SetPicture(PesqPict("ZZI",aFields[nX]))
		Else
			aColumns[Len(aColumns)]:SetPicture(PesqPict("SC1",aFields[nX]))
		EndIf
	EndIf
Next nX


Return( { cTempTab , aColumns } )

/*
===============================================================================================================================
Programa----------: ACOM009M
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para criação do menu.
Parametros--------: Nenhum
Retorno-----------: aRotina - Opções de menu
===============================================================================================================================
*/
Static Function ACOM009M()     

Local aRot := {}
Private oproc

ADD OPTION aRot Title 'Indicar Comprador'		Action 'FWMsgRun( ,{|oproc| U_ACOM009F(oproc) },"Processando...","Aguarde..." )'		OPERATION 2 ACCESS 0
ADD OPTION aRot Title 'Qtd SC x Comprador'		Action 'FWMsgRun( ,{|oproc| U_ACOM010(oproc) },"Processando","Aguarde..." )'		OPERATION 2 ACCESS 0
ADD OPTION aRot Title 'Visualizar'			Action 'U_Acom009Vis()'						OPERATION 2 ACCESS 0
ADD OPTION aRot Title 'Planilha'			Action 'FWMsgRun( ,{|oproc| U_ACOM009T(oproc) },"Processando...","Aguarde..." )'		OPERATION 2 ACCESS 0

Return(Aclone(aRot))

/*
===============================================================================================================================
Programa----------: ACOM009F
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 29/07/2015
Descrição---------: Função utilizada para fazer a gravação do comprador e data de retorno.
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: aRotina - Opções de menu
===============================================================================================================================
*/
User Function ACOM009F(oproc)

Local aArea			:= FWGetArea()
Local nX			:= 0
Local nI			:= 0
Local nCont			:= 0
Local nLenRegs 		:= 0
Local nOpcC			:= 0

Local oGCNom
Local cGCNom		:= Space(TamSX3("Y1_NOME")[1])
Local oGComp
Local cGComp		:= Space(TamSX3("C1_CODCOMP")[1])
Local oGDTRet
Local dGDTRet		:= Date()
Local oSBtCanc
Local oSBtOK
Local oSComp
Local oSDTRet

Local _cConfig		:= GetMV( "IT_CMWFEP" ,, "001" )
Local _aConfig		:= U_ITCFGEML( _cConfig )
Local _cEmlLog		:= ''
Local _cEmail		:= ''
Local _cTxtCHTM		:= ''//Cabecario
Local _cTxtSCHTM	:= ''//SCs
Local _cTxtRHTM		:= ''//Rodape
Local _cGrupo		:= ''
Local _cChave		:= ''

Local aAlias		:= {}

//Valida se usuário pode usar rotina

DBSelectArea("ZZL")
DBSetOrder(3)


If !(DBSeek(xFilial("ZZL") + __cUserId) .And. ZZL->ZZL_ADMSC == "S")

    U_ITMsg("Usuário não autorizado a indicar comprador!","Ação não permitida","Solicite autorização a area responsavel.",1)
	Return

EndIf

Static oDlg

DEFINE MSDIALOG oDlg TITLE "Indica Comprador" FROM 000, 000  TO 150, 435  PIXEL

	@ 005, 006 SAY oSComp PROMPT "Código Comprador ?" SIZE 051, 007 OF oDlg  PIXEL
    @ 005, 058 MSGET oGComp VAR cGComp SIZE 010, 010 OF oDlg  F3 "SY1" VALID ACOM009R(cGComp, @cGCNom) PIXEL
    @ 021, 058 MSGET oGCNom VAR cGCNom SIZE 151, 010 OF oDlg  READONLY PIXEL
    @ 037, 006 SAY oSDTRet PROMPT "Data Prevista Retorno ?" SIZE 065, 010 OF oDlg PIXEL
    @ 037, 070 MSGET oGDTRet VAR dGDTRet SIZE 039, 010 OF oDlg PIXEL 

	DEFINE SBUTTON oSBtOK	FROM 053, 082 TYPE 01 OF oDlg ENABLE ACTION (Iif(ACOM009B(dGDTRet),(nOpcC := 1, oDlg:End()),nOpcC := 0))
    DEFINE SBUTTON oSBtCanc	FROM 053, 114 TYPE 02 OF oDlg ENABLE ACTION oDlg:End()

ACTIVATE MSDIALOG oDlg CENTERED

If nOpcC == 1

	//====================================================================================================
	// Define o cabecalho do HTML
	//====================================================================================================
	_cTxtCHTM += '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">'
	_cTxtCHTM += '<HTML><HEAD><TITLE>.:: WF Indica Comprador ::.</TITLE>'
	_cTxtCHTM += '<META content="text/html; charset=windows-1252" http-equiv=Content-Type></HEAD>'
	_cTxtCHTM += '<style type="text/css"><!--'
	_cTxtCHTM += 'table.bordasimples { border-collapse: collapse; } '
	_cTxtCHTM += 'table.bordasimples tr td { border:1px solid #777777; } '
	_cTxtCHTM += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cTxtCHTM += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cTxtCHTM += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cTxtCHTM += 'td.dados	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cTxtCHTM += '--></style>'

	nLenRegs := Len(aRegsSC1)

	DBSelectArea("SY1")
	DBSetOrder(1)
	DBSeek(xFilial("SY1") + AllTrim(cGComp))

    _cComprador:=cGComp+" - "+AllTrim(SY1->Y1_NOME)//" / Comprador: "+
    _cCodUser  :=SY1->Y1_USER//" / Cod. Usuario: "+
	_cEmail := AllTrim(UsrRetMail(SY1->Y1_USER))
	_cGrupo := SY1->Y1_GRUPCOM

	//====================================================================================================
	// Define o corpo do HTML
	//====================================================================================================
	_cTxtCHTM += '<BODY>'
	_cTxtCHTM += '<center>'
	_cTxtCHTM += '<img src="http://atendimento.italac.com.br/img/italac-logo-new.jpg"><br>'
	_cTxtCHTM += '<table cellSpacing=0 cellPadding=0 width="950" class="bordasimples">'
	_cTxtCHTM += '  <tr>'
	_cTxtCHTM += '     <td class="totais" colspan="8"><center>Relação das SCs para o comprador: <b>' + AllTrim(SY1->Y1_NOME) + '</b></td>'
	_cTxtCHTM += '  </tr>'

	If nLenRegs > 0

		ProcRegua(nLenRegs)

		_cTxtCHTM += '  <TR>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Filial</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Dt Emissão</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Num SC</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Urgente</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Aplicação</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="32%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Des.Investimento</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Dt Retorno</STRONG></P></TD>'
		_cTxtCHTM += '    <TD width="05%" bgcolor="#D8D8D8" align="center" class="itens"><P><STRONG>Necessidade</STRONG></P></TD>'
		_cTxtCHTM += '  </TR>'
        
		BEGIN TRANSACTION
            _aCapaSC:={}	
            _aCompAnterior:={}	
            _cSCsIndicado:=""
			DBSelectArea('SC1')
			SC1->(DBSetOrder(1))
			_cusername := UsrFullName(__cUserId)
			For nX := 1 To Len(aRegsSC1)

			    If aScan(_aCapaSC,aRegsSC1[nX][1]+aRegsSC1[nX][2]) = 0
                   AAdd(_aCapaSC,aRegsSC1[nX][1]+aRegsSC1[nX][2])
                Else
                   Loop//Para fazer só uma vez por SC, caso tenha marcado mais de um item da SC
			    EndIf

				For nI := 1 To Len(aRegsAll)

					If aRegsSC1[nX][1] == aRegsAll[nI][1] .And. aRegsSC1[nX][2] == aRegsAll[nI][2]
						nCont++

						oproc:cCaption := ('Processando Registros...')
						ProcessMessages()

						SC1->(DBGoTo(aRegsAll[nI][4]))
						_nPosComp:=0
						If !Empty(SC1->C1_CODCOMP) .And. cGComp <> SC1->C1_CODCOMP .And. (_nPosComp:=aScan(_aCompAnterior, {|C|C[1]==SC1->C1_CODCOMP} )) = 0
						   AAdd(_aCompAnterior,{ SC1->C1_CODCOMP , "" , "" })
						   _nPosComp:=Len(_aCompAnterior)
						EndIf
						
						If SC1->C1_CODCOMP <> cGComp .Or. SC1->C1_I_DTRET <> dGDTRet
						   SC1->( RecLock( "SC1" , .F. ) )
						   SC1->C1_CODCOMP := cGComp
						   SC1->C1_I_DTRET := dGDTRet
						   SC1->C1_GRUPCOM := _cGrupo
					       SC1->C1_I_INDIC := AllTrim(_cusername)
					       SC1->C1_I_INDDT := Date()
					       SC1->C1_I_INDHR := Time()
						   SC1->( MSUnLock() )
						EndIf
						
						If aRegsSC1[nX][1] + aRegsSC1[nX][2] <> _cChave

							SC1->(DBGoTo(aRegsAll[nI][4]))
	
							_cTxtAuxHTM := '<TR>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="left">' + SC1->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,SC1->C1_FILIAL,1)) + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="left">' + DToC(SC1->C1_EMISSAO) + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="left">' + SC1->C1_NUM + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="center">' + SC1->C1_I_URGEN + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="center">' + SC1->C1_I_APLIC + '</TD>'
							_cTxtAuxHTM += '  <TD width="32%" class="itens" align="left">' + AllTrim(Posicione("ZZI",1,xFilial("ZZI") + SC1->C1_I_CDINV,"ZZI_DESINV")) + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="left">' + DToC(C1_I_DTRET) + '</TD>'
							_cTxtAuxHTM += '  <TD width="05%" class="itens" align="left">' + DToC(C1_DATPRF) + '</TD>'
							_cTxtAuxHTM += '</TR>'

							_cTxtSCHTM   += _cTxtAuxHTM
							_cSCsIndicado+= SC1->C1_FILIAL+"-"+SC1->C1_NUM+", "
							If _nPosComp > 0 
							   _aCompAnterior[_nPosComp,2]+=_cTxtAuxHTM
							   _aCompAnterior[_nPosComp,3]+=SC1->C1_FILIAL+"-"+SC1->C1_NUM+", "
							EndIf
							
							_cChave := aRegsSC1[nX][1] + aRegsSC1[nX][2]
						EndIf
						
					EndIf

				Next nI

			Next nX
			
		END TRANSACTION

		//====================================================================================================
		// Sessão Indicado por:                   
		//====================================================================================================
		_cTxtRHTM += '<tr>'
		_cTxtRHTM += '	<td class="grupos" align="center" colspan="8">Indicado Por: <b>' + UsrFullName(__cUserId) + '</b></td>'
		_cTxtRHTM += '</tr>'
		_cTxtRHTM += '<tr>'
		_cTxtRHTM += '	<td class="grupos" align="center" colspan="8"><a href="http://www.italac.com.br/">http://www.italac.com.br/</a></td>'
		_cTxtRHTM += '</tr>'
    	_cTxtRHTM += '<tr>'
      	_cTxtRHTM += '	<td class="grupos" align="center" colspan="8"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
    	_cTxtRHTM += '</tr>'

		//====================================================================================================
		// Finaliza a tabela anterior da secao
		//====================================================================================================
		_cTxtRHTM += '</table>'
		_cTxtRHTM += '</center>'
		_cTxtRHTM += '<br>'

		//====================================================================================================
		// Finaliza o HTML.
		//====================================================================================================
		_cTxtRHTM += '</BODY>'
		_cTxtRHTM += '</HTML>' 
		        //Cabecalho+SCS       +RODAPE
        _cTxtHTM:=_cTxtCHTM+_cTxtSCHTM+_cTxtRHTM

		U_ITENVMAIL( _aConfig[01] , _cEmail ,,, 'Protocolo das SC´s indicadas no dia ['+ DToC(Date()) +']' , _cTxtHTM ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cEmlLog )

        _aStatus:={}
        AAdd(_aStatus,{"Atual",_cComprador,_cCodUser,Lower(_cEmail),_cEmlLog,SubStr(_cSCsIndicado,1,Len(_cSCsIndicado)-2)})
        
         For nI := 1 TO Len(_aCompAnterior)

	         If SY1->(DBSeek(xFilial("SY1") + _aCompAnterior[nI,1] ))

	            _cEmailAnt:= UsrRetMail(SY1->Y1_USER)
		                //Cabecalho+SCS                 +RODAPE
                _cTxtHTM:=_cTxtCHTM+_aCompAnterior[nI,2]+_cTxtRHTM
                _cEmlLog:=""

		        U_ITENVMAIL( _aConfig[01] , _cEmailAnt ,,, 'Sua(s) SC(s) foram indicadas para outro comprador no dia ['+ DToC(Date()) +']' , _cTxtHTM ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cEmlLog )
               
                AAdd(_aStatus,{"Anterior",_aCompAnterior[nI,1]+" - "+SY1->Y1_NOME,SY1->Y1_USER,Lower(_cEmailAnt),_cEmlLog,SubStr(_aCompAnterior[nI,3],1,Len(_aCompAnterior[nI,3])-2)})

             EndIf
             
         Next

        If Len(_aStatus) > 0 
   	       U_ITListBox( 'Status do(s) Email(s) para o(s) compradore(s):' , {'Indicação','Comprador','Cod Usuario','Email','Status do envio','SCs Marcadas'} , _aStatus , .T. , 1 )
   	    EndIf

		FWMsgRun( ,{|oproc| aAlias := aCom009Qry(oproc) } , 'Aguarde!' , 'Verificando os registros...' )

		aRegsSC1	:= {}
		
		cAliasMrk	:= aAlias[1]
		aColumns 	:= aAlias[2]
		
		//----------------------
		//Criação da MarkBrowse
		//----------------------
		oMrkBrowse:SetAlias(cAliasMrk)
		oMrkBrowse:Refresh()
		oMrkBrowse:Gotop()
	Else

        U_ITMsg("Não foi selecionado nenhum item para o processamento.","Seleção Inválida","Favor selecionar pelo menos um registro.",1)

	EndIf

EndIf

FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: ACOM009R
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 28/09/2015
Descrição---------: Função utilizada para retornar o nome do comprador caso ele exista, senão retorna mensagem.
Parametros--------: cGComp - Código do Comprador
------------------: cGCNom - Variável que irá receber o nome do comprador
Retorno-----------: lRet - Retorno .T. caso ache o comprador, .F. caso contrário e não deixa seguir o processo
===============================================================================================================================
*/
Static Function ACOM009R(cGComp, cGCNom)

Local aArea			:= FWGetArea()
Local lRet			:= .T.

DBSelectArea("SY1")
DBSetOrder(1)
If DBSeek(xFilial("SY1") + cGComp)
	cGCNom := SY1->Y1_NOME
Else

    U_ITMsg("Código do comprador não encontrado.","Comprador Inválido","Favor verificar o código informado.",1)
	lRet := .F.

EndIf

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: Acom009Vis
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 28/09/2015
Descrição---------: Função utilizada para visualizar um única SC selecionada.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function Acom009Vis()

Local aArea		:= FWGetArea()
Local cFilAntOld := cFilAnt

Private lCopia  := Inclui:=Altera:=.F.//Inica essas variavel por causa do botão visualizar
                           
cFilAnt :=aRegsAll[oMrkBrowse:OBROWSE:NAT][1]

DBSelectArea("SC1")
SC1->(DBSetOrder(1))
If SC1->(DBSeek(aRegsAll[oMrkBrowse:OBROWSE:NAT][1] + aRegsAll[oMrkBrowse:OBROWSE:NAT][2] + aRegsAll[oMrkBrowse:OBROWSE:NAT][3]))
	A110Visual("SC1",SC1->(Recno()),2)
EndIf 

cFilAnt := cFilAntOld
FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: ACOM009B
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 28/09/2015
Descrição---------: Função utilizada para validar a data de retorno.
Parametros--------: dGDTRet - Data de retorno informada
Retorno-----------: lRet - Retorno .T. caso ache o comprador, .F. caso contrário e não deixa seguir o processo
===============================================================================================================================
*/
Static Function ACOM009B(dGDTRet)

Local aArea			:= FWGetArea()
Local lRet			:= .T.

If Empty(dGDTRet)

    U_ITMsg("Data prevista de retorno é obrigatória","Data Prevista Retorno","Favor preencher a data prevista de retorno.",1)
	lRet := .F.

ElseIf dGDTRet < Date() 

   U_ITMsg("Data prevista de retorno menor que Hoje",'Atenção!',"Favor preencher a data prevista de retorno maior ou igual a Hoje.",1)
   lRet := .F.

EndIf

FWRestArea(aArea)
Return(lRet)


/*
===============================================================================================================================
Programa----------: ACOM009T
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/10/2015
Descrição---------: Função criada para gerar tela para exportação dos dados para planilha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM009T()

Local aArea		:= FWGetArea()
Local aCampPla	:= {	'Índice',;
						'Filial',;
						'Dt Emissão',;
						'Núm.SC',;
						'Item',;
						'Núm PC',;
						'Item',;
						'Fornecedor',;
						'Cod. Comprad',;
						'Nome Comp.',;
						'Indicador',;
						'Data Indicação',;
						'Hora Indicação',;			
						'Cod. Aprovad',;
						'Nome Aprov',;
						'Produto',;
						'Descrição',;
						'Descrição Detalhada',;
						'Unid.Medida',;
						'Quantidade',;
						'Quant.em Ped',;
						'Último Preço',;
						'Ult.Compra',;
						'Urgente',;
						'Aplicação',;
						'Investimento',;
						'Desc.Invest.',;
						'Centro Custo',;
						'Data Retorno',;
						'Necessidade',;
						'Observação'}
Local aLogPla	:= {}
Local nCont		:= 1

DBSelectArea(cAliasMrk)
(cAliasMrk)->(DBGoTop())

While !(cAliasMrk)->(Eof())
	AAdd( aLogPla , {	StrZero(nCont++,4),;																		//[1]Índice
						(cAliasMrk)->C1_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,(cAliasMrk)->C1_FILIAL,1)),;	//[2]Filial
						SToD((cAliasMrk)->C1_EMISSAO),;																//[3]Emissão
						(cAliasMrk)->C1_NUM,;																		//[4]Número SC
						(cAliasMrk)->C1_ITEM,;												 						//[5]Item
						(cAliasMrk)->C7_NUM,;																		//[6]Número SC
						(cAliasMrk)->C7_ITEM,;												 						//[7]Item
						(cAliasMrk)->C7_FORNECE + "/" + (cAliasMrk)->C7_LOJA + " - " + (cAliasMrk)->A2_NREDUZ,;     //[8]Item
						(cAliasMrk)->C1_CODCOMP,;										   							//[9]Cod. Comprador
						(cAliasMrk)->Y1_NOME,;											   							//[10]Nome Comprador
						(cAliasMrk)->C1_I_INDIC,;																	//[11]Cod Indicador
						DToC(SToD((cAliasMrk)->C1_I_INDDT)),;														//[12] Data indicação
						(cAliasMrk)->C1_I_INDHR,;																	//[13] Hora indicação
						(cAliasMrk)->C1_I_CODAP,;										  							//[14]Cod. Aprovador
						(cAliasMrk)->ZZ7_NOME,;											   							//[15]Nome Aprovador
						(cAliasMrk)->C1_PRODUTO,;																	//[16]Produto
						(cAliasMrk)->C1_DESCRI,;																	//[17]Descrição
						(cAliasMrk)->B1_I_DESCD,;											   						//[18]Descrição Detalhada
						(cAliasMrk)->C1_UM,;																		//[19]Unidade Medida
						AllTrim(Transform((cAliasMrk)->C1_QUANT,PesqPict("SC1","C1_QUANT"))),;						//[20]Quantidade
						AllTrim(Transform((cAliasMrk)->C1_QUJE,PesqPict("SC1","C1_QUJE"))),;						//[21]Quantidade Entregue
						AllTrim(Transform((cAliasMrk)->C1_I_ULTPR,PesqPict("SC1","C1_I_ULTPR"))),;					//[22]Último Preço
						SToD((cAliasMrk)->C1_I_ULTDT),;											  					//[23]Última Compra
						(cAliasMrk)->C1_I_URGEN,;												  					//[24]Urgente
						(cAliasMrk)->C1_I_APLIC,;												  					//[25]Aplicação
						(cAliasMrk)->C1_I_CDINV,;												 					//[26]Código Investimento
						(cAliasMrk)->ZZI_DESINV,;												 					//[27]Descrição Investimento
						(cAliasMrk)->C1_CC,;																		//[28]Centro de Custo
						SToD((cAliasMrk)->C1_I_DTRET),;											  					//[29]Data Retorno
						SToD((cAliasMrk)->C1_DATPRF),; 											 					//[30]Necessidade
						(cAliasMrk)->C1_OBS} )												   						//[31]Observação
	(cAliasMrk)->(DBSkip())
End

U_ITListBox( 'Geração Planilha' , aCampPla , aLogPla , .T. , 1 )

FWRestArea(aArea)
Return

/*
===============================================================================================================================
Programa----------: ACOM009F1
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/03/2019
Descrição---------: Localiza último fornecedor para um produto na filial
Parametros--------: _ntipo - 1 Retorna código do fornecedor, 2 Retorna código da loja
					_cAlias - alias de trabalho
Retorno-----------: _cret - código do fornecedor ou loja
===============================================================================================================================
*/
Static Function ACOM009F1(_ntipo,_cAlias)

Local _cAliaFor  := GetNextAlias()
Local _c1produto := AllTrim((_cAlias)->C1_PRODUTO) 
Local _cFilSC    := AllTrim((_cAlias)->C1_FILIAL) 
Local dData      := DToS(CTOD("01/01"+Str(YEAR(dDataBase),4)))
Local _aRet      := {"",""}

BeginSql alias _cAliaFor
	SELECT C7_FORNECE,C7_LOJA
	FROM %Table:SC7% SC7
	WHERE	SC7.%notDel%
			AND SC7.C7_FILIAL  = %exp:_cFilSC% 
			AND SC7.C7_PRODUTO = %exp:_c1produto% 
			AND SC7.C7_EMISSAO > %exp:dData% 
	ORDER BY SC7.R_E_C_N_O_ DESC
EndSql

If (_cAliaFor)->(!Eof())
	_aRet := {(_cAliaFor)->C7_FORNECE,(_cAliaFor)->C7_LOJA,}
Else
    (_cAliaFor)->(DBCloseArea())
	BeginSql alias _cAliaFor
		SELECT C7_FORNECE,C7_LOJA
		FROM %Table:SC7% SC7
		WHERE	SC7.%notDel%
		AND SC7.C7_FILIAL  = %exp:_cFilSC%
		AND SC7.C7_PRODUTO = %exp:_c1produto%
		ORDER BY SC7.R_E_C_N_O_ DESC
	EndSql
	If (_cAliaFor)->(!Eof())
		_aRet := {(_cAliaFor)->C7_FORNECE,(_cAliaFor)->C7_LOJA,}
	EndIf	
EndIf

(_cAliaFor)->(DBCloseArea())

Return _aRet

/*
===============================================================================================================================
Programa----------: SelectSC1
Autor-------------: Jose Gavetti
Data da Criacao---: 14/10/2025
Descrição---------: Retorna select da SC1 conforme filtros da tela de seleção
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function SelectSC1()
	
	Local cQrySC1 	:= "" 							As Character
	Local cFiliais  := SubStr( MV_PAR01 , 1 , 1 )   As Character
	Local cUrgente	:= SubStr( MV_PAR05 , 1 , 1 )   As Character
	Local cAplic	:= SubStr( MV_PAR06 , 1 , 1 )   As Character
	Local cSituac	:= SubStr( MV_PAR07 , 1 , 1 )	As Character
	Local cAliasSC1 := GetNextAlias()               As Character
	Local lRet      := .F.                          As Logical

	cQrySC1 := " SELECT DISTINCT C1_NUM , C1_EMISSAO FROM "+RETSQLNAME("SC1")+" SC1 "
	cQrySC1 += " WHERE C1_RESIDUO <> 'S' "
	cQrySC1 += " AND SC1.C1_APROV = 'L' "
	cQrySC1 += " AND D_E_L_E_T_ = ' ' "
	
	//Filial Corrente
	If cFiliais == '2' 
		cQrySC1 += " AND C1_FILIAL  = '" + xFilial("SC1") + "' "
	EndIf

	//Filtro Data Ini Data Fim
	If !Empty(MV_PAR03)
		cQrySC1 += " AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "' "
	ElseIf !Empty(MV_PAR02)
		cQrySC1 += " AND C1_EMISSAO >= '" + DToS(MV_PAR02) + "' "
	EndIf  

	//Filtra comprador
	If !Empty(MV_PAR04)
		cQrySC1 += " AND C1_CODCOMP  IN "+FormatIn(AllTrim(MV_PAR04),";")
	EndIf

	//Filtra SC Urgente
	If cUrgente == '1'				//Sim
		cQrySC1 += " AND SC1.C1_I_URGEN = 'S' "
	ElseIf cUrgente == '2'			//Nao
		cQrySC1 += " AND SC1.C1_I_URGEN = 'N' "
	ElseIf cUrgente == '3'			//NF
		cQrySC1 += " AND SC1.C1_I_URGEN = 'F' "
	ElseIf cUrgente == 'A'			//NF
		cQrySC1 += " AND SC1.C1_I_URGEN IN (' ','S','N','F') "
	EndIf

	//Filtra Aplicação
	If cAplic == '1'				//Consumo
		cQrySC1 += " AND SC1.C1_I_APLIC = 'C' "
	ElseIf cAplic == '2'			//Investimento
		cQrySC1 += " AND SC1.C1_I_APLIC = 'I' "
	ElseIf cAplic == '3'			//Manutenção
		cQrySC1 += " AND SC1.C1_I_APLIC = 'M' "
	ElseIf cAplic == '4'			//Serviço
		cQrySC1 += " AND SC1.C1_I_APLIC = 'S' "
	ElseIf cAplic == 'T'			//Todos
		cQrySC1 += " AND SC1.C1_I_APLIC <> ' ' "
	EndIf
	//Filtra Situação
	If cSituac == '1'
		cQrySC1 += " AND C1_QUJE = 0 "
	ElseIf cSituac == '2'
		cQrySC1 += " AND (C1_QUJE > 0 AND C1_QUJE < C1_QUANT) "
	ElseIf cSituac == 'A'
		cQrySC1 += "AND  C1_QUJE < C1_QUANT "
	EndIf

	cQrySC1 += " ORDER BY 1 " 

	cQrySC1 := ChangeQuery(cQrySC1)
	MPSysOpenQuery(cQrySC1,cAliasSC1)

	If !(cAliasSC1)->(Eof())
		lRet := .T.
	Else
		lRet := .F.
		U_ITMsg("Não foram localizados Solicitantes com os filtros selecionados","Atenção",,1)
	EndIf

Return cQrySC1

//-------------------------------------------------------------------
/*/{Protheus.doc} ACOMSELFIL
Seleciona filiais conforme filtros da rotina  
@Return lRet filiais selecionadas
@author Jose Gavetti
@since  19/11/2025
/*/
//-------------------------------------------------------------------
Static Function ACOMSELFIL() As Logical

	Local aColumns	As Array
	Local aSize     As Array
	Local aStru     aS Array
	Local bOk		As Codeblock
	Local bCancel	As Codeblock
	Local cQuery	As Character
	Local cUrgente	As Character
	Local cAplic    As Character
	Local cSituac	As Character
	Local cArqTrab  As Character
	Local cChave	As Character
	Local lRet		As Logical

	lRet		:= .F.
	cQuery		:= ''
	cChave		:= ''
	cArqTrab    := ''
	aColumns	:= {}
	aSize		:= {}
	aStru       := SM0->(DBSTRUCT())
	bOk			:= {||lRet := GRVSELFIL(cArqTrab),oDlg:End()}
	bCancel		:= {|| oMrkBrowse:Deactivate(),oDlg:End()}
	cUrgente	:= SubStr( MV_PAR05 , 1 , 1 )   
	cAplic		:= SubStr( MV_PAR06 , 1 , 1 )   
	cSituac		:= SubStr( MV_PAR07 , 1 , 1 )	

	If Empty(cArqTrab)
		
		cQuery := " SELECT M0_CODFIL , M0_FILIAL, M0_CGC, COUNT(C1_NUM) AS TOTSOLIC  FROM "+RETSQLNAME("SC1")+" SC1 "
		cQuery += " JOIN SYS_COMPANY ON M0_CODFIL = C1_FILIAL "
		cQuery += " WHERE C1_RESIDUO <> 'S' "
		cQuery += " AND SC1.C1_APROV = 'L' "
		cQuery += " AND SC1.D_E_L_E_T_ = ' ' "

		//Filtro Data Ini Data Fim
		If !Empty(MV_PAR03)
			cQuery += " AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "' "
		ElseIf !Empty(MV_PAR02)
			cQuery += " AND C1_EMISSAO >= '" + DToS(MV_PAR02) + "' "
		EndIf  

		//Filtra comprador
		If !Empty(MV_PAR04)
			cQuery += " AND C1_CODCOMP  IN "+FormatIn(AllTrim(MV_PAR04),";")
		EndIf

		//Filtra SC Urgente
		If cUrgente == '1'				//Sim
			cQuery += " AND SC1.C1_I_URGEN = 'S' "
		ElseIf cUrgente == '2'			//Nao
			cQuery += " AND SC1.C1_I_URGEN = 'N' "
		ElseIf cUrgente == '3'			//NF
			cQuery += " AND SC1.C1_I_URGEN = 'F' "
		ElseIf cUrgente == 'A'			//NF
			cQuery += " AND SC1.C1_I_URGEN IN (' ','S','N','F') "
		EndIf

		//Filtra Aplicação
		If cAplic == '1'				//Consumo
			cQuery += " AND SC1.C1_I_APLIC = 'C' "
		ElseIf cAplic == '2'			//Investimento
			cQuery += " AND SC1.C1_I_APLIC = 'I' "
		ElseIf cAplic == '3'			//Manutenção
			cQuery += " AND SC1.C1_I_APLIC = 'M' "
		ElseIf cAplic == '4'			//Serviço
			cQuery += " AND SC1.C1_I_APLIC = 'S' "
		ElseIf cAplic == 'T'			//Todos
			cQuery += " AND SC1.C1_I_APLIC <> ' ' "
		EndIf
		//Filtra Situação
		If cSituac == '1'
			cQuery += " AND C1_QUJE = 0 "
		ElseIf cSituac == '2'
			cQuery += " AND (C1_QUJE > 0 AND C1_QUJE < C1_QUANT) "
		ElseIf cSituac == 'A'
			cQuery += "AND  C1_QUJE < C1_QUANT "
		EndIf

		cQuery += " GROUP BY M0_CODFIL,M0_FILIAL, M0_CGC " 
		cQuery += " ORDER BY M0_CODFIL " 

		cChave := SM0->(IndexKey())
		aAdd(aStru, {'SM0_OK','C',1,0}) // Adiciono o campo de marca
		aAdd(aStru, { "TOTSOLIC", "N", 10, 0 } )

		cArqTrab := GetNextAlias()
		If _oACOM009 <> Nil
			_oACOM009:Delete()
			_oACOM009	:= Nil
		EndIf

		_oACOM009 := FwTemporaryTable():New(cArqTrab)

		_oACOM009:SetFields(aStru)

		_oACOM009:AddIndex("01", {"M0_CODFIL"})
		_oACOM009:AddIndex("02", {"M0_FILIAL"})
		_oACOM009:AddIndex("03", {"M0_CGC"})

		//Criando a Tabela Temporaria
		_oACOM009:Create()
	
		Processa({||SqlToTrb(cQuery, aStru, cArqTrab)})	// Cria arquivo temporario

	EndIf

	// COLUNA M0_CODFIL
	AAdd(aColumns, FWBrwColumn():New())
	aColumns[Len(aColumns)]:SetData( {|| (cArqTrab)->M0_CODFIL } )
	aColumns[Len(aColumns)]:SetTitle("FILIAL")
	aColumns[Len(aColumns)]:SetSize(2)
	aColumns[Len(aColumns)]:SetPicture("@!")

	// COLUNA M0_FILIAL
	AAdd(aColumns, FWBrwColumn():New())
	aColumns[Len(aColumns)]:SetData( {|| (cArqTrab)->M0_FILIAL } )
	aColumns[Len(aColumns)]:SetTitle("NOME")
	aColumns[Len(aColumns)]:SetSize(30)
	aColumns[Len(aColumns)]:SetPicture("@!")

	// COLUNA M0_CGC
	AAdd(aColumns, FWBrwColumn():New())
	aColumns[Len(aColumns)]:SetData( {|| (cArqTrab)->M0_CGC } )
	aColumns[Len(aColumns)]:SetTitle("CNPJ")
	aColumns[Len(aColumns)]:SetSize(15)
	aColumns[Len(aColumns)]:SetPicture("@R 99.999.999/9999-99")

	// COLUNA TOTAL SOLICITAÇÕES
	AAdd(aColumns, FWBrwColumn():New())
	aColumns[Len(aColumns)]:SetData( {|| (cArqTrab)->TOTSOLIC } )
	aColumns[Len(aColumns)]:SetTitle("TOTAL SOLIC")
	aColumns[Len(aColumns)]:SetSize(10)
	aColumns[Len(aColumns)]:SetPicture("@E 99999")

	If !(cArqTrab)->(Eof())

		aSize := MsAdvSize(,.F.,250)

		DEFINE MSDIALOG oDlg TITLE "Seleciona Filiais" From 200,0 to 600,600 OF oMainWnd PIXEL

		oMrkBrowse := FWMarkBrowse():New()
		oMrkBrowse:oBrowse:SetEditCell(.T.)
		oMrkBrowse:oBrowse:SetMainProc("ACOM009")
		oMrkBrowse:SetFieldMark("SM0_OK")
		oMrkBrowse:SetOwner(oDlg)
		oMrkBrowse:SetAlias(cArqTrab)
		oMrkBrowse:SetProfileId("0007")
		oMrkBrowse:SetMenuDef("")
		oMrkBrowse:AddButton("Confirmar", bOk,,2)
		oMrkBrowse:AddButton("Cancelar", bCancel,,2)
		oMrkBrowse:bMark       := {||}
		oMrkBrowse:bAllMark    := {|| ACOMMARK(oMrkBrowse, cArqTrab)}
		oMrkBrowse:SetMark("X", cArqTrab, "SM0_OK")
		oMrkBrowse:SetDescription("")
		oMrkBrowse:SetColumns(aColumns)
		oMrkBrowse:SetTemporary(.T.)
		oMrkBrowse:Activate()

		ACTIVATE MSDIALOG oDlg CENTERED

	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}GRVSELFIL
Grava em uma string com as filiais selecionadas
@author Jose Gavetti
@since  19/11/2025
/*/
//-------------------------------------------------------------------
Static Function GRVSELFIL( cArqTrab As Character ) As Logical

	Local lRet		As Logical
	Local nRecno	As Numeric
	Local nX		As Numeric

	lRet	:= .F.
	nRecno	:= 0
	nX		:= 0

	DBSelectArea(cArqTrab)
	nRecno := (cArqTrab)->(RecNo())
	(cArqTrab)->(DBGoTop())

	While !(cArqTrab)->(Eof())
		If !Empty((cArqTrab)->SM0_OK)
			cSelFil += "'" + RTrim((cArqTrab)->M0_CODFIL) + "',"
			nX++
		EndIf
		(cArqTrab)->(DBSkip())
	EndDo

	(cArqTrab)->(DBGoTo(nRecno))

	// Remove a última vírgula desnecessária
	If !Empty(cSelFil)
		cSelFil := Substr(cSelFil, 1, Len(cSelFil) - 1)
	EndIf

	lRet := IIf(Len(cSelFil) > 0,.T., .F.)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}ACOMMARK
Marca ou desmarca filiais selecionadas
@author Jose Gavetti
@since  19/11/2025
/*/
//-------------------------------------------------------------------
Static Function ACOMMARK( oMrkBrowse As Object, cArqTrab As Character ) As Logical

	Local cMarca As Character

	cMarca := oMrkBrowse:Mark()

	DBSelectArea(cArqTrab)
	(cArqTrab)->(DBGoTop())

	While !(cArqTrab)->(Eof())
		RecLock(cArqTrab, .F.)
			If (cArqTrab)->SM0_OK == cMarca
				(cArqTrab)->SM0_OK := ' '
			Else
				(cArqTrab)->SM0_OK := cMarca
			EndIf
		MSUnLock()
		(cArqTrab)->(DBSkip())
	EndDo

	(cArqTrab)->(DBGoTop())
	oMrkBrowse:oBrowse:Refresh(.T.)

Return .T.
