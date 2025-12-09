#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: MEST019WS
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina responsavel pelo envio de workflow de solicitação de armazem, CHAMADO 33355
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST19WS()//PARA CHAMAR DO MENU FORMULA

FWMsgRun(,{|oProc|  U_MEST019(oProc) },'Aguarde processamento...','Lendo dados...')
   
Return .T.

/*
===============================================================================================================================
Programa----------: MEST019
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina responsavel pelo envio de workflow de solicitação de armazem, CHAMADO 33355
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST019(oProc)

Local _aTables	 := {"SCP","SCR","ZZ7","ZZ8","ZZI","CTT","ZZL","ZP1"}
Local lWFHTML	 := .T. , _nR , _aRegs
Private _cHostWF := ""
Private _lCriaAmb:= .F.

//Verifica a necessidade de criar um ambiente, caso nao esteja 
//criado anteriormente um ambiente, pois ocorrera erro.        
If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf                           
             
If _lCriaAmb              
	//Nao consome licensas
	RPCSetType(3)

	//seta o ambiente com a empresa 01 filial 01   	 
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_ARMAZEM",_aTables)

	//Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento 
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01901"/*cMsgId*/, "MEST01901 - Gerando envio do workflow das solicitações de armazem aos aprovadores na data: " + DToC(DATE()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf 

Private oModel094 := FWLoadModel('MATA094')

_cHostWF:=SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4003/")
lWFHTML :=SuperGetMv("MV_WFHTML",.T.,.T.)

PutMV("MV_WFHTML",.T.)

U_ITWF1WF2Put("APRVSA","Workflow de Solicitação de armazem" )//Grava WF1 a primeira vez se não existir 
_aRegs := LerNEnviados(.F.)//NÃO ENVIADADOS

_cTot:=AllTrim(Str(Len(_aRegs)))

aLog:={}
_aControleEnv:={}

For _nR := 1 TO Len(_aRegs)
    If ValType(oProc) = "O"
	    oProc:cCaption := "Lendo dados: "+StrZero(_nR,5) +" de "+ _cTot 
	    ProcessMessages()    
    EndIf

    MEST019S(_aRegs[_nR,1]) //Rotina responsável por montar o formulário de aprovação e o envio do link gerado.
Next _nR       

PutMV("MV_WFHTML",lWFHTML)

If _lCriaAmb
	RpcClearEnv()  
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01902"/*cMsgId*/, "MEST01902 - Termino do envio do workflow das solicitações de armazem"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Else
	If Len(aLog) > 0
       aCab:={}
       aAdd(aCab,"Filial")
       aAdd(aCab,"Numero SA")
       aAdd(aCab,"Solicitante")
       aAdd(aCab,"Centro Custo")
       aAdd(aCab,"Aprovador")
       aAdd(aCab,"E-Mail")
       aAdd(aCab,"Status")
       aAdd(aCab,"Produtos...")
       aAdd(aCab,"E-Mail original")
	   _cTitulo:='Lista de Aprovações Enviadas'
   //                           , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
       U_ITListBox(_cTitulo,aCab,aLog   , .T.    , 1    ,       ,          ,        ,         ,     ,        , )
	Else
	   U_ITMsg("Não tem Aprovações para enviar",'Atenção!',,1)
	EndIf
EndIf

Return        

/*
===============================================================================================================================
Programa----------: MEST019S
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina responsável por montar o formulário de aprovação e o envio do link gerado.
Parametros--------: nRegSCR - Recebe o recno do SCR
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST019S(nRegSCR)

Local cEmail      := ""
Local cFilAntSalva:= cFilAnt
Private _cAmbiente:=Upper(GETENVSERVER())

SCR->(DBGoTo(nRegSCR))
SCP->(DBSetOrder(1))
SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))

_cCC_SCP   :=""
_cCC_Fil   :=""
_cMVMEST19E:=""
_cMVM19EOri:=""

If SCP->CP_I_INVES = "S"
   cFilAnt :=SCP->CP_FILIAL//atualiza cFilAnt por causa das funções de pegar U_VLDCC() e SuperGetMv("MV_MEST19E")
   _cCC_SCP:=SubStr(SCP->CP_CC,1,5)
   _cCC_Fil:=U_VLDCC()//Busca os CCs da filial corrente
   _cMVMEST19E:=SuperGetMv("MV_MEST19E",.F.,_cMVMEST19E)
   _cMVM19EOri:=LOWER(_cMVMEST19E)
EndIf

//Codigo do processo cadastrado no CFG
_cCodProce := "APRVSA"
// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\workflow\htm\sa_aprovador.htm"
// Assunto da mensagem
_cAssunto := "Aprovação da Solicitação de Armazem Filial " + SCP->CP_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,SCP->CP_FILIAL,1)) + " / SA Número: " + SCP->CP_NUM

//Inicialize a classe TWFProcess e objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de armazem") //PARA O HTML

cFilSA	:= SCP->CP_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, SCP->CP_FILIAL, 1 ))
cNUMSA	:= SCP->CP_NUM
cSolic	:= Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_NOME")
dDtEmi	:= DToC(SCP->CP_EMISSAO)
cAprNom	:= FWSFAllUsers({SCR->CR_USER},{"USR_NOME"})[1][3]//nome completo
cAprov	:= SCR->CR_APROV+" - "+cAprNom//Pega na avaliacao
cEmail	:= FWSFAllUsers({SCR->CR_USER},{"USR_EMAIL"})[1][3] //SCR->CR_USER//vai pegar o e-mail
cObsGen	:= AllTrim(SCP->CP_OBS)
cCcust	:= SCP->CP_CC +" - "+ AllTrim(Posicione("CTT",1,xFilial("CTT") + SCP->CP_CC,"CTT_DESC01"))

_oProcess:NewTask("Aprovacao_SA", _cHtmlMode)  
_oProcess:oHtml:ValByName("Filial"			, cFilSA)
_oProcess:oHtml:ValByName("NumSA"			, cNUMSA)
_oProcess:oHtml:ValByName("Solicitante"	, cSolic)
_oProcess:oHtml:ValByName("DtEmissao"  	, dDtEmi)
_oProcess:oHtml:ValByName("Aprovador"  	, cAprov)
_oProcess:oHtml:ValByName("CentroCusto"	, cCcust)
_oProcess:oHtml:ValByName("Obs"			   , cObsGen)   
_oProcess:oHtml:ValByName("A_RODAP"	      , _cAmbiente)

//Grava log no server
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01904"/*cMsgId*/, "MEST01904 - S-Filial...........: " + cFilSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01905"/*cMsgId*/, "MEST01905 - S-Solicitacao......: " + cNumSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01906"/*cMsgId*/, "MEST01906 - S-Solicitante......: " + cSolic/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01907"/*cMsgId*/, "MEST01907 - S-Email............: " + cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01908"/*cMsgId*/, "MEST01908 - S-Aprovador........: " + cAprov/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01909"/*cMsgId*/, "MEST01909 - S-Arquivo..........: " + _cHtmlMode/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01910"/*cMsgId*/, "MEST01910 - S-CCusto...........: " + cCcust/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01911"/*cMsgId*/, "MEST01911 - S-Observacao.......: " + cObsGen/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

SB2->(DBSetOrder(1))
nVlrTotOrc:=0
While !SCP->(Eof()) .And. SCR->CR_FILIAL == SCP->CP_FILIAL .And. cNUMSA == SCP->CP_NUM
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01912"/*cMsgId*/, "MEST01912 - S-Produto..........: " + SCP->CP_PRODUTO/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	aAdd( _oProcess:oHtml:ValByName("Itens.Item" 		), SCP->CP_ITEM												)
	aAdd( _oProcess:oHtml:ValByName("Itens.Produto"		), SCP->CP_PRODUTO + " - " + SCP->CP_DESCRI			)
	aAdd( _oProcess:oHtml:ValByName("Itens.UM"			), SCP->CP_UM													)
	aAdd( _oProcess:oHtml:ValByName("Itens.Qtde"		), Transform(SCP->CP_QUANT, PesqPict("SC1","C1_QUANT")) 		)

	SB2->(DBSeek(SCP->CP_FILIAL + SCP->CP_PRODUTO + SCP->CP_LOCAL))
	nValor:=(SB2->B2_CM1 * SCP->CP_QUANT)
	nVlrTotOrc+=nValor
    aAdd( _oProcess:oHtml:ValByName("Itens.Valor") ,"R$ "+AllTrim(Transform( nValor ,"@E 999,999,999,999,999.99"))	)

	SBZ->(DBSeek(SCP->CP_FILIAL + SCP->CP_PRODUTO + SCP->CP_LOCAL))
	aAdd( _oProcess:oHtml:ValByName("Itens.EstMin") , Transform(SBZ->BZ_ESTSEG,PesqPict("SBZ","BZ_ESTSEG")) )
	aAdd( _oProcess:oHtml:ValByName("Itens.EstMax") , Transform(SBZ->BZ_EMAX  ,PesqPict("SBZ","BZ_EMAX"  )) )
    
	nSldAtual:=CalcEst( SCP->CP_PRODUTO, SCP->CP_LOCAL , (Date() + 1) )[1]
	aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), Transform(nSldAtual, PesqPict("SB2","B2_QATU"))	)
	
	nMedia:=MEST19Media(SCP->CP_FILIAL,SCP->CP_PRODUTO,SCP->CP_LOCAL)
	aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), Transform(nMedia   , PesqPict("SB2","B2_QATU"))	)
	
	SCP->(DBSkip())
