#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'

/*
===============================================================================================================================
Programa--------: AOMS028
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Programação comercial de entrega dos pedidos de venda para a logística
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS028()

Local _xValid		:= U_ITACSUSR( 'ZZL_PRGLOG' )
Local _cUsrMas		:= U_ITGETMV(  'IT_USRFLOG' , '' )
Local _cCodUsr		:= RetCodUsr()

Private _oBrowse	:= Nil
Private _lValPal	:= .T.
Private bFullName   := {|x| UsrFullName(x) }

//Grava log de utilização
u_itlogacs()

// Validacao para verificar se o Usuario tem acesso à rotina de manutenção de TES
If ValType(_xValid) == 'C' .And. !Empty(_xValid) .And. _xValid $ ('12')

	U_ITUNQSX2( 'ZF7' , 'ZF7_FILIAL+ZF7_CODIGO'						)
	U_ITUNQSX2( 'ZF8' , 'ZF8_FILIAL+ZF8_CODPRG+ZF8_ITEM'			)
	U_ITUNQSX2( 'ZF9' , 'ZF9_FILIAL+ZF9_CODPRG+ZF9_ITNPED+ZF9_ITEM'	)
	
	_oBrowse := FWMBrowse():New()
	
	_oBrowse:SetAlias('ZF7')
	_oBrowse:SetDescription( 'Programações de entrega' )
	
	_oBrowse:AddLegend( "ZF7_STATUS == '1'" , 'GREEN'	, 'Programação pendente'		)
	_oBrowse:AddLegend( "ZF7_STATUS == '2'" , 'BLUE'	, 'Programação aprovada'		)
	_oBrowse:AddLegend( "ZF7_STATUS == '3'" , 'ORANGE'	, 'Programação devolvida'		)
	_oBrowse:AddLegend( "ZF7_STATUS == '4'" , 'YELLOW'	, 'Programação em atendimento'	)
	_oBrowse:AddLegend( "ZF7_STATUS == '5'" , 'RED'		, 'Programação concluída'		)
	_oBrowse:AddLegend( "ZF7_STATUS == '6'" , 'BLACK'	, 'Programação cancelada'		)
	
	_oBrowse:SetFilter( 'ZF7_FILIAL' , xFilial('ZF7') , xFilial('ZF7') )
	
	If ValType( _xValid ) == 'C' .And. _xValid == '2' .And. !( _cCodUsr $ _cUsrMas )
		_oBrowse:SetFilterDefault( 'ZF7_USRLOG == "'+ RetCodUsr() +'"' )
	EndIf
	
	_oBrowse:Activate()

Else
	
	U_ITMsg( 'Usuário sem acesso à rotina de manutenção das programações de entrega da Logística!' , 'Atenção!' , ,1 )

EndIf

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração das opções do menu principal da rotina
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function MenuDef()

Local _aRotina	:= {}

ADD OPTION _aRotina Title 'Visualizar' 	Action 'VIEWDEF.AOMS028'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'		Action 'VIEWDEF.AOMS028'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'		Action 'VIEWDEF.AOMS028'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'		Action 'VIEWDEF.AOMS028'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Aprovar'		Action 'U_AOMS028A(1)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Cancelar'	Action 'U_AOMS028A(3)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Remover'		Action 'U_AOMS028A(6)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Devolver'	Action 'U_AOMS028A(2)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Atender'		Action 'U_AOMS028A(4)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Notificar'	Action 'U_AOMS028A(5)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Transferir'	Action 'U_AOMS028A(7)'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Histórico'	Action 'U_AOMS028C()'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Buscar'		Action 'U_AOMS028B()'		OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Relatório'	Action 'U_AOMS028R'			OPERATION 2 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração do modelo de dados para as telas de manutenção da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ModelDef()

Local _oStrZF7	:= FWFormStruct( 1 , 'ZF7' )
Local _oStrZF8	:= FWFormStruct( 1 , 'ZF8' , {|_cCampo| AOMS028CPO( _cCampo , 3 ) } )
Local _oStrZF9	:= FWFormStruct( 1 , 'ZF9' , {|_cCampo| AOMS028CPO( _cCampo , 4 ) } )
Local _oModel	:= Nil
Local _aGatAux	:= {}

_aGatAux := FwStruTrigger( 'ZF7_USRLOG'	, 'ZF7_NOMLOG'	, 'AllTrim(UsrFullName(M->ZF7_USRLOG))'								, .F.	)
_oStrZF7:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_FILPED'	, 'ZF8_CODCLI'	, 'SC5->C5_CLIENTE'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_FILPED'	, 'ZF8_LOJCLI'	, 'SC5->C5_LOJACLI'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NUMPED'	, 'ZF8_CODCLI'	, 'SC5->C5_CLIENTE'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NUMPED'	, 'ZF8_LOJCLI'	, 'SC5->C5_LOJACLI'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_CODCLI'	, 'ZF8_NOMCLI'	, 'U_AOMS028N( 1 , M->ZF8_FILPED , M->ZF8_NUMPED )'					, .F.	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_LOJCLI'	, 'ZF8_NOMCLI'	, 'U_AOMS028N( 1 , M->ZF8_FILPED , M->ZF8_NUMPED )'					, .F.	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF7_CODSUP'	, 'ZF7_NOMSUP'	, 'SA3->A3_NOME'	, .T. , 'SA3' , 1 , 'xFilial("SA3") + M->ZF7_CODSUP'	)
_oStrZF7:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_CODVEN'	, 'SC5->C5_VEND1'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_CODVEN'	, 'ZF8_NOMVEN'	, 'SA3->A3_NOME'	, .T. , 'SA3' , 1 , 'xFilial("SA3") + M->ZF8_CODVEN'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_PESO'	, 'SC5->C5_I_PESBR'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_VALOR'	, 'Round( U_ITVALPED( "V" , M->ZF8_FILPED , M->ZF8_NUMPED ) , 2 )'	, .F.	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_DTENTR'	, 'SC5->C5_I_DTENT'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_CODMUN'	, 'SC5->C5_I_CMUN'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_MUN'		, 'SC5->C5_I_MUN'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_UF'		, 'SC5->C5_I_EST'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZF8_NOMCLI'	, 'ZF8_OBSPED'	, 'SC5->C5_MENNOTA'	, .T. , 'SC5' , 1 , 'M->( ZF8_FILPED + ZF8_NUMPED )'	)
_oStrZF8:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger('ZF9_PEDIDO'	,'ZF9_CODCLI','U_AOMS0289( 1 , xFilial("SC5") , M->ZF9_PEDIDO )', .F.)
_oStrZF9:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger('ZF9_PEDIDO'	,'ZF9_LOJCLI','U_AOMS0289( 2 , xFilial("SC5") , M->ZF9_PEDIDO )', .F.)
_oStrZF9:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger('ZF9_CODCLI'	,'ZF9_NOMCLI','U_AOMS028N( 2 , xFilial("SC5") , M->ZF9_PEDIDO )', .F.	)
_oStrZF9:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger('ZF9_LOJCLI'	,'ZF9_NOMCLI','U_AOMS028N( 2 , xFilial("SC5") , M->ZF9_PEDIDO )', .F.	)
_oStrZF9:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oModel := MPFormModel():New( 'AOMS028M' ,, {|| AOMS028GRV() } )

_oModel:SetDescription( 'Programação de Entregas - Comercial' )

_oModel:AddFields(	"ZF7MASTER" , /*cOwner*/  , _oStrZF7 )
_oModel:AddGrid(	"ZF8DETAIL" , "ZF7MASTER" , _oStrZF8 )
_oModel:AddGrid(	"ZF9DETAIL" , "ZF8DETAIL" , _oStrZF9 )

_oModel:SetRelation( "ZF8DETAIL" , {	{ "ZF8_FILIAL"	, 'xFilial("ZF8")'	} ,;
										{ "ZF8_CODPRG"	, "ZF7_CODIGO"		} }, ZF8->( IndexKey( 1 ) ) )

_oModel:SetRelation( "ZF9DETAIL" , {	{ "ZF9_FILIAL"	, 'xFilial("ZF9")'	} ,;
										{ "ZF9_CODPRG"	, "ZF7_CODIGO"		} ,;
										{ "ZF9_ITNPED"	, "ZF8_ITEM"		} }, ZF9->( IndexKey( 1 ) ) )

_oModel:GetModel( 'ZF8DETAIL' ):SetUniqueLine( { 'ZF8_FILPED' , 'ZF8_NUMPED' } )
_oModel:GetModel( 'ZF9DETAIL' ):SetUniqueLine( { 'ZF9_PEDIDO' } )

_oModel:GetModel( "ZF7MASTER" ):SetDescription( "Programação"				)
_oModel:GetModel( "ZF8DETAIL" ):SetDescription( "Pedidos de Vendas"			)
_oModel:GetModel( "ZF9DETAIL" ):SetDescription( "Pedidos de Transferência"	)

_oModel:GetModel( "ZF9DETAIL" ):SetOptional( .T. )

_oModel:SetPrimaryKey( { 'ZF7_FILIAL' , 'ZF7_CODIGO' } )

_oModel:SetVldActivate( {|oModel| AOMS028ACT( oModel ) } )

Return(_oModel)

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração do modelo de dados para as telas de manutenção da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ViewDef()

Local _oModel  	:= FWLoadModel( 'AOMS028' )
Local _oStrZF7	:= FWFormStruct( 2 , 'ZF7' , {|_cCampo| AOMS028CPO( _cCampo , 1 ) } )
Local _oStrDET	:= FWFormStruct( 2 , 'ZF7' , {|_cCampo| AOMS028CPO( _cCampo , 2 ) } )
Local _oStrZF8	:= FWFormStruct( 2 , 'ZF8' , {|_cCampo| AOMS028CPO( _cCampo , 3 ) } )
Local _oStrZF9	:= FWFormStruct( 2 , 'ZF9' , {|_cCampo| AOMS028CPO( _cCampo , 4 ) } )
Local _oView	:= Nil

_oView := FWFormView():New()

_oView:SetModel( _oModel )

_oView:AddField( "VIEW_CAB"	, _oStrZF7	, "ZF7MASTER" )
_oView:AddGrid(  "VIEW_PED"	, _oStrZF8	, "ZF8DETAIL" )
_oView:AddGrid(  "VIEW_TRS"	, _oStrZF9	, "ZF9DETAIL" )
_oView:AddField( "VIEW_DET"	, _oStrDET	, "ZF7MASTER" )

_oView:CreateHorizontalBox( 'BOX01' , 025 )
_oView:CreateHorizontalBox( 'BOX02' , 040 )
_oView:CreateHorizontalBox( 'BOX03' , 035 )

_oView:CreateVerticalBox( 'BOX0301' , 050 , 'BOX03' )
_oView:CreateVerticalBox( 'BOX0302' , 050 , 'BOX03' )

_oView:SetOwnerView( "VIEW_CAB" , "BOX01"	)
_oView:SetOwnerView( "VIEW_PED" , "BOX02"	)
_oView:SetOwnerView( "VIEW_TRS" , "BOX0301"	)
_oView:SetOwnerView( "VIEW_DET" , "BOX0302"	)

_oView:AddIncrementField( 'VIEW_PED' , 'ZF8_ITEM' )
_oView:AddIncrementField( 'VIEW_TRS' , 'ZF9_ITEM' )

_oView:EnableTitleView( 'VIEW_CAB' , 'Programação'				)
_oView:EnableTitleView( 'VIEW_PED' , 'Pedidos de Vendas'		)
_oView:EnableTitleView( 'VIEW_TRS' , 'Pedidos de Transferência'	)
_oView:EnableTitleView( 'VIEW_DET' , 'Informações adicionais'	)

Return(_oView)

/*
===============================================================================================================================
Programa--------: AOMS028M
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração da estrutura de pontos de entrada do MVC
Parametros------: Nenhum
Retorno---------: _xRet - Lógico/Conteúdo de acordo com o ponto.
===============================================================================================================================
*/
User Function AOMS028M()

Local _aArea	:= FWGetArea()
Local _aParam	:= ParamIXB
Local _oModel	:= FWModelActive()
Local _oObj		:= Nil
Local _oView	:= FWViewActive()
Local _aParAux	:= {}
Local _xRet		:= .T.
Local _cIdPonto	:= ''
Local _cIdModel	:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _lIsGrid	:= .F.
Local _lPedPal	:= .F.
Local _nLinha	:= 0
Local _nQtdLin	:= 0
Local _nI		:= 0
Local _dDtEntr	:= SToD('')

If _aParam <> NIL

	_oObj		:= _aParam[1]
	_cIdPonto	:= _aParam[2]
	_cIdModel	:= _aParam[3]
	_lIsGrid	:= ( ( Len( _aParam ) > 3 ) .And. ( ValType(_aParam[4]) == 'N' ) )
	
	If _lIsGrid
		_nQtdLin	:= _oObj:GetQtdLine()
		_nLinha		:= _oObj:nLine
	EndIf
	
	If _cIdPonto == 'FORMLINEPOS' .And. _cIdModel == 'ZF8DETAIL' .And. _lValPal
		
		_lValPal := .F.
		_aParAux := { _oObj:GetValue( 'ZF8_FILPED' ) , _oObj:GetValue( 'ZF8_NUMPED' ) }
		
		DBSelectArea('SC5')
		SC5->( DBSetOrder(1) )
		If SC5->( DBSeek( _aParAux[01] + _aParAux[02] ) )
			
			If !Empty( SC5->C5_I_NPALE )
				
				_cFilPal := SC5->C5_FILIAL
				_cPedPal := SC5->C5_I_NPALE
				
				DBSelectArea('SC5')
				SC5->( DBSetOrder(1) )
				If SC5->( DBSeek( _cFilPal + _cPedPal ) )
					
					_lPedPal := .F.
					_dDtEntr := SC5->C5_I_DTENT
					
					For _nI := 1 To _nQtdLin
						
						If _nI <> _nLinha
						
							_oObj:GoLine(_nI)
							
							If !( _oObj:IsDeleted() )
								
								If _oObj:GetValue( 'ZF8_FILPED' ) == _cFilPal .And. _oObj:GetValue( 'ZF8_NUMPED' ) == _cPedPal
									
									_lPedPal := .T.
									
								EndIf
								
							EndIf
						
						EndIf
						
					Next _nI
					
					If !_lPedPal
						
						_cQuery := " SELECT "
						_cQuery += "     ZF8.ZF8_FILIAL AS FILPRG ,"
						_cQuery += "     ZF8.ZF8_CODPRG AS CODPRG "
						_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8 , "+ RetSqlName('ZF7') +" ZF7 "
						_cQuery += " WHERE "
						_cQuery += "     ZF8.D_E_L_E_T_ = ' ' "
						_cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
						_cQuery += " AND ZF7.ZF7_FILIAL = ZF8.ZF8_FILIAL "
						_cQuery += " AND ZF7.ZF7_CODIGO = ZF8.ZF8_CODPRG "
						_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
						_cQuery += " AND ZF8.ZF8_FILPED = '"+ _cFilPal +"' "
						_cQuery += " AND ZF8.ZF8_NUMPED = '"+ _cPedPal +"' "
						_cQuery += " AND ( ( ZF8.ZF8_FILIAL = '"+ xFilial('ZF8') +"' AND ZF8.ZF8_CODPRG <> '"+ _oModel:GetValue('ZF7MASTER','ZF7_CODIGO') +"' ) OR ( ZF8.ZF8_FILIAL <> '"+ xFilial('ZF8') +"' ) ) "
						
						If Select(_cAlias) > 0
							(_cAlias)->( DBCloseArea() )
						EndIf
						
						DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
						
						DBSelectArea(_cAlias)
						(_cAlias)->( DBGoTop() )
						If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->CODPRG )
							
							_aInfHlp := {}
							//                  |....:....|....:....|....:....|....:....|
							aAdd( _aInfHlp	, {	"O pedido ["+ _aParAux[01] +"-"+ _aParAux[02] +"] está amarrado à um "	,;
												" pedido de Pallet que já está informado "								,;
												" na programação ["+ (_cAlias)->FILPRG +"-"+ (_cAlias)->CODPRG +"]!"	})
							
							aAdd( _aInfHlp	, {	"Verifique os pedidos informados e/ou a "	,;
												" configuração da programação pois não é "	,;
												" permitido informar um pedido sem sua "	,;
												" amarração de Pallet quando existir."		})
							
							U_ITCADHLP( _aInfHlp , "AOMS02817" )
							
							U_ITMsg( 'Para o pedido informado existe uma amarração referente à pedido de "Pallet" e esse pedido já encontra-se em na programação ['+ (_cAlias)->FILPRG +'-'+ (_cAlias)->CODPRG +']!',"Atenção" ,  , 1 )
							
							_xRet := .F.
							
						Else
						
							_nQtdLin++
							
							If _oObj:AddLine() == _nQtdLin
								
								_oObj:GoLine( _nQtdLin )
								_oObj:LoadValue( 'ZF8_FILPED' , _cFilPal )
								_oObj:LoadValue( 'ZF8_NUMPED' , _cPedPal )
								_oObj:LoadValue( 'ZF8_DTENTR' , _dDtEntr )
								_oObj:SetValue(  'ZF8_CODCLI' , AllTrim( Posicione( 'SC5' , 1 , _cFilPal + _cPedPal , 'SC5->C5_CLIENTE' ) ) )
								_oObj:SetValue(  'ZF8_LOJCLI' , SC5->C5_LOJACLI )
								
								U_ITMsg( 'Para o pedido informado existe uma amarração referente à pedido de "Pallet" e o pedido de amarração foi incluído automaticamente na previsão!',"Atenção" , ,1 )
								
								_oView:Refresh()
								
							EndIf
						
						EndIf
						
						(_cAlias)->( DBCloseArea() )
						
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf
		
		_lValPal := .T.
		
	EndIf
	
EndIf

FWRestArea(_aArea)

Return( _xRet )

