#Include "TOTVS.ch"
#Include "FWPrintSetup.ch" 
#Include "RPTDEF.CH"

/*
===============================================================================================================================
Programa--------: RGLT020
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Relatório dos registros de recebimentos de leite de terceiros - Análises de gordura
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT020(_lJob As Logical,_aPergunte As Array,_lPdf As Logical,_lEnvMail As Logical,_cDirPlan As Character,_cDirUser As Character)

Local _oProfile			:= Nil As Object
Local _oPrinter			:= Nil As Object
Local _oSetup			:= Nil As Object
Local _oExcel			:= Nil As Object
Local _nDestination		:= 1 As Numeric //1-SERVER - 2-CLIENT
Local _aMargRel			:= {0,0,0,0} As Array//nEsquerda, nSuperior, nDireita, nInferior
Local _cPerg			:= "RGLT020" As Character
Local _nPrintType		:= 6 As Numeric //FwMsPrinter só aceita 2-SPOOL (IMP_SPOOL) ou 6-PDF (IMP_PDF)
Local _cValueType		:= "d:\" As Character
Local _cPathInServer	:= __RelDir As Character
Local _aOrdem			:= {"Por Filial+Ticket+Recepção"} As Array
Local _nFlags			:= PD_ISTOTVSPRINTER+PD_DISABLEORIENTATION+PD_DISABLEPAPERSIZE+PD_DISABLEMARGIN As Numeric//PD_ISTOTVSPRINTER=1,PD_DISABLEDESTINATION=2,PD_DISABLEORIENTATION=4,PD_DISABLEPAPERSIZE=8,PD_DISABLEPREVIEW=16,PD_DISABLEMARGIN=32
Local _cFilePrint		:= If(_lJob,_aPergunte[5]+_aPergunte[6]+"_RGLT020","RGLT020") As Character//+DToS(MSDate())+StrTran(Time(),":","")
Local _nOrientation		:= 1 As Numeric//1-PORTRAIT - 2-LANDSCAPE
Local _cTitulo			:= "RGLT020 - Leite de Terceiros - Fechamento Quinzenal" As Character
Local _nPaperSize		:= 9 As Numeric//1-"Letter 8 1/2 x 11 in" / 2-"A4 210 x 297 mm" / 3-"A3 297 x 420 mm"/ 4-"Executive 7 1/4 x 10 1/2 in" / 5-"Tabloid 11 x 17 in"
Local _nOrdem			:= 1 As Numeric
Local _lPreview			:= .F. As Logical
Local _nX				:= 1 As Numeric
Default _lJob			:= .F.
Default _aPergunte		:= {}
Default _lPdf			:= .T.
Default _cDirPlan		:= ""

If _lPdf
	// Cria Arquivo do Relatorio
	_oPrinter := FWMSPrinter():New(_cFilePrint/*_cFilePrint*/,_nPrintType/*nDevice*/,.T./*lAdjustToLegacy*/,_cPathInServer/*_cPathInServer*/,.T./*lDisabeSetup*/,;
									/*lTReport*/,_oSetup/*oPrintSetup*/,/*cPrinter*/,/*lServer*/,/*lPDFAsPNG*/,.F./*lRaw*/,.T./*lViewPDF*/,/*nQtdCopy*/ )
									
	//Ativa a chave "Real Font Sizes" que diminui a divergência nos tamanhos de fonte encontrados entre impressões com saída PDF e Fila de Impressão.
	_oPrinter:SetParm( "-RFS")
Else
	//Criando o objeto que irá gerar o conteúdo do Excel
	_oExcel := FwMsExcelXlsx():New()
EndIf

If _lJob
	If _lPdf
		_oPrinter:nDevice := IMP_PDF
		_oPrinter:SetPortrait()
		_oPrinter:SetPaperSize(9)
		_oPrinter:cPathPDF := Lower(_cPathInServer)
		_oPrinter:SetViewPDF(.F.)
		_oPrinter:lInJob := .T.
		_oPrinter:lServer := .T.
		_oPrinter:SetResolution(75)
		_oPrinter:SetMargin(0,0,0,0)
	EndIf
	For _nX := 1 To Len(_aPergunte)
		&("MV_PAR" + StrZero(_nX,2,0)) := _aPergunte[_nX]
	Next _nX
Else
	//Busca configurações de impressão no Profile do usuário
	_oProfile:= FWProfile():New()
	_oProfile:SetUser(RetCodUsr())
	_oProfile:SetProgram("RGLT020")
	_oProfile:SetTask("PRINTER")
	_oProfile:SetType("PRINTTYPE")
	_oProfile:Load()
	_nPrintType := IIf(Empty(_oProfile:LoadStrProfile()),_nPrintType,Val(_oProfile:LoadStrProfile()))
	_oProfile:SetType("ORIENTATIO")
	_oProfile:Load()
	_nOrientation := IIf(Empty(_oProfile:LoadStrProfile()),_nOrientation,Val(_oProfile:LoadStrProfile()))
	_oProfile:SetType("DESTINATIO")
	_oProfile:Load()
	_nDestination := IIf(Empty(_oProfile:LoadStrProfile()),_nDestination,Val(_oProfile:LoadStrProfile()))
	_oProfile:SetType("PAPERSIZE")
	_oProfile:Load()
	_nPaperSize := IIf(Empty(_oProfile:LoadStrProfile()),_nPaperSize,Val(_oProfile:LoadStrProfile()))
	_oProfile:SetType("VALUETYPE")
	_oProfile:Load()
	_cValueType := IIf(Empty(_oProfile:LoadStrProfile()),_cValueType,_oProfile:LoadStrProfile())
	
	//Monta tela de seleção de impressora
	_oSetup := FWPrintSetup():New(_nFlags, _cTitulo)
	_oSetup:SetUserParms( {|| Pergunte(_cPerg, .T.) } ) 
	_oSetup:SetPropert(PD_PRINTTYPE   , _nPrintType)//2
	_oSetup:SetPropert(PD_ORIENTATION , _nOrientation)//3
	_oSetup:SetPropert(PD_DESTINATION , _nDestination)//1
	_oSetup:SetPropert(PD_MARGIN      , {_aMargRel[1],_aMargRel[2],_aMargRel[3],_aMargRel[4]})//7
	_oSetup:SetPropert(PD_PAPERSIZE   , _nPaperSize)//4
	_oSetup:aOptions[PD_VALUETYPE] := _cValueType//6
	_oSetup:SetPropert(PD_PREVIEW,.T.)//5
	_oSetup:SetOrderParms(_aOrdem,@_nOrdem)

	//Fecha caso o usuário cancele a tela de configuração
	If !(_oSetup:Activate() == PD_OK)//Exibe tela de Impressão
		_oPrinter:Deactivate() 
		Return
	EndIf
	//Atualiza classe FWMSPrinter com os parâmetros informado pelo usuário
	_oPrinter:SetDevice(_oSetup:GetProperty(PD_PRINTTYPE))
	If _oSetup:GetProperty(PD_ORIENTATION) == 2//paisagem
		_oPrinter:SetLandscape()
	Else
		_oPrinter:SetPortrait()
	EndIf

	_lJob := If(_lJob,.T.,(_oPrinter:lInJob .Or. _oSetup == nil))
	_oPrinter:lServer := If( _lJob , .T., _oSetup:GetProperty(PD_DESTINATION) == 1)//SERVER
	_oPrinter:SetResolution(75)
	_oPrinter:SetMargin(_oSetup:GetProperty(PD_MARGIN)[1],_oSetup:GetProperty(PD_MARGIN)[2],_oSetup:GetProperty(PD_MARGIN)[3],_oSetup:GetProperty(PD_MARGIN)[4])
	_oPrinter:SetPaperSize(9/*_oSetup:GetProperty(PD_PAPERSIZE)*/) //Forçar o papel 9 pois é o que comporta as informações

	If _lJob
		_oPrinter:nDevice := IMP_PDF
		_oPrinter:cPathPDF := Lower(If (_lJob,_cPathInServer,_oSetup:aOptions[PD_VALUETYPE]))
		_oPrinter:SetViewPDF(.F.)
		_oPrinter:lInJob := .T.
		For _nX := 1 To Len(_aPergunte)
			&("MV_PAR" + StrZero(_nX,2,0)) := _aPergunte[_nX]
		Next _nX
	ElseIf _oSetup:GetProperty(PD_PRINTTYPE) == 2 //Spool
		//_oPrinter:cPrinter := _oSetup:aOptions[PD_VALUETYPE] precisei tirar a impressão em Spool pois estava distorcendo algumas informações e não consegui resolver
		_oPrinter:nDevice := IMP_PDF
		_oPrinter:cPathPDF := Lower(_oSetup:aOptions[PD_VALUETYPE])
		_oPrinter:SetViewPDF(.T.)
		_oPrinter:SetPaperSize(9)
		_oPrinter:lInJob := .T.
		//Não consegui compatibilizar a geração em PDF e na impressora. Como não achei uma forma de não listar o spool,
		//precisei abortar a geração.
		MsgInfo("Esse relatório só pode ser gerado em PDF. Processamento abortado.","RGLT02002")
		_oPrinter:Deactivate()
		FreeObj(_oPrinter)
		_oPrinter := Nil
		Return
	ElseIf _oSetup:GetProperty(PD_PRINTTYPE) == 6//PDF
		_oPrinter:cPathPDF := Lower(_oSetup:aOptions[PD_VALUETYPE])
	EndIf

	//Salva configurações no Profile do usuário
	_oProfile:SetType("PRINTTYPE")
	_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_PRINTTYPE)))
	_oProfile:Save()
	_oProfile:SetType("ORIENTATIO")
	_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_ORIENTATION)))
	_oProfile:Save()
	_oProfile:SetType("DESTINATIO")
	_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_DESTINATION)))
	_oProfile:Save()
	_oProfile:SetType("PAPERSIZE")
	_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_PAPERSIZE)))
	_oProfile:Save()
	_oProfile:SetType("VALUETYPE")
	_oProfile:SetStringProfile(_oSetup:GetProperty(PD_VALUETYPE))
	_oProfile:Save()
EndIf

If !_lJob
	Pergunte( _cPerg , .F. )
	Processa({||RGLT020I(_oPrinter,_oExcel,_cPerg,@_lPreview,_lPdf)} , "Aguarde!" , "Selecionando registros das recepções..." )
Else
	RGLT020I(_oPrinter,_oExcel,_cPerg,@_lPreview,_lPdf)
EndIf

If _lPreview//Envia o relatório para a impressão
	If _lPdf
		_oPrinter:Preview()
	Else
		//Ativando o arquivo e gerando o xml
		_oExcel:Activate()
		_oExcel:GetXMLFile(_cDirPlan)
	EndIf
	If !_lEnvMail .And. !Empty(_cDirUser)
		CpyS2T(_cDirPlan, _cDirUser)
	EndIf
Else
	MsgInfo("Não foram encontrados registros de acordo com o parâmetro informado","RGLT02001")
EndIf

If _lPdf
	_oPrinter:Deactivate()
	FreeObj(_oPrinter)
	_oPrinter := Nil
Else
	_oExcel:DeActivate()
	FreeObj(_oExcel)
	_oExcel := Nil
EndIf

Return