EndDo

_oProcess:oHtml:ValByName("VlrTot","R$ "+Transform(nVlrTotOrc,"@E 999,999,999,999,999.99"))

// respostas retornar ao Workflow:
_oProcess:bReturn := "U_MEST019R"
	
_cMailID := _oProcess:Start("\workflow\emp01")//GRAVA O HTML
	
If File("\workflow\emp01\" + _cMailID + ".htm")
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01913"/*cMsgId*/, "MEST01913 - Arquivo " + "\workflow\emp01\" + _cMailID + ".htm" + " criado com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf 
	
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01914"/*cMsgId*/, "MEST01914 - Email enviado para: [" + (cEmail) + "]"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//Codigo do processo cadastrado no CFG
_cCodProce := "APRVSA"

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\workflow\htm\sa_aprovador.htm"

// Assunto da mensagem
_cAssunto := "Aprovação da Solicitação de Armazem Filial " + cFilSA + " / SA Número: " + cNUMSA

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess  := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de armazem")//CRIA PARA O ENVIO DO E-MAIL
chtmlfile  := _cMailID + ".htm"
cMailTo	  := "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(SuperGetMv('MV_WFMLBOX')), "WF7_ENDERE"))
chtmltexto := wfloadfile("\workflow\emp01\" + chtmlfile )
chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto) // grava novamente com as alteracoes necessarias.

// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
_oProcess:NewTask("LINK", "\workflow\htm\sa_link.htm")
	
cLink := _cHostWF + "emp01/" + _cMailID + ".htm"

//CORPO DO E-MAIL
_oProcess:oHtml:ValByName("A_RODAP"	, _cAmbiente)
_oProcess:oHtml:ValByName("AprNom"  , cAprNom	)
_oProcess:oHtml:ValByName("MENSAL0" , "Caro(a) Sr(a) ")
_oProcess:oHtml:ValByName("MENSAL1"	, "Existe uma Solicitação ao Armazém pendente para sua avaliação.")
_oProcess:oHtml:ValByName("MENSAL2"	, "Para visualizar e aprovar ou rejeitar o documento utilize o link abaixo:")
_oProcess:oHtml:ValByName("A_LINK"	, cLink		)
_oProcess:oHtml:ValByName("A_EMAIL"	, "Filial: " + cFilSA + " / SA Número: " + cNUMSA + " CLIQUE AQUI")
_oProcess:oHtml:ValByName("A_SOLIC"	, cSolic	)
_oProcess:oHtml:ValByName("A_CUSTO"	, cCcust	)
_oProcess:oHtml:ValByName("A_OBSSA"	, cObsGen	)

// Informamos o destinatário (Aprovador) do email contendo o link.  
cEmailOri:=LOWER(cEmail)
If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   cEmail:= AllTrim(UsrRetMail(__cUserId))
EndIf
_oProcess:cTo := (cEmail)

// Informamos o assunto do email.  
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

_cMailID	:= _oProcess:fProcessId
_cTaskID	:= _oProcess:fTaskID
U_ITWF1WF2Put("APRVSA",,"WFTP01","ENVIADO/AGUARDANDO APROVACAO" )//Grava WF2 a primeira vez se não existir
 //          cStatusCode, cDescription, cUserName, uShape
_oProcess:Track("WFTP01",_cAssunto    ,cSolic)

// Iniciamos a tarefa e enviamos o email ao destinatário.
_oProcess:Start() //ENVIA O E-MAIL
	
U_ITCONOUT("MEST019 - Email enviado para: [" + (cEmail) + "]")

//Atualiza o sistema com as informações do SITWF e IDHTML
_cItens:=""
SCP->(DBSetOrder(1))
SCP->(DBSeek(SCR->CR_FILIAL+cNUMSA))        
While (!SCP->(Eof()) .And. ( SCR->CR_FILIAL+cNUMSA == SCP->CP_FILIAL+SCP->CP_NUM )) 
	SCP->(RecLock("SCP",.F.))
	SCP->CP_I_SITWF:= "2"//Enviado
   SCP->CP_I_HTMWF:=cLink//GRAVA O ARQUIVO PARA USAR NA LISTAGEM DEPOIS
	SCP->(MSUnLock())    		
   _cItens+=AllTrim(SCP->CP_PRODUTO)+" / "
   SCP->(DBSkip())
EndDo
_cItens:=LEFT(_cItens, Len(_cItens)-3 )
SCP->(DBSeek(SCR->CR_FILIAL+cNUMSA))        
aAdd(aLog,{SCR->CR_FILIAL,cNUMSA,cSolic,cCcust,cAprov,LOWER(cEmail),"Enviado [ "+SCP->CP_STATSA+" ]",_cItens,cEmailOri}) 

//GRAVAO LOG NA TABELA ZGT010
_cTipv := Posicione("SA3",1, xFilial("SA3")+LEFT(cAprov,Len(SCR->CR_APROV)), "A3_I_TIPV")
U_GrVLZGT(cFilSA, LEFT(cAprov,Len(SCR->CR_APROV)) , "MESO19-WF-SA", "E", _cTipv , cLink , cNUMSA )

// ENVIA A COPIA DO E-MAIL DE APROVACAO PARA O GESTOR DA FILIAL
If !Empty(_cMVMEST19E) .And. AllTrim(_cCC_SCP) $ _cCC_Fil  
   MEST19CCopia( _oProcess , nRegSCR )
EndIf

cFilAnt:=cFilAntSalva

Return .T.

/*
===============================================================================================================================
Programa----------: MEST19CCopia
Autor-------------: Alex Wallauer
Data da Criacao---: 15/10/2024
Descrição---------: ENVIA A COPIA DO E-MAIL DE APROVACAO PARA O GESTOR DA FILIAL 
Parametros--------: _oProcess - Processo inicializado do workflow / , nRegSCR - Recno do SCR
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MEST19CCopia( _oProcess, nRegSCR  )

SCR->(DBGoTo(nRegSCR))
SCP->(DBSetOrder(1))
SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))

If aScan(_aControleEnv,SCP->CP_FILIAL+SCP->CP_NUM) = 0
   aAdd(_aControleEnv,SCP->CP_FILIAL+SCP->CP_NUM)
Else
   Return .F.//ENVIA UMA COPIA POR FILIAL + Solicitação
EndIf

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\workflow\htm\SA_APROV_COM_COPIA.htm"
// Assunto da mensagem
_cAssunto := "Validação da Solicitação de Armazem Filial " + SCP->CP_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,SCP->CP_FILIAL,1)) + " / SA Número: " + SCP->CP_NUM

//Inicialize a classe TWFProcess e objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Validação da Solicitação de armazem") //PARA O HTML

cFilSA	:= SCP->CP_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, SCP->CP_FILIAL, 1 ))
cNUMSA	:= SCP->CP_NUM
cSolic	:= Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_NOME")
dDtEmi	:= DToC(SCP->CP_EMISSAO)
cEmail	:= FWSFAllUsers({SCR->CR_USER},{"USR_EMAIL"})[1][3] //SCR->CR_USER//vai pegar o e-mail
cObsGen	:= AllTrim(SCP->CP_OBS)
cCcust	:= SCP->CP_CC +" - "+ AllTrim(Posicione("CTT",1,xFilial("CTT") + SCP->CP_CC,"CTT_DESC01"))
cLocInves:= AllTrim(SCP->CP_I_LOCIN)
If Empty(SCP->CP_I_DESIN) .And. !Empty(cLocInves)
   cDescInve:= AllTrim(Posicione("ZZI",1,xFilial("ZZI")+cLocInves,"ZZI_DESINV"))
Else
   cDescInve:= AllTrim(SCP->CP_I_DESIN)
EndIf

_oProcess:NewTask("Aprovacao_SA"          , _cHtmlMode)  
_oProcess:oHtml:ValByName("Filial"			, cFilSA)
_oProcess:oHtml:ValByName("NumSA"			, cNUMSA)
_oProcess:oHtml:ValByName("Solicitante"	, cSolic)
_oProcess:oHtml:ValByName("DtEmissao"  	, dDtEmi)
_oProcess:oHtml:ValByName("LocInvest"     , cLocInves)
_oProcess:oHtml:ValByName("CentroCusto"	, cCcust)
_oProcess:oHtml:ValByName("DescInvest"    , cDescInve)
_oProcess:oHtml:ValByName("Obs"			   , cObsGen)   
_oProcess:oHtml:ValByName("A_RODAP"	      , _cAmbiente)

SB2->(DBSetOrder(1))
nVlrTotOrc:=0
While !SCP->(Eof()) .And. SCR->CR_FILIAL == SCP->CP_FILIAL .And. cNUMSA == SCP->CP_NUM
	aAdd( _oProcess:oHtml:ValByName("Itens.Item" 	), SCP->CP_ITEM												    )
	aAdd( _oProcess:oHtml:ValByName("Itens.Produto"	), SCP->CP_PRODUTO + " - " + SCP->CP_DESCRI			    )
	aAdd( _oProcess:oHtml:ValByName("Itens.UM"		), SCP->CP_UM													    )
	aAdd( _oProcess:oHtml:ValByName("Itens.Qtde"		), Transform(SCP->CP_QUANT, PesqPict("SC1","C1_QUANT")))

	SB2->(DBSeek(SCP->CP_FILIAL + SCP->CP_PRODUTO + SCP->CP_LOCAL))
	nValor:=(SB2->B2_CM1 * SCP->CP_QUANT)
	nVlrTotOrc+=nValor
    aAdd( _oProcess:oHtml:ValByName("Itens.Valor") ,"R$ "+AllTrim(Transform( nValor ,"@E 999,999,999,999,999.99"))	)

	SBZ->(DBSeek(SCP->CP_FILIAL + SCP->CP_PRODUTO + SCP->CP_LOCAL))
	aAdd( _oProcess:oHtml:ValByName("Itens.EstMin") , Transform(SBZ->BZ_ESTSEG,PesqPict("SBZ","BZ_ESTSEG")) )
	aAdd( _oProcess:oHtml:ValByName("Itens.EstMax") , Transform(SBZ->BZ_EMAX  ,PesqPict("SBZ","BZ_EMAX"  )) )
    
	nSldAtual:=CalcEst( SCP->CP_PRODUTO, SCP->CP_LOCAL , (Date() + 1) )[1]
	aAdd( _oProcess:oHtml:ValByName("Itens.SldAtFil"	), Transform(nSldAtual, PesqPict("SB2","B2_QATU"))	)
	
	nMedia:=MEST19Media(SCP->CP_FILIAL,SCP->CP_PRODUTO,SCP->CP_LOCAL)
	aAdd( _oProcess:oHtml:ValByName("Itens.SldAtEmp"	), Transform(nMedia   , PesqPict("SB2","B2_QATU"))	)
	
	SCP->(DBSkip())
EndDo

_oProcess:oHtml:ValByName("VlrTot","R$ "+Transform(nVlrTotOrc,"@E 999,999,999,999,999.99"))

// respostas retornar ao Workflow:
_cMailID := _oProcess:Start("\workflow\emp01")//GRAVA O HTML
	
If File("\workflow\emp01\" + _cMailID + ".htm")
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01913"/*cMsgId*/, "MEST01913 - Arquivo " + "\workflow\emp01\" + _cMailID + ".htm" + " criado com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf 

//Codigo do processo cadastrado no CFG
_cCodProce := "APRVSA"

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\workflow\htm\sa_aprovador.htm"

// Assunto da mensagem
_cAssunto := "Validação da Solicitação de Armazem Filial " + cFilSA + " / SA Número: " + cNUMSA

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess  := TWFProcess():New(_cCodProce,"Validação da Solicitação de armazem")//CRIA PARA O ENVIO DO E-MAIL
chtmlfile  := _cMailID + ".htm"
cMailTo	  := "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(SuperGetMv('MV_WFMLBOX')), "WF7_ENDERE"))
chtmltexto := wfloadfile("\workflow\emp01\" + chtmlfile )
chtmltexto := StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto) // grava novamente com as alteracoes necessarias.

// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
_oProcess:NewTask("LINK", "\workflow\htm\sa_link.htm")
	
cLink := _cHostWF + "emp01/" + _cMailID + ".htm"

//CORPO DO E-MAIL DA COPIA 
_oProcess:oHtml:ValByName("MENSAL0" , "Caro(s) Gestor(es)")
_oProcess:oHtml:ValByName("MENSAL1"	, "Existe uma Solicitação ao Armazém que foi gerada para o centro de custo de investimentos.")
_oProcess:oHtml:ValByName("MENSAL2"	, "Para visualizar utilize o link abaixo:")
_oProcess:oHtml:ValByName("A_LINK"	, cLink		)
_oProcess:oHtml:ValByName("A_EMAIL"	, "Filial: " + cFilSA + " / SA Número: " + cNUMSA + " CLIQUE AQUI")
_oProcess:oHtml:ValByName("A_SOLIC"	, cSolic	)
_oProcess:oHtml:ValByName("A_CUSTO"	, cCcust	)
_oProcess:oHtml:ValByName("A_OBSSA"	, cObsGen	)
_oProcess:oHtml:ValByName("A_RODAP"	, _cAmbiente)

// Informamos o destinatário (Aprovador) do email contendo o link.  
_oProcess:cTo := _cMVMEST19E

// Informamos o assunto do email.  
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

// Iniciamos a tarefa e enviamos o email ao destinatário.
_oProcess:Start() //ENVIA O E-MAIL

SCR->(DBGoTo(nRegSCR))
SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
aAdd(aLog,{SCR->CR_FILIAL,cNUMSA,cSolic,cCcust,"E-mail dos Gestor(es):",LOWER(_cMVMEST19E),"Enviado [ "+SCP->CP_STATSA+" ]",_cItens,_cMVM19EOri}) 

U_ITCONOUT("MEST019 - Email COPIA enviado para: [" + (_cMVMEST19E) + "]")

Return .T.

/*
===============================================================================================================================
Programa----------: MEST019R
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina responsável pela execução do retorno do workflow QAUNDO APERTA APROVAR OU REJEITAR
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST019R( _oProcess )

Local _cFilial	 := SubStr(_oProcess:oHtml:RetByName("Filial"),1,2)
Local _cNumSA	 := _oProcess:oHtml:RetByName("NumSA")    
Local _cAprova	 := Upper(_oProcess:oHtml:RetByName("APROVACAO"))
Local _cAvaliou := Upper(_oProcess:oHtml:RetByName("Aprovador"))//SCR->CR_APROV+" - "+cAprNom
Local _cObs		 := AllTrim( _oProcess:oHtml:RetByName("CP_OBS") )
Local _cArqHtm	 := SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
Local cAprNom   := AllTrim(SubStr(_cAvaliou, At(" ", _cAvaliou)+3 ))//PEGA SÓ O NOME
Local _sDtLiber := DToC(DATE())
Local _cHrLiber := SubStr(TIME(),1,5)
Local _cVlrCampo:= ""
Local _cHtmlMode:= "\Workflow\htm\sa_concluida.htm"
Local _cAmbiente:= Upper(GETENVSERVER())
Local _bType    := {|x| Type(x)}
Private nRegSCR := 0

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01917"/*cMsgId*/, "MEST01917 - INICIO DO MEST019R"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
nConta:=0
cPilha:=""
cProcName:="XX"
While !Empty(cProcName) .And. nConta < 25
   cProcName:=PROCNAME(nConta)
   cPilha:=""
   If !Empty(cProcName)
      aTipo:={};   aArquivo:={};   aLinha:={};   aData:={};   aHora:={}
	  aRet :=GetFuncArray( PROCNAME(nConta),aTipo,aArquivo,aLinha,aData,aHora)

      cPilha+=StrTran(PROCNAME(nConta),"  ","")
      If Eval(_bType,"aArquivo[1]") = "C" 
         cPilha+=" Fonte: ("+aArquivo[1]+")"
      EndIf
      If Eval(_bType,"aData[1]") = "D" 
         cPilha+=" "+DToC(aData[1])
      EndIf
      If Eval(_bType,"aHora[1]") = "C" 
         cPilha+=" "+aHora[1]
      EndIf
      If Eval(_bType,"aLinha[1]") = "C"
         cPilha+=" linha " +aLinha[1]
      EndIf

      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01918"/*cMsgId*/, "MEST01918 - Pilha de chamada...: "+cPilha/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf
   nConta++   
EndDo
//Grava log no server
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01919"/*cMsgId*/, "MEST01919 - E-Filial...........: " + _cFilial/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01920"/*cMsgId*/, "MEST01920 - E-Solicitacao......: " + _cNumSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01921"/*cMsgId*/, "MEST01921 - E-Aprovador........: " + _cAvaliou/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01922"/*cMsgId*/, "MEST01922 - E-Aprovacao........: " + _cAprova/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01923"/*cMsgId*/, "MEST01923 - E-Data Liberacao...: " + _sDtLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01924"/*cMsgId*/, "MEST01924 - E-Hora Liberacao...: " + _cHrLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01925"/*cMsgId*/, "MEST01925 - E-Arquivo..........: " + _cArqHtm/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
//na variavel vem escrito "APROVAR (Aguarde...)"
If "APROVAR" $ _cAprova //== "S"   
   _cAprova:="S"
	_cVlrCampo:= "APROVACAO"
   _cObsConc  := "A solicitação "+_cNumSA+" já foi APROVADA por "+cAprNom+" na <BR> Data: "+_sDtLiber+", Hora: "+_cHrLiber

   U_ITWF1WF2Put("APRVSA",,"WFTP02","APROVADO" )//Grava WF2 a primeira vez se não existir  'N=Não Enviado;E=Enviado/Aguardando Aprovação;Q=Questionado;A=Aprovado;R-Rejeitado'
   _oProcess:Track("WFTP02",_cObsConc,cAprNom)
Else             
   _cAprova:="N"
	_cVlrCampo:= "REJEICAO"		
   _cObsConc  := "A solicitação "+_cNumSA+" já foi REJEITADA por "+cAprNom+" na <BR> Data: "+_sDtLiber+", Hora: "+_cHrLiber+". "
   _cObsConc  += "Entre em contato com o aprovador que rejeitou para maiores informações"
  
   U_ITWF1WF2Put("APRVSA",,"WFTP03","REJEITADO" )//Grava WF2 a primeira vez se não existir  'N=Não Enviado;E=Enviado/Aguardando Aprovação;Q=Questionado;A=Aprovado;R-Rejeitado'
   _oProcess:Track("WFTP03",_cObsConc,cAprNom)
EndIf

If Empty(_cObs)
	_cObs := _cVlrCampo+" EXECUTADA VIA WORKFLOW"
EndIf

//Chama para atualização do registro da solicitação de armazem, com as informações da aprovação/rejeicao
_cErro:=""
lOk:=MyExec094(_cFilial,_cNumSA,_cAprova,@_cErro,LEFT(_cAvaliou,Len(SCR->CR_APROV)),_cArqHtm,_cObs)

If !lOk 
   _cObsConc:= "Houve um problema na hora da "+_cVlrCampo+":<br>"+_cErro
   chtmlfile  := "\workflow\emp01\" + _cArqHtm + ".Erro"
   MemoWrite(chtmlfile,_cObsConc)
   FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01926"/*cMsgId*/, "MEST01926 - Arq do Erro......: " + chtmlfile/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01927"/*cMsgId*/, "MEST01927 - Obs do Erro......: " + _cObsConc/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   MEST019A(_oProcess,_cObsConc,nRegSCR,.T.)//RETORNO QUE ENVIA E-MAIL para o ERRO PARA O APROVADOR

   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01928"/*cMsgId*/, "MEST01928 - FINAL DO MEST019R  1"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   Return .F.
Else
   chtmlfile  := "\workflow\emp01\" + _cArqHtm + ".Erro"
   MemoWrite(chtmlfile,_cObsConc)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01929"/*cMsgId*/, "MEST01929 - Arq do OK......: " + chtmlfile/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01930"/*cMsgId*/, "MEST01930 - Obs do OK......: " + _cObsConc/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

//Finalize a tarefa anterior para não ficar pendente
_oProcess:Finish()

//Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
//         Origem    ,Destino
MEST19Copy(_cHtmlMode,_cArqHtm)

//Alterando o conteudo do \Workflow\htm\sa_concluida.htm 
chtmlfile  := "\workflow\emp01\" + _cArqHtm + ".htm"
chtmltexto := wfloadfile( chtmlfile )
chtmltexto := StrTran( chtmltexto, "!A_MSG!"  , _cObsConc)
chtmltexto := StrTran( chtmltexto, "!A_RODAP!", _cAmbiente)
WFSAVEFILE( chtmlfile , chtmltexto)

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01931"/*cMsgId*/, "MEST01931 - chtmlfile........: " + chtmlfile/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//Faz a cópia dos arquivos arquivos de aprovação para .old, e cria o arquivo de processo já concluído
DBSelectArea("ZGT")
ZGT->(DBSetOrder(2)) //ZGT_FILIAL+ZGT_IDPED                                                                                                                                            
If ZGT->(DBSeek(_cFilial+_cNumSA))
   While ZGT->(!Eof()) .And. ZGT->ZGT_FILIAL+AllTrim(ZGT->ZGT_IDPED) == _cFilial+_cNumSA
      If AllTrim(ZGT->ZGT_ROTINA) = "MESO19-WF-SA"
         _cArqHtm:=Upper(AllTrim(ZGT->ZGT_HTML))
         _cArqHtm:=SubStr(_cArqHtm,AT("EMP01/",_cArqHtm)+6)
         _cArqHtm:=StrTran(_cArqHtm,".HTM","")
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01932"/*cMsgId*/, "MEST01932 - _cArqHtm.........: " + _cArqHtm/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	   //         Origem    ,Destino
         MEST19Copy(chtmlfile,_cArqHtm)
      EndIf 
	   ZGT->(DBSkip())
   EndDo
EndIf

//Grava log no server
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01933"/*cMsgId*/, "MEST01933 - Filial...........: " + _cFilial/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01934"/*cMsgId*/, "MEST01934 - Solicitacao......: " + _cNumSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01935"/*cMsgId*/, "MEST01935 - Aprovador........: " + _cAvaliou/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01936"/*cMsgId*/, "MEST01936 - Aprovacao........: " + _cVlrCampo/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01937"/*cMsgId*/, "MEST01937 - Data Liberacao...: " + _sDtLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01938"/*cMsgId*/, "MEST01938 - Hora Liberacao...: " + _cHrLiber/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01939"/*cMsgId*/, "MEST01939 - Arquivo..........: " + _cArqHtm/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01940"/*cMsgId*/, "MEST01940 - Obs Concluido....: " + _cObsConc/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

MEST019A(_oProcess,_cObsConc,nRegSCR,.F.)//RETORNO QUE ENVIA E-MAIL PARA O SOLICITANTE

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01941"/*cMsgId*/, "MEST01941 - FINAL DO MEST019R  2"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return .T.

/*
===============================================================================================================================
Programa----------: MEST019A
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Função criada aviso ao Solicitante para enviar e-mail de Aprovacao ou Rejeição
Parametros--------: _oProcess - Processo inicializado do workflow
                    _cObsConc - Resultaldo da aprovacao / rejeicao
					nRegSCR   - registro do SCR
					_lErro    - .T. retorno para o aprovador / .F. retorno para o solicitante
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST019A(_oProcess,_cObsConc,nRegSCR,_lErro)

Local _cFilName := _oProcess:oHtml:RetByName("Filial")
Local _cFilSA	 := SubStr(_cFilName,1,2)
Local _cNumSA	 := _oProcess:oHtml:RetByName("NumSA")    
Local _cAprova	 := Upper(_oProcess:oHtml:RetByName("APROVACAO"))
Local _cAvaliou := Upper(_oProcess:oHtml:RetByName("Aprovador"))//SCR->CR_APROV+" - "+cAprNom
Local _cObs		 := AllTrim( _oProcess:oHtml:RetByName("CP_OBS"))
Local _cArqHtm	 := _oProcess:oHtml:RetByName("WFMAILID")
Local _cAprNom  := AllTrim(SubStr(_cAvaliou, At(" ", _cAvaliou)+3 ))//PEGA SÓ O NOME
Local _sDtLiber := DToS(DATE())
Local _cHrLiber := Time()
Local _cAmbiente:= Upper(GETENVSERVER())
Local _cSolic   := ""
Local _cCcust   := ""
Local _cEmail	 := ""
Local _cAssunto := ""

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01942"/*cMsgId*/, "MEST01942 - INCIO DA MEST019A"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess := TWFProcess():New("APRVSA","Aprovação da Solicitação de armazem")//CRIA PARA O ENVIO DO E-MAIL

SCP->(DBSetOrder(1))
If nRegSCR <> 0
   SCR->(DBGoTo(nRegSCR))
   SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
Else
   SCR->(DBGOBOTTOM())
   SCR->(DBSkip())//DEIXA EM REGISTRO EM BRANCO
   SCP->(DBSeek(_cFilSA+AllTrim(_cNumSA)))
EndIf

_cSolic := Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_NOME")
_cEmail := FWSFAllUsers({ZZL->ZZL_CODUSU},{"USR_EMAIL"})[1][3]
_cCcust := SCP->CP_CC +" - "+ AllTrim(Posicione("CTT",1,xFilial("CTT") + SCP->CP_CC,"CTT_DESC01"))

// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
If _lErro
   _oProcess:NewTask("LINK", "\workflow\htm\SA_RET_APROVADOR.htm")
   _cObs:=_cObsConc
   _cEmail := UsrRetMail(SCR->CR_USER)
Else
   _oProcess:NewTask("LINK", "\workflow\htm\sa_solicitante.htm")
EndIf

If "APROVAR" $ _cAprova //== "S" 
   If _lErro
      _cAviso:= "APROVACAO"
   Else
      _cAviso:= "APROVADA"
   EndIf
   _cAvisoC:= "<font color= #0101DF  style='font-size: 12px; font-weight: bold;'>"+_cAviso+"</font>"//AZUL
Else             
   If _lErro
      _cAviso:= "REJEICAO"		
   Else
      _cAviso:= "REJEITADA"
   EndIf
   _cAvisoC:= "<font color= #FF0000  style='font-size: 12px; font-weight: bold;'>"+_cAviso+"</font>"//VERMELHO
EndIf
If Empty(_cObs)
	_cObs := _cAviso+" VIA WORKFLOW"
EndIf

//Grava log no server
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01943"/*cMsgId*/, "MEST01943 - A-Filial...........: " + _cFilSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01944"/*cMsgId*/, "MEST01944 - A-Solicitacao......: " + _cNumSA/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01945"/*cMsgId*/, "MEST01945 - A-Solicitante......: " + _cSolic/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01946"/*cMsgId*/, "MEST01946 - A-Email............: " + _cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01947"/*cMsgId*/, "MEST01947 - A-Aprovador........: " + _cAvaliou/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01948"/*cMsgId*/, "MEST01948 - A-Aprovacao........: " + _cAviso/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01949"/*cMsgId*/, "MEST01949 - A-Arquivo..........: " + _cArqHtm/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01950"/*cMsgId*/, "MEST01950 - A-CCusto...........: " + _cCcust/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01951"/*cMsgId*/, "MEST01951 - A-Observacao.......: " + _cObs/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_oProcess:oHtml:ValByName("A_SOLIC"	  , _cSolic	)
_oProcess:oHtml:ValByName("Num_SA"	  , _cNumSA	)
_oProcess:oHtml:ValByName("Aprovacao" , _cAvisoC)
_oProcess:oHtml:ValByName("AprNom"	  , _cAprNom)
_oProcess:oHtml:ValByName("A_Data"	  , DToC(SToD(_sDtLiber)))
_oProcess:oHtml:ValByName("A_Hora"	  , _cHrLiber)
_oProcess:oHtml:ValByName("A_CUSTO"	  , _cCcust	)
_oProcess:oHtml:ValByName("A_OBSSA"	  , _cObs   )
_oProcess:oHtml:ValByName("A_RODAP"	, 	_cAmbiente	)

// Informamos o destinatário (Aprovador) do email contendo o link.  
cEmailOri:=LOWER(_cEmail)
If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   _cEmail:= UsrRetMail(__cUserId)
EndIf
_oProcess:cTo := _cEmail

// Informamos o assunto do email.  
_cAssunto := "Retorno WF da Solicitação de armazem Filial " + _cFilName + " / SA Número: " + AllTrim(_cNUMSA) + " - " + _cAviso
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

// Iniciamos a tarefa e enviamos o email ao destinatário.
_oProcess:Start() //ENVIA O E-MAIL
	
FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01952"/*cMsgId*/, "MEST01952 - Email enviado para: " + _cEmail + " com sucesso!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

//GRAVAO LOG NA TABELA ZGT010
_cTipv := Posicione("SA3",1, xFilial("SA3")+LEFT(_cAvaliou,Len(SCR->CR_APROV)), "A3_I_TIPV")
U_GrVLZGT(_cFilSA, LEFT(_cAvaliou,Len(SCR->CR_APROV)) , "MESO19-WF-SA", "R", _cTipv , _cArqHtm , _cNumSA )

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01953"/*cMsgId*/, "MEST01953 - FIM DA MEST019A"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return
/*
===============================================================================================================================
Programa----------: MEST19Lista() / MEST019L
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina responsável por montar a lista de SA's por Aprovador e enviar por e-mail
Parametros--------: oproc
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MEST19Lista()

FWMsgRun(,{|oproc|  U_MEST019L(oproc) },'Aguarde processamento...','Lendo dados...')
   
Return .T.

User Function MEST019L(oproc)//Vai ser agendada, chamar via Schedule
Local _lCriaAmb := .F.
Local lWFHTML	 := .T.
Local _aTables	 := {"SC1","SC7","ZZ7","ZZ8","ZZI","CTT","ZZL","ZP1"}
Local _cCodProce:= ""
Local _cAmbiente:= Upper(GETENVSERVER())
Local _cAssunto := ""
Local _cMailId	 := ""
Local _cTaskID	 := ""
Local _aRegs    := {}
Local _oProcess , _nAprv 
Local _cGet     := ""
Private _cHostWF:= ""

If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf                           
             
If _lCriaAmb              
	//Nao consome licensas
	RPCSetType(3)

	//seta o ambiente com a empresa 01 filial 01
	RpcSetEnv("01","01",,,,"SCHEDULE_WF_SOLICITACAO",_aTables)

	//Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento
    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01954"/*cMsgId*/, "MEST01954 - Gerando envio do workflow das solicitações de armazem aos aprovadores na data: " + DToC(DATE()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	_nRet:=1//TODOS
Else
   aBotoes   :={"TODOS","ATUAL","SAIR"}
   cSubTitulo:="Solicitações de Armazem"
   cMensagem :="TODOS - Lista o WF de todos SEM link para aprovar"+CRLF
   cMensagem +="ATUAL - Lista o WF do Usuario logado COM link para aprovar"

   //Aviso( <cTitulo>                       , <cMensagem>, aBotoes>, <nTamTela>, <cSubTitulo>, <nRotAut>, <cBitMap>   , <lEditMemo>, <nTimer> )
   _nRet:=Aviso( "GERAR LISTA DO WORKFLOW ?", cMensagem  , aBotoes , 3         ,  cSubTitulo ,          , "ENGRENAGEM",    .F.     ,          )

   If _nRet = 3//SAIR
      Return .F.
   EndIf
EndIf 

_cHostWF  := SuperGetMV("IT_WFHOSTS",.T.,"http://protheusteste.italac.com.br:11786/workflow/")//http://protheusteste.italac.com.br:11786/workflow/
lWFHTML	 := SuperGetMv("MV_WFHTML",.T.,.T.)
_cCodProce:= "APRVSA"//Codigo do processo cadastrado no CFG
PutMV("MV_WFHTML",.T.)

If !_lCriaAmb              
   oproc:cCaption := ("Lendo dados dos SOLICITAÇÕES DE ARMAZEM...")
   ProcessMessages()
EndIf

_aRegs:=LerNEnviados(.T.)//PEGA TODOS//OS ENVIADOS E NÃO AVALIADOS

_cGet :=SuperGetMv('MV_WFMLBOX')
SCP->(DBSetOrder(1))
aLog:={}
_aLista:={}
For _nAprv := 1 TO Len(_aRegs)
   // Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
   _oProcess := TWFProcess():New(_cCodProce,"Aprovação da Solicitação de armazem")
   _oProcess:NewTask("LINK", "\workflow\htm\sa_lista.htm")

   _cMailId	   := _oProcess:fProcessId
   _cTaskID	   := _oProcess:fTaskID
   chtmlfile	:= _cMailID + ".htm"
   cMailTo		:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(_cGet), "WF7_ENDERE"))
   chtmltexto	:= wfloadfile("\workflow\emp01\" + chtmlfile )
   chtmltexto	:= StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )
   wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto)

   // Assunto da mensagem
   _cAprovador:= _aRegs[_nAprv,2] 
   While _aRegs[_nAprv,2] == _cAprovador
      SCR->(DBGoTo(_aRegs[_nAprv,1]))        
      SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))

      cFilSA	 := SCP->CP_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, SCP->CP_FILIAL, 1 ))
      cNUMSA	 := SCP->CP_NUM
      cSolic	 := Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_NOME")//Login
      cAprNom	 := FWSFAllUsers({SCR->CR_USER},{"USR_NOME"})[1][3]//Codigo
      cAprov	 := SCR->CR_APROV+" - "+cAprNom
      cCcust	 := SCP->CP_CC + " - " + AllTrim(Posicione("CTT",1,xFilial("CTT") + SCP->CP_CC,"CTT_DESC01"))
      _cAssunto := "Aprovação da Solicitação de Armazem Filial "+cFilSA

      If !_lCriaAmb              
         oproc:cCaption := ("Lendo SA: "+cNUMSA+" / Aprovador: "+cAprNom)
         ProcessMessages()
      EndIf

      If _lCriaAmb //SCHEDULE
         cEmail:= UsrRetMail(SCR->CR_USER)
      Else // MENU / TELA
         cEmail:= UsrRetMail(__cUserId)

         If _nRet = 2 .And. SCR->CR_USER <> __cUserId//só mostra o aprovador logado
            _nAprv++
            If _nAprv > Len(_aRegs) 
               Exit
            EndIf
            Loop
         EndIf
         
         _cItens:="" 
         While (!SCP->(Eof()) .And. ( SCR->CR_FILIAL+AllTrim(SCR->CR_NUM) == SCP->CP_FILIAL+SCP->CP_NUM ))
            _cItens+=AllTrim(SCP->CP_PRODUTO)+" / "
            SCP->(DBSkip())
         EndDo
         _cItens:=LEFT(_cItens, Len(_cItens)-3 )
         SCP->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
         If SCP->CP_I_SITWF = "2"//Enviados
            aAdd(_aLista,{SCP->CP_FILIAL,cNUMSA,cSolic,cCcust,cAprov,"Enviado [ "+SCP->CP_STATSA+" ]",_cItens}) 
         ElseIf SCP->CP_I_SITWF = "1"//Não Enviados
            aAdd(_aLista,{SCP->CP_FILIAL,cNUMSA,cSolic,cCcust,cAprov,"Não Enviado [ "+SCP->CP_STATSA+" ]",_cItens})
            _nAprv++
            If _nAprv > Len(_aRegs) 
               Exit
            EndIf
            Loop//SÓ LISTA/ENVIA EMAIL DOS ENVIADOS QUE NÃO FORAM APROVADOS
         EndIf
      EndIf

      aAdd( _oProcess:oHtml:ValByName("itens.FILIAL")	, cFilSA)
      aAdd( _oProcess:oHtml:ValByName("itens.NUMSA")	, cNUMSA)
      aAdd( _oProcess:oHtml:ValByName("itens.SOLIC")	, cSolic)
      aAdd( _oProcess:oHtml:ValByName("itens.CUSTO")	, cCcust)
      If SCR->CR_USER = __cUserId .And. SCP->CP_STATSA = "B" //SÓ MOSTRA O LINK PARA O APROVADOR LOGADO
         aAdd( _oProcess:oHtml:ValByName("itens.LINK")	, AllTrim(SCP->CP_I_HTMWF) )
         aAdd( _oProcess:oHtml:ValByName("itens.Click"), "Clique Aqui" )
      Else//SENÃO NÃO MOSTRA O LINK
         aAdd( _oProcess:oHtml:ValByName("itens.LINK") , " " )
         aAdd( _oProcess:oHtml:ValByName("itens.Click"), " " )
      EndIf

      _nAprv++
      If _nAprv > Len(_aRegs) 
         Exit
      EndIf
   EndDo

	_oProcess:oHtml:ValByName("AprNom"	, cAprNom	)
   _oProcess:oHtml:ValByName("A_RODAP"	, _cAmbiente)
	   		
	// Informamos o destinatário do email contendo o link.  
   cEmailOri:=LOWER(cEmail)
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      cEmail:= UsrRetMail(__cUserId)
   EndIf
	_oProcess:cTo := (cEmail)

	// Informamos o assunto do email.  
	_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

	// Iniciamos a tarefa e enviamos o email ao destinatário.
	_oProcess:Start()