/*
===============================================================================================================================
Programa--------: AOMS028CPO
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração dos campos para exibição nas telas de manutenção da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028CPO( _cCampo , _nOpc )

Local _lRet	:= .F.

Do Case
	
	Case _nOpc == 1
		_lRet := Upper( AllTrim( _cCampo ) ) $ 'ZF7_FILIAL+ZF7_CODIGO+ZF7_DATA+ZF7_HORA+ZF7_STATUS+ZF7_APROVA+ZF7_TIPCAR+ZF7_USRLOG+ZF7_NOMLOG'
		
	Case _nOpc == 2
		_lRet := Upper( AllTrim( _cCampo ) ) $ 'ZF7_OBS+ZF7_PRAZO+ZF7_NOMVEN+ZF7_CODSUP+ZF7_NOMSUP'
		
	Case _nOpc == 3
		_lRet := Upper( AllTrim( _cCampo ) ) <> 'ZF8_CODPRG'
	
	Case _nOpc == 4
		_lRet := !( Upper( AllTrim( _cCampo ) ) $ 'ZF9_CODPRG+ZF9_ITNPED' )
	
EndCase

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028GRV
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Configuração dos campos para exibição nas telas de manutenção da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028GRV( _lValid )

Local _aInfHlp	:= {}
Local _lRet		:= .T.
Local _oModel	:= FWModelActive()
Local _oModZF8	:= _oModel:GetModel( 'ZF8DETAIL' )
Local _oModZF9	:= _oModel:GetModel( 'ZF9DETAIL' )
Local _cNewCod	:= ''
Local _cCodSup	:= _oModel:GetValue( 'ZF7MASTER' , 'ZF7_CODSUP' )
Local _cFilPed	:= ''
Local _cNumPed	:= ''
Local _cFilPrg	:= ''
Local _nAction	:= _oModel:GetOperation()
Local _nTotLin	:= _oModZF8:Length()
Local _nTotAux	:= _oModZF9:Length()
Local _nI		:= 0
Local _nX		:= 0
Local _oDlg		:= Nil
Local _oGet1	:= Nil
Local _cGet1	:= Space(200)

Default _lValid	:= .F.

For _nI := 1 To _nTotLin

	_oModZF8:GoLine( _nI )
	
	_cFilPed := _oModZF8:GetValue( 'ZF8_FILPED' )
	_cNumPed := _oModZF8:GetValue( 'ZF8_NUMPED' )
	
	If _nI == 1
		_cFilPrg := _cFilPed
	EndIf
	
	If _oModZF8:IsDeleted()
		Loop
	EndIf
	
	If _cFilPrg <> _cFilPed
	
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"Existem pedidos em diferentes Filiais na "	,;
							" na programação atual!"					})
		
		aAdd( _aInfHlp	, {	"Verifique os pedidos informados e/ou a "	,;
							" configuração da programação para que "	,;
							" todos os pedidos tenham a mesma Filial!"	})
		
		U_ITCADHLP( _aInfHlp , "AOMS02812" )
		
		_lRet := .F.
		
		Exit
	
	EndIf
	
	For _nX := 1 To _nTotAux
	
		_oModZF9:GoLine( _nX )
		
		If _oModZF9:IsDeleted()
			Loop
		EndIf
		
		If xFilial('ZF9') == _cFilPed .And. _oModZF9:GetValue( 'ZF9_PEDIDO' ) == _cNumPed
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"O pedido informado no item "+ StrZero(_nI,3) +" está"	,;
								" informado também no espaço reservado aos"				,;
								" pedidos de transferência!"							})
			
			aAdd( _aInfHlp	, {	"Verifique o pedido informado e/ou a"		,;
								" configuração da programação. "			})
			
			U_ITCADHLP( _aInfHlp , "AOMS02809" )
			
			_lRet := .F.
			
			Exit
			
		EndIf
		
	Next _nX
	
	If !_lRet
		Exit
	EndIf
	
	DBSelectArea('SC5')
	SC5->( DBSetOrder(1) )
	If SC5->( DBSeek( _cFilPed + _cNumPed ) )
	
		If SC5->C5_I_PEDPA <> 'S' .And. Posicione('SA3',1,xFilial('SA3')+SC5->C5_VEND1,'A3_SUPER') <> _cCodSup
		
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"O pedido informado no item "+ StrZero(_nI,3) +" está"	,;
								" amarrado à um Coordenador diferente do"				,;
								" configurado na programação!"							})
			
			aAdd( _aInfHlp	, {	"Verifique o pedido informado e/ou a"					,;
								" configuração da programação."							})
			
			U_ITCADHLP( _aInfHlp , "AOMS02807" )
			
			_lRet := .F.
			
			Exit
		
		EndIf
	
	Else
	
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"O pedido informado no item ["+ StrZero(_nI,3) +"] não foi"	,;
							" encontrado no sistema!"									})
		
		aAdd( _aInfHlp	, {	"Verifique os dados e informe um pedido"					,;
							" válido para prosseguir."									})
		
		U_ITCADHLP( _aInfHlp , "AOMS02808" )
		
		_lRet := .F.
		
		Exit
		
	EndIf

Next _nI

If _lValid
	Return( _lRet )
EndIf

If _lRet .And. _nAction == MODEL_OPERATION_INSERT

	_cNewCod := AOMS028NCD()
	
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_CODIGO'	, _cNewCod		)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_USRPRG'	, RetCodUsr()	)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_DATA'		, Date()		)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_HORA'		, Time()		)
	
	U_AOMS028H( { _cNewCod , '1' , 'Inclusão da programação de entregas! [AOMS028]' } )

EndIf

If _lRet .And. _nAction == MODEL_OPERATION_UPDATE .And. _oModel:GetValue( 'ZF7MASTER' , 'ZF7_STATUS' ) == '3'
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_STATUS' , '1' )
EndIf

If _lRet .And. _nAction == MODEL_OPERATION_DELETE
	
	DEFINE MSDIALOG _oDlg TITLE "Justificar:" FROM 178,181 TO 240,697 PIXEL
	
	@ 005,003 Get _oGet1 Var _cGet1 Size 212,020 COLOR CLR_BLACK MULTILINE PIXEL OF _oDlg
	
	DEFINE SBUTTON FROM 015,227 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) , U_ITMsg('É obrigatório justificar a exclusão!','Atenção!',,1) , _oDlg:End() ) ) OF _oDlg
	
	ACTIVATE MSDIALOG _oDlg CENTERED
	
	U_AOMS028H( { ZF7->ZF7_CODIGO , '5' , AllTrim( _cGet1 ) } )
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028N
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Inicializador padrão para o campo nome do Cliente do pedido de Venda
Parametros------: _cFilPed - Filial do pedido de venda do cliente
----------------: _cNumPed - Número do pedido de venda do cliente
					_nOpc - tipo de retorno - 1 razao social
												 2 nome reduzido
Retorno---------: _cRet    - Nome do cliente
===============================================================================================================================
*/

User Function AOMS028N( _nOpc , _cFilPed , _cNumPed )

Local _cRet	:= ''

If !Empty( _cFilPed ) .And. !Empty( _cNumPed )

	DBSelectArea('SC5')
	SC5->( DBSetOrder(1) )
	If SC5->( DBSeek( _cFilPed + _cNumPed ) )
		
		If SC5->C5_TIPO == 'B' .Or. SC5->C5_TIPO == 'D' //// NAO ESTA SAINDO O NOME NA CONFIGURACAO 2 /////
		
			_cRet := AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2') + SC5->( C5_CLIENTE + C5_LOJACLI ) , IIf( _nOpc == 1 , 'A2_NOME' , 'A2_NREDUZ' ) ) )
		
		Else
		
			_cRet := AllTrim( Posicione( 'SA1' , 1 , xFilial('SA1') + SC5->( C5_CLIENTE + C5_LOJACLI ) , IIf( _nOpc == 1 , 'A1_NOME' , 'A1_NREDUZ' ) ) )
		
		EndIf
		
	EndIf

EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa--------: AOMS0289
Autor-----------: Josué Danich Prestes
Data da Criacao-: 22/09/2016
Descrição-------: Inicializador padrão para o campo nome do Cliente do pedido de Venda
Parametros------: _cFilPed - Filial do pedido de venda do cliente
----------------: _cNumPed - Número do pedido de venda do cliente
					_nOpc - tipo de retorno - 1 cliente
												 2 loja
Retorno---------: _cRet    - Nome do cliente
===============================================================================================================================
*/

User Function AOMS0289( _nOpc , _cFilPed , _cNumPed )

Local _cRet	:= ''

If !Empty( _cFilPed ) .And. !Empty( _cNumPed )

	DBSelectArea('SC5')
	SC5->( DBSetOrder(1) )
	If SC5->( DBSeek( _cFilPed + _cNumPed ) )
		
			_cRet :=  IIf( _nOpc == 1 , SC5->C5_CLIENTE , SC5->C5_LOJACLI) 
		
	EndIf

EndIf

Return( _cRet )



/*
===============================================================================================================================
Programa--------: AOMS028V
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Retorna o nome do vendedor de acordo com a chave de pedido de venda informada.
Parametros------: _cFilPed - Filial do Pedido de Venda
----------------: _cNumPed - Número do Pedido de Venda
Retorno---------: _cRet    - Nome do vendedor responsável pelo pedido
===============================================================================================================================
*/

User Function AOMS028V( _cFilPed , _cNumPed )

Local _cRet		:= ''
Local _cCodVen	:= Posicione( 'SC5' , 1 , _cFilPed + _cNumPed , 'C5_VEND1' )

If !Empty( _cCodVen )
	
	_cRet := AllTrim( Posicione( 'SA3' , 1 , xFilial('SA3') + _cCodVen , 'A3_NOME' ) )
	
EndIf

Return( _cRet )


