#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT035
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/08/2022
Descrição---------: Resumo de Valores - Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT035

Local oReport := Nil As Object

Pergunte("RGLT035",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/08/2022
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef() As Object

Local oReport   := Nil As Object
Local oSection  := Nil As Object
Local _aOrdem   := {"Filial+Produto"} As Array

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT035","Resumo de Valores","RGLT035",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta informações referente recepções do Leite de Terceiros")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)
oReport:nFontBody := 5
oReport:SetColSpace(0)
//oReport:SetHeaderSection(.T.)
oSection:SetHeaderPage(.T.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZZX_FILIAL","ZZX","Filial"/*cTitle*/,/*Picture*/,GetSX3Cache("ZZX_FILIAL","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,"CENTER"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_CODPRD","ZZX",/*cTitle*/,/*Picture*/,GetSX3Cache("ZZX_CODPRD","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DESCRI",/*Table*/,"Produto"/*cTitle*/,/*Picture*/,22/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_TIPOLT",/*Table*/,"Procedência"/*cTitle*/,/*Picture*/,15/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ",/*Table*/,"Fornecedor"/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_LITRO",/*Table*/,"Valor"+CRLF+"p/ Litro"/*cTitle*/,'@E 99.9999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VOLNF","ZLX"/*Table*/,"Volume"+CRLF+"Emitido"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VOLREC","ZLX"/*Table*/,"Volume"+CRLF+"Recebido"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_DIFVOL","ZLX"/*Tabela*/,"Diferença"+CRLF+"Balança"/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VLRNF","ZLX"/*Tabela*/,"Valor"+CRLF+"Faturado"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VL_A_PAGAR",/*Table*/,"Valor"+CRLF+"À Pagar"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZAP_GORD","ZAP"/*Table*/,"% Mín."+CRLF+" MG"/*cTitle*/,'@E 99.99'/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_MG_KG",/*Table*/,"Qtd."+CRLF+" MG"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_EMG_KG",/*Table*/,"Qtd.Ex."+CRLF+" MG"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_PGMG",/*Table*/,"Valor"+CRLF+"Pg. MG"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CST_LMG",/*Table*/,"Custo."+CRLF+"Lt. MG"/*cTitle*/,'@E 99.9999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZAP_EST","ZAP"/*Table*/,"% Mín."+CRLF+" EST"/*cTitle*/,'@E 99.99'/*Picture*/,5/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_EST_KG",/*Table*/,"Qtd."+CRLF+" EST"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_PGEST",/*Table*/,"Valor"+CRLF+"Pg. EST"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CST_LEST",/*Table*/,"Custo."+CRLF+"Lt. EST"/*cTitle*/,'@E 99.9999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_NFC",/*Table*/,"NFC"+CRLF+"Pendente"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_NFD",/*Table*/,"NFD"+CRLF+"Pendente"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ICMS_TOT",/*Table*/,"Result."+CRLF+"Cr. ICMS"/*cTitle*/,'@E 9,999,999.99'/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ICMS_COM",/*Table*/,"Cr. ICMS"+CRLF+"NFC"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ICMS_DEV",/*Table*/,"Déb. ICMS"+CRLF+"NFD"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_ICMSFR",/*Table*/,"Cr. ICMS"+CRLF+"Frete"/*cTitle*/,'@E 999,999.99'/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PEDANT",/*Table*/,"Pedágio"+CRLF+"Antecipado"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_FRETE",/*Table*/,"Valor"+CRLF+"Frete"/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_FRETEPED",/*Table*/,"Valor Frete"+CRLF+"+Ped.Antecip."/*cTitle*/,'@E 999,999,999.99'/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_TRNSP",/*Table*/,"Volume"+CRLF+"Transp."/*cTitle*/,'@E 999,999,999'/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CST_FRETG",/*Table*/,"C.Frete"+CRLF+"Geral"/*cTitle*/,'@E 99.9999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CST_FRETR",/*Table*/,"C.Frete"+CRLF+"Real"/*cTitle*/,'@E 99.9999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_TRNSP",/*Table*/,"Qtd."+CRLF+"Car."/*cTitle*/,'@E 999,999'/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/07/2022
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport As Object,_aOrdem As Array)

