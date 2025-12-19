#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS153
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2021
Descrição---------: Cadastro de Premissas. Chamado: 50568 
===============================================================================================================================
*/ 
User Function AOMS153()
 Local _oBrowse := Nil As Object
 Private __cCod := "" As Character
 Private __cPeriod := "" As Character
 _oBrowse := FWMBrowse():New()
 _oBrowse:SetAlias("Z38")
 _oBrowse:SetMenuDef( 'AOMS153' )
 _oBrowse:SetDescription("Premissa")
 _oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Rotina de definição automática do menu via MVC
===============================================================================================================================
*/
Static Function MenuDef() As Array
 Local _aRotina:= {} As Array
 
 ADD OPTION _aRotina Title 'Visualizar'	Action 'VIEWDEF.AOMS153'	OPERATION 2 ACCESS 0
 ADD OPTION _aRotina Title 'Incluir'   	Action 'VIEWDEF.AOMS153'	OPERATION 3 ACCESS 0
 ADD OPTION _aRotina Title 'Alterar'   	Action 'VIEWDEF.AOMS153'	OPERATION 4 ACCESS 0
 ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS153'	OPERATION 5 ACCESS 0
 ADD OPTION _aRotina Title 'Copiar'     Action 'VIEWDEF.AOMS153'   OPERATION 9 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Rotina de definição do Modelo de Dados do MVC
===============================================================================================================================
*/
Static Function ModelDef() As Object
 Local _oStruZ38 := FWFormStruct(1,"Z38") As Object
 Local _oStruZ39 := FWFormStruct(1,"Z39",{ |x| AllTrim(x) $ 'Z39_COD, Z39_DESC, Z39_PERIOD,Z39_PRODUT,Z39_DESCP,Z39_TIPO, Z39_UM, Z39_FATOR, Z39_TPCONV' } ) As Object
 Local _oStruZ40 := FWFormStruct(1,"Z40",{ |x| !AllTrim(x) $ 'Z40_COD, Z40_DESC, Z40_PERIOD' } ) As Object
 Local _oModel  As Object
 Local _aAuxFWDGat := {} As Array
 Local _bPosValidacao := {|| U_AOMS153H(_oModel) } As Block
 Local _bCommit := {|| U_AOMS153K(_oModel) } As Block
 Local _aZ39Rel := {} As Array
 Local _aZ40Rel := {} As Array  
 
 _oStruZ38:AddField( ;
         AllTrim('Bloqueado?') , ;   // [01] C Titulo do campo
         AllTrim('') , ;             // [02] C ToolTip do campo
         'Z38_MSBLQL' , ;            // [03] C identificador (ID) do Field
         'C' , ;                     // [04] C Tipo do campo
         1 , ;                       // [05] N Tamanho do campo
         0 , ;                       // [06] N Decimal do campo
         NIL , ;                     // [07] B Code-block de validação do campo
         NIL , ;                     // [08] B Code-block de validação When do campo
         NIL , ;                     // [09] A Lista de valores permitido do campo
         NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
         { || IIf(INCLUI, "2",Z38->Z38_MSBLQL) } , ;  // [11] B Code-block de inicializacao do campo
         NIL , ;                     // [12] L Indica se trata de um campo chave
         .T. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
         .F. )                       // [14] L Indica se o campo é virt
 
 // Monta a estrutura dos gatilhos
 _aAuxFWDGat := FwStruTrigger('Z38_COD','Z38_DESC','U_AOMS153G(M->Z38_FILIAL,M->Z38_COD)',.F.)
 _oStruZ38:AddTrigger(_aAuxFWDGat[01],_aAuxFWDGat[02],_aAuxFWDGat[03],_aAuxFWDGat[04])
 
 _oModel := MPFormModel():New('AOMS153M' ,/*bPreValidacao*/ , _bPosValidacao /*_bPosValidacao*/ , _bCommit /*bCommit*/ , /*bCancel*/)
 
 _oModel:AddFields("Z38MASTER",/*cOwner*/,_oStruZ38)
 
 aAdd(_aZ39Rel, {'Z39_FILIAL', 'Z38MASTER.Z38_FILIAL'} )
 aAdd(_aZ39Rel, {'Z39_COD'   , 'Z38MASTER.Z38_COD'})
 aAdd(_aZ39Rel, {'Z39_PERIOD', 'Z38MASTER.Z38_PERIOD'})
 
 _oModel:AddGrid("Z39DETAIL" , "Z38MASTER" , _oStruZ39 , )
 _oModel:SetRelation( "Z39DETAIL" , _aZ39Rel , Z39->( IndexKey( 1 ) ) )
 _oModel:GetModel('Z39DETAIL'):SetOnlyQuery(.T.)
 
 aAdd(_aZ40Rel, {'Z40_FILIAL', 'Z38MASTER.Z38_FILIAL'} )
 aAdd(_aZ40Rel, {'Z40_COD'   , 'Z38MASTER.Z38_COD'})
 aAdd(_aZ40Rel, {'Z40_PERIOD', 'Z38MASTER.Z38_PERIOD'})
 
 _oModel:AddGrid("Z40DETAIL" , "Z38MASTER" , _oStruZ40 , )
 _oModel:SetRelation( "Z40DETAIL" , _aZ40Rel , Z40->( IndexKey( 1 ) ) )
 
 
 _oModel:GetModel('Z40DETAIL'):SetNoInsertLine( .T. )
 _oModel:GetModel('Z40DETAIL'):SetNoDeleteLine( .T. )//Para não permitir exclusão de linhas
 _oModel:GetModel('Z40DETAIL'):SetNoUpdateLine( .T. )
 _oModel:GetModel('Z40DETAIL'):SetOptional(.T.)
 _oModel:GetModel('Z40DETAIL'):SetOnlyQuery(.T.)//Para não permitir edição direta na grid
 //_oModel:GetModel('Z40DETAIL'):SetOnlyView(.T.) 
 
 _oModel:GetModel('Z39DETAIL'):SetNoInsertLine( .T. )
 _oModel:GetModel('Z39DETAIL'):SetNoDeleteLine( .T. )//Para não permitir exclusão de linhas
 _oModel:GetModel('Z39DETAIL'):SetNoUpdateLine( .T. )
 _oModel:GetModel('Z39DETAIL'):SetOptional(.T.)
 _oModel:GetModel('Z39DETAIL'):SetOnlyQuery(.T.)//Para não permitir edição direta na grid
 //_oModel:GetModel('Z39DETAIL'):SetOnlyView(.T.) 
 
 _oModel:SetPrimaryKey( {'Z38_FILIAL','Z38_COD','Z38_PERIOD' } )
 _oModel:SetDescription("Premissas")
 
 _oModel:SetVldActivate( { |_oModel| .T. } )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 28/12/2022
