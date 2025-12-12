#Include "report.ch"
#Include "TOTVS.ch"
#Include "rptdef.ch"
#Include "TBICONN.CH"
  
Static _aCargaTot := {}
Static _aLocEnt := {}
Static _aFilial   := FwLoadSM0()

/*
===============================================================================================================================
Programa----------: ROMS002
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Relacao de pedidos pendentes
Parametros--------: _lScheduller := .T. = Rotina rodando via Scheduller
                                    .F. = Rotina rodando manualmente
                    _cEmailEnv   := E-mail de envio do relatório. 
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS002(_lScheduller, _cEmailEnv)

Local _nDiasEmiss  := SuperGetMV("IT_DIASR21",.T.,30)
Local _nDiasEntr   := SuperGetMV("IT_DIASR22",.T.,60)    
Local _cCodBrokers := SuperGetMV("IT_BROKER2",.T.,"001622;001668;")

SET DATE FORMAT TO "DD/MM/YYYY"

Private oBrkCli,oBrkPed,oBrkSup,oBrkCoord,oBrkFil
Private oReport   
Private oSC5FIL_1,oSC5_1,oSC5A_1,oSC5B_1 
Private oSC5FIL_2,oSC5_2,oSC5A_2
Private oSC5FIL_3,oSC5_3,oSC5A_3,oSC5S_3
Private oSC5FIL_4,oSC5_4,oSC5S_4,oSC5A_4
Private oSC5FIL_5,oSC5_5,oSC5S_5,oSC5A_5
Private oSC5FIL_6,oSC5_6   
Private cPerg := "OMS002B"
Private QRY1,QRY2,QRY3,QRY4,QRY5,QRY6//,QRY7
Private aOrd := {"1-Coordenador"  ,; // Analitico
                 "2-Data Entrega" ,; // Analitico e Sintetico 
                 "3-Produto"      ,; // Analitico e Sintetico 
                 "4-Rede"         ,; // Analitico e Sintetico 
                 "5-Municipio"    ,; // Analitico e Sintetico 
                 "6-Prod. Resumido"} // Sintetico
Private cVendedor  := ""
Private cCoordenador:= ""
Private cSupervisor := ""
Private cMunicipio := " "
Private cNomeFil   := " "
Private cDTentrega := ""
Private cRede      := " " 
Private cDataEntr  := " "   
Private cProduto   := " "
Private _aItalac_F3:={}     //    1           2         3                        4                            5            6             7         8               9         10             11        12
Private _nTQtdPallets := 0
Private _nTQtdPalItem := 0
Private _cJustificativas:=""//Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
Private _cClassEnt   := ""//A1_I_CLABC
Private _cAlias := GetNextAlias()

Default _lScheduller := .F. , _cEmailEnv := ""

_aCargaTot := {}

MV_PAR37 := ""
_cCombo := Getsx3cache("B1_I_BIMIX","X3_CBOX")
_cCombo := StrTran(_cCombo,"=","-")
_aDados := StrTokArr(_cCombo, ';')
//Italac_F3:={}         1           2         3                        4                            5            6             7         8        9         10       11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave              , nCpoDesc                   ,bCondTab , cTitAux      , nTamChv , aDados  , nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR37",           ,                        ,                             ,          ,"Grupo Mix",2       ,_aDados  ,Len(_aDados)} )

If _lScheduller
   Pergunte(cPerg,.F.)
Else 
   If !Pergunte(cPerg,.T.)
      Return .F.
   EndIf
   ROMS002P0()
   MV_PAR32 := 1  //FIXA APARECER TODOS OS CAMPOS 
EndIf
  
If _lScheduller
   MV_PAR01 := Space(75)             // Filiais
   MV_PAR02 := Date() - _nDiasEmiss  // Data Emissão Inicial
   MV_PAR03 := Date() + _nDiasEmiss  // Data Emissão Final
   MV_PAR04 := Date() - _nDiasEntr   // Data Entrega Incial
   MV_PAR05 := Date() + _nDiasEntr   // Data Entrega Final
   MV_PAR06 := Space(15)             // Produto de:
   MV_PAR07 := "ZZZZZZZZZZZZZZZ"     // Produto até:
   MV_PAR08 := Space(6)              // Cliente de 
   MV_PAR09 := Space(4)              // Loja de
   MV_PAR10 := "ZZZZZZ"              // Cliente Ate
   MV_PAR11 := "ZZZZ"                // Loja Até
   MV_PAR12 := Space(6)              // Rede
   MV_PAR13 := Space(2)              // Estado
   MV_PAR14 := Space(10)             // Municipio
   MV_PAR15 := _cCodBrokers          // Vendedor / Brokers
   MV_PAR16 := Space(6)              // Supervisor
   MV_PAR17 := Space(6)              // Grupo de produto
   MV_PAR18 := Space(6)              // Produto nivel 2
   MV_PAR19 := Space(6)              // Produto nivel 3
   MV_PAR20 := Space(6)              // Produto nivel 4
   MV_PAR21 := 2                     // 1 = Relatório Sintético / 2 = Relatório Analítico 
   MV_PAR22 := 3                     // Status = 3 = Todos
   MV_PAR23 := 3                     // Bloqueio = 5 = Todos
   MV_PAR24 := Space(8)              // Usuário
   MV_PAR25 := Space(10)             // CFOP
   MV_PAR26 := Space(10)             // Armazém 
   MV_PAR27 := Space(10)             // Subgrupo de Produtos
   MV_PAR28 := 0                     // Peso de
   MV_PAR29 := 9999999.9999          // Peso até
   MV_PAR30 := Space(10)             // Tipo de Carga    
   MV_PAR31 := Space(10)             // Tipo de Agenda
   MV_PAR32 := 1                     // Campos novos = 1 = Sim
   MV_PAR33 := Space(10)             // Situação do Pedido de Vendas
   MV_PAR34 := Space(6)              // Programadção de Entrega
   MV_PAR35 := 2                     // Operação trianagular filtra
   MV_PAR36 := 4//Space(10)          // Classe do cliente.
   MV_PAR37 := Space(10)             // Grupo Mix
   MV_PAR38 := Space(10)             // GERENTE
   MV_PAR39 := ""                    // Dt Liberacao de 
   MV_PAR40 := ""                    // Dt Liberacao ate
   MV_PAR41 := Space(6)              // Código do Evento Comercial
   MV_PAR42	:= CTOD("")              // De Faturamento?               
   MV_PAR43	:= CTOD("")              // Ate Faturamento?              
   MV_PAR44	:= 2                     // Bloq. de carregamentro p/ Saldo ? 1-SIM, 2-NÃO, 3-Ambos
EndIf 

nMV_PAR21Salva:=MV_PAR21//ANALITICO / SINTETICO
nMV_PAR32Salva:=MV_PAR32//Campos novos sim ou não

SB1->(DBSetOrder(1))

DEFINE REPORT oReport NAME "ROMS002" TITLE "Relação de Pedidos" PARAMETER cPerg ACTION {|oReport| ROMS002MI(oReport)} 

//Seta Padrao de impressao Paisagem.
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)
If _lScheduller 
   oReport:nRemoteType := NO_REMOTE        // FORMA DE GERAÇÃO DO RELATÓRIO  
   oReport:nDevice     := 8                // ENVIO DE .PDF VIA E-MAIL
   oReport:cFile       := "ROMS002"
   oReport:cEmail      :=  _cEmailEnv
   oReport:SetPreview(.F.)
EndIf 


//Define secoes para PRIMEIRA ORDEM - COORDENADOR (1) - ORDEM 01
//Secao Filial
DEFINE Section oSC5FIL_1 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL"  OF oSC5FIL_1 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"     OF oSC5FIL_1 ALIAS "" BLOCK{|| QRY1->M0_FILIAL /*FWFilialName(,QRY1->C6_FILIAL)*/} TITLE "Filial" SIZE 20

oSC5FIL_1:OnPrintLine({|| cNomeFil := QRY1->C6_FILIAL  + " -  " + QRY1->M0_FILIAL /*FWFilialName(,QRY1->C6_FILIAL)*/  })
oSC5FIL_1:SetTotalText({|| "SUBTOTAL FILIAL: " + cNomeFil})                                                         
oSC5FIL_1:Disable()

DEFINE Section oSC5_1 OF oSC5FIL_1 TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"
DEFINE CELL NAME "C5_VEND2"   OF oSC5_1 ALIAS "SC5" TITLE "Coordenador"
DEFINE CELL NAME "C5_I_V2NOM"	OF oSC5_1 ALIAS "SC5" TITLE "Nome"
oSC5_1:SetTotalText({|| "SUBTOTAL COORDENADOR: " + QRY1->C5_I_V2NOM })  
oSC5_1:Disable()
DEFINE BREAK oBrkCoord OF oSC5_1 WHEN oSC5_1:Cell("C5_VEND2") TITLE {|| "SUBTOTAL COORDENADOR: " + cCoordenador}

//Define quebra para filial

//Secao Vendedor - SubSecao da Secao SC5_1
DEFINE Section oSC5A_1 OF oSC5_1 TITLE "Vendedor" TABLES "SA3"
DEFINE CELL NAME "C5_VEND1"     OF oSC5A_1 ALIAS "SC5" TITLE "Vendedor"
DEFINE CELL NAME "A3_NOME"      OF oSC5A_1 ALIAS "SA3"
DEFINE CELL NAME "A3_TIPO"      OF oSC5A_1 ALIAS "SA3" TITLE "Tipo Vendedor" Block {|| If(QRY1->A3_TIPO=="E","Externo","Interno")} SIZE 14
DEFINE CELL NAME "C5_VEND3"     OF oSC5A_1 ALIAS "SC5" TITLE "Gerente"
DEFINE CELL NAME "C5_I_V3NOM"   OF oSC5A_1 ALIAS "SC5" TITLE "Nome"
DEFINE CELL NAME "WK_REGGERE"   OF oSC5A_1 ALIAS "ZAM" TITLE "Região do Gerente" Block {|| Tabela("ZC",QRY1->ZAM_REGCOD,.F.)} SIZE 20
    
oSC5A_1:SetTotalInLine(.F.)
oSC5A_1:SetTotalText({||"SUBTOTAL VENDEDOR: " + cVendedor  })
oSC5A_1:OnPrintLine({|| cVendedor    := QRY1->C5_VEND1 + " - " + QRY1->C5_I_V1NOM,;
                        cSupervisor  := QRY1->C5_VEND4 + " - " + QRY1->A32_NOME,;
                        cCoordenador := QRY1->C5_VEND2 + " - " + QRY1->C5_I_V2NOM,;
                    AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSC5A_1:Disable()

//Secao Detalhes - SubSecao da Secao SC5A_1
DEFINE Section oSC5B_1 OF oSC5A_1 TITLE "Coordenador" TABLES "SC5","SB1","SA1" 
DEFINE CELL NAME "C5_NUM"        OF oSC5B_1 ALIAS "SC5" TITLE "Pedido" SIZE 8  
DEFINE CELL NAME "C6_LOCAL"      OF oSC5B_1 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "C5_I_IDPED"    OF oSC5B_1 ALIAS "SC5" TITLE "Pedido Portal"
DEFINE CELL NAME "CPB		"     OF oSC5B_1 ALIAS ""	  TITLE "Código Pedido Broker" BLOCK {|| QRY1->ZW_PEDIMPO }
DEFINE CELL NAME "C5_I_OPER"     OF oSC5B_1 ALIAS "SC5" TITLE "Tp Operacao"
DEFINE CELL NAME "C5_I_PEVIN"    OF oSC5B_1 ALIAS "SC5" TITLE "PV Vinculado" SIZE 8
DEFINE CELL NAME "C6_CLI"        OF oSC5B_1 ALIAS "SC6" BLOCK {|| QRY1->C6_CLI  }
DEFINE CELL NAME "C6_LOJA"       OF oSC5B_1 ALIAS "SC6" BLOCK {|| QRY1->C6_LOJA  }
DEFINE CELL NAME "A1_NOME"       OF oSC5B_1 ALIAS "SA1" TITLE "Razão Social"  SIZE 27 BLOCK {|| QRY1->C5_I_NOME  }
DEFINE CELL NAME "A1_NREDUZ"     OF oSC5B_1 ALIAS "SA1" TITLE "Nome Fantasia" SIZE 27 BLOCK {|| QRY1->C5_I_FANTA  }
DEFINE CELL NAME "A1_I_GRDES"    OF oSC5B_1 ALIAS "SA1" TITLE "Grupo Cliente" SIZE 30  // A1_I_GRCLI
DEFINE CELL NAME "ACY_DESCRI"    OF oSC5B_1 ALIAS "ACY" TITLE "Rede"          SIZE 27
DEFINE CELL NAME "A1_CGC"        OF oSC5B_1 ALIAS "SC6"
DEFINE CELL NAME "C5_EMISSAO"    OF oSC5B_1 ALIAS "SC5" TITLE "Emissao do Pedido" 
DEFINE CELL NAME "A1_MUN"        OF oSC5B_1 ALIAS "SA1" TITLE "Municipio" SIZE 22 BLOCK {|| AllTrim(QRY1->A1_MUN)}
DEFINE CELL NAME "A1_EST"        OF oSC5B_1 ALIAS "SA1" TITLE "UF" SIZE 5 BLOCK {|| AllTrim(QRY1->A1_EST)}
DEFINE CELL NAME "BAIRRO"        OF oSC5B_1 ALIAS "SA1" TITLE "Bairro" SIZE 50 BLOCK {|| AllTrim(QRY1->A1_BAIRRO) }
DEFINE CELL NAME "CEP"           OF oSC5B_1 ALIAS "SA1" TITLE "Cep"    SIZE 50 BLOCK {|| AllTrim(QRY1->A1_CEP) }
DEFINE CELL NAME "B1_I_DESCD"   OF oSC5B_1 ALIAS "SB1" TITLE "Descricao" SIZE 50 BLOCK {|| If (!Empty(QRY1->C6_I_DQESP),QRY1->C6_I_DQESP,QRY1->B1_I_DESCD)}
DEFINE CELL NAME "BM_DESC"      OF oSC5B_1 ALIAS "SBM" TITLE "Grupo de Produto" SIZE 27
DEFINE CELL NAME "C5_I_DTENT"   OF oSC5B_1 ALIAS "SC6" TITLE "Entrega" 
DEFINE CELL NAME "C5_I_AGEND"   OF oSC5B_1 ALIAS "SC5" TITLE "Tp Entrega" 	BLOCK {|| U_TipoEntrega( QRY1->C5_I_AGEND)} SIZE 14
DEFINE CELL NAME "C6_QTDVEN"    OF oSC5B_1 ALIAS "SC6" BLOCK {|| (QRY1->C6_QTDVEN - QRY1->D2_QTDEDEV) } PICTURE "@E 999,999,999,999.99"  SIZE 14 //PICTURE "@E 999,999,999,999.99" SIZE 14  
DEFINE CELL NAME "C6_UM"        OF oSC5B_1 ALIAS "SC6" TITLE "Un.M" SIZE 5
DEFINE CELL NAME "C6_UNSVENTOT" OF oSC5B_1 ALIAS "SC6" PICTURE "@E 999,999,999.99" TITLE "Qtd Ven 2UM Total" SIZE 14//NOVO 1
DEFINE CELL NAME "C6_UNSVEN"    OF oSC5B_1 ALIAS "SC6" BLOCK {|| (QRY1->C6_UNSVEN - QRY1->D1_QTSEGUM) } PICTURE "@E 999,999,999,999.99"  SIZE 14 //PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"     OF oSC5B_1 ALIAS "SC6" TITLE "Seg.UM" SIZE 6 
DEFINE CELL NAME "C6_PRCVEN"    OF oSC5B_1 ALIAS "SC6" PICTURE "@E 999,999,999.9999" 
DEFINE CELL NAME "C6_PRCNET"    OF oSC5B_1 ALIAS "SC6" PICTURE "@E 999,999.9999"  TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_I_VLTAB"   OF oSC5B_1 ALIAS "SC6" TITLE "Preco Tab" PICTURE "@E 99,999.99" 
DEFINE CELL NAME "C6_I_FXPES"   OF oSC5B_1 ALIAS "SC6" TITLE "Faixa Peso" SIZE 9 
DEFINE CELL NAME "VLRPENDEN"    OF oSC5B_1 ALIAS ""    TITLE "Valor Total" BLOCK {|| (QRY1->C6_QTDVEN * QRY1->C6_PRCVEN) - QRY1->D2_VALDEV } PICTURE "@E 999,999,999,999.99"  SIZE 14 
DEFINE CELL NAME "C5_I_PESBR"   OF oSC5B_1 ALIAS ""    PICTURE "@E 999,999,999,999.99" SIZE 14  TITLE "Peso Bruto Total(KG)"//NOVO 2
DEFINE CELL NAME "PESTOTAL"     OF oSC5B_1 ALIAS ""    PICTURE "@E 999,999,999,999.99" SIZE 14  TITLE "Peso Bruto(KG)"
DEFINE CELL NAME "C6_PEDCLI"    OF oSC5B_1 ALIAS "SC6" TITLE "Ped.Cli" SIZE 9
DEFINE CELL NAME "CARGAGERAL"   OF oSC5B_1 ALIAS ""    TITLE "Carga Total Ped"  	BLOCK {|| ROMS2CG(QRY1->C5_FILIAL,QRY1->C5_NUM) } SIZE 50//NOVO 3
DEFINE CELL NAME "CARGATOTAL"   OF oSC5B_1 ALIAS ""    TITLE "Carga Total Item" 	BLOCK {|| ROMS002CT(QRY1->B1_COD,QRY1->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "B1_I_CXPAL"	  OF oSC5B_1 ALIAS "SB1" TITLE "Qtde por Pallet"  	SIZE 40//NOVO 4

If MV_PAR21 = 2//ANALITICO 
    DEFINE CELL NAME "VEICULO"    OF oSC5B_1 ALIAS "" 		TITLE "Veículo Pedido"  			BLOCK {|| ROMS2VEI() } SIZE 20 
    DEFINE CELL NAME "VEICITEM"   OF oSC5B_1 ALIAS "" 		TITLE "Veículo Item"  				BLOCK {|| ROMS2VIT() } SIZE 20 
EndIf

DEFINE CELL NAME "C5_I_TIPCA" OF oSC5B_1 ALIAS "SC5" TITLE "Tp Carga" 	   SIZE 8
DEFINE CELL NAME "C5_I_SENHA" OF oSC5B_1 ALIAS "SC5" TITLE "Senha" 		   SIZE 14
DEFINE CELL NAME "C5_I_HOREN" OF oSC5B_1 ALIAS "SC5" TITLE "Hr. Receb" 	   SIZE 30
DEFINE CELL NAME "C5_I_DOCA"  OF oSC5B_1 ALIAS "SC5" TITLE "Doca" 		   SIZE 8
DEFINE CELL NAME "C5_I_CHAPA" OF oSC5B_1 ALIAS "SC5" TITLE "Qtd Chapa" 	   SIZE 8
DEFINE CELL NAME "C5_I_CHPCL" OF oSC5B_1 ALIAS "SC5" TITLE "Utl Chp Cli" 	SIZE 8
DEFINE CELL NAME "C5_I_OBPED" OF oSC5B_1 ALIAS "SC5" TITLE "Obs Pedido" 	SIZE 30
DEFINE CELL NAME "C5_MENNOTA" OF oSC5B_1 ALIAS "SC5" TITLE "Obs Nota" 	   SIZE 30
DEFINE CELL NAME "C5_I_OPTRI" OF oSC5B_1 ALIAS "SC5" TITLE "Tp PV Op Tri?" 
DEFINE CELL NAME "C5_I_PVREM" OF oSC5B_1 ALIAS "SC5" TITLE "PV Remessa"    BLOCK {|| IIf(QRY1->C5_I_TRCNF=="S" .And. QRY1->C5_I_OPER == "42",QRY1->C5_NUM,QRY1->C5_I_PVREM) }
DEFINE CELL NAME "C5_I_PVFAT" OF oSC5B_1 ALIAS "SC5" TITLE "PV Faturament" BLOCK {|| IIf(QRY1->C5_I_TRCNF=="S" .And. QRY1->C5_I_OPER == "05",QRY1->C5_NUM,QRY1->C5_I_PVFAT) }	
DEFINE CELL NAME "Chep"       OF oSC5B_1 ALIAS "SA1" TITLE "Chep"          SIZE 50 BLOCK {|| AllTrim(QRY1->A1_I_CCHEP) }
DEFINE CELL NAME "C5_I_TRCNF" OF oSC5B_1 ALIAS ""    TITLE "Troca NF?"       BLOCK {|| If(QRY1->C5_I_TRCNF=="S","SIM","NAO")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "B1_I_BIMIX" OF oSC5B_1 ALIAS "SB1" TITLE "Grupo Mix"       SIZE 2 
DEFINE CELL NAME "C5_I_FILFT"    OF oSC5B_1 ALIAS ""    TITLE "Filial Fat."     BLOCK {|| If(QRY1->C5_I_TRCNF=="S",QRY1->C5_I_FILFT+"-"+U_ROMS002F(QRY1->C5_I_FILFT)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FLFNC"    OF oSC5B_1 ALIAS ""    TITLE "Filial Carr."    BLOCK {|| If(QRY1->C5_I_TRCNF=="S",QRY1->C5_I_FLFNC+"-"+U_ROMS002F(QRY1->C5_I_FLFNC)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "SITUACAO"      OF oSC5B_1 ALIAS ""    TITLE "Situação"        BLOCK {|| QRY1->SITUACAO } SIZE 14 
DEFINE CELL NAME "LOCALCID"      OF oSC5B_1 ALIAS ""    TITLE "Cidade Entrega"  BLOCK {|| If(QRY1->C5_I_OPER=="02",U_ROMS002H(QRY1->C6_FILIAL,QRY1->C5_NUM,"CIDADE"),AllTrim(SUBSTR(QRY1->A1_MUN,1,15)))}
DEFINE CELL NAME "LOCALUF"       OF oSC5B_1 ALIAS ""    TITLE "UF Entrega"      BLOCK {|| If(QRY1->C5_I_OPER=="02",U_ROMS002H(QRY1->C6_FILIAL,QRY1->C5_NUM,"UF"),AllTrim(QRY1->A1_EST))}
DEFINE CELL NAME "C5_CONDPAG"    OF oSC5B_1 ALIAS ""    TITLE "Cond.Pgto"       BLOCK {|| QRY1->C5_CONDPAG } SIZE 10
DEFINE CELL NAME "E4_DESCRI"     OF oSC5B_1 ALIAS ""    TITLE "Descr.Cond.Pgto" BLOCK {|| QRY1->E4_DESCRI }  SIZE 14
DEFINE CELL NAME "C5_TPFRETE"    OF oSC5B_1 ALIAS ""    TITLE "Tipo Frete"      BLOCK {|| QRY1->C5_TPFRETE } SIZE 10
DEFINE CELL NAME "C5_DESCONT"    OF oSC5B_1 ALIAS ""    TITLE "$ Desconto"      BLOCK {|| QRY1->C5_DESCONT } SIZE 18  
DEFINE CELL NAME "C5_VEND4"      OF oSC5B_1 ALIAS "SC5" TITLE "Supervisor"      SIZE 12
DEFINE CELL NAME "NOMESUP"       OF oSC5B_1 ALIAS "SC5" TITLE "Nome Supervisor" SIZE 40 BLOCK {|| cSupervisor }	
DEFINE CELL NAME "C5_NOTA"       OF oSC5B_1 ALIAS "SC5" TITLE "Nota Fiscal"     BLOCK {||If(QRY1->C5_I_OPER="42",QRY1->F_C5_NOTA ,If(QRY1->C5_I_OPER="05",QRY1->R_C5_NOTA,QRY1->C5_NOTA)) }
DEFINE CELL NAME "F2_EMISSAO"    OF oSC5B_1 ALIAS "SF2" TITLE "Emissao NFe"     BLOCK {||If(QRY1->C5_I_OPER="42",QRY1->F_F2_EMISSAO ,If(QRY1->C5_I_OPER="05",QRY1->R_F2_EMISSAO,QRY1->F2_EMISSAO)) }
DEFINE CELL NAME "F2_I_NTRAN"    OF oSC5B_1 ALIAS "SF2" TITLE "Transportadora"   
DEFINE CELL NAME "F2_I_NTRIA"    OF oSC5B_1 ALIAS "SF2" TITLE "Nfe Adquiren"  
DEFINE CELL NAME "F2_I_STRIA"    OF oSC5B_1 ALIAS "SF2" TITLE "Ser Adquiren"  
DEFINE CELL NAME "F2_I_DTRIA"    OF oSC5B_1 ALIAS "SF2" TITLE "Data Nfe Adq"  
DEFINE CELL NAME "F2_I_DTRC"     OF oSC5B_1 ALIAS "SF2" TITLE "Dt.Entrega Canhoto" 
DEFINE CELL NAME "ZA1_DESCRI"    OF oSC5B_1 ALIAS "ZA1" TITLE "FAMÍLIA"
DEFINE CELL NAME "ZA3_DESCRI"    OF oSC5B_1 ALIAS "ZA3" TITLE "MARCA"
DEFINE CELL NAME "MES"           OF oSC5B_1 ALIAS ""    TITLE "MES"          BLOCK {|| MesExtenso(QRY1->C5_EMISSAO) }
DEFINE CELL NAME "ZZ6_DESCRO"    OF oSC5B_1 ALIAS "ZZ6" TITLE "CLIENTE GRUPO" 
DEFINE CELL NAME "TABELA"        OF oSC5B_1 ALIAS ""    TITLE "TABELA"       BLOCK {|| QRY1->ZW_TABELA } SIZE 4 
DEFINE CELL NAME "SITAGENDA"     OF oSC5B_1 ALIAS ""    TITLE "SIT AGENDA"   BLOCK {|| If(Empty(AllTrim(QRY1->C5_NOTA)),ROMS2FMT( QRY1->C5_I_AGEND,QRY1->C5_I_DTENT)," ")} SIZE 14
DEFINE CELL NAME "C5_LIBEROK"    OF oSC5B_1 ALIAS "SC5" TITLE "LIBERADO"     BLOCK {|| If((QRY1->C5_LIBEROK !=" " .Or.!Empty(QRY1->C5_NOTA)) ,"ESTOQUE LIBERADO","NAO LIBERADO")} SIZE 14
DEFINE CELL NAME "C9_DATALIB"    OF oSC5B_1 ALIAS "SC9" TITLE "DT Liberacao" 
DEFINE CELL NAME "DAI_DATA"      OF oSC5B_1 ALIAS "DAI" TITLE "Dt Carga" 
DEFINE CELL NAME "DAI_COD"       OF oSC5B_1 ALIAS "DAI" TITLE "O.C." 	
DEFINE CELL NAME "C5_I_DTPRV" OF oSC5B_1 ALIAS ""     TITLE "Dt Prev.Est."            PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_DTSAG" OF oSC5B_1 ALIAS ""     TITLE "Dt.Suger.Agend."         PICTURE "@!"  SIZE 14  
DEFINE CELL NAME "C5_I_ARQOP" OF oSC5B_1 ALIAS ""     TITLE "Arq. Operador Logistico" PICTURE "@!"  SIZE 14  
DEFINE CELL NAME "C5_I_TAB"   OF oSC5B_1 ALIAS "SC5"  TITLE "Tab." 
DEFINE CELL NAME "DA0_DESCRI" OF oSC5B_1 ALIAS "DA0"  TITLE "Desc.Tab.Preço" 
DEFINE CELL NAME "PEDIDO"     OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Ped"          BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_C5_NUM      ,QRY1->R_C5_NUM),"") }
DEFINE CELL NAME "CLIENTE"    OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda CodCli"       BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_C5_CLIENT   ,QRY1->R_C5_CLIENT   ),"") }
DEFINE CELL NAME "LOJAENT"    OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Lj."          BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_C5_LOJAENT  ,QRY1->R_C5_LOJAENT  ),"") }
DEFINE CELL NAME "NOME"       OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Razo Social"  BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_A1_NOME     ,QRY1->R_A1_NOME ),"") }
DEFINE CELL NAME "NOMERED"    OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Fantasia"     BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_A1_NREDUZ   ,QRY1->R_A1_NREDUZ  ),"") }
DEFINE CELL NAME "NOTA"       OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Nfe"          BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_C5_NOTA     ,QRY1->R_C5_NOTA),"") }
DEFINE CELL NAME "SERIE"      OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Serie"        BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_F2_SERIE    ,QRY1->R_F2_SERIE),"") }
DEFINE CELL NAME "EMISSAO"    OF oSC5B_1 ALIAS ""     TITLE "Rem/Vda Emissão"      BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,STOD(QRY1->V_F2_EMISSAO),STOD(QRY1->R_F2_EMISSAO)),"") }
DEFINE CELL NAME "F2_CHVNFE"  OF oSC5B_1 ALIAS "SF2"  TITLE "Rem/Vda Chave NFE"    BLOCK {|| IIf( QRY1->C5_I_OPER $ "42|05", IIf( QRY1->C5_I_OPER == "42" ,QRY1->V_F2_CHVNFE    ,QRY1->R_F2_CHVNFE),"") }
DEFINE CELL NAME "C6_QTDVEN"     OF oSC5B_1 ALIAS "SC6" TITLE "Qtde S/ Abat 1um"    PICTURE "@E 999,999,999,999.99" SIZE 14  
DEFINE CELL NAME "C6_UNSVEN   "  OF oSC5B_1 ALIAS "SC6" TITLE "Qtde S/ Abat 2um"    PICTURE "@E 999,999,999,999.99" SIZE 14  
DEFINE CELL NAME "VLRPENDEN"     OF oSC5B_1 ALIAS ""    TITLE "Valor Total S/ Abat" BLOCK {|| QRY1->C6_QTDVEN * QRY1->C6_PRCVEN } PICTURE "@E 999,999,999,999.99"  SIZE 14 
DEFINE CELL NAME "D2_QTDEDEV"    OF oSC5B_1 ALIAS ""    TITLE "Qtde Devolvida 1um"  PICTURE "@E 999,999,999,999.99" SIZE 14   
DEFINE CELL NAME "D1_QTSEGUM"    OF oSC5B_1 ALIAS ""    TITLE "Qtde Devolvida 2um"  PICTURE "@E 999,999,999,999.99" SIZE 14   
DEFINE CELL NAME "D2_VALDEV"     OF oSC5B_1 ALIAS ""    TITLE "Vlr Devolvida"       PICTURE "@E 999,999,999,999.99" SIZE 14  
DEFINE CELL NAME "C5_ASSNOM"     OF oSC5B_1 ALIAS "SC5" TITLE "Assistente Comercial Resp." 
DEFINE CELL NAME "ZZL_NOME"      OF oSC5B_1 ALIAS "ZZL" TITLE "Usuário de Liberação P.V."         BLOCK {|| QRY1->ZZL_NOME } PICTURE "@!" SIZE 30 
DEFINE CELL NAME "LOC_EMB"       OF oSC5B_1 ALIAS ""    TITLE "Local de Embarque"                 BLOCK {|| QRY1->ZEL_DESCRI } PICTURE "@!" SIZE 40
DEFINE CELL NAME "DIASVIAGEM"    OF oSC5B_1 ALIAS ""    TITLE "Dias de Viagem"                    BLOCK {|| U_ROMS2DLT("DIASVIAGEM") } PICTURE "@E 9,999,999" SIZE 15
DEFINE CELL NAME "DIASOPERAC"    OF oSC5B_1 ALIAS ""    TITLE "Dias Operacional"                  BLOCK {|| U_ROMS2DLT("DIASOPERAC") } PICTURE "@E 9,999,999" SIZE 15
DEFINE CELL NAME "LEADTIME"      OF oSC5B_1 ALIAS ""    TITLE "Lead Time"                         BLOCK {|| U_ROMS2DLT("LEADTIME"  ) } PICTURE "@E 9,999,999" SIZE 15

If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
    DEFINE CELL NAME "REGRA"        OF oSC5B_1 ALIAS ""    TITLE "Regra encontrada"                  BLOCK {|| U_ROMS2DLT("REGRA"  ) } SIZE 200
EndIf

DEFINE CELL NAME "B1_I_BIMIX"   OF oSC5B_1 ALIAS "SB1" TITLE "Grupo Mix" SIZE 2 
DEFINE CELL NAME "USR_DTENT"    OF oSC5B_1 ALIAS ""    TITLE "Ult Usr Dt Entrega"    BLOCK {|| ROMS2USR(QRY1->USR_DTENT ,1)} SIZE 30
DEFINE CELL NAME "USR_TPAGEN"   OF oSC5B_1 ALIAS ""    TITLE "Ult Usr Tp Agend."     BLOCK {|| ROMS2USR(QRY1->USR_TPAGEN,3)} SIZE 30
DEFINE CELL NAME "JUSTIFICAT"   OF oSC5B_1 ALIAS ""    TITLE "Justificativas"        BLOCK {|| U_ROMS002J(QRY1->C5_FILIAL, QRY1->C5_NUM ) } SIZE 60 
DEFINE CELL NAME "C6_I_PDESC"   OF oSC5B_1 ALIAS "SC6" TITLE "% Contrato"            PICTURE "@E 999.99" 
DEFINE CELL NAME "CLASSENT"     OF oSC5B_1 ALIAS ""    TITLE "Classificacao Entrega" BLOCK {|| _cClassEnt                  } SIZE 60  //Variavel preenchida na funçao ROMS2USR() - A1_I_CLABC
DEFINE CELL NAME "A1_I_SHLFP"   OF oSC5B_1 ALIAS "SA1" TITLE "Shelf Life do Produto" SIZE 10
DEFINE CELL NAME "MESOREGI"     OF oSC5B_1 ALIAS ""    TITLE "Mesorregiao"                 BLOCK {|| QRY1->Z21_NOME } SIZE 60//MESORREGIÃO   - Z21_NOME "MESORREGIÃO",  //Z21_FILIAL+Z21_EST+Z21_COD
DEFINE CELL NAME "MICROREG"     OF oSC5B_1 ALIAS ""    TITLE "Microrregiao"                BLOCK {|| QRY1->Z22_NOME } SIZE 60//MICRORREGIÃO -  Z22_NOME "MICRORREGIÃO", //Z22_FILIAL+Z22_EST+Z22_MESO+Z22_COD
DEFINE CELL NAME "ZY4_DESCRI"   OF oSC5B_1 ALIAS ""    TITLE "Evento Comercial"            BLOCK {|| QRY1->ZY4_DESCRI } SIZE 50  
DEFINE CELL NAME "F2_I_PENCL"   OF oSC5B_1 ALIAS ""    TITLE "Dt prev de entrega Cliente"  BLOCK {|| IIf(!Empty(AllTrim(QRY1->C5_NOTA)),(QRY1->F2_I_PENCL),(QRY1->C5_I_DTENT)) }
DEFINE CELL NAME "F2_I_DENCL"   OF oSC5B_1 ALIAS ""    TITLE "Dt entrega Cliente"          BLOCK {|| IIf(!Empty(AllTrim(QRY1->C5_NOTA)),(QRY1->F2_I_DENCL),CTOD("")) }
DEFINE CELL NAME "TR_FIL"       OF oSC5B_1 ALIAS ""    TITLE "TROCA FIL"                   BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->C5_I_FLFNC   ,QRY1->C5_I_FILFT),"") } 
DEFINE CELL NAME "TR_PED"       OF oSC5B_1 ALIAS ""    TITLE "TROCA PED"                   BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->C5_I_PDPR    ,QRY1->C5_I_PDFT   ),"") } 
DEFINE CELL NAME "TR_NFE"       OF oSC5B_1 ALIAS ""    TITLE "TROCA NFE"                   BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->F_C5_NOTA  ,QRY1->T_C5_NOTA  ),"") } 
DEFINE CELL NAME "TR_SERIE"     OF oSC5B_1 ALIAS ""    TITLE "TROCA SERIE"                 BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->F_C5_SERIE ,QRY1->T_C5_SERIE ),"") } 
DEFINE CELL NAME "TR_RAZAO "    OF oSC5B_1 ALIAS ""    TITLE "TROCA RAZAO SOCIAL"          BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->F_A1_NOME  ,QRY1->T_A1_NOME  ),"") }
DEFINE CELL NAME "TR_FANTA"     OF oSC5B_1 ALIAS ""    TITLE "TROCA FANTASIA"              BLOCK {|| IIf( QRY1->C5_I_TRCNF = "S", IIf( QRY1->C5_I_OPER <> "20" ,QRY1->F_A1_NREDUZ,QRY1->T_A1_NREDUZ),"") }
DEFINE CELL NAME "C6_PRODUTO"   OF oSC5B_1 ALIAS "SC6"
DEFINE CELL NAME "C6_I_PRMIN"   OF oSC5B_1 ALIAS "SC6"
DEFINE CELL NAME "C6_I_KIT"     OF oSC5B_1 ALIAS "SC6" TITLE "Código Kit"  BLOCK {|| (QRY1->C6_I_KIT) }  SIZE 14 
DEFINE CELL NAME "C6_I_VLIBB"   OF oSC5B_1 ALIAS "SC6"

