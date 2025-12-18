#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: XFUNOMS
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Rotinas genéricas para utilização nos desenvolvimentos do módulo OMS
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: C_IRRF_INSS
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Função que realizar os calculos de INSS e IRRF dos relatorios de conferencia da comisao da baixa do titulo.
Parâmetros--------: _cTipo    tipo do imposto
                     _nValor   base de cálculo
Retorno-----------: _aImpostos - valor do inss, valor do irrf
===============================================================================================================================
*/
User Function C_IRRF_INSS( _cTipo , _nvalor )

Local _nPorcIRRF        := GetMv("IT_PORIRRF")
Local _aImpostos        := {}

Private _cRecibo
Private _nVlrIrrfPag	:= 	0
Private _nTeto			:=	0
Private _nbaseSest		:=	0
Private _nVlrSest 		:=	0
Private _nbaseinss		:=	0
Private _nvlrinss 		:=	0
Private _nVlrIrrf 		:= 	0
Private _x08_Lim3
Private _x08_Lim3P
Private _x09_rend1
Private _x09_rend2
Private _x09_rend3
Private _x09_rend4
Private _x09_rend5
Private _x09_aliq2
Private _x09_aliq3
Private _x09_aliq4
Private _x09_aliq5
Private _x09_parc2
Private _x09_parc3
Private _x09_parc4
Private _x09_parc5
Private _x09_deddep
Private _x09_limdep
Private _x09_retmin

//Calculos dos impostos de acordo com o cadastro do vendedor.
If _cTipo <> '3' .And. _nvalor > 0 .And. Len(AllTrim(_cTipo)) > 0

    //Gera deducao somente do imposto de IRRF
    If _cTipo == '1'
        _nVlrIrrf := _nvalor * (_nPorcIRRF / 100)
        //Valor minimo a ser cobrado sobre o IRRF.
    
        If _nVlrIrrf < 10
            _nVlrIrrf:=0
        EndIf

        aAdd(_aImpostos,{_nVlrInss,_nVlrIrrf})
    Else
        // calculo INSS
        U_ValINSS()

        _nTeto:= NoRound(_x08_Lim3 * _x08_Lim3P / 100,2)
        _nCorrentVlrINSS := _nvalor * GETMV('IT_VLRINSS') / 100

        If _nCorrentVlrINSS < _nteto
            _nvlrinss :=_nvalor * GETMV('IT_VLRINSS') / 100
        Else
            _nvlrinss :=_nteto
        EndIf

        //CALCULO DO IRRF
        // Busca dados das aliquotas nas tabelas de IRRF
        _nBaseIrrf		:= 0
        u_ValIRRF()

        _nbaseirrf		:= (_nvalor)
        _nbaseirrf		-= (_nvlrinss) // deduz INSS
        _nVlrIrrfPag	:= 0

        If _nBaseIrrf > _x09_rend1 .And. _nBaseIrrf <= _x09_rend2
            _nVlrIrrf:=_nbaseirrf * _x09_aliq2 / 100
            _nvlrIrrf-=_x09_parc2
        ElseIf _nBaseIrrf > _x09_rend2 .And. _nBaseIrrf <= _x09_rend3
            _nVlrIrrf:=_nbaseirrf * _x09_aliq3 / 100
            _nvlrIrrf-=_x09_parc3
        ElseIf _nBaseIrrf > _x09_rend3 .And. _nBaseIrrf <= _x09_rend4
            _nVlrIrrf:=_nbaseirrf * _x09_aliq4 / 100
            _nvlrIrrf-=_x09_parc4
        ElseIf _nBaseIrrf > _x09_rend4 .And. _nBaseIrrf <= _x09_rend5
            _nVlrIrrf:=_nbaseirrf * _x09_aliq5 / 100
            _nvlrIrrf-=_x09_parc5
        Else
            _nVlrIrrf:=0
        EndIf

        If _nVlrIrrf < GETMV('MV_VLRETIR')
            _nVlrIrrf:=0
        EndIf

        _nVlrIrrf  := IIf(_nVlrIrrf < 0,0,_nVlrIrrf)
        _nVlrInss  := IIf(_nVlrInss < 0,0,_nVlrInss)

        aAdd(_aImpostos,{_nVlrInss,_nVlrIrrf})
    EndIf

//Nao calcula impostos para a comissao de acordo com o cadastro
//do vendedor.                                                 
Else
    aAdd(_aImpostos,{0,0})
EndIf

Return _aImpostos

/*
===============================================================================================================================
Programa----------: VerCliSuf
Autor-------------: Guilherme Diogo
Data da Criacao---: 22/10/2012 
Descrição---------: Verifica se o cliente e SUFRAMA e exibe mensagem no pedido de venda. 
Parâmetros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function VERCLISUf()

Local cEmpCorr := cEmpAnt
Local cEmpSuf  := ""
Local cTitulo  := "Cliente SUFRAMA"
Local cTexto   := "O cliente selecionado é um cliente SUFRAMA."
Local _aArea   := FWGetArea()

SM0->(DBSeek(cEmpCorr+cFilAnt))

cEmpSuf := AllTrim(SM0->M0_INS_SUF)

SA1->(DBSetOrder(1))
If SA1->(DBSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))
    cCliSuf := AllTrim(SA1->A1_SUFRAMA)
    If cEmpSuf <> "" .And. cCliSuf <> ""
        U_ITMsg(cTexto, cTitulo,,3)
    EndIf
EndIf

FWRestArea(_aArea)

Return (M->C5_CLIENTE)

/*
===============================================================================================================================
Programa----------: NomeAut
Autor-------------: Guilherme Diogo
Data da Criacao---: 31/10/2012 
Descrição---------: Retorna o nome do autonomo 
Parâmetros--------: _cCodAuton - Codigo do Autonomo   
Retorno-----------: _cnome - Nome do Autonomo
===============================================================================================================================
*/
User Function NomeAut(_cCodAuton)

Local _cAlias := GetNextAlias()
Local _cFiltro:= "%"
Local _cNome  :=""
Local _aArea  := FWGetArea()

_cFiltro += " AND (A2_I_AUT = '" + _cCodAuton + "' OR A2_I_AUTAV = '" + _cCodAuton + "')"
_cFiltro += "%"

BeginSql alias _cAlias
SELECT
A2_NOME NOME
FROM
%Table:SA2%
WHERE
D_E_L_E_T_ = ' '
%exp:_cFiltro%
EndSql

(_cAlias)->(DBGoTop())

_cNome := (_cAlias)->NOME

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return (_cNome)

/*
===============================================================================================================================
Programa----------: ITConv
Autor-------------: Alex Wallauer
Data da Criacao---: 27/05/25 
Descrição---------: Função para conversão entre unidades de medida
Parâmetros--------: cProd - código do produto da quantidade
                    nQuant - quantidade a converter
                    nUM_Ori  - unidade de Origem   
                    nUM_Dest - unidade de Destino 
Retorno-----------: nQtdUM quantidade convertida
===============================================================================================================================
*/
User Function ITConv(cProd,nQuant,nUM_Ori,nUM_Dest)

Return U_CNUM(cProd,nQuant,nUM_Ori,nUM_Dest)
User Function CNUM(cProd,nQuant,nUM_Ori,nUM_Dest)

 Local nQtdUM  := 0
 Local nFator  := Posicione("SB1",1,xFilial("SB1")+cProd,"B1_CONV")

 If nUM_Ori = 1 // Conversão da PRIMEIRA UM para 1 e 2...
    
    Default nUM_Dest := 2
 
    If nFator = 0
        If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
            nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
        EndIf
    Else
        nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
    EndIf

    If nUM_Dest = 2// Conversão da Primeira UM para a Segunda UM
       nQtdUM:= nQuant * nFator
    
    ElseIf nUM_Dest = 3// Conversão da Primeira UM para a Terceira UM
        If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'
           nQtdUM := nQuant * nFator         // Calcula a quantidade na Segunda UM
           nQtdUM := nQtdUM / SB1->B1_I_QT3UM// Conversão da SEGUNDA UM para a Terceira UM
        Else
           nQtdUM := nQuant / SB1->B1_I_QT3UM// Conversão da PRIMEIRA UM para a Terceira UM
        EndIf
    
    EndIf
 
 ElseIf nUM_Ori = 2// Conversão da SEGUNDA UM para...
    
    Default nUM_Dest := 1

    If nFator == 0
        If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
            nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
        EndIf
    Else
        nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_CONV,SB1->B1_CONV)
    EndIf

    nQtdUM:= nQuant * nFator// Conversão da Segunda UM para a Primeira UM

    If nUM_Dest = 3// Conversão da Segunda UM para a Terceira UM
        If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'
           nQtdUM:= nQuant / SB1->B1_I_QT3UM// Conversão da SEGUNDA UM para a Terceira UM
        Else
           nQtdUM:= nQtdUM / SB1->B1_I_QT3UM// Conversão da PRIMEIRA UM para a Terceira UM
        EndIf
    EndIf
 
 
 ElseIf nUM_Ori = 3// Conversão da TERCEIRA UM para 1 ou 2...
   
    If nUM_Dest = 1//CONVERSÃO DA TERCEIRA UM PARA A PRIMEIRA UM PARA PC
       nQtdUM:= nQuant * SB1->B1_I_QT3UM// Conversão da TERCEIRA UM PARA A PRIMEIRA U.M. SEM SER PC ou SEGUNDA se For PC
       If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'
          If nFator == 0
              If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                  nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
              EndIf
          Else
              nFator := If(SB1->B1_TIPCONV=="M", 1/SB1->B1_CONV,SB1->B1_CONV)
          EndIf
          nQtdUM:= nQtdUM * nFator// SENDO PC, Temos a Conversão da Segunda UM para a Primeira UM
       EndIf
    
    ElseIf nUM_Dest = 2//CONVERSÃO DA TERCEIRA UM PARA A SEGUNDA U.M.
      If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_SEGUM = 'PC' .And. SB1->B1_I_3UM = 'CX'//SE For PC esse resultado já é a 2 U.M.
         nQtdUM:= nQuant * SB1->B1_I_QT3UM// Conversão da Terceira UM para a Segunda U.M. sendo PC
      Else
         nQtdUM:= nQuant * SB1->B1_I_QT3UM// Conversão da TERCEIRA UM PARA A PRIMEIRA U.M. SEM SER PC
         If nFator = 0
            If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
               nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
            EndIf
         Else
            nFator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
         EndIf
         nQtdUM:= nQtdUM * nFator // Conversão da Primeira UM para a Segunda UM
       EndIf
    EndIf
EndIf

Return nQtdUM

/*
===============================================================================================================================
Programa----------: VER2UM
Autor-------------: Guilherme Diogo
Data da Criacao---: 31/10/2012 
Descrição---------: Teste se produto tem segunda unidade cadastrada
Parâmetros--------: cProd - código do produto 
Retorno-----------: lret - .T. se tiver segunda unidade cadastrada
===============================================================================================================================
*/
User Function VER2UM(cProd)

lRet := .T.
nFator   := GetAdvFVal("SB1","B1_CONV",xFilial("SB1")+cProd,1,"")

If nFator == 0
    lRet := .F.
EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: RETBLQ
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/05/2016
Descrição---------: Funcao para retornar valor de campo de bloqueio de preço
Parametros--------: Nenhum
Retorno-----------: _cret - Valor do campo de bloqueio
===============================================================================================================================
/*/
User Function RETBLQ() As Char

 If aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_BLPRC"	} )]  == "L"
     Return "L"
 EndIf

Return " "

/*
===============================================================================================================================
Programa----------: BLQPRC
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/01/2009 
Descrição---------: Funcao para validar preço de venda
Parametros--------: _cProd     - Código do produto
                    _nPrcVen   - Preço praticado
                    _cFil      - Filial faturando
                    _lShow     - Mostra mensagem de faixa de preços	
                    _cTab      - Tabela de preços
                    _lTrans    - Chamando de fora da tela de pedido de vendas
                    _lUsaNovo  - NÃO USA MAIS //Obriga uso de novo esquema de tabelas de preços
                    _nFatorPrc - NÃO USA MAIS //Fator aplicado InterEstadual
                    _lVldLinha - NÃO USA MAIS
                    _cGrupoP   - Grupo de produto
                    _cUFPedV   - UF do Cliente do Pedido 
                    _lRetPrc   - NÃO É MAIS UTILIZADO - Grava os campos C6_PRCVEN / C6_I_FXPES no aCols
                    _cTpVenda  - Tipo de Venda F-Carga Fechada / V-Carga Fracionada (Varejo)
                    _lSimplNac - Cliente Optante do Simples nacional
                    _nPesoBrut - Peso Bruto do Pedido de Vendas
                    _nFaixa    - Faixa de Preço
===============================================================================================================================
Retorno-----------: _aRet - Array { T-Preço Fora/F-Preço Ok, Faixa, Msg }
===============================================================================================================================
/*/
User Function BLQPRC(_cProd     As Char   ,;
                     _nPrcVen   As Numeric,;
                     _cFil      As Char   ,;
                     _lShow     As Logical,; 
                     _cTab      As Char   ,; 
                     _lTrans    As Logical,; 
                     _lUsaNovo  As Logical,; //NÃO USA MAIS 
                     _nFatorPrc As Numeric,; //NÃO USA MAIS 
                     _lVldLinha As Logical,; //NÃO USA MAIS 
                     _cGrupoP   As Char   ,; 
                     _cUFPedV   As Char   ,; 
                     _lRetPrc   As Logical,; //NÃO É MAIS UTILIZADO 
                     _cTpVenda  As Char   ,; 
                     _lSimplNac As Logical,; 
                     _nPesoBrut As Numeric,;
                     _nFaixa    As Numeric)
    
 Local _lRet          := .F.         As Logical
 Local _nprcori       := 0           As Numeric
 Local _cTES          := ""          As Char
 Local _cCF           := ""          As Char
 Local _lB1TipoPA     := .F.         As Logical
 Local _lF4DuplicS    := .F.         As Logical
 Local _lZAYTpOprV    := .F.         As Logical
 Local _lAchou        := .F.         As Logical
 Local _aFiliais      := FWLoadSM0() As Array
 Local _cCnpj         := ""          As Char
 Local _nPrecoIt      := 0           As Numeric
 Local _cFilFat       := ""          As Char
 Local _cFilOrig      := ""          As Char
 Local _cUFFat        := ""          As Char
 Local _nI            := 0           As Numeric
 Local _cDescTBPrc    := ""          As Char
 Local _nPosPrc       := 0           As Numeric
 Local _lPortal       := .F.         As Logical
 Local _lWF           := .F.         As Logical
 Local _nPrcMin       := 0           As Numeric
 Local _nPercSimp     := 0           As Numeric
 Local _nPrecoMax     := 0           As Numeric
 Local _cRetMsg       := ""          As Char
 Local _aRet          := {}          As Array
 Local _lRegraNova    := .F.         As Logical
 Local _nFatComercial := 1           As Numeric


 If Type("M->C5_I_EST") = "C"
    Default _cProd 	   := aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"	} )]
    Default _nPrcVen   := M->C6_PRCVEN
    Default _cTab      := M->C5_I_TAB
    Default _cUFPedV   := M->C5_I_EST
    Default _cTpVenda  := M->C5_I_TPVEN //F-> Carga Fechada / V-> Carga Varejo
    Default _cFil 	   := xFilial("SC5")
 ElseIf FWIsInCallStack("U_AOMS115") .Or. FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_AOMS050")
    Default _cProd 	   := SZW->ZW_PRODUTO
    Default _nPrcVen   := SZW->ZW_PRCVEN
    Default _cTab      := SZW->ZW_TABELA
    Default _cUFPedV   := SA1->A1_EST
    Default _cTpVenda  := SZW->ZW_TPVENDA// F-> Carga Fechada / V-> Carga Varejo
    Default _cFil 	   := SZW->ZW_FILIAL
 Else
    Default _cProd 	   := SC6->C6_PRODUTO
    Default _nPrcVen   := SC6->C6_PRCVEN
    Default _cTab      := SC5->C5_I_TAB
    Default _cUFPedV   := SC5->C5_I_EST
    Default _cTpVenda  := SC5->C5_I_TPVEN // F-> Carga Fechada / V-> Carga Varejo
    Default _cFil 	   := xFilial("SC5")
 EndIf	
 Default _lShow     := .F.
 Default _lTrans    := .T. 
 Default _cGrupoP   := ""
 Default _lRetPrc   := .F.
 Default _lSimplNac := .F.
 Default _nPesoBrut :=0
 Default _nFaixa    :=0

 _lRegraNova:= !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
 _lRegraNova:= SuperGetMV("MV_ITMDREG",, _lRegraNova ) //O PARAMETRO DEVE SER CRIADO LOGICO
 _lRegraNova:= _lRegraNova .And. ZGQ->(FIELDPOS("ZGQ_LOCEMB")) > 0 .And. ZGQ->(FIELDPOS("ZGQ_SEGCLI")) 

 Begin Sequence

        _nPrecoIt := 0
        If FWIsInCallStack("U_AOMS032")  //Não valida Preço na Transferência
            _lRet 	 := .F.
            Break
        EndIf
        If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_AOMS015")
            _lPortal := .T.
        End
        If FWIsInCallStack("U_MOMS050") .Or. FWIsInCallStack("U_MOMS050R")
            _lWF := .T.
            _lPortal := .T.
        End
        If   FWIsInCallStack("U_AOMS109")
            _lShow := .F. //Não apresenta mensagens
        EndIf

        If _ltrans .And. !_lPortal .And. !_lWF//Se está na tela de pedido de vendas puxa os dados da ahead e faz teste de liberação de preços
            _nprcori 	 := aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_VLIBP"} )]
            _cTES    	 := aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_TES"	 } )]
            _cCF     	 := aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CF"	 } )]
            //Se tem liberação válida não faz validação de preço
            If M->C5_I_BLPRC = "L"  .And.  _nprcori == _nPrcVen
                _lRet 	 := .F.
                Break
            EndIf

        EndIf

        _lB1TipoPA := (Posicione( "SB1" , 1 , xFilial("SB1") + _cProd, "B1_TIPO"   ) = "PA")// JA DEIXA O SB1 PROCICIONADO
        _lF4DuplicS:= (_lPortal .Or. (Posicione( "SF4" , 1 , xFilial("SF4") + _cTES , "F4_DUPLIC" ) = "S" ))
        _lZAYTpOprV:= (_lPortal .Or. (Posicione( "ZAY" , 1 , xFilial("ZAY") + _cCF  , "ZAY_TPOPER") = "V" ))
        _cDescTBPrc:= ""
        _nPrcVen   := Round(_nPrcVen, 2)
        // Busca o grupo de produtos, caso a variável _cGrupoP esteja vazia.
        If Empty(_cGrupoP)
           _cGrupoP := SB1->B1_GRUPO
        EndIf

        DA1->(DBSetOrder(1)) //DA1_FILIAL+DA1_CODTAB+DA1_CODPRO
        _lAchou :=DA1->(DBSeek(xFilial("DA1")+_ctab+_cProd))
        
        If _lRegraNova .And. _lAchou //NOVA VALIDACAO POR CARGA FECHADA / CARGA FRACIONADA
           
           DA0->(DBSetOrder(1))
           DA0->(DBSeek(xFilial("DA0")+DA1->DA1_CODTAB))
           _cDescTBPrc:= AllTrim(DA1->DA1_CODTAB) + " - " + AllTrim(DA0->DA0_DESCRI)
           _nPrecoMax := DA1->DA1_PRCMAX

            // Obtem a filial de faturamento.
            If FWIsInCallStack("MATA410")
                _cFilFat  := M->C5_I_FILFT
                If Empty(_cFilFat)
                    _cFilFat := M->C5_FILIAL
                    If Empty(_cFilFat) .And. Inclui
                        _cFilFat := xFilial("SC5")
                    EndIf
                EndIf
            Else
                _cFilFat := _cFil
            EndIf

            _cUFFat:= Posicione("ZZM",1,xFilial("ZZM")+_cFilFat,"ZZM_EST")
            If AllTrim(_cUFFat) == AllTrim(_cUFPedV) // UF Fat = UF CLIENTE
               _nFatComercial := 1
            Else// UF Fat <> UF CLIENTE
               _cRegraFatC:=""
               _nFatComercial := BuscaFatComercial(_cFilFat, _cUFPedV, _cProd, _cGrupoP, @_cRegraFatC) // Carrega fator de conversão para calculo do maior preços de vendas.
            EndIf

           If _cTpVenda  = "F" //F-> Carga Fechada
              _nPrecoIt := (DA1->DA1_I_PRF1 / _nFatComercial)
              _nPrcMin  := (DA1->DA1_I_PMF1 / _nFatComercial)
           ElseIf _cTpVenda  = "V" //V-> Carga Varejo / Fracionada
              _nPrecoIt := (DA1->DA1_I_PRF2 / _nFatComercial)
              _nPrcMin  := (DA1->DA1_I_PMF2 / _nFatComercial)
           EndIf

            If _lSimplNac
                _nPercSimp := 1 + (DA1->DA1_I_SIMP / 100)
                _nPrecoIt := NoRound((_nPrecoIt * _nPercSimp),2)
            EndIf 

            If _nPrcVen < _nPrecoIt
                If FWIsInCallStack("MATA410") .And. !l410Auto  //não exibe mensagem do gatilho na efetivação de pedidos
                    If _lshow 
                        U_ITMsg("O preço informado está MENOR que o Preço da Tabela: " + _cDescTBPrc + ;
                                " | Produto: " + AllTrim(_cProd) +;
                                " | Preço informado: " + AllTrim(Transform(_nPrcVen, '@E 9,999.9999')) +;
                                " | Preço da Tabela: " + AllTrim(Transform(_nPrecoIt, '@E 999,999,999.9999')),,;
                                "Preço Minimo: " + AllTrim(Transform(_nPrcMin, '@E 999,999,999.9999'))+CRLF+;
                                "Preço Máximo: " + AllTrim(Transform(_nPrecoMax, '@E 9,999.9999')),3)
                    Else
                       _cRetMsg :="Produto: " + AllTrim(_cProd)+" - O preço informado está MENOR que o Preço da Tabela: " + AllTrim(Transform(_nPrecoIt , '@E 999,999,999.9999'))+CRLF+;
                                  "Preço informado: "  + AllTrim(Transform(_nPrcVen  , '@E 9,999.9999'))+" | Preço Minimo: "+ AllTrim(Transform(_nPrcMin  , '@E 9,999.9999')) + " | Preço Máximo: "+ AllTrim(Transform(_nPrecoMax, '@E 9,999.9999')) + CRLF + CRLF
                       If !FWIsInCallStack("U_MT410TOK")
                          _cRetMsg := "Tabela de Preço: "+ _cDescTBPrc+CRLF+_cRetMsg 
                       EndIf            
                    EndIf
                EndIf
                _lRet := .T.
            EndIf 
  
            If !_lRet .And. _nPrcVen > _nPrecoMax
                If FWIsInCallStack("MATA410") .And. !l410Auto  //não exibe mensagem do gatilho na efetivação de pedidos
                    If _lshow 
                       U_ITMsg("O preço informado está MAIOR que o Preço Máximo da Tabela: " + _cDescTBPrc + ;
                               " | Produto: " + AllTrim(_cProd) + ;
                               " | Preço informado: " + AllTrim(Transform(_nPrcVen, '@E 9,999.9999'))+;
                               " | Preço Máximo: " + AllTrim(Transform(_nPrecoMax, '@E 999,999,999.9999')),,;
                               "Preço Minimo: "   + AllTrim(Transform(_nPrcMin, '@E 999,999,999.9999'))+CRLF+;
                               "Preço da Tabela: "+ AllTrim(Transform(_nPrecoIt, '@E 9,999.9999')),3)
                    Else
                       _cRetMsg := "Produto: " + AllTrim(_cProd)+" - O preço informado está MAIOR que o Preço Máximo da Tabela: " + AllTrim(Transform(_nPrecoMax , '@E 999,999,999.9999'))+CRLF+;
                                   "Preço informado: "  + AllTrim(Transform(_nPrcVen  , '@E 9,999.9999'))+" | Preço Minimo: "+ AllTrim(Transform(_nPrcMin  , '@E 9,999.9999')) + " | Preço da Tabela: "+ AllTrim(Transform(_nPrecoIt, '@E 9,999.9999')) + CRLF + CRLF
                    EndIf
                EndIf
                _lRet := .T.
            EndIf

        // CALCULO ANTERIOR POR FAIXA E PESO
        ElseIf _lAchou .And. SuperGetMV("IT_TABPRG",.T.,.F.)  //DEFINE SE TABELAS DE PREÇOS PERSONALZIADAS ESTÃO LIGADAS OU NÃO
            DA0->(DBSetOrder(1))
            DA0->(DBSeek(xFilial("DA0")+DA1->DA1_CODTAB))
            _cDescTBPrc := AllTrim(DA1->DA1_CODTAB) + "-" + AllTrim(DA0->DA0_DESCRI)

            If _nFaixa >= 1 .And. _nFaixa <= 3
                If  _nFaixa = 3 
                    _nPrecoIt := DA1->DA1_I_PRF3
                    _nPrcMin  := DA1->DA1_I_PMF3
                ElseIf  _nFaixa == 2 
                    _nPrecoIt := DA1->DA1_I_PRF2
                    _nPrcMin  := DA1->DA1_I_PMF2
                ElseIf  _nFaixa = 1 
                    _nPrecoIt := DA1->DA1_I_PRF1
                    _nPrcMin  := DA1->DA1_I_PMF1
                EndIf
            Else
                If ((_nPesoBrut >=  DA0->DA0_I_PES3 .And. _nPesoBrut <  DA0->DA0_I_PES2  ) )
                    _nPrecoIt := DA1->DA1_I_PRF3
                    _nPrcMin  := DA1->DA1_I_PMF3
                    _nFaixa   := 3
                ElseIf ((_nPesoBrut >=  DA0->DA0_I_PES2 .And.  _nPesoBrut <  DA0->DA0_I_PES1) )
                    _nPrecoIt := DA1->DA1_I_PRF2
                    _nPrcMin  := DA1->DA1_I_PMF2
                    _nFaixa   := 2
                Else
                    _nPrecoIt := DA1->DA1_I_PRF1
                    _nPrcMin  := DA1->DA1_I_PMF1
                    _nFaixa   := 1
                EndIf
            EndIf

            _nPrecoMax := DA1->DA1_PRCMAX

            // Obtem a filial de faturamento.
            If FWIsInCallStack("MATA410")
                _cFilFat  := M->C5_I_FILFT
                If Empty(_cFilFat)
                    _cFilFat := M->C5_FILIAL
                    If Empty(_cFilFat) .And. Inclui
                        _cFilFat := xFilial("SC5")
                    EndIf
                EndIf
            Else
                _cFilFat := _cFil
            EndIf

            // Obtem a UF de faturamento.
            _nI       := aScan(_aFiliais, {|x| x[5] == _cFilFat})
            _cCnpj    := _aFiliais[_nI,18]      // C5_FILIAL
            _cUFFat   := Posicione( "SA2" , 3 , xFilial("SA2") + _cCNPJ , "A2_EST" )
            _cFilOrig := cFilAnt

            // Se a variável _cUFPedV está vazia, deve ser igual UF de faturamento.
            If Empty(_cUFPedV)
                _cUFPedV := _cUFFat
            EndIf

            // Com base na filial, obtem o fator a ser aplicado sobre os valores de
            // venda. Quando o estado de faturamento For diferente do cliente,
            // aplica o percentual sobre o valores de vendas definidos para o produto.
            cFilAnt     := _cFilFat // M->C5_I_FILFT// C5_FILIAL

            _nFatComercial := SuperGetMV("IT_FATMINP",.T.,1) // Carrega fator de conversão para calculo do maior preços de vendas.

            cFilAnt     := _cFilOrig

            If AllTrim(_cUFFat) == AllTrim(_cUFPedV) // UF Fat <> UF CLIENTE
                _nFatComercial := 1
            EndIf

            // Compara o valor digitado com os valores de vendas obtidos e com o
            // valor do plano de negócio, e com o valor máximo do produto, para
            // verificação de bloqueio de preço.

            // Preço plano de negócios. VER SE TEM VALOR  NO DA1_I_PTBN // Preço máximo.    // SE TEM VALOR NO DA1_PRCMAX.
            If _lSimplNac
                _nPercSimp := 1 + (DA1->DA1_I_SIMP / 100)
                _nPrecoIt := NoRound((_nPrecoIt * _nPercSimp),2)
            EndIf 
 
            If _nPrcVen <  _nPrecoIt
                If FWIsInCallStack("MATA410").and. !l410Auto  //não exibe mensagem do gatilho na efetivação de pedidos
                    If _lshow 
                        U_ITMsg("4 - O preço informado está menor que o Preço da Tabela: " + _cDescTBPrc + ;
                            " | Produto: " + _cProd +;
                            " | Preço da Tabela: " + AllTrim(Transform(_nPrecoIt, '@E 999,999,999.9999')) +;
                            " | Preço Minimo: " + AllTrim(Transform(_nPrcMin, '@E 999,999,999.9999')) , "Validação de preço pela Faixa " + AllTrim(Str(_nFaixa) + " Peso Pedido " + AllTrim(Transform(_nPesoBrut, '@E 9,999.9999'))  +CRLF) ,,3)     // COLOCAR AS MENSAGENS SEPARADAS. SEPARAR O IFS.
                    Else
                        _cRetMsg := "4 - O preço informado está menor que o Preço da Tabela: " + _cDescTBPrc + " | Produto: " + _cProd + " | Preço: " + AllTrim(Transform(_nPrecoIt, '@E 9,999.9999')) + " | Preço Minimo: " + AllTrim(Transform(_nPrcMin, '@E 9,999.9999')) + " Validação de preço pela Faixa " + AllTrim(Str(_nFaixa)) + " Peso Pedido " + AllTrim(Transform(_nPesoBrut, '@E 999,999,999.9999')) +CRLF 
                    EndIf
                EndIf
                _lRet := .T.
            EndIf 
  
            If !_lRet .And. _nPrcVen > _nPrecoMax
                If FWIsInCallStack("MATA410") .And. !l410Auto  //não exibe mensagem do gatilho na efetivação de pedidos
                    If _lshow 
                    U_ITMsg("O preço informado está maior que o Preço Máximo: " +  AllTrim(Transform(_nPrecoMax, '@E 999,999,999.9999')) + _cDescTBPrc + ;
                        " | Produto: " + _cProd + ;
                        " | Preço da Tabela: " + AllTrim(Transform(_nPrecoIt, '@E 999,999,999.9999')) +;
                        " | Preço Minimo: " + AllTrim(Transform(_nPrcMin, '@E 999,999,999.9999')) , "Validação de preço pela Faixa " + AllTrim(Str(_nFaixa) + " Peso Pedido " + AllTrim(Transform(_nPesoBrut, '@E 999,999,999.9999'))  +CRLF) ,,3)     // COLOCAR AS MENSAGENS SEPARADAS. SEPARAR O IFS.						
                    Else
                        _cRetMsg := "5 - O preço informado está maior que o Preço Máximo: " +  AllTrim(Transform(_nPrecoMax, '@E 9,999.9999')) + _cDescTBPrc + " | Produto: " + _cProd + " | Preço: " + AllTrim(Transform(_nPrecoIt, '@E 999,999,999.9999')) + " | Preço Minimo: " + AllTrim(Transform(_nPrcMin, '@E 9,999.9999')) + " Validação de preço pela Faixa " + AllTrim(Str(_nFaixa)) + " Peso Pedido " + AllTrim(Transform(_nPesoBrut, '@E 999,999,999.9999')) + CRLF
                    EndIf
                EndIf
                _lRet := .T.
            EndIf
        ElseIf _lB1TipoPA .And. (( _lF4DuplicS .And. _lZAYTpOprV ) .Or. _lPortal .Or. FWIsInCallStack("U_ALTERAP"))
            If _lshow .And. FWIsInCallStack("MATA410") .And. !l410Auto  //não exibe mensagem do gatilho na efetivação de pedidos
                U_ITMsg("O produto "+ AllTrim(_cProd) + " não tem cadastro de preços na tabela de preços " + _cDescTBPrc + ".", "Validação de preço",,3)
            EndIf
            _lRet := .T.
        EndIf 

        // Atualiza o campo C6_I_VLIBP com o Preço Digitado
        If !(_lRet) .And. !(_ltrans) .And. FWIsInCallStack("MATA410")
            aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_VLIBP" })] := _nPrcVen
        EndIf

        If _lRetPrc .And. !(_ltrans) .And. FWIsInCallStack("MATA410")
            _nPosPrc := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRCVEN"	} )
            If _nPrecoIt > 0
                aCols[n][_nPosPrc] := _nPrecoIt
            EndIf
            aCols[n][aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_FXPES" })] := _nFaixa
        EndIf
 End Sequence

    //        1       2        3         4           5          6            7
 _aRet := {_lRet, _nFaixa, _cRetMsg , _nPrecoIt , _nPrcMin ,_nPrecoMax, _cDescTBPrc}

Return _aRet

/*
===============================================================================================================================
Programa----------: BuscaFatComercial
Autor-------------: Alex Wallauer
Data da Criacao---: 07/01/2025
Descrição---------: Busca do Fator Comercial por Produto ou Grupo x Filial de Faturamento e UF do Cliente
Parametros--------: _cFilFat.......: Filial de Faturamento
                    _cUF...........: UF do Cliente
                    _cProd.........: Código do Produto
                    _cGrupo........: Grupo do Produto
                    @_cRegraFatC...: Regra da Busca encontrada
Retorno-----------: _nFatComercial.: Fator Comercial
===============================================================================================================================
*/  
Static Function BuscaFatComercial(_cFilFat As Char, _cUF As Char, _cProd As Char, _cGrupo As Char, _cRegraFatC As Char) As Numeric

Local _aRegras   := {} As Array
Local _aOrdBusca := {} As Array , A As Numeric
Local _cB_Prod   := Space(Len(ZAF->ZAF_PROD )) As Char
Local _cB_Grupo  := Space(Len(ZAF->ZAF_GRUPO)) As Char
Local _nFatComercial := 1 As Numeric
Default _cProd := _cB_Prod
Default _cGrupo:= _cB_Grupo

aAdd(_aOrdBusca, _cProd + _cB_Grupo )// ORDEM 01
aAdd(_aRegras, "Regra por produto: "+_cFilFat +" "+_cUF +" "+ _cProd)

aAdd(_aOrdBusca, _cB_Prod + _cGrupo )// ORDEM 02
aAdd(_aRegras, "Regra por Grupo: "+_cFilFat +" "+_cUF +" "+ _cGrupo)

ZAF->(DBSetOrder(1))
For A := 1 To Len(_aOrdBusca)

    ZAF->(DBSeek(xFilial()+_cFilFat+_cUF+_aOrdBusca[A]))
    While .not. ZAF->(Eof()) .And. ZAF->(ZAF_FILIAL+ZAF_FILFAT+ZAF_UF) == xFilial("ZAF")+_cFilFat+_cUF ;
                            .And. ZAF->(ZAF_PROD+ZAF_GRUPO)           == _aOrdBusca[A]
        If ZAF->ZAF_MSBLQL = "1"  //Registro Bloqueado
            ZAF->(DBSkip())
            Loop
        EndIf
        _cRegraFatC:= _aRegras[A]
        _nFatComercial:= ZAF->ZAF_FATOR
        Exit
    EndDo
Next A
 
Return _nFatComercial

/*
===============================================================================================================================
Programa...: PEDPORT
Autor......: Erich Buttner
Data.......: 15/07/2013
Descricao..: Verifica se o pedido veio do portal e não permite alteração de algumas informações    
Parametros.: _cpedportal - id do pedido do portal
Retorno....: Nenhum
===============================================================================================================================
*/
User Function PEDPORT(_cPedPortal)

Local _nPosProduto := 0
Local _lRet := .T.

_nPosProduto	:=  aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})

If Empty(AllTrim(_cPedPortal))
    _lRet := .T.
Else
    If Empty(AllTrim(aCols [n,_nPosProduto]))
        U_ITMsg('Pedido de Venda vindo do Portal, não é Permitido Incluir Item','Atenção!','Caso necessário solicite a manutenção = um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.',1)
        _lRet := .F.
    Else
        If !(U_ITVACESS( 'ZZL' , 3 , 'ZZL_PEDPOR' , "S" ))
            U_ITMsg('Pedido de Venda vindo do Portal, não é Permitido Alteração desta informação por esse usuário','Atenção!','Caso necessário solicite a manutenção = um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.',1)
            _lRet := .F.
        EndIf
    EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa...: BLQMOTO
Autor......: Erich Buttner
Data.......: 31/07/2013
Descricao..: Verifica se o usuario tem permissão para bloquear motorista   
Parametros.: Nenhum
Retorno....: Nenhum
===============================================================================================================================
*/
User Function BLQMOTO()

Local lRet := .F.

SA1->(DBSetOrder(1))
If SA1->(DBSeek(xFilial("ZZL")+FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]))
    If ZZL->ZZL_BLQMOT == 'S'
        lRet := .T.
    EndIf
EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: ITCALIMP
Autor-------------: Alexandre Villar
Data da Criacao---: 24/07/2014
Descrição---------: Funcao utilizada para calcular os impostos do RPA.
Parametros--------: _adadAux - array com dados do rpa
Retorno-----------: _aRet[01]	:= IIf(	_nVlrSest < 0	, 0			, _nVlrSest	)		//M->ZZA_SEST
                    _aRet[02]	:= IIf(	_nVlrInss < 0	, 0			, _nVlrInss	)		//M->ZZA_INSS
                    _aRet[03]	:= IIf( _lGravVl		, _nVlrIrrf	, 0			)		//M->ZZA_IRRF
                    _aRet[04]	:= _aDadAux[02] - ( _nVlrSest + _nVlrInss + _aRet[03] )	//M->ZZA_VLRLIQ
===============================================================================================================================
*/
User Function ITCALIMP( _aDadAux )

//_aDadAux
//01 - M->ZZA_CODAUT
//02 - M->ZZA_VLRBRT
//03 - M->ZZA_CONPAG
//04 - M->ZZA_TPFORN

Local _aRet				:= Array( 04 )
Local nBaseIR			:= GETMV( 'IT_BSIRRF' ,, 0 )
Local _nVlrDep          := 0
Local _cAliaINSS        := GetNextAlias()
Local _cAliaIRRF		:= GetNextAlias()
Local _cAliaReci        := GetNextAlias()
Local _cFilCorr         := ""
Local _nValAcm			:= 0