Descrição---------: Rotina de definição da View do MVC
===============================================================================================================================
*/ 
Static Function ViewDef() As Object
 Local _oStruZ38 := FWFormStruct(2,"Z38") As Object
 Local _oStruZ39 := FWFormStruct(2,"Z39",{ |x| AllTrim(x) $ 'Z39_PRODUT,Z39_DESCP,Z39_TIPO, Z39_UM, Z39_FATOR, Z39_TPCONV' } ) As Object
 Local _oStruZ40 := FWFormStruct(2,"Z40",{ |x| !AllTrim(x) $ 'Z40_COD, Z40_DESC, Z40_PERIOD' } ) As Object
 Local _oModel   := FWLoadModel("AOMS153") As Object
 Local _oView    := Nil As Object
 
     _oStruZ38:AddField( ;                       // Ord. Tipo Desc.
         'Z38_MSBLQL'                    , ;     // [01] C   Nome do Campo
         "99"                            , ;     // [02] C   Ordem
         AllTrim( 'Bloqueado?' )         , ;     // [03] C   Titulo do campo
         AllTrim( 'Bloqueado?' )         , ;     // [04] C   Descricao do campo
         { 'Legenda' }                   , ;     // [05] A   Array com Help
         'C'                             , ;     // [06] C   Tipo do campo
         ''                              , ;     // [07] C   Picture
         NIL                             , ;     // [08] B   Bloco de Picture Var
         ''                              , ;     // [09] C   Consulta F3
         .T.                             , ;     // [10] L   Indica se o campo é alteravel
         NIL                             , ;     // [11] C   Pasta do campo
         NIL                             , ;     // [12] C   Agrupamento do campo
         {"1=Sim","2=Nao"}               , ;     // [13] A   Lista de valores permitido do campo (Combo)
         2                               , ;     // [14] N   Tamanho maximo da maior opção do combo
         NIL                             , ;     // [15] C   Inicializador de Browse
         .F.                             , ;     // [16] L   Indica se o campo é virtual
         NIL                             , ;     // [17] C   Picture Variavel
         NIL                             )       // [18] L   Indica pulo de linha após o campo 
  
  
 _oStruZ39:RemoveField('Z39_DESC')
  
 _oView := FWFormView():New()
 _oView:SetModel(_oModel)
 
 _oView:AddField( "VIEW_MASTER" , _oStruZ38	, "Z38MASTER" )
 _oView:AddGrid(  "VIEW_DETAIL1", _oStruZ39	, "Z39DETAIL" )
 _oView:AddGrid(  "VIEW_DETAIL2", _oStruZ40	, "Z40DETAIL" )
 
 _oView:CreateHorizontalBox( 'BOX0101' , 30 )
 _oView:CreateHorizontalBox( 'BOX0102' , 35 )
 _oView:CreateHorizontalBox( 'BOX0103' , 35 )
 
 _oView:SetOwnerView( "VIEW_MASTER"  , "BOX0101" )
 _oView:SetOwnerView( "VIEW_DETAIL1" , "BOX0102" )
 _oView:SetOwnerView( "VIEW_DETAIL2" , "BOX0103" )
 
 _oView:EnableTitleView('VIEW_DETAIL1', 'Produtos' )  
 _oView:EnableTitleView('VIEW_DETAIL2', 'Coordenador' )  
      
 //Força o fechamento da janela na confirmação
 _oView:SetCloseOnOk({||.T.})
 
