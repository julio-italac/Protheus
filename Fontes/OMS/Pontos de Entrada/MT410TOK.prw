#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT410TOK
Autor-------------: Wodson Reis
Data da Criacao---: 04/08/2009
Descrição---------: PE de validação do pedido de vendas
Parametros--------: ExpA01 - Se a primeira posicao do array conter 1, o usuario pressionou Ok, caso contrario Cancelar.
Retorno-----------: ExpL01 - Se .T. continua a operacao, se .F. nao volta pra tela de pedido sem fazer nada.
===============================================================================================================================
*/
User Function MT410TOK() As Logical

Private _lRet As Logical
Private _lContOK := .T. As Logical

_lRet:=.T.

If .NOT. ( FWIsInCallStack("MDIEXECUTE") .Or. FWIsInCallStack("SIGAADV") )
   _lRet:=MT410_OK()
Else
   FWMsgRun( ,{|oProc|  _lRet:=MT410_OK(oProc) }  , "Aguarde...", "Validando dados..."  )//ATEÇÃO TEM GRAVAÇÃO DENTRO DESSA FUNÇÃO
   // NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE PROCURE POR "COLOQUE AQUI" E INSIRA AS VALIDACOES LÁ POR FAVOR, NÃO COLOQUE NADA AQUI
EndIf

Return _lRet

/*=============================================================================================================================
Programa----------: MT410_OK()
Autor-------------: Alex Wallauer
Data da Criacao---: 21/09/2018
Descrição---------: PE de validação do pedido de venda
Parametros--------: NENHUM
Retorno-----------: ExpL01 - Se .T. continua a operacao, se .F. nao volta pra tela de pedido sem fazer nada.
===============================================================================================================================*/
Static Function MT410_OK(oProc)

Local nX As Numeric
Local nN As Numeric//Restaura o valor de n, que eh a variavel publica do protheus que indica a linha do aCols.
Local _aArea As Array
Local lBlq2 As Logical
Local lBlq3	As Logical
Local cTes As Character
Local nPosProduto As Numeric
Local nPosTes As Numeric
Local cItens As Character
Local cPosPrd As Character
Local cFatCon As Character
Local cPosVlr As Character
Local lPrim	As Logical
Local nTotal As Numeric
Local nDescPer As Numeric
Local cQtdZero As Character
Local nPerc	As Numeric
Local _nValVol As Numeric
Local _aprod As Array
Local _ccodpro As Character
Local _nY As Numeric
Local _cBlqCred As Character
Local nPosDifPe As Numeric
Local _lSegDIf As Logical
Local _lMashup As Logical
Local _cFilHabilit As Character // Filiais habilitadas na integracao Webservice Italac x RDC.
Local _cFilOper	 As Character // Filiais a serem validadas
Local _cOperEst	 As Character // Tipos de operações a serem validados           <<<<<<
Local _cProdPe As Character	// Produtos permitidos                            <<<<<<
Local _cPrd3Um As Character // Produtos a validar pela 3ª unidade de medida
Local _cLocval As Character // Armazéns que não valida quantidade fracionada  <<<<<<
Local _cTpOper As Character //Armazena o tipo de operacao que na TES INTELIGENTE pode ter a TES alterada pelo usuario
Local _cProdNFrac As Character // Produtos proibidos de serem fracionados na Venda.
Local _lValAltPVin As Logical // Habilitar para validar se o PV Vinculado foi altearado para outro PV
Local _lLibMas As Logical
Local _nQtdDia As Numeric
Local _nQtdiaT As Numeric
Local _lExec As Logical
Local _cBloqSBZ  As Character
Local _lValCredito AS Logical // Tem que iniciar com .T. pq pode ta vindo de MSEXECAUTO(), com .T. não limpa os campos de validação de credito
Local _nTotPV AS Numeric
Local _nI As Numeric
Local y As Numeric
Local x As Numeric
Local _lTravadoPorAlguem As Logical
Local _aItensLock As Array
Local auser As Array
Local _nRecOrigem As Numeric
Local _cLocalNFrac  As Character // Armazens/Locais vinculados aos produtos proibidos de serem fracionados na Venda.
Local _cTipOpNFrac  As Character	// Tipos de Operações vinculados aos produtos proibidos de serem fracionados na Venda.
Local _l108 As Logical
Local _laoms074 As Logical
Local _nnipre As Numeric
Local _nRegVinc As Numeric
Local _lEstornoRDc As Logical
Local _nSalvaN As Numeric
Local _cUser As Character
Local _cchep  As Character
Local _nRegSC5 As Numeric
Local _aOrd As Array
Local _cFilSC5  As Character
Local _cBlqContrato As Character
Local _lUsaNovo As Logical
Local _cGrupoP  As Character
Local _cUFPedV  As Character
Local _cTipoProd As Character
Local _cDescriPrd As Character
Local _cDescTBPrc  As Character
Local nZ As Numeric
Local cItensnZ  As Character
Local aTabnZ As Array
Local nPesCarg As Numeric
Local nPsBru As Numeric
Local _cTipoPedido  As Character
Local _ccondr As Character
Local _dHoje As Date
Local _lItemAlterado As Logical
Local _cRedeCliente As Character
Local _lSimplNac As Logical
Local _cSimplNac As Character
Local _aBlqprc As Array
Local _lPrcErr As Logical
Local _nFaixa As Numeric
Local _cMsgPrc As Character
Local _cFilCarreg As Character
Local _lAoms112 As Logical
Local _lFob As Logical
Local _nDescPTon As Numeric
Local _cOperFret As Character
Local _dDtCalcFr As Date
Local _cOperTran As Character
Local _cCrtl3Um As Character // Produtos a validar quantidade fracionada na terceira unidade de medida.

Local _cTextoUnd As Character
Local _cTextCalc As Character

Local _cOperTriangular As Character
Local _cOperFat As Character
Local _cOperRemessa As Character
Local _aProdBlq As Array

Local _cTextoMsg As Character

Local _cLocalPCh As Character
Local _nPos As Numeric
Local _nPosFilAnt As Numeric

Local _cSuframa  As Character
Local _cEstCli   As Character
Local _cEstFil   As Character
Local _cItemOpeT As Character
Local _cTESOperT As Character

Local _nPosDescr As Numeric

Local _dDtAgeMax 
Local _dDtAgeEnt
Local __cCodCli  As Character
Local __cLojaCli As Character
Local _cFilValid As Character
Local _cTESTrans As Character
Local _cCFTransf As Character
Local _aDadosCfo As Array 

If !Inclui .And. !(SC5->C5_NUM == M->C5_NUM)
   SC5->(DBSeek(xFilial()+M->C5_NUM))//RePosiciona caso não esteja posicionado
EndIf

Private lRet As Logical //Padrao variavel LOCAL
Private cNumPrd As Character
Private aItens As Array
Private lDifPes As Logical
Private lTemItemPA As Logical
Private _lItemNovo As Logical


nX			    := 1
nN			    := N //Restaura o valor de n, que eh a variavel publica do protheus que indica a linha do aCols.
_aArea		    := FWGetArea()
lBlq2		    := .F.
lBlq3	     	:= .F.
cTes			:= ""
nPosProduto	    := 0
nPosTes		    := 0
cItens 		    := ""
cPosPrd 	    := ""
cFatCon 		:= ""
cPosVlr		    := ""
lPrim			:= .T.
nTotal		    := 0
nDescPer  	    := 0
cQtdZero  	    := ""
nPerc			:= 0
_nValVol		:= 0
_aprod		    := {}
_ccodpro		:= " "
_nY			    := 1
_cBlqCred		:= '  '
nPosDifPe		:= 0
_lSegDif		:= .T.
_lMashup		:= SuperGetMV("IT_MASHUP",.T.,.F.)
_cFilHabilit 	:= SuperGetMV('IT_FILINTW',.T.,'') // Filiais habilitadas na integracao Webservice Italac x RDC.
_cFilOper		:= SuperGetMV("IT_FILOPE",.T.,"")	// Filiais a serem validadas
_cOperEst		:= SuperGetMV("IT_OPEEST",.T.,"")	// Tipos de operações a serem validados           <<<<<<
_cProdPe		:= SuperGetMV("IT_PRODPE",.T.,"")	// Produtos permitidos                            <<<<<<
_cPrd3Um		:= SuperGetMV("IT_PRD3UM",.T.,"")	// Produtos a validar pela 3ª unidade de medida
_cLocval		:= SuperGetMV("IT_LOCFRA",.T.,"")	// Armazéns que não valida quantidade fracionada  <<<<<<
_cTpOper	    := SuperGetMV("IT_OPETES",.T.,"") //Armazena o tipo de operacao que na TES INTELIGENTE pode ter a TES alterada pelo usuario
_cProdNFrac     := SuperGetMV("IT_PRDNFRA",.T.,"")	// Produtos proibidos de serem fracionados na Venda.
_lValAltPVin    := SuperGetMV("IT_VALALTP",.T.,.T.)	// Habilitar para validar se o PV Vinculado foi altearado para outro PV
_lLibMas	    := .F.
_nQtdDia	    := 0
_nQtdiaT	    := 0
_lExec	        := .F.
_cBloqSBZ       := ""
_lValCredito    := .T. // Tem que iniciar com .T. pq pode ta vindo de MSEXECAUTO(), com .T. não limpa os campos de validação de credito
_nTotPV := 0
_nI := 0
y := 0
x := 0
_lTravadoPorAlguem := .F.
_aItensLock := {}
auser := {}
_nRecOrigem := 0
_cLocalNFrac  := SuperGetMV("IT_LOCNFRA",.T.,"")	// Armazens/Locais vinculados aos produtos proibidos de serem fracionados na Venda.
_cTipOpNFrac  := SuperGetMV("IT_TPONFRA",.T.,"")	// Tipos de Operações vinculados aos produtos proibidos de serem fracionados na Venda.
_l108 := .F.
_laoms074 := .F.
_nnipre := 0
_nRegVinc := 0
_lEstornoRDc := .F.
_nSalvaN := N
_cUser := RetCodUsr()
_cchep := AllTrim(SuperGetMV("IT_CCHEP",.T.,""))
_nRegSC5 := 0
_aOrd := {}
_cFilSC5 := ""
_cBlqContrato := ""
_lUsaNovo := SuperGetMV("IT_TABPRG",.T.,.F.)
_cGrupoP := ""
_cUFPedV := ""
_cTipoProd := ""
_cDescriPrd := ""
_cDescTBPrc := ""
nZ := 0
cItensnZ := ""
aTabnZ := {}
nPesCarg := SuperGetMV("IT_PESOFEC",.T.,4000)
nPsBru := 0
_cTipoPedido := "V"
_ccondr := ""
_dHoje := Date()
_lItemAlterado  := .F.
_cRedeCliente   := ""
_lSimplNac := .F.
_cSimplNac := ""
_aBlqprc := {}
_lPrcErr := .F.
_nFaixa  := 0
_cMsgPrc := ""
_cFilCarreg := ""
_lAoms112 := .F.
_lFob := .F.
_nDescPTon := 0
_cOperFret := SuperGetMV("IT_OPERFRE",.T.,"")
_dDtCalcFr := Ctod(SuperGetMV("IT_DTCALCF",.T.,"23/06/2022"))
_cOperTran := SuperGetMV("IT_OPERTRA",.T.,"20/21")
_cCrtl3Um := "N" // Produtos a validar quantidade fracionada na terceira unidade de medida.

_cTextoUnd := " 2a.UM (segunda) "
_cTextCalc := ""

_cOperTriangular := ""
_cOperFat        := ""
_cOperRemessa    := ""
_aProdBlq        := {}

_cTextoMsg := ""

_cLocalPCh := SuperGetMV('IT_ARMPACH',.T.,'40;42;')
_nPos := 0
_nPosFilAnt := 0
__cCodCli   := ""
__cLojaCli  := ""

lRet 		:= .T. //Padrao variavel LOCAL
cNumPrd 	:= ""
aItens 		:= {}
lDifPes		:= .F.
lTemItemPA	:= .F.
_lItemNovo  := .F.

Begin Sequence

//Se veio do webservice já retorna .T.
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B") 
   _laoms074 := .T.
EndIf

//Se veio da rotina de exclusão automática de pedidos de venda já retorna .T.
If FWIsInCallStack("U_AOMS108")
    _l108 := .T.
EndIf

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaçao Automatica)
If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_MOMS050")
    _lAoms112 := .T.
EndIf

nPosProduto		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"	} )
nPosTes 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_TES"		} )
nPosBlPrc 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_BLPRC"	} )
nPosPedCli 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PEDCLI"	} )
nPosUser 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_USER"  } )
nPosVal			:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_VALOR"   } )
nPosPreco		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRCVEN"  } )
nPosPLIBP		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_PLIBP" } )
nPosVLIBP		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_VLIBP" } )
nPosqtd			:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_QTDVEN"  } )
nPosLoc	    	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"   } )
_cCFOP	        := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CF"	    } )
nPosQtd2		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_UNSVEN"	} )
nPosIte	    	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_ITEM"    } )
nPosAmz         := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_LOCAL"   } )
_nPosItPc       := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_ITEMPC"  } )
nPosPerc        := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_PDESC" } )
nPosCVLTAB      := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_VLTAB" } )
nPosFXPES       := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_FXPES" } )
_nPosPrNet      := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_PRNET" } )
_nPosQPale      := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_QPALT" } )
_nPosCC         := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CC"      } )
_nPosC6OPER     := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_OPER"    } )
nPosVlTab       := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_VLTAB"      } )
nPosPrMin       := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_PRMIN"      } )
_nPosDescr      := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_DESCRI"} )

SC5->( DBSetOrder(1) )

_lbloq4 := .F.

_cOperTriangular:= AllTrim(SuperGetMV( "IT_OPERTRI",.T.,"05,42"))
_cOperFat       := LEFT(_cOperTriangular,2)
_cOperRemessa   := RIGHT(_cOperTriangular,2)

If INCLUI .And. !_lAoms112
    If M->C5_I_OPER = _cOperFat
        M->C5_I_OPTRI := "F"
    ElseIf M->C5_I_OPER = _cOperRemessa
        M->C5_I_OPTRI := "R"
    EndIf
EndIf
//================================================================================
// Tratamentos Operação Triangular e Clientes Remessa efetivação Pedidos do Portal
//================================================================================
If INCLUI .And. _lAoms112
   If Type("_cOperTri") <> "U"
      If ! Empty(_cOperTri)
         M->C5_I_OPTRI := _cOperTri
      EndIf
   EndIf

   If Type("_cCodClien") <> "U"
      If ! Empty(_cCodClien)
         M->C5_I_CLIEN := _cCodClien
      EndIf
   EndIf

   If Type("_cLojaClie") <> "U"
      If ! Empty(_cLojaClie)
         M->C5_I_LOJEN := _cLojaClie
      EndIf
   EndIf
EndIf
//================================================================================
// Tratamentos Gerente Nacional
//================================================================================
If INCLUI .Or. ALTERA
   If ! Empty(M->C5_VEND1) .And. Empty(M->C5_VEND5)
      M->C5_VEND5 := Posicione("SA3",1,xFilial("SA3")+M->C5_VEND1,"A3_I_GERNC")
   EndIf
EndIf

//================================================================================
// Indica se a funçõa foi chamada através da rotina de alteração de pedidos.
//================================================================================
Private _lMsgEmTela := .T.

If Type("_cAOMS074") <> "U" .Or. FWIsInCallStack("U_AOMS109")
   _lMsgEmTela := .F.
EndIf

_cTipoPedido := Posicione("ZAY",1,xFilial("ZAY")+ AllTrim(aCols[1,_cCFOP]) ,"ZAY_TPOPER")

//================================================================================
// Calcula o Peso Bruto Total do Pedido
//================================================================================

nPsBru := M410LITotais()

_cRedeCliente := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_GRPVEN")
//================================================================================
// Validar clientes com bloqueio de contrato
//================================================================================

M410Proc(oProc,"Cadastro do Cliente")

If Inclui .Or. Altera
   If FWIsInCallStack("MATA410") .And. SA1->(FieldPos("A1_I_BLQCT") > 0) .And. M->C5_TIPO = "N"
      _cBlqContrato := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_I_BLQCT")
      If _cBlqContrato == "S"
         U_MT_ITMSG("Cliente com bloqueio de Contrato de Desconto.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Favor procurar o departamento de Contratos para solicitar o desbloqueio.",1)
         lRet := .F.
      EndIf
   EndIf
EndIf

//================================================================================
// *************           TRATAMENTO FOB       *********************
//================================================================================
If Inclui .Or. Altera
    If FWIsInCallStack("MATA410")
        _lFob := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_I_FOB")
        If AllTrim(M->C5_TPFRETE) $ "F/D" .And. !(M->C5_I_OPER $ _cOperFret) .And. DToS(M->C5_EMISSAO) >= DToS(_dDtCalcFr)
            If !_lFob
                U_MT_ITMSG("Para este Cliente não é permitdo o Tipo de Frete FOB.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Para que permita a seleção de Tipo de Frete FOB modifique o respectivo campo no cadastro desse Cliente.",1)
                lRet := .F.
            EndIf
        EndIf
    EndIf
EndIf

