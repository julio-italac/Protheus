#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST007
Autor-------------: Josué Danich
Data da Criacao---: 31/08/2015
Descrição---------: Rotina para criar registros no SB9 - Chamado 11512
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST007()

Local _bProcess    := {|oSelf| MEST007P(oSelf) }
Local _cFunction   := "MEST007"
Local _cTitle      := "Acerto de saldos iniciais"
Local _cDescri	   := "Rotina que realiza a criação de saldos iniciais no B9  e B2"

Private	_cPerg     := "MEST007"

tNewProcess():New( _cFunction, _cTitle, _bProcess, _cDescri, _cPerg,,,,,,.T.)

Return

/*
===============================================================================================================================
Programa----------: MEST007P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/08/2015
Descrição---------: Ajuste de saldos iniciais.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST007P(oself)
  

Local _cAlias  	:= GetNextAlias()
//Local _nRegs		:= 0
Local _nregistros	:= 0
//Local _aLocal 	:= {}
//Local _ctemp		:= ""
Local _nI 			:= 2
//Local _ni2			:= 1
Local _aAutoSB9 	:= {}
//Local _cult 		:= ""
Local _aArms		:= {}
Local _aLog      := {}

//prepara matriz de armazéns
_aArms := StrTokArr(AllTrim(MV_PAR01), ";")

//carrega todo o b1 para analisar

_cQuery := " SELECT "
_cQuery += " B1.B1_COD     CODIGO, "
_cQuery += " B1.B1_LOCPAD  ARMAZEM, "
_cQuery += " B1.B1_TIPO  TIPO "
_cQuery += " FROM "+RetSqlName("SB1")+" B1 "
_cQuery += " WHERE B1.B1_FILIAL = '" + xFilial("SB1") + "'"
_cQuery += " AND  B1.B1_MSBLQL <> '1' "
_cQuery += " AND  B1.D_E_L_E_T_ = ' ' "
_cQuery += IIf( !Empty( MV_PAR03 ) , " AND B1.B1_TIPO IN "+ FormatIn( AllTrim( MV_PAR03 ) , ';' )	, "" ) 
_cQuery += IIf( !Empty( MV_PAR02 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
_cQuery += " ORDER BY B1_FILIAL,B1_COD "
	
If Select(_cAlias) > 0 
 	(_cAlias)->( DBCloseArea() )
EndIf
	
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .T. , .F. )
COUNT TO _nRegistros
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If _nRegistros > 0
	
	oSelf:SetRegua1( _nRegistros )
	
EndIf


aAdd( _aLog , "FUNÇÃO MEST007"								)		                 
aAdd( _aLog , "DATA DE PROCESSAMENTO: " + DToC( Date() )	)
aAdd( _aLog , "HORA DO INICIO DO PROCESSAMENTO: "+ Time()	)
		
oSelf:SaveLog( "INICIO - CRIA SB9" )
		
aAdd( _aLog , "INICIO - CRIA SB9"							)
	

While .not. (_cAlias)->(Eof())

	oSelf:IncRegua1( "PRODUTO: "+ AllTrim((_cAlias)->CODIGO) )
	
	For _nI:= 1 to Len(_aArms)
	
			//procura o armazém com saldo para o produto em qualquer data
			DBSelectArea("SB9")
			SB9->(DBSetOrder(1))
			If .not. SB9->(DBSeek(  xFilial("SB9") + PadR((_cAlias)->CODIGO,15) + AllTrim(_aArms[_nI]) ) )
			
				//cria saldo inicial
		       _aAutoSB9 = {}
		       aAdd (_aAutoSB9, {"B9_FILIAL",   xFilial("SB9")																, 				NIL})
              aAdd (_aAutoSB9, {"B9_COD",   (_cAlias)->CODIGO																, 				NIL})
              aAdd (_aAutoSB9, {"B9_LOCAL", AllTrim(_aArms[_nI])															,				NIL})
              lMSErroAuto = .F.
              MsExecAuto({|x,y,z|MATA220(x,y,z)}, _aAutoSB9, 3)
              If lMsErroAuto
					
					oSelf:SaveLog(	"O PRODUTO "+ AllTrim((_cAlias)->CODIGO	) +" ARMAZEM " + _aArms[_nI] + " APRESENTOU ERRO AO CRIAR O SALDO INICIAL." )
					aAdd( _aLog ,	"O PRODUTO "+ AllTrim((_cAlias)->CODIGO	) +"  ARMAZEM " + _aArms[_nI] + "  APRESENTOU ERRO AO CRIAR O SALDO INICIAL." )
             
            	Else

   					oSelf:SaveLog(	"O PRODUTO "+ AllTrim((_cAlias)->CODIGO	) +" ARMAZEM " + _aArms[_nI] + "  TEVE SALDO INICIAL CRIADO." )
					aAdd( _aLog ,	"O PRODUTO "+ AllTrim((_cAlias)->CODIGO	) +" ARMAZEM " + _aArms[_nI] + "  TEVE SALDO INICIAL CRIADO." )
  
              EndIf
		
			EndIf			
	
	Next

	(_cAlias)->(DBSkip())
	IncProc((_cAlias)->CODIGO)

EndDo

(_cAlias)->(DBCloseArea())


oSelf:SaveLog(	"FINAL - SALDOS INICIAIS" )
aAdd( _aLog ,	"FINAL - SALDOS INICIAIS" )
aAdd( _aLog ,	"HORA DO FIM DO PROCESSAMENTO: "+ Time() )


Processa( {|| MEST007L(_aLog) } , "Gravando dados no arquivo..." )

MsgInfo( "Ajuste de saldos iniciais bem sucedido!" )

//Registra log de acesso a rotina
U_ITLOGACS('MEST007')

//volta a tela inicial
U_MEST007()			

Return


/*
===============================================================================================================================
Programa----------: MEST007C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/08/2015
Descrição---------: Rotina para montar consulta de armazéns (NNR)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST007C()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Armazéns'
Local _aDados	:= {}  , _nI

_cQuery := " SELECT NNR_CODIGO,
_cQuery += " NNR_DESCRI
_cQuery += " FROM "+ RETSQLNAME('NNR') +" NNR "
_cQuery += " WHERE NNR.NNR_FILIAL = '" + xFilial('NNR') +"'"
_cQuery += "  ORDER BY NNR_CODIGO"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->NNR_CODIGO, (_cAlias)->NNR_DESCRI  } )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If U_ITListBox( _cTitAux , { 'X' , 'Armazem', 'Descricao' } , @_aDados , .F. , 2 , 'Selecione os armazens desejados: ' )

	For _nI := 1 To Len( _aDados )
		
		If _aDados[_nI][01]
			_cRet += AllTrim( _aDados[_nI][02] ) +';'
		EndIf
		
	Next _nI
	
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )

EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: MEST007L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/08/2015
Descrição---------: Rotina que permite gravar o LOG referente ao processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST007L(_aLog)

Local _cArq	:= ""
Local _nHdl	:= 0
Local _nPos	:= 0
Local _nI	:= 0

Aviso( "Salvar Log em TXT" , "Este programa ira gerar um arquivo texto com o Log do processamento executado" , {"Ok"} , 1 , "Geração de Arquivo Texto" )

_cArq := tFileDialog( "Documento Texto |*.TXT","Salvar Arquivo Como...",, "C:\", .T., GETF_LOCALHARD + GETF_RETDIRECTORY)

If !Empty(_cArq)

	_nPos := At( ".TXT" , Upper(_cArq) )

	If _nPos == 0
		_cArq := AllTrim(_cArq) + ".TXT"
	EndIf

	_nHdl := FCreate(_cArq)

	If _nHdl == -1
		MsgAlert( "O arquivo de nome "+_cArq+" nao pode ser criado!" , "Atencao!" )
		Return
	EndIf

	ProcRegua( Len(_aLog) )

	For _nI := 1 To Len(_aLog)
			
		FWrite( _nHdl , _aLog[_nI] + chr(13) + chr(10) )
		
		If FError() # 0
			MsgAlert ( "ERRO AO GRAVAR NO ARQUIVO: "+ Str( FError() ) )
			Exit
		EndIf
		
		IncProc()

	Next _nI

	FClose(_nHdl)

	MsgInfo( "Arquivo TXT gerado com sucesso!" )

EndIf

Return


/*
===============================================================================================================================
Programa----------: MEST007D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/08/2015
Descrição---------: Rotina para montar consulta de grupos de produtos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST007D()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Grupos de Produtos'
Local _aDados	:= {} , _nI

_cQuery := " SELECT 	BM_GRUPO, 
_cQuery += " BM_DESC 
_cQuery += " FROM "+ RETSQLNAME('SBM') +" SBM"  
_cQuery += " WHERE SBM.BM_FILIAL = '" + xFilial('SBM') + "'"
_cQuery += " AND SBM.D_E_L_E_T_ = ' '"
_cQuery += " ORDER BY BM_GRUPO"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->BM_GRUPO, (_cAlias)->BM_DESC  } )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If U_ITListBox( _cTitAux , { 'X' , 'Grupo', 'Descricao' } , @_aDados , .F. , 2 , 'Selecione os grupos desejados: ' )

	For _nI := 1 To Len( _aDados )
		
		If _aDados[_nI][01]
			_cRet += AllTrim( _aDados[_nI][02] ) +';'
		EndIf
		
	Next _nI
	
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )

EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: MEST007E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/08/2015
Descrição---------: Rotina para montar consulta de tipos de produtos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST007E()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Tipos de Produtos'
Local _aDados	:= {} , _nI

_cQuery := " SELECT SX5.X5_CHAVE CHAVE, 
_cQuery += " SX5.X5_DESCRI DESCRI 
_cQuery += " FROM "+ RETSQLNAME('SX5') +" SX5
_cQuery += " WHERE SX5.X5_FILIAL = '"+ xFilial('SX5') +"'"
_cQuery += " AND SX5.X5_TABELA = '02'"
_cQuery += " AND SX5.D_E_L_E_T_ = ' '"
_cQuery += " ORDER BY SX5.X5_CHAVE"

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	aAdd( _aDados , { .F. , (_cAlias)->CHAVE,(_cAlias)->DESCRI } )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If U_ITListBox( _cTitAux , { 'X' , 'Tipo', 'Descricao' } , @_aDados , .F. , 2 , 'Selecione os tipos desejados: ' )

	For _nI := 1 To Len( _aDados )
		
		If _aDados[_nI][01]
			_cRet += AllTrim( _aDados[_nI][02] ) +';'
		EndIf
		
	Next _nI
	
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )

EndIf

Return( .T. )
