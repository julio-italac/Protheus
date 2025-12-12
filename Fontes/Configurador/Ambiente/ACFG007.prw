#Include "TOTVS.ch"
#Include 'FWMVCDEF.CH'

/*
===============================================================================================================================
Programa--------: ACFG007
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/05/2023
Descrição-------: Rotina de manutenção de multiplos campos do cadastro de usuários Italac. Chamado 43839.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACFG007

Local _nI      := 0     As Numeric
Local _nJ      := 0     As Numeric
Local _aCampos := {}    As Array
Local _aBkpARot:= {}    As Array
Local _aSeek   := {}    As Array
Local _cCampZZL1 := ''  As Character
Local _cCampZZL2 := ''  As Character
Local _cCampZZL3 := ''  As Character
Local _cCpoBlq   := ''  As Character

Private _oBrowse     := Nil                                       As Object
Private CCADASTRO    := "Alteração de Multipos Usuários Italac"   As Character
Private _aFields     := {}                                        As Array
Private _oMrkBrowse  := Nil                                       As Object
Private _cPerg	      := "ACFG007"                                 As Character
Private _aItalac_F3  := {}                                        As Array
Private _aCamposAlt  := {}                                        As Array

If Type("aRotina") <> "U"
   _aBkpARot := AClone(aRotina)
EndIf

_cCpoBlq := "ZZL_USER;/ZZL_NOME;/ZZL_MATRIC;/ZZL_EMAIL;"

aRotina := {}
aRotina := Menudef()

_cCampZZL1 := AllTrim( SuperGetMV( 'IT_ACMZZL1',.F.,"ZZL_MNTDTE;" ) )
_cCampZZL2 := AllTrim( SuperGetMV( 'IT_ACMZZL2',.F.,"" ) )
_cCampZZL3 := AllTrim( SuperGetMV( 'IT_ACMZZL3',.F.,"" ) )  

If Empty(_cCampZZL1) .And. Empty(_cCampZZL2) .And. Empty(_cCampZZL3)    
   U_ITMsg("Para efetuar a alteração multipla de usuários Italac é obrigatório selecionar pelo menos um campo para alteração.","Atenção",,1) 
   Break 
EndIf

If Alltrim(_cCampZZL1) $ _cCpoBlq .Or. Alltrim(_cCampZZL2) $ _cCpoBlq .Or. Alltrim(_cCampZZL3) $ _cCpoBlq 
   U_ITMsg("Não é permitida a alteração dos campos:" + Chr(13) + Chr(10) + "ZZL_USER" + Chr(13) + Chr(10) + "ZZL_NOME" + Chr(13) + Chr(10) + "ZZL_MATRIC" + Chr(13) + Chr(10) + "ZZL_EMAIL","Atenção","Verifique o conteudo dos parâmetros:" + Chr(13) + Chr(10) + "IT_ACMZZL1"  + Chr(13) + Chr(10) + "IT_ACMZZL2"  + Chr(13) + Chr(10) + "IT_ACMZZL3",1)
   Break 
Endif

// Monta Array com Campos a serem alterados.
If ! Empty(_cCampZZL1) 
   If Left(AllTrim(_cCampZZL1),1) <> ";"
      _cCampZZL1 := AllTrim(_cCampZZL1) + ";"
   EndIf 

   _aCampos := U_ITTXTARRAY(_cCampZZL1,";",10)
   For _nI := 1 To Len(_aCampos)
      _nJ := aScan(_aCamposAlt, AllTrim(_aCampos[_nI]))
      If _nJ == 0 .And. ! Empty(_aCampos[_nI])
         AAdd(_aCamposAlt, AllTrim(_aCampos[_nI]))
      EndIf 
   Next _nI
EndIf 

If ! Empty(_cCampZZL2) 
   If Left(AllTrim(_cCampZZL2),1) <> ";"
      _cCampZZL2 := AllTrim(_cCampZZL2) + ";"
   EndIf 

   _aCampos := U_ITTXTARRAY(_cCampZZL2,";",10)
   For _nI := 1 To Len(_aCampos)
      _nJ := aScan(_aCamposAlt, AllTrim(_aCampos[_nI]))
      If _nJ == 0 .And. ! Empty(_aCampos[_nI])
         AAdd(_aCamposAlt, AllTrim(_aCampos[_nI]))
      EndIf 
   Next _nI
EndIf 

If ! Empty(_cCampZZL3) 
   If Left(AllTrim(_cCampZZL3),1) <> ";"
      _cCampZZL3 := AllTrim(_cCampZZL3) + ";"
   EndIf 

   _aCampos := U_ITTXTARRAY(_cCampZZL3,";",10)
   For _nI := 1 To Len(_aCampos)
      _nJ := aScan(_aCamposAlt, AllTrim(_aCampos[_nI]))
      If _nJ == 0 .And. ! Empty(_aCampos[_nI])
         AAdd(_aCamposAlt, AllTrim(_aCampos[_nI]))
      EndIf 
   Next
EndIf 

// Cria a s variáveis de memória do Array conforme configurações do dicionário de dados.
For _nI := 1 To Len(_aCamposAlt)
   &("M->"+AllTrim(_aCamposAlt[_nI])) := CriaVar(AllTrim(_aCamposAlt[_nI]))   
Next _nI

// Efetua a leitura dos dados e cria tabelas temporarias
FWMsgRun( ,{|_oProc| U_ACFG007L(_oProc) } , 'Aguarde...' , 'Efetuando Leitura dos dados...' )

_aSeek := {}
AAdd(_aSeek,{RetTitle("ZZL_CODUSU")	,{{"","C",006,0,RetTitle("ZZL_CODUSU")	,"@!"}} } )
AAdd(_aSeek,{RetTitle("ZZL_USER")	,{{"","C",025,0,RetTitle("ZZL_USER")	,"@!"}} } )
AAdd(_aSeek,{RetTitle("ZZL_NOME")	,{{"","C",030,0,RetTitle("ZZL_NOME")	,"@!"}} } )

// Criação da MarkBrowse
_oMrkBrowse:= FWMarkBrowse():New()
_oMrkBrowse:SetDataTable(.T.)
_oMrkBrowse:SetAlias("TRBZZL")
_oMrkBrowse:SetDescription("Ajustes em Multiplos Usuarios")
_oMrkBrowse:SetFieldMark('ZZL_OK')
_oMrkBrowse:SetFields( _aFields )
_oMrkBrowse:oBrowse:SetSeek(.T.,_aSeek)
_oMrkBrowse:Activate()

aRotina := AClone(_aBkpARot)

Return 

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/03/2021                            .
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu.
===============================================================================================================================
*/
Static Function MenuDef() As Array