/*
===============================================================================================================================
Programa--------: AOMS028A
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Realiza a aprovação da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028A( _nOpc )

Local _xValAcs	:= U_ITACSUSR( 'ZZL_PRGLOG' )
Local _aArea	:= FWGetArea()
Local _aParBox	:= {}
Local _aParRet	:= {}
Local _aHeader	:= {}
Local _aDados	:= {}
Local _aPedDev	:= {}
Local _aPedAtn	:= {}
Local _aZF9Dev	:= {}
Local _oDlg		:= Nil
Local _oGet1	:= Nil
Local _cGet1	:= Space(200)
Local _cNewCod	:= ''
Local _cNumNota	:= ''
Local _cQuery	:= ''
Local _cAlias	:= ''
Local _nI		:= 0
Local _nX		:= 0
Local _nCntAtn	:= 0
Local _nCntTot	:= 0
Local _nCntDev	:= 0

If ValType( _xValAcs ) <> 'C' .Or. !( _xValAcs $ '1/2' )
	
	U_ITMsg( 'Usuário sem acesso à processar as rotinas de Programações de Entregas!' , 'Atenção!' , ,1 )
	Return
	
EndIf

If _nOpc == 1
	
	If _xValAcs <> '1'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Comercial" podem realizar a aprovação de programações!' , ,1 )
		Return
	EndIf
	
	If ZF7->ZF7_STATUS == '1'
	
		FWExecView( 'Aprovação da programação de entrega' , 'AOMS028' , 4 , _oDlg , {|| .T. } , {|| AOMS028APR() } )
		
		If ZF7->ZF7_STATUS == '2'
			LjMsgRun( 'Enviando WF de comunicação da aprovação...' , 'Aguarde!' , {|| AOMS028WFC('2') } )
		EndIf
		
	Else
		U_ITMsg( 'Somente programações "Pendentes" podem ser aprovadas!' , 'Atenção!' , ,1 )
	EndIf
	
ElseIf _nOpc == 2
    
   	If _xValAcs <> '2'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Logística" podem realizar a devolução de programações!' , 'Atenção!' , ,1 )
		Return
	EndIf
    
    Begin Transaction
    
    If ZF7->ZF7_USRLOG == RetCodUsr()
    
		If ZF7->ZF7_STATUS == '2' .Or. ZF7->ZF7_STATUS == '4'
		
			If U_ITMsg( 'Confirma a devolução da programação: '+ ZF7->ZF7_CODIGO +' ?' , 'Atenção!',,3,2,2 )
				
				DEFINE MSDIALOG _oDlg TITLE "Justificar:" FROM 178,181 TO 240,697 PIXEL
				
					@ 005,003 Get _oGet1 Var _cGet1 Size 212,020 COLOR CLR_BLACK MULTILINE PIXEL OF _oDlg
					
					DEFINE SBUTTON FROM 015,227 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) , U_ITMsg( 'É obrigatório justificar a devolução!' , 'Atenção!' , ,1 ) , _oDlg:End() ) ) OF _oDlg
				
				ACTIVATE MSDIALOG _oDlg CENTERED
				
				If U_ITMsg( 'Deseja devolver todos os ítens da programação? (Sim para todos, Não para devolver indiviudalmente)' , "Atenção",,3,2,2 ) 
				
				
					// Devolução Total. Tratativa para devolução parcial - quando já existem itens faturados
					DBSelectArea('ZF8')
					ZF8->( DBSetOrder(1) )
					If ZF8->( DBSeek( xFilial('ZF8') + ZF7->ZF7_CODIGO ) )
						
						While ZF8->( !Eof() ) .And. ZF8->( ZF8_FILIAL + ZF8_CODPRG ) == xFilial('ZF8') + ZF7->ZF7_CODIGO
							
							DBSelectArea('SC5')
							SC5->( DBSetOrder(1) )
							If SC5->( DBSeek( ZF8->( ZF8_FILPED + ZF8_NUMPED ) ) )
								
								_cNumNota := ''
								
								DBSelectArea('SC6')
								SC6->( DBSetOrder(1) )
								If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
									
									While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
										
										If !Empty(SC6->C6_NOTA)
											_cNumNota := SC6->C6_NOTA
											Exit
										EndIf
										
									SC6->( DBSkip() )
									EndDo
									
								EndIf
								
								If Empty( _cNumNota )
									aAdd( _aPedDev , ZF8->( Recno() ) )
								Else
									aAdd( _aPedAtn , ZF8->( Recno() ) )
								EndIf
								
							EndIf
							
						ZF8->( DBSkip() )
						EndDo
						
					EndIf
					
					
					// Se não houver pedidos atendidos devolve a programação inteira
					If Empty( _aPedAtn )
					
						RecLock( 'ZF7' , .F. )
						
						ZF7->ZF7_STATUS		:= '3'
						ZF7->ZF7_APROVA		:= RetCodUsr()
						ZF7->ZF7_DATA		:= Date()
						ZF7->ZF7_HORA		:= Time()
						
						ZF7->( MSUnLock() )
						
						U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , AllTrim( _cGet1 ) } )
					
					// Se tiver pedidos atendidos, encerra a programação atual e gera outra somente com os pendentes.
					Else
						
						RecLock( 'ZF7' , .F. )
						
						ZF7->ZF7_STATUS		:= '5'
						ZF7->ZF7_APROVA		:= RetCodUsr()
						ZF7->ZF7_DATA		:= Date()
						ZF7->ZF7_HORA		:= Time()
						
						ZF7->( MSUnLock() )
						
						
						// Grava histórico na origem para manter fácil a localização e atualização das programações
						_cNewCod := AOMS028NCD()
						
						U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , 'Foi feita uma devolução parcial que gerou a programação: '+ _cNewCod } )
						U_AOMS028H( { ZF7->ZF7_CODIGO , '5' , 'Programação encerrada automaticamente.' } )
						
						
						// Duplica a programação e transfere somente os pedidos pendentes
						_aDadZF7 := {	ZF7->ZF7_FILIAL		,;
										_cNewCod			,; //ZF7->ZF7_CODIGO
										ZF7->ZF7_DATA		,;
										ZF7->ZF7_HORA		,;
										'3'					,; //ZF7->ZF7_STATUS - 3 = Devolvido
										ZF7->ZF7_APROVA		,;
										ZF7->ZF7_TIPCAR		,;
										ZF7->ZF7_OBS		,;
										ZF7->ZF7_PRAZO		,;
										ZF7->ZF7_CODSUP		,;
										ZF7->ZF7_USRLOG		,;
										ZF7->ZF7_USRPRG		 }
						
						RecLock( 'ZF7' , .T. )
							
							ZF7->ZF7_FILIAL		:= _aDadZF7[01]
							ZF7->ZF7_CODIGO		:= _aDadZF7[02]
							ZF7->ZF7_DATA		:= _aDadZF7[03]
							ZF7->ZF7_HORA		:= _aDadZF7[04]
							ZF7->ZF7_STATUS		:= _aDadZF7[05]
							ZF7->ZF7_APROVA		:= _aDadZF7[06]
							ZF7->ZF7_TIPCAR		:= _aDadZF7[07]
							ZF7->ZF7_OBS		:= _aDadZF7[08]
							ZF7->ZF7_PRAZO		:= _aDadZF7[09]
							ZF7->ZF7_CODSUP		:= _aDadZF7[10]
							ZF7->ZF7_USRLOG		:= _aDadZF7[11]
							ZF7->ZF7_USRPRG		:= _aDadZF7[12]
							
						ZF7->( MSUnLock() )
						
						U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , AllTrim( _cGet1 ) } )
						
						For _nI := 1 To Len( _aPedDev )
							
							DBSelectArea('ZF8')
							ZF8->( DBGoTo( _aPedDev[_nI] ) )
							
							DBSelectArea('ZF9')
							ZF9->( DBSetOrder(1) )
							If ZF9->( DBSeek( ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM ) ) )
								
								While ZF9->( !Eof() ) .And. ZF9->( ZF9_FILIAL + ZF9_CODPRG + ZF9_ITNPED ) == ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM )
									
									aAdd( _aZF9Dev , ZF9->( Recno() ) )
									
								ZF9->( DBSkip() )
								EndDo
								
							EndIf
							
							For _nX := 1 To Len( _aZF9Dev )
								
								ZF9->( DBGoTo( _aZF9Dev[_nX] ) )
								RecLock( 'ZF9' , .F. )
								ZF9->ZF9_CODPRG := _aDadZF7[02]
								ZF9->( MSUnLock() )
								
							Next _nX
							
							RecLock( 'ZF8' , .F. )
							ZF8->ZF8_CODPRG := _aDadZF7[02]
							ZF8->( MSUnLock() )
							
						Next _nI
						
					EndIf
					
					LjMsgRun( 'Enviando WF de comunicação da devolução...' , 'Aguarde!' , {|| AOMS028WFC( '3' , _cGet1 ) } )
				
				Else
				
					
					// Devolução Individual. Verifica quais pedidos podem ser devolvidos (pendentes)
					DBSelectArea('ZF8')
					ZF8->( DBSetOrder(1) )
					If ZF8->( DBSeek( xFilial('ZF8') + ZF7->ZF7_CODIGO ) )
						
						_nCntAtn := 0
						_nCntTot := 0
						
						While ZF8->( !Eof() ) .And. ZF8->( ZF8_FILIAL + ZF8_CODPRG ) == xFilial('ZF8') + ZF7->ZF7_CODIGO
							
							DBSelectArea('SC5')
							SC5->( DBSetOrder(1) )
							If SC5->( DBSeek( ZF8->( ZF8_FILPED + ZF8_NUMPED ) ) )
								
								_cNumNota := ''
								
								DBSelectArea('SC6')
								SC6->( DBSetOrder(1) )
								If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
									
									While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
										
										If !Empty(SC6->C6_NOTA)
											_cNumNota := SC6->C6_NOTA
											Exit
										EndIf
										
									SC6->( DBSkip() )
									EndDo
									
								EndIf
								
								_nCntTot++
								
								If Empty( _cNumNota )
									aAdd( _aPedDev , { ZF8->( Recno() ) , SC5->( Recno() ) } )
								Else
									_nCntAtn++
								EndIf
								
							EndIf
							
						ZF8->( DBSkip() )
						EndDo
						
						If Empty( _aPedDev )
						
							U_ITMsg( 'Não existem pedidos pendentes na programação atual! Verifique a programação selecionada e tente novamente.' , 'Atenção!' , ,1 )
							
						Else
							
							For _nI := 1 To Len( _aPedDev )
								
								DBSelectArea('SC5')
								SC5->( DBGoTo( _aPedDev[_nI][02] ) )
								
								aAdd( _aPedAtn , { .F. , SC5->C5_FILIAL , SC5->C5_NUM , SC5->C5_CLIENTE , SC5->C5_LOJACLI , SC5->C5_I_NOME , SC5->C5_MENNOTA , _aPedDev[_nI][01] , _nI } )
								
							Next _nI
							
							If U_ITLISTBOX( 'Pedidos pendentes da programação' , {'[  ]','Filial','Número','Cliente','Loja','Nome','Msg. Nota'} , @_aPedAtn , .T. , 2 , 'Verifique e selecione os pedidos que deseja devolver:' )
							
								If !Empty( _aPedAtn )
								
									_nCntDev := 0
								
									For _nI := 1 To Len( _aPedAtn )
										If _aPedAtn[_nI][01]
											_nCntDev++
											DBSelectArea("SC5")
											DBSetOrder(1)
											DBSeek(_aPedAtn[_nI][02] + _aPedAtn[_nI][03])
											
											// Se o pedido principal tiver pedido de pallet, este será automaticamente adicionado na devolução
											If !Empty(SC5->C5_I_NPALE) .And. C5_I_PEDPA <> "S"
												If !_aPedAtn[aScan(_aPedAtn,{|x| x[3] == SC5->C5_I_NPALE })][1]
													_aPedAtn[aScan(_aPedAtn,{|x| x[3] == SC5->C5_I_NPALE })][1] := .T.
													U_ITMsg( 'Para o pedido informado existe uma amarração referente à pedido de "Pallet" e o pedido de amarração foi incluído automaticamente na devolução!' , 'Atenção' , ,1 )
												EndIf
											ElseIf !Empty(SC5->C5_I_NPALE) .And. C5_I_PEDPA == "S"
												If !_aPedAtn[aScan(_aPedAtn,{|x| x[3] == SC5->C5_I_NPALE })][1]
													_aPedAtn[aScan(_aPedAtn,{|x| x[3] == SC5->C5_I_NPALE })][1] := .T.
													U_ITMsg( 'Para o pedido de "Pallet" informado existe uma amarração com pedido principal, e o pedido de amarração foi incluído automaticamente na devolução!' , 'Atenção' , ,1 )
													_nCntDev++
												EndIf
											EndIf
										EndIf
//										IIf( _aPedAtn[_nI][01] , _nCntDev++ , Nil )
									Next _nI
									
									If _nCntDev == 0
										
										U_ITMsg( 'Não foram selecionados pedidos para processar!' , 'Atenção!' , ,1 )
										
									Else
									
										// Verifica se deve encerrar a programação atual.
										If _nCntAtn == 0 .And. _nCntDev == _nCntTot
										
											RecLock( 'ZF7' , .F. )
											
											ZF7->ZF7_STATUS		:= '3'
											ZF7->ZF7_APROVA		:= RetCodUsr()
											ZF7->ZF7_DATA		:= Date()
											ZF7->ZF7_HORA		:= Time()
											
											ZF7->( MSUnLock() )
											
											U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , AllTrim( _cGet1 ) } )
										
										Else
											
											// Grava histórico na origem para manter fácil a localização e atualização das programações
											_cNewCod := AOMS028NCD()
											U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , 'Foi feita uma devolução parcial que gerou a programação: '+ _cNewCod } )
											
											If _nCntAtn > 0 .And. ( _nCntAtn + _nCntDev ) == _nCntTot
											
												RecLock( 'ZF7' , .F. )
												
												ZF7->ZF7_STATUS		:= '5'
												ZF7->ZF7_APROVA		:= RetCodUsr()
												ZF7->ZF7_DATA		:= Date()
												ZF7->ZF7_HORA		:= Time()
												
												ZF7->( MSUnLock() )
												
												U_AOMS028H( { ZF7->ZF7_CODIGO , '5' , 'Programação encerrada automaticamente.' } )
												
											EndIf
											
											// Duplica a programação e transfere somente os pedidos pendentes selecionados
											_aDadZF7 := {	ZF7->ZF7_FILIAL		,;
															_cNewCod			,; //ZF7->ZF7_CODIGO
															ZF7->ZF7_DATA		,;
															ZF7->ZF7_HORA		,;
															'3'					,; //ZF7->ZF7_STATUS - 3 = Devolvido
															ZF7->ZF7_APROVA		,;
															ZF7->ZF7_TIPCAR		,;
															ZF7->ZF7_OBS		,;
															ZF7->ZF7_PRAZO		,;
															ZF7->ZF7_CODSUP		,;
															ZF7->ZF7_USRLOG		,;
															ZF7->ZF7_USRPRG		 }
											
											RecLock( 'ZF7' , .T. )
												
												ZF7->ZF7_FILIAL		:= _aDadZF7[01]
												ZF7->ZF7_CODIGO		:= _aDadZF7[02]
												ZF7->ZF7_DATA		:= _aDadZF7[03]
												ZF7->ZF7_HORA		:= _aDadZF7[04]
												ZF7->ZF7_STATUS		:= _aDadZF7[05]
												ZF7->ZF7_APROVA		:= _aDadZF7[06]
												ZF7->ZF7_TIPCAR		:= _aDadZF7[07]
												ZF7->ZF7_OBS		:= _aDadZF7[08]
												ZF7->ZF7_PRAZO		:= _aDadZF7[09]
												ZF7->ZF7_CODSUP		:= _aDadZF7[10]
												ZF7->ZF7_USRLOG		:= _aDadZF7[11]
												ZF7->ZF7_USRPRG		:= _aDadZF7[12]
												
											ZF7->( MSUnLock() )
											
											U_AOMS028H( { ZF7->ZF7_CODIGO , '3' , AllTrim( _cGet1 ) } )
											
											For _nI := 1 To Len( _aPedAtn )
											
												If _aPedAtn[_nI][01]
													
													DBSelectArea('ZF8')
													ZF8->( DBGoTo( _aPedDev[_aPedAtn[_nI][09]][01]) )
													
													DBSelectArea('ZF9')
													ZF9->( DBSetOrder(1) )
													If ZF9->( DBSeek( ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM ) ) )
														
														While ZF9->( !Eof() ) .And. ZF9->( ZF9_FILIAL + ZF9_CODPRG + ZF9_ITNPED ) == ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM )
															
															aAdd( _aZF9Dev , ZF9->( Recno() ) )
															
														ZF9->( DBSkip() )
														EndDo
														
													EndIf
													
													For _nX := 1 To Len( _aZF9Dev )
														
														ZF9->( DBGoTo( _aZF9Dev[_nX] ) )
														RecLock( 'ZF9' , .F. )
														ZF9->ZF9_CODPRG := _aDadZF7[02]
														ZF9->( MSUnLock() )
														
													Next _nX
													
													RecLock( 'ZF8' , .F. )
													ZF8->ZF8_CODPRG := _aDadZF7[02]
													ZF8->( MSUnLock() )
													
												EndIf
												
											Next _nI
											
										EndIf
										
										LjMsgRun( 'Enviando WF de comunicação da devolução...' , 'Aguarde!' , {|| AOMS028WFC( '3' , _cGet1 ) } )
										
									EndIf
								
								EndIf
								
							Else
								U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' ,, 1 )
							EndIf
							
						EndIf
						
					EndIf
					
				EndIf
				
			EndIf
		
		Else
			U_ITMsg( 'Somente programações "Aprovadas" ou "Em Atendimento" podem ser devolvidas!' , 'Atenção!' , ,1 )
		EndIf
	
	Else
		U_ITMsg( 'Somente programações atribuídas ao seu usuário podem ser devolvidas! Verifique a programação selecionada e tente novamente.' , 'Atenção!' , ,1 )
	EndIf
	
	End Transaction
	
ElseIf _nOpc == 3
	
	If _xValAcs <> '1'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Comercial" podem realizar o cancelamento de programações!' , 'Atenção!' , ,1 )
		Return
	EndIf
	
	If ZF7->ZF7_STATUS == '1' .Or. ZF7->ZF7_STATUS == '3'
	
		If U_ITMsg( 'Confirma o cancelamento da programação: '+ ZF7->ZF7_CODIGO +' ?' , 'Atenção!',,3,2,2 )
			
			DEFINE MSDIALOG _oDlg TITLE "Justificar:" FROM 178,181 TO 240,697 PIXEL
			
			@ 005,003 Get _oGet1 Var _cGet1 Size 212,020 COLOR CLR_BLACK MULTILINE PIXEL OF _oDlg
			
			DEFINE SBUTTON FROM 015,227 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) , U_ITMsg('É obrigatório justificar o cancelamento!','Atenção!',,1) , _oDlg:End() ) ) OF _oDlg
			
			ACTIVATE MSDIALOG _oDlg CENTERED
			
			U_AOMS028H( { ZF7->ZF7_CODIGO , '4' , AllTrim( _cGet1 ) } )
			
			RecLock( 'ZF7' , .F. )
			ZF7->ZF7_STATUS		:= '6'
			ZF7->ZF7_APROVA		:= RetCodUsr()
			ZF7->ZF7_DATA		:= Date()
			ZF7->ZF7_HORA		:= Time()
			ZF7->( MSUnLock() )
			
		EndIf
	
	Else
		U_ITMsg( 'Somente programações pendentes ou devolvidas podem ser canceladas!' , 'Atenção!' , ,1 )
	EndIf

ElseIf _nOpc == 4
	
   	If _xValAcs <> '2'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Logística" podem realizar atendimentos de programações!' , 'Atenção!' , ,1 )
		Return
	EndIf
	
	If U_ITMsg( 'Utilizar a seleção múltipla de programações?',"Atenção",,3,2,2 )
		
		_aRegZF7 := AOMS028MSA()
		
		If !Empty(_aRegZF7) .And. U_ITMsg( 'Confirma o atendimento das programações selecionadas?' , 'Atenção!',,3,2,2 )
		
			For _nI := 1 To Len( _aRegZF7 )
				
				DBSelectArea('ZF7')
				ZF7->( DBGoTo( _aRegZF7[_nI] ) )
				
				RecLock( 'ZF7' , .F. )
				ZF7->ZF7_STATUS		:= '4'
				ZF7->( MSUnLock() )
				
			Next _nI
			
			U_ITMsg(  'Programações atualizadas com sucesso!' , 'Concluído!',,2)
		
		EndIf
		
	Else
		
		If ZF7->ZF7_USRLOG == RetCodUsr()
		
			If ZF7->ZF7_STATUS == '2'
			
				If U_ITMsg( 'Confirma o atendimento da programação: '+ ZF7->ZF7_CODIGO +' ?' , 'Atenção!',,3,2,2 )
					
					RecLock( 'ZF7' , .F. )
					ZF7->ZF7_STATUS	:= '4'
					ZF7->( MSUnLock() )
					
				EndIf
			
			Else
				U_ITMsg( 'Somente programações "Aprovadas" podem ser atendidas!' , 'Atenção!' , ,,1 )
			EndIf
		
		Else
			U_ITMsg( 'Somente poderão ser atendidas as programações atribuídas ao seu usuário!' , 'Atenção!' , ,,1 )
		EndIf
	
	EndIf

ElseIf _nOpc == 5
	
	If U_ITMsg( 'Confirma o envio de notificação aos responsáveis pra programação: '+ ZF7->ZF7_CODIGO +' ?' , 'Atenção!',,3,2,2 )
		
		DEFINE MSDIALOG _oDlg TITLE "Notificação:" FROM 178,181 TO 240,697 PIXEL
		
		@ 005,003 Get _oGet1 Var _cGet1 Size 212,020 COLOR CLR_BLACK MULTILINE PIXEL OF _oDlg
		
		DEFINE SBUTTON FROM 015,227 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) , U_ITMsg('É obrigatório preencher a notificação!','Atenção!',,,1) , _oDlg:End() ) ) OF _oDlg
		
		ACTIVATE MSDIALOG _oDlg CENTERED
		
		LjMsgRun( 'Enviando WF de notificação...' , 'Aguarde!' , {|| AOMS028WFC( 'N' , _cGet1 ) } )
		
	EndIf

ElseIf _nOpc == 6
	
	If _xValAcs <> '2'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Logística" podem realizar a remoção de pedidos de programações!' , 'Atenção!' , ,,1 )
		Return
	EndIf
    
    Begin Transaction
    
    If ZF7->ZF7_USRLOG == RetCodUsr()
    
		If ZF7->ZF7_STATUS == '2' .Or. ZF7->ZF7_STATUS == '4'
		
			If U_ITMsg( 'Confirma a remoção de pedidos da programação: '+ ZF7->ZF7_CODIGO +' ?' , 'Atenção!' ,,3,2,2)
				
				DEFINE MSDIALOG _oDlg TITLE "Justificar:" FROM 178,181 TO 240,697 PIXEL
				
					@ 005,003 Get _oGet1 Var _cGet1 Size 212,020 COLOR CLR_BLACK MULTILINE PIXEL OF _oDlg
					
					DEFINE SBUTTON FROM 015,227 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) , U_ITMsg( 'É obrigatório justificar a remoção de pedidos!' , 'Atenção!' , ,1 ) , _oDlg:End() ) ) OF _oDlg
				
				ACTIVATE MSDIALOG _oDlg CENTERED
				
				// Verifica quais pedidos podem ser removidos (pendentes)
				DBSelectArea('ZF8')
				ZF8->( DBSetOrder(1) )
				If ZF8->( DBSeek( xFilial('ZF8') + ZF7->ZF7_CODIGO ) )
					
					_nCntAtn := 0
					_nCntTot := 0
					
					While ZF8->( !Eof() ) .And. ZF8->( ZF8_FILIAL + ZF8_CODPRG ) == xFilial('ZF8') + ZF7->ZF7_CODIGO
						
						DBSelectArea('SC5')
						SC5->( DBSetOrder(1) )
						If SC5->( DBSeek( ZF8->( ZF8_FILPED + ZF8_NUMPED ) ) )
							
							_cNumNota := ''
							
							DBSelectArea('SC6')
							SC6->( DBSetOrder(1) )
							If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
								
								While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
									
									If !Empty(SC6->C6_NOTA)
										_cNumNota := SC6->C6_NOTA
										Exit
									EndIf
									
								SC6->( DBSkip() )
								EndDo
								
							EndIf
							
							_nCntTot++
							
							If Empty( _cNumNota )
								aAdd( _aPedDev , { ZF8->( Recno() ) , SC5->( Recno() ) } )
							Else
								_nCntAtn++
							EndIf
							
						EndIf
						
					ZF8->( DBSkip() )
					EndDo
					
					If Empty( _aPedDev )
					
						U_ITMsg( 'Não existem pedidos pendentes na programação atual! Verifique a programação selecionada e tente novamente.' , 'Atenção!' , ,,1 )
						
					Else
						
						For _nI := 1 To Len( _aPedDev )
							
							DBSelectArea('SC5')
							SC5->( DBGoTo( _aPedDev[_nI][02] ) )
							
							aAdd( _aPedAtn , {	.F.																,;
												SC5->C5_FILIAL													,;
												SC5->C5_NUM														,;
												SC5->C5_CLIENTE													,;
												SC5->C5_LOJACLI													,;
												SC5->C5_I_NOME													,;
												SC5->C5_MENNOTA													,;
												AllTrim( Transform( SC5->C5_I_PESBR , '@E 999,999,999.9999' ) )	,;
												_aPedDev[_nI][01]												,;
												_nI																})
							
						Next _nI
						
						If U_ITLISTBOX( 'Pedidos pendentes da programação' , {'[  ]','Filial','Número','Cliente','Loja','Nome','Msg. Nota','Peso'} , @_aPedAtn , .T. , 2 , 'Verifique e selecione os pedidos que deseja remover da programação atual:' )
						
							If !Empty( _aPedAtn )
							
								_nCntDev := 0
							
								For _nI := 1 To Len( _aPedAtn )
									IIf( _aPedAtn[_nI][01] , _nCntDev++ , Nil )
								Next _nI
								
								If _nCntDev == 0
									
									U_ITMsg( 'Não foram selecionados pedidos para processar!' , 'Atenção!' ,,1 )
									
								Else
								
									// Verifica se deve cancelar a programação atual.
									If _nCntAtn == 0 .And. _nCntDev == _nCntTot
									
										RecLock( 'ZF7' , .F. )
										
										ZF7->ZF7_STATUS		:= '6'
										ZF7->ZF7_APROVA		:= RetCodUsr()
										ZF7->ZF7_DATA		:= Date()
										ZF7->ZF7_HORA		:= Time()
										
										ZF7->( MSUnLock() )
										
										U_AOMS028H( { ZF7->ZF7_CODIGO , '4' , 'Todos os pedidos foram removidos: '+ AllTrim( _cGet1 ) } )
									
									Else
										
										For _nI := 1 To Len( _aPedAtn )
										
											If _aPedAtn[_nI][01]
												
												DBSelectArea('ZF8')
												ZF8->( DBGoTo( _aPedDev[_aPedAtn[_nI][10]][01]) )
												
												U_AOMS028H( { ZF7->ZF7_CODIGO , '5' , 'Remoção de pedido: ['+ ZF8->ZF8_FILPED +'-'+ ZF8->ZF8_NUMPED +'] '+ AllTrim( _cGet1 ) } )
												
												RecLock( 'ZF8' , .F. )
												ZF8->( DBDelete() )
												ZF8->( MSUnLock() )
												
											EndIf
											
										Next _nI
										
									EndIf
									
									LjMsgRun( 'Enviando WF de comunicação da devolução...' , 'Aguarde!' , {|| AOMS028WFC( 'R' , _cGet1 , _aPedAtn ) } )
									
								EndIf
							
							EndIf
							
						Else
							U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' , ,1 )
						EndIf
						
					EndIf
					
				EndIf
				
			EndIf
		
		Else
			U_ITMsg( 'Somente programações "Aprovadas" ou "Em Atendimento" podem ser devolvidas!' , 'Atenção!' , ,1 )
		EndIf
	
	Else
		U_ITMsg( 'Somente programações atribuídas ao seu usuário podem ter pedidos removidos! Verifique a programação selecionada e tente novamente.' , 'Atenção!' , ,1 )
	EndIf
	
	End Transaction

ElseIf _nOpc == 7

	If _xValAcs <> '2'
		U_ITMsg( 'Somente usuários cadastrados com perfil "Logística" podem realizar a transferência de programações!' , 'Atenção!' , ,1 )
		Return
	EndIf
	
	If U_ITMsg(	'Essa rotina transfere as programações que forem selecionadas para outro usuário da Logística. Essa operação não poderá ser desfeita, a não ser que o usuário de '+ ;
					'destino devolva todas as programações utilizando essa mesma rotina. Deseja continuar?' , 'Atenção!',,3,2,2 )
		
		_cQuery := " SELECT * "
		_cQuery += " FROM  "+ RetSqlName('ZF7') +" ZF7 "
		_cQuery += " WHERE "+ RetSqlCond('ZF7')
		_cQuery += " AND ZF7.ZF7_USRLOG = '"+ RetCodUsr() +"' "
		_cQuery += " AND ZF7.ZF7_STATUS IN ('2','4') "
		_cQuery += " ORDER BY ZF7.ZF7_FILIAL, ZF7.ZF7_CODIGO "
		
		_cAlias := GetNextAlias()
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
		
		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )
		While (_cAlias)->( !Eof() )
			
			aAdd( _aDados , {	.F.															,;
								(_cAlias)->ZF7_FILIAL										,;
								(_cAlias)->ZF7_CODIGO										,;
								DToC( SToD( (_cAlias)->ZF7_DATA ) )							,;
								(_cAlias)->ZF7_HORA											,;
								(_cAlias)->ZF7_PRAZO										,;
								U_ITRETBOX( (_cAlias)->ZF7_STATUS , 'ZF7_STATUS' )			,;
								Capital( AllTrim( EVAL(bFullName, (_cAlias)->ZF7_APROVA ) ) )	,;
								U_ITRETBOX( (_cAlias)->ZF7_TIPCAR , 'ZF7_TIPCAR' )			,;
								Capital( AllTrim( EVAL(bFullName,  (_cAlias)->ZF7_CODSUP ) ) )	,;
								Capital( AllTrim( EVAL(bFullName,  (_cAlias)->ZF7_USRLOG ) ) )	})
			
		(_cAlias)->( DBSkip() )
		EndDo
		
		(_cAlias)->( DBCloseArea() )
		
		If Empty( _aDados )
			//								|....:....|....:....|....:....|....:....|
			ShowHelpDlg( 'Atenção!' ,	{	'Não foram encontradas programações que '	,;
											' estejam pendentes ou sendo atendidas '	,;
											' pelo usuário atual!.'						}, 3 ,;
										{	'Somente programações pendentes ou que '	,;
											' estiverem em atendimento podem ser '		,;
											' transferidas para outro usuário.'			}, 3  )
			
		Else
			
			_aHeader := {'Sel','Filial','Programação','Data','Hora','Prazo','Status','Aprovador','Tipo de Carga','Supervisor','Resp. Logística'}
			
			If U_ITListBox( "Geração das Notas de Entrada via CNF" , _aHeader , @_aDados , .T. , 2 , 'Selecione as CNF que deseja gerar! | Mix: '+ ZLE->ZLE_COD )
				
				aAdd( _aParBox , { 1 , "Usuário de destino:" , Space(6) , "@!" , "" , "ZZL_01" , "" , 50 , .T. } )
				_aParRet := { Space(6) }
				
				If ParamBox( _aParBox , "Informar o usuário da logística que receberá as programações:" , @_aParRet , {|| AOMS028VUL( _aParRet[01] ) } ,, .T. , , , , , .F. , .F. )
					
					If U_ITMsg(	'Confirma a transferência das programações para o usuário: '		+;
									_aParRet[01] +' - '+ Capital( AllTrim( EVAL(bFullName,  _aParRet[01] ) ) )	,;
									'Atenção!',,3,2,2																 )
						
						_nX := 0
						_nZ := 0
						
						For _nI := 1 To Len( _aDados )
							
							If _aDados[_nI][01]
								
								_nZ++
								
								DBSelectArea('ZF7')
								ZF7->( DBSetOrder(1) )
								If ZF7->( DBSeek( _aDados[_nI][02] + _aDados[_nI][03] ) )
									
									RecLock( 'ZF7' , .F. )
									ZF7->ZF7_USRLOG := _aParRet[01]
									ZF7->( MSUnLock() )
									
									_nX++
									
								EndIf
								
							EndIf
							
						Next _nI
						
						If _nX > 0
						
							U_ITMsg( 'Foram transferidas '+ cValToChar(_nX) +' programações!' , 'Concluído!' , ,2 )
							_oBrowse:Refresh()
							
						ElseIf _nZ > 0
							
							U_ITMsg( 'Falhou ao processar os registros selecionados!' , 'Atenção!' , ,1 )
							
						Else
							
							U_ITMsg( 'Não foi selecionado nenhum registro, operação não realizada!' , 'Atenção!' , ,1 )
							
						EndIf
						
					Else
						U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' , ,1 )
					EndIf
					
				Else
					U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' , ,1 )
				EndIf
				
			EndIf
			
		EndIf
		
	EndIf

EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa--------: AOMS028APR
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Grava a aprovação da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028APR()

Local _oModel	:= FWModelActive()
Local _oView	:= FWViewActive()
Local _lRet		:= AOMS028GRV( .F. )

If _lRet .And. U_ITMsg( 'Confirma a aprovação da programação de entrega?' , 'Atenção!',,3,2,2 )
	
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_STATUS'	, '2'			)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_APROVA'	, RetCodUsr()	)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_DATA'		, Date()		)
	_oModel:LoadValue( 'ZF7MASTER' , 'ZF7_HORA'		, Time()		)
	_lRet := .T.
	
	U_AOMS028H( { _oModel:GetValue( 'ZF7MASTER' , 'ZF7_CODIGO' ) , '2' , 'Aprovação da programação de entregas! [AOMS028]' } )
	
	_oView:Refresh()

EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028ACT
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Validação na ativação do modelo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028ACT( _oModel )

Local _xValAcs	:= U_ITACSUSR( 'ZZL_PRGLOG' )
Local _lRet		:= .T.
Local _aInfHlp	:= {}
Local _nOper	:= _oModel:GetOperation()

If ( _nOper == 3 .Or. _nOper == 4 .Or. _nOper == 5 ) .And. ( ValType( _xValAcs ) <> 'C' .Or. _xValAcs <> '1' )
	
	_aInfHlp := {}
	//                  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, {	"Somente usuários configurados com perfil "	,;
						" 'Comercial' podem executar essa ação!"	})
	
	aAdd( _aInfHlp	, {	"Verifique a opção selecionada e caso "		,;
						" necessário informe a área de suporte."	})
	
	U_ITCADHLP( _aInfHlp , "AOMS02816" )
	
	_lRet := .F.
	
EndIf

If _nOper == 4 .Or. _nOper == 5
	
	If ZF7->ZF7_STATUS <> '1' .And. ZF7->ZF7_STATUS <> '3'
		
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"Não é possível alterar uma programação"	,;
							" que não esteja com STATUS = Pendente ou"	,;
							" Devolvida."								})
		
		aAdd( _aInfHlp	, {	"Verifique a programação, caso necessário"	,;
							" solicite a devolução ou o cancelamento"	,;
							" para alterar ou desvincular os pedidos."	})
		
		U_ITCADHLP( _aInfHlp , "AOMS02801" )
		
		_lRet := .F.
		
	EndIf
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028R
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Rotina de impressão da programação de entrega
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028R()

Local _cPerg	:= "AOMS028"

If Pergunte( _cPerg )

	Processa( {|| AOMS028PRT() } , 'Aguarde!' , 'Iniciando...' )

Else

	U_ITMsg( 'Operação cancelada pelo usuário' , 'Atenção!' , ,1 )

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS028PRT
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Processa a impressão da programação de entrega
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028PRT()

Local _aArea	:= FWGetArea()
Local _aDados	:= {}
Local _aChvPed	:= {}
Local _oPrt		:= Nil
Local _oFont01	:= TFont():New( "Verdana" ,, 08 ,, .F. )
Local _oFont02	:= TFont():New( "Verdana" ,, 07 ,, .F. )
Local _oFntDes	:= TFont():New( "Verdana" ,, 09 ,, .F. )
Local _oFntSub	:= TFont():New( "Verdana" ,, 10 ,, .F. )
Local _oFntObs	:= TFont():New( "Arial"   ,, 06 ,, .F. )
Local _nColIni	:= 110
Local _nColFim	:= 3380
Local _nLinha	:= 5000 
Local _nI		:= 0 
Local _nX		:= 0
Local _nZ		:= 0
Local _cPedTran	:= ''
Local _nCtrl	:= 0
Local _oBrush	:= TBrush():New( , RGB(215,225,225) )
Local _oBrushD	:= TBrush():New( , RGB(0,0,0) )
Local _nQtPallet:= 0
Local _nQtNoPl	:= 0
Local _nQtSobra	:= 0
Local _cUMPal	:= ''
Local _cInfPal	:= ''
Local _nTotPal	:= 0
Local _nTotPes	:= 0

ProcRegua( 0 )

IncProc( 'Iniciando o objeto de impressão...' )

IncProc( 'Verificando as programações...' )
_aDados := AOMS028SEL()

If Empty(_aDados)
	U_ITMsg( 'Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente.' , 'Atenção!' , ,1 )
	Return
EndIf

IncProc( 'Imprimindo os dados...' )
_oPrt := TMSPrinter():New( 'Programação de entregas: Comercial - Logística' )
_oPrt:SetLandscape() 	//Paisagem
_oPrt:SetPaperSize(9)	//Seta para papel A4

_oPrt:StartPage()
AOMS028ICR( @_oPrt , @_nLinha )

For _nI := 1 To Len( _aDados )

	DBSelectArea('ZF7')
	ZF7->( DBGoTo( _aDados[_nI][01] ) )
	
	AOMS028ICR( @_oPrt , @_nLinha , .T. )
	
	_oPrt:Say( _nLinha , _nColIni + 0020 , 'Filial'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni        , _nLinha + 040	, _nColIni + 0100 )
	_oPrt:Line( _nLinha       , _nColIni + 0100 , _nLinha + 040	, _nColIni + 0100 )
	
	_oPrt:Say( _nLinha , _nColIni + 0120 , 'Código'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 0115 , _nLinha + 040	, _nColIni + 0280 )
	_oPrt:Line( _nLinha       , _nColIni + 0280 , _nLinha + 040	, _nColIni + 0280 )
	
	_oPrt:Say( _nLinha , _nColIni + 0300 , 'Data'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 0295 , _nLinha + 040	, _nColIni + 0480 )
	_oPrt:Line( _nLinha       , _nColIni + 0480 , _nLinha + 040	, _nColIni + 0480 )
	
	_oPrt:Say( _nLinha , _nColIni + 0500 , 'Hora'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 0495 , _nLinha + 040	, _nColIni + 0650 )
	_oPrt:Line( _nLinha       , _nColIni + 0650 , _nLinha + 040	, _nColIni + 0650 )
	
	_oPrt:Say( _nLinha , _nColIni + 0670 , 'Status'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 0665 , _nLinha + 040	, _nColIni + 0950 )
	_oPrt:Line( _nLinha       , _nColIni + 0950 , _nLinha + 040	, _nColIni + 0950 )
	
	_oPrt:Say( _nLinha , _nColIni + 0970 , 'Tipo de Carga'		, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 0965 , _nLinha + 040	, _nColIni + 1350 )
	_oPrt:Line( _nLinha       , _nColIni + 1350 , _nLinha + 040	, _nColIni + 1350 )
	
	_oPrt:Say( _nLinha , _nColIni + 1370 , 'Prazo'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 1365 , _nLinha + 040	, _nColIni + 1600 )
	_oPrt:Line( _nLinha       , _nColIni + 1600 , _nLinha + 040	, _nColIni + 1600 )
	
	_oPrt:Say( _nLinha , _nColIni + 1620 , 'Coord.'				, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 1615 , _nLinha + 040	, _nColIni + 1750 )
	_oPrt:Line( _nLinha       , _nColIni + 1750 , _nLinha + 040	, _nColIni + 1750 )
	
	_oPrt:Say( _nLinha , _nColIni + 1770 , 'Nome Coord.'		, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 1765 , _nLinha + 040	, _nColIni + 2380 )
	_oPrt:Line( _nLinha       , _nColIni + 2380 , _nLinha + 040	, _nColIni + 2380 )
	
	_oPrt:Say( _nLinha , _nColIni + 2400 , 'Cod. Usr.'			, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 2395 , _nLinha + 040	, _nColIni + 2580 )
	_oPrt:Line( _nLinha       , _nColIni + 2580 , _nLinha + 040	, _nColIni + 2580 )
	
	_oPrt:Say( _nLinha , _nColIni + 2600 , 'Resp. Logística'	, _oFntDes )
	_oPrt:Line( _nLinha + 040 , _nColIni + 2595 , _nLinha + 040	, _nColFim )
	_oPrt:Line( _nLinha       , _nColFim        , _nLinha + 040	, _nColFim )
	
	_nLinha += 050
	
	_oPrt:FillRect( { _nLinha + 001 , _nColIni        , _nLinha + 032 , _nColIni + 0100 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 0115 , _nLinha + 032 , _nColIni + 0280 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 0295 , _nLinha + 032 , _nColIni + 0480 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 0495 , _nLinha + 032 , _nColIni + 0650 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 0665 , _nLinha + 032 , _nColIni + 0950 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 0965 , _nLinha + 032 , _nColIni + 1350 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 1365 , _nLinha + 032 , _nColIni + 1600 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 1615 , _nLinha + 032 , _nColIni + 1750 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 1765 , _nLinha + 032 , _nColIni + 2380 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 2395 , _nLinha + 032 , _nColIni + 2580 } , _oBrush )
	_oPrt:FillRect( { _nLinha + 001 , _nColIni + 2595 , _nLinha + 032 , _nColFim        } , _oBrush )
	
	_oPrt:Say( _nLinha , _nColIni + 0020 , ZF7->ZF7_FILIAL																				, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 0120 , ZF7->ZF7_CODIGO																				, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 0295 , DToC( ZF7->ZF7_DATA )																		, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 0520 , SubStr( ZF7->ZF7_HORA , 1 , 5 )																, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 0800 , U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' )													, _oFont01 ,,,, 2 )
	_oPrt:Say( _nLinha , _nColIni + 0970 , U_ITRETBOX( ZF7->ZF7_TIPCAR , 'ZF7_TIPCAR' )													, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 1370 , U_ITRETBOX( ZF7->ZF7_PRAZO  , 'ZF7_PRAZO'  )													, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 1620 , ZF7->ZF7_CODSUP																				, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 1770 , SubStr( AllTrim( Posicione('SA3',1,xFilial('SA3')+ZF7->ZF7_CODSUP,'A3_NOME') ) , 1 , 30 )	, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 2410 , ZF7->ZF7_USRLOG																				, _oFont01 )
	_oPrt:Say( _nLinha , _nColIni + 2600 , SubStr( AllTrim( EVAL(bFullName,  ZF7->ZF7_USRLOG ) ) , 1 , 30 )									, _oFont01 )
	
	_nLinha += 045
	
	If MV_PAR16 == 1
		
		AOMS028ICR( @_oPrt , @_nLinha , .T. )
		
		_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
		
		_oPrt:Say( _nLinha , _nColIni + 0020 , 'Pedido'		   		, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 0210 , 'Dt. de Entrega'		, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 0600 , 'Cliente'			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 1800 , 'Vendedor'			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 2650 , 'Local de Entrega'	, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 3100 , 'Peso (Kg)'			, _oFntDes )
		
		_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
		
		_nLinha += 050
		
		_aPedidos := AOMS028PED( ZF7->ZF7_FILIAL , ZF7->ZF7_CODIGO , .T. )
		
		For _nX := 1 To Len( _aPedidos )
		
			If AOMS028ICR( @_oPrt , @_nLinha , .T. )
				
				_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
				
				_oPrt:Say( _nLinha , _nColIni + 0020 , 'Pedido'		   		, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 0210 , 'Dt. de Entrega'		, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 0600 , 'Cliente'			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 1800 , 'Vendedor'			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 2650 , 'Local de Entrega'	, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 3100 , 'Peso (Kg)'			, _oFntDes )
				
				_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
				
				_nLinha += 050
			
			EndIf
		
			_oPrt:Say( _nLinha , _nColIni        , _aPedidos[_nX][01] +'/'+ _aPedidos[_nX][02]					   			, _oFont02 )
			_oPrt:Say( _nLinha , _nColIni + 0250 , _aPedidos[_nX][03]														, _oFont02 )
			_oPrt:Say( _nLinha , _nColIni + 0500 , _aPedidos[_nX][04] +'/'+ _aPedidos[_nX][05] +' - '+ _aPedidos[_nX][06]	, _oFont02 )
			_oPrt:Say( _nLinha , _nColIni + 1720 , _aPedidos[_nX][07] +' - '+ _aPedidos[_nX][08]							, _oFont02 )
			_oPrt:Say( _nLinha , _nColIni + 2570 , AllTrim( _aPedidos[_nX][09] )											, _oFont02 )
			_oPrt:Say( _nLinha , _nColIni + 3250 , AllTrim( Transform( _aPedidos[_nX][10] , '@E 999,999,999' ) ) +' Kg'		, _oFont02 ,,,, 1 )
			
			
			// Verifica se o pedido do cliente está amarrado à pedidos de transferências
			
			_cPedTran := ''
			
			DBSelectArea('ZF8')
			ZF8->( DBGoTo( _aPedidos[_nX][11] ) )
			
			DBSelectArea('ZF9')
			ZF9->( DBSetOrder(1) )
			If ZF9->( DBSeek( ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM ) ) )
				
				While ZF9->(!Eof()) .And. ZF9->( ZF9_FILIAL + ZF9_CODPRG + ZF9_ITNPED ) == ZF8->( ZF8_FILIAL + ZF8_CODPRG + ZF8_ITEM )
					
					_cPedTran += ' | '+ ZF9->ZF9_FILIAL +'-'+ ZF9->ZF9_PEDIDO
					
				ZF9->( DBSkip() )
				EndDo
				
				If !Empty(_cPedTran)
				
					_nLinha += 035
					_oPrt:Say( _nLinha , _nColIni + 010 , '*Pedidos de Transferência: '+ SubStr( _cPedTran , 4 ) , _oFont01 )
					
				EndIf
				
			EndIf
			
			_oPrt:Say( _nLinha + 10 , _nColIni + _nZ , Replicate( '.' , 327 ) , _oFont01 )
			_nLinha += 040
			
			AOMS028ICR( @_oPrt , @_nLinha , .T. )
			
			_oPrt:Say( _nLinha , _nColIni + 0020 , 'Obs. Pedido'		, _oFont01 )
			_oPrt:Line( _nLinha + 075 , _nColIni        , _nLinha + 075	, _nColIni + 1600 )
			_oPrt:Line( _nLinha       , _nColIni + 1600 , _nLinha + 075	, _nColIni + 1600 )
			
			_oPrt:Say( _nLinha , _nColIni + 1620 , 'Obs. Programação'	, _oFont01 )
			_oPrt:Line( _nLinha + 075 , _nColIni + 1615	, _nLinha + 075	, _nColFim )
			_oPrt:Line( _nLinha       , _nColFim		, _nLinha + 075	, _nColFim )
			
			_nLinha += 040
			
			_oPrt:FillRect( { _nLinha + 001 , _nColIni        , _nLinha + 032 , _nColIni + 1600 } , _oBrush )
			_oPrt:FillRect( { _nLinha + 001 , _nColIni + 1615 , _nLinha + 032 , _nColFim        } , _oBrush )
			
			_oPrt:Say( _nLinha + 5 , _nColIni + 0010 , _aPedidos[_nX][12] , _oFntObs )
			_oPrt:Say( _nLinha + 5 , _nColIni + 1610 , _aPedidos[_nX][13] , _oFntObs )
			
			_nLinha += 045
			
		Next _nX
		
		_nLinha += 060
		_oPrt:FillRect( { _nLinha - 035 , _nColIni , _nLinha - 028 , _nColfim } , _oBrushD )
		
	ElseIf MV_PAR16 == 2
	
		_lImpAnl	:= .F.
		_nLinha		+= 030
		
		AOMS028ICR( @_oPrt , @_nLinha , .T. )
		
		_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
		_oPrt:Say( _nLinha , ( _nColIni / 2 ) + ( _nColFim / 2 ) , 'Produtos da programação' , _oFntSub ,,,, 2 )
		_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
		
		_nLinha += 050
		
		_oPrt:Say( _nLinha , _nColIni        , 'Produto'	   			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 0250 , 'Descrição do Produto'	, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 1600 , 'Qtde. 1ª UM'			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 2000 , 'Qtde. 2ª UM'			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 2500 , 'Carga Total'			, _oFntDes )
		_oPrt:Say( _nLinha , _nColIni + 3000 , 'Peso (Kg)'				, _oFntDes )
		
		_oPrt:Line( _nLinha + 040 , _nColIni , _nLinha + 040 , _nColFim )
		
		_nLinha += 050
		
		_aProduto	:= AOMS028PRD( ZF7->ZF7_CODIGO )
		_nQtdReg	:= Len( _aProduto )
		_nCtrl		:= 0
		
		For _nX := 1 To _nQtdReg
			
			If AOMS028ICR( @_oPrt , @_nLinha , .T. )
				
				_oPrt:Say( _nLinha , _nColIni        , 'Produto'	   			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 0250 , 'Descrição do Produto'	, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 1600 , 'Qtde. 1ª UM'			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 2000 , 'Qtde. 2ª UM'			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 2500 , 'Carga Total'			, _oFntDes )
				_oPrt:Say( _nLinha , _nColIni + 3000 , 'Peso (Kg)'				, _oFntDes )
				
				_oPrt:Line( _nLinha + 040 , _nColIni , _nLinha + 040 , _nColFim )
				
				_nLinha += 050
				
			EndIf
			
			If _nCtrl == 1
				_oPrt:FillRect( { _nLinha + 001 , _nColIni , _nLinha + 032 , _nColFim } , _oBrush )
				_nCtrl := 0
			Else
				_nCtrl := 1
			EndIf
			
			_oPrt:Say( _nLinha , _nColIni        , _aProduto[_nX][01]																	, _oFont01 )
			_oPrt:Say( _nLinha , _nColIni + 0250 , AllTrim( Posicione( 'SB1' , 1 , xFilial('SB1') + _aProduto[_nX][01] , 'B1_DESC' ) )	, _oFont01 )
			_oPrt:Say( _nLinha , _nColIni + 1750 , Transform( _aProduto[_nX][02] , '@E 999,999,999,999' )								, _oFont01 ,,,, 1 )
			_oPrt:Say( _nLinha , _nColIni + 2150 , Transform( _aProduto[_nX][03] , '@E 999,999,999,999.99' )							, _oFont01 ,,,, 1 )
			
			//================================================================================
			// Cálculo da quantidade de Pallets
			//================================================================================
			If SB1->B1_I_UMPAL == '1'
			
				_nQtPallet	:= Int( _aProduto[_nX][02] / SB1->B1_I_CXPAL )
				_nQtNoPl	:= ( _nQtPallet * SB1->B1_I_CXPAL )
				_nQtSobra	:= _aProduto[_nX][02] - _nQtNoPl
				_cUMPal		:= PadR( SB1->B1_UM , TamSX3( 'B1_UM' )[01] )
				
			ElseIf SB1->B1_I_UMPAL == '2'
			
				_nQtPallet	:= Int( _aProduto[_nX][03] / SB1->B1_I_CXPAL )
				_nQtNoPl	:= ( _nQtPallet * SB1->B1_I_CXPAL )
				_nQtSobra	:= _aProduto[_nX][03] - _nQtNoPl
				_cUMPal		:= PadR( SB1->B1_SEGUM , TamSX3( 'B1_SEGUM' )[01] )
				
			ElseIf SB1->B1_I_UMPAL == '3'
			
				_nQtPallet	:= Int( ( _aProduto[_nX][02] / SB1->B1_I_QT3UM ) / SB1->B1_I_CXPAL )
				_nQtNoPl	:= ( _nQtPallet * SB1->B1_I_CXPAL )
				_nQtSobra	:= ( _aProduto[_nX][02] / SB1->B1_I_QT3UM ) - _nQtNoPl
				_cUMPal		:= PadR( SB1->B1_I_3UM , TamSX3( 'B1_I_3UM' )[01] )
				
			Else
			
				_nQtPallet	:= 0
				_nQtSobra	:= 0
				_cUMPal		:= ''
				
			EndIf
			
			_cInfPal := ''
			
			If _nQtPallet > 0
				_cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) + IIf( _nQtSobra > 0 , ' + ' , '' )
			EndIf
			
			If _nQtSobra > 0
				_cInfPal += cValToChar( _nQtSobra ) +' '+ _cUMPal
			EndIf
			
			_nTotPal += _nQtPallet
			
			_oPrt:Say( _nLinha , _nColIni + 2580 , AllTrim( _cInfPal ) , _oFont01 ,,,, 2 )
			
			_nPeso		:= _aProduto[_nX][02] * SB1->B1_PESBRU
			_nTotPes	+= _nPeso
			
			_oPrt:Say( _nLinha , _nColIni + 3100 , Transform( _nPeso , '@E 999,999,999,999.9999' )										, _oFont01 ,,,, 1 )
			
			_nLinha += 030
			
		Next _nX
		
		_nLinha += 020
		
		If AOMS028ICR( @_oPrt , @_nLinha , .T. )
			
			_oPrt:Say( _nLinha , _nColIni        , 'Produto'	   			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 0250 , 'Descrição do Produto'	, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 1600 , 'Qtde. 1ª UM'			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 2000 , 'Qtde. 2ª UM'			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 2500 , 'Carga Total'			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 3000 , 'Peso (Kg)'				, _oFntDes )
			
			_oPrt:Line( _nLinha + 040 , _nColIni , _nLinha + 040 , _nColFim )
			
			_nLinha += 050
			
		EndIf
		
		_oPrt:FillRect( { _nLinha + 001 , _nColIni , _nLinha + 032 , _nColFim } , _oBrush )
		_oPrt:Say( _nLinha , _nColIni , 'TOTAIS DA PROGRAMAÇÃO--------->'											, _oFont01 )
		_oPrt:Say( _nLinha , _nColIni + 2580 , AllTrim( Transform( _nTotPal , '@E 999,999,999,999' ) ) +' Pallets'	, _oFont01 ,,,, 2 )
		_oPrt:Say( _nLinha , _nColIni + 3100 , Transform( _nTotPes , '@E 999,999,999,999.9999' )					, _oFont01 ,,,, 1 )
		
		_nLinha += 050
		
		AOMS028ICR( @_oPrt , @_nLinha , .T. )
		
		
		// Informações complementares somente no modo analítico
		
		DBSelectArea('ZF9')
		ZF9->( DBSetOrder(1) )
		If ZF9->( DBSeek( xFilial('ZF9') + ZF7->ZF7_CODIGO ) )
			
			_nLinha += 050
			
			AOMS028ICR( @_oPrt , @_nLinha , .T. )
			
			_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
			_oPrt:Say( _nLinha , ( _nColIni / 2 ) + ( _nColFim / 2 ) , 'Pedidos de transferências' , _oFntSub ,,,, 2 )
			_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
			
			_nLinha += 050
			
			AOMS028ICR( @_oPrt , @_nLinha , .T. )
			
			_oPrt:Say( _nLinha , _nColIni        , 'Pedido'		   			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 0250 , 'Cód. Cliente'			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 0600 , 'Razão Social/Nome'		, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 1600 , 'Obs. Pedido'			, _oFntDes )
			_oPrt:Say( _nLinha , _nColIni + 3085 , 'Peso (Kg)'				, _oFntDes )
			
			_oPrt:Line( _nLinha + 040 , _nColIni , _nLinha + 040 , _nColFim )
			
			_nLinha		+= 050
			_nCtrl		:= 0
			_aChvPed	:= {}
			
			While ZF9->(!Eof()) .And. ZF9->( ZF9_FILIAL + ZF9_CODPRG ) == xFilial('ZF9') + ZF7->ZF7_CODIGO
				
				If aScan( _aChvPed , ZF9->( ZF9_FILIAL + ZF9_PEDIDO ) ) > 0
					ZF9->( DBSkip() )
					Loop
				Else
					aAdd( _aChvPed , ZF9->( ZF9_FILIAL + ZF9_PEDIDO ) )
				EndIf
				
				If AOMS028ICR( @_oPrt , @_nLinha , .T. )
				
					_oPrt:Say( _nLinha , _nColIni        , 'Pedido'		   			, _oFntDes )
					_oPrt:Say( _nLinha , _nColIni + 0250 , 'Cód. Cliente'			, _oFntDes )
					_oPrt:Say( _nLinha , _nColIni + 0600 , 'Razão Social/Nome'		, _oFntDes )
					_oPrt:Say( _nLinha , _nColIni + 1600 , 'Obs. Pedido'			, _oFntDes )
					_oPrt:Say( _nLinha , _nColIni + 3085 , 'Peso (Kg)'				, _oFntDes )
					
					_oPrt:Line( _nLinha + 040 , _nColIni , _nLinha + 040 , _nColFim )
					
					_nLinha += 050
				
				EndIf
				
				If _nCtrl == 1
					_oPrt:FillRect( { _nLinha + 001 , _nColIni , _nLinha + 032 , _nColFim } , _oBrush )
					_nCtrl := 0
				Else
					_nCtrl := 1
				EndIf
				
				DBSelectArea('SC5')
				SC5->( DBSetOrder(1) )
				If SC5->( DBSeek( xFilial('SC5') + ZF9->ZF9_PEDIDO ) )
				
					_oPrt:Say( _nLinha , _nColIni        , SC5->C5_FILIAL +'-'+ SC5->C5_NUM								, _oFont02 )
					_oPrt:Say( _nLinha , _nColIni + 0260 , SC5->C5_CLIENTE +'/'+ SC5->C5_LOJACLI						, _oFont02 )
					_oPrt:Say( _nLinha , _nColIni + 0600 , AllTrim( U_AOMS028N( 2 , SC5->C5_FILIAL , SC5->C5_NUM ) )	, _oFont02 )
					_oPrt:Say( _nLinha , _nColIni + 1600 , AllTrim( SC5->C5_MENNOTA )									, _oFont02 )
					_oPrt:Say( _nLinha , _nColIni + 3250 , Transform( SC5->C5_I_PESBR , '@E 999,999,999,999.9999' )		, _oFont02 ,,,, 1 )
					
					_nLinha += 030
				
				EndIf
				
			ZF9->( DBSkip() )
			EndDo
			
			_oPrt:Line( _nLinha + 010 , _nColIni , _nLinha + 010 , _nColFim )
			
		Else
			
			_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
			_oPrt:Say( _nLinha , ( _nColIni / 2 ) + ( _nColFim / 2 ) , 'Não foram configurados pedidos de transferências para a programação atual!' , _oFntSub ,,,, 2 )
			_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
			
		EndIf
		
		_nLinha += 100
		
		AOMS028ICR( @_oPrt , @_nLinha , .T. )
		
		// Informações de entregas somente no modo analítico
		
		_oPrt:Line( _nLinha - 005 , _nColIni , _nLinha - 005 , _nColFim )
		_oPrt:Say( _nLinha , ( _nColIni / 2 ) + ( _nColFim / 2 ) , 'Entregas da programação' , _oFntSub ,,,, 2 )
		_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
		
		_cEntreg := ''
		_cEntreg := AOMS028ENT( ZF7->ZF7_CODIGO )
		_cRegEnt := AOMS028REG( 1 , ZF7->ZF7_CODIGO )
		_cMunEnt := AOMS028REG( 2 , ZF7->ZF7_CODIGO )
		
		_nLinha += 050
		
		_oPrt:Say( _nLinha , _nColIni , 'Entregas: '+ _cEntreg															, _oFont01 ) ; _nLinha += 030
		
		_oPrt:FillRect( { _nLinha + 001 , _nColIni , _nLinha + 032 , _nColFim } , _oBrush )
		_oPrt:Say( _nLinha , _nColIni , 'Regiões: '+ _cRegEnt															, _oFont01 ) ; _nLinha += 030
		
		_oPrt:Say( _nLinha , _nColIni , 'Municípios: '+ _cMunEnt														, _oFont01 ) ; _nLinha += 030
		
		_oPrt:FillRect( { _nLinha + 001 , _nColIni , _nLinha + 032 , _nColFim } , _oBrush )
		_oPrt:Say( _nLinha , _nColIni , 'Responsável Comercial: '+ Capital( AllTrim( EVAL(bFullName,  ZF7->ZF7_USRPRG ) ) )	, _oFont01 )
		
		_oPrt:Line( _nLinha + 045 , _nColIni , _nLinha + 045 , _nColFim )
		
		_nLinha		:= 5000
		_nCtrl		:= 0
		_nTotPal	:= 0
		_nTotPes	:= 0
		
	EndIf
	
Next _nI

_oPrt:EndPage()
_oPrt:Preview()

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa--------: AOMS028SEL
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Seleciona os registros para a impressão
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028SEL()

Local _aRet		:= {}
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cStatus	:= ''

Do Case
	Case MV_PAR15 == 1 ; _cStatus := '1,3'
	Case MV_PAR15 == 2 ; _cStatus := '2'
	Case MV_PAR15 == 3 ; _cStatus := '4'
	Case MV_PAR15 == 4 ; _cStatus := '4,5'
	Case MV_PAR15 == 5 ; _cStatus := '6'
EndCase

_cQuery := " SELECT DISTINCT "
_cQuery +=     " ZF7.R_E_C_N_O_ AS REGZF7 "
_cQuery += " FROM  "+ RetSqlName('ZF7') +" ZF7 , "+ RetSqlName('ZF8') +" ZF8 , "+ RetSqlName('SC5') +" SC5 "
_cQuery += " WHERE "+ RetSqlCond('ZF7,ZF8')
_cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
_cQuery += " AND SC5.C5_FILIAL  = ZF8.ZF8_FILPED "
_cQuery += " AND SC5.C5_NUM     = ZF8.ZF8_NUMPED "
_cQuery += " AND ZF8.ZF8_CODPRG = ZF7.ZF7_CODIGO "
_cQuery += " AND ZF7.ZF7_STATUS IN "+ FormatIn( _cStatus , ',' )

If MV_PAR15 == 3

_cQuery += " AND EXISTS ( SELECT SC6.C6_NUM FROM "+ RetSqlName('SC6') +" SC6 WHERE "+ RetSqlDel('SC6') +" AND SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_NOTA = ' ' ) "

ElseIf MV_PAR15 == 4

_cQuery += " AND EXISTS ( SELECT SC6.C6_NUM FROM "+ RetSqlName('SC6') +" SC6 WHERE "+ RetSqlDel('SC6') +" AND SC6.C6_FILIAL = SC5.C5_FILIAL AND SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_NOTA <> ' ' ) "

EndIf

_cQuery += " AND ZF7.ZF7_CODIGO BETWEEN '"+ MV_PAR01			+"' AND '"+ MV_PAR02			+"' "
_cQuery += " AND ZF7.ZF7_DATA   BETWEEN '"+ DToS( MV_PAR07 )	+"' AND '"+ DToS( MV_PAR08 )	+"' "
_cQuery += " AND ZF8.ZF8_DTENTR BETWEEN '"+ DToS( MV_PAR09 )	+"' AND '"+ DToS( MV_PAR10 )	+"' "
_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+ MV_PAR03			+"' AND '"+ MV_PAR05			+"' "
_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+ MV_PAR04			+"' AND '"+ MV_PAR06			+"' "
_cQuery += IIf( Empty(MV_PAR13) , '' , " AND SC5.C5_VEND1   = '"+ MV_PAR13 +"' "				)
_cQuery += IIf( Empty(MV_PAR14) , '' , " AND SC5.C5_VEND2   = '"+ MV_PAR14 +"' "				)
_cQuery += IIf( Empty(MV_PAR11) , '' , " AND SC5.C5_I_EST   IN "+ FormatIn( MV_PAR11 , ';' )	)

If !Empty(MV_PAR12)
	
	_cQuery += " AND EXISTS ( SELECT 1 "
	_cQuery +=              " FROM  "+ RetSqlName('ZF1') +" ZF1 , "+ RetSqlName('ZF2') +" ZF2 "
	_cQuery +=              " WHERE "+ RetSqlCond('ZF1,ZF2')
	_cQuery +=              " AND ZF1.ZF1_CODREG = ZF2.ZF2_CODREG "
	_cQuery +=              " AND ZF1.ZF1_CODREG = '"+ MV_PAR12 +"' "
	_cQuery +=              " AND ZF2.ZF2_CODMUN = SC5.C5_I_EST || SC5.C5_I_CMUN ) "

EndIf

If MV_PAR17 == 1
	_cQuery += " AND ZF7.ZF7_USRLOG = '"+ RetCodUsr() +"' "
EndIf

_cQuery += " ORDER BY ZF7.R_E_C_N_O_ "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGZF7 )
	
	aAdd( _aRet , { (_cAlias)->REGZF7 } )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: AOMS028ICR
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Imprime cabeçalho das páginas do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028ICR( _oPrt , _nLinha , _lIniPag )

Local _cStatus		:= ''
Local _nLimPag		:= 2300
Local _nColIni		:= 0100
Local _nColFim		:= 3380
Local _oFntTit		:= TFont():New( "Arial" ,, 20 , , .T. , , , , .T. , .F. )
Local _oFntDes		:= TFont():New( "Arial" ,, 10 , , .F. , , , , .T. , .F. )
Local _lRet			:= .F.

Default _lIniPag	:= .F.

If _nLinha >= _nLimPag

	_nLinha := 0
	
	If _lIniPag
	
		_oPrt:EndPage()
		_oPrt:StartPage()
		
		_lRet := .T.
	
	EndIf
	
	_nLinha += 100

	_oPrt:Line( _nLinha       , _nColIni , _nLinha       , _nColFim )
	_oPrt:Line( _nLinha + 200 , _nColIni , _nLinha + 200 , _nColFim )
	_oPrt:Line( _nLinha       , _nColIni , _nLinha + 200 , _nColIni )
	_oPrt:Line( _nLinha       , _nColFim , _nLinha + 200 , _nColFim )
	
	_nLinha += 010
	
	_oPrt:SayBitmap( _nLinha , _nColIni + 010 , "/system/lgrl01.bmp" , 340 , 100 )
	_oPrt:Say( _nLinha + 20  , _nColIni + 450 , 'Relatório das programações de entrega: Comercial - Logística' , _oFntTit )
	
	_nLinha += 115
	
	_oPrt:Line( _nLinha , _nColIni + 10 , _nLinha , _nColFim - 10 )
	
	_nLinha += 020
	
	Do Case
		Case MV_PAR15 == 1 ; _cStatus := 'Pendentes'
		Case MV_PAR15 == 2 ; _cStatus := 'Aprovadas'
		Case MV_PAR15 == 3 ; _cStatus := 'Em Atendimento'
		Case MV_PAR15 == 4 ; _cStatus := 'Concluídas'
		Case MV_PAR15 == 5 ; _cStatus := 'Canceladas'
	EndCase
	
	_oPrt:Say( _nLinha , _nColIni + 0020 , 'Relatório das programações : '+ _cStatus				, _oFntDes )
	_oPrt:Say( _nLinha , _nColIni + 1000 , 'Período : '+ DToC( MV_PAR07 ) +' / '+ DToC( MV_PAR08 )	, _oFntDes )
	
	_nLinha += 100
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028MSA
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Rotina para permitir a múltipla seleção de programações
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028MSA()

Local _aRet		:= {}
Local _aDados	:= {}
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _nI		:= 0

_cQuery := " SELECT ZF7.R_E_C_N_O_ AS REGZF7 FROM "+ RETSQLNAME('ZF7') +" ZF7 WHERE "+ RETSQLCOND('ZF7') +" AND ZF7.ZF7_STATUS = '2' AND ZF7.ZF7_USRLOG = '"+ RetCodUsr() +"' ORDER BY ZF7.ZF7_CODIGO "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	
	DBSelectArea('ZF7')
	ZF7->( DBGoTo( (_cAlias)->REGZF7 ) )
	
	aAdd( _aDados , {	.F.												,;
						ZF7->ZF7_CODIGO									,;
						DToC( ZF7->ZF7_DATA )							,;
						ZF7->ZF7_HORA									,;
						U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' )	,;
						U_ITRETBOX( ZF7->ZF7_TIPCAR , 'ZF7_TIPCAR' )	,;
						AllTrim( ZF7->ZF7_OBS )							,;
						ZF7->( Recno() )								})
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Empty(_aDados)
	
	U_ITMsg( 'Não foram encontrados registros pendentes para o seu usuário!' , 'Atenção!' , ,1 )
	
Else

	If U_ITListBox( 'Programações aprovadas' , {'[]','Código','Data','Hora','Status','Tipo Carga','Obs.'} , @_aDados , .T. , 2 , 'Selecione as programações para processar:' )
		
		For _nI := 1 To Len( _aDados )
			
			If _aDados[_nI][01]
				
				aAdd( _aRet , _aDados[_nI][08] )
				
			EndIf
			
		Next _nI
		
		If Empty(_aRet)
			U_ITMsg( 'Não foram selecionados registros para o processamento! Verifique os dados e tente novamente.' , 'Atenção!' , ,1)
		EndIf
		
	Else
	
		U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção',,1 )
	
	EndIf
	
EndIf

Return( _aRet )

/*
===============================================================================================================================
Programa--------: AOMS028U
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Valida os pedidos de clientes informados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028U()

Local _aArea	:= FWGetArea()

Local _oModel	:= FWModelActive()
Local _oModZF8	:= _oModel:GetModel( 'ZF8DETAIL' )
Local _cProgr	:= _oModel:GetValue( 'ZF7MASTER' , 'ZF7_CODIGO' )
Local _cCodSup	:= _oModel:GetValue( 'ZF7MASTER' , 'ZF7_CODSUP' )
Local _cFilPed	:= _oModel:GetValue( 'ZF8DETAIL' , 'ZF8_FILPED' )
Local _cNumPed	:= _oModel:GetValue( 'ZF8DETAIL' , 'ZF8_NUMPED' )
Local _cFilAux	:= ''
Local _nI		:= 0
Local _nTotLin	:= _oModZF8:Length()
Local _nLinAtu	:= _oModZF8:nLine

Local _aInfHlp	:= {}
Local _lRet		:= .T.
Local _cQuery	:= ''
Local _cAlias	:= ''

If !Empty( _cFilPed ) .And. !Empty( _cNumPed )
	
	DBSelectArea('SC5')
	SC5->( DBSetOrder(1) )
	If SC5->( DBSeek( _cFilPed + _cNumPed ) )
		
		If Empty( SC5->C5_LIBEROK ) .And. Empty( SC5->C5_NOTA ) .And. Empty( SC5->C5_BLQ )
			
			If Empty( _cCodSup )
				
				_oModel:SetValue( 'ZF7MASTER' , 'ZF7_CODSUP' , Posicione('SA3',1,xFilial('SA3')+SC5->C5_VEND1,'A3_SUPER') )
				
			Else
				
				If SC5->C5_I_PEDPA <> 'S' .And. _cCodSup <> Posicione('SA3',1,xFilial('SA3')+SC5->C5_VEND1,'A3_SUPER')
					
					_aInfHlp := {}
					//                  |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp	, {	"O pedido informado não está relacionado"		,;
										" com o coordenador da programação atual!"		})
					
					aAdd( _aInfHlp	, {	"Verifique o pedido informado e/ou o"			,;
										" coordenador informado na programação."		})
					
					U_ITCADHLP( _aInfHlp , "AOMS02806" )
					
					_lRet := .F.
					
				EndIf
				
			EndIf
			
			If _lRet
			
				_cQuery := " SELECT "
				_cQuery += "     ZF8.ZF8_FILIAL AS FILPRG ,"
				_cQuery += "     ZF8.ZF8_CODPRG AS CODPRG "
				_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8 , "+ RetSqlName('ZF7') +" ZF7 "
				_cQuery += " WHERE "
				_cQuery += "     ZF8.D_E_L_E_T_ = ' ' "
				_cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
				_cQuery += " AND ZF7.ZF7_FILIAL = ZF8.ZF8_FILIAL "
				_cQuery += " AND ZF7.ZF7_CODIGO = ZF8.ZF8_CODPRG "
				_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
				_cQuery += " AND ZF8.ZF8_FILPED = '"+ _cFilPed +"' "
				_cQuery += " AND ZF8.ZF8_NUMPED = '"+ _cNumPed +"' "
				_cQuery += " AND ( ( ZF8.ZF8_FILIAL = '"+ xFilial('ZF8') +"' AND ZF8.ZF8_CODPRG <> '"+ _cProgr +"' ) OR ( ZF8.ZF8_FILIAL <> '"+ xFilial('ZF8') +"' ) ) "
				
				_cAlias := GetNextAlias()
				
				If Select(_cAlias) > 0
					(_cAlias)->( DBCloseArea() )
				EndIf
				
				DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
				
				DBSelectArea(_cAlias)
				(_cAlias)->( DBGoTop() )
				If (_cAlias)->( !Eof() )
					
					DBSelectArea('ZF7')
					ZF7->( DBSetOrder(1) )
					If ZF7->( DBSeek( (_cAlias)->( FILPRG + CODPRG ) ) )
						
						_aInfHlp := {}
						//                  |....:....|....:....|....:....|....:....|
						aAdd( _aInfHlp	, {	"A Filial e Pedido informados já estão"		,;
											" configurados em outra programação de"		,;
											" entrega!"									})
						
						aAdd( _aInfHlp	, {	"Verifique a programação ["+ (_cAlias)->CODPRG +"] na"			,;
											" Filial ["+ (_cAlias)->FILPRG +"]."							,;
											" Status ["+ U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' ) +"]."	})
						
						U_ITCADHLP( _aInfHlp , "AOMS02802" )
						
						_lRet := .F.
						
					EndIf
					
				EndIf
				
				(_cAlias)->( DBCloseArea() )
			
			EndIf
			
			If _lRet
			
				_cQuery := " SELECT "
				_cQuery += "     ZF9.ZF9_FILIAL AS FILPRG ,"
				_cQuery += "     ZF9.ZF9_CODPRG AS CODPRG  "
				_cQuery += " FROM  "+ RetSqlName('ZF9') +" ZF9 , "+ RetSqlName('ZF7') +" ZF7 "
				_cQuery += " WHERE "
				_cQuery += "     ZF9.D_E_L_E_T_ = ' ' "
				_cQuery += " AND ZF9.D_E_L_E_T_ = ' ' "
				_cQuery += " AND ZF7.ZF7_FILIAL = ZF9.ZF9_FILIAL "
				_cQuery += " AND ZF7.ZF7_CODIGO = ZF9.ZF9_CODPRG "
				_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
				_cQuery += " AND ZF9.ZF9_FILIAL = '"+ _cFilPed +"' "
				_cQuery += " AND ZF9.ZF9_PEDIDO = '"+ _cNumPed +"' "
				
				_cAlias := GetNextAlias()
				
				If Select(_cAlias) > 0
					(_cAlias)->( DBCloseArea() )
				EndIf
				
				DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
				
				DBSelectArea(_cAlias)
				(_cAlias)->( DBGoTop() )
				If (_cAlias)->( !Eof() )
					
					DBSelectArea('ZF7')
					ZF7->( DBSetOrder(1) )
					If ZF7->( DBSeek( (_cAlias)->( FILPRG + CODPRG ) ) )
						
						_aInfHlp := {}
						//                  |....:....|....:....|....:....|....:....|
						aAdd( _aInfHlp	, {	"A Filial e Pedido informados já foram"		,;
											" configurados como pedido de Transf.!"		})
						
						aAdd( _aInfHlp	, {	"Verifique a programação ["+ (_cAlias)->CODPRG +"] na"			,;
											" Filial ["+ (_cAlias)->FILPRG +"]."							,;
											" Status ["+ U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' ) +"]."	})
						
						U_ITCADHLP( _aInfHlp , "AOMS02810" )
						
						_lRet := .F.
						
					EndIf
					
				EndIf
				
				(_cAlias)->( DBCloseArea() )
			
			EndIf
			
		Else
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"O pedido informado não está 'Pendente'"	,;
								" no sistema!"								})
			
			aAdd( _aInfHlp	, {	"Somente poderão ser utilizados nas"		,;
								" programações os pedidos que ainda não"	,;
								" estiverem atendidos ou em processamento."	})
			
			U_ITCADHLP( _aInfHlp , "AOMS02804" )
			
			_lRet := .F.
			
		EndIf
		
		If _nTotLin > 1
		
			For _nI := 1 To _nTotLin
			
				_oModZF8:GoLine( _nI )
				
				_cFilAux := _oModZF8:GetValue( 'ZF8_FILPED' )
				
				If _oModZF8:IsDeleted()
					Loop
				EndIf
				
				If _cFilAux <> _cFilPed
				
					_aInfHlp := {}
					//                  |....:....|....:....|....:....|....:....|
					aAdd( _aInfHlp	, {	"Existem pedidos em diferentes Filiais na "	,;
										" na programação atual!"					})
					
					aAdd( _aInfHlp	, {	"Verifique os pedidos informados e/ou a "	,;
										" configuração da programação para que "	,;
										" todos os pedidos tenham a mesma Filial!"	})
					
					U_ITCADHLP( _aInfHlp , "AOMS02812" )
					
					_lRet := .F.
					
					Exit
				
				EndIf
			
			Next _nI
			
			_oModZF8:GoLine( _nLinAtu )
		
		EndIf
		
	Else
	
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"O pedido informado não foi encontrado no"	,;
							" sistema!"									})
		
		aAdd( _aInfHlp	, {	"Verifique os dados informados e informe"	,;
							" um pedido válido."						})
		
		U_ITCADHLP( _aInfHlp , "AOMS02805" )
		
		_lRet := .F.
	
	EndIf
	
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028T
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Valida os pedidos de transferência informados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028T()

Local _oModel	:= FWModelActive()
Local _cCodPrg	:= _oModel:GetValue( 'ZF7MASTER' , 'ZF7_CODIGO' )
Local _cNumPed	:= _oModel:GetValue( 'ZF9DETAIL' , 'ZF9_PEDIDO' )    
Local _cItem 	:= _oModel:GetValue( 'ZF9DETAIL' , 'ZF9_ITEM' )    
Local _cOpTran	:= U_ITGETMV( 'IT_OPTRAN' , '20,41' )

Local _aInfHlp	:= {}
Local _aArea	:= FWGetArea()
Local _lRet		:= .T.


_cQuery := " SELECT "
_cQuery += "     ZF9.ZF9_PEDIDO "
_cQuery += " FROM  "+ RetSqlName('ZF9') +" ZF9 "
_cQuery += " WHERE "
_cQuery += "     ZF9.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZF9.ZF9_FILIAL = '" + xFilial("SC5") + "'"
_cQuery += " AND ZF9.ZF9_CODPRG = '" + _cCodPrg + "'"    
_cQuery += " AND ZF9.ZF9_ITEM = '" + _cItem + "'"
	
_cAlias := GetNextAlias()
	
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf
	
DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If (_cAlias)->( !Eof() )

	_lRet := .F.    
		
	_aInfHlp := {}
	   //                  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, {	"Pedido de troca só pode ser informado"	,;
								" na inclusão! "	})
	
	aAdd( _aInfHlp	, {	"Exclua e inclua novamente o pedido."	,;
								" "	})						
						
	U_ITCADHLP( _aInfHlp , "AOMS0280E" )


EndIf


DBSelectArea('SC5')
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( xFilial('SC5') + _cNumPed ) )
	
	If Empty( SC5->C5_LIBEROK ) .And. Empty( SC5->C5_NOTA ) .And. Empty( SC5->C5_BLQ ) //Verifica pedido pendente (sem uso)
	
		_lRet := ( SC5->C5_I_OPER $ _cOpTran )
		
		If !_lRet
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"A Filial e Pedido informados não fazem"	,;
								" referência à um pedido de transferência!"	})
			
			aAdd( _aInfHlp	, {	"Verifique os dados e informe um pedido"	,;
								" de transferência para a prosseguir."		})
			
			U_ITCADHLP( _aInfHlp , "AOMS02803" )
			
		EndIf
	
	Else
		
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"O pedido informado não está 'Pendente'"	,;
							" no sistema!"								})
		
		aAdd( _aInfHlp	, {	"Somente poderão ser utilizados nas"		,;
							" programações os pedidos que ainda não"	,;
							" estiverem atendidos ou em processamento."	})
		
		U_ITCADHLP( _aInfHlp , "AOMS02804" )
		
		_lRet := .F.
		
	EndIf

Else

	_aInfHlp := {}
	//                  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, {	"O pedido informado não foi encontrado no"	,;
						" sistema!"									})
	
	aAdd( _aInfHlp	, {	"Verifique os dados informados e informe"	,;
						" um pedido válido."						})
	
	U_ITCADHLP( _aInfHlp , "AOMS02805" )
	
	_lRet := .F.

EndIf

If _lRet

	_cQuery := " SELECT "
	_cQuery += "     ZF8.ZF8_FILIAL AS FILPRG ,"
	_cQuery += "     ZF8.ZF8_CODPRG AS CODPRG "
	_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8 , "+ RetSqlName('ZF7') +" ZF7 "
	_cQuery += " WHERE "
	_cQuery += "     ZF8.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZF7.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZF7.ZF7_FILIAL = ZF8.ZF8_FILIAL "
	_cQuery += " AND ZF7.ZF7_CODIGO = ZF8.ZF8_CODPRG "
	_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
	_cQuery += " AND ZF8.ZF8_FILPED = '"+ xFilial('ZF9')	+"' "
	_cQuery += " AND ZF8.ZF8_NUMPED = '"+ _cNumPed			+"' "
	_cQuery += " AND ( ( ZF8.ZF8_FILIAL = '"+ xFilial('ZF8') +"' AND ZF8.ZF8_CODPRG <> '"+ _cCodPrg +"' ) OR ( ZF8.ZF8_FILIAL <> '"+ xFilial('ZF8') +"' ) ) "
	
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		
		DBSelectArea('ZF7')
		ZF7->( DBSetOrder(1) )
		If ZF7->( DBSeek( (_cAlias)->( FILPRG + CODPRG ) ) )
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"A Filial e Pedido informados já estão"		,;
								" configurados em outra programação de"		,;
								" entrega!"									})
			
			aAdd( _aInfHlp	, {	"Verifique a programação ["+ (_cAlias)->CODPRG +"] na"			,;
								" Filial ["+ (_cAlias)->FILPRG +"]."							,;
								" Status ["+ U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' ) +"]."	})
			
			U_ITCADHLP( _aInfHlp , "AOMS02802" )
			
			_lRet := .F.
			
		EndIf
		
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

If _lRet

	_cQuery := " SELECT "
	_cQuery += "     ZF9.ZF9_FILIAL AS FILPRG ,"
	_cQuery += "     ZF9.ZF9_CODPRG AS CODPRG  "
	_cQuery += " FROM  "+ RetSqlName('ZF9') +" ZF9 , "+ RetSqlName('ZF7') +" ZF7 "
	_cQuery += " WHERE "
	_cQuery += "     ZF9.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZF9.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZF7.ZF7_FILIAL = ZF9.ZF9_FILIAL "
	_cQuery += " AND ZF7.ZF7_CODIGO = ZF9.ZF9_CODPRG "
	_cQuery += " AND ZF7.ZF7_STATUS <> '6' "
	_cQuery += " AND ZF9.ZF9_FILIAL = '"+ xFilial('ZF9')	+"' "
	_cQuery += " AND ZF9.ZF9_PEDIDO = '"+ _cNumPed			+"' "
	_cQuery += " AND ZF9.ZF9_CODPRG <> '"+ _cCodPrg			+"' "
	
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		
		DBSelectArea('ZF7')
		ZF7->( DBSetOrder(1) )
		If ZF7->( DBSeek( (_cAlias)->( FILPRG + CODPRG ) ) )
			
			_aInfHlp := {}
			//                  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, {	"O pedido de transferência informado já"	,;
								" foi utilizado em outra programação!"		})
			
			aAdd( _aInfHlp	, {	"Verifique a programação ["+ (_cAlias)->CODPRG +"] na"			,;
								" Filial ["+ (_cAlias)->FILPRG +"]."							,;
								" Status ["+ U_ITRETBOX( ZF7->ZF7_STATUS , 'ZF7_STATUS' ) +"]."	})
			
			U_ITCADHLP( _aInfHlp , "AOMS02811" )
			
			_lRet := .F.
			
		EndIf
		
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028WFC
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Monta e dispara o WF de comunicação das Movimentações
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028WFC( _cStatus , _cMsgAux , _aPedAtn )

Local _aConfig		:= U_ITCFGEML('')
Local _aPedidos		:= {}
Local _cMsgEml		:= ''
Local _cEmail		:= ''
Local _cPedTrn		:= ''
Local _cStsAux		:= ''
Local _nI			:= 0
Default _cStatus	:= ''
Default _cMsgAux	:= ''

If Empty(_cStatus)
	
	U_ITMsg( 'Falha ao identificar o Status inicial da programação de entrega! Informe a área de TI/ERP.' , 'Atenção!' , ,1)
	Return
	
EndIf

_cEmail := FWSFAllUsers({ZF7->ZF7_USRLOG},{"USR_EMAIL"})[1][3]
If !Empty(_cEmail)
	_cEmail += ','
EndIf
_cEmail += FWSFAllUsers({ZF7->ZF7_USRPRG},{"USR_EMAIL"})[1][3]

If Empty( _cEmail )
	
	U_ITMsg( 'Falha ao localizar o e-mail do destinatário do WF! Verifique com a área de TI/ERP.' , 'Atenção!' , ,1 )
	
Else

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
	
	If _cStatus == 'N'
	_cMsgEml += '	     <td class="titulos"><center>Notificação referente à programação de entregas</center></td>'
	ElseIf _cStatus == 'R'
	_cMsgEml += '	     <td class="titulos"><center>Remoção de pedidos da programação de entregas</center></td>'
	Else
	_cMsgEml += '	     <td class="titulos"><center>A programação de entregas foi atualizada para: '+ U_ITRETBOX( _cStatus , 'ZF7_STATUS' ) +'</center></td>'
	EndIf
	
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
	
	If _cStatus == 'N'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Notificação:</b></td>'
	_cMsgEml += '      <td class="itens" >'+ AllTrim( _cMsgAux ) +'</td>'
	_cMsgEml += '    </tr>'
	ElseIf _cStatus == '3'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Motivo da Devolução:</b></td>'
	_cMsgEml += '      <td class="itens" >'+ AllTrim( _cMsgAux ) +'</td>'
	_cMsgEml += '    </tr>'
	ElseIf _cStatus == 'R'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Motivo da remoção:</b></td>'
	_cMsgEml += '      <td class="itens" >'+ AllTrim( _cMsgAux ) +'</td>'
	_cMsgEml += '    </tr>'
	EndIf
	
	_cMsgEml += '	<tr>'
	_cMsgEml += '		<td class="grupos" align="center" colspan="2"><b>Para maiores informações acesse o sistema e visualize a programação.</b></td>'
	_cMsgEml += '	</tr>'
	_cMsgEml += '	<tr>'
	_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '</table>'
	
	_aPedidos := AOMS028PED( ZF7->ZF7_FILIAL , ZF7->ZF7_CODIGO , .F. )
	
	If ( _cStatus $ '2/N' .And. !Empty(_aPedidos) ) .Or. ( _cStatus == 'R' .And. !Empty(_aPedAtn) )
	
		_cMsgEml += '<br>'
		_cMsgEml += '<table class="bordasimples" width="800">'
		_cMsgEml += '    <tr>'
		
		If _cStatus == 'R'
		_cMsgEml += '      <td align="center" colspan="3" class="grupos">Pedidos removidos da Programação</b></td>'
		Else
		_cMsgEml += '      <td align="center" colspan="4" class="grupos">Pedidos da Programação</b></td>'
		EndIf
		
		_cMsgEml += '    </tr>'
		_cMsgEml += '    <tr>'
		
		If _cStatus == 'R'
		
			_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Pedidos:</b></td>'
			_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Peso:</b></td>'
			_cMsgEml += '      <td class="itens" align="center" width="60%"><b>Cliente:</b></td>'
			
		Else
		
			_cMsgEml += '      <td class="itens" align="center" width="13%"><b>Pedidos:</b></td>'
			_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Peso:</b></td>'
			_cMsgEml += '      <td class="itens" align="center" width="54%"><b>Local de Entrega:</b></td>'
			_cMsgEml += '      <td class="itens" align="center" width="13%"><b>Transf.:</b></td>'
			
		EndIf
		
		_cMsgEml += '    </tr>'
		
		If _cStatus == 'R'
		
			For _nI := 1 To Len( _aPedAtn )
				
				If _aPedAtn[_nI][01]
				
					_cMsgEml += '    <tr>'
					_cMsgEml += '      <td class="itens" align="center" width="20%">'+ _aPedAtn[_nI][02] +'-'+ _aPedAtn[_nI][03]										+'</td>'
					_cMsgEml += '      <td class="itens" align="right"  width="20%">'+ _aPedAtn[_nI][08]																+'</td>'
					_cMsgEml += '      <td class="itens" align="left"   width="60%">'+ _aPedAtn[_nI][04] +'/'+ _aPedAtn[_nI][05] +' - '+ PadR( _aPedAtn[_nI][06] , 60 )	+'</td>'
					_cMsgEml += '    </tr>'
				
				EndIf
			
			Next _nI
		
		Else
		
			For _nI := 1 To Len( _aPedidos )
			
				_cPedTrn := AOMS028GPT( ZF7->ZF7_CODIGO , _aPedidos[_nI][01] , _aPedidos[_nI][02] )
			
				_cMsgEml += '    <tr>'
				_cMsgEml += '      <td class="itens" align="center" width="13%">'+ _aPedidos[_nI][01] +'-'+ _aPedidos[_nI][02]									+'</td>'
				_cMsgEml += '      <td class="itens" align="right"  width="20%">'+ Transform( _aPedidos[_nI][10] , '@E 999,999,999.9999' )						+'</td>'
				_cMsgEml += '      <td class="itens" align="left"   width="54%">'+ _aPedidos[_nI][14] +' - '+ _aPedidos[_nI][09] +' ['+ _aPedidos[_nI][15] +']'	+'</td>'
				_cMsgEml += '      <td class="itens" align="center" width="13%">'+ _cPedTrn																		+'</td>'
				_cMsgEml += '    </tr>'
			
			Next _nI
		
		EndIf
		
		_cMsgEml += '</table>'
	
	EndIf
	
	_cMsgEml += '</center>'
	_cMsgEml += '</body>'
	_cMsgEml += '</html>'
	
	_cEmlLog := ''
	
	If _cStatus == 'N'
		_cStsAux := 'Notificação'
	ElseIf _cStatus == 'R'
		_cStsAux := 'Remoção de Pedidos'
	Else
		_cStsAux := U_ITRETBOX( _cStatus , 'ZF7_STATUS' )
	EndIf
	
	U_ITENVMAIL( _aConfig[01] , _cEmail ,,, 'Programação de entregas - '+ _cStsAux +' ['+ DToC( Date() ) +']' , _cMsgEml ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cEmlLog )
	
	If !Empty( _cEmlLog )
		U_ITMsg( _cEmlLog , 'Término do processamento!' , ,1 )
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS028PRD
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Recupera as informações de produtos da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028PRD( _cCodPrg )

Local _aRet		:= {}
Local _aArea	:= FWGetArea()
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SC6.C6_PRODUTO        AS CODPRD,"
_cQuery += "     SUM( SC6.C6_QTDVEN )  AS QTDVEN,"
_cQuery += "     SUM( SC6.C6_UNSVEN )  AS SQTVEN "
_cQuery += " FROM  "+ RetSqlName('SC5') +" SC5, "+ RetSqlName('SC6') +" SC6, "+ RetSqlName('ZF8') +" ZF8 "
_cQuery += " WHERE "+ RetSqlDel( 'SC5,SC6,ZF8' )
_cQuery += " AND ZF8.ZF8_FILIAL = '"+ xFilial('SC5') +"' "
_cQuery += " AND SC5.C5_FILIAL  = ZF8.ZF8_FILPED "
_cQuery += " AND SC6.C6_FILIAL  = ZF8.ZF8_FILPED "
_cQuery += " AND SC5.C5_NUM     = ZF8.ZF8_NUMPED "
_cQuery += " AND SC6.C6_NUM     = ZF8.ZF8_NUMPED "
_cQuery += " AND ZF8.ZF8_CODPRG = '"+ _cCodPrg +"' "

_cQuery += " AND ZF8.ZF8_DTENTR BETWEEN '"+ DToS( MV_PAR09 )	+"' AND '"+ DToS( MV_PAR10 )	+"' "
_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+ MV_PAR03			+"' AND '"+ MV_PAR05			+"' "
_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+ MV_PAR04			+"' AND '"+ MV_PAR06			+"' "
_cQuery += IIf( Empty(MV_PAR11) , '' , " AND SC5.C5_I_EST   IN "+ FormatIn( MV_PAR11 , ';' )	)

_cQuery += " GROUP BY SC6.C6_PRODUTO "
_cQuery += " ORDER BY SC6.C6_PRODUTO "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	
	aAdd( _aRet , {	(_cAlias)->CODPRD	,;
					(_cAlias)->QTDVEN	,;
					(_cAlias)->SQTVEN	})
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: AOMS028ENT
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Recupera as informações das datas de entrega da programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028ENT( _cCodPrg )

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _aDatas	:= {}
Local _cDtsEnt	:= ''
Local _nI		:= 0

_cQuery := " SELECT "
_cQuery += "     ZF8.R_E_C_N_O_ AS REGZF8 "
_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('SC5') +" SC5 "
_cQuery += " WHERE "+ RetSqlCond('ZF8')
_cQuery += " AND   "+ RetSqlDel('SC5')
_cQuery += " AND ZF8.ZF8_FILPED = SC5.C5_FILIAL "
_cQuery += " AND ZF8.ZF8_NUMPED = SC5.C5_NUM "
_cQuery += " AND ZF8.ZF8_CODPRG = '"+ _cCodPrg +"' "
_cQuery += " AND ZF8.ZF8_DTENTR BETWEEN '"+ DToS( MV_PAR09 )	+"' AND '"+ DToS( MV_PAR10 )	+"' "
_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+ MV_PAR03			+"' AND '"+ MV_PAR05			+"' "
_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+ MV_PAR04			+"' AND '"+ MV_PAR06			+"' "
_cQuery += IIf( Empty(MV_PAR11) , '' , " AND SC5.C5_I_EST   IN "+ FormatIn( MV_PAR11 , ';' )	)

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	DBSelectArea('ZF8')
	ZF8->( DBGoTo( (_cAlias)->REGZF8 ) )
	
	If aScan( _aDatas , ZF8->ZF8_DTENTR ) <= 0
		aAdd( _aDatas , ZF8->ZF8_DTENTR )
	EndIf

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

aSort( _aDatas )

For _nI := 1 To Len( _aDatas )
	_cDtsEnt += IIf( Empty(_cDtsEnt) , '' , ' - ' ) + DToC( _aDatas[_nI] )
Next _nI

FWRestArea( _aArea )

Return( _cDtsEnt )

/*
===============================================================================================================================
Programa--------: AOMS028REG
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Recupera as informações da região da tabela de frete que deve ser usada para atender à programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028REG( _nOpc , _cCodPrg )

Local _xRet		:= NIL
Local _cReg		:= ''
Local _aLocais	:= {}
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nI		:= 0

If _nOpc == 1 .Or. _nOpc == 2

	_cQuery := " SELECT "
	_cQuery += "     SC5.C5_I_EST || SC5.C5_I_CMUN AS CODMUN "
	_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('SC5') +" SC5 "
	_cQuery += " WHERE "+ RetSqlCond('ZF8')
	_cQuery += " AND   "+ RetSqlDel('SC5')
	_cQuery += " AND ZF8.ZF8_FILPED = SC5.C5_FILIAL "
	_cQuery += " AND ZF8.ZF8_NUMPED = SC5.C5_NUM "
	_cQuery += " AND ZF8.ZF8_CODPRG = '"+ _cCodPrg +"' "
	_cQuery += " AND ZF8.ZF8_DTENTR BETWEEN '"+ DToS( MV_PAR09 )	+"' AND '"+ DToS( MV_PAR10 )	+"' "
	_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+ MV_PAR03			+"' AND '"+ MV_PAR05			+"' "
	_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+ MV_PAR04			+"' AND '"+ MV_PAR06			+"' "
	_cQuery += IIf( Empty(MV_PAR11) , '' , " AND SC5.C5_I_EST   IN "+ FormatIn( MV_PAR11 , ';' )	)
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
	
		If aScan( _aLocais , (_cAlias)->CODMUN ) <= 0
		
			aAdd( _aLocais , (_cAlias)->CODMUN )
			_cReg += AllTrim( (_cAlias)->CODMUN ) +';'
			
		EndIf
	    
	(_cAlias)->( DBSkip() )
	EndDo
	
	If !Empty( _cReg )
		
		If _nOpc == 1
		
			_cReg := SubStr( _cReg , 1 , Len(_cReg) -1 )
			
			_cQuery := " SELECT DISTINCT "
			_cQuery += "     ZF1.ZF1_DESREG AS DESREG "
			_cQuery += " FROM  "+ RetSqlName('ZF2') +" ZF2, "+ RetSqlName('ZF1') +" ZF1 "
			_cQuery += " WHERE "+ RetSqlCond('ZF2,ZF1')
			_cQuery += " AND ZF2.ZF2_FILIAL  = ZF1.ZF1_FILIAL "
			_cQuery += " AND ZF2.ZF2_CODREG  = ZF1.ZF1_CODREG "
			_cQuery += " AND ZF2.ZF2_CODMUN  IN "+ FormatIn( _cReg , ';' )
			_cQuery += " ORDER BY ZF1.ZF1_DESREG "
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
			
			_xRet := ''
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )
			While (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->DESREG )
				
				_xRet += AllTrim( (_cAlias)->DESREG ) +' / '
				
			(_cAlias)->( DBSkip() )
			EndDo
			
			(_cAlias)->( DBCloseArea() )
			
			If Empty(_xRet)
				_xRet := 'Não foram encontradas regiões na Tabela de Frete para atender àos pedidos dessa programação!'
			Else
				_xRet := SubStr( _xRet , 1 , Len(_xRet) -3 )
			EndIf
			
		ElseIf _nOpc == 2
			
			_xRet := ''
			
			For _nI := 1 To Len( _aLocais )
				
				DBSelectArea('CC2')
				CC2->( DBSetOrder(1) )
				If CC2->( DBSeek( xFilial('CC2') + _aLocais[_nI] ) )
					
					_xRet += AllTrim( CC2->CC2_MUN ) +'/'+ CC2->CC2_EST +'; '
					
				EndIf
				
			Next _nI
			
			If Empty(_xRet)
				_xRet := 'Não foram encontrados os municípios dos clientes dos pedidos na tabela de municípios do Sistema!'
			Else
				_xRet := SubStr( _xRet , 1 , Len(_xRet) -2 )
			EndIf
		
		EndIf
			
	EndIf
	
ElseIf _nOpc == 3
	
	_cAlias	:= GetNextAlias()
	_xRet	:= {}
	
	_cQuery := " SELECT DISTINCT "
	_cQuery += "     ZFA.ZFA_CFGPRZ AS CONFIG ,"
	_cQuery += "     ZFA.ZFA_DIAMIN AS DIAMIN ,"
	_cQuery += "     ZFA.ZFA_DIAMAX AS DIAMAX  "
	_cQuery += " FROM  "+ RetSqlName('ZFA') +" ZFA, "+ RetSqlName('ZF1') +" ZF1, "+ RetSqlName('ZF2') +" ZF2 "
	_cQuery += " WHERE "+ RetSqlCond('ZFA,ZF1,ZF2')
	_cQuery += " AND ZF1.ZF1_FILIAL  = ZF2.ZF2_FILIAL "
	_cQuery += " AND ZFA.ZFA_CODREG  = ZF1.ZF1_CODREG "
	_cQuery += " AND ZF2.ZF2_CODREG  = ZF1.ZF1_CODREG "
	_cQuery += " AND ZF2.ZF2_CODMUN  = '"+ _cCodPrg +"' "
	_cQuery += " ORDER BY ZFA.ZFA_CFGPRZ "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		
		If !Empty( (_cAlias)->CONFIG )
			
			aAdd( _xRet , { (_cAlias)->CONFIG , (_cAlias)->DIAMIN , (_cAlias)->DIAMAX } )
			
		EndIf
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
EndIf

Return( _xRet )

/*
===============================================================================================================================
Programa--------: AOMS028PED
Autor-----------: Alexandre Villar
Data da Criacao-: 01/10/2015
Descrição-------: Recupera dados de pedidos da programação para impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028PED( _cFilPrg , _cCodPrg , _lRelat )

Local _aRet		:= {}
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _lAdd		:= .T.

Default _lRelat	:= .F.

_cQuery := " SELECT "
_cQuery += "     ZF8.ZF8_FILPED AS FILPED ,"
_cQuery += "     ZF8.ZF8_NUMPED AS NUMPED ,"
_cQuery += "     ZF8.ZF8_DTENTR AS DTENTR ,"
_cQuery += "     SC5.C5_CLIENTE AS CODCLI ,"
_cQuery += "     SC5.C5_LOJACLI AS LOJACLI,"
_cQuery += "     SC5.C5_VEND1   AS CODVEN ,"
_cQuery += "     SA3.A3_NOME    AS NOMVEN ,"
_cQuery += "     SC5.C5_I_END   AS ENDENT ,"
_cQuery += "     SC5.C5_I_BAIRR AS BAIENT ,"
_cQuery += "     SC5.C5_I_MUN	AS MUNENT ,"
_cQuery += "     SC5.C5_I_CEP   AS CEPENT ,"
_cQuery += "     SC5.C5_I_PESBR AS PESO   ,"
_cQuery += "     ZF8.R_E_C_N_O_ AS REGZF8 ,"
_cQuery += "     SC5.C5_MENNOTA AS OBSPED ,"
_cQuery += "     ZF8.ZF8_OBSPRG	AS OBSPRG  "
_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('SC5') +" SC5, "+ RetSqlName('SA3') +" SA3 "
_cQuery += " WHERE "+ RetSqlDel('ZF8,SC5,SA3')
_cQuery += " AND SC5.C5_FILIAL  = ZF8.ZF8_FILPED "
_cQuery += " AND SC5.C5_NUM     = ZF8.ZF8_NUMPED "
_cQuery += " AND SA3.A3_COD     = SC5.C5_VEND1   "
_cQuery += " AND ZF8.ZF8_FILIAL = '"+ _cFilPrg +"' "
_cQuery += " AND ZF8.ZF8_CODPRG = '"+ _cCodPrg +"' "

If _lRelat

_cQuery += " AND ZF8.ZF8_DTENTR BETWEEN '"+ DToS( MV_PAR09 )	+"' AND '"+ DToS( MV_PAR10 )	+"' "
_cQuery += " AND SC5.C5_CLIENTE BETWEEN '"+ MV_PAR03			+"' AND '"+ MV_PAR05			+"' "
_cQuery += " AND SC5.C5_LOJACLI BETWEEN '"+ MV_PAR04			+"' AND '"+ MV_PAR06			+"' "
_cQuery += IIf( Empty(MV_PAR11) , '' , " AND SC5.C5_I_EST   IN "+ FormatIn( MV_PAR11 , ';' )	)

EndIf

_cQuery += " ORDER BY ZF8.ZF8_DTENTR, SC5.C5_CLIENTE, SC5.C5_LOJACLI, ZF8.ZF8_NUMPED "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	
	// Tratativa para filtrar itens faturados no relatório
	If _lRelat
	
		DBSelectArea('ZF8')
		ZF8->( DBGoTo( (_cAlias)->REGZF8 ) )
		
		_lAdd := .F.
		
		DBSelectArea('SC5')
		SC5->( DBSetOrder(1) )
		If SC5->( DBSeek( ZF8->( ZF8_FILPED + ZF8_NUMPED ) ) )
			
			DBSelectArea('SC6')
			SC6->( DBSetOrder(1) )
			If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
				
				While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
					
					If Empty(SC6->C6_NOTA)
						_lAdd := .T.
						Exit
					EndIf
					
				SC6->( DBSkip() )
				EndDo
				
			EndIf
			
		EndIf
	
		If MV_PAR15 == 4
			_lAdd := !_lAdd
		EndIf
	
	EndIf
	
	If _lAdd
	
		aAdd( _aRet , {	(_cAlias)->FILPED																		,;
						(_cAlias)->NUMPED																		,;
						DToC( SToD( (_cAlias)->DTENTR ) )														,;
						(_cAlias)->CODCLI																		,;
						(_cAlias)->LOJACLI																		,;
						U_AOMS028N( 1 , (_cAlias)->FILPED , (_cAlias)->NUMPED )									,;
						(_cAlias)->CODVEN																		,;
						AllTrim( (_cAlias)->NOMVEN )															,;
						Capital( AllTrim( (_cAlias)->BAIENT ) ) +'/'+ Capital( AllTrim( (_cAlias)->MUNENT ) )	,;
						(_cAlias)->PESO																			,;
						(_cAlias)->REGZF8																		,;
						AllTrim( (_cAlias)->OBSPED )															,;
						AllTrim( (_cAlias)->OBSPRG )															,;
						AllTrim( (_cAlias)->ENDENT )															,;
						AllTrim( (_cAlias)->CEPENT )															})
		
	EndIf
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: AOMS028H
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Gravação do Histórico da programação de entrega
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028H( _aDadLog )

Local _cCodItn	:= '001'

DBSelectArea('ZFB')
ZFB->( DBSetOrder(1) )
If ZFB->( DBSeek( xFilial('ZFB') + _aDadLog[01] ) )
	
	While ZFB->(!Eof()) .And. ZFB->( ZFB_FILIAL + ZFB_CODPRG ) == xFilial('ZFB') + _aDadLog[01]
		
		_cCodItn := AllTrim( ZFB->ZFB_ITNLOG )
		
	ZFB->( DBSkip() )
	EndDo
	
	_cCodItn := Soma1( _cCodItn )
	
	While !MayIUseCod( 'AOMS028H_'+ _aDadLog[01] +'_'+ _cCodItn )
		_cCodItn := Soma1( _cCodItn )
	EndDo
	
EndIf

RecLock( 'ZFB' , .T. )
	
	ZFB->ZFB_FILIAL	:= xFilial('ZFB')
	ZFB->ZFB_CODPRG	:= _aDadLog[01]
	ZFB->ZFB_ITNLOG	:= _cCodItn
	ZFB->ZFB_ACAO	:= _aDadLog[02]
	ZFB->ZFB_OBS	:= _aDadLog[03]
	ZFB->ZFB_DATA	:= Date()
	ZFB->ZFB_HORA	:= Time()
	ZFB->ZFB_USR	:= RetCodUsr()
	
ZFB->( MSUnLock() )

Return

/*
===============================================================================================================================
Programa--------: AOMS028C
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Consulta Histórico da programação de entrega
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028C()

Local _aLog	:= {}

DBSelectArea('ZFB')
ZFB->( DBSetOrder(1) )
If ZFB->( DBSeek( xFilial('ZFB') + ZF7->ZF7_CODIGO ) )
	
	While ZFB->( !Eof() ) .And. ZFB->( ZFB_FILIAL + ZFB_CODPRG ) == xFilial('ZFB') + ZF7->ZF7_CODIGO
		
		aAdd( _aLog , {	ZFB->ZFB_ITNLOG										,;
						DToC( ZFB->ZFB_DATA )								,;
						ZFB->ZFB_HORA										,;
						Capital( AllTrim( EVAL(bFullName,  ZFB->ZFB_USR ) ) )	,;
						U_ITRetBox( ZFB->ZFB_ACAO , 'ZFB_ACAO' )			,;
						ZFB->ZFB_OBS										})
		
	ZFB->( DBSkip() )
	EndDo
	
	U_ITListBox( 'Histórico da Programação '+ ZF7->ZF7_CODIGO +':' , {'Item','Data','Hora','Usuário','Ação','Obs'} , _aLog , .F. , 1 )
	
Else

	U_ITMsg( 'Sem registro de histórico para exibir!' , 'Atenção!' , ,1 )
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS028P
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Verifica se um determinado pedido está amarrado à uma programação
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028P( _cFilPed , _cNumPed )

Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT Count(1) AS REG
_cQuery += " FROM  "+ RetSqlName('ZF8') +" ZF8, "+ RetSqlName('ZF7') +" ZF7 "
_cQuery += " WHERE "+ RetSqlCond('ZF8,ZF7')
_cQuery += " AND ZF8.ZF8_CODPRG = ZF7.ZF7_CODIGO "
_cQuery += " AND ZF8.ZF8_FILPED = '"+ _cFilPed +"' "
_cQuery += " AND ZF8.ZF8_NUMPED = '"+ _cNumPed +"' "
_cQuery += " AND ZF7.ZF7_STATUS <> '6' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

_lRet := ( (_cAlias)->( !Eof() ) .And. (_cAlias)->REG > 0 )

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028NCD
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Retorna um novo código para a gravação de novas programações
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS028NCD()

Local _cNewCod	:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT MAX( ZF7.ZF7_CODIGO ) AS CODIGO FROM "+ RETSQLNAME('ZF7') +" ZF7 WHERE "+ RETSQLCOND('ZF7')

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->CODIGO )
	_cNewCod := Soma1( AllTrim( (_cAlias)->CODIGO ) )
Else
	_cNewCod := StrZero( 1 , TamSX3('ZF7_CODIGO')[01] )
EndIf

(_cAlias)->( DBCloseArea() )

While !MayIUseCod( 'AOMS028_ZF7_'+ _cNewCod )
	_cNewCod := Soma1( _cNewCod )
EndDo

Return( _cNewCod )

/*
===============================================================================================================================
Programa--------: AOMS028B
Autor-----------: Alexandre Villar
Data da Criacao-: 06/10/2015
Descrição-------: Busca programação com base em uma chave de Pedido/Filial digitados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS028B()

Local _oDlg		:= NIL
Local _oSeek	:= NIL
Local _oGet1	:= NIL
Local _cGet1	:= Space(08)
Local _cQuery	:= ''
Local _cAlias	:= ''

DEFINE MSDIALOG _oDlg TITLE "Busca Avançada:" FROM 0,0 TO 050,186 PIXEL
	
	@ 002,003 Say 'Digite a Filial + Pedido:'	SIZE 060,010 COLOR CLR_BLACK PIXEL OF _oDlg
	@ 012,003 Get _oGet1 Var _cGet1				SIZE 060,010 COLOR CLR_BLACK PIXEL OF _oDlg
	
	DEFINE SBUTTON FROM 012,066 Type 1 ENABLE ACTION ( IIf( Empty(_cGet1) .Or. Len( AllTrim(_cGet1) ) < 8 , U_ITMsg('É obrigatório informar uma chave válida de busca!','Atenção!',,1) , _oDlg:End() ) ) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If Empty(_cGet1)
	U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção!' , ,1 )
Else
	
	_cQuery := " SELECT ZF7.ZF7_CODIGO AS CODZF7 FROM "+ RETSQLNAME('ZF7') +" ZF7, "+ RETSQLNAME('ZF8') +" ZF8 WHERE "+ RETSQLCOND('ZF7,ZF8') +" AND ZF7.ZF7_CODIGO = ZF8.ZF8_CODPRG AND ZF8.ZF8_FILPED || ZF8.ZF8_NUMPED = '"+ _cGet1 +"' ORDER BY ZF7.ZF7_CODIGO "
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->CODZF7 )
		
		DBSelectArea('ZF7')
		ZF7->( DBSetOrder(1) )
		If ZF7->( DBSeek( xFilial('ZF7') + (_cAlias)->CODZF7 ) )
			
			_oSeek			:= _oBrowse:GetSeek()
			_oSeek:cSeek	:= (_cAlias)->CODZF7
			_oBrowse:nAt	:= _oBrowse:Seek( _oSeek )
			
			_oBrowse:Refresh()
			
		Else
		
			U_ITMsg( 'Falhou ao posicionar na programação: '+ (_cAlias)->CODZF7 +' !'									, 'Atenção!' , ,1 )
			
		EndIf
		
	Else
	
		U_ITMsg( 'A chave de pedido informada ['+ _cGet1 +'] não foi encontrada nas programações na Filial atual!'		, 'Atenção!' ,,1 )
		
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS028GPT
Autor-----------: Alexandre Villar
Data da Criacao-: 23/11/2015
Descrição-------: Recupera os pedidos de transferência de um determinado pedido da programação
Parametros------: _cCodPrg - Código da programação
----------------: _cFilPed - Filial do Pedido da Programação
----------------: _cNumPed - Número do Pedido da Programação
Retorno---------: _cRet    - Pedidos de transferência amarrados ao pedido da programação
===============================================================================================================================
*/