Private _cRecibo		:= ""
Private _nVlrIrrfPag	:= 0
Private _nTeto			:= 0
Private _nbaseSest		:= 0
Private _nVlrSest 		:= 0
Private _nbaseinss		:= 0
Private _nvlrinss 		:= 0
Private _nVlrIrrf 		:= 0
Private _x08_Lim3		:= Nil
Private _x08_Lim3P		:= Nil
Private _x09_rend1		:= Nil
Private _x09_rend2		:= Nil
Private _x09_rend3		:= Nil
Private _x09_rend4		:= Nil
Private _x09_rend5		:= Nil
Private _x09_aliq2		:= Nil
Private _x09_aliq3		:= Nil
Private _x09_aliq4		:= Nil
Private _x09_aliq5		:= Nil
Private _x09_parc2		:= Nil
Private _x09_parc3		:= Nil
Private _x09_parc4		:= Nil
Private _x09_parc5		:= Nil
Private _x09_deddep		:= Nil
Private _x09_limdep		:= Nil
Private _x09_retmin		:= Nil

Public	_lGravVl 		:= .F.

If ( _aDadAux[02] > 0 ) .And. !Empty( _aDadAux[03] ) .And. !Empty( _aDadAux[04] ) .And. !Empty( _aDadAux[01] )

    //Caso o Fornecedor seja Fretista calcula SEST/SENAT
    If _aDadAux[04] == 'F'
        _nbaseSest	:=	_aDadAux[02]	* GETMV( 'IT_BSSEST'	,, 0 ) / 100
        _nVlrSest 	:=	_nBaseSest 		* GETMV( 'IT_VLRSEST'	,, 0 ) / 100
    EndIf

    //| Calcula e Verifica se total de INSS do mes nao ultrapassou o teto            |
    U_ValINSS()

    _nTeto	:= NoRound( _x08_Lim3 * _x08_Lim3P / 100 , 2 )

    _cQuery := " SELECT "
    _cQuery += " 	SUM(INSS) AS INSS "
    _cQuery += " FROM ( "

    _cQuery += " 	SELECT "
    _cQuery += " 		ZZ2_AUTONO		AS COD	, "
    _cQuery += " 		SUM(ZZ2_INSS)	AS INSS	  "
    _cQuery += " 	FROM "+ RetSqlName("ZZ2") +" ZZ2 "
    _cQuery += " 	WHERE "
    _cQuery += " 		ZZ2.D_E_L_E_T_				= ' ' "
    _cQuery += " 	AND	ZZ2_AUTONO    				= '"+ _aDadAux[01] +"' "
    _cQuery += " 	AND	EXISTS ( "
    _cQuery += " 					SELECT DAI.R_E_C_N_O_ AS REGDAI "
    _cQuery += "				 	FROM "+ RetSqlName("DAI") +" DAI "
    _cQuery += " 					INNER JOIN "+ RetSqlName("SF2") +" SF2 "
    _cQuery += " 					ON	SF2.F2_FILIAL				= DAI.DAI_FILIAL "
    _cQuery += " 					AND	SF2.F2_DOC					= DAI.DAI_NFISCA "
    _cQuery += " 					AND SF2.F2_SERIE				= DAI.DAI_SERIE "
    _cQuery += " 					AND SubStr(SF2.F2_EMISSAO,5,2)	= '"+ StrZero( Month(dDataBase)	, 2 ) +"' "
    _cQuery += " 					AND SubStr(SF2.F2_EMISSAO,1,4)	= '"+ StrZero( YEAR(dDataBase)	, 4 ) +"' "
    _cQuery += " 					AND SF2.D_E_L_E_T_				= ' ' "
    _cQuery += " 					WHERE "
    _cQuery += " 						DAI.DAI_FILIAL      = ZZ2.ZZ2_FILIAL "
    _cQuery += " 					AND DAI.DAI_COD         = ZZ2.ZZ2_CARGA "
    _cQuery += " 					AND DAI.D_E_L_E_T_      = ' ' "
    _cQuery += " 				) "
    _cQuery += " 	GROUP BY ZZ2_AUTONO "
    _cQuery += " 	UNION ALL "
    _cQuery += " 	SELECT "
    _cQuery += " 		ZZ2_AUTONO		AS COD	, "
    _cQuery += " 		SUM(ZZ2_INSS)	AS INSS	  "
    _cQuery += " 	FROM "+ RetSqlName("ZZ2") +" ZZ2 "
    _cQuery += " 	WHERE "
    _cQuery += " 		ZZ2.D_E_L_E_T_				= ' ' "
    _cQuery += " 	AND	ZZ2.ZZ2_CARGA  				= ' ' "
    _cQuery += " 	AND	ZZ2_AUTONO    				= '"+ _aDadAux[01] +"' "
    _cQuery += " 	AND SubStr(ZZ2.ZZ2_DATA,5,2)	= '"+ StrZero( Month(dDataBase)	, 2 ) +"' "
    _cQuery += " 	AND SubStr(ZZ2.ZZ2_DATA,1,4)	= '"+ StrZero( YEAR(dDataBase)	, 4 ) +"' "
    _cQuery += " 	GROUP BY ZZ2_AUTONO "
    _cQuery += " 	ORDER BY INSS ) "

    MPSysOpenQuery( _cQuery , _cAliaINSS)

    (_cAliaINSS)->( DBGoTop() )
    If (_cAliaINSS)->( !Eof() )
        //Tipo do Fornecedor igual a Fretista
        If _aDadAux[04] == 'F'
            _nCorrentVlrINSS := ( _aDadAux[02] * GETMV( 'IT_BSINSS' ,, 0 ) / 100 ) * GETMV('IT_VLRINSS') / 100

            If (_cAliaINSS)->INSS + _nCorrentVlrINSS < _nteto
                _nbaseinss	:= _aDadAux[02]	* GETMV( 'IT_BSINSS'	,, 0 ) / 100
                _nvlrinss	:= _nbaseinss	* GETMV( 'IT_VLRINSS'	,, 0 ) / 100
            Else
                If (_cAliaINSS)->INSS + _nCorrentVlrINSS - _nteto > 0
                    _nbaseinss	:= _aDadAux[02] * GETMV( 'IT_BSINSS' ,, 0 ) / 100
                    _nvlrinss	:= _nteto - (_cAliaINSS)->INSS
                EndIf
            EndIf
        Else//Outros
            _nCorrentVlrINSS := _aDadAux[02] * GETMV( 'IT_VLRINSS' ,, 0 ) / 100
            If (_cAliaINSS)->INSS + _nCorrentVlrINSS < _nteto
                _nvlrinss := _aDadAux[02] * GETMV( 'IT_VLRINSS' ,, 0 ) / 100
            Else
                If (_cAliaINSS)->INSS + _nCorrentVlrINSS - _nteto > 0
                    _nvlrinss :=_nteto - (_cAliaINSS)->INSS
                EndIf
            EndIf
        EndIf
    EndIf

    (_cAliaINSS)->( DBCloseArea() )

    //Busca dados das aliquotas nas tabelas de IRRF
    _nBaseIrrf	:= 0
    u_ValIRRF()

    //Adicionado por Guilherme 15/10/2012 para tratar filial autonomo
    _cFilCorr	:= cFilAnt
    cFilAnt		:= "01"

    SRA->( DBSeek( xFilial("SRA") + _aDadAux[01] ) )
    _nVlrDep	:= ValidDep( xFilial("SRA") , _aDadAux[01] ) * _x09_deddep  // calculo do valor a deduzir por dependente
    cFilAnt		:= _cFilCorr

    //Recupera os valores já calculados anteriormente para o mesmo período
    _cQuery := " SELECT "
    _cQuery += " 	SUM(SEST)	AS SEST	, "
    _cQuery += " 	SUM(INSS)	AS INSS	, "
    _cQuery += " 	SUM(TOTAL)	AS TOTAL, "
    _cQuery += " 	SUM(IRRF)	AS IRRF	, "
    _cQuery += " 	COUNT(INSS)	AS CONT	, "
    _cQuery += " 	SUM(PEDAG)	AS PEDAG  "
    _cQuery += " FROM ( "
    _cQuery += " 	SELECT "
    _cQuery += " 		ZZ2_AUTONO		AS COD	, "
    _cQuery += " 		SUM(ZZ2_SEST)	AS SEST	, "
    _cQuery += " 		SUM(ZZ2_INSS)	AS INSS	, "
    _cQuery += " 		SUM(ZZ2_TOTAL)	AS TOTAL, "
    _cQuery += " 		SUM(ZZ2_IRRF)	AS IRRF	, "
    _cQuery += " 		COUNT(ZZ2_INSS)	AS CONT , "
    _cQuery += " 		SUM(ZZ2_VRPEDA)	AS PEDAG  "
    _cQuery += " 	FROM "+ RetSqlName("ZZ2") +" ZZ2 "
    _cQuery += " 	WHERE "
    _cQuery += " 		ZZ2.D_E_L_E_T_				= ' ' "
    _cQuery += " 	AND	ZZ2_AUTONO    				= '"+ _aDadAux[01] +"' "
    _cQuery += " 	AND	EXISTS ( "
    _cQuery += " 					SELECT DAI.R_E_C_N_O_ AS REGDAI "
    _cQuery += "				 	FROM "+ RetSqlName("DAI") +" DAI "
    _cQuery += " 					INNER JOIN "+ RetSqlName("SF2") +" SF2 "
    _cQuery += " 					ON	SF2.F2_FILIAL				= DAI.DAI_FILIAL "
    _cQuery += " 					AND	SF2.F2_DOC					= DAI.DAI_NFISCA "
    _cQuery += " 					AND SF2.F2_SERIE				= DAI.DAI_SERIE "
    _cQuery += " 					AND SubStr(SF2.F2_EMISSAO,5,2)	= '"+ StrZero( Month(dDataBase)	, 2 ) +"' "
    _cQuery += " 					AND SubStr(SF2.F2_EMISSAO,1,4)	= '"+ StrZero( YEAR(dDataBase)	, 4 ) +"' "
    _cQuery += " 					AND SF2.D_E_L_E_T_				= ' ' "
    _cQuery += " 					WHERE "
    _cQuery += " 						DAI.DAI_FILIAL      = ZZ2.ZZ2_FILIAL "
    _cQuery += " 					AND DAI.DAI_COD         = ZZ2.ZZ2_CARGA "
    _cQuery += " 					AND DAI.D_E_L_E_T_      = ' ' "
    _cQuery += " 				) "
    _cQuery += " 	GROUP BY ZZ2_AUTONO "
    _cQuery += " 	UNION ALL "
    _cQuery += " 	SELECT "
    _cQuery += " 		ZZ2_AUTONO		AS COD	, "
    _cQuery += " 		SUM(ZZ2_SEST)	AS SEST	, "
    _cQuery += " 		SUM(ZZ2_INSS)	AS INSS	, "
    _cQuery += " 		SUM(ZZ2_TOTAL)	AS TOTAL, "
    _cQuery += " 		SUM(ZZ2_IRRF)	AS IRRF	, "
    _cQuery += " 		COUNT(ZZ2_INSS)	AS CONT	, "
    _cQuery += " 		SUM(ZZ2_VRPEDA)	AS PEDAG  "
    _cQuery += " 	FROM "+ RetSqlName("ZZ2") +" ZZ2 "
    _cQuery += " 	WHERE "
    _cQuery += " 		ZZ2.D_E_L_E_T_				= ' ' "
    _cQuery += " 	AND	ZZ2.ZZ2_CARGA  				= ' ' "
    _cQuery += " 	AND	ZZ2_AUTONO    				= '"+ _aDadAux[01] +"' "
    _cQuery += " 	AND SubStr(ZZ2.ZZ2_DATA,5,2)	= '"+ StrZero( Month(dDataBase)	, 2 ) +"' "
    _cQuery += " 	AND SubStr(ZZ2.ZZ2_DATA,1,4)	= '"+ StrZero( YEAR(dDataBase)	, 4 ) +"' "
    _cQuery += " 	GROUP BY ZZ2_AUTONO "
    _cQuery += " 	ORDER BY COD ) "

    MPSysOpenQuery( _cQuery , _cAliaIRRF)

    (_cAliaIRRF)->( DBGoTop() )

    //Valida o valor bruto de acordo com o identificador da chamada
    If _aDadAux[05] == 1
        _nValAcm := ((_cAliaIRRF)->TOTAL - (_cAliaIRRF)->PEDAG) + _aDadAux[02]
    ElseIf _aDadAux[05] == 2
        _nValAcm := ((_cAliaIRRF)->TOTAL - (_cAliaIRRF)->PEDAG)
    Else
        _nValAcm := 0
    EndIf

    //Tipo do Fornecedor igual a Fretista
    If _aDadAux[04] == 'F'
        If (_cAliaIRRF)->( !Eof() ) .And. (_cAliaIRRF)->CONT > 0
            _nbaseirrf 		:= 	( _nValAcm * nBaseIR ) / 100
            _nbaseirrf 		-= 	_nVlrDep //deduz por dependente
            _nbaseirrf 		-= 	( (_cAliaIRRF)->INSS + _nvlrinss + _nVlrSest + (_cAliaIRRF)->SEST ) // deduz INSS
            _nVlrIrrfPag 	:=	(_cAliaIRRF)->IRRF
        Else
            _nbaseirrf		:= ( _aDadAux[02] * nBaseIR ) / 100
            _nbaseirrf		-= (_nVlrDep)   // deduz por dependente
            _nbaseirrf		-= (_nvlrinss+_nVlrSest) // deduz INSS
            _nVlrIrrfPag	:= 0
        EndIf
    Else//Outros
        If !Eof() .And. (_cAliaIRRF)->CONT > 0
            _nbaseirrf 		:= 	( _nValAcm )
            _nbaseirrf 		-= 	(_nVlrDep) //deduz por dependente
            _nbaseirrf 		-= 	( (_cAliaIRRF)->INSS + _nvlrinss ) //deduz INSS
            _nVlrIrrfPag 	:=	(_cAliaIRRF)->IRRF
        Else
            _nbaseirrf		:= ( _aDadAux[02]	)
            _nbaseirrf		-= ( _nVlrDep		) //deduz por dependente
            _nbaseirrf		-= ( _nvlrinss		) //deduz INSS
            _nVlrIrrfPag	:= 0
        EndIf
    EndIf

    (_cAliaIRRF)->( DBCloseArea() )

    _cQuery	:=	""

    If		_nBaseIrrf	> _x09_rend1	.And. _nBaseIrrf	<= _x09_rend2
        _nVlrIrrf := ( _nbaseirrf * _x09_aliq2 ) / 100
        _nvlrIrrf -= _x09_parc2
    ElseIf	_nBaseIrrf	> _x09_rend2	.And. _nBaseIrrf	<= _x09_rend3
        _nVlrIrrf := ( _nbaseirrf * _x09_aliq3 ) / 100
        _nvlrIrrf -= _x09_parc3
    ElseIf	_nBaseIrrf	> _x09_rend3	.And. _nBaseIrrf	<= _x09_rend4
        _nVlrIrrf := ( _nbaseirrf * _x09_aliq4 ) / 100
        _nvlrIrrf -= _x09_parc4
    ElseIf	_nBaseIrrf	> _x09_rend4	.And. _nBaseIrrf	<= _x09_rend5
        _nVlrIrrf := ( _nbaseirrf * _x09_aliq5 ) / 100
        _nvlrIrrf -= _x09_parc5
    Else
        _nVlrIrrf := 0
    EndIf

    If _nVlrIrrf > 0
        _cQuery := " SELECT COUNT(ZZ2_RECIBO) AS CONTADOR "
        _cQuery += " FROM "+RetSqlName("ZZ2")
        _cQuery += " WHERE "
        _cQuery += " 	SubStr(ZZ2_DATA,5,2)	= "+ StrZero(Month(dDataBase),2)	+" AND "
        _cQuery += " 	SubStr(ZZ2_DATA,1,4)	= "+ StrZero(YEAR(dDataBase),4)		+" AND "
        _cQuery += " 	ZZ2_AUTONO		   		= '"+ _aDadAux[01]					+"' AND "
        _cQuery += " 	D_E_L_E_T_		   		= ' ' AND "
        _cQuery += " 	ZZ2_IRRF > 0 "

        MPSysOpenQuery( _cQuery , _cAliaReci)

        (_cAliaReci)->( DBGoTop() )

        If (_cAliaReci)->CONTADOR == 0 //e o primeiro recibo
            If _nVlrIrrf < GETMV( 'MV_VLRETIR' ,, 0 ) //se o 1Recibo For menor que 10 nao deve gravar valor
                _lGravVl	:= .F.
            ElseIf _nVlrIrrf >= GETMV( 'MV_VLRETIR' ,, 0 )
                _lGravVl	:= .T.
                _nVlrIrrf	-= _nVlrIrrfPag
            EndIf

            //Se não For o primeiro recibo, gravar subtraindo os valores já retidos
        ElseIf (_cAliaReci)->CONTADOR > 0
            If ( _nVlrIrrf + _nVlrIrrfPag ) < GETMV( 'MV_VLRETIR' ,, 0 ) //se soma do imoposta maior que limite minimo
                _lGravVl := .F.
            ElseIf ( _nVlrIrrf + _nVlrIrrfPag ) >= GETMV( 'MV_VLRETIR' ,, 0 )
                _lGravVl := .T.
                If		_nVlrIrrf >= _nVlrIrrfPag //Se valor a reter For maior ou igual ao somatorio dos retidos
                    _nVlrIrrf -= _nVlrIrrfPag
                ElseIf	_nVlrIrrf < _nVlrIrrfPag//Se For menor, fica com o valor calculado mesmo.
                    _nVlrIrrf := _nVlrIrrf
                EndIf
            EndIf
        EndIf
        (_cAliaReci)->( DBCloseArea() )
    EndIf

    _nVlrIrrf	:= IIf( _nVlrIrrf < 0	, 0			, _nVlrIrrf	)
    _aRet[01]	:= IIf(	_nVlrSest < 0	, 0			, _nVlrSest	)		//M->ZZA_SEST
    _aRet[02]	:= IIf(	_nVlrInss < 0	, 0			, _nVlrInss	)		//M->ZZA_INSS
    _aRet[03]	:= IIf( _lGravVl		, _nVlrIrrf	, 0			)		//M->ZZA_IRRF
    _aRet[04]	:= _aDadAux[02] - ( _nVlrSest + _nVlrInss + _aRet[03] )	//M->ZZA_VLRLIQ
EndIf

Return( _aRet )

/*
===============================================================================================================================
Programa----------: ITVLDSRA
Autor-------------: Alexandre Villar
Data da Criacao---: 01/08/2014
Descrição---------: Funcao que valida o código da Matrícula do Autônomo
Parametros--------: _ccodAut - Código do autonomo
Retorno-----------: _lRet - matricula válida ou não
===============================================================================================================================
*/

User Function ITVLDSRA( _cCodAut )

Local _lRet		:= .T.
Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT "
_cQuery += " 	RA_MAT		,"
_cQuery += " 	RA_NOMECMP	,"
_cQuery += " 	RA_CIC		 "
_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "
_cQuery += " WHERE "
_cQuery += " 		D_E_L_E_T_	= ' ' "
_cQuery += " AND	RA_MAT		= '"+ _cCodAut +"' "
_cQuery += " AND	RA_FILIAL	= '01' "
_cQuery += " AND	RA_CATFUNC	= 'A' "

MPSysOpenQuery( _cQuery , _cAlias)

(_cAlias)->( DBGoTop() )

If (_cAlias)->(Eof()) .Or. Empty( (_cAlias)->RA_MAT )
    _lRet := .F.
EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ValidDep
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/01/2009
Descrição---------: Funcao para verificar dependentes do Autonomo.
Parametros--------: Filial - Filial do autonomo
                    Matric - código do autonomo
Retorno-----------: nRet -  Numero de dependente.
===============================================================================================================================
*/
Static Function ValidDep( Filial , Matric )

Local _nRet		:= 0

SRA->( DBSetOrder(1) ) //RA_FILIAL+RA_MAT
SRA->( DBSeek( Filial + Matric ) )

SRB->( DBSetOrder(1) ) //RB_FILIAL+RB_MAT
If SRB->( DBSeek( Filial + Matric ) )
    While SRB->( !Eof() ) .And. SRB->RB_FILIAL + SRB->RB_MAT == Filial + Matric
        If SRB->RB_TIPIR == "1"
            _nRet++
        ElseIf SRB->RB_TIPIR == "2" .And. ( dDataBase - SRB->RB_DTNASC ) / 360 <= 21
            _nRet++
        ElseIf SRB->RB_TIPIR == "3" .And. ( dDataBase - SRB->RB_DTNASC ) / 360 <= 24
            _nRet++
        EndIf
        SRB->( DBSkip() )
    EndDo
    If _nRet < Val(SRA->RA_DEPIR)
        _nRet := _nRet + ( Val(SRA->RA_DEPIR) - _nRet )
    EndIf
EndIf

Return(_nRet)

/*
===============================================================================================================================
Programa----------: ValINSS
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/01/2009
Descrição---------: Funcao para validar tabela de calculo de INSS para recolhimento do Autonomo.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ValINSS()

Local _cMesAtual:= SubStr(DToS(Date()),1,4)+SubStr(DToS(Date()),5,2)
Local _cDtIni   :=_cMesAtual
Local _cDtfim   :=_cMesAtual
Local _lPassou  := .F.
Local _nValRCC, _nMaxVal

_x08_Lim3 := 0//Zera pra não far erro.log
_x08_Lim3P:= 0//Zera pra não far erro.log
_nMaxVal := 0

_nI := 0
RCC->( DBSetOrder(1) )
If RCC->( DBSeek( xFilial("RCC") + "S001" ))
    While RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO == "S001"
        _cDtIni:=SubStr(RCC->RCC_CONTEU,1,6)//Novo conteudo RCC->RCC_CONTEU = 201801201812     1693.72  8.000  8.000
        _cDtfim:=SubStr(RCC->RCC_CONTEU,7,6)//Novo conteudo RCC->RCC_CONTEU = 201801201812     1693.72  8.000  8.000

        If _cMesAtual >= _cDtIni .And. _cMesAtual <= _cDtfim
            _nI++
            _nValRCC := Val(AllTrim(SubStr(RCC->RCC_CONTEU,13,12)))
            If _nValRCC > _nMaxVal
                _nMaxVal	:= _nValRCC
                _x08_Lim3 := Val( SubStr( RCC->RCC_CONTEU , 13 , 12  ) ) // Sl.Contr Ate
                _x08_Lim3P := Val( SubStr( RCC->RCC_CONTEU , 25 , 7 ) ) // % Desc. INSS
                _lPassou:=.T.
            EndIf
        EndIf
        RCC->(DBSkip())
    EndDo
EndIf

If !_lPassou
    U_ITMsg("Tabela (S001) de INSS (RCC) não cadastrada para o Mes / Ano: "+SubStr( DToS( Date() ) , 5 , 2 ) +" / "+ SubStr( DToS(Date()),1,4 ),;
        'Atenção!',;
        "Favor entrar em contato com o RH para atualização dos parametros da Folha.",1)
EndIf

Return

/*
===============================================================================================================================
Programa----------: ValIRRF
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/01/2009
Descrição---------: Funcao para validar tabela de calculo de IRFF para recolhimento do Autonomo.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ValIRRF()

Local _lPassou  := .F.
Local _cMesAtual:= SubStr(DToS(Date()),1,4)+SubStr(DToS(Date()),5,2)
Local _cDtIni   :=_cMesAtual
Local _cDtfim   :=_cMesAtual

_lAchou := .F.
RCC->( DBSetOrder(1) )
If RCC->( DBSeek( xFilial("RCC") + "S002" ))
    While RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO == "S002"
        _cDtIni:=SubStr(RCC->RCC_CONTEU,1,6)//Novo conteudo RCC->RCC_CONTEU = 201801201812     1903.98     2826.65  7.50    142.80000     3751.05 15.00    354.80000     4664.68 22.50    636.13000999999999.99 27.50    869.36000      189.5999       10.01
        _cDtfim:=SubStr(RCC->RCC_CONTEU,7,6)//Novo conteudo RCC->RCC_CONTEU = 201801201812     1903.98     2826.65  7.50    142.80000     3751.05 15.00    354.80000     4664.68 22.50    636.13000999999999.99 27.50    869.36000      189.5999       10.01

        If _cMesAtual >= _cDtIni .And. _cMesAtual <= _cDtfim
            _X09_REND1 := Val( SubStr( RCC->RCC_CONTEU , 013 , 12  ) ) // ISENCAO
            _X09_REND2 := Val( SubStr( RCC->RCC_CONTEU , 025 , 12  ) ) // REND1
            _X09_REND3 := Val( SubStr( RCC->RCC_CONTEU , 056 , 12  ) ) // REND2
            _X09_REND4 := Val( SubStr( RCC->RCC_CONTEU , 087 , 12  ) ) // REND3
            _X09_REND5 := Val( SubStr( RCC->RCC_CONTEU , 118 , 12  ) ) // REND4
            _X09_ALIQ2 := Val( SubStr( RCC->RCC_CONTEU , 037 , 06  ) ) // ALIQ1
            _X09_ALIQ3 := Val( SubStr( RCC->RCC_CONTEU , 068 , 06  ) ) // ALIQ2
            _X09_ALIQ4 := Val( SubStr( RCC->RCC_CONTEU , 099 , 06  ) ) // ALIQ3
            _X09_ALIQ5 := Val( SubStr( RCC->RCC_CONTEU , 130 , 06  ) ) // ALIQ4
            _X09_PARC2 := Val( SubStr( RCC->RCC_CONTEU , 043 , 13  ) ) // DED1
            _X09_PARC3 := Val( SubStr( RCC->RCC_CONTEU , 074 , 13  ) ) // DED2
            _X09_PARC4 := Val( SubStr( RCC->RCC_CONTEU , 105 , 13  ) ) // DED3
            _X09_PARC5 := Val( SubStr( RCC->RCC_CONTEU , 136 , 13  ) ) // DED4
            _X09_DEDDEP := Val( SubStr( RCC->RCC_CONTEU ,149 , 12  ) ) // DEDDEP
            _X09_LIMDEP := Val( SubStr( RCC->RCC_CONTEU ,161 , 02  ) ) // LIMDEP
            _lpassou := .T.
        EndIf
        RCC->(DBSkip())
    EndDo
EndIf

If !_lPassou
    U_ITMsg("Tabela (S002) de Imposto de Renda (RCC) não cadastrada para o Mes / Ano: "+SubStr( DToS( Date() ) , 5 , 2 ) +" / "+ SubStr( DToS(Date()),1,4 ),;
        'Atenção!',;
        "Favor entrar em contato com o RH para atualização dos parametros da Folha.",1)
EndIf

Return

/*
===============================================================================================================================
Programa----------: ITCODCLI
Autor-------------: Cleiton Campos
Data da Criacao---: 14/07/2008
Descrição---------: Retorna o próximo código sequencial para o cadastro de Clientes
Parametros--------: _pcTipo 	- Tipo de Pessoa (A1_PESSOA)
------------------: _pcCGC		- CPF/CNPJ do CLiente que está sendo cadastrado (A1_CGC)
Retorno-----------: _cRetorno	- Retorna o novo código do Cliente para a inclusão (A1_COD)
===============================================================================================================================
*/ 
User Function ITCODCLI()

Local _aArea    := FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cQuery   := ""
Local _cRetorno := ""
Local _cCodigo  := ""
Local _pcTipo	:= M->A1_PESSOA
Local _pcCGC	:= M->A1_CGC

// Não gera o código caso a rotina seja chamada pela função SPEDMDFE
If FunName() == "SPEDMDFE"
    Return( _cCodigo )
EndIf

If FWIsInCallStack('U_GP010ValPE') .And. !Inclui
    Return M->A1_COD
EndIf

// Monta a consulta do cadastro atual de Clientes
_cQuery := " SELECT MAX( SA1.A1_COD ) AS CODIGO"
_cQuery += " FROM " + RetSqlName("SA1") +" SA1 "
_cQuery += " WHERE "
_cQuery += " 		SA1.D_E_L_E_T_	= ' ' "
_cQuery += " AND	SA1.A1_FILIAL	= '"+ xFilial("SA1") +"' "

// Verifica pelo CPF ou CNPJ de acordo com o tipo de cadastro
If AllTrim(_pcTipo) == "J"
    _cQuery += " AND	SubStr( SA1.A1_CGC , 1 , 8 ) = '" + SubStr( _pcCGC , 1 , 8 ) + "' "
    _cQuery += " AND	SA1.A1_PESSOA = 'J' "
Else
    _cQuery += " AND	SA1.A1_CGC  = '" + AllTrim( _pcCGC ) + "' "
EndIf

MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
    _cCodigo := (_cAlias)->CODIGO
EndIf

(_cAlias)->( DBCloseArea() )

// Se o cliente não existir no cadastro gera um novo sequencial.
If Empty( _cCodigo )
    SA1->( DBSetOrder(1) )
    SA1->( DBGoBottom( ) )
    If SA1->( !Eof() )
        _cCodigo := Soma1( SA1->A1_COD , TamSX3("A1_COD")[01] )

        //Se o código estiver reservado na memória pega o próximo
        While !MayIUseCode( "A1_COD" + xFilial("SA1") + _cCodigo )
            _cCodigo := Soma1( _cCodigo , TamSX3("A1_COD")[01] )
        EndDo
    Else
        _cCodigo := StrZero( 1 , TamSX3("A1_COD")[01] )
    EndIf
EndIf

_cRetorno := _cCodigo

FWRestArea(_aArea)

Return(_cRetorno)

/*
===============================================================================================================================
Programa----------: ITLOJCLI
Autor-------------: Cleiton Campos
Data da Criacao---: 14/07/2008
Descrição---------: Retorna o código da Loja para o cadastro de Clientes
Parametros--------: _pcTipo 	- Tipo de Pessoa (A1_PESSOA)
------------------: _pcCGC		- CPF/CNPJ do CLiente que está sendo cadastrado (A1_CGC)
Retorno-----------: _cRetorno	- Retorna o novo código do Cliente para a inclusão (A1_COD)
===============================================================================================================================
*/
User Function ITLOJCLI()

Local _aArea		:= FWGetArea()
Local _cCod			:= ""
Local _cCNPJ		:= ""
Local _cRetorno		:= ""

// Não gera o código caso a rotina seja chamada pela função SPEDMDFE
If FunName() == "SPEDMDFE"
    Return( _cRetorno )
EndIf

// Se não For Inclusão retorna o código da loja atual
If !INCLUI
    Return( SA1->A1_LOJA )
EndIf

_cCNPJ := M->A1_CGC

If Len( AllTrim( _cCNPJ ) ) > 11
    _cRetorno := SubStr( _cCNPJ , 9 , 4 )

    // VERIFICAR SE O CNPJ DO CLIENTE ESTA CADASTRADO EM ALGUMA LOJA
    _cCod := Posicione( "SA1" , 3 , xFilial("SA1") + _cCNPJ , "A1_COD" )

    If !Empty(_cCod)
        _cRetorno := ITRETLOJA( _cCod , 1 )
    EndIf
Else
    _cRetorno := ITRETLOJA( _cCNPJ , 2 )
EndIf

// Verifica se esta na memoria, sendo usado
If !MayIUseCode( "A1_LOJA"+ xFilial("SA1") + _cCod + _cRetorno )
    MSGSTOP( "Código: "+ _cCod + " / Loja: " + _cRetorno + " já está sendo utilizado. Contacte o administrador do sistema." )
    Return("")
EndIf

//Se é grupo de lojas preenche automatico o campo de grupo de lojas
If Val(_cRetorno) > 1
    DbSelectArea('SA1')
    DbSetOrder(1) //A1_FILIAL+A1_COD
    If SA1->( DbSeek( xFilial('SA1')+M->A1_COD ) )
        If SA1->A1_GRPVEN != '999999'
            M->A1_GRPVEN := SA1->A1_GRPVEN
            M->A1_I_NGRPC := SA1->A1_I_NGRPC
            M->A1_COND := SA1->A1_COND
        EndIf
    EndIf
EndIf

FWRestArea( _aArea )

Return( _cRetorno )

/*
===============================================================================================================================
Programa----------: ITRETLOJA
Autor-------------: Cleiton Campos
Data da Criacao---: 14/07/2008
Descrição---------: Retorna o código da Loja para o cadastro de Clientes
Parametros--------: _cAux - Tipo de Pessoa (A1_PESSOA)
------------------: _nOpc - Define se busca por CPF ou CNPJ
Retorno-----------: _cRetorno	- Retorna o novo código do Cliente para a inclusão (A1_COD)
===============================================================================================================================
*/
Static Function ITRETLOJA( _cAux , _nOpc )

Local cQuery	:= ""
Local cRet		:= ""
Local cAlias	:= GetNextAlias()

cQuery := " SELECT "
cQuery += "	MAX( SA1.A1_LOJA ) AS LOJA "
cQuery += " FROM "+ RetSqlName("SA1") +" SA1 "
cQuery += " WHERE "
cQuery += " 	SA1.D_E_L_E_T_	= ' ' "
If _nOpc == 1
    cQuery += " AND	SA1.A1_COD      = '" + AllTrim( _cAux ) +"' "
Else
    cQuery += " AND	SA1.A1_CGC      = '" + AllTrim( _cAux ) +"' "
EndIf

MPSysOpenQuery(cQuery,cAlias)

(cAlias)->( DBGoTop() )
If (cAlias)->( !Eof() )
    cRet := Soma1( (cAlias)->LOJA )
EndIf

(cAlias)->( DBCloseArea() )

Return( cRet )

/*
===============================================================================================================================
Programa----------: ITVLPRTR
Autor-------------: Xavier
Data da Criacao---: 30/03/2015
Descrição---------: Validação do preço unitario em referencia a tabela de preço de transferencias
Parametros--------: cOper = codigo da operação  
                     cProd = Codigo do produto 
                     nPrc = Preco unitario
                     _nopc =  1 é processamento normal,  2 é processamento que retorna o código do produto com problema
                             3 é quando é chamado do validador
Retorno-----------: lRet - Retorna validando o preço em função do % desvio
===============================================================================================================================
*/
User Function ITVLPRTR(_cOper As Character, _cProd As Character, _nPrc As Numeric,_nOpc As Numeric) As Logical

Local _npreco := 0 As Numeric
Local _aArea     := FWGetArea() As Array
Local _cfildest  := "" As Character
Local _cfilmed   := "" As Character
Local _ndiamed   := 15 As Numeric
Local _nfatortra := 1.0476 As Numerics
Local _dinicial  := SToD('20010101') As DAte
Local _dfinal    := SToD('20010101') As Date
Local _cmens     := "" As Character
Local _cSvFilAnt := cFilAnt As Character //Salva a Filial Anterior 
Local _nmargetra := 0 As Numeric
Local _lRet      := .T. As Logical 
Local _nVLMin    := 0 As Numeric
Local _nVLMax    := 0 As Numeric
Local _cAliasZ09 := "" As Character
Local _cQry      := "" As Character

Default _nopc    := 1

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaççao Automatica)
If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_MOMS050") .Or. FWIsInCallStack("U_AOMS058X")
    Return .T.
EndIf

//Se For troca nota não valida preço de transferência
If M->C5_I_TRCNF = "S"
    //opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
    //opc 3 é quando é chamado do validador

    If _nopc == 1 .Or. _nopc == 3
        Return .T.
    Else
        Return " "
    EndIf
EndIf

_cfildest  := AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"SA1->A1_I_FILOR")) //filial destino do cliente selecionado
_nfatortra := 0 //fator a ser aplicado a média de preço

//Verifica se é validação de operação de movimentação de estoque 
If _coper $ SuperGetMV("IT_OPMEDIO",.F.,'20|22')

    _cAliasZ09 := GetNextAlias()

    _cQry := "SELECT Z09_PRECO, Z09_DESVIO, Z09.R_E_C_N_O_ AS RECNO"
    _cQry += "	FROM " + RetSqlName("Z09")+" Z09 "
    _cQry += "	WHERE Z09_CODOPE = '"+_cOper+"' "
    _cQry += "	  AND Z09_CODPRO = '"+_cProd+"' "
    _cQry += "	  AND Z09_INIVIG <= '"+DToS(Date())+"' "  
    _cQry += "	  AND Z09_FIMVIG >= '"+DToS(Date())+"' "
    _cQry += "	  AND ( Z09_FILORI = ' ' OR Z09_FILORI = '"+cfilant+"' ) "
    _cQry += "	  AND ( Z09_FILDES = ' ' OR  Z09_FILDES = '"+_cfildest+"' ) " 
    _cQry += "	  AND Z09.D_E_L_E_T_ = ' ' "
    _cQry += "	ORDER BY Z09_FILORI DESC, Z09_FILDES DESC "

    _cQry := ChangeQuery(_cQry)

    MPSysOpenQuery( _cQry,_cAliasZ09 )

    If (_cAliasZ09)->( !Eof() ) //Se achou prepara para validação
        _npreco := (_cAliasZ09)->Z09_PRECO
        _nmargetra := (_cAliasZ09)->Z09_DESVIO/100
    Else//Se não achou tabela de preço na regra retorna automaticamente que é preço válido
        //opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
        //opc 3 é quando é chamado do validador
        If _nopc == 1 .Or. _nopc == 3
            Return .T.
        Else
            Return " "
        EndIf
    EndIf
    (_cAliasZ09)->( DBCloseArea() ) //Fecha a área da consulta
