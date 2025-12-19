#Include "RWMake.ch"
#Include "TopConn.ch"
#Include "TOTVS.ch"
#Include "FileIO.ch"	

Static dDataRef := Date()
Static lViaSch	:= GetRemoteType() == -1

/*
===============================================================================================================================
Programa----------: MOMS027
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Programa de Integração com a CISP
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027()

Private oBrowseSZY	:= Nil
Private cCadastro	:= "Integração - CISP"
Private aRotina		:= { 	{ 'Pesquisar'  	, 'AxPesqui'			, 0 , 1 } ,;
							{ 'Visualizar'	, 'U_MOMS027V'			, 0 , 2 } ,;
							{ 'Alterar'		, 'Axaltera'			, 0 , 4 } ,;
							{ 'Excluir'		, 'U_MOMS027D'			, 0 , 5 } ,;
							{ 'Processar'	, 'U_MOMS027X'			, 0 , 3 } ,;
							{ 'Grava TXT'	, 'U_MOMS027T(.F.,.F.)'	, 0 , 7 } ,;
							{ 'Validar'		, 'U_MOMS027L(1,.F.)'	, 0 , 8 } ,;
							{ 'Validar TXT'	, 'U_MOMS027I'			, 0 , 8 }  }


//Grava log de utilização
u_itlogacs()


//===========================================================================
//| Verifica a aplicação do Update do Chamado 5531                          |
//===========================================================================
If AliasInDic("SZY")

	oBrowseSZY := FWMBrowse():New()
	oBrowseSZY:DisableDetails()
	oBrowseSZY:SetAlias("SZY")
	oBrowseSZY:Activate()

Else
	
	U_ITMsg(  "Para utilizar a integração é necessário aplicar a atualização de dicionários 'UPDCISP'." , "Atenção!",,1 )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027X
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de controle da atualização dos dados da base CISP
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027X()

Local cPerg			:= "MOMS027"
Local lThread			:= .F.
Local aparam			:= {cEmpAnt,cFilAnt,.T.,.F.}

//===========================================================================
//| Verifica o acesso do usuário à alteração dos dados da base da CISP      |
//===========================================================================
If !U_ITVLDUSR(4)

	U_ITMsg("Usuário sem acesso à alteração dos dados da base da CISP.","Atenção", "Verifique com a área de TI/ERP.",1)

	Return
	
EndIf


If !Pergunte( cPerg )
	U_ITMsg( "Operação cancelada pelo usuário." , "Atenção!",,1 )
	Return
EndIf

lThread := ( MV_PAR05 == 2 )

//===========================================================================
//| Chama a rotina de processamento                                         |
//===========================================================================
If lThread

	StartJob( "U_MOMS027P" , GetEnvServer() , .F. , Nil , .T. , cEmpAnt , cFilAnt , .T. )
	
	LjMsgRun( "Verificando o ambiente..." , "Aguarde!" , {|| Sleep(2000) } )
	
	
		//seta parâmetros como se fosse JOB
		
		MV_PAR01 := "00000000"
		MV_PAR02 := "99999999"
		MV_PAR03 := "000000"
		MV_PAR04 := "ZZZZZZ"
		MV_PAR05 := 2
		MV_PAR06 := GetMV( "IT_CISPENV" ,, 1 )
			
		U_MOMS027P( aparam , lThread ) //executa como se fosse job mas sem verificar dia da semana permitido
	
Else

	U_MOMS027P( Nil , lThread )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027P
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina que Processa a atualização dos dados da base CISP
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
------------------: cEmpAux		- variável da Empresa para criação do ambiente via JOB
------------------: cFilAux		- variável da Filial para criação do ambiente via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027P( aParam , lThread , cEmpAux , cFilAux , lJobMan )

//Local cDiaSem	:= ""
//Local cDiaAut	:= ""

Default aParam	:= {}
Default lThread := .F.
Default lJobMan	:= .F.

//===========================================================================
//| Verifica a entrada de Parâmetros                                        |
//===========================================================================
If !Empty(aParam) 
	cEmpAux	:= aParam[01]  
	cFilAux	:= aParam[02]
	lThread	:= .T.
	lJobMan	:= .F.
EndIf

//===========================================================================
//| Processa a abertura do ambiente caso a execução seja via JOB            |
//===========================================================================
If lThread
	
	
	//===========================================================================
	//| Prepara o ambiente pra processamento do JOB                             |
	//===========================================================================
	
	u_itconout("Iniciando processo de integracao CISP")
	
	RpcClearEnv()
	RpcSetType(2)
		
	If !RPCSETENV( cEmpAux , cFilAux )
		Return
	EndIf
				
	//===========================================================================
	//| Chama o processo de atualização                                         |
	//===========================================================================
	MOMS027ATU( lThread )
	
Else

	//===========================================================================
	//| Chama o processo de atualização com a janela de acompanhamento          |
	//===========================================================================
	Proc2BarGauge( {|| MOMS027ATU( lThread ) } , "Atualização da Base de Dados" , "Processando..." , "Aguardando o Início..." , .T. )
	
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027ATU
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de atualização dos dados
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027ATU( lThread )

Local _aCodCli	:= {}
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _nnj		:= 0 

Local cAlias	:= GetNextAlias()
Local cPerg		:= "MOMS027"
Local cQuery	:= ""
Local cCodCisp	:= AllTrim( GetMV( "IT_CISPCOD" ,, "0095" ) )
Local cCNPJ		:= ""

Local _dDataDE2	:= YEARSUB( dDataRef , 1 )
Local dDataAc	:= SToD("")
Local dDataAnt	:= SToD("")
Local nVLimCre	:= 0
Local nValorX	:= 0
Local nValorY	:= 0
Local nValorZ	:= 0
Local nValorA	:= 0
Local nValACX	:= 0
Local nValACY	:= 0
Local nValACZ	:= 0
Local nValACA	:= 0
Local nValAVX	:= 0
Local nValAVY	:= 0
Local nValAVZ	:= 0
Local nValAVA	:= 0
Local nValTX	:= 0
Local nValTY	:= 0
Local nValTZ	:= 0
Local nValTA	:= 0
Local nDiasAt	:= 0
Local nSaldo	:= 0
Local nSaldoAC	:= 0
Local nSaldoAnt	:= 0
Local nI		:= 0
Local nTotReg	:= 0
Local nVal05	:= 0
Local nValAc05	:= 0
Local nVal15	:= 0
Local nValAc15	:= 0
Local nVal30	:= 0
Local nValAc30	:= 0
Local nValDebT	:= 0
//Local nValor01	:= 0
//Local nValor02	:= 0
Local _atitulos := {}

Default lThread	:= .F.

//===========================================================================
//| Verifica se a rotina está sendo executada via JOB                       |
//===========================================================================
If lThread
	
	//===========================================================================
	//| Caso necessário inicializa os parâmetros de configuração                |
	//===========================================================================
	If Type(MV_PAR05) <> "N"
	
		Pergunte( cPerg , .F. )
		
		MV_PAR01 := "00000000"
		MV_PAR02 := "99999999"
		MV_PAR03 := "000000"
		MV_PAR04 := "ZZZZZZ"
		MV_PAR05 := 2
		MV_PAR06 := GetMV( "IT_CISPENV" ,, 1 )
		
	EndIf
	
Else

	//===========================================================================
	//| Define a quantidade de Processos                                        |
	//===========================================================================
	BarGauge1Set(04)
	
	//===========================================================================
	//| Inicializa barras de processamento                                      |
	//===========================================================================
	IncProcG1( "Atualização de Clientes [ Processo 01 de 03 ]" )
	ProcessMessage()
	
	IncProcG2( "Lendo registros..." )
	ProcessMessage()

EndIf

u_itconout("Atualização de Clientes [ Processo 01 de 03 ] - Lendo registros...")

//===========================================================================
//| Monta a consulta de atualização do Cadastro de Clientes na base da CISP |
//===========================================================================
cQuery := " SELECT "
cQuery += " 	'1'				   		AS PCTIPO	,"
cQuery += " 	'"+ cCodCisp +"'   		AS PCCASS	,"
cQuery += " 	SubStr(SA1.A1_CGC,1,8)	AS PCCCLI	,"
cQuery += " 	'00000000'		   		AS PCDDAT	,"
cQuery += " 	MIN(SA1.A1_I_DTCAD)		AS PCDCDD	,"
cQuery += " 	'00000000'		 		AS PCDUCM	,"
cQuery += " 	'000000000000000'  		AS PCVULC	,"
cQuery += " 	'00000000'		   		AS PDCMAC	,"
cQuery += " 	'000000000000000'  		AS PCVMAC	,"
cQuery += " 	'000000000000000'  		AS PCVSAT	,"
cQuery += " 	'000000000000000'  		AS PCVLCR	,"
cQuery += " 	'000000'		   		AS PCQPAG	,"
cQuery += " 	'000000'		   		AS PCQDAP	,"
cQuery += " 	'000000000000000'  		AS PCVDAV	,"
cQuery += " 	'000000'		   		AS PCMDAV	,"
cQuery += " 	'000000'		   		AS PCMPMV	,"
cQuery += " 	'000000000000000'  		AS PCDATV	,"
cQuery += " 	'0000'			   		AS PCMTV	,"
cQuery += " 	'000000000000000'		AS PCV15D	,"
cQuery += " 	'0000'					AS PCM15D	,"
cQuery += " 	'000000000000000'		AS PCV30D	,"
cQuery += " 	'0000'					AS PCM30D	,"
cQuery += " 	'00000000'				AS PCDTPC	,"
cQuery += " 	'000000000000000'		AS PCVPCO	,"
cQuery += " 	'2'						AS PCVSIT	,"
cQuery += " 	'0'						AS PCTIPG	,"
cQuery += " 	'00'					AS PCGGA	,"
cQuery += " 	'00000000'				AS PCDTG	,"
cQuery += " 	'000000000000000'		AS PCVLG	,"
cQuery += " 	'000000000000000'		AS PCVPA	,"
cQuery += " 	'  '					AS PCSVV	 "
cQuery += " FROM "+ RetSqlName("SA1") +" SA1 "

cQuery += " WHERE "
cQuery += " 		SA1.D_E_L_E_T_			= ' ' "
cQuery += " AND		SA1.A1_PESSOA			= 'J' "
cQuery += " AND		SA1.A1_FILIAL			= '"+ xFilial("SA1") +"' "
cQuery += " AND		SubStr(SA1.A1_CGC,1,8)	<> '"+ Space(08) +"' "
cQuery += " AND		SubStr(SA1.A1_CGC,1,8)	<> '00000000' "
cQuery += " AND		SA1.A1_I_DTCAD			< '"+ DToS(dDataRef) +"' "
cQuery += " AND		NOT EXISTS				( SELECT SZY.ZY_PCCCLI FROM "+ RetSqlName("SZY") +" SZY WHERE TRIM(SZY.ZY_PCCCLI) = TRIM(SubStr(SA1.A1_CGC,1,8)) AND TRIM(SZY.D_E_L_E_T_) IS NULL ) "
cQuery += " AND		SA1.A1_COD				> '000001' "
cQuery += " AND		SubStr(SA1.A1_CGC,1,8)  BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
cQuery += " AND		SA1.A1_COD  BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' "
cQuery += " AND      SA1.A1_FILIAL = '" + xFilial("SA1") + "'"

cQuery += " GROUP BY SubStr(SA1.A1_CGC,1,8) "
cQuery += " ORDER BY SubStr(SA1.A1_CGC,1,8) "

//===========================================================================
//| Verifica e inicializa os dados para análise                             |
//===========================================================================
If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

nI		:= 0
nTotReg	:= 0

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

//===========================================================================
//| Tratativa das mensagens para processamento via JOB ou Rotina            |
//===========================================================================
If !(lThread)
	
	(cAlias)->( DBEval( {|| nTotReg++ } ) )
	(cAlias)->( DBGoTop() )
	
	BarGauge2Set(nTotReg)

EndIf

//===========================================================================
//| Inclui os Clientes na Base da CISP                                      |
//===========================================================================
While (cAlias)->(!Eof())
	
	nI++
	
	If !lThread
	
		IncProcG2( "["+StrZero(nI,9)+"] de ["+StrZero(nTotReg,9)+"]" )
		ProcessMessage()
	
	EndIf
	
	u_itconout("Atualizando clientes - ["+StrZero(nI,9)+"] de ["+StrZero(nTotReg,9)+"]")

	If !SZY->( DBSeek( xFilial("SZY") + (cAlias)->PCCCLI ) )
	
		SZY->( RecLock( "SZY" , .T. ) )
		
			SZY->ZY_FILIAL	:= xFilial("SZY")
			SZY->ZY_PCTIPO	:= (cAlias)->PCTIPO
			SZY->ZY_PCCASS	:= (cAlias)->PCCASS
			SZY->ZY_PCCCLI	:= (cAlias)->PCCCLI
			SZY->ZY_PCDCDD	:= SToD( (cAlias)->PCDCDD	)
			SZY->ZY_PCVULC	:= Val( (cAlias)->PCVULC	)
			SZY->ZY_PCVMAC	:= Val( (cAlias)->PCVMAC	)
			SZY->ZY_PCVSAT	:= Val( (cAlias)->PCVSAT	)
			SZY->ZY_PCVLCR	:= Val( (cAlias)->PCVLCR	)
			SZY->ZY_PCQPAG	:= Val( (cAlias)->PCQPAG	)
			SZY->ZY_PCQDAP	:= Val( (cAlias)->PCQDAP	)
			SZY->ZY_PCVDAV	:= Val( (cAlias)->PCVDAV	)
			SZY->ZY_PCMDAV	:= Val( (cAlias)->PCMDAV	)
			SZY->ZY_PCMPMV	:= Val( (cAlias)->PCMPMV	)
			SZY->ZY_PCDATV	:= Val( (cAlias)->PCDATV	)
			SZY->ZY_PCMPTV	:= Val( (cAlias)->PCMTV		)
			SZY->ZY_PCV15D	:= Val( (cAlias)->PCV15D	)
			SZY->ZY_PCM15D	:= Val( (cAlias)->PCM15D	)
			SZY->ZY_PCV30D	:= Val( (cAlias)->PCV30D	)
			SZY->ZY_PCM30D	:= Val( (cAlias)->PCM30D	)
			SZY->ZY_PCVPCO	:= Val( (cAlias)->PCVPCO	)
			SZY->ZY_PCVSIT	:= (cAlias)->PCVSIT
			SZY->ZY_PCTIPG	:= (cAlias)->PCTIPG
			SZY->ZY_PCGGA	:= (cAlias)->PCGGA
			SZY->ZY_PCDTG	:= SToD( (cAlias)->PCDTG	)
			SZY->ZY_PCVLG	:= Val( (cAlias)->PCVLG		)
			SZY->ZY_PCVPA	:= Val( (cAlias)->PCVPA		)
			SZY->ZY_PCSVV	:= (cAlias)->PCSVV
			
		SZY->(MSUnLock())
		
	EndIf
	
(cAlias)->(DBSkip())
EndDo

(cAlias)->( DBCloseArea() )

//===========================================================================
//| Tratativa das mensagens para processamento via JOB ou Rotina            |
//===========================================================================
If !(lThread)

	//===========================================================================
	//| Inicializa barras de processamento                                      |
	//===========================================================================
	IncProcG1( "Atualização de Valores [ Processo 02 de 03 ]" )
	ProcessMessage()
	
	BarGauge2Set(0)
	IncProcG2( "Lendo registros..." )
	ProcessMessage()

EndIf

u_itconout("Atualização de Valores [ Processo 02 de 03 ] - Lendo registros...")

//===========================================================================
//| Monta consulta para análise dos Valores dos Clientes                    |
//===========================================================================
cQuery := " SELECT "
cQuery += " 	SubStr(SA1.A1_CGC,1,8)	AS CNPJ, "
cQuery += " 	SA1.A1_COD AS A1_COD, "
cQuery += " 	SA1.A1_LOJA AS A1_LOJA, "
cQuery += " 	SE1.E1_EMISSAO			AS DATACC, "
cQuery += " 	SE1.E1_VALOR + SE1.E1_SDACRES + SE1.E1_JUROS - SE1.E1_SDDECRE AS VALOR, "
cQuery += " 	SE1.E1_SALDO			AS SALDO, "
cQuery += " 	SE1.E1_VENCREA AS VENCTO, "
cQuery += " 	SE1.E1_FILIAL			, "
cQuery += " 	SE1.E1_PREFIXO			, "
cQuery += " 	SE1.E1_NUM			, "
cQuery += " 	SE1.E1_PARCELA			, "
cQuery += " 	SE1.E1_TIPO			, "
cQuery += " 	SE1.E1_CLIENTE			, "
cQuery += " 	SE1.E1_LOJA			, "
cQuery += " 	1              AS ORDEM "

cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "

cQuery += " INNER JOIN "+ RetSqlName("SA1") +" SA1 ON "
cQuery += " 	SE1.E1_CLIENTE			= SA1.A1_COD "
cQuery += " AND	SE1.E1_LOJA				= SA1.A1_LOJA "
cQuery += " AND	SA1.D_E_L_E_T_			= ' ' "
cQuery += " AND	SA1.A1_FILIAL			= '"+ xFilial("SA1") +"' "
cQuery += " AND	SA1.A1_PESSOA			= 'J' "

cQuery += " WHERE "
cQuery += " 	SE1.D_E_L_E_T_			= ' ' "
cQuery += " AND	SE1.E1_I_AVACC <> 'N' " 
cQuery += " AND	SE1.E1_TIPO				NOT IN ('NCC','RA', 'NDC') "
cQuery += " AND	SE1.E1_CLIENTE			> '000001' "
cQuery += " AND	SubStr(SA1.A1_CGC,1,8)	BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
cQuery += " AND	SE1.E1_EMISSAO			< '"+ DToS( dDataRef ) +"' "
cQuery += " AND SE1.E1_VENCREA > '" + DToS(dDataRef - 1825) +"' "
cQuery += " AND	SA1.A1_COD  BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' "     
cQuery += " AND SA1.A1_FILIAL = '" + xFilial("SA1") + "'"
cQuery += " ORDER BY CNPJ, DATACC, ORDEM "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

If !(lThread)
	
	IncProcG2( "Preparando tabela temporária..." )
	ProcessMessage()

EndIf

u_itconout("Atualização de Valores [ Processo 02 de 03 ] - Preparando tabela temporária...")

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

//===========================================================================
//| Inicializa o ambiente e Processa a leitura e gravação dos dados         |
//===========================================================================
DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

nI			:= 0
nTotReg		:= 0

//===========================================================================
//| Tratativa das mensagens para processamento via JOB ou Rotina            |
//===========================================================================
(cAlias)->( DBEval( {|| nTotReg++ } ) )
(cAlias)->( DBGoTop() )

If !(lThread)
	
	BarGauge2Set(nTotReg)

EndIf

//===========================================================================
//| Processa a análise e gravação dos dados                                 |
//===========================================================================
While !(cAlias)->(Eof())

	//===========================================================================
	//| Variáveis de controle                                                   |
	//===========================================================================
	cCNPJ		:= (cAlias)->CNPJ
	
	//Verifica se já foi gravado
	DBSelectArea("SZY")
	SZY->( DBSetOrder(1) )
	If SZY->( DBSeek( xFilial("SZY") + cCNPJ ) ) .And. SZY->ZY_PCDDAT == dDataRef
	
		nI++
		u_itconout("Atualização de Valores [ Processo 02 de 03 ] - ["+StrZero(nI,9)+"] de ["+StrZero(nTotReg,9)+"]")
	
		(cAlias)->(DBSkip())
		Loop
		
	EndIf
	
	nVLimCre	:= U_MOMS027K((cAlias)->A1_COD,(cAlias)->A1_LOJA)
	
	
	//===========================================================================
	//| Variáveis dos Cálculos das Médias                                       |
	//===========================================================================
	nValorX		:= 0
	nValorY		:= 0
	nValorZ		:= 0
	nValorA		:= 0
	nValACX		:= 0
	nValACY		:= 0
	nValACZ		:= 0
	nValACA		:= 0
	nValAVX		:= 0
	nValAVY		:= 0
	nValAVZ		:= 0
	nValAVA		:= 0
	nValTX		:= 0
	nValTY		:= 0
	nValTZ		:= 0
	nValTA		:= 0
	nDiasAt		:= 0
	nValTOT		:= 0
	
	//===========================================================================
	//| Variáveis de Atualização dos Saldos do Cliente                          |
	//===========================================================================
	nSaldo		:= 0
	nSaldoAC	:= 0
	dDataAc		:= SToD("")
	nSaldoAnt	:= 0
	dDataAnt	:= SToD("")
	
	//===========================================================================
	//| Variáveis de Atualização da Penúltima e Última compra do Cliente        |
	//===========================================================================
	nValUC		:= 0
	dDataUC		:= SToD("")
	nValPC		:= 0
	dDataPC		:= SToD("")
	
	//===========================================================================
	//| Variáveis do cálculo de atrasos dos Clientes                            |
	//===========================================================================
	nDiasAtr	:= 0
	nVal05		:= 0
	nValAc05	:= 0
	nVal15		:= 0
	nValAc15	:= 0
	nVal30		:= 0
	nValAc30	:= 0
	nValDebT	:= 0
	
	//Array de titulos acumulados
	_atitulos := {}
	
	While !(cAlias)->(Eof()) .And. (cAlias)->CNPJ == cCNPJ
	
		nI++
		
		If !lThread
		
			IncProcG2("["+StrZero(nI,9)+"] de ["+StrZero(nTotReg,9)+"]")
			ProcessMessage()
		
		EndIf
		
		u_itconout("Atualização de Valores [ Processo 02 de 03 ] - ["+StrZero(nI,9)+"] de ["+StrZero(nTotReg,9)+"]")
 		
		//===========================================================================
		//| Construção do Saldo através da C.C. do Cliente                          |
		//===========================================================================
		If SToD( (cAlias)->DATACC ) >= _dDataDE2 .And. (cAlias)->ORDEM == 1
					
			aAdd(_atitulos,{(cAlias)->(Recno()),; 	//1
				0,;						//2
				(cAlias)->E1_FILIAL,;	//3
				 (cAlias)->E1_PREFIXO,;	//4
				 (cAlias)->E1_NUM,;		//5
				 (cAlias)->E1_PARCELA,;	//6
				 (cAlias)->VALOR,;		//7
				 (cAlias)->E1_TIPO,;	//8
				 (cAlias)->E1_CLIENTE,;	//9
				 (cAlias)->E1_LOJA,;   //10
				 (cAlias)->DATACC ,;  //11
				  { }             } )	//12

			_atitulos[Len(_atitulos)][12] := MOMS0278(_atitulos[Len(_atitulos)] )
			nSaldo := 0
		
			//Roda todos os titulos anteriores para pegar os saldos no dia do novo titulo
			For _nnj := 1 to Len(_atitulos)
				
				nSaldo += MOMS0279(_atitulos[_nnj][12],(cAlias)->DATACC)
			
			Next

			//===========================================================================
			//| Não permite saldo negativo por conta de pagamento de Juros/Multa        |
			//===========================================================================
			If nSaldo < 0
				nSaldo := 0
			EndIf
		
			_atitulos[Len(_atitulos)][2] := nSaldo		
							
			//===========================================================================
			//| Atualização dos dados de Maior Acúmulo do Cliente                       |
			//===========================================================================
			If nSaldo >= nSaldoAc

				nSaldoAc	:= nSaldo
				dDataAc		:= SToD( (cAlias)->DATACC )

			EndIf
						
		EndIf
		
	(cAlias)->(DBSkip())
	EndDo
		
	
	//===============================================================================================
	// Cálculo das Médias de Atraso
	//===============================================================================================
	_aCodCli	:= {}
	_cQuery	:= " SELECT SA1.A1_COD,SA1.A1_LOJA,A1_I_DTCAD FROM "
	_cQuery	+= RetSqlName('SA1') +" SA1 WHERE SA1.D_E_L_E_T_ = ' ' AND SubStr( SA1.A1_CGC , 1 , 8 ) = '"+ AllTrim( cCNPJ ) +"' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
		
	If (_cAlias)->( !Eof() )
	
			_ccodcli := (_cAlias)->A1_COD
			_clojacli := (_cAlias)->A1_LOJA
			
								
			(_cAlias)->( DBCloseArea() )
		
			_cQuery := " SELECT "
			_cQuery += "     SE1.E1_VENCREA AS VENCTO,"
			_cQuery += "     SE1.E1_BAIXA   AS BAIXA ,"
			_cQuery += "     SE1.E1_VALOR   AS VALOR,  "
			_cQuery += "     SE1.E1_SALDO   AS SALDO  "
			_cQuery += " FROM "+ RetSqlName('SE1') +" SE1 "
			_cQuery += " WHERE "
			_cQuery += "      SE1.D_E_L_E_T_ = ' ' "   
			_cQuery += " AND  SE1.E1_CLIENTE = '"+ _ccodcli +"' "
			_cQuery += " AND  SE1.E1_TIPO    NOT IN ('NCC','RA','NDC') "
			_cQuery += " AND  SE1.E1_I_AVACC <> 'N' "
			_cQuery += " AND  SE1.E1_CLIENTE > '000001' "
			_cQuery += " AND  SE1.E1_VENCREA > '" + DToS(dDataRef - 1825) +"' "
			_cQuery += " AND  SE1.E1_EMISSAO < '"+ DToS( dDataRef ) +"' "
	
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )
			While (_cAlias)->( !Eof() )
			
			
				//==========================================================================
				// Soma total dos titulos em aberto
				//==========================================================================
				nValTX += (_cAlias)->SALDO								// Soma o valor dos títulos 
				nValTY += nDiasAt										// Soma a quantidade de dias  do Cliente
				nValTZ += ( (_cAlias)->SALDO * nDiasAt )				// Soma a quantidade de dias x valor do título 
				nValTA++												// Soma a quantidade de titulos 
	
			
				//===========================================================================
				//| Guarda os valores a vencer para os calculos                             |
				//===========================================================================
				If SToD( (_cAlias)->VENCTO ) > dDataRef .And. (_cAlias)->SALDO > 0
			
					nDiasAt := SToD( (_cAlias)->VENCTO ) - dDataRef
					
			      	If nDiasAt < 0
			      	
			      		nDiasAt := 0
		        	
		        	EndIf
		
	        	
					nValAVX += (_cAlias)->SALDO								// Soma o valor dos títulos a vencer
					nValAVY += nDiasAt										// Soma a quantidade de dias a vencer do Cliente
					nValAVZ += ( (_cAlias)->SALDO * nDiasAt )				// Soma a quantidade de dias a vencer x valor do título a vencer
					nValAVA++												// Soma a quantidade de titulos a vencer
				
				EndIf
			
				//===========================================================================
				//| Calcula os Saldos e Médias de Títulos em Aberto e em Atraso             |
				//===========================================================================
				If (_cAlias)->SALDO > 0 
            
					nDiasAtr := dDataRef - SToD( (_cAlias)->VENCTO )
				
					If nDiasAtr > 5
						nVal05		+= Round( (_cAlias)->SALDO , 2 )
						nValAc05	+= Round( nDiasAtr * (_cAlias)->SALDO , 2 )
					EndIf
				
					If nDiasAtr > 15
						nVal15		+= Round( (_cAlias)->SALDO , 2 )
						nValAc15	+= Round( nDiasAtr * (_cAlias)->SALDO , 2 )
					EndIf
				
					If nDiasAtr > 30
						nVal30		+= Round( (_cAlias)->SALDO , 2 )
						nValAc30	+= Round( nDiasAtr * (_cAlias)->SALDO , 2 )
					EndIf
			
				EndIf
	
			
				//===============================================================================================
				// Guarda valores dos Títulos Baixados para o Cálculo das Médias de Atraso
				//===============================================================================================
		       	If (_cAlias)->SALDO = 0 
		       	
		       		If SToD( (_cAlias)->BAIXA ) > SToD( '19900101' )
		       	
		       			nDiasAt := SToD( (_cAlias)->BAIXA ) - SToD( (_cAlias)->VENCTO )
		       		
		       		Else
		       	
		       			nDiasAt := dDataRef - SToD( (_cAlias)->VENCTO )
		       	
		       		EndIf
		        
		       		If nDiasAt < 0
		       			nDiasAt := 0
		       		EndIf
		        
		       		nValorX	+= ( (_cAlias)->VALOR  )	// Soma o valor dos títulos pagos
		       		nValorY += nDiasAt					 					// Soma a Quantidade de Dias em Atraso do Cliente
		       		nValorZ += ( ( (_cAlias)->VALOR  ) * nDiasAt )			// Soma a Quantidade de Dias em Atraso x Valor do Título Pagos com Atraso
		       		nValorA++												// Soma a Quantidade de títulos baixados
		       		
		       	EndIf
				
			(_cAlias)->( DBSkip() )
			
			
			EndDo
			
			(_cAlias)->( DBCloseArea() )
			 
			//==========================================================================
			//Determina data e valor de última e penultima compra
			//==========================================================================
			_cQuery := " SELECT "
			_cQuery += "  		SF2.F2_EMISSAO EMISSAO, NVL(SUM(SF2.F2_VALBRUT),0) VALOR "
			_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
			_cQuery += " WHERE "
			_cQuery += "      SF2.D_E_L_E_T_ = ' ' "
			_cQuery += " AND  SF2.F2_CLIENTE = '"+ _ccodcli +"' "
			_cQuery += " AND  SF2.F2_EMISSAO < '"+ DToS( dDataRef ) +"' "
			_cQuery += " GROUP BY SF2.F2_EMISSAO"
			_cQuery += " ORDER BY SF2.F2_EMISSAO DESC"
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )

			dDataUC := SToD('')
			nValUC := 0
			dDataPUC := SToD('')
			nValPUC := 0

			 If !((_cAlias)->(Eof()))
			 
				//Grava ultima compra
				dDataUC := SToD((_cAlias)->EMISSAO)
				nValUC := (_cAlias)->VALOR				
			
			EndIf
			
			(_cAlias)->(DBSkip())
			
			If !((_cAlias)->(Eof()))
			 
				//Grava penultima compra
				dDataPUC := SToD((_cAlias)->EMISSAO)
				nValPUC := (_cAlias)->VALOR				
			
			EndIf		
	
	EndIf	
	
	nVLimCre :=  U_MOMS027K(_ccodcli,_clojacli)
		
	//===========================================================================
	//| Registra os dados na Base da CISP                                       |
	//===========================================================================
	DBSelectArea("SZY")
	SZY->( DBSetOrder(1) )
	If SZY->( DBSeek( xFilial("SZY") + cCNPJ ) )
	
		SZY->( RecLock("SZY",.F.) )
		    
		    SZY->ZY_PCVLCR	:= nVLimCre									// Limite de Crédito do Cliente
		    SZY->ZY_PCVDAV	:= nValAVX									// Valor Total a vencer
		    SZY->ZY_PCVSAT	:= nValTX							 		// Valor Total do Débito Atual
		    
			//===========================================================================
			//| Grava as Médias de Atraso do Cliente                                    |
			//===========================================================================
			SZY->ZY_PCQPAG	:= Round( nValorZ / nValorX , 2 )			// Média Ponderada de Atraso
			SZY->ZY_PCQDAP	:= Round( nValorY / nValorA , 2 )			// Média Aritmética de Atraso
			
			//===========================================================================
			//| Tratativa para o arredondamento das médias                              |
			//===========================================================================
			If SZY->ZY_PCQDAP == 0 .And. SZY->ZY_PCQPAG > 0
				SZY->ZY_PCQDAP := 0.01
			EndIf
			
			If SZY->ZY_PCQPAG == 0 .And. SZY->ZY_PCQDAP > 0
				SZY->ZY_PCQPAG := 0.01
			EndIf
			
			//===========================================================================
			//| Grava as Médias à Vencer do Cliente                                     |
			//===========================================================================
			SZY->ZY_PCMDAV	:= Round( nValAVZ / nValAVX , 2 )			// Média Ponderada a Vencer
			SZY->ZY_PCMPMV	:= Round( nValAVY / nValAVA , 2 )			// Prazo Médio de Vendas
			
			//===========================================================================
			//| Registra a atualização dos dados de Valores Vencidos                    |
			//===========================================================================
			SZY->ZY_PCDATV	:= Round( nVal05 , 2 )					// Valor do Débito Vencido há mais de 5 dias
			SZY->ZY_PCMPTV	:= Round( nValAc05 / nVal05 , 0 )		// Média Ponderada dos vencidos há mais de 5 dias
			SZY->ZY_PCV15D	:= Round( nVal15 , 2 )					// Valor do Débito vencido há mais de 15 dias
			SZY->ZY_PCM15D	:= Round( nValAc15 / nVal15 , 0 )		// Média Ponderada dos vencidos há mais de 15 dias
			SZY->ZY_PCV30D	:= Round( nVal30 , 2 )					// Valor do Débito vencido há mais de 30 dias
			SZY->ZY_PCM30D	:= Round( nValAc30 / nVal30 , 0 )		// Média Ponderada dos vencidos há mais de 30 dias
			
			//===========================================================================
			//| Verifica a atualização dos dados de maior acúmulo                       |
			//===========================================================================
			If dDataAC  >= _dDataDE2				// Verifica a atualização para os Clientes que possuem o maior acúmulo nos últimos 12 meses
			 
				If dDataAc > 	SZY->ZY_PCDMAC .And. nSaldoAC > SZY->ZY_PCVMAC // Se a data e o valor acumulado For maior que o último enviado
				
					SZY->ZY_PCVMAC	:= nSaldoAC		  		// Grava o novo Valor do Maior Acúmulo
					SZY->ZY_PCDMAC	:= dDataAC		  		// Grava a nova Data do Maior Acúmulo
					
				EndIf
						
			EndIf
				
			//===========================================================================
			//| Registra a atualização da Penúltima e Última compra                     |
			//===========================================================================
			If nValUC > 0 
			
				If  dDataUC > SZY->ZY_PCDUCM
						//Garante que só manda alteração se as datas de ultima compra e penultima compra são 
						//maiores que as já mandadas
				
					SZY->ZY_PCDTPC	:= dDataPUC
					SZY->ZY_PCVPCO	:= nValPUC
					SZY->ZY_PCDUCM	:= dDataUC
					SZY->ZY_PCVULC	:= nValUC
					
				EndIf
							
			EndIf
			
			//=============================================================================
			// Se a data de maior acumuluo é de um ano anterior e a ultima compra menos que 
			// um ano anterior ajusta maior acumulo para a ultima compra 	
			//=============================================================================
			If SZY->ZY_PCDUCM >= _dDataDE2	 .And. SZY->ZY_PCDMAC <= _dDataDE2
					
				  SZY->ZY_PCDMAC := SZY->ZY_PCDUCM
				  SZY->ZY_PCVMAC := SZY->ZY_PCVSAT
			
			EndIf		
		
	
			
			//===========================================================================
			//| Verifica acumulos e ultima compra                     |
			//===========================================================================
			If SZY->ZY_PCVPCO == 0 .And. SZY->ZY_PCDUCM != SZY->ZY_PCDMAC 
			
				SZY->ZY_PCDMAC := SZY->ZY_PCDUCM
				SZY->ZY_PCDTPC := SToD(" ")
							
			EndIf
			
			//===========================================================================
			//| Verifica acumulos e ultima compra                     |
			//===========================================================================
			If SZY->ZY_PCDUCM < SZY->ZY_PCDMAC 
			
				SZY->ZY_PCDMAC := SZY->ZY_PCDUCM
							
			EndIf
			
	
						
			//===========================================================================
			// Se o saldo atual ou ultima compra For maior que o Maior Acúmulo faz ajuste
			//===========================================================================
			If SZY->ZY_PCVMAC <= SZY->ZY_PCVSAT .Or. SZY->ZY_PCVMAC <= SZY->ZY_PCVULC
			
				If SZY->ZY_PCVULC >= SZY->ZY_PCVSAT
				
				  SZY->ZY_PCVMAC := SZY->ZY_PCVULC
				
				Else
				
				  SZY->ZY_PCVMAC := SZY->ZY_PCVSAT
				  
				EndIf
			
			EndIf	
			
		SZY->ZY_PCDDAT	:= dDataRef
		
		SZY->( MSUnLock() )
		
	EndIf
    
EndDo

(cAlias)->( DBCloseArea() )

//===========================================================================
//| Tratativa das mensagens para processamento via JOB ou Rotina            |
//===========================================================================
If !(lThread)
	
	//===========================================================================
	//| Inicializa barras de processamento                                      |
	//===========================================================================
	BarGauge1Set(0)
	IncProcG1( "Verificando os registros [ Processo 03 de 03 ]" )
	ProcessMessage()
	
	BarGauge2Set(0)
	IncProcG2( "Atualizando registros..." )
	ProcessMessage()
	
EndIf

u_itconout("Verificando os registros [ Processo 03 de 03 ] - Atualizando registros...")

DBSelectArea("SZY")
SZY->( DBGoTop() )

//===========================================================================
//| Verificação final dos dados gravados e atualização da Data da Informação|
//===========================================================================
While SZY->(!Eof())

	If SZY->ZY_PCCCLI >= MV_PAR01 .And. SZY->ZY_PCCCLI <= MV_PAR02
	
		SZY->( RecLock( "SZY" , .F. ) )
			
			If !Empty(SZY->ZY_PCDCDD)
				If !Empty(SZY->ZY_PCDUCM) .And. SZY->ZY_PCDUCM >= _dDataDE2
					If !Empty(SZY->ZY_PCVULC)
						If !Empty(SZY->ZY_PCDMAC)
							If !Empty(SZY->ZY_PCVMAC)
								If SZY->ZY_PCVPCO == 0 .And. !Empty(SZY->ZY_PCDTPC)
									SZY->ZY_PCDTPC := SToD("")
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			
			SZY->ZY_PCDDAT	:= dDataRef
		
		SZY->( MSUnLock() )
	
	EndIf
	
SZY->( DBSkip() )
EndDo

//===========================================================================
//| Tratativa das mensagens para processamento via JOB ou Rotina            |
//===========================================================================
If !(lThread)
	
	//===========================================================================
	//| Inicializa barras de processamento                                      |
	//===========================================================================
	BarGauge1Set(0)
	IncProcG1( "Verificando os registros [ Processo 03 de 03 ]" )
	ProcessMessage()
	
	BarGauge2Set(0)
	IncProcG2( "Verificando registros..." )
	ProcessMessage()
	
EndIf

u_itconout("Verificando os registros [ Processo 03 de 03 ] - Verificando registros...")

If MV_PAR06 == 1
	
	If lThread
	
		aValid := U_MOMS027L( 2 , lThread )
		
		If Empty(aValid)
		
			U_MOMS027T( lThread , .T. )
		
		Else
			
			U_MOMS027R( aValid )
			
		EndIf
		
	EndIf

	u_itconout("Verificando os registros [ Processo 03 de 03 ] - Gerando arquivo...")
	Processa( {|| U_MOMS027T( .F. , .T. ) } , "Geração do Arquivo" , "Iniciando, aguarde..." )
	u_itconout("Processo finalizado.")
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027T
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de controle para geração do arquivo TXT da CISP
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027T( lThread , lEnvMail )

Local oDlg			:= Nil
Local cDir			:= Space(150)
Local nOpc			:= 0

Default lThread		:= .F.
Default lEnvMail	:= .F.

//===========================================================================
//| Verifica o acesso do usuário à utilização dos dados da base da CISP     |
//===========================================================================
If !lThread .And. !U_ITVLDUSR(4)

	U_ITMsg("Usuário sem acesso à alteração dos dados da base da CISP.","Atenção","Verifique com a área de TI/ERP.",,1)
	
	Return
	
EndIf

//===========================================================================
//| Solicita a indicação do diretório de destino                            |
//===========================================================================
If lThread

	nOpc	:= 1
	cDir	:= AllTrim( GetMV( "IT_CISPDIR" ,, "\data\CISP\" ) )
	
Else
	
	If !lEnvMail
	
		_nOp:=Aviso( "Atenção!","A rotina atual permite gerar o arquivo em um Local específico ou processar o envio automático por e-mail." +CRLF+CRLF+;
								"Selecione a saída desejada:"	,;
								{"Arquivo","E-mail","Cancela"} )
								//1          2        3
		If _nOp = 1
	
			DEFINE MSDIALOG oDlg TITLE "Geração de Arquivo [TXT]" FROM 0,0 TO 060,552 OF oDlg PIXEL
			
				@005,005 Say "Diretório de Destino:"	SIZE 065,010 PIXEL OF oDlg COLOR CLR_HBLUE
				@014,005 MSGET cDir PICTURE "@!"		SIZE 195,010 PIXEL OF oDlg
				@014,200 BUTTON "..."					SIZE 013,012 PIXEL OF oDlg ACTION cDir := tFileDialog( "\" , "Selecione o Diretorio de Destino:" ,,,, GETF_RETDIRECTORY+GETF_LOCALHARD )
				
				@004,245 BUTTON "&Ok"					SIZE 030,011 PIXEL OF oDlg ACTION ( nOpc := 1 , oDlg:End() )
				@016,245 BUTTON "&Cancelar"				SIZE 030,011 PIXEL OF oDlg ACTION ( nOpc := 0 , oDlg:End() )
			
			ACTIVATE MSDIALOG oDlg CENTER
		
		ElseIf _nOp = 2
		
			nOpc		:= 1
			cDir		:= AllTrim( GetMV( "IT_CISPDIR" ,, "\data\CISP\" ) )
			lEnvMail	:= .T.
			
		EndIf
	
	EndIf

EndIf

//===========================================================================
//| Verifica a opção e a pasta de destino                                   |
//===========================================================================
If nOpc == 1
	
	cDir := AllTrim(cDir)
	
	If lThread
		
		MOMS027TXT( cDir , lThread , lEnvMail )
	
	Else
	
		Processa( {|| MOMS027TXT( cDir , lThread , lEnvMail )} , "Gravando Arquivo TXT..." , "Aguarde!" , .F. )
	
	EndIf
	
Else

	U_ITMsg(  "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027TXT
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de processamento da geração do arquivo TXT da CISP
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027TXT( cDirAux , lThread , lEnvMail )

Local aValid		:= {}
Local cCodCisp		:= AllTrim( GetMV( "IT_CISPCOD" ,, "0095" ) )
Local _cNArq1		:= ""
Local _cNArq2		:= "PFJ_"+ cCodCisp +".TXT"
Local cQuery		:= ""
Local cLinha		:= ""
Local cAlias		:= GetNextAlias()
Local cEmailTo		:= ""
Local cEmailCo		:= ""
Local cEmailBcc		:= ""
Local cAssunto		:= ""
Local cMensagem		:= ""
Local cAttach		:= ""
Local aConfig		:= {}
Local cLog			:= ""

Local dRefAtu		:= SToD("")

Local nI			:= 0
Local nTotReg		:= 0
Local nRegOk		:= 0
Local nHandle		:= 0

Local lProcOk		:= .T.
Local lErroVal		:= .F.

Default cDirAux		:= ""
Default lThread		:= .F.
Default lEnvMail	:= .F.

If !Empty( cDirAux )
	_cNArq1	:= cDirAux + _cNArq2
Else
	_cNArq1	:= AllTrim( GetMV( "IT_CISPDIR" ,, "\data\CISP\" ) ) + _cNArq2
EndIf

If !(lThread)
   If U_ITMsg("Deseja atulizar a data de processamento para a data de Hoje ?",'Atenção!',,2,2,2)

	  ProcRegua(3)
	  IncProc("Atualizando a Data...,Aguarde!")

	  cQuery := "UPDATE " + RETSQLNAME('SZY') + " SET ZY_PCDDAT = '"+DToS(DATE())+"' WHERE D_E_L_E_T_ = ' ' "

	  IncProc("Atualizando a Data...,Aguarde!")
		
	   If TCSqlExec(cQuery) < 0
		   Conout(TcSqlError())
           bBloco:={||  AVISO("TcSqlError()",TcSqlError(),{"Fechar"},3) }
		   U_ITMsg("Erro na atualização da Data: Ver Detalhes ",'Atenção!',"O Arquivo será gerado mesmo assim.",3,,,,,,bBloco)
	   Else
			TCSQLEXEC( "COMMIT" )
	   EndIf

	  IncProc("Atualizando a Data...,Aguarde!")

   EndIf
EndIf

//===========================================================================
//| Apaga o arquivo se o mesmo ja existir para criacao do novo.             |
//===========================================================================
If File( _cNArq1 )
	
	lProcOk := .F.
	
	For nI := 0 To 5 // Tentativas de exclusao do arquivo
	
		If FERASE(_cNArq1) <> -1
			lProcOk := .T.
			Exit
		EndIf
		
	SLEEP( 5000 )
	Next nI
	
	If !lProcOk
	
		If !(lThread)
			U_ITMsg( "Não foi possível excluir o arquivo existente: "+ CRLF + CRLF + _cNArq1 , "Atenção!" , ,1 )
		EndIf
		
		Return
		
	EndIf
	
EndIf

//===========================================================================
//| Cria arquivo novo.                                                      |
//===========================================================================
If lProcOk

	nHandle := FCreate( _cNArq1 )
	
	If nHandle == -1
	
		If !(lThread)
			U_ITMsg( "Não foi possível criar o arquivo: "+ CRLF + CRLF + _cNArq1 , "Atenção!" ,"Verifique o destino e tente novamente..." ,  ,1 )
		EndIf
		
		Return
		
	EndIf
	
EndIf

DBSelectArea("SZY")
SZY->( DBGoTop() )
If SZY->( !Eof() )
	dRefAtu := YEARSUB( SZY->ZY_PCDDAT , 1 )
Else
	dRefAtu := YEARSUB( dDataRef , 1 )
EndIf

//===========================================================================
//| Seleciona os dados CISP para o arquivo.                                 |
//===========================================================================
cQuery := " SELECT "
cQuery += "     SZY.ZY_PCTIPO, "
cQuery += "     SZY.ZY_PCCASS, "
cQuery += "     SZY.ZY_PCCCLI, "
cQuery += "	  	SZY.ZY_PCDDAT, "
cQuery += "     SZY.ZY_PCDCDD, "
cQuery += "     SZY.ZY_PCDUCM, "
cQuery += "     SZY.ZY_PCVULC, "
cQuery += "     SZY.ZY_PCDMAC, "
cQuery += "     SZY.ZY_PCVMAC, "
cQuery += "     SZY.ZY_PCVSAT, "
cQuery += "     SZY.ZY_PCVLCR, "
cQuery += "     SZY.ZY_PCQPAG, "
cQuery += "     SZY.ZY_PCQDAP, "
cQuery += "     SZY.ZY_PCVDAV, "
cQuery += "     SZY.ZY_PCMDAV, "
cQuery += "     SZY.ZY_PCMPMV, "
cQuery += "     SZY.ZY_PCDATV, "
cQuery += "     SZY.ZY_PCMPTV, "
cQuery += "     SZY.ZY_PCV15D, "
cQuery += "     SZY.ZY_PCM15D, "
cQuery += "     SZY.ZY_PCV30D, "
cQuery += "     SZY.ZY_PCM30D, "
cQuery += "     SZY.ZY_PCDTPC, "
cQuery += "     SZY.ZY_PCVPCO "
cQuery += " FROM "+ RetSqlName("SZY") +" SZY "
cQuery += " WHERE "
cQuery += " 		SZY.D_E_L_E_T_	= ' ' "						// Não permite os deletados
cQuery += " AND		SZY.ZY_PCVMAC	> 0.01 "					// Deve possuir registro de Maior Acúmulo
cQuery += " AND	(	SZY.ZY_PCDUCM	> '"+ DToS( dRefAtu ) +"' "	// A Data da última compra deve estar no período
cQuery += " 	OR	SZY.ZY_PCVSAT	> 0.01  "					// ou possuir saldo em aberto
cQuery += "     OR  SZY.ZY_FLAGEN = '1' ) "                       //Flag para forçar envio em caso de arquivo comp.pdf

//===========================================================================
//| Prepara e inicializa os dados para gravação do arquivo.                 |
//===========================================================================
If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

nTotReg	:= 0
nI		:= 0

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
(cAlias)->( DBEval( {|| nTotReg++} ) )
(cAlias)->( DBGoTop() )

If !(lThread)
	ProcRegua(nTotReg)
EndIf

//===========================================================================
//| Processa a gravação do arquivo.                                         |
//===========================================================================
While (cAlias)->(!Eof())

	nI++
	
	If !lThread
		IncProc("["+ StrZero(nI,9) +"] de ["+ StrZero(nTotReg,9) +"]")
	EndIf
	
	lErroVal := .F.
	
	//===========================================================================
	//| Validação da dada de cadastro do Cliente                                |
	//===========================================================================
	If Empty( (cAlias)->ZY_PCDCDD )
		aAdd( aValid , { AllTrim( (cAlias)->ZY_PCCCLI ) , "Data de cadastro do Cliente é obrigatória." } )
		lErroVal := .T.
	EndIf
	
	//===========================================================================
	//| Validação da dada de última compra                                      |
	//===========================================================================
	If Empty( (cAlias)->ZY_PCDUCM )
		aAdd( aValid , { AllTrim( (cAlias)->ZY_PCCCLI ) , "Não existe registro de última compra no histórico desde a implantação." } )
		lErroVal := .T.
	EndIf
	
	//===========================================================================
	//| Validação do valor da última compra                                     |
	//===========================================================================
	If	Empty( (cAlias)->ZY_PCVULC ) .Or. (cAlias)->ZY_PCVULC == 0
		aAdd( aValid , { AllTrim( (cAlias)->ZY_PCCCLI ) , "Não existe valor de última compra no histórico desde a implantação." } )
		lErroVal := .T.
	EndIf
	
	//===========================================================================
	//| Validação da dada de maior acúmulo de saldo em aberto do Cliente        |
	//===========================================================================
	If	Empty( (cAlias)->ZY_PCDMAC )
		aAdd( aValid , { AllTrim( (cAlias)->ZY_PCCCLI ) , "Não foram encontrados registros de data do maior acúmulo de saldo em aberto." } )
		lErroVal := .T.
	EndIf
	
	//===========================================================================
	//| Validação do valor de maior acúmulo de saldo em aberto do Cliente       |
	//===========================================================================
	If	Empty( (cAlias)->ZY_PCVMAC )
		aAdd( aValid , { AllTrim( (cAlias)->ZY_PCCCLI ) , "Não foram encontrados registros de valor do maior acúmulo de saldo em aberto." } )
		lErroVal := .T.
	EndIf
	
	//===========================================================================
	//| Se não passou pela validação não inclui o registro no arquivo           |
	//===========================================================================
	If lErroVal
		(cAlias)->( DBSkip() )
		Loop
	EndIf
	
	nRegOk++
	
	//===========================================================================
	//| Monta a linha para gravação do arquivo                                  |
	//===========================================================================
	cLinha := ""
	
	//===========================================================================
	//| Tratativa para não gerar linha em branco no fim do arquivo              |
	//===========================================================================
	If nRegOk > 1
		cLinha += CRLF
	EndIf
	
	clinha += (cAlias)->ZY_PCTIPO												// | 01 | Identif. (1-CNPJ / 2-CPF / 3-RG / 4-Export. / 5-Insc.Prod./ 9-Outros)
	cLinha += StrZero( Val( (cAlias)->ZY_PCCASS ) , 04 )						// | 02 | Código do Associado
	cLinha += StrZero( Val( (cAlias)->ZY_PCCCLI ) , 20 )						// | 03 | Identificação. (CNPJ / CPF / RG / Export. / Insc.Prod. / Outros)
//	cLinha += PadR( AllTrim( (cAlias)->ZY_PCDDAT )	, 08 , "0" )				// | 04 | Data da Informação
	cLinha += PadR( AllTrim( DToS(DATE()) )			, 08 , "0" )				// | 04 | Data da Informação
	cLinha += PadR( AllTrim( (cAlias)->ZY_PCDCDD )	, 08 , "0" )				// | 05 | Data do Cadastro do Cliente
	cLinha += PadR( AllTrim( (cAlias)->ZY_PCDUCM )	, 08 , "0" )				// | 06 | Data da Última Compra
	cLinha += StrZero( (cAlias)->ZY_PCVULC * 100 , 15 )							// | 07 | Valor da Última Compra
	cLinha += PadR( AllTrim( (cAlias)->ZY_PCDMAC )	, 08 , "0" )				// | 08 | Data do Maior Acúmulo
	cLinha += StrZero( (cAlias)->ZY_PCVMAC * 100 , 15 )							// | 09 | Valor do Maior Acúmulo
	cLinha += StrZero( (cAlias)->ZY_PCVSAT * 100 , 15 )							// | 10 | Valor do Débito Atual Total
	cLinha += StrZero( (cAlias)->ZY_PCVLCR * 100 , 15 )							// | 11 | Valor do Limite de Crédito
	cLinha += StrZero( INT( (cAlias)->ZY_PCQPAG * 100 ) , 06 )					// | 12 | Média Ponderada de Atraso nos Pagamentos (Títulos Baixados)
	cLinha += StrZero( INT( (cAlias)->ZY_PCQDAP * 100 ) , 06 )					// | 13 | Média Aritmética dos Dias de Atraso nos Pagamentos (Títulos Baixados)
	cLinha += StrZero( (cAlias)->ZY_PCVDAV * 100 , 15 )							// | 14 | Valor Débito Atual a Vencer
	cLinha += StrZero( INT( (cAlias)->ZY_PCMDAV * 100 ) , 06 )					// | 15 | Média Ponderada de Títulos a Vencer
	cLinha += StrZero( INT( (cAlias)->ZY_PCMPMV * 100 ) , 06 )					// | 16 | Prazo Médio de Vendas
	cLinha += StrZero( (cAlias)->ZY_PCDATV * 100 , 15 )							// | 17 | Valor do Débito Atual Vencido (+5 Dias)
	cLinha += StrZero( INT( (cAlias)->ZY_PCMPTV ) , 04 )						// | 18 | Média Ponderada de Atraso Títulos Vencidos e não Pagos (+5 Dias)
	cLinha += StrZero( (cAlias)->ZY_PCV15D * 100 , 15 )							// | 19 | Valor do Débito Atual Vencido (+15 Dias)
	cLinha += StrZero( INT( (cAlias)->ZY_PCM15D ) , 04 )						// | 20 | Média Ponderada de Atraso Títulos Vencidos e não Pagos (+15 Dias)
	cLinha += StrZero( (cAlias)->ZY_PCV30D * 100 , 15 )							// | 21 | Valor do Débito Atual Vencido (+30 Dias)
	cLinha += StrZero( INT( (cAlias)->ZY_PCM30D ) , 04 )						// | 22 | Média Ponderada de Atraso Títulos Vencidos e não Pagos (+30 Dias)
	cLinha += PadR( AllTrim( (cAlias)->ZY_PCDTPC ) , 08 , "0" )					// | 23 | Data da Penúltima Compra
	cLinha += StrZero( (cAlias)->ZY_PCVPCO * 100 , 15 )							// | 24 | Valor da Penúltima Compra
	cLinha += "2"																// | 25 | Situação do Cálculo Limite de Crédito: 2 - 2	Limite Operacional de Crédito 
	cLinha += "0"																// | 26 | Tipo de Garantia
	cLinha += "00"																// | 27 | Grau da Garantia - Hipoteca
	cLinha += "00000000"														// | 28 | Data da Validade da Garantia
	cLinha += "000000000000000"													// | 29 | Valor da Garantia
	cLinha += "000000000000000"													// | 30 | Valor da Venda de Pagamento Antecipado
	cLinha += "  "																// | 31 | Venda sem Crédito (Antecipado)
	
	FWrite( nHandle , cLinha )

(cAlias)->( DBSkip() )
EndDo

(cAlias)->(DBCloseArea())
FClose( nHandle )

//===========================================================================
//| Caso sejam identificadas inconsistências exibe janela de informações.   |
//===========================================================================
If !Empty( aValid )
    
	If !(lThread)
		U_ITListBox( "Registros não enviados:" , {"CNPJ","Motivo"} , aValid )
	EndIf
	
EndIf

//===========================================================================
//| Verifica se foram gravados resgitros no arquivo.                        |
//===========================================================================
If nRegOk > 0
	
	If !(lThread)
		U_ITMsg(  "Arquivo:"+ CRLF + CRLF + _cNArq1 + CRLF + CRLF +"gerado com Sucesso!" ,"Concluído!",,2 )
	EndIf
	
	If lEnvMail
		
		cEmailTo	:= Lower( AllTrim( SuperGetMV( "IT_CISPDES" ,.F., "sistema@italac.com.br"		) ) )
		cEmailCo	:= Lower( AllTrim( SuperGetMV( "IT_CISPCOP" ,.F., ""								) ) )
		cEmailBcc:= Lower( AllTrim( GetMV( "IT_CISPCOO" ,, ""								) ) )
		cAssunto	:= AllTrim( GetMV( 'IT_CISPTIT' ,, 'POSITIVAS - PRODUCAO - '+ AllTrim( GetMV( "IT_CISPCOD" ,, "0095" ) ) ) )
		cMensagem	:= MOMS027MSG( 1 )
		cAttach		:= _cNArq1
		aConfig		:= U_ITCFGEML( AllTrim( GetMV( "IT_CISPCFG" ,, "002" ) ) ) //Configuração de e-mail a ser considerada para o envio (Tabela Z02)
		cLog		:= ""
		
		If lThread
			U_ITENVMAIL( aConfig[01] , cEmailTo , cEmailCo , cEmailBcc , cAssunto , cMensagem , cAttach , aConfig[01] , aConfig[02] , aConfig[03] , aConfig[04] , aConfig[05] , aConfig[06] , aConfig[07] , @cLog )
		Else
			LjMsgRun( "Processando o envio por e-mail..." , "Aguarde!" , {|| U_ITENVMAIL( aConfig[01] , cEmailTo , cEmailCo , cEmailBcc , cAssunto , cMensagem , cAttach , aConfig[01] , aConfig[02] , aConfig[03] , aConfig[04] , aConfig[05] , aConfig[06] , aConfig[07] , @cLog ) } )
		EndIf
		
		If Empty( cLog )
			
			If !(lThread)
				U_ITMsg( "E-mail enviado com sucesso!" , "Atenção!",,2 )
			Else
			
				//Grava data de envio de email para não enviar mais de um email por dia via schedule
				PutMV("ITDTCISP",DATE())
			
			EndIf
			
			
			
		Else
		
			If !(lThread)
				U_ITMsg(  cLog , "Atenção!",,3 )
			EndIf
			
		EndIf
		
		FRename( _cNArq1 , SubStr( _cNArq1 , 1 , Len(_cNArq1) - 4 ) +"_"+ DToS( Date() ) +"_"+ StrTran( Time() , ":" , "" ) +".txt" )
		
	EndIf
	
ElseIf File(_cNArq1)

	//===========================================================================
	//| Tenta apagar o arquivo se o mesmo foi gerado em branco.                 |
	//===========================================================================
	For nI := 1 To 5
	
		If FERASE(_cNArq1) <> -1
			Exit
		EndIf
		
	SLEEP( 5000 )
	Next nI
	
	If !(lThread)
		U_ITMsg(  "Falha na geração do arquivo!"+ CRLF +"O arquivo não pode ser gerado em branco." , "Atenção!",,1 )
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027L
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de controle da validação dos dados gerados
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027L( nOpc , lThread )

Local aRet		:= {}

Default nOpc	:= 1
Default lThread	:= .F.

//===========================================================================
//| Verifica o acesso do usuário à alteração dos dados da base da CISP      |
//===========================================================================
If !lThread .And. !U_ITVLDUSR(4)

	U_ITMsg("Usuário sem acesso à alteração dos dados da base da CISP.","Atenção","Verifique com a área de TI/ERP.",,1)

	Return
	
EndIf

If lThread
	
	aRet := MOMS027INF( lThread )
	
Else

	Processa( {|lEnd| MOMS027INF() } , "Analisando Inconsistências na Base - Aguarde..." , "Processando..." )

EndIf

Return( aRet )

/*
===============================================================================================================================
Programa----------: MOMS027INF
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de validação das informações da Base CISP
===============================================================================================================================
Parametros--------: lThread		- se verdadeiro define que a rotina está sendo executada via JOB
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027INF( lThread )

Local _dDataDE2	:= SToD("")
Local aDadosAux	:= {}
Local lValid	:= .F.
Local nI		:= 0
Local nTotReg	:= 0

Default lThread	:= .F.

//===========================================================================
//| Posiciona no alias da base CISP                                         |
//===========================================================================
DBSelectArea("SZY")

SZY->( DBGoTop() )
SZY->( DBEval( {|| nTotReg++ } ) )
SZY->( DBGoTop() )

ProcRegua(nTotReg)

If nTotReg > 0
	_dDataDE2 := YearSub( SZY->ZY_PCDDAT , 1 )
EndIf

//===========================================================================
//| Processa a validação dos conteúdos                                      |
//===========================================================================
While SZY->(!Eof())
	
	nI++
	IncProc( "["+ StrZero( nI , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]" )
	
	//===========================================================================
	//| Verifica o preenchimento da data de cadastro                            |
	//===========================================================================
	If Empty(SZY->ZY_PCDCDD)
		lValid := .T.
		aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data de cadastro do Cliente está em branco." } )
	ElseIf SZY->ZY_PCDCDD > SZY->ZY_PCDDAT
		lValid := .T.
		aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data de cadastro do Cliente é maior que a data de atualização da base." } )
	EndIf
	
	//===========================================================================
	//| Só valida clientes que possuem registro de data de última compra.       |
	//===========================================================================
	If !Empty(SZY->ZY_PCDUCM)
		
		//===========================================================================
		//| Só valida clientes que possuem registro de valor da última compra.      |
		//===========================================================================
		If !Empty(SZY->ZY_PCVULC)

			//===========================================================================
			//| Validações da Data de Última Compra                                     |
			//===========================================================================
			If SZY->ZY_PCDUCM > SZY->ZY_PCDDAT
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data da última compra é maior que a data de atualização da base." } )
			EndIf
			
			If SZY->ZY_PCDUCM < SZY->ZY_PCDCDD
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data da última compra é menor do que a data de cadastro do Cliente." } )
			EndIf
			
			If SZY->ZY_PCDUCM <= SZY->ZY_PCDTPC
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data da última compra é menor ou igual do que a data da penúltima compra." } )
			EndIf
			
			//===========================================================================
			//| Validações da Data de Maior Acúmulo do Cliente                          |
			//===========================================================================
			If SZY->ZY_PCDMAC > SZY->ZY_PCDDAT
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data de maior acúmulo é maior do que a data de atualização da base." } )
			EndIf
			
			If SZY->ZY_PCDMAC < SZY->ZY_PCDCDD
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data de maior acúmulo é menor do que a data de cadastro do Cliente." } )
			EndIf
			
			If SZY->ZY_PCDMAC > SZY->ZY_PCDUCM
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Data de maior acúmulo é maior do que a data da última compra." } )
			EndIf
			
				
			//===========================================================================
			//| Validações do Valor de Maior Acúmulo do Cliente                         |
			//===========================================================================
			If SZY->ZY_PCVMAC < SZY->ZY_PCVSAT
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O valor do maior acúmulo é menor do que o valor do saldo atual do Cliente." } )
			EndIf
			
			If SZY->ZY_PCVMAC < SZY->ZY_PCVULC
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O valor do maior acúmulo é menor do que o valor da última compra do Cliente." } )
			EndIf
			
			//===========================================================================
			//| Validações do Valor do Saldo Atual do Cliente                           |
			//===========================================================================
			If SZY->ZY_PCVSAT < SZY->ZY_PCVDAV
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual é menor do que o saldo atual à vencer do Cliente." } )
			EndIf
			
			If SZY->ZY_PCVSAT < SZY->ZY_PCDATV
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual é menor do que o saldo vencido (+5) do Cliente." } )
			EndIf
			
			If SZY->ZY_PCVSAT < SZY->ZY_PCV15D
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual é menor do que o saldo vencido (+15) do Cliente." } )
			EndIf
			
			If SZY->ZY_PCVSAT < SZY->ZY_PCV30D
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual é menor do que o saldo vencido (+30) do Cliente." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Ponderada de Atrasos do Cliente                      |
			//===========================================================================
			If SZY->ZY_PCQPAG == 0 .And. SZY->ZY_PCQDAP <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de atrasos é igual a zero e a média aritmética não é igual a zero." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Aritmética de Atrasos do Cliente                     |
			//===========================================================================
			If SZY->ZY_PCQDAP == 0 .And. SZY->ZY_PCQPAG <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média aritmética de atrasos é igual a zero e a média ponderada não é igual a zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo Atual à vencer do Cliente                            |
			//===========================================================================
			If SZY->ZY_PCVDAV > SZY->ZY_PCVSAT
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual à vencer é maior que o saldo total atual do Cliente." } )
			EndIf
			
			If SZY->ZY_PCVDAV == 0 .And. SZY->ZY_PCMDAV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual à vencer é igual a zero e foi calculada a média ponderada de títulos à vencer." } )
			EndIf
			
			If SZY->ZY_PCVDAV == 0 .And. SZY->ZY_PCMPMV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo atual à vencer é igual a zero e foi calculada a média de prazo à vencer." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Ponderada à vencer do Cliente                        |
			//===========================================================================
			If SZY->ZY_PCMDAV == 0 .And. SZY->ZY_PCVDAV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de títulos à vencer é igual a zero e o saldo à vencer é maior que zero." } )
			EndIf
			
			If SZY->ZY_PCMDAV == 0 .And. SZY->ZY_PCMPMV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de títulos à vencer é igual a zero e a média de prazo à vencer é maior que zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Prazo Médio à vencer do Cliente                            |
			//===========================================================================
			If SZY->ZY_PCMPMV == 0 .And. SZY->ZY_PCVDAV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O prazo médio à vencer é igual a zero e o saldo à vencer é maior que zero." } )
			EndIf
			
			If SZY->ZY_PCMPMV == 0 .And. SZY->ZY_PCMDAV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O prazo médio à vencer é igual a zero e a média ponderada à vencer é maior que zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+5) do Cliente                            |
			//===========================================================================
			If SZY->ZY_PCDATV > SZY->ZY_PCVSAT
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+5) é maior que o saldo total atual do Cliente." } )
			EndIf
			
			If SZY->ZY_PCDATV == 0 .And. SZY->ZY_PCMPTV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+5) é igual a zero e foi calculada média ponderada de vencidos (+5)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+5) do Cliente                    |
			//===========================================================================
			If SZY->ZY_PCMPTV <> 0 .And. SZY->ZY_PCMPTV < 5
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+5) é menor do que 5." } )
			EndIf
			
			If SZY->ZY_PCMPTV == 0 .And. SZY->ZY_PCDATV <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+5) é igual a zero e existe saldo vencido (+5)." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+15) do Cliente                            |
			//===========================================================================
			If SZY->ZY_PCV15D > SZY->ZY_PCDATV
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+15) é maior que o saldo vencido (+5)." } )
			EndIf
			
			If SZY->ZY_PCV15D == 0 .And. SZY->ZY_PCM15D <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+15) é igual a zero e foi calculada média ponderada vencida (+15)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+15) do Cliente                   |
			//===========================================================================
			If SZY->ZY_PCM15D <> 0 .And. SZY->ZY_PCM15D < 15
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+15) é menor do que 15." } )
			EndIf
			
			If SZY->ZY_PCM15D == 0 .And. SZY->ZY_PCV15D <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+15) é igual a zero e existe saldo vencido (+15)." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+30) do Cliente                            |
			//===========================================================================
			If SZY->ZY_PCV30D > SZY->ZY_PCV15D
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+30) é maior que o saldo vencido (+15)." } )
			EndIf
			
			If SZY->ZY_PCV30D == 0 .And. SZY->ZY_PCM30D <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "O saldo vencido (+30) é igual a zero e foi calculada média ponderada vencida (+30)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+30) do Cliente                   |
			//===========================================================================
			If SZY->ZY_PCM30D <> 0 .And. SZY->ZY_PCM30D < 30
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+30) é menor do que 30." } )
			EndIf
			
			If SZY->ZY_PCM30D == 0 .And. SZY->ZY_PCV30D <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A média ponderada de vencidos (+30) é igual a zero e existe saldo vencido (+30)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Data da Penúltima Compra do Cliente                        |
			//===========================================================================
			If SZY->ZY_PCDTPC == SZY->ZY_PCDUCM
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A data da penúltima compra é igual à data de última compra." } )
			EndIf
			
			If SZY->ZY_PCDTPC > SZY->ZY_PCDUCM
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A data da penúltima compra é maior que a data de última compra." } )
			EndIf
			
			If Empty( SZY->ZY_PCDTPC ) .And. SZY->ZY_PCVPCO <> 0
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Não foi registrada a data da penúltima compra e o valor da penúltima compra é maior que zero." } )
			EndIf
			
			If !Empty( SZY->ZY_PCDTPC ) .And. SZY->ZY_PCDTPC < SZY->ZY_PCDCDD
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "A data da penúltima compra é anterior à data de cadastro do Cliente." } )
			EndIf
			
			If Empty( SZY->ZY_PCDTPC ) .And. !Empty( SZY->ZY_PCDUCM ) .And. !Empty( SZY->ZY_PCDMAC ) .And. SZY->ZY_PCDUCM <> SZY->ZY_PCDMAC
				lValid := .T.
				aAdd( aDadosAux , { SZY->ZY_PCCCLI , "Não foi registrada a data da penúltima compra e a data de maior acúmulo é diferente da data de última compra." } )
			EndIf
			
		EndIf
		
	EndIf
	
SZY->(DBSkip())
EndDo

SZY->(DBGoTop())

//===========================================================================
//| Verifica se existem inconsistências e exibe informações caso necessário |
//===========================================================================
If lValid

	If !(lThread)
	
		MsgInfo( "Foram encontradas inconsistências durante a validação! É recomendado executar a atualização da base antes de gerar um novo arquivo para enviar." , "Atenção!" )
		U_ITListBox( "Inconsistências" , { "CNPJ" , "Mensagem" } , aDadosAux )
		
	EndIf
	
Else

	If !(lThread)
		
		MsgInfo( "Todos os registros foram validados com sucesso!" , "Concluído!" )
		
	EndIf
	
EndIf

Return( aDadosAux )

/*
===============================================================================================================================
Programa----------: MOMS027V
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de visualização dos dados de um Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027V()

//Local nOpca			:= 0

Private aButtons	:= {}
Private cCadastro	:= "Integração - Cisp"
Private _aCamposVis	:= {	"NOUSER"	, "ZY_FILIAL"	, "ZY_PCTIPO"	, "ZY_PCCASS"	, "ZY_PCCCLI"	, "ZY_PCDDAT"	, "ZY_PCDCDD"	, "ZY_PCDUCM"	, "ZY_PCVULC"	,;
							"ZY_PCDMAC"	, "ZY_PCVMAC"	, "ZY_PCVSAT"	, "ZY_PCVLCR"	, "ZY_PCQPAG"	, "ZY_PCQDAP"	, "ZY_PCVDAV"	, "ZY_PCMDAV"	, "ZY_PCMPMV"	,;
							"ZY_PCDATV"	, "ZY_PCMPTV"	, "ZY_PCV15D"	, "ZY_PCM15D"	, "ZY_PCV30D"	, "ZY_PCM30D"	, "ZY_PCDTPC"	, "ZY_PCVPCO"	, "ZY_PCVSIT"	,;
							"ZY_PCTIPG"	, "ZY_PCGGA"	, "ZY_PCDTG"	, "ZY_PCVLG"	, "ZY_PCVPA"	, "ZY_PCSVV"	}


//===========================================================================
//| Adiciona botões das funcionalidades extras da rotina                    |
//===========================================================================
aAdd( aButtons , { "RECALC" , {|| MsgRun( "Selecionando Registros..." , "Aguarde" , {|| MOMS027CCR() } ) }	, "Conta Corrente"		, "C.Corrente"	} )
aAdd( aButtons , { "POSCLI" , {|| MsgRun( "Selecionando Registros..." , "Aguarde" , {|| MOMS027CAD() } ) }	, "Cadastro do Cliente"	, "Cadastro"	} )

//===========================================================================
//| Inicializa a visualização padrão da base                                |
//===========================================================================
DBSelectArea("SZY")
AxVisual( "SZY" , SZY->(Recno()) , 2 , _aCamposVis ,,,, aButtons )

Return

/*
===============================================================================================================================
Programa----------: MOMS027D
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de exclusão dos dados de análise de um Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027D( cAlias , nReg , nOpc )


Private aButtons	:= {}
Private cCadastro	:= "Integração - Cisp"


//===========================================================================
//| Verifica o acesso do usuário à alteração dos dados da base da CISP      |
//===========================================================================
If !U_ITVLDUSR(4)

	U_ITMsg("Usuário sem acesso à alteração dos dados da base da CISP.","Atenção","Verifique com a área de TI/ERP.",,1)

	Return
	
EndIf

//===========================================================================
//| Adiciona botões das funcionalidades extras da rotina                    |
//===========================================================================
aAdd( aButtons , { "RECALC" , {|| MsgRun( "Selecionando Registros..." , "Aguarde" , {|| MOMS027CCR() } ) }	, "Conta Corrente"		, "C.Corrente"	} )
aAdd( aButtons , { "POSCLI" , {|| MsgRun( "Selecionando Registros..." , "Aguarde" , {|| MOMS027CAD() } ) }	, "Cadastro do Cliente"	, "Cadastro"	} )

//===========================================================================
//| Inicializa a exclusão padrão da base                                    |
//===========================================================================
AxDeleta( cAlias , nReg , nOpc ,,, aButtons )

Return


/*
===============================================================================================================================
Programa----------: MOMS027CAD
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de visualização dos ítens do cadastro de um Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027CAD()

Local _aArea	:= FWGetArea()
Local aDadosAux	:= {}
Local oDlg		:= Nil
Local oLbx		:= Nil

//===========================================================================
//| Posiciona na tabela de Clientes                                         |
//===========================================================================
DBSelectArea("SA1")
SA1->( DBSetOrder(3) )
If SA1->( DBSeek( xFilial("SA1") + AllTrim(SZY->ZY_PCCCLI) ) )
	
	While SubStr( SA1->A1_CGC , 1 , 8 ) == AllTrim( SZY->ZY_PCCCLI )
	
		aAdd( aDadosAux , { SA1->A1_COD +' - '+ SA1->A1_LOJA , SA1->A1_NOME , SA1->A1_MUN , SA1->A1_EST } )
		SA1->(DBSkip())
	
	EndDo

	//===========================================================================
	//| Monta a ListBox com os dados do Cliente                                 |
	//===========================================================================
	DEFINE MSDIALOG oDlg TITLE "Cadastros do Cliente" FROM 000,000 TO 500,800 COLORS RGB(141,192,222),RGB(188,199,205) PIXEL
		
		@ 002,002 LISTBOX oLbx FIELDS HEADER "Cliente" , "Nome" , "Cidade" , "UF" SIZE 398,233 OF oDlg PIXEL
		
		oLbx:SetArray( aDadosAux )
		oLbx:bLine := {|| { aDadosAux[oLbx:nAt][01] , aDadosAux[oLbx:nAt][02] , aDadosAux[oLbx:nAt][03] , aDadosAux[oLbx:nAt][04] }}
	
	DEFINE SBUTTON FROM 237,374 Type 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL
	ACTIVATE MSDIALOG oDlg CENTER
   
Else

   U_ITMsg( "Cliente não encontrado" , "Atenção" ,,1 )
   FWRestArea(_aArea)
   Return
   
EndIf


FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MOMS027CCR
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de construção da visualização do extrato da "conta corrente" de um Cliente
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027CCR()

Private oButton1	:= Nil
Private oButton2	:= Nil
Private oGet1		:= Nil
Private cGet1		:= Space(9)
Private oGet2		:= Nil
Private cGet2		:= Space(3)
Private oGet3		:= Nil
Private cGet3		:= Space(1)
Private oGet4		:= Nil
Private cGet4		:= Space(1)
Private oPanel1		:= Nil
Private oSay1		:= Nil
Private oSay2		:= Nil
Private oSay3		:= Nil
Private oSay4		:= Nil
Private oWBrowse1	:= Nil
Private aWBrowse1	:= {}

Static oDlg			:= Nil

DEFINE MSDIALOG oDlg TITLE "Conta Corrente" FROM 000,000 TO 500,800 COLORS RGB(141,192,222),RGB(188,199,205) PIXEL

	MOMS027BR1()
	MOMS027CD1( AllTrim( SZY->ZY_PCCCLI ) )

ACTIVATE MSDIALOG oDlg CENTER ON INIT MOMS027ENB( oDlg )

Return

/*
===============================================================================================================================
Programa----------: MOMS027ENB
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Monta a barra de menu superior da janela
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027ENB( oObj , bObj )

Local oBar		:= Nil

DEFINE BUTTONBAR oBar SIZE 25,25 3D TOP OF oObj

DEFINE BUTTON oBtnNp  RESOURCE "MDIEXCEL"	OF oBar ACTION Processa( {|lEnd| MOMS027EXC( oWBrowse1:aArray ) } , 'Processando arquivo...' )	TOOLTIP ""
DEFINE BUTTON oBtOk   RESOURCE "Cancel"		OF oBar ACTION oDlg:End()												  		TOOLTIP ""

oBar:bRClicked :={|| AllwaysTrue() }

Return

/*
===============================================================================================================================
Programa----------: MOMS027EXC
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de exportação dos dados da "conta corrente" do Cliente em arquivo formatado do Excel
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027EXC( aDadosAux )

Local nHandle	:= 0
Local cArqPesq	:= GetTempPath() +"\"+ AllTrim(SZY->ZY_PCCCLI) +".XLS"
Local cCabHtml	:= ""
Local cLinFile	:= ""
Local cFileCont	:= ""
Local lFlag		:= .T.
Local nTotReg	:= Len( aDadosAux )
Local nI		:= 0

If nTotReg <= 0
	
	U_ITMsg(  "Não é possível gerar um arquivo vazio!" , "Atenção!",,1 )
	Return
	
EndIf

ProcRegua( nTotReg )

//===========================================================================
//| Verifica a geração do arquivo                                           |
//===========================================================================
nHandle := FCreate( cArqPesq , 0 )

If nHandle == -1
	U_ITMsg( "Nao foi possivel abrir ou criar o arquivo: " + cArqPesq,"Atenção",,1 )
	Return
EndIf

//===========================================================================
//| Monta o cabeçalho do arquivo                                            |
//===========================================================================
cCabHtml	:= "<!-- Created with AEdiX by Kirys Tech 2000,http://www.kt2k.com --> "				+CRLF
cCabHtml	+= "<!DOCTYPE html Public '-//W3C//DTD HTML 4.01 Transitional//EN'>"	 				+CRLF
cCabHtml	+= "<html>"															 					+CRLF
cCabHtml	+= "<head>"															 					+CRLF
cCabHtml	+= "  <title>Centro de custo</title>"									 				+CRLF
cCabHtml	+= "  <meta name='GENERATOR' content='AEdiX by Kirys Tech 2000,http://www.kt2k.com'>"	+CRLF
cCabHtml	+= "</head>"																			+CRLF
cCabHtml	+= "<body bgcolor='#FFFFFF'>"															+CRLF

cRodHtml	:= "</body>"																			+CRLF
cRodHtml	+= "</html>"

cFileCont	:= cCabHtml

cLinFile	:= "<table border='1' cellpadding='3' cellspacing='0' bordercolor='#8B8B83' bgColor='#FFFFFF'>"							+CRLF
cLinFile	+= "<TR>"																												+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Documento</b></TD>"							+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Parcela</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Emissao</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Cnpj</b></TD>"									+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Fatura</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Pagto.</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Dt.Operacao</b></TD>"							+CRLF
cLinFile	+= "<TD bgcolor='#6E8B3D' align='center'><FONT face=' Arial ' size=1 color='#FFFFFF'><b>Saldo</b></FONT></TD>"			+CRLF
cLinFile	+= "<TD bgcolor='#6E8B3D' align='center'><FONT face=' Arial ' size=1 color='#FFFFFF'><b>Maior Ac.</b></FONT></TD>"		+CRLF
cLinFile	+= "<TD bgcolor='#6E8B3D' align='center'><FONT face=' Arial ' size=1 color='#FFFFFF'><b>Data M.A.</b></FONT></TD>"		+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Vcto Real</b></TD>"			  				+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Dt.Baixa</b></TD>"			 					+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Atraso</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Vlr.Atraso</b></TD>"							+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Dias AV</b></TD>"								+CRLF
cLinFile	+= "<TD align='center' style='Background: #9AC0CD; font-style: Bold;'><b>Vlr.AV</b></TD>"								+CRLF
cLinFile	+= "</TR>"																												+CRLF

cFileCont	+= cLinFile
cLinFile	:= ""

FWrite( nHandle , cFileCont )

lFlag		:= .T.

//===========================================================================
//| Monta o conteúdo do arquivo                                             |
//===========================================================================
For nI := 1 To nTotReg
	
	IncProc( "["+ StrZero(nI,6) +"] de ["+ StrZero( nTotReg , 6 ) +"]" )
	If lFlag
	
		If	( SZY->ZY_PCVMAC == Val( StrTran( StrTran( aDadosAux[nI][08] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDMAC == CTOD( aDadosAux[nI][07] ) )	.OR.;
			( SZY->ZY_PCVPCO == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDTPC == CTOD( aDadosAux[nI][03] ) )	.OR.;
			( SZY->ZY_PCVULC == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDUCM == CTOD( aDadosAux[nI][03] ) )
			
			If CTOD( aDadosAux[nI][07] ) > YEARSUB( dDataRef , 1 )
			
				cLinFile		:= "<TR>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
 			Else
 			
				If	( SZY->ZY_PCVMAC == Val( StrTran( StrTran( aDadosAux[nI][08] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDMAC == CTOD( aDadosAux[nI][07] ) )	.OR.;
					( SZY->ZY_PCVPCO == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDTPC == CTOD( aDadosAux[nI][03] ) )	.OR.;
					( SZY->ZY_PCVULC == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDUCM == CTOD( aDadosAux[nI][03] ) )

					cLinFile	:= "<TR>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+ AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                    If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
     				  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
     				  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
                    Else
         			  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
      	    		  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                    EndIf
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
    				cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
	    			cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "</TR>"

                 Else

					cLinFile	:= "<TR>"
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                    If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
     				  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
         			  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
                    Else
       		    	  cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
       			      cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                    EndIf
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
    				cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
	    			cLinFile	+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
					cLinFile	+= "</TR>"
					
			     EndIf
			     
			EndIf
						
		Else

			If	CTOD( aDadosAux[nI][07] ) > YEARSUB( dDataRef , 1 )

				cLinFile		:= "<TR>"
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
    			cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
			Else
			
				cLinFile := "<TR>"
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][03]		 		+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
	            If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#FFFFFF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
			EndIf
					
		EndIf
		
		lFlag := .F.
		
	Else
	
		If	( SZY->ZY_PCVMAC == Val( StrTran( StrTran( aDadosAux[nI][08] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDMAC == CTOD( aDadosAux[nI][07] ) )	.OR.;
			( SZY->ZY_PCVPCO == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDTPC == CTOD( aDadosAux[nI][03] ) )	.OR.;
			( SZY->ZY_PCVULC == Val( StrTran( StrTran( aDadosAux[nI][06] ,".","" ) , "," , "." ) )	.And. SZY->ZY_PCDUCM == CTOD( aDadosAux[nI][03] ) )
			
			If CTOD( aDadosAux[nI][07] ) > YEARSUB( dDataRef , 1 )
			
				cLinFile		:= "<TR>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#FF0000' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#FF0000' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
			Else
			
				cLinFile		:= "<TR>"
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"				

			EndIf
			
		Else
		
			If	CTOD( aDadosAux[nI][07] ) > YEARSUB( dDataRef , 1 )
			
				cLinFile		:= "<TR>"
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>&nbsp</b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>&nbsp</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
    			cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#27408B' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
			Else
			
				cLinFile		:= "<TR>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][01] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][02] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][03]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][04] )	+"</b></FONT></TD>"+CRLF
                If Val( StrTran( StrTran( aDadosAux[nI][05] ,".","" ) , "," , "." ) ) > 0
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
                Else
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b> </b></FONT></TD>"+CRLF
      				cLinFile	+= "<TD bgcolor='#C6E2FF' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][06] )	+"</b></FONT></TD>"+CRLF
                EndIf
	    		cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][07]				+"</b></FONT></TD>"+CRLF
		        cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][08] )	+"</b></FONT></TD>"+CRLF
     			cLinFile		+= "<TD bgcolor='#CAFF70' align='right'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][09] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#CAFF70' align='center'><FONT face=' Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][10]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][11]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	aDadosAux[nI][12]				+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][13] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][14] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][17] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "<TD bgcolor='#C6E2FF' align='right'><FONT face='Arial ' size=1 color='#8B8989' ><b>"+	AllTrim( aDadosAux[nI][18] )	+"</b></FONT></TD>"+CRLF
				cLinFile		+= "</TR>"
				
			EndIf
			
		EndIf
		
		lFlag := .T.
		
	EndIf
	
	FWrite( nHandle , cLinFile )
	cLinFile := ""
	
Next nI

cLinFile := "</Table>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<table border='1' cellpadding='3' cellspacing='0' bordercolor='#8B8B83' bgColor='#FFFFFF'>"+CRLF
cLinFile += "<TR>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#6E8B3D' align='center'><FONT face=' Arial ' size=1 color='#FFFFFF'><b>Data Informação</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#6E8B3D' align='center'><FONT face=' Arial ' size=1 color='#FFFFFF'><b>"+DToC(SZY->ZY_PCDDAT)+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Cnpj</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+SZY->ZY_PCCCLI+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Data Cad.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+DToC(SZY->ZY_PCDCDD)+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Vlr.Maior.Acum.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCVMAC,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Data M.Acum</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+DToC(SZY->ZY_PCDMAC)+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile ) 

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Deb.Atual Total</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCVSAT,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Penúlt.Compra</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCVPCO,"@e 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Data Penúlt.Cp.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+DToC(SZY->ZY_PCDTPC)+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Ultima Compra.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCVULC,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Data Ult.Compra</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+DToC(SZY->ZY_PCDUCM)+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Pond.Atraso</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCQPAG,"@E 999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Aritm.Atraso</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCQDAP,"@E 999.99")+"</b></FONT></TD>"+CRLF  
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Vlr.Deb.a Venc.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCVDAV,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Pond.A Vc.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCMDAV,"@E 999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Prazo Med. Vd.</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCMPMV,"@E 999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Vencido +5 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCDATV,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Pond.+5 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCMPTV,"@E 999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Vencido +15 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCV15D,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Pond.+15 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCM15D,"@E 999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Vencido +30 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCV30D,"@E 9,999,999,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

cLinFile := "<TR>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#0000CD' ><b>Med.Pond.+30 dias</b></FONT></TD>"+CRLF
cLinFile += "<TD bgcolor='#C6E2FF' align='center'><FONT face='Arial ' size=1 color='#000000' ><b>"+Transform(SZY->ZY_PCM30D,"@E 9,999.99")+"</b></FONT></TD>"+CRLF
cLinFile += "</TR>"+CRLF
FWrite( nHandle , cLinFile )

//-- Acrescenta o rodape do html --//
FWrite( nHandle , cRodHtml )

//-- Libera o Arquivo --//
FClose(nHandle)

LjMsgRun( "Abrindo o arquivo..." , "Aguarde!" , {|| SHELLEXECUTE( "open" , cArqPesq , "" , "" , 5 ) } )

Return

/*/

