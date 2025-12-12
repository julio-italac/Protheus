#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST008
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/10/2015
Descrição---------: Rotina para marcar produtos como obsoletos e/ou bloquear - Chamado 10289
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST008()
                             
Private _cPerg:= "MEST008"

//Pega parâmetros
If !Pergunte(_cPerg,.T.)   
	Return
EndIf  

//Monta Tela
MEST008P()

Return     

/*
===============================================================================================================================
Programa----------: MEST008P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Monta tela de markbrowse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008P()   

Local _oPanel ,x
Local _oDlg1
Local _nHeight     := 0
Local _nWidth      := 0
Local _aSize       := {}
Local _aBotoes     := {}
Local _aCoors      := {}

Local _oOK    	  	:= LoadBitmap(GetResources(),'LBOK')
Local _oNO        	:= LoadBitmap(GetResources(),'LBNO')
Local _oNOrmal    	:= LoadBitmap(GetResources(),'br_verde')
Local _oObsoleto  	:= LoadBitmap(GetResources(),'br_azul')     
Local _oBloqueado	:= LoadBitmap(GetResources(),'br_vermelho')     
           
Private _oQtda

Private _nOpca     := 0
Private _nQtdPrd   := 0   
                      
Private _aObjects  := {}
Private _aPosObj1  := {}               
Private _aInfo     := {}
                         
Private _cAlias   := 'TE1'    

Private _aTitulo   := {}
Private _aStruct   := {}    

Private _oBrowse    

Private _oFont12b                      

Private _dDtPriMov, _dDtUltMov
Private _aStructExcel  := {}
       
//===============================================================
//Define a fonte a ser utilizada no GRID                           
//===============================================================
Define Font _oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito                

//===============================================================
// Cria o arquivo Temporario para insercao dos dados selecionados. 
//===============================================================
FWMsgRun(,{|| MEST008C(_cAlias)  },'MONTANDO A ESTRUTURA DOS DADOS...','AGUARDE...')

                                                                                 
Begin Transaction

//===============================================================
// Insere os dados no arquivo temporario criado                    
//===============================================================
FWMsgRun(,{|oProc| MEST008D(_cAlias,oProc)  },'INSERINDO OS DADOS SELECIONADOS...','AGUARDE...')

//===============================================================
// Faz o calculo automatico de dimensoes de objetos     
//===============================================================
_aSize := MSADVSIZE()                    

//===============================================================
// Obtem tamanhos das telas                                            
//===============================================================
aAdd( _aObjects, { 0, 0, .T., .T., .T. } )

_aInfo    := { _aSize[ 1 ], _aSize[ 2 ], _aSize[ 3 ], _aSize[ 4 ], 3, 3 } 
_aPosObj1 := MsObjSize( _aInfo, _aObjects,  , .T. ) 

//===============================================================
// Botoes da tela.                       
//===============================================================
aAdd( _aBotoes, {"S4WB005N" ,{|| MEST008V()                                                                             },"Visualizar Produto..." ,"Produto"      })
//aAdd( _aBotoes, {'RELATORIO',{||MsgRun("Imprimindo Relatório Aguarde...",,{|| ,MEST008IP() })  },"Imprimir"})    
aAdd( _aBotoes, {'RELATORIO',{|| FWMsgRun(,{|oProc| MEST008IP(oProc) },'Aguarde processamento...','Lendo dados...')  },"Imprimir"})    
aAdd( _aBotoes, {'S4WB011N' ,{|| U_MEST008F()  }         ,"Filtrar"})   
aAdd( _aBotoes, {'FORM '    ,{||U_MEST008E()  }         ,"Exportar Excel"})  
aAdd( _aBotoes, {'PENDENTE' ,{||U_MEST008M("MARCAR")}   ,"Marcar Todos"})  
aAdd( _aBotoes, {'NOTE'     ,{||U_MEST008M("DESMARCAR")},"Desmarcar Todos"})  

//===============================================================
// Grava log de filtro e carga dos dados.
//=============================================================== 
U_ITLOGACS('MEST008P')

//===============================================================
// Cria a tela para selecao dos Titulos                              
//===============================================================

DEFINE MSDIALOG _oDlg1 TITLE OemToAnsi("ROTINA DE AJUSTE DE PRODUTOS OBSOLETOS") From 0,0 To _aSize[6]+15,_aSize[5] OF oMainWnd PIXEL

_oPanel       := TPanel():New(0,0,'',_oDlg1,, .T., .T.,, ,315,35,.T.,.T. )

@ 0.8 ,00.8 Say OemToAnsi("Quantidade:")        OF _oPanel FONT _oFont12b 
@ 0.8 ,0005 Say _oQtda VAR _nQtdPrd Picture "@E 999999" SIZE 60,8 OF _oPanel FONT _oFont12b 

//Legenda    
@ 0.5 ,032 Say OemToAnsi("Legenda:")        OF _oPanel FONT _oFont12b 
@ 0.4 ,039 Say OemToAnsi("- Produto Normal ")        OF _oPanel FONT _oFont12b 
@ 1.0 ,039 Say OemToAnsi("- Produto Obsoleto ")        OF _oPanel FONT _oFont12b 
@ 1.6 ,039 Say OemToAnsi("- Produto Bloqueado ")        OF _oPanel FONT _oFont12b 
@ 005, 300 BITMAP oBitmap1 SIZE 022, 016 OF _oPanel FILENAME 'br_verde' NOBORDER PIXEL
@ 013, 300 BITMAP oBitmap1 SIZE 022, 016 OF _oPanel FILENAME 'br_azul'  NOBORDER PIXEL
@ 021, 300 BITMAP oBitmap1 SIZE 022, 016 OF _oPanel FILENAME 'br_vermelho'  NOBORDER PIXEL

If FlatMode()
	_aCoors := GetScreenRes()
	_nHeight	:= _aCoors[2]
	_nWidth	:= _aCoors[1]
Else
	_nHeight	:= 143
	_nWidth	:= 315
EndIf                    

DBSelectArea(_cAlias)     
(_cAlias)->(DBGoTop())

_oBrowse := TCBrowse():New( 35,01,_aPosObj1[1,3] + 7,_aPosObj1[1,4]-50,,;
	                     ,{20,20,02,09,02,02,10,06,04,54,08,08,08,17,17},;
	                     _oDlg1,,,,,{||},,_oFont12b,,,,,.F.,_cAlias,.T.,,.F.,,.T.,.T.)                                                                                               
	                     
For x:=1 to Len(_aStruct)       
	
	If _aStruct[x,5] == 1
			
		If _aStruct[x,1] == _cAlias + "_STATUS" 

			_oBrowse:AddColumn(TCColumn():New("",{|| IIf(&(_cAlias+'->' +_cAlias + "_STATUS") == Space(2),_oNO,_oOK)},,,,"CENTER",,.T.,.F.,,,,.F.,))  

		ElseIf _aStruct[x,1] == _cAlias + "_LEGEND"

		   	_oBrowse:AddColumn(TCColumn():New("",{|| IIf(&(_cAlias + '->' +_cAlias + "_BLOQ") == "S",_oBloqueado,IIf(&(_cAlias + '->' +_cAlias + "_OBSOL")="S",_oObsoleto,_oNOrmal))},,,,"CENTER",,.T.,.F.,,,,.F.,))  

		Else

			_oBrowse:AddColumn(TCColumn():New(OemToAnsi(_aTitulo[x,2]),&("{ || " + _cAlias + '->' + _aStruct[x,1]+"}"),_aTitulo[x,3],,,If(_aStruct[x,2]=="N","RIGHT","LEFT"),,.F.,.F.,,,,.F.,))      					

		EndIf
		
	EndIf
	
Next x         
	
_oBrowse:GetColSizes()        
	
// Evento de duplo click na celula
_oBrowse:bLDblClick   := {|| MEST008S1(_cAlias,&(_cAlias+'->' +_cAlias + "_STATUS"))}  
    
//Evento quando o usuario clica na coluna desejada
_oBrowse:bHeaderClick := { |_oBrowse, _nCol| _nColuna:= _nCol,MsgRun("FAVOR AGUARDE, REALIZANDO OPERAÇÃO...",,{|| MEST008S2(_cAlias,_nColuna) }) }                    

_oDlg1:lMaximized:=.T.
    
ACTIVATE MSDIALOG _oDlg1 ON INIT (EnchoiceBar(_oDlg1,{|| If(MEST008VL(_nQtdPrd),(_nOpca:= 1,_oDlg1:End()),) },;
                                                     {||                         _nOpca:= 2,_oDlg1:End()},,_aBotoes),;
                                       (_oPanel:Align:=CONTROL_ALIGN_TOP,_oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,_oBrowse:Refresh()))
                                              
If _nOpca = 1

   FWMsgRun(,{|oProc| MEST008AL(oProc) },'Aguarde processamento...','Lendo dados...')   
   
EndIf
//===============================================================
// Fecha a area de uso do arquivo temporario no Protheus.          
//===============================================================
(_cAlias)->(DBCloseArea())
	
End Transaction

Return

/*
===============================================================================================================================
Programa----------: MEST008C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Cria tabela temporaria para montagem da tela 
Parametros--------: _cTab - Alias da tabela temporária
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008C(_cTab)

_aStruct  := {}            
_aTitulo  := {}                            

//==================================================================================
// Criando estrutura da tabela temporaria das unidades                 
//==================================================================================
   
aAdd(_aStruct,{_cTab+"_STATUS"  ,"C",02,1,1   })  
aAdd(_aStruct,{_cTab+"_LEGEND"  ,"C",02,1,1   })  
aAdd(_aStruct,{_cTab+"_TIPO"    ,"C",02,1,1   })
aAdd(_aStruct,{_cTab+"_GRUPO"   ,"C",04,1,1   })
aAdd(_aStruct,{_cTab+"_PRIMOV"  ,"D",08,1,1   })
aAdd(_aStruct,{_cTab+"_DETPRI"  ,"C",20,1,1   })
aAdd(_aStruct,{_cTab+"_ULMOV"   ,"D",08,1,1   })
aAdd(_aStruct,{_cTab+"_DETUL"   ,"C",20,1,1   })
aAdd(_aStruct,{_cTab+"_CODIGO"  ,"C",20,1,1   })
aAdd(_aStruct,{_cTab+"_DESCRI"  ,"C",60,1,1   })
aAdd(_aStruct,{_cTab+"_BLOQ"    ,"C",01,1,0   })
aAdd(_aStruct,{_cTab+"_OBSOL"   ,"C",01,1,0   })
aAdd(_aStruct,{_cTab+"_SEQCAL"  ,"C",14,1,0   })

_aStructExcel := Aclone(_aStruct)             

//==================================================================================
// Armazena no array aCampos o nome, descricao dos campos e picture  
//==================================================================================

aAdd(_aTitulo,{_cTab+"_STATUS"  ,"  "                   ," "                          	,1})  
aAdd(_aTitulo,{_cTab+"_LEGEND"  ,"  "                   ," "                          	,2})  
aAdd(_aTitulo,{_cTab+"_TIPO"   ,"TIPO"                  ,PesqPict("SB1","B1_TIPO") 		,3})  
aAdd(_aTitulo,{_cTab+"_GRUPO"     ,"GRUPO >>"            ,PesqPict("SB1","B1_GRUPO")  	,4})
aAdd(_aTitulo,{_cTab+"_PRIMOV"  ,"PRI MOVIM"              ,PesqPict("SD3","D3_EMISSAO")	,5})
aAdd(_aTitulo,{_cTab+"_DETPRI"  ,"DOC ORI"              ,"@!"	,6})
aAdd(_aTitulo,{_cTab+"_ULMOV"  ,"ULT MOVIM"              ,PesqPict("SD3","D3_EMISSAO") 	,7})
aAdd(_aTitulo,{_cTab+"_DETUL"  ,"DOC ORI"              ,"@!"	,8})
aAdd(_aTitulo,{_cTab+"_CODIGO"    ,"CODIGO"                 ,PesqPict("SB1","B1_COD")  	,9})
aAdd(_aTitulo,{_cTab+"_DESCRI"  ,"DESCRICAO"             ,PesqPict("SB1","B1_DESC") 	,10})


//===============================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta. 
//===============================================================
If Select(_cTab) <> 0
	(_cTab)->(DBCloseArea())
EndIf

_otemp := FWTemporaryTable():New( _cTab, _aStruct)

_otemp:AddIndex( "01", {_cAlias + "_CODIGO", _cAlias + "_SEQCAL"} )
_otemp:Create()

Return
      
/*
===============================================================================================================================
Programa----------: MEST008D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Insere os dados selecionados de acordo com os filtros informados pelo usuario no arquivo temporario criado
Parametros--------: _cTab - Alias da tabela temporária
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008D(_cTab,oProc)
                 
Local _cAliasSB1:= GetNextAlias()
Local _cAliasSB2:= GetNextAlias()
Local _cFiltro  := "%"
Local _cFilD3   := "%"
Local _cFilD2   := "%"
Local _cFilD1   := "%"
Local _culmov   := SToD("20010101")
Local _cprimov  := SToD("20490101")
Local _culdoc	  := ""
Local _cpridoc  := ""
Local _ctipul	  := ""
Local _ctipri	  := ""
Local _cfilial := AllTrim(xFilial("SBZ"))
Local _cSeqMov  := ""
      
//Filtros

//filtro de filial
_cfilial:= AllTrim(xFilial("SBZ"))
_cFiltro+= " AND B1_FILIAL = '" + xFilial("SB1") + "'"
_cFilD1 += " AND D1_FILIAL = '" + xFilial("SD1") + "'"
_cFilD2 += " AND D2_FILIAL = '" + xFilial("SD3") + "'"
_cfild3 += " AND D3_FILIAL = '" + xFilial("SD3") + "'"


//Tipo de produto
If !Empty(MV_PAR04)
	_cFiltro  += " AND B1.B1_TIPO IN " + FormatIn(AllTrim(MV_PAR04),";")
EndIf   
		
//Grupo de produto
If !Empty(MV_PAR03)
	_cFiltro  += " AND B1.B1_GRUPO IN " + FormatIn(AllTrim(MV_PAR03),";")
EndIf      
		
_cFiltro      += "%"

//filtros da D3
If !Empty(MV_PAR06)
	
	_cfild3 += " AND NOT (D3_TM IN " + FormatIn(AllTrim(MV_PAR06),";") + ")" 	

EndIf

//filtros duplos da D3
If !Empty(MV_PAR07)
	
	_cfild3 += " AND NOT ( SubStr(D3_DOC,1," + AllTrim(Str(Len(AllTrim(MV_PAR07)))) + ") = '" + AllTrim(MV_PAR07) + "')"  	

EndIf
//estorno e movimento de estoque do D3
_cFilD3      += " AND D3_ESTORNO <> 'S'"
_cFilD3      += "%"

//estorno e movimento de estoque do D1
_cFilD1   	+= " AND (SELECT F4_ESTOQUE FROM " + retsqlname("SF4") + " F4 WHERE F4.F4_FILIAL = '" + xFilial("SF4") + "'"
_cFilD1	    += " AND F4.D_E_L_E_T_ = ' ' AND F4.F4_CODIGO = D1.D1_TES AND ROWNUM = 1) = 'S'"
_cFilD1   	+= "%"

//estorno e movimento de estoque do D2
_cFilD2      += " AND (SELECT F4_ESTOQUE FROM " + retsqlname("SF4") + " F4 WHERE F4.F4_FILIAL = '" + xFilial("SF4") + "'"
_cFilD2      += " AND F4.D_E_L_E_T_ = ' ' AND F4.F4_CODIGO = D2.D2_TES AND ROWNUM = 1) = 'S'"
_cFilD2      += "%"

//===============================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta. 
//===============================================================
If Select(_cAliasSB1) <> 0
	
	(_cAliasSB1)->(DBCloseArea())

EndIf

//===============================================================
// Query para selecao dos dados das datas dos movimentos                       
//===============================================================
			
//Normal ou obsoletos sem trazer data inicial para melhorar performance

oProc:cCaption := ("1/2-Lendo dados, Aguarde...")
ProcessMessages()
			
If MV_PAR08 == 3 //só obsoletos 
			
			BeginSql alias _cAliasSB1   	   	
			   	SELECT 

				 	B1.B1_DESC,B1.B1_COD,B1.B1_GRUPO,B1.B1_TIPO,B1.B1_MSBLQL,
				 	(SELECT MAX(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) ULD2,
				 	(SELECT MAX(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) ULD1,
				 	(SELECT MAX(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) ULD3,
				 	'2001010' PRI2,
				 	'2001010' PRI1,
				 	'2001010' PRI3,
	 			 	
	 			 	(SELECT D2.R_E_C_N_O_ FROM %Table:SD2% D2 WHERE ROWNUM = 1
	 			 	 AND D2.D2_EMISSAO =  (SELECT MAX(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%)
	 			 	 AND D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) REGD2MAX, 
				 	
				 	(SELECT D1.R_E_C_N_O_ FROM %Table:SD1% D1 WHERE ROWNUM = 1
				 	AND D1.D1_DTDIGIT = (SELECT MAX(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%)
				 	AND D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) REGD1MAX,
				 	
				 	(SELECT D3.R_E_C_N_O_ FROM %Table:SD3% D3 WHERE ROWNUM = 1
				 	AND D3.D3_EMISSAO = (SELECT MAX(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%)  
				 	AND D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) REGD3MAX,
				 	
				 	'N/D' DOCD2MIN,
				 	'N/D' DOCD1MIN,
				 	'N/D' DOCD3MIN,
					(SELECT BZ_I_OBSOL FROM %Table:SBZ% BZ WHERE BZ.BZ_FILIAL = %exp:_cfilial% AND  BZ.BZ_COD = B1.B1_COD AND BZ.D_E_L_E_T_ = ' ' AND ROWNUM = 1 ) BZOBSOL 
	
				FROM 
					%Table:SB1% B1 
				WHERE 
			        B1.D_E_L_E_T_ = ' '
			        %exp:_cFiltro%			 
				ORDER BY B1.B1_COD
			EndSql

Else //procura normal
	
			BeginSql alias _cAliasSB1   	   	
			   	SELECT 

				 	B1.B1_DESC,B1.B1_COD,B1.B1_GRUPO,B1.B1_TIPO,B1.B1_MSBLQL,
				 	(SELECT MAX(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) ULD2,
				 	(SELECT MAX(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) ULD1,
				 	(SELECT MAX(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) ULD3,
				 	(SELECT MIN(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) PRI2,
				 	(SELECT MIN(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) PRI1,
				 	(SELECT MIN(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) PRI3,
	 			 	
	 			 	(SELECT D2.R_E_C_N_O_ FROM %Table:SD2% D2 WHERE ROWNUM = 1
	 			 	AND D2.D2_EMISSAO = (SELECT MAX(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%)  
	 			 	AND D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) REGD2MAX,
	 			 	
				 	(SELECT D1.R_E_C_N_O_ FROM %Table:SD1% D1 WHERE ROWNUM = 1
				 	 AND D1.D1_DTDIGIT = (SELECT MAX(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%)
				 	 AND D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) REGD1MAX,
				 	 
				 	(SELECT D3.R_E_C_N_O_ FROM %Table:SD3% D3 WHERE ROWNUM = 1
				 	 AND D3.D3_EMISSAO = (SELECT MAX(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%)
				 	 AND D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) REGD3MAX,
				 	 
				 	(SELECT D2.R_E_C_N_O_ FROM %Table:SD2% D2 WHERE ROWNUM = 1
				 	 AND D2.D2_EMISSAO = (SELECT MIN(D2.D2_EMISSAO) FROM %Table:SD2% D2 WHERE D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) 
				 	 AND D2.D2_COD = B1.B1_COD AND D2.D_E_L_E_T_ = ' ' %exp:_cfild2%) REGD2MIN,
				 	
				 	(SELECT D1.R_E_C_N_O_ FROM %Table:SD1% D1 WHERE ROWNUM = 1
				 	 AND D1.D1_DTDIGIT = (SELECT MIN(D1.D1_DTDIGIT) FROM %Table:SD1% D1 WHERE D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%)  
				 	 AND D1.D1_COD = B1.B1_COD AND D1.D_E_L_E_T_ = ' ' %exp:_cfild1%) REGD1MIN,
				 	 
				 	(SELECT D3.R_E_C_N_O_ FROM %Table:SD3% D3 WHERE ROWNUM = 1
				 	 AND D3.D3_EMISSAO = (SELECT MIN(D3.D3_EMISSAO) FROM %Table:SD3% D3 WHERE D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%)  
				 	 AND D3.D3_COD = B1.B1_COD AND D3.D_E_L_E_T_ = ' ' %exp:_cfild3%) REGD3MIN,
				 	 
					(SELECT BZ_I_OBSOL FROM %Table:SBZ% BZ WHERE BZ.BZ_FILIAL = %exp:_cfilial% AND  BZ.BZ_COD = B1.B1_COD AND BZ.D_E_L_E_T_ = ' ' 
						AND ROWNUM = 1 ) BZOBSOL 
	
				FROM 
					%Table:SB1% B1 
				WHERE 
			        B1.D_E_L_E_T_ = ' '
			        %exp:_cFiltro%			 
				ORDER BY B1.B1_COD
			EndSql
	
EndIf

(_cAliasSB1)->(DBGoTop())   

If (_cAliasSB1)->(Eof())

   U_ITMsg("Não encontrou resgistros",'Atenção!',"SOLUCAO",1) // Cancel
    
	//1 - Indica que nao foram encontrados dados 0 - Indica que foram encontrados dados
	Return .F.

EndIf

_nConta:=0
COUNT TO _nConta
_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)+1
_nConta:=0

MV_PAR01:=MV_PAR01
MV_PAR02:=MV_PAR02

(_cAliasSB1)->(DBGoTop())   

_cAliasSB2	:= 	GetNextAlias()

While (_cAliasSB1)->(!Eof())

   _nConta++
   oProc:cCaption := ("2/2-Lendo Dados: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
   ProcessMessages()

	_culmov := '20010101'
	_cprimov := '20490101'

	//Define ultimo movimento e se grava
	If (_cAliasSB1)->ULD2 >  _culmov
       SD2->(DBGoTo((_cAliasSB1)->REGD2MAX))
       
       _cSeqMov   := SD2->D2_SEQCALC 
	   _culmov    := (_cAliasSB1)->ULD2
	   _culdoc    := SD2->D2_DOC//(_cAliasSB1)->DOCD2MAX // _culdoc := (_cAliasSB1)->DOCD2MAX
	   _ctipul    := "SD2"
	
	EndIf

	If (_cAliasSB1)->ULD1 >  _culmov
       SD1->(DBGoTo((_cAliasSB1)->REGD1MAX))                                      
       
       _cSeqMov   := SD1->D1_SEQCALC
	   _culmov    := (_cAliasSB1)->ULD1
	   _culdoc    := SD1->D1_DOC  //(_cAliasSB1)->DOCD1MAX // _culdoc := (_cAliasSB1)->DOCD1MAX
	   _ctipul    := "SD1"
	
	EndIf

	If (_cAliasSB1)->ULD3 >  _culmov
       SD3->(DBGoTo((_cAliasSB1)->REGD3MAX))
       
       _cSeqMov   := SD3->D3_SEQCALC
	   _culmov    := (_cAliasSB1)->ULD3
	   _culdoc    := SD3->D3_DOC //(_cAliasSB1)->DOCD3MAX // _culdoc := (_cAliasSB1)->DOCD3MAX
	   _ctipul    := "SD3"
	
	EndIf
	
	//Define primeiro movimento e se grava
	If MV_PAR08 <> 3 .And. (_cAliasSB1)->PRI2 <  _cprimov
       SD2->(DBGoTo((_cAliasSB1)->REGD2MIN))
       
       _cSeqMov    := SD2->D2_SEQCALC
	   _cprimov    := (_cAliasSB1)->PRI2
	   _cpridoc    := SD2->D2_DOC // (_cAliasSB1)->DOCD2MIN // _cpridoc := (_cAliasSB1)->DOCD2MIN
	   _ctipri     := "SD2"
	
	EndIf

	If MV_PAR08 <> 3 .And. (_cAliasSB1)->PRI1 <  _cprimov
       SD1->(DBGoTo((_cAliasSB1)->REGD1MIN))
       
       _cSeqMov    := SD1->D1_SEQCALC
	   _cprimov    := (_cAliasSB1)->PRI1
	   _cpridoc    := SD1->D1_DOC  // (_cAliasSB1)->DOCD1MIN // _cpridoc := (_cAliasSB1)->DOCD1MIN
	   _ctipri     := "SD1"
	
	EndIf

	If MV_PAR08 <> 3 .And. (_cAliasSB1)->PRI3 <  _cprimov
       SD3->(DBGoTo((_cAliasSB1)->REGD3MIN))
       
       _cSeqMov    := SD3->D3_SEQCALC 
	   _cprimov    := (_cAliasSB1)->PRI3
	   _cpridoc    := SD3->D3_DOC  //(_cAliasSB1)->DOCD3MIN // _cpridoc := (_cAliasSB1)->DOCD3MIN
	   _ctipri     := "SD3"
	
	EndIf
	
	//Se não tem data de primeiro movimento apresenta 01/01/2001 para o usuário saber que não tem 
	If _cprimov == '20490101'
	
		_cprimov := "20010101"
		
	EndIf

	//só inclui o que tem ultimo movimento menor que o indicado no primeiro parametro e primeiro movimento maior que o indicado no primeiro parametro
	If SToD(_culmov) <= MV_PAR02 .And. ( SToD(_cprimov) >= MV_PAR01 .Or. MV_PAR08 = 3)
	

		//filtra bloqueados e obsoletos de acordo com MV_PAR08
		If MV_PAR08 = 1 .OR.;//TODOS
		  (MV_PAR08 = 2 .And. (_cAliasSB1)->B1_MSBLQL == 'S') .Or. ;                                     //BLOQUEADOS
		  (MV_PAR08 = 3 .And. (_cAliasSB1)->BZOBSOL   == 'S' .And. (_cAliasSB1)->B1_MSBLQL != 'S') .Or. ;//OBSOLETOS
		  (MV_PAR08 = 4 .And. (_cAliasSB1)->BZOBSOL   != 'S' .And. (_cAliasSB1)->B1_MSBLQL != 'S')       //LIBERADOS
		
			DBSelectArea(_cTab)	                     	
			RecLock(_cTab,.T.)    
		
		
				&(_cTab+'->'+_cTab+'_STATUS') 		:= Space(2)
				&(_cTab+'->'+_cTab+'_LEGEND') 		:= Space(2) 
				&(_cTab+'->'+_cTab+'_TIPO') 		:= (_cAliasSB1)->B1_TIPO
				&(_cTab+'->'+_cTab+'_GRUPO'   ) 	:= (_cAliasSB1)->B1_GRUPO
				&(_cTab+'->'+_cTab+'_PRIMOV') 		:= SToD(_cprimov)
				&(_cTab+'->'+_cTab+'_DETPRI') 		:= _cpridoc + " - " + _ctipri
				&(_cTab+'->'+_cTab+'_ULMOV') 		:= SToD(_culmov)
				&(_cTab+'->'+_cTab+'_DETUL') 		:= _culdoc + " - " + _ctipul
				&(_cTab+'->'+_cTab+'_CODIGO'  ) 	:= (_cAliasSB1)->B1_COD
				&(_cTab+'->'+_cTab+'_DESCRI') 		:= (_cAliasSB1)->B1_DESC
				&(_cTab+'->'+_cTab+'_OBSOL') 		:= (_cAliasSB1)->BZOBSOL
				&(_cTab+'->'+_cTab+'_BLOQ') 		:= (_cAliasSB1)->B1_MSBLQL
                &(_cTab+'->'+_cTab+'_SEQCAL')       := _cSeqMov
                
			(_cTab)->(MSUnLock())       

		EndIf

	EndIf		
		         
	(_cAliasSB1)->(DBSkip())            
	
EndDo

(_cAliasSB1)->(DBCloseArea())

U_ITLOGACS('MEST008')

Return .T.

/*
===============================================================================================================================
Programa----------: MEST008S1
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Ajusta marcação de linha do browse
Parametros--------: 	_cTab - Alias da tabela temporária
						_cstatus - Marcação a ser feita na linha	
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008S1(_cTab,_cStatus)

If _cStatus == Space(2) 

	RecLock(_cTab,.F.)	   		

		&(_cTab+'->'+_cTab+'_STATUS'):= 'XX'
		
		_nQtdPrd++ 
			     		
	(_cTab)->(MSUnLock())  
		
Else
			
	RecLock(_cTab,.F.)   		

		&(_cTab+'->'+_cTab+'_STATUS'):= Space(2) 
	
		_nQtdPrd--  

	(_cTab)->(MSUnLock())  
	
EndIf      
	
_nQtdPrd:= IIf(_nQtdPrd<0,0,_nQtdPrd)

_oQtda:Refresh()	
	
_oBrowse:Refresh(.T.)  	

Return

/*
===============================================================================================================================
Programa----------: MEST008S2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Ajusta todas as marcações de linha do browse
Parametros--------: 	_cTab - Alias da tabela temporária
						_nColuna - coluna a ser ajustada
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008S2(_cTab,_nColuna)

Local _aArea:= FWGetArea()
		
	  //Marca ou desmarca todos os titulos selecionados 	
      If _nColuna == 1    
      
      		DBSelectArea(_cTab)
      		(_cTab)->(DBGoTop())
      		
      		While (_cTab)->(!Eof())   
      		                    
      			//Se o titulo nao estiver selecionado
      			If &(_cTab+'->'+_cTab+'_STATUS') == Space(2) 

					RecLock(_cTab,.F.)	   		
						&(_cTab+'->'+_cTab+'_STATUS'):= 'XX'
						_nQtdPrd++ 
						
						(_cTab)->(MSUnLock())  
					
		        //Titulo selecionado
				Else
				
					RecLock(_cTab,.F.)   		
						&(_cTab+'->'+_cTab+'_STATUS'):= Space(2) 
						_nQtdPrd--  
	
					(_cTab)->(MSUnLock())  
	
   				EndIf      
           
      		(_cTab)->(DBSkip())
      		EndDo     
      		
      		_nQtdPrd:= IIf(_nQtdPrd<0,0,_nQtdPrd)  
   			_oQtda:Refresh()	
   						
			FWRestArea(_aArea) 
			                 
		      
      EndIf                  
	
_oBrowse:DrawSelect()   
_oBrowse:Refresh(.T.)      
      
Return                                               

/*
===============================================================================================================================
Programa----------: MEST008V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Funcao para Visualizacao no arquivo temporario. 
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008V()

Local _aArea:= FWGetArea()
Private cCadastro
cCadastro 	:= OemToAnsi( "Visualizar" )

DBSelectArea("SB1")
SB1->(DBSetOrder(1))

If SB1->(DBSeek(  xFilial("SB1") + TE1->TE1_CODIGO ))

	AxVisual( "SB1", SB1->( Recno() ), 2 )

    //===============================================================
    // Grava log de visualização de dados.
    //=============================================================== 
    U_ITLOGACS('MEST008V')

EndIf

FWRestArea( _aArea )        

Return

/*
===============================================================================================================================
Programa----------: MEST008CA
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime cabecalho da página
Parametros--------: impnrpag - número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008CA(impNrPag)

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "Relação de PRODUTO - Rotina de produtos obsoletos" 
  
_nLinha:=0100

	_oPrint:SayBitmap(_nLinha,_nColInic,cRaizServer + "system/lgrl01.bmp",250,100)        
	
	If impNrPag <> 0
	
		_oPrint:Say (_nLinha,(_nColInic + 2750),"PÁGINA: " + AllTrim(Str(_nPagina)),_oFont12b)
	
	Else
	
			_oPrint:Say (_nLinha,(_nColInic + 2750),"SIGA/MEST008",_oFont12b)
			_oPrint:Say (_nLinha + 100,(_nColInic + 2750),"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),_oFont12b)
	
	EndIf
	
	_oPrint:Say (_nLinha + 50,(_nColInic + 2750),"DATA DE EMISSÃO: " + DToC(DATE()),_oFont12b)
	_nLinha+=(_nSaltoLinha * 3)           
	                                                   
	_oPrint:Say (_nLinha,_nColFinal / 2,cTitulo,_oFont16b,_nColFinal,,,2)
	
	_nLinha+=_nSaltoLinha 
	_nLinha+=_nSaltoLinha        
	
	_oPrint:Line(_nLinha,_nColInic,_nLinha,_nColFinal)      
	
	_nLinha+=_nSaltoLinha 
	_nLinha+=_nSaltoLinha

Return                                       

/*
===============================================================================================================================
Programa----------: MEST008CD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime cabeçalho dos produtos
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008CD()
 
_nLinInBox:= _nLinha
 
_oPrint:FillRect({(_nLinha+3),_nColInic,_nLinha + _nSaltoLinha,_nColFinal},_oBrush)                    
 
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 10   ,"Tipo"          	,_oFont12b)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 160  ,"Grupo"         	,_oFont12b)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 500  ,"Pri. Mov."      ,_oFont12b)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 700  ,"Ul. Mov."        ,_oFont12b)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 850  ,"Código"       	,_oFont12b)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 1190 ,"Descrição"  	   ,_oFont12b)

Return  

/*
===============================================================================================================================
Programa----------: MEST008DD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime dados dos produtos
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MEST008DD(_cTipo,_cGrupo,_cUlmov,_cCodigo,_cDescri,_cprimov)                 
                                                            
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 10   ,_cTipo                     ,_oFont12)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 160  ,_cGrupo    		          ,_oFont12)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 500  ,DToC(_cprimov)               ,_oFont12)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 700  ,DToC(_cUlmov)               ,_oFont12)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 850  ,_cCodigo                     ,_oFont12)
_oPrint:Say (_nLinha + _nAjuAltLi1,_nColInic + 1190  ,_cDescri	                   ,_oFont12)

Return        

/*
===============================================================================================================================
Programa----------: MEST008BX
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime linhas de box
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MEST008BX()
      
_oPrint:Line(_nLinInBox,_nColInic + 155 ,_nLinha+_nSaltoLinha,_nColInic + 155 )  
_oPrint:Line(_nLinInBox,_nColInic + 495 ,_nLinha+_nSaltoLinha,_nColInic + 495 )  
_oPrint:Line(_nLinInBox,_nColInic + 695 ,_nLinha+_nSaltoLinha,_nColInic + 645 )  
_oPrint:Line(_nLinInBox,_nColInic + 845 ,_nLinha+_nSaltoLinha,_nColInic + 645 )  
_oPrint:Line(_nLinInBox,_nColInic + 1185 ,_nLinha+_nSaltoLinha,_nColInic + 985 )


_oPrint:Box(_nLinInBox ,_nColInic,_nLinha+_nSaltoLinha,_nColFinal) 

Return 

/*
===============================================================================================================================
Programa----------: MEST008QB
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime linhas de box
Parametros--------: 	_nLinhas - em que linha esta a impressao
						impbox - se imprime box
						impcabec - se imprime cabecalho
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MEST008QB(_nLinhas,impBox,impCabec)   

	//Quebra de pagina
	If _nLinha > _nquebrapag
				
		_nLinha:= _nLinha - (_nSaltoLinha * _nLinhas)
		
		If impBox == 1  
		
			MEST008BX()          
		   	   
		EndIf	 
		
		_oPrint:EndPage()					// Finaliza a Pagina.
		_oPrint:StartPage()					//Inicia uma nova Pagina					
		_nPagina++		
		
		MEST008CA(1)         
		
		If impCabec == 1
			
			MEST008CD()
	
			_nLinha+=_nSaltoLinha   
			_oPrint:Line(_nLinha,_nColInic,_nLinha,_nColFinal) 
		
		EndIf
		
	EndIf  
	
Return	    

/*
===============================================================================================================================
Programa----------: MEST008IP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprime a ordem -  Nome
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/                          
Static Function MEST008IP(oProc)   

Local _aArea        := FWGetArea() 
                  
Private _oFont10
Private _oFont10b
Private _oFont12
Private _oFont12b  
Private _oFont16b           
Private _oFont14
Private _oFont14b
Private _oPrint
Private _nPagina     := 1
Private _nLinha      := 0100
Private _nColInic    := 0030
Private _nColFinal   := 3360 
Private _nquebrapag  := 2200 
Private _nLinInBox   
Private _nSaltoLinha := 50     
Private _nAjuAltLi1  := 11 //ajusta a altura de impressao dos dados do relatorio 
Private _oBrush      := TBrush():New( ,CLR_LIGHTGRAY)  

                                                                              
Define Font _oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font _oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
Define Font _oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font _oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  

Define Font _oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font _oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
Define Font _oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito 

_oPrint:= TMSPrinter():New( "AJUSTA OBSOLETO SB1" )  
_oPrint:SetPaperSize(9)	// Seta para papel A4		
_oPrint:SetLandscape() // Paisagem

DBSelectArea("TE1")
TE1->(DBGoTop())    

//Imprime o cabecalho e cabecalho de dados da primeira pagina
MEST008CA(0)     

MEST008CD()

_nConta:=TE1->(LASTREC())
_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)+1
_nConta:=0

While TE1->(!Eof())
   
   _nConta++
   oProc:cCaption := ("Imprmindo Mat.: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
   ProcessMessages()

	_nLinha+=_nSaltoLinha   
    _oPrint:Line(_nLinha,_nColInic,_nLinha,_nColFinal) 
    MEST008QB(1,1,1)   
    MEST008DD(TE1->TE1_TIPO,TE1->TE1_GRUPO,TE1->TE1_ULMOV,TE1->TE1_CODIGO,TE1->TE1_DESCRI,TE1->TE1_PRIMOV)
     
	TE1->(DBSkip())
	
EndDo

_oPrint:EndPage()
_oPrint:Preview()

FWRestArea(_aArea)         

//===============================================================
// Grava log de Impressão dos dados.
//=============================================================== 
U_ITLOGACS('MEST008IP')

Return       

/*
===============================================================================================================================
Programa----------: MEST008AL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Altera produtos selecionados
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/   
Static Function MEST008AL(oProc)

Local _aArea        := FWGetArea()  
Local _aLog		  := {}  

Private lMsErroAuto := .F.
lMsErroAuto := .F.

DBSelectArea("TE1")
TE1->(DBGoTop())

aAdd( _aLog , "FUNÇÃO MEST008"								)		                 
aAdd( _aLog , "DATA DE PROCESSAMENTO: "+ DToC( Date() )		)
aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)

_nConta:=0
_nConta:=TE1->(LASTREC())
_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)+1
_nConta:=0
		

SBZ->(DBSetOrder(1))
SB1->(DBSetOrder(1))

While TE1->(!Eof())

   _nConta++
   oProc:cCaption := ("Lendo Dados: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
   ProcessMessages()
       
	//Somente registros marcados 
	If TE1->TE1_STATUS == 'XX' 
	
		
		If SBZ->(DBSeek(  xFilial("SBZ") + TE1->TE1_CODIGO )) .And. SB1->(DBSeek(  xFilial("SB1") + TE1->TE1_CODIGO ))                        
		
			//verifica parâmetro para ver o que muda
			If MV_PAR05 == 1 .Or. MV_PAR05 == 3
			
				RecLock("SBZ",.F.)
				SBZ->BZ_I_OBSOL := 'S'
				aAdd( _aLog ,	"O PRODUTO "+ AllTrim(TE1->TE1_CODIGO) +" FOI MARCADO COMO OBSOLETO." )
				SBZ->(MSUnLock())  
				
			EndIf
			
			If MV_PAR05 == 2 .Or. MV_PAR05 == 3
			
				RecLock("SB1",.F.)  
				SB1->B1_MSBLQL := 'S'
				aAdd( _aLog ,	"O PRODUTO "+ AllTrim(TE1->TE1_CODIGO) +" FOI MARCADO COMO BLOQUEADO." )
				SB1->(MSUnLock()) 
				
			EndIf
			
			If MV_PAR05 == 4
			
				RecLock("SB1",.F.)  
				SB1->B1_MSBLQL := 'N'
				aAdd( _aLog ,	"O PRODUTO "+ AllTrim(TE1->TE1_CODIGO) +" FOI MARCADO COMO DESBLOQUEADO." )
				SB1->(MSUnLock()) 
				
					
			EndIf
	
			If MV_PAR05 == 5
			
				RecLock("SBZ",.F.)  
				SBZ->BZ_I_OBSOL := 'N'
				aAdd( _aLog ,	"O PRODUTO "+ AllTrim(TE1->TE1_CODIGO) +" FOI DESMARCADO COMO OBSOLETO." )
				SBZ->(MSUnLock())  
					
			EndIf
		Else
		
				xMagHelpFis("Erro","Erro ao alterar o seguinte produto: " + TE1->TE1_CODIGO +" - " + TE1->TE1_DESCRI)
				aAdd( _aLog ,	"O PRODUTO "+ AllTrim(TE1->TE1_CODIGO) +" NÃO FOI ENCONTRADO NO SB1 E SBZ." )
			
		EndIf	
	
	EndIf

	TE1->(DBSkip())

EndDo

FWRestArea(_aArea) 

aAdd( _aLog ,	"FINAL - INDICADOR DE PRODUTOS" )
aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: "+ Time() )

oProc:cCaption := "Gravando Log..."
ProcessMessages()
//Grava log de processamento
MEST008LO(_aLog) 
 
Return

/*
===============================================================================================================================
Programa----------: MEST008VL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Valida se tem produtos selecionados
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MEST008VL(_nQtdPrd)

Local _lRet:= .T.

If _nQtdPrd == 0      
	
	xMagHelpFis("Validação","Favor selecionar um ou mais títulos antes de realizar esta operação.",;
	            "Favor proceder de acordo com a solicitação efetuada acima, qualquer dúvida favor entrar em contato com o depto de informática.")              
	
	_lRet:= .F.

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MEST008CO
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Rotina para montar consulta de tipos de movimentação de estoque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST008CO()

Local _cRet		:= ''   , _nI
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Movimentos de estoque'
Local _aDados	:= {}

_cQuery := " SELECT F5_CODIGO, 
_cQuery += " F5_TEXTO FROM "
_cQuery += RETSQLNAME('SF5') +" SF5 
_cQuery += " WHERE " + RETSQLCOND('SF5') 
_cQuery += " AND SF5.F5_FILIAL = '" + xFilial("SF5") + "'"
_cQuery += " ORDER BY SF5.F5_CODIGO"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

_cQuery := ChangeQuery(_cQuery)

MPSysOpenQuery(_cQuery,_cAlias)

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

//carrega documentos válidos na matriz
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->F5_CODIGO, (_cAlias)->F5_TEXTO  } )
	
	(_cAlias)->( DBSkip() )
	
EndDo

(_cAlias)->( DBCloseArea() )

//Se tiver documentos válidos cria a consulta
If Len(_aDados) > 0

	If U_ITListBox( _cTitAux , { '__' , 'Código', 'Descrição' } , @_aDados , .F. , 2 , 'Selecione os tipos de movimento desejados: ' )

		For _nI := 1 To Len( _aDados )
		
			If _aDados[_nI][01]
				_cRet += AllTrim( _aDados[_nI][02] ) +'/'
			EndIf
		
		Next _nI
	
		&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )
		
	EndIf

//se não tiver documentos válidos alerta e sai
Else
	
	alert("Não há tipos de movimentos válidos!")
	
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: MEST008LO
Autor-------------: Josué Danich Prestes	
Data da Criacao---: 19/10/2015
Descrição---------: Rotina que permite gravar o LOG referente ao processamento
Parametros--------: _aLog - registro de eventos a ser salvo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST008LO(_aLog)

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

Return

/*
===============================================================================================================================
Programa----------: MEST008E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2017
Descrição---------: Rotina de exportação de dados para o Excel.
Parametros--------: Nenhum
===============================================================================================================================
*/
User Function MEST008E() 
Local _oDlgE,_bOk,_bCancel
Local _cTitulo
Local _oDados
Local _lRet := .F.
Local _nI
Local _cCampo