/*
===============================================================================================================================
Programa----------: RGLT020I
Autor-------------: Alexandre Villar
Data da Criacao---: 13/07/2015
Descrição---------: Rotina de processamento e impressão do relatório
Parametros--------: _oPrinter,_cPerg,_lPreview
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT020I(_oPrinter As Object,_oExcel As Object,_cPerg As Character,_lPreview As Logical,_lPdf As Logical)

Local _aRet			:= {} As Array
Local _cAlias		:= GetNextAlias() As Character
Local _cFiltro		:= "%" As Character
Local _cFilSA2		:= "% %" As Character
Local _cPedido		:= '' As Character
Local _nI			:= 0 As Numeric
Local _nTam			:= 0 As Numeric
Private _nNumPag	:= 0 As Numeric
Private _cDtIni		:= '' As Character
Private _cDtFim		:= '' As Character

If MV_PAR01 == 1
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01'
	_cDtFim := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '15'
Else
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '16'
	_cDtFim := DToS( LastDay( SToD( SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01' ) ) )
EndIf

_cFiltro += IIf( MV_PAR03 == 1 , " AND SC7.C7_FORNECE  = 'F00001' ", "" )
_cFiltro += IIf( MV_PAR03 == 2 , " AND SC7.C7_FORNECE <> 'F00001' AND SubStr(SC7.C7_FORNECE,1,1) <> 'Z' ", "" )
_cFiltro += IIf( MV_PAR03 == 3 , " AND SubStr(SC7.C7_FORNECE,1,1) = 'Z' ", "" )
_cFiltro += IIf( !Empty(MV_PAR04) , " AND ZA7.ZA7_TIPPRD IN "+ FormatIn( MV_PAR04 , ';' ), "" )
_cFiltro += "%"

//Centro Leite
If MV_PAR11 == 1
	_cFilSA2 := "% AND A2_L_CENTR = '1' %"
ElseIf MV_PAR11 == 2
	_cFilSA2 := "% AND A2_L_CENTR = '2' %"
EndIf

BeginSql alias _cAlias
SELECT GERAL.ZA7_TIPPRD, GERAL.ORIGEM, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_NREDUZ, SA2.A2_RECINSS, 
       RTRIM(SA2.A2_DDD) || '-' || SA2.A2_TEL TELEFONE, RTRIM(SA2.A2_END) || ', ' || RTRIM(SA2.A2_NR_END) || SA2.A2_ENDCOMP ENDERECO,
       SA2.A2_MUN, SA2.A2_EST, SA2.A2_EMAIL, SA2.A2_CGC, SA2.A2_INSCR, SA2.A2_CONTATO, GERAL.PRC_LIQ, GERAL.C7_PRECO, GERAL.C7_PICM,
       GERAL.C7_PRODUTO, GERAL.C7_L_PMGB, GERAL.C7_L_PMGB2, GERAL.C7_L_PMEST, GERAL.C7_L_EXEMG, GERAL.C7_L_EXEM2, GERAL.C7_L_PMEST, 
	   GERAL.C7_L_EXEST, SA2.A2_L_KMLE, GERAL.PRODUTO, GERAL.VENCTO, RTRIM(GERAL.PEDIDOS) PEDIDOS, GERAL.FUNDESA
  FROM (SELECT ZA7.ZA7_TIPPRD,
               Case
                 WHEN SubStr(SC7.C7_FORNECE, 1, 1) = 'Z' THEN
                  'PLATAFORMA'
                 WHEN SC7.C7_FORNECE = 'F00001' THEN
                  'LEITE FILIAIS'
                 Else
                  'LEITE TERCEIRO'
               END ORIGEM,
               SC7.C7_FORNECE, SC7.C7_LOJA,
               SC7.C7_PRECO * DECODE(SC7.C7_PICM, 0, 1, ((100 - SC7.C7_PICM) / 100)) PRC_LIQ,
               SC7.C7_PRECO, SC7.C7_PICM, SC7.C7_PRODUTO,
               (SELECT SB1.B1_DESC
                  FROM %Table:SB1% SB1
                 WHERE SB1.D_E_L_E_T_ = ' '
                   AND SB1.B1_FILIAL = %xFilial:SB1%
                   AND SB1.B1_COD = SC7.C7_PRODUTO) PRODUTO,
               SC7.C7_L_PMGB, SC7.C7_L_PMGB2, SC7.C7_L_EXEMG, SC7.C7_L_EXEM2, SC7.C7_L_PMEST, SC7.C7_L_EXEST, 
               NVL((SELECT MAX(SE2.E2_VENCREA)
                     FROM %Table:SE2% SE2
                    WHERE SE2.D_E_L_E_T_ = ' '
                      AND SE2.E2_FILIAL = %xFilial:SE2%
                      AND SE2.E2_FORNECE = SC7.C7_FORNECE
                      AND SE2.E2_LOJA = SC7.C7_LOJA
                      AND EXISTS
                    (SELECT F1_DOC
                             FROM %Table:SF1% SF1T, %Table:SD1% SD1T
                            WHERE SF1T.D_E_L_E_T_ = ' '
							  AND SD1T.D_E_L_E_T_ = ' '
                              AND SF1T.F1_FILIAL = %xFilial:SF1%
							  AND SD1T.D1_FILIAL = SF1T.F1_FILIAL
                              AND SF1T.F1_FORNECE = SD1T.D1_FORNECE
                              AND SF1T.F1_LOJA = SD1T.D1_LOJA
                              AND SF1T.F1_DOC = SD1T.D1_DOC
							  AND SF1T.F1_STATUS = 'A'
                              AND SF1T.F1_SERIE = SD1T.D1_SERIE
                              AND SD1T.D1_NFORI = ' '
                              AND SF1T.F1_DOC = SE2.E2_NUM
                              AND SF1T.F1_FORNECE = SC7.C7_FORNECE
                              AND SF1T.F1_LOJA = SC7.C7_LOJA
                              AND SF1T.F1_FORMUL <> 'S'
                              AND SF1T.F1_TIPO = 'N'
                              AND SF1T.F1_DTDIGIT BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
                              AND SE2.E2_EMISSAO BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%)),
                   ' ') AS VENCTO,
               LISTAGG(SC7.C7_NUM, ';') WITHIN GROUP(ORDER BY SC7.C7_NUM) AS PEDIDOS, 
			   SUM(D1_VALFUND + B.F2D_VALOR) FUNDESA
          FROM %Table:SC7% SC7, %Table:ZA7% ZA7, %Table:SD1% SD1, %Table:ZLX% ZLX, %Table:ZZX% ZZX,
			(SELECT F2D_IDREL, F2D_VALOR
                  FROM %Table:F2D% F2D, %Table:F2B% F2B
                 WHERE F2D.D_E_L_E_T_ = ' '
                   AND F2B.D_E_L_E_T_ = ' '
                   AND F2D_TABELA = 'SD1'
                   AND F2D_IDCAD = F2B_ID
                   AND F2B_TRIB = 'FUNDES') B
         WHERE SC7.D_E_L_E_T_ = ' '
           AND ZA7.D_E_L_E_T_ = ' '
           AND SD1.D_E_L_E_T_ = ' '
           AND ZLX.D_E_L_E_T_ = ' '
		   AND ZZX.D_E_L_E_T_ = ' '
           AND SC7.C7_FILIAL = %xFilial:SC7%
           AND ZA7.ZA7_FILIAL = %xFilial:ZA7%
           AND SD1.D1_FILIAL = %xFilial:SD1%
           AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		   AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
           AND ZA7.ZA7_FILIAL = ZZX.ZZX_FILIAL
           AND ZA7_TIPPRD = ZZX.ZZX_CODPRD
           AND ZA7.ZA7_CODPRD = ZLX_PRODLT
           AND ZZX_CODIGO = ZLX.ZLX_CODANA
           AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
           AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
		   AND SD1.D1_IDTRIB = B.F2D_IDREL(+)
           %exp:_cFiltro%
           AND SC7.C7_EMISSAO BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
           AND SC7.C7_FORNECE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
           AND SC7.C7_LOJA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
           AND D1_FORNECE = SC7.C7_FORNECE
           AND D1_LOJA = SC7.C7_LOJA
           AND D1_PEDIDO = SC7.C7_NUM
           AND D1_COD = SC7.C7_PRODUTO
           AND ZLX_FORNEC = SC7.C7_FORNECE
           AND ZLX_LJFORN = SC7.C7_LOJA
           AND ZLX_PRODLT = SC7.C7_PRODUTO
           AND ZLX_NRONF = D1_DOC
           AND ZLX_SERINF = D1_SERIE
         GROUP BY ZA7.ZA7_TIPPRD, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_PRECO, SC7.C7_PICM, SC7.C7_L_PMGB, SC7.C7_L_PMGB2, 
		 		SC7.C7_L_PMEST, SC7.C7_L_EXEST, SC7.C7_L_EXEMG, SC7.C7_L_EXEM2, SC7.C7_PRODUTO) GERAL,
       %Table:SA2% SA2
 WHERE SA2.D_E_L_E_T_ = ' '
   AND SA2.A2_FILIAL = %xFilial:SA2%
   AND SA2.A2_COD = GERAL.C7_FORNECE
   AND SA2.A2_LOJA = GERAL.C7_LOJA
   %exp:_cFilSA2%
 ORDER BY GERAL.ORIGEM, GERAL.ZA7_TIPPRD, SA2.A2_NREDUZ
EndSql

ProcRegua(0)
While (_cAlias)->( !Eof() )

	_cPedido := ""

	_nTam	:= AT(";",AllTrim((_cAlias)->PEDIDOS))
	If _nTam == 0
		_nTam := Len(AllTrim((_cAlias)->PEDIDOS))
	EndIf
	_nI		:= 1
	If _nTam > 0
		While _nI <= Len(AllTrim((_cAlias)->PEDIDOS))
			If !(SubStr((_cAlias)->PEDIDOS,_nI,_nTam - 1) $ _cPedido)
				_cPedido += SubStr(AllTrim((_cAlias)->PEDIDOS),_nI,_nTam)
			EndIf
			_nI := _nI + _nTam
		End
	EndIf
	
	If SubStr(_cPedido, Len(_cPedido), 1) <> ";"
		_cPedido := _cPedido + ";"
	EndIf
	//Retiro o último ;, pois no FormatIn ficará ('XXX','') e o Embedded SQL irá converter em ' '
	//que irá gerar problemas posteriores
	_cPedido := SubStr(_cPedido,1,Len(_cPedido)-1)
	
	aAdd( _aRet , {				(_cAlias)->ORIGEM										,; //01 - Codigo de Produto
								(_cAlias)->A2_COD										,; //02 - Procedencia
								(_cAlias)->A2_LOJA										,; //03 - Procedencia
					AllTrim(	(_cAlias)->A2_NOME )									,; //04 - Fornecedor
					AllTrim(	(_cAlias)->A2_NREDUZ )									,; //05 - Fornecedor
					AllTrim(	(_cAlias)->TELEFONE )									,; //06 - Número do Pedido
					AllTrim(	(_cAlias)->ENDERECO )									,; //07 - Número do Pedido
					AllTrim(	(_cAlias)->A2_MUN )										,; //08 - Número do Pedido
					AllTrim(	(_cAlias)->A2_EST )										,; //09 - Número do Pedido
					AllTrim(	(_cAlias)->A2_EMAIL )									,; //10 - Número do Pedido
					AllTrim(	(_cAlias)->A2_CGC )										,; //11 - Número do Pedido
					AllTrim(	(_cAlias)->A2_INSCR )									,; //12 - Número do Pedido
					AllTrim(	(_cAlias)->A2_CONTATO )									,; //13 - Número do Pedido
			AllTrim( Transform(	(_cAlias)->PRC_LIQ		, '@E 999,999,999,999.9999' ) )	,; //14 - Pagamento Mínimo MG
			AllTrim( Transform(	(_cAlias)->C7_PRECO		, '@E 999,999,999,999.9999' ) )	,; //15 - Valor unitário do pedido
			AllTrim( Transform(	(_cAlias)->C7_PICM		, '@E 999,999,999,999.99'   ) )	,; //16 - % ICMS
								AllTrim(_cPedido )										,; //17 - Número do Pedido
					AllTrim(	(_cAlias)->PRODUTO )									,; //18 - Número do Pedido
			AllTrim( Transform(	(_cAlias)->C7_L_PMGB	, '@E 999,999,999,999.99'   ) )	,; //19 - % MG
			AllTrim( Transform(	(_cAlias)->C7_L_EXEMG	, '@E 999,999,999,999.9999' ) )	,; //20 - Preço Excedido MG
			AllTrim( Transform(	(_cAlias)->A2_L_KMLE	, '@E 999,999,999,999'		) )	,; //21
					AllTrim(    (_cAlias)->VENCTO )										,; //22
					AllTrim(    (_cAlias)->C7_PRODUTO )									,; //23
					AllTrim(	(_cAlias)->ZA7_TIPPRD )									,; //24
			AllTrim( Transform(	(_cAlias)->C7_L_PMEST	, '@E 999,999,999,999.99'   ) )	,; //25 - % EST
			AllTrim( Transform(	(_cAlias)->C7_L_EXEST	, '@E 999,999,999,999.9999' ) )	,; //26 - Preço EST
					 			(_cAlias)->A2_RECINSS									,; //27 - Calcula INSS
					 			(_cAlias)->C7_L_EXEM2									,; //28 - C7_L_EXEM2
					 			(_cAlias)->C7_L_PMGB2									,; //29 - C7_L_PMGB2
								(_cAlias)->FUNDESA										}) //30 - FUNDESA
			

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Len(_aRet) > 0
	_lPreview:= .T.
EndIf

RGLT020PRT(_aRet,_oPrinter,_oExcel,_cPerg,_lPdf)

Return

/*
===============================================================================================================================
Programa--------: RGLT020PRT
Autor-----------: Alexandre Villar
Data da Criacao-: 13/07/2015
Descrição-------: Função para controlar e imprimir os dados do relatório
Parametros------: _aDados  - Dados do relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT020PRT(_aDados As Array,_oPrinter As Object,_oExcel As Object,_cPerg As Character,_lPdf As Logical)

Local _aCabec1	:= {} As Array
Local _aCabec2	:= {} As Array
Local _aColCab	:= {} As Array
Local _aColCab2	:= {} As Array
Local _aColItn	:= {} As Array
Local _aColItn2	:= {} As Array
Local _aColDiv	:= {} As Array
Local _aItnAux	:= {} As Array
Local _aTotAux	:= {} As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:= "" As Character
Local _nLinha	:= 2 As Numeric
Local _nI		:= 0 As Numeric
Local _nX		:= 0 As Numeric
Local _nZ		:= 0 As Numeric
Local _nY		:= 0 As Numeric
Local _nValUlt	:= 0 As Numeric
Local _nDifAux	:= 0 As Numeric
Local _nLinAux	:= 0 As Numeric
Local _nTotAux	:= 0 As Numeric
Local _aNFDev	:= {} As Array
Local _nNFDTot	:= 0 As Numeric
Local _aPeds	:= {} As Array
Local _nD		:= 0 As Numeric
Local _nQuant	:= 0 As Numeric
Local _lExtrato := .F. As Logical
Local _cWorkSheet:= "" As Character
Local _cTable	:= "Transportador"
Local _nExtrato	:= 0 As Numeric
Local _nMatGExc	:= 0 As Numeric
Local _nTotPgMg	:= 0 As Numeric
Local _nFaixa	:= 0 As Numeric
Local _nDifLtr	:= 0 As Numeric
Private _oFont12	:= Nil As Object
Private _oFont08	:= Nil As Object
Private _oFont07	:= Nil As Object
Private _oFont08N	:= Nil As Object

If _lPdf
	_oFont12	:= TFontEx():New(_oPrinter,"Tahoma",16,16,.T.,.T.,.F.)
	_oFont08	:= TFontEx():New(_oPrinter,"Tahoma",10,10,.F.,.T.,.F.)
	_oFont07	:= TFontEx():New(_oPrinter,"Tahoma",09,09,.F.,.F.,.F.)
	_oFont08N	:= TFontEx():New(_oPrinter,"Tahoma",10,10,.T.,.F.,.F.)
EndIf

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
ProcRegua( Len( _aDados ) )

//====================================================================================================
// Processa a impressão dos dados
//====================================================================================================
For _nI := 1 To Len( _aDados )
	_cWorkSheet:= "Dados Transportador"+StrZero(_nI,2)
	_aCabec2:= { 'Entr. Fáb.' , 'Mov.' , ''        , '    NF' , 'Recebido' , 'Balança'  , ''         , ''        , 'Unit.' , ''        , 'Recebida' , ' Exced.' }
	If _lPdf
		_aColDiv:= {0040, 0355, 0460, 0660, 0850, 1060, 1220, 1440, 1640, 1790, 1950, 2170}
		_aColCab:= { 0100         , 0380   , 0500      , 0720     , 0900       , 1090       , 1290       , 1490      , 1690    , 1810      , 2000       , 2200      }
		_aColCab2:= {}
		_aColItn:= { 0070         , 0395   , 0500      , 0540     , 0750       , 900       , 1130       , 1330      , 1480    , 1640      , 1850       , 2130      }
	EndIf
	
	IncProc( 'Imprimindo registro: ['+ StrZero( _nI , 6 ) +'] de ['+ StrZero( Len( _aDados ) , 6 ) +']' )
	
	//====================================================================================================
	// Inicializa a página e adiciona cabecalho de conteúdo
	//====================================================================================================
	_nLinha := 5000
	RGLT020VPG( @_oPrinter, @_nLinha , ( _nI > 1 ), @_oExcel, _lPdf,  _cWorkSheet, _cTable )

	//============================================
	//Cabeçalho
	//============================================
	Cabec(_oPrinter, @_nLinha,_aDados, _nI, _oExcel, _lPdf,  _cWorkSheet, _cTable )
	

	//====================================================================================================
	// Verifica dados para imprimir a relação das entradas do fornecedor no período - GRUPO 01 - Início
	//====================================================================================================
	If _lPdf
		_oPrinter:Say( _nLinha , 060 , "> Relação das Entradas:" , _oFont12:oFont )
		_nLinha += 030
	EndIf

	_cFiltro := "% AND SD1.D1_PEDIDO  IN "+ FormatIn( _aDados[_nI][17] , ';' ) + " %"
	
	BeginSql alias _cAlias
	SELECT ZLX_DATAEN, ZLX_HRENTR, DIA_MOV, ZLX_NRONF, ZLX_VOLNF, ZLX_VOLREC, ZLX_VOLREC, ZLX_DIFVOL, ZLX_VLRNF, ZLX_ICMSNF, ZLX_PRCNF, GORDURA, EXTRATO, 
	CALC_EXT FROM (
	SELECT ZLX.ZLX_DATAEN, ZLX.ZLX_HRENTR, SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA_MOV, ZLX.ZLX_NRONF, ZLX.ZLX_VOLNF,
          ZLX.ZLX_VOLREC, ZLX.ZLX_DIFVOL, ZLX.ZLX_VLRNF, ZLX.ZLX_ICMSNF, ZLX.ZLX_PRCNF,
          NVL(Round((SELECT SUM(ZAP_GORD) / COUNT(1)
                      FROM %Table:ZAP% ZAP
                     WHERE ZAP.D_E_L_E_T_ = ' '
                       AND ZAP.ZAP_FILIAL = ZLX.ZLX_FILIAL
                       AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO),
                    2),
              0) GORDURA,
		NVL(Round((SELECT SUM(ZAP_EST) / COUNT(1)
                      FROM %Table:ZAP% ZAP
                     WHERE ZAP.D_E_L_E_T_ = ' '
                       AND ZAP.ZAP_FILIAL = ZLX.ZLX_FILIAL
                       AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO),
                    2),
              0) EXTRATO,
	NVL((SELECT 'S' FROM %Table:SC7% WHERE D_E_L_E_T_ = ' ' AND C7_FILIAL = D1_FILIAL AND C7_NUM = D1_PEDIDO AND C7_ITEM = D1_ITEMPC AND C7_L_PMEST > 0),'N') CALC_EXT
     FROM %Table:ZLX% ZLX, %Table:SD1% SD1
    WHERE ZLX.D_E_L_E_T_ = ' '
      AND SD1.D_E_L_E_T_ = ' '
      AND SD1.D1_FILIAL = %xFilial:SD1%
      AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
      AND ZLX.ZLX_FILIAL = SD1.D1_FILIAL
      AND SD1.D1_DOC = ZLX.ZLX_NRONF
      AND SD1.D1_SERIE = ZLX.ZLX_SERINF
      AND ZLX.ZLX_DATAEN <> ' '
      %exp:_cFiltro%
      AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
      AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
      AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
      AND ZLX.ZLX_PRODLT = %exp:_aDados[_nI][23]%
		)
	GROUP BY ZLX_DATAEN, ZLX_HRENTR, DIA_MOV, ZLX_NRONF, ZLX_VOLNF, ZLX_VOLREC, ZLX_VOLREC, ZLX_DIFVOL, ZLX_VLRNF, ZLX_ICMSNF, ZLX_PRCNF, GORDURA, EXTRATO, CALC_EXT
	ORDER BY ZLX_DATAEN, ZLX_NRONF
	EndSql

	_aItnAux := {}
	_aTotAux := { 'Total Geral:' ,'','',0,0,0,0,0,0,0,0,0,0 }
	_nExtrato:= 0
	_lExtrato := (_cAlias)->CALC_EXT == 'S'
	_aCabec1:= { 'Data/Hora'  , 'Dia' , 'Núm. NF' , 'Volume' , ' Volume' , 'Dif. na' , 'Valor NF' , 'ICMS NF' , 'Preço' , IIf(_lExtrato,'Teor EST','Teor MG') ,IIf(_lExtrato,'Qtd. EST','Qtd. MG') , 'Qtd. MG' }				
	
	If !_lPdf
		_cWorkSheet:="Relação de Entradas"+StrZero(_nI,2)
		_cTable:= _cWorkSheet
		//Criando Aba 2
		_oExcel:AddworkSheet(_cWorkSheet)
		//Criando a Tabela
		_oExcel:SetFontSize(14)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddTable (_cWorkSheet,_cTable,.T.)
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		//Criando Colunas
		//cWorkSheet	,cTable		,cColumm	,nAlign	,nFormat	,lTotal
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[01]+' '+_aCabec2[01],1,4,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[02]+' '+_aCabec2[02],2,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[03]+' '+_aCabec2[03],1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[04]+''+_aCabec2[04]+ " (L)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[05]+' '+_aCabec2[05]+ " (L)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[06]+' '+_aCabec2[06]+ " (L)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[07]+' '+_aCabec2[07]+ " (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[08]+' '+_aCabec2[08]+ " (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[09]+' '+_aCabec2[09]+ " (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[10]+' '+_aCabec2[10]+ " (%)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[11]+' '+_aCabec2[11]+ " (KG)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,_aCabec1[12]+' '+_aCabec2[12]+ " (KG)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Preço KG MG.",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Total Pg. MG.",3,3,.F.,)
	EndIf

	While (_cAlias)->( !Eof() )
		_nTotPgMg := 0
		_nFaixa	:= 0
		If _lPdf
			If RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf ) .Or. Empty( _aItnAux )
				_oPrinter:Box(_nLinha,040,_nLinha+080,2450)
				
				For _nX := 1 To Len( _aCabec1 )
					If Empty( _aCabec2[_nX] )
						_oPrinter:Say( _nLinha + 30 , _aColCab[_nX] , _aCabec1[_nX] , _oFont08N:oFont )
					Else
						_oPrinter:Say( _nLinha + 30 , _aColCab[_nX] , _aCabec1[_nX] , _oFont08N:oFont )
						_oPrinter:Say( _nLinha + 60 , _aColCab[_nX] , _aCabec2[_nX] , _oFont08N:oFont )
					EndIf
					_oPrinter:Line( _nLinha , _aColDiv[_nX] , _nLinha + 080 ,  _aColDiv[_nX] )
				Next _nX
				
				_nLinha += 85
				
			EndIf
		EndIf
		
		_nMatGExc	 := (_cAlias)->ZLX_VOLREC * ((_cAlias)->GORDURA-Val(StrTran(StrTran(_aDados[_nI][19],'.',''),',','.')))/ 100 // Qtd MG Excedida
		//Total Pagamento Materia Gorda por viagem
		If !_lExtrato
		 	If (_cAlias)->GORDURA > Val( StrTran(StrTran(_aDados[_nI][19],'.',''),',','.'))/*C7_L_PMGB*/ .And. (_cAlias)->GORDURA <= _aDados[_nI][29] //C7_L_PMGB2
				_nFaixa := Val(StrTran(StrTran(_aDados[_nI][20],'.',''),',','.')) //C7_L_EXEMG
			ElseIf (_cAlias)->GORDURA > _aDados[_nI][29]//C7_L_PMGB2
				_nFaixa := _aDados[_nI][28] //C7_L_EXEM2
			EndIf
			_nTotPgMg := _nMatGExc * _nFaixa
		EndIf

		aAdd( _aItnAux , {	DToC(SToD((_cAlias)->ZLX_DATAEN)) +" | "+ (_cAlias)->ZLX_HRENTR,; //Data/hora
							StrZero(Val((_cAlias)->DIA_MOV ),2),; //Dia Mov
							AllTrim((_cAlias)->ZLX_NRONF),; //Num NF
							(_cAlias)->ZLX_VOLNF,; // Volume NF
							(_cAlias)->ZLX_VOLREC,; // Volume Recebido
							(_cAlias)->ZLX_DIFVOL,; // Dif na balança
							(_cAlias)->ZLX_VLRNF,; // Valor NF
							(_cAlias)->ZLX_ICMSNF,; // ICMS NF
							(_cAlias)->ZLX_PRCNF,; // Preço Unitário
							IIf(_lExtrato,(_cAlias)->EXTRATO,(_cAlias)->GORDURA),; // Teor MG
							((_cAlias)->ZLX_VOLREC * IIf(_lExtrato,(_cAlias)->EXTRATO,(_cAlias)->GORDURA))/100,; // Qtd MG Recebida
							_nMatGExc}) //Qtd MG Excedida
		If !_lPdf
			aAdd(_aItnAux[Len(_aItnAux)],_nFaixa) //Valor da Faixa a ser considerado no cálculo do pagamento: 6 ou 12, normalmente
			aAdd(_aItnAux[Len(_aItnAux)],_nTotPgMg) //Total Pagamento Materia Gorda por viagem
		EndIf
		
		_aTotAux[04] += (_cAlias)->ZLX_VOLNF
		_aTotAux[05] += (_cAlias)->ZLX_VOLREC
		_aTotAux[06] += (_cAlias)->ZLX_DIFVOL
		_aTotAux[07] += (_cAlias)->ZLX_VLRNF
		_aTotAux[08] += (_cAlias)->ZLX_ICMSNF
		_aTotAux[09] := _aTotAux[07] / _aTotAux[04]
		_aTotAux[11] += ( (_cAlias)->ZLX_VOLREC * ( IIf(_lExtrato,(_cAlias)->EXTRATO,(_cAlias)->GORDURA) / 100 ) )
		_aTotAux[10] := ( _aTotAux[11] / _aTotAux[05] ) * 100
		_aTotAux[12] += _nMatGExc
		_aTotAux[13] += _nTotPgMg
		//Tratar quando extrato estiver igual a zero para não distorcer as informações para os cenários em que ele não é informado
		_nExtrato += ((_cAlias)->ZLX_VOLREC * (_cAlias)->EXTRATO ) / 100
		_nValUlt := (_cAlias)->ZLX_PRCNF

		If _lPdf
			For _nX := 1 To Len( _aColItn )
				If StrZero(_nX,2) $ '04,05,06'
					_oPrinter:SayAlign(_nLinha, _aColItn[_nX], AllTrim(Transform(_aItnAux[Len(_aItnAux)][_nX], '@E 999,999,999,999'))+" L", _oFont07:oFont, 300,10,,1)
				ElseIf StrZero(_nX,2) $ '07,08'
					_oPrinter:SayAlign(_nLinha, _aColItn[_nX], AllTrim(Transform(_aItnAux[Len(_aItnAux)][_nX], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
				ElseIf StrZero(_nX,2) $ '09'
					_oPrinter:SayAlign(_nLinha, _aColItn[_nX], AllTrim(Transform(_aItnAux[Len(_aItnAux)][_nX], '@E 999,999,999.9999')), _oFont07:oFont, 300,10,,1)
				ElseIf StrZero(_nX,2) $ '10'
					_oPrinter:SayAlign(_nLinha, _aColItn[_nX], AllTrim(Transform(_aItnAux[Len(_aItnAux)][_nX], '@E 999,999,999,999.99'))+" %", _oFont07:oFont, 300,10,,1)
				ElseIf StrZero(_nX,2) $ '11,12'
					_oPrinter:SayAlign(_nLinha, _aColItn[_nX], AllTrim(Transform(_aItnAux[Len(_aItnAux)][_nX], '@E 999,999,999,999.99'))+" Kg", _oFont07:oFont, 300,10,,1)
				Else
					_oPrinter:Say(_nLinha+20, _aColItn[_nX], _aItnAux[Len(_aItnAux)][_nX], _oFont07:oFont)
				EndIf
				_oPrinter:Line( _nLinha - 10 , _aColDiv[_nX] , _nLinha + 29 , _aColDiv[_nX] )
			Next _nX
			
			_oPrinter:Line( _nLinha - 10 , 2450 , _nLinha + 29 , 2450 )//Borda externa dos itens da Relação de Entradas
			_nLinha += 029
			_oPrinter:Line( _nLinha , 0040 , _nLinha , 2450 )
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,_aItnAux[Len(_aItnAux)])
		EndIf

		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If _lPdf
		_nLinha += 040
		_oPrinter:Line( _nLinha , 0040 , _nLinha , 2450 ) //Borda superior do Total Geral
		_nLinha += 010
		
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		//====================================================================================================
		// Processa a impressão dos Totalizadores
		//====================================================================================================
		For _nX := 1 To Len( _aColItn )
			Do Case
				Case _nX <= 03; _oPrinter:Say(_nLinha+15, _aColItn[_nX], _aTotAux[_nX] , _oFont07:oFont )
				Case _nX <= 06; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 999,999,999,999') +' L', _oFont07:oFont,300,10,,1)
				Case _nX <= 08; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 999,999,999,999.99'), _oFont07:oFont,300,10,,1)
				Case _nX == 09; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 999,999,999,999.9999'), _oFont07:oFont,300,10,,1)
				Case _nx == 10; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 9,999,999,999.99') + ' %', _oFont07:oFont,300,10,,1)
				Case _nx == 11; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 9,999,999,999.99') + ' Kg', _oFont07:oFont,300,10,,1)
				Case _nx == 12; _oPrinter:SayAlign(_nLinha, _aColItn[_nX], Transform(_aTotAux[_nX], '@E 9,999,999,999.99') + ' Kg', _oFont07:oFont,300,10,,1)
			EndCase
			
			If _nX == 1 .Or. _nX > 3
				_oPrinter:Line(_nLinha - 10, _aColDiv[_nX], _nLinha + 29, _aColDiv[_nX])//_oPrinter:Line(_nLinha - 20, _aColDiv[_nX], _nLinha + 18, _aColDiv[_nX])
			EndIf
			
		Next _nX
		
		_oPrinter:Line( _nLinha - 10 , 2450 , _nLinha + 29 , 2450 )//Borda externa dos itens da Relação de Entradas //_oPrinter:Line(_nLinha - 20, 2450, _nLinha + 18, 2450 )
		_nLinha += 029//_nLinha += 010
		_oPrinter:Line(_nLinha, 0040, _nLinha, 2450 )//Borda inferior do Total Geral
		
		//====================================================================================================
		// Impressão do resumo das recepções
		//====================================================================================================
		_nLinha += 060
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Say(_nLinha, 060, "Quantidade Recebida: ", _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha-30, 400, Transform( _aTotAux[05], '@E 999,999,999,999' ) +' L', _oFont08N:oFont,300,10,,1)
		
		_nLinha += 030
	Else
		_oExcel:SetFontSize(11)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{})
		_oExcel:AddRow(_cWorkSheet,_cTable,_aTotAux)
		_oExcel:AddRow(_cWorkSheet,_cTable,{})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Quantidade Recebida (L):",Transform( _aTotAux[05], '@E 999,999,999,999' )})
	EndIf

	_aPeds := StrTokArr(_aDados[_nI][17],";")
	_nQuant := 0
	For _nD := 1 To Len(_aPeds)

		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
		    SELECT C7_NUM, SUM(C7_QUANT) C7_QUANT
		      FROM %Table:SC7%
		     WHERE D_E_L_E_T_ = ' '
		       AND C7_FILIAL = %xFilial:SC7%
		       AND C7_NUM = %exp:_aPeds[_nD]%
		     GROUP BY C7_NUM
		EndSql

		While (_cAlias)->( !Eof() )
			_nQuant += (_cAlias)->C7_QUANT
			(_cAlias)->( DBSkip() )
		EndDo
		(_cAlias)->( DBCloseArea() )
	Next _nD
	If _lPdf
		_oPrinter:Say(_nLinha, 060, "Quantidade Programada (L): ", _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha-30, 400, Transform( _nQuant , '@E 999,999,999,999' ), _oFont08N:oFont,300,10,,1)
		
		_nLinha += 030
		
		_oPrinter:Say(_nLinha, 060, "Diferença de Programação (L): ", _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha-25, 400, Transform(( _aTotAux[05] - _nQuant), '@E 999,999,999,999'), _oFont08N:oFont,300,10,,1)
		_oPrinter:Say(_nLinha, 800, IIf((_aTotAux[05] - _nQuant) < 0 , 'A menor que o programado!' , '' ), _oFont08N:oFont)

		//====================================================================================================
		// Verifica dados para imprimir a relação das entradas do fornecedor no período - GRUPO 01 - Fim
		//====================================================================================================
	Else
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Quantidade Programada (L):",Transform( _nQuant , '@E 999,999,999,999' )})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Diferença de Programação (L):",Transform(( _aTotAux[05] - _nQuant), '@E 999,999,999,999'),;
						IIf((_aTotAux[05] - _nQuant) < 0 , 'A menor que o programado!' , '' )})
	EndIf
		
	If _lPdf
		//====================================================================================================
		// Força quebra de página e impressão do cabeçalho
		//====================================================================================================
		_nLinha := 5000
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		//============================================
		//Cabeçalho
		//============================================
		Cabec(_oPrinter, @_nLinha,_aDados, _nI, _oExcel, _lPdf, _cWorkSheet, _cTable )

		//====================================================================================================
		// Imprime dados da Apuração Financeira - GRUPO 02 - Início
		//====================================================================================================
		_oPrinter:Say(_nLinha, 1000, "Apuração Financeira", _oFont12:oFont)
		_nLinha += 040
		
		_oPrinter:Say(_nLinha + 0250, 1600, '_____________________________________', _oFont08N:oFont)
		_oPrinter:Say(_nLinha + 0290, 1825, 'Depto. do Leite', _oFont08N:oFont)
		
		_oPrinter:Say(_nLinha + 0550, 1600, '_____________________________________', _oFont08N:oFont)
		_oPrinter:Say(_nLinha + 0590, 1725, 'Suprimento de Leite e Fomento', _oFont08N:oFont)
		
		_oPrinter:Say(_nLinha + 0850, 1600, '_____________________________________', _oFont08N:oFont)
		_oPrinter:Say(_nLinha + 0890, 1820, 'Depto. Financeiro', _oFont08N:oFont)
	Else
		_cWorkSheet:="Apuração Financeira"+StrZero(_nI,2)
		_cTable:= _cWorkSheet
		//Criando Aba 2
		_oExcel:AddworkSheet(_cWorkSheet)
		//Criando a Tabela
		_oExcel:AddTable (_cWorkSheet,_cTable,.T.)
		//Criando Colunas
		//cWorkSheet	,cTable		,cColumm	,nAlign	,nFormat	,lTotal
		_oExcel:AddColumn(_cWorkSheet,_cTable,'',1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'',2,4,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'',3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'',3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'',3,3,.F.,)
	EndIf

	If _lPdf
		//====================================================================================================
		// Imprime quadro do fechamento de valores à pagar para o fornecedor
		//====================================================================================================
		_oPrinter:Say(_nLinha, 050, 'Valores à pagar para o fornecedor', _oFont08N:oFont)
		_nLinha += 038
		_oPrinter:Box(_nLinha-20,040,_nLinha+IIf(_aDados[_nI][27]='S',205,170),1330)	
		
		_oPrinter:Say(_nLinha,	  0050, 'Produto', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  0780, 'Quantidade', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 0780, '  recebida', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  0970, '   Preço', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 0970, 'acertado', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  1190, '  Valor', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 1190, 'a Pagar', _oFont08N:oFont)
		_nLinha -= 38
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Valores à pagar para o fornecedor","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Produto","","Quantidade Recebida (L - Kg)","Preço Acertado (R$)","Valor a Pagar (R$)"})
	EndIf

	If _aDados[_nI][24] == '004'//Creme
		_nLinAux := 080
		_nTotAux := (_aTotAux[12]*Val(StrTran(StrTran(_aDados[_nI][20],'.',''),',','.')))
	ElseIf _lExtrato
		_nLinAux := 080
		_nTotAux := (_nExtrato*Val(StrTran(StrTran(_aDados[_nI][26],'.',''),',','.')))
	Else
		_nLinAux := 100
		_nTotAux := (_aTotAux[05]*Val(StrTran(StrTran(_aDados[_nI][15],'.',''),',','.')))+_aTotAux[13]
		
		If _lPdf
			_oPrinter:Say(_nLinha + 070+25, 0050, SubStr(_aDados[_nI][18],1,47), _oFont07:oFont)
			_oPrinter:SayAlign(_nLinha + 070, 650, AllTrim(Transform(_aTotAux[05], '@E 999,999,999,999')) +' L', _oFont07:oFont,300,10,,1)
			_oPrinter:SayAlign(_nLinha + 070, 810, _aDados[_nI][15], _oFont07:oFont,300,10,,1)
			_oPrinter:SayAlign(_nLinha + 070, 1020, AllTrim(Transform(_aTotAux[05]*Val(StrTran(StrTran(_aDados[_nI][15],'.',''),',','.')),'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{_aDados[_nI][18],"",;
							_aTotAux[05],;
							Val(StrTran(StrTran(_aDados[_nI][15],'.',''),',','.')),;
							_aTotAux[05]*Val(StrTran(StrTran(_aDados[_nI][15],'.',''),',','.'))})
		EndIf
	EndIf
	If _lPdf
		_oPrinter:Say(_nLinha + _nLinAux+28, 050, 'Matéria Gorda', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 650, AllTrim(Transform(_aTotAux[12], '@E 999,999,999,999.99'))+' Kg', _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 810, AllTrim(Transform(_aTotAux[13]/_aTotAux[12],'@E 999,999,999.9999')),_oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 1020, AllTrim(Transform(_aTotAux[13],'@E 999,999,999,999.99')),_oFont07:oFont,300,10,,1)
		
		_nLinha += 30

		_oPrinter:Say(_nLinha + _nLinAux+25, 050, 'EST - Extrato Seco Total', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 650, AllTrim(Transform(_nExtrato, '@E 999,999,999,999.99'))+' Kg', _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 810, AllTrim(Transform(Val( StrTran(StrTran(_aDados[_nI][26],'.',''),',','.')),'@E 999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha + _nLinAux, 1020, AllTrim(Transform(_nExtrato*Val( StrTran( StrTran(_aDados[_nI][26],'.',''),',','.')),'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)

		_oPrinter:Line(_nLinha + 135, 0040, _nLinha + 135, 1330)
		_oPrinter:Say(_nLinha  + 135+25, 0050, 'Valor total a pagar:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha  + 135, 1020, AllTrim(Transform(_nTotAux,'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		
		If _aDados[_nI][27] =='S'//Calcula Funrural
			_nLinha += 35
			_oPrinter:Say(_nLinha  + 135+25, 0050, 'Valor total a pagar (- Funrural):', _oFont08N:oFont)
			_oPrinter:SayAlign(_nLinha  + 135, 1020, AllTrim(Transform(_nTotAux-(_nTotAux*0.015),'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		ElseIf _aDados[_nI][30] > 0//Calcula Fundesa
			_nLinha += 35
			_oPrinter:Say(_nLinha  + 135+25, 0050, 'Valor total a pagar (- Fundesa):', _oFont08N:oFont)
			_oPrinter:SayAlign(_nLinha  + 135, 1020, AllTrim(Transform(_nTotAux-(_aTotAux[05]*0.000841),'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		EndIf
	Else
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Matéria Gorda","",;
						_aTotAux[12],;
						_aTotAux[13]/_aTotAux[12],;
						_aTotAux[13]})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"EST - Extrato Seco Total","",;
						_nExtrato,;
						Val(StrTran(StrTran(_aDados[_nI][26],'.',''),',','.')),;
						_nExtrato*Val( StrTran( StrTran(_aDados[_nI][26],'.',''),',','.'))})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor total a pagar:","","","",_nTotAux})
		If _aDados[_nI][27] =='S'//Calcula Funrural
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor total a pagar (- Funrural):","","","",_nTotAux-(_nTotAux*0.015)})
		ElseIf _aDados[_nI][30] > 0//Calcula Fundesa
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor total a pagar (- Fundesa):","","","",_nTotAux-(_aTotAux[05]*0.000841)})
		EndIf
		_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","",""})
	EndIf
	If _lPdf
		//====================================================================================================
		// Imprime quadro das notas já emitidas pelo fornecedor
		//====================================================================================================
		_nLinha += 210
		_oPrinter:Say(_nLinha, 050, 'Emissão de notas fiscais do fornecedor', _oFont08N:oFont)
		_nLinha += 038
		_oPrinter:Box(_nLinha-20,040,_nLinha+110,1330)
		
		_oPrinter:Say(_nLinha,	  0050, 'Produto', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  0780, 'Quantidade', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 0780, '  faturada', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  0970, '   Preço', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 0970, 'médio NF', _oFont08N:oFont)
		_oPrinter:Say(_nLinha,	  1180, '   Valor', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 1180, 'faturado', _oFont08N:oFont)
		_nLinha += 30
		_oPrinter:Say(_nLinha + 20, 0050, SubStr(_aDados[_nI][18],1,47), _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha, 650, AllTrim(Transform(_aTotAux[04],'@E 999,999,999,999'))+' L', _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(_aTotAux[07]/_aTotAux[04],'@E 999,999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(_aTotAux[07],'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
		_nLinha += 30
		_oPrinter:Line(_nLinha, 0040, _nLinha, 1330)
		_oPrinter:Say(_nLinha+30, 0050, 'Valor total faturado:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(_aTotAux[07],'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Emissão de notas fiscais do fornecedor","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Produto","","Quantidade Faturada (L)","Preço Médio NF (R$)","Valor Faturado (R$)"})
		_oExcel:SetFontSize(11)// Tamanho da fonte.
		_oExcel:SetBold(.F.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{_aDados[_nI][18],"",;
						_aTotAux[04],;
						_aTotAux[07]/_aTotAux[04],;
						_aTotAux[07]})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor total faturado:","","","",_aTotAux[07]})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","",""})
	EndIf
	//====================================================================================================
	// Consulta dados de faturamentos de devolução já emitidos para o fornecedor
	//====================================================================================================
	_cFiltro := "% AND SD1.D1_PEDIDO  IN "+ FormatIn( _aDados[_nI][17] , ';' ) + " %"
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT SD2.D2_DOC NUMERO, SD2.D2_QUANT QTDE, SD2.D2_PRUNIT VL_UNIT, SD2.D2_TOTAL VL_TOT,
		       NVL((SELECT MAX(E2_VENCREA)
		             FROM %Table:SE2% SE2
		            WHERE SE2.D_E_L_E_T_ = ' '
		              AND SE2.E2_FILIAL = %xFilial:SE2%
		              AND SE2.E2_FILIAL = SD2.D2_FILIAL
		              AND SE2.E2_PREFIXO = SD2.D2_SERIE
		              AND SE2.E2_NUM = SD2.D2_DOC
		              AND SE2.E2_FORNECE = SD2.D2_CLIENTE
		              AND SE2.E2_LOJA = SD2.D2_LOJA),
		           ' ') VENCREA
		  FROM %Table:SD2% SD2
		 WHERE SD2.D_E_L_E_T_ = ' '
		   AND SD2.D2_FILIAL = %xFilial:SD2%
		   AND SD2.D2_TIPO IN ('B', 'D')
		   AND EXISTS
		 (SELECT 1 FROM %Table:ZLX% ZLX, %Table:SD1% SD1
		         WHERE ZLX.D_E_L_E_T_ = ' '
		           AND SD1.D_E_L_E_T_ = ' '
		           AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		           AND SD1.D1_FILIAL = %xFilial:SD1%
		           AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
		           AND SD1.D1_FILIAL = SD2.D2_FILIAL
		           AND SD1.D1_DOC = ZLX.ZLX_NRONF
		           AND SD1.D1_SERIE = ZLX.ZLX_SERINF
		           AND SD2.D2_CLIENTE = ZLX.ZLX_FORNEC
		           AND SD2.D2_LOJA = ZLX.ZLX_LJFORN
		           AND SD2.D2_NFORI = ZLX.ZLX_NRONF
		           AND SD2.D2_SERIORI = ZLX.ZLX_SERINF
		           %exp:_cFiltro%
		           AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
		           AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
		           AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
		           AND ZLX.ZLX_PRODLT = %exp:_aDados[_nI][23]%)
		   AND NOT EXISTS (SELECT 1 FROM %Table:SD1% SD11
					WHERE SD11.D_E_L_E_T_ = ' '
					AND SD2.D2_FILIAL = SD11.D1_FILIAL
					AND SD2.D2_CLIENTE = SD11.D1_FORNECE
					AND SD2.D2_LOJA = SD11.D1_LOJA
					AND SD2.D2_DOC = SD11.D1_NFORI
					AND SD2.D2_SERIE = SD11.D1_SERIORI
					AND SD2.D2_QUANT = SD11.D1_QUANT)
		 ORDER BY SD2.D2_DOC
	EndSql
		
	_aNFDev		:= {}
	_nNFDTot	:= 0
	
	While (_cAlias)->( !Eof() )
		aAdd( _aNFDev , { (_cAlias)->NUMERO , (_cAlias)->QTDE , (_cAlias)->VL_UNIT , (_cAlias)->VL_TOT , (_cAlias)->VENCREA } )
		_nNFDTot += (_cAlias)->VL_TOT
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	//====================================================================================================
	// Consulta dados de complementos já lançados do fornecedor
	//====================================================================================================
	_cFiltro := "% AND D1.D1_PEDIDO   IN "+ FormatIn( _aDados[_nI][17] , ';' ) + " %"
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		 SELECT SD1.D1_DOC NUMERO, SD1.D1_QUANT QTDE, SD1.D1_VUNIT VL_UNIT, SD1.D1_TOTAL VL_TOT,
		        NVL((SELECT MAX(E2_VENCREA)
		              FROM %Table:SE2% SE2
		             WHERE SE2.D_E_L_E_T_ = ' '
		               AND SE2.E2_FILIAL = SD1.D1_FILIAL
		               AND SE2.E2_PREFIXO = SD1.D1_SERIE
		               AND SE2.E2_NUM = SD1.D1_DOC
		               AND SE2.E2_FORNECE = SD1.D1_FORNECE
		               AND SE2.E2_LOJA = SD1.D1_LOJA),
		            ' ') VENCREA
		   FROM %Table:SD1% SD1
		  WHERE SD1.D_E_L_E_T_ = ' '
		    AND SD1.D1_FILIAL = %xFilial:SD1%
		    AND SD1.D1_TIPO IN ('N', 'C')
		    AND EXISTS
		  (SELECT 1
		           FROM %Table:ZLX% ZLX, %Table:SD1% D1
		          WHERE ZLX.D_E_L_E_T_ = ' '
		            AND D1.D_E_L_E_T_ = ' '
		            AND D1.D1_FILIAL = ZLX.ZLX_FILIAL
		            AND D1.D1_FILIAL = SD1.D1_FILIAL
		            AND D1.D1_DOC = ZLX.ZLX_NRONF
		            AND D1.D1_SERIE = ZLX.ZLX_SERINF
		            AND SD1.D1_FORNECE = ZLX.ZLX_FORNEC
		            AND SD1.D1_LOJA = ZLX.ZLX_LJFORN
		            AND SD1.D1_NFORI = ZLX.ZLX_NRONF
		            AND SD1.D1_SERIORI = ZLX.ZLX_SERINF
		            %exp:_cFiltro%
		            AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
		            AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
		            AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
		            AND ZLX.ZLX_PRODLT = %exp:_aDados[_nI][23]%)
		  ORDER BY SD1.D1_DOC
	EndSql
		
	_aNFCom		:= {}
	_nNFCTot	:= 0
	
	While (_cAlias)->( !Eof() )
		aAdd( _aNFCom , { (_cAlias)->NUMERO , (_cAlias)->QTDE , (_cAlias)->VL_UNIT , (_cAlias)->VL_TOT , (_cAlias)->VENCREA } )
		_nNFCTot += (_cAlias)->VL_TOT
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	//====================================================================================================
	// Imprime quadro do Fechamento à Devolver - Descontando as devoluções e complementos já emitidos
	//====================================================================================================
	If _lPdf
		_nLinha += 80
		_oPrinter:Say(_nLinha, 050, 'Notas fiscais de devolução a serem emitidas pela Italac ', _oFont08N:oFont)
		_nLinha += 038
		_oPrinter:Box(_nLinha-20,040,_nLinha+130,1330)
		
		_oPrinter:Say(_nLinha, 	  0050, 'Tipo de NF de Devolução', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  0780, 'Quantidade', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  1010, 'Preço', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 1010, 'Unit.', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  1230, 'Valor', _oFont08N:oFont)
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Notas fiscais de devolução a serem emitidas pela Italac","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Tipo de NF de Devolução","","Quantidade (L)","Preço Unit. (R$)","Valor (R$)"})
	EndIf	
	//====================================================================================================
	// Imprime dados da diferença de litragem à devolver para o fornecedor
	//====================================================================================================
	_nDifLtr := _aTotAux[04] - _aTotAux[05]
	
	For _nX := 1 To Len( _aNFCom )
		_nDifLtr += _aNFCom[_nX][02]
	Next _nX
	
	For _nX := 1 To Len( _aNFDev )
		_nDifLtr -= _aNFDev[_nX][02]
	Next _nX
	
	_nComAux := -( _aTotAux[04] - _aTotAux[05] ) + IIf( _nDifLtr > 0 , _nDifLtr , 0 )
	_nDifLtr := IIf( _nDifLtr > 0 , _nDifLtr , 0 )
	If _lPdf
		_nLinha += 25
		_oPrinter:Say(_nLinha + 20, 050, 'Devol. Ref. Diferença de Litragem', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha, 650, AllTrim(Transform(IIf(_nDifLtr>0,_nDifLtr,0),'@E 999,999,999,999'))+' L', _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(_nValUlt,'@E 999,999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nDifLtr>0,_nDifLtr,0)*_nValUlt,'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
	Else
		_oExcel:SetFontSize(11)// Tamanho da fonte.
		_oExcel:SetBold(.F.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Devol. Ref. Diferença de Litragem","",;
											IIf(_nDifLtr>0,_nDifLtr,0),;
											_nValUlt,;
											IIf(_nDifLtr>0,_nDifLtr,0)*_nValUlt})
	EndIf

	_nValLtr := ( IIf( _nDifLtr > 0 , _nDifLtr , 0 ) * _nValUlt )
	
	//====================================================================================================
	// Valores de Litragem complementar a ser emitida
	//====================================================================================================
	For _nX := 1 To Len( _aNFCom )
		_nComAux -= _aNFCom[_nX][02]
	Next _nX
	
	_nValAux := Val( StrTran( StrTran( _aDados[_nI][15] , '.' , '' ) , ',' , '.' ) )
	_nLtrCom := ( _nComAux * _nValAux )
	
	//====================================================================================================
	// Imprime dados da diferença de valor à devolver para o fornecedor
	//====================================================================================================
	_nDifAux := _aTotAux[07] - _nTotAux
	_nDifAux -= _nValLtr
	_nDifAux += _nLtrCom
	_nDifAux -= _nNFDTot*(1-0.015)
	
	For _nX := 1 To Len( _aNFCom )
		_nDifAux += _aNFCom[_nX][04]
	Next _nX
	_nDevVal := ( IIf( ( _aTotAux[04] - _aTotAux[05] ) > 0 , _aTotAux[04] - _aTotAux[05] , 0 ) * _nValUlt ) + IIf( _nDifAux > 0 , _nDifAux , 0 )
	_nValPen := _nDevVal - _nNFDTot*(1-0.015)

	If _lPdf
		_nLinha += 25
		_oPrinter:Say(_nLinha + 20, 0050, 'Devol. Ref. Diferença de Valor', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(IIf(_nDifAux>0,_nDifAux,0),'@E 999,999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nDifAux>0,_nDifAux,0),'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
		
		_nLinha += 30
		_oPrinter:Line(_nLinha, 0040, _nLinha, 1330)
		_oPrinter:Say(_nLinha  + 30, 0050, 'Valor pendente à devolver:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nDifAux>0,_nDifAux,0)+_nValLtr,'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
	
		//====================================================================================================
		// Imprime quadro dos dados do Fechamento
		//====================================================================================================
		_nLinha += 80
		_oPrinter:Say(_nLinha, 050, 'Notas fiscais complementares a serem emitidas pelo fornecedor', _oFont08N:oFont)
		_nLinha += 038
		_oPrinter:Box(_nLinha-20,040,_nLinha+130,1330)
		
		_oPrinter:Say(_nLinha, 	  0050, 'Tipo de NF de Complementar', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  0780, 'Quantidade', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  1010, 'Preço', _oFont08N:oFont)
		_oPrinter:Say(_nLinha+20, 1010, 'Unit.', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 	  1230, 'Valor', _oFont08N:oFont)
		_nLinha += 25
		_oPrinter:Say(_nLinha + 20, 050, 'Compl. Ref. Diferença de Litragem', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha, 650, AllTrim(Transform(IIf(_nComAux>0,_nComAux,0),'@E 999,999,999,999'))+' L', _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(IIf(_nValAux>0,_nValAux,0),'@E 999,999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nLtrCom>0,_nLtrCom,0),'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
	Else
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Devol. Ref. Diferença de Valor","","",;
						IIf(_nDifAux>0,_nDifAux,0),;
						IIf(_nDifAux>0,_nDifAux,0)})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor pendente à devolver:","","","",;
						IIf(_nDifAux>0,_nDifAux,0)+_nValLtr})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","",""})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Notas fiscais complementares a serem emitidas pelo fornecedor","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Tipo de NF de Complementar","","Quantidade (L)","Preço Unit. (R$)","Valor (R$)"})
		_oExcel:SetFontSize(11)// Tamanho da fonte.
		_oExcel:SetBold(.F.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Compl. Ref. Diferença de Litragem","",;
						IIf(_nComAux>0,_nComAux,0),;
						IIf(_nValAux>0,_nValAux,0),;
						IIf(_nLtrCom>0,_nLtrCom,0)})
	EndIf

	_nDifAux := _aTotAux[07] - _nTotAux
	_nDifAux += IIf( _nLtrCom > 0 , _nLtrCom , 0 )
	_nDifAux -= _nNFDTot*(1-0.015)
	_nDifAux -= _nValPen
	
	For _nX := 1 To Len( _aNFCom )
		_nDifAux += _aNFCom[_nX][04]
	Next _nX
	
	If _lPdf
		_nLinha += 25
		_oPrinter:Say(_nLinha + 20, 0050, 'Compl. Ref. Diferença de Valor', _oFont07:oFont)
		_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(IIf(_nDifAux<0,-_nDifAux,0),'@E 999,999,999,999.9999')), _oFont07:oFont,300,10,,1)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nDifAux<0,-_nDifAux,0),'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
		_nLinha += 30
		_oPrinter:Line(_nLinha, 0040, _nLinha, 1330)
		_oPrinter:Say(_nLinha + 30, 0050, 'Valor pendente à receber:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(IIf(_nLtrCom>0,_nLtrCom,0)+IIf(_nDifAux<0,-_nDifAux,0),'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		
		//====================================================================================================
		// Imprime quadro dos dados do Fechamento
		//====================================================================================================
		_nLinha += 80
		_oPrinter:Say(_nLinha, 250, 'Controle das notas fiscais complementares/devoluções', _oFont08N:oFont)
	Else
		_oExcel:SetFontSize(11)// Tamanho da fonte.
		_oExcel:SetBold(.F.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Compl. Ref. Diferença de Valor","","",;
						IIf(_nDifAux<0,-_nDifAux,0),;
						IIf(_nDifAux<0,-_nDifAux,0)})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Valor pendente à receber:","","","",;
						IIf(_nLtrCom>0,_nLtrCom,0)+IIf(_nDifAux<0,-_nDifAux,0)})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Controle das notas fiscais complementares/devoluções","","","",""})
	EndIf

	
	If !Empty(_aNFDev)
		If _lPdf
			_nLinha += 060
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			
			_oPrinter:Say(_nLinha, 050, 'Notas fiscais de devolução emitidas até o momento', _oFont08N:oFont)
			
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			_nLinha += 010
			_oPrinter:Line(_nLinha, 0040, _nLinha, 1330)
			_oPrinter:Line(_nLinha, 0040, _nLinha + 060, 0040)
			_oPrinter:Line(_nLinha, 1330, _nLinha + 060, 1330)
			_nLinha += 028
			_oPrinter:Say(_nLinha, 0050, 'Número', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 0400, 'Vencimento', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 0780, 'Quantidade', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 1010, 'Preço', _oFont08N:oFont)
			_oPrinter:Say(_nLinha+20, 1010, 'Unit.', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 1230, 'Valor', _oFont08N:oFont)
		Else
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Notas fiscais de devolução emitidas até o momento","","","",""})
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Número","Vencimento","Quantidade (L)","Preço Unit. (R$)","Valor (R$)"})
		EndIf
		
		For _nX := 1 To Len( _aNFDev )
			If _lPdf
				_nLinha += 30
				RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
				//====================================================================================================
				// Imprime quadro dos dados do Fechamento
				//====================================================================================================
				_oPrinter:Say(_nLinha+20, 050, _aNFDev[_nX][01], _oFont07:oFont)
				_oPrinter:Say(_nLinha+20, 400, DToC(SToD(_aNFDev[_nX][05])), _oFont07:oFont)
				_oPrinter:SayAlign(_nLinha, 650, AllTrim(Transform(_aNFDev[_nX][02],'@E 999,999,999,999')), _oFont07:oFont,300,10,,1)
				_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(_aNFDev[_nX][03],'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
				_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(_aNFDev[_nX][04],'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
				
				_oPrinter:Line(_nLinha, 0040, _nLinha + 030, 0040)
				_oPrinter:Line(_nLinha, 1330, _nLinha + 030, 1330)
			Else
				_oExcel:SetFontSize(11)// Tamanho da fonte.
				_oExcel:SetBold(.F.)// Efeito Negrito.
				_oExcel:AddRow(_cWorkSheet,_cTable,{_aNFDev[_nX][01],;
								SToD(_aNFDev[_nX][05]),;
								_aNFDev[_nX][02],;
								_aNFDev[_nX][03],;
								_aNFDev[_nX][04]})
			EndIf
		Next _nX
		
		If _lPdf
			_nLinha += 030
			_oPrinter:Box(_nLinha,040,_nLinha+040,1330)
			_oPrinter:Say(_nLinha + 030, 050, 'Total devolvido: ', _oFont08N:oFont)
			_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(_nNFDTot,'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		Else
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Total devolvido: ","","","",_nNFDTot})
		EndIf
	EndIf
		
	If !Empty(_aNFCom)
		If _lPdf
			_nLinha += 060
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			
			_oPrinter:Say(_nLinha, 050, 'Notas fiscais complementares recebidas até o momento', _oFont08N:oFont)
			
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			_nLinha += 010
			_oPrinter:Line(_nLinha, 0040, _nLinha, 1330)
			_oPrinter:Line(_nLinha, 0040, _nLinha + 060, 0040)
			_oPrinter:Line(_nLinha, 1330, _nLinha + 060, 1330)
			_nLinha += 028
			_oPrinter:Say(_nLinha, 0050, 'Número', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 0400, 'Vencimento', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 0780, 'Quantidade', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 1010, 'Preço', _oFont08N:oFont)
			_oPrinter:Say(_nLinha+20, 1010, 'Unit.', _oFont08N:oFont)
			_oPrinter:Say(_nLinha, 1230, 'Valor', _oFont08N:oFont)
		Else
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Notas fiscais complementares recebidas até o momento","","","",""})
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Número","Vencimento","Quantidade (L)","Preço Unit. (R$)","Valor (R$)"})
		EndIf
		For _nX := 1 To Len( _aNFCom )
			If _lPdf
				_nLinha += 030
				RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
				//====================================================================================================
				// Imprime quadro dos dados do Fechamento
				//====================================================================================================
				_oPrinter:Say(_nLinha+20, 0050, _aNFCom[_nX][01], _oFont07:oFont)
				_oPrinter:Say(_nLinha+20, 0400, DToC(SToD(_aNFCom[_nX][05])), _oFont07:oFont)
				_oPrinter:SayAlign(_nLinha, 650, AllTrim(Transform(_aNFCom[_nX][02],'@E 999,999,999,999')), _oFont07:oFont,300,10,,1)
				_oPrinter:SayAlign(_nLinha, 810, AllTrim(Transform(_aNFCom[_nX][03],'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
				_oPrinter:SayAlign(_nLinha, 1030, AllTrim(Transform(_aNFCom[_nX][04],'@E 999,999,999,999.99')), _oFont07:oFont,300,10,,1)
				
				_oPrinter:Line(_nLinha, 0040, _nLinha + 030, 0040)
				_oPrinter:Line(_nLinha, 1330, _nLinha + 030, 1330)
			Else
				_oExcel:SetFontSize(11)// Tamanho da fonte.
				_oExcel:SetBold(.F.)// Efeito Negrito.
				_oExcel:AddRow(_cWorkSheet,_cTable,{_aNFCom[_nX][01],;
								SToD(_aNFCom[_nX][05]),;
								_aNFCom[_nX][02],;
								_aNFCom[_nX][03],;
								_aNFCom[_nX][04]})
			EndIf
		Next _nX
		If _lPdf
			_nLinha += 030
			_oPrinter:Box(_nLinha,040,_nLinha+040,1330)
			_oPrinter:Say(_nLinha  + 030, 050, 'Total recebido: ', _oFont08N:oFont)
			_oPrinter:SayAlign(_nLinha, 1020, AllTrim(Transform(_nNFCTot,'@E 999,999,999,999.99')), _oFont08N:oFont,300,10,,1)
		Else
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Total recebido: ","","","",_nNFCTot})
			_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","",""})
		EndIf
	EndIf
	If _lPdf
		_nLinha += 100
		//====================================================================================================
		// Imprime quadro dos dados informativos ao fornecedor
		//====================================================================================================
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Say(_nLinha, 1000, 'Informativo ao Fornecedor: ', _oFont08N:oFont)
		_nLinha += 035
		
		RGLT020VPG( @_oPrinter , @_nLinha , .T. , @_oExcel, _lPdf )
		_oPrinter:Box(_nLinha-20,040,3000,2450)

		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZLY_CODIGO
			FROM %Table:ZLY%
			WHERE D_E_L_E_T_ = ' '
			AND ZLY_FILIAL = %xFilial:ZLY%
			AND ZLY_REFINI = %exp:_cDtIni%
		EndSql

		While (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->ZLY_CODIGO )
			
			DBSelectArea('ZLZ')
			ZLZ->( DBSetOrder(1) )
			If ZLZ->( DBSeek( xFilial('ZLZ') + (_cAlias)->ZLY_CODIGO ) )
				
				_cMsg := StrTran( StrTran( ZLZ->ZLZ_MSG , Chr(13) , '#' ) , Chr(10) , '' )
				_aMsg := StrTokArr( _cMsg , '#' )
				
				For _nX := 1 To Len( _aMsg )
					_cMsg := AllTrim( _aMsg[_nX] )
					If Len(_cMsg) > 200
						_nZ := 1
						While _nZ < Len(_cMsg)
							_nY := 0
							If !Empty( SubStr( _cMsg , _nZ ) )
								While SubStr( _cMsg , _nZ + 194 - _nY , 1 ) <> ' '
									If ( _nZ + 194 - _nY ) > _nZ
										_nY++
									Else
										_nY := 0
										Exit
									EndIf
								EndDo
								_oPrinter:Say( _nLinha + 005 + ( 30 * ( _nX - 1 ) ) , 060 , SubStr( _cMsg , _nZ , 195 - _nY ) , _oFont07:oFont )
							EndIf
						_nLinha	+= 030
						_nZ		+= ( 195 - _nY )
						EndDo
					Else
						_oPrinter:Say( _nLinha + 005 + ( 30 * ( _nX - 1 ) ) , 060 , _cMsg , _oFont07:oFont )
					EndIf
				Next _nX
			Else
				_oPrinter:Say(_nLinha + 005, 060, '* Sem informações adicionais *', _oFont07:oFont)
			EndIf
			
		(_cAlias)->( DBSkip() )
		EndDo
		
		(_cAlias)->( DBCloseArea() )	
	
		//====================================================================================================
		// Imprime dados da Apuração Financeira - GRUPO 02 - Fim
		//====================================================================================================
		_nLinha := 5000
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		//============================================
		//Cabeçalho
		//============================================
		Cabec(_oPrinter, @_nLinha,_aDados, _nI, _oExcel, _lPdf, _cWorkSheet, _cTable )
	EndIf

	//==============================================================================================================
	// Imprime dados de Créditos e Débitos (convênios, adiantamentos, empréstimos e antecipação) - GRUPO 03 - Início
	//==============================================================================================================
	_cAlias := GetNextAlias()
	BeginSql Alias _cAlias
    SELECT E2_FORNECE, E2_LOJA, A2_NREDUZ, E2_NUM, E2_EMISSAO, E2_VENCTO, ZT1_DESCRI EVENTO, E2_VALOR+E2_ACRESC-E2_DECRESC E2_VALOR
      FROM %Table:SE2% SE2, %Table:SA2% SA2, %Table:ZT0% ZT0, %Table:ZT1% ZT1
     WHERE SE2.D_E_L_E_T_ = ' '
       AND SA2.D_E_L_E_T_ = ' '
       AND ZT0.D_E_L_E_T_ = ' '
       AND ZT1.D_E_L_E_T_ = ' '
       AND A2_COD = E2_FORNECE
       AND A2_LOJA = E2_LOJA
       AND E2_FILIAL = ZT0_FILIAL
       AND E2_FILIAL = ZT1_FILIAL
       AND E2_FORNECE = ZT0_FORNEC
       AND E2_LOJA = ZT0_LOJA
       AND E2_NUM = ZT0_COD
       AND ZT1_COD = ZT0_EVENTO
       AND E2_FILIAL = %xFilial:SE2%
       AND E2_FORNECE = %exp:_aDados[_nI][02]%
       AND E2_LOJA = %exp:_aDados[_nI][03]%
       AND E2_VENCTO BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
       AND E2_ORIGEM = 'AGLT022'
       AND E2_TIPO = 'NF'
    UNION ALL
    SELECT E2_FORNECE, E2_LOJA, A2_NREDUZ, E2_NUM, E2_EMISSAO, E2_VENCTO, ZT1_DESCRI EVENTO, (E2_VALOR+E2_ACRESC-E2_DECRESC) * -1 E2_VALOR
      FROM %Table:SE2% SE2, %Table:SA2% SA2, %Table:ZLI% ZLI, %Table:ZT1% ZT1
     WHERE SE2.D_E_L_E_T_ = ' '
       AND ZLI.D_E_L_E_T_ = ' '
       AND SA2.D_E_L_E_T_ = ' '
       AND ZT1.D_E_L_E_T_ = ' '
       AND A2_COD = E2_FORNECE
       AND A2_LOJA = E2_LOJA
       AND E2_FILIAL = ZLI_FILIAL
       AND E2_FILIAL = ZT1_FILIAL
       AND E2_FORNECE = ZLI_RETIRO
       AND E2_LOJA = ZLI_RETILJ
       AND E2_NUM = ZLI_COD || ZLI_SEQ
       AND ZT1_COD = ZLI_EVENTO
       AND E2_FILIAL = %xFilial:SE2%
       AND E2_FORNECE = %exp:_aDados[_nI][02]%
       AND E2_LOJA = %exp:_aDados[_nI][03]%
       AND E2_VENCTO BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
       AND E2_ORIGEM = 'AGLT011'
       AND E2_TIPO = 'NDF'
    UNION ALL
    SELECT E2_FORNECE, E2_LOJA, A2_NREDUZ, E2_NUM||'-'||E2_PARCELA E2_NUM, E2_EMISSAO, E2_VENCTO,
           DECODE(ZLN_TIPO,'E','EMPRESTIMO','N','ANTECIPACAO','A','ADIANTAMENTO') EVENTO, (E2_VALOR+E2_ACRESC-E2_DECRESC) * -1 E2_VALOR
      FROM %Table:SE2% SE2, %Table:SA2% SA2, %Table:ZLN% ZLN
     WHERE SE2.D_E_L_E_T_ = ' '
       AND ZLN.D_E_L_E_T_ = ' '
       AND SA2.D_E_L_E_T_ = ' '
       AND A2_COD = E2_FORNECE
       AND A2_LOJA = E2_LOJA
       AND E2_FILIAL = ZLN_FILIAL
       AND E2_FORNECE = ZLN_SA2COD
       AND E2_LOJA = ZLN_SA2LJ
       AND E2_NUM = ZLN_COD
       AND E2_FILIAL = %xFilial:SE2%
       AND E2_FORNECE = %exp:_aDados[_nI][02]%
       AND E2_LOJA = %exp:_aDados[_nI][03]%
       AND E2_VENCTO BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
       AND E2_ORIGEM = 'AGLT016'
       AND E2_TIPO = 'NDF'
     ORDER BY 1, 2, 4, 5
	EndSql

	If _lPdf
		_oPrinter:Say( _nLinha , 060 , "> Relação de Créditos e Débitos" , _oFont12:oFont )
		_nLinha += 030
		
		_aColCab2 := { 0450 , 0850 , 1050 , 1250 , 2000 }
		_aColItn2 := { 0070 , 0460 , 0700 , 900 , 1280 , 2130 }
		
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)
		
		_oPrinter:Say(_nLinha + 028, _aColItn2[01], 'Fornecedor', _oFont08N:oFont)
		_oPrinter:Say(_nLinha + 028, _aColItn2[02], 'Número', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], 'Emissão', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], 'Vencto', _oFont08N:oFont, 300,10,,1)
		_oPrinter:Say(_nLinha + 028, _aColItn2[05], 'Evento', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, _aColItn2[06], 'Valor', _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColCab2)
			_oPrinter:Line(_nLinha, _aColCab2[_nZ], _nLinha + 040, _aColCab2[_nZ])
		Next _nZ
		_nLinha += 040
	Else
		_cWorkSheet:="Créditos e Débitos"+StrZero(_nI,2)
		_cTable:= _cWorkSheet
		//Criando Aba 2
		_oExcel:AddworkSheet(_cWorkSheet)
		_oExcel:SetFontSize(14)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		//Criando a Tabela
		_oExcel:AddTable (_cWorkSheet,_cTable,.T.)
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		//Criando Colunas
		//cWorkSheet	,cTable		,cColumm	,nAlign	,nFormat	,lTotal
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Fornecedor',1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Número',1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Emissão',3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Vencto',3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Evento',3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,'Valor (R$)',3,3,.F.,)
	EndIf

	_aResFrt := {}
	_aTotFrt := { 0 }
	
	While (_cAlias)->( !Eof() )

		If _lPdf
			//_nLinha += 030
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		EndIf

		If Len(_aResFrt) == 0
			aAdd( _aResFrt , { (_cAlias)->(E2_FORNECE+E2_LOJA) , (_cAlias)->A2_NREDUZ , 1 , _nTotAux, (_cAlias)->E2_VALOR , _nTotAux+(_cAlias)->E2_VALOR } )
		Else
			_aResFrt[01][03]++
			_aResFrt[01][04] += 0
			_aResFrt[01][05] += (_cAlias)->E2_VALOR
			_aResFrt[01][06] += (_cAlias)->E2_VALOR
		EndIf
		
		_aTotFrt[01] += (_cAlias)->E2_VALOR
		If _lPdf
			_oPrinter:Box(_nLinha,040,_nLinha+030,2450)
			
			_oPrinter:Say(_nLinha+ 025, _aColItn2[01], (_cAlias)->A2_NREDUZ, _oFont07:oFont)
			_oPrinter:Say(_nLinha+ 025, _aColItn2[02], (_cAlias)->E2_NUM, _oFont07:oFont)
			_oPrinter:SayAlign(_nLinha, _aColItn2[03], DToC( SToD((_cAlias)->E2_EMISSAO)), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[04], DToC( SToD((_cAlias)->E2_VENCTO)), _oFont07:oFont, 300,10,,1)
			_oPrinter:Say(_nLinha+ 025, _aColItn2[05], (_cAlias)->EVENTO, _oFont07:oFont)
			_oPrinter:SayAlign(_nLinha, _aColItn2[06], AllTrim(Transform((_cAlias)->E2_VALOR,'@E 999,999,999,999.99')),_oFont07:oFont, 300,10,,1)
			//Grade da tabela
			For _nZ := 1 to Len(_aColCab2)
				_oPrinter:Line(_nLinha, _aColCab2[_nZ], _nLinha + 040, _aColCab2[_nZ])
			Next _nZ
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{(_cAlias)->A2_NREDUZ,;
							(_cAlias)->E2_NUM,;
							DToC( SToD((_cAlias)->E2_EMISSAO)),;
							DToC( SToD((_cAlias)->E2_VENCTO)),;
							(_cAlias)->EVENTO,;
							(_cAlias)->E2_VALOR})
		EndIf
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If _lPdf
		_nLinha += 030
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)
		
		_oPrinter:Say(_nLinha +025, _aColItn2[01], 'Total Geral:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha-3, _aColItn2[06], AllTrim(Transform(_aTotFrt[01],'@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:Line(_nLinha, _aColCab2[01], _nLinha + 040, _aColCab2[01])
		_oPrinter:Line(_nLinha, _aColCab2[05], _nLinha + 040, _aColCab2[05])
		
		_nLinha += 100
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Say( _nLinha , 060 , "> Resumo por fornecedor" , _oFont12:oFont )
		_nLinha += 030
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_aColCab2 := { 0700 , 1110 , 1520 , 1930 }
		_aColItn2 := { 0070 , 800 , 1200 , 1600 , 2130 }
		
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)

		_oPrinter:Say(_nLinha + 028, _aColItn2[01], 'Fornecedor', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, _aColItn2[02], 'Qtd. Títulos', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], 'Vlr. Pagar (R$)', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], 'Vlr. Cred/Deb (R$)', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[05], 'Vlr. Líquido (R$)', _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColCab2)
			_oPrinter:Line(_nLinha, _aColCab2[_nZ], _nLinha + 040, _aColCab2[_nZ])
		Next _nZ
		_nLinha += 040
	Else
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Total Geral: ","","","","",_aTotFrt[01]})
			_oExcel:SetFontSize(12)// Tamanho da fonte.
			_oExcel:SetBold(.T.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Resumo por fornecedor: ","","","","",""})
			_oExcel:AddRow(_cWorkSheet,_cTable,{"Fornecedor","","Qtd. Títulos","Vlr. Pagar (R$)","Vlr. Cred/Deb (R$)","Vlr. Líquido (R$)"})
	EndIf

	_aTotFrt := { 0 , 0 , 0 , 0 }
	
	For _nX := 1 To Len( _aResFrt )
		If _lPdf
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			_oPrinter:Box(_nLinha,040,_nLinha+030,2450)
			
			_oPrinter:Say(_nLinha+ 025, _aColItn2[01], _aResFrt[_nX][02], _oFont07:oFont)
			_oPrinter:SayAlign(_nLinha, _aColItn2[02], AllTrim(Transform(_aResFrt[_nX][03], '@E 999,999,999,999')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[03], AllTrim(Transform(_aResFrt[_nX][04], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[04], AllTrim(Transform(_aResFrt[_nX][05], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[05], AllTrim(Transform(_aResFrt[_nX][06], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			//Grade da tabela
			For _nZ := 1 to Len(_aColCab2)
				_oPrinter:Line(_nLinha, _aColCab2[_nZ], _nLinha + 040, _aColCab2[_nZ])
			Next _nZ
			_nLinha += 030
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{_aResFrt[_nX][02],"",;
						_aResFrt[_nX][03],;
						_aResFrt[_nX][04],;
						_aResFrt[_nX][05],;
						_aResFrt[_nX][06]})
		EndIf
		_aTotFrt[01] += _aResFrt[_nX][03]
		_aTotFrt[02] += _aResFrt[_nX][04]
		_aTotFrt[03] += _aResFrt[_nX][05]
		_aTotFrt[04] += _aResFrt[_nX][06]
	
		If _lPdf
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		EndIf
	Next _nX
	If _lPdf
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)
		
		_oPrinter:Say(_nLinha + 025, _aColItn2[01] , 'Total:', _oFont08N:oFont)
		_oPrinter:SayAlign(_nLinha, _aColItn2[02], AllTrim(Transform(_aTotFrt[01], '@E 999,999,999,999'   )), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], AllTrim(Transform(_aTotFrt[02], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], AllTrim(Transform(_aTotFrt[03], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[05], AllTrim(Transform(_aTotFrt[04], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColCab2)
			_oPrinter:Line(_nLinha, _aColCab2[_nZ], _nLinha + 040, _aColCab2[_nZ])
		Next _nZ
		_nLinha += 150
		
		//Imprime bloco com assinaturas
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )

		_oPrinter:Say(_nLinha, 0090, "__________________________________          __________________________________          __________________________________", _oFont08N:oFont)
		_nLinha += 028
		_oPrinter:Say(_nLinha, 0300, 'Depto. do Leite'	, _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 0950, 'Suprimento de Leite e Fomento', _oFont08N:oFont)
		_oPrinter:Say(_nLinha, 1800, 'Depto. Financeiro', _oFont08N:oFont)

		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		//==============================================================================================================
		// Imprime dados de Créditos e Débitos (convênios, adiantamentos, empréstimos e antecipação) - GRUPO 03 - Fim
		//==============================================================================================================
		_nLinha := 5000
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		//============================================
		//Cabeçalho
		//============================================
		Cabec(_oPrinter, @_nLinha,_aDados, _nI, _oExcel, _lPdf, _cWorkSheet, _cTable )
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Total:","",;
					_aTotFrt[01],;
					_aTotFrt[02],;
					_aTotFrt[03],;
					_aTotFrt[04]})
	EndIf
	//====================================================================================================
	// Imprime dados da Apuração do Frete - GRUPO 04 - Início
	//====================================================================================================	
	_cFiltro := "% AND SD1.D1_PEDIDO IN "+ FormatIn(_aDados [ _nI ] [ 17 ], ';') + " %"
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT NUMERO, DIA_MOV, CTE, NREDUZ, PLACA, VLRKM, VLRFRT, PEDAGI, ICMSFR, TVLFRT, CUSTO, CHAVE, VOLUME FROM (
		SELECT ZLX.ZLX_NRONF NUMERO, SubStr(ZLX.ZLX_DTENTR, 7, 2) DIA_MOV, ZLX.ZLX_CTE CTE, SA2.A2_NREDUZ NREDUZ, ZLX.ZLX_PLACA PLACA,
		       Case
		         WHEN ZLX.ZLX_VLRKM > 0 THEN
		          ZLX.ZLX_VLRKM
		         WHEN ZZU.ZZU_KMFORN > 0 THEN
		          (ZLX.ZLX_VLRFRT / ZZU.ZZU_KMFORN)
		         Else
		          0
		       END VLRKM,
		       ZLX.ZLX_VLRFRT VLRFRT, ZLX.ZLX_PEDAGI PEDAGI, ZLX.ZLX_ICMSFR ICMSFR, ZLX.ZLX_TVLFRT TVLFRT,
		       Case
		         WHEN ZLX.ZLX_VOLREC > 0 THEN
		          ((ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI) / ZLX.ZLX_VOLREC)
		         Else
		          0
		       END CUSTO,
		       ZLX.ZLX_TRANSP || ZLX.ZLX_LJTRAN CHAVE,
		       ZLX.ZLX_VOLREC VOLUME
		  FROM %Table:ZLX% ZLX
		  JOIN %Table:SD1% SD1
		    ON SD1.D_E_L_E_T_ = ' '
		   AND SD1.D1_FILIAL = %xFilial:SD1%
		   AND ZLX.ZLX_FILIAL = SD1.D1_FILIAL
		   AND SD1.D1_DOC = ZLX.ZLX_NRONF
		   AND SD1.D1_SERIE = ZLX.ZLX_SERINF
		   %exp:_cFiltro%
		  LEFT JOIN %Table:SA2% SA2
		    ON SA2.D_E_L_E_T_ = ' '
		   AND SA2.A2_FILIAL = %xFilial:SA2%
		   AND ZLX.ZLX_TRANSP = SA2.A2_COD
		   AND ZLX.ZLX_LJTRAN = SA2.A2_LOJA
		  LEFT JOIN %Table:ZZX% ZZX
		    ON ZZX.D_E_L_E_T_ = ' '
		   AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
		   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
		   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
		  LEFT JOIN %Table:ZZV% ZZV
		    ON ZZV.D_E_L_E_T_ = ' '
		   AND ZZV.ZZV_FILIAL = %xFilial:ZZV%
		   AND ZZX.ZZX_FILIAL = ZZV.ZZV_FILIAL
		   AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
		   AND ZZV.ZZV_TRANSP = ZLX.ZLX_TRANSP
		   AND ZZV.ZZV_LJTRAN = ZLX.ZLX_LJTRAN
		  LEFT JOIN %Table:ZZU% ZZU
		    ON ZZU.D_E_L_E_T_ = ' '
		   AND ZZU.ZZU_FILIAL = %xFilial:ZZU%
		   AND ZLX.ZLX_FILIAL = ZZU.ZZU_FILIAL
		   AND ZZU.ZZU_TRANSP = ZLX.ZLX_TRANSP
		   AND ZZU.ZZU_LJTRAN = ZLX.ZLX_LJTRAN
		   AND ZZU.ZZU_CAPACI = ZZV.ZZV_FXCAPA
		   AND ZZU.ZZU_FORNEC = ZLX.ZLX_FORNEC
		   AND ZZU.ZZU_LJFORN = ZLX.ZLX_LJFORN
		 WHERE ZLX.D_E_L_E_T_ = ' '
		   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		   AND ZLX.ZLX_DTENTR BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
		   AND ZLX.ZLX_FORNEC = %exp:_aDados[_nI][02]%
		   AND ZLX.ZLX_LJFORN = %exp:_aDados[_nI][03]%
		   AND ZLX.ZLX_PRODLT = %exp:_aDados[_nI][23]%
		 ORDER BY ZLX.ZLX_DTENTR, ZLX.ZLX_CODIGO)
		 GROUP BY NUMERO, DIA_MOV, CTE, NREDUZ, PLACA, VLRKM, VLRFRT, PEDAGI, ICMSFR, TVLFRT, CUSTO, CHAVE, VOLUME
	EndSql
	_aDadFrt := {}
	
	While (_cAlias)->( !Eof() )
		aAdd( _aDadFrt , {	(_cAlias)->NUMERO		,;
							(_cAlias)->DIA_MOV		,;
							(_cAlias)->CTE			,;
							(_cAlias)->NREDUZ		,;
							(_cAlias)->PLACA		,;
							(_cAlias)->VLRKM		,;
							(_cAlias)->VLRFRT		,;
							(_cAlias)->PEDAGI		,;
							(_cAlias)->ICMSFR		,;
							(_cAlias)->TVLFRT		,;
							(_cAlias)->CUSTO		,;
							(_cAlias)->CHAVE		,;
							(_cAlias)->VOLUME		})
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	If _lPdf
		_oPrinter:Say( _nLinha , 060 , "> Apuração de Frete" , _oFont12:oFont )
		_nLinha += 030
		
		_aColDiv := {0280, 0350, 0515, 1020, 1170, 1300, 1530, 1740, 1930, 2220}
		_aColItn2 := {0070, 0290, 0355, 0520, 1050, 990, 1220, 1430, 1620, 1900, 2130}
		
		_oPrinter:Box(_nLinha,040,_nLinha+080,2450)
		
		_oPrinter:SayAlign(_nLinha, _aColItn2[01], 'Número NF', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[02], 'Dia', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha+030, _aColItn2[02], 'Mov', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], 'Núm. CTE', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], 'Transportadora', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[05], 'Placa', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[06], 'Preço', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha+030, _aColItn2[06], '/Km', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[07], 'Valor Frete', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[08], 'Pedágio', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[09], 'ICMS', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[10], 'Total Prest.', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[11], 'Custo/Litro', _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColDiv)
			_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 080, _aColDiv[_nZ])
		Next _nZ
		_nLinha += 080
	Else
		_cWorkSheet:="Apuração de Frete"+StrZero(_nI,2)
		_cTable:= _cWorkSheet
		_oExcel:SetFontSize(14)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		//Criando Aba 2
		_oExcel:AddworkSheet(_cWorkSheet)
		//Criando a Tabela
		_oExcel:AddTable (_cWorkSheet,_cTable,.T.)
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		//Criando Colunas
		//cWorkSheet	,cTable		,cColumm	,nAlign	,nFormat	,lTotal
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Número NF",1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Dia Mov",1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Núm. CTE",1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Transportadora",1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Placa",1,1,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Preço/KM (R$)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Valor Frete (R$)",3,2,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Pedágio (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"ICMS (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Total Prest. (R$)",3,3,.F.,)
		_oExcel:AddColumn(_cWorkSheet,_cTable,"Custo/Litro (R$)",3,3,.F.,)
	EndIf

	_aResFrt := {}
	_aTotFrt := { 0 , 0 , 0 , 0 , 0 , 0 }
	
	For _nX := 1 To Len( _aDadFrt )
		If _lPdf	
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		EndIf

		If ( _nPosAux := aScan( _aResFrt , {|x| x[01] == _aDadFrt[_nX][12] } ) ) == 0
			aAdd( _aResFrt , { _aDadFrt[_nX][12] , _aDadFrt[_nX][04] , 1 , _aDadFrt[_nX][13] , _aDadFrt[_nX][06] , _aDadFrt[_nX][07] , _aDadFrt[_nX][08] , _aDadFrt[_nX][09] , _aDadFrt[_nX][10] , _aDadFrt[_nX][11] } )
		Else
			_aResFrt[_nPosAux][03]++
			_aResFrt[_nPosAux][04] += _aDadFrt[_nX][13]
			_aResFrt[_nPosAux][05] += _aDadFrt[_nX][06]
			_aResFrt[_nPosAux][06] += _aDadFrt[_nX][07]
			_aResFrt[_nPosAux][07] += _aDadFrt[_nX][08]
			_aResFrt[_nPosAux][08] += _aDadFrt[_nX][09]
			_aResFrt[_nPosAux][09] += _aDadFrt[_nX][10]
		EndIf
		
		_aTotFrt[01] += _aDadFrt[_nX][06]
		_aTotFrt[02] += _aDadFrt[_nX][07]
		_aTotFrt[03] += _aDadFrt[_nX][08]
		_aTotFrt[04] += _aDadFrt[_nX][09]
		_aTotFrt[05] += _aDadFrt[_nX][10]
		_aTotFrt[06] += _aDadFrt[_nX][11]
		If _lPdf
			_oPrinter:Box(_nLinha,040,_nLinha+030,2450)

			_oPrinter:SayAlign(_nLinha, _aColItn2[01], _aDadFrt[_nX][01], _oFont07:oFont, 300,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[02], _aDadFrt[_nX][02], _oFont07:oFont, 300,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[03], _aDadFrt[_nX][03], _oFont07:oFont, 300,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[04], _aDadFrt[_nX][04], _oFont07:oFont, 600,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[05], _aDadFrt[_nX][05], _oFont07:oFont, 300,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[06], AllTrim(Transform(_aDadFrt[_nX][06],'@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[07], AllTrim(Transform(_aDadFrt[_nX][07],'@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[08], AllTrim(Transform(_aDadFrt[_nX][08],'@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[09], AllTrim(Transform(_aDadFrt[_nX][09],'@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[10], AllTrim(Transform(_aDadFrt[_nX][10],'@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[11], AllTrim(Transform(_aDadFrt[_nX][11],'@E 999,999,999,999.9999')), _oFont07:oFont, 300,10,,1)
			//Grade da tabela
			For _nZ := 1 to Len(_aColDiv)
				_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 030, _aColDiv[_nZ])
			Next _nZ
			_nLinha += 030
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{_aDadFrt[_nX][01],;
							_aDadFrt[_nX][02],;
							_aDadFrt[_nX][03],;
							_aDadFrt[_nX][04],;
							_aDadFrt[_nX][05],;
							_aDadFrt[_nX][06],;
							_aDadFrt[_nX][07],;
							_aDadFrt[_nX][08],;
							_aDadFrt[_nX][09],;
							_aDadFrt[_nX][10],;
							_aDadFrt[_nX][11]})
		EndIf
	Next _nX
	
	If _lPdf
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)
		
		_oPrinter:SayAlign(_nLinha, _aColItn2[01], 'Total Geral:', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[07], AllTrim(Transform(_aTotFrt[02], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[08], AllTrim(Transform(_aTotFrt[03], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1) 
		_oPrinter:SayAlign(_nLinha, _aColItn2[09], AllTrim(Transform(_aTotFrt[04], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1) 
		_oPrinter:SayAlign(_nLinha, _aColItn2[10], AllTrim(Transform(_aTotFrt[05], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1) 
		_oPrinter:SayAlign(_nLinha, _aColItn2[11], AllTrim(Transform(_aTotFrt[06]/Len(_aDadFrt),'@E 999,999,999,999.9999')), _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColDiv)
			If _nZ == 01 .Or. _nZ > 05
				_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 040, _aColDiv[_nZ])
			EndIf
		Next _nZ
		_nLinha += 090
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Say(_nLinha, 060, "> Resumo por transportadora", _oFont12:oFont)
		
		_nLinha += 030
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_aColDiv := {0540, 0840, 1140, 1440, 1740, 2040}
		_aColItn2 := {0070, 0530, 0830, 1130, 1430, 1720, 2130}
		
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)

		_oPrinter:SayAlign(_nLinha, _aColItn2[01], 'Transportadora', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[02], 'Qtd. Viagens', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], 'Vol. Transp.', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], 'Valor Frete', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[05], 'Pedágio', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[06], 'ICMS', _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[07], 'Total Prest.', _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColDiv)
			_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 040, _aColDiv[_nZ])
		Next _nZ
		_nLinha += 040
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Total Geral:","","","","","",;
							_aTotFrt[02],;
							_aTotFrt[03],;
							_aTotFrt[04],;
							_aTotFrt[05],;
							_aTotFrt[06]/Len(_aDadFrt)})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"","","","","","","","","","",""})
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Resumo por Transportadora","","","","","","","","","",""})
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Transportadora","","","","","Qtd. Viagens","Vol. Transp. (L)","Valor Frete (R$)","Pedágio (R$)","ICMS (R$)","Total Prest. (R$)"})
	EndIf
	_aTotFrt := { 0 , 0 , 0 , 0 , 0 , 0 }

	For _nX := 1 To Len( _aResFrt )
		If _lPdf
			RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
			
			_oPrinter:Box(_nLinha,040,_nLinha+030,2450)
			
			_oPrinter:SayAlign(_nLinha, _aColItn2[01], _aResFrt[_nX][02], _oFont07:oFont, 700,10,,0)
			_oPrinter:SayAlign(_nLinha, _aColItn2[02], AllTrim(Transform(_aResFrt[_nX][03], '@E 999,999,999,999')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[03], AllTrim(Transform(_aResFrt[_nX][04], '@E 999,999,999,999')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[04], AllTrim(Transform(_aResFrt[_nX][06], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[05], AllTrim(Transform(_aResFrt[_nX][07], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[06], AllTrim(Transform(_aResFrt[_nX][08], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			_oPrinter:SayAlign(_nLinha, _aColItn2[07], AllTrim(Transform(_aResFrt[_nX][09], '@E 999,999,999,999.99')), _oFont07:oFont, 300,10,,1)
			//Grade da tabela
			For _nZ := 1 to Len(_aColDiv)
				_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 040, _aColDiv[_nZ])
			Next _nZ
			_nLinha += 030
		Else
			_oExcel:SetFontSize(11)// Tamanho da fonte.
			_oExcel:SetBold(.F.)// Efeito Negrito.
			_oExcel:AddRow(_cWorkSheet,_cTable,{_aResFrt[_nX][02],"","","","",;
							_aResFrt[_nX][03],;
							_aResFrt[_nX][04],;
							_aResFrt[_nX][06],;
							_aResFrt[_nX][07],;
							_aResFrt[_nX][08],;
							_aResFrt[_nX][09]})
		EndIf
		_aTotFrt[01] += _aResFrt[_nX][03]
		_aTotFrt[02] += _aResFrt[_nX][04]
		_aTotFrt[03] += _aResFrt[_nX][06]
		_aTotFrt[04] += _aResFrt[_nX][07]
		_aTotFrt[05] += _aResFrt[_nX][08]
		_aTotFrt[06] += _aResFrt[_nX][09]
	Next _nX
	
	If _lPdf
		RGLT020VPG( @_oPrinter , @_nLinha , .T., @_oExcel, _lPdf )
		
		_oPrinter:Box(_nLinha,040,_nLinha+040,2450)

		_oPrinter:SayAlign(_nLinha, _aColItn2[01], 'Total:', _oFont08N:oFont, 300,10,,0)
		_oPrinter:SayAlign(_nLinha, _aColItn2[02], AllTrim(Transform(_aTotFrt[01], '@E 999,999,999,999')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[03], AllTrim(Transform(_aTotFrt[02], '@E 999,999,999,999')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[04], AllTrim(Transform(_aTotFrt[03], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[05], AllTrim(Transform(_aTotFrt[04], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[06], AllTrim(Transform(_aTotFrt[05], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		_oPrinter:SayAlign(_nLinha, _aColItn2[07], AllTrim(Transform(_aTotFrt[06], '@E 999,999,999,999.99')), _oFont08N:oFont, 300,10,,1)
		//Grade da tabela
		For _nZ := 1 to Len(_aColDiv)
			_oPrinter:Line(_nLinha, _aColDiv[_nZ], _nLinha + 040, _aColDiv[_nZ])
		Next _nZ
		//====================================================================================================
		// Imprime dados da Apuração do Frete - GRUPO 04 - Fim
		//====================================================================================================	
	Else
		_oExcel:SetFontSize(12)// Tamanho da fonte.
		_oExcel:SetBold(.T.)// Efeito Negrito.
		_oExcel:AddRow(_cWorkSheet,_cTable,{"Total: ","","","","",;
							_aTotFrt[01],;
							_aTotFrt[02],;
							_aTotFrt[03],;
							_aTotFrt[04],;
							_aTotFrt[05],;
							_aTotFrt[06]})
	EndIf
Next _nI

Return

/*
===============================================================================================================================
Programa--------: RGLT020VPG
Autor-----------: Alexandre Villar
Data da Criacao-: 29/04/2014
Descrição-------: Validação do pocicionamento da página atual para quebras
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
----------------: lFinPag	- Determina se deve encerrar a página atual
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RGLT020VPG(_oPrinter As Object,_nLinha As Numeric,_lFinPag As Logical,_oExcel As Object,_lPdf As Logical,_cWorkSheet As Character,_cTable As Character) As Logical

Local _nLimPag		:= 3000 As Numeric//limite de linhas
Local _lRet			:= .F. As Logical
Default _lFinPag	:= .T.

If _lPdf .And. _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lFinPag
		_oPrinter:EndPage()
		_lRet := .T.
	EndIf
	
	//====================================================================================================
	// Inicializa a nova página e o posicionamento
	//====================================================================================================
	_oPrinter:StartPage()
	_nLinha	:= 280
	_nNumPag++
	
	//====================================================================================================
	// Imprime quadro do Título
	//====================================================================================================
	_oPrinter:Box(-040,040,090,2450)

	//====================================================================================================
	// Insere logo no cabecalho
	//====================================================================================================
	If File( "LGRL01.BMP" )
		_oPrinter:SayBitmap( 000 , 050 , "LGRL01.BMP" , 400 , 80 )
	EndIf
		
	_oPrinter:Say( 010 , 0420 , AllTrim( SM0->M0_NOMECOM )	 							 						, _oFont12:oFont )
	_oPrinter:Say( 050 , 0420 , 'Endereço: '+		AllTrim( SM0->M0_ENDCOB		) + AllTrim( SM0->M0_COMPCOB )		, _oFont08N:oFont )
	_oPrinter:Say( 050 , 1500 , 'Bairro: '+		AllTrim( SM0->M0_BAIRCOB	)									, _oFont08N:oFont )
	_oPrinter:Say( 050 , 2000 , 'Cidade: '+		AllTrim( SM0->M0_CIDCOB		) +' / '+ AllTrim( SM0->M0_ESTCOB )	, _oFont08N:oFont )
	_oPrinter:Say( 080 , 0420 , 'Telefone: '+		AllTrim( SM0->M0_TEL		)									, _oFont08N:oFont )
	_oPrinter:Say( 080 , 1100 , 'CNPJ: '+			Transform( SM0->M0_CGC		, '@R! NN.NNN.NNN/NNNN-99' )	  		, _oFont08N:oFont )
	_oPrinter:Say( 080 , 1900 , 'Inscr.Est.: '+	AllTrim( SM0->M0_INSC )											, _oFont08N:oFont )
	
	_nLinha := 150
EndIf

If !_lPdf
	//Criando Aba 1
	_oExcel:AddworkSheet(_cWorkSheet)
	//Criando a Tabela
	_oExcel:AddTable (_cWorkSheet,_cTable,.F.)
	//Criando Colunas
	//cWorkSheet	,cTable		,cColumm	,nAlign	,nFormat	,lTotal
	_oExcel:AddColumn(_cWorkSheet,_cTable,"",1,1,.F.,)
	_oExcel:AddColumn(_cWorkSheet,_cTable,"",1,1,.F.,)
	_oExcel:AddRow(_cWorkSheet,_cTable,{AllTrim(SM0->M0_NOMECOM),})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Endereço",AllTrim(SM0->M0_ENDCOB) + AllTrim(SM0->M0_COMPCOB)})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Bairro",AllTrim(SM0->M0_BAIRCOB)})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Cidade",AllTrim(SM0->M0_CIDCOB) +' / '+ AllTrim(SM0->M0_ESTCOB)})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Telefone",AllTrim(SM0->M0_TEL)})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"CNPJ",Transform( SM0->M0_CGC,'@R! NN.NNN.NNN/NNNN-99')})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Inscr.Est.",AllTrim(SM0->M0_INSC)})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"",""})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"",""})
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: Cabec
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 11/12/2023
Descrição-------: Imprime os quadros de Fornecedor e produto
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Cabec(_oPrinter As Object,_nLinha As Numeric,_aDados As Array,_nI As Numeric,_oExcel As Object,_lPdf As Logical,_cWorkSheet As Character,_cTable As Character)

Local _cTitulo := "> Fechamento: "+ cValToChar(MV_PAR01) +"ª quinzena / "+ MesExtenso(SubStr(AllTrim(MV_PAR02),1,2));
	+" "+ SubStr(AllTrim(MV_PAR02),3,4) +" - "+ _aDados[_nI][01] As Character

If _lPdf
	_oPrinter:Say( _nLinha , 060 , _cTitulo, _oFont12:oFont )
	_nLinha += 25
	//====================================================================================================
	// Imprime quadro dos dados do Fornecedor
	//====================================================================================================
	_oPrinter:Box(_nLinha,040,_nLinha+115,2450)
	_nLinha += 025

	_oPrinter:Say(_nLinha, 0080, 'Fornecedor: '+ AllTrim(_aDados[_nI][02] +'/'+ _aDados[_nI][03]) +' - '+ AllTrim(_aDados[_nI][04]), _oFont08N:oFont)
	_oPrinter:Say(_nLinha, 1700, 'Fantasia: '+ AllTrim(_aDados[_nI][05]), _oFont08N:oFont)
	_nLinha += 035
	_oPrinter:Say(_nLinha, 0080, 'Endereço: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0240, AllTrim(_aDados[_nI][07]), _oFont07:oFont)
	_oPrinter:Say(_nLinha, 1080, 'Cidade: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1205, AllTrim(_aDados[_nI][08]) +' / '+ AllTrim(_aDados[_nI][09]), _oFont07:oFont)
	_oPrinter:Say(_nLinha, 1750, 'e-Mail: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1890, SubStr(_aDados[_nI][10],1,36), _oFont07:oFont)
	_nLinha += 035
	_oPrinter:Say(_nLinha, 0080, 'CNPJ: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0190, Transform(_aDados[_nI][11],'@R! NN.NNN.NNN/NNNN-99'), _oFont07:oFont)
	_oPrinter:Say(_nLinha, 0600, 'Inscr.Est.: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0790, AllTrim(_aDados[_nI][12]), _oFont07:oFont)
	_oPrinter:Say(_nLinha, 1200, 'Telefone: ' , _oFont08N:oFont); _oPrinter:Say(_nLinha, 1380, AllTrim(_aDados[_nI][06]), _oFont07:oFont)
	_oPrinter:Say(_nLinha, 1700, 'Contato: ' , _oFont08N:oFont); _oPrinter:Say(_nLinha, 1880, AllTrim(_aDados[_nI][13]), _oFont07:oFont)

	_nLinha += 80

	//====================================================================================================
	// Imprime quadro dos dados do Fechamento
	//====================================================================================================
	_oPrinter:Box(_nLinha,040,_nLinha+160,2450)	

	_nLinha += 025

	_oPrinter:Say(_nLinha, 0080, 'Preço Unitário: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0370, 'R$ '+ _aDados[_nI][14],_oFont07:oFont)
	_oPrinter:Say(_nLinha, 0750, 'Produto: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0930, _aDados[_nI][18],_oFont07:oFont)
	_oPrinter:Say(_nLinha, 1700, 'Km: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1800, _aDados[_nI][21],_oFont07:oFont)
	_nLinha += 035
	_oPrinter:Say(_nLinha, 0080, 'Preço Unit. + ICMS: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0430, 'R$ '+ _aDados[_nI][15],_oFont07:oFont)
	_oPrinter:Say(_nLinha, 0750, '% Mín. MG: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0950, _aDados[_nI][19] +' %',_oFont07:oFont)
	_oPrinter:Say(_nLinha, 1700, '% Mín. EST: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1920, _aDados[_nI][25] +' %',_oFont07:oFont)
	_nLinha += 035
	_oPrinter:Say(_nLinha, 0080, 'Alíquota + ICMS: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0390, _aDados[_nI][16] +' %',_oFont07:oFont)
	_oPrinter:Say(_nLinha, 0750, 'Pg. Exc. MG: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0980, 'R$ '+ _aDados[_nI][20],_oFont07:oFont)
	_oPrinter:Say(_nLinha, 1700, 'Pg. Exc. EST: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1950, 'R$ '+ _aDados[_nI][26],_oFont07:oFont)
	_nLinha += 035
	_oPrinter:Say(_nLinha, 0080, 'Pedidos: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 0230, _aDados[_nI][17], _oFont07:oFont)
	_oPrinter:Say(_nLinha, 1700, 'Vencto: ', _oFont08N:oFont); _oPrinter:Say(_nLinha, 1920, DToC(SToD(_aDados[_nI][22])), _oFont07:oFont)

	_nLinha += 100
Else
	_oExcel:AddRow(_cWorkSheet,_cTable,{_cTitulo,})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Fornecedor",AllTrim(_aDados[_nI][02] +'/'+ _aDados[_nI][03]) +' - '+ AllTrim(_aDados[_nI][04])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Fantasia",AllTrim(_aDados[_nI][05])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Endereço",AllTrim(_aDados[_nI][07])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Cidade",AllTrim(_aDados[_nI][08]) +' / '+ AllTrim(_aDados[_nI][09])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"e-Mail",AllTrim(_aDados[_nI][10])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"CNPJ",Transform(_aDados[_nI][11],'@R! NN.NNN.NNN/NNNN-99')})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Inscr. Est.",AllTrim(_aDados[_nI][12])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Telefone",AllTrim(_aDados[_nI][06])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Contato",AllTrim(_aDados[_nI][13])})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Preço Unitário",'R$ '+ _aDados[_nI][14]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Produto",_aDados[_nI][18]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"KM",_aDados[_nI][21]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Preço Unit. + ICMS",'R$ '+ _aDados[_nI][15]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"% Mín. MG",_aDados[_nI][19] +' %'})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"% Mín. EST",_aDados[_nI][25] +' %'})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Alíquota + ICMS",_aDados[_nI][16] +' %'})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Pg. Exc. MG",'R$ '+ _aDados[_nI][20]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Pg. Exc. EST",'R$ '+ _aDados[_nI][26]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Pedidos",_aDados[_nI][17]})
	_oExcel:AddRow(_cWorkSheet,_cTable,{"Vencto",DToC(SToD(_aDados[_nI][22]))})
EndIf
	
Return