Else
    _cfilmed   := SuperGetMV("IT_FILMEDT",.F.,"") //filiais que usam média de preço
    _ndiamed   := SuperGetMV("IT_DIASTRA",.F.,15)  //dias corridos para fazer a média de preço

    //Se não é transferência e estoque em filial sem média de preço segue valiação normal de tabela de preço de transferência

    //verifica se é transferencia, se não For retorna .T. direto
    Z09->( DBSetOrder(2) )

    If !((Posicione("SB1",1,xFilial("SB1")+AllTrim(_cProd),"B1_TIPO") == 'PA' ;
            .Or. Posicione("SB1",1,xFilial("SB1")+AllTrim(_cProd),"B1_GRUPO") == '0813') .And. ;
            Z09->(DBSeek(xFilial("Z09")+_cOper)) )

        //opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
        //opc 3 é quando é chamado do validador

        If _nopc == 1 .Or. _nopc == 3
            Return .T.
        Else
            Return " "
        EndIf
    EndIf

    //verifica se cliente tem campo filial origem válido
    SA1->( DBSetOrder(1) )

    If SA1->( DBSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI) )
        If !(AllTrim(SA1->A1_I_FILOR) >= '01' .And. AllTrim(SA1->A1_I_FILOR) <= 'ZZ')
            //opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
            //opc 3 é quando é chamado do validador

            If _nopc == 3
                U_ITMsg("Cliente não é filial válida para receber transferência","Validação","Favor solicitar apoio ao Departamento Fiscal/Comercial.",1)
            EndIf

            If _nopc == 1 .Or. _nopc == 3
                Return .F.
            Else
                Return " "
            EndIf
        EndIf
    EndIf

    //muda para filial destino para pegar o parâmetro
    cFilAnt := _cfildest

    _nfatortra := SuperGetMV("IT_FATORTR",.F.,1.0476) //fator a ser aplicado a média de preço

    //volta a filial local
    cFilAnt := _cSvFilAnt

    //Se filial destino pertence ao IT_FILMEDTRA usa média de preço
    If AllTrim(_cfildest) $ _cfilmed
        //carrega margem disponivel para a operação
        Z09->( DBSetOrder(1) )

        If Z09->( DBSeek(xFilial("Z09")+_cOper) )
            _nmargetra := (Z09->Z09_DESVIO/100) //margem de variação permitida
        Else
            _nmargetra := 0
        EndIf

        //calcula faixa de análise de média de vendas
        //ultimo dia de venda desde que não seja o dia atual (que não está completo) menos a quantidade de dias do IT_DIASTRA
        _adatas := U_AOMS002C(_cfildest,_cprod,_ndiamed)
        _dinicial := _adatas[1]
        _dfinal   := _adatas[2]

        //calcula média de preco de vendas
        _npreco := U_AOMS002M(_dinicial,_dfinal,_cfildest,_cprod,_nfatortra)

        If _npreco == 0
            //se não achar vendas do produto na filial destino avisa e usa tabela de preços de transferência
            _cmens := "tabela"
        EndIf
    Else
        //marca flag para executa cálculo por tabela de preço de transferência
        _cmens     := "tabela"
    EndIf

    If Len(_cmens) > 1 .And. _lRet
        //carrega preço da tabela de precos de transferencia para a operação do pedido de vendas
        _lRet := .F.
        _atabelas := U_AOMS002P(_cprod,xFilial("SC5"),_cfildest,_cOper)
        _npreco := _atabelas[1]
        _nmargetra := _atabelas[2]

        If _npreco > 0
            _lRet := .T.
        EndIf

        //se não achou preço na tabela avisa e trava o processo
        If .not. _lRet
            //opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
            //opc 3 é quando é chamado do validador

            If _nopc == 1 .Or. _nopc == 3
                If _nopc == 3
                    //Não tem tabela de preço de transferência para o produto
                    U_ITMsg("Para o tipo de operação "+_coper+" o produto "+_cprod+" não está cadastrado na Tabela de Preço de Transferência.",;
                        "Validação", "Favor solicitar apoio ao Departamento Fiscal.",1)
                EndIf
                Return _lRet
            Else
                Return _cprod
            EndIf
        EndIf
    EndIf
EndIf

If _npreco > 0  .And. _nPrc > 0
    //se achou preço acima de zero faz a validação
    _lRet := .T.

    //define preço máximo e mínimo
    _nVLMin := _npreco - ( _npreco * _nmargetra)
    _nVLMax := _npreco + ( _npreco * _nmargetra)

    If _nPrc < _nVLMin .Or. _nPrc > _nVLMax
        If _nopc == 1 .Or. _nopc == 3
            U_ITMsg("Produto: " + _cProd + " fora da regra de preço de transferencias.",;
                "Validação", "Mantenha o preço dentro de uma margem de " + AllTrim(Str(_nmargetra*100)) + "% do preço sugerido.",1)
        EndIf
        _lRet := .F.
    EndIf
EndIf

FWRestArea(_aArea)

//opc 1 é processamento normal, opc 2 é processamento que retorna o código do produto com problema
If _nopc == 2 .And. .not. _lRet
    Return _cProd
EndIf

Return ( _lRet )

/*
===============================================================================================================================
Programa----------: OMSMSGNF
Autor-------------: Alexandre Villar
Data da Criacao---: 22/05/2015
Descrição---------: Configura mensagem auxiliar da NF
Parametros--------: Nenhum
Retorno-----------: _lRet - (.T./.F.) de acordo com as validações
===============================================================================================================================
*/
User Function OMSMSGNF()

Local _aArea	:= FWGetArea()
Local _lRet     := .F.

If !Empty(SF2->F2_CARGA) .And. SF2->F2_I_FRET > 0
    SA2->( DBSetOrder(1) )
    If SA2->( DBSeek( xFilial('SA2') + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
        // Tratativa para Transportadora ou Autonomo do RS
        If SA2->A2_I_CLASS $ 'T/A' .And. SM0->M0_ESTENT == 'RS'
            // Verifica se o estado do transportador é diferente da filial que estiver faturando
            _lRet := ( SA2->A2_EST <> SM0->M0_ESTENT .And. SF2->F2_EST <> SM0->M0_ESTENT )
            // Tratativa para Transportadora de GO
        ElseIf SA2->A2_I_CLASS == 'T' .And. SM0->M0_ESTENT == 'GO'
            // Sempre que ele For credenciado (IN 1298), não gera mensagem. Mensagem para: 1-transportador fora do estado
            //e cliente dentro do estado. 2-Cliente de fora do estado, independente do transportador
            _lRet := (SA2->A2_I_I1298 <> 'S' .And. SA2->A2_I_I1298 <> 'L') .And. ((SF2->F2_EST==SM0->M0_ESTENT .And. SA2->A2_EST <> SM0->M0_ESTENT) .Or. (SF2->F2_EST<>SM0->M0_ESTENT))
            // Tratativa para Transportadora demais estados
        ElseIf SA2->A2_I_CLASS == 'T' .And. !SM0->M0_ESTENT $ 'RS/GO'
            //Cliente e transportador Fora do estado
            If SM0->M0_ESTENT $ 'PR'
                _lRet := ( SF2->F2_EST <> SM0->M0_ESTENT) .And. ( SA2->A2_EST <> SM0->M0_ESTENT)
            Else// Trasportador de fora do estado
                _lRet := ( SA2->A2_EST <> SM0->M0_ESTENT)
            EndIf
            // Tratativa para Autonomo
        ElseIf SA2->A2_I_CLASS == 'A' .And. SM0->M0_ESTENT <> 'RS'
            _lRet := SF2->F2_EST <> SM0->M0_ESTENT
        EndIf
    EndIf
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ITVLDEST
Autor-------------: Alexandre Villar
Data da Criacao---: 19/06/2015
Descrição---------: Verifica estoque disponível considerando estoque em poder de terceiros
Parametros--------: _ntipo - 1 estoque local, 2 estoque de terceiros
                    _cfilped - filial do pedido
                    _ccodped - código do pedido
                    _cLocal - Local do estoque					
Retorno-----------: _lRet - (.T./.F.) se tem saldo para liberar o pedido
===============================================================================================================================
*/
User Function ITVLDEST( _nTipo , _cFilPed , _cCodPed , _cLocal  , _aProd )

Local _lRet		:= .F.,I
Local _lErro    := .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _aItens	:= {}
Local _aSaldo   := {}
Local _nPos     := 0,_cPictQtde
Local _cCodLib  := AllTrim(SuperGetMV('IT_EST3LIB',.T.,''))
Local _cValSald := AllTrim(SuperGetMV('IT_VALSALD',.T.,'1'))

Default _cLocal	:= ''
Default _nTipo	:= 0
Default _aProd	:= {}

If _cFilPed + _cCodPed <> SC5->C5_FILIAL + SC5->C5_NUM
    SC5->( DBSetOrder(1) )
    SC5->( DBSeek( _cFilPed + _cCodPed ) )
EndIf
SC6->( DBSetOrder(1) )
If SC6->( DBSeek( _cFilPed + _cCodPed ) )
    While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == _cFilPed + _cCodPed
        _cTes := Upper( AllTrim( Posicione( "SF4" , 1 , xFilial("SF4") + SC6->C6_TES , "F4_ESTOQUE" ) ) )

        If _cTes == "S" .And. !(SC5->C5_FILIAL = "40" .And. SC5->C5_I_OPER $ "06/10/31/41" .And. SC6->C6_LOCAL $ "50/52")
            SC9->( DBSetOrder(1) )
            If SC9->( DBSeek( SC6->C6_FILIAL + SC6->C6_NUM + SC6->C6_ITEM  ) )
                If _nTipo = 1
                    _lRet:= .T.
                    If (_nPos:=aScan(_aItens,{|I| I[1]+I[2] == SC9->C9_PRODUTO+SC9->C9_LOCAL })) = 0
                        aAdd(_aItens,{SC9->C9_PRODUTO,SC9->C9_LOCAL,SC9->C9_QTDLIB, SC9->(RECNO()) ,SC9->C9_FILIAL , SC9->C9_BLEST })
                    Else
                        If !(AllTrim( SC9->C9_BLEST ) == AllTrim( _cCodLib ))//Coloco o errado para validar lá em baixo
                            _aItens[_nPos,6]:=SC9->C9_BLEST
                        EndIf
                        _aItens[_nPos,3]+=SC9->C9_QTDLIB
                    EndIf
                    SC6->( DBSkip() )
                    Loop
                EndIf

                _cQuery := " SELECT "
                _cQuery += "     SB2.B2_QATU AS SALDO , "
                _cQuery += "     SB2.B2_QATU - SB2.B2_RESERVA AS SALDO_R , "
                _cQuery += "     SB2.B2_QATU - SB2.B2_RESERVA + SB2.B2_QNPT AS SALDO_3 "
                _cQuery += " FROM  "+ RetSqlName('SB2') +" SB2 "
                _cQuery += " WHERE "
                _cQuery += "     SB2.B2_FILIAL  = '"+ SC9->C9_FILIAL  +"' "
                _cQuery += " AND SB2.B2_COD     = '"+ SC9->C9_PRODUTO +"' "
                _cQuery += " AND SB2.B2_LOCAL   = '"+ SC9->C9_LOCAL   +"' "
                _cQuery += " AND SB2.D_E_L_E_T_ = ' ' "

                MPSysOpenQuery(_cQuery,_cAlias)

                (_cAlias)->( DBGoTop() )
                If (_cAlias)->( !Eof() )
                    // Verifica o saldo em estoque, desconta a reserva e soma o estoque em poder de terceiros
                    If SC9->C9_LOCAL $ _cLocal
                        _lRet := ( (_cAlias)->SALDO_3 >= SC9->C9_QTDLIB )
                        // Verifica o saldo em estoque e desconta a reserva
                    Else
                        _lRet := ( (_cAlias)->SALDO_R >= SC9->C9_QTDLIB )
                    EndIf
                Else
                    _lRet := .F.
                EndIf

                //Valida com calcest
                If _lRet
                    aSaldos := CalcEst( SC9->C9_PRODUTO , SC9->C9_LOCAL , Date() + 1 ) //obtém o saldo final em estoque na data informada
                    _nQatu  := aSaldos[01]//SB2->B2_QATU

                    If _nQatu < SC9->C9_QTDLIB
                        U_ITMsg("O produto " + SC9->C9_PRODUTO + " no armazém " + SC9->C9_LOCAL + " possui divergência de saldo na SB2",;
                            "Atenção","Entre em contato com o departamento de Custos",1)
                        _lRet := .F.
                    EndIf
                EndIf

                (_cAlias)->( DBCloseArea() )
            EndIf
        Else
            _lRet := .T.
        EndIf

        If !_lRet
            Exit
        EndIf

        SC6->( DBSkip() )
    EndDo
EndIf

If _nTipo = 1 .And. _lRet
    _cPictQtde:=PesqPict("SC9","C9_QTDLIB")
    SB2->(DBSetOrder(1))
    For I := 1 To Len(_aItens)
        _laAdd:=.T.
        If AllTrim( _aItens[I,6] ) == AllTrim( _cCodLib )
            If _cValSald = "2"
                SB2->( DBSeek(_aItens[I,5]+_aItens[I,1]+_aItens[I,2]) )
                _nSaldo:=SB2->B2_QATU//_aSaldo[1]//SaldoSB2()// (SB2->B2_QATU - SB2->B2_RESERVA)
            Else//If _cValSald = "1" qq cosia diferente de 2
                _aSaldo:=CalcEst( _aItens[I,1] , _aItens[I,2] , dDataBase+1 )
                _nSaldo:=_aSaldo[1]
            EndIf
            _lErro:= _aItens[I,3] > _nSaldo
            If _lErro
                _lRet :=.F.
            EndIf
        Else
            _lRet := .F.
        EndIf
        If _lErro
            SC9->(DBGoTo(_aItens[I,4]))
            aAdd( _aProd , { SC9->C9_CARGA, SC9->C9_PEDIDO , SC9->C9_ITEM , SC9->C9_PRODUTO , SC9->C9_LOCAL , TRANS(_aItens[I,3],_cPictQtde) , TRANS(_nSaldo,_cPictQtde) ,;
                "Problema no Estoque: Não existe saldo em estoque para faturar, Verifique os Pedidos Liberados. (C9_BLEST = '"+SC9->C9_BLEST+"')" } )
        EndIf
    Next I
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: ITCFOPS
Autor-----------: Jeovane
Data da Criacao-: 29/06/2014
Descrição-------: Funcao usada para buscar CFOPs de acordo com o tipo de operacao
Uso-------------: Italac
Parametros------: _cTpOper - Tipo de Operação
Retorno---------: _cRet    - CFOPS selecionados
===============================================================================================================================
*/
User Function ITCFOPS( _cTpOper )

Local _cRet		:= ""
Local _aArea	:= FWGetArea()

ZAY->( DBSetOrder(3) ) // ZAY_FILIAL + ZAY_TPOPER + ZAY_CF
ZAY->( DBSeek( xFilial("ZAY" ) ) )
While ZAY->( !Eof() ) .And. ZAY->ZAY_FILIAL == xFilial("ZAY")
    If ZAY->ZAY_TPOPER $ _cTpOper
        _cRet += AllTrim( ZAY->ZAY_CF ) + ";"
    EndIf
    ZAY->( DBSkip() )
EndDo

FWRestArea( _aArea )

Return( _cRet )

/*
===============================================================================================================================
Programa--------: ITCFOPS
Autor-----------: Jeovane
Data da Criacao-: 29/06/2014
Descrição-------: Funcao usada para selecionar CFOPs de acordo com o tipo de operacao
Parametros------: _cTpOper - Tipo de Operação
Retorno---------: _cRet    - CFOPS selecionados
===============================================================================================================================
*/
User Function LstTpCF()

Local i			:= 0
Local cCombo	:= " "

Private nTam		:= 0
Private nMaxSelect	:= 0
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ""
Private cTitulo		:= ""
Private MvParDef	:= ""
Private cConte		:= {}
Private nCont		:= 0

#IFDEF WINDOWS
    oWnd := GetWndDefault()
#EndIf

SX3->( DBSetOrder(2) )
If SX3->( DBSeek( "ZAY_TPOPER" ) )
    cCombo := X3Cbox()
EndIf

//"V=VENDA;T=TRANSFERENCIA;B=BONIFICACAO;R=REMESSA;O=OUTROS"

//A funcao StrTokArr() tem o objetivo de retornar um array, de acordo com os dados passados como parametro para a funcao
aOpcoes := StrTokArr( cCombo , ';' )

//Tratamento para carregar variaveis da lista de opcoes
nTam		:= 1
nMaxSelect	:= 5
cTitulo		:= "CFOP X Tipo de Operacao"

For i := 1 To Len( aOpcoes )
    MvParDef += SubStr( aOpcoes[i] , 1 , 1 )
    aAdd( aCat , SubStr( aOpcoes[i] , 3 , Len( aOpcoes[i] ) - 2 ) )
Next i

//Adiciona Opcao Todos
MvParDef += "A"
aAdd( aCat , "TODOS" )

MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )

//Executa funcao que monta tela de opcoes
F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

//Tratamento para separar retorno com barra ";"
&MvRet := ""

For i := 1 To Len( MvPar ) Step 1
    If !( SubStr( MvPar , i , 1 ) $ " |*" )
        &MvRet += SubStr( MvPar , i , 1 ) +";"
    EndIf
Next i

//Trata para tirar o ultimo caracter
&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )

// o usuario selecionar a opção de todos ele retornar todas as cfops cadastradas. 
cConte := StrTokArr( &MvRet , ";" )

For i := 1 To Len( cConte )
    If cConte[i] == 'A'
        nCont++
    EndIf
Next i

If nCont > 0
    &MvRet := "V;T;B;R;O"
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: vldPedBon
Autor-------------: Fabiano Dias
Data da Criacao---: 01/08/2011
Descrição---------: Funcao utilizada para verificar atraves da CFOP se o pedido de venda corrente é do tipo bonificacao, pois
------------------: este deverá entrar no sistema com o status bloqueado caso tenha valor acima de R$ 500,00
Parametros--------: aCols - Dados dos ítens do pedido de venda
Retorno-----------: Lógico - Define se o registro deverá ser bloqueado
===============================================================================================================================
*/
User Function vldPedBon( aCols )

Local _lRet		:= .F.
Local _x		:= 1
Local _cCFOP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_CF"	} )
Local _nValor	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_VALOR"	} )
Local _nSomator	:= 0

For _x := 1 To Len(aCols)
    // Se a linha nao estiver deletada
    If !aCols[_x][Len(aCols[_x])]
        //Efetua o somatorio dos itens para constatar se o pedido possui
        //um  valor acima de 500 reais, pois somente sera bloqueado os
        //pedidos com valor acima de 500 reais.

        _nSomator += aCols[_x][_nValor]
        //Caso encontre uma das duas CFOP citadas abaixo o pedido
        //de venda corrente sera considerado do tipo bonificacao.
        //================================================================================
        If AllTrim(aCols[_x][_cCFOP]) $ '5910/6910/5911/6911'
            _lRet  := .T.
        EndIf
    EndIf
Next _x

If !( _lRet .And. ( _nSomator > GetMV( "IT_VLRBON" ,, 500 ) ) )
    _lRet := .F.
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: vldContrato
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
Descrição---------: Funcao utilizada nos seguintes pontos de entrada: MSD2460/SF2460I para verificar se os dados do pedido na     
                    hora de seu faturamento podem ser armazenados na SD2,SF2 e SE1, isto porque eu posso inserir um pedido que    
                    tenha produtos oom desconto e fatura-lo em outro dia, so que no momento em que ele For faturado ele pode estar  
                    com a data de vigencia vencida, ou bloqueado, ou devido a alguma alteracao do depto comercial ele voltou a nao
                    estar mais aprovado, necessitando de uma nova aprovacao.	
Parametros--------:	cNumContr - código a ser localizado no ZAZ_COD
Retorno-----------: .T. se armazenara as informacoes do pedido com relacao a desconto na SD2,SF2 e SE1, ou .F. se nao podera	 
===============================================================================================================================
*/ 
User Function vldContrato(cNumContr)

Local aArea := FWGetArea()
Local lRet  := .F.
Local cQuery:= ""

//1 - Armazena se o tipo do contrato esta com a data de vigencia em vigor, se esta aprovado ou se esta bloqueado, caso 
//alguma das condicoes seja contraditoria ele retornara falso
//2 - Armazena o tipo do contrato 
Local aRetor:={.F.,""}

If (!Empty(cNumContr)) .And. (Len(AllTrim(cNumContr)) > 5)
    cQuery := "SELECT ZAZ_MSBLQL,ZAZ_DTFIM,ZAZ_STATUS,ZAZ_ABATIM"
    cQuery += " FROM " + RetSqlName("ZAZ")
    cQuery += " WHERE D_E_L_E_T_ = ' '  AND ZAZ_FILIAL = '" + xFilial("ZAZ") + "'"
    cQuery += " AND ZAZ_COD = '" + cNumContr + "' "

    MPSysOpenQuery(cQuery,"TMP17")

    TMP17->(DBGoTop())

    If TMP17->ZAZ_MSBLQL == '1'//Verifica se o contrato esta bloqueado
        lRet  := .F.
    ElseIf TMP17->ZAZ_STATUS == 'N'//Verifica se o contrato ainda nao foi aprovado pelo financeiro
        lRet  := .F.
    ElseIf TMP17->ZAZ_DTFIM < DToS(Date()) //Se o contrato estiver com a data de vigencia vencida de acordo com a data do servidor onde esta inslado o protheus
        lRet  := .F.
    Else
        lRet  := .T.//Permite o faturamento
    EndIf

    aRetor[1]:= lRet
    aRetor[2]:= TMP17->ZAZ_ABATIM

    TMP17->(DBCloseArea())

    FWRestArea(aArea)
EndIf

Return aRetor

/*
===============================================================================================================================
Programa----------: veriContrato
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
Descrição---------: Funcao para verificar se existe contrato de desconto contratual para o cliente ou sua rede.	
Parametros--------: 	cCodclient - código do cliente
                        cLojacli - loja do cliente
                        cCodProdut - código do produto
Retorno-----------: Array - aRetorno com as seguintes posicoes e valores           												
                               1 - Armazena o valor do desconto																			
                            2 - Se o contrato esta aprovado																				
                            3 - Se contrato esta com a data de vigencia valida															
                            4 - Numero do contrato	
===============================================================================================================================
*/            
User Function veriContrato(cCodclient,cLojacli,cCodProdut)

Local cQuery    := ""
Local nVlrDesc  := 0  //Armazena o valor de desconto integral
Local nVlrDesPa := 0  //Armazena o valor de desconto parcial
Local cAbatiment:= "" //Tipo do Abatimento
//Array que armazenara os seguintes valores nas seguinte posicoes
//1 - se possui contrato
//2 - numero do contrato
//3 - o estado do cliente(MG,SP,RO)
//4 - se o contrato esta aprovada
//5 - se o contrato esta com a data de vigencia valida       
//6 - Numero do contrato
Local aDados    := {.F.,"","",.T.,.T.}
//1 - Armazena o valor do desconto integral
//2 - Se o contrato esta aprovado
//3 - Se contrato esta com a data de vigencia valida
//4 - Numero do contrato                   
//5 - Armazena o valor do desconto parcial 
//6 - Tipo do abatimento
Local aRetorno  := {0,.T.,.T.,"",0,""}
Local aGetArea  := FWGetArea()
Local aAreaTMP10:= {}
Local lcontrato := .F.//Armazena se encontrou contrato na primeira checagem que eh por cliente + loja, caso nao encontre procura somente por cliente
Local nreg      := 0

cQuery := "SELECT ZAZ_COD,ZAZ_LOJA,ZAZ_STATUS,ZAZ_DTFIM"
cQuery += " FROM " + RetSqlName("ZAZ")
cQuery += " WHERE D_E_L_E_T_  = ' '  AND ZAZ_FILIAL = '" + xFilial("ZAZ") + "'"
cQuery += " AND ZAZ_CLIENT = '" + cCodclient + "'"
cQuery += " AND ZAZ_MSBLQL = '2'"

MPSysOpenQuery(cQuery,"TMP10")
DBSelectArea("TMP10")//NÃO TIRAR
Count To nreg
//Contabiliza o numero de registros encontrados pela query

TMP10->(DBGoTop())

//Se encontrar um contrato nao bloqueado para um cliente sem considerar a loja, caso ela tenha sido especificada no contrato

If nreg > 0
    While TMP10->(!Eof())
        If !Empty(TMP10->ZAZ_LOJA)
            //Verifica se a loja informada no contrato e a mesma loja informada no pedido
            If TMP10->ZAZ_LOJA == cLojacli
                //Possui contrato especifico para este cliente e loja
                lcontrato:=.T.

                aAreaTMP10:= TMP10->(GetArea())
                aDescontos:= u_VerItensC(TMP10->ZAZ_COD,cCodProdut,'C',cCodclient,cLojacli,'')
                nVlrDesc  := aDescontos[1] //Desconto Integral
                nVlrDesPa := aDescontos[2] //Desconto Parcial
                cAbatiment:= aDescontos[3] //Tipo do Abatimento
                FWRestArea(aAreaTMP10)

                //Possui contrato para o produto especificado
                If nVlrDesc > 0
                    //verifica se o contrato encontra-se vigente
                    If TMP10->ZAZ_DTFIM >= DToS(Date())
                        //Se o contrato estiver ativo
                        If TMP10->ZAZ_STATUS == 'S'
                            aRetorno[4]:=TMP10->ZAZ_COD//Numero do contrato
                            lcontrato:=.T.
                            Exit
                        Else
                            //Contrato nao aprovado
                            aRetorno[2]:=.F.
                            aRetorno[4]:=TMP10->ZAZ_COD
                            lcontrato:=.T.
                            Exit
                        EndIf
                    Else
                        //Data do contrato vigente nao esta ativa
                        aRetorno[3]:=.F.
                        aRetorno[4]:=TMP10->ZAZ_COD
                        lcontrato:=.T.
                        Exit
                    EndIf
                EndIf
            EndIf
        EndIf
        TMP10->(DBSkip())
    EndDo

    //Quando nao encontrar um contrato que tenha cliente + loja, ele vai buscar um mais generico somente por cliente
    If !lcontrato
        TMP10->(DBGoTop())

        While TMP10->(!Eof())
            If Empty(TMP10->ZAZ_LOJA)
                aAreaTMP10:= TMP10->(GetArea())
                aDescontos:= u_VerItensC(TMP10->ZAZ_COD,cCodProdut,'C',cCodclient,cLojacli,'')
                nVlrDesc  := aDescontos[1] //Desconto Integral
                nVlrDesPa := aDescontos[2] //Desconto Parcial
                cAbatiment:= aDescontos[3] //Tipo do Abatimento
                FWRestArea(aAreaTMP10)

                //possui contrato para o cliente sem loja especificada no contrato
                lcontrato:=.T.

                //Possui contrato para o produto especificado
                If nVlrDesc > 0
                    //verifica se o contrato encontra-se vigente
                    If TMP10->ZAZ_DTFIM >= DToS(Date())
                        //Se o contrato estiver ativo
                        If TMP10->ZAZ_STATUS == 'S'
                            aRetorno[4]:=TMP10->ZAZ_COD
                            lcontrato:=.T.
                            Exit
                        Else
                            //Contrato nao aprovado
                            aRetorno[2]:=.F.
                            aRetorno[4]:=TMP10->ZAZ_COD
                            lcontrato:=.T.
                            Exit
                        EndIf
                    Else
                        //Data do contrato vigente nao esta ativa
                        aRetorno[3]:=.F.
                        aRetorno[4]:=TMP10->ZAZ_COD
                        lcontrato:=.T.
                        Exit
                    EndIf
                EndIf
            EndIf
            TMP10->(DBSkip())
        EndDo
    EndIf
EndIf

If  !lcontrato
    //Se o cliente informado no pedido de vendas nao possuir um contrato(ou que este esteja bloqueado)procura pela rede
    aDados:= u_VerContRede(cCodclient,cLojacli)
    aRetorno[4]:= aDados[2]//Armazena numero do contrato

    If aDados[1]
        aDescontos:= u_VerItensC(aDados[2],cCodProdut,'R',cCodclient,cLojacli,aDados[3])
        nVlrDesc  := aDescontos[1] //Desconto Integral
        nVlrDesPa := aDescontos[2] //Desconto Parcial
        cAbatiment:= aDescontos[3] //Tipo do Abatimento
        //Se encontrou um contrato para o produto especificado
        If nVlrDesc > 0
            aRetorno[2]:= aDados[4]//Se o contrato esta aprovado
            aRetorno[3]:= aDados[5]//Se o contrato esta com a data de vigencia em vigor

            If !aRetorno[2]
                nVlrDesc := 0
                nVlrDesPa:= 0
            EndIf

            If !aRetorno[3]
                nVlrDesc := 0
                nVlrDesPa:= 0
            EndIf
        EndIf
    EndIf
EndIf

// Deleta os arquivos temporarios. 
TMP10->(DBCloseArea())

aRetorno[1]:= nVlrDesc   //Armazena o valor do desconto integral
aRetorno[5]:= nVlrDesPa  //Armazena o valor de desconto parcial
aRetorno[6]:= cAbatiment //Tipo do Abatimento

FWRestArea(aGetArea)

Return aRetorno

/*
===============================================================================================================================
Programa----------: VerContRede
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
Descrição---------: Funcao utilizada para verificar se existe contrato de desconto para a rede do cliente especificado no pedido
                       de vendas, esta funcao eh utilizada depois de constatar que nao existe contrato para o cliente.    
Parametros--------: 	cCodclient - código do cliente
                        cLojacli - loja do cliente
Retorno-----------: Array - aDados com as seguintes posicoes e valores           												
                        1 - se possui contrato																						
                        2 - numero do contrato																						
                        3 - o estado do cliente(MG,SP,RO)																			
                        4 - se o contrato esta aprovada																				
                        5 - se o contrato esta com a data de vigencia valida    
===============================================================================================================================
*/      

User Function VerContRede(cCodclient,cLojacli)

Local cQuery    := ""
Local cRede	    := ""
Local aDados    :={.F.,"","",.T.,.T.}
Local cEst		:=""
Local aGetArea :=FWGetArea()

cQuery := "SELECT A1_GRPVEN,A1_EST"
cQuery += " FROM " + RetSqlName("SA1")
cQuery += " WHERE D_E_L_E_T_  = ' '  AND A1_FILIAL = '" + xFilial("SA1") + "'"
cQuery += " AND A1_COD = '" + cCodclient + "'"
cQuery += " AND A1_LOJA = '" + cLojacli + "'"
cQuery += " AND A1_GRPVEN IS NOT NULL"

MPSysOpenQuery(cQuery,"TMP11")
TMP11->(DBGoTop())

//Caso o cliente tenha um grupo de vendas(Rede) especificado no seu cadastro
If !Empty(TMP11->A1_GRPVEN)
    //Armazena grupo de vendas e estado para liberar TMP11
    cRede:=TMP11->A1_GRPVEN
    cEst :=TMP11->A1_EST

    // Deleta os arquivos temporarios.

    //Pesquisa na tabela de desconto contratual se existe contrato para a rede do cliente especificado no pedido de vendas
    cQuery := "SELECT ZAZ_COD,ZAZ_DTFIM,ZAZ_STATUS"
    cQuery += " FROM " + RetSqlName("ZAZ")
    cQuery += " WHERE D_E_L_E_T_  = ' '  AND ZAZ_FILIAL = '" + xFilial("ZAZ") + "'"
    cQuery += " AND ZAZ_GRPVEN = '" + cRede + "'"
    cQuery += " AND ZAZ_MSBLQL = '2'"//Caso ele nao esteja bloqueado

    MPSysOpenQuery(cQuery,"TMP12")
    TMP12->(DBGoTop())

    //Se encontrar um contrato para um cliente sem considerar a loja, caso ela tenha sido especificada no contrato
    If !Empty(TMP12->ZAZ_COD)
        //Se o contrato estiver com a data de vigencia em vigor
        If TMP12->ZAZ_DTFIM >= DToS(Date())
            //Se o contrato estiver ativo
            If TMP12->ZAZ_STATUS == 'S'
                aDados[1]:=.T.
                aDados[2]:=TMP12->ZAZ_COD
                aDados[3]:=cEst
            Else
                aDados[1]:=.T.
                aDados[4]:=.F. //Contrato nao aprovado
                aDados[2]:=TMP12->ZAZ_COD
            EndIf
        Else
            aDados[1]:=.T.
            aDados[5]:=.F. //Contrato nao esta com a data vigente valida
            aDados[2]:=TMP12->ZAZ_COD
        EndIf
    EndIf

    TMP12->(DBCloseArea())
EndIf

TMP11->(DBCloseArea())
FWRestArea(aGetArea)

Return aDados

/*
===============================================================================================================================
Programa----------: verItensC
Autor-------------: Renato de Morcerf
Data da Criacao---: 02/09/2008
Descrição---------: Procura o valor do desconto para determinado produto especificado no pedido de venda, de acordo com os dados
                       fornecidos no contrato de desconto contratual.    
Parametros--------: 	codContrato - codigo do contrato
                        cCodProduto - código do produto
                        ctipoPesqu - tipo de pesquisa
                        cCodclient - código do cliente
                        cLojacli - loja do cliente
                        cEst - estado do cliente
Retorno-----------: % de desconto de acordo com o valor informado no contrato de desconto contratual    
===============================================================================================================================
*/ 
User Function verItensC(codContrato,cCodProduto,ctipoPesqu,cCodclient,cLojacli,cEst)

Local cQuery    := ""
Local nVlrDesc  := 0  //Desconto Integral
Local nVlrDesPa := 0  //Desconto Parcial
Local cAbatiment:= "" //Armazena o tipo do Abatimento
Local lControle :=.F.
Local aGetArea  := FWGetArea()
//1 - Armazena o desconto integral
//2 - Armazena o desconto parcial
//3 - Tipo do Abatimento
Local aDescontos:= {0,0,""}

//Caso tenha sido informado o cliente no cabecalho do cadastro do desconto contratual
//nao sera necessario efetuar algumas consideracoes para encontrar o valor do desconto fornecido para 
//os produtos informados nos itens do contrato
If ctipoPesqu == 'C'

    cQuery := "SELECT ZB0_DESCTO,ZB0_DESCPA,ZB0_ABATIM"
    cQuery += " FROM " + RetSqlName("ZB0")
    cQuery += " WHERE D_E_L_E_T_  = ' '  AND ZB0_FILIAL = '" + xFilial("ZB0") + "'"
    cQuery += " AND ZB0_COD = '" + codContrato + "'"
    cQuery += " AND ZB0_SB1COD = '" + cCodProduto + "'"

    MPSysOpenQuery(cQuery,"TMP13")
    TMP13->(DBGoTop())

    //Caso o cliente tenha um grupo de vendas(Rede) especifico no seu cadastro
    If !Empty(TMP13->ZB0_DESCTO)
        nVlrDesc  := TMP13->ZB0_DESCTO
        nVlrDesPa := TMP13->ZB0_DESCPA
        cAbatiment:= TMP13->ZB0_ABATIM
    EndIf

    TMP13->(DBCloseArea())

    //Quando informado a rede no cabecalho do cadastro do desconto contratual, deve-se checar se
    //foi informado o campo cliente nos itens do contrato, caso tenha sido informado verificar a loja e o estado
    //ou informado o campo estado sozinho para uma determinada rede para depois disso pegar o valor do desconto de acordo com o produto
Else
    cQuery := "SELECT ZB0_CLIENT,ZB0_LOJA,ZB0_EST,ZB0_DESCTO,ZB0_DESCPA,ZB0_ABATIM,ZB0_COD"
    cQuery += " FROM " + RetSqlName("ZB0")
    cQuery += " WHERE D_E_L_E_T_  = ' ' AND ZB0_FILIAL = '" + xFilial("ZB0") + "'"
    cQuery += " AND ZB0_COD = '" + codContrato + "'"
    cQuery += " AND ZB0_SB1COD = '" + cCodProduto + "'"

    MPSysOpenQuery(cQuery,"TMP14")
    TMP14->(DBGoTop())

    //Caso o cliente tenha no contrato um desconto para o produto especificado
    If !Empty(TMP14->ZB0_COD)
        //Procura um cliente + loja + estado
        While TMP14->(!Eof())
            If (TMP14->ZB0_CLIENT == cCodclient) .And. (TMP14->ZB0_LOJA == cLojacli) .And. (TMP14->ZB0_EST == cEst)
                nVlrDesc  := TMP14->ZB0_DESCTO
                nVlrDesPa := TMP14->ZB0_DESCPA
                cAbatiment:= TMP14->ZB0_ABATIM
                lControle:=.T.
                Exit
            EndIf
            TMP14->(DBSkip())
        EndDo

        TMP14->(DBGoTop())

        If !lControle
            //Procura um cliente + loja
            While TMP14->(!Eof())
                If (TMP14->ZB0_CLIENT == cCodclient) .And. (TMP14->ZB0_LOJA == cLojacli) .And. Empty(TMP14->ZB0_EST)
                    nVlrDesc  := TMP14->ZB0_DESCTO
                    nVlrDesPa := TMP14->ZB0_DESCPA
                    cAbatiment:= TMP14->ZB0_ABATIM
                    lControle:=.T.
                    Exit
                EndIf
                TMP14->(DBSkip())
            EndDo
        EndIf

        TMP14->(DBGoTop())

        If !lControle
            //Procura um cliente
            While TMP14->(!Eof())
                If (TMP14->ZB0_CLIENT == cCodclient) .And. Empty(TMP14->ZB0_LOJA) .And. Empty(TMP14->ZB0_EST)
                    nVlrDesc  := TMP14->ZB0_DESCTO
                    nVlrDesPa := TMP14->ZB0_DESCPA
                    cAbatiment:= TMP14->ZB0_ABATIM
                    lControle:=.T.
                    Exit
                EndIf
                TMP14->(DBSkip())
            EndDo
        EndIf

        //Procura somente por estado
        TMP14->(DBGoTop())

        If !lControle
            //Procura um estado
            While TMP14->(!Eof())
                If (TMP14->ZB0_EST == cEst) .And. Empty(TMP14->ZB0_CLIENT) .And. Empty(TMP14->ZB0_LOJA)
                    nVlrDesc  := TMP14->ZB0_DESCTO
                    nVlrDesPa := TMP14->ZB0_DESCPA
                    cAbatiment:= TMP14->ZB0_ABATIM
                    lControle:=.T.
                    Exit
                EndIf
                TMP14->(DBSkip())
            EndDo
        EndIf

        TMP14->(DBGoTop())

        //So existe um registro caso nao se encontre dados nos filtros, pois a SQL ja filtro por produto
        If !lControle
            While TMP14->(!Eof())
                If Empty(TMP14->ZB0_EST) .And. Empty(TMP14->ZB0_CLIENT) .And. Empty(TMP14->ZB0_LOJA)
                    nVlrDesc  := TMP14->ZB0_DESCTO
                    nVlrDesPa := TMP14->ZB0_DESCPA
                    cAbatiment:= TMP14->ZB0_ABATIM
                    lControle:=.T.
                    Exit
                EndIf
                TMP14->(DBSkip())
            EndDo
        EndIf
    EndIf

    TMP14->(DBCloseArea())
EndIf

aDescontos[1]:= nVlrDesc   //Desconto integral
aDescontos[2]:= nVlrDesPa  //Desconto parcial
aDescontos[3]:= cAbatiment //Tipo do abatimento

FWRestArea(aGetArea)

Return aDescontos

/*
===============================================================================================================================
Programa--------: Veriprog
Autor-----------: Josué Danich Prestes
Data da Criacao-: 12/05/2016
Descrição-------: Verifica e ajusta programações de entrega na exclusão do pedido
Parametros------: Nenhum
Retorno---------: lret - continua com exclusão do pedido ou não
===============================================================================================================================
*/
User Function Veriprog( )

Local lret := .T.
Local _cfilial2 	:= ""
Local _ccodigo2 	:= ""
Local _cstatus2 	:= ""
Local _cfilial 	:= ""
Local _ccodigo 	:= ""
Local _cstatus 	:= ""
Local _cusrlo  	:= ""
Local _cusrco  	:= ""
Local _nzf7		:= 0
Local _nzf8		:= 0
Local _nzf9		:= 0
Local _cEmail	:= ""
Local _nprogs 	:= 0
Local _aAreaSC5  	:= SC5->( FWGetArea() )
Local _aAreaZF7  	:= ZF7->( FWGetArea() )
Local _aAreaZF8  	:= ZF8->( FWGetArea() )
Local _aAreaZF9  	:= ZF9->( FWGetArea() )
Local _cAlias		:= ""