//==========================================================================================
// Validar os usuários que são autorizados a fazer manutenção em pedidos de transferências.
//==========================================================================================
If ZZL->(FieldPos("ZZL_IPVTRA")) > 0
   If (Inclui .Or. Altera .Or. AllTrim(aRotina[1][1]) == "Excluir") .And. M->C5_I_TRCNF <> "S" .And. !_lAoms074
      If M->C5_I_OPER $ _cOperTran
         ZZL->( DBSetOrder(3) )
         If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
            If ZZL->ZZL_IPVTRA <> "S"
               U_MT_ITMSG("Usuário não autorizado a realizar manutenção em Pedidos de Vendas com operações de transferências de pedidos.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"",1)
               lRet := .F.
            EndIf
         Else
            U_MT_ITMSG("Usuário não autorizado a realizar manutenção em Pedidos de Vendas com operações de transferências de pedidos.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"",1)
            lRet := .F.
         EndIf
      EndIf
   EndIf
EndIf

//==================================================
// Calcula desconto por tonelada para fretes Fob.
//==================================================
If Inclui .Or. Altera
   _lFob := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_I_FOB")
   If _lFob .And. AllTrim(M->C5_TPFRETE) $ "F/D" .And. !(M->C5_I_OPER $ _cOperFret) .And. DToS(M->C5_EMISSAO) >= DToS(_dDtCalcFr)
      _nDescPTon := U_M410BDES(M->C5_FILIAL,M->C5_I_EST, M->C5_I_OPER , M->C5_I_CMUN) // Retorna o desconto por tonelada para pedidos Fob.
      If _nDescPTon > 0
         M->C5_DESCONT :=  ((nPsBru/1000)*_nDescPTon)
      EndIf
   EndIf
EndIf
//================================================================================
// *************           TRATAMENTO TABELA DE PREÇO        *********************
//================================================================================
_cSimplNac := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_SIMPNAC")
If _cSimplNac == "1"
   _lSimplNac := .T. // O cliente é optante do Simples Nacional
Else
   _lSimplNac := .F. // O cliente não é Optante do Simples Nacional
EndIf

//**************************************************************************************************************************//
//Busca do Local de Embarque - Chamado 43864
//-------------------------------------------//
If M->C5_I_OPER <> _cOperFat .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5 //EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
   _cLocal1oItem:=""
   For nX := 1 To Len(aCols)
       If aCols[nX][Len(aCols[nX])]
          Loop
       EndIf
       _cLocal1oItem:=AllTrim(aCols[nX,nPosLoc])//
       Exit
   Next
   M->C5_I_LOCEM:=U_BuscaLocalEmbarque(cFilAnt,_cLocal1oItem,M->C5_VEND1)//Função no Programa AOMS136.PRW
EndIf

//===================================================================================
// Carrega o grupo de produtos fora do If para ser utilizado em varias validações.
//===================================================================================
_cGrupoP   := Posicione("SB1",1,xFilial("SB1")+acols[N][nPosProduto],"B1_GRUPO")
_cTipoProd := Posicione("SB1",1,xFilial("SB1")+acols[N][nPosProduto],"B1_TIPO")

//===================================================================================
// Busca do Local de Embarque - Chamado 43864
//===================================================================================
If  lRet .And. M->C5_TIPO = "N" .And. M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26") .And.;
    !FWIsInCallStack("U_AOMS032") .AND.;
    !FWIsInCallStack("U_AOMS032EXE") .And. ;
    !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103")  .AND.;
    !(FWIsInCallStack("U_AOMS099")) .And. !_l108 .And. !_laoms074 .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5 .And. !_lAoms112

    //_cGrupoP   := Posicione("SB1",1,xFilial("SB1")+acols[N][nPosProduto],"B1_GRUPO")
    //_cTipoProd := Posicione("SB1",1,xFilial("SB1")+acols[N][nPosProduto],"B1_TIPO")

    //================================================================================
    // Busca Dados do aCols para Tratar se o item sofre manutenção na função Alterar
    //================================================================================
    _lItemNovo:=.F.//Alterado dentro da função M410SITITEM()
    If Altera
        _lItemAlterado := M410SITITEM()
    EndIf

     If FWIsInCallStack("MATA410") .And. _cTipoProd = 'PA' .And. !(FWIsInCallStack("U_AOMS098")) .And. !(FWIsInCallStack("U_AOMS099")) ;
        .And. !(FWIsInCallStack("U_AOMS032")) .And. !(FWIsInCallStack("U_AOMS074")) .And. ! (FWIsInCallStack("U_AOMS112"))
        //=========================================================================== 
        // Valida produtos bloqueados por filial, confome cadastro de 
        // produtos bloqueados por filial.
        //===========================================================================
        If lRet .And. Inclui // (Inclui .Or. Altera)
           If M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26") 
              
              ZBS->(DBSetOrder(1))
              //==================================================================
              // Quando For troca nota validar na filial de carregamento. 
              //==================================================================
              If M->C5_I_TRCNF == 'S'
                 _cFilValid :=  M->C5_I_FLFNC
              Else
                 _cFilValid :=  xFilial("SC5")
              EndIf 

              If Empty(_cFilValid)
                 _cFilValid :=  xFilial("SC5")
              EndIf 
              
              For _nI := 1 To Len(acols)
                  If aCols[_nI,Len(aHeader)+1] // Se Linha Excluida
                     Loop
                  EndIf

                  If ZBS->(MsSeek(xFilial("ZBS")+_cFilValid+acols[_nI][nPosProduto])) //ZBS->(MsSeek(xFilial("ZBS")+xFilial("SC6")+acols[_nI][nPosProduto]))
                     If ZBS->ZBS_SITUAC == "B" 
                        U_MT_ITMSG("Produto [" + AllTrim(acols[_nI][nPosProduto]) + "-" + AllTrim(acols[_nI][_nPosDescr]) + "] bloqueado para filial [" + _cFilValid + "], de acordo com o cadastro de produtos bloqueados por filial.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                                  "Bloqueio definido pela equipe do Comercial.",1)
                        lRet := .F.           
                        Exit
			            EndIf 
                  EndIf 
              Next
           EndIf 
        EndIf           

        If Empty(AllTrim(M->C5_I_TAB))
           //Carrega tabela de preços
           aTabnZ := U_ITTABPRC(M->C5_FILGCT,M->C5_I_FILFT,M->C5_VEND3,M->C5_VEND2,M->C5_VEND1,M->C5_CLIENTE,M->C5_LOJACLI,.T.,,M->C5_VEND4,M->C5_I_GRPVE , _cGrupoP,M->C5_I_OPER,M->C5_I_LOCEM,M->C5_I_CLIEN,M->C5_I_LOJEN)
           _ctab    := aTabnZ[1]
           _ntab    := aTabnZ[2]
           _cGrupoP := aTabnZ[5]  // Grupo de estoque do produto.
           _cUFPedV := aTabnZ[6]  // UF do pedido de vendas.
           M->C5_I_ORTBP := _ntab
           M->C5_I_TAB   := _cTab
        Else
           _cTab    := M->C5_I_TAB
           _nTab    := M->C5_I_ORTBP
           _cUFPedV := M->C5_I_EST
        EndIf
        _cDescriPrd := ""
        _cDescTBPrc := ""

        If !Empty(M->C5_EMISSAO)
            _dHoje := M->C5_EMISSAO
        EndIf

         //Valida validade da tabela da regra posicionada, se For inválida pula a análise
        DA0->(DBSetOrder(1))

        If (DA0->(DBSeek(xFilial("DA0")+_ctab)))
           If DA0->DA0_ATIVO == '2'  //Tabela inativa
               _cDescTBPrc := AllTrim(_ctab) + "-" + AllTrim(DA0->DA0_DESCRI)
               U_MT_ITMSG("Tabela de preços " + _cDescTBPrc + ", Inativa!",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Verifique regras de tabelas de preço",1)
               lRet := .F.
           EndIf
           If lRet .And. DA0->DA0_DATDE > Date() .Or. DA0->DA0_DATATE < _dHoje .And. !Altera
              _cDescTBPrc := AllTrim(_ctab) + "-" + AllTrim(DA0->DA0_DESCRI)
              U_MT_ITMSG("Tabela de preços " + _cTab + "-" + _cDescTBPrc + " fora da vigência!",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Verifique regras de tabelas de preço",1)
              lRet := .F.
           EndIf
        ElseIf Empty(_ctab)
           U_MT_ITMSG("Tabela de preços não preenchida!",'Atencao! Ped.: '+M->C5_NUM,"Verifique regras de tabelas de preço",1)
           lRet := .F.
        Else
           U_MT_ITMSG("Tabela de preços " + _ctab + " não localizada!",'Atencao! Ped.: '+M->C5_NUM,"Verifique regras de tabelas de preço",1)
           lRet := .F.
        EndIf

        If lRet
           If M->C5_I_TPVEN == "F" .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
               If nPsBru < nPesCarg .And. Empty(M->C5_I_PODES)
                   U_MT_ITMSG("Este pedido não pode ser do tipo (F - Fechada).","Falha","Para que o pedido seja do tipo (F - Fechada) "+;
                               "o peso total do Pedido devem ser maior ou igual a "+ cValToChar(nPesCarg )+" Kg. Para concluir o pedido altere o Tipo de Venda "+;
                               "para (V - Fracionada).",1)
                   lRet := .F.
               EndIf
           EndIf

           _cDescTBPrc := AllTrim(_ctab) + "-" + AllTrim(DA0->DA0_DESCRI)

           If lRet .And. ( _lItemAlterado .Or. Inclui )  .And. !(FWIsInCallStack("U_AOMS098"))
              //Valida existência de produtos na tabela de preços selecionada
              For _nnipre := 1 To Len(acols)
                  If aCols[_nnipre,Len(aHeader)+1] // Se Linha Excluida
                     Loop
                  EndIf

                  DA1->(DBSetOrder(1)) //DA1_FILIAL+DA1_CODTAB+DA1_CODPRO
                  If !(DA1->(DBSeek(xFilial("DA1")+_ctab+acols[_nnipre][nPosProduto])))
                     _cDescriPrd += "Produto sem cadastro: " + AllTrim(acols[_nnipre][nPosProduto]) + "-" + AllTrim(Posicione("SB1",1,xFilial("SB1")+acols[_nnipre][nPosProduto],"B1_DESC"))+CRLF
                     lRet := .F.
                  Else
                     If Inclui
                        If DA1->DA1_ATIVO == '1'
                           If nPsBru >=  DA0->DA0_I_PES1
                               acols[_nnipre][nPosCVLTAB] := DA1->DA1_I_PRF1
                               acols[_nnipre][nPosFXPES] := 1
                           ElseIf nPsBru >=  DA0->DA0_I_PES2 .And. nPsBru <  DA0->DA0_I_PES1
                              acols[_nnipre][nPosCVLTAB] := DA1->DA1_I_PRF2
                              acols[_nnipre][nPosFXPES] := 2
                           Else
                              acols[_nnipre][nPosCVLTAB] := DA1->DA1_I_PRF3
                              acols[_nnipre][nPosFXPES] := 3
                           EndIf
                        Else
                           lRet := .F.
                           _cDescriPrd += "Produto Inativo: " + AllTrim(acols[_nnipre][nPosProduto]) + "-" + AllTrim(Posicione("SB1",1,xFilial("SB1")+acols[_nnipre][nPosProduto],"B1_DESC"))+CRLF
                        EndIf
                     ElseIf Altera
                          If  DA1->DA1_ATIVO == '1'
                              If nPsBru >=  DA0->DA0_I_PES1
                                 acols[_nnipre][nPosFXPES] := 1
                              ElseIf nPsBru >=  DA0->DA0_I_PES2 .And. nPsBru <  DA0->DA0_I_PES1
                                 acols[_nnipre][nPosFXPES] := 2
                              Else
                                 acols[_nnipre][nPosFXPES] := 3
                              EndIf
                          Else
                              lRet := .F.
                              _cDescriPrd += "Produto Inativo: " + AllTrim(acols[_nnipre][nPosProduto]) + "-" + AllTrim(Posicione("SB1",1,xFilial("SB1")+acols[_nnipre][nPosProduto],"B1_DESC"))+CRLF
                          EndIf
                     EndIf
                 EndIf
            Next
              If !lRet
                  U_MT_ITMSG("Existem produtos que não constam na tabela de preço ou esta Inativo " + _cDescTBPrc+". Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                             'Atencao!',"Verifique a tabela de preço e regras de tabela de preço para esse pedido"                               ,1     ,       ,        ,         ,     ,     ,{|| U_ITMSGLOG(_cDescriPrd,"Produtos com Problema.") },_cDescriPrd )
              EndIf
          EndIf
        EndIf
        If lRet .And. Empty(M->C5_I_PODES) .And. Inclui //Inclusão e Não Desdobramento
           If Len(aCols) > 0
               For nZ := 1 To Len(aCols)
                   _aBlqprc  := U_BLQPRC(aCols[nZ][nPosProduto],aCols[nZ][nPosPreco],  M->C5_FILIAL,   .F.,M->C5_I_TAB,       ,_lusanovo,           ,        .T., _cGrupoP,_cUFPedV,         ,         ,_lSimplNac,nPsBru,0)
                   _lPrcErr  := _aBlqprc[1]
                   _nFaixa   := _aBlqprc[2]
                   _cMsgPrc  := _aBlqprc[3]  // Grupo de estoque do produto.
                   _nPrecoIt := _aBlqprc[4]
                   _nPrecoMin:= _aBlqprc[5]
                   If Len(_aBlqprc) > 6
                      _cDescTBPrc:=_aBlqprc[7] 
                   EndIf 
                   If _lPrcErr
                       cItensnZ += _cMsgPrc
                       aCols[nZ][nPosBlPrc] 	:= "B"
                   EndIf
                   aCols[nZ][nPosVlTab]  := _nPrecoIt
                   aCols[nZ][nPosPrMin]  := _nPrecoMin
                   //fim
               Next nZ
           EndIf
           M->C5_I_FXPES := _nFaixa
           If cItensnZ != ""
              U_MT_ITMSG("O(s) preço(s) praticado(s) algum(ns) item(ns) está(ão) fora da tabela de preço. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                         'Atencao!',"O pedido será marcado como bloqueado para posterior avaliação."                                              ,1     ,       ,        ,         ,     ,     ,{|| U_ITMSGLOG(cItensnZ,"Produtos fora da tabela de preço: "+_cDescTBPrc) },cItensnZ )
              M->C5_I_BLPRC	:= "B"
              M->C5_I_DTLIB	:= CTOD("")
           Else
              M->C5_I_BLPRC	:= " "
           EndIf
        EndIf
    EndIf
EndIf

//======================================================================
// Valida quantidades em segunda unidade de medida, multipla de Pallet.  
//======================================================================
If lRet .And. _cTipoProd = 'PA' .And. (FWIsInCallStack("MATA410") .Or. FWIsInCallStack("U_AOMS098") .Or. FWIsInCallStack("U_AOMS032") .Or. FWIsInCallStack("U_AOMS112")) .And. (Inclui .Or. Altera) .And. M->C5_TIPO = "N" .And. M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26")
   
   _cTextoMsg := ""
   
   _cValFilEm := SUPERGETMV('IT_VFILLOC',.F.,"90SP50;93PR51") // Validação filial x Local de Embarque. 

   If (M->C5_I_TRCNF == "S" .And.  (M->C5_I_FLFNC+M->C5_I_LOCEM) $ _cValFilEm) .Or. (M->C5_I_TRCNF == "N" .And.  (xFilial("SC5")+M->C5_I_LOCEM) $ _cValFilEm)    

      For _nI := 1 To Len(acols)
          If aCols[_nI,Len(aHeader)+1] // Se Linha Excluida
             Loop
          EndIf
                   
          _nNCxPalet := Posicione("SB1",1,xFilial("SB1")+aCols[_nI][nPosProduto],"B1_I_CXPAL") // Numero de caixas por Pallet   

          If (_nNCxPalet > aCols[_nI][nPosQtd2]) .Or. (Mod( aCols[_nI][nPosQtd2], _nNCxPalet ) <> 0)
             _cTextoMsg +=  "Produto [" + AllTrim(acols[_nI][nPosProduto]) + "-" + AllTrim(acols[_nI][_nPosDescr]) + ;
                            "] com quantidades em segunda unidade diferente de multipo de palete."
             lRet := .F.  
          EndIf          
      Next

      If ! lRet
         U_MT_ITMSG(_cTextoMsg,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                    "As quantidades deste item devem ser multiplas de palete.",1)
      EndIf 
   EndIf 
EndIf 

//================================================================================
// *************           TRATAMENTO DE DEAD-LOCK           *********************
//================================================================================
If lRet .And. !FWIsInCallStack( "MSEXECAUTO" )
   M410Proc(oProc,"Locks")
   _lTravadoPorAlguem := U_LockPed(M->C5_CLIENTE,M->C5_LOJACLI,cFilAnt,_aItensLock) //Função no italacxfun que faz o lock completo previnindo deadlock
   If _lTravadoPorAlguem
      lRet:=.F.
   EndIf
EndIf
//================================================================================
// *************           TRATAMENTO DE DEAD-LOCK           *********************
//================================================================================

//----------------------------------------------------------------------------------------------------
//Força campos de cliente e loja entrega a ficarem iguais aos campos cliente loja do pedido
//----------------------------------------------------------------------------------------------------
M->C5_CLIENTE := M->C5_CLIENT
M->C5_LOJAENT := M->C5_LOJACLI

//Busca o/a Assistente do Pedido no Cadastro de Assistente Adm Comercial Responsável - Chamado 43076            
If Inclui .And. M->C5_TIPO = "N"
   //                              _cRede       ,_cVend     ,_cSupe     ,_cCoor     ,_cGere
   _aAssistente:=U_BuscaAssistente(_cRedeCliente,M->C5_VEND1,M->C5_VEND4,M->C5_VEND2,M->C5_VEND3)//Função no Programa AOMS135.PRW
   M->C5_ASSCOD:=_aAssistente[1]
   M->C5_ASSNOM:=_aAssistente[2]
EndIf

//Se não For exclusão não permite cliente com mesmo cnpj da filial atual
//Só bloqueia para operações de venda e transferência
If lRet .And. !_laoms074 .And. !_l108 .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5 .And. AllTrim(SM0->M0_CGC) == AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_CGC"))//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
    If _cTipoPedido $ "VT"
           U_MT_ITMSG("Pedido de venda ou transferência não pode ter como cliente a própria filial.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
               "Altere o cliente",1)
        lRet := .F.
    EndIf
EndIf

// Bloquear a alteração e exclusão de pedidos de vendas quando o campo C5_I_ENVRD (Enviado para o RDC)
// estiver com o conteúdo "S" (Sim).
If lRet .And. !_laoms074 .And. !_l108 .And. M->C5_TIPO = "N" .And. (ParamIXB[1] = 4 .Or. ParamIXB[1] = 5 .Or. ParamIXB[1] = 1)//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

   If SC5->C5_FILIAL $ _cFilHabilit // Filiais habilitadas na integracao Webservice Italac x RDC.
      If SC5->C5_I_ENVRD == "S"
         If ParamIXB[1] = 4 .And. !FWIsInCallStack("U_ALTERAP") .And. !FWIsInCallStack("U_AOMS085B")// Alteração desde que não seja via webservice do RDC

            _cTextoMsg := 'O pedido '+SC5->C5_NUM+ " pedido já foi integrado ao sistema TMS e não pode ser alterado."

            U_MT_ITMSG(_cTextoMsg ,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+SC5->C5_NUM,;
               "Solicite o retorno do pedido para o Protheus.",1)

         ElseIf ParamIXB[1] = 5 .Or. ParamIXB[1] = 1//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

            _cTextoMsg := 'O pedido '+SC5->C5_NUM+ " pedido já foi integrado ao sistema TMS e não pode ser excluido."

            U_MT_ITMSG(_cTextoMsg,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+SC5->C5_NUM,;
               "Solicite o retorno do pedido para o Protheus.",1)

         EndIf
         lRet := .F.
      EndIf
   EndIf
EndIf

//==============================================================================================================
//Se já foi retornado do RDC e não For integração WEbservice deve preencher o campo C5_I_ENVRD com "N"
//Se não enviou ainda continua na pendência de enviar, se estiver como S ou R coloca para reenviar de imediato
//=============================================================================================================
If ParamIXB[1] = 4 .And. !_laoms074 .And. !FWIsInCallStack("U_ALTERAP") .And. !FWIsInCallStack("U_AOMS085B") .And. M->C5_TIPO = "N"  // Alteração desde que não seja via webservice do RDC
   M->C5_I_ENVRD := "N"
EndIf

//==============================================================================================================
// Valida operação exclusiva para cliente Chep ( 50)
//==============================================================================================================

If lRet .And. !FWIsInCallStack("U_ALTERAP") .And. !_laoms074 .And. !_l108 .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4) .And. !(FUNNAME() = 'OMSA200')

    _coper50 := AllTrim( SuperGetMV('IT_CHEPCLS',.T.,'') ) //Operação exclusiva para cliente Chep
    _coper51 := AllTrim( SuperGetMV('IT_CHEPCLN',.T.,'' ) ) //Operação exclusiva para cliente não Chep


    //Valida operação 50 para clientes cadastrados no Chep
    If lRet .And. M->C5_I_OPER = _coper50 .And. (M->C5_TIPO != 'N' .Or. Len(AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_I_CCHEP"))) != 10)

        U_MT_ITMSG( "Operação " + _coper50 + " é exclusiva para clientes cadastrados na Chep",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                     "Altere o tipo de operação válida para cliente não Chep e tipo do pedido para Normal.",1)

        lRet := .F.

    EndIf

    //Valida operação 51 só para clientes não cadastrados no chep
    If lRet .And. M->C5_I_OPER = _coper51 .And. (M->C5_TIPO != 'N' .Or.Len(AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_I_CCHEP"))) == 10)

        U_MT_ITMSG( "Operação " + _coper51 + " é exclusiva para clientes não cadastrados na Chep",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                     "Altere o tipo de operação válida para cliente Chep e tipo do pedido para Normal.",1)

        lRet := .F.
    EndIf
EndIf

//================================================================================
// Validacao para a filial 91 - Manual
//================================================================================
If cFilAnt = "91" .And. lRet .And. !_l108 .And. !_laoms074 .And. M->C5_TIPO = "N"
   M410Proc(oProc,"Filial 91")
   lRet:= U_AOMS058(4)
EndIf

//=================================================================================================================
// Validacao do Projeto de unificação de pedidos de troca nota
//=================================================================================================================
If  lRet .And. !_l108 .And. !_laoms074 .And. M->C5_TIPO = "N"  .And. ParamIXB[1] <> 5 .And. ParamIXB[1] <> 1//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

    M410Proc(oProc,"Troca NF")
   _aAreaSC5:=SC5->(GetArea())

  //Só valida quando NÃO chamar da tela de Estorno de classificação e no estorno do doc da carga
   If M->C5_I_TRCNF = "S" .And. !(FUNNAME()) $ "MATA140,MATA521B,MATA460B,MATA103" .And. !(FWIsInCallStack("U_AOMS099"))  .And. !(FWIsInCallStack("M520_VALID")) .And. !(FWIsInCallStack("OMS200DELPV"))

      If lRet .And. M->C5_TIPO # "N"
         U_MT_ITMSG('O pedido '+M->C5_NUM +  " foi marcado como troca nota que só pode ser usado com Pedido do Tipo Normal",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+SC5->C5_NUM,;
                        'Altere o tipo do Pedido para "N"-Normal',1)
         lRet := .F.
      EndIf

      If lRet .And. !Empty(M->C5_I_FILFT+M->C5_I_FLFNC) .And. M->C5_I_FILFT == M->C5_I_FLFNC
         U_MT_ITMSG('Pedido: '+M->C5_NUM + " Filial de Faturamento não pode ser igual a de Carregamento",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+SC5->C5_NUM,;
                        "Altere a filial de Carregamento",1)

         lRet := .F.
      EndIf

      If lRet
         If AllTrim(SuperGetMV("IT_PRONF",.T.,"N")) == "N" //Testa a Filial atual se pode ser troca nota
            U_MT_ITMSG('Pedido '+M->C5_NUM + " Filial Atual não é troca nota: "+cFilAnt,'Atencao! (MT410TOK) Ped.: '+M->C5_NUM,;
                           "Verifique o Parametro: IT_PRONF",1)
            lRet := .F.
         EndIf
      EndIf

      If lRet
         cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+M->C5_I_FILFT,1,"")
         If Empty(M->C5_I_FILFT) .Or. Empty(cFilDes)//Testa se a filial de faturamento foi preenchida e existe no ZZM
            U_MT_ITMSG('Pedido: '+M->C5_NUM + " Filial de Faturamento nao preenchida ou nao Cadastrada: " +M->C5_I_FILFT,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Preencha uma filial cadastrada",1)

            lRet := .F.
         EndIf
      EndIf

      If lRet
         _cFilSalva:= cFilAnt
         cFilAnt   := M->C5_I_FILFT
         If AllTrim(SuperGetMV("IT_FATNF",.T.,"N")) == "N" //Testa a filial de Faturamento
           U_MT_ITMSG('Pedido: '+M->C5_NUM + " Filial de Faturamento não é troca nota: "+cFilAnt,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Verifique o Parametro: IT_FATNF",1)
            lRet := .F.
         EndIf
         cFilAnt := _cFilSalva
      EndIf

      If lRet//AWF - 18/11/2016
         cFilsFat:= AllTrim(GetAdvFVal("ZZM","ZZM_FILFAT",xFilial("ZZM")+M->C5_I_FLFNC,1,""))
         If Empty(cFilsFat)//Testa se a filial de faturamento esta no grupo do campo ZZM
           U_MT_ITMSG('Pedido '+M->C5_NUM + " Filial de Carregamento: "+M->C5_I_FLFNC+" não possui grupo de Filiais de Faturamento",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",1)
           lRet := .F.
         ElseIf !M->C5_I_FILFT $ cFilsFat//Testa se a filial de faturamento esta no grupo do campo ZZM
           U_MT_ITMSG('Pedido '+M->C5_NUM + "Filial de Faturamento "+M->C5_I_FILFT+" nao esta no grupo de filiais ("+cFilsFat+") da Filial de Carregamento: "+M->C5_I_FLFNC,;
                               'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",1)
            lRet := .F.
         EndIf
      EndIf

      SC5->( DBSetOrder(1) )
      If lRet .And. !Empty(M->C5_I_FLFNC) .And. M->C5_I_FLFNC <> SC5->C5_FILIAL //Validaco se o usuario estiver na Filial de Faturamento Pedido de Faturamento de troca nota
         If !Empty(M->C5_I_PDPR) .And. SC5->( DBSeek( M->C5_I_FLFNC + M->C5_I_PDPR ) )
            U_MT_ITMSG('Pedido '+M->C5_NUM +  " nao pode ser alterado por possuir um Pedido de Carregamento: "+M->C5_I_FLFNC +" "+ M->C5_I_PDPR,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Estorne o Documento de Transferencia",1)
            lRet := .F.
         EndIf
      EndIf

      If lRet .And. !Empty(M->C5_I_FILFT) .And. M->C5_I_FILFT <> SC5->C5_FILIAL//Validaco se o usuario estiver no Pedido de Carregamento de troca nota
         If !Empty(M->C5_I_PDFT) .And. SC5->( DBSeek( M->C5_I_FILFT + M->C5_I_PDFT ) )
               U_MT_ITMSG('Pedido '+M->C5_NUM + " nao pode ser alterado por possuir um Pedido de Faturamento: "+M->C5_I_FILFT +" "+ M->C5_I_PDFT,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Estorne o Documento de Transferencia",1)
            lRet := .F.
         EndIf
      EndIf

      If lRet .And. !Empty(M->C5_I_FILFT) .And. M->C5_I_FILFT <> SC5->C5_FILIAL//validacao para nao transferir um numero de pedio que já exista na filial de faturamento
         If SC5->( DBSeek( M->C5_I_FILFT + M->C5_NUM ) )//seek do numero atual na filial de faturamento
            U_MT_ITMSG('Pedido: '+M->C5_NUM + "nao pode ser alterado para troca nota por que já existe mesmo número na filial de Faturamento: "+M->C5_I_FILFT,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                           "Faça uma copia desse pedido para gerar um numero novo e altere a copia para troca nota.",1)
            lRet := .F.
         EndIf
      EndIf

      _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação triangular
      lAchouZPE:=.F.

       If lRet .And. !M->C5_I_OPER $ "50/51" .And. ZPE->(DBSeek(xFilial("ZPE")))//Codigo se segurança para quando não tiver nada cadastrado não validar

            ZPE->(DBSetOrder(3))//ZPE_FILIAL+ZPE_GERCOD+ZPE_ESTADO+ZPE_OPERAC+ZPE_ADQUIR+ZPE_ADQLOJ+ZPE_FILCAR+ZPE_FILFAT
               _cProdZPF:=""
               If ZPE->(DBSeek(xFilial("ZPE")+M->C5_VEND3+M->C5_I_EST))

                  While ZPE->(!Eof()) .And. xFilial("ZPE")+ZPE->ZPE_GERCOD+ZPE->ZPE_ESTADO == ZPE->ZPE_FILIAL+M->C5_VEND3+M->C5_I_EST

                  If M->C5_I_OPER $ ZPE->ZPE_OPERAC
                     If !(M->C5_I_OPER $ _cOperTriangular) .Or. ZPE->ZPE_ADQUIR+ZPE->ZPE_ADQLOJ == M->C5_I_CLIEN+M->C5_I_LOJEN
                        If M->C5_I_FLFNC $ AllTrim(ZPE->ZPE_FILCAR) .And. M->C5_I_FILFT $ AllTrim(ZPE->ZPE_FILFAT)
                           If ZPE->ZPE_MSBLQL <> "1"
                              lAchouZPE:=.T.
                           EndIf
                        EndIf
                        EndIf
                     EndIf

                      If lAchouZPE

                      For _nnipre := 1 To Len(acols)
                           If aCols[_nnipre][Len(aCols[_nnipre])]// SE LINHA DELETADA
                              Loop
                           EndIf
                           _cProdSZPF:=acols[_nnipre][nPosProduto]
                              ZPF->(DBSetOrder(1))//ZPF_FILIAL+ZPF_CODIGO+ZPF_PROCOD+ZPF_GRUPO
                           If !ZPF->(DBSeek(xFilial("ZPF")+ZPE->ZPE_CODIGO+_cProdSZPF)) .Or. ZPF->ZPF_MSBLQL = "1"
                                  ZPF->(DBSetOrder(2))//ZPF_FILIAL+ZPF_CODIGO+ZPF_GRUPO+ZPF_PROCOD
                               If !ZPF->(DBSeek(xFilial("ZPF")+ZPE->ZPE_CODIGO+LEFT(_cProdSZPF,4))) .Or. ZPF->ZPF_MSBLQL = "1"
                                       lAchouZPE:=.F.
                                       If !AllTrim(_cProdSZPF) $ _cProdZPF
                                          _cProdZPF+=" ["+AllTrim(_cProdSZPF)+If(ZPF->ZPF_MSBLQL='1'," (B)","")+"]"
                                       EndIf
                                   EndIf
                           EndIf
                      Next

                       EndIf

                       ZPE->(DBSkip())

                   EndDo

                If !lAchouZPE
                    lRet := .F.
                    If !Empty(_cProdZPF)
                        U_MT_ITMSG('Gerente: '+M->C5_VEND3+"-"+AllTrim(Posicione("SA3",1,xFilial("SA3")+M->C5_VEND3,"A3_NOME"))+", UF: "+M->C5_I_EST+", Oper.: "+M->C5_I_OPER+;
                                   ", Cliente: "+M->C5_CLIENTE+M->C5_LOJACLI+"-"+AllTrim( Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NREDUZ"))+;
                                   " e Filiais da Troca Nota: "+M->C5_I_FLFNC+" / "+M->C5_I_FILFT+" não pertence ao grupo de filiais autorizadas cadastradas (ZPF) para esses Produtos: "+_cProdZPF,'Atencao!',;
                                   "Cadastre um grupo de filiais de Troca Nota para esse gerente, estado, Operacao, Filiais da Troca Nota e Produtos ou Grupos (ZPE/ZPF).",1)
                    Else
                        U_MT_ITMSG('Gerente: '+M->C5_VEND3+"-"+AllTrim(Posicione("SA3",1,xFilial("SA3")+M->C5_VEND3,"A3_NOME"))+", UF: "+M->C5_I_EST+", Oper.: "+M->C5_I_OPER+;
                                   ", Cliente: "+M->C5_CLIENTE+"-"+M->C5_LOJACLI+"-"+AllTrim( Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NREDUZ") )+;
                                   " e Filiais da Troca Nota: "+M->C5_I_FLFNC+" / "+M->C5_I_FILFT+" não pertencem a nenhum grupo de filiais autorizadas cadastradas p/ Troca NF (ZPE).",'Atencao!',;
                                   "Cadastre um grupo de filiais de Troca Nota para esse gerente, estado, Operacao, Filiais da Troca Nota e Produtos ou Grupos (ZPE).",1)
                    EndIf
                EndIf

            ElseIf !lAchouZPE
                 U_MT_ITMSG('Gerente: '+M->C5_VEND3+"-"+AllTrim(Posicione("SA3",1,xFilial("SA3")+M->C5_VEND3,"A3_NOME"))+", UF: "+M->C5_I_EST+", Oper.: "+M->C5_I_OPER+;
                            ", Cliente: "+M->C5_CLIENTE+"-"+M->C5_LOJACLI+"-"+AllTrim( Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NREDUZ") )+;
                            " e Filiais da Troca Nota: "+M->C5_I_FLFNC+" / "+M->C5_I_FILFT+" não pertencem a nenhum grupo de filiais autorizadas cadastradas p/ Troca NF (ZPE).",'Atencao!',;
                            "Cadastre um grupo de filiais de Troca Nota para esse gerente, estado, Operacao, Filiais da Troca Nota e Produtos ou Grupos (ZPE).",1)
                 lRet := .F.
            EndIf


           EndIf

   ElseIf M->C5_I_TRCNF = "N"

      If Empty(M->C5_I_PDFT) .And. Empty(M->C5_I_PDPR)
         M->C5_I_FLFNC:=Space(Len(SC5->C5_I_FLFNC))
         M->C5_I_FILFT:=Space(Len(SC5->C5_I_FILFT))
      EndIf

   EndIf

   FWRestArea(_aAreaSC5)
   FWRestArea(_aArea)

ElseIf  lRet .And. !_l108 .And. !_laoms074 .And. M->C5_I_TRCNF = "S"

    If M->C5_TIPO # "N"
       U_MT_ITMSG('O pedido '+M->C5_NUM +  " foi marcado como troca nota que só pode ser usado com Pedido do Tipo Normal",'Atencao!',;
                  'Altere o tipo do Pedido para "N"-Normal',1)
       lRet := .F.
    EndIf

EndIf

SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial('SA1') + M->( C5_CLIENTE + C5_LOJACLI ) ) )

//================================================================================
// Verifica se o ponto de entrada está sendo chamado da rotina de Efetivação
// do Pedido de Vendas (AOMS112), caso afirmativo, verifica se a variável de
// memória M->C5_I_AGEND está preenchida ou não. Caso a variável _cTpAgenda
// definida no fonte exista e possua conteúdo e a variável M->C5_I_AGEND esteja
// vazia, o conteúdo da variável _cTpAgenda é atribuido a variável:
//  M->C5_I_AGEND := _cTpAgenda.
// Obs.: A chamada do ponto de entrada MT410TOK estava limpando o conteúdo da
// da variável M->C5_I_AGEND.
//================================================================================
If _lAoms112
   If Empty(M->C5_I_AGEND) .And. Type("_cTpAgenda") == "C"
      If !Empty(_cTpAgenda)
         M->C5_I_AGEND := _cTpAgenda
      EndIf
   EndIf
EndIf

//================================================================================
// Validação do tipo de entrega
//================================================================================
If lRet .And. !_l108 .And. !_laoms074 .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4) .AND.;
   M->C5_TIPO = "N" .And. M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26") .AND.;
  !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003")  .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID"))

   M410Proc(oProc,"Tipo de entrega")
   If Empty(M->C5_I_AGEND)
      U_MT_ITMSG(' Pedido  '+M->C5_NUM + " Tipo de Entrega não preenchido.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                     'Preencher Tipo de Entrega, um dos ultimos campos da primeira pasta.',1)
      lRet := .F.

   ElseIf M->C5_I_AGEND = 'M' .And. SA1->A1_I_AGEND <> M->C5_I_AGEND//Quando o PV é M o Cliente tem que ser tb

     U_MT_ITMSG('Pedido '+M->C5_NUM + " Tipo de Entrega do Cliente ["+U_TipoEntrega(SA1->A1_I_AGEND)+"] diferente do informado no Pedido [M].", 'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM, ;
                     'Cliente não pode ser Agendado c/ multa. Altere o Tipo de Entrega do Pedido para DIFERENTE de [M – AGENDADA C/ MULTA]',1)
      lRet := .F.
   EndIf

EndIf

If Inclui .Or. Altera
   If SA1->A1_I_BLQDC == "1" .And. M->C5_TIPO = "N"//Bloqueio por deconto contratual

     U_MT_ITMSG("Cliente com bloqueio de Desconto Contratual.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Favor procurar o departamento de Contratos para solicitar o desbloqueio.",1)
     lRet := .F.

   EndIf
EndIf

//==================================================================
// Na criação/alteração do Pedido de Operação Triangular 42,
// Verifica se existe TES para o Pedido de Destino Operação 05.
//==================================================================  
_cItemOpeT := ""
If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
   If M->C5_I_OPER == _cOperRemessa .And. ! Empty(M->C5_I_CLIEN)
      SA1->(MsSeek(xFilial("SA1") + M->C5_I_CLIEN + M->C5_I_LOJEN))
      _cSuframa := If(!Empty(SA1->A1_SUFRAMA),"S","N")
      //_cCpoSN   := If(SA1->A1_SIMPNAC="1","S","N")
      //_cCpoCI   := If(SA1->A1_CONTRIB="2","N","S")
      _cEstCli  := SA1->A1_EST
      _cEstFil  := SM0->M0_ESTCOB
   EndIf 
EndIf 
//================================================================================
// Processa todos os itens do Pedido
//================================================================================
While nX <= Len(aCols) .And. lRet .And. !_l108 .And. !_laoms074
   //================================================================================
   // Muda o valor de N
   //================================================================================
   N := nX

   //================================================================================
   M410Proc(oProc,"Regras do Item "+aCols[nX][nPosIte])

   //================================================================================
   // ****************  REGRA DE BLOQUEIO DE VENDAS DO PEDIDO  *********************
   _cMenBroqueio:=""
   If lRet .And.  M->C5_I_TRCNF <> "S" .And. M->C5_TIPO = "N" .And. Inclui .And. !(FunName() $ "OMSA200,MATA140,MATA521B,MATA460B,MATA103") .And. !(FWIsInCallStack("U_AOMS099"));
    .And. !(FWIsInCallStack("U_AOMS099"))  .And. !(FWIsInCallStack("M520_VALID"))
    If U_BloqueiaPV(M->C5_CLIENTE,M->C5_LOJACLI,aCols[nX][nPosProduto],@_cMenBroqueio,M->C5_I_OPER)
        U_MT_ITMSG('Pedido '+M->C5_NUM + " " + _cMenBroqueio,'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,;
                   "Existe regra de bloqueio de faturamento para as condições acima deste pedido. Duvidas procurar o departamento fiscal.",1)
         lRet:=   .F.
         Exit
      EndIf
   EndIf
   // ****************  REGRAS DE BLOQUEIO DE VENDAS DO PEDIDO  *********************
   //================================================================================

    If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;

       If !(FWIsInCallStack("U_AOMS074"))
          aCols[nX][_nPosQPale] := U_AOMS010() // Recalcula quantidade de Pallets
       EndIf

       //======================================================
       // Atualiza campo Centro de Custo do Item C6_CC.
       //======================================================
       M->C6_PRODUTO := aCols[nX][nPosProduto]
       aCols[nX][_nPosCC] := U_ACOM034G()
       //======================================================

        aCols[nX][nPosPedCli]:= StrTran( StrTran( StrTran( aCols[nX][nPosPedCli] , "ª" , "" ) , "º" , "" ) , CHAR(176) , "" ) // VERIFICAR O PEDIDO DO CLIENTE NÃO CONTEM CARACTER ESPECIAL
          aCols[nX][_nPosItPc] := aCols[nX][nPosIte]
          cTes                 := GetAdvFVal( "SF4" , "F4_DUPLIC" , xFilial("SF4") + aCols[nX][nPosTes] , 1 , "" )

         If !GdDeleted(nX) .And. M->C5_TIPO = "N" .And. cTes == "S" .And. !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE") .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103")  .And. !_lAoms112 ;
            .And. AllTrim(aCols[nX][nPosProduto]) <> _cchep
            If !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID")) .And. !(AllTrim(aCols[nX,_cCFOP]) $ '5910/6910/5911/6911') .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5  .And. !(FWIsInCallStack("U_AOMS098")) //EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
                If _lItemAlterado .Or. Inclui  .Or. ( AllTrim(SC5->C5_CLIENTE) != AllTrim(M->C5_CLIENTE) .And. AllTrim(SC5->C5_LOJACLI) != AllTrim(M->C5_LOJACLI))

                    _aBlqprc  := U_BLQPRC(aCols[nX][nPosProduto],aCols[nX][nPosPreco],SC5->C5_FILIAL,.F., M->C5_I_TAB,,_lusanovo,, .T., _cGrupoP,_cUFPedV ,         ,         ,_lSimplNac,nPsBru,0)
                    _lPrcErr  := _aBlqprc[1]
                    _nFaixa   := _aBlqprc[2]
                    _cMsgPrc  := _aBlqprc[3]  // Grupo de estoque do produto.
                    _nPrecoIt := _aBlqprc[4]
                    _nPrecoMin:= _aBlqprc[5]

                    M->C5_I_FXPES := _nFaixa

                    If _lPrcErr
                        lBlq3   			:= .T.
                        _lbloq4				:= .T.
                        M->C5_I_BLPRC		:= "B"
                        M->C5_I_DTLIB		:= CTOD("")
                        aCols[nX][nPosBlPrc] := "B"
                        //Se tem liberacao  de preco mas não passou na validacao verifica se o preco e prazo de liberacao estao ok
                        //Se tem liberacao  de preco mas não passou na validacao verifica se cliente e loja é igual ao original
                    EndIf
                    aCols[nX][nPosVlTab]  := _nPrecoIt
                    aCols[nX][nPosPrMin]  := _nPrecoMin
                EndIf
            EndIf
        EndIf

        If Inclui .Or. Altera
            //================================================================================
            // VERIFICAR UNIDADES DE MEDIDA
            //================================================================================
            If lRet .And. !_laoms074 .And. M->C5_TIPO = "N"
                If !aCols[nx,Len(aHeader)+1] // Se Linha Nao Deletada
                    cPosPrd	:= aScan( aHeader , {|nx| Upper(AllTrim(nx[2]) ) == "C6_PRODUTO" } )
                    cNumPrd	:= AllTrim( Acols[nx][cPosPrd] )
                    cFatCon	:= Posicione( "SB1" , 1 , xFilial("SB1") + cNumPrd			, "B1_I_SFCON" )
                    cQtdZero	:= Posicione( "SF4" , 1 , xFilial("SF4") + aCols[n,nPosTes]	, "F4_QTDZERO" )

                    nPosDifPe 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_DIFPE"  } )
                    cDifPe			:= acols[n,nPosDifPe]

                    SB1->( DBSetOrder(1) )
                    SB1->( DBSeek( xFilial("SB1") + cNumPrd ) )

                    If cDifPe == "S"

                        If lPrim

                            If U_MT_ITMSG("Ped.: " + M->C5_NUM + " Devolução é referente a Diferença de Pesagem entre a Italac e o Cliente?",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,,3,2,2 )
                                lDifPes := .T.
                            Else
                                If cFatCon == "1"

                                    _lSegDIf := VldPeca(nx)

                                    If !_lSegDif
                                        acols[n,nPosDifPe] := "N"
                                    EndIf
                                EndIf
                            EndIf

                        EndIf

                        If !_lSegDIf .And. !lDifPes

                            If !Empty(aItens)

                                For y := 1 To Len(aItens)

                                    cItens += aItens[y][1] +" "
                                    cItens += aItens[y][2] +" "
                                    cItens += CVALTOCHAR( aItens[y][3] ) +" / "
                                    cItens += CVALTOCHAR( aItens[y][4] ) +" = "
                                    cItens += CVALTOCHAR( aItens[y][5] ) +CHR(13)+CHR(10)

                                Next y


                                U_MT_ITMSG('Pedido '+M->C5_NUM + " Quantidades informadas (Quantidade/Qtd. 2a UM) não correspondem aos limites de fator de conversão."	,;
                                            'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Verifique as quantidades informadas para o(s) produto(s):"+ CHR(13) + CHR(10) + cItens + " ",1 )

                                lRet := .F.

                            EndIf

                        EndIf

                        lPrim := .F.
                        VldDev(nx)


                    Else
                        If cFatCon == "1"
                            _lSegDIf := VldPeca(nx)

                            If !_lSegDif
                                acols[n,nPosDifPe] := "N"
                            EndIf
                        EndIf

                        If !_lSegDif

                            If !Empty(aItens)

                                For y := 1 To Len(aItens)
                                    cItens += aItens[y][1] +" "
                                    cItens += aItens[y][2] +" "
                                    cItens += CVALTOCHAR( aItens[y][3] ) +" / "
                                    cItens += CVALTOCHAR( aItens[y][4] ) +" = "
                                    cItens += CVALTOCHAR( aItens[y][5] ) +CHR(13)+CHR(10)
                                Next y

                                U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Quantidades informadas (Quantidade/Qtd. 2a UM) não correspondem aos limites de fator de conversão."	,;
                                            'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Verifique as quantidades informadas para o(s) produto(s):"+ CHR(13) + CHR(10) + cItens + " ",1 )

                                lRet := .F.

                            EndIf

                        EndIf
                    EndIf

                EndIf

            EndIf
        EndIf
        //================================================================================
        //  Valida o preenchimento da segunda unidade de medida
        //================================================================================
         If lRet .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID"))  //NÃO VALIDA NAS MOVIMENTAÇÕES DE PEDIDO DO TROCA NOTA
            lRet := U_AOMS050(1,aCols[n,nPosTes],lDifPes)
        EndIf

    EndIf

    If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
       //================================================================================
       // Valida NCM informado no cadastro do produto.
       //================================================================================
       If lRet .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID")) .And. _cTipoPedido !="T" //NÃO VALIDA NAS MOVIMENTAÇÕES DE PEDIDO DO TROCA NOTA
           lRet := U_AOMS050(2)
       EndIf

       //===============================================================================
       // Replica Data de Entrada Informada na C5 para C6
       //================================================================================
       If lRet .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID")) .And. _cTipoPedido !="T" .And. !_lAoms112 //NÃO VALIDA NAS MOVIMENTAÇÕES DE PEDIDO DO TROCA NOTA
         lRet := U_AOMS050(3)
       EndIf
       //================================================================================
       // Funcao responsavel por efetuar a validacao no pedido de venda para constatar se
       // o produto indicado na linha corrente possui regra de comissao amarrada para o
       // vendedor indicado no pedido de venda desta forma proibindo que se inclua um
       // pedido de venda sem autorizacao
       //================================================================================
       If lRet .And. M->C5_TIPO == 'N' .AND.;
          !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003").and. !(FWIsInCallStack("M520_VALID"));
          .And. !(FWIsInCallStack("U_AOMS099"))  //NÃO VALIDA NAS MOVIMENTAÇÕES DE PEDIDO DO TROCA NOTA
          lRet:= U_AOMS049(M->C5_VEND1,.T., M->C5_CLIENTE,M->C5_LOJACLI,_cRedeCliente)
       EndIf

       //================================================================================
       // Chama a funcao de recalculo da comissao
       //================================================================================
       If M->C5_TIPO = "N"
           U_AOMS013(.T.)
       EndIf

       //================================================================================
       // Validar preco do produto com a tabela de preço de transferencias
       // somente quando não é troca nota
       //================================================================================
       If M->C5_I_OPER $ SuperGetMV("IT_OPMEDIO",.F.,'20|22') .And. !GdDeleted(nx) .And. !(M->C5_I_TRCNF = "S") .And.  M->C5_TIPO = "N" .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !_lAoms112 .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID")) //NÃO VALIDA NAS MOVIMENTAÇÕES DE PEDIDO DO TROCA NOTA
          _ccodipro := U_ITVLPRTR( M->C5_I_OPER , GdFieldGet( "C6_PRODUTO" , nx ) , GdFieldGet( "C6_PRCVEN" , nx ), 2 )
          If Len(AllTrim(_ccodipro)) > 1
             aAdd(_aprod,_ccodipro)  //se tem problema vai adicionando na matriz para mostrar todos de uma vez
          EndIf
       EndIf

       //===============================================================================
       //Valida se o armazém é para faturamento - Conforme cadastro "Locais de estoque"
       //Se operação estiver no campo de exceção para faturamento deixa faturar mesmo
       // que Local de estoque não seja de faturamento
       //===============================================================================
       If lRet
          _cAmFatP := Posicione("NNR",1,xFilial("NNR")+aCols[nx,nPosLoc],"NNR_I_AMFT")
          _cAmDevo := Posicione("NNR",1,xFilial("NNR")+aCols[nx,nPosLoc],"NNR_I_AMDE")
          If _cAmFatP == "N" .And. !( AllTrim(M->C5_I_OPER) $ AllTrim(NNR->NNR_I_EXFT) ) .And. !(M->C5_TIPO == 'D' .And. _cAmDevo == "S")
                lRet := .F.
                U_MT_ITMSG("O Local informado: " + AllTrim(aCols[nx,nPosLoc]) + " , não é um armazém válido para faturamento.","Alerta",;
                "Favor informar outro armazém.",1)
          EndIf
       EndIf

    EndIf

    aAdd(_aItensLock, { aCols[nX][nPosProduto] , aCols[nX][nPosAmz] })
    If aCols[nX][nPosBlPrc] == "B"
       _lbloq4 := .T.  //Existe Item Bloqueado, então bloquear C5_I_BLPRC
    EndIf

    //==================================================================
    // Na criação/alteração do Pedido de Operação Triangular 42,
    // Verifica se existe TES para o Pedido de Destino Operação 05.
    //==================================================================
    If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
       If M->C5_I_OPER == _cOperRemessa .And. ! Empty(M->C5_I_CLIEN)
          _cTESOperT := U_SelectTES(aCols[nX][nPosProduto],_cSuframa,_cEstCli,_cEstFil,M->C5_I_CLIEN,M->C5_I_LOJEN,"05",aCols[nX][nPosAmz],M->C5_TIPO)
          If Empty(_cTESOperT)
             _cItemOpeT += aCols[nX][nPosProduto] + "-" + Posicione("SB1",1,xFilial("SB1")+aCols[nX][nPosProduto],"B1_DESC") +"; "
          EndIf 
       EndIf 
    EndIf 

    //====================================================================================== 
    // Quando o MSExecAuto For rodado da rotina de Transferência de Pedidos de Vendas,
    // Faz a atualização da TES na unidade de destino.
    // O Trigger automático atualiza a TES, mas é sobreposta pela TES da filial de Origem.
    //======================================================================================
    If ParamIXB[1] == 3 .And. FWIsInCallStack('U_AOMS032EXE')
       SA1->(MsSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI))
       _cSuframa   := If(!Empty(SA1->A1_SUFRAMA),"S","N")
       _cTESTrans  := U_SelectTES(aCols[nX][nPosProduto],_cSuframa,SA1->A1_EST,SM0->M0_ESTCOB,M->C5_CLIENTE,M->C5_LOJACLI,M->C5_I_OPER,aCols[nX][nPosAmz],M->C5_TIPO)
       aCols[nX][nPosTes] := _cTESTrans 

       _cCFTransf := " "
       _aDadosCfo := {}

       SF4->(DBSetOrder(1))
       If SF4->(DBSeek(xFilial("SF4") + _cTESTrans))     
          aAdd(_aDadosCfo,{"OPERNF","S"})
          aAdd(_aDadosCfo,{"TPCLIFOR",M->C5_TIPOCLI})					
          aAdd(_aDadosCfo,{"UFDEST"  ,If(M->C5_TIPO $ "DB",SA2->A2_EST,SA1->A1_EST)})
          aAdd(_aDadosCfo,{"INSCR"   ,If(M->C5_TIPO$"DB",SA2->A2_INSCR,SA1->A1_INSCR)})
          _cCFTransf := MaFisCfo(,SF4->F4_CF,_aDadosCfo) 
       EndIf 

       aCols[n,_cCFOP] :=_cCFTransf 

    EndIf 

    nX++

EndDo

//==================================================================
// Na criação/alteração do Pedido de Operação Triangular 42,
// Verifica se existe TES para o Pedido de Destino Operação 05.
//==================================================================
If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
   If M->C5_I_OPER == _cOperRemessa .And. ! Empty(_cItemOpeT)
      U_MT_ITMSG("Não existem TES cadastradas para algum(uns) item(ns) do Pedido de Vendas de Operação Triangular 05.",;   //,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                 'Atencao!',"Para gravar o Pedido de Vendas de Operação Triangular 42, deve-se cadastrar a TES dos itens do Pedido de Vendas de Operação Triangular 05.",1     ,       ,        ,         ,     ,     ,{|| U_ITMSGLOG(_cItemOpeT,"Itens sem TES cadastrada para Pedido de Operação Triangular 05.") }, _cItemOpeT)
      lRet := .F.
   EndIf 
EndIf 

//======================================================================
// Valida a data de entrega uma única vez na capa do pedido de vendas.
//======================================================================
If lRet
   If funname() == "MATA410" .And. (FWIsInCallStack('A410PCopia') .Or.  !INCLUI .And. M->C5_I_DTENT != SC5->C5_I_DTENT ) .Or. ( INCLUI .And. M->C5_I_AGEND != "P")  //Só valida na alteração de houver mudança da data de entrega
      If (M->C5_I_AGEND <> 'P') .Or. !INCLUI .And. M->C5_I_DTENT != SC5->C5_I_DTENT  // ( INCLUI .And. M->C5_I_AGEND != "P") // M->C5_I_AGEND == 'I'
         //Sempre valida na inclusão e entrega imediata e na alteração de data de entrega
         _cFilCarreg := xFilial("SC5")
         If ! Empty(M->C5_I_FLFNC)
            _cFilCarreg := M->C5_I_FLFNC
         EndIf

         lRet:= U_OMSVLDENT(M->C5_I_DTENT, M->C5_CLIENT, M->C5_LOJACLI, M->C5_I_FILFT, M->C5_NUM,0    ,      ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN) //Valida data de entrega
      EndIf
   EndIf
EndIf

//================================================================================================
// Valida se a data de entrega é maior que a data máxima de agendamento para pedidos agendados.
//================================================================================================
If lRet 
   If funname() == "MATA410" .And. (INCLUI .Or. ALTERA)
      If (M->C5_I_AGEND == 'A' .Or. M->C5_I_AGEND == 'M')  //A=AGENDADA;I=IMEDIATA;M=AGENDADA C/MULTA;P=AGUARD. AGENDA;R=REAGENDAR;N=REAGENDAR C/MULTA;T=Agend. pelo Transp;O=AGENDADO PELO OP.LOG
        	                  // U_OMSVLDENT(M->C5_I_DTENT, M->C5_CLIENT, M->C5_LOJACLI, M->C5_I_FILFT, M->C5_NUM,0    ,      ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN) //Valida data de entrega
         _dDtAgeEnt := Date()+U_OmsVldEnt(Date()       , M->C5_CLIENT,M->C5_LOJACLI,M->C5_I_FILFT  ,M->C5_NUM ,1    ,.F.   ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN)

		   _dDtAgeMax := U_DTVAL112(_dDtAgeEnt)

         If M->C5_I_DTENT >_dDtAgeMax
            U_MT_ITMSG("A data de entrega: "+DToC(M->C5_I_DTENT) +",  não pode ser maior que a data máxima permitida para agendamento: " + DToC(_dDtAgeMax) +".",'Validação Data de Entrega',,1 )
            lRet := .F.
         EndIf 

      EndIf 
   EndIf 
EndIf 

//********************** VALIDACAO NOVA DE CREDITO UNIFICADA ***************************************************//
If lRet .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !_lAoms112 .And. !(FWIsInCallStack("U_AOMS099")) .And. M->C5_TIPO = 'N' .And. (Inclui .Or. Altera) .And. !_l108 .And. !_laoms074 .And. !(FWIsInCallStack("M520_VALID"))

    M410Proc(oProc,"Credito Unificado")
    _nTotPV:=0
    _lValCredito:=.T.
    
    For _nI := 1 To Len(acols)

       If !GdDeleted(_nI)

           _nTotPV += acols[_nI][nPosVal]

          If AllTrim(aCols[_nI][nPosProduto]) == _cchep .Or. AllTrim(aCols[_nI,_cCFOP]) $ '5910/6910/5911/6911'//NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
             _lValCredito:=.F.
             Exit
          EndIf

          If Posicione("SF4",1,xFilial("SF4")+aCols[_nI,nPosTes],"F4_DUPLIC") != 'S' //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA
             _lValCredito:=.F.
             Exit
          EndIf

          If Posicione("ZAY",1,xFilial("ZAY")+ AllTrim(aCols[_nI,_cCFOP]) ,"ZAY_TPOPER") != 'V' //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
             _lValCredito:=.F.
             Exit
          EndIf

       EndIf

    Next _nI

    If _lValCredito
    
         If M->C5_I_OPER == _cOperRemessa .And. !Empty(M->C5_I_CLIEN)
            __cCodCli := M->C5_I_CLIEN
            __cLojaCli := M->C5_I_LOJEN
         Else
            __cCodCli := M->C5_CLIENTE
            __cLojaCli := M->C5_LOJACLI
         EndIf
         
         _aRetCre := U_ValidaCredito( _nTotPV , __cCodCli , __cLojaCli , Altera , , , , M->C5_MOEDA,Inclui,M->C5_NUM, M->C5_VEND3, M->C5_VEND2, M->C5_VEND4, M->C5_VEND1)
         _cBlqCred:=_aRetCre[1]

         If _aRetCre[2] = "B"//Se bloqueou

            If M->C5_I_BLCRE == "R"

                U_MT_ITMSG("Pedido " + M->C5_NUM + " Avaliação de crédito do pedido não foi aprovada - "	+;
                "O pedido continuará marcado como REJEITADO.",'Validação Crédito',,1 )
                lBlq2			:= .T.
                M->C5_I_BLCRE	:= "R"
                M->C5_I_DTAVA := Date()
                M->C5_I_HRAVA := Time()
                M->C5_I_USRAV := cUserName
                M->C5_I_MOTBL := _cBlqCred


            Else

                U_MT_ITMSG("Pedido " + M->C5_NUM + " Avaliação de crédito do pedido não foi aprovada - "	+;
                            "O pedido será marcado como bloqueado para posterior avaliação.",'Validação Crédito',,1 )

                lBlq2			:= .T.
                M->C5_I_BLCRE	:= "B"
                M->C5_I_DTAVA := Date()
                M->C5_I_HRAVA := Time()
                M->C5_I_USRAV := cUserName
                M->C5_I_MOTBL := _cBlqCred

            EndIf

         EndIf

        M->C5_I_MOTBL := _cBlqCred//Sempre grava a descrição

    EndIf//If _lValCredito

EndIf
//********************** VALIDACAO NOVA DE CREDITO UNIFICADA ***************************************************//

//===============================================================================
// Se bloqueiou uma das linhas por preço, bloqueia o pedido, senão libera
//===============================================================================
If _lbloq4

    M->C5_I_BLPRC := "B"
    M->C5_I_DTLIB := CTOD("")

ElseIf M->C5_I_BLPRC != "L"

    M->C5_I_BLPRC := " "
    M->C5_I_DTLIB := CTOD("")

EndIf

//===============================================================================
// Se bloqueiou uma das linhas por crédito bloqueia o pedido, senão libera
//===============================================================================

If !_lValCredito

    M->C5_I_LIBC  := 0
    M->C5_I_LIBCA := ""
    M->C5_I_LIBCT := ""
    M->C5_I_LIBL  := CTOD("")
    M->C5_I_LIBCV := 0
    M->C5_I_LIBCD := CTOD("")
    M->C5_I_BLCRE := ""
    M->C5_I_MOTBL := ""
    M->C5_I_DTLIC := CTOD("")

    M->C5_I_DTAVA := CTOD("")
    M->C5_I_HRAVA := ""
    M->C5_I_USRAV := ""

ElseIf lBlq2

    If M->C5_I_BLCRE != "R"
        M->C5_I_BLCRE	:= "B"
    EndIf
    M->C5_I_DTAVA := Date()
    M->C5_I_HRAVA := Time()
    M->C5_I_USRAV := cUserName
    M->C5_I_MOTBL := _cBlqCred

ElseIf M->C5_I_BLCRE != "L" .And. M->C5_I_LIBC != 2

    M->C5_I_BLCRE	:= ""
    M->C5_I_LIBC := 0
    M->C5_I_DTAVA := Date()
    M->C5_I_HRAVA := Time()
    M->C5_I_USRAV := cUserName
    M->C5_I_MOTBL := _cBlqCred

ElseIf M->C5_I_BLCRE != "L" .And. M->C5_I_LIBC == 2

    M->C5_I_BLCRE	:= "L"

EndIf

//================================================================================
// Se tem produto com problema de preço de transferência apresenta mensagem
// com todos de uma vez.
//================================================================================
If Len(_aprod) >= 1

    M410Proc(oProc,"Preco de transferencia")

     _ccodpro := "Para o tipo de operação "+M->C5_I_OPER+" existem produtos no pedido que não estão em conformidade com a Tabela de Preço de Transferência."
     //_ccodpro += +Space(40)+"------------------------------------------------------------------------------------------------"
     For _nY := 1 To Len(_aprod)

       _ccodpro += CRLF + AllTrim(_aprod[_ny]) + " - " + Posicione("SB1",1,xFilial("SB1")+_aprod[_ny],"B1_DESC") //+Space(20)

     Next _nY

      //================================================================================
      //Não tem tabela de preço de transferência para o produto
      //================================================================================
                //_cMens                             ,_cTitu              ,_cSolu                                            ,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
          U_MT_ITMSG('Ped.: '+M->C5_NUM + " " + _ccodpro,"Validação de preço","Favor solicitar apoio ao Departamento Comercial.",1     ,       ,        ,         ,     ,     ,{|| U_ITMSGLOG(_ccodpro,"Validação de preço") }, _ccodpro)

    lRet := .F.

EndIf

If ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 .And. !_l108 .And. !_laoms074//1-Excluir; 3-Incluir/Copiar; 4-Alterar;

    //================================================================================
    // Restaura o valor da variavel padrao
    //================================================================================
    N := nN

    //================================================================================
    // Validacao para campos C5_I_NFREF e C5_I_SERNF, quando o
    // usuario informar que eh uma nota fiscal de sedex devera necessariamente
    // informar a NF e Serie de Referencia
    //================================================================================
    If M->C5_I_NFSED == "S" .And. lRet .And. M->C5_TIPO = "N"

        lRet := (!Empty(M->C5_I_NFREF) .And. !Empty(M->C5_I_SERNF))

        If !lRet

            U_MT_ITMSG('Pedido '+M->C5_NUM + " Quando campo 'NF Sedex' For 'SIM', deverá necessáriamente ser preenchido a informação 'Número NF' e 'Serie NF'."	,;
                       "Validação Sedex","Preencher informações nos campos relacionados.",1)

        ElseIf SC5->(FIELDPOS("C5_I_PVREF")) <> 0 .And. !Empty(M->C5_I_PVREF)

            _cPallet:="2"
            _TipoC  :=""
            SA1->(DBSetOrder(1))
            If SA1->( DBSeek( xFilial("SA1") + M->C5_CLIENTE+M->C5_LOJACLI ) )
                _TipoC := SA1->A1_I_CHEP
                If !Empty(SA1->A1_I_PALET)
                    _cPallet:= SA1->A1_I_PALET
                EndIf
            EndIf
            If Empty(_TipoC)
                _TipoC := "C"
            EndIf
            If !SC5->C5_TIPO $ "B/D"//Se NÃO For beneficiamento e Devolução
                If _cPallet $ "S,1"
                    If _TipoC = "C"
                        _TipoC:= "1"
                    Else
                        lRet:=.F.
                    EndIf
                Else
                    lRet:=.F.
                EndIf
            Else
                lRet:=.F.
            EndIf

            If !lRet
               U_MT_ITMSG("O cliente de Destino do SEDEX não é PALLET CHEP.","Validação Sedex","Não precisa preencher o campo PV Referencia e Quantidade de Pallet.",1)
               Break
            EndIf

            SF2->(DBORDERNICKNAME("IT_I_PEDID"))
            If !SF2->(DBSeek(xFilial()+M->C5_I_PVREF))
               U_MT_ITMSG('Pedido: ['+M->C5_I_PVREF+"] não tem nota fiscal relacionada.","Validação Sedex","Preencha o campo PV Referencia quando a Carga de origem tiver Pallet Chep.",1)
               lRet:=.F.
               Break
            EndIf

            DAI->(DBSetOrder(4))//DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
            If !DAI->(DBSeek(xFilial()+SF2->F2_I_PEDID+SF2->F2_CARGA))

               U_MT_ITMSG('Carga de Origem: ['+SF2->F2_CARGA +"] da Nota: ["+SF2->F2_DOC+" "+SF2->F2_SERIE+"] não encontrada.","Validação Sedex","Preencha o campo PV Referencia quando a Carga de origem tiver Pallet Chep.",1)
               lRet:=.F.
               Break

            ElseIf DAI->DAI_I_TIPC <> "1" .Or. Empty(DAI->DAI_I_QTPA)

               U_MT_ITMSG('Pedido: ['+M->C5_I_PVREF+'] na Carga de Origem: ['+SF2->F2_CARGA + "] da Nota ["+SF2->F2_DOC+" "+SF2->F2_SERIE+"] não é PALLET CHEP.","Validação Sedex","Somente preencha o campo PV Referencia quando a Carga de origem tiver PALLET CHEP.",1)
               lRet:=.F.
               Break

            ElseIf SC5->(FIELDPOS("C5_I_QTPA")) <> 0 .And. Empty(M->C5_I_QTPA)

               U_MT_ITMSG('Pedido: ['+M->C5_I_PVREF+'] na Carga de Origem: ['+SF2->F2_CARGA + "] da Nota: ["+SF2->F2_DOC+" "+SF2->F2_SERIE+"] TEM PALLET CHEP.","Validação Sedex","Preencha o campo Quantidade Pallet quando a Carga de origem tiver Pallet Chep.",1)
               lRet:=.F.
               Break

            EndIf

        EndIf

    EndIf

    //================================================================================
    // Funcao responsavel por calcular o somatorio dos valores de descontos
    // contratuais e pegar o numero do contrato caso exista um para o pedido e por
    // validar se o contrato esta ativo, ou com a data de vigencia valida
    //================================================================================
    // Comentado por Fabiano Dias no dia 23/02/10 devido a constatacao do Analista
    // Tiago Correa de que a rotina de desconto contratual nao mais englobaria a parte
    // de pedido de venda somente gerando valores na SF2-SD2-SE1
    //================================================================================
    If lRet .And. M->C5_TIPO = "N"  .And. !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103") ;
       .And. !(FWIsInCallStack("U_AOMS099")) .And. !(FWIsInCallStack("M520_VALID")) .And. M->C5_I_OPER != "20" .And. !(FWIsInCallStack("U_AOMS098"))
       M410Proc(oProc,"Contrato")
       lRet := somContrato()
    EndIf

    If lRet

        M410Proc(oProc,"2a U.M.")
        If !valida2Um()

              U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Existe(m) produto(s) informado(s) que não possui(em) a 2a U.M..", "Validação 2a. Unidade"		,;
                            "Favor informar no cadastro do produto a segunda unidade de medida.",1	 )

        EndIf

    EndIf

    If lRet
        For x := 1 To Len(aCols)
            M410Proc(oProc,"Item "+aCols[x][nPosIte])
            _nProduto	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C6_PRODUTO"	})
            _nqtdsegu	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C6_UNSVEN"	})
            _cproduto	:= acols[x][_nProduto]
            _nquant		:= acols[x][_nqtdsegu]	//M->C6_UNSVEN

            If _nquant > 0 .And. Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_CONV") == 0 .And. !(AllTrim(Posicione("SB1",1,xFilial("SB1")+AllTrim(_cproduto),"B1_GRUPO ")) $ AllTrim(SuperGetMV("IT_GRP2U",.T.,"0006")))

               U_MT_ITMSG("Pedido " + M->C5_NUM + " Produto " + AllTrim(_cproduto) + " não tem fator de conversão cadastrado, impossível usar segunda medida!",'Validação 2a. Unidade',,1)

               lRet := .F.
               Exit
            EndIf
        Next x
    EndIf
EndIf

//================================================================================
// Verifica se Desconto é maior que 10% do Total do Pedido de Vendas
//================================================================================
If lRet .And. AllTrim(M->C5_TPFRETE) $ "F/D" .And. !_l108 .And. !_laoms074

    M410Proc(oProc,"Desconto")
    cPosVlr := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "C6_VALOR" } )

    For x := 1 To Len(aCols)
        nTotal += aCols[x,cPosVlr]
    Next x

    nPerc		:= GETMV( "IT_PERDESC" ,, 0 )
    nDescPer	:= ( nTotal * nPerc ) / 100 //Vlr Tot.*Perc. Permitido = Resulta no Valor permitido para desconto.
    If M->C5_DESCONT > nDescPer

       U_MT_ITMSG('Ped.: '+M->C5_NUM + " Foi informado o Valor do Desconto maior que "+CVALTOCHAR(nPerc)+"% do Valor Total do Pedido!"	, "Validação Desconto",;
                  "Favor verificar o Valor Total do Pedido e o Valor do Desconto.",1)

        lRet := .F.

    EndIf

EndIf

If ( ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 ) .And. lRet  .And. !_l108//1-Excluir; 3-Incluir/Copiar; 4-Alterar;
    M410Proc(oProc,"TES")
    lRet := vldTESBloq()
EndIf

//================================================================================
// Valida e-mail do cadastro do cliente ou fornecedor
//================================================================================
If ( ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 ) .And. lRet .And. !_l108 .And. !_laoms074 //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
    M410Proc(oProc,"e-mail do cadastro do cliente ou fornecedor")
    lRet := U_vldEmail()
EndIf

//================================================================================
// Valida se o vendedor encontra-se bloqueado no cadastro de vendedor
//================================================================================
If (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) .And. lRet .And. !_l108 .And. !_laoms074//1-Excluir; 3-Incluir/Copiar; 4-Alterar;
    M410Proc(oProc,"vendedor encontra-se bloqueado no cadastro")
    lRet := U_AOMS044( M->C5_VEND1 )
EndIf

//================================================================================
// Valida o coordenador para verificar se é igual ao da regra de comissao.
//================================================================================
If cTes == "S" .And. M->C5_TIPO = "N" .And. ( ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 ) .And. lRet .And. !_l108 .And. !_laoms074//1-Excluir; 3-Incluir/Copiar; 4-Alterar;
    M410Proc(oProc,"coordenador")
    lRet := vldCoorden( M->C5_VEND1 , M->C5_VEND2 , M->C5_I_V2NOM , M->C5_CLIENTE , M->C5_LOJACLI , M->C5_VEND3 )
EndIf

//================================================================================
// Campos referentes ao controle de pedidos de venda do tipo bonificacao tenham seus status alterados
// corretamente. Somente na inclusao, copia ou alteracao de um pedido de venda.
//================================================================================
If ( ParamIXB[1] == 3 .Or. ParamIXB[1] == 4 ) .And. M->C5_TIPO = "N" .And. M->C5_I_OPER = "10" .And. lRet .And. !_l108 .And. !_laoms074 .And. !FWIsInCallStack("U_AOMS032")//1-Excluir; 3-Incluir/Copiar; 4-Alterar;

    //================================================================================
    // Somente sera atualizado o status do pedido de venda quando este nao For
    // executado via siga-auto.
    //================================================================================
    If !l410Auto
       M410Proc(oProc,"bonificacao")

       //================================================================================
       // Verifica se o pedido corrente eh um pedido do tipo bonificacao
       //================================================================================
       If u_vldPedBon( aCols) .And. ParamIXB[1] == 3 //Se é inclusão, inclui bloqueado

            If M->C5_I_BLOQ	!= 'B'

                  U_MT_ITMSG(	"Pedido "+M->C5_NUM + " de bonificação bloqueado - "	+;
                            "O pedido deverá ser liberado antes de ficar disponível para faturamento.",'Validação Bonificação',,1)

            EndIf

            M->C5_I_BLOQ	:= 'B'       //Armazena o status bloqueado em um pedido de venda do tipo bonificacao
            M->C5_I_MTBON	:= ' '       //Armazena a matricula do usuario que realizou a aprovacao de pedido de venda
            M->C5_I_DLIBE	:= SToD(' ') //Armazena a data da aprovacao de pedido de venda
            M->C5_I_HLIBE	:= ' ' 	     //Armazena a hora da aprovacao de pedido de venda
            M->C5_I_STAWF	:= 'N' 		 //Armazena se ja foi enviado o HTML para aprovacao a um aprovador
            M->C5_I_BLPRC   := ""
            M->C5_I_BLCRE   := ""

       ElseIf  M->C5_I_BLOQ == "L" .And. !vldlibbon(aCols) //se é alteração só bloqueia não tem liberação ou liberação não é mais válida

            M->C5_I_BLOQ	:= 'B'       //Armazena o status bloqueado em um pedido de venda do tipo bonificacao
            M->C5_I_MTBON	:= ' '       //Armazena a matricula do usuario que realizou a aprovacao de pedido de venda
            M->C5_I_DLIBE	:= SToD(' ') //Armazena a data da aprovacao de pedido de venda
            M->C5_I_HLIBE	:= ' ' 	     //Armazena a hora da aprovacao de pedido de venda
            M->C5_I_STAWF	:= 'N' 		 //Armazena se ja foi enviado o HTML para aprovacao a um aprovador
            M->C5_I_BLPRC   := ""
            M->C5_I_BLCRE   := ""

       ElseIf .not. u_vldPedBon( aCols) //se não é bonificação zera os campos de bonificação

            M->C5_I_BLOQ:= ' '
            M->C5_I_MTBON := ' '
            M->C5_I_DLIBE := SToD(' ')
            M->C5_I_HLIBE := ' '
            M->C5_I_STAWF := ' '

       EndIf

    EndIf
Else
    If  M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26") .And. !(M->C5_I_OPER $ '24/05' .Or.  M->C5_TPFRETE $ "F/D" .Or. M->C5_CONDPAG = "001" ) .And. !FWIsInCallStack("U_AOMS032")
        M->C5_I_BLOQ	:= ' '
        M->C5_I_MTBON:= ' '
        M->C5_I_DLIBE:= SToD(' ')
        M->C5_I_HLIBE:= ' '
        M->C5_I_STAWF:= 'N'
    ElseIf ParamIXB[1] == 4 .And. !FWIsInCallStack("U_AOMS032") .And. M->C5_I_OPER <> "10" .And. SC5->C5_I_OPER == "10"
        M->C5_I_BLOQ	:= ' '
        M->C5_I_MTBON	:= ' '
        M->C5_I_DLIBE	:= SToD(' ')
        M->C5_I_HLIBE	:= ' '
        M->C5_I_STAWF	:= 'N'
    EndIf
EndIf

//Quando Inclusão
If ParamIXB[1] == 3 .And. M->C5_TIPO = "N" .And. lRet .And. !_l108 .And. !_laoms074 .And.;
  !(FunName() $ "MATA140,MATA521B,MATA460B,MATA103,AOMS003") .And. !_lAoms112 .And. ;
   M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26") .And. !FWIsInCallStack("U_AOMS032")
   lTemItemPA:=.F.
   For _nI := 1 To Len(acols)
       If !GdDeleted(_nI)
          If AllTrim(Posicione("SB1",1,xFilial("SB1")+acols[_nI][nPosProduto],"B1_TIPO")) == "PA"
             lTemItemPA:=.T.
             Exit
          EndIf
       EndIf
   Next

    If (M->C5_I_OPER = '24' .Or.  ( M->C5_TPFRETE $ "F/D" .And. lTemItemPA) )
        M->C5_I_BLOQ	:= 'B'
        M->C5_I_MTBON	:= ' '
        M->C5_I_DLIBE	:= SToD(' ')
        M->C5_I_HLIBE	:= ' '
        M->C5_I_STAWF	:= 'N'
    EndIf
EndIf

//=====================================================================================
//Na copia, inclusao ou alteracao de um pedido de venda eh verificado para constatar 
//se existem regras de TES INTELIGENTE para os produtos inseridos no pedido de acordo
//com o produto, cliente e loja e suframa, nao necessario retorno por zerar a TES.
//=====================================================================================
If (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) .And. lRet .And. !l410Auto .And. !_l108 .And. !_laoms074//1-Excluir; 3-Incluir/Copiar; 4-Alterar;

   If M->C5_TIPO == 'N'
      M410Proc(oProc,"regras de TES INTELIGENTE")
      If Len(AllTrim(M->C5_I_OPER)) == 0
         U_MT_ITMSG('Pedido '+M->C5_NUM + " Para o tipo de pedido de venda normal é necessario o fornecimento do campo tipo da operação.","Validação Tipo Operação",;
                    "Para que possa ser realizada uma consulta para checar se existe TES INTELIGENTE.",1)
         lRet:= .F.
      Else

            //====================================================================
            //|Caso o tipo da operacao nao esteja contido nos tipos de operacoes |
            //|que podem ter a sua TES alterada pelo usuario na TES INTELIGENTE. |
            //====================================================================
            If !(M->C5_I_OPER $ AllTrim(_cTpOper))
                lRet:= U_AOMS058(3)
            EndIf

            //==================================================================
            //|Valida o tipo de operacao fornecido diante do cliente informado.|
            //==================================================================
            If lRet
                lRet:=vldTpOper()
            EndIf

      EndIf

   EndIf

EndIf

If (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) .And. lRet .And. !_l108 .And. !_laoms074

    M410Proc(oProc,"Totais")

    //================================================================================
    // Validação do valor máximo permitido para o campo C5_VOLUME1
    //================================================================================
    _nValVol := Val( AllTrim( StrTran( StrTran( PesqPict("SC5","C5_VOLUME1") , '@E' , '' ) , ',' , '' ) ) )

    If M->C5_VOLUME1 > _nValVol

       If _lMsgEmTela
          U_MT_ITMSG(	'Pedido '+M->C5_NUM +" O volume calculado para esse pedido é maior que o limite para o campo ["+ Transform( _nValVol , PesqPict("SC5","C5_VOLUME1") ) +"]."	,;
                          "Validação volumes",;
                        "O sistema permite que sejam informadas no máximo ["+ Transform( _nValVol , PesqPict("SC5","C5_VOLUME1") ) +"] unidades de Volumes, "	+;
                        "desta forma caso a quantidade digitada esteja correta será necessário digitar mais de um pedido para compor o total.",1					 )
       Else
          _cAOMS074Vld += 'Atencao! (MT410TOK) Ped.: '+M->C5_NUM +;
                           " O volume calculado para esse pedido é maior que o limite para o campo ["+ Transform( _nValVol , PesqPict("SC5","C5_VOLUME1") ) +"]."	+;
                           " O sistema permite que sejam informadas no máximo ["+ Transform( _nValVol , PesqPict("SC5","C5_VOLUME1") ) +"] unidades de Volumes, "	+;
                           " desta forma caso a quantidade digitada esteja correta será necessário digitar mais de um pedido para compor o total."
       EndIf
        lRet := .F.

    EndIf

EndIf

//================================================================================
// VERIFCAÇÃO DO NUMERO DO PEDIDO DE VENDA
//================================================================================
cPedido := M->C5_NUM

If ParamIXB[1] == 3  .And. !_l108 .And. !_laoms074

    cMay := "SC5"+ AllTrim( xFilial("SC5") )

    DBSelectArea("SC5")
    SC5->( DBSetOrder(1) )
    While SC5->( DBSeek( xFilial("SC5") + cPedido ) .Or. !MayIUseCode( cMay + cPedido ) )

          M410Proc(oProc,"No. do Pedido: "+cPedido)

          cPedido := Soma1( cPedido , Len( SC5->C5_NUM ) )
    EndDo

EndIf

//================================================================================
// GRAVAÇÃO DO NOME DO USUÁRIO NA INCLUSÃO
//================================================================================
If ParamIXB[1] == 3 .And. lRet .And. !_l108 .And. !_laoms074//Se inclusão e tudo ok

    PswOrder(1) // Busca por ID

    If PSWSEEK( __cUserId, .T. )
        aUser := PSWRET() // Retorna vetor com informações do usuário
    EndIf

    For Y := 1 To Len(aCols)

        If !aCols[y,Len(aHeader)+1] //Se Linha Nao Deletada
            If Len(auser) > 0
                aCols[y,nPosUser] := aUser[1,2] //Grava o Usuário no campo C6_I_USER
            Else
                aCols[y,nPosUser] := "Auto"
            EndIf
        EndIf

    Next y

EndIf

//================================================================================
// Se filial Contem no Parametro IT_FILPV e Operação é 02, 	                      |
// o armazém deverá ser 21. Chamado 6498.                                        |
//================================================================================
If lRet .And. !_l108

    If cFilAnt $ GetMv("IT_FILPV") .And. M->C5_I_OPER == '02'

        nPosAmz  := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "C6_LOCAL" } )
        nPosItem := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "C6_ITEM" } )

        For x := 1 To Len(aCols)

            M410Proc(oProc,"Item "+aCols[x][nPosIte])

            If aCols[x,nPosAmz] <> '21'
                 If _lMsgEmTela .And. !_laoms074

                  U_MT_ITMSG('Pedido '+M->C5_NUM +  " No Item "+aCols[x,nPosItem]+", o Armazém "+aCols[x,nPosAmz]+" não pode ser utilizado se a Filial é "+cFilAnt+" e Tipo de Operação é '02 - Venda Funcionário'.",;
                                "Validação pedido funcionário",;
                              "Neste cenário, deverá ser utilizado Armazém '21'.",1)
                 Else

                  _cAOMS074Vld += 'Atencao! (MT410TOK) Ped.: '+M->C5_NUM +;
                                  " No Item "+aCols[x,nPosItem]+", o Armazém "+aCols[x,nPosAmz]+" não pode ser utilizado se a Filial é "+cFilAnt+" e Tipo de Operação é '02 - Venda Funcionário'." +;
                                  " Neste cenário, deverá ser utilizado Armazém '21'."
               EndIf

                lRet := .F.
                Exit

            EndIf

           Next x

    EndIf

EndIf

//================================================================================
// Se For Cfop de venda para funcionário/produtor limita o pedido ao limite de
// crédito do cliente
//================================================================================
If (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) .And. !_l108 .And. !_laoms074//1-Excluir; 3-Incluir/Copiar; 4-Alterar;

    If lRet .And. !_lAoms112

        M410Proc(oProc,"venda para funcionario/produtor")

        lRet := vldPedFun( aCols )

    EndIf

EndIf

//================================================================================
// Se é pedido manual verifica se usuário tem restrição filialxarmazém
//================================================================================
If ( AllTrim(funname()) == "MATA410" .Or. FWIsInCallStack("U_AOMS109")) .And. !_l108 .And. !_laoms074 .And. !_laoms112
    If lRet

        M410Proc(oProc,"se usuario tem restricao")

        lRet := vldFilArm ( aCols )

    EndIf

EndIf

//==============================================================================================
// Bloco de verificação de amarração com a programação de entrega e ajustes de exclusão
//==============================================================================================
If (ParamIXB[1] = 1 .Or. ParamIXB[1] = 5) .And. lRet .And. !_l108 .And. !_laoms074 .And. M->C5_TIPO = "N" .And. !_lAoms112

    M410Proc(oProc,"amarracao com a programacao de entrega e ajustes de exclusao")

    lRet := u_veriprog()

EndIf

//=======================================================================================================
// Verifica se a operação está sendo mudada para bonificação, se estiver bloqueia o pedido por
// bonificação
//=======================================================================================================
If lRet .And. SC5->C5_I_OPER != '10' .And. M->C5_I_OPER == '10' .And. ParamIXB[1] == 4 .And. !_l108 .And. !_laoms074 .And. M->C5_TIPO = "N" .And. !_lAoms112

        U_MT_ITMSG('Pedido '+M->C5_NUM + " Pedido sendo alterado para bonificação.",;
                    "Validação Bonificação",;
                    "Deverá passar por liberação antes de faturar.",2)

     M->C5_I_BLOQ	:= 'B'       //Armazena o status bloqueado em um pedido de venda do tipo bonificacao
     M->C5_I_MTBON	:= ' '       //Armazena a matricula do usuario que realizou a aprovacao de pedido de venda
     M->C5_I_DLIBE	:= SToD(' ') //Armazena a data da aprovacao de pedido de venda
     M->C5_I_HLIBE	:= ' ' 	     //Armazena a hora da aprovacao de pedido de venda
     M->C5_I_STAWF	:= 'N' 		 //Armazena se ja foi enviado o HTML para aprovacao a um aprovador
     M->C5_I_BLPRC  := ""
     M->C5_I_BLCRE  := ""

EndIf

//================================
// Validação de execução do Mashup
//================================
If ParamIXB[1] == 3 .And. !l410Auto .And. !_l108 .And. !_laoms074 .And. M->C5_TIPO = "N" .And. !_lAoms112
    If lRet
        If _lMashup

           M410Proc(oProc,"execucao do Mashup")

            DBSelectArea("ZZL")
            ZZL->( DBSetOrder(3) )
            If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
                If ZZL->ZZL_LIBMAS == "S"
                    _lLibMas := .T.
                EndIf
            EndIf

            If !_lLibMas

                SA1->(DBSetOrder(1))
                SA1->(DBSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI))

                _nQtdDia	:= Val(SA1->A1_I_PEREX)
                _nQtdiaT	:= IIf(Empty(SA1->A1_I_DTEXE),0,dDataBase - SA1->A1_I_DTEXE)
                _lExec		:= IIf(_nQtdiaT > _nQtdDia, .T., .F.)

                If SA1->A1_PESSOA <> "F"
                    If AllTrim(SA1->A1_I_SITRF) <> "APTO" .And. AllTrim(SA1->A1_I_SITRF) <> "REGULAR" .And. AllTrim(SA1->A1_I_SITRF) <> "ATIVO" .And. AllTrim(SA1->A1_I_SITRF) <> "ATIVA" .Or. _lExec
                        _lRet := .F.
                        If _lExec
                            If AllTrim(SA1->A1_I_END) $ SA1->A1_END

                                  U_MT_ITMSG('É necessário realizar a consulta deste cadastro na Receita Federal devido a periodicidade de consulta. A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' , "Validção Mashup",,1 )

                                lRet := .F.

                            EndIf
                        Else
                            If Empty(SA1->A1_I_SITRF)
                               If _lMsgEmTela
                                  U_MT_ITMSG('É necessário realizar a consulta deste cadastro na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.',"Validação Mashup",,1 )
                               Else

                                  _cAOMS074Vld += 'É necessário realizar a consulta deste cadastro na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.'

                               EndIf

                                lRet := .F.
                            Else
                               If _lMsgEmTela
                                  U_MT_ITMSG( 'Não é possível concluir o cadastro deste fornecedor, devido seu status na Receita Federal estar como [' + AllTrim(SA1->A1_I_SITRF) + '].',"Validação Mashup",,1 )
                               Else

                                  _cAOMS074Vld += 'Não é possível concluir o cadastro deste fornecedor, devido seu status na Receita Federal estar como [' + AllTrim(SA1->A1_I_SITRF) + '].'

                               EndIf
                                lRet := .F.
                            EndIf
                        EndIf
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
EndIf

//================================================================================
// Se um produto estiver contido no parâmetro IT_PRDNFRAC e se o armazem
// estiver no parâmetro IT_LOCNFRAC ou o tipo de oparação estiver no parâmetro
// IT_TPONFRAC, obrigatóriamente deverá validar as quantidades fracionadas.
//================================================================================
SB1->(DBSetOrder(1))
If  !_laoms074 .And. lRet .And. !_l108 .And. (!ParamIXB[1] = 5 .And. !ParamIXB[1] = 1)//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

  _cProds:=""
  For nX := 1 To Len(aCols)
   // Muda o valor de N
    N := nX
    M410Proc(oProc,"(2a) Quantidades fracionadas, Item "+aCols[nX][nPosIte])

    If aCols[n][Len(aCols[n])]
       Loop
    EndIf

    If AllTrim(aCols[n,nPosProduto]) $ _cProdNFrac .And. (AllTrim(aCols[n,nPosLoc]) $ _cLocalNFrac .Or. M->C5_I_OPER $ _cTipOpNFrac)

        SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto])))
        If aCols[n,nPosQtd2] <> Int(aCols[n,nPosQtd2])
            _cTextCalc := " " + AllTrim(Transform(aCols[n,nPosQtd2],"@E 999,999,999.9999")) + " " + SB1->B1_SEGUM
            lRet := .F.
            _cProds+="Item: " + aCols[n,nPosIte]+" Produto: " + AllTrim(aCols[n,nPosProduto]) + " - " + LEFT(SB1->B1_DESC,45) + _cTextCalc + CRLF
        EndIf

    Else
        //=====================================================================================
        //Validação de quantidade fracionada
        //=====================================================================================
        If cFilAnt $ _cFilOper
                If !(M->C5_I_OPER $ _cOperEst)
                    If !(AllTrim(aCols[n,nPosProduto]) $ _cProdPe) .And. 	 !aCols[n][Len(aCols[n])] 	//Se a linha nao estiver deletada
                        If !(AllTrim(aCols[n,nPosLoc]) $ _cLocval) .And. M->C5_I_NFSED != "S" //não valida para armazéns do IT_LOCFRA e para pedido Sedex

                           If SBZ->(FieldPos("BZ_I_PR3UM")) > 0
                              //=========================================
                              // Nova versão da validação.
                              //=========================================
                              //_cCrtl3Um := Posicione("SBZ",1, M->C5_FILIAL + aCols[n,nPosProduto] ,"BZ_I_PR3UM")
                              _cCrtl3Um := Posicione("SBZ",1, cFilant + aCols[n,nPosProduto] ,"BZ_I_PR3UM")

                              If _cCrtl3Um == "S"

                                 //If (AllTrim(aCols[n,nPosProduto]) $ _cPrd3Um)

                                 SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto])))
                                 If aCols[n,nPosqtd] / SB1->B1_I_QT3UM <> Int(aCols[n,nPosqtd] / SB1->B1_I_QT3UM)
                                    _cTextoUnd := " 3a.UM (terceira) "
                                    _cTextCalc := " " + AllTrim(Transform(aCols[n,nPosqtd] / SB1->B1_I_QT3UM,"@E 999,999,999.9999")) + " " + SB1->B1_I_3UM

                                    lRet := .F.
                                    _cProds+="Item: " + aCols[n,nPosIte]+" Produto: " + AllTrim(aCols[n,nPosProduto]) + " - " + LEFT(SB1->B1_DESC,45)+ _cTextCalc + CRLF
                                 EndIf
                              Else
                                 DBSelectArea("SB1")
                                 DBSetOrder(1)
                                 DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto]))
                                 If aCols[n,nPosQtd2] <> Int(aCols[n,nPosQtd2])
                                    _cTextCalc := " " + AllTrim(Transform(aCols[n,nPosQtd2],"@E 999,999,999.9999")) + " " + SB1->B1_SEGUM
                                     lRet := .F.
                                    _cProds+="Item: " + aCols[n,nPosIte]+" Produto: " + AllTrim(aCols[n,nPosProduto]) + " - " + LEFT(SB1->B1_DESC,45) + _cTextCalc + CRLF
                                 EndIf
                              EndIf

                           Else
                              //============================================
                              // versão antiga da validação.
                              //============================================
                              If (AllTrim(aCols[n,nPosProduto]) $ _cPrd3Um)
                                 SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto])))
                                 If aCols[n,nPosqtd] / SB1->B1_I_QT3UM <> Int(aCols[n,nPosqtd] / SB1->B1_I_QT3UM)
                                    _cTextCalc := " " + AllTrim(Transform(aCols[n,nPosqtd] / SB1->B1_I_QT3UM,"@E 999,999,999.9999")) + " " + SB1->B1_I_3UM
                                    lRet := .F.
                                    _cProds+="Item: " + aCols[n,nPosIte]+" Produto: " + AllTrim(aCols[n,nPosProduto]) + " - " + LEFT(SB1->B1_DESC,45) + _cTextCalc + CRLF
                                 EndIf
                              Else
                                 DBSelectArea("SB1")
                                 DBSetOrder(1)
                                 DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto]))
                                 If aCols[n,nPosQtd2] <> Int(aCols[n,nPosQtd2])
                                    _cTextCalc := " " + AllTrim(Transform(aCols[n,nPosQtd2],"@E 999,999,999.9999")) + " " + SB1->B1_SEGUM
                                    lRet := .F.
                                    _cProds+="Item: " + aCols[n,nPosIte]+" Produto: " + AllTrim(aCols[n,nPosProduto]) + " - " + LEFT(SB1->B1_DESC,45) + _cTextCalc + CRLF
                                 EndIf
                              EndIf
                           EndIf

                        EndIf
                    EndIf
                EndIf
        EndIf
    EndIf

  Next

  If !lRet
      U_MT_ITMSG("Existem produtos que não podem ser vendidos com quantidades fracionadas. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                    "Validação Fracionado","Favor informar apenas quantidades inteiras na" + _cTextoUnd + " de medida." ,1     ,       ,        ,         ,     ,     ,{|| U_ITMSGLOG(_cProds,"Validação Fracionado") },_cProds )

  EndIf

EndIf

//Validação de campo de desconto
If lRet .And. !_l108 .And. !_laoms074

    _nTotPV := 0
    For _nI := 1 To Len(acols)

        If !GdDeleted(_nI)

            _nTotPV += acols[_nI][nPosVal]

        EndIf

    Next

    If M->C5_DESCONT > _nTotPV .And. !_l108 .And. !_laoms074

        U_MT_ITMSG("Valor de desconto não pode ser maior que o valor total do pedido!",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Revise valor do desconto",1)
        lRet := .F.

    EndIf

EndIf

// Valida a vinculação de notas fiscais SEDEX.
If lRet .And. !_lAoms112 .And. ParamIXB[1] <> 1 .And. ParamIXB[1] <> 5 //EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
   lRet := U_M410VLSDX("TUDOOK")
EndIf

End Sequence

//***********   TRATAMENTO DE OPERCAO TRIANGULAR  ********************************
Begin Sequence

_cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação triangular
_cOperFat       := LEFT(_cOperTriangular,2)
_cOperRemessa   := RIGHT(_cOperTriangular,2)
_nRecOrigem     := SC5->(RECNO())
If lRet .And. M->C5_TIPO = "N" .And. (M->C5_I_OPER $ _cOperTriangular .Or. SC5->C5_I_OPER = _cOperFat)//Se antes da alteração era 05...

    If _laoms074//FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC")

        nPsBru := M410LITotais()//Calcula os Totais

    EndIf

   M410Proc(oProc,"TRATAMENTO DE OPERCAO TRIANGULAR")
   If !Empty(M->C5_I_PVFAT) .And. M->C5_I_OPER = _cOperRemessa//Verefica se o Pedido de Venda do pedido de remessa não tem NOTA
      SF2->(DBORDERNICKNAME("IT_I_PEDID"))
      If SF2->(DBSeek(xFilial()+M->C5_I_PVFAT))
         U_MT_ITMSG("Pedido de Venda "+AllTrim(M->C5_I_PVFAT)+" desse Pedido já esta na NF: "+AllTrim(SF2->F2_DOC),"Atencao!",;
                  "Estorne a NF: "+AllTrim(SF2->F2_DOC)+" do Pedido de Venda "+AllTrim(M->C5_I_PVFAT)+" para dar manutenção nesse Pedido de Remessa",1)
         lRet:=.F.
         Break
      EndIf
   EndIf


   If M->C5_I_OPER = _cOperRemessa
      M->C5_I_OPTRI = "R"

      If Empty(M->C5_I_CLIEN) .Or. Empty(M->C5_I_LOJEN)
         U_MT_ITMSG("Cliente de Faturamento não preenchido para esse Pedido de Venda","Atencao!","Selecione um cliente de Remessa nesse Pedido de Venda para gerar o Pedido de Remessa",1)
         lRet:=.F.
         Break
      EndIf

      If M->C5_I_CLIEN+M->C5_I_LOJEN == M->C5_CLIENTE+M->C5_LOJACLI
         U_MT_ITMSG("Cliente de remessa não pode ser igual ao cliente do Pedido de Venda","Atencao!","Selecione um cliente de Remessa diferente do cleinte do Pedido de Venda para gerar o Pedido de Remessa",1)
         lRet:=.F.
         Break
      EndIf

   EndIf

   SC5->(DBGoTo(_nRecOrigem)) //Volta o POSICIONAMENTO do pedido de origem SEMPRE
   If ParamIXB[1] = 4//ALTERACAO
      SC5->(MSRLOCK(SC5->(RECNO())))  //Retrava por garantia
   EndIf

EndIf
//Se não For mais TRATAMENTO DE OPERACAO TRIANGULAR limpa tudo
If lRet .And. !M->C5_I_OPER $ _cOperTriangular
   M->C5_I_OPTRI:=Space(Len(SC5->C5_I_OPTRI))
   M->C5_I_PVREM:=Space(Len(SC5->C5_I_PVREM))
   M->C5_I_PVFAT:=Space(Len(SC5->C5_I_PVFAT))
   M->C5_I_CLIEN:=Space(Len(SC5->C5_I_CLIEN))
   M->C5_I_LOJEN:=Space(Len(SC5->C5_I_LOJEN))
EndIf

//================================================================================
//***********   TRATAMENTO DE OPERACAO TRIANGULAR  ********************************
//================================================================================

//================================================================================
//***********   Tratamento para PV vinculados  ***********************************
//================================================================================
If lRet .And. M->C5_TIPO = "N"  .And. !_laoms074 .And. !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE") .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4 .Or. ParamIXB[1] = 1 .Or. ParamIXB[1] = 5) //EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

   If !Empty(M->C5_I_PEVIN) .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4) // INCLUSAO OU ALTERACAO

      M410Proc(oProc,"PV vinculados")

      If M->C5_NUM == M->C5_I_PEVIN
         U_MT_ITMSG("O numero do Pedido vinculado é igual ao numero do Pedido Atual.","PEDIDO VINCUALADO",;
                    "Selecione um Pedido diferente do atual",1)
         lRet:=.F.
         Break

      EndIf

      If _lValAltPVin .And. ParamIXB[1] == 4 .And. !Empty(SC5->C5_I_PEVIN) .And. !(SC5->C5_I_PEVIN == M->C5_I_PEVIN)
         U_MT_ITMSG("O Pedido vinculado "+SC5->C5_I_PEVIN+" atual não pode ser alterado para o Pedido "+M->C5_I_PEVIN,"PEDIDO VINCUALADO",;
                    "Limpe o campo "+AVSX3("C5_I_PEVIN",5)+", grave o Pedido Atual e altere novamente para vincular o novo Pedido",1)
         lRet:=.F.
         Break

      EndIf

      //SC5 Já esta na ordem e o recno já ta salvo
      If !SC5->(DBSeek(xFilial()+M->C5_I_PEVIN))
         U_MT_ITMSG("O Pedido vinculado "+M->C5_I_PEVIN+" não existe.","PEDIDO VINCUALADO",;
                    "Selecione um Pedido cadastrado",1)

         lRet:=.F.
         Break

      ElseIf !Empty(SC5->C5_I_PEVIN) .And. !(SC5->C5_I_PEVIN == M->C5_NUM)

         U_MT_ITMSG("O Pedido vinculado "+M->C5_I_PEVIN+" já esta vinculado com outro Pedido: "+SC5->C5_I_PEVIN,"PEDIDO VINCUALADO",;
                    "Selecione outro um Pedido",1)

         lRet:=.F.
         Break

      Else//ve se tem carga e nota

         SC9->( DBSetOrder(1) )
         If SC9->( DBSeek( SC5->C5_FILIAL + M->C5_I_PEVIN ) )
            While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL + M->C5_I_PEVIN
               If !Empty(SC9->C9_CARGA)
                  U_MT_ITMSG("Pedido Vinculado "+AllTrim(M->C5_I_PEVIN)+" já esta na carga: "+SC9->C9_CARGA,"Atencao!","Estorne a carga "+AllTrim(SC9->C9_CARGA)+" ou selecione outro pedido",1)
                  lRet:=.F.
                  Break
               EndIf
               If !Empty(SC9->C9_NFISCAL)
                  U_MT_ITMSG("Pedido Vinculado "+AllTrim(M->C5_I_PEVIN)+" já tem Nota: "+SC9->C9_NFISCAL,"Atencao!","Estorne a Nota "+AllTrim(SC9->C9_NFISCAL)+" ou selecione outro pedido",1)
                  lRet:=.F.
                  Break
               EndIf
               SC9->(DBSkip())
            EndDo
         EndIf

      EndIf

   ElseIf ParamIXB[1] = 1 .Or. ParamIXB[1] = 5 //EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO

      If !Empty(SC5->C5_I_PEVIN)

         U_MT_ITMSG('Esse pedido possui outro pedido '+M->C5_I_PEVIN+" vinculado, não pode ser excluido.","PEDIDO VINCUALADO",;
                    "Entre na Alteração desse pedido para desvincular o pedido limpando o campo "+AVSX3("C5_I_PEVIN",5),1)

         lRet:=.F.
         Break

      EndIf

   EndIf

   SC5->(DBGoTo(_nRecOrigem)) //Volta o POSICIONAMENTO do pedido de origem SEMPRE
   If ParamIXB[1] = 4//ALTERACAO
      SC5->(MSRLOCK(SC5->(RECNO()))) //Retrava por garantia
   EndIf

EndIf//***********   Tratamento para PV vinculados  ***********************************

//============================================================================================================
// Validação de consistência de condição de pagamento  
//============================================================================================================
If lRet .And. M->C5_TIPO = "N" .And.  (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) //3-Incluir/Copiar; 4-Alterar;
   //============================================
   // Manter a validação abaixo para: 
   // - Demembramento
   // - Operação Triangular faturamento (05)
   // - Transferência
   //============================================
   If M->C5_I_OPER $ _cOperFat .Or. FWIsInCallStack("U_AOMS098") .Or.  FWIsInCallStack("U_AOMS032EXE") // Operação Triangular 05  ou Desmembramento ou Transferência

      _ccondr := M->C5_CONDPAG

      If lRet //.And. Empty(AllTrim(SC5->C5_CONDPAG))
         _ccondr := U_IT_conpv(@lRet) //carrega condição de pagamento personalizada do pedido aberto
      EndIf

      If lRet .And. _ccondr <> SA1->A1_COND   // Somente aceitar quando For Diferente do Cliente, caso usr tenha alterado na inclusão
         M->C5_CONDPAG := _ccondr
      EndIf
   Else
      //======================================================================
      // Valida condições de pagamento para clientes com condições especiais.
      //======================================================================
      _lOK:=.T.
      _ccondr := U_IT_conpv(@_lOK) //carrega condição de pagamento personalizada do pedido aberto

      If !Empty(_ccondr) .And. Empty(M->C5_CONDPAG)
         M->C5_CONDPAG := _ccondr
      ElseIf ! Empty(_ccondr) .And. M->C5_CONDPAG <> _ccondr 
         If _lOK//SE NÃO deu mensagem dentro da função U_IT_conpv() dá aqui
            U_MT_ITMSG("Cliente com condição de pagamento específica: ("+_ccondr+"). ","Atencao!","A condição de pagamento ("+M->C5_CONDPAG+") informada no pedido de vendas não é permitida para esse Cliente.",1)
         EndIf
         lRet:=.F.
         Break
      ElseIf Empty(M->C5_CONDPAG)
         U_MT_ITMSG("A condição de pagamento não foi informada.","Atencao!",,1)
         lRet:=.F.
         Break
      EndIf
   EndIf  
EndIf

If lRet .And. (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4); //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
        .And. M->C5_TIPO = "N" .And. M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26")
   //=====================================================================
   // Regras de validação de prazo médio com base no cadastro de cliente.
   //=====================================================================
   _cCondCli  := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ,"A1_COND")
   _nPrazoMCl := Posicione("SE4",1,xFilial("SE4") + _cCondCli ,"E4_I_PRZMD") // 1=E4_FILIAL+E4_CODIGO
   _cDCondCli := AllTrim(SE4->E4_DESCRI)
   //----------------------//
   _nPrazoPV  := Posicione("SE4",1,xFilial("SE4") + M->C5_CONDPAG ,"E4_I_PRZMD") // 1=E4_FILIAL+E4_CODIGO
   _cDCondPV  := AllTrim(SE4->E4_DESCRI)

   If _nPrazoPV > _nPrazoMCl
      U_MT_ITMSG("O prazo médio do pedido "+AllTrim(Str(_nPrazoPV))+" é maior que o prazo médio do cliente: "+AllTrim(Str(_nPrazoMCl))+CRLF+;
                 "Cond. Cliente: "+_cCondCli+"-"+_cDCondCli+CRLF+"Cond. Pedido: "+M->C5_CONDPAG+"-"+_cDCondPV,;
                 "Validação Condição de Pagamento.","Por favor entrar em contato com o departamento comercial."+CRLF+;
                 "Filial + Pedido: "+M->C5_FILIAL+" "+M->C5_NUM+CRLF+;
                 "Operação:  "+M->C5_I_OPER,2)
      lRet := .F.
      Break
   EndIf