oSC5B_1:Cell("PESTOTAL"):SetHeaderAlign("RIGHT")
oSC5B_1:SetTotalInLine(.F.)
oSC5B_1:SetTotalText({||"SUBTOTAL VENDEDOR:" + cVendedor })
oSC5B_1:OnPrintLine({|| cVendedor := QRY1->C5_VEND1 + " - " + QRY1->C5_I_V1NOM, cCoordenador := QRY1->C5_VEND2 + " - " + QRY1->C5_I_V2NOM ,AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSC5B_1:Disable()

//Alinha os titulos dos campos numericos a direita - Somente campos que nao estao no SX3
oSC5B_1:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

//Define secoes para SEGUNDA ORDEM - DATA DE ENTREGA (2)
//SECAO FILIAL
DEFINE Section oSC5FIL_2 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL" OF oSC5FIL_2 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"    OF oSC5FIL_2 ALIAS "" BLOCK {|| FWFilialName(,QRY2->C6_FILIAL)} TITLE "Filial" SIZE 20

oSC5FIL_2:OnPrintLine({|| cNomeFil := QRY2->C6_FILIAL  + " -  " + FWFilialName(,QRY2->C6_FILIAL) })
oSC5FIL_2:SetTotalText({|| "SUBTOTAL FILIAL: " + cFilial})                                                        
oSC5FIL_2:Disable() 

//Secao para ORDEM DATA ENTREGA
DEFINE Section oSC5_2 OF oSC5FIL_2 TITLE "Dados" TABLES "SB1","SC6","SC5","SA3","SA1","ZF8"  
DEFINE CELL NAME "C5_I_DTENT"	OF oSC5_2 ALIAS "SC6"
oSC5_2:Disable()

//Secao Detalhes - SubSecao da Secao SC5A_1
DEFINE Section oSC5A_2 OF oSC5_2 TITLE ("Data de Entrega "+If(MV_PAR21=1,"Sintético","Analítico")) TABLES "SC5","SB1" //TOTAL TEXT "SUBTOTAL" TOTAL IN COLUMN
DEFINE CELL NAME "C5_NUM" 		OF oSC5A_2 ALIAS "SC5" TITLE "Pedido"
DEFINE CELL NAME "C5_I_PEVIN" OF oSC5A_2 ALIAS "SC5" TITLE "PV Vinculado" SIZE 8
DEFINE CELL NAME "C5_EMISSAO" OF oSC5A_2 ALIAS "SC5" TITLE "Emissao do Pedido" 
DEFINE CELL NAME "C6_CLI"     OF oSC5A_2 ALIAS "SC6" SIZE 12
DEFINE CELL NAME "C6_LOJA"    OF oSC5A_2 ALIAS "SC6" SIZE 12
DEFINE CELL NAME "A1_NREDUZ"  OF oSC5A_2 ALIAS "SA1" SIZE 25
DEFINE CELL NAME "MUNEST"     OF oSC5A_2 ALIAS "SA1" TITLE "Municipio(UF)" SIZE 17 BLOCK {|| AllTrim(QRY2->A1_MUN) + '(' + AllTrim(QRY2->A1_EST) + ')'}
DEFINE CELL NAME "BAIRRO"     OF oSC5A_2 ALIAS "SA1" TITLE "Bairro" SIZE 50 BLOCK {|| AllTrim(QRY2->A1_BAIRRO) }
DEFINE CELL NAME "CEP"        OF oSC5A_2 ALIAS "SA1" TITLE "Cep"    SIZE 50 BLOCK {|| AllTrim(QRY2->A1_CEP) }   

If MV_PAR21 = 2//ANALITICO
    DEFINE CELL NAME "B1_I_DESCD" OF oSC5A_2 ALIAS "SB1" TITLE "Produto"       SIZE 36 BLOCK {|| If (!Empty(QRY2->C6_I_DQESP),QRY2->C6_I_DQESP,QRY2->B1_I_DESCD)}
    DEFINE CELL NAME "C6_QTDVEN"  OF oSC5A_2 ALIAS "SC6" PICTURE "@E 99,999,999.99"  SIZE 14
    DEFINE CELL NAME "C6_UM"      OF oSC5A_2 ALIAS "SC6" TITLE "Un. M"   SIZE 6
    DEFINE CELL NAME "C6_UNSVEN"  OF oSC5A_2 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
    DEFINE CELL NAME "C6_SEGUM"   OF oSC5A_2 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
    DEFINE CELL NAME "CARGATOTAL" OF oSC5A_2 ALIAS ""    TITLE "Carga Total" BLOCK {|| If(MV_PAR21=1,(QRY2->CARGATOTAL),ROMS002CT(QRY2->B1_COD,QRY2->C6_QTDVEN)) } SIZE 50
    DEFINE CELL NAME "C6_I_QPALT" OF oSC5A_2 ALIAS "SC6" TITLE "Pallets" PICTURE "@E 99,999,999"
    DEFINE CELL NAME "C6_LOCAL"   OF oSC5A_2 ALIAS "SC6" TITLE "Armazém" SIZE 3
    DEFINE CELL NAME "C6_PRCVEN"  OF oSC5A_2 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14
    DEFINE CELL NAME "C6_PRCNET"  OF oSC5A_2 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
    DEFINE CELL NAME "VLRPENDEN"  OF oSC5A_2 ALIAS ""    TITLE "Valor Total"    BLOCK {|| QRY2->C6_QTDVEN*QRY2->C6_PRCVEN } PICTURE "@E 999,999,999,999.99"  SIZE 16
Else//SINTETICO
    DEFINE CELL NAME "CARGATOTAL" OF oSC5A_2 ALIAS "" TITLE "Pallets" SIZE 50 PICTURE "@E 99,999,999"
EndIf

DEFINE CELL NAME "PESBRUTO"   OF oSC5A_2 ALIAS ""     TITLE "Peso Bruto(Kg)" BLOCK {|| If(MV_PAR21=1,(QRY2->C5_PBRUTO),(QRY2->C6_QTDVEN * QRY2->B1_PESBRU)) } PICTURE "@E 99,999,999.99"  SIZE 17 
DEFINE CELL NAME "C6_PEDCLI"  OF oSC5A_2 ALIAS "QRY2" TITLE "Ped.Cli" SIZE 9

If MV_PAR21 = 2//ANALITICO 
    DEFINE CELL NAME "CARGAGERAL" OF oSC5A_2 ALIAS ""     TITLE "Carga Total Ped"  	BLOCK {|| ROMS2CG(QRY2->C6_FILIAL,QRY2->C5_NUM) } SIZE 50//NOVO 3
    DEFINE CELL NAME "CARGATOTAL" OF oSC5A_2 ALIAS ""     TITLE "Carga Total Item" 	BLOCK {|| ROMS002CT(QRY2->B1_COD,QRY2->C6_QTDVEN) } SIZE 50
    DEFINE CELL NAME "VEICULO"    OF oSC5A_2 ALIAS ""     TITLE "Veículo Pedido"  	BLOCK {|| ROMS2VEI() } SIZE 20 
    DEFINE CELL NAME "VEICITEM"   OF oSC5A_2 ALIAS ""     TITLE "Veículo Item"  		BLOCK {|| ROMS2VIT() } SIZE 20 
EndIf

DEFINE CELL NAME "C5_I_TIPCA" OF oSC5A_2 ALIAS "SC5" TITLE "Tp Carga"      SIZE 8
DEFINE CELL NAME "C5_I_AGEND" OF oSC5A_2 ALIAS "SC5" TITLE "Tp Agenda"     SIZE 10
DEFINE CELL NAME "C5_I_SENHA" OF oSC5A_2 ALIAS "SC5" TITLE "Senha"         SIZE 14
DEFINE CELL NAME "C5_I_HOREN" OF oSC5A_2 ALIAS "SC5" TITLE "Hr. Receb"     SIZE 30
DEFINE CELL NAME "C5_I_DOCA"  OF oSC5A_2 ALIAS "SC5" TITLE "Doca"          SIZE 8
DEFINE CELL NAME "C5_I_CHAPA" OF oSC5A_2 ALIAS "SC5" TITLE "Qtd Chapa" 	   SIZE 8
DEFINE CELL NAME "C5_I_CHPCL" OF oSC5A_2 ALIAS "SC5" TITLE "Utl Chp Cli"   SIZE 8
DEFINE CELL NAME "C5_I_OBPED" OF oSC5A_2 ALIAS "SC5" TITLE "Obs Pedido"    SIZE 30
DEFINE CELL NAME "C5_MENNOTA" OF oSC5A_2 ALIAS "SC5" TITLE "Obs Nota"      SIZE 30
DEFINE CELL NAME "C5_I_OPTRI" OF oSC5A_2 ALIAS "SC5" TITLE "Tp PV Op Tri?" SIZE 10
DEFINE CELL NAME "C5_I_PVREM" OF oSC5A_2 ALIAS "SC5" TITLE "PV Remessa"    SIZE 10 BLOCK {|| IIf(QRY2->C5_I_TRCNF=="S" .And. QRY2->C5_I_OPER == "42",QRY2->C5_NUM,QRY2->C5_I_PVREM) }
DEFINE CELL NAME "C5_I_PVFAT" OF oSC5A_2 ALIAS "SC5" TITLE "PV Faturament" SIZE 10 BLOCK {|| IIf(QRY2->C5_I_TRCNF=="S" .And. QRY2->C5_I_OPER == "05",QRY2->C5_NUM,QRY2->C5_I_PVFAT) }	
DEFINE CELL NAME "C5_I_OPER"  OF oSC5A_2 ALIAS "SC5" TITLE "Tp Operacao"   SIZE 10
DEFINE CELL NAME "Chep"       OF oSC5A_2 ALIAS "SA1" TITLE "Chep"          SIZE 50 BLOCK {|| AllTrim(QRY2->A1_I_CCHEP) }	
DEFINE CELL NAME "C5_I_TRCNF" OF oSC5A_2 ALIAS "" TITLE "Troca NF?"     BLOCK {|| If(QRY2->C5_I_TRCNF=="S","SIM","NAO")}          PICTURE "@!"  SIZE 14
DEFINE CELL NAME "C5_I_FILFT" OF oSC5A_2 ALIAS "" TITLE "Filial Fat."   BLOCK {|| If(QRY2->C5_I_TRCNF=="S",QRY2->C5_I_FILFT+"-"+U_ROMS002F(QRY2->C5_I_FILFT)," ")} PICTURE "@!"  SIZE 14
DEFINE CELL NAME "C5_I_FLFNC" OF oSC5A_2 ALIAS "" TITLE "Filial Carr."  BLOCK {|| If(QRY2->C5_I_TRCNF=="S",QRY2->C5_I_FLFNC+"-"+U_ROMS002F(QRY2->C5_I_FLFNC)," ")} PICTURE "@!"  SIZE 14
DEFINE CELL NAME "SITUACAO"   OF oSC5A_2 ALIAS "" TITLE "Situação"      BLOCK {|| QRY2->SITUACAO } SIZE 14
DEFINE CELL NAME "LOCALENTR"  OF oSC5A_2 ALIAS "" TITLE "Local Entrega" BLOCK {|| U_ROMS002H(QRY2->C6_FILIAL,QRY2->C5_NUM)}  
DEFINE CELL NAME "NRCARGA"    OF oSC5A_2 ALIAS "" TITLE "Numero Carga"  BLOCK {|| U_ROMS002N(QRY2->C6_FILIAL,QRY2->C5_NUM)}  
DEFINE CELL NAME "C5_TPFRETE" OF oSC5A_2 ALIAS "" TITLE "Tipo Frete"    BLOCK {|| QRY2->C5_TPFRETE } SIZE 10

If MV_PAR21 == 1  //SINTÉTICO
    DEFINE CELL NAME "TOTALPED"     OF oSC5A_2 ALIAS "" TITLE "Vlr Total Ped"  BLOCK {|| QRY2->TOTALPED }  PICTURE "@E 99,999,999.99"  SIZE 17 
EndIf

DEFINE CELL NAME "ZF8_FILIAL" OF oSC5A_2 ALIAS "" TITLE "Fil. Prog. Entr." BLOCK {|| QRY2->ZF8_FILIAL }
DEFINE CELL NAME "ZF8_CODPRG" OF oSC5A_2 ALIAS "" TITLE "Cod. Prog. Entr." BLOCK {|| QRY2->ZF8_CODPRG }
DEFINE CELL NAME "LOC_EMB"    OF oSC5A_2 ALIAS "" TITLE "Local de Embarque"  BLOCK {|| QRY2->ZEL_DESCRI } PICTURE "@!" SIZE 40
DEFINE CELL NAME "USR_DTENT"  OF oSC5A_2 ALIAS "" TITLE "Ult Usr Dt Entrega" BLOCK {|| ROMS2USR(QRY2->USR_DTENT ,1)} SIZE 30
DEFINE CELL NAME "USR_TPAGEN" OF oSC5A_2 ALIAS "" TITLE "Ult Usr Tp Agend."  BLOCK {|| ROMS2USR(QRY2->USR_TPAGEN,2)} SIZE 30
DEFINE CELL NAME "JUSTIFICAT" OF oSC5A_2 ALIAS "" TITLE "Justificativas"     BLOCK {|| _cJustificativas            } SIZE 60  ////Variavel preenchida na funçao ROMS2USR() - Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
DEFINE CELL NAME "A1_I_SHLFP" OF oSC5A_2 ALIAS "SA1" TITLE "Shelf Life"    SIZE 50 BLOCK {|| AllTrim(QRY2->A1_I_SHLFP) }   

oSC5A_2:SetTotalInLine(.F.)
oSC5A_2:SetTotalText({||"SUBTOTAL DATA ENTREGA: " + cDataEntr })
oSC5A_2:OnPrintLine({|| cDataEntr := DToC(QRY2->C5_I_DTENT) })
        //Quando Sintetico devolve sempre .T.,Analitica
oSC5A_2:Disable()

//Alinha os titulos dos campos numericos a direita
oSC5A_2:Cell("PESBRUTO"):SetHeaderAlign("RIGHT")
oSC5A_2:Cell("PESBRUTO"):SetAlign("RIGHT")

//Define Break - Quebra por cliente, mas nao sumariza
DEFINE BREAK oBrkPed OF oSC5A_2 WHEN oSC5A_2:Cell("C5_NUM")

//Define secoes para TERCEIRA ORDEM - PRODUTO (3)      
//Secao Filial
DEFINE Section oSC5FIL_3 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL"	OF oSC5FIL_3 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	   OF oSC5FIL_3 ALIAS "" BLOCK{|| FWFilialName(,QRY3->C6_FILIAL)} TITLE "Filial" SIZE 20

oSC5FIL_3:OnPrintLine({|| cNomeFil := QRY3->C6_FILIAL  + " -  " + FWFilialName(,QRY3->C6_FILIAL) })
oSC5FIL_3:SetTotalText({|| "SUBTOTAL FILIAL: " + cFilial})                                                        
oSC5FIL_3:Disable()   

//Secao para ordem Produto
DEFINE Section oSC5_3 OF oSC5FIL_3 TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  
DEFINE CELL NAME "C6_PRODUTO" OF oSC5_3 ALIAS "SC6"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5_3 ALIAS "SB1" SIZE 40 BLOCK {|| If (!Empty(QRY3->C6_I_DQESP),QRY3->C6_I_DQESP,QRY3->B1_I_DESCD)}
DEFINE CELL NAME "C5_VEND2"	OF oSC5_3 ALIAS "SC5" 
DEFINE CELL NAME "C5_I_V2NOM"	OF oSC5_3 ALIAS "SC5" TITLE "Nome"
oSC5_3:SetLinesBefore(4)

DEFINE Section oSC5A_3 OF oSC5_3 TITLE "Produto Analitico" TABLES "SC5","SB1"
DEFINE CELL NAME "C5_NUM" 		OF oSC5A_3 ALIAS "SC5" TITLE "Pedido"
DEFINE CELL NAME "C5_I_PEVIN" OF oSC5A_3 ALIAS "SC5" TITLE "PV Vinculado"
DEFINE CELL NAME "C6_ITEM"    OF oSC5A_3 ALIAS "SC6" 
DEFINE CELL NAME "C5_EMISSAO" OF oSC5A_3 ALIAS "SC5" TITLE "Emissao do Pedido" 
DEFINE CELL NAME "C5_I_DTENT" OF oSC5A_3 ALIAS "SC6" 
DEFINE CELL NAME "C6_CLI"     OF oSC5A_3 ALIAS "SC6"
DEFINE CELL NAME "C6_LOJA"    OF oSC5A_3 ALIAS "SC6"
DEFINE CELL NAME "A1_NREDUZ"  OF oSC5A_3 ALIAS "SA1" SIZE 30
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5A_3 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5A_3 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14
DEFINE CELL NAME "C6_PRCNET"  OF oSC5A_3 ALIAS "SC6" PICTURE "@E 999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5A_3 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5A_3 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5A_3 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL" OF oSC5A_3 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY3->C6_PRODUTO,QRY3->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5A_3 ALIAS "SC6"  TITLE "Armazém" SIZE 3
DEFINE CELL NAME "VLRPENDEN"  OF oSC5A_3 ALIAS ""     TITLE "Valor Total" BLOCK {|| QRY3->C6_QTDVEN*QRY3->C6_PRCVEN } PICTURE "@E 999,999,999,999.99"  SIZE 17
DEFINE CELL NAME "C6_PEDCLI"  OF oSC5A_3 ALIAS "SC6"  TITLE "Ped.Cli" SIZE 9
DEFINE CELL NAME "C5_I_TRCNF" OF oSC5A_3 ALIAS "" TITLE "Troca NF?"         BLOCK {|| If(QRY3->C5_I_TRCNF=="S","SIM","NAO")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FILFT" OF oSC5A_3 ALIAS "" TITLE "Filial Fat."       BLOCK {|| If(QRY3->C5_I_TRCNF=="S",QRY3->C5_I_FILFT+"-"+U_ROMS002F(QRY3->C5_I_FILFT)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FLFNC" OF oSC5A_3 ALIAS "" TITLE "Filial Carr."      BLOCK {|| If(QRY3->C5_I_TRCNF=="S",QRY3->C5_I_FLFNC+"-"+U_ROMS002F(QRY3->C5_I_FLFNC)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "SITUACAO"   OF oSC5A_3 ALIAS "" TITLE "Situação"          BLOCK {|| QRY3->SITUACAO } SIZE 14 
DEFINE CELL NAME "LOC_EMB"    OF oSC5A_3 ALIAS "" TITLE "Local de Embarque" BLOCK {|| QRY3->ZEL_DESCRI } PICTURE "@!" SIZE 40
DEFINE CELL NAME "USR_DTENT"  OF oSC5A_3 ALIAS "" TITLE "Ult Usr Dt Entrega" BLOCK {|| ROMS2USR(QRY3->USR_DTENT ,1)} SIZE 30 
DEFINE CELL NAME "USR_TPAGEN" OF oSC5A_3 ALIAS "" TITLE "Ult Usr Tp Agend."  BLOCK {|| ROMS2USR(QRY3->USR_TPAGEN,2)} SIZE 30 
DEFINE CELL NAME "JUSTIFICAT" OF oSC5A_3 ALIAS "" TITLE "Justificativas"     BLOCK {|| _cJustificativas            } SIZE 60  ////Variavel preenchida na funçao ROMS2USR() - Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD

oSC5A_3:SetTotalInLine(.F.)
oSC5A_3:OnPrintLine({|| cDTentrega:=QRY3->C5_I_DTENT, cProduto := AllTrim(QRY3->C6_PRODUTO) +  " - " + If(!Empty(QRY3->C6_I_DQESP),QRY3->C6_I_DQESP,QRY3->B1_I_DESCD),AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSC5A_3:SetTotalText({|| "SUBTOTAL PRODUTO: " + cProduto})
oSC5A_3:Disable()

//Alinha os titulos dos campos numericos a direita
oSC5A_3:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT") 

DEFINE Section oSC5S_3 OF oSC5_3 TITLE "Produto Sintetico" TABLES "SC6","SB1"
DEFINE CELL NAME "C6_PRODUTO" OF oSC5S_3 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5S_3 ALIAS "SB1" TITLE "Descricao" SIZE 40 BLOCK {|| If (!Empty(QRY3->C6_I_DQESP),QRY3->C6_I_DQESP,QRY3->B1_I_DESCD)}
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5S_3 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5S_3 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14 BLOCK {|| QRY3->VLRPENDEN/QRY3->C6_QTDVEN }
DEFINE CELL NAME "C6_PRCNET"  OF oSC5S_3 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5S_3 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5S_3 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5S_3 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL" OF oSC5S_3 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY3->C6_PRODUTO,QRY3->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5S_3 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "C6_QTDENT"  OF oSC5S_3 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 14
DEFINE CELL NAME "QTDPENDEN"  OF oSC5S_3 ALIAS "" TITLE "Qtd. Pendente"     BLOCK {|| QRY3->C6_QTDVEN - QRY3->C6_QTDENT } PICTURE "@E 999,999,999,999.99"  //Quantidade vendida - quantidade entregue
DEFINE CELL NAME "VLRPENDEN"  OF oSC5S_3 ALIAS "" TITLE "Valor Total"       PICTURE "@E 999,999,999,999.99" SIZE 17
DEFINE CELL NAME "LOC_EMB"    OF oSC5S_3 ALIAS "" TITLE "Local de Embarque" BLOCK {|| QRY3->ZEL_DESCRI } PICTURE "@!" SIZE 40

oSC5S_3:SetTotalInLine(.F.)
oSC5S_3:OnPrintLine({|| cCoordenador := QRY3->C5_VEND2 + " - " + QRY3->C5_I_V2NOM ,AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSC5S_3:SetTotalText({||"SUBTOTAL Coordenador: " + cCoordenador})
oSC5S_3:Disable()

//Alinha os titulos dos campos numericos a direita
oSC5S_3:Cell("QTDPENDEN"):SetHeaderAlign("RIGHT")
oSC5S_3:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

//Define secoes para QUARTA ORDEM - REDE (4)        

//Secao Filial
DEFINE Section oSC5FIL_4 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL"  OF oSC5FIL_4 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"     OF oSC5FIL_4 ALIAS "" BLOCK {|| FWFilialName(,QRY4->C6_FILIAL)} TITLE "Filial" SIZE 20

oSC5FIL_4:OnPrintLine({|| cNomeFil := QRY4->C6_FILIAL  + " -  " + FWFilialName(,QRY4->C6_FILIAL) })
oSC5FIL_4:SetTotalText({|| "SUBTOTAL FILIAL: " + cFilial})                                                        
oSC5FIL_4:Disable()   

DEFINE Section oSC5_4 OF oSC5FIL_4 TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  
DEFINE CELL NAME "A1_GRPVEN"     OF oSC5_4 ALIAS "SA1"
DEFINE CELL NAME "ACY_DESCRI"    OF oSC5_4 ALIAS "SA1"

oSC5_4:Disable()

//Secao Sintetica
DEFINE Section oSC5S_4 OF oSC5_4 TITLE "Rede Sintetico" TABLES "SC6","SB1"
DEFINE CELL NAME "C6_PRODUTO" OF oSC5S_4 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5S_4 ALIAS "SB1" TITLE "Descricao" SIZE 40 BLOCK {|| If (!Empty(QRY4->C6_I_DQESP),QRY4->C6_I_DQESP,QRY4->B1_I_DESCD)}
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5S_4 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5S_4 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14 BLOCK {|| QRY4->VLRPENDEN/QRY4->C6_QTDVEN }
DEFINE CELL NAME "C6_PRCNET"  OF oSC5S_4 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5S_4 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5S_4 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5S_4 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL" OF oSC5S_4 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY4->C6_PRODUTO,QRY4->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5S_4 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "C6_QTDENT"  OF oSC5S_4 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 16
DEFINE CELL NAME "QTDPENDEN"  OF oSC5S_4 ALIAS "" TITLE "Qtd. Pendente" BLOCK {|| QRY4->C6_QTDVEN - QRY4->C6_QTDENT } PICTURE "@E 999,999,999,999.99"  //Quantidade vendida - quantidade entregue
DEFINE CELL NAME "VLRPENDEN"  OF oSC5S_4 ALIAS "" TITLE "Valor Total" PICTURE "@E 999,999,999,999.99"  SIZE 17
DEFINE CELL NAME "LOCALENTR"  OF oSC5S_4 ALIAS "" TITLE "Local Entrega"     BLOCK {|| U_ROMS002H(QRY4->C6_FILIAL,QRY4->C6_NUM)}  PICTURE "@!"  SIZE 40
DEFINE CELL NAME "LOC_EMB"    OF oSC5S_4 ALIAS "" TITLE "Local de Embarque"  BLOCK {|| QRY4->ZEL_DESCRI } PICTURE "@!" SIZE 40

oSC5S_4:SetTotalInLine(.F.)
oSC5S_4:SetTotalText({||"SUBTOTAL REDE: " + cRede})
oSC5S_4:OnPrintLine({|| cRede := QRY4->A1_GRPVEN + " - " + QRY4->ACY_DESCRI })
oSC5S_4:Disable()

//Alinha os titulos dos campos numericos a direita
oSC5S_4:Cell("QTDPENDEN"):SetHeaderAlign("RIGHT")
oSC5S_4:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

//Secao Analitica
DEFINE Section oSC5A_4 OF oSC5_4 TITLE "Rede Analitico" TABLES "SC6","SB1"
DEFINE CELL NAME "C5_NUM"  OF oSC5A_4 ALIAS "SC5" TITLE "Pedido" SIZE 8
DEFINE CELL NAME "C5_I_PEVIN" OF oSC5A_4 ALIAS "SC5" TITLE "PV Vinculado" SIZE 8
DEFINE CELL NAME "C6_ITEM"    OF oSC5A_4 ALIAS "SC6" 
DEFINE CELL NAME "C6_PRODUTO" OF oSC5A_4 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5A_4 ALIAS "SB1" TITLE "Descricao" SIZE 40 BLOCK {|| If (!Empty(QRY4->C6_I_DQESP),QRY4->C6_I_DQESP,QRY4->B1_I_DESCD)}
DEFINE CELL NAME "C5_EMISSAO" OF oSC5A_4 ALIAS "SC5" TITLE "Emissao do Pedido"  //PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "C5_I_DTENT" OF oSC5A_4 ALIAS "SC6" //PICTURE "@E 999,999,999.99"                
DEFINE CELL NAME "C6_CLI"     OF oSC5A_4 ALIAS "SC6" SIZE 08
DEFINE CELL NAME "C6_LOJA"    OF oSC5A_4 ALIAS "SC6" SIZE 08
DEFINE CELL NAME "A1_NREDUZ"  OF oSC5A_4 ALIAS "SA1" SIZE 23
DEFINE CELL NAME "MUNEST"     OF oSC5A_4 ALIAS "SA1" TITLE "Municipio(UF)" SIZE 17 BLOCK {|| AllTrim(QRY4->A1_MUN) + '(' + AllTrim(QRY4->A1_EST) + ')'}
DEFINE CELL NAME "BAIRRO"     OF oSC5A_4 ALIAS "SA1" TITLE "Bairro" SIZE 50 BLOCK {|| AllTrim(QRY4->A1_BAIRRO) }
DEFINE CELL NAME "CEP"        OF oSC5A_4 ALIAS "SA1" TITLE "Cep"    SIZE 50 BLOCK {|| AllTrim(QRY4->A1_CEP) }   
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5A_4 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5A_4 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14
DEFINE CELL NAME "C6_PRCNET"  OF oSC5A_4 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5A_4 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5A_4 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5A_4 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL"	OF oSC5A_4 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY4->C6_PRODUTO,QRY4->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5A_4 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "VLRPENDEN"  OF oSC5A_4 ALIAS "" TITLE "Valor Total" BLOCK {|| QRY4->C6_QTDVEN*QRY4->C6_PRCVEN } PICTURE "@E 999,999,999,999.99" SIZE 17
DEFINE CELL NAME "C6_PEDCLI"  OF oSC5A_4 ALIAS "SC6" TITLE "Ped.Cli" SIZE 9
DEFINE CELL NAME "C5_I_TRCNF" OF oSC5A_4 ALIAS "" TITLE "Troca NF?"      BLOCK {|| If(QRY4->C5_I_TRCNF=="S","SIM","NAO")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FILFT" OF oSC5A_4 ALIAS "" TITLE "Filial Fat."       BLOCK {|| If(QRY4->C5_I_TRCNF=="S",QRY4->C5_I_FILFT+"-"+U_ROMS002F(QRY4->C5_I_FILFT)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FLFNC" OF oSC5A_4 ALIAS "" TITLE "Filial Carr."      BLOCK {|| If(QRY4->C5_I_TRCNF=="S",QRY4->C5_I_FLFNC+"-"+U_ROMS002F(QRY4->C5_I_FLFNC)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "SITUACAO"   OF oSC5A_4 ALIAS "" TITLE "Situação"          BLOCK {|| QRY4->SITUACAO } SIZE 14 
DEFINE CELL NAME "LOCALENTR"  OF oSC5A_4 ALIAS "" TITLE "Local Entrega"     BLOCK {|| U_ROMS002H(QRY4->C6_FILIAL,QRY4->C5_NUM)}  PICTURE "@!" SIZE 40
DEFINE CELL NAME "LOC_EMB"    OF oSC5A_4 ALIAS "" TITLE "Local de Embarque" BLOCK {|| QRY4->ZEL_DESCRI } PICTURE "@!" SIZE 40
DEFINE CELL NAME "USR_DTENT"  OF oSC5A_4 ALIAS "" TITLE "Ult Usr Dt Entrega" BLOCK {|| ROMS2USR(QRY4->USR_DTENT ,1)} SIZE 30 
DEFINE CELL NAME "USR_TPAGEN" OF oSC5A_4 ALIAS "" TITLE "Ult Usr Tp Agend."  BLOCK {|| ROMS2USR(QRY4->USR_TPAGEN,2)} SIZE 30 
DEFINE CELL NAME "JUSTIFICAT" OF oSC5A_4 ALIAS "" TITLE "Justificativas"     BLOCK {|| _cJustificativas            } SIZE 60  ////Variavel preenchida na funçao ROMS2USR() - Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD

oSC5A_4:SetTotalInLine(.F.)
oSC5A_4:SetTotalText({||"SUBTOTAL REDE: " + cRede})
oSC5A_4:OnPrintLine({|| cRede := QRY4->A1_GRPVEN + " - " + QRY4->ACY_DESCRI })
oSC5A_4:Disable()

//Alinha os titulos dos campos numericos a direita
oSC5A_4:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")                                                   

//Define secoes para QUINTA ORDEM - MUNICIPIO (5)      

//Secao Filial
DEFINE Section oSC5FIL_5 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL"	OF oSC5FIL_5 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSC5FIL_5 ALIAS "" BLOCK{|| FWFilialName(,QRY5->C6_FILIAL)} TITLE "Filial" SIZE 20

oSC5FIL_5:OnPrintLine({|| cNomeFil := QRY5->C6_FILIAL  + " -  " + FWFilialName(,QRY5->C6_FILIAL) })
oSC5FIL_5:SetTotalText({|| "SUBTOTAL FILIAL: " + cFilial})                                                        
oSC5FIL_5:Disable()  

DEFINE Section oSC5_5 OF oSC5FIL_5 TITLE "Dados" TABLES "SA1"  ORDERS aOrd
DEFINE CELL NAME "A1_COD_MUN" 	OF oSC5_5 ALIAS "SA1" SIZE 10
DEFINE CELL NAME "A1_MUN"      	OF oSC5_5 ALIAS "SA1" 
DEFINE CELL NAME "A1_EST"      	OF oSC5_5 ALIAS "SA1" 

oSC5_5:Disable()

DEFINE BREAK oBrkMun OF oSC5_5 WHEN oSC5_5:Cell("A1_MUN") TITLE {|| "SUBTOTAL MUNICIPIO: " + cMunicipio}
oBrkMun:OnPrintTotal({|| oReport:SkipLine(4)})  //Salta 4 linhas ao imprimir o totalizador municipio

//Secao Vendedor - SubSecao da Secao SC5_1
DEFINE Section oSC5_5A OF oSC5_5 TITLE "Vendedor" TABLES "SA3"
DEFINE CELL NAME "C5_VEND1"   OF oSC5_5A ALIAS "SC5" TITLE "Vendedor"
DEFINE CELL NAME "A3_NOME"    OF oSC5_5A ALIAS "SA3"

oSC5_5A:SetTotalInLine(.F.)
oSC5_5A:SetTotalText({||"SUBTOTAL VENDEDOR: " + cVendedor  })
oSC5_5A:OnPrintLine({|| cVendedor := QRY5->C5_VEND1 + " - " + QRY5->C5_I_V1NOM,AllwaysTrue(),cMunicipio := QRY5->A1_COD_MUN + " - " + QRY5->A1_MUN }) //Atualiza Variavel do Subtotal
oSC5_5A:Disable()

//Secao Sintetica
DEFINE Section oSC5S_5          OF oSC5_5A TITLE "Municipio Sintetico" TABLES "SC6","SB1"

DEFINE CELL NAME "C6_PRODUTO" OF oSC5S_5 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5S_5 ALIAS "SB1" TITLE "Descricao" SIZE 40 BLOCK {|| If (!Empty(QRY5->C6_I_DQESP),QRY5->C6_I_DQESP,QRY5->B1_I_DESCD)}
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5S_5 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 17 
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5S_5 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14 BLOCK {|| QRY5->VLRPENDEN/QRY5->C6_QTDVEN  }
DEFINE CELL NAME "C6_PRCNET"  OF oSC5S_5 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5S_5 ALIAS "SC6" TITLE "Un. M" SIZE 5
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5S_5 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14 
DEFINE CELL NAME "C6_SEGUM"   OF oSC5S_5 ALIAS "SC6" TITLE "Seg. UM" SIZE 5
DEFINE CELL NAME "CARGATOTAL"	OF oSC5S_5 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY5->C6_PRODUTO,QRY5->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"	OF oSC5S_5 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "C6_QTDENT"	OF oSC5S_5 ALIAS "SC6" PICTURE "@E 999,999.99" SIZE 08 TITLE "Vlr. Uni."
DEFINE CELL NAME "QTDPENDEN"	OF oSC5S_5 ALIAS "" TITLE "Qtd. Pendente"     BLOCK {|| QRY5->C6_QTDVEN - QRY5->C6_QTDENT } PICTURE "@E 999,999,999,999.99"  //Quantidade vendida - quantidade entregue
DEFINE CELL NAME "VLRPENDEN"	OF oSC5S_5 ALIAS "" TITLE "Valor Total"       PICTURE "@E 999,999,999,999.99"  SIZE 17
DEFINE CELL NAME "LOCALENTR" 	OF oSC5S_5 ALIAS "" TITLE "Local Entrega"     BLOCK {|| U_ROMS002H(QRY5->C6_FILIAL,QRY5->C5_NUM)}  PICTURE "@!" SIZE 40
DEFINE CELL NAME "LOC_EMB"    OF oSC5S_5 ALIAS "" TITLE "Local de Embarque" BLOCK {|| QRY5->ZEL_DESCRI } PICTURE "@!" SIZE 40

oSC5S_5:SetTotalInLine(.F.)
oSC5S_5:SetTotalText({||"SUBTOTAL VENDEDOR: " + cVendedor})
oSC5S_5:OnPrintLine({|| cVendedor := QRY5->C5_VEND1 + " - " + QRY5->C5_I_V1NOM })
oSC5S_5:Disable()
oSC5S_5:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

//Secao Analitica
DEFINE Section oSC5A_5        OF oSC5_5A TITLE "Municipio Analitico" TABLES "SC5","SB1"

DEFINE CELL NAME "C5_NUM" 		OF oSC5A_5 ALIAS "SC5" TITLE "Pedido"
DEFINE CELL NAME "C5_I_PEVIN" OF oSC5A_5 ALIAS "SC5" TITLE "PV Vinculado"
DEFINE CELL NAME "C6_CLI"     OF oSC5A_5 ALIAS "SC6"
DEFINE CELL NAME "C6_LOJA"    OF oSC5A_5 ALIAS "SC6"
DEFINE CELL NAME "A1_NREDUZ"  OF oSC5A_5 ALIAS "SA1" SIZE 30
DEFINE CELL NAME "C5_EMISSAO" OF oSC5A_5 ALIAS "SC5" TITLE "Emissao do Pedido" 
DEFINE CELL NAME "B1_COD"     OF oSC5A_5 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5A_5 ALIAS "SB1" TITLE "Descricao" SIZE 40 BLOCK {|| If (!Empty(QRY5->C6_I_DQESP),QRY5->C6_I_DQESP,QRY5->B1_I_DESCD)}
DEFINE CELL NAME "C5_I_DTENT" OF oSC5A_5 ALIAS "SC6" TITLE "Entrega" 
DEFINE CELL NAME "C6_QTDVEN"  OF oSC5A_5 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"  OF oSC5A_5 ALIAS "SC6" PICTURE "@E 999,999,999.9999"
DEFINE CELL NAME "C6_PRCNET"  OF oSC5A_5 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5A_5 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5A_5 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5A_5 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL"	OF oSC5A_5 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY5->B1_COD,QRY5->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5A_5 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "VLRPENDEN"  OF oSC5A_5 ALIAS "" TITLE "Valor Total" BLOCK {|| QRY5->C6_QTDVEN*QRY5->C6_PRCVEN } PICTURE "@E 999,999,999,999.99"  SIZE 17
DEFINE CELL NAME "C6_PEDCLI"  OF oSC5A_5 ALIAS "SC6" TITLE "Ped.Cli" SIZE 9
DEFINE CELL NAME "C5_I_TRCNF" OF oSC5A_5 ALIAS "" TITLE "Troca NF?"         BLOCK {|| If(QRY5->C5_I_TRCNF=="S","SIM","NAO")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FILFT" OF oSC5A_5 ALIAS "" TITLE "Filial Fat."       BLOCK {|| If(QRY5->C5_I_TRCNF=="S",QRY5->C5_I_FILFT+"-"+U_ROMS002F(QRY5->C5_I_FILFT)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "C5_I_FLFNC" OF oSC5A_5 ALIAS "" TITLE "Filial Carr."      BLOCK {|| If(QRY5->C5_I_TRCNF=="S",QRY5->C5_I_FLFNC+"-"+U_ROMS002F(QRY5->C5_I_FLFNC)," ")} PICTURE "@!"  SIZE 14 
DEFINE CELL NAME "SITUACAO"   OF oSC5A_5 ALIAS "" TITLE "Situação"          BLOCK {|| QRY5->SITUACAO } SIZE 14 
DEFINE CELL NAME "LOCALENTR"  OF oSC5A_5 ALIAS "" TITLE "Local Entrega"     BLOCK {|| U_ROMS002H(QRY5->C6_FILIAL,QRY5->C5_NUM)}   PICTURE "@!" SIZE 40
DEFINE CELL NAME "LOC_EMB"    OF oSC5A_5 ALIAS "" TITLE "Local de Embarque" BLOCK {|| QRY5->ZEL_DESCRI } PICTURE "@!" SIZE 40
DEFINE CELL NAME "USR_DTENT" 	OF oSC5A_5 ALIAS "" TITLE "Ult Usr Dt Entrega" BLOCK {|| ROMS2USR(QRY5->USR_DTENT ,1)} SIZE 30  
DEFINE CELL NAME "USR_TPAGEN" OF oSC5A_5 ALIAS "" TITLE "Ult Usr Tp Agend."  BLOCK {|| ROMS2USR(QRY5->USR_TPAGEN,2)} SIZE 30  
DEFINE CELL NAME "JUSTIFICAT" OF oSC5A_5 ALIAS "" TITLE "Justificativas"     BLOCK {|| _cJustificativas            } SIZE 30  ////Variavel preenchida na funçao ROMS2USR() - Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD

oSC5A_5:SetTotalInLine(.F.)
oSC5A_5:SetTotalText({||"SUBTOTAL VENDEDOR: " + cVendedor})
oSC5A_5:OnPrintLine({|| cVendedor := QRY5->C5_VEND1 + " - " + QRY5->C5_I_V1NOM })
oSC5A_5:Disable()
oSC5A_5:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

//Define secao para SEXTA ORDEM - PRODUTO RESUMIDO (6)

//Secao Filial
DEFINE Section oSC5FIL_6 OF oReport TITLE "Dados" TABLES "SB1","SC6","SC5","SA3"  ORDERS aOrd
DEFINE CELL NAME "C6_FILIAL"	OF oSC5FIL_6 ALIAS "SC6"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSC5FIL_6 ALIAS "" BLOCK{|| FWFilialName(,QRY6->C6_FILIAL)} TITLE "Filial" SIZE 20

oSC5FIL_6:OnPrintLine({|| cNomeFil := QRY6->C6_FILIAL  + " -  " + FWFilialName(,QRY6->C6_FILIAL) })
oSC5FIL_6:SetTotalText({|| "SUBTOTAL FILIAL: " + cFilial})                                                        
oSC5FIL_6:Disable()  

DEFINE Section oSC5_6 OF oSC5FIL_6 TITLE "Produto Resumido" TABLES "SC6","SB1" ORDERS aOrd
DEFINE CELL NAME "C6_PRODUTO"	OF oSC5_6 ALIAS "SC6" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" OF oSC5_6 ALIAS "SB1" TITLE "Descricao" SIZE 40 //BLOCK {|| If (!Empty(QRY6->C6_I_DQESP),QRY6->C6_I_DQESP,QRY6->B1_I_DESCD)}
DEFINE CELL NAME "C6_QTDVEN"	OF oSC5_6 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 16
DEFINE CELL NAME "C6_PRCVEN"	OF oSC5_6 ALIAS "SC6" PICTURE "@E 999,999,999.9999" SIZE 14 BLOCK {|| QRY6->VLRPENDEN/QRY6->C6_QTDVEN  }
DEFINE CELL NAME "C6_PRCNET"	OF oSC5_6 ALIAS "SC6" PICTURE "@E 999,999,999.9999" TITLE "Preco Net" SIZE 9
DEFINE CELL NAME "C6_UM"      OF oSC5_6 ALIAS "SC6" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "C6_UNSVEN"  OF oSC5_6 ALIAS "SC6" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C6_SEGUM"   OF oSC5_6 ALIAS "SC6" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "CARGATOTAL"	OF oSC5_6 ALIAS "" TITLE "Carga Total" BLOCK {|| ROMS002CT(QRY6->C6_PRODUTO,QRY6->C6_QTDVEN) } SIZE 50
DEFINE CELL NAME "C6_LOCAL"   OF oSC5_6 ALIAS "SC6" TITLE "Armazém" SIZE 3
DEFINE CELL NAME "C6_QTDENT"	OF oSC5_6 ALIAS "SC6" PICTURE "@E 999,999,999,999.99" SIZE 14
DEFINE CELL NAME "QTDPENDEN"	OF oSC5_6 ALIAS ""    TITLE "Qtd. Pendente"     BLOCK {|| QRY6->C6_QTDVEN - QRY6->C6_QTDENT } PICTURE "@E 999,999,999,999.99"  //Quantidade vendida - quantidade entregue
DEFINE CELL NAME "VLRPENDEN"	OF oSC5_6 ALIAS ""    TITLE "Valor Total"       PICTURE "@E 999,999,999,999.99" SIZE 17
DEFINE CELL NAME "LOC_EMB"    OF oSC5_6 ALIAS ""    TITLE "Local de Embarque" BLOCK {|| QRY6->ZEL_DESCRI } PICTURE "@!" SIZE 40

oSC5_6:SetTotalInLine(.F.)
oSC5_6:Disable()
oSC5_6:Cell("VLRPENDEN"):SetHeaderAlign("RIGHT")

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ROMS002MI
Autor-------------: Jeovane
Data da Criacao---: 24/09/2008
Descrição---------: Rotina principal de impressão    
Parametros--------: oReport - objeto de impressão
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS002MI(oReport)

Local _lAbreParentesis
Local _cTexto
Local _ADADOSREL := {}
Local _aCab := {}
 
Private cFiltro      := "%"
Private cFilBloqueio := "%"
Private nOrdem := oSC5FIL_1:GetOrder() //Busca ordem selecionada pelo usuario  
Private _cFiltro2    := "%"  
Private cTimeInicial:=Time()

ROMS002P0()

MV_PAR21:=nMV_PAR21Salva//ANALITICO / SINTETICO
MV_PAR32:=nMV_PAR32Salva//Campos novos sim ou não

oReport:SetTitle("Relação de Pedidos. " + If(nOrdem <> 7,If(MV_PAR21 == 1,"Sintético. ", " Analítico. "),"") + " Data emissão de " + DToC(MV_PAR02) + " até "  + DToC(MV_PAR03) + ". Ordem "  + aOrd[nOrdem]) 

//Define o filtro de acordo com os parametros digitados
//Filtra Filial da SC5
If !Empty(AllTrim(MV_PAR01))	
    If Len(AllTrim(MV_PAR01)) < 5
        MV_PAR01:=LEFT(MV_PAR01,2)
        cFiltro += " AND SC5.C5_FILIAL = '"+MV_PAR01+"' "
    Else
        cFiltro += " AND SC5.C5_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";")
    EndIf

    //POR DATA DE ENTREGA SE TIVER PREENCHIDA O PARAMETRO DE CODIGO DE PROGRAMACAO DE ENTREGA
    If !Empty(MV_PAR34) .And. nOrdem = 2 //.AND. MV_PAR21 == 1//SINTETICO E ANALITICO
        //CODIGO DE PROGRAMACAO DE ENTREGA
        If !Empty( MV_PAR34 )
            cFiltro += " AND EXISTS (SELECT 'Y' FROM "   + retSqlName("ZF8") + " ZF81 WHERE ZF81.D_E_L_E_T_ = ' ' AND ZF81.ZF8_FILIAL = SC5.C5_FILIAL AND ZF81.ZF8_NUMPED = SC5.C5_NUM AND ZF81.ZF8_CODPRG = '" +AllTrim(MV_PAR34)+"') "
        EndIf
    EndIf
EndIf

//Filtra Emissao da SC5
If !Empty(MV_PAR02) .Or. !Empty(MV_PAR03)
    If MV_PAR02 == MV_PAR03
        cFiltro += " AND SC5.C5_EMISSAO = '" + DToS(MV_PAR02) + "' "
    Else
        If Empty(MV_PAR02) 
        MV_PAR02 := CTOD("01/01/2000")
        EndIf
        
        If Empty(MV_PAR03) 
        MV_PAR03 := CTOD("31/12/2099")
        EndIf
        cFiltro += " AND SC5.C5_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
    EndIf
EndIf

//Filtra data Entrega
If !Empty(MV_PAR04) .Or. !Empty(MV_PAR05)
    If MV_PAR04 == MV_PAR05
        cFiltro += " AND SC5.C5_I_DTENT = '" + DToS(MV_PAR04) + "' "
    Else
        If Empty(MV_PAR04) 
        MV_PAR04 := CTOD("01/01/2000")
        EndIf
        
        If Empty(MV_PAR05) 
        MV_PAR05 := CTOD("31/12/2099")
        EndIf
        cFiltro += " AND SC5.C5_I_DTENT BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "'"
    EndIf
EndIf

//Filtra Produto
If !Empty(MV_PAR06) .And. !Empty(MV_PAR07)
    If MV_PAR06 == MV_PAR07   	
        cFiltro += " AND SC6.C6_PRODUTO = '" + MV_PAR06 + "'"
    Else
        cFiltro += " AND SC6.C6_PRODUTO BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "'"
    EndIf
EndIf

//Filtra Cliente
If !Empty(MV_PAR08) .And. !Empty(MV_PAR10)
    cFiltro += " AND SC5.C5_CLIENT BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "'"
EndIf

//Filtra Loja Cliente
If !Empty(MV_PAR09) .And. !Empty(MV_PAR11)
    cFiltro += " AND SC5.C5_LOJAENT BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "'"
EndIf 

//Filtra Rede Cliente
If !Empty(MV_PAR12)
    cFiltro += " AND SA1.A1_GRPVEN IN " + FormatIn(MV_PAR12,";")
EndIf
    
//Filtra Estado Cliente
If !Empty(MV_PAR13) 
    cFiltro += " AND SA1.A1_EST IN " + FormatIn(MV_PAR13,";")
EndIf

//Filtra Cod Municipio Cliente
If !Empty(MV_PAR14) 
    cFiltro += " AND SA1.A1_COD_MUN IN " + FormatIn(MV_PAR14,";")
EndIf

//Filtra Vendedor
If !Empty(MV_PAR15) 
    If Len(AllTrim(MV_PAR15)) < 7  //selecionou apenas um Vendedor
        cFiltro += " AND SC5.C5_VEND1 = '" + AllTrim(MV_PAR15) + "' "
    Else
        cFiltro += " AND SC5.C5_VEND1 IN " + FormatIn(MV_PAR15,";")	
    EndIf
EndIf

//Filtra Supervisor
If !Empty(MV_PAR16)
    If Len(AllTrim(MV_PAR16)) < 7  //selecionou apenas um Vendedor
        cFiltro += " AND SC5.C5_VEND2 = '" + AllTrim(MV_PAR16) + "' "
    Else
        cFiltro += " AND SC5.C5_VEND2 IN " + FormatIn(MV_PAR16,";")
    EndIf
EndIf

//Filtra Gerente
If !Empty(MV_PAR38)
    If Len(AllTrim(MV_PAR38)) < 7  //selecionou apenas um Vendedor
        cFiltro += " AND SC5.C5_VEND3 = '" + AllTrim(MV_PAR38) + "' "
    Else
        cFiltro += " AND SC5.C5_VEND3 IN " + FormatIn(MV_PAR38,";")
    EndIf
EndIf

//Filtra Grupo de Produtos
If !Empty(MV_PAR17)
    If Len(AllTrim(MV_PAR17)) < 5  //selecionou apenas um Grupo
        cFiltro += " AND SB1.B1_GRUPO = '" + AllTrim(MV_PAR17) + "' "
    Else
        cFiltro += " AND SB1.B1_GRUPO IN " + FormatIn(MV_PAR17,";")
    EndIf
EndIf

//Filtra Produto Nivel 2
If !Empty(MV_PAR18)
    cFiltro += " AND SB1.B1_I_NIV2 IN " + FormatIn(MV_PAR18,";")
EndIf

//Filtra Produto Nivel 3
If !Empty(MV_PAR19)
    cFiltro += " AND SB1.B1_I_NIV3 IN " + FormatIn(MV_PAR19,";")
EndIf

//Filtra Produto Nivel 4
If !Empty(MV_PAR20)
    cFiltro += " AND SB1.B1_I_NIV4 IN " + FormatIn(MV_PAR20,";")
EndIf

//Filtra Produto por Mix
If !Empty(MV_PAR37)
    cFiltro += " AND SB1.B1_I_BIMIX IN " + FormatIn(MV_PAR37,";")
EndIf

//Filtra Status Pedido
If MV_PAR22 == 1 //Pedido Liberados
    cFiltro += " AND SC5.C5_LIBEROK <> ' ' AND SC5.C5_NOTA = ' ' AND SC5.C5_BLQ = ' '
ElseIf MV_PAR22 == 2 //Somente Emitidos
    cFiltro += " AND SC5.C5_LIBEROK = ' ' AND SC5.C5_NOTA = ' ' AND SC5.C5_BLQ = ' ' "  
ElseIf MV_PAR22 == 3 //Faturados
    cFiltro += " AND SC5.C5_NOTA <> ' ' "  
ElseIf MV_PAR22 == 4 //Lib (+) Só Emitidos
    cFiltro += " AND SC5.C5_NOTA = ' ' AND SC5.C5_BLQ = ' ' "
EndIf

//Filtra operação triangulas
If MV_PAR35 == 1 //Não filtra
    cFiltro += " AND SC5.C5_I_OPER NOT IN ('05','42') "
ElseIf MV_PAR35 == 2 //05- Venda
    cFiltro += " AND SC5.C5_I_OPER  = '05'  " 
EndIf 

//Filtra usuario filial + matricula
If !Empty(MV_PAR24)
    cFiltro += " AND SC5.C5_I_CDUSU = '" + AllTrim(MV_PAR24) + "' "
EndIf

//busca CFOPS de acordo com parametro definido por usuario	
If !Empty(MV_PAR25)
    //Senao tiver escolhido 'A' opcao todos
    If !("A" $ MV_PAR25 )
        cCfops := U_ITCFOPS(MV_PAR25)
        cFiltro += " AND SC6.C6_CF IN " + FormatIn(cCfops,";")
    EndIf
EndIf

//Filtra Armazem
If !Empty(MV_PAR26)
    cFiltro += " AND SC6.C6_LOCAL IN " + FormatIn(MV_PAR26,";")
EndIf

//Sub Grupo de Produto
If !Empty(MV_PAR27)
    cFiltro += " AND SB1.B1_I_SUBGR IN " + FormatIn(MV_PAR27,";")
EndIf

//Peso Bruto
If MV_PAR28 > 0 .Or. MV_PAR29 > 0
    cFiltro += " AND SC5.C5_I_PESBR BETWEEN " + AllTrim(Str(MV_PAR28)) + " AND " + AllTrim(Str(MV_PAR29)) + " "
EndIf

//Tipo de Carga
If !Empty( MV_PAR30 )
    cFiltro += " AND SC5.C5_I_TIPCA IN " + FormatIn( AllTrim( MV_PAR30) , ";" )
EndIf

//Tipo de Agenda
If !Empty( MV_PAR31 )
    cFiltro += " AND SC5.C5_I_AGEND IN " + FormatIn( AllTrim(MV_PAR31) , ";" )
EndIf  

If MV_PAR36 <> 4
    cFiltro += " AND (SELECT A1_I_CLABC FROM "+ RETSQLNAME('SA1') +" SA1 "
    cFiltro += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = SC5.C5_CLIENTE AND SA1.A1_LOJA = SC5.C5_LOJACLI "
    cFiltro += " AND ROWNUM = 1) = '"+Str(MV_PAR36,1)+"' "
ElseIf !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
    cFiltro += " AND (SELECT A1_I_CLABC FROM "+ RETSQLNAME('SA1') +" SA1 "
    cFiltro += " WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = SC5.C5_CLIENTE AND SA1.A1_LOJA = SC5.C5_LOJACLI "
    cFiltro += " AND ROWNUM = 1) <> ' ' "
EndIf

//Situação do Pedido de Vendas
If nOrdem == 1 .Or. nOrdem == 2 .Or. nOrdem == 3 .Or. nOrdem == 4 .Or. nOrdem == 5 
    If "S" $ MV_PAR33  // Sem Bloqueio
        cFiltro += " AND NOT (C5_I_BLOQ = 'B' OR "  // Bloqueio bonIficação.   
        cFiltro += " SC5.C5_I_BLPRC = 'B' OR "  // Bloqueio preço
        cFiltro += " SC5.C5_I_BLCRE  = 'B') "    // Bloqueio credito. 
    Else            
        _lAbreParentesis := .F.
        
        If ("C" $ MV_PAR33 .Or. "P" $ MV_PAR33 .Or. "B" $ MV_PAR33)
            cFiltro += " AND ( "
            _lAbreParentesis := .T.
        EndIf
        
        If "C" $ MV_PAR33 // Bloqueio de Credito
            //cFiltro += " AND C5_I_BLCRE  = 'B' "
            If _lAbreParentesis                   
                cFiltro += " SC5.C5_I_BLCRE  = 'B' "
                _lAbreParentesis := .F.
            Else
                cFiltro += " OR SC5.C5_I_BLCRE  = 'B' "
            EndIf
        EndIf
        
        If "P" $ MV_PAR33 // Bloqueio de Preço
            //cFiltro += " AND C5_I_BLPRC = 'B' "
            If _lAbreParentesis                   
                cFiltro += " SC5.C5_I_BLPRC = 'B' "
                _lAbreParentesis := .F.
            Else
                cFiltro += " OR SC5.C5_I_BLPRC = 'B' "
            EndIf
        EndIf
        
        If "B" $ MV_PAR33 // Bloqueio BonIficação
            //cFiltro += " AND C5_I_BLOQ = 'B' "
            If _lAbreParentesis                   
                cFiltro += " SC5.C5_I_BLOQ = 'B' "
                _lAbreParentesis := .F.
            Else
                cFiltro += " OR SC5.C5_I_BLOQ = 'B' "
            EndIf
        EndIf
                
        If ("C" $ MV_PAR33 .Or. "P" $ MV_PAR33 .Or. "B" $ MV_PAR33)
            cFiltro += " ) "
        EndIf
    EndIf
EndIf

// Filtro por código de evento comercial
// Código Evento
If !Empty(MV_PAR41) 
    cFiltro += " AND SC5.C5_I_EVENT  = '" + MV_PAR41 + "' " 
EndIf

// Filtro por data de liberação
// Dt Liberacao de -- MV_PAR39
If !Empty(MV_PAR39) .Or. !Empty(MV_PAR40)
    If MV_PAR39 == MV_PAR40
        cFiltro += " AND C9_DATALIB = '" + DToS(MV_PAR39) + "' "
    Else
        If Empty(MV_PAR39) 
        MV_PAR39 := CTOD("01/01/2000")
        EndIf
        
        If Empty(MV_PAR40) 
        MV_PAR40 := CTOD("31/12/2099")
        EndIf

        cFiltro += " AND C9_DATALIB BETWEEN '" + DToS(MV_PAR39) + "' AND '" + DToS(MV_PAR40) + "'"
    EndIf
EndIf

//Filtra Emissao da Nota
If !Empty(MV_PAR42) .Or. !Empty(MV_PAR43)
    If MV_PAR42 == MV_PAR43
        cFiltro += " AND SF2.F2_EMISSAO = '" + DToS(MV_PAR42) + "' "
    Else
        If Empty(MV_PAR42) 
            MV_PAR42 := CTOD("01/01/2000")
        EndIf
        
        If Empty(MV_PAR43) 
            MV_PAR43 := CTOD("31/12/2099")
        EndIf
        cFiltro += " AND SF2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR42) + "' AND '" + DToS(MV_PAR43) + "'"
    EndIf
EndIf

// Bloq. de carregamentro p/ Saldo ? 1-SIM, 2-NÃO, 3-Ambos
If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
    If MV_PAR44 == 1 //SIM
        cFiltro += " AND SC5.C5_I_BLSLD = 'S' "
    ElseIf MV_PAR44 == 2 //NÃO
        cFiltro += " AND SC5.C5_I_BLSLD  = 'N'  " 
    EndIf 
EndIf 

cFiltro += "%"        

//Aqui define expressao de filtro para caso usuario escolher parametro  
//de pedidos liberados ou todos e escolher motivo de codigo d e bloqueio

cFilBloqueio := "% 	LEFT JOIN " + retSqlName("SC9") + " SC9 ON SC6.C6_NUM = SC9.C9_PEDIDO "
cFilBloqueio += " AND SC6.C6_FILIAL = SC9.C9_FILIAL AND SC6.C6_ITEM = SC9.C9_ITEM AND SC6.C6_PRODUTO = SC9.C9_PRODUTO "
cFilBloqueio += " AND SC9.D_E_L_E_T_ =  ' ' "	

If MV_PAR23 == 1 //Estoque Bloqueado
    cFilBloqueio += " AND SC9.C9_BLEST = '02' "
ElseIf MV_PAR23 == 2 //Liberados
    cFilBloqueio += " AND SC9.C9_BLEST = ' ' "	
EndIf
cFilBloqueio += " LEFT JOIN " + retSqlName("ZZL") + " ZZL ON SUBSTR(SC9.C9_I_USLIB,3,6) = ZZL.ZZL_CODUSU "
cFilBloqueio += " AND ZZL.D_E_L_E_T_ =  ' ' "	

cFilBloqueio += "%" 

// IMPRIME PAGINA DE PARÂMETROS 
If ! Empty(MV_PAR06)
    _cTexto  := AllTrim(MV_PAR06) + "-" + Posicione("SB1",1,xFilial("SB1")+U_ItKey(MV_PAR06,"B1_COD"),"B1_DESC") // "MV_PAR06"	"De Produto"
    MV_PAR06 := _cTexto
EndIf

If ! Empty(MV_PAR07)
    _cTexto  := AllTrim(MV_PAR07) + "-" + Posicione("SB1",1,xFilial("SB1")+U_ItKey(MV_PAR07,"B1_COD"),"B1_DESC") // "MV_PAR07"	"Ate Produto"
    MV_PAR07 := _cTexto
EndIf

If ! Empty(MV_PAR08)
    _cTexto := AllTrim(MV_PAR08) + "-" + Posicione("SA1",1,xFilial("SA1")+U_ItKey(MV_PAR08,"A1_COD"),"A1_NOME") // "MV_PAR08"	"De Cliente"
    MV_PAR08 := _cTexto
EndIf

If ! Empty(MV_PAR10)
    _cTexto := AllTrim(MV_PAR10) + "-" + Posicione("SA1",1,xFilial("SA1")+U_ItKey(MV_PAR10,"A1_COD"),"A1_NOME") // "MV_PAR10"	"Ate Cliente"
    MV_PAR10 := _cTexto
EndIf

If ! Empty(MV_PAR30)
    _cTexto := ""
    If "1" $ MV_PAR30
        _cTexto += "1=Paletizada; "
    EndIf
    
    If "2" $ MV_PAR30
        _cTexto += "2=Batida; "
    EndIf
    
    If ! Empty(_cTexto)
        MV_PAR30 := AllTrim(MV_PAR30) + " - [" + _cTexto + "]"
    EndIf
EndIf

If ! Empty(MV_PAR31)
    _cTexto := ""
    If "A" $ MV_PAR31
        _cTexto += "A=Agendada; "
    EndIf
    
    If "I" $ MV_PAR31
        _cTexto += "I=Imediata; "
    EndIf
    
    If "P" $ MV_PAR31
        _cTexto += "P=Aguardando Agenda; "
    EndIf
    
    If "M" $ MV_PAR31
        _cTexto += " M=Agendada Multa; "
    EndIf
    
    If "R" $ MV_PAR31
        _cTexto += " R=Reagendar; "
    EndIf
    
    If "N" $ MV_PAR31
        _cTexto += " N=Reagendar c/Multa; "
    EndIf

    If "T" $ MV_PAR31
        _cTexto += " T=Agend. pelo Transp; "
    EndIf

    If ! Empty(_cTexto)  
        MV_PAR31 := AllTrim(MV_PAR31) + " - [" + _cTexto + "]"
    EndIf
EndIf

If ! Empty(MV_PAR33)
    _cTexto := ""
    If "S" $ MV_PAR33
        _cTexto += "S=Sem Bloqueio; "
    EndIf
    
    If "C" $ MV_PAR33
        _cTexto += "C=Com Bloqueio Credito; "
    EndIf
    
    If "P" $ MV_PAR33
        _cTexto += "P=Bloqueio Preço; "
    EndIf
    
    If "B" $ MV_PAR33
        _cTexto += "B=Bloqueio BonIficação. "
    EndIf
    
    If ! Empty(_cTexto)
        MV_PAR33 := AllTrim(MV_PAR33) + " - [" + _cTexto + "]"
    EndIf
EndIf

_cFiltro2 += "%"

If nOrdem =  1
   // Roda a query com base na tela de parâmetros iniciais
   // e cria tabela temporária.
   FWMsgRun(,{|oProc|  _aDadosRel := ROMS002Q(cFilBloqueio,cFiltro,oProc) },'Aguarde processamento, Hora Inicial: '+cTimeInicial,"Executando leitura do Banco de dados (SELECT)...")

   If Empty(_aDadosRel)
      U_ITMsg("Não existem dados para emissão do relatório","Atenção","Altere os filtros e tentenovamente",1)
      Return .F.
   EndIf
 
   _cArq := "ROMS002_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".xlsx"
   _cDir := AllTrim(GetTempPath())
   _cTitulo := ""

   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   
   aAdd(_aCab,{"Cod", 1 , 4 , .F.})
   aAdd(_aCab,{"Filial", 1 , 1 , .F.})
   aAdd(_aCab,{"Coordenador", 1 , 1 , .F.})
   aAdd(_aCab,{"Nome", 1 , 1 , .F.})
   aAdd(_aCab,{"Vendedor", 1 , 1 , .F.})
   aAdd(_aCab,{"Nome Vend.", 1 , 1 , .F.})
   aAdd(_aCab,{"Tipo Vendedor", 1 , 1 , .F.})
   aAdd(_aCab,{"Gerente", 1 , 1 , .F.})
   aAdd(_aCab,{"Nome", 1 , 1 , .F.})
   aAdd(_aCab,{"Regiao do Gerente", 1 , 1 , .F.})
   aAdd(_aCab,{"Pedido", 1 , 1 , .F.})
   aAdd(_aCab,{"Armazem", 1 , 1 , .F.})
   aAdd(_aCab,{"Pedido Portal", 1 , 1 , .F.})
   aAdd(_aCab,{"Codigo Pedido Broker", 1 , 1 , .F.})
   aAdd(_aCab,{"Tp Operacao", 1 , 1 , .F.})
   aAdd(_aCab,{"PV Vinculado", 1 , 1 , .F.})
   aAdd(_aCab,{"Cliente", 1 , 1 , .F.})
   aAdd(_aCab,{"Loja", 1 , 1 , .F.})
   aAdd(_aCab,{"Razao Social", 1 , 1 , .F.})
   aAdd(_aCab,{"Nome Fantasia", 1 , 1 , .F.})
   aAdd(_aCab,{"Grupo Cliente", 1 , 1 , .F.})
   aAdd(_aCab,{"Rede", 1 , 1 , .F.})
   aAdd(_aCab,{"CNPJ/CPF", 1 , 1 , .F.})
   aAdd(_aCab,{"Emissao do Pedido", 1 , 4 , .F.})
   aAdd(_aCab,{"Municipio", 1 , 1 , .F.})
   aAdd(_aCab,{"UF", 1 , 1 , .F.})
   aAdd(_aCab,{"Bairro", 1 , 1 , .F.})
   aAdd(_aCab,{"CEP", 1 , 1 , .F.})
   aAdd(_aCab,{"Descricao", 1 , 1 , .F.})
   aAdd(_aCab,{"Grupo de Produto", 1 , 1 , .F.})
   aAdd(_aCab,{"Entrega", 1 , 4 , .F.})
   aAdd(_aCab,{"Tp Entrega", 1 , 1 , .F.})
   aAdd(_aCab,{"Quantidade", 1 , 2 , .F.})
   aAdd(_aCab,{"Un.M", 1 , 1 , .F.})
   aAdd(_aCab,{"Qtd Ven 2UM Total", 1 , 2 , .F.})
   aAdd(_aCab,{"Qtd Ven 2 UM", 1 , 2 , .F.})
   aAdd(_aCab,{"Seg.UM", 1 , 1 , .F.})
   aAdd(_aCab,{"Prc Unitario", 1 , 2 , .F.})
   aAdd(_aCab,{"Preco Net", 1 , 2 , .F.})
   aAdd(_aCab,{"Preco Tab", 1 , 2 , .F.})
   aAdd(_aCab,{"Faixa Peso" , 1 , 2 , .F.})
   aAdd(_aCab,{"Valor Total", 1 , 2, .F.})
   aAdd(_aCab,{"Peso Bruto Total(KG)", 1 , 2 , .F.})
   aAdd(_aCab,{"Peso Bruto(KG)", 1 , 2 , .F.})
   aAdd(_aCab,{"Ped.Cli", 1 , 1 , .F.})
   aAdd(_aCab,{"Carga Total Ped", 1 , 1 , .F.})
   aAdd(_aCab,{"Carga Total Item", 1 , 1 , .F.})
   aAdd(_aCab,{"Qtde por Pallet", 1 , 2 , .F.})
   If MV_PAR21 = 2//ANALITICO 
      aAdd(_aCab,{"Veiculo Pedido", 1 , 1 , .F.})
      aAdd(_aCab,{"Veiculo Item", 1 , 1 , .F.})
   EndIf
   aAdd(_aCab,{"Tp Carga", 1 , 1 , .F.})
   aAdd(_aCab,{"Senha", 1 , 1 , .F.})
   aAdd(_aCab,{"Hr. Receb", 1 , 1 , .F.})
   aAdd(_aCab,{"Doca", 1 , 1 , .F.})
   aAdd(_aCab,{"Qtd Chapa", 1 , 1 , .F.})
   aAdd(_aCab,{"Utl Chp Cli", 1 , 1 , .F.})
   aAdd(_aCab,{"Obs Pedido", 1 , 1 , .F.})
   aAdd(_aCab,{"Obs Nota", 1 , 1 , .F.})
   aAdd(_aCab,{"Tp PV Op Tri?", 1 , 1 , .F.})
   aAdd(_aCab,{"PV Remessa", 1 , 1 , .F.})
   aAdd(_aCab,{"PV Faturament", 1 , 1 , .F.})
   aAdd(_aCab,{"Chep", 1 , 1 , .F.})
   aAdd(_aCab,{"Troca NF?", 1 , 1 , .F.})
   aAdd(_aCab,{"Grupo Mix", 1 , 1 , .F.})
   aAdd(_aCab,{"Filial Fat."  , 1 , 1 , .F.})
   aAdd(_aCab,{"Filial Carr." , 1 , 1 , .F.})
   aAdd(_aCab,{"Situacao"  , 1 , 1 , .F.})
   aAdd(_aCab,{"Cidade Entrega" , 1 , 1 , .F.})
   aAdd(_aCab,{"UF Entrega"  , 1 , 1 , .F.})
   aAdd(_aCab,{"Cond.Pgto"  , 1 , 1 , .F.})
   aAdd(_aCab,{"Descr.Cond.Pgto", 1 , 1 , .F.})
   aAdd(_aCab,{"Tipo Frete"  , 1 , 1 , .F.})
   aAdd(_aCab,{"$ Desconto"  , 1 , 2 , .F.})
   aAdd(_aCab,{"Supervisor" , 1 , 1 , .F.})
   aAdd(_aCab,{"Nome Supervisor", 1 , 1 , .F.})
   aAdd(_aCab,{"Nota Fiscal" , 1 , 1 , .F.})
   aAdd(_aCab,{"Emissao NFe"  , 1 , 4 , .F.})
   aAdd(_aCab,{"Transportadora" , 1 , 1 , .F.})
   aAdd(_aCab,{"Nfe Adquiren" , 1 , 1 , .F.})
   aAdd(_aCab,{"Ser Adquiren" , 1 , 1 , .F.})
   aAdd(_aCab,{"Data Nfe Adq" , 1 , 4 , .F.})
   aAdd(_aCab,{"Dt.Entrega Canhoto" , 1 , 4 , .F.})
   aAdd(_aCab,{"FAMILIA", 1 , 1 , .F.})
   aAdd(_aCab,{"MARCA", 1 , 1 , .F.})
   aAdd(_aCab,{"MES"   , 1 , 1 , .F.})
   aAdd(_aCab,{"CLIENTE GRUPO" , 1 , 1 , .F.})
   aAdd(_aCab,{"TABELA"  , 1 , 1 , .F.})
   aAdd(_aCab,{"SIT AGENDA", 1 , 1 , .F.})
   aAdd(_aCab,{"LIBERADO" , 1 , 1 , .F.})
   aAdd(_aCab,{"DT Liberacao" , 1 , 4 , .F.})
   aAdd(_aCab,{"Dt Carga" , 1 , 4 , .F.})
   aAdd(_aCab,{"O.C."  , 1 , 1 , .F.})
   aAdd(_aCab,{"Dt Prev.Est." , 1 , 4 , .F.})      
   aAdd(_aCab,{"Dt.Suger.Agend." , 1 , 4 , .F.})    
   aAdd(_aCab,{"Arq. Operador Logistico" , 1 , 1 , .F.})
   aAdd(_aCab,{"Tab." , 1 , 1 , .F.})
   aAdd(_aCab,{"Desc.Tab.Preco" , 1 , 1 , .F.})
   aAdd(_aCab,{"Rem/Vda Ped" , 1 , 1 , .F.})     
   aAdd(_aCab,{"Rem/Vda CodCli" , 1 , 1 , .F.})   
   aAdd(_aCab,{"Rem/Vda Lj." , 1 , 1 , .F.})    
   aAdd(_aCab,{"Rem/Vda Razo Social" , 1 , 1 , .F.})
   aAdd(_aCab,{"Rem/Vda Fantasia" , 1 , 1 , .F.})  
   aAdd(_aCab,{"Rem/Vda Nfe" , 1 , 1 , .F.})    
   aAdd(_aCab,{"Rem/Vda Serie" , 1 , 1 , .F.})    
   aAdd(_aCab,{"Rem/Vda Emissão" , 1 , 4 , .F.})   
   aAdd(_aCab,{"Rem/Vda Chave NFE" , 1 , 1 , .F.})  
   aAdd(_aCab,{"Qtde S/ Abat 1um" , 1 , 2 , .F.}) 
   aAdd(_aCab,{"Qtde S/ Abat 2um" , 1 , 2 , .F.})  
   aAdd(_aCab,{"Valor Total S/ Abat" , 1 , 2 , .F.})
   aAdd(_aCab,{"Qtde Devolvida 1um" , 1 , 2 , .F.})  
   aAdd(_aCab,{"Qtde Devolvida 2um" , 1 , 2 , .F.}) 
   aAdd(_aCab,{"Vlr Devolvida" , 1 , 2 , .F.})   
   aAdd(_aCab,{"Assistente Comercial Resp." , 1 , 1 , .F.})
   aAdd(_aCab,{"Usuario de Liberacao P.V." , 1 , 1 , .F.})   
   aAdd(_aCab,{"Local de Embarque" , 1 , 1 , .F.})       
   aAdd(_aCab,{"Dias de Viagem" , 1 , 2 , .F.})        
   aAdd(_aCab,{"Dias Operacional" , 1 , 2 , .F.})        
   aAdd(_aCab,{"Lead Time" , 1 , 2 , .F.})            
   aAdd(_aCab,{"Grupo Mix", 1 , 1 , .F.}) 
   aAdd(_aCab,{"Ult Usr Dt Entrega" , 1 , 1 , .F.}) 
   aAdd(_aCab,{"Ult Usr Tp Agend." , 1 , 1 , .F.})  
   aAdd(_aCab,{"Justificativas" , 1 , 1 , .F.})    
   aAdd(_aCab,{"% Contrato" , 1 , 2 , .F.})      
   aAdd(_aCab,{"Classificacao Entrega" , 1 , 1 , .F.})
   aAdd(_aCab,{"Shelf Life do Produto" , 1 , 1 , .F.})
   aAdd(_aCab,{"Mesorregiao" , 1 , 1 , .F.})        
   aAdd(_aCab,{"Microrregiao" , 1 , 1 , .F.})       
   aAdd(_aCab,{"Evento Comercial" , 1 , 1 , .F.})      
   aAdd(_aCab,{"Dt prev de entrega Cliente" , 1 , 1 , .F.}) 
   aAdd(_aCab,{"Dt entrega Cliente" , 1 , 4 , .F.})     
   aAdd(_aCab,{"TROCA FIL" , 1 , 4 , .F.})         
   aAdd(_aCab,{"TROCA PED" , 1 , 1 , .F.})         
   aAdd(_aCab,{"TROCA NFE" , 1 , 1 , .F.})         
   aAdd(_aCab,{"TROCA SERIE" , 1 , 1 , .F.})         
   aAdd(_aCab,{"TROCA RAZAO SOCIAL" , 1 , 1 , .F.})    
   aAdd(_aCab,{"TROCA FANTASIA" , 1 , 1 , .F.}) 
   aAdd(_aCab,{"Produto", 1 , 1 , .F.})
   aAdd(_aCab,{"Preco Min", 1 , 2 , .F.})
   aAdd(_aCab,{"Grupo dos PVs", 1 , 2 , .F.})
   aAdd(_aCab,{"Qtd Agendamento", 1 , 2 , .F.}) //C5_I_QTDA
   aAdd(_aCab,{"PV Original", 2 , 1 , .F.})     //C5_I_PEDOR
   aAdd(_aCab,{"PV Gerado pelo Desm",2,1,.F.})  //C5_I_PODES
   If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
      aAdd(_aCab,{"Bloq. de carregamentro p/ Saldo",2,1,.F.})  //C5_I_BLSLD
   EndIf  
   
   aAdd(_aCab,{"Código Kit",2,1,.F.}) 
   aAdd(_aCab,{"Preço da Tabela",1,2,.F.})

   cETimeInicial:=Time()
   
   _cTitulo:="Relatorio de Pedidos Geral - Por coordenador - Hora Inicial: "+cTimeInicial+" - Hora Final: "+Time()

   SET DATE FORMAT TO "DD/MM/YYYY"
                      //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan ,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX,oProc)   
   FWMsgRun(,{|oProc| U_ITGEREXCEL(_cArq    ,_cDir      ,_cTitulo,"Relatorio",_aCab      ,_aDadosRel,.F.       ,          ,        ,            ,            ,          ,            ,.T.   ,oProc)  },'Aguarde processamento, Hora Inicial: '+cTimeInicial,"H.I.:"+cETimeInicial+", Gerando Excel: "+_cDir+_cArq)
   SET DATE FORMAT TO "DD/MM/YY"

    U_ITMsg("Relatorio gerado com Sucesso: "+CRLF+_cDir+_cArq+CRLF+;
            "Hora Inicial: "+cTimeInicial+CRLF+;
            "Hora Ini Excel: "+cETimeInicial+CRLF+;
            "Hora Final: "+TIME();
            ,"Atenção",,2)

   oReport:SetPreview(.F.)

   Return .T.
Else
    //VerIfica qual ordem usuario definiu
    If nOrdem == 1 //1-COORDENADOR

        cOrdem := "% SC5.C5_VEND2,SC5.C5_VEND1,SC6.C6_CLI,SC5.C5_I_DTENT %"	
        //Habilita Secoes
        oSC5FIL_1:Enable()
        oSC5_1:Enable()
        oSC5A_1:Enable()
        oSC5B_1:Enable()		
        
        //Define break para Filial para sumarizar campos
        DEFINE BREAK oBrkFil OF oSC5FIL_1 WHEN oSC5FIL_1:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}

        //Define Break - Quebra por cliente, mas nao sumariza
        DEFINE BREAK oBrkCli OF oSC5B_1 WHEN oSC5B_1:Cell("C6_CLI")	
        //Define funcoes de soma para secao
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkSup //coloca o Break aqui para sumarizar a secao do supervisor 
        DEFINE FUNCTION FROM oSC5B_1:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkSup
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkSup
        DEFINE FUNCTION FROM oSC5B_1:Cell("PESTOTAL") FUNCTION SUM BREAK oBrkSup

        //Define funcoes de soma para secao
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkCoord //coloca o Break aqui para sumarizar a secao do Coordenador
        DEFINE FUNCTION FROM oSC5B_1:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkCoord
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkCoord
        DEFINE FUNCTION FROM oSC5B_1:Cell("PESTOTAL") FUNCTION SUM BREAK oBrkCoord

        //define funcoes novamente para sumarizar por filial
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
        DEFINE FUNCTION FROM oSC5B_1:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        DEFINE FUNCTION FROM oSC5B_1:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        DEFINE FUNCTION FROM oSC5B_1:Cell("PESTOTAL") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
    ElseIf nOrdem == 2 //ORDEM POR DATA DE ENTREGA

        U_ITLOGACS("ROMS002-2")

        If MV_PAR21 == 1//SINTETICO  - AWF
            cOrdem := "% SC5.C5_I_DTENT,SC6.C6_NUM %"	
            //Habilita Secoes
            oSC5FIL_2:Enable()
            oSC5_2:Enable()
            oSC5A_2:Enable()	

            //Define break para Filial para sumarizar campos
            DEFINE BREAK oBrkFil OF oSC5FIL_2 WHEN oSC5FIL_2:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}
            
            //Define Break - Quebra por cliente, mas nao sumariza
            DEFINE BREAK oBrkPed OF oSC5A_2 WHEN oSC5A_2:Cell("C5_NUM")

            //Define funcoes de soma para secao
            DEFINE FUNCTION FROM oSC5A_2:Cell("PESBRUTO")    FUNCTION SUM BREAK oBrkPed
            
            //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5A_2:Cell("PESBRUTO")  FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        Else//ANALITICO
            cOrdem := "% SC5.C5_I_DTENT,SC6.C6_NUM %"	
            //Habilita Secoes
            oSC5FIL_2:Enable()
            oSC5_2:Enable()
            oSC5A_2:Enable()	
            
            //Define break para Filial para sumarizar campos
            DEFINE BREAK oBrkFil OF oSC5FIL_2 WHEN oSC5FIL_2:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}
            
            //Define Break - Quebra por cliente, mas nao sumariza
            DEFINE BREAK oBrkPed OF oSC5A_2 WHEN oSC5A_2:Cell("C5_NUM")

            //Define funcoes de soma para secao
            DEFINE FUNCTION FROM oSC5A_2:Cell("C6_QTDVEN")   FUNCTION SUM BREAK oBrkPed
            DEFINE FUNCTION FROM oSC5A_2:Cell("VLRPENDEN")   FUNCTION SUM BREAK oBrkPed
            DEFINE FUNCTION FROM oSC5A_2:Cell("C6_UNSVEN")   FUNCTION SUM BREAK oBrkPed
            DEFINE FUNCTION FROM oSC5A_2:Cell("PESBRUTO")    FUNCTION SUM BREAK oBrkPed
            
            //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5A_2:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5A_2:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_2:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_2:Cell("PESBRUTO")  FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        EndIf
    ElseIf nOrdem == 3 //ORDEM POR PRODUTO
        U_ITLOGACS("ROMS002-3")
            //Define break para Filial para sumarizar campos
        DEFINE BREAK oBrkFil OF oSC5FIL_3 WHEN oSC5FIL_3:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}

        //Define funcoes de soma para secao PRODUTO  - Sintetico
        If MV_PAR21 == 1 //SINTETICO
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_QTDVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_QTDENT")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_UNSVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_3:Cell("QTDPENDEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_3:Cell("VLRPENDEN")   FUNCTION SUM 
            
                //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_QTDENT") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_3:Cell("QTDPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_3:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_3:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		
        Else
            //Define funcoes de soma para secao Produto  - Analitico
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_QTDVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_UNSVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5A_3:Cell("VLRPENDEN")   FUNCTION SUM 

                //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5A_3:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		
            
            DEFINE BREAK oBrkDtEntr OF oSC5A_3 WHEN oSC5A_3:CELL("C5_I_DTENT") TITLE {|| "TOTAL DATA DE ENTREGA " }
            
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkDtEntr NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5A_3:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkDtEntr NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_3:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkDtEntr NO END REPORT NO END Section 
        EndIf

        cOrdem := "% SC6.C6_PRODUTO,SC6.C6_NUM,SC6.C6_ITEM %"
        oSC5FIL_3:Enable()
        oSC5_3:Enable()

    ElseIf nOrdem == 4 //ORDEM POR REDE

        U_ITLOGACS("ROMS002-4")
            //Define break para Filial para sumarizar campos
        DEFINE BREAK oBrkFil OF oSC5FIL_4 WHEN oSC5FIL_4:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}

        //Define funcoes de soma para secao 	
        If MV_PAR21 == 1 //SINTETICO

            oSC5S_4:Enable()	
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_QTDVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_QTDENT")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_UNSVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_4:Cell("QTDPENDEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5S_4:Cell("VLRPENDEN")   FUNCTION SUM 
                //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_QTDENT") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_4:Cell("QTDPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_4:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_4:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		
        Else	
            oSC5A_4:Enable()	
            DEFINE FUNCTION FROM oSC5A_4:Cell("C6_QTDVEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5A_4:Cell("VLRPENDEN")   FUNCTION SUM 
            DEFINE FUNCTION FROM oSC5A_4:Cell("C6_UNSVEN")   FUNCTION SUM 

                //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5A_4:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5A_4:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_4:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		
        EndIf

        cOrdem := "% SA1.A1_GRPVEN %"
        oSC5FIL_4:Enable()
        oSC5_4:Enable()	

    ElseIf nOrdem == 5

        U_ITLOGACS("ROMS002-5")
            //Define break para Filial para sumarizar campos
        DEFINE BREAK oBrkFil OF oSC5FIL_5 WHEN oSC5FIL_5:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}
        //Define funcoes de soma para secao
        oSC5_5A:Enable()		
        If MV_PAR21 == 1 //SINTETICO
            oSC5S_5:Enable()	
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_QTDVEN")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_QTDENT")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_UNSVEN")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5S_5:Cell("QTDPENDEN")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5S_5:Cell("VLRPENDEN")   FUNCTION SUM BREAK oBrkMun
            
                //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_QTDENT") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_5:Cell("QTDPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_5:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5S_5:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		
            
        Else // ANALITICO	
            oSC5A_5:Enable()	
            DEFINE FUNCTION FROM oSC5A_5:Cell("C6_QTDVEN")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5A_5:Cell("VLRPENDEN")   FUNCTION SUM BREAK oBrkMun
            DEFINE FUNCTION FROM oSC5A_5:Cell("C6_UNSVEN")   FUNCTION SUM BREAK oBrkMun
            
            //define funcoes novamente para sumarizar por filial
            DEFINE FUNCTION FROM oSC5A_5:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
            DEFINE FUNCTION FROM oSC5A_5:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
            DEFINE FUNCTION FROM oSC5A_5:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 		

            
        EndIf

        cOrdem := "% SA1.A1_GRPVEN %"
        oSC5FIL_5:Enable()
        oSC5_5:Enable()	
    ElseIf nOrdem == 6
        U_ITLOGACS("ROMS002-6")
            //Define break para Filial para sumarizar campos
        DEFINE BREAK oBrkFil OF oSC5FIL_6 WHEN oSC5FIL_6:CELL("C6_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}

        //Define funcoes de soma para secao
        oSC5FIL_6:Enable()			
        oSC5_6:Enable()			

            //define funcoes novamente para sumarizar por filial
        DEFINE FUNCTION FROM oSC5_6:Cell("C6_QTDVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
        DEFINE FUNCTION FROM oSC5_6:Cell("C6_QTDENT") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        DEFINE FUNCTION FROM oSC5_6:Cell("QTDPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section 
        DEFINE FUNCTION FROM oSC5_6:Cell("VLRPENDEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
        DEFINE FUNCTION FROM oSC5_6:Cell("C6_UNSVEN") FUNCTION SUM BREAK oBrkFil NO END REPORT NO END Section
    EndIf

    //Define query para ordem Coordenador

    If nOrdem == 1 // POR COORDENADOR - ORDEM 01
        _cAlias := "QRY1"
        _cCposSD2 := "%"

        //CAMPOS DE SUB SELECT DO SD2
        _cCposSD2 += " (SELECT NVL(SUM ( (D2_QTDEDEV)), 0) "
        _cCposSD2 += "    FROM " + RetSqlName("SD2") + " SD2 "
        _cCposSD2 += "   WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL "
        _cCposSD2 += "     AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
        _cCposSD2 += "     AND SD2.D2_LOJA    = SF2.F2_LOJA "
        _cCposSD2 += "     AND SD2.D2_DOC     = SF2.F2_DOC "
        _cCposSD2 += "     AND SD2.D2_SERIE   = SF2.F2_SERIE "
        _cCposSD2 += "     AND SD2.D2_COD     = SC6.C6_PRODUTO "
        _cCposSD2 += "     AND SD2.D_E_L_E_T_ = ' ') D2_QTDEDEV, "
        _cCposSD2 += " (SELECT NVL(SUM ( (D2_VALDEV)), 0) "
        _cCposSD2 += "    FROM " + RetSqlName("SD2") + " SD2 "
        _cCposSD2 += "   WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL "
        _cCposSD2 += "     AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
        _cCposSD2 += "     AND SD2.D2_LOJA    = SF2.F2_LOJA "
        _cCposSD2 += "     AND SD2.D2_DOC     = SF2.F2_DOC "
        _cCposSD2 += "     AND SD2.D2_SERIE   = SF2.F2_SERIE "
        _cCposSD2 += "     AND SD2.D2_COD     = SC6.C6_PRODUTO "
        _cCposSD2 += "     AND SD2.D_E_L_E_T_ = ' ') D2_VALDEV, "

        _cCposSD2 += "(SELECT NVL(SUM (D1_QTSEGUM), 0) "
        _cCposSD2 += "    FROM " + RetSqlName("SD1") + " SD1, " + RetSqlName("SD2") + " SD2"
        _cCposSD2 += "   WHERE SD2.D2_FILIAL    = SF2.F2_FILIAL "
        _cCposSD2 += "     AND SD2.D2_CLIENTE   = SF2.F2_CLIENTE "
        _cCposSD2 += "     AND SD2.D2_LOJA      = SF2.F2_LOJA "
        _cCposSD2 += "     AND SD2.D2_DOC       = SF2.F2_DOC "
        _cCposSD2 += "     AND SD2.D2_SERIE     = SF2.F2_SERIE "
        _cCposSD2 += "     AND SD2.D2_COD       = SC6.C6_PRODUTO "
        _cCposSD2 += "      AND SD1.D1_FILIAL   = SD2.D2_FILIAL "
        _cCposSD2 += "      AND SD1.D1_FORNECE  = SD2.D2_CLIENTE "
        _cCposSD2 += "      AND SD1.D1_LOJA     = SD2.D2_LOJA "
        _cCposSD2 += "      AND SD1.D1_DTDIGIT >= SD2.D2_EMISSAO "
        _cCposSD2 += "      AND SD1.D1_NFORI    = SD2.D2_DOC "
        _cCposSD2 += "      AND SD1.D1_SERIORI  = SD2.D2_SERIE "
        _cCposSD2 += "      AND SD1.D1_COD      = SD2.D2_COD "
        _cCposSD2 += "      AND SD1.D1_ITEMORI  = SD2.D2_ITEM "
        _cCposSD2 += "      AND SD1.D1_TIPO     = 'D' "
        _cCposSD2 += "      AND SD1.D1_TES     <> ' ' "
        _cCposSD2 += "      AND SD1.D_E_L_E_T_  = ' ') D1_QTSEGUM " 

        _cCposSD2 += "%"

        BEGIN REPORT QUERY oSC5FIL_1
        BeginSql alias "QRY1"   	   	
        SELECT 
                SC5.R_E_C_N_O_ SC5RECNO,
                SC5.C5_NUM,
                SC6.C6_LOCAL,
                SC5.C5_I_PEVIN, 
                SC6.C6_ITEM,
                SC5.C5_EMISSAO,
                SC5.C5_I_DTENT, 
                SC5.C5_CLIENT C6_CLI, 
                SC5.C5_LOJAENT C6_LOJA,
                SC5.C5_NOTA,
                SA1.A1_NOME,
                SA1.A1_NREDUZ,
                SA1.A1_I_CCHEP,			
                SA1.A1_CEP,
                SA1.A1_I_CLABC,
                SC6.C6_PRODUTO,
                SC6.C6_QTDVEN,
                SC6.C6_PRCVEN,
                SC6.C6_VALOR,
                SC6.C6_UM,
                SC6.C6_SEGUM,
                SC6.C6_QTDENT,
                SC6.C6_I_PDESC,
                SC6.C6_I_PRMIN,
                SC6.C6_I_VLIBB,
                SB1.B1_I_DESCD,
                SB1.B1_COD,
                SC5.C5_VEND1,
                SC5.C5_I_V1NOM,
                SC5.C5_VEND2,
                SC5.C5_I_V2NOM,
                SC5.C5_VEND3,
                SC5.C5_I_V3NOM,
                SA3.A3_COD,
                SA3.A3_NOME,
                SA3.A3_SUPER,
                ACY.ACY_DESCRI,
                ACY.ACY_GRPVEN,
                SC6.C6_UNSVEN,
                (SELECT SUM(C6_UNSVEN) FROM %Table:SC6% SC6T WHERE SC6T.%notDel%  AND SC6T.C6_FILIAL = SC5.C5_FILIAL  AND SC6T.C6_NUM = SC5.C5_NUM ) C6_UNSVENTOT,//Qtd Ven 2 UM ,
                SC6.C6_FILIAL AS C6_FILIAL,
                SC6.C6_QTDLIB,
                SC6.C6_NUM,
                SC6.C6_I_DQESP,
                SC6.C6_I_KIT,  		   
                SA1.A1_CGC,
                SA1.A1_MUN,
                SA1.A1_BAIRRO,
                SA1.A1_EST,
                SA1.A1_I_GRDES,
                    SA1.A1_I_GRCLI,
                    SA1.A1_I_SHLFP,
                SC6.C6_PEDCLI,
                (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                (SB1.B1_PESBRU * SC6.C6_QTDVEN) PESTOTAL,
                SC5.C5_I_PESBR,
                SC5.C5_I_TIPCA,
                SC5.C5_I_AGEND,
                SC5.C5_I_SENHA,
                SC5.C5_I_HOREN,
                SC5.C5_I_DOCA,
                SC5.C5_I_CHAPA,
                SC5.C5_I_CHPCL,
                SC5.C5_I_OBPED,
                SC5.C5_MENNOTA,
                    SC5.C5_I_OPER,
                SC5.C5_I_TRCNF,  
                    SC5.C5_I_FILFT,  
                    SC5.C5_I_FLFNC,
                    SC5.C5_I_EVENT,
                SC5.C5_I_IDPED,
                SC5.C5_FILIAL,
                SBM.BM_DESC,
                ZA1.ZA1_DESCRI,
                ZA3.ZA3_DESCRI,
                ZZ6.ZZ6_DESCRO,
                SZW.ZW_TABELA,
                SC5.C5_I_OPTRI,
                SC5.C5_I_PVREM,
                SC5.C5_I_PVFAT, 			
                SC5.C5_ASSCOD,
                SC5.C5_ASSNOM,
                SC5.C5_I_LOCEM,
                SC5.C5_I_QTDA,
                    Case 
                        WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                        WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                        WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLOQ   = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                        WHEN SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ   = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                        WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC  = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                        WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                        WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                        WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ  = 'B' THEN 'BLQ BONIf'
                    END AS SITUACAO,
                    SC5.C5_CONDPAG,
                    SC5.C5_TPFRETE,
                    SE4.E4_DESCRI,
                SC5.C5_DESCONT,  
                SC5.C5_VEND4, 
                SF2.F2_EMISSAO,
                SF2.F2_I_NTRAN,
                SF2.F2_I_NTRIA, 
                SF2.F2_I_STRIA,
                SF2.F2_I_DTRIA,
                SF2.F2_I_DTRC,  
                SF2.F2_CHVNFE, 
                SF2.F2_I_PENCL,
                SF2.F2_I_DENCL,
                SC5.C5_LIBEROK, DAI.DAI_DATA, DAI.DAI_COD, SC5.C5_I_DTPRV, SC5.C5_I_DTSAG, SC5.C5_I_ARQOP,
                SC5.C5_I_TAB, DA0.DA0_DESCRI, SC6.C6_I_FXPES, C6_I_VLTAB,
                SA32.A3_NOME AS A32_NOME,
                SA3.A3_TIPO,
                SC5.C5_VEND2 AS ORDER_VEND2,
                SC5.C5_VEND3,
                SC9.C9_I_USLIB,
                ZZL.ZZL_NOME,
                SC9.C9_DATALIB,
                CC2.CC2_I_MESO,
                CC2.CC2_I_MICR,
                SC5.C5_I_PDPR,
                SC5.C5_I_FLFNC,
                SC5.C5_I_FILFT,
                SC5.C5_I_PDFT,
                SC5.C5_I_NOME,
                SC5.C5_I_FANTA,
                Z21.Z21_NOME,
                Z22.Z22_NOME,
                ZY4.ZY4_DESCRI,
                ZEL.ZEL_DESCRI,
                SZW.ZW_PEDIMPO,
                ZAM.ZAM_REGCOD,
                SC5R.C5_FILIAL  R_C5_FILIAL,
                SC5R.C5_NUM     R_C5_NUM,
                SC5R.C5_CLIENT  R_C5_CLIENT, 
                SC5R.C5_LOJAENT R_C5_LOJAENT,
                SC5R.C5_NOTA    R_C5_NOTA,
                SA1R.A1_NOME    R_A1_NOME,
                SA1R.A1_NREDUZ  R_A1_NREDUZ,
                SF2R.F2_SERIE   R_F2_SERIE,
                SF2R.F2_EMISSAO R_F2_EMISSAO,
                SF2R.F2_I_NTRAN R_F2_I_NTRAN,
                SF2R.F2_I_NTRIA R_F2_I_NTRIA, 
                SF2R.F2_I_STRIA R_F2_I_STRIA,
                SF2R.F2_I_DTRIA R_F2_I_DTRIA,
                SF2R.F2_I_DTRC  R_F2_I_DTRC,  
                SF2R.F2_CHVNFE  R_F2_CHVNFE, 
                SC5F.C5_FILIAL  F_C5_FILIAL,
                SC5F.C5_I_FLFNC F_C5_I_FLFNC,
                SC5F.C5_NUM     F_C5_NUM,
                SC5F.C5_I_PDPR  F_C5_I_PDPR,
                SC5F.C5_CLIENT  F_C5_CLIENT,
                SC5F.C5_LOJAENT F_C5_LOJA,
                SC5F.C5_NOTA    F_C5_NOTA,
                SA1F.A1_NOME    F_A1_NOME,
                SA1F.A1_NREDUZ  F_A1_NREDUZ,
                SC5F.C5_SERIE   F_C5_SERIE,
                SF2F.F2_SERIE   F_F2_SERIE,
                SF2F.F2_EMISSAO F_F2_EMISSAO,
                SF2F.F2_I_NTRAN F_F2_I_NTRAN,
                SF2F.F2_I_NTRIA F_F2_I_NTRIA, 
                SF2F.F2_I_STRIA F_F2_I_STRIA,
                SF2F.F2_I_DTRIA F_F2_I_DTRIA,
                SF2F.F2_I_DTRC  F_F2_I_DTRC, 
                SF2F.F2_CHVNFE  F_F2_CHVNFE,   
                SC5T.C5_FILIAL  T_C5_FILIAL,
                SC5T.C5_I_FILFT T_C5_I_FILFT,
                SC5T.C5_NUM     T_C5_NUM,
                SC5T.C5_I_PDFT  T_C5_I_PDFT ,
                SC5T.C5_CLIENT  T_C5_CLIENT, 
                SC5T.C5_LOJAENT T_C5_LOJA,
                SC5T.C5_NOTA    T_C5_NOTA,
                SA1T.A1_NOME    T_A1_NOME,
                SA1T.A1_NREDUZ  T_A1_NREDUZ,
                SC5T.C5_SERIE   T_C5_SERIE,
                SF2T.F2_SERIE   T_F2_SERIE,
                SF2T.F2_EMISSAO T_F2_EMISSAO,
                SF2T.F2_I_NTRAN T_F2_I_NTRAN,
                SF2T.F2_I_NTRIA T_F2_I_NTRIA, 
                SF2T.F2_I_STRIA T_F2_I_STRIA,
                SF2T.F2_I_DTRIA T_F2_I_DTRIA,
                SF2T.F2_I_DTRC  T_F2_I_DTRC,  
                SF2T.F2_CHVNFE  T_F2_CHVNFE, 
                SC5V.C5_FILIAL  V_C5_FILIAL,
                SC5V.C5_NUM     V_C5_NUM,
                SC5V.C5_CLIENT  V_C5_CLIENT, 
                SC5V.C5_LOJAENT V_C5_LOJAENT,
                SC5V.C5_NOTA    V_C5_NOTA,
                SA1V.A1_NOME    V_A1_NOME,
                SA1V.A1_NREDUZ  V_A1_NREDUZ,
                SF2V.F2_SERIE   V_F2_SERIE,
                SF2V.F2_EMISSAO V_F2_EMISSAO,
                SF2V.F2_I_NTRAN V_F2_I_NTRAN,
                SF2V.F2_I_NTRIA V_F2_I_NTRIA, 
                SF2V.F2_I_STRIA V_F2_I_STRIA,
                SF2V.F2_I_DTRIA V_F2_I_DTRIA,
                SF2V.F2_I_DTRC  V_F2_I_DTRC,  
                SF2V.F2_CHVNFE  V_F2_CHVNFE, 
                SM0.M0_FILIAL,
                (
                    SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                    FROM (
                            SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                            FROM %Table:ZY3% ZY3
                            WHERE ZY3.%notDel%
                                AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                            GROUP BY ZY3_FILFT,ZY3_NUMPV 
                            ) ZY3
                    LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                    WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                    AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                )  AS USR_DTENT,
                (
                    SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                    FROM (
                            SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                            FROM %Table:ZY3% ZY3
                            WHERE ZY3.%notDel%
                                AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                            GROUP BY ZY3_FILFT,ZY3_NUMPV 
                            ) ZY3
                    LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                    WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                    AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                )  AS USR_TPAGEN,
                ZY3_2.ZY3_JUSCOD,
                ZY3_2.ZY5_DESCR,
                %exp:_cCposSD2%//SE For POR MAIS CAMPOS DEIXE ESSE SEMPRE POR ULTIMO
            FROM 
                %Table:SC5% SC5
                JOIN %Table:SC6% SC6 ON SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM
                %exp:cFilBloqueio%
                JOIN %Table:SA1% SA1  ON SA1.A1_FILIAL  = ' ' AND SA1.A1_COD      = SC5.C5_CLIENT AND SA1.A1_LOJA = SC5.C5_LOJAENT
                JOIN %Table:SB1% SB1  ON SB1.B1_FILIAL  = ' ' AND SB1.B1_COD      = SC6.C6_PRODUTO
                JOIN %Table:SA3% SA3  ON SA3.A3_FILIAL  = ' ' AND SA3.A3_COD      = SC5.C5_VEND1			   
                LEFT JOIN %Table:CC2% CC2  ON CC2.CC2_FILIAL = ' ' AND CC2.CC2_EST     = SA1.A1_EST     AND CC2.CC2_CODMUN = SA1.A1_COD_MUN AND CC2.%notDel%
                LEFT JOIN %Table:SBM% SBM  ON SBM.BM_FILIAL  = ' ' AND SB1.B1_GRUPO    = SBM.BM_GRUPO   AND SBM.%notDel%	
                LEFT JOIN %Table:ACY% ACY  ON ACY.ACY_FILIAL = ' ' AND SA1.A1_GRPVEN   = ACY.ACY_GRPVEN AND ACY.%notDel%		
                LEFT JOIN %Table:SE4% SE4  ON SE4.E4_FILIAL  = ' ' AND SE4.E4_CODIGO   = SC5.C5_CONDPAG AND SE4.%notDel%
                LEFT JOIN %Table:ZA1% ZA1  ON ZA1.ZA1_FILIAL = ' ' AND ZA1.ZA1_COD     = SB1.B1_I_NIV2  AND ZA1.ZA1_CDGRUP = SB1.B1_GRUPO  AND ZA1.%notDel%	
                LEFT JOIN %Table:ZA3% ZA3  ON ZA3.ZA3_FILIAL = ' ' AND ZA3.ZA3_COD     = SB1.B1_I_NIV4  AND ZA3.%notDel%
                LEFT JOIN %Table:ZZ6% ZZ6  ON ZZ6.ZZ6_FILIAL = ' ' AND ZZ6.ZZ6_CODIGO  = SA1.A1_I_GRCLI AND ZZ6.%notDel% 
                LEFT JOIN %Table:DA0% DA0  ON DA0.DA0_FILIAL = ' ' AND DA0.DA0_CODTAB  = SC5.C5_I_TAB   AND DA0.%notDel%
                LEFT JOIN %Table:SZW% SZW  ON SZW.ZW_FILIAL  = SC5.C5_FILIAL AND SZW.ZW_IDPED   = SC5.C5_I_IDPED  AND SZW.ZW_ITEM  = 1 AND SZW.%notDel%
                LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	
                LEFT JOIN %Table:DAI% DAI  ON DAI.DAI_FILIAL = SC5.C5_FILIAL AND DAI.DAI_CLIENT =  SC5.C5_CLIENTE AND DAI.DAI_LOJA = SC5.C5_LOJACLI  AND DAI.DAI_PEDIDO = SC5.C5_NUM AND DAI.%notDel%
                LEFT JOIN SYS_COMPANY SM0  ON SM0.M0_CODFIL = SC5.C5_FILIAL AND SM0.%notDel%
                
                //Nota de Remessa - Faturamento da Triangular
                LEFT JOIN %Table:SC5% SC5R ON SC5R.C5_FILIAL = SC5.C5_FILIAL AND SC5R.C5_NUM    = SC5.C5_I_PVREM  AND SC5R.%notDel%
                LEFT JOIN %Table:SA1% SA1R ON SA1R.A1_FILIAL = ' ' AND SA1R.A1_COD  = SC5R.C5_CLIENT AND SA1R.A1_LOJA = SC5R.C5_LOJAENT and SA1R.%notDel%
                LEFT JOIN %Table:SF2% SF2R ON SF2R.F2_FILIAL  = SC5R.C5_FILIAL AND SF2R.F2_DOC     = SC5R.C5_NOTA     AND SF2R.F2_SERIE = SC5R.C5_SERIE AND SF2R.F2_CLIENT = SC5R.C5_CLIENTE AND SF2R.F2_LOJA = SC5R.C5_LOJACLI AND SF2R.%notDel%
                
                //Nota de Venda - Faturamento da Triangular
                LEFT JOIN %Table:SC5% SC5V ON SC5V.C5_FILIAL = SC5.C5_FILIAL AND SC5V.C5_NUM    = SC5.C5_I_PVFAT AND SC5V.%notDel%
                LEFT JOIN %Table:SA1% SA1V ON SA1V.A1_FILIAL = ' ' AND SA1V.A1_COD  = SC5V.C5_CLIENTE AND SA1V.A1_LOJA = SC5V.C5_LOJAENT and SA1V.%notDel%
                LEFT JOIN %Table:SF2% SF2V ON SF2V.F2_FILIAL  = SC5V.C5_FILIAL AND SF2V.F2_DOC     = SC5V.C5_NOTA     AND SF2V.F2_SERIE = SC5V.C5_SERIE AND SF2V.F2_CLIENT = SC5V.C5_CLIENTE AND SF2V.F2_LOJA = SC5V.C5_LOJACLI AND SF2V.%notDel%

                //Nota de Faturamento
                LEFT JOIN %Table:SC5% SC5F ON SC5F.C5_FILIAL = SC5.C5_I_FLFNC AND SC5F.C5_NUM = SC5.C5_I_PDPR AND SC5F.%notDel%
                LEFT JOIN %Table:SA1% SA1F ON SA1F.A1_FILIAL = ' ' AND SA1F.A1_COD = SC5F.C5_CLIENT AND SA1F.A1_LOJA = SC5F.C5_LOJAENT and SA1F.%notDel%
                LEFT JOIN %Table:SF2% SF2F ON SF2F.F2_FILIAL = SC5F.C5_FILIAL AND SF2F.F2_DOC = SC5F.C5_NOTA AND SF2F.F2_SERIE = SC5F.C5_SERIE AND SF2F.F2_CLIENT = SC5F.C5_CLIENTE AND SF2F.F2_LOJA = SC5F.C5_LOJACLI AND SF2F.%notDel%

                //Nota de Transferencia
                LEFT JOIN %Table:SC5% SC5T ON SC5T.C5_FILIAL = SC5.C5_I_FILFT AND SC5T.C5_NUM    = SC5.C5_I_PDFT  AND SC5T.%notDel%
                LEFT JOIN %Table:SA1% SA1T ON SA1T.A1_FILIAL = ' ' AND SA1T.A1_COD  = SC5T.C5_CLIENTE AND SA1T.A1_LOJA = SC5T.C5_LOJAENT and SA1T.%notDel%
                LEFT JOIN %Table:SF2% SF2T ON SF2T.F2_FILIAL  = SC5T.C5_FILIAL AND SF2T.F2_DOC     = SC5T.C5_NOTA     AND SF2T.F2_SERIE = SC5T.C5_SERIE AND SF2T.F2_CLIENT = SC5T.C5_CLIENTE AND SF2T.F2_LOJA = SC5T.C5_LOJACLI AND SF2T.%notDel%
                
                LEFT JOIN %Table:SA3% SA32 ON SA32.A3_FILIAL = ' ' AND SA32.A3_COD  = SC5.C5_VEND4   AND SA32.%notDel%
                        
                LEFT JOIN %Table:Z21% Z21  ON Z21.Z21_FILIAL = ' ' AND Z21.Z21_EST     = SA1.A1_EST  AND Z21.Z21_COD = CC2.CC2_I_MESO AND Z21.%notDel%
                LEFT JOIN %Table:Z22% Z22  ON Z22.Z22_FILIAL = ' ' AND Z22.Z22_EST     = SA1.A1_EST  AND Z22.Z22_MESO = CC2.CC2_I_MESO AND Z22.Z22_COD = CC2.CC2_I_MICR AND Z22.%notDel%
                LEFT JOIN %Table:ZY4% ZY4  ON ZY4.ZY4_FILIAL = ' ' AND ZY4.ZY4_EVENTO = SC5.C5_I_EVENT AND ZY4.%notDel%
                LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                LEFT JOIN %Table:ZAM% ZAM  ON ZAM.ZAM_FILIAL = ' ' AND ZAM.ZAM_COOCOD = SC5.C5_VEND2 AND ZAM.ZAM_GERCOD = SC5.C5_VEND3 AND ZAM.%notDel%
                LEFT JOIN ( SELECT ZY3_FILFT,ZY3_NUMPV,ZY3_JUSCOD, ZY5_DESCR, MAX(ZY3.R_E_C_N_O_)  AS RECZY3
                            FROM %Table:ZY3% ZY3, %Table:ZY5% ZY5
                            WHERE ZY3.D_E_L_E_T_ = ' ' AND ZY5.D_E_L_E_T_ = ' ' AND ZY5.ZY5_COD = ZY3_JUSCOD
                            GROUP BY ZY3_FILFT,ZY3_NUMPV,ZY3_JUSCOD, ZY5_DESCR
                            ) ZY3_2 ON ZY3_2.ZY3_NUMPV = SC5.C5_NUM AND ZY3_2.ZY3_FILFT = SC5.C5_FILIAL
            WHERE 
                SC5.%notDel%  
                AND SC6.%notDel%  
                AND SA1.%notDel%  	 	
                AND SB1.%notDel%  					
                AND SA3.%notDel%  											
                AND SC6.C6_BLQ <> 'R'
                %exp:cFiltro%
            ORDER BY 
                SC6.C6_FILIAL,SC5.C5_VEND2,SC5.C5_VEND1,SC6.C6_CLI,SC5.C5_NUM			   
        EndSql
        END REPORT QUERY oSC5FIL_1  

    ElseIf nOrdem == 2 //POR DATA DE ENTREGA
        _cAlias := "QRY2"
        //======================================================================= 
        // Query quando os dois parâmetros de filtro da SC9 estiverem vazios. 
        // A SC9 não pode fazer parte da query, para poder exibir os pedidos
        // que ainda não foram liberados.
        //======================================================================= 
        // verIfica se relatorio vai ser analitico ou sintetico
        // 1 == sintetico
        If MV_PAR21 == 1 //SINTETICO
            //Define query para ordem por data
            //Define query para ordem por data
            BEGIN REPORT QUERY oSC5FIL_2
                BeginSql alias "QRY2"   	   	
                    SELECT 
                        SC5.C5_NUM,
                        SC5.C5_FILIAL,
                        SC5.C5_I_PEVIN,
                        SC5.C5_EMISSAO,
                        SC5.C5_I_DTENT, 
                        SC5.C5_CLIENT C6_CLI,
                        SC5.C5_LOJAENT C6_LOJA,
                        SA1.A1_NREDUZ, 
                        SC5.C5_VEND1,
                        SC5.C5_I_V1NOM ,
                        SC6.C6_FILIAL,
                        SA1.A1_MUN,
                        SA1.A1_BAIRRO,
                        SA1.A1_EST,   
                        SA1.A1_I_CCHEP,
                        SA1.A1_CEP,
                        SA1.A1_I_SHLFP,
                        SC6.C6_PEDCLI,
                        SC5.C5_I_TIPCA,
                        SC5.C5_I_AGEND,
                        SC5.C5_I_SENHA,
                        SC5.C5_I_HOREN,
                        SC5.C5_I_DOCA,
                        SC5.C5_I_CHAPA,
                        SC5.C5_I_CHPCL,
                        SC5.C5_I_OBPED,
                        SC5.C5_MENNOTA,
                        SC5.C5_I_OPER,
                        SC5.C5_I_TRCNF,  
                        SC5.C5_I_FILFT,  
                        SC5.C5_I_FLFNC,
                        ZF8.ZF8_FILIAL,
                        ZF8.ZF8_CODPRG,
                        SUM(SC6.C6_I_QPALT) CARGATOTAL,
                        SUM(SC6.C6_QTDVEN * SB1.B1_PESBRU) C5_PBRUTO,//SC5.C5_PBRUTO,    
                        SC5.C5_I_OPTRI,
                        SC5.C5_I_PVREM,
                        SC5.C5_I_PVFAT,
                        SC5.C5_TPFRETE,
                        SC5.C5_I_LOCEM,
                        SC5.C5_I_QTDA,
                            Case 
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B'  AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B'  THEN 'BLQ CREDITO/BLQ BONIf'   
                                WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B'  THEN 'BLQ PRECO/BLQ BONIf'     
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B'  THEN 'BLQ CREDITO/BLQ PRECO' 
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B'  AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                            END AS SITUACAO,
                        (Select sum(c6_valor) from %Table:SC6% SC6T WHERE SC6T.%notDel%  AND SC6T.C6_FILIAL = SC5.C5_FILIAL  AND SC6T.C6_NUM = SC5.C5_NUM ) TOTALPED ,
                        (
                            SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                            FROM (
                                    SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                    FROM %Table:ZY3% ZY3
                                    WHERE ZY3.%notDel%
                                        AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                                    GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                    ) ZY3
                            LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                            WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                            AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                        )  AS USR_DTENT,
                        (
                            SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                            FROM (
                                    SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                    FROM %Table:ZY3% ZY3
                                    WHERE ZY3.%notDel%
                                        AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                                    GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                    ) ZY3
                            LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                            WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                            AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                        )  AS USR_TPAGEN,
                        SC5.C5_I_TAB, DA0.DA0_DESCRI, ZEL.ZEL_DESCRI		
                    FROM   
                        %Table:SC5% SC5
                        JOIN %Table:SC6% SC6 ON SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM
                        %exp:cFilBloqueio%
                        JOIN %Table:SA1% SA1 ON SA1.A1_FILIAL  = ' ' AND SC5.C5_CLIENT  = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA 
                        JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL  = ' ' AND SB1.B1_COD     = SC6.C6_PRODUTO 
                        LEFT JOIN %Table:DA0% DA0 ON DA0.DA0_FILIAL = ' ' AND DA0.DA0_CODTAB = SC5.C5_I_TAB
                        LEFT JOIN %Table:ZF8% ZF8 ON ZF8.ZF8_FILPED = SC5.C5_FILIAL AND ZF8.ZF8_NUMPED = SC5.C5_NUM AND ZF8.%notDel%
                        LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	
                        LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                    WHERE 
                        SC5.%notDel%  
                        AND SC6.%notDel%
                        AND SA1.%notDel%
                        AND SB1.%notDel%
                        AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                        %exp:_cFiltro2%
                        AND SC6.C6_BLQ <> 'R' 
                        %exp:cFiltro%
                    GROUP BY 
                        SC5.C5_NUM,
                        SC5.C5_FILIAL,
                        SC5.C5_I_PEVIN,
                        SC5.C5_EMISSAO,
                        SC5.C5_I_DTENT, 
                        SC5.C5_CLIENT ,
                        SC5.C5_LOJAENT,
                        SA1.A1_NREDUZ, 
                        SC5.C5_VEND1,
                        SC5.C5_I_V1NOM ,
                        SC6.C6_FILIAL,
                        SA1.A1_MUN,
                        SA1.A1_BAIRRO,
                        SA1.A1_EST,   
                        SA1.A1_I_CCHEP,
                        SA1.A1_CEP,			
                        SC6.C6_PEDCLI,
                        SC5.C5_I_TIPCA,
                        SC5.C5_I_AGEND,
                        SC5.C5_I_SENHA,
                        SC5.C5_I_HOREN,
                        SC5.C5_I_DOCA,
                        SC5.C5_I_CHAPA,
                        SC5.C5_I_CHPCL,
                        SC5.C5_I_OBPED,
                        SC5.C5_MENNOTA,
                        SC5.C5_I_OPER,
                        SC5.C5_I_TRCNF,  
                        SC5.C5_I_FILFT,  
                        SC5.C5_I_FLFNC,
                        ZF8.ZF8_FILIAL,
                        ZF8.ZF8_CODPRG,
                        SC5.C5_PBRUTO, 
                        SC5.C5_I_OPTRI,
                        SC5.C5_I_PVREM,
                        SC5.C5_I_PVFAT,  
                        SC5.C5_TPFRETE,          
                        SC5.C5_I_LOCEM,
                            Case 
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                                WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                                WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                                WHEN C5_I_BLCRE = 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                                WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                            END
                        ,SC5.C5_I_TAB, DA0.DA0_DESCRI,ZEL.ZEL_DESCRI,SA1.A1_I_SHLFP,SC5.C5_I_QTDA
                    ORDER BY 
                        SC5.C5_FILIAL,SC5.C5_I_DTENT,SC5.C5_NUM
                EndSql
            END REPORT QUERY oSC5FIL_2

        Else //ANALITICO
            //Define query para ORDEM POR DATA
            BEGIN REPORT QUERY oSC5FIL_2
                   BeginSql alias "QRY2"   	   	
                       SELECT 
                           SC5.C5_NUM,
                           SC5.C5_I_PEVIN,
                           SC6.C6_ITEM,
                           SC5.C5_EMISSAO,
                           SC5.C5_I_DTENT, 
                           SC5.C5_CLIENT C6_CLI,
                           SC5.C5_LOJAENT C6_LOJA,
                           SA1.A1_NREDUZ,
                           SA1.A1_I_CCHEP,
                           SA1.A1_CEP,			 
                     SA1.A1_I_SHLFP,
                           SC6.C6_QTDVEN,
                           SC6.C6_PRCVEN,
                           SC6.C6_VALOR,
                           SC6.C6_LOCAL,
                           SC6.C6_UM,
                           SC6.C6_SEGUM,
                           SC6.C6_QTDENT,
                           SB1.B1_I_DESCD,
                           SB1.B1_COD,
                           SC5.C5_VEND1,
                           SC5.C5_I_V1NOM ,
                           SA3.A3_SUPER,
                           SA3.A3_COD,
                           SA3.A3_NOME,
                           ACY.ACY_DESCRI,
                           ACY.ACY_GRPVEN,
                           SC6.C6_UNSVEN,
                           SC6.C6_FILIAL,
                           SC6.C6_QTDLIB,
                           SC6.C6_NUM,
                           SC6.C6_I_DQESP,
                           SA1.A1_MUN,
                           SA1.A1_BAIRRO,
                           SA1.A1_EST,
                           SB1.B1_PESBRU,
                           (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                           SC6.C6_PEDCLI,
                           SC5.C5_I_TIPCA,
                           SC5.C5_I_AGEND,
                           SC5.C5_I_SENHA,
                           SC5.C5_I_HOREN,
                           SC5.C5_I_DOCA,
                           SC5.C5_I_CHAPA,
                           SC5.C5_I_CHPCL,
                           SC5.C5_I_OBPED,
                           SC5.C5_MENNOTA,
                           SC5.C5_I_OPER,			
                           SC5.C5_I_TRCNF,  
                           SC5.C5_I_FILFT,  
                           SC5.C5_I_FLFNC,
                           ZF8.ZF8_FILIAL,
                           ZF8.ZF8_CODPRG,
                           SC6.C6_I_QPALT,   
                           SC5.C5_I_OPTRI,
                           SC5.C5_I_PVREM,
                           SC5.C5_I_PVFAT,
                           SC5.C5_TPFRETE,
                           SC5.C5_I_LOCEM,  
                        SC5.C5_I_QTDA,
                     ZEL.ZEL_DESCRI,
                           Case 
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                               WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                               WHEN C5_I_BLCRE = 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                           END AS SITUACAO,
                           (
                               SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                               FROM (
                                       SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                       FROM %Table:ZY3% ZY3
                                       WHERE ZY3.%notDel%
                                           AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                                       GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                       ) ZY3
                               LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                               WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                               AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                           )  AS USR_DTENT,
                           (
                               SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                               FROM (
                                       SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                       FROM %Table:ZY3% ZY3
                                       WHERE ZY3.%notDel%
                                           AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                                       GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                       ) ZY3
                               LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                               WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                               AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                           )  AS USR_TPAGEN
                       FROM 
                           %Table:SC5% SC5
                           JOIN %Table:SC6% SC6 ON SC6.C6_FILIAL = SC5.C5_FILIAL  AND SC6.C6_NUM = SC5.C5_NUM
                           %exp:cFilBloqueio%
                           JOIN %Table:SA1% SA1 ON SA1.A1_FILIAL = ' ' AND SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA 
                           JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = ' ' AND SB1.B1_COD = SC6.C6_PRODUTO
                           JOIN %Table:SA3% SA3 ON SA3.A3_FILIAL = ' ' AND SA3.A3_COD = SC5.C5_VEND1
                           JOIN %Table:SBM% SBM ON SBM.BM_FILIAL = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO
                           JOIN %Table:ACY% ACY ON ACY.ACY_FILIAL = ' ' AND ACY.ACY_GRPVEN	= SA1.A1_GRPVEN
                           LEFT JOIN %Table:ZF8% ZF8 ON ZF8.ZF8_FILPED = SC5.C5_FILIAL AND ZF8.ZF8_NUMPED = SC5.C5_NUM AND ZF8.%notDel%
                         LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                     LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                       WHERE 
                           SC5.%notDel%  
                           AND SC6.%notDel%  
                           AND SA1.%notDel%  		
                           AND SB1.%notDel%  					
                           AND SA3.%notDel%  											
                           AND SBM.%notDel%				
                           AND ACY.%notDel%			
                           AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                           %exp:_cFiltro2%
                           AND SC6.C6_BLQ <> 'R'
                           %exp:cFiltro%
                       ORDER BY 
                           SC6.C6_FILIAL,SC5.C5_I_DTENT,SC6.C6_NUM
                    EndSql
            END REPORT QUERY oSC5FIL_2
             EndIf 
    ElseIf nOrdem == 3//DEFINE QUERY PARA O RELATORIO  ORDEM PRODUTOS
        _cAlias := "QRY3"
        If MV_PAR21 == 1 // SINTETICO
            oSC5S_3:Enable()			
            oSC5_3:Cell("C6_PRODUTO"):Disable()
            oSC5_3:Cell("B1_I_DESCD"):Disable()	
            BEGIN REPORT QUERY oSC5FIL_3
                BeginSql alias "QRY3"   	   	
                    SELECT 			
                        SC5.C5_VEND2,
                        SC5.C5_I_V2NOM,
                        SUM(SC6.C6_QTDVEN) AS C6_QTDVEN,
                        AVG(SC6.C6_PRCVEN) AS C6_PRCVEN,
                        SUM(SC6.C6_VALOR) AS C6_VALOR,
                        SUM(SC6.C6_QTDENT) AS C6_QTDENT,
                        SUM(SC6.C6_QTDVEN*SC6.C6_PRCVEN) AS VLRPENDEN,
                        (Round(avg(SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                        SUM(SC6.C6_UNSVEN) AS C6_UNSVEN, 
                        SC6.C6_LOCAL,
                        SC6.C6_UM,
                        SC6.C6_SEGUM,
                        SB1.B1_I_DESCD,
                        SB1.B1_COD, 
                        SC6.C6_PRODUTO,
                        SC6.C6_FILIAL, 
                        SC5.C5_I_LOCEM,
                        SC6.C6_I_DQESP,
                    ZEL.ZEL_DESCRI
                    FROM 
                        %Table:SC5% SC5
                        JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_FILIAL = SC5.C5_FILIAL 
                        %exp:cFilBloqueio%				
                        JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                        JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                        JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                        JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                        JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN
                    LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                    LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                    WHERE 
                        SC5.%notDel%  
                        AND SC6.%notDel%  
                        AND SA1.%notDel%  		
                        AND SB1.%notDel%  					
                        AND SA3.%notDel%  											
                        AND SBM.%notDel%				
                        AND ACY.%notDel%			
                        AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                        AND SC6.C6_BLQ <> 'R'
                        %exp:cFiltro%
                    GROUP BY 
                        SC6.C6_UM,SC6.C6_SEGUM,SB1.B1_I_DESCD,SB1.B1_COD, SC6.C6_LOCAL, 
                        SC5.C5_VEND2,C5_I_V2NOM,SC6.C6_PRODUTO,SC6.C6_FILIAL,SC5.C5_I_LOCEM,SC6.C6_I_DQESP,ZEL.ZEL_DESCRI  
                    ORDER BY 
                        SC6.C6_FILIAL,SC5.C5_VEND2			
                EndSql
            END REPORT QUERY oSC5FIL_3
       Else //ANALITICO - ORDEM PRODUTOS
           oSC5A_3:Enable()	
           oSC5_3:Cell("C5_VEND2"):Disable()
           //oSC5_3:Cell("SUPERVISOR"):Disable()	
           BEGIN REPORT QUERY oSC5FIL_3
               BeginSql alias "QRY3"   	   	
                       SELECT 
                       SC5.C5_NUM,SC5.C5_I_PEVIN,
                       SC6.C6_ITEM,
                       SC5.C5_EMISSAO,
                       SC5.C5_I_DTENT, 
                       SC5.C5_CLIENT C6_CLI,
                       SC5.C5_LOJAENT C6_LOJA,
                       SA1.A1_NREDUZ, 
                       SC6.C6_QTDVEN,
                       SC6.C6_PRCVEN,
                       SC6.C6_VALOR,
                       SC6.C6_LOCAL,
                       SC6.C6_UM,
                       SC6.C6_SEGUM,
                       SC6.C6_QTDENT,
                       SB1.B1_I_DESCD,
                       SB1.B1_COD,
                       SC5.C5_VEND1,
                       SC5.C5_I_V1NOM ,
                       SC5.C5_VEND2,
                       SC5.C5_I_V2NOM,
                       SC5.C5_VEND3,
                       SC5.C5_I_V3NOM,
                       SA3.A3_COD,
                       SA3.A3_NOME,
                       ACY.ACY_DESCRI,
                       ACY.ACY_GRPVEN,
                       SC6.C6_PRODUTO,
                       SC6.C6_UNSVEN,
                       SC6.C6_FILIAL,
                       SC6.C6_QTDLIB,
                       SC6.C6_NUM,
                       SC6.C6_I_DQESP,
                       (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET, 
                       SC6.C6_PEDCLI,
                       SC5.C5_I_TRCNF,  
                       SC5.C5_I_FILFT,  
                       SC5.C5_I_FLFNC,
                       SC5.C5_I_LOCEM,
                  ZEL.ZEL_DESCRI,
                           Case 
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                               WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                               WHEN C5_I_BLCRE = 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                           END AS SITUACAO,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_DTENT,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_TPAGEN
                   FROM 
                       %Table:SC5% SC5
                       JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_FILIAL = SC5.C5_FILIAL 
                       %exp:cFilBloqueio%
                       JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                       JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                       JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                       JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                       JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN
                  LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                      LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                   WHERE 
                       SC5.%notDel%  
                       AND SC6.%notDel%  
                       AND SA1.%notDel%  		
                       AND SB1.%notDel%  					
                       AND SA3.%notDel%  											
                       AND SBM.%notDel%				
                       AND ACY.%notDel%			
                       AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                       AND SC6.C6_BLQ <> 'R'
                       %exp:cFiltro%
                   ORDER BY 
                       SC6.C6_FILIAL,SC6.C6_PRODUTO,SC5.C5_I_DTENT,SC6.C6_CLI,SC6.C6_LOJA
               EndSql
           END REPORT QUERY oSC5FIL_3
       EndIf

ElseIf nOrdem == 4 //DEFINE QUERY PARA O RELATORIO - ORDEM REDE
      _cAlias := "QRY4"
       If MV_PAR21 == 1 //SINTETICO
           oSC5S_4:Enable()	
           BEGIN REPORT QUERY oSC5FIL_4					   
               BeginSql alias "QRY4"   	   	
                   SELECT			    
                       SUM(SC6.C6_QTDVEN) AS C6_QTDVEN,
                       AVG(SC6.C6_PRCVEN) AS C6_PRCVEN,
                       SUM(SC6.C6_UNSVEN) AS C6_UNSVEN,
                       SUM(SC6.C6_QTDENT) AS C6_QTDENT,
                       SUM(SC6.C6_VALOR) AS C6_VALOR,
                       SUM(SC6.C6_QTDVEN*SC6.C6_PRCVEN) AS VLRPENDEN,
                       (Round(avg(SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                       SC6.C6_LOCAL,
                       SC6.C6_UM,
                       SC6.C6_SEGUM,
                       ACY.ACY_DESCRI,
                       ACY.ACY_GRPVEN,
                       SA1.A1_GRPVEN,
                       SC6.C6_PRODUTO,
                       SB1.B1_I_DESCD,
                       SC6.C6_FILIAL,
                       SC6.C6_I_DQESP,
                       SC5.C5_I_LOCEM, 
                       SC6.C6_NUM,
                  ZEL.ZEL_DESCRI
                   FROM 
                       %Table:SC5% SC5
                       JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL 				
                       %exp:cFilBloqueio%				
                       JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                       JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                       JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                       JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                       JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN				
                  LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	      
                      LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                   WHERE 
                       SC5.%notDel%  
                       AND SC6.%notDel%  
                       AND SA1.%notDel%  		
                       AND SB1.%notDel%  					
                       AND SA3.%notDel%  											
                       AND SBM.%notDel%				
                       AND ACY.%notDel%			
                       AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                       AND SC6.C6_BLQ <> 'R'
                       %exp:cFiltro%
                   GROUP BY 		 		    
                       SC6.C6_UM,SC6.C6_SEGUM,ACY.ACY_DESCRI,ACY.ACY_GRPVEN,SA1.A1_GRPVEN,SC6.C6_PRODUTO,SB1.B1_I_DESCD,
                       SC6.C6_FILIAL,SC6.C6_I_DQESP,SC6.C6_LOCAL,SC5.C5_I_LOCEM,SC6.C6_NUM,ZEL.ZEL_DESCRI
                   ORDER BY 
                       SC6.C6_FILIAL,ACY.ACY_GRPVEN
               EndSql
           END REPORT QUERY oSC5FIL_4
       Else // ***************** ANALITICO *****************
           oSC5A_4:Enable()	
           BEGIN REPORT QUERY oSC5FIL_4
               BeginSql alias "QRY4"   	   	
                   SELECT 			 
                       SC5.C5_NUM,SC5.C5_I_PEVIN,
                       SC5.C5_EMISSAO,
                       SC5.C5_I_DTENT, 
                       SC5.C5_CLIENT C6_CLI,
                       SC5.C5_LOJAENT C6_LOJA,
                       SA1.A1_NREDUZ, 
                       SC6.C6_QTDVEN,
                       SC6.C6_PRCVEN,
                       SC6.C6_VALOR,
                       SC6.C6_LOCAL,
                       SC6.C6_UM,
                       SC6.C6_UNSVEN,
                       SC6.C6_SEGUM,
                       SC6.C6_QTDENT,
                       SB1.B1_I_DESCD,
                       SB1.B1_COD,
                       SC5.C5_VEND1,
                       SC5.C5_I_V1NOM,
                       ACY.ACY_DESCRI,
                       SA1.A1_GRPVEN,
                       SC6.C6_PRODUTO,
                       SC6.C6_FILIAL,
                       (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET, 
                       SC6.C6_QTDLIB,
                       SC6.C6_NUM,
                       SC6.C6_ITEM,
                       SC6.C6_I_DQESP,
                       SA1.A1_MUN,SA1.A1_BAIRRO,
                       SA1.A1_EST,
                       SA1.A1_I_CCHEP,
                       SA1.A1_CEP,				
                       SC6.C6_PEDCLI,
                       SC5.C5_I_TRCNF,  
                       SC5.C5_I_FILFT,  
                       SC5.C5_I_FLFNC,
                       SC5.C5_I_LOCEM,
                  ZEL.ZEL_DESCRI,
                           Case 
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                               WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                               WHEN C5_I_BLCRE = 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                           END AS SITUACAO,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_DTENT,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_TPAGEN
                   FROM 
                       %Table:SC5% SC5
                       JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL  
                       %exp:cFilBloqueio%
                       JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                       JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                       JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                       JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                       JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN
                  LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                      LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                   WHERE 			
                       SC5.%notDel%  
                       AND SC6.%notDel%  
                       AND SA1.%notDel%  		
                       AND SB1.%notDel%  					
                       AND SA3.%notDel%  											
                       AND SBM.%notDel%				
                       AND ACY.%notDel%			
                       AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                       AND SC6.C6_BLQ <> 'R'
                       %exp:cFiltro%
                   ORDER BY 
                       SC6.C6_FILIAL,SA1.A1_GRPVEN,SC5.C5_I_DTENT,SC6.C6_NUM,SC6.C6_ITEM
               EndSql
           END REPORT QUERY oSC5FIL_4
       EndIf 

ElseIf nOrdem == 5 //DEFINE QUERY PARA O RELATORIO - ORDEM MUNICIPIO
    _cAlias := "QRY5"
    If MV_PAR21 == 1 //SINTETICO
           oSC5S_5:Enable()	
           BEGIN REPORT QUERY oSC5FIL_5
               BeginSql alias "QRY5"   	   	
                   SELECT 			    
                       SUM(SC6.C6_QTDVEN) AS C6_QTDVEN,
                       AVG(SC6.C6_PRCVEN) AS C6_PRCVEN,
                       SUM(SC6.C6_UNSVEN) AS C6_UNSVEN,
                       SUM(SC6.C6_QTDENT) AS C6_QTDENT,
                       SUM(SC6.C6_VALOR) AS C6_VALOR,
                       SUM(SC6.C6_QTDVEN*SC6.C6_PRCVEN) AS VLRPENDEN,
                       (Round(avg(SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                       SC6.C6_LOCAL,SC6.C6_UM,SC6.C6_SEGUM,SA1.A1_COD_MUN,SA1.A1_MUN,SA3.A3_COD,SA3.A3_NOME,SC5.C5_I_V1NOM,
                       SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SC5.C5_VEND1,SA1.A1_EST , SC5.C5_I_LOCEM,SC5.C5_NUM,
                  ZEL.ZEL_DESCRI
                   FROM 
                       %Table:SC5% SC5
                       JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL 				
                       %exp:cFilBloqueio%				
                       JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                       JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                       JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                       JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                       JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN				
                  LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                      LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                   WHERE 
                       SC5.%notDel%  
                       AND SC6.%notDel%  
                       AND SA1.%notDel%  		
                       AND SB1.%notDel%  					
                       AND SA3.%notDel%  											
                       AND SBM.%notDel%				
                       AND ACY.%notDel%			
                       AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                       AND SC6.C6_BLQ <> 'R'
                       %exp:cFiltro%
                   GROUP BY 		 		    
                       SC6.C6_UM,SC6.C6_SEGUM,SA1.A1_COD_MUN,SA1.A1_MUN,SA3.A3_COD,SA3.A3_NOME, SC6.C6_LOCAL,SC5.C5_I_V1NOM,
                       SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SC5.C5_VEND1,SA1.A1_EST,SC5.C5_I_LOCEM,SC5.C5_NUM,ZEL.ZEL_DESCRI  
                   ORDER BY 
                       SC6.C6_FILIAL,SA1.A1_MUN,SC5.C5_VEND1
               EndSql
           END REPORT QUERY oSC5FIL_5
       Else //ANALITICO 5  - ORDEM MUNICIPIO
           oSC5A_5:Enable()	
           BEGIN REPORT QUERY oSC5FIL_5
               BeginSql alias "QRY5"
                   SELECT 			
                       SC5.C5_NUM,SC5.C5_I_PEVIN,
                       SC5.C5_EMISSAO,
                       SC5.C5_I_DTENT, 
                       SC5.C5_CLIENT C6_CLI,
                       SC5.C5_LOJAENT C6_LOJA,
                       SA1.A1_NREDUZ, 
                       SC6.C6_QTDVEN,
                       SC6.C6_PRCVEN,
                       SC6.C6_VALOR,
                       SC6.C6_VALOR,
                       SC6.C6_UM,
                       SC6.C6_LOCAL,
                       SC6.C6_UNSVEN,
                       SC6.C6_SEGUM,
                       SC6.C6_QTDENT,
                       SB1.B1_I_DESCD,
                       SB1.B1_COD,
                       SC5.C5_VEND1,
                       SC5.C5_I_V1NOM,
                       SA1.A1_COD_MUN,
                       SA1.A1_MUN,
                       SC6.C6_PRODUTO,
                       SC6.C6_FILIAL,
                       SC6.C6_QTDLIB,
                       SC6.C6_NUM,
                       (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET, 
                       SC6.C6_ITEM,
                       SC6.C6_I_DQESP,
                       SA3.A3_NOME,
                       SA1.A1_EST,
                       SC6.C6_PEDCLI,
                       SC5.C5_I_TRCNF,  
                       SC5.C5_I_FILFT,  
                       SC5.C5_I_FLFNC,
                       SC5.C5_I_LOCEM,
                  ZEL.ZEL_DESCRI,
                           Case 
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
                               WHEN C5_I_BLPRC = 'B'  AND C5_I_BLOQ  = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
                               WHEN C5_I_BLCRE = 'B'  AND C5_I_BLPRC = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
                               WHEN C5_I_BLCRE = 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC = 'B' AND C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
                               WHEN C5_I_BLCRE <> 'B' AND C5_I_BLPRC <> 'B' AND C5_I_BLOQ = 'B' THEN 'BLQ BONIf'
                           END AS SITUACAO,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_DTENT,
                       (
                           SELECT ZY3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                           FROM (
                                   SELECT ZY3_FILFT,ZY3_NUMPV, MAX(R_E_C_N_O_) AS RECNO 
                                   FROM %Table:ZY3% ZY3
                                   WHERE ZY3.%notDel%
                                       AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                                   GROUP BY ZY3_FILFT,ZY3_NUMPV 
                                   ) ZY3
                           LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
                           WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
                           AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
                       )  AS USR_TPAGEN
                   FROM 
                       %Table:SC5% SC5
                       JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL  
                       %exp:cFilBloqueio%
                       JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                       JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                       JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                       JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                       JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN
                  LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                      LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
                   WHERE 
                       SC5.%notDel%  
                       AND SC6.%notDel%  
                       AND SA1.%notDel%  		
                       AND SB1.%notDel%  					
                       AND SA3.%notDel%  											
                       AND SBM.%notDel%				
                       AND ACY.%notDel%			
                       AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                       AND SC6.C6_BLQ <> 'R'
                       %exp:cFiltro%
                   ORDER BY 
                       SC6.C6_FILIAL,SA1.A1_MUN,SC5.C5_VEND1,SC5.C5_I_DTENT,SC6.C6_NUM,SC6.C6_ITEM
               EndSql
           END REPORT QUERY oSC5FIL_5
       EndIf

ElseIf nOrdem == 6 //DEFINE QUERY PARA O RELATORIO - ORDEM PRODUTO - RESUMIDO
    _cAlias := "QRY6"
    BEGIN REPORT QUERY oSC5FIL_6
           BeginSql alias "QRY6"   	   	
               SELECT 		    
                   SUM(SC6.C6_QTDVEN) AS C6_QTDVEN,
                   AVG(SC6.C6_PRCVEN) AS C6_PRCVEN,
                   SUM(SC6.C6_UNSVEN) AS C6_UNSVEN,
                   SUM(SC6.C6_QTDENT) AS C6_QTDENT,
                   SUM(SC6.C6_VALOR) AS C6_VALOR,
                   SUM(SC6.C6_QTDVEN*SC6.C6_PRCVEN) AS VLRPENDEN,
                   (Round(avg(SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
                   SC6.C6_LOCAL, SC6.C6_UM,SC6.C6_SEGUM,	SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SC5.C5_I_LOCEM,SB1.B1_COD,ZEL.ZEL_DESCRI
               FROM 
                   %Table:SC5% SC5
                   JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL 				
                   %exp:cFilBloqueio%				
                   JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
                   JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
                   JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
                   JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
                   JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN				
               LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
                   LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
               WHERE 
                   SC5.%notDel%  
                   AND SC6.%notDel%  
                   AND SA1.%notDel%  		
                   AND SB1.%notDel%  					
                   AND SA3.%notDel%  											
                   AND SBM.%notDel%				
                   AND ACY.%notDel%			
                   AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
                   AND SC6.C6_BLQ <> 'R'
                   %exp:cFiltro%
               GROUP BY 		 		    
                   SC6.C6_LOCAL, SC6.C6_UM,SC6.C6_SEGUM,	SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SC5.C5_I_LOCEM,SB1.B1_COD,ZEL.ZEL_DESCRI
               ORDER BY 
                   SC6.C6_FILIAL,SB1.B1_COD,SB1.B1_I_DESCD
           EndSql
       END REPORT QUERY oSC5FIL_6 

   EndIf
   //SECAO COORDENADOR/VENDEDOR
   oSC5_1:SetParentQuery()
   oSC5_1:SetParentFilter({|cParam| QRY1->C6_FILIAL == cParam },{|| QRY1->C6_FILIAL })
      
   oSC5A_1:SetParentQuery()
   oSC5A_1:SetParentFilter({|cParam| QRY1->C6_FILIAL + QRY1->C5_VEND2 == cParam },{|| QRY1->C6_FILIAL + QRY1->C5_VEND2 })

   oSC5B_1:SetParentQuery()
   oSC5B_1:SetParentFilter({|cParam| QRY1->C6_FILIAL + QRY1->C5_VEND2 + QRY1->C5_VEND1 == cParam },{|| QRY1->C6_FILIAL + QRY1->C5_VEND2 + QRY1->C5_VEND1 })

   //SECAO DATA DE ENTREGA
   oSC5_2:SetParentQuery()
   oSC5_2:SetParentFilter({|cParam| QRY2->C6_FILIAL == cParam },{|| QRY2->C6_FILIAL })

   oSC5A_2:SetParentQuery()
   oSC5A_2:SetParentFilter({|cParam| QRY2->C6_FILIAL + DToS(QRY2->C5_I_DTENT) == cParam },{|| QRY2->C6_FILIAL + DToS(QRY2->C5_I_DTENT) })                       

   //Secao Produto - analitico - grupo por produto 
   oSC5_3:SetParentQuery()
   oSC5_3:SetParentFilter({|cParam| QRY3->C6_FILIAL == cParam },{|| QRY3->C6_FILIAL })

   oSC5A_3:SetParentQuery()
   oSC5A_3:SetParentFilter({|cParam| QRY3->C6_FILIAL + QRY3->C6_PRODUTO == cParam },{|| QRY3->C6_FILIAL + QRY3->C6_PRODUTO })                       

   //Secao Produto - sintetico - grupo por supervisor
   oSC5S_3:SetParentQuery()
   oSC5S_3:SetParentFilter({|cParam| QRY3->C6_FILIAL + QRY3->C5_VEND2 == cParam },{|| QRY3->C6_FILIAL + QRY3->C5_VEND2 })                       

   //Secao RedeoSC5FIL_1
   oSC5_4:SetParentQuery()
   oSC5_4:SetParentFilter({|cParam| QRY4->C6_FILIAL == cParam },{|| QRY4->C6_FILIAL })

   oSC5S_4:SetParentQuery()
   oSC5S_4:SetParentFilter({|cParam| QRY4->C6_FILIAL + QRY4->A1_GRPVEN == cParam },{|| QRY4->C6_FILIAL + QRY4->A1_GRPVEN })                       

   //Secao Rede
   oSC5A_4:SetParentQuery()
   oSC5A_4:SetParentFilter({|cParam| QRY4->C6_FILIAL + QRY4->A1_GRPVEN == cParam },{|| QRY4->C6_FILIAL + QRY4->A1_GRPVEN })                       

   //Secao Municipio    
   oSC5_5:SetParentQuery()
   oSC5_5:SetParentFilter({|cParam| QRY5->C6_FILIAL == cParam },{|| QRY5->C6_FILIAL })

   oSC5_5A:SetParentQuery()
   oSC5_5A:SetParentFilter({|cParam | QRY5->C6_FILIAL + QRY5->A1_MUN == cParam },{|| QRY5->C6_FILIAL + QRY5->A1_MUN })

   //Secao Municipio
   oSC5S_5:SetParentQuery()
   oSC5S_5:SetParentFilter({|cParam| QRY5->C6_FILIAL+QRY5->A1_MUN+QRY5->C5_VEND1 == cParam },{|| QRY5->C6_FILIAL+QRY5->A1_MUN+QRY5->C5_VEND1 })

   //Secao Municipio
   oSC5A_5:SetParentQuery()
   oSC5A_5:SetParentFilter({|cParam| QRY5->C6_FILIAL+QRY5->A1_MUN+QRY5->C5_VEND1 == cParam },{|| QRY5->C6_FILIAL+QRY5->A1_MUN+QRY5->C5_VEND1 })

   //Secao Produto Resumido
   oSC5_6:SetParentQuery()
   oSC5_6:SetParentFilter({|cParam| QRY6->C6_FILIAL == cParam },{|| QRY6->C6_FILIAL })
EndIf

If nOrdem == 1    
       oSC5FIL_1:Print(.T.)
ElseIf nOrdem == 2
    oSC5FIL_2:Print(.T.)
ElseIf nOrdem == 3
    oSC5FIL_3:Print(.T.)
ElseIf nOrdem == 4
    oSC5FIL_4:Print(.T.)
ElseIf nOrdem == 5
    oSC5FIL_5:Print(.T.)
ElseIf nOrdem == 6
    oSC5FIL_6:Print(.T.)      
    ROMS002PR()  		
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS002PL
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009
Descrição---------: Filtra codigo do bloqueio para pedido
Parametros--------: nQtdLib: Quantidade Liberada na C6                                                      						
                        cFil: Filial da C6                                                                    						
                        cNum: Numero do Pedido                                                               						
                        cItem: Item do pedido 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS002PL(nQtdLib,cFil,cNum,cItem)

Local lRet := .T.  
Local aArea := FWGetArea()

If nQtdLib > 0 
    DBSelectArea("SC9") 
    SC9->(DBSetOrder(1))
    SC9->(DBSeek(cFil+cNum+cItem))
        
    If MV_PAR23 == 1 .And. SC9->C9_BLEST = '02'//Bloqueio Estoque
            lRet := .T.
    ElseIf MV_PAR23 == 2 .And. SC9->C9_BLEST = '  ' //Sem Bloqueio do Estoque
            lRet := .T. 
    EndIf 
EndIf
     
FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: ROMS002PR
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009
Descrição---------: Impressão resumida 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS002PR()         

Local _aProdutos:= {}      
Local _nPos     := 0    

Local _nTotqtd1 := 0
Local _nTotqtd2 := 0
Local _nTotqtdEn:= 0
Local _nTotqtdPe:= 0
Local _nTotValor:= 0 , x
               
Private _nSaltoLin:= 60
Private _ColIni   := 40   
Private _ColFin   := 3300   
Private oFont11b,oFont11  
Private nRow           

Define Font oFont11b Name "Arial"       Size 0,-11 Bold	// Arial 11 Negrito
Define Font oFont11  Name "Courier New" Size 0,-11 	    // Arial 11 

DBSelectArea("QRY6")
QRY6->(DBGoTop())

While QRY6->(!Eof())   
    _nPos := aScan(_aProdutos,{|x| x[1] == QRY6->C6_PRODUTO })
    If _nPos > 0    
        _aProdutos[_nPos,3]+= QRY6->C6_QTDVEN
        _aProdutos[_nPos,5]+= QRY6->C6_UNSVEN
        _aProdutos[_nPos,7]+= QRY6->C6_QTDENT
        _aProdutos[_nPos,8]+= QRY6->VLRPENDEN
    Else        
        aAdd(_aProdutos,{	QRY6->C6_PRODUTO,;		//01 
                            QRY6->B1_I_DESCD,;		//02
                            QRY6->C6_QTDVEN,;		//03
                            QRY6->C6_UM,;			//04
                            QRY6->C6_UNSVEN,;		//05
                            QRY6->C6_SEGUM,;		//06
                            QRY6->C6_QTDENT,;		//07
                                QRY6->VLRPENDEN})		//08

    EndIf
    QRY6->(DBSkip())
EndDo                           

_aProdutos:= aSort(_aProdutos,,,{|x, y| x[1] < y[1]})		// Ordenar    

If Len(_aProdutos) > 0
    //Finaliza a pagina de impressao atual                     
    oReport:EndPage()
    //Inicia uma nova Pagina
    oReport:StartPage()         
                           
    nRow:= oReport:Row()      
    
    nRow+= _nSaltoLin
    oReport:Say(nRow,_ColIni,"Relação de produtos resumida, desconsiderando Filial",oFont11b)
    
    nRow+= _nSaltoLin
    nRow+= _nSaltoLin
                     
    //Define cabecalho para impressao
    _nLinha:=nRow //Armazena a posicao inicial do box
    oReport:Say(nRow,_ColIni      ,"Produto"  ,oFont11b)   
    oReport:Say(nRow,_ColIni + 260,"Descrição",oFont11b)
    oReport:Say(nRow,_ColIni + 1180,"Quantidade",oFont11b)
    oReport:Say(nRow,_ColIni + 1550,"Prc Unitario",oFont11b)
    oReport:Say(nRow,_ColIni + 1700,"1a. U.M.",oFont11b)
    oReport:Say(nRow,_ColIni + 1850,"Qtde Vend. 2a. U.M.",oFont11b)
    oReport:Say(nRow,_ColIni + 2200,"2a. U.M.",oFont11b)
    oReport:Say(nRow,_ColIni + 2360,"Qtde. Entregue",oFont11b)
    oReport:Say(nRow,_ColIni + 2670,"Qtde. Pendente",oFont11b) 
    oReport:Say(nRow,_ColIni + 3070,"Valor Total",oFont11b)
     
    //Imprime Dados
    For x:=1 to Len(_aProdutos)                     
        //Quebra de pagina
       If nRow + _nSaltoLin > 2325
                                
               oReport:Box(_nLinha,_ColIni - 10,nRow + _nSaltoLin,_ColFin)	
            ROMS002DV()
            //Finaliza a pagina de impressao atual                     
            oReport:EndPage()
            //Inicia uma nova Pagina
            oReport:StartPage()    
            nRow:= oReport:Row()
            nRow+= _nSaltoLin
            _nLinha:=nRow //Armazena a posicao inicial do box
        Else
             nRow+= _nSaltoLin 
        EndIf
    
           oReport:Say(nRow,_ColIni       ,_aProdutos[x,1]																		   ,oFont11)   
        oReport:Say(nRow,_ColIni + 260 ,SUBSTR(_aProdutos[x,2],1,39)														   ,oFont11)
        oReport:Say(nRow,_ColIni + 1010,Transform(_aProdutos[x,3],"@E 999,999,999,999.99")									   ,oFont11)
        oReport:Say(nRow,_ColIni + 1330,Transform(_aProdutos[x,8]/(_aProdutos[x,3] - _aProdutos[x,7]),"@E 999,999,999.9999"),oFont11)
        oReport:Say(nRow,_ColIni + 1700,_aProdutos[x,4]																	   ,oFont11)
        oReport:Say(nRow,_ColIni + 1880,Transform(_aProdutos[x,5],"@E 999,999,999.99")										   ,oFont11)
        oReport:Say(nRow,_ColIni + 2200,_aProdutos[x,6]																       ,oFont11)
        oReport:Say(nRow,_ColIni + 2250,Transform(_aProdutos[x,7],"@E 999,999,999,999.99")								       ,oFont11)
        oReport:Say(nRow,_ColIni + 2560,Transform(_aProdutos[x,3] - _aProdutos[x,7],"@E 999,999,999,999.99")			       ,oFont11) 
        oReport:Say(nRow,_ColIni + 2890,Transform(_aProdutos[x,8],"@E 999,999,999,999.99")									   ,oFont11)		
            
        oReport:Line(nRow,_ColIni,nRow,_ColFin)
            
        //Efetua somatorio do totalizador geral
        _nTotqtd1 += _aProdutos[x,3]
        _nTotqtd2 += _aProdutos[x,5]
        _nTotqtdEn+= _aProdutos[x,7]
        _nTotqtdPe+= (_aProdutos[x,3] - _aProdutos[x,7])
        _nTotValor+= _aProdutos[x,8]	                             
    Next x               
    
    nRow+= _nSaltoLin	
    
    //Imprime o total Geral do Relatorio resumido	    
    oReport:Say(nRow,_ColIni       ,"Total Geral"																	   ,oFont11b)   
    oReport:Say(nRow,_ColIni + 1010,Transform(_nTotqtd1,"@E 999,999,999,999.99")									   ,oFont11)
    oReport:Say(nRow,_ColIni + 1880,Transform(_nTotqtd2,"@E 999,999,999.99")										   ,oFont11)
    oReport:Say(nRow,_ColIni + 2250,Transform(_nTotqtdEn,"@E 999,999,999,999.99")								       ,oFont11)
    oReport:Say(nRow,_ColIni + 2560,Transform(_nTotqtdPe,"@E 999,999,999,999.99")			       					   ,oFont11) 
    oReport:Say(nRow,_ColIni + 2890,Transform(_nTotValor,"@E 999,999,999,999.99")									   ,oFont11)		
    oReport:Line(nRow,_ColIni,nRow,_ColFin)
               
    //Imprime ultimo box e divisoria 
    oReport:Box(_nLinha,_ColIni - 10,nRow + _nSaltoLin,_ColFin)	
    ROMS002DV()
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS002DV
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009
Descrição---------: Imprime linhas de divisão da página 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS002DV()

oReport:Line(_nLinha,_ColIni + 255 ,nRow + _nSaltoLin,_ColIni + 255 )
oReport:Line(_nLinha,_ColIni + 1060,nRow + _nSaltoLin,_ColIni + 1060)  
oReport:Line(_nLinha,_ColIni + 1385,nRow + _nSaltoLin,_ColIni + 1385) 
oReport:Line(_nLinha,_ColIni + 1675,nRow + _nSaltoLin,_ColIni + 1675) 
oReport:Line(_nLinha,_ColIni + 1840,nRow + _nSaltoLin,_ColIni + 1840)
oReport:Line(_nLinha,_ColIni + 2180,nRow + _nSaltoLin,_ColIni + 2180)
oReport:Line(_nLinha,_ColIni + 2345,nRow + _nSaltoLin,_ColIni + 2345)
oReport:Line(_nLinha,_ColIni + 2615,nRow + _nSaltoLin,_ColIni + 2615)
oReport:Line(_nLinha,_ColIni + 2935,nRow + _nSaltoLin,_ColIni + 2935)

Return

/*
===============================================================================================================================
Programa----------: ROMS002F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/11/2016
Descrição---------: Retornar o nome da filial 
Parametros--------: _cCodFilial = Codigo da Filial
Retorno-----------: Nome da Filial
===============================================================================================================================
*/
User Function ROMS002F(_cCodFilial)

Local _cRet := ""    
Local _nI
Local _cSM0_NOME := 7 // Nome da filial 

Begin Sequence                                  
   If Empty(_cCodFilial)
      Break
   EndIf
   
   _nI := aScan(_aFilial,{|x| x[5] = _cCodFilial})   
   If _nI > 0
      _cRet := _aFilial[_nI,_cSM0_NOME]
   EndIf   
End Sequence

Return _cRet   

/*
===============================================================================================================================
Programa----------: ROMS002V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/11/2016
Descrição---------: Validar a digitação do filtro situação do pedido.
Parametros--------: Não há
Retorno-----------: True or False
===============================================================================================================================
*/
User Function ROMS002V()

Local _lRet := .T.   
Local _aOpcoes := {} 
Local _nI 
Local _aSitPedido
Local _nJ 

Begin Sequence  
   aAdd(_aOpcoes,"T") // Todos
   aAdd(_aOpcoes,"S") // Sem Bloqueio
   aAdd(_aOpcoes,"C") // Bloqueio Credito
   aAdd(_aOpcoes,"P") // Bloqueio Preco
   aAdd(_aOpcoes,"B") // Bloqueio BonIficacao
   aAdd(_aOpcoes,"L") // Liberados                                
   
   If ! Empty(MV_PAR33)
      _aSitPedido := StrTokArr(MV_PAR33,";")
      For _nI := 1 To Len(_aSitPedido)
          _nJ := aScan(_aOpcoes, AllTrim(_aSitPedido[_nI]))
          If _nJ == 0
             U_ITMsg("Situação de Pedido de vendas inválido!","Atenção",,1)
             _lRet := .F.
             Exit
          EndIf
      Next
   EndIf
   
End Sequence

Return _lRet 

/*
===============================================================================================================================
Programa----------: ROMS002H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/10/2017
Descrição---------: Retorna o Local de entrega do pedido de vendas, levando em consideração os pedidos de compras dos 
                    funcionários Italac (Tabela Z12). 
Parametros--------: _cCodFil = Filial da nota fiscal
                    _cNumPed = Numero do pedido de vendas gravado na tabela SF2.
Retorno-----------: Nome do Local de entrega.
===============================================================================================================================
*/
User Function ROMS002H(_cCodFil,_cNumPed,_Coluna)

Local _cRet := ""    
Local _aOrd := SaveOrd({"SC5","Z12"})
Default _Coluna := ""

Begin Sequence     

    If (_nPos := aScan(_aLocEnt,{|x| x[1]+x[2]+x[3] == _cCodFil+_cNumPed+_Coluna }))
        _cRet := _aLocEnt[_nPos,4]
    Else
        Z12->(DBSetOrder(3))
        
        If Z12->(DBSeek(_cCodFil+_cNumPed))
            If Empty(_Coluna) 
                _cRet := AllTrim(Upper(U_ITRetBox( Z12->Z12_LOCENT ,"Z12_LOCENT")))
            ElseIf _Coluna == "CIDADE"
                _cRet := AllTrim(Upper(U_ITRetBox( Z12->Z12_LOCENT ,"Z12_LOCENT"))) 
            EndIf
            Break
        EndIf
        
        SC5->(DBSetOrder(1))
        If SC5->(DBSeek(_cCodFil+_cNumPed))
            If Empty(_Coluna)
                _cRet :=  AllTrim(SC5->C5_I_MUN) +"/"+ AllTrim(SC5->C5_I_EST)
            Else
                If _Coluna == "CIDADE"
                    _cRet :=  AllTrim(SC5->C5_I_MUN) 
                Else
                    _cRet :=  AllTrim(SC5->C5_I_EST)
                EndIf
            EndIf
        EndIf
        aAdd(_aCargaTot,{_cCodFil,_cNumPed,_Coluna,_cRet})
    EndIf
End Sequence

RestOrd(_aOrd)

Return _cRet 

/*
===============================================================================================================================
Programa----------: ROMS2CG
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 08/06/2022
Descrição---------: Retorna a Carga Total  do pdedido = ao relatorio de Ordem de Carga
Parametros--------: _cfil,_cPed
Retorno-----------: Carga Geral
===============================================================================================================================
*/
Static Function ROMS2CG(_cfil,_cPed)

Local _cInfPal   := ''
Local _nQtPallet := 0
Local _nPos      := 0

If (_nPos := aScan(_aCargaTot,{|x| x[1]+x[2] == _cfil+_cPed }))
    _nQtPallet := _aCargaTot[_nPos,3]
    If _nQtPallet > 0
        _cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) 
    EndIf
Else
    SC6->( DBSetOrder(1) )
    SC6->( DBSeek( _cfil+_cPed) )

    While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == _cfil+_cPed
        _nQtPallet  += ROMS002CT(SC6->C6_PRODUTO,SC6->C6_QTDVEN,.T.)
        SC6->( DBSkip() )
    EndDo
    If _nQtPallet > 0
        _cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) 
    EndIf

    _nTQtdPallets := _nQtPallet
    aAdd(_aCargaTot,{_cfil,_cPed,_nQtPallet})
EndIf

Return _cInfPal

/*
===============================================================================================================================
Programa----------: ROMS002CT
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 22/01/2018
Descrição---------: Retorna a Carga Total = ao relatorio de Ordem de Carga
Parametros--------: _cProduto: SC6->C6_PRODUTO , _nQtde: SC6->C6_QTDVEN
Retorno-----------: Carga Total
===============================================================================================================================
*/
Static Function ROMS002CT(_cProduto,_nQtde,_lQtdePallt)

Local _aOrd := SaveOrd({"SC5","Z12"})
Local _nQtPallet:= 0
Local _nQtSobra	:= 0
Local _nQtNoPl	:= 0
Local _cUMPal	:= ''
Local _cInfPal  := ''

Default _lQtdePallt := .F.

Begin Sequence     
    //A ordem foi setada no inicio do programa
    If !SB1->(DBSeek(xFilial()+_cProduto))
        BREAK
    EndIf

    // Cálculo da quantidade de Pallets
    If SB1->B1_I_UMPAL == '1'
        _nQtPallet	:= Int( _nQtde / SB1->B1_I_CXPAL )
    ElseIf SB1->B1_I_UMPAL == '2'
        _nQtPallet	:= Int( ROMS2CNV( _nQtde , 1 , 2 ) / SB1->B1_I_CXPAL )
    ElseIf SB1->B1_I_UMPAL == '3'
        _nQtPallet	:= Int( ROMS2CNV( _nQtde , 1 , 3 ) / SB1->B1_I_CXPAL )
    Else
        _nQtPallet	:= 0
        _nQtSobra	:= 0
        _cUMPal		:= ''
    EndIf
    If _lQtdePallt
        BREAK
    EndIf

    _nQtNoPl := ( _nQtPallet * SB1->B1_I_CXPAL )
    
    // Dados para impressão da sobra com relação aos Pallets completos
    If SB1->B1_I_QTOC3 == '1'
        If SB1->B1_I_UMPAL == '2'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 2 , 1 )
        ElseIf SB1->B1_I_UMPAL == '3'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 3 , 1 )
        EndIf
        
        _nQtSobra	:= _nQtde - _nQtNoPl
        _cUMPal		:= PadR( SB1->B1_UM , TamSX3( 'B1_UM' )[01] )
    ElseIf SB1->B1_I_QTOC3 == '2'
        If SB1->B1_I_UMPAL == '1'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 1 , 2 )
        ElseIf SB1->B1_I_UMPAL == '3'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 3 , 2 )
        EndIf
        
        _nQtSobra	:= ROMS2CNV( _nQtde , 1 , 2 ) - _nQtNoPl
        _cUMPal		:= PadR( SB1->B1_SEGUM , TamSX3( 'B1_SEGUM' )[01] )
    ElseIf SB1->B1_I_QTOC3 == '3'
        If SB1->B1_I_UMPAL == '1'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 1 , 3 )
        ElseIf SB1->B1_I_UMPAL == '2'
            _nQtNoPl := ROMS2CNV( _nQtNoPl , 2 , 3 )
        EndIf
        
        _nQtSobra	:= ROMS2CNV( _nQtde , 1 , 3 ) - _nQtNoPl
        _cUMPal		:= PadR( SB1->B1_I_3UM , TamSX3( 'B1_I_3UM' )[01] )
    Else
        _nQtPallet	:= 0
        _nQtSobra	:= 0
        _cUMPal		:= ''
    EndIf

    _cInfPal := ''
    
    If !Empty( _cUMPal )
        If _nQtPallet > 0
            _cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) + IIf( _nQtSobra > 0 , ' + ' , '' )
        EndIf
        
        If _nQtSobra > 0
            _cInfPal += cValToChar( _nQtSobra ) +' '+ _cUMPal
        EndIf
    EndIf
End Sequence

RestOrd(_aOrd)
If _lQtdePallt
    _nTQtdPalItem := _nQtPallet
    Return _nQtPallet
Else
    Return _cInfPal
    _nTQtdPalItem := 0
EndIf

/*
===============================================================================================================================
Programa----------: ROMS2CNV
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 22/01/2018
Descrição---------: Função para conversão entre unidades de medida - COPIA DA ROMS004CNV
Parametros--------: _nQtdAux , _nUMOri , _nUMDes
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS2CNV( _nQtdAux , _nUMOri , _nUMDes )

Local _nRet	:= 0

Do Case
    Case _nUMDes == 1
        // Conversão da Segunda UM para a Primeira
        If _nUMOri == 2
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux * SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux / SB1->B1_CONV
            EndIf
        // Conversão da Terceira UM para a Primeira
        ElseIf _nUMOri == 3
            _nRet := _nQtdAux * SB1->B1_I_QT3UM
        EndIf
    Case _nUMDes == 2
        // Conversão da Primeira UM para a Segunda
        If _nUMOri == 1
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux * SB1->B1_CONV
            EndIf
        // Conversão da Terceira UM para a Segunda
        ElseIf _nUMOri == 3
            _nRet := _nQtdAux * SB1->B1_I_QT3UM
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nRet / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nRet * SB1->B1_CONV
            EndIf
        EndIf
    Case _nUMDes == 3
        // Conversão da Primeira UM para a Terceira
        If _nUMOri == 1
            _nRet := _nQtdAux / SB1->B1_I_QT3UM
        // Conversão da Segunda UM para a Terceira
        ElseIf _nUMOri == 2
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux * SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux / SB1->B1_CONV
            EndIf
            _nRet := _nRet / SB1->B1_I_QT3UM
        EndIf
EndCase

Return _nRet 

/*
===============================================================================================================================
Programa----------: ROMS2FMT
Autor-------------: Jonathan Torioni
Data da Criacao---: 05/06/2020
Descrição---------: Formata agendamento
Parametros--------: cAgend,dDtEnt
Retorno-----------: cSitAg
===============================================================================================================================
*/
Static Function ROMS2FMT(cAgend,dDtEnt)

Local cSitAg := U_TipoEntrega(cAgend)//C5_I_AGEND
Local nCont	 := (SToD(dDtEnt) - DATE())
Do Case
    //Case cAgend = 'I'
    //	cSitAg := "Imediato"
    //Case cAgend = 'O'
    //	cSitAg := "Agendada pelo Op. Log."
    //Case cAgend == "P"
    //	cSitAg := "Aguardando agenda"
    Case Empty(cAgend)//C5_I_AGEND
        cSitAg := "Imediato"
    Case cAgend $ "AM"//C5_I_AGEND
        If nCont <= 0
            cSitAg := "Perdeu agenda"
        ElseIf (nCont > 1) .And. (nCont <= 7)
            cSitAg := "Semana 1"
        ElseIf (nCont > 7) .And. (nCont <= 14)
            cSitAg := "Semana 2"
        ElseIf (nCont > 14) .And. (nCont <= 21)
            cSitAg := "Semana 3"
        ElseIf nCont > 21
            cSitAg := "Posterior"
        EndIf
EndCase

Return cSitAg

/*
===============================================================================================================================
Programa----------: ROMS002S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/07/2020
Descrição---------: Rotina que rodoa o Relatório de Pedidos Pendentes em Carteira no modo Scheduller.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS002S()

Local _cEmailR21 
Local _cEmailR22 
Local _cEmailR23 
Local _cEmails, _aEmails, _nI 
Local _cDirArq

Begin Sequence

    // Preparando o ambiente com a filial da carga recebida
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ROMS00201"/*cMsgId*/, "ROMS00201 - Preparando ambiente. Integração liberação de bloqueio de pedidos."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01'; 
           TABLES "SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1";
           MODULO 'OMS'
   cFilAnt := "01" // Filal Matriz

   _cEmailR21 := SuperGetMV("IT_MAILR21",.T.,"")    
   _cEmailR22 := SuperGetMV("IT_MAILR22",.T.,"")
   _cEmailR23 := SuperGetMV("IT_MAILR23",.T.,"")

   _cEmails := ""
   If ! Empty(_cEmailR21)
      _cEmails += If(Right(AllTrim(_cEmailR21),1) == ";", AllTrim(_cEmailR21), AllTrim(_cEmailR21)+";") 
   EndIf

   If ! Empty(_cEmailR22)
      _cEmails += If(Right(AllTrim(_cEmailR22),1) == ";", AllTrim(_cEmailR22), AllTrim(_cEmailR22)+";") 
   EndIf

   If ! Empty(_cEmailR23)
      _cEmails += If(Right(AllTrim(_cEmailR23),1) == ";", AllTrim(_cEmailR23), AllTrim(_cEmailR23)+";") 
   EndIf
   
   If Empty(_cEmails)
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ROMS00202"/*cMsgId*/, "ROMS00202 - Nenhum e-mail foi informado para envio do relatório Pedidos Pendentes Carteira"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Break 
   EndIf 

   _aEmails := U_ITTXTARRAY(_cEmails,";",30,1)

   _cDirArq := GetTempPath()
   _cDirArq := AllTrim(_cDirArq)    
   
   If Right(_cDirArq,1) <> "\"
      _cDirArq := _cDirArq + "\totvsprinter\ROMS002.PDF"
   Else
      _cDirArq := _cDirArq + "totvsprinter\ROMS002.PDF"
   EndIf
   
   For _nI := 1 To Len(_aEmails)
       If File(_cDirArq)
          FERASE(_cDirArq) 
       EndIf 
       U_ROMS002(.T., _aEmails[_nI]) // Chama a rotina principal no modo Scheduller.
   Next 

   If File(_cDirArq)
      FERASE(_cDirArq) 
   EndIf
   
   // Limpa o ambiente, liberando a licença e fechando as conexões
   RpcClearEnv() 

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: ROMS002N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/12/2021
Descrição---------: VerIfica se existe carga para o pedido de vendas posicionado e se existir retorna o numero da carga.
Parametros--------: _cFilial = Filial do Pedido
                    _cNumPed = Numero do Pedido
Retorno-----------: _cRet    = Numero da Carga se existir
                             = Espaços se não existir o numero da carga.
===============================================================================================================================
*/
User Function ROMS002N(_cFilial,_cNumPed)

Local _cRet := Space(6)

Begin Sequence
   DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
   If DAI->(MsSeek(_cFilial + _cNumPed))
      _cRet := DAI->DAI_COD
   EndIf 
End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: ROMS002R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/03/2023
Descrição---------: Rotina para retornar a Região do Gerente.
Parametros--------: _cCodCoord = Código do Coordenador
                    _cCodGer   = Código do Gerente
Retorno-----------: _cRet      = Região do Gerente ou Espaços.
===============================================================================================================================
*/
User Function ROMS002R(_cCodCoord,_cCodGer)

Local _cRet := "  "

Begin Sequence
   ZAM->(DBSetOrder(1)) // ZAM_FILIAL+ZAM_COOCOD+ZAM_GERCOD+ZAM_REGCOD
   If ZAM->(MsSeek(xFilial("ZAM")+_cCodCoord + _cCodGer))
      _cRet := Tabela("ZC",ZAM->ZAM_REGCOD,.F.) 
   EndIf 
End Sequence

Return _cRet 
 
/*
===============================================================================================================================
Programa----------: ROMS2DLT
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 22/01/2018
Descrição---------: Função para retornar os dias de viagem, operação e lead time
===============================================================================================================================
*/
User Function ROMS2DLT(_cColuna)

Local _nRet      := 0
Local _lAchou    := .F.
Local _cFilCarreg:= " "

Static nRenoZEL  := 0
Static nRenoSZG5 := 0
Static cTipofrete:= " "
Static _cRegra   := " "

If _cColuna == "DIASVIAGEM"
    SC5->(DBGoTo((_cAlias)->SC5RECNO))
    _cFilCarreg := SC5->C5_FILIAL 
    If !Empty(SC5->C5_I_FLFNC)
        _cFilCarreg := SC5->C5_I_FLFNC
    EndIf 
    _cFilFt := SC5->C5_FILIAL 
    If !Empty(SC5->C5_I_FILFT)
        _cFilFt := SC5->C5_I_FILFT
    EndIf

    aHeader   :={}
    aCols     :={}
    _lAchouZG5:=.F.
    _lAchou:= (U_OMSVLDENT(DATE(),SC5->C5_CLIENTE,SC5->C5_LOJACLI,_cFilFt,SC5->C5_NUM,0,.F.,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN,@_lAchouZG5,@_cRegra))

    If _lAchouZG5
        ZEL->(DBSetOrder(1))//  // ZEL_FILIAL+ZEL_CODIGO - FILIAL COMPARTILHADA
        ZEL->(DBSeek(xFilial()+SC5->C5_I_LOCEM))
        cTipofrete:= SC5->C5_I_TPVEN
        nRenoSZG5 := ZG5->(RECNO())
        nRenoZEL  := ZEL->(RECNO())
        If cTipofrete = "F"
            _nRet :=ZG5->ZG5_DIASV
        ElseIf cTipofrete = "V"
            _nRet :=ZG5->ZG5_FRDIAV
        EndIf
    Else
        nRenoSZG5:=0
        nRenoZEL :=0
    EndIf
ElseIf _cColuna == "DIASOPERAC" .And. nRenoSZG5 > 0
    ZG5->(DBGoTo(nRenoSZG5))
    ZG5->(DBGoTo(nRenoZEL))
    If cTipofrete = "F"
        _nRet :=ZEL->ZEL_TMPOPE//ZG5->ZG5_TMPOPE
    ElseIf cTipofrete = "V"
        _nRet :=ZEL->ZEL_TMPOPE//ZG5->ZG5_FRTOP
    EndIf
ElseIf _cColuna == "LEADTIME" .And. nRenoSZG5 > 0
    ZG5->(DBGoTo(nRenoSZG5))
    ZG5->(DBGoTo(nRenoZEL))
    If cTipofrete = "F"
        _nRet :=(ZG5->ZG5_DIASV+ZEL->ZEL_TMPOPE)//ZG5->ZG5_TMPOPE
    ElseIf cTipofrete = "V"
        _nRet :=(ZG5->ZG5_DIASV+ZEL->ZEL_TMPOPE)//ZG5->ZG5_FRTOP
    EndIf
    cTipofrete:=" "
    nRenoSZG5:=0
ElseIf _cColuna == "REGRA" 
    _nRet:=_cRegra
    _cRegra:=""
EndIf

Return _nRet

/*
===============================================================================================================================
Programa----------: ROMS2VEI
Autor-------------: Igor Melgaço
Data da Criacao---: 23/10/2022
Descrição---------: Retorna Veiculo de acordo com a qtd de Palletes
Parametros--------: 
Retorno-----------: _cReturn
===============================================================================================================================
*/
Static Function ROMS2VEI()

Local _cReturn := ""

If _nTQtdPallets <= 10
    _cReturn := "Sem veiculo"
ElseIf _nTQtdPallets >= 11 .And. _nTQtdPallets <= 14
    _cReturn := "Truck"
ElseIf _nTQtdPallets >= 15 .And. _nTQtdPallets <= 19
    _cReturn := "Sem veiculo"	
ElseIf _nTQtdPallets >= 20 .And. _nTQtdPallets <= 30
    _cReturn := "Carreta"
ElseIf _nTQtdPallets >= 31 .And. _nTQtdPallets <= 50
    _cReturn := "RodoTrem"
Else
    _cReturn := "Sem veiculo"
EndIf

Return _cReturn

/*
===============================================================================================================================
Programa----------: ROMS2VEI
Autor-------------: Igor Melgaço
Data da Criacao---: 23/10/2022
Descrição---------: Retorna Veiculo de acordo com a qtd de Palletes
Parametros--------: 
Retorno-----------: _cReturn
===============================================================================================================================
*/
Static Function ROMS2VIT()

Local _cReturn := ""

If _nTQtdPalItem <= 10
    _cReturn := "Sem veiculo"
ElseIf _nTQtdPalItem >= 11 .And. _nTQtdPalItem <= 14
    _cReturn := "Truck"
ElseIf _nTQtdPalItem >= 15 .And. _nTQtdPalItem <= 19
    _cReturn := "Sem veiculo"	
ElseIf _nTQtdPalItem >= 20 .And. _nTQtdPalItem <= 30
    _cReturn := "Carreta"
ElseIf _nTQtdPalItem >= 31 .And. _nTQtdPalItem <= 50
    _cReturn := "RodoTrem"
Else
    _cReturn := "Sem veiculo"
EndIf

Return _cReturn

/*
===============================================================================================================================
Programa----------: ROMS2USR
Autor-------------: Igor Melgaço
Data da Criacao---: 23/10/2022
Descrição---------: Retorna usuario data e Hora em uma coluna e grava a variavel _cJustificativas e _cClassEnt
Parametros--------: _cCampos: Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI || ZY3_JUSCOD
                    _nChama: 1 = 1a coluna / 2 = 2a coluna / 3 = 2a coluna e preenche a variavel _cClassEnt
Retorno-----------: _cReturn: Y3_2.ZY3_CODUSR || ZY3_2.ZY3_DTMONI || ZY3_2.ZY3_HRMONI - _cNome + " " + _cData + " " + _cHora
===============================================================================================================================
*/
Static Function ROMS2USR(_cCampos,_nChama)

Local _cNome   := ""
Local _cData   := ""
Local _cHora   := ""
Local _cRetorno:= Space(6+8+8)
Local _cJusCod := ""
Local _cJusDes := ""

If !Empty(AllTrim(_cCampos))
    _cNome   := UsrFullName(Subs(_cCampos,1,6))
    _cData   := DToC(SToD(Subs(_cCampos,7,8)))
    _cHora   := Subs(_cCampos,15,Len(ZY3->ZY3_HRMONI))
    _cRetorno:= _cNome + " " + _cData + " " + _cHora

    _cJusCod := Subs(_cCampos,20,Len(ZY3->ZY3_JUSCOD))
    If !Empty(_cJusCod)
        _cJusDes := Upper(AllTrim(Posicione("ZY5",1,xFilial("ZY5")+_cJusCod,"ZY5_DESCR")))
        If _nChama = 1
            _cJustificativas:=_cJusDes
        ElseIf _nChama >= 2 .And. !_cJusDes $ _cJustificativas .And. !Empty(_cJusDes)
            If !Empty(_cJustificativas)
                _cJustificativas+=" // "+_cJusDes
            Else
                _cJustificativas:=_cJusDes
            EndIf
        EndIf
    ElseIf _nChama = 1
        _cJustificativas:=""
    EndIf
EndIf

If _nChama = 3
    _cClassEnt:=(_cAlias)->A1_I_CLABC
    If _cClassEnt = '1'
        _cClassEnt:="1-TOP 1 NACIONAL"
    ElseIf _cClassEnt = '2'
        _cClassEnt:="2-TOP 5 Reg. SP "
    ElseIf _cClassEnt = '3'
        _cClassEnt:="3-TOP 5 Reg. RS "
    EndIf
EndIf

Return _cRetorno

/*
===============================================================================================================================
Programa----------: ROMS002Q
Autor-------------: Igor Melgaço
Data da Criacao---: 27/06/2024
Descrição---------: Executa query da Ordem 1 e retorna array de dados
Parametros--------: cFilBloqueio,cFiltro,oProc
Retorno-----------: _aDados
===============================================================================================================================
*/
Static Function ROMS002Q(cFilBloqueio,cFiltro,oProc)

Local _cCposSD2  := ""
Local _aLinha    := {}
Local _aDados    := {}
Local _nTotReg   := 0
Local _aOpcoes   := {}
Local _aOpAgen   := {}
Local _aOpCarg   := {}

Private nConta   := 0

_aOpcoes := ROMS002X3("C5_TPFRETE")
_aOpAgen := ROMS002X3("C5_I_AGEND")
_aOpCarg := ROMS002X3("C5_I_TIPCA")

oProc:cCaption := ("1-Executando leitura do Banco de dados (SELECT)...")
ProcessMessages()

_cCposSD2 := "%"

//CAMPOS DE SUB SELECT DO SD2
_cCposSD2 += " (SELECT NVL(SUM ( (D2_QTDEDEV)), 0) "
_cCposSD2 += "    FROM " + RetSqlName("SD2") + " SD2 "
_cCposSD2 += "   WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL "
_cCposSD2 += "     AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
_cCposSD2 += "     AND SD2.D2_LOJA    = SF2.F2_LOJA "
_cCposSD2 += "     AND SD2.D2_DOC     = SF2.F2_DOC "
_cCposSD2 += "     AND SD2.D2_SERIE   = SF2.F2_SERIE "
_cCposSD2 += "     AND SD2.D2_COD     = SC6.C6_PRODUTO "
_cCposSD2 += "     AND SD2.D_E_L_E_T_ = ' ') D2_QTDEDEV, "

_cCposSD2 += " (SELECT NVL(SUM ( (D2_VALDEV)), 0) "
_cCposSD2 += "    FROM " + RetSqlName("SD2") + " SD2 "
_cCposSD2 += "   WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL "
_cCposSD2 += "     AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
_cCposSD2 += "     AND SD2.D2_LOJA    = SF2.F2_LOJA "
_cCposSD2 += "     AND SD2.D2_DOC     = SF2.F2_DOC "
_cCposSD2 += "     AND SD2.D2_SERIE   = SF2.F2_SERIE "
_cCposSD2 += "     AND SD2.D2_COD     = SC6.C6_PRODUTO "
_cCposSD2 += "     AND SD2.D_E_L_E_T_ = ' ') D2_VALDEV, "

_cCposSD2 += "(SELECT NVL(SUM (D1_QTSEGUM), 0) "
_cCposSD2 += "    FROM " + RetSqlName("SD1") + " SD1 , " + RetSqlName("SD2") + " SD2"
_cCposSD2 += "   WHERE SD2.D2_FILIAL    = SF2.F2_FILIAL "
_cCposSD2 += "     AND SD2.D2_CLIENTE   = SF2.F2_CLIENTE "
_cCposSD2 += "     AND SD2.D2_LOJA      = SF2.F2_LOJA "
_cCposSD2 += "     AND SD2.D2_DOC       = SF2.F2_DOC "
_cCposSD2 += "     AND SD2.D2_SERIE     = SF2.F2_SERIE "
_cCposSD2 += "     AND SD2.D2_COD       = SC6.C6_PRODUTO "
_cCposSD2 += "      AND SD1.D1_FILIAL   = SD2.D2_FILIAL "
_cCposSD2 += "      AND SD1.D1_FORNECE  = SD2.D2_CLIENTE "
_cCposSD2 += "      AND SD1.D1_LOJA     = SD2.D2_LOJA "
_cCposSD2 += "      AND SD1.D1_DTDIGIT >= SD2.D2_EMISSAO "
_cCposSD2 += "      AND SD1.D1_NFORI    = SD2.D2_DOC "
_cCposSD2 += "      AND SD1.D1_SERIORI  = SD2.D2_SERIE "
_cCposSD2 += "      AND SD1.D1_COD      = SD2.D2_COD "
_cCposSD2 += "      AND SD1.D1_ITEMORI  = SD2.D2_ITEM "
_cCposSD2 += "      AND SD1.D1_TIPO     = 'D' "
_cCposSD2 += "      AND SD1.D1_TES     <> ' ' "
_cCposSD2 += "      AND SD1.D_E_L_E_T_  = ' ') D1_QTSEGUM " 

_cCposSD2 += "%"

_cCposNovos := "%"
If SC5->(FIELDPOS("C5_I_AGRUP")) > 0 
    _cCposNovos+= " SC5.C5_I_AGRUP, "
EndIf 
If SC5->(FIELDPOS("C5_I_DIASV")) > 0 
    _cCposNovos+= " SC5.C5_I_DIASV, "
EndIf
If SC5->(FIELDPOS("C5_I_DIASO")) > 0
    _cCposNovos+= " SC5.C5_I_DIASO, "
EndIf
If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
    _cCposNovos+= " SC5.C5_I_BLSLD, "
EndIf
_cCposNovos+= "%"

If Select(_cAlias) > 0
    (_cAlias)->(DBCloseArea())
EndIf

BeginSql alias _cAlias   	
    SELECT 
       SC5.R_E_C_N_O_ SC5RECNO,
       SC5.C5_NUM,
       SC6.C6_LOCAL,
       SC5.C5_I_PEVIN, 
       SC6.C6_ITEM,
       SC5.C5_EMISSAO,
       SC5.C5_I_DTENT, 
       SC5.C5_CLIENT C6_CLI, 
       SC5.C5_LOJAENT C6_LOJA,
       SC5.C5_NOTA,
       SA1.A1_NOME,
       SA1.A1_NREDUZ,
       SA1.A1_I_CCHEP,			
       SA1.A1_CEP,
       SA1.A1_I_CLABC,
       SC6.C6_PRODUTO,
       SC6.C6_QTDVEN,
       SC6.C6_PRCVEN,
       SC6.C6_VALOR,
       SC6.C6_UM,
       SC6.C6_SEGUM,
       SC6.C6_QTDENT,
       SC6.C6_I_PDESC,
       SC6.C6_I_PRMIN,
       SC6.C6_I_VLIBB,
       SB1.B1_I_DESCD,
       SB1.B1_COD,
       SB1.B1_I_CXPAL,
       SB1.B1_I_BIMIX,
       SC5.C5_VEND1,
       SC5.C5_I_V1NOM,
       SC5.C5_VEND2,
       SC5.C5_I_V2NOM,
       SC5.C5_VEND3,
       SC5.C5_I_V3NOM,
       SA3.A3_COD,
       SA3.A3_NOME,
       SA3.A3_SUPER,
       ACY.ACY_DESCRI,
       ACY.ACY_GRPVEN,
       SC6.C6_UNSVEN,
       SC6.C6_I_KIT,     
       (SELECT SUM(C6_UNSVEN) FROM %Table:SC6% SC6T WHERE SC6T.%notDel%  AND SC6T.C6_FILIAL = SC5.C5_FILIAL  AND SC6T.C6_NUM = SC5.C5_NUM ) C6_UNSVENTOT,//Qtd Ven 2 UM ,
       SC6.C6_FILIAL AS C6_FILIAL,
       SC6.C6_QTDLIB,
       SC6.C6_NUM,
       SC6.C6_I_DQESP,
       SA1.A1_CGC,
       SA1.A1_MUN,
       SA1.A1_BAIRRO,
       SA1.A1_EST,
       SA1.A1_I_GRDES,
       SA1.A1_I_GRCLI,
       SA1.A1_I_SHLFP,
       SC6.C6_PEDCLI,
       (Round((SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
       (SB1.B1_PESBRU * SC6.C6_QTDVEN) PESTOTAL,
       SC5.C5_I_PESBR,
       SC5.C5_I_TIPCA,
       SC5.C5_I_AGEND,
       SC5.C5_I_SENHA,
       SC5.C5_I_HOREN,
       SC5.C5_I_DOCA,
       SC5.C5_I_CHAPA,
       SC5.C5_I_CHPCL,
       SC5.C5_I_OBPED,
       SC5.C5_MENNOTA,
       SC5.C5_I_OPER,
       SC5.C5_I_TRCNF,  
       SC5.C5_I_FILFT,  
       SC5.C5_I_FLFNC,
       SC5.C5_I_EVENT,
       SC5.C5_I_IDPED,
       SC5.C5_FILIAL,
       SBM.BM_DESC,
       ZA1.ZA1_DESCRI,
       ZA3.ZA3_DESCRI,
       ZZ6.ZZ6_DESCRO,
       SZW.ZW_TABELA,
       SC5.C5_I_OPTRI,
       SC5.C5_I_PVREM,
       SC5.C5_I_PVFAT,
       SC5.C5_ASSCOD,
       SC5.C5_ASSNOM,
       SC5.C5_I_LOCEM,
       SC5.C5_I_QTDA,
       SC5.C5_I_PEDOR,
       SC5.C5_I_PODES,	   
         Case 
            WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'SEM BLQ'                  
            WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ  = 'B' THEN 'BLQ CREDITO/BLQ PRECO/BLQ BONIf'
            WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLOQ   = 'B' THEN 'BLQ CREDITO/BLQ BONIf'   
            WHEN SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ   = 'B' THEN 'BLQ PRECO/BLQ BONIf'     
            WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC  = 'B' THEN 'BLQ CREDITO/BLQ PRECO' 
            WHEN SC5.C5_I_BLCRE  = 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'BLQ CREDITO'
            WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC  = 'B' AND SC5.C5_I_BLOQ <> 'B' THEN 'BLQ PRECO'
            WHEN SC5.C5_I_BLCRE <> 'B' AND SC5.C5_I_BLPRC <> 'B' AND SC5.C5_I_BLOQ  = 'B' THEN 'BLQ BONIf'
         END AS SITUACAO,
       SC5.C5_CONDPAG,
       SC5.C5_TPFRETE,
       SE4.E4_DESCRI,
       SC5.C5_DESCONT,  
       SC5.C5_VEND4, 
       SF2.F2_EMISSAO,
       SF2.F2_I_NTRAN,
       SF2.F2_I_NTRIA, 
       SF2.F2_I_STRIA,
       SF2.F2_I_DTRIA,
       SF2.F2_I_DTRC,  
       SF2.F2_CHVNFE, 
       SF2.F2_I_PENCL,
       SF2.F2_I_DENCL,
       SC5.C5_LIBEROK, DAI.DAI_DATA, DAI.DAI_COD, SC5.C5_I_DTPRV, SC5.C5_I_DTSAG, SC5.C5_I_ARQOP,
       SC5.C5_I_TAB, DA0.DA0_DESCRI, SC6.C6_I_FXPES, C6_I_VLTAB,
       SA32.A3_NOME AS A32_NOME,
       SA3.A3_TIPO,
       SC5.C5_VEND2 AS ORDER_VEND2,
       SC5.C5_VEND3,
       SC9.C9_I_USLIB,
       ZZL.ZZL_NOME,
       SC9.C9_DATALIB,
       CC2.CC2_I_MESO,
       CC2.CC2_I_MICR,
       SC5.C5_I_PDPR,
       SC5.C5_I_FLFNC,
       SC5.C5_I_FILFT,
       SC5.C5_I_PDFT,
       SC5.C5_I_NOME,
       SC5.C5_I_FANTA,
       Z21.Z21_NOME,
       Z22.Z22_NOME,
       ZY4.ZY4_DESCRI,
       ZEL.ZEL_DESCRI,
       SZW.ZW_PEDIMPO,
       ZAM.ZAM_REGCOD, %exp:_cCposNovos%
       SC5R.C5_FILIAL  R_C5_FILIAL,
       SC5R.C5_NUM     R_C5_NUM,
       SC5R.C5_CLIENT  R_C5_CLIENT, 
       SC5R.C5_LOJAENT R_C5_LOJAENT,
       SC5R.C5_NOTA    R_C5_NOTA,
       SA1R.A1_NOME    R_A1_NOME,
       SA1R.A1_NREDUZ  R_A1_NREDUZ,
       SF2R.F2_SERIE   R_F2_SERIE,
       SF2R.F2_EMISSAO R_F2_EMISSAO,
       SF2R.F2_I_NTRAN R_F2_I_NTRAN,
       SF2R.F2_I_NTRIA R_F2_I_NTRIA, 
       SF2R.F2_I_STRIA R_F2_I_STRIA,
       SF2R.F2_I_DTRIA R_F2_I_DTRIA,
       SF2R.F2_I_DTRC  R_F2_I_DTRC,  
       SF2R.F2_CHVNFE  R_F2_CHVNFE, 
       SC5F.C5_FILIAL  F_C5_FILIAL,
       SC5F.C5_I_FLFNC F_C5_I_FLFNC,
       SC5F.C5_NUM     F_C5_NUM,
       SC5F.C5_I_PDPR  F_C5_I_PDPR,
       SC5F.C5_CLIENT  F_C5_CLIENT,
       SC5F.C5_LOJAENT F_C5_LOJA,
       SC5F.C5_NOTA    F_C5_NOTA,
       SA1F.A1_NOME    F_A1_NOME,
       SA1F.A1_NREDUZ  F_A1_NREDUZ,
       SC5F.C5_SERIE   F_C5_SERIE,
       SF2F.F2_SERIE   F_F2_SERIE,
       SF2F.F2_EMISSAO F_F2_EMISSAO,
       SF2F.F2_I_NTRAN F_F2_I_NTRAN,
       SF2F.F2_I_NTRIA F_F2_I_NTRIA, 
       SF2F.F2_I_STRIA F_F2_I_STRIA,
       SF2F.F2_I_DTRIA F_F2_I_DTRIA,
       SF2F.F2_I_DTRC  F_F2_I_DTRC, 
       SF2F.F2_CHVNFE  F_F2_CHVNFE,   		
       SC5T.C5_FILIAL  T_C5_FILIAL,
       SC5T.C5_I_FILFT T_C5_I_FILFT,
       SC5T.C5_NUM     T_C5_NUM,
       SC5T.C5_I_PDFT  T_C5_I_PDFT ,
       SC5T.C5_CLIENT  T_C5_CLIENT, 
       SC5T.C5_LOJAENT T_C5_LOJA,
       SC5T.C5_NOTA    T_C5_NOTA,
       SA1T.A1_NOME    T_A1_NOME,
       SA1T.A1_NREDUZ  T_A1_NREDUZ,
       SC5T.C5_SERIE   T_C5_SERIE,
       SF2T.F2_SERIE   T_F2_SERIE,
       SF2T.F2_EMISSAO T_F2_EMISSAO,
       SF2T.F2_I_NTRAN T_F2_I_NTRAN,
       SF2T.F2_I_NTRIA T_F2_I_NTRIA, 
       SF2T.F2_I_STRIA T_F2_I_STRIA,
       SF2T.F2_I_DTRIA T_F2_I_DTRIA,
       SF2T.F2_I_DTRC  T_F2_I_DTRC,  
       SF2T.F2_CHVNFE  T_F2_CHVNFE, 		
       SC5V.C5_FILIAL  V_C5_FILIAL,
       SC5V.C5_NUM     V_C5_NUM,
       SC5V.C5_CLIENT  V_C5_CLIENT, 
       SC5V.C5_LOJAENT V_C5_LOJAENT,
       SC5V.C5_NOTA    V_C5_NOTA,
       SA1V.A1_NOME    V_A1_NOME,
       SA1V.A1_NREDUZ  V_A1_NREDUZ,
       SF2V.F2_SERIE   V_F2_SERIE,
       SF2V.F2_EMISSAO V_F2_EMISSAO,
       SF2V.F2_I_NTRAN V_F2_I_NTRAN,
       SF2V.F2_I_NTRIA V_F2_I_NTRIA, 
       SF2V.F2_I_STRIA V_F2_I_STRIA,
       SF2V.F2_I_DTRIA V_F2_I_DTRIA,
       SF2V.F2_I_DTRC  V_F2_I_DTRC,  
       SF2V.F2_CHVNFE  V_F2_CHVNFE,
       SM0.M0_FILIAL,
        (
            SELECT TRIM(ZY3_2.ZY3_COMENT) ||' POR ' || SUBSTR(ZY3_2.ZY3_NOMUSR,1,10) || ' EM : ' || SUBSTR(ZY3_2.ZY3_DTMONI, 7, 2) || '/' || SUBSTR(ZY3_2.ZY3_DTMONI, 5, 2) || '/' || SUBSTR(ZY3_2.ZY3_DTMONI, 1, 4) || ' AS ' || ZY3_2.ZY3_HRMONI 
            FROM (
                    SELECT ZY3_FILFT,ZY3_NUMPV, ZY3_NOMUSR,ZY3_DTMONI,ZY3_HRMONI, MAX(R_E_C_N_O_) AS RECNO 
                    FROM %Table:ZY3% ZY3
                    WHERE ZY3.%notDel%
                        AND ZY3.ZY3_NUMPV = SC5.C5_NUM 
                        AND ROWNUM = 1  
                        AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Data de entrega modificada%')
                    GROUP BY ZY3_FILFT, ZY3_NUMPV,ZY3_NOMUSR,ZY3_DTMONI,ZY3_HRMONI
                    ORDER BY RECNO DESC
                    ) ZY3
            LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
            WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
            AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
        )  AS USR_DTENT,
        ( 
            SELECT TRIM(ZY3_2.ZY3_COMENT) ||' POR ' || SUBSTR(ZY3_2.ZY3_NOMUSR,1,10) || ' EM : ' ||  SUBSTR(ZY3_2.ZY3_DTMONI, 7, 2) || '/' || SUBSTR(ZY3_2.ZY3_DTMONI, 5, 2) || '/' || SUBSTR(ZY3_2.ZY3_DTMONI, 1, 4) || ' AS ' || ZY3_2.ZY3_HRMONI 
            FROM (
                    SELECT ZY3_FILFT,ZY3_NUMPV, ZY3_NOMUSR,ZY3_DTMONI,ZY3_HRMONI, MAX(R_E_C_N_O_) AS RECNO 
                    FROM %Table:ZY3% ZY3
                    WHERE ZY3.%notDel%
                        AND ZY3.ZY3_NUMPV = SC5.C5_NUM 
                        AND ROWNUM = 1  
                        AND Upper(ZY3.ZY3_COMENT) LIKE Upper('%Tipo de Agendamento modificada%')
                    GROUP BY ZY3_FILFT, ZY3_NUMPV,ZY3_NOMUSR,ZY3_DTMONI,ZY3_HRMONI
                    ORDER BY RECNO DESC
                    ) ZY3
            LEFT JOIN %Table:ZY3% ZY3_2 ON ZY3_2.R_E_C_N_O_ = ZY3.RECNO
            WHERE ZY3.ZY3_NUMPV = SC5.C5_NUM 
            AND ZY3.ZY3_FILFT = SC5.C5_FILIAL
        )  AS USR_TPAGEN,
        %exp:_cCposSD2%//SE For POR MAIS CAMPOS DEIXE ESSE SEMPRE POR ULTIMO
   FROM 
       %Table:SC5% SC5
       JOIN %Table:SC6% SC6 ON SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM
       %exp:cFilBloqueio%
       JOIN %Table:SA1% SA1  ON SA1.A1_FILIAL  = ' ' AND SA1.A1_COD      = SC5.C5_CLIENT AND SA1.A1_LOJA = SC5.C5_LOJAENT
       JOIN %Table:SB1% SB1  ON SB1.B1_FILIAL  = ' ' AND SB1.B1_COD      = SC6.C6_PRODUTO
       JOIN %Table:SA3% SA3  ON SA3.A3_FILIAL  = ' ' AND SA3.A3_COD      = SC5.C5_VEND1			   
       LEFT JOIN %Table:CC2% CC2  ON CC2.CC2_FILIAL = ' ' AND CC2.CC2_EST     = SA1.A1_EST     AND CC2.CC2_CODMUN = SA1.A1_COD_MUN AND CC2.%notDel%
       LEFT JOIN %Table:SBM% SBM  ON SBM.BM_FILIAL  = ' ' AND SB1.B1_GRUPO    = SBM.BM_GRUPO   AND SBM.%notDel%	
       LEFT JOIN %Table:ACY% ACY  ON ACY.ACY_FILIAL = ' ' AND SA1.A1_GRPVEN   = ACY.ACY_GRPVEN AND ACY.%notDel%		
       LEFT JOIN %Table:SE4% SE4  ON SE4.E4_FILIAL  = ' ' AND SE4.E4_CODIGO   = SC5.C5_CONDPAG AND SE4.%notDel%
       LEFT JOIN %Table:ZA1% ZA1  ON ZA1.ZA1_FILIAL = ' ' AND ZA1.ZA1_COD     = SB1.B1_I_NIV2  AND ZA1.ZA1_CDGRUP = SB1.B1_GRUPO  AND ZA1.%notDel%	
       LEFT JOIN %Table:ZA3% ZA3  ON ZA3.ZA3_FILIAL = ' ' AND ZA3.ZA3_COD     = SB1.B1_I_NIV4  AND ZA3.%notDel%
       LEFT JOIN %Table:ZZ6% ZZ6  ON ZZ6.ZZ6_FILIAL = ' ' AND ZZ6.ZZ6_CODIGO  = SA1.A1_I_GRCLI AND ZZ6.%notDel% 
       LEFT JOIN %Table:DA0% DA0  ON DA0.DA0_FILIAL = ' ' AND DA0.DA0_CODTAB  = SC5.C5_I_TAB   AND DA0.%notDel%
       LEFT JOIN %Table:SZW% SZW  ON SZW.ZW_FILIAL  = SC5.C5_FILIAL AND SZW.ZW_IDPED   = SC5.C5_I_IDPED  AND SZW.ZW_ITEM  = 1 AND SZW.%notDel%
       LEFT JOIN %Table:SF2% SF2  ON SF2.F2_FILIAL  = SC5.C5_FILIAL AND SF2.F2_DOC     = SC5.C5_NOTA     AND SF2.F2_SERIE = SC5.C5_SERIE AND SF2.F2_CLIENT = SC5.C5_CLIENTE AND SF2.F2_LOJA = SC5.C5_LOJACLI AND SF2.%notDel%	     
       LEFT JOIN %Table:DAI% DAI  ON DAI.DAI_FILIAL = SC5.C5_FILIAL AND DAI.DAI_CLIENT =  SC5.C5_CLIENTE AND DAI.DAI_LOJA = SC5.C5_LOJACLI  AND DAI.DAI_PEDIDO = SC5.C5_NUM AND DAI.%notDel%
       LEFT JOIN SYS_COMPANY SM0  ON SM0.M0_CODFIL  = SC5.C5_FILIAL AND SM0.%notDel%
      
        //Nota de Remessa - Faturamento da Triangular
        LEFT JOIN %Table:SC5% SC5R ON SC5R.C5_FILIAL = SC5.C5_FILIAL AND SC5R.C5_NUM    = SC5.C5_I_PVREM  AND SC5R.%notDel%
        LEFT JOIN %Table:SA1% SA1R ON SA1R.A1_FILIAL = ' ' AND SA1R.A1_COD  = SC5R.C5_CLIENT AND SA1R.A1_LOJA = SC5R.C5_LOJAENT and SA1R.%notDel%
        LEFT JOIN %Table:SF2% SF2R ON SF2R.F2_FILIAL  = SC5R.C5_FILIAL AND SF2R.F2_DOC     = SC5R.C5_NOTA     AND SF2R.F2_SERIE = SC5R.C5_SERIE AND SF2R.F2_CLIENT = SC5R.C5_CLIENTE AND SF2R.F2_LOJA = SC5R.C5_LOJACLI AND SF2R.%notDel%
        
        //Nota de Venda - Faturamento da Triangular
        LEFT JOIN %Table:SC5% SC5V ON SC5V.C5_FILIAL = SC5.C5_FILIAL AND SC5V.C5_NUM    = SC5.C5_I_PVFAT AND SC5V.%notDel%
        LEFT JOIN %Table:SA1% SA1V ON SA1V.A1_FILIAL = ' ' AND SA1V.A1_COD  = SC5V.C5_CLIENTE AND SA1V.A1_LOJA = SC5V.C5_LOJAENT and SA1V.%notDel%
        LEFT JOIN %Table:SF2% SF2V ON SF2V.F2_FILIAL  = SC5V.C5_FILIAL AND SF2V.F2_DOC     = SC5V.C5_NOTA     AND SF2V.F2_SERIE = SC5V.C5_SERIE AND SF2V.F2_CLIENT = SC5V.C5_CLIENTE AND SF2V.F2_LOJA = SC5V.C5_LOJACLI AND SF2V.%notDel%

        //Nota de Faturamento
        LEFT JOIN %Table:SC5% SC5F ON SC5F.C5_FILIAL = SC5.C5_I_FLFNC AND SC5F.C5_NUM = SC5.C5_I_PDPR AND SC5F.%notDel%
        LEFT JOIN %Table:SA1% SA1F ON SA1F.A1_FILIAL = ' ' AND SA1F.A1_COD = SC5F.C5_CLIENT AND SA1F.A1_LOJA = SC5F.C5_LOJAENT and SA1F.%notDel%
        LEFT JOIN %Table:SF2% SF2F ON SF2F.F2_FILIAL = SC5F.C5_FILIAL AND SF2F.F2_DOC = SC5F.C5_NOTA AND SF2F.F2_SERIE = SC5F.C5_SERIE AND SF2F.F2_CLIENT = SC5F.C5_CLIENTE AND SF2F.F2_LOJA = SC5F.C5_LOJACLI AND SF2F.%notDel%

        //Nota de Transferencia
        LEFT JOIN %Table:SC5% SC5T ON SC5T.C5_FILIAL = SC5.C5_I_FILFT AND SC5T.C5_NUM    = SC5.C5_I_PDFT  AND SC5T.%notDel%
        LEFT JOIN %Table:SA1% SA1T ON SA1T.A1_FILIAL = ' ' AND SA1T.A1_COD  = SC5T.C5_CLIENTE AND SA1T.A1_LOJA = SC5T.C5_LOJAENT and SA1T.%notDel%
        LEFT JOIN %Table:SF2% SF2T ON SF2T.F2_FILIAL  = SC5T.C5_FILIAL AND SF2T.F2_DOC     = SC5T.C5_NOTA     AND SF2T.F2_SERIE = SC5T.C5_SERIE AND SF2T.F2_CLIENT = SC5T.C5_CLIENTE AND SF2T.F2_LOJA = SC5T.C5_LOJACLI AND SF2T.%notDel%
        
        LEFT JOIN %Table:SA3% SA32 ON SA32.A3_FILIAL = ' ' AND SA32.A3_COD  = SC5.C5_VEND4   AND SA32.%notDel%
        
        LEFT JOIN %Table:Z21% Z21  ON Z21.Z21_FILIAL = ' ' AND Z21.Z21_EST    = SA1.A1_EST  AND Z21.Z21_COD = CC2.CC2_I_MESO AND Z21.%notDel%
        LEFT JOIN %Table:Z22% Z22  ON Z22.Z22_FILIAL = ' ' AND Z22.Z22_EST    = SA1.A1_EST  AND Z22.Z22_MESO = CC2.CC2_I_MESO AND Z22.Z22_COD = CC2.CC2_I_MICR AND Z22.%notDel%
        LEFT JOIN %Table:ZY4% ZY4  ON ZY4.ZY4_FILIAL = ' ' AND ZY4.ZY4_EVENTO = SC5.C5_I_EVENT AND ZY4.%notDel%
        LEFT JOIN %Table:ZEL% ZEL  ON ZEL.ZEL_FILIAL = ' ' AND ZEL.ZEL_CODIGO = SC5.C5_I_LOCEM AND ZEL.%notDel%
        LEFT JOIN %Table:ZAM% ZAM  ON ZAM.ZAM_FILIAL = ' ' AND ZAM.ZAM_COOCOD = SC5.C5_VEND2 AND ZAM.ZAM_GERCOD = SC5.C5_VEND3 AND ZAM.%notDel%
   WHERE 
       SC5.%notDel%  
       AND SC6.%notDel%  
       AND SA1.%notDel%  	 	
       AND SB1.%notDel%  					
       AND SA3.%notDel%  											
       AND SC6.C6_BLQ <> 'R'
       %exp:cFiltro%
    ORDER BY 
        SC6.C6_FILIAL,SC5.C5_VEND2,SC5.C5_VEND1,SC6.C6_CLI,SC5.C5_NUM			   
EndSql

DBSelectArea(_cAlias) 
(_cAlias)->(DBGoTop())   

Count to _nTotReg

_cTot := AllTrim(Str(_nTotReg))

(_cAlias)->(DBGoTop())   
While (_cAlias)->(!Eof())
    nConta++

    oProc:cCaption := ("Lendo Registro: " + AllTrim(Str(nConta)) + " de " + _cTot )
    ProcessMessages()

    _aLinha := {}
    aAdd(_aLinha,(_cAlias)->C6_FILIAL)
    aAdd(_aLinha,(_cAlias)->M0_FILIAL)
    aAdd(_aLinha,(_cAlias)->C5_VEND2) //"Coordenador"
    aAdd(_aLinha,(_cAlias)->C5_I_V2NOM) // NOME
    aAdd(_aLinha,(_cAlias)->C5_VEND1) 
    aAdd(_aLinha,(_cAlias)->A3_NOME) 
    aAdd(_aLinha,If((_cAlias)->A3_TIPO=="E","Externo","Interno")) 
    aAdd(_aLinha,(_cAlias)->C5_VEND3) 
    aAdd(_aLinha,(_cAlias)->C5_I_V3NOM) 
    aAdd(_aLinha,Tabela("ZC",(_cAlias)->ZAM_REGCOD,.F.)) 
    aAdd(_aLinha,(_cAlias)->C5_NUM) 
    aAdd(_aLinha,(_cAlias)->C6_LOCAL) 
    aAdd(_aLinha,(_cAlias)->C5_I_IDPED) 
    aAdd(_aLinha,(_cAlias)->ZW_PEDIMPO) 
    aAdd(_aLinha,(_cAlias)->C5_I_OPER) 
    aAdd(_aLinha,(_cAlias)->C5_I_PEVIN) 
    aAdd(_aLinha,(_cAlias)->C6_CLI)
    aAdd(_aLinha,(_cAlias)->C6_LOJA)
    aAdd(_aLinha,(_cAlias)->A1_NOME)
    aAdd(_aLinha,(_cAlias)->A1_NREDUZ)
    aAdd(_aLinha,(_cAlias)->A1_I_GRDES)
    aAdd(_aLinha,(_cAlias)->ACY_DESCRI)
    aAdd(_aLinha,(_cAlias)->A1_CGC)
    aAdd(_aLinha,ROMS002VD((_cAlias)->C5_EMISSAO))
    aAdd(_aLinha,(_cAlias)->A1_MUN)
    aAdd(_aLinha,(_cAlias)->A1_EST)
    aAdd(_aLinha,(_cAlias)->A1_BAIRRO)
    aAdd(_aLinha,(_cAlias)->A1_CEP)
    aAdd(_aLinha,(_cAlias)->B1_I_DESCD)
    aAdd(_aLinha,(_cAlias)->BM_DESC)
    aAdd(_aLinha,ROMS002VD((_cAlias)->C5_I_DTENT))
    aAdd(_aLinha,ROMS002O(_aOpAgen, U_TipoEntrega( (_cAlias)->C5_I_AGEND)) )
    aAdd(_aLinha,(_cAlias)->C6_QTDVEN - (_cAlias)->D2_QTDEDEV)
    aAdd(_aLinha,(_cAlias)->C6_UM)
    aAdd(_aLinha,(_cAlias)->C6_UNSVENTOT)
    aAdd(_aLinha,((_cAlias)->C6_UNSVEN - (_cAlias)->D1_QTSEGUM))
    aAdd(_aLinha,(_cAlias)->C6_SEGUM)
    aAdd(_aLinha,(_cAlias)->C6_PRCVEN)
    aAdd(_aLinha,(_cAlias)->C6_PRCNET)
    aAdd(_aLinha,(_cAlias)->C6_I_VLTAB)
    aAdd(_aLinha,(_cAlias)->C6_I_FXPES)
    aAdd(_aLinha,((_cAlias)->C6_QTDVEN * (_cAlias)->C6_PRCVEN) - (_cAlias)->D2_VALDEV )
    aAdd(_aLinha,(_cAlias)->C5_I_PESBR)
    aAdd(_aLinha,(_cAlias)->PESTOTAL)
    aAdd(_aLinha,(_cAlias)->C6_PEDCLI)
    aAdd(_aLinha,ROMS2CG((_cAlias)->C5_FILIAL,(_cAlias)->C5_NUM))
    aAdd(_aLinha,ROMS002CT((_cAlias)->B1_COD,(_cAlias)->C6_QTDVEN))
    aAdd(_aLinha,(_cAlias)->B1_I_CXPAL)
    If MV_PAR21 = 2//ANALITICO 
        aAdd(_aLinha,ROMS2VEI())
        aAdd(_aLinha,ROMS2VIT())
    EndIf
    aAdd(_aLinha,ROMS002O(_aOpCarg,(_cAlias)->C5_I_TIPCA) )
    aAdd(_aLinha,(_cAlias)->C5_I_SENHA)
    aAdd(_aLinha,(_cAlias)->C5_I_HOREN)
    aAdd(_aLinha,(_cAlias)->C5_I_DOCA)
    aAdd(_aLinha,(_cAlias)->C5_I_CHAPA)
    aAdd(_aLinha,(_cAlias)->C5_I_CHPCL)
    aAdd(_aLinha,(_cAlias)->C5_I_OBPED)
    aAdd(_aLinha,(_cAlias)->C5_MENNOTA)
    aAdd(_aLinha,(_cAlias)->C5_I_OPTRI)
    aAdd(_aLinha,(_cAlias)->C5_I_PVREM)
    aAdd(_aLinha,(_cAlias)->C5_I_PVFAT)
    aAdd(_aLinha,(_cAlias)->A1_I_CCHEP)
    aAdd(_aLinha,If((_cAlias)->C5_I_TRCNF=="S","SIM","NAO"))
    aAdd(_aLinha,(_cAlias)->B1_I_BIMIX)
    aAdd(_aLinha,If((_cAlias)->C5_I_TRCNF=="S",(_cAlias)->C5_I_FILFT+"-"+U_ROMS002F((_cAlias)->C5_I_FILFT)," ") )
    aAdd(_aLinha,If((_cAlias)->C5_I_TRCNF=="S",(_cAlias)->C5_I_FLFNC+"-"+U_ROMS002F((_cAlias)->C5_I_FLFNC)," ") ) 
    aAdd(_aLinha,(_cAlias)->SITUACAO   ) 
    aAdd(_aLinha,If((_cAlias)->C5_I_OPER=="02",U_ROMS002H((_cAlias)->C6_FILIAL,(_cAlias)->C5_NUM,"CIDADE"),AllTrim(SUBSTR((_cAlias)->A1_MUN,1,15)))   ) 
    aAdd(_aLinha,If((_cAlias)->C5_I_OPER=="02",U_ROMS002H((_cAlias)->C6_FILIAL,(_cAlias)->C5_NUM,"UF"),AllTrim((_cAlias)->A1_EST)))
    aAdd(_aLinha,(_cAlias)->C5_CONDPAG ) 
    aAdd(_aLinha,(_cAlias)->E4_DESCRI  ) 
    aAdd(_aLinha,ROMS002O(_aOpcoes,(_cAlias)->C5_TPFRETE)  )
    aAdd(_aLinha,(_cAlias)->C5_DESCONT ) 
    aAdd(_aLinha,(_cAlias)->C5_VEND4   )
    aAdd(_aLinha,cSupervisor    ) 
    aAdd(_aLinha,(_cAlias)->C5_NOTA )
    aAdd(_aLinha,ROMS002VD((_cAlias)->F2_EMISSAO))  
    aAdd(_aLinha,(_cAlias)->F2_I_NTRAN )
    aAdd(_aLinha,(_cAlias)->F2_I_NTRIA ) 
    aAdd(_aLinha,(_cAlias)->F2_I_STRIA )
    aAdd(_aLinha,ROMS002VD((_cAlias)->F2_I_DTRIA)) 
    aAdd(_aLinha,ROMS002VD((_cAlias)->F2_I_DTRC))  
    aAdd(_aLinha,(_cAlias)->ZA1_DESCRI )
    aAdd(_aLinha,(_cAlias)->ZA3_DESCRI )    
    aAdd(_aLinha,MesExtenso((_cAlias)->C5_EMISSAO) ) 
    aAdd(_aLinha,(_cAlias)->ZZ6_DESCRO )    
    aAdd(_aLinha,(_cAlias)->ZW_TABELA ) 
    aAdd(_aLinha,If(Empty(AllTrim((_cAlias)->C5_NOTA)),ROMS2FMT( (_cAlias)->C5_I_AGEND,(_cAlias)->C5_I_DTENT)," ")) 
    aAdd(_aLinha, If(((_cAlias)->C5_LIBEROK !=" " .Or.!Empty((_cAlias)->C5_NOTA)) ,"ESTOQUE LIBERADO","NAO LIBERADO") )
    aAdd(_aLinha,ROMS002VD((_cAlias)->C9_DATALIB)) 
    aAdd(_aLinha,ROMS002VD((_cAlias)->DAI_DATA)) 
    aAdd(_aLinha,(_cAlias)->DAI_COD    ) 
    aAdd(_aLinha,ROMS002VD((_cAlias)->C5_I_DTPRV))
    aAdd(_aLinha,ROMS002VD(((_cAlias)->C5_I_DTSAG)) )
    aAdd(_aLinha,(_cAlias)->C5_I_ARQOP )
    aAdd(_aLinha,(_cAlias)->C5_I_TAB)
    aAdd(_aLinha,(_cAlias)->DA0_DESCRI)
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_C5_NUM      ,(_cAlias)->R_C5_NUM),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_C5_CLIENT   ,(_cAlias)->R_C5_CLIENT   ),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_C5_LOJAENT  ,(_cAlias)->R_C5_LOJAENT  ),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_A1_NOME     ,(_cAlias)->R_A1_NOME ),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_A1_NREDUZ   ,(_cAlias)->R_A1_NREDUZ  ),"")) 
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_C5_NOTA     ,(_cAlias)->R_C5_NOTA),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_F2_SERIE    ,(_cAlias)->R_F2_SERIE),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,ROMS002VD((_cAlias)->V_F2_EMISSAO),ROMS002VD((_cAlias)->R_F2_EMISSAO)),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_OPER $ "42|05", IIf( (_cAlias)->C5_I_OPER == "42" ,(_cAlias)->V_F2_CHVNFE    ,(_cAlias)->R_F2_CHVNFE),"") )
    aAdd(_aLinha,(_cAlias)->C6_QTDVEN)
    aAdd(_aLinha,(_cAlias)->C6_UNSVEN )  
    aAdd(_aLinha,(_cAlias)->C6_QTDVEN * (_cAlias)->C6_PRCVEN )
    aAdd(_aLinha,(_cAlias)->D2_QTDEDEV)
    aAdd(_aLinha,(_cAlias)->D1_QTSEGUM)
    aAdd(_aLinha,(_cAlias)->D2_VALDEV)
    aAdd(_aLinha,(_cAlias)->C5_ASSNOM)
    aAdd(_aLinha,(_cAlias)->ZZL_NOME )
    aAdd(_aLinha,(_cAlias)->ZEL_DESCRI)
    If SC5->(FIELDPOS("C5_I_DIASV")) > 0 .And. SC5->(FIELDPOS("C5_I_DIASO")) > 0
        aAdd(_aLinha,(_cAlias)->C5_I_DIASV)
        aAdd(_aLinha,(_cAlias)->C5_I_DIASO)
        aAdd(_aLinha,((_cAlias)->C5_I_DIASV+(_cAlias)->C5_I_DIASO))
    Else
        aAdd(_aLinha,U_ROMS2DLT("DIASVIAGEM"))
        aAdd(_aLinha,U_ROMS2DLT("DIASOPERAC"))
        aAdd(_aLinha,U_ROMS2DLT("LEADTIME"  ))
    EndIf
    aAdd(_aLinha,(_cAlias)->B1_I_BIMIX)
    aAdd(_aLinha,(_cAlias)->USR_DTENT)
    aAdd(_aLinha,(_cAlias)->USR_TPAGEN)
    aAdd(_aLinha,U_ROMS002J((_cAlias)->C5_FILIAL, (_cAlias)->C5_NUM)) 
    aAdd(_aLinha,(_cAlias)->C6_I_PDESC)
    aAdd(_aLinha,_cClassEnt)       
    aAdd(_aLinha,(_cAlias)->A1_I_SHLFP)
    aAdd(_aLinha,(_cAlias)->Z21_NOME )
    aAdd(_aLinha,(_cAlias)->Z22_NOME)
    aAdd(_aLinha,(_cAlias)->ZY4_DESCRI)
    aAdd(_aLinha,ROMS002VD(IIf(!Empty(AllTrim((_cAlias)->C5_NOTA)),((_cAlias)->F2_I_PENCL),((_cAlias)->C5_I_DTENT))) )
    aAdd(_aLinha,ROMS002VD(IIf(!Empty(AllTrim((_cAlias)->C5_NOTA)),((_cAlias)->F2_I_DENCL),"")) )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->C5_I_FLFNC   ,(_cAlias)->C5_I_FILFT),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->C5_I_PDPR    ,(_cAlias)->C5_I_PDFT   ),"")) 
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->F_C5_NOTA  ,(_cAlias)->T_C5_NOTA  ),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->F_C5_SERIE ,(_cAlias)->T_C5_SERIE ),"") )
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->F_A1_NOME  ,(_cAlias)->T_A1_NOME  ),""))
    aAdd(_aLinha,IIf( (_cAlias)->C5_I_TRCNF = "S", IIf( (_cAlias)->C5_I_OPER <> "20" ,(_cAlias)->F_A1_NREDUZ,(_cAlias)->T_A1_NREDUZ),""))
    aAdd(_aLinha,(_cAlias)->C6_PRODUTO)
    aAdd(_aLinha,(_cAlias)->C6_I_PRMIN)
    If SC5->(FIELDPOS("C5_I_AGRUP")) > 0 
        aAdd(_aLinha,(_cAlias)->C5_I_AGRUP)
    Else
        aAdd(_aLinha," ")
    EndIf
    aAdd(_aLinha,(_cAlias)->C5_I_QTDA)
    aAdd(_aLinha,If( (_cAlias)->C5_I_PEDOR==(_cAlias)->C5_NUM , Space(Len((_cAlias)->C5_I_PEDOR)) , (_cAlias)->C5_I_PEDOR ))
    aAdd(_aLinha,If( (_cAlias)->C5_I_PEDOR==(_cAlias)->C5_NUM , Space(Len((_cAlias)->C5_I_PODES)) , (_cAlias)->C5_I_PODES ))
    If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
        aAdd(_aLinha,If( (_cAlias)->C5_I_BLSLD="S" , "SIM" , "NÃO" ))
    EndIf
    aAdd(_aLinha,(_cAlias)->C6_I_KIT)
    aAdd(_aLinha,(_cAlias)->C6_I_VLIBB) // Preço da Tabela

    aAdd(_aDados,_aLinha)

    (_cAlias)->(DBSkip())
