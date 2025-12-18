#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F060PROC
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/11/2016
Descrição---------: Ponto de Entrada de validação de inclusão de títulos no bordero - Chamado 16924
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F060PROC()

Local _aArea		:= FWGetArea()
Local _aAreaSE1		:= SE1->(GetArea())
Local _cBancoP		:= ""
Local _cContaP		:= ""
Local _cSubcoP		:= ""
Local _cAgencP		:= ""
Local _cOperP		:= ""
Local _cAgencia		:= ParamIXB[2]
Local _cConta		:= ParamIXB[3]
Local _aBco			:= {}
Local _cTexto		:= ""
Local _cAux			:= ""
Local _nOpc			:= 0
Local _aDatSacado	:= {}
Local _lBloqCNAB	:= SuperGetMV("ITBLCNAB", ,.F.)

If Type("_LREIMPRIME") == "U"
   _LREIMPRIME := .F.
EndIf 

DBSelectArea("ZZJ")
DBSetOrder(1)
If ZZJ->(DBSeek(xFilial("ZZJ")+AllTrim(cfilant)))
	While AllTrim(ZZJ->ZZJ_FILIAL) == AllTrim(xFilial("ZZJ")) .And. AllTrim(ZZJ->ZZJ_FILACE) == AllTrim(cfilant)
		aAdd(_aBco, {ZZJ->ZZJ_BANCO,ZZJ->ZZJ_CONTA,ZZJ->ZZJ_AGENCI,ZZJ->ZZJ_SUBCON,ZZJ->ZZJ_OPER,ZZJ->ZZJ_DEFAUL})
					//      1             2               3               4                5           6
		ZZJ->( DBSkip() )
	End
EndIf

DBSelectArea("TRB")
TRB->(DBSetOrder(1))
TRB->(DBGoTop())