EndIf

//============================================================================================================
//Validação para não permitir fracionamento para PAs onde a 1a UM For UN (represente 1 inteiro)
//============================================================================================================
If lRet .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4)
   M410Proc(oProc,"Verificando quantidade fracionadas...")
   lRet:=MT410_UN(oProc)
EndIf

//================================================================================
// Valida se o cliente aceita troca nota ou não.
//================================================================================
If lRet .And. (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4) //1-Excluir; 3-Incluir/Copiar; 4-Alterar;
   SA1->(DBSetOrder(1))
   SA1->(MSSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI))
   If M->C5_I_TRCNF == "S" .And. SA1->A1_I_TRCNF == "N"
      U_MT_ITMSG("O cliente "+M->C5_CLIENTE+" "+M->C5_LOJACLI+" - "+AllTrim(SA1->A1_NOME) + " deste pedido " + M->C5_NUM + " de vendas não aceita troca de NF.","Atencao!",,1)
      lRet:=.F.
      Break
   EndIf
EndIf

//================================================================================
// VALIDACAO DE PRODUTOS BLOQUEADOS POR FILIAL
//================================================================================
_cProds:=""
//NÃO VALIDAR:
//Quando Transferir o Pedido (U_AOMS032EXE)
//Quando Desmembrar o Pedido (U_AOMS098)
//Quando Receber dados WS do RDC (U_AOMS074)
If lRet .And. ( _lItemNovo .Or. Inclui ) .And. !(FWIsInCallStack("U_AOMS098"))    .AND.;
                        M->C5_TIPO = "N" .And. !(FWIsInCallStack("U_AOMS074"))    .AND.;
                                               !(FWIsInCallStack("U_AOMS032EXE")) .AND.;
                   M->C5_I_OPER $ SuperGetMV("IT_TPOPER",.T.,"01,42,08,12,15,24,25,26")

    //Valida existência de produtos na tabela de preços selecionada
   SC6->(DBSetOrder(1))
    For _nnipre := 1 To Len(acols)
        If aCols[_nnipre,Len(aHeader)+1] // Se Linha Excluida
           Loop
        EndIf
        //Ignora os itens que já existia
           If _lItemNovo .And. SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM+aCols[_nnipre][nPosIte]))
           Loop
        EndIf

        _cBloqSBZ:=Posicione("SBZ",1,xFilial("SBZ")+acols[_nnipre][nPosProduto],"BZ_I_BLQPR")
        If _cBloqSBZ == "S"
           _cDescr:=Posicione("SB1",1,xFilial("SB1")+acols[_nnipre][nPosProduto],"B1_DESC")
           aAdd(_aProdBlq,({acols[_nnipre][nPosIte],acols[_nnipre][nPosProduto],_cDescr}))
           _cProds+="Item: " + aCols[_nnipre,nPosIte]+" Produto: " + AllTrim(aCols[_nnipre,nPosProduto]) + "-" + _cDescr + CRLF
           lRet := .F.
        EndIf
    Next

    If !lRet

        U_MT_ITMSG("Há produtos neste pedido constam como bloqueados para esta filial. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                    "Validação de Produtos Bloqueados","Favor informar apenas produtos desbloqueados."         ,1     ,       ,        ,         ,     ,     ,;
                    {|| U_ITListBox( 'Itens do Pedido com Bloqueio de Produto para Filial' , {"Item do Pedido","Codigo","Descricao do Produto"} , _aProdBlq , .F. , 1 ) },_cProds )
      Break
    EndIf