===============================================================================================================================
Programa----------: MOMS027BR1
Autor-------------: Alexandre Villar
Data da Criacao---: 28/02/2014
===============================================================================================================================
Descrição---------: Monta os itens do Browse 1 - [Rotina atualizada] 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
/*/

Static Function MOMS027BR1()

Local oFont1 := TFont():New( "Arial" , 9 , 7 ,.T.,.F.,5,.T.,5,.T.,.F.)

aAdd( aWBrowse1 , {" "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "} )

@012,001 LISTBOX oWBrowse1	Fields HEADER	"Docto"		, "Parc."	, "Emissão"	, "CNPJ"	, "Valor Op."	, "Vlr Fat."	, "Data Op."	, "Saldo C/C "	, "Maior Acum. "	,;
											"Data M.A."	, "Vcto. "	, "Baixa"	, "Atraso"	, "Vlr Atr."	, "Data"		, "Valor"		, "Dias AV"		, "Vlr.AV"			 ;
							SIZE 400,220 FONT oFont1 OF oPanel1 PIXEL ColSizes 10,10,10,10,20,20,10,45,45,30,10,25,10,20,10,20,10,45

oWBrowse1:SetArray(aWBrowse1)

oWBrowse1:bLine := {|| {	aWBrowse1[oWBrowse1:nAt,01]	,;
							aWBrowse1[oWBrowse1:nAt,02]	,;
							aWBrowse1[oWBrowse1:nAt,03]	,;
							aWBrowse1[oWBrowse1:nAt,04]	,;
							aWBrowse1[oWBrowse1:nAt,05]	,;
							aWBrowse1[oWBrowse1:nAt,06]	,;
							aWBrowse1[oWBrowse1:nAt,07]	,;
							aWBrowse1[oWBrowse1:nAt,08]	,;
							aWBrowse1[oWBrowse1:nAt,09]	,;
							aWBrowse1[oWBrowse1:nAt,10]	,;
							aWBrowse1[oWBrowse1:nAt,11]	,;
							aWBrowse1[oWBrowse1:nAt,12]	,;
							aWBrowse1[oWBrowse1:nAt,13]	,;
							aWBrowse1[oWBrowse1:nAt,14]	,;
							aWBrowse1[oWBrowse1:nAt,15]	,;
							aWBrowse1[oWBrowse1:nAt,16]	,;
							aWBrowse1[oWBrowse1:nAt,17]	,;
							aWBrowse1[oWBrowse1:nAt,18]	}}
Return

/*
===============================================================================================================================
Programa----------: MOMS027CD1
Autor-------------: Alexandre Villar
Data da Criacao---: 01/04/2014
===============================================================================================================================
Descrição---------: Carrega os dados do Browse 1 - Rotina atualizada
===============================================================================================================================
Parametros--------: cCNPJ - Chave do CNPJ do Cliente
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027CD1(cnpj)

Local _dDataDE2	:= YEARSUB( dDataRef , 1 )
Local cQuery	:= ""

cQuery := " SELECT "
cQuery += " 	E1_NUM,"
cQuery += " 	E1_PARCELA,"
cQuery += " 	E1_EMISSAO,"
cQuery += " 	SubStr(A1_CGC,1,8) AS CNPJ,"
cQuery += " 	E1_VALOR,"
cQuery += " 	F2_VALFAT,"
cQuery += " 	E1_EMISSAO AS DATACC,"
cQuery += " 	0 AS SALDO,"
cQuery += " 	E1_VENCREA,"
cQuery += " 	Case WHEN E1_VENCREA >= '"+ DToS(_dDataDE2) +"' THEN ' ' Else E1_BAIXA END AS E1_BAIXA , "
cQuery += " 	0 AS DIATRA ,"
cQuery += " 	0 AS VLRCALC, "
cQuery += " 	'' AS DATAM,"
cQuery += " 	0 AS VLRM,"
cQuery += " 	Case WHEN E1_VENCREA >= '"+ DToS(Date()) +"' THEN E1_VALOR Else 0 END AS VLRDAV,"
cQuery += " 	Case WHEN E1_VENCREA > '"+ DToS(Date()) +"' THEN ABS( TO_DATE(E1_EMISSAO,'YYYYMMDD')-TO_DATE(E1_VENCREA,'YYYYMMDD') ) Else 0 END AS DIASAV, "
cQuery += " 	Case WHEN E1_VENCREA > '"+ DToS(Date()) +"' THEN ABS( TO_DATE(E1_EMISSAO,'YYYYMMDD')-TO_DATE(E1_VENCREA,'YYYYMMDD') ) * E1_VALOR Else 0 END AS VLRAVC,"
cQuery += " 	A1_LC,"
cQuery += " 	1 AS ORDEM"

cQuery += " FROM "+ RetSqlName("SE1") +" SE1"

cQuery += " INNER JOIN "+ RetSqlName("SA1") +" SA1 ON"
cQuery += " 		SE1.E1_CLIENTE	= SA1.A1_COD "
cQuery += " AND 	SE1.E1_LOJA		= SA1.A1_LOJA "
cQuery += " AND		SA1.A1_FILIAL	= '"+ xFilial("SA1") +"' "

cQuery += " INNER JOIN "+ RetSqlName("SF2") +" SF2 ON "
cQuery += " 	SE1.E1_FILIAL			= SF2.F2_FILIAL "
cQuery += " AND	SE1.E1_NUM				= SF2.F2_DOC "
cQuery += " AND	SE1.E1_PREFIXO			= SF2.F2_SERIE "
cQuery += " AND SE1.E1_CLIENTE			= SF2.F2_CLIENTE "
cQuery += " AND	SE1.E1_LOJA				= SF2.F2_LOJA "
cQuery += " AND	SF2.D_E_L_E_T_			= ' ' "

cQuery += " WHERE"
cQuery += " 		SE1.E1_EMISSAO	<= '"+ DToS(Date())	+"'"
cQuery += " AND (	SE1.E1_BAIXA	>= '"+ DToS(_dDataDE2)	+"' OR TRIM(SE1.E1_BAIXA) IS NULL )"
cQuery += " AND		SE1.E1_TIPO		NOT IN ( 'NCC' , 'RA', 'NDC' ) "
cQuery += " AND		SE1.D_E_L_E_T_	= ' ' "
cQuery += " AND	    SE1.E1_I_AVACC <> 'N' " 
cQuery += " AND     SE1.E1_VENCREA > '" + DToS(dDataRef - 1825) +"' "
cQuery += " AND		SA1.D_E_L_E_T_	= ' ' "
cQuery += " AND		SubStr(A1_CGC,1,8)	BETWEEN '"+CNPJ+"' AND '"+CNPJ+"' "

cQuery += " UNION ALL"

cQuery += " SELECT"
cQuery += " 	E1_NUM,"
cQuery += " 	E1_PARCELA,"
cQuery += " 	E1_EMISSAO,"
cQuery += " 	SubStr(A1_CGC,1,8) AS CNPJ, "
cQuery += " 	Case WHEN TRIM(E1_BAIXA) IS NOT NULL THEN (E1_VALOR*-1) END AS E1_VALOR,"
cQuery += " 	0 AS F2_VALFAT,"
cQuery += " 	Case WHEN TRIM(E1_BAIXA) IS NOT NULL THEN E1_BAIXA END AS DATACC,"
cQuery += " 	0 AS SALDO,"
cQuery += " 	E1_VENCREA,"
cQuery += " 	E1_BAIXA,"
cQuery += " 	Case "
cQuery += " 		WHEN ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE(E1_BAIXA,'YYYYMMDD') ) >= 0	THEN ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE(E1_BAIXA,'YYYYMMDD') ) "
cQuery += " 		WHEN TRIM(E1_BAIXA) IS NOT NULL AND E1_BAIXA > E1_VENCREA					THEN ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE('"+ DToS(Date()) +"','YYYYMMDD') ) "
cQuery += " 		WHEN TRIM(E1_BAIXA) IS NULL AND E1_VENCREA < '"+ DToS(Date())+"'		THEN ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE('"+ DToS(Date()) +"','YYYYMMDD') ) "
cQuery += " 		Else 0 END AS DIATRA,"
cQuery += " 	Case "
cQuery += " 		WHEN ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE(E1_BAIXA,'YYYYMMDD') ) >= 0	THEN ( E1_VALOR * ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE(E1_BAIXA,'YYYYMMDD') ) ) "
cQuery += " 		WHEN TRIM(E1_BAIXA) IS NOT NULL AND E1_BAIXA > E1_VENCREA					THEN ( E1_VALOR * ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE('"+ DToS(Date()) +"','YYYYMMDD') ) )"
cQuery += " 		WHEN TRIM(E1_BAIXA) IS NULL AND E1_VENCREA < '"+DToS(Date())+"'		THEN ( E1_VALOR * ABS( TO_DATE(E1_VENCREA,'YYYYMMDD')-TO_DATE('"+ DToS(Date()) +"','YYYYMMDD') ) )"
cQuery += " 		Else 0 END AS VLRCALC,"
cQuery += " 	'' AS DATAM,"
cQuery += " 	0 AS VLRM,"
cQuery += " 	0 AS VLRDAV,"
cQuery += " 	0 AS DIASAV,"
cQuery += " 	0 AS VLRAVC,"
cQuery += " 	A1_LC,"
cQuery += " 	2 AS ORDEM"
cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "

cQuery += " INNER JOIN "+ RetSqlName("SA1") +" SA1 ON"
cQuery += " 		SE1.E1_CLIENTE	= SA1.A1_COD"
cQuery += " AND	SE1.E1_LOJA		= SA1.A1_LOJA"
cQuery += " AND	SA1.D_E_L_E_T_	= ' ' "
cQuery += " AND	SA1.A1_FILIAL	= '"+ xFilial("SA1") +"' "

cQuery += " INNER JOIN "+ RetSqlName("SF2") +" SF2 ON "
cQuery += " 	SE1.E1_FILIAL			= SF2.F2_FILIAL "
cQuery += " AND	SE1.E1_NUM				= SF2.F2_DOC "
cQuery += " AND	SE1.E1_PREFIXO			= SF2.F2_SERIE "
cQuery += " AND SE1.E1_CLIENTE			= SF2.F2_CLIENTE "
cQuery += " AND	SE1.E1_LOJA				= SF2.F2_LOJA "
cQuery += " AND	SF2.D_E_L_E_T_			= ' ' "

cQuery += " WHERE"
cQuery += " 		SE1.E1_EMISSAO	<= '"+ DToS(Date()) +"'"
cQuery += " AND	SE1.E1_TIPO		NOT IN ( 'NCC' , 'RA', 'NDC' ) "
cQuery += " AND	SE1.D_E_L_E_T_	= ' ' "
cQuery += " AND	SE1.E1_I_AVACC <> 'N' " 
cQuery += " AND	SE1.E1_BAIXA	<> ' ' "
cQuery += " AND	SE1.E1_BAIXA	>= '"+ DToS(_dDataDE2) +"'"
cQuery += " AND	SE1.E1_VENCREA	< '"+ DToS(Date()) +"'"
cQuery += " AND SE1.E1_VENCREA > '" + DToS(dDataRef - 1825) +"' "
cQuery += " AND	SubStr(SA1.A1_CGC,1,8) BETWEEN  '"+CNPJ+"' AND '"+CNPJ+"' "

cQuery += " ORDER BY CNPJ , DATACC , E1_NUM , E1_PARCELA , ORDEM "

If Select("TRB1") > 0
	TRB1->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , "TRB1" , .T. , .F. )
DBSelectArea("TRB1")

//==================================================================================
// Fecha Alias se estiver em Uso 
//==================================================================================
If Select("TRD1") > 0
	TRD1->( DBCloseArea() )
EndIf

//==================================================================================
// Monta a interface padrao com o usuario...                           
//==================================================================================
aCampos :=	{	{ "E1_NUM"    , "C" , 06 , 0 } ,;
				{ "E1_PARCELA", "C" , 03 , 0 } ,;
				{ "E1_EMISSAO", "D" , 08 , 0 } ,;
				{ "CNPJ"      , "C" , 08 , 0 } ,;
				{ "E1_VALOR"  , "N" , 16 , 2 } ,;
				{ "F2_VALFAT" , "N" , 16 , 2 } ,;
				{ "DATACC"    , "D" , 08 , 0 } ,;
				{ "SALDO"     , "N" , 16 , 2 } ,; 
				{ "MAIORAC"   , "N" , 16 , 2 } ,; 
				{ "DATAMAC"   , "D" , 08 , 2 } ,; 
				{ "E1_VENCREA", "D" , 08 , 2 } ,;
				{ "E1_BAIXA"  , "D" , 08 , 0 } ,;
				{ "DIATRA"    , "N" , 09 , 0 } ,;
				{ "VLRCALC"   , "N" , 16 , 2 } ,;
				{ "DATAM"     , "D" , 08 , 0 } ,;
				{ "VLRM"      , "N" , 16 , 2 } ,;
				{ "DIASAV"    , "N" , 09 , 0 } ,;
				{ "VLRAVC"    , "N" , 16 , 2 }  }

_otemp := FWTemporaryTable():New( "TRD1", aCampos )

_otemp:Create()

xSaldo	:= 0 
xSaldo1	:= 0
xSalac	:= 0
xData 	:= SToD("")

While TRB1->(!Eof()) 

	xSaldo1	+= TRB1->E1_VALOR
   	xSaldo	+= TRB1->E1_VALOR 
   	
   	If xSaldo1 < 0
       xSaldo1 := 0
	   xSaldo  := 0
   	EndIf
   	
	TRD1->( RecLock( "TRD1" , .T. ) )
	
		TRD1->E1_NUM		:= TRB1->E1_NUM
		TRD1->E1_PARCELA	:= TRB1->E1_PARCELA
		TRD1->E1_EMISSAO	:= SToD( TRB1->E1_EMISSAO )
		TRD1->CNPJ			:= TRB1->CNPJ
		TRD1->E1_VALOR		:= TRB1->E1_VALOR
		TRD1->F2_VALFAT		:= TRB1->F2_VALFAT
		TRD1->DATACC		:= SToD( TRB1->DATACC )
		
	    If xSaldo1 >= xSalac .And. SToD( TRB1->DATACC ) >= _dDataDE2
		    xSalac			:= xSaldo
		    xData			:= SToD( TRB1->DATACC )
		EndIf
		
		TRD1->E1_VENCREA	:= SToD( TRB1->E1_VENCREA )
		TRD1->E1_BAIXA		:= SToD( TRB1->E1_BAIXA )
		TRD1->DIATRA		:= TRB1->DIATRA
		TRD1->VLRCALC		:= TRB1->VLRCALC
		TRD1->DATAM			:= SToD( TRB1->DATAM )
		TRD1->VLRM			:= TRB1->VLRM
		TRD1->DIASAV		:= TRB1->DIASAV
		TRD1->VLRAVC		:= TRB1->VLRAVC
	   	TRD1->MAIORAC		:= xSalac
	    TRD1->DATAMAC		:= xData
		TRD1->SALDO			:= XSALDO
		
	TRD1->( MSUnLock() )
	
TRB1->(DBSkip())
EndDo

TRD1->( DBGoTop() )
xSaldo := 0

If TRD1->( !Eof() )

	aWBrowse1 := {}

	While TRD1->(!Eof())
	
		xSaldo += TRD1->E1_VALOR 
		
		aAdd( aWBrowse1 , {	AllTrim(	TRD1->E1_NUM )	  							,;
							AllTrim(	TRD1->E1_PARCELA )							,;
							DToC(		TRD1->E1_EMISSAO )							,;
							AllTrim(	TRD1->CNPJ )								,;
							TRANSFORM(	TRD1->E1_VALOR	, "@e 9,999,999,999.99" )	,;
							TRANSFORM(	TRD1->F2_VALFAT	, "@e 9,999,999,999.99" )	,;
							DToC(		TRD1->DATACC )								,;
							TRANSFORM(	TRD1->SALDO		, "@e 9,999,999,999.99" )	,;
							TRANSFORM(	TRD1->MAIORAC	, "@e 9,999,999,999.99" )	,;		
							DToC(		TRD1->DATAMAC )								,;		
							DToC(		TRD1->E1_VENCREA )							,;
							DToC(		TRD1->E1_BAIXA )							,;
							TRANSFORM(	TRD1->DIATRA	, "@e 999,999" )			,;
							TRANSFORM(	TRD1->VLRCALC	, "@e 9,999,999,999.99" )	,;
							DToC(		TRD1->DATAM )								,;
							TRANSFORM(	TRD1->VLRM		, "@e 9,999,999,999.99" )	,;
							TRANSFORM(	TRD1->DIASAV	, "@e 999,999")	  			,;
							TRANSFORM(	TRD1->VLRAVC	, "@e 9,999,999,999.99" )	})
		
	TRD1->(DBSkip())
	EndDo
	
Else

	cGet3		:= " "
	cGet4		:= " "
	aWBrowse1	:= {}
	
	aAdd( aWBrowse1 , {" "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "} )
	U_ITMsg( "Cnpj sem movimento!" , "Atenção",,1 )
	
EndIf

oWBrowse1:SetArray(aWBrowse1)
oWBrowse1:bLine := {|| {	aWBrowse1[oWBrowse1:nAt,01]		,;
							aWBrowse1[oWBrowse1:nAt,02]		,;
							aWBrowse1[oWBrowse1:nAt,03]		,;
							aWBrowse1[oWBrowse1:nAt,04]		,;
							aWBrowse1[oWBrowse1:nAt,05]		,;
							aWBrowse1[oWBrowse1:nAt,06]		,;
							aWBrowse1[oWBrowse1:nAt,07]		,;
							aWBrowse1[oWBrowse1:nAt,08]		,;
							aWBrowse1[oWBrowse1:nAt,09]		,;
							aWBrowse1[oWBrowse1:nAt,10]		,;
							aWBrowse1[oWBrowse1:nAt,11]		,;
							aWBrowse1[oWBrowse1:nAt,12]		,;
							aWBrowse1[oWBrowse1:nAt,13]		,;
							aWBrowse1[oWBrowse1:nAt,14]		,;
							aWBrowse1[oWBrowse1:nAt,15]		,;
							aWBrowse1[oWBrowse1:nAt,16]		,;
							aWBrowse1[oWBrowse1:nAt,17]		,;
							aWBrowse1[oWBrowse1:nAt,18]		}}
							
Return

/*
===============================================================================================================================
Programa----------: MOMS027I
Autor-------------: Alexandre Villar
Data da Criacao---: 30/04/2014
===============================================================================================================================
Descrição---------: Importa o arquivo gerado e exibe na tela com opção de exportação pra Excel
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027I()

Local oDlg		:= Nil
Local oBtnAux	:= Nil
Local cArqAux	:= Space(150)
Local nOpc		:= 0

//===========================================================================
//| Solicita a indicação do diretório de destino                            |
//===========================================================================
DEFINE MSDIALOG oDlg TITLE "Validação de Arquivo [TXT]" FROM 0,0 TO 060,552 OF oDlg PIXEL

	@005,005 Say "Selecione o Arquivo:"				SIZE 065,010 PIXEL OF oDlg COLOR CLR_HBLUE
	@014,005 MSGET cArqAux PICTURE "@!"				SIZE 195,010 PIXEL OF oDlg
	
	@029,400 BTNBMP oBtnAux RESOURCE "OPEN_OCEAN"	SIZE 025,025 PIXEL OF oDlg ACTION ( cArqAux := cGetFile( "*.txt" , "Selecione o Diretorio de Destino:" , 1 , "C:\" , .F. , GETF_LOCALHARD + GETF_NETWORKDRIVE ) )
	
	@004,245 BUTTON "&Ok"							SIZE 030,011 PIXEL OF oDlg ACTION ( nOpc := 1 , oDlg:End() )
	@016,245 BUTTON "&Cancelar"						SIZE 030,011 PIXEL OF oDlg ACTION ( nOpc := 0 , oDlg:End() )

ACTIVATE MSDIALOG oDlg CENTER

//===========================================================================
//| Verifica a opção e a pasta de destino                                   |
//===========================================================================
If nOpc == 1

	cArqAux := AllTrim(cArqAux)
	Processa( {|| MOMS027VT( cArqAux ) } , "Lendo Arquivo TXT..." , "Aguarde!" , .F. )
	
Else

	U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027VT
Autor-------------: Alexandre Villar
Data da Criacao---: 30/04/2014
===============================================================================================================================
Descrição---------: Monta os dados e prepara a exportação para Excel
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027VT( cArqAux )

Local aColAux	:= {}
Local aHeader	:= {}
Local cBuffer	:= ""
Local lValida	:= .F.
Local nHdlAux	:= FT_FUSE( cArqAux )
Local nLinha	:= 0
Local nTotReg	:= 0
Local nRegVal	:= 0 , nI

If nHdlAux == -1
	U_ITMsg( "Não foi possível abrir o arquivo informado! Verifique o arquivo e tente novamente.","Atenção",,1 )
	Return
EndIf

nTotReg := FT_FLastRec()

If nTotReg > 0

	aHeader := {	"Tipo Ident."					,; //| 01 |
					"Código Associado"				,; //| 02 |
					"Id. Cliente"					,; //| 03 |
					"Data da Informação"			,; //| 04 |
					"Data Inc. do Cliente" 			,; //| 05 |
					"Data da Última Compra"			,; //| 06 |
					"Valor da Última Compra"		,; //| 07 |
					"Data do Maior Acúmulo"			,; //| 08 |
					"Valor Maior Acúmulo"			,; //| 09 |
					"Valor Débito Atual Total"		,; //| 10 |
					"Valor Limite de Crédito"		,; //| 11 |
					"M.P. de Atrasos"				,; //| 12 |
					"M.A. de Atrasos"				,; //| 13 |
					"Valor Débito a Vencer"			,; //| 14 |
					"M.P. a Vencer"					,; //| 15 |
					"Prazo Médio de Vendas"			,; //| 16 |
					"Valor Vencido (>5 Dias)"		,; //| 17 |
					"M.P. Vencidos (>5 Dias)"		,; //| 18 |
					"Valor Vencido (>15 Dias)"		,; //| 19 |
					"M.P. Vencidos (>15 Dias)"		,; //| 20 |
					"Valor Vencido (>30 Dias)"		,; //| 21 |
					"M.P. Vencidos (>30 Dias)"		,; //| 22 |
					"Data da Penúltima Compra"		,; //| 23 |
					"Valor da Penúltima Compra"		,; //| 24 |
					"Cálculo Limite de Crédito"		,; //| 25 |
					"Tipo de Garantia"				,; //| 26 |
					"Grau da Garantia"				,; //| 27 |
					"Data Validade da Garantia"		,; //| 28 |
					"Valor da Garantia"				,; //| 29 |
					"Valor Pagamento Antecipado"	,; //| 30 |
					"Venda sem Crédito"				 } //| 31 |
	
	ProcRegua( nTotReg )
	
	FT_FGoTop()
	
	While !FT_FEOF()
	
		cBuffer	:= FT_FReadLn()
		nLinha++
		IncProc( "["+ StrZero( nLinha , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]" )
		
		If !Empty(cBuffer) .And. Len( cBuffer ) == 280
			
			aAdd( aColAux , {	SubStr( cBuffer , 001 , 01 )									,; //01	PCTIPO	N 01 001 / 001	Identif. (1-CNPJ / 2-CPF / 3-RG / 4-Export. / 5-Insc.Prod./ 9-Outros)
								SubStr( cBuffer , 002 , 04 )									,; //02	PCCASS	N 04 002 / 005	Código do Associado
								SubStr( cBuffer , 006 , 20 )									,; //03	PCCCLI	N 20 006 / 025	Identificação. (CNPJ / CPF / RG / Export. / Insc.Prod. / Outros)
								SubStr( cBuffer , 026 , 08 )									,; //04	PCDDAT	N 08 026 / 033	Data da Informação
								SubStr( cBuffer , 034 , 08 )									,; //05	PCDCDD	N 08 034 / 041	Data  Cadastramento do Cliente
								SubStr( cBuffer , 042 , 08 )									,; //06	PCDUCM	N 08 042 / 049	Data da Última Compra
								SubStr( cBuffer , 050 , 13 ) +"."+ SubStr( cBuffer , 063 , 02 )	,; //07	PCVULC	N 15 050 / 064	Valor da Última Compra
								SubStr( cBuffer , 065 , 08 )									,; //08	PCDMAC	N 08 065 / 072	Data  do Maior Acúmulo
								SubStr( cBuffer , 073 , 13 ) +"."+ SubStr( cBuffer , 086 , 02 )	,; //09	PCVMAC	N 15 073 / 087	Valor Maior Acúmulo
								SubStr( cBuffer , 088 , 13 ) +"."+ SubStr( cBuffer , 101 , 02 )	,; //10	PCVSAT	N 15 088 / 102	Valor Débito Atual Total
								SubStr( cBuffer , 103 , 13 ) +"."+ SubStr( cBuffer , 116 , 02 )	,; //11	PCVLCR	N 15 103 / 117	Valor Limite de Crédito
								SubStr( cBuffer , 118 , 04 ) +"."+ SubStr( cBuffer , 122 , 02 )	,; //12	PCQPAG	N 06 118 / 123	Média Ponderada de Atraso (Títulos Pagos)
								SubStr( cBuffer , 124 , 04 ) +"."+ SubStr( cBuffer , 128 , 02 )	,; //13	PCQDAP	N 06 124 / 129	Média Aritm.Dias de Atraso Pagamento
								SubStr( cBuffer , 130 , 13 ) +"."+ SubStr( cBuffer , 143 , 02 )	,; //14	PCVDAV	N 15 130 / 144	Valor Débito Atual a Vencer
								SubStr( cBuffer , 145 , 04 ) +"."+ SubStr( cBuffer , 149 , 02 )	,; //15	PCMDAV	N 06 145 / 150	Média Ponderada de Títulos a Vencer
								SubStr( cBuffer , 151 , 04 ) +"."+ SubStr( cBuffer , 155 , 02 )	,; //16	PCMPMV	N 06 151 / 156	Prazo Médio de Vendas 
								SubStr( cBuffer , 157 , 13 ) +"."+ SubStr( cBuffer , 170 , 02 )	,; //17	PCDATV	N 15 157 / 171	Valor Débito Atual Vencido + 5 Dias
								SubStr( cBuffer , 172 , 04 )									,; //18	PCMPTV	N 04 172 / 175	Média Ponderada de Atraso + 5 Dias
								SubStr( cBuffer , 176 , 13 ) +"."+ SubStr( cBuffer , 189 , 02 )	,; //19	PCV+15D	N 15 176 / 190	Valor Débito Atual Vencido + 15 Dias
								SubStr( cBuffer , 191 , 04 )									,; //20	PCM+15D	N 04 191 / 194	Média Ponderada de Atraso + 15 Dias
								SubStr( cBuffer , 195 , 13 ) +"."+ SubStr( cBuffer , 208 , 02 )	,; //21	PCV+30D	N 15 195 / 209	Valor Débito Atual Vencido + 30 Dias
								SubStr( cBuffer , 210 , 04 )									,; //22	PCM+30D	N 04 210 / 213	Média Ponderada de Atraso + 30 Dias
								SubStr( cBuffer , 214 , 08 )									,; //23	PCDTPC	N 08 214 / 221	Data da Penúltima Compra
								SubStr( cBuffer , 222 , 13 ) +"."+ SubStr( cBuffer , 235 , 02 )	,; //24	PCVPCO	N 15 222 / 236	Valor da Penúltima Compra
								SubStr( cBuffer , 237 , 01 )									,; //25	PCVSIT	N 01 237 / 237	Situação do Cálculo Limite de Crédito
								SubStr( cBuffer , 238 , 01 )									,; //26	PCTIPG	N 01 238 / 238	Tipo de Garantia
								SubStr( cBuffer , 239 , 02 )									,; //27	PCGGA	N 02 239 / 240	Grau da Garantia - Hipoteca
								SubStr( cBuffer , 241 , 08 )									,; //28	PCDTG	N 08 241 / 248	Data Validade da Garantia
								SubStr( cBuffer , 249 , 13 ) +"."+ SubStr( cBuffer , 262 , 02 )	,; //29	PCVLG	N 15 249 / 263	Valor da Garantia
								SubStr( cBuffer , 264 , 13 ) +"."+ SubStr( cBuffer , 277 , 02 )	,; //30	PCVPA	N 15 264 / 278	Valor da Venda Pagamento Antecipado
								SubStr( cBuffer , 279 , 02 )									}) //31	PCSVV	C 02 279 / 280	Venda sem Crédito (ANTECIPADO)
		
		EndIf
		
	FT_FSKIP()
	EndDo
	
	If Empty( aColAux )
		U_ITMsg(  "Não foram encontrados registros válidos para exibir! Verifique o arquivo e tente novamente." , "Atenção!",,1 )
	Else
		
		nRegVal := Len( aColAux )
		
		ProcRegua( nRegVal )
		
		For nI := 1 To nRegVal
		
			IncProc( "["+ StrZero( nI , 9 ) +"] de ["+ StrZero( nRegVal , 9 ) +"]" )
			
			//===========================================================================
			//| Ajusta formato dos campos de Data                                       |
			//===========================================================================
			aColAux[nI][04] := SToD(	aColAux[nI][04] )
			aColAux[nI][05] := SToD(	aColAux[nI][05] )
			aColAux[nI][06] := SToD(	aColAux[nI][06] )
			aColAux[nI][08] := SToD(	aColAux[nI][08] )
			aColAux[nI][23] := SToD(	aColAux[nI][23] )
			aColAux[nI][28] := SToD(	aColAux[nI][28] )
			
			//===========================================================================
			//| Ajusta formato dos campos de Valor                                      |
			//===========================================================================
			aColAux[nI][07] := Val(		aColAux[nI][07] )
			aColAux[nI][09] := Val(		aColAux[nI][09] )
			aColAux[nI][10] := Val(		aColAux[nI][10] )
			aColAux[nI][11] := Val(		aColAux[nI][11] )
			aColAux[nI][12] := Val(		aColAux[nI][12] )
			aColAux[nI][13] := Val(		aColAux[nI][13] )
			aColAux[nI][14] := Val(		aColAux[nI][14] )
			aColAux[nI][15] := Val(		aColAux[nI][15] )
			aColAux[nI][16] := Val(		aColAux[nI][16] )
			aColAux[nI][17] := Val(		aColAux[nI][17] )
			aColAux[nI][18] := Val(		aColAux[nI][18] )
			aColAux[nI][19] := Val(		aColAux[nI][19] )
			aColAux[nI][20] := Val(		aColAux[nI][20] )
			aColAux[nI][21] := Val(		aColAux[nI][21] )
			aColAux[nI][22] := Val(		aColAux[nI][22] )
			aColAux[nI][24] := Val(		aColAux[nI][24] )
			aColAux[nI][29] := Val(		aColAux[nI][29] )
			aColAux[nI][30] := Val(		aColAux[nI][30] )
		
		Next nI
		
		//===========================================================================
		//| Chama a rotina que constrói a tela e permite a exportação               |
		//===========================================================================
		lValida := U_ITListBox( "Leitura do Arquivo CISP: ["+ StrZero( nRegVal , 9 ) +"] registros." , aHeader , aColAux , .T. )
		
		If lValida .And. U_ITMsg( "Deseja processar a validação dos dados do arquivo?" , "Atenção!" ,,3,2,2 ) 
			LjMsgRun( "Validando dados do arquivo..." , "Aguarde!" , {|| MOMS027VAR(aColAux) } )
		EndIf
	
	EndIf

Else

	U_ITMsg(  "O arquivo está vazio ou é inválido para análise! Verifique o arquivo e tente novamente." , "Atenção!" ,,1 )

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027VAR
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Rotina de validação das informações da Base CISP
===============================================================================================================================
Parametros--------: aDados	- Array com os dados do arquivo para validação
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027VAR( aDados )

Local aDadosAux	:= {}
Local lValid	:= .F.
Local nI		:= 0
Local nTotReg	:= 0
                  
//===========================================================================
//| Posiciona no alias da base CISP                                         |
//===========================================================================
nTotReg := Len( aDados )

ProcRegua(nTotReg)

//===========================================================================
//| Processa a validação dos conteúdos                                      |
//===========================================================================
While nI < nTotReg
	
	nI++
	IncProc( "["+ StrZero( nI , 9 ) +"] de ["+ StrZero( nTotReg , 9 ) +"]" )

//01	PCTIPO	N 01 001 / 001	Identif. (1-CNPJ / 2-CPF / 3-RG / 4-Export. / 5-Insc.Prod./ 9-Outros)
//02	PCCASS	N 04 002 / 005	Código do Associado
//03	PCCCLI	N 20 006 / 025	Identificação. (CNPJ / CPF / RG / Export. / Insc.Prod. / Outros)
//04	PCDDAT	N 08 026 / 033	Data da Informação
//05	PCDCDD	N 08 034 / 041	Data  Cadastramento do Cliente
//06	PCDUCM	N 08 042 / 049	Data da Última Compra
//07	PCVULC	N 15 050 / 064	Valor da Última Compra
//08	PCDMAC	N 08 065 / 072	Data  do Maior Acúmulo
//09	PCVMAC	N 15 073 / 087	Valor Maior Acúmulo
//10	PCVSAT	N 15 088 / 102	Valor Débito Atual Total
//11	PCVLCR	N 15 103 / 117	Valor Limite de Crédito
//12	PCQPAG	N 06 118 / 123	Média Ponderada de Atraso (Títulos Pagos)
//13	PCQDAP	N 06 124 / 129	Média Aritm.Dias de Atraso Pagamento
//14	PCVDAV	N 15 130 / 144	Valor Débito Atual a Vencer
//15	PCMDAV	N 06 145 / 150	Média Ponderada de Títulos a Vencer
//16	PCMPMV	N 06 151 / 156	Prazo Médio de Vendas 
//17	PCDATV	N 15 157 / 171	Valor Débito Atual Vencido + 5 Dias
//18	PCMPTV	N 04 172 / 175	Média Ponderada de Atraso + 5 Dias
//19	PCV+15D	N 15 176 / 190	Valor Débito Atual Vencido + 15 Dias
//20	PCM+15D	N 04 191 / 194	Média Ponderada de Atraso + 15 Dias
//21	PCV+30D	N 15 195 / 209	Valor Débito Atual Vencido + 30 Dias
//22	PCM+30D	N 04 210 / 213	Média Ponderada de Atraso + 30 Dias
//23	PCDTPC	N 08 214 / 221	Data da Penúltima Compra
//24	PCVPCO	N 15 222 / 236	Valor da Penúltima Compra
//25	PCVSIT	N 01 237 / 237	Situação do Cálculo Limite de Crédito
//26	PCTIPG	N 01 238 / 238	Tipo de Garantia
//27	PCGGA	N 02 239 / 240	Grau da Garantia - Hipoteca
//28	PCDTG	N 08 241 / 248	Data Validade da Garantia
//29	PCVLG	N 15 249 / 263	Valor da Garantia
//30	PCVPA	N 15 264 / 278	Valor da Venda Pagamento Antecipado
//31	PCSVV	C 02 279 / 280	Venda sem Crédito (ANTECIPADO)

	//===========================================================================
	//| Verifica o preenchimento da data de cadastro                            |
	//===========================================================================
	If Empty( aDados[nI][05] )
		lValid := .T.
		aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data de cadastro do Cliente está em branco." } )
	ElseIf aDados[nI][05] > aDados[nI][04]
		lValid := .T.
		aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data de cadastro do Cliente é maior que a data de atualização da base." } )
	EndIf
	
	//===========================================================================
	//| Só valida clientes que possuem registro de data de última compra.       |
	//===========================================================================
	If !Empty(aDados[nI][06])
		
		//===========================================================================
		//| Só valida clientes que possuem registro de valor da última compra.      |
		//===========================================================================
		If !Empty(aDados[nI][07]) .And. aDados[nI][07] > 0

			//===========================================================================
			//| Validações da Data de Última Compra                                     |
			//===========================================================================
			If aDados[nI][06] > aDados[nI][04]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data da última compra é maior que a data de atualização da base." } )
			EndIf
			
			If aDados[nI][06] < aDados[nI][05]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data da última compra é menor do que a data de cadastro do Cliente." } )
			EndIf
			
			If aDados[nI][06] <= aDados[nI][23]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data da última compra é menor ou igual do que a data da penúltima compra." } )
			EndIf
			
			//===========================================================================
			//| Validações da Data de Maior Acúmulo do Cliente                          |
			//===========================================================================
			If aDados[nI][08] > aDados[nI][04]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data de maior acúmulo é maior do que a data de atualização da base." } )
			EndIf
			
			If aDados[nI][08] < aDados[nI][05]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data de maior acúmulo é menor do que a data de cadastro do Cliente." } )
			EndIf
			
			If aDados[nI][08] > aDados[nI][06]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Data de maior acúmulo é maior do que a data da última compra." } )
			EndIf
			
				
			//===========================================================================
			//| Validações do Valor de Maior Acúmulo do Cliente                         |
			//===========================================================================
			If aDados[nI][09] < aDados[nI][10]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O valor do maior acúmulo é menor do que o valor do saldo atual do Cliente." } )
			EndIf
			
			If aDados[nI][09] < aDados[nI][07]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O valor do maior acúmulo é menor do que o valor da última compra do Cliente." } )
			EndIf
			
			//===========================================================================
			//| Validações do Valor do Saldo Atual do Cliente                           |
			//===========================================================================
			If aDados[nI][10] < aDados[nI][14]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual é menor do que o saldo atual à vencer do Cliente." } )
			EndIf
			
			If aDados[nI][10] < aDados[nI][17]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual é menor do que o saldo vencido (+5) do Cliente." } )
			EndIf
			
			If aDados[nI][10] < aDados[nI][19]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual é menor do que o saldo vencido (+15) do Cliente." } )
			EndIf
			
			If aDados[nI][10] < aDados[nI][21]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual é menor do que o saldo vencido (+30) do Cliente." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Ponderada de Atrasos do Cliente                      |
			//===========================================================================
			If aDados[nI][12] == 0 .And. aDados[nI][13] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de atrasos é igual a zero e a média aritmética não é igual a zero." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Aritmética de Atrasos do Cliente                     |
			//===========================================================================
			If aDados[nI][13] == 0 .And. aDados[nI][12] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média aritmética de atrasos é igual a zero e a média ponderada não é igual a zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo Atual à vencer do Cliente                            |
			//===========================================================================
			If aDados[nI][14] > aDados[nI][10]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual à vencer é maior que o saldo total atual do Cliente." } )
			EndIf
			
			If aDados[nI][14] == 0 .And. aDados[nI][15] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual à vencer é igual a zero e foi calculada a média ponderada de títulos à vencer." } )
			EndIf
			
			If aDados[nI][14] == 0 .And. aDados[nI][16] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo atual à vencer é igual a zero e foi calculada a média de prazo à vencer." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média Ponderada à vencer do Cliente                        |
			//===========================================================================
			If aDados[nI][15] == 0 .And. aDados[nI][14] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de títulos à vencer é igual a zero e o saldo à vencer é maior que zero." } )
			EndIf
			
			If aDados[nI][15] == 0 .And. aDados[nI][16] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de títulos à vencer é igual a zero e a média de prazo à vencer é maior que zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Prazo Médio à vencer do Cliente                            |
			//===========================================================================
			If aDados[nI][16] == 0 .And. aDados[nI][14] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O prazo médio à vencer é igual a zero e o saldo à vencer é maior que zero." } )
			EndIf
			
			If aDados[nI][16] == 0 .And. aDados[nI][15] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O prazo médio à vencer é igual a zero e a média ponderada à vencer é maior que zero." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+5) do Cliente                            |
			//===========================================================================
			If aDados[nI][17] > aDados[nI][10]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+5) é maior que o saldo total atual do Cliente." } )
			EndIf
			
			If aDados[nI][17] == 0 .And. aDados[nI][18] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+5) é igual a zero e foi calculada média ponderada de vencidos (+5)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+5) do Cliente                    |
			//===========================================================================
			If aDados[nI][18] <> 0 .And. aDados[nI][18] < 5
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+5) é menor do que 5." } )
			EndIf
			
			If aDados[nI][18] == 0 .And. aDados[nI][17] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+5) é igual a zero e existe saldo vencido (+5)." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+15) do Cliente                            |
			//===========================================================================
			If aDados[nI][19] > aDados[nI][17]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+15) é maior que o saldo vencido (+5)." } )
			EndIf
			
			If aDados[nI][19] == 0 .And. aDados[nI][20] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+15) é igual a zero e foi calculada média ponderada vencida (+15)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+15) do Cliente                   |
			//===========================================================================
			If aDados[nI][20] <> 0 .And. aDados[nI][20] < 15
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+15) é menor do que 15." } )
			EndIf
			
			If aDados[nI][20] == 0 .And. aDados[nI][19] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+15) é igual a zero e existe saldo vencido (+15)." } )
			EndIf
			
			//===========================================================================
			//| Validação do Saldo à vencido (+30) do Cliente                            |
			//===========================================================================
			If aDados[nI][21] > aDados[nI][19]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+30) é maior que o saldo vencido (+15)." } )
			EndIf
			
			If aDados[nI][21] == 0 .And. aDados[nI][22] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "O saldo vencido (+30) é igual a zero e foi calculada média ponderada vencida (+30)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Média ponderada vencida (+30) do Cliente                   |
			//===========================================================================
			If aDados[nI][22] <> 0 .And. aDados[nI][22] < 30
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+30) é menor do que 30." } )
			EndIf
			
			If aDados[nI][22] == 0 .And. aDados[nI][21] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A média ponderada de vencidos (+30) é igual a zero e existe saldo vencido (+30)." } )
			EndIf
			
			//===========================================================================
			//| Validação da Data da Penúltima Compra do Cliente                        |
			//===========================================================================
			If aDados[nI][23] == aDados[nI][06]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A data da penúltima compra é igual à data de última compra." } )
			EndIf
			
			If aDados[nI][23] > aDados[nI][06]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A data da penúltima compra é maior que a data de última compra." } )
			EndIf
			
			If Empty( aDados[nI][23] ) .And. aDados[nI][24] <> 0
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Não foi registrada a data da penúltima compra e o valor da penúltima compra é maior que zero." } )
			EndIf
			
			If !Empty( aDados[nI][23] ) .And. aDados[nI][23] < aDados[nI][05]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "A data da penúltima compra é anterior à data de cadastro do Cliente." } )
			EndIf
			
			If Empty( aDados[nI][23] ) .And. !Empty( aDados[nI][06] ) .And. !Empty( aDados[nI][08] ) .And. aDados[nI][06] <> aDados[nI][08]
				lValid := .T.
				aAdd( aDadosAux , { StrZero(nI,6) , aDados[nI][03] , "Não foi registrada a data da penúltima compra e a data de maior acúmulo é diferente da data de última compra." } )
			EndIf
			
		EndIf
		
	EndIf
	
SZY->(DBSkip())
EndDo

SZY->(DBGoTop())

//===========================================================================
//| Verifica se existem inconsistências e exibe informações caso necessário |
//===========================================================================
If lValid
	MsgInfo( "Foram encontradas inconsistências durante a validação! É recomendado executar a atualização da base antes de gerar um novo arquivo para enviar." , "Atenção!" )
	U_ITListBox( "Inconsistências" , { "Linha" , "CNPJ" , "Mensagem" } , aDadosAux )
Else
	MsgInfo( "Todos os registros foram validados com sucesso!" , "Concluído!" )
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027MSG
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Define a mensagem para envio do e-mail.
===============================================================================================================================
Parametros--------: aDados	- Array com os dados do arquivo para validação
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS027MSG( nOpc )

Local cMsgAux	:= ""

Default nOpc	:= 1

cMsgAux := '<HMTL>'
cMsgAux += '<HEAD>'
cMsgAux += '<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
cMsgAux += '<TITLE>Arquivo CISP</TITLE>'
cMsgAux += '</HEAD>'
cMsgAux += '<BODY><br>'
cMsgAux += '<FONT FACE="Courier New" Style="font-size:12px">'
cMsgAux	+= 'Processamento do envio de Arquivos para a CISP para atualização de bases:<br>'
cMsgAux += '-------------------------------------------------------------------------------------------------------<br>'
cMsgAux += ' Ambiente.........: '+ GetEnvServer() +'<br>'
cMsgAux += ' Data Proc........: '+ DToC( Date() ) +'<br>'
cMsgAux += ' Hora.............: '+ Time() +'<br>'
cMsgAux += '-------------------------------------------------------------------------------------------------------<br>'

If nOpc == 1
	cMsgAux += 'O arquivo anexo foi gerado com base na última atualização (Verificar a data da base no arquivo).<br><br>'
Else
	cMsgAux += 'O arquivo anexo contém o LOG de erros da validação dos dados da base atualizada.<br><br>'
EndIf

cMsgAux += '=======================================================================================================<br>'
cMsgAux += '<i><b> Atenção: essa é uma mensagem automática, favor não responder. </b></i>                          <br>'
cMsgAux += '=======================================================================================================<br>'
cMsgAux += '</FONT>'
cMsgAux += '</BODY>'
cMsgAux += '</HMTL>'

Return( cMsgAux )

/*
===============================================================================================================================
Programa----------: MOMS027R
Autor-------------: Alexandre Villar
Data da Criacao---: 07/03/2014
===============================================================================================================================
Descrição---------: Monta a mensagem de e-mail com o log de erros de validação.
===============================================================================================================================
Parametros--------: aDados	- Array com os dados do arquivo para validação
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS027R( aValid )

Local nHandle	:= 0
Local nI		:= 0
Local nConta	:= 0

Local _cNArq1	:= AllTrim( GetMV( "IT_CISPDIR" ,, "\data\CISP\" ) ) + "Log_Validacao_"+ DToS(Date()) +"_"+ StrTran( Time() , ":" , "" ) +".txt"

Local cEmailTo	:= Lower( AllTrim( GetMV( "IT_CISPDEV" ,, "sistema@italac.com.br"		) ) )
Local cEmailCo	:= Lower( AllTrim( GetMV( "IT_CISPCOV" ,, ""							) ) )
Local cEmailBcc	:= Lower( AllTrim( GetMV( "IT_CISPOOV" ,, ""							) ) )

Local cAssunto	:= "Arquivo CISP - Falha de Validação da Base: "+ SubStr( DToS( dDataRef ) , 7 , 2 ) +"-"+ SubStr( DToS( dDataRef ) , 5 , 2 ) +"-"+ SubStr( DToS( dDataRef ) , 1 , 4 )
Local cMensagem	:= MOMS027MSG( 2 )
Local aConfig	:= U_ITCFGEML( AllTrim( GetMV( "IT_CISPCFG" ,, "002" ) ) ) //Configuração de e-mail a ser considerada para o envio (Tabela Z02)
Local cLog		:= ""

Default aValid	:= {}

If !Empty(aValid)
	
	nHandle := FCreate( _cNArq1 )
	
	If nHandle == -1
	
		Return
		
	EndIf
	
	For nI := 1 To Len(aValid)
	    
		cLinha := "Cliente: "+ aValid[nI][01] +" - "+ aValid[nI][02] + CRLF
		
		FWrite( nHandle , cLinha )
		
		nConta++
		
	Next nI
	
	FClose( nHandle )
	
	If nConta > 0
		
		U_ITENVMAIL( aConfig[01] , cEmailTo , cEmailCo , cEmailBcc , cAssunto , cMensagem , _cNArq1 , aConfig[01] , aConfig[02] , aConfig[03] , aConfig[04] , aConfig[05] , aConfig[06] , aConfig[07] , @cLog )
		
	Else
		
		For nI := 0 To 5 // Tentativas de exclusao do arquivo
		
			If FERASE(_cNArq1) <> -1
				lProcOk := .T.
				Exit
			EndIf
			
		SLEEP( 5000 )
		Next nI
		
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS027K
Autor-------------: Josué Danich
Data da Criacao---: 10/11/2017
===============================================================================================================================
Descrição---------: Retorna limite de crédito do cliente
===============================================================================================================================
Parametros--------: _ccodigo - código do cliente
					_cloja - loja do cliente
===============================================================================================================================
Retorno-----------: _nlimite - valor de limite de crédito
===============================================================================================================================
*/