EndDo

oProc:cCaption := ("Lendo Registro: "+StrZero(nConta,10) +" de "+ _cTot )
ProcessMessages()

(_cAlias)->( DBCloseArea() )

Return _aDados

/*
===============================================================================================================================
Programa----------: ROMS002O
Autor-------------: Igor Melgaço
Data da Criacao---: 27/06/2024
Descrição---------: Retorna o conteudo de campos Combo
Parametros--------: _aOpcoes,_cSel
Retorno-----------: _cDados
===============================================================================================================================
*/
Static Function ROMS002O(_aOpcoes,_cSel)

Local _cDados := ""
Local i := 0

For i := 1 To Len(_aOpcoes)
    If '=' $ _aOpcoes[i] .And. StrTokArr(_aOpcoes[i], '=')[1] == _cSel
        _cDados := StrTokArr(_aOpcoes[i], '=')[2]
        Exit
    EndIf
Next

If Empty(AllTrim(_cDados))
    _cDados := _cSel
EndIf 

Return _cDados

/*
===============================================================================================================================
Programa----------: ROMS002X3
Autor-------------: Igor Melgaço
Data da Criacao---: 27/06/2024
Descrição---------: Retorna as opções do Combo
Parametros--------: _cCampo
Retorno-----------: _aOpcoes
===============================================================================================================================
*/
Static Function ROMS002X3(_cCampo)