Private _cfil1 		:= ""
Private _cped1 		:= ""
Private _cfil2 		:= ""
Private _cped2 		:= ""

_cQuery := " SELECT "
_cQuery +=     " ZF8.ZF8_FILIAL AS FILIAL,"
_cQuery +=     " ZF8.ZF8_CODPRG AS CODPRG,"
_cQuery +=     " ZF8.ZF8_ITEM   AS ITEM,"
_cQuery +=     " ZF7.ZF7_STATUS AS STSZF7, "
_cQuery +=     " ZF7.ZF7_USRLOG AS USRLOG,"
_cQuery +=     " ZF7.R_E_C_N_O_ AS ZF7RECNO,"
_cQuery +=     " ZF8.R_E_C_N_O_ AS ZF8RECNO,"
_cQuery +=     " ZF7.ZF7_USRPRG AS USRPRG"
_cQuery += " FROM "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('ZF7') +" ZF7 "
_cQuery += " WHERE "
_cQuery +=     " ZF8.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZF8.ZF8_FILIAL = ZF7.ZF7_FILIAL "
_cQuery += " AND ZF8.ZF8_CODPRG = ZF7.ZF7_CODIGO "
_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
_cQuery += " AND ZF8.ZF8_FILPED = '"+ SC5->C5_FILIAL +"' "
_cQuery += " AND ZF8.ZF8_NUMPED = '"+ SC5->C5_NUM    +"' "

_cAlias := GetNextAlias()

MPSysOpenQuery(_cQuery,_cAlias)
(_cAlias)->( DBGoTop() )

//Se achou como pedido primário de uma programação de entrega procura se tem um outro pedido atrelado como troca nota
If !((_cAlias)->( Eof() ))
    _cQuery := " SELECT "
    _cQuery +=     " ZF9.ZF9_FILIAL AS FILIAL,"
    _cQuery +=     " ZF9.ZF9_CODPRG AS CODPRG,"
    _cQuery +=     " ZF7.ZF7_STATUS AS STSZF7, "
    _cQuery +=     " ZF7.ZF7_USRLOG AS USRLOG,"
    _cQuery +=     " ZF7.R_E_C_N_O_ AS ZF7RECNO,"
    _cQuery +=     " ZF9.R_E_C_N_O_ AS ZF9RECNO,"
    _cQuery +=     " ZF7.ZF7_USRPRG AS USRPRG"
    _cQuery += " FROM "+ RetSqlName('ZF9') +" ZF9, "+ RetSqlName('ZF7') +" ZF7 "
    _cQuery += " WHERE "
    _cQuery +=     " ZF9.D_E_L_E_T_ = ' ' "
    _cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
    _cQuery += " AND ZF9.ZF9_FILIAL = ZF7.ZF7_FILIAL "
    _cQuery += " AND ZF9.ZF9_CODPRG = ZF7.ZF7_CODIGO "
    _cQuery += " AND ZF7.ZF7_STATUS <> '6' "
    _cQuery += " AND ZF9.ZF9_FILIAL = '"+ (_cAlias)->FILIAL 	+"' "
    _cQuery += " AND ZF9.ZF9_CODPRG = '"+ (_cAlias)->CODPRG    	+"' "
    _cQuery += " AND ZF9.ZF9_ITNPED = '"+ (_cAlias)->ITEM    	+"' "

    _cAlias2 := GetNextAlias()

    MPSysOpenQuery(_cQuery,_cAlias2)
    (_cAlias2)->( DBGoTop() )
//Se não achou como pedido primário fecha a query e procura como pedido de troca nota em uma programação
Else
    _cQuery := " SELECT "
    _cQuery +=     " ZF9.ZF9_FILIAL AS FILIAL,"
    _cQuery +=     " ZF9.ZF9_CODPRG AS CODPRG,"
    _cQuery +=     " ZF9.ZF9_ITNPED AS ITNPED,"
    _cQuery +=     " ZF7.ZF7_STATUS AS STSZF7, "
    _cQuery +=     " ZF7.ZF7_USRLOG AS USRLOG,"
    _cQuery +=     " ZF7.R_E_C_N_O_ AS ZF7RECNO,"
    _cQuery +=     " ZF9.R_E_C_N_O_ AS ZF9RECNO,"
    _cQuery +=     " ZF7.ZF7_USRPRG AS USRPRG"
    _cQuery += " FROM "+ RetSqlName('ZF9') +" ZF9, "+ RetSqlName('ZF7') +" ZF7 "
    _cQuery += " WHERE "
    _cQuery +=     " ZF9.D_E_L_E_T_ = ' ' "
    _cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
    _cQuery += " AND ZF9.ZF9_FILIAL = ZF7.ZF7_FILIAL "
    _cQuery += " AND ZF9.ZF9_CODPRG = ZF7.ZF7_CODIGO "
    _cQuery += " AND ZF7.ZF7_STATUS <> '6' "
    _cQuery += " AND ZF9.ZF9_FILIAL = '"+ SC5->C5_FILIAL +"' "
    _cQuery += " AND ZF9.ZF9_PEDIDO = '"+ SC5->C5_NUM    +"' "

    _cAlias2 := GetNextAlias()

    MPSysOpenQuery(_cQuery,_cAlias2)
    (_cAlias2)->( DBGoTop() )

    //Se achou como pedido de nota fiscal de troca procura o pedido principal em programação
    If !((_cAlias2)->( Eof() ))
        _cQuery := " SELECT "
        _cQuery +=     " ZF8.ZF8_FILIAL AS FILIAL,"
        _cQuery +=     " ZF8.ZF8_CODPRG AS CODPRG,"
        _cQuery +=     " ZF8.ZF8_ITEM   AS ITEM,"
        _cQuery +=     " ZF7.ZF7_STATUS AS STSZF7, "
        _cQuery +=     " ZF7.ZF7_USRLOG AS USRLOG,"
        _cQuery +=     " ZF7.R_E_C_N_O_ AS ZF7RECNO,"
        _cQuery +=     " ZF8.R_E_C_N_O_ AS ZF8RECNO,"
        _cQuery +=     " ZF7.ZF7_USRPRG AS USRPRG"
        _cQuery += " FROM "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('ZF7') +" ZF7 "
        _cQuery += " WHERE "
        _cQuery +=     " ZF8.D_E_L_E_T_ = ' ' "
        _cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
        _cQuery += " AND ZF8.ZF8_FILIAL = ZF7.ZF7_FILIAL "
        _cQuery += " AND ZF8.ZF8_CODPRG = ZF7.ZF7_CODIGO "
        _cQuery += " AND ZF7.ZF7_STATUS <> '6' "
        _cQuery += " AND ZF8.ZF8_FILIAL = '"+ (_cAlias2)->FILIAL 	+"' "
        _cQuery += " AND ZF8.ZF8_CODPRG = '"+ (_cAlias2)->CODPRG    	+"' "
        _cQuery += " AND ZF8.ZF8_ITEM = '" + (_cAlias2)->ITNPED    	+"' "

        _cAlias := GetNextAlias()

        MPSysOpenQuery(_cQuery,_cAlias)
        (_cAlias)->( DBGoTop() )
    EndIf
EndIf

//Guarda dados de pedido na programação e na programação de troca nota
If ((_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->STSZF7 ))
    lret := .F.
    _nprogs++
    _cfilial := (_cAlias)->FILIAL
    _ccodigo := (_cAlias)->CODPRG
    _cstatus := (_cAlias)->STSZF7
    _cusrlo  := (_cAlias)->USRLOG
    _cusrco  := (_cAlias)->USRPRG
    _nzf7	  := (_cAlias)->ZF7RECNO
    _nzf8	  := (_cAlias)->ZF8RECNO
EndIf

If ((_cAlias2)->( !Eof() ) .And. !Empty( (_cAlias2)->STSZF7 ))
    lret := .F.
    _nprogs++
    _cfilial2 := (_cAlias2)->FILIAL
    _ccodigo2 := (_cAlias2)->CODPRG
    _cstatus2 := (_cAlias2)->STSZF7
    _cusrlo  := (_cAlias2)->USRLOG
    _cusrco  := (_cAlias2)->USRPRG
    _nzf7	  := (_cAlias2)->ZF7RECNO
    _nzf9	  := (_cAlias2)->ZF9RECNO
EndIf

//Fecha queries
(_cAlias2)->( DBCloseArea() )
(_cAlias)->( DBCloseArea() )

//posiciona tabelas de programação de logpitica
ZF7->( DBGoTo(_nzf7) )
ZF8->( DBGoTo(_nzf8) )
ZF9->( DBGoTo(_nzf9) )

//Guarda dados de pedidos da zf8 e zf9 para poderem ser usados mesmo depois de apagar as programações
_cfil1 := ZF8->ZF8_FILPED
_cped1 := ZF8->ZF8_NUMPED
_cfil2 := ZF9->ZF9_FILIAL
_cped2 := ZF9->ZF9_PEDIDO

If !Empty(_cusrlo)
    _cEmail :=FWSFAllUsers({_cusrlo},{"USR_EMAIL"})[1][3]
EndIf

If !Empty(_cEmail)
	_cEmail += ','
EndIf

If !Empty(_cusrco)
    _cEmail += FWSFAllUsers({_cusrco},{"USR_EMAIL"})[1][3]
EndIf

If !lret
    If _nprogs == 1
        _lresp := .F.
        _lresp := U_ITMsg('O pedido selecionado está amarrado à uma programação de entrega da Logística ! '	+ Chr(13) + Chr(10)  + Chr(13) + Chr(10)  +;
            'A programação será ajustada de acordo com esta exclusão e um email de alerta será enviado para ' + _cemail ,;
            'Validação de programação de entrega',;
            'Deseja continuar ajustando a programação?'+ Chr(13) + Chr(10) + Chr(13) + Chr(10) +;
            '['+ _cfilial +'/'+ _ccodigo +']  - Pedido  ' + _cfil1 + '/' + _cped1 + '- Status: '+ U_ITRETBOX( _cstatus , 'ZF7_STATUS' ),3,2,2)
        If _lresp
            lret := .T.
            If u_remprog() //Remove programação e retorna true se bem sucedido
                u_mailprog(_cemail, 1) //Envia email de remoção de pedido da programação para responsáveis
                lret := .T.
            Else
                U_ITMsg('Não foi possível realizar ajustes na programação, exclusão não será realizada!',,,1)
            EndIf
        EndIf
    Else
        _lresp := .F.
        _lresp := U_ITMsg('O pedido selecionado está amarrado à programações de entrega e troca nota da Logística ! '	+ Chr(13) + Chr(10)  + Chr(13) + Chr(10)  +;
            'As programações será ajustada de acordo com esta exclusão e um email de alerta será enviado para ' + _cemail ,;
            'Validação de programação de entrega',;
            'Deseja continuar ajustando as programações?'+ Chr(13) + Chr(10) + ;
            '['+ _cfilial +'/'+ _ccodigo +']  - Pedido  ' + _cfil1 + '/' + _cped1 + '- Status: '+ U_ITRETBOX( _cstatus , 'ZF7_STATUS' ) + Chr(13) + Chr(10) +;
            '['+ _cfilial2 +'/'+ _ccodigo2 +']  - Pedido  ' + _cfil2 + '/' + _cped2 + '- Status: '+ U_ITRETBOX( _cstatus2 , 'ZF7_STATUS' )  ,3,2,2)
        If _lresp
            If u_remprog() //Remove programação e retorna true se bem sucedido
                u_mailprog(_cemail, 2) //Envia email de remoção de pedido da programação para responsáveis
                lret := .T.
            Else
                U_ITMsg( 'Não foi possível realizar ajustes nas programações, exclusão não será realizada!', 'Atenção!',,1)
            EndIf
        EndIf
    EndIf
EndIf

SC5->( FWRestArea(_aAreaSC5) )
ZF7->( FWRestArea(_aAreaZF7) )
ZF8->( FWRestArea(_aAreaZF8) )
ZF9->( FWRestArea(_aAreaZF9) )

Return lret

/*
===============================================================================================================================
Programa--------: mailprog
Autor-----------: Josué Danich Prestes
Data da Criacao-: 12/05/2016
Descrição-------: Monta e dispara o WF de cancelamento de programação de entrega
Parametros------: _cEmail - email para enviar WF
                    _ntipo - se é programação de entrega ( 1 ) ou de entrega com troca nota ( 2 )
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function mailprog( _cEmail, _ntipo   )

Local _aConfig		:= U_ITCFGEML('')
Local _cMsgEml		:= ''
Local _cStsAux		:= ''

_cMsgEml := '<html>'
_cMsgEml += '<head><title>Programação de Entrega</title></head>'
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

_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Id. da Programação: <b>'+ ZF7->ZF7_FILIAL +'/'+ ZF7->ZF7_CODIGO +'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ AllTrim( Posicione('SM0',1,cEmpAnt+ZF7->ZF7_FILIAL,'M0_FILIAL') ) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Coordenador:</b></td>'
_cMsgEml += '      <td class="itens" >'+ AllTrim( Posicione('SA3',1,xFilial('SA3')+ZF7->ZF7_CODSUP,'A3_NOME') ) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Tipo de Carga:</b></td>'
_cMsgEml += '      <td class="itens" >'+ U_ITRETBOX( ZF7->ZF7_TIPCAR , 'ZF7_TIPCAR' ) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Data Aprov.:</b></td>'
_cMsgEml += '      <td class="itens" >'+ DToC( ZF7->ZF7_DATA ) +' - '+ SubStr( ZF7->ZF7_HORA , 1 , 5 ) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Prazo:</b></td>'
_cMsgEml += '      <td class="itens" >'+ U_ITRETBOX( ZF7->ZF7_PRAZO , 'ZF7_PRAZO' ) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Obs. Program.:</b></td>'
_cMsgEml += '      <td class="itens" >'+ AllTrim( ZF7->ZF7_OBS ) +'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Motivo da remoção:</b></td>'
_cMsgEml += '      <td class="itens" > Exclusão do pedido </td>'
_cMsgEml += '    </tr>'

_cMsgEml += '	<tr>'
_cMsgEml += '		<td class="grupos" align="center" colspan="2"><b>Para maiores informações acesse o sistema e visualize a programação.</b></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '	<tr>'
_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="800">'
_cMsgEml += '    <tr>'

_cMsgEml += '      <td align="center" colspan="3" class="grupos">Pedido removidos da Programação por exclusão</b></td>'

_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'


_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Pedidos:</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Peso:</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="60%"><b>Cliente:</b></td>'

_cMsgEml += '    </tr>'

//Posiciona SC5
SC5->( DBSetOrder(1) )
SC5->( DBSeek( _cfil1 + _cped1 ))

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%">'+ SC5->C5_FILIAL +'-'+ SC5->C5_NUM			+'</td>'
_cMsgEml += '      <td class="itens" align="right"  width="20%">'+ AllTrim( Transform( SC5->C5_I_PESBR , '@E 999,999,999.9999' ) )			+'</td>'
_cMsgEml += '      <td class="itens" align="left"   width="60%">'+ SC5->C5_CLIENTE +'/'+ SC5->C5_LOJACLI +' - '+ PadR( SC5->C5_I_NOME , 60 )	+'</td>'
_cMsgEml += '    </tr>'

If _ntipo == 2
    //Posiciona SC5
    SC5->( DBSeek( _cfil2 + _cped2 ))
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="20%">'+ SC5->C5_FILIAL +'-'+ SC5->C5_NUM			+'</td>'
    _cMsgEml += '      <td class="itens" align="right"  width="20%">'+ AllTrim( Transform( SC5->C5_I_PESBR , '@E 999,999,999.9999' ) )			+'</td>'
    _cMsgEml += '      <td class="itens" align="left"   width="60%">'+ SC5->C5_CLIENTE +'/'+ SC5->C5_LOJACLI +' - '+ PadR( SC5->C5_I_NOME , 60 )	+'</td>'
    _cMsgEml += '    </tr>'
EndIf

_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cEmlLog := ''

_cStsAux := 'Remoção de Pedidos por exclusão'

U_ITENVMAIL( _aConfig[01] , _cEmail ,,, 'Programação de entregas - Exclusão de Pedido ['+ DToC( Date() ) +']' , _cMsgEml ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cEmlLog )

Return

/*
================================================================================================================================
Programa--------: Remprog
Autor-----------: Josué Danich Prestes
Data da Criacao-: 12/05/2016
Descrição-------: Remove programação de entrega de pedido excluido
Parametros------: Nenhum
Retorno---------: lret - sempre true
===============================================================================================================================
*/
User Function Remprog()

Local _lRet  		:= .F.
Local _npeds 		:= 0
Local _cAlias 	:= ""

//Analisa se existe mais de um pedido na programação de entrega
_cQuery := " SELECT "
_cQuery +=     " COUNT(ZF8_FILIAL) AS TOTI"
_cQuery += " FROM "+ RetSqlName('ZF8') +" ZF8 "
_cQuery += " WHERE "
_cQuery +=     " ZF8.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZF8.ZF8_FILIAL = '" + ZF7->ZF7_FILIAL + "'"
_cQuery += " AND ZF8.ZF8_CODPRG = '" + ZF7->ZF7_CODIGO + "'"

_cAlias := GetNextAlias()

MPSysOpenQuery(_cQuery,_cAlias)
(_cAlias)->( DBGoTop() )

_npeds := (_cAlias)->TOTI

(_cAlias)->( DBCloseArea() )

BEGIN TRANSACTION
    If _npeds == 1
        //Se é o único pedido da programação mantém o registro e muda a programação para cancelada
        ZF7->( RecLock("ZF7", .F.) )
        ZF7->ZF7_STATUS := '6'
        ZF7->( MSUnLock() )
    Else
        //Se tem mais de um pedido na programação faz a exclusão do pedido e do pedido de troca nota da programação
        ZF8->( RecLock("ZF8", .F.))
        ZF8->( DBDelete() )
        ZF8->( MSUnLock() )

        //Se tem pedido para troca de nota também exclui a programação
        If !( ZF9->( Eof() ) )
            ZF9->( RecLock("ZF9", .F.))
            ZF9->( DBDelete() )
            ZF9->( MSUnLock() )
        EndIf
    EndIf
END TRANSACTION

_lRet := .T.

Return _lRet

/*
===============================================================================================================================
Programa----------: OMSMSGN2
Autor-------------: Vanderson Azevedo
Data da Criacao---: 09/11/2016
Descricao---------: Valida mensagem fiscal para credenciados da IN1298 de Goias
Parametros--------: Nenhum
Retorno-----------: _lRet - (.T./.F.) de acordo com as valida??es
Usuario-----------: Rotina reescrita a partir do fonte MOMS008
===============================================================================================================================
*/
User Function OMSMSGN2()

Local _aArea	:= FWGetArea()
Local _lRet     := .F.

If !Empty(SF2->F2_CARGA) .And. SF2->F2_I_FRET > 0
    SA2->( DBSetOrder(1) )
    If SA2->( DBSeek( xFilial('SA2') + SF2->( F2_I_CTRA + F2_I_LTRA ) ) )
        // Verifica se e transportadora ou Autonomo
        If SA2->A2_I_CLASS == 'T' .And. SM0->M0_ESTENT == 'GO' .And. SA2->A2_I_I1298 == 'S'
            // Verifica se é uma operação para fora do estado
            _lRet := ( SA2->A2_I_I1298 == 'S' .And. SF2->F2_EST <> SM0->M0_ESTENT )
        EndIf
    EndIf
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
================================================================================================================================
Programa--------: omsvldent
Autor-----------: Josué Danich Prestes
Data da Criacao-: 05/04/2017
Descrição-------: Função para validação da data de entrega de um pedido de vendas
Parametros------: _ddtent     - Data de entrega à validar
                  _cClient    - Cliente
                  _cLoja      - Loja
                  _cfilft     - Filial de Faturamento
                  _cpedido    - numero do pedido
                  _nret       - Retorna validação de data de entrega ou dias de transit tima
                  _lshow      - mostra mensagem
                  _cFilCarreg - Filial de origem do pedido de vendas
                  _cOperPedV  - Operação do Pedido de Vendas
                  _cTipoVenda - Tipo de Venda (Fechada ou Fracionada) 
                  _lAchouZG5  - Para passar como refererencia @_lAchouZG5
                  _cRegra     - Para passar como refererencia @_cRegra
                  _cLocalEmb  - Local de Embarque para usar na nova busca
                  _lValSC5    - Se .T. (DEFAULT) valida e busca dados no SC5 senão para usar em um programa novo alem do que já tem
Retorno---------: _lRet - .T. data de entrega válida, .F. caso contrário.
===============================================================================================================================
*/
User Function OMSVLDENT(_ddent,_cClient,_cLoja,_cfilft,_cpedido,_nret,_lshow,_cFilCarreg,_cOperPedV,_cTipoVenda,_lAchouZG5,_cRegra,_cLocalEmb,_lValSC5)

Local _lRet      := .T.
Local _aSC5      := SC5->(getarea())
Local _aSZW      := SZW->(getarea())
Local _aSA1      := SA1->(getarea())
Local _aSB1      := SB1->(getarea())
Local _lAchou    := .F.
Local _lerro     := .F.
Local npositem	 := aScan( aHeader, { |x| AllTrim(x[2])== "C6_ITEM" } )
Local nposprod   := aScan( aHeader, { |x| AllTrim(x[2])== "C6_PRODUTO" } )
Local nposloc    := aScan( aHeader, { |x| AllTrim(x[2])== "C6_LOCAL" } )
Local _ndias     := 0
Local _coper     := SuperGetMV("IT_ENTOPER",.T.,"01")
Local _cret      := "N"
Local _xret      := ""
Local _cLocal    := ""
Local _cMesoReg  := ""
Local _cMicroReg := ""
Local _cCodMunic := ""
Local _cEstado   := ""
Local _lBusca_2  := .F.
Local _cOperItap := SuperGetMV("IT_OPERITA",.T.,"25") //Operação Itapetininga
Local _cArmaItap := SuperGetMV("IT_ARMAITA",.T.,"36") //Armazem para Operação Itapetininga
Local _cLocalOp  := ""
Local _dDtDias   := SToD("")
Local _nTamaCol  := 0
Local _lMata410  := FWIsInCallStack("MATA410")
Local _lAOMS112  := .F.
Local _lAOMS116  := FWIsInCallStack("U_AOMS116")
Local _lAOMS109  := FWIsInCallStack("U_AOMS109")
Local _lAOMS032  := FWIsInCallStack("U_AOMS032")
Local _laoms074  := .F.
Local _lAOMS099  := (FWIsInCallStack("U_AOMS099"))
Local _cTpVen    := ""
Local _nDiasTrTi := 0
Local _nRegSA1
Local _nDiasFech := 0
Local _nDiasVar  := 0

Default _nret      := 0
Default _lshow     := .T.
Default _cFilCarreg:= ""
Default _cOperPedV := ""
Default _lAchouZG5 := .F.
Default _cRegra    := ""
Default _lValSC5   := .T.

_acolsori  := acols
_nRegSA1   := SA1->(Recno()) 
_aCabVldent:= {"Item","Estado","Municipio","Armazém","Transit Time","Data Digitada","Dt Ent Min","Obs","Produto","Descrição"}//Private PARA SER INICIADA NO PROGRAMA QUE CHAMA
_aIteVldent:= {}//Private PARA SER INICIADA NO PROGRAMA QUE CHAMA

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaççao Automatica)
If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_MOMS050")
    _lAoms112 := .T.
EndIf
//Se veio do webservice já retorna .T.
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
    _laoms074 := .T.
EndIf 

Begin Sequence
    //Se é análise de efetivação de pedido pula direto para a análise
    If _lAOMS112 .And. !_lMata410
        npositem	:= 1 //'aScan( aHeader, { |x| AllTrim(x[2])== "C6_ITEM" } )'
        nposprod	:= 2 //aScan( aHeader, { |x| AllTrim(x[2])== "C6_PRODUTO" } )
        nposloc	    := 3 //aScan( aHeader, { |x| AllTrim(x[2])== "C6_LOCAL" } )

        //Monta acols
        _nposori := SZW->(Recno())
        acols := {}
        SZW->(DBSetOrder(1))
        SZW->(DBSeek(_cfilft+_cpedido))

        _cLocalOp := IIf(SZW->ZW_TIPO $ _cOperItap,_cArmaItap,"")
        _cTpVen   := _cTipoVenda

        While SZW->ZW_FILIAL == _cfilft .And. SZW->ZW_IDPED == _cpedido
            aAdd(acols,{SZW->ZW_ITEM,SZW->ZW_PRODUTO,SZW->ZW_LOCAL})
            SZW->(DBSkip())
        EndDo 

        SZW->(DBGoTo(_nposori))  
    ElseIf !_lAOMS116 .And. !_lAOMS099.And.  !_laoms074 .And. !_lAOMS032 .And. _lValSC5
        //Localiza pedido
        SC5->(DbOrderNickName("IT_NUM"))//C5_NUM - OERDEM P - 25
        If !SC5->(DBSeek(_cpedido))
            //Verifica se é inclusão
            If _lMata410 .And. inclui 
                //Valida se tipo de pedido e operação deve ter data de entrega validada
                //Se não precisa validar retorna true ou zero dias de transit time
                If !(M->C5_TIPO == "N") .Or. !(M->C5_I_OPER $ _coper) 
                    If _nret == 0 
                        //Valida se data é menor que data atual
                        If Empty(_ddent) .Or. _ddent < Date()
                            _cObs:="Data de Entrega do Pedido inferior a data atual.."
                            If _lshow
                                U_MT_ITMSG("Data de Entrega do Pedido inferior a data atual!","Atenção - Pedido " + _cpedido ,"Digite uma Data de Entrega superior a data atual.",1)
                            EndIf

                            _cRet := "S"
                            _xret := .F.
                            Break
                        Else
                            _cRet := "S"
                            _xret := .T.
                            Break
                        EndIf
                    Else
                        _cRet := "S"
                        _xret := 0
                        Break
                    EndIf
                EndIf
            Else
                //Se não achou pedido retorna .F. ou -1
                _cObs:="Pedido não localizado para validar data de entrega!"
                If _lshow
                    U_MT_ITMSG("Pedido não localizado para validar data de entrega!")
                EndIf

                If _nret == 0
                    _cRet := "S"
                    _xret := .F.
                    Break
                Else
                    _cRet := "S"
                    _xret := -1
                    Break
                EndIf
            EndIf
        Else
            //Valida se tipo de pedido e operação deve ter data de entrega validada
            //Se não precisa validar retorna true ou zero dias de transit time
            If (!(SC5->C5_TIPO == "N") .Or. !(SC5->C5_I_OPER $ _coper)) .And. !(SC5->C5_I_AGEND $ "AM" .And. _lAOMS032)
                _cRegra:=" Não busca dias para C5_TIPO ["+SC5->C5_TIPO+"] <> N ou C5_I_OPER ["+SC5->C5_I_OPER+"] <> "+_coper//+" e C5_I_AGEND ["+SC5->C5_I_AGEND+"] <> 'AM'
                If _nret == 0
                    //Valida se data é menor que data atual
                    If Empty(_ddent) .Or. _ddent < Date()
                        _cObs:="Data de Entrega do Pedido inferior a data atual."
                        If _lshow
                            U_MT_ITMSG("Data de Entrega do Pedido inferior a data atual!","Atenção - Pedido " + _cpedido ,"Digite uma Data de Entrega superior a data atual.",1)
                        EndIf

                        _cRet := "S"
                        _xret := .F.
                        Break
                    Else
                        _cRet  := "S"
                        _xret  := .T.
                        Break
                    EndIf
                Else
                    _cRet := "S"
                    _xret := 0
                    Break
                EndIf
            ElseIf (SC5->C5_I_AGEND $ "AM" .And. _lAOMS032)
                If _nret > 0
                    _lRet := 0
                Else
                    _lRet := .T.
                EndIf
                Return _lRet
            EndIf
        EndIf

        If Type("M->C5_I_OPER") == "C" .And. _lMata410 .And. !_lAOMS032
            _cLocalOp := IIf(M->C5_I_OPER $ _cOperItap,_cArmaItap,"")
            _cTpVen   := M->C5_I_TPVEN
        Else
            _cLocalOp := IIf(SC5->C5_I_OPER $ _cOperItap,_cArmaItap,"")
            _cTpVen   := SC5->C5_I_TPVEN
        EndIf

        //Valida se data foi preenchida e é maior que a data atual
        If (Empty(_ddent) .Or. _ddent < Date()) .And. _nret == 0
            _cprod := '112233'

            _cObs:="Data de Entrega do Pedido inferior a data atual!"
            If _lshow
                U_MT_ITMSG("Data de Entrega do Pedido inferior a data atual!","Atenção - Pedido " + _cpedido ,"Digite uma Data de Entrega superior a data atual.",1)
            EndIf
            _cRegra:="2-Data de Entrega do Pedido inferior a data atual!"
            _lRet := .F.
        EndIf

    ElseIf _lAOMS116
        _cLocalOp := IIf("20" $ _cOperItap,_cArmaItap,"")
        _cTpVen   := "F"
    EndIf

    // Posiciona no cadastro de Clientes.
    SA1->(DBSetOrder(1))
    SA1->(MSSeek(xFilial("SA1") + _cClient + _cLoja))

    // REGRAS ANTIGAS DE TRANSIT TIME.
    // Mantida até que todos os fontes que chamam a função sejam alterados.
    If _lRet .And. Empty(_cOperPedV)
        // Procura regras de transit time válidas
        If Empty(_cfilft)
            _cfilft := xFilial("SC5")
        EndIf

        _ncols := 1
        _nTamaCol := IIf(Empty(_cLocalOp),Len(acols),1)

        While _ncols <= _nTamaCol
            _cLocal    := IIf(Empty(_cLocalOp),AllTrim(aCols[_nCols][nPosloc]),_cLocalOp)
            _cMesoReg  := "" // Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MESO")
            _cMicroReg := "" //Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
            _cCodMunic := SA1->A1_COD_MUN
            _cEstado   := SA1->A1_EST
            _lBusca_2  := .F.
            _lAchou    := .F.
            _cRegra    := ""

            If !Empty(_cLocal)
                ZG5->(DBSetOrder(3))
                If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
                    _lAchou   := .T.
                    _lBusca_2 := .F.
                    _cRegra   := "Regra Armazem/Estado/Mesorregiao/Microrregiao/Municipio"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg))
                    _lAchou   := .T.
                    _lBusca_2 := .F.
                    _cRegra   := "Regra Armazem/Estado/Mesorregiao/Microrregiao"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg))
                    _lAchou   := .T.
                    _lBusca_2 := .F.
                    _cRegra   := "Regra Armazem/Estado/Mesorregiao"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado))
                    _lAchou   := .T.
                    _lBusca_2 := .F.
                    _cRegra   := "Regra Armazem/Estado"
                Else
                    _lBusca_2 := .T.
                EndIf
                _lAchouZG5 := _lAchou
            Else
                _lBusca_2 := .T.
            EndIf

            If _lBusca_2
                ZG5->(DBSetOrder(2))
                If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
                    _lAchou := .T.
                    _cRegra := "Regra Estado/Mesorregiao/Microrregiao/Municipio"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg))
                    _lAchou := .T.
                    _cRegra := "Regra Estado/Mesorregiao/Microrregiao"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg))
                    _lAchou := .T.
                    _cRegra := "Regra Estado/Mesorregiao"
                ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado))
                    _lAchou := .T.
                    _cRegra := "Regra Estado"
                Else
                    _lAchou := .F.
                EndIf
                _lAchouZG5 := _lAchou
            EndIf

            If _lAchou
                _nDiasTrTi := IIf(_cTpVen == "F", ZG5->ZG5_DIAS , IIf(ZG5->ZG5_FRDIAS >0,ZG5->ZG5_FRDIAS,ZG5->ZG5_DIAS))
                _dDtDias   := Date() + _nDiasTrTi + 1

                If _ddent >= _dDtDias
                    _cObs := _cRegra
                Else
                    _cObs := "Data de Entrega não Permitida !! Somente Data Maior ou Igual a " + DToC(_dDtDias)
                    _lerro := .T.
                EndIf

                If _nDiasTrTi > _ndias
                    _ndias := _nDiasTrTi
                EndIf
            Else
                _nDiasTrTi := 0
                _ndias   := -1
                _cObs    := "Cidade do Cliente não é atendida pela Filial"
                _dDtDias := SToD("")
                _lErro   := .T.
            EndIf

            aAdd(_aIteVldent, { aCols[_nCols][nPositem],;
                SA1->A1_EST,;
                SA1->A1_COD_MUN + " - " + SA1->A1_MUN ,;
                aCols[_nCols][nPosloc],;
                _nDiasTrTi,;
                _ddent,;
                _dDtDias,;
                _cObs,;
                aCols[_nCols][nPosprod],;
                Posicione("SB1",1,xFilial("SB1")+aCols[_nCols][nPosprod],"B1_DESC")	})

            _nCols++
        EndDo

        //Apresenta itlist se não achou regra de transit time
        If _lerro .And. _nret == 0
            _cObs:="Data de entrega inválida com regras de transit time!"
            If _lshow

                If FWIsInCallStack( 'U_AOMS032' ) .Or. FWIsInCallStack("MSEXECAUTO")
                    U_MT_ITMSG("Data de entrega inválida com regras de transit time!","Atenção - Pedido " + _cpedido ,"Ajuste a data de entrega ou cadastro de transit time.",1)
                Else
                    U_MT_ITMSG("Data de entrega inválida com regras de transit time!","Atenção - Pedido " + _cpedido ,"Ajuste a data de entrega ou cadastro de transit time de acordo com a próxima tela",1)
                    U_ITListBox( 'Resultados das regras de transit time para o pedido' , _aCabVldent ,_aIteVldent,.T.,1)
                EndIf

            EndIf

            _lRet := .F.
        EndIf
    Else
        // NOVAS REGRAS DE TRANSIT TIME.
        // Para entrar neste trecho os novos parâmetros da função devem
        // estar preenchidos.
        If _lRet
            _cMesoReg  := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MESO")
            _cMicroReg := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
            _cCodMunic := SA1->A1_COD_MUN
            _cEstado   := SA1->A1_EST
            _lAchouZG5 := .F.
            _nDiasFech := 0
            _nDiasVar  := 0

            If Empty(_cFilCarreg)
                _cFilCarreg := xFilial("SC5")
            EndIf
            
            If _cLocalEmb = NIL//SEM PASSAR O Local DE EMBARQUE
                
                //  FILIAL+FILIAL ORIGEM+ESTADO+OPERACAO+MUNICIPIO+MESO REGIAO+MICRO REGIAL
                ZG5->(DBSetOrder(4)) // ZG5_FILIAL+ZG5_FILORI+ZG5_UF+ZG5_OPER+ZG5_CODMUN+ZG5_MESO+ZG5_MICRO
                If ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+SA1->A1_COD_MUN+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                    //1)	Primeira Busca (Estado + Operação + Município)
                    If ZG5->ZG5_FILORI = _cFilCarreg .And. ZG5->ZG5_UF = SA1->A1_EST .And. ZG5->ZG5_OPER = _cOperPedV
                        _lAchouZG5 := .T.
                        _cRegra := "Regra Filial/Estado/Operacao/Municipio:"+_cFilCarreg+SA1->A1_EST+_cOperPedV+SA1->A1_COD_MUN+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")
                    EndIf
                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+_cMicroReg))
                    //2)	Se não encontrou na regra anterior (Estado + Operação + Mesorregião + Microrregião)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Operacao/Mesorregiao/Microrregiao:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+_cMicroReg

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+U_ITKEY(" ","ZG5_MICRO")))
                    //3)	Se não encontrou na regra anterior (Estado + Operação + Mesorregião)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Operacao/Mesorregiao:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+U_ITKEY(" ","ZG5_MICRO")

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                    //4)	Se não encontrou na regra anterior (Estado + Operação)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Operacao:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+_cOperPedV+U_ITKEY(" ","ZG5_CODMUN")+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+SA1->A1_COD_MUN+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                    //5)	Se não encontrou na regra anterior (Estado +Município)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Municipio:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+SA1->A1_COD_MUN+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+_cMicroReg))
                    //6)	Se não encontrou na regra anterior (Estado + Mesorregião + Microrregião)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Mesorregiao/Microrregiao:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+_cMicroReg

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+U_ITKEY(" ","ZG5_MICRO")))
                    //7)	Se não encontrou na regra anterior (Estado + Mesorregião)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado/Mesorregiao:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+U_ITKEY(" ","ZG5_MICRO")

                ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                    //8)	Se não encontrou na regra anterior (Estado)
                    _lAchouZG5 := .T.
                    _cRegra := "Regra Filial/Estado:"+xFilial("ZG5")+_cFilCarreg+SA1->A1_EST+U_ITKEY(" ","ZG5_OPER")+U_ITKEY(" ","ZG5_CODMUN")+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")
                Else
                    _cRegra := "Não achou Filial/Estado/Operacao/Municipio/Mesorregiao/Microrregiao:"+_cFilCarreg+"/"+SA1->A1_EST+"/"+_cOperPedV+"/"+SA1->A1_COD_MUN+"/"+_cMesoReg+"/"+_cMicroReg
                EndIf
            
            ElseIf !Empty(_cLocalEmb) //PASSANDO O Local DE EMBARQUE
                // FILIAL + Local DE EMBARQUE + ESTADO + MUNICIPIO + MESO_REGIAO + MICRO_REGIAO
                    ZG5->(DBSetOrder(5)) // ZG5_FILIAL+ZG5_LOCEMB+ZG5_UF+ZG5_CODMUN+ZG5_MESO+ZG5_MICRO
                    If ZG5->(MsSeek(xFilial("ZG5")+_cLocalEmb+SA1->A1_EST+SA1->A1_COD_MUN+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                        _cRegra:= "1) Buscou por (Local de embarque + Estado + Município)"
                        _lAchouZG5 := .T.
                    ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cLocalEmb+SA1->A1_EST+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+_cMicroReg))
                        _cRegra:= "2) Buscou por (Local de embarque + Estado + Mesorregião + Microrregião)"
                        _lAchouZG5 := .T.
                    ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cLocalEmb+SA1->A1_EST+U_ITKEY(" ","ZG5_CODMUN")+_cMesoReg+U_ITKEY(" ","ZG5_MICRO")))
                        _cRegra:= "3) Buscou por (Local de embarque + Estado + Mesorregião)"
                        _lAchouZG5 := .T.
                    ElseIf ZG5->(MsSeek(xFilial("ZG5")+_cLocalEmb+SA1->A1_EST+U_ITKEY(" ","ZG5_CODMUN")+U_ITKEY(" ","ZG5_MESO")+U_ITKEY(" ","ZG5_MICRO")))
                        _cRegra:= "4) Buscou por (Local de embarque + Estado )"
                        _lAchouZG5 := .T.
                Else
                    _cRegra := "Não achou Local de Embarque/Estado/Municipio/Mesorregiao/Microrregiao:"+_cLocalEmb+"/"+SA1->A1_EST+"/"+SA1->A1_COD_MUN+"/"+_cMesoReg+"/"+_cMicroReg
                    EndIf
            
            EndIf
            _lRet      := _lAchouZG5
            _ndias     := 0

            If _lAchouZG5
                _nDiasFech := ZG5->ZG5_DIAS
                _nDiasVar  := ZG5->ZG5_FRDIAS
                If _cTipoVenda == "F" // Quando Carga Fechada
                    _ndias := _nDiasFech + 1
                Else// _cTipoVenda == "V" Quando Carga Fracionada (Varejo)
                    _ndias := _nDiasVar  + 1
                EndIf
            EndIf

            If _nret == 0 .And. !_lAOMS099 .And.  !_laoms074 .And. !_lAOMS032
                _cObs:=_cRegra
                If Empty(_ddent) .Or. DToS(_ddent) <= DToS(Date()) .Or. DToS((_ddent + _ndias)) <= DToS(Date())
                    _cObs:="Data de Entrega do Pedido inferior ou igual a data atual!"
                    If _lshow
                        U_MT_ITMSG(_cObs,"Atenção - Pedido " + _cpedido ,"Digite uma Data de Entrega superior a data atual.",1)
                    EndIf
                    _lRet := .F.   
                    Break          
                EndIf

                If ! _lAchouZG5
                    _cObs:="Transit Time não localizado!"
                    If _lshow
                        U_MT_ITMSG(_cObs,"Atenção - Pedido " + _cpedido ,"Cadastre um Transit Time para este pedido de vendas.",1)
                    EndIf
                Else
                    If DToS(_ddent) < DToS((Date() + _ndias))

                        _cObs:="Data de Entrega do Pedido inferior ao Transit Time do Pedido de Vendas!"
                        If _lshow
                            U_MT_ITMSG(_cObs,"Atenção - Pedido " + _cpedido ,"Digite uma Data de Entrega superior ao Transit Time do Pedido de Vendas.",1)
                        EndIf
                        _lRet := .F. 
                        Break        
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf

