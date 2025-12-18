#Include "TOTVS.ch"
#Include "FWMVCDef.ch"
#Include "TBICONN.ch"

Static _nOper

/*
===============================================================================================================================
Programa----------: ITEM / ITITEMPE.PRW
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/02/2019
Descrição---------: Ponto de entrada no padrão MVC chamado pela rotina de manutenção de Produtos (Fonte: MATA010.PRX) 
Parametros--------: ParamIXB = parametros padrões de pontos de entrada Totvs.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITEM() 

Local _aParam        := ParamIXB               As aArray
Local _lRet          := .T.					   As Logical
Local _cIdPonto      := ''                     As Character 
Local _cIdModel      := ''					   As Character 	
Local _oModel        := FWModelActive()        As Object 
Local _oModelSB1     := Nil                    As Object
Local _oObj          := Nil                    As Object

If _aParam <> NIL
	_oObj     := _aParam[1]
	_cIdPonto := _aParam[2]
	_cIdModel := _aParam[3]
	_nOper	:= _oObj:GetOperation()
		
	If _cIdPonto == 'MODELPOS'                //'Chamada na validação total do modelo (MODELPOS).' 

	ElseIf _cIdPonto == 'MODELVLDACTIVE'      //Chamada na validação da ativação do Model.

	ElseIf _cIdPonto == 'FORMPOS'             //'Chamada na validação total do formulário (FORMPOS).'

		_oModelSB1  := _oModel:GetModel('SB1MASTER')

		_lRet := ITITEMV(_oModelSB1)

	ElseIf _cIdPonto == 'FORMLINEPRE'         //'Chamada na pré validação da linha do formulário (FORMLINEPRE). Onde esta se tentando deletar uma linha''É um FORMGRID.'
		
	ElseIf _cIdPonto == 'FORMLINEPOS'         //'Chamada na validação da linha do formulário (FORMLINEPOS).' É um FORMGRID.
		
	ElseIf _cIdPonto == 'MODELCOMMITTTS'      //'Chamada apos a gravação total do modelo e dentro da transação (MODELCOMMITTTS).' 

		// Chama antigo ponto de entrada do fonte MATA010 da alteração de produtos.
		If _nOper == MODEL_OPERATION_INSERT 
			U_ITITEMI() //U_MT010INC()
		ElseIf _nOper == MODEL_OPERATION_UPDATE
			U_ITITEMM() //U_MT010ALT()
		ElseIf _nOper == MODEL_OPERATION_DELETE 
			U_ITITEME() 
		EndIf 

	ElseIf _cIdPonto == 'MODELCOMMITNTTS'     //'Chamada apos a gravação total do modelo e fora da transação(MODELCOMMITNTTS).' 

	ElseIf _cIdPonto == 'FORMCOMMITTTSPOS'    //'Chamada apos a gravação da tabela do formulário (FORMCOMMITTTSPOS).' 
	
	ElseIf _cIdPonto == 'MODELCANCEL'         //'Chamada no Botão Cancelar (MODELCANCEL).'

	ElseIf _cIdPonto == 'MODELVLDACTIVE'      //'Chamada na validação da ativação do Model.' 

	ElseIf _cIdPonto == 'BUTTONBAR'           //'Adicionando Botão na Barra de Botões (BUTTONBAR).'

	EndIf
EndIf
	
Return _lRet 

/*
===============================================================================================================================
Programa----------: ITITEME 
Autor-------------: Igor Melgaço
Data da Criacao---: 24/09/2024  
Descrição---------: Ponto de entrada excluir indicadores relativos a ele	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITITEME()

Local _aArea	:= FWGetArea()   As Array
Local _cEmpCor	:= cEmpAnt       As Character

DBSelectArea("SM0")
SM0->( DBGoTop() )
While ( SM0->( !Eof() ) .And. _cEmpCor == SM0->M0_CODIGO ) // Percorrer todas as filiais
	DBSelectArea("SBZ")
	SBZ->( DBSetOrder(1) )
	If SBZ->( DBSeek( AllTrim(SM0->M0_CODFIL) + SB1->B1_COD ) )
		RecLock("SBZ",.F.)
      	DbDelete()
		MSUnLock()
	EndIf
	SM0->( DBSkip() )
EndDo

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ITITEMM
Autor-------------: Frederico O. C. Jr 
Data da Criacao---: 28/08/2008  
Descrição---------: Ponto de entrada para validar alteracao do produto e atualizar indicadores relativos a ele	(Substituição do MT010ALT)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITITEMM

Local _aArea	:= FWGetArea()  As Array
Local _cEmpCor	:= cEmpAnt      As Characater

DBSelectArea("SM0")
SM0->( DBGoTop() )
While ( SM0->( !Eof() ) .And. _cEmpCor == SM0->M0_CODIGO )
	DBSelectArea("SBZ")
	SBZ->( DBSetOrder(1) )
	If SBZ->( DBSeek( AllTrim(SM0->M0_CODFIL) + SB1->B1_COD ) )
		RecLock("SBZ",.F.)
			SBZ->BZ_ORIGEM    	:= SB1->B1_ORIGEM	   
		   	SBZ->BZ_TIPO   		:= SB1->B1_TIPO      
			SBZ->BZ_I_DESCR		:= SB1->B1_DESC		
			SBZ->BZ_IPI		   	:= SB1->B1_IPI		   
			SBZ->BZ_I_DETPR   	:= SB1->B1_I_DESCD	
		  	SBZ->BZ_PIS		   	:= SB1->B1_PIS		   
			SBZ->BZ_COFINS	   	:= SB1->B1_COFINS	   
			SBZ->BZ_CSLL	   	:= SB1->B1_CSLL		
			SBZ->BZ_IRRF	   	:= SB1->B1_IRRF		
			SBZ->BZ_ALIQISS		:= SB1->B1_ALIQISS	
			SBZ->BZ_CODISS	   	:= SB1->B1_CODISS	   
		   SBZ->BZ_PCOFINS   	:= SB1->B1_PCOFINS	
		   SBZ->BZ_PPIS      	:= SB1->B1_PPIS
		MSUnLock()
	EndIf
	SM0->( DBSkip() )
EndDo

U_AOMS078G("SB1") // Grava os dados dos Produtos nas tabelas de muro para integração com o sistema RDC.

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ITITEMI
Autor-------------: Frederico O. C. Jr 
Data da Criacao---: 28/08/2008  
Descrição---------: Ponto de entrada para, na inclusao de produto, gerar indicadores de produto	(Substituição do MT010INC)	 
Parametros--------: nOpcao - não utilizado / _oProcess - não utilizado
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITITEMI(nOpcao,_oProcess)

Local _aArea	:= FWGetArea()      As Array
Local _cEmpCor	:= cEmpAnt      	As Character
Local _aHeader  := {}				As Array
Local _aStruct  := {}				As Array
Local _acamps   := {}               As Array
Local _nCont	:= 0				As Numeric
Local _nI	    := 0				As Numeric
Local _nk       := 0                As Numeric

Private cProduto:= SB1->B1_COD      As Character
	
//Inicio da validação para preenchimento de campos na tabela SBZ conforme rotina padrão. Chamado: 2518
_acamps := SBZ->(Dbstruct()) 

For _nk := 1 to Len(_acamps)
	If Getsx3cache(_acamps[_nk][1],"X3_RELACAO") <> ' ' 
		_nCont++
		aAdd(_aHeader,{_acamps[_nk][1]})
		aAdd(_aStruct,{Getsx3cache(_acamps[_nk][1],"X3_RELACAO")}) 
	EndIf
Next _nk 

SM0->( DBGoTop() )

While SM0->(!Eof()) .And. _cEmpCor == SM0->M0_CODIGO   
	DBSelectArea("SBZ")
	RecLock("SBZ",.T.)
	SBZ->BZ_FILIAL	:= AllTrim(SM0->M0_CODFIL)
	SBZ->BZ_COD		:= SB1->B1_COD
	SBZ->BZ_TIPO   	:= SB1->B1_TIPO
	SBZ->BZ_LOCPAD	:= SB1->B1_LOCPAD
	SBZ->BZ_ORIGEM	:= SB1->B1_ORIGEM 				
	SBZ->BZ_I_DESCR	:= SB1->B1_DESC 
	SBZ->BZ_IPI		:= SB1->B1_IPI 
	SBZ->BZ_I_DETPR := SB1->B1_I_DESCD 
	SBZ->BZ_PIS		:= SB1->B1_PIS
	SBZ->BZ_COFINS	:= SB1->B1_COFINS
	SBZ->BZ_CSLL	:= SB1->B1_CSLL
	SBZ->BZ_IRRF	:= SB1->B1_IRRF
	SBZ->BZ_ALIQISS	:= SB1->B1_ALIQISS
	SBZ->BZ_CODISS	:= SB1->B1_CODISS
	SBZ->BZ_PCOFINS := SB1->B1_PCOFINS
	SBZ->BZ_PPIS    := SB1->B1_PPIS

	For _nI:= 1 to _nCont  
		If _aHeader[_nI][1] <> 'BZ_COD' .And. _aHeader[_nI][1] <> 'BZ_LOCPAD' .And. _aHeader[_nI][1] <> 'BZ_ORIGEM' 
			If _aHeader[_nI][1] <> 'BZ_I_DESCR' .And. _aHeader[_nI][1] <> 'BZ_PIS' .And. _aHeader[_nI][1] <> 'BZ_COFINS' 
				If _aHeader[_nI][1] <> 'BZ_CSLL' .And. _aHeader[_nI][1] <> 'BZ_IRRF' .And. _aHeader[_nI][1] <> 'BZ_PCOFINS' .And. _aHeader[_nI][1] <> 'BZ_PPIS' 			     
					SBZ->&(_aHeader[_nI][1]) := M->&(_aStruct[_nI][1]) 
				EndIf
			EndIf
		EndIf
	Next _nI  
		
	SBZ->( MSUnLock() )
	SM0->( DBSkip() )
EndDo		

FWRestArea(_aArea)                                                         

// Grava os dados dos produtos nas tabelas de muro para integração com o sistema RDC.
U_AOMS078G("SB1")
  
Return    

/*
===============================================================================================================================
Programa----------: ITITEMV
Autor-------------: Jose Gavetti
Data da Criacao---: 21/11/2025
Descrição---------: Validações no cadastro de Produtos. Substitui o A010TOK.
Parametros--------: Nenhum
Retorno-----------: Lógico com exibição de mensagens para tratativa das negativas
===============================================================================================================================
*/
Static Function ITITEMV(_oModelSB1)