EndIf

//======================================================================================
// Validações para geração de Pedido de Pallets de devolução, para os armazéns 40 e 42
// para pedidos de vendas sem geração de carga.
//======================================================================================
If lRet .And. (ParamIXB[1] == 3 .Or. ParamIXB[1] == 4)
   //======================================================================================
   If M->C5_I_GPADV == "S"
   //======================================================================================
      If Empty(M->C5_I_TRAPA) .Or. Empty(M->C5_I_LTRAP)
         U_MT_ITMSG("Este pedido de vendas está configurado para gerar pedidos de pallets de devolução. O preenchimento dos campos código e loja da transportadora do pedido de pallets de devolução são obrigatórios.",;
                    "Atenção",;
                    "Preencha os campos códio e loja da transportadora do pedido de pallets de devolução.",1)
         lRet:= .F.
      EndIf

      If lRet
         SA1->(DBSetOrder(1))
         If ! SA1->(MsSeek(xFilial("SA1")+M->C5_I_TRAPA+M->C5_I_LTRAP))
            U_MT_ITMSG("O código e a loja da transportadora do pedido de pallets de devolução não existe.",;
                    "Atenção",;
                    "Informe um código e loja da transportadora do pedido de pallets de devolução que exista.",1)
            lRet:= .F.
         EndIf
      EndIf

      If lRet
         SA1->(DBSetOrder(1))
         If SA1->(MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))
            If M->C5_I_GPADV == "S"
               If SA1->A1_I_CHEP <> "C"
                  U_MT_ITMSG("Este pedido de vendas está configurado para gerar pedido de pallets de devolução, mas o cliente não é do tipo Pallet Chep.",;
                  "Atenção",;
                  "Informe um cliente do tipo pallet chep.",1)
                  lRet:= .F.
               EndIf

               If lRet .And. Empty(SA1->A1_I_CCHEP)
                  U_MT_ITMSG("Este pedido de vendas está configurado para gerar pedido de pallets de devolução, mas o campo código chep do cadastro do cliente não está preenchido.",;
                  "Atenção",;
                  "Informe um cliente com o campo código Chep preenchido.",1)
                  lRet:= .F.
               EndIf
            EndIf
         EndIf
      EndIf

      //=================================================================
      // Verifica se há itens nos amrmazéns 40 e 42.
      //=================================================================
      // _nPosQPale      := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_QPALT" } )
      _lTemLocPCh := .F.
      _lTemQtdPal := .F.
      For x := 1 To Len(aCols)
          If acols[x][nPosLoc] $ _cLocalPCh
             _lTemLocPCh := .T.
          EndIf

          If acols[x][nPosLoc] $ _cLocalPCh .And. acols[x][_nPosQPale] > 0
             _lTemQtdPal := .T.
          EndIf
      Next

      If ! _lTemLocPCh
         U_MT_ITMSG("Este pedido de Vendas está com a opção gerar pedido de pallet igual a Sim, mas não existe nenhum item nos armazéns: " + AllTrim(_cLocalPCh) + ".",;
                    "Atenção",;
                    "Para gerar pedido de Pallets, é preciso ter itens nos armazéns: " + AllTrim(_cLocalPCh) + ".",1)
         lRet := .F.
      EndIf

      If ! _lTemQtdPal
         U_MT_ITMSG("Este pedido de Vendas está com a opção gerar pedido de pallet igual a Sim, mas não existe quantidade de palltes informado.",;
                    "Atenção",;
                    "Para gerar pedido de Pallets, é preciso informar a quantidade de pallets.",1)
         lRet := .F.
      EndIf

   EndIf //If M->C5_I_GPADV == "S"