End Sequence

SA1->(DBGoTo(_nRegSA1))

If _nret > 0
    _lRet := _ndias
Else
    If !_lRet .And. _lAOMS109
        _lRet := .T.
    EndIf
EndIf

FWRestArea(_aSC5)
FWRestArea(_aSZW)
FWRestArea(_aSA1)
FWRestArea(_aSB1)

acols := _acolsori

Return _lRet

/*
================================================================================================================================
Programa--------: retlgilga
Autor-----------: Josué Danich Prestes
Data da Criacao-: 09/05/2017
Descrição-------: Função para retornar string a ser gravado nos campos usrlgi/uarlga
Parametros------: _cid - id do usuário
Retorno---------: _cstring -> string a ser gravado nos campos usrlgi/uarlga
===============================================================================================================================
*/
User Function retlgilga(_cid)

Local _cstring := ""
Local _npos := SC5->(Recno())
Local _aAreaAnt := GETAREA("SC5")


//Detecta string sendo gravado no dia para pegar padrão de data
SC5->(DbOrderNickName("IT_NUM"))//C5_NUM - OERDEM P - 25
SC5->(DBGoBottom())

_cstring := SC5->C5_USERLGI

SC5->(DBGoTo(_npos))

_cstring := SubStr(_cstring,1,10) + SubStr(_cid,1,1) + SubStr(_cstring,12,Len(_cstring))
_cstring := SubStr(_cstring,1,14) + SubStr(_cid,2,1) + SubStr(_cstring,16,Len(_cstring))
_cstring := SubStr(_cstring,1,1) + SubStr(_cid,3,1) + SubStr(_cstring,3,Len(_cstring))
_cstring := SubStr(_cstring,1,5) + SubStr(_cid,4,1) + SubStr(_cstring,7,Len(_cstring))
_cstring := SubStr(_cstring,1,9) + SubStr(_cid,5,1) + SubStr(_cstring,11,Len(_cstring))
_cstring := SubStr(_cstring,1,13) + SubStr(_cid,6,1) + SubStr(_cstring,15,Len(_cstring))

FWRestArea(_aAreaAnt)

Return _cstring

/*
===============================================================================================================================
Função-------------: STPEDIDO
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/05/2017
Descrição---------: Retorna status do pedido
Parametros--------: _ntipo - 0 Retorna status por código a ser decomposto
                             1 Retorna status em texto legível por humanos
Retorno-----------: _cstatus
                    1 - Pedido de Venda em Aberto
                    2 - Pedido de Venda Encerrado 
                    3 - Pedido de Venda Liberado
                    4 - Pedido de Venda com Bloqueio de Estoque
                    5 - Pedido de Venda com Bloqueio de Verba
                    6 - Pedido de Venda com Bloqueio de Bonificação
                    7 - Pedido de Venda com Bonificação Rejeitada
                    8 - Pedido de Venda com Bloqueio de Preço
                    9 - Pedido de Venda com Preço Rejeitado 
                    10 - Pedido de Venda com Bloqueio de Crédito
                    11 - Pedido de Venda com Crédito Rejeitado
                    12 - Pedido Carregamento Troca Nota Aberto
                    13 - Pedido Carregamento Troca Nota Liberado
                    14 - Pedido Faturamento Troca Nota Aberto
                    15 - Pedido Faturamento Troca Nota Liberado
                    
===============================================================================================================================
*/  
User Function STPEDIDO(_ntipo)

Local _nstatus := 1
Local _cstatus := ""
Local _lbloq := .T.
Default _ntipo := 0

If (SC5->C5_I_BLOQ == ' ' .Or. SC5->C5_I_BLOQ == 'L')
    If ( SC5->C5_I_BLPRC == ' ' .Or. SC5->C5_I_BLPRC == 'L' .Or. SC5->C5_I_BLPRC == 'C')
        If (SC5->C5_I_BLCRE == ' ' .Or. SC5->C5_I_BLCRE == 'L' .Or. SC5->C5_I_BLCRE == 'C')
            _lbloq := .F. //Pedido não tem bloqueio de crédito/preço/bonificacao
        EndIf
    EndIf
EndIf


Begin Sequence
    If !Empty(SC5->C5_NOTA)
        _nstatus := 02
        _cstatus := "Pedido de Venda Encerrado"
        Break
    EndIf

    If SC5->C5_I_TRCNF = 'S' .And. SC5->C5_I_PDFT = SC5->C5_NUM .And. !Empty(SC5->C5_LIBEROK) .And. !_lbloq
        If !(u_verest()) //Função que verifica se tem SC9 com bloqueio de estoque, é prioritário em cima da legenda de troca nota
            _nstatus := 04
            _cstatus := "Pedido de Venda com Bloqueio de Estoque"
            Break
        EndIf

        _nstatus := 15
        _cstatus := "Pedido Faturamento Troca Nota Liberado"
        Break
    EndIf

    If SC5->C5_I_TRCNF = 'S' .And. SC5->C5_I_PDFT = SC5->C5_NUM .And. Empty(SC5->C5_LIBEROK) .And. !_lbloq
        _nstatus := 14
        _cstatus := "Pedido Faturamento Troca Nota"
        Break
    EndIf

    If SC5->C5_I_TRCNF = 'S' .And. Empty(SC5->C5_I_PDFT) .And. !Empty(SC5->C5_LIBEROK) .And. !_lbloq
        If !(u_verest()) //Função que verifica se tem SC9 com bloqueio de estoque, é prioritário em cima da legenda de troca nota
            _nstatus := 04
            _cstatus := "Pedido de Venda com Bloqueio de Estoque"
            Break
        EndIf

        _nstatus := 13
        _cstatus := "Pedido Carregamento Troca Nota Liberado"
        Break
    EndIf

    If SC5->C5_I_TRCNF = 'S' .And. Empty(SC5->C5_I_PDFT) .And. Empty(SC5->C5_LIBEROK) .And. !_lbloq
        _nstatus := 12
        _cstatus := "Pedido Carregamento Troca Nota"
        Break
    EndIf

    If SC5->C5_I_BLCRE == 'R'
        _nstatus := 11
        _cstatus := "Pedido de Venda com Crédito Rejeitado"
        Break
    EndIf

    If SC5->C5_I_BLCRE == 'B'
        _nstatus := 10
        _cstatus := "Pedido de Venda com Bloqueio de Crédito"
        Break
    EndIf

    If SC5->C5_I_BLPRC == 'R'
        _nstatus := 09
        _cstatus := "Pedido de Venda com Preço Rejeitado"
        Break
    EndIf

    If SC5->C5_I_BLPRC == 'B'
        _nstatus := 08
        _cstatus := "Pedido de Venda com Bloqueio de Preço"
        Break
    EndIf

    If SC5->C5_I_BLOQ == 'R'
        _nstatus := 07
        _cstatus := "Pedido de Venda com Bonificação Rejeitada"
        Break
    EndIf

    If SC5->C5_I_BLOQ == 'B'
        _nstatus := 06
        _cstatus := "Pedido de Venda com Bloqueio de Bonificação"
        Break
    EndIf

    If !Empty(SC5->C5_LIBEROK) .And. !(u_verest()) //Função que verifica se tem SC9 com bloqueio de estoque
        _nstatus := 04
        _cstatus := "Pedido de Venda com Bloqueio de Estoque"
        Break
    EndIf

    If  !Empty(SC5->C5_LIBEROK) .And. !_lbloq
        _nstatus := 03
        _cstatus := "Pedido de Venda Liberado"
        Break
    EndIf

    If _nstatus == 01
        _cstatus := "Pedido de Venda em Aberto"
        Break
    EndIf
End Sequence

If _ntipo == 0
    _cstatus := StrZero(_nstatus,2)
EndIf

Return _cstatus

/*
===============================================================================================================================
Função------------: ENVSITPV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/05/2016
Descrição---------: Gera os dados XML com base nos Pedidos de Vendas selecionados e integra via webservice.
Parametros--------: _item - dados do pedido a ser bloqueado
Retorno-----------: Sempre .T.
===============================================================================================================================
*/  
User Function ENVSITPV(_item,_lMarcaEnv)

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cRodXML := ""
Local _cEmpWebService := ""
Local _aOrd
Local _cXML
Local _cResult := ""
Local _cResposta, _cSituacao
Local _nRegSC5
Local _cSitPed := ""

Default _lMarcaEnv:=.T.
Default _item := {"  ", SC5->C5_FILIAL,SC5->C5_NUM} //Se não mandar parâmetro analisa pedido posicionado

Begin Sequence
    If Select("ZFM") == 0 // Se a tabela ZFM não estiver aberta, abre a tabela ZFM.
        ChkFile("ZFM")
    EndIf

    If Select("SC5") == 0 // Se a tabela SC5 não estiver aberta, abre a tabela SC5.
        ChkFile("SC5")
    EndIf

    _nRegSC5 := SC5->(Recno())

    _aOrd := SaveOrd({"ZFM","SC5"}) // Salva no Array _aOrd a ordem dos índices das tabelas posicionadas e a posição atual do ponterio de registro.

    SC5->(DBSetOrder(1))
    If !(SC5->(DBSeek(_item[2]+_item[3]))) //Se não achar o pedido de vendas sai da rotina de imediato
        Break
    EndIf

    _cSitPed := U_STPEDIDO()

    If SC5->C5_I_ENVRD = "S"
        // Se a filial atual estiver habilitada a utilizar o TMS MultiEmbarcador,
        // Chama a rotina nova de Envio de Situação do Pedido de Vendas.
        If U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms 
            U_AOMS140O() // Nova Rotina de Envio da Situação do Pedido de Vendas para o TMS MultiEmbarcador.    
            Break 
        EndIf 

        // Chama a rotina antiga, do RDC, de envio da Situação do Pedido de Vendas
        If _lMarcaEnv
            U_GRVCAPAC(SC5->C5_FILIAL,NIL,SC5->C5_NUM,"[ ENVSITPV - MARCAENV - "+AllTrim(FUNNAME())+" ] [ Sit.: "+_cSitPed+" ]")
            Break
        EndIf

        // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
        ZFM->(DBSetOrder(1))
        If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
            _cDirXML := ZFM->ZFM_LOCXML
            _cLink   := AllTrim(ZFM->ZFM_LINK01)
        Else
            Break
        EndIf

        If Empty(_cDirXML) .Or. Empty(_cLink)
            Break
        EndIf

        _cDirXML := AllTrim(_cDirXML)
        If Right(_cDirXML,1) <> "\"
            _cDirXML := _cDirXML + "\"
        EndIf

        // Lê os arquivos modelo XML e os transforma em String.
        _cCabXML := LEXMLS(_cDirXML+"Cab_BloqPedido.txt")
        If Empty(_cCabXML)
            Break
        EndIf

        oWsdl := tWSDLManager():New() // Cria o objeto da WSDL.
        oWsdl:nTimeout := 30          // Timeout de 10 segundos
        oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo

        oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.
        oWsdl:SetOperation("AlteraSituacaoPedido") // Define qual operação será realizada.

        Begin Transaction
            // Realiza a integração dos bloqueios e pedidos de vendas (Envio de XML) via WebService.

            SC5->(DBSeek(_item[2]+_item[3])) //Posiciona pedido para montar xml
            _cDetXML := LEXMLS(_cDirXML+"DET_BloqPedido.txt")
            _cRodXML := LEXMLS(_cDirXML+"Rodape_BloqPedido.txt")

            //Monta XML
            _cXML := _cCabXML + &(_cDetXML) + _cRodXML  // Monta o XML de envio.
            // Limpa & da string
            _cXML := StrTran(_cXML,"&"," ")

            // Envia para o servidor
            _cOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.

            If _cOk
                _cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
            Else
                _cResult := oWsdl:cError
            EndIf

            _cResposta := AllTrim(StrTran(_cResult,Chr(10)," "))
            _cResposta := Upper(_cResposta)

            oWsdl:GetSoapResponse() //finaliza soap
            // "Importado Com Sucesso"
            _cSituacao := "P"

            If ! _cOk
                _cSituacao := "N"
            ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)
                _cSituacao := "N"
            EndIf

            // grava resultado // sempre como processado
            ZGA->(RecLock("ZGA",.T.))
            ZGA->ZGA_DTENT   := SC5->C5_I_DTENT
            ZGA->ZGA_SITUAC  := _cSituacao
            ZGA->ZGA_NUM     := SC5->C5_NUM
            ZGA->ZGA_USUARI  := __cUserId
            ZGA->ZGA_DATAAL  := Date()
            ZGA->ZGA_HORASA  := Time()
            ZGA->ZGA_STATUS  := _cSitPed
            ZGA->ZGA_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela dizendo que deu certo ou não.
            ZGA->ZGA_XML     := _cXML
            ZGA->(MSUnLock())

        End Transaction

        If "AN EXCEPTION  OCCURRED AT 1:0 WSDLPARSER EXCEPTION" $ Upper(ZGA->ZGA_RETORN) .OR.;
                "AN EXCEPTION  OCCURRED AT 0:0 WSDLPARSER EXCEPTION" $ Upper(ZGA->ZGA_RETORN)
            U_GRVCAPAC(SC5->C5_FILIAL,NIL,SC5->C5_NUM,"[ ENVSITPV - ERRO - "+AllTrim(FUNNAME())+" ]")
        EndIf

        If Type("oWsdl") = "O"
            oWsdl:=Nil
            //Limpa o Objeto: Conforme orientado pelo Framework
            DelClassIntf()//Exclui todas classes de interface da thread.
        EndIf

    EndIf

    SC5->(RecLock("SC5",.F.))
    SC5->C5_I_STATU := U_STPEDIDO() //Função de análise do pedido de vendas no xfunoms
    SC5->(MSUnLock())
End Sequence

RestOrd(_aOrd)

SC5->(DBGoTo(_nRegSC5))

Return .T.

/*
===============================================================================================================================
Função-------------: LEXMLS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq - arquivo xml de formato
Retorno-----------: _cret - conteúdo do arquivo
===============================================================================================================================
*/  
Static Function LEXMLS(_cArq)

Local _cRet := ""
Local _nStatusArq
Local _cLine

_nStatusArq := FT_FUse(_cArq)
// Se houver erro de abertura abandona processamento
If _nStatusArq = -1
    Break
EndIf

// Posiciona na primeria linha
FT_FGoTop()

While !FT_FEof()
    _cLine  := FT_FReadLn()
    _cRet +=  _cLine
    FT_FSKIP()
EndDo

// Fecha o Arquivo
FT_FUSE()

Return _cRet

/*
===============================================================================================================================
Função-------------: VEREST
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/10/2016
Descrição---------: Verifica se pedido tem SC9 com bloqueio de estoque
Parametros--------: Nenhum
Retorno-----------: _lRet - Falso se tiver bloqueio de estoque
===============================================================================================================================
*/  
User Function verest()

Local _lRet := .T.
Local _aSC9   := GetArea("SC9")
Local _aSC6   := GetArea("SC6")

SC6->(DBSetOrder(1))
SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

While SC5->C5_FILIAL+SC5->C5_NUM == SC6->C6_FILIAL+SC6->C6_NUM
    SC9->(DBSetOrder(1))

    If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
        If SC9->C9_BLEST == '02'
            _lRet := .F.
        EndIf
    Else//Se não achar sc9 é falha de liberação de estoque
        _lRet := .F.
    EndIf
    SC6->(DBSkip())
EndDo

FWRestArea(_aSC9)
FWRestArea(_aSC6)

Return _lRet

/*
===============================================================================================================================
Programa--------: GrvMonitor()
Autor-----------: Alex Wallauer
Data da Criacao-: 28/04/2017
Descrição-------: Grava o ZY3 para o Monitor pedido de vendas
Parametros------: _cFilial - filial do PV 
                  _cNum    - numero do PV
                  _cJUSCOD - codigo da justificativa
                  _cCOMENT - comentario
                  _cLENCMON- 'S' encerra o monitoramento 'I' inicia
                  _dDTNECE - data da necessidade de faturamento
                  _dDTFAT  - data de entrega 
                  _dDTFOLD - data de entrega ante de alterar
                  _cObserv    - Observação estoque.
                  _cVinculoTb - Código de Vinculo entre as Tabelas ZY3 e ZY8
                  _dDtSugAgen - Data sugerida de agendamento.
Retorno---------: Lógico (.T.) Se tudo OK 
OBSERVAÇÃO------: NÃO INICIAR ACOLS E AHEADER NESSA FUNÇAO PQ TEM LUGRARES QUE ELES JÁ EXISTEM e não são o que precisamos 
===============================================================================================================================
*/

User Function GrvMonitor(_cFilial,_cNum,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE,_dDTFAT,_dDTFOLD, _cObserv, _cVinculoTb, _dDtSugAgen,_lRestArea)

Local _cSequen  := "0000"
Local _aAreaSC5 := SC5->(GetArea())
Local _aAreaZY3 := ZY3->(GetArea())
Local _cENCMON  := "I"
Default _cFilial:= SC5->C5_FILIAL
Default _cNum   := SC5->C5_NUM
Default _dDtPrevEst := Ctod("  /  /  ")
Default _cObserv    := ""
Default _cVinculoTb := ""
Default _dDtSugAgen := Ctod("  /  /  ")
Default _lRestArea  := .T.

ZY3->(DBSetOrder(2))
If ZY3->(DBSeek(_cnum))
    While ZY3->( !Eof() ) .And. ZY3->ZY3_NUMPV == _cnum
        If !Empty(_cLENCMON)//Se não For branco tem que gravar em todas as linhas senão segue a logica de grava a linha nova com o ultimo conteudo
            ZY3->(RecLock("ZY3",.F.))
            ZY3->ZY3_ENCMON := _cLENCMON
            ZY3->(MSUnLock())
        EndIf
        If ZY3->ZY3_SEQUEN > _cSequen
            _cSequen := ZY3->ZY3_SEQUEN
            _cENCMON := ZY3->ZY3_ENCMON
        EndIf
        ZY3->(DBSkip())
    EndDo
ElseIf !Empty(_cLENCMON)
    _cENCMON := _cLENCMON
EndIf

//Valida se existe campo de código de usuário para não dar errolog em schedule e webservice
If Type("__cUserId") == "U"
    _cUsertmp:= "000000"
    _cNome   := "WEBSERVICE"
Else
    _cUsertmp:= __cUserId
    _cNome   := AllTrim(UsrFullName(__cUserId))
EndIf

ZY3->(RecLock("ZY3",.T.))
ZY3->ZY3_NUMPV  := _cNum
ZY3->ZY3_FILFT  := _cFilial
ZY3->ZY3_SEQUEN := Soma1(_cSequen)
ZY3->ZY3_DTMONI := Date()
ZY3->ZY3_HRMONI := Time()
ZY3->ZY3_CODUSR := _cUsertmp
ZY3->ZY3_NOMUSR := _cNome
ZY3->ZY3_ORIGEM := FUNNAME()
//Parametros
ZY3->ZY3_DTNECE := _dDTNECE//SC5->C5_I_DTENT - (U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,_cFilial,_cNum,1))
ZY3->ZY3_DTFOLD := _dDTFOLD
ZY3->ZY3_DTFAT  := _dDTFAT //SC5->C5_I_DTENT
ZY3->ZY3_JUSCOD := _cJUSCOD
ZY3->ZY3_COMENT := _cCOMENT
ZY3->ZY3_ENCMON := _cENCMON
ZY3->ZY3_OBSERV := _cObserv
ZY3->ZY3_VNCZY8 := _cVinculoTb
ZY3->ZY3_DTSUAG := _dDtSugAgen
//Parametros
ZY3->(MSUnLock())
If _lRestArea
    FWRestArea(_aAreaSC5)
    FWRestArea(_aAreaZY3)
EndIf

Return .T.

/*
===============================================================================================================================
Função------------: GRVCAPAC
Autor-------------: Alex Wallauer
Data da Criacao---: 06/06/2017
Descrição---------: Função para gravar o ZFU. Grava os dados de capa da carga.
Parametros--------: _cFilial,_cCodEmpWS : Variaveis iniciadas Locais
Retorno-----------: Recno do ZFU
===============================================================================================================================
*/
User Function GRVCAPAC(_cFilial,_cCodEmpWS,_cPV,_cOrigem)//Chamada do XFUNOMS.PRW tb

Local _nRec:=0
Default _cCodEmpWS := SuperGetMV('IT_EMPWEBSE',.T.,'000001')
Default _cOrigem:="[U_INCLUIC]"

// Grava log de comuinicação
    If _cPV = NIL
        ZFU->(RecLock("ZFU",.T.))
        ZFU->ZFU_FILIAL  := _cFilial          // Filial do Sistema
        ZFU->ZFU_CODEMP  := _cCodEmpWS	     // Codigo Empresa WebServer
        ZFU->ZFU_DATA    := Date()            // Data de Emissão
        ZFU->ZFU_HORA    := Time()            // Hora de inclusão na tabela de muro
        ZFU->ZFU_USUARI  := __cUserId         // Codigo do Usuário
        ZFU->ZFU_DATAAL  := Date()            // Data de Alteração
        ZFU->ZFU_SITUAC  := "P"               // Situação do Registro
        ZFU->ZFU_ENSTUS  := "S"               // Marcou para enviar Status
        ZFU->ZFU_CNPJEM  := U_CARGA:CNPJEM    // CNPJ do Embarcador
        ZFU->ZFU_CODIGO  := U_CARGA:CODIGO    // Codigo da Carga no RDC
        ZFU->ZFU_I_FRDC  := U_CARGA:CODFIL    // Codigo da Filial RDC
        ZFU->ZFU_PLACAC  := U_CARGA:PLACA1    // Placa do caminhão
        ZFU->ZFU_PLACA2  := U_CARGA:PLACA2    // Placa do Veiculo 2
        ZFU->ZFU_PLACA3  := U_CARGA:PLACA3    // Placa do Veiculo 3
        ZFU->ZFU_PLACA4  := U_CARGA:PLACA4    // Placa do Veiculo 4
        ZFU->ZFU_CPFMOT  := U_CARGA:CPFM	     // CPF do motorista
        ZFU->ZFU_PESOBR  := U_CARGA:PESOB     // Peso bruto
        ZFU->ZFU_PESOLQ  := U_CARGA:PESOL     // Peso liquido
        ZFU->ZFU_VALCAR  := U_CARGA:VALOR     // Valor
        ZFU->ZFU_DTEMIS  := CTod(U_CARGA:DATAE)// Data de emissão da Carga
        ZFU->ZFU_DTCARR  := CTod(U_CARGA:DATAC)// Data de carregamento
        ZFU->ZFU_CNPJTR  := U_CARGA:CNPJTRA	  // CNPJ da Transportadora
        ZFU->ZFU_TIPO    := U_CARGA:TIPO	      // Tipo do veiculo
        ZFU->ZFU_FRETE   := U_CARGA:FRETE              // Valor do Frete
        ZFU->ZFU_VLRPDG  := U_CARGA:PEDAGIO            // Valor do Pedagio
        ZFU->ZFU_RDCUSR  := AllTrim(Str(U_CARGA:USUCAD,6)) // Codigo do Usuário da Alteração
        ZFU->ZFU_OBS1    := U_CARGA:OBSERV1            // Observação 1
        ZFU->ZFU_OBS2    := U_CARGA:OBSERV2            // Observação 2
        ZFU->ZFU_PRECAR  := U_CARGA:PRECARGA           // Precarga? S/N
        ZFU->ZFU_REGCAP  := StrZero(ZFU->(Recno()),10) // Numero Registro Tab.Capa
        ZFU->ZFU_RETORN  := "Iniciou Gravação da Carga do RDC "+_cOrigem// Retorno Integracao Italac-RDC
        ZFU->ZFU_CODIGO  := U_CARGA:CODIGO             // Codigo da Carga no RDC
        ZFU->ZFU_RECRDC  := AllTrim(Str(U_CARGA:RECNUM,10)) // Grava o Recno RDC na Tabela de muro.
        If DAK->(DBSeek(_cFilial+AllTrim(U_CARGA:CODIGO))) // DBSeek(_cFilial+U_CARGA:CODIGO)
            ZFU->ZFU_NCARGA:=DAK->DAK_COD
        EndIf
        ZFU->(MSUnLock())
        _nRec := ZFU->(Recno())
    Else
        ZGY->(RecLock("ZGY",.T.))
        ZGY->ZGY_FILIAL  := _cFilial          // Filial do Sistema
        ZGY->ZGY_CODEMP  := _cCodEmpWS	     // Codigo Empresa WebServer
        ZGY->ZGY_DATA    := Date()            // Data de Emissão
        ZGY->ZGY_HORA    := Time()            // Hora de inclusão na tabela de muro
        ZGY->ZGY_USUARI  := __cUserId         // Codigo do Usuário
        ZGY->ZGY_DATAAL  := Date()            // Data de Alteração
        ZGY->ZGY_SITUAC  := "P"               // Situação do Registro
        ZGY->ZGY_ENSTUS  := "S"               // Marcou para enviar Status
        ZGY->ZGY_CODIGO  := _cPV
        ZGY->ZGY_NCARGA  := _cPV
        ZGY->ZGY_RETORN  := "ENVIO DO STATUS DO PEDIDO DO RDC "+_cOrigem
        ZGY->(MSUnLock())
        _nRec:=ZGY->(Recno())
    EndIf

Return _nRec

/*
===============================================================================================================================
Programa--------: IT_Oper_Triangular()
Autor-----------: Alex Wallauer
Data da Criacao-: 21/08/2017
Descrição-------: Geração do Pedido de Remessa em cima do Pedido de Venda e alteração de compartibilidade dos 2
Parametros------: _cPedido: Numero do Pedido da filial atual  
                  _lExclui: Replica a exclusão
Retorno---------: .T. ou .F.
===============================================================================================================================*/
User Function IT_OperTriangular(_cPedido,_lExclui,_lComTela)//U_IT_OperTriangular()

Local _aArea:=FWGetArea()
Local _aAreaSC5:=SC5->( FWGetArea() )
Local _aAreaSC6:=SC6->( FWGetArea() )
Local _nRecOrigem:=0
Local _lGerouOK:=.T.
Default _lComTela:=FWIsInCallStack("MDIEXECUTE") .Or. FWIsInCallStack("SIGAADV")

If Empty(M->C5_I_OPTRI) .Or. Empty(_cPedido)//Se esse campo C5_I_OPTRI em branco PV normal
   FWRestArea(_aAreaSC5)
   Return .T.
EndIf

SC5->(DBSetOrder(1))
If _cPedido # SC5->C5_NUM
    If !SC5->(DBSeek(xFilial()+_cPedido))
        U_MT_ITMSG("Pedido não encontrado: "+_cPedido,"Atenção!","Entrar em contato com a area de TI e dar print dessa mensagem.",1) 
        FWRestArea(_aAreaSC5)
        Return .F.
    EndIf
EndIf

Private _aLog:={}
_nRecOrigem  := SC5->(RECNO())

//INCLUSAO
If M->C5_I_OPTRI = "R" .And. !_lExclui .And. (Empty(M->C5_I_PVFAT) .Or. !SC5->(DBSeek(xFilial()+M->C5_I_PVFAT))) //Gera o PV de Faturamento
    SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem
    If !_lComTela
        _lGerouOK := ManutPed("GERA",.F.,@_lComTela)
    Else
        Processa( {|| _lGerouOK := ManutPed("GERA",.F.,_lComTela) } ,, "Gerando Pedido de Faturamento..." )
    EndIf
    If !_lGerouOK
        lRet:=.F. 
        _cProblema:="Ocorreram problemas na Geração de Pedidos de Faturamento, para maiores detalhes veja a Coluna Movimentação."
        _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR para voltar a tela do Pedido."
    EndIf
    If _lGerouOK 
        If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
            U_MT_ITMSG("Pedido de Faturamento Gerado :"+M->C5_I_PVFAT,"Atenção!",,2)
        EndIf
    EndIf     

//ALTERACAO / EXCLUSAO
ElseIf SC5->(DBSeek(xFilial()+M->C5_I_PVFAT)) .AND.;
       (SC5->C5_I_OPTRI = "R" .And. !Empty( SC5->C5_I_PVFAT ) .OR.; //Replica as alterações do PV de Remessa no PV de Faturamento
        SC5->C5_I_OPTRI = "F" .And. !Empty( SC5->C5_I_PVREM ))      //Replica as alterações do PV de Faturamento no PV de Remessa no 
    SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem
    If !_lComTela
        _lGerouOK := ManutPed("REPLICA",_lExclui,@_lComTela)
    Else
        Processa( {|| _lGerouOK := ManutPed("REPLICA",_lExclui,_lComTela) } ,, If(_lExclui,"Excluindo","Alterando")+" Pedido Triangular..." )
    EndIf

    If !_lGerouOK
        lRet:=.F. 
        _cProblema:="Ocorreram problemas na Exclusão do Pedido de Faturamento da Operação Triangular, para maiores detalhes veja a Coluna Movimentação."
        _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR."
    EndIf
EndIf

If Len(_aLog) > 0 .And. (!_lGerouOK .Or. _lComTela)
   _bOK:={|| U_ITMsg(_cProblema,"Atenção!",_cSolucao,1) , .F. }
   _bCancel := NIL
   _cMsgTop:="Para maiores detalhes clique em 'OUTRAS AÇÕES' e escolha 'EXPORTAÇÃO PARA EXCEL' de sua preferencia e veja a coluna movimentação por completa na planilha gerada'."
   U_ITListBox( 'Log de Geracao de Pedidos de Operação Triangular (XFUNOMS - Linha '+ StrZero(procline(1),6)+")" ,;
                {" ",'Pedido Fat.','Pedido Remessa','Movimentação','Cliente','Operacao'} , _aLog , .T. , 4,_cMsgTop,,;
                { 10,           50,             50,           150,      150,        35,},, _bOK,_bCancel)
EndIf     

FWRestArea(_aArea)
FWRestArea(_aAreaSC5)
FWRestArea(_aAreaSC6)

Return !_lGerouOK

/*
===============================================================================================================================
Programa--------: ManutPed()
Autor-----------: Alex Wallauer
Data da Criacao-: 22/08/2017
Descrição-------: Geração do PV de Remessa em cima do PV de Venda e alteração de compartibilidade das duas
Parametros------: _cAcao: "GERA" Gera pedido de Remessa "REPLICA" Replica a ação de um PV 
                  _lExclui: Replica a exclusão
                  _lComTela: Se vai mostrar a tela de log
Retorno---------: .T. ou .F.
===============================================================================================================================*/
Static Function ManutPed(_cAcao AS CHAR, _lExclui AS LOGICAL, _lComTela AS LOGICAL) As Logical

Local _cCliente AS CHAR, _cLoja AS CHAR, I AS NUMERIC
Local _cPedOrigem AS CHAR
Local _cTpOper AS CHAR, _aItensPV AS ARRAY
Local _lDeuErro        := .F. AS LOGICAL
Local _cOperTriangular := AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42")) AS CHAR // Tipos de operações da operação trigular
Local _cOperFat        := LEFT(_cOperTriangular, 2) AS CHAR 
Local _cOperRemessa    := RIGHT(_cOperTriangular, 2) AS CHAR 
Local _nRecOrigem      := SC5->(RECNO()) AS NUMERIC 
Local _cMostraErro     := "" AS CHAR
Local _cMensagem       := "" AS CHAR

SC5->( DBSetOrder(1) )
SC6->( DBSetOrder(1) )

If _cAcao = "GERA" //INCLUI
    _cPedOrigem  := M->C5_NUM
    M->C5_CLIENTE:= M->C5_CLIENT :=M->C5_I_CLIEN//Cliente do PV Adquirente no 42 e Principal no 05
    M->C5_LOJACLI:= M->C5_LOJAENT:=M->C5_I_LOJEN//Cliente do PV Adquirente no 42 e Principal no 05

    If !FWIsInCallStack("U_AOMS032") 
        //M->C5_VEND1  := U_AOMS006()//Gatilho do M->C5_CLIENTE Carrega esses campos: M->C5_VEND2,M->C5_VEND3
    Else
        M->C5_VEND1   := _cCodVend1  
        M->C5_VEND2   := _cCodVend2 
        M->C5_VEND3   := _cCodVend3  
        M->C5_VEND4   := _cCodVend4  
        M->C5_VEND5   := _cCodVend5  
        M->C5_I_V1NOM := _cNomVend1  
        M->C5_I_V2NOM := _cNomVend2  
        M->C5_I_V3NOM := _cNomVend3  
    EndIf 

    M->C5_I_EST  := U_AOMS017()//Gatilho do M->C5_CLIENT Carrega esses campos: M->C5_I_NOME,M->C5_I_FANTA,M->C5_I_CMUN,M->C5_I_MUN,M->C5_I_CEP,M->C5_I_END,M->C5_I_BAIRR,M->C5_I_DDD,M->C5_I_TEL,M->C5_I_GRPVE,M->C5_I_NOMRD,M->C5_I_V1NOM,M->C5_I_V2NOM,,M->C5_I_V3NOM,M->C5_I_HORP,M->C5_I_AGEND,M->C5_I_TIPCA,M->C5_I_CHPCL

    // Monta o cabeçalho do pedido NOVO
    _aCabPV  :={}//Private 
    aAdd( _aCabPV, { "C5_FILIAL"	,xFilial("SC5"), Nil})//Filial
    aAdd( _aCabPV, { "C5_TIPO"	    ,M->C5_TIPO    , Nil})//Tipo de pedido
    aAdd( _aCabPV, { "C5_I_OPER"	,_cOperFat     , Nil})//Tipo da operacao
    aAdd( _aCabPV, { "C5_CLIENTE"	,M->C5_CLIENTE , NiL})//Codigo do cliente
    aAdd( _aCabPV, { "C5_LOJACLI"	,M->C5_LOJACLI , NiL})//Loja do cliente
    aAdd( _aCabPV, { "C5_CLIENT"    ,M->C5_CLIENTE , Nil})//Codigo do cliente entrega
    aAdd( _aCabPV, { "C5_LOJAENT"	,M->C5_LOJACLI , NiL})//Loja para entrada
    aAdd( _aCabPV, { "C5_I_AGEND"   ,M->C5_I_AGEND , Nil})//Tipo de Entrega
    aAdd( _aCabPV, { "C5_VEND1"     ,M->C5_VEND1   , Nil})//Vendedor
    aAdd( _aCabPV, { "C5_I_EST"     ,M->C5_I_EST   , Nil})//Estado
    aAdd( _aCabPV, { "C5_I_HOREN"   ,M->C5_I_HOREN, Nil})   
    aAdd( _aCabPV, { "C5_I_CDUSU"   ,M->C5_I_CDUSU, Nil})   
    aAdd( _aCabPV, { "C5_I_TIPCA"   ,M->C5_I_TIPCA   , Nil})//Tipo de Carga
    aAdd( _aCabPV, { "C5_I_AGEND"   ,M->C5_I_AGEND   , Nil})//Tipo de Agendamento
    aAdd( _aCabPV, { "C5_I_CHAPA"   ,M->C5_I_CHAPA   , Nil})//Qtd de Chapa
    aAdd( _aCabPV, { "C5_I_CUSDE"   ,M->C5_I_CUSDE   , Nil})//Custo Descarga
    aAdd( _aCabPV, { "C5_I_HORDE"   ,M->C5_I_HORDE   , Nil})//Hora Descarga
    aAdd( _aCabPV, { "C5_I_TPVEN"   ,M->C5_I_TPVEN   , Nil})//Tipo de Venda
    aAdd( _aCabPV, { "C5_I_TAB"     ,M->C5_I_TAB     , Nil})//Tabela de Preço
    aAdd( _aCabPV, { "C5_TPFRETE"   ,M->C5_TPFRETE   , Nil})//Tp Frete
    aAdd( _aCabPV, { "C5_DESCONT"   ,M->C5_DESCONT   , Nil})//Desconto	
    aAdd( _aCabPV, { "C5_VEND2"     ,M->C5_VEND2     , Nil})// Codigo Coordenador 
    aAdd( _aCabPV, { "C5_VEND3"     ,M->C5_VEND3     , Nil})// Codigo Gerente
    aAdd( _aCabPV, { "C5_VEND4"     ,M->C5_VEND4     , Nil})// Codigo Supervisor
    aAdd( _aCabPV, { "C5_VEND5"     ,M->C5_VEND5     , Nil})// Codigo Gerente Nacional
    aAdd( _aCabPV, { "C5_I_V1NOM"   ,M->C5_I_V1NOM   , Nil})// Nome Representante
    aAdd( _aCabPV, { "C5_I_V2NOM"   ,M->C5_I_V2NOM   , Nil})// Nome Coordenador
    aAdd( _aCabPV, { "C5_I_V3NOM"   ,M->C5_I_V3NOM   , Nil})// Nome Gerente

    DadosPed("SC5")

    // Monta o item do pedido NOVO
    _aItemPV :={}//Private 
    _aItensPV:={}//LOCAL

    SC6->( DBSetOrder(1) )
    SC6->( DBSeek( SC5->C5_FILIAL + _cPedOrigem ) )
    While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + _cPedOrigem
        _aItemPV:={}		
        aAdd( _aItemPV,{ "C6_FILIAL" ,SC6->C6_FILIAL  , Nil }) // FILIAL
        DadosPed("SC6","SC6")
        aAdd( _aItensPV ,_aItemPV )
        SC6->( DBSkip() )
    EndDo
    // Geração do pedido NOVO
    lMsErroAuto:=.F.
        _cAOMS074 := "ManutPed()/XFUNOMS" // Variável de controle para indicar a origem da chamada de funções.
    _cAOMS074Vld := ""

    FWMsgRun( , {||  MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 3 ) }, "AGUARDE...", "GERANDO O PEDIDO DE FATURAMENTO PARA O PEDIDO DO VENDA... ") 

    If lMsErroAuto .Or. SC5->(Eof())
        If ( __lSx8 ) 
            RollBackSx8()
        EndIf 
        _cMensagem:=""
        If !Empty(_cAOMS074Vld)
            _cMensagem:="Validação Italac (_cAOMS074Vld): "+AllTrim(_cAOMS074Vld)+CRLF
        EndIf
        _cMostraErro:=""
        If _lComTela
            _cMostraErro:=" ["+AllTrim(MostraErro())+"] "
        Else
            _cMostraErro:=" ["+AllTrim(MostraErro("/data/italac/controle/","manutped_mostraerro_"+AllTrim(_cPedOrigem)+".log"))+"] "
        EndIf
        If !Empty(_cMostraErro)
            _cMostraErro:=StrTran(_cMostraErro,CRLF," ",1,1)
            _cMensagem+="Validação Padrão (MostraErro()): "
            _cMensagem+=_cMostraErro
        EndIf

        _cMensagem+=If(SC5->(Eof()),"[SC5 em Eof()]","")
        _cMensagem:='Erro ao criar o Pedido de Faturamento: '+_cMensagem
        _cCliente:=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
        aAdd( _aLog    , {.F.,M->C5_NUM     ,""              ,_cMensagem    ,_cCliente,M->C5_I_OPER} )
        
        _lDeuErro:=.T.//Se der algum Erro
    Else
        _lDeuErro:=.F.//Se der algum Erro

        // Grava campos de controle no pedido de Faturamento
        SC5->( RecLock( 'SC5' , .F. ) )
        SC5->C5_I_PVREM:= _cPedOrigem// Pedido de Venda Original
        SC5->C5_I_OPTRI:= "F"        // Marca o PV de Faturamento
        SC5->( MSUnLock() )
        _cMemAux:=""
        If SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
            While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
                If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
                    _nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA PEDIDO
                Else
                    _nQtdLib := SC9->C9_QTDLIB
                EndIf

                If _nQtdLib # SC6->C6_QTDVEN
                    _lComTela:=.T.
                    _cMemAux:=", mas Não liberou o Pedido, Item: [ "+SC6->C6_FILIAL+" "+SC6->C6_NUM+" "+SC6->C6_ITEM+"] "
                    Exit
                EndIf
                SC6->( DBSkip() )
            EndDo
        EndIf

        // Grava o LOG de Inclusão do Pedidos de Remessa Novo
        _cCliente :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") )
        _cMensagem:='Gerou o Pedido de Remessa'+_cMemAux
        aAdd( _aLog , {.T.,_cPedOrigem         ,SC5->C5_NUM         ,_cMensagem    ,_cCliente,SC5->C5_I_OPER} )
        // Grava campos de controle no pedido de Remessa
        If SC5->(DBSeek(xFilial()+_cPedOrigem))
            SC5->( RecLock( 'SC5' , .F. ) )
            SC5->C5_I_PVFAT:=M->C5_I_PVFAT:= _aLog[1,3]// Pedido de Remessa
            SC5->C5_I_OPTRI:=M->C5_I_OPTRI:= "R"       // Marca o PV  Remessa
                SC5->( MSUnLock() )
        EndIf
    EndIf