Local _lExecuta      := .T.									As Logical 
Local _cB1_DESC      := ""									As Character
Local _cB1_I_DESCD   := ""									As Character
Local _cCerto        := ""									As Character
Local _nCont         := 0									As Numeric
Local _lFasesB1      := SuperGetMV("IT_FASESB1",.F.,.F.)	As Logical
Local _lValida       := .F.                                 As Logical 
Local _cIT_PRDSVOK   := SuperGetMV("IT_PRDSVOK",.F.,"")     As Character

If _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE
	_cB1_DESC := _oModelSB1:GetValue('B1_DESC') 
	If !Empty(AllTrim(_cB1_DESC))
		_lExecuta := U_CRMA980VCP(@_cB1_DESC   ,"B1_DESC")
		_oModelSB1:LoadValue('B1_DESC',_cB1_DESC)  
	EndIf
	
	_cB1_I_DESCD := _oModelSB1:GetValue('B1_I_DESCD') 
	If _lExecuta .And. !Empty(AllTrim(_cB1_I_DESCD))
		_lExecuta := U_CRMA980VCP(@_cB1_I_DESCD   ,"B1_I_DESCD")
		_oModelSB1:LoadValue('B1_I_DESCD',_cB1_I_DESCD)  
	EndIf
Endif   

// Valida digitação da segunda unidade de medida do produto se não For grupo de exceção de medida
If (! Empty(M->B1_SEGUM) .And. Empty(M->B1_CONV) .And. !(M->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006") )) .OR.;
	( Empty(M->B1_SEGUM) .And. ! Empty(M->B1_CONV) .And. !(M->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006") ))
	Help(NIL, NIL, "A010TOK01", NIL, "Fator de conversão não preenchido para a segunda unidade de medida.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Favor preencher o fator de conversão. Ao informar a segunda unidade de medida, o fator de conversão precisa ser preenchido."})
	_lExecuta := .F.
EndIf

// Valida digitação da segunda unidade de medida do produto se não For grupo de exceção de medida
If _lExecuta
	If  Empty(SB1->B1_I_NIV5) .And.  Empty(M->B1_I_NIV5)//NÃO MEXEU E NÃO TEM N5
		If AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)== AllTrim(M->B1_DESC) .OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4)  .AND.;
			(!AllTrim(SB1->B1_DESC) == AllTrim(M->B1_DESC) .Or. !AllTrim(SB1->B1_I_DESCD) == AllTrim(M->B1_I_DESCD) )
			Help(NIL, NIL, "A010TOK02", NIL, "Descrições não pode ser alteradas quando o produto possui niveis preenchidos ate o nivel 4.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Favor contactar o depto de custos, resposavel pelo cadastro de niveis."})
			_lExecuta := .F.
		EndIf
	ElseIf  Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5)//COLOCOU  N5
		_cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)
		
		If (_cCerto == AllTrim(M->B1_DESC) .And. _cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5)
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+_cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And.  Empty(M->B1_I_NIV5)//TIROU  N5
			_cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)
			_cCerto:=AllTrim(_cCerto)
		If (_cCerto == AllTrim(M->B1_DESC) .And. _cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5) // .AND.;
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+_cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5) .And.  M->B1_I_NIV5 = SB1->B1_I_NIV5//NÃO MEXEU E TEM OU NÃO TROCOU N5
		_cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)

		If (_cCerto == AllTrim(M->B1_DESC) .And. _cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5)  .AND.;
			(!AllTrim(SB1->B1_DESC) == AllTrim(M->B1_DESC) .Or. !AllTrim(SB1->B1_I_DESCD) == AllTrim(M->B1_I_DESCD) )
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições não pode ser alteradas quando o produto possui niveis preenchidos ate o nivel 4", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Favor contactar o depto de custos, resposavel pelo cadastro de niveis."+_cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5) .And.  M->B1_I_NIV5 <> SB1->B1_I_NIV5//NÃO MEXEU E TEM OU TROCOU 
		_cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)

		If (_cCerto == AllTrim(M->B1_DESC) .And. _cCerto == AllTrim(M->B1_I_DESCD)) .OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5) // .AND.;
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+_cCerto})
			_lExecuta := .F.
		EndIf
	EndIf