Next _nAprv

PutMV("MV_WFHTML",lWFHTML)

If _lCriaAmb
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   RpcClearEnv()  
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01955"/*cMsgId*/, "MEST01955 - Termino do envio do workflow das solicitações de armazem na data: " + DToC(DATE()) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Else
   If Len(_aLista) > 0
      aCab:={}
      aAdd(aCab,"Filial")
      aAdd(aCab,"Numero SA")
      aAdd(aCab,"Solicitante")
      aAdd(aCab,"Centro Custo")
      aAdd(aCab,"Aprovador")
      aAdd(aCab,"Status")
      aAdd(aCab,"Produtos...")
      _cTitulo:='Lista de Aprovações Pendentes - '+If(_nRet = 2,"ATUAL","TODOS")
      //                           , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,aCab,_aLista   , .T.    , 1    ,       ,          ,        ,         ,     ,        , )
   Else
      U_ITMsg("Não tem Aprovações Pendentes",'Atenção!',,1)
   EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: LerNEnviados
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Rotina para ler os WF não enviados
Parametros--------: _lEnviados: .T. enviados e não avaliados / .F. não enviados 
Retorno-----------: _aRegistros
===============================================================================================================================
*/
Static Function LerNEnviados(_lTodos)

Local _aRegistros:= {}
Local _cQuery    := ""
Local cAlias     := GetNextAlias()
Local cFils      := AllTrim(SuperGetMV("IT_FILIWFS",.T.,"01;40;10;20;23"))

