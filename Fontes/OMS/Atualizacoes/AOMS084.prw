#Include "APWEBSRV.CH"
#Include "TOTVS.ch"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: AOMS084
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Rotina de integração e envio de dados dos Pedidos de Vendas via webservice para o sistema RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084()

Local _aCores  := {}
Local _afilial := {}
Local _nI      := 1
Local _cFilProc := ""

Private aRotina := {}
Private cCadastro
Private _lScheduler:= ( Select("SM0") <= 0 ) // ( Select("SX3") <= 0 )

If _lScheduler
    // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
    u_itconout( '[AOMS084] - TOTAL DO PROCESSO INICIALIZADO '  )

    RpcClearEnv()
    RpcSetType(2)

    // Preparando o ambiente com a filial da carga recebida
    RpcSetEnv("01", "01",,,,, {'SC5','SC6',"ZFQ","ZFR","SA2","SA1",'ZP1'})

    Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

    _cfilial := "01"

    _afilial := SuperGetMV('IT_FILINTW',.T.,"'01';'20';'23';'40';'90';'93'") // Filiais habilitadas na integracao Webservice Italac x RDC.
    _afilial := U_ITTXTARRAY(_afilial ,";",99)
    _cfilial := _aFilial[1]

    // Inicia processamento com base nas filiais do parâmetro.

    // Preparando o ambiente com a filial lida do parâmetro
    RpcClearEnv()
    RpcSetType(2)

    RpcSetEnv("01", _cfilial,,,,, {'SC5','SC6',"ZFQ","ZFR","SA2","SA1",'ZP1'})

    Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

    cFilAnt := _cfilial

   While _nI < Len(_afilial)

      u_itconout( '[AOMS084] - Iniciando schedule de pedidos para filial ' + cfilant )

      U_AOMS084I()

      u_itconout( '[AOMS084] -  Finalizado schedule de pedidos para filial ' + cfilant )

        _cFilProc := _cFilial

      _nI++

      _cfilial := _afilial[_nI]

      u_itconout( '[AOMS084] -  Abrindo o ambiente para filial '+ _cfilial + '...' )

      cfilant := _afilial[_nI]
      SM0->(DBSeek('01'+cfilant))

   EndDo

   //Executa último item
   If ! Empty(_cfilial)
      u_itconout( '[AOMS084] -  Iniciando schedule de pedidos para filial ' + cfilant )

      U_AOMS084I()
   EndIf

   If Empty(cfilant)
       cfilant:= _cFilProc
    EndIf

   u_itconout( '[AOMS084] -  Finalizado schedule de pedidos para filial ' + cfilant )

   u_itconout( '[AOMS084] - TOTAL DO PROCESSO FINALIZADO ' + cfilant )

Else

   //Grava Log de execução da rotina
   U_ITLOGACS()

   cCadastro := "Integração dos Dados dos Pedidos de Vendas Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"                     ,"U_AOMS084V" ,0,2})
   aAdd(aRotina,{"Integracao Webservice"          ,"U_AOMS084I" ,0,4})
   aAdd(aRotina,{"Legenda"                        ,"U_AOMS084L" ,0,6})
   aAdd(aRotina,{"Reprocessa pedidos"             ,"U_AOMS084Y" ,0,3})
   aAdd(aRotina,{"Reproc.Pedidos por Nota Fiscal" ,"U_AOMS084Z" ,0,3})

   aAdd(_aCores,{"ZFQ_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'R'" ,"BR_AMARELO" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'A'" ,"BR_LARANJA" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'L'" ,"BR_CINZA" })

   DBSelectArea("ZFQ")
   ZFQ->(DBSetOrder(1))
   ZFQ->(DBGoTop())
   MBrowse(6,1,22,75,"ZFQ", , , , , , _aCores)

EndIf

Return

/*
===============================================================================================================================
Função------------: AOMS084L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084L()

Local _aLegenda := {}

Begin Sequence
   aAdd(_aLegenda,{"BR_LARANJA"  ,"Aguardando Aprovação" })
   aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })
   aAdd(_aLegenda,{"BR_CINZA"    ,"Liberado Manualmente" })

   BrwLegenda(cCadastro, "Legenda", _aLegenda)

End Sequence

Return

/*
===============================================================================================================================
Função------------: AOMS084I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Rotina de integração e envio de dados dos Pedidos de Vendas via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084I()

Local _lRet := .F.
Local _aStrucZFQ
Local _aOrd := SaveOrd({"SX3","ZFQ"})
Local _aCmpZFQ := {}
Local _aButtons := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI

Private _oMarkZFQ, _cMarcaZFQ := GetMark()
Private aHeader := {} , aCols := {}

Begin Sequence
   //Montagem do aheader
   aHeader := {}
   FillGetDados(1,"ZFQ",1,,,{||.T.},,,,,,.T.)

   //                          1                    2               3              4               5                6             7        8              9                 10
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ
   aAdd( _aCmpZFQ , { "WK_OK"		,    , "Marca"                                          ,"@!"})

   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2])=="ZFQ_FILIAL" .Or. AllTrim(aHeader[_nI,2])=="ZFQ_DSCSIT"
          Loop
       EndIf
       aAdd( _aCmpZFQ , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next

   // Cria as estruturas das tabelas temporárias
   _aStrucZFQ := {}
   aAdd(_aStrucZFQ,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFQ,{"WKRECNO", "N", 10,0})
   For _nI := 1 To Len(aHeader)
       aAdd(_aStrucZFQ,{aHeader[_nI,2], aHeader[_nI,8], aHeader[_nI,4] ,aHeader[_nI,5]})
   Next

   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   If Select("TRBZFQ") > 0
      TRBZFQ->( DBCloseArea() )
   EndIf

   // Abre o arquivo TRBZFQ criado dentro do protheus.
   _otemp := FWTemporaryTable():New( "TRBZFQ",  _aStrucZFQ )

   // Cria os indices para o arquivo.
   _otemp:AddIndex( "01", {"ZFQ_DATA"} )
   _otemp:AddIndex( "02", {"ZFQ_PEDIDO","ZFQ_DATA"} )
   _otemp:Create()

   // Cria os indices da tabela temporária.
   DBSelectArea("TRBZFQ")

   // Tratamento para Schedule
   If _lScheduler
       u_itconout( '[AOMS084] -  - Atualizando pedidos retornados...' )

       _nTot := 0

       //===============================================================================================================
       //Atualiza pedidos retornados de data anterior para pedidos a serem enviados para o RDC
       //===============================================================================================================
       U_AOMS084K()
       //===============================================================================================================

       u_itconout( '[AOMS084] -  - Gravado no muro '+ AllTrim(Str( _nTot , 6 )) +' registros...' )

       u_itconout( '[AOMS084] -  - Lendo registros a serem integrados...' )
       _nTot := 0

       //Lendo dados a serem integrados e monta TRBZFQ
       U_AOMS084D()

       If _nTot = 0

          u_itconout( '[AOMS084] -  - Não foram encontrados pedidos para processar.' )

       Else

          u_itconout( '[AOMS084] -  - Enviando pedido para rdc '+ AllTrim(Str( _nTot , 6 )) +' registros...' )

          //Envia Xml para rdc ou para o TMS
          //Roda primeiro o TMS pra depois rodar o RDC
          U_AOMS084Q()
          U_AOMS084W()
          
       EndIf

       Break

   EndIf

   // Carrega os dados da tabela ZFQ
   
   FWMsgRun(,{|oproc|  U_AOMS084D(oproc)},'Aguarde processamento...','Lendo dados a serem integrados...')

   TRBZFQ->(DBGoTop())

   If TRBZFQ->(Eof())

     U_ITMsg("Não foram localizados registros para integrar","Atenção",,1)
     Break

   EndIf

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}

   aAdd(_aButtons,{"",{|| U_AOMS084M("T") }              ,"Marc/Des" ,"Marca/Desmarca Todos"})
   aAdd(_aButtons,{"",{|| U_AOMS084T(TRBZFQ->(Recno())) },"Pesquisar","Pesquisar"           })

  _cTitulo := "Integração de Pedidos de Vendas Via WebService"
   // Monta a tela de dados com MSSELECT.
   Define MsDialog _oDlgInt Title _cTitulo From 0,0 To 200,80 Of oMainWnd

      _oMarkZFQ := MsSelect():New("TRBZFQ","WK_OK","",_aCmpZFQ,@_lInverte, @_cMarcaZFQ,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})

      _oMarkZFQ:bAval := {|| U_AOMS084M("P")}
      _oDlgInt:lMaximized:=.T.

   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZFQ:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZFQ:oBrowse:Refresh() )

   If _lRet
      FWMsgRun(, {|oproc| U_AOMS084Q(oproc) } , 'Aguarde!' , 'Integrando Dados do Pedido de Vendas...' )
      FWMsgRun(, {|oproc| U_AOMS084W(oproc) } , 'Aguarde!' , 'Integrando Dados do Pedido de Vendas...' )
   EndIf
End Sequence

// Fecha e exclui as tabelas temporárias
If Select("TRBZFQ") > 0
   TRBZFQ->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função----------: AOMS084M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/10/2016
Descrição-------: Função para marcar e desmarcar todos Pedidos de Vendas que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS084M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZFQ->(Recno())

Begin Sequence
   If Empty(TRBZFQ->WK_OK )
      _cSimboloMarca := _cMarcaZFQ
   Else
      _cSimboloMarca := Space(2)
   EndIf

   If _cTipoMarca == "P"
      TRBZFQ->(RecLock("TRBZFQ",.F.))
      TRBZFQ->WK_OK := _cSimboloMarca
      TRBZFQ->(MSUnLock())
   Else
      TRBZFQ->(DBGoTop())
      While ! TRBZFQ->(Eof())
         TRBZFQ->(RecLock("TRBZFQ",.F.))
         TRBZFQ->WK_OK := _cSimboloMarca
         TRBZFQ->(MSUnLock())

         TRBZFQ->(DBSkip())
      EndDo

   EndIf

End Sequence

TRBZFQ->(DBGoTo(_nRegAtu))
_oMarkZFQ:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Função------------: AOMS084W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Gera os dados XML com base nos Pedidos de Vendas selecionados e integra via webservice
                    para o sistema RDC.
Parametros--------: oproc - objeto da barra de progresso
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084W(oproc)

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cItemXML := ""
Local _cDetA_XML := ""
Local _cDetB_XML := ""
Local _cRodXML := ""
Local _cDadosItens
Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFQ","ZFM","ZFR","SC9","SC5"})
Local _lReserva := SuperGetMV('IT_GESTPVR',.T.,.F.)
Local _cXML
Local _cResult := ""
Local _aRecnoItem, _nI
Local _lEnvXml
Local _cResposta, _cSituacao, _cReserva
Local lAchouSC5 := .F.

Default oproc := nil

Begin Sequence
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
If !_lScheduler

   If ValType(oproc) = "O"

      oproc:cCaption := ("1/10 - Verificando itens selecionados...")
      ProcessMessages()

   EndIf

   TRBZFQ->(DBGoTop())
   While ! TRBZFQ->(Eof())
      If ! Empty(TRBZFQ->WK_OK)
         _cEmpWebService := TRBZFQ->ZFQ_CODEMP
         _lItemSelect := .T.
         Exit
      EndIf

      TRBZFQ->(DBSkip())
   EndDo

   If ! _lItemSelect
      U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção",,1)
      Break
   EndIf

Else

   TRBZFQ->(DBGoTop())//Todos estão marcados
   _cEmpWebService := TRBZFQ->ZFQ_CODEMP

EndIf
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("2/10 - Identificando diretório dos XML...")
            ProcessMessages()

         EndIf

   EndIf
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else
      If _lScheduler
         u_itconout( "[AOMS084] - Empresa WebService para envio dos dados não localizada.")
      Else
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      Break
   EndIf

If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lScheduler
         u_itconout("[AOMS084] - Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      Else
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf
      Break
EndIf

_cDirXML := AllTrim(_cDirXML)
If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
EndIf

// Lê os arquivos modelo XML e os transforma em String.
If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("3/10 - Lendo arquivo XML Modelo de Cabeçalho...")
            ProcessMessages()

         EndIf

EndIf
_cCabXML := U_AOMS084X(_cDirXML+"Cab_EnviaPedido.txt")
If Empty(_cCabXML)
      If _lScheduler
         u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do cabeçalhode envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de envio Pedido de Vendas. ","Atenção",,1)
      EndIf
      Break
EndIf

If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("4/10 - Lendo arquivo XML Modelo de Detalhe A...")
            ProcessMessages()

         EndIf

EndIf

_cDetA_XML := U_AOMS084X(_cDirXML+"DET_A_EnviaPedido.txt")

If Empty(_cDetA_XML)
   If _lScheduler
      u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do detalhe A de envio Pedido de Vendas.")
   Else
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A de envio Pedido de Vendas.","Atenção",,1)
   EndIf
      Break
EndIf

If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("5/10 - Lendo arquivo XML Modelo de Detalhe B...")
            ProcessMessages()

         EndIf

EndIf

_cDetB_XML := U_AOMS084X(_cDirXML+"DET_B_EnviaPedido.txt")

If Empty(_cDetB_XML)
      If _lScheduler
         u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do detalhe B de envio Pedido de Vendas..")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe B de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break

EndIf

If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("6/10 - Lendo arquivo XML Modelo de Item de Pedido...")
            ProcessMessages()

         EndIf

EndIf

_cItemXML := U_AOMS084X(_cDirXML+"Item_EnviaPedido.txt")

If Empty(_cItemXML)
      If _lScheduler
         u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo dos itens de envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo dos itens de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break

EndIf

If !_lScheduler

         If ValType(oproc) = "O"

            oproc:cCaption := ("7/10 - Lendo arquivo XML Modelo de Rodapé...")
            ProcessMessages()

         EndIf

EndIf

_cRodXML := U_AOMS084X(_cDirXML+"Rodape_EnviaPedido.txt")
If Empty(_cRodXML)
      If _lScheduler
         u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do rodapé de envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
EndIf

// Verifica se o pedido já tem liberação, não permite a integração via Webservice e muda a situação
// do registro na tabela de muro para "Liberado Manualmente".
SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO
ZFR->(DBSetOrder(5))
SC5->(DBSetOrder(1))

// Verifica se existe algum item para envio de XML que não foi liberado manualmente.
_lEnvXml := .F.

TRBZFQ->(DBGoTop())
While ! TRBZFQ->(Eof())
      If ! Empty(TRBZFQ->WK_OK) //.AND. TRBZFQ->ZFQ_PEDIDO == '500324'//RETIRAR
         _lEnvXml := .T.
         Exit
      EndIf

      TRBZFQ->(DBSkip())
EndDo
If ! _lEnvXml  // Não há dados para envio do XML.
      Break
EndIf

// Concatena os Pedidos de Vendas selecionados e monta array de XML com os dados.
If !_lScheduler
   If ValType(oproc) = "O"
      oproc:cCaption := ("8/10 - Montando dados de envio...")
      ProcessMessages()
   EndIf
EndIf

oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.

oWsdl:nTimeout := 90          // Timeout de 90 segundos
oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo

oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.
oWsdl:SetOperation( "EnviaPedido") // Define qual operação será realizada.

_aresult := {}

ZFR->(DBSetOrder(5))
SC9->(DBSetOrder(1))

If ValType(oproc) = "O"

   oproc:cCaption := ("9/10 - Enviando dados para RDC...")
   ProcessMessages()

EndIf


TRBZFQ->(DBGoTop())
While ! TRBZFQ->(Eof())

      If ! Empty(TRBZFQ->WK_OK) 
         ZFQ->(DBGoTo(TRBZFQ->WKRECNO))
         If (SC5->(DBSeek(ZFQ->ZFQ_FILIAL+ZFQ->ZFQ_PEDIDO))) 
            lAchouSC5 := .T. 
            If U_IT_TMS(SC5->C5_I_LOCEM)
               TRBZFQ->(DBSkip())
               Loop
            EndIf
         Else
            lAchouSC5 := .F. 
         EndIf

         Begin Transaction


            u_itconout( '[AOMS084] -  - Enviando pedido ' + ZFQ->ZFQ_PEDIDO + ' para rdc ...' )

            If ValType(oproc) = "O"

               oproc:cCaption := ("10/10 - Enviando dados para RDC - Pedido " + ZFQ->ZFQ_PEDIDO + "..." )
               ProcessMessages()

            EndIf


            If !lAchouSC5  //Se não achar o pedido de vendas marca como enviado e não transmite

               ZFQ->(RecLock("ZFQ",.F.))
               ZFQ->ZFQ_SITUAC  := "P"
               ZFQ->ZFQ_DATAAL  := Date()
               ZFQ->ZFQ_RETORN  := "Eliminado por exclusão do pedido no SC5"
               ZFQ->ZFQ_DATAP := Date()
               ZFQ->ZFQ_HORAP := Time()
               ZFQ->(MSUnLock())
               u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' eliminado da muro por exclusão ...' )

            ElseIf !Empty(SC5->C5_NOTA) //Se pedido já tem nota não envia mais para RDC

               ZFQ->(RecLock("ZFQ",.F.))
               ZFQ->ZFQ_SITUAC  := "P"
               ZFQ->ZFQ_DATAAL  := Date()
               ZFQ->ZFQ_RETORN  := "Eliminado por SC5 já possuir nota emitida"
               ZFQ->ZFQ_DATAP := Date()
               ZFQ->ZFQ_HORAP := Time()
               ZFQ->(MSUnLock())
               u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' eliminado da muro por ter nota emitida ...' )

            Else

               //Verifica se consegue lockar o SC5
               If !(SC5->(Msrlock(SC5->(Recno()))))

                     //Se não conseguir lockar o SC5 desarma a transação e parte para o próximo registro
                     Disarmtransaction()
                     TRBZFQ->(DBSkip())
                     u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' não enviado por lock na SC5 ...' )
               Else

                 // Atualiza a situação e reserva do pedido de vendas, antes de enviar para o sistema RDC.
                 _cReserva := ""
                 _cMotivo := ""
                 If ! SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
                    _cReserva := "1" // Não tem reserva de estoque = Verde => Sem Reserva
                    _cMotivo  := "Não tem reserva de estoque = Verde => Sem Reserva"
                 Else
                  If U_Verest()
                     _cReserva := "2" // Conseguiu reservar estoque = Amarelo => Reservado
                  Else
                     _cReserva := "3" // Não há estoque disponível  = Azul => Bloqueio de estoque
                     _cMotivo  :=  "Não há estoque disponível  = Azul => Bloqueio de estoque"
                  EndIf

                 EndIf

                  If _cReserva <> "2" .And. _lReserva
                     //Se não consegue reservar estque desarma a transação e parte para o próximo registro
                     Disarmtransaction()
                     TRBZFQ->(DBSkip())
                     u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' não enviado. Motivo: '+_cMotivo )
                  EndIf

                 ZFQ->(RecLock("ZFQ",.F.))
                 ZFQ->ZFQ_RESERV := _cReserva
                 ZFQ->ZFQ_SITPED	:= U_STPEDIDO() // Status do Pedido, rotina no xfunoms
                 ZFQ->(MSUnLock())

                 // Realiza a integração dos pedidos de vendas (Envio de XML) via WebService.
                 ZFR->(DBSeek(ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)+"N"))

                 _aRecnoItem := {}
                 _cDadosItens := ""
                 While ! ZFR->(Eof()) .And. ZFR->(ZFR_FILIAL+ZFR_NUMPED+ZFR_SITUAC) = ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)+"N"
                  _cDadosItens += &(_cItemXML)
                  aAdd(_aRecnoItem,ZFR->(Recno()))

                  ZFR->(DBSkip())

                 EndDo

                //Monta XML
                _cXML := _cCabXML + &(_cDetA_XML)+ _cDadosItens + &(_cDetB_XML) + _cRodXML  // Monta o XML de envio.

                //Limpa & da string
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

                 // "Importado Com Sucesso"
                 _cSituacao := "P"


                 If ! _cOk
                  _cSituacao := "N"
                 ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta .Or. "REGISTRO EXISTE" $ _cResposta)
                 _cSituacao := "N"

                EndIf

                //grava resultado // sempre como processado

                ZFQ->(RecLock("ZFQ",.F.))
                 ZFQ->ZFQ_SITUAC  := _cSituacao // IIf(_cok, "P", "N")

                 ZFQ->ZFQ_DATAAL  := Date()
                 ZFQ->ZFQ_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não.
                 ZFQ->ZFQ_XML     := _cXML
                 ZFQ->ZFQ_DATAP := Date()
                 ZFQ->ZFQ_HORAP := Time()
                 ZFQ->(MSUnLock())

                 _lfalha := .F.  //Verifica se tem falha de processamento no Loop a seguir

                 For _nI := 1 To Len(_aRecnoItem)

                   ZFR->(DBGoTo(_aRecnoItem[_nI]))


                   ZFR->(RecLock("ZFR",.F.))
                   ZFR->ZFR_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
                   ZFR->ZFR_DATAAL  := Date()
                   ZFR->ZFR_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não.
                   ZFR->(MSUnLock())

                 Next

                 If _cSituacao == "P"

                   SC5->(RecLock("SC5",.F.))
                   SC5->C5_I_ENVRD := "S"
                   SC5->(MSUnLock())
                   SC5->(MSUnLockall())
                   u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' enviado para rdc ...' )

                 Else

                  SC5->(MSUnLock())
                  SC5->(MSUnLockall())
                  u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' falhou envio para rdc ...' )

                 EndIf

                 aAdd(_aresult,{ZFQ->ZFQ_PEDIDO,ZFQ->ZFQ_CNPJEM,ZFQ->ZFQ_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
                 Sleep(100) //Espera para não travar a comunicação com o webservice da RDC

               EndIf
           EndIf
         End Transaction
         SC5->(MSRUNLOCK(SC5->(Recno())))
      EndIf

      TRBZFQ->(DBSkip())

EndDo

_aCabecalho := {}
aAdd(_aCabecalho,"PEDIDO" )
aAdd(_aCabecalho,"CNPJ")
aAdd(_aCabecalho,"RETORNO")

_cTitulo := "Resultados da integração"

If Len(_aresult) > 0 .And. !_lScheduler

   u_ITListBox( _cTitulo , _aCabecalho , _aresult  ) // Exibe uma tela de resultado.

EndIf



End Sequence

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função-------------: AOMS084X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: _cRet
===============================================================================================================================
*/
User Function AOMS084X(_cArq)
Local _cRet := ""
Local _nStatusArq
Local _cLine