User Function MOMS027K( _ccodigo, _cloja  )

Local _nlimite := 0
Local _aareaSA1 := SA1->(Getarea())

//-- Posiciona no Cliente Atual (Cód.+Loja) para recuperar o Código do Risco e a Validade do Limite de Crédito --//
DBSelectArea("SA1")
SA1->( DBSetOrder(1) )
		
If SA1->( DBSeek( xFilial("SA1") + _ccodigo ) ) 

		   dDtLimCr:= SA1->A1_VENCLC			     // Recupera a Data de Validade do Limite de Crédito

		   While SA1->(!Eof()) .And.  _ccodigo == SA1->A1_COD
		      If SA1->A1_LC > 0 .And. SA1->A1_VENCLC >= Date() .And. SA1->A1_MSBLQL != '1'
	
		      	_nlimite += SA1->A1_LC
	
		      EndIf
		      SA1->(DBSkip())
		   EndDo
		   
EndIf

SA1->(FWRestArea(_aareaSA1))

Return _nlimite

/*
===============================================================================================================================
Programa----------: MOMS0278
Autor-------------: Josué Danich
Data da Criacao---: 10/11/2017
===============================================================================================================================
Descrição---------: Retorna saldo do título
===============================================================================================================================
Parametros--------: _atitulos - array com dado do titulo
===============================================================================================================================
Retorno-----------: _aextrato - extrato o titulo
===============================================================================================================================
*/
Static Function MOMS0278(_atitulos)