_cQuery := " SELECT DISTINCT SCR.R_E_C_N_O_ REC , SCR.CR_APROV "
_cQuery += "                   FROM " + RetSqlName("SCR") + " SCR "
_cQuery += "                   JOIN " + RetSqlName("ZZL") + " ZZL ON SCR.CR_USER = ZZL.ZZL_CODUSU "
_cQuery += "                   JOIN " + RetSqlName("SCP") + " SCP ON SCR.CR_NUM  = SCP.CP_NUM AND SCR.CR_FILIAL = SCP.CP_FILIAL "
_cQuery += " WHERE SCR.D_E_L_E_T_ = ' ' AND SCP.D_E_L_E_T_ = ' ' AND ZZL.D_E_L_E_T_ = ' ' "
_cQuery += "       AND SCR.CR_FILIAL IN " + FormatIn(cFils,";")
_cQuery += "       AND SCR.CR_TIPO    = 'SA' "
_cQuery += "       AND SCP.CP_EMISSAO >= '20200727' "

If _lTodos .Or. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento//PARA TELA VIA TELA
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento//PODE SER QQ FILTRO PARA TESTES NA HOMOLOGACAO E DESENV
      _cQuery += " AND SCP.CP_I_SITWF <> ' ' "
      _cQuery += " AND SCP.CP_STATSA  =  'B'"
      _cQuery += " AND SCP.CP_I_INVES <> 'S' "
      _cQuery += " AND SCP.CP_EMISSAO >= '20240801' "
   Else// PRODUCAO - LISTA DE APROVAÇÕES ENVIADAS E NÃO AVALIADOS
      _cQuery += " AND SCP.CP_I_SITWF = '2' "//ENVIADOS
      _cQuery += " AND SCP.CP_STATSA  = 'B' "//BLOQUEADOS
   EndIf