EndIf

If lRet .And. !_lAoms112 .And. !_l108 .And. !_laoms074 .And. M->C5_I_OPER $ "15|20|21|22|42"
	
   _aSM0 := FWLoadSM0()

   SA1->(DBSetOrder(1))
	SA1->(MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))
   _nPos := aScan(_aSM0,{|x| x[18] = AllTrim(SA1->A1_CGC) })

   Do Case
		Case M->C5_I_OPER = "20" 
         If _nPos > 0 
            _nPosFilAnt := aScan(_aSM0,{|x| x[2] = AllTrim(FwCodFil()) })
            If _nPosFilAnt > 0  .And. _aSM0[_nPos,18] == _aSM0[_nPosFilAnt,18]
               lRet := .F.
               U_MT_ITMSG("Para operação 20 não é permitido clientes que correspondam a filial logada.",;
                     "Atenção",;
                     "Selecione outro Cliente que corresponda a uma Filiais cadastradas.",1)
				EndIf
         Else
            lRet := .F.
            U_MT_ITMSG("Para operação 20 só é permitido clientes que correspondam a uma das filiais cadastradas.",;
                     "Atenção",;
                     "Selecione outro Cliente que corresponda a uma Filiais cadastradas.",1)
         EndIf
      Case M->C5_I_OPER = "21" .And. _nPos = 0
         lRet := .F.
         U_MT_ITMSG("Para operação 21 só é permitido clientes que correspondam a uma das filiais cadastradas.",;
                  "Atenção",;
                  "Selecione o Cliente que corresponda a uma Filial cadastrada.",1)
		
      Case M->C5_I_OPER = "22" .And. _nPos > 0
         _nPosFilAnt := aScan(_aSM0,{|x| x[2] = AllTrim(FwCodFil()) })
         If _nPosFilAnt > 0  .And. _aSM0[_nPos,18] <> _aSM0[_nPosFilAnt,18]
            lRet := .F.
            U_MT_ITMSG("Para operação 22 só é permitido clientes que corresnponda a filial de inclusão do Pedido.",;
                  "Atenção",;
                  "Selecione o Cliente que corresponda a Filial logada.",1)
         EndIf
			
      Case M->C5_I_OPER = "15" .And. !(SA1->A1_TIPO == "F" .And. M->C5_TIPOCLI=="F" .And. (AllTrim(Upper(SA1->A1_INSCR)) == "ISENTO" .Or. Empty(SA1->A1_INSCR)))
         lRet := .F.
         U_MT_ITMSG("Para operação 15 só é permitido clientes do Tipo Consumidor Final com Inscrição Estatual preenchida como ISENTO ou não preenchida.",;
                  "Atenção",;
                  "Selecione outro Cliente ou troque a operação.",1)

      Case M->C5_I_OPER = "42" .And. _nPos > 0 
         lRet := .F.
         U_MT_ITMSG("Para operação 42 só é permitido clientes que não correspondam a uma das filiais cadastradas.",;
                  "Atenção",;
                  "Selecione o Cliente que não corresponda a uma Filial cadastrada.",1)

   EndCase
EndIf

//==============================================================
// Solicitação do fiscal. Sempre validar M->C5_I_OPER == "15".
//==============================================================
If lRet 
   If M->C5_I_OPER = "15" .And. !(SA1->A1_TIPO == "F" .And. M->C5_TIPOCLI=="F" .And. (AllTrim(Upper(SA1->A1_INSCR)) == "ISENTO" .Or. Empty(SA1->A1_INSCR)))
      lRet := .F.
      U_MT_ITMSG("Para operação 15 só é permitido clientes do Tipo Consumidor Final com Inscrição Estatual preenchida como ISENTO ou não preenchida.",;
                 "Atenção",;
                 "Selecione outro Cliente ou troque a operação.",1)
   EndIf  
EndIf 

// NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE E SEM TELA "COLOQUE AQUI" ACIMA, ANTES DO End Sequence

//ESSAS VALIDAÇÕES ABAIXO TEM TELAS DEIXE ELAS SEMPRE POR ULTIMO

//Não chama em desmembramento que não é considerado corte
//Não chama no corte da tela de central de pvs que tem a própria chamada de motivo
Private _cJustAG := " "// preenchido na função MT410_JA()
Private _cJustDE := " "// preenchido na função MT410_JA()
Private _cObseAG := " "// preenchido na função MT410_JA()
Private _cObseDE := " "// preenchido na função MT410_JA()
Private _lGrvMon := .F.// preenchido no retorno da função MT410_JA() //GRAVA O MONITOR DEPOIS DE TODAS AS VALIDAÇÕES
If lRet .And. !_laoms074 .And. ParamIXB[1] = 4 .And. M->C5_TIPO = "N" .And. !FWIsInCallStack("U_AOMS099") .AND.;
                                                                            !FWIsInCallStack("U_AOMS109") .AND.;
                                                                            !FWIsInCallStack("U_MOMS047") .AND.;
                                                                            !FWIsInCallStack("U_MOMS066") .AND.;
                                                                            !FWIsInCallStack("U_AOMS108") .AND.;
                                                                            !FWIsInCallStack("U_ITMA521CORRI") .AND.;
                                                                            !FWIsInCallStack("U_OM521BRW")
   M410Proc(oProc,"Verificando alteraçoes com justificativas...")
   Private _lAltData:=SC5->C5_I_DTENT <> M->C5_I_DTENT .And. M->C5_I_AGEND <> "I"//não é necessário justificar a alteração da data de entrega do pedido quando o pedido For Tp Entrega imediato (M->C5_I_AGEND = I)
   Private _lAltAgen:=SC5->C5_I_AGEND <> M->C5_I_AGEND
   _lPrecisaPedir:=!(AllTrim(M->C5_I_OPER) $ AllTrim(SuperGetMV('IT_MPVOP',.T.,'50/51/02')))
   If _lPrecisaPedir .And. _lAltData .Or. _lAltAgen//Se é alteração valida com tela, vê se alterou a data de entrega ou o tipo de agendamento e pergunta o codigo e a obeservaçao da justificativa,  TEM TELA
      lRet:=_lGrvMon:=MT410_JA()//PARA GRAVA NO ZY3 NA FUNÇÃO GrvMonitor() (XFUNOMS.PRW)
   EndIf
   If lRet//Se é alteração valida com tela, vê se é corte e pergunta motivo de corte TEM TELA
      M410Proc(oProc,"Verificando corte...")
      lRet:=MT410_CT()//PARA GRAVA NO Z07 NA FUNÇÃO ITGrvLog() (ITALCXFUN.PRW)
   EndIf
EndIf

//Se é alteração validada com tela vê se é corte e pergunta motivo de corte TEM TELA
End Sequence

SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem
If !lRet .And. ParamIXB[1] = 4//ALTERACAO  CASO devolva .F.
   SC5->(MSRLOCK(SC5->(RECNO())))  //Retrava por garantia
EndIf

// TRATAMENTO PARA  EXCLUI O PEDIDO DE PALLET
If lRet .And. ParamIXB[1] == 4 .And. M->C5_I_GPADV == "S"
   If !Empty(M->C5_I_NPALE)
      lRet := MT410EXCPA(M->C5_I_NPALE)
      If !lRet
         U_MT_ITMSG("Não foi possível excluir o pedido de Pallet: " + M->C5_I_NPALE,;
                 "Atenção",;
                 "O pedido de pallet precisa ser excluido manualmente.",1)
      Else
         M->C5_I_NPALE := ""
      EndIf
   EndIf
EndIf
// TRATAMENTO PARA  EXCLUI O PEDIDO DE PALLET

//***********   Tratamento para PV vinculados - RDC     OPCAO DE TRANSFERENCIA           INCLUSAO         OU  ALTERACAO
If lRet .And. M->C5_TIPO = "N" .And. !_laoms074  .And. !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE") .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4)

    M410Proc(oProc,"PV vinculados")
   _lDiferente:=.F.
   _lAchou:=.F.

   If !Empty(M->C5_I_PEVIN) .And. ( ParamIXB[1] = 3 .Or. Empty(SC5->C5_I_PEVIN) )
      _lAchou:=SC5->(DBSeek(xFilial()+M->C5_I_PEVIN))//Posiciona no Novo
   ElseIf ParamIXB[1] # 3 .And. !Empty(SC5->C5_I_PEVIN)
      If !Empty(M->C5_I_PEVIN) .And. !(SC5->C5_I_PEVIN = M->C5_I_PEVIN) // Tratamento para caso a variavel _lValAltPVin  = .F.
         _lDiferente:=.T.//Trocou o PV vinculado
      EndIf
      _lAchou:=SC5->(DBSeek(xFilial()+SC5->C5_I_PEVIN))//Posiciona no Antigo se _lDiferente = .T.
   EndIf

   //================================================================================
   // Realiza a solicitação de retorno do pedido de vendas que foi vinculado para
   // o sistema RDC, caso este já tenha sido integrado.
   //================================================================================
   If _lAchou
      If ! MT410TOKC(@_lEstornoRDc)
         lRet := .F.
      EndIf

      _nRegVinc := SC5->(Recno())
   EndIf

   //================================================================================
   // NESSA FUNCAO MTPV_VIN TEM GRAVAÇÃO DE DADOS
   //================================================================================
   If lRet
      If MTPV_VIN(_lAchou,_lDiferente)//Posiciona no Antigo se diferente e limpa OU no novo se não é diferente para atualizar
         If _lDiferente// Tratamento para caso a variavel _lValAltPVin  = .F.
            _lAchou:=SC5->(DBSeek(xFilial()+M->C5_I_PEVIN))//Posiciona no Novo
            If !MTPV_VIN(_lAchou) // NESSA FUNCAO TEM GRAVAÇÃO DE DADOS
               lRet:=.F.
            EndIf
         EndIf
      Else
         lRet:=.F.
      EndIf
   EndIf

   SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem SEMPRE
   If ParamIXB[1] = 4//ALTERACAO
      SC5->(MSRLOCK(SC5->(RECNO())))  //Retrava por garantia
   EndIf

EndIf
//***********   Tratamento para PV vinculados  ***********************************

// NÃO INCLUIR NENHUMA ALTERAÇÃO DA VARIÁVEL DE VALIDAÇÃO (lRet) para .F.
// APÓS ESSE TRECHO, POIS SÓ PODE SER EXECUTADO SE O RETORNO DA FUNÇÃO For TRUE
// NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE PROCURE POR "COLOQUE AQUI" E INSIRA AS VALIDACOES LÁ POR FAVOR, NÃO COLOQUE NADA AQUI

//Se For exclusão validada faz a exclusão do ZFQ E ZFR
If lRet .And. (ParamIXB[1] = 1 .Or. ParamIXB[1] = 5)

    ZFQ->(DBSetOrder(3))
    If ZFQ->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

        While ZFQ->ZFQ_FILIAL == SC5->C5_FILIAL .And. ZFQ->ZFQ_PEDIDO == SC5->C5_NUM

            If ZFQ->ZFQ_SITUAC == 'N'

                ZFQ->(RecLock("ZFQ",.F.))
                ZFQ->ZFQ_SITUAC  := "P"
                ZFQ->ZFQ_DATAAL  := Date()
                ZFQ->ZFQ_RETORN  := "Eliminado por exclusão do pedido no SC5"
                ZFQ->(MSUnLock())
                ZFQ->(DBGoTop())
                ZFQ->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

            Else

                ZFQ->(DBSkip())

            EndIf

        EndDo

    EndIf

EndIf

// NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE PROCURE POR "COLOQUE AQUI" E INSIRA AS VALIDACOES LÁ POR FAVOR, ANTES DO End Sequence

M410Proc(oProc," e Executando gravacoes finais")

//================================================================================
// Se estiver validado e existir programação de entrega faz atualização
// da data de entrega
//================================================================================
DBSelectArea("ZF8")
ZF8->( DBSetOrder(2) )

If  lRet .And. ZF8->( DBSeek( SC5->C5_FILIAL + M->C5_NUM ) )

    ZF8->( RecLock( "ZF8", .F. ) )

    ZF8->ZF8_DTENTR := M->C5_I_DTENT

    ZF8->( MSUnLock() )

EndIf

//================================================================================
// Se estiver validado e For alteração de data de entrega inclui monitoria de
// pedido de vendas
//================================================================================
//ALTERACAO OU EXCLUIR DO MENU OU  EXCLUSAO EXECAUTO
If lRet .And. M->C5_TIPO = "N" .And. (ParamIXB[1] = 1 .Or. ParamIXB[1] = 5) .And. ;//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO // ((ParamIXB[1] = 4 .And. M->C5_I_DTENT <> SC5->C5_I_DTENT) .Or.
             !(AllTrim(M->C5_I_OPER) $ AllTrim(SuperGetMV('IT_MPVOP',.T.,'50/51/02')))
    If !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE")
           If ParamIXB[1] = 1 .Or. ParamIXB[1] = 5//EXCLUIR DO MENU  OU  EXCLUSAO EXECAUTO
           _dDTNECE := M->C5_I_DTENT
             _cJUSCOD := "010"//PEDIDO EXCLUÍDO
             _cCOMENT := "Monitor encerrado por exclusão do pedido de vendas"
             _cENCERR := "S"
              U_GrvMonitor(,,_cJUSCOD,_cCOMENT,_cENCERR,_dDTNECE,M->C5_I_DTENT,SC5->C5_I_DTENT)
        EndIf
    EndIf
EndIf

//GRAVA POR JÁ PASSOU POR TODAS AS VALIDAÇÕES
If lRet
   If ParamIXB[1] = 3 .And. (M->C5_I_AGEND = "A" .Or. M->C5_I_AGEND = "M")
      M->C5_I_QTDA:=1
   ElseIf ParamIXB[1] = 4 .And. _lGrvMon .And. _lContOk
      M->C5_I_QTDA:=M->C5_I_QTDA+1
   EndIf
EndIf
If lRet .And. _lGrvMon//GRAVA O MONITOR AQUI POR JÁ PASSOU POR TODAS AS VALIDAÇÕES
   If _lAltData
      _cCOMENT := "Data de entrega modificada de " + DToC(SC5->C5_I_DTENT) + " para " + DToC(M->C5_I_DTENT) + " via alteração de pedido de vendas."
                 //_cFilial,_cNum,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE     ,_dDTFAT      ,_dDTFOLD       , _cObserv, _cVinculoTb, _dDtSugAgen
       U_GrvMonitor(        ,     ,_cJustDE,_cCOMENT,""       ,M->C5_I_DTENT,M->C5_I_DTENT,SC5->C5_I_DTENT,_cObseDE)
   EndIf
   If _lAltAgen
      _cCOMENT := "Tipo de Agendamento modificada de " + SC5->C5_I_AGEND + " para " + M->C5_I_AGEND + " via alteração de pedido de vendas."
                 //_cFilial,_cNum,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE     ,_dDTFAT      ,_dDTFOLD       , _cObserv, _cVinculoTb, _dDtSugAgen
      U_GrvMonitor(        ,     ,_cJustAG,_cCOMENT,""       ,M->C5_I_DTENT,M->C5_I_DTENT,SC5->C5_I_DTENT,_cObseAG)
   EndIf
EndIf

//=====================================================================================
// Enviar pedido de vendas vinculado para o sistema RDC, caso não tenha sido enviado.
//=====================================================================================
//**    INTEGRAÇÃO WEBSERVICE       OPCAO DE TRANSFERENCIA             INCLUSAO    OU  ALTERACAO
If lRet .And. M->C5_TIPO = "N" .And. !_laoms074 .And. !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE")  .And. (ParamIXB[1] = 3 .Or. ParamIXB[1] = 4) .And. !Empty(M->C5_I_PEVIN)
   _nRegSC5 := SC5->(Recno()) // Salva a posição atual do SC5.
   _aOrd := SaveOrd({"SC5"})  // Salva a ordem dos indices.
   _cFilSC5 := SC5->C5_FILIAL

   SC5->(DBSetOrder(1))       // C5_FILIAL+C5_NUM
   If SC5->(DBSeek(_cFilSC5+M->C5_I_PEVIN))  // Posiciona no Pedido de Vendas Vinculado.
      U_RETPVRDC() // Grava na tabela de muro o pedido de vendas vinculado para envio ao sistema RDC.
   EndIf

   SC5->(DBGoTo(_nRegSC5)) // Volta o SC5 para a posição original.
   RestOrd(_aOrd)          // Volta os indices para a posição original.
EndIf

FWRestArea(_aArea)

If ParamIXB[1] = 3
   M->C5_I_DIASV:=0
   M->C5_I_DIASV:=0
EndIf

//Grava campo de data de necessidade de faturamento
If lRet .And. M->C5_TIPO = "N" //.And. !FWIsInCallStack("U_AOMS032") .And. !FWIsInCallStack("U_AOMS032EXE") // Tem que recalcula C5_I_DTNEC na transferencia sim 23/10/24

   _cFilCarreg := xFilial("SC5")
   If ! Empty(M->C5_I_FLFNC)
      _cFilCarreg := M->C5_I_FLFNC
   EndIf
   _lAchouZG5:=.F.
   _cRegra:=""
   M->C5_I_DTNEC := M->C5_I_DTENT - (U_OMSVLDENT(M->C5_I_DTENT,M->C5_CLIENTE,M->C5_LOJACLI,M->C5_I_FILFT,M->C5_NUM,1,  ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN,@_lAchouZG5,@_cRegra,M->C5_I_LOCEM))

   If _lAchouZG5
      If M->C5_I_TPVEN = "F"
         M->C5_I_DIASV:=ZG5->ZG5_DIASV
         M->C5_I_DIASO:=ZG5->ZG5_TMPOPE
      ElseIf M->C5_I_TPVEN = "V"
         M->C5_I_DIASV:=ZG5->ZG5_FRDIAV
         M->C5_I_DIASO:=ZG5->ZG5_FRTOP
      EndIf
   EndIf

EndIf

If !lRet .And. M->C5_TIPO = "N" //Se não validou alteração do pedido libera os locks preventivos e cancela transação

    DisarmTransaction()
    SB2->(DBUNLOCK())
    SA1->(DBUNLOCK())
    MSUnLockAll()

    //===================================================================================
    // Houve um estorno do pedido de vendas do sistema RDC, mas uma das
    // validações não permitiu a gravação do pedido, então voltamos o pedido de vendas
    // para o sistema RDC desde que não esteja no webservice
    //===================================================================================
    If _lEstornoRDc .And. !_laoms074  .And. !_lAoms112
       SC5->(DBGoTo(_nRegVinc))
       U_RETPVRDC() // Grava tabelas de muro para envio ao sistema RDC.
       SC5->(DBGoTo(_nRecOrigem))
    EndIf
EndIf

// NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE PROCURE POR "COLOQUE AQUI" E INSIRA AS VALIDACOES LÁ POR FAVOR, NÃO COLOQUE NADA AQUI

If Type("lMsErroAuto") = "L" .And. !lRet .And. !lMsErroAuto//Só altera o conteudo do lMsErroAuto se ele tiver Falso e o retorno For falso
   lMsErroAuto:=!lRet//Só Joga verdadeiro de For o caso
EndIf

N := _nSalvaN

// NOVAS VALIDAÇOES SEM GRAVAÇÃO NA BASE PROCURE POR "COLOQUE AQUI" E INSIRA AS VALIDACOES LÁ POR FAVOR, NÃO COLOQUE NADA AQUI

Return( lRet )

/*
===============================================================================================================================
Programa----------: somContrato
Autor-------------: Fabiano Dias
Data da Criacao---: 02/12/2009
Descrição---------: Funcao utilizada para efetuar o somatorio do valor descontato na inclusao, alteracao, e copia dos itens de
------------------: um pedido de venda, e pegar o numero do contrato de desconto contratual.
Parametros--------: Nenhum
Retorno-----------: Lógico - define se podera realizar a operacao de inclusao, alteracao ou copia
===============================================================================================================================
*/
Static Function somContrato()

Local aArea			:= FWGetArea()
Local nX			:= 0
Local nN			:= N //Restaura o valor de n, que eh a variavel publica do protheus que indica a linha do aCols.
Local aDados		:= {0,.T.,.T.,""}
Local cNumContr		:= ""
Local lRet			:= .T. //Armazena se podera ser efetuada a alteracao, copia e inclusao de acordo com a vigencia dos dados do contrato
Local nProduto		:= aScan( aHeader , {|X| Upper(AllTrim(X[2])) == "C6_PRODUTO"	} )//Produto
Local nPosPerc		:= aScan( aHeader , {|x| Upper(AllTrim(x[2])) == "C6_I_PDESC"	} )

Private nTES		:= aScan( aHeader , {|X| Upper(AllTrim(X[2])) == "C6_TES"		} )

For nX := 1 To Len(aCols)

    //======================================================================
    // Atualiza o valor de N
    //======================================================================
    N := nX

    //======================================================================
    //Se a linha nao estiver deletada
    //======================================================================
    If !aCols[n][Len(aCols[n])]

        //======================================================================
        // Caso o usuario tenha fornecido uma TES verifica se tem contrato
        //======================================================================
        If !Empty(aCols[n][nTES])

            //======================================================================
            // Se a TES gerar financeiro busca dados de desconto contratual
            //======================================================================
            If (Posicione("SF4",1,xFilial("SF4") + aCols[n][nTES],"F4_DUPLIC") == 'S')

                aDados := u_veriContrato( M->C5_CLIENTE , M->C5_LOJACLI , aCols[n][nProduto] )

                //======================================================================
                // Se tem desconto
                //======================================================================
                If aDados[1] > 0

                    aCols[n,nPosPerc] := aDados[1]
                    //Para gravar os percentuais de todos os produtos eh necessario chamar a VeriContrato item a item

                Else

                    aCols[n,nPosPerc] := 0

                EndIf

                aCols[N,_nPosPrNet] := aCols[N,nPosPreco] - ((aCols[N,nPosPreco] * aCols[N,nPosPerc]) / 100)

                cNumContr := aDados[4] //Armazena o numero do contrato

                //======================================================================
                // Contrato nao esta aprovado pelo financeiro
                //======================================================================
                If !aDados[2]

                    lRet := .F.


                     U_MT_ITMSG(	'Pedido '+M->C5_NUM + " O contrato de desconto de venda: "+ cNumContr +" esta ativo para este cliente, aguardando somente a aprovacao do financeiro. "	+;
                                     "Solicite ao departamento financeiro a sua liberação antes de efetuar o pedido de venda."										,;
                                     "Validação de contrato",;
                                     "Ou solicite ao departamento comercial para que seja efetuado o bloqueio do contrato: "+ cNumContr,1								 )

                     Exit

                EndIf

                 //======================================================================
                // Contrato nao esta com a data de vigencia em vigor
                //======================================================================
                If !aDados[3]

                    lRet := .F.


                    U_MT_ITMSG(	'Pedido '+M->C5_NUM + " utiliza contrato de desconto "+ cNumContr	+;
                                    " ativo que esta com a data de vigencia vencida."				,;
                                    "Validação Contrato",;
                                    "Entrar em contato com o depto comercial",1						 )

                    Exit

                EndIf

            EndIf

        EndIf

    EndIf

Next nX

M->C5_I_NRZAZ:= cNumContr //Numero do contrato de desconto contratual

FWRestArea(aArea)

N:= nN //Restaura o valor de n, que eh a variavel publica do protheus que indica a linha do aCols.

Return( lRet )

/*
===============================================================================================================================
Programa----------: valida2Um
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2010
Descrição---------: Funcao utilizada para validar no pedido de venda se o usuario esta infomando um valor na segunda unidade
------------------: de medida quando o produto nao possui uma segunda unidade de medida ou fator de conversao no seu cadastro
------------------: de produto.
Parametros--------: Nenhum
Retorno-----------: Lógico - Define se o cadastro do produto possui inconsistências
===============================================================================================================================
*/

Static Function valida2Um()

Local nProduto	:=  aScan( aHeader , {|X| Upper( AllTrim( X[2] ) )	== "C6_PRODUTO"	} ) //Produto
Local nPosQtd2	:=  aScan( aHeader , {|x| AllTrim( x[2] )			== "C6_UNSVEN"	} )

Local aArea		:= FWGetArea()
Local lRet		:= .T.
Local nOld		:= n,nX

For nX := 1 To Len(aCols)

    n := nX

    //================================================================================
    // Se a linha nao estiver deletada
    //================================================================================
    If !aCols[n][Len(aCols[n])]

        //================================================================================
        // Caso haja inconsistencia no cadastro de produto zerar a 2 qtde de medida
        //================================================================================
        If !vldQtde2um( aCols[n,nProduto] , aCols[n,nPosQtd2] )
            lRet := .F.
            Exit
        EndIf

    EndIf

Next nx

n := nOld

FWRestArea(aArea)

Return( lRet )

/*
===============================================================================================================================
Programa----------: vldQtde2um
Autor-------------: Fabiano Dias
Data da Criacao---: 31/03/2010
Descrição---------: Funcao utilizada para validar no pedido de venda se o usuario esta infomando um valor na segunda unidade
------------------: de medida quando o produto nao possui uma segunda unidade de medida ou fator de conversao no seu cadastro
------------------: de produto.
Parametros--------: cproduto - produto a validar
                    qtdesegum - quantidade informada na segunda unidade
Retorno-----------: Verdadeiro - Caso encontre inconsistencia no cadastro do produto de acordo com a descricao citada acima
------------------: Falso - O cadastro do produto esta ok
===============================================================================================================================
*/
Static Function vldQtde2um(cProduto,qtdesegum)

Local cFiltro:= "%"
Local lRet:= .T.

If Select("QRYTMP2UM") > 0
    DBSelectArea("QRYTMP2UM")
    DBCloseArea()
EndIf

//Filtros

//Para o caso de algum dia o cadastro de produtos deixar de ser compartilhado
If !Empty(xFilial("SB1"))
    cFiltro+= " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
EndIf

cFiltro+= " AND SB1.B1_COD = '" + cProduto + "'"

cFiltro+= "%"

BeginSql alias "QRYTMP2UM"
    SELECT
    B1_SEGUM,B1_CONV,B1_GRUPO
    FROM
    %Table:SB1% SB1
    WHERE
    SB1.%notDel%
    %exp:cFiltro%
EndSql

DBSelectArea("QRYTMP2UM")

If QRYTMP2UM->(!Eof())
    If (Empty(QRYTMP2UM->B1_SEGUM) .And. QRYTMP2UM->B1_CONV <> 0) .Or. (qtdesegum > 0 .And. Empty(QRYTMP2UM->B1_SEGUM))
        lRet:= .F.
    EndIf
EndIf

DBSelectArea("QRYTMP2UM")
DBCloseArea()

Return lRet

/*
===============================================================================================================================
Programa----------: vldTESBloq
Autor-------------: Fabiano Dias
Data da Criacao---: 28/09/2010
Descrição---------: Funcao utilizada para validar no pedido de venda se TES fornecida nao esta bloqueada, pois este tipo de
------------------: bloqueio somente pode ser feito por ponto de entrada.
Parametros--------: Nenhum
Retorno-----------: Lógico - Define se todas as TES estão liberadas para uso
===============================================================================================================================
*/

Static Function vldTESBloq()

Local nTES	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_TES" } )
Local _nProduto := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_PRODUTO" } )

Local aArea	:= FWGetArea()
Local lRet	:= .T.  , nx
Local nOld	:= n

For nX := 1 To Len(aCols)

    n := nX

    //================================================================================
    // Se a linha nao estiver deletada
    //================================================================================
    If !aCols[n][Len(aCols[n])]
       //================================================================================
       // Verifica se a TES esta bloqueada
       //================================================================================
       If AllTrim(Posicione("SF4",1,xFilial("SF4") + aCols[n][nTES],"F4_MSBLQL")) == '1'
          lRet := .F.
       EndIf

       //================================================================================
       // Verifica se há contradição entre a TES que diz para não movimentar estoques
       // e a configuração do produto que diz para movimentar estoque.
       //================================================================================
       If AllTrim(Posicione("SF4",1,xFilial("SF4") + aCols[n][nTES],"F4_ESTOQUE")) == "N" .And.;
          AllTrim(Posicione("SB5",1,xFilial("SB5") + aCols[n][_nProduto],"B5_I_ESTOB")) == "S"

          U_MT_ITMSG("Ped.: " + M->C5_NUM + " O Produto " + AllTrim(aCols[n][_nProduto]) + " exige movimento de estoque e a TES " + AllTrim(aCols[n][nTES]) + " não movimenta estoque!",;
                  "Validação TES",,1 )

          lRet := .F.

       EndIf
    EndIf

