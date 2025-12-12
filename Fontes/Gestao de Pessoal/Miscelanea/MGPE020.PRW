#Include	"Protheus.Ch"

/*
===============================================================================================================================
Programa----------: MGPE020
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/07/2019
Descrição---------: Rotina de extração dos dados para o envio a Alelo referente ao Vale Refeição - Chamado 30108
Retorno-----------: Nenhum  
===============================================================================================================================
*/
User Function MGPE020()

Local _aParAux:={} , nI
Local _aParRet:={}

Private _aItalac_F3:={}
_cRetorno:=Space(150)
//aAdd(_aItalac_F3,{"TST_CAMPO",_cTabela ,_nCpoChave,_nCpoDesc , _bCondTab , _cTitAux , _nTamChv , _aDados , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{ "MV_PAR01"  ,         ,          ,          ,           ,          ,          ,         ,          ,           ,       ,{|A| U_MGPE20DIR() }})

Private MV_PAR01:=Space(100)
If cFilant $ "90,92" 
   MV_PAR02:=U_ItGetMv("IT_VRCONTRA","11134414")+Space(10)
Else
   MV_PAR02:=U_ItGetMv("IT_VRCONTRA",Space(20))
EndIf
Private MV_PAR03:="VR_"+AllTrim(cFilant)+"_"+DToS(DATE())+".CSV"+Space(20)

aAdd( _aParAux , { 1 , "Selecione o Diretorio"    , MV_PAR01, "@!"    , ""	, 'F3ITLC', "" , 100 , .T. } )
aAdd( _aParAux , { 1 , "No. do Contrato da Filial", MV_PAR02, "@!"    , ""	, 	      , "" , 065 , .T. } )
aAdd( _aParAux , { 1 , "Nome Arquivo p/ Geracao"  , MV_PAR03, "@!"    , ""	, 	      , "" , 065 , !Empty(MV_PAR02) } )
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 

While .T.

   lSair:=.T.
   
   If !ParamBox( _aParAux , "Geração do Arquivo de Vale Refeição." , @_aParRet )
      Return .T.
   EndIf

   FWMsgRun( ,{|oproc| lSair:=MGPE020INI(oproc) } , "Processando..." , "Iniciando o processamento..." )

   If lSair
      Exit
   Else
      MsgInfo( "Arquivo gerado com sucesso!" )   
   EndIf

EndDo

SET DATE FORMAT TO "DD/MM/YY"
	
Return .T.

/*
===============================================================================================================================
Programa----------: ITSelDir
Autor-------------: Alexandre Villar
Data da Criacao---: 29/07/2019
Descrição---------: Permite selecionar um diretório local
Parametros--------: Nenhum
Retorno-----------: cDir - Caminho do diretório selecionado
===============================================================================================================================
*/

User Function MGPE20DIR()

While .T.
   cDir := tFileDialog( "Documento Texto |*.TXT","Selecione o Diretorio de Destino:" ,, MV_PAR01, .T., GETF_MULTISELECT)
   cDir := AllTrim(cDir)
   If !Empty(cDir) .And. !ExistDir(cDir) //Verifica a existência do diretório e tenta criar caso não exista   
		nCriaDir := MakeDir( cDir )
		If nCriaDir <> 0
			U_ITMsg("Não foi possível criar ou utilizar o diretório:"+ CRLF + CRLF + cDir,;
					            "Alerta", " Verificar permissões para Gravação na Pasta de destino.",1)
			Loop
		EndIf
	EndIf
   Exit
EndDo 

If !Empty(cDir)
    MV_PAR01  := cDir
EndIf    
_cRetorno := .T.//_cRetorno É Public e tem que devolver logica

Return .F. //Tem Retornar .F. para não chamar o resto da função de F3

