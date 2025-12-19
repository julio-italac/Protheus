#Include "TOTVS.ch"
#Include "TBICONN.CH"
#Include "FWPrintSetup.ch"
#Include "PARMTYPE.CH"

/*
===============================================================================================================================
Função-------------: MGLT032
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de integração WebService Italac x Evomilk. Chamado 48915.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032(_lSchedule)

Local _lEnvDadoP := .T.
Local _lEnvDadoC := .T.
Local _lEnvDadoS := .T.
Local _lEnvDadoE := .T.
Local _lEnvDadoF := .T.
Local _lEnvDadoG := .T.
Local _lEnvDadoH := .T.
Local _lEnvDadoI := .T.

Private _lHaDadosP   := .F. // Indica se há dados dos produtores para Integração.
Private _lHaDadosC   := .F. // Indica se há dados das coleta para Integração.
Private _lHaDadosE   := .F. // Indica se há dados das coletas excluidas.
Private _nTotRegs    := 0
Private _aDadosTC    := {}   // Código e Loja de Produtores Titulares de Tanques coletivos já lidos do cadastro de produtores.
Private _cUnidVinc   := SM0->M0_CGC // Unidade na qual os produtores e coletas estão vinculados.
Private _lJaTemAss   := .F.
Private _cCodEvoMilk := "EVOMKT" // Cadastro direcionado para links de testes.
Private _nAceitos    := 0
Private _nRejeitados := 0
Private _lEfetivaEnvio:=totvs.framework.environment.Type.get() == '1' .Or. FWGetRunSchedule()//1-Produção, 2-Homologação,3-Desenvolvimento

Default _lSchedule := .F.

Begin Sequence

   // Envia Dados de Inclusões de Associação / Cooperativa
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados de inclusão das Associações / Cooperativas para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoS := .F.
      Else
         _lEnvDadoS := .T.
      EndIf
   Else
      U_ItConOut("[MGLT032] Enviando dados de inclusão das Associações / Cooperativas para o sistema da Evomilk")
   EndIf

   If ! _lSchedule
      If _lEnvDadoS
         ProcRegua(0)

         Processa( {|| U_MGLT032P(_lSchedule,"INCASS") } , 'Aguarde!' , 'Lendo dados das Associações / Cooperativa...' )

         If _lHaDadosP
            Processa( {|| U_MGLT032K("M","INCASS")} , 'Aguarde!' , 'Enviando dados das Associações / Cooperativas...' )
         EndIf

         U_ITMsg("Envio dos dados das Associações / Cooperativas para o sistema Evomilk Concluido.","Atenção",,2)
      EndIf
   Else
      U_MGLT032P(_lSchedule,"INCASS")  // Faz a leitura dos dados.
      If _lHaDadosP
          U_MGLT032K("S","INCASS")// Envia os dados dos Produtores via Integração WebService.
      EndIf

      U_ItConOut("[MGLT032] - Envio dos dados das Associações / Cooperativas para o sistema Evomilk Concluido.")
   EndIf

   // Envia Dados de Alteração de Associação / Cooperativa
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados de alteração das Associações / Cooperativas para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoS := .F.
      Else
         _lEnvDadoS := .T.
      EndIf
   Else
      U_ItConOut("[MGLT032] Enviando dados de alterações das Associações / Cooperativas para o sistema da Evomilk")
   EndIf

   If ! _lSchedule
      If _lEnvDadoS
         ProcRegua(0)

         Processa( {|| U_MGLT032P(_lSchedule,"ALTASS") } , 'Aguarde!' , 'Lendo dados das Associações / Cooperativa...' )

         If _lHaDadosP
            //Processa( {|| U_MGLT32UP("M","ALTASS")} , 'Aguarde!' , 'Enviando dados das Associações / Cooperativas...' )
            Processa( {|| U_MGLT032K("M","ALTASS")} , 'Aguarde!' , 'Enviando dados das Associações / Cooperativas...' )
         EndIf

         U_ITMsg("Envio dos dados das Associações / Cooperativas para o sistema Evomilk Concluido.","Atenção",,2)
      EndIf
   Else
      U_MGLT032P(_lSchedule,"ALTASS")  // Faz a leitura dos dados.
      If _lHaDadosP
          U_MGLT032K("S","ALTASS") // Envia os dados dos Produtores via Integração WebService.
      EndIf

      U_ItConOut("[MGLT032] - Envio dos dados das Associações / Cooperativas para o sistema Evomilk Concluido.")
   EndIf

   // Envia Dados dos Produtores - INCLUSÃO DE PRODUTORES.
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados de INCLUSÃO dos produtores para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoP := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoP

         _nTotRegs   := 0
         _cLidos     := ""
         _cLeuCapa   := ""
         _cLeuItens  := ""
         _nAceitos   := 0
         _nRejeitados:= 0

         Processa( {|| U_MGLT032P(_lSchedule,"I") } , 'Aguarde!' , 'Lendo dados dos Produtores...' )

         If _lHaDadosP  .And. U_ITMsg("Confirma o envio dos dados de INCLUSÃO dos produtores para o sistema da Evomilk?","Atenção" ,"Lidos: "+_cLidos+ " - Capa: "+_cLeuCapa+" - Detalhes "+_cLeuItens,3,2, 2)

            Processa( {|| U_MGLT032Q("M","I") } , 'Aguarde!' , 'Enviando dados dos Produtores...' ) //INCLUSÃO -  Envia os dados dos Produtores via Integração WebService. INCLUSÃO

            _cResultado:=" - Aceitos: "+AllTrim(Str(_nAceitos))+" - Rejeitados: "+AllTrim(Str(_nRejeitados))

            U_ITMsg("Envio dos dados dos Produtores para o sistema Evomilk CONCLUIDO.","Atenção","Lidos: "+_cLidos+ " - Capa: "+_cLeuCapa+" - Detalhes "+_cLeuItens+_cResultado,2)

         ElseIf !_lHaDadosP

            U_ITMsg("Não tem Produtores para processar.","Atenção",,1)

         EndIf

      EndIf
   Else
      U_MGLT032P(_lSchedule,"I")  // Faz a leitura dos dados.
      If _lHaDadosP
         U_MGLT032Q("S","I") //INCLUSÃO -  Envia os dados dos Produtores via Integração WebService. INCLUSÃO
      EndIf

   EndIf

   // Envia Dados dos Produtores - ALTERAÇÃO DE PRODUTORES.
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados de ALTERAÇÃO dos produtores para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoP := .F.
      Else
         _lEnvDadoP := .T.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoP
         ProcRegua(0)

         _nTotRegs   := 0
         _cLidos     := ""
         _cLeuCapa   := ""
         _cLeuItens  := ""
         _nAceitos   := 0
         _nRejeitados:= 0

         Processa( {|| U_MGLT032P(_lSchedule,"A") } , 'Aguarde!' , 'Lendo dados dos Produtores...' )

         If _lHaDadosP .And. U_ITMsg("Confirma o envio dos dados de ALTERAÇÃO dos produtores para o sistema da Evomilk?","Atenção" ,"Lidos: "+_cLidos+ " - Capa: "+_cLeuCapa+" - Detalhes "+_cLeuItens,3,2, 2)

            Processa( {|| U_MGLT032Q("M","A") } , 'Aguarde!' , 'Enviando dados dos Produtores...' ) //ALTERAÇÃO - Envia os dados dos Produtores via Integração WebService.

            _cResultado:=" - Aceitos: "+AllTrim(Str(_nAceitos))+" - Rejeitados: "+AllTrim(Str(_nRejeitados))

            U_ITMsg("Envio dos dados dos Produtores para o sistema Evomilk CONCLUIDO.","Atenção","Lidos: "+_cLidos+ " - Capa: "+_cLeuCapa+" - Detalhes "+_cLeuItens+_cResultado,2)

         ElseIf !_lHaDadosP

            U_ITMsg("Não tem Produtores para processar.","Atenção",,1)

         EndIf
 
      EndIf
   Else
      U_MGLT032P(_lSchedule,"A")  // Faz a leitura dos dados.
      If _lHaDadosP
         U_MGLT032Q("S","A") //ALTERAÇÃO -  Envia os dados dos Produtores via Integração WebService.
      EndIf

   EndIf

   // ENVIA DADOS DOS VOLUMES COLETADOS.
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados das coletas de leite para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoC := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoC
         ProcRegua(0)

         _nTotRegs   := 0
         _cLidos     := ""
         _cLeuVol    := ""
         _nAceitos   := 0
         _nRejeitados:= 0

         Processa( {|| U_MGLT032V(_lSchedule) } , 'Aguarde!' , 'Lendo dados das Coletas de Leite...' )
         If _lHaDadosC
            Processa( {|| U_MGLT032R("M") } , 'Aguarde!' , 'Enviando dados das Coletas de Leite...' ) // Envia os dados dos Produtores via Integração WebService.
         EndIf

         _cResultado:="Aceitos: "+AllTrim(Str(_nAceitos))+" - Rejeitados: "+AllTrim(Str(_nRejeitados))

         U_ITMsg("Envio dos dados dos Coletas de Leite para o sistema Evomilk CONCLUIDO.","Atenção","Lidos: "+_cLidos+ " - Volume: "+_cLeuVol+" - Detalhes: "+_cResultado,2)

      EndIf
   Else
      U_MGLT032V(_lSchedule)  // Faz a leitura dos dados.
      If _lHaDadosC
         U_MGLT032R("S") // Envia os dados das Coletas via Integração WebService.
      EndIf
   EndIf

   // ENVIA DADOS PARA EXCLUSÃO DOS VOLUMES COLETADOS.
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados de solicitação de exclusao das coletas de leite para o sistema da Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoE := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoE
         ProcRegua(0)

         _nTotRegs   := 0
         _cLidos     := ""
         _cLeuVol    := ""
         _nAceitos   := 0
         _nRejeitados:= 0

         Processa( {|| U_MGLT032C(_lSchedule) } , 'Aguarde!' , 'Lendo dados das Coletas de Leite Excluidas ...' )
         If _lHaDadosE
            Processa( {|| U_MGLT032D("M") } , 'Aguarde!' , 'Enviando dados das Coletas de Leite Excluidas...' ) // Envia os dados dos Produtores via Integração WebService.
         EndIf

         _cResultado := "Aceitos: "+AllTrim(Str(_nAceitos))+" - Rejeitados: "+AllTrim(Str(_nRejeitados))

         U_ITMsg("Envio dos dados de Exclusão das Coletas de Leite para o sistema Evomilk CONCLUIDO.","Atenção","Lidos: "+_cLidos+ " - Volume: "+_cLeuVol+" - Detalhes: "+_cResultado,2)

      EndIf
   Else
      U_MGLT032C(_lSchedule)  // Faz a leitura dos dados.
      If _lHaDadosC
         U_MGLT032D("S") // Envia os dados das Coletas de Leite Excluidas via Integração WebService.
      EndIf
   EndIf

   // Grava os dados das Notas Fiscais em Tabela de Muro para Envio a Evomilk
   If ! _lSchedule
      If ! U_ITMsg("Confirma a leitura e gravação dos dados de notas fiscais para envio para a Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoF := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoF
         ProcRegua(0)

         Processa( {|| U_MGL32LNF() } , 'Aguarde!' , 'Lendo e Gravando dados das Notas Fiscais para Envio a Evomilk...' )
      EndIf
   EndIf

   // Transmite os dados das Notas Fiscais gravados em Tabela de Muro para o Sistema Evomilk.
   If ! _lSchedule
      If ! U_ITMsg("Confirma a transmissão dos dados de notas fiscais para o sistema Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoG := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoG
         ProcRegua(0)

         Processa( {|| U_MGL32TNF() } , 'Aguarde!' , 'Transmitindo os dados das Notas Fiscais para Envio a Evomilk...' )
      EndIf
   EndIf

   // Grava os dados dos Extratos/Demonstrativos em Tabela de Muro para Envio a Evomilk
   If ! _lSchedule
      If ! U_ITMsg("Confirma a leitura e gravação dos dados de Extratos/Demonstrativos para envio para a Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoH := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoH
         ProcRegua(0)

         Processa( {|| U_MGL32LEX() } , 'Aguarde!' , 'Lendo e Gravando dados de Extratos/Demonstrativos para Envio a Evomilk...' )
      EndIf
   EndIf

   // Transmite os dados dos Extratos/Demonstrativos gravados em Tabela de Muro para o Sistema Evomilk.
   If ! _lSchedule
      If ! U_ITMsg("Confirma a transmissão dos dados de Extratos/Demonstrativos para o sistema Evomilk?","Atenção" , , ,2, 2)
         _lEnvDadoI := .F.
      EndIf
   EndIf

   If ! _lSchedule
      If _lEnvDadoI
         ProcRegua(0)

         Processa( {|| U_MGL32TEX() } , 'Aguarde!' , 'Transmitindo os dados dos Extratos/Demonstrativos para o sistema Evomilk...' )
      EndIf
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032P
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de envio de dados dos produtores integração WebService para  Evomilk
Parametros---------: _lSchedule = .T. = Rotina chamada via Scheduller.
                                  = .F. = Rotina chamada via menu.
                     _cOpcao      = "I" = Roda a integração de Inclusão de produtores no App Evomilk.
                                  = "A" = Roda a integração de Alteração de produtores no App Evomilk.
                                  = "INCASS" = Inclusão de Produtores de Associação ou Cooperativa
                                  = "ALTASS" = Alteração de Produtores de Associação ou Cooperativa
                                  = "REENVASS"   = Reenvia todas as associações/Cooperativas por filial
                                  = "PRD_COMUM"  = Reenvia produtores informando código e loja
                                  = "ASS_CODIGO_LOJA" = Reenvia Associação/Cooperativa informando código e loja.
                                  = "ASS_CNPJ"   = Reenvia Associação/Cooperativa informando o CNPJ.
                                  = "SETOR"      = Reenvia produtores comuns por setor.
                     _cCodProd    = Código do Produtor
                     _cLojaProd   = Loja do Produtor
                     _cCnpjProd   = CNPJ do Produtor
                     _cSetor      = Setor do Produtor
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032P(_lScheduller,_cOpcao,_cCodProd,_cLojaProd,_cCnpjProd,_cSetor)

Local _aStruct := {}
Local _aStruct2 := {}
Local _aStruct3 := {}
Local _cCodForn, _cLojaForn
Local _cFilEnvio := xFilial("ZL3")
Local _lNovoGrupo := .T.

Default _lSchedule := .F.
Default _cOpcao := "I"

Begin Sequence

   If ! _lSchedule
      IncProc("Gerando dados dos Produtores para envio...")
   EndIf

   // Cria Tabela Temporária para atualização do SA2
   _aStruct3 := {}
   aAdd(_aStruct3,{"A2_COD"    ,"C",6  ,0})  // matricula_laticinio: TESTE_278363
   aAdd(_aStruct3,{"A2_LOJA"   ,"C",4  ,0})  // Loja_laticinio: TESTE_278363
   aAdd(_aStruct3,{"A2_L_FAZEN","C",60 ,0})  // Nome da Fazenda
   aAdd(_aStruct3,{"WK_RECNO"  ,"N",10 ,0})  // Nr Recno SA2

   If Select("TRBSA2") > 0
      TRBSA2->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCABA criado dentro do banco de dados protheus.
   _oTemp := FWTemporaryTable():New( "TRBSA2",  _aStruct3 )

   // Cria os indices para o arquivo.
   _oTemp:AddIndex( "01", {"A2_COD","A2_LOJA"} )
   _oTemp:Create()

   DBSelectArea("TRBSA2")

   // Cria Tabela Temporária para armazenar dados do JSon
   _aStruct := {}
   aAdd(_aStruct,{"A2_COD"    ,"C",6  ,0})  // matricula_laticinio:
   aAdd(_aStruct,{"A2_LOJA"   ,"C",4  ,0})  // Loja_laticinio:
   aAdd(_aStruct,{"A2_NOME"   ,"C",40 ,0})  // nome_razao_social
   aAdd(_aStruct,{"A2_CGC"    ,"C",14 ,0})  // cpf_cnpj: 349.812.172-34
   aAdd(_aStruct,{"A2_INSCR"  ,"C",18 ,0})  // inscricao_estadual:
   aAdd(_aStruct,{"A2_PFISICA","C",18 ,0})  // rg_ie: ABC320303
   aAdd(_aStruct,{"A2_DTNASC" ,"D",8  ,0})  // data_nascimento_fundacao: 1994-10-10
   aAdd(_aStruct,{"WK_OBSERV" ,"C",100,0})  // info_adicional: Observação / info adicional...
   aAdd(_aStruct,{"A2_ENDCOMP","C",50 ,0})  // complemento:
   aAdd(_aStruct,{"A2_END"    ,"C",90 ,0})  // endereco
   aAdd(_aStruct,{"WK_NUMERO" ,"C",20 ,0})  // numero
   aAdd(_aStruct,{"A2_BAIRRO" ,"C",50 ,0})  // bairro
   aAdd(_aStruct,{"A2_CEP"    ,"C",8  ,0})  // cep
   aAdd(_aStruct,{"WK_ID_UF"  ,"C",2  ,0})  // id_uf: 21
   aAdd(_aStruct,{"A2_COD_MUN","C",5  ,0})  // id_cidade: 73
   aAdd(_aStruct,{"A2_MUN"    ,"C",50 ,0})  // municipio
   aAdd(_aStruct,{"A2_EST"    ,"C",2  ,0})  // estado
   aAdd(_aStruct,{"A2_BANCO"  ,"C",3  ,0})  // codigo do banco
   aAdd(_aStruct,{"A2_AGENCIA","C",5  ,0})  // codigo da agencia
   aAdd(_aStruct,{"A2_NUMCON" ,"C",12 ,0})  // numero da conta
   aAdd(_aStruct,{"A2_EMAIL"  ,"C",100,0})  // email
   aAdd(_aStruct,{"A2_DDD"    ,"C",3,0})    // celular1: 95920298034
   aAdd(_aStruct,{"A2_TEL"    ,"C",50,0})   // celular1: 95920298034
   aAdd(_aStruct,{"A2_TEL2"   ,"C",50,0})   // celular2: null
   aAdd(_aStruct,{"A2_TEL3"   ,"C",50,0})   // telefone1: 5590038949
   aAdd(_aStruct,{"A2_TEL4"   ,"C",50,0})   // telefone2: null
   aAdd(_aStruct,{"A2_TEL1W"  ,"C",50,0})   // celular1_whatsapp: true
   aAdd(_aStruct,{"A2_TEL2W"  ,"C",50,0})   // celular2_whatsapp: false
   aAdd(_aStruct,{"WK_TIPOPRO","C",10 ,0})  // ASSOCIACAO/ASSOCIADO
   aAdd(_aStruct,{"A2_L_TPASS","C",1  ,0})  // Tipo Associação
   aAdd(_aStruct,{"WK_ORDEMP" ,"C",1 ,0})   // Ordenação Produtor para envio.
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Nr Recno SA2
   aAdd(_aStruct,{"A2_L_ATIVO","C",10 ,0})  // situacao  // Ativo / Inativo
   aAdd(_aStruct,{"A2_L_NFPRO","C",1 ,0})   // laticinio_emite_nf 
   aAdd(_aStruct,{"A2_NREDUZ" ,"C",20 ,0})  // nome 
  
   If Select("TRBCAB") > 0
      TRBCAB->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp := FWTemporaryTable():New( "TRBCAB",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp:AddIndex( "01", {"A2_COD"} )
   _oTemp:AddIndex( "02", {"A2_CGC"} )
   _oTemp:AddIndex( "03", {"WK_ORDEMP","A2_COD","A2_LOJA"} )
   _oTemp:Create()

   DBSelectArea("TRBCAB")

   _aStruct2 := {}
   aAdd(_aStruct2,{"A2_COD"    ,"C",6  ,0})  // matricula_laticinio: TESTE_278363
   aAdd(_aStruct2,{"A2_LOJA"   ,"C",4  ,0})  // Loja_laticinio: TESTE_278363
   aAdd(_aStruct2,{"A2_CGC"    ,"C",14 ,0})  // cpf_cnpj: 349.812.172-34
   aAdd(_aStruct2,{"A2_L_FAZEN","C",40 ,0})  // nome_propriedade_rural: PROPRIEDADE TESTE 001
   aAdd(_aStruct2,{"A2_L_NIRF" ,"C",11 ,0})  // NIRF: ABC4658
   aAdd(_aStruct2,{"A2_L_TANQ" ,"C",6  ,0})  // id_tipo_tanque: 1
   aAdd(_aStruct2,{"A2_L_TANLJ","C",4  ,0})  // Loja Tanque
   aAdd(_aStruct2,{"A2_L_CAPTQ","N",11 ,0})  // capacidade_tanque: 720
   aAdd(_aStruct2,{"A2_L_LATIT","N",10 ,6})  // latitude_propriedade: -17.855250
   aAdd(_aStruct2,{"A2_L_LONGI","N",10 ,6})  // longitude_propriedade: -46.223278
   aAdd(_aStruct2,{"A2_L_MARTQ","C",20 ,0})  // Marca do Tanque
   aAdd(_aStruct2,{"A2_L_CLASS","C",01 ,0})  // id_tipo_tanque
   aAdd(_aStruct2,{"A2_L_LI_RO","C",06 ,0})  // Código_Linha_Rota
   aAdd(_aStruct2,{"ZL3_DESCRI","C",40 ,0})  // Descrição_Linha_Rota
   aAdd(_aStruct2,{"WK_AREA"   ,"N",12 ,6})  // area: 2000.15
   aAdd(_aStruct2,{"WK_RECRIA" ,"C",10 ,0})  // recria: 1
   aAdd(_aStruct2,{"WK_VACASEC","C",10 ,0})  // vaca_seca: 12
   aAdd(_aStruct2,{"WK_VACALAC","C",10 ,0})  // vaca_lactacao: 6
   aAdd(_aStruct2,{"WK_HORACOL","C",10 ,0})  // horario_coleta: 23:59
   aAdd(_aStruct2,{"WK_RACAPRO","C",50 ,0})  // raca_propriedade: Nome Raça predominante Teste
   aAdd(_aStruct2,{"A2_L_FREQU","C",10 ,0})  // frequencia_coleta: 17
   aAdd(_aStruct2,{"WK_PRDDIAR","N",10 ,2})  // fproducao_media_diaria: 7251.31
   aAdd(_aStruct2,{"WK_AREAUTI","N",10 ,2})  // area_utilizada_producao: 837.84
   aAdd(_aStruct2,{"A2_L_CAPAC","C",01 ,0})  // capacidade_refrigeracao: 307
   aAdd(_aStruct2,{"A2_L_ATIVO","C",10 ,0})  // situacao  // Ativo / Inativo
   aAdd(_aStruct2,{"A2_L_SIGSI","C",11 ,0})  // SigSif
   aAdd(_aStruct2,{"A2_L_RESFR","C",1  ,0})  // id_tab_tanque_tipo_resfriamento
   aAdd(_aStruct2,{"A2_ENDCOMP","C",50 ,0})  // complemento: Complemento Teste
   aAdd(_aStruct2,{"A2_END"    ,"C",90 ,0})  // endereco: Rua Caminho Andante
   aAdd(_aStruct2,{"WK_NUMERO" ,"C",20 ,0})  // numero: 429 A
   aAdd(_aStruct2,{"A2_BAIRRO" ,"C",50 ,0})  // bairro: Bairro Teste
   aAdd(_aStruct2,{"A2_CEP"    ,"C",8  ,0})  // cep: 51462-745
   aAdd(_aStruct2,{"A2_COD_MUN","C",5  ,0})  // id_cidade: 73
   aAdd(_aStruct2,{"A2_MUN"    ,"C",50 ,0})  // municipio
   aAdd(_aStruct2,{"A2_EST"    ,"C",2  ,0})  // estado
   aAdd(_aStruct2,{"A2_EMAIL"  ,"C",100,0})  // email: TESTE_278363@email.com
   aAdd(_aStruct2,{"A2_DDD"    ,"C",3  ,0})  // celular1: 95920298034
   aAdd(_aStruct2,{"A2_TEL"    ,"C",50 ,0})  // celular1: 95920298034
   aAdd(_aStruct2,{"A2_L_NATRA","C",50 ,0})  // Nome Atravessador
   aAdd(_aStruct2,{"A2_L_TPASS","C",1 ,0})   // Tipo Associação
   aAdd(_aStruct2,{"WK_TIPOPRO","C",10 ,0})  // ASSOCIACAO/ASSOCIADO
   aAdd(_aStruct2,{"A2_L_NFPRO","C",1  ,0})  // laticinio_emite_nf 
   aAdd(_aStruct2,{"A2_NREDUZ" ,"C",20 ,0})  // nome 
   aAdd(_aStruct2,{"WK_ORDEMP" ,"C",1  ,0})  // Ordenação Produtor para envio.
   aAdd(_aStruct2,{"WK_RECNO"  ,"N",10 ,0})  // Nr Recno SA2
   aAdd(_aStruct2,{"WK_REGCAB" ,"N",10 ,0})  // Nr Recno TRBCAB

   If Select("TRBDET") > 0
      TRBDET->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBDET criado dentro do banco de dados protheus.
   _oTemp2 := FWTemporaryTable():New( "TRBDET",  _aStruct2 )

   // Cria os indices para o arquivo.
   _oTemp2:AddIndex( "01", {"A2_COD"})
   _oTemp2:AddIndex( "02", {"A2_COD","A2_LOJA"})
   _oTemp2:AddIndex( "03", {"A2_CGC"})
   _oTemp2:AddIndex( "04", {"WK_ORDEMP","A2_COD","A2_LOJA"} )
   _oTemp2:Create()

   DBSelectArea("TRBDET")

   // Monta select de leitura de dados do cadastro de Produtores rurais.
   _cQry := " SELECT DISTINCT A2_COD, "  // matricula_laticinio: TESTE_278363
   _cQry += " A2_NOME, "                 // nome_razao_social  : PRODUTOR TESTE 3337
   _cQry += " A2_CGC, "                  // cpf_cnpj: 349.812.172-34
   _cQry += " A2_INSCR, "                // inscricao_estadual: 170642
   _cQry += " A2_PFISICA, "              // rg_ie: ABC320303
   _cQry += " A2_DTNASC, "               // data_nascimento_fundacao: 1994-10-10
   _cQry += " A2_ENDCOMP, "              // complemento: Complemento Teste
   _cQry += " A2_END, "                  // endereco: Rua Caminho Andante
   _cQry += " A2_BAIRRO, "               // bairro: Bairro Teste
   _cQry += " A2_CEP, "                  // cep: 51462-745
   _cQry += " A2_COD_MUN, "              // id_cidade: 73
   _cQry += " A2_MUN, "                  // municipio
   _cQry += " A2_EST, "                  // estado
   _cQry += " A2_EMAIL, "                // email: TESTE_278363@email.com
   _cQry += " A2_DDD, "                  // DDD
   _cQry += " A2_TEL, "                  // celular1: 95920298034
   _cQry += " A2_LOJA, "                 // Loja_laticinio: TESTE_278363
   _cQry += " A2_BANCO, "                // codigo do banco
   _cQry += " A2_AGENCIA, "              // codigo da agencia
   _cQry += " A2_NUMCON, "               // numero da conta
   _cQry += " A2_L_FAZEN, "              // nome_propriedade_rural: PROPRIEDADE TESTE 001
   _cQry += " A2_L_NIRF, "               // NIRF: ABC4658
   _cQry += " A2_L_TANQ, "               // id_tipo_tanque: 1
   _cQry += " A2_L_CAPTQ, "              // capacidade_tanque: 720
   _cQry += " A2_L_LATIT, "              // latitude_propriedade: -17.855250
   _cQry += " A2_L_LONGI, "              // longitude_propriedade: -46.223278
   _cQry += " A2_L_FREQU, "              // frequencia_coleta: 17
   _cQry += " A2_L_MARTQ, "              // Marca do Tanque
   _cQry += " A2_L_CAPAC, "              // capacidade_refrigeracao: 307
   _cQry += " A2_L_CLASS, "              // id_tipo_tanque
   _cQry += " A2_L_ATIVO, "              // ativo inativo
   _cQry += " A2_L_SIGSI, "              //
   _cQry += " A2_L_TANLJ, "              //
   _cQry += " A2_L_RESFR, "              //
   _cQry += " A2_L_NATRA, "              // Nome Atravessador
   _cQry += " A2_L_TPASS, "              // Tipo Associação
   _cQry += " A2_L_NFPRO, "              // laticinio_emite_nf
   _cQry += " A2_NREDUZ,  "              // nome
   _cQry += " A2_L_LI_RO, "
   _cQry += " ZL3_DESCRI, "
   _cQry += " SA2.R_E_C_N_O_ AS NRREG, "
   _cQry += " Case "
   _cQry += "     WHEN A2_L_CLASS = 'C' THEN 'B' "
   _cQry += "     WHEN A2_L_CLASS = 'U' THEN 'C' "
   _cQry += "     WHEN A2_L_CLASS = 'F' THEN 'D' "
   _cQry += "     Else 'A' "
   _cQry += " END AS ORDEMP"
   If _cOpcao == "SETOR"     // Reenvia produtores comuns por setor.
      _cQry += " FROM " + RetSqlName("SA2") + " SA2, " + RetSqlName("ZL3") + " ZL3, " + RetSqlName("ZL2") + " ZL2 "  
      _cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND ZL3.D_E_L_E_T_ = ' ' AND ZL2.D_E_L_E_T_ = ' ' "
      _cQry += " AND ZL3_FILIAL = ZL2_FILIAL AND ZL3_SETOR = ZL2_COD "    
      _cQry += " AND ZL2_COD = '" + _cSetor + "' "
   Else 
   _cQry += " FROM " + RetSqlName("SA2") + " SA2, " + RetSqlName("ZL3") + " ZL3 "
   _cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND ZL3.D_E_L_E_T_ = ' ' "
   EndIf 
   _cQry += " AND ZL3_COD = A2_L_LI_RO "

   _cQry += " AND ZL3_FILIAL = '" + _cFilEnvio + "' " // Cada filial/Cnpj Italac possui um Usuário e Senha. Ler do cadastro empresas Webservice. Enviar apenas as filias 01, 04, 23. 01=Corumbaiba/GO, 04=Araguari/MG, 23=Tapejara/RS

   // Inclusão de Produtores
   If _cOpcao == "I"          // Inclusão de Produtores
      _cQry += " AND (SA2.A2_L_ENVEV = ' ' OR  SA2.A2_L_ENVEV = 'S') AND ((SA2.A2_L_NFPRO <> 'S' OR (SA2.A2_L_NFPRO = 'S' AND Length(Trim(SA2.A2_CGC))  < 14 ) ) " // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa não enviar nesta opção.
      _cQry += " OR (SA2.A2_L_NFPRO = 'S' AND SA2.A2_COD IN (SELECT ZLJ_CODPAT
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND ROWNUM <= 2 AND ZLJ.ZLJ_CODPAT = SA2.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2.A2_LOJA AND ZLJ.ZLJ_LOJPAT = '0001')) "
      _cQry += " OR (SA2.A2_L_NFPRO = 'S' AND (SA2.A2_L_TPASS = 'N' OR SA2.A2_L_TPASS = ' '))) "
   // Alteração de Produtores
   ElseIf _cOpcao == "A"      // Alteração de Produtores
      _cQry += " AND  (SA2.A2_L_ENVEV = 'N' AND SA2.A2_L_ENVAT = 'S') AND ((SA2.A2_L_NFPRO <> 'S' OR (SA2.A2_L_NFPRO = 'S' AND Length(Trim(SA2.A2_CGC))  < 14 ) ) "      // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa não enviar nesta opção.
      _cQry += " OR (SA2.A2_L_NFPRO = 'S' AND SA2.A2_COD IN (SELECT ZLJ_CODPAT
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND ROWNUM <= 2 AND ZLJ.ZLJ_CODPAT = SA2.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2.A2_LOJA AND ZLJ.ZLJ_LOJPAT = '0001')) "
      _cQry += " OR (SA2.A2_L_NFPRO = 'S' AND (SA2.A2_L_TPASS = 'N' OR SA2.A2_L_TPASS = ' '))) "
   // Inclusão de Associação / Cooperativa
   ElseIf _cOpcao == "INCASS" // Inclusão de Associação / Cooperativa
      _cQry += " AND (SA2.A2_L_ENVEV = ' ' OR SA2.A2_L_ENVEV = 'S') AND SA2.A2_L_NFPRO = 'S' AND   Length(Trim(SA2.A2_CGC))  = 14 "  // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa.
      _cQry += " AND SA2.A2_COD NOT IN (SELECT ZLJ_CODPAT
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2_AS "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2_AS.D_E_L_E_T_ = ' ' AND ZLJ.ZLJ_CODPAT = SA2_AS.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2_AS.A2_LOJA " 
      _cQry += " AND SA2_AS.A2_L_ATIVO = 'S' AND ROWNUM <= 2 AND ZLJ.ZLJ_CODPAT = SA2.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2.A2_LOJA AND ZLJ.ZLJ_LOJPAT = '0001' AND SA2.A2_L_TPASS <> 'A' ) "
      _cQry += " AND SA2.A2_L_TPASS <> 'N' "
   // Alteração de Associação / Cooperativa
   ElseIf _cOpcao == "ALTASS" // Alteração de Associação / Cooperativa
      _cQry += " AND  SA2.A2_L_ENVEV = 'N' AND A2_L_ENVAT = 'S' AND SA2.A2_L_NFPRO = 'S' AND   Length(Trim(SA2.A2_CGC))  = 14 "       // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa.
      _cQry += " AND SA2.A2_COD NOT IN (SELECT ZLJ_CODPAT
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2_AS "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2_AS.D_E_L_E_T_ = ' ' AND ZLJ.ZLJ_CODPAT = SA2_AS.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2_AS.A2_LOJA "
      _cQry += " AND SA2_AS.A2_L_ATIVO = 'S' AND ROWNUM <= 2 AND ZLJ.ZLJ_CODPAT = SA2.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2.A2_LOJA AND ZLJ.ZLJ_LOJPAT = '0001') "
      _cQry += " AND SA2.A2_L_TPASS <> 'N' "
   // Reenvio de Associação / Cooperativa 
   ElseIf _cOpcao == "REENVASS" // Reenvio de Associação / Cooperativa
      _cQry += " AND  SA2.A2_L_NFPRO = 'S' AND   Length(Trim(SA2.A2_CGC))  = 14 "  // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa.
      _cQry += " AND SA2.A2_COD NOT IN (SELECT ZLJ_CODPAT
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2_AS "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2_AS.D_E_L_E_T_ = ' ' AND ZLJ.ZLJ_CODPAT = SA2_AS.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2_AS.A2_LOJA AND "
      _cQry += " SA2_AS.A2_L_ATIVO = 'S' AND ROWNUM <= 2 AND ZLJ.ZLJ_CODPAT = SA2.A2_COD AND ZLJ.ZLJ_LOJPAT = SA2.A2_LOJA AND ZLJ.ZLJ_LOJPAT = '0001') "
      _cQry += " AND SA2.A2_L_TPASS <> 'N' "
   ElseIf _cOpcao == "PRD_COMUM" // Reenvia produtores informando código e loja
      _cQry += " AND SA2.A2_COD = '" + _cCodProd + "'  AND SA2.A2_LOJA = '" + _cLojaProd + "'  AND (SA2.A2_L_NFPRO <> 'S' OR (SA2.A2_L_NFPRO = 'S' AND Length(Trim(SA2.A2_CGC))  < 14 ) ) "
   ElseIf _cOpcao == "ASS_CODIGO_LOJA" // Reenvia Associação/Cooperativa informando código e loja.
      _cQry += " AND SA2.A2_COD = '" + _cCodProd + "'  AND SA2.A2_LOJA = '" + _cLojaProd + "'  AND SA2.A2_L_NFPRO = 'S' "
   ElseIf _cOpcao == "ASS_CNPJ"  // Reenvia Associação/Cooperativa informando o CNPJ.
      _cQry += " AND SA2.A2_CGC = '" + _cCnpjProd + "'  AND SA2.A2_L_NFPRO = 'S' " 
   EndIf

   _cQry += " AND A2_I_CLASS = 'P' "

   _cQry += " AND A2_COD <> '      ' " // Foi identificado no cadastro de fornecedores alguns registros sem o código preenchido.
   
   // Enviar as Associações/Cooperados Bloqueados/Ativos e Inativos para termos um Histórico. 
   If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS")
      If _cOpcao == "INCASS" .Or. _cOpcao == "REENVASS"
         //_cQry += " AND A2_L_ATIVO <> 'N' "  // Não Enviar inativos na inclusão. //Enviar todos para histórico no App Evomilk.
      EndIf

      _cQry += " ORDER BY A2_COD,A2_LOJA "
   Else
      _cQry += " ORDER BY ORDEMP, A2_COD,A2_LOJA "
   EndIf

   If Select("QRYSA2") > 0
      QRYSA2->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYSA2")
   DBSelectArea("QRYSA2")
   Count To _nTotRegs

   If !_lSchedule
      ProcRegua(_nTotRegs)
   EndIf
   _cTot:=AllTrim(Str(_nTotRegs))
   _cLidos:= _cTot
   nConta:=0

   _cCodForn := Space(6)
   _cLojaForn := Space(4) 

   QRYSA2->(DBGoTop())

   While ! QRYSA2->(Eof())
      nConta++
      
      If !_lSchedule
         IncProc("Lendo Produtores: "+StrZero(nConta,5) +" de "+ _cTot)
      EndIf

      // Quando um Produtor com CPF está cadastrado com Emite nota Propria igual a
      // Sim, o cadastro está errado. Filtrar este produtor.
      If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS")
         If Len(AllTrim(QRYSA2->A2_CGC)) < 14
            QRYSA2->(DBSkip())
            Loop
         EndIf
      EndIf

      // Mudança de código de Associação / Cooperativa
      If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS")
         _lNovoGrupo := .F.
      EndIf

      // Grava as tabelas temporárias para envio dos dados
      If (_cCodForn <> QRYSA2->A2_COD .Or. _cLojaForn <> QRYSA2->A2_LOJA) .And. _cOpcao <> "ALTASS"
         _cCodForn  := QRYSA2->A2_COD
         _cLojaForn := QRYSA2->A2_LOJA

         TRBCAB->(DBAPPEND())
         TRBCAB->A2_COD     := QRYSA2->A2_COD            // id_tipo_tanque: 1
         TRBCAB->A2_LOJA    := QRYSA2->A2_LOJA
         TRBCAB->A2_NOME    := StrTran(QRYSA2->A2_NOME,'"'," ")  //C,40  // nome_razao_social  : PRODUTOR TESTE 3337
         TRBCAB->A2_CGC     := QRYSA2->A2_CGC            //C,14  // cpf_cnpj: 349.812.172-34
         TRBCAB->A2_INSCR   := QRYSA2->A2_INSCR          //C,18  // inscricao_estadual: 170642
         TRBCAB->A2_PFISICA := QRYSA2->A2_PFISICA        //C,18  // rg_ie: ABC320303
         TRBCAB->A2_DTNASC  := SToD(QRYSA2->A2_DTNASC)   //D,8   // data_nascimento_fundacao: 1994-10-10
         TRBCAB->WK_OBSERV  := ""                        //C,100 // info_adicional: Observação / info adicional...
         TRBCAB->A2_ENDCOMP := StrTran(QRYSA2->A2_ENDCOMP,'"'," ")        //C,50  // complemento: Complemento Teste
         TRBCAB->A2_END     := StrTran(QRYSA2->A2_END,'"'," ")            //C,90  // endereco: Rua Caminho Andante
         TRBCAB->WK_NUMERO  := ""                        //C,20  // numero: 429 A
         TRBCAB->A2_BAIRRO  := StrTran(QRYSA2->A2_BAIRRO,'"'," ")         //C,50  // bairro: Bairro Teste
         TRBCAB->A2_CEP     := QRYSA2->A2_CEP            //C,8   // cep: 51462-745
         TRBCAB->WK_ID_UF   := ""                        //C,2   // id_uf: 21
         TRBCAB->A2_COD_MUN := QRYSA2->A2_COD_MUN        //C,5   // id_cidade: 73
         TRBCAB->A2_MUN     := QRYSA2->A2_MUN            // municipio
         TRBCAB->A2_EST     := QRYSA2->A2_EST            // estado
         TRBCAB->A2_BANCO   := QRYSA2->A2_BANCO          // codigo do banco
         TRBCAB->A2_AGENCIA := QRYSA2->A2_AGENCIA        // codigo da agencia
         TRBCAB->A2_NUMCON  := QRYSA2->A2_NUMCON         // numero da conta
         TRBCAB->A2_EMAIL   := QRYSA2->A2_EMAIL          //C,100 // email: TESTE_278363@email.com
         TRBCAB->A2_TEL     := AllTrim(QRYSA2->A2_DDD)+QRYSA2->A2_TEL //C,50  // celular1: 95920298034
         TRBCAB->A2_TEL2    := ""                        //C,50  // celular2: null
         TRBCAB->A2_TEL3    := ""                        //C,50  // telefone1: 5590038949
         TRBCAB->A2_TEL4    := ""                        //C,50  // telefone2: null
         TRBCAB->A2_TEL1W   := "False"                   //C,50  // celular1_whatsapp: true
         TRBCAB->A2_TEL2W   := "False"                   //C,50  // celular2_whatsapp: false
         TRBCAB->WK_RECNO   := QRYSA2->NRREG             //N,10 ,0 // Nr Recno SA2
         TRBCAB->WK_ORDEMP  := QRYSA2->ORDEMP            // Ordenação dos dados para envio
         TRBCAB->A2_L_ATIVO := If(QRYSA2->A2_L_ATIVO=="N","false","true") // _cSituacao
         TRBCAB->A2_L_TPASS := QRYSA2->A2_L_TPASS        // Tipo Associação
         
         If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS" .Or. _cOpcao == "ASS_CODIGO_LOJA" .Or. _cOpcao == "ASS_CNPJ") 
            If QRYSA2->A2_LOJA == "0001" //Empty(QRYSA2->A2_L_TPASS) .And. QRYSA2->A2_LOJA == "0001"
               TRBCAB->A2_L_TPASS := "A"
               TRBCAB->A2_L_ATIVO := "true" // "ATIVO" // _cSituacao    
            ElseIf QRYSA2->A2_L_TPASS == "A" .And. QRYSA2->A2_LOJA <> "0001"
               TRBCAB->A2_L_TPASS := "C"
            EndIf
         EndIf 

         TRBCAB->A2_L_NFPRO  := QRYSA2->A2_L_NFPRO // laticinio_emite_nf
         TRBCAB->A2_NREDUZ   := QRYSA2->A2_NREDUZ  // nome

         TRBCAB->(MSUnLock())

         _lJaTemAss := U_MGLT29WM(TRBCAB->A2_COD, TRBCAB->A2_LOJA, TRBCAB->A2_CGC) // Retorna se já tem Associação/Cooperativa cadastrada.

         // Mudança de código de Associação / Cooperativa
         If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS" .Or. _cOpcao == "ASS_CODIGO_LOJA" .Or. _cOpcao == "ASS_CNPJ")
            If _cOpcao == "INCASS"
               If ! _lJaTemAss // Se não existir nenhuma associação cadastrada é novo grupo, inclui uma Associação.
                  _lNovoGrupo := .T.
               Else  // Se não existir é um associado.
                  _lNovoGrupo := .F.
               EndIf
            Else
               _lNovoGrupo := .T.
            EndIf
         EndIf

      ElseIf _cOpcao == "ALTASS"

         TRBCAB->(DBAPPEND())
         TRBCAB->A2_COD     := QRYSA2->A2_COD            // id_tipo_tanque: 1
         TRBCAB->A2_LOJA    := QRYSA2->A2_LOJA
         TRBCAB->A2_NOME    := QRYSA2->A2_NOME           //C,40  // nome_razao_social  : PRODUTOR TESTE 3337
         TRBCAB->A2_CGC     := QRYSA2->A2_CGC            //C,14  // cpf_cnpj: 349.812.172-34
         TRBCAB->A2_INSCR   := QRYSA2->A2_INSCR          //C,18  // inscricao_estadual: 170642
         TRBCAB->A2_PFISICA := QRYSA2->A2_PFISICA        //C,18  // rg_ie: ABC320303
         TRBCAB->A2_DTNASC  := SToD(QRYSA2->A2_DTNASC)   //D,8   // data_nascimento_fundacao: 1994-10-10
         TRBCAB->WK_OBSERV  := ""                        //C,100 // info_adicional: Observação / info adicional...
         TRBCAB->A2_ENDCOMP := StrTran(QRYSA2->A2_ENDCOMP,'"'," ")        //C,50  // complemento: Complemento Teste
         TRBCAB->A2_END     := StrTran(QRYSA2->A2_END,'"'," ")            //C,90  // endereco: Rua Caminho Andante
         TRBCAB->WK_NUMERO  := ""                        //C,20  // numero: 429 A
         TRBCAB->A2_BAIRRO  := StrTran(QRYSA2->A2_BAIRRO,'"'," ")         //C,50  // bairro: Bairro Teste
         TRBCAB->A2_CEP     := QRYSA2->A2_CEP            //C,8   // cep: 51462-745
         TRBCAB->WK_ID_UF   := ""                        //C,2   // id_uf: 21
         TRBCAB->A2_COD_MUN := QRYSA2->A2_COD_MUN        //C,5   // id_cidade: 73
         TRBCAB->A2_MUN     := QRYSA2->A2_MUN            // municipio
         TRBCAB->A2_EST     := QRYSA2->A2_EST            // estado
         TRBCAB->A2_BANCO   := QRYSA2->A2_BANCO          // codigo do banco
         TRBCAB->A2_AGENCIA := QRYSA2->A2_AGENCIA        // codigo da agencia
         TRBCAB->A2_NUMCON  := QRYSA2->A2_NUMCON         // numero da conta
         TRBCAB->A2_EMAIL   := QRYSA2->A2_EMAIL          //C,100 // email: TESTE_278363@email.com
         TRBCAB->A2_TEL     := AllTrim(QRYSA2->A2_DDD)+QRYSA2->A2_TEL //C,50  // celular1: 95920298034
         TRBCAB->A2_TEL2    := ""                        //C,50  // celular2: null
         TRBCAB->A2_TEL3    := ""                        //C,50  // telefone1: 5590038949
         TRBCAB->A2_TEL4    := ""                        //C,50  // telefone2: null
         TRBCAB->A2_TEL1W   := "False"                   //C,50  // celular1_whatsapp: true
         TRBCAB->A2_TEL2W   := "False"                   //C,50  // celular2_whatsapp: false
         TRBCAB->WK_RECNO   := QRYSA2->NRREG             //N,10 ,0 // Nr Recno SA2
         TRBCAB->WK_ORDEMP  := QRYSA2->ORDEMP            // Ordenação dos dados para envio
         TRBCAB->A2_L_ATIVO := If(QRYSA2->A2_L_ATIVO=="N","false","true") // _cSituacao
         TRBCAB->A2_L_TPASS := QRYSA2->A2_L_TPASS        // Tipo Associação
         TRBCAB->A2_L_NFPRO := QRYSA2->A2_L_NFPRO // laticinio_emite_nf
         TRBCAB->A2_NREDUZ  := QRYSA2->A2_NREDUZ  // nome

         If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS" .Or. _cOpcao == "ASS_CODIGO_LOJA" .Or. _cOpcao == "ASS_CNPJ") 
            If QRYSA2->A2_LOJA == "0001" //(Empty(QRYSA2->A2_L_TPASS) .And. QRYSA2->A2_LOJA == "0001") .Or. (QRYSA2->A2_L_TPASS == "C" .And. QRYSA2->A2_LOJA == "0001")
               TRBCAB->A2_L_TPASS := "A"
               TRBCAB->A2_L_ATIVO := "true" // "ATIVO" // _cSituacao    
            ElseIf QRYSA2->A2_L_TPASS == "A" .And. QRYSA2->A2_LOJA <> "0001"
               TRBCAB->A2_L_TPASS := "C"
            EndIf
         EndIf 

         TRBCAB->(MSUnLock())
      EndIf 

      TRBDET->(DbAppend())
      TRBDET->A2_COD     := QRYSA2->A2_COD  // QRYSA2->A2_L_TANQ      // QRYSA2->A2_COD         //C,6     // matricula_laticinio: TESTE_278363
      TRBDET->A2_LOJA    := QRYSA2->A2_LOJA // QRYSA2->A2_L_TANLJ     // QRYSA2->A2_LOJA        //C,4     // Loja_laticinio: TESTE_278363
      TRBDET->A2_CGC     := QRYSA2->A2_CGC         //C,14    // cpf_cnpj: 349.812.172-34
      TRBDET->A2_L_FAZEN := StrTran(QRYSA2->A2_L_FAZEN,'"',"")     //C,40    // nome_propriedade_rural: PROPRIEDADE TESTE 001
      TRBDET->A2_L_NIRF  := QRYSA2->A2_L_NIRF      //C,11    // NIRF: ABC4658
      TRBDET->A2_L_TANQ  := QRYSA2->A2_L_TANQ      //C,10    // id_tipo_tanque: 1
      TRBDET->A2_L_CAPTQ := QRYSA2->A2_L_CAPTQ     //N,11    // capacidade_tanque: 720
      TRBDET->A2_L_LATIT := QRYSA2->A2_L_LATIT     //N,10 ,6 // latitude_propriedade: -17.855250
      TRBDET->A2_L_LONGI := QRYSA2->A2_L_LONGI     //N,10 ,6 // longitude_propriedade: -46.223278
      TRBDET->A2_L_MARTQ := QRYSA2->A2_L_MARTQ     //C,20    // id_tipo_tanque: // Marca do tanque
      TRBDET->A2_L_CLASS := QRYSA2->A2_L_CLASS     //C,01    // id_tipo_tanque:
      TRBDET->WK_AREA    := 0                      //N,12 ,6 // area: 2000.15
      TRBDET->WK_RECRIA  := ""                     //C,10    // recria: 1
      TRBDET->WK_VACASEC := ""                     //C,10    // vaca_seca: 12
      TRBDET->WK_VACALAC := ""                     //C,10    // vaca_lactacao: 6
      TRBDET->WK_HORACOL := ""                     //C,10    // horario_coleta: 23:59
      TRBDET->WK_RACAPRO := ""                     //C,50    // raca_propriedade: Nome Raça predominante Teste
      TRBDET->A2_L_FREQU := QRYSA2->A2_L_FREQU     //C,10    // frequencia_coleta: 17
      TRBDET->WK_PRDDIAR := 0                      //N,10 ,2 // fproducao_media_diaria: 7251.31
      TRBDET->WK_AREAUTI := 0                      //N,10 ,2 // area_utilizada_producao: 837.84
      TRBDET->A2_L_CAPAC := QRYSA2->A2_L_CAPAC     //N,10 ,2 // capacidade_refrigeracao: 307
      TRBDET->WK_RECNO   := QRYSA2->NRREG          //N,10 ,0 // Nr Recno SA2
      //-------------------------------------------------------
      TRBDET->A2_L_LI_RO := QRYSA2->A2_L_LI_RO     //        codigo_linha_laticinio
      TRBDET->ZL3_DESCRI := QRYSA2->ZL3_DESCRI     //        nome_linha
      TRBDET->A2_L_ATIVO := If(QRYSA2->A2_L_ATIVO="N","false","true") // _cSituacao
      TRBDET->A2_L_SIGSI := QRYSA2->A2_L_SIGSI     // _cSigSif
      TRBDET->A2_L_TANLJ := QRYSA2->A2_L_TANLJ     // Loja tanque
      TRBDET->A2_L_RESFR := QRYSA2->A2_L_RESFR     // _cTipoResf
      //-------------------------------------------------------
      TRBDET->A2_ENDCOMP := StrTran(QRYSA2->A2_ENDCOMP,'"'," ")        //C,50  // complemento: Complemento Teste
      TRBDET->A2_END     := StrTran(QRYSA2->A2_END,'"'," ")            //C,90  // endereco: Rua Caminho Andante
      TRBDET->WK_NUMERO  := ""                        //C,20  // numero: 429 A
      TRBDET->A2_BAIRRO  := StrTran(QRYSA2->A2_BAIRRO,'"'," ")         //C,50  // bairro: Bairro Teste
      TRBDET->A2_CEP     := QRYSA2->A2_CEP            //C,8   // cep: 51462-74
      TRBDET->A2_COD_MUN := QRYSA2->A2_COD_MUN        //C,5   // id_cidade: 73
      TRBDET->A2_MUN     := QRYSA2->A2_MUN            // municipio
      TRBDET->A2_EST     := QRYSA2->A2_EST            // estado
      TRBDET->A2_EMAIL   := QRYSA2->A2_EMAIL          //C,100 // email: TESTE_278363@email.com
      TRBDET->A2_TEL     := AllTrim(QRYSA2->A2_DDD)+QRYSA2->A2_TEL //C,50  // celular1: 95920298034
      TRBDET->A2_L_NATRA := StrTran(QRYSA2->A2_L_NATRA,'"'," ")        //Nome Atravessador
      TRBDET->A2_L_TPASS := QRYSA2->A2_L_TPASS        // Tipo Associação
      TRBDET->WK_REGCAB  := TRBCAB->(Recno())         // Recno do TRBCAB para alterações.
      TRBDET->A2_L_NFPRO := QRYSA2->A2_L_NFPRO        // laticinio_emite_nf
      TRBDET->A2_NREDUZ  := QRYSA2->A2_NREDUZ         // nome
      // Mudança de código de Associação / Cooperativa
      If (_cOpcao == "INCASS" .Or. _cOpcao == "ALTASS" .Or. _cOpcao == "REENVASS" .Or. _cOpcao == "ASS_CODIGO_LOJA" .Or. _cOpcao == "ASS_CNPJ")
         If QRYSA2->A2_LOJA == "0001"
            //If _lNovoGrupo
            _lNovoGrupo := .F.
            TRBDET->WK_TIPOPRO := "ASSOCIACAO"
            TRBDET->A2_L_ATIVO := "true" // "ATIVO"      // _cSituacao 
         Else
            TRBDET->WK_TIPOPRO := "ASSOCIADO"
         EndIf
      EndIf

      TRBDET->WK_ORDEMP  := QRYSA2->ORDEMP         // Ordenação dos dados para envio

      TRBDET->(MSUnLock())
      _lHaDadosP := .T.

      QRYSA2->(DBSkip())

   EndDo

   _cLeuCapa   := AllTrim(Str(TRBCAB->(LastRec())))
   _cLeuItens  := AllTrim(Str(TRBDET->(LastRec())))

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032Q
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de Envio de dados dos Produtores Rurais via WebService Italac para Sistema Evomilk - INCLUSÃO / ALTERAÇÃO
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
                    _cOpcao   = "I" = Roda a integração de Inclusão de produtores no App Evomilk.
                              = "A" = Roda a integração de Alteração de produtores no App Evomilk.
                    _cRotina  = Rotina que está rodando a função de envio dos dados de produtores.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032Q(_cChamada,_cOpcao,_cRotina)

Local _aHeadOut   As array
Local _aRecnoSA2  As array
Local _nI         As Numeric
Local _nX         As Numeric
Local _nJ         As Numeric
Local _nTotRegEnv As Numeric
Local _cJSonGrp   As Character
Local _cItens     As Character
Local _cHoraIni   As Character
Local _cHoraFin   As Character
Local _cMinutos   As Character
Local _nMinutos   As Character
Local _cRetorno   As Character
Local _cKey       As Character
Local _aProdEnv   As Character
Local _cClasParc  As Character
Local _cCabProdu  As Character
Local _cDadosBCA  As Character
Local _cDadosBCB  As Character
Local _cDadosEmA  As Character
Local _cDadosEmB  As Character
Local _cDadosTlA  As Character
Local _cDadosTlB  As Character
Local _cPropried  As Character
Local _cDadosEdA  As Character
Local _cDadosEdB  As Character
Local _cRodaPe    As Character
Local _cJsonBco   As Character
Local _cJsonEml   As Character
Local _cJsonTel   As Character
Local _cJsonProp  As Character
Local _cJsonEnde  As Character
Local _CJSONENV   As Character
Local _cTenantid  As Character
Local _cEmpWebService As Character
Local _lTemTelef As Logical
Local _lTemEmail As Logical
Local _cJsonComp As Character 

Private _cIdProdut := ""
Private _cMatLatic := ""   //            matricula_laticinio
Private _cRazaoSoc := ""   //            nome_razao_social
Private _cCpf_Cnpj := ""   //            cpf_cnpj
Private _cInscrEst := ""   //            inscricao_estadual
Private _cRg_IE    := ""   //            rg_ie
Private _cDtNascF  := ""   //            data_nascimento_fundacao
Private _cDtHrEnv  := ""   //            data_hora
Private _cDataSit  := ""   //            data_situacao
Private _cObserv   := ""   //            info_adicional
Private _cComplem  := ""   //            complemento
Private _cEndereco := ""   //            endereco
Private _cNrEnd    := ""   //            numero
Private _cBairro   := ""   //            bairro
Private _cCep      := ""   //            cep
Private _cIdUF     := ""   //            id_uf
Private _cIDCidade := ""   //            id_cidade
Private _cCodBanco := ""   //            Codigo do Banco
Private _cCodAgenc := ""   //            Codigo da Agencia
Private _cNumConta := ""   //            Numero da Conta
Private _cEMail    := ""   //            email
Private _cCelular  := ""   //            celular1
Private _cCelula2  := ""   //            celular2
Private _cTelefon1 := ""   //            telefone1
Private _cTelefon2 := ""   //            telefone2
Private _cWhatsAp1 := ""   //            celular1_whatsapp
Private _cWhatsAp2 := ""   //            celular2_whatsapp
Private _cLEmiteNF := ""   //            laticinio_emite_nf   
Private _cTpPessoa := ""   //            tipo_pessoa          
Private _cTituTanq := ""   //            titular_ponto_coleta 
Private _cNomeFant := ""   //            _nome

            // Detalhe
Private _cNomeProp  := ""  //           nome_propriedade_rural
Private _cNIRF      := ""  //           NIRF
Private _cTipoTanq  := ""  //           id_tipo_tanque
Private _cCapacTnq  := ""  //           capacidade_tanque
Private _cLatitude  := ""  //           latitude_propriedade
Private _cLongitud  := ""  //           longitude_propriedade
Private _cArea      := ""  //           area
Private _cRecria    := ""  //           recria
Private _cVacaSeca  := ""  //           vaca_seca
Private _cVacaLacta := ""  //           vaca_lactacao
Private _cHoraCole  := ""  //           horario_coleta
Private _cRacaProp  := ""  //           raca_propriedade
Private _cFreqCol   := ""  //           frequencia_coleta
Private _cProdDia   := ""  //           producao_media_diaria
Private _cAreaUti   := ""  //           area_utilizada_producao
Private _cCapacRef  := ""  //           capacidade_refrigeracao
Private _cCodPropr  := ""  //           codigo_propriedade_laticinio
Private _cCodLinha  := ""  //           codigo_linha_laticinio
Private _cDescLin   := ""  //           nome_linha

Private _cSituacao  := ""
Private _cCidade    := ""
Private _cUF        := ""
Private _cCod_Ibge  := ""
Private _cSigSif   := ""
Private _cCodPropL := ""
Private _cCodigotq := ""
Private _cTipoResf := ""
Private _cMarcaTanq:= ""
Private _cCPFCnpjP := ""
Private _cMatParce := ""

Private _cTitTanq  := ""    // cpf_cnpj
Private _cMatrLat  := ""    // matricula_laticinio
Private _cTelPrinc := "SIM" // telefone_principal
Private _cEMailPri := "SIM" // email_principal
Private _cSitTnq   := ""    // situacao
Private _CSITPROP  := ""    // Situação Proprietario
Private _CCLASPROP := ""    // Classificação Proprietári do Tanque
Private _CNOMETNQ  := ""    // Nome do Tanque
Private _cNomBanco := ""    // Nome do Banco
Private _cTitConta := ""
Private _cInfoAdic := ""
Private _CDataCad  := ""
Private _cHoraCad  := ""

Private _cComplemD := ""   //            complemento
Private _cEnderecD := ""   //            endereco
Private _cNrEndD   := ""   //            numero
Private _cBairroD  := ""   //            bairro
Private _cCepD     := ""   //            cep
Private _cIdUFD    := ""   //            id_uf
Private _cIDCidadD := ""   //            id_cidade
Private _cEMailD   := ""   //            email 2
Private _cTelefonD := ""   //            Telefone demais propriedades
Private _cVincLat  := ""
Private _cProduTit := "true"
Private _cContaPri := "true"
Private _cParceiro  := "" 

Default _cChamada := "M"
Default _cOpcao   := "I"
Default _cRotina  := "PADRAO" // "TIT_TC"

Begin Sequence
   
   _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
   _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
   _nTotRegEnv := 50 // 1 
 
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)
      If _cOpcao == "I"
         _cLinkWS  := AllTrim(ZFM->ZFM_LINK02)  // Link de envio de INCLUSÃO de Produtores.
      Else
         _cLinkWS  := AllTrim(ZFM->ZFM_LINK04)  // Link de envio de ALTERAÇÃO de Produtores.
      EndIf
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   _cCabProdu := U_MGLT032X(_cDirJSon+"Cabec_Evomilk_Produtores.json")
   If Empty(_cCabProdu)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho Produtores na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosBCA := ', "dadosbancarios":'

   If Empty(_cDadosBCA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Dados Bancarios_A na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosBCB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Bancarios_B_Produtores.json")
   If Empty(_cDadosBCB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Bancarios_B_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEmA := ' , "emails": '

   If Empty(_cDadosEmA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Emails_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEmB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Emails_B_Produtores.json")
   If Empty(_cDadosEmB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Endereços de Email_B na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosTlA := ', "telefones": '

   If Empty(_cDadosTlA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Telefones_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosTlB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Telefones_B_Produtores.json")
   If Empty(_cDadosTlB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Numeros de Telefone_B na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cPropried := U_MGLT032X(_cDirJSon+"Det_Evomilk_Propriedades_Produtores.json")
   If Empty(_cPropried)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Propriedades_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEdA := ',    "enderecos": ['
   If Empty(_cDadosEdA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Enderecos_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEdB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Enderecos_B_Produtores.json")
   If Empty(_cDadosEdB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Enderecos_B_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cRodaPe := U_MGLT032X(_cDirJSon+"Rodape_Evomilk_Produtores.json")
   
   If Empty(_cRodaPe)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Rodape_Evomilk_Produtores.json","Atenção",,1)
      EndIf
      Break
   EndIf


   // Obtem o Token de acesso ao App Evomilk.
   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Produtores cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf


   // Define o CNPJ da unidade para a tag vinculado_ao_laticinio
   _cVincLat  := _cUnidVinc // Unidade na qual os produtores e coletas estão vinculados // SM0->M0_CGC

   _cHoraIni := Time() // Horario Inicial de Processamento

   _aHeadOut := {}

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

   _nI := 1

   _aProdEnv := {}

   TRBCAB->(DBSetOrder(3)) // {"WK_ORDEMP","A2_COD","A2_LOJA"}
   TRBDET->(DBSetOrder(2)) // TRBDET->(DBSetOrder(1)) // {"A2_COD","A2_LOJA"}

   If _cChamada == "M" // Chamada via menu.
      ProcRegua(_nTotRegs)
   EndIf
   _cTot:=AllTrim(Str(_nTotRegs))
   nConta:=0
   TRBCAB->(DBGoTop())
   _nIntervalo := 5 // 15

   _cJSonEnv  := ""   
   _cJSonGrp  := ""
   _aProdutor := {}   

   While ! TRBCAB->(Eof())

      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))
      If _nMinutos > _nIntervalo //  minutos

         _cKeyOld:=AllTrim(_cKey)

         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _nIntervalo == 5 // 10// já adiou uma vez não adia mais
               If _cChamada == "M" // Chamada via menu.
                  U_ITMsg("Erro ao na obtenção do Token.","Atenção","Rotina de Integração de Produtores cancelada.",1)
               EndIf
               Break
            EndIf
            _nIntervalo := 5 // 10
            _cKey:=AllTrim(_cKeyOld)
         EndIf

         _aHeadOut := {}
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

         _cHoraIni := Time()

      EndIf

      _lTemBanco := .F.
      _lTemTelef := .F.
      _lTemEmail := .F.

      // Efetua a leitura dos dados para montagem do JSON.
      _cItens    := ""
      _cIdProdut := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA//      codigo_usuario
      _cMatLatic := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA//      matricula_laticinio
      _cRazaoSoc := TRBCAB->A2_NOME             //            nome_razao_social
      _cCpf_Cnpj := TRBCAB->A2_CGC              //            cpf_cnpj
      _cInscrEst := TRBCAB->A2_INSCR            //            inscricao_estadual
      _cRg_IE    := TRBCAB->A2_PFISICA          //            rg_ie
      _cDtNascF  := StrZero(Year(TRBCAB->A2_DTNASC),4)+"-"+StrZero(Month(TRBCAB->A2_DTNASC),2)+"-"+StrZero(Day(TRBCAB->A2_DTNASC),2)   //            data_nascimento_fundacao
      _cDtHrEnv  := StrZero(Year(Date()),4)+"-"+StrZero(Month(Date()),2)+"-"+StrZero(Day(Date()),2) + "T" + Time() + "Z"
      _cDataSit  := StrZero(Year(Date()),4)+"-"+StrZero(Month(Date()),2)+"-"+StrZero(Day(Date()),2)
      _cObserv   := ""                          //            info_adicional
      _cComplem  := TRBCAB->A2_ENDCOMP          //            complemento
      _cEndereco := TRBCAB->A2_END              //            endereco
      _cNrEnd    := ""                          //            numero
      _cBairro   := TRBCAB->A2_BAIRRO           //            bairro
      _cCep      := TRBCAB->A2_CEP              //            cep
      _cIdUF     := ""                          //            id_uf
      _cIDCidade := ""                          //            id_cidade
      _cCidade   := AllTrim(TRBCAB->A2_MUN)     //            municipio
      _cUF       := AllTrim(TRBCAB->A2_EST)     //            estado
      _cCod_Ibge := TRBCAB->A2_COD_MUN          //            codigo_ibge"
      _cCodBanco := AllTrim(TRBCAB->A2_BANCO)   //            Codigo do Banco
      _cCodAgenc := AllTrim(TRBCAB->A2_AGENCIA) //            Codigo da Agencia
      _cNumConta := AllTrim(TRBCAB->A2_NUMCON)  //            Numero da Conta
      _cNomBanco := AllTrim(Posicione('SA6',1,xFilial('SA6')+_cCodBanco,'A6_NOME'))
      _cTitConta := TRBCAB->A2_NOME
      _cInfoAdic := ""
      _cEMail    := TRBCAB->A2_EMAIL            //            email
      _cCelular  := ""                          //            celular1
      _cCelula2  := ""                          //            celular2
      _cTelefon1 := TRBCAB->A2_TEL              //            telefone1

      If ! Empty(_cTelefon1)
         _lTemTelef := .T.
      EndIf

      If ! Empty(_cEMail)
         _lTemEmail := .T.
      EndIf

      If !Empty(_cTelefon1)
         _cTelefon1 := '"' +AllTrim(_cTelefon1)  + '"'
      EndIf

      _cTelefon2 := ""                          //            telefone2
      _cWhatsAp1 := "SIM"                       //            celular1_whatsapp
      _cWhatsAp1 := "false"                     //            celular2_whatsapp

      //=======================================================================================
      // Este trecho trata os varios e-mails de um campo e envia um a um em campos diferentes.
      //=======================================================================================
      _cEMail := AllTrim(StrTran(_cEMail,",",";"))
      _aCabMail  := U_ITTXTARRAY(_cEMail,";",10)

      _cNomeFant := TRBCAB->A2_NREDUZ

      _cJsonProp := ""  //  _cPropried
      _cJsonBco  := ""  //  _cDadosBCB
      _cJsonTel  := ""  //  _cDadosTlB
      _cJsonEml  := ""  //  _cDadosEmB
      _cJsonEnde := ""  //  _cDadosEdB

      _aRecnoSA2 := {}

      TRBDET->(MsSeek(TRBCAB->A2_COD+TRBCAB->A2_LOJA))

      While ! TRBDET->(Eof()) .And. TRBCAB->A2_COD+TRBCAB->A2_LOJA == TRBDET->A2_COD+TRBDET->A2_LOJA

         nConta++
         If _cChamada == "M" // Chamada via menu.
            IncProc(_cHoraIni+"-Enviando Produtores: "+StrZero(nConta,5) +" de "+ _cTot)
         EndIf

         _cCodPropr  := ""                                    //           codigo_propriedade_laticinio
         _cNomeProp  := AllTrim(TRBDET->A2_L_FAZEN)           //           nome_propriedade_rural
        
         _cNIRF      := TRBDET->A2_L_NIRF                     //           NIRF

         _cCodPropL  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA
         _cMatLatic  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA    // matricula_laticinio

         _cTipoTanq  := "INDIVIDUAL"
         _CCLASPROP  := "PRODUTOR INDIVIDUAL"

         _cMatrLat   := ""
         _cTitTanq   := ""
         _cMatParce  := ""
         _cCPFCnpjP  := ""
         _cTituTanq  := "true"

         If TRBDET->A2_L_NFPRO == "S"
            _cLEmiteNF := "true"  
         Else 
            _cLEmiteNF := "false" 
         EndIf 

         If Len(AllTrim(TRBDET->A2_CGC)) < 14
            _cTpPessoa := "1" 
         Else 
            _cTpPessoa := "2" 
         EndIf 
         
         _cNomeFant    := TRBDET->A2_NREDUZ

         If TRBDET->A2_L_CLASS == "C"
            _cTipoTanq  := "COLETIVO"
            _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO"
         ElseIf TRBDET->A2_L_CLASS == "U"
            _CCLASPROP  := "USUARIO DE TANQUE COMUNITARIO"
            _cTipoTanq  := "COLETIVO"
            _cMatrLat   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
            _cTitTanq   := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque

            _cClasParc  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_L_CLASS') // Classificação do Titular do Tanque
            If AllTrim(_cClasParc) == "F"
               _cCPFCnpjP  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque
               _cMatParce  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
            EndIf
            _cTituTanq  := "false"

         ElseIf TRBDET->A2_L_CLASS == "F"
             _cTipoTanq  := "FAMILIAR" //"INDIVIDUAL"
             _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO" // "PRODUTOR INDIVIDUAL"
         EndIf

         If ! Empty(_cCPFCnpjP) .And. AllTrim(_cCPFCnpjP) == AllTrim(_cCpf_Cnpj)
            _cCPFCnpjP := ""
            _cMatParce := ""
         EndIf

         _CNOMETNQ   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ //        Nome do Tanque
         _cCapacTnq  := AllTrim(Str(TRBDET->A2_L_CAPTQ,11))   //           capacidade_tanque
         _cLatitude  := AllTrim(Str(TRBDET->A2_L_LATIT,18,6)) //           latitude_propriedade
         _cLongitud  := AllTrim(Str(TRBDET->A2_L_LONGI,18,6)) //           longitude_propriedade
         _cArea      := ""                                    //           area
         _cRecria    := ""                                    //           recria
         _cVacaSeca  := ""                                    //           vaca_seca
         _cVacaLacta := ""                                    //           vaca_lactacao
         _cHoraCole  := ""                                    //           horario_coleta
         _cRacaProp  := ""                                    //           raca_propriedade

         If TRBDET->A2_L_FREQU == "1"
            _cFreqCol   := "48"                               //           frequencia_coleta
         Else
            _cFreqCol   := "24"
         EndIf

         _cProdDia   := ""                                    //           producao_media_diaria
         _cAreaUti   := ""                                    //           area_utilizada_producao
         _cCapacRef  := ""                                    //           capacidade_refrigeracao
         //Cap. Resfri.	Capacidade Resfriamento	0=Nenhuma	2=Duas Ordenhas	4=Quatro Ordenhas

         If TRBDET->A2_L_CAPAC == "0"
            _cCapacRef  := "Nenhuma"
         ElseIf TRBDET->A2_L_CAPAC == "2"
            _cCapacRef  := "Duas Ordenhas"
         ElseIf TRBDET->A2_L_CAPAC == "4"
            _cCapacRef  := "Quatro Ordenhas"
         EndIf

         If Empty(_cCapacRef)
            _cCapacRef := "nenhuma"
         EndIf

         _cSituacao  := TRBDET->A2_L_ATIVO
         _cSitTnq    := TRBDET->A2_L_ATIVO
         _CSITPROP   := TRBDET->A2_L_ATIVO
         _cSigSif    := TRBDET->A2_L_SIGSI
         _cCodigotq  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
         _cTipoResf  := If(TRBDET->A2_L_RESFR == "E","EXPANSAO","IMERSAO")
         _cMarcaTanq := TRBDET->A2_L_MARTQ
         _cCodLinha  := TRBDET->A2_L_LI_RO   //           codigo_linha_laticinio
         _cDescLin   := TRBDET->ZL3_DESCRI   //           nome_linha
         _cComplemD  := TRBDET->A2_ENDCOMP          //            complemento
         _cEnderecD  := TRBDET->A2_END              //            endereco
         _cNrEndD    := ""                          //            numero
         _cBairroD   := TRBDET->A2_BAIRRO           //            bairro
         _cCepD      := TRBDET->A2_CEP              //            cep
         _cIDCidadD  := ""                          //            id_cidade

         _cCodIbgeD  := TRBDET->A2_COD_MUN          //           codigo_ibge"
         _cEMailD    := TRBDET->A2_EMAIL            //            email
         _cTelefonD  := TRBDET->A2_TEL
         _cCidade    := AllTrim(TRBDET->A2_MUN)     //            municipio
         _cUF        := AllTrim(TRBDET->A2_EST)     //            estado
         _cCod_Ibge  := TRBDET->A2_COD_MUN          //            codigo_ibge"

         If ! Empty(_cTelefonD)
            _lTemTelef := .T.
            _cTelefon1 := _cTelefonD
         EndIf

         If !Empty(_cEMailD)
            _lTemEmail := .T.
            _cEMail := _cEMailD
         EndIf

         If !Empty(_cCodBanco) .And. !Empty(_cCodAgenc) .And. !Empty(_cNumConta)//SE NÃO TEM NÃO ENVIA
            _cJsonBco  += If(!Empty(_cJsonBco),",","")  + &(_cDadosBCB)
            _lTemBanco:=.T.
         EndIf
         If ! Empty(_cEMailD)//SE NÃO TEM NÃO ENVIA
            _cJsonEml  += If(!Empty(_cJsonEml),",","")  + &(_cDadosEmB)
         EndIf
         If ! Empty(_cTelefonD)//SE NÃO TEM NÃO ENVIA
             _cJsonTel  += If(!Empty(_cJsonTel),",","")  + &(_cDadosTlB)
         EndIf
         _cJsonProp += If(!Empty(_cJsonProp),",","") + &(_cPropried)
         _cJsonEnde += If(!Empty(_cJsonEnde),",","") + &(_cDadosEdB)

         // Guarda os fornecedores do JSon para atualização do SA2
         aAdd(_aRecnoSA2, TRBDET->WK_RECNO)
         aAdd(_aProdutor,{TRBDET->A2_COD,;      // 1
                          TRBDET->A2_LOJA,;     // 2
                          TRBCAB->A2_NOME,;     // 3
                          "R" ,;                // 4
                          TRBDET->WK_RECNO,;    // 5
                          ""})                  // 6

         TRBDET->(DBSkip())
      EndDo

      _CDataCad  := DToC(Date())
      _cHoraCad  := Time()

      //_cJSonEnv:= &(_cCabProdu) + _cPropried + _cDadosBCA + _cDadosBCB + _cDadosTlA + _cDadosTlB + _cDadosEmA + _cDadosEmB + _cDadosEdA + _cDadosEdB + _cRodaPe
      _cJSonEnv    := &(_cCabProdu) + _cJsonProp +" ] "

      If _lTemBanco // Tem BANCO
         _cJSonEnv += _cDadosBCA + "[" + _cJsonBco + "]"
      Else
         _cJSonEnv += _cDadosBCA + "null"
      EndIf

      If _lTemTelef // Tem TELEFONTE
         _cJSonEnv += _cDadosTlA + "[" + _cJsonTel + "]"
      Else
         _cJSonEnv += _cDadosTlA + "null"
      EndIf

      If _lTemEmail  // Tem E-MAIL
         _cJSonEnv += _cDadosEmA + "[" + _cJsonEml + "]"
      Else
         _cJSonEnv += _cDadosEmA + "null"
      EndIf

      _cJSonEnv += _cDadosEdA + _cJsonEnde + _cRodaPe

      _aProdutor[Len(_aProdutor), 6] := _cJSonEnv // Grava o JSon enviado de cada produtor para atualização da tabela de muro.

      _cJSonGrp += If(!Empty(_cJSonGrp),",","[") + _cJSonEnv 

      If _nI >= _nTotRegEnv

         _cJSonGrp += "]"

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil
         _nTimOut	 	:= 720
         _cRetorno   := ""
         _cRetHttp    := ''

         _aExcecao := {{"\","-"},{char(9),""}}  // Char(9) = Tecla Tab.
         _cJSonGrp := U_ITSUBCHR(_cJSonGrp, _aExcecao)

         // Envio do JSon
         _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonGrp                , _nTimOut    , _aHeadOut   , @_cJSonRet ) )
         _cJsonComp := _cJSonGrp

         _cJSonEnv := ""
         _cJSonGrp := ""
         _cResult  := ""
         _cSucesso := ""
         _cErro    := ""
         _aSucesso := {}
         _aErro    := {}
  
         If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
            _cRetHttp := DecodeUtf8(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            
            _oJson := JsonObject():new()

            _cRet := _oJson:FromJson(_cRetHttp)
         
            _cResult  := _oJson:GetJsonObject("status")
            _oResult  := _oJson:GetJsonObject("result")
            _cSucesso := _oResult:GetJsonObject("success")
            _cErro    := _oResult:GetJsonObject("error")
            
            _aSucesso := StrTokArr2(_cSucesso,",")
         EndIf

         If ValType(_cResult) <> "C"  
            _cResult := ""
         EndIf 

         If Len(_aSucesso) > 0         
            For _nJ := 1 To Len(_aSucesso)  
                _cCodigoLj := AllTrim(_aSucesso[_nJ])
                If Len(_cCodigoLj) == 11
                   _cCod  := SubStr(_cCodigoLj,1,6)
                   _cLoja := SubStr(_cCodigoLj,8,4)
                   _nX := aScan(_aProdutor,{|x| x[1] == _cCod .And. x[2] == _cLoja})
                   If _nX > 0
                      _aProdutor[_nX,4] := "A"
                   EndIf 
                EndIf  
            Next _nJ
         EndIf

         For _nX := 1 To Len(_aProdutor)
             If _aProdutor[_nX,4] == "A"
                // Grava dados dos Produtores Enviados e aceitos.
                ZBH->(RecLock("ZBH",.T.))
                ZBH->ZBH_FILIAL := xFilial("ZBH")            // Filial do Sistema
                ZBH->ZBH_CODPRO := _aProdutor[_nX,1]         // Codigo do Produtor
                ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]         // Loja do Produtor
                ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]         // Nome do Produtor
                ZBH->ZBH_MOTIVO := AllTrim(_cRetHttp)        // Motivo da Rejeição
                ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6])         //_cJSonGrp // JSON enviado
                ZBH->ZBH_DTREJ  := Date()                    // Data da Rejeição
                ZBH->ZBH_HRREJ  := Time()                    // Hora da Rejeição
                ZBH->ZBH_DTENV  := Date()                    // Data de Envio
                ZBH->ZBH_HRENV  := Time()                    // Hora de Envio
                ZBH->ZBH_STATUS := "A"                       // Status da Integraç
                ZBH->ZBH_WEBINT := "E"                       // Indica que a integração está sendo realizada com o App Evomilk
			       ZBH->(MSUnLock())
                _nAceitos++
                // Marca produtor como já enviado para o sistema Evomilk.
                // INCLUSÃO E ALTERAÇÃO DE PRODUTORES SUCESSO
                SA2->(DBGoTo(_aProdutor[_nX,5]))
                SA2->(RecLock("SA2", .F.))
                If _cOpcao == "I"  // Inclusão
                   SA2->A2_L_ENVEV := "N"
                   SA2->A2_L_ITCOL := "S"
                Else // Alteração
                   SA2->A2_L_ENVAT := "N"
                EndIf
                SA2->(MSUnLock())
             Else
                // Grava dados dos Produtores enviados e rejeitados.
                ZBH->(RecLock("ZBH",.T.))
                ZBH->ZBH_FILIAL := xFilial("ZBH")            // Filial do Sistema
                ZBH->ZBH_CODPRO := _aProdutor[_nX,1]         // Codigo do Produtor
                ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]         // Loja do Produtor
                ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]         // Nome do Produtor
                ZBH->ZBH_MOTIVO := AllTrim(_cRetHttp)        // Motivo da Rejeição
                ZBH->ZBH_JSONEN := _cJsonComp // AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado
                ZBH->ZBH_DTREJ  := Date()                    // Data da Rejeição
                ZBH->ZBH_HRREJ  := Time()                    // Hora da Rejeição
                ZBH->ZBH_DTENV	 := Date()                  // Data de Envio
                ZBH->ZBH_HRENV	 := Time()                  // Hora de Envio
                ZBH->ZBH_STATUS := "R"                       // Status da Integração
                ZBH->ZBH_WEBINT := "E"                       // Indica que a integração está sendo realizada com o App Evomilk
			       ZBH->(MSUnLock())
                _nRejeitados++
             EndIf
         Next 

         _aProdEnv  := {}
         _cJSonEnv  := ""
         _aProdutor := {}
         _nI := 0

      EndIf

      _nI += 1

      TRBCAB->(DBSkip())

   EndDo

   If ! Empty(_cJSonGrp) // ! Empty(_cJSonEnv)
      _cJSonGrp += "]"

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil
      _nTimOut	 	:= 720
      _cRetorno   := ""

      _cRetHttp    := ''
      _cResult     := ""
      _cSucesso    := ""
      _aSucesso    := {}

      _aExcecao := {{"\","-"},{char(9),""}}  // Char(9) = Tecla Tab.
      _cJSonGrp := U_ITSUBCHR(_cJSonGrp, _aExcecao)
      
      // Envio do JSon
      _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonGrp , _nTimOut , _aHeadOut , @_cJSonRet ) )
      _cJsonComp := _cJSonGrp

      If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
         _cRetHttp := DecodeUtf8(_cRetHttp)

         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         _oJson := JsonObject():new()

         _cRet := _oJson:FromJson(_cRetHttp)
         _cResult  := _oJson:GetJsonObject("status")
         _oResult  := _oJson:GetJsonObject("result")
         _cSucesso := _oResult:GetJsonObject("success")
         _cErro    := _oResult:GetJsonObject("error")
         _aSucesso := StrTokArr2(_cSucesso,",")
      EndIf

      If ValType(_cResult) <> "C"  
         _cResult := ""
      EndIf 

      If Len(_aSucesso)            
         For _nJ := 1 To Len(_aSucesso) 
             _cCodigoLj := AllTrim(_aSucesso[_nJ])
             If Len(_cCodigoLj) == 11
                _cCod  := SubStr(_cCodigoLj,1,6)
                _cLoja := SubStr(_cCodigoLj,8,4)
                _nX := aScan(_aProdutor,{|x| x[1] == _cCod .And. x[2] == _cLoja})
                If _nX > 0
                   _aProdutor[_nX,4] := "A"
                EndIf 
             EndIf  
         Next _nJ
      EndIf 

      For _nX := 1 To Len(_aProdutor)
          If _aProdutor[_nX,4] == "A"
             // Grava Dados dos Produtores Enviados e aceitos para histórico
             ZBH->(RecLock("ZBH",.T.))
             ZBH->ZBH_FILIAL := xFilial("ZBH")             // Filial do Sistema
             ZBH->ZBH_CODPRO := _aProdutor[_nX,1]          // Codigo do Produtor
             ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]          // Loja do Produtor
             ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]          // Nome do Produtor
             ZBH->ZBH_MOTIVO := AllTrim(_cRetHttp)         // Motivo da Rejeição
             ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6]) //_cJSonGrp // JSON enviado
             ZBH->ZBH_DTENV  := Date()                     // Data de Envio
             ZBH->ZBH_HRENV  := Time()                     // Hora de Envio
             ZBH->ZBH_STATUS := "A"                        // Status da Integração
             ZBH->ZBH_WEBINT := "E"                        // Indica que a integração está sendo realizada com o App Evomilk		ZBH->(MSUnLock())
             ZBH->(MSUnLock())
             _nAceitos++
             // Marca produtor como já enviado para o sistema Evomilk.
             SA2->(DBGoTo(_aProdutor[_nX,5]))
             SA2->(RecLock("SA2", .F.))
             If _cOpcao == "I"  // Inclusão
                SA2->A2_L_ENVEV := "N"
                SA2->A2_L_ITCOL := "S"
             Else // Alteração
                SA2->A2_L_ENVAT := "N"
             EndIf
             SA2->(MSUnLock())
          Else
             // Grava dados de envio rejeitados para histórico.
             ZBH->(RecLock("ZBH",.T.))
             ZBH->ZBH_FILIAL := xFilial("ZBH")              // Filial do Sistema
             ZBH->ZBH_CODPRO := _aProdutor[_nX,1]           // Codigo do Produtor
             ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]           // Loja do Produtor
             ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]           // Nome do Produtor
             ZBH->ZBH_MOTIVO := AllTrim(_cRetHttp)          // Motivo da Rejeição
             ZBH->ZBH_JSONEN := _cJsonComp   // AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado
             ZBH->ZBH_DTREJ  := Date()                      // Data da Rejeição
             ZBH->ZBH_HRREJ  := Time()                      // Hora da Rejeição
             ZBH->ZBH_DTENV  := Date()                      // Data de Envio
             ZBH->ZBH_HRENV  := Time()                      // Hora de Envio
             ZBH->ZBH_STATUS := "R"                         // Status da Integração
             ZBH->ZBH_WEBINT := "E"                         // Indica que a integração está sendo realizada com o App Evomilk
		       ZBH->(MSUnLock())
             _nRejeitados++
          EndIf
      Next _nX
   EndIf 

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032V
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de envio de dados dos Volumes de Leite Coletados.
Parametros---------: _lSchedule = .T. = Rotina chamada via scheduller
                                    .F. = Rotina chamada via menu.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032V(_lSchedule)

Local _aStruct   := {}
Local _cDtColIni := SUPERGETMV('IT_DTCOLEV',.F.,  "01/05/2025")
Local _oTemp3, _oTemp5
Local _cFilEnvC := xFilial("ZL3")
//Local _dDataFim := MonthSum(Ctod(_cDtColIni),1)

Default _lSchedule := .F.

Begin Sequence

   If ! _lSchedule
      IncProc("Gerando dados das Coletas de Leita para envio...")
   EndIf

   // Cria Tabela Temporária para atualização da ZLJ
   _aStruct := {}
   aAdd(_aStruct,{"ZLJ_VIAGEM","C",10 ,0})  
   aAdd(_aStruct,{"ZLJ_NUMERO","C",10 ,0})  
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  

   If Select("TRBZLJ") > 0
      TRBZLJ->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp5 := FWTemporaryTable():New( "TRBZLJ",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp5:AddIndex( "01", {"ZLJ_VIAGEM","ZLJ_NUMERO"} )
   _oTemp5:Create()

   DBSelectArea("TRBZLJ")

   // Cria Tabela Temporária para armazenar dados do JSon
   _aStruct := {}
   aAdd(_aStruct,{"ZLJ_VIAGEM","C",10 ,0})  
   aAdd(_aStruct,{"ZLJ_NUMERO","C",10 ,0})  
   aAdd(_aStruct,{"ZLJ_CODPAT","C",6  ,0})  
   aAdd(_aStruct,{"ZLJ_LOJPAT","C",4  ,0})  
   aAdd(_aStruct,{"ZLJ_VOLUME","N",14 ,0})  // volume_litros
   aAdd(_aStruct,{"ZLJ_DTIVIA","D",8  ,0})  // data_coleta
   aAdd(_aStruct,{"ZLJ_HRINI" ,"C",8  ,0})  // hora_coleta
   aAdd(_aStruct,{"WK_OBSERV" ,"C",100,0})  // observações
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno da Tabela ZLJ
   aAdd(_aStruct,{"WK_EXCLUID","C",5  ,0})  // Indica se é inclusão ou exclusão de coletas

   If Select("TRBCOL") > 0
      TRBCOL->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp3 := FWTemporaryTable():New( "TRBCOL",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp3:AddIndex( "01", {"ZLJ_CODPAT","ZLJ_LOJPAT"})

   _oTemp3:Create()

   DBSelectArea("TRBCOL")

   _nTotRegs := 0

   // Monta select de leitura de dados do cadastro de coletas de leite.
   _cQry := " SELECT "
   _cQry += " ZLJ_VIAGEM, "              
   _cQry += " ZLJ_NUMERO, "              
   _cQry += " ZLJ_CODPAT, "              
   _cQry += " ZLJ_LOJPAT, "              
   _cQry += " ZLJ_VOLUME, "              // volume_litros
   _cQry += " ZLJ_DTIVIA, "              // data_coleta
   _cQry += " ZLJ_HRINI , "              // HORARIO INICIAL COLETA // ZLJ_HRFIM = HORARIO FINAL COLETA
   _cQry += " ZLJ.R_E_C_N_O_ AS NRREG "
   _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2 "
   _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
   
   If ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
      _cQry += " AND (ZLJ.ZLJ_ENVEVO = ' ' OR ZLJ.ZLJ_ENVEVO = 'S') "
   EndIf
   
   _cQry += " AND ZLJ_DTIVIA >= '" + DToS(Ctod(_cDtColIni)) + "' "

   //==================================== Este filtro foi criado temporáriamente para permitir o envio das coletas em etapas. 
   //==================================== Para podermos enviar um mes de cada vez. 
   //_cQry += " AND ZLJ_DTIVIA <= '" + DToS(_dDataFim) + "' "  
      
   _cQry += " AND ZLJ_CODPAT = A2_COD AND ZLJ_LOJPAT = A2_LOJA "
   _cQry += " AND SA2.A2_L_ITCOL = 'S' "
   _cQry += " AND ZLJ_FILIAL = '" + _cFilEnvC + "' "
   _cQry += " AND ZLJ_STATUS = 'E' "

   _cQry += " ORDER BY ZLJ_CODPAT,ZLJ_LOJPAT "

   If Select("QRYZLJ") > 0
      QRYZLJ->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYZLJ")

   DBSelectArea("QRYZLJ")

   Count To _nTotRegs

   QRYZLJ->(DBGoTop())

   If ! _lSchedule
      ProcRegua(_nTotRegs)
   EndIf
   
   _cTot := AllTrim(Str(_nTotRegs))
   
   nConta := 0

   While ! QRYZLJ->(Eof())

      nConta++
      If ! _lSchedule
         IncProc("Lendo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      TRBCOL->(DbAppend())
      TRBCOL->ZLJ_VIAGEM := QRYZLJ->ZLJ_VIAGEM         // C 10  // numero_identificador: "309700845-3097009404"
      TRBCOL->ZLJ_NUMERO := QRYZLJ->ZLJ_NUMERO         // C 10  // numero_identificador: "309700845-3097009404"
      TRBCOL->ZLJ_CODPAT := QRYZLJ->ZLJ_CODPAT         // C 6   // matricula_produtor //A2_COD
      TRBCOL->ZLJ_LOJPAT := QRYZLJ->ZLJ_LOJPAT         // C 4   // matricula_produtor //A2_LOJA
      TRBCOL->ZLJ_VOLUME := QRYZLJ->ZLJ_VOLUME         // N 14  // volume_litros
      TRBCOL->ZLJ_DTIVIA := SToD(QRYZLJ->ZLJ_DTIVIA)   // D 8   // data_coleta
      TRBCOL->ZLJ_HRINI  := QRYZLJ->ZLJ_HRINI          // C 8   // hora_coleta
      TRBCOL->WK_OBSERV  := ""                         // C 100 // observações
      TRBCOL->WK_RECNO   := QRYZLJ->NRREG              // N 10  // Recno da Tabela ZLJ
      TRBCOL->WK_EXCLUID := "false"                    // C 5   // Indica que é uma inclusão de coletas

      _lHaDadosC := .T.

      QRYZLJ->(DBSkip())
   EndDo

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032R
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de Envio de dados das coletas via WebService Italac para Sistema Evomilk
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032R(_cChamada)

Local _cColetaL := ""
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local _cJSonEnv
Local _nStart
Local _nRetry
Local _cJSonRet
Local _nTimOut
Local _cRetHttp
Local _cJSonColeta, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 500 //50 // 100  // Total de registros para envio.
Local _nI 
Local _nJ 
Local _nX
Local _aColetaEnv
Local _nRecno := 0
Local _LinkCerto := ""
Local _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
Local _aColetas  := {}
Local _cJsonComp := ""
Local _nIntervalo

Private _cNrIdent
Private _cNrMatr
Private _cVolume
Private _cDtColeta
Private _cHoraCol
Private _cObserv
Private _cNomeCoop
Private _cTipoCoop
Private _cExcluida := 'False'

Private _OFWRITER // Para gravação de arquivos texto, para envio para Evomilk para conferência.

Default _cChamada := "M"

Begin Sequence
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK03) // LINK DE ENVIO DA COLETA DO LEITE.
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cColetaL := U_MGLT032X(_cDirJSon+"Coleta_de_Leite_Evomilk.json")

   If Empty(_cColetaL)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo Coleta de Leite integração Italac x Evomilk","Atenção",,1)
      EndIf

      Break
   EndIf

   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf

   _cHoraIni := Time() // Horario Inicial de Processamento

   _aHeadOut := {}

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')
   _nTotRegs:=TRBCOL->(LastRec())
   If _cChamada == "M"
      ProcRegua(_nTotRegs)
   EndIf

   _cJSonColeta := "["
   _cJSonGrp    := ""
   _cResult  := ""
   _cSucesso := ""
   _cErro    := ""
   _aSucesso := {}
   _aErro    := {}
   _nIntervalo := 5

   _nI := 1

   _aColetaEnv := {}
   _cTot:=AllTrim(Str(_nTotRegs))
   _cLidos:= _cTot
   nConta:=0

   TRBCOL->(DBGoTop())
   While ! TRBCOL->(Eof())

      nConta++
      If _cChamada == "M"
         IncProc("Transmitindo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))
      If _nMinutos > _nIntervalo // 5 // 28 // minutos
         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _cChamada == "M" // Chamada via menu.
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
            EndIf

            Break
         EndIf

         _aHeadOut := {}
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

         _cHoraIni := Time()

      EndIf

      // Efetua a leitura dos dados e montagem do JSon.
      _cNrIdent  := TRBCOL->ZLJ_VIAGEM+TRBCOL->ZLJ_NUMERO            // C 6   // numero_identificador: "309700845-3097009404"
      _cNrMatr   := TRBCOL->ZLJ_CODPAT + "-" + TRBCOL->ZLJ_LOJPAT    // C 6   // matricula_produtor //A2_COD
      _cVolume   := AllTrim(Str(TRBCOL->ZLJ_VOLUME,14))         // N 14  // volume_litros
      _cDtColeta := StrZero(Year(TRBCOL->ZLJ_DTIVIA),4) + "-" + StrZero(Month(TRBCOL->ZLJ_DTIVIA),2) + "-" + StrZero(Day(TRBCOL->ZLJ_DTIVIA),2)      // D 8   // data_coleta
      _cHoraCol  := TRBCOL->ZLJ_HRINI                           // WK_HORACOL                          // C 8   // hora_coleta
      _cObserv   := TRBCOL->WK_OBSERV                           // C 100 // observações
      _nRecno    := TRBCOL->WK_RECNO
      _cExcluida := TRBCOL->WK_EXCLUID

      //Guarda as coletas para atualização das tabelas.
      _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+TRBCOL->ZLJ_CODPAT+TRBCOL->ZLJ_LOJPAT,'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado
      If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
         _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador
      Else
         _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
      EndIf
      aAdd(_aColetas, {_cNrIdent,;            // Ticket         // 1
                       TRBCOL->ZLJ_CODPAT,;   // Codigo         // 2
                       TRBCOL->ZLJ_LOJPAT,;   // Loja           // 3
                       _cNomeCoop,;           // Nome           // 4
                       _cDtColeta,;           // Dt Coleta      // 5
                             "R" ,;           // Status         // 6
                       TRBCOL->WK_RECNO,;     // Recno          // 7
                       ""})                   // JSon da Coleta // 8  

      _cNomeCoop := ""
      _cTipoCoop := ""

      _cJSonEnv := &(_cColetaL)       

      _cJSonGrp += If(!Empty(_cJSonGrp),",","") + _cJSonEnv

      _aColetas[Len(_aColetas), 8 ] := _cJSonEnv

      If _nI >= _nTotRegEnv

         _cJSonColeta += _cJSonGrp + "]"

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil
         _nTimOut	 	:= 720 //120

         _cRetHttp    := ''

         _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )

         _cJsonComp := _cJSonColeta

         _cResult  := ""
         _cSucesso := ""
         _cErro    := ""
         _aSucesso := {}
         _aErro    := {}

         If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
            _cRetHttp := DecodeUtf8(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            
            _oJson := JsonObject():new()
            _cRet := _oJson:FromJson(_cRetHttp)
         
            _cResult  := _oJson:GetJsonObject("status")
            _oResult  := _oJson:GetJsonObject("result")
            
            _cSucesso := _oResult:GetJsonObject("success")
            _cErro    := _oResult:GetJsonObject("error")
            
         EndIf
        
         If ValType(_cResult) <> "C"  
            _cResult := ""
         EndIf 

         _aSucesso := StrTokArr2(_cSucesso,",")
                  
         For _nJ := 1 To Len(_aSucesso) 
         
             _cCodigoCo := AllTrim(_aSucesso[_nJ])
             _nX := aScan(_aColetas,{|x| x[1] == _cCodigoCo})
             If _nX > 0
                _aColetas[_nX,6] := "A"
             EndIf 
         Next _nJ

         For _nX := 1 To Len(_aColetas)
             
             If _aColetas[_nX,6] == "A"
                // Grava dados das coletas enviadas e aceitas para histórico.
                ZBI->(RecLock("ZBI",.T.))
                ZBI->ZBI_FILIAL  := xFilial("ZBI")        // Filial do Sistema
                ZBI->ZBI_TICKET  := _aColetas[_nX,1]      // Ticket
                ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
                ZBI->ZBI_CODPRO  := _aColetas[_nX,2]      // Codigo do Produtor
                ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]      // Loja do Produtor
                ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]       // Nome
                ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)   // Motivo da Rejeição
                ZBI->ZBI_JSONEN  :=  _aColetas[_nX,8]     //_cJSonColeta  // Json de Envio
                ZBI->ZBI_DTENV	  :=  Date()             // Data de Envio
                ZBI->ZBI_HRENV	  :=  Time()             // Hora de Envio
                ZBI->ZBI_STATUS  :=  "A"                  // Status da Integração
                ZBI->ZBI_WEBINT  :=  "E"                  // Indica que a integração está sendo realizada com o App Evomilk
                ZBI->(MSUnLock())
                _nAceitos++

                // Atualiza a tabela ZLJ
                ZLJ->(DBGoTo(_aColetas[_nX,7]))
                ZLJ->(RecLock("ZLJ", .F.))
                ZLJ->ZLJ_ENVEVO := "N"
                ZLJ->(MSUnLock())
             Else
                // Grava dados das coletas enviadas e rejeitadas para histórico.
                ZBI->(RecLock("ZBI",.T.))
                ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
                ZBI->ZBI_TICKET  := _aColetas[_nX,1]           // Ticket
                ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
                ZBI->ZBI_CODPRO  := _aColetas[_nX,2]           // Codigo do Produtor
                ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]           // Loja do Produtor
                ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]           // Nome
                ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)        // Motivo da Rejeição
                ZBI->ZBI_DTREJ   :=  Date()                    // Data da Rejeição
                ZBI->ZBI_HRREJ   :=  Time()                    // Hora da Rejeição
                ZBI->ZBI_JSONEN  :=  _cJsonComp //_aColetas[_nX,8]          // _cJSonColeta // Json de Envio
                ZBI->ZBI_DTENV	  :=  Date()                  // Data de Envio
                ZBI->ZBI_HRENV   :=  Time()                    // Hora de Envio
                ZBI->ZBI_STATUS  :=  "R"                       // Status da Integração
                ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
                ZBI->(MSUnLock())
                _nRejeitados++
             EndIf
         Next 
        
         _aColetaEnv := {}
         _cJSonColeta := "["
         _cJSonGrp := ""
         _nI := 0
         _aColetas := {}

      EndIf

      _nI += 1

      TRBCOL->(DBSkip())
   EndDo

   If ! Empty(_cJSonGrp)
      _cJSonColeta += _cJSonGrp + "]"
      _nStart 	   := 0
      _nRetry 	   := 0
      _cJSonRet    := Nil
      _nTimOut	   := 720 // 120
      _cRetHttp    := ''
      _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )
      
      _cJsonComp := _cJSonColeta

      _cResult  := ""
      _cSucesso := ""
      _cErro    := ""
      _aSucesso := {}
      _aErro    := {}

      If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
         _cRetHttp := DecodeUtf8(_cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )

         _oJson := JsonObject():new()
         _cRet := _oJson:FromJson(_cRetHttp)
         
         _cResult  := _oJson:GetJsonObject("status")
         _oResult  := _oJson:GetJsonObject("result")
         _cSucesso := _oResult:GetJsonObject("success")
         _cErro    := _oResult:GetJsonObject("error")
      EndIf

      If ValType(_cResult) <> "C"  
         _cResult := ""
      EndIf 

      _aSucesso := StrTokArr2(_cSucesso,",")
                  
      For _nJ := 1 To Len(_aSucesso) 
         
          _cCodigoCo := AllTrim(_aSucesso[_nJ])
          _nX := aScan(_aColetas,{|x| x[1] == _cCodigoCo})
          If _nX > 0
             _aColetas[_nX,6] := "A"
          EndIf  
      Next _nJ

      For _nX := 1 To Len(_aColetas)
         
          If _aColetas[_nX,6] == "A"
             // Grava dados das coletas enviadas e aceitas para histórico.
             ZBI->(RecLock("ZBI",.T.))
             ZBI->ZBI_FILIAL  := xFilial("ZBI")                         // Filial do Sistema
             ZBI->ZBI_TICKET  := _aColetas[_nX,1]                       // Ticket
             ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-","")) // Data Coleta
             ZBI->ZBI_CODPRO  := _aColetas[_nX,2]                       // Codigo do Produtor
             ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]                       // Loja do Produtor
             ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]                       // Nome
             ZBI->ZBI_MOTIVO  := AllTrim(_cRetHttp)                     // Motivo da Rejeição
             ZBI->ZBI_JSONEN  := _aColetas[_nX,8]                       // _cJSonColeta  // Json de Envio
             ZBI->ZBI_DTENV	:= Date()                                 // Data de Envio
             ZBI->ZBI_HRENV	:= Time()                                 // Hora de Envio
             ZBI->ZBI_STATUS  := "A"                                    // Status da Integração
             ZBI->ZBI_WEBINT  := "E"                                    // Indica que a integração está sendo realizada com o App Evomilk
             ZBI->(MSUnLock())
             _nAceitos++

             // Atualiza a tabela ZLJ
             ZLJ->(DBGoTo(_aColetas[_nX,7]))
             ZLJ->(RecLock("ZLJ", .F.))
             ZLJ->ZLJ_ENVEVO := "N"
             ZLJ->(MSUnLock())
          Else
             // Grava dados das coletas enviadas e rejeitadas para histórico.
             ZBI->(RecLock("ZBI",.T.))
             ZBI->ZBI_FILIAL  := xFilial("ZBI")                          // Filial do Sistema
             ZBI->ZBI_TICKET  := _aColetas[_nX,1]                        // Ticket
             ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
             ZBI->ZBI_CODPRO  := _aColetas[_nX,2]                        // Codigo do Produtor
             ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]                        // Loja do Produtor
             ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]                        // Nome
             ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)                     // Motivo da Rejeição
             ZBI->ZBI_DTREJ   :=  Date()                                 // Data da Rejeição
             ZBI->ZBI_HRREJ   :=  Time()                                 // Hora da Rejeição
             ZBI->ZBI_JSONEN  :=  _cJsonComp // _aColetas[_nX,8]         //_cJSonColeta              // Json de Envio
             ZBI->ZBI_DTENV	:=  Date()                                 // Data de Envio
             ZBI->ZBI_HRENV   :=  Time()                                 // Hora de Envio
             ZBI->ZBI_STATUS  :=  "R"                                    // Status da Integração
             ZBI->ZBI_WEBINT  :=  "E"                                    // Indica que a integração está sendo realizada com o App Evomilk
             ZBI->(MSUnLock())
             _nRejeitados++
          EndIf
      Next
   EndIf
End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032T
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Efetua o Login no WebService da Evomilk e obtem o Token de acesso.
                     O Período estimado de validade deste Token é de 30 min.
Parametros---------: _cChamada = "M" = Menu
                                 "S" = Scheduller
Retorno------------: _cRet = Vazio ou o Token de acesso.
===============================================================================================================================
*/
User Function MGLT032T(_cChamada)

Local _cRet := ""
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local _cDirJSon, _cLinkWS
Local _cUsuario, _cSenha
Local _aHeadOut := {}
Local _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")

Default _cChamada := "M"

Begin Sequence

   _cUsuario := ""
   _cSenha   := ""

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK01)   // LINK DE LOGIN E OBTENÇÃO DO TOKEN
      _cUsuario := AllTrim(ZFM->ZFM_USRNOM)
      _cSenha   := AllTrim(ZFM->ZFM_SENHA)
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil
   _nTimOut	 	:= 720

   _aHeadOut := {}
   aAdd(_aHeadOut,'Content-Type: application/json')
   //aAdd(_aHeadOut,'Authorization: Basic '+Encode64("api.italac:api.italac.2021"))
   aAdd(_aHeadOut,'Authorization: Basic '+Encode64(_cUsuario + ":" + _cSenha))
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

   _cLinkWS := AllTrim(_cLinkWS)

   _cGetParms := ""

   // Envio do JSon
   _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , '{}' , _nTimOut , _aHeadOut , @_cJSonRet ) )

   _oRetJSon := Nil
   _cKey := ""
   _oTokenJSon := Nil

   If ! Empty(_cRetHttp)
      _cRetHttp := StrTran( _cRetHttp, "\n", "" )
      FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
   EndIf

   If ! Empty(_oRetJSon)
      _cKey := _oRetJSon:token
   Else
      Break
   EndIf

   _cRet := _cKey

End Sequence

Return _cRet

/*
===============================================================================================================================
Função-------------: MGLT032X
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição---------: Lê o arquivo JSON modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/
User Function MGLT032X(_cArq)

Local _cRet := ""
Local _nStatusArq
Local _cLine

Begin Sequence
   _nStatusArq := FT_FUse(_cArq)

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
Função-------------: MGLT032TXT
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição---------: Lê o arquivo texto no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/
Static Function MGLT032TXT(_cArq)

Local _aRet := {}
Local _nStatusArq
Local _cLine

Begin Sequence
   _nStatusArq := FT_FUse(_cArq)

   // Se houver erro de abertura abandona processamento
   If _nStatusArq = -1
      Break
   EndIf

   // Posiciona na primeria linha
   FT_FGoTop()

   While !FT_FEOF()
      _cLine := FT_FReadLn()

      _cline :=  AllTrim(_cLine) + ";" + CRLF

      _aDados := U_ITTXTARRAY(_cline,";",3)

      aAdd(_aRet,Aclone(_aDados))

      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _aRet

/*
===============================================================================================================================
Função-------------: MGLT032S
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente as integrações de envio de dados para o
                     App Evomilk
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032S()

Local _cFilIntWS, _aFilIntWS
Local _nI
Local _LigaDesWS

Begin Sequence

   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   RESET ENVIRONMENT
   RpcSetType(2) // 3

   // Inicia processamento com base nas filiais do parâmetro.

   // Preparando o ambiente com a filial 01
   RpcSetEnv("01", "01",,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM"})

   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   // Liga ou Desliga a integração Webservice via Scheduller
   _LigaDesWS := SUPERGETMV('IT_LIGAWSE',.F.,  .T.)
   If ! _LigaDesWS
      Break
   EndIf

   // Inicia a Integração Webservice via Scheduller.
   _cFilIntWS := SUPERGETMV('IT_FILITEV',.F.,  "01;")

   _aFilIntWS := {}

   ZZM->(DBGoTop())

   While ! ZZM->(Eof())
      If ZZM->ZZM_CODIGO $ _cFilIntWS
         aAdd(_aFilIntWS,ZZM->ZZM_CODIGO)
      EndIf

      ZZM->(DBSkip())
   EndDo

   // Para cada empresa cadastrada no parâmetro IT_FILITEV, inicializa o ambiente, simulando o usuário
   // fazendo login na filial a ser processada.
   For _nI := 1 To Len(_aFilIntWS)

       _cfilial := _aFilIntWS[_nI]

       // Ativa a filial contida em _aFilIntWS
       RESET ENVIRONMENT
       RpcSetType(2) // 3

       // Inicia processamento com base nas filiais do parâmetro.

       // Preparando o ambiente com a filial 01
       RpcSetEnv("01", _cfilial ,,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM"})

       Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

       cFilAnt := _cfilial

	    cUSUARIO := Space(06)+"Administrador  " // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
	    cUserName:= "Schedule" // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.

       // Rotina de integração de envio dos dados de Produtores, Coleta de Leite e Recebimento dos dados
       // dos Produtores do App Evomilk

       U_MGLT032(.T.)  // .T. = Indica que a rotina foi chamada via Scheduller.

   Next

 End Sequence

 Return

/*
===============================================================================================================================
Função-------------: MGLT032O
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina alternativa de envio dos dados das coletas para o App Evomilk.
                     Esta rotina utiliza um parâmetro de data inicial de leitura diferente e possibilita a rotina de Scheduller
                     funcionar.
Parametros---------: _lSchedule = Indica se a rotina foi chamada via Scheduller ou não.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032O(_lSchedule)

Private _lHaDadosD := .F.
Private _nTotRegs  := 0

Default _lSchedule := .F.

Begin Sequence

   // Envia Dados dos Volumes coletados.
   If ! _lSchedule
      If ! U_ITMsg("Confirma o envio dos dados das coletas de leite para o sistema da Evomilk?","Atenção" , , ,2, 2)
         Break
      EndIf
   EndIf

   If ! _lSchedule
      ProcRegua(0)

      Processa( {|| U_MGLT032M(_lSchedule) } , 'Aguarde!' , 'Lendo dados das Coletas de Leite...' )
      If _lHaDadosD
         Processa( {|| U_MGLT032N("M") } , 'Aguarde!' , 'Enviando dados das Coletas de Leite...' ) // Envia os dados dos Produtores via Integração WebService.
      EndIf

      U_ITMsg("Envio dos dados das Coletas de Leite para o sistema Evomilk Concluido.","Atenção",,2)

   Else
      U_MGLT032M(_lSchedule)  // Faz a leitura dos dados.
      If _lHaDadosD
         U_MGLT032N("S") // Envia os dados das Coletas via Integração WebService.
      EndIf

   EndIf

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032M
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina alternativa de leitura e envio de dados dos Volumes de Leite Coletados.
                     Esta rotina utiliza outro parâmetro de data inicial possibilitando enviar os dados juntamente com a
                     rotina de Scheduller funcionando.
Parametros---------: _lSchedule = .T. = Rotina chamada via scheduller
                                    .F. = Rotina chamada via menu.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032M(_lSchedule)

Local _aStruct   := {}
Local _cDtColIni := SUPERGETMV('IT_DTCOLEV',.F.,  "01/05/2025") // SUPERGETMV('IT_DTCOL02',.F.,"01/10/2024")
Local _oTemp3
Local _cFilEnvC := xFilial("ZL3")

Default _lSchedule := .F.

Begin Sequence

   If ! _lSchedule
      IncProc("Gerando dados das Coletas de Leita para envio...")
   EndIf

   // Cria Tabela Temporária para armazenar dados do JSon
   _aStruct := {}
   aAdd(_aStruct,{"ZLJ_VIAGEM","C",10 ,0})  // numero_identificador: "06019"
   aAdd(_aStruct,{"ZLJ_CODPAT","C",6  ,0})  // matricula_produtor //A2_COD
   aAdd(_aStruct,{"ZLJ_LOJPAT","C",4  ,0})  // matricula_produtor //A2_LOJA
   aAdd(_aStruct,{"ZLJ_VOLUME","N",14 ,0})  // volume_litros
   aAdd(_aStruct,{"ZLJ_DTIVIA","D",8  ,0})  // data_coleta
   aAdd(_aStruct,{"ZLJ_HRINI" ,"C",8  ,0})  // hora_coleta   //aAdd(_aStruct,{"WK_HORACOL","C",8  ,0})  // hora_coleta
   aAdd(_aStruct,{"WK_OBSERV" ,"C",100,0})  // observações
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno da Tabela ZLJ

   If Select("TRBCL2") > 0
      TRBCL2->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp3 := FWTemporaryTable():New( "TRBCL2",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp3:AddIndex( "01", {"ZLJ_CODPAT","ZLJ_LOJPAT"})

   _oTemp3:Create()

   DBSelectArea("TRBCL2")

   // Monta select de leitura de dados do cadastro de Produtores rurais.
   _nTotRegs := 0

   If ! _lSchedule
      _cQry := " SELECT COUNT(*) AS TOTREGS "       // numero_identificador: "06019"
      _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2 "
      _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
      If ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
         _cQry += " AND (ZLJ.ZLJ_ENVEVO = ' ' OR ZLJ.ZLJ_ENVEVO = 'S')  "
      EndIf
      _cQry += " AND ZLJ_DTIVIA >= '"+ DToS(Ctod(_cDtColIni)) + "' "
      _cQry += " AND ZLJ_CODPAT = A2_COD AND ZLJ_LOJPAT = A2_LOJA "
      _cQry += " AND SA2.A2_L_ITCOL = 'S' "
      _cQry += " AND ZLJ_FILIAL = '" + _cFilEnvC + "' "
      _cQry += " ORDER BY ZLJ_CODPAT,ZLJ_LOJPAT "

      If Select("QRY2ZLJ") > 0
         QRY2ZLJ->(DBCloseArea())
      EndIf

      MPSysOpenQuery( _cQry , "QRY2ZLJ")

      _nTotRegs := QRY2ZLJ->TOTREGS
   EndIf

   If Select("QRY2ZLJ") > 0
      QRY2ZLJ->(DBCloseArea())
   EndIf

   // Monta select de leitura de dados do cadastro de Produtores rurais.
   _cQry := " SELECT ZLJ_VIAGEM, "       // numero_identificador: "06019"
   _cQry += " ZLJ_CODPAT, "              // matricula_produtor //A2_COD
   _cQry += " ZLJ_LOJPAT, "              // matricula_produtor //A2_LOJA
   _cQry += " ZLJ_VOLUME, "              // volume_litros
   _cQry += " ZLJ_DTIVIA, "              // data_coleta
   _cQry += " ZLJ_HRINI, "               // HORARIO INICIAL COLETA // ZLJ_HRFIM = HORARIO FINAL COLETA
   _cQry += " ZLJ.R_E_C_N_O_ AS NRREG "
   _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2 "
   _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
   If ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
      _cQry += " AND (ZLJ.ZLJ_ENVEVO = ' ' OR ZLJ.ZLJ_ENVEVO = 'S')  "
   EndIf
   _cQry += " AND ZLJ_DTIVIA >= '"+ DToS(Ctod(_cDtColIni)) + "' "
   _cQry += " AND ZLJ_CODPAT = A2_COD AND ZLJ_LOJPAT = A2_LOJA "
   _cQry += " AND SA2.A2_L_ITCOL = 'S' "
   _cQry += " AND ZLJ_FILIAL = '" + _cFilEnvC + "' "
   _cQry += " ORDER BY ZLJ_CODPAT,ZLJ_LOJPAT "

   If Select("QRY2ZLJ") > 0
      QRY2ZLJ->(DBCloseArea())
   EndIf


   MPSysOpenQuery( _cQry , "QRY2ZLJ")

   QRY2ZLJ->(DBGoTop())

   If ! _lSchedule
      ProcRegua(_nTotRegs)
   EndIf
   _cTot:=AllTrim(Str(_nTotRegs))
   nConta:=0

   While ! QRY2ZLJ->(Eof())

      nConta++
      If ! _lSchedule
         IncProc("Lendo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      TRBCL2->(DbAppend())
      TRBCL2->ZLJ_VIAGEM := QRY2ZLJ->ZLJ_VIAGEM         // C 6   // numero_identificador: "06019"
      TRBCL2->ZLJ_CODPAT := QRY2ZLJ->ZLJ_CODPAT         // C 6   // matricula_produtor //A2_COD
      TRBCL2->ZLJ_LOJPAT := QRY2ZLJ->ZLJ_LOJPAT         // C 4   // matricula_produtor //A2_LOJA
      TRBCL2->ZLJ_VOLUME := QRY2ZLJ->ZLJ_VOLUME         // N 14  // volume_litros
      TRBCL2->ZLJ_DTIVIA := SToD(QRY2ZLJ->ZLJ_DTIVIA)   // D 8   // data_coleta
      TRBCL2->ZLJ_HRINI  := QRY2ZLJ->ZLJ_HRINI          // C 8   // hora_coleta
      TRBCL2->WK_OBSERV  := ""                         // C 100 // observações
      TRBCL2->WK_RECNO   := QRY2ZLJ->NRREG              // N 10  // Recno da Tabela ZLJ

      _lHaDadosD := .T.

      QRY2ZLJ->(DBSkip())
   EndDo

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032N
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de Envio de dados das coletas via WebService Italac para Sistema Evomilk
                     Rotina alternativa que utilizar outro parâmetro de período inicial, possibilitando utilizar a rotina
                     juntamente com a rotina do Scheduller.
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032N(_cChamada)

Local _cColetaL := ""
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local _cJSonEnv
Local _nStart
Local _nRetry
Local _cJSonRet
Local _nTimOut
Local _cRetHttp
Local _cJSonColeta, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 50 //  1 // 100  // Total de registros para envio.
Local _nI , _oRetJSon, _lResult
Local _aColetaEnv
Local _cDataCol
Local _nRecno := 0
Local _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
Local _nIntervalo 

Private _cNrIdent
Private _cNrMatr
Private _cVolume
Private _cDtColeta
Private _cHoraCol
Private _cObserv

Default _cChamada := "M"

Begin Sequence
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK03) // Link de envio da coleta do leite.
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cColetaL := U_MGLT032X(_cDirJSon+"Coleta_de_Leite.txt")

   If Empty(_cColetaL)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo Coleta de Leite integração Italac x Evomilk","Atenção",,1)
      EndIf

      Break
   EndIf

   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf

   _cHoraIni := Time() // Horario Inicial de Processamento

   _aHeadOut := {}

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

   If _cChamada == "M"
      ProcRegua(_nTotRegs)
   EndIf
   _cTot:=AllTrim(Str(_nTotRegs))
   nConta:=0

   _cJSonColeta := "["
   _cJSonGrp    := ""
   _nI := 1
   _nIntervalo := 5

   _aColetaEnv := {}

   TRBCL2->(DBGoTop())
   While ! TRBCL2->(Eof())

      If _cChamada == "M"
         nConta++
         IncProc("Transmitindo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))
      If _nMinutos > _nIntervalo // 5 // 28 // minutos
         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _cChamada == "M" // Chamada via menu.
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
            EndIf

            Break
         EndIf

         _aHeadOut := {}
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

         _cHoraIni := Time()

      EndIf

      // Efetua a leitura dos dados e montagem do JSon.
      _cNrIdent  := TRBCL2->ZLJ_VIAGEM // C 6   // numero_identificador: "06019"
      _cNrMatr   := TRBCL2->ZLJ_CODPAT + "-" + TRBCL2->ZLJ_LOJPAT // C 6   // matricula_produtor //A2_COD
      _cVolume   := AllTrim(Str(TRBCL2->ZLJ_VOLUME,14))         // N 14  // volume_litros
      _cDtColeta := StrZero(Year(TRBCL2->ZLJ_DTIVIA),4) + "-" + StrZero(Month(TRBCL2->ZLJ_DTIVIA),2) + "-" + StrZero(Day(TRBCL2->ZLJ_DTIVIA),2)      // D 8   // data_coleta
      _cHoraCol  := TRBCL2->ZLJ_HRINI                           // WK_HORACOL                          // C 8   // hora_coleta
      _cObserv   := TRBCL2->WK_OBSERV                           // C 100 // observações
      _nRecno    := TRBCL2->WK_RECNO

      _cJSonEnv := &(_cColetaL)

      _cJSonGrp += If(!Empty(_cJSonGrp),",","") + _cJSonEnv

      If _nI >= _nTotRegEnv

         _cJSonColeta += _cJSonGrp + "]"

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil
         _nTimOut	 	:= 720

         _cRetHttp    := ''

         _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )

         If ! Empty(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
         EndIf

         If ! Empty(_oRetJSon)
            _lResult := _oRetJSon:resultado
         EndIf

         If _lResult // Integração realizada com sucesso

            // Grava dados das coletas enviadas e aceitas para histórico.
            _cDataCol := StrTran(_cDtColeta,"-","")

            _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado

            ZBI->(RecLock("ZBI",.T.))
            ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
            ZBI->ZBI_TICKET  := _cNrIdent                  // Ticket
            ZBI->ZBI_DTCOLE  := SToD(_cDataCol)            // Data Coleta
            ZBI->ZBI_CODPRO  :=  SubStr(_cNrMatr,1,6)      // Codigo do Produtor
            ZBI->ZBI_LOJPRO  :=  SubStr(_cNrMatr,8,4)      // Loja do Produtor

            If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
               _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador

               ZBI->ZBI_NOMPRO := _cNomeCoop
            Else
               ZBI->ZBI_NOMPRO  :=  Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
            EndIf

            ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)        // Motivo da Rejeição
            ZBI->ZBI_JSONEN  :=  _cJSonColeta              // Json de Envio
            ZBI->ZBI_DTENV	  :=  Date()                    // Data de Envio
            ZBI->ZBI_HRENV	  :=  Time()                    // Hora de Envio
            ZBI->ZBI_STATUS  :=  "A"                       // Status da Integração
            ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
            ZBI->(MSUnLock())

            // Atualiza a tabela ZLJ
            If _nRecno > 0 .And. ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0 // ENVIO DA COLETA
               ZLJ->(DBGoTo(_nRecno))
               ZLJ->(RecLock("ZLJ", .F.))
               ZLJ->ZLJ_ENVEVO := "N"
               ZLJ->(MSUnLock())
               _nRecno := 0
            EndIf
         Else
            _cDataCol := StrTran(_cDtColeta,"-","")

            _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado

            // Grava dados das coletas enviadas e rejeitadas para histórico.
            ZBI->(RecLock("ZBI",.T.))
            ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
            ZBI->ZBI_TICKET  := _cNrIdent                  // Ticket
            ZBI->ZBI_DTCOLE  := SToD(_cDataCol)            // Data Coleta
            ZBI->ZBI_CODPRO  :=  SubStr(_cNrMatr,1,6)      // Codigo do Produtor
            ZBI->ZBI_LOJPRO  :=  SubStr(_cNrMatr,8,4)      // Loja do Produtor

            If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
               _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador

               ZBI->ZBI_NOMPRO := _cNomeCoop
            Else
               ZBI->ZBI_NOMPRO  :=  Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
            EndIf

            ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)        // Motivo da Rejeição
            ZBI->ZBI_DTREJ   :=  Date()                    // Data da Rejeição
            ZBI->ZBI_HRREJ   :=  Time()                    // Hora da Rejeição
            ZBI->ZBI_JSONEN  :=  _cJSonColeta              // Json de Envio
            ZBI->ZBI_DTENV	  :=  Date()                    // Data de Envio
            ZBI->ZBI_HRENV	  :=  Time()                    // Hora de Envio
            ZBI->ZBI_STATUS  :=  "R"                       // Status da Integração
            ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
            ZBI->(MSUnLock())

         EndIf

         _aColetaEnv := {}
         _cJSonColeta := "["
         _cJSonGrp := ""
         _nI := 0

      EndIf

      _nI += 1

      TRBCL2->(DBSkip())
   EndDo

   If ! Empty(_cJSonGrp)
      _cJSonColeta += _cJSonGrp + "]"
      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil
      _nTimOut	 	:= 720

      _cRetHttp    := ''

      _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )

      If ! Empty(_cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
      EndIf

      If ! Empty(_oRetJSon)
         _lResult := _oRetJSon:resultado
      EndIf

      If _lResult // Integração realizada com sucesso

         _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado

         // Grava dados das coletas enviadas e aceitas para histórico.
         ZBI->(RecLock("ZBI",.T.))
         ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
         ZBI->ZBI_TICKET  := _cNrIdent                  // Ticket
         ZBI->ZBI_DTCOLE  := SToD(_cDataCol)            // Data Coleta
         ZBI->ZBI_CODPRO  := SubStr(_cNrMatr,1,6)       // Codigo do Produtor
         ZBI->ZBI_LOJPRO  := SubStr(_cNrMatr,1,4)       // Loja do Produtor

         If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
            _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador

            ZBI->ZBI_NOMPRO := _cNomeCoop
         Else
            ZBI->ZBI_NOMPRO  := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
         EndIf

         ZBI->ZBI_MOTIVO  := AllTrim(_cRetHttp)         // Motivo da Rejeição
         ZBI->ZBI_JSONEN  := _cJSonColeta               // Json de Envio
         ZBI->ZBI_DTENV	  :=  Date()                    // Data de Envio
         ZBI->ZBI_HRENV	  :=  Time()                    // Hora de Envio
         ZBI->ZBI_STATUS  :=  "A"                       // Status da Integração
         ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
         ZBI->(MSUnLock())

         // Atualiza a tabela ZLJ
         If _nRecno > 0 .And. ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
            ZLJ->(DBGoTo(_nRecno))
            ZLJ->(RecLock("ZLJ", .F.))
            ZLJ->ZLJ_ENVEVO := "N"
            ZLJ->(MSUnLock())
            _nRecno := 0
         EndIf
      Else
         _cDataCol := StrTran(_cDtColeta,"-","")

         _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado

         // Grava dados das coletas enviadas e rejeitadas para histórico.
         ZBI->(RecLock("ZBI",.T.))
         ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
         ZBI->ZBI_TICKET  := _cNrIdent                  // Ticket
         ZBI->ZBI_DTCOLE  := SToD(_cDataCol)            // Data Coleta
         ZBI->ZBI_CODPRO  := SubStr(_cNrMatr,1,6)       // Codigo do Produtor
         ZBI->ZBI_LOJPRO  := SubStr(_cNrMatr,1,4)       // Loja do Produtor

         If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
            _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador

            ZBI->ZBI_NOMPRO := _cNomeCoop
         Else
            ZBI->ZBI_NOMPRO  := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
         EndIf

         ZBI->ZBI_MOTIVO  := AllTrim(_cRetHttp)         // Motivo da Rejeição
         ZBI->ZBI_DTREJ   := Date()                     // Data da Rejeição
         ZBI->ZBI_HRREJ   := Time()                     // Hora da Rejeição
         ZBI->ZBI_JSONEN  := _cJSonColeta               // Json de Envio
         ZBI->ZBI_DTENV	  :=  Date()                    // Data de Envio
         ZBI->ZBI_HRENV	  :=  Time()                    // Hora de Envio
         ZBI->ZBI_STATUS  :=  "R"                       // Status da Integração
         ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
         ZBI->(MSUnLock())

      EndIf
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032J
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Gera arquivo TXT com as coletas de Jaru, para importação de dados da Evomilk no período de:
                     01/01/2021 a 31/12/2021.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032J()

Local _nI
Local _ddata := Ctod("01/01/2021")

Private _nTotRegs := 0

Begin Sequence
   // Gera arquivo TXT com os Dados dos Volumes coletados exclusivo par Jaru.

   For _nI := 1 To  365
       If ! U_ITMsg("Confirma a geração do arquivo TxT com os dados das coletas de Jaru para envio a Evomilk? Periodo: "+DToC(_ddata),"Atenção" , , ,2, 2)
          Break
       EndIf

       ProcRegua(0)

       Processa( {|| U_MGLT032A(_ddata) } , 'Aguarde!' , 'Lendo dados das Coletas de Leite...' )

       Processa( {|| U_MGLT032B(DToC(_ddata)) } , 'Aguarde!' , 'Gravando Arquivo Texto das Coletas de Leite...' )

       _ddata := _ddata + 1

       U_ITMsg("Geração de arquivo TXT com os dados das Coletas de Leite de Jaru Concluido.","Atenção",,2)
   Next

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032A
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Faz a leitura dos dados das coletas de leite de Jaru para geração de arquivo Texto.
                     Para envio para Evomilk.
Parametros---------: _dDataMin = Data minima de leitura.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032A(_dDataMin)

Local _aStruct   := {}

Begin Sequence

   IncProc("Gerando dados das Coletas de Leita para geração de Txt de Jaru...")

   // Cria Tabela Temporária para armazenar dados do JSon
   _aStruct := {}
   aAdd(_aStruct,{"ZLJ_VIAGEM","C",10 ,0})  // numero_identificador: "06019"
   aAdd(_aStruct,{"ZLJ_CODPAT","C",6  ,0})  // matricula_produtor //A2_COD
   aAdd(_aStruct,{"ZLJ_LOJPAT","C",4  ,0})  // matricula_produtor //A2_LOJA
   aAdd(_aStruct,{"ZLJ_VOLUME","N",14 ,0})  // volume_litros
   aAdd(_aStruct,{"ZLJ_DTIVIA","D",8  ,0})  // data_coleta
   aAdd(_aStruct,{"ZLJ_HRINI" ,"C",8  ,0})  // hora_coleta   //aAdd(_aStruct,{"WK_HORACOL","C",8  ,0})  // hora_coleta
   aAdd(_aStruct,{"WK_OBSERV" ,"C",100,0})  // observações
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno da Tabela ZLJ

   If Select("TRBCOLT") > 0
      TRBCOLT->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp3 := FWTemporaryTable():New( "TRBCOLT",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp3:AddIndex( "01", {"ZLJ_CODPAT","ZLJ_LOJPAT"})

   _oTemp3:Create()

   DBSelectArea("TRBCOLT")

   // Monta select de leitura de dados do cadastro de Produtores rurais.
   _nTotRegs := 0

   _cQry := " SELECT COUNT(*) AS TOTREGS "       // numero_identificador: "06019"
   _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2 "
   _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
   If ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
      _cQry += " AND (ZLJ.ZLJ_ENVEVO = ' ' OR ZLJ.ZLJ_ENVEVO = 'S')  "
   EndIf
   _cQry += " AND ZLJ_DTIVIA < '20220101' "
   _cQry += " AND ZLJ_DTIVIA = '"+ DToS(_dDataMin) + "' "
   _cQry += " AND ZLJ_CODPAT = A2_COD AND ZLJ_LOJPAT = A2_LOJA "
   _cQry += " AND SA2.A2_L_ITCOL = 'S' "
   _cQry += " AND ZLJ_FILIAL = '10' "
   _cQry += " ORDER BY ZLJ_CODPAT,ZLJ_LOJPAT "

   If Select("QRYZLJT") > 0
      QRYZLJT->(DBCloseArea())
   EndIf


   MPSysOpenQuery( _cQry , "QRYZLJT")

   _nTotRegs := QRYZLJT->TOTREGS

   If Select("QRYZLJT") > 0
      QRYZLJT->(DBCloseArea())
   EndIf

   // Monta select de leitura de dados do cadastro de Produtores rurais.
   _cQry := " SELECT ZLJ_VIAGEM, "       // numero_identificador: "06019"
   _cQry += " ZLJ_CODPAT, "              // matricula_produtor //A2_COD
   _cQry += " ZLJ_LOJPAT, "              // matricula_produtor //A2_LOJA
   _cQry += " ZLJ_VOLUME, "              // volume_litros
   _cQry += " ZLJ_DTIVIA, "              // data_coleta
   _cQry += " ZLJ_HRINI, "               // HORARIO INICIAL COLETA // ZLJ_HRFIM = HORARIO FINAL COLETA
   _cQry += " ZLJ.R_E_C_N_O_ AS NRREG "
   _cQry += " FROM " + RetSqlName("ZLJ") + " ZLJ, " + RetSqlName("SA2") + " SA2 "
   _cQry += " WHERE ZLJ.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
   If ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
      _cQry += " AND (ZLJ.ZLJ_ENVEVO = ' ' OR ZLJ.ZLJ_ENVEVO = 'S')
   EndIf
   _cQry += " AND ZLJ_DTIVIA >= '"+ DToS(Ctod(_cDtColIni)) + "' "
   _cQry += " AND ZLJ_DTIVIA = '"+ DToS(_dDataMin) + "' "
   _cQry += " AND ZLJ_CODPAT = A2_COD AND ZLJ_LOJPAT = A2_LOJA "
   _cQry += " AND SA2.A2_L_ITCOL = 'S' "
   _cQry += " AND ZLJ_FILIAL = '10' "
   _cQry += " ORDER BY ZLJ_CODPAT,ZLJ_LOJPAT "

   If Select("QRYZLJT") > 0
      QRYZLJT->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYZLJT")

   QRYZLJT->(DBGoTop())

   ProcRegua(_nTotRegs)
   _cTot:=AllTrim(Str(_nTotRegs))
   nConta:=0

   While ! QRYZLJT->(Eof())
      nConta++
      IncProc("Lendo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)

      TRBCOLT->(DbAppend())
      TRBCOLT->ZLJ_VIAGEM := QRYZLJT->ZLJ_VIAGEM         // C 6   // numero_identificador: "06019"
      TRBCOLT->ZLJ_CODPAT := QRYZLJT->ZLJ_CODPAT         // C 6   // matricula_produtor //A2_COD
      TRBCOLT->ZLJ_LOJPAT := QRYZLJT->ZLJ_LOJPAT         // C 4   // matricula_produtor //A2_LOJA
      TRBCOLT->ZLJ_VOLUME := QRYZLJT->ZLJ_VOLUME         // N 14  // volume_litros
      TRBCOLT->ZLJ_DTIVIA := SToD(QRYZLJT->ZLJ_DTIVIA)   // D 8   // data_coleta
      TRBCOLT->ZLJ_HRINI  := QRYZLJT->ZLJ_HRINI          // C 8   // hora_coleta
      TRBCOLT->WK_OBSERV  := ""                         // C 100 // observações
      TRBCOLT->WK_RECNO   := QRYZLJT->NRREG              // N 10  // Recno da Tabela ZLJ

      _lHaDadosC := .T.

      QRYZLJT->(DBSkip())
   EndDo

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032B
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de geração de arquivo TxT para envio a Evomilk. Exclusivo da filial Jaru.
                     No periodo de 01/01/2021 a 31/12/2021.
Parametros--------:  _dDataTXT = Data de geração do TXT.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032B(_dDataTXT)

Local _cColetaL := ""
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local _cJSonEnv
Local _cJSonColeta, _cJSonGrp
Local _nRecno := 0

Private _cNrIdent
Private _cNrMatr
Private _cVolume
Private _cDtColeta
Private _cHoraCol
Private _cObserv

_cDirTXT:=_cNomeArq:=""

Begin Sequence
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK03) // Link de envio da coleta do leite.
   Else
      U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Break
   EndIf

   If Empty(_cDirJSon)
      U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cColetaL := U_MGLT032X(_cDirJSon+"Coleta_de_Leite.txt")

   If Empty(_cColetaL)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo Coleta de Leite integração Italac x Evomilk","Atenção",,1)
      Break
   EndIf

   ProcRegua(_nTotRegs)

   _cDirTXT := "\data\Italac\CiaLeite\"//GetTempPath() //"\DATA\JULIO\"
   _cNomeArq:= "Coleta_Leite_Jaru_" + DToS(Ctod(_dDataTXT)) + ".Txt"

   _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)

   If ! _oFWriter:Create()
      U_ITMsg("Erro na criação do arquivo texto para gravação dos dados de coleta de Jaru, para envio a Evomilk.","Atenção",,1)
      Break
   EndIf

   _oFWriter:Write("[" + CRLF)

   _cJSonColeta := "["
   _cJSonGrp    := ""

   TRBCOLT->(DBGoTop())
   While ! TRBCOLT->(Eof())

      IncProc("Gerando arquivo texto [" + _dDataTXT + "]...")

      // Efetua a leitura dos dados e montagem do JSon.
      _cNrIdent  := TRBCOLT->ZLJ_VIAGEM                        // C 6   // numero_identificador: "06019"
      _cNrMatr   := TRBCOLT->ZLJ_CODPAT+"-"+TRBCOLT->ZLJ_LOJPAT    // C 6   // matricula_produtor //A2_COD
      _cVolume   := AllTrim(Str(TRBCOLT->ZLJ_VOLUME,14))         // N 14  // volume_litros
      _cDtColeta := StrZero(Year(TRBCOLT->ZLJ_DTIVIA),4) + "-" + StrZero(Month(TRBCOLT->ZLJ_DTIVIA),2) + "-" + StrZero(Day(TRBCOLT->ZLJ_DTIVIA),2)      // D 8   // data_coleta
      _cHoraCol  := TRBCOLT->ZLJ_HRINI                           // WK_HORACOL                          // C 8   // hora_coleta
      _cObserv   := TRBCOLT->WK_OBSERV                           // C 100 // observações
      _nRecno    := TRBCOLT->WK_RECNO

      _cJSonEnv := &(_cColetaL) + CRLF   // Incluir aqui comando para gravação da linha do aquivo texto.

      _oFWriter:Write(_cJSonEnv)

      _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado

      ZBI->(RecLock("ZBI",.T.))
      ZBI->ZBI_FILIAL  := xFilial("ZBI")                   // Filial do Sistema
      ZBI->ZBI_TICKET  := _cNrIdent                        // Ticket
      ZBI->ZBI_DTCOLE  := TRBCOLT->ZLJ_DTIVIA              //SToD(_cDataCol)                  // Data Coleta
      ZBI->ZBI_CODPRO  :=  SubStr(_cNrMatr,1,6)            // Codigo do Produtor
      ZBI->ZBI_LOJPRO  :=  SubStr(_cNrMatr,8,4)            // Loja do Produtor

      If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
         _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador

         ZBI->ZBI_NOMPRO := _cNomeCoop
      Else
         ZBI->ZBI_NOMPRO  := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
      EndIf

      ZBI->ZBI_MOTIVO  :=  "Enviado via Arquivo Texto"     // Motivo da Rejeição
      ZBI->ZBI_JSONEN  :=  _cJSonEnv                       // Json de Envio
      ZBI->ZBI_DTENV	  :=  Date()                          // Data de Envio
      ZBI->ZBI_HRENV	  :=  Time()                          // Hora de Envio
      ZBI->ZBI_STATUS  :=  "A"                             // Status da Integração
      ZBI->ZBI_WEBINT  :=  "E"                       // Indica que a integração está sendo realizada com o App Evomilk
      ZBI->(MSUnLock())

      // Atualiza a tabela ZLJ
      If _nRecno > 0 .And. ZLJ->(FIELDPOS("ZLJ_ENVEVO")) > 0
         ZLJ->(DBGoTo(_nRecno))
         ZLJ->(RecLock("ZLJ", .F.))
         ZLJ->ZLJ_ENVEVO := "N"
         ZLJ->(MSUnLock())
         _nRecno := 0
      EndIf

      TRBCOLT->(DBSkip())
   EndDo

   _oFWriter:Write("]")

   //Encerra o arquivo
   _oFWriter:Close()

End Sequence
Return

/*
===============================================================================================================================
Função-------------: MGLT032I
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Gera arquivo Texto com informações dos produtores usuários de tanques coletivos e produtores familiares, e
                     seus vinculos com os produtores principais.
                     A geração dos dados é por filial.
Parametros--------:  _cFilEnvio = Filial de geração dos dados
                     _cNomeFil  = Nome da Filial de Envio
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032I(_cFilEnvio,_cNomeFil)

Local _cQry := ""
Local _cLinha, _cClassif
Local _lLinhaUm
Local _cFazenda

Default _cFilEnvio := xFilial("ZL3")
Default _cNomeFil := ""

_cDirTXT  := GetTempPath()//"\data\Italac\CiaLeite\"//GetTempPath() //"\DATA\JULIO\"
_cNomeArq := "Listagem_com_Vinculação_Produtor_Usuario_TC_Familiar_e_Produtor_Principal_Filial_"

Begin Sequence

   _cQry := " SELECT DISTINCT A2_COD, "  // matricula_laticinio: TESTE_278363
   _cQry += " A2_LOJA, "                 // Loja_laticinio: TESTE_278363
   _cQry += " A2_NOME, "                 // nome_razao_social  : PRODUTOR TESTE 3337
   _cQry += " A2_CGC, "                  // cpf_cnpj: 349.812.172-34
   _cQry += " A2_L_FAZEN, "              // nome_propriedade_rural: PROPRIEDADE TESTE 001
   _cQry += " A2_L_NIRF, "               // NIRF: ABC4658
   _cQry += " A2_L_SIGSI, "              //
   _cQry += " A2_L_TANQ, "               // id_tipo_tanque: 1
   _cQry += " A2_L_TANLJ, "              //
   _cQry += " A2_L_CLASS, "
   _cQry += " SA2.R_E_C_N_O_ AS RECNOSA2, "
   _cQry += " (SELECT DISTINCT A2_CGC FROM " + RetSqlName("SA2") + " SA2B "
   _cQry += "  WHERE SA2B.D_E_L_E_T_ = ' ' AND SA2B.A2_COD = SA2.A2_L_TANQ AND SA2B.A2_LOJA = SA2.A2_L_TANLJ) AS CPFCNPJ "
   _cQry += " FROM " + RetSqlName("SA2") + " SA2, " + RetSqlName("ZL3") + " ZL3 "
   _cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND ZL3.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZL3_COD = A2_L_LI_RO "
   _cQry += " AND ZL3_FILIAL = '" + _cFilEnvio + "' " // Cada filial/Cnpj Italac possui um Usuário e Senha. Ler do cadastro empresas Webservice. Enviar apenas as filias 01, 04, 23. 01=Corumbaiba/GO, 04=Araguari/MG, 23=Tapejara/RS
   _cQry += " AND A2_I_CLASS = 'P' "
   _cQry += " AND A2_MSBLQL = '2' "
   _cQry += " AND A2_L_ATIVO <> 'N' "
   _cQry += " AND A2_COD <> '      ' "
   _cQry += " AND (A2_L_CLASS = 'U' OR A2_L_CLASS = 'F') "
   _cQry += " ORDER BY A2_COD,A2_LOJA "

   If Select("QRYSA2") > 0
         QRYSA2->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYSA2")

   _cCodForn := Space(6)

   QRYSA2->(DBGoTop())

   ProcRegua(0)

   _cDirTXT := GetTempPath()//"\data\Italac\CiaLeite\"//GetTempPath() //"\DATA\JULIO\"
   _cNomeArq:= _cNomeArq +_cFilEnvio + "_" + Lower(_cNomeFil) + ".Txt"

   _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)

   If ! _oFWriter:Create()
      U_ITMsg("Erro na criação do arquivo texto para gravação dos dados Produtores usuários tanque coletivos e familiares e seu vinculos com o produtor principal.","Atenção",,1)
      Break
   EndIf

   _oFWriter:Write("[" + CRLF)

   _lLinhaUm := .T.

   While ! QRYSA2->(Eof())
      IncProc("Gravando arquivo texto...")

      If Empty(QRYSA2->A2_COD) // Foi identificado no cadastro de fornecedores alguns registros sem o código preenchido.
         QRYSA2->(DBSkip())
         Loop
      EndIf

      _cClassif := ""
      If QRYSA2->A2_L_CLASS == "U"
         _cClassif := "USUARIO TANQUE COLETIVO"
      ElseIf QRYSA2->A2_L_CLASS == "F"
         _cClassif := "FAMILIAR"
      EndIf

      _cFazenda := AllTrim(StrTran(QRYSA2->A2_L_FAZEN,'"'," "))
      If _cFazenda == "--"
         _cFazenda := "SEM NOME"
      EndIf

      _cLinha := If(!_lLinhaUm,"," + CRLF ,"")
      _cLinha += '{ "matricula_laticinio" : "' + AllTrim(QRYSA2->A2_COD) + '",'
      _cLinha += ' "Loja_laticinio" : "' + AllTrim(QRYSA2->A2_LOJA) + '",'
      _cLinha += ' "nome_razao_social" : "' + AllTrim(QRYSA2-> A2_NOME)+ '",'
      _cLinha += ' "cpf_cnpj" : "' + AllTrim(QRYSA2->A2_CGC)+ '",'
      _cLinha += ' "nome_propriedade_rural" : "' + _cFazenda + '",'    // AllTrim(QRYSA2->A2_L_FAZEN)
      _cLinha += ' "classificacao_laticinio" : "' + AllTrim(_cClassif)+ '",'
      _cLinha += ' "nirf" : "' + AllTrim(QRYSA2->A2_L_NIRF) + '",'
      _cLinha += ' "sigsif" : "' + AllTrim(QRYSA2->A2_L_SIGSI)+ '",'
      _cLinha += ' "matricula_produtor_principal" : "' + AllTrim(QRYSA2->A2_L_TANQ)+ '",'
      _cLinha += ' "loja_produtor_principal" : "' + AllTrim(QRYSA2->A2_L_TANLJ)+ '",'
      _cLinha += ' "cpf_cnpj_produtor_principal" : "' + AllTrim(QRYSA2->CPFCNPJ) + '"} '

      _oFWriter:Write(_cLinha)

      QRYSA2->(DBSkip())

      _lLinhaUm := .F.

   EndDo

   _oFWriter:Write("]")

   //Encerra o arquivo
   _oFWriter:Close()

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032L
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Função Principal que Gera arquivo Texto com informações dos produtores usuários de tanques coletivos e
                     produtores familiares, e seus vinculos com os produtores principais.
                     A geração dos dados é por filial.
Parametros--------:  Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032L()
Local _nI
Local _aFilProc := {}

Begin Sequence

   If ! U_ITMsg("Confirma a geração do arquivo TxT com os vinculos Produtores usuários tanques coletivos/familiares e os produtores principais?","Atenção" , , ,2, 2)
      Break
   EndIf

   aAdd(_aFilProc, {"01","Corumbaiba"})    // CORUMBAIBA	   01
   aAdd(_aFilProc, {"04","Araguari"})      // ARAGUARI	   04
   aAdd(_aFilProc, {"23","Tapejara"})      // TAPEJARA	   23
   aAdd(_aFilProc, {"40","Tres Coracoes"}) // TRÊS CORAÇÕES 40
   aAdd(_aFilProc, {"24","Crissiumal"})    // CRISSIUMAL    24
   aAdd(_aFilProc, {"25","Girua"})         // GIRUÁ         25
   aAdd(_aFilProc, {"09","Ipora"})         // IPORÁ	      09
   aAdd(_aFilProc, {"02","Itapaci"})       // ITAPACI	      02
   aAdd(_aFilProc, {"10","Jaru"})          // JARU		      10
   aAdd(_aFilProc, {"11","Nova Mamore"})   // NOVA MAMORE	11
   aAdd(_aFilProc, {"20","Passo Fundo"})       // PASSO FUNDO	20
   aAdd(_aFilProc, {"06","Pontalina"})         // PONTALINA		06
   aAdd(_aFilProc, {"0B","Quirinopolis"})      // QUIRINÓPOLIS	0B
   aAdd(_aFilProc, {"93","Parana_Cascavel"})   // PARANA_CASCAVEL 93

   For _nI := 1 To Len(_aFilProc)
       Processa( {|| U_MGLT032I(_aFilProc[_nI,1],_aFilProc[_nI,2]) } , 'Aguarde!' , 'Gravando arquivo TXT...' )
   Next

   U_ITMsg("Termino da gravação do arquivo TXT.", "Atenção" ,,1)

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT32TXT
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Gera arquivo TXT com os dados dos Produtores. Faz a leitura dos dados por filial.
Parametros---------: _cTipoArq = Tipo de arquivo texto: PRODUTORES ou ASSOCIACOES
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT32TXT(_cTipoArq)

Local _cQry
Local _aFilSA2 := {}
Local _nI, _cFilEnvio

Private _nTotRegs := 0

Default _cTipoArq := "PRODUTORES"

Begin Sequence
   //==========================================================================
   // Gera arquivo TXT com os Dados dos Volumes coletados exclusivo par Jaru.
   //==========================================================================

   aAdd(_aFilSA2, { "01","CORUMBAIBA"})
   aAdd(_aFilSA2, { "04","ARAGUARI"})
   aAdd(_aFilSA2, { "23","TAPEJARA"})
   aAdd(_aFilSA2, { "40","TRES CORACOES"})
   aAdd(_aFilSA2, { "24","CRISSIUMAL"})
   aAdd(_aFilSA2, { "25","GIRUA"})
   aAdd(_aFilSA2, { "09","IPORA"})
   aAdd(_aFilSA2, { "02","ITAPACI"})
   aAdd(_aFilSA2, { "10","JARU"})
   aAdd(_aFilSA2, { "11","NOVA MAMORE"})
   aAdd(_aFilSA2, { "20","PASSO FUNDO"})
   aAdd(_aFilSA2, { "06","PONTALINA"})
   aAdd(_aFilSA2, { "0B","QUIRINOPOLIS"})
   aAdd(_aFilSA2, { "93","PARANA_CASCAVEL"})
   aAdd(_aFilSA2, { "31","CONCEICAO_DO_ARAGUAIA"})
   aAdd(_aFilSA2, { "32","COUTO_DE_MAGALHAES"})


   For _nI := 1 To Len(_aFilSA2)
       // Monta select de leitura de dados do cadastro de Produtores rurais.
       _cFilEnvio := _aFilSA2[_nI,1]

       _cQry := " SELECT DISTINCT A2_COD, "
       _cQry += " A2_LOJA, "
       _cQry += " A2_CGC, "
       _cQry += " A2_NOME, "
       _cQry += " A2_L_ATIVO, "
       _cQry += " A2_DTNASC,  "
       _cQry += " A2_L_LI_RO, "
       _cQry += " ZL3_DESCRI, "
       _cQry += " A2_EMAIL, "
       _cQry += " A2_L_TPASS, "
       _cQry += " A2_L_NATRA, "
       _cQry += " SA2.R_E_C_N_O_ AS NRREG "  // capacidade_refrigeracao: 307
       _cQry += " FROM " + RetSqlName("SA2") + " SA2, " + RetSqlName("ZL3") + " ZL3 "
       _cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND ZL3.D_E_L_E_T_ = ' ' "
       _cQry += " AND ZL3_COD = A2_L_LI_RO "
       _cQry += " AND ZL3_FILIAL = '" + _cFilEnvio + "' " // Cada filial/Cnpj Italac possui um Usuário e Senha. Ler do cadastro empresas Webservice. Enviar apenas as filias 01, 04, 23. 01=Corumbaiba/GO, 04=Araguari/MG, 23=Tapejara/RS
       _cQry += " AND A2_I_CLASS = 'P' "
       _cQry += " AND A2_MSBLQL = '2' "
       _cQry += " AND A2_COD <> '      ' "
       If _cTipoArq == "ASSOCIACOES"
          _cQry += " AND SA2.A2_L_NFPRO = 'S' "  // Quando SA2.A2_L_NFPRO = 'S' é Associação/Cooperativa/Associado/Cooperado
       EndIf
       _cQry += " ORDER BY A2_COD,A2_LOJA "

       If Select("QRYSA2") > 0
          QRYSA2->(DBCloseArea())
       EndIf

       MPSysOpenQuery( _cQry , "QRYSA2")

       TCSetField('QRYSA2',"A2_DTNASC","D",8,0)

       QRYSA2->(DBGoTop())

       DBSelectArea("QRYSA2")//O MPSysOpenQuery() NÃO DEIXA NA AREA NOVA

       Count to _nTotRegs

       QRYSA2->(DBGoTop())

       Processa( {|| U_MGLT32GRV(_aFilSA2[_nI,2],_nTotRegs, _cTipoArq) } , 'Aguarde!' , 'Gravando Arquivo Texto dos Produtores...' )

   Next

   U_ITMsg("Geração de arquivo TXT com os dados Produtores Concluido.","Atenção",,2)

End Sequence

If Select("QRYSA2") > 0
   QRYSA2->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Função-------------: MGLT32GRV
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de geração de arquivo TxT dos Produtores envio a Evomilk.
Parametros--------:  _cNomeFil = Nome da filial
                     _nTotRegs = numero total de registros
                     _cTipoArq = Tipo de aquivo (ASSOCIACAO/COOPERATIVA/ASSOCIADO/COOPERADO/PRODUTOR NORMAL)
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT32GRV(_cNomeFil,_nTotRegs,_cTipoArq)

Local _cDados, _cTipoEstb

Begin Sequence

   ProcRegua(_nTotRegs)

   _cDirTXT := GetTempPath() // "\data\Italac\CiaLeite\"//GetTempPath() //"\DATA\JULIO\"
   _cNomeArq:= "Produtores_de_" + AllTrim(_cNomeFil) +"_"+AllTrim(_cTipoArq)+ "_" + DToS(Date()) + ".Txt"

   _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)

   If ! _oFWriter:Create()
      U_ITMsg("Erro na criação do arquivo texto para gravação dos dados de coleta de Jaru, para envio a Evomilk.","Atenção",,1)
      Break
   EndIf

   _oFWriter:Write("UNIDADE;MATRICULA;CPF;NOME;DT_NASC_PROPRIEDADE;LINHA_ROTA;NOME_LINHA_ROTA;TIPO_ESTABELECIMENTO;STATUS;E_MAIL;" + CRLF)

   QRYSA2->(DBGoTop())

   While ! QRYSA2->(Eof())

      IncProc("Gerando arquivo texto: "+ AllTrim(_cNomeFil) + "...")

      _cTipoEstb := "-----"
      If QRYSA2->A2_L_TPASS == "A"
         _cTipoEstb := "ASSOCIAÇÃO/COOPERATIVA"
      ElseIf QRYSA2->A2_L_TPASS == "C"
         _cTipoEstb := "ASSOCIADO/COOPERADO"
      EndIf

      // Efetua a leitura dos dados e montagem do JSon.
      _cDados := AllTrim(_cNomeFil)+";"
      _cDados += QRYSA2->A2_COD + "-" + QRYSA2->A2_LOJA+";"
      _cDados += AllTrim(QRYSA2->A2_CGC) +";"

      If _cTipoArq == "ASSOCIACOES"
         If ! Empty(QRYSA2->A2_L_NATRA)
            _cDados += AllTrim(QRYSA2->A2_L_NATRA) + ";"
         Else
            _cDados += AllTrim(QRYSA2->A2_NOME) + ";"
         EndIf
      Else
         _cDados += AllTrim(QRYSA2->A2_NOME) + ";"
      EndIf

      _cDados += StrZero(Year(QRYSA2->A2_DTNASC),4)+"-"+StrZero(Month(QRYSA2->A2_DTNASC),2)+"-"+StrZero(Day(QRYSA2->A2_DTNASC),2)+";"
      _cDados += AllTrim(QRYSA2->A2_L_LI_RO) + ";"
      _cDados += AllTrim(QRYSA2->ZL3_DESCRI) + ";"
      _cDados += _cTipoEstb + ";"
      If AllTrim(QRYSA2->A2_L_ATIVO) == "N"
         _cDados += "INATIVO;"
      Else
         _cDados += "ATIVO;"
      EndIf

      _cDados += AllTrim(QRYSA2->A2_EMAIL)+";"

      _cDados += CRLF

      _oFWriter:Write(_cDados)

      QRYSA2->(DBSkip())
   EndDo

   //Encerra o arquivo
   _oFWriter:Close()

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032K
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de Envio de dados dos Produtores Rurais de Associação ou Cooperativas via WebService
                     Italac para Sistema Evomilk
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
                    _cOpcao   = "INCASS" = Roda a integração de Inclusão de produtores Associação/Cooperativa no App Cia leite.

Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032K(_cChamada,_cOpcao)

Local _cItens 
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local  _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 1 // 100  // Total de registros para envio.
Local _aProdEnv
Local _aHeadOut := {}
Local _cClasParc
Local _cLinkAss
Local _cLinkSoc
Local _nI
Local _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
Local _nJ

            // Cabeçalho
Local _cCabProdu  As Character
Local _cDadosBCA  As Character
Local _cDadosBCB  As Character
Local _cDadosEmA  As Character
Local _cDadosEmB  As Character
Local _cDadosTlA  As Character
Local _cDadosTlB  As Character
Local _cPropried  As Character
Local _cDadosEdA  As Character
Local _cDadosEdB  As Character
Local _cRodaPe    As Character
Local _cJsonBco   As Character
Local _cJsonEml   As Character
Local _cJsonTel   As Character
Local _cJsonProp  As Character
Local _cJsonEnde  As Character
Local _CJSONENV   As Character
Local _lTemTelef As Logical
Local _lTemEmail As Logical
Local _nX
Local _nAceitos := 0
Local _nRejeitados := 0
Local _cJsonComp As Character 

Private _cIdProdut := ""
Private _cMatLatic := ""   //            matricula_laticinio
Private _cRazaoSoc := ""   //            nome_razao_social
Private _cCpf_Cnpj := ""   //            cpf_cnpj
Private _cInscrEst := ""   //            inscricao_estadual
Private _cRg_IE    := ""   //            rg_ie
Private _cDtNascF  := ""   //            data_nascimento_fundacao
Private _cDtHrEnv  := ""   //            data_hora
Private _cDataSit  := ""   //            data_situacao
Private _cObserv   := ""   //            info_adicional
Private _cComplem  := ""   //            complemento
Private _cEndereco := ""   //            endereco
Private _cNrEnd    := ""   //            numero
Private _cBairro   := ""   //            bairro
Private _cCep      := ""   //            cep
Private _cIdUF     := ""   //            id_uf
Private _cIDCidade := ""   //            id_cidade

Private _cCodBanco := ""   //            Codigo do Banco
Private _cCodAgenc := ""   //            Codigo da Agencia
Private _cNumConta := ""   //            Numero da Conta

Private _cEMail    := ""   //            email
Private _cCelular  := ""   //            celular1
Private _cCelula2  := ""   //            celular2
Private _cTelefon1 := ""   //            telefone1
Private _cTelefon2 := ""   //            telefone2
Private _cWhatsAp1 := ""   //            celular1_whatsapp
Private _cWhatsAp2 := ""   //            celular2_whatsapp
Private _cLEmiteNF := ""   //            laticinio_emite_nf   
Private _cTpPessoa := ""   //            tipo_pessoa          
Private _cTituTanq := ""   //            titular_ponto_coleta 
Private _cNomeFant := ""   //            _nome

            // Detalhe
Private _cNomeProp  := ""  //           nome_propriedade_rural
Private _cNIRF      := ""  //           NIRF
Private _cTipoTanq  := ""  //           id_tipo_tanque
Private _cCapacTnq  := ""  //           capacidade_tanque
Private _cLatitude  := ""  //           latitude_propriedade
Private _cLongitud  := ""  //           longitude_propriedade
Private _cArea      := ""  //           area
Private _cRecria    := ""  //           recria
Private _cVacaSeca  := ""  //           vaca_seca
Private _cVacaLacta := ""  //           vaca_lactacao
Private _cHoraCole  := ""  //           horario_coleta
Private _cRacaProp  := ""  //           raca_propriedade
Private _cFreqCol   := ""  //           frequencia_coleta
Private _cProdDia   := ""  //           producao_media_diaria
Private _cAreaUti   := ""  //           area_utilizada_producao
Private _cCapacRef  := ""  //           capacidade_refrigeracao
Private _cCodPropr  := ""  //           codigo_propriedade_laticinio
Private _cCodLinha  := ""  //           codigo_linha_laticinio
Private _cDescLin   := ""  //           nome_linha


Private _cSituacao  := ""
Private _cCidade    := ""
Private _cUF        := ""
Private _cCod_Ibge  := ""
Private _cSigSif   := ""
Private _cCodPropL := ""
Private _cCodigotq := ""
Private _cTipoResf := ""
Private _cMarcaTanq:= ""

Private _cCPFCnpjP := ""
Private _cMatParce := ""

// Nova Tags
Private _cTitTanq  := ""    // cpf_cnpj
Private _cMatrLat  := ""    // matricula_laticinio
Private _cTelPrinc := "SIM" // telefone_principal
Private _cEMailPri := "SIM" // email_principal
Private _cSitTnq   := ""    // situacao
Private _CSITPROP  := ""    // Situação Proprietario
Private _CCLASPROP := ""    // Classificação Proprietári do Tanque
Private _CNOMETNQ  := ""    // Nome do Tanque
Private _cNomBanco := ""    // Nome do Banco
Private _cTitConta := ""
Private _cInfoAdic := ""
Private _CDataCad  := ""
Private _cHoraCad  := ""

Private _cComplemD := ""   //            complemento
Private _cEnderecD := ""   //            endereco
Private _cNrEndD   := ""   //            numero
Private _cBairroD  := ""   //            bairro
Private _cCepD     := ""   //            cep
Private _cIdUFD    := ""   //            id_uf
Private _cIDCidadD := ""   //            id_cidade
Private _cEMailD   := ""   //            email 2
Private _cTelefonD := ""   //            Telefone demais propriedades
Private _cProduTit := "true"
Private _cContaPri := "true"
Private _oFWRITER
Private _cVincLat   := ""          // Código do Laticinio Associação/Cooperativa ao qual o Cooperado pertence.
Private _cTipoLat   := "ASSOCIACAO"
Private _aRecnoSA2  := {}
Private _cParceiro  := "" 


Private _cNomRespL := ""
Private _cTelRespL := ""
Private _cEmaRespL := ""

Private _cNomRespP := ""
Private _cTelRespP := ""
Private _cEmaRespP := ""


Default _cChamada := "M"
Default _cOpcao   := "I"

Begin Sequence
   _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
   _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
   _nTotRegEnv := 50 // 1 
 

   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)
      If _cOpcao == "INCASS"
         _cLinkAss := AllTrim(ZFM->ZFM_LINK05)  // Link de envio de inclusão de Associação / Cooperativa
         _cLinkSoc := AllTrim(ZFM->ZFM_LINK02)  // Link de envio de inclusão de Associados / Cooperados
      Else
         _cLinkAss := AllTrim(ZFM->ZFM_LINK05)  // Link de envio de alteração de Associação / Cooperativas
         _cLinkSoc := AllTrim(ZFM->ZFM_LINK02)  // Link de envio de alteração de Associados / Cooperados
      EndIf
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON Associação/Cooperativa e os transforma em String.
   _cAssoc_A := U_MGLT032X(_cDirJSon+"associacao_cooperativa_evomilk_parceiros.json")
   If Empty(_cAssoc_A)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (A) associação/cooperativa integração Italac x Evomilk","Atenção",,1)
      EndIf

      Break
   EndIf

   // Lê os arquivos modelo JSON Associados/Cooperados e os transforma em String.
   _cCabProdu := U_MGLT032X(_cDirJSon+"Cabec_Evomilk_Produtores.json")
   If Empty(_cCabProdu)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho Produtores na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosBCA := ', "dadosbancarios":'

   If Empty(_cDadosBCA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Dados Bancarios_A na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosBCB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Bancarios_B_Produtores.json")
   If Empty(_cDadosBCB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Bancarios_B_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEmA := ' , "emails": '

   If Empty(_cDadosEmA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Emails_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEmB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Emails_B_Produtores.json")
   If Empty(_cDadosEmB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Endereços de Email_B na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosTlA := ', "telefones": '

   If Empty(_cDadosTlA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Telefones_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosTlB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Telefones_B_Produtores.json")
   If Empty(_cDadosTlB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON Numeros de Telefone_B na integração Italac x Evomilk.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cPropried := U_MGLT032X(_cDirJSon+"Det_Evomilk_Propriedades_Produtores.json")
   If Empty(_cPropried)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Propriedades_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEdA := ',    "enderecos": ['
   If Empty(_cDadosEdA)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Enderecos_A_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDadosEdB := U_MGLT032X(_cDirJSon+"Det_Evomilk_Dados_Enderecos_B_Produtores.json")
   If Empty(_cDadosEdB)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Det_Evomilk_Dados_Enderecos_B_Produtores.json","Atenção",,1)
      EndIf

      Break
   EndIf

   _cRodaPe := U_MGLT032X(_cDirJSon+"Rodape_Evomilk_Produtores.json")
   
   If Empty(_cRodaPe)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo "+_cDirJSon+"Rodape_Evomilk_Produtores.json","Atenção",,1)
      EndIf
      Break
   EndIf

   // Obtem o Token de Integração com a Evomilk
   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Produtores Associação/Cooperativa cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf
   // Define o CNPJ da unidade para a tag vinculado_ao_laticinio
   _cVincLat  := _cUnidVinc // Unidade na qual os produtores e coletas estão vinculados // SM0->M0_CGC

   _cHoraIni := Time() // Horario Inicial de Processamento

   _aHeadOut := {}

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

   _nI := 1

   _aProdEnv := {}

   TRBCAB->(DBSetOrder(3)) // {"WK_ORDEMP","A2_COD","A2_LOJA"}
   TRBDET->(DBSetOrder(2)) // TRBDET->(DBSetOrder(1)) // {"A2_COD","A2_LOJA"}
   SA2->(DBSetOrder(1))

   If _cChamada == "M" // Chamada via menu.
      ProcRegua(_nTotRegs)
   EndIf
   _cTot:=AllTrim(Str(_nTotRegs))
   nConta:=0
   TRBCAB->(DBGoTop())
   _nIntervalo := 5 // 15

   _cJSonEnv  := ""   
   _cJSonGrp  := ""
   _aProdutor := {}   
   While ! TRBCAB->(Eof())

      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))
      If _nMinutos > _nIntervalo //  minutos
         _cKeyOld:=AllTrim(_cKey)

         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _nIntervalo == 5 // 10// já adiou uma vez não adia mais
               If _cChamada == "M" // Chamada via menu.
                  U_ITMsg("Erro ao na obtenção do Token.","Atenção","Rotina de Integração de Produtores cancelada.",1)
               EndIf
               Break
            EndIf
            _nIntervalo := 5 // 10
            _cKey:=AllTrim(_cKeyOld)
         EndIf

         _aHeadOut := {}
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

         _cHoraIni := Time()

      EndIf

      _lTemBanco := .F.
      _lTemTelef := .F.
      _lTemEmail := .F.

      // Efetua a leitura dos dados para montagem do JSON.
      _cItens    := ""
      _cIdProdut := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA//      codigo_usuario
      _cMatLatic := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA//      matricula_laticinio
      _cRazaoSoc := TRBCAB->A2_NOME             //            nome_razao_social
      _cCpf_Cnpj := TRBCAB->A2_CGC              //            cpf_cnpj
      _cInscrEst := TRBCAB->A2_INSCR            //            inscricao_estadual
      _cRg_IE    := TRBCAB->A2_PFISICA          //            rg_ie
      _cDtNascF  := StrZero(Year(TRBCAB->A2_DTNASC),4)+"-"+StrZero(Month(TRBCAB->A2_DTNASC),2)+"-"+StrZero(Day(TRBCAB->A2_DTNASC),2)   //            data_nascimento_fundacao
      _cDtHrEnv  := StrZero(Year(Date()),4)+"-"+StrZero(Month(Date()),2)+"-"+StrZero(Day(Date()),2) + "T" + Time() + "Z"
      _cDataSit  := StrZero(Year(Date()),4)+"-"+StrZero(Month(Date()),2)+"-"+StrZero(Day(Date()),2)
      _cObserv   := ""                          //            info_adicional
      _cComplem  := TRBCAB->A2_ENDCOMP          //            complemento
      _cEndereco := TRBCAB->A2_END              //            endereco
      _cNrEnd    := ""                          //            numero
      _cBairro   := TRBCAB->A2_BAIRRO           //            bairro
      _cCep      := TRBCAB->A2_CEP              //            cep
      _cIdUF     := ""                          //            id_uf
      _cIDCidade := ""                          //            id_cidade
      _cCidade   := AllTrim(TRBCAB->A2_MUN)     //            municipio
      _cUF       := AllTrim(TRBCAB->A2_EST)     //            estado
      _cCod_Ibge := TRBCAB->A2_COD_MUN          //            codigo_ibge"

      _cCodBanco := AllTrim(TRBCAB->A2_BANCO)   //            Codigo do Banco
      _cCodAgenc := AllTrim(TRBCAB->A2_AGENCIA) //            Codigo da Agencia
      _cNumConta := AllTrim(TRBCAB->A2_NUMCON)  //            Numero da Conta
      _cNomBanco := AllTrim(Posicione('SA6',1,xFilial('SA6')+_cCodBanco,'A6_NOME'))
      _cTitConta := TRBCAB->A2_NOME
      _cInfoAdic := ""

      _cEMail    := TRBCAB->A2_EMAIL            //            email
      _cCelular  := ""                          //            celular1
      _cCelula2  := ""                          //            celular2
      _cTelefon1 := TRBCAB->A2_TEL              //            telefone1
      _cNomeFant := TRBCAB->A2_NREDUZ
      _cSituacao := TRBCAB->A2_L_ATIVO

      _cParceiro := TRBCAB->A2_COD+"-0001"//TRBCAB->A2_CGC 

      If ! Empty(_cTelefon1)
         _lTemTelef := .T.
      EndIf

      If ! Empty(_cEMail)
         _lTemEmail := .T.
      EndIf

      _cTelefon2 := ""                          //            telefone2
      _cWhatsAp1 := "SIM"                       //            celular1_whatsapp
      _cWhatsAp1 := "false"                     //            celular2_whatsapp

      // Define o CNPJ da unidade para a tag vinculado_ao_laticinio
      _cVincLat  := _cUnidVinc // Unidade na qual os produtores e coletas estão vinculados // SM0->M0_CGC

      // Integra para a Evomilk o JSon da Associação / Cooperativa
      _cJSonEnv := &(_cAssoc_A) 
      If TRBCAB->A2_L_TPASS == "A" 
         MGLT32ENVA(_cJSonEnv, _cLinkAss ,_aHeadOut , TRBCAB->WK_RECNO,"A",TRBCAB->A2_COD,TRBCAB->A2_LOJA,TRBCAB->A2_NOME)
                  
         TRBCAB->(DBSkip()) // Não foi possível incluir o primeiro registro. A Associação / cooperativa.
         Loop // Portanto, os associados/cooperados também não poderão ser incluidos. Deve-se seguir a sequencia.
      EndIf

      // Este trecho trata os varios e-mails de um campo e envia um a um em campos diferentes.
      _cEMail := AllTrim(StrTran(_cEMail,",",";"))
      _aCabMail  := U_ITTXTARRAY(_cEMail,";",10)

      _cJsonProp := ""  //  _cPropried
      _cJsonBco  := ""  //  _cDadosBCB
      _cJsonTel  := ""  //  _cDadosTlB
      _cJsonEml  := ""  //  _cDadosEmB
      _cJsonEnde := ""  //  _cDadosEdB

      _aRecnoSA2 := {}

      TRBDET->(MsSeek(TRBCAB->A2_COD+TRBCAB->A2_LOJA))   

      While ! TRBDET->(Eof()) .And. TRBCAB->A2_COD+TRBCAB->A2_LOJA == TRBDET->A2_COD+TRBDET->A2_LOJA

         nConta++
         If _cChamada == "M" // Chamada via menu.
            IncProc(_cHoraIni+"-Enviando Produtores: "+StrZero(nConta,5) +" de "+ _cTot)
         EndIf

         If AllTrim(TRBDET->WK_TIPOPRO) == "ASSOCIACAO"
            TRBDET->(DBSkip())
            Loop
         EndIf
         _cCodPropr  := ""                                    //           codigo_propriedade_laticinio
         _cNomeProp  := AllTrim(TRBDET->A2_L_FAZEN)           //           nome_propriedade_rural
         _cNIRF      := TRBDET->A2_L_NIRF                     //           NIRF

         _cCodPropL  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA
         _cMatLatic  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA    // matricula_laticinio


         _cRazaoSoc := TRBDET->A2_L_NATRA                     //            nome_atravessador

         _cTipoTanq  := "INDIVIDUAL"
         _CCLASPROP  := "PRODUTOR INDIVIDUAL"

         _cMatrLat   := ""
         _cTitTanq   := ""
         _cMatParce  := ""
         _cCPFCnpjP  := ""
         _cTituTanq  := "true"

         If TRBDET->A2_L_NFPRO == "S"
            _cLEmiteNF := "true"  
         Else 
            _cLEmiteNF := "false" 
         EndIf 

         If Len(AllTrim(TRBDET->A2_CGC)) < 14
            _cTpPessoa := "1" 
         Else 
            _cTpPessoa := "2" 
         EndIf 
         
         _cNomeFant    := TRBDET->A2_NREDUZ

         If TRBDET->A2_L_CLASS == "C"
            _cTipoTanq  := "COLETIVO"
            _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO"
         ElseIf TRBDET->A2_L_CLASS == "U"
            _CCLASPROP  := "USUARIO DE TANQUE COMUNITARIO"
            _cTipoTanq  := "COLETIVO"
            _cMatrLat   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
            _cTitTanq   := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque

            _cClasParc  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_L_CLASS') // Classificação do Titular do Tanque
            If AllTrim(_cClasParc) == "F"
               _cCPFCnpjP  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque
               _cMatParce  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
            EndIf
            _cTituTanq  := "false"

         ElseIf TRBDET->A2_L_CLASS == "F"
            _cTipoTanq  := "FAMILIAR" //"INDIVIDUAL"
            _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO" // "PRODUTOR INDIVIDUAL"
         EndIf

         If ! Empty(_cCPFCnpjP) .And. AllTrim(_cCPFCnpjP) == AllTrim(_cCpf_Cnpj)
            _cCPFCnpjP := ""
            _cMatParce := ""
         EndIf

         _CNOMETNQ   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ //        Nome do Tanque
         _cCapacTnq  := AllTrim(Str(TRBDET->A2_L_CAPTQ,11))   //           capacidade_tanque
         _cLatitude  := AllTrim(Str(TRBDET->A2_L_LATIT,18,6)) //           latitude_propriedade
         _cLongitud  := AllTrim(Str(TRBDET->A2_L_LONGI,18,6)) //           longitude_propriedade
         _cArea      := ""                                    //           area
         _cRecria    := ""                                    //           recria
         _cVacaSeca  := ""                                    //           vaca_seca
         _cVacaLacta := ""                                    //           vaca_lactacao
         _cHoraCole  := ""                                    //           horario_coleta
         _cRacaProp  := ""                                    //           raca_propriedade

         If TRBDET->A2_L_FREQU == "1"
            _cFreqCol   := "48"                               //           frequencia_coleta
         Else
            _cFreqCol   := "24"
         EndIf

         _cProdDia   := ""                                    //           producao_media_diaria
         _cAreaUti   := ""                                    //           area_utilizada_producao
         _cCapacRef  := ""                                    //           capacidade_refrigeracao
         //Cap. Resfri.	Capacidade Resfriamento	0=Nenhuma	2=Duas Ordenhas	4=Quatro Ordenhas

         If TRBDET->A2_L_CAPAC == "0"
            _cCapacRef  := "Nenhuma"
         ElseIf TRBDET->A2_L_CAPAC == "2"
            _cCapacRef  := "Duas Ordenhas"
         ElseIf TRBDET->A2_L_CAPAC == "4"
            _cCapacRef  := "Quatro Ordenhas"
         EndIf

         If Empty(_cCapacRef)
            _cCapacRef := "nenhuma"
         EndIf

         _cSituacao  := TRBDET->A2_L_ATIVO
         _cSitTnq    := TRBDET->A2_L_ATIVO
         _CSITPROP   := TRBDET->A2_L_ATIVO
         _cSigSif    := TRBDET->A2_L_SIGSI
         _cCodigotq  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
         _cTipoResf  := If(TRBDET->A2_L_RESFR == "E","EXPANSAO","IMERSAO")
         _cMarcaTanq := TRBDET->A2_L_MARTQ
         _cCodLinha  := TRBDET->A2_L_LI_RO   //           codigo_linha_laticinio
         _cDescLin   := TRBDET->ZL3_DESCRI   //           nome_linha

         _cComplemD  := TRBDET->A2_ENDCOMP          //            complemento
         _cEnderecD  := TRBDET->A2_END              //            endereco
         _cNrEndD    := ""                          //            numero
         _cBairroD   := TRBDET->A2_BAIRRO           //            bairro
         _cCepD      := TRBDET->A2_CEP              //            cep
         _cIDCidadD  := ""                          //            id_cidade

         _cCodIbgeD  := TRBDET->A2_COD_MUN          //           codigo_ibge"
         _cEMailD    := TRBDET->A2_EMAIL            //            email
         _cTelefonD  := TRBDET->A2_TEL
         _cCidade    := AllTrim(TRBDET->A2_MUN)     //            municipio
         _cUF        := AllTrim(TRBDET->A2_EST)     //            estado
         _cCod_Ibge  := TRBDET->A2_COD_MUN          //            codigo_ibge"

         If ! Empty(_cTelefonD)
            _lTemTelef := .T.
            _cTelefon1 := _cTelefonD
         EndIf

         If !Empty(_cEMailD)
            _lTemEmail := .T.
            _cEMail := _cEMailD
         EndIf

         If !Empty(_cCodBanco) .And. !Empty(_cCodAgenc) .And. !Empty(_cNumConta)//SE NÃO TEM NÃO ENVIA
            _cJsonBco  += If(!Empty(_cJsonBco),",","")  + &(_cDadosBCB)
            _lTemBanco:=.T.
         EndIf
         If ! Empty(_cEMailD)//SE NÃO TEM NÃO ENVIA
            _cJsonEml  += If(!Empty(_cJsonEml),",","")  + &(_cDadosEmB)
         EndIf
         If ! Empty(_cTelefonD)//SE NÃO TEM NÃO ENVIA
             _cJsonTel  += If(!Empty(_cJsonTel),",","")  + &(_cDadosTlB)
         EndIf
         _cJsonProp += If(!Empty(_cJsonProp),",","") + &(_cPropried)
         _cJsonEnde += If(!Empty(_cJsonEnde),",","") + &(_cDadosEdB)

         // Guarda os fornecedores do JSon para atualização do SA2
         aAdd(_aRecnoSA2, TRBDET->WK_RECNO)
         aAdd(_aProdutor,{TRBDET->A2_COD,;      // 1
                          TRBDET->A2_LOJA,;     // 2
                          TRBCAB->A2_NOME,;     // 3
                          "R" ,;                // 4
                          TRBDET->WK_RECNO,;    // 5
                          "",;                  // 6
                          "COOPERADO",;         // 7
                          ""})                  // 8

         TRBDET->(DBSkip())
      EndDo

      _CDataCad  := DToC(Date())
      _cHoraCad  := Time()

      _cJSonEnv    := &(_cCabProdu) + _cJsonProp +" ] "

      If _lTemBanco // Tem BANCO
         _cJSonEnv += _cDadosBCA + "[" + _cJsonBco + "]"
      Else
         _cJSonEnv += _cDadosBCA + "null"
      EndIf

      If _lTemTelef // Tem TELEFONTE
         _cJSonEnv += _cDadosTlA + "[" + _cJsonTel + "]"
      Else
         _cJSonEnv += _cDadosTlA + "null"
      EndIf

      If _lTemEmail  // Tem E-MAIL
         _cJSonEnv += _cDadosEmA + "[" + _cJsonEml + "]"
      Else
         _cJSonEnv += _cDadosEmA + "null"
      EndIf

      _cJSonEnv += _cDadosEdA + _cJsonEnde + _cRodaPe

      If Len(_aProdutor) > 0  
         _aProdutor[Len(_aProdutor), 6] := _cJSonEnv // Grava o JSon enviado de cada produtor para atualização da tabela de muro.
      EndIf 

      _cJSonGrp += If(!Empty(_cJSonGrp),",","[") + _cJSonEnv 

      If _nI >= _nTotRegEnv

         _cJSonGrp += "]"

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil
         _nTimOut	 	:= 720
         _cRetorno   := ""
         _cRetHttp    := ''

         _aExcecao := {{"\","-"},{char(9),""}}  // Char(9) = Tecla Tab.
         _cJSonGrp := U_ITSUBCHR(_cJSonGrp, _aExcecao)

         // Envio do JSon
         _cRetHttp  := AllTrim( HttpPost( _cLinkSoc , '' , _cJSonGrp                , _nTimOut    , _aHeadOut   , @_cJSonRet ) )
         _cJsonComp := _cJSonGrp
         _cJSonEnv := ""
         _cJSonGrp := ""
         _cResult  := ""
         _cSucesso := ""
         _cErro    := ""
         _aSucesso := {}
         _aErro    := {}

         If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
            _cRetHttp := DecodeUtf8(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            
            _oJson := JsonObject():new()

            _cRet := _oJson:FromJson(_cRetHttp)
         
            _cResult  := _oJson:GetJsonObject("status")
            _oResult  := _oJson:GetJsonObject("result")
            _cSucesso := _oResult:GetJsonObject("success")
            _cErro    := _oResult:GetJsonObject("error")
            
            _aSucesso := StrTokArr2(_cSucesso,",")
         EndIf

         If ValType(_cResult) <> "C"  
            _cResult := ""
         EndIf 

         If Len(_aSucesso) > 0         
            For _nJ := 1 To Len(_aSucesso)  
                _cCodigoLj := AllTrim(_aSucesso[_nJ])
                If Len(_cCodigoLj) == 11
                   _cCod  := SubStr(_cCodigoLj,1,6)
                   _cLoja := SubStr(_cCodigoLj,8,4)
                   _nX := aScan(_aProdutor,{|x| x[1] == _cCod .And. x[2] == _cLoja})
                   If _nX > 0
                      _aProdutor[_nX,4] := "A"
                   EndIf 
                EndIf  
            Next _nJ
         EndIf

         For _nX := 1 To Len(_aProdutor)
             If _aProdutor[_nX,4] == "A"
                // Grava dados dos Produtores Enviados e aceitos.
                ZBH->(RecLock("ZBH",.T.))
                ZBH->ZBH_FILIAL := xFilial("ZBH")            // Filial do Sistema
                ZBH->ZBH_CODPRO := _aProdutor[_nX,1]         // Codigo do Produtor
                ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]         // Loja do Produtor
                ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]         // Nome do Produtor
                ZBH->ZBH_MOTIVO := If(_aProdutor[_nX,7] == "COOPERADO" , AllTrim(_cRetHttp) , _aProdutor[_nX,8])  // Retorno da Intregração
                ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6])         //_cJSonGrp // JSON enviado
                ZBH->ZBH_DTREJ  := Date()                    // Data da Rejeição
                ZBH->ZBH_HRREJ  := Time()                    // Hora da Rejeição
                ZBH->ZBH_DTENV  := Date()                    // Data de Envio
                ZBH->ZBH_HRENV  := Time()                    // Hora de Envio
                ZBH->ZBH_STATUS := "A"                       // Status da Integraç
                ZBH->ZBH_WEBINT := "E"                       // Indica que a integração está sendo realizada com o App Evomilk
			       ZBH->(MSUnLock())
                _nAceitos++

                // Marca produtor como já enviado para o sistema Evomilk.

                // INCLUSÃO E ALTERAÇÃO DE PRODUTORES SUCESSO
                If SA2->(MsSeek(xFilial("SA2") + _aProdutor[_nX,1] + _aProdutor[_nX,2]))
                   SA2->(RecLock("SA2", .F.))
                   If _cOpcao == "INCASS"  // Inclusão de Associação/Cooperativa
                      SA2->A2_L_ENVEV := "N"
                      SA2->A2_L_ITCOL := "S"
                   Else // Alteração
                      SA2->A2_L_ENVAT := "N"
                   EndIf
                   SA2->(MSUnLock())
                EndIf 
             Else
                // Grava dados dos Produtores enviados e rejeitados.
                ZBH->(RecLock("ZBH",.T.))
                ZBH->ZBH_FILIAL := xFilial("ZBH")            // Filial do Sistema
                ZBH->ZBH_CODPRO := _aProdutor[_nX,1]         // Codigo do Produtor
                ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]         // Loja do Produtor
                ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]         // Nome do Produtor
                ZBH->ZBH_MOTIVO := If(_aProdutor[_nX,7] == "COOPERADO" , AllTrim(_cRetHttp) , _aProdutor[_nX,8])  // Retorno da Intregração // AllTrim(_cRetHttp)
                
                If _aProdutor[_nX,7] == "COOPERADO"   
                   ZBH->ZBH_JSONEN := _cJsonComp //AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado
                Else // Associação
                   ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado
                EndIf 

                ZBH->ZBH_DTREJ  := Date()                    // Data da Rejeição
                ZBH->ZBH_HRREJ  := Time()                    // Hora da Rejeição
                ZBH->ZBH_DTENV	 := Date()                  // Data de Envio
                ZBH->ZBH_HRENV	 := Time()                  // Hora de Envio
                ZBH->ZBH_STATUS := "R"                       // Status da Integração
                ZBH->ZBH_WEBINT := "E"                       // Indica que a integração está sendo realizada com o App Evomilk
			       ZBH->(MSUnLock())
                _nRejeitados++
             EndIf
         Next 

         _aProdEnv  := {}
         _cJSonEnv  := ""
         _aProdutor := {}
         _nI := 0

      EndIf

      _nI += 1

      TRBCAB->(DBSkip())

   EndDo
   
   _nAceitos    := 0 
   _nRejeitados := 0

   If ! Empty(_cJSonGrp) // ! Empty(_cJSonEnv)
      _cJSonGrp += "]"

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil
      _nTimOut	 	:= 720
      _cRetorno   := ""

      _cRetHttp    := ''
      _cResult     := ""
      _cSucesso    := ""
      _aSucesso    := {}

      _aExcecao := {{"\","-"},{char(9),""}}  // Char(9) = Tecla Tab.
      _cJSonGrp := U_ITSUBCHR(_cJSonGrp, _aExcecao)
      
      // Envio do JSon
      _cRetHttp  := AllTrim( HttpPost( _cLinkSoc , '' , _cJSonGrp , _nTimOut , _aHeadOut , @_cJSonRet ) )
      _cJsonComp := _cJSonGrp

      If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
         _cRetHttp := DecodeUtf8(_cRetHttp)

         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         _oJson := JsonObject():new()

         _cRet := _oJson:FromJson(_cRetHttp)
         _cResult  := _oJson:GetJsonObject("status")
         _oResult  := _oJson:GetJsonObject("result")
         _cSucesso := _oResult:GetJsonObject("success")
         _cErro    := _oResult:GetJsonObject("error")
         _aSucesso := StrTokArr2(_cSucesso,",")
      EndIf

      If ValType(_cResult) <> "C"  
         _cResult := ""
      EndIf 

      If Len(_aSucesso)            
         For _nJ := 1 To Len(_aSucesso) 
             _cCodigoLj := AllTrim(_aSucesso[_nJ])
             If Len(_cCodigoLj) == 11
                _cCod  := SubStr(_cCodigoLj,1,6)
                _cLoja := SubStr(_cCodigoLj,8,4)
                _nX := aScan(_aProdutor,{|x| x[1] == _cCod .And. x[2] == _cLoja})
                If _nX > 0
                   _aProdutor[_nX,4] := "A"
                EndIf 
             EndIf  
         Next _nJ
      EndIf 

      For _nX := 1 To Len(_aProdutor)
          If _aProdutor[_nX,4] == "A"
             // Grava Dados dos Produtores Enviados e aceitos para histórico
             ZBH->(RecLock("ZBH",.T.))
             ZBH->ZBH_FILIAL := xFilial("ZBH")             // Filial do Sistema
             ZBH->ZBH_CODPRO := _aProdutor[_nX,1]          // Codigo do Produtor
             ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]          // Loja do Produtor
             ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]          // Nome do Produtor
             ZBH->ZBH_MOTIVO := If(_aProdutor[_nX,7] == "COOPERADO" , AllTrim(_cRetHttp) , _aProdutor[_nX,8])  // Retorno da Intregração  // AllTrim(_cRetHttp)         // Motivo da Rejeição
             ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6]) //_cJSonGrp // JSON enviado
             ZBH->ZBH_DTENV  := Date()                     // Data de Envio
             ZBH->ZBH_HRENV  := Time()                     // Hora de Envio
             ZBH->ZBH_STATUS := "A"                        // Status da Integração
             ZBH->ZBH_WEBINT := "E"                        // Indica que a integração está sendo realizada com o App Evomilk		ZBH->(MSUnLock())
             ZBH->(MSUnLock())
             _nAceitos++

             // Marca produtor como já enviado para o sistema Evomilk.
             If SA2->(MsSeek(xFilial("SA2") + _aProdutor[_nX,1] + _aProdutor[_nX,2]))
                SA2->(RecLock("SA2", .F.))
                If _cOpcao == "INCASS"  // Inclusão de Associação/Cooperativa
                   SA2->A2_L_ENVEV := "N"
                   SA2->A2_L_ITCOL := "S"
                Else // Alteração
                   SA2->A2_L_ENVAT := "N"
                EndIf
                SA2->(MSUnLock())
             EndIf 
          Else
             // Grava dados de envio rejeitados para histórico.
             ZBH->(RecLock("ZBH",.T.))
             ZBH->ZBH_FILIAL := xFilial("ZBH")              // Filial do Sistema
             ZBH->ZBH_CODPRO := _aProdutor[_nX,1]           // Codigo do Produtor
             ZBH->ZBH_LOJPRO := _aProdutor[_nX,2]           // Loja do Produtor
             ZBH->ZBH_NOMPRO := _aProdutor[_nX,3]           // Nome do Produtor
             ZBH->ZBH_MOTIVO := If(_aProdutor[_nX,7] == "COOPERADO" , AllTrim(_cRetHttp) , _aProdutor[_nX,8])  // Retorno da Intregração //AllTrim(_cRetHttp) 

             If _aProdutor[_nX,7] == "COOPERADO"
                ZBH->ZBH_JSONEN := _cJsonComp // AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado
             Else 
                ZBH->ZBH_JSONEN := AllTrim(_aProdutor[_nX,6])  //_cJSonGrp // JSON enviado   
             EndIf 

             ZBH->ZBH_DTREJ  := Date()                      // Data da Rejeição
             ZBH->ZBH_HRREJ  := Time()                      // Hora da Rejeição
             ZBH->ZBH_DTENV  := Date()                      // Data de Envio
             ZBH->ZBH_HRENV  := Time()                      // Hora de Envio
             ZBH->ZBH_STATUS := "R"                         // Status da Integração
             ZBH->ZBH_WEBINT := "E"                         // Indica que a integração está sendo realizada com o App Evomilk
		       ZBH->(MSUnLock())
             _nRejeitados++
          EndIf
      Next _nX
   EndIf 

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT32ENVA
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/10/2024
Descrição----------: Rotina de Integração dos de Associação / Cooperativas Italac para Sistema Evomilk
Parametros--------: _cJSonEnv = JSon de Envio.
                    _cLinkEnv = Link de envio dos dados.
                    _aHeadEnv = Header de envio dos dados.
                    _aRegSA2  = Recnos do casdastro de Produtores para marcar como já enviados.
                    _cTipoAss = A = Associação/Cooperativa
                                C = Associado/cooperado
                    _cCodProd = Código da associação/cooperativa
                    _cLojaProd = Loja da associação/cooperativa
                    _cNomeProd = Nome da Associação/Cooperativa
Retorno------------: _lRet = .T. = Enviados com sucesso.
                           = .F. = Falha no envio.
===============================================================================================================================
*/
Static Function MGLT32ENVA(_cJSonEnv, _cLinkEnv ,_aHeadEnv , _nRegSA2,_cTipoAss,_cCodProd,_cLojaProd,_cNomeProd)

Local _lRet := .T.
Local _cJSonAux := "", _aExcecao := {}

Begin Sequence

   If ! Empty(_cJSonEnv)
      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil
      _nTimOut	 	:= 720
      _cRetorno   := ""

      _cRetHttp    := ''
      _oRetJSon    := ''

      // Remoção de caracteres especiais do JSon antes do envio
      _cJSonAux := StrTran(_cJSonEnv,"\/","/-/")
      _aExcecao := {{"\","-"},{char(9)," "}}  // Char(9) = Tecla Tab.
      _cJSonAux := U_ITSUBCHR(_cJSonAux, _aExcecao)
      _cJSonAux := StrTran(_cJSonAux,"/-/","\/")
      _cJSonEnv := _cJSonAux

      // Envio do JSon
      _cRetHttp := AllTrim( HttpPost( _cLinkEnv , '' , _cJSonEnv , _nTimOut , _aHeadEnv , @_cJSonRet ) )

      If ! Empty(_cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
      EndIf

      _cAuxHTTP := Upper(_cRetHttp)

      _lResult := .F.

      If ! Empty(_cRetHttp) .And. "STATUS" $ Upper(_cAuxHTTP) .And. _oRetJSon:status == "success" // ! Empty(_oRetJSon) .And. "STATUS" $ Upper(_cAuxHTTP) 
         _lResult := .T.
      EndIf

      // Marca produtor como já enviado para o sistema Evomilk.
      If _lResult // Integração realizada com sucesso
         aAdd(_aRecnoSA2, {_nRegSA2,_cTipoAss})
         aAdd(_aProdutor,{ _cCodProd,;           // 1 // Codigo da Associação/Cooperativa
                          _cLojaProd,;           // 2 // Loja da Associação/Cooperativa
                          _cNomeProd,;           // 3 // Nome da Associação/Cooperativa
                          "A" ,;                 // 4
                          0   ,;                 // 5
                          _cJSonEnv,;            // 6
                          "ASSOCIACAO",;         // 7
                          AllTrim(_cRetHttp)})   // 8
      Else
         _lRet := .F.
         aAdd(_aProdutor,{ _cCodProd,;           // 1 // Codigo da Associação/Cooperativa
                          _cLojaProd,;           // 2 // Loja da Associação/Cooperativa
                          _cNomeProd,;           // 3 // Nome da Associação/Cooperativa
                          "R" ,;                 // 4
                          0   ,;                 // 5
                          _cJSonEnv,;            // 6
                          "ASSOCIACAO",;         // 7
                          AllTrim(_cRetHttp)})   // 8

      EndIf

   EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Função-------------: MGLT32UP
Autor--------------: Julio de Paula Paz
Data da Criacao----: 30/04/2025
Descrição----------: Rotina de Envio de dados das Alterações Produtores Rurais de Associação ou Cooperativas via WebService. 
                     Italac para Sistema Companhia do Leite.
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
                    _cOpcao   = "INCASS" = Roda a integração de Inclusão de produtores Associação/Cooperativa no App Cia leite.

Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32UP(_cChamada,_cOpcao)

Local _cRodaPe // _cCabec, _cDetalhe, _cAssociac 
Local _cItens //, _cEnvio 
Local _cEmpWebService // "000004"
Local _cJSonProd, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _aProdEnv
Local _aHeadOut := {} 
Local _cClasParc 
Local _cLinkAss
Local _cLinkSoc
Local _nI 
Local _aCabMail, _cCabMail, _cCabJson, _nY
Local _aDetMail, _cDetMail, _cDetJson
Local _nIntervalo

            // Cabeçalho
Private _cIdProdut := ""            
Private _cMatLatic := ""   //            matricula_laticinio      
Private _cRazaoSoc := ""   //            nome_razao_social        
Private _cCpf_Cnpj := ""   //            cpf_cnpj                  
Private _cInscrEst := ""   //            inscricao_estadual        
Private _cRg_IE    := ""   //            rg_ie                    
Private _cDtNascF  := ""   //            data_nascimento_fundacao 
Private _cObserv   := ""   //            info_adicional           
Private _cComplem  := ""   //            complemento              
Private _cEndereco := ""   //            endereco                  
Private _cNrEnd    := ""   //            numero                   
Private _cBairro   := ""   //            bairro                    
Private _cCep      := ""   //            cep                       
Private _cIdUF     := ""   //            id_uf                    
Private _cIDCidade := ""   //            id_cidade                
Private _cCodBanco := ""   //            Codigo do Banco
Private _cCodAgenc := ""   //            Codigo da Agencia
Private _cNumConta := ""   //            Numero da Conta
Private _cEMail    := ""   //            email                     
Private _cCelular  := ""   //            celular1                  
Private _cCelula2  := ""   //            celular2                  
Private _cTelefon1 := ""   //            telefone1                 
Private _cTelefon2 := ""   //            telefone2                 
Private _cWhatsAp1 := ""   //            celular1_whatsapp         
Private _cWhatsAp2 := ""   //            celular2_whatsapp         
            
            // Detalhe 
Private _cNomeProp  := ""  //           nome_propriedade_rural    
Private _cNIRF      := ""  //           NIRF                      
Private _cTipoTanq  := ""  //           id_tipo_tanque            
Private _cCapacTnq  := ""  //           capacidade_tanque         
Private _cLatitude  := ""  //           latitude_propriedade      
Private _cLongitud  := ""  //           longitude_propriedade     
Private _cArea      := ""  //           area                      
Private _cRecria    := ""  //           recria                    
Private _cVacaSeca  := ""  //           vaca_seca                 
Private _cVacaLacta := ""  //           vaca_lactacao             
Private _cHoraCole  := ""  //           horario_coleta            
Private _cRacaProp  := ""  //           raca_propriedade         
Private _cFreqCol   := ""  //           frequencia_coleta         
Private _cProdDia   := ""  //           producao_media_diaria    
Private _cAreaUti   := ""  //           area_utilizada_producao   
Private _cCapacRef  := ""  //           capacidade_refrigeracao  
Private _cCodPropr  := ""  //           codigo_propriedade_laticinio  
Private _cCodLinha  := ""  //           codigo_linha_laticinio
Private _cDescLin   := ""  //           nome_linha

Private _cSituacao  := ""
Private _cCid_UF    := ""
Private _cCod_Ibge  := ""
Private _cSigSif   := ""
Private _cCodPropL := ""
Private _cCodigotq := "" 
Private _cTipoResf := ""
Private _cMarcaTanq:= ""
Private _cCPFCnpjP := ""
Private _cMatParce := ""

// Nova Tags
Private _cTitTanq  := ""    // cpf_cnpj
Private _cMatrLat  := ""    // matricula_laticinio
Private _cTelPrinc := "SIM" // telefone_principal
Private _cEMailPri := "SIM" // email_principal
Private _cSitTnq   := ""    // situacao
Private _CSITPROP  := ""    // Situação Proprietario
Private _CCLASPROP := ""    // Classificação Proprietári do Tanque
Private _CNOMETNQ  := ""    // Nome do Tanque
Private _cNomBanco := ""    // Nome do Banco
Private _cTitConta := ""
Private _cInfoAdic := ""
Private _CDataCad  := ""
Private _cHoraCad  := ""

Private _cComplemD := ""   //            complemento              
Private _cEnderecD := ""   //            endereco                  
Private _cNrEndD   := ""   //            numero                   
Private _cBairroD  := ""   //            bairro                    
Private _cCepD     := ""   //            cep                       
Private _cIdUFD    := ""   //            id_uf                    
Private _cIDCidadD := ""   //            id_cidade            
Private _cEMailD   := ""   //            email 2 
Private _cTelefonD := ""   //            Telefone demais propriedades   

Private _oFWRITER  
Private _cVincLat           // Código do Laticinio Associação/Cooperativa ao qual o Cooperado pertence.
Private _cTipoLat   := "ASSOCIACAO"
Private _aRecnoSA2  := {}
Private _cParceiro  := "" 

Private _cNomRespL := ""
Private _cTelRespL := ""
Private _cEmaRespL := ""

Private _cNomRespP := ""
Private _cTelRespP := ""
Private _cEmaRespP := ""

Private _cCodEvoMilk :="EVOMKT"

Default _cChamada := "M"
Default _cOpcao   := "I"

Begin Sequence 
   // Obtem os dados do servidor Webservice.
   _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML) 
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)
      If _cOpcao == "INCASS" 
         _cLinkAss := AllTrim(ZFM->ZFM_LINK05)  // Link de envio de inclusão de Associação / Cooperativa
         _cLinkSoc := AllTrim(ZFM->ZFM_LINK06)  // Link de envio de inclusão de Associados / Cooperados
      Else
         _cLinkAss := AllTrim(ZFM->ZFM_LINK05)  // Link de envio de alteração de Associação / Cooperativas
         _cLinkSoc := AllTrim(ZFM->ZFM_LINK06)  // Link de envio de alteração de Associados / Cooperados
      EndIf 
   Else 
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf 

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      EndIf 

      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON Associação/Cooperativa e os transforma em String.
   _cAssoc_A := U_MGLT032X(_cDirJSon+"ASSOCIACAO_COOPERATIVA_CIA_LEITE_PRODUTOR_A.txt")  
   If Empty(_cAssoc_A)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (A) associação/cooperativa integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   _cAssoc_B:= U_MGLT032X(_cDirJSon+"ASSOCIACAO_COOPERATIVA_CIA_LEITE_PRODUTOR_B.txt")  
   If Empty(_cAssoc_B)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (B) associação/cooperativa integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   _cAssoc_C := U_MGLT032X(_cDirJSon+"ASSOCIACAO_COOPERATIVA_CIA_LEITE_PRODUTOR_C.txt")  
   If Empty(_cAssoc_C)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (C) associação/cooperativa integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf


   //================================================================================
   // Lê os arquivos modelo JSON Associado/Cooperado e os transforma em String.
   //================================================================================
   _cCabec_A := U_MGLT032X(_cDirJSon+"Cabec_CIA_LEITE_PRODUTOR_ASSOCIADO_A.txt") 
   If Empty(_cCabec_A)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (A) associado/cooperado integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   _cCabec_B := U_MGLT032X(_cDirJSon+"Cabec_CIA_LEITE_PRODUTOR_ASSOCIADO_B.txt") 
   If Empty(_cCabec_B)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (B) associado/cooperado integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   _cCabec_C := U_MGLT032X(_cDirJSon+"Cabec_CIA_LEITE_PRODUTOR_ASSOCIADO_C.txt") 
   If Empty(_cCabec_C)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho (C) associado/cooperado integração Italac x Companhia do Leite.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   _cDetalheA := U_MGLT032X(_cDirJSon+"Detalhe_CIA_LEITE_PRODUTOR_ASSOCIADO_A.txt") 

   If Empty(_cDetalheA)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe (A) Propriedades produtor rural associado/cooperado.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDetalheB := U_MGLT032X(_cDirJSon+"Detalhe_CIA_LEITE_PRODUTOR_ASSOCIADO_B.txt") 

   If Empty(_cDetalheB)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe (B) Propriedades produtor rural associado/cooperado.","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDetalheC := U_MGLT032X(_cDirJSon+"Detalhe_CIA_LEITE_PRODUTOR_ASSOCIADO_C.txt") 

   If Empty(_cDetalheC)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe (C) Propriedades produtor rural associado/cooperado.","Atenção",,1)
      EndIf

      Break
   EndIf

   //======================================================================================== 
   _cRodape := U_MGLT032X(_cDirJSon+"Rodape_CIA_LEITE_PRODUTOR_ASSOCIADO.txt") 
   If Empty(_cRodape)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON Rodape Produtor Rural associado/cooperado Integração Italac x Companhia do Leite.","Atenção",,1)
      EndIf 

      Break
   EndIf
    
   // Obtem o Token de Integração com a Cia do Leite
   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Produtores Associação/Cooperativa cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf 
   
   _cHoraIni := Time() // Horario Inicial de Processamento
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

   //_cLinkWS := 'https://app-cdl-int-hml.azurewebsites.net/Public/v1/produtores/'

   _cJSonProd := "["
   _cJSonGrp := ""
   _nI := 1
   _nIntervalo := 5 

   _aProdEnv := {}

   TRBCAB->(DBSetOrder(3)) // {"WK_ORDEMP","A2_COD","A2_LOJA"} 
   TRBDET->(DBSetOrder(1))
   SA2->(DBSetOrder(1))

   TRBDET->(DBGoTop())
   While ! TRBDET->(Eof())

      TRBCAB->(DBGoTo(TRBDET->WK_REGCAB))
      
      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))      
      If _nMinutos > _nIntervalo // 5 // 28 //  minutos 
         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _cChamada == "M" // Chamada via menu.   
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Produtores Associação/Cooperativa cancelada.","Atenção",,1)
            EndIf
   
            Break
         EndIf 
         
         _aHeadOut := {}              
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

         _cHoraIni := Time()

      EndIf 

      // Efetua a leitura dos dados para montagem do JSON.
      _cItens := ""
      _cIdProdut := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA 
      _cMatLatic := TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA          //            matricula_laticinio  
      _cRazaoSoc := TRBCAB->A2_NOME                             //            nome_razao_social        
      _cCpf_Cnpj := TRBCAB->A2_CGC                              //            cpf_cnpj                  
      _cInscrEst := TRBCAB->A2_INSCR                            //            inscricao_estadual        
      _cRg_IE    := TRBCAB->A2_PFISICA                          //            rg_ie                    
      _cDtNascF  := StrZero(Year(TRBCAB->A2_DTNASC),4)+"-"+StrZero(Month(TRBCAB->A2_DTNASC),2)+"-"+StrZero(Day(TRBCAB->A2_DTNASC),2)   //            data_nascimento_fundacao 
      _cObserv   := ""                                          //            info_adicional           
      _cComplem  := TRBCAB->A2_ENDCOMP                          //            complemento              
      _cEndereco := TRBCAB->A2_END                              //            endereco                  
      _cNrEnd    := ""                                          //            numero                   
      _cBairro   := TRBCAB->A2_BAIRRO                           //            bairro                    
      _cCep      := TRBCAB->A2_CEP                              //            cep                       
      _cIdUF     := ""                                          //            id_uf                    
      _cIDCidade := ""                                          //            id_cidade                
      _cCid_UF   := AllTrim(TRBCAB->A2_MUN) + "\/" + AllTrim(TRBCAB->A2_EST)             // municipio  // estado        
      _cCod_Ibge := TRBCAB->A2_COD_MUN                          //           codigo_ibge"
      _cCodBanco := AllTrim(TRBCAB->A2_BANCO)                   //            Codigo do Banco
      _cCodAgenc := AllTrim(TRBCAB->A2_AGENCIA)                 //            Codigo da Agencia
      _cNumConta := AllTrim(TRBCAB->A2_NUMCON)                  //            Numero da Conta      
      _cNomBanco := AllTrim(Posicione('SA6',1,xFilial('SA6')+_cCodBanco,'A6_NOME'))
      _cTitConta := ""
      _cInfoAdic := ""
      _cEMail    := TRBCAB->A2_EMAIL            //            email                     
      _cCelular  := ""                          //            celular1                  
      _cCelula2  := ""                          //            celular2                  
      _cTelefon1 := TRBCAB->A2_TEL              //            telefone1                 
      _cTelefon2 := ""                          //            telefone2                 
      _cWhatsAp1 := "NAO"                     //            celular2_whatsapp         

      // Define o CNPJ da unidade para a tag vinculado_ao_laticinio
      _cVincLat  := _cUnidVinc // Unidade na qual os produtores e coletas estão vinculados // SM0->M0_CGC

      _cNomRespL := TRBCAB->A2_NOME
      _cTelRespL := TRBCAB->A2_TEL
      _cEmaRespL := TRBCAB->A2_EMAIL
      _cTipoLat  := "ASSOCIACAO"
      _cSituacao := TRBCAB->A2_L_ATIVO
      _aRecnoSA2  := {}  // Array com os dados para atualização do cadastro de produtores como já enviados.

      // Este trecho trata os varios e-mails de um campo e envia um a um em campos diferentes. 
      _cEMail := AllTrim(StrTran(_cEMail,",",";"))
      _aCabMail  := U_ITTXTARRAY(_cEMail,";",10) 
      
      _cCabMail := ""
      _cCabJson := ""
      _cEMailPri := "SIM"

      If Len(_aCabMail) > 0 
         For _nY := 1 To Len(_aCabMail)
             _cEMail   := StrTran(_aCabMail[_nY],";","") 
             _cCabJson := &(_cAssoc_B)
             _cCabMail += If(!Empty(_cCabMail),",","") + _cCabJson
             _cEMailPri := "NAO"
         Next 
      Else 
         _cCabJson := &(_cAssoc_B)
         _cCabMail += If(!Empty(_cCabMail),",","") + _cCabJson
      EndIf     
      
      If TRBCAB->A2_L_TPASS == "A" // Associação
         // Integra para a Cia do Leite o JSon da Associação / Cooperativa
         _cJSonEnv := &(_cAssoc_A) + _cCabMail + &(_cAssoc_C)

         MGLT29ENVA(_cJSonEnv, _cLinkAss ,_aHeadOut , TRBCAB->WK_RECNO,"A")
         
         TRBDET->(DBSkip()) // Não foi possível incluir o primeiro registro. A Associação / cooperativa.
         Loop // Portanto, os associados/cooperados também não poderão ser incluidos. Deve-se seguir a sequencia.
      EndIf 

      // Integra para a Cia do Leite os JSon dos Associcados / Cooperados
      _cVincLat  := TRBCAB->A2_CGC     // Código da Associação/Cooperativa ao qual o cooperado pertence.
      _cTipoLat   := "ASSOCIACAO"

      If TRBDET->A2_L_TPASS == "A" // Associação
         TRBDET->(DBSkip())
         Loop 
      EndIf 

      _cCodPropr  := ""                                    //           codigo_propriedade_laticinio
      _cNomeProp  := TRBDET->A2_L_FAZEN                    //           nome_propriedade_rural    
      _cNIRF      := TRBDET->A2_L_NIRF                     //           NIRF  

      _cCodPropL  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA
      _cMatLatic  := TRBDET->A2_COD+"-"+TRBDET->A2_LOJA    // TRBCAB->A2_COD+"-"+TRBCAB->A2_LOJA//            matricula_laticinio  

      _cTipoTanq  := "INDIVIDUAL" 
      _CCLASPROP  := "PRODUTOR INDIVIDUAL"

      _cMatrLat   := ""
      _cTitTanq   := ""
      _cMatParce  := ""
      _cCPFCnpjP  := ""
      _cCid_UF    := AllTrim(TRBDET->A2_MUN) + "\/" + AllTrim(TRBDET->A2_EST)             // municipio  // estado        

      If TRBDET->A2_L_CLASS == "C"
         _cTipoTanq  := "COLETIVO"
         _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO"
      ElseIf TRBDET->A2_L_CLASS == "U"
         _CCLASPROP  := "USUARIO DE TANQUE COMUNITARIO"
         _cTipoTanq  := "COLETIVO"
         _cMatrLat   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
         _cTitTanq   := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque
         _cClasParc  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_L_CLASS') // Classificação do Titular do Tanque
         If AllTrim(_cClasParc) == "F"
            _cCPFCnpjP  := Posicione('SA2',1,xFilial('SA2')+TRBDET->A2_L_TANQ+TRBDET->A2_L_TANLJ,'A2_CGC') // CPF_CNPJ do Titular do Tanque
            _cMatParce  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
         EndIf 
      ElseIf TRBDET->A2_L_CLASS == "F"
         _cTipoTanq  := "FAMILIAR" //"INDIVIDUAL"
         _CCLASPROP  := "TITULAR DE TANQUE COMUNITARIO" // "PRODUTOR INDIVIDUAL"
      EndIf

      If ! Empty(_cCPFCnpjP) .And. AllTrim(_cCPFCnpjP) == AllTrim(_cCpf_Cnpj)
         _cCPFCnpjP := ""
         _cMatParce := ""
      EndIf 

      _CNOMETNQ   := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ //        Nome do Tanque
      _cCapacTnq  := AllTrim(Str(TRBDET->A2_L_CAPTQ,11))   //           capacidade_tanque         
      _cLatitude  := AllTrim(Str(TRBDET->A2_L_LATIT,18,6)) //           latitude_propriedade      
      _cLongitud  := AllTrim(Str(TRBDET->A2_L_LONGI,18,6)) //           longitude_propriedade     
      _cArea      := ""                                    //           area                      
      _cRecria    := ""                                    //           recria                    
      _cVacaSeca  := ""                                    //           vaca_seca                 
      _cVacaLacta := ""                                    //           vaca_lactacao             
      _cHoraCole  := ""                                    //           horario_coleta            
      _cRacaProp  := ""                                    //           raca_propriedade         
         
      If TRBDET->A2_L_FREQU == "1"
         _cFreqCol   := "48"                               //           frequencia_coleta         
      Else 
         _cFreqCol   := "24"
      EndIf    

      _cProdDia   := ""                                    //           producao_media_diaria    
      _cAreaUti   := ""                                    //           area_utilizada_producao   
      _cCapacRef  := ""                                    //           capacidade_refrigeracao  

      If TRBDET->A2_L_CAPAC == "0"
         _cCapacRef  := "Nenhuma" 
      ElseIf TRBDET->A2_L_CAPAC == "2"
         _cCapacRef  := "Duas Ordenhas"
      ElseIf TRBDET->A2_L_CAPAC == "4"
         _cCapacRef  := "Quatro Ordenhas"
      EndIf 

      If Empty(_cCapacRef)
         _cCapacRef := "nenhuma"
      EndIf 

      _cSituacao  := TRBDET->A2_L_ATIVO 
      _cSitTnq    := TRBDET->A2_L_ATIVO
      _CSITPROP   := TRBDET->A2_L_ATIVO
      _cSigSif    := TRBDET->A2_L_SIGSI         
      _cCodigotq  := TRBDET->A2_L_TANQ+"-"+TRBDET->A2_L_TANLJ
      _cTipoResf  := If(TRBDET->A2_L_RESFR == "E","EXPANSAO","IMERSAO")
      _cMarcaTanq := TRBDET->A2_L_MARTQ
      _cCodLinha  := TRBDET->A2_L_LI_RO   //           codigo_linha_laticinio
      _cDescLin   := TRBDET->ZL3_DESCRI   //           nome_linha

      _cComplemD  := TRBDET->A2_ENDCOMP          //            complemento              
      _cEnderecD  := TRBDET->A2_END              //            endereco                  
      _cNrEndD    := ""                          //            numero                   
      _cBairroD   := TRBDET->A2_BAIRRO           //            bairro                    
      _cCepD      := TRBDET->A2_CEP              //            cep                       
      _cIDCidadD  := ""                          //            id_cidade                
      _cCidUFD    := AllTrim(TRBDET->A2_MUN) + "\/" + AllTrim(TRBDET->A2_EST)             // municipio  // estado        
      _cCodIbgeD  := TRBDET->A2_COD_MUN          //           codigo_ibge"
      _cEMailD    := TRBDET->A2_EMAIL            //            email                     
      _cTelefonD  := TRBDET->A2_TEL

      //----------------------------------
      _cRazaoSoc := TRBDET->A2_L_NATRA
      _cCpf_Cnpj := ""
      _cInscrEst := ""
      _cRg_IE    := ""
      _cDtNascF  := ""
      _cObserv   := ""
      _cComplem  := ""
      _cEndereco := ""
      _cNrEnd    := ""
      _cBairro   := ""
      _cCep      := ""
      _cComplemD := ""
      _cEnderecD := ""
      _cNrEndD   := ""
      _cBairroD  := ""
      _cCepD     := ""

      // Este trecho trata os varios e-mails de um campo e envia um a um em campos diferentes. 
      _cEMailD    := AllTrim(StrTran(_cEMailD,",",";"))
      _aDetMail   := U_ITTXTARRAY(_cEMailD,";",10) 
      
      _cDetMail := ""
      _cDetJson := ""

      If Len(_aDetMail) > 0 
         For _nY := 1 To Len(_aDetMail)
             _cEMailD  := StrTran(_aDetMail[_nY],";","") 
             _cDetJson := &(_cDetalheB)
             _cDetMail += If(!Empty(_cDetMail),",","") + _cDetJson
         Next 
      Else 
         _cDetJson := &(_cDetalheB)
         _cDetMail += If(!Empty(_cDetMail),",","") + _cDetJson
      EndIf     
      
      _cItens += If(!Empty(_cItens),",","") + &(_cDetalheA) + _cDetMail + &(_cDetalheC)

      _CDataCad  := DToC(Date())  
      _cHoraCad  := Time()
         
      //_cJSonEnv := &(_cCabec) + _cItens + _cRodape
      _cJSonEnv := &(_cCabec_A) + _cCabMail + &(_cCabec_C) + _cItens + _cRodape
         
      MGLT29ENVA(_cJSonEnv, _cLinkSoc ,_aHeadOut , TRBDET->WK_RECNO, "C")

      _cItens := ""

      TRBDET->(DBSkip())

   EndDo 

   // Atualiza cadastro de produtores como já enviados para Cia do Leite.
   If Len(_aRecnoSA2) > 0 // 1 // Significa que foi integrado com sucesso uma Associação / Cooperativa com sucesso.
         
      For _nI := 1 To Len(_aRecnoSA2)
          SA2->(DBGoTo(_aRecnoSA2[_nI,1]))
      
          SA2->(RecLock("SA2", .F.))
          SA2->A2_L_ENVEV := "N" 
          If Empty(SA2->A2_L_ITCOL)
             SA2->A2_L_ITCOL := "S"
          EndIf
          SA2->A2_L_ENVAT := "N"
          SA2->A2_L_TPASS := _aRecnoSA2[_nI,2]
          SA2->(MSUnLock())
      Next 

   EndIf 

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGLT032C
Autor--------------: Julio de Paula Paz
Data da Criacao----: 05/05/2025
Descrição----------: Rotina de leitura de dados para envio de solicitação de exclusão dos Volumes de Leite Coletados,
                     no App Evomilk.
Parametros---------: _lSchedule = .T. = Rotina chamada via scheduller
                                    .F. = Rotina chamada via menu.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032C(_lSchedule)

Local _aStruct := {}
Local _oTemp3
Local _oTemp5

Default _lSchedule := .F.

Begin Sequence

   If ! _lSchedule
      IncProc("Gerando dados das Coletas de Leita para envio...")
   EndIf

   // Cria Tabela Temporária para atualização da ZBY
   _aStruct := {}
   aAdd(_aStruct,{"ZBY_VIAGEM","C",10 ,0})  
   aAdd(_aStruct,{"ZBY_NUMERO","C",10 ,0})  
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  

   If Select("TRBZBY") > 0
      TRBZBY->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp5 := FWTemporaryTable():New( "TRBZBY",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp5:AddIndex( "01", {"ZBY_VIAGEM","ZBY_NUMERO"} )
   _oTemp5:Create()

   DBSelectArea("TRBZBY")

   // Cria Tabela Temporária para armazenar dados do JSon
   _aStruct := {}
   aAdd(_aStruct,{"ZBY_VIAGEM","C",10 ,0})  
   aAdd(_aStruct,{"ZBY_NUMERO","C",10 ,0})  
   aAdd(_aStruct,{"ZBY_CODPAT","C",6  ,0})  
   aAdd(_aStruct,{"ZBY_LOJPAT","C",4  ,0})  
   aAdd(_aStruct,{"ZBY_VOLUME","N",14 ,0})  // volume_litros
   aAdd(_aStruct,{"ZBY_DTIVIA","D",8  ,0})  // data_coleta
   aAdd(_aStruct,{"ZBY_HRINI" ,"C",8  ,0})  // hora_coleta
   aAdd(_aStruct,{"WK_OBSERV" ,"C",100,0})  // observações
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno da Tabela ZBY
   aAdd(_aStruct,{"WK_EXCLUID","C",5  ,0})  // Indica se é inclusão ou exclusão de coletas

   If Select("TRBCOL") > 0
      TRBCOL->(DBCloseArea())
   EndIf

   // Abre o arquivo TRBCAB criado dentro do banco de dados protheus.
   _oTemp3 := FWTemporaryTable():New( "TRBCOL",  _aStruct )

   // Cria os indices para o arquivo.
   _oTemp3:AddIndex( "01", {"ZBY_CODPAT","ZBY_LOJPAT"})

   _oTemp3:Create()

   DBSelectArea("TRBCOL")

   _nTotRegs := 0

   // Monta select de leitura de dados do cadastro de coletas de leite.
   _cQry := " SELECT "
   _cQry += " ZBY_VIAGEM, "              
   _cQry += " ZBY_NUMERO, "              
   _cQry += " ZBY_CODPAT, "              
   _cQry += " ZBY_LOJPAT, "              
   _cQry += " ZBY_VOLUME, "              // volume_litros
   _cQry += " ZBY_DTIVIA, "              // data_coleta
   _cQry += " ZBY_HRINI , "              // HORARIO INICIAL COLETA // ZBY_HRFIM = HORARIO FINAL COLETA
   _cQry += " ZBY.R_E_C_N_O_ AS NRREG "
   _cQry += " FROM " + RetSqlName("ZBY") + " ZBY " 
   _cQry += " WHERE ZBY.D_E_L_E_T_ = ' ' "
   
   If ZBY->(FIELDPOS("ZBY_ENVEVO")) > 0
      _cQry += " AND (ZBY.ZBY_ENVEVO = ' ' OR ZBY.ZBY_ENVEVO = 'S') "
   EndIf
   
   _cQry += " ORDER BY ZBY_CODPAT,ZBY_LOJPAT "

   If Select("QRYZBY") > 0
      QRYZBY->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYZBY")

   DBSelectArea("QRYZBY")

   Count To _nTotRegs

   QRYZBY->(DBGoTop())

   If ! _lSchedule
      ProcRegua(_nTotRegs)
   EndIf
   
   _cTot := AllTrim(Str(_nTotRegs))
   
   nConta := 0

   While ! QRYZBY->(Eof())

      nConta++
      If ! _lSchedule
         IncProc("Lendo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      TRBCOL->(DbAppend())
      TRBCOL->ZBY_VIAGEM := QRYZBY->ZBY_VIAGEM         // C 10  // numero_identificador: "309700845-3097009404"
      TRBCOL->ZBY_NUMERO := QRYZBY->ZBY_NUMERO         // C 10  // numero_identificador: "309700845-3097009404"
      TRBCOL->ZBY_CODPAT := QRYZBY->ZBY_CODPAT         // C 6   // matricula_produtor //A2_COD
      TRBCOL->ZBY_LOJPAT := QRYZBY->ZBY_LOJPAT         // C 4   // matricula_produtor //A2_LOJA
      TRBCOL->ZBY_VOLUME := QRYZBY->ZBY_VOLUME         // N 14  // volume_litros
      TRBCOL->ZBY_DTIVIA := SToD(QRYZBY->ZBY_DTIVIA)   // D 8   // data_coleta
      TRBCOL->ZBY_HRINI  := QRYZBY->ZBY_HRINI          // C 8   // hora_coleta
      TRBCOL->WK_RECNO   := QRYZBY->NRREG              // N 10  // Recno da Tabela ZBY
      TRBCOL->WK_EXCLUID := "true"                     // C 5   // Indica que é uma exclusão de coletas

      _lHaDadosE := .T.  

      QRYZBY->(DBSkip())
   EndDo

End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGLT032D
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/02/2025
Descrição----------: Rotina de Envio de dados das coletas de Leite Excluídas via WebService Italac para Sistema Evomilk
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MGLT032D(_cChamada)

Local _cColetaL := ""
Local _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
Local _cJSonEnv
Local _nStart
Local _nRetry
Local _cJSonRet
Local _nTimOut
Local _cRetHttp
Local _cJSonColeta, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 500 //50 // 100  // Total de registros para envio.
Local _nI 
Local _nJ 
Local _nX
Local _aColetaEnv
Local _nRecno := 0
Local _LinkCerto := ""
Local _cTenantid := SUPERGETMV('IT_TENAIDE',.F., "LATITATE1")
Local _aColetas  := {}
Local _cJsonComp := ""
Local _nIntervalo

Private _cNrIdent
Private _cNrMatr
Private _cVolume
Private _cDtColeta
Private _cHoraCol
Private _cObserv
Private _cNomeCoop
Private _cTipoCoop
Private _cExcluida := 'False'

Private _OFWRITER // Para gravação de arquivos texto, para envio para Evomilk para conferência.

Default _cChamada := "M"

Begin Sequence
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK03) // LINK DE ENVIO DA COLETA DO LEITE.
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf

      Break
   EndIf

   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      EndIf

      Break
   EndIf

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cColetaL := U_MGLT032X(_cDirJSon+"Coleta_de_Leite_Evomilk.json")

   If Empty(_cColetaL)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo Coleta de Leite integração Italac x Evomilk","Atenção",,1)
      EndIf

      Break
   EndIf

   _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

   If Empty(_cKey)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf

   _cHoraIni := Time() // Horario Inicial de Processamento

   _aHeadOut := {}

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')
   _nTotRegs:=TRBCOL->(LastRec())
   If _cChamada == "M"
      ProcRegua(_nTotRegs)
   EndIf

   _cJSonColeta := "["
   _cJSonGrp    := ""
   _cResult  := ""
   _cSucesso := ""
   _cErro    := ""
   _aSucesso := {}
   _aErro    := {}

   _nI := 1

   _aColetaEnv := {}
   _cTot       := AllTrim(Str(_nTotRegs))
   _cLidos     := _cTot
   nConta      := 0
   _nIntervalo := 5

   TRBCOL->(DBGoTop())
   While ! TRBCOL->(Eof())

      nConta++
      If _cChamada == "M"
         IncProc("Transmitindo Coletas: "+StrZero(nConta,6) +" de "+ _cTot)
      EndIf

      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))
      If _nMinutos > _nIntervalo // 5 // 28 // minutos
         _cKey := U_MGLT032T(_cChamada) // Obtem o Token de acesso.

         If Empty(_cKey)
            If _cChamada == "M" // Chamada via menu.
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Coleta de Leite Produtores cancelada.","Atenção",,1)
            EndIf

            Break
         EndIf

         _aHeadOut := {}
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid) // aAdd(_aHeadOut,'TENANTID: LATITATE1')

         _cHoraIni := Time()

      EndIf

      // Efetua a leitura dos dados e montagem do JSon.
      _cNrIdent  := TRBCOL->ZBY_VIAGEM+TRBCOL->ZBY_NUMERO            // C 6   // numero_identificador: "309700845-3097009404"
      _cNrMatr   := TRBCOL->ZBY_CODPAT + "-" + TRBCOL->ZBY_LOJPAT    // C 6   // matricula_produtor //A2_COD
      _cVolume   := AllTrim(Str(TRBCOL->ZBY_VOLUME,14))         // N 14  // volume_litros
      _cDtColeta := StrZero(Year(TRBCOL->ZBY_DTIVIA),4) + "-" + StrZero(Month(TRBCOL->ZBY_DTIVIA),2) + "-" + StrZero(Day(TRBCOL->ZBY_DTIVIA),2)      // D 8   // data_coleta
      _cHoraCol  := TRBCOL->ZBY_HRINI                           // WK_HORACOL                          // C 8   // hora_coleta
      _cObserv   := TRBCOL->WK_OBSERV                           // C 100 // observações
      _nRecno    := TRBCOL->WK_RECNO
      _cExcluida := TRBCOL->WK_EXCLUID

      //Guarda as coletas para atualização das tabelas.
      _cTipoCoop := Posicione('SA2',1,xFilial('SA2')+TRBCOL->ZBY_CODPAT+TRBCOL->ZBY_LOJPAT,'A2_L_TPASS') // Tipo de Associação // Associado/Cooperado
      If !Empty(_cTipoCoop) .And. _cTipoCoop == "C"
         _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_L_NATRA') // Nome Atravessador
      Else
         _cNomeCoop := Posicione('SA2',1,xFilial('SA2')+SubStr(_cNrMatr,1,6)+SubStr(_cNrMatr,8,4),'A2_NOME') // Nome do Produtor?
      EndIf
      aAdd(_aColetas, {_cNrIdent,;            // Ticket         // 1
                       TRBCOL->ZBY_CODPAT,;   // Codigo         // 2
                       TRBCOL->ZBY_LOJPAT,;   // Loja           // 3
                       _cNomeCoop,;           // Nome           // 4
                       _cDtColeta,;           // Dt Coleta      // 5
                             "R" ,;           // Status         // 6
                       TRBCOL->WK_RECNO,;     // Recno          // 7
                       ""})                   // JSon da Coleta // 8  

      _cNomeCoop := ""
      _cTipoCoop := ""

      _cJSonEnv := &(_cColetaL)       

      _cJSonGrp += If(!Empty(_cJSonGrp),",","") + _cJSonEnv

      _aColetas[Len(_aColetas), 8 ] := _cJSonEnv

      If _nI >= _nTotRegEnv

         _cJSonColeta += _cJSonGrp + "]"

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil
         _nTimOut	 	:= 720 //120

         _cRetHttp    := ''

         _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )
         
         _cJsonComp := _cJSonColeta

         _cResult  := ""
         _cSucesso := ""
         _cErro    := ""
         _aSucesso := {}
         _aErro    := {}

         If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
            _cRetHttp := DecodeUtf8(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            
            _oJson := JsonObject():new()
            _cRet := _oJson:FromJson(_cRetHttp)
         
            _cResult  := _oJson:GetJsonObject("status")
            _oResult  := _oJson:GetJsonObject("result")
            
            _cSucesso := _oResult:GetJsonObject("success")
            _cErro    := _oResult:GetJsonObject("error")
            
         EndIf
        
         If ValType(_cResult) <> "C"  
            _cResult := ""
         EndIf 

         _aSucesso := StrTokArr2(_cSucesso,",")
                  
         For _nJ := 1 To Len(_aSucesso) 
         
             _cCodigoCo := AllTrim(_aSucesso[_nJ])
             _nX := aScan(_aColetas,{|x| x[1] == _cCodigoCo})
             If _nX > 0
                _aColetas[_nX,6] := "A"
             EndIf 
         Next _nJ

         For _nX := 1 To Len(_aColetas)
             
             If _aColetas[_nX,6] == "A"
                // Grava dados das coletas enviadas e aceitas para histórico.
                ZBI->(RecLock("ZBI",.T.))
                ZBI->ZBI_FILIAL  := xFilial("ZBI")        // Filial do Sistema
                ZBI->ZBI_TICKET  := _aColetas[_nX,1]      // Ticket
                ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
                ZBI->ZBI_CODPRO  := _aColetas[_nX,2]      // Codigo do Produtor
                ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]      // Loja do Produtor
                ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]       // Nome
                ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)   // Motivo da Rejeição
                ZBI->ZBI_JSONEN  :=  _aColetas[_nX,8]     //_cJSonColeta  // Json de Envio
                ZBI->ZBI_DTENV	  :=  Date()             // Data de Envio
                ZBI->ZBI_HRENV	  :=  Time()             // Hora de Envio
                ZBI->ZBI_STATUS  :=  "A"                  // Status da Integração
                ZBI->ZBI_WEBINT  :=  "E"                  // Indica que a integração está sendo realizada com o App Evomilk
                ZBI->(MSUnLock())
                _nAceitos++

                // Atualiza a tabela ZBY
                ZBY->(DBGoTo(_aColetas[_nX,7]))
                ZBY->(RecLock("ZBY", .F.))
                ZBY->ZBY_ENVEVO := "N"
                ZBY->(MSUnLock())
             Else
                // Grava dados das coletas enviadas e rejeitadas para histórico.
                ZBI->(RecLock("ZBI",.T.))
                ZBI->ZBI_FILIAL  := xFilial("ZBI")             // Filial do Sistema
                ZBI->ZBI_TICKET  := _aColetas[_nX,1]           // Ticket
                ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
                ZBI->ZBI_CODPRO  := _aColetas[_nX,2]           // Codigo do Produtor
                ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]           // Loja do Produtor
                ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]           // Nome
                ZBI->ZBI_MOTIVO  := AllTrim(_cRetHttp)         // Motivo da Rejeição
                ZBI->ZBI_DTREJ   := Date()                     // Data da Rejeição
                ZBI->ZBI_HRREJ   := Time()                     // Hora da Rejeição

                ZBI->ZBI_JSONEN  := _cJsonComp                 // _aColetas[_nX,8]          // _cJSonColeta // Json de Envio

                ZBI->ZBI_DTENV	:= Date()                     // Data de Envio
                ZBI->ZBI_HRENV   := Time()                     // Hora de Envio
                ZBI->ZBI_STATUS  := "R"                        // Status da Integração
                ZBI->ZBI_WEBINT  := "E"                        // Indica que a integração está sendo realizada com o App Evomilk
                ZBI->(MSUnLock())
                _nRejeitados++
             EndIf
         Next 
        
         _aColetaEnv := {}
         _cJSonColeta := "["
         _cJSonGrp := ""
         _nI := 0
         _aColetas := {}

      EndIf

      _nI += 1

      TRBCOL->(DBSkip())
   EndDo

   If ! Empty(_cJSonGrp)
      _cJSonColeta += _cJSonGrp + "]"
      _nStart 	   := 0
      _nRetry 	   := 0
      _cJSonRet    := Nil
      _nTimOut	   := 720 // 120
      _cRetHttp    := ''
      _cRetHttp  := AllTrim( HttpPost( _cLinkWS , '' , _cJSonColeta , _nTimOut , _aHeadOut , @_cJSonRet ) )
      
      _cJsonComp := _cJSonColeta

      _cResult  := ""
      _cSucesso := ""
      _cErro    := ""
      _aSucesso := {}
      _aErro    := {}

      If ! Empty(_cRetHttp) .And. "success" $ _cRetHttp
         _cRetHttp := DecodeUtf8(_cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )

         _oJson := JsonObject():new()
         _cRet := _oJson:FromJson(_cRetHttp)
         
         _cResult  := _oJson:GetJsonObject("status")
         _oResult  := _oJson:GetJsonObject("result")
         _cSucesso := _oResult:GetJsonObject("success")
         _cErro    := _oResult:GetJsonObject("error")
      EndIf

      If ValType(_cResult) <> "C"  
         _cResult := ""
      EndIf 

      _aSucesso := StrTokArr2(_cSucesso,",")
                  
      For _nJ := 1 To Len(_aSucesso) 
         
          _cCodigoCo := AllTrim(_aSucesso[_nJ])
          _nX := aScan(_aColetas,{|x| x[1] == _cCodigoCo})
          If _nX > 0
             _aColetas[_nX,6] := "A"
          EndIf  
      Next _nJ

      For _nX := 1 To Len(_aColetas)
         
          If _aColetas[_nX,6] == "A"
             // Grava dados das coletas enviadas e aceitas para histórico.
             ZBI->(RecLock("ZBI",.T.))
             ZBI->ZBI_FILIAL  := xFilial("ZBI")                         // Filial do Sistema
             ZBI->ZBI_TICKET  := _aColetas[_nX,1]                       // Ticket
             ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-","")) // Data Coleta
             ZBI->ZBI_CODPRO  := _aColetas[_nX,2]                       // Codigo do Produtor
             ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]                       // Loja do Produtor
             ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]                       // Nome
             ZBI->ZBI_MOTIVO  := AllTrim(_cRetHttp)                     // Motivo da Rejeição
             ZBI->ZBI_JSONEN  := _aColetas[_nX,8]                       // _cJSonColeta  // Json de Envio
             ZBI->ZBI_DTENV	:= Date()                                 // Data de Envio
             ZBI->ZBI_HRENV	:= Time()                                 // Hora de Envio
             ZBI->ZBI_STATUS  := "A"                                    // Status da Integração
             ZBI->ZBI_WEBINT  := "E"                                    // Indica que a integração está sendo realizada com o App Evomilk
             ZBI->(MSUnLock())
             _nAceitos++

             // Atualiza a tabela ZBY
             ZBY->(DBGoTo(_aColetas[_nX,7]))
             ZBY->(RecLock("ZBY", .F.))
             ZBY->ZBY_ENVEVO := "N"
             ZBY->(MSUnLock())
          Else
             // Grava dados das coletas enviadas e rejeitadas para histórico.
             ZBI->(RecLock("ZBI",.T.))
             ZBI->ZBI_FILIAL  := xFilial("ZBI")                          // Filial do Sistema
             ZBI->ZBI_TICKET  := _aColetas[_nX,1]                        // Ticket
             ZBI->ZBI_DTCOLE  := SToD(StrTran(_aColetas[_nX,5],"-",""))  // Data Coleta
             ZBI->ZBI_CODPRO  := _aColetas[_nX,2]                        // Codigo do Produtor
             ZBI->ZBI_LOJPRO  := _aColetas[_nX,3]                        // Loja do Produtor
             ZBI->ZBI_NOMPRO  := _aColetas[_nX,4]                        // Nome
             ZBI->ZBI_MOTIVO  :=  AllTrim(_cRetHttp)                     // Motivo da Rejeição
             ZBI->ZBI_DTREJ   :=  Date()                                 // Data da Rejeição
             ZBI->ZBI_HRREJ   :=  Time()                                 // Hora da Rejeição

             ZBI->ZBI_JSONEN  :=  _cJsonComp // _aColetas[_nX,8]         // _cJSonColeta // Json de Envio

             ZBI->ZBI_DTENV	:=  Date()                                 // Data de Envio
             ZBI->ZBI_HRENV   :=  Time()                                 // Hora de Envio
             ZBI->ZBI_STATUS  :=  "R"                                    // Status da Integração
             ZBI->ZBI_WEBINT  :=  "E"                                    // Indica que a integração está sendo realizada com o App Evomilk
             ZBI->(MSUnLock())
             _nRejeitados++
          EndIf
      Next
   EndIf
   
End Sequence

Return

/*
===============================================================================================================================
Função-------------: MGL32LNF
Autor--------------: Julio de Paula Paz
Data da Criacao----: 29/05/2024
Descrição----------: Chama a rotina de integração de notas fiscais, para leitura de dados, geração de PDF de Danfe 
                     e gravação da tabelas de ZBV para envio ao app Cia do Leite.
                     Rotina rodada em modo Scheduller.
                     NOTAS FISCAIS
Parametros--------:  Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32LNF()

Begin Sequence 

   // Chama a rotina de leitura e gravação de dados das notas fiscais
   // para envio ao App Cia do Leite.
   // Esta função é para programação do Scheduler.
   U_MGL32NFS("L")

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGL32TNF
Autor--------------: Julio de Paula Paz
Data da Criacao----: 29/05/2024
Descrição----------: Chama a rotina de integração de notas fiscais, de leitura da tabelas gravadas ZBV , rodada em 
                     modo Scheduller, e transmite via Webservice para o App Cia do Leite. 
Parametros--------:  Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32TNF()

Begin Sequence 

   // Chama a rotina de leitura das tabelas ZBV e transmite a
   // nota fiscal via webservice para envio ao App Cia do Leite.
   // Esta função é para programação do Scheduler.
   U_MGL32NFS("T")

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGL32CNF()
Autor--------------: Julio de Paula Paz
Data da Criacao----: 06/06/2024
Descrição----------: Faz a contagem das notas fiscais disponíveis para integração.
Parametros--------:  Nenhum
Retorno------------: _nTotalNF = Total de notas fiscias disponíveis para integração
===============================================================================================================================
*/  
User Function MGL32CNF()

Local _nTotalNF := 0
Local _nNrDiasNFE
Local _cQry 

Begin Sequence 
   
   _nNrDiasNFE := SUPERGETMV('IT_NRDIANF',.F.,60) // Numero de dias para retroceder e considerar a leituras das notas fiscais de produtores.

   _cAnoMes := Str(Year(Date() - _nNrDiasNFE),4) + StrZero(Month(Date() - _nNrDiasNFE),2)   

   _cQry := " SELECT Count(*) NTOTNOTAS "
   _cQry += " FROM "+RETSQLNAME("SF1") +" SF1 "
   _cQry += " INNER JOIN "+RETSQLNAME("SA2")+" SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA AND SA2.A2_I_CLASS = 'P' "
   _cQry += " INNER JOIN SYS_COMPANY SM0 ON M0_CODIGO = '01' AND M0_CODFIL = F1_FILIAL     AND SM0.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED001 SPED01 ON SPED01.CNPJ = SM0.M0_CGC AND SPED01.IE = SM0.M0_INSC     AND SPED01.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED050 SPED50 ON  SPED50.ID_ENT = SPED01.ID_ENT     AND SPED50.NFE_ID = (F1_SERIE || F1_DOC)     AND SPED50.STATUS = '6'     AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += " WHERE "
   _cQry += " SF1.D_E_L_E_T_ =' ' "
   _cQry += " AND F1_ESPECIE = 'SPED' "
   _cQry += " AND F1_CHVNFE <> ' ' "
   _cQry += " AND SubStr(F1_EMISSAO,1,6) >= '"+ _cAnoMes + "' "  // " AND SubStr(F1_EMISSAO,1,6) = '"+ _cAnoMes + "' "   
   _cQry += " AND A2_I_CLASS = 'P' "
   _cQry += " AND A2_MSBLQL = '2' "
   _cQry += " AND A2_L_ATIVO <> 'N' " 
   _cQry += " AND SA2.A2_L_ENVEV = 'N' "
   _cQry += " AND F1_FORMUL = 'S' "
   _cQry += " AND (F1_I_SITUA = ' ' OR F1_I_SITUA = 'N') "  
   _cQry += " AND F1_FILIAL = '" + xFilial("SF1") + "' "  
   _cQry += " AND F1_SERIE = '3' " // Serie 3 = Notas fiscais de produtores de leite.
   _cQry += " AND NOT F1_CHVNFE IN (SELECT ZBV_CHVNFE FROM " + RetSqlName("ZBV") + " ZBV "
   _cQry += "                       WHERE ZBV.D_E_L_E_T_ = ' ' AND ZBV_FILIAL = SF1.F1_FILIAL "
   _cQry += "                             AND ZBV_NRNFE  = SF1.F1_DOC AND ZBV_SERNFE = SF1.F1_SERIE "
   _cQry += "                             AND ZBV_CODPRO = SF1.F1_FORNECE AND ZBV_LOJPRO = SF1.F1_LOJA "	
   _cQry += "                             AND ZBV_STATUS = 'N') "	 

   If Select("QRYTOTNF") > 0
      QRYTOTNF->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYTOTNF" )

   _nTotalNF := QRYTOTNF->NTOTNOTAS

End Sequence 

If Select("QRYTOTNF") > 0
   QRYTOTNF->(DBCloseArea())
EndIf

Return _nTotalNF

/*
===============================================================================================================================
Função-------------: MGL32NFS
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/04/2024
Descrição----------: Rotina Scheduller de integração de notas fiscais e extrato para o App Cia do Leite.
Parametros--------:  _cOpcNFE = "L" = Ler e gravar dados das notas (Gerar PDF Danfe e Demonstrativos).
                              = "T" = Transmitir dados para o App Cia do Leite
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32NFS(_cOpcNFE)

Local _nI //, _nJ

Begin Sequence 
     
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   RESET ENVIRONMENT
   RpcSetType(2) 
 
   // Preparando o ambiente com a filial 01
   RpcSetEnv("01", "01",,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM"})

   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
   
   // Inicia a Integração Webservice via Scheduller.
   _cFilIntWS := SUPERGETMV('IT_FILITEV',.F.,"01;") 

   _aFilIntWS := {}
   
   ZZM->(DBGoTop())

   While ! ZZM->(Eof())
      If ZZM->ZZM_CODIGO $ _cFilIntWS

         aAdd(_aFilIntWS,ZZM->ZZM_CODIGO)
      EndIf 
     
      ZZM->(DBSkip())
   EndDo 

   // Para cada empresa cadastrada no parâmetro IT_FILITEV, inicializa o ambiente, simulando o usuário
   // fazendo login na filial a ser processada.
   For _nI := 1 To Len(_aFilIntWS)   
    
       _cfilial := _aFilIntWS[_nI]

       // Ativa a filial contida em _aFilIntWS
       RESET ENVIRONMENT
       RpcSetType(2) 
   
       // Preparando o ambiente com a filial 01
       RpcSetEnv("01", _cfilial ,,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM","ZBV","ZBX"})
          
       Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
      
       cFilAnt := _cfilial 

	    cUSUARIO := Space(06)+"Administrador  " // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
	    cUserName:= "Schedule" // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
	    
      // Liga ou Desliga a geração de dados para integração Webservice via Scheduller de Notas Fiscais
      _LigaDesGD := SUPERGETMV('IT_LIGDEGD',.F.,.T.) 

       // Rotina de gravação das tabelas de muro ZBV e ZBX para envio das
       // Notas Fiscais e Demonstrativos para o App Cia do Leite.
       If _cOpcNFE == "L" .And. _LigaDesGD
          U_MGL32NFE(.T.)  // .T. = Indica que a rotina foi chamada via Scheduller. 
       EndIf 

      // Liga ou Desliga o envio de dados para integração Webservice via Scheduller de Notas Fiscais
      _LigaDesEN := SUPERGETMV('IT_LIGDEEN',.F.,.T.) 

       // Rotina de transmissão dos dados gravados nas tabela ZBV e ZBX para
       // o App Cia do Leite.
       If _cOpcNFE == "T" .And. _LigaDesEN
          U_MGL32EVN(.T.) // Envia os dados gravados na tabela ZBV para o App Cia do Leite.
       EndIf 
   Next 

End Sequence

Return 

/*
===============================================================================================================================
Função-------------: MGL32NFE
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/04/2024
Descrição----------: Rotina de integração de notas fiscais para o App Cia do Leite. Rotina de gravação dos dados das tabelas
                     de muro ZBV e ZBX para envio dos dados das Notas Fiscais e Demonstrativos para o App Cia do Leite.
Parametros--------:  _lSchedule = .T./.F. = Rotina chamada via Scheduller ou menu.
                     _cTipoInt  = "N" = Nota fiscal
                                = "E" = Extrato
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32NFE(_lSchedule, _cTipoInt)

Local _cDir := "\temp\italapp\" 
Local _nNrDiasNFE := 0
Local _nJ

Private _cPdfExtra
Private _aDadosSpd := {}
Private _cFilSF1 := ""
Private _nTotNotas := 0 

// Variaveis criadas para não alterar diconário SX1 via programa.
// É necessário pois a função Pergunte() altera o conteúdo das variáveis
// MV_PARXX toda vez que é chamada.
Private _xMV_PAR01
Private _xMV_PAR02
Private _xMV_PAR03
Private _xMV_PAR04
Private _xMV_PAR05
Private _xMV_PAR06
Private _xMV_PAR07
Private _xMV_PAR08
Private _xMV_PAR09 
Private _xMV_PAR10 
Private _xMV_PAR11
Private _xMV_PAR12
Private _xMV_PAR13
Private _xMV_PAR14
Private _xMV_PAR15
Private _xMV_PAR16

Begin Sequence 

   If ! File("\temp\italapp\")
      MakeDir("\temp\italapp\")
   EndIf 
                             
   _nNrDiasNFE := SUPERGETMV('IT_NRDIANF',.F.,60) // Numero de dias para retroceder e considerar a leituras das notas fiscais de produtores.

   // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
   If Select("SPED050") > 0
      SPED050->( DBCloseArea() )
   EndIf     
   
   USE SPED050 ALIAS SPED050 SHARED NEW VIA "TOPCONN" 
   
   _cAnoMes := Str(Year(Date() - _nNrDiasNFE),4) + StrZero(Month(Date() - _nNrDiasNFE),2)   

   _cQry := " SELECT F1_DOC, "
   _cQry += " SPED50.R_E_C_N_O_ NRECNO, "
   _cQry += "     SF1.R_E_C_N_O_ REGSF1, "
   _cQry += "     SF1.F1_FORNECE, "
   _cQry += "     SF1.F1_LOJA, SA2.A2_NOME, SA2.A2_CGC, SA2.R_E_C_N_O_ REGSA2 "
   _cQry += " FROM "+RETSQLNAME("SF1") +" SF1 "
   _cQry += " INNER JOIN "+RETSQLNAME("SA2")+" SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA AND SA2.A2_I_CLASS = 'P' "
   _cQry += " INNER JOIN SYS_COMPANY SM0 ON M0_CODIGO = '01' AND M0_CODFIL = F1_FILIAL     AND SM0.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED001 SPED01 ON SPED01.CNPJ = SM0.M0_CGC AND SPED01.IE = SM0.M0_INSC     AND SPED01.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED050 SPED50 ON  SPED50.ID_ENT = SPED01.ID_ENT     AND SPED50.NFE_ID = (F1_SERIE || F1_DOC)     AND SPED50.STATUS = '6'     AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += " WHERE "
   _cQry += " SF1.D_E_L_E_T_ =' ' "
   _cQry += " AND F1_ESPECIE = 'SPED' "
   _cQry += " AND F1_CHVNFE <> ' ' "
   _cQry += " AND SubStr(F1_EMISSAO,1,6) >= '"+ _cAnoMes + "' "  // _cQry += " AND SubStr(F1_EMISSAO,1,6) = '"+ _cAnoMes + "' "
   _cQry += " AND A2_I_CLASS = 'P' "
   _cQry += " AND A2_MSBLQL = '2' "
   _cQry += " AND A2_L_ATIVO <> 'N' " 
   _cQry += " AND SA2.A2_L_ENVEV = 'N' "
   _cQry += " AND F1_FORMUL = 'S' "
   _cQry += " AND (F1_I_SITUA = ' ' OR F1_I_SITUA = 'N') "  
   _cQry += " AND F1_FILIAL = '" + xFilial("SF1") + "' "  
   _cQry += " AND F1_SERIE = '3' " // Serie 3 = Notas fiscais de produtores de leite.
   _cQry += " AND NOT F1_CHVNFE IN (SELECT ZBV_CHVNFE FROM " + RetSqlName("ZBV") + " ZBV "
   _cQry += "                       WHERE ZBV.D_E_L_E_T_ = ' ' AND ZBV_FILIAL = SF1.F1_FILIAL "
   _cQry += "                             AND ZBV_NRNFE  = SF1.F1_DOC AND ZBV_SERNFE = SF1.F1_SERIE "
   _cQry += "                             AND ZBV_CODPRO = SF1.F1_FORNECE AND ZBV_LOJPRO = SF1.F1_LOJA "	
   _cQry += "                             AND ZBV_STATUS = 'N') "	 

   If Select("QRYSF1") > 0
      QRYSF1->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYSF1" )

   DBSelectArea("QRYSF1")

   Count To _nTotNotas

   If ! _lSchedule
      ProcRegua(_nTotNotas)
   EndIf

   QRYSF1->(DBGoTop())

   IMP_PDF := 6 
   cIdEnt := RetIdEnti(.F.)
   
   SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM                                                                                                     
   ZBV->(DBSetOrder(5)) // ZBV_FILIAL+ZBV_NRNFE+ZBV_SERNFE+ZBV_CODPRO+ZBV_LOJPRO+ZBV_STATUS

  _nJ := 1  

   While ! QRYSF1->(Eof()) 

      If ! _lSchedule
         IncProc("Gerando PDFs das Notas Fiscais dos Produtores..." + AllTrim(Str(_nJ,10)) + "/" + AllTrim(Str(_nTotNotas,10)))
         _nJ += 1
      EndIf 
      
      SF1->(DBGoTo(QRYSF1->REGSF1))

      If AllTrim(SF1->F1_SERIE) <> "3"
         QRYSF1->(DBSkip())
         Loop
      EndIf 
      
      SA2->(DBGoTo(QRYSF1->REGSA2))
      
      SPED050->(DBGoTo(QRYSF1->NRECNO))
      
      _aDadosSpd := { SPED050->NFE_PROT,;      // 1
                      SPED050->XML_SIG,;       // 2 
                      SPED050->NFE_ID,;        // 3
                      SPED050->XML_DPEC,;      // 4
                      SPED050->REG_DPEC,;      // 5 
                      SPED050->TIME_NFE,;      // 6
                      SPED050->DATE_NFE,;      // 7
                      "",;                     // 8
                      Str(SPED050->STATUS,1),; // 9
                      "",;                     // 10
                      ""}                      // 11
      
      // Gera o Danfe do Produtor em PDF
      _aDevice := {}
      aAdd(_aDevice,"DISCO") // 1
      aAdd(_aDevice,"SPOOL") // 2
      aAdd(_aDevice,"EMAIL") // 3
      aAdd(_aDevice,"EXCEL") // 4
      aAdd(_aDevice,"HTML" ) // 5
      aAdd(_aDevice,"PDF"  ) // 6

      Pergunte("NFSIGW",.F.) 

      MV_PAR01 := SF1->F1_DOC
	   MV_PAR02 := SF1->F1_DOC
	   MV_PAR03 := SF1->F1_SERIE
	   MV_PAR04 := 1	// [Operacao] NF de Entrada
	   MV_PAR05 := 2	// [Frente e Verso] Sim
	   MV_PAR06 := 2	// [DANFE simplificado] Sim
      MV_PAR07 := SF1->F1_EMISSAO 
      MV_PAR08 := SF1->F1_EMISSAO 
      MV_PAR09 := Space(1)
      MV_PAR10 := Space(1)
      MV_PAR11 := SF1->F1_FORNECE   
      MV_PAR12 := SF1->F1_FORNECE             
      MV_PAR13 := SF1->F1_LOJA 
      MV_PAR14 := SF1->F1_LOJA
      MV_PAR15 := SF1->F1_L_SETOR 
      MV_PAR16 := SF1->F1_L_LINHA 

      _xMV_PAR01 := MV_PAR01 // SF1->F1_DOC
      _xMV_PAR02 := MV_PAR02 // SF1->F1_DOC
      _xMV_PAR03 := MV_PAR03 // SF1->F1_SERIE
      _xMV_PAR04 := MV_PAR04 // 1	// [Operacao] NF de Entrada
      _xMV_PAR05 := MV_PAR05 // 2	// [Frente e Verso] Sim
      _xMV_PAR06 := MV_PAR06 // 2	// [DANFE simplificado] Sim
      _xMV_PAR07 := MV_PAR07 // SF1->F1_EMISSAO 
      _xMV_PAR08 := MV_PAR08 // SF1->F1_EMISSAO 
      _xMV_PAR09 := MV_PAR09 // Space(1)
      _xMV_PAR10 := MV_PAR10 // Space(1)
      _xMV_PAR11 := MV_PAR11 // SF1->F1_FORNECE   
      _xMV_PAR12 := MV_PAR12 // SF1->F1_FORNECE             
      _xMV_PAR13 := MV_PAR13 // SF1->F1_LOJA 
      _xMV_PAR14 := MV_PAR14 // SF1->F1_LOJA
      _xMV_PAR15 := MV_PAR15 // SF1->F1_L_SETOR 
      _xMV_PAR16 := MV_PAR16 // SF1->F1_L_LINHA 

      cFilePrint := "DANFE_PRODUTOR_"+SF1->F1_FORNECE+"_LOJA_"+SF1->F1_LOJA+"_NF_"+AllTrim(SF1->F1_DOC)+"_"+AllTrim(SF1->F1_SERIE)+DToS(MSDate())+".pdf"
      cFilePrint := Lower(cFilePrint)

      nLocal       	 := 2 //"LOCAL" //If(fwGetProfString(cSession,"LOCAL","SERVER",.T.)=="SERVER",1,2 )
      nOrientation 	 := 1 // If(fwGetProfString(cSession,"ORIENTATION","PORTRAIT",.T.)=="PORTRAIT",1,2)
      cDevice     	 := "PDF" // If(Empty(fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.)),"PDF",fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.))
      nPrintType      := aScan(_aDevice,{|x| x == cDevice })
      lAdjustToLegacy := .F.

            //  FWMsPrinter():New ( < cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer]       , [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
      oDanfe := FWMSPrinter():New(cFilePrint         , IMP_PDF   , lAdjustToLegacy   , _cDir /*cPathInServer*/, .T.             ,            ,                ,            ,           ,             ,        , .F. )

		oDanfe:SetViewPDF(.F.)
		oDanfe:lInJob := .T.

                    // 1      2       3        4      5         6          7          8        9
        U_RGLT076(cIdEnt ,/*cVal1*/,/*cVal2*/ ,oDanfe ,       ,cFilePrint ,/*lIsLoja*/, /*nTipo*/, _cDir )  
      
      If ValType(oDanfe) == "O"
         FreeObj(oDanfe)
      EndIf
      oDanfe := Nil
 
      If ! File(_cDir+cFilePrint)  // Não foi possível gerar o PDF do Danfe. 
         QRYSF1->(DBSkip())
         Loop
      EndIf 
   
      // Converte o PDF da Nota Fiscal e Demonstrativo em Encode64
      _cEcod64Nf := Encode64( ,_cDir + cFilePrint)

      If Empty(_cEcod64Nf)
         Sleep(1000)
         _cEcod64Nf := Encode64( ,_cDir + cFilePrint)
      EndIf 

      // Se já existir a nota fiscal na tabela ZBV. Exclui para incluir novamente.
      If ZBV->(MsSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+"N")) // ZBV_FILIAL+ZBV_NRNFE+ZBV_SERNFE+ZBV_CODPRO+ZBV_LOJPRO+ZBV_STATUS
         While ! ZBV->(Eof()) .And. ZBV->(ZBV_FILIAL+ZBV_NRNFE+ZBV_SERNFE+ZBV_CODPRO+ZBV_LOJPRO+ZBV_STATUS) == SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+"N"
            ZBV->(RecLock("ZBV",.F.))    
            ZBV->(DbDelete())
            ZBV->(MSUnLock())

            ZBV->(DBSkip())
         EndDo
      EndIf 
         
      // Obtem os dados de item da nota de entrada.
      _nQtdLit := 0

      SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
      SD1->(MSSEEK(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
      While ! SD1->(Eof()) .And. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == ;
                                    SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
         
         _nQtdLit := _nQtdLit + SD1->D1_QUANT  

         SD1->(DBSkip())
      EndDo 

      Begin Transaction 
         ZBV->(RecLock("ZBV",.T.))
         ZBV->ZBV_FILIAL := SF1->F1_FILIAL                                                            // Filial do Sistema
         ZBV->ZBV_NRNFE  := SF1->F1_DOC		                                                         // Numero da Nota Fiscal
         ZBV->ZBV_SERNFE := SF1->F1_SERIE		                                                         // Serie da Nota Fiscal
         ZBV->ZBV_CHVNFE := SF1->F1_CHVNFE 	                                                         // Chave da Nota Fiscal
         ZBV->ZBV_DTEMIS := SF1->F1_EMISSAO	                                                         // Data Emissão NFE
         ZBV->ZBV_CODPRO := SF1->F1_FORNECE	                                                         // Codigo do Produtor
         ZBV->ZBV_LOJPRO := SF1->F1_LOJA		                                                         // Loja do Produtor
         ZBV->ZBV_NOMPRO := Posicione('SA2',1,xFilial('SA2')+SF1->F1_FORNECE+SF1->F1_LOJA,'A2_NOME')	// Nome do Produtor
         ZBV->ZBV_PDFNFE := _cEcod64Nf		                                                            // Pdf NFE em ENCODE 64
         ZBV->ZBV_VALNFE := SF1->F1_VALBRUT		                                                      // Valor Total Nota Fiscal
         ZBV->ZBV_QTDLIT := _nQtdLit                                                                  // Quantidade de Litros
         ZBV->ZBV_AMREFE := StrZero(Year(SF1->F1_EMISSAO),4)+"-"+StrZero(Month(SF1->F1_EMISSAO),2)		//	Ano e Mês de Referencia
         ZBV->ZBV_STATUS := "N"	                                                                  // Status da Integração Nfe // N = Não processado / P=Processado / I = Integrado.
         ZBV->ZBV_DTHORA := StrZero(Year(Date()),4) + "-" + StrZero(Month(Date()),2) + "-" + StrZero(Day(Date()),2) + "T" + Time() + "Z"    // XML da NFE em Encode64
         ZBV->(MSUnLock())
      End Transaction 
      
      If Type("_cEcod64Nf") == "O"
         FreeObj(_cEcod64Nf)
      EndIf 
	   _cEcod64Nf := Nil	

      // Exclui o PDF da Danfe e do Demonstrativo, após a gravação da tabela ZBV.
      If File(_cDir + cFilePrint) // Exclui o PDF do Danfe 
         FErase(_cDir + cFilePrint)
      EndIf 

      QRYSF1->(DBSkip())
   EndDo 
 
End Sequence 

If Select("SPED050") > 0
   SPED050->( DBCloseArea() )
EndIf  

Return 

/*
===============================================================================================================================
Função-------------: MGL32EVN(_lSchedule)
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2022
Descrição----------: Rotina de Envio de dados das Notas Fiscais via WebService Italac para Sistema Evomilk.
Parametros--------:  _lSchedule = .T. = Rotina rodada em modo automático. .F. = Rotina rotada através de menu.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32EVN(_lSchedule)

Local _cEmpWebService
Local _cJSonEnv 
Local _nStart 
Local _nRetry 
Local _cJSonRet
Local _nTimOut	
Local _cRetHttp
Local _cJSonNFE, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 1 // 100  // Total de registros para envio.
Local _nI , _oRetJSon, _lResult 
Local _cQry := ""
Local _cTenantid := ""
Local _nIntervalo

Private _cEcod64Ex
Private _cEcod64Nf
Private _cCodEvoMilk :="EVOMKT"

Default _lSchedule := .F.

Begin Sequence 
   // Obtem os dados do servidor Webservice.
   _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK06) // Link de envio das Notas Fiscais.
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else 
      If ! _lSchedule // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf 

      Break
   EndIf

   If Empty(_cDirJSon)
      If ! _lSchedule // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      EndIf 

      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cModeloNF := U_MGLT032X(_cDirJSon + "notas_fiscais_produtores_evomilk.json")

   If Empty(_cModeloNF)
      If ! _lSchedule // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON Capa do PDF de Notas Fiscais na integração Italac x Evomilk.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   If _lSchedule
      _cKey := U_MGLT032T("S") // Obtem o Token de acesso. S=Schedule
   Else 
      _cKey := U_MGLT032T("M") // Obtem o Token de acesso. M=menu
   EndIf 

   If Empty(_cKey)
      If ! _lSchedule // Chamada via menu.   
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Pdfs de Notas fiscais Cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf 
   
   _cHoraIni := Time() // Horario Inicial de Processamento
   
   _aHeadOut := {}              
   

   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid)

   _cJSonNFE := "["
   _cJSonGrp    := ""
   _nI := 1
   _nIntervalo := 5
   
   // Efetua a leitura de dados para integração.

   _cQry := " SELECT ZBV.R_E_C_N_O_ REGZBV, SF1.R_E_C_N_O_  REGSF1 "       // numero_identificador: "06019"
   _cQry += " FROM " + RetSqlName("SF1") + " SF1, " + RetSqlName("ZBV") + " ZBV "  
   _cQry += " WHERE SF1.D_E_L_E_T_ = ' ' AND ZBV.D_E_L_E_T_ = ' ' "
   _cQry += " AND F1_FILIAL  = ZBV_FILIAL "
   _cQry += " AND F1_FORNECE = ZBV_CODPRO "
   _cQry += " AND F1_LOJA    = ZBV_LOJPRO "
   _cQry += " AND F1_DOC     = ZBV_NRNFE "
   _cQry += " AND F1_SERIE   = ZBV_SERNFE "
   _cQry += " AND F1_ESPECIE = 'SPED' "   
   _cQry += " AND ZBV_STATUS = 'N' "  
   _cQry += " AND ZBV_FILIAL = '" + xFilial("ZBV") + "' "

   If Select("QRYZBV") > 0
      QRYZBV->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYZBV" )

   DBSelectArea("QRYZBV")

   Count To _nTotRegs

   If ! _lSchedule
      ProcRegua(_nTotRegs)
   EndIf 

   // Inicia o envio dos dados.
   QRYZBV->(DBGoTop())
   While ! QRYZBV->(Eof())
      
      If ! _lSchedule 
         IncProc("Transmitindo os dados das notas fiscais...")
      EndIf 
      
      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))      
      If _nMinutos > _nIntervalo // 5 // 28 // minutos 
         If _lSchedule
            _cKey := U_MGLT032T("S") // Obtem o Token de acesso. S=Schedule
         Else 
            _cKey := U_MGLT032T("M") // Obtem o Token de acesso. M=menu
         EndIf 

         If Empty(_cKey)
            If ! _lSchedule  // Chamada via menu.   
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Notas Fiscais cancelada.","Atenção",,1)
            EndIf
   
            Break
         EndIf 
         
         _aHeadOut := {}              
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) ) 
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid)

         _cHoraIni := Time()

      EndIf 
      
      // Posiciona os registros das tabelas ZBV E SF1.
      ZBV->(DBGoTo(QRYZBV->REGZBV))
      SF1->(DBGoTo(QRYZBV->REGSF1))

      // Efetua a leitura dos dados e montagem do JSon.
      _cJSonEnv := &(_cModeloNF) 

      _cJSonGrp += If(!Empty(_cJSonGrp),",","") + _cJSonEnv 

      If _nI >= _nTotRegEnv
  
         _cJSonNFE += _cJSonGrp + "]"
   
        _cJSonNFE := DecodeUTF8(_cJSonNFE, "cp1252")

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil 
         _nTimOut	 	:= 120
         
         _cRetHttp    := ''

         _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonNFE , _nTimOut , _aHeadOut , @_cJSonRet ) ) 

         If ! Empty(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)             
         EndIf
   
         _cAuxHTTP := Upper(_cRetHttp)  

         _lResult := .F. 
         If ! Empty(_oRetJSon) .And."STATUS" $ _cAuxHTTP .And. _oRetJSon:status == "success"
            _lResult := .T. //_oRetJSon:status
         EndIf 
       
         If _lResult // Integração realizada com sucesso 
            // Grava dados das Notas Fiscais e Demonstrativos para histórico.
            ZBV->(RecLock("ZBV",.F.)) 
            ZBV->ZBV_RETNFE :=  AllTrim(_cRetHttp)    // Retorno da Integração
            ZBV->ZBV_JSONNF := _cJSonNFE              // Json de Envio 
            ZBV->ZBV_DTENVN := Date()                 // Data de Envio
            ZBV->ZBV_HRENVI := Time()                 // Hora de Envio
            ZBV->ZBV_STATUS := "A"                    // Status da Integração
            ZBV->(MSUnLock())
        
            // Comentar este trecho.
            // Atualiza a tabela SF1    
            SF1->(RecLock("SF1", .F.))
            SF1->F1_I_SITUA := "P"	  // Situação Integração Cia Leite
            SF1->F1_I_DTENV := Date() // Data de Enviao para Cia do Leite
            SF1->F1_I_HRENV := Time() // Hora de Envio para Cia do Leite
            SF1->(MSUnLock())
            
         Else 
            // Grava dados das Notas Fiscais e Demonstrativos para histórico.
            ZBV->(RecLock("ZBV",.F.)) 
            ZBV->ZBV_RETNFE :=  AllTrim(_cRetHttp)    // Retorno da Integração
            ZBV->ZBV_JSONNF := _cJSonNFE              // Json de Envio 
            ZBV->ZBV_DTENVN := Date()                 // Data de Envio
            ZBV->ZBV_HRENVI := Time()                 // Hora de Envio
            ZBV->ZBV_STATUS := "R"                    // Status da Integração
            ZBV->(MSUnLock())
         EndIf 

         _cJSonNFE := "["
         _cJSonGrp := ""
         _nI := 0

      EndIf 
      
      _nI += 1
      
      QRYZBV->(DBSkip())
   EndDo 

   If ! Empty(_cJSonGrp)
      _cJSonNFE += _cJSonGrp + "]"

      _cJSonNFE := DecodeUTF8(_cJSonNFE, "cp1252")

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil 
      _nTimOut	 	:= 120
       
      _cRetHttp    := ''

      _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonNFE , _nTimOut , _aHeadOut , @_cJSonRet ) ) 

      If ! Empty(_cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)             
      EndIf
       
       _cAuxHTTP := Upper(_cRetHttp)  

      _lResult := .F.
      If ! Empty(_oRetJSon) .And. "STATUS" $ _cAuxHTTP .And. _oRetJSon:status == "success" // "status" $ _cRetHttp  
         _lResult := .T. // _oRetJSon:status
      EndIf 
       
      If _lResult // Integração realizada com sucesso
         // Grava dados das Notas Fiscais e Demonstrativos para histórico.
         ZBV->(RecLock("ZBV",.F.)) 
         ZBV->ZBV_RETNFE :=  AllTrim(_cRetHttp)    // Retorno da Integração
         ZBV->ZBV_JSONNF := _cJSonNFE              // Json de Envio 
         ZBV->ZBV_DTENVN := Date()                 // Data de Envio
         ZBV->ZBV_HRENVI := Time()                 // Hora de Envio
         ZBV->ZBV_STATUS := "A"                    // Status da Integração
         ZBV->(MSUnLock())

         // Atualiza a tabela SF1
         SF1->(RecLock("SF1", .F.))
         SF1->F1_I_SITUA := "P"	  // Situação Integração Cia Leite
         SF1->F1_I_DTENV := Date() // Data de Enviao para Cia do Leite
         SF1->F1_I_HRENV := Time() // Hora de Envio para Cia do Leite
         SF1->(MSUnLock())
         
      Else
         // Grava dados das Notas Fiscais e Demonstrativos para histórico.
         ZBV->(RecLock("ZBV",.F.)) 
         ZBV->ZBV_RETNFE :=  AllTrim(_cRetHttp)    // Retorno da Integração
         ZBV->ZBV_JSONNF := _cJSonNFE              // Json de Envio 
         ZBV->ZBV_DTENVN := Date()                 // Data de Envio
         ZBV->ZBV_HRENVI := Time()                 // Hora de Envio
         ZBV->ZBV_STATUS := "R"                    // Status da Integração // 
         ZBV->(MSUnLock())
      EndIf 
   
   EndIf 
   
End Sequence 

If Select("QRYZBV") > 0
   QRYZBV->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Função-------------: MGL32LEX
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2025
Descrição----------: Chama a rotina de integração de extratos de produtores, para leitura de dados e geração de PDF dos Extratos 
                     e gravação das tabelas de ZBX para envio ao app Evomilk.
                     Rotina rodada em modo Scheduller.
                     Esta função é para programação do Scheduler.
                     EXTRATOS
Parametros--------:  Nenhum
Retorno------------: Nenhum
================================================================================================================================
*/  
User Function MGL32LEX()

Begin Sequence 

   // Chama a rotina de leitura e gravação de dados dos Extratos
   // para envio ao App Evomilk.
   U_MGL32EXS("L")

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGL32TEX
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2025
Descrição----------: Chama a rotina de integração de Extratos/Demonstrativos, de leitura da tabela gravada  ZBX, rodada em 
                     modo Scheduller, e transmite via Webservice para o App Evomilk. 
Parametros--------:  Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32TEX()

Begin Sequence 

   // Chama a rotina de leitura da tabela ZBX e transmite o
   // extrato/demonstrativo via webservice para envio ao App Evomilk.
   // Esta função é para programação do Scheduler.
   U_MGL32EXS("T")

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGL32EXS
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/04/2024
Descrição----------: Rotina Scheduller de integração de extratos/demonstrativos para o App Evomilk.
Parametros--------:  _cOpcNFE = "L" = Ler e gravar dados das notas (Gerar PDF Danfe e Demonstrativos).
                              = "T" = Transmitir dados para o App Cia do Leite
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32EXS(_cOpcExt)
Local _nI

Begin Sequence 
     
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   RESET ENVIRONMENT
   RpcSetType(2) 
   
   // Preparando o ambiente com a filial 01
   RpcSetEnv("01", "01",,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM","ZBV","ZBX"})

   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   // Inicia a Integração Webservice via Scheduller.
   _cFilIntWS := SUPERGETMV('IT_FILITEV',.F.,"01;")

   _aFilIntWS := {}
   
   ZZM->(DBGoTop())

   While ! ZZM->(Eof())
      If ZZM->ZZM_CODIGO $ _cFilIntWS
         aAdd(_aFilIntWS,ZZM->ZZM_CODIGO)
      EndIf 
     
      ZZM->(DBSkip())
   EndDo 

   // Para cada empresa cadastrada no parâmetro IT_FILITEV, inicializa o ambiente, simulando o usuário
   // fazendo login na filial a ser processada.
   For _nI := 1 To Len(_aFilIntWS)   
    
       _cfilial := _aFilIntWS[_nI]

       // Ativa a filial contida em _aFilIntWS
       RESET ENVIRONMENT
       RpcSetType(2) 
   
       // Preparando o ambiente com a filial
       RpcSetEnv("01", _cfilial ,,,,, {"SA2","ZLJ","ZLD",'ZBG', "ZBH", "ZBI", "ZZM","ZBV","ZBX"})
    
       Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
      
       cFilAnt := _cfilial 

	    cUSUARIO := Space(06)+"Administrador  " // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
	    cUserName:= "Schedule" // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
	    
      // Liga ou Desliga a geração de dados para integração Webservice via Scheduller de Notas Fiscais
      // e extratos.
      _LigaDesGD := SUPERGETMV('IT_LIGDEGD',.F.,.T.)

       // Rotina de gravação da tabela de muro ZBX para envio dos
       // Extratos/Demonstrativos para o App Evomilk.
       If _cOpcExt == "L" .And. _LigaDesGD
          
          U_MGL32EXT(.T.)  // .T. = Indica que a rotina foi chamada via Scheduller. 

       EndIf 


      // Liga ou Desliga o envio de dados para integração Webservice via Scheduller de Notas Fiscais
      // e extratos.
      _LigaDesEN := SUPERGETMV('IT_LIGDEEN',.F.,.T.)

       // Rotina de transmissão dos dados gravados na tabela ZBX para
       // o App Evomilk.
       If _cOpcExt == "T" .And. _LigaDesEN
          
          U_MGL32EVE(.T.) // Envia os dados gravados na tabela ZBV para o App Cia do Leite.

       EndIf 
       
   Next 

End Sequence

Return 

/*
===============================================================================================================================
Função-------------: MGL32EXT
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2025
Descrição----------: Rotina de integração de extratos/demonstrativos para o App Evomilk. Rotina de gravação dos dados da tabela
                     de muro ZBX para envio dos dados dos Extratos/Demonstrativos para o App Evomilk.
Parametros--------:  _lSchedule = .T./.F. = Rotina chamada via Scheduller ou menu.
                     _cTipoInt  = "N" = Nota fiscal
                                = "E" = Extrato
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32EXT(_lSchedule, _cTipoInt)

Local _cDir := "\temp\italapp\" 
Local _nNrDiasNFE := 0
Local _aMesesTxt
Local _cMesTxt
Local _cMes
Local _nI 
Local _nJ 

Private _cPdfExtra
Private _aDadosSpd := {}
Private _cFilSF1 := ""
Private _nTotNotas

Begin Sequence 

   If ! File("\temp\italapp\")
      MakeDir("\temp\italapp\")
   EndIf 

   // Array com os meses para listar em Português.
   _aMesesTxt := {}
   aAdd(_aMesesTxt,{"01","Janeiro"})
   aAdd(_aMesesTxt,{"02","Fevereiro"})
   aAdd(_aMesesTxt,{"03","Março"})
   aAdd(_aMesesTxt,{"04","Abril"})
   aAdd(_aMesesTxt,{"05","Maio"})
   aAdd(_aMesesTxt,{"06","Junho"})
   aAdd(_aMesesTxt,{"07","Julho"})
   aAdd(_aMesesTxt,{"08","Agosto"})
   aAdd(_aMesesTxt,{"09","Setembro"})
   aAdd(_aMesesTxt,{"10","Outubro"})
   aAdd(_aMesesTxt,{"11","Novembro"})
   aAdd(_aMesesTxt,{"12","Dezembro"})
                             
   // Faz a leitura das notas fiscais para geração dos extratos/demonstrativos
   _nNrDiasNFE :=  SUPERGETMV('IT_NRDIANF',.F.,30)
   _cAnoMes := Str(Year(Date() - _nNrDiasNFE),4) + StrZero(Month(Date() - _nNrDiasNFE),2)   

   _cQry := " SELECT F1_DOC, "
   _cQry += " SPED50.R_E_C_N_O_ NRECNO, "
   _cQry += "     SF1.R_E_C_N_O_ REGSF1, "
   _cQry += "     SF1.F1_FORNECE, "
   _cQry += "     SF1.F1_LOJA, SA2.A2_NOME, SA2.A2_CGC, SA2.R_E_C_N_O_ REGSA2 "
   _cQry += " FROM "+RETSQLNAME("SF1") +" SF1 "
   _cQry += " INNER JOIN "+RETSQLNAME("SA2")+" SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA AND SA2.A2_I_CLASS = 'P' "
   _cQry += " INNER JOIN SYS_COMPANY SM0 ON M0_CODIGO = '01' AND M0_CODFIL = F1_FILIAL     AND SM0.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED001 SPED01 ON SPED01.CNPJ = SM0.M0_CGC AND SPED01.IE = SM0.M0_INSC     AND SPED01.D_E_L_E_T_ = ' ' "
   _cQry += " INNER JOIN SPED050 SPED50 ON  SPED50.ID_ENT = SPED01.ID_ENT     AND SPED50.NFE_ID = (F1_SERIE || F1_DOC)     AND SPED50.STATUS = '6'     AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += " WHERE "
   _cQry += " SF1.D_E_L_E_T_ =' ' "
   _cQry += " AND F1_ESPECIE = 'SPED' "
   _cQry += " AND F1_CHVNFE <> ' ' "
   _cQry += " AND SubStr(F1_EMISSAO,1,6) >= '"+ _cAnoMes + "' "   //_cQry += " AND SubStr(F1_EMISSAO,1,6) = '"+ _cAnoMes + "' " // 
   _cQry += " AND A2_I_CLASS = 'P' "
   _cQry += " AND A2_MSBLQL = '2' "
   _cQry += " AND A2_L_ATIVO <> 'N' " 
   _cQry += " AND SA2.A2_L_ENVEV = 'N' "
   _cQry += " AND F1_FORMUL = 'S' "
   _cQry += " AND (F1_I_SITEX = ' ' OR F1_I_SITEX = 'N') "   
   _cQry += " AND F1_FILIAL = '" + xFilial("SF1") + "' "  
   _cQry += " AND F1_SERIE = '3' " // Serie 3 = Notas fiscais de produtores de leite.
   _cQry += " AND NOT F1_CHVNFE IN (SELECT F1_CHVNFE FROM " + RetSqlName("ZBX") + " ZBX, " + RetSqlName("SF1") + " SF1_2 "
   _cQry += "                       WHERE ZBX.D_E_L_E_T_ = ' ' "
   _cQry += "                             AND SF1_2.D_E_L_E_T_ = ' ' "
   _cQry += "                             AND ZBX_FILIAL = SF1.F1_FILIAL "
   _cQry += "                             AND ZBX_NRNFE  = SF1.F1_DOC "
   _cQry += "                             AND ZBX_SERNFE = SF1.F1_SERIE "
   _cQry += "                             AND ZBX_CODPRO = SF1.F1_FORNECE "
   _cQry += "                             AND ZBX_LOJPRO = SF1.F1_LOJA "	
   _cQry += "                             AND ZBX_STATUS = 'N' "	
   _cQry += "                             AND ZBX_FILIAL = SF1_2.F1_FILIAL "
   _cQry += "                             AND ZBX_NRNFE  = SF1_2.F1_DOC "
   _cQry += "                             AND ZBX_SERNFE = SF1_2.F1_SERIE "
   _cQry += "                             AND ZBX_CODPRO = SF1_2.F1_FORNECE "
   _cQry += "                             AND ZBX_LOJPRO = SF1_2.F1_LOJA) "	

   If Select("QRYSF1") > 0
      QRYSF1->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYSF1" )

   DBSelectArea("QRYSF1")

   Count To _nTotNotas

   If ! _lSchedule
      ProcRegua(_nTotNotas)
   EndIf

   QRYSF1->(DBGoTop())

   IMP_PDF := 6 
   cIdEnt := RetIdEnti(.F.)
   
   SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM                                                                                                     
   ZBX->(DBSetOrder(4)) // ZBX_FILIAL+ZBX_NRNFE+ZBX_SERNFE+ZBX_CODPRO+ZBX_LOJPRO+ZBX_STATUS

   _nJ := 1  

   While ! QRYSF1->(Eof()) 
      
      If ! _lSchedule
         IncProc("Gerando PDFs dos Extratos dos Produtores..." + AllTrim(Str(_nJ,10)) + "/" + AllTrim(Str(_nTotNotas,10)))
         _nJ += 1
      EndIf 

      SF1->(DBGoTo(QRYSF1->REGSF1))
   
      If AllTrim(SF1->F1_SERIE) <> "3"
         QRYSF1->(DBSkip())
         Loop
      EndIf 
      
      // Gera o Demonstrativo/Extrato do Produtor.
      _cPdfExtra := "Demonstrativo_Produtor_" + AllTrim(SF1->F1_FORNECE) +"_Loja_"+AllTrim(SF1->F1_LOJA) + "_" + DToS(MSDate()) + ".pdf" 
      _cPdfExtra := Lower(_cPdfExtra)

      U_RGLT075(.T.,,SF1->F1_FORNECE,SF1->F1_LOJA, SF1->F1_FILIAL,SF1->F1_EMISSAO,_cDir,_cPdfExtra)

      If ! File(_cDir+_cPdfExtra)  // Não foi possível gerar o PDF do Extrato.
         QRYSF1->(DBSkip())
         Loop
      EndIf 

      // Converte o PDF do Demonstrativo em Encode64
      _cEcod64Ex := Encode64( ,_cDir + _cPdfExtra)

      If Empty(_cEcod64Ex)
         Sleep(1000)
         _cEcod64Ex := Encode64( ,_cDir + _cPdfExtra)
      EndIf

      // Se já existir extrato/demonstrativo na tabela ZBX. Exclui para incluir novamente.
      If ZBX->(MsSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+"N")) // ZBX_FILIAL+ZBX_NRNFE+ZBX_SERNFE+ZBX_CODPRO+ZBX_LOJPRO+ZBX_STATUS
         While ! ZBX->(Eof()) .And. ;
            ZBX->ZBX_FILIAL+ZBX->ZBX_NRNFE+ZBX->ZBX_SERNFE+ZBX->ZBX_CODPRO+ZBX->ZBX_LOJPRO+ZBX->ZBX_STATUS == ;
            SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+"N"
            
            ZBX->(RecLock("ZBX",.F.))    
            ZBX->(DbDelete())
            ZBX->(MSUnLock())
             
            ZBX->(DBSkip()) 
         EndDo 

      EndIf 

      // Obtem os dados de item da nota de entrada.
      _nQtdLit := 0

      SD1->(DBSetOrder(1))
      SD1->(MSSEEK(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
      While ! SD1->(Eof()) .And. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == ;
                                    SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
         
         _nQtdLit := _nQtdLit + SD1->D1_QUANT  

         SD1->(DBSkip())
      EndDo 

      _cMes    := StrZero(Month(SF1->F1_EMISSAO),2)
      _nI      := aScan(_aMesesTxt, {|x| x[1] = _cMes})
      _cMesTxt := _aMesesTxt[_nI,2]

      // Grava a tabela ZBX
      Begin Transaction 
        ZBX->(RecLock("ZBX",.T.))
        ZBX->ZBX_FILIAL := SF1->F1_FILIAL                                             // Filial do Sistema
        ZBX->ZBX_NRNFE  := SF1->F1_DOC		                                          // Numero da Nota Fiscal
        ZBX->ZBX_SERNFE := SF1->F1_SERIE		                                          // Serie da Nota Fiscal
        ZBX->ZBX_DTEMIS := SF1->F1_EMISSAO	                                          // Data Emissão NFE
        ZBX->ZBX_CODPRO := SF1->F1_FORNECE	                                          // Codigo do Produtor
        ZBX->ZBX_LOJPRO := SF1->F1_LOJA		                                          // Loja do Produtor
        ZBX->ZBX_NOMPRO := Posicione('SA2',1,xFilial('SA2')+SF1->F1_FORNECE+SF1->F1_LOJA,'A2_NOME')	// Nome do Produtor
        ZBX->ZBX_PDFEXT := _cEcod64Ex // Pdf Extrato em ENCODE 64
        ZBX->ZBX_STATUS := "N" 
        ZBX->ZBX_VALTOT := SF1->F1_VALBRUT
        ZBX->ZBX_QTDLIT := _nQtdLit
        ZBX->ZBX_AMREFE := StrZero(Year(SF1->F1_EMISSAO),4)+"-"+StrZero(Month(SF1->F1_EMISSAO),2)
        ZBX->ZBX_DTHORA := StrZero(Year(Date()),4) + "-" + StrZero(Month(Date()),2) + "-" + StrZero(Day(Date()),2) + "T" + Time() + "Z"    // XML da NFE em Encode64
        ZBX->ZBX_OBSERV := "Pagto de " + _cMesTxt
        ZBX->(MSUnLock())

      End Transaction 
      
      If Type("_cEcod64Ex") == "O"
         FreeObj(_cEcod64Ex)
      EndIf 
	   _cEcod64Ex := Nil	 

      // Exclui o PDF do Demonstrativo, após a gravação da tabela ZBX.
      If File(_cDir + _cPdfExtra) // Exclui o PDF do Demonstrativo
         FErase(_cDir + _cPdfExtra)
      EndIf 

      QRYSF1->(DBSkip())
   EndDo 
 
End Sequence 

Return 

/*
===============================================================================================================================
Função-------------: MGL32EVE(_lSchedule)
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2022
Descrição----------: Rotina de Envio de dados dos Extratos via WebService Italac para Sistema Evomilk.
Parametros--------:  _lSchedule = .T. = Rotina rodada em modo automático. .F. = Rotina rotada através de menu.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGL32EVE(_lSchedule)

Local _cEmpWebService
Local _cJSonEnv 
Local _nStart 
Local _nRetry 
Local _cJSonRet
Local _nTimOut	
Local _cRetHttp
Local _cJSoNext, _cJSonGrp
Local _cHoraIni, _cHoraFin, _cMinutos, _nMinutos
Local _nTotRegEnv := 1 // Total de registros para envio.
Local _nI , _oRetJSon, _lResult 
Local _cQry := ""
Local _cTenantid := ""
Local _nIntervalo

Private _cEcod64Ex
Private _cEcod64Nf
Private _cCodEvoMilk :="EVOMKT"

Default _lSchedule := .F.

Begin Sequence 
   // Obtem os dados do servidor Webservice.
   _cEmpWebService := SUPERGETMV('IT_CODWSEV',.F.,_cCodEvoMilk)
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK07) // Link de envio dos Extratos/Demonstrativos.
      If !Empty(AllTrim(ZFM->ZFM_LINK10))
         _cTenantid:= AllTrim(ZFM->ZFM_LINK10)
      EndIf
   Else 
      If ! _lSchedule // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf 

      Break
   EndIf

   If Empty(_cDirJSon)
      If ! _lSchedule // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      EndIf 

      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cModeloEx := U_MGLT032X(_cDirJSon + "extrato_produtores_evomilk.json")

   If Empty(_cModeloEx)
      If ! _lSchedule // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON Capa do PDF de Notas Fiscais na integração Italac x Evomilk.","Atenção",,1) 
      EndIf 

      Break
   EndIf

   If _lSchedule
      _cKey := U_MGLT032T("S") // Obtem o Token de acesso. S=Schedule
   Else 
      _cKey := U_MGLT032T("M") // Obtem o Token de acesso. M=menu
   EndIf 

   If Empty(_cKey)
      If ! _lSchedule // Chamada via menu.   
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Pdfs de Notas fiscais Cancelada.","Atenção",,1)
      EndIf

      Break

   EndIf 
   
   _cHoraIni := Time() // Horario Inicial de Processamento
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Accept: application/json')
   aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )
   aAdd(_aHeadOut,'TENANTID: ' + _cTenantid)

   _cJSoNext := "["
   _cJSonGrp    := ""
   _nI := 1
   _nIntervalo := 5
   
   // Efetua a leitura de dados para integração.
   _cQry := " SELECT ZBX.R_E_C_N_O_ REGZBX, SF1.R_E_C_N_O_  REGSF1 "       // numero_identificador: "06019"
   _cQry += " FROM " + RetSqlName("SF1") + " SF1, " + RetSqlName("ZBX") + " ZBX "  
   _cQry += " WHERE SF1.D_E_L_E_T_ = ' ' AND ZBX.D_E_L_E_T_ = ' ' "
   _cQry += " AND F1_FILIAL  = ZBX_FILIAL "
   _cQry += " AND F1_FORNECE = ZBX_CODPRO "
   _cQry += " AND F1_LOJA    = ZBX_LOJPRO "
   _cQry += " AND F1_DOC     = ZBX_NRNFE "
   _cQry += " AND F1_SERIE   = ZBX_SERNFE "
   _cQry += " AND F1_ESPECIE = 'SPED' "   
   _cQry += " AND ZBX_STATUS = 'N' "  
   _cQry += " AND ZBX_FILIAL = '" + xFilial("ZBX") + "' "

   If Select("QRYZBX") > 0
      QRYZBX->(DBCloseArea())
   EndIf

   MPSysOpenQuery( _cQry , "QRYZBX" )

   DBSelectArea("QRYZBX")

   Count To _nTotRegs

   If ! _lSchedule
      ProcRegua(_nTotRegs)
   EndIf 

   // Inicia o envio dos dados.
   QRYZBX->(DBGoTop())
   While ! QRYZBX->(Eof())
      
      If ! _lSchedule 
         IncProc("Transmitindo os dados dos extratos/demonstrativos...")
      EndIf 
      
      // Calcula o tempo decorrido para obtenção de um novo Token
      _cHoraFin := Time()
      _cMinutos := ElapTime (_cHoraIni , _cHoraFin)
      _nMinutos := Val(SubStr(_cMinutos,4,2))      

      If _nMinutos > _nIntervalo // 5 // 28 // minutos 
         If _lSchedule
            _cKey := U_MGLT032T("S") // Obtem o Token de acesso. S=Schedule
         Else 
            _cKey := U_MGLT032T("M") // Obtem o Token de acesso. M=menu
         EndIf 

         If Empty(_cKey)
            If ! _lSchedule  // Chamada via menu.   
               U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Notas Fiscais cancelada.","Atenção",,1)
            EndIf
   
            Break
         EndIf 
         
         _aHeadOut := {}              
         aAdd(_aHeadOut,'Accept: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) ) 
         aAdd(_aHeadOut,'TENANTID: ' + _cTenantid)

         _cHoraIni := Time()

      EndIf 
      
      // Posiciona os registros das tabelas ZBX E SF1.
      ZBX->(DBGoTo(QRYZBX->REGZBX))
      SF1->(DBGoTo(QRYZBX->REGSF1))

      // Efetua a leitura dos dados e montagem do JSon.
      _cJSonEnv := &(_cModeloEx) 

      _cJSonGrp += If(!Empty(_cJSonGrp),",","") + _cJSonEnv 

      If _nI >= _nTotRegEnv
  
         _cJSoNext += _cJSonGrp + "]"
   
        _cJSoNext := DecodeUTF8(_cJSoNext, "cp1252")

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil 
         _nTimOut	 	:= 120
         
         _cRetHttp    := ''

         _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSoNext , _nTimOut , _aHeadOut , @_cJSonRet ) ) 

         If ! Empty(_cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)             
         EndIf
   
         _cAuxHTTP := Upper(_cRetHttp)  

         _lResult := .F. 
         If ! Empty(_oRetJSon) .And."STATUS" $ _cAuxHTTP .And. _oRetJSon:status == "success"
            _lResult := .T. // _oRetJSon:status
         EndIf 
       
         If _lResult // Integração realizada com sucesso 
            // Grava dados das Notas Fiscais e Demonstrativos para histórico.
            ZBX->(RecLock("ZBX",.F.)) 
            ZBX->ZBX_RETEXT :=  AllTrim(_cRetHttp)    // Retorno da Integração
            ZBX->ZBX_JSONEX := _cJSoNext              // Json de Envio 
            ZBX->ZBX_DTENVE := Date()                 // Data de Envio
            ZBX->ZBX_HRENVE := Time()                 // Hora de Envio
            ZBX->ZBX_STATUS := "A"                    // Status da Integração
            ZBX->(MSUnLock())
            // Comentar este trecho.
            // Atualiza a tabela SF1    
            SF1->(RecLock("SF1", .F.))
            SF1->F1_I_SITEX := "P"	  // Situação Integração 
            SF1->F1_I_DTEEV := Date() // Data de Envio para Evomilk
            SF1->F1_I_HREEV := Time() // Hora de Envio para Evomilk
            SF1->(MSUnLock())
            
         Else 
            // Grava dados das Notas Fiscais e Demonstrativos para histórico.
            ZBX->(RecLock("ZBX",.F.)) 
            ZBX->ZBX_RETEXT :=  AllTrim(_cRetHttp)    // Retorno da Integração
            ZBX->ZBX_JSONEX := _cJSoNext              // Json de Envio 
            ZBX->ZBX_DTENVE := Date()                 // Data de Envio
            ZBX->ZBX_HRENVE := Time()                 // Hora de Envio
            ZBX->ZBX_STATUS := "R"                    // Status da Integração
            ZBX->(MSUnLock())
         EndIf 

         _cJSoNext := "["
         _cJSonGrp := ""
         _nI := 0

      EndIf 
      
      _nI += 1
      
      QRYZBX->(DBSkip())
   EndDo 

   If ! Empty(_cJSonGrp)
      _cJSoNext += _cJSonGrp + "]"

      _cJSoNext := DecodeUTF8(_cJSoNext, "cp1252")

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil 
      _nTimOut	 	:= 120
       
      _cRetHttp    := ''

      _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSoNext , _nTimOut , _aHeadOut , @_cJSonRet ) ) 

      If ! Empty(_cRetHttp)
         //varinfo("WebPage-http ret.", _cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
         FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)             
      EndIf
       
       _cAuxHTTP := Upper(_cRetHttp)  

      _lResult := .F.
      If ! Empty(_oRetJSon) .And. "STATUS" $ _cAuxHTTP .And. _oRetJSon:status = "success" // "status" $ _cRetHttp  
         //_lResult := _oRetJSon:resultado
         _lResult := .T. // _oRetJSon:status
      EndIf 

      If _lResult // Integração realizada com sucesso 
         // Grava dados das Notas Fiscais e Demonstrativos para histórico.
         ZBX->(RecLock("ZBX",.F.)) 
         ZBX->ZBX_RETEXT :=  AllTrim(_cRetHttp)    // Retorno da Integração
         ZBX->ZBX_JSONEX := _cJSoNext              // Json de Envio 
         ZBX->ZBX_DTENVE := Date()                 // Data de Envio
         ZBX->ZBX_HRENVE := Time()                 // Hora de Envio
         ZBX->ZBX_STATUS := "A"                    // Status da Integração
         ZBX->(MSUnLock())
         // Comentar este trecho.
         // Atualiza a tabela SF1    
         SF1->(RecLock("SF1", .F.))
         SF1->F1_I_SITEX := "P"	  // Situação Integração 
         SF1->F1_I_DTEEV := Date() // Data de Enviao para Cia do Leite
         SF1->F1_I_HREEV := Time() // Hora de Envio para Cia do Leite
         SF1->(MSUnLock())
      Else 
         // Grava dados das Notas Fiscais e Demonstrativos para histórico.
         ZBX->(RecLock("ZBX",.F.)) 
         ZBX->ZBX_RETEXT :=  AllTrim(_cRetHttp)    // Retorno da Integração
         ZBX->ZBX_JSONEX := _cJSoNext              // Json de Envio 
         ZBX->ZBX_DTENVE := Date()                 // Data de Envio
         ZBX->ZBX_HRENVE := Time()                 // Hora de Envio
         ZBX->ZBX_STATUS := "R"                    // Status da Integração
         ZBX->(MSUnLock())
      EndIf 
   EndIf 
   
End Sequence 

If Select("QRYZBX") > 0
   QRYZBX->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Função-------------: MGLT32OM
Autor--------------: Julio de Paula Paz
Data da Criacao----: 18/08/2025
Descrição----------: Roda as rotinas selecionadas pelo usuário no menu do fonte AGLT054.
Parametros---------: _cOpcaoM = Opção de menu a ser rodada.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32OM(_cOpcaoM)

Local _aParaux   := {}
Local _aParRet   := {}
Local _cTxtMsg   := ""
Local _cCodUser  := "" 

Private _lHaDadosP := .F. // Indica se há dados dos produtores para Integração.
Private _nTotRegs  := 0
Private _cUnidVinc := SM0->M0_CGC // Unidade na qual os produtores e coletas estão vinculados.
Private _lJaTemAss := .F.

Begin Sequence 

   If _cOpcaoM == "D" //'Gera Arq.Txt Produtores Rejeitados nas Integrações'    
        _cTxtMsg   := "Gera Arq.Txt Produtores Rejeitados nas Integrações'"
   ElseIf _cOpcaoM == "E" // 'Gera Arq.Txt Produtores Aceitos nas Integrações'  
      _cTxtMsg   := "Gera Arq.Txt Produtores Aceitos nas Integrações"
   ElseIf _cOpcaoM == "F" // 'Gera Arq.Txt Coletas Rejeitadas nas Integrações'  
      _cTxtMsg   := "Gera Arq.Txt Coletas Rejeitadas nas Integrações"
   ElseIf _cOpcaoM == "G" // 'Gera Arq.Txt Coletas Aceitas nas Integrações'     
      _cTxtMsg   := "Gera Arq.Txt Coletas Aceitas nas Integrações"
   ElseIf _cOpcaoM == "H" // 'Gera Arq.Txt Notas Fiscais Rejeitadas nas Integrações'     
      _cTxtMsg   := "Gera Arq.Txt Notas Fiscais Rejeitadas nas Integrações"
   ElseIf _cOpcaoM == "I" // 'Gera Arq.Txt Notas Fiscais Aceitas nas Integrações'     
      _cTxtMsg   := "Gera Arq.Txt Notas Fiscais Aceitas nas Integrações"
   ElseIf _cOpcaoM == "J" // 'Gera Arq.Txt Extratos Rejeitados nas Integrações'     
      _cTxtMsg   := "Gera Arq.Txt Extratos Rejeitados nas Integrações"
   ElseIf _cOpcaoM == "K" // 'Gera Arq.Txt Extratos Aceitos nas Integrações'     
      _cTxtMsg   := "Gera Arq.Txt Extratos Aceitos nas Integrações"
   EndIf 

   If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
      _cCodUser := __cUserId
   Else 
      _cCodUser := Space(6)
   EndIf 

   If Empty(_cCodUser)
      _cCodUser := RetCodUsr()
   EndIf 
   
   
   ZZL->( DBSetOrder(3) )
   If ZZL->( DBSeek( xFilial("ZZL") + U_ItKey(_cCodUser,"ZZL_CODUSU")) ) // RetCodUsr()
      lSemAcesso:=!(ZZL->ZZL_GETXTL == "S") .And. _cOpcaoM $ "A/B/C/D/E/F/G/H"    
      If lSemAcesso
          U_ITMsg( "Usuário sem acesso para rodar a opção de menu: [" + _cTxtMsg + "]" , "Atenção!","Para ter acesso a esta opção é necessário solicitar ao TI liberação, no cadastro de Gestão de Usuários Italac. ",1 )
          ZZL->( DBSetOrder(1) )
	       Break           
      EndIf 
      
      lSemAcesso:=!(ZZL->ZZL_ENVPRL == "S") .And. _cOpcaoM = "I"
      If lSemAcesso
         U_ITMsg( "Usuário sem acesso para rodar a opção de menu: [" + _cTxtMsg + "]" , "Atenção!","Para ter acesso a esta opção é necessário solicitar ao TI liberação, no cadastro de Gestão de Usuários Italac. ",1 )
         ZZL->( DBSetOrder(1) )
	      Break   
      EndIf 
   Else 
      ZZL->( DBSetOrder(1) )
      U_ITMsg( "Usuário sem acesso para rodar a opção de menu: [" + _cTxtMsg + "]" , "Atenção!","Para ter acesso a esta opção é necessário solicitar ao TI liberação, no cadastro de Gestão de Usuários Italac. ",1 )
	   Break 
   EndIf
   
   ZZL->( DBSetOrder(1) ) 

   If _cOpcaoM == "D"
      // Gera arquivo Texto com os Dados dos Produtores Rejeitados nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados dos Produtores REJEITADOS nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf
   
      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Produtores Rejeitados"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Produtotes Rejeitados"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Produtores Rejeitados" , @_aParRet )
	      U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	      Break 
	   EndIf
         
      Processa( {|| U_MGLT32RJ(MV_PAR01,MV_PAR02) } , 'Aguarde!' , 'Gerando arquivo texto com Produtores rejeitados...' )

   ElseIf _cOpcaoM == "E"
      // Gera arquivo Texto com os Dados dos Produtores Aceitos nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados dos Produtores ACEITOS nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}

      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Produtores Aceitos"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Produtores Aceitos"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Produtores Aceitos" , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf
         
      Processa( {|| U_MGLT32AC(MV_PAR01,MV_PAR02) } , 'Aguarde!' , 'Gerando arquivo texto com Produtores aceitos...' )

   ElseIf _cOpcaoM == "F"
      // Gera arquivo Texto com os Dados das Coletas Rejeitadas
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados das Coletas rejeitadas nas integrações?","Atenção" , , ,2, 2)
         Break 
      EndIf

      _aParAux := {}
          
      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Coleta Rejeitada "  , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Coleta Rejeitada " , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Coletas Rejeitadas " , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	      Break 
	   EndIf

      Processa( {|| U_MGLT32CL("R") } , 'Aguarde!' , 'Gerando arquivo texto com as Coletas rejeitadas...' )

   ElseIf _cOpcaoM == "G"
      // Gera arquivo Texto com os Dados das Coletas Aceitas
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados das Coletas Aceitas nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}
         
      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Aceite Coleta"  , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Aceite Coleta" , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Coletas Aceitas " , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf

      Processa( {|| U_MGLT32CL("A") } , 'Aguarde!' , 'Gerando arquivo texto com as Coletas aceitas...' )

   ElseIf _cOpcaoM == "H"
      // Gera arquivo Texto com os Dados das Notas Fiscais rejeitadas nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados das Notas Fiscais rejeitadas nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}

      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Notas Fiscais Rejeitadas"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Notas Fiscais Rejeitadas"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Notas Fiscais Rejeitadas" , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf
         
      Processa( {|| U_MGLT32NF(MV_PAR01,MV_PAR02,"R") } , 'Aguarde!' , 'Gerando arquivo texto com Notas Fiscais rejeitadas...' )
   
   ElseIf _cOpcaoM == "I"
      // Gera arquivo Texto com os Dados das Notas Fiscais aceitas nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados das Notas Fiscais aceitas nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}

      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Notas Fiscais Aceitas"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Notas Fiscais Aceitas"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Notas Fiscais Aceitas" , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf
         
      Processa( {|| U_MGLT32NF(MV_PAR01,MV_PAR02,"A") } , 'Aguarde!' , 'Gerando arquivo texto com Notas Fiscais aceitas...' )

   ElseIf _cOpcaoM == "J"
      // Gera arquivo Texto com os Dados dos Extratos/Demonstrativos rejeitados nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados dos Extratos/Demontrativos rejeitados nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}

      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Extratos/Demontrativos rejeitados"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Extratos/Demonstrativos rejeitados"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Extratos/Demonstrativos" , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf
         
      Processa( {|| U_MGLT32EX(MV_PAR01,MV_PAR02,"R") } , 'Aguarde!' , 'Gerando arquivo texto com Extratos/Demonstrativos rejeitados...' )
    
   ElseIf _cOpcaoM == "K"
      // Gera arquivo Texto com os Dados dos Extratos/Demonstrativos Aceitos nas integrações
      If ! U_ITMsg("Confirma a Geração de Arquivo Texto com os dados dos Extratos/Demontrativos Aceitos nas integrações?","Atenção" , , ,2, 2)
         Break
      EndIf

      _aParAux := {}

      MV_PAR01 := Ctod("  /  /  ")
      MV_PAR02 := Ctod("  /  /  ")

      aAdd( _aParAux , { 1 , "De Dt Extratos/Demontrativos aceitos"   , MV_PAR01, "@D", ""	, ""	  , ""          ,050      , .T. } )
      aAdd( _aParAux , { 1 , "Ate Dt Extratos/Demonstrativos aceitos"  , MV_PAR02, "@D", ""	, ""	  , ""          ,050      , .T. } )
         
      aAdd(_aParRet,"MV_PAR01")
      aAdd(_aParRet,"MV_PAR02")

      If !ParamBox( _aParAux , "Geração de Arquivo Texto - Extratos/Demonstrativos" , @_aParRet )
         U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
         Break 
      EndIf
         
      Processa( {|| U_MGLT32EX(MV_PAR01,MV_PAR02,"A") } , 'Aguarde!' , 'Gerando arquivo texto com Extratos/Demonstrativos aceitos...' ) 
   EndIf 

   If _cOpcaoM $ "D/E/F/G/H/I/J/K"
      U_ITMsg( "Arquivos gravados no diretório temporário do usuário. Na pasta: " + AllTrim(GetTempPath()) , "Atenção!","Para acessar esta pasta, digite o comando: %TEMP% no campo de pesquisa da barra de tarefa do Windows.",2 )
   EndIf 

End Sequence 
 
Return 

/*
===============================================================================================================================
Função-------------: MGLT32RJ
Autor--------------: Julio de Paula Paz
Data da Criacao----: 18/08/2025
Descrição----------: Gera Listagem de Produteres rejeitados na integração.
Parametros--------:  _dDataRj = Data de Rejeição para geração do arquivo
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32RJ(_dDataRj,_dDtFimRej)

Local _cDirTXT, _cNomeArq
Local _nI, _nJ
Local _cQry 
Local _oFWriter
Local _aFilProc := {}
Local _cLinha, _cJsonRet, _cJsonEnv
Local _cEnvCiaL, _cIntCol, _cEnvAlt
Local _aSaveArea := FWGetArea()

Begin Sequence 

   ProcRegua(15)

   _cFilIntWS := AllTrim(SUPERGETMV('IT_FILITEV',.F.,"01;"))
   _aFilIntWS := StrTokArr2(_cFilIntWS, ";", .F.)
   _cNomeFilWS := ""
  
   ZZM->(DBSetOrder(1))

   For _nJ := 1 To Len(_aFilIntWS)
       If ZZM->(MsSeek(xFilial("ZZM")+_aFilIntWS[_nJ]))    
          _cNomeFilWS := AllTrim(ZZM->ZZM_DESCRI)
          _cNomeFilWS := StrTran(_cNomeFilWS," ","_")
          _cNomeFilWS := StrTran(_cNomeFilWS,"-","_")
          aAdd(_aFilProc, {ZZM->ZZM_CODIGO,_cNomeFilWS})
       EndIf 
   Next 

   For _nI := 1 To Len(_aFilProc)
       
       IncProc("Gerando arquivo texto da Unidade: " + AllTrim(_aFilProc[_nI,2]))

       _cDirTXT := GetTempPath() 
       _cNomeArq:= "Produtores_Rejeitados_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataRj) + ".csv"

       _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)
   
       If ! _oFWriter:Create()
          U_ITMsg("Erro na criação do arquivo texto para gravação dos dados dos produtores rejeitados na integração.","Atenção",,1) 
          Break 
       EndIf 

       _cQry := " SELECT DISTINCT ZBH.R_E_C_N_O_ AS NRREG, A2_L_ENVEV, A2_L_ENVAT, A2_L_ITCOL "
       _cQry += " FROM " + RetSqlName("ZBH") + " ZBH, " + RetSqlName("SA2") + " SA2 "
       _cQry += " WHERE ZBH.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
       _cQry += " AND ZBH.ZBH_FILIAL = '"+ _aFilProc[_nI,1] + "' "
       _cQry += " AND ZBH.ZBH_WEBINT = 'E' "

       If ! Empty(_dDataRj)
          _cQry += " AND ZBH.ZBH_DTENV  >= '" + DToS(_dDataRj) + "' "
       EndIf 

       If ! Empty(_dDtFimRej)
          _cQry += " AND ZBH.ZBH_DTENV  <= '" + DToS(_dDtFimRej) + "' "
       EndIf 

       _cQry += " AND ZBH.ZBH_STATUS = 'R' "
       _cQry += " AND ZBH.ZBH_CODPRO = SA2.A2_COD "
       _cQry += " AND ZBH.ZBH_LOJPRO = SA2.A2_LOJA "

       If Select("QRYZBH") > 0
          QRYZBH->(DBCloseArea())
       EndIf

       MPSysOpenQuery( _cQry , "QRYZBH" )
       
       DBSelectArea("QRYZBH")
       Count To _nTotRegs

       QRYZBH->(DBGoTop())

       ProcRegua(_nTotRegs)
       
       _oFWriter:Write("CODIGO PRODUTOR;LOJA;NOME;ENVIA_CIA_LEITE;INTEGRA_COLETA;ENVIA_ALTERACAO_CIA_LEITE;JSON RETORNO;JSON ENVIO" + CRLF)

       _nJ := 1 
       While ! QRYZBH->(Eof())
          IncProc("Gerando arquivo texto: "+ StrZero(_nJ,6) + " de " + StrZero(_nTotRegs,6) + "...")
          _nJ += 1

          ZBH->(DBGoTo(QRYZBH->NRREG))

          _cJsonRet := StrTran(ZBH->ZBH_MOTIVO,CRLF,"")
          _cJsonRet := StrTran(_cJsonRet,chr(10),"")
                    
          _cJsonEnv := StrTran(ZBH->ZBH_JSONEN,CRLF,"")
          _cJsonEnv := StrTran(_cJsonEnv,chr(10),"")

          _cEnvCiaL := " "
          _cIntCol  := " "
          _cEnvAlt  := " "
          
          If QRYZBH->A2_L_ENVEV == "S"
             _cEnvCiaL := "SIM"
          ElseIf QRYZBH->A2_L_ENVEV == "N" 
             _cEnvCiaL := "NAO"   
          EndIf 
          
          If QRYZBH->A2_L_ITCOL == "S"
             _cIntCol  := "SIM"
          ElseIf QRYZBH->A2_L_ITCOL == "N"
             _cIntCol  := "NAO"
          EndIf 

          If QRYZBH->A2_L_ENVAT == "S"
             _cEnvAlt  := "SIM"
          ElseIf QRYZBH->A2_L_ENVAT == "N"
             _cEnvAlt  := "NAO"
          EndIf 

          _cLinha   := ZBH->ZBH_CODPRO+ ";" + ZBH->ZBH_LOJPRO + ";" + AllTrim(ZBH->ZBH_NOMPRO) + ";" + _cEnvCiaL + ";" + _cIntCol + ";" + _cEnvAlt + ";" + _cJsonRet+ ";" + _cJsonEnv + CRLF
          _oFWriter:Write(_cLinha)

          QRYZBH->(DBSkip())

       EndDo
       
       //Encerra o arquivo
       _oFWriter:Close()
   
   Next

End Sequence 

If Select("QRYZBH") > 0
   QRYZBH->(DBCloseArea())
EndIf

FWRestArea(_aSaveArea)

Return

/*
===============================================================================================================================
Função-------------: MGLT32AC
Autor--------------: Julio de Paula Paz
Data da Criacao----: 18/08/2025
Descrição----------: Gera Listagem de Produteres rejeitados na integração.
Parametros--------:  _dDataAc = Data de Aceitação para geração do arquivo
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32AC(_dDataAc, _dDtFimAce)

Local _cDirTXT, _cNomeArq
Local _nI, _nJ
Local _cQry 
Local _oFWriter
Local _aFilProc := {}
Local _cLinha, _cJsonRet, _cJsonEnv
Local _cEnvCiaL, _cIntCol, _cEnvAlt
Local _aSaveArea := FWGetArea()

Begin Sequence 

   ProcRegua(15)
   
   _cFilIntWS := AllTrim(SUPERGETMV('IT_FILITEV',.F.,"01;"))
   _aFilIntWS := StrTokArr2(_cFilIntWS, ";", .F.)
   _cNomeFilWS := ""
  
   ZZM->(DBSetOrder(1))

   For _nJ := 1 To Len(_aFilIntWS)
       If ZZM->(MsSeek(xFilial("ZZM")+_aFilIntWS[_nJ]))    
          _cNomeFilWS := AllTrim(ZZM->ZZM_DESCRI)
          _cNomeFilWS := StrTran(_cNomeFilWS," ","_")
          _cNomeFilWS := StrTran(_cNomeFilWS,"-","_")
          aAdd(_aFilProc, {ZZM->ZZM_CODIGO,_cNomeFilWS})
       EndIf 
   Next

   For _nI := 1 To Len(_aFilProc)
       
       IncProc("Gerando arquivo texto da Unidade: " + AllTrim(_aFilProc[_nI,2]))

       _cDirTXT := GetTempPath() 
       
       _cNomeArq:= "Produtores_Aceitos_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataAc) + ".csv"

       _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)
   
       If ! _oFWriter:Create()
          U_ITMsg("Erro na criação do arquivo texto para gravação dos dados dos produtores aceitos na integração.","Atenção",,1) 
          Break 
       EndIf 

       _cQry := " SELECT DISTINCT ZBH.R_E_C_N_O_ AS NRREG, A2_L_ENVEV, A2_L_ENVAT, A2_L_ITCOL "
       _cQry += " FROM " + RetSqlName("ZBH") + " ZBH, " + RetSqlName("SA2") + " SA2 "
       _cQry += " WHERE ZBH.D_E_L_E_T_ = ' ' AND SA2.D_E_L_E_T_ = ' ' "
       _cQry += " AND ZBH.ZBH_FILIAL = '"+ _aFilProc[_nI,1] + "' "
       _cQry += " AND ZBH.ZBH_WEBINT = 'E' "
         
       If ! Empty(_dDataAc)
          _cQry += " AND ZBH.ZBH_DTENV  >= '" + DToS(_dDataAc) + "' "
       EndIf 

       If ! Empty(_dDtFimAce)
          _cQry += " AND ZBH.ZBH_DTENV  <= '" + DToS(_dDtFimAce) + "' "
       EndIf 

       _cQry += " AND ZBH.ZBH_STATUS = 'A' "
       _cQry += " AND ZBH.ZBH_CODPRO = SA2.A2_COD "
       _cQry += " AND ZBH.ZBH_LOJPRO = SA2.A2_LOJA "

       If Select("QRYZBH") > 0
          QRYZBH->(DBCloseArea())
       EndIf

       MPSysOpenQuery( _cQry , "QRYZBH" )
       
       DBSelectArea("QRYZBH")

       Count To _nTotRegs

       QRYZBH->(DBGoTop())

       ProcRegua(_nTotRegs)
       
       _oFWriter:Write("CODIGO PRODUTOR;LOJA;NOME;ENVIA_CIA_LEITE;INTEGRA_COLETA;ENVIA_ALTERACAO_CIA_LEITE;JSON RETORNO;JSON ENVIO" + CRLF)

       _nJ := 1 
       While ! QRYZBH->(Eof())
          IncProc("Gerando arquivo texto: "+ StrZero(_nJ,6) + " de " + StrZero(_nTotRegs,6) + "...")
          _nJ += 1

          ZBH->(DBGoTo(QRYZBH->NRREG))
      
          _cJsonRet := StrTran(ZBH->ZBH_MOTIVO,CRLF,"")
          _cJsonRet := StrTran(_cJsonRet,chr(10),"")
                    
          _cJsonEnv := StrTran(ZBH->ZBH_JSONEN,CRLF,"")
          _cJsonEnv := StrTran(_cJsonEnv,chr(10),"")

          _cEnvCiaL := " "
          _cIntCol  := " "
          _cEnvAlt  := " "
          
          If QRYZBH->A2_L_ENVEV == "S"
             _cEnvCiaL := "SIM"
          ElseIf QRYZBH->A2_L_ENVEV == "N" 
             _cEnvCiaL := "NAO"   
          EndIf 
          
          If QRYZBH->A2_L_ITCOL == "S"
             _cIntCol  := "SIM"
          ElseIf QRYZBH->A2_L_ITCOL == "N"
             _cIntCol  := "NAO"
          EndIf 

          If QRYZBH->A2_L_ENVAT == "S"
             _cEnvAlt  := "SIM"
          ElseIf QRYZBH->A2_L_ENVAT == "N"
             _cEnvAlt  := "NAO"
          EndIf 

          _cLinha   := ZBH->ZBH_CODPRO+ ";" + ZBH->ZBH_LOJPRO + ";" + AllTrim(ZBH->ZBH_NOMPRO) + ";" + _cEnvCiaL + ";" + _cIntCol + ";" + _cEnvAlt + ";" + _cJsonRet+ ";" + _cJsonEnv + CRLF
          _oFWriter:Write(_cLinha)

          QRYZBH->(DBSkip())

       EndDo
       
       //Encerra o arquivo
       _oFWriter:Close()
   
   Next

End Sequence 

If Select("QRYZBH") > 0
   QRYZBH->(DBCloseArea())
EndIf

FWRestArea(_aSaveArea)

Return

/*
===============================================================================================================================
Função-------------: MGLT32CL
Autor--------------: Julio de Paula Paz
Data da Criacao----: 18/08/2025
Descrição----------: Gera arquivo TXT com os dados das Coletas Integradas Aceitas ou Rejeitadas, por filial.
Parametros---------: _cSituacao = Status da Coleta "A" = Aceita / "R" = Rejeitadas
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32CL(_cSituacao)

Local _cQry 
Local _aFilSA2 := {}
Local _aSaveArea := FWGetArea()
Local _nJ

Private _nTotRegs := 0

Default _cSituacao := "R"

Begin Sequence    
   // Gera arquivo TXT com os Dados dos Volumes coletados 
   _cFilIntWS := AllTrim(SUPERGETMV('IT_FILITEV',.F.,"01;"))
   _aFilIntWS := StrTokArr2(_cFilIntWS, ";", .F.)
   _cNomeFilWS := ""
  
   ZZM->(DBSetOrder(1))

   For _nJ := 1 To Len(_aFilIntWS)
       If ZZM->(MsSeek(xFilial("ZZM")+_aFilIntWS[_nJ]))    
          _cNomeFilWS := AllTrim(ZZM->ZZM_DESCRI)
          _cNomeFilWS := StrTran(_cNomeFilWS," ","_")
          _cNomeFilWS := StrTran(_cNomeFilWS,"-","_")
          aAdd(_aFilSA2, {ZZM->ZZM_CODIGO,_cNomeFilWS})
       EndIf 
   Next
   
   _cQry := " SELECT ZBI_FILIAL, ZBI_CODPRO, ZBI_LOJPRO, ZBI.R_E_C_N_O_ REGZBI , SA2.R_E_C_N_O_ REGSA2 "
   _cQry += " FROM " + RetSqlName("SA2") + " SA2, " + RetSqlName("ZBI") + " ZBI "   
   _cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND ZBI.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZBI_CODPRO = A2_COD AND ZBI_LOJPRO = A2_LOJA "
   _cQry += " AND A2_I_CLASS = 'P' "
   _cQry += " AND A2_MSBLQL = '2' "
   _cQry += " AND A2_COD <> '      ' "
   _cQry += " AND ZBI_STATUS = '"+ _cSituacao + "' "
   _cQry += " AND A2_L_ENVEV = 'N' " 
   _cQry += " AND ZBI_WEBINT = 'E' "

   If ! Empty(MV_PAR01)
      _cQry += " AND ZBI_DTENV >= '"+DToS(MV_PAR01)+"' "
   EndIf 

   If ! Empty(MV_PAR02)
      _cQry += " AND ZBI_DTENV <= '"+DToS(MV_PAR02)+"' "
   EndIf 

   _cQry += " ORDER BY ZBI_FILIAL, ZBI_CODPRO, ZBI_LOJPRO " 

    If Select("QRYZBI") > 0
       QRYZBI->(DBCloseArea())
    EndIf

    MPSysOpenQuery( _cQry , "QRYZBI" )
    
    DBSelectArea("QRYZBI")

    QRYZBI->(DBGoTop())
       
    Count to _nTotRegs

    QRYZBI->(DBGoTop())

    Processa( {|| U_MGLT32IC(_aFilSA2,_nTotRegs,_cSituacao) } , 'Aguarde!' , 'Gravando Arquivo Texto das Coletas...' )  
     
    U_ITMsg("Geração de arquivo TXT com os dados das Coletas concluido.","Atenção",,2)

End Sequence 

If Select("QRYZBI") > 0
   QRYZBI->(DBCloseArea())
EndIf

FWRestArea(_aSaveArea)

Return 

/*
===============================================================================================================================
Função-------------: MGLT32IC
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/06/2023
Descrição----------: Rotina de geração de arquivo TxT das Coletas das Associações Rejeitadas.
Parametros--------:  Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32IC(_aFilSA2,_nTotRegs,_cSituacao)

Local _cDirTXT, _cNomeArq
Local _cDados
Local _nJ 
Local _cRetApp

Default _cSituacao := "R"

Begin Sequence 

   ProcRegua(_nTotRegs)

   _cDirTXT := GetTempPath() 
   If _cSituacao == "R"
      _cNomeArq:= "Dados_das_Coletas_Rejeitadas_nas_Integrações" + DToS(Date()) + ".csv"
   Else
      _cNomeArq:= "Dados_das_Coletas_Aceitas_nas_Integrações" + DToS(Date()) + ".csv"
   EndIf 

   _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)
   
   If ! _oFWriter:Create()
      U_ITMsg("Erro na criação do arquivo texto para gravação dos dados das coletaas Integradas.","Atenção",,1) 
      Break 
   EndIf 

   _oFWriter:Write("UNIDADE;MATRICULA;CPF;NOME;RETORNO_APP;JSON_ENVIO;" + CRLF)
   
   QRYZBI->(DBGoTop())
   
   _nJ := 1

   _oFWriter:Write("[")

   While ! QRYZBI->(Eof())
      
      IncProc("Gerando arquivo texto: "+ StrZero(_nJ,6) + " de " + StrZero(_nTotRegs,6) + "...")
      _nJ += 1
 
      SA2->(DBGoTo(QRYZBI->REGSA2))
      ZBI->(DBGoTo(QRYZBI->REGZBI))

      // Efetua a leitura dos dados e montagem do JSon.
      _nI := aScan(_aFilSA2,{|x| x[1] == QRYZBI->ZBI_FILIAL})
      _cDados := _aFilSA2[_nI,2] + ";" 
      _cDados += SA2->A2_COD + "-" + SA2->A2_LOJA+";"
      _cDados += AllTrim(SA2->A2_CGC) +";"                  
      _cDados += AllTrim(SA2->A2_L_NATRA) + ";" 
      _cRetApp := StrTran(ZBI->ZBI_MOTIVO,Char(10)," ")
      _cDados += AllTrim(_cRetApp) + ";"
      _cDados += AllTrim(ZBI->ZBI_JSONEN)
      _cDados += CRLF  
              
      _oFWriter:Write(_cDados)

      QRYZBI->(DBSkip())
   EndDo 
   
   _oFWriter:Write("]")

   //Encerra o arquivo
   _oFWriter:Close()

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: MGLT32NF
Autor--------------: Julio de Paula Paz
Data da Criacao----: 19/08/2025
Descrição----------: Gera Listagem de Notas Fiscais Aceitas ou Rejeitados na integração em CSV.
Parametros--------:  _dDataRj   = Data Inicial da Rejeição / Aceite
                     _dDtFimRej = Data Final da rejeição / Aceite 
                     _cStatus   = A = Integrações Aceitas
                                  R = Integrações Rejeitadas
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32NF(_dDataRj,_dDtFimRej,_cStatus)

Local _cDirTXT, _cNomeArq
Local _nI, _nJ
Local _cQry 
Local _oFWriter
Local _aFilProc := {}
Local _cLinha, _cJsonRet, _cJsonEnv

Local _aSaveArea := FWGetArea()

Begin Sequence 

   ProcRegua(15)

   _cFilIntWS := AllTrim(SUPERGETMV('IT_FILITEV',.F.,"01;"))
   _aFilIntWS := StrTokArr2(_cFilIntWS, ";", .F.) 
   _cNomeFilWS := ""
  
   ZZM->(DBSetOrder(1))

   For _nJ := 1 To Len(_aFilIntWS)
       If ZZM->(MsSeek(xFilial("ZZM")+_aFilIntWS[_nJ]))    
          _cNomeFilWS := AllTrim(ZZM->ZZM_DESCRI)
          _cNomeFilWS := StrTran(_cNomeFilWS," ","_")
          _cNomeFilWS := StrTran(_cNomeFilWS,"-","_")
          aAdd(_aFilProc, {ZZM->ZZM_CODIGO,_cNomeFilWS})
       EndIf 
   Next 

   For _nI := 1 To Len(_aFilProc)
       
       IncProc("Gerando arquivo texto da Unidade: " + AllTrim(_aFilProc[_nI,2]))

       _cDirTXT := GetTempPath() 

       If _cStatus == "R"
          _cNomeArq:= "Notas_Fiscais_Rejeitados_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataRj) + ".csv"
       Else 
          _cNomeArq:= "Notas_Fiscais_Aceitas_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataRj) + ".csv"
       EndIf 

       _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)
   
       If ! _oFWriter:Create()
          U_ITMsg("Erro na criação do arquivo texto para gravação dos dados das notas fiscais rejeitados na integração.","Atenção",,1) 
          Break 
       EndIf 

       _cQry := " SELECT DISTINCT ZBV_FILIAL, ZBV_CODPRO, ZBV_LOJPRO ,  ZBV.R_E_C_N_O_ AS NRREG "
       _cQry += " FROM " + RetSqlName("ZBV") + " ZBV "
       _cQry += " WHERE ZBV.D_E_L_E_T_ = ' ' "
       _cQry += " AND ZBV.ZBV_FILIAL = '"+ _aFilProc[_nI,1] + "' "
       
       If ! Empty(_dDataRj)
          _cQry += " AND ZBV.ZBV_DTENVN  >= '" + DToS(_dDataRj) + "' "
       EndIf 

       If ! Empty(_dDtFimRej)
          _cQry += " AND ZBV.ZBV_DTENVN  <= '" + DToS(_dDtFimRej) + "' "
       EndIf 

       _cQry += " AND ZBV.ZBV_STATUS = '"+ _cStatus + "' "

       _cQry += " ORDER BY ZBV_FILIAL, ZBV_CODPRO, ZBV_LOJPRO "

       If Select("QRYTZBV") > 0
          QRYTZBV->(DBCloseArea())
       EndIf

       MPSysOpenQuery( _cQry , "QRYTZBV" )
       
       DBSelectArea("QRYTZBV")
       Count To _nTotRegs

       QRYTZBV->(DBGoTop())

       ProcRegua(_nTotRegs)
       
       _oFWriter:Write("CODIGO PRODUTOR;LOJA;NOME; NOTA FISCAL;SERIE;JSON RETORNO;JSON ENVIO" + CRLF)

       _nJ := 1 
       While ! QRYTZBV->(Eof())
          IncProc("Gerando arquivo texto: "+ StrZero(_nJ,6) + " de " + StrZero(_nTotRegs,6) + "...")
          _nJ += 1

          ZBV->(DBGoTo(QRYTZBV->NRREG))

          _cJsonRet := StrTran(ZBV->ZBV_RETNFE,CRLF,"")
          _cJsonRet := StrTran(_cJsonRet,chr(10),"")
                    
          _cJsonEnv := StrTran(ZBV->ZBV_JSONNF,CRLF,"")
          _cJsonEnv := StrTran(_cJsonEnv,chr(10),"")

          _cLinha   := ZBV->ZBV_CODPRO+ ";" + ZBV->ZBV_LOJPRO + ";" + AllTrim(ZBV->ZBV_NOMPRO) + ";" + ZBV->ZBV_NRNFE + ";" + ZBV->ZBV_SERNFE + ";" + _cJsonRet+ ";" + _cJsonEnv + CRLF
          _oFWriter:Write(_cLinha)

          QRYTZBV->(DBSkip())

       EndDo
       
       //Encerra o arquivo
       _oFWriter:Close()
   
   Next

End Sequence 

If Select("QRYTZBV") > 0
   QRYTZBV->(DBCloseArea())
EndIf

FWRestArea(_aSaveArea)

Return

/*
===============================================================================================================================
Função-------------: MGLT32EX
Autor--------------: Julio de Paula Paz
Data da Criacao----: 19/08/2025
Descrição----------: Gera Listagem de Notas Fiscais Aceitas ou Rejeitados na integração em CSV.
Parametros--------:  _dDataRj   = Data Inicial da Rejeição / Aceite
                     _dDtFimRej = Data Final da rejeição / Aceite 
                     _cStatus   = A = Integrações Aceitas
                                  R = Integrações Rejeitadas
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MGLT32EX(_dDataRj,_dDtFimRej,_cStatus)

Local _cDirTXT, _cNomeArq
Local _nI, _nJ
Local _cQry 
Local _oFWriter
Local _aFilProc := {}
Local _cLinha, _cJsonRet, _cJsonEnv

Local _aSaveArea := FWGetArea()

Begin Sequence 

   ProcRegua(15)

   _cFilIntWS := AllTrim(SUPERGETMV('IT_FILITEV',.F.,"01;"))
   _aFilIntWS := StrTokArr2(_cFilIntWS, ";", .F.)
   _cNomeFilWS := ""
  
   ZZM->(DBSetOrder(1))

   For _nJ := 1 To Len(_aFilIntWS)
       If ZZM->(MsSeek(xFilial("ZZM")+_aFilIntWS[_nJ]))    
          _cNomeFilWS := AllTrim(ZZM->ZZM_DESCRI)
          _cNomeFilWS := StrTran(_cNomeFilWS," ","_")
          _cNomeFilWS := StrTran(_cNomeFilWS,"-","_")
          aAdd(_aFilProc, {ZZM->ZZM_CODIGO,_cNomeFilWS})
       EndIf 
   Next 

   For _nI := 1 To Len(_aFilProc)
       
       IncProc("Gerando arquivo texto da Unidade: " + AllTrim(_aFilProc[_nI,2]))

       _cDirTXT := GetTempPath() 

       If _cStatus == "R"
          _cNomeArq:= "Extratos_Demonstrativos_Rejeitados_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataRj) + ".csv"
       Else 
          _cNomeArq:= "Extratos_Demonstrativos_Aceitos_na_Integracao_Unidade_" + _aFilProc[_nI,2] + "_Data_" + DToS(_dDataRj) + ".csv"
       EndIf 


       _oFWriter := FWFileWriter():New(_cDirTXT + _cNomeArq , .T.)
   
       If ! _oFWriter:Create()
          U_ITMsg("Erro na criação do arquivo texto para gravação dos dados das notas fiscais rejeitados na integração.","Atenção",,1) 
          Break 
       EndIf 

       _cQry := " SELECT DISTINCT ZBX_FILIAL, ZBX_CODPRO, ZBX_LOJPRO ,  ZBX.R_E_C_N_O_ AS NRREG "
       _cQry += " FROM " + RetSqlName("ZBX") + " ZBX "
       _cQry += " WHERE ZBX.D_E_L_E_T_ = ' ' "
       _cQry += " AND ZBX.ZBX_FILIAL = '"+ _aFilProc[_nI,1] + "' "
       
       If ! Empty(_dDataRj)
          _cQry += " AND ZBX.ZBX_DTENVE  >= '" + DToS(_dDataRj) + "' "
       EndIf 

       If ! Empty(_dDtFimRej)
          _cQry += " AND ZBX.ZBX_DTENVE  <= '" + DToS(_dDtFimRej) + "' "
       EndIf 

       _cQry += " AND ZBX.ZBX_STATUS = '"+ _cStatus + "' "

       _cQry += " ORDER BY ZBX_FILIAL, ZBX_CODPRO, ZBX_LOJPRO "

       If Select("QRYTZBX") > 0
          QRYTZBX->(DBCloseArea())
       EndIf

       MPSysOpenQuery( _cQry , "QRYTZBX" )
       
       DBSelectArea("QRYTZBX")
       Count To _nTotRegs

       QRYTZBX->(DBGoTop())

       ProcRegua(_nTotRegs)
       
       _oFWriter:Write("CODIGO PRODUTOR;LOJA;NOME;OBSERVACAO;JSON RETORNO;JSON ENVIO" + CRLF)

       _nJ := 1 
       While ! QRYTZBX->(Eof())
          IncProc("Gerando arquivo texto: "+ StrZero(_nJ,6) + " de " + StrZero(_nTotRegs,6) + "...")
          _nJ += 1

          ZBX->(DBGoTo(QRYTZBX->NRREG))

          _cJsonRet := StrTran(ZBX->ZBX_RETEXT,CRLF,"")
          _cJsonRet := StrTran(_cJsonRet,chr(10),"")
                    
          _cJsonEnv := StrTran(ZBX->ZBX_JSONEX,CRLF,"")
          _cJsonEnv := StrTran(_cJsonEnv,chr(10),"")

          _cLinha   := ZBX->ZBX_CODPRO+ ";" + ZBX->ZBX_LOJPRO + ";" + AllTrim(ZBX->ZBX_NOMPRO) + ";" + AllTrim(ZBX->ZBX_OBSERV) + ";" + _cJsonRet+ ";" + _cJsonEnv + CRLF
          _oFWriter:Write(_cLinha)

          QRYTZBX->(DBSkip())

       EndDo
       
       //Encerra o arquivo
       _oFWriter:Close()
   
   Next

End Sequence 

If Select("QRYTZBX") > 0
   QRYTZBX->(DBCloseArea())
EndIf

FWRestArea(_aSaveArea)

Return