Next nx

//================================================================================
// Caso tenha encontrada alguma TES Bloqueada que esteja em copia de pediddo
//================================================================================
If !lRet


    U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Não poderá ser realizada a cópia/alteração deste pedido, pois possui TES bloqueada"			,;
                    "Validação TES",;
                    "Favor contactar o departamento fiscal.",1	 )

EndIf

n := nOld

FWRestArea(aArea)

Return( lRet )

/*
===============================================================================================================================
Programa----------: vldEmail
Autor-------------: Fabiano Dias
Data da Criacao---: 14/02/2011
Descrição---------: Funcao utilizada para validar na inclusao, alteracao ou copia do pedido de venda o campo e-mail do cliente
------------------: ou e-mail para verificar se o mesmo encontra-se com algum tipo de problema.
Parametros--------: Nenhum
Retorno-----------: Lógico - Define se o campo e-mail foi preenchido corretamente.
===============================================================================================================================
*/
User Function vldEmail()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.

//================================================================================
// Caso o tipo do pedido de venda seja dos tipos:
//   N= Normal
//   C= Complemento de Precos
//   I= Complemento de ICMS
//   P= Complemento de IPI
// Sera efetuada uma busca na tabela SA1 pelo e-mail do cliente
// para posterior averiguacao.
//================================================================================
If M->C5_TIPO $ 'N/C/I/P'

    DBSelectArea("SA1")
    SA1->( DBSetOrder(1) )
    If SA1->( DBSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI ) )

        _lRet := U_EEmail( AllTrim( SA1->A1_EMAIL ) )

        If !_lRet .And. M->C5_I_OPER == '02'

            _lRet := .T.

        ElseIf !_lRet


            U_MT_ITMSG(	'Pedido  '+M->C5_NUM + " Foi encontrado um problema no E-MAIL do cliente: "+ CRLF + CRLF + M->C5_CLIENTE +'/'+ M->C5_LOJACLI +'-'+ SA1->A1_NOME,;
                            "Validação Email",;
                            "Favor alterar o cadastro do cliente antes de efetuar a conclusão desta operação, pois o mesmo encontra-se vazio ou com formato inválido.",1	 )

        EndIf

    EndIf

//================================================================================
// Caso o tipo do pedido de venda seja dos tipos:
//   D= Devolucao de compras
//   B= Utiliza Fornecedor
// Sera efetuada uma busca na tabela SA2 pelo e-mail do fornecedor para posterior
// averiguacao.
//================================================================================
ElseIf M->C5_TIPO $ 'D/B'

    DBSelectArea("SA2")
    SA2->( DBSetOrder(1) )
    If SA2->( DBSeek( xFilial("SA2") + M->C5_CLIENTE + M->C5_LOJACLI ) )

        _lRet := U_EEmail( AllTrim( SA2->A2_EMAIL ) )

        If !_lRet .And. M->C5_I_OPER == '02'

            _lRet := .T.

        ElseIf !_lRet


            U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Foi encontrado um problema no E-MAIL do fornecedor: "+ CRLF + CRLF + M->C5_CLIENTE +'/'+ M->C5_LOJACLI +'-'+ SA2->A2_NOME,;
                         "Validação Email",;
                            "Favor alterar o cadastro do fornecedor antes de efetuar a conclusão desta operação, pois o mesmo encontra-se vazio ou com formato inválido.",1	 )

        EndIf

    EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: vldCoorden
Autor-------------: Fabiano Dias
Data da Criacao---: 09/03/2011
Descrição---------: Funcao utilizada para validar o coordenador informado no pedido para constatar se este eh igual ao da regra
------------------: de comissao eh o mesmo do cadastro do vendedor.
Parametros--------: _cVendedor - Codigo do Vendedor
------------------: _cCoorden  - Codigo do Coordenador
------------------: _cDesCoord - Descricao do Coordenador
Retorno-----------: Lógico - Define se as informações estão corretas
===============================================================================================================================
*/
Static Function vldCoorden( _cVendedor , _cCoorden , _cDesCoord , _cCliente , _cLojaCli , _cCodGeren )

Local _cAlias		:= GetNextAlias()
Local _cAliasSA3	:= GetNextAlias()
Local _cAliasVal	:= ""
Local _cAliasSA1	:= ""

Local _lRet			:= .T.
Local _cFiltro		:= ""
Local _cFiltrSA3	:= ""
Local _cFiltrSA1	:= ""
Local _cFilSA3		:= ""

Local _cCodCoZAE	:= ""
Local _cCodExc		:= AllTrim( GetMV( 'IT_COMEXCR' ,, '' ) )

Local _lPedUnitz	:= .F.
Local x

Local _nPosProd  :=  aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "C6_PRODUTO"})

//===============================================================
//|Percorre todos os itens do pedido de venda para constatar    |
//|se este eh um pedido de PALLET, pois os pedidos de pallet    |
//|sao feitos de forma sepada dos outros pedidos de venda, sendo|
//|que os pedidos de PALLET nao devem entrar na validacao.      |
//===============================================================
For x:=1 To Len(aCols)

    //===============================================
    //|Verifica se a linha nao se encontra deletada.|
    //===============================================
    If !aCols[x,Len(aHeader)+1]

        //============================================
        //|Grupo de produtos dos unitizadores == 0813|
        //============================================
        If SubStr(aCols[x,_nPosProd],1,4) == '0813'

            _lPedUnitz:= .T.
            Exit

        EndIf

    EndIf

Next x

//========================================================================
//|Somente quando o tipo do pedido de venda For igual a normal  		 |
//========================================================================
If M->C5_TIPO == 'N' .And. !_lPedUnitz .And. FUNNAME() != "AOMS003"

    _cFiltro := "% "
    _cFiltro += "     D_E_L_E_T_ = ' ' "
    _cFiltro += " AND ZAE_VEND   = '"+ _cVendedor +"' "
    _cFiltro += " %"

    BeginSql alias _cAlias

        SELECT		ZAE_CODSUP, ZAE_MSBLQL
        FROM		%Table:ZAE%
        WHERE		%exp:_cFiltro%
        GROUP BY	ZAE_CODSUP, ZAE_MSBLQL

    EndSql

    DBSelectArea(_cAlias)
    (_cAlias)->( DBGoTop() )
    If (_cAlias)->( !Eof() )

        If (_cAlias)->ZAE_MSBLQL == '1'

            _lRet := .F.

            //U_MT_ITMSG(_cMens,_cTitu,_cSolu,_ntipo
            U_MT_ITMSG('O cadastro das regras de comissão do '+;
                    'vendedor informado no pedido de venda '+;
                    'está bloqueado!'						,;
                    'Atencao(MT410TOK) P:'+M->C5_NUM        ,;
                    'Para confirmar o pedido, verifique o ' +;
                    'vendedor informado e/ou o cadastro das '+;
                    'regras de comissão para o mesmo.', 1 )

        EndIf

        If _lRet

            _cCodCoZAE := AllTrim( (_cAlias)->ZAE_CODSUP )

            //==============================================================
            //|Pesquisa o coordenador cadastradado no cadastro de vendedor.|
            //==============================================================
            _cFiltrSA3 := "% "
            _cFiltrSA3 += "     D_E_L_E_T_ = ' ' "
            _cFiltrSA3 += " AND A3_COD     = '"+ _cVendedor +"' "
            _cFiltrSA3 += " %"

            BeginSql alias _cAliasSA3

                SELECT	A3_SUPER
                FROM	%Table:SA3%
                WHERE	%exp:_cFiltrSA3%

            EndSql

            DBSelectArea(_cAliasSA3)
            (_cAliasSA3)->( DBGoTop() )

            //==================================================================
            //|Verifica se existe divergencia de cadastros na regra de comissao|
            //|com o cadastro de vendedor.                                     |
            //==================================================================
            If _cCodCoZAE <> AllTrim( (_cAliasSA3)->A3_SUPER )

                _lRet := .F.

                U_MT_ITMSG( 		 	'O cadastro do vendedor informado no '		+;
                                    'pedido de venda está com divergências '	+;
                                    'com relação às regras de comissão!'		,;
                                    'Atencao(MT410TOK) P:'+M->C5_NUM            ,;
                                     'O coordenador amarrado ao vendedor não '	+;
                                    'é o mesmo que está cadastrado nas regras '	+;
                                    'de comissão para o mesmo.'					, 1 )

            ElseIf _cCodCoZAE <>  AllTrim(_cCoorden)

                _lRet   := .F.

                U_MT_ITMSG(		    'O coordenador de vendas informado no '		+;
                                    'pedido de venda está com divergências '	+;
                                    'com relação às regras de comissão!'		,;
                                    'Atencao(MT410TOK) P:'+M->C5_NUM            ,;
                                     'Selecione novamente o vendedor no pedido '	+;
                                    'de venda para atualizar os dados do '		+;
                                    'cadastro ou verifique o cadastro do '		+;
                                    'vendedor para atualizar as informações!'	,1)

            EndIf

            DBSelectArea( _cAliasSA3 )
            (_cAliasSA3)->( DBCloseArea() )

        EndIf

    Else

        If Empty(_cCodExc) .Or. !( _cVendedor $ _cCodExc )

            _lRet   := .F.

            U_MT_ITMSG(			'O vendedor informado não possui regras de '+;
                                'comissão cadastradas no sistema!'			,;
                                 'Atencao(MT410TOK) P:'+M->C5_NUM+;
                                 'Para confirmar o pedido, verifique o '		+;
                                'vendedor informado e/ou o cadastro das '	+;
                                'regras de comissão para o mesmo.'			,,1 )

        EndIf

    EndIf

    DBSelectArea(_cAlias)
    (_cAlias)->( DBCloseArea() )

    //Verifca se o vendedor informado no pedido esta amarrado ao cliente e loja informados.
    If _lRet

        _cAliasSA1 := GetNextAlias()

        _cFiltrSA1 := "% "
        _cFiltrSA1 += "     D_E_L_E_T_ = ' ' "
        _cFiltrSA1 += " AND A1_COD     = '"+ _cCliente +"' "
        _cFiltrSA1 += " AND A1_LOJA    = '"+ _cLojaCli +"' "
        _cFiltrSA1 += " %"

        BeginSql alias _cAliasSA1

            SELECT	A1_VEND,A1_I_VEND2
            FROM	%Table:SA1%
            WHERE	%exp:_cFiltrSA1%

        EndSql

        DBSelectArea(_cAliasSA1)
        (_cAliasSA1)->( DBGoTop() )
        //Não validar quando For opercao 05 por causa do portal e operacao triangular
        If M->C5_I_OPER  <> "05" .And. (_cAliasSA1)->A1_VEND <> _cVendedor .And. (_cAliasSA1)->A1_I_VEND2 <> _cVendedor

            _lRet := .F.

            U_MT_ITMSG(			'O vendedor informado no pedido de vendas '		+;
                                'está divergente do informado no cadastro '		+;
                                'do cliente ou o cliente não está amarrado '	+;
                                'à um vendedor responsável válido.'				,;
                                 'Atencao(MT410TOK) P:'+M->C5_NUM,;
                                 'Informe um vendedor que esteja amarrado '		+;
                                'ao cadastro do cliente ou verifique o '		+;
                                'cadastro do cliente para completar as '		+;
                                'informações necessárias.'						,1 )

        EndIf

        DBSelectArea(_cAliasSA1)
        (_cAliasSA1)->( DBCloseArea() )

    EndIf

    //=================================================================
    //|Valida se o coordenador e gerente informados no pedido de venda|
    //|são os mesmos informados no cadastro do vendedor.              |
    //=================================================================
    If _lRet

        _cAliasVal:= GetNextAlias()

        //=======================================================================
        //|Pesquisa o coordenador e gerente informados no cadastro de vendedor. |
        //=======================================================================
        _cFilSA3 := "% "
        _cFilSA3 += "     D_E_L_E_T_ = ' ' "
        _cFilSA3 += " AND A3_COD     = '"+ _cVendedor +"' "
        _cFilSA3 += " %"

        BeginSql alias _cAliasVal

            SELECT	A3_SUPER , A3_GEREN
            FROM	%Table:SA3%
            WHERE	%exp:_cFilSA3%

        EndSql

        DBSelectArea(_cAliasVal)
        (_cAliasVal)->( DBGoTop() )

        If (_cAliasVal)->( !Eof() )

            If (_cAliasVal)->A3_SUPER <> _cCoorden .Or. (_cAliasVal)->A3_GEREN <> _cCodGeren

                _lRet:= .F.

                U_MT_ITMSG(			'O cadastro do vendedor não está amarrado '		+;
                                    'ao coordenador/gerente informados no '			+;
                                    'pedido de venda atual. '						,;
                                     'Atencao(MT410TOK) P:'+M->C5_NUM,;
                                     'Selecione novamente o vendedor no pedido '		+;
                                    'de venda para atualizar os dados do '			+;
                                    'cadastro ou verifique o cadastro do '			+;
                                    'vendedor para atualizar as informações!'		,1)

            EndIf

        EndIf

        DBSelectArea(_cAliasVal)
        (_cAliasVal)->( DBCloseArea() )

    EndIf

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: vldTpOper
Autor-------------: Fabiano Dias
Data da Criacao---: 25/10/2011
Descrição---------: Funcao utilizada para validar o tipo de operacao fornecida diante do cliente informado no pedido de venda.
Parametros--------: aCols - Dados dos ítens do pedido de venda
Retorno-----------: Lógico - Define se o tipo utilizado é válido.
===============================================================================================================================
*/
Static Function vldTpOper()

Local _lRet		:= .T.
Local _cTpOper2	:= GETMV("IT_TPOPER2") //Armazena o tipo de operacao que na TES INTELIGENTE pode ser utilizado para cliente 000001 - Italac //Lucas Borges Ferreira - 09/05/2012
Local _cTpOper3	:= GETMV("IT_TPOPER3")
Local _cFiltro	:= ""
Local cAliasSRA	:= "SRA"

//===================================================================
//|Operacao que estiverem contidas no parametro IT_TPOPER2 so pode- |
//|rao ser utilizadas para o cliente 000001, ou seja, a propria 	|
//|ITALAC e suas lojas. 		|
//|Alterado para que seja validada as operacoes que estiverem no    |
//|parametroIT_TPOPER2.												|
//===================================================================
If M->C5_I_OPER $ AllTrim(_cTpOper2)

    If M->C5_CLIENTE <> '000001'


        U_MT_ITMSG(	'Pedido.: '+M->C5_NUM + " Para o tipo de operacao: "+ AllTrim(_cTpOper2)+", somente podera ser informado o cliente 000001(ITALAC)."	,;
                    "Validação de operação",;
                        "Favor verificar se o tipo de operacao indicado esta correto, ou alterar o codigo do cliente informado.",1	 )

        _lRet := .F.

    EndIf

//==============================================================================
//|Outros tipo de operacao nao podem ter como cliente o codigo: 000001(ITALAC).|
//==============================================================================
Else

    If M->C5_CLIENTE == '000001'


        U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Para o tipo de operacao diferente de: "+ AllTrim(_cTpOper2) +", nao podera ser informado o cliente 000001(ITALAC)."	,;
                    "Validação de operação",;
                        "Favor verificar se o tipo de operacao indicado esta correto, ou alterar o codigo do cliente informado.",1				 )

        _lRet := .F.

    EndIf

EndIf

//===================================================================
//|Operacao que estiverem contidas no parametro IT_TPOPER3 so pode- |
//|rao ser utilizadas para cliente que são funcionários ativos.     |
//|Incluida validação para     |
//|venda para funcionários										    |
//===================================================================
If M->C5_I_OPER $ AllTrim(_cTpOper3) .And. M->C5_CLIENTE <> ' '

    DBSelectArea("SA1")
    SA1->( DBSetOrder(1) )
    SA1->( DBSeek( xFilial("SA1") + M->( C5_CLIENTE + C5_LOJACLI ) ) )

    _cFiltro := "% "
    _cFiltro += "     D_E_L_E_T_ = ' '
    _cFiltro += " AND RA_SITFOLH IN (' ','F','A')
    _cFiltro += " AND RA_CATFUNC IN ('M','E')
    _cFiltro += " AND RA_CIC     = '"+ SA1->A1_CGC +"' "
    _cFiltro += " %"

    cAliasSRA := GetNextAlias()

    BeginSql Alias cAliasSRA

        SELECT RA_MAT
        FROM	%Table:SRA%
        WHERE	%exp:_cFiltro%

    EndSql

    If (cAliasSRA)->(Eof()) .Or. (cAliasSRA)->(Bof())

           U_MT_ITMSG(	'Pedido '+M->C5_NUM + " Para o tipo de operacao: "+ AllTrim(_cTpOper3) +", somente poderão ser informados clientes que também são funcionários."	,;
                       "Validação de operação",;
                           "Favor verificar se o tipo de operacao indicado esta correto, ou alterar o codigo do cliente informado.",1					 )

        _lRet := .F.

    Else
      //================================================================================
      // Bloquear a compra de produtos por funcionários afastados.
      //================================================================================
       SR8->(DBSetOrder(1))  // R8_FILIAL+R8_MAT+DToS(R8_DATAINI)+R8_TIPO
       SR8->(DBSeek(xFilial("SR8")+(cAliasSRA)->RA_MAT))
       While ! SR8->(Eof()) .And. SR8->R8_FILIAL+SR8->R8_MAT == xFilial("SR8")+(cAliasSRA)->RA_MAT
           If SR8->R8_TIPO <> "Q" .Or. SR8->R8_TIPO <> "F"
            _lRet := .T.
             Exit
        Else
          If (Empty(SR8->R8_DATAFIM) .Or. SR8->R8_DATAFIM >= Date())

             U_MT_ITMSG('Pedido '+M->C5_NUM + "Funcionários com situação afastado não podem fazer pedidos de compras."	  ,;
                         "Validação pedido funcionário",;
                              "Os funcionários devem estar com situação ativo, para que os pedidos de compras possam ser realizados.",1	 )
            _lRet := .F.
            Exit
          EndIf
        EndIf

          SR8->(DBSkip())
       EndDo
    EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: VldPeca
Autor-------------: Lucas Crevilari
Data da Criacao---: 04/09/2014
Descrição---------: Funcao utilizada para validar as quantidades (Qtd e Qtd 2a UM).Chamado 7182
Parametros--------: Nenhum
Retorno-----------: ( .T. ) Dados validos para inclusao ( .F. ) caso contrario.
===============================================================================================================================
*/
Static Function VldPeca(nx)

Local _cOperEst		:= SuperGetMV("IT_OPEEST",.T.,"")	// Tipos de operações que não valida quantidade fracionada
Local _cProdPe		:= SuperGetMV("IT_PRODPE",.T.,"")	// Produtos permitidos que não validam quantidades fracinadas
Local _cLocval		:= SuperGetMV("IT_LOCFRA",.T.,"")	// Armazéns que não valida quantidade fracionada
Local _nPosProduto, _nPosLoc
Local _cProdNFrac   := SuperGetMV("IT_PRDNFRA",.T.,"")	// Produtos proibidos de serem fracionados na Venda.
Local _cLocalNFrac  := SuperGetMV("IT_LOCNFRA",.T.,"")	// Armazens/Locais vinculados aos produtos proibidos de serem fracionados na Venda.
Local _cTipOpNFrac  := SuperGetMV("IT_TPONFRA",.T.,"")	// Tipos de Operações vinculados aos produtos proibidos de serem fracionados na Venda.

_nQuant2	:=	aScan(aHeader,{|nx|Upper(AllTrim(nx[2]))	== "C6_UNSVEN"})
_nQtdPrd	:=  aScan(aHeader,{|nx|Upper(AllTrim(nx[2]))	== "C6_QTDVEN"})

_nPosProduto:=  aScan(aHeader,{|nx|Upper(AllTrim(nx[2]))	== "C6_PRODUTO"})
_nPosLoc    :=  aScan(aHeader,{|nx|Upper(AllTrim(nx[2]))	== "C6_LOCAL"})

nQtdProd 	:= Acols[nx][_nQtdPrd]
nQtd2UM 	:= Acols[nx][_nQuant2]
cNumIt		:= Acols[nx][1]
cDescIt		:= AllTrim(Acols[nx][3])

//================================================================================
// Se um produto estiver contido no parâmetro IT_PRDNFRAC e se o armazem
// estiver no parâmetro IT_LOCNFRAC ou o tipo de oparação estiver no parâmetro
// IT_TPONFRAC, obrigatóriamente deverá validar as quantidades fracionadas.
//================================================================================
If AllTrim(aCols[nx,_nPosProduto]) $ _cProdNFrac .And. (AllTrim(aCols[nx,_nPosLoc]) $ _cLocalNFrac .Or. M->C5_I_OPER $ _cTipOpNFrac)
   //================================================================================
   // Realiza a validação fracionamento de produtos na segunda unidade de medida.
   //================================================================================
   If nQtd2UM <> Int(nQtd2UM)
      U_MT_ITMSG("O produto" +AllTrim(SB1->B1_DESC)+" não pode ser vendido com quantidade fracionada na Segunda Unidade de Medida.",;
                 "Validação Fracionado",;
                 "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)
      lRet:= .F.
      Return .F.
   EndIf
Else
   //================================================================================
   // As condições das 3 linhas a seguir, determinam se haverá ou não validação sobre
   // fracionamento da segunda unidade de medida.
   //================================================================================
   If !(M->C5_I_OPER $ _cOperEst)
      If !(AllTrim(aCols[nx,_nPosProduto]) $ _cProdPe)
         If !(AllTrim(aCols[nx,_nPosLoc]) $ _cLocval)
            //================================================================================
            // Realiza a validação fracionamento de produtos na segunda unidade de medida.
            //================================================================================
            If nQtd2UM <> Int(nQtd2UM)
               U_MT_ITMSG("O produto" +AllTrim(SB1->B1_DESC)+" não pode ser vendido com quantidade fracionada na Segunda Unidade de Medida.",;
                          "Validação Fracionado",;
                          "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)
               lRet:= .F.
               Return .F.
            EndIf
         EndIf
      EndIf
   EndIf
EndIf

nVlrPeca := nQtdProd / nQtd2UM

nFtMin := Posicione("SB1",1,xFilial("SB1")+cNumPrd,"B1_I_FTMIN")
nFtMax := Posicione("SB1",1,xFilial("SB1")+cNumPrd,"B1_I_FTMAX")

If nVlrPeca < nFtMin .Or. nVlrPeca > nFtMax //Fora dos limites: menor que o Minimo ou maior que o Maximo
    aAdd(aItens,{cNumIt,cDescIt,nQtdProd,nQtd2UM,nVlrPeca, nx})
    Return  .F.
EndIf

Return  .T.

/*
===============================================================================================================================
Programa----------: VldDev
Autor-------------: Lucas Crevilari
Data da Criacao---: 11/09/2014
Descrição---------: Funcao utilizada para verificar se é Devolucao de Diferenca de Pesagem. Chamado 7182
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VldDev(nx)

_cDoc 		:= SC5->C5_NOTA 	 //aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_NOTA"})
_cSerie 	:= SC5->C5_SERIE 	 //aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_SERIE"})
_cCliente 	:= M->C5_CLIENTE //aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_CLI"})
_cLoja 		:= M->C5_LOJACLI //aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_LOJA"})
_cProduto 	:= aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_PRODUTO"})

DBSelectArea("SD2")
DBSetOrder(3)
If DBSeek(xFilial("SD2")+_cDoc+_cSerie+_cCliente+_cLoja+Acols[nx,_cProduto])
    RecLock("SD2")
    IIf(lDifPes,cExpressao := "S", cExpressao := "N")
    Replace D2_I_DIFPE With cExpressao
    SD2->(MSUnLock())
EndIf

_cDifPes := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C6_I_DIFPE"}) //Diferenca de Pesagem.

If lDifPes
    Acols[nx,_cDifPes] := "S"
Else
    Acols[nx,_cDifPes] := "N"
EndIf

Return

/*
===============================================================================================================================
Programa----------: vldPedFun
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2015
Descrição---------: Funcao utilizada para verificar atraves da CFOP se o pedido de venda corrente é de venda para funcionário
/produtor e limitar o valor de limite de crédito do mesmo
Parametros--------: aCols - Dados dos ítens do pedido de venda
Retorno-----------: Lógico - Define se o registro deverá ser bloqueado
===============================================================================================================================
*/
Static Function vldPedFun( aCols )

Local _lRet		:= .F.
Local _x			:= 1
Local _npedabr 	:= 0

Local _cCFOP	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_CF"	} )
Local _nValor	:= aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_VALOR"	} )

Local _nSomator	:= 0
Local _nlimcre	:= 0

//só verifica para pedido normal de venda
If M->C5_TIPO = "N"

    //verifica se cliente ativo e puxa limite de crédito
    DBSelectArea("SA1")
    SA1->( DBSetOrder(1) )
    SA1->( DBSeek( xFilial("SA1") + M->( C5_CLIENTE + C5_LOJACLI ) ) )


    _cFiltro := "% "
    _cFiltro += "     D_E_L_E_T_ = ' '   "
    _cFiltro += " AND RA_CIC     = '"+ SA1->A1_CGC +"' "
    _cFiltro += " %"


    //verifica se é fornecedor produtor
    _cFiltro2 := "% "
    _cFiltro2 += "     D_E_L_E_T_ = ' ' "
    _cFiltro2 += " AND A2_I_CLASS = 'P' AND A2_MSBLQL <> '1' "
    _cFiltro2 += " AND A2_CGC     = '"+ SA1->A1_CGC +"' "
    _cFiltro2 += " %"


    cAliasSRA := GetNextAlias()

    BeginSql Alias cAliasSRA

        SELECT	RA_CIC
        FROM	%Table:SRA%
        WHERE	%exp:_cFiltro%
        UNION ALL
        SELECT A2_CGC
        FROM %Table:SA2%
        WHERE %exp:_cFiltro2%

    EndSql

    If (cAliasSRA)->( Eof())
        _lRet := .T.
    EndIf

    (cAliasSRA)->( DBCloseArea())
Else
    //Se não é pedido normal já deixa validado
    _lRet := .T.
EndIf

If .not. _lRet
    //Verifica tipo de crédito e carrega se For tipo A ou B, também carrega o total de pedidos em abero
    If SA1->A1_RISCO == "A"
        _lRet := .T.
    ElseIf SA1->A1_RISCO == "B"
        If SA1->A1_VENCLC >= Date()
            _nlimcre := SA1->A1_LC

            _cFiltro := "% "
            _cFiltro += "     C6.D_E_L_E_T_ = ' '
            _cFiltro += " AND C6.C6_CLI     = '"+ SA1->A1_COD +"' "
            _cFiltro += " AND C6.C6_LOJA     = '"+ SA1->A1_LOJA +"' "
            _cFiltro += " AND C6.C6_FILIAL     = '"+ xFilial("SC6") +"' "
            _cFiltro += " AND C6.C6_NUM     <> '"+ M->C5_NUM +"' "
            _cFiltro += " AND C6.C6_BLQ     <> 'R' "
            _cFiltro += " AND (SELECT ZAY_TPOPER FROM " + retsqlname("ZAY") + " ZAY WHERE ZAY.ZAY_FILIAL = '" + xFilial("ZAY") + "'"
            _cFiltro += " AND ZAY.ZAY_CF = C6.C6_CF AND ZAY.D_E_L_E_T_ = ' ')    = 'V' "
            _cFiltro += " %"

            cAliasSC6 := GetNextAlias()

            BeginSql Alias cAliasSC6
               SELECT	SUM(((C6_QTDVEN-C6_QTDENT)*C6_PRCVEN)-C6_VALDESC) SOMA
               FROM	%Table:SC6% C6
               WHERE	%exp:_cFiltro%
            EndSql

            _npedabr := (cAliasSC6)->SOMA

            (cAliasSC6)->( DBCloseArea() )
        Else
                U_MT_ITMSG('Pedido '+M->C5_NUM	+ " Limite de crédito do funcionário/produtor vencido, será considerado limite de crédito zerado.",;
                "Validação pedido Funcionário/Produtor",;
            "Favor solicitar apoio ao Departamento Financeiro/Comercial.")
        EndIf
    Else
        U_MT_ITMSG('Pedido '+M->C5_NUM	 + " Funcionário/Produtor com risco de crédito " + AllTrim(SA1->A1_RISCO) + ", será considerado limite de crédito zerado.",;
        "Validação pedido Funcionário/Produtor",;
        "Favor solicitar apoio ao Departamento Financeiro/Comercial.")
    EndIf
EndIf

//verifica se total do pedido e outros pedidos em aberto estão dentro do limite de crédito
If .not. _lRet
    For _x := 1 To Len(aCols)

        //================================================================================
        // Se a linha nao estiver deletada verifica se é cfop de venda e soma ao total
        //================================================================================
        If !aCols[_x][Len(aCols[_x])]
            If Posicione("ZAY",1,xFilial("ZAY")+AllTrim(aCols[_x][_cCFOP]),"ZAY_TPOPER") == "V"
                _nSomator += aCols[_x][_nValor]
            EndIf
        EndIf
    Next _x

    If  (_nSomator + _npedabr) <= _nlimcre
        _lRet := .T.
    Else
        U_MT_ITMSG("Pedido ultrapassa limite de crédito disponível." + chr(13) + chr(10) +;
        "Limite de crédito....." + PadL(AllTrim(transform(_nlimcre,"@E 999,999,999.99")),13,".") + chr(13) + chr(10) +;
        "Pedidos em aberto" + PadL(AllTrim(transform(_npedabr,"@E 999,999,999.99")),13,".") + chr(13) + chr(10) +;
        "----------------------------------------------------------------" + chr(13) + chr(10) +;
        "Limite disponível..." + PadL(AllTrim(transform(_nlimcre - _npedabr,"@E 999,999,999.99")),13,".") + chr(13) + chr(10) +;
        "Total do pedido......." + PadL(AllTrim(transform(_nSomator,"@E 999,999,999.99")),13,"."),;
        "Validação pedido Funcionário/Produtor",;
        "Favor solicitar apoio ao Departamento Comercial/Crédito.",1)
    EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: vldFilArm
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/09/2015
Descrição---------: Identifica se usuário tem restrição para a Filial x Armazém
Parametros--------: aCols - Dados dos ítens do pedido de venda
Retorno-----------: Lógico - Define se o registro deverá ser bloqueado
===============================================================================================================================
*/
Static Function vldFilArm( aCols )

Local _lRet		    := .T.
Local _cCodArmaz	:=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "C6_LOCAL"	} )
Local _cCodProd	    :=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "C6_PRODUTO"	} )
Local _nI			:= 1
Local _cmens		:= ""
Local _ccodusr      := AllTrim(RetCodUsr())
Local _cOperXLocal  := ""
Local _lRet2 := .T. , _cListaArmaz := ""

_cOperXLocal  := SuperGetMV('IT_OPERXLO',.T.,'10;24;')
_cFilXArmazem := SuperGetMV('IT_FILXARM',.T.,'9036;')