Begin Sequence
   _nStatusArq := FT_FUse(Lower(_cArq))

   // Se houver erro de abertura abandona processamento
   If _nStatusArq = -1
      Break
   EndIf

   // Posiciona na primeria linha
   FT_FGoTop()


   While !FT_FEOF()
      _cLine  := FT_FReadLn()

      _cRet +=  _cLine

      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _cRet

/*
===============================================================================================================================
Função------------: AOMS084D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: oproc - objeto de barra de processamento
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function AOMS084D(oproc)
Local _lRet := .F.,_nI
Local _nregs := 0
Local _npos := 1
Local _cFilAcesso:=AllTrim(SuperGetMV('IT_GESTAOP',.T.,'XX' ) )
Local _cOpeAcesso:=AllTrim(SuperGetMV('IT_GESTPVO',.T.,"01;20;24;25;26;42") )
Local _aDadosZFQ := {}
Local _cIT_NAGEND := AllTrim(SuperGetMV("IT_NAGEND",.F., "P;R;N"))//P=Aguardando Agenda; R=Reagendar; N=Reagendar com Multa
//Local _lWsTms

Default oproc := nil

_cTipoOper  := SuperGetMV('IT_TIPOOPE',.T.,'01;10;17;20;41;')
_nTot:=0

Begin Sequence
   // Indica se rotina de integração WebService é TMS Multi-Embarcador ou RDC.
   If !_lScheduler .And. ValType(oproc) = "O"
      oproc:cCaption := ("Lendo registros...")
      ProcessMessages()
   EndIf


   //Carrega total de registros
   ZFQ->(DBGoTop())
   ZFQ->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
   ZFQ->(DBSeek(xFilial("ZFQ")+"N"))

   While ! ZFQ->(Eof()) .And. ZFQ->(ZFQ_FILIAL+ZFQ_SITUAC) == xFilial("ZFQ")+"N"

     _nregs++
     ZFQ->(DBSkip())

   EndDo

   ZFQ->(DBGoTop())
   ZFQ->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
   ZFQ->(DBSeek(xFilial("ZFQ")+"N"))

   While ! ZFQ->(Eof()) .And. ZFQ->(ZFQ_FILIAL+ZFQ_SITUAC) == xFilial("ZFQ")+"N"

      If !_lScheduler .And. ValType(oproc) = "O"
         oproc:cCaption := ("Processando registro " + StrZero(_npos,9) + " de " + StrZero(_nregs,9) + "...")
         ProcessMessages()
      EndIf
      _npos++
      
      _lLoop:=.F.
      If SC5->(DBSeek(ZFQ->ZFQ_FILIAL+U_ItKey(ZFQ->ZFQ_PEDIDO,"C5_NUM")))
         
         //========================================
         // Integração com o Sistema RDC ativa.
         // Fitra dados gerados para o TMS.
         //========================================
         If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms 
            If "TMS" $ ZFQ->ZFQ_FLUXO  // Indica dados gerados para o sistema TMS 
               ZFQ->(DBSkip())
               Loop
            EndIf 
         EndIf 
         //======================================= Fim Filtro de dados para o RDC <<< 

         
         // Pedidos com tipo de entraga: P=Aguardando Agenda; R=Reagendar; N=Reagendar que não pode enviar
         If SC5->C5_TIPO = 'N' .And. SC5->C5_I_AGEND $  _cIT_NAGEND //P=Aguardando Agenda; R=Reagendar; N=Reagendar
            _lLoop:=.T.
         EndIf
         
         //Só envia pedidos cuja o campo SC5->C5_I_BLSLD = 'N'
         If SC5->(FIELDPOS("C5_I_BLSLD")) > 0 .And. SC5->C5_I_BLSLD = 'S'
            _lLoop:=.T.
         EndIf

         If !_lLoop .And. SC5->C5_FILIAL $ _cFilAcesso .And. SC5->C5_I_OPER $ _cOpeAcesso  .And. SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
            While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
               If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))	.Or. !Empty(SC9->C9_BLEST) .Or. SC9->C9_QTDLIB <> SC6->C6_QTDVEN
                    _lLoop:=.T.
                   Exit
               EndIf
               SC6->(DBSkip())
            EndDo
         EndIf

      Else
         _lLoop:=.T.
      EndIf

      If _lLoop
         ZFQ->(DBSkip())
         Loop
      EndIf


      TRBZFQ->(DBAPPEND())
      For _nI := 1 To ZFQ->(FCount())

          nPos:=TRBZFQ->(FieldPos(  ZFQ->( FieldName(_nI)) ))
          If nPos # 0
              If ValType(ZFQ->( FieldGet(_nI))) == "C" .And. Len(ZFQ->( FieldGet(_nI))) > 1000
                 TRBZFQ->(FieldPut(nPos,SubStr(ZFQ->( FieldGet(_nI) ),1,1000) ))
              Else
                 TRBZFQ->(FieldPut(nPos,ZFQ->( FieldGet(_nI) ) ))
              EndIf
          EndIf

      Next

      If .T.

       //------------------------------------------------------------------------------------------------------
       // Filtro temporário, após definição definitiva tirar pergunta de escolha se filtra ou não. //
       //------------------------------------------------------------------------------------------------------

       SC5->(DBSetOrder(1))
       SC6->(DBSetOrder(1))
       SC9->(DBSetOrder(1))
       If SC5->(DBSeek(ZFQ->ZFQ_FILIAL+U_ITKEY(ZFQ->ZFQ_PEDIDO,"C5_NUM"))) .And. SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

          If SC5->C5_I_ENVRD == 'S' //Se pedido já está marcado cAOMS084Domo enviado marca muro como enviado também

            aAdd(_aDadosZFQ,ZFQ->(Recno()))

          ElseIf SC5->C5_FILIAL == '40' .Or. (SC5->C5_FILIAL == '01') .Or. ( SC5->C5_FILIAL = '90' .And. SC6->C6_Local == '36') .Or. SC5->C5_FILIAL == '20' .Or. SC5->C5_FILIAL == '23' .Or. SC5->C5_FILIAL == '93'  .Or. SC5->C5_FILIAL == '10' .Or. SC5->C5_FILIAL == '31' .Or. SC5->C5_FILIAL == '30' // ( SC5->C5_FILIAL = '90' .And. SC6->C6_Local == '36')

             If Empty(SC5->C5_NOTA) //Só manda o que ainda não tem nota

                If SC5->C5_TIPO == "N"  //Só manda pedido tipo normal

                   If SC5->C5_I_ENVRD <> "S" .And. SC5->C5_I_ENVRD <> "R" .And. SC5->C5_I_ENVRD <> "V"//Só manda pedidos que estão com status de não enviado

                     If SC5->C5_I_OPER $ _cTipoOper  //Só operações do parâmetro IT_TIPOOPER

                         If !(SC5->C5_I_TRCNF == 'S' .And. SC5->C5_I_PDPR == SC5->C5_NUM) //Não envia pedido carregamento troca nota

                               //Analisa se tem item no armazém 40
                               SC6->(DBSetOrder(1))
                               If (SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM)))

                                  _ltem40 := .F.
                                  _ltemcarga := .F.
                                  SC9->(DBSetOrder(1))
                                  While SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM

                                     If SC6->C6_Local == '40' .Or. SC6->C6_Local == '42' .Or. SC6->C6_Local == '50' .Or. SC6->C6_Local == '52'

                                        _ltem40 := .T.

                                     EndIf

                                     If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))

                                        If !Empty(SC9->C9_CARGA)

                                           _ltemcarga := .T.

                                        EndIf

                                     EndIf

                                     SC6->(DBSkip())

                                  EndDo


                                  If !(_ltem40) .And. !(_ltemcarga)

                                     TRBZFQ->WK_OK := _cMarcaZFQ
                                     _nTot++

                                  EndIf

                               EndIf

                         EndIf

                     EndIf

                  EndIf

                EndIf

             EndIf

          EndIf

       EndIf

      EndIf

      If TRBZFQ->WK_OK != _cMarcaZFQ

         TRBZFQ->(DbDelete())

      Else

         TRBZFQ->WKRECNO := ZFQ->(Recno())

      EndIf

      _lRet := .T.
      ZFQ->(DBSkip())
   EndDo

   For _nI := 1 To Len(_aDadosZFQ)
       ZFQ->(DBGoTo(_aDadosZFQ[_nI]))
       RecLock("ZFQ",.F.)
       ZFQ->ZFQ_SITUAC := 'P'
       ZFQ->ZFQ_DATAP := Date()
       ZFQ->ZFQ_HORAP := Time()
       ZFQ->(MSUnLock())
   Next

   TRBZFQ->(DBGoTop())

End Sequence

Return _lRet

/*
===============================================================================================================================
Função------------: AOMS084N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Com base em um endereço passado como parâmetro, retorna o numero deste endereço.
Parametros--------: _cEndereco = Endereço a ser lido e retornado o número.
Retorno-----------: _cRet
===============================================================================================================================
*/
User Function AOMS084N(_cEndereco)
Local _cRet := "000000"
Local _nPos
Local _nI
Local _cPartNumero
Local _lTipoNumerico

Begin Sequence
   If Empty(_cEndereco)
      Break
   EndIf

   _nPos := At(",",_cEndereco) // Retorna a posição da primeira virgula encontrada no endereço

   If _nPos == 0 // Se não existir virgula no endereço, não retorna nada.
      Break
   EndIf

   _cPartNumero := AllTrim(SubStr(_cEndereco,_nPos+1,Len(_cEndereco))) // Pega a parte do endereço do numero em diante.

   _lTipoNumerico := .T.
   For _nI := 1 To Len(_cPartNumero) // Localiza a posição que termina o numero.
       If ! SubStr(_cPartNumero,_nI,1) $ "0123456789"
          _lTipoNumerico := .F.
          Exit
       EndIf

       If SubStr(_cPartNumero,_nI,1) $ " ,.-/\"
          _nPos := _nI - 1
          Exit
       Else
          _nPos := _nI
       EndIf
   Next

   If _lTipoNumerico
      _cRet := SubStr(_cPartNumero,1,_nPos)  // Retorna apenas o numero do endereço.
   EndIf

End Sequence

If Empty(AllTrim(_cret))

  _cret := "00000"

 EndIf

Return _cRet