Static Function AOMS028GPT( _cCodPrg , _cFilPed , _cNumPed )

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     ZF9.ZF9_FILIAL AS FILIAL,"
_cQuery += "     ZF9.ZF9_PEDIDO AS PEDIDO "
_cQuery += " FROM  "+ RetSqlName('ZF9') +" ZF9, "+ RetSqlName('ZF8') +" ZF8 "
_cQuery += " WHERE "+ RetSqlCond('ZF9,ZF8')
_cQuery += " AND ZF9.ZF9_CODPRG = ZF8.ZF8_CODPRG "
_cQuery += " AND ZF9.ZF9_ITNPED = ZF8.ZF8_ITEM "
_cQuery += " AND ZF9.ZF9_CODPRG = '"+ _cCodPrg +"' "
_cQuery += " AND ZF8.ZF8_FILPED = '"+ _cFilPed +"' "
_cQuery += " AND ZF8.ZF8_NUMPED = '"+ _cNumPed +"' "
_cQuery += " ORDER BY ZF9.ZF9_FILIAL, ZF9.ZF9_PEDIDO "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	
	_cRet := (_cAlias)->FILIAL +'-'+ (_cAlias)->PEDIDO +' '
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

Return( _cRet )

/*
===============================================================================================================================
Programa--------: AOMS028L
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 30/01/2017
Descrição-------: Valida usuário da logistica
Parametros------: Nenhum
Retorno---------: Lógico indicando usuário válido ou não
===============================================================================================================================
*/
User Function AOMS028L()

