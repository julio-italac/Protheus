#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

Static _lAltCodTab := .F.
Static _aBloqSA1 := {}  // Array Static para guardar informações de bloqueio por desconto contratual.
Static _aCNPJ := {}

/*
===============================================================================================================================
Programa----------: CRMA980
Autor-------------: Igor Melgaço
Data da Criacao---: 24/08/2021
Descrição---------: Ponto de entrada MVC CRMA980 que substitui mata030.
Parametros--------: Nenhum
Retorno-----------: lRet 
===============================================================================================================================
*/
User Function CRMA980()
	Local aParam := ParamIXB
	Local xRet := .T.
	Local oObj := ""
	Local cIdPonto := ""
	Local cIdModel := ""
	Local lIsGrid := .F.
	Local _oModel := FWModelActive()
	Local _oModelSA1
	Local _cVend1,_cVend2,_cVend3,_cVend4
	Local _aListaVend, _cEnvWorkF, _cNomeGrupo
	Local _cNomVendA, _cNomVendB, _cGrpVend
	Local _nOperation, _cDescCont
	Local _cBloq, _cBloqDesc

	Local _cUfMVA := U_ITGetMV("IT_UFSMVA","PR")
	Local _cTRIBMVA
	Local _nLimCTela
	Local _nLimeteAp

	If aParam <> NIL
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid := (Len(aParam) > 3)

		If cIdPonto == "MODELPOS" //"Chamada na validação total do modelo."

		ElseIf cIdPonto == "FORMPOS" //"Chamada na validação total do formulário."

			_oModelSA1  := _oModel:GetModel('SA1MASTER')

			xRet := CRMA980TOK(_oModelSA1)

			_nOperation := _oModel:GetOperation()

			//==================================================================
			// Valida permissão do usuário para incluir ou alterar um cliente.
			// Tendo como base o limite de crédito no cadastro de usuários.
			//==================================================================
			If ! FWIsInCallStack("U_GP010VALPE") .And. ! FWIsInCallStack("IMPORTAFUN") .And. ! FWIsInCallStack("U_IMPCLI") .And. ! FWIsInCallStack("MOMS003L") .And. ! FWIsInCallStack("MOMS055I")
				_nLimCTela := _oModelSA1:GetValue("A1_LC")
				_nLimeteAp := Posicione("ZZL",3,xFilial("ZZL")+AllTrim(__cUserId),"ZZL_VLMAXP") // ZZL_FILIAL+ZZL_CODUSU
				If ValType(_nLimeteAp) <> "N"
					_nLimeteAp := 0
				EndIf

				If _nOperation == MODEL_OPERATION_INSERT .And. xRet
					If _nLimCTela > _nLimeteAp
						U_ITMsg("O Valor do limite de crédito deste cliente: " + AllTrim(Str(_nLimCTela,14,2)) + ", é superior ao limite permitido para este usuário incluir o cliente: " + AllTrim(Str(_nLimeteAp,14,2))+".","Atenção","",1)
						xRet := .F.
					EndIf
				EndIf

				If _nOperation == MODEL_OPERATION_UPDATE .And. xRet
					If _nLimCTela <> SA1->A1_LC
						If _nLimCTela > _nLimeteAp
							U_ITMsg("O Valor do limite de crédito deste cliente: " + AllTrim(Str(_nLimCTela,14,2)) + ", é superior ao limite permitido para este usuário alterar o cliente: " + AllTrim(Str(_nLimeteAp,14,2))+".","Atenção","",1)
							_lRet := .F.
						EndIf
					EndIf
				EndIf
			EndIf

			//=============================================================================
			// Demais validações da Rotina de manutenção de clientes em MVC
			//=============================================================================
			If xRet .And. _nOperation == MODEL_OPERATION_UPDATE //_oModelSA1:IsUpdated()
				_cVend1   := _oModelSA1:GetValue("A1_VEND")
				_cVend2   := _oModelSA1:GetValue("A1_I_VEND2")
				_cVend3   := _oModelSA1:GetValue("A1_I_VEND3")
				_cVend4   := _oModelSA1:GetValue("A1_I_VEND4")
				_cGrpVend := _oModelSA1:GetValue("A1_GRPVEN")
				//===================================================================================
				// Verifica se houve alterações nos Vendedores para envio de Workflow para o
				// Responsável.
				//===================================================================================
				If (_cVend1 <> SA1->A1_VEND ;
						.Or. _cVend2 <> SA1->A1_I_VEND2;
						.Or. _cVend3 <> SA1->A1_I_VEND3;
						.Or. _cVend4 <> SA1->A1_I_VEND4)

					_aListaVend := {}

					_cEnvWorkF  := Posicione("ACY",1,xFilial("ACY")+_cGrpVend,"ACY_I_ALTV") // 1 = ACY_FILIAL+ACY_GRPVEN
					_cNomeGrupo := Posicione("ACY",1,xFilial("ACY")+_cGrpVend,"ACY_DESCRI")

					If _cEnvWorkF == "S"

						If _cVend1 <> SA1->A1_VEND
							_cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_NOME")
							_cNomVendB := Posicione("SA3",1,xFilial("SA3")+_cVend1,"A3_NOME")
							aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_VEND,_cNomVendA,_cVend1,_cNomVendB,"Vendedor1"})
						EndIf

						If _cVend2 <> SA1->A1_I_VEND2
							_cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND2,"A3_NOME")
							_cNomVendB := Posicione("SA3",1,xFilial("SA3")+_cVend2,"A3_NOME")
							aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND2,_cNomVendA,_cVend2,_cNomVendB,"Vendedor2"})
						EndIf

						If _cVend3 <> SA1->A1_I_VEND3
							_cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND3,"A3_NOME")
							_cNomVendB := Posicione("SA3",1,xFilial("SA3")+_cVend3,"A3_NOME")
							aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND3,_cNomVendA,_cVend3,_cNomVendB,"Vendedor3"})
						EndIf

						If _cVend4 <> SA1->A1_I_VEND4
							_cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND4,"A3_NOME")
							_cNomVendB := Posicione("SA3",1,xFilial("SA3")+_cVend4,"A3_NOME")
							aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND4,_cNomVendA,_cVend4,_cNomVendB,"Vendedor4"})
						EndIf

						U_CRMA980X(_aListaVend)

					EndIf
				EndIf
			EndIf

			//===================================================================================
			// Realiza bloqueio de Cliente por desconto contratual. Chamado 30177.
			//===================================================================================
			If xRet .And. (_nOperation == MODEL_OPERATION_UPDATE .Or. _nOperation == MODEL_OPERATION_INSERT)

				_cGrpVend  := _oModelSA1:GetValue("A1_GRPVEN")
				_cDescCont := Posicione("ACY",1,xFilial("ACY")+_cGrpVend,"ACY_I_DESC") // ACY_FILIAL+ACY_GRPVEN

				_cBloq     := _oModelSA1:GetValue("A1_MSBLQL")
				_cBloqDesc := _oModelSA1:GetValue("A1_I_BLQDC")
				_aBloqSA1  := {.F.,;          // Bloqueio por contrato
				_cBloq,;        // Bloqueio por Cliente
				_cBloqDesc}     // Bloqueio Contrato

				If (AllTrim(_cDescCont) == "S" .And. _nOperation == MODEL_OPERATION_INSERT) .Or. (_nOperation == MODEL_OPERATION_UPDATE .And. _cGrpVend <> SA1->A1_GRPVEN .And. AllTrim(_cDescCont) == "S")

					// If AllTrim(_cDescCont) == "S"

					If U_ITMsg("O grupo de cliente informado para este cliente possui uma regra de desconto contratual preexistente,"+;
							" ao confirmar este cadastro o mesmo será bloqueado para análise do setor de contratos. "+ CRLF +;
							" Deseja prosseguir?", "Atenção", "",2,2,2) // 3,2,2

						_aBloqSA1 := {.T.,;     // Bloqueio por contrato
						"1",;     // Bloqueio por Cliente
						"1"}      // Bloqueio Contrato

					Else
						_aBloqSA1 := {.F.,;          // Bloqueio por contrato
						"",;   //M->A1_MSBLQL,; // Bloqueio por Cliente
						""}    //M->A1_I_BLQDC} // Bloqueio Contrato

						xRet := .F.
					EndIf
				EndIf
			EndIf

			If xRet .And. (_nOperation == MODEL_OPERATION_UPDATE .Or. _nOperation == MODEL_OPERATION_INSERT) .And. !IsInCallStack("U_MOMS003") .And. ! FWIsInCallStack("IMPORTAFUN") .And. ! FWIsInCallStack("U_IMPCLI") .And. ! FWIsInCallStack("MOMS003L") .And. ! FWIsInCallStack("MOMS055I") .AND. !FWIsInCallStack("U_GP010VALPE") .And. !FWIsInCallStack("U_GP265VALPE")
				xRet := U_CRMA980REP(_oModelSA1:GetValue("A1_CGC"),_oModelSA1:GetValue("A1_COND"),_oModelSA1:GetValue("A1_GRPVEN"),_oModelSA1:GetValue("A1_I_NGRPC"))
			EndIf

		ElseIf cIdPonto == "FORMLINEPRE" //"Chamada na pré validação da linha do formulário. "

		ElseIf cIdPonto == "FORMLINEPOS" //"Chamada na validação da linha do formulário."

		ElseIf cIdPonto == "MODELCOMMITTTS" //"Chamada após a gravação total do modelo e dentro da transação."
			If oObj:GetOperation() == MODEL_OPERATION_UPDATE//ALTERACAO
				CRMA980MC()
				CRMA980PT(aParam)
				U_CRMA980CON()
				U_CRMA980A(M->A1_COND,M->A1_GRPVEN,M->A1_I_NGRPC) // Ajuste para replicar A1_COND e A1_GRPVEN entre clientes com mesma base de CNPJ. Chamado 51346.
				Return .T.
			ElseIf oObj:GetOperation() == MODEL_OPERATION_INSERT//INCLUSAO
				CRMA980INC()
				U_CRMA980CON()
				U_CRMA980A(M->A1_COND,M->A1_GRPVEN,M->A1_I_NGRPC) // Ajuste para replicar A1_COND e A1_GRPVEN entre clientes com mesma base de CNPJ. Chamado 51346.
				Return .T.
			EndIf

		ElseIf cIdPonto == "MODELCOMMITNTTS" //"Chamada apos a gravacao total do modelo e fora da transacao."
			//=======================================================================
			// Verifica se as validações da rotina de desconto contratual se
			// deve bloquear o Cliente. Caso afirmativo bloqueia o cliente por
			// Desconto Contratual.
			//=======================================================================
			If _aBloqSA1[1]   // Bloqueia SA1 por Desconto Contratual = True or False
				SA1->(RecLock("SA1",.F.))
				//SA1->A1_MSBLQL  := "1" // Bloqueio por Cliente
				SA1->A1_I_BLQDC := "1"
				SA1->(MSUnLock())
				//==================================================================
				// Envia Workflow de bloqueio de clientes por desconto contratual.
				//==================================================================
				U_CRMA980Y()

			EndIf

			//=====================================================================
			// Para os clientes que não são dos estados "AM-RR-AP" gravar os campos
			// suframa com: A1_CALCSUF = "N" e A1_SUFRAMA = " ".
			//=====================================================================
			If ! (SA1->A1_EST $ "AM-RR-AP-AC-RO")
				SA1->(RecLock("SA1",.F.))
				SA1->A1_CALCSUF := "N"
				SA1->A1_SUFRAMA := " "
				SA1->(MSUnLock())
			EndIf

			//=====================================================================
			// Para os clientes que são funcionários, gravar tipo e seguimento
			// como consumidor final.
			//=====================================================================
			If SA1->A1_CLIFUN == "1"
				SA1->(RecLock("SA1",.F.))
				SA1->A1_TIPO    := "F"  //  Tipo = Consumidor Final
				SA1->A1_I_GRCLI := "39" //  Seguimento = Consumidor Final
				SA1->(MSUnLock())
			EndIf

			//=====================================================================
			// Para os clientes do Paraná optantes pelo Simples Nacional grava
			// grava o campo Grupo Tributário com "023", para obterem benefícios.
			//=====================================================================
			If SA1->A1_EST $ _cUfMVA .And. SA1->A1_SIMPNAC == "1" // 1=Sim;2=Não
				SA1->(RecLock("SA1",.F.))
				SA1->A1_GRPTRIB := _cTRIBMVA //"023" //  Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
				SA1->(MSUnLock())
			Else
				If SA1->A1_GRPTRIB == _cTRIBMVA
					SA1->(RecLock("SA1",.F.))
					SA1->A1_GRPTRIB := " "
					SA1->(MSUnLock())
				EndIf
			EndIf

		ElseIf cIdPonto == "FORMCOMMITTTSPRE" //"Chamada após a gravação da tabela do formulário."

		ElseIf cIdPonto == "FORMCOMMITTTSPOS" //"Chamada após a gravação da tabela do formulário."

		ElseIf cIdPonto == "MODELCANCEL"

		ElseIf cIdPonto == "BUTTONBAR"
			xRet := CRMA980BUT(aParam)
		EndIf
	EndIf