/*
===============================================================================================================================
Função------------: AOMS084P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Grava os dados dos Pedidos de Vendas nas tabelas de muro, através de ponto de entrada, após a inclusão
                    ou alteração de um pedido de vendas.
Parametros--------: _cSituacao = situação do pedido de vendas na gravação da tabela de muro.
                    oproc      = objeto da barra de progresso
                    _cChamada  = BROWSER = Browser do Pedido de Vendas.
                               = MANUTENCAO = Manutenção do Pedido de Vendas.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084P(_cSituacao, oproc, _cChamada, _cSulfixo)
Local _aOrd := SaveOrd({"ZFQ","ZFR","SC6","SA2","SA1"})
Local _nRegSC6 := SC6->(Recno())
Local _nI
Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.T.,'000001')
Local _aFilial := FwLoadSM0()
Local _cCnpj
Local _aUF, _cUFCli
Local _aCalcItens
Local _lSeekSB5
Local _nQtd, _cUnidade, _nPesoUnit, _nPesoTot, _nPrecoVenda
Local _cTipoCA
Local _cForEmbM, _cLojaEmbM, _cFilRDC
Local _cEndereco, _cNumero, _cComplemento, _cIBGEFA, _cBairro
Local _nRegSA2
Local _nFatConvPa
Local _lTemSitN
Local _nQtdPecas := 0
//Local _lWsTms
Local _cIndIEExp,_cIndIEFor,_cIndIECli
Local _cPedCliente:= ""
Local _cIT_NAGEND := AllTrim(SuperGetMV("IT_NAGEND",.F., "P;R;N"))//P=Aguardando Agenda; R=Reagendar; N=Reagendar com Multa

Default oproc := nil, _cChamada := "BROWSER"

//Se estiver no webservice não executa
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
   Return
EndIf


Begin Sequence

   If ValType(_cSulfixo) == "U"
      _cSulfixo := ""
   EndIf

   // Esta condição bloqueia a gravação na tabela de muro e envio ao RDC de pedidos de vendas do
   // tipo troca nota.
   If SC5->C5_I_FILFT == SC5->C5_FILIAL  .And. SC5->C5_I_PDFT == SC5->C5_NUM .And. SC5->C5_I_TRCNF == 'S' .And. ! FWIsInCallStack("U_AOMS140I") .And. ! FWIsInCallStack("U_AOMS152A")
      If Type("ncont") == "N"
         ncont := ncont - 1
         _nNaoIntegra += 1
      EndIf

      Break
   EndIf

   //============================================================================================
   //Se o pedido já tem nota emitida não faz mais inclusões ou alterações na tabela de muro
   //============================================================================================
   If !Empty(SC5->C5_NOTA) .And. ! FWIsInCallStack("U_AOMS140I") .And. ! FWIsInCallStack("U_AOMS152A")

      If Type("ncont") == "N"
         ncont := ncont - 1
         _nNaoIntegra += 1
      EndIf

        Break

   EndIf

   //============================================================================================
   //Só envia pedidos cuja operação pertença ao IT_TIPOOPER
   //============================================================================================
   _cTipoOper  := SuperGetMV('IT_TIPOOPE',.T.,'01;10;17;20;41;')
   If !(SC5->C5_I_OPER $ _cTipoOper)

      If Type("ncont") == "N"
         ncont := ncont - 1
         _nNaoIntegra += 1
      EndIf

        Break

   EndIf

   //====================================================================================================
   // Pedidos com tipo de entraga: P=Aguardando Agenda; R=Reagendar; N=Reagendar que não pode enviar  
   //====================================================================================================
   If SC5->C5_TIPO = 'N' .And. SC5->C5_I_AGEND $  _cIT_NAGEND .And. ! FWIsInCallStack("U_AOMS152A") //P=Aguardando Agenda; R=Reagendar; N=Reagendar
      If Type("ncont") == "N"
         ncont := ncont - 1
         _nNaoIntegra += 1
      EndIf
      Break
   EndIf

   //============================================================================================
   //Só envia pedidos cuja o campo SC5->C5_I_BLSLD = 'N'
   //============================================================================================
   If SC5->(FIELDPOS("C5_I_BLSLD")) > 0 .And. SC5->C5_I_BLSLD = 'S'
      If Type("ncont") == "N"
         ncont := ncont - 1
         _nNaoIntegra += 1
      EndIf
      Break
   EndIf


   //================================================================================
   // Caso já existe registro não processado apaga tudo
   //================================================================================

   cQuery	:= " SELECT ZFQ.r_e_c_n_o_ REG "
   cQuery	+= " FROM  "+ RetSqlName('ZFQ') + " ZFQ "
   If ! Empty(_cSulfixo) .And. _cSulfixo == "ESP"
      cQuery	+= " WHERE "+ RetSqlDel('ZFQ') + " AND ZFQ_PEDIDO = '" + SC5->C5_NUM + "_" + _cSulfixo + "' AND ZFQ_SITUAC = 'C' "
   ElseIf ! Empty(_cSulfixo)
      cQuery	+= " WHERE "+ RetSqlDel('ZFQ') + " AND ZFQ_PEDIDO = '" + SC5->C5_NUM + "_" + _cSulfixo + "' AND ZFQ_SITUAC = 'T' "
   Else
      cQuery	+= " WHERE "+ RetSqlDel('ZFQ') + " AND ZFQ_PEDIDO = '" + SC5->C5_NUM + "' AND ZFQ_SITUAC = 'N' "
   EndIf
   If Select("TRABT") <> 0
      TRABT->( DBCloseArea(  ) )
   EndIf

   MPSysOpenQuery( cQuery , "TRABT")
   DBSelectArea("TRABT")

   _lTemSitN := .F.

   While !(TRABT->(Eof()))

       ZFQ->(DBGoTo(TRABT->REG))

      If ! Empty(_cSulfixo) // Chamado da geração de carga Troca Nota Fiscal
         If ZFQ->ZFQ_SITUAC == "T" .Or. ZFQ->ZFQ_SITUAC == "C"
            _lTemSitN := .T.
             ZFQ->(RecLock("ZFQ",.F.))
            ZFQ->(DbDelete())
            ZFQ->(MSUnLock())
         EndIf
      Else  // Chamada da integração com o RDC
         If ZFQ->ZFQ_SITUAC == "N"
            _lTemSitN := .T.
            ZFQ->(RecLock("ZFQ",.F.))
            ZFQ->(DbDelete())
            ZFQ->(MSUnLock())
         EndIf
      EndIf

        TRABT->(DBSkip())

   EndDo

   //===========================================================================================================
   // Se a chamada da função AOMS084P tiver sido feita da rotina de manutenção de pedidos de vendas,
   // e não existir na tabela de muro pedidos de vendas com situação igual "N", não se deve gerar tabela de muro.
   //===========================================================================================================
   If ! Empty(_cChamada) .And. _cChamada == "MANUTENCAO"
      If ! _lTemSitN .And. SC5->C5_I_ENVRD <> "R" .And. ! Empty(SC5->C5_I_ENVRD)
         Break
      ElseIf SC5->C5_I_ENVRD == "R"
         SC5->(RecLock("SC5",.F.))
         SC5->C5_I_ENVRD := "N"
         SC5->(MSUnLock())
      EndIf
   EndIf

   cQuery	:= " SELECT ZFR.r_e_c_n_o_ REG "
   cQuery	+= " FROM  "+ RetSqlName('ZFR') + " ZFR "

   If ! Empty(_cSulfixo) .And. _cSulfixo == "ESP"
      cQuery	+= " WHERE "+ RetSqlDel('ZFR') + " AND ZFR_NUMPED = '" + SC5->C5_NUM + "_" +_cSulfixo + "' AND ZFR_SITUAC = 'C' "
   ElseIf ! Empty(_cSulfixo)
      cQuery	+= " WHERE "+ RetSqlDel('ZFR') + " AND ZFR_NUMPED = '" + SC5->C5_NUM + "_" +_cSulfixo + "' AND ZFR_SITUAC = 'T' "
   Else
      cQuery	+= " WHERE "+ RetSqlDel('ZFR') + " AND ZFR_NUMPED = '" + SC5->C5_NUM + "' AND ZFR_SITUAC = 'N' "
   EndIf

   If Select("TRABT") <> 0
      TRABT->( DBCloseArea(  ) )
   EndIf

   MPSysOpenQuery( cQuery , "TRABT")
   DBSelectArea("TRABT")

   While !(TRABT->(Eof()))

          ZFR->(DBGoTo(TRABT->REG))
          If ! Empty(_cSulfixo) // Chamado da geração de carga Troca Nota Fiscal
             If ZFR->ZFR_SITUAC == "T" .Or. ZFR->ZFR_SITUAC == "C"
                  ZFR->(RecLock("ZFR",.F.))
                 ZFR->(DbDelete())
                 ZFR->(MSUnLock())
             EndIf
          Else // Chamada da integração com o RDC.
             If ZFR->ZFR_SITUAC == "N"
                ZFR->(RecLock("ZFR",.F.))
                 ZFR->(DbDelete())
                 ZFR->(MSUnLock())
              EndIf
          EndIf

         TRABT->(DBSkip())

    EndDo

   //================================================================================
   // Monta array dos estados
   //================================================================================
   _aUF := {}
   aAdd(_aUF,{"RO","11"})
   aAdd(_aUF,{"AC","12"})
   aAdd(_aUF,{"AM","13"})
   aAdd(_aUF,{"RR","14"})
   aAdd(_aUF,{"PA","15"})
   aAdd(_aUF,{"AP","16"})
   aAdd(_aUF,{"TO","17"})
   aAdd(_aUF,{"MA","21"})
   aAdd(_aUF,{"PI","22"})
   aAdd(_aUF,{"CE","23"})
   aAdd(_aUF,{"RN","24"})
   aAdd(_aUF,{"PB","25"})
   aAdd(_aUF,{"PE","26"})
   aAdd(_aUF,{"AL","27"})
   aAdd(_aUF,{"MG","31"})
   aAdd(_aUF,{"ES","32"})
   aAdd(_aUF,{"RJ","33"})
   aAdd(_aUF,{"SP","35"})
   aAdd(_aUF,{"PR","41"})
   aAdd(_aUF,{"SC","42"})
   aAdd(_aUF,{"RS","43"})
   aAdd(_aUF,{"MS","50"})
   aAdd(_aUF,{"MT","51"})
   aAdd(_aUF,{"GO","52"})
   aAdd(_aUF,{"DF","53"})
   aAdd(_aUF,{"SE","28"})
   aAdd(_aUF,{"BA","29"})
   aAdd(_aUF,{"EX","99"})

   //---------------------------
   _cUFCli    := ""    // Estado do Cliente
   _cInscrCli := ""    // InscricaoEstadual
   _cNomeFCli := ""    // NomeFantasia
   _cRGIECl   := ""    // RGIE
   _cRazaoCli := ""    // RazaoSocial
   _cTipoPCli := ""    // TipoPessoa
   _cCEPCli   := ""    // CEP

   //========================================================
   // Obtem dados do Vendedor
   //========================================================
   _cCodVend  := SC5->C5_VEND1
   _cCPFVend  := ""    // CPF
   _cEmailVen := ""    // Email
   _cNomeVend := ""    // Nome
   _cRGVend   := ""    // RG
   _cTelVend  := ""    // Telefone

   SA3->(DBSetOrder(1))
   If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND1))
      _cCPFVend  := AllTrim(SA3->A3_CGC)  // CPF
      _cEmailVen := AllTrim(SA3->A3_EMAIL)  // Email
      _cNomeVend := AllTrim(SA3->A3_NOME)  // Nome
      _cRGVend   := ""  // RG
      _cTelVend  := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
   EndIf

   //========================================================
   // Obtem dados do Coordenador
   //========================================================
   _cCodCoord := SC5->C5_VEND2  // Cod. Coordenador
   _cCPFCoord := ""    // CPF
   _cEmailCoo := ""    // Email
   _cNomeCoor := ""    // Nome
   _cRGCoord  := ""    // RG
   _cTelCoord := ""    // Telefone

   SA3->(DBSetOrder(1))
   If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND2))
      _cCPFCoord  := AllTrim(SA3->A3_CGC)    // CPF
      _cEmailCoo := AllTrim(SA3->A3_EMAIL)  // Email
      _cNomeCoor := AllTrim(SA3->A3_NOME)   // Nome
      _cRGCoord  := ""  // RG
      _cTelCoord := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
   EndIf

   //========================================================
   // Obtem dados do Gerente.
   //========================================================
   _cCodGeren  := SC5->C5_VEND3  // Cod. Gerente
   _cCPFGeren  := ""    // CPF
   _cEmailGer  := ""    // Email
   _cNomeGeren := ""    // Nome
   _cRGGeren   := ""    // RG
   _cTelGeren  := ""    // Telefone

   SA3->(DBSetOrder(1))
   If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND3))
      _cCPFGeren  := AllTrim(SA3->A3_CGC)  // CPF
      _cEmailGer := AllTrim(SA3->A3_EMAIL)  // Email
      _cNomeGeren := AllTrim(SA3->A3_NOME)  // Nome
      _cRGGeren   := ""  // RG
      _cTelGeren  := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
   EndIf

   //================================================================================
   // Define o tipo de carga do pedido
   //================================================================================
   _cIndIECli := ""
   _cTipoCA := "2"
   SA1->(DBSetOrder(1))
   If SA1->(DBSeek(xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI)))
      If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
         _cTipoCA := "1"  //chep
      Else
         _cTipoCA := "2" //estivada
      EndIf

      _cUFCli := SA1->A1_EST // Posicione("SA1",1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),"A1_EST")

      _cInscrCli := AllTrim(SA1->A1_INSCR)                      // InscricaoEstadual
      _cNomeFCli := AllTrim(SA1->A1_NREDUZ)                     // NomeFantasia
      _cRGIECl   := AllTrim(SA1->A1_RG)                         // RGIE
      _cRazaoCli := AllTrim(SA1->A1_NOME)                       // RazaoSocial
      _cTipoPCli := If(SA1->A1_PESSOA=="P","Fisica","Juridica") // TipoPessoa
      _cCEPCli   := AllTrim(SA1->A1_CEP)                        // CEP

      /*
      A1_CONTRIB = 1 = Sim = Contribuinte ICMS
           = 2 = Não = Não Contribuinte ICMS
      A1_INSCR   = ISENTO = Inscrição Estadual
      */

      If SA1->A1_CONTRIB == "1" .And. !Empty(SA1->A1_INSCR) .And. AllTrim(SA1->A1_INSCR) <> "ISENTO"
         _cIndIECli := "ContribuinteICMS"   // "1" //Contribuinte ICMS
      ElseIf SA2->A2_CONTRIB == "1"
         _cIndIECli := "ContribuinteIsento" // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
      Else
         _cIndIECli := "NaoContribuite"     // "9" //  Não Contribuinte que pode ou não ter inscição est.
      EndIf

   EndIf

   _coper50 := AllTrim(SuperGetMV('IT_CHEPCLS',.T.,'')) //Operação exclusiva para cliente Chep
   _coper51 := AllTrim(SuperGetMV('IT_CHEPCLN',.T.,'')) //Operação exclusiva para cliente não Chep

   If SC5->C5_I_OPER == _coper50 .Or. SC5->C5_I_OPER == _coper51 //pedido de pallet deve ser enviado como estivado

     _cTipoCA := "2"

   EndIf

   //================================================================================
   // Grava os dados do pedido de vendas para integração como WebService.
   //================================================================================
   _aCalcItens := U_AOMS084C(SC5->C5_FILIAL + SC5->C5_NUM)

   //_cUFCli := Posicione("SA1",1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),"A1_EST")

   If aScan(_aUF,{|x| x[1] == _cUFCli}) == 0

      _cUFCli := "EX"

   EndIf


   _nI := aScan(_aFilial,{|x| x[5] = SC5->C5_FILIAL})
   _cCnpj := _aFilial[_nI,18]
   SA2->(DBSetOrder(3))
   SA2->(DBSeek(xFilial("SA2")+_cCnpj))
   _cvend := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME")
   _coord := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NOME")
   _coord := IIf(Empty(_coord),_cvend,_coord)
   _nRegSA2 := SA2->(Recno())

   _cCepForn  := AllTrim(SA2->A2_CEP)                                                   // CEP
   _cInscEst  := AllTrim(SA2->A2_INSCR)                                                 // InscricaoEstadual
   _cNFantFor := AllTrim(SA2->A2_NREDUZ)                                                // NomeFantasia
   _cRgiForn  := ""                                                                     // RGIE
   _cRazaoFor := AllTrim(SA2->A2_NOME)                                                  // RazaoSocial
   _cTipoPFor := If(SA2->A2_TIPO=="P","Fisica","Juridica")                              // TipoPessoa
   _cCondPag  := AllTrim(Posicione('SE4',1,xFilial('SE4')+SC5->C5_CONDPAG,'E4_DESCRI')) // Condição de Pagamento
   _cCodForn  := SA2->A2_COD                                                            // Codigo Fornecedor
   _cLojaForn := SA2->A2_LOJA                                                           // Loja do Fornecedor

   /*
   A2_CONTRIB = 1 = Sim = Contribuinte ICMS
           = 2 = Não = Não Contribuinte ICMS
   A2_INSCR   = ISENTO = Inscrição Estadual
   */
   _cIndIEFor := ""
   If SA2->A2_CONTRIB == "1" .And. !Empty(SA2->A2_INSCR) .And. AllTrim(SA2->A2_INSCR) <> "ISENTO"
      _cIndIEFor := "ContribuinteICMS"   // "1" //Contribuinte ICMS
   ElseIf SA2->A2_CONTRIB == "1"
      _cIndIEFor := "ContribuinteIsento" // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
   Else
      _cIndIEFor := "NaoContribuite"     // "9" //  Não Contribuinte que pode ou não ter inscição est.
   EndIf

   //================================================================================
   // Os endereços de clientes abaixo estão com o nome da rua separada do numero,
   // e do complemento.
   //================================================================================
   _cEndereco    := SA2->A2_I_END
   _cNumero      := SA2->A2_I_NUM
   _cComplemento := SA2->A2_COMPLEM

   If Empty(_cEndereco)
      _cEndereco    := SA2->A2_END
      _cNumero      := U_AOMS084N(SA2->A2_END)
      _cComplemento := SA2->A2_COMPLEM
   EndIf

   ZFQ->(RecLock("ZFQ",.T.))  
   ZFQ->ZFQ_FILIAL := SC5->C5_FILIAL         // xFilial("ZFQ")   // Filial do Sistema
   ZFQ->ZFQ_DATA   := Date()    		         // Data de Emissão
   ZFQ->ZFQ_HORA   := Time()                 // Hora de inclusão na tabela de muro.
   ZFQ->ZFQ_CNPJEM := _cCnpj	               // CNPJ do Embarcador

   If ! Empty(_cSulfixo)
      ZFQ->ZFQ_PEDIDO := SC5->C5_NUM + "_" + _cSulfixo // Número do Pedido
   Else
      ZFQ->ZFQ_PEDIDO := SC5->C5_NUM  // Número do Pedido
   EndIf

   ZFQ->ZFQ_STATUS := '1'
   ZFQ->ZFQ_PEDID2 := SC5->C5_I_PEVIN    	   // Pedido Original
   ZFQ->ZFQ_CNPJFA := _cCnpj                 // CNPJ da Fábrica
   If ZFQ->(FIELDPOS("ZFQ_CODOPE")) > 0
      ZFQ->ZFQ_CODOPE := SC5->C5_I_OPER      // Codigo de Operação
   EndIf
   ZFQ->ZFQ_BAIRRO := SA2->A2_BAIRRO         // Bairro
   ZFQ->ZFQ_ENDERE := _cEndereco    // SA2->A2_END              // Endereço da Fábrica
   ZFQ->ZFQ_NUMERO := _cNumero      // U_AOMS084N(SA2->A2_END)  // Número do Endereço da Fábrica
   ZFQ->ZFQ_COMEND := _cComplemento // "000"                    // Complemento do Endereço
   ZFQ->ZFQ_IBGEFA := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)

   ZFQ->ZFQ_CNPJDE := Posicione("SA1",1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),"A1_CGC") // CNPJ do Destinatário
   ZFQ->ZFQ_ENDENT := SC5->C5_I_END  	         // Endereco de Entrega
   ZFQ->ZFQ_CEPENT := SC5->C5_I_CEP  	         // CEP de Entrega
   ZFQ->ZFQ_BAIENT := SC5->C5_I_BAIRR	         // Bairro de entrega
   ZFQ->ZFQ_NUMENT := U_AOMS084N(SC5->C5_I_END) //SC5->C5_I_MUN  	       // Número de Entrega
   ZFQ->ZFQ_IBGENT := _aUF[aScan(_aUF,{|x| x[1] == _cUFCli})][02] + SC5->C5_I_CMUN 	// Municipio de Entrega  (Código IBGE)
   ZFQ->ZFQ_DTEMIS := SC5->C5_EMISSAO	         // Data Emissão
   ZFQ->ZFQ_DTPREV := SC5->C5_I_DTENT	         // Data de Previsão de Entrega
   ZFQ->ZFQ_CAPROD := _aCalcItens[4]            //_cTipoCarga  // Caracteristica do Produto
    If SC5->C5_I_AGEND $ "A/M"                  // Data de Entrega Agendada
      ZFQ->ZFQ_DTAGEN := SC5->C5_I_DTENT
   Else
      ZFQ->ZFQ_DTAGEN := Ctod("  /  /  ")	     // Data de Entrega Agendada
   EndIf
   ZFQ->ZFQ_TIPEDI := AOMS084G()               //Define tipo de pedido, 1 normal, 2 pallet
   ZFQ->ZFQ_CNPJTR := ""	                   // CNPJ de Transferência
   ZFQ->ZFQ_ENDTRA := ""                       // Endereco de Transferência
   ZFQ->ZFQ_CEPTRA := ""                       // CEP de Transferência
   ZFQ->ZFQ_BAIRTR := ""                       // Bairro de Transferência
   ZFQ->ZFQ_NRTRAN := ""                       // Número de Transferência
   ZFQ->ZFQ_IBGETR := ""                       // Municipio de Transferência  (Código IBGE)
   ZFQ->ZFQ_REPRES := _cvend // SC5->C5_VEND1 // Representante
   ZFQ->ZFQ_COORDE := _coord // SC5->C5_VEND2 // Coordenador de Venda
   ZFQ->ZFQ_ASSIST := RETFIELD("SRA",1,SC5->C5_I_CDUSU,"SRA->RA_NOME") // SC5->C5_I_NOUSU	     // Assitente
   ZFQ->ZFQ_PESOPE := SC5->C5_I_PESBR	       // Peso Total do Pedido
   ZFQ->ZFQ_VLRPED := _aCalcItens[1]           // SOMAR C6_VALOR  	// Valor Total do Pedido

   If _cTipoCA == "2" // Enviar zeros no na qtd pallet capa e item. Trata-se de uma Carga Batida. Não há Pallets.
      ZFQ->ZFQ_QTDEPA := 0
   Else
      ZFQ->ZFQ_QTDEPA := _aCalcItens[2]           // SOMAR C6_I_QPALT	// Quantidade de Pallet´s
   EndIf

   ZFQ->ZFQ_VOLUME := Ceiling(_aCalcItens[3])  // SOMATÓRIA: C6_PRODUTO ==> b5_ecaltem X b5_ecprofe X b5_eclarge X C6_QTDVEN 	// Volume M³ Total do Pedido // //   Ceiling - esta função arredonda para cima em numeros inteiros, o valor passado como parâmetro.
   ZFQ->ZFQ_DATAAL := Date()
   ZFQ->ZFQ_SITUAC := If(Empty(_cSituacao),"N",_cSituacao)
   ZFQ->ZFQ_CODEMP := _cCodEmpWS
   ZFQ->ZFQ_COCHEP := Posicione("SA1",1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),"A1_I_CCHEP") // CNPJ do Destinatário
   ZFQ->ZFQ_TIPOPA := _cTipoCA
   If Type("__cUserId") = "C" .And. !Empty(__cUserId)
      ZFQ->ZFQ_USUARI := __cUserId
      ZFQ->ZFQ_USUALT := Posicione("ZZL",3,xFilial("ZZL")+__cUserId,"ZZL_RDCUSR")
   EndIf

   If ZFQ->(FIELDPOS("ZFQ_TPOPER")) > 0
      _cCanalVen := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_I_VBROK")
      If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N' // Transferência de Pedido de Vendas
         ZFQ->ZFQ_TPOPER := "TRANSF_UNID"
      ElseIf SC5->C5_I_TRCNF = 'S'
         ZFQ->ZFQ_TPOPER := "TROCA_NF"
      ElseIf !Empty(_cCanalVen) .And. _cCanalVen == "B"
         ZFQ->ZFQ_TPOPER := "BROKER"
      ElseIf SC5->C5_TPFRETE == "F" // FRETE = FOB  
         ZFQ->ZFQ_TPOPER := "FOB"
      Else // Venda Direta = Venda Normal
         ZFQ->ZFQ_TPOPER := "VD_DIR"
      EndIf
   EndIf

   //Ajuste  para frete Fob ser enviado como agenda F para o RDC
   If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N'
      ZFQ->ZFQ_TPAGEN	:=	"T"
   Else
      //c5_i_oper = '20' e c5_i_trcnf = 'N' tipo = 'T'
      If SC5->C5_TPFRETE == "F"
         ZFQ->ZFQ_TPAGEN := "F"
      Else
         ZFQ->ZFQ_TPAGEN	:=	SC5->C5_I_AGEND
      EndIf
   EndIf

   _cGrupoVen := Posicione("SA1",1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),"A1_GRPVEN")
   If ! Empty(_cGrupoVen)
      ZFQ->ZFQ_COREDE	:=	Posicione("ACY",1,xFilial("ACY")+_cGrupoVen,"ACY_DESCRI") // Ordem 1 - ACY_FILIAL+ACY_GRPVEN
   EndIf
   If ! Empty(SC5->C5_VEND3)
      ZFQ->ZFQ_GERENT	:= Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND3,"A3_NOME")
   EndIf
   ZFQ->ZFQ_SITPED	:=	U_STPEDIDO()             // Status do Pedido, rotina no xfunoms
   ZFQ->ZFQ_OBSCPA	:=	Alltrim(U_AOMS074X(SC5->C5_I_OBCOP))+IF(SC5->C5_CONDPAG='001'," A VISTA / PAG. ANTECIPADO",'')
   ZFQ->ZFQ_OBSPVE	:=	U_AOMS074X(SC5->C5_I_OBPED)
   ZFQ->ZFQ_OBSNFE	:=	U_AOMS074X(SC5->C5_MENNOTA)
   ZFQ->ZFQ_FILRDC   := Posicione("ZZM",1,xFilial("ZZM")+SC5->C5_FILIAL,"ZZM_FILRDC")

   //If AllTrim(ZFQ->ZFQ_FILRDC)  == "90"  // Solicitação do Vanderlei 
   //   ZFQ->ZFQ_FILRDC :=  "9001"
   //EndIf 

   If u_IT_TMS(SC5->C5_I_LOCEM)  /*_lWsTms*/ .Or. !Empty(_cSulfixo) // Sistema TMS MultiEmbarcador
      ZFQ->ZFQ_FLUXO := "PROTHEUS ENVIA TMS"  
   Else // Sistema RDC
      ZFQ->ZFQ_FLUXO := "PROTHEUS ENVIA RDC"  
   EndIf 

   ZFQ->ZFQ_REGCAP := ZFQ->(Recno())
   ZFQ->ZFQ_DATAI := Date()
   ZFQ->ZFQ_HORAI := Time()

   If ZFQ->(FIELDPOS("ZFQ_CODVEN")) > 0
      //--------------------------------------------------
      ZFQ->ZFQ_CODVEN := _cCodVend  // Codigo Vendedor
      ZFQ->ZFQ_CPFVEN := _cCPFVend  // CPF
      ZFQ->ZFQ_MAILVE := _cEmailVen // Email
      ZFQ->ZFQ_TELVEN := _cTelVend  // Telefone
      //--------------------
      ZFQ->ZFQ_CODGER := _cCodGeren // Cod. Gerente
      ZFQ->ZFQ_CPFGER := _cCPFGeren // CPF
      ZFQ->ZFQ_MAILGE := _cEmailGer // Email
      ZFQ->ZFQ_TELGER := _cTelGeren // Telefone
      //--------------------
      ZFQ->ZFQ_CODCOO := _cCodCoord // Cod. Coordenador
      ZFQ->ZFQ_CPFCOO := _cCPFCoord // CPF
      ZFQ->ZFQ_MAILCO := _cEmailCoo // Email
      ZFQ->ZFQ_TELCOO := _cTelCoord // Telefone
      //--------------------
      ZFQ->ZFQ_RAZFOR := _cRazaoFor // Razão Social Fornecedor
      ZFQ->ZFQ_FANFOR := _cNFantFor // Nome Fantasia Fornecedor
      ZFQ->ZFQ_CEPFOR := _cCepForn  // CEP Fornecedor
      ZFQ->ZFQ_INSFOR := _cInscEst  // Inscrição Estadual Fornecedor
      ZFQ->ZFQ_TIPPEF := _cTipoPFor // Tipo de Pessoa Fornecedor

      ZFQ->ZFQ_LOJFOR := _cLojaForn  // Loja do Fornecedor
      ZFQ->ZFQ_CODFOR := _cCodForn   // Codigo Fornecedor
      ZFQ->ZFQ_INDIEF := _cIndIEFor

      ZFQ->ZFQ_RAZCLI := _cRazaoCli // Razão Social Cliente
      ZFQ->ZFQ_FANCLI := _cNomeFCli // Nome Fantasia Cliente
      ZFQ->ZFQ_CEPCLI := _cCEPCli   // CEP Cliente
      ZFQ->ZFQ_INSCLI := _cInscrCli // Inscrição Estadual Cliente
      ZFQ->ZFQ_TIPPEC := _cTipoPCli // Tipo Pessoa Cliente
      ZFQ->ZFQ_INDIEC := _cIndIECli

      _cCanalVen := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_I_VBROK")
      If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N' // Transferência de Pedido de Vendas
         ZFQ->ZFQ_TPOPER := "TRANSF_UNID"
      ElseIf SC5->C5_I_TRCNF = 'S'
         ZFQ->ZFQ_TPOPER := "TROCA_NF"
      ElseIf !Empty(_cCanalVen) .And. _cCanalVen == "B"
         ZFQ->ZFQ_TPOPER := "BROKER"
      ElseIf SC5->C5_TPFRETE == "F" // FRETE = FOB
         ZFQ->ZFQ_TPOPER := "FOB"
      Else // Venda Direta = Venda Normal
         ZFQ->ZFQ_TPOPER := "VD_DIR"
      EndIf

      //Ajuste  para frete Fob ser enviado como agenda F para o RDC
      If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N'         // Utilizar estas regras no tipo de operação.
         ZFQ->ZFQ_TPAGEN	:=	"T"
      Else
         //c5_i_oper = '20' e c5_i_trcnf = 'N' tipo = 'T'
         If SC5->C5_TPFRETE == "F"
            ZFQ->ZFQ_TPAGEN := "F"
         Else
            ZFQ->ZFQ_TPAGEN	:=	SC5->C5_I_AGEND
         EndIf
      EndIf
   EndIf

   ZFQ->(MSUnLock())

   _nQtd      := 0
   _cUnidade  := 0
   _nPesoUnit := 0
   _nPesoTot  := 0
   _nPrecoVenda := 0

   _cForEmbM  := ""
   _cLojaEmbM := ""
   _cFilRDC   := ""
   _cPedCliente := ""

   ZG9->(DBSetOrder(1)) // ZG9_FILIAL+ZG9_CODFIL+ZG9_ARMAZE
   SB1->(DBSetOrder(1)) // B1_FILIAL+B1_COD
   SB5->(DBSetOrder(1)) // B5_FILIAL+B5_COD
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
      _lSeekSB5 := .F.
      If SB5->(DBSeek(xFilial("SB5")+SC6->C6_PRODUTO))
         _lSeekSB5 := .T.
      EndIf
      SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))

      _nvolume := (SB5->B5_ECALTEM * SB5->B5_ECPROFE * SB5->B5_ECLARGE * SC6->C6_QTDVEN)
      _nvolume := IIf(_nvolume>0,_nvolume,1)


      _ncubado := (Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_PESBRU")*SC6->C6_QTDVEN)


      _ncubado := IIf(_ncubado>0,_ncubado,1)

      _nqpalets := SC6->C6_I_QPALT

      _nqpalets := IIf(_nqpalets>99,99,_nqpalets)

      _nPesoTot  := SB1->B1_PESBRU * SC6->C6_QTDVEN
      _nPrecoVenda := SC6->C6_PRCVEN

      _nFatConvPa := 0   // Fator de Conversão de Pallets.
      _nQtdPecas := 0

      If SC6->C6_UNSVEN == 0 // Não há segunda unidade de medida
         _nQtd      := SC6->C6_QTDVEN
         _cUnidade  := "2" // Unidade de Medida // "1 - Caixa(2a. unidade) e 2 - Unidade (1a.unidade)"
         _nPesoUnit := SB1->B1_PESBRU
         _nPrecoVenda := SC6->C6_PRCVEN

         If SB1->B1_I_UMPAL == "1"
            _nFatConvPa := SB1->B1_I_CXPAL
         Else
            _nFatConvPa := 0
        EndIf

      Else

         If SB1->B1_I_UMPAL == "2"
            _nFatConvPa := SB1->B1_I_CXPAL
         Else
            If SB1->B1_I_UMPAL == "1"
               _nFatConvPa := SB1->B1_I_CXPAL
            Else
               _nFatConvPa := 0
           EndIf
         EndIf

         If SC6->C6_UM == "KG" .And. SB1->B1_I_PCCX <> 0
            _nQtdPecas := SC6->C6_UNSVEN
            _cUnidade  := "3"
            _nQtd      := SC6->C6_QTDVEN
         Else
            _nQtd      := SC6->C6_UNSVEN
            _cUnidade  := "1" // Unidade de Medida // "1 - Caixa(2a. unidade) , 2 - Unidade (1a.unidade) e 3 - Quilos"
         EndIf

         _nconv := IIf(SB1->B1_CONV==0,1,SB1->B1_CONV)

         If SB1->B1_TIPCONV == "D" // TIPO DE CONVERSAO DIVISÃO
             _nPesoUnit := SB1->B1_PESBRU * _nconv
             _nPrecoVenda := SC6->C6_PRCVEN * _nconv
         Else
            _nPesoUnit := SB1->B1_PESBRU / _nconv
            _nPrecoVenda := SC6->C6_PRCVEN / _nconv
         EndIf
      EndIf

      ZFR->(RecLock("ZFR",.T.))
      ZFR->ZFR_FILIAL	:= SC6->C6_FILIAL           // Filial do Sistema
      ZFR->ZFR_DATA	    := Date()	                //	Data de Emissão
      ZFR->ZFR_HORA     := Time()                   //   Hora de inclusão na tabela de muro.

      If ! Empty(_cSulfixo)
         ZFR->ZFR_NUMPED	:= SC6->C6_NUM + "_" + _cSulfixo  //	Numero Pedido de Vendas
      Else
         ZFR->ZFR_NUMPED	:= SC6->C6_NUM //	Numero Pedido de Vendas
      EndIf

      ZFR->ZFR_ITEM	   := SC6->C6_ITEM   	       //	Numero do Item
      ZFR->ZFR_CODIGO	:= AllTrim(SC6->C6_PRODUTO) + Right(_cCnpj,6)	//	Código do Produto
      ZFR->ZFR_QTDEPR	:= _nQtd                    // SC6->C6_QTDVEN 	       //	Quantidade do Produto
      ZFR->ZFR_QTDPEC   := _nQtdPecas               // Quantidade de peças  para UM = KG
      ZFR->ZFR_UNMED	   := _cUnidade                // If(SC6->C6_UM == "CX","1","2") // Unidade de Medida // "1 - Caixa e 2 - Unidade"
      ZFR->ZFR_NATOPE	:= AllTrim(SC6->C6_CF)	    //	Natureza de Operação
      ZFR->ZFR_PESOUN	:= _nPesoUnit               // SB1->B1_PESBRU	       //	Peso Unitário do Produto
      ZFR->ZFR_VOLUME	:= Ceiling(_nvolume)        //   Ceiling - esta função arredonda para cima em numeros inteiros, o valor passado como parâmetro.
      ZFR->ZFR_VLRPRO	:= _nPrecoVenda             //SC6->C6_PRCVEN 	       //	Valor Unitário do Produto

      If _cTipoCA == "2"                            // Enviar zeros no na qtd pallet capa e item. Trata-se de uma Carga Batida. Não há Pallets.
         ZFR->ZFR_QTDEPA := 0
      Else
         ZFR->ZFR_QTDEPA := _nqpalets               //	Quantidade de Pallet´s
      EndIf

      ZFR->ZFR_CUBADO	:= _ncubado
      ZFR->ZFR_PESOBR	:= _nPesoTot                // SB1->B1_PESBRU * SC6->C6_QTDVEN 	//	Peso Bruto
      ZFR->ZFR_USUARI	:= __cUserId			       // Codigo do Usuário
      ZFR->ZFR_DATAAL	:= Date()			          // Data de Alteração
      ZFR->ZFR_SITUAC	:= If(Empty(_cSituacao),"N",_cSituacao)//AWF-11/05/17 - Mudei para "N"		           // Situação do Registro = Aguardando Liberação
      ZFR->ZFR_CODARM   := SC6->C6_Local            // Codigo do Armazem.
      ZFR->ZFR_CODEMP	:= _cCodEmpWS			       // Codigo Empresa WebServer
      ZFR->ZFR_FLUXO    := "PROTHEUS ENVIA RDC"
      ZFR->ZFR_FATOPA   := _nFatConvPa              // Fator de convesão de Pallets.
      ZFR->ZFR_REGCAP   := ZFQ->(Recno())

      If ZFR->(FIELDPOS("ZFR_DSCPRD")) > 0
         //-------------------
         ZFR->ZFR_DSCPRD:= SB1->B1_DESC
         ZFR->ZFR_GRPPRD:= SB1->B1_GRUPO
         ZFR->ZFR_DSCGRP:= AllTrim(Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"))
         ZFR->ZFR_SEGUNI:= SC6->C6_SEGUM
         ZFR->ZFR_QTDSGU:= SC6->C6_UNSVEN
         ZFR->ZFR_QTDPAL:= SB1->B1_I_CXPAL
      EndIf

      ZFR->(MSUnLock())

      //==================================================================================
      // Este trecho verifica se há endereço de embarcador para este pedido de vendas.
      //==================================================================================

      If Empty(_cForEmbM)
         If ZG9->(DBSeek(xFilial("ZG9")+SC6->C6_FILIAL+SC6->C6_LOCAL))
            _cForEmbM  := ZG9->ZG9_CODFOR
            _cLojaEmbM := ZG9->ZG9_LOJFOR
            _cFilRDC   := ZG9->ZG9_FILRDC
         EndIf
      EndIf
      If Empty(_cPedCliente) .And. !Empty(AllTrim(SC6->C6_NUMPCOM))
         _cPedCliente := AllTrim(SC6->C6_NUMPCOM)
      EndIf


      SC6->(DBSkip())
   EndDo

   //==================================================================================
   // Há endereço de embarcador para este item, então, o endereço da filial de origem
   // deve ser alterado para o endereço do embarcador de mercadorias.
   //==================================================================================
   If !Empty(_cForEmbM) .And. !u_IT_TMS(SC5->C5_I_LOCEM) /*! _lWsTms*/ .And. Empty(_cSulfixo) // _lWsTms = .F. = TMS RDC
      //================================================================================
      // Os endereços de clientes abaixo estão com o nome da rua separada do numero,
      // e do complemento.
      //================================================================================
      _cEndereco    := ""
      _cNumero      := ""
      _cComplemento := ""
      _cIBGEFA      := ""
      _cBairro      := ""

      SA2->(DBSetOrder(1))
      If SA2->(DBSeek(xFilial("SA2")+_cForEmbM+_cLojaEmbM)) // Posiciona no embarcador das mercadorias
         _cEndereco    := SA2->A2_I_END
         _cNumero      := SA2->A2_I_NUM
         _cComplemento := SA2->A2_COMPLEM
         _cIBGEFA      := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)
         _cBairro      := SA2->A2_BAIRRO

         If Empty(_cEndereco)
            _cEndereco    := SA2->A2_END
            _cNumero      := U_AOMS084N(SA2->A2_END)
            _cComplemento := SA2->A2_COMPLEM
            _cIBGEFA      := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)
            _cBairro      := SA2->A2_BAIRRO
         EndIf
      EndIf

      ZFQ->(RecLock("ZFQ",.F.))
      ZFQ->ZFQ_BAIRRO := _cBairro       // SA2->A2_BAIRRO           // Bairro
      ZFQ->ZFQ_ENDERE := _cEndereco     // SA2->A2_END              // Endereço da Fábrica
      ZFQ->ZFQ_NUMERO := _cNumero       // U_AOMS084N(SA2->A2_END)  // Número do Endereço da Fábrica
      ZFQ->ZFQ_COMEND := _cComplemento  // "000"                    // Complemento do Endereço
      ZFQ->ZFQ_IBGEFA := _cIBGEFA       // _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)
      If ! Empty(_cFilRDC)
         ZFQ->ZFQ_FILRDC := _cFilRDC
      EndIf

      //If AllTrim(ZFQ->ZFQ_FILRDC)  == "90"  // Solicitação do Vanderlei 
      //   ZFQ->ZFQ_FILRDC :=  "9001"
      //EndIf 

      ZFQ->(MSUnLock())

   Else // _lWsTms = .T. = TMS MULTI EMBARCADOR DA MULTI SOFTWARE
      _cCNPJEX := "" // CNPJ do Expedidor
      _cCEPEXP := "" // Cep do Expedidor
      _cIBGEEX := "" // Municpio da Expedidor (Código IBGE)
      _cINSEXP := "" // Inscrição Estadual Expedidor
      _cENDEXP := "" // Endereço do Expedidor
      _cNUMEXP := "" // Número do Endereço do Expedidor
      _cFANEXP := "" // Nome Fantasia Expedidor
      _cRAZEXP := "" // Razação Social Expedidor
      _cTIPPEX := "" // Tipo Pessoa Expedidor

      If ! Empty(_cForEmbM)
         SA2->(DBSetOrder(1))
         If SA2->(DBSeek(xFilial("SA2")+_cForEmbM+_cLojaEmbM)) // Posiciona no embarcador das mercadorias
            _cCNPJEX := SA2->A2_CGC     // CNPJ do Expedidor
            _cCEPEXP := SA2->A2_CEP     // Cep do Expedidor
            _cIBGEEX := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)                                            // Municpio da Expedidor (Código IBGE)
            _cINSEXP := SA2->A2_INSCR   // Inscrição Estadual Expedidor
            _cENDEXP := SA2->A2_I_END   // Endereço do Expedidor
            _cNUMEXP := SA2->A2_I_NUM   // Número do Endereço do Expedidor
            _cFANEXP := SA2->A2_NREDUZ  // Nome Fantasia Expedidor
            _cRAZEXP := SA2->A2_NOME    // Razação Social Expedidor
            _cTIPPEX := If(SA2->A2_TIPO=="P","Fisica","Juridica") // TipoPessoa

            If Empty(_cENDEXP)
               _cENDEXP := SA2->A2_END             // Endereço do Expedidor
               _cNUMEXP := U_AOMS084N(SA2->A2_END) // Número do Endereço do Expedidor
               _cIBGEEX      := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)
            EndIf
            //--------------------------------------------
            /*
            A2_CONTRIB = 1 = Sim = Contribuinte ICMS
                       = 2 = Não = Não Contribuinte ICMS
            A2_INSCR   = ISENTO = Inscrição Estadual
            */
            _cIndIEExp := ""
            If SA2->A2_CONTRIB == "1" .And. !Empty(SA2->A2_INSCR) .And. AllTrim(SA2->A2_INSCR) <> "ISENTO"
               _cIndIEExp := "ContribuinteICMS"    // "1" //Contribuinte ICMS
            ElseIf SA2->A2_CONTRIB == "1"
               _cIndIEExp := "ContribuinteIsento"  // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
            Else
               _cIndIEExp := "NaoContribuite"      // "9" //  Não Contribuinte que pode ou não ter inscição est.
            EndIf
