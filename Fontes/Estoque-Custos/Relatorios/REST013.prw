#Include "TOTVS.ch"
#Include "TBICONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*
==============================================================================================================================================================
Programa----------: REST013 / REST013M
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: WFW de auditoria de CC entre SA e atendimento de SA - Chamado 28093
Parametros--------: _lLSchedule - execeutado via Schedule ou via tela
                    _lLMensal - Mensal ou Semanal
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
User Function REST013M()// PARA CHAMAR O RELATORIO MEMSAL U_REST013M () NO SCHEDULE

Return U_REST013(.T.,.T.)

User Function REST013(_lLSchedule As Logical,_lLMensal As Logical)//PARA CHAMAR OS RELATORIOS SEMANAIS U_REST013 () NO _lSchedule

Local  _nI  := 0 As Numeric
Local _cAlias:= GetNextAlias() As Character
    	
Private _lSchedule  := .T. As Logical

If ValType(_lLSchedule) = "L"
   _lSchedule:=_lLSchedule
EndIf

Private _lMensal   := .F. As Logical

If ValType(_lLMensal) = "L"
   _lMensal:=_lLMensal
EndIf

Private _cAssunto   :="" As Character
Private _cDatas     :="Sem filtro de datas" As Character
Private _cCentro    :="" As Character
Private _cNomeFilial:="" As Character
Private _cPathSrv   :=__RelDir As Character
Private _cFileName  :="" As Character//O nome é preenchido na funcao U_ROMS004(.T.) - Ex.: \SPOOL\REST013_20130214_165826.pdf
Private _aDadosTotal:={} As Array
Private _aAnaliTotal:={} As Array
Private _aEmail_CC  :={} As Array
Private _aEmailCC   :={} As Array
Private _aEmailGG   :={} As Array
Private _cEmail     :="" As Character
Private _cEnvPara   :="" As Character
Private _cCentrosC  :="" As Character//"0113001;0103001"//Testes 
Private _cFilial    :="" As Character//Filial Gerente
Private _aResultado :={} As Array
Private _cTitJanela :="" As Character
Private _cFilsGerent:="" As Character
Private _cAmbiente  :=GETENVSERVER() As Character

If _lSchedule .And. SELECT("SX3") = 0
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "REST013"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "REST01301"/*cMsgId*/, "REST01301 - Iniciando..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   RpcSetType(3)
   PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "EST" TABLES "ZZL","SD3","SD1","SCP","SB1","SA2"
Else
   
   _lSchedule:=.F.

   MV_PAR01:=(dDataBase)//-7
	MV_PAR02:=1
   _aOpc:={"1-MENSAL","2-SEMANAL"}
   _cTitulo:="Filtro dos dados de Centros de Custos"
        
	_aParAux:={}
   AAdd( _aParAux , { 1 , "Data"             , MV_PAR01, "@D"  , "" ,"", ".T." , 070 , .T. } )
   AAdd( _aParAux , { 3 , "Tipo de Relatório", MV_PAR02,_aOpc  , 60 , '' , .T. } )

   _aParRet:={}
   For _nI := 1 To Len( _aParAux )
       AAdd( _aParRet , _aParAux[_nI][03] )
   Next 

   If !ParamBox( _aParAux , _cTitulo, _aParRet , {|| .T. } , , , , , , , .T. , .T. )
       Return .T.
   EndIf

   If ValType(MV_PAR02) = "C"
      MV_PAR02:=Val(MV_PAR02)
   EndIf
   _lMensal:=(MV_PAR02=1)

EndIf
BeginSql alias _cAlias
   SELECT R_E_C_N_O_ REG_ZZL FROM %Table:ZZL%
   WHERE D_E_L_E_T_ = ' '
   AND ZZL_FILIAL = %xFilial:ZZL%
   AND ZZL_CC <>  ' ' AND ZZL_EMAIL <> ' '
   ORDER BY ZZL_NOME
EndSql

While (_cAlias)->(!Eof())
	ZZL->(DBGoTo((_cAlias)->REG_ZZL))
   If !_lSchedule 
      _cFilial:=cFilAnt//Inicia com cFilAnt para não dar SKIP quando não entra em Nenhum If abaixo
      If Left(AllTrim(ZZL->ZZL_CC),1) = "C" .And. !_lMensal //NO SEMANAL EU FILTRO SÓ OS COORDENADORES E PEGO TODOS OS GERENTES
         _cFilial:=SubStr(AllTrim(ZZL->ZZL_CC),3,2)//Filial do Coordenador
      ElseIf Left(AllTrim(ZZL->ZZL_CC),1) = "G" .And. _lMensal//NO MENSAL EU FILTRO SÓ OS GERENTES E PEGO TODOS OS COORDENADORES
         _cFilial:=AllTrim(SubStr(AllTrim(ZZL->ZZL_CC),3))//Filial do Gerente
      EndIf
      If !cFilAnt $ _cFilial 
	      (_cAlias)->(DBSkip())
         Loop
      EndIf
   EndIf
   If _lSchedule .Or. _lMensal .Or. Left(AllTrim(ZZL->ZZL_CC),1) <> "G" //Coodernadores 
	   AAdd(_aEmail_CC,{AllTrim(ZZL->ZZL_EMAIL),AllTrim(ZZL->ZZL_CC),AllTrim(ZZL->ZZL_NOME),.T.} )
      AAdd(_aEmailCC ,{.T.,AllTrim(ZZL->ZZL_NOME),AllTrim(ZZL->ZZL_CC),AllTrim(ZZL->ZZL_EMAIL)} )//LISTBOX
   EndIf
   If (!_lSchedule  .And. _lMensal .And. Left(AllTrim(ZZL->ZZL_CC),1) = "G") //GERENTES
	   AAdd(_aEmailGG ,{.T.,AllTrim(ZZL->ZZL_NOME),AllTrim(ZZL->ZZL_CC),AllTrim(ZZL->ZZL_EMAIL)} )//LISTBOX
   EndIf
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If !_lSchedule 
   If  _lMensal
      _aEmailCC:=_aEmailGG
   EndIf
   If Len(_aEmailCC )= 0
      FWAlertInfo("Não tem "+If(_lMensal,"Gerente","Coordenadores")+" no cadastrado de usuarios para a Filial Atual "+cFilAnt,"REST01301")
      Return .F.
	ElseIf U_ITListBox( 'Usuarios / e-mails cadastrados:' , {" ",'NOME' , 'CENTROS DE CUSTO' , 'E-MAIL' } , _aEmailCC , .T. , 2 , 'Selecione os Usuarios: ' )
      lMarcou:=.F.
      If _lMensal//GERENTES
	   	For _nI := 1 To Len( _aEmailCC )
            If (_nPos:=aScan(_aEmail_CC,{|G|G[1]+G[2]+G[3] == _aEmailCC[_nI,4]+_aEmailCC[_nI,3]+_aEmailCC[_nI,2] })) > 0
	   		   _aEmail_CC[_nPos,4]:=_aEmailCC[_nI,1]
               If _aEmailCC[_nI,1]
                  _cFilsGerent+=AllTrim(SubStr(_aEmailCC[_nI,3],3))+";"//Só aqui preenche GERENTES VIA TELA
                  lMarcou:=.T.
               EndIf
            EndIf
	   	Next
      Else//COORDENADORES
	   	For _nI := 1 To Len( _aEmailCC )
            If (_nPos:=aScan(_aEmail_CC,{|G|G[1]+G[2]+G[3] == _aEmailCC[_nI,4]+_aEmailCC[_nI,3]+_aEmailCC[_nI,2] })) > 0
	   		   _aEmail_CC[_nPos,4]:=_aEmailCC[_nI,1]
               If _aEmailCC[_nI,1]
                  lMarcou:=.T.
               EndIf
            EndIf
	   	Next _nI
      EndIf
      If !lMarcou
         FWAlertInfo("Não tem "+If(_lMensal,"Gerente","Coordenador")+" marcado. Marque pelo menos um.","REST01302")
         Return .F.
      EndIf
   Else
      Return .F.
	EndIf
EndIf

If _lSchedule 
   _dData:=Date()
Else
   _dData:=MV_PAR01//dDataBase
EndIf   

