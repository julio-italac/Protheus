#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST003
Autor-------------: Guilherme Diogo
Data da Criacao---: 23/10/2012
Descrição---------: Rotina para realizar o acerto do saldo em estoque de acordo com a planilha do almoxarifado (Tabela ZZR)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST003()

Local _bProcess    := {|oSelf| MEST003PRC(oSelf) }
Local _cFunction   := "MEST003"
Local _cTitle      := "Acerto do Estoque do Almoxarifado"
Local _cDescri	   := "Rotina que realiza o acerto do estoque de acordo com a planilha do almoxarifado"

Private	_cPerg     := "MEST003"

tNewProcess():New( _cFunction, _cTitle, _bProcess, _cDescri, _cPerg,,,,,,.T.)

Return

/*
===============================================================================================================================
Programa----------: MEST003PRC
Autor-------------: Guilherme Diogo
Data da Criacao---: 23/10/2012
Descrição---------: Funcao responsavel por realizar a importacao dos dados.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST003PRC(oSelf)
  
Local _nRegSB1 := 0
Local _nRegZZR := 0
//Local _nRegSB2 := 0 
Local _nRegSBZ := 0
Local _cQuery  := ""
Local _cTBSB1  := GetNextAlias()
Local _aCab    := {}
Local _aSD3    := {}
Local _aToSD3  := {}
Local _cCod    := ""
Local _cArmaz    := ""


//================================================================================
// Controles da ZZR
//================================================================================
Local _cTBZZR  := GetNextAlias()
Local _cCodZZR := ""
Local _nSldZZR := 0
//Local _cLocZZR := ""
Local _nCusZZR := 0

//================================================================================
// Controles da SBZ
//================================================================================
Local _cTBSBZ  := GetNextAlias()
Local _cCodSBZ := ""
Local _cLocSBZ := ""
Local _nMinSBZ := 0
Local _nMaxSBZ := 0

//Local _nQtdSB2 := 0
//Local _nCusSB2 := 0
Local _cObs    := "MOVIMENTO GERADO PELA ROTINA MEST003"
//Local _nSaldo  := 0
Local _aLog    := {} 
Local _nQatu   := 0
Local _nVatu1  := 0
Local _nCm1    := 0
Local _cStatus := ""
//Local _cTipo   := ""

Private lMsErroAuto := .F.

//Define armazém
_cArmaz		:= MV_PAR01

//================================================================================
// Zera Saldo SB2
//================================================================================
If MV_PAR03 == 1
    
    //================================================================================
	// Query SB1
	//================================================================================
	_cQuery := " SELECT "
	_cQuery += "   B1.B1_COD     CODIGO, "
	_cQuery += "   B1.B1_I_DESCD DESCRICAO, "
	_cQuery += "   B1.B1_GRUPO   GRUPO, "
	_cQuery += "   B1.B1_LOCPAD  ARMAZEM, "
	_cQuery += "   B1.B1_MSBLQL  STATUS1 "
	If !Empty(MV_PAR05)
		_cQuery += " FROM "+RetSqlName("SB1")+" B1 JOIN "+RetSqlName("ZZR")+" ZZR ON B1.B1_COD = ZZR.ZZR_COD " //INCLUIDA VALIDAÇÃO COM ZZR
		_cQuery += " WHERE "
		_cQuery += " B1.D_E_L_E_T_ = ' ' AND ZZR.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZZR.ZZR_DOC = '"+AllTrim(MV_PAR05)+"' " //ZERAR SOMENTE PRODUTOS DO DOC DA PLANILHA DE INVENTÁRIO
	Else
		_cQuery += " FROM "+RetSqlName("SB1")+" B1 "
		_cQuery += " WHERE "                    
		_cQuery += " B1.D_E_L_E_T_ = ' ' "
	EndIf
	_cQuery += " AND  B1.B1_FILIAL = '" + xFilial("SB1") + "'"
	_cQuery += IIf( !Empty( MV_PAR06 ) , " AND B1.B1_TIPO IN "+ FormatIn( AllTrim( MV_PAR06 ) , ';' )	, "" ) 
	_cQuery += IIf( !Empty( MV_PAR02 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
	
	If Select(_cTBSB1) > 0 
	 	(_cTBSB1)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cTBSB1 , .T. , .F. )
	COUNT TO _nRegSB1
	
	If _nRegSB1 > 0
	
		oSelf:SetRegua1( _nRegSB1 )
		
		aAdd( _aLog , "FUNÇÃO MEST003"								)		                 
		aAdd( _aLog , "DATA DE PROCESSAMENTO: " + DToC( Date() )	)
		aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)
		
		oSelf:SaveLog( "INICIO - ZERA SB2" )
		
	    aAdd( _aLog , "INICIO - ZERA SB2"							)
		
		(_cTBSB1)->( DBGoTop() )
		
		While (_cTBSB1)->( !Eof() )
		
			_cCod		:= (_cTBSB1)->CODIGO
			_cStatus	:= (_cTBSB1)->STATUS1
			
			DBSelectArea("SB1")
			SB1->( DBSetOrder(1) )
			If SB1->( DBSeek( xFilial("SB1") + _cCod ) )
				
				If _cStatus == "1"
					
					SB1->( RecLock( "SB1" , .F. ) )
					SB1->B1_MSBLQL := "2"
					SB1->( MSUnLock() )
					
					oSelf:SaveLog(	"O PRODUTO "+ AllTrim(_cCod) +" ESTÁ BLOQUEADO EM SEU CADASTRO." )
					aAdd( _aLog ,	"O PRODUTO "+ AllTrim(_cCod) +" ESTÁ BLOQUEADO EM SEU CADASTRO." )
				
				EndIf
			
			EndIf
			
			oSelf:IncRegua1( "PRODUTO: "+ AllTrim(_cCod) )
			
			DBSelectArea("SB2")
			SB2->( DBSetOrder(1) )
			If SB2->( DBSeek( xFilial("SB2") + _cCod + _cArmaz ) )
			
				_nQatu  := SB2->B2_QATU
				_nVatu1 := SB2->B2_VATU1
				_nCm1   := SB2->B2_CM1
				
				If !( _nQatu == 0 .And. _nVatu1 == 0 )
					
					If _nQatu == 0 .And. _nVatu1 > 0
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
							 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
                        
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                   	{ "D3_TM"       ,"997"              , NIL },;
									{ "D3_TM"       ,AllTrim(MV_PAR09)  , NIL },;
									{ "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, 0					, NIL },;
									{ "D3_CUSTO1"	, _nVatu1			, NIL },;
									{ "D3_CUSTO3"	, _nVatu1			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }

                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
					
							lMsErroAuto := .F.
                            MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao
							
							If lMsErroAuto
								
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
								
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
						
						END TRANSACTION
					
					ElseIf _nQatu == 0 .And. _nVatu1 < 0
					    
						_nVatu1	:= _nVatu1 * -1
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
						 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
						
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                    { "D3_TM"       ,"497"              , NIL },;
                                    { "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, 0					, NIL },;
									{ "D3_CUSTO1"	, _nVatu1			, NIL },;
									{ "D3_CUSTO3"	, _nVatu1			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }

                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
						
							lMsErroAuto := .F.
							
							MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao

							If lMsErroAuto
							
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
							
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
						
						END TRANSACTION
						
					ElseIf _nQatu > 0 .And. _nQatu <= 99999999.99 .And. _nVatu1 == 0
					
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
						 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
						
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                    { "D3_TM"       ,"998"              , NIL },;
                                    { "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, _nQatu			, NIL },;
									{ "D3_CUSTO1"	, 0     			, NIL },;
									{ "D3_CUSTO3"	, 0     			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }
                        
                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
						
							lMsErroAuto := .F.
							
							MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao

							If lMsErroAuto
								
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
								
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
						
						END TRANSACTION
						
					ElseIf _nQatu > 0 .And. _nQatu <= 99999999.99 .And. _nVatu1 > 0
						
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
						 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
						
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                    { "D3_TM"       ,"997"              , NIL },;
                                    { "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, _nQatu			, NIL },;
									{ "D3_CUSTO1"	, _nVatu1			, NIL },;
									{ "D3_CUSTO3"	, _nVatu1			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }

                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
						
							lMsErroAuto := .F.
							
							MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao

							If lMsErroAuto
								
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
								
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
							
						END TRANSACTION
						
					ElseIf _nQatu < 0 .And. _nVatu1 >= 0
						
						_nQatu	:= _nQatu * -1
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
						 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
						
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                    { "D3_TM"       ,"498"              , NIL },;
                                    { "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, _nQatu			, NIL },;
									{ "D3_CUSTO1"	, 0     			, NIL },;
									{ "D3_CUSTO3"	, 0     			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }

                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
							
							lMsErroAuto := .F.
							
							MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao

							If lMsErroAuto
								
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
								
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
							
						END TRANSACTION
						
					ElseIf _nQatu < 0 .And. _nVatu1 < 0
						 
						_nQatu  := _nQatu * -1
						_nVatu1 := _nVatu1 * -1 
                        _aToSD3 := {}
						_aCab   := {}
						_aSD3   := {}
						 
						DBSelectArea("SD3")
						SD3->( DBSetOrder(3) )
						
                        _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                                    { "D3_TM"       ,"497"              , NIL },;
                                    { "D3_CC"       ,"        "         , NIL },;
                                    { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                        _aSD3 := {	{ "D3_COD"		, _cCod				, NIL },;
									{ "D3_LOCAL"	, _cArmaz			, NIL },;
									{ "D3_QUANT"	, _nQatu			, NIL },;
									{ "D3_CUSTO1"	, _nVatu1  			, NIL },;
									{ "D3_CUSTO3"	, _nVatu1  			, NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
									{ "D3_I_OBS"    , _cObs				, NIL } }

                        aAdd(_aToSD3,_aSD3)

						BEGIN TRANSACTION
							
							lMsErroAuto := .F.
							
							MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao

							If lMsErroAuto
								
								If MV_PAR07 == 2
									MOSTRAERRO()
								EndIf
								
								oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCod) )
								DisarmTransaction()
								
							EndIf
							
						END TRANSACTION
						
					EndIf
					
				EndIf
				
			EndIf
			
			DBSelectArea("SB1")
			SB1->( DBSetOrder(1) )
			If SB1->( DBSeek( xFilial("SB1") + _cCod ) )
			
				If _cStatus == "1"
				
					SB1->( RecLock( "SB1" , .F. ) )
					SB1->B1_MSBLQL := _cStatus
					SB1->( MSUnLock() )
				
				EndIf
				
			EndIf
   			
   			(_cTBSB1)->( DBSkip() )
   		EndDo
   		
   		(_cTBSB1)->( DBCloseArea() )
   	
    EndIf
    
    oSelf:SaveLog(	"FINAL - ZERA SB2" ) 
	aAdd( _aLog ,	"FINAL - ZERA SB2" ) 
	aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: "+ Time() )

//================================================================================
// Saldo ZZR
//================================================================================
ElseIf MV_PAR03 == 2

	//================================================================================
	// Query ZZR
	//================================================================================
	_cQuery := " SELECT "
	_cQuery += "   ZZR.ZZR_COD   PRODUTO, "
	_cQuery += "   ZZR.ZZR_SALDO SALDO, "
	_cQuery += "   ZZR.ZZR_LOCAL LOCAL, "
	_cQuery += "   ZZR.ZZR_LOCALI LOCALIZACAO, "
	_cQuery += "   ZZR.ZZR_CUSTO CUSTO, "
	_cQuery += "   ZZR.R_E_C_N_O_ REG, "
	_cQuery += "   B1.B1_MSBLQL  STATUS1 "
	_cQuery += " FROM "+ RetSqlName("ZZR") +" ZZR "
	_cQuery += " JOIN "+ RetSqlName("SB1") +" B1 "
	_cQuery += " ON ZZR.ZZR_COD = B1.B1_COD "
	_cQuery += " WHERE "
	_cQuery += "     	ZZR.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND B1.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND ZZR.ZZR_FILIAL = '"+ xFilial("ZZR")	+"' "
	_cQuery += " 		AND ZZR.ZZR_STATUS = '1' "
	_cQuery += " 		AND ZZR.ZZR_DOC IN "+ FormatIn( MV_PAR05 , ';' )											
	_cQuery += IIf( !Empty( _cArmaz ) , " AND ZZR.ZZR_LOCAL IN "+ FormatIn( AllTrim( _cArmaz ) , ';' )	, "" ) 
	_cQuery += " 		AND B1.B1_FILIAL = '"+ xFilial("SB1")	+"' "
	_cQuery += IIf( !Empty( MV_PAR06 ) , " AND B1.B1_TIPO IN "+ FormatIn( AllTrim( MV_PAR06 ) , ';' )	, "" ) 
	_cQuery += IIf( !Empty( MV_PAR02 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 


	If Select(_cTBZZR) > 0 
	 	(_cTBZZR)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cTBZZR , .T. , .F. )
	COUNT TO _nRegZZR
	
	If _nRegZZR > 0
	
		oSelf:SetRegua1(_nRegZZR)
		
		aAdd( _aLog , "FUNÇÃO MEST003"								)		                 
		aAdd( _aLog , "DATA DE PROCESSAMENTO: "+ DToC( Date() )		)
		aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)
		
		oSelf:SaveLog(	"INICIO - SALDO ZZR" )
	    aAdd( _aLog ,	"INICIO - SALDO ZZR" )
		
		(_cTBZZR)->( DBGoTop() )
		
		While (_cTBZZR)->(!Eof())
		
			
			_cCodZZR := (_cTBZZR)->PRODUTO
			_nSldZZR := (_cTBZZR)->SALDO
			_nCusZZR := (_cTBZZR)->CUSTO 
			_cStatus := (_cTBZZR)->STATUS1
			
			oSelf:IncRegua1( "PRODUTO: " + AllTrim(_cCodZZR) )
			
			If _cStatus == "1"
				
				oSelf:SaveLog(	"O PRODUTO " + AllTrim(_cCodZZR) + " ESTÁ BLOQUEADO EM SEU CADASTRO." )
				aAdd( _aLog ,	"O PRODUTO " + AllTrim(_cCodZZR) + " ESTÁ BLOQUEADO EM SEU CADASTRO." )
				
			Else
	
                _aToSD3 := {}
				_aCab   := {}
				_aSD3   := {}
				 
				DBSelectArea("SD3")
				SD3->( DBSetOrder(3) )
				
                _aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                           	{ "D3_TM"		,AllTrim(MV_PAR08)  , Nil },; //{ "D3_TM"       ,"497"              , NIL },;
                            { "D3_CC"       ,AllTrim(MV_PAR04)  , NIL },;
                            { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                _aSD3 := {	{ "D3_COD"		, _cCodZZR			, NIL },;
							{ "D3_LOCAL"	, _cArmaz			, NIL },;
							{ "D3_QUANT"	, _nSldZZR			, NIL },;
							{ "D3_CUSTO1"	, _nCusZZR  		, NIL },;
							{ "D3_CUSTO3"	, _nCusZZR  	    , NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
							{ "D3_I_OBS"    , _cObs				, NIL } }

                aAdd(_aToSD3,_aSD3)

				BEGIN TRANSACTION
				
					lMsErroAuto := .F.
					
                    MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao
					
					If lMsErroAuto
						
						If MV_PAR07 == 2
									MOSTRAERRO()
						EndIf
								
						oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
						aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
						DisarmTransaction()
						
					Else
					
						//se movimentou ok muda o registro do ZZR para processado	
						ZZR->(DBGoTo((_cTBZZR)->REG))
						RecLock("ZZR",.F.)
						ZZR->ZZR_STATUS := "2"
						ZZR->(MSUnLock())
					
					EndIf
				
				END TRANSACTION
							
			EndIf
			
		(_cTBZZR)->( DBSkip() )
   		EndDo
   		
   		(_cTBZZR)->( DBCloseArea() )
   		
    EndIf
	
	oSelf:SaveLog(	"FINAL - SALDO ZZR" ) 
	aAdd( _aLog ,	"FINAL - SALDO ZZR" )
	aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: " + Time() )

//================================================================================
// Indicador de Produtos
//================================================================================
ElseIf MV_PAR03 == 3
    
    //================================================================================
	// Query ZZR
	//================================================================================
	_cQuery := " SELECT "
	_cQuery += "   ZZR.ZZR_COD   PRODUTO, "
	_cQuery += "   ZZR.ZZR_SALDO SALDO, "
	_cQuery += "   ZZR.ZZR_LOCAL LOCAL, "
	_cQuery += "   ZZR.ZZR_LOCALI LOCALIZACAO, "
	_cQuery += "   ZZR.ZZR_CUSTO CUSTO, "
	_cQuery += "   ZZR.ZZR_QMINI MINIMO, "
	_cQuery += "   ZZR.ZZR_QMAX  MAXIMO, "
	_cQuery += "   ZZR.R_E_C_N_O_ REG, "
	_cQuery += "   B1.B1_MSBLQL  STATUS1 "
	_cQuery += " FROM "+ RetSqlName("ZZR") +" ZZR "
	_cQuery += " JOIN "+ RetSqlName("SB1") +" B1 "
	_cQuery += " ON ZZR.ZZR_COD = B1.B1_COD "
	_cQuery += " WHERE "
	_cQuery += "     	ZZR.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND B1.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND ZZR.ZZR_FILIAL = '"+ xFilial("ZZR")	+"' "
	//_cQuery += " 		AND ZZR.ZZR_STATUS = '1' "
	_cQuery += " 		AND ZZR.ZZR_DOC IN "+ FormatIn( MV_PAR05 , ';' )											
	_cQuery += IIf( !Empty( _cArmaz ) , " AND ZZR.ZZR_LOCAL IN "+ FormatIn( AllTrim( _cArmaz ) , ';' )	, "" ) 
	_cQuery += " 		AND B1.B1_FILIAL = '"+ xFilial("SB1")	+"' "
	_cQuery += IIf( !Empty( MV_PAR06 ) , " AND B1.B1_TIPO IN "+ FormatIn( AllTrim( MV_PAR06 ) , ';' )	, "" ) 
	_cQuery += IIf( !Empty( MV_PAR02 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
	
	If Select(_cTBSBZ) > 0 
		(_cTBSBZ)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cTBSBZ , .T. , .F. )
	COUNT TO _nRegSBZ
	
	If _nRegSBZ > 0
	    
		oSelf:SetRegua1( _nRegSBZ )
		
		aAdd( _aLog , "FUNÇÃO MEST003"								)		                 
		aAdd( _aLog , "DATA DE PROCESSAMENTO: "+ DToC( Date() )		)
		aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)
		
		oSelf:SaveLog(	"INICIO - INDICADOR DE PRODUTOS" )
	    aAdd( _aLog ,	"INICIO - INDICADOR DE PRODUTOS" )
		
		(_cTBSBZ)->( DBGoTop() )
		
		While (_cTBSBZ)->( !Eof() )
		    
			oSelf:IncRegua1( "PRODUTO: " + AllTrim((_cTBSBZ)->PRODUTO) )
			
			_cCodSBZ := (_cTBSBZ)->PRODUTO
			_cLocSBZ := (_cTBSBZ)->LOCALIZACAO
			_nMinSBZ := (_cTBSBZ)->MINIMO
			_nMaxSBZ := (_cTBSBZ)->MAXIMO
			
			DBSelectArea("SBZ")
			SBZ->( DBSetOrder(1) )
			If SBZ->( DBSeek( xFilial("SBZ") + _cCodSBZ ) )
			
				SBZ->( RecLock( "SBZ" , .F. ) )
				
					SBZ->BZ_I_LOCAL := _cLocSBZ
					SBZ->BZ_ESTSEG  := _nMinSBZ
		      		SBZ->BZ_EMAX    := _nMaxSBZ
		            
				SBZ->( MSUnLock() )
				
				//se movimentou ok muda o registro do ZZR para processado	
				ZZR->(DBGoTo((_cTBSBZ)->REG))
				RecLock("ZZR",.F.)
				ZZR->ZZR_STATUS := "2"
				ZZR->(MSUnLock())
			
			 	oSelf:SaveLog(	"O PRODUTO "+ AllTrim(_cCodSBZ) +" TEVE O CADASTRO DE INDICADOR ATUALIZADO." )
			 	aAdd( _aLog ,	"O PRODUTO "+ AllTrim(_cCodSBZ) +" TEVE O CADASTRO DE INDICADOR ATUALIZADO." )
			 	
			EndIf
			
		(_cTBSBZ)->( DBSkip() )
		EndDo		
		 
		(_cTBSBZ)->( DBCloseArea() )
		 
	EndIf
	
	oSelf:SaveLog(	"FINAL - INDICADOR DE PRODUTOS" )
	aAdd( _aLog ,	"FINAL - INDICADOR DE PRODUTOS" )
	aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: "+ Time() )


//================================================================================
// Acerto de valores
//================================================================================
ElseIf MV_PAR03 == 4

	//================================================================================
	// Query ZZR
	//================================================================================
	_cQuery := " SELECT "
	_cQuery += "   ZZR.ZZR_COD   PRODUTO, "
	_cQuery += "   ZZR.ZZR_SALDO SALDO, "
	_cQuery += "   ZZR.ZZR_LOCAL LOCAL, "
	_cQuery += "   ZZR.ZZR_LOCALI LOCALIZACAO, "
	_cQuery += "   ZZR.ZZR_CUSTO CUSTO, "
	_cQuery += "   ZZR.R_E_C_N_O_ REG, "
	_cQuery += "   B1.B1_MSBLQL  STATUS1 "
	_cQuery += " FROM "+ RetSqlName("ZZR") +" ZZR "
	_cQuery += " JOIN "+ RetSqlName("SB1") +" B1 "
	_cQuery += " ON ZZR.ZZR_COD = B1.B1_COD "
	_cQuery += " WHERE "
	_cQuery += "     	ZZR.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND B1.D_E_L_E_T_ = ' ' "
	_cQuery += " 		AND ZZR.ZZR_FILIAL = '"+ xFilial("ZZR")	+"' "
	_cQuery += " 		AND ZZR.ZZR_STATUS = '1' "
	_cQuery += " 		AND ZZR.ZZR_DOC IN "+ FormatIn( MV_PAR05 , ';' )											
	_cQuery += IIf( !Empty( _cArmaz ) , " AND ZZR.ZZR_LOCAL IN "+ FormatIn( AllTrim( _cArmaz ) , ';' )	, "" ) 
	_cQuery += " 		AND B1.B1_FILIAL = '"+ xFilial("SB1")	+"' "
	_cQuery += IIf( !Empty( MV_PAR06 ) , " AND B1.B1_TIPO IN "+ FormatIn( AllTrim( MV_PAR06 ) , ';' )	, "" ) 
	_cQuery += IIf( !Empty( MV_PAR02 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 


	If Select(_cTBZZR) > 0 
	 	(_cTBZZR)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cTBZZR , .T. , .F. )
	COUNT TO _nRegZZR
	
	If _nRegZZR > 0
	
		oSelf:SetRegua1(_nRegZZR)
		
		aAdd( _aLog , "FUNÇÃO MEST003 - CORRECAO VALORES"			)		                 
		aAdd( _aLog , "DATA DE PROCESSAMENTO: "+ DToC( Date() )		)
		aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)
		
		oSelf:SaveLog(	"INICIO - SALDO ZZR" )
	    aAdd( _aLog ,	"INICIO - SALDO ZZR" )
		
		(_cTBZZR)->( DBGoTop() )
		
		While (_cTBZZR)->(!Eof())
		
			
			_cCodZZR := (_cTBZZR)->PRODUTO
			_nSldZZR := (_cTBZZR)->SALDO
			_nCusZZR := (_cTBZZR)->CUSTO 
			_cStatus := (_cTBZZR)->STATUS1
			
			oSelf:IncRegua1( "PRODUTO: " + AllTrim(_cCodZZR) )
			
			If _cStatus == "1"
				
				oSelf:SaveLog(	"O PRODUTO " + AllTrim(_cCodZZR) + " ESTÁ BLOQUEADO EM SEU CADASTRO." )
				aAdd( _aLog ,	"O PRODUTO " + AllTrim(_cCodZZR) + " ESTÁ BLOQUEADO EM SEU CADASTRO." )
				
			Else
	
                _aToSD3 := {}
				_aCab   := {}
				_aSD3   := {}
				 
				DBSelectArea("SD3")
				SD3->( DBSetOrder(3) )
				
                
				If _nCusZZR > 0
				
					_aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                      	      { "D3_TM"       ,AllTrim(MV_PAR08)    , NIL },;
                          	  { "D3_CC"       ,AllTrim(MV_PAR04)  , NIL },;
                         	   { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                	_aSD3 := {	{ "D3_COD"		, _cCodZZR			, NIL },;
								{ "D3_LOCAL"	, _cArmaz			, NIL },;
								{ "D3_QUANT"	, _nSldZZR			, NIL },;
								{ "D3_CUSTO1"	, _nCusZZR  		, NIL },;
								{ "D3_CUSTO3"	, _nCusZZR  	    , NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
								{ "D3_I_OBS"    , _cObs				, NIL } }

                	aAdd(_aToSD3,_aSD3)

					BEGIN TRANSACTION
				
						lMsErroAuto := .F.
					
                   		MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao
					
						If lMsErroAuto
						
							If MV_PAR07 == 2
								MOSTRAERRO()
							EndIf
								
							oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
							aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
							DisarmTransaction()
						
						Else
					
							//se movimentou ok muda o registro do ZZR para processado	
							ZZR->(DBGoTo((_cTBZZR)->REG))
							RecLock("ZZR",.F.)
							ZZR->ZZR_STATUS := "2"
							ZZR->(MSUnLock())
					
						EndIf
				
					END TRANSACTION
				Else
					_nCusZZR:= _nCusZZR*-1
					_aCab := {  { "D3_FILIAL"   , xFilial("SD3")	, Nil },;
                      	      	{ "D3_TM"       ,AllTrim(MV_PAR09)  , NIL },;
                          	  	{ "D3_CC"       ,AllTrim(MV_PAR04)  , NIL },;
                         	   { "D3_EMISSAO"  ,DDATABASE          , NIL }}

                	_aSD3 := {	{ "D3_COD"		, _cCodZZR			, NIL },;
								{ "D3_LOCAL"	, _cArmaz			, NIL },;
								{ "D3_QUANT"	, _nSldZZR			, NIL },;
								{ "D3_CUSTO1"	, _nCusZZR  		, NIL },;
								{ "D3_CUSTO3"	, _nCusZZR  	    , NIL },; //INCLUIDO POR ERICH BUTTNER DIA 23/09/13 - GRAVAR O CAMPO DE CUSTO3 (UFIR)
								{ "D3_I_OBS"    , _cObs				, NIL } }

                	aAdd(_aToSD3,_aSD3)

					BEGIN TRANSACTION
				
						lMsErroAuto := .F.
					
                   		MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab , _aToSD3 , 3 ) //Inclusao
					
						If lMsErroAuto
						
							If MV_PAR07 == 2
								MOSTRAERRO()
							EndIf
								
							oSelf:SaveLog(	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
							aAdd( _aLog ,	"ERRO AO PROCESSAR O PRODUTO " + AllTrim(_cCodZZR) )
							DisarmTransaction()
						
						Else
					
							//se movimentou ok muda o registro do ZZR para processado	
							ZZR->(DBGoTo((_cTBZZR)->REG))
							RecLock("ZZR",.F.)
							ZZR->ZZR_STATUS := "2"
							ZZR->(MSUnLock())
					
						EndIf
				
					END TRANSACTION

				EndIf
			EndIf
		(_cTBZZR)->( DBSkip() )
   		EndDo
   		
   		(_cTBZZR)->( DBCloseArea() )
   		
    EndIf
	
	oSelf:SaveLog(	"FINAL - SALDO ZZR" ) 
	aAdd( _aLog ,	"FINAL - SALDO ZZR" )
	aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: " + Time() )



EndIf

Processa( {|| MEST003C(_aLog) } , "Gravando dados no arquivo..." )

//Regristra log de acesso
U_ITLOGACS('MEST003')

U_MEST003()

Return

/*
===============================================================================================================================
Programa----------: MEST003C
Autor-------------: Guilherme Diogo
Data da Criacao---: 23/10/2012
Descrição---------: Rotina que permite gravar o LOG referente ao processamento
Parametros--------: _aLog - registro de eventos a ser salvo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST003C(_aLog)

Local _cArq	:= ""
Local _nHdl	:= 0
Local _nPos	:= 0
Local _nI	:= 0

Aviso( "Salvar Log em TXT" , "Este programa ira gerar um arquivo texto com o Log do processamento executado" , {"Ok"} , 1 , "Geração de Arquivo Texto" )

_cArq := tFileDialog( "Documento Texto |*.TXT", OemToAnsi("Salvar Arquivo Como...") ,, "C:\", .T., GETF_MULTISELECT)

If !Empty(_cArq)

	_nPos := At( ".TXT" , Upper(_cArq) )

	If _nPos == 0
		_cArq := AllTrim(_cArq) + ".TXT"
	EndIf

	_nHdl := FCreate(_cArq)

	If _nHdl == -1
		MsgAlert( "O arquivo de nome "+_cArq+" nao pode ser criado!" , "Atencao!" )
		Return
	EndIf

	ProcRegua( Len(_aLog) )

	For _nI := 1 To Len(_aLog)
			
		FWrite( _nHdl , _aLog[_nI] + chr(13) + chr(10) )
		
		If FError() # 0
			MsgAlert ( "ERRO AO GRAVAR NO ARQUIVO: "+ Str( FError() ) )
			Exit
		EndIf
		
		IncProc()

	Next _nI

	FClose(_nHdl)

	MsgInfo( "Arquivo TXT gerado com sucesso!" )

EndIf	

//volta a tela inicial
U_MEST003()

Return

/*
===============================================================================================================================
Programa----------: MEST003C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/08/2015
Descrição---------: Rotina para montar consulta de documentos de inventário (ZZR)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST003C()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Documentos de inventário disponíveis'
Local _aDados	:= {}  ,_nI

_cQuery := " SELECT ZZR_DOC, 
_cQuery += " ZZR_OBS FROM "
_cQuery += RETSQLNAME('ZZR') +" ZZR 
_cQuery += " WHERE " + RETSQLCOND('ZZR') 
_cQuery += " AND ZZR_STATUS = '1' 
_cQuery += " AND ZZR_FILIAL = '" + xFilial("ZZR") + "'"
_cQuery += " GROUP BY ZZR_DOC, ZZR_OBS "
_cQuery += " ORDER BY ZZR_DOC"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

//carrega documentos válidos na matriz
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->ZZR_DOC, (_cAlias)->ZZR_OBS  } )
	
	(_cAlias)->( DBSkip() )
	
EndDo

(_cAlias)->( DBCloseArea() )

//Se tiver documentos válidos cria a consulta
If Len(_aDados) > 0

	If U_ITListBox( _cTitAux , { '__' , 'Documento', 'OBS' } , @_aDados , .F. , 2 , 'Selecione os documentos desejados: ' )

		For _nI := 1 To Len( _aDados )
		
			If _aDados[_nI][01]
				_cRet += AllTrim( _aDados[_nI][02] ) +';'
			EndIf
		
		Next _nI
	
		&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
		
	EndIf

//se não tiver documentos válidos alerta e sai
Else
	
	alert("Não há documentos válidos!")
	
EndIf

Return( .T. )
