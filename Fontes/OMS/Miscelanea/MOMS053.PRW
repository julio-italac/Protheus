#Include 'TOTVS.CH'

/*  
===============================================================================================================================
Programa----------: MOMS053
Autor-------------: Jonathan Torioni
Data da Criacao---: 18/05/2020
===============================================================================================================================
Descrição---------: Importação da tabela de preço
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function MOMS053()
    Local cFile := ""
    Local aDados := {} //Primeira posição do array é o aHeader, as demais é o aCols
    Local aCampos := {}
    Local aCols := {}
    Local nX := 0
    Local cPathSrv := "\temp\"
    Local aPose := {}
    Local nArq := 0
    Local aButtons := {}
    Local _bOK
    Local lRet := .T.
    
    Private oBj   := Nil
    Private lHtml := (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtml
    Private oMark         := NIL
    Private lInverte := .F.
    Private cMark := GetMark()
    Private _cNwAlias   := GetNextAlias()
    Private oDlg        := Nil
    Private cItem := ""
    Private cTabAnt := ""
    Private cFilPos := ""
       
    _bOK := {|aParam| MOMS053OK(aParam) }

    cFile := tFileDialog( "*.csv|*.csv", "Selecao de Arquivo" ,, "C:\", .T., GETF_LOCALHARD + GETF_RETDIRECTORY)                     
    
    If cFile == ""
        U_ITMsg("Processo cancelado. Local do arquivo não informado.", "Falha!")
        lRet := .F.
    EndIf
    
    If !(".csv" $ cFile)
        U_ITMsg("O arquivo deve estar no formato *.csv", "Falha!")
        lRet := .F.
    EndIf

    If lRet
        aPose := StrTokArr(cFile, "\")
        nArq := Len(aPose)
        
        //Realizo a transferencia do arquivo para a pasta \temp\ para conseguir fazer a leitur
        If lHtml
            If CpyT2S(cFile,cPathSrv)
                cFile := cPathSrv + aPose[nArq]
                MsgRun( "Enviando arquivo para o servidor..." ,"Aguarde.", {|| Sleep(2000) } ) //Sleep para concluir a movimentação do arquivo.
            EndIf
        EndIf

        Processa({||aDados := MOMS053R(cFile), "Lendo arquivo de dados..." })
        aAdd(aCampos, aDados[1][1])
        aAdd(aCampos, aDados[1][2])
        aAdd(aCampos, aDados[1][3])
        aAdd(aCampos, aDados[1][4]) 
        aAdd(aCampos, aDados[1][5])
        aAdd(aCampos, aDados[1][6])
        aAdd(aCampos, aDados[1][7])
        aAdd(aCampos, aDados[1][8])
        aAdd(aCampos, aDados[1][9])
        aAdd(aCampos, aDados[1][10])
        aAdd(aCampos, aDados[1][11])

        aAdd(aCampos, aDados[1][12])
        aAdd(aCampos, aDados[1][13])
        aAdd(aCampos, aDados[1][14])
        aAdd(aCampos, aDados[1][15])

        For nX := 2 TO Len(aDados)
            aAdd(aCols, aDados[nX])
        Next
        oBj := MsNewProcess():New({||U_MOMS053G(aCols,oBj)},"Processando importação...","Aguarde...", .F.)

        U_ITListBox( "Importação Tabela de Preço" , aCampos , aCols , .T. , 1 , /*_cMsgTop*/ , /*_lSelUnc*/ , /*_aSizes*/ , /*_nCampo*/ , _bOk /*bOk*/ , /*bCancel*/, aButtons , /*aCampos*/ , /*bDblClk*/ , aCols , /*bCondMarca*/)
    EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS053R