Return _oView

/*
===============================================================================================================================
Programa----------: AOMS153H
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Pos Validação
===============================================================================================================================
*/ 
User Function AOMS153H(_oModel As Object) As Logical
   Local lRet := .T. As Logical
   Local _cFilial := xFilial("Z38") As Char
   Local _cCod := _oModel:GetValue("Z38MASTER","Z38_COD") As Char
   Local _cPeriodo := _oModel:GetValue("Z38MASTER","Z38_PERIOD")  As Char
   Local nOper := _oModel:GetOperation() As Numeric
   Local nRecno := 0 As Numeric
   
   If nOper == 3 //Inclusao
      DBSelectArea("Z38")
      DBSetOrder(1)
      If DBSeek(_cFilial+_cCod+_cPeriodo)
         lRet := .F.
         U_ITMsg("Já existe um registro nesse cadastro com a mesma chave digitada Codigo: "+_cCod+" Periodo: "+_cPeriodo,"Atenção","Prencha pelo menos um desses campos com valores difrentes dos citados.",3 , , , .T.)
      Else
         lRet := .T.
      EndIf
   ElseIf nOper == 5 //Exclusão
      lRet := .T.
      DBSelectArea("Z39")
      DBSetOrder(1)
      If DBSeek(_cFilial+_cCod+_cPeriodo)
         lRet := .F.
         U_ITMsg("Existem registros relacionados a esse codigo: "+_cCod+" no cadastro de Premissa Vs Produtos.","Atenção","Antes da exclusão dessa Premissa exclua os registros relacionados no Cadastro de Premissa Vs Produtos.",3 , , , .T.)
      EndIf

      If lRet
         DBSelectArea("Z40")
         DBSetOrder(1)
         If DBSeek(_cFilial+_cCod+_cPeriodo)
            lRet := .F.
            U_ITMsg("Existem registros relacionados a esse codigo: "+_cCod+" no cadastro de Premissa Vs Coordenador.","Atenção","Antes da exclusão dessa Premissa exclua os registros relacionados no Cadastro de Premissa Vs Coordenador.",3 , , , .T.)
         EndIf
      EndIf
   Else
      nRecno := Z38->(Recno()) 
      DBSelectArea("Z38")
      DBSetOrder(1)
      If DBSeek(_cFilial+_cCod+_cPeriodo)
         While _cFilial+_cCod+_cPeriodo == Z38->(Z38_FILIAL+Z38_COD+Z38_PERIOD) .And. Z38->(!Eof())
            If Z38->(Recno()) <> nRecno
               lRet := .F.
               U_ITMsg("Já existe um registro nesse cadastro com a mesma chave digitada Codigo: "+_cCod+" Periodo: "+_cPeriodo,"Atenção","Prencha pelo menos um desses campos com valores difrentes dos citados.",3 , , , .T.)
               Exit
            EndIf
            Z38->(DBSkip())
         EndDo
         lRet := .T.
      Else
         lRet := .T.
      EndIf
   EndIf
   
Return lRet

/*
===============================================================================================================================
Programa----------: AOMS153G
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Pos Validação
===============================================================================================================================
*/ 
User Function AOMS153G(_cFilial As Char, _cCod As Char) As Char
   Local _cRetorno := "" As Character
   Local _aAreaZ38 := {} As Array

   _aAreaZ38 := GetArea("Z38")

   DBSelectArea("Z38")
   DBSetOrder(1)
   DBSeek(_cFilial+_cCod)
   _cRetorno := Z38->Z38_DESC
   
   FWRestArea(_aAreaZ38)

Return _cRetorno