Local _cFiltro  := "%" As Character
Local _cFilDeb  := "% %" As Character
Local _cFilSD1  := "% %" As Character
Local _cFilSA2  := "% %" As Character
Local _cAlias	  := GetNextAlias() As Character
Local _aSelFil	:= {} As Array
Local _nOrdem	  := oReport:Section(1):GetOrder()  As Numeric
Local _lPlanilha:= oReport:nDevice == 4 As Logical
Local _cFilial	:= "" As Character
Local _cProduto := "" As Character
Local _cProceden := "" As Character
Local _cCampos  := "" As Character
Local _aQuebras := {'oQbrProc','oQbrProd'} As Array
Local _nX       := 0 As Numeric

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZZX")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio  |
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
oQbrProc  := TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("ZZX_CODPRD"):uPrint+oReport:Section(1):Cell("ZLX_TIPOLT"):uPrint} /*uBreak*/, {||"SubTotal: " + _cFilial + ' - '+ AllTrim(FWFilialName(cEmpAnt,_cFilial,1 ))+ ' - ' +_cProceden } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
oQbrProd  := TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZZX_CODPRD") /*uBreak*/, {||"Total Produto: " + _cFilial + ' - '+ AllTrim(FWFilialName(cEmpAnt,_cFilial,1 ))+ ' - '+ _cProduto } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)