For _nI := 1 To Len(acols)

        If !aCols[_nI	][Len(aHeader)+1] //Não verifica linhas deletadas

            //============================================
            //Valida armazémxprodutoxFilialxusuário
            //============================================
            _aRet:= U_ACFG004E(_ccodusr, AllTrim(xFilial("SD1")), AllTrim(acols[_nI][_cCodArmaz]),AllTrim(acols[_nI][_cCodProd]),.F.)

            //se ainda está valido verifica se não teve erro
            If _lRet

              _lRet:= _aRet[1]

            EndIf

            // adiciona armazens com problema se ainda não estiver na mensagem
            If Empty(_cmens)

                _cmens += _aRet[2]

            ElseIf !(_aRet[2]$_cmens) .And. !(Empty(_aRet[2]))

                _cmens += ", " + _aRet[2]

            EndIf

            //====================================================
            // Validação por Tipo de Operação X Filial X Armazém
            //====================================================
            If M->C5_I_OPER $  _cOperXLocal .And. cFilAnt+AllTrim(acols[_nI][_cCodArmaz]) $ _cFilXArmazem
               _lRet2 := .F.
               _cListaArmaz += AllTrim(acols[_nI][_cCodArmaz]) + "; "
            EndIf

        EndIf

Next

//============================================
//Mostra lista de armazéns com problema
//============================================
If !(_lRet)
        U_MT_ITMSG( 'Pedido '+M->C5_NUM + " Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: " + CRLF + _cmens,;
                    "Validação usuário",;
                    'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.',1 )
EndIf

//======================================================================
// Mostra mensagem da Validação por Tipo de Operação X Filial X Armazém
//======================================================================
If ! _lRet2
   U_MT_ITMSG( " Filial: " + cFilAnt + ', Pedido Nr.: '+M->C5_NUM + ", Operação: " + M->C5_I_OPER +", Armazém: "+ _cListaArmaz + CRLF +;
               " Não é permitido utilizar esta operação para este armazém.",;
               " Validação Operação X Filial X Armazém:",'',1 )
   _lRet := .F.

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: vldlibbon
Autor-----------: Josué Danich Prestes
Data da Criacao-: 12/04/2016
Descrição-------: Valida liberação de bonificação do pedido
Parametros------: acols - linhas do pedido
Retorno---------: _lRet - se continua liberado ou não
===============================================================================================================================
*/
Static Function vldlibbon( acols )

Local _lRet 		:= .T.
Local _ntotprc 	:= 0
Local _ntotqtd 	:= 0
Local _nPosPreco	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRCVEN"  } )
Local _nPosqtd  	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_QTDVEN"  } )

//Verifica Status
If M->C5_I_BLOQ = "B"
   U_MT_ITMSG(	"Pedido " + M->C5_NUM + " de bonificação bloqueado "	,;
               "Validação Bonificação",;
                           "O pedido deverá ser liberado antes de ficar disponível para faturamento.",1 )

   Return .F.
EndIf

If M->C5_I_BLOQ == "R"
   U_MT_ITMSG(	"Pedido " + M->C5_NUM + " de bonificação REJEITADO ",;
                  "Validação Bonificação",;
                           "O pedido não poderá ser enviado para faturamento.",1 )

   Return .F.
EndIf

If M->C5_I_BLOQ == "L"
   //verifica alteração de cliente e loja
   If !(SC5->C5_I_CLILB == M->C5_CLIENTE .And. SC5->C5_I_LLIBB == M->C5_LOJACLI)
      U_MT_ITMSG(	"Pedido " + M->C5_NUM + " O cliente do pedido foi alterado desde a liberação de bonificação - "	,;
                     "Validação Bonificação",;
                           "O pedido deverá ser liberado novamente antes de ficar disponível para faturamento.",1)
      Return .F.
   EndIf

   //roda acols para verificar preço e quantidade
   _nI := 1
   DBSelectArea("SC6")
   SC6->( DBSetOrder(1) )
   SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

   While _nI <= Len(acols)

      _ntotprc += acols[_nI][_nPosPreco]
      _ntotqtd += acols[_nI][_nPosqtd]

      If !(acols[_nI][_nPosPreco] == SC6->C6_PRCVEN .And. acols[_nI][_nPosqtd] == SC6->C6_QTDVEN)

         U_MT_ITMSG(	"Pedido " + M->C5_NUM + " Preços e/ou quantidades foram alterados desde a liberação de bonificação ",;
                           "Validação Bonificação",;
                           "O pedido deverá ser liberado novamente antes de ficar disponível para faturamento.",1 )

         Return .F.

      EndIf

      _nI++

      SC6->( DBSkip() )
   EndDo

    //verifica totais
   If !(_ntotprc == SC5->C5_I_VLIBB .And. _ntotqtd == SC5->C5_I_QLIBB)
      U_MT_ITMSG(	"Pedido " + M->C5_NUM + " Preços e/ou quantidades foram alterados desde a liberação de bonificação - "	+;
                  "Validação Bonificação",;
                  "O pedido deverá ser liberado novamente antes de ficar disponível para faturamento.",1 )
      Return .F.
   EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: MTPV_VIN()
Autor-----------: Alex Wallauer
Data da Criacao-: 18/01/2018
Descrição-------: Tratamento para Pedido VINCULADO
Parametros--------: _lAchou: Achou no SC5 / _lLimpa: Limpa o campo C5_I_PEVIN
Retorno-----------: True ou False de acordo com A TRAVA SC5
===============================================================================================================================
*/
Static Function MTPV_VIN(_lAchou,_lLimpa)

Local _lTravou:=.F.,M,_cUser,_cMen,_cSol
Local _laoms074 := .F.

//Se veio do webservice já retorna .T.
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
    _laoms074 := .T.
EndIf

If _lAchou

   If !SC5->(MSRLOCK(SC5->(RECNO())))
      For M := 1 To 5
         If SC5->(MsRLock(SC5->(RECNO())))
               _lTravou:=.T.
               Exit
         EndIf
      Next
      If !_lTravou
         _cUser:= TCInternal(53)
         _cMen := "O Pedido vinculado "+M->C5_I_PEVIN+" esta sendo atualizado por outro Usuario ["+_cUser+"]"
         _cSol := "Aguarde por alguns instantes a liberação do Pedido e tente novamente."
         U_MT_ITMSG( _cMen , 'Atencao!',_cSol,1)

         lRet:=.F.
         Return .F.

      EndIf
   EndIf

   If (Empty(M->C5_I_PEVIN) .Or. _lLimpa) .And. !_laoms074
      If !Empty(SC5->C5_I_PEVIN)//Só faço atualização se necessario
         SC5->(RecLock("SC5",.F.))
         SC5->C5_I_PEVIN := ""

         U_RETPVRDC() // Grava tabelas de muro para envio ao sistema RDC.
      EndIf
   Else
      If SC5->C5_I_PEVIN <> M->C5_NUM .And. !_laoms074//Só faço atualização se necessario
         SC5->(RecLock("SC5",.F.))
         SC5->C5_I_PEVIN := M->C5_NUM

         U_RETPVRDC() // Grava tabelas de muro para envio ao sistema RDC.
      EndIf
   EndIf
   SC5->(MSUnLock())//destrava o MSRLOCK

ElseIf !Empty(M->C5_I_PEVIN) .And. !_laoms074//Se não achar o gravado SC5->C5_I_PEVIN não preisa validar pq já que não existe não preciso atualizar
   //Essa validação é caso o pedido seja deletado entre a validação e gravação
   U_MT_ITMSG("O Pedido vinculado "+M->C5_I_PEVIN+" não existe.","PEDIDO VINCUALADO","Vincule um Pedido cadastrado",1)
   lRet:=.F.
   Return .F.
EndIf

Return .T.

/*
=================================================================================================================================
Programa--------: MT410TOKC
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/08/2018
Descrição-------: Rotina de solicitação de retorno do Pedido integrado para o Sistema RDC/TMS multi-Embarcador(Cancela Pedido).
Parametros------: _lEstornoRDc = Variável passada por referencia que receberá o resultado da solicitação de retorno do pedido de
                                 vendas do sistema RDC. Esta variável indica se houve ou não integração com o sistema RDC.
Retorno---------: Nenhum
=================================================================================================================================
*/
Static Function MT410TOKC(_lEstornoRDc)

Local _lRet := .T.
Local _cTextoMsg

Begin Sequence

   _lEstornoRDc := .F.

   If SC5->C5_I_ENVRD <> "S"
      Break
   EndIf

   //================================================================================
   // Realiza a integração do cancelamento do pedido de vendas selecionados e
   // atualiza tabelas de muro.
   //================================================================================
   If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
      FWMsgRun(,{|oproc| _lRet := U_AOMS094E(oproc,.F.)},'Aguarde processamento...','Integrando dados cancelamento Pedidos de Vendas...')
   Else
      FWMsgRun(,{|oproc| _lRet := U_AOMS140E(oproc,.T.)},'Aguarde processamento...','Integrando dados cancelamento Pedidos de Vendas...')
   EndIf
   If !_lRet
      If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
         _cTextoMsg := "Não foi possível realizar o cancelamento de Pedidos de Vendas no Sistema RDC."
      Else
         _cTextoMsg := "Não foi possível realizar o cancelamento de Pedidos de Vendas no Sistema TMS Multi-Embarcador."
      EndIf
      U_MT_ITMSG(_cTextoMsg,"Atenção",,1)
   EndIf
   _lEstornoRDc := _lRet

End Sequence

Return _lRet

/*
=================================================================================================================================
Programa--------: RETPVRDC()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/08/2018
Descrição-------: Rotina de devolução de retorno do Pedido integrado para o Sistema RDC.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function RETPVRDC()

Begin Sequence
   If SC5->C5_I_ENVRD = "S"
      Break
   EndIf

   //================================================================================
   // Realiza a devolução do pedido de vendas selecionados e
   // atualiza tabelas de muro.
   //================================================================================
   RecLock("SC5",.F.)
   SC5->C5_I_ENVRD := "N"
   SC5->C5_I_DTRET := SToD("") // Data de retorno do pedido de vendas do RDC para o Protheus
   SC5->C5_I_HRRET := ""       // Hora de retorno do pedidod e vendas do RDC para o Protheus
   SC5->(MSUnLock())

   FWMsgRun(,{|oproc| U_AOMS084P(,oproc)},'Aguarde processamento...','Integrando dados devolução Pedidos de Vendas...' )

End Sequence

Return

/*
===============================================================================================================================
Programa----------: M410LITotais
Autor-------------: Alex Wallauer
Data da Criacao---: 27/09/2017
Descrição---------: Calcula os Totais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function M410LITotais()

Local nVolume   	:= 0
Local cEspecie  	:= ""
Local _nPesoBrut	:= 0
Local nQtdItem  	:= 0  , nx
Local nPesBruTotItem:= 0
Local nPosProduto	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
Local nPosQtd1 	    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN" })
Local nPosQtd2 	    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_UNSVEN" })
Local nPosUM1 	    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_UM"     })
Local nPosUM2 	    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_SEGUM"  })
Local nPosPBTI	    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_PTBRU"})
Local _lPesVaria    := .F.
Local _cCodTPONFRAC := SuperGetMV("IT_VOLN3M",.T.,"00060034701")// QUEIJO RALADO 40 G

SB1->(DBSetOrder(1))

For nx:=1 To Len(aCols)

   If !aTail(aCols[nx])  // Se Linha Nao Deletada

      SB1->(DBSeek(xFilial("SB1")+aCols[nx,nPosProduto]))

      //CALCULA O PESO BRUTO TOTAL DO PEDIDO DE VENDA

      If ! FWIsInCallStack("U_ALTERAP") .And. !FWIsInCallStack("U_AOMS085B")
         If SB1->B1_I_PCCX > 0 .And. aCols[nx][nPosPBTI] <> 0 .And. ! (FWIsInCallStack("U_AOMS098") .Or. FWIsInCallStack("U_AOMS099") .Or. FWIsInCallStack("U_AOMS032") ) // Peso Variável
            nPesBruTotItem := aCols[nx][nPosPBTI]
            _lPesVaria := .T.
         Else
            nPesBruTotItem:=(SB1->B1_PESBRU * aCols[nx,nPosQtd1])
            If nPosPBTI <> 0
               aCols[nx][nPosPBTI]:=nPesBruTotItem
            EndIf
         EndIf
      Else
         If nPosPBTI <> 0 .And. aCols[nx][nPosPBTI] == 0
            nPesBruTotItem :=(SB1->B1_PESBRU * aCols[nx,nPosQtd1])
            aCols[nx][nPosPBTI] := nPesBruTotItem

         ElseIf SB1->B1_I_PCCX > 0 // Peso Variável
            nPesBruTotItem := aCols[nx][nPosPBTI]
            _lPesVaria := .T.
         Else
            nPesBruTotItem :=(SB1->B1_PESBRU * aCols[nx,nPosQtd1])
            If nPosPBTI <> 0
               aCols[nx][nPosPBTI]:=nPesBruTotItem
            EndIf
         EndIf
      EndIf
      _nPesoBrut += nPesBruTotItem

      nQtdItem++

      If SB1->B1_I_QT3UM > 0 .And. !AllTrim(aCols[nx,nPosProduto]) $  _cCodTPONFRAC

         If AllTrim(SB1->B1_TIPO) == 'PA'
               If AllTrim(SB1->B1_SEGUM) == 'PC'
                  If aCols[nx,nPosQtd2]/SB1->B1_I_QT3UM >= 1
                     nVolume+=aCols[nx,nPosQtd2]/SB1->B1_I_QT3UM
                  Else
                     nVolume++
                  EndIf
               ElseIf AllTrim(SB1->B1_SEGUM) == 'CX' .And. SB1->B1_I_QT3UM = 1
                  nVolume+=aCols[nx,nPosQtd2]/SB1->B1_I_QT3UM
               Else
                  If aCols[nx,nPosQtd1]/SB1->B1_I_QT3UM >= 1
                     nVolume+=aCols[nx,nPosQtd1]/SB1->B1_I_QT3UM
                  Else
                     nVolume++
                  EndIf
               EndIf
         EndIf
         If nQtdItem == 1
            cEspecie := SB1->B1_I_3UM
         EndIf
         If cEspecie <> SB1->B1_I_3UM
            cEspecie := "DIVERSOS"
         EndIf

      ElseIf aCols[nx,nPosQtd2] > 0
         If aCols[nx,nPosQtd2] >= 1
            nVolume+=aCols[nx,nPosQtd2]
         Else
            nVolume++
         EndIf

         If nQtdItem == 1
            cEspecie := aCols[nx,nPosUM2]
         EndIf
         If cEspecie <> aCols[nx,nPosUM2]
            cEspecie := "DIVERSOS"
         EndIf

      Else
         If aCols[nx,nPosQtd1] >= 1
            nVolume+=aCols[nx,nPosQtd1]
         Else
            nVolume++
         EndIf

         If nQtdItem == 1
            cEspecie := aCols[nx,nPosUM1]
         EndIf
         If cEspecie <> aCols[nx,nPosUM1]
            cEspecie := "DIVERSOS"
         EndIf
      EndIf
   EndIf
Next nx

//Armazena o peso bruto total do Pedido de Venda
M->C5_I_PESBR:= _nPesoBrut

If FWIsInCallStack("U_AOMS098") .Or. FWIsInCallStack("U_AOMS099") .Or. FWIsInCallStack("U_AOMS032")
   M->C5_PBRUTO  := 0          // Zerar peso bruto padrão quando a rotina For chamada do Desmembramentos de pedidos.
ElseIf _lPesVaria .And. Type("ALTERA") <> "U" .And. ALTERA
   M->C5_PBRUTO  := _nPesoBrut // Gravar novo peso bruto quando o peso For variável e For uma alteração.
ElseIf ! _lPesVaria .And. Type("ALTERA") <> "U" .And. ALTERA
   M->C5_PBRUTO  := 0
EndIf
If M->C5_TIPO <> 'B' .Or. Empty(M->C5_VOLUME1)
   M->C5_VOLUME1 := nVolume
EndIf

If M->C5_TIPO <> 'B' .Or. Empty(M->C5_ESPECI1)
   M->C5_ESPECI1 := cEspecie
EndIf

Return _nPesoBrut

/*
===============================================================================================================================
Programa----------: M410Proc
Autor-------------: Alex Wallauer
Data da Criacao---: 27/09/2017
Descrição---------: Calcula os Totais
Parametros--------: oProc,_cMensagem
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function M410Proc(oProc,_cMensagem)

If oProc <> NIL
   oProc:cCaption := "Validando "+_cMensagem+"..."
   ProcessMessages()
EndIf

Return

/*
===============================================================================================================================
Programa----------: CPBT_SC5()
Autor-------------: Alex Wallauer
Data da Criacao---: 26/10/2018
Descrição---------: Carga Peso Bruto Total _ SC5
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CPBT_SC5()

Local _cPerg:="FILTRA_PV"

If !Pergunte(_cPerg , .T. )
   Return .F.
EndIf

Private _nGravados:=0
cTimeInicial:=Time()

FWMsgRun( ,{|oProc|  CPBT_SC5(oProc,cTimeInicial) }  , "SC6 - Inicio: "+LEFT(cTimeInicial,5)+" ["+AllTrim(MV_PAR01)+"] ["+DToC(MV_PAR02)+"] ["+DToC(MV_PAR03)+"] ["+AllTrim(MV_PAR04)+"]" )

Return .T.

/*
===============================================================================================================================
Programa----------: CPBT_SC5()
Autor-------------: Alex Wallauer
Data da Criacao---: 26/10/2018
Descrição---------: Carga Peso Bruto Total _ SC5
Parametros--------: oProc,cTimeInicial
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CPBT_SC5(oProc,cTimeInicial)

Local nConta :=0
Local xTotal :=0
Local nTam   :=0
Local _cAlias:= GetNextAlias()
Local cQuery := " SELECT SC5.R_E_C_N_O_ RECSF FROM "+ RetSqlName("SC5")+" SC5 WHERE "

oProc:cCaption :=  "Filtrando SC5, Aguarde..."
ProcessMessages()

cQuery += " SC5.D_E_L_E_T_	= ' ' "
If !Empty(MV_PAR01)
   cQuery += " AND	SC5.C5_FILIAL IN "+ FormatIn(AllTrim(MV_PAR01),";")
EndIf
If !Empty(MV_PAR03)
   cQuery += " AND SC5.C5_EMISSAO BETWEEN '"+ DToS(MV_PAR02) +"' AND '"+ DToS(MV_PAR03) +"' "
ElseIf !Empty(MV_PAR02)
   cQuery += " AND SC5.C5_EMISSAO = '"+ DToS(MV_PAR02)+"' "
EndIf
If !Empty(MV_PAR04)
   cQuery += " AND	SC5.C5_TIPO IN "+ FormatIn(MV_PAR04,";")
EndIf

If Select(_cAlias) > 0
   (_cAlias)->( DBCloseArea() )
EndIf

MPSysOpenQuery(cQuery,_cAlias)
DBSelectArea(_cAlias)

(_cAlias)->( DBGoTop() )
COUNT To  xTotal

If xTotal > 30000
xTotal:=AllTrim(Str(xTotal))

   If !U_ITMsg("Serão processado "+xTotal+" registros, CONFIRMA?","Atenção",,3,2,2)
      Return .F.
   EndIf

   cTimeInicial:=Time()
Else
   xTotal:=AllTrim(Str(xTotal))
EndIf

(_cAlias)->( DBGoTop() )
nTam:=Len(xTotal)+1

While (_cAlias)->(!Eof())

   nConta++

   SC5->(DBGoTo( (_cAlias)->RECSF ) )

   oProc:cCaption :=  "Lendo "+Str(nConta,nTam)+" de "+xTotal +" Lendo PV: "+SC5->C5_FILIAL+" "+SC5->C5_NUM+" PB Gravados: "+AllTrim(Str(_nGravados))
   ProcessMessages()

   GravaPeso(@_nGravados)

   (_cAlias)->( DBSkip() )

EndDo

_nGravados:=AllTrim(Str(_nGravados))

U_ITMsg("Carga (SC6) do Peso Bruto completada com sucesso "+_nGravados+" registros gravados.","Atenção","Hora inicio "+cTimeInicial+" - Hora fim "+TIME()+" Parametros: ["+AllTrim(MV_PAR01)+"] ["+DToC(MV_PAR02)+"] ["+DToC(MV_PAR03)+"] ["+AllTrim(MV_PAR04)+"]",2)

Return .T.
/*
===============================================================================================================================
Programa----------: GravaPeso
Autor-------------: Alex Wallauer
Data da Criacao---: 15/10/2018
Descrição---------: Processa a gravação dos pesos do itens da NF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GravaPeso(_nGravados)

Local _cFilSB1 := xFilial("SB1")

If SC6->(FIELDPOS("C6_I_PTBRU")) = 0
   Return .F.
EndIf

Default _nGravados:=0

SC6->( DBSetOrder(1) )
If 	SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
   While SC6->(!Eof()) .And. SC6->C6_FILIAL+SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM
      If Empty(SC6->C6_I_PTBRU) .And. !Empty(SC6->C6_QTDVEN)
         _nPesoItem := ( Posicione( "SB1" , 1 , _cFilSB1 + SC6->C6_PRODUTO , "B1_PESBRU" ) * SC6->C6_QTDVEN )
         If _nPesoItem <> 0 .And. SC6->( RecLock( "SC6",.F.,,.T.))
               SC6->C6_I_PTBRU := _nPesoItem
               SC6->( MSUnLock() )
               _nGravados++
         EndIf

      EndIf
      SC6->( DBSkip() )
   EndDo
EndIf

Return .T.

/*=============================================================================================================================
Programa----------: MT410_CT()
Autor-------------: Josué Danich
Data da Criacao---: 21/09/2018
Descrição---------: Validação e entrada de motivo de corte
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: ExpL01 - Se .T. continua a operacao, se .F. nao volta pra tela de pedido sem fazer nada.
===============================================================================================================================*/
Static Function MT410_CT()

Local _lRet := .T.
Local _aitens := {}
Local _nnk := 1
Local _ltemct := .F.
Local nLinha        := 10
Local _nCol			:= 15
Local nPosProduto		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"	} )
Local nPosQtde			:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_QTDVEN"  } )
Local _omotiv

Public _cmotivs    := "  "

SC6->(DBSetOrder(1))

If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   While SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM

      //Só grava e questiona corte de produto PA em pedido de vendas
      If AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPO")) == "PA" .And. Posicione("ZAY",1,xFilial("ZAY")+SC6->C6_CF,"ZAY_TPOPER") == "V"
         aAdd(_aitens,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_QTDVEN})
      EndIf
      SC6->(DBSkip())
   EndDo

   For _nnk := 1 To Len(_aitens)
      _npos := aScan(acols,{|apos| AllTrim(apos[nPosProduto]) == AllTrim(_aitens[_nnk][2])})

      //Se não achou o produto no acols é porque foi alterado
      //Se a linha está deletada é corte pois nção aceita linha com produto repetido mesmo deletada
      If _npos == 0 .Or. aCols[_npos][Len(aCols[_npos])]
         _ltemct := .T.
         _lRet := .F.
         Exit

      //Se não está deletada mas a quantidade diminui
      ElseIf acols[_npos][nPosQtde] < _aitens[_nnk][3]
         _ltemct := .T.
         _lRet := .F.
         Exit
      EndIf
   Next

   If _ltemct
      _cQuery := " SELECT "
      _cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
      _cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
      _cQuery += " WHERE "
      _cQuery += "     D_E_L_E_T_ = ' ' "
      _cQuery += " AND X5_TABELA  = 'Z1' AND TRIM(X5_CHAVE) <> '98' AND TRIM(X5_CHAVE) <> '99' "
      _cQuery += " ORDER BY X5_CHAVE "

      If Select("TMPCF") > 0
         ("TMPCF")->( DBCloseArea() )
      EndIf

      MPSysOpenQuery(_cQuery,'TMPCF')
      DBSelectArea('TMPCF')

      _amotivs := {}

      While TMPCF->( !Eof() )
         aAdd( _amotivs , AllTrim( TMPCF->CHAVE ) + " - " + AllTrim( TMPCF->DESCRI ) )
         TMPCF->( DBSkip() )
      EndDo

      ("TMPCF")->( DBCloseArea() )

      _cmotivs := _amotivs[1]

      DEFINE MSDIALOG _oDlg2 TITLE ("Corte por alteração de PV") From 0,0 To 325, 650 PIXEL

      @ nLinha,_nCol Say OemToAnsi("Selecione o motivo para corte:")
      nLinha+=12

      _omotiv := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_cmotivs:=u,_cmotivs)}, _amotivs,250,20,_oDlg2,,,,,,.T.,,,,,,,,,'') //40

      nLinha+=38

      @ nLinha,_nCol    Button "OK" SIZE 41,15 ACTION ( _lRet := .T. ,_oDlg2:End()) Pixel
         @ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( _oDlg2:End() ) Pixel

      ACTIVATE MSDIALOG _oDlg2


      If !_lRet

         U_MT_ITMSG("Não foi selecionado motivo de corte, alteração não será efetuada","Atenção",,1)

      EndIf

   EndIf

EndIf

Return _lRet

/*=============================================================================================================================
Programa----------: MT410_JA()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/10/2023
Descrição---------: Ao alterar os campos c5_i_agend ou c5_i_dtent, obrigar preenchimento do campo justificativa (zy3_juscod)
                    especifica para esses campos e observação (zy3_observ) da justificativa com texto minimo de 10 caracteres
Parametros--------: Nenhum
Retorno-----------: Se .T. continua a as outras validações, se .F. nao volta pra tela de pedido sem fazer nada.
===============================================================================================================================
*/
Static Function MT410_JA

Local _lRet    := .F.
Local nLinha   := 10
Local _nCol1   := 05
Local _nCol2   := 40
Local _nCol3   := 90
Local _nTam    := 300

_cJustAG := Space(3)  // _aJustAG[1]
_cJustDE := Space(3)  // _aJustDE[1]
_cObseAG := Space(Len(ZY3->ZY3_OBSERV))
_cObseDE := Space(Len(ZY3->ZY3_OBSERV))

_cTitJus:="Justificativas das alterações "
_aFoders:={}
If _lAltAgen
   aAdd(_aFoders,"Tipo de Agendamento")
   _cTitJus+="de Data de Entrega"
EndIf
If _lAltData
   aAdd(_aFoders,"Data de Entrega")
   If _lAltAgen
      _cTitJus+=" e "
   EndIf
   _cTitJus+="do Tipo de Agendamento"
EndIf

While .T.

   DEFINE MSDIALOG _oDlg2 TITLE _cTitJus From 0,0 To 280, 700 PIXEL

    _nColFolder:=350
    _nLinFolder:=100
    nLinha:=1

    oTFolder1:= TFolder():New( nLinha,1,_aFoders,,_oDlg2,,,,.T., , _nColFolder,_nLinFolder )

    If _lAltAgen
        nLinha:=5
        @ nLinha,_nCol1 Say "Tipo de Agendamento de: "+U_TipoEntrega(SC5->C5_I_AGEND) OF oTFolder1:aDialogs[1] PIXEL

        nLinha+=15
        @ nLinha,_nCol1 Say "Tipo de Agendamento para: "+U_TipoEntrega(M->C5_I_AGEND) OF oTFolder1:aDialogs[1] PIXEL

        nLinha+=15
        @ nLinha+4,_nCol1 Say "Justificativas:"       OF oTFolder1:aDialogs[1] PIXEL
        @ nLinha,_nCol2 MSGET _cJustAG F3 "ZY5"   SIZE 30,010  Valid(MT410VLJUS(_cJustAG , "C5_I_AGEND")) PIXEL OF oTFolder1:aDialogs[1] WHEN _lAltAgen //MULTILINE
                
        nLinha+=20
        @ nLinha+2,_nCol1 Say  "Observação:" SIZE 060  ,007  PIXEL OF oTFolder1:aDialogs[1]
        @ nLinha,_nCol2 MSGet _cObseAG       SIZE _nTam,010  PIXEL OF oTFolder1:aDialogs[1] WHEN .F. 
    EndIf

///***********************  FOLDER 2 *************************************************
    If _lAltData
        nLinha:=5
        @ nLinha,_nCol1 Say "Data de Entrega de: "+DToC(SC5->C5_I_DTENT) OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL

          nLinha+=15
        @ nLinha,_nCol1 Say "Data de Entrega para: "+DToC(M->C5_I_DTENT) OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL

        nLinha+=15
        @ nLinha+4,_nCol1 Say "Justificativas:"           OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL
        @ nLinha,_nCol2 MSGet _cJustDE  F3 "ZY5"  Valid(MT410VLJUS(_cJustDE , "C5_I_DTENT")) SIZE 030,010 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)] WHEN _lAltData //MULTILINE

        nLinha+=20
        @ nLinha+2,_nCol1 Say  "Observação:" SIZE 060  ,007 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)]
        @ nLinha,_nCol2 Get _cObseDE       SIZE _nTam,010 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)] WHEN .F.
    EndIf
    nLinha+=60
    @ nLinha,_nCol3    Button "CONTINUAR" SIZE 50,15 ACTION ( _lRet := .T. ,_oDlg2:End()) PIXEL
       @ nLinha,_nCol3+99 Button "VOLTAR"    SIZE 50,15 ACTION ( _lRet := .F. ,_oDlg2:End()) PIXEL

   ACTIVATE MSDIALOG _oDlg2

   If ! _lRet
      U_MT_ITMSG("Não foi selecionada/Digitada a Justificativa/Observação, alteração do Pedido não será efetuada.","Atenção",,1)
   Else
      If (_lAltData .And. Empty(_cJustDE)) 
         U_MT_ITMSG("O código de justificativa para alteração da data de entrega não foi informado.","Atenção",,1)
         _lRet := .F.
      EndIf 

      If (_lAltAgen .And. Empty(_cJustAG))
         U_MT_ITMSG("O código de justificativa para alteração do tipo de agendamento não foi informado.","Atenção",,1)
         _lRet := .F.
      EndIf

      If ParamIXB[1] = 4//ALTERACAO
         If (SC5->C5_I_AGEND ="P" .And. M->C5_I_AGEND = "A") .OR.;
            (SC5->C5_I_AGEND ="R" .And. M->C5_I_AGEND = "A") .OR.;
            (SC5->C5_I_AGEND ="P" .And. M->C5_I_AGEND = "M") .OR.;
            (SC5->C5_I_AGEND ="N" .And. M->C5_I_AGEND = "A")
          	_lContOk := .T.
         Else
         	_lContOk := .F.
         EndIf
      EndIf 	
   EndIf

   Exit
EndDo

Return _lRet

/*
====================================================================================================================================================================
Programa----------: MT410_UN()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/04/2019
Descrição---------: Validação para não permitir fracionamento para PAs (produtos acabados) onde a primeira unidade de medida For UN (represente 1 inteiro)
Parametros--------: oProc
Retorno-----------: .T. ou .F.
====================================================================================================================================================================*/
Static Function MT410_UN(oProc)

Local _lRet  := .T.
Local _cProds:="" , nX
Local nPosProduto:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"	} )

ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
      Return .T.
   EndIf
EndIf

For nX := 1 To Len(aCols)
   // Muda o valor de N
    N := nX
    M410Proc(oProc,"(1a) Quantidades fracionadas, Item "+aCols[nX][nPosIte])

    If aCols[n][Len(aCols[n])]
       Loop
    EndIf

    SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[n,nPosProduto])))
    If SB1->B1_TIPO == "PA" .And. SB1->B1_UM == "UN"

        If aCols[n,nPosQtd] <> noround((aCols[n,nPosQtd]),0)
            _lRet := .F.
            _cProds+="Item: " + aCols[n,nPosIte]+" Prod.: " + AllTrim(aCols[n,nPosProduto])+" - UM: "+SB1->B1_UM+ " - " + LEFT(SB1->B1_DESC,45) + CHR(13)+CHR(10)
        EndIf

    EndIf

Next

If !_lRet
   U_MT_ITMSG("Não é permitido fracionar a quantidade da 1a. UM de produto onde a UM For UN. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                 "Validação Fracionado","Favor informar apenas quantidades inteiras na Primeira Unidade de Medida."         ,1     ,       ,        ,         ,     ,     ,;
                 {|| U_ITMSGLOG(_cProds,"Validação Fracionado") },_cProds )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: M410SITITEM()