//----------------------------------------------
            ZFQ->(RecLock("ZFQ",.F.))
            ZFQ->ZFQ_CNPJEX := _cCNPJEX  // CNPJ do Expedidor
            ZFQ->ZFQ_CEPEXP := _cCEPEXP  // Cep do Expedidor
            ZFQ->ZFQ_IBGEEX := _cIBGEEX  // Municpio da Expedidor (Código IBGE)
            ZFQ->ZFQ_INSEXP := _cINSEXP  // Inscrição Estadual Expedidor
            ZFQ->ZFQ_ENDEXP := _cENDEXP  // Endereço do Expedidor
            ZFQ->ZFQ_NUMEXP := _cNUMEXP  // Número do Endereço do Expedidor
            ZFQ->ZFQ_FANEXP := _cFANEXP  // Nome Fantasia Expedidor
            ZFQ->ZFQ_RAZEXP := _cRAZEXP  // Razação Social Expedidor
            ZFQ->ZFQ_TIPPEX := _cTIPPEX  // Tipo Pessoa Expedidor
            //------------------------------
            ZFQ->ZFQ_INDIEE := _cIndIEExp
            //------------------------------
            If ! Empty(_cFilRDC)
               ZFQ->ZFQ_FILRDC := _cFilRDC
            EndIf

            //If AllTrim(ZFQ->ZFQ_FILRDC) == "90"  // Solicitação do Vanderlei 
            //   ZFQ->ZFQ_FILRDC :=  "9001"
            //EndIf 

            ZFQ->(MSUnLock())
         EndIf
         SA2->(DBSetOrder(3))


      EndIf
   EndIf

   If ZFR->(FIELDPOS("ZFQ_NUMPCO")) > 0 .And. !Empty(_cPedCliente)
      ZFQ->(RecLock("ZFQ",.F.))
      ZFQ->ZFQ_NUMPCO := _cPedCliente
      ZFQ->(MSUnLock())
   EndIf
End Sequence

RestOrd(_aOrd)
SC6->(DBGoTo(_nRegSC6))

Return

