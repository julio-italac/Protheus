#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: F050ROT
Autor-----------: Igor Melgaço
Data da Criacao-: 19/10/2021
Descrição-------: P.E. para inclusão de botões na tela de manutenção dos títulos a pagar no Financeiro. Chamado 38001
Parametros------: Nenhum
Retorno---------: aRotina -  Array com as rotinas acrescidas no botão
===============================================================================================================================
*/
User Function F050ROT()
     
    Local aArea   := FWGetArea()
    Local aRotina := ParamIXB // Array contendo os botoes padrões da rotina.
 
    // Tratamento no array aRotina para adicionar novos botoes e retorno do novo array.
    aAdd(aRotina, { "Bloqueio / Desbloqueio Gerencial"       , "U_F050BLQGER()", 0, 8, 0,.F.})
    aAdd(aRotina, { "Log de Bloqueio / Desbloqueio Gerencial", "U_F050BLQLOG()", 0, 8, 0,.F.})
    aAdd(aRotina, { "Bloqueio / Desbloqueio Gerencial em Lote", "U_MFIN019()"  , 0, 8, 0,.F.})
    aAdd(aRotina, {"Histórico de Alterações"                  , "U_FI050HIS"   , 0, 2, 0,.F.})
    FWRestArea(aArea)
 
Return aRotina