Autor-------------: Jonathan Torioni
Data da Criacao---: 18/05/2020
===============================================================================================================================
Descrição---------: Realiza a leitura do arquivo de importação
===============================================================================================================================
Parametros--------: cFile - Local + nome do arquivo.csv
===============================================================================================================================
Retorno-----------: aCampos - Retorna os dados do arquivo no formato de um array
===============================================================================================================================
*/
Static Function MOMS053R(cFile)
    Local nX        := 0
    Local aCampos   := {}
    Local nTotal    := 0
    Local nAtual    := 0

    If !FILE(cFile)
        Alert("Arquivo não foi encontrado no diretório informado.")
        Return
    EndIf

    FT_FUSE(cFile)
    nTotal := FT_FLASTREC()
    ProcRegua(nTotal)
    FT_FGOTOP()
    //Pego todos os dados do arquivo
    While !FT_FEOF()
        nAtual++
        IncProc("Lendo arquivo para importação [" + StrZero(nAtual,5)+ "] de [" + StrZero(nTotal,5) + "]")
        cLinha := FT_FREADLN()
        aAdd(aCampos, Separa(cLinha, ";", .T.))
        FT_FSKIP()
    EndDo

    FT_FUSE()
    //Realizo a tratativa dos dados enviados.
    For nX := 2 TO Len(aCampos)
        aCampos[nX][3] := StrZero(Val(aCampos[nX][3]),11)
        aCampos[nX][5] := StrZero(Val(aCampos[nX][5]),4)
        aCampos[nX][6] := NOROUND(Val(StrTran(aCampos[nX][6], ",",".")),5)
        aCampos[nX][7] := NOROUND(Val(StrTran(aCampos[nX][7], ",",".")),5,)
        aCampos[nX][8] := NOROUND(Val(StrTran(aCampos[nX][8], ",",".")),5)
        aCampos[nX][9] := NOROUND(Val(StrTran(aCampos[nX][9], ",",".")),5)
        aCampos[nX][10] := NOROUND(Val(StrTran(aCampos[nX][10], ",",".")),5,)
        aCampos[nX][11] := NOROUND(Val(StrTran(aCampos[nX][11], ",",".")),5)
        aCampos[nX][12] := NOROUND(Val(StrTran(aCampos[nX][12], ",",".")),5)
        aCampos[nX][13] := NOROUND(Val(StrTran(aCampos[nX][13], ",",".")),5)
        aCampos[nX][14] := NOROUND(Val(StrTran(aCampos[nX][14], ",",".")),5)
        aCampos[nX][15] := NOROUND(Val(StrTran(aCampos[nX][15], ",",".")),5)        
    Next

Return aCampos

/*
===============================================================================================================================
Programa----------: MOMS053G
Autor-------------: Jonathan Torioni
Data da Criacao---: 18/05/2020
===============================================================================================================================
Descrição---------: Realiza a validação e a gravação dos dados na DA1
===============================================================================================================================
Parametros--------: cFile - Local + nome do arquivo.csv
===============================================================================================================================
Retorno-----------: aCampos - Retorna os dados do arquivo no formato de um array
===============================================================================================================================
*/
User Function MOMS053G(aDados, oBj)
Local nW := 0
Local nTot1 := 0
Local _cStatus := ""
Local _nDA1_PRF1 := 0
Local _nDA1_PMF1 := 0
Local _nDA1_PRF2 := 0
Local _nDA1_PMF2 := 0
Local _nDA1_PRF3 := 0
Local _nDA1_PMF3 := 0
Local _nDA1_PRMX := 0