/*
===============================================================================================================================
Função------------: AOMS084C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Efetua a leitura de todos os itens do pedido de vendas e efetua os seguintes cálculos relacionados ao
                    pedido de vendas:
                    1) Somatória do campo:  C6_VALOR
                    2) Somatória do campo:  C6_I_QPALT
                    3) Somatória do volume: C6_PRODUTO ==> b5_ecaltem X b5_ecprofe X b5_eclarge X C6_QTDVEN

Parametros--------: _cCodPesq = Filial + numero do pedido de vendas
Retorno-----------: _aResult = Array com o resultado de todos os calaculos realizados pela funçõa.
                    _aResult[1] = Somatória do Valor Total do Item
                    _aResult[2] = Somatória da Quantidade de Pallet
                    _aResult[3] = Somatória do Volume
                    _aResult[4] = Tipo de Carga (Seca, Refrigerada ou Não Definida)
===============================================================================================================================
*/
User Function AOMS084C(_cCodPesq)
Local _aRet := {}
Local _aOrd := SaveOrd({"SC6","SB5"})
Local _nSomaTot, _nSomaQPalet, _nSomaVolume
Local _lCargaRefrig, _cCarga
Local _cFilRDC := "", _cCodFil

Begin Sequence
   _nSomaTot     := 0
   _nSomaQPalet  := 0
   _nSomaVolume  := 0
   _cTipoCarga   := ""
   _lCargaRefrig := .F.
   _cCarga       := "1" // Não definido

   _cCodFil := SubStr(_cCodPesq,1,2)

   //=============================================================
   // Obtem o código da filial RDC
   //=============================================================
   _cFilRDC := Space(2)

   ZG9->(DBSetOrder(1)) // ZG9_FILIAL+ZG9_CODFIL+ZG9_ARMAZE
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(_cCodPesq))
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cCodPesq

      If ZG9->(DBSeek(xFilial("ZG9")+SC6->C6_FILIAL+SC6->C6_LOCAL))
         _cFilRDC := ZG9->ZG9_FILRDC
         Exit
      EndIf

      SC6->(DBSkip())
   EndDo

   If Empty(_cFilRDC)
      _cFilRDC := Posicione("ZZM",1,xFilial("ZZM")+_cCodFil,"ZZM_FILRDC")
   EndIf

   //=============================================================
   // Obtem os valores dos itens de pedidos.
   //=============================================================

   SB5->(DBSetOrder(1)) // B5_FILIAL+B5_COD
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(_cCodPesq))
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cCodPesq
      _nSomaTot    += SC6->C6_VALOR
      _nSomaQPalet += SC6->C6_I_QPALT

      If SB5->(DBSeek(xFilial("SB5")+SC6->C6_PRODUTO))
         _nSomaVolume += (SB5->B5_ECALTEM * SB5->B5_ECPROFE * SB5->B5_ECLARGE * SC6->C6_QTDVEN)
      EndIf

      _cTipoCarga := Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPCAR")

      If _cTipoCarga == "000001"
         If ! _lCargaRefrig
            If AllTrim(_cFilRDC) == "9001"  // CD-SP
               _cCarga := "5" // Carga Seca
            Else  // Demais filiais
               _cCarga := "1" // Carga Seca
            EndIf
         EndIf
      ElseIf _cTipoCarga == "000002"
         If AllTrim(_cFilRDC) == "9001"  // CD-SP
            _cCarga := "6"    // Carga Refrigerada
         Else  // Demais filiais
            _cCarga := "2"    // Carga Refrigerada
         EndIf
         _lCargaRefrig := .T.
      EndIf

      SC6->(DBSkip())
   EndDo

   If _nSomaQpalet > 99

     _nsomaQpalet := 99

   ElseIf _nSomaQpalet < 1

     _nsomaqpalet := 1

   EndIf

   _aRet := {_nSomaTot, _nSomaQPalet, IIf(_nSomaVolume>0,_nSomaVolume,1), _cCarga}

End Sequence

RestOrd(_aOrd, .T.)

Return _aRet

/*
=================================================================================================================================
Programa--------: AOMS084V()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/10/2016
Descrição-------: Exibe os dados do Pedido de Vendas posicionado na tela do MsBrowse.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS084V()
Local _aStrucZFR
Local _aCmpZFR := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInvZFR := .F.
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2

Private _oMarkZFR, _cMarcaZFR := GetMark()
Private aHeader := {} , aCols := {}

Begin Sequence

   //Montagem do aheader
   //=============================================================================
   aHeader := {}
   FillGetDados(1,"ZFR",1,,,{||.T.},,,,,,.T.)

   //                          1                    2               3              4               5                6             7        8              9                 10
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFR := {}
   //aAdd(_aStrucZFR,{"WKRECNO", "N", 10,0})
   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2])=="ZFR_FILIAL"
          Loop
       EndIf

       //                     Campo                 Titulo           Picture
       aAdd( _aCmpZFR , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )

       aAdd(_aStrucZFR,{aHeader[_nI,2], aHeader[_nI,8], aHeader[_nI,4] ,aHeader[_nI,5]})
   Next

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZFR") > 0
      TRBZFR->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZFR criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFR",  _aStrucZFR )

   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFR_ITEM"} )
   _otemp:Create()

   //================================================================================
   // Carrega os dados da tabela ZFQ
   //================================================================================
   For _nI := 1 To ZFQ->(FCount())
       &("M->"+ZFQ->(FieldName(_nI))) :=  &("ZFQ->"+ZFQ->(FieldName(_nI)))
   Next

   //================================================================================
   // Carrega os dados da tabela ZFR
   //================================================================================
   ZFR->(DBSetOrder(5))  // ZFR_FILIAL+ZFR_NUMPED+ZFR_SITUAC
   ZFR->(DBSeek(ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)))
   While ! ZFR->(Eof()) .And. ZFR->(ZFR_FILIAL+ZFR_NUMPED) == ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)
      If ZFR->ZFR_REGCAP <> ZFQ->ZFQ_REGCAP
         ZFR->(DBSkip())
         Loop
      EndIf

      TRBZFR->(RecLock("TRBZFR",.T.))
      For _nI := 1 To TRBZFR->(FCount())
          If AllTrim(TRBZFR->(FieldName(_nI))) == "ZFR_ALI_WT"
             TRBZFR->ZFR_ALI_WT := "ZFR"
          ElseIf AllTrim(TRBZFR->(FieldName(_nI))) == "ZFR_REC_WT"
             TRBZFR->ZFR_REC_WT := ZFR->(Recno())
          Else
             &("TRBZFR->"+TRBZFR->(FieldName(_nI))) :=  &("ZFR->"+TRBZFR->(FieldName(_nI)))
          EndIf
      Next
      TRBZFR->(MSUnLock())

      ZFR->(DBSkip())
   EndDo
   TRBZFR->(DBGoTop())

   //================================================================================
   // Monta a tela Enchoice ZFQ  x MsSelect ZFR
   //================================================================================
   _aObjects := {}
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. )

   _bOk := {|| _oDlgEnch:End()}
   _bCancel := {|| _lRet := .F., _oDlgEnch:End()}

   _cTitulo := "Integração de Pedido de Vendas Via WebService - Visualização"

   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel

      EnChoice( "ZFQ" ,_nReg, _nOpcx, , , , , _aPosObj[1], , 3 )

      _oMarkZFR := MsSelect():New("TRBZFR","","",_aCmpZFR,@_lInvZFR, @_cMarcaZFR,{_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4]})

   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel)

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================
If Select("TRBZFR") > 0
   TRBZFR->(DBCloseArea())
EndIf

Return

/*
=================================================================================================================================
Programa--------: AOMS084A()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/10/2016
Descrição-------: Rotina de aprovação de pedidos de vendas que poderão ser integrados via webservice.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS084A()
Local _cTitulo
Local _bOk, _bCancel
Local _oDlgApr
Local _lRet := .T.
Local _nTamPedido := TamSX3("C5_NUM")[1]

Private _dDtIni := Ctod("  /  /  "), _dDtFinal := Ctod("  /  /  ")
Private _cNrPedIni := Space(_nTamPedido)
Private _cNrPedFim := Space(_nTamPedido)

Begin Sequence
   //================================================================================
   // Tela de Aprovação de Pedido de Vendas
   //================================================================================
   _cTitulo := "Aprovação dos Pedidos de Vendas para Integração via WebService"
   _bOk := {|| If(U_AOMS084S("BOTAOOK"),(_lRet := .T., _oDlgApr:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgApr:End()}

   Define MsDialog _oDlgApr Title _cTitulo From 9,0 To 22,55 Of oMainWnd

      @ 06,20 Say "Data Prev. Entrega Incial: " Of _oDlgApr Pixel
      @ 05,80 Get _dDtIni Size 30, 10 Of _oDlgApr Pixel

      @ 26,20 Say "Data Prev. Entrega Final: " Of _oDlgApr Pixel
      @ 25,80 Get _dDtFinal Size 30, 10 Of _oDlgApr Valid(U_AOMS084S("DATAFINAL")) Pixel

      @ 46,20 Say "Nr.Pedido Incial: " Of _oDlgApr Pixel
      @ 45,80 Get _cNrPedIni Size 30, 10 Of _oDlgApr Pixel

      @ 66,20 Say "Nr.Pedido Final: " Of _oDlgApr Pixel
      @ 65,80 Get _cNrPedFim Size 30, 10 Of _oDlgApr Valid(U_AOMS084S("NR_PEDIDO")) Pixel

   Activate MsDialog _oDlgApr On Init EnchoiceBar(_oDlgApr,_bOk,_bCancel) CENTERED

   //================================================================================
   // Altera a situação dos dados dos pedidos de vendas das tabelas de muro, de
   // "Aguardando Aprovação" para "Não Processados".
   //================================================================================
   If _lRet
       FWMsgRun(, {|oproc| U_AOMS084R(oproc) } , 'Aguarde!' , 'Alterando Registro para Situação "Não Processados"...' )
   EndIf

End Sequence

Return

/*
=================================================================================================================================
Programa--------: AOMS084S()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/10/2016
Descrição-------: Valida a digitação das Datas, na rotina de mudança da Situação do Pedido de Vendas de "Aguardando Aprovação"
                  Para "Não Processados".
Parametros------: _cChamada = Variável ou botão que chamou a validação.
Retorno---------: .T. ou .F.
=================================================================================================================================
*/
User Function AOMS084S(_cChamada)
Local _lRet := .T.
Local _nI, _aUF := {}

Begin Sequence
   If _cChamada == "BOTAOOK"
      If Empty(_dDtIni) .Or. Empty(_dDtFinal)
         MsgStop("Informe um período de datas.","Atenção")
         _lRet := .F.
         Break
      EndIf

      If _dDtIni > _dDtFinal
         MsgStop("A data inicial não pode ser maior que a data final.","Atenção")
         _lRet := .F.
         Break
      EndIf

      If _cNrPedIni > _cNrPedFim
         MsgStop("O numero de pedido de vendas inicial não pode ser maior que o numero de pdidos de vendas final.","Atenção")
         _lRet := .F.
         Break
      EndIf
   EndIf

   If _cChamada == "DATAFINAL"
      If _dDtIni > _dDtFinal
         MsgStop("A data inicial não pode ser maior que a data final.","Atenção")
         _lRet := .F.
         Break
      EndIf
   EndIf

   If _cChamada == "NR_PEDIDO"
      If _cNrPedIni > _cNrPedFim
         MsgStop("O numero de pedido de vendas inicial não pode ser maior que o numero de pdidos de vendas final.","Atenção")
         _lRet := .F.
         Break
      EndIf
   EndIf

   If _cChamada == "UF_CLIENTE"
      If ! Empty(MV_PAR07)
         MV_PAR07 := Upper(MV_PAR07)
         aAdd(_aUF,"RO")
         aAdd(_aUF,"AC")
         aAdd(_aUF,"AM")
         aAdd(_aUF,"RR")
         aAdd(_aUF,"PA")
         aAdd(_aUF,"AP")
         aAdd(_aUF,"TO")
         aAdd(_aUF,"MA")
         aAdd(_aUF,"PI")
         aAdd(_aUF,"CE")
         aAdd(_aUF,"RN")
         aAdd(_aUF,"PB")
         aAdd(_aUF,"PE")
         aAdd(_aUF,"AL")
         aAdd(_aUF,"MG")
         aAdd(_aUF,"ES")
         aAdd(_aUF,"RJ")
         aAdd(_aUF,"SP")
         aAdd(_aUF,"PR")
         aAdd(_aUF,"SC")
         aAdd(_aUF,"RS")
         aAdd(_aUF,"MS")
         aAdd(_aUF,"MT")
         aAdd(_aUF,"GO")
         aAdd(_aUF,"DF")
         aAdd(_aUF,"SE")
         aAdd(_aUF,"BA")
         aAdd(_aUF,"EX")

         _nI := aScan(_aUF,MV_PAR07)

         If _nI == 0
            MsgStop("Sigla de estado inválida. Informe uma sigla de estado válida.","Atenção")
            _lRet := .F.
         EndIf
      EndIf
   EndIf

   If _cChamada == "PESO_FINAL"
      If ! Empty(MV_PAR08) .And. MV_PAR08 > MV_PAR09
         MsgStop("O peso inicial não pode ser maior que o peso final.","Atenção")
         _lRet := .F.
      EndIf
   EndIf

End Sequence

Return _lRet