Local _aOpcoes := {}
Local _cBox := ""

DBSelectArea("SX3")
DBSetOrder(2)
If DBSeek(_cCampo)
    _cBox := X3Cbox()
    _aOpcoes := StrTokArr(_cBox, ';')
EndIf

Return _aOpcoes

/*
===============================================================================================================================
Programa----------: ROMS002P0
Autor-------------: Igor Melgaço
Data da Criacao---: 05/07/2024
Descrição---------: Valida o Preenchimento dos parametros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function ROMS002P0()

Local _lValid := .F.
Local _cMsg := ""

While !_lValid
    _lValid := ROMS002VP(MV_PAR42,MV_PAR43)
    If !_lValid
        _cMsg := "Para os parametros de periodo de faturamento de e até é necessário o preenchimento dos dois campos!"
        U_ITMsg(_cMsg,"Atenção","",1)
        Pergunte(cPerg,.T.)
    EndIf
EndDo

Return 

/*
===============================================================================================================================
Programa----------: ROMS002VP
Autor-------------: Igor Melgaço
Data da Criacao---: 05/07/2024
Descrição---------: Valida o Preenchimento de Datas
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function ROMS002VP(dDataIni,dDataFim)

Local _lValid := .F.

If !Empty(dDataIni) .Or. !Empty(dDataFim)
    If !Empty(dDataIni) .And. !Empty(dDataFim)
        _lValid := .T.
    Else 
        _lValid := .F.
    EndIf
Else
    _lValid := .T.
EndIf

Return _lValid

/*
===============================================================================================================================
Programa----------: ROMS002VD
Autor-------------: Igor Melgaço
Data da Criacao---: 05/07/2024
Descrição---------: Trata o conteudo dos campos Data
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function ROMS002VD(_cData)

Local _dRet   := ""

If !Empty(AllTrim(_cData)) 
   _dRet := SToD(_cData)
EndIf

Return _dRet

/*
===============================================================================================================================
Programa----------: ROMS002J
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/07/2025
Descrição---------: Retornar a ultima justificativa do log de alterações do pedido de vendas.
Parametros--------: _cCodFil  = Código da Filial
                    _cNumPedV = Numero do Pedido de Vendas
Retorno-----------: _cRet =  Código e descrição do Pedido de Vendas.
===============================================================================================================================
*/
User Function ROMS002J(_cCodFil, _cNumPedV)