/*
===============================================================================================================================
Programa----------: MGPE020INI
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/07/2019
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MGPE020INI(oproc)

Local _cQuery	   := ""
Local _aDados	   := {}
Local _cArq		   := ""
Local _cLocalEnt  := RIGHT(AllTrim(SM0->M0_CGC),4)
Local _cFilVesao  := SuperGetMV('IT_MGP20RL',.F.,  "90;92")

Private cAliasAux	:= GetNextAli8as()

//Grava Log de execução da rotina
U_ITLOGACS( "MGPE020" )

SET DATE FORMAT TO "DD/MM/YYYY"

oproc:cCaption := ("Lendo dados...")
ProcessMessages()

_cQuery := " SELECT  R0_FILIAL, R0_MAT, R0_VALCAL, RA_NOMECMP , RA_CIC, RA_NASC, RA_SEXO, RA_MAE, RA_EMAIL, RA_DDDCELU, RA_NUMCELU "
_cQuery += " FROM " +RETSQLNAME("SR0") + " SR0 "
_cQuery += " JOIN " +RETSQLNAME("SRA") + " SRA ON SRA.RA_MAT = SR0.R0_MAT AND SRA.RA_FILIAL = SR0.R0_FILIAL " 
_cQuery += " WHERE  SR0.R0_TPVALE = 1   " 
_cQuery += " AND SR0.R0_FILIAL = '"+cFilant+"' AND SR0.D_E_L_E_T_ = ' '  " 
_cQuery += " AND SRA.RA_FILIAL = '"+cFilant+"' AND SRA.D_E_L_E_T_ = ' '  " 
_cQuery += " AND SRA.RA_DEMISSA = ' ' "
_cQuery += " ORDER BY R0_MAT "
	
MPSysOpenQuery( _cQuery , cAliasAux ) 

oProc:cCaption := ("Contando os dados lidos...")
ProcessMessages()
DBSelectArea(cAliasAux)
(cAliasAux)->(DBGoTop())
_cTot := 0
COUNT TO _cTot
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
(cAliasAux)->(DBGoTop())
_npv:=0

If RIGHT(AllTrim(MV_PAR01),1) <> "\"
   _cArq:=AllTrim(MV_PAR01)+"\"
Else
   _cArq:=AllTrim(MV_PAR01)
EndIf   
_cArq:=_cArq+AllTrim(MV_PAR03)

If FILE(_cArq)
   FERASE(_cArq)
EndIf
_nHdl := FCreate(_cArq)

If _nHdl == -1
	MsgAlert("O arquivo de nome "+_cArq+" nao pode ser criado! Verifique os parametros.","Atencao!")
	Return .F.
EndIf

_cLinha:=";CONTRATO;;;;;;;;"
FWrite(_nHdl, _cLinha + chr(13) + chr(10))

_cLinha:="%;11134414;%;;;;;;;"
FWrite(_nHdl, _cLinha + chr(13) + chr(10))

If ! xFilial("SRA") $ _cFilVesao // Gerar o relatório no formato antigo.
   _cLinha:=";NOME DO USUARIO;CPF;DATA DE NASCIMENTO;CODIGO DE SEXO;VALOR;TIPO DE Local ENTREGA;Local DE ENTREGA;MATRICULA;NOME DA MAE;EMAIL;TELEFONE CELULAR"
Else // Para as filiais do parâmetro gerar o relatório no novo formato. 
   _cLinha:=";NOME DO USUARIO;CPF;DATA DE NASCIMENTO;CODIGO DE SEXO;VALOR;TIPO DE Local ENTREGA;Local DE ENTREGA;MATRICULA;"
EndIf 

FWrite(_nHdl, _cLinha + chr(13) + chr(10))

_nZerados:=0
_nGerados:=0

While (cAliasAux)->(!Eof())

	_npv++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()
    _aItens:={}
   If ! xFilial("SRA") $ _cFilVesao // Gerar o relatório no formato antigo. 
	   aAdd(_aItens,.T.)
	   aAdd(_aItens,(cAliasAux)->R0_FILIAL)
	   aAdd(_aItens,(cAliasAux)->R0_MAT)
	   aAdd(_aItens,(cAliasAux)->RA_NOMECMP)
	   aAdd(_aItens,AllTrim(TRANSFORM((cAliasAux)->R0_VALCAL,"@E 999,999,999.99")))
	   aAdd(_aItens,(cAliasAux)->RA_CIC)
	   aAdd(_aItens,DToC(SToD((cAliasAux)->RA_NASC)))
	   aAdd(_aItens,(cAliasAux)->RA_SEXO)
	   aAdd(_aItens,_cLocalEnt)
	   aAdd(_aItens,(cAliasAux)->RA_MAE)
	   aAdd(_aItens,(cAliasAux)->RA_EMAIL)
	   aAdd(_aItens,AllTrim((cAliasAux)->RA_DDDCELU+" "+(cAliasAux)->RA_NUMCELU))
   Else // Novo layout do relatório.
      //aAdd(_aItens,.T.)
      aAdd(_aItens,"%") 
      aAdd(_aItens,(cAliasAux)->RA_NOMECMP)
      aAdd(_aItens,(cAliasAux)->RA_CIC)
      aAdd(_aItens,DToC(SToD((cAliasAux)->RA_NASC)))
      aAdd(_aItens,(cAliasAux)->RA_SEXO)
	   aAdd(_aItens,AllTrim(TRANSFORM((cAliasAux)->R0_VALCAL,"@E 999,999,999.99")))
	   aAdd(_aItens,"FI") 
	   aAdd(_aItens,_cLocalEnt)
	   aAdd(_aItens,(cAliasAux)->R0_MAT)
      aAdd(_aItens,"%") 
   EndIf 
   
//------------------------------------------------------------------------    
    _cLinha:="%;"+AllTrim((cAliasAux)->RA_NOMECMP)+";"+;
                  AllTrim((cAliasAux)->RA_CIC)+";"+;
                  DToC(SToD((cAliasAux)->RA_NASC))+";"+;
                  (cAliasAux)->RA_SEXO+";"+;
                  AllTrim(TRANSFORM((cAliasAux)->R0_VALCAL,"@E 999,999,999.99"))+";FI;"+;
                  _cLocalEnt+";"+;
                  AllTrim(Str(Val((cAliasAux)->R0_MAT)))+";"
    //--------------------------------------------------------------------
    If ! xFilial("SRA") $ _cFilVesao // Gerar o relatório no formato antigo. 
       _cLinha+=AllTrim((cAliasAux)->RA_MAE)+";"
	    _cLinha+=AllTrim((cAliasAux)->RA_EMAIL)+";"
       If !Empty((cAliasAux)->RA_NUMCELU)
	       _cLinha+=AllTrim(((cAliasAux)->RA_DDDCELU)+AllTrim((cAliasAux)->RA_NUMCELU)+";%")
       Else
	       _cLinha+=";%"
       EndIf
    Else // Para o novo formato do relatório. 
       _cLinha+="%"
    EndIf    
    //---------------------------------------------------------------------
    If (cAliasAux)->R0_VALCAL > 0
	    FWrite(_nHdl, _cLinha + chr(13) + chr(10))
       _nGerados++
    Else
       //_aItens[1]:=.F. 
       _nZerados++
    EndIf

	 aAdd(_aDados,_aItens)

    (cAliasAux)->(DBSkip())
 
EndDo

(cAliasAux)->( DBCloseArea() )

FClose(_nHdl)

//Monta _aCab
_aCab:={}

If ! xFilial("SRA") $ _cFilVesao // Gerar o relatório no formato antigo. 
   aAdd(_aCab,"")
   aAdd(_aCab,Upper(Getsx3cache("R0_FILIAL","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("R0_MAT","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_NOMECMP","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("R0_VALCAL","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_CIC","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_NASC","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_SEXO","X3_TITULO")))
   aAdd(_aCab,"Local DE ENTREGA")
   aAdd(_aCab,"NOME DA MAE")
   aAdd(_aCab,"EMAIL")
   aAdd(_aCab,"TELEFONE CELULAR")
Else // Novo Layout
   //aAdd(_aCab,"")
   aAdd(_aCab,"")
   aAdd(_aCab,Upper(Getsx3cache("RA_NOMECMP","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_CIC","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_NASC","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("RA_SEXO","X3_TITULO")))
   aAdd(_aCab,Upper(Getsx3cache("R0_VALCAL","X3_TITULO")))
   aAdd(_aCab,"TIPO Local DE ENTREGA")
   aAdd(_aCab,"Local DE ENTREGA")
   aAdd(_aCab,Upper(Getsx3cache("R0_MAT","X3_TITULO")))
   aAdd(_aCab,"")

EndIf  

If Len(_aDados) > 0
   _cTitulo:="LOG dos dados gerados no arquivo "+_cArq
   _cMsgTop:="ARQUIVO "+Upper(_cArq)+" GERADO COM SUCESSO / "+;
             AllTrim(TRANSFORM(_nGerados,"@E 999,999,999"))+" Matriculas Geradas / "+;
             _cTot+" Matriculas Lidas / "+;
             AllTrim(TRANSFORM(_nZerados,"@E 999,999,999"))+" Matriculas Zeradas"
   If ! xFilial("SRA") $ _cFilVesao // Gerar o relatório no formato antigo.           
	   U_ITLISTBOX(_cTitulo, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop)
   Else 
      U_ITLISTBOX(_cTitulo, _aCab    , _aDados   , .T.      ,        ,_cMsgTop)
   EndIf 
Else
	U_ITMsg("Nenhum registro gerado!","Atenção",,1)
EndIf

Return .F.