Local _lRet		:= .F.
Local _oModel	:= FWModelActive()
Local _cCodLog	:= _oModel:GetValue( 'ZF7MASTER' , 'ZF7_USRLOG' )

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial('ZZL') + _cCodLog ) )
	
	If ZZL->ZZL_PRGLOG == '2'
	
		_lRet := .T.
		
	Else
	
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"O código de usuário informado para ser o "	,;
							" responsável pela programação na "			,;
							" logística não é válido!"					})
		
		aAdd( _aInfHlp	, {	"Deve ser informado um usuário que esteja "	,;
							" cadastrado na gestão de usuários com "	,;
							" perfil 'logística'. "						})
		
		U_ITCADHLP( _aInfHlp , "AOMS02818" )
		
	EndIf

Else
	
	_aInfHlp := {}
	//                  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, {	"O código de usuário informado para ser o "	,;
						" responsável pela programação na "			,;
						" logística não é válido!"					})
	
	aAdd( _aInfHlp	, {	"Deve ser informado um usuário que esteja "	,;
						" cadastrado na gestão de usuários com "	,;
						" perfil 'logística'. "						})
	
	U_ITCADHLP( _aInfHlp , "AOMS02818" )
	
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS028I
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 30/01/2017
Descrição-------: Gatilha linha de pedidos
Parametros------: Nenhum
Retorno---------: Dados de pedido do ZF8
===============================================================================================================================
*/