Local _cRet := " "
Local _cQry := " "

Begin Sequence 

    _cQry := " SELECT ZY3_FILFT,ZY3_NUMPV,ZY3_JUSCOD, ZY5_DESCR, ZY3.R_E_C_N_O_ RECNOZY3 "
    _cQry += " FROM " + RetSqlName("ZY3") + " ZY3, " + RetSqlName("ZY5") + " ZY5 "
    _cQry += " WHERE ZY3.D_E_L_E_T_ = ' ' AND ZY5.D_E_L_E_T_ = ' ' AND ZY5.ZY5_COD = ZY3_JUSCOD "
    _cQry += " AND ZY3_NUMPV = '" + _cNumPedV + "' AND ZY3_FILFT = '" + _cCodFil + "' " 
    _cQry += " ORDER BY RECNOZY3 DESC"

    If Select("QRYZY3") > 0
        QRYZY3->(DBCloseArea())
    EndIf

    MPSysOpenQuery( _cQry , "QRYZY3")

    DBSelectArea("QRYZY3") 

    If ! QRYZY3->(Eof()) .And. ! QRYZY3->(Bof())
        _cRet := QRYZY3->ZY3_JUSCOD + "-" + QRYZY3->ZY5_DESCR
    EndIf 

    End Sequence 

    If Select("QRYZY3") > 0
    QRYZY3->(DBCloseArea())
    EndIf

Return _cRet 