Private aNDA0 := {}
    
    DA0->(DBSelectArea("DA0"))
    DA0->(DBSetOrder(1))
    DA1->(DBSelectArea("DA1"))
    DA1->(DBSetOrder(1))

    nTot1 := Len(aDados)
    oBj:SetRegua1(nTot1)

    For nW := 1 TO Len(aDados)
        oBj:IncRegua1("Gravando dados na tabela:" + StrZero(nW,4) + " de " + StrZero(nTot1,4) + "...")
        DA0->(DBSeek(xFilial("DA0")+aDados[nW][1]))

        If DA1->(!DBSeek(xFilial("DA0")+aDados[nW][1]+aDados[nW][3]))
           _cStatus := "I"
           DA1->(RecLock("DA1",.T.))
           DA1->DA1_FILIAL := xFilial("DA0")
           DA1->DA1_ITEM   := MOMS053N(xFilial("DA0"), aDados[nW][1]) 
           DA1->DA1_ATIVO  := "1"
           DA1->DA1_I_MIX  := Posicione("SB1",1,xFilial("SB1")+aDados[nW][3],"B1_I_BIMIX") 
           DA1->DA1_TPOPER := "4"
           DA1->DA1_QTDLOTE := 999999.99
           DA1->DA1_MOEDA  := 1
           DA1->DA1_I_FILO := "01"
           DA1->DA1_DATVIG := DA0->DA0_DATDE
           DA1->DA1_CODTAB := aDados[nW][1]
           DA1->DA1_CODPRO := aDados[nW][3]
           DA1->DA1_GRUPO  := aDados[nW][5]
        Else 
           _cStatus := "A"
           DA1->(RecLock("DA1",.F.))
        EndIf  
        
        /*
        DA1->DA1_PRCVEN := aDados[nW][6]
        DA1->DA1_I_PMFE := aDados[nW][7]
        DA1->DA1_I_PRFE := aDados[nW][8]
        DA1->DA1_I_PMFR := aDados[nW][9]
        DA1->DA1_PRCMAX := aDados[nW][10]
        DA1->DA1_I_PRCA := aDados[nW][10]
        */

        //===============================================
        // Salva valores antes de atualizar a Tabela DA1.
        //===============================================
        _nDA1_PRF1 := DA1->DA1_I_PRF1
        _nDA1_PMF1 := DA1->DA1_I_PMF1
        _nDA1_PRF2 := DA1->DA1_I_PRF2
        _nDA1_PMF2 := DA1->DA1_I_PMF2
        _nDA1_PRF3 := DA1->DA1_I_PRF3
        _nDA1_PMF3 := DA1->DA1_I_PMF3
        _nDA1_PRMX := DA1->DA1_PRCMAX

        //============================================
        // Atualiza valores da tabela DA1.
        //============================================
        DA1->DA1_I_PRF1 := aDados[nW][9] 
        DA1->DA1_I_PMF1 := aDados[nW][10]
        DA1->DA1_I_PRF2 := aDados[nW][11]
        DA1->DA1_I_PMF2 := aDados[nW][12]            
        DA1->DA1_I_PRF3 := aDados[nW][13]
        DA1->DA1_I_PMF3 := aDados[nW][14]
        DA1->DA1_PRCMAX := aDados[nW][15]
        DA1->DA1_I_PRCA := aDados[nW][15]
       
        DA1->(MSUnLock())

 
        DA0->(RecLock("DA0",.F.))
        DA0->DA0_I_PES1 := aDados[nW][6]
        DA0->DA0_I_PES2 := aDados[nW][7]
        DA0->DA0_I_PES3 := aDados[nW][8]
        DA0->(MSUnLock())

 
        //Log de inclusão
        ZGS->(RecLock("ZGS",.T.))
        ZGS->ZGS_FILIAL := xFilial("DA1")
        ZGS->ZGS_ITEM   := DA1->DA1_ITEM
        ZGS->ZGS_DATA   := Date()
        ZGS->ZGS_HORA   := Time()
        ZGS->ZGS_USER   := cUserName
        ZGS->ZGS_MODULO := funname()	
        ZGS->ZGS_CODTAB := DA0->DA0_CODTAB
        ZGS->ZGS_DATDE 	:= DA0->DA0_DATDE
        ZGS->ZGS_HORADE	:= DA0->DA0_HORADE
        ZGS->ZGS_DATATE	:= DA0->DA0_DATATE
        ZGS->ZGS_HORATE	:= DA0->DA0_HORATE
        ZGS->ZGS_CONDPG	:= DA0->DA0_CONDPG
        ZGS->ZGS_TPHORA	:= DA0->DA0_TPHORA
        ZGS->ZGS_ATIVO 	:= DA0->DA0_ATIVO
        ZGS->ZGS_ODATDE := DA0->DA0_DATDE
        ZGS->ZGS_OHORAD := DA0->DA0_HORADE
        ZGS->ZGS_ODATAT := DA0->DA0_DATATE
        ZGS->ZGS_OHORAT := DA0->DA0_HORATE
        ZGS->ZGS_OCONDP := DA0->DA0_CONDPG
        ZGS->ZGS_OTPHOR := DA0->DA0_TPHORA
        ZGS->ZGS_OATIVO := DA0->DA0_ATIVO
        ZGS->ZGS_PES1   := DA0->DA0_I_PES1
        ZGS->ZGS_PES2   := DA0->DA0_I_PES2
        ZGS->ZGS_PES3   := DA0->DA0_I_PES3

		ZGS->ZGS_OOBS	:= DA0->DA0_I_OBS
		ZGS->ZGS_I_OFIL := DA0->DA0_I_FILI
		ZGS->ZGS_I_FILI := DA0->DA0_I_FILI
        
        ZGS->ZGS_I_PRMP	:= DA1->DA1_I_PRMP
        ZGS->ZGS_I_PTBN	:= DA1->DA1_I_PTBN
        ZGS->ZGS_I_VIGI	:= DA1->DA1_I_VIGI
        ZGS->ZGS_I_VIGF	:= DA1->DA1_I_VIGF
    
        ZGS->ZGS_GRUPO 	:= DA1->DA1_GRUPO
        ZGS->ZGS_CODPRO	:= DA1->DA1_CODPRO	  // Produto
        ZGS->ZGS_OCODPR	:= DA1->DA1_CODPRO	  // Produto ant
        ZGS->ZGS_PRCVEN	:= DA1->DA1_PRCVEN	  // Prc Venda
        ZGS->ZGS_I_PRCA	:= DA1->DA1_I_PRCA
        ZGS->ZGS_PRCMAX	:= DA1->DA1_PRCMAX	  // Prc Max	
        ZGS->ZGS_PRF1	:= DA1->DA1_I_PRF1	  // Preco Fx 1	
        ZGS->ZGS_PRF2	:= DA1->DA1_I_PRF2	  // Preco Fx 2	
        ZGS->ZGS_PRF3	:= DA1->DA1_I_PRF3	  // Preco Fx 3
        ZGS->ZGS_PMF1	:= DA1->DA1_I_PMF1	  // Pr Min Fx1	
        ZGS->ZGS_PMF2	:= DA1->DA1_I_PMF2	  // Pr Min Fx2	
        ZGS->ZGS_PMF3	:= DA1->DA1_I_PMF3	  // Pr Min Fx3
        ZGS->ZGS_OPRCVE	:= DA1->DA1_PRCVEN    // Prc Venda Ant	
        ZGS->ZGS_OPRCMA	:= _nDA1_PRMX         // DA1->DA1_PRCMAX    // Prc Mx Ant	
        //ZGS->ZGS_PMF1	:= _nDA1_PRF1         // DA1->DA1_I_PRF1    // Preço Fx 1 Ant	
        //ZGS->ZGS_PMF2	:= _nDA1_PRF2         // DA1->DA1_I_PRF2    // Preço Fx 2 Ant
        //ZGS->ZGS_PMF3	:= _nDA1_PRF3         // DA1->DA1_I_PRF3    // Preço Fx 3 Ant
        ZGS->ZGS_OPRF1  := _nDA1_PRF1         // Preço Fx 1 Ant
		ZGS->ZGS_OPRF2  := _nDA1_PRF2         // Preço Fx 2 Ant
		ZGS->ZGS_OPRF3  := _nDA1_PRF3         // Preço Fx 3 Ant
        ZGS->ZGS_OPMF1	:= _nDA1_PMF1         // DA1->DA1_I_PMF1    // Pr Min Fx1 A
        ZGS->ZGS_OPMF2	:= _nDA1_PMF2         // DA1->DA1_I_PMF2    // Pr Min Fx2 A
        ZGS->ZGS_OPMF3	:= _nDA1_PMF3         // DA1->DA1_I_PMF3    // Pr Min Fx3 A	