/*
=================================================================================================================================
Programa--------: AOMS084R()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/10/2016
Descrição-------: Altera a situação dos dados dos pedidos de vendas das tabelas de muro, de "Aguardando Aprovação"
                  para "Não Processados".
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS084R(oproc)
Local _cQry, _nTotRegs
Local _aOrd := SaveOrd({"ZFR","ZFQ"})
Local _aItensZFR, _nI
Default oproc := nil

Begin Sequence
   _cQry := " SELECT R_E_C_N_O_ AS NRRECNO FROM "+RetSqlName("ZFQ")+" ZFQ "
   _cQry += " WHERE ZFQ.D_E_L_E_T_ = ' ' AND ZFQ_SITUAC = 'A' "
   _cQry += " AND ZFQ_FILIAL = '" + xFilial("ZFQ") + "' "
   _cQry += " AND ZFQ_DTPREV >= '"+DToS(_dDtIni)+"' AND ZFQ_DTPREV <= '"+DToS(_dDtFinal)+"' "

   If ! Empty(_cNrPedIni)
      _cQry += " AND ZFQ_PEDIDO >= '"+_cNrPedIni+"' "
   EndIf

   If ! Empty(_cNrPedFim)
      _cQry += " AND ZFQ_PEDIDO <= '"+_cNrPedFim+"' "
   EndIf

   If Select("TRBZFQ") > 0
      TRBZFQ->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "TRBZFQ")
   DBSelectArea("TRBZFQ")

   Count To _nTotRegs

   If _nTotRegs == 0
      U_ITMsg("Nenhum registro foi encontrado para o período informado.","Atenção",,1)
      Break
   EndIf

   TRBZFQ->(DBGoTop())

   ZFR->(DBSetOrder(5))

   While ! TRBZFQ->(Eof())
      ZFQ->(DBGoTo(TRBZFQ->NRRECNO))

      If ValType(oproc) = "O"

           oproc:cCaption := ("Processando Pedido: "+ZFQ->ZFQ_PEDIDO)
           ProcessMessages()

        EndIf

      ZFQ->(RecLock("ZFQ",.F.))
      ZFQ->ZFQ_SITUAC := "N"
      ZFQ->ZFQ_DATAP := Date()
      ZFQ->ZFQ_HORAP := Time()
      ZFQ->(MSUnLock())

      _aItensZFR := {}

      ZFR->(DBSeek(xFilial("ZFR")+ZFQ->ZFQ_PEDIDO+"A"))
      While ! ZFR->(Eof()) .And. ZFR->(ZFR_FILIAL+ZFR_NUMPED+ZFR_SITUAC) == ZFQ->ZFQ_FILIAL+ZFQ->ZFQ_PEDIDO+"A" //xFilial("ZFR")+ZFQ->ZFQ_PEDIDO+"A"
         aAdd(_aItensZFR,ZFR->(Recno()))

         ZFR->(DBSkip())
      EndDo

      For _nI := 1 To Len(_aItensZFR)
          ZFR->(DBGoTo(_aItensZFR[_nI]))

          ZFR->(RecLock("ZFR",.F.))
          ZFR->ZFR_SITUAC := "N"
          ZFR->(MSUnLock())
      Next

      TRBZFQ->(DBSkip())
   EndDo

End Sequence

If Select("TRBZFQ") > 0
   TRBZFQ->(DBCloseArea())
EndIf

RestOrd(_aOrd,.T.) // Volta a ordem os indices das tabelas para ordem anterior e volta os ponteiros de registros das tabelas

Return

/*
=================================================================================================================================
Programa--------: AOMS084B()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 31/10/2016
Descrição-------: Rotina de solicitação de retorno do Pedido integrado para o Sistema RDC(Cancela Pedido).
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS084B()
Local _cTexto := ""

Begin Sequence

   _cTexto := "Confirma a solicitação de retorno do pedido de vendas ["+AllTrim(SC5->C5_NUM)+"], que foi integrado ao sistema TMS Multi Embarcador?"

   If ! U_ITMsg(_cTexto,"Atenção",,3,2,2)
      Break
   EndIf

   _cTexto := "Este pedido não se encontra integrado ao sistema TMS !"

   If SC5->C5_I_ENVRD <> "S"
      U_ITMsg(_cTexto,"Atenção",,1)
      Break
   EndIf

   //================================================================================
   // Realiza a integração do cancelamento do pedido de vendas selecionados e
   // atualiza tabelas de muro.
   //================================================================================
   If !u_IT_TMS(SC5->C5_I_LOCEM) 
      FWMsgRun(,{|oproc| U_AOMS094E(oproc)},'Aguarde processamento...','Integrando dados cancelamento Pedidos de Vendas...')
   Else
      FWMsgRun(,{|oproc| U_AOMS140E(oproc)},'Aguarde processamento...','Integrando dados cancelamento Pedidos de Vendas...')
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Função------------: AOMS084Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/12/2016
Descrição---------: Reprocessa pedidos de vendas para envio ao RDC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084Y()

Local _nquant := 0

If pergunte('AOMS084',.T.)

      cQueryi	:= " SELECT DISTINCT SC5.r_e_c_n_o_ reg "
      cQueryc	:= " SELECT count(*) quant "
      cQuery	:= " FROM  "+ RetSqlName('SC5') + " SC5 , "+ RetSqlName('SC6') + " SC6 "
      cQuery	+= " WHERE "+ RetSqlDel('SC5') + " AND " + RetSqlDel('SC6')
      cQuery	+= " AND SC5.C5_FILIAL = SC6.C6_FILIAL AND SC5.C5_NUM = SC6.C6_NUM "
      cQuery	+= " AND SC5.C5_EMISSAO > '20170101' "
      cQuery	+= " AND SC5.C5_NOTA < '0000001' "
      cQuery	+= " AND SC5.C5_I_ENVRD <> 'S' AND  SC5.C5_I_ENVRD <> 'R'  AND  SC5.C5_I_ENVRD <> 'V' "
      cQuery	+= " AND NOT EXISTS (select sc9.c9_carga from "+ RetSqlName('SC9') + " sc9 where "+ RetSqlDel('SC9')
        cQuery	+= "                                                             and sc9.c9_pedido = sc5.c5_num
        cQuery	+= "                                                             and sc9.c9_filial = sc5.c5_filial AND SC9.C9_CARGA <> ' ')

        If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)

           cQuery += " AND SC5.C5_I_DTENT BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"

        EndIf

        If !Empty(AllTrim(MV_PAR01))

           cQuery += " AND SC5.C5_FILIAL IN " + FormatIn(MV_PAR01,";")

      EndIf

      If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)

           cQuery += " AND SC5.C5_NUM BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "'"

        EndIf

        //Do Armazem
        If ! Empty(MV_PAR06)
           cQuery += " AND SC6.C6_Local IN " + FormatIn(MV_PAR06,";")
        EndIf

        //UF Cliente
        If ! Empty(MV_PAR07)
           cQuery += " AND SC5.C5_I_EST = '"+MV_PAR07+"' "
        EndIf

        //Peso De
        If ! Empty(MV_PAR08)
           cQuery += " AND SC5.C5_I_PESBR >= " + AllTrim(Str(MV_PAR08,18,3))
        EndIf

        //Peso Ate
        If ! Empty(MV_PAR09)
           cQuery += " AND SC5.C5_I_PESBR <= " + AllTrim(Str(MV_PAR09,18,3))
        EndIf

      If Select("TRAB1") <> 0
         TRAB1->( DBCloseArea(  ) )
      EndIf

      MPSysOpenQuery( cQueryc + cQuery , "TRAB1")
      DBSelectArea("TRAB1")

      _nquant := TRAB1->QUANT

      If Select("TRAB1") <> 0
         TRAB1->( DBCloseArea(  ) )
      EndIf

      MPSysOpenQuery( cQueryi + cQuery , "TRAB1")
      DBSelectArea("TRAB1")

      If _lScheduler

         //===============================================================================================================
         //Atualiza pedidos retornados de data anterior para pedidos a serem enviados para o RDC
         //===============================================================================================================

         u_itconout( '[AOMS084] -  - Importanto Pedidos Retornados...' )
         U_AOMS084K(@_nquant)
         u_itconout( '[AOMS084] -  - ' + StrZero(_nquant,6) + ' pedidos processados...' )


         //===============================================================================================================

         //===============================================================================================================
         //Atualiza muro com pedidos selecionados
         //===============================================================================================================

         u_itconout( '[AOMS084] -  - Atualizando muro...' )
         U_AOMS084H(@_nquant)
         u_itconout( '[AOMS084] -  - ' + StrZero(_nquant,6) + ' pedidos processados...' )

         //===============================================================================================================


      Else


         //===============================================================================================================
         //Atualiza pedidos retornados de data anterior para pedidos a serem enviados para o RDC
         //===============================================================================================================

         FWMsgRun(,{|oproc| U_AOMS084K(_nQuant,oproc)},'Aguarde processamento...','Atualizando Pedidos Retornados...')



         //===============================================================================================================

         //===============================================================================================================
         //Atualiza muro com pedidos selecionados
         //===============================================================================================================

         FWMsgRun(,{|oproc| U_AOMS084H(_nQuant,oproc)},'Aguarde processamento...',"Importando Pedidos..." )

         //===============================================================================================================

      EndIf

EndIf

If !_lScheduler

   alert(StrZero(_nquant,4) + " Pedidos importados com sucesso!")

EndIf

Return

/*
===============================================================================================================================
Função------------: AOMS084Z
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2016
Descrição---------: Reprocessa pedidos de vendas tendo como base as notas fiscais, para envio ao RDC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084Z()
Local _nQuant := 0
Local _cQueryI, _cQueryC, _cQuery

Begin Sequence

   If Pergunte('AOMS084',.T.)
      _cQueryI := " SELECT SC5.r_e_c_n_o_ reg "
     _cQueryC := " SELECT count(*) quant "
     _cQuery  := " FROM  "+ RetSqlName('SC5') + " SC5, " + RetSqlName('SF2') + " SF2 "
     _cQuery  += " WHERE "+ RetSqlDel('SC5') + " AND " + RetSqlDel('SF2')
     _cQuery  += " AND C5_FILIAL = F2_FILIAL AND C5_NUM = F2_I_PEDID "
     _cQuery  += " AND SC5.C5_I_ENVRD <> 'S' AND SC5.C5_I_ENVRD <> 'R'   AND SC5.C5_I_ENVRD <> 'V' "
     _cQuery  += " AND SC5.C5_NOTA <>  ' ' "

      If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)

         _cQuery += " AND SF2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"

      EndIf

      If !Empty(AllTrim(MV_PAR01))

         _cQuery += " AND SC5.C5_FILIAL IN " + FormatIn(MV_PAR01,";")

     EndIf

      If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)

         _cQuery += " AND SC5.C5_NUM BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "'"

      EndIf

      If Select("TRAB1") <> 0
       TRAB1->( DBCloseArea() )
      EndIf

      MPSysOpenQuery( _cQueryC + _cQuery , "TRAB1")
      DBSelectArea("TRAB1")

      _nQuant := TRAB1->QUANT

     If Select("TRAB1") <> 0
        TRAB1->( DBCloseArea() )
      EndIf

      MPSysOpenQuery( _cQueryI + _cQuery , "TRAB1")
      DBSelectArea("TRAB1")//O MPSysOpenQuery() NÃO DEIXA NA AREA NOVA

      FWMsgRun(,{|oproc| U_AOMS084K(_nQuant,oproc)},'Aguarde processamento...','Atualizando Pedidos Retornados...')

      FWMsgRun(,{|oproc| U_AOMS084H(_nQuant,oproc)},'Aguarde processamento...',"Importando Pedidos..." )

   EndIf

   U_ITMsg("Total de " + StrZero(_nQuant,4) + " Pedidos importados com sucesso!","Processamento concluido",,2)

End Sequence

Return

/*
===============================================================================================================================
Função------------: AOMS084k
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/12/2016
Descrição---------: Grava Reprocessamento pedidos de vendas retornados para envio ao RDC
Parametros--------: nquant - quantidade de pedidos
               oproc - objeto de barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AOMS084K(nquant,oproc)

Private ncont := 1, _nNaoIntegra := 0

Default nquant := 0

Default oproc := nil


_nTot:=0
_cTipoOper  := SuperGetMV('IT_TIPOOPE',.T.,'01;10;17;20;41;')
_cFilHabilit:= SuperGetMV('IT_FILINTW',.T.,'' ) // Filiais habilitadas na integracao Webservice Italac x RDC.

cQueryI  := " SELECT SC5.R_E_C_N_O_ REG "
cQuery	:= " FROM  "+ RetSqlName('SC5') + " SC5 "
cQuery	+= " WHERE "+ RetSqlDel('SC5')
cQuery	+= " AND SC5.C5_EMISSAO > '20170101' "
cQuery	+= " AND SC5.C5_NOTA = '      ' "
cQuery   += " AND SC5.C5_I_ENVRD = 'R' "
cQuery   += " AND SC5.C5_I_AGEND NOT IN ('R','P','N') " 
cQuery   += " AND SC5.C5_I_DTRET < '" + DToS(Date()) + "'"
cQuery   += " AND SC5.C5_FILIAL IN " + FormatIn(_cFilHabilit,";")

If Select("TRABH") <> 0
   TRABH->( DBCloseArea(  ) )
EndIf

MPSysOpenQuery( cQueryI + cQuery , "TRABH")
DBSelectArea("TRABH")

While TRABH->( !Eof() )

   //posiciona sc5
   SC5->(DBGoTo(TRABH->REG))

   If !_lScheduler

       If ValType(oproc) = "O"

           oproc:cCaption := ("Gravando pedido " + StrZero(ncont,4) + " de " + StrZero(nquant,4))
           ProcessMessages()

        EndIf

      ncont++

   EndIf


   _nTot++

    If SC5->(MSRLOCK(SC5->(RECNO())))

       u_AOMS084P("N") //Grava tabela de muro

       RecLock("SC5",.F.)
       SC5->C5_I_HRRET := " "
       SC5->C5_I_DTRET := SToD("")
       SC5->C5_I_ENVRD := "N"
       SC5->(MSUnLock())
       SC5->(MSUnLockall())

    EndIf

    TRABH->(DBSkip())

EndDo


Return

/*
===============================================================================================================================
Função------------: AOMS084H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/12/2016
Descrição---------: Grava Reprocessamento pedidos de vendas para envio ao RDC
Parametros--------: nquant - quantidade de pedidos
               oproc - objeto de barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084H(nquant,oproc)

Private ncont := 1, _nNaoIntegra := 0

Default nquant := 0

Default oproc := nil

_cDataA := Date()
_cTimeA := Time()

While TRAB1->( !Eof() )

   //posiciona sc5
   SC5->(DBGoTo(TRAB1->REG))

   If !_lScheduler

      If ValType(oproc) = "O"

           oproc:cCaption := ("Gravando pedido " + StrZero(ncont,4) + " de " + StrZero(nquant,4))
           ProcessMessages()

        EndIf

      ncont++

   EndIf

   u_AOMS084P("N") //Grava tabela de muro

   nquant++

   TRAB1->(DBSkip())

EndDo


Return

/*
===============================================================================================================================
Função------------: AOMS084T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/03/2017
Descrição---------: Rotina de pesquisa de pedidos para integrados para o sistema RDC.
Parametros--------: _nRegAtu = Numero do registro do item posicionado.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084T(_nRegAtu)
Local _bOk, _bCancel
Local _oRadio, _nRadio := 1
Local _lRet := .F.

Private _oDlgPesq, _dDtEmiss, _cPedido, _oDtEmiss, _oPedido

Begin Sequence
   _bOk := {|| _lRet := .T., _oDlgPesq:End()}
   _bCancel := {|| _lRet := .F., _oDlgPesq:End()}

   _cTitulo := "Pesquisa da Integração do Pedidos de Vendas"
   _dDtEmiss := Ctod("  /  /  ")
   _cPedido  := Space(6)

   //================================================================================
   // Monta a tela de Pesquisa de Dados.
   //================================================================================
   Define MsDialog _oDlgPesq Title _cTitulo From 9,0 To 25,50 Of oMainWnd

      @ 03,08 Say " Ordem de Pesquisa " Pixel of _oDlgPesq
      @ 10,04 To 40,80 Pixel of _oDlgPesq
      @ 15,10 Radio _oRadio Var _nRadio Items "Por Data Emissão", "Por Pedido Vendas" Size 70,25 On Change U_AOMS084E(_nRadio) Pixel Of _oDlgPesq

      @ 50,10 Say "Data Emissão" Pixel of _oDlgPesq
      @ 50,70 Get _oDtEmiss  Var _dDtEmiss Picture "@d" Size 30,10 Pixel Of _oDlgPesq

      @ 70,10 Say "Nr.Pedido Vendas" Pixel of _oDlgPesq
      @ 70,70 Get _oPedido   Var _cPedido Picture "@!" Size 30,10 Pixel Of _oDlgPesq
      _oPedido:Disable()

      @ 90,040  Button "Pesquisar" Size 50,20  Of _oDlgPesq Pixel Action EVAL(_bOk)
      @ 90,105  Button "Sair"      Size 50,20  Of _oDlgPesq Pixel Action EVAL(_bCancel)

   Activate MsDialog _oDlgPesq CENTERED //On Init EnchoiceBar(_oDlgPesq,_bOk,_bCancel)

   If _lRet
      If _nRadio == 1
         If ! Empty(_dDtEmiss)
            TRBZFQ->(DBSetOrder(1))
            TRBZFQ->(DBSeek(DToS(_dDtEmiss)))
         Else
            MsgInfo("Para efetuar a pesquisa corretamente, preencha a data.","Atenção")
         EndIf
      Else
         If ! Empty(_cPedido)
            TRBZFQ->(DBSetOrder(2))
            TRBZFQ->(DBSeek(_cPedido))
         Else
            MsgInfo("Para efetuar a pesquisa corretamente, preencha a data.","Atenção")
         EndIf

      EndIf
   Else
      TRBZFQ->(DBGoTo(_nRegAtu))
   EndIf

   _oMarkZFQ:oBrowse:Refresh()

End Sequence

Return

/*
===============================================================================================================================
Função------------: AOMS084E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/03/2017
Descrição---------: Na mudança do botão de rádio, habiita ou desabilita um determinado campo.
Parametros--------: _nRadio = Opção de radio selecionada.
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AOMS084E(_nRadio)

Begin Sequence
   If _nRadio == 1
      _oDtEmiss:Enable()
      _oPedido:Disable()
   Else
      _oDtEmiss:Disable()
      _oPedido:Enable()
   EndIf

   _oDlgPesq:Refresh()

End Sequence

Return .T.



/*
=================================================================================================================================
Programa--------: AOMS084F()
Autor-----------: Josué Danich Prestes
Data da Criacao-: 19/05/2017
Descrição-------: Rotina de devolução de retorno do Pedido integrado para o Sistema RDC.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS084F()
Local _cTextoMsg

Begin Sequence

   _cTextoMsg := "Confirma a devolução do pedido de vendas ["+AllTrim(SC5->C5_NUM)+"], para o sistema TMS ?"

   If ! MsgYesNo(_cTextoMsg,"Atenção")
      Break
   EndIf

   If SC5->C5_I_ENVRD = "S"
      _cTextoMsg := "Este pedido já está enviado ao sistema TMS !"

      MsgInfo(_cTextoMsg,"Atenção")
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
=================================================================================================================================
Programa--------: AOMS084G()
Autor-----------: Josué Danich Prestes
Data da Criacao-: 16/08/2017
Descrição-------: Identifica se é pedido só com pallets ou não
Parametros------: Nenhum (Deve receber SC5 posicionada)
Retorno---------: _ctipo, "1" PARA PEDIDO NORMAL E "2" PARA PEDIDO DE PALLET
=================================================================================================================================
*/
Static Function AOMS084G()

Local _ctipo := "1"
Local _aarea := getarea("SC6")
Local _lachou := .T.

SC6->(DBSetOrder(1))

If  SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

  _lachou := .F.

  While SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM

    If Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPO") != "UN"

       _lachou := .T. //Marca se achar produto que não é pallet

    EndIf

    SC6->(DBSkip())

  EndDo

EndIf

SC6->(FWRestArea(_aarea))

If !_lachou //Se não achou produto que não é pallet marca o pedido como pedido de pallet

  _ctipo := "2"

EndIf

Return _ctipo