/*
===============================================================================================================================
Programa----------: AOMS153I
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Validação do campo periodo
===============================================================================================================================
*/ 
User Function AOMS153I() As Logical
   Local lRet := .T. As Logical
   Local _cPeriodo := M->Z38_PERIOD As Char
   
   If Len(AllTrim(_cPeriodo)) < 6
      U_ITMsg("Contuedo inválido preenchido!","Atenção","Preencha com Ano e Mês (AAAA/MM) no Campo.",3 , , , .T.) 
      lRet := .F.
   ElseIf Subs(_cPeriodo,5,2) > "12"
      lRet := .F.
      U_ITMsg("Mês digitado inválido!","Atenção","",3 , , , .T.)
   Else
      lRet := .T.
   EndIf

Return lRet


/*
===============================================================================================================================
Programa----------: AOMS153J
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Inicializa o campo Z38_COD
===============================================================================================================================
*/ 
User Function AOMS153J() As Char
 Local _cCod := Z38->Z38_COD As Char
   
   If ALTERA
      __cCod := Z38->Z38_COD
      __cPeriod := Z38->Z38_PERIOD
   Else
      __cCod := ""
      __cPeriod := ""
      If INCLUI
         _cCod := Space(Len(Z38->Z38_COD))
      EndIf
   EndIf
   
Return _cCod

/*
===============================================================================================================================
Programa----------: AOMS153K
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Gravaçao dos registros relacionados
===============================================================================================================================
*/ 
User Function AOMS153K(_oModel As Object) As Logical
 Local _cFilial := xFilial("Z38") As Char
 Local _cCod := _oModel:GetValue("Z38MASTER","Z38_COD")  As Char
 Local _cPeriodo := _oModel:GetValue("Z38MASTER","Z38_PERIOD")  As Char
 Local aZ39 := {} As Array
 Local aZ40 := {} As Array
 Local i  := 0 As Numeric
 Local _nOperation := _oModel:GetOperation() As Numeric
 Local lContinua := .F. As Logical
 
 Begin Transaction

 If _nOperation = 3 .And. !Empty(AllTrim(__cCod)) .And. !Empty(AllTrim(__cPeriod))

   FWFormCommit( _oModel )

   DBSelectArea("Z39")
   DBSetOrder(1)
   If DBSeek( _cFilial + __cCod + __cPeriod)
      lContinua := .T.
   EndIf

   DBSelectArea("Z40")
   DBSetOrder(1)
   If DBSeek( _cFilial + __cCod + __cPeriod)
      lContinua := .T.
   EndIf

   If lContinua .And. U_ITMsg("Deseja copiar tb os registros relacionados de Premissa Vs Produtos e Premissa Vs Coordenador?",'Atenção!',,2,2,2)
      DBSelectArea("Z39")
      DBSetOrder(1)
      If DBSeek( _cFilial + __cCod + __cPeriod)
         While _cFilial + __cCod + __cPeriod == Z39->(Z39_FILIAL+Z39_COD+Z39_PERIOD) .And. Z39->(!Eof())
            aAdd(aZ39,{Z39->Z39_PRODUT,Z39->Z39_TIPO,Z39->Z39_UM,Z39->Z39_FATOR,Z39->Z39_TPCONV})         
            Z39->(DBSkip())
         EndDo
      EndIf

      DBSelectArea("Z40")
      DBSetOrder(1)
      If DBSeek( _cFilial + __cCod + __cPeriod)
         While _cFilial + __cCod + __cPeriod == Z40->(Z40_FILIAL+Z40_COD+Z40_PERIOD) .And. Z40->(!Eof())
            aAdd(aZ40,{Z40->Z40_COORD,Z40->Z40_ALVO,Z40->Z40_ATING})         
            Z40->(DBSkip())
         EndDo
      EndIf

      DBSelectArea("Z39")
      For i := 1 To Len(aZ39)
         Z39->(RecLock("Z39",.T.))
         Z39->Z39_FILIAL := _cFilial
         Z39->Z39_COD    := _cCod
         Z39->Z39_PERIOD := _cPeriodo
         Z39->Z39_PRODUT := aZ39[i][1]
         Z39->Z39_TIPO   := aZ39[i][2]
         Z39->Z39_UM     := aZ39[i][3]
         Z39->Z39_FATOR  := aZ39[i][4]
         Z39->Z39_TPCONV := aZ39[i][5]
         Z39->(MSUnLock())
      Next

      DBSelectArea("Z40")
      
      For i := 1 To Len(aZ40)
         Z40->(RecLock("Z40",.T.))
         Z40->Z40_FILIAL := _cFilial
         Z40->Z40_COD    := _cCod
         Z40->Z40_PERIOD := _cPeriodo
         Z40->Z40_COORD := aZ40[i][1]
         Z40->Z40_ALVO  := aZ40[i][2]
         //Z40->Z40_ATING := aZ40[i][3]
         Z40->(MSUnLock())
      Next
   EndIf
 Else

   FWFormCommit( _oModel )

 EndIf

 End Transaction

Return .T.