/*
        ZGS->ZGS_CODPRO	:= DA1->DA1_CODPRO OK
        ZGS->ZGS_GRUPO 	:= DA1->DA1_GRUPO OK
        ZGS->ZGS_PRCVEN	:= DA1->DA1_PRCVEN OK
        ZGS->ZGS_I_PRCA	:= DA1->DA1_I_PRCA OK
        ZGS->ZGS_PRCMAX	:= DA1->DA1_PRCMAX OK
        ZGS->ZGS_I_PRMP	:= DA1->DA1_I_PRMP OK
        ZGS->ZGS_I_PTBN	:= DA1->DA1_I_PTBN OK
        ZGS->ZGS_I_VIGI	:= DA1->DA1_I_VIGI OK
        ZGS->ZGS_I_VIGF	:= DA1->DA1_I_VIGF OK
        ZGS->ZGS_OCODPR := DA1->DA1_CODPRO OK
        ZGS->ZGS_OGRUPO := DA1->DA1_GRUPO  OK
        ZGS->ZGS_OPRCVE := DA1->DA1_PRCVEN OK
        ZGS->ZGS_I_OPRC := DA1->DA1_I_PRCA OK
        ZGS->ZGS_OPRCMA := DA1->DA1_PRCMAX OK
        ZGS->ZGS_I_OPRM := DA1->DA1_I_PRMP OK
        ZGS->ZGS_I_OPTB := DA1->DA1_I_PTBN OK
        ZGS->ZGS_I_OVII := DA1->DA1_I_VIGI OK
        ZGS->ZGS_I_OVIF := DA1->DA1_I_VIGF OK
        ZGS->ZGS_PRF1   := DA1->DA1_I_PRF1 OK
        ZGS->ZGS_PMF1   := DA1->DA1_I_PMF1 OK
        ZGS->ZGS_PRF2   := DA1->DA1_I_PRF2 OK
        ZGS->ZGS_PMF2   := DA1->DA1_I_PMF2 OK          
        ZGS->ZGS_PRF3   := DA1->DA1_I_PRF3 OK 
        ZGS->ZGS_PMF3   := DA1->DA1_I_PMF3 OK  
*/
        ZGS->ZGS_STATUS := _cStatus

        ZGS->(MSUnLock())
         
    Next
        
    U_ITMsg("Todos os dados foram importados com sucesso!","Processamento Concluído.")