ElseIf _nOper == MODEL_OPERATION_INSERT .And._lExecuta
	If !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4)  .And. ;
		(Empty(M->B1_I_NIV2) .Or. Empty(M->B1_I_NIV3) .Or. Empty(M->B1_I_NIV4))
			Help(NIL, NIL, "A010TOK03", NIL, "Todos os Niveis 2 , 3 e 4 devem ser preenchidos quando For PA ou embalagem de PA.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Preencha os niveis ou troque o tipo do produto."})
		_lExecuta := .F.
	EndIf
EndIf

// VALIDA PRODUTO ACABADO. 
If M->B1_TIPO == 'PA'
	If Empty(M->B1_I_SUBGR)
		Help(NIL, NIL, "A010TOK03", NIL, "Quando o tipo do Produto For igual a PA deve-se fornecer o Sub Grupo do Produto", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Favor preencher o campo Sub Grupo do Produto para confirmar o cadastro/alteração do Produto"})
		_lExecuta := .F.
	EndIf
	// Validação para Código EAN. 
	If Empty(M->B1_CODBAR)
		Help(NIL, NIL, "A010TOK03", NIL, "Quando o tipo do Produto For igual a PA deve-se informar o Código de Barras - EAN", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Favor preencher o campo Cod Barras para confirmar o cadastro/alteração do Produto"})
		_lExecuta := .F.
	EndIf
// VALIDA PRODUTO DE SERVIÇO. 
ElseIf M->B1_TIPO == 'SV' .And. !AllTrim(M->B1_COD) $ _cIT_PRDSVOK
	If !Empty(M->B1_PICM)
		Help(NIL, NIL, "A010TOK03", NIL, "Aliquota de ICMS não pode ser preenchida para um produto de tipo = 'SV'", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Zere Aliquota de ICMS desse produto ou troque o tipo para diferente de 'SV'"})
		_lExecuta := .F.
	EndIf     
	If !Empty(M->B1_IPI)
		Help(NIL, NIL, "A010TOK03", NIL, "Aliquota de IPI não pode ser preenchida para um produto de tipo = 'SV'", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Zere Aliquota de IPI desse produto ou troque o tipo para diferente de 'SV'"})
		_lExecuta := .F.
	EndIf     
EndIf

//  Inicio da validação realizada no campo B1_DESC afim de não permitir o uso de espaçamento feitos apartir da tecla tab e a tecla enter.
_nCont:= StrTran(M->B1_DESC	,'	',"") 

If _nCont <> M->B1_DESC .Or. LTrim(StrTran(M->B1_DESC	,'	',"")) <> M->B1_DESC
	Help(NIL, NIL, "A010TOK03", NIL, "Erro no preenchimento do campo Descrição", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Favor retirar os espaços em branco para prosseguir com o cadastro"})
	_lExecuta := .F. 
EndIf    

If _nOper == MODEL_OPERATION_INSERT  .And. _lExecuta
	SB1->(DBSetOrder(3))
	SB1->(DBSeek( xFilial()+AllTrim(M->B1_DESC) ))
	While SB1->(!Eof()) .And. AllTrim(M->B1_DESC) == AllTrim(SB1->B1_DESC)
		If AllTrim(M->B1_I_DESCD) == AllTrim(SB1->B1_I_DESCD)
			Help(NIL, NIL, "A010TOK03", NIL, "Produto já cadastrado", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Descrição já existente no Produto: "+SB1->B1_COD})
			_lExecuta := .F. 
			Exit
		EndIf
		SB1->(DBSkip())
	EndDo
	SB1->(DBSetOrder(1))
EndIf    

// Apagar o NCM dos produtos do GRUPO 1000, para todos os itens que forem TIPO SV - Chamado 19481
ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
If _lFasesB1
	_lValida:=!ZZL->ZZL_CADPRD = "1" // Alex: Não retirar esse comentario CHAMADO 31466 Habilitdo por enquanto  .T.//desabilitdo
Else
	_lValida:=.T.
EndIf

If (M->B1_GRUPO $ SuperGetMV("IT_GRUNCM",.F.,"1000") .And. M->B1_TIPO $ SuperGetMV("IT_TIPNCM",.F.,'SV')) .Or. M->B1_TIPO $ SuperGetMV("IT_TIPOPRD",.F.,'IM')
	If _lExecuta .And. !Empty(M->B1_POSIPI) .And. _lValida
		If (M->B1_GRUPO $ SuperGetMV("IT_GRUNCM",.F.,"1000") .And. M->B1_TIPO $ SuperGetMV("IT_TIPNCM",.F.,'SV')) 
			Help(NIL, NIL, "A010TOK03", NIL, "O produto pertence ao(s) grupo(s) "+AllTrim(SuperGetMV("IT_GRUNCM",.F.,"1000"))+" e ao(s) tipo(s) "+AllTrim(SuperGetMV("IT_TIPNCM",.F.,'SV'))+". ", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Portanto o conteúdo do campo NCM será removido."})
		Else
			Help(NIL, NIL, "A010TOK03", NIL, "O produto pertence ao(s) tipo(s) "+AllTrim(SuperGetMV("IT_TIPOPRD",.F.,'IM'))+". ", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Portanto o conteúdo do campo NCM será removido."})
		EndIf   
		_oModelSB1:LoadValue('B1_POSIPI', "          ")
	EndIf
ElseIf Empty(M->B1_POSIPI) .And. _lValida
	Help(NIL, NIL, "A010TOK03", NIL, "O campo da NCM não esta preenchido.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Favor preencher o campo da NCM na pasta Impostos (segunda pasta)"})
	_lExecuta := .F. 
EndIf

// Valida preenchimento Motivo do bloqueio 
If M->B1_MSBLQL == '1' .And. Empty(M->B1_I_MOTBL)
	_lExecuta := .F.
	Help(NIL, NIL, "A010TOK03", NIL, 'Campo Motivo Bloqueio vazio!', 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Para produtos bloqueados favor preencher o motivo do bloqueio."})
ElseIf M->B1_MSBLQL <> '1'
	M->B1_I_MOTBL:=Space(Len(SB1->B1_I_MOTBL))
	_oModelSB1:LoadValue('B1_I_MOTBL',Space(Len(SB1->B1_I_MOTBL)))
EndIf	

// Se For inclusão de PA, envia ITEMWF para sistema@italac.com.br
If _lFasesB1
	If _lExecuta .And. (_nOper == MODEL_OPERATION_INSERT  .Or. "#CONTROLE" $ SB1->B1_I_MOTBL)
		_lExecuta:=ITEMWLINC(_oModelSB1)
	EndIf
EndIf

// Se For inclusão de PA, envia ITEMWF para sistema@italac.com.br
If _lExecuta .And. !_nOper == MODEL_OPERATION_INSERT .And. (SB1->B1_UM <> M->B1_UM .Or. SB1->B1_SEGUM <> M->B1_SEGUM .Or. SB1->B1_CONV <> M->B1_CONV .Or. SB1->B1_TIPCONV <> M->B1_TIPCONV)
	If !(ISINCALLSTACK("MDIEXECUTE") .Or. ISINCALLSTACK("SIGAADV"))
		_lExecuta := ITEMCADSB1()
	Else
		FWMsgRun( ,{|oProc| _lExecuta := ITEMCADSB1(oProc) } , "Processando..." , "Validando Armazem..." )
	EndIf
EndIf

// Se For inclusão de PA, envia ITEMWF para sistema@italac.com.br
If _lExecuta .And. _nOper == MODEL_OPERATION_INSERT
	ITEMWF()
EndIf

If _lExecuta .And. !_nOper == MODEL_OPERATION_INSERT  .And. !FWIsInCallStack("MSEXECAUTO")
	M->B1_I_USRNA:=Capital(RTrim(UsrFullName(RetCodUsr())))
	M->B1_I_USRDA:=DToC(Date())
	_oModelSB1:LoadValue('B1_I_USRNA' ,M->B1_I_USRNA)
	_oModelSB1:LoadValue('B1_I_USRDA' ,M->B1_I_USRDA)
EndIf

Return _lExecuta

/*
===============================================================================================================================
Programa----------: ITEMWF
Autor-------------: Lucas Crevilari
Data da Criacao---: 12/09/2014
Descrição---------: Envio de ITEMWF quando For realizado cadastro de PA. Chamado 7363
Parametros--------: Nenhum	
Retorno-----------: Nenhum
===============================================================================================================================
*/   
Static Function ITEMWF()

Local _cEmail 		:= Space(0)  As Character                    
Local _cErrorMsg 	:= ""		 As Character       
Local _cRemetente   := ""		 As Character       
Local _cHtml 		:= ""		 As Character
Local _cSubject		:= ""		 As Character
Local _lResult 		:= ""		 As Logical
Local _cTitulo 		:= ""		 As Character
Local _cTexto2		:= ""		 As Character 
Local _cAlias		:= ""		 As Character
Local _cEmlLog      := ""		 As Character
Local _cLogErro     := ""        As Character

CONNECT SMTP ;
SERVER   GetMV("MV_RElseRV") ; 	// Nome do servidor de e-mail
ACCOUNT  GetMV("MV_RELACNT") ; 	// Nome da conta a ser usada no e-mail
PASSWORD GetMV("MV_RELPSW") ; 	// Senha
RESULT _lResult 				// Resultado da tentativa de conexão

If !_lResult // Nao foi possivel estabelecer conexao com o servidor 
	Help(NIL, NIL, "A010TOK03", NIL, "Falha no envio do email", 1, 0, NIL, NIL, NIL, NIL, NIL,{MailGetErr()})
EndIf

If _lResult 
	// Conectado ao Servidor, enviando o e-mail... 
	MailAuth(GetMV("MV_RELACNT"),GetMV("MV_RELPSW"))
	_cRemetente := GetMV("MV_RELACNT")

	If M->B1_TIPO == "PA"
		_cSubject := "Novo Cadastro de Produto Acabado" 
	Else
		_cSubject := "Novo Cadastro de Produto"
	EndIf	 		

	_cHtml := Space(0)
	_cHtml += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.01 Transitional//EN""http://www.w3.org/TR/html4/loose.dtd">'
	_cHtml += '<html>'
	_cHtml += '<head>'
	_cHtml += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"><title>Untitled Document</title>'
	_cHtml += '<style Type="text/css">'
	_cHtml += '<!--body,td,th { font-family: Arial, Helvetica, sans-serif; font-size: 12px;}.negrito { font-family: Arial, Helvetica, sans-serif; font-size: 12px; font-weight: bold; color: #003366;}.negrito2 { font-family: Arial, Helvetica, sans-serif; font-size: 15px; font-weight: bold; color: #003366;}.texto1 { font-family: Arial, Helvetica, sans-serif; font-size: 11px; color: #666666;}.texto2 { font-family: Arial, Helvetica, sans-serif; font-size: 9px; color: #666666;}-->'
	_cHtml += '</style>'
	_cHtml += '</head>'
	_cHtml += '<body>'                                                         
	_cHtml += '<p class=MsoNormal>'
    _cHtml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'

	If M->B1_TIPO == "PA"
		_cTitulo := "Novo Cadastro de Produto Acabado"
		_cTexto2 := "Novo Produto Acabado cadastrado no Protheus:"		
	Else	
		_cTitulo := "Novo Cadastro de Produto"
		_cTexto2 := "Novo Produto cadastrado no Protheus:"		
	EndIf	
    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	   _cTitulo += " - TESTE"
    EndIf

	_cHtml += '<table width="996" height="39"> <tr> <td align="center"><span class="negrito2" align="center">'+_cTitulo+'</span><br>'
	_cHtml += '<br> </td> </tr> </table>'
	_cHtml += '<p><span class="negrito">Prezados, </span>'
	_cHtml += '<br><span class="negrito">'+_cTexto2+'</span><span class="texto1"></span></br></p>'

	_cHtml += '<p><span class="negrito">Codigo: </span>'+M->B1_COD
	_cHtml += '<br><span class="negrito">Descricao: </span></br>'+M->B1_DESC+'</p>'
	
	_cHtml += '<p><span class="negrito">Usuário que realizou cadastro: </span>'+AllTrim(RetCodUsr())+" - "+AllTrim(UsrFullName(RetCodUsr()))
	_cHtml += '<br><span class="negrito">Data de Cadastro: </span></br>'+DToC(dDataBase)+" as "+TIME()+'</p>'
	_cHtml += '<table width="500" border="0" cellpadding="0" cellspacing="8"> <tr> <td width="167"><P class=MsoNormal> <span class="texto2" align="center"></span></p>'//</body></html>'

	_cHtml += '<br>'
	_cHtml += '<br>'
	_cHtml += '<br>'

	_cHtml += '<p><span class="negrito">Ambiente: </span></br> ['+ GETENVSERVER() +']'
	_cHtml += '   <span class="negrito"> / Fonte:    </span></br> [A010TOK] </p>'
	_cHtml += '</body>'
	_cHtml += '</html>'	
	
	// Selecionar os e-mail's dos usuarios que sera enviado o resumo do HTML
	If M->B1_TIPO == "PA"
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZZL_EMAIL
			FROM %Table:ZZL%
			WHERE	D_E_L_E_T_ = ' '
			AND		ZZL_ENVWFP = 'S'
		EndSql
	Else				
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZZL_EMAIL
			FROM %Table:ZZL%
			WHERE	D_E_L_E_T_ = ' '
			AND		ZZL_ENVWPT = 'S'
		EndSql	
	EndIf	

	// Deve existir no minimo um e-mail para a rotina processar a montagem e envio do arquivo
	If (_cAlias)->( !Eof() )
		While (_cAlias)->( !Eof() )
			_cEmail += ";"+ AllTrim( (_cAlias)->ZZL_EMAIL )
			(_cAlias)->(DBSkip() )
		EndDo
		_cEmail := SubStr( _cEmail , 2 , Len( _cEmail ) )
	EndIf

    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	   _cEmlLog := "Rotina executada em Ambiente de Testes: ["+ GetEnvServer() +"]. Não será processado o envio de e-mail!"
		Help(NIL, NIL, "A010TOK03", NIL, Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+_cEmail+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
	   Return
    EndIf
	
	Send mail ; 		    // envia e-mail
	from _cRemetente ; 	 	// de
	To _cEmail ; 		    // para
	subject _cSubject ;  	// assunto
	body _cHtml ;			// mensagem em HTML
	RESULT _lResult 
					
	If !_lResult 
	   GET MAIL ERROR _cErrorMsg
	   _cLogErro := "Falha de Envio: "+ AllTrim(_cErrorMsg)
	Else
	   _cLogErro := "Sucesso: e-mail enviado corretamente!"
    EndIf

   DISCONNECT SMTP SERVER

    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		Help(NIL, NIL, "A010TOK03", NIL, Upper(_cLogErro)+CHR(13)+CHR(10)+"E-mail para: "+_cEmail+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
    EndIf
EndIf 

Return

/*
===============================================================================================================================
Programa----------: ITEMCADSB1()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/11/2019
Descrição---------: Rotina para zerar a 1o Quantidade e da 2o Quantidade 
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITEMCADSB1(oProc)

Local _cObs     := "MOVIMENTO GERADO PELA ALTERACAO DE U.M. (A010TOK)"  As Character
Local _cArmaz   := ""													As Character
Local _cCod     := SB1->B1_COD 											As Character
Local _lEfetivar:= .T.													As Logical
Local _cAlias   := GetNextAlias()                                       As Character
Local _aExecAuto:= {}													As Array
Local _aLog     := {}													As Array
Local _nX       := 0													As Numeric
Local _lRet     := .T.													As Logical
Local _lTudoZerado := .F.                                               As Logical
Local _cQuery   := " SELECT "											As Character

BeginSql alias _cAlias
	SELECT NNR_CODIGO CODIGO, NNR_DESCRI DESCRICAO
	FROM %Table:NNR%
	WHERE D_E_L_E_T_ = ' '
EndSql

COUNT To _nRegSB1

_cTot   :=AllTrim(Str(_nRegSB1))
_nTam   :=Len(_cTot)+1
_nConta :=0		
_aLogTOK:={}

SB2->( DBSetOrder(1) )
ZZM->( DBSetOrder(1) )
ZZM->( DBGoTop() )
While ZZM->( !Eof() )
	_nConta:=0
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		_cArmaz := (_cAlias)->CODIGO
		_nConta++
		If oProc <> NIL
	        oProc:cCaption := ("Analisando Filial ["+ZZM->ZZM_CODIGO+"] / Armazem:  ["+_cArmaz+"], "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
			ProcessMessages()
		EndIf
		
		If SB2->( DBSeek( ZZM->ZZM_CODIGO+ _cCod + _cArmaz ) )
			_nQatu   := SB2->B2_QATU
			_nQatu2N := SB2->B2_QTSEGUM
			_nVatu1  := SB2->B2_VATU1
			If SB1->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006")
				lTemSegUM:= _nQatu2N > 0 
            Else
				lTemSegUM:= (SB1->B1_CONV > 0 .And. _nQatu2N > 0) .Or. (SB1->B1_CONV = 0 .And. _nQatu2N = 0)
			EndIf
		   
			If _nQatu > 0 .And. _nVatu1 > 0 .And. lTemSegUM
				aAdd(_aExecAuto,{_cArmaz,(_cAlias)->DESCRICAO,ZZM->ZZM_CODIGO,ZZM->ZZM_DESCRI})
			ElseIf _nQatu > 0 .And. _nVatu1 = 0 .And. lTemSegUM
				aAdd(_aExecAuto,{_cArmaz,(_cAlias)->DESCRICAO,ZZM->ZZM_CODIGO,ZZM->ZZM_DESCRI})
			ElseIf !(_nQatu = 0 .And. _nVatu1 = 0 .And. _nQatu2N = 0)
				aAdd( _aLog ,{.F.,_cArmaz,(_cAlias)->DESCRICAO,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem com quantidades / valores incorretos",ZZM->ZZM_CODIGO+" - "+ZZM->ZZM_DESCRI} )
				_lRet:= .F.
			ElseIf _nQatu = 0 .And. _nVatu1 = 0 .And. _nQatu2N = 0
				aAdd( _aLogTOK ,{.T.,_cArmaz,(_cAlias)->DESCRICAO,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"INVENTARIAR URGENTE",ZZM->ZZM_CODIGO+" - "+ZZM->ZZM_DESCRI} )
			EndIf
		EndIf
		(_cAlias)->(DBSkip())
	EndDo
	ZZM->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

_cTot:=AllTrim(Str(Len(_aExecAuto)))
_nTam:=Len(_cTot)
_nConta:=0		

_cQuery := "SELECT MAX(D3_DOC) AS MAXD3DOC "
_cQuery += " FROM " + RetSqlName("SD3") + " D3"
_cQuery += " WHERE D3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SubStr( D3.D3_DOC , 1 , 1 ) IN ('0','1','2','3','4','5','6','7','8','9') "

SB2->( DBSetOrder(1) )

For _nX :=  1 To Len(_aExecAuto)
	_cArmaz := _aExecAuto[_nX,1]
	_cDArmaz:= _aExecAuto[_nX,2]
	_cFilial:= _aExecAuto[_nX,3]
	_cFilDes:= _aExecAuto[_nX,4]

	_nConta++
    If oProc <> NIL
	   oProc:cCaption := ("Zerando Filial ["+_cFilial+"] / Armazem:  ["+_cArmaz+"], "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
	   ProcessMessages()
	EndIf   
	
	If SB2->( DBSeek( _cFilial + _cCod + _cArmaz ) )
		_nQatu   := SB2->B2_QATU
		_nQatu2N := SB2->B2_QTSEGUM
		_nVatu1  := SB2->B2_VATU1
        
		If SB1->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006")
		   lTemSegUM:= _nQatu2N > 0 
        Else
		   lTemSegUM:=(SB1->B1_CONV > 0 .And. _nQatu2N > 0) .Or. (SB1->B1_CONV = 0 .And. _nQatu2N = 0)
		EndIf   

	    If !_lRet
	       aAdd( _aLog ,{.F.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem não foi zerado, pois existem outros armazens incorretos",_cFilial+" - "+_cFilDes} )
           Loop
	    EndIf

	    _cD3_DOC:= ""
	    _cQueryF:= " AND D3.D3_FILIAL = '" + _cFilial + "'"
		DBUSEAREA(.T.,"TOPCONN", TcGenQry(,,(_cQuery+_cQueryF)), "SD3T", .T., .F. )
		If SD3T->( !Eof() )
			_cD3_DOC:=Soma1(SD3T->MAXD3DOC)
		EndIf
		SD3T->( DBCloseArea() )        

		_aSD31 := {}
        _aCab1 := {}
        _aToSD31 := {}

		If _nQatu > 0 .And. _nVatu1 > 0 .And. lTemSegUM
			_aCab1 := {	{ "D3_FILIAL"	, _cFilial			, Nil },;
			            { "D3_TM"		, "997"				, NIL },;//SAIDA
                        { "D3_CC"       ,"        "         , NIL },;
			            { "D3_DOC"		, _cD3_DOC			, NIL },;
			            { "D3_EMISSAO"	, dDataBase			, NIL } }			

			_aSD31 := {	{ "D3_COD"		, _cCod				, NIL },;
			            { "D3_LOCAL"	, _cArmaz			, NIL },;
			            { "D3_QUANT"	, _nQatu    		, NIL },;//TIRAR
			            { "D3_CUSTO1"	, _nVatu1			, NIL },;//TIRAR
		            	{ "D3_CUSTO3"	, _nVatu1			, NIL },;//TIRAR
		            	{ "D3_QTSEGUM"	, _nQatu2N			, NIL },;//TIRAR
			            { "D3_I_OBS"    , _cObs				, NIL } }
			
		ElseIf _nQatu > 0 .And. _nVatu1 = 0 .And. lTemSegUM
			_aCab1 := {	{ "D3_FILIAL"	, _cFilial			, Nil },;
			            { "D3_TM"		, "998"				, NIL },;//SAIDA
                        { "D3_CC"       ,"        "         , NIL },;
		            	{ "D3_DOC"		, _cD3_DOC			, NIL },;
			            { "D3_EMISSAO"	, dDataBase			, NIL } }			

			_aSD31 := {	{ "D3_COD"		, _cCod				, NIL },;
			            { "D3_LOCAL"	, _cArmaz			, NIL },;
		            	{ "D3_QUANT"	, _nQatu    		, NIL },;//TIRAR
		            	{ "D3_CUSTO1"	, 0  				, NIL },;
			            { "D3_CUSTO3"	, 0					, NIL },;
			            { "D3_QTSEGUM"	, _nQatu2N			, NIL },;//TIRAR
			            { "D3_I_OBS"    , _cObs				, NIL } }
		EndIf
		
        aAdd(_aToSD31,_aSD31)

		BEGIN TRANSACTION
		
		lMsErroAuto := .F.
		
		If _lEfetivar .And. Len(_aSD31) > 0
			cFilOld:=cFilAnt
			cFilAnt:=_cFilial
            MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab1 , _aToSD31 , 3 ) //Inclusao
			cFilAnt:=cFilOld
		EndIf
		
		If lMsErroAuto
			//_cErro:="MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MEST015.LOG")+" ]" 
			_cErro := "MSExecAuto: [ Este armazém não foi zerado, verifique empenhos e reservas e remova-os antes de alterar o produto. ]" 
			
			aAdd( _aLog ,{.F.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,_cErro,_cFilial+" - "+_cFilDes} )
		    _lRet:= .F.
			
			DisarmTransaction()
		ElseIf Len(_aSD31) > 0
			aAdd( _aLog ,{.T.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem com quantidades/valores zerado com sucesso",_cFilial+" - "+_cFilDes} )
		EndIf
		
		END TRANSACTION
	EndIf
Next _nX

_lTudoZerado:=.F.
If Len(_aLog) = 0 .And. Len(_aLogTOK) > 0
   _lTudoZerado:=.T.
   _aLog:=_aLogTOK
EndIf

_aLogAux:=aClone(_aLog)
_aLog:={}
For _nX :=  1 To Len(_aLogAux)
	aAdd( _aLog ,{_aLogAux[_nX,1],;
	              _aLogAux[_nX,9],;
	              _aLogAux[_nX,2],;
	              (Transform(_aLogAux[_nX,4],PesqPict("SB2","B2_QATU   "))),;
	              (Transform(_aLogAux[_nX,5],PesqPict("SB2","B2_QTSEGUM"))),;
	              (Transform(_aLogAux[_nX,6],PesqPict("SB2","B2_VATU1  "))),;
	              (Transform(_aLogAux[_nX,7],PesqPict("SB1","B1_CONV   "))),;
	              _aLogAux[_nX,8]} )
Next _nX

aSort(_aLog,,,{|X,Y| (X[2]+X[3]) < (Y[2]+Y[3]) })//ORDEM DE FILIAL + ARMAZEM

ITEMLOG(_aLog,oProc,_lRet,_lTudoZerado)

Return _lRet

/*
===============================================================================================================================
Programa----------: ITEMLOG()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/11/2019
Descrição---------: Rotina para zerar a 1o Quantidade e da 2o Quantidade 
Parametros--------: _aLog,oProc,_lRet
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITEMLOG(_aLog,oProc,_lRet,_lTudoZerado)

Local _aCab	:={} As Array
Local _aSize:={} As Array 

If Len(_aLog) > 0 //Monta aheader
	aAdd(_aCab,"")//01
	aAdd(_aSize,5)
	aAdd(_aCab,"Filial")//02
	aAdd(_aSize,90)
	aAdd(_aCab,"Armazem")//03
	aAdd(_aSize,5)
	aAdd(_aCab,"Qtde.1a.UM")//04
	aAdd(_aSize,45)
	aAdd(_aCab,"Qtde.2a.UM")//05
	aAdd(_aSize,45)
	aAdd(_aCab,"Vlr.Tot.Atual")//06
	aAdd(_aSize,45)
	aAdd(_aCab,"Fator.Conv.")//07
	aAdd(_aSize,45)
	aAdd(_aCab,"Resultado")//08
	aAdd(_aSize,150)

    nPosResu:=Len(_aCab)//Posiçao do "Resultado"
    ITEMEMAIL(_aLog,_aCab,oProc,_lRet,_lTudoZerado)

    aBotoes:={}                                           
    aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
    aAdd( aBotoes , { "" , {|| ITEMEMAIL(_aLog,_aCab,oProc,_lRet,_lTudoZerado) }	, "" , "Re-Envio de e-mail"		  } )
//          ITListBox(__cTitAux              , _aHeader , _aCols  , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
   _lRet:=U_ITLISTBOX("Armazens Processados", _aCab    , _aLog   , .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes)
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: ITEMEMAIL()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/11/2019
Descrição---------: Monta e envia email 
Parametros--------: _aTLinhas,_aCab,oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITEMEMAIL(_aTLinhas,_aCab,oProc,_lRet,_lTudoZerado)

Local _aConfig	:= U_ITCFGEML('')																As Array
Local _cEmlLog	:= ""																			As Character
Local _cMsgEml	:= ""																			As Character
Local _nI  		:= 0																			As Numeric																		
Local _aSizes	:= {}																			As Array
Local _aSizeOK  := {}																			As Array
Local _cGetCc	:= ""																			As Character
Local _cErMens	:= "Correções necessarias antes de alterar o cadastro"							As Character
Local _cOKMens	:= "Inventariar o produto nos armazens relacionados"							As Character
Local _cGetPara	:= "almoxarifados@italac.com.br"												As Character
Local _cTot     := AllTrim(Str(Len(_aTLinhas)))													As Character
Local _nTam     := Len(_cTot)																	As Numeric
Local _cNomeFil := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') )     	As Character
Local _cTit      := ""																			As Character
Local _cGetAssun := "Alterações do Produto "+AllTrim(SB1->B1_COD)+"-"+AllTrim(M->B1_DESC)+": " 	As Character
Local _cOKLista  := ""                                                                          As Character
Local _cGetLista := ""																			As Character
Local _lEnvia    := .F. 																		As Logical

Default _lTudoZerado := .F.

If SB1->B1_UM <> M->B1_UM 
   _cTit     +='Alteração da 1a U.M. <b>De: "'+SB1->B1_UM+'" Para: "'+M->B1_UM+'"</b>'+CHR(13)+CHR(10)
   _cGetAssun+='1a U.M. De: "'+SB1->B1_UM+'" Para: "'+M->B1_UM+'", '
EndIf

If SB1->B1_SEGUM <> M->B1_SEGUM 
   _cTit     +='Alteração da 2a U.M. <b>De: "'+SB1->B1_SEGUM+'" Para: "'+M->B1_SEGUM+'"</b>'+CHR(13)+CHR(10)
   _cGetAssun+='2a U.M. De: "'+SB1->B1_SEGUM+'" Para: "'+M->B1_SEGUM+'", '
EndIf

If SB1->B1_TIPCONV <> M->B1_TIPCONV 
   _cTit     +='Alteração do Tipo Conversão <b>De: "'+SB1->B1_TIPCONV+'" Para: "'+M->B1_TIPCONV+'"</b>'+CHR(13)+CHR(10)
   _cGetAssun+='Tipo Conv. De: "'+SB1->B1_TIPCONV+'" Para: "'+M->B1_TIPCONV+'", '
EndIf

If SB1->B1_CONV <> M->B1_CONV
   _cTit     +='Alteração da Conversão <b>De: "'+AllTrim(Str(SB1->B1_CONV,10,2))+'" Para: "'+AllTrim(Str(M->B1_CONV,10,2))+'"</b>'+CHR(13)+CHR(10)
   _cGetAssun+='Conversão De: "'+AllTrim(Str(SB1->B1_CONV,10,2))+'" Para: "'+AllTrim(Str(M->B1_CONV,10,2))+'", '
EndIf

_cTit     +="PRODUTO: <b>"+AllTrim(SB1->B1_COD)+"-"+AllTrim(M->B1_DESC)+"</b>"
_cGetAssun:=LEFT(_cGetAssun,Len(_cGetAssun)-2)

If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   _cGetPara	:= ""
EndIf

If Len(UsrRetGrp(PswChave(RetCodUsr()),RetCodUsr())) # 0 
   _cGetCc  := LOWER(AllTrim(UsrRetMail(__cUserId)))+Space(150) // Pega e-mail do usuario
EndIf

If Empty(_cGetPara)
   _cGetPara:=_cGetCc
EndIf   

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+_cTit+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados da alteração</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Alterado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
If _lRet
   _cMsgEml += '      <td class="itens" >'+_cOKMens+'</td>'
Else
   _cMsgEml += '      <td class="itens" >'+_cErMens+'</td>'
EndIf
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

//          01   02   03   04   05 
_aSizeOK:={"22","05","10","33","30"}
If _lRet
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="1300">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizeOK)))+'" class="grupos"><b>Produto de Filiais / Armazens para INVENTARIAR URGENTE</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[01]+'%"><b>'+_aCab[02]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[02]+'%"><b>'+_aCab[03]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[03]+'%"><b>Produto</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[04]+'%"><b>Descrição</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%"><b>'+_aCab[08]+'</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    #LISTAOK#'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'
EndIf

If !_lTudoZerado
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_aSizes:={"05","05","10","10","18","07","45"}
	If _lRet
		_cMsgEml += ' <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>Valores e Quantidades de Filiais / Armazens Zerados</b></td>'
	Else
		_cMsgEml += ' <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>Filiais / Armazens com problemas</b></td>'
	EndIf
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[02]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[03]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[03]+'%"><b>'+_aCab[04]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[04]+'%"><b>'+_aCab[05]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%"><b>'+_aCab[06]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%"><b>'+_aCab[07]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%"><b>'+_aCab[08]+'</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    #LISTA#'
	_cMsgEml += '</table>'
EndIf

_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [A010TOK]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cOKLista:=""
_cGetLista:=""
_lEnvia:=.F.
For _nI := 1 To Len(_aTLinhas)
    If oProc <> NIL
	   oProc:cCaption := ("Enviando Log: "+AllTrim(StrZero(_nI,_nTam))+" de "+ _cTot)
	   ProcessMessages()
	EndIf   
	
	If _lRet
		_cOKLista += '    <tr>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[01]+'%">'+ _aTLinhas[_nI][02]+'</td>'
		_cOKLista += '      <td class="itens" align="center" width="'+_aSizeOK[02]+'%">'+ _aTLinhas[_nI][03]+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[03]+'%">'+ SB1->B1_COD+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[04]+'%">'+ M->B1_DESC+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%"><b>INVENTARIAR URGENTE</b></td>'
		_cOKLista += '    </tr>'
	    _lEnvia:=.T.
	EndIf
	
	If !_lTudoZerado
		_cGetLista += '    <tr>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ LEFT(_aTLinhas[_nI][02],2)+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aTLinhas[_nI][03]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[03]+'%">'+ _aTLinhas[_nI][04]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[04]+'%">'+ _aTLinhas[_nI][05]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">R$ '+ _aTLinhas[_nI][06]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%">'+ _aTLinhas[_nI][07]+'</td>'
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ _aTLinhas[_nI][08]+'</td>'
		_cGetLista += '    </tr>'
	    _lEnvia:=.T.
	EndIf
Next _nI

If _lEnvia
   _cMsgEml:=StrTran(_cMsgEml,"#LISTAOK#",_cOKLista)
   _cMsgEml:=StrTran(_cMsgEml,"#LISTA#",_cGetLista)
		
   // Chama a função para envio do e-mail
   U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), _cGetPara, _cGetCc, "", _cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   	Help(NIL, NIL, "A010TOK03", NIL, Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+_cGetPara+" Com Copia: "+_cGetCc+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
   EndIf
Else
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   	Help(NIL, NIL, "A010TOK03", NIL,"Não tem registros para enviar", 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
   EndIf   
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ITEMWLINC()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/12/2019
Descrição---------: Monta e envia email 
Parametros--------: _oModelSB1
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITEMWLINC(_oModelSB1)

Local _aConfig	:= U_ITCFGEML('') 							As Array
Local _acTo     := {} 										As Array
Local _nX       := 0										As Numeric
Local _cEmlLog	:= ""										As Character
Local _cMsgEml	:= ""										As Character
Local _cGetCc	:= ""										As Character
Local _cGetPara	:= "sistema@italac.com.br"					As Character
Local _cTit     := "ALTERAÇÃO DE PRODUTO"					As Character
Local _cGetAssun:='NOVO PRODUTO EM PROCESSO DE INCLUSAO'	As Character
Local _cMens    := ""										As Character

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU

If !Inclui .And. !("#CONTROLE" $ SB1->B1_I_MOTBL)
	Return .T.	    
ElseIf  (!DBSeek(xFilial("ZZL") + __cUserId) .Or. ZZL->ZZL_CADPRD = "5" .Or. ZZL->ZZL_CADPRD = " ") .OR.;
	(!ZZL->ZZL_CADPRD $ "1,0" .And. !_nOper == MODEL_OPERATION_UPDATE)
   	Help(NIL, NIL, "A010TOK03", NIL,"O usuário: " + cUserName + " não possui permissão para executar esta ação neste cadastro.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Verificar com a área de TI a possibilidade de habilitar o seu usuário."})
	Return .F.	    
ElseIf ZZL->ZZL_CADPRD = "0"
	Return .T.	    
EndIf

If !Inclui
	M->B1_I_MOTBL:=SB1->B1_I_MOTBL
	M->B1_MSBLQL :=SB1->B1_MSBLQL
EndIf   

If ZZL->ZZL_CADPRD = "1"//Almoxarifado (Incluir)
	If Inclui .Or. "#CONTROLE1" $ SB1->B1_I_MOTBL
		_cTit :="INCLUSAO DE PRODUTO"
		_cMens:="Aguardando FISCAL preencher campos"
		cTipo:=" = '2'"
		M->B1_MSBLQL :="1"
		M->B1_I_MOTBL:="#CONTROLE1 - "+_cMens//Inclusão do Almoxarifado"
	Else
		Return .T.//SE NÃO TIVER NA FASE 1 NÃO ENVIA EMAIL
	EndIf   
ElseIf ZZL->ZZL_CADPRD = "2"//FISCAL 
	If "#CONTROLE1" $ SB1->B1_I_MOTBL  .Or. "#CONTROLE2" $ SB1->B1_I_MOTBL  //NA FASE  ANTERIOR OU ATUAL DE NOVO
		_cMens:="Aguardando CONTABILIDADE preencher campos"
		cTipo:=" = '3'"
		M->B1_I_MOTBL:="#CONTROLE2 - "+_cMens//Alteração do Fiscal"
	Else
		Return .T.//SE NÃO TIVER NA FASE 2 NÃO ENVIA EMAIL
	EndIf
ElseIf ZZL->ZZL_CADPRD = "3"//CONTABILIDADE 
	If "#CONTROLE2" $ SB1->B1_I_MOTBL .Or. "#CONTROLE3" $ SB1->B1_I_MOTBL  //NA FASE  ANTERIOR OU ATUAL DE NOVO
		_cMens:="Aguardando EXPEDIÇÃO preencher campos"
		cTipo:=" = '4'"
		M->B1_I_MOTBL:="#CONTROLE3 - "+_cMens//Alteração do Fiscal"
	ElseIf !"#CONTROLE3" $ SB1->B1_I_MOTBL 
		Help(NIL, NIL, "A010TOK03", NIL,"Deve-se aguardar a Fiscal preencher os campos para finalizar o processo.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Verificar com a área de Fiscal."})
		Return .F.	    
	EndIf   
ElseIf ZZL->ZZL_CADPRD = "4"//EXPEDICAO 
	_cTit :="Novo produto incluido com SUCESSO no cadastro"
	_cMens:="PRODUTO DESBLOQUEADO E DISPONIVEL PARA USO"
	_cGetAssun :=Upper(_cTit)
	If "#CONTROLE3" $ SB1->B1_I_MOTBL  
		M->B1_I_MOTBL:=""
		M->B1_MSBLQL :="2"
	Else
		Help(NIL, NIL, "A010TOK03", NIL,"Deve-se aguardar a Contabilidade preencher os campos para finalizar o processo.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Verificar com a área de Contabilidade."})
		Return .F.	    
	EndIf   
	cTipo:=" IN ('1','2','3','4') "
Else
   Return .T.
EndIf

_oModelSB1:LoadValue('B1_MSBLQL' ,M->B1_MSBLQL)
_oModelSB1:LoadValue('B1_I_MOTBL',M->B1_I_MOTBL)

_cFileName:=NIL
If !Inclui
	_cAlteracoes:="Produto:;"+M->B1_COD+"-"+AllTrim(M->B1_DESC)+CHR(13)+CHR(10)+CHR(13)+CHR(10)
	_cAlteracoes+="CAMPO;ANTES;DEPOIS"+CHR(13)+CHR(10)

	_aStruct:= SB1->(DBSTRUCT())
	For _nX := 1 To Len(_aStruct)
		_cUsado:=Getsx3cache(_aStruct[_nX][1],"X3_USADO")
		If !X3USO(_cUsado)
			Loop
		EndIf
		_cConOrg := "SB1->"+AllTrim(_aStruct[_nX][1] )
		_cConAlt :=   "M->"+AllTrim(_aStruct[_nX][1] )
		Do Case
			Case _aStruct[_nX][2] == "C"
				_cConOrg := AllTrim( &(_cConOrg) )
				_cConAlt := AllTrim( &(_cConAlt) )
			Case _aStruct[_nX][2] == "N"
				_cConOrg := " "+cValToChar( &(_cConOrg) )
				_cConAlt := " "+cValToChar( &(_cConAlt) )
			Case _aStruct[_nX][2] == "D"
				_cConOrg := DToC( &(_cConOrg) )
				_cConAlt := DToC( &(_cConAlt) )
			Case _aStruct[_nX][2] == "L"
				_cConOrg := If( &(_cConOrg) , ".T." , ".F." )
				_cConAlt := If( &(_cConAlt) , ".T." , ".F." )
			Case _aStruct[_nX][2] == "M"
				_cConOrg := AllTrim( &(_cConOrg) )
				_cConAlt := AllTrim( &(_cConAlt) )
		EndCase
		If !(_cConOrg == _cConAlt)
			_cAlteracoes+=AllTrim( _aStruct[_nX][1] )+";"+_cConOrg+";"+_cConAlt+CHR(13)+CHR(10)
		EndIf
	Next _nX
	_cFileName:="ALTERACOES_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".CSV"
	_cFileName:=AllTrim(GETMV("MV_RELT",,"\SPOOL\"))+_cFileName
	MemoWrite(_cFileName,_cAlteracoes)
EndIf   

_cQry := "SELECT ZZL_EMAIL "
_cQry += "FROM " + RetSqlName("ZZL") + " "
_cQry += "WHERE ZZL_FILIAL = '" + xFilial("ZZL") + "' "
_cQry += "  AND ZZL_CADPRD "+cTipo
_cQry += "  AND D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBZZL" , .T., .F. )

DBSelectArea("TRBZZL")
TRBZZL->(DBGoTop())

_acTo:={}
While !TRBZZL->(Eof())
	aAdd(_acTo,AllTrim(TRBZZL->ZZL_EMAIL))
	TRBZZL->(DBSkip())
EndDo
TRBZZL->(DBCloseArea())

If ZZL->ZZL_CADPRD <> "4" .And. Len(UsrRetGrp(PswChave(RetCodUsr()),RetCodUsr())) # 0 // Quando nao For rotina automatica do configurador
   _cGetCc  := LOWER(AllTrim(UsrRetMail(__cUserId))) // Pega e-mail do usuario
   aAdd(_acTo,_cGetCc)
EndIf

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+_cTit+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do Produto</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>CODIGO: </b></td>'
_cMsgEml += '      <td class="itens" >'+ M->B1_COD +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>DESCRIÇÃO: </b></td>'
_cMsgEml += '      <td class="itens" >'+ M->B1_DESC +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>SOLICITANTE:</b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>STATUS: </b></td>'
_cMsgEml += '      <td class="itens" >'+_cMens+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [A010TOK]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

For _nX := 1 To Len(_acTo)
    _cGetPara:=_acTo[_nX]
    //ITEnvMail(cFrom        ,cEmailTo,_cEmailCo,cEmailBcc,cAssunto ,_cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,_cLogErro)
    U_ITENVMAIL(_aConfig[01], _cGetPara,         ,         ,_cGetAssun,_cMsgEml ,_cFileName,_aConfig[01],_aConfig[02],_aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
       Help(NIL, NIL, "A010TOK03", NIL,Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+_cGetPara, 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{""})
    EndIf
    If _cFileName <> NIL
	   FERASE(_cFileName)
	EndIf   
Next _nX

Return .T.