User Function AOMS028I()

Local _oModel	:= FWModelActive()
Local _cFilAux	:= ''
Local _nLinAtu	:= 0
Local _nLinMax	:= 0

If ValType( _oModel ) == 'O'
	
	_nLinAtu := _oModel:GetModel('ZF8DETAIL'):nLine
	_nLinMax := _oModel:GetModel('ZF8DETAIL'):Length()
	
	If _nLinAtu > 0
		
		_nLinAtu := 1
		
		_oModel:GetModel('ZF8DETAIL'):GoLine(_nLinAtu)
		
		If _oModel:GetModel('ZF8DETAIL'):isDeleted()
		
			While _nLinAtu <= _nLinMax .And. _oModel:GetModel('ZF8DETAIL'):isDeleted()
			    
			    _nLinAtu++
			    
			    If _nLinAtu <= _nLinMax
					_oModel:GetModel('ZF8DETAIL'):GoLine(_nLinAtu)
				EndIf
				
			EndDo
		
		EndIf
		
		If _nLinAtu <= _nLinMax
			_cFilAux := _oModel:GetValue( 'ZF8DETAIL' , 'ZF8_FILPED' )
		EndIf
		
	EndIf
	
EndIf

Return( _cFilAux )

/*
===============================================================================================================================
Programa--------: AOMS028VUL
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 30/01/2017
Descrição-------: Valida usuário
Parametros------: Nenhum
Retorno---------: _lRet - .T. - Permite usuário informado / .F. - Não permite usuário informado
===============================================================================================================================
*/