Else// PRODUCAO - SCHEDULE - NÃO ENVIADOS
   _cQuery += "    AND SCP.CP_I_SITWF = '1' "//NÃO ENVIADOS
   _cQuery += "    AND SCP.CP_STATSA  = 'B' "//BLOQUEADOS
EndIf

_cQuery += "       AND ZZL.ZZL_LIBSAS = 'S' "
_cQuery += "       ORDER BY 2 "

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery( _cQuery , cAlias )

While (cAlias)->(!Eof())
   aAdd( _aRegistros , { (cAlias)->REC , (cAlias)->CR_APROV }  )
   (cAlias)->(DBSkip())
EndDo

(cAlias)->(DBCloseArea())
DBSelectArea("SCR")

Return _aRegistros

/*
===============================================================================================================================
Programa----------: MyExec094()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: MATA094 - Liberação de Documentos MVC
Parametros--------: cFil.......: Recebe a Filial do documento a ser avaliado
                    _cNum......: Recebe o número do documento a ser avaliado
                    cAprov.....: Seleciona a operação de aprovação de documentos
                    _cErro.....: Recebe o erro do documento
                    _cAprovador: Recebe o código do aprovador do documento
                    _cArqHtm...: Recebe o htm do documento
					     _cObs......: Observação da aprovação / rejeicao
Retorno-----------: .T. ou .F.
===============================================================================================================================*/
Static Function MyExec094(cFil,_cNum,cAprov,_cErro,_cAprovador,_cArqHtm,_cObs)