While !TRB->(Eof())

	DBSelectArea("SE1")
	SE1->( DBSetOrder(1) )
	If SE1->( DBSeek(xFilial("SE1")+TRB->E1_PREFIXO+TRB->E1_NUM+TRB->E1_PARCELA+TRB->E1_TIPO) )
	
	   	If Empty(AllTrim(SE1->E1_NUMBCO)) 
			
			//Se tem incosistência entre campos de idcnab e nosso numero e parâmetro
			// de bloqueio estiver ativo vai impedir a geração do bordero
			If (!Empty(AllTrim(SE1->E1_IDCNAB)) .Or. !Empty(AllTrim(SE1->E1_I_NUMBC))) .And. _lBloqCNAB
		
				_cTexto += "Prefixo.....: " + SE1->E1_PREFIXO + CRLF
				_cTexto += "Título......: " + SE1->E1_NUM + CRLF
				_cTexto += "Parcela.....: " + SE1->E1_PARCELA + CRLF
				_cTexto += "Tipo........: " + SE1->E1_TIPO + CRLF
				_cTexto += "" + CRLF

				// Retiro a marcaçao, para não incluir o registro no borderô
				TRB->( RecLock( "TRB" , .F. ) )
				TRB->E1_OK := " "
				TRB->( MSUnLock() )
						
			Else
			
				Begin Transaction

					//============================================================
					//procura se o cliente tem um banco padrão
					//============================================================
					_cPadrao := Posicione("SA1", 1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA, "A1_I_BOLE")
				
					If Empty(_cPadrao)
						
						If Len(_aBco) > 0 

							For _nOpc := 1 To Len(_aBco)
								If SubStr(_cPadrao,1,3) == _aBco[_nOpc][1] .Or. (Empty(_cPadrao) .And. Len(_aBco) = 1)
									_cBancoP 	:= 	AllTrim(_aBco[_nOpc][1])
									_cContaP 	:=	AllTrim(_aBco[_nOpc][2])
									_cSubcoP 	:=	AllTrim(_aBco[_nOpc][4])
									_cAgencP 	:= 	AllTrim(_aBco[_nOpc][3])
									_cOperP		:=	AllTrim(_aBco[_nOpc][5])
									Exit
								ElseIf AllTrim(_aBco[_nOpc][6]) == "S"
									_cBancoP 	:= 	AllTrim(_aBco[_nOpc][1])
									_cContaP 	:=	AllTrim(_aBco[_nOpc][2])
									_cSubcoP 	:=	AllTrim(_aBco[_nOpc][4])
									_cAgencP 	:= 	AllTrim(_aBco[_nOpc][3])
									_cOperP		:=	AllTrim(_aBco[_nOpc][5])
									Exit							
								EndIf
							Next _nOpc
						EndIf
					Else

						_nOpc := aScan(_aBco,{|_vAux|_vAux[1]== SubStr(_cPadrao,1,3) })

						If _nOpc > 0 

							_cBancoP :=	AllTrim(_aBco[_nOpc][1])
							_cContaP :=	AllTrim(_aBco[_nOpc][2])
							_cSubcoP :=	AllTrim(_aBco[_nOpc][4])
							_cAgencP :=	AllTrim(_aBco[_nOpc][3])
							_cOperP	 :=	AllTrim(_aBco[_nOpc][5])

						EndIf	

					EndIf
				
					_cPortado := IIf( Empty( SE1->E1_PORTADO )	, _cBancoP , SE1->E1_PORTADO	)
					_cAgencia := IIf( Empty( SE1->E1_AGEDEP )	, _cAgencP , SE1->E1_AGEDEP		)
					_cConta   := IIf( Empty( SE1->E1_CONTA ) 	, _cContaP , SE1->E1_CONTA		)	            

					If !(AllTrim(_cPortado) == AllTrim(ParamIXB[1]) .And. AllTrim(_cAgencia) == AllTrim(ParamIXB[2]) .And. AllTrim(_cConta) == AllTrim(ParamIXB[3]))
						// Retiro a marcaçao, para não incluir o registro no borderô
						TRB->( RecLock( "TRB" , .F. ) )
						TRB->E1_OK := " "
						TRB->( MSUnLock() )
					Else
						//Posiciona o SA6 (Bancos)
						DBSelectArea("SA6")
						SA6->( DBSetOrder(1) )
						SA6->( DBSeek(xFilial("SA6")+U_ITKEY(_cPortado, "A6_COD")+U_ITKEY(_cAgencia, "A6_AGENCIA")+U_ITKEY(_cConta, "A6_NUMCON")) )		

						//Posiciona o SA1 (Cliente)
						DBSelectArea("SA1")
						SA1->( DBSetOrder(1) )
						SA1->( DBSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA) )
						
						//Posiciona o SEE (Parametros banco)
						DBSelectArea("SEE")
						SEE->( DBSetOrder(1) )
						If SEE->( DBSeek(xFilial("SEE");
									+AllTrim(_cPortado)+Space(TamSX3("EE_CODIGO")[1]-Len(AllTrim(_cPortado)));
									+AllTrim(_cAgencia)+Space(TamSX3("EE_AGENCIA")[1]-Len(AllTrim(_cAgencia)));
									+AllTrim(_cConta)+Space(TamSX3("EE_CONTA")[1]-Len(AllTrim(_cConta)));
									+AllTrim(_cSubcoP) ) )
						
							_cNumFaixa := StrZero(Val(SEE->EE_FAXATU) + 1,10)		       
													
							While !MayIUseCode(_cPortado + _cAgencia + _cConta + xFilial("SEE") + _cNumFaixa)	//verifica se esta sendo usado na memoria
								_cNumFaixa := StrZero(Val(_cNumFaixa) + 1,10)							  		//busca o proximo numero disponivel 						
							EndDo  
											
							SEE->( RecLock( "SEE" , .F. ) )
								SEE->EE_FAXATU := _cNumFaixa
							SEE->( MSUnLock() )
						EndIf
						
						_aDadosBanco	:= {	SA6->A6_COD																									,; 	//Numero do Banco
												Left( SA6->A6_NOME , AT("-",SA6->A6_NOME)-1 )																,; 	//Nome do Banco
												IIf( SA6->A6_COD=="479" , StrZero(Val(AllTrim(SEE->EE_AGBOSTO)),7),u_agencia(SA6->A6_COD,SA6->A6_AGENCIA))	,; 	//Agência
												IIf( SA6->A6_COD=="479" , AllTrim(SEE->EE_CODEMP), u_conta(SA6->A6_COD,SA6->A6_NUMCON) )						,; 	//Conta Corrente
												IIf( SA6->A6_COD $ "479/033" , "" ,SubStr( AllTrim(SA6->A6_NUMCON) ,Len(AllTrim(SA6->A6_NUMCON)) , 1 ) )	,; 	//Dígito da conta corrente
												AllTrim(SEE->EE_I_CARTE)																					,; 	//Carteira
												0																											 }	//VARIACAO //AllTrim(SEE->EE_VARIACA)}
								
						_aDatSacado	:= {	AllTrim( SA1->A1_NOME )						,; //Razão Social
											AllTrim( SA1->A1_COD )						,; //Código
											AllTrim( SA1->A1_END )+"-"+SA1->A1_BAIRRO	,; //Endereço
											AllTrim( SA1->A1_MUN )						,; //Cidade
											SA1->A1_EST									,; //Estado
											SA1->A1_CEP									 } //CEP
						
						_nVlrAbat	:= SomaAbat( SE1->E1_PREFIXO , SE1->E1_NUM , SE1->E1_PARCELA , "R" , 1 ,, SE1->E1_CLIENTE , SE1->E1_LOJA )
						
						_CB_RN_NN	:= u_Ret_cBarra(Subs(_aDadosBanco[1],1,3)+"9",;
													Subs(_aDadosBanco[3],1,4),;
													_aDadosBanco[4],;
													_aDadosBanco[5],;                                                     
													_aDadosBanco[6],;
													AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA),;
													(SE1->E1_SALDO-_nVlrAbat),;
													SE1->E1_VENCTO,;
													SEE->EE_CODEMP,;
													_cNumFaixa,;
													IIf(SE1->E1_DECRESC > 0,.T.,.F.),;
													SE1->E1_PARCELA)
						
						//Gravo o desbloqueio do título
						RecLock("SE1",.F.)
							//SE1->E1_NUMBCO	:= StrTran(StrTran(_CB_RN_NN[3],"/",""),"-","")	//GRAVA NOSSO NUMERO NO TITULO
							//SE1->E1_I_NUMBC	:= StrTran(StrTran(_CB_RN_NN[3],"/",""),"-","")	//GRAVA NOSSO NUMERO NO TITULO BKP
							SE1->E1_NUMBCO	:= StrTran(StrTran(_CB_RN_NN[4],"/",""),"-","")  //GRAVA NOSSO NUMERO NO TITULO
							SE1->E1_I_NUMBC	:= SE1->E1_NUMBCO //GRAVA NOSSO NUMERO NO TITULO BKP
						MSUnLock()
					EndIf

				End Transaction
		  	EndIf
		Else
			If !(AllTrim(SE1->E1_I_ULBCO) == AllTrim(ParamIXB[1]) .And. AllTrim(SE1->E1_I_ULAGE) == AllTrim(ParamIXB[2]) .And. AllTrim(SE1->E1_I_ULCTA) == AllTrim(ParamIXB[3]))
				// Retiro a marcaçao, para não incluir o registro no borderô
				TRB->( RecLock( "TRB" , .F. ) )
				TRB->E1_OK := " "
				TRB->( MSUnLock() )
			EndIf
		EndIf
	EndIf

	TRB->( DBSkip() )