ElseIf _cAcao = "REPLICA"//ALTERA E EXCLUI
    lMsErroAuto:=.F.
    _cPedOrigem:=SC5->C5_NUM
    _cCliente  :=""
    _cLoja     :=""

    If SC5->C5_I_OPTRI = "F" // Estou no PV de Venda/Faturamento e vou alterar o de Remessa
        _cPedAltera:=SC5->C5_I_PVREM
        _cTpOper   :=_cOperRemessa
        //Vou alterar o campo de cliente princiapal do pedido de remessa
        _cCliente  :=SC5->C5_I_CLIEN//Cliente do PV de Remessa principal
        _cLoja     :=SC5->C5_I_LOJEN//Cliente do PV de Remessa principal
        _cClient   :=""
        _cLojaEnt  :=""
        If SC5->(DBSeek(xFilial()+_cPedAltera))//Quando chega nesse ponto o pedido de Origem já foi gravado
            If (_cCliente+_cLoja == SC5->C5_CLIENTE+SC5->C5_LOJACLI)//Se não mudou o cliente de remessa puxar os dados dos campos do gatilho
                M->C5_VEND1  :=SC5->C5_VEND1
            Else
                M->C5_VEND1  :=""
            EndIf
        EndIf
    ElseIf SC5->C5_I_OPTRI = "R" // Estou de PV de Remessa e vou alterar o de Venda/Faturamento
        _cPedAltera:=SC5->C5_I_PVFAT
        _cTpOper   :=_cOperFat
        //Altera somente o campo de cliente entrega do pedido de Venda/Faturamento
        _cClient   :=SC5->C5_CLIENTE//Cliente do PV de Remessa custumizado
        _cLojaEnt  :=SC5->C5_LOJACLI//Cliente do PV de Remessa custumizado
        If SC5->(DBSeek(xFilial()+_cPedAltera))//Quando chega nesse ponto o pedido de Origem já foi gravado
            _cCliente    := SC5->C5_CLIENTE
            _cLoja       := SC5->C5_LOJACLI
            M->C5_VEND1  := SC5->C5_VEND1
        EndIf
    EndIf

    SC5->( DBGoTo( _nRecOrigem ))//volta Recno do Pedido do pedido atual

    If _lExclui .And. _cPedAltera == SC5->C5_I_PVREM//Codigo de segurança para nunca deletar o PV de Remessa
        Return .F.//Para não limpar os campos
    EndIf

    _aCabPV  :={}//Private 
    aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL, Nil})//filial
    aAdd( _aCabPV, { "C5_NUM"       ,_cPedAltera   , Nil})//PEDIDO QUE SERÁ ALTERADO
    aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO  , Nil})//Tipo de pedido
        aAdd( _aCabPV, { "C5_I_OPER"	,_cTpOper      , Nil})//Tipo da operacao
    aAdd( _aCabPV, { "C5_CLIENTE"   ,_cCliente     , NiL})//Codigo do cliente
    aAdd( _aCabPV, { "C5_LOJACLI"   ,_cLoja        , NiL})//Loja do cliente
    aAdd( _aCabPV, { "C5_CLIENT"    ,_cCliente     , Nil})//Codigo do cliente entrega padrão
    aAdd( _aCabPV, { "C5_LOJAENT"   ,_cLoja        , NiL})//Loja para entrada padrão
    aAdd( _aCabPV, { "C5_I_CLIEN"   ,_cClient      , Nil})//Codigo do cliente da Remessa custumizado
    aAdd( _aCabPV, { "C5_I_LOJEN"	,_cLojaEnt     , NiL})//Loja para entrada da Remessa custumizado

    aAdd( _aCabPV, { "C5_I_TIPCA"     ,SC5->C5_I_TIPCA   , Nil})//Tipo de Carga
    aAdd( _aCabPV, { "C5_I_AGEND"     ,SC5->C5_I_AGEND   , Nil})//Tipo de Agendamento
    aAdd( _aCabPV, { "C5_I_CHAPA"     ,SC5->C5_I_CHAPA   , Nil})//Qtd de Chapa
    aAdd( _aCabPV, { "C5_I_CUSDE"     ,SC5->C5_I_CUSDE   , Nil})//Custo Descarga
    aAdd( _aCabPV, { "C5_I_HORDE"     ,SC5->C5_I_HORDE   , Nil})//Hora Descarga
    aAdd( _aCabPV, { "C5_I_TPVEN"     ,SC5->C5_I_TPVEN   , Nil})//Tipo de Venda
    aAdd( _aCabPV, { "C5_I_TAB"       ,SC5->C5_I_TAB     , Nil})//Tabela de Preço		
    aAdd( _aCabPV, { "C5_TPFRETE"     ,SC5->C5_TPFRETE   , Nil})//Tp Frete
    aAdd( _aCabPV, { "C5_DESCONT"     ,SC5->C5_DESCONT   , Nil})//Desconto	

    If !Empty(M->C5_VEND1)
        aAdd( _aCabPV, { "C5_VEND1"  ,M->C5_VEND1   , Nil})//Vendedor
    EndIf
    aAdd( _aCabPV, { "C5_I_AGEND"   ,M->C5_I_AGEND , Nil})//Tipo de Entrega
    DadosPed("SC5")

    SC6->( DBSeek( SC5->C5_FILIAL + _cPedAltera ) )
    _aItensPVAlt:={}
    While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + _cPedAltera
        aAdd(_aItensPVAlt,{ SC6->C6_ITEM,.F.,SC6->(RECNO()) })
        SC6->( DBSkip() )
    EndDo

    // Monta o item do pedido
    _aItemPV :={}
    _aItensPV:={}
    SC6->( DBSetOrder(1) )
    SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )//Pedido alterado
    While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
        If (nPos:=aScan(_aItensPVAlt,{|I| I[1]==SC6->C6_ITEM} )) = 0
            _lExisteItem :=.F.//Inclusão
        Else
            _lExisteItem:=.T.//Alterado
            _aItensPVAlt[nPos,2]:=.T.
        EndIf

        _aItemPV:={}		
        If _lExisteItem//Não adiciona se For uma inclusão
            aAdd( _aItemPV, { "LINPOS", "C6_ITEM", SC6->C6_ITEM } )//Esse item é adicionado para localizar a linha na Execauto quando a linha é alterada ou excluída
        EndIf

        aAdd( _aItemPV, { "AUTDELETA" , "N"            , nil })//Indica se a linha está sendo excluída ou não
        aAdd( _aItemPV, { "C6_FILIAL" ,SC6->C6_FILIAL  , Nil })// FILIAL
        aAdd( _aItemPV, { "C6_NUM"    ,SC6->C6_NUM     , Nil })// Num. Pedido

        DadosPed("SC6","SC6")//COLOCA NA _aItemPV os outros campos

        aAdd( _aItensPV ,_aItemPV )

        SC6->( DBSkip() )
    EndDo

    For I := 1 To Len(_aItensPVAlt)
        If !_aItensPVAlt[I,2]
            SC6->(DBGoTo(_aItensPVAlt[I,3]))
            _aItemPV:={}		
            aAdd( _aItemPV, { "LINPOS"    ,"C6_ITEM"       , SC6->C6_ITEM } )//Esse item é adicionado para localizar a linha na Execauto quando a linha é alterada ou excluída
            aAdd( _aItemPV, { "AUTDELETA" ,"S"             , Nil })//Indica se a linha está sendo excluída ou não
            aAdd( _aItemPV, { "C6_FILIAL" ,SC6->C6_FILIAL  , Nil })// FILIAL
            aAdd( _aItemPV, { "C6_NUM"    ,SC6->C6_NUM     , Nil })// Num. Pedido
            aAdd( _aItensPV ,_aItemPV )
        EndIf   
    Next I

    // REPLICA O PEDIDO OU EXCLUI
    SC9->( DBSetOrder(1) )
    _cMensagem:=""
    If _lExclui .And. SC9->( DBSeek( SC5->C5_FILIAL + _cPedAltera  ) )//SE TIVER SC9 ESTORNA A LIBERACAO
        SC6->(DBSetOrder(1))
        SC6->(DBSeek(SC5->C5_FILIAL+_cPedAltera))
        
        //Se tiver liberação válida para todos os itens desfaz liberação
        While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+_cPedAltera
            SC9->(DBSetOrder(1))
            If (SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)))
                SC9->(_lRet:=A460Estorna()) // estorna a liberação
                If !_lRet
                    _cMensagem+="Pedido + Item: "+SC6->C6_NUM+" + "+SC6->C6_ITEM+" teve problemas na liberação "
                    lMsErroAuto:=.T.
                EndIf
            EndIf
            SC6->(DBSkip())
        EndDo
        
        SC9->(DBSetOrder(1))
        If !SC9->(DBSeek(SC5->C5_FILIAL+_cPedAltera))
            SC5->(RecLock("SC5",.F.))
            SC5->C5_LIBEROK := "  "
            SC5->C5_I_STATU := "01"
            SC5->(MSUnLock())
        Else
                _cMensagem+="Pedido: "+SC6->C6_NUM+" teve problemas na liberação (Ainda tem SC9) "
            lMsErroAuto:=.T.
        EndIf
    EndIf

    If !lMsErroAuto
        If _lComTela
                FWMsgRun( , {||  MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , If(_lExclui,5,4) ) }, "AGUARDE...",If(_lExclui,"EXCLUINDO","ALTERANDO")+" O PEDIDO DE FATURAMENTO DA O.T. ... ")   	
        Else
            MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , If(_lExclui,5,4) ) 
        EndIf
    EndIf

    _cCliente :=_cCliente+" / "+_cLoja+" / "+AllTrim( Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLoja,"A1_NREDUZ") )

    If lMsErroAuto
        If ( __lSx8 )
            RollBackSx8()
        EndIf 
        If Empty(_cMensagem)
            _cMensagem:=" ["+MostraErro()+"]"
        EndIf

        SC5->( DBGoTo( _nRecOrigem ))//Recno do Pedido de Origem 
        If _lExclui
            _cMensagem:='Erro ao excluir o Pedido '+_cPedAltera+': '+_cMensagem
        Else
            _cMensagem:='Erro ao alterar o Pedido '+_cPedAltera+': '+_cMensagem
        EndIf
        aAdd( _aLog    , {.F.,SC5->C5_I_PVFAT     ,SC5->C5_I_PVREM ,_cMensagem    ,_cCliente,SC5->C5_I_OPER} )
        
        _lDeuErro:=.T.//Se der algum Erro
    Else
        If _lExclui
            SC5->( DBGoTo( _nRecOrigem ))//Recno do Pedido de Origem 
            SC5->( RecLock( 'SC5' , .F. ) )
            SC5->C5_I_PVFAT:=Space(Len(SC5->C5_I_PVFAT))
                SC5->( MSUnLock() )
            _lDeuErro:=.F.//Se der algum Erro
            _cMensagem:='Foi Excluido o Pedido de Faturamento da Operacao Triangular: '+_cPedAltera
        Else
            _cMemAux:=""
            If SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
                While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
                    If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
                        _nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA PEDIDO
                    Else
                        _nQtdLib := SC9->C9_QTDLIB
                    EndIf

                    If _nQtdLib # SC6->C6_QTDVEN
                        _lComTela:=.T.
                        _cMemAux:=", mas Não liberou o Pedido, Item: [ "+SC6->C6_FILIAL+" "+SC6->C6_NUM+" "+SC6->C6_ITEM+"] "
                        Exit
                    EndIf

                    SC6->( DBSkip() )
                EndDo
            EndIf
            _cMensagem:='Foi alterado o Pedido de Faturamento da Operacao Triangular: '+_cPedAltera+_cMemAux
        EndIf
        aAdd( _aLog , {.T.,SC5->C5_NUM         ,SC5->C5_I_PVREM ,_cMensagem    ,_cCliente,SC5->C5_I_OPER} )

        If !FWIsInCallStack("U_AOMS109") .And. _lComTela
            U_ITMsg(_cMensagem,"Atenção!",,2)
        EndIf
    EndIf
EndIf

Return !_lDeuErro
 
/*
===============================================================================================================================
Programa--------: DadosPed()
Autor-----------: Alex Wallauer
Data da Criacao-: 22/08/2017
Descrição-------: Carregamentos das arrays das tebelas SC5 e SC6
Parametros------: _cTabela: SC5 ou SC6 
                  _cAlias: Alias dos itens
Retorno---------: .T.
===============================================================================================================================*/
Static Function DadosPed(_cTabela,_cAlias)

If _cTabela = "SC5"
    aAdd( _aCabPV, { "C5_EMISSAO"    ,M->C5_EMISSAO, NiL}) //Data de emissao
    aAdd( _aCabPV, { "C5_TRANSP"     ,M->C5_TRANSP , Nil}) 
    aAdd( _aCabPV, { "C5_CONDPAG"    ,M->C5_CONDPAG, NiL}) //Codigo da condicao de pagamanto*
    aAdd( _aCabPV, { "C5_MOEDA"	    ,M->C5_MOEDA  , Nil}) //Moeda
    aAdd( _aCabPV, { "C5_MENPAD"     ,M->C5_MENPAD , Nil}) 
    aAdd( _aCabPV, { "C5_LIBEROK"    ,M->C5_LIBEROK, NiL}) //Liberacao Total
    aAdd( _aCabPV, { "C5_TIPLIB"     ,M->C5_TIPLIB , Nil}) //Tipo de Liberacao
    aAdd( _aCabPV, { "C5_TIPOCLI"    ,M->C5_TIPOCLI, NiL}) //Tipo do Cliente
    aAdd( _aCabPV, { "C5_I_NPALE"    ,M->C5_I_NPALE, NiL}) //Numero que originou a pedido de palete
    aAdd( _aCabPV, { "C5_I_PEDPA"    ,M->C5_I_PEDPA, NiL}) //Pedido Refere a um pedido de Pallet
    aAdd( _aCabPV, { "C5_I_DTENT"    ,M->C5_I_DTENT, Nil}) //Dt de Entrega // M->C5_I_DTENT
    aAdd( _aCabPV, { "C5_I_TRCNF" ,M->C5_I_TRCNF , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_FLFNC" ,M->C5_I_FLFNC , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_FILFT" ,M->C5_I_FILFT , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_PDFT"  ,M->C5_I_PDFT  , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_PDPR"  ,M->C5_I_PDPR  , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_LOCEM" ,M->C5_I_LOCEM , NIL})//Campos do Troca Nota agora serão  replicados do Pedido 42 para o Pedido 05, Chamado 43893
    aAdd( _aCabPV, { "C5_I_OBCOP" 	,M->C5_I_OBCOP, Nil})
    aAdd( _aCabPV, { "C5_I_OBPED" 	,M->C5_I_OBPED, Nil})
    aAdd( _aCabPV, { "C5_I_BLPRC"    ,M->C5_I_BLPRC, Nil})
    aAdd( _aCabPV, { "C5_I_BLCRE"    ,M->C5_I_BLCRE, Nil})
    aAdd( _aCabPV, { "C5_I_BLCRE"    ,M->C5_I_BLCRE, Nil})
    aAdd( _aCabPV, { "C5_I_SENHA"    ,M->C5_I_SENHA, Nil})
    aAdd( _aCabPV, { "C5_I_HOREN"    ,M->C5_I_HOREN, Nil})   
    aAdd( _aCabPV, { "C5_I_TIPCA"    ,M->C5_I_TIPCA, Nil})
    aAdd( _aCabPV, { "C5_I_CDUSU"    ,M->C5_I_CDUSU, Nil})   
    aAdd( _aCabPV, { "C5_MENNOTA"    ,M->C5_MENNOTA, Nil})
    aAdd( _aCabPV, { "C5_MENPAD"     ,M->C5_MENPAD , Nil})
    aAdd( _aCabPV, { "C5_I_PODES"    ,""           , Nil})//Limpar esse campos sempre, Chamado 43893
    aAdd( _aCabPV, { "C5_I_BLPRC"    ,M->C5_I_BLPRC, Nil}) 
    aAdd( _aCabPV, { "C5_I_DTLIB"    ,M->C5_I_DTLIB, Nil})
    aAdd( _aCabPV, { "C5_I_IDPED"    ,M->C5_I_IDPED, Nil})
    aAdd( _aCabPV, { "C5_ORIGEM "    ,M->C5_ORIGEM , Nil})
    aAdd( _aCabPV, { "C5_I_DTAIM"    ,M->C5_I_DTAIM, Nil})
    aAdd( _aCabPV, { "C5_I_HORAI"    ,M->C5_I_HORAI, Nil})
    aAdd( _aCabPV, { "C5_I_DATAA"    ,M->C5_I_DATAA, Nil})
    aAdd( _aCabPV, { "C5_I_HORAA"    ,M->C5_I_HORAA, Nil})
    aAdd( _aCabPV, { "C5_I_DTLIP"    ,M->C5_I_DTLIP, Nil})
    aAdd( _aCabPV, { "C5_I_MLIBP"    ,M->C5_I_MLIBP, Nil})
    aAdd( _aCabPV, { "C5_I_DTAVA"    ,M->C5_I_DTAVA, Nil})
    aAdd( _aCabPV, { "C5_I_HRAVA"    ,M->C5_I_HRAVA, Nil})
    aAdd( _aCabPV, { "C5_I_USRAV"    ,M->C5_I_USRAV, Nil})
    aAdd( _aCabPV, { "C5_I_LIBCA"    ,M->C5_I_LIBCA, Nil})
    aAdd( _aCabPV, { "C5_I_LIBCT"    ,M->C5_I_LIBCT, Nil})
    aAdd( _aCabPV, { "C5_I_LIBL "    ,M->C5_I_LIBL , Nil})
    aAdd( _aCabPV, { "C5_I_LIBCV"    ,M->C5_I_LIBCV, Nil}) //49 valor liberado de crédito
    aAdd( _aCabPV, { "C5_I_LIBCD"    ,M->C5_I_LIBCD, Nil})
    aAdd( _aCabPV, { "C5_I_BLCRE"    ,M->C5_I_BLCRE, Nil})
    aAdd( _aCabPV, { "C5_I_MOTBL"    ,M->C5_I_MOTBL, Nil})
    aAdd( _aCabPV, { "C5_I_DTLIC"    ,M->C5_I_DTLIC, Nil})
    aAdd( _aCabPV, { "C5_I_PLIBP"    ,M->C5_I_PLIBP, Nil})
    aAdd( _aCabPV, { "C5_I_ULIBP"    ,M->C5_I_ULIBP, Nil}) 
    aAdd( _aCabPV, { "C5_I_VLIBP"    ,M->C5_I_VLIBP, Nil})//56 valor liberado de preço
    aAdd( _aCabPV, { "C5_I_MOTLP"    ,M->C5_I_MOTLP, Nil})
    aAdd( _aCabPV, { "C5_I_MOTLB"    ,M->C5_I_MOTLB, Nil})
    aAdd( _aCabPV, { "C5_I_QLIBP"    ,M->C5_I_QLIBP, Nil}) //59 TOTAL liberado de preço
    aAdd( _aCabPV, { "C5_I_VLIBB"    ,M->C5_I_VLIBB, Nil})//60 valor liberado de bonificação
    aAdd( _aCabPV, { "C5_I_QLIBB"    ,M->C5_I_QLIBB, Nil})
    aAdd( _aCabPV, { "C5_I_CLILP"    ,M->C5_I_CLILP, Nil})
    aAdd( _aCabPV, { "C5_I_CLILB"    ,M->C5_I_CLILB, Nil})
    aAdd( _aCabPV, { "C5_I_LLIBB"    ,M->C5_I_LLIBB, Nil})
    aAdd( _aCabPV, { "C5_I_ULIBB"    ,M->C5_I_ULIBB, Nil})
    aAdd( _aCabPV, { "C5_I_LLIBP"    ,M->C5_I_LLIBP, Nil})
    aAdd( _aCabPV, { "C5_I_HLIBP"    ,M->C5_I_HLIBP, Nil})
    aAdd( _aCabPV, { "C5_I_FILOR"    ,M->C5_I_FILOR, Nil})
    aAdd( _aCabPV, { "C5_I_PEDOR"    ,M->C5_I_PEDOR, Nil})
    aAdd( _aCabPV, { "C5_I_DTRAN"    ,M->C5_I_DTRAN, Nil})
    aAdd( _aCabPV, { "C5_I_UTRAN"    ,M->C5_I_UTRAN, Nil})
    aAdd( _aCabPV, { "C5_I_MTRAN"    ,M->C5_I_MTRAN, Nil})
    aAdd( _aCabPV, { "C5_I_DOCA "    ,M->C5_I_DOCA , Nil})
    aAdd( _aCabPV, { "C5_I_FLFNC"    ,M->C5_I_FLFNC, Nil})
    aAdd( _aCabPV, { "C5_I_OBSAV"    ,M->C5_I_OBSAV, Nil})
    aAdd( _aCabPV, { "C5_I_FILFT"    ,M->C5_I_FILFT, Nil})
    aAdd( _aCabPV, { "C5_I_TAB "    ,M->C5_I_TAB , Nil}) 
ElseIf _cTabela = "SC6"
    aAdd( _aItemPV , { "C6_ITEM"    ,(_cAlias)->C6_ITEM    , Nil}) // Numero do Item no Pedido
    aAdd( _aItemPV , { "C6_PRODUTO" ,(_cAlias)->C6_PRODUTO , Nil}) // Codigo do Produto
    aAdd( _aItemPV , { "C6_UNSVEN"  ,(_cAlias)->C6_UNSVEN  , Nil}) // Quantidade Vendida 2 un
    aAdd( _aItemPV , { "C6_QTDVEN"  ,(_cAlias)->C6_QTDVEN  , Nil}) // Quantidade Vendida
    aAdd( _aItemPV , { "C6_PRCVEN"  ,(_cAlias)->C6_PRCVEN  , Nil}) // Preco Unitario Liquido
    aAdd( _aItemPV , { "C6_PRUNIT"  ,(_cAlias)->C6_PRUNIT  , Nil}) // Preco Unitario Liquido
    aAdd( _aItemPV , { "C6_ENTREG"  ,(_cAlias)->C6_ENTREG  , Nil}) // Data da Entrega
    aAdd( _aItemPV , { "C6_LOJA"    ,(_cAlias)->C6_LOJA	   , Nil})
    aAdd( _aItemPV , { "C6_SUGENTR" ,(_cAlias)->C6_SUGENTR , Nil}) // Data da Entrega
    aAdd( _aItemPV , { "C6_VALOR"   ,(_cAlias)->C6_VALOR   , Nil}) // valor total do item // (_cAlias)->C6_VALOR
    aAdd( _aItemPV , { "C6_UM"      ,(_cAlias)->C6_UM      , Nil}) // Unidade de Medida Primar.
    aAdd( _aItemPV , { "C6_LOCAL"   ,(_cAlias)->C6_LOCAL   , Nil}) // Almoxarifado
    aAdd( _aItemPV , { "C6_DESCRI"  ,(_cAlias)->C6_DESCRI  , Nil}) // Descricao
    aAdd( _aItemPV , { "C6_QTDLIB"  ,(_cAlias)->C6_QTDLIB  , Nil}) // Quantidade Liberada
    aAdd( _aItemPV , { "C6_PEDCLI"  ,(_cAlias)->C6_PEDCLI  , Nil})
    aAdd( _aItemPV , { "C6_I_BLPRC" ,(_cAlias)->C6_I_BLPRC , Nil})
    aAdd( _aItemPV , { "C6_I_QPALT" ,(_cAlias)->C6_I_QPALT , Nil}) // Quantidade de Pallets
    aAdd( _aItemPV,  { "C6_I_USER " ,(_cAlias)->C6_I_USER  , Nil})
    aAdd( _aItemPV,  { "C6_I_LIBPC" ,(_cAlias)->C6_I_LIBPC , Nil})
    aAdd( _aItemPV,  { "C6_I_DLIBP" ,(_cAlias)->C6_I_DLIBP , Nil})
    aAdd( _aItemPV,  { "C6_I_PLIBP" ,(_cAlias)->C6_I_PLIBP , Nil})
    aAdd( _aItemPV,  { "C6_I_ULIBP" ,(_cAlias)->C6_I_ULIBP , Nil})
    aAdd( _aItemPV,  { "C6_I_VLIBP" ,(_cAlias)->C6_I_VLIBP , Nil})
    aAdd( _aItemPV,  { "C6_I_MOTLP" ,(_cAlias)->C6_I_MOTLP , Nil})
    aAdd( _aItemPV,  { "C6_I_QTLIP" ,(_cAlias)->C6_I_QTLIP , Nil})
    aAdd( _aItemPV,  { "C6_I_CLILP" ,(_cAlias)->C6_I_CLILP , Nil})
    aAdd( _aItemPV,  { "C6_I_CLILB" ,(_cAlias)->C6_I_CLILB , Nil})
    aAdd( _aItemPV,  { "C6_I_VLIBB" ,(_cAlias)->C6_I_VLIBB , Nil})
    aAdd( _aItemPV,  { "C6_I_QLIBB" ,(_cAlias)->C6_I_QLIBB , Nil})
    aAdd( _aItemPV,  { "C6_I_LLIBP" ,(_cAlias)->C6_I_LLIBP , Nil})
    aAdd( _aItemPV,  { "C6_I_LLIBB" ,(_cAlias)->C6_I_LLIBB , Nil})
    aAdd( _aItemPV,  { "C6_I_MOTLB" ,(_cAlias)->C6_I_MOTLB , Nil})
    aAdd( _aItemPV,  { "C6_I_PLIBB" ,(_cAlias)->C6_I_PLIBB , Nil})
    aAdd( _aItemPV,  { "C6_I_DLIBB" ,(_cAlias)->C6_I_DLIBB , Nil})
    aAdd( _aItemPV,  { "C6_I_VLTAB" ,(_cAlias)->C6_I_VLTAB , Nil})
    aAdd( _aItemPV,  { "C6_I_PRMIN" ,(_cAlias)->C6_I_PRMIN , Nil})
EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: IT_conpg()
Autor-----------: Josué Danich Prestes
Data da Criacao-: 26/03/2018
Descrição-------: Retorna condição de pagamento personalizada
Parametros------: _cCliente - código do cliente
                  _cLoja - loja do cliente
                  _cproduto - produto
                  _lTemCP_Especial - Se tem condição especial
Retorno---------: _cCondEspecial - código da condição de pagamento
===============================================================================================================================*/
User Function IT_conpg(_cCliente,_cLoja,_cproduto,_lTemCP_Especial)

Local _cCondEspecial := " "

Default _cCliente    := M->C5_CLIENT
Default _cLoja       := M->C5_LOJAENT
Default _cproduto    := " "

_lTemCP_Especial:= .F.
//Posiciona cliente
SA1->(DBSetOrder(1))
If !( SA1->(DBSeek(xFilial("SA1")+_cCliente+_cLoja)))
    Return _cCondEspecial
EndIf

If Empty(_cproduto) .And. Empty(M->C5_CONDPAG)
_cCondEspecial := AllTrim(SA1->A1_COND) 
EndIf 

//Por cliente +  loja
ZGO->(DBSetOrder(2)) //ZGO_CLIENT+ZGO_LOJA

If ZGO->(DBSeek(_cCliente+_cLoja))
    //Fase um - Procura condição com filial vazia e produto vazio
    While ZGO->ZGO_CLIENT == _cCliente .And. ZGO->ZGO_LOJA == _cLoja
        If Empty(ZGO->ZGO_PRODUT) .And. Empty(ZGO->ZGO_FILCD)  
            _cCondEspecial := ZGO->ZGO_CONDPA
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(_cCliente+_cLoja))

    //Fase dois - Procura condição com filial igual cfilant e produto vazio
    While ZGO->ZGO_CLIENT == _cCliente .And. ZGO->ZGO_LOJA == _cLoja
        If Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_FILCD) == AllTrim(cfilant) 
            _cCondEspecial := ZGO->ZGO_CONDPA
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(_cCliente+_cLoja))

    //Fase três - Procura condição com filial vazia e produto preenchido
    While ZGO->ZGO_CLIENT == _cCliente .And. ZGO->ZGO_LOJA == _cLoja
        If !Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_PRODUT) == AllTrim(_cproduto) .And. Empty(ZGO->ZGO_FILCD)  
            _lTemCP_Especial := .T.
            _cCondEspecial := ZGO->ZGO_CONDPA
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(_cCliente+_cLoja))

    //Fase quatro - procura condição com filial igual cfilant e produto igual ao primeiro produto do acols
    While ZGO->ZGO_CLIENT == _cCliente .And. ZGO->ZGO_LOJA == _cLoja
        If !Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_PRODUT) == AllTrim(_cproduto) .And. AllTrim(ZGO->ZGO_FILCD) == AllTrim(cfilant)  
            _lTemCP_Especial := .T.
            _cCondEspecial := ZGO->ZGO_CONDPA
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(_cCliente+_cLoja))
EndIf		
 
ZGO->(DBSetOrder(5)) //ZGO_REDE

//Por rede
If ZGO->(DBSeek(SA1->A1_GRPVEN))
    //Fase um - Procura condição com filial vazia e produto vazio
    While ZGO->ZGO_REDE == SA1->A1_GRPVEN
        If Empty(ZGO->ZGO_PRODUT) .And. Empty(ZGO->ZGO_FILCD)  
            _cCondEspecial := ZGO->ZGO_CONDPA 
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(SA1->A1_GRPVEN))			

    //Fase dois - Procura condição com filial igual cfilant e produto vazio
    While ZGO->ZGO_REDE == SA1->A1_GRPVEN    
        If Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_FILCD) == AllTrim(cfilant) 
            _cCondEspecial := ZGO->ZGO_CONDPA      
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(SA1->A1_GRPVEN))			

    //Fase três - Procura condição com filial vazia e produto preenchido
    While ZGO->ZGO_REDE == SA1->A1_GRPVEN
        If !Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_PRODUT) == AllTrim(_cproduto) .And. Empty(ZGO->ZGO_FILCD)  
            _lTemCP_Especial := .T.
            _cCondEspecial := ZGO->ZGO_CONDPA
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(SA1->A1_GRPVEN))			

    //Fase quatro - procura condição com filial igual cfilant e produto igual ao primeiro produto do acols
    While ZGO->ZGO_REDE == SA1->A1_GRPVEN
        If !Empty(ZGO->ZGO_PRODUT) .And. AllTrim(ZGO->ZGO_PRODUT) == AllTrim(_cproduto) .And. AllTrim(ZGO->ZGO_FILCD) == AllTrim(cfilant)  
            _cCondEspecial := ZGO->ZGO_CONDPA           
            _lTemCP_Especial := .T.
        EndIf
        ZGO->(DBSkip())
    EndDo
    ZGO->(DBSeek(SA1->A1_GRPVEN))
EndIf

If Empty(_cCondEspecial)
    _cCondEspecial :=  M->C5_CONDPAG
EndIf

Return _cCondEspecial

/*
===============================================================================================================================
Programa--------: IT_conpv()
Autor-----------: Josué Danich Prestes
Data da Criacao-: 26/03/2018
Descrição-------: Retorna condição de pagamento personalizada para o pedido de vendas aberto
Parametros------: apenas o lret de retorno da validação mas precisa estar com pedido aberto no mata410
Retorno---------: _cCondPagOK - código da condição de pagamento
===============================================================================================================================
*/
User Function IT_conpv(lret as logical) as char

Local _cCPag   := "" As Char
Local _cCondPagOK := u_IT_conpg(AllTrim(M->C5_CLIENT),AllTrim(M->C5_LOJAENT)) As Char//Busca a condição de pagamento do cliente (pode especial sem produto) ou do SC5
Local nx := 0 As Numeric
Local _nPosPro := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"}) As Numeric
Local _nPosDesc:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_DESCRI" }) As Numeric
Local _lTemCP_Especial := .F. As Logical
Local _cCPSemProd := _cCondPagOK As Char
Default lret   := .T. 

For nx:=1 To Len(aCols)
    If !aTail(aCols[nx])  // Se Linha Nao Deletada
       _cCPag :=  u_IT_conpg(AllTrim(M->C5_CLIENT),AllTrim(M->C5_LOJAENT),acols[nx][_npospro],@_lTemCP_Especial)
       If nx = 1 .And. !Empty(_cCPag) .And. Empty(_cCPSemProd)//Se não tiver a condição do cliente e do SC5 , a CP do 1o item que vale de comparacao com os outros
          _cCPSemProd := _cCPag
       EndIf
       If !Empty(_cCPag) .And. _lTemCP_Especial
           _cCondPagOK := _cCPag
       EndIf
       If _cCPSemProd <> _cCondPagOK  //Se a condição do produto é diferente da encontrada em outros produtos do pedido
          U_MT_ITMSG("O produto " + AllTrim(acols[nx][_npospro])+" - "+AllTrim(acols[nx][_nPosDesc])+" tem a regra de condição de pagamento " +  _cCondPagOK + " em divergência com a condição " + _cCPSemProd + " já definida nos demais produtos ou pedido!",;
                     "Atenção","Elabore um pedido de vendas separado para outra condição de pagamento",1)
          lRet := .F.
          Exit
        EndIf
    EndIf
Next nx

Return _cCondPagOK