Static Function AOMS028VUL( _cCodUsr )

Local _xRet := U_ITACSUSR( 'ZZL_PRGLOG' , '2' , _cCodUsr )

If ValType( _xRet ) == 'N' .And. _xRet == 0
	//								|....:....|....:....|....:....|....:....|
	ShowHelpDlg( 'Atenção!' ,	{	'Usuário informado não está cadastrado na '	,;
									' Gestão de Usuários Italac!'				}, 2 ,;
								{	'Verifique o código informado.'				}, 1  )
	_xRet := .F.

ElseIf ValType( _xRet ) == 'L' .And. !_xRet
	//								|....:....|....:....|....:....|....:....|
	ShowHelpDlg( 'Atenção!' ,	{	'Usuário informado não está configurado '	,;
									' como Logística na Gestão de Usuários '	,;
									' Italac!'									}, 3 ,;
								{	'Verifique o código informado.'				}, 1  )

EndIf

Return( _xRet )

/*
===============================================================================================================================
Programa--------: A028VLD
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 30/01/2017
Descrição-------: Função criada para validar os acessos dos usuários logísticos a filial corrente.
Parametros------: Nenhum
Retorno---------: _lRet - .T. - Permite usuário informado / .F. - Não permite usuário informado
===============================================================================================================================
*/
User Function A028VLD()
Local _aArea	:= FWGetArea()
Local _lRet		:= .F.
Local _nX		:= 0