/*
===============================================================================================================================
Programa--------: F050BLQGER
Autor-----------: Igor Melgaço
Data da Criacao-: 19/10/2021
Descrição-------: Rotina de Bloqueio Gerencial de Títulos no Contas a Pagar
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F050BLQGER(_lAut,_cMsg)
Local _cBloq    := ""
Local lContinua := .T.
Local _cApos    := ""
Local _cAntes   := ""
Local _lRet     := .F.

Default _lAut := .F.
Default _cMsg := ""

If SE2->E2_SALDO > 0
    lContinua := .T.
Else
    lContinua := .F.
    If _lAut
        _cMsg := "Não é possivel realizar o bloqueio deste Título pois não há saldo!"
    Else
        U_ITMsg("Não é possivel realizar o bloqueio deste Título pois não há saldo!",,,3,,,,,, )
    EndIf
EndIf
 
If !_lAut .And. lContinua
    DBSelectArea("ZZL")
    DBSetOrder(3)
    If DBSeek(xFilial("ZZL")+__cUserId)
        If !(ZZL->ZZL_BLQGER == "S")
            lContinua := .F.
            U_ITMsg("Usuário sem permissão de acesso a esta rotina. Para mais informações procurar o gestor financeiro da unidade.",,,3,,,,,, )
        Else
            lContinua := .T.
        EndIf
    EndIf
EndIf

If lContinua

    _cBloq := IIf(SE2->E2_MSBLQL == "1","2","1")
    
    If !_lAut
	    lContinua :=  U_ITMsg("Confirma o " + Iif(_cBloq == "1","Bloqueio","Desbloqueio") + " Gerencial do Título " + AllTrim(SE2->E2_NUM) + IIf(!Empty(AllTrim(SE2->E2_PARCELA)),"  Parcela: " + SE2->E2_PARCELA,"")+"  Tipo : "+AllTrim(SE2->E2_TIPO)+"  Fornecedor: "+AllTrim(SE2->E2_NOMFOR)+" ?",IIf(_cBloq == "S","Bloqueio","Desbloqueio") + " Gerencial",,,2,,,,,)
    EndIf

    If lContinua    
        _cAntes := SE2->E2_MSBLQL
        
        Begin Transaction

            DBSelectArea("SE2")
            If RecLock("SE2", .F.)
                SE2->E2_MSBLQL := _cBloq 
                MSUnLock()

                lContinua := .T.
            Else
                If _lAut
                    _cMsg := "Atenção! Registro em uso. Aguarde alguns momentos e tente novamente"
                Else
			        U_ITMsg("Registro em uso","Atenção","Aguarde alguns momentos e tente novamente",1)
                EndIf

                lContinua := .F.
		    EndIf

            If lContinua
                _cApos := _cBloq
                
                DBSelectArea("ZE3")
                RecLock("ZE3", .T.)
                ZE3->ZE3_FILIAL := xFilial("ZE3") 
                ZE3->ZE3_ROTINA := "U_F050BLQGER" 
                ZE3->ZE3_TABELA := "SE2" 
                ZE3->ZE3_RECNO  := SE2->(Recno())
                ZE3->ZE3_CHAVE  := SE2->E2_FILIAL + "|" + SE2->E2_PREFIXO + "|" + SE2->E2_NUM + "|" + SE2->E2_PARCELA + "|" + SE2->E2_TIPO + "|" + SE2->E2_FORNECE + "|" + SE2->E2_LOJA
                ZE3->ZE3_DATA   := dDatabase
                ZE3->ZE3_HORA   := Time()
                ZE3->ZE3_CODUSU := FWSFAllUsers({__cUserId})[1][2]
                ZE3->ZE3_NOMUSU := FWSFAllUsers({__cUserId},{"USR_NOME"})[1][3]
                ZE3->ZE3_ACAO   := IIf(_cBloq == "1","Bloqueio","Desbloqueio")
                ZE3->ZE3_ALTAPL := "E2_MSBLQL (" + AllTrim(Getsx3cache("E2_MSBLQL","X3_TITULO")) + ") = De: '" + _cAntes + "' Para: '" + _cApos +"' "
                MSUnLock()
            EndIf

        End Transaction

        If lContinua 
            If _lAut
                _cMsg := ("Título " +IIf(_cBloq == "1","bloqueado","desbloqueado") + " com sucesso!")
            Else
                U_ITMsg("Título " +IIf(_cBloq == "1","bloqueado","desbloqueado") + " com sucesso!",,,2,,,,,, )
            EndIf

            _lRet := .T.
        Else
            _lRet := .F.
        EndIf
    EndIf
Else
    _lRet := .F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: F050BLQLOG
Autor-----------: Igor Melgaço
Data da Criacao-: 19/10/2021
Descrição-------: Rotina para exibição do Log de Bloqueio e Desbloqueio Gerencial do Título
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F050BLQLOG()
Local _aCab    := {}
Local _aSize   := {}
Local _aLogBLQ := {}
Local _cChave  := ""
Local _cTitAux := ""
Local _lHasOk  := .F.

_cChave := SE2->E2_FILIAL + "|" + SE2->E2_PREFIXO + "|" + SE2->E2_NUM + "|" + SE2->E2_PARCELA + "|" + SE2->E2_TIPO + "|" + SE2->E2_FORNECE + "|" + SE2->E2_LOJA

DBSelectArea("ZE3")
DBSetOrder(1)
If DBSeek("U_F050BLQGER"+"SE2"+Rtrim(_cChave))
    While "U_F050BLQGER"+"SE2"+Rtrim(_cChave) == ZE3->ZE3_ROTINA+ZE3->ZE3_TABELA+Rtrim(ZE3->ZE3_CHAVE)
        aAdd(_aLogBLQ,{IIf(Upper(AllTrim(ZE3->ZE3_ACAO))=="DESBLOQUEIO",.T.,.F.),ZE3->ZE3_ACAO,ZE3->ZE3_DATA,ZE3->ZE3_HORA,ZE3->ZE3_CODUSU,ZE3->ZE3_NOMUSU} )
        ZE3->(DBSkip())
    EndDo
EndIf

_aCab   := {"","Acao","Data","Hora","Cod Usuario","Nome do Usuario"}
_aSize  := {20,50,50,50,50,200}
_lHasOk := .F. // Não exibe o Botao Ok na Enchoicebar do ITListBox

If Len(_aLogBLQ) > 0
    _cTitAux := "Log de Bloqueio / Desbloqueio Gerencial do Título " + AllTrim(SE2->E2_NUM) + IIf(!Empty(AllTrim(SE2->E2_PARCELA)),"  Parcela: " + SE2->E2_PARCELA,"")+"  Tipo : "+AllTrim(SE2->E2_TIPO)+"  Fornecedor: "+AllTrim(SE2->E2_NOMFOR)
    U_ITListBox( _cTitAux,_aCab,_aLogBLQ , .T., 4 , , , _aSize  , , , , , , , , , , _lHasOk)
Else
    U_ITMsg("Nao houve Bloqueio para esse Título.",'Atenção!',,3)
EndIf

Return

/*
===============================================================================================================================
Programa--------: FI050HIS
Autor-----------: Igor Melgaço
Data da Criacao-: 02/01/2025
Descrição-------: Consulta histórico de Alterações
Parametros------: 
Retorno---------: 
===============================================================================================================================
*/
User Function FI050HIS()
    U_MOMS045G( SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA), "Historico","SE2",1)
Return