/*
===============================================================================================================================
Programa--------: U_ITTABPRC
Autor-----------: Josué Danich Prestes
Data da Criacao-: 26/03/2018
Descrição-------: Retorna tabela de preços para o pedido de vendas #PRECODEVENDAS

Parametros------: _cFilCarreg- Filial de embarque
                  _cFilFatura- Filial de faturamento
                  _cGeren    - Gerente da venda
                  _cCoord    - Coordenador da venda
                  _cVend     - Vendedor do pedido
                  _cCliente  - Cliente do pedido
                  _cLojacli  - Loja do cliente do pedido	
                  _lUsaNovo  - Sempre usa novo cadastro de tabela de preços - NÃO USA MAIS
                  _cTab      - Nome da tabela
                  _cSuper    - Codigo do supervisor
                  _cRede     - Codigo da rede
                  _cGrupoPrd - Codigo do grupo de produtos - NÃO USA MAIS
                  _cTipoOper - Codigo do tipo de operação
                  _cLocalEmb - Codigo do Local de Embarque
                  _cCliAdqu  - Cliente Adquirente do pedido
                  _cLojadqu  - Loja do cliente Adquirente do pedido	

Retorno---------: _aRet - array com código a tabela de preços e recno de origem da regra 
===============================================================================================================================
*/
User Function ITTabPrc(_cFilCarreg As Char,;
                       _cFilFatura As Char,;
                        _cGeren As Char,;
                        _cCoord As Char,;
                        _cVend As Char,;
                        _cCliente As Char,;
                        _cLojaCli As Char,;
                        _lUsaNovo As Logical,;
                        _cTab As Char,;
                        _cSuper As Char,;
                        _cRede As Char,;
                        _cGrupoPrd As Char,;
                        _cTipoOper As Char,;
                        _cLocalEmb As Char,;
                        _cCliAdqu As Char,;
                        _cLojadqu As Char) As Array
 Local _cTabDireta As Char
 Local _nRecno As Numeric
 Local _cRegra As Char
 Local _cFilori As Char
 Local _nI As Numeric
 Local _cRegra1 := " " As Char
 Local _cRegra2 As Char
 Local _cRegra3 As Char
 Local _cRegra4 As Char
 Local _cRegra5 As Char
 Local _cRegra6 As Char
 Local _cRegra7 As Char
 Local _cTabPre1 As Char
 Local _cTabPre2 As Char
 Local _cTabPre3 As Char
 Local _cTabPre4 As Char
 Local _cTabPre5 As Char
 Local _cTabPre6 As Char
 Local _cTabPre7 As Char
 Local _nRecno1 As Numeric
 Local _nRecno2 As Numeric
 Local _nRecno3 As Numeric
 Local _nRecno4 As Numeric
 Local _nRecno5 As Numeric
 Local _nRecno6 As Numeric
 Local _nRecno7 As Numeric
 Local _nFatMinPrc As Numeric
 Local _cGrupoP :="" As Char
 Local _cGrupoP1 As Char
 Local _cGrupoP2 As Char
 Local _cGrupoP3 As Char
 Local _cGrupoP4 As Char
 Local _cGrupoP5 As Char
 Local _cGrupoP6 As Char
 Local _cGrupoP7 As Char
 Local _cUFPedV :="" As Char
 Local _cUFPedV1 As Char
 Local _cUFPedV2 As Char
 Local _cUFPedV3 As Char
 Local _cUFPedV4 As Char
 Local _cUFPedV5 As Char
 Local _cUFPedV6 As Char
 Local _cUFPedV7 As Char
 Local _cSegCli  As Char
 Local _cUF      As Char
 Local _cOperTriangular As Char
 Local _cOperRemessa    As Char
 Local _cOperFat        As Char
 Local _lRegraNova      As Logical //Mudança na politica de Preço de Vendas 01/2025
 Local _aCposBusca      As Array
 Local _aDadosZGQ       As Array
  
 _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação trigular
 _cOperFat       := LEFT(_cOperTriangular,2)
 _cOperRemessa   := RIGHT(_cOperTriangular,2)
 _lRegraNova     := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
 _lRegraNova     := SuperGetMV("MV_ITMDREG",, _lRegraNova ) //O PARAMETRO DEVE SER CRIADO LOGICO
 _lRegraNova     := _lRegraNova .And. ZGQ->(FIELDPOS("ZGQ_LOCEMB")) > 0 .And. ZGQ->(FIELDPOS("ZGQ_SEGCLI")) > 0
 _cTabDireta     := "   " //Origem do Cliente ou da Operação
 _nRecno         := 0
 _cRegra         := "Não Encontrou Tabela"
 _cfilori        := cfilant
 
 //CARREGA DEFAULTS POIS QUANDO ESTÃO COM O PEDIDO DE VENDAS ABERTO CHAMA A FUNÇÃO SEM PARÂMETROS
 If Type("M->C5_I_OPER") = "C"
    Default _cTipoOper := M->C5_I_OPER 
    Default _cTab      := M->C5_I_TAB 
    Default _cRede     := M->C5_I_GRPVE
    Default _cFilCarreg:= M->C5_FILGCT
    Default _cFilFatura:= M->C5_I_FILFT
    Default _cSuper    := M->C5_VEND4
    Default _cGeren    := M->C5_VEND3
    Default _cCoord    := M->C5_VEND2
    Default _cVend     := M->C5_VEND1
    Default _cCliente  := M->C5_CLIENTE
    Default _cLojacli  := M->C5_LOJACLI
    Default _cLocalEmb := M->C5_I_LOCEM
    Default _cCliAdqu  := M->C5_I_CLIEN
    Default _cLojadqu  := M->C5_I_LOJEN
 Else
    Default _cTipoOper := SC5->C5_I_OPER 
    Default _cTab      := SC5->C5_I_TAB 
    Default _cRede     := SC5->C5_I_GRPVE
    Default _cFilCarreg:= SC5->C5_FILGCT
    Default _cFilFatura:= SC5->C5_I_FILFT
    Default _cSuper    := SC5->C5_VEND4
    Default _cGeren    := SC5->C5_VEND3
    Default _cCoord    := SC5->C5_VEND2
    Default _cVend     := SC5->C5_VEND1
    Default _cCliente  := SC5->C5_CLIENTE
    Default _cLojacli  := SC5->C5_LOJACLI
    Default _cLocalEmb := SC5->C5_I_LOCEM
    Default _cCliAdqu  := SC5->C5_I_CLIEN
    Default _cLojadqu  := SC5->C5_I_LOJEN
 EndIf
 
 Begin Sequence
 
 //Carrega dados de filial, filial de faturamento e carregamento se não foram informados
 If Type("M->C5_NUM") = "C"
     If M->C5_NUM == SC5->C5_NUM
         _cfilial := SC5->C5_FILIAL //Se ja estão gravando o pedido sempre considera o C5_FILIAL para operações multifiliais
     Else
         _cfilial := cfilant //Se não inclusão considera a filial atual
     EndIf
 Else
     _cfilial := _cFilFatura //Se não tem a variavel de memoria não tem como saber se chama com SC5 ou SZW
 EndIf
 
 If Empty(_cFilCarreg)
     _cFilCarreg := _cfilial
 EndIf
 
 If Empty(_cFilFatura)
     _cFilFatura := _cfilial 
 EndIf 
 
 //Muda filial para filial de faturamento para carregar parâmetros corretamente
 cfilant := _cFilFatura// AGORA JÁ ESTA NA FILIAL DE FATURAMENTO
 
 //     PRIMEIRA BUSCA
 _cTabDireta := Posicione("ZB4",1,xFilial("ZB4")+_cTipoOper,"ZB4_TABPRC")
 
 If Empty(_cTabDireta) .Or. !(DA0->(DBSeek(xFilial("DA0")+_cTabDireta))) .Or. DA0->DA0_ATIVO = '2' .Or. DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < Date()//Tabela inativa
    _cTabDireta:= "   "
 Else
    _cRegra1   := "Regra por Operação " + _cTipoOper
 EndIf
 
 //      SEGUNDA BUSCA
 //NOVA REGARA DE BUSCA DA OPERACO IANGULAR
 If _lRegraNova .And. _cTipoOper $ _cOperTriangular .And. Empty(_cTabDireta)
    If _cOperFat = _cTipoOper//05 - Faturamento
       _cCliAdqu  := _cCliente
       _cLojadqu  := _cLojacli
    EndIf//se For 42 - Remessa não precisa mudar o adquirente

    ZGQ->(DBSetOrder(4))//ZGQ_FILIAL+ZGQ_FILFAT+ZGQ_LOCEMB+ZGQ_CLIENT+ZGQ_LOJA
    ZGQ->(DBSeek(xFilial()+_cFilFatura+_cLocalEmb+_cCliAdqu+_cLojadqu))
     
    While .not. ZGQ->(Eof()) .And. xFilial("ZGQ")+_cFilFatura+_cLocalEmb+_cCliAdqu+_cLojadqu == ZGQ->(ZGQ_FILIAL+ZGQ_FILFAT+ZGQ_LOCEMB+ZGQ_CLIENT+ZGQ_LOJA)
       If ZGQ->ZGQ_ATIVA = "N"  
          ZGQ->(DBSkip())
          Loop
       ElseIf !Empty(ZGQ->ZGQ_SEGCLI+; // Seguimento do Cliente (A1_I_GRCLI)
                     ZGQ->ZGQ_REDE  +; // Rede do Cliente
                     ZGQ->ZGQ_GEREN +; // Gerente do vendedor (A3_GEREN)
                     ZGQ->ZGQ_UFPEDV+; // UF do Cliente -A1_EST
                     ZGQ->ZGQ_COORDE+; // Coordenador do vendedor (A3_SUPER)
                     ZGQ->ZGQ_SUPERV+; // Supervisor do vendedor  (A3_I_SUPE)
                     ZGQ->ZGQ_VENDED ) // Código do Vendedor Informado 
             ZGQ->(DBSkip())
             Loop
         ElseIf !(DA0->(DBSeek(xFilial("DA0")+ZGQ->ZGQ_TABPRE)))
             ZGQ->(DBSkip())
             Loop
         ElseIf DA0->DA0_ATIVO == '2' //Tabela inativa
             ZGQ->(DBSkip())
             Loop
         ElseIf DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < Date()
             ZGQ->(DBSkip())
             Loop
         EndIf
         
         _cRegra1   := "Regra por Adquirente da Operação Triangular " +_cCliAdqu + "-" + _cLojadqu + "("+_cFilFatura+_cLocalEmb+")"
         _cTabDireta:= ZGQ->ZGQ_TABPRE
         _nRecno    := ZGQ->(Recno())
         _cGrupoP   := ZGQ->ZGQ_GRUPOP
         _cUFPedV   := ZGQ->ZGQ_UFPEDV
                 
         Exit
    EndDo
 
    If Empty(_cTabDireta)
       //      //   1   2   3   4   5     6
       _aRet  := {"   ",0,"   ",0,"   ","   "}
       cfilant:= _cfilori
       Return _aRet
    EndIf
 EndIf

 //TERCEIRA BUSCA
 If Empty(_cTabDireta)
     _cTabDireta := Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLojaCli,"A1_TABELA")  
    If ZGQ->ZGQ_ATIVA = "N" .Or. !(DA0->(DBSeek(xFilial("DA0")+_cTabDireta))) .Or. DA0->DA0_ATIVO = '2' .Or. DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < Date()//Tabela inativa
       _cTabDireta:= ""
    Else
       _cRegra1   := "Regra por Cliente " +_cCliente + "-" + _cLojaCli
    EndIf
 EndIf 
  
 //NOVA REGRA DE BUSCA DO ZGQ
 If _lRegraNova .And. Empty(AllTrim(_cTabDireta)) //LOCALIZAR A TABELA DE PREÇO UTILIZANDO O CADASTRO DE REGRAS DE TABELA DE PREÇO
    //QUARTA BUSCA
    _cSegCli:=Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLojaCli,"A1_I_GRCLI")//SEGUIMENTO DO CLIENTE
    _cUF:=SA1->A1_EST//Estado DO CLIENTE

    _aCposBusca:={_cFilFatura,_cLocalEmb,_cCliente,_cLojaCli,_cSegCli,_cRede,_cGeren,_cUF,_cCoord,_cSuper,_cVend}

    _ctab:=BuscaTabPreco(_aCposBusca,@_cRegra, @_nRecno, @_cGrupoP, @_cUFPedV)//QUARTA BUSCA

    //REGRA ANTERIOR DE BUSCA DO ZGQ
 ElseIf ( ( SuperGetMV("IT_TABPRG",.T.,.F.)) .And. Empty(AllTrim(_cTabDireta)) )  // Carrega tabela de regras se o parametro de regras estiver ativo
    _aDadosZGQ := {}
    _cGrupoP := ""
    _cUFPedV := ""
 
     // Carrega array _aDadosZGQ com as regras de tabela de preços ativas.
     DA0->(DBSetOrder(1))
     ZGQ->(DBSetOrder(1))
     ZGQ->(DBGoTop())
     
     While .not. ZGQ->(Eof()) 
         //Valida validade da tabela da regra posicionada, se For inválida pula a análise
         
         _cfilda0 := IIf(Empty(ZGQ->ZGQ_FILFAT),ZGQ->ZGQ_FILEMB,ZGQ->ZGQ_FILFAT)
         If !(DA0->(DBSeek(xFilial("DA0")+ZGQ->ZGQ_TABPRE)))
             ZGQ->(DBSkip())
             Loop
         ElseIf DA0->DA0_ATIVO == '2' //Tabela inativa
             ZGQ->(DBSkip())
             Loop
         ElseIf DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < Date()
             ZGQ->(DBSkip())
             Loop
         EndIf
         
         If AllTrim(_cFilCarreg) == AllTrim(ZGQ->ZGQ_FILFAT)
           aAdd(_aDadosZGQ, {ZGQ->ZGQ_FILEMB,; // - Filial de Embarque     - 01
                             ZGQ->ZGQ_TABPRE,; // - Tabela de Preco        - 02
                             ZGQ->ZGQ_FILFAT,; // - Filial de Faturamento  - 03
                             ZGQ->ZGQ_GEREN ,; // - Gerente                - 04
                             ZGQ->ZGQ_COORDE,; // - Coordenador            - 05
                             ZGQ->ZGQ_SUPERV,; // - Supervisor             - 06
                             ZGQ->ZGQ_VENDED,; // - Vendedor               - 07
                             ZGQ->ZGQ_REDE  ,; // - Rede                   - 08
                             ZGQ->ZGQ_CLIENT,; // - Cliente                - 09
                             ZGQ->ZGQ_LOJA,;   // - Loja                   - 10
                             ZGQ->(Recno()),;  // - Recno do Registro      - 11
                             ZGQ->ZGQ_GRUPOP,; // - Grupo do Produto       - 12
                             ZGQ->ZGQ_UFPEDV}) // - UF do Pedido de Vendas - 13
         EndIf

         ZGQ->(DBSkip())
     EndDo
     
     _cRegra1 := ""
     _cRegra2 := ""
     _cRegra3 := ""
     _cRegra4 := ""
     _cRegra5 := ""
     _cRegra6 := ""
     _cRegra7 := ""
     
     _cTabPre1 := ""
     _cTabPre2 := ""
     _cTabPre3 := ""
     _cTabPre4 := ""
     _cTabPre5 := ""
     _cTabPre6 := ""
     _cTabPre7 := ""
     
     _cGrupoP1 := ""
     _cGrupoP2 := ""
     _cGrupoP3 := ""
     _cGrupoP4 := ""
     _cGrupoP5 := ""
     _cGrupoP6 := ""
     _cGrupoP7 := ""
     
     _cUFPedV1 := ""
     _cUFPedV2 := ""
     _cUFPedV3 := ""
     _cUFPedV4 := ""
     _cUFPedV5 := ""
     _cUFPedV6 := ""
     _cUFPedV7 := ""
     
     // Com base nos parÃ¢metros passados para a função ITTABPRC, determina a regras da tabela de
     // preço.
     // Neste trecho nãoo considera o grupo de produtos.
     For _nI := 1 To Len(_aDadosZGQ)
        // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura   // 1
        If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And.;// - Filial de Faturamento  - 3
             Empty(_aDadosZGQ[_nI,4]) .And. ;                                       // - Gerente                - 4
             Empty(_aDadosZGQ[_nI,5]) .And. ;                                       // - Coordenador            - 5
             Empty(_aDadosZGQ[_nI,6]) .And. ;                                       // - Supervisor             - 6
             Empty(_aDadosZGQ[_nI,7]) .And. ;                                       // - Vendedor               - 7
             Empty(_aDadosZGQ[_nI,8]) .And. ;                                       // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9]) .And. ;                                       // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                              // - Loja                   - 10
             
             _cRegra1  := "Regra de Filial de Faturamento " + _cFilFatura
             _cTabPre1 := _aDadosZGQ[_nI,2]                                         // - Tabela de PreÃ§o        - 2
             _nRecno1  := _aDadosZGQ[_nI,11]                                        // - Recno do Registro      - 11
             _cGrupoP1 := _aDadosZGQ[_nI,12]                                        // - Grupo de Produtos      - 12
             _cUFPedV1 := _aDadosZGQ[_nI,13]                                        // - UF do Pedido de Vendas - 13
             
        EndIf
         
         // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura + " e gerente " + _cGeren // 2
         If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And. ;  // - Filial de Faturamento  - 3
             (!Empty(_cGeren)         .And. _aDadosZGQ[_nI,4] == _cGeren)  .And. ;  // - Gerente                - 4
             Empty(_aDadosZGQ[_nI,5]) .And. ;                                       // - Coordenador            - 5
             Empty(_aDadosZGQ[_nI,6]) .And. ;                                       // - Supervisor             - 6
             Empty(_aDadosZGQ[_nI,7]) .And. ;                                       // - Vendedor               - 7
             Empty(_aDadosZGQ[_nI,8]) .And. ;                                       // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9]) .And. ;                                       // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                              // - Loja                   - 10
             
             _cRegra2  := "Regra de Filial de Faturamento " + _cFilFatura + " e gerente " + _cGeren // 2
             _cTabPre2 := _aDadosZGQ[_nI,2]                                         // - Tabela de PreÃ§o        - 2
             _nRecno2  := _aDadosZGQ[_nI,11]                                        // - Recno do Registro      - 11
             _cGrupoP2 := _aDadosZGQ[_nI,12]                                        // - Grupo de Produtos      - 12
             _cUFPedV2 := _aDadosZGQ[_nI,13]                                        // - UF do Pedido de Vendas - 13
         EndIf
         
         // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + " e coordenador " + _cCoord // 3
         If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And. ;  // - Filial de Faturamento  - 3
             (!Empty(_cGeren)         .And. _aDadosZGQ[_nI,4] == _cGeren)  .And. ;  // - Gerente                - 4
             (!Empty(_cCoord)         .And. _aDadosZGQ[_nI,5] == _cCoord)  .And. ;  // - Coordenador            - 5
             Empty(_aDadosZGQ[_nI,6]) .And. ;                                       // - Supervisor             - 6
             Empty(_aDadosZGQ[_nI,7]) .And. ;                                       // - Vendedor               - 7
             Empty(_aDadosZGQ[_nI,8]) .And. ;                                       // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9]) .And. ;                                       // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                              // - Loja                   - 10
             
             _cRegra3  := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + " e coordenador " + _cCoord // 3
             _cTabPre3 := _aDadosZGQ[_nI,2]                                         // - Tabela de PreÃ§o        - 2
             _nRecno3  := _aDadosZGQ[_nI,11]                                        // - Recno do Registro      - 11
             _cGrupoP3 := _aDadosZGQ[_nI,12]                                        // - Grupo de Produtos      - 12
             _cUFPedV3 := _aDadosZGQ[_nI,13]                                        // - UF do Pedido de Vendas - 13
         EndIf
         
         // _cRegra := "Regra de Filial de Filial de faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + " e supervisor " + ZGQ->ZGQ_SUPERV // 4
         If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And. ; // - Filial de Faturamento  - 3
             (!Empty(_cGeren)         .And. _aDadosZGQ[_nI,4] == _cGeren)  .And. ;    // - Gerente                - 4
             (!Empty(_cCoord)         .And. _aDadosZGQ[_nI,5] == _cCoord)  .And. ;    // - Coordenador            - 5
             (!Empty(_cSuper)         .And. _aDadosZGQ[_nI,6] == _cSuper)  .And. ;    // - Supervisor             - 6
             Empty(_aDadosZGQ[_nI,7])        .And. ;                                  // - Vendedor               - 7
             Empty(_aDadosZGQ[_nI,8])        .And. ;                                  // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9])        .And. ;                                  // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                                // - Loja                   - 10
             
             _cRegra4  := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + " e supervisor " + _cSuper
             _cTabPre4 := _aDadosZGQ[_nI,2]                                           // - Tabela de PreÃ§o        - 2
             _nRecno4  := _aDadosZGQ[_nI,11]                                          // - Recno do Registro      - 11
             _cGrupoP4 := _aDadosZGQ[_nI,12]                                          // - Grupo de Produtos      - 12
             _cUFPedV4 := _aDadosZGQ[_nI,13]                                          // - UF do Pedido de Vendas - 13
         EndIf
         
         // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " + ZGQ->ZGQ_SUPERV + " e vendedor " + _cVend //5
         If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And. ;       // - Filial de Faturamento  - 3
             (!Empty(_cGeren)         .And. _aDadosZGQ[_nI,4] == _cGeren)  .And. ;          // - Gerente                - 4
             (!Empty(_cCoord)         .And. _aDadosZGQ[_nI,5] == _cCoord)  .And. ;          // - Coordenador            - 5
             (_aDadosZGQ[_nI,6] == _cSuper)   .And. ;                                       // - Supervisor             - 6
             (!Empty(_cVend)                  .And. _aDadosZGQ[_nI,7] == _cVend)   .And. ;  // - Vendedor               - 7
             Empty(_aDadosZGQ[_nI,8])         .And. ;                                       // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9])         .And. ;                                       // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                                      // - Loja                   - 10
             
             _cRegra5  := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " +_cSuper + " e vendedor " + _cVend //5
             _cTabPre5 := _aDadosZGQ[_nI,2]                                                 // - Tabela de PreÃ§o        - 2
             _nRecno5  := _aDadosZGQ[_nI,11]                                                // - Recno do Registro      - 11
             _cGrupoP5 := _aDadosZGQ[_nI,12]                                                // - Grupo de Produtos      - 12
             _cUFPedV5 := _aDadosZGQ[_nI,13]                                                // - UF do Pedido de Vendas - 13
         EndIf
         
         // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " + _cSuper + ", vendedor " + _cVend + " e rede " + _cRede // 6
         If (!Empty(_cFilFatura)      .And. _aDadosZGQ[_nI,3] == _cFilFatura) .And. ;      // - Filial de Faturamento  - 3
             (!Empty(_cGeren)         .And. _aDadosZGQ[_nI,4] == _cGeren)  .And. ;         // - Gerente                - 4
             Empty(_aDadosZGQ[_nI,5]) .And. ;                                              // - Coordenador            - 5
             Empty(_aDadosZGQ[_nI,6]) .And. ;                                              // - Supervisor             - 6
             Empty(_aDadosZGQ[_nI,7]) .And. ;                                              // - Vendedor               - 7
             (!Empty(_cRede)          .And. _aDadosZGQ[_nI,8] == _cRede)   .And. ;         // - Rede                   - 8
             Empty(_aDadosZGQ[_nI,9]) .And. ;                                              // - Cliente                - 9
             Empty(_aDadosZGQ[_nI,10])                                                     // - Loja                   - 10
             
             _cRegra6  := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " + _cSuper + ", vendedor " + _cVend + " e rede " + _cRede // 6
             _cTabPre6 := _aDadosZGQ[_nI,2]                                                // - Tabela de PreÃ§o        - 2
             _nRecno6  := _aDadosZGQ[_nI,11]                                               // - Recno do Registro      - 11
             _cGrupoP6 := _aDadosZGQ[_nI,12]                                               // - Grupo de Produtos      - 12
             _cUFPedV6 := _aDadosZGQ[_nI,13]                                               // - UF do Pedido de Vendas - 13
         EndIf
 
         // _cRegra := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " + ZGQ->ZGQ_SUPERV + ", vendedor " + _cVend + ", rede " + ZGQ->ZGQ_REDE + " e cliente " + _cCliente + "/" + _cLojaCli // 7
         If (!Empty(_cFilFatura) .And. _aDadosZGQ[_nI,3] == _cFilFatura)  .And. ;            // - Filial de Faturamento  - 3
             (!Empty(_cGeren)    .And. _aDadosZGQ[_nI,4] == _cGeren)   .And. ;               // - Gerente                - 4
             (!Empty(_cCoord)    .And. _aDadosZGQ[_nI,5] == _cCoord)   .And. ;               // - Coordenador            - 5
             (_aDadosZGQ[_nI,6] == _cSuper)   .And. ;                                        // - Supervisor             - 6
             (!Empty(_cVend)                  .And. _aDadosZGQ[_nI,7] == _cVend)    .And. ;  // - Vendedor               - 7
             (!Empty(_cRede)                  .And. _aDadosZGQ[_nI,8] == _cRede)    .And. ;  // - Rede                   - 8
             (!Empty(_cCliente)               .And. _aDadosZGQ[_nI,9] == _cCliente) .And. ;  // - Cliente                - 9
             (!Empty(_cLojaCli)               .And. _aDadosZGQ[_nI,10] == _cLojaCli)         // - Loja                   - 10
             
             _cRegra7  := "Regra de Filial de Faturamento " + _cFilFatura + ", gerente " + _cGeren + ", coordenador " + _cCoord + ", supervisor " + _cSuper + ", vendedor " + _cVend + ", rede " + _cRede + " e cliente " + _cCliente + "/" + _cLojaCli // 7
             _cTabPre7 := _aDadosZGQ[_nI,2]                                                  // - Tabela de PreÃ§o        - 2
             _nRecno7  := _aDadosZGQ[_nI,11]                                                 // - Recno do Registro      - 11
             _cGrupoP7 := _aDadosZGQ[_nI,12]                                                 // - Grupo de Produtos      - 12
             _cUFPedV7 := _aDadosZGQ[_nI,13]                                                 // - UF do Pedido de Vendas - 13
         EndIf
     Next _nI
       
     If ! Empty(_cTabPre7)
         _ctab    := _cTabPre7
         _nRecno  := _nRecno7
         _cRegra  := "7-" + _cRegra7
         _cGrupoP := _cGrupoP7
         _cUFPedV := _cUFPedV7
     ElseIf ! Empty(_cTabPre6)
         _ctab    := _cTabPre6
         _nRecno  := _nRecno6
         _cRegra  := "6-" + _cRegra6
         _cGrupoP := _cGrupoP6
         _cUFPedV := _cUFPedV6
     ElseIf ! Empty(_cTabPre5)
         _ctab    := _cTabPre5
         _nRecno  := _nRecno5
         _cRegra  := "5-" + _cRegra5
         _cGrupoP := _cGrupoP5
         _cUFPedV := _cUFPedV5
     ElseIf ! Empty(_cTabPre4)
         _ctab    := _cTabPre4
         _nRecno  := _nRecno4
         _cRegra  := "4-" + _cRegra4
         _cGrupoP := _cGrupoP4
         _cUFPedV := _cUFPedV4
     ElseIf ! Empty(_cTabPre3)
         _ctab    := _cTabPre3
         _nRecno  := _nRecno3
         _cRegra  :="3-" +  _cRegra3
         _cGrupoP := _cGrupoP3
         _cUFPedV := _cUFPedV3
     ElseIf ! Empty(_cTabPre2)
         _ctab    := _cTabPre2
         _nRecno  := _nRecno2
         _cRegra  := "2-" + _cRegra2
         _cGrupoP := _cGrupoP2
         _cUFPedV := _cUFPedV2
     ElseIf ! Empty(_cTabPre1)
         _ctab    := _cTabPre1
         _nRecno  := _nRecno1
         _cRegra  := "1-" + _cRegra1
         _cGrupoP := _cGrupoP1
         _cUFPedV := _cUFPedV1
     EndIf
 Else
    _ctab  :=AllTrim(_cTabDireta)
    _cRegra:=AllTrim(_cRegra1)
 EndIf 
 
 End Sequence
 
 If _lRegraNova 
     _cRegraFatC:=""
    _nFatMinPrc := BuscaFatComercial(_cFilFatura, _cUFPedV, , _cGrupoP, @_cRegraFatC) // Carrega fator de conversão para calculo do maior preços de vendas.
 Else
    _nFatMinPrc := SuperGetMV("IT_FATMINP",.T.,1) // CARREGA FATOR DE CONVERSAO PARA CALCULO DO MAIOR PRECOS DE VENDAS.
 EndIf
 
 //     //   1       2        3         4           5          6
 _aRet := {_ctab, _nRecno, _cRegra, _nFatMinPrc, _cGrupoP, _cUFPedV}
 
 cfilant := _cfilori

Return _aRet

/*
===============================================================================================================================
Programa----------: BuscaTabPreco
Autor-------------: Alex Wallauer
Data da Criacao---: 07/01/2025
Descrição---------: Nova Busca de Tabela de preço
Parametros--------: _aCposBusca.: Array com os dados da busca: {_cFilFat,_cLocEmb,_cClient,_cLoja,_cSegCli,_cRede,_cGeren,_cUF,_cCoorde,_cSuperv,_cVended}
                    @_cRegra....: Grava a Regra usada
                    @_nRecno....: Grava o Recno usado
                    @_cGrupoP...: Grava o Grupo usado
                    @_cUFPedV...: Grava a UF usada
Retorno-----------: _cTabDireta.: Tabela de Preço
===============================================================================================================================
*/  
Static Function BuscaTabPreco(_aCposBusca As Array, _cRegra As Char, _nRecno  As Char, _cGrupoP As Char, _cUFPedV As Char)

 Local _aRegras   := {} As Array
 Local _aOrdBusca := {} As Array , A As Numeric
 Local _cB_Client := Space(Len(ZGQ->ZGQ_CLIENT )) As Char
 Local _cB_Loja   := Space(Len(ZGQ->ZGQ_LOJA   )) As Char
 Local _cB_SegCli := Space(Len(ZGQ->ZGQ_SEGCLI )) As Char
 Local _cB_Rede   := Space(Len(ZGQ->ZGQ_REDE   )) As Char
 Local _cB_Geren  := Space(Len(ZGQ->ZGQ_GEREN  )) As Char
 Local _cB_UF     := Space(Len(ZGQ->ZGQ_UFPEDV )) As Char
 Local _cB_Coorde := Space(Len(ZGQ->ZGQ_COORDE )) As Char
 Local _cB_Superv := Space(Len(ZGQ->ZGQ_SUPERV )) As Char
 Local _cB_Vended := Space(Len(ZGQ->ZGQ_VENDED )) As Char
 Local _cFilFat   := _aCposBusca[01]              As Char
 Local _cLocEmb   := _aCposBusca[02]              As Char
 Local _cClient   := _aCposBusca[03]              As Char
 Local _cLoja     := _aCposBusca[04]              As Char
 Local _cSegCli   := _aCposBusca[05]              As Char
 Local _cRede     := _aCposBusca[06]              As Char
 Local _cGeren    := _aCposBusca[07]              As Char
 Local _cUF       := _aCposBusca[08]              As Char
 Local _cCoorde   := _aCposBusca[09]              As Char
 Local _cSuperv   := _aCposBusca[10]              As Char
 Local _cVended   := _aCposBusca[11]              As Char
 Local _cTabDireta:= "   " As Char
 
 // 01 - Código do Cliente  + Código da Loja do Cliente 
 // INDICE:     ,ZGQ_CLIENT  +ZGQ_LOJA  +ZGQ_SEGCLI  +ZGQ_REDE  +ZGQ_GEREN  +ZGQ_UFPEDV  +ZGQ_COORDE +ZGQ_SUPERV  + ZGQ_VENDED
 aAdd(_aOrdBusca, _cClient   + _cLoja   + _cB_SegCli + _cB_Rede + _cB_Geren + _cB_UF +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 01
 aAdd(_aRegras, "Regra por Cliente + Loja: " + _cClient + " + " + _cLoja)
 
 // 02 - Código da Rede do Cliente (A1_GRPVEN) + Gerente do vendedor (A3_GEREN) + Estado do Cliente (A1_EST)
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cRede + _cGeren + _cUF   +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 02
 aAdd(_aRegras, "Regra por Gerente + Rede +  Estado: " +_cRede+" + " +_cGeren+" + "+ _cUF)
 
 // 03 - Código da Rede do Cliente (A1_GRPVEN) + Gerente do vendedor (A3_GEREN)
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cRede   + _cGeren   + _cB_UF +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 03
 aAdd(_aRegras, "Regra por Gerente + Rede: " + _cRede+" + " +_cGeren)
  
 // 04 - Estado do Cliente (A1_EST) 
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cB_Rede + _cB_Geren + _cUF   +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 04
 aAdd(_aRegras, "Regra por Estado do Cliente: " + _cUF)
 
 // 05 - Segmento do cliente (A1_I_GRCLI) + Estado do Cliente (A1_EST)
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cSegCli + _cB_Rede + _cB_Geren + _cUF   +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 05
 aAdd(_aRegras, "Regra por Segmento + Estado: " + _cSegCli+" + "+ _cUF)
 
 // 06 - Gerente do vendedor (A3_GEREN) + Coordenador do vendedor (A3_SUPER) + Supervisor do vendedor (A3_I_SUPE) 
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cSegCli + _cB_Rede + _cB_Geren   + _cB_UF +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 06
 aAdd(_aRegras, "Regra por Segmento: " + _cSegCli)
 
 // 07 - Gerente do vendedor (A3_GEREN) + Coordenador do vendedor (A3_SUPER) + Supervisor do vendedor (A3_I_SUPE) + Código do Vendedor 
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cB_Rede + _cGeren   + _cB_UF +_cCoorde + _cSuperv + _cVended)// REGRA 07
 aAdd(_aRegras, "Regra por Gerente + Coordenador + Supervisor + Vendedor: " + _cGeren+" + "  +_cCoorde+" + "   + _cSuperv+" + " + _cVended)
 
 // 08 - Gerente do vendedor (A3_GEREN) + Coordenador do vendedor (A3_SUPER) + Supervisor do vendedor (A3_I_SUPE) + Código do Vendedor 
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cB_Rede + _cGeren   + _cB_UF +_cCoorde + _cSuperv + _cB_Vended)// REGRA 08
 aAdd(_aRegras, "Regra por Gerente + Coordenador + Supervisor: " + _cGeren+" + "  +_cCoorde+" + "+ _cSuperv)
 
 // 09 - Gerente do vendedor (A3_GEREN) + Coordenador do vendedor (A3_SUPER) 
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cB_Rede + _cGeren   + _cB_UF +_cCoorde   + _cB_Superv + _cB_Vended )// REGRA 09
 aAdd(_aRegras, "Regra por Gerente + Coordenador: " + _cGeren+" + "  +_cCoorde)

 // 10 - Gerente do vendedor (A3_GEREN)
 aAdd(_aOrdBusca, _cB_Client + _cB_Loja + _cB_SegCli + _cB_Rede + _cGeren + _cB_UF +_cB_Coorde + _cB_Superv + _cB_Vended )// REGRA 10
 aAdd(_aRegras,	"Regra por Gerente do Vendedor " + _cGeren)
 
 ZGQ->(DBSetOrder(4))//ZGQ_FILIAL+ZGQ_FILFAT+ZGQ_LOCEMB+ZGQ_CLIENT+ZGQ_LOJA+ZGQ_SEGCLI+ZGQ_REDE+ZGQ_GEREN+ZGQ_UFPEDV+ZGQ_COORDE+ZGQ_SUPERV+ZGQ_VENDED
 For A := 1 To Len(_aOrdBusca)
      ZGQ->(DBSeek(xFilial()+_cFilFat+_cLocEmb+_aOrdBusca[A]))
      
      While .not. ZGQ->(Eof()) .And. xFilial("ZGQ")+_cFilFat+_cLocEmb == ZGQ->(ZGQ_FILIAL+ZGQ_FILFAT+ZGQ_LOCEMB);
                                 .And. _aOrdBusca[A] == ZGQ->(ZGQ_CLIENT+ZGQ_LOJA+ZGQ_SEGCLI+ZGQ_REDE+ZGQ_GEREN+ZGQ_UFPEDV+ZGQ_COORDE+ZGQ_SUPERV+ZGQ_VENDED)
         If ZGQ->ZGQ_ATIVA = "N"  //Tabela inativa
              ZGQ->(DBSkip())
              Loop
          ElseIf !(DA0->(DBSeek(xFilial("DA0")+ZGQ->ZGQ_TABPRE)))
              ZGQ->(DBSkip())
              Loop
          ElseIf DA0->DA0_ATIVO = '2' //Tabela inativa
              ZGQ->(DBSkip())
              Loop
          ElseIf DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < Date()
              ZGQ->(DBSkip())
              Loop
          EndIf
          
          _cRegra    := _aRegras[A]+ " ("+_cFilFat+_cLocEmb+")" 
          _cTabDireta:= ZGQ->ZGQ_TABPRE
          _nRecno    := ZGQ->(Recno())
          _cGrupoP   := ZGQ->ZGQ_GRUPOP
          _cUFPedV   := ZGQ->ZGQ_UFPEDV
          Exit
      EndDo
 Next A
 
 ZGQ->(DBSetOrder(1))

Return _cTabDireta

/*
================================================================================================================================
Programa--------: IvldDA1
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 05/07/2016
Descrição-------: Função para validação dos itens da tabela de preço
Parametros------: Nenhum
Retorno---------: _lRet - .T. deixa completar a alteração, .F. caso contrário.
===============================================================================================================================
*/
User Function IvldDA1()

Local _aArea		:= FWGetArea()
Local _lRet			:= .T.
Local _cQuery		:= ""
Local _cQryDA1		:= ""
Local _cQryPRO		:= ""
Local _nTotReg		:= Len(aCols)
Local _oModel		:= FWModelActive()
Local _oModelDA0	:= _oModel:GetModel( 'DA0MASTER' )
Local _nPosTab		:= aScan(_oModelDA0:ADATAMODEL[1], {|x| AllTrim(x[1]) == "DA0_CODTAB"})
Local _nPosIte		:= aScan(aHeader, {|x| AllTrim(x[2]) == "DA1_ITEM"})
Local _nPosPro		:= aScan(aHeader, {|x| AllTrim(x[2]) == "DA1_CODPRO"})

// Verifica se a tabela está com filtro aplicado
_cQuery := "SELECT COUNT(*) DA1_TOTREG "
_cQuery += "FROM " + RetSqlName("DA1") + " "
_cQuery += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
_cQuery += "  AND DA1_CODTAB = '" + _oModelDA0:ADATAMODEL[1][_nPosTab][2] + "' "
_cQuery += "  AND D_E_L_E_T_ = ' ' "

MPSysOpenQuery(_cQuery,"TRBDA1")
TRBDA1->(DBGoTop())

If _nTotReg < TRBDA1->DA1_TOTREG
    Help( ,, 'Atenção! XFUNOMS - IvldDA1',, "Não é permitida alteração na tabela de preço filtrada.",1,0,, ,,, , {"Favor tirar o filtro da tabela"} )
    _lRet := .F.
Else
    // verifica se o item existe na tabela de preço
    _cQryDA1 := "SELECT COUNT(DA1_CODTAB) DA1_TOTTAB "
    _cQryDA1 += "FROM " + RetSqlName("DA1") + " "
    _cQryDA1 += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
    _cQryDA1 += "  AND DA1_CODTAB = '" + _oModelDA0:ADATAMODEL[1][_nPosTab][2] + "' "
    _cQryDA1 += "  AND DA1_ITEM = '" + aCols[n][_nPosIte] + "' "
    _cQryDA1 += "  AND D_E_L_E_T_ = ' ' "

    MPSysOpenQuery(_cQryDA1,"TRBDAA")
    TRBDAA->(DBGoTop())

    If TRBDAA->DA1_TOTTAB > 0
        Help( ,, 'Atenção! XFUNOMS - IvldDA1',, "Não é permitida alteração do item.",1,0,, ,,, , {"Favor inclua um item novo."} )
        _lRet := .F.
    Else
        // Verifica se o produto existe na tabela de preço
        _cQryPRO := "SELECT COUNT(DA1_CODPRO) DA1_TOTPRO "
        _cQryPRO += "FROM " + RetSqlName("DA1") + " "
        _cQryPRO += "WHERE DA1_FILIAL = '" + xFilial("DA1") + "' "
        _cQryPRO += "  AND DA1_CODTAB = '" + _oModelDA0:ADATAMODEL[1][_nPosTab][2] + "' "
        _cQryPRO += "  AND DA1_CODPRO = '" + aCols[n][_nPosPro] + "' "
        _cQryPRO += "  AND D_E_L_E_T_ = ' ' "

        MPSysOpenQuery(_cQryPRO,"TRBPRO")
        TRBPRO->(DBGoTop())

        If TRBPRO->DA1_TOTPRO > 0
            Help( ,, 'Atenção! XFUNOMS - IvldDA1',, "O produto informado já existe nesta tabela de preço.",1,0,, ,,, , {"Favor inclua um item novo."} )
            _lRet := .F.
        EndIf
        TRBPRO->(DBCloseArea())
    EndIf
    TRBDAA->(DBCloseArea())