_aUserInf := FWUsrEmp(M->ZF7_USRLOG) 

If Len(_aUserInf) > 0
	If _aUserInf[1] <> "@@@@"
		For _nX := 1 To Len(_aUserInf)
			If cFilAnt == SubStr(_aUserInf[_nX],3,2)
				_lRet := .T.
				Exit
			EndIf
		Next _nX
	Else
		_lRet := .T.			
	Endif	
	If !_lRet
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, {	"Usuário informado não tem autorização na "	,;
							" filial corrente do sistema.     "			})
	
		aAdd( _aInfHlp	, {	"Verifique os acessos do usuário. "			})
	
		U_ITCADHLP( _aInfHlp , "AOMS02819" )
	EndIf
Else
	_aInfHlp := {}
	//                  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, {	"Usuário informado não está cadastrado no "	,;
						" módulo configurador do sistema. "			})
		
	aAdd( _aInfHlp	, {	"Verifique o código informado.    "			})
		
	U_ITCADHLP( _aInfHlp , "AOMS02821" )

	_lRet := .F.
EndIf

FWRestArea(_aArea)
Return(_lRet)


/*
===============================================================================================================================
Programa--------: AOMS028Z
Autor-----------: Josué Danich Prestes
Data da Criacao-: 19/09/2017
Descrição-------: Gatilha filial para seleção de pedidos
Parametros------: Nenhum
Retorno---------: _cfilial - Filial a ser gatilhada
===============================================================================================================================
*/
User Function AOMS028Z()

Local _cfilial := "01"
Local _oModel	:= FWModelActive()
Local _oModZF8	:= _oModel:GetModel( 'ZF8DETAIL' )
Local _nLinAtu	:= _oModZF8:nLine

If _nlinAtu > 0

 _cfilial := _oModel:GetValue( 'ZF8DETAIL' , 'ZF8_FILPED' )
 
EndIf

Return _cfilial