Return xRet

/*
===============================================================================================================================
Programa----------: CRMA980MC
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Ponto de entrada para gravar os dados do cadastro do Cliente após a alteração. 
                    Substituiu o MALTCLI do mata030.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CRMA980MC()

	Local _aArea	:= FWGetArea()
	Local _cCodUsr	:= RetCodUsr()
	Local _cConta	:= ''

//================================================================================
//| Verifica se o LOG de Alterações está ativo e chama a ggravação do LOG        |
//================================================================================
	If Type("_aITASA1") == "A" .And. !Empty(_aITASA1)
		U_ITGrvLog( _aITASA1 , "SA1" , 1 , SA1->( A1_FILIAL + A1_COD + A1_LOJA ) , "A" , _cCodUsr )
	EndIf

	_aITASA1 := {}

	FWRestArea( _aArea )

//====================================================================================================
// Verifica a configuração do cadastro para ajustar a conta contábil
//====================================================================================================
	Do Case

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'AM' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069992'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RS' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069993'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'MG' .And. SA1->A1_PESSOA == 'F' .And. SA1->A1_COD_MUN == '69307' //Três Corações
		_cConta := '1102069995'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'SP' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069996'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST $ 'MG/GO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069998'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069999'

	EndCase

	If !Empty( _cConta ) .And. _cConta <> SA1->A1_CONTA

		RecLock( 'SA1' , .F. )
		SA1->A1_CONTA := _cConta
		SA1->( MSUnLock() )

	EndIf

Return

/*
===============================================================================================================================
Programa----------: CRMA980PT
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Ponto de entrada executado para validação após confirmação da alteração do cliente
                    Substitui o M030PALT.
Parametros--------: ParamIXB[1] - nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CRMA980PT(aParam)

	Local _aArea	:= FWGetArea()
	Local _nOpcao	:= aParam[1]
	Local _lRet	 	:= .T.
	Local _lMashup	:= U_ItGetMV("IT_MASHUP",.F.)
	Local _lLibMas	:= .F.
	Local _nQtdDia	:= Val(SA1->A1_I_PEREX)
	Local _nQtdiaT	:= dDataBase - SA1->A1_I_DTEXE
	Local _lExec	:= IIf(_nQtdDia > _nQtdiaT, .T., .F.)

	Begin Sequence
		If _nOpcao == 1
			//===================================================================================
			// Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
			//===================================================================================
			U_AOMS076G()

			//===================================================================================
			// Rotina de Mashup
			//===================================================================================
			If _lMashup
				If SA1->A1_PESSOA <> "F"
					_cUser := RetCodUsr()

					DBSelectArea("ZZL")
					ZZL->( DBSetOrder(3) )
					If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
						If ZZL->ZZL_LIBMAS == "S"
							_lLibMas := .T.
						EndIf
					EndIf

					If !_lLibMas
						If (AllTrim(SA1->A1_I_SITRF) <> "ATIVO" .And. AllTrim(SA1->A1_I_SITRF) <> "REGULAR" .And. AllTrim(SA1->A1_I_SITRF) <> "APTO" .And. AllTrim(SA1->A1_I_SITRF) <> "ATIVA") .Or. _lExec
							If !(AllTrim(SA1->A1_I_NUM) $ SA1->A1_END)
								RecLock("SA1", .F.)
								If !Empty(SA1->A1_I_END) .And. Empty(SA1->A1_I_NUM) .And. Empty(SA1->A1_COMPLEM)
									SA1->A1_END := AllTrim(SA1->A1_I_END)
								ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM) .And. Empty(SA1->A1_COMPLEM)
									SA1->A1_END := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM)
								ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM) .And. !Empty(SA1->A1_COMPLEM)
									SA1->A1_END := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM) + " " + AllTrim(SA1->A1_COMPLEM)
								EndIf
							EndIf
							SA1->A1_I_DTEXE := dDataBase
							SA1->(MSUnLock())
						EndIf
					EndIf
				EndIf
			EndIf
			U_AOMS076G()
		EndIf
	End Sequence

	If !Empty(SA1->A1_INSCR)
		RecLock("SA1", .F.)
		SA1->A1_INSCR := AllTrim(StrTran(SA1->A1_INSCR,"-",""))
		MSUnLock()
	EndIf

	If _lAltCodTab
		SA1->(RecLock("SA1", .F.))
		SA1->A1_TABELA := "" // Cliente alterado simples nacional = NÃO, deve limpar o codigo da tabela de preços simples nacional.
		SA1->(MSUnLock())

		_lAltCodTab := .F.
	EndIf

	FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: CRMA980PTB
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Determina se o campo A1_TABELA será alterado após a gravação.
                    Substitui o M30PALTAB do Fonte MA030TOK.
Parametros--------: _lAltTabela = .T./.F.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CRMA980PTB(_lAltTabela)

	Begin Sequence
		If _lAltTabela
			_lAltCodTab := .T.
		Else
			_lAltCodTab := .F.
		EndIf
	End Sequence

Return

/*
===============================================================================================================================
Programa----------: CRMA980INC
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Ponto de entrada para gravar os dados do cadastro do Cliente após a inclusão.
                    Substitui o M030INC.
Parametros--------: ParamIXB -> Numérico -> Tipo da operação do usuário. Conteúdo 3 significa que o usuário cancelou a inclusão.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CRMA980INC()

	Local _aArea	:= FWGetArea()
	Local _cConta	:= ''
	Local _cEnd		:= ''

	Local _lMashup	:= U_ItGetMV("IT_MASHUP",.F.)

	Local _nQtdDia	:= 0
	Local _nQtdiaT	:= 0
	Local _lExec	:= .F.

	Local _lLibMas	:= .F.

//====================================================================================================
// Verifica a configuração do cadastro para ajustar a conta contábil
//====================================================================================================
	Do Case

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'AM' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069992'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RS' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069993'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'MG' .And. SA1->A1_PESSOA == 'F' .And. SA1->A1_COD_MUN == '69307' //Três Corações
		_cConta := '1102069995'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'SP' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069996'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST $ 'MG/GO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069998'

	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069999'

	EndCase

	If !Empty( _cConta ) .And. _cConta <> SA1->A1_CONTA

		RecLock( 'SA1' , .F. )
		SA1->A1_CONTA := _cConta
		SA1->( MSUnLock() )

	EndIf

//===================================================================================
// Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
//===================================================================================
	If Type("M->A1_COD") <> "U" // Indica que foi confirmado uma inclusão.
		U_AOMS076G()
	EndIf

//================================================================================
// Cria item contábil para o novo fornecedor
//================================================================================
	CTD->(DBSetOrder(1))

	If .not. CTD->(DBSeek(xFilial("CTD")+"SA1"+ AllTrim(SA1->A1_COD)))

		RecLock("CTD", .T.)

		CTD->CTD_ITEM := "SA1" + AllTrim(SA1->A1_COD)
		CTD->CTD_DESC01 := SA1->A1_NOME
		CTD->CTD_BLOQ :=  "2"
		CTD->CTD_DTEXIS := SToD("19800101")
		CTD->CTD_ITLP := "SA2" + AllTrim(SA1->A1_COD)
		CTD->CTD_CLOBRG := "2"
		CTD->CTD_ACCLVL := "1"
		CTD->CTD_CLASSE := "2"

		MSUnLock()

	EndIf

	If _lMashup

		_cUser := RetCodUsr()

		DBSelectArea("ZZL")
		ZZL->( DBSetOrder(3) )
		If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
			If ZZL->ZZL_LIBMAS == "S"
				_lLibMas := .T.
			EndIf
		EndIf

		If SA1->A1_PESSOA <> "F"
			_nQtdDia	:= Val(SA1->A1_I_PEREX)
			_nQtdiaT	:= IIf(Empty(M->A1_I_DTEXE),0,dDataBase - M->A1_I_DTEXE)
			_lExec		:= IIf(_nQtdiaT > _nQtdDia, .T., .F.)
			If !_lLibMas .Or. _lExec
				If IsInCallStack("MA030Trans")
					If !Empty(SA1->A1_I_END) .And. Empty(SA1->A1_I_NUM)
						_cEnd := AllTrim(SA1->A1_I_END)
					ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM)
						_cEnd := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM)
					EndIf

					RecLock("SA1", .F.)
					SA1->A1_END		:= _cEnd
					SA1->A1_I_DTEXE	:= Date()
					SA1->(MSUnLock())
				EndIf
			Else
				RecLock("SA1", .F.)
				SA1->A1_I_DTEXE := Date()
				SA1->(MSUnLock())
			EndIf
		EndIf
	EndIf

	FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: CRMA980TOK
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Validações no cadastro de Clientes. Substitui o MA030TOK.
Parametros--------: Nenhum
Retorno-----------: Lógico com exibição de mensagens para tratativa das negativas
===============================================================================================================================
*/
Static Function CRMA980TOK(_oModelSA1)
	Local _aParam    := ParamIXB
	Local _oObj
	Local _aArea	:= FWGetArea()
	Local _cAlias	:= GetNextAlias()
	Local _cQuery	:= ""
	Local _cUser	:= ""
	Local _cCodigo	:= ""
	Local _cTxtAux	:= ""
	Local _lRet		:= .T.

	Local _lMashup	:= U_ItGetMV("IT_MASHUP",.F.)
	Local _lLibMas	:= .F.

	Local _nQtdDia	:= Val(M->A1_I_PEREX)
	Local _nQtdiaT	:= IIf(Empty(M->A1_I_DTEXE),0,dDataBase - M->A1_I_DTEXE)
	Local _lExec	:= IIf(_nQtdiaT > _nQtdDia, .T., .F.)

	Local _cVendGen := U_ITGetMV("IT_VENDGEN","000156")
	Local _cGrpGen  := U_ITGetMV("IT_GRPGEN","11")

	Local _cA1_NOME    := ""
	Local _cA1_END     := ""
	Local _cA1_BAIRRO  := ""
	Local _cA1_ENDCOB  := ""
	Local _cA1_ENDREC  := ""
	Local _cA1_ENDENT  := ""
	Local _cA1_BAIRROE := ""

	Private _cMensagem	:= ""
	Private _lAuto		:= FunName() == "MOMS003"
	Private _lVarLog	:= Type("_aLogM003") == "A"

	_oObj := _aParam[1]

	If _oObj:GetOperation() == MODEL_OPERATION_INSERT

		//================================================================================
		// Validação do código de Cliente gerado automaticamente
		//================================================================================
		_cQuery := " SELECT MAX(A1_COD) AS CODIGO "
		_cQuery += " FROM "+ RetSqlName( 'SA1' )
		_cQuery += " WHERE D_E_L_E_T_ = ' ' "

		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

		DBSelectArea( _cAlias )
		(_cAlias)->( DBGoTop() )
		If (_cAlias)->( !Eof() )
			_cCodigo := (_cAlias)->CODIGO
		Else
			_cCodigo := StrZero( 0 , TamSX3("A1_COD")[01] )
		EndIf

		(_cAlias)->( DBCloseArea() )

		If _cCodigo == M->A1_COD

			//Verifica se existe o codigo do cliente com a mesma loja ja cadastrado.
			_cQry := " SELECT COUNT(*) AS CONTADOR "
			_cQry += " FROM " + RetSqlName("SA1") + " "
			_cQry += " WHERE A1_COD = '" + M->A1_COD + "' "
			_cQry += "   AND A1_LOJA = '" + M->A1_LOJA + "' "

			DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBCLI" , .T. , .F. )

			DBSelectArea("TRBCLI")
			TRBCLI->(DBGoTop())

			If TRBCLI->CONTADOR <> 0

				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O código de cliente: " + M->A1_COD + " e Loja: " + M->A1_LOJA + " já existe." } )
					EndIf
				Else
					U_ITMsg("Este código de cliente já está em uso!","Validação Código","Favor digitar novamente o CPF/CNPJ.",1)
				EndIf

				_lRet := .F.

			EndIf

			DBSelectArea("TRBCLI")
			TRBCLI->(DBCloseArea())

		EndIf

		DBSelectArea( 'SA1' )
		SA1->( DBSetOrder (3) )
		If SA1->( DBSeek( xFilial("SA1") + M->A1_CGC ) )

			_cUser := RetCodUsr()

			DBSelectArea("ZZL")
			ZZL->( DBSetOrder(3) )
			If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )

				If ZZL->ZZL_INCCLI <> 'S'

					If _lAuto
						If _lVarLog
							aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O usuário: " + Capital( UsrFullName( _cUser ) ) + " não tem permissão para incluir cliente que já possui cadastro com o mesmo CPF/CNPJ" } )
						EndIf
					Else
						U_ITMsg("O usuário "+ Capital( UsrFullName( _cUser ) ) +" não tem permissão para incluir um cliente que já possui cadastro com o mesmo CPF/CNPJ.",;
							"Validação usuário",;
							"Informar a área de TI/ERP solicitando a liberação!",1)
					EndIf

					_lRet := .F.

				EndIf

			Else

				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O usuário: " + Capital( UsrFullName( _cUser ) ) + " não tem permissão para incluir cliente que já possui cadastro com o mesmo CPF/CNPJ" } )
					EndIf
				Else
					U_ITMsg("O usuário "+ Capital( UsrFullName( _cUser ) ) +" não tem permissão para incluir um cliente que já possui cadastro com o mesmo CPF/CNPJ.",;
						"Validação usuário",;
						"Informar a área de TI/ERP solicitando a liberação!",1)
				EndIf

				_lRet := .F.

			EndIf

		EndIf

		If _lRet .And. !IsInCallStack("U_AOMS014")
			_lRet := CRMA980RIS()
		EndIf

	EndIf

	If _oObj:GetOperation() == MODEL_OPERATION_INSERT .Or. _oObj:GetOperation() == MODEL_OPERATION_UPDATE


		//================================================================================
		// Validação do preenchimento do campo de e-mail. Rotina automatica não deve mostrar
		//================================================================================
		If !IsInCallStack("U_GP010VALPE") .And. !IsInCallStack("U_GP265VALPE")
			If Empty( M->A1_EMAIL ) .And. ( FunName() <> "MOMS003" ) .And. FUNNAME() <> "GPEA010"

				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo E-Mail não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ". Não cadastre endereços genéricos." } )
					EndIf
				Else
					U_ITMsg('O campo "e-mail" não foi preenchido, esse campo não é obrigatório mas deve ser preenchido com um endereço válido!',;
						'Validação Email','Não cadastre endereços genéricos como "funcionarios@italac.com.br" ou nfe@italac.com.br', 3)
				EndIf

			EndIf

			If Empty(M->A1_INSCR) .And. ( FunName() <> "MOMS003" ) .And. ( FunName() <> "GPEA010" )


				U_ITMsg('Preencher como ISENTO quando For dispensado de IE e deixar em branco quando For não contribuinte do ICMS.  ',;
					'Atenção','Dúvidas procurar departamento FISCAL.',2)

			EndIf

		EndIf

		_cTxtAux := LTrim( StrTran( M->A1_NOME , '	' , '' ) )

		If _cTxtAux <> M->A1_NOME

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Nome não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + "." } )
				EndIf
			Else
				U_ITMsg("Erro no preenchimento do campo Nome!","Validação de Nome","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
			EndIf

			_lRet := .F.
		EndIf

		_cTxtAux := LTrim( StrTran( M->A1_END , '	' , '' ) )

		If _cTxtAux <> M->A1_END

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Endereço não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
				EndIf
			Else
				U_ITMsg("Erro no preenchimento do campo Endereço!","Validação de endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
			EndIf

			_lRet := .F.
		EndIf

		_cTxtAux := LTrim( StrTran( M->A1_BAIRRO , '	' , "" ) )

		If _cTxtAux <> M->A1_BAIRRO

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Bairro não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
				EndIf
			Else
				U_ITMsg("Erro no preenchimento do campo Endereço!","Validação de endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
			EndIf

			_lRet := .F.
		EndIf

		_cTxtAux := LTrim( StrTran( M->A1_COMPLEM , '	' , "" ) )

		If M->A1_COMPLEM <> ' ' .And. _cTxtAux <> M->A1_COMPLEM

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Complemento não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
				EndIf
			Else
				U_ITMsg("Erro no preenchimento do campo Complemento do Endereço!","Validação Endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
			EndIf

			_lRet := .F.
		EndIf

		_cTxtAux := LTrim( StrTran( M->A1_INSCR , '	' , "" ) )

		If _cTxtAux <> AllTrim(M->A1_INSCR)

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Inscrição Estadual não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
				EndIf
			Else
				U_ITMsg("Erro no preenchimento do campo Inscrição Estadual!","Validação de inscrição estadual","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
			EndIf

			_lRet := .F.
		EndIf

		If _lRet .And. !IsInCallStack("U_AOMS014")
			_lRet := CRMA980RIS()
		EndIf

		//================================================================================
		// Validação da sitação cadastral do cliente, conforme retorno no mashups
		//================================================================================
		If _lMashup
			If M->A1_PESSOA <> "F" .And. M->A1_COD <> "000001"
				_cUser := RetCodUsr()

				DBSelectArea("ZZL")
				ZZL->( DBSetOrder(3) )
				If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
					If ZZL->ZZL_LIBMAS == "S"
						_lLibMas := .T.
					EndIf
				EndIf

				If !_lLibMas
					If _oObj:GetOperation() == MODEL_OPERATION_INSERT
						If (AllTrim(M->A1_I_SITRF) <> "ATIVO" .And. AllTrim(M->A1_I_SITRF) <> "REGULAR" .And. AllTrim(M->A1_I_SITRF) <> "APTO" .And. AllTrim(M->A1_I_SITRF) <> "ATIVA") .Or. _lExec
							If _lExec
								_lRet := .F.
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal devido a periodicidade de consulta. A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' } )
								Else
									U_ITMsg( "É necessário realizar a consulta deste cadastro na Receita Federal devido a periodicidade de consulta.","Validação Mashup","A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.",1 )
								EndIf
							Else
								_lRet := .F.
								If Empty(M->A1_I_SITRF)
									If IsInCallStack("U_MOMS003")
										aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' } )
									Else
										U_ITMsg( "É necessário realizar a consulta deste cadastro na Receita Federal e se 'Jurídico' no Sintegra também.","Validação Mashup","A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.",1 )
									EndIf
								Else
									If IsInCallStack("U_MOMS003")
										aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Não é possível concluir a criação do cadastro de cliente, devido o status deste Fornecedor na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' } )
									Else
										U_ITMsg( 'Não é possível concluir o cadastro deste cliente, devido seu status na Receita Federal estar como [' + AllTrim(M->A1_I_SITRF) + '].' , "Validação Mashup",,1 )
									EndIf
								EndIf
							EndIf
						EndIf
					ElseIf _oObj:GetOperation() == MODEL_OPERATION_UPDATE
						If (AllTrim(A1_I_SITRF) <> "ATIVO" .And. AllTrim(A1_I_SITRF) <> "REGULAR" .And. AllTrim(A1_I_SITRF) <> "APTO" .And. AllTrim(A1_I_SITRF) <> "ATIVA") .Or. _lExec
							If _lExec
								_lRet := .F.
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal devido a periodicidade de consulta. A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' } )
								Else
									U_ITMsg( 'É necessário realizar a consulta deste cadastro na Receita Federal devido a periodicidade de consulta.',"Validação Mashup",'A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' , 1)
								EndIf
							Else
								_lRet := .F.
								If Empty(A1_I_SITRF)
									If IsInCallStack("U_MOMS003")
										aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' } )
									Else
										U_ITMsg( 'É necessário realizar a consulta deste cadastro na Receita Federal e se "Jurídico" no Sintegra também.',"Validação Mashup",'A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' , 1 )
									EndIf
								Else
									If IsInCallStack("U_MOMS003")
										aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Não é possível concluir a criação do cadastro de cliente, devido o status deste Fornecedor na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' } )
									Else
										U_ITMsg( 'Não é possível concluir o cadastro deste cliente, devido seu status na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' ,"Validação Mashup",,1 )
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf


//================================================================================
//Validação de campos Chep
//================================================================================
	If _lRet .And. M->A1_I_CHEP  == "C" .And. Len(AllTrim(A1_I_CCHEP)) != 10

		U_ITMsg("Campo de código de cadastro chep inválido!","Validação Chep","Mude cliente para pallet pbr ou inclua código Chep válido!",1)
		_lRet := .F.

	EndIf

	If _lRet .And. M->A1_I_CHEP  != "C" .And. Len(AllTrim(A1_I_CCHEP)) > 0

		U_ITMsg("Campo de código de cadastro chep prenchido para cliente não Chep!","Validação Chep","Mude cliente para chep pbr ou limpe o código Chep válido!",1)
		_lRet := .F.

	EndIf

	If !IsInCallStack("U_AOMS014")
		If !Empty(M->A1_INSCR)
			M->A1_INSCR := AllTrim(StrTran(M->A1_INSCR,"-",""))
		EndIf

		//==========================================================================
		// Quando o cliente For alterado para Simples Nacional == NÃO,
		// Limpar código de tabela de preços Simples Nacional do campo A1_TABELA.
		//==========================================================================
		If _lRet .And. _oObj:GetOperation() == MODEL_OPERATION_UPDATE
			If SA1->A1_SIMPNAC == "1" .And. M->A1_SIMPNAC == "2"
				U_CRMA980PTB(.T.)
			Else
				U_CRMA980PTB(.F.)
			EndIf
		EndIf
	EndIf

	If _lRet .And. !Empty(AllTrim(_cGrpGen)) .And. !Empty(AllTrim(_cVendGen))

		If M->A1_I_GRCLI $ _cGrpGen .And. (IsInCallStack("MATA030") .Or. IsInCallStack("CRMA980") ) .And. !(M->A1_VEND $ _cVendGen)

			U_ITMsg("A efetivação não será realizada!"+Chr(13)+Chr(10)+"Para este grupo de clientes "+M->A1_I_GRCLI+" só é permito vincular os vendedores genéricos: "+_cVendGen,"Atenção","Altere o vendedor para um que seja genérico conforme informado.",1)
			_lRet := .F.

		EndIf

	EndIf

	_cA1_NOME := _oModelSA1:GetValue("A1_NOME")
	If _lRet .And. !Empty(AllTrim(_cA1_NOME))
		_lRet := U_CRMA980VCP(@_cA1_NOME ,"A1_NOME")
		_oModelSA1:LoadValue("A1_NOME",_cA1_NOME)
	EndIf

	_cA1_END := _oModelSA1:GetValue("A1_END")
	If _lRet .And. !Empty(AllTrim(_cA1_END))
		_lRet := U_CRMA980VCP(@_cA1_END    ,"A1_END")
		_oModelSA1:LoadValue("A1_END",_cA1_END)
	EndIf

	_cA1_BAIRRO := _oModelSA1:GetValue("A1_BAIRRO")
	If _lRet .And. !Empty(AllTrim(_cA1_BAIRRO))
		_lRet := U_CRMA980VCP(@_cA1_BAIRRO    ,"A1_BAIRRO")
		_oModelSA1:LoadValue("A1_BAIRRO",_cA1_BAIRRO)
	EndIf

	_cA1_ENDCOB := _oModelSA1:GetValue("A1_ENDCOB")
	If _lRet .And. !Empty(AllTrim(_cA1_ENDCOB))
		_lRet := U_CRMA980VCP(@_cA1_ENDCOB    ,"A1_ENDCOB")
		_oModelSA1:LoadValue("A1_ENDCOB",_cA1_ENDCOB)
	EndIf

	_cA1_ENDREC := _oModelSA1:GetValue("A1_ENDREC")
	If _lRet .And. !Empty(AllTrim(_cA1_ENDREC))
		_lRet := U_CRMA980VCP(@_cA1_ENDREC    ,"A1_ENDREC")
		_oModelSA1:LoadValue("A1_ENDREC",_cA1_ENDREC)
	EndIf

	_cA1_ENDENT := _oModelSA1:GetValue("A1_ENDENT")
	If _lRet .And. !Empty(AllTrim(_cA1_ENDENT))
		_lRet := U_CRMA980VCP(@_cA1_ENDENT    ,"A1_ENDENT")
		_oModelSA1:LoadValue("A1_ENDENT",_cA1_ENDENT)
	EndIf

	_cA1_BAIRROE := _oModelSA1:GetValue("A1_BAIRROE")
	If _lRet .And. !Empty(AllTrim(_cA1_ENDENT))
		_lRet := U_CRMA980VCP(@_cA1_BAIRROE    ,"A1_BAIRROE")
		_oModelSA1:LoadValue("A1_BAIRROE",_cA1_BAIRROE)
	EndIf

	If _lRet .And. (_oObj:GetOperation() == MODEL_OPERATION_INSERT .Or. _oObj:GetOperation() == MODEL_OPERATION_UPDATE) .And. !IsInCallStack("U_AOMS014")
		If _oModelSA1:GetValue("A1_PESSOA") == "J" .And. (Empty(AllTrim(_oModelSA1:GetValue("A1_CNAE"))) .Or. _oModelSA1:GetValue("A1_CNAE") == "    - /  ")
			U_ITMsg("Necessário o preenchimento do campo CNAE para Clientes pessoa Jurídica!","Atenção","",1)
			_lRet := .F.
		EndIf
	EndIf

	FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: CRMA980RIS
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Validaçao do grau de risco e limite de credito. Substitui o MA030RIS do fonte MA030TOK. 
Parametros--------: Nenhum
Retorno-----------: Lógico com exibição de mensagens para tratativa das negativas
===============================================================================================================================
*/
Static Function CRMA980RIS()

	Local _aArea	:= FWGetArea()
	Local _lRet		:= .T.
	Local _cQry		:= ""
	Local _cCliente	:= ""
	Local _cLoja	:= ""
	Local _cAlias	:= GetNextAlias()
	Local _cQuery	:= ''
	Local _aCliente	:= {}
	Local _cLjvalid	:= ""
	Local _aRecnos	:= {}
	Local _lLimite	:= .F.
	Local _lRisco	:= .F.
	Local _nI		:= 0

	Begin Sequence

		If IsInCallStack("U_MOMS055") // Não validar msexecauto da integração do Broker.
			Break
		EndIf

		_cCliente	:= M->A1_COD
		_cLoja		:= M->A1_LOJA

		_cQuery := " SELECT "
		_cQuery += " 	A1.A1_COD, A1.A1_LOJA, A1.A1_LC, A1.R_E_C_N_O_ AS SA1REG "
		_cQuery += " FROM "+ RetSqlName ("SA1")+ " A1  "
		_cQuery += " WHERE "
		_cQuery += " 		A1.D_E_L_E_T_	= ' ' "
		_cQuery += " AND	A1.A1_LC		<> '0'   "
		_cQuery += " AND	A1.A1_COD		= '"+ _cCliente + "' "

		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )
		While (_cAlias)->( !Eof() )

			If _cLoja <> (_cAlias)->A1_LOJA
				aAdd( _aCliente,	{ (_cAlias)->A1_LOJA }	)
				aAdd( _aRecnos,	{ (_cAlias)->SA1REG }	)
			EndIf

			(_cAlias)->( DBSkip() )
		EndDo

		//================================================================================
		// Não permite gravar Limite se já tiver Limite gravado em outras Lojas. Rotina automatica não deve mostrar
		//================================================================================
		If Len( _aCliente ) > 0

			If M->A1_LC <> 0 .And. ( FunName() <> "MOMS003" )
				_lLimite := .T.
			EndIf
			//================================================================================
			// Tratativa para o chamado - 5717 - Permitir gravar Prospect sem Limite
			//================================================================================
		ElseIf M->A1_LC == 0 .And. ( FunName() <> "AOMS016" )

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Limite de Crédito não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ". É obrigatório o preencimento deste campo." } )
				EndIf
			Else
				U_ITMsg("Limite de crédito não preenchido!","Validação Crédito","É obrigatório incluir um limite de crédito para o cliente.",1)
			EndIf

			_lRet := .F.
		EndIf

		(_cAlias)->( DBCloseArea() )

		// Verificacao se existe alguma loja deste cliente com o risco diferente do que está sendo informado
		_cQry := "SELECT COUNT(*) AS QTDENT "
		_cQry += "FROM " + RetSqlName("SA1") + " "
		_cQry += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
		_cQry += "  AND A1_COD = '" + M->A1_COD + "' "
		_cQry += "  AND A1_LOJA <> '" + M->A1_LOJA + "' "
		_cQry += "  AND A1_RISCO <> '" + M->A1_RISCO + "' "
		_cQry += "  AND D_E_L_E_T_ = ' ' "

		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQTD" , .T. , .F. )

		DBSelectArea("TRBQTD")
		TRBQTD->(DBGoTop())

		If TRBQTD->QTDENT > 0
			_lRisco := .T.
		EndIf

		DBSelectArea("TRBQTD")
		TRBQTD->(DBCloseArea())

		If _lLimite .And. !_lRisco

			_cLjvalid := ""

			For _nI := 1 to Len( _aCliente )

				If _nI == Len( _aCliente )
					_cLjvalid  += _aCliente[_nI][01]
				Else
					_cLjvalid  += _aCliente[_nI][01] + "; "
				EndIf

			Next _nI

			If U_ITMsg("A(s) Loja(s) " + _cLjvalid + " do cliente " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + ;
					" já possui(em) valor(es) de Limite(s) cadastrado(s), como o valor de Limite é compartilhado entre as lojas somente uma loja deverá ter limite estabelecido!",;
					"Validação Crédito","Deseja manter este limite de crédito compartilhado para todas as lojas? O sistema irá zerar o limite de crédito das outras lojas.",2,2,2)
				CRMA980VLC(_lLimite, _aCliente, _aRecnos)
			Else
				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"As lojas: " + _cLjvalid + " do cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", já possui(em) valor(es) de Limite(s) cadastrado(s)." } )
					EndIf
				EndIf
				_lRet := .F.
			EndIf
		ElseIf !_lLimite .And. _lRisco

			If !IsInCallStack("U_MOMS003")

				If U_ITMsg("Erro no Grau de Risco informado para o cliente - " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + chr(10) + chr(13) + ;
						"É necessário verificar o cadastro deste cliente, pois existem outras lojas com o Grau de Risco diferente deste cadastro.",;
						"Validação Crédito","Deseja replicar este Risco para todas as lojas?",2,2,2)

					CRMA980VRIS()
				Else
					_lRet := .F.
				EndIf
			Else
				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"Erro no Grau de Risco informado no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", existem outras lojas com o Grau de Risco diferente deste cadastro." } )
					EndIf
				EndIf
				_lRet := .F.
			EndIf
		ElseIf _lLimite .And. _lRisco

			_cLjvalid := ""

			For _nI := 1 to Len( _aCliente )

				If _nI == Len( _aCliente )
					_cLjvalid  += _aCliente[_nI][01]
				Else
					_cLjvalid  += _aCliente[_nI][01] + "; "
				EndIf

			Next _nI

			If U_ITMsg("A(s) Loja(s) " + _cLjvalid + " do cliente - " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + ;
					"já possui(em) valor(es) de Limite(s) cadastrado(s), como o valor de Limite é compartilhado entre as lojas somente uma loja deverá ter limite estabelecido!",;
					"Validação de limite de crédito","Deseja manter este Grau de Risco e limite de crédito compartilhado para todas as lojas? O sistema irá zerar o limite de crédito das outras lojas.",2,2,2)

				CRMA980VLC(_lLimite, _aCliente, _aRecnos)
				CRMA980VRIS()
			Else
				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"As lojas: " + _cLjvalid + " do cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", já possui(em) valor(es) de Limite(s) cadastrado(s)." } )
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"Erro no Grau de Risco informado no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", existem outras lojas com o Grau de Risco diferente deste cadastro." } )
					EndIf
				EndIf
				_lRet := .F.
			EndIf
		EndIf

	End Sequence

	FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: CRMA980VLC
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Funcao para zerar o limite de credito, caso uma outra loja ja o tenha. Substitui o VLDLIM do Fonte MA030TOK.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CRMA980VLC(_lLimite, _aCliente, _aRecnos)

	Local _nI		:= 0

	If _lLimite
		If M->A1_LC > 0
			DBSelectArea("SA1")
			For _nI := 1 To Len( _aRecnos )
				DBGoTo( _aRecnos[_nI][01] )
				RecLock("SA1", .F.)
				Replace SA1->A1_LC With 0
				MSUnLock()
			Next _nI
		EndIf
	EndIf

Return

/*
===============================================================================================================================
Programa----------: CRMA980VRIS
Autor-------------: Igor Melgaço
Data da Criacao---: 25/08/2021
Descrição---------: Funcao para gravar o mesmo grau de risco para todas as lojas. Substitui o VLDLIM.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CRMA980VRIS()
	Local _cQry	:= ""

// Seleciona todos as lojas do cliente em questao, para que sejam atualizados os riscos em todos os registros deste cliente
	_cQry := "SELECT A1_FILIAL, A1_COD, A1_LOJA, R_E_C_N_O_ AS RECSA1 "
	_cQry += "FROM " + RetSqlName("SA1") + " "
	_cQry += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
	_cQry += "  AND A1_COD = '" + M->A1_COD + "' "
	_cQry += "  AND A1_LOJA <> '" + M->A1_LOJA + "' "
	_cQry += "  AND D_E_L_E_T_ = ' ' "

	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBSA1" , .T. , .F. )

	DBSelectArea("TRBSA1")
	TRBSA1->(DBGoTop())

	While !TRBSA1->(Eof())
		DBSelectArea("SA1")
		DBGoTo(TRBSA1->RECSA1)
		RecLock("SA1", .F.)
		Replace SA1->A1_RISCO With M->A1_RISCO
		MSUnLock()
		TRBSA1->(DBSkip())
	End

	DBSelectArea("TRBSA1")
	TRBSA1->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: CRMA980BUT
Autor-------------: Igor Melgaço
Data da Criacao---: 30/08/2021
Descrição---------: Ponto de entrada para inclusão de botões na tela de manutenção do cadastro de Clientes. Substitui o MA030BUT
Parametros--------: ParamIXB -> Numérico -> Tipo da operação do usuário.
Retorno-----------: aBtnUsr - Array para inclusão de botões na tela de manutenção do cadastro de Clientes
===============================================================================================================================
*/
Static Function CRMA980BUT(aParam)

	Local nOpcA		:= aParam[01]
	Local aBtnUsr		:= {}
	Local cMatUsr		:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]

//================================================================================
//| Inclui botoes na tela do cadastro de clientes se não For inclusão            |
//================================================================================
	If	nOpcA != 3

		aAdd( aBtnUsr , { "Historico de Alteracoes","Historico de Alteracoes", {|| U_COMS004() } } )

		//Se é usuário do crédito inclui botão de análise de crédito
		If GetAdvFVal( "ZZL" , "ZZL_LIBCRE" , xFilial("ZZL") + cMatUsr , 1 , "N" ) == "S"

			aAdd( aBtnUsr , { "Analise de Credito" , "Analise de Credito", {|| FWMsgRun(,{ || U_TelCred(2)}, "Aguarde...","Realizando consulta Cisp...") }} )

		EndIf

	EndIf

//================================================================================
//| Caso a chamada seja de alteração, guarda os valores originais dos campos     |
//================================================================================
	If nOpcA == 4
		Public _aITASA1 := U_ITINILOG( "SA1" )
	EndIf

Return( aBtnUsr )

/*
===============================================================================================================================
Programa----------: CRMA980WHE
Autor-------------: Igor Melgaço
Data da Criacao---: 09/11/2021
Descrição---------: Rotina ue retorna acesso a campos para usuário referentes a Liberação de Credito   
Parametros--------: Nenhum      
Retorno-----------: (.T./.F.)
===============================================================================================================================
*/
User Function CRMA980WHE()
	Local lExecAuto := .F.
	Local lReturn   := .F.
	Local _cCodID := __cUserId

	lExecAuto := IsInCallStack('MSEXECAUTO')

	If lExecAuto
		lReturn := .T.
	Else

		If Posicione("ZZL",3,xFilial("ZZL")+AllTrim(_cCodID),"ZZL_LIBCRE") == "S"
			lReturn := .T.
		Else
			lReturn := .F.
		EndIf

	EndIf

Return lReturn

/*
===============================================================================================================================
Programa----------: CRMA980X
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2021
Descrição---------: Rotina de envio de e-mail WorkFlow notificando a alteração dos vendedores.
Parametros--------: _aDados = {{ Rede , Nome Rede, Cod Vend. Anterior, Nome Vend. Anterior, Cod. Vend.Atual, Nome Vend.Atual},
                           ...,{ Rede , Nome Rede, Cod Vend. Anterior, Nome Vend. Anterior, Cod. Vend.Atual, Nome Vend.Atual}} 
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CRMA980X(_aDados)

	Local _aConfig	:= U_ITCFGEML('')
	Local _cMsgEml	:= '',_nI
	Local _cAssunto := "WORKFLOW - ALTERAÇÃO DE VENDEDOR EM CLIENTE COM CONTROLE DE REDE"
	Local _cEmail1	:= AllTrim(U_ITGETMV("IT_EMALGP1",""))
	Local _cEmail2	:= AllTrim(U_ITGETMV("IT_EMALGP2",""))
	Local _cEmailEnv, _cEmlLog := ""

	If Empty(_cEmail1) .And. Empty(_cEmail2)
		Return
	EndIf

	_cEmailEnv := AllTrim(_cEmail1) + ";" + AllTrim(_cEmail2)

	_cMsgEml := '<html>'
	_cMsgEml += '<head><title>' + _cAssunto + '</title></head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
	_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
	_cMsgEml += 'td.AZUL    { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; }'
	_cMsgEml += 'td.amarelo { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFF00; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
	_cMsgEml += '	</tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="2" class="grupos" width="100%"><b>' + _cAssunto + '</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="20%"><b>Cliente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="80%">' + SA1->A1_COD +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Loja:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_LOJA +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Nome:</b></td>'
	_cMsgEml += '      <td class="itens" align="left width="65%">' + SA1->A1_NOME +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Rede:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + _aDados[01][01] +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Descrição Rede:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + _aDados[01][02]  +'</td>'
	_cMsgEml += '    </tr>'
//_cMsgEml += '    <tr>'
//_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Usuario:</b></td>'
//_cMsgEml += '      <td class="itens" align="left" >' + __cUserId +'</td>'
//_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Usuario Alterador:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + UsrFullName (__cUserId)  +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Data da Alteração:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + DToC(Date()) +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Hora da Alteração:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + Time() + '</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += ' <tr>'
	_cMsgEml += '   <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
	_cMsgEml += ' </tr>'
	_cMsgEml += '</table>'

	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Codigo Vendedor Anterior</b></td>'
	_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Nome Vendedor Anterior</b></td>'
	_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Codigo Vendedor Atual</b></td>'
	_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Nome Vendedor Atual</b></td>'
	_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Vendedor Alterado</b></td>'
	_cMsgEml += '    </tr>'

	For _nI := 1 To Len( _aDados )
		_cMsgEml += '    <tr>'
		_cMsgEml += '     <td class="itens" align="left" width="10%">'+_aDados[_nI][03]+'</td>'
		_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][04]+'</td>'
		_cMsgEml += '     <td class="itens" align="left" width="10%">'+_aDados[_nI][05]+'</td>'
		_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][06]+'</td>'
		_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][07]+'</td>'
		_cMsgEml += '    </tr>'
	Next _nI

	_cMsgEml += '</table>'

	U_ITConOut('Enviando E-mail(s) para: '+_cEmailEnv+ " - Log de Processamento - Vendedores Alterados - "+TIME()+" - [ M030PALT]")

//    ITEnvMail(cFrom     ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
	U_ITENVMAIL( _aConfig[01] , _cEmailEnv ,"",         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Return .T.

/*
===============================================================================================================================
Programa----------: CRMA980Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2021
Descrição---------: Rotina de envio de e-mail WorkFlow notificando a bloqueio do cliente por desconto contratual. 
                    Chamado 30177.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CRMA980Y()

	Local _aConfig	:= U_ITCFGEML('')
	Local _cMsgEml	:= ''
	Local _cAssunto := "WORKFLOW - CLIENTE BLOQUEADO PARA AVALIAÇÃO DE REGRA DE DESCONTO CONTRATUAL"
	Local _cEmail1	:= AllTrim(U_ITGETMV("IT_EMALCL1","sistema@italac.com.br"))
	Local _cEmail2	:= AllTrim(U_ITGETMV("IT_EMALCL2","sistema@italac.com.br"))
	Local _cEmailEnv, _cEmlLog := ""

	If Empty(_cEmail1) .And. Empty(_cEmail2)
		Return
	EndIf

	_cEmailEnv := AllTrim(_cEmail1) + ";" + AllTrim(_cEmail2)

	_cMsgEml := '<html>'
	_cMsgEml += '<head><title>' + _cAssunto + '</title></head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
	_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
	_cMsgEml += 'td.AZUL    { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; }'
	_cMsgEml += 'td.amarelo { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFF00; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
	_cMsgEml += '	</tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="2" class="grupos" width="100%"><b>' + _cAssunto + '</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="20%"><b>Cliente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="80%">' + SA1->A1_COD +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Loja:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_LOJA +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Nome:</b></td>'
	_cMsgEml += '      <td class="itens" align="left width="65%">' + SA1->A1_NOME +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Rede:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_GRPVEN+'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Descrição Rede:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + AllTrim(Posicione("ACY",1,xFilial("ACY")+SA1->A1_GRPVEN,"ACY_DESCRI" ))+'</td>'
	_cMsgEml += '    </tr>'
//_cMsgEml += '    <tr>'
//_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Usuario:</b></td>'
//_cMsgEml += '      <td class="itens" align="left" >' + __cUserId +'</td>'
//_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Usuario Alterador:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + UsrFullName (__cUserId)  +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Data da Alteração:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + DToC(Date()) +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Hora da Alteração:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="65%">' + Time() + '</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += ' <tr>'
	_cMsgEml += '   <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
	_cMsgEml += ' </tr>'
	_cMsgEml += '</table>'

	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Descrição</b></td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '     <td class="itens" align="left" width="10%">'
//_cMsgEml += '     Este cliente foi bloqueado pois em seus cadastro foi informado um grupo de vendas para qual já existe um contrato de desconto preexistente.'
//_cMsgEml += '     O desbloqueio do cadastro será realizado pela equipe de manutenção dos cadastros de descontos contratuais. </td>'
	_cMsgEml += '     Este cliente foi bloqueado pois foi informado em seu cadastro um grupo de vendas que possui um desconto contratual de uso restrito. '
	_cMsgEml += '     A avaliação deste cadastro e o seu desbloqueio será realizada pela equipe que faz a gestão dos contratos de descontos! </td> '
	_cMsgEml += '</table>'

	U_ITConOut('Enviando E-mail(s) para: '+_cEmailEnv+ " - Log de Processamento - Cliente Bloqueado - "+TIME()+" - [ CRMA980Y]")

//    ITEnvMail(cFrom     ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
	U_ITENVMAIL( _aConfig[01] , _cEmailEnv ,"",         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Return .T.

/*
===============================================================================================================================
Programa----------: CRMA980VCP
Autor-------------: Igor Melgaço
Data da Criacao---: 30/05/2022
Descrição---------: Rotina que verifica o prenchimento de caracteres invalidos
Parametros--------: Nenhum      
Retorno-----------: (.T./.F.) 
===============================================================================================================================
*/
User Function CRMA980VCP(cCampo,cDesc,lSubstitui,lAuto)

	Local _cCarac      := U_ItGetMv("ITCARACINV","¡±¤¥ƒ‡£®©²³~^`´º°[§#*><!?|°ª'µ’"+'"')
	Local _cCaracInv   := ""
	Local _lCaracInv   := .F.
	Local i            := 0
	Local j            := 0
	Local _lRet        := .T.
	Local _cTitulo     := ""
	Local _cCaracSub   := U_ItGetMv("ITCARACSUB","S / N;S /N;S/ N;S Nr;SNr;S Num;S.Nr;S. Nr;S .Nr;S.Num;S. Num;S .Num")
	Local _aSub        := {}
	Local _aSub2       := {}
	Local _aSubSp      := {}

	Default cDesc      := ""
	Default lSubstitui := .F.
	Default lAuto      := .F.

//Tratamento para o Endereço sem Numero
	If !Empty(AllTrim(cDesc)) .And. cDesc $ "A1_END | A1_ENDCOB | A1_ENDREC | A1_ENDENT | A2_END | A2_ENDCOB | A2_ENDREC | A2_ENDENT"

		_aSub2 := StrTokArr (_cCaracSub, ";")

		For i := 1 To 10
			For j := 1 To Len(_aSub2)
				aAdd(_aSubSp,StrTran(_aSub2[j]," " ,Space(i)))
			Next
		Next

		For i := 1 To Len(_aSubSp)
			aAdd(_aSub,_aSubSp[i])
		Next

		cCampo := StrTran(cCampo,",          " ,", ")
		cCampo := StrTran(cCampo,",         " ,", ")
		cCampo := StrTran(cCampo,",        " ,", ")
		cCampo := StrTran(cCampo,",       " ,", ")
		cCampo := StrTran(cCampo,",      " ,", ")
		cCampo := StrTran(cCampo,",     " ,", ")
		cCampo := StrTran(cCampo,",    " ,", ")
		cCampo := StrTran(cCampo,",   " ,", ")
		cCampo := StrTran(cCampo,",  " ,", ")

		For i := 1 To Len(_aSub)

			cCampo := StrTran(cCampo," "+_aSub[i] ," S/N")
			cCampo := StrTran(cCampo,","+_aSub[i] ," S/N")
			cCampo := StrTran(cCampo,", "+_aSub[i] ," S/N")

		Next

	EndIf

//===================================================================================================
// Converte os Caracteres
//===================================================================================================
	cCampo := StrTran(cCampo ,"á","a")
	cCampo := StrTran(cCampo ,"Á","A")
	cCampo := StrTran(cCampo ,"à","a")
	cCampo := StrTran(cCampo ,"À","A")
	cCampo := StrTran(cCampo ,"ã","a")
	cCampo := StrTran(cCampo ,"Ã","A")
	cCampo := StrTran(cCampo ,"â","a")
	cCampo := StrTran(cCampo ,"Â","A")
	cCampo := StrTran(cCampo ,"ä","a")
	cCampo := StrTran(cCampo ,"Ä","A")
	cCampo := StrTran(cCampo ,"é","e")
	cCampo := StrTran(cCampo ,"É","E")
	cCampo := StrTran(cCampo ,"ë","e")
	cCampo := StrTran(cCampo ,"Ë","E")
	cCampo := StrTran(cCampo ,"ê","e")
	cCampo := StrTran(cCampo ,"Ê","E")
	cCampo := StrTran(cCampo ,"í","i")
	cCampo := StrTran(cCampo ,"Í","I")
	cCampo := StrTran(cCampo ,"ï","i")
	cCampo := StrTran(cCampo ,"Ï","I")
	cCampo := StrTran(cCampo ,"î","i")
	cCampo := StrTran(cCampo ,"Î","I")
	cCampo := StrTran(cCampo ,"ý","y")
	cCampo := StrTran(cCampo ,"Ý","y")
	cCampo := StrTran(cCampo ,"ÿ","y")
	cCampo := StrTran(cCampo ,"ó","o")
	cCampo := StrTran(cCampo ,"Ó","O")
	cCampo := StrTran(cCampo ,"õ","o")
	cCampo := StrTran(cCampo ,"Õ","O")
	cCampo := StrTran(cCampo ,"ö","o")
	cCampo := StrTran(cCampo ,"Ö","O")
	cCampo := StrTran(cCampo ,"ô","o")
	cCampo := StrTran(cCampo ,"Ô","O")
	cCampo := StrTran(cCampo ,"ò","o")
	cCampo := StrTran(cCampo ,"Ò","O")
	cCampo := StrTran(cCampo ,"ú","u")
	cCampo := StrTran(cCampo ,"Ú","U")
	cCampo := StrTran(cCampo ,"ù","u")
	cCampo := StrTran(cCampo ,"Ù","U")
	cCampo := StrTran(cCampo ,"ü","u")
	cCampo := StrTran(cCampo ,"Ü","U")
	cCampo := StrTran(cCampo ,"ç","c")
	cCampo := StrTran(cCampo ,"Ç","C")
	cCampo := StrTran(cCampo ,"ñ","n")
	cCampo := StrTran(cCampo ,"Ñ","N")
	cCampo := StrTran(cCampo ,"¼","1/4")
	cCampo := StrTran(cCampo ,"½","1/2")
	cCampo := StrTran(cCampo ,"¾","3/4")
	cCampo := StrTran(cCampo ,";",",")
	cCampo := StrTran(cCampo ,"–","-")
	cCampo := StrTran(cCampo ,"!","")
	cCampo := StrTran(cCampo ,"×","x")
	cCampo := StrTran(cCampo ,"°","o")

	If lSubstitui
		_lRet := cCampo
	Else
		//===================================================================================================
		// Resgata a descrição do Campo
		//===================================================================================================
		SX3->(DBSetOrder(2))
		SX3->( DBSeek(cDesc) )
		_cTitulo := X3TITULO()


		//===================================================================================================
		// Valida digitação de caracteres invalidos na descrição
		//===================================================================================================
		For i := 1 To Len(cCampo)
			If Subs(cCampo,i,1) $ _cCarac
				_cCaracInv += " " + Subs(cCampo,i,1)
				_lCaracInv := .T.
			EndIf
		Next

		If _lCaracInv
			If !lAuto
				U_ITMsg( "Caracteres inválidos preenchidos no campo "+_cTitulo,"Atenção",;
					"Retire os caracteres especiais.",1,,,.T.)
				//"Substitua os seguintes caracteres preenchidos "+_cCaracInv+".",1,,,.F.)
			EndIf
			_lRet := .F.
		EndIf
	EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: CRMA980CON
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2023
Descrição---------: Acerto do campo A1_CONTRIB / Funcao chamada tb do PE MALTCLI e M030INC
Parametros--------: Nenhum      
Retorno-----------: .T.
===============================================================================================================================
*/
User Function CRMA980CON

	SA1->(RecLock("SA1", .F.))
//A1_TPJ: 1=ME - Micro Empresa;2=EPP - Empresas de Pequeno Porte;3=MEI - Microempreendedor Individual;4=Não Optante
	If (Empty(SA1->A1_INSCR) .Or. AllTrim(SA1->A1_INSCR) == "ISENTO") .And. SA1->A1_TPJ =="3" .And. SA1->A1_EST $ "RS|SC|PR" .And. SA1->A1_SIMPNAC=="1"//1=Sim;2=Não
		SA1->A1_CONTRIB := "1"
	ElseIf Empty(SA1->A1_INSCR) .Or. AllTrim(SA1->A1_INSCR) == "ISENTO"
		SA1->A1_CONTRIB := "2"
	Else
		SA1->A1_CONTRIB := "1" // 1=Sim;2=Não
	EndIf
	If SA1->A1_CLIFUN = "1"   // 1=SIm;2=Nao
		SA1->A1_CONTRIB := "2" // 1=Sim;2=Não
	EndIf

	SA1->A1_INSCR := U_AOMS138N(SA1->A1_INSCR,SA1->A1_EST)

	SA1->(MSUnLock())

Return .T.

/*
===============================================================================================================================
Programa----------: CRMA980REP
Autor-------------: Igor Melgaço
Data da Criacao---: 11/09/2025
===============================================================================================================================
Descrição---------: Gatilho do CNPJ Chamado 51346
===============================================================================================================================
Parametros--------: _cCnpj     
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
User Function CRMA980REP(_cCnpj,_cCondPagto,_cGrpVen,_cNomeGrpVen)
	Local _nI := 0
	Local _cBaseCnpj := ""
	Local _aArea := FwGetArea("SA1")
	Local _cFilial := xFilial("SA1")
	Local _cCabec := {"","Código","Loja","Nome","Cond.Pagto","Grp.Vendas"}
	Local _lOk := .T.

	If !Empty(Alltrim(_cCnpj))
		For _nI := 1 To Len(_cCnpj)
			If Subs(_cCnpj,_nI,1) $ "0123456789"
				_cBaseCnpj += Subs(_cCnpj,_nI,1)
			EndIf
		Next

		If Len(_cBaseCnpj) = 14

			_cBaseCnpj := Subs(_cBaseCnpj,1,8)

			If Len(_aCNPJ) > 0
				_aCNPJ := {}
			EndIf

			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(_cFilial+_cBaseCnpj)
				Do While _cFilial+_cBaseCnpj == SA1->(SA1->A1_FILIAL+Subs(SA1->A1_CGC,1,8)) .AND. SA1->(!Eof())
					If (_cCondPagto <> SA1->A1_COND .OR. _cGrpVen <> SA1->A1_GRPVEN) .AND. SA1->A1_MSBLQL <> '1' .AND. SA1->A1_CGC <> _cCNPJ
						AADD(_aCNPJ,{.F.,SA1->A1_COD,SA1->A1_LOJA,SA1->A1_NREDUZ,SA1->A1_COND,SA1->A1_GRPVEN,SA1->(recno())})
					EndIf
					SA1->(DbSkip())
				EndDo
			EndIf

			If Len(_aCNPJ) > 0

				_aSiz := {5,10,30,15,10,10,10}

				_cMsgTop := "Clientes do mesmo CNPJ com dados de Cond. Pagto  / Grupo de Vendas divergentes "

				_cTitulo := "Marque os Clientes para atualizar com os novos dados de Cond. Pagto "+_cCondPagto+" e Grupo de Vendas "+_cGrpVen

				//                                 , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _aBbuttons )
				_lOk := U_ITListBox(_cTitulo,_cCabec   ,_aCNPJ        , .F.      , 2      ,_cMsgTop  ,          ,/*_aSiz*/,         ,     ,         )

				If !_lOk
					_aCNPJ := {}
				EndIf
			EndIf

			FwRestArea(_aArea)

		EndIf
	EndIf

Return _lOk


/*
===============================================================================================================================
Programa----------: CRMA980A
Autor-------------: Igor Melgaço
Data da Criacao---: 11/09/2025
===============================================================================================================================
Descrição---------: Processa alterações nas demais lojas do mesma base CNPJ - Chamado 51346
===============================================================================================================================
Parametros--------: _cCondPagto,_cGrpVen,_cNomeGrpVen     
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
User Function CRMA980A(_cCondPagto,_cGrpVen,_cNomeGrpVen)
	Local _nI := 0
	Local _aArea := {}

	If Len(_aCNPJ) > 0
		_aArea := FwGetArea("SA1")

		For _nI := 1 To Len(_aCNPJ)
			If _aCNPJ[_nI][1]
				SA1->(DbGoTo(_aCNPJ[_nI][7]))
				SA1->(Reclock("SA1",.F.))
				SA1->A1_COND    := _cCondPagto
				SA1->A1_GRPVEN  := _cGrpVen
				SA1->A1_I_NGRPC := _cNomeGrpVen
				SA1->(MSUnLock())
			EndIf
		Next

		FwRestArea(_aArea)
	EndIf

Return