Return
 
/*
===============================================================================================================================
Programa----------: MOMS053N
Autor-------------: Jonathan Torioni
Data da Criacao---: 18/05/2020
===============================================================================================================================
Descrição---------: Retorna numeração para DA1_ITEM
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: cNum 
===============================================================================================================================
*/
Static Function MOMS053N(_cFil, cTab)
    Local cNum := ""

    If cItem == ""
        cItem := StrZero(1,3)
        cNum := cItem
        cTabAnt := cTab
        cFilPos := _cFil
    ElseIf cItem != "" .And. cTabAnt == cTab .And. cFilPos == _cFil
        cItem := StrZero(Val(cItem)+1,3)
        cNum := cItem
        cTabAnt := cTab
        cFilPos := _cFil
    ElseIf cItem != "" .And. (cTabAnt != cTab .Or. cFilPos != _cFil)
        cItem := StrZero(1,3)
        cNum := cItem
        cTabAnt := cTab
        cFilPos := _cFil
    EndIf
Return cNum

/*
===============================================================================================================================
Programa----------: MOMS053OK
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/04/2021
===============================================================================================================================
Descrição---------: Função do botão BOK, Efetiva ou não a gravação dos dados importados e finaliza a tela de exibição dos dados
===============================================================================================================================
Parametros--------: aParam = Parametros da função ITLIST.
===============================================================================================================================
Retorno-----------: _aParam:end() = Finaliza a tela de exibição dos dados.
===============================================================================================================================
*/
Static Function MOMS053OK(_aParam)

Begin Sequence

If U_ITMsg("Confirma a importação dos dados?",'Atenção!',,2,2,2)
   oBj:Activate()
EndIf 

End Sequence

Return (_aParam:end())