/*
===============================================================================================================================
Programa----------: AOMS084Q
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/10/2023
Descrição---------: Rotina de transmissão de dados webservice para o sistema TMS da Multi-Embarcador / Multsoftware.
                    Adiciona Pedido de Vendas e Carga no TMS (Método AdicionarCarga).
Parametros--------: oproc = Objeto de mensagens
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS084Q(oproc)
Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cItemXML := ""
Local _cDetA_1_XML := "", _cDetA_2_XML := "" //,_cDetA_3_XML := ""
Local _cDetC_XML := ""
Local _cRodXML := ""
Local _cDadosItens
Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFQ","ZFM","ZFR","SC9","SC5"})
Local _aUF := {}
Local _cDetA3Cab, _cDetA3Rod, _cDetA3GeF, _cDetA3GeJ, _cDetA3SuF, _cDetA3SuJ, _cDetA3VeF, _cDetA3VeJ
Local _cDetA3Ger, _cDetA3Sup, _cDetA3Ven

Local _cXML

Local _cResult := ""
Local _aRecnoItem, _nI
Local _lEnvXml
Local _cResposta, _cSituacao, _cReserva
Local _cForEmbM, _cLojaEmbM, _cFilRDC
Local _cIndIEExp,_cIndIEFor,_cIndIECli
Local lAchouSC5 := .F. 

Private _cToken
Private _cInscrCli // InscricaoEstadual
Private _cNomeFCli // NomeFantasia
Private _cRGIECl   // RGIE
Private _cRazaoCli // RazaoSocial
Private _cTipoPCli // TipoPessoa
Private _cCPFVend  // CPF
Private _cEmailVen // Email
Private _cNomeVend // Nome
Private _cRGVend   // RG
Private _cTelVend  // Telefone
Private _cGrupoProd // CodigoGrupoProduto
Private _cDescGrpP  // DescricaoGrupoProduto
Private _cDescProd  // DescricaoProduto
Private _cQtdPalEm  // QuantidadeCaixaPorPallet
Private _cQtdPorCx  // QuantidadePorCaixa
Private _cCepForn  // CEP
Private _cInscEst  // InscricaoEstadual
Private _cNFantFor // NomeFantasia
Private _cRgiForn   // RGIE
Private _cRazaoFor // RazaoSocial
Private _cTipoPFor // TipoPessoa
Private _cCondPag  // TipoPagamento

Default oproc := nil

Begin Sequence
   // Retorna Codigo Empresa WebService TMS-MULTI EMBARCADOR.
   _cEmpWebService := SuperGetMV('IT_EMPTMSM',.T.,"000005")

   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("1/12 - Verificando itens selecionados...")
          ProcessMessages()
      EndIf

      TRBZFQ->(DBGoTop())
      While ! TRBZFQ->(Eof())
         If ! Empty(TRBZFQ->WK_OK)
            //_cEmpWebService := TRBZFQ->ZFQ_CODEMP
            _lItemSelect := .T.
            Exit
         EndIf

         TRBZFQ->(DBSkip())
      EndDo

      If ! _lItemSelect
         U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> MULTI-EMBARCADOR.","Atenção",,1)
         Break
      EndIf
   Else
      TRBZFQ->(DBGoTop())//Todos estão marcados
      //_cEmpWebService := TRBZFQ->ZFQ_CODEMP
   EndIf

   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("2/12 - Identificando diretório dos XML...")
         ProcessMessages()
       EndIf
   EndIf

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else
      If _lScheduler
         u_itconout( "[AOMS084] - Empresa WebService para envio dos dados não localizada.")
      Else
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      Break
   EndIf

   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lScheduler
         U_Itconout("[AOMS084] - Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      Else
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf
      Break
   EndIf

   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo XML e os transforma em String.
   //================================================================================
   If !_lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("3/12 - Lendo arquivo XML Modelo de Cabeçalho...")
           ProcessMessages()
      EndIf
   EndIf

   _cCabXML := U_AOMS084X(_cDirXML+"Cab_Pedido_TMS.txt")
   If Empty(_cCabXML)
      If _lScheduler
         U_Itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do cabeçalhode envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de envio Pedido de Vendas. ","Atenção",,1)
      EndIf
      Break
   EndIf

  If !_lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("4/12 - Lendo arquivo XML Modelo de Detalhe A_1...")
           ProcessMessages()
        EndIf
   EndIf

   _cDetA_1_XML := U_AOMS084X(_cDirXML+"Det_A_1_Pedido_TMS.TXT")
   If Empty(_cDetA_1_XML)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_1 de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("5/12 - Lendo arquivo XML Modelo de Detalhe A_2...")
           ProcessMessages()
        EndIf
   EndIf

   _cDetA_2_XML := U_AOMS084X(_cDirXML+"Det_A_2_EXPEDIDOR_Pedido_TMS.TXT")
   If Empty(_cDetA_2_XML)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_2_Expedidor de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("6/12 - Lendo arquivo XML Modelo de Detalhe A_3...")
           ProcessMessages()
        EndIf
   EndIf
   _cDetA3Cab := U_AOMS084X(_cDirXML+"det_a_3_cab_pedido_tms.TXT")
   If Empty(_cDetA3Cab)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Cabeçalho de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

 _cDetA3Rod := U_AOMS084X(_cDirXML+"det_a_3_Rodape_pedido_tms.TXT")
   If Empty(_cDetA3Rod)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Rodapé de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

//==================
 _cDetA3GeF := U_AOMS084X(_cDirXML+"det_a_3_FuncGerente_CPF_pedido_tms.TXT")
   If Empty(_cDetA3GeF)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Gerente CPF de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

//===================
   _cDetA3GeJ := U_AOMS084X(_cDirXML+"det_a_3_FuncGerente_CNPJ_pedido_tms.TXT")
   If Empty(_cDetA3GeJ)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Gerente CNPJ de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

//===================
   _cDetA3SuF := U_AOMS084X(_cDirXML+"det_a_3_FuncSupervisor_CPF_pedido_tms.TXT")
   If Empty(_cDetA3SuF)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Supervisor CPF de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf


//================
   _cDetA3SuJ := U_AOMS084X(_cDirXML+"det_a_3_FuncSupervisor_CNPJ_pedido_tms.TXT")
   If Empty(_cDetA3SuJ)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Supervisor CNPJ de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

//================
   _cDetA3VeF := U_AOMS084X(_cDirXML+"det_a_3_FuncVendedor_CPF_pedido_tms.TXT")
   If Empty(_cDetA3VeF)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Vendedor CPF de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf

//================
   _cDetA3VeJ := U_AOMS084X(_cDirXML+"det_a_3_FuncVendedor_CNPJ_pedido_tms.TXT")
   If Empty(_cDetA3VeJ)
      U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A_3 Vendedor CNPJ de envio Pedido de Vendas.","Atenção",,1)
      Break
   EndIf

   If !_lScheduler
      If ValType(oproc) = "O"
         oproc:cCaption := ("7/12 - Lendo arquivo XML Modelo de Item de Pedido...")
         ProcessMessages()
      EndIf
   EndIf
//=================================================================================================================

   _cItemXML := U_AOMS084X(_cDirXML+"Det_B_Itens_Pedido_TMS.TXT")
   If Empty(_cItemXML)
      If _lScheduler
         U_Itconout("[AOMS084] - Erro na leitura do arquivo XML modelo dos itens de envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo dos itens de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
   EndIf

   If ! _lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("8/12 - Lendo arquivo XML Modelo de Detalhe B...")
         ProcessMessages()
       EndIf
   EndIf

   _cDetC_XML := U_AOMS084X(_cDirXML+"Det_C_Pedido_TMS.TXT")
   If Empty(_cDetC_XML)
      If _lScheduler
         U_Itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do detalhe C de envio Pedido de Vendas..")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe C de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
   EndIf

   If !_lScheduler
        If ValType(oproc) = "O"
         oproc:cCaption := ("9/12 - Lendo arquivo XML Modelo de Rodapé...")
         ProcessMessages()
      EndIf
   EndIf

   _cRodXML := U_AOMS084X(_cDirXML+"Rodape_Pedido_TMS.txt")
   If Empty(_cRodXML)
      If _lScheduler
         u_itconout("[AOMS084] - Erro na leitura do arquivo XML modelo do rodapé de envio Pedido de Vendas.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
   EndIf

   //--------------------------------------------------------------------------------------------------
   // Verifica se o pedido já tem liberação, não permite a integração via Webservice e muda a situação
   // do registro na tabela de muro para "Liberado Manualmente".
   //--------------------------------------------------------------------------------------------------
   SC9->(DBSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO
   ZFR->(DBSetOrder(5))
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM
   SA1->(DBSetOrder(3)) // A1_FILIAL+A1_CGC
   SA2->(DBSetOrder(3)) // A2_FILIAL+A2_CGC
   SA3->(DBSetOrder(1)) // A3_FILIAL+A3_LOJA
   SB1->(DBSetOrder(1)) // B1_FILIAL+B1_COD

   //=====================================================================================
   // Verifica se existe algum item para envio de XML que não foi liberado manualmente.
   //=====================================================================================
   _lEnvXml := .F.

   TRBZFQ->(DBGoTop())
   While ! TRBZFQ->(Eof())
      If ! Empty(TRBZFQ->WK_OK)
         _lEnvXml := .T.
         Exit
      EndIf

      TRBZFQ->(DBSkip())
   EndDo

   If ! _lEnvXml  // Não há dados para envio do XML.
      Break
   EndIf

   //================================================================================
   // Concatena os Pedidos de Vendas selecionados e monta array de XML com os dados.
   //================================================================================
   If !_lScheduler
        If ValType(oproc) = "O"
           oproc:cCaption := ("10/12 - Montando dados de envio...")
           ProcessMessages()
      EndIf
   EndIf

   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.

   oWsdl:nTimeout := 90          // Timeout de 90 segundos
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo

   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da MULTI-EMBARCADOR.
   oWsdl:SetOperation( "AdicionarCarga") // Define qual operação será realizada.

   _aresult := {}

   ZFR->(DBSetOrder(5))
   SC9->(DBSetOrder(1))
   SA3->(DBSetOrder(1))
   SA2->(DBSetOrder(3))
   SA1->(DBSetOrder(3))
   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
   ZG9->(DBSetOrder(1)) // ZG9_FILIAL+ZG9_CODFIL+ZG9_ARMAZE

   If ValType(oproc) = "O"
      oproc:cCaption := ("11/12 - Enviando dados para MULTI-EMBARCADOR...")
      ProcessMessages()
   EndIf

   //================================================================================
   // Monta array dos estados
   //================================================================================
   _aUF := {}
   aAdd(_aUF,{"RO","11"})
   aAdd(_aUF,{"AC","12"})
   aAdd(_aUF,{"AM","13"})
   aAdd(_aUF,{"RR","14"})
   aAdd(_aUF,{"PA","15"})
   aAdd(_aUF,{"AP","16"})
   aAdd(_aUF,{"TO","17"})
   aAdd(_aUF,{"MA","21"})
   aAdd(_aUF,{"PI","22"})
   aAdd(_aUF,{"CE","23"})
   aAdd(_aUF,{"RN","24"})
   aAdd(_aUF,{"PB","25"})
   aAdd(_aUF,{"PE","26"})
   aAdd(_aUF,{"AL","27"})
   aAdd(_aUF,{"MG","31"})
   aAdd(_aUF,{"ES","32"})
   aAdd(_aUF,{"RJ","33"})
   aAdd(_aUF,{"SP","35"})
   aAdd(_aUF,{"PR","41"})
   aAdd(_aUF,{"SC","42"})
   aAdd(_aUF,{"RS","43"})
   aAdd(_aUF,{"MS","50"})
   aAdd(_aUF,{"MT","51"})
   aAdd(_aUF,{"GO","52"})
   aAdd(_aUF,{"DF","53"})
   aAdd(_aUF,{"SE","28"})
   aAdd(_aUF,{"BA","29"})
   aAdd(_aUF,{"EX","99"})

   // Obtem o token de acesso ao sistema multi embarcador.
   _cToken := SuperGetMV('IT_TOKMUTE',.T.,"a78e0523d3794843855e8d95c2bff8d4")

   TRBZFQ->(DBGoTop())
   While ! TRBZFQ->(Eof())

      If ! Empty(TRBZFQ->WK_OK)
         ZFQ->(DBGoTo(TRBZFQ->WKRECNO))
         If (SC5->(DBSeek(ZFQ->ZFQ_FILIAL+ZFQ->ZFQ_PEDIDO))) 
            lAchouSC5 := .T. 
            If !U_IT_TMS(SC5->C5_I_LOCEM)
               TRBZFQ->(DBSkip())
               Loop
            EndIf
         Else
            lAchouSC5 := .F. 
         EndIf

         Begin Transaction

            U_Itconout( '[AOMS084] -  - Enviando pedido ' + ZFQ->ZFQ_PEDIDO + ' para multi-embarcador ...' )

            If ValType(oproc) = "O"
               oproc:cCaption := ("12/12 - Enviando dados para MULTI-EMBARCADOR - Pedido " + ZFQ->ZFQ_PEDIDO + "..." )
               ProcessMessages()
            EndIf

            If !lAchouSC5 //Se não achar o pedido de vendas marca como enviado e não transmite
               ZFQ->(RecLock("ZFQ",.F.))
               ZFQ->ZFQ_SITUAC  := "P"
               ZFQ->ZFQ_DATAAL  := Date()
               ZFQ->ZFQ_RETORN  := "Eliminado por exclusão do pedido no SC5"
               ZFQ->ZFQ_DATAP := Date()
               ZFQ->ZFQ_HORAP := Time()
               ZFQ->(MSUnLock())
               U_Itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' eliminado da muro por exclusão ...' )
            ElseIf !Empty(SC5->C5_NOTA) //Se pedido já tem nota não envia mais para MULTI-EMBARCADOR
               ZFQ->(RecLock("ZFQ",.F.))
               ZFQ->ZFQ_SITUAC  := "P"
               ZFQ->ZFQ_DATAAL  := Date()
               ZFQ->ZFQ_RETORN  := "Eliminado por SC5 já possuir nota emitida"
               ZFQ->ZFQ_DATAP := Date()
               ZFQ->ZFQ_HORAP := Time()
               ZFQ->(MSUnLock())
               U_Itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' eliminado da muro por ter nota emitida ...' )
            Else
               //Verifica se consegue lockar o SC5
               If !(SC5->(Msrlock(SC5->(Recno()))))
                    //Se não conseguir lockar o SC5 desarma a transação e parte para o próximo registro
                    Disarmtransaction()
                    TRBZFQ->(DBSkip())
                    u_itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' não enviado por lock na SC5 ...' )
               Else
                  //=======================================================================================
                  // Atualiza os Pedidos antigos da tabela ZFQ ante de transmitir dados no novo WebService
                  //=======================================================================================
                  If Empty(ZFQ->ZFQ_CODVEN) .Or. Empty(ZFQ->ZFQ_CODGER) .Or. Empty(ZFQ->ZFQ_CODCOO)
                     //========================================================
                     // Busca os dados dos Expedidor
                     //========================================================
                     _cForEmbM  := ""
                     _cLojaEmbM := ""
                     _cFilRDC   := ""

                     SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
                     While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
                        If Empty(_cForEmbM)
                           If ZG9->(DBSeek(xFilial("ZG9")+SC6->C6_FILIAL+SC6->C6_LOCAL))
                              _cForEmbM  := ZG9->ZG9_CODFOR
                              _cLojaEmbM := ZG9->ZG9_LOJFOR
                              _cFilRDC   := ZG9->ZG9_FILRDC
                              Exit
                           EndIf
                        EndIf

                        SC6->(DBSkip())

                     EndDo

                     _cCNPJEX := ""   // CNPJ do Expedidor
                     _cCEPEXP := ""   // Cep do Expedidor
                     _cIBGEEX := ""   // Municpio da Expedidor (Código IBGE)
                     _cINSEXP := ""   // Inscrição Estadual Expedidor
                     _cENDEXP := ""   // Endereço do Expedidor
                     _cNUMEXP := ""   // Número do Endereço do Expedidor
                     _cFANEXP := ""   // Nome Fantasia Expedidor
                     _cRAZEXP := ""   // Razação Social Expedidor
                     _cTIPPEX := ""   // Tipo Pessoa Expedidor
                     _cIndIEExp := "" // Indicador Inscrição Estadual Expedidor

                     If ! Empty(_cForEmbM)
                        SA2->(DBSetOrder(1))
                        If SA2->(DBSeek(xFilial("SA2")+_cForEmbM+_cLojaEmbM)) // Posiciona no embarcador das mercadorias
                           _cCNPJEX := SA2->A2_CGC     // CNPJ do Expedidor
                           _cCEPEXP := SA2->A2_CEP     // Cep do Expedidor
                           _cIBGEEX := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)                                            // Municpio da Expedidor (Código IBGE)
                           _cINSEXP := SA2->A2_INSCR   // Inscrição Estadual Expedidor
                           _cENDEXP := SA2->A2_I_END   // Endereço do Expedidor
                           _cNUMEXP := SA2->A2_I_NUM   // Número do Endereço do Expedidor
                           _cFANEXP := SA2->A2_NREDUZ  // Nome Fantasia Expedidor
                           _cRAZEXP := SA2->A2_NOME    // Razação Social Expedidor
                           _cTIPPEX := If(SA2->A2_TIPO=="P","Fisica","Juridica") // TipoPessoa

                           If Empty(_cENDEXP)
                              _cENDEXP := SA2->A2_END             // Endereço do Expedidor
                              _cNUMEXP := U_AOMS084N(SA2->A2_END) // Número do Endereço do Expedidor
                              _cIBGEEX := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN 	  // Municpio da Fábrica (Código IBGE)
                           EndIf

                           If SA2->A2_CONTRIB == "1" .And. !Empty(SA2->A2_INSCR) .And. AllTrim(SA2->A2_INSCR) <> "ISENTO"
                              _cIndIEExp := "ContribuinteICMS" // "1" //Contribuinte ICMS
                           ElseIf SA2->A2_CONTRIB == "1"
                              _cIndIEExp := "ContribuinteIsento" // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
                           Else
                              _cIndIEExp := "NaoContribuite" // "9" //  Não Contribuinte que pode ou não ter inscição est.
                           EndIf

                        EndIf

                        SA2->(DBSetOrder(3))
                     EndIf

                     //========================================================
                     // Obtem dados do Vendedor
                     //========================================================
                     _cCodVend  := SC5->C5_VEND1
                     _cCPFVend  := ""    // CPF
                     _cEmailVen := ""    // Email
                     _cNomeVend := ""    // Nome
                     _cRGVend   := ""    // RG
                     _cTelVend  := ""    // Telefone

                     If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND1))
                        _cCPFVend  := AllTrim(SA3->A3_CGC)  // CPF
                        _cEmailVen := AllTrim(SA3->A3_EMAIL)  // Email
                        _cNomeVend := AllTrim(SA3->A3_NOME)  // Nome
                        _cRGVend   := ""  // RG
                        _cTelVend  := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
                     EndIf

                     //========================================================
                     // Obtem dados do Coordenador
                     //========================================================
                     _cCodCoord := SC5->C5_VEND2  // Cod. Coordenador
                     _cCPFCoord := ""    // CPF
                     _cEmailCoo := ""    // Email
                     _cNomeCoor := ""    // Nome
                     _cRGCoord  := ""    // RG
                     _cTelCoord := ""    // Telefone

                     If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND2))
                        _cCPFCoord  := AllTrim(SA3->A3_CGC)    // CPF
                        _cEmailCoo := AllTrim(SA3->A3_EMAIL)  // Email
                        _cNomeCoor := AllTrim(SA3->A3_NOME)   // Nome
                        _cRGCoord  := ""  // RG
                        _cTelCoord := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
                     EndIf

                     //========================================================
                     // Obtem dados do Gerente.
                     //========================================================
                     _cCodGeren  := SC5->C5_VEND3  // Cod. Gerente
                     _cCPFGeren  := ""    // CPF
                     _cEmailGer  := ""    // Email
                     _cNomeGeren := ""    // Nome
                     _cRGGeren   := ""    // RG
                     _cTelGeren  := ""    // Telefone

                     If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND3))
                        _cCPFGeren  := AllTrim(SA3->A3_CGC)  // CPF
                        _cEmailGer := AllTrim(SA3->A3_EMAIL)  // Email
                        _cNomeGeren := AllTrim(SA3->A3_NOME)  // Nome
                        _cRGGeren   := ""  // RG
                        _cTelGeren  := SA3->A3_DDDTEL+AllTrim(SA3->A3_TEL) // Telefone
                     EndIf

                     //============================================================
                     // Obtem dados do Fornecedor
                     //============================================================
                     _cCepForn  := ""            // CEP
                     _cInscEst  := ""            // InscricaoEstadual
                     _cNFantFor := ""            // NomeFantasia
                     _cRgiForn  := ""            // RGIE
                     _cRazaoFor := ""            // RazaoSocial
                     _cTipoPFor := ""            // TipoPessoa
                     //_cCondPag  := AllTrim(Posicione('SE4',1,xFilial('SE4')+SC5->C5_CONDPAG,'E4_DESCRI'))
                     _cIndIEFor := ""            // Indicador Inscrição Estadual Fornecedor

                     If SA2->(MsSeek(xFilial("SA2")+ZFQ->ZFQ_CNPJEM))
                        _cCepForn  := AllTrim(SA2->A2_CEP)                                                   // CEP
                        _cInscEst  := AllTrim(SA2->A2_INSCR)                                                 // InscricaoEstadual
                        _cNFantFor := AllTrim(SA2->A2_NREDUZ)                                                // NomeFantasia
                        _cRgiForn  := ""                                                                     // RGIE
                        _cRazaoFor := AllTrim(SA2->A2_NOME)                                                  // RazaoSocial
                        _cTipoPFor := If(SA2->A2_TIPO=="P","Fisica","Juridica")                              // TipoPessoa
                        //_cCondPag  := AllTrim(Posicione('SE4',1,xFilial('SE4')+SC5->C5_CONDPAG,'E4_DESCRI'))
                        _cCodForn  := SA2->A2_COD                                                            // Codigo Fornecedor
                        _cLojaForn := SA2->A2_LOJA                                                           // Loja do Fornecedor

                        If SA2->A2_CONTRIB == "1" .And. !Empty(SA2->A2_INSCR) .And. AllTrim(SA2->A2_INSCR) <> "ISENTO"
                           _cIndIEFor := "ContribuinteICMS"   // "1" //Contribuinte ICMS
                        ElseIf SA2->A2_CONTRIB == "1"
                           _cIndIEFor := "ContribuinteIsento" // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
                        Else
                           _cIndIEFor := "NaoContribuite"     // "9" //  Não Contribuinte que pode ou não ter inscição est.
                        EndIf

                     EndIf

                     //============================================================
                     // Obtem dados do Cliente
                     //============================================================
                     _cInscrCli := ""    // InscricaoEstadual
                     _cNomeFCli := ""    // NomeFantasia
                     _cRGIECl   := ""    // RGIE
                     _cRazaoCli := ""    // RazaoSocial
                     _cTipoPCli := ""    // TipoPessoa
                     _cCEPCli   := ""    // CEP

                     _cIndIECli := ""    // Indicador Inscrição Estadual Cliente

                     If SA1->(MsSeek(xFilial("SA1")+ZFQ->ZFQ_CNPJDE))
                        _cInscrCli := AllTrim(SA1->A1_INSCR)                      // InscricaoEstadual
                        _cNomeFCli := AllTrim(SA1->A1_NREDUZ)                     // NomeFantasia
                        _cRGIECl   := AllTrim(SA1->A1_RG)                         // RGIE
                        _cRazaoCli := AllTrim(SA1->A1_NOME)                       // RazaoSocial
                        _cTipoPCli := If(SA1->A1_PESSOA=="P","Fisica","Juridica") // TipoPessoa
                        _cCEPCli   := AllTrim(SA1->A1_CEP)

                        If SA1->A1_CONTRIB == "1" .And. !Empty(SA1->A1_INSCR) .And. AllTrim(SA1->A1_INSCR) <> "ISENTO"
                           _cIndIECli := "ContribuinteICMS"   // "1" //Contribuinte ICMS
                        ElseIf SA2->A2_CONTRIB == "1"
                           _cIndIECli := "ContribuinteIsento" // "2" // Contibuinte Isento de Incrição no Cad Contrib.ICM
                        Else
                           _cIndIECli := "NaoContribuite"     // "9" //  Não Contribuinte que pode ou não ter inscição est.
                        EndIf

                     EndIf

                     ZFQ->(RecLock("ZFQ",.F.))
                     ZFQ->ZFQ_CODVEN := _cCodVend  // Codigo Vendedor
                     ZFQ->ZFQ_CPFVEN := _cCPFVend  // CPF
                     ZFQ->ZFQ_MAILVE := _cEmailVen // Email
                     ZFQ->ZFQ_TELVEN := _cTelVend  // Telefone

                     ZFQ->ZFQ_CODGER := _cCodGeren // Cod. Gerente
                     ZFQ->ZFQ_CPFGER := _cCPFGeren // CPF
                     ZFQ->ZFQ_MAILGE := _cEmailGer // Email
                     ZFQ->ZFQ_TELGER := _cTelGeren // Telefone

                     ZFQ->ZFQ_CODCOO := _cCodCoord // Cod. Coordenador
                     ZFQ->ZFQ_CPFCOO := _cCPFCoord // CPF
                     ZFQ->ZFQ_MAILCO := _cEmailCoo // Email
                     ZFQ->ZFQ_TELCOO := _cTelCoord // Telefone

                     ZFQ->ZFQ_RAZFOR := _cRazaoFor // Razão Social Fornecedor
                     ZFQ->ZFQ_FANFOR := _cNFantFor // Nome Fantasia Fornecedor
                     ZFQ->ZFQ_CEPFOR := _cCepForn  // CEP Fornecedor
                     ZFQ->ZFQ_INSFOR := _cInscEst  // Inscrição Estadual Fornecedor
                     ZFQ->ZFQ_TIPPEF := _cTipoPFor // Tipo de Pessoa Fornecedor
                     ZFQ->ZFQ_LOJFOR := _cLojaForn  // Loja do Fornecedor
                     ZFQ->ZFQ_CODFOR := _cCodForn   // Codigo Fornecedor
                     ZFQ->ZFQ_INDIEF := _cIndIEFor  // Indicador Inscrição Estadual Fornecedor

                     ZFQ->ZFQ_RAZCLI := _cRazaoCli     // Razão Social Cliente
                     ZFQ->ZFQ_FANCLI := _cNomeFCli     // Nome Fantasia Cliente
                     ZFQ->ZFQ_CEPCLI := _cCEPCli       // CEP Cliente
                     ZFQ->ZFQ_INSCLI := _cInscrCli     // Inscrição Estadual Cliente
                     ZFQ->ZFQ_TIPPEC := _cTipoPCli     // Tipo Pessoa Cliente
                     ZFQ->ZFQ_CODOPE := SC5->C5_I_OPER // Codigo de Operação
                     ZFQ->ZFQ_INDIEC := _cIndIECli     // Indicador Inscrição Estadual Cliente

                     //=============================================================================
                     _cCanalVen := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_I_VBROK")

                     If ZFQ->(FIELDPOS("ZFQ_TPOPER")) > 0
                        If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N' // Transferência de Pedido de Vendas
                           ZFQ->ZFQ_TPOPER := "TRANSF_UNID"
                        ElseIf SC5->C5_I_TRCNF = 'S'
                           ZFQ->ZFQ_TPOPER := "TROCA_NF"
                        ElseIf !Empty(_cCanalVen) .And. _cCanalVen == "B"
                           ZFQ->ZFQ_TPOPER := "BROKER"
                        ElseIf SC5->C5_TPFRETE == "F" // FRETE = FOB
                           ZFQ->ZFQ_TPOPER := "FOB"
                        Else // Venda Direta = Venda Normal
                           ZFQ->ZFQ_TPOPER := "VD_DIR"
                        EndIf
                     EndIf
                     //=============================================================================

                     //Ajuste  para frete Fob ser enviado como agenda F para o RDC
                     If SC5->C5_I_OPER  == "20" .And. SC5->C5_I_TRCNF = 'N'
                        ZFQ->ZFQ_TPAGEN	:=	"T"
                     Else
                        //c5_i_oper = '20' e c5_i_trcnf = 'N' tipo = 'T'
                        If SC5->C5_TPFRETE == "F"
                           ZFQ->ZFQ_TPAGEN := "F"
                        Else
                           ZFQ->ZFQ_TPAGEN	:=	SC5->C5_I_AGEND
                        EndIf
                     EndIf

                     //---------------------------------
                     If ! Empty(_cForEmbM)
                        ZFQ->ZFQ_CNPJEX := _cCNPJEX   // CNPJ do Expedidor
                        ZFQ->ZFQ_CEPEXP := _cCEPEXP   // Cep do Expedidor
                        ZFQ->ZFQ_IBGEEX := _cIBGEEX   // Municpio da Expedidor (Código IBGE)
                        ZFQ->ZFQ_INSEXP := _cINSEXP   // Inscrição Estadual Expedidor
                        ZFQ->ZFQ_ENDEXP := _cENDEXP   // Endereço do Expedidor
                        ZFQ->ZFQ_NUMEXP := _cNUMEXP   // Número do Endereço do Expedidor
                        ZFQ->ZFQ_FANEXP := _cFANEXP   // Nome Fantasia Expedidor
                        ZFQ->ZFQ_RAZEXP := _cRAZEXP   // Razação Social Expedidor
                        ZFQ->ZFQ_TIPPEX := _cTIPPEX   // Tipo Pessoa Expedidor
                        ZFQ->ZFQ_INDIEE := _cIndIEExp // Indicador Inscrição Estadual Expedidor
                        //------------------------------
                        If ! Empty(_cFilRDC)
                           ZFQ->ZFQ_FILRDC := _cFilRDC
                        EndIf
                        
                        //If AllTrim(ZFQ->ZFQ_FILRDC)  == "90"  // Solicitação do Vanderlei 
                        //   ZFQ->ZFQ_FILRDC :=  "9001"
                        //EndIf 

                     EndIf
                     //---------------------------------

                     ZFQ->(MSUnLock())
                  EndIf

                  //==============================================================
                  // Obtem dados do vendedor
                  //==============================================================
                  If SA3->(MsSeek(xFilial("SA3")+SC5->C5_VEND1))
                     _cCPFVend  := AllTrim(SA3->A3_CGC)  // CPF
                     _cEmailVen := AllTrim(SA3->A3_EMAIL)  // Email
                     _cNomeVend := AllTrim(SA3->A3_NOME)  // Nome
                     _cRGVend   := ""  // RG
                     _cTelVend  := "("+SA3->A3_DDDTEL+")"+AllTrim(SA3->A3_TEL) // Telefone
                  EndIf

                  //==============================================================
                  // Obtem dados do Cliente
                  //==============================================================
                  _cInscrCli := "" // InscricaoEstadual
                  _cNomeFCli := "" // NomeFantasia
                  _cRGIECl   := "" // RGIE
                  _cRazaoCli := "" // RazaoSocial
                  _cTipoPCli := "" // Tipo Pessoa

                  If SA1->(MsSeek(xFilial("SA1")+ZFQ->ZFQ_CNPJDE))
                     _cInscrCli := AllTrim(SA1->A1_INSCR)         // InscricaoEstadual
                     _cNomeFCli := AllTrim(SA1->A1_NREDUZ)        // NomeFantasia
                     _cRGIECl   := AllTrim(SA1->A1_RG)   // RGIE
                     _cRazaoCli := AllTrim(SA1->A1_NOME) // RazaoSocial
                     _cTipoPCli := If(SA1->A1_PESSOA=="P","Fisica","Juridica") // TipoPessoa
                  EndIf

                  //==============================================================
                  // Obtem dados do Fornecedor
                  //==============================================================
                  _cCepForn  := ""  // CEP
                  _cInscEst  := ""  // InscricaoEstadual
                  _cNFantFor := ""  // NomeFantasia
                  _cRgiForn  := ""  // RGIE
                  _cRazaoFor := ""  // RazaoSocial
                  _cTipoPFor := ""  // TipoPessoa
                  _cCondPag  := ""
                  _cCodForn  := ""
                  _cLojaForn := ""

                  If SA2->(MsSeek(xFilial("SA2")+ZFQ->ZFQ_CNPJEM))
                     _cCepForn  := AllTrim(SA2->A2_CEP)    // CEP
                     _cInscEst  := AllTrim(SA2->A2_INSCR)  // InscricaoEstadual
                     _cNFantFor := AllTrim(SA2->A2_NREDUZ) // NomeFantasia
                     _cRgiForn  := ""  // RGIE
                     _cRazaoFor := AllTrim(SA2->A2_NOME)  // RazaoSocial
                     _cTipoPFor := If(SA2->A2_TIPO=="P","Fisica","Juridica")  // TipoPessoa
                     _cCondPag  := AllTrim(Posicione('SE4',1,xFilial('SE4')+SC5->C5_CONDPAG,'E4_DESCRI'))
                     _cCodForn  := SA2->A2_COD            // Codigo Fornecedor
                     _cLojaForn := SA2->A2_LOJA           // Loja Fornecedor
                  EndIf
                  //-----------------------------------------------------------------------------------------
                  // Atualiza a situação e reserva do pedido de vendas, antes de enviar para o sistema MULTI-EMBARCADOR.
                  //-----------------------------------------------------------------------------------------
                  _cReserva := ""
                  If ! SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
                     _cReserva := "1" // Não tem reserva de estoque = Verde => Sem Reserva
                  Else
                     If U_Verest()
                        _cReserva := "2" // Conseguiu reservar estoque = Amarelo => Reservado
                     Else
                        _cReserva := "3" // Não há estoque disponível  = Azul => Bloqueio de estoque
                     EndIf
                  EndIf

                  ZFQ->(RecLock("ZFQ",.F.))
                  ZFQ->ZFQ_RESERV := _cReserva
                  ZFQ->ZFQ_SITPED := U_STPEDIDO() // Status do Pedido, rotina no xfunoms
                  //ZFQ->ZFQ_DSCSIT := U_STPEDIDO(1) // Descricao Situacao Pedido
                  ZFQ->(MSUnLock())

                  //-----------------------------------------------------------------------------------------
                  // Realiza a integração dos pedidos de vendas (Envio de XML) via WebService.
                  //-----------------------------------------------------------------------------------------
                  ZFR->(DBSeek(ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)+"N"))

                  _aRecnoItem := {}
                  _cDadosItens := ""
                  While ! ZFR->(Eof()) .And. ZFR->(ZFR_FILIAL+ZFR_NUMPED+ZFR_SITUAC) = ZFQ->(ZFQ_FILIAL+ZFQ_PEDIDO)+"N"

                     //============================================================
                     // Faz a atualização dos itens para pedidos de vendas antigos
                     //============================================================
                     If Empty(ZFR->ZFR_GRPPRD)
                        ZFR->(RecLock("ZFR",.F.))
                        If SB1->(MsSeek(xFilial("SB1")+SubStr(ZFR->ZFR_CODIGO,1,11))) // C5_TPFRETE
                           ZFR->ZFR_DSCPRD   := SB1->B1_DESC
                           ZFR->ZFR_GRPPRD   := SB1->B1_GRUPO
                           ZFR->ZFR_DSCGRP   := AllTrim(Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"))
                           ZFR->ZFR_QTDPAL   := SB1->B1_I_CXPAL
                        EndIf

                        If SC6->(MsSeek(ZFR->ZFR_FILIAL+ZFR->ZFR_NUMPED+ZFR->ZFR_ITEM+SubStr(ZFR->ZFR_CODIGO,1,11))) //  C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
                           ZFR->ZFR_SEGUNI   := SC6->C6_SEGUM
                           ZFR->ZFR_QTDSGU   := SC6->C6_UNSVEN
                        EndIf
                        ZFR->(MSUnLock())
                     EndIf

                     _cDadosItens += &(_cItemXML)
                     aAdd(_aRecnoItem,ZFR->(Recno()))

                     ZFR->(DBSkip())
                  EndDo

                  //_cDetA3Cab, _cDetA3Rod, _cDetA3GeF, _cDetA3GeJ, _cDetA3SuF, _cDetA3SuJ, _cDetA3VeF, _cDetA3VeJ

                  If Len(AllTrim(ZFQ->ZFQ_CPFGER)) < 14 // Modelo de XML só com o CPF do Gerente do Vendedor.
                     _cDetA3Ger := &(_cDetA3GeF)
                  Else                                  // Modelo de XML só com o CNPJ do Gerente do Vendedor.
                     _cDetA3Ger := &(_cDetA3GeJ)
                  EndIf

                  If Len(AllTrim(ZFQ->ZFQ_CPFCOO)) < 14 // Modelo de XML só com o CPF do Supervisor do Vendedor.
                     _cDetA3Sup := &(_cDetA3SuF)
                  Else                                  // Modelo de XML só com o CNPJ do Supervisor do Vendedor.
                     _cDetA3Sup := &(_cDetA3SuJ)
                  EndIf

                  If Len(AllTrim(ZFQ->ZFQ_CPFVEN)) < 14  // Modelo de XML só com o CPF do Vendedor.
                     _cDetA3Ven := &(_cDetA3VeF)
                  Else                                   // Modelo de XML só com o CNPJ do Vendedor.
                     _cDetA3Ven := &(_cDetA3VeJ)
                  EndIf

                   //Monta XML
                   //_cXML := &(_cCabXML) + &(_cDetA_XML)+ _cDadosItens + &(_cDetC_XML) + _cRodXML  // Monta o XML de envio.
                  If ! Empty(ZFQ->ZFQ_CNPJEX) // Possui Expedidor preenchido. Inclui a Tag do Expedidor
                     //_cXML := &(_cCabXML) + &(_cDetA_1_XML) + &(_cDetA_2_XML) + &(_cDetA_3_XML) + _cDadosItens + &(_cDetC_XML) + _cRodXML  // Monta o XML de envio.
                     _cXML := &(_cCabXML) + &(_cDetA_1_XML) + &(_cDetA_2_XML) + &(_cDetA3Cab) + _cDetA3Ger + _cDetA3Sup + _cDetA3Ven + &(_cDetA3Rod) + _cDadosItens + &(_cDetC_XML) + _cRodXML  // Monta o XML de envio.
                  Else  // Não possui Expedidor Preenchido. Não Inclui a Tag Expedidor
                     //_cXML := &(_cCabXML) + &(_cDetA_1_XML) + &(_cDetA_3_XML) + _cDadosItens + &(_cDetC_XML) + _cRodXML  // Monta o XML de envio.
                     _cXML := &(_cCabXML) + &(_cDetA_1_XML) + &(_cDetA3Cab) + _cDetA3Ger + _cDetA3Sup + _cDetA3Ven + &(_cDetA3Rod) + _cDadosItens + &(_cDetC_XML) + _cRodXML  // Monta o XML de envio.
                  EndIf

                   //Limpa & da string
                   _cXML := StrTran(_cXML,"&"," ")

                  // Envia para o servidor
                  _cOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da MULTI-EMBARCADOR.

                  If _cOk
                     _cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
                  Else
                     _cResult := oWsdl:cError
                  EndIf

                  _cTextoPesq := Upper(_cResult)

                  _cCodMsg   := ""
                  _cTextoMsg := ""

                  If "CODIGOMENSAGEM" $ _cTextoPesq
                     _nI := At("CODIGOMENSAGEM",_cTextoPesq)
                     _cCodMsg := AllTrim(SubStr(_cResult,_nI, 20))

                     _nI := At(":",_cCodMsg)
                     _cCodMsg := AllTrim(SubStr(_cCodMsg,_nI+1, 3))
                  EndIf

                  If "MENSAGEM" $ _cTextoPesq
                     _nI := At("MENSAGEM",_cTextoPesq)       // Retorna a primeira ocorrência da palavra MENSAGEM (CODIGOMENSAGEM:).
                     _nI := At("MENSAGEM",_cTextoPesq,_nI+5) // Retorna a segunda ocorrência da palavra MENSAGEM (MENSAGEM:).

                     _nJ := At("OBJETO",_cTextoPesq)
                     _nNrPos := _nJ - (_nI + 2)
                     _cTextoMsg := AllTrim(SubStr(_cResult,_nI, _nNrPos))

                     If Upper(AllTrim(_cTextoMsg)) <> "MENSAGEM:" // Contem mensagem
                        _nI := At(":",_cTextoMsg)
                        _nJ := Len(_cTextoMsg)
                        _nNrPos := _nJ - (_nI + 1)

                        _cTextoMsg := AllTrim(SubStr(_cTextoMsg, _nI+1, _nNrPos))
                     Else
                        _cTextoMsg := "" // A TAG Mensagem está vazia.
                     EndIf
                  EndIf

                  _cResposta := ""
                  _cSituacao := "P" // "Importado Com Sucesso"
                  _cCodRast  := ""
                  _cRespTxt  := StrTran(_cResult,Chr(13)+Chr(10),"")
                  _cRespTxt  := StrTran(_cResult,Chr(10),"")

                  If _cCodMsg == "200" // Integrado com Sucesso

                     //_nI := At("RASTREAMENTOPEDIDO",_cTextoPesq)
                     //_nJ := At("REMETENTE",_cTextoPesq)
                     //protocoloIntegracaoPedido
                     _nI := At("PROTOCOLOINTEGRACAOPEDIDO",_cTextoPesq)
                     _nJ := At("STATUS",_cTextoPesq)
                     _nNrPos := 1

                     _cCodRast := ""
                     If _nI > 0 .And. _nJ >0
                        _nNrPos := _nJ - _nI

                        _cRastreador := AllTrim(SubStr(_cResult,_nI, _nNrPos))

                        _cTextoPesq := Upper(_cRastreador)
                        _nJ := Len(AllTrim(_cTextoPesq))

                        //_nI := At("ENTREGA",_cTextoPesq)
                        _nI := At(":",_cTextoPesq)
                        _nNrPos := _nJ - (_nI + 1)
                        _cCodRast := AllTrim(SubStr(_cRastreador,_nI+1,_nNrPos))
                     EndIf

                     _cResposta := "Integrado com Sucesso - Nenhum problema encontrado, a requisição foi processada e retornou dados"

                  ElseIf _cCodMsg == "300" // Dados Inválidos
                     //_cSituacao := "R"
                     _cSituacao := "N"
                     _cResposta := "Dados Inválidos - " + AllTrim(_cRespTxt) // "Dados Inválidos - Algum dado da requisição não é válido, ou está faltando"

                  ElseIf _cCodMsg == "400" // Falha Interna Web Service
                     _cSituacao := "N"
                     _cResposta := "Falha Interna Web Service - " + AllTrim(_cRespTxt) // "Falha Interna Web Service - Erro interno no processamento. Caso seja persistente, contatar o suporte da MultiSoftware"

                  ElseIf _cCodMsg == "500" // Duplicidade na Requisição
                     //_cSituacao := "P"
                     _cSituacao := "N"
                     _cResposta := "Duplicidade na Requisição - " + AllTrim(_cRespTxt)  // "Duplicidade na Requisição - A requisição já foi feita, ou o registro já foi inserido anteriormente"

                  Else
                     _cSituacao := "N"
                     _cResposta := AllTrim(StrTran(_cResult,Chr(10)," "))
                     _cResposta := Upper(_cResposta)
                  EndIf

                  If ! Empty(_cTextoMsg)
                     _cResposta := _cResposta + " " + _cTextoMsg
                  EndIf

                   //grava resultado // sempre como processado

                   ZFQ->(RecLock("ZFQ",.F.))
                  ZFQ->ZFQ_SITUAC  := _cSituacao // IIf(_cok, "P", "N")

                  ZFQ->ZFQ_DATAAL  := Date()
                  ZFQ->ZFQ_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não.
                  ZFQ->ZFQ_XML     := _cXML
                  ZFQ->ZFQ_XMLRET  := _cResult
                  ZFQ->ZFQ_RASTMS  := _cCodRast
                  ZFQ->ZFQ_DATAP   := Date()
                  ZFQ->ZFQ_HORAP   := Time()
                  ZFQ->(MSUnLock())

                  _lfalha := .F.  //Verifica se tem falha de processamento no Loop a seguir

                  For _nI := 1 To Len(_aRecnoItem)
                      ZFR->(DBGoTo(_aRecnoItem[_nI]))

                      ZFR->(RecLock("ZFR",.F.))
                      ZFR->ZFR_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
                      ZFR->ZFR_DATAAL  := Date()
                      ZFR->ZFR_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não.
                      ZFR->(MSUnLock())
                  Next

                  If _cSituacao == "P"
                     SC5->(RecLock("SC5",.F.))
                     SC5->C5_I_ENVRD := "S"
                     SC5->C5_I_CDTMS := _cCodRast //SC5->C5_RASTMS  := _cCodRast   // Código de rastreamento
                     SC5->(MSUnLock())
                     SC5->(MSUnLockall())
                     U_Itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' enviado para multi-embarcador ...' )
                  Else
                     SC5->(MSUnLock())
                     SC5->(MSUnLockall())
                     U_Itconout( '[AOMS084] -  - Pedido ' + ZFQ->ZFQ_PEDIDO + ' falhou envio para multi-embarcador ...' )
                  EndIf

                  aAdd(_aresult,{ZFQ->ZFQ_PEDIDO,ZFQ->ZFQ_CNPJEM,ZFQ->ZFQ_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
                  Sleep(100) //Espera para não travar a comunicação com o webservice da MULTI-EMBARCADOR
               EndIf
            EndIf
         End Transaction
         SC5->(MSRUNLOCK(SC5->(Recno())))
      EndIf

      TRBZFQ->(DBSkip())
   EndDo

   _aCabecalho := {}
   aAdd(_aCabecalho,"PEDIDO" )
   aAdd(_aCabecalho,"CNPJ")
   aAdd(_aCabecalho,"RETORNO")

   _cTitulo := "Resultados da integração"

   If Len(_aresult) > 0 .And. !_lScheduler
      U_ITListBox( _cTitulo , _aCabecalho , _aresult  ) // Exibe uma tela de resultado.
     EndIf

End Sequence

RestOrd(_aOrd)

Return