Private _aDados := {"Todos os Dados","Apenas Dados Selecionados"}
Private _cDados := ""

Begin Sequence
   //===============================================================
   // Cria tabela temporária para Exportação de dados em Excel  
   //===============================================================
   _cCampo := _cAlias + "_LEGEND"
   _nI := aScan(_aStructExcel,{|x| x[1] == _cCampo})
   If _nI > 0
      _aStructExcel[_nI,3] := 15 // Aumenta o tamanho do campo para gravar o texto da legenda.
   EndIf                                                                                      
   
   If Select("TRBEXCEL") > 0
      TRBEXCEL->(DBCloseArea())
   EndIf

   _otemp := FWTemporaryTable():New( "TRBEXCEL", _aStructExcel )

   _otemp:AddIndex( "01", {_cAlias + "_CODIGO", _cAlias + "_SEQCAL"} )
   
   _otemp:Create()
     
   //===============================================================
   // Tela principal para geração do relatório em Excel
   //===============================================================
   _cTitulo := "Exportação dos Dados para o MS Excel"
   
   _bOk := {|| _lRet := .T., _oDlgE:End()}
   _bCancel := {|| _lRet := .F., _oDlgE:End()}
   
   Define MsDialog _oDlgE Title _cTitulo From 9,0 To 20,60 Of oMainWnd 
      @ 35,05 Say "Dados a Serem Exportados: " Of _oDlgE Pixel		
      @ 35,100 ComboBox _oDados Var _cDados Items {"Todos os Dados","Apenas Dados Selecionados"} Size 100,10 Of _oDlgE Pixel	
      
   Activate MsDialog _oDlgE On Init EnchoiceBar(_oDlgE,_bOk,_bCancel) CENTERED 
   
   If _lRet 
      Processa( {|| U_MEST008G() } , "Exportando dados para Excel..." )
      
      //===============================================================
      // Grava log de Exportação dos dados para o Excel.
      //=============================================================== 
      U_ITLOGACS('MEST008E')
      
   EndIf 
   