End

If !Empty(_cTexto)
	_cAux := "LOG DE INCLUSÃO - BORDERÔ" + CRLF
	_cAux += "====================================================" + CRLF
	_cAux += "" + CRLF
	_cAux += "Os títulos selecionados, aparentemente já foram enviados para o banco e estão com problemas, estes registros estão sendo bloqueados." + CRLF
	_cAux += "Para desbloquear os títulos, acesse a rotina Desbloqueio Cnab em Atualizações / Específico Italac." + CRLF
	_cAux += "" + CRLF
	_cTexto := _cAux + _cTexto + CRLF
	
	fLog(_cTexto)
EndIf

FWRestArea(_aAreaSE1)
FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: fLog
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 16/11/2016
Descrição---------: Função criada para impressão de log, ao final da validação da seleção dos títulos
Parametros--------: _cTexto - Texto a ser mostrado em uma janela de log
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fLog(_cTexto)

Local _cFile	:= ""
Local _cMask	:= "Arquivos Texto" + "(*.TXT)|*.txt|"
Local _oDlg		:= NIL
Local _oFont	:= NIL
Local _oMemo	:= NIL

Define Font _oFont Name "Mono AS" Size 5, 12

Define MsDialog _oDlg Title "Atualizacao concluida." From 3, 0 to 340, 417 Pixel

@ 5, 5 Get _oMemo Var _cTexto Memo Size 200, 145 Of _oDlg Pixel 
_oMemo:bRClicked := { || AllwaysTrue() }
_oMemo:oFont     := _oFont

Define SButton From 153, 175 Type  1 Action _oDlg:End() Enable Of _oDlg Pixel // Apaga
Define SButton From 153, 145 Type 13 Action ( _cFile := tFileDialog( _cMask , "Selecione o Diretorio de Destino:" ,,,, GETF_RETDIRECTORY+GETF_LOCALHARD ), If( _cFile == "", .T., ;
MemoWrite( _cFile, _cTexto ) ) ) Enable Of _oDlg Pixel

Activate MsDialog _oDlg Center

Return