Local _aextrato := {{_atitulos[11],_atitulos[7], "P"}}
Local cQuery := ""
	
cQuery += " 	SELECT e5_data, e5_valor, e5_recpag "
cQuery += " 				FROM "+ RetSqlName("SE5") +" SE5S WHERE "
cQuery += " 					SE5S.E5_FILORIG   = '" + _atitulos[3] + "'	AND	SE5S.E5_PREFIXO  = '" +  _atitulos[4] + "' "
cQuery += " 				AND	SE5S.E5_FILIAL   = '" + _atitulos[3] + "' " 
cQuery += " 				AND	SE5S.E5_NUMERO   = '" + _atitulos[5] + "'			AND	SE5S.E5_PARCELA  = '" + _atitulos[6] + "' "
cQuery += " 				AND	SE5S.E5_TIPO     = '" + _atitulos[8] + "'			AND	SE5S.E5_CLIFOR   = '" + _atitulos[9] + "' "
cQuery += " 				AND	SE5S.E5_LOJA     = '" + _atitulos[10] + "'			AND	SE5S.D_E_L_E_T_  = ' ' "
cQuery += " 				AND	SE5S.E5_SITUACA  NOT IN ( 'C' , 'X' )	AND	SE5S.E5_TIPO     NOT IN ( 'NCC' , 'RA', 'NDC' ) "
cQuery += " 				AND	SE5S.E5_VALOR    > 0			" 
cQuery += " 				AND	SE5S.E5_TIPODOC  IN ( 'VL' , 'ES' , 'CP' , 'BA' , 'DC' )  "