Local oModel094 := Nil      //-- Objeto que receberá o modelo da MATA094
Local nLenSCR   := Len(SCR->CR_NUM)//-- Controle de tamanho de campo do documento
Local lOk       := .T.      //-- Controle de validação e commit
Local aErro     := {}       //-- Recebe msg de erro de processamento
Local cTipo     := "SA"     //-- Recebe o tipo do documento a ser avaliado

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01956"/*cMsgId*/, "MEST01956 - MYEXEC094 - SCR DBSeek...: [" + cFil + cTipo + PadR(_cNum, nLenSCR) + _cAprovador+"] "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
cFilAnt:=cFil
SCR->(DBSetOrder(3)) //CR_FILIAL+CR_TIPO+CR_NUM+CR_APROV
If SCR->(DBSeek(cFil + cTipo + PadR(_cNum, nLenSCR) + _cAprovador))
   nRegSCR:=SCR->(RECNO())

   //INICA A VARIAVEL cUserName para usar dentro da função RetCodUsr() usada dentro do programa MATA094
   cUserName:= FWSFAllUsers({SCR->CR_USER})[1][3]

   //GRAVA LOG NO SERVER
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01957"/*cMsgId*/, "MEST01957 - MYEXEC094 - cFilAnt .....: " + cFilAnt/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01958"/*cMsgId*/, "MEST01958 - MYEXEC094 - RECNO SCR ...: " + AlltoChar(nRegSCR)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01959"/*cMsgId*/, "MEST01959 - MYEXEC094 - SCR->CR_USER.: " + SCR->CR_USER/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01960"/*cMsgId*/, "MEST01960 - MYEXEC094 - cUserName....: " + cUserName/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01961"/*cMsgId*/, "MEST01961 - MYEXEC094 - RetCodUsr()..: " + RetCodUsr()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01962"/*cMsgId*/, "MEST01962 - MYEXEC094 - _cObs........: " + _cObs/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   //-- Códigos de operações possíveis:
   //--"001" // Liberado *
   //--"002" // Estornar
   //--"003" // Superior
   //--"004" // Transferir Superior
   //--"005" // Rejeitado *
   //--"006" // Bloqueio
   //--"007" // Visualizacao
   //-- Seleciona a operação de aprovação de documentos
   If cAprov = "S"
      A094SetOp('001')// Liberado
   Else
      A094SetOp('005')// Rejeitado
   EndIf
   //-- Carrega o modelo de dados e seleciona a operação de aprovação (UPDATE)
   oModel094 := FWLoadModel('MATA094')
   oModel094:SetOperation( MODEL_OPERATION_UPDATE )
   oFieldSCR:= oModel094:GetModel("FieldSCR")
   oFieldSCR:Activate()
   oFieldSCR:LoadValue("CR_OBS" , _cObs ) 
   oModel094:Activate()
   //-- Valida o formulário
   lOk := oModel094:VldData()
   If lOk
      //-- Se validou, grava o formulário
      lOk := oModel094:CommitData()//oFieldSCR:CommitData() .And.
   EndIf

   If !lOk//-- Avalia erros
      //-- Busca o Erro do Modelo de Dados
      aErro := oModel094:GetErrorMessage()
      //-- Monta o Texto que será mostrado na tela
      _cErro+='Mensagem do erro: [' + AllToChar(aErro[06]) + ']<br>'
      If !Empty(aErro[07])
         _cErro+='Mensagem da solução: [' + AllToChar(aErro[07]) + ']<br>'
      EndIf
      _cErro+='cFilAnt: ' + cFilAnt+'<br>'
      _cErro+='RECNO SCR: ' + AlltoChar(nRegSCR)+'<br>'
      _cErro+='SCR->CR_USER: ' + SCR->CR_USER+'<br>'
      _cErro+='cUserName: ' + cUserName+'<br>'
      _cErro+='RetCodUsr(): ' + RetCodUsr()+'<br>'
   EndIf

   SCP->(DBSetOrder(1))
   SCP->(DBSeek(xFilial("SCP")+_cNum))        
   While (!SCP->(Eof()) .And. ( xFilial("SCP")+_cNum == SCP->CP_FILIAL+SCP->CP_NUM )) 
      SCP->(RecLock("SCP",.F.))
      If lOk    
         SCP->CP_I_SITWF:= "2"//Enviado, marca de novo por garantia
      EndIf
      SCP->CP_I_OBSAP:=_cObs
      SCP->(MSUnLock())    		
      SCP->(DBSkip())        	
   EndDo

   //-- Desativa o modelo de dados
   oModel094:DeActivate()