If _lMensal//***************************************  MEMSAL  ***************************************
	If MONTH( _dData ) > 1//DE FEV A DEZ
		MV_PAR01 := SToD(AllTrim(Str(YEAR( _dData ))) + StrZero(( MONTH(_dData)-1),2)+"01")    //INICIO DO MES ANTERIOR
		MV_PAR02 := SToD(AllTrim(Str(YEAR( _dData ))) + StrZero(( MONTH(_dData)  ),2)+"01") - 1//FINAL SO MES ANTERIOR
	Else//SE JANEIRO
		MV_PAR01 := SToD(AllTrim(Str( YEAR(_dData)-1 )) + "1201")//INICIO DO MES ANTERIOR
		MV_PAR02 := SToD(AllTrim(Str( YEAR(_dData)-1 )) + "1231")//FINAL SO MES ANTERIOR
	EndIf
    If _lSchedule 
       REST013Datas()//ENVIA MENSAL DO MES ANTERIOR
    Else   
       FWMsgRun(,{|oProc| REST013Datas(oProc) },'Datas de '+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02) ,'Lendo dados Mensais...')//ENVIA MENSAL DO MES ANTERIOR
    EndIf   
Else//***************************************  SEMANAL  ***************************************
   MV_PAR01:=(_dData-7)
   MV_PAR02:=(_dData-1)
   If Day(MV_PAR02) < 7 //Se antes do setimo dia do mes atual 

      MV_PAR02:=SToD(AllTrim(Str(YEAR( _dData ))) + StrZero(( MONTH(_dData) ),2)+"01")-1//DE MV_PAR01 ATE O ULTIMO DIA DO MES ANTERIOR
      If _lSchedule 
         REST013Datas()//CHAMA ANTES AQUI PARA QUEBRA DOS MESES - ENVIA PARTE FINAL DO MES ANTERIOR 
      Else
         FWMsgRun(,{|oProc| REST013Datas(oProc) },'Datas de '+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02) ,'Lendo dados Semanais...')
      EndIf   

      MV_PAR01:=SToD(AllTrim(Str(YEAR( _dData ))) + StrZero(( MONTH(_dData) ),2)+"01")
      MV_PAR02:=(_dData-1)////ENVIA PARTE INICIAL DO MES ATUAL - DO DIA PRIMEIRO ATE MV_PAR02

   EndIf 
   If _lSchedule 
      REST013Datas()//ENVIA PARTE INICIAL DO MES ATUAL SE DAY(MV_PAR02) < 7 SENÃO OS ULTIMOS 7 DIAS 
   Else
      FWMsgRun(,{|oProc| REST013Datas(oProc) },'Datas de '+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02) ,'Lendo dados Semanais...')
   EndIf   
EndIf

If _lSchedule
   RESET ENVIRONMENT
ElseIf Len(_aResultado) > 0
   U_ITListBox( 'Resultado dos envios' , { "Filial",'Processamento' , 'Registros' ,"E-MAIL ", "Centros de custo","Observações" } , _aResultado , .T. , 1 , )