EndIf

TRBDA1->(DBCloseArea())
FWRestArea(_aArea)

Return(_lRet)

/*
================================================================================================================================
Programa--------: Nfoplog
Autor-----------: Josué Danich Prestes
Data da Criacao-: 24/04/2018
Descrição-------: Detecta se nota vai por operador logistico e operador de redespacho.
Parametros------: _cfilial - filial da nota
                  _cnota - numero da nota
                  _serie - serie da nota
Retorno---------: _lRet - se a nota vai por operador logistico ou não
===============================================================================================================================
*/
User Function Nfoplog(_cfilial,_cnota,_cserie)

Local _lRet := .F.

DAI->(DBSetOrder(3))

If DAI->(DBSeek(_cfilial+_cnota+_cserie))
    If DAI->DAI_I_OPER == '1' .Or. DAI->DAI_I_REDP == '1' // Considerar operador logistico e operador de redespacho.
       _lRet := .T.
       If !Empty(DAI->DAI_I_OPLO)
          _cCodOL :=DAI->DAI_I_OPLO
          _cLojaOP:=DAI->DAI_I_LOPL
       Else
          _cCodOL :=DAI->DAI_I_TRED
          _cLojaOP:=DAI->DAI_I_LTRE
       EndIf
    EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: TelCred
Autor-------------: Josué Danich
Data da Criacao---: 13/08/2018
Descrição---------: Tela de análise de crédito do prospect
Parametros--------: _nmodo - 1 Chamado da tela de prospect
                             2 Chamado de telas com cliente já cadastrado
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function TelCred(_nmodo)

Local oFecha
Local oFolder1
Local oGet1
Local oGet10
Local oGet11
Local oGet12
Local oGet13
Local oGet14
Local oGet15
Local oGet16
Local oGet17
Local oGet18
Local oGet2
Local oGet3
Local oGet4
Local oGet5
Local oGet6
Local oGet7
Local oGet8
Local oGet9
Local oGroup1
Local oGroup2
Local oGroup3
Local oGroup4
Local oGroup6
Local oSay1
Local oSay10
Local oSay11
Local oSay12
Local oSay13
Local oSay14
Local oSay15
Local oSay16
Local oSay17
Local oSay18
Local oSay2
Local oSay21
Local oSay22
Local oSay24
Local oSay25
Local oSay26
Local oSay27
Local oSay28
Local oSay3
Local oSay4
Local oSay44
Local oSay5
Local oSay6
Local oSay7
Local oSay8
Local oSay9
Local oWBrowse1
Local oWBrowse2
Local oWBrowse3

Private aWBrowse1 := {}
Private aWBrowse2 := {}
Private aWBrowse3 := {}
Private _ccnpj := ""
Private _cnome := ""
Private _crazao := ""
Private _cdata := ""
Private _cender := ""
Private _cbairro := ""
Private _ccidade := ""
Private _ctelefone := ""
Private _cdata2 := ""
Private _cassoc := ""
Private _cObs := ""
Private _ccnae := ""
Private _csitrec := ""
Private _cdtrec := ""
Private _cdtcrec := ""
Private _cinsc := ""
Private _csitst := ""
Private _cdtst := ""
Private _cdtcst := ""
Private _csimples := ""
Private _cdtsimp := ""
Private _cdtcsimp :=  ""
Private 	_ccheques
Private _cprotes
Private _cdcheques:= ""
Private cdebatu
Private cvenc5
Private cvenc15
Private cvenc30
Private ctotlim
Private cmaior
Private cVendas
Private _cUfCli
Private _llret

Static oDlg

If _nmodo == 1  //Chamado da tela de prospect
    _crazao  := SZX->ZX_NOME     //_cnome := SZX->ZX_NOME  
    _cnome   := SZX->ZX_NREDUZ 
    _ccnpj   := SZX->ZX_CGC
    _cpessoa := SZX->ZX_PESSOA
    _cinscr  := SZX->ZX_INSCR
    _cUfCli  := SZX->ZX_EST
Else//Chamado de telas com cadastro de cliente já efetuado
    _crazao  := SA1->A1_NOME     //_cnome := SA1->A1_NOME 
    _cnome   := SA1->A1_NREDUZ 
    _ccnpj   := SA1->A1_CGC
    _cpessoa := SA1->A1_PESSOA
    _cinscr  := SA1->A1_INSCR
    _cUfCli  := SA1->A1_EST
EndIf

//Faz consulta na Cisp
FWMsgRun(,{|| _llret := u_ConCisp(_cnome,_ccnpj,_cpessoa,_cinscr, _cUfCli)},"Aguarde...","Consultando Cisp...")

//Apresenta resultado
If _llret

    DEFINE MSDIALOG oDlg TITLE "Análise de Crédito - " + AllTrim(_cnome)  FROM 000, 000  To 500, 1000 COLORS 0, 16777215 PIXEL

    @ 008, 007 FOLDER oFolder1 SIZE 483, 196 OF oDlg ITEMS "Resumo","Ratings","Positivas","Restrições" COLORS 0, 16777215 PIXEL

    //Folder Resumo
    @ 002, 004 GROUP oGroup1 To 169, 286 OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
    @ 011, 006 Say oSay1 PROMPT "CNPJ" SIZE 065, 006 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 024, 006 Say oSay2 PROMPT "Razão social" SIZE 065, 009 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 036, 006 Say oSay44 PROMPT "Nome Fantasia" SIZE 059, 012 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 049, 006 Say oSay5 PROMPT "Data Fundação" SIZE 101, 017 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 061, 006 Say oSay6 PROMPT "Endereço" SIZE 089, 014 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 074, 006 Say oSay7 PROMPT "Bairro" SIZE 101, 015 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 086, 006 Say oSay8 PROMPT "Cidade" SIZE 115, 017 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 099, 006 Say oSay11 PROMPT "Telefone" SIZE 129, 017 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 111, 006 Say oSay12 PROMPT "Data Cadastramento" SIZE 130, 013 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 124, 006 Say oSay13 PROMPT "Ass Cadastrante" SIZE 132, 015 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 136, 006 Say oSay14 PROMPT "Observações" SIZE 126, 014 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 001, 291 GROUP oGroup2 To 066, 470 PROMPT "Receita Federal  " OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
    @ 070, 291 GROUP oGroup3 To 126, 470 PROMPT "Sintegra   " OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
    @ 134, 291 GROUP oGroup4 To 170, 470 PROMPT "Simples Nacional   " OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
    @ 011, 077 MSGET oGet1 VAR _ccnpj WHEN .F. SIZE 060, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 024, 077 MSGET oGet2 VAR _crazao WHEN .F. SIZE 150, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 036, 077 MSGET oGet3 VAR _cnome WHEN .F. SIZE 150, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 049, 077 MSGET oGet4 VAR _cdata WHEN .F. SIZE 060, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 061, 077 MSGET oGet5 VAR _cender WHEN .F. SIZE 150, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 074, 077 MSGET oGet6 VAR _cbairro WHEN .F. SIZE 150, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 086, 077 MSGET oGet7 VAR _ccidade WHEN .F. SIZE 150, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 099, 077 MSGET oGet8 VAR _ctelefone WHEN .F. SIZE 060, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 111, 077 MSGET oGet9 VAR _cdata2 WHEN .F. SIZE 060, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 124, 077 MSGET oGet10 VAR _cassoc WHEN .F. SIZE 060, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 136, 077 MSGET oGet11 VAR _cObs WHEN .F. SIZE 200, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL

    @ 146, 296 Say oSay3 PROMPT _csimples SIZE 166, 009 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 157, 296 Say oSay4 PROMPT IIf(Empty(_cdtsimp)," ","DATA SIMPLES: ") + _cdtsimp +  " - DATA CONS. " + _cdtcsimp SIZE 167, 009 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 085, 296 Say oSay9 PROMPT "INSC ESTADUAL " + _cinsc  SIZE 168, 008 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 098, 296 Say oSay10 PROMPT _csitst + "  - DATA " +  _cdtst SIZE 140, 009 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 111, 296 Say oSay15 PROMPT "CONSULTA EM " + _cdtcst SIZE 097, 008 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 032, 296 Say oSay16 PROMPT _csitrec + " - DATA " + _cdtrec SIZE 164, 009 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 048, 296 Say oSay17 PROMPT "CONSULTA EM " + _cdtcrec SIZE 076, 008 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL
    @ 016, 296 Say oSay18 PROMPT "CNAE " + _ccnae SIZE 112, 010 OF oFolder1:aDialogs[1] COLORS 0, 16777215 PIXEL

    //Folder Ratings

    oazul  	:= LoadBitmap(GetResources(),'br_azul')
    overde 	:= LoadBitmap(GetResources(),'br_verde')
    overme 	:= LoadBitmap(GetResources(),'br_vermelho')
    oamare 	:= LoadBitmap(GetResources(),'br_amarelo')

    oWBrowse1 := TCBrowse():New(014 , 008,452, 146,,,,oFolder1:aDialogs[2],,,,,{||},,,,,,,.F.,,.T.,,.F.,,.T.,.T.)

    oWBrowse1:SetArray(aWBrowse1)

    oWBrowse1:AddColumn(TCColumn():New("",{|| IIf(aWBrowse1[oWBrowse1:nAt,1]=="A",oazul,;
        IIf(aWBrowse1[oWBrowse1:nAt,1]=="B",overde,;
        IIf(aWBrowse1[oWBrowse1:nAt,1]=="C",oamare,overme))) }          ,,,,"CENTER",    ,.T.,.F.,,,,.F.,))

    oWBrowse1:AddColumn(TCColumn():New("Mês/Ano"    			, {|| aWBrowse1[oWBrowse1:nAt,2]},,,,"CENTER", 60 ,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Classificação"   	, {|| aWBrowse1[oWBrowse1:nAt,3]},,,,"CENTER", 60 ,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Pontualidade"    	, {|| aWBrowse1[oWBrowse1:nAt,4]},,,,"CENTER", 60 ,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Relacionamento"  	, {|| aWBrowse1[oWBrowse1:nAt,5]},,,,"CENTER", 60,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Restritivas"     	, {|| aWBrowse1[oWBrowse1:nAt,6]},,,,"CENTER", 60,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Crédito na Praça"    , {|| aWBrowse1[oWBrowse1:nAt,7]},,,,"CENTER", 60,.F.,.F.,,,,.F., ) )
    oWBrowse1:AddColumn(TCColumn():New("Densidade Comercial" , {|| aWBrowse1[oWBrowse1:nAt,8]},,,,"CENTER", 60,.F.,.F.,,,,.F., ) )

    // Folder Positivas
    @ 006, 005 LISTBOX oWBrowse2 Fields HEADER "Segmento","Data Info","Associada","Fone","Cliente desde","Ult Compra","Dt Maior Ac.","Maior Acumulo","Debito Atual","Vencido 5+","Vencido 15+","Vencido 30+","Prazo médio","Media Atrasos","Media Vencidos","Limite Crédito","Tp limite Crédito" SIZE 454, 160 OF oFolder1:aDialogs[3] PIXEL ColSizes 50,50
    oWBrowse2:SetArray(aWBrowse2)
    oWBrowse2:bLine := {|| {;
        aWBrowse2[oWBrowse2:nAt,1],;
        aWBrowse2[oWBrowse2:nAt,2],;
        aWBrowse2[oWBrowse2:nAt,3],;
        aWBrowse2[oWBrowse2:nAt,4],;
        aWBrowse2[oWBrowse2:nAt,5],;
        aWBrowse2[oWBrowse2:nAt,6],;
        aWBrowse2[oWBrowse2:nAt,7],;
        aWBrowse2[oWBrowse2:nAt,8],;
        aWBrowse2[oWBrowse2:nAt,9],;
        aWBrowse2[oWBrowse2:nAt,10],;
        aWBrowse2[oWBrowse2:nAt,11],;
        aWBrowse2[oWBrowse2:nAt,12],;
        aWBrowse2[oWBrowse2:nAt,13],;
        aWBrowse2[oWBrowse2:nAt,14],;
        aWBrowse2[oWBrowse2:nAt,15],;
        aWBrowse2[oWBrowse2:nAt,16],;
        aWBrowse2[oWBrowse2:nAt,17];
        }}


    //Folder Restrições
    @ 009, 008 LISTBOX oWBrowse3 Fields HEADER "Associada","Data","1a Restricao","2a Restricao" SIZE 327, 164 OF oFolder1:aDialogs[4] PIXEL ColSizes 50,50
    oWBrowse3:SetArray(aWBrowse3)
    oWBrowse3:bLine := {|| {;
        aWBrowse3[oWBrowse3:nAt,1],;
        aWBrowse3[oWBrowse3:nAt,2],;
        aWBrowse3[oWBrowse3:nAt,3],;
        aWBrowse3[oWBrowse3:nAt,4];
        }}

    @ 009, 345 GROUP oGroup6 To 175, 474 PROMPT "Resumo Financeiro " OF oFolder1:aDialogs[4] COLOR 0, 16777215 PIXEL

    @ 029, 350 Say oSay21 PROMPT "Débito Atual" SIZE 034, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 039, 350 Say oSay22 PROMPT "Vencido 5+" SIZE 035, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 054, 350 Say oSay24 PROMPT "Vencido 15+" SIZE 035, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 066, 350 Say oSay25 PROMPT "Vencido 30+" SIZE 035, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 077, 350 Say oSay26 PROMPT "Total Limite Crédito" SIZE 035, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 090, 350 Say oSay27 PROMPT "Maior acumulo" SIZE 040, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 102, 350 Say oSay28 PROMPT "Vendas ult 24 meses" SIZE 035, 007 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 025, 393 MSGET oGet12 VAR cdebatu WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 038, 393 MSGET oGet13 VAR cvenc5 WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 050, 393 MSGET oGet14 VAR cvenc15 WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 062, 393 MSGET oGet15 VAR cvenc30 WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 075, 393 MSGET oGet16 VAR ctotlim WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 086, 393 MSGET oGet17 VAR cmaior WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL
    @ 098, 393 MSGET oGet18 VAR cVendas WHEN .F. SIZE 052, 010 OF oFolder1:aDialogs[4] COLORS 0, 16777215 PIXEL

    @ 220, 427 BUTTON oFecha PROMPT "Fechar" SIZE 053, 014 OF oDlg ACTION (oDlg:End()) PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

EndIf

Return

/*
===============================================================================================================================
Programa----------: ConCisp
Autor-------------: Josué Danich
Data da Criacao---: 13/08/2018
Descrição---------: Consulta analitca Cisp
Parametros--------: _cnome - razão social do cliente
                    _ccnpj - cnpj do cliente
                    _cpessoa - tipo de pessoa juridica/fisica do cliente
                    _cinscr - inscrição estadual do cliente
                    _cUfCli - Estado do Cliente
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ConCisp(_cnome,_ccnpj,_cpessoa,_cinscr,_cUfCli)

Local cUrlcisp    := "https://servicos.cisp.com.br/v1/avaliacao-analitica/raiz/" + SubStr(AllTrim(_ccnpj),1,8)
Local aHeadOut        := {}
Local cHdcisp     := ""
Local cCorcisp    := ""
Local _ocisp
Local _osprotesto
Local _acisp      := {}
Local _lRet           := .T.
Local _cpasswd        := SuperGetMV("IT_PWCISP",.T.,"!t@lac95_01#")
Local _cuser		  := SuperGetMV("IT_USCISP",.T.,"ws09501")
Local _nnj				:= 0
Local _nnk				:= 0
Local _nni				:= 0
Local _lLinkPrd      := SuperGetMV("IT_LKCISPP",.T.,.T.) 

//Só atualiza pessoas juridicas
If (_cpessoa == "F")
    If Type("_NATUA") == "U"
        _natua := 2
    EndIf 
    If _natua == 2
        U_ITMsg("Não atualiza pessoa física via Cisp","Atenção",,1)
    EndIf
    Return
EndIf

//Define usuário e password
aAdd( aHeadOut , "Authorization: Basic "+Encode64(_cuser + ":" + _cpasswd ) )

//Faz chamada ao webservice do cisp
CHdcisp  := ""
cCorcisp := HttpGet(cUrlcisp,"",NIL,aHeadOut,@cHdcisp)
_ocisp   := nil
_acisp := StrTokArr(cHdcisp,chr(10))

//Verifica e formata resposta do cisp
If SubStr(cHdcisp,1,15) == "HTTP/1.1 200 OK" .And. FWJsonDeserialize(cCorcisp,@_ocisp)
    _ccnpj :=  _ccnpj
    _crazao := _ocisp:cliente:razaosocial
    _cnome := _ocisp:cliente:nomefantasia
    _cdata := _ocisp:cliente:datafundacao
    _cdata := If(Type("_cdata")="C",SubStr(_cdata,9,2)+"/"+SubStr(_cdata,6,2)+"/"+SubStr(_cdata,1,4)," ")
    _cender := _ocisp:cliente:endereco
    _cbairro := _ocisp:cliente:bairro
    _ccidade := _ocisp:cliente:cidade + " - " + _ocisp:cliente:uf
    _ctelefone := _ocisp:cliente:telefone
    _cdata2 := _ocisp:cliente:datacadastramento
    _cdata2 := If(Type("_cdata2")="C",SubStr(_cdata2,9,2)+"/"+SubStr(_cdata2,6,2)+"/"+SubStr(_cdata2,1,4)," ")
    _cassoc := _ocisp:cliente:associadacadastrante
    _cObs   := If(AttIsMemberOf(_ocisp:cliente, "observacoes"),_ocisp:cliente:observacoes,"")

    If "cnae" $ cCorcisp  //Teste para ver se veio informações da receita
        If AttIsMemberOf(_ocisp, "receitaFederal") .And. ValType(_ocisp:RECEITAFEDERAL) == "O"  .And. AttIsMemberOf(_ocisp:receitaFederal, "cnae")
            _ccnae := _ocisp:receitaFederal:cnae
            _csitrec := _ocisp:receitaFederal:situacaoCadastral
            _cdtrec := _ocisp:receitaFederal:dataSituacaoCadastral
            _cdtrec := IIf(Type("_cdtrec")="C",SubStr(_cdtrec,9,2)+"/"+SubStr(_cdtrec,6,2)+"/"+SubStr(_cdtrec,1,4)," ")
            _cdtcrec := _ocisp:receitaFederal:dataConsulta
            _cdtcrec := IIf(Type("_cdtcrec")="C",SubStr(_cdtcrec,9,2)+"/"+SubStr(_cdtcrec,6,2)+"/"+SubStr(_cdtcrec,1,4)," ")
        Else
            _ccnae := "N/C"
            _csitrec := "N/C"
            _cdtrec := "N/C"
            _cdtrec := "N/C"
            _cdtcrec := "N/C"
            _cdtcrec := "N/C"
        EndIf
    EndIf

    _lAchou := .F.
    _npos := 0

    For _nnj := 1 To Len(_ocisp:sintegras)
        If AllTrim(_ocisp:sintegras[_nnj]:inscricaoEstadual) == AllTrim(_cinscr)
            _lAchou := .T.
            _npos := _nnj
        EndIf
    Next _nnj

    If _npos > 0
        _cinsc := _ocisp:sintegras[1]:inscricaoEstadual + " - " + _ocisp:sintegras[1]:uf
        _csitst := _ocisp:sintegras[1]:situacaoCadastral
        _cdtst := _ocisp:sintegras[1]:dataSituacaoCadastral
        _cdtst := IIf(Type("_cdtst")="C",SubStr(_cdtst,9,2)+"/"+SubStr(_cdtst,6,2)+"/"+SubStr(_cdtst,1,4)," ")
        _cdtcst := _ocisp:sintegras[1]:dataConsulta
        _cdtcst := IIf(Type("_cdtcst")="C",SubStr(_cdtcst,9,2)+"/"+SubStr(_cdtcst,6,2)+"/"+SubStr(_cdtcst,1,4)," ")
    Else
        _cinsc := "N/C"
        _csitst := "N/C"
        _cdtst := "N/C"
        _cdtst := "N/C"
        _cdtcst := "N/C"
        _cdtcst := "N/C"

        //Faz consulta especifica de sintegra com o cnpj completo
        cHDSintegrae  := ""

        If _lLinkPrd
            cUrlsintegrae := "https://api.maxxi.cisp.com.br/Public-bases/v1/sintegra/cnpj/"+ AllTrim(_ccnpj)+"/uf/"+AllTrim(_cUfCli)+"?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw" //"https://servicos.cisp.com.br/v1/sintegra/" + AllTrim(M->ZX_CGC)  
        Else
            cUrlsintegrae := "https://api-homol.maxxi.cisp.com.br/Public-bases/v1/sintegra/cnpj/"+ AllTrim(_ccnpj)+"/uf/"+AllTrim(_cUfCli)+"?key=43c629ff-e72e-4172-a0fe-ffdef386573a" //"https://servicos.cisp.com.br/v1/sintegra/" + AllTrim(M->ZX_CGC)
        EndIf 
            
        aHeadOut := {} 
        aAdd( aHeadOut , "accept:application/json")

        //Faz chamada ao webservice do Sintegra
        cCorSintegrae := HttpGet(cUrlsintegrae,"",NIL,aHeadOut,@cHdSintegrae)
        _osintegrae   := ""

        cCorSintegrae := DecodeUTF8(cCorSintegrae, "cp1252")  
        _oJson := JsonObject():new()
        _cRet := _oJson:FromJson(cCorSintegrae)

        If (SubStr(cHdSintegrae,1,12) == "HTTP/1.1 200" .And. ValType(_cRet) == "U") //.and. FWJsonDeserialize(cCorSintegrae,@_osintegrae) .And. Len(_osintegrae) > 0)
            _aNames := _oJson:GetNames()
            _osintegra := _oJson:GetJsonObject("company")
            If ValType(_osintegra) == "A" .Or. ValType(_osintegra) == "J" 
                _osintegra := _osintegra[1]
            EndIf 

            _nI := aScan(_aNames, "updateDate" )
            If _nI > 0
                _cDtAlter := _oJson[_aNames[_nI]]
            EndIf 

            _oDoctos := _osintegra:GetJsonObject("documents")  // _oJson:GetJsonObject("document")
            _oDoctos := _oDoctos[1]

            _aNameDocs := _oDoctos:GetNames()

            _nI := aScan(_aNameDocs ,"Type" )
            _cTipoDocs := ""

            If _nI > 0
                _cTipoDocs := _oDoctos[_aNameDocs[_nI]]	  
            EndIf 

            _nI := aScan(_aNameDocs ,"value" )
            _cNrDocs := ""

            If _nI > 0
                _cNrDocs := _oDoctos[_aNameDocs[_nI]]	
                _cNrDocs := StrTran(_cNrDocs,".","")  
            EndIf 

            _oRegSit := _osintegra:GetJsonObject("register")
            _aNameReg  := _oRegSit:GetNames()

            _nI := aScan(_aNameReg, "status" )

            If _nI > 0
                _cSituacRg := _oRegSit[_aNameReg[_nI]]
            EndIf  

            _cDtAltRec := ""

            _nI := aScan(_aNameReg, "date" )
            If _nI > 0
                _cDtAltRec := _oRegSit[_aNameReg[_nI]]
                If !Empty(_cDtAltRec)
                    _cDtAltRec := StrTran(_cDtAltRec,"-","")
                Else
                    _cDtAltRec := "       " 
                EndIf 
            EndIf 
               _cinsc  := If(Empty(_cNrDocs),"ISENTO",_cNrDocs)
               _csitst := Upper(_cSituacRg)
               _cdtst  := DToC(SToD(_cDtAltRec))
               _cdtcst := DToC(Date())
        Else
            _cinsc := "N/C"
            _csitst := "N/C"
            _cdtst := "N/C"
            _cdtcst := "N/C"
        EndIf
    EndIf

    If _cinsc == "N/C"

        _cender := "N/C - Falhou consulta sintegra na Cisp"
        _cbairro := "N/C"
        _ccidade := "N/C"
        _ctelefone := "N/C"

    EndIf

    If "descricaoOptante" $ cCorcisp  //Teste para ver se veio informações de Simples
        _csimples := _ocisp:simplesNacional:descricaoOptante
        _cdtsimp  := _ocisp:simplesNacional:dataSimples
        _cdtsimp  := IIf(Type("_cdtsimp")="C",SubStr(_cdtsimp,9,2)+"/"+SubStr(_cdtsimp,6,2)+"/"+SubStr(_cdtsimp,1,4)," ")
        _cdtcsimp :=  _ocisp:simplesNacional:dataConsulta
        _cdtcsimp := IIf(Type("_cdtcsimp")="C",SubStr(_cdtcsimp,9,2)+"/"+SubStr(_cdtcsimp,6,2)+"/"+SubStr(_cdtcsimp,1,4)," ")
    Else
        _csimples := "N/C"
        _cdtsimp := "N/C"
        _cdtsimp := "N/C"
        _cdtcsimp :=  "N/C"
        _cdtcsimp := "N/C"
    EndIf

    For _nnj := 1 To Len(_ocisp:ratings)

        aAdd(aWBrowse1,{_ocisp:ratings[_nnj]:classificacao,;															//01 Status
        _ocisp:ratings[_nnj]:data,;																//02 Mes ano
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:descricaoClassificacao,11,20)),; 											//03 Classificacao
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:quesitos:descricaoNotaPontualidadeNivelAtraso,11,20)),;  					//04 "Pontualidade"
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:quesitos:descricaoNotaRelacionamentoMercado,11,20)),;  					//05 "Relacionamento"
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:quesitos:descricaoNotaOcorrenciasRestritivas,11,20)),;  					//06 "Restritivas"
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:quesitos:descricaoNotaCreditoPraca,11,20)),;  								//07 "Crédito na Praça"
        decodeutf8(SubStr(_ocisp:ratings[_nnj]:quesitos:descricaoNotaDensidadeComercial,11,20))})  						//08 "Densidade Comercial"

    Next _nnj

    If Len(aWBrowse1) == 0
        aAdd(aWBrowse1,{"1","N/C","N/C","N/C","N/C","N/C","N/C","N/C"})
    EndIf

    For _nnk := 1 To Len(_ocisp:positivaSegmentos)
        _csegmento := AllTrim(_ocisp:positivaSegmentos[_nnk]:descricaoSegmento)
        For _nnj := 1 To Len(_ocisp:positivaSegmentos[_nnk]:positivas)
            aAdd(aWBrowse2,{decodeutf8(_csegmento),;//01 "Segmento"
            _ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:dataInformacao,;//02 "Data Info"
            decodeutf8(_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:razaoSocial),;//03 "Associada",;
                SubStr(_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:fone,7,50),;//04 "Fone",;
                _ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:dataClienteDesde,;//05"Cliente desde",;
                _ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:dataUltimaCompra,;//06"Ult Compra",;
                _ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:dataMaiorAcumulo,;//07"Dt Maior Ac.",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorMaiorAcumulo),"@E 999,999,999.99"),;//08"Maior Acumulo",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorDebitoAtual),"@E 999,999,999.99"),;//09"Debito Atual",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorDebitoVencidoMais05Dias),"@E 999,999,999.99"),;//10"Vencido 5+",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorDebitoVencidoMais15Dias),"@E 999,999,999.99"),;//11"Vencido 15+",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorDebitoVencidoMais30Dias),"@E 999,999,999.99"),;//12"Vencido 30+",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:prazoMedioDeVendas),"@E 999,999,999.99"),;//13"Prazo médio",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorMediaPonderadaAtrasoPagamentos),"@E 999,999,999.99"),;//14"Media Atrasos",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:mediaPonderadaTitulosVencidosMais05Dias),"@E 999,999,999.99"),;//15"Media Vencidos",;
                transform((_ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:valorLimiteCredito),"@E 999,999,999.99"),;//16"Limite Crédito",;
                _ocisp:positivaSegmentos[_nnk]:positivas[_nnj]:descricaoLimiteCredito})//17"Tp limite Crédito"
        Next _nnj
    Next _nnk

    If Len(aWBrowse2) == 0
        aAdd(aWBrowse2,{"N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C","N/C"})
    EndIf

    For _nnk := 1 To Len(_ocisp:restritivas)
        aAdd(aWBrowse3,{_ocisp:restritivas[_nnk]:razaoSocial,;
            _ocisp:restritivas[_nnk]:datainformacao,;
            decodeutf8(_ocisp:restritivas[_nnk]:descricaoprimeirarestritiva),;
            decodeutf8(_ocisp:restritivas[_nnk]:descricaosegundarestritiva)})
    Next _nnk

    For _nnk := 1 To Len(_ocisp:alertas)
        aAdd(aWBrowse3,{decodeutf8(_ocisp:alertas[_nnk]:razaoSocial),_ocisp:alertas[_nnk]:dataAtualizacao,decodeutf8(_ocisp:alertas[_nnk]:descricaoAlerta)," "})
    Next _nnk

    _ccheques := StrZero(_ocisp:chequeSemfundo:totalDevolucoes,2)
    _cdcheques:= "N/C"

    For _nni := 1 To Len(_ocisp:chequeSemfundo:cheques)
        If _nni == 1
            _cdcheques := _ocisp:chequeSemfundo:cheques[_nni]:dataocorrencia
        Else
            _cdcheques += ", " + _ocisp:chequeSemfundo:cheques[_nni]:dataocorrencia
        EndIf
    Next _nni

    _ndebatu := _ocisp:informacaoSuporte
    If Type("_ndebatu") == "O"
        cdebatu := transform( _ocisp:informacaoSuporte:valorTotalDebitoAtual ,"@E 999,999,999.99")
        cvenc5 := transform( _ocisp:informacaoSuporte:valorTotalDebitoVencidoMais05Dias ,"@E 999,999,999.99")
        cvenc15 := transform( _ocisp:informacaoSuporte:valorTotalDebitoVencidoMais15Dias ,"@E 999,999,999.99")
        cvenc30 := transform( _ocisp:informacaoSuporte:valorTotalDebitoVencidoMais30Dias ,"@E 999,999,999.99")
        ctotlim := transform( _ocisp:informacaoSuporte:valorTotalLimiteCredito ,"@E 999,999,999.99")
        cmaior  := transform( _ocisp:informacaoSuporte:valorTotalMaiorAcumulo ,"@E 999,999,999.99")
        cVendas := transform( _ocisp:informacaoSuporte:quantidadeAssociadasVendasUltimos2Meses ,"@E 999,999,999")
    Else
        cdebatu := transform( 0 ,"@E 999,999,999.99")
        cvenc5  := transform( 0 ,"@E 999,999,999.99")
        cvenc15 := transform( 0 ,"@E 999,999,999.99")
        cvenc30 := transform( 0 ,"@E 999,999,999.99")
        ctotlim := transform( 0 ,"@E 999,999,999.99")
        cmaior  := transform( 0 ,"@E 999,999,999.99")
        cVendas := transform( 0 ,"@E 999,999,999")
    EndIf

    //Lê protestos
    _cprotes := "ERRO NA CONSULTA"

    //Faz chamada ao webservice de pesquisa de protesto
    cUrlprotesto := "https://servicos.cisp.com.br/v1/consulta-protesto/" + AllTrim(_ccnpj)
    cHdprotesto := ""
    cCorProtesto            := HttpGet(cUrlprotesto,"",NIL,aHeadOut,@cHdprotesto)

    //Verifica e formata resposta do Sintegra
    If SubStr(cHdprotesto,1,15) == "HTTP/1.1 200 OK" .And. FWJsonDeserialize(cCorprotesto,@_osprotesto)
        If ! ("NADA CONSTA" $ Upper(_osprotesto:situacao))
            _cprotes := _osprotesto:situacao + " - " +  StrZero(_osprotesto:qtdTitulos,3) + " protestos"
        Else
            _cprotes := _osprotesto:situacao + " - 000 protestos"
        EndIf
    EndIf

    //Se achou protestos adiciona na tela de alerta
    If "NADA CONSTA" $ Upper(_cprotes) // "NADA CONSTA - 000 protestos"
        aAdd(aWBrowse3,{"PROTESTOS","Cons. em " + DToC(Date()),_CPROTES," "})
    EndIf

    //Se achou cheques devolvidos  adiciona na tela de alerta
    If _ccheques != '00'
        aAdd(aWBrowse3,{"CHEQUES DEVOLVIDOS","Cons. em " +  DToC(Date()),_ccheques," "})
    EndIf


    If Len(aWBrowse3) == 0
        aAdd(aWBrowse3,{"N/C","N/C","N/C","N/C"})
    EndIf
Else
    U_ITMsg("Falha de consulta na cisp!","Atenção",,1)
    _lRet := .F.
EndIf

Return _lRet

/*=============================================================================================================================
Programa----------: ITPARCS()
Autor-------------: Josué Danich
Data da Criacao---: 04/04/2019
Descrição---------: Retorno de quantidade de parcelas da condição de pagamento
Parametros--------: _ccond - código da condição de pagamento
Retorno-----------: _nparcs - número de parcelas
===============================================================================================================================
*/
User Function IT_PARCS(_ccond As Char)  As Numeric

Local _nparcs  := 0 As Numeric
Local _aRet:= condicao(1000,_ccond,0,Date())  As Array 

_nparcs := Len(_aRet)

Return _nparcs

/*=============================================================================================================================
Programa----------: ITTPARC()
Autor-------------: Josué Danich
Data da Criacao---: 04/04/2019
Descrição---------: Atualiza E4_I_PARCS
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function ITTPARCS()

Local _aRet := {}

If !U_ITMsg("Atualizar E4_I_PARCS de todos os registros?","Atenção",,2,2,2)
    U_ITMsg("Processo cancelado","Atenção",,1)
    Return
EndIf

SE4->(DBGoTop())

While SE4->(!Eof())
    _nposi := SE4->(Recno())
    _aRet := condicao(1000,SE4->E4_CODIGO,0,Date())
    SE4->(DBGoTo(_nposi))
    RecLock("SE4",.F.)
    SE4->E4_I_PARCS := Len(_aRet)
    SE4->(MSUnLock())
    SE4->(DBSkip())
EndDo

Return 

/*=============================================================================================================================
Programa----------: ITENTIMED()
Autor-------------: Jonathan Torioni
Data da Criacao---: 31/07/2020
Descrição---------: Função utilizada no gatilho do campo C5_I_AGEND
Parametros--------: _dData
                    _cCliente
                    _cLjCli
                    _cFilFt
                    _cNumPv
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function ITENTIMED(_dData,_cCliente,_cLjCli, _cFilFt,_cNumPv)
Local _dRet
Local _dNec

//Primeiro calculo a data da necessidade para conseguir validar a data de entrega
//Data da necessidade só sera calculada antecipadamente se a entrega For imediata

_dNec := DataValida(_dData+1, .T.)
_dRet := DataValida(_dNec + U_OMSVLDENT(_dData,_cCliente,_cLjCLi,_cFilFt,_cNumPv,1,.F.),.T.)

Return _dRet

/*=============================================================================================================================
Programa----------: OMSDTENG()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/09/20211
Descrição---------: Função que chama a função  U_OMSVLDENT(), para ser utilizada em gatilhos, devido o excesso de parâmetros
                    da função  U_OMSVLDENT() não caber no campo de regras do dicionário de gatilhos.
Parametros--------: _dData       = data a ser utilizada pela função  U_OMSVLDENT().
                    _lVarMemoria = .T. = Alias de variável de memória.
                                   .F. = Alias de tabela de dados.
                    _lValida     = .T. = Valida transit time apenas.
                                 = .F. = Retorn o numero de dias do transit time.
Retorno-----------: _xRet   = .T./.F. = quando a função  U_OMSVLDENT() For uma validação.
                            = Numero de dias = quando a função  U_OMSVLDENT() For de cálculo de transit time.
===============================================================================================================================
*/
User Function OMSDTENG(_dData,_lVarMemoria,_lValida)
Local _cFilCarreg := ""
Local _nAcao
Local _xRet := .F.
Default _dData := Date()
Default _lVarMemoria := .T.
Default _lValida := .F.

If _lVarMemoria
    _cFilCarreg := xFilial("SC5")
    If ! Empty(M->C5_I_FLFNC)
        _cFilCarreg := M->C5_I_FLFNC
    EndIf
Else
    _cFilCarreg := SC5->C5_FILIAL
    If ! Empty(SC5->C5_I_FLFNC)
        _cFilCarreg := SC5->C5_I_FLFNC
    EndIf
EndIf

If _lValida
    _nAcao := 0
Else
    _nAcao := 1
EndIf

If _lVarMemoria
    _xRet := U_OMSVLDENT(M->C5_I_DTENT,M->C5_CLIENTE,M->C5_LOJACLI,M->C5_I_FILFT,M->C5_NUM,_nAcao,.F.,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN)
Else
    _xRet := U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,_nAcao,.F.,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN)
EndIf

Return _xRet

/*
===============================================================================================================================
Programa----------: ArredMax
Autor-------------: Abrahao P. Santos
Data da Criacao---: 18/12/2008
Descrição---------: Arredonda um valor para o maior numero inteiro, por exemplo: 10,02 para 11 ou 10,99 para 11. 
Parametros--------: nvalor - número  ser arrendodado
Retorno-----------: nvalor - valor arredondado
===============================================================================================================================
*/
User Function ARREDMAX(nValor)

If Int(nValor) < nValor
    nValor := Round(nValor+0.5,0)
EndIf

Return(nValor)

/*
===============================================================================================================================
Programa----------: U_IT_TMS()
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 06/06/2025
Descrição---------: Retorna se o Local de Embraque usa TMS ou não .
Parametros--------: _cLocEmb = Codigo do locae de Embarque
Retorno-----------: .T. = Local de embarque É TMS - MultiEmbarcador
                    .F. = Local de embarque É TMS - RDC
===============================================================================================================================
*/
User Function IT_TMS(_cLocEmb)
Local lRet := .F.//RDC
Static _cWsTms := "XXXX"

If _cWsTms ="XXXX"
    _cWsTms := SuperGetMV( 'IT_LOEMTMS',.F.,"")
EndIf

If !Empty(_cWsTms) .And. Upper(_cLocEmb) $ Upper(_cWsTms)
    lRet:= .T.//MultiEmbarcador
EndIf

Return lRet