Else
    _cErro+="Documento não encontrado, Chave: "+cFil + cTipo + AllTrim(_cNum) + _cAprovador+" [ MyExec094 ] "
EndIf 

If lOk
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01963"/*cMsgId*/, "MEST01963 - MYEXEC094 - OK...........: " + If(cAprov="S","APROVADO: ","REJEITADO: ")+_cObs/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Else
   FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01964"/*cMsgId*/, "MEST01964 - MYEXEC094 - ERRO.........: " + _cErro/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

Return lOk

/*
===============================================================================================================================
Programa----------: MEST19Media()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Media dos ultimos 3 meses 
Parametros--------: cFil, cItem, cLocal
Retorno-----------: nMedia
===============================================================================================================================*/
Static Function MEST19Media(cFil,cItem,cLocal)

Local cQry:=""
Local _dDAtaIncio:= Date() - 90
Local nMedia     := 0

cQry += " SELECT D3_EMISSAO, D3_QUANT  "
cQry += " FROM " + RetSqlName("SD3") + " D3 "
cQry += " WHERE D3.D_E_L_E_T_ = ' ' "
cQry += "   AND D3_ESTORNO  <> 'S'   "
cQry += "   AND D3.D3_TM     = '560' "
cQry += "   AND D3.D3_FILIAL = '" + cFil   + "' "
cQry += "   AND D3_COD       = '" + AllTrim(cItem)  + "' "
cQry += "   AND D3.D3_LOCAL  = '" + cLocal + "' "
cQry += "   AND D3.D3_EMISSAO BETWEEN '" + DToS(_dDAtaIncio) + "' AND '" + DToS(DATE()) + "' "//MEDIA