ElseIf !_lSchedule
   FWAlertInfo("Nao tem dados para o Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02),"REST01303")
EndIf

Return .T.

/*
==============================================================================================================================================================
Programa----------: REST013Datas()
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: WFW de auditoria de CC entre SA e atendimento de SA
Parametros--------: oProc
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
Static Function REST013Datas(oProc As Object) As Logical

Local _nX      := 0 As Numeric
Local lRet     :=.T. As Logical
Private lHtml  := (GetRemoteType() == 5) As Logical//Valida se o ambiente é SmartClientHtml

cMensagem:=""
_aControle:={}//SÓ zerar aqui essa array

For _nX := 1 To Len(_aEmail_CC)//LER COORDENADORES

    If !_aEmail_CC[_nX,4] .Or. Left(_aEmail_CC[_nX,2],1) <> "C" //Coodernadores
       Loop
    EndIf
    _cEmail    :=Lower(_aEmail_CC[_nX,1])
    _cCentrosC :=SubStr(_aEmail_CC[_nX,2],3)//Centros de Csuto
    _cFilial   :=SubStr(_aEmail_CC[_nX,2],3,2)//Filial principal do Titulo
    _cEnvPara  :=_aEmail_CC[_nX,3]
    
    If ValType(oProc) = "O"
       oProc:cCaption := _cTitJanela := ("REST11-Coord.: "+_cFilial+" / "+_aEmail_CC[_nX,3])
       ProcessMessages()
    EndIf

    _aCabExcel:={}
    _aGerExcel:={}
    //1 - Relatório para responsáveis por Centro de custo com as baixas de almoxarifado e serviços contratados para o seu CC;
    If REST013Rel("REST011") .And. !_lMensal//Enviar detalhado os produtos baixados no CC (usar como referencia o relatório REST011)
       lRet:=REST013Email( {|| REST013Rel("REST011") } )
    EndIf   

    If ValType(oProc) = "O"
       oProc:cCaption := _cTitJanela := ("RCOM09-Coord.: "+_cFilial+" / "+_aEmail_CC[_nX,3])
       ProcessMessages()
    EndIf
    _cEmail:=LOWER(_aEmail_CC[_nX,1])//Recarrega pq é alterado quando por tela

    _aCabExcel:={}
    _aGerExcel:={}
    If REST013Rel("RCOM009").AND. !_lMensal//Enviar separado das informações acima os dados dos serviços contratados, filtrando o cfop 1933/2933 (referencia relatório RCOM009)
       lRet:=REST013Email( {|| REST013Rel("RCOM009") } )
    EndIf

    If !lRet .And. !_lMensal
       Exit
    EndIf
Next _nX

lRet:=.F.
For _nX := 1 TO Len(_aEmail_CC)//LER GERENTES

    If !_aEmail_CC[_nX,4] .Or. Left(_aEmail_CC[_nX,2],1) <> "G" //Gerentes
       Loop
    EndIf
    
    _cEmail  :=Lower(_aEmail_CC[_nX,1])
    _cFilial :=AllTrim(SubStr(_aEmail_CC[_nX,2],3))//Filial do Titulo e do Gerente Pode ser varias
    _cEnvPara:=_aEmail_CC[_nX,3]
    
    If !_lSchedule .And. _lMensal .And. !cFilAnt $ _cFilial 
       Loop
    EndIf

    If ValType(oProc) = "O"
       oProc:cCaption := _cTitJanela := ("Gerente: "+_cFilial+" / "+_cEnvPara)
       ProcessMessages()
    EndIf

    _aCabExcel:={}
    _aGerExcel:={}
    //2 - Relatório para o gerente geral da fábrica com os totais dos CC enviados acima
    If REST013Rel("TOTAL")
       lRet:=REST013Email( {|| REST013Rel("TOTAL") } )//Sempre retorna .T. para saber que pelos menos enviou 1
    EndIf   
    If !lRet
       Exit
    EndIf
Next _nX

If !_lSchedule .And. _lMensal .And. !lRet
   AAdd(_aResultado,{cFilAnt,"MENSAL",TRANSF(0,"@E 999,999"),"Filial sem Gerente ou Coordenador no cadastrado usuarios.","","Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)})
EndIf

If _lSchedule 
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "REST013"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "REST01302"/*cMsgId*/, "REST01302 - "+cMensagem/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

Return lRet

/*
==============================================================================================================================================================
Programa----------: REST013Rel
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: WFW de auditoria de CC entre SA e atendimento de SA
Parametros--------: _nTipo: tipo do relatorio
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
Static Function REST013Rel(cTipo As Character) As Logical

Local _nX := 0 As Numeric 

Private _cAlias   := GetNextAlias()
Private _cTipo    := cTipo
Private _nPagAux  := 0 //Conta Pagina
Private aDados    := {}//1                2                3        4         5 (Aplicao Direta)          6                   7               8    9
Private aTit1     := {"Nr.S.A."    ,"Produto"        ,"Descricao","Data"     ,"AD"               ,"         Entregue","    Custo Total" ,"Usr SA","OBS"}//9 cols
Private aTit1Excel:= {"Nr.S.A."    ,"Produto"        ,"Descricao","Data"     ,"AD"               ,"         Entregue","    Custo Total" ,"Usr SA","OBS","Filial + CC","Descricao CC"}//11 cols
Private aTit2     := {"Fornecedor" ,"     Quantidade","Documento","Dt. Dig." ," Valor Unitario"  ,"     Valor Total" ,"Descricao"       }//7 cols
Private aTit2Excel:= {"Fornecedor" ,"     Quantidade","Documento","Dt. Dig." ," Valor Unitario"  ,"     Valor Total" ,"Descricao"       ,"Filial + CC","Descricao CC"}//9 cols
Private aTit3     := {"Fil Cod. CC"  ,"Descricao CC"   ,"Custo Total"}//3 cols
Private _nTotal   := 0
Private _nPosTotal:= 0//Posicao da coluna de total
Private _nPosQbra := 0//Posicao da coluna de QUEBRA
Private _cPicTotal:= "@E 999,999,999.99"
Private _lRetrato := .F.
Private _c7CCSintet:= ""
Private _c6CCSintet:= ""
Private _c5CCSintet:= ""

If !totvs.framework.environment.Type.get() == '1' .And. _lMensal //1-Produção, 2-Homologação,3-Desenvolvimento
   aTit3Excel:= {"Filail","CC","Descricao CC"   ,"Custo Total","SELECT","Somou"}//6 cols
Else
   aTit3Excel:= {"Filail","CC","Descricao CC"   ,"Custo Total"}//4 cols
EndIf

If _cTipo = "REST011"
   _aCabExcel:={}
   For _nX := 1 To Len(aTit1Excel)
    	// Alinhamento: 1-Left   ,2-Center,3-Right
    	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
    	//            Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    	If _nX = 6
      	AAdd(_aCabExcel,{aTit1Excel[_nX]  ,3           ,2         ,.F.})//Entregue
    	ElseIf _nX = 7
      	AAdd(_aCabExcel,{aTit1Excel[_nX]  ,3           ,3         ,.F.})//Custo Total
    	ElseIf _nX = 4 
      	AAdd(_aCabExcel,{aTit1Excel[_nX]  ,2           ,4         ,.F.})//DATA
      Else
    	   AAdd(_aCabExcel,{aTit1Excel[_nX]  ,1           ,1         ,.F.})//CARACTER
    	EndIf
   Next _nX

   MV_PAR07:=""
   _aCC:=StrTokArr(_cCentrosC,";")
   For _nX := 1 TO Len(_aCC)
       If !Empty(_aCC[_nX])
          If Len(_aCC[_nX]) > 7
             MV_PAR07+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC
          ElseIf Len(_aCC[_nX]) = 7
             _c7CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          ElseIf Len(_aCC[_nX]) = 6
             _c6CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          ElseIf Len(_aCC[_nX]) = 5
             _c5CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          EndIf   
       EndIf   
   Next _nX

   _cCentro   :=MV_PAR07+_c7CCSintet+_c6CCSintet+_c5CCSintet
   _cCentro   :=Left(_cCentro,Len(_cCentro)-1)
   _c5CCSintet:=Left(_c5CCSintet,Len(_c5CCSintet)-1)
   _c6CCSintet:=Left(_c6CCSintet,Len(_c6CCSintet)-1)
   _c7CCSintet:=Left(_c7CCSintet,Len(_c7CCSintet)-1)
   MV_PAR07   :=Left(MV_PAR07,Len(MV_PAR07)-1)

ElseIf _cTipo = "RCOM009"
   _aCabExcel:={}
   For _nX := 1 to Len(aTit2Excel)
    	// Alinhamento: 1-Left   ,2-Center,3-Right
    	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
    	//            Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    	If _nX = 2
      	AAdd(_aCabExcel,{aTit2Excel[_nX]  ,3           ,2         ,.F.})//Quantidade
    	ElseIf _nX = 5 .And. _nX = 6
      	AAdd(_aCabExcel,{aTit2Excel[_nX]  ,3           ,3         ,.F.})//Custo Total
    	ElseIf _nX = 4 
      	AAdd(_aCabExcel,{aTit2Excel[_nX]  ,2           ,4         ,.F.})//DATA
      Else
    	   AAdd(_aCabExcel,{aTit2Excel[_nX]  ,1           ,1         ,.F.})//CARACTER
    	EndIf
   Next _nX

   MV_PAR03:="1000"
   MV_PAR04:="1000"
   MV_PAR07:=MV_PAR01
   MV_PAR08:=MV_PAR02
   MV_PAR17:="1933;2933"
   MV_PAR18:=""
   _aCC:=StrTokArr(_cCentrosC,";")
   For _nX := 1 TO Len(_aCC)
       If !Empty(_aCC[_nX])
          If Len(_aCC[_nX]) > 7
             MV_PAR18+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC
          ElseIf Len(_aCC[_nX]) = 7
             _c7CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          ElseIf Len(_aCC[_nX]) = 6
             _c6CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          ElseIf Len(_aCC[_nX]) = 5
             _c5CCSintet+=_aCC[_nX]+";"//LISTA DE FILIA+CC DO ZZL->ZZL_CC - SINTETICO
          EndIf
       EndIf
   Next _nX
   _cCentro   :=MV_PAR18+_c7CCSintet+_c6CCSintet+_c5CCSintet
   _cCentro   :=Left(_cCentro,Len(_cCentro)-1)
   _c5CCSintet:=Left(_c5CCSintet,Len(_c5CCSintet)-1)
   _c6CCSintet:=Left(_c6CCSintet,Len(_c6CCSintet)-1)
   _c7CCSintet:=Left(_c7CCSintet,Len(_c7CCSintet)-1)
   MV_PAR18   :=Left(MV_PAR18,Len(MV_PAR18)-1)

ElseIf _cTipo = "TOTAL"

   _aCabExcel:={}
   For _nX := 1 to Len(aTit3Excel)
    	// Alinhamento: 1-Left   ,2-Center,3-Right
    	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
    	//            Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    	If _nX = 4 .Or. _nX = 6
      	AAdd(_aCabExcel,{aTit3Excel[_nX]  ,3           ,3         ,.F.})//MONETARIO
      Else
    	   AAdd(_aCabExcel,{aTit3Excel[_nX]  ,1           ,1         ,.F.})//CARACTER
    	EndIf
   Next _nX
  aDados:={}
  _cCentro:=""
  _aGerExcel:={}
  _aDadosTotal:=aSort(_aDadosTotal,,,{|x,y| x[4] > y[4] })
  For _nX := 1 TO Len(_aDadosTotal)
      If Left(_aDadosTotal[_nX,1],2) $ _cFilial
         AAdd(aDados    , {Left(_aDadosTotal[_nX,1],2)+" "+SubStr(_aDadosTotal[_nX,1],3),_aDadosTotal[_nX,2],_aDadosTotal[_nX,3]} )
         AAdd(_aGerExcel, {Left(_aDadosTotal[_nX,1],2),SubStr(_aDadosTotal[_nX,1],3),_aDadosTotal[_nX,2],_aDadosTotal[_nX,4]} )
         _cCentro+=_aDadosTotal[_nX,1]+";"//SubStr(_aDadosTotal[T,1],3)+" / "
         _nTotal+=_aDadosTotal[_nX,4]
      EndIf
  Next _nX
  _cCentro  :=Left(_cCentro,Len(_cCentro)-1)
  _lRetrato :=.T.
  _nPosTotal:=3//Posicao da coluna de total
  nTotal    :=Len(aDados)
  cMensagem +=_cTipo+": "+AllTrim(Str(nTotal))+" Registros lidos - Email Para "+_cEmail+" - CC: "+_cCentro+CHR(13)+CHR(10)
  AAdd(_aResultado,{_cFilial,"MENSAL",TRANSF(nTotal,"@E 999,999"),_cEmail,_cCentro,"Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)})
  _cCentro  +=";CCQtde: "+AllTrim(Str(nTotal))

  If nTotal = 0
     Return .F.
  EndIf

EndIf

//SÓ ENTRA AQUI QUANDO _cTipo = "REST011" OU _cTipo = "RCOM009"
If _lSchedule .And. Len(aDados) = 0//Preenche aDados acima no _cTipo = "TOTAL"
//SEM TELA 
   REST013Select()

   If Select(_cAlias) = 0
      Return .F.
   EndIf
   (_cAlias)->( DBGoTop() )
   nTotal:=0
   COUNT TO nTotal

   cMensagem+=_cTipo+": "+AllTrim(Str(nTotal))+" Registros lidos - Email para "+_cEmail+CHR(13)+CHR(10)

   If nTotal = 0
      (_cAlias)->(DBCloseArea())
      Return .F.
   EndIf

   REST013Ler()
   If _lMensal
      aDados:={}//Zera pq já preenchei o _aDadosTotal e não precisa gerar os relatorios "REST011" e "RCOM009" no mensal
   EndIf   

//SÓ ENTRA AQUI QUANDO _cTipo = "REST011" OU _cTipo = "RCOM009"
ElseIf Len(aDados) = 0//Preenche aDados acima quando no _cTipo = "TOTAL"
//COM TELA 

//   LjMsgRun( "SELECT: Lendo Dados: "+_cTipo , _cTitJanela , {|| REST013Select() } )
   REST013Select() 

   If Select(_cAlias) = 0
      Return .F.
   EndIf
   (_cAlias)->( DBGoTop() )
   nTotal:=0
   COUNT TO nTotal

   If nTotal = 0
      (_cAlias)->(DBCloseArea())
      Return .F.
   EndIf

// AAdd(_aResultado,{_cFilial,"SEMANAL ["+_cTipo+"]",TRANSF(nTotal,"@E 999,999"),_cEmail,_cCentrosC,"Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)})
   AAdd(_aResultado,{_cFilial,"SEMANAL ["+_cTipo+"]",       nTotal              ,_cEmail,_cCentrosC,"Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)})
   
   FWMsgRun( ,{|oProc|  REST013Ler(oProc) } , "Aguarde!" , "Acumulando Dados: "+_cTipo+TRANSF(nTotal,"@E 999,999")  )

   If _lMensal
      aDados:={}//Zera pq já preenchei o _aDadosTotal e não precisa gerar os relatorios "REST011" e "RCOM009" no mensal
   EndIf   

EndIf

If Len(aDados) > 0

    _cFileName:=Upper(REST013NameFile())
    If _lSchedule 
       //FWMsPrinter(): New (< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
	   _oPrint := FWMsPrinter():New(_cFileName, IMP_PDF   , .T.               , _cPathSrv       , .T.             ,            ,                ,            , .T. )
    Else
       //FWMsPrinter(): New (< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
	   _oPrint := FWMsPrinter():New(_cFileName, IMP_PDF   , .T.               , _cPathSrv       , .T.             ,            ,                ,)
	   If Upper(_oPrint:cPathPDF) == "C:\" .Or. Empty(_oPrint:cPathPDF)
          _oPrint:cPathPDF := Lower(_cPathSrv)
	   EndIf
    EndIf

    // Configura modo Paisagem de Impressao
    _oPrint:SetResolution(78)
    If _lRetrato
       _oPrint:SetPortrait()
    Else   
       _oPrint:SetLandscape()
    EndIf   


    // Define impressao em papel A4
    _oPrint:SetPaperSize(DMPAPER_A4)
    _oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior


    // Se enviar por e-mail nao abre o arquivo apos a impressao
    If _lSchedule //Aqui é sempre Exporta PDF via e-mail

//**** Configuracoes para via WF de Carga **********************************************************************************
       _oPrint:SetViewPDF(.F.)
       _oPrint:cPathPDF := Lower(_cPathSrv)	// Caso seja utilizada impressão em IMP_PDF
//**** Configuracoes para via WF  **********************************************************************************

	   // Chama a impressão
       REST013CMP( @_oPrint ) 

       _oPrint:lViewPDF := .F.
       _oPrint:Preview()
       Sleep(2000)//dá um tempinho para criar o arquivo
       FreeObj(_oPrint)
       _cFileName:=_cPathSrv+_cFileName      
       _adatfile := directory(_cFilename)
       If file(_cFilename)
	      _adatfile := directory(_cFilename)
	      _ntamanho := _adatfile[1][2]
	   Else
	      _ntamanho := 0
	   EndIf
       
    Else
	   // Chama a impressão
       LjMsgRun( "Criando Layout: "+_cTipo , _cTitJanela , {|| REST013CMP( @_oPrint ) } )
      _cPathSrv:=_oPrint:cPathPDF
      _oPrint:lViewPDF := .F.
       
       LjMsgRun( "Gerando PDF: "+_cPathSrv+_cFilename , _cTitJanela , {|| _oPrint:Preview() } )//Visualiza antes de imprimir

       FreeObj(_oPrint)
       _cFileName:=_cPathSrv+_cFileName      
       _adatfile := directory(_cFilename)
       If file(_cFilename)
	      _adatfile := directory(_cFilename)
	      _ntamanho := _adatfile[1][2]
	   Else
	      _ntamanho := 0
	   EndIf
    EndIf

ElseIf !_lMensal
    If !_lSchedule 
       AAdd(_aResultado,{_cFilial,"SEMANAL ["+_cTipo+"]",TRANSF(0,"@E 999,999"),_cEmail,_cCentrosC,"Periodo de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)})
    EndIf
    
    Return .F.
EndIf

Return .T.

/*
==============================================================================================================================================================
Programa----------: REST013Ler()
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: Ler SELECTs e grava e arrays
Parametros--------: Nenhum
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
Static Function REST013Ler(oProc As Object) As Logical

Local _nConta  := 0 As Numeric 
Local nTam     := 82 As Numeric
Local nTamB1   := 80 As Numeric

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
   _nConta++
   If ValType(oProc) = "O"
       oProc:cCaption := ("Lendo: "+ StrZero(_nConta,6) + " de " + StrZero(nTotal,6))
       ProcessMessages()
   EndIf
   
   If _cTipo = "REST011"
      cObs1:=Left(   (_cAlias)->D3_I_OBS ,nTam)
      cObs2:=SubStr( (_cAlias)->D3_I_OBS ,nTam+1,nTam )
      cObs3:=SubStr( (_cAlias)->D3_I_OBS ,nTam+nTam+1 )
		
		aItem:={}//{"Nr.S.A."   ,"Produto"        ,"Descricao","Data"     ,"AD"(Aplicao Direta)  ,"         Entregue","    Custo Total" ,"Usr SA","OBS"}
   	AAdd(aItem,(_cAlias)->D3_NUMSA)                                            //01
		AAdd(aItem,(_cAlias)->CP_PRODUTO)                                          //02
		AAdd(aItem,Left((_cAlias)->CP_DESCRI,32))                                  //03
		AAdd(aItem,DToC(SToD((_cAlias)->D3_EMISSAO)))                              //04
		_nPosData:=Len(aItem)
		AAdd(aItem,If((_cAlias)->D3_I_ORIGE="MATA103"," S"," N"))                  //05
		AAdd(aItem,TRANSF((_cAlias)->D3_QUANT, _cPicTotal))                        //06
		_nPosQtde:=Len(aItem)
		AAdd(aItem,TRANSF((_cAlias)->D3_CUSTO1,_cPicTotal))                        //07
		_nPosTotal:=Len(aItem)//Posicao da coluna de total    
		AAdd(aItem,(_cAlias)->CP_SOLICIT)                                          //08
		AAdd(aItem,cObs1)                                                          //09
      _nPosOBS:=Len(aItem)  //Posicao da coluna Descricao
		AAdd(aItem,(_cAlias)->D3_FILIAL+(_cAlias)->D3_CC)                          //10
		_nPosQbra :=Len(aItem)//Posicao da Quebra DE FIL + CC
		AAdd(aItem,Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D3_CC,"CTT_DESC01"))//11
		AAdd(aItem,(_cAlias)->D3_CUSTO1)                                           //12

		_nTotal+=(_cAlias)->D3_CUSTO1

		AAdd(aDados,aItem)
      aItemE:=ACLONE(aItem)
      ASize(aItemE,(_nPosQbra+1)) //POE PARA O Tamanho do Cabeçalho  do Excel
		AAdd(_aGerExcel,aItemE)
      _aGerExcel[Len(_aGerExcel),_nPosData ]:=SToD((_cAlias)->D3_EMISSAO)
      _aGerExcel[Len(_aGerExcel),_nPosQtde ]:=(_cAlias)->D3_QUANT
      _aGerExcel[Len(_aGerExcel),_nPosTotal]:=(_cAlias)->D3_CUSTO1
      _aGerExcel[Len(_aGerExcel),_nPosOBS  ]:=(_cAlias)->D3_I_OBS
      _aGerExcel[Len(_aGerExcel),_nPosQbra ]:=(_cAlias)->D3_FILIAL+" "+(_cAlias)->D3_CC
    
		If !Empty(cObs2)
		   aItem:={}//{"Nr.S.A.","Produto Descricao","Data","AD","Entregue Bx","Custo Total","Usr SA","OBS"}
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
		   AAdd(aItem,cObs2)
		   AAdd(aItem,(_cAlias)->D3_FILIAL+(_cAlias)->D3_CC)                          //10
		   AAdd(aItem,Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D3_CC,"CTT_DESC01"))//11
   		AAdd(aItem,0)
		   AAdd(aDados,aItem)
		EndIf
		If !Empty(cObs3)
		   aItem:={}//{"Nr.S.A.","Produto Descricao","Data","AD","Entregue Bx","Custo Total","Usr SA","OBS"}
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
   		AAdd(aItem,"")
		   AAdd(aItem,cObs3)
		   AAdd(aItem,(_cAlias)->D3_FILIAL+(_cAlias)->D3_CC)                          //10
		   AAdd(aItem,Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D3_CC,"CTT_DESC01"))//11
   		AAdd(aItem,0)
		   AAdd(aDados,aItem)
		EndIf
		
	   AAdd(_aAnaliTotal , { (_cAlias)->D3_FILIAL , (_cAlias)->D3_CC , _cEmail , (_cAlias)->D3_CUSTO1 , "REST011", 0 } )

		If (nPos:=aScan(_aDadosTotal,{ |T| T[1] == (_cAlias)->D3_FILIAL+(_cAlias)->D3_CC } ) ) = 0 
		   AAdd( _aDadosTotal , {(_cAlias)->D3_FILIAL+(_cAlias)->D3_CC , Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D3_CC,"CTT_DESC01") , TRANSF((_cAlias)->D3_CUSTO1,_cPicTotal) , (_cAlias)->D3_CUSTO1} )
         AAdd(  _aControle  , (_cAlias)->D3_FILIAL+(_cAlias)->D3_CC+_cEmail )
         _aAnaliTotal[Len(_aAnaliTotal),6]:=(_cAlias)->D3_CUSTO1
		ElseIf aScan(_aControle ,(_cAlias)->D3_FILIAL+(_cAlias)->D3_CC+_cEmail) <> 0
         _aDadosTotal[nPos,4]+=(_cAlias)->D3_CUSTO1
         _aDadosTotal[nPos,3]:=TRANSF(_aDadosTotal[nPos,4],_cPicTotal)
         _aAnaliTotal[Len(_aAnaliTotal),6]:=(_cAlias)->D3_CUSTO1
		EndIf    
		
	ElseIf _cTipo = "RCOM009"
      cObs1:=Left(   (_cAlias)->B1_DESC ,nTamB1)
      cObs2:=SubStr( (_cAlias)->B1_DESC ,nTamB1+1 )

		aItem:={}//{"Fornecedor","Quantidade","Documento","Dt.Dig.","Vlr. Unit.","Valor","Descricao"}
		AAdd(aItem,(_cAlias)->RAZAO)                                                 //01
		AAdd(aItem,TRANSF((_cAlias)->D1_QUANT,_cPicTotal))                           //02
		_nPosQtde:=Len(aItem)
		AAdd(aItem,(_cAlias)->D1_DOC)                                                //03
		AAdd(aItem,DToC(SToD((_cAlias)->D1_DTDIGIT)))                                //04
		_nPosData:=Len(aItem)
		AAdd(aItem,TRANSF((_cAlias)->D1_VUNIT,_cPicTotal))                           //05
		_nPosUNIT:=Len(aItem)
		AAdd(aItem,TRANSF((_cAlias)->D1_TOTAL,_cPicTotal))                           //06
		_nPosTotal:=Len(aItem)//Posicao da coluna de total
		AAdd(aItem,cObs1)                                                            //07
      _nPosOBS:=Len(aItem)  //Posicao da coluna Descricao
		AAdd(aItem,(_cAlias)->D1_FILIAL+(_cAlias)->D1_CC)                            //08
		_nPosQbra :=Len(aItem)//Posicao da Quebra DE FIL + CC
		AAdd(aItem,Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D1_CC,"CTT_DESC01"))  //09
		AAdd(aItem,(_cAlias)->D1_TOTAL)							                          //10

		_nTotal+=(_cAlias)->D1_TOTAL
		
		AAdd(aDados,aItem)
      aItemE:=ACLONE(aItem)
      ASize(aItemE,(_nPosQbra+1)) //POE PARA O Tamanho do Cabeçalho do Excel
		AAdd(_aGerExcel,aItemE)
      _aGerExcel[Len(_aGerExcel),_nPosQtde ]:=(_cAlias)->D1_QUANT
      _aGerExcel[Len(_aGerExcel),_nPosData ]:=SToD((_cAlias)->D1_DTDIGIT)
      _aGerExcel[Len(_aGerExcel),_nPosUNIT ]:=(_cAlias)->D1_VUNIT
      _aGerExcel[Len(_aGerExcel),_nPosTotal]:=(_cAlias)->D1_TOTAL
      _aGerExcel[Len(_aGerExcel),_nPosOBS  ]:=(_cAlias)->B1_DESC
      _aGerExcel[Len(_aGerExcel),_nPosQbra ]:=(_cAlias)->D1_FILIAL+" "+(_cAlias)->D1_CC

		If !Empty(cObs2)
         aItem:={}//{"Fornecedor","Quantidade","Documento","Dt.Dig.","Vlr. Unit.","Valor","Descricao"}
         AAdd(aItem,"")
         AAdd(aItem,"")
         AAdd(aItem,"")
         AAdd(aItem,"")
         AAdd(aItem,"")
         AAdd(aItem,"")
         AAdd(aItem,cObs2)
         AAdd(aItem,(_cAlias)->D1_FILIAL+(_cAlias)->D1_CC)                            //08
         AAdd(aItem,Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D1_CC,"CTT_DESC01"))  //09
         AAdd(aItem,0) 							                                            //10
         AAdd(aDados,aItem)
		EndIf

	   AAdd(_aAnaliTotal , { (_cAlias)->D1_FILIAL , (_cAlias)->D1_CC, _cEmail  , (_cAlias)->D1_TOTAL , "RCOM009" , 0} )

		If (nPos:=aScan(_aDadosTotal,{ |T| T[1] == (_cAlias)->D1_FILIAL+(_cAlias)->D1_CC } ) ) = 0 
		   AAdd( _aDadosTotal , {(_cAlias)->D1_FILIAL+(_cAlias)->D1_CC , Posicione("CTT",1,xFilial("CTT")+(_cAlias)->D1_CC,"CTT_DESC01") , TRANSF((_cAlias)->D1_TOTAL,_cPicTotal) , (_cAlias)->D1_TOTAL} )
         AAdd(  _aControle , (_cAlias)->D1_FILIAL+(_cAlias)->D1_CC+_cEmail )
         _aAnaliTotal[Len(_aAnaliTotal),6]:=(_cAlias)->D1_TOTAL
		ElseIf aScan(_aControle , (_cAlias)->D1_FILIAL+(_cAlias)->D1_CC+_cEmail) <> 0
         _aDadosTotal[nPos,4]+=(_cAlias)->D1_TOTAL
         _aDadosTotal[nPos,3]:=TRANSF(_aDadosTotal[nPos,4],_cPicTotal)
         _aAnaliTotal[Len(_aAnaliTotal),6]:=(_cAlias)->D1_TOTAL
		EndIf    
		
	EndIf

	(_cAlias)->( DBSkip() )
EndDo
		
(_cAlias)->( DBCloseArea() )

Return .T.

/*
===============================================================================================================================
Programa----------: REST013CMP
Autor-------------: Alexandre Villar
Data da Criacao---: 03/12/2014
Descrição---------: Função para imprimir os dados
Parametros--------: _oPrint := Objeto de impressão do relatório
------------------: _nLinha := Controle de posicionamento de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST013CMP(_oPrint As Object)

Local _aResumo	:= {} As Array
Local _nI      := 0 As Numeric
Local _nX      := 0 As Numeric
Local _nColIni	:= 0100 As Numeric
Local _nLinha   := 0 As Numeric
Local _nTotFOR  := 0 As Numeric
//Configuracoes para "Exporta para PDF" / Envio via e-mail
Local _oFont14 	 := TFont():New( "Arial"	 ,, 14,,.T.) As Object
Local _oFontCour := TFont():New('Courier new',, 12,,.F.) As Object
Local _oFont1Cour:= TFont():New('Courier new',, 12,,.T.) As Object

Private _nColMax	:= 3280 As Numeric//ULTIMA COLUNA
Private _nColFimPDH := _nColMax-940 As Numeric//Pagina,Data e hora
//Configuracoes para "Exporta para PDF" / Envio via e-mail
Private _nLinMax	:= 2180 As Numeric //LINHA MAXIMA PARA QUEBRA
Private _aPosicao:= {} As Array//Preenchida na REST013Sub()

If !_lSchedule .And. !(_oPrint:CPRINTER == "PDF")// _oPrint:CPRINTER == "PDF" quer dizer Exporta PDF via seleção na Tela
   //**** Configuracoes para "Envia para Spool de impressao **********************************************************************************
   _nColMax	   := 3230//ULTIMA COLUNA
   _nColFimPDH := _nColMax-900//Pagina,Data e hora
   //**** Configuracoes para "Envia para Spool de impressao **********************************************************************************
EndIf
If _lRetrato
   _nColMax	   := 2530//ULTIMA COLUNA
   _nColFimPDH := _nColMax-940//Pagina,Data e hora
   _nLinMax	   := 3100//LINHA MAXIMA PARA QUEBRA
EndIf

_oPrint:StartPage()
	
REST013CAB( @_oPrint , @_nLinha  , _nColIni )
REST013Sub(_nColIni,_oPrint,@_nLinha,_oFont14)

_aResumo := aDados

If _cTipo <> "TOTAL"//QUEBRA DE TOTOAL POR CC
   _cSalvaCC:=_aResumo[1,_nPosQbra]
   _nTotalQBG:=0
   _nTotFOR:=_nPosQbra-1
Else
   _nTotFOR:=Len(_aResumo[1])
EndIf   

For _nX := 1 To Len(_aResumo)
	If _nLinha >= _nLinMax
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
		_oPrint:EndPage()
		_oPrint:StartPage()
		
		REST013CAB( @_oPrint , @_nLinha  , _nColIni)
    	REST013Sub(_nColIni,_oPrint,@_nLinha,_oFont14)
	EndIf

	If _cTipo <> "TOTAL"
		If _cSalvaCC <> _aResumo[_nX,_nPosQbra]//QUEBRA DE TOTOAL POR CC
	        _nLinha -= 025
			_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
			_nLinha += 040
			_oPrint:Say( _nLinha,_aPosicao[1],"TOTAL "+SubStr(_aResumo[_nX-1,_nPosQbra],1,2)+"-"+SubStr(_aResumo[_nX-1,_nPosQbra],3)+"-"+_aResumo[_nX-1,_nPosQbra+1],_oFont1Cour)
			_oPrint:Say( _nLinha,_aPosicao[_nPosTotal],TRANSF(_nTotalQBG,_cPicTotal),_oFont1Cour )
			_nTotalQBG:=0
			_cSalvaCC :=_aResumo[_nX,_nPosQbra]
			_nTotalQBG+=_aResumo[_nX,_nPosQbra+2]
	        _nLinha += 080
		Else
			_nTotalQBG+=_aResumo[_nX,_nPosQbra+2]
		EndIf
	EndIf

    For _nI := 1 To _nTotFOR
        _oPrint:Say( _nLinha,_aPosicao[_nI],_aResumo[_nX,_nI],_oFontCour )
    Next _nI
	_nLinha += 050
Next _nX

If _cTipo <> "TOTAL"
	_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
	_nLinha += 050
	_oPrint:Say( _nLinha,_aPosicao[1],"TOTAL "+SubStr(_aResumo[_nX-1,_nPosQbra],1,2)+"-"+SubStr(_aResumo[_nX-1,_nPosQbra],3)+"-"+_aResumo[_nX-1,_nPosQbra+1],_oFont1Cour )
	_oPrint:Say( _nLinha,_aPosicao[_nPosTotal],TRANSF(_nTotalQBG,_cPicTotal),_oFont1Cour )
	_nLinha += 050
EndIf

_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColMax )
_nLinha += 050
_oPrint:Say( _nLinha,_aPosicao[1],"TOTAL GERAL",_oFont1Cour )
_oPrint:Say( _nLinha,_aPosicao[_nPosTotal],TRANSF(_nTotal,_cPicTotal),_oFont1Cour )

Return

/*
===============================================================================================================================
Programa----------: REST013CAB
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
Descrição---------: Função para construir o cabeçalho da página
Parametros--------: _oPrint := Objeto de impressão do relatório
------------------: _nLinha := Controle de posicionamento de linhas
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST013CAB(_oPrint As Object, _nLinha As Numeric, _nColIni As Numeric)

Local _oFont10	:= TFont():New( "Arial" ,, 14 ,,.T. ) As Object
Local _oFont18	:= TFont():New( "Arial" ,, 28 ,,.T. ) As Object

_nLinha := 50
_nPagAux++

_oPrint:Line( _nLinha, _nColIni , _nLinha, _nColMax )
_nLinha += 015

_oPrint:SayBitmap( _nLinha-8, _nColIni + 020 , 'lgrl01.bmp' , 300 , 130 ) // Imagem tem que estar abaixo do RootPath

If _cTipo = "REST011"
   _nSomaCol1:=0865
   _nSomaCol2:=0//1200
   _nSomaCol3:=0//1080
   _cAssunto :="Relação produtos consumidos no CC"
ElseIf _cTipo = "RCOM009"
   _nSomaCol1:=0800
   _nSomaCol2:=0//1200
   _nSomaCol3:=0//1080
   _cAssunto :="Relação de serviços contratados no CC"
ElseIf _cTipo = "TOTAL"
   _nSomaCol1:=0820
   _nSomaCol2:=0//0950
   _nSomaCol3:=0//0810
   _cAssunto :="Relação gastos por CC "
EndIf

_cNomeFilial:='Filial: '+ _cFilial +' - '+ AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , "01" + _cFilial, 1, "" ))
_oPrint:Say( _nLinha+60 ,(_nColIni+_nSomaCol1), _cAssunto   , _oFont18 )
_oPrint:Say( _nLinha+135,(_nColIni+_nSomaCol2), _cNomeFilial, _oFont10 )

_oPrint:SayAlign( _nLinha,_nColFimPDH, 'Página: '+ StrZero(_nPagAux,3)	, _oFont10 ,900,100,, 1 )
_nLinha += 060

_oPrint:SayAlign( _nLinha,_nColFimPDH, 'Data: '+ DToC( Date() )	    , _oFont10 ,900,100,, 1 )
_nLinha += 055

_oPrint:SayAlign( _nLinha,_nColFimPDH, 'Hora: '+ Time()			    , _oFont10 ,900,100,, 1 )
_nLinha += 060

_cDts:="Periodo: "+_cDatas
If _lMensal
   _cDts+= " - MENSAL"
Else
   _cDts+= " - SEMANAL"
EndIf   
_oPrint:Say( _nLinha,(_nColIni+_nSomaCol3), _cDts , _oFont10 )
_nLinha += 015

_oPrint:Line( _nLinha , _nColIni , _nLinha, _nColMax )
_nLinha += 040

Return

/*
===============================================================================================================================
Programa----------: REST013Sub()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2014
Descrição---------: Imprimie os cabecalho  das colulas dos pedidos
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST013Sub(_nColIni As Numeric,_oPrint As Object,_nLinha As Numeric,_oFont14 As Object) As Logical

Local aTitulo:={aTit1,aTit2,aTit3} As Array
Local _nX := 0 As Numeric 
Local nTipo:=1 As Numeric

_aPosicao:={}

If _cTipo = "REST011"
//aTit1:={"Nr.S.A.","Produto","Descricao","Data","Entregue","Custo Total","Usr SA","OBS"}
	_nCol002:= _nColIni + 0140 //Produto
	_nCol003:= _nCol002 + 0200 //Descricao       
	_nCol004:= _nCol003 + 0550 //Data            
	_nCol00A:= _nCol004 + 0170 //APLICACAO DIRETA - ENTROU DEPOIS
	_nCol005:= _nCol004 + 0240 //Entregue        
	_nCol006:= _nCol005 + 0260 //Custo Total     
	_nCol007:= _nCol006 + 0250 //Usr SA
	_nCol008:= _nCol007 + 0190 //OBS
	
	AAdd(_aPosicao,_nColIni)//Nr.S.A.
	AAdd(_aPosicao,_nCol002)
	AAdd(_aPosicao,_nCol003)
	AAdd(_aPosicao,_nCol004)
	AAdd(_aPosicao,_nCol00A)
	AAdd(_aPosicao,_nCol005)
	AAdd(_aPosicao,_nCol006)
	AAdd(_aPosicao,_nCol007)
	AAdd(_aPosicao,_nCol008)
	
ElseIf _cTipo = "RCOM009"
//aTit2:={"Fornec","Rz.Social","Qtd.","Documento","Dt.Dig.","Vlr. Unit.","Valor","Descricao"}
	nTipo:=2
	_nCol002:= _nColIni + 0665
	_nCol003:= _nCol002 + 0250
	_nCol004:= _nCol003 + 0225
	_nCol005:= _nCol004 + 0215
	_nCol006:= _nCol005 + 0250
	_nCol007:= _nCol006 + 0250
	
	AAdd(_aPosicao,_nColIni)
	AAdd(_aPosicao,_nCol002)
	AAdd(_aPosicao,_nCol003)
	AAdd(_aPosicao,_nCol004)
	AAdd(_aPosicao,_nCol005)
	AAdd(_aPosicao,_nCol006)
	AAdd(_aPosicao,_nCol007)
	
ElseIf _cTipo = "TOTAL"
//aTit3:={"Fil Cod. CC","Centro de Custo","Custo Total"}	
	nTipo:=3
	_nCol002:= _nColIni + 0300
	_nCol003:= _nCol002 + 0800
	AAdd(_aPosicao,_nColIni)
	AAdd(_aPosicao,_nCol002)
	AAdd(_aPosicao,_nCol003)
	
EndIf

For _nX := 1 To Len(aTitulo[nTipo]) //Os titulos que determinam quantas colunas serão impressao
    _oPrint:Say( _nLinha,_aPosicao[_nX],aTitulo[nTipo,_nX],_oFont14 )
Next

_nLinha += 050
		
Return .T.

/*
===============================================================================================================================
Programa----------: REST013NameFile()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2014
Descrição---------: Gera o nome do arquivo com Date() e Time()
Parametros--------: Ccarga - numero da carga que será usado como parte do nome do arquivo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST013NameFile() As Character

Local	cFileName	:=	'' As Character
Local	cAux		   :=	'' As Character

cFileName:="REST013_"
cFileName+=DToS( Date() ) + "_"
cAux:=Time()
cAux:=StrTran( cAux , ":" , "" )
cFileName:=cFileName+cAux+".pdf"

Return cFileName

/*
==============================================================================================================================================================
Programa----------: REST013Select
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: Selects dos relatorios 
Parametros--------: Nenhum
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
Static Function REST013Select() As Logical

Local _cFiltro := "" As Character 
Local _cQuery  := "" As Character

If _cTipo = "REST011"
	If !Empty(DToS(MV_PAR02))
	   _cFiltro += " D3_EMISSAO >= '" + DToS(MV_PAR01) + "' AND "
	   _cFiltro += " D3_EMISSAO <= '" + DToS(MV_PAR02) + "' AND "
       _cDatas  := " De "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)
	EndIf

	If !Empty(MV_PAR07) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet) .Or. !Empty(_c5CCSintet)
	   _cFiltro += " ( "
   EndIf

	If !Empty(MV_PAR07) 
		_cFiltro += " D3_FILIAL||D3_CC  IN "+FormatIn(MV_PAR07,";")
   EndIf

   If !Empty(_c7CCSintet)
	   If !Empty(MV_PAR07) 
         _cFiltro += " OR "
      EndIf   
		_cFiltro += " SubStr(D3_FILIAL||D3_CC,1,7) IN "+FormatIn(_c7CCSintet,";")
	EndIf

   If !Empty(_c6CCSintet)
	   If !Empty(MV_PAR07) .Or. !Empty(_c7CCSintet)
         _cFiltro += " OR "
      EndIf
		_cFiltro += " SubStr(D3_FILIAL||D3_CC,1,6) IN "+FormatIn(_c6CCSintet,";")
	EndIf

   If !Empty(_c5CCSintet)
	   If !Empty(MV_PAR07) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet)
         _cFiltro += " OR "
      EndIf
		_cFiltro += " SubStr(D3_FILIAL||D3_CC,1,5) IN "+FormatIn(_c5CCSintet,";")
	EndIf

	If !Empty(MV_PAR07) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet) .Or. !Empty(_c5CCSintet)
	   _cFiltro += " ) AND "
   EndIf

	If !_lSchedule .And. !Empty(_cFilsGerent)
		_cFiltro += " D3_FILIAL IN "+FormatIn(_cFilsGerent,";")+" AND "
	EndIf

	_cQuery:=" SELECT  D3_FILIAL,D3_NUMSA,CP_PRODUTO,CP_DESCRI,CP_SOLICIT,D3_QUANT,D3_CUSTO1,D3_EMISSAO,D3_I_OBS,D3_CC,D3_I_ORIGE "
	_cQuery+="  FROM "+RetSQLName('SD3')+" SD3 "
	_cQuery+="  JOIN "+RetSQLName('SCP')+" SCP ON D3_FILIAL = CP_FILIAL AND D3_NUMSA = CP_NUM AND D3_ITEMSA = CP_ITEM "
	_cQuery+="   WHERE "+_cFiltro
	_cQuery+="    SD3.D3_ESTORNO <> 'S' AND "
	_cQuery+="    SCP.D_E_L_E_T_ = ' '  AND "
	_cQuery+="    SD3.D_E_L_E_T_ = ' '  "
	_cQuery+=" UNION ALL "
	_cQuery+=" SELECT  D3_FILIAL,D3_NUMSA,D3_COD,    B1_DESC,  D3_USUARIO,D3_QUANT,D3_CUSTO1,D3_EMISSAO,D3_I_OBS,D3_CC,D3_I_ORIGE "
	_cQuery+="  FROM "+RetSQLName('SD3')+" SD3 "
	_cQuery+="  JOIN "+RetSQLName('SB1')+" SB1 ON D3_COD = B1_COD "
	_cQuery+="   WHERE "+_cFiltro
	_cQuery+="    SD3.D3_ESTORNO <> 'S' AND "
	_cQuery+="    SD3.D3_NUMSA    = ' ' AND "
	_cQuery+="    SB1.D_E_L_E_T_  = ' ' AND "
	_cQuery+="    SD3.D_E_L_E_T_  = ' '     "
	_cQuery+="   ORDER BY D3_CC, D3_EMISSAO"
   MPSysOpenQuery(ChangeQuery(_cQuery),_cAlias)
   
ElseIf _cTipo = "RCOM009"
	If !Empty(MV_PAR04)
	   _cFiltro  += " SD1.D1_GRUPO >= '" + MV_PAR03 + "' AND "
	   _cFiltro  += " SD1.D1_GRUPO <= '" + MV_PAR04 + "' AND "
	EndIf

	If !Empty(DToS(MV_PAR08))
	   _cFiltro += " SD1.D1_DTDIGIT >= '" + DToS(MV_PAR07) + "' AND "
	   _cFiltro += " SD1.D1_DTDIGIT <= '" + DToS(MV_PAR08) + "' AND "
       _cDatas  := " De "+DToC(MV_PAR07)+" ate "+DToC(MV_PAR08)
	EndIf

	//busca CFOPS
	MV_PAR17 := AllTrim(MV_PAR17)
	If !Empty(MV_PAR17)
		_cFiltro  += "  SD1.D1_CF IN " + FormatIn(MV_PAR17,";")+" AND "//1933;2933
	EndIf

   If !Empty(MV_PAR18) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet).OR. !Empty(_c5CCSintet)
	   _cFiltro += " ( "
   EndIf

	If !Empty(MV_PAR18) 
		_cFiltro += " D1_FILIAL||D1_CC  IN "+FormatIn(MV_PAR18,";")
   EndIf

   If !Empty(_c7CCSintet)
	   If !Empty(MV_PAR18) 
         _cFiltro += " OR "
      EndIf
		_cFiltro += " SubStr(D1_FILIAL||D1_CC,1,7) IN "+FormatIn(_c7CCSintet,";")
	EndIf

   If !Empty(_c6CCSintet)
	   If !Empty(MV_PAR18) .Or. !Empty(_c7CCSintet)
         _cFiltro += " OR "
      EndIf
		_cFiltro += " SubStr(D1_FILIAL||D1_CC,1,6) IN "+FormatIn(_c6CCSintet,";")
	EndIf

   If !Empty(_c5CCSintet)
	   If !Empty(MV_PAR18) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet)
         _cFiltro += " OR "
      EndIf
		_cFiltro += " SubStr(D1_FILIAL||D1_CC,1,5) IN "+FormatIn(_c5CCSintet,";")
	EndIf

   If !Empty(MV_PAR18) .Or. !Empty(_c7CCSintet) .Or. !Empty(_c6CCSintet).OR. !Empty(_c5CCSintet)
	   _cFiltro += " ) AND "
   EndIf

	If !_lSchedule .And. !Empty(_cFilsGerent)
		_cFiltro  += " D1_FILIAL IN "+FormatIn(_cFilsGerent,";")+" AND "
	EndIf
	
	_cQuery:=" SELECT D1_FILIAL, D1_DOC, D1_FORNECE, D1_DTDIGIT, D1_QUANT, D1_VUNIT, D1_TOTAL, B1_DESC, A2_NOME RAZAO , D1_CC "
	_cQuery+=" FROM "+RetSQLName('SD1')+" SD1, "
	_cQuery+="      "+RetSQLName('SB1')+" SB1, "
	_cQuery+="      "+RetSQLName('SA2')+" SA2  "
	_cQuery+=" WHERE"+_cFiltro
	_cQuery+="      SB1.B1_COD      =  SD1.D1_COD     AND "
	_cQuery+="      SA2.A2_COD      =  SD1.D1_FORNECE AND "
	_cQuery+="      SA2.A2_LOJA     =  SD1.D1_LOJA    AND "
	_cQuery+="      SD1.D1_TES     <>  ' '            AND "  
	_cQuery+="      SA2.D_E_L_E_T_ = ' ' AND "
	_cQuery+="      SD1.D_E_L_E_T_ = ' ' AND "
	_cQuery+="      SB1.D_E_L_E_T_ = ' ' "
	_cQuery+="   ORDER BY D1_CC, D1_DTDIGIT, D1_DOC "
   MPSysOpenQuery(ChangeQuery(_cQuery),_cAlias)	
EndIf

Return .T.

/*
==============================================================================================================================================================
Programa----------: REST013Email
Autor-------------: Alex Wallauer
Data da Criacao---: 14/02/2019
Descrição---------: Envia os e-mails
Parametros--------: bExecuta
Retorno-----------: Nenhum
==============================================================================================================================================================
*/
Static Function REST013Email(bExecuta As CodeBlock) As Logical

Local _cEmlLog := "" As Character
Local _aConfig := U_ITCFGEML('') As Array
Local _cMsgEml := "" As Character
Local _cEnvPor := "" As Character
Local _ntamanho:= 0 As Numeric
Local _nI      := 0 As Numeric
Local _lAutSalv:= _lSchedule As Logical
Local cEmailCo := "" As Character

Private _cArqExcel:=StrTran(Upper(_cFileName),".PDF",".XLSX") As Character
Private _cArqAnali:=StrTran(Upper(_cFileName),".PDF","")+"Ana.XLSX" As Character

While _nI <= 5 .And. _ntamanho == 0//Verifica se gerou pdf com tamanho maior que zero, em caso de erro repete o relatório até 5 vezes
	_ntamanho := 0
	_adatfile := {}
	If File(_cFileName)
		_adatfile := directory(_cFileName)
		_ntamanho := _adatfile[1][2]
	EndIf
    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "REST013"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "REST01303"/*cMsgId*/, "REST01303 - Envio de E-mail do Arquivo: "+If(FILE(_cFileName),"","NAO")+ " achou " + _cFilename + " com tamanho  " + TRANSF(_ntamanho,"@E 999,999")/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	If _ntamanho = 0
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "REST013"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "REST01304"/*cMsgId*/, "REST01304 - Tentativa "+Str(_nI+1,1)+" de Gerar "+_cAssunto/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FErase(_cFileName)
 	   _lSchedule:=.T.
      _aGerExcel:={}//ZERA PARA NÃO DUPLICAR CADA VEZ QUE PASSAR
		EVAL(bExecuta)
 	   _lSchedule:=_lAutSalv		
	EndIf
	_nI++
EndDo

If _lSchedule
   If _lMensal
      _cEnvPor := "Mensal Automatico"
   Else
      _cEnvPor := "Semanal Automatico"
   EndIf   
Else
   _cEnvPor := UsrFullName(__cUserId)
EndIf
_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+_cAssunto+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+_cAssunto+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Esse relatorio contem as informações dos centros de custo abaixo</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" width="30%"><b>Periodo:</b></td>'//align="center"
_cMsgEml += '      <td class="itens" >'+ _cDatas +'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" width="30%"><b>Enviado de: </b></td>'//align="center"
_cMsgEml += '      <td class="itens" >'+ _cEnvPor +'</td>' 
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" width="30%"><b>Enviado para: </b></td>'//align="center"
_cMsgEml += '      <td class="itens" >'+ _cEnvPara +'</td>' 
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="center" width="30%"><b>Filial / C. Custo</b></td>'
_cMsgEml += '      <td class="grupos" align="center" ><b>Descrição</b></td>' 
_cMsgEml += '    </tr>'

_aCC:=StrTokArr(_cCentro,";")
For _nI := 1 To Len(_aCC)
	If !Empty(_aCC[_nI])
		_cMsgEml += '    <tr>'
		_cMsgEml += '      <td class="itens" align="center" width="30%">'+ SubStr(_aCC[_nI],1,2)+" / "+SubStr(_aCC[_nI],3) +'</td>'
		_cMsgEml += '      <td class="itens" >'+ Posicione("CTT",1,xFilial("CTT")+SubStr(_aCC[_nI],3),"CTT_DESC01") +'</td>'
		_cMsgEml += '    </tr>'
	EndIf
Next _nI

_cMsgEml += '	<tr>'
_cMsgEml += '		<td class="grupos" align="center" colspan="2"><b>Para maiores informações acesse o arquivo anexo.</b></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '	<tr>'
_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
If _lSchedule 
   _cMsgEml += '<BR><b>Ambiente:</b> ['+ _cAmbiente +'] / <b>Fonte:</b> [REST013] Via Schedule</BR>'
Else
   _cMsgEml += '<BR><b>Ambiente:</b> ['+ _cAmbiente +'] / <b>Fonte:</b> [REST013] Via Tela</BR>'
EndIf
_cAssunto+=" - "+_cDatas
If _lMensal
   _cAssunto+= " - MENSAL"
   _aGerExcel:=aSort(_aGerExcel,,,{|x,y| x[4] > y[4] })
Else
   _cAssunto+= " - SEMANAL"
EndIf

//TESTA DENTRO DA FUNÇÃO REST13GEREXCEL() SE A ARRAY _aGerExcel ESTA ZERADA
_cEmailAux:=_cEmail
If !_lSchedule
   _cEmail :=AllTrim(LOWER(UsrRetMail(RetCodUsr())))//PRECISA PASSAR AQUI MESMO COM A ARRAY _aGerExcel ZERADA
   LjMsgRun( "Gerando Excel: "+_cArqExcel , _cTitJanela , {|| _cArqExcel:= REST13GerExcel(_cPathSrv,_cArqExcel,_aCabExcel,_aGerExcel) } )
   If _lMensal
      LjMsgRun( "Gerando Excel: "+_cArqAnali , _cTitJanela , {|| _cArqAnali:= REST13GerExcel(_cPathSrv,_cArqAnali,_aCabExcel,_aAnaliTotal) } )
   EndIf   
Else
   _cArqExcel:= REST13GerExcel(_cPathSrv,_cArqExcel,_aCabExcel,_aGerExcel)
   If _lMensal
      _cArqAnali:= REST13GerExcel(_cPathSrv,_cArqAnali,_aCabExcel,_aAnaliTotal) 
   EndIf
EndIf   
If _lMensal
   If File(_cArqAnali)
      _cFileName:=_cFileName+";"+_cArqAnali
   EndIf
EndIf
//SE DENTRO DA FUNÇÃO REST13GEREXCEL() A ARRAY _aGerExcel CHEGAR ZERADA DEVOLVE A VARIAVEL _cArqExcel = ""
If File(_cArqExcel)
   _cFileName:=_cFileName+";"+_cArqExcel
EndIf

If _lSchedule
   //U_ITENVMAIL(cFrom        ,cEmailTo ,cEmailCo  ,cEmailBcc,cAssunto ,_cMsgEml ,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
   U_ITENVMAIL( _aConfig[01] , _cEmail , cEmailCo  ,         ,_cAssunto, _cMsgEml,_cFileName,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
Else
   LjMsgRun( "Enviando E-mail: "+_cEmail , _cTitJanela, {|| U_ITENVMAIL( _aConfig[01] , _cEmail , cEmailCo  ,         ,_cAssunto, _cMsgEml,_cFileName,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog ) } )
EndIf

If !Empty( _cEmlLog )
   cMensagem+=_cAssunto+" - "+_cEmlLog+ " - E-mail para: " + _cEmail+" - "+cEmailCo+" - Com anexo " + AllTrim(_cfileName) + " - PDF com tamanho de " + TRANSF(_ntamanho,"@E 9,999,999")+CHR(13)+CHR(10)
   AAdd(_aResultado,{_cFilial,"E-MAIL",TRANSF(Len(_aGerExcel),"@E 999,999"),_cEmail,_cCentro,_cAssunto+": "+_cEmlLog+ " Com anexo " + AllTrim(_cfileName) + ", PDF com tamanho de "+AllTrim(TRANSF(_ntamanho,"@E 9,999,999"))})
EndIf

If _cFileName # Nil .And. File(_cFileName)
   FErase(_cFileName)
EndIf
If _cArqExcel # Nil .And. File(_cArqExcel)
   FErase(_cArqExcel)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: REST13GerExcel()
Autor-------------: Alex Wallauer
Data da Criacao---: 13/06/2024
Descrição---------: Gera Excel e envia por e-mail
Parametros--------: _cPathSrv,_cArquivo,_aCabExcel,_aGerExcel
Retorno-----------: _cPathSrv+_cArquivo+".xlsx"
===============================================================================================================================
*/
Static Function REST13GerExcel(_cPathSrv As Character,_cArquivo As Character,_aCabExcel As Array,_aGerExcel As Array) As Character

Local _cNomePlan := "SEMANAL" As Character

If Len(_aCabExcel) = 0 .Or. Len(_aGerExcel) = 0//TESTA AQUI SE TÁ ZERADO 
   Return ""
EndIf

If "MENSAL" $ _cAssunto
   _cNomePlan:="MENSAL"
EndIf
If Upper(_cPathSrv) $ Upper(_cArquivo)//Se o arquivo _cArquivo já tiver o diretorio
   _cPathSrv:=""
   _cArquivo:=SubStr(_cArquivo,2)//TIRA A PRIMEIRA BARRA PQ NA FUNÇÃO U_ITGEREXCEL()) COLOCA DE NOVO _cDiretorio+"\"+_cNomeArq
EndIf
//ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo ,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX)
U_ITGEREXCEL(_cArquivo,_cPathSrv  ,_cAssunto,_cNomePlan,_aCabExcel ,_aGerExcel,           ,          ,        , .T.        ,            ,          , .T.        ,.T.)
If Empty(_cPathSrv)
   _cPathSrv:="/"//COLOCA A BARRA DE VOLTA PQ TIROU ANTES 
EndIf
If File(_cPathSrv+_cArquivo)
   Return (_cPathSrv+_cArquivo)
EndIf

Return ""