Autor-------------: Jerry
Data da Criacao---: 09/12/2019
Descrição---------: Retorna verdadeiro quando o Preço ou Qtd do Produto foi alterado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function M410SITITEM()

Local nX := 1
Local _lItemAlterado := .F.
Local _nPosProduto	:= 0
Local _nPosTes 		:= 0
Local _nPosUser 	:= 0
Local _nPosPreco	:= 0
Local _nPosqtd		:= 0
Local _cCFOP	    := 0
Local _nPosIte	    := 0
Local _nPosVal		:= 0
Local _cSimilar     := ""
Local _lCodAlterado := .F.
Local _cQueijo		:= "N"
Local _nQtdAlterado := 0
Local _ntolporc     := SuperGetMV("IT_TOLPC",.F.,10) //Percentual Tolerância para Produto PA do Tipo Queijo.

_nPosProduto	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRODUTO"	} )
_nPosTes 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_TES"		} )
_nPosUser 		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_I_USER"  } )
_nPosPreco		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_PRCVEN"  } )
_nPosqtd		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_QTDVEN"  } )
_cCFOP	        := aScan( aHeader , { |x| AllTrim(x[2]) == "C6_CF"	    } )
_nPosIte	   	:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_ITEM"    } )
_nPosVal		:= aScan( aHeader , { |x| AllTrim(x[2]) == "C6_VALOR"   } )

//================================================================================
// Processa todos os itens do Pedido
//================================================================================
While nX <= Len(aCols) 
    If !GdDeleted(nX)

        _lCodAlterado := .F.

         SC6->(DBSetOrder(1))
           If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM+aCols[nX][_nPosIte]))
            _cQueijo  := Posicione( "SB1" , 1 , xFilial("SB1") + SC6->C6_PRODUTO , "B1_I_QQUEI")
            If aCols[nX][_nPosProduto] != SC6->C6_PRODUTO
                _lCodAlterado := .T.
                _cSimilar := Posicione( "SB1" , 1 , xFilial("SB1") + SC6->C6_PRODUTO , "B1_I_PRDSM")
                If AllTrim(aCols[nX][_nPosProduto]) $ AllTrim(_cSimilar)
                    _lCodAlterado := .F.
                End
            EndIf
               If aCols[nX][_nPosPreco] != SC6->C6_PRCVEN .Or. aCols[nX][_nPosqtd] > SC6->C6_QTDVEN .Or. _lCodAlterado
                   _nQtdAlterado := _nQtdAlterado+1

                If _cQueijo = "S" .And. aCols[nX][_nPosqtd] <= (  SC6->C6_QTDVEN  + (( SC6->C6_QTDVEN  * _ntolporc) / 100 ) )
                    _nQtdAlterado := _nQtdAlterado-1
                End
             EndIf
        Else
            _lItemNovo:=.T.
            _nQtdAlterado := _nQtdAlterado+1
           EndIf
    EndIf

    nX++
EndDo

If _nQtdAlterado > 0
    _lItemAlterado := .T.
EndIf

Return  _lItemAlterado

/*
===============================================================================================================================
Programa----------: M410VLSDX
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/09/2021
Descrição---------: Valida a seleção de notas fiscais Sedex vinculadas ao pedido de Vendas.
Parametros--------: _cCampo = Campo que chamou a validação.
                            = Ou validação final do Pedido de Vendas.
Retorno-----------: _lRet = .T. = Validação Ok
                            .F. = Erro de validação
===============================================================================================================================
*/
User Function M410VLSDX(_cCampo)

Local _lRet := .T.

Begin Sequence
   SF1->(DBSetOrder(1)) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

   If _cCampo == "C5_I_NFREF"
      If Empty(M->C5_I_NFREF)
         U_MT_ITMSG("Este pedido está configurado como SEDEX. O preenchimento da nota fiscal de referência é obrigatório.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Preencha o numero da nota fiscal de referência SEDEX.",1)
         _lRet := .F.
         Break
      EndIf

      If ! SF1->(MsSeek(xFilial("SF1")+M->C5_I_NFREF))
         U_MT_ITMSG("A nota fiscal informada não existe para esta filial.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Informe um numero de nota fiscal que exista.",1)
         _lRet := .F.
      EndIf

   ElseIf _cCampo == "C5_I_SERNF"
      If Empty(M->C5_I_SERNF)
         U_MT_ITMSG("Este pedido está configurado como SEDEX. O preenchimento da série da nota fiscal de referência é obrigatório.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Preencha a série da nota fiscal de referência SEDEX.",1)
         _lRet := .F.
         Break
      EndIf

      If ! SF1->(MsSeek(xFilial("SF1")+M->C5_I_NFREF+M->C5_I_SERNF))
         U_MT_ITMSG("A nota fiscal e série informadas não existe para esta filial.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Informe um numero de nota fiscal e série que exista.",1)
         _lRet := .F.
         Break
      EndIf

   ElseIf _cCampo == "TUDOOK"
       If M->C5_I_NFSED <> "S"
          M->C5_I_NFREF := Space(9)
          M->C5_I_SERNF := Space(3)
          Break
       EndIf

       If Empty(M->C5_I_NFREF)
         U_MT_ITMSG("Este pedido está configurado como SEDEX. O preenchimento da nota fiscal de referência é obrigatório.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Preencha o numero da nota fiscal de referência SEDEX.",1)
         _lRet := .F.
         Break
      EndIf

      If Empty(M->C5_I_SERNF)
         U_MT_ITMSG("Este pedido está configurado como SEDEX. O preenchimento da série da nota fiscal de referência é obrigatório.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Preencha a série da nota fiscal de referência SEDEX.",1)
         _lRet := .F.
         Break
      EndIf

      If ! SF1->(MsSeek(xFilial("SF1")+M->C5_I_NFREF+M->C5_I_SERNF))
         U_MT_ITMSG("A nota fiscal e série informadas não existe para esta filial.",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Informe um numero de nota fiscal e série que exista.",1)
         _lRet := .F.
      EndIf

    ElseIf _cCampo == "C5_I_NFSED"
       If M->C5_I_NFSED <> "S"
          M->C5_I_NFREF := Space(9)
          M->C5_I_SERNF := Space(3)
          Break
       EndIf
   EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: M410BDES
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/06/2022
Descrição---------: Busca o desconto por tonelada no cadastro ZBL.
Parametros--------: _cFilOrige = Filial de Origem
                    _cUF       = Estado
                    _cOperVend = Operação de Venda
                    _cCodMunic = Codigo do municipio
Retorno-----------: _nRet = Desconto por tonelada cadastrado na tabel ZBL.
===============================================================================================================================
*/
User Function M410BDES(_cFilOrige , _cUF , _cOperVend , _cCodMunic)

Local _nRet := 0
Local _cMesoReg := Space(6)
Local _cMicroReg := Space(6)

Begin Sequence

   CC2->(DBSetOrder(1)) // CC2_FILIAL+CC2_EST+CC2_CODMUN
   If CC2->(MsSeek(xFilial("CC2")+_cUF+_cCodMunic))
      _cMesoReg  := CC2->CC2_I_MESO // Meso região
      _cMicroReg := CC2->CC2_I_MICR // Micro região
   EndIf

   ZBL->(DBSetOrder(4)) // ZBL_FILIAL+ZBL_FILORI+ZBL_UF+ZBL_OPER+ZBL_CODMUN+ZBL_MESO+ZBL_MICRO

   ZBL->(MsSeek(xFilial("ZBL") + _cFilOrige + _cUF)) //+ _cOperVend + _cCodMunic))

   While ! ZBL->(Eof()) .And. ZBL->(ZBL_FILIAL+ZBL_FILORI+ZBL_UF) == ;     // +ZBL_OPER+ZBL_CODMUN) == ;
                                 xFilial("ZBL") + _cFilOrige + _cUF           // + _cOperVend + _cCodMunic

      //If ! Empty(_cOperVend) .And. ! Empty(_cCodMunic) .And. ! Empty(_cMesoReg) .And. ! Empty(_cMicroReg)
      If ! Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And. ! Empty(ZBL->ZBL_MESO) .And. ! Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_OPER == _cOperVend .And. ZBL->ZBL_CODMUN == _cCodMunic .And. ZBL->ZBL_MESO == _cMesoReg .And. ZBL->ZBL_MICRO == _cMicroReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      //If ! Empty(_cOperVend) .And. ! Empty(_cCodMunic) .And. ! Empty(_cMesoReg) .And. Empty(_cMicroReg)
      If ! Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And. ! Empty(ZBL->ZBL_MESO) .And. Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_OPER == _cOperVend .And. ZBL->ZBL_CODMUN == _cCodMunic .And. ZBL->ZBL_MESO == _cMesoReg     //.And. ZBL->ZBL_MICRO == _cMicroReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      //If ! Empty(_cOperVend) .And. ! Empty(_cCodMunic) .And. Empty(_cMesoReg) .And. ! Empty(_cMicroReg)
      If ! Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And. Empty(ZBL->ZBL_MESO) .And. ! Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_OPER == _cOperVend .And. ZBL->ZBL_CODMUN == _cCodMunic .And. ZBL->ZBL_MICRO == _cMicroReg    // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      //If ! Empty(_cOperVend) .And. ! Empty(_cCodMunic) .And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
      If ! Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And. Empty(ZBL->ZBL_MESO) .And. Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_OPER == _cOperVend .And. ZBL->ZBL_CODMUN == _cCodMunic       // .And. ZBL->ZBL_MICRO == _cMicroReg // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      //If ! Empty(_cOperVend) .And. Empty(_cCodMunic)     //.And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
      If ! Empty(ZBL->ZBL_OPER) .And. Empty(ZBL->ZBL_CODMUN)     //.And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
         If ZBL->ZBL_OPER == _cOperVend                  // .And. ZBL->ZBL_CODMUN == _cCodMunic // .And. ZBL->ZBL_MICRO == _cMicroReg // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf
//-------------------------------------------------------------------------
      If Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And.  ! Empty(ZBL->ZBL_MESO) .And.  Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_CODMUN == _cCodMunic .And. ZBL->ZBL_MESO == _cMesoReg              // ZBL->ZBL_OPER == _cOperVend // .And. // .And. ZBL->ZBL_MICRO == _cMicroReg // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      If Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN) .And.  Empty(ZBL->ZBL_MESO) .And.  ! Empty(ZBL->ZBL_MICRO)
         If ZBL->ZBL_CODMUN == _cCodMunic .And. ZBL->ZBL_MICRO == _cMicroReg  // ZBL->ZBL_OPER == _cOperVend // .And. // .And. ZBL->ZBL_MICRO == _cMicroReg // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf
//-------------------------------------------------------------------------
      //If Empty(_cOperVend) .And. ! Empty(_cCodMunic)    //.And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
      If Empty(ZBL->ZBL_OPER) .And. ! Empty(ZBL->ZBL_CODMUN)    //.And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
         If ZBL->ZBL_CODMUN == _cCodMunic               // ZBL->ZBL_OPER == _cOperVend // .And. // .And. ZBL->ZBL_MICRO == _cMicroReg // .And. ZBL->ZBL_MESO == _cMesoReg
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      //If Empty(_cOperVend) .And. Empty(_cCodMunic) .And. Empty(_cMesoReg) .And. Empty(_cMicroReg)
      If Empty(ZBL->ZBL_OPER) .And. Empty(ZBL->ZBL_CODMUN) .And. Empty(ZBL->ZBL_MESO) .And. Empty(ZBL->ZBL_MICRO)
         If Empty(ZBL->ZBL_OPER) .And. Empty(ZBL->ZBL_CODMUN) .And. Empty(ZBL->ZBL_MICRO) .And. Empty(ZBL->ZBL_MESO)
            _nRet := ZBL->ZBL_DESCON
            Break
         EndIf
      EndIf

      ZBL->(DBSkip())
   EndDo

End Sequence

Return _nRet

/*
===============================================================================================================================
Programa--------: U_MT_ITMSG()
Autor-----------: Alex Wallauer
Data da Criacao-: 21/09/2017
Descrição-------: Tratamento para as mensagens não dar erro na integração do RDC e via MSEXECAUTO()
Parametros--------: _cMens         - Texto a ser apresentado na mensagem.
                    _ctitu         - Texto com título da mensagem.
                    _csolu         - Texto a ser apresentado como solução.
                    _ntipo         - número para escolher estilo e figura da mensagem.
                    _nbotao        - botão ok (1) ou botão ok e cancela (2).
                    _nmenbot       - Mensagem botões (1) Ok/Cancela (2) Sim/Não.
                    _lHelpMvc      - .T. chama função Help do MVC, .F. exibe tela customizada para a função ITMSG..
                    _cbt1,_cbt2    - Ajusta texto dos botões se tiver diferente do Default (texto personalizado).
                    _bMaisDetalhes - CodeBlock que será executado no botão "Mais Detalhes".
                    _cMaisDetalhes - Texto que será somando na mensagem de erro para MSEXECAUTO().
Retorno-----------: True ou False de acordo com botão ok/sim ou cancela/não escolhido
===============================================================================================================================
*/
User Function MT_ITMSG(_cMens,_cTitu,_cSolu,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes,_cMaisDetalhes)

Local _lRetorno:=.T.

Default _cMens:=""
Default _cTitu:=""
Default _cSolu:=""
Default _cMaisDetalhes:=""

If ValType(_cSolu) <> "C"
   _cSolu:=""
EndIf
If ValType(_cMaisDetalhes) <> "C"
   _cMaisDetalhes:=""
EndIf

If Type("_lMsgEmTela") <> "L" .Or. _lMsgEmTela
   _lRetorno:=U_ITMsg(_cMens,_cTitu,_cSolu,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes)
Else
   If Type("_cAOMS074Vld") = "C"
      If Type("_cAOMS074") <> "C"
         _cAOMS074 := ""
      EndIf

      If Empty(_cAOMS074Vld) .And. !Empty(M->C5_NUM)
         If !Empty(_cAOMS074)
            _cAOMS074Vld += '('+_cAOMS074+'/MT410TOK) PV: '+AllTrim(M->C5_NUM)+". "
         Else
            _cAOMS074Vld += '(MT410TOK) PV: '+AllTrim(M->C5_NUM)+". "
         EndIf
      EndIf
      _cMens:=StrTran(_cMens,"Clique em mais detalhes","")
      _cAOMS074Vld += _cTitu+": "+_cMens+". "
      If !Empty(_cSolu)
          _cAOMS074Vld += "Solucao: "+_cSolu+". "
      EndIf
      If !Empty(_cMaisDetalhes)
          _cAOMS074Vld += "Detalhes: "+_cMaisDetalhes+". "
      EndIf
   EndIf
EndIf

Return _lRetorno

/*
===============================================================================================================================
Programa----------: M410BDES
Autor-------------: Julio de Paula Paz
Data da Criacao---: 03/10/2024
Descrição---------: Realiza a exclusão do pedido de pallets vinculado ao pedido de vendas, para que seja gerado um novo
                    pedido de pallets com os dados atualizados.
Parametros--------: _cNrPdPale = Numero do pedido de pallets vinculado os pedido de vendas.
Retorno-----------: _lRet := .T. = Pedido de pallet excluido com sucesso.
                             .F. = Não foi possível excluir o pedido de pallet.
===============================================================================================================================
*/
Static Function MT410EXCPA(_cNrPdPale)

Local _lRet := .T.
Local _nRegSC5 := SC5->(Recno())
Local _nRegSC6 := SC6->(Recno())
Local _cFilOrigem, _cPedOrigem

Begin Sequence
   If Empty(_cNrPdPale)
      Break
   EndIf


   _aCabPV  :={}
   _aItemPV :={}
   _aItensPV:={}

   SC5->(DBSetOrder(1))
   If ! SC5->(MsSeek(xFilial("SC5")+_cNrPdPale))
      //_lRet := .F.
      Break
   EndIf

   aAdd( _aCabPV, { "C5_FILIAL"	    ,SC5->C5_FILIAL   , Nil}) //filial
   aAdd( _aCabPV, { "C5_NUM"        ,SC5->C5_NUM	  , Nil})
   aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO     , Nil}) //Tipo de pedido
   aAdd( _aCabPV, { "C5_I_OPER"	    ,SC5->C5_I_OPER   , Nil}) //Tipo da operacao
   aAdd( _aCabPV, { "C5_CLIENTE"    ,SC5->C5_CLIENTE  , NiL}) //Codigo do cliente
   aAdd( _aCabPV, { "C5_CLIENT"     ,SC5->C5_CLIENT	  , Nil})
   aAdd( _aCabPV, { "C5_LOJAENT"    ,SC5->C5_LOJAENT  , NiL}) //Loja para entrada
   aAdd( _aCabPV, { "C5_LOJACLI"    ,SC5->C5_LOJACLI  , NiL}) //Loja do cliente
   aAdd( _aCabPV, { "C5_EMISSAO"    ,SC5->C5_EMISSAO  , NiL}) //Data de emissao
   aAdd( _aCabPV, { "C5_TRANSP"     ,SC5->C5_TRANSP	  , Nil})
   aAdd( _aCabPV, { "C5_CONDPAG"    ,SC5->C5_CONDPAG  , NiL}) //Codigo da condicao de pagamanto*
   aAdd( _aCabPV, { "C5_VEND1"      ,SC5->C5_VEND1	  , Nil})
   aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA    , Nil}) //Moeda
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD	  , Nil})
   aAdd( _aCabPV, { "C5_LIBEROK"    ,SC5->C5_LIBEROK  , NiL}) //Liberacao Total
   aAdd( _aCabPV, { "C5_TIPLIB"     ,SC5->C5_TIPLIB   , Nil}) //Tipo de Liberacao
   aAdd( _aCabPV, { "C5_TIPOCLI"    ,SC5->C5_TIPOCLI  , NiL}) //Tipo do Cliente
   aAdd( _aCabPV, { "C5_I_NPALE"    ,SC5->C5_I_NPALE  , NiL}) //Numero que originou a pedido de palete
   aAdd( _aCabPV, { "C5_I_PEDPA"    ,SC5->C5_I_PEDPA  , NiL}) //Pedido Refere a um pedido de Pallet
   aAdd( _aCabPV, { "C5_I_DTENT"    ,SC5->C5_I_DTENT  , Nil}) //Dt de Entrega // SC5->C5_I_DTENT
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF  , Nil})
   aAdd( _aCabPV, { "C5_I_OBCOP" 	,SC5->C5_I_OBCOP  , Nil})
   aAdd( _aCabPV, { "C5_I_OBPED" 	,SC5->C5_I_OBPED  , Nil})
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC  , Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE  , Nil})
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT  , Nil})
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC  , Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE  , Nil})
   aAdd( _aCabPV, { "C5_I_TIPCA"    ,SC5->C5_I_TIPCA  , Nil})
   aAdd( _aCabPV, { "C5_MENNOTA"    ,SC5->C5_MENNOTA  , Nil})
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD   , Nil})
   aAdd( _aCabPV, { "C5_I_PODES"    ,SC5->C5_NUM      , Nil})
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC  , Nil})
   aAdd( _aCabPV, { "C5_I_DTLIB"    ,SC5->C5_I_DTLIB  , Nil})
   aAdd( _aCabPV, { "C5_I_IDPED"    ,SC5->C5_I_IDPED  , Nil})
   aAdd( _aCabPV, { "C5_ORIGEM "    ,SC5->C5_ORIGEM   , Nil})
   aAdd( _aCabPV, { "C5_I_DTAIM"    ,SC5->C5_I_DTAIM  , Nil})
   aAdd( _aCabPV, { "C5_I_HORAI"    ,SC5->C5_I_HORAI  , Nil})
   aAdd( _aCabPV, { "C5_I_DATAA"    ,SC5->C5_I_DATAA  , Nil})
   aAdd( _aCabPV, { "C5_I_HORAA"    ,SC5->C5_I_HORAA  , Nil})
   aAdd( _aCabPV, { "C5_I_DTLIP"    ,SC5->C5_I_DTLIP  , Nil})
   aAdd( _aCabPV, { "C5_I_MLIBP"    ,SC5->C5_I_MLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_DTAVA"    ,SC5->C5_I_DTAVA  , Nil})
   aAdd( _aCabPV, { "C5_I_HRAVA"    ,SC5->C5_I_HRAVA  , Nil})
   aAdd( _aCabPV, { "C5_I_USRAV"    ,SC5->C5_I_USRAV  , Nil})
   aAdd( _aCabPV, { "C5_I_LIBCA"    ,SC5->C5_I_LIBCA  , Nil})
   aAdd( _aCabPV, { "C5_I_LIBCT"    ,SC5->C5_I_LIBCT  , Nil})
   aAdd( _aCabPV, { "C5_I_LIBL "    ,SC5->C5_I_LIBL   , Nil})
   aAdd( _aCabPV, { "C5_I_LIBCV"    ,SC5->C5_I_LIBCV  , Nil})
   aAdd( _aCabPV, { "C5_I_LIBCD"    ,SC5->C5_I_LIBCD  , Nil})
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE  , Nil})
   aAdd( _aCabPV, { "C5_I_MOTBL"    ,SC5->C5_I_MOTBL  , Nil})
   aAdd( _aCabPV, { "C5_I_DTLIC"    ,SC5->C5_I_DTLIC  , Nil})
   aAdd( _aCabPV, { "C5_I_PLIBP"    ,SC5->C5_I_PLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_ULIBP"    ,SC5->C5_I_ULIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_VLIBP"    ,SC5->C5_I_VLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_MOTLP"    ,SC5->C5_I_MOTLP  , Nil})
   aAdd( _aCabPV, { "C5_I_MOTLB"    ,SC5->C5_I_MOTLB  , Nil})
   aAdd( _aCabPV, { "C5_I_QLIBP"    ,SC5->C5_I_QLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_VLIBB"    ,SC5->C5_I_VLIBB  , Nil})
   aAdd( _aCabPV, { "C5_I_QLIBB"    ,SC5->C5_I_QLIBB  , Nil})
   aAdd( _aCabPV, { "C5_I_CLILP"    ,SC5->C5_I_CLILP  , Nil})
   aAdd( _aCabPV, { "C5_I_CLILB"    ,SC5->C5_I_CLILB  , Nil})
   aAdd( _aCabPV, { "C5_I_LLIBB"    ,SC5->C5_I_LLIBB  , Nil})
   aAdd( _aCabPV, { "C5_I_ULIBB"    ,SC5->C5_I_ULIBB  , Nil})
   aAdd( _aCabPV, { "C5_I_LLIBP"    ,SC5->C5_I_LLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_HLIBP"    ,SC5->C5_I_HLIBP  , Nil})
   aAdd( _aCabPV, { "C5_I_FILOR"    ,SC5->C5_I_FILOR  , Nil})
   aAdd( _aCabPV, { "C5_I_PEDOR"   , SC5->C5_I_PEDOR  , Nil})
   aAdd( _aCabPV, { "C5_I_DTRAN"    ,SC5->C5_I_DTRAN  , Nil})
   aAdd( _aCabPV, { "C5_I_UTRAN"    ,SC5->C5_I_UTRAN  , Nil})
   aAdd( _aCabPV, { "C5_I_MTRAN"    ,SC5->C5_I_MTRAN  , Nil})
   aAdd( _aCabPV, { "C5_I_HORP "    ,SC5->C5_I_HORP   , Nil})
   aAdd( _aCabPV, { "C5_I_AGEND"    ,SC5->C5_I_AGEND  , Nil})
   aAdd( _aCabPV, { "C5_I_CHPCL"    ,SC5->C5_I_CHPCL  , Nil})
   aAdd( _aCabPV, { "C5_I_DOCA "    ,SC5->C5_I_DOCA   , Nil})
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF  , Nil})
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC  , Nil})
   aAdd( _aCabPV, { "C5_I_OBSAV"    ,SC5->C5_I_OBSAV  , Nil})
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT  , Nil})
   aAdd( _aCabPV, { "C5_I_PDFT "    ,SC5->C5_I_PDFT   , Nil})
   aAdd( _aCabPV, { "C5_I_PDPR "    ,SC5->C5_I_PDPR   , Nil})
   aAdd( _aCabPV, { "C5_TPFRETE"    ,SC5->C5_TPFRETE  , Nil})
   aAdd( _aCabPV, { "C5_I_PSORI"    ,SC5->C5_I_PSORI  , Nil})
   aAdd( _aCabPV, { "C5_I_TAB"      ,SC5->C5_I_TAB    , Nil})
   aAdd( _aCabPV, { "C5_I_PEDDW"    ,SC5->C5_I_PEDDW  , Nil})
   aAdd( _aCabPV, { "C5_I_TPVEN"    ,SC5->C5_I_TPVEN  , Nil})
   aAdd( _aCabPV, { "C5_VEND2"      ,SC5->C5_VEND2	  , Nil})
   aAdd( _aCabPV, { "C5_VEND3"      ,SC5->C5_VEND3	  , Nil})
   aAdd( _aCabPV, { "C5_VEND4"      ,SC5->C5_VEND4	  , Nil})
   aAdd( _aCabPV, { "C5_VEND5"      ,SC5->C5_VEND5	  , Nil})
   aAdd( _aCabPV, { "C5_I_SENHA"    ,SC5->C5_I_SENHA  , Nil})
   aAdd( _aCabPV, { "C5_I_NRZAZ"    ,SC5->C5_I_NRZAZ  , Nil})
   aAdd( _aCabPV, { "C5_I_LIBC"     ,SC5->C5_I_LIBC	  , Nil})
   aAdd( _aCabPV, { "C5_I_OPTRIN"   ,SC5->C5_I_OPTRIN , Nil}) // Tipo PV na operacao trian
   aAdd( _aCabPV, { "C5_I_PVREM"    ,SC5->C5_I_PVREM  , Nil}) // Pedido de Remessa
   aAdd( _aCabPV, { "C5_I_PVFAT"    ,SC5->C5_I_PVFAT  , Nil}) // Pedido de FAturamento
   aAdd( _aCabPV, { "C5_I_CLIEN"    ,SC5->C5_I_CLIEN  , Nil}) // Cli Remessa
   aAdd( _aCabPV, { "C5_I_LOJEN"    ,SC5->C5_I_LOJEN  , Nil}) // Loj Remessa

   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
   SC6->(DBSeek(xFilial("SC6")+_cNrPdPale))
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6") + _cNrPdPale

      _aItemPV:={}
      aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM"       , SC6->C6_ITEM }) //  Informa a posição do item
      aAdd( _aItemPV , { "AUTDELETA"  ,"N"             , Nil }) // Informa se o item será ou não excluído.
      aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
      aAdd( _aItemPV , { "C6_NUM"     ,SC6->C6_NUM     , Nil }) // Num. Pedido
      aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
      aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
      aAdd( _aItemPV , { "C6_UNSVEN"  ,SC6->C6_UNSVEN  , Nil }) // Quantidade Vendida 2 un
      aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
      aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
      aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
      aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
      aAdd( _aItemPV , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
      aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
      aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item // SC6->C6_VALOR
      aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
      aAdd( _aItemPV , { "C6_TES"     ,SC6->C6_TES     , Nil })
      aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
      aAdd( _aItemPV , { "C6_CF"      ,SC6->C6_CF	   , Nil })
      aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
      aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
      aAdd( _aItemPV , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
      aAdd( _aItemPV , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })
      aAdd( _aItemPV , { "C6_I_QPALT" ,SC6->C6_I_QPALT , Nil }) // Quantidade de Pallets
      aAdd( _aItemPV,  { "C6_I_USER " ,SC6->C6_I_USER , Nil})
      aAdd( _aItemPV,  { "C6_I_LIBPC" ,SC6->C6_I_LIBPC, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBP" ,SC6->C6_I_DLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBP" ,SC6->C6_I_PLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_ULIBP" ,SC6->C6_I_ULIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBP" ,SC6->C6_I_VLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLP" ,SC6->C6_I_MOTLP, Nil})
      aAdd( _aItemPV,  { "C6_I_QTLIP" ,SC6->C6_I_QTLIP, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILP" ,SC6->C6_I_CLILP, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILB" ,SC6->C6_I_CLILB, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBB" ,SC6->C6_I_VLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_QLIBB" ,SC6->C6_I_QLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBP" ,SC6->C6_I_LLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBB" ,SC6->C6_I_LLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLB" ,SC6->C6_I_MOTLB, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBB" ,SC6->C6_I_PLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBB" ,SC6->C6_I_DLIBB, Nil})
      aAdd( _aItemPV,  { "C6_COMIS1"  ,SC6->C6_COMIS1, Nil})
      aAdd( _aItemPV,  { "C6_COMIS2"  ,SC6->C6_COMIS2, Nil})
      aAdd( _aItemPV,  { "C6_COMIS3"  ,SC6->C6_COMIS3, Nil})
      aAdd( _aItemPV,  { "C6_COMIS4"  ,SC6->C6_COMIS4, Nil})
      aAdd( _aItemPV,  { "C6_COMIS5"  ,SC6->C6_COMIS5, Nil})
      aAdd( _aItemPV,  { "C6_I_PDESC" ,SC6->C6_I_PDESC, Nil})
      aAdd( _aItemPV,  { "C6_I_VLTAB" ,SC6->C6_I_VLTAB, Nil})
      aAdd( _aItemPV,  { "C6_ITEMPC"  ,SC6->C6_ITEMPC, Nil})

      aAdd( _aItensPV ,_aItemPV )

      SC6->(DBSkip())
   EndDo

   _cFilOrigem := SC5->C5_FILIAL
   _cPedOrigem := SC5->C5_I_NPALE

   lMsErroAuto:=.F.

   MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV, 5 )

   If lMsErroAuto
      _cNomeArqLog := "Pedido_de_Pallet_"+AllTrim(_cNrPdPale)+"_"+DToS(Date())+"_"+StrTran(Time(),":","_")+".log"
      _cMsgErro := MostraErro("\system\", _cNomeArqLog)
      //U_ItConOut(_cMsgErro)
      _lRet := .F.
   Else
      //=========================================================================================================
      // Confirmado a exclusão do pedido de pallet, remove o vinculo do pedido que originou o pedido de pallet.
      //=======================================================================================================
      If SC5->( DBSeek( _cFilOrigem + _cPedOrigem ) )
         SC5->( RecLock( 'SC5' , .F. ) )
         SC5->C5_I_NPALE := ''
         SC5->C5_I_PEDPA := ''
         SC5->C5_I_PEDGE := '' //É o Pedido Gerador de Pallet
         SC5->( MSUnLock() )
      EndIf
   EndIf

End Sequence

SC5->(DBGoTo(_nRegSC5))
SC6->(DBGoTo(_nRegSC6))

Return _lRet

/*
===============================================================================================================================
Programa----------: MT410VLJUS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2025
Descrição---------: Valida a digitação da justificativa de alteração de tipo de agendamenteo e alteração de data de entrega.
Parametros--------: _cDado  = Informação a ser validada
                    _cCampo = Campo que chamou a validação.
Retorno-----------: _lRet := .T. = Dados corretos
                             .F. = Erro nos dados
===============================================================================================================================
*/
Static Function MT410VLJUS(_cDado, _cCampo)

Local _lRet := .T.

Begin Sequence 
   If ! Empty(_cDado)
      ZY5->(DBSetOrder(1))
      If ! ZY5->(MsSeek(xFilial("ZY5")+_cDado))
         U_MT_ITMSG("O código de justificativa informado não existe.","Atenção",,1)
         _lRet := .F.
      Else
         If _cCampo == "C5_I_AGEND"
            _cObseAG := ZY5->ZY5_DESCR
         Else
            _cObseDE := ZY5->ZY5_DESCR
         EndIf 
      EndIf 
   EndIf 
End Sequence 

Return _lRet 