If Select("TRB") <> 0
   TRB->(DBCloseArea())
EndIf
cQry := ChangeQuery(cQry)
MPSysOpenQuery(cQry,"TRB")

TRB->(DBGoTop())
If !TRB->(Eof())
   nMedia+=TRB->D3_QUANT
EndIf
nMedia:=(nMedia/3)

If Select("TRB") <> 0
   TRB->(DBCloseArea())
EndIf

Return nMedia

/*
===============================================================================================================================
Programa----------: MEST19Copy()
Autor-------------: Alex Wallauer
Data da Criacao---: 06/07/2020
Descrição---------: Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
Parametros--------: _cHtmlMode,_cArqHtm
Retorno-----------: nMedia
===============================================================================================================================*/
Static Function MEST19Copy(_cHtmlMode,_cArqHtm)

If Upper("\workflow\emp01\" + _cArqHtm + ".htm") == Upper(_cHtmlMode)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01965"/*cMsgId*/, "MEST01965 - Origem e destino iguais: DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Return .T.
EndIf

If File("\workflow\emp01\" + _cArqHtm + ".htm")
	If __CopyFile("\workflow\emp01\" + _cArqHtm + ".htm", "\workflow\emp01\" + _cArqHtm + ".old")
		If MEST019CP("\workflow\emp01\" + _cArqHtm + ".htm",_cHtmlMode) //Recria _cArqHtm com conteudo do modelo _cHtmlMode
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01966"/*cMsgId*/, "MEST01966 - Cópia do arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm de conclusão efetuada com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
         FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01967"/*cMsgId*/, "MEST01967 - Problema na cópia de arquivo DE "+_cHtmlMode+" PARA \workflow\emp01\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	Else
      FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01968"/*cMsgId*/, "MEST01968 - Não foi possível renomear o arquivo " + _cArqHtm + ".htm."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Else
   FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MEST019"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MEST01969"/*cMsgId*/, "MEST01969 - Arquivo não encontrado \workflow\emp01\" + _cArqHtm + ".htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MEST019CP
Autor-------------: Alex Wallauer
Data da Criacao---: 25/06/2020
Descrição---------: Recria arquivo com conteúdo de outro arquivo
Parametros--------: _cArqDest - Arquivo onde vai gravar o conteudo
					     _cArqOri - Arquivo com conteúdo a ser utilizado
Retorno-----------: _lRet - lógico indicando se completou o processo
===============================================================================================================================
*/
Static Function MEST019CP(_cArqDest,_cArqOri)

Local _lRet := .T.
Local _cconteudo := MemoRead( _cArqOri)

If Empty(_cconteudo)
	_lRet := .F.
EndIf
If _lRet .And. FERASE(_cArqDest)==0 

	_nHandle := FCreate(_cArqDest) 
	If _nHandle > 0
		FClose(_nHandle)
		_lRet := memowrite(_cArqDest,_cconteudo)
	Else
		_lRet := .F.
	EndIf
Else
	_lRet := .F.
EndIf 
	
Return _lRet