If Select("SE5T") > 0
	SE5T->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , "SE5T" , .T. , .F. )
	
While !SE5T->(Eof())
	
	aAdd(_aextrato,{SE5T->E5_DATA,SE5T->E5_VALOR,SE5T->E5_RECPAG})
	SE5T->(DBSkip())
	
EndDo

Return _aextrato

/*
===============================================================================================================================
Programa----------: MOMS0278
Autor-------------: Josué Danich
Data da Criacao---: 10/11/2017
===============================================================================================================================
Descrição---------: Retorna saldo do título
===============================================================================================================================
Parametros--------: _aextrato - array com movimento do titulo
					_cdata - data do saldo
===============================================================================================================================
Retorno-----------: _nsaldi - saldo do título na data
===============================================================================================================================
*/
Static Function MOMS0279(_aextrato,_cdata)

Local _nsaldi := 0   , _nnk

For _nnk := 1 to Len(_aextrato)

	If SToD(_aextrato[_nnk][1]) <= SToD(_cdata)
	
		If _aextrato[_nnk][3] == "R"
		
			_nsaldi := _nsaldi - _aextrato[_nnk][2]
			
		Else
		
			_nsaldi := _nsaldi + _aextrato[_nnk][2]
		
		EndIf
		
	EndIf

Next

Return _nsaldi