For _nX := 1 to Len(_aQuebras)
  TRFunction():New(oReport:Section(1):Cell("VLR_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZLX_VOLNF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZLX_DIFVOL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZLX_VLRNF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VL_A_PAGAR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZAP_GORD")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("QTD_MG_KG")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("QTD_EMG_KG")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_PGMG")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("CST_LMG")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZAP_EST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("QTD_EST_KG")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_PGEST")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("CST_LEST")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_NFC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_NFD")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ICMS_TOT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ICMS_COM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ICMS_DEV")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("ZLX_ICMSFR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("PEDANT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_FRETE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VLR_FRETEPED")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("VOL_TRNSP")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("CST_FRETG")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("CST_FRETR")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
  TRFunction():New(oReport:Section(1):Cell("QTD_TRNSP")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,&(_aQuebras[_nX])/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
Next _nX

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZZX_FILIAL"):Disable()
  oReport:Section(1):Cell("ZZX_CODPRD"):Disable()
  oReport:Section(1):Cell("DESCRI"):Disable()
  oReport:Section(1):Cell("ZLX_TIPOLT"):Disable()
  oReport:Section(1):Cell("QTD_MG_KG"):Disable()
  oReport:Section(1):Cell("CST_LMG"):Disable()
  oReport:Section(1):Cell("ZAP_EST"):Disable()
  oReport:Section(1):Cell("VLR_PGEST"):Disable()
  oReport:Section(1):Cell("CST_LEST"):Disable()
  oReport:Section(1):Cell("PEDANT"):Disable()
  oReport:Section(1):Cell("VLR_FRETEPED"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZZX.ZZX_FILIAL "+ GetRngFil( _aSelFil, "ZZX", .T.,)
If !Empty(MV_PAR08)
	_cFiltro += " AND ZZX.ZZX_CODPRD IN "+ FormatIn( MV_PAR04 , ';' )
EndIf

If MV_PAR09 == 1 
	_cFiltro += " AND ZLX.ZLX_TIPOLT = 'F' "
ElseIf MV_PAR09 == 2 
	_cFiltro += " AND ZLX.ZLX_TIPOLT = 'T' "
ElseIf MV_PAR09 == 3 
 _cFiltro += " AND ZLX.ZLX_TIPOLT = 'P' "
EndIf
_cFiltro += " %"

If MV_PAR12==1
  _cFilDeb := "% (SE2.E2_ORIGEM IN ('AGLT011', 'AGLT016') AND SE2.E2_TIPO = 'NDF') OR %"
EndIf

If !Empty(MV_PAR13)
  _cFilSD1 := "% AND SD1.D1_CF NOT IN "+FormatIn(AllTrim(MV_PAR13),"/")
  _cFilSD1 += "  AND COMP.D1_CF NOT IN "+FormatIn(AllTrim(MV_PAR13),"/")+" %"
EndIf

_cCampos := "%, SA2.A2_NREDUZ %"

//Centro Leite
If MV_PAR14 == 1
	_cFilSA2 := "% AND A2_L_CENTR = '1' %"
ElseIf MV_PAR14 == 2
	_cFilSA2 := "% AND A2_L_CENTR = '2' %"
EndIf

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()

BeginSql Alias _cAlias
SELECT ZZX_FILIAL, ZZX_CODPRD, X5_DESCRI DESCRI, ZLX_TIPOLT, ORD_PRC, A2_NREDUZ, VLR_LITRO, ZLX_VOLNF, ZLX_VOLREC, ZLX_DIFVOL, ZLX_VLRNF,
       VL_A_PAGAR - (Case WHEN FUNDESA > 0 THEN Round(ZLX_VOLREC*0.000841,2) Else 0 END) VL_A_PAGAR,
        ZAP_GORD, QTD_MG_KG, QTD_EMG_KG, VLR_PGMG, CST_LMG, ZAP_EST, QTD_EST_KG, VLR_PGEST, CST_LEST, 
       Case WHEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)-VLR_NFC > 0 THEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)-VLR_NFC Else 0 END VLR_NFC, 
       Case WHEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)+ZLX_VLRNF-VL_A_PAGAR-VLR_NFD > 0 THEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)+ZLX_VLRNF-VL_A_PAGAR-VLR_NFD Else 0 END VLR_NFD, 
       ZLX_ICMSNF+VLR_ICMSC-VLR_ICMSD ICMS_TOT, 
       Case WHEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)-VLR_NFC > 0 AND D1_PICM > 0 THEN ((Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)-VLR_NFC)*D1_PICM/100 Else 0 END ICMS_COM,
       Case WHEN (Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)+ZLX_VLRNF-VL_A_PAGAR-VLR_NFD > 0 AND D1_PICM > 0 THEN ((Round((VL_A_PAGAR-VLR_PGMG)/ZLX_VOLREC,2)*ZLX_DIFVOL)+ZLX_VLRNF-VL_A_PAGAR-VLR_NFD)*D1_PICM/100 Else 0 END ICMS_DEV,
       ZLX_ICMSFR, PEDANT, VLR_FRETE, VLR_FRETEPED, VOL_TRNSP, CST_FRETG, CST_FRETR, QTD_TRNSP
       FROM (
      SELECT ZZX.ZZX_FILIAL, ZZX.ZZX_CODPRD, SX5.X5_DESCRI, ZLX.ZLX_TIPOLT,
       Case
         WHEN ZLX.ZLX_TIPOLT = 'P' THEN '1'
         WHEN ZLX.ZLX_TIPOLT = 'F' THEN '2'
         WHEN ZLX.ZLX_TIPOLT = 'T' THEN '3'
       END ORD_PRC
       , SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NREDUZ, 
      NVL(DECODE(SUM(ZLX.ZLX_VOLREC), 0, 0, Round((
        Case
            WHEN ZZX.ZZX_CODPRD = '004' THEN 0
            WHEN C7_L_EXEST > 0 THEN Round(SUM((ZLX.ZLX_VOLREC * COALESCE(Round(ZAP.ZAP_EST, 2), 0) / 100)) * C7_L_EXEST,2) /*QTD_EST_KG*/
            Else SUM(ZLX.ZLX_VOLREC * ENT.C7_PRECO)
        END +
        SUM((((ZAP.ZAP_GORD - ENT.C7_L_PMGB) * ZLX.ZLX_VOLREC) / 100) * 
            Case
                WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB AND
                      NVL(Round(ZAP_GORD, 2), 0) <= ENT.C7_L_PMGB2 THEN
                  ENT.C7_L_EXEMG
                WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB2 THEN
                  ENT.C7_L_EXEM2
                Else
                  0
              END
            )) /
            SUM(ZLX.ZLX_VOLREC),4)),0) VLR_LITRO,
       SUM(ZLX.ZLX_VOLNF) ZLX_VOLNF,
       SUM(ZLX.ZLX_VOLREC) ZLX_VOLREC,
       SUM(ZLX.ZLX_DIFVOL) ZLX_DIFVOL,
       SUM(ZLX.ZLX_VLRNF) ZLX_VLRNF,
       NVL(Round(
        Case
            WHEN ZZX.ZZX_CODPRD = '004' THEN 0
            WHEN C7_L_EXEST > 0 THEN Round(SUM((ZLX.ZLX_VOLREC * COALESCE(Round(ZAP.ZAP_EST, 2), 0) / 100)) * C7_L_EXEST,2) /*QTD_EST_KG*/
            Else SUM(ZLX.ZLX_VOLREC * ENT.C7_PRECO)
          END +
        SUM((((NVL(Round(ZAP_GORD,2),0) - ENT.C7_L_PMGB) * ZLX.ZLX_VOLREC) / 100) *
       Case
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB AND
                NVL(Round(ZAP_GORD, 2), 0) <= ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEMG
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEM2
          Else
            0
        END
       ),2),0) + NVL(AVG(FIN.E2_VALOR), 0) - NVL(SUM(FUNRURAL), 0) VL_A_PAGAR,
       Round(AVG(NVL(Round(ZAP.ZAP_GORD,2),0)),2) ZAP_GORD,
       Round(SUM((ZLX.ZLX_VOLREC * NVL(Round(ZAP.ZAP_GORD,2),0) / 100)),2) QTD_MG_KG,
       NVL(Round(SUM((((Round(ZAP.ZAP_GORD,2) - ENT.C7_L_PMGB) * ZLX.ZLX_VOLREC) / 100)), 4), 0) QTD_EMG_KG,
       NVL(Round(SUM((((Round(ZAP.ZAP_GORD,2) - ENT.C7_L_PMGB) * ZLX.ZLX_VOLREC) / 100) *
       Case
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB AND
                NVL(Round(ZAP_GORD, 2), 0) <= ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEMG
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEM2
          Else
            0
        END
       ), 2), 0) VLR_PGMG,
       NVL(DECODE(SUM(ZLX.ZLX_VOLREC), 0, 0, Round(SUM((((Round(ZAP.ZAP_GORD,2) - ENT.C7_L_PMGB) * ZLX.ZLX_VOLREC) / 100) * 
       Case
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB AND
                NVL(Round(ZAP_GORD, 2), 0) <= ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEMG
          WHEN NVL(Round(ZAP_GORD, 2), 0) > ENT.C7_L_PMGB2 THEN
            ENT.C7_L_EXEM2
          Else
            0
        END
       ) /SUM(ZLX.ZLX_VOLREC),4)),0) CST_LMG,
       Round(AVG(NVL(Round(ZAP.ZAP_EST,2),0)),2) ZAP_EST,
       Round(SUM((ZLX.ZLX_VOLREC * NVL(Round(ZAP.ZAP_EST,2),0) / 100)),2) QTD_EST_KG,
              NVL(Round(SUM((((ZAP.ZAP_EST - ENT.C7_L_PMEST) * ZLX.ZLX_VOLREC) / 100) * ENT.C7_L_EXEST), 2), 0) VLR_PGEST,
       NVL(DECODE(SUM(ZLX.ZLX_VOLREC), 0, 0, Round(SUM((((ZAP.ZAP_EST - ENT.C7_L_PMEST) * ZLX.ZLX_VOLREC) / 100) * ENT.C7_L_EXEST) /
                            SUM(ZLX.ZLX_VOLREC),4)),0) CST_LEST,
       NVL(SUM(ENT.D1_TOTAL),0) VLR_NFC,
       NVL(SUM(ENT.D2_TOTAL),0) VLR_NFD,
       NVL(SUM(ZLX.ZLX_ICMSNF), 0) ZLX_ICMSNF,
       NVL(SUM(ENT.D1_VALICM),0) VLR_ICMSC,
       NVL(SUM(ENT.D2_VALICM),0) VLR_ICMSD,
       NVL(SUM(FUNDESA),0) FUNDESA,
       ENT.D1_PICM,
       NVL(SUM(ZLX.ZLX_PEDANT),0) PEDANT,
       NVL(SUM(ZLX.ZLX_ICMSFR),0) ZLX_ICMSFR,
       NVL(SUM(ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI),0) VLR_FRETE,
       NVL(SUM(ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI + ZLX.ZLX_PEDANT),0) VLR_FRETEPED,
       SUM(Case WHEN ZZV.ZZV_PERCUR = '2' THEN ZLX_VOLREC Else 0 END ) VOL_TRNSP,
       DECODE(SUM(ZLX.ZLX_VOLREC), 0, 0, Round(SUM(ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI) / SUM(ZLX.ZLX_VOLREC), 4)) CST_FRETG,
       DECODE(SUM(Case WHEN ZZV.ZZV_PERCUR = '2' THEN ZLX_VOLREC Else 0 END ), 0, 0, Round(SUM(ZLX.ZLX_VLRFRT + ZLX.ZLX_PEDAGI) / SUM(Case WHEN ZZV.ZZV_PERCUR = '2' THEN ZLX_VOLREC Else 0 END ), 4)) CST_FRETR,
       COUNT(1) QTD_TRNSP
  FROM %Table:ZLX% ZLX, %Table:ZZX% ZZX, %Table:SA2% SA2, %Table:SX5% SX5, %Table:ZZV% ZZV,
  (SELECT ZAP.ZAP_FILIAL, ZAP.ZAP_CODIGO, AVG(ZAP.ZAP_GORD) ZAP_GORD, AVG(ZAP.ZAP_EST) ZAP_EST FROM %Table:ZAP% ZAP WHERE ZAP.D_E_L_E_T_ = ' '
          GROUP BY ZAP.ZAP_FILIAL, ZAP.ZAP_CODIGO) ZAP,
  (SELECT SD1.D1_FILIAL, SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE, SD1.D1_LOJA, SC7.C7_PRECO, SC7.C7_L_PMGB, C7_L_PMGB2, SC7.C7_L_EXEST, 
          SC7.C7_L_PMEST, SC7.C7_L_EXEMG, SC7.C7_L_EXEM2, SD1.D1_PICM, SUM(COMP.D1_TOTAL) D1_TOTAL, SUM(COMP.D1_VALICM) D1_VALICM, 
          SUM(SD2.D2_TOTAL) D2_TOTAL, SUM(SD2.D2_VALICM) D2_VALICM,
          SUM(F2D_VALOR + SD1.D1_VALFUND) FUNDESA,
          NVL(SUM(SD1.D1_VLSENAR + SD1.D1_VALFUN + SD1.D1_VALINS),0)
                       -NVL(SUM(ROUND(D2_TOTAL * 0.015, 2)),0)
                       +NVL(SUM(COMP.D1_VLSENAR + COMP.D1_VALFUN + COMP.D1_VALINS),0) FUNRURAL
       FROM %Table:SD1% SD1, %Table:SF1% SF1, %Table:SC7% SC7, %Table:SD1% COMP, %Table:SD2% SD2,
        (SELECT F2D_IDREL, F2D_VALOR FROM %Table:F2D% F2D, %Table:F2B% F2B
        WHERE F2D.D_E_L_E_T_ = ' '
        AND F2B.D_E_L_E_T_ = ' '
        AND F2D_TABELA = 'SD1'
        AND F2D_IDCAD = F2B_ID
        AND F2B_TRIB = 'FUNDES') E
       WHERE SD1.D_E_L_E_T_ = ' '
       AND SF1.D_E_L_E_T_ = ' '
       AND SC7.D_E_L_E_T_ = ' '
       AND COMP.D_E_L_E_T_ (+) = ' '
       AND SD2.D_E_L_E_T_ (+) = ' '
       AND SF1.F1_FILIAL = SD1.D1_FILIAL
       AND SF1.F1_DOC = SD1.D1_DOC
       AND SF1.F1_SERIE = SD1.D1_SERIE
       AND SF1.F1_FORNECE = SD1.D1_FORNECE
       AND SF1.F1_LOJA = SD1.D1_LOJA
       AND SF1.F1_STATUS = 'A'
       AND SF1.F1_FORMUL <> 'S'
       %exp:_cFilSD1%
       AND SD1.D1_FILIAL = SC7.C7_FILIAL
       AND SD1.D1_PEDIDO = SC7.C7_NUM
       AND SD1.D1_ITEMPC = SC7.C7_ITEM
       AND SD1.D1_FILIAL = COMP.D1_FILIAL (+)
       AND SD1.D1_FORNECE = COMP.D1_FORNECE (+)
       AND SD1.D1_LOJA = COMP.D1_LOJA (+)
       AND SD1.D1_DOC = COMP.D1_NFORI (+)
       AND SD1.D1_SERIE = COMP.D1_SERIORI (+)
       AND SD1.D1_FILIAL = SD2.D2_FILIAL (+)
       AND SD1.D1_FORNECE = SD2.D2_CLIENTE (+)
       AND SD1.D1_LOJA = SD2.D2_LOJA (+)
       AND SD1.D1_DOC = SD2.D2_NFORI (+)
       AND SD1.D1_SERIE = SD2.D2_SERIORI (+)
       AND SD1.D1_IDTRIB = E.F2D_IDREL (+)
       GROUP BY SD1.D1_FILIAL, SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE, SD1.D1_LOJA, SC7.C7_PRECO, SC7.C7_L_PMGB, SC7.C7_L_PMGB2, SC7.C7_L_EXEST,
               SC7.C7_L_PMEST, SC7.C7_L_EXEMG, SC7.C7_L_EXEM2, SD1.D1_PICM
       ) ENT,
  (SELECT SE2.E2_FILIAL, SE2.E2_FORNECE, SE2.E2_LOJA, 
       SUM(Case WHEN SE2.E2_ORIGEM = 'AGLT022' THEN SE2.E2_VALOR+SE2.E2_ACRESC-SE2.E2_DECRESC Else (SE2.E2_VALOR+SE2.E2_ACRESC-SE2.E2_DECRESC)*-1 END) E2_VALOR FROM %Table:SE2% SE2
       WHERE SE2.D_E_L_E_T_ = ' '
       AND SE2.E2_VENCTO BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
       AND (%exp:_cFilDeb% /*(SE2.E2_ORIGEM IN ('AGLT011', 'AGLT016') AND SE2.E2_TIPO = 'NDF') OR */
           (SE2.E2_ORIGEM = 'AGLT022' AND SE2.E2_TIPO = 'NF'))
     GROUP BY SE2.E2_FILIAL, SE2.E2_FORNECE, SE2.E2_LOJA) FIN
 WHERE ZLX.D_E_L_E_T_ = ' '
   AND ZZX.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND SX5.D_E_L_E_T_ = ' '
   AND ZZV.D_E_L_E_T_ (+) = ' '
   AND ZZX_CODPRD = SX5.X5_CHAVE
   AND SX5.X5_TABELA = 'Z7'
   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
   AND ZLX.ZLX_FILIAL = ZAP.ZAP_FILIAL (+)
   AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO (+)
   AND ZLX.ZLX_FILIAL = ENT.D1_FILIAL (+)
   AND ZLX.ZLX_NRONF  = ENT.D1_DOC (+)
   AND ZLX.ZLX_SERINF = ENT.D1_SERIE (+)
   AND ZLX.ZLX_FORNEC = ENT.D1_FORNECE (+)
   AND ZLX.ZLX_LJFORN = ENT.D1_LOJA (+)
   AND ZLX.ZLX_FORNEC = FIN.E2_FORNECE(+)
   AND ZLX.ZLX_LJFORN = FIN.E2_LOJA(+)
   AND ZLX.ZLX_FILIAL = FIN.E2_FILIAL(+)
   AND ZLX.ZLX_FILIAL = ZZV.ZZV_FILIAL (+)
   AND ZLX.ZLX_PLACA = ZZV.ZZV_PLACA (+)
   AND ZLX.ZLX_TRANSP = ZZV.ZZV_TRANSP (+)
   AND ZLX.ZLX_LJTRAN = ZZV.ZZV_LJTRAN (+)
   %exp:_cFiltro%
   AND ZLX.ZLX_FORNEC = SA2.A2_COD
   AND ZLX.ZLX_LJFORN = SA2.A2_LOJA
   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
   %exp:_cFilSA2%
   AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
   AND ZZX.ZZX_FORNEC BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
   AND ZZX.ZZX_LJFORN BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
 GROUP BY ZZX.ZZX_FILIAL, ZZX.ZZX_CODPRD, SX5.X5_DESCRI, ZLX.ZLX_TIPOLT, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NREDUZ, ZLX.ZLX_FORNEC, ZLX.ZLX_LJFORN, ENT.C7_L_PMGB, ENT.C7_L_PMGB2, ENT.C7_L_EXEMG, ENT.C7_L_EXEM2, ENT.C7_L_PMEST, ENT.C7_L_EXEST, ENT.C7_PRECO, ENT.D1_PICM
  ORDER BY ZZX.ZZX_CODPRD, ORD_PRC, ZZX.ZZX_FILIAL, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NREDUZ) A
EndSql

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):Init()
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(0)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
  oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZZX_FILIAL
	_cProduto := (_cAlias)->ZZX_CODPRD+' - '+AllTrim((_cAlias)->DESCRI)
  _cTipo:= oReport:Section(1):Cell("ZLX_TIPOLT"):GetCBox()
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