End Sequence

Return

/*
===============================================================================================================================
Programa----------: MEST008G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2017
Descrição---------: Grava dados em tabela temporária para o Excel e chama o gerador de relatório em Excel.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST008G()
Local _nRegAtu := (_cAlias)->(Recno())
Local _nTotRegs := (_cAlias)->(LastRec())
Local _nI

Local _cDir := GetTempPath()  // Diretório de Geração das planilhas.
Local _cArq := "REL_CONFERENCIA_FISCAL_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   
Local _aCabecalho := {}//- Array de cabecalho da planilha {{"Titulo 1","Alinhamento","Formatacao","Totaliza(s/n)"},
Local _aCampos := {}
Local _cCampo

Begin Sequence
   ProcRegua(_nTotRegs)
   
   _cCampo := "TRBEXCEL->"+_cAlias + "_LEGEND"
   
   //================================================================================
   // Gravando dados para o relatorio em Excel.
   //================================================================================      
   (_cAlias)->(DBGoTop())
   While ! (_cAlias)->(Eof())  
      IncProc("Gravando dados para Rel.Excel...")
      
      If AllTrim(_cDados) == _aDados[2] //{"Todos os Dados","Apenas Dados Selecionados"}
         If Empty(&(_cAlias+'->' +_cAlias + "_STATUS"))
            (_cAlias)->(DBSkip())
            Loop
         EndIf
      EndIf
      
      TRBEXCEL->(RecLock("TRBEXCEL",.T.))
      For _nI := 1 To (_cAlias)->(FCount())
          &("TRBEXCEL->"+(_cAlias)->(FieldName(_nI))) := &(_cAlias+"->"+(_cAlias)->(FieldName(_nI)))
      Next
      
      If &(_cAlias + '->' +_cAlias + "_BLOQ") == "S"
         &(_cCampo) := "BLOQUEADO"
      ElseIf &(_cAlias + '->' +_cAlias + "_OBSOL")=="S"
         &(_cCampo) := "OBSOLETO"
      Else
         &(_cCampo) := "NORMAL"
      EndIf
      TRBEXCEL->(MSUnLock())      
      
      (_cAlias)->(DBSkip())
   EndDo

   //================================================================================
   // Gerando o Relatorio em Excel
   //================================================================================      
   IncProc("Gerando o Relatorio em Excel...")

   //================================================================================
   // Montando Cabeçalho do Relatório
   //================================================================================         
   _aCabecalho := {}//- Array de cabecalho da planilha {{"Titulo 1","Alinhamento","Formatacao","Totaliza(s/n)"},
   //                Titulo das Colunas             ,Alinhamento ,Formatação, Totaliza?
   aAdd(_aCabecalho,{"STATUS"   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"LEGENDA"  ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"TIPO"     ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"GRUPO >>" ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"PRI MOVIM",1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DOC ORI"  ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ULT MOVIM",1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DOC ORI"  ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CODIGO"   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRICAO",1           ,1         ,.F.})
   
   //======================================================================================================================
   // Array com os campos para leitura de dados e montagem dos dados do relatório.
   //======================================================================================================================
   _aCampos := {} // {"TRBREL->A1_COD", "TRBREL->A1_LOJA", "TRBREL->A1_NOME"} 
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_STATUS" )
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_LEGEND")
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_TIPO"  )
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_GRUPO" )
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_PRIMOV")
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_DETPRI")
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_ULMOV" )
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_DETUL" )
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_CODIGO")
   aAdd(_aCampos,"TRBEXCEL->"+_cAlias+"_DESCRI")
   
   //================================================================================
   // Abrindo o relatório no Excel.
   //================================================================================                                                                                            
   IncProc("Abrindo o relatório no Excel...")
   U_ITGEREXCEL(_cArq,_cDir,"RELAÇÃO DE PRODUTOS OBSOLETOS E/OU PARA BLOQUEAR","RELATORIO",_aCabecalho,,.T.,"TRBEXCEL",_aCampos)   

End Sequence

(_cAlias)->(DBGoTo(_nRegAtu)) // Posiciona no ultimo registro posicionado na tela,antes de gerar relatório em Excel.

Return

/*
===============================================================================================================================
Programa----------: MEST008F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2017
Descrição---------: Realizar a filtragem de dados da tela de marca e deamarca.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST008F()
Local _oDlgF,_bOk,_bCancel
Local _cTitulo
Local _lRet := .F.
Local _cExpres01, _cExpressao//, _cExpres02
Local _aItensDt := {"Maior","Igual","Menor"} 
Local _aItensSD := {"Sim","Nao"}
Local _cAcoesFiltro, _aAcoesFiltro := {"Filtrar", "Limpar Filtro"}   

Private _cMove_P, _cMove_F
Private _cOpcSD1, _cOpcSD2, _cOpcSD3 

Begin Sequence              
   _dDtPriMov := Ctod("  /   /  ")
   _dDtUltMov := Ctod("  /   /  ")
   _cOpcSD1 := "Sim"
   _cOpcSD2 := "Sim"
   _cOpcSD3 := "Sim"
   _cMove_P := "Maior"
   _cMove_F := "Menor"
   _cAcoesFiltro := _aAcoesFiltro[1] // {"Filtrar", "Limpar Filtro"}   
   
   _cTitulo := "Filtragem dos Dados de Seleção"
   
   _bOk := {|| _lRet := .T., _oDlgF:End()}
   _bCancel := {|| _lRet := .F., _oDlgF:End()}
   
   Define MsDialog _oDlgF Title _cTitulo From 9,0 To 30, 60 Of oMainWnd 
        nCol:=62
        nLin:=35        
      @ nLin,05 Say "Dt.Primeiro Movimento: " Of _oDlgF Pixel		
      @ nLin,nCol Get _dDtPriMov Size 40,10 Of _oDlgF Pixel
      @ nLin,120 ComboBox  _cMove_P Items _aItensDt Size 50,10 Of _oDlgF Pixel	//_oDadosP Var
        nLin+=20
      
      @ nLin,05 Say "Dt.Ultimo Movimento: " Of _oDlgF Pixel		
      @ nLin,nCol Get _dDtUltMov Size 40,10 Of _oDlgF Pixel
      @ nLin,120 ComboBox  _cMove_F Items _aItensDt Size 50,10 Of _oDlgF Pixel	//_oDadosF Var
        nLin+=20
      
      @ nLin,05 Say "Exibir SD1: " Of _oDlgF Pixel		
      @ nLin,nCol ComboBox  _cOpcSD1 Items _aItensSD Size 30,10 Of _oDlgF Pixel	//_oDadosSD1 Var
        nLin+=20

      @ nLin,05 Say "Exibir SD2: " Of _oDlgF Pixel		
      @ nLin,nCol ComboBox  _cOpcSD2 Items _aItensSD Size 30,10 Of _oDlgF Pixel	//_oDadosSD2 Var
        nLin+=20

      @ nLin,05 Say "Exibir SD3: " Of _oDlgF Pixel		
      @ nLin,nCol ComboBox  _cOpcSD3 Items _aItensSD Size 30,10 Of _oDlgF Pixel	//_oDadosSD3 Var
        nLin+=20
                                                                                            
      @ nLin,05 Say "Ações do Filtro: " Of _oDlgF Pixel		
      @ nLin,nCol ComboBox  _cAcoesFiltro Items _aAcoesFiltro Size 60,10 Of _oDlgF Pixel  //_oDadosAcao Var

   Activate MsDialog _oDlgF On Init EnchoiceBar(_oDlgF,_bOk,_bCancel)  
   
   If _lRet 
      If AllTrim(_cAcoesFiltro) == _aAcoesFiltro[2] // "Limpar Filtro"  
         _cExpressao := _cAlias+"->(DBClearFilter())"
         &(_cExpressao)
      Else
         _cExpres01 := ""
      
         If ! Empty(_dDtPriMov)
            _cExpres01 := "DToS("+_cAlias+"_PRIMOV)"
            If AllTrim(_cMove_P) == _aItensDt[1]     // "Maior"
               _cExpres01 += " > DToS(_dDtPriMov) "
            ElseIf AllTrim(_cMove_P) == _aItensDt[2] // "Igual"
               _cExpres01 += " = DToS(_dDtPriMov) "
            ElseIf AllTrim(_cMove_P) == _aItensDt[3] // "Menor"
               _cExpres01 += " < DToS(_dDtPriMov) "
            EndIf       
         EndIf
      
         If ! Empty(_dDtUltMov)
            If ! Empty(_dDtPriMov)
               _cExpres01 += " .And. "
            EndIf
                                      
            _cExpres01 += " DToS("+_cAlias+"_ULMOV)" 
            If AllTrim(_cMove_F) == _aItensDt[1]     // "Maior"
               _cExpres01 += " > DToS(_dDtUltMov) "
            ElseIf AllTrim(_cMove_F) == _aItensDt[2] // "Igual"
               _cExpres01 += " = DToS(_dDtUltMov) "
            ElseIf AllTrim(_cMove_F) == _aItensDt[3] // "Menor"
               _cExpres01 += " < DToS(_dDtUltMov) "
            EndIf     
         EndIf
           
         If AllTrim(_cOpcSD1) == _aItensSD[2] // Nao
            If ! Empty(_cExpres01)
               _cExpres01 += " .And. " 
            EndIf
            _cExpres01 += "! ('SD1' $ "+_cAlias+"_DETPRI) "
            _cExpres01 += ".And. ! ('SD1' $ "+_cAlias+"_DETUL) "
         EndIf
      
         If AllTrim(_cOpcSD2) == _aItensSD[2] // Nao
            If ! Empty(_cExpres01)
               _cExpres01 += " .And. " 
            EndIf
            _cExpres01 += "! ('SD2' $ "+_cAlias+"_DETPRI) "
            _cExpres01 += ".And. ! ('SD2' $ "+_cAlias+"_DETUL) "
         EndIf
      
         If AllTrim(_cOpcSD3) == _aItensSD[2] // Nao
            If ! Empty(_cExpres01)
               _cExpres01 += " .And. " 
            EndIf
            _cExpres01 += "! ('SD3' $ "+_cAlias+"_DETPRI) "
            _cExpres01 += ".And. ! ('SD3' $ "+_cAlias+"_DETUL) "
         EndIf
      
         _cExpressao := _cAlias+"->(DbSetFilter({|| "+_cExpres01+' } , "'+_cExpres01+'" ))'

         &(_cExpressao)  
                               
         If (_cAlias)->(Eof()) .Or. (_cAlias)->(Bof())
            MsgStop("Não existem dados que satisfaçam as opções de filtros.","Atenção")
            _cExpressao := _cAlias+"->(DBClearFilter())"
            &(_cExpressao)
            Break
         EndIf
         
      EndIf
      
      //===============================================================
      // Grava log de Filtragem de dados.
      //=============================================================== 
      U_ITLOGACS('MEST008F')
      
   EndIf

End Sequence

(_cAlias)->(DBGoTop())

_oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MEST008M
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/04/2017
Descrição---------: Marca ou desmarca todos os registros filtrados.
Parametros--------: _cOpcao = "MARCAR" ou "DESMARCAR" registros.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST008M(_cOpcao)

Local _nRegAtu := (_cAlias)->(Recno())

Begin Sequence         
   (_cAlias)->(DBGoTop())
   While ! (_cAlias)->(Eof())
      If _cOpcao == "MARCAR"
         MEST008S1(_cAlias,Space(2))
      Else // DESMARCAR
         MEST008S1(_cAlias,"XX")
      EndIf
           
      (_cAlias)->(DBSkip())
   EndDo
End Sequence

(_cAlias)->(DBGoTo(_nRegAtu)) 

//===============================================================
// Grava log de Marcação de registros.
//=============================================================== 
U_ITLOGACS('MEST008E')

Return