Local _aRotina := {} As Array

ADD OPTION _aRotina Title 'Altera Dados'  Action 'U_ACFG007A'	OPERATION 4 ACCESS 0

Return(_aRotina)

/*
===============================================================================================================================
Programa--------: ACFG007L
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/05/2023
Descrição-------: Grava Tabela Temporária para alteração de multiplos usuários.
Parametros------: _oProc = Objeto da regua de processamento.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACFG007L(_oProc As Object)

Local _aStruct    := {}             As Array
Local _aStrucZZL  := {}             As Array
Local _nI         := 0              As Numeric
Local _cAlias     := GetNextAlias() As Character

BeginSql alias _cAlias
   SELECT ZZL_CODUSU, ZZL_USER, ZZL_NOME, ZZL_EMAIL, ZZL_MNTDTE, R_E_C_N_O_ NRRECNO
   FROM %Table:ZZL%
   WHERE D_E_L_E_T_ = ' ' 
EndSql

Count To _nTotRegs

(_cAlias)->(DBGoTop())

If _nTotRegs > 0    // Cria a tabela temporária
   AAdd(_aStruct,{"ZZL_OK"      , "C",  2, 0})
   AAdd(_aStruct,{"ZZL_CODUSU"  , "C",  6, 0})
   AAdd(_aStruct,{"ZZL_USER"    , "C",  25, 0})  
   AAdd(_aStruct,{"ZZL_NOME"    , "C",  30, 0})
   AAdd(_aStruct,{"ZZL_EMAIL"   , "C",  60, 0})   
   AAdd(_aStruct,{"ZZL_MNTDTE"  , "C",  10, 0})
   AAdd(_aStruct,{"ZZL_RECNO"   , "N",  10, 0})   

   // Montando o _aFields do FWMarkBrowse.
   //                         Titulo      Code-Block          Tipo  Picture  Alinhamento   Tamanho                 Decimal
   AAdd(_aFields, {" "                   ,{|| TRBZZL->ZZL_OK}    , "C",     , 1           ,2                      ,0}) 
   AAdd(_aFields, {RetTitle("ZZL_CODUSU"),{|| TRBZZL->ZZL_CODUSU}, "C", "@!", 1           ,TamSX3("ZZL_CODUSU")[1],TamSX3("ZZL_CODUSU")[2]}) 
   AAdd(_aFields, {RetTitle("ZZL_USER")  ,{|| TRBZZL->ZZL_USER}  , "C", "@!", 1           ,TamSX3("ZZL_USER")[1]  ,TamSX3("ZZL_USER")[2]}) 
   AAdd(_aFields, {RetTitle("ZZL_NOME")  ,{|| TRBZZL->ZZL_NOME}  , "C", "@!", 1           ,TamSX3("ZZL_NOME")[1]  ,TamSX3("ZZL_NOME")[2]}) 
   AAdd(_aFields, {RetTitle("ZZL_EMAIL") ,{|| TRBZZL->ZZL_EMAIL} , "C", "@!", 1           ,TamSX3("ZZL_EMAIL")[1] ,TamSX3("ZZL_EMAIL")[2]}) 
   
   If Select("TRBZZL") <> 0
      TRBZZL->(DBCloseArea())
   EndIf
   
   // Cria arquivo de dados temporário
   _oTemp := FWTemporaryTable():New( "TRBZZL",  _aStruct )
   _otemp:AddIndex( "01", {"ZZL_CODUSU"} ) // CÓDIGO DE USUÁRIO
   _otemp:AddIndex( "02", {"ZZL_USER"} )   // USUÁRIO
   _otemp:AddIndex( "03", {"ZZL_NOME"} )   // NOME DO USUÁRIO

   _otemp:Create()

   // Cria Tabela Temporária com os campos selecionados na tela de parâmetros iniciais.
   _aStrucZZL := {}

   For _nI := 1 To Len(_aCamposAlt)
      AAdd(_aStrucZZL, {_aCamposAlt[_nI],Getsx3cache(_aCamposAlt[_nI],"X3_TIPO"), Getsx3cache(_aCamposAlt[_nI],"X3_TAMANHO"),Getsx3cache(_aCamposAlt[_nI],"X3_DECIMAL")} )
   Next _nI
   
   If Select("TRBALT") <> 0
      TRBALT->(DBCloseArea())
   EndIf

   // Cria arquivo de dados temporário
   _oTemp2 := FWTemporaryTable():New( "TRBALT",  _aStrucZZL )
   _otemp2:Create()

   TRBALT->(DbAppend()) // Após criar a tabela, insere um registro vazio para digitação.
   TRBALT->(MSUnLock())

   // Grava na tabela temporária os dados da Query e os cálculos de reajustes.
   _nI := 1

   While ! (_cAlias)->(Eof())
      _oProc:cCaption := ("Gravando Tabelas Temporárias de Usuários..." + AllTrim(Str(_nI,10)) + "/" + AllTrim(Str(_nTotRegs,10)))
      ProcessMessages()
   
      TRBZZL->(RecLock("TRBZZL",.T.))
      TRBZZL->ZZL_OK     := "  "
      TRBZZL->ZZL_CODUSU := (_cAlias)->ZZL_CODUSU
      TRBZZL->ZZL_USER   := (_cAlias)->ZZL_USER
      TRBZZL->ZZL_NOME   := (_cAlias)->ZZL_NOME
      TRBZZL->ZZL_EMAIL  := (_cAlias)->ZZL_EMAIL
      TRBZZL->ZZL_RECNO  := (_cAlias)->NRRECNO
      TRBZZL->ZZL_MNTDTE := (_cAlias)->ZZL_MNTDTE
      TRBZZL->(MSUnLock())        

      (_cAlias)->(DBSkip())
      
      _nI += 1
   EndDo
EndIf

(_cAlias)->(DBCloseArea())

Return

/*
=================================================================================================================================
Programa--------: ACFG007A()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/05/2023
Descrição-------: Rotina de alteração multipla de usuários Italac.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function ACFG007A

Local _aSizeAut   := MsAdvSize(.T.) As Array
Local _oDlgAlt    := Nil            As Object
Local _nI         := 0              As Numeric
Local _aBkpAHead  := {}             As Array
Local _aBkpARot   := {}             As Array
Local _nOpc       := 0              As Numeric

Private _oGetTRBA := Nil            As Object

If Type("aHeader") <> "U"
   _aBkpAHead := AClone(aHeader)
EndIf 

aHeader := {}
aCols   := {}
_aLinhaAC := {}

For _nI := 1 To Len(_aCamposAlt)
      AAdd(aHeader ,{Getsx3cache(_aCamposAlt[_nI],"X3_TITULO"),;    // 1  = X3_TITULO 
                     Getsx3cache(_aCamposAlt[_nI],"X3_CAMPO"),;     // 2  = X3_CAMPO
                     Getsx3cache(_aCamposAlt[_nI],"X3_PICTURE") ,;  // 3  = X3_PICTURE                    
                     Getsx3cache(_aCamposAlt[_nI],"X3_TAMANHO") ,;  // 4  = X3_TAMANHO            
                     Getsx3cache(_aCamposAlt[_nI],"X3_DECIMAL") ,;  // 5  = X3_DECIMAL
                     Getsx3cache(_aCamposAlt[_nI],"X3_VALID") ,;    // 6  = X3_VALID                 
                     Getsx3cache(_aCamposAlt[_nI],"X3_USADO") ,;    // 7  = X3_USADO
                     Getsx3cache(_aCamposAlt[_nI],"X3_TIPO") ,;     // 8  = X3_TIPO                   
                     Getsx3cache(_aCamposAlt[_nI],"X3_F3"),;        // 9  = X3_CONTEXT 
                     Getsx3cache(_aCamposAlt[_nI],"X3_CONTEXT"),;   // 10 = X3_CONTEXT 
                     Getsx3cache(_aCamposAlt[_nI],"X3_CBOX")})      // 11 = X3_F3
      
      AAdd(_aLinhaAC,CriaVar(_aCamposAlt[_nI]))
Next _nI

AAdd(_aLinhaAC,.F.)
AAdd(aCols,_aLinhaAC)

// Faz backup e mota aRotina para o MSGETDB e inicializa variavei de inclusão e alteração do MsgetDb.
_aBkpARot := AClone(aRotina)
aRotina := {}   
AAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
AAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
AAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
AAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
AAdd(aRotina,{"Excluir"		,"AxExclui",0,5})
Inclui := .F.
Altera := .T.

// Configurações Iniciais 
_aObjects := {} 
AAdd( _aObjects, { 315,  50, .T., .T. } )
AAdd( _aObjects, { 100, 100, .T., .T. } )

_aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

_aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

// Monta tela do MSGETDB.
DEFINE MSDIALOG _oDlgALT TITLE "Alteração Multipla dos Usuários Italac" FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL // 00,00 TO 300,400

   @ _aPosObj[2,3]-30, 05  BUTTON _OBtnEfetiva PROMPT "&Gravar" SIZE 70, 012 OF _oDlgAlt ACTION ( _nOpc := 1, _oDlgAlt:End() ) PIXEL
   @ _aPosObj[2,3]-30, 90  BUTTON _OBtnSair    PROMPT "&Sair"	 SIZE 50, 012 OF _oDlgAlt ACTION ( _nOpc := 0, _oDlgAlt:End() ) PIXEL
               //MsNewGetDados():New( [ nTop], [ nLeft], [ nBottom]       , [ nRight ]   , [ nStyle], [ cLinhaOk]  , [ cTudoOk]   ,   [ cIniCpos], [ aAlter]  , [ nFreeze], [ nMax], [ cFieldOk]  , [ cSuperDel], [ cDelOk]    , [ oWnd] , [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] ) --> Objeto
   _oGetTRBA := MsNewGetDados():New( 015    , 0       , _aPosObj[2,3]-50 , _aPosObj[2,4], GD_UPDATE, "AllwaysTrue", "AllwaysTrue", ""           , _aCamposAlt,           , 1      , "AllwaysTrue", ""          , "AllwaysTrue", _oDlgAlt, aHeader       , aCols)

ACTIVATE MSDIALOG _oDlgAlt CENTERED

If _nOpc == 1
   If ! U_ITMsg("Confirma a gravação dos dados?","Atenção" , , ,2, 2) 
      Break 
   EndIf
   
   U_ACFG007G()
EndIf 

aRotina := AClone(_aBkpARot)
aHeader := AClone(_aBkpAHead)

Return

/*
===============================================================================================================================
Programa--------: ACFG007G
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/05/2023
Descrição-------: Rotina de gravação dos dados alterados.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACFG007G

Local _aDadoAnte  := {}                   As Array
Local _cMarca     := _oMrkBrowse:Mark()   As Character
Local _nI         := 0                    As Numeric

TRBZZL->(DBGoTop())
While ! TRBZZL->(Eof())
   If _oMrkBrowse:IsMark(_cMarca)
      ZZL->(DBGoTo(TRBZZL->ZZL_RECNO))
      
      _aDadoAnte := U_ITIniLog( 'ZZL', _aCamposAlt)	// Monta array com os dados antes das alterações.
      // Atualiza tabela ZZL
      ZZL->(RecLock("ZZL",.F.))
      
      For _nI := 1 To Len(_aCamposAlt)
         &("ZZL->"+AllTrim(_aCamposAlt[_nI])) := &("M->"+AllTrim(_aCamposAlt[_nI]))     
      Next _nI

      ZZL->(MSUnLock())
      
      // Grava log de alteração.
      U_ITGrvLog( _aDadoAnte , "ZZL" , 1 , ZZL->ZZL_FILIAL+FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] , "A" , __cUserId, Date() , Time() )            
   EndIf 

   TRBZZL->(DBSkip()) 
EndDo

U_ITMsg("Dados gravados com sucesso!.","Atenção",,2)

FWMsgRun( ,{|_oProc| U_ACFG007L(_oProc) } , 'Aguarde...' , 'Efetuando Leitura dos dados...' ) //JJS

Return
